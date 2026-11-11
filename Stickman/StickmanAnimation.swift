import Foundation
import SwiftUI

// MARK: - Sistema de animacion por KEYFRAMES (v2, pase v4)
//
// Sustituye las "poses sueltas con senos" de la v1 por clips de datos:
// cada animacion es una lista de keyframes (tiempo, pose del esqueleto,
// easing hacia el siguiente keyframe) que se interpolan. Principios
// clasicos aplicados: anticipacion (agacharse antes de saltar),
// squash & stretch (aplastarse/estirarse), follow-through (los brazos
// llegan tarde), timing distinto por accion y easing en cada tramo.
//
// PASE v4 ("como en los videos", ver README): locomocion y pelea
// rehechas con estructura de animacion tradicional sobre los patrones
// de REFERENCES.md — contactos que se aguantan, golpes con
// anticipacion -> tramo seco -> pose de impacto aguantada -> recogida
// lenta, y ciclos de duracion irregular en vez de uniformes. Los clips
// rehechos llevan el comentario "v4" y el video del que sale el patron.
//
// PASE v6 (fidelidad de MOVIMIENTO, pase largo clip a clip sobre los
// mismos videos — AvA 1, AvA 2 y AvA 4; ver CHANGELOG-ANIM.md):
//  - Motor: dos easings nuevos (.powerIn, .backOut) pensados para el
//    timing de AvA: caidas que ACELERAN hasta el impacto y
//    recuperaciones con overshoot que "respira" al asentarse.
//  - Carrera de AvA 2 rehecha como sprint de dos tiempos SIMETRICOS
//    (la v4 tenia la segunda mitad comprimida y cojeaba): contacto ->
//    absorcion profunda -> impulso -> vuelo largo, con la caida al
//    siguiente contacto acelerando (powerIn).
//  - Pelea: combo reestructurado a rafaga (jab-jab-cross-patada-
//    barrido) con holds de impacto mas largos que las anticipaciones,
//    y clips NUEVOS hitReact (recibir golpe: recoil + tambaleo) y
//    getUp (levantarse del suelo con overshoot) — la v4 no tenia
//    reaccion de golpe propio ni levantada completa.
//  - Interaccion AvA 1: escapeShake reestructurado en 3 fases de
//    amplitud creciente + reseteo (antes el bucle reseteaba la
//    amplitud de golpe) y clip NUEVO escapeBurst (la rotura en si).
//  - Poderes con estructura de ataque (antes eran poses en bucle sin
//    fases): fuego y laser con carga -> descarga seca -> sosten con
//    temblor de retroceso -> recuperacion; flyDash NUEVO (rafaga de
//    supervelocidad); superPunch con vibracion de impacto.
//  - Vida: idle con cambios de peso aguantados, dangle con el patron
//    completo 8/2/5/8/2/5 de la spec, dormir con respiracion mas
//    lenta y un tic de sueno, colgarse con pendulo mas largo.
//  LIMITES DEL MOTOR (documentados, no invisibles): cada tramo se
//  interpola con UN solo easing para todos los canales, asi que el
//  "retraso" de una parte del cuerpo dentro de un mismo tramo se
//  finge con keyframes intermedios extra (ver walk v6). No hay canal
//  de rotacion global del cuerpo: la inclinacion se construye con
//  neckOff/hipDX. Los clips nuevos (hitReact, getUp, escapeBurst,
//  flyDash) quedan en la libreria listos para cablear; no se anaden
//  casos a StickmanAction porque sus switches son exhaustivos.
//
// La pose se expresa en un espacio local comodo de interpolar:
//  - hipHeight: altura de la cadera sobre el suelo/plataforma
//  - neckOff:  cuello respecto a la cadera
//  - headOff:  centro de la cabeza respecto al cuello
//  - elbow/hand: codo y mano respecto al cuello
//  - knee/foot:  rodilla y pie respecto a la cadera (dy positivo = hacia abajo)
//  - squash: escala vertical global (1 = normal, <1 aplastado, >1 estirado)

struct SkeletonPose {
    var hipHeight: CGFloat = 56
    var hipDX: CGFloat = 0
    var neckOff: CGPoint = CGPoint(x: 0, y: -42)
    var headOff: CGPoint = CGPoint(x: 0, y: -23)
    var elbowL: CGPoint = CGPoint(x: -17, y: 19)
    var handL: CGPoint = CGPoint(x: -20, y: 40)
    var elbowR: CGPoint = CGPoint(x: 17, y: 19)
    var handR: CGPoint = CGPoint(x: 20, y: 40)
    var kneeL: CGPoint = CGPoint(x: -11, y: 27)
    var footL: CGPoint = CGPoint(x: -13, y: 56)
    var kneeR: CGPoint = CGPoint(x: 11, y: 27)
    var footR: CGPoint = CGPoint(x: 13, y: 56)
    var squash: CGFloat = 1

    static let standing = SkeletonPose()

    func lerped(to other: SkeletonPose, t: CGFloat) -> SkeletonPose {
        func l(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }
        func lp(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: l(a.x, b.x), y: l(a.y, b.y)) }
        return SkeletonPose(
            hipHeight: l(hipHeight, other.hipHeight), hipDX: l(hipDX, other.hipDX),
            neckOff: lp(neckOff, other.neckOff), headOff: lp(headOff, other.headOff),
            elbowL: lp(elbowL, other.elbowL), handL: lp(handL, other.handL),
            elbowR: lp(elbowR, other.elbowR), handR: lp(handR, other.handR),
            kneeL: lp(kneeL, other.kneeL), footL: lp(footL, other.footL),
            kneeR: lp(kneeR, other.kneeR), footR: lp(footR, other.footR),
            squash: l(squash, other.squash))
    }
}

enum AnimEasing {
    case linear, easeIn, easeOut, easeInOut, snappy, softLanding
    case powerIn   // v6: easeIn cubico — acelera hasta el impacto (caidas, aterrizajes de vuelo)
    case backOut   // v6: overshoot de asentamiento — pasa un poco del objetivo y vuelve (recuperaciones)
    func apply(_ t: Double) -> Double {
        let x = min(1, max(0, t))
        switch self {
        case .linear: return x
        case .easeIn: return x * x
        case .easeOut: return 1 - (1 - x) * (1 - x)
        case .easeInOut: return x * x * (3 - 2 * x)
        case .snappy: return 1 - pow(1 - x, 3)          // llega rapido y clava
        case .softLanding: return 1 - pow(1 - x, 4)     // frena muy suave al final
        case .powerIn: return x * x * x                 // v6: la gravedad manda
        case .backOut:                                  // v6: settle con vida (curva "back" clasica)
            let c1 = 1.70158, c3 = 2.70158, u = x - 1
            return 1 + c3 * u * u * u + c1 * u * u
        }
    }
}

struct AnimKeyframe {
    var time: Double
    var pose: SkeletonPose
    var easing: AnimEasing = .easeInOut   // easing DESDE este keyframe al siguiente
}

struct AnimationClip {
    var name: String
    var duration: Double
    var loops: Bool
    var keyframes: [AnimKeyframe]

    func sample(at rawTime: Double) -> SkeletonPose {
        guard let first = keyframes.first else { return .standing }
        if keyframes.count == 1 { return first.pose }
        var t = rawTime
        if loops {
            t = rawTime.truncatingRemainder(dividingBy: duration)
            if t < 0 { t += duration }
        } else {
            t = min(max(0, rawTime), duration)
        }
        // Tramo actual
        var i = 0
        while i < keyframes.count - 1 && keyframes[i + 1].time <= t { i += 1 }
        let a = keyframes[i]
        if i == keyframes.count - 1 {
            if loops { // ultimo -> primero (cierre del ciclo)
                let span = duration - a.time
                guard span > 0.001 else { return a.pose }
                let f = a.easing.apply((t - a.time) / span)
                return a.pose.lerped(to: first.pose, t: CGFloat(f))
            }
            return a.pose
        }
        let b = keyframes[i + 1]
        let span = b.time - a.time
        guard span > 0.001 else { return b.pose }
        let f = a.easing.apply((t - a.time) / span)
        return a.pose.lerped(to: b.pose, t: CGFloat(f))
    }
}

// Constructor comodo de poses a partir de la pose de pie
private func P(_ modify: (inout SkeletonPose) -> Void) -> SkeletonPose {
    var p = SkeletonPose.standing
    modify(&p)
    return p
}
private func K(_ time: Double, _ pose: SkeletonPose, _ easing: AnimEasing = .easeInOut) -> AnimKeyframe {
    AnimKeyframe(time: time, pose: pose, easing: easing)
}

// MARK: - Catalogo completo de clips (repertorio de los videos)

enum AnimationLibrary {

    // -- Despertar (AvA1: se estira, bosteza, se frota, mira confundido) --
    static let wakeUp = AnimationClip(name: "despertar", duration: 2.8, loops: false, keyframes: [
        K(0.0, P { $0.hipHeight = 30; $0.squash = 0.82; $0.handL = CGPoint(x: -8, y: 34); $0.handR = CGPoint(x: 8, y: 34) }, .easeOut),
        K(0.5, P { $0.hipHeight = 52 }, .easeInOut),
        K(0.9, P { $0.handL = CGPoint(x: -30, y: -28); $0.handR = CGPoint(x: 30, y: -28); $0.elbowL = CGPoint(x: -24, y: -4); $0.elbowR = CGPoint(x: 24, y: -4); $0.squash = 1.07 }, .easeOut), // estirarse
        K(1.4, P { $0.handR = CGPoint(x: 12, y: -16); $0.elbowR = CGPoint(x: 16, y: 6); $0.headOff = CGPoint(x: 3, y: -21) }, .easeInOut), // bostezo: mano a la boca
        K(1.9, P { $0.handR = CGPoint(x: 14, y: -38); $0.elbowR = CGPoint(x: 18, y: -10) }, .easeInOut), // frotarse la cabeza
        K(2.3, P { $0.headOff = CGPoint(x: -7, y: -23) }, .snappy), // mira a un lado
        K(2.55, P { $0.headOff = CGPoint(x: 7, y: -23) }, .snappy), // y al otro, confundido
        K(2.8, SkeletonPose.standing)
    ])

    // -- Idle vivo v6: estar vivo SIN moverse apenas --
    // En los videos el stickman quieto no "flota en un bucle": RESPIRA
    // (sube/baja el pecho ~1 px, lento) y de vez en cuando CAMBIA EL
    // PESO de pierna con un desplazamiento que se AGUANTA segundos,
    // no un vaiven continuo. Estructura: respiracion constante de
    // fondo (clave en neckOff.y y squash 1.000<->1.012) + un cambio
    // de peso a mitad de ciclo + una mirada corta tras el cambio.
    static let idle = AnimationClip(name: "idle", duration: 4.8, loops: true, keyframes: [
        K(0.0, P { $0.neckOff.y = -41.5; $0.hipDX = -2; $0.squash = 1.0 }, .easeInOut), // peso a la izquierda, exhala
        K(1.2, P { $0.neckOff.y = -43; $0.hipDX = -2; $0.squash = 1.012; $0.handL.x = -21.5; $0.handR.x = 21.5 }, .easeInOut), // inspira (los brazos se abren un pelo con el pecho)
        K(2.3, P { $0.neckOff.y = -41.5; $0.hipDX = -2; $0.squash = 1.0 }, .easeIn), // exhala... y empieza a pasar el peso
        K(2.85, P { $0.neckOff.y = -42.5; $0.hipDX = 2.5; $0.squash = 1.008; $0.headOff.x = 1 }, .easeInOut), // peso a la derecha: se AGUANTA aqui
        K(3.9, P { $0.neckOff.y = -41.5; $0.hipDX = 2.5; $0.headOff.x = 6; $0.headOff.y = -22 }, .snappy), // mira a un lado (tarde, tras asentarse)
        K(4.45, P { $0.neckOff.y = -42; $0.hipDX = 1; $0.headOff.x = 2 }, .easeInOut) // la mirada vuelve y el peso regresa camino del cierre
    ])

    static let scratchHead = AnimationClip(name: "rascarse", duration: 1.4, loops: true, keyframes: [
        K(0.0, P { $0.handR = CGPoint(x: 15, y: -40); $0.elbowR = CGPoint(x: 19, y: -12) }, .easeInOut),
        K(0.35, P { $0.handR = CGPoint(x: 11, y: -37); $0.elbowR = CGPoint(x: 19, y: -12) }, .easeInOut),
        K(0.7, P { $0.handR = CGPoint(x: 16, y: -41); $0.elbowR = CGPoint(x: 19, y: -12) }, .easeInOut),
        K(1.05, P { $0.handR = CGPoint(x: 12, y: -38); $0.elbowR = CGPoint(x: 19, y: -12) }, .easeInOut)
    ])

    static let lookAround = AnimationClip(name: "mirar", duration: 2.2, loops: true, keyframes: [
        K(0.0, P { $0.headOff.x = 0 }, .snappy),
        K(0.7, P { $0.headOff.x = -8; $0.headOff.y = -22 }, .snappy),
        K(1.4, P { $0.headOff.x = 8; $0.headOff.y = -22 }, .snappy)
    ])

    // -- LOCOMOCION v6: caminar --
    // Sobre la v4 (contactos aguantados, timing irregular, caida real
    // al apoyar 56 -> 51.5, brazos contralaterales amplios) se anaden
    // dos cosas que se ven en AvA 1/4 y que la v4 no podia expresar:
    //  1) RETRASO DE BRAZOS: el brazo llega a su extremo ~0.07 DESPUES
    //     del contacto de la pierna contraria (follow-through real).
    //     Como el motor interpola un tramo con un solo easing, el
    //     retraso se construye con un keyframe "lag" tras cada
    //     contacto en el que las piernas ya salen y los brazos aun no.
    //  2) CABEZA EN CONTRAFASE VERTICAL: cuando la cadera baja al
    //     pasar (51.5), la cabeza queda relativamente ALTA (-23.5) y
    //     en los contactos baja con el peso (-22): el cuello absorbe.
    // Balanceo de cadera en el eje de avance: en el paso de paso el
    // cuerpo PASA sobre el pie de apoyo (hipDX +2) y en los contactos
    // se queda un pelo detras (0).
    static let walk = AnimationClip(name: "caminar", duration: 0.80, loops: true, keyframes: [
        K(0.0, P { p in // CONTACTO izquierdo: talon delante, peso cayendo
            p.neckOff = CGPoint(x: 4, y: -42); p.headOff = CGPoint(x: 1, y: -22); p.hipHeight = 54; p.hipDX = 0
            p.footL = CGPoint(x: 20, y: 54); p.kneeL = CGPoint(x: 13, y: 27)
            p.footR = CGPoint(x: -17, y: 50); p.kneeR = CGPoint(x: -7, y: 22)
            p.handL = CGPoint(x: -17, y: 41); p.elbowL = CGPoint(x: -18, y: 19)
            p.handR = CGPoint(x: 31, y: 41); p.elbowR = CGPoint(x: 18, y: 19)
        }, .easeIn),
        K(0.07, P { p in // LAG: las piernas ya salen del contacto; los brazos TODAVIA no (siguen en el extremo)
            p.neckOff = CGPoint(x: 4, y: -41.5); p.headOff = CGPoint(x: 2, y: -22.5); p.hipHeight = 52.5; p.hipDX = 1
            p.footL = CGPoint(x: 12, y: 52); p.kneeL = CGPoint(x: 10, y: 28)
            p.footR = CGPoint(x: -13, y: 45); p.kneeR = CGPoint(x: -13, y: 18)
            p.handL = CGPoint(x: -18, y: 41); p.handR = CGPoint(x: 30, y: 41)
        }, .easeOut),
        K(0.20, P { p in // PASO: punto bajo, el cuerpo pasa sobre el apoyo; brazos a mitad de balanceo
            p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: 4, y: -23.5); p.hipHeight = 51.5; p.hipDX = 2
            p.footL = CGPoint(x: 2, y: 51.5); p.kneeL = CGPoint(x: 7, y: 29)
            p.footR = CGPoint(x: -7, y: 39); p.kneeR = CGPoint(x: -19, y: 14)
            p.handL = CGPoint(x: -24, y: 42); p.handR = CGPoint(x: 20, y: 42)
        }, .easeInOut),
        K(0.27, P { p in // LAG espejo: la pierna libre ya busca el suelo; los brazos llegan tarde otra vez
            p.neckOff = CGPoint(x: 3, y: -41.5); p.headOff = CGPoint(x: 2, y: -22.5); p.hipHeight = 53; p.hipDX = 1
            p.footL = CGPoint(x: -10, y: 45); p.kneeL = CGPoint(x: -14, y: 18)
            p.footR = CGPoint(x: 13, y: 52); p.kneeR = CGPoint(x: 10, y: 28)
            p.handL = CGPoint(x: -28, y: 41); p.handR = CGPoint(x: 15, y: 41)
        }, .easeIn), // cae al contacto contrario
        K(0.40, P { p in // CONTACTO derecho (asimetria leve: zancada un pelo mas larga)
            p.neckOff = CGPoint(x: 4, y: -42); p.headOff = CGPoint(x: 1, y: -22); p.hipHeight = 54; p.hipDX = 0
            p.footL = CGPoint(x: -16, y: 50); p.kneeL = CGPoint(x: -7, y: 22)
            p.footR = CGPoint(x: 21, y: 54); p.kneeR = CGPoint(x: 14, y: 27)
            p.handL = CGPoint(x: 32, y: 41); p.elbowL = CGPoint(x: 18, y: 19)
            p.handR = CGPoint(x: -16, y: 41); p.elbowR = CGPoint(x: -18, y: 19)
        }, .easeIn),
        K(0.47, P { p in // LAG derecho
            p.neckOff = CGPoint(x: 4, y: -41.5); p.headOff = CGPoint(x: 2, y: -22.5); p.hipHeight = 52.5; p.hipDX = 1
            p.footL = CGPoint(x: -13, y: 45); p.kneeL = CGPoint(x: -13, y: 18)
            p.footR = CGPoint(x: 12, y: 52); p.kneeR = CGPoint(x: 10, y: 28)
            p.handL = CGPoint(x: 31, y: 41); p.handR = CGPoint(x: -17, y: 41)
        }, .easeOut),
        K(0.60, P { p in // PASO contrario
            p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: 4, y: -23.5); p.hipHeight = 51.5; p.hipDX = 2
            p.footL = CGPoint(x: -8, y: 39); p.kneeL = CGPoint(x: -19, y: 14)
            p.footR = CGPoint(x: 3, y: 51.5); p.kneeR = CGPoint(x: 8, y: 29)
            p.handL = CGPoint(x: 21, y: 42); p.handR = CGPoint(x: -23, y: 42)
        }, .easeInOut),
        K(0.67, P { p in // LAG final: prepara el cierre del ciclo en el contacto inicial
            p.neckOff = CGPoint(x: 3, y: -41.5); p.headOff = CGPoint(x: 2, y: -22.5); p.hipHeight = 53; p.hipDX = 1
            p.footL = CGPoint(x: 14, y: 52); p.kneeL = CGPoint(x: 10, y: 28)
            p.footR = CGPoint(x: -10, y: 45); p.kneeR = CGPoint(x: -14, y: 18)
            p.handL = CGPoint(x: 16, y: 41); p.handR = CGPoint(x: -27, y: 41)
        }, .easeIn)
    ])

    // -- LOCOMOCION v6: correr — LA CARRERA DE THE CHOSEN ONE (AvA 2) --
    // En AvA 2 TCO corre PESADO y bajo, con el torso volcado: es un
    // sprint de dos tiempos, no un galope. La v4 tenia las dos mitades
    // del ciclo desiguales (contactos en 0 y .36 de .58) y eso leia
    // como cojera; la v6 lo simetriza (contactos en 0 y .30 de .60,
    // asimetria SOLO en las poses, nunca en el timing) y estructura
    // cada mitad igual que un salto encadenado:
    //   CONTACTO (.00) -> ABSORCION (.06, squash .91, cadera a 46)
    //   -> IMPULSO/toe-off (.13, stretch 1.06) -> VUELO (.21, cadera
    //   a 58, NINGUN pie cerca del suelo) -> cae al siguiente contacto
    //   con easing powerIn: la caida acelera, no se desliza.
    // El vuelo ocupa ~57% de cada mitad: es lo que hace que la
    // carrera de AvA 2 se lea "con potencia" y no como un trote.
    // Brazos: bombeo cruzando el cuerpo, codos cerrados, puño
    // contrario a la zancada llegando a la altura de la barbilla.
    // Cabeza: mirada clavada al frente (headOff casi constante) —
    // el cuello absorbe el boteo del torso, como en el video.
    static let run = AnimationClip(name: "correr", duration: 0.60, loops: true, keyframes: [
        K(0.0, P { p in // CONTACTO izquierdo: el pie cae LEJOS, delante del cuerpo volcado
            p.neckOff = CGPoint(x: 18, y: -38); p.headOff = CGPoint(x: 8, y: -20); p.hipHeight = 51
            p.footL = CGPoint(x: 36, y: 51); p.kneeL = CGPoint(x: 22, y: 24)
            p.footR = CGPoint(x: -30, y: 30); p.kneeR = CGPoint(x: -24, y: 10) // trasera acaba de despegar, talon al gluteo
            p.handL = CGPoint(x: -26, y: 16); p.elbowL = CGPoint(x: -10, y: 20) // brazo atras, codo cerrado
            p.handR = CGPoint(x: 32, y: 4); p.elbowR = CGPoint(x: 24, y: 18)   // puño contrario delante, cruzando
        }, .easeIn), // el peso sigue hundiendose hacia la absorcion
        K(0.06, P { p in // ABSORCION: compresion maxima, todo el peso en una pierna
            p.neckOff = CGPoint(x: 19, y: -37); p.headOff = CGPoint(x: 8, y: -19); p.hipHeight = 46; p.squash = 0.91
            p.footL = CGPoint(x: 25, y: 46); p.kneeL = CGPoint(x: 23, y: 18)
            p.footR = CGPoint(x: -13, y: 29); p.kneeR = CGPoint(x: -23, y: 9) // la libre ya barre hacia delante por abajo
            p.handL = CGPoint(x: -18, y: 22); p.handR = CGPoint(x: 24, y: 10)
        }, .easeOut), // explota fuera del fondo: extension violenta
        K(0.13, P { p in // IMPULSO (toe-off): pierna de apoyo estirada atras, rodilla libre clavando arriba
            p.neckOff = CGPoint(x: 18, y: -38); p.headOff = CGPoint(x: 7, y: -20); p.hipHeight = 54; p.squash = 1.06
            p.footL = CGPoint(x: -11, y: 48); p.kneeL = CGPoint(x: 2, y: 23)
            p.footR = CGPoint(x: 15, y: 25); p.kneeR = CGPoint(x: 27, y: 9)
            p.handL = CGPoint(x: 2, y: 10); p.elbowL = CGPoint(x: -14, y: 16)
            p.handR = CGPoint(x: 8, y: 20); p.elbowR = CGPoint(x: 18, y: 14)
        }, .easeOut), // sigue subiendo al vuelo
        K(0.21, P { p in // VUELO: el cuerpo entero en el aire, zancada abierta al maximo
            p.neckOff = CGPoint(x: 17, y: -39); p.headOff = CGPoint(x: 7, y: -21); p.hipHeight = 58; p.squash = 1.02
            p.footL = CGPoint(x: -35, y: 37); p.kneeL = CGPoint(x: -21, y: 15) // trasera estirada en el aire
            p.footR = CGPoint(x: 31, y: 28); p.kneeR = CGPoint(x: 27, y: 13)   // delantera buscando el suelo, tibia colgando
            p.handL = CGPoint(x: 30, y: 2); p.elbowL = CGPoint(x: 23, y: 18)   // el bombeo cruza: ahora el puño izquierdo delante
            p.handR = CGPoint(x: -28, y: 14); p.elbowR = CGPoint(x: -9, y: 20)
        }, .powerIn), // la gravedad manda: la caida al contacto ACELERA
        K(0.30, P { p in // CONTACTO derecho (espejo con asimetria de pose, no de tiempo)
            p.neckOff = CGPoint(x: 18, y: -38); p.headOff = CGPoint(x: 8, y: -20); p.hipHeight = 51
            p.footL = CGPoint(x: -29, y: 31); p.kneeL = CGPoint(x: -23, y: 10)
            p.footR = CGPoint(x: 37, y: 51); p.kneeR = CGPoint(x: 23, y: 24)
            p.handL = CGPoint(x: 33, y: 5); p.elbowL = CGPoint(x: 24, y: 18)
            p.handR = CGPoint(x: -25, y: 17); p.elbowR = CGPoint(x: -10, y: 20)
        }, .easeIn),
        K(0.36, P { p in // ABSORCION derecha
            p.neckOff = CGPoint(x: 19, y: -37); p.headOff = CGPoint(x: 8, y: -19); p.hipHeight = 46; p.squash = 0.91
            p.footL = CGPoint(x: -12, y: 29); p.kneeL = CGPoint(x: -22, y: 9)
            p.footR = CGPoint(x: 26, y: 46); p.kneeR = CGPoint(x: 24, y: 18)
            p.handL = CGPoint(x: 25, y: 11); p.handR = CGPoint(x: -17, y: 23)
        }, .easeOut),
        K(0.43, P { p in // IMPULSO derecho
            p.neckOff = CGPoint(x: 18, y: -38); p.headOff = CGPoint(x: 7, y: -20); p.hipHeight = 54; p.squash = 1.06
            p.footL = CGPoint(x: 16, y: 25); p.kneeL = CGPoint(x: 28, y: 9)
            p.footR = CGPoint(x: -10, y: 48); p.kneeR = CGPoint(x: 3, y: 23)
            p.handL = CGPoint(x: 9, y: 21); p.elbowL = CGPoint(x: 18, y: 14)
            p.handR = CGPoint(x: 3, y: 11); p.elbowR = CGPoint(x: -14, y: 16)
        }, .easeOut),
        K(0.51, P { p in // VUELO derecho -> cierra cayendo al contacto inicial
            p.neckOff = CGPoint(x: 17, y: -39); p.headOff = CGPoint(x: 7, y: -21); p.hipHeight = 58; p.squash = 1.02
            p.footL = CGPoint(x: 32, y: 28); p.kneeL = CGPoint(x: 28, y: 13)
            p.footR = CGPoint(x: -34, y: 37); p.kneeR = CGPoint(x: -20, y: 15)
            p.handL = CGPoint(x: -27, y: 15); p.elbowL = CGPoint(x: -9, y: 20)
            p.handR = CGPoint(x: 31, y: 3); p.elbowR = CGPoint(x: 23, y: 18)
        }, .powerIn)
    ])

    // -- Derrape al parar / cambiar de sentido (v4: mas peso, molinete de brazos) --
    static let skid = AnimationClip(name: "derrape", duration: 0.55, loops: false, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: -12, y: -40); p.headOff = CGPoint(x: -4, y: -22); p.hipHeight = 50; p.squash = 0.95 // se echa muy atras
            p.footL = CGPoint(x: 27, y: 50); p.kneeL = CGPoint(x: 15, y: 27) // pies por delante frenando, clavados
            p.footR = CGPoint(x: 18, y: 50); p.kneeR = CGPoint(x: 11, y: 29)
            p.handL = CGPoint(x: -30, y: 6); p.handR = CGPoint(x: 28, y: -8) // brazos en molinete buscando equilibrio
        }, .easeOut),
        K(0.22, P { p in
            p.neckOff = CGPoint(x: -10, y: -41); p.hipHeight = 52
            p.footL = CGPoint(x: 24, y: 52); p.footR = CGPoint(x: 15, y: 52)
            p.handL = CGPoint(x: -24, y: 22); p.handR = CGPoint(x: 30, y: 16) // el molinete se calma
        }, .easeInOut),
        K(0.55, SkeletonPose.standing, .softLanding) // settle largo
    ])

    // -- Giro con paso cruzado --
    static let turn = AnimationClip(name: "giro", duration: 0.3, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.15, P { p in
            p.hipHeight = 52; p.squash = 0.94
            p.footL = CGPoint(x: 12, y: 52); p.footR = CGPoint(x: -4, y: 50) // paso cruzado
            p.handL = CGPoint(x: -26, y: 34); p.handR = CGPoint(x: 26, y: 34)
        }, .easeOut),
        K(0.3, SkeletonPose.standing)
    ])

    // -- Salto por fases v4 (la vista elige segun fisica) --
    // Anticipacion MAS larga y profunda que en la v2/v3 (en los videos
    // se agacha "de verdad" antes de saltar), stretch mayor al despegar
    // y aterrizaje con squash que se AGUANTA y settle con overshoot.
    static let jumpCrouch = AnimationClip(name: "salto-agacharse", duration: 0.26, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.16, P { p in
            p.hipHeight = 42; p.squash = 0.88
            p.kneeL = CGPoint(x: -15, y: 19); p.footL = CGPoint(x: -14, y: 42)
            p.kneeR = CGPoint(x: 15, y: 19); p.footR = CGPoint(x: 14, y: 42)
            p.handL = CGPoint(x: -20, y: 34); p.handR = CGPoint(x: 20, y: 34)
        }, .easeIn), // sigue bajando: anticipacion en dos tiempos
        K(0.26, P { p in
            p.hipHeight = 35; p.squash = 0.78 // ANTICIPACION profunda, cargada
            p.neckOff = CGPoint(x: 5, y: -34); p.headOff = CGPoint(x: 3, y: -19)
            p.kneeL = CGPoint(x: -18, y: 15); p.footL = CGPoint(x: -16, y: 35)
            p.kneeR = CGPoint(x: 18, y: 15); p.footR = CGPoint(x: 16, y: 35)
            p.handL = CGPoint(x: -27, y: 26); p.handR = CGPoint(x: 27, y: 26) // brazos muy atras, listos para lanzar
        })
    ])
    static let jumpStretch = AnimationClip(name: "salto-estirar", duration: 0.32, loops: false, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 59; p.squash = 1.17 // STRETCH maximo al despegar
            p.footL = CGPoint(x: -7, y: 44); p.kneeL = CGPoint(x: -5, y: 23)
            p.footR = CGPoint(x: 8, y: 46); p.kneeR = CGPoint(x: 6, y: 24)
            p.handL = CGPoint(x: -24, y: -12); p.handR = CGPoint(x: 24, y: -12) // los brazos se lanzan arriba (follow-through)
        }, .easeOut),
        K(0.32, P { p in
            p.squash = 1.03
            p.footL = CGPoint(x: -14, y: 36); p.kneeL = CGPoint(x: -13, y: 17)
            p.footR = CGPoint(x: 15, y: 38); p.kneeR = CGPoint(x: 13, y: 18)
            p.handL = CGPoint(x: -28, y: 4); p.handR = CGPoint(x: 28, y: 4) // y quedan flotando un instante
        })
    ])
    static let fallPose = AnimationClip(name: "caida", duration: 0.55, loops: false, keyframes: [
        K(0.0, P { p in
            p.footL = CGPoint(x: -21, y: 32); p.kneeL = CGPoint(x: -16, y: 15) // piernas abiertas buscando suelo
            p.footR = CGPoint(x: 22, y: 34); p.kneeR = CGPoint(x: 17, y: 16)
            p.handL = CGPoint(x: -29, y: -6); p.handR = CGPoint(x: 29, y: -6) // brazos arriba, en panico leve
        }, .easeInOut),
        K(0.3, P { p in
            p.footL = CGPoint(x: -24, y: 37); p.footR = CGPoint(x: 25, y: 39)
            p.handL = CGPoint(x: -31, y: 2); p.handR = CGPoint(x: 27, y: 6) // bracea asimetrico preparando el impacto
            p.neckOff = CGPoint(x: 3, y: -40)
        }, .easeInOut),
        K(0.55, P { p in
            p.footL = CGPoint(x: -23, y: 39); p.footR = CGPoint(x: 24, y: 41)
            p.handL = CGPoint(x: -28, y: 8); p.handR = CGPoint(x: 30, y: 8)
        })
    ])
    static let landing = AnimationClip(name: "aterrizar", duration: 0.55, loops: false, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 36; p.squash = 0.74 // SQUASH de impacto, mas profundo
            p.kneeL = CGPoint(x: -19, y: 14); p.footL = CGPoint(x: -20, y: 36)
            p.kneeR = CGPoint(x: 19, y: 14); p.footR = CGPoint(x: 20, y: 36)
            p.handL = CGPoint(x: -28, y: 30); p.handR = CGPoint(x: 28, y: 30) // manos casi al suelo
            p.neckOff = CGPoint(x: 4, y: -36)
        }, .easeOut),
        K(0.14, P { p in p.hipHeight = 38; p.squash = 0.79 }, .easeInOut), // AGUANTA el impacto (pose larga)
        K(0.34, P { p in p.hipHeight = 53; p.squash = 0.97 }, .easeOut),   // recupera...
        K(0.44, P { p in p.hipHeight = 57; p.squash = 1.03 }, .easeInOut), // ...con overshoot
        K(0.5, P { p in p.hipHeight = 55; p.squash = 0.99 }, .easeOut),    // v6: micro-rebote (el cuerpo "resuena" una vez mas, mitad de amplitud)
        K(0.55, SkeletonPose.standing, .softLanding)                        // y settle suave
    ])
    static let roll = AnimationClip(name: "rodar", duration: 0.66, loops: false, keyframes: [
        K(0.0, P { p in p.hipHeight = 36; p.squash = 0.9; p.headOff = CGPoint(x: 6, y: -18) }, .easeIn), // se inclina al suelo
        K(0.13, P { p in p.hipHeight = 30; p.squash = 0.84; p.neckOff = CGPoint(x: 10, y: -26); p.handL = CGPoint(x: 14, y: 26); p.handR = CGPoint(x: 18, y: 28) }, .easeIn), // manos al suelo, se encoge
        K(0.3, P { p in // hecho una bola (pasa rapido)
            p.hipHeight = 21; p.neckOff = CGPoint(x: 15, y: -17); p.headOff = CGPoint(x: 8, y: -9)
            p.footL = CGPoint(x: -2, y: 19); p.kneeL = CGPoint(x: 10, y: 7)
            p.footR = CGPoint(x: 4, y: 21); p.kneeR = CGPoint(x: 14, y: 9)
            p.handL = CGPoint(x: -2, y: -2); p.handR = CGPoint(x: 6, y: 0)
        }, .easeOut),
        K(0.48, P { p in p.hipHeight = 38; p.neckOff = CGPoint(x: 6, y: -34); p.squash = 1.02 }, .easeOut), // sale con impulso
        K(0.66, SkeletonPose.standing, .softLanding)
    ])
    static let dizzy = AnimationClip(name: "mareado", duration: 1.6, loops: true, keyframes: [
        K(0.0, P { $0.headOff = CGPoint(x: -8, y: -20); $0.hipDX = -3; $0.handL = CGPoint(x: -24, y: 30); $0.handR = CGPoint(x: 24, y: 30) }, .easeInOut),
        K(0.8, P { $0.headOff = CGPoint(x: 8, y: -20); $0.hipDX = 3; $0.neckOff.x = 3 }, .easeInOut)
    ])

    // -- Pelea con el cursor/dedo v6 (AvA 1: guerra contra el cursor;
    // AvA 2/4: las peleas son RAFAGAS, no golpes sueltos con pausa) --
    // Estructura tradicional por golpe: ANTICIPACION corta -> GOLPE
    // SECO (tramo snappy de .06-.09) -> IMPACTO AGUANTADO (hold de
    // .09-.16, MAS largo que la anticipacion) -> recogida que ya es
    // la carga del siguiente golpe. La v6 reordena la v4 en rafaga:
    // jab-jab (el segundo con la mitad de anticipacion: sale de la
    // propia recogida del primero, como en los intercambios de AvA 4)
    // -> cross con cadera -> patada frontal -> barrido -> guardia.
    // Entre rafagas, la guardia RESPIRA con bounce (nunca foto quieta).
    static let fightCombo = AnimationClip(name: "pelea", duration: 3.6, loops: true, keyframes: [
        K(0.0, P { p in // guardia baja y ancha, peso en los talones
            p.hipHeight = 49; p.neckOff = CGPoint(x: 6, y: -40); p.squash = 0.97
            p.footL = CGPoint(x: -20, y: 49); p.kneeL = CGPoint(x: -12, y: 26)
            p.footR = CGPoint(x: 22, y: 49); p.kneeR = CGPoint(x: 13, y: 26)
            p.handL = CGPoint(x: 17, y: 6); p.elbowL = CGPoint(x: 4, y: 17)
            p.handR = CGPoint(x: 27, y: 11); p.elbowR = CGPoint(x: 14, y: 20)
        }, .easeInOut),
        K(0.20, P { p in // bounce de guardia: sube un pelo, listo
            p.hipHeight = 51; p.squash = 1.0
            p.footL = CGPoint(x: -20, y: 51); p.footR = CGPoint(x: 22, y: 51)
            p.handL = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 26, y: 13)
        }, .easeIn), // carga el jab: hombro atras
        K(0.34, P { p in // ANTICIPACION jab 1: puño recogido, torso girado
            p.hipHeight = 50; p.neckOff = CGPoint(x: 2, y: -40); p.hipDX = -2
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 22, y: 50)
            p.handR = CGPoint(x: 12, y: 14); p.elbowR = CGPoint(x: -2, y: 20)
            p.handL = CGPoint(x: 18, y: 6)
        }, .snappy), // ¡JAB 1! extension total en .07
        K(0.41, P { p in // IMPACTO jab 1: puño clavado, torso volcado
            p.hipHeight = 50; p.neckOff = CGPoint(x: 11, y: -39); p.hipDX = 3
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50)
            p.handR = CGPoint(x: 50, y: 4); p.elbowR = CGPoint(x: 28, y: 5)
            p.handL = CGPoint(x: 13, y: 11)
        }, .easeInOut), // AGUANTA el impacto
        K(0.50, P { p in // el puño sigue clavado; la recogida empieza...
            p.hipHeight = 50; p.neckOff = CGPoint(x: 10, y: -39); p.hipDX = 3
            p.handR = CGPoint(x: 49, y: 5); p.elbowR = CGPoint(x: 28, y: 6)
            p.handL = CGPoint(x: 14, y: 10)
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50)
        }, .easeIn), // ...y SIN volver a guardia carga el segundo jab (anticipacion minima)
        K(0.58, P { p in // ANTICIPACION jab 2: solo media recogida
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -40); p.hipDX = 0
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 23, y: 50)
            p.handR = CGPoint(x: 27, y: 10); p.elbowR = CGPoint(x: 8, y: 14)
            p.handL = CGPoint(x: 15, y: 9)
        }, .snappy), // ¡JAB 2! mas rapido que el primero
        K(0.64, P { p in // IMPACTO jab 2
            p.hipHeight = 50; p.neckOff = CGPoint(x: 12, y: -39); p.hipDX = 4
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50)
            p.handR = CGPoint(x: 51, y: 3); p.elbowR = CGPoint(x: 29, y: 4)
            p.handL = CGPoint(x: 13, y: 11)
        }, .easeInOut), // hold
        K(0.74, P { p in p.handR = CGPoint(x: 50, y: 4); p.neckOff.x = 11; p.hipDX = 4; p.hipHeight = 50; p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50) }, .easeIn), // recoge girando la cadera al reves: carga el cross
        K(0.94, P { p in // ANTICIPACION cross: puño izquierdo muy atras, squash de carga
            p.hipHeight = 49; p.neckOff = CGPoint(x: 3, y: -40); p.hipDX = -3; p.squash = 0.96
            p.footL = CGPoint(x: -19, y: 49); p.footR = CGPoint(x: 23, y: 49)
            p.handL = CGPoint(x: 8, y: 13); p.elbowL = CGPoint(x: -6, y: 19)
            p.handR = CGPoint(x: 22, y: 10)
        }, .snappy), // ¡CROSS! con toda la cadera
        K(1.04, P { p in // IMPACTO cross
            p.hipHeight = 49; p.neckOff = CGPoint(x: 13, y: -39); p.hipDX = 5
            p.footL = CGPoint(x: -22, y: 49); p.footR = CGPoint(x: 25, y: 49)
            p.handL = CGPoint(x: 48, y: 7); p.elbowL = CGPoint(x: 26, y: 8)
            p.handR = CGPoint(x: 15, y: 11)
        }, .easeInOut), // hold: el cross se aguanta mas (es el golpe fuerte de la rafaga)
        K(1.20, P { p in p.handL = CGPoint(x: 47, y: 8); p.neckOff.x = 12; p.hipDX = 4; p.hipHeight = 49; p.footL = CGPoint(x: -22, y: 49); p.footR = CGPoint(x: 25, y: 49) }, .easeIn), // recoge a guardia...
        K(1.40, P { p in // guardia, bounce — y sin pausa carga la patada
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -40)
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 22, y: 50)
            p.handL = CGPoint(x: 17, y: 6); p.handR = CGPoint(x: 27, y: 11)
        }, .easeIn), // CHAMBER: rodilla sube, cuerpo atras
        K(1.58, P { p in
            p.hipHeight = 52; p.neckOff = CGPoint(x: -3, y: -41)
            p.footL = CGPoint(x: -13, y: 52)
            p.footR = CGPoint(x: 16, y: 26); p.kneeR = CGPoint(x: 26, y: 22)
            p.handL = CGPoint(x: -24, y: 20); p.handR = CGPoint(x: 20, y: 4)
        }, .snappy), // ¡PATADA FRONTAL! extension seca en .09
        K(1.67, P { p in // IMPACTO patada: pierna recta a la altura del pecho del "cursor"
            p.hipHeight = 53; p.neckOff = CGPoint(x: -6, y: -41)
            p.footL = CGPoint(x: -14, y: 53)
            p.footR = CGPoint(x: 52, y: 18); p.kneeR = CGPoint(x: 32, y: 16)
            p.handL = CGPoint(x: -28, y: 24); p.handR = CGPoint(x: 16, y: 2)
        }, .easeInOut), // hold de impacto
        K(1.82, P { p in p.footR = CGPoint(x: 50, y: 20); p.kneeR = CGPoint(x: 31, y: 17); p.hipHeight = 52; p.neckOff.x = -5; p.footL = CGPoint(x: -14, y: 52) }, .easeIn), // recoge la pierna y se deja caer...
        K(2.0, P { p in // ...al agachón que carga el barrido (anticipacion larga, la del golpe final)
            p.hipHeight = 37; p.squash = 0.88; p.neckOff = CGPoint(x: 7, y: -31); p.headOff = CGPoint(x: 4, y: -18)
            p.footL = CGPoint(x: -10, y: 37); p.footR = CGPoint(x: 14, y: 37)
            p.handL = CGPoint(x: -12, y: 24); p.handR = CGPoint(x: 14, y: 26) // manos casi al suelo
        }, .snappy), // ¡BARRIDO GIRATORIO! pierna extendida barriendo bajo
        K(2.18, P { p in
            p.hipHeight = 33; p.neckOff = CGPoint(x: 10, y: -29); p.headOff = CGPoint(x: 5, y: -17)
            p.footL = CGPoint(x: -6, y: 33); p.footR = CGPoint(x: 44, y: 8); p.kneeR = CGPoint(x: 26, y: 7)
            p.handL = CGPoint(x: -16, y: 27); p.handR = CGPoint(x: 18, y: 29)
        }, .easeOut), // se levanta del barrido con impulso
        K(2.5, P { p in
            p.hipHeight = 46; p.squash = 0.96; p.neckOff = CGPoint(x: 6, y: -38)
            p.footL = CGPoint(x: -16, y: 46); p.footR = CGPoint(x: 20, y: 46)
            p.handL = CGPoint(x: -6, y: 18); p.handR = CGPoint(x: 24, y: 14)
        }, .easeInOut),
        K(2.85, P { p in // guardia otra vez, respira (settle del combo)
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -39)
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 22, y: 50)
            p.handL = CGPoint(x: 17, y: 6); p.handR = CGPoint(x: 27, y: 11)
        }, .easeInOut),
        K(3.3, P { p in // bounce final: casi la pose inicial, el ciclo cierra limpio
            p.hipHeight = 49; p.neckOff = CGPoint(x: 6, y: -40); p.squash = 0.97
            p.footL = CGPoint(x: -20, y: 49); p.footR = CGPoint(x: 22, y: 49)
            p.handL = CGPoint(x: 17, y: 7); p.handR = CGPoint(x: 27, y: 12)
        }, .easeInOut)
    ])

    // Bloqueo v6: antebrazos cruzados en alto. Sobre la v4 (flinch al
    // impacto) se anade lo que vende los bloqueos de AvA 4: los PIES
    // DERRAPAN hacia atras al parar el golpe (el cuerpo entero se
    // desplaza 5-6 pt, no se queda clavado), un aguante con micro-
    // temblor mientras dura la presion, y la recuperacion en DOS
    // tiempos (primero planta los pies, despues re-alza la guardia).
    static let block = AnimationClip(name: "bloquear", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in // antebrazos cruzados delante, firme
            p.hipHeight = 49; p.squash = 0.96
            p.handL = CGPoint(x: 15, y: -2); p.elbowL = CGPoint(x: -2, y: 16)
            p.handR = CGPoint(x: 13, y: 6); p.elbowR = CGPoint(x: 20, y: 18)
            p.footL = CGPoint(x: -16, y: 49); p.footR = CGPoint(x: 18, y: 49)
        }, .snappy), // ¡IMPACTO! el golpe le empuja hacia atras Y los pies derrapan
        K(0.14, P { p in
            p.hipHeight = 46; p.squash = 0.9; p.hipDX = -6; p.neckOff = CGPoint(x: -3, y: -39)
            p.handL = CGPoint(x: 13, y: -4); p.handR = CGPoint(x: 11, y: 4)
            p.footL = CGPoint(x: -22, y: 46); p.footR = CGPoint(x: 12, y: 46) // derrape: ambos pies atras
        }, .easeInOut), // AGUANTA la presion: micro-temblor de esfuerzo
        K(0.26, P { p in
            p.hipHeight = 46; p.squash = 0.91; p.hipDX = -6; p.neckOff = CGPoint(x: -2, y: -39)
            p.handL = CGPoint(x: 14, y: -3); p.handR = CGPoint(x: 12, y: 5)
            p.footL = CGPoint(x: -22, y: 46); p.footR = CGPoint(x: 12, y: 46)
        }, .easeOut), // primer tiempo de recuperacion: vuelve a plantar los pies
        K(0.45, P { p in p.hipHeight = 48; p.squash = 0.95; p.hipDX = -3; p.handL = CGPoint(x: 15, y: -3); p.handR = CGPoint(x: 12, y: 5); p.footL = CGPoint(x: -18, y: 48); p.footR = CGPoint(x: 16, y: 48) }, .easeInOut),
        K(0.7, P { p in p.hipHeight = 49; p.squash = 0.96; p.hipDX = -1; p.handL = CGPoint(x: 15, y: -2); p.handR = CGPoint(x: 13, y: 6); p.footL = CGPoint(x: -16, y: 49); p.footR = CGPoint(x: 18, y: 49) }, .easeInOut) // segundo tiempo: guardia re-alzada, aguanta
    ])

    // Recibir un golpe v6 (NUEVO — la v4 no tenia reaccion de golpe
    // propia; lo mas parecido era block, que es defensa activa).
    // En AvA el que recibe NO se queda quieto: la cabeza y el torso
    // se van hacia atras de golpe (latigazo), da un paso trastabillado
    // y se recupera en dos bamboleos de amplitud decreciente.
    // Estructura: RECOIL seco (.07) -> tambaleo 1 -> tambaleo 2 (mitad
    // de amplitud) -> guardia temblorosa -> de pie.
    // CABLEADO SUGERIDO (integracion): reproducir al entrar en
    // .stunned o tras un impacto del dedo en modo pelea.
    static let hitReact = AnimationClip(name: "recibir golpe", duration: 1.15, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .snappy), // de pie, sin verlo venir — el latigazo es inmediato
        K(0.07, P { p in // RECOIL: cabeza y torso hacia atras, brazos se abren de golpe
            p.hipHeight = 52; p.neckOff = CGPoint(x: -12, y: -37); p.headOff = CGPoint(x: -8, y: -19); p.hipDX = -7; p.squash = 0.94
            p.handL = CGPoint(x: -34, y: 8); p.elbowL = CGPoint(x: -20, y: 14)
            p.handR = CGPoint(x: 36, y: 2); p.elbowR = CGPoint(x: 22, y: 12)
            p.footL = CGPoint(x: -20, y: 52); p.footR = CGPoint(x: 8, y: 46) // un pie se despega del suelo
            p.kneeR = CGPoint(x: 2, y: 26)
        }, .easeOut), // sale trastabillando: paso atras obligado
        K(0.24, P { p in // TAMBALEO 1: pisa atras como puede, brazos molinete buscando equilibrio
            p.hipHeight = 50; p.neckOff = CGPoint(x: -8, y: -39); p.headOff = CGPoint(x: -6, y: -20); p.hipDX = -5
            p.footL = CGPoint(x: -16, y: 50); p.footR = CGPoint(x: 28, y: 50)
            p.handL = CGPoint(x: -28, y: 22); p.handR = CGPoint(x: 30, y: 18)
        }, .easeInOut),
        K(0.48, P { p in // TAMBALEO 2: mitad de amplitud, ya recupera la vertical
            p.hipHeight = 52; p.neckOff = CGPoint(x: -4, y: -41); p.headOff = CGPoint(x: -3, y: -21); p.hipDX = -2
            p.footL = CGPoint(x: -10, y: 52); p.footR = CGPoint(x: 24, y: 52)
            p.handL = CGPoint(x: -22, y: 14); p.handR = CGPoint(x: 24, y: 16)
        }, .easeOut),
        K(0.78, P { p in // sube una guardia TEMBLOROSA (aun no esta fino)
            p.hipHeight = 54; p.neckOff = CGPoint(x: -1, y: -42); p.headOff = CGPoint(x: 0, y: -22)
            p.footL = CGPoint(x: -18, y: 54); p.footR = CGPoint(x: 20, y: 54)
            p.handL = CGPoint(x: -18, y: 10); p.handR = CGPoint(x: 26, y: 13)
        }, .softLanding),
        K(1.15, P { p in // de pie, guardia baja, listo otra vez
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -23)
            p.footL = CGPoint(x: -19, y: 55); p.footR = CGPoint(x: 21, y: 55)
            p.handL = CGPoint(x: -18, y: 12); p.handR = CGPoint(x: 25, y: 14)
        }, .linear)
    ])

    // Levantarse del suelo v6 (NUEVO — encadena con la pose final de
    // trip, que es exactamente su keyframe 0). En AvA el stickman no
    // "aparece" de pie tras una caida: se apoya en los antebrazos,
    // pasa a gatas, sube a cuclillas balanceandose y se pone de pie
    // con un pelo de overshoot (backOut) antes de asentarse.
    // CABLEADO SUGERIDO (integracion): tras trip/knockDown, antes de
    // volver a idle.
    static let getUp = AnimationClip(name: "levantarse", duration: 1.05, loops: false, keyframes: [
        K(0.0, P { p in // == pose de suelo de trip (su keyframe de 0.5): de bruces
            p.hipHeight = 13; p.neckOff = CGPoint(x: -30, y: -5); p.headOff = CGPoint(x: -17, y: -3)
            p.handL = CGPoint(x: -22, y: 6); p.handR = CGPoint(x: -6, y: 9)
            p.footL = CGPoint(x: 42, y: 11); p.kneeL = CGPoint(x: 20, y: 6)
            p.footR = CGPoint(x: 40, y: 5); p.kneeR = CGPoint(x: 18, y: 3)
        }, .easeOut), // empuja con los antebrazos y levanta la cabeza
        K(0.22, P { p in
            p.hipHeight = 16; p.neckOff = CGPoint(x: -25, y: -9); p.headOff = CGPoint(x: -12, y: -16)
            p.handL = CGPoint(x: -24, y: 8); p.handR = CGPoint(x: 4, y: 12)
            p.footL = CGPoint(x: 36, y: 12); p.footR = CGPoint(x: 34, y: 6)
        }, .easeInOut), // pasa a gatas: una mano plantada, rodillas bajo la cadera
        K(0.48, P { p in
            p.hipHeight = 30; p.neckOff = CGPoint(x: -14, y: -22); p.headOff = CGPoint(x: -6, y: -18)
            p.handL = CGPoint(x: -16, y: 22); p.handR = CGPoint(x: 22, y: 26)
            p.kneeL = CGPoint(x: -14, y: 20); p.kneeR = CGPoint(x: 16, y: 18)
            p.footL = CGPoint(x: -18, y: 30); p.footR = CGPoint(x: 24, y: 26)
        }, .easeOut), // sube a cuclillas alta, brazos balanceando
        K(0.74, P { p in
            p.hipHeight = 44; p.squash = 0.95; p.neckOff = CGPoint(x: -4, y: -34); p.headOff = CGPoint(x: -2, y: -21)
            p.handL = CGPoint(x: -24, y: 26); p.handR = CGPoint(x: 26, y: 24)
            p.kneeL = CGPoint(x: -14, y: 24); p.kneeR = CGPoint(x: 12, y: 24)
            p.footL = CGPoint(x: -16, y: 44); p.footR = CGPoint(x: 18, y: 44)
        }, .backOut), // de pie con un pelo de overshoot (asentamiento con vida)
        K(0.92, P { p in
            p.hipHeight = 57; p.squash = 1.03; p.neckOff = CGPoint(x: 1, y: -43); p.headOff = CGPoint(x: 0, y: -23)
            p.handL = CGPoint(x: -21, y: 38); p.handR = CGPoint(x: 21, y: 38)
            p.footL = CGPoint(x: -14, y: 57); p.footR = CGPoint(x: 14, y: 57)
        }, .softLanding), // ...y asienta en la postura neutra exacta
        K(1.05, SkeletonPose.standing, .linear)
    ])

    static let dodgeDuck = AnimationClip(name: "esquivar-agachado", duration: 0.6, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .snappy),
        K(0.1, P { p in // baja DE GOLPE (la esquiva es un reflejo, sin anticipacion)
            p.hipHeight = 29; p.squash = 0.76; p.neckOff = CGPoint(x: 7, y: -27); p.headOff = CGPoint(x: 3, y: -16)
            p.kneeL = CGPoint(x: -17, y: 11); p.footL = CGPoint(x: -16, y: 29)
            p.kneeR = CGPoint(x: 17, y: 11); p.footR = CGPoint(x: 16, y: 29)
            p.handL = CGPoint(x: -20, y: 22); p.handR = CGPoint(x: 20, y: 22)
        }, .easeInOut), // se queda bajo un instante, mirando al dedo
        K(0.32, P { p in p.hipHeight = 31; p.squash = 0.8; p.headOff = CGPoint(x: 5, y: -17) }, .easeOut),
        K(0.6, SkeletonPose.standing, .softLanding) // sube despacio, con cautela
    ])

    // v6 (AvA 1): agarrarse al cursor y FORCEJEAR con el. Sobre la
    // v4 (cuelga, se balancea, patea el dedo, intenta TREPAR) se
    // anade el beat que la v4 no tenia y que en el video vende la
    // lucha: cuando trepar falla, APOYA LOS DOS PIES en el dedo y
    // EMPUJA con las piernas haciendo palanca, arqueando el cuerpo
    // hacia atras — y luego resbala de vuelta a colgar. Ciclo 1.9.
    static let grabFinger = AnimationClip(name: "agarrar-dedo", duration: 1.9, loops: true, keyframes: [
        K(0.0, P { p in // recien agarrado: cuelga de las dos manos
            p.hipHeight = 58; p.neckOff = CGPoint(x: -3, y: -44)
            p.handL = CGPoint(x: -6, y: -34); p.elbowL = CGPoint(x: -12, y: -14)
            p.handR = CGPoint(x: 8, y: -34); p.elbowR = CGPoint(x: 13, y: -14)
            p.footL = CGPoint(x: -14, y: 52); p.kneeL = CGPoint(x: -10, y: 26)
            p.footR = CGPoint(x: 16, y: 50); p.kneeR = CGPoint(x: 11, y: 25)
        }, .easeInOut),
        K(0.35, P { p in // balanceo: el cuerpo va a un lado
            p.neckOff = CGPoint(x: 4, y: -44); p.hipDX = 4
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: -19, y: 49); p.footR = CGPoint(x: 12, y: 53)
        }, .snappy), // ¡PATEA el dedo con las dos piernas!
        K(0.55, P { p in
            p.hipHeight = 54; p.neckOff = CGPoint(x: 6, y: -42); p.hipDX = 3
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: 8, y: 34); p.kneeL = CGPoint(x: 10, y: 18)
            p.footR = CGPoint(x: 14, y: 36); p.kneeR = CGPoint(x: 13, y: 19)
        }, .easeInOut), // se recoge tras la patada
        K(0.8, P { p in
            p.neckOff = CGPoint(x: -2, y: -44); p.hipDX = -2
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: -12, y: 51); p.footR = CGPoint(x: 17, y: 50)
        }, .easeIn), // intenta TREPAR por el dedo: tira de brazos
        K(1.15, P { p in // sube un palmo: manos mas arriba, cuerpo pegado al "dedo"
            p.hipHeight = 63; p.squash = 1.04; p.neckOff = CGPoint(x: 0, y: -45)
            p.handL = CGPoint(x: -5, y: -40); p.elbowL = CGPoint(x: -13, y: -18)
            p.handR = CGPoint(x: 7, y: -40); p.elbowR = CGPoint(x: 13, y: -18)
            p.footL = CGPoint(x: -10, y: 48); p.kneeL = CGPoint(x: -13, y: 24)
            p.footR = CGPoint(x: 11, y: 47); p.kneeR = CGPoint(x: 13, y: 23)
        }, .easeInOut), // se le acaba la fuerza y cae de vuelta a colgar
        K(1.38, P { p in
            p.hipHeight = 58; p.neckOff = CGPoint(x: -3, y: -44)
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: -15, y: 52); p.footR = CGPoint(x: 15, y: 51)
        }, .easeIn), // v6: busca apoyo con los pies EN el dedo (brace)
        K(1.6, P { p in // APOYA los dos pies en el dedo, piernas flexionadas, cuerpo arqueado atras
            p.hipHeight = 56; p.neckOff = CGPoint(x: -8, y: -43); p.hipDX = -5
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: -2, y: 32); p.kneeL = CGPoint(x: -8, y: 20)
            p.footR = CGPoint(x: 5, y: 35); p.kneeR = CGPoint(x: 0, y: 22)
        }, .snappy), // ¡EMPUJA con las piernas! palanca con todo el cuerpo
        K(1.74, P { p in
            p.hipHeight = 61; p.squash = 1.03; p.neckOff = CGPoint(x: -11, y: -44); p.hipDX = -7
            p.handL = CGPoint(x: -6, y: -31); p.handR = CGPoint(x: 8, y: -31) // las manos resbalan un poco
            p.footL = CGPoint(x: 2, y: 26); p.kneeL = CGPoint(x: -2, y: 16)
            p.footR = CGPoint(x: 9, y: 29); p.kneeR = CGPoint(x: 4, y: 18)
        }, .easeInOut) // no cede: resbala de vuelta a colgar (el cierre de bucle lo devuelve)
    ])

    // v6 (AvA 1): ser agarrado = PATALEO frenetico. Sobre la v4:
    // ciclo mas corto (.72 -> .64), intervalos IRREGULARES (el panico
    // no lleva metronomo), retorcimiento mayor (hipDX +-3, cabeza
    // +-4) y un EMPUJE DOBLE aguantado .06 en mitad del ciclo — ese
    // micro-freeze en pleno esfuerzo es lo que lo hace leer "real"
    // en vez de "gif en bucle". Todo lineal a proposito.
    static let grabbed = AnimationClip(name: "agarrado", duration: 0.64, loops: true, keyframes: [
        K(0.0, P { p in
            p.footL = CGPoint(x: -22, y: 38); p.kneeL = CGPoint(x: -15, y: 17)
            p.footR = CGPoint(x: 20, y: 44); p.kneeR = CGPoint(x: 14, y: 21)
            p.handL = CGPoint(x: -29, y: 4); p.handR = CGPoint(x: 27, y: 0); p.headOff = CGPoint(x: -4, y: -22)
        }, .linear),
        K(0.11, P { p in // patada izquierda, brazo contrario
            p.footL = CGPoint(x: -10, y: 47); p.kneeL = CGPoint(x: -8, y: 22)
            p.footR = CGPoint(x: 26, y: 35); p.kneeR = CGPoint(x: 17, y: 15)
            p.handL = CGPoint(x: -24, y: -7); p.handR = CGPoint(x: 31, y: 10); p.headOff = CGPoint(x: 4, y: -22); p.hipDX = 2
        }, .linear),
        K(0.21, P { p in // patada derecha, se retuerce al otro lado
            p.footL = CGPoint(x: -26, y: 42); p.kneeL = CGPoint(x: -17, y: 19)
            p.footR = CGPoint(x: 11, y: 48); p.kneeR = CGPoint(x: 9, y: 23)
            p.handL = CGPoint(x: -31, y: 10); p.handR = CGPoint(x: 23, y: -5); p.headOff = CGPoint(x: -2, y: -21); p.hipDX = -3
        }, .linear),
        K(0.32, P { p in // EMPUJE DOBLE: las dos piernas a la vez contra la pinza
            p.footL = CGPoint(x: -17, y: 49); p.footR = CGPoint(x: 19, y: 49)
            p.kneeL = CGPoint(x: -10, y: 24); p.kneeR = CGPoint(x: 11, y: 24)
            p.handL = CGPoint(x: -27, y: -3); p.handR = CGPoint(x: 29, y: 6); p.hipDX = 3; p.squash = 0.97
        }, .linear),
        K(0.38, P { p in // ...AGUANTADO: el esfuerzo se congela un instante
            p.footL = CGPoint(x: -17, y: 49); p.footR = CGPoint(x: 19, y: 49)
            p.handL = CGPoint(x: -26, y: -2); p.handR = CGPoint(x: 28, y: 7); p.hipDX = 3
        }, .linear),
        K(0.47, P { p in // suelta de golpe y vuelve el pataleo
            p.footL = CGPoint(x: -24, y: 35); p.footR = CGPoint(x: 24, y: 39)
            p.handL = CGPoint(x: -29, y: 8); p.handR = CGPoint(x: 25, y: -7); p.headOff = CGPoint(x: -4, y: -21); p.hipDX = -2
        }, .linear),
        K(0.56, P { p in
            p.footL = CGPoint(x: -11, y: 46); p.footR = CGPoint(x: 14, y: 48)
            p.handL = CGPoint(x: -24, y: 0); p.handR = CGPoint(x: 30, y: 4); p.headOff = CGPoint(x: 2, y: -22); p.hipDX = 1
        }, .linear)
    ])

    // v6 (AvA 1): forcejeo para escapar de la caja de seleccion.
    // La v4 tenia el defecto de bucle clasico: la amplitud crecia
    // durante 1.0 s y el wrap la reseteaba de golpe a floja. La v6
    // reestructura el ciclo (2.6 s) como el momento real del video:
    // FASE 1 sacudidas flojas (amplitud 2) -> FASE 2 empuja las
    // "paredes" con las manos abiertas (amplitud 4-5) -> FASE 3
    // violencia maxima (amplitud 6-7, squash extremos) -> RESETEO
    // visible: se agacha, re-agarra las paredes y respira (.26) —
    // el descenso de amplitud ahora es PARTE de la animacion, no un
    // corte del bucle. Todo lineal: la violencia no lleva easing.
    static let escapeShake = AnimationClip(name: "escapar-caja", duration: 2.6, loops: true, keyframes: [
        // FASE 1: sacudidas flojas, aun esta probando la caja
        K(0.0, P { $0.hipDX = -2; $0.squash = 0.97; $0.handL = CGPoint(x: -22, y: 18); $0.handR = CGPoint(x: 22, y: 18); $0.headOff = CGPoint(x: -2, y: -23) }, .linear),
        K(0.18, P { $0.hipDX = 2; $0.squash = 1.02; $0.headOff.x = 2 }, .linear),
        K(0.36, P { $0.hipDX = -2; $0.squash = 0.96; $0.headOff.x = -2 }, .linear),
        K(0.54, P { $0.hipDX = 3; $0.squash = 1.03; $0.headOff.x = 3 }, .linear),
        // FASE 2: manos abiertas contra las paredes, empuja de verdad
        K(0.74, P { $0.hipDX = -4; $0.squash = 0.94; $0.handL = CGPoint(x: -28, y: 10); $0.handR = CGPoint(x: 26, y: 20); $0.headOff.x = -4 }, .linear),
        K(0.94, P { $0.hipDX = 5; $0.squash = 1.05; $0.handL = CGPoint(x: -26, y: 20); $0.handR = CGPoint(x: 28, y: 10); $0.headOff.x = 5 }, .linear),
        K(1.14, P { $0.hipDX = -5; $0.squash = 0.93; $0.handL = CGPoint(x: -29, y: 12); $0.handR = CGPoint(x: 27, y: 18); $0.headOff.x = -5 }, .linear),
        K(1.34, P { $0.hipDX = 5; $0.squash = 1.06; $0.handL = CGPoint(x: -27, y: 18); $0.handR = CGPoint(x: 29, y: 12); $0.headOff.x = 5 }, .linear),
        // FASE 3: violencia maxima — a punto de romperla
        K(1.54, P { $0.hipDX = -7; $0.squash = 0.9; $0.handL = CGPoint(x: -31, y: 8); $0.handR = CGPoint(x: 29, y: 16); $0.headOff.x = -7; $0.hipHeight = 52; $0.footL = CGPoint(x: -20, y: 52); $0.footR = CGPoint(x: 20, y: 52) }, .linear),
        K(1.72, P { $0.hipDX = 7; $0.squash = 1.08; $0.handL = CGPoint(x: -29, y: 16); $0.handR = CGPoint(x: 31, y: 8); $0.headOff.x = 7 }, .linear),
        K(1.9, P { $0.hipDX = -7; $0.squash = 0.9; $0.handL = CGPoint(x: -31, y: 10); $0.handR = CGPoint(x: 30, y: 14); $0.headOff.x = -7 }, .linear),
        K(2.08, P { $0.hipDX = 6; $0.squash = 1.07; $0.headOff.x = 6 }, .linear),
        // RESETEO: se agacha, re-agarra y respira antes de volver a probar
        K(2.34, P { $0.hipDX = 0; $0.squash = 0.9; $0.hipHeight = 48; $0.handL = CGPoint(x: -18, y: 26); $0.handR = CGPoint(x: 18, y: 26); $0.headOff = CGPoint(x: 0, y: -20); $0.neckOff = CGPoint(x: 0, y: -38); $0.footL = CGPoint(x: -15, y: 48); $0.footR = CGPoint(x: 15, y: 48) }, .linear)
    ])

    // La ROTURA de la caja v6 (NUEVO — el instante en que escapa en
    // AvA 1: no se desvanece, EXPLOTA hacia fuera). One-shot:
    // carga agachado empujando las paredes -> extension total con los
    // brazos lanzados -> vuelta en el aire recogido -> sale cayendo
    // (encadena con fallPose/landing).
    // CABLEADO SUGERIDO (integracion): al cumplirse escapingSince >
    // ~2-3 s, reproducir escapeBurst y liberar la caja.
    static let escapeBurst = AnimationClip(name: "romper-caja", duration: 0.85, loops: false, keyframes: [
        K(0.0, P { p in // cargado contra las paredes, a punto de reventar
            p.hipHeight = 46; p.squash = 0.82; p.neckOff = CGPoint(x: 0, y: -36); p.headOff = CGPoint(x: 0, y: -20)
            p.handL = CGPoint(x: -30, y: 10); p.handR = CGPoint(x: 30, y: 10)
            p.footL = CGPoint(x: -20, y: 46); p.footR = CGPoint(x: 20, y: 46)
        }, .snappy), // ¡ROMPE! extension total, brazos lanzados fuera
        K(0.16, P { p in
            p.hipHeight = 62; p.squash = 1.12; p.neckOff = CGPoint(x: 2, y: -46); p.headOff = CGPoint(x: 2, y: -24)
            p.handL = CGPoint(x: -38, y: -6); p.elbowL = CGPoint(x: -22, y: -8)
            p.handR = CGPoint(x: 38, y: -6); p.elbowR = CGPoint(x: 22, y: -8)
            p.footL = CGPoint(x: -16, y: 54); p.footR = CGPoint(x: 18, y: 52)
        }, .easeOut), // en el aire se recoge (vuelta corta)
        K(0.38, P { p in
            p.hipHeight = 58; p.squash = 0.94; p.neckOff = CGPoint(x: -6, y: -38); p.headOff = CGPoint(x: -4, y: -18)
            p.handL = CGPoint(x: -24, y: 18); p.handR = CGPoint(x: 24, y: 20)
            p.footL = CGPoint(x: -10, y: 44); p.kneeL = CGPoint(x: -14, y: 22)
            p.footR = CGPoint(x: 14, y: 40); p.kneeR = CGPoint(x: 16, y: 20)
        }, .easeIn), // sale cayendo, brazos abriendose para el aterrizaje
        K(0.62, P { p in
            p.hipHeight = 52; p.neckOff = CGPoint(x: -2, y: -40); p.headOff = CGPoint(x: 0, y: -21)
            p.handL = CGPoint(x: -28, y: 6); p.handR = CGPoint(x: 28, y: 8)
            p.footL = CGPoint(x: -14, y: 46); p.footR = CGPoint(x: 16, y: 44)
        }, .easeOut),
        K(0.85, P { p in // pose de caida lista para encadenar con landing
            p.hipHeight = 52; p.neckOff = CGPoint(x: 0, y: -42); p.headOff = CGPoint(x: 0, y: -22)
            p.handL = CGPoint(x: -24, y: 34); p.handR = CGPoint(x: 24, y: 34)
            p.footL = CGPoint(x: -13, y: 50); p.footR = CGPoint(x: 13, y: 50)
        }, .linear)
    ])

    static let squashed = AnimationClip(name: "aplastado", duration: 0.6, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .snappy),
        K(0.12, P { p in p.hipHeight = 26; p.squash = 0.55; p.headOff = CGPoint(x: 0, y: -15); p.neckOff.y = -24; p.footL = CGPoint(x: -24, y: 26); p.footR = CGPoint(x: 24, y: 26) }, .easeOut),
        K(0.38, P { p in p.hipHeight = 30; p.squash = 0.66 }, .easeInOut),
        K(0.6, P { p in p.hipHeight = 56; p.squash = 1.06 }, .easeOut) // rebota de vuelta
    ])

    static let thrownSpin = AnimationClip(name: "lanzado", duration: 0.7, loops: true, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -30, y: -14); p.handR = CGPoint(x: 28, y: 10) // brazos girando como aspas
            p.footL = CGPoint(x: -18, y: 40); p.footR = CGPoint(x: 20, y: 34)
        }, .linear),
        K(0.35, P { p in
            p.handL = CGPoint(x: -28, y: 12); p.handR = CGPoint(x: 30, y: -12)
            p.footL = CGPoint(x: -22, y: 32); p.footR = CGPoint(x: 16, y: 42)
        }, .linear)
    ])

    static let wallSlide = AnimationClip(name: "deslizarse-pared", duration: 0.6, loops: false, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -24, y: -18); p.handR = CGPoint(x: -22, y: 8) // manos contra la pared
            p.footL = CGPoint(x: -10, y: 44); p.footR = CGPoint(x: -4, y: 48); p.neckOff.x = -5
        }, .easeIn),
        K(0.6, P { p in p.handL = CGPoint(x: -24, y: -10); p.handR = CGPoint(x: -22, y: 14) })
    ])

    // -- Reacciones sociales / emociones --
    static let wave = AnimationClip(name: "saludar", duration: 1.0, loops: true, keyframes: [
        K(0.0, P { $0.handR = CGPoint(x: 26, y: -28); $0.elbowR = CGPoint(x: 17, y: -8) }, .easeInOut),
        K(0.25, P { $0.handR = CGPoint(x: 33, y: -25); $0.elbowR = CGPoint(x: 17, y: -8) }, .easeInOut),
        K(0.5, P { $0.handR = CGPoint(x: 25, y: -29); $0.elbowR = CGPoint(x: 17, y: -8) }, .easeInOut),
        K(0.75, P { $0.handR = CGPoint(x: 33, y: -25); $0.elbowR = CGPoint(x: 17, y: -8) }, .easeInOut)
    ])
    static let shrug = AnimationClip(name: "encogerse", duration: 1.2, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeOut),
        K(0.35, P { p in p.neckOff.y = -38; p.handL = CGPoint(x: -27, y: 22); p.handR = CGPoint(x: 27, y: 22); p.elbowL = CGPoint(x: -18, y: 26); p.elbowR = CGPoint(x: 18, y: 26) }, .easeInOut),
        K(0.85, P { p in p.neckOff.y = -38; p.handL = CGPoint(x: -27, y: 22); p.handR = CGPoint(x: 27, y: 22) }, .easeOut),
        K(1.2, SkeletonPose.standing)
    ])
    static let thumbsUp = AnimationClip(name: "pulgar-arriba", duration: 1.1, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .snappy),
        K(0.3, P { $0.handR = CGPoint(x: 30, y: 2); $0.elbowR = CGPoint(x: 18, y: 14); $0.hipHeight = 58 }, .easeOut),
        K(0.8, P { $0.handR = CGPoint(x: 30, y: 2); $0.elbowR = CGPoint(x: 18, y: 14) }, .easeInOut),
        K(1.1, SkeletonPose.standing)
    ])
    static let deny = AnimationClip(name: "negar", duration: 1.3, loops: false, keyframes: [
        K(0.0, P { p in p.handL = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -10, y: 24); p.headOff.x = -5 }, .easeInOut), // brazos cruzados
        K(0.4, P { $0.headOff.x = 6 }, .easeInOut),
        K(0.8, P { $0.headOff.x = -5 }, .easeInOut),
        K(1.3, P { $0.headOff.x = 0 })
    ])
    static let laugh = AnimationClip(name: "reir", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in p.neckOff.y = -39; p.headOff = CGPoint(x: 0, y: -20); p.handL = CGPoint(x: -14, y: 30); p.handR = CGPoint(x: 14, y: 30) }, .easeInOut), // se agarra la tripa, hombros tiemblan
        K(0.22, P { p in p.neckOff.y = -42; p.headOff.y = -23 }, .easeInOut),
        K(0.45, P { p in p.neckOff.y = -39; p.headOff.y = -20 }, .easeInOut),
        K(0.67, P { p in p.neckOff.y = -42; p.headOff.y = -23 }, .easeInOut)
    ])
    // v4: enfado con CUERPO: se hincha el pecho, echa la cabeza atras
    // y pega DOS pisotones con aguante de impacto, como el berrinche de AvA 1.
    static let stomp = AnimationClip(name: "enfadado-pisoton", duration: 1.45, loops: true, keyframes: [
        K(0.0, P { p in p.handL = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -10, y: 24); p.headOff.y = -20; p.neckOff = CGPoint(x: -2, y: -41) }, .easeIn), // se va hinchando de rabia
        K(0.25, P { p in p.neckOff = CGPoint(x: -4, y: -43); p.headOff = CGPoint(x: -2, y: -24); p.squash = 1.03; p.handL = CGPoint(x: 11, y: 22); p.handR = CGPoint(x: -11, y: 22) }, .snappy), // ¡levanta el pie muy alto!
        K(0.38, P { $0.footR = CGPoint(x: 17, y: 30); $0.kneeR = CGPoint(x: 15, y: 12); $0.neckOff.y = -42 }, .easeIn), // ¡PISOTON! cae con todo el peso
        K(0.5, P { p in p.footR = CGPoint(x: 17, y: 56); p.kneeR = CGPoint(x: 13, y: 27); p.squash = 0.9; p.hipHeight = 53; p.headOff.y = -19 }, .easeInOut), // AGUANTA clavado en el suelo
        K(0.68, P { p in p.footR = CGPoint(x: 17, y: 54); p.squash = 0.93; p.hipHeight = 54 }, .snappy), // ¡segundo pie arriba!
        K(0.82, P { $0.footL = CGPoint(x: -17, y: 30); $0.kneeL = CGPoint(x: -15, y: 12); $0.footR = CGPoint(x: 17, y: 56) }, .easeIn), // ¡PISOTON 2!
        K(0.95, P { p in p.footL = CGPoint(x: -17, y: 56); p.kneeL = CGPoint(x: -13, y: 27); p.squash = 0.9; p.hipHeight = 53; p.headOff.y = -19 }, .easeInOut), // aguanta, bufando
        K(1.2, P { p in p.squash = 0.96; p.hipHeight = 55; p.neckOff = CGPoint(x: -2, y: -41); p.headOff.y = -20 }, .easeInOut) // se va calmando (hasta el siguiente ciclo)
    ])
    // v4: panico en dos tiempos — primero el SUSTO (salto seco, manos a
    // la cabeza) y luego el temblor, como reacciona el stickman de AvA 1
    // cuando el cursor viene a por el.
    static let scared = AnimationClip(name: "asustado", duration: 0.85, loops: true, keyframes: [
        K(0.0, P { p in // ¡SUSTO! brinco con manos a la cabeza y stretch
            p.hipHeight = 61; p.squash = 1.09
            p.handL = CGPoint(x: -14, y: -34); p.elbowL = CGPoint(x: -17, y: -12)
            p.handR = CGPoint(x: 14, y: -34); p.elbowR = CGPoint(x: 17, y: -12)
            p.headOff = CGPoint(x: 0, y: -24)
            p.footL = CGPoint(x: -15, y: 48); p.footR = CGPoint(x: 15, y: 48)
        }, .easeOut), // cae de vuelta...
        K(0.16, P { p in
            p.hipHeight = 52; p.squash = 0.94
            p.handL = CGPoint(x: -24, y: -22); p.handR = CGPoint(x: 24, y: -22)
            p.footL = CGPoint(x: -14, y: 52); p.footR = CGPoint(x: 14, y: 52)
        }, .linear), // ...y se queda TEMBLANDO con las manos en alto
        K(0.28, P { $0.hipDX = -1.5; $0.handL = CGPoint(x: -25, y: -23); $0.handR = CGPoint(x: 23, y: -21) }, .linear),
        K(0.4, P { $0.hipDX = 1.5 }, .linear),
        K(0.52, P { $0.hipDX = -1.5; $0.hipHeight = 53 }, .linear),
        K(0.64, P { $0.hipDX = 1.5 }, .linear),
        K(0.76, P { $0.hipDX = 0; $0.hipHeight = 52 }, .linear)
    ])
    static let celebrate = AnimationClip(name: "celebrar", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in p.hipHeight = 46; p.squash = 0.9 }, .easeIn),
        K(0.3, P { p in p.hipHeight = 60; p.squash = 1.08; p.handL = CGPoint(x: -26, y: -30); p.handR = CGPoint(x: 26, y: -30); p.footL = CGPoint(x: -16, y: 48); p.footR = CGPoint(x: 16, y: 48) }, .easeOut), // salto con brazos arriba
        K(0.6, P { p in p.hipHeight = 52; p.handL = CGPoint(x: -24, y: -24); p.handR = CGPoint(x: 24, y: -24) }, .easeInOut)
    ])
    static let dance = AnimationClip(name: "bailar", duration: 3.2, loops: true, keyframes: [
        K(0.0, P { p in p.hipHeight = 52; p.footL = CGPoint(x: -22, y: 52); p.footR = CGPoint(x: 8, y: 52); p.handL = CGPoint(x: -24, y: -14); p.handR = CGPoint(x: 20, y: 30) }, .easeInOut), // paso lateral
        K(0.4, P { p in p.hipHeight = 55; p.footL = CGPoint(x: -6, y: 55); p.footR = CGPoint(x: 24, y: 55); p.handL = CGPoint(x: -18, y: 28); p.handR = CGPoint(x: 26, y: -12) }, .easeInOut),
        K(0.8, P { p in p.hipHeight = 52; p.footL = CGPoint(x: 10, y: 52); p.footR = CGPoint(x: -20, y: 52); p.handL = CGPoint(x: -24, y: -12); p.handR = CGPoint(x: 22, y: 28) }, .easeInOut),
        K(1.2, P { p in p.hipHeight = 58; p.handL = CGPoint(x: -28, y: -22); p.handR = CGPoint(x: 28, y: -22); p.footL = CGPoint(x: -14, y: 50); p.footR = CGPoint(x: 14, y: 50) }, .easeOut), // salto/gesto
        K(1.6, P { p in p.hipHeight = 53; p.neckOff.x = -6; p.footL = CGPoint(x: -26, y: 53); p.footR = CGPoint(x: -12, y: 53); p.handL = CGPoint(x: -10, y: 34); p.handR = CGPoint(x: 26, y: 10) }, .easeInOut), // moonwalk: se desliza atras inclinado
        K(2.2, P { p in p.hipHeight = 53; p.neckOff.x = -6; p.footL = CGPoint(x: -30, y: 53); p.footR = CGPoint(x: -16, y: 50); p.handR = CGPoint(x: 26, y: 10) }, .easeInOut),
        K(2.7, P { p in p.hipHeight = 50; p.squash = 0.92; p.handL = CGPoint(x: -26, y: 20); p.handR = CGPoint(x: 26, y: 20) }, .easeIn), // prepara giro
        K(3.0, P { p in p.hipHeight = 57; p.handL = CGPoint(x: -28, y: -18); p.handR = CGPoint(x: 28, y: -18) }, .easeOut) // giro con brazos fuera
    ])
    static let proud = AnimationClip(name: "orgulloso", duration: 1.8, loops: true, keyframes: [
        K(0.0, P { p in p.neckOff = CGPoint(x: -3, y: -43); p.headOff.y = -25; p.handL = CGPoint(x: -4, y: 4); p.elbowL = CGPoint(x: -20, y: 20); p.handR = CGPoint(x: 4, y: 4); p.elbowR = CGPoint(x: 20, y: 20) }, .easeInOut), // manos en la cadera, pecho fuera
        K(0.9, P { p in p.neckOff.y = -44; p.headOff.y = -26 }, .easeInOut)
    ])
    static let yawn = AnimationClip(name: "bostezar", duration: 1.6, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeInOut),
        K(0.5, P { p in p.handR = CGPoint(x: 11, y: -15); p.elbowR = CGPoint(x: 15, y: 8); p.headOff = CGPoint(x: 2, y: -20); p.neckOff.y = -39 }, .easeInOut),
        K(1.1, P { p in p.handR = CGPoint(x: 11, y: -15); p.headOff.y = -19 }, .easeOut),
        K(1.6, SkeletonPose.standing)
    ])
    static let sitBored = AnimationClip(name: "sentado-aburrido", duration: 3.0, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 4, y: -32); p.headOff = CGPoint(x: 5, y: -19)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
            p.handL = CGPoint(x: -10, y: 20); p.handR = CGPoint(x: 12, y: -8); p.elbowR = CGPoint(x: 16, y: 10) // cabeza apoyada en la mano
        }, .easeInOut),
        K(1.5, P { p in p.neckOff.y = -30; p.headOff.y = -17 }, .easeInOut) // suspira y se hunde
    ])
    static let sit = AnimationClip(name: "sentado", duration: 2.6, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
            p.handL = CGPoint(x: -10, y: 24); p.handR = CGPoint(x: 10, y: 24)
        }, .easeInOut),
        K(1.3, P { p in p.neckOff.y = -33 }, .easeInOut)
    ])
    // Dormir v6: respiracion mas lenta y PROFUNDA (ciclo 4.2 s, el
    // pecho baja a 11 y sube a 12.5 — en la v4 apenas 1 pt en 3.4 s)
    // y un TIC DE SUENO por ciclo: el pie derecho pega una patadita
    // involuntaria (~.2 s) y todo vuelve a la calma. Es el detalle
    // que en los videos separa "estatua tumbada" de "personaje vivo".
    static let sleep = AnimationClip(name: "dormir", duration: 4.2, loops: true, keyframes: [
        K(0.0, P { p in // tumbado de lado, espira
            p.hipHeight = 11; p.neckOff = CGPoint(x: -32, y: -3); p.headOff = CGPoint(x: -19, y: -2)
            p.footL = CGPoint(x: 44, y: 9); p.kneeL = CGPoint(x: 22, y: 5)
            p.footR = CGPoint(x: 42, y: 3); p.kneeR = CGPoint(x: 20, y: 1)
            p.handL = CGPoint(x: -10, y: 8); p.handR = CGPoint(x: -16, y: 6)
        }, .easeInOut), // inspira: el cuerpo entero se hincha un pelo
        K(1.05, P { p in p.hipHeight = 12.5; p.neckOff = CGPoint(x: -32, y: -4.5) }, .easeInOut), // espira
        K(2.1, P { p in p.hipHeight = 11; p.neckOff = CGPoint(x: -32, y: -3) }, .easeInOut), // inspira otra vez
        K(3.15, P { p in p.hipHeight = 12; p.neckOff = CGPoint(x: -32, y: -4) }, .snappy), // ¡TIC! patadita involuntaria del pie derecho
        K(3.35, P { p in p.footR = CGPoint(x: 47, y: 0); p.kneeR = CGPoint(x: 23, y: -1) }, .easeOut), // el pie vuelve a su sitio...
        K(3.6, P { p in p.footR = CGPoint(x: 42, y: 3); p.kneeR = CGPoint(x: 20, y: 1); p.hipHeight = 11.5 }, .easeInOut) // ...y la respiracion sigue como si nada hasta el cierre
    ])
    static let hide = AnimationClip(name: "esconderse", duration: 1.4, loops: true, keyframes: [
        K(0.0, P { p in // agazapado tras el objeto, asoma la cabeza
            p.hipHeight = 30; p.squash = 0.85; p.neckOff = CGPoint(x: 4, y: -28); p.headOff = CGPoint(x: 9, y: -19)
            p.kneeL = CGPoint(x: -15, y: 12); p.footL = CGPoint(x: -14, y: 30)
            p.kneeR = CGPoint(x: 15, y: 12); p.footR = CGPoint(x: 14, y: 30)
            p.handL = CGPoint(x: -6, y: 16); p.handR = CGPoint(x: 14, y: 10)
        }, .easeInOut),
        K(0.7, P { p in p.headOff.x = 12 }, .easeInOut)
    ])

    // -- Herramientas (como en los videos) --
    static let drawWithPencil = AnimationClip(name: "dibujar-lapiz", duration: 1.0, loops: true, keyframes: [
        K(0.0, P { p in // lapiz grande con las DOS manos, con esfuerzo
            p.neckOff = CGPoint(x: 7, y: -38); p.hipHeight = 50
            p.handL = CGPoint(x: 24, y: 26); p.elbowL = CGPoint(x: 8, y: 22)
            p.handR = CGPoint(x: 30, y: 32); p.elbowR = CGPoint(x: 16, y: 26)
            p.footL = CGPoint(x: -16, y: 50); p.footR = CGPoint(x: 18, y: 50)
        }, .easeInOut),
        K(0.3, P { p in p.handL = CGPoint(x: 28, y: 30); p.handR = CGPoint(x: 34, y: 36); p.neckOff.y = -36 }, .easeInOut), // trazo
        K(0.55, P { p in p.handL = CGPoint(x: 22, y: 22); p.handR = CGPoint(x: 28, y: 27) }, .easeInOut), // levanta
        K(0.8, P { p in p.handL = CGPoint(x: 27, y: 29); p.handR = CGPoint(x: 33, y: 35); p.neckOff.y = -36 }, .easeInOut) // otro trazo
    ])
    static let eraseRub = AnimationClip(name: "borrar-goma", duration: 0.8, loops: true, keyframes: [
        K(0.0, P { p in p.neckOff = CGPoint(x: 6, y: -38); p.handR = CGPoint(x: 26, y: 30); p.elbowR = CGPoint(x: 14, y: 22); p.hipHeight = 51 }, .easeInOut),
        K(0.2, P { $0.handR = CGPoint(x: 36, y: 33) }, .easeInOut), // frota a un lado
        K(0.4, P { $0.handR = CGPoint(x: 25, y: 29) }, .easeInOut), // y al otro
        K(0.6, P { $0.handR = CGPoint(x: 36, y: 33) }, .easeInOut)
    ])
    static let swordFence = AnimationClip(name: "esgrima", duration: 2.2, loops: true, keyframes: [
        K(0.0, P { p in // en guardia, paso de esgrima
            p.hipHeight = 49; p.neckOff = CGPoint(x: 6, y: -40)
            p.footL = CGPoint(x: -20, y: 49); p.footR = CGPoint(x: 24, y: 49)
            p.handR = CGPoint(x: 34, y: 10); p.elbowR = CGPoint(x: 18, y: 10)
            p.handL = CGPoint(x: -18, y: 16)
        }, .snappy),
        K(0.4, P { p in // estocada: se lanza entero
            p.hipHeight = 47; p.neckOff = CGPoint(x: 13, y: -39); p.hipDX = 6
            p.footL = CGPoint(x: -26, y: 47); p.footR = CGPoint(x: 30, y: 47)
            p.handR = CGPoint(x: 52, y: 6); p.elbowR = CGPoint(x: 30, y: 7)
        }, .easeIn),
        K(0.8, P { p in // molinete: espada en circulo (mano alta y cruzada)
            p.handR = CGPoint(x: 18, y: -30); p.elbowR = CGPoint(x: 20, y: -8)
        }, .snappy),
        K(1.2, P { p in // tajo descendente
            p.handR = CGPoint(x: 40, y: 26); p.elbowR = CGPoint(x: 26, y: 6); p.hipHeight = 48
        }, .easeInOut),
        K(1.7, P { p in // guardia otra vez
            p.hipHeight = 49; p.handR = CGPoint(x: 34, y: 10); p.elbowR = CGPoint(x: 18, y: 10)
        }, .easeInOut)
    ])
    static let hammering = AnimationClip(name: "martillo", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: 22, y: -26); p.elbowR = CGPoint(x: 16, y: -4); p.neckOff = CGPoint(x: 4, y: -40) }, .easeIn), // levanta el martillo (anticipacion lenta)
        K(0.45, P { p in p.handR = CGPoint(x: 30, y: 18); p.elbowR = CGPoint(x: 18, y: 10); p.neckOff.y = -36; p.squash = 0.96 }, .easeOut), // GOLPE rapido
        K(0.62, P { p in p.handR = CGPoint(x: 29, y: 15) }, .easeInOut)
    ])
    // Trepar v6: la v4 alternaba las manos simetrico con easeInOut —
    // leia como "nadar en el sitio". Trepar de verdad (spec y videos)
    // tiene dos fases distintas por mano: ALCANCE rapido y ligero
    // (la mano sube y agarra) y TIRON fuerte y mas lento (los codos
    // se cierran, el cuerpo se pega a la pared, el pie contrario
    // empuja). Ciclo asimetrico alcance-tiron-alcance-tiron.
    static let climb = AnimationClip(name: "trepar", duration: 0.7, loops: true, keyframes: [
        K(0.0, P { p in // mano derecha acaba de agarrar ARRIBA; izquierda sujeta abajo
            p.handL = CGPoint(x: -14, y: -13); p.elbowL = CGPoint(x: -15, y: -6)
            p.handR = CGPoint(x: 15, y: -29); p.elbowR = CGPoint(x: 17, y: -14)
            p.footL = CGPoint(x: -11, y: 47); p.kneeL = CGPoint(x: -13, y: 24) // pie izquierdo empujando
            p.footR = CGPoint(x: 11, y: 37); p.kneeR = CGPoint(x: 13, y: 17)   // derecho buscando apoyo
        }, .easeInOut), // TIRON derecho: codos se cierran, cuerpo sube y se pega
        K(0.17, P { p in
            p.handL = CGPoint(x: -14, y: -14); p.elbowL = CGPoint(x: -16, y: -6)
            p.handR = CGPoint(x: 14, y: -19); p.elbowR = CGPoint(x: 21, y: -4)
            p.footL = CGPoint(x: -10, y: 48); p.footR = CGPoint(x: 12, y: 47) // el pie derecho planta
            p.kneeR = CGPoint(x: 13, y: 24)
            p.squash = 0.97; p.neckOff = CGPoint(x: 0, y: -41)
        }, .easeOut), // ALCANCE izquierdo: rapido y ligero, la mano vuela arriba
        K(0.35, P { p in
            p.handL = CGPoint(x: -16, y: -30); p.elbowL = CGPoint(x: -17, y: -15)
            p.handR = CGPoint(x: 14, y: -19); p.elbowR = CGPoint(x: 20, y: -5)
            p.footL = CGPoint(x: -9, y: 37); p.kneeL = CGPoint(x: -12, y: 17) // pie izquierdo buscando apoyo
            p.footR = CGPoint(x: 11, y: 47)
            p.squash = 1.0; p.neckOff = CGPoint(x: 0, y: -42)
        }, .easeInOut), // TIRON izquierdo
        K(0.52, P { p in
            p.handL = CGPoint(x: -15, y: -20); p.elbowL = CGPoint(x: -21, y: -4)
            p.handR = CGPoint(x: 15, y: -13); p.elbowR = CGPoint(x: 16, y: -6)
            p.footL = CGPoint(x: -11, y: 47); p.footR = CGPoint(x: 9, y: 37)
            p.kneeL = CGPoint(x: -13, y: 24); p.kneeR = CGPoint(x: 12, y: 17)
            p.squash = 0.97; p.neckOff = CGPoint(x: 0, y: -41)
        }, .easeOut) // el cierre de bucle es el ALCANCE derecho siguiente
    ])
    static let playBall = AnimationClip(name: "jugar-pelota", duration: 0.84, loops: true, keyframes: [
        K(0.0, P { $0.handL = CGPoint(x: -24, y: 30); $0.handR = CGPoint(x: 24, y: 30) }, .easeInOut),
        K(0.42, P { $0.hipHeight = 52; $0.footR = CGPoint(x: 22, y: 40); $0.kneeR = CGPoint(x: 16, y: 18) }, .easeInOut) // toquecito con el pie
    ])

    // -- Chosen One (AvA2) --
    // Vuelo v6: la v4 era una pose casi estatica con un micro-ajuste;
    // en AvA 2 TCO vuela con BALANCEO de cuerpo entero (sube y baja
    // como un delfin, "porpoising") y las piernas hacen una tijera
    // lenta de natacion. Stretch constante (1.05-1.07): a velocidad,
    // el cuerpo se ALARGA. La estela la dibuja el motor de poderes;
    // el clip aporta el ritmo al que la estela "respira".
    static let flyPose = AnimationClip(name: "volar", duration: 1.2, loops: true, keyframes: [
        K(0.0, P { p in // tipo superman: un puño delante, cuerpo recto inclinado y ESTIRADO
            p.neckOff = CGPoint(x: 14, y: -38); p.headOff = CGPoint(x: 7, y: -20); p.squash = 1.06
            p.handR = CGPoint(x: 44, y: -6); p.elbowR = CGPoint(x: 24, y: -4)
            p.handL = CGPoint(x: -14, y: 22); p.elbowL = CGPoint(x: -16, y: 8)
            p.footL = CGPoint(x: -40, y: 16); p.kneeL = CGPoint(x: -20, y: 10)
            p.footR = CGPoint(x: -36, y: 24); p.kneeR = CGPoint(x: -18, y: 15)
        }, .easeInOut), // cresta del balanceo: el cuerpo sube y se arquea
        K(0.3, P { p in
            p.neckOff = CGPoint(x: 15, y: -40); p.headOff = CGPoint(x: 8, y: -21); p.squash = 1.07
            p.footL = CGPoint(x: -38, y: 21); p.footR = CGPoint(x: -39, y: 15) // tijera: las piernas se cruzan
            p.handL = CGPoint(x: -16, y: 24)
        }, .easeInOut), // valle: cae un pelo, cuerpo mas plano
        K(0.6, P { p in
            p.neckOff = CGPoint(x: 13, y: -36); p.headOff = CGPoint(x: 6, y: -19); p.squash = 1.05
            p.footL = CGPoint(x: -41, y: 18); p.footR = CGPoint(x: -35, y: 22)
            p.handL = CGPoint(x: -12, y: 20)
        }, .easeInOut), // segunda cresta (el balanceo en los videos no es perfectamente periodico)
        K(0.9, P { p in
            p.neckOff = CGPoint(x: 14, y: -39); p.headOff = CGPoint(x: 7, y: -20); p.squash = 1.06
            p.footL = CGPoint(x: -39, y: 15); p.footR = CGPoint(x: -37, y: 25)
            p.handL = CGPoint(x: -15, y: 23)
        }, .easeInOut)
    ])
    // Rafaga de supervelocidad v6 (NUEVO — los dashes de AvA 2 en los
    // que TCO se convierte en una linea horizontal): cuerpo TOTALMENTE
    // horizontal, brazos pegados atras como alas, piernas juntas
    // estiradas, stretch maximo (1.12). Es una pose de "postura de
    // flecha" con micro-vibracion de velocidad, no un vuelo tranquilo.
    // CABLEADO SUGERIDO (integracion): salidas explosivas de huida y
    // embestidas en modo Chosen One.
    static let flyDash = AnimationClip(name: "rafaga", duration: 0.7, loops: true, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: 20, y: -30); p.headOff = CGPoint(x: 10, y: -15); p.squash = 1.12
            p.handL = CGPoint(x: -24, y: 10); p.elbowL = CGPoint(x: -14, y: 4)
            p.handR = CGPoint(x: -20, y: 17); p.elbowR = CGPoint(x: -11, y: 9)
            p.footL = CGPoint(x: -44, y: 22); p.kneeL = CGPoint(x: -23, y: 13)
            p.footR = CGPoint(x: -42, y: 28); p.kneeR = CGPoint(x: -22, y: 17)
        }, .linear), // micro-vibracion de velocidad (lineal, +-1)
        K(0.12, P { p in p.neckOff.y = -29; p.headOff.y = -14; p.footL.y = 23; p.footR.y = 27 }, .linear),
        K(0.24, P { p in p.neckOff.y = -31; p.headOff.y = -16; p.footL.y = 21; p.footR.y = 29 }, .linear),
        K(0.36, P { p in p.neckOff.y = -30; p.headOff.y = -15; p.footL.y = 22; p.footR.y = 28 }, .linear),
        K(0.5, P { p in // respiro del dash: se descomprime un instante sin perder la flecha
            p.squash = 1.09; p.neckOff = CGPoint(x: 19, y: -31); p.headOff = CGPoint(x: 9, y: -16)
        }, .linear)
    ])
    // v6 (AvA 2): la carga de energia de TCO. La v4 ya crecia en
    // amplitud (1->3) pero a ritmo CONSTANTE; en el video el temblor
    // ademas ACELERA: los intervalos se encogen (.25 -> .18 -> .16 ->
    // .14 -> .12 -> .10) mientras la amplitud sube 1->2->3->4->5->6,
    // como una olla a presion. La explosion llega un pelo antes
    // (1.62) porque la rampa es mas densa.
    static let chargePower = AnimationClip(name: "cargar-energia", duration: 1.9, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.55, P { p in // se agacha cargando, puños a los lados, primer temblor
            p.hipHeight = 41; p.squash = 0.89; p.neckOff = CGPoint(x: 0, y: -35)
            p.handL = CGPoint(x: -23, y: 23); p.handR = CGPoint(x: 23, y: 23)
            p.elbowL = CGPoint(x: -17, y: 16); p.elbowR = CGPoint(x: 17, y: 16)
            p.footL = CGPoint(x: -21, y: 41); p.footR = CGPoint(x: 21, y: 41)
        }, .linear), // temblor: amplitud creciente, frecuencia creciente
        K(0.8, P { $0.hipDX = -1; $0.hipHeight = 41 }, .linear),
        K(0.98, P { $0.hipDX = 2; $0.hipHeight = 40 }, .linear),
        K(1.14, P { $0.hipDX = -3; $0.hipHeight = 40; $0.squash = 0.88 }, .linear),
        K(1.28, P { $0.hipDX = 4; $0.hipHeight = 39 }, .linear),
        K(1.4, P { $0.hipDX = -5; $0.hipHeight = 39; $0.squash = 0.86 }, .linear),
        K(1.5, P { $0.hipDX = 6; $0.hipHeight = 38 }, .easeOut), // ¡ESTALLA el aura! se yergue de golpe
        K(1.62, P { p in
            p.hipHeight = 59; p.squash = 1.08; p.hipDX = 0
            p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.handL = CGPoint(x: -26, y: -22); p.handR = CGPoint(x: 26, y: -22)
            p.elbowL = CGPoint(x: -18, y: -4); p.elbowR = CGPoint(x: 18, y: -4)
            p.footL = CGPoint(x: -19, y: 53); p.footR = CGPoint(x: 19, y: 53)
        }, .easeInOut), // aguanta en la pose de poder, aura fuera
        K(1.9, P { p in p.hipHeight = 58; p.squash = 1.05; p.handL = CGPoint(x: -25, y: -20); p.handR = CGPoint(x: 25, y: -20) })
    ])
    // Fuego v6 (AvA 2): la v4 era una pose inclinada que se balanceaba
    // — no habia ATAQUE. En el video lanzar fuego tiene fases claras
    // y el bucle las recorre enteras: CARGA (se echa atras, junta las
    // manos al pecho reuniendo la llama) -> DESCARGA seca (.12, las
    // dos manos empujan el chorro) -> SOSTENIDO con temblor de
    // retroceso (el chorro le empuja el cuerpo hacia atras, las manos
    // vibran +-2) -> RECUPERACION corta y vuelta a cargar.
    static let firePose = AnimationClip(name: "fuego", duration: 1.1, loops: true, keyframes: [
        K(0.0, P { p in // empieza a reunir: manos bajas viniendo hacia el pecho
            p.neckOff = CGPoint(x: 2, y: -41); p.headOff = CGPoint(x: 1, y: -22); p.hipHeight = 52; p.squash = 0.98
            p.handL = CGPoint(x: 14, y: 20); p.handR = CGPoint(x: 20, y: 24)
            p.footL = CGPoint(x: -18, y: 52); p.footR = CGPoint(x: 18, y: 52)
        }, .easeIn), // CARGA: se echa atras apretando la llama entre las manos
        K(0.28, P { p in
            p.neckOff = CGPoint(x: -3, y: -40); p.headOff = CGPoint(x: -1, y: -21); p.hipHeight = 51; p.squash = 0.96
            p.handL = CGPoint(x: 18, y: 14); p.handR = CGPoint(x: 24, y: 18)
            p.footL = CGPoint(x: -19, y: 51); p.footR = CGPoint(x: 17, y: 51)
        }, .snappy), // ¡DESCARGA! empuje con las dos manos, torso volcado en el chorro
        K(0.4, P { p in
            p.neckOff = CGPoint(x: 15, y: -37); p.headOff = CGPoint(x: 7, y: -20); p.hipHeight = 50; p.squash = 1.02; p.hipDX = 3
            p.handL = CGPoint(x: 46, y: 6); p.elbowL = CGPoint(x: 26, y: 8)
            p.handR = CGPoint(x: 50, y: 12); p.elbowR = CGPoint(x: 29, y: 13)
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 15, y: 50)
        }, .linear), // SOSTENIDO: el retroceso le empuja y las manos vibran
        K(0.52, P { p in p.handL = CGPoint(x: 44, y: 8); p.handR = CGPoint(x: 48, y: 10); p.hipDX = 1; p.neckOff.x = 13 }, .linear),
        K(0.62, P { p in p.handL = CGPoint(x: 47, y: 5); p.handR = CGPoint(x: 51, y: 13); p.hipDX = 0; p.neckOff.x = 14 }, .linear),
        K(0.72, P { p in p.handL = CGPoint(x: 44, y: 7); p.handR = CGPoint(x: 48, y: 11); p.hipDX = 1; p.neckOff.x = 13 }, .easeInOut), // corta el chorro y recupera
        K(0.92, P { p in
            p.neckOff = CGPoint(x: 8, y: -39); p.headOff = CGPoint(x: 4, y: -21); p.hipHeight = 51
            p.handL = CGPoint(x: 34, y: 16); p.handR = CGPoint(x: 38, y: 20)
            p.footL = CGPoint(x: -19, y: 51); p.footR = CGPoint(x: 17, y: 51)
        }, .easeInOut) // el cierre de bucle lo devuelve a reunir la siguiente llama
    ])
    // Laser v6 (AvA 2): misma idea — la v4 era una cabeza ladeada en
    // bucle. Fases: TENSION previa (aprieta, squash .97) -> DISPARO
    // seco (.08): la cabeza sale hacia delante y el RETROCESO la
    // empuja atras, el cuerpo se atrinchera con las piernas abiertas
    // y los puños atras -> SOSTENIDO con vibracion de cabeza (+-1.5,
    // es lo que vende la potencia del rayo) -> corte y sacudida.
    static let laserPose = AnimationClip(name: "laser", duration: 1.0, loops: true, keyframes: [
        K(0.0, P { p in // tension previa: puños apretados a los lados, cuerpo rigido
            p.neckOff = CGPoint(x: -2, y: -42); p.headOff = CGPoint(x: -1, y: -23); p.squash = 0.99
            p.handL = CGPoint(x: -22, y: 26); p.handR = CGPoint(x: 22, y: 26)
            p.footL = CGPoint(x: -17, y: 56); p.footR = CGPoint(x: 17, y: 56)
        }, .easeIn), // CARGA: la cabeza se recoge un pelo, todo se aprieta
        K(0.2, P { p in
            p.neckOff = CGPoint(x: -4, y: -40); p.headOff = CGPoint(x: -3, y: -21); p.squash = 0.97
            p.handL = CGPoint(x: -23, y: 27); p.handR = CGPoint(x: 23, y: 27)
        }, .snappy), // ¡DISPARO! el retroceso le echa la cabeza atras y se atrinchera
        K(0.28, P { p in
            p.neckOff = CGPoint(x: -8, y: -41); p.headOff = CGPoint(x: -6, y: -25); p.hipDX = -2
            p.handL = CGPoint(x: -26, y: 28); p.handR = CGPoint(x: 26, y: 28)
            p.footL = CGPoint(x: -20, y: 56); p.footR = CGPoint(x: 20, y: 56)
        }, .linear), // SOSTENIDO: vibracion de cabeza y cuello (la fuerza del rayo)
        K(0.42, P { p in p.headOff = CGPoint(x: -5, y: -24); p.neckOff.x = -7 }, .linear),
        K(0.54, P { p in p.headOff = CGPoint(x: -7, y: -25); p.neckOff.x = -9; p.hipDX = -3 }, .linear),
        K(0.66, P { p in p.headOff = CGPoint(x: -5, y: -24); p.neckOff.x = -7; p.hipDX = -2 }, .easeOut), // corta el rayo: sacude la cabeza
        K(0.84, P { p in
            p.neckOff = CGPoint(x: -4, y: -41); p.headOff = CGPoint(x: -2, y: -22); p.hipDX = -1
            p.handL = CGPoint(x: -23, y: 26); p.handR = CGPoint(x: 23, y: 26)
            p.footL = CGPoint(x: -18, y: 56); p.footR = CGPoint(x: 18, y: 56)
        }, .easeInOut) // el cierre de bucle vuelve a la tension previa
    ])
    // v4 (AvA 2): superpuñetazo con anticipacion LARGA — TCO carga el
    // brazo muy atras, da el paso enorme... y el golpe sale seco, se
    // aguanta clavado y solo entonces recoge.
    static let superPunchPose = AnimationClip(name: "superpunetazo", duration: 1.15, loops: false, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: -4, y: 18); p.neckOff.x = -3 }, .easeIn), // empieza a cargar
        K(0.3, P { p in // carga MAXIMA: puño muy atras, torso girado, peso atras
            p.handR = CGPoint(x: -16, y: 12); p.elbowR = CGPoint(x: -14, y: 16)
            p.neckOff = CGPoint(x: -7, y: -40); p.headOff = CGPoint(x: -3, y: -22)
            p.hipHeight = 49; p.squash = 0.93; p.hipDX = -3
            p.footL = CGPoint(x: -14, y: 49); p.footR = CGPoint(x: 16, y: 49)
            p.handL = CGPoint(x: 14, y: 10)
        }, .easeIn), // aguanta la carga un instante (tension)...
        K(0.45, P { p in p.handR = CGPoint(x: -17, y: 11); p.neckOff.x = -8; p.hipDX = -4 }, .snappy), // ...paso enorme Y GOLPE con todo el cuerpo
        K(0.58, P { p in // IMPACTO: extension total, cadera y hombro volcados
            p.neckOff = CGPoint(x: 17, y: -38); p.hipDX = 9; p.hipHeight = 52; p.squash = 1.02
            p.handR = CGPoint(x: 58, y: 2); p.elbowR = CGPoint(x: 32, y: 3)
            p.footL = CGPoint(x: -27, y: 52); p.footR = CGPoint(x: 22, y: 52)
            p.kneeL = CGPoint(x: -15, y: 27); p.kneeR = CGPoint(x: 13, y: 27)
            p.handL = CGPoint(x: -22, y: 20)
        }, .linear), // v6: VIBRACION de impacto — el puño clavado TIEMBLA .12 (la onda de choque sale del brazo)
        K(0.64, P { p in p.handR = CGPoint(x: 55, y: 0); p.neckOff.x = 15; p.hipDX = 8 }, .linear),
        K(0.7, P { p in p.handR = CGPoint(x: 58, y: 3); p.neckOff.x = 17; p.hipDX = 9 }, .easeInOut), // el temblor muere y el golpe queda clavado un instante mas
        K(0.82, P { p in p.handR = CGPoint(x: 56, y: 3); p.neckOff.x = 16; p.hipDX = 8 }, .easeIn), // recoge despacio, sobrado
        K(1.15, P { p in p.handR = CGPoint(x: 28, y: 12); p.neckOff.x = 5; p.hipDX = 2; p.hipHeight = 54 }, .softLanding)
    ])
    // Superfuerza v6: sostener el bloque ya no es un bucle plano: el
    // peso le hace CEDER las rodillas una vez por ciclo (baja 4 pt,
    // squash .93) y el se rehace empujando hacia arriba — ese
    // ceder-y-recuperar es el ciclo de esfuerzo de AvA 2/4.
    static let strengthPose = AnimationClip(name: "superfuerza", duration: 1.6, loops: true, keyframes: [
        K(0.0, P { p in // bloque sobre la cabeza, piernas plantadas
            p.handL = CGPoint(x: -17, y: -34); p.handR = CGPoint(x: 17, y: -34)
            p.elbowL = CGPoint(x: -16, y: -10); p.elbowR = CGPoint(x: 16, y: -10)
            p.hipHeight = 51; p.footL = CGPoint(x: -17, y: 51); p.footR = CGPoint(x: 17, y: 51)
        }, .linear), // temblor de esfuerzo, lineal
        K(0.5, P { p in p.hipHeight = 50; p.hipDX = -1; p.handL.y = -33; p.handR.y = -33 }, .easeIn), // el peso GANA un instante: las rodillas ceden
        K(1.0, P { p in
            p.hipHeight = 47; p.squash = 0.93; p.hipDX = 1
            p.handL = CGPoint(x: -16, y: -30); p.handR = CGPoint(x: 16, y: -30)
            p.footL = CGPoint(x: -18, y: 47); p.footR = CGPoint(x: 18, y: 47)
        }, .easeOut), // EMPUJA de vuelta arriba con las piernas
        K(1.35, P { p in p.hipHeight = 52; p.squash = 1.01; p.handL = CGPoint(x: -17, y: -35); p.handR = CGPoint(x: 17, y: -35); p.footL = CGPoint(x: -17, y: 52); p.footR = CGPoint(x: 17, y: 52) }, .easeInOut) // y asienta para el siguiente ciclo de esfuerzo
    ])
    // v4 (AvA 2): la pose de poder ENTRA, no aparece: se agacha
    // cargando, EXPLOTA hacia arriba con el puño al cielo y aguanta.
    static let powerPose = AnimationClip(name: "pose-poder", duration: 1.8, loops: true, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn), // carga agachandose
        K(0.4, P { p in
            p.hipHeight = 43; p.squash = 0.89; p.neckOff = CGPoint(x: 0, y: -36)
            p.handL = CGPoint(x: -21, y: 24); p.handR = CGPoint(x: 21, y: 24)
            p.footL = CGPoint(x: -20, y: 43); p.footR = CGPoint(x: 20, y: 43)
        }, .snappy), // ¡EXPLOTA! puño al cielo, cuerpo estirado
        K(0.58, P { p in
            p.hipHeight = 60; p.squash = 1.09; p.neckOff = CGPoint(x: -2, y: -44); p.headOff = CGPoint(x: -1, y: -25)
            p.handR = CGPoint(x: 16, y: -46); p.elbowR = CGPoint(x: 13, y: -22)
            p.handL = CGPoint(x: -8, y: 6); p.elbowL = CGPoint(x: -20, y: 18)
            p.footL = CGPoint(x: -16, y: 54); p.footR = CGPoint(x: 16, y: 54)
        }, .easeInOut), // AGUANTA la pose, sobrado (con micro-temblor de poder)
        K(1.1, P { p in p.handR = CGPoint(x: 17, y: -45); p.neckOff.y = -45; p.hipHeight = 59 }, .easeInOut),
        K(1.5, P { p in p.handR = CGPoint(x: 16, y: -46); p.hipHeight = 60; p.squash = 1.08 }, .easeIn) // y vuelve a cargar para el ciclo
    ])

    // MARK: v3 — Superficies (pared / techo / bordes)

    /// Colgarse de una pared v6: pendulo de 2.4 s (la v4 hacia un
    /// vaiven de 1.8 sin extremos definidos). Las piernas van con
    /// RETRASO respecto a la cadera (pendulo fisico: el cuerpo pasa
    /// y las piernas llegan despues) y en un extremo BAJA LA MIRADA
    /// a ver donde pondria los pies — gesto tipico de los videos.
    static let hangWall = AnimationClip(name: "colgarse-pared", duration: 2.4, loops: true, keyframes: [
        K(0.0, P { p in // centro del pendulo
            p.handR = CGPoint(x: 6, y: -52); p.elbowR = CGPoint(x: 10, y: -26) // mano agarrada arriba
            p.handL = CGPoint(x: -18, y: 6); p.hipHeight = 52
            p.footL = CGPoint(x: -12, y: 50); p.footR = CGPoint(x: 10, y: 52)
        }, .easeInOut), // extremo A: la cadera llega, las piernas aun no
        K(0.6, P { p in
            p.hipDX = 3; p.footL = CGPoint(x: -9, y: 50); p.footR = CGPoint(x: 13, y: 52)
        }, .easeInOut), // centro de vuelta (las piernas ya pasaron)
        K(1.2, P { p in
            p.hipDX = 0; p.footL = CGPoint(x: -13, y: 50); p.footR = CGPoint(x: 9, y: 52)
        }, .easeInOut), // extremo B: y aqui mira hacia ABAJO
        K(1.8, P { p in
            p.hipDX = -3; p.headOff = CGPoint(x: 2, y: -19)
            p.footL = CGPoint(x: -16, y: 50); p.footR = CGPoint(x: 6, y: 52)
        }, .easeInOut) // el cierre de bucle vuelve al centro subiendo la mirada
    ])
    /// Colgarse del techo v6: mismo pendulo de 2.4 s con los dos
    /// brazos al ancla; las piernas colgando arrastran detras de la
    /// cadera medio tiempo, como un peso muerto que balancea.
    static let hangCeil = AnimationClip(name: "colgarse-techo", duration: 2.4, loops: true, keyframes: [
        K(0.0, P { p in // centro
            p.handL = CGPoint(x: -10, y: -50); p.elbowL = CGPoint(x: -12, y: -24)
            p.handR = CGPoint(x: 10, y: -50); p.elbowR = CGPoint(x: 12, y: -24)
            p.footL = CGPoint(x: -13, y: 54); p.footR = CGPoint(x: 13, y: 54)
        }, .easeInOut), // extremo A
        K(0.6, P { p in
            p.hipDX = 3; p.footL = CGPoint(x: -9, y: 54); p.footR = CGPoint(x: 16, y: 54)
        }, .easeInOut), // centro
        K(1.2, P { p in
            p.hipDX = 0; p.footL = CGPoint(x: -14, y: 54); p.footR = CGPoint(x: 12, y: 54)
        }, .easeInOut), // extremo B
        K(1.8, P { p in
            p.hipDX = -3; p.footL = CGPoint(x: -17, y: 54); p.footR = CGPoint(x: 9, y: 54)
        }, .easeInOut)
    ])
    /// Caminar boca abajo por el techo (set `swing` de la spec, 8 poses):
    /// brazos agarrados arriba alternando, piernas colgando que se balancean.
    /// La vista lo dibuja INVERTIDO (ancla en el techo).
    static let swingCeil = AnimationClip(name: "techo-swing", duration: 0.88, loops: true, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -22, y: -48); p.elbowL = CGPoint(x: -14, y: -24)
            p.handR = CGPoint(x: 4, y: -50); p.elbowR = CGPoint(x: 8, y: -25)
            p.footL = CGPoint(x: -16, y: 50); p.footR = CGPoint(x: 14, y: 52)
        }, .easeInOut),
        K(0.22, P { p in p.hipDX = 2; p.footL.x = -8; p.footR.x = 18 }, .easeInOut),
        K(0.44, P { p in
            p.handL = CGPoint(x: -4, y: -50); p.handR = CGPoint(x: 22, y: -48)
            p.footL = CGPoint(x: 16, y: 50); p.footR = CGPoint(x: -14, y: 52)
        }, .easeInOut),
        K(0.66, P { p in p.hipDX = -2; p.footL.x = 8; p.footR.x = -18 }, .easeInOut)
    ])
    /// PullUp: agarrarse de un borde y subirse a pulso.
    static let pullUp = AnimationClip(name: "pull-up", duration: 0.9, loops: false, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -14, y: -48); p.handR = CGPoint(x: 14, y: -48)
            p.elbowL = CGPoint(x: -16, y: -22); p.elbowR = CGPoint(x: 16, y: -22)
            p.hipHeight = 48; p.footL = CGPoint(x: -12, y: 46); p.footR = CGPoint(x: 12, y: 46)
        }, .easeIn),
        K(0.45, P { p in // tira de brazos: la cadera sube y una rodilla busca el borde
            p.hipHeight = 58; p.squash = 1.05
            p.elbowL = CGPoint(x: -20, y: -6); p.elbowR = CGPoint(x: 20, y: -6)
            p.handL = CGPoint(x: -16, y: -30); p.handR = CGPoint(x: 16, y: -30)
            p.kneeR = CGPoint(x: 16, y: 10); p.footR = CGPoint(x: 18, y: 30)
        }, .easeOut),
        K(0.9, SkeletonPose.standing, .softLanding)
    ])
    /// Sentado en un borde con las piernas COLGANDO y balanceandose.
    /// v6: el patron de la spec (8/2/5) ahora recorre el ciclo
    /// COMPLETO dos veces (8/2/5/8/2/5 = 6.0 s) en vez de una, con la
    /// segunda vuelta de amplitud algo menor y las rodillas un pelo
    /// mas dobladas — los balanceos reales pierden energia y la
    /// recuperan, no repiten el mismo arco para siempre.
    static let dangle = AnimationClip(name: "piernas-colgando", duration: 6.0, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34)
            p.kneeL = CGPoint(x: -13, y: 12); p.footL = CGPoint(x: -11, y: 40) // pie BAJO el asiento
            p.kneeR = CGPoint(x: 13, y: 12); p.footR = CGPoint(x: 15, y: 38)
            p.handL = CGPoint(x: -14, y: 22); p.handR = CGPoint(x: 14, y: 22) // manos apoyadas en el borde
        }, .easeInOut),
        K(1.6, P { p in p.footL.x = -5; p.footR.x = 9; p.neckOff.y = -33 }, .easeInOut),  // balanceo largo (8)
        K(2.0, P { p in p.footL.x = -13; p.footR.x = 17 }, .easeInOut),                     // toque corto (2)
        K(3.0, P { p in p.footL.x = -11; p.footR.x = 15 }, .easeInOut),                     // medio (5): centro, las piernas "respiran"
        K(4.6, P { p in // segunda vuelta (8): amplitud menor, rodillas mas dobladas
            p.footL = CGPoint(x: -6, y: 39); p.footR = CGPoint(x: 10, y: 37)
            p.kneeL = CGPoint(x: -11, y: 14); p.kneeR = CGPoint(x: 12, y: 14); p.neckOff.y = -33
        }, .easeInOut),
        K(5.0, P { p in p.footL.x = -12; p.footR.x = 16 }, .easeInOut),                     // toque corto (2)
        K(6.0, P { p in // medio (5) y cierre EXACTO en la pose inicial
            p.footL = CGPoint(x: -11, y: 40); p.footR = CGPoint(x: 15, y: 38)
            p.kneeL = CGPoint(x: -13, y: 12); p.kneeR = CGPoint(x: 13, y: 12); p.neckOff.y = -34
        }, .easeInOut)
    ])
    /// Tropezar (Trip): traspiés, brazos aspas, cae de bruces y se levanta atontado.
    /// Pose larga de suelo, como las caidas largas de la spec (30-52 ticks).
    static let trip = AnimationClip(name: "tropezar", duration: 1.5, loops: false, keyframes: [
        K(0.0, P { p in p.neckOff = CGPoint(x: 8, y: -40); p.footL = CGPoint(x: 22, y: 46); p.footR = CGPoint(x: 4, y: 40) }, .snappy), // traspiés
        K(0.25, P { p in // cae hacia delante, brazos aspas
            p.hipHeight = 40; p.neckOff = CGPoint(x: 14, y: -32); p.headOff = CGPoint(x: 6, y: -18)
            p.handL = CGPoint(x: -26, y: -16); p.handR = CGPoint(x: 30, y: -10)
            p.footL = CGPoint(x: -14, y: 38); p.footR = CGPoint(x: 10, y: 36)
        }, .easeIn),
        K(0.5, P { p in // de bruces en el suelo (pose larga)
            p.hipHeight = 13; p.neckOff = CGPoint(x: -30, y: -5); p.headOff = CGPoint(x: -17, y: -3)
            p.handL = CGPoint(x: -22, y: 6); p.handR = CGPoint(x: -6, y: 9)
            p.footL = CGPoint(x: 42, y: 11); p.footR = CGPoint(x: 40, y: 5); p.kneeL = CGPoint(x: 20, y: 6); p.kneeR = CGPoint(x: 18, y: 3)
        }, .easeOut),
        K(1.05, P { p in p.hipHeight = 14; p.headOff.y = -6 }, .easeInOut), // atontado, quieto
        K(1.5, P { p in p.hipHeight = 34; p.neckOff = CGPoint(x: 4, y: -34) }, .easeOut) // se incorpora
    ])
    /// Bounce: botar al levantarse / de contento (squash-stretch exagerado).
    static let bounce = AnimationClip(name: "botar", duration: 0.9, loops: false, keyframes: [
        K(0.0, P { $0.hipHeight = 34; $0.squash = 0.8 }, .easeIn),
        K(0.35, P { p in p.hipHeight = 62; p.squash = 1.1; p.footL = CGPoint(x: -13, y: 44); p.footR = CGPoint(x: 13, y: 44); p.handL = CGPoint(x: -24, y: -14); p.handR = CGPoint(x: 24, y: -14) }, .easeOut),
        K(0.62, P { $0.hipHeight = 48; $0.squash = 0.92 }, .easeInOut),
        K(0.9, SkeletonPose.standing, .softLanding)
    ])
    /// Tumbarse panza arriba (LieDown / sprawl), distinto de dormir: despierto, mirando arriba.
    static let sprawl = AnimationClip(name: "tumbado", duration: 3.2, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 10; p.neckOff = CGPoint(x: -34, y: -2); p.headOff = CGPoint(x: -20, y: -1)
            p.footL = CGPoint(x: 46, y: 8); p.kneeL = CGPoint(x: 24, y: 4)
            p.footR = CGPoint(x: 38, y: 2); p.kneeR = CGPoint(x: 19, y: 0) // una rodilla doblada
            p.handL = CGPoint(x: -14, y: 6); p.handR = CGPoint(x: 8, y: -12) // mano tras la cabeza
        }, .easeInOut),
        K(1.6, P { p in p.footR = CGPoint(x: 40, y: 3); p.neckOff.y = -3 }, .easeInOut) // mueve un pie, aburrido
    ])

    // v4: fuera los clips sociales (hug / hugged / hugOffer) y los
    // unicos de Victim (lassoSpin / stab / cursorSetup / workSit):
    // salieron con el duo y con Victim.

    /// Clip principal segun la accion (la locomocion y el salto van por fases en la vista).
    static func clip(for action: StickmanAction) -> AnimationClip {
        switch action {
        case .drawn, .idle: return idle
        case .awakening: return wakeUp
        case .walking, .climbing: return action == .climbing ? climb : walk
        case .running, .fleeing: return run
        case .jumping: return jumpStretch
        case .landing: return landing
        case .rolling: return roll
        case .dizzy: return dizzy
        case .dancing: return dance
        case .waving, .withFriend: return wave
        case .sitting: return sit
        case .resting: return sitBored
        case .sleeping: return sleep
        case .sword: return swordFence
        case .hammering: return hammering
        case .fighting: return fightCombo
        case .blocking: return block
        case .dodging: return dodgeDuck
        case .grabbingFinger: return grabFinger
        case .grabbed: return grabbed
        case .escaping: return escapeShake
        case .squashed: return squashed
        case .thrown: return thrownSpin
        case .scared: return scared
        case .yawning: return yawn
        case .denying: return deny
        case .proud: return proud
        case .laughing: return laugh
        case .celebrating: return celebrate
        case .stomping: return stomp
        case .shrugging: return shrug
        case .thumbsUp: return thumbsUp
        case .hiding: return hide
        case .drawingObject: return drawWithPencil
        case .usingTool: return eraseRub
        case .playingBall: return playBall
        case .powerPose: return powerPose
        case .flying: return flyPose
        case .usingPower: return powerPose // la vista refina segun el poder activo
        // v3
        case .wallClimbing: return climb
        case .ceilingWalking: return swingCeil
        case .hangingWall: return hangWall
        case .hangingCeiling: return hangCeil
        case .dangling: return dangle
        case .pullingUp: return pullUp
        case .tripping: return trip
        case .bouncing: return bounce
        case .lyingDown: return sprawl
        case .dropping: return fallPose
        case .chasingFinger: return run
        case .sittingFacingFinger: return sit
        case .gettingUp: return getUp
        case .escapeBurst: return escapeBurst
        // Integracion v7/v8/v9: casos nuevos -> clips de las tandas
        case .jetFlight: return AnimationLibraryV7.flameJet
        case .uppercut: return AnimationLibraryV7.uppercut
        case .flyingKick: return AnimationLibraryV7.flyingKick
        case .tackling: return AnimationLibraryV7.tackle
        case .snatching: return AnimationLibraryV7.snatchTool
        case .typing: return AnimationLibraryV7.typeFrenzy
        case .pushingHeavy: return AnimationLibraryV7.pushHeavy
        case .peeking: return AnimationLibraryV7.peekCorner
        case .crawling: return AnimationLibraryV7.crawl
        case .swingingRope: return AnimationLibraryV7.swingRope
        case .meditating: return AnimationLibraryV7.meditate
        case .exercising: return AnimationLibraryV7.pushUps
        case .jumpRoping: return AnimationLibraryV7.jumpRope
        case .eating: return AnimationLibraryV7.eatSnack
        case .drinking: return AnimationLibraryV7.drinkSip
        case .sneezing: return AnimationLibraryV7.sneeze
        case .hiccuping: return AnimationLibraryV7.hiccup
        case .walkingBack: return AnimationLibraryV8.walkBack
        case .sneaking: return AnimationLibraryV8.sneak
        case .carryingLoaded: return AnimationLibraryV8.walkLoaded
        case .throwingLoaded: return AnimationLibraryV9.throwLoaded
        case .fallingWithObject: return AnimationLibraryV9.fallWithObject
        case .handstanding: return AnimationLibraryV8.handstand
        case .tightroping: return AnimationLibraryV8.tightrope
        case .oneHandHanging: return AnimationLibraryV8.oneHandHang
        case .backKicking: return AnimationLibraryV8.backKick
        case .kneeStriking: return AnimationLibraryV8.kneeStrike
        case .elbowStriking: return AnimationLibraryV8.elbowStrike
        case .headbutting: return AnimationLibraryV8.headbutt
        case .leaningBack: return AnimationLibraryV8.leanBack
        case .chargingFireball: return AnimationLibraryV8.fireCharge
        case .diving: return AnimationLibraryV8.dive
        case .clapping: return AnimationLibraryV8.clap
        case .bowing: return AnimationLibraryV8.bow
        case .begging: return AnimationLibraryV8.beg
        case .impatient: return AnimationLibraryV8.impatient
        case .shivering: return AnimationLibraryV8.shiver
        case .beckoning: return AnimationLibraryV8.beckon
        case .highFiving: return AnimationLibraryV8.highFive
        case .groundPounding: return AnimationLibraryV9.groundPound
        case .feinting: return AnimationLibraryV9.feint
        case .sidestepping: return AnimationLibraryV9.sidestep
        case .parrying: return AnimationLibraryV9.palmParry
        case .fingerShielding: return AnimationLibraryV9.fingerShield
        case .stretching: return AnimationLibraryV9.stretchSide
        case .noddingOff: return AnimationLibraryV9.nodOff
        case .sleepRolling: return AnimationLibraryV9.sleepRoll
        case .inspecting: return AnimationLibraryV9.crouchInspect
        case .releasingBird: return AnimationLibraryV9.releaseBird
        case .pettingCreature: return AnimationLibraryV9.petCreature
        case .feedingCreature: return AnimationLibraryV9.feedCreature
        case .ridingHorse: return AnimationLibraryV9.rideHorse
        case .conducting: return AnimationLibraryV9.conduct
        case .wallJumping: return AnimationLibraryV9.wallJump
        }
    }

    /// Refinamiento de usingPower segun el poder concreto.
    static func clip(forPower power: Power) -> AnimationClip {
        switch power {
        case .fireBreath: return firePose
        case .eyeLaser: return laserPose
        case .superPunch: return superPunchPose
        case .superStrength: return strengthPose
        case .flight: return flyPose
        default: return powerPose
        }
    }
}

// MARK: - Criaturas que cobran vida (AvA4): ciclos simples

enum CreatureAnimation {
    /// Pajarito: aleteo + vuelo en circulos (devuelve offset y angulo de ala -1..1)
    static func bird(phase: Double, t: Double) -> (offset: CGPoint, flap: CGFloat) {
        let cx = CGFloat(sin(t * 0.55)) * 86
        let cy = 128 + CGFloat(sin(t * 1.15)) * 20
        let flap = CGFloat(sin(phase * 16))
        return (CGPoint(x: cx, y: cy), flap)
    }
    /// Perrito: trote con rebote (desplazamiento lateral y boteo)
    static func dog(phase: Double, t: Double, stickmanX: CGFloat) -> (x: CGFloat, bounce: CGFloat, legSwing: CGFloat) {
        let target = stickmanX - 54
        let wobble = CGFloat(sin(t * 0.8)) * 26
        return (target + wobble, abs(CGFloat(sin(phase * 11))) * 4, CGFloat(sin(phase * 11)))
    }
}
