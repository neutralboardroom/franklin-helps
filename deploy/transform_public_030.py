from pathlib import Path
import json, hashlib, base64, re, html
SITE=Path('public')
TODAY='2026-09-24'; RECHECK='2026-12-23'
rjs=SITE/'assets/resources.js'; raw=rjs.read_text(); pre='window.FH_RESOURCES = '; resources=json.loads(raw[len(pre):].strip()[:-1])
for r in resources:
    if r['id'] in {'FHR-025','FHR-026'}:
        r['checked_date']=TODAY; r['recheck_by']=RECHECK; r['web_rechecked']=True
new=[
{'id':'FHR-027','title':'Tennessee CoverRx — prescription coverage for eligible residents','need':'Prescription costs / Tennessee','group':'Prescription costs','area':'Tennessee / eligible Franklin residents','summary':'Tennessee residents ages 18–64 who meet CoverRx rules can review prescription coverage and apply while enrollment is open. Eligibility includes income and pharmacy-coverage limits, so check the official state page before applying.','url':'https://www.tn.gov/content/tn/tenncare/coverrx/coverrx-application.html','source_org':'Tennessee TennCare / CoverRx','checked_date':TODAY,'recheck_by':RECHECK,'relationship':'official-government-resource','source_finding_ids':['FHMAIN-030-RX-001'],'point_of_display_recheck':True,'web_rechecked':True,'freshness_state_at_build':'recheck-on-use','title_es':'Tennessee CoverRx — cobertura de recetas para residentes elegibles','need_es':'Costos de recetas / Tennessee','area_es':'Tennessee / residentes elegibles de Franklin','summary_es':'Los residentes de Tennessee de 18 a 64 años que cumplen las reglas de CoverRx pueden revisar la cobertura de recetas y solicitarla mientras la inscripción está abierta. La elegibilidad incluye límites de ingresos y de otra cobertura de farmacia; consulta la página oficial del estado antes de solicitar.'},
{'id':'FHR-028','title':'HealthWell Foundation — help with insured out-of-pocket medication costs','need':'Prescription costs / insured patients','group':'Prescription costs','area':'United States / eligible Franklin residents','summary':'HealthWell may help insured patients with eligible disease funds pay prescription coinsurance, copays, deductibles, premiums and selected out-of-pocket costs. Fund availability and eligibility can change, so check the current fund and rules directly.','url':'https://www.healthwellfoundation.org/eligibility/','source_org':'HealthWell Foundation','checked_date':TODAY,'recheck_by':RECHECK,'relationship':'independent-charitable-resource-not-a-franklin-helps-partner','source_finding_ids':['FHMAIN-030-RX-002'],'point_of_display_recheck':True,'web_rechecked':True,'freshness_state_at_build':'recheck-on-use','title_es':'HealthWell Foundation — ayuda con costos de medicamentos no cubiertos por completo','need_es':'Costos de recetas / personas aseguradas','area_es':'Estados Unidos / residentes elegibles de Franklin','summary_es':'HealthWell puede ayudar a pacientes asegurados con fondos de enfermedad elegibles a pagar coseguro, copagos, deducibles, primas y ciertos costos de bolsillo. La disponibilidad de fondos y la elegibilidad pueden cambiar; revisa el fondo y las reglas actuales directamente.'},
{'id':'FHR-029','title':'TotalAssist — charitable help with eligible healthcare and medication costs','need':'Prescription costs / serious or chronic conditions','group':'Prescription costs','area':'United States / eligible Franklin residents','summary':'Patient Advocate Foundation’s TotalAssist offers disease-specific charitable assistance for eligible out-of-pocket healthcare costs, including medication copays, coinsurance and deductibles. Search the current fund list because eligibility, covered medications and fund status vary.','url':'https://totalassist.org/funds/','source_org':'Patient Advocate Foundation / TotalAssist','checked_date':TODAY,'recheck_by':RECHECK,'relationship':'independent-charitable-resource-not-a-franklin-helps-partner','source_finding_ids':['FHMAIN-030-RX-003'],'point_of_display_recheck':True,'web_rechecked':True,'freshness_state_at_build':'recheck-on-use','title_es':'TotalAssist — ayuda caritativa con costos elegibles de atención y medicamentos','need_es':'Costos de recetas / enfermedades graves o crónicas','area_es':'Estados Unidos / residentes elegibles de Franklin','summary_es':'TotalAssist de Patient Advocate Foundation ofrece ayuda caritativa por enfermedad para ciertos costos de bolsillo, incluidos copagos, coseguro y deducibles de medicamentos. Consulta la lista actual de fondos porque la elegibilidad, los medicamentos cubiertos y el estado de cada fondo varían.'}
]
for r in new:
    r['search_terms']=' '.join(str(r.get(k,'')) for k in ['title','need','group','area','summary','source_org']).lower()
    r['search_terms_es']=' '.join(str(r.get(k,'')) for k in ['title_es','need_es','group','area_es','summary_es','source_org']).lower()
resources += new
resources.sort(key=lambda r:(0 if r.get('group')=='Prescription costs' else 1, int(r['id'].split('-')[1])))
rjs.write_text(pre+json.dumps(resources,ensure_ascii=False,separators=(',',':'))+';\n')
sri='sha384-'+base64.b64encode(hashlib.sha384(rjs.read_bytes()).digest()).decode()

def esc(s): return html.escape(s,quote=True)
def card(r,es=False):
    need=r['need_es'] if es else r['need']; title=r['title_es'] if es else r['title']; summ=r['summary_es'] if es else r['summary']; area=r['area_es'] if es else r['area']
    checked='24 sep. 2026' if es else 'Sep. 24, 2026'
    return (f'<article class="resource static-resource" data-need="{esc(r["need"])}" data-resource-id="{r["id"]}"><div class="need">{esc(need)}</div>'
      f'<span class="freshness recheck-on-use">{"Confirma disponibilidad" if es else "Check availability"}</span><h3>{esc(title)}</h3>'
      f'<p class="resource-summary">{esc(summ)}</p><details class="resource-more"><summary>{"Detalles" if es else "Details"}</summary>'
      f'<p class="resource-full">{esc(summ)} {"Confirma elegibilidad y disponibilidad directamente en la fuente oficial." if es else "Confirm eligibility and availability directly with the official source."}</p>'
      f'<p class="meta">{"Área: " if es else "Area: "}{esc(area)}</p><p class="meta">{"Verificado: " if es else "Checked: "}{checked}</p></details>'
      f'<div class="resource-actions"><button aria-pressed="false" class="filter save-resource static-save resource-save-action" disabled="disabled" type="button">{"Guardar recurso" if es else "Save resource"}</button>'
      f'<a class="source-link resource-primary-action" href="{esc(r["url"])}" rel="noopener noreferrer" target="_blank">{"Información oficial ↗" if es else "Official information ↗"}</a></div></article>')
for rel,es in [('help/index.html',False),('es/help/index.html',True)]:
    p=SITE/rel; s=p.read_text()
    s=s.replace('Search 26 resources','Search 29 resources').replace('Busca 26 recursos','Busca 29 recursos')
    if es:
        dup='<p class="filter-instruction">Explora por categoría o busca en todos los recursos:</p><p class="filter-instruction">Explora por categoría o busca en todos los recursos:</p>'
        s=s.replace(dup,'<p class="filter-instruction">Explora por categoría o busca en todos los recursos:</p>')
    marker='<a href="https://mercytn.org/" rel="noopener noreferrer" target="_blank">Mercy Community Healthcare ↗</a></div>'
    extra='<a href="https://www.healthwellfoundation.org/eligibility/" rel="noopener noreferrer" target="_blank">HealthWell Foundation ↗</a><a href="https://totalassist.org/funds/" rel="noopener noreferrer" target="_blank">TotalAssist ↗</a>'
    assert marker in s
    s=s.replace(marker, marker[:-6]+extra+'</div>',1)
    anchor='</article></div><section aria-labelledby="suggestedHeading" class="resource-suggestions"'
    assert anchor in s
    s=s.replace(anchor,'</article>'+''.join(card(r,es) for r in new)+'</div><section aria-labelledby="suggestedHeading" class="resource-suggestions"',1)
    if es: s=s.replace('Verificado: 23 sep. 2026','Verificado: 24 sep. 2026')
    else: s=s.replace('Checked: Sep. 23, 2026','Checked: Sep. 24, 2026')
    s=re.sub(r'integrity="sha384-[^"]+" src="([^"]*assets/resources\.js)"',f'integrity="{sri}" src="\\1"',s)
    s=s.replace('src="\\1"', 'src="assets/resources.js"' if rel=='help/index.html' else 'src="../../assets/resources.js"')
    p.write_text(s)
print('SRI',sri)
