#!/usr/bin/env python3
from pathlib import Path
import json,re,hashlib,base64
PUBLIC=Path('public')
REL='FH-MAIN-0.1.32'; DATE='2026-09-25'; EXPECTED_FILES=82

def sri(p): return 'sha384-'+base64.b64encode(hashlib.sha384(p.read_bytes()).digest()).decode()
def patch_record(x):
    rid=x.get('id')
    if rid=='FHR-011':
        x.update(summary='Franklin Housing Authority publishes public-housing and voucher-program information. Application and waiting-list status can change; check the official Housing Programs page at the time help is needed.',checked_date='2026-09-17',recheck_by='2026-09-25',freshness_state_at_build='recheck-on-use',point_of_display_recheck=True,web_rechecked=False,summary_es='Franklin Housing Authority publica información sobre vivienda pública y programas de vales. El estado de solicitudes y listas de espera puede cambiar; consulta la página oficial de Housing Programs cuando necesites ayuda.',title_es='Franklin Housing Authority — programas de vivienda',need_es='Programas de vivienda',area_es='Franklin')
    elif rid=='FHR-018':
        x.update(summary='Tennessee DHS provides child-care payment assistance for eligible families, an online or paper application path, and a provider search that can filter for providers accepting Child Care Payment Assistance. Required verification documents vary by case; confirm current eligibility and provider availability directly with DHS.',checked_date=DATE,recheck_by='2026-10-25',freshness_state_at_build='recheck-on-use',point_of_display_recheck=True,web_rechecked=True,summary_es='Tennessee DHS ofrece asistencia para pagar cuidado infantil a familias elegibles, solicitud en línea o en papel y búsqueda de proveedores que puede filtrar los que aceptan Child Care Payment Assistance. Los documentos de verificación dependen del caso; confirma elegibilidad y disponibilidad directamente con DHS.',title_es='Tennessee DHS — asistencia de cuidado infantil y búsqueda de proveedores',need_es='Asistencia de cuidado infantil',area_es='Williamson County / programa de Tennessee')
    elif rid=='FHR-026':
        x.update(summary='Medicare Extra Help can reduce Part D premiums, deductibles, coinsurance and other drug costs for people with limited income and resources. Medicare lists 2026 general income/resource limits of $23,940/$18,090 for an individual and $32,460/$36,100 for a married couple; some people qualify automatically. Check Medicare for the current rules before applying.',checked_date=DATE,recheck_by='2026-12-24',summary_es='Medicare Extra Help puede reducir primas, deducibles, coseguro y otros costos de medicamentos de la Parte D para personas con ingresos y recursos limitados. Medicare publica para 2026 límites generales de ingresos/recursos de $23,940/$18,090 para una persona y $32,460/$36,100 para una pareja casada; algunas personas califican automáticamente. Consulta Medicare para las reglas actuales antes de solicitar.')
    elif rid=='FHR-028':
        x.update(summary='HealthWell may assist insured patients when it has an open fund for the covered diagnosis and medication and the applicant meets its financial and treatment rules. HealthWell says applicants generally need insurance that covers part of treatment; funds can open or close as funding changes, so check the current disease-fund list.',checked_date=DATE,recheck_by='2026-10-25',summary_es='HealthWell puede ayudar a pacientes asegurados cuando existe un fondo abierto para el diagnóstico y medicamento cubiertos y la persona cumple sus reglas financieras y de tratamiento. HealthWell indica que, en general, se necesita seguro que cubra parte del tratamiento; los fondos pueden abrir o cerrar según cambie el financiamiento, así que consulta la lista actual de fondos por enfermedad.')
    elif rid=='FHR-029':
        x.update(summary='Patient Advocate Foundation’s TotalAssist publishes disease-specific charitable funds for eligible out-of-pocket healthcare costs, including medication costs. Its current fund list shows that fund status varies by condition and can be open or closed; check the live fund list before relying on availability.',checked_date=DATE,recheck_by='2026-10-02',summary_es='TotalAssist de Patient Advocate Foundation publica fondos caritativos por enfermedad para ciertos costos elegibles de atención, incluidos medicamentos. Su lista actual muestra que el estado varía según la enfermedad y puede estar abierto o cerrado; consulta la lista vigente antes de depender de la disponibilidad.')
    if rid in {'FHR-011','FHR-018','FHR-026','FHR-028','FHR-029'}:
        vals=[x.get(k,'') for k in ('title','need','group','area','summary','source_org')]; x['search_terms']=' '.join(str(v) for v in vals if v).lower()
        vals=[x.get(k,'') for k in ('title_es','need_es','group','area_es','summary_es','source_org')]; x['search_terms_es']=' '.join(str(v) for v in vals if v).lower()
    return x

rp=PUBLIC/'assets/resources.js'; raw=rp.read_text(); arr=json.loads(raw.split('=',1)[1].strip().rstrip(';')); arr=[patch_record(x) for x in arr]; rp.write_text('window.FH_RESOURCES = '+json.dumps(arr,ensure_ascii=False,separators=(',',':'))+';\n')
lp=PUBLIC/'assets/live-state.js'; m=re.search(r'window\.FH_LIVE_STATE\s*=\s*(\{.*\})\s*;\s*$',lp.read_text(),re.S); st=json.loads(m.group(1)); st.update(release=REL,build_date=DATE,resource_cards=29); lp.write_text('window.FH_LIVE_STATE = '+json.dumps(st,ensure_ascii=False,separators=(',',':'))+';\n')
sp=PUBLIC/'assets/styles.css'; css=sp.read_text(); addon='\n/* FH-MAIN-0.1.32 resource-preparation guidance; no brand changes. */\n.resource-prep{max-width:820px;margin:16px 0 24px;padding:16px 18px;border:1px solid var(--line);background:var(--soft)}.resource-prep h3{margin-top:0}.resource-prep ul{margin-bottom:8px;padding-left:22px}.resource-prep li{margin:6px 0}\n'
if 'FH-MAIN-0.1.32 resource-preparation' not in css: sp.write_text(css+addon)

lookup={x['id']:x for x in arr}
def card_patch(text,rid,es=False):
    pat=re.compile(r'(<article\b[^>]*data-resource-id="'+re.escape(rid)+r'"[^>]*>.*?</article>)',re.S)
    mm=pat.search(text)
    if not mm: raise SystemExit('missing card '+rid)
    seg=mm.group(1); x=lookup[rid]
    title=x.get('title_es') if es else x['title']; need=x.get('need_es') if es else x['need']; area=x.get('area_es') if es else x['area']; summary=x.get('summary_es') if es else x['summary']
    seg=re.sub(r'(<div class="need">).*?(</div>)',lambda m:m.group(1)+need+m.group(2),seg,count=1,flags=re.S)
    seg=re.sub(r'(<h3>).*?(</h3>)',lambda m:m.group(1)+title+m.group(2),seg,count=1,flags=re.S)
    seg=re.sub(r'(<p class="resource-summary">).*?(</p>)',lambda m:m.group(1)+summary+m.group(2),seg,count=1,flags=re.S)
    full=summary+(' Confirma elegibilidad y disponibilidad directamente en la fuente oficial.' if es else ' Confirm eligibility and availability directly with the official source.')
    seg=re.sub(r'(<p class="resource-full">).*?(</p>)',lambda m:m.group(1)+full+m.group(2),seg,count=1,flags=re.S)
    seg=re.sub(r'(<p class="meta">)(?:Area|Área):.*?(</p>)',lambda m:m.group(1)+(('Área: ' if es else 'Area: ')+area)+m.group(2),seg,count=1,flags=re.S)
    date=('Verificado: 17 sep. 2026 • confirma ahora' if es else 'Checked: Sep. 17, 2026 • verify now') if rid=='FHR-011' else ('Verificado: 25 sep. 2026' if es else 'Checked: Sep. 25, 2026')
    seg=re.sub(r'(<p class="meta">)(?:Checked|Verificado):.*?(</p>)',lambda m:m.group(1)+date+m.group(2),seg,count=1,flags=re.S)
    return text[:mm.start()]+seg+text[mm.end():]

def patch_help(rel,es=False):
    p=PUBLIC/rel; text=p.read_text()
    for rid in ['FHR-011','FHR-018','FHR-026','FHR-028','FHR-029']: text=card_patch(text,rid,es)
    if 'id="prepare-before-applying"' not in text:
        if es:
            prep='<section class="resource-prep" id="prepare-before-applying"><h3>Antes de solicitar ayuda</h3><ul><li>Abre la fuente oficial y confirma que el programa o fondo esté disponible hoy.</li><li>Revisa los requisitos antes de compartir información personal; algunos programas pueden pedir identificación, ingresos, cobertura u otros documentos.</li><li>Guarda el nombre del programa y cualquier número de confirmación que te entregue la fuente oficial.</li></ul><p class="fine">Franklin Helps no necesita que subas estos documentos para usar este directorio público.</p></section>'
            anchor='<div class="notice"><strong>Los detalles pueden cambiar. </strong>Confirma elegibilidad y disponibilidad en la fuente oficial.</div>'
        else:
            prep='<section class="resource-prep" id="prepare-before-applying"><h3>Before you apply</h3><ul><li>Open the official source and confirm the program or fund is available today.</li><li>Review requirements before sharing personal information; some programs may ask for identity, income, coverage or other verification.</li><li>Keep the program name and any confirmation number the official source gives you.</li></ul><p class="fine">Franklin Helps does not need you to upload these documents to use this public directory.</p></section>'
            anchor='<div class="notice"><strong>Details can change. </strong>Check official sources for current eligibility and availability.</div>'
        if anchor not in text: raise SystemExit('missing prep anchor '+rel)
        text=text.replace(anchor,anchor+prep,1)
    p.write_text(text)
patch_help('help/index.html',False); patch_help('es/help/index.html',True)

for rel in ['health.json','maintenance.json']:
    p=PUBLIC/rel; x=json.loads(p.read_text()); x['release']=REL
    if 'build_date' in x: x['build_date']=DATE
    if 'resource_cards' in x: x['resource_cards']=29
    p.write_text(json.dumps(x,indent=2)+'\n')

old={'styles.css':'sha384-0Cb1SfwrQZP3lTP+xRCI2Tfj088HFfcZp498hzde/L8bRiA+i581KxeaV6D/mj3T','resources.js':'sha384-lu1wgEyegjeXkIKyiAi/6oQFmFZ97sPcfDhrgZ7/p9jqDluHfNGHtzodao2ryrEP','live-state.js':'sha384-QBFFnXCTMgM/N1K0ytr6/I27WX9+p0kvoxc/Pj1JLbgQE7dtKH6XpctIzQnNg5MO'}
new={n:sri(PUBLIC/'assets'/n) for n in old}
for p in PUBLIC.rglob('*.html'):
    text=p.read_text()
    for n in old: text=text.replace('integrity="'+old[n]+'"','integrity="'+new[n]+'"')
    p.write_text(text)

rows=[]
for p in sorted(x for x in PUBLIC.rglob('*') if x.is_file()): rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(PUBLIC).as_posix()}\n")
tree=hashlib.sha256(''.join(rows).encode()).hexdigest()
expected='f3d810a8d30d662c318ecf08bfd078e6401c8f29fb765206a75911f5e0f160e0'
if len(rows)!=EXPECTED_FILES: raise SystemExit(f'file count {len(rows)} != {EXPECTED_FILES}')
if tree!=expected: raise SystemExit(f'tree {tree} != {expected}')
print(json.dumps({'release':REL,'files':len(rows),'public_tree_sha256':tree,'sri':new},indent=2))
