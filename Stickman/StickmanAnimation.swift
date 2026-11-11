import Foundation
import SwiftUI

// MARK: - Sistema de animacion por KEYFRAMES (v2)
//
// Sustituye las "poses sueltas con senos" de la v1 por clips de datos:
// cada animacion es una lista de keyframes (tiempo, pose del esqueleto,
// easing hacia el siguiente keyframe) que se interpolan. Principios
// clasicos aplicados: anticipacion (agacharse antes de saltar),
// squash & stretch (aplastarse/estirarse), follow-through (los brazos
// llegan tarde), timing distinto por accion y easing en cada tramo.
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
    func apply(_ t: Double) -> Double {
        let x = min(1, max(0, t))
        switch self {
        case .linear: return x
        case .easeIn: return x * x
        case .easeOut: return 1 - (1 - x) * (1 - x)
        case .easeInOut: return x * x * (3 - 2 * x)
        case .snappy: return 1 - pow(1 - x, 3)          // llega rapido y clava
        case .softLanding: return 1 - pow(1 - x, 4)     // frena muy suave al final
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

    // -- Idle vivo: respiracion, balanceo, cambiar el peso --
    static let idle = AnimationClip(name: "idle", duration: 3.6, loops: true, keyframes: [
        K(0.0, P { $0.neckOff.y = -41; $0.hipDX = -2 }, .easeInOut),
        K(0.9, P { $0.neckOff.y = -43; $0.handL.x = -22; $0.handR.x = 22 }, .easeInOut),
        K(1.8, P { $0.neckOff.y = -41; $0.hipDX = 2; $0.headOff.x = 4 }, .easeInOut),
        K(2.7, P { $0.neckOff.y = -43; $0.headOff.x = -3 }, .easeInOut)
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

    // -- LOCOMOCION: caminar (contralateral, boteo, inclinacion leve) --
    static let walk = AnimationClip(name: "caminar", duration: 0.84, loops: true, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: 3, y: -42); p.hipHeight = 55
            p.footL = CGPoint(x: 17, y: 55); p.kneeL = CGPoint(x: 12, y: 28)
            p.footR = CGPoint(x: -15, y: 52); p.kneeR = CGPoint(x: -6, y: 24)
            p.handL = CGPoint(x: -13, y: 40); p.handR = CGPoint(x: 27, y: 40) // brazo contrario a la pierna adelantada
        }, .easeInOut),
        K(0.21, P { p in
            p.hipHeight = 53 // boteo: punto bajo al pasar
            p.footL = CGPoint(x: 4, y: 53); p.kneeL = CGPoint(x: 6, y: 30)
            p.footR = CGPoint(x: -10, y: 44); p.kneeR = CGPoint(x: -16, y: 18) // pierna trasera se recoge
            p.handL = CGPoint(x: -20, y: 41); p.handR = CGPoint(x: 20, y: 41)
        }, .easeInOut),
        K(0.42, P { p in
            p.neckOff = CGPoint(x: 3, y: -42); p.hipHeight = 55
            p.footL = CGPoint(x: -15, y: 52); p.kneeL = CGPoint(x: -6, y: 24)
            p.footR = CGPoint(x: 17, y: 55); p.kneeR = CGPoint(x: 12, y: 28)
            p.handL = CGPoint(x: -27, y: 40); p.handR = CGPoint(x: 13, y: 40)
        }, .easeInOut),
        K(0.63, P { p in
            p.hipHeight = 53
            p.footL = CGPoint(x: -10, y: 44); p.kneeL = CGPoint(x: -16, y: 18)
            p.footR = CGPoint(x: 4, y: 53); p.kneeR = CGPoint(x: 6, y: 30)
            p.handL = CGPoint(x: -20, y: 41); p.handR = CGPoint(x: 20, y: 41)
        }, .easeInOut)
    ])

    // -- LOCOMOCION: correr (zancada amplia, inclinado, bombeo) --
    static let run = AnimationClip(name: "correr", duration: 0.52, loops: true, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: 11, y: -40); p.headOff = CGPoint(x: 5, y: -22); p.hipHeight = 54
            p.footL = CGPoint(x: 28, y: 50); p.kneeL = CGPoint(x: 18, y: 26)
            p.footR = CGPoint(x: -24, y: 38); p.kneeR = CGPoint(x: -20, y: 10) // recogida alta detras
            p.handL = CGPoint(x: -6, y: 16); p.elbowL = CGPoint(x: -14, y: 20) // brazos en angulo, bombeando
            p.handR = CGPoint(x: 30, y: 22); p.elbowR = CGPoint(x: 16, y: 14)
        }, .easeInOut),
        K(0.13, P { p in
            p.neckOff = CGPoint(x: 12, y: -39); p.hipHeight = 50 // suspension tras el impulso
            p.footL = CGPoint(x: 10, y: 44); p.kneeL = CGPoint(x: 16, y: 22)
            p.footR = CGPoint(x: -6, y: 34); p.kneeR = CGPoint(x: -18, y: 8)
            p.handL = CGPoint(x: -16, y: 24); p.handR = CGPoint(x: 20, y: 14)
        }, .easeInOut),
        K(0.26, P { p in
            p.neckOff = CGPoint(x: 11, y: -40); p.headOff = CGPoint(x: 5, y: -22); p.hipHeight = 54
            p.footL = CGPoint(x: -24, y: 38); p.kneeL = CGPoint(x: -20, y: 10)
            p.footR = CGPoint(x: 28, y: 50); p.kneeR = CGPoint(x: 18, y: 26)
            p.handL = CGPoint(x: -30, y: 22); p.elbowL = CGPoint(x: -16, y: 14)
            p.handR = CGPoint(x: 6, y: 16); p.elbowR = CGPoint(x: 14, y: 20)
        }, .easeInOut),
        K(0.39, P { p in
            p.neckOff = CGPoint(x: 12, y: -39); p.hipHeight = 50
            p.footL = CGPoint(x: -6, y: 34); p.kneeL = CGPoint(x: -18, y: 8)
            p.footR = CGPoint(x: 10, y: 44); p.kneeR = CGPoint(x: 16, y: 22)
            p.handL = CGPoint(x: -20, y: 14); p.handR = CGPoint(x: 16, y: 24)
        }, .easeInOut)
    ])

    // -- Derrape al parar / cambiar de sentido --
    static let skid = AnimationClip(name: "derrape", duration: 0.42, loops: false, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: -9, y: -41); p.hipHeight = 52 // se echa atras
            p.footL = CGPoint(x: 24, y: 52); p.kneeL = CGPoint(x: 14, y: 28) // pies por delante frenando
            p.footR = CGPoint(x: 16, y: 52); p.kneeR = CGPoint(x: 10, y: 30)
            p.handL = CGPoint(x: -28, y: 26); p.handR = CGPoint(x: 30, y: 28) // brazos buscando equilibrio
        }, .easeOut),
        K(0.42, SkeletonPose.standing, .softLanding)
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

    // -- Salto por fases (la vista elige segun fisica) --
    static let jumpCrouch = AnimationClip(name: "salto-agacharse", duration: 0.22, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.22, P { p in
            p.hipHeight = 40; p.squash = 0.84 // ANTICIPACION
            p.kneeL = CGPoint(x: -16, y: 18); p.footL = CGPoint(x: -15, y: 40)
            p.kneeR = CGPoint(x: 16, y: 18); p.footR = CGPoint(x: 15, y: 40)
            p.handL = CGPoint(x: -24, y: 30); p.handR = CGPoint(x: 24, y: 30) // brazos atras
        })
    ])
    static let jumpStretch = AnimationClip(name: "salto-estirar", duration: 0.3, loops: false, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 58; p.squash = 1.12 // STRETCH al despegar
            p.footL = CGPoint(x: -8, y: 46); p.kneeL = CGPoint(x: -6, y: 24)
            p.footR = CGPoint(x: 9, y: 48); p.kneeR = CGPoint(x: 7, y: 25)
            p.handL = CGPoint(x: -22, y: -6); p.handR = CGPoint(x: 22, y: -6) // brazos arriba (follow-through)
        }, .easeOut),
        K(0.3, P { p in
            p.squash = 1.04
            p.footL = CGPoint(x: -13, y: 38); p.kneeL = CGPoint(x: -12, y: 18)
            p.footR = CGPoint(x: 14, y: 40); p.kneeR = CGPoint(x: 12, y: 19)
            p.handL = CGPoint(x: -26, y: 8); p.handR = CGPoint(x: 26, y: 8)
        })
    ])
    static let fallPose = AnimationClip(name: "caida", duration: 0.5, loops: false, keyframes: [
        K(0.0, P { p in
            p.footL = CGPoint(x: -20, y: 34); p.kneeL = CGPoint(x: -15, y: 16) // piernas abiertas buscando suelo
            p.footR = CGPoint(x: 21, y: 36); p.kneeR = CGPoint(x: 16, y: 17)
            p.handL = CGPoint(x: -28, y: -2); p.handR = CGPoint(x: 28, y: -2)
        }, .easeInOut),
        K(0.5, P { p in
            p.footL = CGPoint(x: -22, y: 38); p.footR = CGPoint(x: 23, y: 40)
            p.handL = CGPoint(x: -29, y: 4); p.handR = CGPoint(x: 29, y: 4)
        })
    ])
    static let landing = AnimationClip(name: "aterrizar", duration: 0.42, loops: false, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 38; p.squash = 0.8 // SQUASH de impacto
            p.kneeL = CGPoint(x: -18, y: 16); p.footL = CGPoint(x: -19, y: 38)
            p.kneeR = CGPoint(x: 18, y: 16); p.footR = CGPoint(x: 19, y: 38)
            p.handL = CGPoint(x: -26, y: 28); p.handR = CGPoint(x: 26, y: 28)
        }, .easeOut),
        K(0.2, P { p in p.hipHeight = 50; p.squash = 0.95 }, .easeInOut),
        K(0.42, SkeletonPose.standing, .softLanding)
    ])
    static let roll = AnimationClip(name: "rodar", duration: 0.62, loops: false, keyframes: [
        K(0.0, P { p in p.hipHeight = 34; p.squash = 0.85; p.headOff = CGPoint(x: 8, y: -16) }, .easeIn),
        K(0.2, P { p in // hecho una bola
            p.hipHeight = 22; p.neckOff = CGPoint(x: 14, y: -18); p.headOff = CGPoint(x: 8, y: -10)
            p.footL = CGPoint(x: -2, y: 20); p.kneeL = CGPoint(x: 10, y: 8)
            p.footR = CGPoint(x: 4, y: 22); p.kneeR = CGPoint(x: 14, y: 10)
            p.handL = CGPoint(x: -2, y: -2); p.handR = CGPoint(x: 6, y: 0)
        }, .easeInOut),
        K(0.42, P { p in p.hipHeight = 36; p.neckOff = CGPoint(x: 6, y: -34) }, .easeOut),
        K(0.62, SkeletonPose.standing, .softLanding)
    ])
    static let dizzy = AnimationClip(name: "mareado", duration: 1.6, loops: true, keyframes: [
        K(0.0, P { $0.headOff = CGPoint(x: -8, y: -20); $0.hipDX = -3; $0.handL = CGPoint(x: -24, y: 30); $0.handR = CGPoint(x: 24, y: 30) }, .easeInOut),
        K(0.8, P { $0.headOff = CGPoint(x: 8, y: -20); $0.hipDX = 3; $0.neckOff.x = 3 }, .easeInOut)
    ])

    // -- Pelea con el cursor/dedo (AvA1): combo completo --
    static let fightCombo = AnimationClip(name: "pelea", duration: 2.6, loops: true, keyframes: [
        K(0.0, P { p in // guardia de artes marciales
            p.hipHeight = 50; p.neckOff = CGPoint(x: 5, y: -40)
            p.footL = CGPoint(x: -18, y: 50); p.footR = CGPoint(x: 20, y: 50)
            p.handL = CGPoint(x: 16, y: 8); p.elbowL = CGPoint(x: 4, y: 18)
            p.handR = CGPoint(x: 26, y: 12); p.elbowR = CGPoint(x: 14, y: 20)
        }, .snappy),
        K(0.3, P { p in // jab (punetazo 1)
            p.hipHeight = 50; p.neckOff = CGPoint(x: 8, y: -40)
            p.footL = CGPoint(x: -18, y: 50); p.footR = CGPoint(x: 20, y: 50)
            p.handR = CGPoint(x: 46, y: 6); p.elbowR = CGPoint(x: 26, y: 8)
            p.handL = CGPoint(x: 14, y: 10)
        }, .easeIn), // vuelve guardando (follow-through lento)
        K(0.55, P { p in // cross (punetazo 2, con cadera)
            p.hipHeight = 49; p.neckOff = CGPoint(x: 10, y: -40); p.hipDX = 3
            p.footL = CGPoint(x: -18, y: 49); p.footR = CGPoint(x: 22, y: 49)
            p.handL = CGPoint(x: 44, y: 8); p.elbowL = CGPoint(x: 24, y: 10)
            p.handR = CGPoint(x: 16, y: 10)
        }, .snappy),
        K(0.85, P { p in // guardia otra vez
            p.hipHeight = 50; p.neckOff = CGPoint(x: 5, y: -40)
            p.footL = CGPoint(x: -18, y: 50); p.footR = CGPoint(x: 20, y: 50)
            p.handL = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 26, y: 12)
        }, .easeIn),
        K(1.25, P { p in // patada frontal
            p.hipHeight = 52; p.neckOff = CGPoint(x: -4, y: -41)
            p.footL = CGPoint(x: -12, y: 52)
            p.footR = CGPoint(x: 48, y: 22); p.kneeR = CGPoint(x: 30, y: 18)
            p.handL = CGPoint(x: -26, y: 22); p.handR = CGPoint(x: 18, y: 6)
        }, .easeInOut),
        K(1.7, P { p in // patada giratoria (se agacha y gira: manos al suelo)
            p.hipHeight = 34; p.neckOff = CGPoint(x: 8, y: -30); p.headOff = CGPoint(x: 4, y: -18)
            p.footL = CGPoint(x: -8, y: 34); p.footR = CGPoint(x: 40, y: 10); p.kneeR = CGPoint(x: 24, y: 8)
            p.handL = CGPoint(x: -14, y: 26); p.handR = CGPoint(x: 16, y: 28)
        }, .snappy),
        K(2.1, P { p in // recupera guardia, respira
            p.hipHeight = 50; p.neckOff = CGPoint(x: 5, y: -39)
            p.footL = CGPoint(x: -18, y: 50); p.footR = CGPoint(x: 20, y: 50)
            p.handL = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 26, y: 12)
        }, .easeInOut)
    ])

    static let block = AnimationClip(name: "bloquear", duration: 0.7, loops: true, keyframes: [
        K(0.0, P { p in // antebrazos cruzados delante
            p.hipHeight = 49; p.squash = 0.96
            p.handL = CGPoint(x: 15, y: -2); p.elbowL = CGPoint(x: -2, y: 16)
            p.handR = CGPoint(x: 13, y: 6); p.elbowR = CGPoint(x: 20, y: 18)
            p.footL = CGPoint(x: -16, y: 49); p.footR = CGPoint(x: 18, y: 49)
        }, .easeInOut),
        K(0.35, P { p in p.hipHeight = 47; p.handL = CGPoint(x: 16, y: -4); p.handR = CGPoint(x: 14, y: 4) }, .easeInOut)
    ])

    static let dodgeDuck = AnimationClip(name: "esquivar-agachado", duration: 0.55, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .snappy),
        K(0.16, P { p in
            p.hipHeight = 30; p.squash = 0.78; p.neckOff = CGPoint(x: 6, y: -28); p.headOff = CGPoint(x: 3, y: -17)
            p.kneeL = CGPoint(x: -17, y: 12); p.footL = CGPoint(x: -16, y: 30)
            p.kneeR = CGPoint(x: 17, y: 12); p.footR = CGPoint(x: 16, y: 30)
        }, .easeOut),
        K(0.55, SkeletonPose.standing, .softLanding)
    ])

    static let grabFinger = AnimationClip(name: "agarrar-dedo", duration: 1.1, loops: true, keyframes: [
        K(0.0, P { p in // colgando del dedo con las dos manos, balanceo
            p.hipHeight = 58; p.neckOff = CGPoint(x: -3, y: -44)
            p.handL = CGPoint(x: -6, y: -34); p.elbowL = CGPoint(x: -12, y: -14)
            p.handR = CGPoint(x: 8, y: -34); p.elbowR = CGPoint(x: 13, y: -14)
            p.footL = CGPoint(x: -14, y: 52); p.kneeL = CGPoint(x: -10, y: 26)
            p.footR = CGPoint(x: 16, y: 50); p.kneeR = CGPoint(x: 11, y: 25)
        }, .easeInOut),
        K(0.55, P { p in
            p.neckOff = CGPoint(x: 3, y: -44); p.hipDX = 3
            p.handL = CGPoint(x: -6, y: -34); p.handR = CGPoint(x: 8, y: -34)
            p.footL = CGPoint(x: -17, y: 50); p.footR = CGPoint(x: 13, y: 53)
        }, .easeInOut)
    ])

    static let grabbed = AnimationClip(name: "agarrado", duration: 0.8, loops: true, keyframes: [
        K(0.0, P { p in // patalea en el aire
            p.footL = CGPoint(x: -20, y: 40); p.kneeL = CGPoint(x: -14, y: 18)
            p.footR = CGPoint(x: 22, y: 44); p.kneeR = CGPoint(x: 15, y: 20)
            p.handL = CGPoint(x: -28, y: 6); p.handR = CGPoint(x: 28, y: 2)
        }, .easeInOut),
        K(0.4, P { p in
            p.footL = CGPoint(x: -24, y: 44); p.footR = CGPoint(x: 18, y: 38)
            p.handL = CGPoint(x: -26, y: 0); p.handR = CGPoint(x: 30, y: 8)
        }, .easeInOut)
    ])

    static let escapeShake = AnimationClip(name: "escapar-caja", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { $0.hipDX = -3; $0.squash = 0.96; $0.handL = CGPoint(x: -26, y: 18); $0.handR = CGPoint(x: 26, y: 18) }, .linear),
        K(0.15, P { $0.hipDX = 3; $0.squash = 1.03 }, .linear),
        K(0.3, P { $0.hipDX = -3; $0.squash = 0.96 }, .linear),
        K(0.45, P { $0.hipDX = 3; $0.squash = 1.04 }, .linear),
        K(0.6, P { $0.hipDX = -2; $0.squash = 0.97 }, .linear),
        K(0.75, P { $0.hipDX = 2; $0.squash = 1.02 }, .linear)
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
    static let stomp = AnimationClip(name: "enfadado-pisoton", duration: 1.1, loops: true, keyframes: [
        K(0.0, P { p in p.handL = CGPoint(x: 10, y: 24); p.handR = CGPoint(x: -10, y: 24); p.headOff.y = -20 }, .snappy), // brazos cruzados
        K(0.3, P { $0.footR = CGPoint(x: 16, y: 34); $0.kneeR = CGPoint(x: 14, y: 14) }, .snappy), // levanta el pie
        K(0.45, P { $0.footR = CGPoint(x: 16, y: 56); $0.squash = 0.94 }, .easeInOut), // PISOTON
        K(0.75, P { $0.footR = CGPoint(x: 16, y: 34) }, .snappy)
    ])
    static let scared = AnimationClip(name: "asustado", duration: 0.5, loops: true, keyframes: [
        K(0.0, P { p in p.handL = CGPoint(x: -26, y: -24); p.handR = CGPoint(x: 26, y: -24); p.hipHeight = 53; p.hipDX = -1 }, .linear), // manos arriba, temblor
        K(0.12, P { $0.hipDX = 1 }, .linear),
        K(0.25, P { $0.hipDX = -1 }, .linear),
        K(0.37, P { $0.hipDX = 1 }, .linear)
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
    static let sleep = AnimationClip(name: "dormir", duration: 3.4, loops: true, keyframes: [
        K(0.0, P { p in // tumbado de lado, respira lento
            p.hipHeight = 11; p.neckOff = CGPoint(x: -32, y: -3); p.headOff = CGPoint(x: -19, y: -2)
            p.footL = CGPoint(x: 44, y: 9); p.kneeL = CGPoint(x: 22, y: 5)
            p.footR = CGPoint(x: 42, y: 3); p.kneeR = CGPoint(x: 20, y: 1)
            p.handL = CGPoint(x: -10, y: 8); p.handR = CGPoint(x: -16, y: 6)
        }, .easeInOut),
        K(1.7, P { p in p.hipHeight = 12; p.neckOff = CGPoint(x: -32, y: -4) }, .easeInOut)
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
    static let climb = AnimationClip(name: "trepar", duration: 0.7, loops: true, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -14, y: -26); p.handR = CGPoint(x: 16, y: -12)
            p.footL = CGPoint(x: -10, y: 38); p.kneeL = CGPoint(x: -13, y: 18)
            p.footR = CGPoint(x: 12, y: 48); p.kneeR = CGPoint(x: 13, y: 24)
        }, .easeInOut),
        K(0.35, P { p in
            p.handL = CGPoint(x: -16, y: -12); p.handR = CGPoint(x: 14, y: -27)
            p.footL = CGPoint(x: -12, y: 48); p.footR = CGPoint(x: 10, y: 38)
        }, .easeInOut)
    ])
    static let playBall = AnimationClip(name: "jugar-pelota", duration: 0.84, loops: true, keyframes: [
        K(0.0, P { $0.handL = CGPoint(x: -24, y: 30); $0.handR = CGPoint(x: 24, y: 30) }, .easeInOut),
        K(0.42, P { $0.hipHeight = 52; $0.footR = CGPoint(x: 22, y: 40); $0.kneeR = CGPoint(x: 16, y: 18) }, .easeInOut) // toquecito con el pie
    ])

    // -- Chosen One (AvA2) --
    static let flyPose = AnimationClip(name: "volar", duration: 1.2, loops: true, keyframes: [
        K(0.0, P { p in // tipo superman: un puno delante, cuerpo recto inclinado
            p.neckOff = CGPoint(x: 14, y: -38); p.headOff = CGPoint(x: 7, y: -20)
            p.handR = CGPoint(x: 44, y: -6); p.elbowR = CGPoint(x: 24, y: -4)
            p.handL = CGPoint(x: -14, y: 22)
            p.footL = CGPoint(x: -40, y: 16); p.kneeL = CGPoint(x: -20, y: 10)
            p.footR = CGPoint(x: -36, y: 24); p.kneeR = CGPoint(x: -18, y: 15)
        }, .easeInOut),
        K(0.6, P { p in p.neckOff.y = -36; p.footL.y = 19; p.footR.y = 21 }, .easeInOut)
    ])
    static let chargePower = AnimationClip(name: "cargar-energia", duration: 1.5, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.6, P { p in // agachado, puños a los lados, temblando de energia
            p.hipHeight = 42; p.squash = 0.9; p.neckOff = CGPoint(x: 0, y: -36)
            p.handL = CGPoint(x: -22, y: 22); p.handR = CGPoint(x: 22, y: 22)
            p.footL = CGPoint(x: -20, y: 42); p.footR = CGPoint(x: 20, y: 42)
        }, .easeInOut),
        K(1.1, P { p in p.hipHeight = 43; p.hipDX = 1 }, .linear),
        K(1.5, P { p in p.hipHeight = 58; p.squash = 1.06; p.handL = CGPoint(x: -24, y: -20); p.handR = CGPoint(x: 24, y: -20) }, .easeOut) // explosion de aura
    ])
    static let firePose = AnimationClip(name: "fuego", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in // se inclina y sopla/lanza con las dos manos
            p.neckOff = CGPoint(x: 12, y: -38); p.headOff = CGPoint(x: 6, y: -20); p.hipHeight = 51
            p.handL = CGPoint(x: 30, y: 12); p.handR = CGPoint(x: 36, y: 18)
            p.footL = CGPoint(x: -20, y: 51); p.footR = CGPoint(x: 16, y: 51)
        }, .easeInOut),
        K(0.45, P { p in p.neckOff.x = 14; p.handL = CGPoint(x: 34, y: 10); p.handR = CGPoint(x: 40, y: 16) }, .easeInOut)
    ])
    static let laserPose = AnimationClip(name: "laser", duration: 0.8, loops: true, keyframes: [
        K(0.0, P { p in // cabeza atras por el retroceso, cuerpo tenso
            p.neckOff = CGPoint(x: -6, y: -41); p.headOff = CGPoint(x: -4, y: -24)
            p.handL = CGPoint(x: -22, y: 24); p.handR = CGPoint(x: 22, y: 24)
            p.footL = CGPoint(x: -18, y: 56); p.footR = CGPoint(x: 18, y: 56)
        }, .easeInOut),
        K(0.4, P { p in p.headOff.x = -5; p.neckOff.x = -7 }, .easeInOut)
    ])
    static let superPunchPose = AnimationClip(name: "superpunetazo", duration: 0.85, loops: false, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: -6, y: 16); p.neckOff.x = -4 }, .easeIn), // carga el brazo atras
        K(0.35, P { p in p.handR = CGPoint(x: -12, y: 14); p.hipHeight = 50; p.squash = 0.94 }, .snappy), // paso enorme...
        K(0.5, P { p in // ...Y GOLPE con todo el cuerpo
            p.neckOff = CGPoint(x: 15, y: -39); p.hipDX = 7; p.hipHeight = 52
            p.handR = CGPoint(x: 54, y: 4); p.elbowR = CGPoint(x: 30, y: 5)
            p.footL = CGPoint(x: -24, y: 52); p.footR = CGPoint(x: 20, y: 52)
            p.handL = CGPoint(x: -20, y: 18)
        }, .easeOut),
        K(0.85, P { p in p.handR = CGPoint(x: 30, y: 10); p.neckOff.x = 6 }, .softLanding)
    ])
    static let strengthPose = AnimationClip(name: "superfuerza", duration: 1.6, loops: true, keyframes: [
        K(0.0, P { p in // bloque sobre la cabeza, piernas tiemblan un poco
            p.handL = CGPoint(x: -17, y: -34); p.handR = CGPoint(x: 17, y: -34)
            p.elbowL = CGPoint(x: -16, y: -10); p.elbowR = CGPoint(x: 16, y: -10)
            p.hipHeight = 51; p.footL = CGPoint(x: -17, y: 51); p.footR = CGPoint(x: 17, y: 51)
        }, .easeInOut),
        K(0.8, P { p in p.hipHeight = 53; p.hipDX = 1 }, .easeInOut)
    ])
    static let powerPose = AnimationClip(name: "pose-poder", duration: 1.4, loops: true, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: 20, y: -34); p.elbowR = CGPoint(x: 15, y: -10); p.handL = CGPoint(x: -4, y: 4); p.elbowL = CGPoint(x: -20, y: 18); p.neckOff = CGPoint(x: -3, y: -43) }, .easeInOut),
        K(0.7, P { p in p.handR = CGPoint(x: 22, y: -36); p.neckOff.y = -44 }, .easeInOut)
    ])

    // MARK: v3 — Superficies (pared / techo / bordes)

    /// Colgarse de una pared: un brazo arriba agarrado, piernas colgando con balanceo leve.
    static let hangWall = AnimationClip(name: "colgarse-pared", duration: 1.8, loops: true, keyframes: [
        K(0.0, P { p in
            p.handR = CGPoint(x: 6, y: -52); p.elbowR = CGPoint(x: 10, y: -26) // mano agarrada arriba
            p.handL = CGPoint(x: -18, y: 6); p.hipHeight = 52
            p.footL = CGPoint(x: -12, y: 50); p.footR = CGPoint(x: 10, y: 52)
        }, .easeInOut),
        K(0.9, P { p in p.hipDX = 2; p.footL.x = -9; p.footR.x = 13 }, .easeInOut)
    ])
    /// Colgarse del techo: los DOS brazos arriba (al ancla), cuerpo colgando y balanceo.
    static let hangCeil = AnimationClip(name: "colgarse-techo", duration: 1.8, loops: true, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: -10, y: -50); p.elbowL = CGPoint(x: -12, y: -24)
            p.handR = CGPoint(x: 10, y: -50); p.elbowR = CGPoint(x: 12, y: -24)
            p.footL = CGPoint(x: -13, y: 54); p.footR = CGPoint(x: 13, y: 54)
        }, .easeInOut),
        K(0.9, P { p in p.hipDX = 3; p.footL.x = -8; p.footR.x = 17 }, .easeInOut)
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
    /// Tiempos IRREGULARES a proposito (patron de la spec: 8/2/5/8/2/5):
    /// las piernas pasan por debajo de la linea del asiento.
    static let dangle = AnimationClip(name: "piernas-colgando", duration: 3.0, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 0, y: -34)
            p.kneeL = CGPoint(x: -13, y: 12); p.footL = CGPoint(x: -11, y: 40) // pie BAJO el asiento
            p.kneeR = CGPoint(x: 13, y: 12); p.footR = CGPoint(x: 15, y: 38)
            p.handL = CGPoint(x: -14, y: 22); p.handR = CGPoint(x: 14, y: 22) // manos apoyadas en el borde
        }, .easeInOut),
        K(1.6, P { p in p.footL.x = -5; p.footR.x = 9; p.neckOff.y = -33 }, .easeInOut),  // balanceo largo (8)
        K(2.0, P { p in p.footL.x = -13; p.footR.x = 17 }, .easeInOut),                     // toque corto (2)
        K(3.0, P { p in p.footL.x = -11; p.footR.x = 15 }, .easeInOut)                      // medio (5) y vuelta
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

    // MARK: v3 — Sociales

    /// Abrazo (rol Hug / HuggingSolid): brazos abiertos hacia el otro y apretar.
    static let hug = AnimationClip(name: "abrazar", duration: 2.4, loops: true, keyframes: [
        K(0.0, P { p in
            p.handL = CGPoint(x: 26, y: 4); p.elbowL = CGPoint(x: 8, y: 14)
            p.handR = CGPoint(x: 30, y: 14); p.elbowR = CGPoint(x: 14, y: 20)
            p.neckOff = CGPoint(x: 5, y: -41)
        }, .easeInOut),
        K(0.8, P { p in p.handL = CGPoint(x: 30, y: 0); p.handR = CGPoint(x: 34, y: 10); p.hipDX = 2 }, .easeInOut), // aprieta
        K(1.6, P { p in p.handL = CGPoint(x: 27, y: 3); p.handR = CGPoint(x: 31, y: 13) }, .easeInOut)
    ])
    /// Abrazado (rol Hugged / HuggedSolid, espejo): se deja abrazar, brazos a media altura, se inclina.
    static let hugged = AnimationClip(name: "abrazado", duration: 2.4, loops: true, keyframes: [
        K(0.0, P { p in
            p.neckOff = CGPoint(x: -3, y: -41); p.headOff = CGPoint(x: -3, y: -22)
            p.handL = CGPoint(x: -14, y: 18); p.handR = CGPoint(x: 12, y: 20)
        }, .easeInOut),
        K(0.8, P { p in p.handL = CGPoint(x: -8, y: 10); p.handR = CGPoint(x: 18, y: 12); p.hipDX = -2 }, .easeInOut), // corresponde un poco
        K(1.6, P { p in p.neckOff.y = -40 }, .easeInOut)
    ])
    /// Ofrecerse para abrazo (HugAffordance): brazos abiertos esperando.
    static let hugOffer = AnimationClip(name: "ofrecer-abrazo", duration: 3.2, loops: true, keyframes: [
        K(0.0, P { p in p.handL = CGPoint(x: -30, y: -2); p.handR = CGPoint(x: 30, y: -2); p.elbowL = CGPoint(x: -18, y: 8); p.elbowR = CGPoint(x: 18, y: 8) }, .easeInOut),
        K(1.6, P { p in p.handL.y = 2; p.handR.y = 2; p.headOff.x = 4 }, .easeInOut) // mira esperanzado
    ])

    // MARK: v3 — Unicos de Victim (AvA 1)

    /// SpinLasso: el brazo gira en circulo sobre la cabeza (el lazo se dibuja en la vista).
    static let lassoSpin = AnimationClip(name: "lazo", duration: 1.0, loops: true, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: 24, y: -34); p.elbowR = CGPoint(x: 12, y: -18); p.neckOff = CGPoint(x: 3, y: -42) }, .linear),
        K(0.25, P { $0.handR = CGPoint(x: 2, y: -46) }, .linear),
        K(0.5, P { $0.handR = CGPoint(x: -22, y: -34) }, .linear),
        K(0.75, P { $0.handR = CGPoint(x: 0, y: -24) }, .linear)
    ])
    /// Stabbing: apuñalar rapido hacia delante/abajo (3 poses rapidas, como la spec).
    static let stab = AnimationClip(name: "apunalar", duration: 0.66, loops: true, keyframes: [
        K(0.0, P { p in p.handR = CGPoint(x: 12, y: -18); p.elbowR = CGPoint(x: 14, y: 2); p.neckOff = CGPoint(x: 5, y: -40) }, .snappy), // atras
        K(0.16, P { p in p.handR = CGPoint(x: 38, y: 16); p.elbowR = CGPoint(x: 22, y: 8); p.hipDX = 3 }, .easeIn), // ¡zas!
        K(0.33, P { p in p.handR = CGPoint(x: 13, y: -16) }, .snappy),
        K(0.49, P { p in p.handR = CGPoint(x: 38, y: 16); p.hipDX = 3 }, .easeIn)
    ])
    /// CursorSetup: posar solemne junto al cursor que el mismo se ha colocado.
    static let cursorSetup = AnimationClip(name: "cursor-setup", duration: 2.0, loops: true, keyframes: [
        K(0.0, P { p in // de rodillas/señalando el cursor, pose larga y seria (250 ticks en la spec)
            p.hipHeight = 40; p.neckOff = CGPoint(x: 6, y: -36); p.headOff = CGPoint(x: 4, y: -20)
            p.kneeL = CGPoint(x: -14, y: 22); p.footL = CGPoint(x: -12, y: 40)
            p.kneeR = CGPoint(x: 15, y: 24); p.footR = CGPoint(x: 20, y: 38)
            p.handR = CGPoint(x: 32, y: -6); p.elbowR = CGPoint(x: 18, y: 4) // señala el cursor
            p.handL = CGPoint(x: -12, y: 22)
        }, .easeInOut),
        K(1.0, P { p in p.headOff.x = 6; p.handR.y = -3 }, .easeInOut)
    ])
    /// SitWhileWorking: sentado picando con la herramienta (teclea/apuñala el papel).
    static let workSit = AnimationClip(name: "a-trabajar", duration: 0.72, loops: true, keyframes: [
        K(0.0, P { p in
            p.hipHeight = 26; p.neckOff = CGPoint(x: 6, y: -33); p.headOff = CGPoint(x: 4, y: -19)
            p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
            p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
            p.handL = CGPoint(x: 16, y: 16); p.handR = CGPoint(x: 26, y: 10); p.elbowR = CGPoint(x: 16, y: 14)
        }, .easeInOut),
        K(0.18, P { $0.handR = CGPoint(x: 28, y: 20) }, .snappy), // pica
        K(0.36, P { $0.handL = CGPoint(x: 20, y: 20); $0.handR = CGPoint(x: 24, y: 11) }, .easeInOut),
        K(0.54, P { $0.handL = CGPoint(x: 17, y: 15) }, .snappy) // pica con la otra
    ])

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
        case .chasingPeer, .chasingFinger: return run
        case .sparring: return fightCombo
        case .hugging: return hug
        case .hugged: return hugged
        case .hugOffer: return hugOffer
        case .lassoSpin: return lassoSpin
        case .stabbing: return stab
        case .cursorSetup: return cursorSetup
        case .working: return workSit
        case .sittingFacingFinger: return sit
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
