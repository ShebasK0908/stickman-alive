import Foundation
import SwiftUI

// MARK: - PASE v7: clips NUEVOS minados de AvA 1, AvA 2 y AvA 4
//
// Continuacion del pase v6 (ver CHANGELOG-ANIM.md): se han vuelto a
// mirar los tres episodios buscando MOVIMIENTOS que la libreria de
// 63 clips aun no tuviera, y se han recreado como clips de datos con
// el mismo sistema (SkeletonPose / AnimKeyframe / AnimationClip).
//
// Que NO es (la linea de siempre): no se ha copiado ni un fotograma
// ni se ha usado ningun sprite de terceros. Solo el PATRON de
// movimiento (que hace el cuerpo, en que orden, con que tiempos),
// re-expresado con nuestro esqueleto de offsets y los criterios de
// la v6: anticipacion antes de cada accion, holds de impacto mas
// largos que la anticipacion de los golpes rapidos, squash & stretch
// para el peso, easings .powerIn para las caidas que aceleran y
// .backOut para las recuperaciones que "respiran".
//
// Fichero ADITIVO y autonimo: no toca StickmanAnimation.swift ni
// anade casos a StickmanAction (sus switches son exhaustivos y sin
// default; el cableado es trabajo de integracion, ver
// CHANGELOG-ANIM-V7.md). Los tipos SkeletonPose, AnimKeyframe,
// AnimationClip y AnimEasing son los del fichero original (mismo
// modulo al integrar). Los helpers P/K originales son `private` de
// su fichero y no se ven desde aqui: por eso existen P7/K7.
//
// OJO al escribir poses: cada keyframe es una pose COMPLETA construida
// desde `standing` (igual que en la libreria original). Todo canal
// que no se toca en un keyframe vuelve al valor de pie, asi que cada
// keyframe de este fichero fija todos los canales que le importan.

// Constructor comodo de poses a partir de la pose de pie (gemelo de P)
private func P7(_ modify: (inout SkeletonPose) -> Void) -> SkeletonPose {
    var p = SkeletonPose.standing
    modify(&p)
    return p
}
private func K7(_ time: Double, _ pose: SkeletonPose, _ easing: AnimEasing = .easeInOut) -> AnimKeyframe {
    AnimKeyframe(time: time, pose: pose, easing: easing)
}

// MARK: - Catalogo v7 (19 clips nuevos)

enum AnimationLibraryV7 {

    // ============================================================
    // MARK: Poderes y entradas (AvA 2 + fotos del usuario)
    // ============================================================

    // -- Vuelo propulsado VERTICAL (fotos de referencia del usuario,
    // 2026-11-11): chorros de llama que salen de las MANOS hacia
    // abajo y lo sostienen en el aire. Es el complemento vertical de
    // flyPose (horizontal, tipo superman): cuerpo RECTO, brazos
    // pegados a los costados con las palmas hacia abajo, piernas
    // rectas y juntas. El ciclo es el ciclo del chorro: carga en el
    // suelo -> despegue seco -> sosten con temblor -> bache (el
    // chorro "tose" y pierde altura) -> re-ignicion -> sosten alto
    // -> descenso a recargar. Los chorros los dibuja el motor de
    // poderes desde las manos; aqui solo va el cuerpo (como en
    // firePose/laserPose): conviene encender el efecto en el
    // keyframe de despegue (0.44) y cortarlo en el descenso (1.85).
    static let flameJet = AnimationClip(name: "vuelo-propulsado", duration: 2.2, loops: true, keyframes: [
        K7(0.0, P7 { p in // en el suelo: agachado, puños abajo a los lados, cargando fuego
            p.hipHeight = 50; p.squash = 0.93; p.neckOff = CGPoint(x: 2, y: -38); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -13, y: 16); p.handL = CGPoint(x: -12, y: 32)
            p.elbowR = CGPoint(x: 13, y: 16); p.handR = CGPoint(x: 12, y: 32)
            p.kneeL = CGPoint(x: -12, y: 25); p.footL = CGPoint(x: -14, y: 50)
            p.kneeR = CGPoint(x: 12, y: 25); p.footR = CGPoint(x: 14, y: 50)
        }, .easeIn), // la carga crece (el fuego ruge en las palmas)
        K7(0.30, P7 { p in // carga maxima: mas agachado, micro-temblor de presion
            p.hipHeight = 48; p.squash = 0.91; p.hipDX = -1; p.neckOff = CGPoint(x: 3, y: -37); p.headOff = CGPoint(x: 3, y: -19)
            p.elbowL = CGPoint(x: -14, y: 17); p.handL = CGPoint(x: -13, y: 34)
            p.elbowR = CGPoint(x: 14, y: 17); p.handR = CGPoint(x: 13, y: 34)
            p.kneeL = CGPoint(x: -13, y: 24); p.footL = CGPoint(x: -15, y: 48)
            p.kneeR = CGPoint(x: 13, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .snappy), // ¡DESPEGUE! los chorros lo lanzan hacia arriba
        K7(0.44, P7 { p in // en el aire: recto y ESTIRADO, brazos pegados, piernas juntas
            p.hipHeight = 62; p.squash = 1.08; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -12, y: 38)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 12, y: 38)
            p.kneeL = CGPoint(x: -5, y: 29); p.footL = CGPoint(x: -4, y: 58)
            p.kneeR = CGPoint(x: 5, y: 29); p.footR = CGPoint(x: 4, y: 58)
        }, .linear), // sosten con temblor de chorro (lineal, como la vibracion de flyDash)
        K7(0.70, P7 { p in
            p.hipHeight = 61; p.squash = 1.06; p.hipDX = 1; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -12, y: 37)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 12, y: 39)
            p.kneeL = CGPoint(x: -5, y: 29); p.footL = CGPoint(x: -4, y: 57)
            p.kneeR = CGPoint(x: 5, y: 29); p.footR = CGPoint(x: 4, y: 57)
        }, .linear),
        K7(0.95, P7 { p in
            p.hipHeight = 62; p.squash = 1.06; p.hipDX = -1; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -13, y: 39)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 11, y: 37)
            p.kneeL = CGPoint(x: -5, y: 29); p.footL = CGPoint(x: -4, y: 57)
            p.kneeR = CGPoint(x: 5, y: 29); p.footR = CGPoint(x: 4, y: 57)
        }, .easeInOut), // BACHE: el chorro tose y pierde un pelo de altura
        K7(1.25, P7 { p in
            p.hipHeight = 57; p.squash = 1.02; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -12, y: 17); p.handL = CGPoint(x: -14, y: 36)
            p.elbowR = CGPoint(x: 12, y: 17); p.handR = CGPoint(x: 14, y: 36)
            p.kneeL = CGPoint(x: -6, y: 28); p.footL = CGPoint(x: -5, y: 54)
            p.kneeR = CGPoint(x: 6, y: 28); p.footR = CGPoint(x: 5, y: 54)
        }, .snappy), // RE-IGNICION: empuja con las palmas y recupera la altura
        K7(1.45, P7 { p in // sosten alto, estable
            p.hipHeight = 62; p.squash = 1.07; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -12, y: 38)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 12, y: 38)
            p.kneeL = CGPoint(x: -5, y: 29); p.footL = CGPoint(x: -4, y: 58)
            p.kneeR = CGPoint(x: 5, y: 29); p.footR = CGPoint(x: 4, y: 58)
        }, .easeInOut),
        K7(1.85, P7 { p in // empieza a bajar para recargar: el cierre del ciclo
            p.hipHeight = 59; p.squash = 1.04; p.neckOff = CGPoint(x: 2, y: -42); p.headOff = CGPoint(x: 1, y: -23)
            p.elbowL = CGPoint(x: -11, y: 18); p.handL = CGPoint(x: -12, y: 37)
            p.elbowR = CGPoint(x: 11, y: 18); p.handR = CGPoint(x: 12, y: 37)
            p.kneeL = CGPoint(x: -5, y: 29); p.footL = CGPoint(x: -4, y: 56)
            p.kneeR = CGPoint(x: 5, y: 29); p.footR = CGPoint(x: 4, y: 56)
        }, .easeIn)
    ])

    // -- Aterrizaje de superheroe (AvA 2: TCO cae de muy alto y clava
    // la llegada): una rodilla al suelo, el pie contrario plantado y
    // el PUÑO al suelo, con la cabeza alta mirando al frente. La
    // caida llega con powerIn (acelera), el impacto se aguanta con
    // tremor y la levantada es lenta y sobrada (backOut al asentar).
    // Encadenar DESPUES de fallPose; el motor pone el desplazamiento.
    static let heroLanding = AnimationClip(name: "aterrizaje-heroe", duration: 1.25, loops: false, keyframes: [
        K7(0.0, P7 { p in // cayendo, recogido, el puño ya busca el suelo
            p.hipHeight = 58; p.squash = 1.05; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -14, y: 10); p.handL = CGPoint(x: -18, y: 16)
            p.elbowR = CGPoint(x: 10, y: 18); p.handR = CGPoint(x: 16, y: 28)
            p.kneeL = CGPoint(x: 12, y: 24); p.footL = CGPoint(x: 10, y: 42)
            p.kneeR = CGPoint(x: -4, y: 22); p.footR = CGPoint(x: -13, y: 38)
        }, .powerIn), // la gravedad manda: acelera hasta el impacto
        K7(0.16, P7 { p in // ultimo instante: pierna delantera lista, puño extendido
            p.hipHeight = 54; p.squash = 1.02; p.neckOff = CGPoint(x: 4, y: -38); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -15, y: 11); p.handL = CGPoint(x: -20, y: 18)
            p.elbowR = CGPoint(x: 12, y: 20); p.handR = CGPoint(x: 19, y: 34)
            p.kneeL = CGPoint(x: 14, y: 26); p.footL = CGPoint(x: 9, y: 50)
            p.kneeR = CGPoint(x: -2, y: 24); p.footR = CGPoint(x: -11, y: 44)
        }, .powerIn), // ¡IMPACTO! la pose del heroe, clavada
        K7(0.30, P7 { p in
            p.hipHeight = 22; p.squash = 0.94; p.neckOff = CGPoint(x: 14, y: -27); p.headOff = CGPoint(x: 8, y: -16)
            p.elbowL = CGPoint(x: -16, y: 10); p.handL = CGPoint(x: -21, y: 17)
            p.elbowR = CGPoint(x: 21, y: 21); p.handR = CGPoint(x: 16, y: 46) // puño al suelo
            p.kneeL = CGPoint(x: 23, y: 8); p.footL = CGPoint(x: 18, y: 22) // pie plantado
            p.kneeR = CGPoint(x: 7, y: 20); p.footR = CGPoint(x: 25, y: 9)  // rodilla al suelo
        }, .linear), // tremor del impacto (la onda sale del puño)
        K7(0.40, P7 { p in
            p.hipHeight = 22; p.squash = 0.95; p.neckOff = CGPoint(x: 14, y: -27); p.headOff = CGPoint(x: 8, y: -16)
            p.elbowL = CGPoint(x: -16, y: 10); p.handL = CGPoint(x: -21, y: 17)
            p.elbowR = CGPoint(x: 21, y: 21); p.handR = CGPoint(x: 17, y: 45)
            p.kneeL = CGPoint(x: 23, y: 8); p.footL = CGPoint(x: 18, y: 22)
            p.kneeR = CGPoint(x: 7, y: 20); p.footR = CGPoint(x: 25, y: 9)
        }, .linear),
        K7(0.55, P7 { p in // aguanta la pose y levanta la mirada
            p.hipHeight = 23; p.squash = 0.96; p.neckOff = CGPoint(x: 13, y: -29); p.headOff = CGPoint(x: 7, y: -19)
            p.elbowL = CGPoint(x: -15, y: 10); p.handL = CGPoint(x: -20, y: 16)
            p.elbowR = CGPoint(x: 21, y: 21); p.handR = CGPoint(x: 16, y: 45)
            p.kneeL = CGPoint(x: 23, y: 9); p.footL = CGPoint(x: 18, y: 23)
            p.kneeR = CGPoint(x: 7, y: 20); p.footR = CGPoint(x: 25, y: 10)
        }, .easeOut), // se levanta, sin prisa
        K7(0.90, P7 { p in // medio levantado, el puño se despega del suelo
            p.hipHeight = 42; p.squash = 0.99; p.neckOff = CGPoint(x: 8, y: -36); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: -14, y: 12); p.handL = CGPoint(x: -18, y: 18)
            p.elbowR = CGPoint(x: 14, y: 14); p.handR = CGPoint(x: 20, y: 22)
            p.kneeL = CGPoint(x: 18, y: 16); p.footL = CGPoint(x: 16, y: 42)
            p.kneeR = CGPoint(x: 8, y: 22); p.footR = CGPoint(x: 14, y: 40)
        }, .backOut), // asienta de pie, sobrado
        K7(1.25, P7 { p in
            p.hipHeight = 56; p.squash = 1.01; p.neckOff = CGPoint(x: 2, y: -43); p.headOff = CGPoint(x: 1, y: -23)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 15, y: 17); p.handR = CGPoint(x: 17, y: 32) // puño cerrado al costado
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        })
    ])

    // ============================================================
    // MARK: Pelea — golpes sueltos (AvA 1 y AvA 2)
    // La rafaga vive en fightCombo; estos son los golpes con nombre
    // propio que en los videos aparecen SUELTOS (contraataques,
    // remates) y que la libreria no tenia como clips independientes.
    // ============================================================

    // -- Gancho ascendente (uppercut): el golpe que levanta al rival
    // en AvA 1/2. Carga MUY baja (el puño casi en la rodilla, cuerpo
    // enroscado), explosion vertical hasta quedarse de puntillas con
    // el puño en el cielo, y bajada a la guardia del combo.
    static let uppercut = AnimationClip(name: "gancho", duration: 1.05, loops: false, keyframes: [
        K7(0.0, P7 { p in // guardia del combo (pose de partida encadenable)
            p.hipHeight = 50; p.squash = 0.98; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        }, .easeIn), // se agacha cargando: el puño baja buscando el suelo
        K7(0.30, P7 { p in // carga profunda: torso girado, puño junto a la rodilla
            p.hipHeight = 42; p.squash = 0.90; p.hipDX = -2; p.neckOff = CGPoint(x: -4, y: -36); p.headOff = CGPoint(x: -2, y: -20)
            p.elbowL = CGPoint(x: 2, y: 14); p.handL = CGPoint(x: 14, y: 2)  // la otra mano guarda la cara
            p.elbowR = CGPoint(x: 4, y: 26); p.handR = CGPoint(x: 16, y: 34)
            p.kneeL = CGPoint(x: -13, y: 20); p.footL = CGPoint(x: -21, y: 42)
            p.kneeR = CGPoint(x: 14, y: 20); p.footR = CGPoint(x: 23, y: 42)
        }, .easeIn), // aguanta la bobina un instante mas
        K7(0.40, P7 { p in
            p.hipHeight = 41; p.squash = 0.89; p.hipDX = -3; p.neckOff = CGPoint(x: -5, y: -35); p.headOff = CGPoint(x: -3, y: -19)
            p.elbowL = CGPoint(x: 2, y: 14); p.handL = CGPoint(x: 13, y: 1)
            p.elbowR = CGPoint(x: 2, y: 27); p.handR = CGPoint(x: 14, y: 36)
            p.kneeL = CGPoint(x: -13, y: 19); p.footL = CGPoint(x: -21, y: 41)
            p.kneeR = CGPoint(x: 14, y: 19); p.footR = CGPoint(x: 23, y: 41)
        }, .snappy), // ¡GANCHO! explosion vertical con todo el cuerpo
        K7(0.52, P7 { p in // apex: de puntillas, puño en el cielo, cuerpo estirado
            p.hipHeight = 60; p.squash = 1.09; p.hipDX = 2; p.neckOff = CGPoint(x: 6, y: -44); p.headOff = CGPoint(x: 3, y: -24)
            p.elbowL = CGPoint(x: 0, y: 10); p.handL = CGPoint(x: 12, y: -4)
            p.elbowR = CGPoint(x: 17, y: -13); p.handR = CGPoint(x: 24, y: -38)
            p.kneeL = CGPoint(x: -8, y: 30); p.footL = CGPoint(x: -13, y: 58)
            p.kneeR = CGPoint(x: 7, y: 30); p.footR = CGPoint(x: 11, y: 58)
        }, .linear), // el apex vibra un pelo (el golpe sigue subiendo)
        K7(0.60, P7 { p in
            p.hipHeight = 60; p.squash = 1.09; p.hipDX = 2; p.neckOff = CGPoint(x: 6, y: -44); p.headOff = CGPoint(x: 3, y: -24)
            p.elbowL = CGPoint(x: 0, y: 10); p.handL = CGPoint(x: 12, y: -4)
            p.elbowR = CGPoint(x: 18, y: -12); p.handR = CGPoint(x: 25, y: -37)
            p.kneeL = CGPoint(x: -8, y: 30); p.footL = CGPoint(x: -13, y: 58)
            p.kneeR = CGPoint(x: 7, y: 30); p.footR = CGPoint(x: 11, y: 58)
        }, .easeOut), // baja a guardia alta
        K7(0.78, P7 { p in
            p.hipHeight = 53; p.neckOff = CGPoint(x: 5, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 3, y: 15); p.handL = CGPoint(x: 15, y: 4)
            p.elbowR = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 25, y: 0)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -16, y: 53)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 19, y: 53)
        }, .easeInOut),
        K7(1.05, P7 { p in // guardia del combo otra vez (cierre encadenable)
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 4, y: 17); p.handL = CGPoint(x: 17, y: 6)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 27, y: 11)
            p.kneeL = CGPoint(x: -12, y: 26); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 13, y: 26); p.footR = CGPoint(x: 22, y: 50)
        })
    ])

    // -- Patada voladora (AvA 2: TCO se lanza en el aire y clava la
    // patada con el cuerpo casi horizontal). Distinta de la patada
    // frontal de fightCombo, que es de pie: aqui AMBOS pies dejan el
    // suelo y la pierna de apoyo cuelga detras. Sin rotacion global
    // (limite del motor) la horizontal se sugiere con neckOff atras
    // y squash estirado. Termina en agachon de aterrizaje: encadenar
    // con la recuperacion de `landing`.
    static let flyingKick = AnimationClip(name: "patada-voladora", duration: 0.95, loops: false, keyframes: [
        K7(0.0, P7 { p in // en el aire, recogido: las dos piernas encogidas
            p.hipHeight = 57; p.squash = 1.02; p.neckOff = CGPoint(x: 4, y: -40); p.headOff = CGPoint(x: 2, y: -21)
            p.elbowL = CGPoint(x: -14, y: 10); p.handL = CGPoint(x: -16, y: 14)
            p.elbowR = CGPoint(x: -12, y: 16); p.handR = CGPoint(x: -20, y: 22)
            p.kneeL = CGPoint(x: 6, y: 20); p.footL = CGPoint(x: -8, y: 36)
            p.kneeR = CGPoint(x: 22, y: 16); p.footR = CGPoint(x: 8, y: 28)
        }, .easeIn), // sube y aprieta la camara de la patada
        K7(0.18, P7 { p in // camara maxima: rodilla arriba, cuerpo cargado
            p.hipHeight = 59; p.squash = 1.05; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -15, y: 9); p.handL = CGPoint(x: -18, y: 12)
            p.elbowR = CGPoint(x: -13, y: 15); p.handR = CGPoint(x: -22, y: 20)
            p.kneeL = CGPoint(x: 2, y: 22); p.footL = CGPoint(x: -12, y: 38)
            p.kneeR = CGPoint(x: 26, y: 14); p.footR = CGPoint(x: 4, y: 22)
        }, .snappy), // ¡PATADA! extension seca
        K7(0.30, P7 { p in // IMPACTO: pierna recta a la altura del pecho, cuerpo atras
            p.hipHeight = 58; p.squash = 1.08; p.hipDX = 3; p.neckOff = CGPoint(x: -8, y: -38); p.headOff = CGPoint(x: -3, y: -20)
            p.elbowL = CGPoint(x: 10, y: 8); p.handL = CGPoint(x: 24, y: 0)   // guardia delante
            p.elbowR = CGPoint(x: -16, y: 12); p.handR = CGPoint(x: -27, y: 15)
            p.kneeL = CGPoint(x: -9, y: 25); p.footL = CGPoint(x: -21, y: 40) // la otra pierna cuelga detras
            p.kneeR = CGPoint(x: 32, y: 17); p.footR = CGPoint(x: 54, y: 20)
        }, .easeInOut), // hold de impacto
        K7(0.44, P7 { p in
            p.hipHeight = 58; p.squash = 1.07; p.hipDX = 3; p.neckOff = CGPoint(x: -8, y: -38); p.headOff = CGPoint(x: -3, y: -20)
            p.elbowL = CGPoint(x: 10, y: 8); p.handL = CGPoint(x: 23, y: 1)
            p.elbowR = CGPoint(x: -16, y: 12); p.handR = CGPoint(x: -27, y: 15)
            p.kneeL = CGPoint(x: -9, y: 25); p.footL = CGPoint(x: -21, y: 40)
            p.kneeR = CGPoint(x: 31, y: 17); p.footR = CGPoint(x: 53, y: 21)
        }, .easeIn), // recoge la pierna y el cuerpo vuelve a vertical
        K7(0.62, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -39); p.headOff = CGPoint(x: 0, y: -21)
            p.elbowL = CGPoint(x: -4, y: 14); p.handL = CGPoint(x: 6, y: 10)
            p.elbowR = CGPoint(x: -10, y: 14); p.handR = CGPoint(x: -14, y: 18)
            p.kneeL = CGPoint(x: -4, y: 24); p.footL = CGPoint(x: -14, y: 42)
            p.kneeR = CGPoint(x: 22, y: 18); p.footR = CGPoint(x: 12, y: 30)
        }, .powerIn), // cae hacia el aterrizaje
        K7(0.80, P7 { p in
            p.hipHeight = 46; p.squash = 0.94; p.neckOff = CGPoint(x: 4, y: -37); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -14, y: 20)
            p.elbowR = CGPoint(x: 8, y: 14); p.handR = CGPoint(x: 16, y: 18)
            p.kneeL = CGPoint(x: -10, y: 20); p.footL = CGPoint(x: -15, y: 45)
            p.kneeR = CGPoint(x: 10, y: 20); p.footR = CGPoint(x: 16, y: 45)
        }, .easeOut),
        K7(0.95, P7 { p in // agachon de aterrizaje (encadena con `landing`)
            p.hipHeight = 42; p.squash = 0.90; p.neckOff = CGPoint(x: 5, y: -35); p.headOff = CGPoint(x: 2, y: -19)
            p.elbowL = CGPoint(x: -13, y: 14); p.handL = CGPoint(x: -16, y: 22)
            p.elbowR = CGPoint(x: 9, y: 14); p.handR = CGPoint(x: 18, y: 20)
            p.kneeL = CGPoint(x: -11, y: 18); p.footL = CGPoint(x: -17, y: 42)
            p.kneeR = CGPoint(x: 11, y: 18); p.footR = CGPoint(x: 18, y: 42)
        })
    ])

    // -- Placaje (AvA 2: la embestida con el hombro con la que TCO
    // derriba lo que tenga delante). Salida de velocista, cuerpo en
    // flecha baja, CONTACTO con los brazos envolviendo (el "rival"
    // lo pone el mundo), empuje de piernas y caida de los dos: el
    // clip termina encima, en pose de montada baja. El avance
    // horizontal lo pone el motor, como en run/flyDash.
    static let tackle = AnimationClip(name: "placaje", duration: 1.1, loops: false, keyframes: [
        K7(0.0, P7 { p in // agachado de velocista, listo para salir
            p.hipHeight = 44; p.squash = 0.95; p.neckOff = CGPoint(x: 12, y: -34); p.headOff = CGPoint(x: 5, y: -18)
            p.elbowL = CGPoint(x: -14, y: 14); p.handL = CGPoint(x: -20, y: 24)
            p.elbowR = CGPoint(x: -16, y: 16); p.handR = CGPoint(x: -24, y: 28)
            p.kneeL = CGPoint(x: -14, y: 20); p.footL = CGPoint(x: -25, y: 44)
            p.kneeR = CGPoint(x: 12, y: 18); p.footR = CGPoint(x: 6, y: 40)
        }, .powerIn), // arranca acelerando, cuerpo en flecha baja
        K7(0.22, P7 { p in // horizontal, brazos abiertos a envolver
            p.hipHeight = 48; p.squash = 1.06; p.hipDX = 4; p.neckOff = CGPoint(x: 20, y: -28); p.headOff = CGPoint(x: 8, y: -14)
            p.elbowL = CGPoint(x: 16, y: 2); p.handL = CGPoint(x: 30, y: 4)
            p.elbowR = CGPoint(x: 20, y: -2); p.handR = CGPoint(x: 35, y: -3)
            p.kneeL = CGPoint(x: -6, y: 18); p.footL = CGPoint(x: -16, y: 30)
            p.kneeR = CGPoint(x: -18, y: 20); p.footR = CGPoint(x: -32, y: 36)
        }, .easeIn), // ¡CONTACTO! los brazos envuelven y el hombro entra
        K7(0.42, P7 { p in
            p.hipHeight = 47; p.squash = 0.97; p.hipDX = 6; p.neckOff = CGPoint(x: 17, y: -26); p.headOff = CGPoint(x: 6, y: -13)
            p.elbowL = CGPoint(x: 14, y: 8); p.handL = CGPoint(x: 22, y: 15)
            p.elbowR = CGPoint(x: 18, y: 4); p.handR = CGPoint(x: 27, y: 9)
            p.kneeL = CGPoint(x: 2, y: 18); p.footL = CGPoint(x: -6, y: 32)
            p.kneeR = CGPoint(x: -15, y: 21); p.footR = CGPoint(x: -28, y: 38)
        }, .easeInOut), // empuja con las piernas, el rival cede
        K7(0.58, P7 { p in
            p.hipHeight = 45; p.squash = 0.96; p.hipDX = 8; p.neckOff = CGPoint(x: 16, y: -24); p.headOff = CGPoint(x: 5, y: -13)
            p.elbowL = CGPoint(x: 14, y: 8); p.handL = CGPoint(x: 21, y: 16)
            p.elbowR = CGPoint(x: 18, y: 4); p.handR = CGPoint(x: 26, y: 10)
            p.kneeL = CGPoint(x: 12, y: 16); p.footL = CGPoint(x: 10, y: 34)
            p.kneeR = CGPoint(x: -8, y: 20); p.footR = CGPoint(x: -18, y: 36)
        }, .powerIn), // los dos caen
        K7(0.80, P7 { p in
            p.hipHeight = 30; p.squash = 0.93; p.neckOff = CGPoint(x: 18, y: -18); p.headOff = CGPoint(x: 6, y: -10)
            p.elbowL = CGPoint(x: 16, y: 10); p.handL = CGPoint(x: 24, y: 20)
            p.elbowR = CGPoint(x: 19, y: 6); p.handR = CGPoint(x: 28, y: 14)
            p.kneeL = CGPoint(x: 10, y: 12); p.footL = CGPoint(x: 8, y: 28)
            p.kneeR = CGPoint(x: -6, y: 12); p.footR = CGPoint(x: -14, y: 26)
        }, .easeOut),
        K7(1.1, P7 { p in // encima del derribado: manos apoyadas, una rodilla abajo
            p.hipHeight = 18; p.squash = 0.95; p.neckOff = CGPoint(x: 25, y: -9); p.headOff = CGPoint(x: 9, y: -6)
            p.elbowL = CGPoint(x: 18, y: 6); p.handL = CGPoint(x: 27, y: 17)
            p.elbowR = CGPoint(x: 20, y: 3); p.handR = CGPoint(x: 30, y: 12)
            p.kneeL = CGPoint(x: 6, y: 6); p.footL = CGPoint(x: 2, y: 16)
            p.kneeR = CGPoint(x: -8, y: 5); p.footR = CGPoint(x: -18, y: 14)
        })
    ])

    // ============================================================
    // MARK: Interaccion y mundo (AvA 1 y AvA 4)
    // ============================================================

    // -- Arrebatar una herramienta (AvA 1: le roba el lapiz/goma al
    // animador de un zarpazo y se lo queda mirandolo). Zarpazo seco
    // tras una carga corta, micro-tiron de "ya es mio" y reculada al
    // pecho. Encadena bien con drawWithPencil/eraseRub (la vista
    // dibuja la herramienta en la mano, como ya hace con el lapiz).
    static let snatchTool = AnimationClip(name: "arrebatar", duration: 1.0, loops: false, keyframes: [
        K7(0.0, P7 { p in // de pie, aun no ha visto nada
            p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 4, y: -22)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: -20, y: 40)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: 20, y: 40)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .easeInOut), // ¡lo ha visto! la cabeza se clava en el objetivo
        K7(0.25, P7 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: 7, y: -21)
            p.elbowL = CGPoint(x: -17, y: 19); p.handL = CGPoint(x: -20, y: 39)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: 20, y: 39)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeIn), // carga el zarpazo: brazo atras, peso atras
        K7(0.42, P7 { p in
            p.hipHeight = 48; p.squash = 0.93; p.hipDX = -3; p.neckOff = CGPoint(x: -3, y: -38); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -2, y: 16); p.handL = CGPoint(x: 10, y: 16)
            p.elbowR = CGPoint(x: -12, y: 16); p.handR = CGPoint(x: -14, y: 20)
            p.kneeL = CGPoint(x: -11, y: 24); p.footL = CGPoint(x: -17, y: 48)
            p.kneeR = CGPoint(x: 10, y: 24); p.footR = CGPoint(x: 15, y: 48)
        }, .snappy), // ¡ZARPAZO! se lanza entero a por la herramienta
        K7(0.52, P7 { p in // extension total, la mano se cierra sobre el objetivo
            p.hipHeight = 51; p.squash = 1.04; p.hipDX = 7; p.neckOff = CGPoint(x: 13, y: -38); p.headOff = CGPoint(x: 5, y: -20)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -16, y: 18)
            p.elbowR = CGPoint(x: 31, y: 5); p.handR = CGPoint(x: 55, y: 6)
            p.kneeL = CGPoint(x: -14, y: 26); p.footL = CGPoint(x: -25, y: 50)
            p.kneeR = CGPoint(x: 16, y: 26); p.footR = CGPoint(x: 28, y: 51)
        }, .easeInOut), // lo tiene: micro-tiron de "ya es mio"
        K7(0.62, P7 { p in
            p.hipHeight = 51; p.squash = 1.03; p.hipDX = 6; p.neckOff = CGPoint(x: 12, y: -38); p.headOff = CGPoint(x: 5, y: -20)
            p.elbowL = CGPoint(x: -12, y: 14); p.handL = CGPoint(x: -16, y: 18)
            p.elbowR = CGPoint(x: 29, y: 6); p.handR = CGPoint(x: 52, y: 7)
            p.kneeL = CGPoint(x: -14, y: 26); p.footL = CGPoint(x: -25, y: 50)
            p.kneeR = CGPoint(x: 16, y: 26); p.footR = CGPoint(x: 28, y: 51)
        }, .easeIn), // tira y se lo trae al pecho, reculando
        K7(0.80, P7 { p in
            p.hipHeight = 52; p.squash = 0.98; p.hipDX = -2; p.neckOff = CGPoint(x: 2, y: -39); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: -13, y: 15); p.handL = CGPoint(x: -14, y: 20)
            p.elbowR = CGPoint(x: 10, y: 12); p.handR = CGPoint(x: 17, y: 15) // la herramienta, contra el pecho
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -16, y: 52)
            p.kneeR = CGPoint(x: 10, y: 26); p.footR = CGPoint(x: 17, y: 52)
        }, .easeOut),
        K7(1.0, P7 { p in // lo mira triunfante, subiendolo un poco para verlo
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 4, y: -19)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -18, y: 34)
            p.elbowR = CGPoint(x: 12, y: 8); p.handR = CGPoint(x: 19, y: 10)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        })
    ])

    // -- Lanzar un objeto pesado con las DOS manos por encima de la
    // cabeza (AvA 2: TCO lanza ventanas y trozos de interfaz). Carga
    // echandose atras con el objeto en alto, latigazo de todo el
    // cuerpo al soltar y follow-through con la mirada siguiendo el
    // vuelo. El objeto lo dibuja la vista hasta el keyframe de
    // suelta (0.58), como hace con la pelota de playBall.
    static let throwOverhead = AnimationClip(name: "lanzar-objeto", duration: 1.3, loops: false, keyframes: [
        K7(0.0, P7 { p in // objeto sobre la cabeza, agarrado con las dos manos
            p.hipHeight = 53; p.squash = 0.99; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -15, y: -14); p.handL = CGPoint(x: -11, y: -38)
            p.elbowR = CGPoint(x: 15, y: -14); p.handR = CGPoint(x: 11, y: -38)
            p.kneeL = CGPoint(x: -10, y: 26); p.footL = CGPoint(x: -15, y: 53)
            p.kneeR = CGPoint(x: 10, y: 26); p.footR = CGPoint(x: 15, y: 53)
        }, .easeIn), // carga echandose atras, el objeto pesa
        K7(0.30, P7 { p in
            p.hipHeight = 47; p.squash = 0.91; p.hipDX = -3; p.neckOff = CGPoint(x: -7, y: -37); p.headOff = CGPoint(x: -4, y: -21)
            p.elbowL = CGPoint(x: -16, y: -16); p.handL = CGPoint(x: -13, y: -42)
            p.elbowR = CGPoint(x: 13, y: -17); p.handR = CGPoint(x: 9, y: -43)
            p.kneeL = CGPoint(x: -12, y: 21); p.footL = CGPoint(x: -18, y: 47)
            p.kneeR = CGPoint(x: 11, y: 21); p.footR = CGPoint(x: 16, y: 47)
        }, .easeIn), // aguanta la carga un instante (tension)
        K7(0.45, P7 { p in
            p.hipHeight = 46; p.squash = 0.90; p.hipDX = -4; p.neckOff = CGPoint(x: -8, y: -36); p.headOff = CGPoint(x: -5, y: -20)
            p.elbowL = CGPoint(x: -16, y: -16); p.handL = CGPoint(x: -14, y: -42)
            p.elbowR = CGPoint(x: 13, y: -17); p.handR = CGPoint(x: 8, y: -43)
            p.kneeL = CGPoint(x: -12, y: 20); p.footL = CGPoint(x: -18, y: 46)
            p.kneeR = CGPoint(x: 11, y: 20); p.footR = CGPoint(x: 16, y: 46)
        }, .snappy), // ¡LANZA! latigazo de todo el cuerpo hacia delante
        K7(0.58, P7 { p in // suelta: brazos barriendo hacia delante-arriba, paso largo
            p.hipHeight = 55; p.squash = 1.05; p.hipDX = 5; p.neckOff = CGPoint(x: 13, y: -37); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: 14, y: -4); p.handL = CGPoint(x: 24, y: -16)
            p.elbowR = CGPoint(x: 18, y: -8); p.handR = CGPoint(x: 29, y: -20)
            p.kneeL = CGPoint(x: -14, y: 22); p.footL = CGPoint(x: -24, y: 44) // trasera de puntillas
            p.kneeR = CGPoint(x: 14, y: 28); p.footR = CGPoint(x: 20, y: 55)  // delantera plantada
        }, .easeOut), // follow-through: los brazos siguen y caen
        K7(0.75, P7 { p in
            p.hipHeight = 53; p.hipDX = 4; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: 16, y: 6); p.handL = CGPoint(x: 28, y: 4)
            p.elbowR = CGPoint(x: 20, y: 2); p.handR = CGPoint(x: 33, y: 0)
            p.kneeL = CGPoint(x: -12, y: 25); p.footL = CGPoint(x: -20, y: 50)
            p.kneeR = CGPoint(x: 12, y: 27); p.footR = CGPoint(x: 18, y: 53)
        }, .easeInOut), // se recoge mirando el vuelo del objeto
        K7(1.0, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 4, y: -41); p.headOff = CGPoint(x: 3, y: -23)
            p.elbowL = CGPoint(x: -13, y: 16); p.handL = CGPoint(x: -14, y: 26)
            p.elbowR = CGPoint(x: 12, y: 13); p.handR = CGPoint(x: 20, y: 16)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -14, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 14, y: 55)
        }, .backOut),
        K7(1.3, P7 { p in // de pie, mirada alta: aun lo sigue con los ojos
            p.hipHeight = 56; p.neckOff = CGPoint(x: 1, y: -42); p.headOff = CGPoint(x: 2, y: -24)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 38)
            p.elbowR = CGPoint(x: 14, y: 16); p.handR = CGPoint(x: 18, y: 30)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        })
    ])

    // -- Teclear frenetico (AvA 4: se pone a aporrear el teclado / la
    // pantalla cuando "hackea" o trabaja). De pie inclinado sobre el
    // teclado invisible, las dos manos alternando GOLPES cortos a
    // ritmo de ametralladora (tramos lineales, como los temblores de
    // la v6: el ritmo lo hace la alternancia, no el easing), la
    // cabeza clavada en la pantalla y una micro-pausa por ciclo en
    // la que levanta la vista a releer. El teclado lo aporta la zona
    // del mundo; sin prop el gesto se lee igual.
    static let typeFrenzy = AnimationClip(name: "teclear", duration: 1.2, loops: true, keyframes: [
        K7(0.0, P7 { p in // inclinado sobre el teclado, mano izquierda abajo
            p.hipHeight = 54; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 5, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 36)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 30)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear), // golpe derecho
        K7(0.12, P7 { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 5, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 30)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 36)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear), // golpe izquierdo, el cuerpo se va inclinando
        K7(0.25, P7 { p in
            p.hipHeight = 54; p.hipDX = 1; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 36)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 30)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear),
        K7(0.36, P7 { p in
            p.hipHeight = 54; p.hipDX = 1; p.neckOff = CGPoint(x: 10, y: -38); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 30)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 36)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear),
        K7(0.49, P7 { p in // mas inclinado, a tope
            p.hipHeight = 54; p.squash = 0.99; p.hipDX = 1; p.neckOff = CGPoint(x: 11, y: -37); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 36)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 30)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear),
        K7(0.60, P7 { p in
            p.hipHeight = 54; p.squash = 0.99; p.hipDX = 1; p.neckOff = CGPoint(x: 11, y: -37); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 30)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 36)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear),
        K7(0.73, P7 { p in
            p.hipHeight = 54; p.hipDX = 1; p.neckOff = CGPoint(x: 11, y: -37); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 36)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 30)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .linear),
        K7(0.84, P7 { p in
            p.hipHeight = 54; p.hipDX = 1; p.neckOff = CGPoint(x: 11, y: -37); p.headOff = CGPoint(x: 6, y: -18)
            p.elbowL = CGPoint(x: 4, y: 20); p.handL = CGPoint(x: 15, y: 30)
            p.elbowR = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 25, y: 36)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 54)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 54)
        }, .easeInOut), // micro-pausa: levanta la vista a releer lo escrito
        K7(0.95, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: 3, y: 20); p.handL = CGPoint(x: 13, y: 33)
            p.elbowR = CGPoint(x: 13, y: 20); p.handR = CGPoint(x: 23, y: 33)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 16, y: 55)
        }, .easeInOut) // y vuelve a aporrear (cierre del ciclo)
    ])

    // -- Empujar un objeto pesado (AvA 2/4: empuja ventanas y bloques
    // de interfaz con todo el cuerpo). Distinto de strengthPose, que
    // es SOSTENER peso encima: aqui el empuje es horizontal, el
    // cuerpo va en diagonal, las piernas mandan, el pie RESBALA una
    // vez por ciclo y se re-planta. El objeto lo pone el mundo; las
    // manos van a la altura del pecho contra su "pared".
    static let pushHeavy = AnimationClip(name: "empujar-pesado", duration: 1.6, loops: true, keyframes: [
        K7(0.0, P7 { p in // apoyado en diagonal, empujando
            p.hipHeight = 49; p.squash = 0.97; p.neckOff = CGPoint(x: 16, y: -34); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: 17, y: 8); p.handL = CGPoint(x: 29, y: 4)
            p.elbowR = CGPoint(x: 19, y: 13); p.handR = CGPoint(x: 31, y: 11)
            p.kneeL = CGPoint(x: 15, y: 25); p.footL = CGPoint(x: 4, y: 49)
            p.kneeR = CGPoint(x: -15, y: 22); p.footR = CGPoint(x: -27, y: 42)
        }, .easeIn), // empuja mas: las piernas mandan y el cuerpo se hunde
        K7(0.40, P7 { p in
            p.hipHeight = 47; p.squash = 0.94; p.hipDX = 2; p.neckOff = CGPoint(x: 18, y: -32); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: 17, y: 8); p.handL = CGPoint(x: 30, y: 5)
            p.elbowR = CGPoint(x: 19, y: 13); p.handR = CGPoint(x: 32, y: 12)
            p.kneeL = CGPoint(x: 16, y: 23); p.footL = CGPoint(x: 2, y: 47)
            p.kneeR = CGPoint(x: -16, y: 20); p.footR = CGPoint(x: -29, y: 40)
        }, .linear), // temblor de esfuerzo maximo
        K7(0.52, P7 { p in
            p.hipHeight = 47; p.squash = 0.94; p.hipDX = 2; p.neckOff = CGPoint(x: 18, y: -32); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: 17, y: 8); p.handL = CGPoint(x: 31, y: 4)
            p.elbowR = CGPoint(x: 19, y: 13); p.handR = CGPoint(x: 33, y: 11)
            p.kneeL = CGPoint(x: 16, y: 23); p.footL = CGPoint(x: 2, y: 47)
            p.kneeR = CGPoint(x: -16, y: 20); p.footR = CGPoint(x: -29, y: 40)
        }, .snappy), // ¡el pie delantero RESBALA hacia atras!
        K7(0.64, P7 { p in
            p.hipHeight = 45; p.squash = 0.92; p.hipDX = -2; p.neckOff = CGPoint(x: 19, y: -30); p.headOff = CGPoint(x: 8, y: -15)
            p.elbowL = CGPoint(x: 15, y: 11); p.handL = CGPoint(x: 27, y: 8)
            p.elbowR = CGPoint(x: 17, y: 16); p.handR = CGPoint(x: 29, y: 15)
            p.kneeL = CGPoint(x: 10, y: 22); p.footL = CGPoint(x: -6, y: 45)
            p.kneeR = CGPoint(x: -16, y: 18); p.footR = CGPoint(x: -30, y: 38)
        }, .easeOut), // re-planta el pie y empuja de verdad: el objeto cede
        K7(1.0, P7 { p in
            p.hipHeight = 50; p.squash = 0.99; p.hipDX = 4; p.neckOff = CGPoint(x: 17, y: -33); p.headOff = CGPoint(x: 6, y: -17)
            p.elbowL = CGPoint(x: 17, y: 8); p.handL = CGPoint(x: 30, y: 4)
            p.elbowR = CGPoint(x: 19, y: 13); p.handR = CGPoint(x: 32, y: 11)
            p.kneeL = CGPoint(x: 17, y: 26); p.footL = CGPoint(x: 8, y: 50)
            p.kneeR = CGPoint(x: -13, y: 23); p.footR = CGPoint(x: -24, y: 44)
        }, .easeInOut), // respira apoyado en el objeto antes de seguir
        K7(1.3, P7 { p in
            p.hipHeight = 51; p.hipDX = 3; p.neckOff = CGPoint(x: 15, y: -35); p.headOff = CGPoint(x: 5, y: -18)
            p.elbowL = CGPoint(x: 17, y: 8); p.handL = CGPoint(x: 29, y: 5)
            p.elbowR = CGPoint(x: 19, y: 13); p.handR = CGPoint(x: 31, y: 12)
            p.kneeL = CGPoint(x: 16, y: 26); p.footL = CGPoint(x: 6, y: 51)
            p.kneeR = CGPoint(x: -14, y: 23); p.footR = CGPoint(x: -25, y: 45)
        }, .easeInOut)
    ])

    // -- Asomarse a una esquina (AvA 4: avanza con cautela y espia).
    // Distinto de hide (agazapado TRAS un objeto, cadera a 30): aqui
    // va DE PIE, pegado a una esquina invisible a su derecha, con las
    // dos manos en el borde; solo la cabeza y un poco de torso pasan
    // la esquina. El ciclo tiene la cautela dentro: asomada lenta,
    // mirada hacia abajo, escondida SECA cuando "oye algo", espera
    // contenida y segunda asomada a medias antes de retirarse.
    static let peekCorner = AnimationClip(name: "asomarse", duration: 2.6, loops: true, keyframes: [
        K7(0.0, P7 { p in // escondido: solo las manos en el borde delatan que hay alguien
            p.hipHeight = 56; p.hipDX = -3; p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: -3, y: -22)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 23, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 25, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 56)
            p.kneeR = CGPoint(x: -4, y: 27); p.footR = CGPoint(x: -5, y: 56)
        }, .easeInOut), // se asoma despacio, estirando el cuello
        K7(0.70, P7 { p in // asomado: cabeza y hombros ya pasaron la esquina
            p.hipHeight = 56; p.hipDX = -2; p.neckOff = CGPoint(x: 13, y: -39); p.headOff = CGPoint(x: 11, y: -21)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 24, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 26, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -16, y: 56)
            p.kneeR = CGPoint(x: -1, y: 27); p.footR = CGPoint(x: -2, y: 56)
        }, .easeInOut), // aguanta y mira hacia abajo
        K7(1.10, P7 { p in
            p.hipHeight = 56; p.hipDX = -2; p.neckOff = CGPoint(x: 13, y: -38); p.headOff = CGPoint(x: 12, y: -18)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 24, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 26, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -16, y: 56)
            p.kneeR = CGPoint(x: -1, y: 27); p.footR = CGPoint(x: -2, y: 56)
        }, .snappy), // ha oido algo: se esconde DE GOLPE
        K7(1.45, P7 { p in
            p.hipHeight = 56; p.hipDX = -4; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: -4, y: -21)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 23, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 25, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 56)
            p.kneeR = CGPoint(x: -4, y: 27); p.footR = CGPoint(x: -5, y: 56)
        }, .easeInOut), // quieto, conteniendo la respiracion
        K7(1.95, P7 { p in
            p.hipHeight = 56; p.hipDX = -3; p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: -3, y: -22)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 23, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 25, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 56)
            p.kneeR = CGPoint(x: -4, y: 27); p.footR = CGPoint(x: -5, y: 56)
        }, .easeInOut), // segunda asomada, solo a medias
        K7(2.30, P7 { p in
            p.hipHeight = 56; p.hipDX = -3; p.neckOff = CGPoint(x: 8, y: -40); p.headOff = CGPoint(x: 5, y: -21)
            p.elbowL = CGPoint(x: 16, y: 16); p.handL = CGPoint(x: 23, y: 27)
            p.elbowR = CGPoint(x: 17, y: 8); p.handR = CGPoint(x: 25, y: 5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -15, y: 56)
            p.kneeR = CGPoint(x: -4, y: 27); p.footR = CGPoint(x: -5, y: 56)
        }, .easeInOut) // y se retira del todo (cierre del ciclo)
    ])

    // -- Arrastrarse a cuatro patas (AvA 1/4: avanza pegado al suelo
    // tras un golpe o para pasar bajo algo). No habia NADA a cuatro
    // patas en la libreria (sprawl/sleep son tumbado quieto, getUp
    // es levantarse). Ciclo de gateo de comando: mano derecha +
    // rodilla izquierda, paso intermedio con la cadera baja, mano
    // izquierda + rodilla derecha. La cabeza va alta, mirando al
    // frente: no huye, AVANZA.
    static let crawl = AnimationClip(name: "arrastrarse", duration: 1.1, loops: true, keyframes: [
        K7(0.0, P7 { p in // pareja A: mano derecha y rodilla izquierda adelantadas
            p.hipHeight = 27; p.squash = 0.99; p.hipDX = 1; p.neckOff = CGPoint(x: 22, y: -17); p.headOff = CGPoint(x: 13, y: -8)
            p.elbowL = CGPoint(x: 0, y: 21); p.handL = CGPoint(x: 2, y: 42)
            p.elbowR = CGPoint(x: 17, y: 19); p.handR = CGPoint(x: 25, y: 40)
            p.kneeL = CGPoint(x: -7, y: 17); p.footL = CGPoint(x: -23, y: 23)
            p.kneeR = CGPoint(x: -16, y: 15); p.footR = CGPoint(x: -31, y: 20)
        }, .easeInOut), // paso intermedio: la cadera baja un pelo al pasar el peso
        K7(0.27, P7 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 22, y: -16); p.headOff = CGPoint(x: 13, y: -8)
            p.elbowL = CGPoint(x: 8, y: 21); p.handL = CGPoint(x: 13, y: 42)
            p.elbowR = CGPoint(x: 10, y: 20); p.handR = CGPoint(x: 14, y: 41)
            p.kneeL = CGPoint(x: -12, y: 16); p.footL = CGPoint(x: -27, y: 22)
            p.kneeR = CGPoint(x: -11, y: 16); p.footR = CGPoint(x: -26, y: 21)
        }, .easeInOut), // pareja B: mano izquierda y rodilla derecha adelantadas
        K7(0.55, P7 { p in
            p.hipHeight = 27; p.squash = 0.99; p.hipDX = 1; p.neckOff = CGPoint(x: 22, y: -17); p.headOff = CGPoint(x: 14, y: -8)
            p.elbowL = CGPoint(x: 17, y: 19); p.handL = CGPoint(x: 25, y: 40)
            p.elbowR = CGPoint(x: 0, y: 21); p.handR = CGPoint(x: 2, y: 42)
            p.kneeL = CGPoint(x: -16, y: 15); p.footL = CGPoint(x: -31, y: 20)
            p.kneeR = CGPoint(x: -7, y: 17); p.footR = CGPoint(x: -23, y: 23)
        }, .easeInOut), // intermedio espejo
        K7(0.82, P7 { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 22, y: -16); p.headOff = CGPoint(x: 13, y: -7)
            p.elbowL = CGPoint(x: 10, y: 20); p.handL = CGPoint(x: 14, y: 41)
            p.elbowR = CGPoint(x: 8, y: 21); p.handR = CGPoint(x: 13, y: 42)
            p.kneeL = CGPoint(x: -11, y: 16); p.footL = CGPoint(x: -26, y: 21)
            p.kneeR = CGPoint(x: -12, y: 16); p.footR = CGPoint(x: -27, y: 22)
        }, .easeInOut)
    ])

    // -- Columpiarse de un cable (AvA 1/4: se agarra a lo que cuelga
    // y se balancea ganando arco). Distinto de hangCeil/hangWall,
    // que son pendulos PASIVOS de poca amplitud: aqui las dos manos
    // van al MISMO punto de agarre, el arco es grande y en cada
    // extremo hay BOMBEO de piernas (las echa hacia donde va el
    // columpio) y en el centro las extiende para ganar velocidad.
    // La caida al centro va con powerIn, como mandan los videos.
    static let swingRope = AnimationClip(name: "columpiarse", duration: 2.8, loops: true, keyframes: [
        K7(0.0, P7 { p in // extremo trasero: piernas arrastrando detras
            p.hipHeight = 56; p.hipDX = -5; p.neckOff = CGPoint(x: -6, y: -40); p.headOff = CGPoint(x: -3, y: -21)
            p.elbowL = CGPoint(x: -7, y: -26); p.handL = CGPoint(x: -4, y: -53)
            p.elbowR = CGPoint(x: 7, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -14, y: 24); p.footL = CGPoint(x: -25, y: 40)
            p.kneeR = CGPoint(x: -11, y: 26); p.footR = CGPoint(x: -21, y: 45)
        }, .powerIn), // cae hacia el centro ganando velocidad
        K7(0.70, P7 { p in // centro: piernas extendidas bombeando hacia delante
            p.hipHeight = 59; p.squash = 1.03; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -7, y: -26); p.handL = CGPoint(x: -4, y: -53)
            p.elbowR = CGPoint(x: 7, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: -2, y: 30); p.footL = CGPoint(x: 0, y: 50)
            p.kneeR = CGPoint(x: 3, y: 30); p.footR = CGPoint(x: 5, y: 52)
        }, .easeOut), // sube al extremo delantero frenando
        K7(1.40, P7 { p in // extremo delantero: patada de bombeo en lo alto
            p.hipHeight = 56; p.hipDX = 5; p.neckOff = CGPoint(x: 6, y: -40); p.headOff = CGPoint(x: 3, y: -21)
            p.elbowL = CGPoint(x: -7, y: -26); p.handL = CGPoint(x: -4, y: -53)
            p.elbowR = CGPoint(x: 7, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: 12, y: 20); p.footL = CGPoint(x: 23, y: 32)
            p.kneeR = CGPoint(x: 15, y: 23); p.footR = CGPoint(x: 27, y: 38)
        }, .powerIn), // vuelve a caer al centro
        K7(2.10, P7 { p in // centro de vuelta: bombeo espejo
            p.hipHeight = 59; p.squash = 1.03; p.neckOff = CGPoint(x: 0, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -7, y: -26); p.handL = CGPoint(x: -4, y: -53)
            p.elbowR = CGPoint(x: 7, y: -26); p.handR = CGPoint(x: 4, y: -53)
            p.kneeL = CGPoint(x: 2, y: 30); p.footL = CGPoint(x: 4, y: 52)
            p.kneeR = CGPoint(x: -3, y: 30); p.footR = CGPoint(x: -1, y: 50)
        }, .easeOut) // y sube al extremo trasero (cierre del ciclo)
    ])

    // ============================================================
    // MARK: Vida — cuerpo y gestos (rellenar los huecos de "estar vivo")
    // ============================================================

    // -- Meditar levitando: piernas cruzadas, mudra en el regazo y
    // una levitacion LENTA que sube y baja con la respiracion (no es
    // un vaiven: cada fase se aguanta mas de un segundo, como el
    // cambio de peso del idle v6). Una respiracion profunda por
    // ciclo, con la cabeza inclinada y las manos subiendo al pecho.
    // El gesto de calma "zen" de los momentos tranquilos de AvA 4.
    static let meditate = AnimationClip(name: "meditar", duration: 4.6, loops: true, keyframes: [
        K7(0.0, P7 { p in // cruzado, flotando bajo, manos en el regazo
            p.hipHeight = 59; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -19, y: 19); p.handL = CGPoint(x: -4, y: 36)
            p.elbowR = CGPoint(x: 19, y: 19); p.handR = CGPoint(x: 4, y: 36)
            p.kneeL = CGPoint(x: -16, y: 29); p.footL = CGPoint(x: 14, y: 35)  // pie izquierdo cruzado a la derecha
            p.kneeR = CGPoint(x: 16, y: 28); p.footR = CGPoint(x: -13, y: 33)
        }, .easeInOut), // inspira: sube flotando
        K7(1.15, P7 { p in
            p.hipHeight = 61; p.squash = 1.012; p.neckOff = CGPoint(x: 0, y: -44); p.headOff = CGPoint(x: 0, y: -24)
            p.elbowL = CGPoint(x: -19, y: 19); p.handL = CGPoint(x: -4, y: 35)
            p.elbowR = CGPoint(x: 19, y: 19); p.handR = CGPoint(x: 4, y: 35)
            p.kneeL = CGPoint(x: -16, y: 29); p.footL = CGPoint(x: 14, y: 35)
            p.kneeR = CGPoint(x: 16, y: 28); p.footR = CGPoint(x: -13, y: 33)
        }, .easeInOut), // espira: baja flotando y gira la cabeza un pelo
        K7(2.30, P7 { p in
            p.hipHeight = 59; p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 3, y: -23)
            p.elbowL = CGPoint(x: -19, y: 19); p.handL = CGPoint(x: -4, y: 36)
            p.elbowR = CGPoint(x: 19, y: 19); p.handR = CGPoint(x: 4, y: 36)
            p.kneeL = CGPoint(x: -16, y: 29); p.footL = CGPoint(x: 14, y: 35)
            p.kneeR = CGPoint(x: 16, y: 28); p.footR = CGPoint(x: -13, y: 33)
        }, .easeInOut), // respiracion profunda: las manos suben al pecho
        K7(3.45, P7 { p in
            p.hipHeight = 60; p.squash = 1.015; p.neckOff = CGPoint(x: 1, y: -42); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -18, y: 17); p.handL = CGPoint(x: -3, y: 31)
            p.elbowR = CGPoint(x: 18, y: 17); p.handR = CGPoint(x: 3, y: 31)
            p.kneeL = CGPoint(x: -16, y: 29); p.footL = CGPoint(x: 14, y: 35)
            p.kneeR = CGPoint(x: 16, y: 28); p.footR = CGPoint(x: -13, y: 33)
        }, .easeInOut) // y vuelve al centro (cierre del ciclo)
    ])

    // -- Flexiones: plancha completa a una repeticion por ciclo. La
    // bajada la manda la gravedad (easeIn, 0.55 s), abajo se aguanta
    // con temblor (como los holds de esfuerzo de strengthPose) y la
    // subida es el empuje (snappy al salir, easeOut al llegar). El
    // motor puede contar repeticiones si lo usa como "ejercicio".
    static let pushUps = AnimationClip(name: "flexiones", duration: 1.5, loops: true, keyframes: [
        K7(0.0, P7 { p in // plancha alta: cuerpo recto en diagonal, brazos extendidos
            p.hipHeight = 30; p.neckOff = CGPoint(x: 30, y: -12); p.headOff = CGPoint(x: 12, y: -6)
            p.elbowL = CGPoint(x: -2, y: 20); p.handL = CGPoint(x: 2, y: 41)
            p.elbowR = CGPoint(x: 4, y: 21); p.handR = CGPoint(x: 8, y: 41)
            p.kneeL = CGPoint(x: -25, y: 11); p.footL = CGPoint(x: -45, y: 24)
            p.kneeR = CGPoint(x: -22, y: 13); p.footR = CGPoint(x: -41, y: 26)
        }, .easeIn), // baja: la gravedad manda, los codos se doblan hacia atras
        K7(0.55, P7 { p in // abajo: pecho casi en el suelo
            p.hipHeight = 22; p.squash = 0.99; p.neckOff = CGPoint(x: 28, y: -8); p.headOff = CGPoint(x: 11, y: -4)
            p.elbowL = CGPoint(x: -13, y: 7); p.handL = CGPoint(x: 2, y: 29)
            p.elbowR = CGPoint(x: -8, y: 8); p.handR = CGPoint(x: 7, y: 29)
            p.kneeL = CGPoint(x: -24, y: 10); p.footL = CGPoint(x: -44, y: 17)
            p.kneeR = CGPoint(x: -21, y: 12); p.footR = CGPoint(x: -40, y: 18)
        }, .linear), // aguanta abajo temblando
        K7(0.68, P7 { p in
            p.hipHeight = 22; p.squash = 0.99; p.neckOff = CGPoint(x: 28, y: -8); p.headOff = CGPoint(x: 11, y: -3)
            p.elbowL = CGPoint(x: -13, y: 7); p.handL = CGPoint(x: 2, y: 29)
            p.elbowR = CGPoint(x: -8, y: 8); p.handR = CGPoint(x: 7, y: 30)
            p.kneeL = CGPoint(x: -24, y: 10); p.footL = CGPoint(x: -44, y: 17)
            p.kneeR = CGPoint(x: -21, y: 12); p.footR = CGPoint(x: -40, y: 18)
        }, .snappy), // ¡empuja! de vuelta a la plancha
        K7(0.95, P7 { p in
            p.hipHeight = 30; p.squash = 1.01; p.neckOff = CGPoint(x: 30, y: -12); p.headOff = CGPoint(x: 12, y: -6)
            p.elbowL = CGPoint(x: -2, y: 20); p.handL = CGPoint(x: 2, y: 41)
            p.elbowR = CGPoint(x: 4, y: 21); p.handR = CGPoint(x: 8, y: 41)
            p.kneeL = CGPoint(x: -25, y: 11); p.footL = CGPoint(x: -45, y: 24)
            p.kneeR = CGPoint(x: -22, y: 13); p.footR = CGPoint(x: -41, y: 26)
        }, .easeInOut), // aguanta arriba y respira antes de la siguiente
        K7(1.25, P7 { p in
            p.hipHeight = 30; p.neckOff = CGPoint(x: 30, y: -13); p.headOff = CGPoint(x: 12, y: -7)
            p.elbowL = CGPoint(x: -2, y: 20); p.handL = CGPoint(x: 2, y: 41)
            p.elbowR = CGPoint(x: 4, y: 21); p.handR = CGPoint(x: 8, y: 41)
            p.kneeL = CGPoint(x: -25, y: 11); p.footL = CGPoint(x: -45, y: 24)
            p.kneeR = CGPoint(x: -22, y: 13); p.footR = CGPoint(x: -41, y: 26)
        }, .easeInOut)
    ])

    // -- Saltar a la comba: dos saltos por ciclo (el segundo un pelo
    // mas alto: en los videos ni las repeticiones son gemelas). Saltos
    // cortos con los pies juntos, aterrizaje con squash y despegue
    // con stretch; las muñecas hacen su circulito a los lados (la
    // cuerda la sugiere el movimiento, no hace falta prop: pasa
    // "por debajo" en cada apex). La caida de cada salto, con
    // powerIn como en la carrera.
    static let jumpRope = AnimationClip(name: "comba", duration: 1.05, loops: true, keyframes: [
        K7(0.0, P7 { p in // contacto: pies juntos, agachado de aterrizaje
            p.hipHeight = 53; p.squash = 0.94; p.neckOff = CGPoint(x: 2, y: -39); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -16, y: 30)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 16, y: 30)
            p.kneeL = CGPoint(x: -6, y: 24); p.footL = CGPoint(x: -5, y: 53)
            p.kneeR = CGPoint(x: 6, y: 24); p.footR = CGPoint(x: 5, y: 53)
        }, .easeOut), // despega estirandose
        K7(0.10, P7 { p in
            p.hipHeight = 58; p.squash = 1.04; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -17, y: 28)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 17, y: 28)
            p.kneeL = CGPoint(x: -5, y: 26); p.footL = CGPoint(x: -5, y: 44)
            p.kneeR = CGPoint(x: 5, y: 26); p.footR = CGPoint(x: 5, y: 44)
        }, .easeInOut), // apex: la cuerda pasa por debajo
        K7(0.26, P7 { p in
            p.hipHeight = 62; p.squash = 1.02; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -16, y: 31)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 16, y: 31)
            p.kneeL = CGPoint(x: -6, y: 21); p.footL = CGPoint(x: -5, y: 35)
            p.kneeR = CGPoint(x: 6, y: 21); p.footR = CGPoint(x: 5, y: 35)
        }, .powerIn), // cae acelerando
        K7(0.40, P7 { p in
            p.hipHeight = 57; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -17, y: 29)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 17, y: 29)
            p.kneeL = CGPoint(x: -6, y: 25); p.footL = CGPoint(x: -5, y: 49)
            p.kneeR = CGPoint(x: 6, y: 25); p.footR = CGPoint(x: 5, y: 49)
        }, .easeInOut), // contacto 2 (= pose inicial)
        K7(0.52, P7 { p in
            p.hipHeight = 53; p.squash = 0.94; p.neckOff = CGPoint(x: 2, y: -39); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -16, y: 30)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 16, y: 30)
            p.kneeL = CGPoint(x: -6, y: 24); p.footL = CGPoint(x: -5, y: 53)
            p.kneeR = CGPoint(x: 6, y: 24); p.footR = CGPoint(x: 5, y: 53)
        }, .easeOut), // despegue 2
        K7(0.62, P7 { p in
            p.hipHeight = 59; p.squash = 1.05; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -17, y: 28)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 17, y: 28)
            p.kneeL = CGPoint(x: -5, y: 26); p.footL = CGPoint(x: -5, y: 43)
            p.kneeR = CGPoint(x: 5, y: 26); p.footR = CGPoint(x: 5, y: 43)
        }, .easeInOut), // apex 2: un pelo mas alto que el primero
        K7(0.78, P7 { p in
            p.hipHeight = 63; p.squash = 1.02; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -16, y: 31)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 16, y: 31)
            p.kneeL = CGPoint(x: -6, y: 20); p.footL = CGPoint(x: -5, y: 34)
            p.kneeR = CGPoint(x: 6, y: 20); p.footR = CGPoint(x: 5, y: 34)
        }, .powerIn),
        K7(0.92, P7 { p in
            p.hipHeight = 57; p.neckOff = CGPoint(x: 1, y: -40); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -17, y: 15); p.handL = CGPoint(x: -17, y: 29)
            p.elbowR = CGPoint(x: 17, y: 15); p.handR = CGPoint(x: 17, y: 29)
            p.kneeL = CGPoint(x: -6, y: 25); p.footL = CGPoint(x: -5, y: 49)
            p.kneeR = CGPoint(x: 6, y: 25); p.footR = CGPoint(x: 5, y: 49)
        }, .easeInOut) // al contacto (cierre del ciclo)
    ])

    // -- Comer algo dibujado (AvA 4: se dibuja comida y se la come).
    // El ciclo completo de "vida": mirar la comida, mordisco con
    // hold, masticar con bobs cortos de cabeza/cuello (el unico
    // sitio donde un micro-movimiento repetido ES la accion), trago
    // con la cabeza atras y frotarse la tripa satisfecho, dos veces
    // por ciclo (el segundo mordisco mas pequeno). El alimento lo
    // dibuja la vista en la mano derecha, como el lapiz.
    static let eatSnack = AnimationClip(name: "comer", duration: 3.4, loops: true, keyframes: [
        K7(0.0, P7 { p in // mira la comida que tiene en la mano, valorandola
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 3, y: -22)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 11, y: 10); p.handR = CGPoint(x: 16, y: 9)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // la sube a la boca
        K7(0.50, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 3, y: -40); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 1); p.handR = CGPoint(x: 8, y: -13)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // ¡ÑAM! aguanta el mordisco
        K7(0.75, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 3, y: -40); p.headOff = CGPoint(x: 5, y: -19)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 1); p.handR = CGPoint(x: 8, y: -12)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // mastica: bobs cortos
        K7(1.05, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 4); p.handR = CGPoint(x: 10, y: -5)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut),
        K7(1.35, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 3, y: -20)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 6); p.handR = CGPoint(x: 11, y: -2)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // traga: cabeza atras, la mano baja
        K7(1.65, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: -2, y: -25)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 11, y: 10); p.handR = CGPoint(x: 15, y: 10)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // satisfecho: se frota la tripa (dos pasadas)
        K7(2.05, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -8, y: 20); p.handL = CGPoint(x: 0, y: 30)
            p.elbowR = CGPoint(x: 11, y: 10); p.handR = CGPoint(x: 16, y: 10)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut),
        K7(2.35, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -8, y: 21); p.handL = CGPoint(x: 1, y: 32)
            p.elbowR = CGPoint(x: 11, y: 10); p.handR = CGPoint(x: 16, y: 10)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // segundo mordisco, mas pequeno
        K7(2.75, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 3, y: -40); p.headOff = CGPoint(x: 4, y: -20)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 2); p.handR = CGPoint(x: 9, y: -11)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // mastica una vez y baja la mano
        K7(3.05, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 4, y: -21)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 14, y: 5); p.handR = CGPoint(x: 11, y: -3)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut) // a mirar la comida otra vez (cierre del ciclo)
    ])

    // -- Beber de un vaso dibujado: lo sube, inclina la cabeza atras
    // y da dos tragos (bobs de garganta), baja el vaso, se limpia la
    // boca con el dorso de la mano y suelta el "ahh" con la mano al
    // pecho. One-shot: beber es un gesto con final, no un bucle.
    static let drinkSip = AnimationClip(name: "beber", duration: 1.8, loops: false, keyframes: [
        K7(0.0, P7 { p in // vaso en la mano, abajo
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 2, y: -22)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 36)
            p.elbowR = CGPoint(x: 10, y: 13); p.handR = CGPoint(x: 14, y: 17)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // lo sube a la boca y empieza a inclinar la cabeza
        K7(0.40, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: -2, y: -24)
            p.elbowL = CGPoint(x: -15, y: 14); p.handL = CGPoint(x: -19, y: 26) // mano a la cadera
            p.elbowR = CGPoint(x: 15, y: -3); p.handR = CGPoint(x: 7, y: -16)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // bebiendo: cabeza atras del todo, trago 1
        K7(0.80, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: -2, y: -43); p.headOff = CGPoint(x: -6, y: -26)
            p.elbowL = CGPoint(x: -15, y: 14); p.handL = CGPoint(x: -19, y: 26)
            p.elbowR = CGPoint(x: 15, y: -4); p.handR = CGPoint(x: 6, y: -18)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // trago 2 (bob de garganta)
        K7(1.10, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: -2, y: -43); p.headOff = CGPoint(x: -5, y: -25)
            p.elbowL = CGPoint(x: -15, y: 14); p.handL = CGPoint(x: -19, y: 26)
            p.elbowR = CGPoint(x: 15, y: -4); p.handR = CGPoint(x: 6, y: -17)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // baja el vaso y se limpia la boca con el dorso
        K7(1.35, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 34)
            p.elbowR = CGPoint(x: 17, y: -2); p.handR = CGPoint(x: 13, y: -13)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 10, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeOut), // ¡ahh! satisfecho, mano al pecho
        K7(1.55, P7 { p in
            p.hipHeight = 56; p.squash = 1.01; p.neckOff = CGPoint(x: 1, y: -42); p.headOff = CGPoint(x: 0, y: -23)
            p.elbowL = CGPoint(x: -10, y: 12); p.handL = CGPoint(x: -6, y: 10)
            p.elbowR = CGPoint(x: 10, y: 14); p.handR = CGPoint(x: 15, y: 19)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        }, .softLanding),
        K7(1.8, P7 { p in // fin: de pie, el vaso colgando relajado en la mano
            p.hipHeight = 56; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 1, y: -23)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 37)
            p.elbowR = CGPoint(x: 13, y: 17); p.handR = CGPoint(x: 17, y: 24)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 56)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 56)
        })
    ])

    // -- Estornudar: el gag clasico de cuerpo de AvA (las reacciones
    // fisicas exageradas). La gracia esta en la CONSTRUCCION: picor,
    // inspiracion que arquea todo el cuerpo hacia atras, SUSPENSE
    // tembloroso aguantado... y explosion seca que lo dobla por la
    // mitad. Sin suspense no hay estornudo: por eso dura 1.35 s para
    // un gesto de 0.1 s. Termina frotandose la nariz, aturdido.
    static let sneeze = AnimationClip(name: "estornudar", duration: 1.35, loops: false, keyframes: [
        K7(0.0, SkeletonPose.standing, .easeInOut), // algo le pica en la nariz...
        K7(0.30, P7 { p in // picor: la cabeza se echa un poco atras, la mano sube
            p.hipHeight = 55; p.neckOff = CGPoint(x: -1, y: -42); p.headOff = CGPoint(x: -2, y: -24)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 38)
            p.elbowR = CGPoint(x: 15, y: 4); p.handR = CGPoint(x: 13, y: -6)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeIn), // inspira hondo: todo el cuerpo se arquea atras
        K7(0.55, P7 { p in
            p.hipHeight = 57; p.squash = 1.04; p.neckOff = CGPoint(x: -6, y: -43); p.headOff = CGPoint(x: -5, y: -25)
            p.elbowL = CGPoint(x: -18, y: 16); p.handL = CGPoint(x: -24, y: 30)
            p.elbowR = CGPoint(x: 15, y: -2); p.handR = CGPoint(x: 10, y: -15) // mano a la cara
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -15, y: 57)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 15, y: 57)
        }, .linear), // SUSPENSE: congelado, temblando
        K7(0.72, P7 { p in
            p.hipHeight = 57; p.squash = 1.04; p.neckOff = CGPoint(x: -7, y: -43); p.headOff = CGPoint(x: -6, y: -25)
            p.elbowL = CGPoint(x: -18, y: 16); p.handL = CGPoint(x: -24, y: 30)
            p.elbowR = CGPoint(x: 15, y: -2); p.handR = CGPoint(x: 10, y: -15)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -15, y: 57)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 15, y: 57)
        }, .snappy), // ¡¡ACHIS!! se dobla por la mitad
        K7(0.86, P7 { p in
            p.hipHeight = 47; p.squash = 0.90; p.hipDX = 3; p.neckOff = CGPoint(x: 14, y: -32); p.headOff = CGPoint(x: 10, y: -14)
            p.elbowL = CGPoint(x: -17, y: 12); p.handL = CGPoint(x: -25, y: 19)
            p.elbowR = CGPoint(x: 19, y: 14); p.handR = CGPoint(x: 29, y: 23)
            p.kneeL = CGPoint(x: -11, y: 21); p.footL = CGPoint(x: -16, y: 47)
            p.kneeR = CGPoint(x: 11, y: 21); p.footR = CGPoint(x: 17, y: 47)
        }, .easeInOut), // se queda doblado un instante, aturdido
        K7(1.05, P7 { p in
            p.hipHeight = 49; p.squash = 0.95; p.neckOff = CGPoint(x: 10, y: -34); p.headOff = CGPoint(x: 7, y: -16)
            p.elbowL = CGPoint(x: -15, y: 14); p.handL = CGPoint(x: -21, y: 24)
            p.elbowR = CGPoint(x: 16, y: 14); p.handR = CGPoint(x: 24, y: 26)
            p.kneeL = CGPoint(x: -11, y: 23); p.footL = CGPoint(x: -16, y: 49)
            p.kneeR = CGPoint(x: 11, y: 23); p.footR = CGPoint(x: 16, y: 49)
        }, .easeOut), // se incorpora frotandose la nariz
        K7(1.35, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -16, y: 18); p.handL = CGPoint(x: -19, y: 37)
            p.elbowR = CGPoint(x: 14, y: -3); p.handR = CGPoint(x: 8, y: -17)
            p.kneeL = CGPoint(x: -11, y: 27); p.footL = CGPoint(x: -13, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        })
    ])

    // -- Hipo: el otro gag de cuerpo, en bucle. Dos hipos por ciclo
    // a intervalos IRREGULARES (0.88 y 1.97: el hipo no lleva
    // metronomo, como el panico de grabbed v6), cada uno un salto
    // seco de todo el cuerpo (cadera +4/+5 en 0.07-0.09 s, squash de
    // resorte, cabeza latigada hacia arriba). Entre hipo e hipo:
    // calma tensa con la mano en el pecho, y tras el segundo se
    // tapa la boca avergonzado... sin que le sirva de nada.
    static let hiccup = AnimationClip(name: "hipo", duration: 2.9, loops: true, keyframes: [
        K7(0.0, P7 { p in // calma: mano en el pecho, esperando
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -12, y: 12); p.handL = CGPoint(x: -7, y: 9)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 19, y: 38)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // espera... tension minima
        K7(0.80, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 0, y: -22)
            p.elbowL = CGPoint(x: -12, y: 12); p.handL = CGPoint(x: -7, y: 8)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 19, y: 38)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡HIP! salto seco de todo el cuerpo
        K7(0.88, P7 { p in
            p.hipHeight = 59; p.squash = 1.05; p.neckOff = CGPoint(x: 0, y: -44); p.headOff = CGPoint(x: -2, y: -25)
            p.elbowL = CGPoint(x: -15, y: 8); p.handL = CGPoint(x: -12, y: 4)
            p.elbowR = CGPoint(x: 18, y: 15); p.handR = CGPoint(x: 23, y: 32)
            p.kneeL = CGPoint(x: -10, y: 25); p.footL = CGPoint(x: -12, y: 57)
            p.kneeR = CGPoint(x: 10, y: 25); p.footR = CGPoint(x: 13, y: 57)
        }, .easeOut), // cae y se asienta
        K7(1.10, P7 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -12, y: 12); p.handL = CGPoint(x: -7, y: 9)
            p.elbowR = CGPoint(x: 16, y: 18); p.handR = CGPoint(x: 19, y: 37)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // calma... se tapa la boca por si acaso
        K7(1.85, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -22)
            p.elbowL = CGPoint(x: -12, y: 12); p.handL = CGPoint(x: -7, y: 9)
            p.elbowR = CGPoint(x: 14, y: -2); p.handR = CGPoint(x: 9, y: -15)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .snappy), // ¡HIP! mas grande: la mano no lo salva
        K7(1.97, P7 { p in
            p.hipHeight = 60; p.squash = 1.06; p.neckOff = CGPoint(x: -1, y: -44); p.headOff = CGPoint(x: -3, y: -25)
            p.elbowL = CGPoint(x: -18, y: 13); p.handL = CGPoint(x: -24, y: 22) // brazos abiertos del susto
            p.elbowR = CGPoint(x: 17, y: 2); p.handR = CGPoint(x: 16, y: -8)
            p.kneeL = CGPoint(x: -11, y: 25); p.footL = CGPoint(x: -13, y: 58)
            p.kneeR = CGPoint(x: 11, y: 25); p.footR = CGPoint(x: 14, y: 58)
        }, .easeOut), // se asienta, avergonzado, cabeza baja
        K7(2.25, P7 { p in
            p.hipHeight = 55; p.squash = 0.99; p.neckOff = CGPoint(x: 2, y: -40); p.headOff = CGPoint(x: 2, y: -20)
            p.elbowL = CGPoint(x: -14, y: 16); p.handL = CGPoint(x: -16, y: 30)
            p.elbowR = CGPoint(x: 14, y: -2); p.handR = CGPoint(x: 9, y: -14) // sigue tapandose la boca
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut), // baja la mano despacio... por ahora
        K7(2.60, P7 { p in
            p.hipHeight = 55; p.neckOff = CGPoint(x: 1, y: -41); p.headOff = CGPoint(x: 1, y: -21)
            p.elbowL = CGPoint(x: -13, y: 14); p.handL = CGPoint(x: -12, y: 24)
            p.elbowR = CGPoint(x: 13, y: 6); p.handR = CGPoint(x: 14, y: 8)
            p.kneeL = CGPoint(x: -10, y: 27); p.footL = CGPoint(x: -12, y: 55)
            p.kneeR = CGPoint(x: 11, y: 27); p.footR = CGPoint(x: 13, y: 55)
        }, .easeInOut) // a la calma inicial (cierre del ciclo)
    ])
}
