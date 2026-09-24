from pathlib import Path
import json, hashlib, base64, re

SITE=Path('public')
RELEASE='FH-MAIN-0.1.31'
DATE='2026-09-24'


def replace_once(path, old, new, label):
    p=Path(path); s=p.read_text()
    if old not in s:
        raise SystemExit(f'missing anchor {label} in {p}')
    p.write_text(s.replace(old,new,1))

# Public live-state truth: fix stale 0.1.28/26-resource public state.
live={
  'release':RELEASE,
  'role_id':'FH_MAIN_PRODUCT',
  'build_date':DATE,
  'community':'FH-TN-FRANKLIN',
  'resource_navigation':'AVAILABLE',
  'resource_cards':29,
  'medication_access':'CLOSED_INTAKE_NOT_OPEN',
  'giving':'CLOSED_STRIPE_PENDING',
  'sponsor_payments':'CLOSED_STRIPE_PENDING',
  'community_host':'CLOSED_ENROLLMENT_NOT_OPEN',
  'participants_published':0,
  'spanish_parity':'CORE_PUBLIC_PARITY',
  'franklin_only':True,
  'tax_wording':'NO_TAX_DEDUCTIBILITY_CLAIM_WITHOUT_DOCUMENTED_AUTHORITY',
  'public_reporting':'DOCUMENTED_COMPLETED_RESULTS_ONLY',
  'outreach':'OUTSIDE_MAIN_PRODUCT_NOT_OPENED_BY_RELEASE'
}
live_path=SITE/'assets/live-state.js'
live_path.write_text('window.FH_LIVE_STATE = '+json.dumps(live,separators=(',',':'))+';\n')
health={
  'service':'franklin-helps-main-product','community':'FH-TN-FRANKLIN','release':RELEASE,
  'build_date':DATE,'health':'ok','franklin_only':True,'resource_navigation':'available',
  'resource_cards':29,'contains_private_state':False
}
(SITE/'health.json').write_text(json.dumps(health,indent=2)+'\n')
(SITE/'maintenance.json').write_text(json.dumps({'release':RELEASE,'public_site':'available','resource_navigation':'available'},indent=2)+'\n')

# Homepage: restore compact present-tense action module, adapted to current Medication Access scope.
home=SITE/'index.html'
needle='</section>\n<section class="section alt"><div class="local-inline-grid">'
module='''</section>
<section class="section current-actions"><span class="eyebrow">What can I do today?</span><h2>Start with the path that fits you.</h2><div class="grid2"><article class="card"><h3>I need help</h3><p>Search 29 local and public resources, including prescription-cost help.</p><a class="text-link" href="help/index.html">Find local help →</a></article><article class="card"><h3>I run a local business or organization</h3><p>Learn how free Community Host participation can help neighbors find Franklin Helps.</p><a class="text-link" href="host/index.html">Explore Community Host →</a></article><article class="card"><h3>I want to support Franklin Helps</h3><p>Giving and sponsorship payments are not open yet. See how support is intended to work.</p><a class="text-link" href="give/index.html">See giving status →</a></article><article class="card"><h3>I want to understand the model</h3><p>See how Franklin Helps checks existing prescription help before considering local assistance.</p><a class="text-link" href="how/index.html">How Franklin Helps works →</a></article></div></section>
<section class="section alt"><div class="local-inline-grid">'''
replace_once(home,needle,module,'homepage current-actions insertion')

home_es=SITE/'es/index.html'
module_es='''</section>
<section class="section current-actions"><span class="eyebrow">¿Qué puedo hacer hoy?</span><h2>Empieza con la opción que te corresponde.</h2><div class="grid2"><article class="card"><h3>Necesito ayuda</h3><p>Busca 29 recursos locales y públicos, incluida ayuda con costos de recetas.</p><a class="text-link" href="help/index.html">Encontrar ayuda local →</a></article><article class="card"><h3>Tengo un negocio u organización local</h3><p>Conoce cómo la participación gratuita como Anfitrión Comunitario puede ayudar a vecinos a encontrar Franklin Helps.</p><a class="text-link" href="host/index.html">Explorar Anfitrión Comunitario →</a></article><article class="card"><h3>Quiero apoyar a Franklin Helps</h3><p>Las donaciones y los pagos de patrocinio todavía no están abiertos. Conoce cómo se espera que funcione el apoyo.</p><a class="text-link" href="give/index.html">Ver estado de donaciones →</a></article><article class="card"><h3>Quiero entender el modelo</h3><p>Conoce cómo Franklin Helps revisa primero la ayuda existente para recetas antes de considerar asistencia local.</p><a class="text-link" href="how/index.html">Cómo funciona Franklin Helps →</a></article></div></section>
<section class="section alt"><div class="local-inline-grid">'''
replace_once(home_es,needle,module_es,'Spanish homepage current-actions insertion')

# Find Help: human language for broad navigation filter.
replace_once(SITE/'help/index.html','data-filter="Navigation" type="button">Navigation</button>','data-filter="Navigation" type="button">Not sure where to start?</button>','help navigation label')
replace_once(SITE/'es/help/index.html','data-filter="Navigation" type="button">Navegación</button>','data-filter="Navigation" type="button">¿No sabes por dónde empezar?</button>','Spanish help navigation label')

# Giving: make the closed state impossible to miss while preserving explanatory content.
give=SITE/'give/index.html'
replace_once(give,'<span class="eyebrow">Support Franklin Helps</span><h1>Help local support reach prescription costs that other practical help did not cover.</h1><p class="lede">Franklin Helps checks insurance, public programs and other practical help first. Charitable support can then focus on an eligible prescription cost that remains.</p>',
'''<span class="eyebrow">Giving status</span><h1>Giving is not open yet.</h1><p class="lede">Franklin Helps is preparing one-time and monthly giving so local support can help with eligible prescription costs that practical programs did not cover.</p><div class="notice giving-closed-note"><strong>No payment is collected on this page today.</strong> Secure checkout, receipts, recurring-gift management, refund/error handling and exact legal/tax wording must be verified before giving opens.</div>''','give closed-state hero')
give_es=SITE/'es/give/index.html'
s=give_es.read_text()
m=re.search(r'<h1>.*?</h1><p class="lede">.*?</p>',s)
if not m: raise SystemExit('missing Spanish give hero')
new='''<h1>Las donaciones todavía no están abiertas.</h1><p class="lede">Franklin Helps está preparando opciones de una sola vez y mensuales para que el apoyo local pueda ayudar con costos elegibles de recetas que otros programas prácticos no cubrieron.</p><div class="notice giving-closed-note"><strong>Hoy no se cobra ningún pago en esta página.</strong> Antes de abrir las donaciones deben verificarse el pago seguro, recibos, administración de aportes recurrentes, reembolsos/errores y el lenguaje legal y tributario exacto.</div>'''
give_es.write_text(s[:m.start()]+new+s[m.end():])

# Host: restore what-we-ask + Host/Sponsor separation lost in later refactors.
host=SITE/'host/index.html'
insert='''<section class="section alt"><span class="eyebrow">What Franklin Helps asks</span><h2>Keep the role simple and accurate.</h2><div class="grid2"><article class="card"><h3>Use current approved materials</h3><p>Display Franklin Helps signs and QR materials as provided and replace outdated materials when updated versions are issued.</p></article><article class="card"><h3>Keep the relationship clear</h3><p>Hosting does not mean endorsement, sponsorship, medical guidance or authority to decide who receives assistance.</p></article></div></section><section class="section"><span class="eyebrow">Community Host vs Sponsor</span><h2>Hosting is free. Sponsorship is separate.</h2><div class="table-wrap"><table class="status-table"><thead><tr><th>Community Host</th><th>Sponsor</th></tr></thead><tbody><tr><td>Designed to be free</td><td>Optional financial support after sponsorship opens</td></tr><tr><td>Displays approved local-help materials</td><td>Supports the Franklin Helps mission financially</td></tr><tr><td>No resident or donor list access</td><td>No resident or donor list access</td></tr><tr><td>Does not imply endorsement</td><td>Recognition only under approved terms</td></tr></tbody></table></div><p class="fine">Live Community Host enrollment and sponsorship payments are not opened by this release.</p></section>'''
replace_once(host,'</main>',insert+'</main>','host audit follow-through')
host_es=SITE/'es/host/index.html'
insert_es='''<section class="section alt"><span class="eyebrow">Lo que pide Franklin Helps</span><h2>Mantener el papel sencillo y preciso.</h2><div class="grid2"><article class="card"><h3>Usar materiales actuales y aprobados</h3><p>Mostrar letreros y materiales QR de Franklin Helps como se entregan y reemplazar materiales antiguos cuando se emitan versiones nuevas.</p></article><article class="card"><h3>Mantener clara la relación</h3><p>Ser anfitrión no significa aval, patrocinio, orientación médica ni autoridad para decidir quién recibe asistencia.</p></article></div></section><section class="section"><span class="eyebrow">Anfitrión Comunitario vs Patrocinador</span><h2>Ser anfitrión es gratuito. El patrocinio es aparte.</h2><div class="table-wrap"><table class="status-table"><thead><tr><th>Anfitrión Comunitario</th><th>Patrocinador</th></tr></thead><tbody><tr><td>Diseñado para ser gratuito</td><td>Apoyo financiero opcional cuando se abra el patrocinio</td></tr><tr><td>Muestra materiales aprobados de ayuda local</td><td>Apoya financieramente la misión de Franklin Helps</td></tr><tr><td>Sin acceso a listas de residentes o donantes</td><td>Sin acceso a listas de residentes o donantes</td></tr><tr><td>No implica aval</td><td>Reconocimiento solo bajo términos aprobados</td></tr></tbody></table></div><p class="fine">Esta versión no abre la inscripción real de Anfitriones Comunitarios ni los pagos de patrocinio.</p></section>'''
replace_once(host_es,'</main>',insert_es+'</main>','Spanish host audit follow-through')

# Sponsor: explain useful possibilities, but keep payments/terms closed and owner-controlled.
sponsor=SITE/'sponsor/index.html'
sponsor_insert='''<section class="section alt"><span class="eyebrow">Program status</span><h2>Sponsorship payments are not open yet.</h2><p class="lede">Franklin Helps is preparing the sponsorship path. No price, tier, promised reach or recognition package is offered on this page today.</p></section><section class="section"><span class="eyebrow">Possible ways businesses may support</span><h2>Useful options can be added only after their terms are approved.</h2><div class="grid3"><article class="card"><h3>Local program support</h3><p>Support medication-access work and responsible program operations after financial activation.</p></article><article class="card"><h3>Employee engagement</h3><p>Future approved options may include workplace participation or matching-gift awareness without sharing employee donor information.</p></article><article class="card"><h3>Approved community recognition</h3><p>Recognition may be offered only after real sponsorship and approved terms; acknowledgment does not mean endorsement.</p></article></div></section>'''
replace_once(sponsor,'</main>',sponsor_insert+'</main>','sponsor audit follow-through')
sponsor_es=SITE/'es/sponsor/index.html'
sponsor_insert_es='''<section class="section alt"><span class="eyebrow">Estado del programa</span><h2>Los pagos de patrocinio todavía no están abiertos.</h2><p class="lede">Franklin Helps está preparando la vía de patrocinio. Hoy esta página no ofrece precios, niveles, alcance prometido ni paquetes de reconocimiento.</p></section><section class="section"><span class="eyebrow">Formas posibles de apoyo empresarial</span><h2>Las opciones útiles se añadirán solo después de aprobar sus términos.</h2><div class="grid3"><article class="card"><h3>Apoyo al programa local</h3><p>Apoyar el trabajo de acceso a medicamentos y operaciones responsables después de la activación financiera.</p></article><article class="card"><h3>Participación de empleados</h3><p>Opciones futuras aprobadas pueden incluir participación laboral o información sobre aportes equivalentes sin compartir datos de donantes empleados.</p></article><article class="card"><h3>Reconocimiento comunitario aprobado</h3><p>El reconocimiento puede ofrecerse solo después de un patrocinio real y bajo términos aprobados; un agradecimiento no significa aval.</p></article></div></section>'''
replace_once(sponsor_es,'</main>',sponsor_insert_es+'</main>','Spanish sponsor audit follow-through')

# Get Involved: independent volunteer discovery; no Franklin Helps volunteer operation implied.
gi=SITE/'get-involved/index.html'
gi_insert='''<section class="section alt"><span class="eyebrow">Volunteer locally</span><h2>Want to give time instead of money?</h2><p class="lede">Franklin Helps does not run a broad volunteer program. Independent local organizations can help you find current ways to serve.</p><div class="grid2"><article class="card"><h3>Franklin Tomorrow</h3><p>Its Engage page points residents toward civic and volunteer opportunities in Franklin.</p><a class="text-link" href="https://franklintomorrow.org/engage/" rel="noopener noreferrer" target="_blank">Explore Franklin Tomorrow ↗</a></article><article class="card"><h3>GivingMatters</h3><p>Browse reviewed Middle Tennessee nonprofit profiles by cause and community to find organizations whose work fits your interests.</p><a class="text-link" href="https://givingmatters.cfmt.org/" rel="noopener noreferrer" target="_blank">Explore GivingMatters ↗</a></article></div><p class="fine">These are independent resources, not Franklin Helps partners unless separately confirmed. Opportunities and availability can change.</p></section>'''
replace_once(gi,'</main>',gi_insert+'</main>','get involved volunteer discovery')
gi_es=SITE/'es/get-involved/index.html'
gi_insert_es='''<section class="section alt"><span class="eyebrow">Voluntariado local</span><h2>¿Quieres aportar tiempo en vez de dinero?</h2><p class="lede">Franklin Helps no opera un programa amplio de voluntariado. Organizaciones locales independientes pueden ayudarte a encontrar formas actuales de servir.</p><div class="grid2"><article class="card"><h3>Franklin Tomorrow</h3><p>Su página Engage orienta a residentes hacia oportunidades cívicas y de voluntariado en Franklin.</p><a class="text-link" href="https://franklintomorrow.org/engage/" rel="noopener noreferrer" target="_blank">Explorar Franklin Tomorrow ↗</a></article><article class="card"><h3>GivingMatters</h3><p>Explora perfiles revisados de organizaciones sin fines de lucro de Middle Tennessee por causa y comunidad.</p><a class="text-link" href="https://givingmatters.cfmt.org/" rel="noopener noreferrer" target="_blank">Explorar GivingMatters ↗</a></article></div><p class="fine">Son recursos independientes, no socios de Franklin Helps salvo confirmación aparte. Las oportunidades y la disponibilidad pueden cambiar.</p></section>'''
replace_once(gi_es,'</main>',gi_insert_es+'</main>','Spanish get involved volunteer discovery')

# Impact: reconcile public count + plainer evidence language.
impact=SITE/'impact/index.html'
s=impact.read_text().replace('contains 26 Franklin and Williamson County resources','contains 29 Franklin and Williamson County resources')
s=s.replace('supported by evidence.','supported by a clear record.')
s=s.replace('<strong>Evidence path</strong><span>The record supporting the result.</span>','<strong>Supporting record</strong><span>The record behind the result.</span>')
impact.write_text(s)
impact_es=SITE/'es/impact/index.html'
s=impact_es.read_text().replace('contiene 26 recursos','contiene 29 recursos')
s=s.replace('respaldarse con evidencia.','respaldarse con un registro claro.')
s=s.replace('<strong>Evidencia</strong><span>El registro que respalda el resultado.</span>','<strong>Registro de respaldo</strong><span>El registro detrás del resultado.</span>')
impact_es.write_text(s)

# Transparency: remove process jargon from public-facing model explanation.
replace_once(SITE/'transparency/index.html','Apply program rules, controlled payment and documented reporting.','Confirm eligibility, use a controlled payment method and keep a record of what was provided.','transparency plain language')
replace_once(SITE/'es/transparency/index.html','Aplicar reglas, pago controlado y reportes documentados.','Confirmar elegibilidad, usar un método de pago controlado y mantener un registro de lo proporcionado.','Spanish transparency plain language')

# Update live-state.js SRI in every HTML page.
sri='sha384-'+base64.b64encode(hashlib.sha384(live_path.read_bytes()).digest()).decode()
pat=re.compile(r'integrity="sha384-[^"]+" src="([^"]*assets/live-state\.js)"')
htmls=list(SITE.rglob('*.html'))
count=0
for p in htmls:
    s=p.read_text()
    s2,n=pat.subn(lambda m:f'integrity="{sri}" src="{m.group(1)}"',s)
    if n:
        p.write_text(s2); count+=n
if count < 40:
    raise SystemExit(f'live-state SRI replacements unexpectedly low: {count}')
print(json.dumps({'release':RELEASE,'live_state_sri':sri,'html_sri_references_updated':count},indent=2))
