import SwiftUI

// MARK: - Dibujo procedural del stickman (Canvas, sin assets)
// Cabeza hueca naranja como The Second Coming, esqueleto articulado por codigo.

struct StickmanCanvasView: View {
    @ObservedObject var controller: StickmanController

    private let orange = Color(red: 1.0, green: 0.45, blue: 0.0)

    var body: some View {
        Canvas { context, size in
            drawScene(context: &context, size: size)
        }
    }

    // MARK: Escena completa

    private func drawScene(context: inout GraphicsContext, size: CGSize) {
        let groundY = size.height - 10
        let c = controller
        let effectiveGround = groundY - c.platformHeight - c.heightAboveGround
        let cx = c.x

        drawPlatforms(context: &context, size: size, groundY: groundY)
        if let frozenX = c.frozenPatchX { drawFrozenPatch(context: &context, x: frozenX, groundY: groundY) }
        for object in c.objects { drawObject(context: &context, object: object, groundY: groundY, stickmanX: cx, effectiveGround: effectiveGround) }

        // Aura del Modo Chosen One
        if c.isChosenOne {
            var aura = context
            aura.opacity = 0.16 + 0.07 * sin(c.phase * 6)
            let rect = CGRect(x: cx - 62, y: effectiveGround - 168, width: 124, height: 168)
            aura.fill(Path(ellipseIn: rect), with: .color(.yellow))
        }
        // Imagenes fantasma de la supervelocidad
        if c.activePower == .superSpeed {
            drawStickman(context: &context, cx: cx - c.facing * 34, ground: effectiveGround, size: size, opacity: 0.22)
            drawStickman(context: &context, cx: cx - c.facing * 68, ground: effectiveGround, size: size, opacity: 0.10)
        }
        drawPowerEffects(context: &context, size: size, groundY: groundY, effectiveGround: effectiveGround)
        drawStickman(context: &context, cx: cx, ground: effectiveGround, size: size, opacity: 1.0)
        drawParticles(context: &context, groundY: groundY)
        // Suelo
        var floor = Path(); floor.move(to: CGPoint(x: 0, y: groundY)); floor.addLine(to: CGPoint(x: size.width, y: groundY))
        context.stroke(floor, with: .color(.gray.opacity(0.5)), lineWidth: 2)
    }

    private func drawPlatforms(context: inout GraphicsContext, size: CGSize, groundY: CGFloat) {
        context.opacity = 0.35
        for (h, w, fromLeft) in [(CGFloat(46), CGFloat(120), true), (CGFloat(104), CGFloat(140), false)] {
            var p = Path()
            let y = groundY - h
            if fromLeft { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
            else { p.move(to: CGPoint(x: size.width - w, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }
            context.stroke(p, with: .color(.gray), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
        }
        context.opacity = 1
    }

    private func drawFrozenPatch(context: inout GraphicsContext, x: CGFloat, groundY: CGFloat) {
        var ctx = context; ctx.opacity = 0.55
        ctx.fill(Path(ellipseIn: CGRect(x: x - 46, y: groundY - 7, width: 92, height: 12)), with: .color(Color(red: 0.6, green: 0.88, blue: 1.0)))
    }

    // MARK: Objetos dibujados

    private func drawObject(context: inout GraphicsContext, object: DrawnObject, groundY: CGFloat, stickmanX: CGFloat, effectiveGround: CGFloat) {
        if object.state == .gone { return }
        var ctx = context
        let ox = object.x
        var baseColor: Color = .black
        if object.state == .burnt { baseColor = .gray }
        if object.state == .frozen { baseColor = Color(red: 0.45, green: 0.75, blue: 0.95) }
        let heldSword = object.kind == .sword && (controller.action == .sword)
        if heldSword { return } // la lleva en la mano

        switch object.kind {
        case .sword:
            var p = Path(); p.move(to: CGPoint(x: ox - 12, y: groundY)); p.addLine(to: CGPoint(x: ox + 14, y: groundY - 26))
            ctx.stroke(p, with: .color(.gray), lineWidth: 3.5)
        case .ball:
            let bounce = controller.action == .playingBall ? abs(sin(object.bouncePhase)) * 20 : 0
            ctx.fill(Path(ellipseIn: CGRect(x: ox - 13, y: groundY - 26 - bounce, width: 26, height: 26)), with: .color(.red))
        case .chair:
            var p = Path()
            p.move(to: CGPoint(x: ox - 16, y: groundY - 22)); p.addLine(to: CGPoint(x: ox + 16, y: groundY - 22))
            p.move(to: CGPoint(x: ox - 16, y: groundY - 22)); p.addLine(to: CGPoint(x: ox - 16, y: groundY))
            p.move(to: CGPoint(x: ox + 16, y: groundY - 22)); p.addLine(to: CGPoint(x: ox + 16, y: groundY))
            p.move(to: CGPoint(x: ox - 16, y: groundY - 22)); p.addLine(to: CGPoint(x: ox - 16, y: groundY - 46))
            p.move(to: CGPoint(x: ox - 16, y: groundY - 46)); p.addLine(to: CGPoint(x: ox + 4, y: groundY - 46))
            ctx.stroke(p, with: .color(baseColor), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        case .table:
            var p = Path()
            p.move(to: CGPoint(x: ox - 26, y: groundY - 30)); p.addLine(to: CGPoint(x: ox + 26, y: groundY - 30))
            p.move(to: CGPoint(x: ox - 20, y: groundY - 30)); p.addLine(to: CGPoint(x: ox - 20, y: groundY))
            p.move(to: CGPoint(x: ox + 20, y: groundY - 30)); p.addLine(to: CGPoint(x: ox + 20, y: groundY))
            ctx.stroke(p, with: .color(baseColor), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        case .doorHouse:
            var p = Path()
            p.addRect(CGRect(x: ox - 20, y: groundY - 52, width: 40, height: 52))
            p.move(to: CGPoint(x: ox - 26, y: groundY - 52)); p.addLine(to: CGPoint(x: ox, y: groundY - 72)); p.addLine(to: CGPoint(x: ox + 26, y: groundY - 52))
            ctx.stroke(p, with: .color(baseColor), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: ox + 8, y: groundY - 28, width: 5, height: 5)), with: .color(baseColor))
        case .block:
            if object.state == .lifted {
                ctx.stroke(Path(CGRect(x: stickmanX - 21, y: effectiveGround - 176, width: 42, height: 42)), with: .color(.purple), lineWidth: 4)
            } else {
                ctx.stroke(Path(CGRect(x: ox - 19, y: groundY - 38, width: 38, height: 38)), with: .color(.purple), lineWidth: 4)
            }
        case .target:
            for (r, col) in [(20.0, Color.red), (13.0, Color.white), (6.0, Color.red)] {
                ctx.stroke(Path(ellipseIn: CGRect(x: ox - CGFloat(r), y: groundY - 58 - CGFloat(r), width: CGFloat(r) * 2, height: CGFloat(r) * 2)), with: .color(col == .white && object.state == .frozen ? baseColor : col), lineWidth: 3)
            }
            var stand = Path(); stand.move(to: CGPoint(x: ox, y: groundY - 38)); stand.addLine(to: CGPoint(x: ox, y: groundY))
            ctx.stroke(stand, with: .color(baseColor), lineWidth: 3)
        case .friend:
            drawMiniFriend(context: &ctx, ox: ox, groundY: groundY)
        }

        // Estados especiales
        if object.state == .burning {
            let flicker = CGFloat(sin(controller.phase * 18)) * 4
            var flame = Path()
            flame.move(to: CGPoint(x: ox - 14, y: groundY - 20)); flame.addLine(to: CGPoint(x: ox, y: groundY - 52 - flicker)); flame.addLine(to: CGPoint(x: ox + 14, y: groundY - 20)); flame.closeSubpath()
            var fctx = context; fctx.opacity = 0.8; fctx.fill(flame, with: .color(.orange))
        }
        if object.state == .frozen {
            var ictx = context; ictx.opacity = 0.45
            ictx.fill(Path(CGRect(x: ox - 24, y: groundY - 66, width: 48, height: 62)), with: .color(Color(red: 0.65, green: 0.9, blue: 1.0)))
        }
        if object.state == .cutInHalf {
            var cut = Path(); cut.move(to: CGPoint(x: ox - 24, y: groundY - 62)); cut.addLine(to: CGPoint(x: ox + 24, y: groundY - 8))
            context.stroke(cut, with: .color(.white), lineWidth: 6)
            context.stroke(cut, with: .color(.red), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
    }

    private func drawMiniFriend(context: inout GraphicsContext, ox: CGFloat, groundY: CGFloat) {
        let color: Color = Color(red: 0.15, green: 0.45, blue: 0.9)
        let hip = CGPoint(x: ox, y: groundY - 44)
        let neck = CGPoint(x: ox, y: groundY - 76)
        let head = CGPoint(x: ox, y: groundY - 92)
        var p = Path()
        p.move(to: hip); p.addLine(to: neck)
        p.move(to: hip); p.addLine(to: CGPoint(x: ox - 12, y: groundY)); p.move(to: hip); p.addLine(to: CGPoint(x: ox + 12, y: groundY))
        let wave = CGFloat(sin(controller.phase * 7)) * 7
        p.move(to: neck); p.addLine(to: CGPoint(x: ox - 16, y: groundY - 62))
        p.move(to: neck); p.addLine(to: CGPoint(x: ox + 18, y: groundY - 96 + wave))
        context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        context.stroke(Path(ellipseIn: CGRect(x: head.x - 13, y: head.y - 13, width: 26, height: 26)), with: .color(color), lineWidth: 4)
    }

    // MARK: Efectos de poder (fuego / laser / hielo / onda de choque)

    private func drawPowerEffects(context: inout GraphicsContext, size: CGSize, groundY: CGFloat, effectiveGround: CGFloat) {
        guard controller.action == .usingPower || controller.action == .flying, let power = controller.activePower else { return }
        let c = controller
        let head = CGPoint(x: c.x + c.facing * 4, y: effectiveGround - 128)
        let hand = CGPoint(x: c.x + c.facing * 40, y: effectiveGround - 88)
        switch power {
        case .eyeLaser:
            if let target = c.objects.first(where: { $0.state == .intact }) {
                var glow = context; glow.opacity = 0.35
                var beam = Path(); beam.move(to: head); beam.addLine(to: CGPoint(x: target.x, y: groundY - 46))
                glow.stroke(beam, with: .color(.red), lineWidth: 8)
                context.stroke(beam, with: .color(.red), lineWidth: 3)
            }
        case .fireBreath:
            let len = 62 + CGFloat(sin(c.phase * 22)) * 10
            var flame = Path()
            flame.move(to: hand); flame.addLine(to: CGPoint(x: hand.x + c.facing * len, y: hand.y - 12)); flame.addLine(to: CGPoint(x: hand.x + c.facing * len * 0.8, y: hand.y + 14)); flame.closeSubpath()
            var f = context; f.opacity = 0.75; f.fill(flame, with: .color(.orange))
        case .ice:
            var beam = Path(); beam.move(to: hand); beam.addLine(to: CGPoint(x: hand.x + c.facing * 78, y: hand.y + 26))
            var i = context; i.opacity = 0.7; i.stroke(beam, with: .color(Color(red: 0.55, green: 0.85, blue: 1.0)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        case .superPunch:
            let radius = CGFloat((c.phase * 95).truncatingRemainder(dividingBy: 85)) + 12
            var s = context; s.opacity = max(0, 0.8 - Double(radius) / 110)
            s.stroke(Path(ellipseIn: CGRect(x: hand.x - radius, y: hand.y - radius, width: radius * 2, height: radius * 2)), with: .color(.orange), lineWidth: 4)
        default: break
        }
    }

    private func drawParticles(context: inout GraphicsContext, groundY: CGFloat) {
        for particle in controller.particles {
            var ctx = context; ctx.opacity = particle.opacity
            let center = CGPoint(x: particle.position.x, y: groundY - particle.position.y)
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - particle.size / 2, y: center.y - particle.size / 2, width: particle.size, height: particle.size)), with: .color(particle.color))
        }
    }

    // MARK: El stickman articulado

    private func drawStickman(context: inout GraphicsContext, cx: CGFloat, ground: CGFloat, size: CGSize, opacity: Double) {
        let c = controller
        let p = c.phase
        let f = c.facing
        var ctx = context; ctx.opacity = opacity

        let pose = makePose(cx: cx, ground: ground, phase: p, facing: f)

        var body = Path()
        // Torso
        body.move(to: pose.hip); body.addLine(to: pose.neck)
        // Piernas: cadera -> rodilla -> pie
        body.move(to: pose.hip); body.addLine(to: pose.kneeL); body.addLine(to: pose.footL)
        body.move(to: pose.hip); body.addLine(to: pose.kneeR); body.addLine(to: pose.footR)
        // Brazos: hombro(=cuello) -> codo -> mano
        body.move(to: pose.neck); body.addLine(to: pose.elbowL); body.addLine(to: pose.handL)
        body.move(to: pose.neck); body.addLine(to: pose.elbowR); body.addLine(to: pose.handR)
        ctx.stroke(body, with: .color(c.action == .drawn ? .gray : orange), style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))

        // Cabeza HUECA (circulo sin relleno)
        ctx.stroke(Path(ellipseIn: CGRect(x: pose.head.x - 20, y: pose.head.y - 20, width: 40, height: 40)), with: .color(c.action == .drawn ? .gray : orange), lineWidth: 5.5)

        // Espada en la mano cuando hace esgrima
        if c.action == .sword {
            let hand = pose.handR
            let tip = CGPoint(x: hand.x + f * 44 * CGFloat(c.swordProgress), y: hand.y - 8 * CGFloat(c.swordProgress))
            var sword = Path(); sword.move(to: hand); sword.addLine(to: tip)
            ctx.stroke(sword, with: .color(.gray), lineWidth: 4)
            var guardP = Path(); guardP.move(to: CGPoint(x: hand.x, y: hand.y - 7)); guardP.addLine(to: CGPoint(x: hand.x, y: hand.y + 7))
            ctx.stroke(guardP, with: .color(.brown), lineWidth: 4)
        }
        _ = size
    }

    // MARK: Pose procedural segun accion / micro-actividad / poder

    private struct Pose { var hip, neck, head, elbowL, handL, elbowR, handR, kneeL, footL, kneeR, footR: CGPoint }

    private func makePose(cx: CGFloat, ground: CGFloat, phase p: Double, facing f: CGFloat) -> Pose {
        let c = controller
        let action = c.action
        let breathe = CGFloat(sin(p * 2.0)) * 2
        let scratch = c.microActivity == "se rasca la cabeza"
        let headShake: CGFloat = action == .denying ? CGFloat(sin(p * 15)) * 5 : 0

        // Dormido: tumbado en el suelo
        if action == .sleeping {
            let hip = CGPoint(x: cx, y: ground - 12)
            let neck = CGPoint(x: cx - f * 34, y: ground - 14)
            let head = CGPoint(x: neck.x - f * 20, y: ground - 12)
            return Pose(hip: hip, neck: neck, head: head,
                        elbowL: CGPoint(x: neck.x, y: neck.y + 10), handL: CGPoint(x: neck.x + 14, y: neck.y + 12),
                        elbowR: CGPoint(x: neck.x - 8, y: neck.y + 10), handR: CGPoint(x: neck.x - 18, y: neck.y + 12),
                        kneeL: CGPoint(x: hip.x + f * 22, y: ground - 8), footL: CGPoint(x: hip.x + f * 44, y: ground - 4),
                        kneeR: CGPoint(x: hip.x + f * 20, y: ground - 16), footR: CGPoint(x: hip.x + f * 42, y: ground - 12))
        }

        // Sentado / descanso: cadera baja, piernas dobladas
        if action == .sitting || action == .resting {
            let hip = CGPoint(x: cx, y: ground - 26)
            let neck = CGPoint(x: cx, y: hip.y - 34 + breathe)
            let head = CGPoint(x: neck.x + headShake, y: neck.y - 22)
            return Pose(hip: hip, neck: neck, head: head,
                        elbowL: CGPoint(x: neck.x - 14, y: neck.y + 16), handL: CGPoint(x: neck.x - 10, y: ground - 8),
                        elbowR: CGPoint(x: neck.x + 14, y: neck.y + 16), handR: CGPoint(x: neck.x + 10, y: ground - 8),
                        kneeL: CGPoint(x: hip.x - 16, y: ground - 20), footL: CGPoint(x: hip.x - 16, y: ground),
                        kneeR: CGPoint(x: hip.x + 16, y: ground - 20), footR: CGPoint(x: hip.x + 16, y: ground))
        }

        var hip = CGPoint(x: cx, y: ground - 56)
        if action == .dancing { hip.y -= abs(CGFloat(sin(p * 6))) * 9 }
        if action == .flying { hip.y -= 6 }
        let lean: CGFloat = (action == .running || action == .flying) ? f * 9 : (action == .proud || action == .powerPose ? -f * 4 : 0)
        let neck = CGPoint(x: hip.x + lean, y: hip.y - 42 + breathe)
        let head = CGPoint(x: neck.x + lean * 0.5 + headShake, y: neck.y - 23)

        // Piernas por defecto (de pie)
        var kneeL = CGPoint(x: hip.x - 11, y: hip.y + 27); var footL = CGPoint(x: hip.x - 13, y: ground)
        var kneeR = CGPoint(x: hip.x + 11, y: hip.y + 27); var footR = CGPoint(x: hip.x + 13, y: ground)
        // Brazos por defecto (caidos, con balanceo)
        var elbowL = CGPoint(x: neck.x - 17, y: neck.y + 19); var handL = CGPoint(x: neck.x - 20, y: neck.y + 40)
        var elbowR = CGPoint(x: neck.x + 17, y: neck.y + 19); var handR = CGPoint(x: neck.x + 20, y: neck.y + 40)

        switch action {
        case .walking, .climbing, .playingBall:
            let s = CGFloat(sin(p * 8)) * 15
            kneeL = CGPoint(x: hip.x + s, y: hip.y + 26); footL = CGPoint(x: hip.x + s * 1.25, y: ground - max(0, -s) * 0.35)
            kneeR = CGPoint(x: hip.x - s, y: hip.y + 26); footR = CGPoint(x: hip.x - s * 1.25, y: ground - max(0, s) * 0.35)
            handL.x += -s * 0.7; handR.x += s * 0.7
            if action == .climbing { handL = CGPoint(x: neck.x - 15, y: neck.y - 22); handR = CGPoint(x: neck.x + 15 + CGFloat(sin(p * 8)) * 6, y: neck.y - 24) }
        case .running:
            let s = CGFloat(sin(p * 13)) * 23
            kneeL = CGPoint(x: hip.x + s, y: hip.y + 24); footL = CGPoint(x: hip.x + s * 0.8, y: ground - 9)
            kneeR = CGPoint(x: hip.x - s, y: hip.y + 24); footR = CGPoint(x: hip.x - s * 0.8, y: ground - 9)
            handL.x += -s * 0.8; handR.x += s * 0.8; handL.y -= 12; handR.y -= 12
        case .jumping, .thrown:
            kneeL = CGPoint(x: hip.x - 15, y: hip.y + 20); footL = CGPoint(x: hip.x - 22, y: hip.y + 38)
            kneeR = CGPoint(x: hip.x + 15, y: hip.y + 20); footR = CGPoint(x: hip.x + 22, y: hip.y + 38)
            handL = CGPoint(x: neck.x - 26, y: neck.y - 8); handR = CGPoint(x: neck.x + 26, y: neck.y - 8)
        case .flying:
            kneeL = CGPoint(x: hip.x - f * 24, y: hip.y + 13); footL = CGPoint(x: hip.x - f * 46, y: hip.y + 19)
            kneeR = CGPoint(x: hip.x - f * 20, y: hip.y + 22); footR = CGPoint(x: hip.x - f * 42, y: hip.y + 30)
            handR = CGPoint(x: neck.x + f * 42, y: neck.y - 4); elbowR = CGPoint(x: neck.x + f * 21, y: neck.y - 2) // brazo Superman
            handL = CGPoint(x: neck.x - f * 18, y: neck.y + 24)
        case .dancing:
            let w = CGFloat(sin(p * 6)) * 13
            handL = CGPoint(x: neck.x - 22, y: neck.y - 18 + w); elbowL = CGPoint(x: neck.x - 18, y: neck.y + 2)
            handR = CGPoint(x: neck.x + 22, y: neck.y - 18 - w); elbowR = CGPoint(x: neck.x + 18, y: neck.y + 2)
            footL.x -= 5 + w * 0.4; footR.x += 5 - w * 0.4
        case .waving, .withFriend:
            let w = CGFloat(sin(p * 10)) * 8
            handR = CGPoint(x: neck.x + 24 + w, y: neck.y - 26); elbowR = CGPoint(x: neck.x + 16, y: neck.y - 6)
        case .sword:
            handR = CGPoint(x: neck.x + f * 36, y: neck.y + 10); elbowR = CGPoint(x: neck.x + f * 18, y: neck.y + 9)
            footL.x -= 7; footR.x += 11
        case .fighting:
            let punch = (sin(p * 11) > 0 ? CGFloat(21) : CGFloat(7)) * f
            handR = CGPoint(x: neck.x + punch + f * 13, y: neck.y + 9); elbowR = CGPoint(x: neck.x + f * 12, y: neck.y + 9)
            handL = CGPoint(x: neck.x - f * 12, y: neck.y + 17)
        case .scared:
            let t = CGFloat(sin(p * 38)) * 2.2
            handL = CGPoint(x: neck.x - 25 + t, y: neck.y - 22); handR = CGPoint(x: neck.x + 25 + t, y: neck.y - 22)
        case .yawning:
            handR = CGPoint(x: head.x + 11, y: head.y + 5); elbowR = CGPoint(x: neck.x + 15, y: neck.y + 13)
        case .drawingObject, .usingTool:
            let scribble = CGFloat(sin(p * 16)) * 4
            handR = CGPoint(x: neck.x + f * 27 + scribble, y: neck.y + 36); elbowR = CGPoint(x: neck.x + f * 15, y: neck.y + 17)
        case .denying:
            handL = CGPoint(x: neck.x + 9, y: neck.y + 22); handR = CGPoint(x: neck.x - 9, y: neck.y + 22) // brazos cruzados
        case .proud:
            handL = CGPoint(x: hip.x - 5, y: hip.y + 3); elbowL = CGPoint(x: neck.x - 21, y: neck.y + 19)
            handR = CGPoint(x: hip.x + 5, y: hip.y + 3); elbowR = CGPoint(x: neck.x + 21, y: neck.y + 19)
        case .powerPose:
            handR = CGPoint(x: neck.x + 19, y: neck.y - 32); elbowR = CGPoint(x: neck.x + 15, y: neck.y - 9)
            handL = CGPoint(x: hip.x - 4, y: hip.y + 3); elbowL = CGPoint(x: neck.x - 20, y: neck.y + 18)
        case .usingPower:
            if c.activePower == .superStrength {
                handL = CGPoint(x: neck.x - 18, y: neck.y - 30); handR = CGPoint(x: neck.x + 18, y: neck.y - 30)
                elbowL = CGPoint(x: neck.x - 17, y: neck.y - 7); elbowR = CGPoint(x: neck.x + 17, y: neck.y - 7)
            } else if c.activePower == .superPunch {
                handR = CGPoint(x: neck.x + f * 47, y: neck.y + 8); elbowR = CGPoint(x: neck.x + f * 23, y: neck.y + 8)
            } else {
                handL = CGPoint(x: neck.x + f * 29, y: neck.y + 13); handR = CGPoint(x: neck.x + f * 33, y: neck.y + 19)
                elbowL = CGPoint(x: neck.x + f * 15, y: neck.y + 11); elbowR = CGPoint(x: neck.x + f * 16, y: neck.y + 14)
            }
        default: break
        }
        if scratch, action == .idle {
            handR = CGPoint(x: head.x + 13, y: head.y - 10); elbowR = CGPoint(x: neck.x + 17, y: neck.y + 3)
        }
        return Pose(hip: hip, neck: neck, head: head, elbowL: elbowL, handL: handL, elbowR: elbowR, handR: handR, kneeL: kneeL, footL: footL, kneeR: kneeR, footR: footR)
    }
}
