import Foundation
import SwiftUI

// MARK: - PASE v8: tercera tanda de clips NUEVOS
//
// Continuacion de los pases v6 (63 clips) y v7 (19 clips): el
// usuario pidio "Mas" y esta tanda anade 22 clips que NO duplican
// ninguno de los 82 anteriores. Fuentes de la lista: (1) huecos de
// repertorio (golpes sueltos que faltaban: codazo, cabezazo,
// rodillazo, patada trasera; locomocion que faltaba: hacia atras,
// sigilo, el pino) y (2) el cruce con el catalogo de behaviors del
// pack Shimeji (SHIMEJI_SPEC.md + variante AlanBeckerStickFigures:
// 91 acciones / 57 behaviors de TCO), del que salen walkLoaded
// (WalkWithIe/RunWithIe) y sitSpinHead (SitAndSpinHead); el resto
// del catalogo ya estaba cubierto por el sistema o por los 82
// clips, o queda fuera con motivo (ver CHANGELOG-ANIM-V8.md).
//
// Que NO es (la linea de siempre): no se ha copiado ni un fotograma
// ni se ha usado ningun sprite del pack. El pack ha servido solo
// como CATALOGO de nombres de comportamiento (que hace el cuerpo,
// en que situaciones), re-expresado con nuestro esqueleto de
// offsets y los criterios de la v6: anticipacion antes de cada
// accion, holds de impacto mas largos que la anticipacion de los
// golpes rapidos, squash & stretch para el peso, easings .powerIn
// para las caidas que aceleran y .backOut para las recuperaciones
// que "respiran".
//
// Fichero ADITIVO y autonimo: no toca StickmanAnimation.swift ni
// StickmanAnimationV7.swift, y no anade casos a StickmanAction (sus
// switches son exhaustivos y sin default; el cableado es trabajo
// de integracion, ver CHANGELOG-ANIM-V8.md). Los tipos
// SkeletonPose, AnimKeyframe, AnimationClip y AnimEasing son los
// del fichero original (mismo modulo al integrar). Los helpers
// P/K (v6) y P7/K7 (v7) son `private` de sus ficheros y no se ven
// desde aqui: por eso existen P8/K8.
//
// OJO al escribir poses: cada keyframe es una pose COMPLETA
// construida desde `standing` (igual que en v6/v7). Todo canal que
// no se toca en un keyframe vuelve al valor de pie, asi que cada
// keyframe de este fichero fija todos los canales que le importan.

// Constructor comodo de poses a partir de la pose de pie (gemelo de P/P7)
private func P8(_ modify: (inout SkeletonPose) -> Void) -> SkeletonPose {
    var p = SkeletonPose.standing
    modify(&p)
    return p
}
private func K8(_ time: Double, _ pose: SkeletonPose, _ easing: AnimEasing = .easeInOut) -> AnimKeyframe {
    AnimKeyframe(time: time, pose: pose, easing: easing)
}

// MARK: - Catalogo v8 (22 clips nuevos)

enum AnimationLibraryV8 {

    // ============================================================
    // MARK: Locomocion y mundo
    // ============================================================

    // -- Caminar HACIA ATRAS: no es `walk` al reves. Tantea con la
    // punta del pie antes de apoyar el peso, lleva el torso girado
    // mirando por encima del hombro (la cabeza va clavada atras
    // todo el ciclo) y los brazos un poco atras, tanteando tambien.
    // Pasos mas cortos y cadera mas baja que en walk: desconfia.
    // El motor lo desplaza hacia atras (velocidad negativa respecto
    // al facing); el clip solo pone el cuerpo.
    static let walkBack = AnimationClip(name: "caminar-atras", duration: 0.9, loops: true, keyframes: [
        K8(0.0, P8 { p in // contacto derecho atras: el pie ya apoyo tras tantear
            p.hipHeight = 53; p.neckOff = CGPoint(x: -3, y: -40); p.headOff = CGPoint(x: -6, y: -21)
            p.elbowL = CGPoint(x: -19, y: 18); p.handL = CGPoint(x: -25, y: 34)
            p.elbowR = CGPoint(x: 15, y: 20); p.handR = CGPoint(x: 10, y: 38)
            p.kneeL = CGPoint(x: -6, y: 26); p.footL = CGPoint(x: 14, y: 48)  // apoyo adelantado (queda delante al retroceder)
            p.kneeR = CGPoint(x: -16, y: 22); p.footR = CGPoint(x: -20, y: 53) // pie de apoyo, atras
        }, .easeInOut), // el pie izquierdo tantea hacia atras, de puntillas
        K8(0.22, P8 { p in
            p.hipHeight = 52; p.squash = 0.98; p.neckOff = CGPoint(x: -3, y: -39); p.headOff = CGPoint(x: -7, y: -20)
            p.elbowL = CGPoint(x: -19, y: 18); p.handL = CGPoint(x: -26, y: 33)
            p.elbowR = CGPoint(x: 15, y: 20); p.handR = CGPoint(x: 11, y: 37)
            p.kneeL = CGPoint(x: -14, y: 20); p.footL = CGPoint(x: -18, y: 42) // en el aire, buscando suelo
            p.kneeR = CGPoint(x: -15, y: 24); p.footR = CGPoint(x: -19, y: 52)
        }, .easeOut), // apoya el izquierdo atras: contacto
        K8(0.45, P8 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: -3, y: -40); p.headOff = CGPoint(x: -6, y: -21)
            p.elbowL = CGPoint(x: -16, y: 20); p.handL = CGPoint(x: -14, y: 38)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 24, y: 33)
            p.kneeL = CGPoint(x: -16, y: 22); p.footL = CGPoint(x: -20, y: 53) // apoyo atras
            p.kneeR = CGPoint(x: -6, y: 26); p.footR = CGPoint(x: 13, y: 47)  // el derecho ya paso delante
        }, .easeInOut), // el derecho tantea hacia atras
        K8(0.67, P8 { p in
            p.hipHeight = 52; p.squash = 0.98; p.neckOff = CGPoint(x: -3, y: -39); p.headOff = CGPoint(x: -5, y: -20)
            p.elbowL = CGPoint(x: -16, y: 20); p.handL = CGPoint(x: -13, y: 37)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 25, y: 32)
            p.kneeL = CGPoint(x: -15, y: 24); p.footL = CGPoint(x: -19, y: 52)
            p.kneeR = CGPoint(x: -13, y: 20); p.footR = CGPoint(x: -17, y: 42) // buscando suelo
        }, .easeOut) // apoya y el ciclo cierra en el contacto inicial
    ])

    // -- Sigilo / de puntillas: pasos cortisimos y LENTOS (el ciclo
    // dura casi el doble que walk), cadera alta porque va de
    // puntillas (los pies nunca apoyan el talon: foot.y queda 4-6
    // por encima del apoyo pleno), torso echado adelante y brazos
    // bajos abiertos para equilibrarse. Una vez por ciclo se CONGELA
    // del todo (0.95-1.15): ha oido algo. Distinto de peekCorner
    // (estatico, en una esquina): esto es locomocion furtiva.
    static let sneak = AnimationClip(name: "sigilo", duration: 1.6, loops: true, keyframes: [
        K8(0.0, P8 { p in // paso apoyado de puntillas, torso volcado
            p.hipHeight = 56; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 6, y: -20)
            p.elbowL = CGPoint(x: -20, y: 16); p.handL = CGPoint(x: -26, y: 30)
            p.elbowR = CGPoint(x: 20, y: 16); p.handR = CGPoint(x: 26, y: 30)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -12, y: 50)
            p.kneeR = CGPoint(x: 14, y: 24); p.footR = CGPoint(x: 18, y: 50)
        }, .easeInOut), // levanta el pie muy despacio, rodilla alta de puntillas
        K8(0.4, P8 { p in
            p.hipHeight = 57; p.neckOff = CGPoint(x: 11, y: -38); p.headOff = CGPoint(x: 6, y: -20)
            p.elbowL = CGPoint(x: -21, y: 15); p.handL = CGPoint(x: -27, y: 29)
            p.elbowR = CGPoint(x: 19, y: 17); p.handR = CGPoint(x: 24, y: 31)
            p.kneeL = CGPoint(x: 16, y: 14); p.footL = CGPoint(x: 20, y: 36) // pie en el aire, buscando donde caer
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 51)
        }, .easeInOut), // lo posa sin hacer ruido
        K8(0.7, P8 { p in
            p.hipHeight = 56; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 7, y: -20)
            p.elbowL = CGPoint(x: -19, y: 17); p.handL = CGPoint(x: -24, y: 31)
            p.elbowR = CGPoint(x: 21, y: 15); p.handR = CGPoint(x: 27, y: 29)
            p.kneeL = CGPoint(x: 13, y: 24); p.footL = CGPoint(x: 17, y: 50)
            p.kneeR = CGPoint(x: -11, y: 26); p.footR = CGPoint(x: -13, y: 50)
        }, .snappy), // ¡FREEZE! ha oido algo: quieto de golpe, la cabeza gira al ruido
        K8(0.95, P8 { p in
            p.hipHeight = 56; p.squash = 0.99; p.neckOff = CGPoint(x: 9, y: -38); p.headOff = CGPoint(x: -4, y: -21)
            p.elbowL = CGPoint(x: -20, y: 16); p.handL = CGPoint(x: -26, y: 30)
            p.elbowR = CGPoint(x: 20, y: 16); p.handR = CGPoint(x: 26, y: 30)
            p.kneeL = CGPoint(x: 13, y: 24); p.footL = CGPoint(x: 17, y: 50)
            p.kneeR = CGPoint(x: -11, y: 26); p.footR = CGPoint(x: -13, y: 50)
        }, .easeInOut), // aguanta el freeze, solo respira
        K8(1.15, P8 { p in
            p.hipHeight = 56; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 0, y: -20)
            p.elbowL = CGPoint(x: -20, y: 16); p.handL = CGPoint(x: -26, y: 30)
            p.elbowR = CGPoint(x: 20, y: 16); p.handR = CGPoint(x: 26, y: 30)
            p.kneeL = CGPoint(x: 13, y: 24); p.footL = CGPoint(x: 17, y: 50)
            p.kneeR = CGPoint(x: -11, y: 26); p.footR = CGPoint(x: -13, y: 50)
        }, .easeInOut), // reanuda: levanta el otro pie y el ciclo se cierra en el paso inicial
        K8(1.35, P8 { p in
            p.hipHeight = 57; p.neckOff = CGPoint(x: 11, y: -38); p.headOff = CGPoint(x: 6, y: -20)
            p.elbowL = CGPoint(x: 19, y: 17); p.handL = CGPoint(x: 24, y: 31)
            p.elbowR = CGPoint(x: -21, y: 15); p.handR = CGPoint(x: -27, y: 29)
            p.kneeL = CGPoint(x: 12, y: 25); p.footL = CGPoint(x: 15, y: 51)
            p.kneeR = CGPoint(x: 16, y: 14); p.footR = CGPoint(x: 20, y: 36)
        }, .easeInOut)
    ])

    // -- Caminar CARGANDO un objeto pesado (cruce con el pack:
    // WalkWithIe/RunWithIe, andar agobiado portando una ventana/
    // objeto). Las manos van ARRIBA sujetando la carga sobre la
    // cabeza, los pasos son cortos, la cadera bambolea hipDX +-3
    // con cada apoyo y hay tembleque lineal de esfuerzo en cada
    // planta. Distinto de strengthPose (ESTATICO, sosteniendo en el
    // sitio): esto es LOCOMOCION cargada. El objeto lo dibuja la
    // vista fijo a las manos, como el bloque de strengthPose.
    static let walkLoaded = AnimationClip(name: "caminar-cargado", duration: 1.0, loops: true, keyframes: [
        K8(0.0, P8 { p in // apoyo derecho, bamboleo a ese lado, carga en alto
            p.hipHeight = 49; p.hipDX = 2; p.neckOff = CGPoint(x: 1, y: -37); p.headOff = CGPoint(x: 1, y: -19)
            p.elbowL = CGPoint(x: -15, y: -8); p.handL = CGPoint(x: -14, y: -30)
            p.elbowR = CGPoint(x: 15, y: -8); p.handR = CGPoint(x: 15, y: -30)
            p.kneeL = CGPoint(x: -8, y: 25); p.footL = CGPoint(x: -2, y: 44)  // paso corto, en el aire
            p.kneeR = CGPoint(x: 10, y: 24); p.footR = CGPoint(x: 12, y: 49)  // apoyo
        }, .linear), // tembleque de esfuerzo al plantar
        K8(0.12, P8 { p in
            p.hipHeight = 48; p.hipDX = 3; p.squash = 0.97; p.neckOff = CGPoint(x: 1, y: -36); p.headOff = CGPoint(x: 1, y: -19)
            p.elbowL = CGPoint(x: -15, y: -8); p.handL = CGPoint(x: -14, y: -29)
            p.elbowR = CGPoint(x: 15, y: -8); p.handR = CGPoint(x: 15, y: -29)
            p.kneeL = CGPoint(x: -6, y: 25); p.footL = CGPoint(x: 0, y: 46)
            p.kneeR = CGPoint(x: 10, y: 23); p.footR = CGPoint(x: 12, y: 48)
        }, .easeInOut), // pasa el peso al otro pie: bamboleo contrario
        K8(0.5, P8 { p in // apoyo izquierdo (espejo con asimetria de bamboleo)
            p.hipHeight = 49; p.hipDX = -3; p.neckOff = CGPoint(x: 0, y: -37); p.headOff = CGPoint(x: 0, y: -19)
            p.elbowL = CGPoint(x: -15, y: -8); p.handL = CGPoint(x: -15, y: -30)
            p.elbowR = CGPoint(x: 15, y: -8); p.handR = CGPoint(x: 14, y: -30)
            p.kneeL = CGPoint(x: -10, y: 24); p.footL = CGPoint(x: -12, y: 49)
            p.kneeR = CGPoint(x: 8, y: 25); p.footR = CGPoint(x: 2, y: 44)
        }, .linear), // tembleque al plantar el izquierdo
        K8(0.62, P8 { p in
            p.hipHeight = 48; p.hipDX = -4; p.squash = 0.97; p.neckOff = CGPoint(x: 0, y: -36); p.headOff = CGPoint(x: 0, y: -19)
            p.elbowL = CGPoint(x: -15, y: -8); p.handL = CGPoint(x: -15, y: -29)
            p.elbowR = CGPoint(x: 15, y: -8); p.handR = CGPoint(x: 14, y: -29)
            p.kneeL = CGPoint(x: -10, y: 23); p.footL = CGPoint(x: -12, y: 48)
            p.kneeR = CGPoint(x: 6, y: 25); p.footR = CGPoint(x: 0, y: 46)
        }, .easeInOut) // y bamboleo de vuelta al apoyo derecho: cierra el ciclo
    ])

    // -- El PINO (handstand): secuencia completa en one-shot —
    // agacharse, manos al suelo, patada arriba, balanceo con
    // correcciones (las manos "caminan" 1-2 pt y las piernas hacen
    // tijera para no caerse), bajada controlada y de pie. En el
    // pino el esqueleto se invierte con offsets: neckOff pasa a
    // POSITIVO (el cuello queda DEBAJO de la cadera) y las piernas
    // apuntan al cielo (foot.y muy negativo). El cruce de la
    // inversion se resuelve con un tramo snappy, como en trip.
    static let handstand = AnimationClip(name: "el-pino", duration: 2.9, loops: false, keyframes: [
        K8(0.0, SkeletonPose.standing, .easeIn), // se agacha a plantar las manos
        K8(0.32, P8 { p in
            p.hipHeight = 36; p.squash = 0.92; p.neckOff = CGPoint(x: 10, y: -30); p.headOff = CGPoint(x: 5, y: -18)
            p.elbowL = CGPoint(x: -14, y: 14); p.handL = CGPoint(x: -12, y: 32)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 14, y: 32)
            p.kneeL = CGPoint(x: -14, y: 18); p.footL = CGPoint(x: -16, y: 36)
            p.kneeR = CGPoint(x: 12, y: 18); p.footR = CGPoint(x: 10, y: 36)
        }, .snappy), // ¡PATADA ARRIBA! a medio invertir: una pierna ya va al cielo
        K8(0.55, P8 { p in
            p.hipHeight = 66; p.squash = 1.02; p.neckOff = CGPoint(x: 2, y: 26); p.headOff = CGPoint(x: 1, y: 14)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -9, y: 38)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 9, y: 38)
            p.kneeL = CGPoint(x: -8, y: -24); p.footL = CGPoint(x: -10, y: -48) // pierna alta
            p.kneeR = CGPoint(x: 15, y: -6); p.footR = CGPoint(x: 21, y: -14)  // la otra aun sube
        }, .easeOut), // clava el pino: cuerpo recto, manos al suelo
        K8(0.78, P8 { p in
            p.hipHeight = 74; p.squash = 1.04; p.neckOff = CGPoint(x: 0, y: 34); p.headOff = CGPoint(x: 0, y: 16)
            p.elbowL = CGPoint(x: -10, y: 19); p.handL = CGPoint(x: -8, y: 40)
            p.elbowR = CGPoint(x: 10, y: 19); p.handR = CGPoint(x: 8, y: 40)
            p.kneeL = CGPoint(x: -9, y: -27); p.footL = CGPoint(x: -11, y: -54)
            p.kneeR = CGPoint(x: 9, y: -27); p.footR = CGPoint(x: 11, y: -54)
        }, .easeInOut), // balanceo: se va hacia un lado, las piernas hacen tijera
        K8(1.15, P8 { p in
            p.hipHeight = 73; p.hipDX = 3; p.neckOff = CGPoint(x: 3, y: 33); p.headOff = CGPoint(x: 1, y: 16)
            p.elbowL = CGPoint(x: -10, y: 19); p.handL = CGPoint(x: -7, y: 40)
            p.elbowR = CGPoint(x: 11, y: 19); p.handR = CGPoint(x: 10, y: 40) // esta mano "camina" para corregir
            p.kneeL = CGPoint(x: -13, y: -25); p.footL = CGPoint(x: -18, y: -50)
            p.kneeR = CGPoint(x: 6, y: -28); p.footR = CGPoint(x: 7, y: -55)
        }, .easeInOut), // correccion contraria: ahora se va al otro lado
        K8(1.55, P8 { p in
            p.hipHeight = 73; p.hipDX = -3; p.neckOff = CGPoint(x: -3, y: 33); p.headOff = CGPoint(x: -1, y: 16)
            p.elbowL = CGPoint(x: -11, y: 19); p.handL = CGPoint(x: -10, y: 40) // ahora camina la otra mano
            p.elbowR = CGPoint(x: 10, y: 19); p.handR = CGPoint(x: 7, y: 40)
            p.kneeL = CGPoint(x: -6, y: -28); p.footL = CGPoint(x: -7, y: -55)
            p.kneeR = CGPoint(x: 13, y: -25); p.footR = CGPoint(x: 18, y: -50)
        }, .easeInOut), // estable un momento, sobrado: una patadita de celebracion
        K8(1.95, P8 { p in
            p.hipHeight = 74; p.squash = 1.04; p.neckOff = CGPoint(x: 0, y: 34); p.headOff = CGPoint(x: 0, y: 16)
            p.elbowL = CGPoint(x: -10, y: 19); p.handL = CGPoint(x: -8, y: 40)
            p.elbowR = CGPoint(x: 10, y: 19); p.handR = CGPoint(x: 8, y: 40)
            p.kneeL = CGPoint(x: -9, y: -27); p.footL = CGPoint(x: -11, y: -54)
            p.kneeR = CGPoint(x: 16, y: -20); p.footR = CGPoint(x: 24, y: -38) // patadita
        }, .easeIn), // BAJADA: una pierna cae buscando el suelo, la otra sigue
        K8(2.3, P8 { p in
            p.hipHeight = 62; p.neckOff = CGPoint(x: 3, y: 24); p.headOff = CGPoint(x: 2, y: 13)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -9, y: 37)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 9, y: 37)
            p.kneeL = CGPoint(x: -6, y: -16); p.footL = CGPoint(x: -6, y: -34)
            p.kneeR = CGPoint(x: 14, y: 8); p.footR = CGPoint(x: 16, y: 28) // este pie ya casi toca
        }, .easeOut), // se recoge agachado, manos aun en el suelo
        K8(2.6, P8 { p in
            p.hipHeight = 38; p.squash = 0.94; p.neckOff = CGPoint(x: 6, y: -31); p.headOff = CGPoint(x: 3, y: -19)
            p.elbowL = CGPoint(x: -14, y: 15); p.handL = CGPoint(x: -13, y: 30)
            p.elbowR = CGPoint(x: 15, y: 15); p.handR = CGPoint(x: 13, y: 30)
            p.kneeL = CGPoint(x: -13, y: 19); p.footL = CGPoint(x: -15, y: 38)
            p.kneeR = CGPoint(x: 12, y: 19); p.footR = CGPoint(x: 11, y: 38)
        }, .backOut), // y se levanta como si nada
        K8(2.9, SkeletonPose.standing)
    ])

    // -- Cuerda floja: equilibrio sobre un borde fino (los bordes
    // de la interfaz son su "cuerda"). Pies EN LINEA (x casi 0,
    // pasos minimos en el sitio), brazos en cruz oscilando con
    // correcciones desfasadas y, una vez por ciclo, un susto
    // grande: bamboleo amplio, un brazo hace molinillo y se salva.
    // Distinto de dangle (sentado en el borde): esto es de pie
    // SOBRE el borde.
    static let tightrope = AnimationClip(name: "cuerda-floja", duration: 2.6, loops: true, keyframes: [
        K8(0.0, P8 { p in // en la cuerda: pies en linea, brazos en cruz
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -19) // mira abajo, a la cuerda
            p.elbowL = CGPoint(x: -24, y: 4); p.handL = CGPoint(x: -38, y: -2)
            p.elbowR = CGPoint(x: 24, y: 4); p.handR = CGPoint(x: 38, y: -2)
            p.kneeL = CGPoint(x: -3, y: 27); p.footL = CGPoint(x: -2, y: 55)
            p.kneeR = CGPoint(x: 3, y: 27); p.footR = CGPoint(x: 2, y: 55)
        }, .easeInOut), // correccion suave a un lado
        K8(0.5, P8 { p in
            p.hipHeight = 55; p.hipDX = 2; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -24, y: 2); p.handL = CGPoint(x: -38, y: -8) // este brazo sube
            p.elbowR = CGPoint(x: 24, y: 6); p.handR = CGPoint(x: 38, y: 3)   // este baja
            p.kneeL = CGPoint(x: -3, y: 27); p.footL = CGPoint(x: -2, y: 55)
            p.kneeR = CGPoint(x: 3, y: 27); p.footR = CGPoint(x: 2, y: 55)
        }, .easeInOut), // pasito minimo hacia delante (en el sitio: el avance lo pone el motor)
        K8(0.9, P8 { p in
            p.hipHeight = 55; p.hipDX = 1; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -24, y: 4); p.handL = CGPoint(x: -37, y: -3)
            p.elbowR = CGPoint(x: 24, y: 4); p.handR = CGPoint(x: 37, y: -3)
            p.kneeL = CGPoint(x: -2, y: 26); p.footL = CGPoint(x: -1, y: 49) // pie levantado, a medio paso
            p.kneeR = CGPoint(x: 3, y: 27); p.footR = CGPoint(x: 2, y: 55)
        }, .easeInOut), // lo posa y... ¡SUSTO! se va de lado
        K8(1.25, P8 { p in
            p.hipHeight = 54; p.hipDX = 5; p.squash = 0.98; p.neckOff = CGPoint(x: 5, y: -39); p.headOff = CGPoint(x: 4, y: -19)
            p.elbowL = CGPoint(x: -22, y: 0); p.handL = CGPoint(x: -34, y: -14)
            p.elbowR = CGPoint(x: 22, y: 8); p.handR = CGPoint(x: 33, y: 12)
            p.kneeL = CGPoint(x: -4, y: 26); p.footL = CGPoint(x: -3, y: 54)
            p.kneeR = CGPoint(x: 4, y: 27); p.footR = CGPoint(x: 3, y: 54)
        }, .linear), // MOLINILLO para salvarse (dos medias vueltas rapidas de brazos)
        K8(1.45, P8 { p in
            p.hipHeight = 54; p.hipDX = 4; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 3, y: -19)
            p.elbowL = CGPoint(x: -18, y: -8); p.handL = CGPoint(x: -26, y: -24)
            p.elbowR = CGPoint(x: 18, y: -6); p.handR = CGPoint(x: 27, y: -22)
            p.kneeL = CGPoint(x: -4, y: 26); p.footL = CGPoint(x: -3, y: 54)
            p.kneeR = CGPoint(x: 4, y: 27); p.footR = CGPoint(x: 3, y: 54)
        }, .linear),
        K8(1.65, P8 { p in
            p.hipHeight = 55; p.hipDX = 2; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -23, y: 2); p.handL = CGPoint(x: -36, y: -10)
            p.elbowR = CGPoint(x: 23, y: 5); p.handR = CGPoint(x: 36, y: 5)
            p.kneeL = CGPoint(x: -3, y: 27); p.footL = CGPoint(x: -2, y: 55)
            p.kneeR = CGPoint(x: 3, y: 27); p.footR = CGPoint(x: 2, y: 55)
        }, .easeInOut), // se estabiliza, respira (uff)
        K8(2.1, P8 { p in
            p.hipHeight = 55; p.hipDX = 0; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -24, y: 4); p.handL = CGPoint(x: -38, y: -3)
            p.elbowR = CGPoint(x: 24, y: 4); p.handR = CGPoint(x: 38, y: -3)
            p.kneeL = CGPoint(x: -3, y: 27); p.footL = CGPoint(x: -2, y: 55)
            p.kneeR = CGPoint(x: 3, y: 27); p.footR = CGPoint(x: 2, y: 55)
        }, .easeInOut) // y el ciclo vuelve a la correccion inicial
    ])

    // -- Colgarse de UNA sola mano (del techo o de un borde alto):
    // el cuerpo entero cuelga libre (los pies NO tocan nada), con
    // pendulo mas amplio que hangCeil (que va a dos manos y mas
    // rigido) y la mano libre VIVA: primero cuelga, luego se la
    // pone en la cadera sobrado y al final senala hacia abajo.
    // Las piernas arrastran con retraso, como en hangCeil/hangWall.
    static let oneHandHang = AnimationClip(name: "colgarse-una-mano", duration: 3.0, loops: true, keyframes: [
        K8(0.0, P8 { p in // centro del pendulo: mano R agarrada arriba, L colgando
            p.hipHeight = 50; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -15, y: 18); p.handL = CGPoint(x: -17, y: 38)
            p.elbowR = CGPoint(x: 6, y: -26); p.handR = CGPoint(x: 4, y: -53) // agarre unico
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -12, y: 46)
            p.kneeR = CGPoint(x: 10, y: 26); p.footR = CGPoint(x: 12, y: 46)
        }, .easeInOut), // extremo A: la cadera llega y las piernas aun no
        K8(0.7, P8 { p in
            p.hipHeight = 50; p.hipDX = 4; p.neckOff = CGPoint(x: 2, y: -43); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -18, y: 38)
            p.elbowR = CGPoint(x: 6, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 46)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 15, y: 46)
        }, .easeInOut), // centro de vuelta: la mano libre se pone en la cadera, sobrado
        K8(1.4, P8 { p in
            p.hipHeight = 50; p.hipDX = 0; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -19, y: 12); p.handL = CGPoint(x: -13, y: 24) // mano en la cadera
            p.elbowR = CGPoint(x: 6, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -14, y: 46)
            p.kneeR = CGPoint(x: 8, y: 26); p.footR = CGPoint(x: 10, y: 46)
        }, .easeInOut), // extremo B, con la mano aun en la cadera
        K8(2.1, P8 { p in
            p.hipHeight = 50; p.hipDX = -4; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: -19, y: 12); p.handL = CGPoint(x: -13, y: 24)
            p.elbowR = CGPoint(x: 6, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -14, y: 26); p.footL = CGPoint(x: -16, y: 46)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 46)
        }, .easeInOut), // vuelve al centro y la mano libre cae otra vez: cierra el ciclo
        K8(2.65, P8 { p in
            p.hipHeight = 50; p.hipDX = -1; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -16, y: 17); p.handL = CGPoint(x: -17, y: 36)
            p.elbowR = CGPoint(x: 6, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -13, y: 46)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 11, y: 46)
        }, .easeInOut)
    ])

    // ============================================================
    // MARK: Pelea — golpes sueltos que faltaban
    // La rafaga sigue en fightCombo (v6) y gancho/patada-voladora/
    // placaje en la v7; estos son los golpes con nombre propio que
    // aun no existian como clip independiente.
    // ============================================================

    // -- Patada TRASERA: el clasico "no mires, patea" — medio giro
    // de cadera, la mirada se va por encima del hombro y la pierna
    // sale hacia ATRAS con todo el cuerpo inclinado hacia delante
    // como contrapeso. Sin rotacion global: el giro se sugiere con
    // hipDX/neckOff y la cabeza mirando atras.
    static let backKick = AnimationClip(name: "patada-trasera", duration: 0.9, loops: false, keyframes: [
        K8(0.0, P8 { p in // guardia del combo (encadenable)
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeIn), // carga: se vuelca adelante y levanta la rodilla trasera
        K8(0.28, P8 { p in
            p.hipHeight = 49; p.squash = 0.95; p.hipDX = -1; p.neckOff = CGPoint(x: 8, y: -38); p.headOff = CGPoint(x: -3, y: -21)
            p.elbowL = CGPoint(x: 2, y: 15); p.handL = CGPoint(x: 14, y: 4)
            p.elbowR = CGPoint(x: 10, y: 18); p.handR = CGPoint(x: 22, y: 12)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -18, y: 49)
            p.kneeR = CGPoint(x: -16, y: 16); p.footR = CGPoint(x: -8, y: 34) // rodilla camara, pie cargado
        }, .snappy), // ¡PATADA HACIA ATRAS! extension total, torso de contrapeso
        K8(0.42, P8 { p in
            p.hipHeight = 52; p.squash = 1.03; p.hipDX = 2; p.neckOff = CGPoint(x: 14, y: -36); p.headOff = CGPoint(x: -4, y: -20)
            p.elbowL = CGPoint(x: 8, y: 14); p.handL = CGPoint(x: 24, y: 10) // brazos adelante, contrapeso
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 30, y: 14)
            p.kneeL = CGPoint(x: -6, y: 27); p.footL = CGPoint(x: -10, y: 52) // unico apoyo
            p.kneeR = CGPoint(x: -30, y: 20); p.footR = CGPoint(x: -50, y: 38) // la patada, clavada atras
        }, .linear), // hold de impacto, con micro-vibracion
        K8(0.54, P8 { p in
            p.hipHeight = 52; p.hipDX = 2; p.neckOff = CGPoint(x: 14, y: -36); p.headOff = CGPoint(x: -4, y: -20)
            p.elbowL = CGPoint(x: 8, y: 14); p.handL = CGPoint(x: 24, y: 10)
            p.elbowR = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 29, y: 13)
            p.kneeL = CGPoint(x: -6, y: 27); p.footL = CGPoint(x: -10, y: 52)
            p.kneeR = CGPoint(x: -29, y: 20); p.footR = CGPoint(x: -49, y: 38)
        }, .easeIn), // recoge la pierna
        K8(0.72, P8 { p in
            p.hipHeight = 50; p.neckOff = CGPoint(x: 8, y: -39); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: 5, y: 16); p.handL = CGPoint(x: 18, y: 6)
            p.elbowR = CGPoint(x: 13, y: 19); p.handR = CGPoint(x: 26, y: 10)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -18, y: 50)
            p.kneeR = CGPoint(x: 4, y: 22); p.footR = CGPoint(x: -2, y: 44) // a medio recoger
        }, .backOut), // asienta en guardia otra vez
        K8(0.9, P8 { p in
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Rodillazo: primero AGARRA (las dos manos van a los
    // "hombros" del rival y tiran hacia abajo) y la rodilla sube a
    // encontrarse con las manos. El tiron y la rodilla son un solo
    // gesto: por eso la cadera sube y el torso se dobla encima.
    static let kneeStrike = AnimationClip(name: "rodillazo", duration: 0.85, loops: false, keyframes: [
        K8(0.0, P8 { p in // guardia del combo
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeOut), // las manos salen a agarrar
        K8(0.18, P8 { p in
            p.hipHeight = 51; p.neckOff = CGPoint(x: 8, y: -40); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: 14, y: 10); p.handL = CGPoint(x: 30, y: 2)
            p.elbowR = CGPoint(x: 20, y: 14); p.handR = CGPoint(x: 34, y: 8)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 51)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 51)
        }, .snappy), // ¡RODILLAZO! tira de las manos hacia abajo y la rodilla sube seca
        K8(0.34, P8 { p in
            p.hipHeight = 54; p.squash = 1.02; p.neckOff = CGPoint(x: 12, y: -36); p.headOff = CGPoint(x: 5, y: -19)
            p.elbowL = CGPoint(x: 10, y: 20); p.handL = CGPoint(x: 26, y: 14) // manos empujando abajo
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: 30, y: 18)
            p.kneeL = CGPoint(x: -10, y: 28); p.footL = CGPoint(x: -16, y: 54) // apoyo, de puntillas
            p.kneeR = CGPoint(x: 32, y: -2); p.footR = CGPoint(x: 28, y: 20)  // la rodilla, en el objetivo
        }, .linear), // hold de impacto
        K8(0.46, P8 { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 12, y: -36); p.headOff = CGPoint(x: 5, y: -19)
            p.elbowL = CGPoint(x: 10, y: 20); p.handL = CGPoint(x: 26, y: 14)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: 30, y: 18)
            p.kneeL = CGPoint(x: -10, y: 28); p.footL = CGPoint(x: -16, y: 54)
            p.kneeR = CGPoint(x: 31, y: -1); p.footR = CGPoint(x: 27, y: 20)
        }, .easeOut), // suelta y la pierna baja
        K8(0.64, P8 { p in
            p.hipHeight = 51; p.neckOff = CGPoint(x: 7, y: -39); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: 6, y: 17); p.handL = CGPoint(x: 19, y: 7)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -19, y: 51)
            p.kneeR = CGPoint(x: 10, y: 22); p.footR = CGPoint(x: 14, y: 42)
        }, .backOut),
        K8(0.85, P8 { p in // guardia otra vez
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Codazo: golpe corto y sucio hacia atras-lado. La carga
    // lleva el puno al pecho y el codo muy atras (el codo es el
    // arma); el latigazo es del TORSO entero girando, no del brazo.
    // Termina medio girado y se repone a guardia.
    static let elbowStrike = AnimationClip(name: "codazo", duration: 0.8, loops: false, keyframes: [
        K8(0.0, P8 { p in // guardia del combo
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeIn), // carga: puno al pecho, codo muy atras, torso enroscado
        K8(0.24, P8 { p in
            p.hipHeight = 48; p.squash = 0.94; p.hipDX = -2; p.neckOff = CGPoint(x: -2, y: -38); p.headOff = CGPoint(x: -2, y: -21)
            p.elbowL = CGPoint(x: 2, y: 15); p.handL = CGPoint(x: 13, y: 3)   // guarda la cara
            p.elbowR = CGPoint(x: -14, y: 12); p.handR = CGPoint(x: 4, y: 18) // codo cargado atras
            p.kneeL = CGPoint(x: -13, y: 24); p.footL = CGPoint(x: -21, y: 48)
            p.kneeR = CGPoint(x: 13, y: 24); p.footR = CGPoint(x: 22, y: 48)
        }, .snappy), // ¡CODAZO! el torso gira y el codo barre hacia el lado-atras
        K8(0.38, P8 { p in
            p.hipHeight = 51; p.squash = 1.01; p.hipDX = 2; p.neckOff = CGPoint(x: 9, y: -39); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: 3, y: 16); p.handL = CGPoint(x: 15, y: 5)
            p.elbowR = CGPoint(x: 30, y: 4); p.handR = CGPoint(x: 12, y: 14) // el codo, clavado en el objetivo
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -18, y: 51)
            p.kneeR = CGPoint(x: 14, y: 26); p.footR = CGPoint(x: 24, y: 51)
        }, .linear), // hold de impacto
        K8(0.5, P8 { p in
            p.hipHeight = 51; p.hipDX = 2; p.neckOff = CGPoint(x: 9, y: -39); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: 3, y: 16); p.handL = CGPoint(x: 15, y: 5)
            p.elbowR = CGPoint(x: 29, y: 4); p.handR = CGPoint(x: 12, y: 14)
            p.kneeL = CGPoint(x: -11, y: 26); p.footL = CGPoint(x: -18, y: 51)
            p.kneeR = CGPoint(x: 14, y: 26); p.footR = CGPoint(x: 24, y: 51)
        }, .easeOut), // desenrosca volviendo a guardia
        K8(0.8, P8 { p in
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Cabezazo: se agarra, echa la cabeza atras del todo y la
    // lanza como un martillo. Al volver queda un instante atontado
    // (micro-tambaleo, mismo lenguaje que el final de dizzy) antes
    // de recuperar la guardia: el cabezazo tambien duele.
    static let headbutt = AnimationClip(name: "cabezazo", duration: 0.95, loops: false, keyframes: [
        K8(0.0, P8 { p in // guardia del combo
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeOut), // agarra con las dos manos y se acerca
        K8(0.16, P8 { p in
            p.hipHeight = 51; p.neckOff = CGPoint(x: 8, y: -40); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: 14, y: 10); p.handL = CGPoint(x: 30, y: 2)
            p.elbowR = CGPoint(x: 20, y: 14); p.handR = CGPoint(x: 34, y: 8)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 51)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 51)
        }, .easeIn), // echa la cabeza ATRAS cargando el martillo
        K8(0.36, P8 { p in
            p.hipHeight = 52; p.squash = 1.01; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: -8, y: -25)
            p.elbowL = CGPoint(x: 13, y: 11); p.handL = CGPoint(x: 28, y: 3)
            p.elbowR = CGPoint(x: 19, y: 15); p.handR = CGPoint(x: 32, y: 9)
            p.kneeL = CGPoint(x: -12, y: 27); p.footL = CGPoint(x: -20, y: 52)
            p.kneeR = CGPoint(x: 13, y: 27); p.footR = CGPoint(x: 22, y: 52)
        }, .snappy), // ¡CABEZAZO! todo el torso cae sobre la cabeza
        K8(0.48, P8 { p in
            p.hipHeight = 49; p.squash = 0.93; p.neckOff = CGPoint(x: 16, y: -33); p.headOff = CGPoint(x: 15, y: -13)
            p.elbowL = CGPoint(x: 12, y: 14); p.handL = CGPoint(x: 26, y: 8)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 30, y: 13)
            p.kneeL = CGPoint(x: -13, y: 24); p.footL = CGPoint(x: -21, y: 49)
            p.kneeR = CGPoint(x: 14, y: 24); p.footR = CGPoint(x: 23, y: 49)
        }, .linear), // hold de impacto (le zumba la cabeza)
        K8(0.6, P8 { p in
            p.hipHeight = 49; p.squash = 0.94; p.neckOff = CGPoint(x: 15, y: -34); p.headOff = CGPoint(x: 14, y: -14)
            p.elbowL = CGPoint(x: 12, y: 14); p.handL = CGPoint(x: 26, y: 8)
            p.elbowR = CGPoint(x: 18, y: 18); p.handR = CGPoint(x: 30, y: 13)
            p.kneeL = CGPoint(x: -13, y: 24); p.footL = CGPoint(x: -21, y: 49)
            p.kneeR = CGPoint(x: 14, y: 24); p.footR = CGPoint(x: 23, y: 49)
        }, .easeOut), // retrocede atontado, un paso tambaleante
        K8(0.78, P8 { p in
            p.hipHeight = 50; p.hipDX = -2; p.neckOff = CGPoint(x: 4, y: -39); p.headOff = CGPoint(x: -3, y: -21)
            p.elbowL = CGPoint(x: 5, y: 16); p.handL = CGPoint(x: 18, y: 7)
            p.elbowR = CGPoint(x: 13, y: 19); p.handR = CGPoint(x: 25, y: 10)
            p.kneeL = CGPoint(x: -13, y: 25); p.footL = CGPoint(x: -23, y: 50)
            p.kneeR = CGPoint(x: 10, y: 25); p.footR = CGPoint(x: 16, y: 47)
        }, .backOut), // se le pasa y vuelve a guardia
        K8(0.95, P8 { p in
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Esquiva hacia ATRAS (arqueo): el golpe pasa por encima y
    // el se dobla hacia atras plantando los pies, con la cadera
    // ADELANTADA y los brazos buscando el equilibrio detras.
    // Distinta de dodgeDuck (agacharse de golpe) y de block
    // (parar el golpe): aqui no toca nada, solo se aparta.
    static let leanBack = AnimationClip(name: "esquiva-atras", duration: 0.9, loops: false, keyframes: [
        K8(0.0, SkeletonPose.standing, .snappy), // ve venir el golpe: ¡se arquea de golpe!
        K8(0.14, P8 { p in
            p.hipHeight = 54; p.hipDX = 4; p.squash = 1.02; p.neckOff = CGPoint(x: -15, y: -37); p.headOff = CGPoint(x: -9, y: -20)
            p.elbowL = CGPoint(x: -20, y: 14); p.handL = CGPoint(x: -26, y: 28)
            p.elbowR = CGPoint(x: 14, y: 22); p.handR = CGPoint(x: 22, y: 30) // brazos atras, equilibrio
            p.kneeL = CGPoint(x: -9, y: 28); p.footL = CGPoint(x: -12, y: 54)
            p.kneeR = CGPoint(x: 10, y: 28); p.footR = CGPoint(x: 12, y: 54)
        }, .easeInOut), // aguanta arqueado: el golpe pasa por encima
        K8(0.38, P8 { p in
            p.hipHeight = 54; p.hipDX = 4; p.neckOff = CGPoint(x: -16, y: -36); p.headOff = CGPoint(x: -10, y: -19)
            p.elbowL = CGPoint(x: -20, y: 14); p.handL = CGPoint(x: -27, y: 27)
            p.elbowR = CGPoint(x: 14, y: 22); p.handR = CGPoint(x: 23, y: 29)
            p.kneeL = CGPoint(x: -9, y: 28); p.footL = CGPoint(x: -12, y: 54)
            p.kneeR = CGPoint(x: 10, y: 28); p.footR = CGPoint(x: 12, y: 54)
        }, .linear), // tembleque de cintura: casi se cae hacia atras
        K8(0.52, P8 { p in
            p.hipHeight = 53; p.hipDX = 5; p.squash = 0.99; p.neckOff = CGPoint(x: -14, y: -37); p.headOff = CGPoint(x: -8, y: -20)
            p.elbowL = CGPoint(x: -19, y: 12); p.handL = CGPoint(x: -24, y: 24)
            p.elbowR = CGPoint(x: 15, y: 20); p.handR = CGPoint(x: 24, y: 27)
            p.kneeL = CGPoint(x: -9, y: 27); p.footL = CGPoint(x: -12, y: 53)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 12, y: 53)
        }, .backOut), // se endereza de un tiron, sobrado
        K8(0.75, P8 { p in
            p.hipHeight = 56; p.neckOff = CGPoint(x: -2, y: -41); p.headOff = CGPoint(x: -1, y: -22)
            p.elbowL = CGPoint(x: -17, y: 18); p.handL = CGPoint(x: -21, y: 36)
            p.elbowR = CGPoint(x: 17, y: 18); p.handR = CGPoint(x: 21, y: 36)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .easeInOut),
        K8(0.9, SkeletonPose.standing)
    ])

    // ============================================================
    // MARK: Poderes (Chosen One / Second Coming despierto)
    // ============================================================

    // -- Cargar una BOLA DE FUEGO entre las manos: clip DEDICADO
    // de carga, pensado para encadenar ANTES de firePose. Las
    // palmas se encaran frente al pecho y la bola "crece" entre
    // ellas: las manos se van separando a medida que crece, con
    // el tembleque acelerando en intervalos decrecientes (el
    // lenguaje de chargePower, pero localizado en las manos) y el
    // cuerpo echandose atras resistiendo la presion. La vista
    // dibuja la bola entre las palmas: su diametro es la distancia
    // entre manos (visible desde ~0.35, maxima al final). El
    // ultimo keyframe deja las manos en la posicion de la que
    // arranca la descarga de firePose.
    static let fireCharge = AnimationClip(name: "bola-fuego", duration: 1.5, loops: false, keyframes: [
        K8(0.0, P8 { p in // manos viniendo al pecho, aun sin bola
            p.hipHeight = 53; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -6, y: 18); p.handL = CGPoint(x: 8, y: 22)
            p.elbowR = CGPoint(x: 22, y: 16); p.handR = CGPoint(x: 26, y: 24)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -18, y: 53)
            p.kneeR = CGPoint(x: 12, y: 26); p.footR = CGPoint(x: 18, y: 53)
        }, .easeIn), // palmas encaradas: nace la bola (mini) y empieza el tembleque
        K8(0.35, P8 { p in
            p.hipHeight = 52; p.squash = 0.98; p.neckOff = CGPoint(x: 0, y: -40); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: -2, y: 16); p.handL = CGPoint(x: 13, y: 15)
            p.elbowR = CGPoint(x: 24, y: 15); p.handR = CGPoint(x: 21, y: 16)
            p.kneeL = CGPoint(x: -13, y: 25); p.footL = CGPoint(x: -19, y: 52)
            p.kneeR = CGPoint(x: 13, y: 25); p.footR = CGPoint(x: 19, y: 52)
        }, .linear), // la bola crece: las manos se separan, el tembleque aprieta
        K8(0.6, P8 { p in
            p.hipHeight = 51; p.squash = 0.96; p.hipDX = -1; p.neckOff = CGPoint(x: -1, y: -40); p.headOff = CGPoint(x: -1, y: -21)
            p.elbowL = CGPoint(x: -4, y: 16); p.handL = CGPoint(x: 10, y: 14)
            p.elbowR = CGPoint(x: 26, y: 15); p.handR = CGPoint(x: 24, y: 15)
            p.kneeL = CGPoint(x: -13, y: 25); p.footL = CGPoint(x: -19, y: 51)
            p.kneeR = CGPoint(x: 13, y: 25); p.footR = CGPoint(x: 19, y: 51)
        }, .linear),
        K8(0.82, P8 { p in
            p.hipHeight = 51; p.squash = 0.95; p.hipDX = 1; p.neckOff = CGPoint(x: -2, y: -39); p.headOff = CGPoint(x: -1, y: -20)
            p.elbowL = CGPoint(x: -6, y: 16); p.handL = CGPoint(x: 7, y: 13)
            p.elbowR = CGPoint(x: 28, y: 15); p.handR = CGPoint(x: 27, y: 14)
            p.kneeL = CGPoint(x: -14, y: 25); p.footL = CGPoint(x: -20, y: 51)
            p.kneeR = CGPoint(x: 14, y: 25); p.footR = CGPoint(x: 20, y: 51)
        }, .linear),
        K8(1.05, P8 { p in // bola grande: le cuesta contenerla, se echa atras
            p.hipHeight = 50; p.squash = 0.94; p.hipDX = -1; p.neckOff = CGPoint(x: -3, y: -39); p.headOff = CGPoint(x: -2, y: -20)
            p.elbowL = CGPoint(x: -8, y: 16); p.handL = CGPoint(x: 4, y: 12)
            p.elbowR = CGPoint(x: 30, y: 15); p.handR = CGPoint(x: 30, y: 13)
            p.kneeL = CGPoint(x: -14, y: 24); p.footL = CGPoint(x: -21, y: 50)
            p.kneeR = CGPoint(x: 14, y: 24); p.footR = CGPoint(x: 21, y: 50)
        }, .easeOut), // la recoge un instante contra el pecho: lista para soltarla
        K8(1.32, P8 { p in
            p.hipHeight = 51; p.squash = 0.97; p.neckOff = CGPoint(x: -2, y: -40); p.headOff = CGPoint(x: -1, y: -21)
            p.elbowL = CGPoint(x: -2, y: 16); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 25, y: 15); p.handR = CGPoint(x: 23, y: 16)
            p.kneeL = CGPoint(x: -13, y: 25); p.footL = CGPoint(x: -19, y: 51)
            p.kneeR = CGPoint(x: 13, y: 25); p.footR = CGPoint(x: 19, y: 51)
        }, .easeInOut), // aguanta la bola cargada (de aqui salta la descarga de firePose)
        K8(1.5, P8 { p in
            p.hipHeight = 51; p.squash = 0.96; p.neckOff = CGPoint(x: -2, y: -40); p.headOff = CGPoint(x: -1, y: -21)
            p.elbowL = CGPoint(x: -2, y: 16); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 25, y: 15); p.handR = CGPoint(x: 23, y: 16)
            p.kneeL = CGPoint(x: -13, y: 25); p.footL = CGPoint(x: -19, y: 51)
            p.kneeR = CGPoint(x: 13, y: 25); p.footR = CGPoint(x: 19, y: 51)
        })
    ])

    // -- Vuelo en PICADO: one-shot de trayectoria. Entra como
    // flyDash (flecha horizontal), hunde la nariz (la cabeza y el
    // torso caen respecto a la linea de vuelo), se aguanta el
    // picado con vibracion lineal y REMONTA al final abriendo los
    // brazos, en la pose de la que puede colgar flyPose. La bajada
    // real la pone el motor; en el clip la "caida" relativa se
    // marca con hipHeight decreciente y tramo powerIn.
    static let dive = AnimationClip(name: "picado", duration: 0.85, loops: false, keyframes: [
        K8(0.0, P8 { p in // flecha de flyDash: cuerpo horizontal, brazos atras
            p.hipHeight = 60; p.squash = 1.10; p.neckOff = CGPoint(x: 20, y: -30); p.headOff = CGPoint(x: 9, y: -17)
            p.elbowL = CGPoint(x: -16, y: 8); p.handL = CGPoint(x: -30, y: 16)
            p.elbowR = CGPoint(x: -14, y: 12); p.handR = CGPoint(x: -28, y: 20)
            p.kneeL = CGPoint(x: -16, y: 8); p.footL = CGPoint(x: -34, y: 12)
            p.kneeR = CGPoint(x: -14, y: 12); p.footR = CGPoint(x: -32, y: 16)
        }, .easeIn), // hunde la nariz: cabeza y torso caen, las piernas quedan en la linea
        K8(0.25, P8 { p in
            p.hipHeight = 57; p.squash = 1.11; p.neckOff = CGPoint(x: 24, y: -18); p.headOff = CGPoint(x: 12, y: -11)
            p.elbowL = CGPoint(x: -17, y: 6); p.handL = CGPoint(x: -31, y: 13)
            p.elbowR = CGPoint(x: -15, y: 10); p.handR = CGPoint(x: -29, y: 17)
            p.kneeL = CGPoint(x: -17, y: 6); p.footL = CGPoint(x: -36, y: 9)
            p.kneeR = CGPoint(x: -15, y: 10); p.footR = CGPoint(x: -34, y: 13)
        }, .powerIn), // PICADO pleno: acelera cayendo, vibracion de velocidad
        K8(0.42, P8 { p in
            p.hipHeight = 52; p.squash = 1.12; p.neckOff = CGPoint(x: 25, y: -15); p.headOff = CGPoint(x: 13, y: -10)
            p.elbowL = CGPoint(x: -17, y: 6); p.handL = CGPoint(x: -32, y: 12)
            p.elbowR = CGPoint(x: -15, y: 10); p.handR = CGPoint(x: -30, y: 16)
            p.kneeL = CGPoint(x: -17, y: 5); p.footL = CGPoint(x: -37, y: 8)
            p.kneeR = CGPoint(x: -15, y: 9); p.footR = CGPoint(x: -35, y: 12)
        }, .linear),
        K8(0.55, P8 { p in
            p.hipHeight = 49; p.squash = 1.11; p.neckOff = CGPoint(x: 25, y: -16); p.headOff = CGPoint(x: 13, y: -10)
            p.elbowL = CGPoint(x: -17, y: 6); p.handL = CGPoint(x: -31, y: 13)
            p.elbowR = CGPoint(x: -15, y: 10); p.handR = CGPoint(x: -29, y: 17)
            p.kneeL = CGPoint(x: -17, y: 6); p.footL = CGPoint(x: -36, y: 9)
            p.kneeR = CGPoint(x: -15, y: 10); p.footR = CGPoint(x: -34, y: 13)
        }, .easeOut), // REMONTE: abre los brazos como alas y la nariz sube
        K8(0.72, P8 { p in
            p.hipHeight = 52; p.squash = 1.05; p.neckOff = CGPoint(x: 14, y: -34); p.headOff = CGPoint(x: 6, y: -19)
            p.elbowL = CGPoint(x: -22, y: 2); p.handL = CGPoint(x: -34, y: 6)
            p.elbowR = CGPoint(x: 20, y: 6); p.handR = CGPoint(x: 30, y: 10)
            p.kneeL = CGPoint(x: -12, y: 14); p.footL = CGPoint(x: -24, y: 22)
            p.kneeR = CGPoint(x: -8, y: 18); p.footR = CGPoint(x: -18, y: 26)
        }, .easeInOut), // asienta en vuelo normal (encadenable con flyPose)
        K8(0.85, P8 { p in
            p.hipHeight = 55; p.squash = 1.06; p.neckOff = CGPoint(x: 8, y: -38); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: -18, y: 8); p.handL = CGPoint(x: -26, y: 14)
            p.elbowR = CGPoint(x: 16, y: 12); p.handR = CGPoint(x: 24, y: 18)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -18, y: 32)
            p.kneeR = CGPoint(x: -6, y: 24); p.footR = CGPoint(x: -12, y: 34)
        })
    ])

    // -- Levantar un objeto ENORME: el ACTO de levantarlo, en
    // one-shot, pensado para encadenar DESPUES con strengthPose
    // (que es el bucle de sostenerlo). Estructura: agarrarlo en el
    // suelo, un primer tiron que FRACASA (sube un palmo y recae,
    // con tembleque), respiro, y el tiron bueno con todo el cuerpo
    // que lo clava arriba con paso de tambaleo. El ultimo keyframe
    // reproduce la pose inicial de strengthPose para el encadenado.
    static let liftHuge = AnimationClip(name: "levantar-enorme", duration: 1.7, loops: false, keyframes: [
        K8(0.0, P8 { p in // agachado, manos en el objeto (en el suelo, delante)
            p.hipHeight = 34; p.squash = 0.92; p.neckOff = CGPoint(x: 12, y: -28); p.headOff = CGPoint(x: 6, y: -16)
            p.elbowL = CGPoint(x: -6, y: 16); p.handL = CGPoint(x: -2, y: 34)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 20, y: 36)
            p.kneeL = CGPoint(x: -15, y: 16); p.footL = CGPoint(x: -18, y: 34)
            p.kneeR = CGPoint(x: 14, y: 16); p.footR = CGPoint(x: 18, y: 34)
        }, .easeIn), // primer tiron: lo despega un palmo...
        K8(0.35, P8 { p in
            p.hipHeight = 38; p.squash = 0.95; p.neckOff = CGPoint(x: 8, y: -32); p.headOff = CGPoint(x: 4, y: -18)
            p.elbowL = CGPoint(x: -10, y: 8); p.handL = CGPoint(x: -8, y: 22)
            p.elbowR = CGPoint(x: 14, y: 10); p.handR = CGPoint(x: 14, y: 24)
            p.kneeL = CGPoint(x: -14, y: 19); p.footL = CGPoint(x: -18, y: 38)
            p.kneeR = CGPoint(x: 13, y: 19); p.footR = CGPoint(x: 17, y: 38)
        }, .linear), // ...y RECAE: no puede (todavia), tembleque de brazos
        K8(0.55, P8 { p in
            p.hipHeight = 35; p.squash = 0.92; p.hipDX = -1; p.neckOff = CGPoint(x: 10, y: -29); p.headOff = CGPoint(x: 5, y: -16)
            p.elbowL = CGPoint(x: -7, y: 15); p.handL = CGPoint(x: -3, y: 32)
            p.elbowR = CGPoint(x: 15, y: 17); p.handR = CGPoint(x: 19, y: 34)
            p.kneeL = CGPoint(x: -15, y: 16); p.footL = CGPoint(x: -18, y: 35)
            p.kneeR = CGPoint(x: 14, y: 16); p.footR = CGPoint(x: 18, y: 35)
        }, .easeIn), // respira, se recoloca los pies y agarra mejor
        K8(0.75, P8 { p in
            p.hipHeight = 33; p.squash = 0.90; p.neckOff = CGPoint(x: 12, y: -27); p.headOff = CGPoint(x: 6, y: -15)
            p.elbowL = CGPoint(x: -6, y: 16); p.handL = CGPoint(x: -2, y: 34)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 20, y: 36)
            p.kneeL = CGPoint(x: -16, y: 15); p.footL = CGPoint(x: -20, y: 33)
            p.kneeR = CGPoint(x: 15, y: 15); p.footR = CGPoint(x: 20, y: 33)
        }, .snappy), // ¡EL TIRON BUENO! piernas y espalda a la vez, el objeto sube
        K8(0.98, P8 { p in
            p.hipHeight = 46; p.squash = 1.0; p.neckOff = CGPoint(x: 4, y: -36); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -14, y: -2); p.handL = CGPoint(x: -13, y: -16) // el objeto ya va por el pecho
            p.elbowR = CGPoint(x: 14, y: -2); p.handR = CGPoint(x: 13, y: -16)
            p.kneeL = CGPoint(x: -13, y: 22); p.footL = CGPoint(x: -18, y: 46)
            p.kneeR = CGPoint(x: 12, y: 22); p.footR = CGPoint(x: 17, y: 46)
        }, .easeOut), // lo clava ARRIBA del todo, con paso de tambaleo al asentar
        K8(1.3, P8 { p in
            p.hipHeight = 50; p.hipDX = 3; p.squash = 0.98; p.neckOff = CGPoint(x: 1, y: -38); p.headOff = CGPoint(x: 1, y: -20)
            p.elbowL = CGPoint(x: -16, y: -10); p.handL = CGPoint(x: -17, y: -33)
            p.elbowR = CGPoint(x: 16, y: -10); p.handR = CGPoint(x: 17, y: -33)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -16, y: 50)
            p.kneeR = CGPoint(x: 14, y: 24); p.footR = CGPoint(x: 24, y: 48) // el pie que se replanta
        }, .backOut), // asienta: pose inicial de strengthPose (de aqui, su bucle)
        K8(1.7, P8 { p in
            p.hipHeight = 51; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -16, y: -10); p.handL = CGPoint(x: -17, y: -34)
            p.elbowR = CGPoint(x: 16, y: -10); p.handR = CGPoint(x: 17, y: -34)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -17, y: 51)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 17, y: 51)
        })
    ])

    // ============================================================
    // MARK: Vida — gestos y micro-vida
    // ============================================================

    // -- Aplaudir: las manos se encuentran en el centro del pecho.
    // El ritmo es el gag: dos aplausos normales, una pausa con
    // asentimiento de cabeza (esta impresionado) y un doble rapido
    // final con ganas. Nada de metronomo perfecto.
    static let clap = AnimationClip(name: "aplaudir", duration: 1.2, loops: true, keyframes: [
        K8(0.0, P8 { p in // manos separadas, listas
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -2, y: 20); p.handL = CGPoint(x: 3, y: 16)
            p.elbowR = CGPoint(x: 25, y: 18); p.handR = CGPoint(x: 27, y: 16)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡PLAS! primer aplauso
        K8(0.14, P8 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 4, y: 19); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 20, y: 18); p.handR = CGPoint(x: 17, y: 14) // manos juntas en el centro
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeOut), // se separan
        K8(0.26, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -2, y: 20); p.handL = CGPoint(x: 3, y: 16)
            p.elbowR = CGPoint(x: 25, y: 18); p.handR = CGPoint(x: 27, y: 16)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡PLAS! segundo
        K8(0.4, P8 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 4, y: 19); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 20, y: 18); p.handR = CGPoint(x: 17, y: 14)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // pausa: asiente con la cabeza, impresionado
        K8(0.62, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -1, y: 20); p.handL = CGPoint(x: 4, y: 16)
            p.elbowR = CGPoint(x: 24, y: 18); p.handR = CGPoint(x: 26, y: 16)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡PLAS!
        K8(0.78, P8 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: 4, y: 19); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 20, y: 18); p.handR = CGPoint(x: 17, y: 14)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeOut), // se separan un pelo...
        K8(0.88, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: 1, y: 20); p.handL = CGPoint(x: 6, y: 15)
            p.elbowR = CGPoint(x: 23, y: 18); p.handR = CGPoint(x: 24, y: 15)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡PLAS-PLAS! doble rapido de cierre, con mini-bounce
        K8(1.0, P8 { p in
            p.hipHeight = 56; p.squash = 1.01; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: 4, y: 19); p.handL = CGPoint(x: 12, y: 14)
            p.elbowR = CGPoint(x: 20, y: 18); p.handR = CGPoint(x: 17, y: 14)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .easeInOut) // se separan y el ciclo vuelve a empezar
    ])

    // -- Reverencia: inclinacion profunda con una mano al pecho y
    // la otra atras, elegante. Hold LARGO abajo (el respeto se
    // aguanta, no se pasa volando) y subida lenta con backOut.
    static let bow = AnimationClip(name: "reverencia", duration: 1.6, loops: false, keyframes: [
        K8(0.0, SkeletonPose.standing, .easeInOut), // empieza a inclinarse, mano al pecho
        K8(0.3, P8 { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 10, y: -35); p.headOff = CGPoint(x: 4, y: -19)
            p.elbowL = CGPoint(x: -19, y: 10); p.handL = CGPoint(x: -24, y: 8)  // brazo atras, elegante
            p.elbowR = CGPoint(x: 8, y: 20); p.handR = CGPoint(x: 3, y: 15)     // mano al pecho
            p.kneeL = CGPoint(x: -9, y: 27); p.footL = CGPoint(x: -9, y: 54)   // pies juntos
            p.kneeR = CGPoint(x: 9, y: 27); p.footR = CGPoint(x: 9, y: 54)
        }, .easeInOut), // inclinacion plena
        K8(0.62, P8 { p in
            p.hipHeight = 51; p.squash = 0.97; p.neckOff = CGPoint(x: 24, y: -23); p.headOff = CGPoint(x: 10, y: -13)
            p.elbowL = CGPoint(x: -20, y: 8); p.handL = CGPoint(x: -26, y: 5)
            p.elbowR = CGPoint(x: 9, y: 19); p.handR = CGPoint(x: 3, y: 14)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -9, y: 51)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 9, y: 51)
        }, .easeInOut), // AGUANTA la reverencia (el hold es el gesto)
        K8(0.98, P8 { p in
            p.hipHeight = 51; p.squash = 0.97; p.neckOff = CGPoint(x: 24, y: -23); p.headOff = CGPoint(x: 10, y: -13)
            p.elbowL = CGPoint(x: -20, y: 8); p.handL = CGPoint(x: -26, y: 5)
            p.elbowR = CGPoint(x: 9, y: 19); p.handR = CGPoint(x: 3, y: 14)
            p.kneeL = CGPoint(x: -9, y: 26); p.footL = CGPoint(x: -9, y: 51)
            p.kneeR = CGPoint(x: 9, y: 26); p.footR = CGPoint(x: 9, y: 51)
        }, .easeOut), // sube despacio, con dignidad
        K8(1.35, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 6, y: -38); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -18, y: 15); p.handL = CGPoint(x: -22, y: 26)
            p.elbowR = CGPoint(x: 12, y: 19); p.handR = CGPoint(x: 10, y: 24)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -11, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 11, y: 55)
        }, .backOut),
        K8(1.6, SkeletonPose.standing)
    ])

    // -- Suplicar de rodillas: las dos rodillas al suelo, las manos
    // JUNTAS frente al pecho y bobs de suplica con todo el torso.
    // A mitad de ciclo abre las manos en un "por favooor" mas
    // grande y las vuelve a juntar. Bucle de gesto (puede suplicar
    // rato largo al dedo).
    static let beg = AnimationClip(name: "suplicar", duration: 2.2, loops: true, keyframes: [
        K8(0.0, P8 { p in // de rodillas, manos juntas, bob de suplica abajo
            p.hipHeight = 23; p.neckOff = CGPoint(x: 13, y: -29); p.headOff = CGPoint(x: 5, y: -15)
            p.elbowL = CGPoint(x: 2, y: 16); p.handL = CGPoint(x: 11, y: 8)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 15, y: 9) // manos juntas rezando
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 17) // rodillas al suelo, empeines detras
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 14, y: 17)
        }, .easeOut), // bob hacia arriba: mira al dedo, esperanzado
        K8(0.35, P8 { p in
            p.hipHeight = 24; p.neckOff = CGPoint(x: 9, y: -32); p.headOff = CGPoint(x: 3, y: -18)
            p.elbowL = CGPoint(x: 2, y: 15); p.handL = CGPoint(x: 11, y: 6)
            p.elbowR = CGPoint(x: 16, y: 17); p.handR = CGPoint(x: 15, y: 7)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 17)
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 14, y: 17)
        }, .easeIn), // bob abajo otra vez
        K8(0.7, P8 { p in
            p.hipHeight = 23; p.neckOff = CGPoint(x: 13, y: -29); p.headOff = CGPoint(x: 5, y: -15)
            p.elbowL = CGPoint(x: 2, y: 16); p.handL = CGPoint(x: 11, y: 8)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 15, y: 9)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 17)
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 14, y: 17)
        }, .easeInOut), // abre las manos: ¡por favooor! el gesto grande
        K8(1.15, P8 { p in
            p.hipHeight = 24; p.neckOff = CGPoint(x: 11, y: -30); p.headOff = CGPoint(x: 4, y: -17)
            p.elbowL = CGPoint(x: -8, y: 12); p.handL = CGPoint(x: -2, y: 2)  // palmas arriba, abiertas
            p.elbowR = CGPoint(x: 24, y: 13); p.handR = CGPoint(x: 28, y: 3)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 17)
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 14, y: 17)
        }, .easeInOut), // las vuelve a juntar, bob profundo de cierre
        K8(1.6, P8 { p in
            p.hipHeight = 22; p.squash = 0.97; p.neckOff = CGPoint(x: 15, y: -28); p.headOff = CGPoint(x: 6, y: -14)
            p.elbowL = CGPoint(x: 2, y: 16); p.handL = CGPoint(x: 11, y: 8)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 15, y: 9)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -14, y: 17)
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 14, y: 17)
        }, .easeOut) // sube a la pose inicial y el ciclo se cierra
    ])

    // -- Impaciencia: brazos cruzados, un pie golpeando el suelo a
    // ritmo rapido (tramos lineales cortos) y, una vez por ciclo,
    // se mira la muneca como quien mira la hora y resopla con la
    // cabeza. El golpeteo NO para mientras mira: es lo que lo
    // delata.
    static let impatient = AnimationClip(name: "impaciencia", duration: 2.4, loops: true, keyframes: [
        K8(0.0, P8 { p in // brazos cruzados, pie derecho apoyado
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)  // mano L cruzada al lado contrario
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)   // mano R cruzada encima
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .linear), // TOC: el pie golpea (sube y baja seco)
        K8(0.13, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 50) // pie en el aire
        }, .linear),
        K8(0.26, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .linear), // TOC
        K8(0.39, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 50)
        }, .linear),
        K8(0.52, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // se mira la MUNECA (la hora): descruza solo el brazo izquierdo
        K8(0.95, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: -2, y: -18) // cabeza baja hacia la muneca
            p.elbowL = CGPoint(x: -10, y: 8); p.handL = CGPoint(x: 2, y: -2)   // muneca frente a la cara
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 50) // el pie SIGUE golpeando
        }, .linear), // TOC (mirando la hora)
        K8(1.08, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: -2, y: -18)
            p.elbowL = CGPoint(x: -10, y: 8); p.handL = CGPoint(x: 2, y: -2)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // resopla: niega con la cabeza y vuelve a cruzar los brazos
        K8(1.45, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: -4, y: -21)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 50)
        }, .linear), // TOC
        K8(1.58, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .linear), // TOC
        K8(1.71, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 15, y: 50)
        }, .linear), // TOC, y el ciclo cierra al volver a apoyar
        K8(1.84, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -14, y: 22); p.handL = CGPoint(x: 13, y: 10)
            p.elbowR = CGPoint(x: 16, y: 24); p.handR = CGPoint(x: -6, y: 13)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut) // cola tranquila hasta cerrar el bucle (la impaciencia respira)
    ])

    // -- Temblar de frio: abrazado a si mismo (cada mano al hombro
    // contrario), codos pegados, rodillas juntas, y un temblor FINO
    // y constante hecho con keyframes lineales cortos — el mismo
    // recurso que la vibracion de flyDash/chargePower, pero en
    // todo el cuerpo. Una vez por ciclo, un ESCALOFRIO grande:
    // se encoge de golpe y da un saltito. Distinto de scared
    // (miedo: manos arriba, retrocede): esto es termico y comico.
    static let shiver = AnimationClip(name: "temblar-frio", duration: 1.8, loops: true, keyframes: [
        K8(0.0, P8 { p in // abrazado, temblor fino (fase 0)
            p.hipHeight = 53; p.squash = 0.97; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 1, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)   // mano L al hombro contrario
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)  // mano R al otro hombro
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)  // rodillas juntas
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .linear), // temblor (fase 1)
        K8(0.12, P8 { p in
            p.hipHeight = 53; p.hipDX = -1; p.squash = 0.97; p.neckOff = CGPoint(x: 0, y: -39); p.headOff = CGPoint(x: -1, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .linear), // temblor (fase 2)
        K8(0.24, P8 { p in
            p.hipHeight = 52; p.hipDX = 1; p.squash = 0.96; p.neckOff = CGPoint(x: 2, y: -38); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 25); p.footL = CGPoint(x: -8, y: 52)
            p.kneeR = CGPoint(x: 7, y: 25); p.footR = CGPoint(x: 8, y: 52)
        }, .linear), // temblor (fase 3)
        K8(0.36, P8 { p in
            p.hipHeight = 53; p.squash = 0.97; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 0, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .snappy), // ¡ESCALOFRIO! se encoge de golpe y da un saltito
        K8(0.55, P8 { p in
            p.hipHeight = 57; p.squash = 1.03; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -7, y: 21); p.handL = CGPoint(x: 10, y: 2)
            p.elbowR = CGPoint(x: 11, y: 23); p.handR = CGPoint(x: -6, y: 4)
            p.kneeL = CGPoint(x: -8, y: 24); p.footL = CGPoint(x: -9, y: 49) // pies despegados en el saltito
            p.kneeR = CGPoint(x: 8, y: 24); p.footR = CGPoint(x: 9, y: 49)
        }, .easeOut), // cae del saltito y se re-abraza
        K8(0.75, P8 { p in
            p.hipHeight = 53; p.squash = 0.96; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 1, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .linear), // temblor (fase 1, segunda vuelta)
        K8(0.95, P8 { p in
            p.hipHeight = 53; p.hipDX = -1; p.squash = 0.97; p.neckOff = CGPoint(x: 0, y: -39); p.headOff = CGPoint(x: -1, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .linear), // temblor (fase 2)
        K8(1.15, P8 { p in
            p.hipHeight = 52; p.hipDX = 1; p.squash = 0.96; p.neckOff = CGPoint(x: 2, y: -38); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 25); p.footL = CGPoint(x: -8, y: 52)
            p.kneeR = CGPoint(x: 7, y: 25); p.footR = CGPoint(x: 8, y: 52)
        }, .linear), // temblor (fase 3) y el ciclo se cierra
        K8(1.35, P8 { p in
            p.hipHeight = 53; p.squash = 0.97; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 1, y: -20)
            p.elbowL = CGPoint(x: -8, y: 22); p.handL = CGPoint(x: 9, y: 3)
            p.elbowR = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -7, y: 5)
            p.kneeL = CGPoint(x: -7, y: 26); p.footL = CGPoint(x: -8, y: 53)
            p.kneeR = CGPoint(x: 7, y: 26); p.footR = CGPoint(x: 8, y: 53)
        }, .linear)
    ])

    // -- Llamar con la mano ("ven aqui"): la mano derecha se curva
    // hacia si dos veces, pausa desafiante con la cabeza ladeada y
    // la otra mano en la cadera, y dos llamadas mas rapidas. Es el
    // gesto de provocacion al dedo por excelencia. Distinto de
    // wave (saludar, mano en alto oscilando): esto es a la altura
    // del pecho y el movimiento es de GARRA hacia dentro.
    static let beckon = AnimationClip(name: "ven-aqui", duration: 1.4, loops: true, keyframes: [
        K8(0.0, P8 { p in // mano en la cadera, la otra lista a la altura del pecho
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25) // mano en la cadera
            p.elbowR = CGPoint(x: 19, y: 12); p.handR = CGPoint(x: 27, y: 4)    // mano abierta hacia el dedo
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeIn), // llamada 1: la garra se cierra hacia si
        K8(0.22, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 17, y: 13); p.handR = CGPoint(x: 16, y: 8)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeOut), // abre otra vez
        K8(0.4, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 19, y: 12); p.handR = CGPoint(x: 27, y: 4)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeIn), // llamada 2
        K8(0.6, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 17, y: 13); p.handR = CGPoint(x: 16, y: 8)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeInOut), // PAUSA desafiante: cabeza ladeada, mano abierta quieta
        K8(0.95, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 6, y: -21) // ladea la cabeza
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 19, y: 12); p.handR = CGPoint(x: 27, y: 4)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeIn), // llamadas 3 y 4, mas rapidas (pierde la paciencia)
        K8(1.12, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 17, y: 13); p.handR = CGPoint(x: 16, y: 8)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeOut),
        K8(1.24, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 19, y: 12); p.handR = CGPoint(x: 27, y: 4)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeIn),
        K8(1.36, P8 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -20, y: 15); p.handL = CGPoint(x: -14, y: 25)
            p.elbowR = CGPoint(x: 17, y: 13); p.handR = CGPoint(x: 16, y: 8)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .easeOut) // abre y el ciclo se cierra
    ])

    // -- Chocar los cinco con el dedo: el gesto AMISTOSO con el
    // dedo (el contrapunto de grabFinger/grabbed, que son de
    // forcejeo). Mira arriba, salta con la palma abierta al cielo,
    // CONTACTO con hold — la mano se queda un instante "pegada"
    // al dedo — y baja contento con un mini-punito de celebracion.
    // La vista debe alinear la palma con la posicion del dedo en
    // la marca de contacto (0.48).
    static let highFive = AnimationClip(name: "chocar-cinco", duration: 1.0, loops: false, keyframes: [
        K8(0.0, P8 { p in // mirando arriba, al dedo, con ganas
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -42); p.headOff = CGPoint(x: 2, y: -24)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 20, y: 22)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeIn), // se agacha un pelo para saltar
        K8(0.2, P8 { p in
            p.hipHeight = 51; p.squash = 0.93; p.neckOff = CGPoint(x: 1, y: -39); p.headOff = CGPoint(x: 2, y: -23)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: -20, y: 38)
            p.elbowR = CGPoint(x: 15, y: 18); p.handR = CGPoint(x: 18, y: 30)
            p.kneeL = CGPoint(x: -13, y: 24); p.footL = CGPoint(x: -15, y: 51)
            p.kneeR = CGPoint(x: 13, y: 24); p.footR = CGPoint(x: 15, y: 51)
        }, .snappy), // ¡SALTA! palma abierta al cielo
        K8(0.36, P8 { p in
            p.hipHeight = 62; p.squash = 1.07; p.neckOff = CGPoint(x: 1, y: -44); p.headOff = CGPoint(x: 2, y: -25)
            p.elbowL = CGPoint(x: -15, y: 16); p.handL = CGPoint(x: -18, y: 28)
            p.elbowR = CGPoint(x: 12, y: -18); p.handR = CGPoint(x: 16, y: -40) // la palma, en lo alto
            p.kneeL = CGPoint(x: -8, y: 28); p.footL = CGPoint(x: -10, y: 48)
            p.kneeR = CGPoint(x: 8, y: 28); p.footR = CGPoint(x: 10, y: 48)
        }, .easeOut), // CONTACTO con el dedo: la mano se queda pegada un instante
        K8(0.48, P8 { p in
            p.hipHeight = 63; p.squash = 1.04; p.neckOff = CGPoint(x: 1, y: -44); p.headOff = CGPoint(x: 2, y: -25)
            p.elbowL = CGPoint(x: -15, y: 16); p.handL = CGPoint(x: -18, y: 28)
            p.elbowR = CGPoint(x: 12, y: -18); p.handR = CGPoint(x: 16, y: -40)
            p.kneeL = CGPoint(x: -8, y: 28); p.footL = CGPoint(x: -10, y: 49)
            p.kneeR = CGPoint(x: 8, y: 28); p.footR = CGPoint(x: 10, y: 49)
        }, .easeIn), // cae del salto
        K8(0.68, P8 { p in
            p.hipHeight = 54; p.squash = 0.95; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 34)
            p.elbowR = CGPoint(x: 14, y: 12); p.handR = CGPoint(x: 18, y: 8)
            p.kneeL = CGPoint(x: -12, y: 25); p.footL = CGPoint(x: -14, y: 54)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 14, y: 54)
        }, .backOut), // aterriza contento: mini-punito de celebracion
        K8(0.86, P8 { p in
            p.hipHeight = 57; p.squash = 1.02; p.neckOff = CGPoint(x: 1, y: -42); p.headOff = CGPoint(x: 2, y: -23)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 6); p.handR = CGPoint(x: 20, y: -2) // punito arriba
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 57)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 57)
        }, .easeInOut),
        K8(1.0, SkeletonPose.standing)
    ])

    // -- Sentado girando la cabeza (cruce con el pack:
    // SitAndSpinHead): micro-vida SENTADA. El cuerpo queda en la
    // pose de `sit` y SOLO se mueve la cabeza (y la respiracion
    // del cuello): mira a un lado con giro seco, aguanta, mira al
    // otro, niega despacio dos veces y vuelve al frente. Es el
    // companero sentado de lookAround (que es de pie).
    static let sitSpinHead = AnimationClip(name: "sentado-girar-cabeza", duration: 2.6, loops: true, keyframes: [
        K8(0.0, P8 { p in // sentado mirando al frente (base de sit)
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .snappy), // gira la cabeza a la izquierda, seco
        K8(0.3, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: -1, y: -34); p.headOff = CGPoint(x: -8, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .easeInOut), // aguanta mirando (respira: el cuello sube 1)
        K8(0.85, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: -1, y: -33); p.headOff = CGPoint(x: -8, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .snappy), // gira a la derecha, seco
        K8(1.15, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 1, y: -34); p.headOff = CGPoint(x: 8, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .easeInOut), // aguanta mirando a la derecha
        K8(1.65, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 1, y: -33); p.headOff = CGPoint(x: 8, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .easeInOut), // vuelve al frente negando despacio (mini no-no)
        K8(2.0, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34); p.headOff = CGPoint(x: -3, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .easeInOut),
        K8(2.25, P8 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -11, y: 24)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 11, y: 24)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        }, .easeInOut) // y se centra: el ciclo se cierra en la pose inicial
    ])
}
