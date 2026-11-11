import SwiftUI

// MARK: - Dibujo procedural del stickman (Canvas, sin assets) — v2
// Cabeza hueca naranja como The Second Coming. La pose ya NO se calcula
// con senos por accion: se MUESTREA de los clips de keyframes de
// StickmanAnimation.swift (con blend caminar<->correr segun velocidad).

struct StickmanCanvasView: View {
    @ObservedObject var controller: StickmanController

    private let orange = Color(red: 1.0, green: 0.45, blue: 0.0)

    var body: some View {
        Canvas { context, size in
            drawScene(context: &context, size: size)
        }
        .allowsHitTesting(false)   // los toques los gestiona SOLO el gesto del lienzo en ContentView
    }

    // MARK: Escena completa

    private func drawScene(context: inout GraphicsContext, size: CGSize) {
        let groundY = size.height - 10
        let c = controller
        let effectiveGround = groundY - c.platformHeight - c.heightAboveGround
        let cx = c.x

        drawPlatforms(context: &context, size: size, groundY: groundY)
        if let frozenX = c.frozenPatchX { drawFrozenPatch(context: &context, x: frozenX, groundY: groundY) }
        drawUserStrokes(context: &context, groundY: groundY)
        for object in c.objects where object.id != c.hidingObjectID {
            drawObject(context: &context, object: object, groundY: groundY, stickmanX: cx, effectiveGround: effectiveGround)
        }

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
        // El objeto tras el que se esconde se dibuja DELANTE de el
        if let hid = c.hidingObjectID, let object = c.objects.first(where: { $0.id == hid }) {
            drawObject(context: &context, object: object, groundY: groundY, stickmanX: cx, effectiveGround: effectiveGround)
        }
        // Caja de seleccion de AvA1 cuando esta agarrado / escapando
        if c.action == .grabbed || c.action == .escaping {
            var box = Path()
            box.addRect(CGRect(x: cx - 44, y: effectiveGround - 148, width: 88, height: 148))
            context.stroke(box, with: .color(.blue.opacity(0.75)), style: StrokeStyle(lineWidth: 1.6, dash: [6, 4]))
            for corner in [CGPoint(x: cx - 44, y: effectiveGround - 148), CGPoint(x: cx + 44, y: effectiveGround - 148),
                           CGPoint(x: cx - 44, y: effectiveGround), CGPoint(x: cx + 44, y: effectiveGround)] {
                context.fill(Path(ellipseIn: CGRect(x: corner.x - 3.5, y: corner.y - 3.5, width: 7, height: 7)), with: .color(.blue))
            }
        }
        drawParticles(context: &context, groundY: groundY)
        // Suelo
        var floor = Path(); floor.move(to: CGPoint(x: 0, y: groundY)); floor.addLine(to: CGPoint(x: size.width, y: groundY))
        context.stroke(floor, with: .color(.gray.opacity(0.5)), lineWidth: 2)
    }

    // MARK: Trazos del usuario (lapiz): persistentes y fisicos

    private func drawUserStrokes(context: inout GraphicsContext, groundY: CGFloat) {
        for stroke in controller.userStrokes { strokePath(context: &context, points: stroke.points, groundY: groundY, opacity: 1) }
        if let current = controller.currentStroke { strokePath(context: &context, points: current.points, groundY: groundY, opacity: 0.65) }
    }
    private func strokePath(context: inout GraphicsContext, points: [CGPoint], groundY: CGFloat, opacity: Double) {
        guard let first = points.first else { return }
        var ctx = context; ctx.opacity = opacity
        if points.count == 1 {
            ctx.fill(Path(ellipseIn: CGRect(x: first.x - 3, y: groundY - first.y - 3, width: 6, height: 6)), with: .color(.black))
            return
        }
        var p = Path()
        p.move(to: CGPoint(x: first.x, y: groundY - first.y))
        for pt in points.dropFirst() { p.addLine(to: CGPoint(x: pt.x, y: groundY - pt.y)) }
        ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
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

    // MARK: Objetos dibujados (por el stickman o su mundo)

    private func drawObject(context: inout GraphicsContext, object: DrawnObject, groundY: CGFloat, stickmanX: CGFloat, effectiveGround: CGFloat) {
        if object.state == .gone { return }
        var ctx = context
        let ox = object.x
        var baseColor: Color = .black
        if object.state == .burnt { baseColor = .gray }
        if object.state == .frozen { baseColor = Color(red: 0.45, green: 0.75, blue: 0.95) }

        switch object.kind {
        case .bird: drawBird(context: &ctx, object: object, groundY: groundY); return
        case .dog: drawDog(context: &ctx, object: object, groundY: groundY, stickmanX: stickmanX); return
        case .hammer:
            if controller.action == .hammering { return } // lo lleva en la mano
            var p = Path()
            p.move(to: CGPoint(x: ox - 8, y: groundY)); p.addLine(to: CGPoint(x: ox + 4, y: groundY - 18))
            ctx.stroke(p, with: .color(.brown), lineWidth: 3.5)
            ctx.stroke(Path(CGRect(x: ox - 2, y: groundY - 26, width: 16, height: 9)), with: .color(.gray), lineWidth: 3.5)
        case .sword:
            if controller.action == .sword { return } // la lleva en la mano
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
            } else if controller.shieldKind == .block && controller.action == .blocking {
                return // lo lleva delante como escudo (lo dibuja drawStickman)
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

    // Criatura AvA4: pajarito que aletea y vuela en circulos
    private func drawBird(context: inout GraphicsContext, object: DrawnObject, groundY: CGFloat) {
        let anim = CreatureAnimation.bird(phase: controller.phase, t: object.bouncePhase)
        let bx = object.x + anim.offset.x
        let by = groundY - anim.offset.y
        var p = Path()
        p.addEllipse(in: CGRect(x: bx - 11, y: by - 6, width: 22, height: 12))            // cuerpo
        p.move(to: CGPoint(x: bx - 2, y: by - 4))                                          // ala
        p.addLine(to: CGPoint(x: bx - 12, y: by - 4 - anim.flap * 11))
        p.move(to: CGPoint(x: bx + 11, y: by - 2)); p.addLine(to: CGPoint(x: bx + 17, y: by - 4)) // pico
        context.stroke(p, with: .color(Color(red: 0.2, green: 0.55, blue: 0.9)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: bx + 3, y: by - 4, width: 3.5, height: 3.5)), with: .color(.black))
    }

    // Criatura AvA4: perrito que trota y sigue al stickman
    private func drawDog(context: inout GraphicsContext, object: DrawnObject, groundY: CGFloat, stickmanX: CGFloat) {
        let anim = CreatureAnimation.dog(phase: controller.phase, t: object.bouncePhase, stickmanX: stickmanX)
        let dx = anim.x
        let top = groundY - 20 - anim.bounce
        var p = Path()
        p.move(to: CGPoint(x: dx - 16, y: top)); p.addLine(to: CGPoint(x: dx + 10, y: top))       // lomo
        p.move(to: CGPoint(x: dx + 10, y: top)); p.addLine(to: CGPoint(x: dx + 17, y: top - 8))   // cuello/cabeza
        p.move(to: CGPoint(x: dx - 16, y: top)); p.addLine(to: CGPoint(x: dx - 23, y: top - 7))   // cola
        let s = anim.legSwing * 6
        p.move(to: CGPoint(x: dx - 12, y: top)); p.addLine(to: CGPoint(x: dx - 12 + s, y: groundY - anim.bounce))
        p.move(to: CGPoint(x: dx - 6, y: top)); p.addLine(to: CGPoint(x: dx - 6 - s, y: groundY - anim.bounce))
        p.move(to: CGPoint(x: dx + 4, y: top)); p.addLine(to: CGPoint(x: dx + 4 - s, y: groundY - anim.bounce))
        p.move(to: CGPoint(x: dx + 9, y: top)); p.addLine(to: CGPoint(x: dx + 9 + s, y: groundY - anim.bounce))
        context.stroke(p, with: .color(Color(red: 0.55, green: 0.38, blue: 0.2)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        context.stroke(Path(ellipseIn: CGRect(x: dx + 11, y: top - 15, width: 13, height: 13)), with: .color(Color(red: 0.55, green: 0.38, blue: 0.2)), lineWidth: 3.2)
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
            if let target = c.objects.first(where: { $0.state == .intact && !$0.kind.isCreature }) {
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

    // MARK: El stickman: pose muestreada de los clips

    private struct JointPoints { var hip, neck, head, elbowL, handL, elbowR, handR, kneeL, footL, kneeR, footR: CGPoint }

    private func currentPose() -> SkeletonPose {
        let c = controller
        if c.isSkidding { return AnimationLibrary.skid.sample(at: c.skidElapsed) }
        if c.isTurning && [.walking, .running, .fleeing].contains(c.action) {
            return AnimationLibrary.turn.sample(at: c.turnElapsed)
        }
        if c.isWallSliding { return AnimationLibrary.wallSlide.sample(at: min(c.animTime, 0.6)) }
        if c.isJumpWindingUp { return AnimationLibrary.jumpCrouch.sample(at: c.animTime) }
        if (c.action == .jumping || c.action == .thrown) && c.isAirborne {
            if c.action == .thrown { return AnimationLibrary.thrownSpin.sample(at: c.animTime) }
            if c.velocityY > 80 { return AnimationLibrary.jumpStretch.sample(at: min(c.animTime, 0.3)) }
            return AnimationLibrary.fallPose.sample(at: c.animTime)
        }
        switch c.action {
        case .walking, .running, .fleeing, .playingBall:
            // Blend caminar<->correr por velocidad REAL, fase de zancada ligada a la velocidad
            let walkPose = AnimationLibrary.walk.sample(at: c.gaitPhase01 * AnimationLibrary.walk.duration)
            let runPose = AnimationLibrary.run.sample(at: c.gaitPhase01 * AnimationLibrary.run.duration)
            return walkPose.lerped(to: runPose, t: c.speedNorm)
        case .climbing:
            return AnimationLibrary.climb.sample(at: c.gaitPhase01 * AnimationLibrary.climb.duration * 1.4)
        case .usingPower:
            if let power = c.activePower { return AnimationLibrary.clip(forPower: power).sample(at: c.animTime) }
            return AnimationLibrary.powerPose.sample(at: c.animTime)
        case .idle:
            if c.microActivity == "se rasca la cabeza" { return AnimationLibrary.scratchHead.sample(at: c.animTime) }
            if c.microActivity == "mira a un lado" { return AnimationLibrary.lookAround.sample(at: c.animTime) }
            return AnimationLibrary.idle.sample(at: c.animTime)
        default:
            return AnimationLibrary.clip(for: c.action).sample(at: c.animTime)
        }
    }

    private func jointPoints(cx: CGFloat, ground: CGFloat) -> JointPoints {
        let c = controller
        let pose = currentPose()
        let f = c.facing
        func fromHip(_ p: CGPoint, hip: CGPoint) -> CGPoint { CGPoint(x: hip.x + p.x * f, y: hip.y + p.y) }
        func fromNeck(_ p: CGPoint, neck: CGPoint) -> CGPoint { CGPoint(x: neck.x + p.x * f, y: neck.y + p.y) }
        let hip = CGPoint(x: cx + pose.hipDX * f, y: ground - pose.hipHeight)
        let neck = fromHip(pose.neckOff, hip: hip)
        let head = fromNeck(pose.headOff, neck: neck)
        return JointPoints(
            hip: hip, neck: neck, head: head,
            elbowL: fromNeck(pose.elbowL, neck: neck), handL: fromNeck(pose.handL, neck: neck),
            elbowR: fromNeck(pose.elbowR, neck: neck), handR: fromNeck(pose.handR, neck: neck),
            kneeL: fromHip(pose.kneeL, hip: hip), footL: fromHip(pose.footL, hip: hip),
            kneeR: fromHip(pose.kneeR, hip: hip), footR: fromHip(pose.footR, hip: hip))
    }

    private func drawStickman(context: inout GraphicsContext, cx: CGFloat, ground: CGFloat, size: CGSize, opacity: Double) {
        let c = controller
        let f = c.facing
        var ctx = context; ctx.opacity = opacity
        let j = jointPoints(cx: cx, ground: ground)
        let pose = currentPose()
        let color: Color = c.action == .drawn ? .gray : orange

        var body = Path()
        body.move(to: j.hip); body.addLine(to: j.neck)
        body.move(to: j.hip); body.addLine(to: j.kneeL); body.addLine(to: j.footL)
        body.move(to: j.hip); body.addLine(to: j.kneeR); body.addLine(to: j.footR)
        body.move(to: j.neck); body.addLine(to: j.elbowL); body.addLine(to: j.handL)
        body.move(to: j.neck); body.addLine(to: j.elbowR); body.addLine(to: j.handR)
        ctx.stroke(body, with: .color(color), style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))

        // Cabeza HUECA (con squash vertical del clip)
        let headH = 40 * pose.squash
        let headW = 40 * (1 + (1 - pose.squash) * 0.55)
        ctx.stroke(Path(ellipseIn: CGRect(x: j.head.x - headW / 2, y: j.head.y - headH / 2, width: headW, height: headH)),
                   with: .color(color), lineWidth: 5.5)

        // Herramientas/objetos EN LA MANO segun la accion
        let hand = j.handR
        let dir = CGPoint(x: hand.x - j.elbowR.x, y: hand.y - j.elbowR.y)
        let len = max(1, hypot(dir.x, dir.y))
        let unit = CGPoint(x: dir.x / len, y: dir.y / len)
        if c.action == .sword || (c.shieldKind == .sword && c.action == .blocking) {
            let tip = CGPoint(x: hand.x + unit.x * 48, y: hand.y + unit.y * 48)
            var sword = Path(); sword.move(to: hand); sword.addLine(to: tip)
            ctx.stroke(sword, with: .color(.gray), lineWidth: 4)
            var guardP = Path()
            guardP.move(to: CGPoint(x: hand.x - unit.y * 7, y: hand.y + unit.x * 7))
            guardP.addLine(to: CGPoint(x: hand.x + unit.y * 7, y: hand.y - unit.x * 7))
            ctx.stroke(guardP, with: .color(.brown), lineWidth: 4)
        }
        if c.action == .drawingObject {
            // Lapiz grande cogido con las dos manos (como en los videos)
            let tip = CGPoint(x: hand.x + f * 16, y: hand.y + 30)
            var pencil = Path(); pencil.move(to: CGPoint(x: hand.x - f * 10, y: hand.y - 16)); pencil.addLine(to: tip)
            ctx.stroke(pencil, with: .color(Color(red: 0.95, green: 0.75, blue: 0.15)), lineWidth: 7)
            var tipP = Path(); tipP.move(to: CGPoint(x: hand.x + f * 11, y: hand.y + 21)); tipP.addLine(to: tip)
            ctx.stroke(tipP, with: .color(.black), lineWidth: 3)
        }
        if c.action == .usingTool {
            // Goma rosa en la mano
            ctx.stroke(Path(CGRect(x: hand.x - 9, y: hand.y - 6, width: 18, height: 12)), with: .color(.pink), lineWidth: 4)
        }
        if c.action == .hammering {
            let grip = hand
            let headC = CGPoint(x: grip.x + unit.x * 26, y: grip.y + unit.y * 26)
            var handle = Path(); handle.move(to: CGPoint(x: grip.x - unit.x * 8, y: grip.y - unit.y * 8)); handle.addLine(to: headC)
            ctx.stroke(handle, with: .color(.brown), lineWidth: 4.5)
            var headP = Path()
            headP.move(to: CGPoint(x: headC.x - unit.y * 11, y: headC.y + unit.x * 11))
            headP.addLine(to: CGPoint(x: headC.x + unit.y * 11, y: headC.y - unit.x * 11))
            ctx.stroke(headP, with: .color(.gray), lineWidth: 8)
        }
        if c.shieldKind == .block && c.action == .blocking {
            // Bloque de la interfaz usado como ESCUDO delante del cuerpo
            let shieldCenter = CGPoint(x: cx + f * 34, y: ground - 72)
            ctx.stroke(Path(CGRect(x: shieldCenter.x - 19, y: shieldCenter.y - 24, width: 38, height: 48)), with: .color(.purple), lineWidth: 4.5)
        }
        _ = size
    }
}
