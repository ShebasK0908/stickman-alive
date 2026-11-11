import Foundation
import SwiftUI

// MARK: - PASE v9: cuarta tanda de clips NUEVOS
//
// Continuacion de los pases v6 (63 clips), v7 (19) y v8 (22):
// esta tanda anade 20 clips que NO duplican ninguno de los 104
// anteriores. El usuario pidio expresamente "velos 4 veces cada
// uno", asi que el pase se ha hecho en CUATRO pasadas sobre el
// mismo material (los videos AvA 1/2/4 segun REFERENCES.md y la
// biblia destilada en CHANGELOG-ANIM.md, mas el catalogo de
// behaviors de SHIMEJI_SPEC.md), cada una con una lente distinta:
//
//   Pasada 1 - HISTORIA: beats narrativos de AvA 1/2/4 que aun no
//              tenian clip propio -> groundPound.
//   Pasada 2 - PELEA fina: micro-movimientos de combate
//              secundarios -> feint, sidestep, palmParry,
//              fingerShield.
//   Pasada 3 - VIDA: micro-gestos idle y de descanso ->
//              stretchSide, nodOff, sleepRoll, sitCrossed,
//              crouchInspect.
//   Pasada 4 - TSC/DIBUJO (prioritaria: dibujar es la firma de
//              The Second Coming, el protagonista actual) ->
//              releaseBird, rideHorse, petCreature, feedCreature,
//              drawStairs, drawUmbrella, conduct; mas los restos
//              reales del catalogo Shimeji aun sin mapear:
//              fallWithObject (FallWithIe), throwLoaded (ThrowIe)
//              y wallJump (JumpFromWall).
//
// El detalle de cada pasada, los descartes con motivo y los
// huecos que quedan estan en CHANGELOG-ANIM-V9.md.
//
// Que NO es (la linea de siempre): no se ha copiado ni un
// fotograma ni se ha usado ningun sprite del pack ni de los
// videos, ni como asset ni como pose copiada 1:1. Todo es
// recreacion propia del MOVIMIENTO con el esqueleto de offsets
// existente y los criterios de la v6/v8: anticipacion antes de
// cada accion, holds de impacto mas largos que las anticipaciones
// de los golpes rapidos, squash & stretch para el peso, easings
// .powerIn para las caidas que aceleran y .backOut para las
// recuperaciones que "respiran". Sin rotacion global del cuerpo:
// el esqueleto no la soporta y ningun clip de esta tanda la pide.
//
// Protagonista: THE SECOND COMING (naranja 241,129,12, cabeza
// hueca). Los clips son datos de pose sin color, asi que valen
// igual que en las tandas anteriores; el color vive en la capa
// de dibujo, no aqui.
//
// Fichero ADITIVO y autonimo: no toca StickmanAnimation.swift ni
// los ficheros v7/v8, y no anade casos a StickmanAction (sus
// switches son exhaustivos y sin default; el cableado es trabajo
// de integracion, ver CHANGELOG-ANIM-V9.md). Los tipos
// SkeletonPose, AnimKeyframe, AnimationClip y AnimEasing son los
// del fichero original (mismo modulo al integrar). Los helpers
// P/K (v6), P7/K7 (v7) y P8/K8 (v8) son `private` de sus ficheros
// y no se ven desde aqui: por eso existen P9/K9.
//
// OJO al escribir poses: cada keyframe es una pose COMPLETA
// construida desde `standing` (igual que en v6/v7/v8). Todo canal
// que no se toca en un keyframe vuelve al valor de pie, asi que
// cada keyframe de este fichero fija todos los canales que le
// importan.

// Constructor comodo de poses a partir de la pose de pie (gemelo de P/P7/P8)
private func P9(_ modify: (inout SkeletonPose) -> Void) -> SkeletonPose {
    var p = SkeletonPose.standing
    modify(&p)
    return p
}
private func K9(_ time: Double, _ pose: SkeletonPose, _ easing: AnimEasing = .easeInOut) -> AnimKeyframe {
    AnimKeyframe(time: time, pose: pose, easing: easing)
}

// MARK: - Catalogo v9 (20 clips nuevos)

public enum AnimationLibraryV9 {

    // ============================================================
    // MARK: Pasada 1 - HISTORIA (beats de AvA 1/2/4 sin clip propio)
    // ============================================================

    // -- Punetazo al SUELO (AvA 2: The Chosen One revienta el
    // escritorio de un punetazo descendente). No es superPunchPose
    // (punetazo horizontal, de pie) ni heroLanding (aterrizaje con
    // la rodilla): aqui SALTA a proposito, clava el puno DERECHO
    // en el suelo con todo el peso encima y se levanta desde el
    // puno plantado. La onda de choque la dibuja el motor de
    // poderes en la marca de impacto (0.64).
    static let groundPound = AnimationClip(name: "punetazo-suelo", duration: 1.15, loops: false, keyframes: [
        K9(0.0, SkeletonPose.standing, .easeIn), // se agacha cargando el salto, puno subiendo
        K9(0.18, P9 { p in
            p.hipHeight = 42; p.squash = 0.88; p.neckOff = CGPoint(x: 6, y: -34); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -16, y: 32)
            p.elbowR = CGPoint(x: 16, y: -2); p.handR = CGPoint(x: 20, y: -18) // el puno ya va arriba
            p.kneeL = CGPoint(x: -16, y: 20); p.footL = CGPoint(x: -20, y: 42)
            p.kneeR = CGPoint(x: 16, y: 20); p.footR = CGPoint(x: 20, y: 42)
        }, .snappy), // ¡SALTA! estirado en el aire, puno sobre la cabeza
        K9(0.38, P9 { p in
            p.hipHeight = 66; p.squash = 1.10; p.neckOff = CGPoint(x: 2, y: -44); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -18, y: 10); p.handL = CGPoint(x: -26, y: 24) // brazo libre, arrastrado
            p.elbowR = CGPoint(x: 10, y: -24); p.handR = CGPoint(x: 8, y: -46)  // el puno, en lo alto
            p.kneeL = CGPoint(x: -12, y: 20); p.footL = CGPoint(x: -16, y: 40)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 16, y: 44)
        }, .easeInOut), // aguanta un pelo en el apice, mirando donde va a clavar
        K9(0.5, P9 { p in
            p.hipHeight = 67; p.squash = 1.08; p.neckOff = CGPoint(x: 4, y: -42); p.headOff = CGPoint(x: 3, y: -20)
            p.elbowL = CGPoint(x: -18, y: 10); p.handL = CGPoint(x: -26, y: 24)
            p.elbowR = CGPoint(x: 10, y: -23); p.handR = CGPoint(x: 8, y: -45)
            p.kneeL = CGPoint(x: -12, y: 21); p.footL = CGPoint(x: -16, y: 41)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 16, y: 44)
        }, .powerIn), // ¡CLAVA EL PUNO! todo el cuerpo cae detras del brazo
        K9(0.64, P9 { p in
            p.hipHeight = 28; p.squash = 0.82; p.hipDX = 3; p.neckOff = CGPoint(x: 18, y: -22); p.headOff = CGPoint(x: 8, y: -12)
            p.elbowL = CGPoint(x: -20, y: -6); p.handL = CGPoint(x: -30, y: -16) // brazo libre lanzado atras-arriba
            p.elbowR = CGPoint(x: 24, y: 26); p.handR = CGPoint(x: 30, y: 50)   // EL PUNO, plantado en el suelo
            p.kneeL = CGPoint(x: -18, y: 14); p.footL = CGPoint(x: -24, y: 28)
            p.kneeR = CGPoint(x: 18, y: 16); p.footR = CGPoint(x: 26, y: 26)
        }, .linear), // hold de impacto: el puno tiembla clavado
        K9(0.76, P9 { p in
            p.hipHeight = 28; p.squash = 0.84; p.hipDX = 3; p.neckOff = CGPoint(x: 18, y: -22); p.headOff = CGPoint(x: 8, y: -13)
            p.elbowL = CGPoint(x: -20, y: -6); p.handL = CGPoint(x: -30, y: -16)
            p.elbowR = CGPoint(x: 24, y: 26); p.handR = CGPoint(x: 30, y: 49)
            p.kneeL = CGPoint(x: -18, y: 14); p.footL = CGPoint(x: -24, y: 28)
            p.kneeR = CGPoint(x: 18, y: 16); p.footR = CGPoint(x: 26, y: 26)
        }, .easeOut), // se levanta apoyandose en el puno, que se despega el ultimo
        K9(0.95, P9 { p in
            p.hipHeight = 44; p.squash = 0.97; p.neckOff = CGPoint(x: 8, y: -36); p.headOff = CGPoint(x: 3, y: -20)
            p.elbowL = CGPoint(x: -16, y: 16); p.handL = CGPoint(x: -18, y: 34)
            p.elbowR = CGPoint(x: 18, y: 20); p.handR = CGPoint(x: 24, y: 30)
            p.kneeL = CGPoint(x: -13, y: 22); p.footL = CGPoint(x: -16, y: 44)
            p.kneeR = CGPoint(x: 13, y: 22); p.footR = CGPoint(x: 16, y: 44)
        }, .backOut), // y se asienta de pie, sobrado
        K9(1.15, SkeletonPose.standing)
    ])

    // ============================================================
    // MARK: Pasada 2 - PELEA fina (micro-movimientos secundarios)
    // La rafaga sigue en fightCombo (v6), los golpes con nombre en
    // v7/v8; esto es la capa FINA que faltaba entre golpe y golpe:
    // enganar, apartarse sin agacharse, desviar, y usar el propio
    // dedo del usuario como escudo.
    // ============================================================

    // -- AMAGO (finta de jab): vende un jab que NUNCA sale. El
    // hombro salta, el peso se vuelca adelante y la mano llega
    // solo a MITAD de camino, se congela un instante ("¿ha
    // picado?") y se recoge de golpe con la cabeza escapando al
    // lado contrario. La gracia es lo que NO pasa: ningun keyframe
    // extiende el brazo del todo. Encadenable desde la guardia de
    // fightCombo (misma pose inicial/final que backKick y cia).
    static let feint = AnimationClip(name: "amago", duration: 0.9, loops: false, keyframes: [
        K9(0.0, P9 { p in // guardia del combo (encadenable)
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeIn), // vende la finta: hombro y peso saltan adelante
        K9(0.14, P9 { p in
            p.hipHeight = 49; p.hipDX = 2; p.neckOff = CGPoint(x: 9, y: -39); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: 8, y: 15); p.handL = CGPoint(x: 22, y: 4) // la mano ya asoma
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -16, y: 49)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 24, y: 49)
        }, .snappy), // ¡EL AMAGO! la mano sale disparada... a medias
        K9(0.26, P9 { p in
            p.hipHeight = 50; p.hipDX = 3; p.neckOff = CGPoint(x: 12, y: -38); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: 16, y: 8); p.handL = CGPoint(x: 30, y: 0) // medio jab: ahi se queda
            p.elbowR = CGPoint(x: 12, y: 18); p.handR = CGPoint(x: 24, y: 10) // la guardia NO se vende
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 50)
            p.kneeR = CGPoint(x: 14, y: 26); p.footR = CGPoint(x: 24, y: 50)
        }, .linear), // micro-freeze: a ver si pica
        K9(0.34, P9 { p in
            p.hipHeight = 50; p.hipDX = 3; p.neckOff = CGPoint(x: 12, y: -38); p.headOff = CGPoint(x: 5, y: -20)
            p.elbowL = CGPoint(x: 16, y: 8); p.handL = CGPoint(x: 30, y: 0)
            p.elbowR = CGPoint(x: 12, y: 18); p.handR = CGPoint(x: 24, y: 10)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 50)
            p.kneeR = CGPoint(x: 14, y: 26); p.footR = CGPoint(x: 24, y: 50)
        }, .snappy), // se recoge DE GOLPE y la cabeza escapa al otro lado
        K9(0.48, P9 { p in
            p.hipHeight = 49; p.hipDX = -1; p.neckOff = CGPoint(x: 2, y: -39); p.headOff = CGPoint(x: -4, y: -21)
            p.elbowL = CGPoint(x: 3, y: 16); p.handL = CGPoint(x: 16, y: 7)
            p.elbowR = CGPoint(x: 13, y: 16); p.handR = CGPoint(x: 26, y: 6) // guardia alta: listo para castigar
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 49)
            p.kneeR = CGPoint(x: 12, y: 26); p.footR = CGPoint(x: 20, y: 49)
        }, .backOut), // se asienta en guardia con la cabeza ladeada, sobrado
        K9(0.7, P9 { p in
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeInOut),
        K9(0.9, P9 { p in // guardia exacta: listo para el golpe de verdad
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Paso LATERAL (esquiva lateral): dos pasitos cruzados
    // rapidisimos hacia un lado con la guardia siempre en alto y
    // la mirada clavada en la amenaza (la cabeza NO viaja con el
    // cuerpo: se queda "mirando" mientras el cuerpo se va). El
    // desplazamiento lateral real lo pone el motor; el clip pone
    // la inclinacion (se vuelca hacia el lado del paso y luego se
    // frena volcandose al contrario) y el cruce de pies. Distinto
    // de leanBack (arqueo en el sitio) y de dodgeDuck (agacharse):
    // aqui el cuerpo CAMBIA DE SITIO sin bajar ni arquearse.
    static let sidestep = AnimationClip(name: "paso-lateral", duration: 0.7, loops: false, keyframes: [
        K9(0.0, P9 { p in // guardia del combo
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .snappy), // ¡EXPLOTA hacia el lado! primer paso cruzado, cuerpo volcado
        K9(0.12, P9 { p in
            p.hipHeight = 48; p.squash = 0.95; p.hipDX = -4; p.neckOff = CGPoint(x: 2, y: -38); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: 6, y: 14); p.handL = CGPoint(x: 18, y: 4) // la guardia no baja
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 26, y: 6)
            p.kneeL = CGPoint(x: -4, y: 24); p.footL = CGPoint(x: 2, y: 44)  // pie cruzando por debajo
            p.kneeR = CGPoint(x: 16, y: 22); p.footR = CGPoint(x: 26, y: 46) // el otro aun arrastra
        }, .linear), // segundo paso, aun mas rapido
        K9(0.24, P9 { p in
            p.hipHeight = 48; p.squash = 0.95; p.hipDX = -5; p.neckOff = CGPoint(x: 1, y: -38); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: 6, y: 14); p.handL = CGPoint(x: 18, y: 4)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 26, y: 6)
            p.kneeL = CGPoint(x: -16, y: 24); p.footL = CGPoint(x: -24, y: 46) // planta ancho, frenando
            p.kneeR = CGPoint(x: -2, y: 22); p.footR = CGPoint(x: 4, y: 42)    // el otro cruza detras
        }, .easeOut), // frena volcandose al contrario y planta la guardia
        K9(0.42, P9 { p in
            p.hipHeight = 50; p.hipDX = -2; p.neckOff = CGPoint(x: 5, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -14, y: 26); p.footL = CGPoint(x: -24, y: 50)
            p.kneeR = CGPoint(x: 10, y: 26); p.footR = CGPoint(x: 14, y: 50)
        }, .easeInOut), // se asienta: ya esta en otro sitio, misma guardia
        K9(0.7, P9 { p in
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Desvio con la PALMA: en vez de parar el golpe (block: lo
    // absorbe y derrapa) o esquivarlo (el cuerpo se aparta), aqui
    // lo DESVIA: la palma abierta barre de dentro a fuera y el
    // golpe resbala de largo, mientras la otra mano queda cargada
    // para el contragolpe. El gesto es del brazo y del torso que
    // se desenrosca, no de las piernas: los pies apenas se mueven.
    static let palmParry = AnimationClip(name: "desvio-palma", duration: 0.8, loops: false, keyframes: [
        K9(0.0, P9 { p in // guardia del combo
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeOut), // la palma sube y se cruza cargando el desvio
        K9(0.16, P9 { p in
            p.hipHeight = 50; p.hipDX = -1; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 12, y: 14); p.handL = CGPoint(x: 22, y: 10) // palma cruzada al otro lado
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 26, y: 10)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .snappy), // ¡DESVIA! la palma barre hacia fuera y el golpe pasa de largo
        K9(0.3, P9 { p in
            p.hipHeight = 51; p.hipDX = 2; p.neckOff = CGPoint(x: 8, y: -39); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: -6, y: 10); p.handL = CGPoint(x: -16, y: 2)  // la palma, fuera del todo
            p.elbowR = CGPoint(x: 10, y: 20); p.handR = CGPoint(x: 20, y: 16) // la otra, CARGADA para responder
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -22, y: 50)
            p.kneeR = CGPoint(x: 12, y: 26); p.footR = CGPoint(x: 20, y: 50)
        }, .linear), // aguanta el desvio un instante (el rival sigue de largo)
        K9(0.42, P9 { p in
            p.hipHeight = 51; p.hipDX = 2; p.neckOff = CGPoint(x: 8, y: -39); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: -6, y: 10); p.handL = CGPoint(x: -17, y: 2)
            p.elbowR = CGPoint(x: 10, y: 20); p.handR = CGPoint(x: 20, y: 16)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -22, y: 50)
            p.kneeR = CGPoint(x: 12, y: 26); p.footR = CGPoint(x: 20, y: 50)
        }, .easeOut), // la palma vuelve a guardia; la mano cargada tarda un pelo mas (amenaza)
        K9(0.6, P9 { p in
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 3, y: 16); p.handL = CGPoint(x: 14, y: 7)
            p.elbowR = CGPoint(x: 12, y: 19); p.handR = CGPoint(x: 22, y: 13) // aun medio cargada
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .backOut),
        K9(0.8, P9 { p in // guardia exacta
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Escudo-DEDO: agarra el dedo del usuario con las dos
    // manos y lo planta DELANTE como escudo, agazapado detras.
    // Es el uso defensivo del dedo (grabFinger/grabbed son de
    // forcejeo y trepa; highFive es amistoso): aqui el dedo es
    // mobiliario de trincheras. Bucle: atrincherado -> se asoma
    // por arriba -> un "impacto" contra el dedo lo sacude entero
    // (el no recibe nada, pero vibra con el dedo) -> se asoma por
    // el otro lado -> atrincherado. La vista debe alinear las dos
    // manos con la posicion real del dedo, como en highFive.
    static let fingerShield = AnimationClip(name: "escudo-dedo", duration: 1.7, loops: true, keyframes: [
        K9(0.0, P9 { p in // atrincherado: agazapado, las dos manos agarrando el dedo en alto-delante
            p.hipHeight = 44; p.squash = 0.94; p.neckOff = CGPoint(x: 8, y: -32); p.headOff = CGPoint(x: 3, y: -16)
            p.elbowL = CGPoint(x: 2, y: -6); p.handL = CGPoint(x: 14, y: -26)  // agarre izquierdo del dedo
            p.elbowR = CGPoint(x: 18, y: -4); p.handR = CGPoint(x: 24, y: -24) // agarre derecho
            p.kneeL = CGPoint(x: -16, y: 20); p.footL = CGPoint(x: -22, y: 44)
            p.kneeR = CGPoint(x: 16, y: 20); p.footR = CGPoint(x: 24, y: 44)
        }, .easeInOut), // se asoma por encima del dedo, curioso
        K9(0.4, P9 { p in
            p.hipHeight = 45; p.neckOff = CGPoint(x: 8, y: -34); p.headOff = CGPoint(x: 4, y: -21) // la cabeza ya pasa el dedo
            p.elbowL = CGPoint(x: 2, y: -6); p.handL = CGPoint(x: 14, y: -26)
            p.elbowR = CGPoint(x: 18, y: -4); p.handR = CGPoint(x: 24, y: -24)
            p.kneeL = CGPoint(x: -16, y: 20); p.footL = CGPoint(x: -22, y: 45)
            p.kneeR = CGPoint(x: 16, y: 20); p.footR = CGPoint(x: 24, y: 45)
        }, .snappy), // ¡IMPACTO en el dedo! se agacha de golpe y todo vibra
        K9(0.62, P9 { p in
            p.hipHeight = 40; p.squash = 0.90; p.neckOff = CGPoint(x: 10, y: -28); p.headOff = CGPoint(x: 2, y: -13)
            p.elbowL = CGPoint(x: 2, y: -4); p.handL = CGPoint(x: 14, y: -22) // agarra mas fuerte
            p.elbowR = CGPoint(x: 18, y: -2); p.handR = CGPoint(x: 23, y: -20)
            p.kneeL = CGPoint(x: -14, y: 16); p.footL = CGPoint(x: -24, y: 40) // los pies derrapan un pelo
            p.kneeR = CGPoint(x: 14, y: 16); p.footR = CGPoint(x: 22, y: 40)
        }, .linear), // tembleque de recuperacion, aun agazapado
        K9(0.85, P9 { p in
            p.hipHeight = 43; p.squash = 0.93; p.hipDX = -1; p.neckOff = CGPoint(x: 7, y: -31); p.headOff = CGPoint(x: 1, y: -15)
            p.elbowL = CGPoint(x: 2, y: -6); p.handL = CGPoint(x: 14, y: -25)
            p.elbowR = CGPoint(x: 18, y: -4); p.handR = CGPoint(x: 24, y: -23)
            p.kneeL = CGPoint(x: -15, y: 19); p.footL = CGPoint(x: -23, y: 43)
            p.kneeR = CGPoint(x: 15, y: 19); p.footR = CGPoint(x: 23, y: 43)
        }, .easeInOut), // se asoma por el OTRO lado del dedo
        K9(1.25, P9 { p in
            p.hipHeight = 45; p.hipDX = 2; p.neckOff = CGPoint(x: 10, y: -33); p.headOff = CGPoint(x: 9, y: -18)
            p.elbowL = CGPoint(x: 2, y: -6); p.handL = CGPoint(x: 14, y: -26)
            p.elbowR = CGPoint(x: 18, y: -4); p.handR = CGPoint(x: 24, y: -24)
            p.kneeL = CGPoint(x: -16, y: 20); p.footL = CGPoint(x: -22, y: 45)
            p.kneeR = CGPoint(x: 16, y: 20); p.footR = CGPoint(x: 24, y: 45)
        }, .easeInOut) // vuelve a atrincherarse: el ciclo se cierra en la pose inicial
    ])

    // ============================================================
    // MARK: Pasada 3 - VIDA (micro-gestos idle y de descanso)
    // idle ya respira y cambia el peso; lookAround ya mira; yawn ya
    // bosteza; wakeUp ya se despereza AL DESPERTAR. Esto es la
    // micro-vida que quedaba entre esos clips: dormirse DE PIE,
    // rodar SIN despertarse, sentarse cruzado en el suelo,
    // agacharse a curiosear y el estiramiento lateral de verdad.
    // ============================================================

    // -- Estirarse de LADO: el estiramiento que wakeUp no hace
    // (el suyo es vertical, brazos al cielo recien despierto).
    // Este es el de estar vivo y desperezarse a mitad de sesion:
    // brazos arriba y el torso se dobla ENTERO hacia un lado
    // (neckOff.x grande, el brazo de arriba arquea sobre la
    // cabeza y el de abajo resbala por la pierna), aguanta, centro
    // y al otro lado. Simetrico a proposito: es ejercicio, no pose.
    static let stretchSide = AnimationClip(name: "estirarse-lado", duration: 2.4, loops: false, keyframes: [
        K9(0.0, SkeletonPose.standing, .easeInOut), // inspira y sube los brazos al cielo
        K9(0.35, P9 { p in
            p.hipHeight = 57; p.squash = 1.04; p.neckOff = CGPoint(x: 0, y: -44); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -14, y: -16); p.handL = CGPoint(x: -20, y: -40)
            p.elbowR = CGPoint(x: 14, y: -16); p.handR = CGPoint(x: 20, y: -40)
            p.kneeL = CGPoint(x: -8, y: 27); p.footL = CGPoint(x: -9, y: 57) // pies juntos
            p.kneeR = CGPoint(x: 8, y: 27); p.footR = CGPoint(x: 9, y: 57)
        }, .easeInOut), // se dobla a la IZQUIERDA: el brazo derecho arquea sobre la cabeza
        K9(0.8, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: -16, y: -36); p.headOff = CGPoint(x: -8, y: -20)
            p.elbowL = CGPoint(x: -16, y: 8); p.handL = CGPoint(x: -18, y: 30)  // mano baja resbalando por la pierna
            p.elbowR = CGPoint(x: 2, y: -26); p.handR = CGPoint(x: -16, y: -40) // mano de arriba, sobre la cabeza
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // aguanta el estiramiento, profundiza un pelo
        K9(1.15, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: -17, y: -35); p.headOff = CGPoint(x: -8, y: -20)
            p.elbowL = CGPoint(x: -16, y: 8); p.handL = CGPoint(x: -18, y: 31)
            p.elbowR = CGPoint(x: 2, y: -26); p.handR = CGPoint(x: -18, y: -39)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // vuelve al centro, brazos aun arriba
        K9(1.5, P9 { p in
            p.hipHeight = 57; p.squash = 1.04; p.neckOff = CGPoint(x: 0, y: -44); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -14, y: -16); p.handL = CGPoint(x: -20, y: -40)
            p.elbowR = CGPoint(x: 14, y: -16); p.handR = CGPoint(x: 20, y: -40)
            p.kneeL = CGPoint(x: -8, y: 27); p.footL = CGPoint(x: -9, y: 57)
            p.kneeR = CGPoint(x: 8, y: 27); p.footR = CGPoint(x: 9, y: 57)
        }, .easeInOut), // se dobla a la DERECHA (espejo)
        K9(1.85, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 16, y: -36); p.headOff = CGPoint(x: 8, y: -20)
            p.elbowL = CGPoint(x: -2, y: -26); p.handL = CGPoint(x: 16, y: -40)
            p.elbowR = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 18, y: 30)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // aguanta un pelo
        K9(2.1, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 17, y: -35); p.headOff = CGPoint(x: 8, y: -20)
            p.elbowL = CGPoint(x: -2, y: -26); p.handL = CGPoint(x: 18, y: -39)
            p.elbowR = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 18, y: 31)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .backOut), // suelta: los brazos bajan flotando y el cuerpo "respira" al sitio
        K9(2.4, SkeletonPose.standing)
    ])

    // -- Cabecear (dormirse DE PIE): el sueno le vence en vertical.
    // La cabeza se hunde en DOS tiempos (con un micro-bob en el
    // fondo, a punto de caer) y de golpe se despierta sobresaltado,
    // mira a los lados por si le han visto y vuelve a hundirse:
    // el bucle ES el gag. Distinto de sleep (tumbado, dormido de
    // verdad) y de yawn (un bostezo suelto): esto es la LUCHA
    // contra el sueno, de pie y con verguenza.
    static let nodOff = AnimationClip(name: "cabecear", duration: 3.0, loops: true, keyframes: [
        K9(0.0, P9 { p in // de pie, ya con sueno: brazos muertos, mirada baja
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -17, y: 20); p.handL = CGPoint(x: -20, y: 41)
            p.elbowR = CGPoint(x: 17, y: 20); p.handR = CGPoint(x: 20, y: 41)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // la cabeza empieza a hundirse
        K9(0.7, P9 { p in
            p.hipHeight = 54; p.squash = 0.99; p.neckOff = CGPoint(x: 3, y: -38); p.headOff = CGPoint(x: 3, y: -16)
            p.elbowL = CGPoint(x: -17, y: 20); p.handL = CGPoint(x: -20, y: 41)
            p.elbowR = CGPoint(x: 17, y: 20); p.handR = CGPoint(x: 20, y: 41)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -13, y: 54)
            p.kneeR = CGPoint(x: 11, y: 26); p.footR = CGPoint(x: 13, y: 54)
        }, .easeInOut), // se hunde del todo: barbilla al pecho, rodillas flojas
        K9(1.3, P9 { p in
            p.hipHeight = 52; p.squash = 0.97; p.neckOff = CGPoint(x: 6, y: -34); p.headOff = CGPoint(x: 5, y: -11)
            p.elbowL = CGPoint(x: -17, y: 21); p.handL = CGPoint(x: -20, y: 42)
            p.elbowR = CGPoint(x: 17, y: 21); p.handR = CGPoint(x: 20, y: 42)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -13, y: 52)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 13, y: 52)
        }, .linear), // micro-bob en el fondo: esta A PUNTO de desplomarse
        K9(1.6, P9 { p in
            p.hipHeight = 52; p.squash = 0.97; p.neckOff = CGPoint(x: 6, y: -33); p.headOff = CGPoint(x: 5, y: -10)
            p.elbowL = CGPoint(x: -17, y: 21); p.handL = CGPoint(x: -20, y: 42)
            p.elbowR = CGPoint(x: 17, y: 21); p.handR = CGPoint(x: 20, y: 42)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -13, y: 52)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 13, y: 52)
        }, .snappy), // ¡SE DESPIERTA DE GOLPE! erguido, brazos abiertos del susto
        K9(1.78, P9 { p in
            p.hipHeight = 57; p.squash = 1.03; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -19, y: 18); p.handL = CGPoint(x: -24, y: 36)
            p.elbowR = CGPoint(x: 19, y: 18); p.handR = CGPoint(x: 24, y: 36)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 57)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 57)
        }, .easeInOut), // mira a un lado: ¿me ha visto alguien?
        K9(2.2, P9 { p in
            p.hipHeight = 56; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: -6, y: -23)
            p.elbowL = CGPoint(x: -18, y: 19); p.handL = CGPoint(x: -22, y: 38)
            p.elbowR = CGPoint(x: 18, y: 19); p.handR = CGPoint(x: 22, y: 38)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .easeInOut), // y al otro
        K9(2.55, P9 { p in
            p.hipHeight = 56; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 6, y: -23)
            p.elbowL = CGPoint(x: -18, y: 19); p.handL = CGPoint(x: -22, y: 38)
            p.elbowR = CGPoint(x: 18, y: 19); p.handR = CGPoint(x: 22, y: 38)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .easeInOut) // nadie mira... y el sueno vuelve a bajarle la cabeza (cierra el ciclo)
    ])

    // -- Rodar DORMIDO: durmiendo de un lado, se remueve, pedalea
    // un poco, se recoge en bola y RUEDA entero al otro lado sin
    // despertarse, donde sigue durmiendo en la pose espejo de
    // `sleep`. Es un one-shot de transicion (el cerebro lo lanza
    // dentro del estado de sueno, entre dos `sleep`). Sin rotacion
    // global: la rodada se construye como en el pino de la v8 —
    // compresion, un keyframe "a la espalda" con las extremidades
    // revueltas y asentamiento al otro lado.
    static let sleepRoll = AnimationClip(name: "rodar-dormido", duration: 1.8, loops: false, keyframes: [
        K9(0.0, P9 { p in // dormido de un lado (pose de sleep, lado A)
            p.hipHeight = 11; p.neckOff = CGPoint(x: -32, y: -3); p.headOff = CGPoint(x: -19, y: -2)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: -10, y: 8)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: -16, y: 6)
            p.kneeL = CGPoint(x: 22, y: 5); p.footL = CGPoint(x: 44, y: 9)
            p.kneeR = CGPoint(x: 20, y: 1); p.footR = CGPoint(x: 42, y: 3)
        }, .easeInOut), // se remueve: un brazo busca y las piernas pedalean en el aire
        K9(0.45, P9 { p in
            p.hipHeight = 11; p.neckOff = CGPoint(x: -30, y: -4); p.headOff = CGPoint(x: -17, y: -3)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: -6, y: 10)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: -24, y: 2)
            p.kneeL = CGPoint(x: 20, y: 6); p.footL = CGPoint(x: 38, y: 10)
            p.kneeR = CGPoint(x: 21, y: 2); p.footR = CGPoint(x: 46, y: 6)
        }, .easeInOut), // se recoge en bola cogiendo impulso
        K9(0.8, P9 { p in
            p.hipHeight = 10; p.squash = 0.94; p.neckOff = CGPoint(x: -24, y: -2); p.headOff = CGPoint(x: -13, y: -1)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -4, y: 10)
            p.elbowR = CGPoint(x: 12, y: 14); p.handR = CGPoint(x: 2, y: 8)
            p.kneeL = CGPoint(x: -14, y: 8); p.footL = CGPoint(x: 28, y: 12)
            p.kneeR = CGPoint(x: -12, y: 6); p.footR = CGPoint(x: 24, y: 10)
        }, .snappy), // ¡RUEDA! el instante a la espalda, todo revuelto
        K9(1.05, P9 { p in
            p.hipHeight = 12; p.squash = 0.96; p.neckOff = CGPoint(x: -4, y: -10); p.headOff = CGPoint(x: -2, y: -6)
            p.elbowL = CGPoint(x: -16, y: 4); p.handL = CGPoint(x: -20, y: -2)
            p.elbowR = CGPoint(x: 14, y: 2); p.handR = CGPoint(x: 18, y: -4)
            p.kneeL = CGPoint(x: -16, y: 10); p.footL = CGPoint(x: -30, y: 14)
            p.kneeR = CGPoint(x: 16, y: 8); p.footR = CGPoint(x: 28, y: 12)
        }, .easeOut), // cae al otro lado y se asienta (lado B, espejo)
        K9(1.35, P9 { p in
            p.hipHeight = 11; p.neckOff = CGPoint(x: 30, y: -4); p.headOff = CGPoint(x: 17, y: -3)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: 18, y: 6)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: 12, y: 8)
            p.kneeL = CGPoint(x: -20, y: 4); p.footL = CGPoint(x: -40, y: 8)
            p.kneeR = CGPoint(x: -18, y: 2); p.footR = CGPoint(x: -38, y: 4)
        }, .easeInOut), // respiracion profunda: sigue dormido como si nada (pose espejo de sleep)
        K9(1.8, P9 { p in
            p.hipHeight = 11; p.neckOff = CGPoint(x: 32, y: -3); p.headOff = CGPoint(x: 19, y: -2)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: 16, y: 6)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: 10, y: 8)
            p.kneeL = CGPoint(x: -22, y: 5); p.footL = CGPoint(x: -44, y: 9)
            p.kneeR = CGPoint(x: -20, y: 1); p.footR = CGPoint(x: -42, y: 3)
        })
    ])

    // -- Sentado con las piernas CRUZADAS en el suelo: la variante
    // de suelo del catalogo (sit tiene variantes de piernas en la
    // spec) que faltaba. NO es meditate (v7): aquel FLOTA en el
    // aire en postura zen; este esta en el SUELO (cadera 24),
    // manos sobre las rodillas, esperando — y su vida es de
    // espera impaciente: balanceo, un pie cruzado que golpea el
    // suelo y cambios de peso. Rodillas fuera, pies cruzados al
    // lado contrario (como meditate, pero pegado al suelo).
    static let sitCrossed = AnimationClip(name: "sentado-cruzado", duration: 3.2, loops: true, keyframes: [
        K9(0.0, P9 { p in // cruzado en el suelo, manos en las rodillas, respira
            p.hipHeight = 24; p.neckOff = CGPoint(x: 0, y: -36); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16) // mano sobre la rodilla
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 22)  // pie izquierdo cruzado a la derecha
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 22)  // pie derecho cruzado a la izquierda
        }, .easeInOut), // balanceo a un lado con la respiracion
        K9(0.8, P9 { p in
            p.hipHeight = 24; p.hipDX = 2; p.neckOff = CGPoint(x: 1, y: -35); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 22)
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 20) // el pie cruzado empieza a golpear
        }, .linear), // TOC TOC: el pie golpea el suelo (la espera se nota)
        K9(1.05, P9 { p in
            p.hipHeight = 24; p.hipDX = 2; p.neckOff = CGPoint(x: 1, y: -35); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 22)
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 23)
        }, .linear),
        K9(1.3, P9 { p in
            p.hipHeight = 24; p.hipDX = 2; p.neckOff = CGPoint(x: 1, y: -35); p.headOff = CGPoint(x: 4, y: -20) // ladea la cabeza
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 22)
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 20)
        }, .easeInOut), // balanceo al otro lado; ahora golpea el otro pie, una vez
        K9(2.1, P9 { p in
            p.hipHeight = 24; p.hipDX = -2; p.neckOff = CGPoint(x: -1, y: -35); p.headOff = CGPoint(x: -3, y: -21)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 20)
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 22)
        }, .linear),
        K9(2.35, P9 { p in
            p.hipHeight = 24; p.hipDX = -2; p.neckOff = CGPoint(x: -1, y: -35); p.headOff = CGPoint(x: -3, y: -21)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -17, y: 16)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 17, y: 16)
            p.kneeL = CGPoint(x: -18, y: 10); p.footL = CGPoint(x: 12, y: 22)
            p.kneeR = CGPoint(x: 18, y: 10); p.footR = CGPoint(x: -12, y: 22)
        }, .easeInOut) // vuelve al centro: el ciclo se cierra en la pose inicial
    ])

    // -- Agacharse a MIRAR algo en el suelo: cuclillas profundas
    // frente a una cosita que ha encontrado (o que acaba de
    // dibujar), la toca dos veces con un dedo y la segunda vez LA
    // COSA SE MUEVE: respingo, y vuelve a inclinarse fascinado.
    // Es el beat de curiosidad de AvA 4 sin necesidad de props:
    // la vista solo tiene que poner "la cosa" bajo su dedo en las
    // marcas de toque (0.75 y 1.35). Distinto de hide (agazapado
    // tras un objeto, defensivo) y de crawl (a gatas, locomocion).
    static let crouchInspect = AnimationClip(name: "agacharse-mirar", duration: 2.8, loops: true, keyframes: [
        K9(0.0, P9 { p in // cuclillas mirando la cosa, una mano en la rodilla
            p.hipHeight = 26; p.squash = 0.94; p.neckOff = CGPoint(x: 14, y: -26); p.headOff = CGPoint(x: 8, y: -14)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 26, y: 30) // el dedo, cerca de la cosa
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 26)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 26)
        }, .easeInOut), // se inclina mas cerca, a punto de tocar
        K9(0.5, P9 { p in
            p.hipHeight = 25; p.squash = 0.94; p.neckOff = CGPoint(x: 17, y: -24); p.headOff = CGPoint(x: 10, y: -12)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 17, y: 17); p.handR = CGPoint(x: 28, y: 32)
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 25)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 25)
        }, .snappy), // TOQUE 1: la pincha con el dedo
        K9(0.75, P9 { p in
            p.hipHeight = 25; p.squash = 0.93; p.neckOff = CGPoint(x: 18, y: -23); p.headOff = CGPoint(x: 10, y: -12)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 30, y: 34) // contacto
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 25)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 25)
        }, .easeOut), // retira el dedo y ladea la cabeza: ¿que es esto?
        K9(1.1, P9 { p in
            p.hipHeight = 26; p.squash = 0.94; p.neckOff = CGPoint(x: 15, y: -25); p.headOff = CGPoint(x: 4, y: -13)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 24, y: 28)
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 26)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 26)
        }, .snappy), // TOQUE 2
        K9(1.35, P9 { p in
            p.hipHeight = 25; p.squash = 0.93; p.neckOff = CGPoint(x: 18, y: -23); p.headOff = CGPoint(x: 10, y: -12)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 30, y: 34)
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 25)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 25)
        }, .snappy), // ¡LA COSA SE HA MOVIDO! respingo entero, manos arriba
        K9(1.6, P9 { p in
            p.hipHeight = 29; p.squash = 0.97; p.neckOff = CGPoint(x: 8, y: -28); p.headOff = CGPoint(x: 5, y: -16)
            p.elbowL = CGPoint(x: -16, y: 10); p.handL = CGPoint(x: -14, y: 14)
            p.elbowR = CGPoint(x: 14, y: 12); p.handR = CGPoint(x: 16, y: 18) // la mano, retirada de golpe
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -19, y: 29)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 19, y: 29)
        }, .easeInOut), // pero la curiosidad gana: vuelve a inclinarse, fascinado
        K9(2.2, P9 { p in
            p.hipHeight = 26; p.squash = 0.94; p.neckOff = CGPoint(x: 15, y: -25); p.headOff = CGPoint(x: 9, y: -13)
            p.elbowL = CGPoint(x: -16, y: 12); p.handL = CGPoint(x: -16, y: 20)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 26, y: 29) // el dedo flota sobre la cosa, sin tocar (esta vez no)
            p.kneeL = CGPoint(x: -16, y: 14); p.footL = CGPoint(x: -18, y: 26)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 18, y: 26)
        }, .easeInOut) // se asienta en la cuclilla inicial: el ciclo se cierra
    ])

    // ============================================================
    // MARK: Pasada 4 - TSC / DIBUJO (la firma de The Second Coming)
    // En AvA 4, TSC dibuja cosas y COBRAN VIDA. drawWithPencil ya
    // cubre el acto de dibujar en si; esta serie es lo que pasa
    // DESPUES del trazo: soltar lo dibujado, montarlo, cuidarlo,
    // usarlo como herramienta y hasta dirigirlo. Las criaturas y
    // objetos los dibuja la vista (trazo del usuario o trazo
    // procedural); el clip pone el cuerpo de TSC en cada papel.
    // ============================================================

    // -- Soltar el pajaro dibujado: termina un trazo bajo (con el
    // "lapiz" aun en las manos), presenta la criatura con las dos
    // manos abiertas y la SUELTA hacia arriba: los brazos se
    // abren al cielo, la cabeza la sigue subiendo, la mira dar
    // una vuelta (la mirada cruza de un lado a otro) y baja los
    // brazos despacio, con un asentimiento de orgullo. La vista
    // hace nacer el pajaro de trazo entre sus manos en la marca
    // de suelta (0.75) y lo vuela en circulo sobre el.
    static let releaseBird = AnimationClip(name: "soltar-pajaro", duration: 2.4, loops: false, keyframes: [
        K9(0.0, P9 { p in // ultimo trazo: inclinado sobre el dibujo, manos bajas juntas
            p.hipHeight = 50; p.neckOff = CGPoint(x: 7, y: -38); p.headOff = CGPoint(x: 3, y: -20)
            p.elbowL = CGPoint(x: 8, y: 22); p.handL = CGPoint(x: 22, y: 28)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: 28, y: 32)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -16, y: 50)
            p.kneeR = CGPoint(x: 11, y: 26); p.footR = CGPoint(x: 18, y: 50)
        }, .easeOut), // se incorpora presentando lo dibujado, palmas abiertas
        K9(0.45, P9 { p in
            p.hipHeight = 52; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: 0, y: 14); p.handL = CGPoint(x: 12, y: 16)
            p.elbowR = CGPoint(x: 20, y: 14); p.handR = CGPoint(x: 26, y: 17)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -15, y: 52)
            p.kneeR = CGPoint(x: 11, y: 26); p.footR = CGPoint(x: 17, y: 52)
        }, .snappy), // ¡LO SUELTA! brazos abiertos al cielo, cara arriba
        K9(0.75, P9 { p in
            p.hipHeight = 54; p.squash = 1.02; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -25)
            p.elbowL = CGPoint(x: -16, y: 2); p.handL = CGPoint(x: -24, y: -12)
            p.elbowR = CGPoint(x: 16, y: 2); p.handR = CGPoint(x: 24, y: -12)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 54)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 54)
        }, .easeInOut), // lo sigue con la mirada: sube y se va a un lado
        K9(1.2, P9 { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 2, y: -42); p.headOff = CGPoint(x: 5, y: -26)
            p.elbowL = CGPoint(x: -16, y: 6); p.handL = CGPoint(x: -22, y: -4)
            p.elbowR = CGPoint(x: 16, y: 6); p.handR = CGPoint(x: 22, y: -4)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 54)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 54)
        }, .easeInOut), // la vuelta del pajaro le cruza la mirada al otro lado
        K9(1.7, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: -5, y: -25)
            p.elbowL = CGPoint(x: -17, y: 10); p.handL = CGPoint(x: -21, y: 6)
            p.elbowR = CGPoint(x: 17, y: 10); p.handR = CGPoint(x: 21, y: 6)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 53)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 53)
        }, .easeInOut), // se aleja volando: baja los brazos y asiente, orgulloso de su obra
        K9(2.1, P9 { p in
            p.hipHeight = 52; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -19) // el asentimiento
            p.elbowL = CGPoint(x: -17, y: 17); p.handL = CGPoint(x: -20, y: 36)
            p.elbowR = CGPoint(x: 17, y: 17); p.handR = CGPoint(x: 20, y: 36)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 52)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 52)
        }, .backOut),
        K9(2.4, SkeletonPose.standing)
    ])

    // -- Montar el caballo dibujado: bucle de trote del JINETE (el
    // caballo de trazo lo pone la vista bajo el; el avance lo pone
    // el motor). Sentado alto (cadera 40: la montura), piernas
    // colgando a ambos lados con los pies en "estribo", las dos
    // manos delante agarrando las riendas a la altura del pecho.
    // El trote es de dos tiempos (patron de run reducido a
    // cadera y manos): rebote lineal corto, las riendas botan en
    // contrafase y la cabeza va clavada al frente absorbiendo.
    // Una vez por ciclo tira de las riendas y levanta la barbilla.
    static let rideHorse = AnimationClip(name: "montar-caballo", duration: 1.4, loops: true, keyframes: [
        K9(0.0, P9 { p in // a caballo: sentado en la montura, riendas en las manos
            p.hipHeight = 40; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 2, y: 12); p.handL = CGPoint(x: 14, y: 6)   // rienda izquierda
            p.elbowR = CGPoint(x: 16, y: 12); p.handR = CGPoint(x: 24, y: 7)  // rienda derecha
            p.kneeL = CGPoint(x: -14, y: 16); p.footL = CGPoint(x: -15, y: 36) // pierna colgando al costado
            p.kneeR = CGPoint(x: 14, y: 16); p.footR = CGPoint(x: 15, y: 36)
        }, .linear), // trote, tiempo 1: rebote arriba
        K9(0.18, P9 { p in
            p.hipHeight = 43; p.squash = 1.02; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 2, y: 11); p.handL = CGPoint(x: 13, y: 4)
            p.elbowR = CGPoint(x: 16, y: 11); p.handR = CGPoint(x: 23, y: 5)
            p.kneeL = CGPoint(x: -14, y: 17); p.footL = CGPoint(x: -17, y: 37) // los pies se atrasan un pelo
            p.kneeR = CGPoint(x: 14, y: 17); p.footR = CGPoint(x: 13, y: 37)
        }, .linear), // tiempo 2: cae al paso siguiente
        K9(0.36, P9 { p in
            p.hipHeight = 40; p.squash = 0.98; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: 2, y: 13); p.handL = CGPoint(x: 15, y: 8)
            p.elbowR = CGPoint(x: 16, y: 13); p.handR = CGPoint(x: 25, y: 9)
            p.kneeL = CGPoint(x: -14, y: 15); p.footL = CGPoint(x: -14, y: 35)
            p.kneeR = CGPoint(x: 14, y: 15); p.footR = CGPoint(x: 16, y: 35)
        }, .linear), // tiempo 1 otra vez (con micro-desfase de cadera)
        K9(0.54, P9 { p in
            p.hipHeight = 43; p.squash = 1.02; p.hipDX = 1; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 2, y: 11); p.handL = CGPoint(x: 13, y: 4)
            p.elbowR = CGPoint(x: 16, y: 11); p.handR = CGPoint(x: 23, y: 5)
            p.kneeL = CGPoint(x: -14, y: 17); p.footL = CGPoint(x: -16, y: 37)
            p.kneeR = CGPoint(x: 14, y: 17); p.footR = CGPoint(x: 14, y: 37)
        }, .linear), // tiempo 2
        K9(0.72, P9 { p in
            p.hipHeight = 40; p.squash = 0.98; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: 2, y: 13); p.handL = CGPoint(x: 15, y: 8)
            p.elbowR = CGPoint(x: 16, y: 13); p.handR = CGPoint(x: 25, y: 9)
            p.kneeL = CGPoint(x: -14, y: 15); p.footL = CGPoint(x: -14, y: 35)
            p.kneeR = CGPoint(x: 14, y: 15); p.footR = CGPoint(x: 16, y: 35)
        }, .easeInOut), // tira de las riendas y levanta la barbilla: pose de jinete sobrado
        K9(1.0, P9 { p in
            p.hipHeight = 41; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: 0, y: 14); p.handL = CGPoint(x: 10, y: 8)  // riendas recogidas
            p.elbowR = CGPoint(x: 14, y: 14); p.handR = CGPoint(x: 20, y: 9)
            p.kneeL = CGPoint(x: -13, y: 15); p.footL = CGPoint(x: -13, y: 34) // talones un pelo adelante
            p.kneeR = CGPoint(x: 13, y: 15); p.footR = CGPoint(x: 17, y: 34)
        }, .easeInOut) // suelta las riendas a su sitio: el trote sigue (cierra el ciclo)
    ])

    // -- Acariciar a su criatura: de rodillas sobre UNA rodilla
    // junto a la criatura (la vista la dibuja a su derecha, a la
    // altura de su mano), le pasa la mano por el lomo en arcos
    // completos: baja deslizandose hacia delante, se levanta por
    // detras y vuelve. Dos caricias por ciclo, la segunda mas
    // lenta y con la cabeza mas baja: esta a gusto. La otra mano
    // se apoya en su propia rodilla plantada. Ritmo de caricia
    // real: el deslizamiento es el tramo LARGO; la vuelta, corta.
    static let petCreature = AnimationClip(name: "acariciar-criatura", duration: 2.6, loops: true, keyframes: [
        K9(0.0, P9 { p in // arrodillado junto a la criatura, mano al inicio del lomo
            p.hipHeight = 30; p.neckOff = CGPoint(x: 8, y: -32); p.headOff = CGPoint(x: 5, y: -16)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24) // mano apoyada en su rodilla
            p.elbowR = CGPoint(x: 14, y: 8); p.handR = CGPoint(x: 24, y: 20)    // mano sobre la criatura, atras
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10) // rodilla izquierda en el suelo
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 30)    // pie derecho plantado
        }, .easeInOut), // caricia 1: la mano se desliza por el lomo hacia delante
        K9(0.45, P9 { p in
            p.hipHeight = 30; p.neckOff = CGPoint(x: 9, y: -31); p.headOff = CGPoint(x: 5, y: -16)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24)
            p.elbowR = CGPoint(x: 17, y: 11); p.handR = CGPoint(x: 31, y: 26)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10)
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 30)
        }, .easeInOut), // fin de la caricia: la mano llega al cuello de la criatura
        K9(0.85, P9 { p in
            p.hipHeight = 30; p.neckOff = CGPoint(x: 9, y: -31); p.headOff = CGPoint(x: 6, y: -15)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24)
            p.elbowR = CGPoint(x: 18, y: 12); p.handR = CGPoint(x: 34, y: 28)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10)
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 30)
        }, .easeInOut), // la mano se levanta y vuelve por encima (tramo corto)
        K9(1.3, P9 { p in
            p.hipHeight = 30; p.neckOff = CGPoint(x: 8, y: -32); p.headOff = CGPoint(x: 4, y: -17)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24)
            p.elbowR = CGPoint(x: 14, y: 8); p.handR = CGPoint(x: 24, y: 20)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10)
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 30)
        }, .easeInOut), // caricia 2, mas lenta: se inclina mas sobre la criatura
        K9(1.85, P9 { p in
            p.hipHeight = 29; p.neckOff = CGPoint(x: 10, y: -30); p.headOff = CGPoint(x: 6, y: -14)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24)
            p.elbowR = CGPoint(x: 17, y: 11); p.handR = CGPoint(x: 31, y: 26)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10)
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 29)
        }, .easeInOut), // fin de la segunda caricia
        K9(2.25, P9 { p in
            p.hipHeight = 29; p.neckOff = CGPoint(x: 10, y: -30); p.headOff = CGPoint(x: 6, y: -14)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -10, y: 24)
            p.elbowR = CGPoint(x: 18, y: 12); p.handR = CGPoint(x: 34, y: 28)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -14, y: 10)
            p.kneeR = CGPoint(x: 14, y: 14); p.footR = CGPoint(x: 16, y: 29)
        }, .easeInOut) // levanta la mano y el ciclo vuelve a empezar
    ])

    // -- Dar de comer a su criatura: de pie, inclinado sobre la
    // criatura que tiene a los pies (la vista la dibuja delante-
    // abajo), le ofrece comida con los dedos: extiende la mano
    // baja, la "espolvorea" con tres micro-sacudidas (tramos
    // lineales cortos), la retira a la "bolsa" que sostiene la
    // otra mano a la cadera, coge mas y vuelve a ofrecer, esta
    // vez mas bajo (la criatura se ha acercado). Distinto de
    // eatSnack (el come) y de petCreature (rodilla en el suelo,
    // caricias): aqui es el ritual de alimentar, de pie.
    static let feedCreature = AnimationClip(name: "dar-de-comer", duration: 2.2, loops: true, keyframes: [
        K9(0.0, P9 { p in // inclinado, ofreciendo la primera tanda con la mano baja
            p.hipHeight = 48; p.squash = 0.98; p.neckOff = CGPoint(x: 12, y: -34); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26) // sostiene la "bolsa" a la cadera
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 28, y: 32)   // la mano que ofrece
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .linear), // espolvorea: tres micro-sacudidas de dedos
        K9(0.25, P9 { p in
            p.hipHeight = 48; p.squash = 0.98; p.neckOff = CGPoint(x: 12, y: -34); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 29, y: 34)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .linear),
        K9(0.4, P9 { p in
            p.hipHeight = 48; p.squash = 0.98; p.neckOff = CGPoint(x: 12, y: -34); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 28, y: 33)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .linear),
        K9(0.55, P9 { p in
            p.hipHeight = 48; p.squash = 0.98; p.neckOff = CGPoint(x: 12, y: -34); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 29, y: 34)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .easeInOut), // retira la mano a la bolsa a coger mas (mira la bolsa)
        K9(0.95, P9 { p in
            p.hipHeight = 48; p.neckOff = CGPoint(x: 10, y: -35); p.headOff = CGPoint(x: 4, y: -18)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 8, y: 16); p.handR = CGPoint(x: 2, y: 22) // metiendo la mano en la bolsa
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .easeInOut), // ofrece la segunda tanda, MAS BAJA (la criatura ya esta a sus pies)
        K9(1.45, P9 { p in
            p.hipHeight = 47; p.squash = 0.98; p.neckOff = CGPoint(x: 13, y: -33); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 30, y: 35)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 47)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 47)
        }, .linear), // espolvorea otra vez
        K9(1.65, P9 { p in
            p.hipHeight = 47; p.squash = 0.98; p.neckOff = CGPoint(x: 13, y: -33); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 31, y: 36)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 47)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 47)
        }, .linear),
        K9(1.8, P9 { p in
            p.hipHeight = 47; p.squash = 0.98; p.neckOff = CGPoint(x: 13, y: -33); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 30, y: 35)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 47)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 47)
        }, .easeInOut), // se retira a medias y la mira comer, complacido
        K9(2.0, P9 { p in
            p.hipHeight = 48; p.neckOff = CGPoint(x: 11, y: -34); p.headOff = CGPoint(x: 5, y: -17)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -12, y: 26)
            p.elbowR = CGPoint(x: 16, y: 15); p.handR = CGPoint(x: 24, y: 28)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .easeInOut) // y vuelve a ofrecer: el ciclo se cierra en la pose inicial
    ])

    // -- Dibujar una escalera y SUBIRLA: secuencia completa en
    // one-shot. Dibuja los peldaños bajos delante (dos trazos con
    // las dos manos, familia drawWithPencil), se incorpora a
    // admirarla con las manos en la cadera, y la sube: peldano 1
    // (un pie alto, el otro aun en el suelo, brazos de equilibrio)
    // y peldano 2 (mas alto), hasta quedar DE PIE ENCIMA mirando
    // abajo con orgullo. La subida real la acompana el motor
    // desplazandolo a los peldaños dibujados; el clip sube la
    // cadera por tramos (56 de referencia -> 60 -> 66 -> 68) y
    // deja los pies en las alturas relativas de cada peldano.
    // Termina en la pose de "encima": no vuelve a standing a
    // proposito (el cerebro decide desde ahi: bajar, saltar...).
    static let drawStairs = AnimationClip(name: "dibujar-escalera", duration: 3.0, loops: false, keyframes: [
        K9(0.0, P9 { p in // trazo 1: dibuja el primer peldaño, inclinado y bajo
            p.hipHeight = 48; p.neckOff = CGPoint(x: 9, y: -36); p.headOff = CGPoint(x: 4, y: -18)
            p.elbowL = CGPoint(x: 6, y: 20); p.handL = CGPoint(x: 20, y: 30)
            p.elbowR = CGPoint(x: 15, y: 22); p.handR = CGPoint(x: 27, y: 34)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 16, y: 48)
        }, .easeInOut), // trazo 2: el segundo peldaño, un poco mas alto/lejos
        K9(0.4, P9 { p in
            p.hipHeight = 48; p.neckOff = CGPoint(x: 10, y: -35); p.headOff = CGPoint(x: 4, y: -18)
            p.elbowL = CGPoint(x: 7, y: 20); p.handL = CGPoint(x: 24, y: 32)
            p.elbowR = CGPoint(x: 16, y: 22); p.handR = CGPoint(x: 31, y: 36)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 16, y: 48)
        }, .easeInOut), // se incorpora a admirarla: manos a la cadera, mirada abajo
        K9(0.8, P9 { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -18, y: 14); p.handL = CGPoint(x: -14, y: 26)
            p.elbowR = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 15, y: 26)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 54)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 54)
        }, .easeIn), // sube al PELDAÑO 1: pie derecho alto, el izquierdo aun empuja desde el suelo
        K9(1.25, P9 { p in
            p.hipHeight = 60; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -18, y: 10); p.handL = CGPoint(x: -24, y: 20) // brazos de equilibrio
            p.elbowR = CGPoint(x: 18, y: 10); p.handR = CGPoint(x: 24, y: 20)
            p.kneeL = CGPoint(x: -8, y: 32); p.footL = CGPoint(x: -10, y: 58)  // pie de empuje, abajo
            p.kneeR = CGPoint(x: 16, y: 12); p.footR = CGPoint(x: 22, y: 34)   // pie en el peldaño 1
        }, .easeInOut), // sube al PELDAÑO 2 con el pie contrario
        K9(1.7, P9 { p in
            p.hipHeight = 66; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -19, y: 8); p.handL = CGPoint(x: -26, y: 16)
            p.elbowR = CGPoint(x: 19, y: 8); p.handR = CGPoint(x: 26, y: 16)
            p.kneeL = CGPoint(x: 14, y: 14); p.footL = CGPoint(x: 20, y: 40)   // pie en el peldaño 2
            p.kneeR = CGPoint(x: -6, y: 34); p.footR = CGPoint(x: -8, y: 64)   // el otro aun en el 1
        }, .easeOut), // CORONA: de pie encima de su escalera, brazos fuera
        K9(2.15, P9 { p in
            p.hipHeight = 68; p.squash = 1.01; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 3, y: -19) // mira ABAJO, a lo subido
            p.elbowL = CGPoint(x: -19, y: 8); p.handL = CGPoint(x: -25, y: 14)
            p.elbowR = CGPoint(x: 19, y: 8); p.handR = CGPoint(x: 25, y: 14)
            p.kneeL = CGPoint(x: -10, y: 33); p.footL = CGPoint(x: -11, y: 66)
            p.kneeR = CGPoint(x: 10, y: 33); p.footR = CGPoint(x: 11, y: 66)
        }, .easeInOut), // aguanta arriba, un mini-rebote de orgullo
        K9(2.6, P9 { p in
            p.hipHeight = 69; p.squash = 1.02; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -19, y: 8); p.handL = CGPoint(x: -25, y: 14)
            p.elbowR = CGPoint(x: 19, y: 8); p.handR = CGPoint(x: 25, y: 14)
            p.kneeL = CGPoint(x: -10, y: 33); p.footL = CGPoint(x: -11, y: 67)
            p.kneeR = CGPoint(x: 10, y: 33); p.footR = CGPoint(x: 11, y: 67)
        }, .easeInOut) // pose final: encima de la escalera (de aqui manda el cerebro)
    ])

    // -- Dibujar un paraguas cuando "llueve": mira arriba
    // preocupado (la lluvia la pone el sistema de clima/efecto de
    // la app), garabatea a toda prisa SOBRE su cabeza (las dos
    // manos arriba, trazos cortos lineales), agarra el mango en
    // cuanto aparece y se encoge debajo: una mano arriba en el
    // mango, la otra abrazandose, piernas juntas. Una rafaga lo
    // inclina entero y se repone bajo el paraguas. One-shot que
    // TERMINA en la pose de sujetarlo (la integracion la aguanta
    // mientras "llueva"): la creacion es el clip; el estado, la
    // pose final.
    static let drawUmbrella = AnimationClip(name: "dibujar-paraguas", duration: 2.8, loops: false, keyframes: [
        K9(0.0, P9 { p in // mira arriba: las primeras gotas (cara al cielo)
            p.hipHeight = 54; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: -1, y: -26)
            p.elbowL = CGPoint(x: -16, y: 16); p.handL = CGPoint(x: -18, y: 32)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 18, y: 32)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 54)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 54)
        }, .easeIn), // ¡a dibujar! las dos manos garabatean sobre la cabeza
        K9(0.3, P9 { p in
            p.hipHeight = 56; p.squash = 1.03; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -25)
            p.elbowL = CGPoint(x: -8, y: -18); p.handL = CGPoint(x: -12, y: -38)
            p.elbowR = CGPoint(x: 10, y: -16); p.handR = CGPoint(x: 16, y: -36)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .linear), // garabato rapido (la prisa se lee en tramos lineales cortos)
        K9(0.5, P9 { p in
            p.hipHeight = 56; p.squash = 1.03; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -25)
            p.elbowL = CGPoint(x: -8, y: -18); p.handL = CGPoint(x: -10, y: -36)
            p.elbowR = CGPoint(x: 10, y: -16); p.handR = CGPoint(x: 14, y: -38)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .snappy), // ¡AGARRA el mango! una mano se queda arriba; la otra se recoge
        K9(0.75, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -10, y: 20); p.handL = CGPoint(x: 4, y: 16)   // brazo libre abrazandose
            p.elbowR = CGPoint(x: 8, y: -20); p.handR = CGPoint(x: 10, y: -42)  // LA MANO DEL MANGO
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -10, y: 53)  // piernas juntas, bajo el paraguas
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 10, y: 53)
        }, .easeInOut), // RAFAGA: la lluvia lo empuja y se inclina entero agarrando fuerte
        K9(1.3, P9 { p in
            p.hipHeight = 53; p.hipDX = 3; p.neckOff = CGPoint(x: 6, y: -38); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: -10, y: 20); p.handL = CGPoint(x: 5, y: 15)
            p.elbowR = CGPoint(x: 9, y: -20); p.handR = CGPoint(x: 12, y: -41)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -13, y: 53) // pies abiertos, atrincherado
            p.kneeR = CGPoint(x: 10, y: 26); p.footR = CGPoint(x: 14, y: 53)
        }, .easeInOut), // pasa la rafaga: vuelve a su sitio bajo el paraguas
        K9(1.9, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -10, y: 20); p.handL = CGPoint(x: 4, y: 16)
            p.elbowR = CGPoint(x: 8, y: -20); p.handR = CGPoint(x: 10, y: -42)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -10, y: 53)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 10, y: 53)
        }, .easeInOut), // se sacude las gotas de la mano libre
        K9(2.35, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: -18, y: 10); p.handL = CGPoint(x: -26, y: 18) // sacudida fuera del paraguas
            p.elbowR = CGPoint(x: 8, y: -20); p.handR = CGPoint(x: 10, y: -42)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -10, y: 53)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 10, y: 53)
        }, .easeInOut), // pose final: sujetando el paraguas, seco y a salvo
        K9(2.8, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -10, y: 20); p.handL = CGPoint(x: 4, y: 16)
            p.elbowR = CGPoint(x: 8, y: -20); p.handR = CGPoint(x: 10, y: -42)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -10, y: 53)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 10, y: 53)
        })
    ])

    // -- Dirigir a sus criaturas como una ORQUESTA: TSC con el
    // "lapiz-batuta" en la mano derecha marca un 4/4 de manual —
    // abajo (fuerte, con squash), dentro, fuera, arriba — y la
    // mano izquierda hace de espejo expresivo (pianos, avisos,
    // crescendos). Al final de cada ciclo, una floritura: levanta
    // las dos manos en crescendo y el golpe final cae con el
    // primer tiempo del ciclo siguiente. Es el papel de "creador
    // que gobierna lo creado" de AvA 4 llevado a gesto puro. Las
    // criaturas (vista) reaccionan a las marcas 0.35/0.8/1.25/1.7.
    static let conduct = AnimationClip(name: "dirigir-orquesta", duration: 3.0, loops: true, keyframes: [
        K9(0.0, P9 { p in // batuta arriba, listo: tiempo 4 del ciclo anterior
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -15, y: -2); p.handL = CGPoint(x: -18, y: -8)
            p.elbowR = CGPoint(x: 12, y: -8); p.handR = CGPoint(x: 16, y: -20) // la batuta
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 55)
        }, .easeIn), // TIEMPO 1: abajo, fuerte, todo el cuerpo marca
        K9(0.35, P9 { p in
            p.hipHeight = 53; p.squash = 0.96; p.neckOff = CGPoint(x: 3, y: -39); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -14, y: 6); p.handL = CGPoint(x: -14, y: 8)
            p.elbowR = CGPoint(x: 13, y: 8); p.handR = CGPoint(x: 18, y: 16)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -12, y: 53)
            p.kneeR = CGPoint(x: 11, y: 26); p.footR = CGPoint(x: 12, y: 53)
        }, .easeOut), // TIEMPO 2: dentro, suave
        K9(0.8, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -16, y: 2); p.handL = CGPoint(x: -18, y: 2)
            p.elbowR = CGPoint(x: 7, y: 2); p.handR = CGPoint(x: 4, y: 0)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 55)
        }, .easeOut), // TIEMPO 3: fuera, amplio
        K9(1.25, P9 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -13, y: -2); p.handL = CGPoint(x: -10, y: -4)
            p.elbowR = CGPoint(x: 20, y: 0); p.handR = CGPoint(x: 30, y: -2)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 55)
        }, .easeIn), // TIEMPO 4: arriba, recogiendo para el crescendo
        K9(1.7, P9 { p in
            p.hipHeight = 56; p.squash = 1.01; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -15, y: -6); p.handL = CGPoint(x: -16, y: -14) // la izquierda tambien sube
            p.elbowR = CGPoint(x: 12, y: -8); p.handR = CGPoint(x: 16, y: -20)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 56)
        }, .easeInOut), // se balancea avisando a las criaturas (las mira)
        K9(2.2, P9 { p in
            p.hipHeight = 55; p.hipDX = 2; p.neckOff = CGPoint(x: 2, y: -42); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -17, y: -4); p.handL = CGPoint(x: -20, y: -10)
            p.elbowR = CGPoint(x: 14, y: -6); p.handR = CGPoint(x: 20, y: -16)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 55)
        }, .snappy), // FLORITURA: se estira entero preparando el golpe final
        K9(2.6, P9 { p in
            p.hipHeight = 57; p.squash = 1.03; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -15, y: -6); p.handL = CGPoint(x: -18, y: -16)
            p.elbowR = CGPoint(x: 9, y: -12); p.handR = CGPoint(x: 10, y: -26) // batuta a lo mas alto
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -12, y: 57)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 12, y: 57)
        }, .easeInOut) // y el golpe cae como tiempo 1 del ciclo siguiente (pose inicial)
    ])

    // ============================================================
    // MARK: Pasada 4 (cont.) - Restos reales del catalogo Shimeji
    // Del cruce completo del catalogo (SHIMEJI_SPEC.md + las 91
    // acciones del conf de TCO/TSC) quedaban sin mapear: FallWithIe
    // y ThrowIe (la pareja de walkLoaded/liftHuge: caer CON el
    // objeto y deshacerse de el lanzandolo) y los despegues
    // JumpFromWall/JumpFromCeiling. De techo no hace falta clip:
    // soltarse del techo ES entrar en fallPose (ver descartes en
    // el changelog). De pared si: no existia despegue propio.
    // ============================================================

    // -- Caer SUJETANDO el objeto (FallWithIe): pierde el apoyo
    // cargando y cae SIN SOLTAR la carga: los brazos van cruzados
    // sobre el pecho abrazando el bulto durante toda la caida
    // (fallPose agita los brazos libres buscando aire; aqui los
    // brazos tienen prohibido moverse de su abrazo). El cuerpo va
    // mas rigido y vertical, las piernas buscan el suelo juntas,
    // y el aterrizaje se absorbe en cuclillas CON el objeto a
    // salvo, encadenable a strengthPose/walkLoaded al levantarse.
    static let fallWithObject = AnimationClip(name: "caer-con-objeto", duration: 1.15, loops: false, keyframes: [
        K9(0.0, P9 { p in // en el aire, ya abrazado a la carga
            p.hipHeight = 58; p.squash = 1.04; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -4, y: 14); p.handL = CGPoint(x: 12, y: 8)  // mano cruzada sujetando
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 0, y: 10)  // la otra, cruzada encima
            p.kneeL = CGPoint(x: -8, y: 24); p.footL = CGPoint(x: -12, y: 44) // piernas recogidas, juntas
            p.kneeR = CGPoint(x: 8, y: 26); p.footR = CGPoint(x: 10, y: 46)
        }, .powerIn), // cae: el abrazo se aprieta, las piernas buscan el suelo
        K9(0.3, P9 { p in
            p.hipHeight = 54; p.squash = 1.05; p.neckOff = CGPoint(x: 3, y: -39); p.headOff = CGPoint(x: 3, y: -19)
            p.elbowL = CGPoint(x: -5, y: 13); p.handL = CGPoint(x: 13, y: 7)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 1, y: 9)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -11, y: 50)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 11, y: 50)
        }, .powerIn), // ultimo tramo: se prepara sin soltar (barbilla dentro, rodillas listas)
        K9(0.5, P9 { p in
            p.hipHeight = 50; p.squash = 1.03; p.neckOff = CGPoint(x: 5, y: -37); p.headOff = CGPoint(x: 3, y: -17)
            p.elbowL = CGPoint(x: -5, y: 13); p.handL = CGPoint(x: 13, y: 7)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 1, y: 9)
            p.kneeL = CGPoint(x: -12, y: 24); p.footL = CGPoint(x: -14, y: 48)
            p.kneeR = CGPoint(x: 12, y: 24); p.footR = CGPoint(x: 14, y: 48)
        }, .linear), // IMPACTO con los pies: la carga no se entera
        K9(0.62, P9 { p in
            p.hipHeight = 38; p.squash = 0.88; p.neckOff = CGPoint(x: 10, y: -30); p.headOff = CGPoint(x: 5, y: -15)
            p.elbowL = CGPoint(x: -5, y: 13); p.handL = CGPoint(x: 13, y: 7)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 1, y: 9)
            p.kneeL = CGPoint(x: -15, y: 18); p.footL = CGPoint(x: -18, y: 38)
            p.kneeR = CGPoint(x: 15, y: 18); p.footR = CGPoint(x: 18, y: 38)
        }, .easeOut), // bamboleo de recuperacion, aun abrazado
        K9(0.85, P9 { p in
            p.hipHeight = 44; p.squash = 0.95; p.hipDX = -1; p.neckOff = CGPoint(x: 6, y: -36); p.headOff = CGPoint(x: 3, y: -19)
            p.elbowL = CGPoint(x: -4, y: 14); p.handL = CGPoint(x: 12, y: 8)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 0, y: 10)
            p.kneeL = CGPoint(x: -12, y: 22); p.footL = CGPoint(x: -15, y: 44)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 15, y: 44)
        }, .backOut), // de pie con la carga a salvo (de aqui, strengthPose o walkLoaded)
        K9(1.15, P9 { p in
            p.hipHeight = 51; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -4, y: 14); p.handL = CGPoint(x: 12, y: 8)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 0, y: 10)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -14, y: 51)
            p.kneeR = CGPoint(x: 11, y: 26); p.footR = CGPoint(x: 14, y: 51)
        })
    ])

    // -- Lanzar lo CARGADO (ThrowIe): la pareja de walkLoaded.
    // Entra EN la pose de carga de walkLoaded (manos arriba
    // sujetando el bulto sobre la cabeza, a media zancada
    // temblorosa), se planta, hunde la carga cargando el lanzamiento
    // y la LANZA con el cuerpo entero: arqueo, extension total y
    // los PIES DESPEGADOS del suelo en el pico del esfuerzo —
    // luego cae con las manos vacias, doblado de alivio, y se
    // sacude las manos dos veces. Distinto de throwOverhead (v7):
    // aquel es un lanzamiento ATLETICO de un objeto cogido en el
    // sitio (carga atras y arco sobre la cabeza, pies plantados);
    // este es deshacerse de un PESO que ya llevaba encima, con
    // entrada en marcha, despegue y final de descarga. La vista
    // suelta el objeto en el pico (0.5).
    static let throwLoaded = AnimationClip(name: "lanzar-carga", duration: 1.2, loops: false, keyframes: [
        K9(0.0, P9 { p in // en marcha cargada (pose de walkLoaded: manos arriba con el bulto)
            p.hipHeight = 49; p.hipDX = 2; p.neckOff = CGPoint(x: 1, y: -37); p.headOff = CGPoint(x: 1, y: -19)
            p.elbowL = CGPoint(x: -15, y: -8); p.handL = CGPoint(x: -14, y: -30)
            p.elbowR = CGPoint(x: 15, y: -8); p.handR = CGPoint(x: 15, y: -30)
            p.kneeL = CGPoint(x: -8, y: 25); p.footL = CGPoint(x: -2, y: 44)  // a media zancada
            p.kneeR = CGPoint(x: 10, y: 24); p.footR = CGPoint(x: 12, y: 49)
        }, .easeIn), // se planta y hunde la carga cargando el lanzamiento (la carga baja con el)
        K9(0.28, P9 { p in
            p.hipHeight = 44; p.squash = 0.90; p.neckOff = CGPoint(x: -3, y: -34); p.headOff = CGPoint(x: -2, y: -18)
            p.elbowL = CGPoint(x: -16, y: -4); p.handL = CGPoint(x: -15, y: -26)
            p.elbowR = CGPoint(x: 16, y: -4); p.handR = CGPoint(x: 15, y: -26)
            p.kneeL = CGPoint(x: -14, y: 20); p.footL = CGPoint(x: -18, y: 44) // pies plantados, anchos
            p.kneeR = CGPoint(x: 14, y: 20); p.footR = CGPoint(x: 18, y: 44)
        }, .snappy), // ¡LA LANZA! extension total, los pies dejan el suelo
        K9(0.5, P9 { p in
            p.hipHeight = 58; p.squash = 1.12; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 3, y: -20)
            p.elbowL = CGPoint(x: -4, y: -22); p.handL = CGPoint(x: 2, y: -44)  // manos lanzadas arriba-delante
            p.elbowR = CGPoint(x: 14, y: -20); p.handR = CGPoint(x: 20, y: -42)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 38) // en el aire
            p.kneeR = CGPoint(x: 10, y: 22); p.footR = CGPoint(x: 14, y: 40)
        }, .easeIn), // cae de vuelta, manos ya vacias y abiertas
        K9(0.68, P9 { p in
            p.hipHeight = 50; p.squash = 1.02; p.neckOff = CGPoint(x: 8, y: -37); p.headOff = CGPoint(x: 4, y: -19)
            p.elbowL = CGPoint(x: -14, y: 6); p.handL = CGPoint(x: -20, y: 16)
            p.elbowR = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 22, y: 18)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -14, y: 48)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 15, y: 48)
        }, .easeOut), // aterriza DOBLADO de alivio, manos en las rodillas: uff
        K9(0.88, P9 { p in
            p.hipHeight = 40; p.squash = 0.94; p.neckOff = CGPoint(x: 14, y: -30); p.headOff = CGPoint(x: 7, y: -15)
            p.elbowL = CGPoint(x: -8, y: 16); p.handL = CGPoint(x: -10, y: 26)
            p.elbowR = CGPoint(x: 12, y: 16); p.handR = CGPoint(x: 13, y: 26)
            p.kneeL = CGPoint(x: -13, y: 18); p.footL = CGPoint(x: -16, y: 40)
            p.kneeR = CGPoint(x: 13, y: 18); p.footR = CGPoint(x: 16, y: 40)
        }, .easeInOut), // se incorpora sacudiendose las manos (el polvo del peso)
        K9(1.05, P9 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: 0, y: 18); p.handL = CGPoint(x: 8, y: 20)  // manos juntas sacudiendose
            p.elbowR = CGPoint(x: 18, y: 16); p.handR = CGPoint(x: 14, y: 22)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 53)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 53)
        }, .backOut), // ligero otra vez: de pie y sin carga
        K9(1.2, SkeletonPose.standing)
    ])

    // -- Saltar DESDE LA PARED (JumpFromWall): el despegue que el
    // sistema de superficies no tenia como gesto propio. Entra en
    // la pose de agarre de hangWall (cuerpo pegado a la pared de
    // su izquierda, manos y pies contra ella), se COMPRIME contra
    // la pared y se IMPULSA fuera: extension diagonal explosiva
    // con los brazos arrastrando desde la pared, cayendo en una
    // pose de arco libre que encadena con fallPose/jumpStretch
    // segun mande el motor. El desplazamiento lo pone el motor;
    // el clip pone el muelle. (De techo no hay clip: soltarse es
    // entrar en fallPose, ver changelog.)
    static let wallJump = AnimationClip(name: "salto-desde-pared", duration: 0.65, loops: false, keyframes: [
        K9(0.0, P9 { p in // agarrado a la pared de su izquierda (familia hangWall)
            p.hipHeight = 52; p.neckOff = CGPoint(x: -2, y: -41); p.headOff = CGPoint(x: -2, y: -22)
            p.elbowL = CGPoint(x: -14, y: -14); p.handL = CGPoint(x: -22, y: -30) // manos a la pared, arriba
            p.elbowR = CGPoint(x: -6, y: -10); p.handR = CGPoint(x: -16, y: -24)
            p.kneeL = CGPoint(x: -14, y: 20); p.footL = CGPoint(x: -20, y: 38)   // pies contra la pared
            p.kneeR = CGPoint(x: -10, y: 24); p.footR = CGPoint(x: -16, y: 44)
        }, .easeIn), // se comprime contra la pared: el muelle se carga
        K9(0.18, P9 { p in
            p.hipHeight = 48; p.squash = 0.92; p.neckOff = CGPoint(x: -4, y: -36); p.headOff = CGPoint(x: -2, y: -20)
            p.elbowL = CGPoint(x: -15, y: -10); p.handL = CGPoint(x: -23, y: -26) // empuja la pared
            p.elbowR = CGPoint(x: -7, y: -6); p.handR = CGPoint(x: -17, y: -20)
            p.kneeL = CGPoint(x: -17, y: 14); p.footL = CGPoint(x: -21, y: 32)   // rodillas cargadas
            p.kneeR = CGPoint(x: -13, y: 18); p.footR = CGPoint(x: -17, y: 38)
        }, .snappy), // ¡IMPULSO! extension diagonal fuera de la pared
        K9(0.34, P9 { p in
            p.hipHeight = 56; p.squash = 1.10; p.hipDX = 4; p.neckOff = CGPoint(x: 8, y: -40); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: -16, y: 10); p.handL = CGPoint(x: -24, y: 22) // brazos arrastrando desde la pared
            p.elbowR = CGPoint(x: 10, y: 14); p.handR = CGPoint(x: 16, y: 26)
            p.kneeL = CGPoint(x: -2, y: 26); p.footL = CGPoint(x: 4, y: 48)     // piernas extendidas alejandose
            p.kneeR = CGPoint(x: 10, y: 24); p.footR = CGPoint(x: 18, y: 44)
        }, .easeOut), // arco libre: se recoge a pose de vuelo/caida encadenable
        K9(0.52, P9 { p in
            p.hipHeight = 58; p.squash = 1.05; p.neckOff = CGPoint(x: 6, y: -41); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -18, y: 8); p.handL = CGPoint(x: -26, y: 18)
            p.elbowR = CGPoint(x: 18, y: 8); p.handR = CGPoint(x: 26, y: 18)
            p.kneeL = CGPoint(x: -6, y: 24); p.footL = CGPoint(x: -8, y: 44)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 16, y: 40)
        }, .easeInOut), // pose final de arco (de aqui, fallPose o vuelo segun el motor)
        K9(0.65, P9 { p in
            p.hipHeight = 58; p.squash = 1.05; p.neckOff = CGPoint(x: 6, y: -41); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -18, y: 8); p.handL = CGPoint(x: -26, y: 18)
            p.elbowR = CGPoint(x: 18, y: 8); p.handR = CGPoint(x: 26, y: 18)
            p.kneeL = CGPoint(x: -6, y: 24); p.footL = CGPoint(x: -8, y: 44)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 16, y: 40)
        })
    ])
}
