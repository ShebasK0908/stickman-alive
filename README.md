# Stickman con Vida — app para iPhone (.ipa)

**The Chosen One** de Alan Becker (*Animator vs. Animation*): un stickman
negro dibujado por código (trazo sólido, cabeza llena — el dibujo de
siempre, el que el usuario aprobó) que **cobra vida dentro de un falso
programa de animación** (lienzo blanco, barra de herramientas, línea de
tiempo) y vive ahí con voluntad propia. Swift puro + SwiftUI + Canvas,
sin dependencias ni assets externos: todo se dibuja y se anima por código.

Bundle ID: `dev.stickman.alive` · Mínimo: iOS 16.0 · Sin firmar (para SideStore).

## v4 — SOLO The Chosen One y pase de animación «como en los vídeos»

Dos cambios, pedidos por el usuario tras probar la v3 («está mal»):

1. **Un solo personaje.** Victim sale de la escena: fuera el dúo, sus
   únicos (lazo, cursor apuñalado, «a trabajar»), los planes y clips
   sociales (abrazos, sparring entre los dos, robarse la herramienta,
   sentarse juntos, descanso compartido) y su panel de cerebro. La app
   es de The Chosen One, solo. Todo lo demás de la v3 se conserva para
   él: superficies (suelo/paredes/techo/bordes), ChaseMouse y sentarse
   a mirar el dedo, arrastrado con inclinación según el tirón, lanzado,
   toolbar funcional con modos, dibujar que cobra vida, IA de defensa,
   cerebro complejo con descansos cada 2 min y sus poderes.
2. **Pase de animación sobre los vídeos de Alan Becker que envió el
   usuario** (patrones destilados en `REFERENCES.md`). Su queja
   constante es EL MOVIMIENTO, así que los clips clave se han rehecho
   con estructura de animación tradicional — anticipación → acción
   rápida → pose de impacto aguantada → settle — y timing irregular,
   en vez de ciclos uniformes:

   | Clip rehecho | Qué cambió | Patrón / vídeo |
   |---|---|---|
   | `run` | Carrera **pesada**: torso muy inclinado (cuello +16), zancada larguísima (±33), bombeo de brazos cruzando el cuerpo con codos flexionados, y por ciclo: contacto corto (snappy) → **absorción** con squash 0,92 → **impulso**/toe-off con stretch 1,05 → **fase de vuelo** larga sin ningún pie en el suelo. | TCO corriendo en **AvA 2** |
   | `walk` | Contactos que se aguantan más que las pasadas (0/.19/.40/.585 en 0,78 s), boteo con caída real al apoyar (56→51,5), balanceo contralateral amplio y cabeza con follow-through a contrafase. | Andar con peso de **AvA 1 / AvA 4** |
   | `jumpCrouch` / `jumpStretch` / `landing` / `roll` | Anticipación más larga y profunda (dos tiempos, squash 0,78, brazos muy atrás), stretch 1,17 al despegar, aterrizaje con squash 0,74 **aguantado**, overshoot y settle; rodada con manos al suelo y salida con impulso. | Saltos/caídas de **AvA 1 y AvA 2** |
   | `fallPose` | Brazos arriba en pánico leve y braceo asimétrico preparando el impacto. | Caídas de **AvA 1** |
   | `fightCombo` | Combo reescrito (3,6 s): guardia con bounce → **jab** (anticipación, golpe seco snappy, impacto aguantado, recogida lenta) → **cross** con cadera, igual → **patada frontal** con chamber → **barrido giratorio** con anticipación larga agachado. | Guerra contra el cursor en **AvA 1**; golpes con todo el cuerpo en **AvA 2** |
   | `block` / `dodgeDuck` | Bloqueo con **flinch** de impacto (le empuja atrás y se replanta); esquiva que baja de golpe, sin anticipación, y sube con cautela. | Defensa de **AvA 1** |
   | `grabFinger` | Agarrarse al cursor y **forcejear**: se cuelga, se balancea, **patea el dedo** y **intenta trepar por él** hasta que se le acaba la fuerza. | TCO/victim agarrando el cursor en **AvA 1** |
   | `grabbed` | Pataleo **frenético** (6 poses lineales, patadas alternas y a la vez, retorciéndose). | Ser arrastrado en **AvA 1** |
   | `escapeShake` | La sacudida para escapar de la caja de selección **crece en amplitud** (±2 → ±6) empujando las «paredes» de la caja. | Escape de la selección en **AvA 1** |
   | `skid` | Más echado atrás, molinete de brazos buscando equilibrio y settle largo. | Frenadas de **AvA 2** |
   | `scared` | Pánico en dos tiempos: **susto** (brinco seco con manos a la cabeza y stretch) → **temblor** con manos en alto. | Reacción al cursor en **AvA 1** |
   | `stomp` | Enfado con cuerpo: se hincha el pecho y pega **dos pisotones** con aguante de impacto. | Berrinche de **AvA 1** |
   | `powerPose` / `chargePower` / `superPunchPose` | La pose de poder **entra**: carga agachado → explota con el puño al cielo → aguanta. La carga de energía **tiembla cada vez más** (amplitud 1→3) hasta que el aura estalla. El superpuñetazo gana anticipación larga (carga máxima aguantada) e impacto clavado. | Transformaciones y golpes de **AvA 2** |

   Nota honesta: los patrones salen de los vídeos y de lo destilado en
   `REFERENCES.md`; no se ha copiado ningún frame ni asset de nadie —
   son los clips procedurales de siempre, rehechos con mejor timing y
   poses más marcadas. El resto del catálogo (idle, baile, dormir,
   esgrima, superficies de la v3, poderes…) no se ha tocado en este pase.

## v3 — DOS personajes y roaming 360° (ejemplo Shimeji superado) — *histórico: la v4 lo reduce a un solo personaje*

El usuario envió como ejemplo un Shimeji-ee fan de Alan Becker (9
personajes, 1.328 frames PNG, 51 behaviors) y pidió: *el catálogo entero
en SOLO dos personajes — The Chosen One y Victim — y mejor que el
ejemplo*. La v3 lo recrea con poses procedurales (sin copiar ni un PNG)
y le añade lo que el ejemplo no tiene: poderes reales, dibujo que cobra
vida, IA de defensa y cerebro complejo por personaje.

**Los dos personajes** (cada uno con su controlador, cerebro, impulsos
y memoria; instancias parametrizadas de la arquitectura v2):

- **The Chosen One** — negro, trazo más grueso. Poderoso y desafiante:
  travesura y energía altas. Es el ÚNICO con poderes (los de la v2:
  volar, fuego, láser, hielo, superpuñetazo, superfuerza, supervelocidad,
  crear/destruir) y con Modo Chosen One.
- **Victim** — gris oscuro, el dibujado del AvA 1. Nervioso y
  reivindicativo contra el animador (enfado base, menos sociable).
  Repertorio propio recreado de la spec: **SpinLasso** (gira el lazo
  sobre la cabeza, dibujado en Canvas), **CursorSetup + Stabbing** (se
  coloca junto a "su" cursor y lo apuñala) y **SitWhileWorking**
  (sentarse «a trabajar» picando un papel). Cuando TCO usa un poder
  delante de él, reacciona: se asusta y retrocede, se esconde tras un
  objeto o le planta cara con el lazo. Cuando Victim provoca (lazo /
  apuñalar), TCO se ríe o bloquea, sobrado.

**Sistema de superficies (el motor manda, como en la spec):** cada
personaje está anclado a una superficie (`StickSurface`): `floor`
(suelo sobre la timeline, plataformas falsas de la interfaz y trazos
del usuario, como en la v2), `wallLeft` / `wallRight` (paredes del
lienzo) y `ceiling` (techo). La gravedad depende de la superficie:
trepar sube a velocidad constante anclado a la pared; en el techo
camina **boca abajo** con el ciclo *swing* (la vista lo dibuja
invertido, ancla en el borde superior); descolgarse de pared o techo
(`dropping`) devuelve el control a la física normal y cae al suelo con
aterrizaje/rodar/mareo según impacto. Transiciones de esquina:
suelo→pared (llega caminando y hace PullUp al anclarse), pared→techo
(al coronar pasa solo a caminar boca abajo), techo→pared (al llegar al
borde baja trepando), techo/pared→suelo (descolgarse). Sin plan en una
superficie, un «autopiloto» de superficie decide: seguir trepando,
caminar por el techo o descolgarse. La parte superior de la toolbar y
la timeline se representan con el sistema de plataformas de la v2
(46/104) y los bordes de esas plataformas son donde se sienta con las
piernas colgando (`dangling`, con el ciclo de balanceo de tiempos
irregulares de la spec, patrón 8/2/5).

**Timing como la spec:** la zancada se lee en el espacio (la fase de
zancada va ligada a la velocidad real desde la v2: correr avanza
≈4,5× por ciclo que caminar con duración parecida), duraciones
irregulares a propósito en esperas/colgaduras/piernas colgando,
tropiezos con pose larga de suelo, y caídas desde el techo con poses
largas de caída.

**Social entre los dos (affordances de la spec):** *HugSearch* es el
plan social con más peso (en la spec, Freq 1000, el mayor del
catálogo): corre hacia el otro y le abraza, y el otro pasa al rol
espejo *Hugged*; *HugAffordance* (ofrecerse con los brazos abiertos);
perseguirse (*Chase* del otro) y acabar en **sparring** de broma con
los clips de pelea (el otro responde peleando o huyendo entre risas);
**robarse la herramienta** (el robado se enfada con pisotón o se ríe);
**sentarse juntos** en un borde; y separación suave para que no se
solapen. Descansos cada 2 min por personaje: si uno descansa, el otro
puede **unirse al descanso** en unos segundos o ir a **sentarse a su
lado** (o seguir a la suya).

**Interacción con el dedo, para AMBOS:** *ChaseMouse* — si el dedo
está a media distancia y sin violencia, lo persiguen corriendo (Victim
con más ganas: es «su» cursor) y al llegar se sientan a mirarlo
(*SitAndFaceMouse*, girándose hacia el dedo); en la persecución pueden
**tropezar** (*Trip*); *Dragged* con pose **pinch inclinada hacia el
lado del tirón** (como las 7 variantes −50…+50 px de la spec); *Thrown*
y toda la IA de defensa de la v2, ahora por personaje (cada uno con su
contador de acoso: el panel 🧠 muestra los dos cerebros lado a lado).
El gesto del lienzo agarra/toca al personaje **más cercano** al dedo;
los trazos del lápiz se aplican a los dos (copias idénticas, físicas
para ambos).

### Behaviors de la spec: implementados y fuera (honesto)

Implementados (51 del catálogo, adaptados): ChaseMouse,
SitAndFaceMouse, Dragged (pinch por lado), Thrown, Fall, Trip,
WalkAlong/RunAlongFloor, WalkAndSit (planes caminar→sentarse),
GrabBottomWall + RunAndGrabWall (llegar a la esquina y anclarse),
HoldOntoWall, FallFromWall, ClimbHalfwayAlongWall, ClimbAlongWall,
HoldOntoCeiling, FallFromCeiling, ClimbAlongCeiling (swing boca
abajo), segundo «suelo» elevado y vida sobre él (plataformas
timeline/botones: caminar, sentarse en sus bordes, piernas colgando),
StandUp, SitDown, SitWhileDanglingLegs, LieDown, Dance (en la spec
TCO/Victim no lo tienen; aquí lo reciben los dos, como pidió el
usuario), HugAffordance, HugSearch, HuggingSolid, HuggedSolid,
SpinLasso, Stabbing, CursorSetup/CursorHate, SitWhileWorking,
PullUp (al borde y al anclarse a la pared).

Adaptaciones y lo que queda fuera, y por qué:

- **Familia «IE» (ventana activa del escritorio):** en un iPhone no hay
  ventanas; su equivalente en escena son las plataformas de la interfaz
  (timeline y botones), que ya actúan como segundo suelo con bordes
  donde sentarse y desde donde saltar. `ClimbIEBottom` (boca abajo por
  el borde *inferior* de una ventana) no tiene equivalente físico en la
  escena y **no** se implementa como tal; el desplazamiento boca abajo
  sí existe, pero en el techo (`ClimbAlongCeiling`).
- **PullUpShimeji / Breed (invocar/multiplicar personajes):** fuera a
  propósito — la escena tiene exactamente dos personajes por decisión
  del usuario, no una población de hasta 50.
- **`couch`:** era un set decorativo de 1 frame sin behavior propio;
  su función (descanso «en casa») la cubren la silla dibujada y el
  descanso obligatorio.
- El agarre a pared en plena caída (`GrabWall` dentro de Thrown) se
  aproxima con el deslizado por la pared de la v2, no con anclaje
  completo a media caída.

Se mantiene TODO lo de la v2: toolbar real con modos
cursor/lápiz/goma, trazos persistentes y físicos, dibujo que cobra
vida (objetos y criaturas de AvA4), cerebro complejo con impulsos,
memoria y planes por personaje, IA de defensa, y descanso obligatorio
cada 2 minutos. Sin archivos nuevos: la v3 evoluciona los 7 ficheros
Swift existentes, así que el `project.pbxproj` no cambia.

## v2 — qué se corrigió tras probar la v1 en el iPhone

Feedback real del usuario: *«No me deja interactuar con los botones o
opciones a la izquierda para dibujar o borrar cosas, y sus animaciones no
se parecen en nada a las del vídeo»*. Causas encontradas en el código v1:

1. **La toolbar izquierda era decorativa:** un `VStack` de imágenes SF
   Symbols sin ningún `Button`, y el lienzo tenía un
   `DragGesture(minimumDistance: 0)` que lo interpretaba todo como
   cursor/arrastre. No existía modo lápiz/goma ni trazos del usuario.
   **Arreglo:** toolbar con **botones SwiftUI reales** (≥52 pt, modo
   activo resaltado en naranja) en una columna *hermana* del lienzo,
   fuera de su gesto: **Cursor, Lápiz, Goma, Borrar todo y Deshacer**,
   más una fila de estado que dice el modo actual («Modo: Lápiz — dibuja
   con el dedo»). Un único gesto en el lienzo, ramificado por modo:
   lápiz = trazos libres **persistentes y físicos** (sus tramos casi
   horizontales son plataformas: puede aterrizar, caminar y subirse a
   lo que dibujes), goma = arrastrar sobre trazos u objetos para
   borrarlos, cursor = agarrar/lanzar/tocar al stickman.
2. **Las animaciones eran poses sueltas** calculadas con `sin(phase*k)`.
   **Arreglo:** sistema nuevo por **keyframes** con principios clásicos
   (ver «Animación» y «Locomoción» más abajo).

### Locomoción (reescrita desde cero)

Ya no hay `x += velocidad fija`: hay velocidad con **aceleración y
frenada con peso**, fase de zancada **ligada a la velocidad real**
(a más velocidad, ciclo más rápido y zancada más larga), **blend
caminar↔correr** por velocidad, **derrape con polvo** al frenar en seco
o cambiar de sentido, **giro con paso cruzado**, salto con
**anticipación** (se agacha antes de despegar), vuelo con stretch,
caída con piernas abiertas, y aterrizajes según impacto: squash suave,
**rodar** si cae fuerte y **mareo** si cae muy fuerte. También se
desliza frenando cuando choca contra un borde en el aire.

### Pequeña IA de interacción / defensa

- **Percibe tu dedo:** distancia, velocidad y velocidad de acercamiento
  (`FingerTracker`), y distingue un toque amistoso (lento, único) de
  persecución o agarres repetidos (`InteractionBrain`).
- **Decide en tiempo real:** acercarse curioso, saludar, **huir
  corriendo**, esquivar **agachándose / rodando / saltando por encima
  del dedo**, **bloquear** con los brazos, **agarrar tu dedo** y
  forcejear (el cursor se tambalea), **contraatacar** con el combo de
  artes marciales, **esconderse** tras un objeto dibujado (que pasa a
  dibujarse delante de él), usar un **bloque o la espada como
  escudo/arma**, y si el acoso sigue, un **mini Modo Chosen One**
  (superpuñetazo con onda de choque).
- **Aprende en la sesión:** el contador de **acoso** (visible en el
  panel 🧠) sube con agarres, persecuciones y toques bruscos, y decae
  con calma; dibujarle algo o jugar suave lo baja y vuelve a ser
  curioso/amistoso. Si le sujetas el dedo más de ~2,2 s, **se sacude y
  escapa de la caja de selección solo**.
- **Se ve:** bocadillos al decidir («¡eh!», «no me atrapas», «vale,
  jugamos» → saludo), guardia visible al sentirse amenazado y el panel
  muestra su última decisión de IA y el nivel de acoso.

### Animación por keyframes (`StickmanAnimation.swift`)

Cada animación es un **clip de datos** (duración, keyframes de ángulos/
posición raíz sobre el esqueleto articulado, easing por tramo) que la
vista muestrea; la locomoción y el salto se eligen por fases físicas.
Catálogo: despertar (estirarse, bostezar, frotarse, mirar confundido),
idle vivo (respiración, balanceo, rascarse, mirar), caminar contralateral
con boteo, correr inclinado con bombeo, derrape, giro cruzado, salto por
fases (anticipación → stretch → caída → squash), voltereta/rodar,
aterrizaje, mareo, pelea completa (guardia, puñetazos 1-2, patada,
patada giratoria, bloqueo), esquivas, agarrar el dedo, ser agarrado
(pataleo), escapar de la caja, ser aplastado, ser lanzado (brazos
aspas), deslizarse por la pared, señalar no — encogerse de hombros,
pulgar arriba, negar, reír, pisotón enfadado, asustarse con temblor,
sentarse aburrido con la cabeza en la mano, dormir tumbado, celebrar,
bailar (pasos laterales, giro y moonwalk), dibujar con el lápiz grande
a dos manos, frotar la goma, esgrima (estocada y molinete), martillo,
trepar, y Chosen One: vuelo tipo superman, cargar energía agachado con
aura, aliento de fuego inclinado, láser con retroceso, superpuñetazo
con paso enorme, superfuerza temblorosa. Las criaturas de AvA4
(pajarito que aletea y vuela en círculos, perrito que trota y le sigue)
se animan con sus propios ciclos (`CreatureAnimation`).

## No es una marioneta: tiene LIBERTAD

Los botones son **sugerencias**, no órdenes. Según su humor, a veces obedece,
a veces niega con la cabeza («no, ahora no»), y a veces hace otra cosa porque
le apetece («¡yo quiero la espada!»).

### Su cerebro (complejo)

- **Percepción:** dónde está tu dedo/cursor, qué objetos dibujados siguen
  vivos, qué partes de la interfaz puede alcanzar, cuánto hace que no le
  haces caso y dónde está él.
- **Impulsos que compiten** (0–100, evolucionan solos): energía, curiosidad,
  ganas de jugar, travesura, sociabilidad, aburrimiento y enfado.
- **Emoción derivada** de los impulsos: tranquilo, contento, curioso,
  travieso, aburrido, enfadado, furioso o con sueño. Se ve en la barra superior.
- **Memoria corta:** recuerda si le has molestado mucho (→ más peleas y más
  Modo Chosen One) o si has jugado bien con él (→ más sociable). La memoria
  se va desvaneciendo con el tiempo.
- **Planificador de secuencias:** no hace acciones sueltas, hace *planes* de
  varios pasos con cola de acciones, por ejemplo:
  - *Construir mi rincón:* dibujar silla → dibujar mesa → acercarse → sentarse.
  - *Explorar la interfaz:* ir → **trepar a la línea de tiempo** → curiosear
    una herramienta robada → bajar → **subirse a los botones** → presumir.
  - *Entrenar como Chosen One:* pose de poder → volar → láser a un blanco →
    fuego → aterrizar orgulloso.
  - *Dibujar un amigo:* dibuja un segundo stickman (azul) y juega/saluda con él.
  Si le interrumpes (un toque, un arrastre), puede **retomar el plan o
  abandonarlo** según su humor.
- **Actividad continua:** nunca está totalmente quieto fuera de los descansos.
  Respira, parpadea, mira a los lados, cambia el peso, se rasca la cabeza,
  bosteza… (micro-animaciones; el panel 🧠 muestra qué está haciendo).
- **Descanso OBLIGATORIO cada 2 minutos:** un temporizador de actividad de
  120 s. Al cumplirse, pausa su plan, se dibuja una silla si no tiene, se
  sienta a descansar **15–20 s** («descanso...», recupera energía, mini-siesta
  con «zzz» ocasional) y después **se levanta solo**: retoma el plan pausado
  si aún le apetece o genera uno nuevo.

**Panel 🧠 (opcional):** botón en la barra superior que muestra sus impulsos
con barras, su emoción, su plan actual, su micro-actividad, lo que piensa y
cuánto falta para su próximo descanso.

### Lo que hace por su cuenta

Deambula y explora toda la escena, trepa por la línea de tiempo y los botones,
usa herramientas de la barra por su cuenta, y **dibuja sus propios objetos**:
una espada para hacer esgrima, una pelota para jugar solo, una silla y una
mesa para su rincón, una puertita/casa, y un amigo. Si no pasa nada se aburre,
bosteza y se sienta; si está contento, baila o saluda solo.

### Tu dedo es el cursor del animador

- Tocar cerca de él: se asusta y esquiva.
- Tocar a media distancia: se encara y **pelea con tu dedo** (y si le tocas
  mucho, se enfada, lo agarra y puede entrar en Modo Chosen One).
- Arrastrarlo agarrándolo: lo mueves y al soltar **sale lanzado con física**
  (gravedad incluida). Si lo lanzas muy fuerte, se enfada: «¡no soy un juguete!»

## Poderes como The Chosen One

Estructurados en código como `enum Power`, con un sistema de partículas
simple en Canvas (`ParticleSystem`):

| Poder | Qué hace |
|---|---|
| **Volar** | Despega, vuela por el lienzo dejando estela de partículas |
| **Fuego** | Llamas por las manos que **queman un objeto dibujado** (queda chamuscado) |
| **Láser por los ojos** | Rayos rojos que **cortan un objeto dibujado por la mitad** |
| **Hielo** | Congela un objeto (queda azul, bajo hielo) o un tramo del suelo |
| **Superpuñetazo** | Onda de choque: **sacude toda la interfaz** y empuja los objetos |
| **Superfuerza** | **Levanta un bloque morado de la interfaz** sobre su cabeza y lo mueve de sitio |
| **Supervelocidad** | Corre dejando **imágenes fantasma** |
| **Crear / destruir** | Energía que crea un objeto nuevo o desintegra uno existente |

**Modo Chosen One:** no es solo un botón. Su cerebro lo activa por su cuenta
cuando la travesura o el enfado suben mucho, cuando recuerda que le han
molestado, o cuando quiere lucirse: dura unos segundos, con **aura amarilla**
e indicador «⚡ CHOSEN ONE» en la barra superior, y encadena poderes en un
plan (entrenar / lucirse). El botón «⚡ Chosen One» de la barra de sugerencias
también es solo una sugerencia: a veces lo ignora («hoy no me apetece lucirme»).

## Inicio: «Darle vida»

Al abrir la app el stickman está **dibujado e inmóvil** (gris). El botón
**«▶ Darle vida»** muestra una consola falsa de código que se escribe sola
— broma en homenaje al vídeo de referencia, que era un tutorial falso
animado a propósito, sin código real — y entonces despierta y empieza a
vivir por su cuenta.

## Cómo se compila el .ipa

Sin Mac propio: **GitHub Actions**.

1. Sube este proyecto a un repositorio de GitHub (tal cual, con la carpeta
   `.github/workflows/`).
2. El workflow **«Build iOS IPA (sin firmar)»** se lanza solo al subir a
   `main` o a mano desde la pestaña *Actions*.
3. En un runner `macos-latest` ejecuta `./build.sh`:
   `xcodebuild` compila el proyecto `Stickman.xcodeproj` (esquema `Stickman`,
   Release, SDK iphoneos) con `CODE_SIGNING_ALLOWED=NO`, y
   `./package-ipa.sh` empaqueta `Payload/Stickman.app` en **`Stickman.ipa`**
   sin firmar.
4. El .ipa queda como **artifact** de la ejecución y además se publica en la
   **Release `app-v1`** del repositorio.

El `Info.plist` es real y completo (bundle ID `dev.stickman.alive` escrito,
sin marcadores sin sustituir).

## Instalar con SideStore

1. Descarga `Stickman.ipa` de la Release `app-v1` (o del artifact de Actions).
2. Abre **SideStore** en el iPhone → pestaña *My Apps* → botón **+** →
   elige `Stickman.ipa`.
3. Espera a que se instale y abre **Stickman** desde la pantalla de inicio.
   (Como toda app con SideStore, hay que refrescarla cada 7 días desde el
   propio SideStore conectado a la misma Wi-Fi/VPN que uses para refrescar.)

## Estructura del código

- `Stickman/StickmanApp.swift` — Punto de entrada `@main`.
- `Stickman/ContentView.swift` — La escena/programa de animación falso,
  gestos táctiles (agarre/toque), consola falsa de «Darle vida», barra
  de sugerencias y panel 🧠 (v4: un solo cerebro, el de TCO).
- `Stickman/StickmanBrain.swift` — El cerebro: `CharacterKind` (v4:
  solo `chosenOne`) y `StickSurface` (v3), `Perception`, `Drives`,
  `Emotion`, `ShortMemory`, `Plan`/`PlanStep` (con destino x /
  superficie) y `PlanLibrary` (planes v2 + roaming 360).
- `Stickman/StickmanEngine.swift` — `StickmanController` (una única
  instancia, TCO): física (gravedad, saltos, lanzamientos), motor de
  superficies 360°, ejecutor de planes, ciclo de descanso de 120 s,
  reacciones al dedo y sugerencias con probabilidad de obediencia.
- `Stickman/StickmanPowers.swift` — `enum Power`, objetos dibujados
  (`DrawnObject`) y el `ParticleSystem`.
- `Stickman/StickmanView.swift` — Dibujo procedural en Canvas:
  esqueleto articulado, cabeza llena, poses por acción/poder, inversión
  en el techo, objetos, amigo, aura, fantasmas, láser/fuego/hielo y
  partículas.
- `Stickman/StickmanAnimation.swift` — Clips de keyframes (v2 + v3:
  superficies y dangle irregular + pase v4 de locomoción/pelea).
- `Stickman/Info.plist`, `Stickman/Assets.xcassets` — Configuración e icono
  (catálogo vacío: la app compila sin icono personalizado).
- `Stickman.xcodeproj` — Proyecto Xcode (iOS 16.0, Swift 5).
- `build.sh` / `package-ipa.sh` — Compilación sin firma y empaquetado .ipa.
- `.github/workflows/build-ipa.yml` — CI en macOS que produce el .ipa.
