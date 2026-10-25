"""Append full captions below unchanged vector figures for an email PDF."""
import io,csv,pathlib,sys
from pypdf import PdfReader,PdfWriter,Transformation
from reportlab.pdfgen.canvas import Canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from xml.sax.saxutils import escape
pdfmetrics.registerFont(TTFont('CaptionUnicode','/System/Library/Fonts/Supplemental/Arial Unicode.ttf'))
pdfmetrics.registerFontFamily('CaptionUnicode',normal='CaptionUnicode',bold='CaptionUnicode',italic='CaptionUnicode',boldItalic='CaptionUnicode')
root=pathlib.Path(sys.argv[1]);caps={x['figure_id']:x for x in csv.DictReader((root/'captions.csv').open())};writer=PdfWriter()
for group in ['primary','primary_bmi_ge30']:
 for name in ['F1-B','F2','S1-same-day-ABG','S2-ICD-acuity']:
  key=group+'/'+name;src=PdfReader(root/'figures'/f'{key}.pdf').pages[0];width=float(src.mediabox.width);height=float(src.mediabox.height)
  text='<b>'+escape(key)+'</b><br/>'+escape(caps[key]['caption'])+'<br/><i>New results: investigator interpretation and figure approval pending.</i>'
  para=Paragraph(text,ParagraphStyle('caption',fontName='CaptionUnicode',fontSize=9.5,leading=12))
  _,h=para.wrap(width-40,10000);extra=h+35;buf=io.BytesIO();c=Canvas(buf,pagesize=(width,height+extra));para.drawOn(c,20,18);c.save();buf.seek(0)
  page=PdfReader(buf).pages[0];page.merge_transformed_page(src,Transformation().translate(tx=0,ty=extra));writer.add_page(page)
writer.add_metadata({'/Title':'All-BMI integrated analysis: key figures with captions','/Subject':'Aggregate investigator review; no new scientific approval'})
with (root/'key_figures.pdf').open('wb') as f:writer.write(f)
print('Captioned eight-figure booklet created')
