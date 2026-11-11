import Foundation

// MARK: - V10 · MOTOR DE MOVIMIENTO PROCEDURAL («hazlo tuyo»)
//
// Orden del usuario (2026-11-12): la build de clips «sigue siendo muy
// floja» — reproducir keyframes se siente marioneta sin peso. Cambio
// de fondo: la LOCOMOCION y las TRANSICIONES ya no se muestrean de
// clips, se GENERAN cada frame y se resuelven con fisica de muelles:
//
//  * GENERADORES (ProceduralPoseGen): marcha/carrera desde blancos de
//    pie alternos (apoyo con el pie plantado a la altura real de la
//    cadera, balanceo con arco y pliegue de talon, balanceo de pelvis,
//    inclinacion del torso segun la ACELERACION real, zancada y
//    frecuencia ligadas a la velocidad real via gaitPhase01 del
//    motor); idle con respiracion y cambios de peso generados; aire
//    (subida/apex/caida) mezclado por la velocidad vertical REAL, con
//    estiramiento al caer y pose de estrella al ser lanzado.
//  * SOLUCIONADOR (ProceduralBody): cada articulacion de la pose
//    objetivo pasa por un muelle amortiguado (spring-damper) con
//    rigidez/amortiguacion POR GRUPO (masa, torso, brazos, piernas,
//    squash): los brazos llegan tarde (follow-through), la cadera
//    rebota al aterrizar con un impulso proporcional al impacto, el
//    cuerpo lanzado GIRA con velocidad angular y se recupera con
//    overshoot elastico. Energia «loquita» intacta: los muelles van
//    SUBamortiguados a proposito (zeta 0,33–0,9 segun grupo), nada de
//    sobre-amortiguar hasta dejarlo soso.
//  * Los 124 clips especiales (gestos, pelea, vida, cinemáticas) NO
//    se tocan: su salida pasa por el mismo solucionador con el perfil
//    que toque (pesado en aterrizar/levantarse/sentarse, suelto al
//    ser agarrado), asi que heredan peso sin reescribirlos. Las
//    cinematicas imponen su pose exacta (snap): son beats guionizados.
//  * El cerebro y las acciones siguen mandando INTENCIONES (caminar
//    a X, saltar, huir, sentarse...); esto solo cambia COMO se mueve.
//  * Las superficies y los dibujos solidos de la ronda 2/fusion no se
//    tocan: el motor consume las mismas (contexto de superficie del
//    controlador; en pared/techo manda el sistema anterior).

// MARK: Constantes UNICAS del motor (todo numero vive aqui)

enum ProceduralTuning {
    /// Longitudes de referencia de la pose de pie (para el pliegue de
    /// rodilla/codo por heuristica de punto medio, ver midJoint):
    /// muslo+ tibia de SkeletonPose.standing (~29,2 + ~29,1).
    static let legReach: CGFloat = 58.3
    /// Brazo + antebrazo de la pose de pie (~25,5 + ~21,2).
    static let armReach: CGFloat = 51.5
    /// Velocidad angular del vuelco al ser lanzado (rad/s).
    static let spinRate: CGFloat = 5.4
    /// Perfiles de muelle por modo (k en 1/s², zeta adimensional).
    static let profileStandard = SpringProfile(massK: 120, massZ: 0.60, torsoK: 150, torsoZ: 0.72, armK: 85, armZ: 0.52, legK: 260, legZ: 0.88, squashK: 130, squashZ: 0.45)
    static let profileGait = SpringProfile(massK: 500, massZ: 0.80, torsoK: 170, torsoZ: 0.74, armK: 95, armZ: 0.55, legK: 430, legZ: 0.90, squashK: 150, squashZ: 0.50)
    static let profileSoft = SpringProfile(massK: 90, massZ: 0.60, torsoK: 120, torsoZ: 0.70, armK: 70, armZ: 0.50, legK: 200, legZ: 0.85, squashK: 120, squashZ: 0.45)
    static let profileHeavy = SpringProfile(massK: 95, massZ: 0.40, torsoK: 130, torsoZ: 0.60, armK: 80, armZ: 0.45, legK: 240, legZ: 0.80, squashK: 105, squashZ: 0.33)
    static let profileLoose = SpringProfile(massK: 120, massZ: 0.55, torsoK: 110, torsoZ: 0.55, armK: 55, armZ: 0.38, legK: 120, legZ: 0.50, squashK: 120, squashZ: 0.45)
}

struct SpringProfile {
    var massK: CGFloat, massZ: CGFloat       // cadera (hipHeight/hipDX): la MASA
    var torsoK: CGFloat, torsoZ: CGFloat     // cuello y cabeza
    var armK: CGFloat, armZ: CGFloat         // codos y manos (los mas rezagados)
    var legK: CGFloat, legZ: CGFloat         // rodillas y pies (los mas firmes)
    var squashK: CGFloat, squashZ: CGFloat   // aplastamiento (el mas rebotante)
}

// MARK: Contexto por frame (lo construye la vista desde el controlador)

struct ProceduralContext {
    var action: StickmanAction
    var surfaceIsFloor = true
    var facing: CGFloat = 1
    var gaitPhase01: Double = 0
    var speedNorm: CGFloat = 0
    var moveSpeed: CGFloat = 0
    var animTime: Double = 0
    var time: Double = 0            // reloj global (controller.phase)
    var velocityY: CGFloat = 0
    var isAirborne = false
    var isJumpWindingUp = false
    var isSkidding = false
    var isTurning = false
    var isWallSliding = false
    var pinchLean: CGFloat = 0
    var microActivity = "respira"
    var hasCinematicPose = false
}

// MARK: - Generadores de pose (puros y deterministas)

enum ProceduralPoseGen {

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    static func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(hi, max(lo, v)) }
    static func frac(_ x: Double) -> Double { x - floor(x) }
    static func sstep(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        let t = clamp((x - a) / (b - a), 0, 1)
        return t * t * (3 - 2 * t)
    }

    /// Articulacion intermedia SIN IK rigida (las poses de autor de
    /// los clips estiran/acortan segmentos ±20 %: la lectura manda,
    /// no la anatomia): punto medio raiz->objetivo empujado en
    /// perpendicular. `forward` = la articulacion abulta hacia +x
    /// (rodillas); si no, hacia atras (codos).
    static func midJoint(root: CGPoint, target: CGPoint, bend: CGFloat, forward: Bool) -> CGPoint {
        let dx = target.x - root.x, dy = target.y - root.y
        let len = max(4, hypot(dx, dy))
        var px = dy / len, py = -dx / len       // perpendicular «hacia delante»
        if !forward { px = -px; py = -py }
        return CGPoint(x: (root.x + target.x) / 2 + px * bend,
                       y: (root.y + target.y) / 2 + py * bend)
    }
    /// Pliegue de pierna: cuanto mas corto el alcance efectivo, mas
    /// se dobla; minimo 2,5 (nunca recta de palo) y tope 17.
    static func legBend(to foot: CGPoint, extra: CGFloat = 0) -> CGFloat {
        clamp((ProceduralTuning.legReach - hypot(foot.x, foot.y)) * 0.55, 2.5, 17) + extra
    }
    static func armBend(to hand: CGPoint) -> CGFloat {
        clamp((ProceduralTuning.armReach - hypot(hand.x, hand.y)) * 0.5, 2, 13) + 2
    }

    // MARK: Marcha / carrera generadas por blancos de pie

    static func gait(phase rawPhase: Double, speedNorm sRaw: CGFloat, lean: CGFloat) -> SkeletonPose {
        let s = clamp(sRaw, 0, 1)
        let phase = frac(rawPhase)
        let stanceF = lerp(0.60, 0.36, s)         // fraccion de ciclo en apoyo (correr vuela mas)
        let stride = lerp(47, 84, s)              // recorrido del pie en apoyo (uds de pose)
        let clearance = lerp(9, 13.5, s)          // altura del pie en balanceo
        let hipBase = lerp(53.0, 52.0, s)
        let bobAmp = lerp(1.7, 6.4, s)
        // La cadera cae JUSTO tras cada contacto (minimos en .09/.59)
        // y se eleva en el paso/vuelo (.34/.84): dos botes por ciclo.
        let c4 = CGFloat(cos(4 * Double.pi * (phase - 0.09)))
        let hipH = hipBase - bobAmp * c4

        var p = SkeletonPose.standing
        p.hipHeight = hipH
        p.squash = 1 - s * 0.085 * max(0, c4) + s * 0.05 * max(0, -c4)

        var footX: [CGFloat] = [0, 0]
        var footY: [CGFloat] = [0, 0]
        var swingAmt: [CGFloat] = [0, 0]
        var stanceSum: CGFloat = 0, stanceCount: CGFloat = 0
        for i in 0...1 {
            let psi = frac(phase + 0.5 * Double(i))
            if psi < Double(stanceF) {
                // APOYO: el pie esta PLANTADO (su y = altura de la
                // cadera: toca el suelo) y barre de delante a atras a
                // velocidad constante = la del suelo (sin patinar).
                let u = CGFloat(psi / Double(stanceF))
                footX[i] = stride / 2 - stride * u
                footY[i] = hipH
                stanceSum += footX[i]; stanceCount += 1
            } else {
                // BALANCEO: vuelve delante por un arco, con pliegue
                // de talon extra al correr al principio del avance.
                let u = CGFloat((psi - Double(stanceF)) / (1 - Double(stanceF)))
                let e = u + (u * u * (3 - 2 * u) - u) * 0.5
                footX[i] = -stride / 2 + stride * e
                let lift = clearance * CGFloat(pow(sin(Double.pi * Double(u)), 0.9))
                let fold = s * 5 * CGFloat(sin(Double.pi * Double(min(u * 1.6, 1))))
                footY[i] = hipH - lift - fold
                swingAmt[i] = CGFloat(sin(Double.pi * Double(u)))
            }
        }
        // VUELO (ningun pie en apoyo, solo al correr): la zancada se
        // ABRE en el aire como en los videos (si no, los pies se
        // juntan bajo el cuerpo y la carrera se lee floja).
        if stanceCount == 0 {
            let front = footX[0] >= footX[1] ? 0 : 1
            footX[front] += 11 * s
            footX[1 - front] -= 11 * s
        }
        for i in 0...1 {
            let foot = CGPoint(x: footX[i], y: footY[i])
            let knee = midJoint(root: .zero, target: foot,
                                bend: legBend(to: foot, extra: swingAmt[i] * (2.5 + 4.5 * s)),
                                forward: true)
            if i == 0 { p.footL = foot; p.kneeL = knee } else { p.footR = foot; p.kneeR = knee }
        }
        // La pelvis se desplaza sobre el pie de apoyo (no va centrada
        // como un palo) y acompana un poco a la inclinacion.
        if stanceCount > 0 { p.hipDX = clamp(0.35 * stanceSum / stanceCount, -4, 5) + lean * 0.25 + s * 2.5 }

        // Torso: inclinacion base por velocidad + la que manda la
        // aceleracion (lean); el cuello ABSORBE el boteo (cuando la
        // cadera cae, el torso se acorta un pelo y se vuelca).
        p.neckOff = CGPoint(x: lerp(4, 23, s) + lean + (54 - hipH) * 0.30,
                            y: -42 + (54 - hipH) * 0.20)
        // Cabeza estabilizada: contrafase vertical (absorbe el boteo).
        p.headOff = CGPoint(x: lerp(1, 10, s) + lean * 0.4,
                            y: -22.5 + (hipH - hipBase) * 0.30)
        // Brazos en contra de la pierna del mismo lado (contralateral
        // cruzado: mano = -0,95 x pie), con bombeo al correr.
        let handBaseY = lerp(40, 15, s)
        for i in 0...1 {
            let hy = handBaseY - 3 * s * CGFloat(sin(2 * Double.pi * (phase + 0.5 * Double(i) + 0.5)))
            let hand = CGPoint(x: -0.95 * footX[i], y: hy)
            let elbow = midJoint(root: .zero, target: hand, bend: armBend(to: hand), forward: false)
            if i == 0 { p.handL = hand; p.elbowL = elbow } else { p.handR = hand; p.elbowR = elbow }
        }
        return p
    }

    // MARK: Idle generado: respiracion + cambio de peso aguantado

    static func idle(time t: Double) -> SkeletonPose {
        var p = SkeletonPose.standing
        let breath = sin(2 * Double.pi * t / 4.8)                 // el ritmo del clip idle
        let cyc = floor(t / 4.8)
        let fr = (t / 4.8) - cyc
        let even = Int(cyc) % 2 == 0
        let cur: CGFloat = even ? -2 : 2.5                        // se AGUANTA en cada lado
        let prev: CGFloat = cyc < 1 ? cur : (even ? 2.5 : -2)
        let blend = sstep(CGFloat(fr) / 0.14, 0, 1)
        p.hipDX = prev + (cur - prev) * blend + CGFloat(sin(2 * Double.pi * t / 1.7)) * 0.3
        p.hipHeight = 55.8 + CGFloat(breath) * 0.35
        p.neckOff = CGPoint(x: CGFloat(sin(2 * Double.pi * t / 7.3)) * 0.6,
                            y: -42 + CGFloat(breath) * 0.9)
        p.headOff = CGPoint(x: CGFloat(sin(2 * Double.pi * t / 9.1)) * 1.6,
                            y: -23 + CGFloat(breath) * 0.5)
        p.squash = 1 + CGFloat(breath) * 0.007
        // Pies plantados (su y sigue a la cadera: el suelo no se mueve)
        let fl = CGPoint(x: -13, y: p.hipHeight), frt = CGPoint(x: 13, y: p.hipHeight)
        p.footL = fl; p.footR = frt
        p.kneeL = midJoint(root: .zero, target: fl, bend: legBend(to: fl), forward: true)
        p.kneeR = midJoint(root: .zero, target: frt, bend: legBend(to: frt), forward: true)
        let hl = CGPoint(x: -20 - CGFloat(breath) * 0.8, y: 40)
        let hr = CGPoint(x: 20 + CGFloat(breath) * 0.8, y: 40)
        p.handL = hl; p.handR = hr
        p.elbowL = midJoint(root: .zero, target: hl, bend: armBend(to: hl), forward: false)
        p.elbowR = midJoint(root: .zero, target: hr, bend: armBend(to: hr), forward: false)
        return p
    }

    // MARK: Aire generado: subida / apex / caida por velocidad real

    static func air(velocityY vy: CGFloat, animTime t: Double, thrown: Bool) -> SkeletonPose {
        if thrown {
            // Estrella que se debate: miembros abiertos y aleteo.
            var p = SkeletonPose.standing
            p.hipHeight = 55; p.neckOff = CGPoint(x: 0, y: -40); p.headOff = CGPoint(x: 0, y: -21)
            p.squash = 1.02
            p.footL = CGPoint(x: -27, y: 38); p.kneeL = CGPoint(x: -16, y: 18)
            p.footR = CGPoint(x: 28, y: 42); p.kneeR = CGPoint(x: 17, y: 20)
            p.handL = CGPoint(x: -35 + CGFloat(sin(t * 11)) * 5, y: -8 + CGFloat(cos(t * 13)) * 4)
            p.handR = CGPoint(x: 35 + CGFloat(sin(t * 11 + 2)) * 5, y: -4)
            p.elbowL = CGPoint(x: -24, y: 4); p.elbowR = CGPoint(x: 24, y: 6)
            p.footL.x += CGFloat(sin(t * 9 + 1)) * 4
            p.footR.x -= CGFloat(sin(t * 9.7)) * 4
            return p
        }
        // Tres poses clave generadas; la mezcla la manda vy REAL
        // (los clips solo conocian animTime: por eso se veia flojo).
        var rise = SkeletonPose.standing
        rise.hipHeight = 57; rise.neckOff = CGPoint(x: 6, y: -43); rise.headOff = CGPoint(x: 3, y: -23)
        rise.squash = 1.05
        rise.footL = CGPoint(x: -14, y: 54); rise.kneeL = CGPoint(x: -4, y: 30)
        rise.footR = CGPoint(x: 16, y: 47); rise.kneeR = CGPoint(x: 14, y: 22)
        rise.handL = CGPoint(x: -26, y: 6); rise.elbowL = CGPoint(x: -20, y: 16)
        rise.handR = CGPoint(x: 24, y: -2); rise.elbowR = CGPoint(x: 20, y: 14)

        var apex = SkeletonPose.standing
        apex.hipHeight = 56; apex.neckOff = CGPoint(x: 3, y: -42); apex.headOff = CGPoint(x: 2, y: -22.5)
        apex.footL = CGPoint(x: -18, y: 44); apex.kneeL = CGPoint(x: -8, y: 24)
        apex.footR = CGPoint(x: 20, y: 42); apex.kneeR = CGPoint(x: 16, y: 20)
        apex.handL = CGPoint(x: -24, y: 14); apex.elbowL = CGPoint(x: -18, y: 22)
        apex.handR = CGPoint(x: 24, y: 14); apex.elbowR = CGPoint(x: 18, y: 22)

        var fall = SkeletonPose.standing
        fall.hipHeight = 57.5; fall.neckOff = CGPoint(x: 2, y: -41); fall.headOff = CGPoint(x: 1, y: -22)
        fall.squash = 0.97
        fall.footL = CGPoint(x: -8, y: 56); fall.kneeL = CGPoint(x: -2, y: 30)
        fall.footR = CGPoint(x: 14, y: 58); fall.kneeR = CGPoint(x: 10, y: 30)
        // Molinete lento buscando el equilibrio (fase por animTime)
        let a = t * 7
        fall.handL = CGPoint(x: CGFloat(-24 * cos(a)), y: CGFloat(12 + 9 * sin(a)))
        fall.handR = CGPoint(x: CGFloat(24 * cos(a)), y: CGFloat(12 - 9 * sin(a)))
        fall.elbowL = CGPoint(x: fall.handL.x * 0.6, y: fall.handL.y + 12)
        fall.elbowR = CGPoint(x: fall.handR.x * 0.6, y: fall.handR.y + 12)

        let wR = sstep(vy, 60, 260)
        let wF = sstep(-vy, 60, 260)
        var p = apex
        if wR > 0 { p = p.lerped(to: rise, t: wR) }
        if wF > 0 { p = p.lerped(to: fall, t: wF) }
        // Estiramiento con la velocidad de caida (el cuerpo se alarga)
        if vy < -260 { p.squash = 0.97 + CGFloat(min(1, Double(-vy - 260) / 700)) * 0.05 }
        return p
    }
}

// MARK: - Solucionador de muelles (estado entre frames)

final class ProceduralBody {

    /// Pose resuelta del frame actual (la vista la consume en
    /// jointPoints/drawStickman sin recalcular).
    private(set) var framePose: SkeletonPose?
    /// Giro del cuerpo entero (rad, espacio de pantalla): lo integra
    /// el solucionador y lo aplica la vista girando las articulaciones
    /// alrededor de la cadera. 0 salvo lanzado/inclinacion en salto.
    private(set) var bodyAngle: CGFloat = 0

    private var cur: SkeletonPose?
    private var vel = SkeletonPose(hipHeight: 0, hipDX: 0, neckOff: .zero, headOff: .zero,
                                   elbowL: .zero, handL: .zero, elbowR: .zero, handR: .zero,
                                   kneeL: .zero, footL: .zero, kneeR: .zero, footR: .zero, squash: 0)
    private var angleVel: CGFloat = 0
    private var lastTime: Double?
    private var prevSpeed: CGFloat = 0
    private var smoothedAccel: CGFloat = 0
    private var prevAirborne = false
    private var lastAirVy: CGFloat = 0
    private var wasThrown = false
    private var spinSign: CGFloat = 1

    /// Inclinacion actual del torso por aceleracion (uds de pose).
    private var lean: CGFloat { ProceduralPoseGen.clamp(smoothedAccel * 0.016, -9, 11) }

    private func snap(to p: SkeletonPose) {
        cur = p
        vel = SkeletonPose(hipHeight: 0, hipDX: 0, neckOff: .zero, headOff: .zero,
                           elbowL: .zero, handL: .zero, elbowR: .zero, handR: .zero,
                           kneeL: .zero, footL: .zero, kneeR: .zero, footR: .zero, squash: 0)
        bodyAngle = 0; angleVel = 0
        framePose = p
    }

    @discardableResult
    func resolve(context ctx: ProceduralContext, clipPose: () -> SkeletonPose) -> SkeletonPose {
        // Cinematicas: la escena impone la pose EXACTA (snap, sin
        // muelles): son beats guionizados, no locomocion.
        if ctx.hasCinematicPose {
            let p = clipPose()
            snap(to: p)
            lastTime = ctx.time
            prevAirborne = ctx.isAirborne
            return p
        }
        let rawDt = lastTime.map { ctx.time - $0 } ?? 0
        if rawDt <= 0.0001, let f = framePose { return f }     // mismo frame: no re-integrar
        if cur == nil || rawDt > 0.25 {                        // primer frame o teletransporte
            let (target, _) = targetAndProfile(ctx, clipPose: clipPose)
            snap(to: target)
            lastTime = ctx.time
            prevSpeed = ctx.moveSpeed
            prevAirborne = ctx.isAirborne
            return target
        }
        let dt = min(rawDt, 0.05)

        // Aceleracion suavizada -> inclinacion (arrancar se vuelca,
        // frenar se echa atras: el derrape del clip remata).
        let instAccel = (ctx.moveSpeed - prevSpeed) / CGFloat(dt)
        smoothedAccel += (instAccel - smoothedAccel) * 0.30
        prevSpeed = ctx.moveSpeed

        // Aterrizaje: el impacto REAL (ultima vy en el aire) entra
        // como impulso en los muelles de masa y squash: a mas duro el
        // golpe, mas se hunde y mas rebota al recuperarse.
        if prevAirborne && !ctx.isAirborne && lastAirVy < -150 {
            let impact = -lastAirVy
            vel.squash -= min(2.2, impact * 0.0016)
            vel.hipHeight -= min(26, impact * 0.016)
            if wasThrown { angleVel += spinSign * 1.6 }
        }

        let (target, profile) = targetAndProfile(ctx, clipPose: clipPose)
        integrate(target: target, profile: profile, dt: dt)
        updateAngle(ctx, dt: dt)

        lastTime = ctx.time
        prevAirborne = ctx.isAirborne
        if ctx.isAirborne { lastAirVy = ctx.velocityY }
        framePose = cur
        return cur ?? target
    }

    // MARK: Objetivo y perfil segun la intencion

    private func targetAndProfile(_ ctx: ProceduralContext, clipPose: () -> SkeletonPose) -> (SkeletonPose, SpringProfile) {
        let a = ctx.action
        if ctx.surfaceIsFloor && !ctx.isJumpWindingUp && !ctx.isSkidding && !ctx.isTurning && !ctx.isWallSliding {
            // Aire: pose GENERADA por velocidad (salto/caida/lanzado)
            if ctx.isAirborne && (a == .jumping || a == .thrown || a == .dropping) {
                return (ProceduralPoseGen.air(velocityY: ctx.velocityY, animTime: ctx.animTime, thrown: a == .thrown),
                        ProceduralTuning.profileLoose)
            }
            switch a {
            case .walking, .running, .fleeing, .chasingFinger, .playingBall:
                // Locomocion GENERADA (ya no se muestrean walk/run)
                return (ProceduralPoseGen.gait(phase: ctx.gaitPhase01, speedNorm: ctx.speedNorm, lean: lean),
                        ProceduralTuning.profileGait)
            case .idle:
                // Idle generado, salvo las micro-acciones de clip
                // (rascarse / mirar), que quedan como clips con peso.
                if ctx.microActivity != "se rasca la cabeza" && ctx.microActivity != "mira a un lado" {
                    return (ProceduralPoseGen.idle(time: ctx.time), ProceduralTuning.profileSoft)
                }
            case .grabbed, .escaping:
                // Clip de agarrado + capa procedural: pataleo que crece
                // con el forcejeo y balanceo pendular tras el tiron.
                var p = clipPose()
                let t = ctx.animTime
                let amp = 3 + min(t, 1.6) * 2.2
                let s1 = CGFloat(sin(t * 12.5)) * CGFloat(amp)
                let s2 = CGFloat(sin(t * 12.5 + 2.1)) * CGFloat(amp) * 0.8
                p.footL.x += s1; p.footR.x -= s2
                p.footL.y -= abs(s1) * 0.35; p.footR.y -= abs(s2) * 0.35
                p.hipDX += ctx.pinchLean * 3
                p.neckOff.x += ctx.pinchLean * 4
                p.headOff.x += ctx.pinchLean * 3
                p.handL.y -= 5; p.handR.y -= 5
                return (p, ProceduralTuning.profileLoose)
            case .landing, .gettingUp, .sitting, .rolling, .tripping, .squashed, .bouncing:
                // Transiciones de peso: el clip manda la forma, los
                // muelles pesados (subamortiguados) ponen el PESO:
                // hundirse, pasar de largo y asentarse.
                return (clipPose(), ProceduralTuning.profileHeavy)
            default:
                break
            }
        }
        // Todo lo demas (los 124 clips: gestos, pelea, vida, trepar,
        // superficies): clip intacto, salida por los muelles estandar.
        return (clipPose(), ProceduralTuning.profileStandard)
    }

    // MARK: Integracion de muelles (semi-implicita, subpasos 120 Hz)

    private func spring(_ x: inout CGFloat, _ v: inout CGFloat, target: CGFloat, k: CGFloat, zeta: CGFloat, dt: Double) {
        let a = Double(k) * Double(target - x) - 2 * Double(zeta) * sqrt(Double(k)) * Double(v)
        v += CGFloat(a * dt)
        x += v * CGFloat(dt)
    }
    private func springPoint(_ p: inout CGPoint, _ v: inout CGPoint, target: CGPoint, k: CGFloat, zeta: CGFloat, dt: Double) {
        spring(&p.x, &v.x, target: target.x, k: k, zeta: zeta, dt: dt)
        spring(&p.y, &v.y, target: target.y, k: k, zeta: zeta, dt: dt)
    }

    private func integrate(target: SkeletonPose, profile pr: SpringProfile, dt: Double) {
        guard var c = cur else { cur = target; return }
        let steps = max(1, Int(ceil(dt / (1.0 / 120.0))))
        let h = dt / Double(steps)
        for _ in 0..<steps {
            spring(&c.hipHeight, &vel.hipHeight, target: target.hipHeight, k: pr.massK, zeta: pr.massZ, dt: h)
            spring(&c.hipDX, &vel.hipDX, target: target.hipDX, k: pr.massK, zeta: pr.massZ, dt: h)
            springPoint(&c.neckOff, &vel.neckOff, target: target.neckOff, k: pr.torsoK, zeta: pr.torsoZ, dt: h)
            springPoint(&c.headOff, &vel.headOff, target: target.headOff, k: pr.torsoK, zeta: pr.torsoZ, dt: h)
            springPoint(&c.elbowL, &vel.elbowL, target: target.elbowL, k: pr.armK, zeta: pr.armZ, dt: h)
            springPoint(&c.handL, &vel.handL, target: target.handL, k: pr.armK, zeta: pr.armZ, dt: h)
            springPoint(&c.elbowR, &vel.elbowR, target: target.elbowR, k: pr.armK, zeta: pr.armZ, dt: h)
            springPoint(&c.handR, &vel.handR, target: target.handR, k: pr.armK, zeta: pr.armZ, dt: h)
            springPoint(&c.kneeL, &vel.kneeL, target: target.kneeL, k: pr.legK, zeta: pr.legZ, dt: h)
            springPoint(&c.footL, &vel.footL, target: target.footL, k: pr.legK, zeta: pr.legZ, dt: h)
            springPoint(&c.kneeR, &vel.kneeR, target: target.kneeR, k: pr.legK, zeta: pr.legZ, dt: h)
            springPoint(&c.footR, &vel.footR, target: target.footR, k: pr.legK, zeta: pr.legZ, dt: h)
            spring(&c.squash, &vel.squash, target: target.squash, k: pr.squashK, zeta: pr.squashZ, dt: h)
        }
        cur = c
    }

    // MARK: Giro del cuerpo (lanzado) e inclinacion en salto

    private func updateAngle(_ ctx: ProceduralContext, dt: Double) {
        if ctx.isAirborne && ctx.action == .thrown {
            // Vuelco balistico: velocidad angular casi constante, con
            // entrada suave; el sentido lo fija el lado del lanzamiento.
            if !wasThrown { spinSign = ctx.facing >= 0 ? 1 : -1; wasThrown = true }
            let target = ProceduralTuning.spinRate * spinSign
            angleVel += (target - angleVel) * CGFloat(1 - exp(-7 * dt))
            bodyAngle += angleVel * CGFloat(dt)
            return
        }
        wasThrown = false
        var target: CGFloat = 0
        if ctx.isAirborne && (ctx.action == .jumping || ctx.action == .dropping) {
            // Inclina con la velocidad: sube volcado, cae echandose atras
            target = ctx.facing * ProceduralPoseGen.clamp(ctx.velocityY * 0.00012, -0.09, 0.13)
        } else {
            // Recuperacion: al multiplo de vuelta completa mas cercano,
            // con muelle subamortiguado (pasa de largo y vuelve: elastico)
            target = (bodyAngle / (2 * CGFloat.pi)).rounded() * 2 * CGFloat.pi
        }
        let k = 65.0, z = 0.5
        let acc = k * Double(target - bodyAngle) - 2 * z * sqrt(k) * Double(angleVel)
        angleVel += CGFloat(acc * dt)
        bodyAngle += angleVel * CGFloat(dt)
        if !ctx.isAirborne && abs(bodyAngle - target) < 0.002 && abs(angleVel) < 0.02 {
            bodyAngle = 0; angleVel = 0
        }
    }
}
