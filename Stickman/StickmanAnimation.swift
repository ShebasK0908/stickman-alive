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

    // -- LOCOMOCION v4: caminar --
    // Rehacho "como en los videos" (AvA 1/4: andar con peso, no flotar):
    // contactos que se AGUANTAN mas que los pasos de paso (timing
    // irregular: 0 / .19 / .40 / .585 en un ciclo de .78), boteo con
    // caida real al apoyar (hipHeight 56 -> 51.5), balanceo de brazos
    // contralateral AMPLIO y cabeza con follow-through: llega TARDE al
    // balanceo del torso (headOff.x va a contrafase del cuello).
    static let walk = AnimationClip(name: "caminar", duration: 0.78, loops: true, keyframes: [
        K(0.0, P { p in // CONTACTO: talon delante, peso cayendo sobre la pierna
            p.neckOff = CGPoint(x: 4, y: -42); p.headOff = CGPoint(x: 1, y: -23); p.hipHeight = 54
            p.footL = CGPoint(x: 19, y: 54); p.kneeL = CGPoint(x: 13, y: 27)
            p.footR = CGPoint(x: -17, y: 50); p.kneeR = CGPoint(x: -7, y: 22)
            p.handL = CGPoint(x: -16, y: 41); p.elbowL = CGPoint(x: -18, y: 19)
            p.handR = CGPoint(x: 30, y: 41); p.elbowR = CGPoint(x: 18, y: 19) // brazo contrario, amplio
        }, .easeIn), // el peso cae: acelera hacia el apoyo
        K(0.19, P { p in // PASO/pasada: punto bajo, pierna libre se recoge alta
            p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: 4, y: -22); p.hipHeight = 51.5
            p.footL = CGPoint(x: 2, y: 51); p.kneeL = CGPoint(x: 7, y: 29)
            p.footR = CGPoint(x: -8, y: 40); p.kneeR = CGPoint(x: -19, y: 15)
            p.handL = CGPoint(x: -23, y: 42); p.handR = CGPoint(x: 21, y: 42)
        }, .easeOut), // sale del apoyo con impulso
        K(0.40, P { p in // CONTACTO contrario (espejo no exacto: leve asimetria humana)
            p.neckOff = CGPoint(x: 4, y: -42); p.headOff = CGPoint(x: 1, y: -23); p.hipHeight = 54
            p.footL = CGPoint(x: -16, y: 50); p.kneeL = CGPoint(x: -7, y: 22)
            p.footR = CGPoint(x: 20, y: 54); p.kneeR = CGPoint(x: 14, y: 27)
            p.handL = CGPoint(x: -31, y: 41); p.elbowL = CGPoint(x: -18, y: 19)
            p.handR = CGPoint(x: 15, y: 41); p.elbowR = CGPoint(x: 18, y: 19)
        }, .easeIn),
        K(0.585, P { p in // PASO contrario
            p.neckOff = CGPoint(x: 3, y: -41); p.headOff = CGPoint(x: 4, y: -22); p.hipHeight = 51.5
            p.footL = CGPoint(x: -9, y: 40); p.kneeL = CGPoint(x: -19, y: 15)
            p.footR = CGPoint(x: 3, y: 51); p.kneeR = CGPoint(x: 8, y: 29)
            p.handL = CGPoint(x: -21, y: 42); p.handR = CGPoint(x: 24, y: 42)
        }, .easeOut)
    ])

    // -- LOCOMOCION v4: correr — LA CARRERA DE THE CHOSEN ONE (AvA 2) --
    // En AvA 2 TCO corre PESADO y bajo, casi galopando: torso muy
    // inclinado hacia delante, zancada larguisima, brazos bombeando
    // cruzando el cuerpo con los codos flexionados, y una fase de VUELO
    // clara en cada zancada (ningun pie toca el suelo). Estructura de
    // animacion tradicional, no un ciclo uniforme:
    //   contacto (corto, snappy) -> ABSORCION/compresion (squash .92)
    //   -> IMPULSO/toe-off (stretch 1.05) -> VUELO (el tramo largo)
    // Timing irregular: los contactos duran ~.07 y los vuelos ~.14.
    static let run = AnimationClip(name: "correr", duration: 0.58, loops: true, keyframes: [
        K(0.0, P { p in // CONTACTO pie izquierdo: cae lejos, delante del cuerpo
            p.neckOff = CGPoint(x: 16, y: -39); p.headOff = CGPoint(x: 7, y: -21); p.hipHeight = 52
            p.footL = CGPoint(x: 33, y: 50); p.kneeL = CGPoint(x: 20, y: 25)
            p.footR = CGPoint(x: -27, y: 33); p.kneeR = CGPoint(x: -22, y: 9) // talon recogido casi al gluteo
            p.handL = CGPoint(x: -24, y: 18); p.elbowL = CGPoint(x: -8, y: 22)  // brazo atras, codo cerrado
            p.handR = CGPoint(x: 30, y: 6); p.elbowR = CGPoint(x: 22, y: 20)   // puño delante cruzando
        }, .snappy), // el impacto se clava
        K(0.07, P { p in // ABSORCION: todo el peso comprime la pierna de apoyo
            p.neckOff = CGPoint(x: 17, y: -38); p.headOff = CGPoint(x: 8, y: -20); p.hipHeight = 47; p.squash = 0.92
            p.footL = CGPoint(x: 24, y: 47); p.kneeL = CGPoint(x: 21, y: 20)
            p.footR = CGPoint(x: -16, y: 30); p.kneeR = CGPoint(x: -24, y: 10)
            p.handL = CGPoint(x: -18, y: 24); p.handR = CGPoint(x: 26, y: 12)
        }, .easeIn), // sigue cargando el impulso...
        K(0.15, P { p in // IMPULSO: la pierna de apoyo se extiende y empuja (toe-off)
            p.neckOff = CGPoint(x: 16, y: -39); p.headOff = CGPoint(x: 6, y: -21); p.hipHeight = 54; p.squash = 1.05
            p.footL = CGPoint(x: -6, y: 46); p.kneeL = CGPoint(x: 4, y: 22)
            p.footR = CGPoint(x: 8, y: 28); p.kneeR = CGPoint(x: -14, y: 8) // rodilla libre ya sube
            p.handL = CGPoint(x: -4, y: 12); p.elbowL = CGPoint(x: -12, y: 18)
            p.handR = CGPoint(x: 14, y: 22); p.elbowR = CGPoint(x: 20, y: 16)
        }, .easeOut), // ...y despega
        K(0.29, P { p in // VUELO: ningun pie en el suelo; rodilla delantera alta, pierna trasera estirada atras
            p.neckOff = CGPoint(x: 15, y: -40); p.headOff = CGPoint(x: 7, y: -22); p.hipHeight = 57; p.squash = 1.02
            p.footL = CGPoint(x: -30, y: 36); p.kneeL = CGPoint(x: -18, y: 14) // trasera se estira en el aire
            p.footR = CGPoint(x: 24, y: 26); p.kneeR = CGPoint(x: 24, y: 12)   // delantera: muslo arriba, tibia colgando
            p.handL = CGPoint(x: 26, y: 8); p.elbowL = CGPoint(x: 20, y: 20)   // el bombeo cruza: puño contrario delante
            p.handR = CGPoint(x: -22, y: 20); p.elbowR = CGPoint(x: -6, y: 22)
        }, .easeIn), // la gravedad manda: cae hacia el siguiente contacto
        K(0.36, P { p in // CONTACTO pie derecho (espejo con leve asimetria)
            p.neckOff = CGPoint(x: 16, y: -39); p.headOff = CGPoint(x: 7, y: -21); p.hipHeight = 52
            p.footL = CGPoint(x: -26, y: 34); p.kneeL = CGPoint(x: -21, y: 9)
            p.footR = CGPoint(x: 34, y: 50); p.kneeR = CGPoint(x: 21, y: 25)
            p.handL = CGPoint(x: 31, y: 7); p.elbowL = CGPoint(x: 22, y: 20)
            p.handR = CGPoint(x: -23, y: 19); p.elbowR = CGPoint(x: -8, y: 22)
        }, .snappy),
        K(0.43, P { p in // ABSORCION derecha
            p.neckOff = CGPoint(x: 17, y: -38); p.headOff = CGPoint(x: 8, y: -20); p.hipHeight = 47; p.squash = 0.92
            p.footL = CGPoint(x: -15, y: 30); p.kneeL = CGPoint(x: -23, y: 10)
            p.footR = CGPoint(x: 25, y: 47); p.kneeR = CGPoint(x: 22, y: 20)
            p.handL = CGPoint(x: 27, y: 13); p.handR = CGPoint(x: -17, y: 25)
        }, .easeIn),
        K(0.51, P { p in // IMPULSO derecho -> cierra en el vuelo (el cierre del ciclo llega al contacto)
            p.neckOff = CGPoint(x: 16, y: -39); p.headOff = CGPoint(x: 6, y: -21); p.hipHeight = 55; p.squash = 1.05
            p.footL = CGPoint(x: 9, y: 27); p.kneeL = CGPoint(x: -13, y: 8)
            p.footR = CGPoint(x: -5, y: 45); p.kneeR = CGPoint(x: 5, y: 22)
            p.handL = CGPoint(x: 15, y: 23); p.handR = CGPoint(x: -3, y: 13)
        }, .easeOut)
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

    // -- Pelea con el cursor/dedo v4 (AvA 1: guerra contra el cursor;
    // AvA 2: golpes de TCO con todo el cuerpo) --
    // Cada golpe sigue el esquema de animacion tradicional:
    // ANTICIPACION corta (carga atras) -> GOLPE SECO (tramo snappy,
    // rapidisimo) -> pose de IMPACTO AGUANTADA -> recogida mas lenta.
    // La guardia entre golpes tiene bounce (no es una foto quieta).
    static let fightCombo = AnimationClip(name: "pelea", duration: 3.6, loops: true, keyframes: [
        K(0.0, P { p in // guardia baja y ancha, peso en los talones
            p.hipHeight = 49; p.neckOff = CGPoint(x: 6, y: -40); p.squash = 0.97
            p.footL = CGPoint(x: -20, y: 49); p.kneeL = CGPoint(x: -12, y: 26)
            p.footR = CGPoint(x: 22, y: 49); p.kneeR = CGPoint(x: 13, y: 26)
            p.handL = CGPoint(x: 17, y: 6); p.elbowL = CGPoint(x: 4, y: 17)
            p.handR = CGPoint(x: 27, y: 11); p.elbowR = CGPoint(x: 14, y: 20)
        }, .easeInOut),
        K(0.22, P { p in // bounce de guardia: sube un pelo, listo
            p.hipHeight = 51; p.squash = 1.0
            p.footL = CGPoint(x: -20, y: 51); p.footR = CGPoint(x: 22, y: 51)
            p.handL = CGPoint(x: 16, y: 8); p.handR = CGPoint(x: 26, y: 13)
        }, .easeIn), // empieza a cargar el jab: hombro atras
        K(0.38, P { p in // ANTICIPACION jab: el puño derecho se recoge y el torso gira
            p.hipHeight = 50; p.neckOff = CGPoint(x: 2, y: -40); p.hipDX = -2
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 22, y: 50)
            p.handR = CGPoint(x: 12, y: 14); p.elbowR = CGPoint(x: -2, y: 20)
            p.handL = CGPoint(x: 18, y: 6)
        }, .snappy), // ¡JAB! tramo seco: extension total en un instante
        K(0.47, P { p in // IMPACTO jab: puño clavado, torso volcado en el golpe
            p.hipHeight = 50; p.neckOff = CGPoint(x: 11, y: -39); p.hipDX = 3
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50)
            p.handR = CGPoint(x: 50, y: 4); p.elbowR = CGPoint(x: 28, y: 5)
            p.handL = CGPoint(x: 13, y: 11)
        }, .easeInOut), // AGUANTA el impacto (hold)
        K(0.62, P { p in // sigue clavado un instante mas
            p.hipHeight = 50; p.neckOff = CGPoint(x: 10, y: -39); p.hipDX = 3
            p.handR = CGPoint(x: 49, y: 5); p.elbowR = CGPoint(x: 28, y: 6)
            p.handL = CGPoint(x: 14, y: 10)
            p.footL = CGPoint(x: -21, y: 50); p.footR = CGPoint(x: 24, y: 50)
        }, .easeIn), // recogida: vuelve cargando el cross a la vez
        K(0.85, P { p in // ANTICIPACION cross: gira la cadera al reves, puño izquierdo atras
            p.hipHeight = 49; p.neckOff = CGPoint(x: 3, y: -40); p.hipDX = -3; p.squash = 0.96
            p.footL = CGPoint(x: -19, y: 49); p.footR = CGPoint(x: 23, y: 49)
            p.handL = CGPoint(x: 8, y: 13); p.elbowL = CGPoint(x: -6, y: 19)
            p.handR = CGPoint(x: 22, y: 10)
        }, .snappy), // ¡CROSS! con toda la cadera
        K(0.95, P { p in // IMPACTO cross
            p.hipHeight = 49; p.neckOff = CGPoint(x: 13, y: -39); p.hipDX = 5
            p.footL = CGPoint(x: -22, y: 49); p.footR = CGPoint(x: 25, y: 49)
            p.handL = CGPoint(x: 48, y: 7); p.elbowL = CGPoint(x: 26, y: 8)
            p.handR = CGPoint(x: 15, y: 11)
        }, .easeInOut), // hold
        K(1.12, P { p in p.handL = CGPoint(x: 47, y: 8); p.neckOff.x = 12; p.hipDX = 4; p.hipHeight = 49; p.footL = CGPoint(x: -22, y: 49); p.footR = CGPoint(x: 25, y: 49) }, .easeIn),
        K(1.32, P { p in // guardia, bounce
            p.hipHeight = 50; p.neckOff = CGPoint(x: 6, y: -40)
            p.footL = CGPoint(x: -20, y: 50); p.footR = CGPoint(x: 22, y: 50)
            p.handL = CGPoint(x: 17, y: 6); p.handR = CGPoint(x: 27, y: 11)
        }, .easeIn), // carga la patada: rodilla sube (chamber)
        K(1.52, P { p in // CHAMBER: rodilla alta, cuerpo echado atras
            p.hipHeight = 52; p.neckOff = CGPoint(x: -3, y: -41)
            p.footL = CGPoint(x: -13, y: 52)
            p.footR = CGPoint(x: 16, y: 26); p.kneeR = CGPoint(x: 26, y: 22)
            p.handL = CGPoint(x: -24, y: 20); p.handR = CGPoint(x: 20, y: 4)
        }, .snappy), // ¡PATADA FRONTAL! extension seca
        K(1.63, P { p in // IMPACTO patada: pierna recta a la altura del pecho del "cursor"
            p.hipHeight = 53; p.neckOff = CGPoint(x: -6, y: -41)
            p.footL = CGPoint(x: -14, y: 53)
            p.footR = CGPoint(x: 52, y: 18); p.kneeR = CGPoint(x: 32, y: 16)
            p.handL = CGPoint(x: -28, y: 24); p.handR = CGPoint(x: 16, y: 2)
        }, .easeInOut), // hold de impacto
        K(1.8, P { p in p.footR = CGPoint(x: 50, y: 20); p.kneeR = CGPoint(x: 31, y: 17); p.hipHeight = 52; p.neckOff.x = -5; p.footL = CGPoint(x: -14, y: 52) }, .easeIn), // recoge la pierna...
        K(2.0, P { p in // ...y se agacha cargando el barrido (anticipacion larga)
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
        K(3.3, P { p in // bounce final antes de cerrar el ciclo
            p.hipHeight = 49; p.neckOff = CGPoint(x: 6, y: -40); p.squash = 0.97
            p.footL = CGPoint(x: -20, y: 49); p.footR = CGPoint(x: 22, y: 49)
            p.handL = CGPoint(x: 17, y: 7); p.handR = CGPoint(x: 27, y: 12)
        }, .easeInOut)
    ])

    static let block = AnimationClip(name: "bloquear", duration: 0.9, loops: true, keyframes: [
        K(0.0, P { p in // antebrazos cruzados delante, firme
            p.hipHeight = 49; p.squash = 0.96
            p.handL = CGPoint(x: 15, y: -2); p.elbowL = CGPoint(x: -2, y: 16)
            p.handR = CGPoint(x: 13, y: 6); p.elbowR = CGPoint(x: 20, y: 18)
            p.footL = CGPoint(x: -16, y: 49); p.footR = CGPoint(x: 18, y: 49)
        }, .snappy), // ¡IMPACTO! el golpe le empuja hacia atras (flinch)
        K(0.14, P { p in
            p.hipHeight = 46; p.squash = 0.9; p.hipDX = -5; p.neckOff = CGPoint(x: -3, y: -39)
            p.handL = CGPoint(x: 13, y: -4); p.handR = CGPoint(x: 11, y: 4)
            p.footL = CGPoint(x: -19, y: 46); p.footR = CGPoint(x: 15, y: 46)
        }, .easeOut), // absorbe y vuelve a plantar los pies
        K(0.45, P { p in p.hipHeight = 49; p.squash = 0.97; p.hipDX = -1; p.handL = CGPoint(x: 16, y: -3); p.handR = CGPoint(x: 14, y: 5); p.footL = CGPoint(x: -16, y: 49); p.footR = CGPoint(x: 18, y: 49) }, .easeInOut),
        K(0.7, P { p in p.hipHeight = 48; p.handL = CGPoint(x: 15, y: -2); p.handR = CGPoint(x: 13, y: 6) }, .easeInOut) // aguanta en guardia
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

    // v4 (AvA 1): agarrarse al cursor y FORCEJEAR con el: se cuelga,
    // se balancea, patea el dedo y hasta intenta TREPAR por el.
    static let grabFinger = AnimationClip(name: "agarrar-dedo", duration: 1.5, loops: true, keyframes: [
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
        }, .easeInOut)
    ])

    // v4 (AvA 1): ser agarrado = PATALEO frenetico, nada de balanceo suave.
    static let grabbed = AnimationClip(name: "agarrado", duration: 0.72, loops: true, keyframes: [
        K(0.0, P { p in
            p.footL = CGPoint(x: -22, y: 38); p.kneeL = CGPoint(x: -15, y: 17)
            p.footR = CGPoint(x: 20, y: 44); p.kneeR = CGPoint(x: 14, y: 21)
            p.handL = CGPoint(x: -29, y: 4); p.handR = CGPoint(x: 27, y: 0); p.headOff = CGPoint(x: -3, y: -22)
        }, .linear),
        K(0.12, P { p in // patada izquierda, brazo contrario
            p.footL = CGPoint(x: -10, y: 46); p.kneeL = CGPoint(x: -8, y: 22)
            p.footR = CGPoint(x: 25, y: 36); p.kneeR = CGPoint(x: 17, y: 15)
            p.handL = CGPoint(x: -24, y: -6); p.handR = CGPoint(x: 30, y: 10); p.headOff = CGPoint(x: 3, y: -22)
        }, .linear),
        K(0.24, P { p in // patada derecha, se retuerce
            p.footL = CGPoint(x: -25, y: 42); p.kneeL = CGPoint(x: -17, y: 19)
            p.footR = CGPoint(x: 12, y: 47); p.kneeR = CGPoint(x: 9, y: 23)
            p.handL = CGPoint(x: -30, y: 10); p.handR = CGPoint(x: 24, y: -4); p.hipDX = -2
        }, .linear),
        K(0.36, P { p in // las dos piernas a la vez, empuja con todo
            p.footL = CGPoint(x: -16, y: 48); p.footR = CGPoint(x: 18, y: 48)
            p.kneeL = CGPoint(x: -10, y: 24); p.kneeR = CGPoint(x: 11, y: 24)
            p.handL = CGPoint(x: -26, y: -2); p.handR = CGPoint(x: 28, y: 6); p.hipDX = 2
        }, .linear),
        K(0.48, P { p in
            p.footL = CGPoint(x: -23, y: 36); p.footR = CGPoint(x: 23, y: 40)
            p.handL = CGPoint(x: -28, y: 8); p.handR = CGPoint(x: 26, y: -6); p.headOff = CGPoint(x: -3, y: -21)
        }, .linear),
        K(0.6, P { p in
            p.footL = CGPoint(x: -12, y: 45); p.footR = CGPoint(x: 15, y: 47)
            p.handL = CGPoint(x: -25, y: 0); p.handR = CGPoint(x: 29, y: 4)
        }, .linear)
    ])

    // v4 (AvA 1): forcejeo para escapar de la caja de seleccion: la
    // sacudida CRECE en amplitud como en el video (empieza floja y
    // acaba violentisima, empujando las "paredes" de la caja).
    static let escapeShake = AnimationClip(name: "escapar-caja", duration: 1.0, loops: true, keyframes: [
        K(0.0, P { $0.hipDX = -2; $0.squash = 0.97; $0.handL = CGPoint(x: -24, y: 16); $0.handR = CGPoint(x: 24, y: 16); $0.headOff = CGPoint(x: -2, y: -23) }, .linear),
        K(0.14, P { $0.hipDX = 2; $0.squash = 1.02; $0.headOff.x = 2 }, .linear),
        K(0.28, P { $0.hipDX = -3; $0.squash = 0.95; $0.handL = CGPoint(x: -27, y: 14); $0.handR = CGPoint(x: 25, y: 20); $0.headOff.x = -3 }, .linear),
        K(0.42, P { $0.hipDX = 4; $0.squash = 1.05; $0.headOff.x = 4 }, .linear),
        K(0.56, P { $0.hipDX = -5; $0.squash = 0.93; $0.handL = CGPoint(x: -29, y: 18); $0.handR = CGPoint(x: 28, y: 12); $0.headOff.x = -5 }, .linear), // empuja la pared de la caja
        K(0.7, P { $0.hipDX = 5; $0.squash = 1.07; $0.headOff.x = 5 }, .linear),
        K(0.84, P { $0.hipDX = -6; $0.squash = 0.92; $0.handL = CGPoint(x: -30, y: 12); $0.handR = CGPoint(x: 30, y: 18); $0.headOff.x = -6 }, .linear) // ¡a punto de romperla!
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
    // v4 (AvA 2): la carga de energia de TCO — se agacha, aprieta los
    // puños y el temblor CRECE hasta que el aura estalla.
    static let chargePower = AnimationClip(name: "cargar-energia", duration: 1.9, loops: false, keyframes: [
        K(0.0, SkeletonPose.standing, .easeIn),
        K(0.55, P { p in // se agacha cargando, puños a los lados, primer temblor
            p.hipHeight = 41; p.squash = 0.89; p.neckOff = CGPoint(x: 0, y: -35)
            p.handL = CGPoint(x: -23, y: 23); p.handR = CGPoint(x: 23, y: 23)
            p.elbowL = CGPoint(x: -17, y: 16); p.elbowR = CGPoint(x: 17, y: 16)
            p.footL = CGPoint(x: -21, y: 41); p.footR = CGPoint(x: 21, y: 41)
        }, .linear), // el temblor crece: amplitud 1 -> 2 -> 3
        K(0.85, P { $0.hipDX = -1; $0.hipHeight = 41 }, .linear),
        K(1.05, P { $0.hipDX = 1.5; $0.hipHeight = 40 }, .linear),
        K(1.25, P { $0.hipDX = -2.5; $0.hipHeight = 40; $0.squash = 0.87 }, .linear),
        K(1.45, P { $0.hipDX = 3; $0.hipHeight = 39 }, .easeOut), // ¡ESTALLA el aura! se yergue de golpe
        K(1.65, P { p in
            p.hipHeight = 59; p.squash = 1.08; p.hipDX = 0
            p.neckOff = CGPoint(x: 0, y: -43); p.headOff = CGPoint(x: 0, y: -24)
            p.handL = CGPoint(x: -26, y: -22); p.handR = CGPoint(x: 26, y: -22)
            p.elbowL = CGPoint(x: -18, y: -4); p.elbowR = CGPoint(x: 18, y: -4)
            p.footL = CGPoint(x: -19, y: 53); p.footR = CGPoint(x: 19, y: 53)
        }, .easeInOut), // aguanta en la pose de poder, aura fuera
        K(1.9, P { p in p.hipHeight = 58; p.squash = 1.05; p.handL = CGPoint(x: -25, y: -20); p.handR = CGPoint(x: 25, y: -20) })
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
        }, .easeInOut), // AGUANTA el golpe clavado (la onda hace el resto)
        K(0.78, P { p in p.handR = CGPoint(x: 56, y: 3); p.neckOff.x = 16; p.hipDX = 8 }, .easeIn), // recoge despacio, sobrado
        K(1.15, P { p in p.handR = CGPoint(x: 28, y: 12); p.neckOff.x = 5; p.hipDX = 2; p.hipHeight = 54 }, .softLanding)
    ])
    static let strengthPose = AnimationClip(name: "superfuerza", duration: 1.6, loops: true, keyframes: [
        K(0.0, P { p in // bloque sobre la cabeza, piernas tiemblan un poco
            p.handL = CGPoint(x: -17, y: -34); p.handR = CGPoint(x: 17, y: -34)
            p.elbowL = CGPoint(x: -16, y: -10); p.elbowR = CGPoint(x: 16, y: -10)
            p.hipHeight = 51; p.footL = CGPoint(x: -17, y: 51); p.footR = CGPoint(x: 17, y: 51)
        }, .easeInOut),
        K(0.8, P { p in p.hipHeight = 53; p.hipDX = 1 }, .easeInOut)
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
