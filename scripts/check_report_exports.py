#!/usr/bin/env python3
"""Inspect aggregate exports and prepare visual-review sheets; never certify manual QC."""
from pathlib import Path
import argparse,csv,hashlib,json,subprocess,xml.etree.ElementTree as ET
from PIL import Image,ImageDraw,ImageChops

NS='{http://www.w3.org/1999/xhtml}'
def geometry(pdf):
    root=ET.fromstring(subprocess.check_output(['pdftotext','-bbox-layout',str(pdf),'-']))
    rows=[]
    for i,page in enumerate(root.iter(NS+'page'),1):
        w,h=float(page.attrib['width']),float(page.attrib['height']);bad=[];replacement=[];heights=[];words=[]
        for word in page.iter(NS+'word'):
            x0,y0,x1,y1=[float(word.attrib[k]) for k in ['xMin','yMin','xMax','yMax']]
            if x0 < -1 or y0 < -1 or x1>w+1 or y1>h+1:bad.append(word.text)
            if '\ufffd' in (word.text or ''):replacement.append(word.text)
            heights.append(y1-y0)
            words.append((x0,y0,x1,y1,word.text))
        collisions=[]
        words.sort()
        for j,a in enumerate(words):
            for b in words[j+1:]:
                if b[0]>=a[2]:break
                dx=min(a[2],b[2])-max(a[0],b[0]);dy=min(a[3],b[3])-max(a[1],b[1])
                area=min((a[2]-a[0])*(a[3]-a[1]),(b[2]-b[0])*(b[3]-b[1]))
                if dx>1 and dy>2 and area>0 and dx*dy/area>.2:collisions.append([a[4],b[4]])
        rows.append(dict(page=i,width_pt=w,height_pt=h,outside=bad,replacement=replacement,text_collisions=collisions,min_text_height_pt=min(heights) if heights else None))
    return rows

def sheets(items,out,width,columns,per_sheet):
    out.mkdir(parents=True,exist_ok=True)
    for start in range(0,len(items),per_sheet):
        group=items[start:start+per_sheet];thumbs=[]
        for name,path in group:
            im=Image.open(path).convert('L');im.thumbnail((width,round(width*1.48)));thumbs.append((name,im.copy()))
        heights=[max(im.height for _,im in thumbs[i:i+columns])+23 for i in range(0,len(thumbs),columns)]
        canvas=Image.new('RGB',(columns*(width+6),sum(heights)),'#e6e6e6');draw=ImageDraw.Draw(canvas)
        for j,(name,im) in enumerate(thumbs):
            x=(j%columns)*(width+6);y=sum(heights[:j//columns]);draw.text((x+3,y+3),name,fill='black');canvas.paste(im,(x,y+22))
        canvas.save(out/f'sheet-{start//per_sheet+1:03}.png')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('review',type=Path);args=ap.parse_args();review=args.review.resolve();qc=review/'qc';qc.mkdir(exist_ok=True)
    results={'review':str(review),'manual_review':'pending','reports':{},'figures':[]}
    for name in ['bmi_hypercapnia','bmi_hypercapnia_audit']:
        pdf=review/(name+'.pdf');dest=qc/name;dest.mkdir(exist_ok=True)
        pages=geometry(pdf);results['reports'][name]={'sha256':hashlib.sha256(pdf.read_bytes()).hexdigest(),'pages':pages}
        subprocess.run(['pdftoppm','-r','100','-png',str(pdf),str(dest/'page')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        paths=sorted(dest.glob('page-*.png'),key=lambda p:int(p.stem.split('-')[-1]))
        sheets([(p.stem,p) for p in paths],dest/'overview',330,5,10)
    for png in sorted((review/'figures').glob('*.png')):
        im=Image.open(png);rgb=im.convert('RGB');r,g,b=rgb.split()
        checks=geometry(png.with_suffix('.pdf'))
        results['figures'].append(dict(id=png.stem,dpi=im.info.get('dpi'),size=im.size,vector=png.with_suffix('.svg').exists(),grayscale=ImageChops.difference(r,g).getbbox() is None and ImageChops.difference(g,b).getbbox() is None,pages=checks))
    sheets([(p.stem,p) for p in sorted((review/'figures').glob('*.png'))],qc/'figure-sheets',748,2,4)
    (qc/'automated-export-checks.json').write_text(json.dumps(results,indent=2)+'\n')
    issues=[]
    for name,r in results['reports'].items():
        for p in r['pages']:
            if p['outside'] or p['replacement'] or p['text_collisions']:issues.append([name,p['page'],p['outside'],p['replacement'],p['text_collisions']])
    for f in results['figures']:
        if not f['vector'] or not f['grayscale'] or not f['dpi'] or abs(f['dpi'][0]-300)>1:issues.append([f['id'],'format'])
        for p in f['pages']:
            if p['outside'] or p['replacement'] or p['text_collisions']:issues.append([f['id'],'bounds/symbols/collisions',p['text_collisions']])
    (qc/'automated-issues.json').write_text(json.dumps(issues,indent=2)+'\n')
    print(json.dumps({'pages':{k:len(v['pages']) for k,v in results['reports'].items()},'figures':len(results['figures']),'issues':issues,'manual_review':'pending'}))
    if issues:raise SystemExit('Export issues require repair or explicit review; no visual pass asserted')
if __name__=='__main__':main()
