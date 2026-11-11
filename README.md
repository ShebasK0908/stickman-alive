# Stickman con Vida — app para iPhone (.ipa)

Un stickman naranja de cabeza hueca, como The Second Coming de Alan Becker
(*Animator vs. Animation*), que **cobra vida dentro de un falso programa de
animación** (lienzo blanco, barra de herramientas, línea de tiempo) y vive ahí
con voluntad propia. Swift puro + SwiftUI + Canvas, sin dependencias ni assets
externos: todo se dibuja y se anima por código.

Bundle ID: `dev.stickman.alive` · Mínimo: iOS 16.0 · Sin firmar (para SideStore).

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
  gestos táctiles, consola falsa de «Darle vida», barra de sugerencias y
  panel 🧠.
- `Stickman/StickmanBrain.swift` — El cerebro: `Perception`, `Drives`,
  `Emotion`, `ShortMemory`, `Plan`/`PlanStep` y `PlanLibrary`.
- `Stickman/StickmanEngine.swift` — `StickmanController`: física
  (gravedad, saltos, lanzamientos), ejecutor de planes, ciclo de descanso
  de 120 s, reacciones al dedo y sugerencias con probabilidad de obediencia.
- `Stickman/StickmanPowers.swift` — `enum Power`, objetos dibujados
  (`DrawnObject`) y el `ParticleSystem`.
- `Stickman/StickmanView.swift` — Dibujo procedural en Canvas: esqueleto
  articulado, poses por acción/poder, objetos, amigo, aura, fantasmas,
  láser/fuego/hielo y partículas.
- `Stickman/Info.plist`, `Stickman/Assets.xcassets` — Configuración e icono
  (catálogo vacío: la app compila sin icono personalizado).
- `Stickman.xcodeproj` — Proyecto Xcode (iOS 16.0, Swift 5).
- `build.sh` / `package-ipa.sh` — Compilación sin firma y empaquetado .ipa.
- `.github/workflows/build-ipa.yml` — CI en macOS que produce el .ipa.
