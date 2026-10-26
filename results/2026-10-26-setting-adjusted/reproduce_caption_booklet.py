"""Rebuild the figure booklet with unchanged vector masters and complete captions.
Usage: python reproduce_caption_booklet.py SNAPSHOT FONT_REGULAR FONT_BOLD FRESH_PDF
Requires existing pypdf/reportlab; fonts must cover the actual caption characters.
"""
from pathlib import Path
import csv,sys,tempfile
from pypdf import PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.lib.utils import simpleSplit
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
snapshot,regular,bold,output=map(Path,sys.argv[1:5])
assert not output.exists(),'Use a fresh PDF output'
for name,path in [('Caption',regular),('Heading',bold)]:pdfmetrics.registerFont(TTFont(name,str(path)))
keys=['F0-primary-gas','F1-main','primary/F2','primary/S1-same-day-ABG','primary/S2-ICD-acuity','primary_bmi_ge30/F1-B','primary_bmi_ge30/F2','primary_bmi_ge30/S1-same-day-ABG','primary_bmi_ge30/S2-ICD-acuity']
lookup={r['figure_id']:r for r in csv.DictReader((snapshot/'captions.csv').open())}
writer=PdfWriter()
with tempfile.TemporaryDirectory(prefix='bmi-caption-booklet-') as temporary:
 for i,key in enumerate(keys):
  text=lookup[key]['caption'];title=key+' — figure caption'
  for font,value in [('Caption',text),('Heading',title)]:
   missing=sorted({c for c in value if not c.isspace() and ord(c) not in pdfmetrics.getFont(font).face.charToGlyph})
   assert not missing,(font,key,missing)
  writer.append(str(snapshot/'figures'/(key+'.pdf')))
  page=Path(temporary)/f'caption-{i}.pdf';c=canvas.Canvas(str(page),pagesize=(210*mm,297*mm));c.setFont('Heading',12);c.drawString(10*mm,282*mm,title);c.setFont('Caption',10);y=273*mm
  for line in simpleSplit(text,'Caption',10,190*mm):
   if y<15*mm:c.showPage();c.setFont('Caption',10);y=282*mm
   c.drawString(10*mm,y,line);y-=13
  c.save();writer.append(str(page))
 writer.write(output)
print('Booklet recreated from unchanged figure PDFs; all caption glyphs covered')
