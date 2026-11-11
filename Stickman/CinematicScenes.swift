import Foundation
import CoreGraphics

// MARK: - Las 6 cinematicas de The Second Coming, como DATOS
//
// Guiones PROPIOS del proyecto (los de CINEMATICS_SPEC.md), interpretados
// por CinematicPlayer (CinematicEngine.swift). Ninguna escena copia una
// escena de las peliculas: son situaciones nuestras —nacer, romper su
// caja, pelearse con el dedo, despertar, sonar, dibujar juntos—.
//
// COREOGRAFIA = BIBLIA v6 (CHANGELOG-ANIM.md): cada tramo de accion dura
// un numero entero de bucles del clip que lo interpreta, para que los
// holds y el squash caigan donde el pase v6 los puso:
//   run 0.60 (contactos 0.00/0.30) · walk 0.80 · idle 4.8 · wakeUp 2.8
//   fightCombo 3.6 — impactos a +0.41 (jab 1), +0.64 (jab 2), +1.04
//     (cross), +1.67 (patada), +2.18 (barrido); la haptica y las chispas
//     de las escenas caen EXACTAMENTE en esas marcas de cada ciclo.
//   block 0.9 (los pies derrapan al parar) · hitReact 1.15 · getUp 1.05
//   grabFinger 1.9 · escapeShake 2.6 (3 fases dentro del propio clip:
//     flojo -> empuja "paredes" -> violencia maxima -> reseteo visible)
//   escapeBurst 0.85 · chargePower 1.9 (el aura ESTALLA a +1.62)
//   firePose 1.1 (descarga a +0.40) · laserPose 1.0 (disparo a ~+0.34)
//   superPunchPose 1.15 (impacto a +0.58, vibracion +0.58...+0.70)
//   flyPose 1.2 · flyDash 0.7 · landing 0.55 · sleep 4.2 · celebrate 0.9
//   thumbsUp 1.1 · wave 1.0 · laugh 0.9 · proud 1.8 · powerPose 1.8
//   sit 2.6 · drawWithPencil 1.0 · hammering 0.9 · scared 0.85
// Los poderes se usan con poseSource .clip(clip(forPower:)) — el clip
// exacto del poder — mientras el beat .setPower enciende el efecto
// visual de la vista principal (llama, rayo, onda de choque).

enum CinematicCatalog {
    static let all: [CinematicScene] = [
        nacimiento, escapeDeLaCaja, dueloConElDedo,
        despertarSecondComing, elSueno, dibujamosJuntos,
    ]

    static func scene(_ id: CinematicSceneID) -> CinematicScene {
        switch id {
        case .nacimiento: return nacimiento
        case .escapeDeLaCaja: return escapeDeLaCaja
        case .dueloConElDedo: return dueloConElDedo
        case .despertarSecondComing: return despertarSecondComing
        case .elSueno: return elSueno
        case .dibujamosJuntos: return dibujamosJuntos
        }
    }

    // MARK: 1 · Nacimiento (~30 s · primera apertura)
    //
    // Lienzo en blanco; el cursor-lapiz lo dibuja trazo a trazo (la capa
    // pinta la figura, el cuerpo real esta oculto); el trazo tiembla, la
    // cabeza se hace solida, cobra vida con wakeUp (2.8, el mismo clip
    // de bringToLife), se mira las manos, una primera chispa le asusta
    // (scared 0.85) y despues sonrie (thumbsUp: la "sonrisa" sin cara).
    static let nacimiento = CinematicScene(
        id: .nacimiento,
        title: "Nacimiento",
        synopsis: "Un lapiz lo dibuja trazo a trazo en un lienzo en blanco. Tiembla, se hace solido, se levanta, se mira las manos... y una primera chispa le da su primer susto y su primera sonrisa.",
        trigger: .firstLaunch,
        duration: 30,
        beats: [
            CinematicBeat(0.0, .letterbox(1, duration: 1.2), note: "Lienzo en blanco, bandas de cine"),
            CinematicBeat(0.0, .subtitle("Un lienzo en blanco...", seconds: 2.8)),
            CinematicBeat(0.4, .callback(.hideCharacter(true)), note: "El cuerpo real espera oculto: nace en la capa"),
            CinematicBeat(1.6, .propShow(.pencil, dx: 36, height: 148, scale: 1)),
            CinematicBeat(1.6, .drawProgress(1, duration: 8.8), note: "6 trazos en 8.8 s: cabeza, torso, brazos, piernas"),
            CinematicBeat(2.2, .subtitle("Alguien esta dibujando algo...", seconds: 3)),
            CinematicBeat(6.0, .particles(kind: .spark, count: 3, anchor: .head), note: "Polvo del trazo"),
            CinematicBeat(8.6, .particles(kind: .spark, count: 3, anchor: .head)),
            CinematicBeat(8.9, .subtitle("El trazo tiembla... esta a punto de despertar.", seconds: 2.4)),
            CinematicBeat(10.4, .callback(.bornAlive), note: "La capa se retira: bringToLife() de verdad"),
            CinematicBeat(10.4, .propHide(.pencil)),
            CinematicBeat(10.4, .poseSource(.followStage), note: "Manda su accion real: .awakening con wakeUp 2.8"),
            CinematicBeat(10.6, .subtitle("Ha nacido un stickman.", seconds: 2.4)),
            CinematicBeat(13.2, .poseSource(.clip(AnimationLibrary.lookAround)), note: "lookAround 2.2: se mira las manos"),
            CinematicBeat(13.4, .subtitle("Se mira las manos. No entiende nada todavia.", seconds: 2.6)),
            CinematicBeat(15.4, .particles(kind: .spark, count: 6, anchor: .hands), note: "¡Primera chispa!"),
            CinematicBeat(15.4, .haptic(.light)),
            CinematicBeat(15.55, .poseSource(.action(.scared)), note: "scared 0.85"),
            CinematicBeat(15.6, .subtitle("¡Una chispa! ¡De sus propias manos!", seconds: 2.2)),
            CinematicBeat(16.4, .poseSource(.action(.scared)), note: "Segundo susto, mas flojo"),
            CinematicBeat(17.3, .poseSource(.action(.idle)), note: "idle 4.8: respiracion y cambio de peso aguantado"),
            CinematicBeat(17.3, .camera(scale: 1.12, focusX: 0.5, focusY: 0.45, duration: 1.6), note: "La camara se acerca a mirarlo"),
            CinematicBeat(18.0, .subtitle("Sobrevive a su primera chispa.", seconds: 2.6)),
            CinematicBeat(22.1, .poseSource(.action(.thumbsUp)), note: "thumbsUp 1.1: su sonrisa (no tiene cara; es esto)"),
            CinematicBeat(22.3, .haptic(.success)),
            CinematicBeat(22.3, .subtitle("Y sonrie. Le gusta estar vivo.", seconds: 2.6)),
            CinematicBeat(23.2, .poseSource(.action(.waving)), note: "wave 1.0 x2"),
            CinematicBeat(23.4, .subtitle("Hola, dedo gigante.", seconds: 2.2)),
            CinematicBeat(25.2, .camera(scale: 1, focusX: 0.5, focusY: 0.5, duration: 1.4)),
            CinematicBeat(25.2, .letterbox(0, duration: 1.4)),
            CinematicBeat(25.4, .subtitle("Ahora el lienzo es su casa. Dejalo vivir.", seconds: 3.4)),
            CinematicBeat(27.0, .poseSource(.action(.idle))),
        ])

    // MARK: 2 · Escape de la caja (~35 s · al desbloquear el modo libre)
    //
    // Forcejeo con la estructura del propio escapeShake v6: su ciclo de
    // 2.6 s ya lleva las 3 fases (flojo -> paredes -> violencia maxima)
    // y el reseteo; aqui se encadenan 3 ciclos con la grieta de la caja
    // creciendo entre medias. Despues: idea, martillo dibujado
    // (hammering 0.9 x4), escapeBurst 0.85 para romper la esquina, la
    // carrera pesada (run 0.60 x5) hasta el otro lado y celebracion.
    // La esquina rota queda en el mundo (callback .persistentBrokenBox).
    static let escapeDeLaCaja = CinematicScene(
        id: .escapeDeLaCaja,
        title: "Escape de la caja",
        synopsis: "Encerrado en la caja de seleccion, forcejea en tres oleadas, dibuja un martillo, rompe una esquina y sale corriendo a un lienzo que por fin es entero suyo. La caja rota se queda como trofeo.",
        trigger: .freeModeUnlock,
        duration: 35,
        beats: [
            CinematicBeat(0.0, .letterbox(0.85, duration: 1.0)),
            CinematicBeat(0.0, .propShow(.selectionBox, dx: 0, height: 0, scale: 1)),
            CinematicBeat(0.3, .subtitle("Otra vez dentro de la caja de seleccion.", seconds: 3)),
            CinematicBeat(0.5, .poseSource(.action(.idle))),
            CinematicBeat(2.5, .poseSource(.clip(AnimationLibrary.block)), note: "block 0.9: se apoya en el borde y empuja; los pies derrapan"),
            CinematicBeat(2.9, .haptic(.medium)),
            CinematicBeat(2.9, .particles(kind: .sweat, count: 4, anchor: .feet)),
            CinematicBeat(3.4, .poseSource(.action(.escaping)), note: "escapeShake ciclo 1 de 3 (fases 1-2: flojo, paredes)"),
            CinematicBeat(3.6, .haptic(.light)),
            CinematicBeat(4.6, .haptic(.light)),
            CinematicBeat(5.2, .propProgress(.selectionBox, 0.25), note: "Primera grieta en la esquina"),
            CinematicBeat(6.0, .poseSource(.action(.escaping)), note: "Ciclo 2"),
            CinematicBeat(7.8, .propProgress(.selectionBox, 0.5)),
            CinematicBeat(8.6, .poseSource(.action(.escaping)), note: "Ciclo 3: violencia maxima del clip"),
            CinematicBeat(9.2, .haptic(.medium)),
            CinematicBeat(10.4, .propProgress(.selectionBox, 0.7)),
            CinematicBeat(10.6, .haptic(.heavy)),
            CinematicBeat(10.6, .particles(kind: .spark, count: 6, anchor: .hands)),
            CinematicBeat(11.2, .poseSource(.action(.sitting)), note: "sit 2.6: se sienta a pensar"),
            CinematicBeat(11.4, .subtitle("La fuerza no basta. Necesita una herramienta.", seconds: 2.8)),
            CinematicBeat(13.8, .poseSource(.action(.drawingObject)), note: "drawWithPencil 1.0 en bucle: dibuja el martillo"),
            CinematicBeat(14.0, .subtitle("Dibuja un martillo. Su lapiz, sus reglas.", seconds: 2.8)),
            CinematicBeat(15.9, .propShow(.hammer, dx: 58, height: 0, scale: 1)),
            CinematicBeat(16.2, .propHide(.hammer), note: "Ya lo tiene en la mano: el clip hammering lo dibuja el"),
            CinematicBeat(16.2, .poseSource(.action(.hammering)), note: "hammering 0.9 x4 contra la esquina"),
            CinematicBeat(16.65, .haptic(.medium)),
            CinematicBeat(17.5, .propProgress(.selectionBox, 0.85)),
            CinematicBeat(17.55, .haptic(.medium)),
            CinematicBeat(18.45, .haptic(.medium)),
            CinematicBeat(18.45, .particles(kind: .spark, count: 5, anchor: .groundFront)),
            CinematicBeat(19.0, .propProgress(.selectionBox, 0.95)),
            CinematicBeat(19.35, .haptic(.medium)),
            CinematicBeat(19.8, .poseSource(.action(.escapeBurst)), note: "escapeBurst 0.85 v6: carga squash 0.82 -> extension total"),
            CinematicBeat(20.0, .haptic(.heavy)),
            CinematicBeat(20.0, .particles(kind: .spark, count: 14, anchor: .character)),
            CinematicBeat(20.1, .propHide(.selectionBox)),
            CinematicBeat(20.1, .callback(.persistentBrokenBox), note: "La esquina rota queda como prop en el mundo"),
            CinematicBeat(20.7, .face(1)),
            CinematicBeat(20.7, .poseSource(.action(.running)), note: "run 0.60 x5: la carrera pesada simetrica"),
            CinematicBeat(20.7, .moveTo(fraction: 0.80, duration: 3.0, easing: .easeIn)),
            CinematicBeat(21.0, .subtitle("¡LIBRE! ¡TODO EL LIENZO!", seconds: 2.4)),
            CinematicBeat(23.7, .poseSource(.clip(AnimationLibrary.skid)), note: "skid 0.55: derrape con squash"),
            CinematicBeat(23.75, .haptic(.light)),
            CinematicBeat(24.25, .poseSource(.action(.celebrating)), note: "celebrate 0.9 x2"),
            CinematicBeat(24.6, .particles(kind: .energy, count: 10, anchor: .head)),
            CinematicBeat(26.05, .poseSource(.action(.laughing)), note: "laugh 0.9"),
            CinematicBeat(26.2, .subtitle("La caja rota se queda. Es su trofeo.", seconds: 3)),
            CinematicBeat(26.95, .face(-1)),
            CinematicBeat(26.95, .poseSource(.action(.walking)), note: "walk 0.80 x4: vuelve paseando, sobrado"),
            CinematicBeat(26.95, .moveTo(fraction: 0.58, duration: 3.2, easing: .easeInOut)),
            CinematicBeat(30.15, .poseSource(.action(.proud)), note: "proud 1.8"),
            CinematicBeat(31.95, .letterbox(0, duration: 1.2)),
            CinematicBeat(31.95, .poseSource(.action(.idle))),
            CinematicBeat(32.2, .subtitle("Modo libre completo: el mundo es suyo.", seconds: 2.6)),
        ])

    // MARK: 3 · Duelo con el dedo (~40 s · agarres repetidos)
    //
    // Camara lenta (timeScale 0.35) para el agarre —grabFinger 1.9
    // muestreado con el reloj de escena: se ralentiza de verdad—,
    // forcejeo escapeShake, el dedo le pega (hitReact 1.15 + getUp
    // 1.05: la pareja v6 de caerse y levantarse) y tres ciclos enteros
    // de fightCombo con la haptica clavada en las marcas de impacto de
    // cada rafaga. Al final el dedo duda: ventana de TREGUA de 3 s
    // (boton en pantalla). Las dos salidas comparten linea temporal
    // gracias a las ramas .onlyTruce / .onlyNoTruce desde la etiqueta.
    static let dueloConElDedo = CinematicScene(
        id: .dueloConElDedo,
        title: "Duelo con el dedo",
        synopsis: "Le has agarrado demasiadas veces. El tiempo se ralentiza, atrapa tu dedo y suelta la rafaga entera: jab, jab, cross, patada, barrido. Al final, el dedo duda: ¿rendirse o tregua?",
        trigger: .repeatedGrabs,
        duration: 40,
        beats: [
            CinematicBeat(0.0, .letterbox(0.85, duration: 1.0)),
            CinematicBeat(0.0, .propShow(.finger, dx: 120, height: 128, scale: 1.15)),
            CinematicBeat(0.3, .poseSource(.action(.blocking)), note: "block 0.9 en bucle: guardia alta"),
            CinematicBeat(0.4, .subtitle("El dedo vuelve a por el.", seconds: 2.6)),
            CinematicBeat(1.8, .propMove(.finger, dx: 64, height: 120, duration: 0.8, easing: .easeIn), note: "El dedo se acerca"),
            CinematicBeat(2.6, .timeScale(0.35, duration: 0.4), note: "CAMARA LENTA: el reloj de escena baja a 0.35"),
            CinematicBeat(2.6, .poseSource(.action(.grabbingFinger)), note: "grabFinger 1.9 ralentizado: trepa y hace palanca con las piernas"),
            CinematicBeat(2.8, .subtitle("Lo atrapa. Esta vez no se escapa.", seconds: 3)),
            CinematicBeat(6.2, .timeScale(1, duration: 0.5), note: "Vuelve el tiempo real"),
            CinematicBeat(6.2, .poseSource(.action(.escaping)), note: "escapeShake 2.6: forcejea colgando del dedo"),
            CinematicBeat(7.0, .haptic(.medium)),
            CinematicBeat(8.0, .haptic(.medium)),
            CinematicBeat(8.8, .propMove(.finger, dx: 30, height: 96, duration: 0.18, easing: .snappy), note: "¡El dedo le pega!"),
            CinematicBeat(8.98, .haptic(.heavy)),
            CinematicBeat(8.98, .particles(kind: .spark, count: 8, anchor: .hands)),
            CinematicBeat(8.98, .poseSource(.clip(AnimationLibrary.hitReact)), note: "hitReact 1.15 v6: recoil y tambaleo x2"),
            CinematicBeat(10.1, .subtitle("Se levanta. Ahora le toca a el.", seconds: 2.4)),
            CinematicBeat(10.13, .poseSource(.clip(AnimationLibrary.getUp)), note: "getUp 1.05 v6: su pose 0 ES la de suelo de trip"),
            CinematicBeat(11.18, .face(1), note: "De cara al dedo"),
            CinematicBeat(11.18, .poseSource(.action(.fighting)), note: "fightCombo ciclo 1: jab-jab-cross-patada-barrido"),
            CinematicBeat(11.18, .propMove(.finger, dx: 54, height: 118, duration: 0.3, easing: .easeOut), note: "El dedo queda a distancia de puño"),
            CinematicBeat(11.59, .haptic(.medium)),   // impacto jab 1 (+0.41)
            CinematicBeat(11.59, .particles(kind: .spark, count: 4, anchor: .hands)),
            CinematicBeat(11.82, .haptic(.light)),    // impacto jab 2 (+0.64)
            CinematicBeat(12.22, .haptic(.heavy)),    // impacto cross (+1.04)
            CinematicBeat(12.22, .particles(kind: .spark, count: 6, anchor: .hands)),
            CinematicBeat(12.85, .haptic(.heavy)),    // impacto patada (+1.67)
            CinematicBeat(13.36, .haptic(.medium)),   // barrido (+2.18)
            CinematicBeat(14.78, .poseSource(.action(.blocking)), note: "block x2: el dedo contraataca y el para, derrapando"),
            CinematicBeat(15.2, .haptic(.medium)),
            CinematicBeat(15.2, .particles(kind: .sweat, count: 4, anchor: .feet)),
            CinematicBeat(16.58, .poseSource(.action(.fighting)), note: "fightCombo ciclo 2"),
            CinematicBeat(16.99, .haptic(.medium)),
            CinematicBeat(17.22, .haptic(.light)),
            CinematicBeat(17.62, .haptic(.heavy)),
            CinematicBeat(18.25, .haptic(.heavy)),
            CinematicBeat(18.76, .haptic(.medium)),
            CinematicBeat(20.18, .poseSource(.clip(AnimationLibrary.flyDash)), note: "flyDash 0.7: embestida flecha (sin poder activo: es velocidad pura)"),
            CinematicBeat(20.3, .propMove(.finger, dx: 46, height: 116, duration: 0.2, easing: .easeOut)),
            CinematicBeat(20.53, .haptic(.light)),
            CinematicBeat(20.88, .poseSource(.action(.fighting)), note: "fightCombo ciclo 3"),
            CinematicBeat(21.29, .haptic(.medium)),
            CinematicBeat(21.52, .haptic(.light)),
            CinematicBeat(21.92, .haptic(.heavy)),
            CinematicBeat(22.55, .haptic(.heavy)),
            CinematicBeat(23.06, .haptic(.medium)),
            CinematicBeat(24.48, .offerTruce, note: "Ventana de 3 s: boton TREGUA en pantalla"),
            CinematicBeat(24.48, .poseSource(.action(.grabbingFinger)), note: "Lo tiene sujeto, dudando"),
            CinematicBeat(24.48, .propMove(.finger, dx: 58, height: 112, duration: 1.2, easing: .easeInOut), note: "Forcejeo flojo"),
            CinematicBeat(24.6, .subtitle("El dedo duda... ¿tregua?", seconds: 2.6)),
            CinematicBeat(26.2, .label("tregua"), note: "Destino del salto de tregua"),
            // — Rama SIN tregua: el dedo se rinde y se retira —
            CinematicBeat(26.2, .propMove(.finger, dx: 240, height: 300, duration: 1.3, easing: .easeIn), note: "Se rinde: sale por arriba a la derecha", branch: .onlyNoTruce),
            CinematicBeat(27.6, .subtitle("El dedo se rinde.", seconds: 2), branch: .onlyNoTruce),
            // — Rama CON tregua: vuelve, chocan el puño y se va en paz —
            CinematicBeat(26.25, .timeScale(0.5, duration: 0.3), note: "Medio tiempo para el apreton", branch: .onlyTruce),
            CinematicBeat(26.3, .propMove(.finger, dx: 40, height: 104, duration: 0.9, easing: .easeOut), note: "El dedo vuelve despacio", branch: .onlyTruce),
            CinematicBeat(27.2, .poseSource(.action(.thumbsUp)), note: "thumbsUp 1.1: trato hecho", branch: .onlyTruce),
            CinematicBeat(27.9, .propMove(.finger, dx: 26, height: 92, duration: 0.25, easing: .snappy), note: "¡Choca el puño!", branch: .onlyTruce),
            CinematicBeat(28.05, .haptic(.success), branch: .onlyTruce),
            CinematicBeat(28.05, .particles(kind: .energy, count: 8, anchor: .hands), branch: .onlyTruce),
            CinematicBeat(28.15, .propMove(.finger, dx: 230, height: 300, duration: 0.8, easing: .easeIn), note: "Se va en paz", branch: .onlyTruce),
            CinematicBeat(28.2, .timeScale(1, duration: 0.4), branch: .onlyTruce),
            CinematicBeat(28.2, .subtitle("Tregua. Hoy, amigos.", seconds: 2.2), branch: .onlyTruce),
            // — Cierre compartido —
            CinematicBeat(29.0, .propHide(.finger)),
            CinematicBeat(29.0, .poseSource(.action(.celebrating)), note: "celebrate 0.9 x2: gano el"),
            CinematicBeat(30.8, .poseSource(.action(.laughing)), note: "laugh 0.9 x2"),
            CinematicBeat(32.6, .poseSource(.action(.chasingFinger)), note: "Sale tras el dedo, jugueton (clip de correr)"),
            CinematicBeat(32.6, .moveTo(fraction: 0.78, duration: 2.4, easing: .easeOut)),
            CinematicBeat(35.0, .poseSource(.action(.sittingFacingFinger)), note: "sitFacing 2.6: se sienta de cara a donde se fue"),
            CinematicBeat(35.3, .subtitle("Otro dia se pelearan. Hoy gano el.", seconds: 2.6)),
            CinematicBeat(37.6, .letterbox(0, duration: 1.2)),
            CinematicBeat(37.6, .poseSource(.action(.proud)), note: "proud 1.8 de cierre"),
        ])

    // MARK: 4 · El despertar (~30 s · primer despertar de poderes)
    //
    // Todo el arco de poderes con la gramatica v6 carga -> descarga ->
    // sostenido -> recuperacion: chargePower (estalla a +1.62: ahi van
    // el desbloqueo, la haptica y la rafaga), vuelo flyPose, fuego x3
    // ciclos (descargas a +0.40), laser x3 (disparos a ~+0.34, contra
    // la "roca" = objeto .block garantizado del mundo), superpunetazo
    // (impacto a +0.58: grieta en el suelo) y dash flyDash de despedida.
    // Al terminar, los poderes quedan desbloqueados (callback).
    static let despertarSecondComing = CinematicScene(
        id: .despertarSecondComing,
        title: "Despertar",
        synopsis: "El aura estalla, despega volando, escupe fuego, parte una roca con el laser y agrieta el suelo de un superpunetazo. Desde hoy, los poderes son suyos en el modo libre.",
        trigger: .firstAwakeningActivation,
        duration: 30,
        beats: [
            CinematicBeat(0.0, .letterbox(0.85, duration: 1.0)),
            CinematicBeat(0.2, .poseSource(.action(.idle))),
            CinematicBeat(0.3, .subtitle("Algo se remueve dentro de el...", seconds: 2.6)),
            CinematicBeat(1.3, .poseSource(.clip(AnimationLibrary.chargePower)), note: "chargePower 1.9: temblor que ACELERA (v6)"),
            CinematicBeat(2.0, .particles(kind: .energy, count: 5, anchor: .hands)),
            CinematicBeat(2.5, .particles(kind: .energy, count: 7, anchor: .character)),
            CinematicBeat(2.92, .callback(.unlockAwakening), note: "+1.62 del clip: ESTALLA el aura — poderes desbloqueados"),
            CinematicBeat(2.92, .haptic(.heavy)),
            CinematicBeat(2.92, .particles(kind: .energy, count: 16, anchor: .character)),
            CinematicBeat(2.95, .subtitle("¡DESPIERTA!", seconds: 1.8)),
            CinematicBeat(3.2, .poseSource(.action(.powerPose)), note: "powerPose 1.8"),
            CinematicBeat(3.4, .subtitle("El despertar: poderes desbloqueados.", seconds: 2.4)),
            CinematicBeat(5.0, .heightTo(150, duration: 0.9, easing: .easeOut), note: "Despega"),
            CinematicBeat(5.0, .poseSource(.action(.flying)), note: "flyPose 1.2: balanceo de delfin, stretch 1.05-1.07"),
            CinematicBeat(5.2, .subtitle("Puede volar.", seconds: 2.2)),
            CinematicBeat(8.3, .heightTo(56, duration: 0.6, easing: .easeInOut), note: "Baja a altura de manos: va a escupir fuego"),
            CinematicBeat(8.9, .callback(.ensureRock), note: "La roca: un .block intacto del mundo para el laser"),
            CinematicBeat(8.9, .setPower(.fireBreath), note: "La vista dibuja la llama; el cuerpo lo pone el clip"),
            CinematicBeat(8.9, .poseSource(.clip(AnimationLibrary.clip(forPower: .fireBreath))), note: "firePose 1.1 x3 ciclos enteros"),
            CinematicBeat(9.1, .subtitle("Fuego: carga, descarga seca y sostenido temblando.", seconds: 2.8)),
            CinematicBeat(9.3, .haptic(.medium)),    // descarga ciclo 1 (+0.40)
            CinematicBeat(9.3, .particles(kind: .fire, count: 10, anchor: .hands)),
            CinematicBeat(10.4, .haptic(.medium)),   // descarga ciclo 2
            CinematicBeat(10.4, .particles(kind: .fire, count: 10, anchor: .hands)),
            CinematicBeat(11.5, .haptic(.medium)),   // descarga ciclo 3
            CinematicBeat(11.5, .particles(kind: .fire, count: 10, anchor: .hands)),
            CinematicBeat(12.2, .setPower(.eyeLaser)),
            CinematicBeat(12.2, .poseSource(.clip(AnimationLibrary.clip(forPower: .eyeLaser))), note: "laserPose 1.0 x3: tension -> disparo -> sostenido vibrando -> corte"),
            CinematicBeat(12.4, .subtitle("El laser busca la roca...", seconds: 2.4)),
            CinematicBeat(12.54, .haptic(.light)),   // disparo ciclo 1 (~+0.34)
            CinematicBeat(12.54, .particles(kind: .spark, count: 6, anchor: .groundFront)),
            CinematicBeat(13.54, .haptic(.light)),   // disparo ciclo 2
            CinematicBeat(14.54, .haptic(.light)),   // disparo ciclo 3
            CinematicBeat(15.2, .setPower(nil)),
            CinematicBeat(15.2, .heightTo(0, duration: 0.55, easing: .powerIn), note: "Caida que acelera (powerIn, como pide la v6)"),
            CinematicBeat(15.2, .poseSource(.clip(AnimationLibrary.fallPose))),
            CinematicBeat(15.75, .poseSource(.clip(AnimationLibrary.landing)), note: "landing 0.55 con su micro-rebote v6"),
            CinematicBeat(16.3, .setPower(.superPunch)),
            CinematicBeat(16.3, .poseSource(.clip(AnimationLibrary.clip(forPower: .superPunch))), note: "superPunchPose 1.15: anticipacion larga conservada"),
            CinematicBeat(16.5, .subtitle("Y el superpunetazo agrieta el suelo.", seconds: 2.4)),
            CinematicBeat(16.88, .haptic(.heavy), note: "IMPACTO (+0.58); la vibracion +0.58...+0.70 va en el clip"),
            CinematicBeat(16.88, .particles(kind: .spark, count: 12, anchor: .groundFront)),
            CinematicBeat(16.88, .propShow(.groundCrack, dx: 62, height: 0, scale: 1)),
            CinematicBeat(16.95, .propProgress(.groundCrack, 1), note: "La grieta se abre"),
            CinematicBeat(17.45, .setPower(nil)),
            CinematicBeat(17.45, .poseSource(.action(.powerPose)), note: "powerPose 1.8: se recrea"),
            CinematicBeat(19.25, .poseSource(.clip(AnimationLibrary.flyDash)), note: "flyDash 0.7 x2: postura flecha, stretch 1.12"),
            CinematicBeat(19.25, .heightTo(120, duration: 0.5, easing: .easeOut)),
            CinematicBeat(19.25, .moveTo(fraction: 0.82, duration: 1.4, easing: .easeIn), note: "Cruza el lienzo en dash"),
            CinematicBeat(20.65, .poseSource(.action(.flying)), note: "flyPose: se queda flotando, sobrado"),
            CinematicBeat(20.65, .heightTo(80, duration: 0.8, easing: .easeInOut)),
            CinematicBeat(23.05, .heightTo(0, duration: 0.55, easing: .powerIn)),
            CinematicBeat(23.05, .poseSource(.clip(AnimationLibrary.fallPose))),
            CinematicBeat(23.6, .poseSource(.clip(AnimationLibrary.landing))),
            CinematicBeat(24.15, .poseSource(.action(.powerPose)), note: "powerPose final 1.8"),
            CinematicBeat(24.3, .subtitle("Poderes listos para el modo libre.", seconds: 2.6)),
            CinematicBeat(25.95, .poseSource(.action(.celebrating)), note: "celebrate 0.9 x2"),
            CinematicBeat(26.3, .particles(kind: .energy, count: 10, anchor: .head)),
            CinematicBeat(27.75, .letterbox(0, duration: 1.3)),
            CinematicBeat(27.75, .poseSource(.action(.idle))),
            CinematicBeat(28.0, .subtitle("Ahora si: que empiece la fiesta.", seconds: 1.9)),
        ])

    // MARK: 5 · El sueno (~20 s · tras varios ciclos de dormir)
    //
    // Entra con el ya dormido (el disparador cuenta entradas reales en
    // .sleeping): bostezo, se sienta, sleep 4.2 con su respiracion lenta
    // y su tic de sueno por ciclo. La burbuja muestra dos mini-escenas
    // de trazo azul: el gigante y el volando entre nubes. Si el usuario
    // toca la pantalla, salta a la etiqueta "despertar": sobresalto
    // (scared) y getUp. Sin toque, despierta solo en el mismo punto.
    static let elSueno = CinematicScene(
        id: .elSueno,
        title: "El sueño",
        synopsis: "Se duerme en mitad del lienzo y suena: primero es gigante, luego vuela entre nubes de trazo. Si le tocas, se despierta de un sobresalto.",
        trigger: .sleepCycles,
        duration: 20,
        beats: [
            CinematicBeat(0.0, .letterbox(0.7, duration: 1.2)),
            CinematicBeat(0.2, .poseSource(.action(.yawning)), note: "yawn 1.6"),
            CinematicBeat(0.4, .subtitle("Otro dia largo en el lienzo...", seconds: 2.6)),
            CinematicBeat(1.8, .poseSource(.action(.sitting)), note: "sit 2.6: se tumba desde sentado"),
            CinematicBeat(4.4, .stageAction(.sleeping), note: "Su bocadillo Zzz de la vista principal"),
            CinematicBeat(4.4, .poseSource(.action(.sleeping)), note: "sleep 4.2: respiracion profunda + tic del pie por ciclo"),
            CinematicBeat(5.4, .particles(kind: .zzz, count: 3, anchor: .head)),
            CinematicBeat(6.2, .propShow(.dreamGiant, dx: 0, height: 0, scale: 1), note: "Burbuja 1: el, gigante"),
            CinematicBeat(6.4, .subtitle("Suena que es GIGANTE.", seconds: 2.6)),
            CinematicBeat(7.4, .particles(kind: .zzz, count: 3, anchor: .head)),
            CinematicBeat(9.4, .particles(kind: .zzz, count: 3, anchor: .head)),
            CinematicBeat(10.6, .propHide(.dreamGiant)),
            CinematicBeat(10.6, .propShow(.dreamFlight, dx: 0, height: 0, scale: 1), note: "Burbuja 2: el, volando entre nubes"),
            CinematicBeat(10.8, .subtitle("Y ahora vuela entre nubes de trazo.", seconds: 2.8)),
            CinematicBeat(11.4, .particles(kind: .zzz, count: 3, anchor: .head)),
            CinematicBeat(13.4, .particles(kind: .zzz, count: 3, anchor: .head)),
            CinematicBeat(15.4, .label("despertar"), note: "Un toque en pantalla salta hasta aqui"),
            CinematicBeat(15.4, .propHide(.dreamFlight)),
            CinematicBeat(15.4, .stageAction(.idle), note: "Se acabo el estado dormido en el mundo"),
            CinematicBeat(15.4, .poseSource(.action(.scared)), note: "scared 0.85: sobresalto"),
            CinematicBeat(15.45, .haptic(.warning)),
            CinematicBeat(15.5, .subtitle("¡Eh! ¿Ya es de dia?", seconds: 2)),
            CinematicBeat(16.25, .poseSource(.clip(AnimationLibrary.getUp)), note: "getUp 1.05"),
            CinematicBeat(17.3, .poseSource(.action(.shrugging)), note: "shrug 1.2"),
            CinematicBeat(17.4, .subtitle("Solo era un sueno. Un buen sueno.", seconds: 2)),
            CinematicBeat(18.5, .letterbox(0, duration: 1.0)),
            CinematicBeat(18.5, .poseSource(.action(.idle))),
        ])

    // MARK: 6 · Dibujamos juntos (~25 s · dibujar sin pegarle)
    //
    // La escena amable: viene ANDANDO (walk 0.80 x3, con su retraso de
    // brazos v6) hasta el centro, se sienta de cara al dedo, dibuja
    // media casita (drawWithPencil 1.0 en bucle mientras houseProgress
    // traza paredes y tejado), le pasa el lapiz al usuario —la casita
    // se completa con el lapiz azul— y la casita QUEDA en el mundo
    // (callback .persistentHouse). Celebracion y despedida andando.
    static let dibujamosJuntos = CinematicScene(
        id: .dibujamosJuntos,
        title: "Dibujamos juntos",
        synopsis: "Tras varios dibujos sin peleas, se acerca andando, se sienta junto a tu cursor y dibuja media casita. Te pasa el lapiz, la terminas tu, y la casita se queda en el mundo para siempre.",
        trigger: .kindDrawing,
        duration: 25,
        beats: [
            CinematicBeat(0.0, .letterbox(0.7, duration: 1.0)),
            CinematicBeat(0.3, .face(1)),
            CinematicBeat(0.3, .poseSource(.action(.walking)), note: "walk 0.80 x3: andar con peso, brazos con retraso"),
            CinematicBeat(0.3, .moveTo(fraction: 0.40, duration: 2.4, easing: .easeInOut)),
            CinematicBeat(0.5, .subtitle("Hoy no hay peleas. Hoy se dibuja.", seconds: 2.6)),
            CinematicBeat(2.7, .poseSource(.action(.sittingFacingFinger)), note: "Se sienta de cara a tu cursor (2.6)"),
            CinematicBeat(3.4, .propShow(.userPencil, dx: 108, height: 30, scale: 1), note: "Tu lapiz, cerca"),
            CinematicBeat(5.3, .poseSource(.action(.drawingObject)), note: "drawWithPencil 1.0 en bucle"),
            CinematicBeat(5.3, .propShow(.drawnPencil, dx: 30, height: 66, scale: 1), note: "Su lapiz naranja"),
            CinematicBeat(5.3, .houseProgress(0.5, duration: 6.0), note: "Media casita: paredes y tejado"),
            CinematicBeat(5.5, .subtitle("El traza media casita...", seconds: 3)),
            CinematicBeat(11.3, .propHide(.drawnPencil)),
            CinematicBeat(11.3, .poseSource(.action(.thumbsUp)), note: "thumbsUp 1.1: te la pasa"),
            CinematicBeat(11.4, .propMove(.userPencil, dx: 96, height: 40, duration: 0.8, easing: .easeOut), note: "Tu lapiz se acerca a la casita"),
            CinematicBeat(11.5, .subtitle("...y te pasa el lapiz.", seconds: 2.2)),
            CinematicBeat(12.4, .poseSource(.action(.sitting)), note: "sit 2.6 en bucle: mira como la terminas"),
            CinematicBeat(12.4, .houseProgress(1.0, duration: 5.2), note: "Puerta, ventana, chimenea... y el sol al completar"),
            CinematicBeat(12.8, .subtitle("La terminas tu. Entre los dos.", seconds: 2.8)),
            CinematicBeat(14.5, .particles(kind: .spark, count: 4, anchor: .hands)),
            CinematicBeat(16.5, .particles(kind: .spark, count: 4, anchor: .hands)),
            CinematicBeat(17.6, .callback(.persistentHouse), note: "La casita pasa al decorado del mundo"),
            CinematicBeat(17.6, .propHide(.userPencil)),
            CinematicBeat(17.6, .poseSource(.action(.celebrating)), note: "celebrate 0.9 x2"),
            CinematicBeat(17.8, .haptic(.success)),
            CinematicBeat(17.8, .subtitle("Una casita hecha a cuatro manos.", seconds: 2.6)),
            CinematicBeat(19.4, .poseSource(.action(.waving)), note: "wave 1.0 x2: se despide"),
            CinematicBeat(21.4, .face(1)),
            CinematicBeat(21.4, .poseSource(.action(.walking)), note: "walk x3 de vuelta a su vida"),
            CinematicBeat(21.4, .moveTo(fraction: 0.66, duration: 2.4, easing: .easeInOut)),
            CinematicBeat(23.8, .letterbox(0, duration: 1.0)),
            CinematicBeat(23.8, .poseSource(.action(.idle))),
            CinematicBeat(23.9, .subtitle("La casita se queda en el mundo.", seconds: 2)),
        ])
}
