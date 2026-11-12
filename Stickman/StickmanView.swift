import SwiftUI

// MARK: - Dibujo procedural del stickman (Canvas, sin assets) — v4
// La pose se MUESTREA de los clips de keyframes de StickmanAnimation.swift
// (con blend caminar<->correr segun velocidad).
//
// UN personaje, The Second Coming (naranja, cabeza de ANILLO hueco;
// proporciones y escala global en ViewTuning: figura al 0,8 y cabeza
// grande segun los modelos del usuario, ver DISENO-TCO.md y
// stickman-nodes/NODES_SPEC.md). Roaming 360: en
// el TECHO el cuerpo se dibuja INVERTIDO (ancla en el borde superior,
// balanceo swing) y en las PAREDES trepa/colgado junto al borde.

struct StickmanCanvasView: View {
    @ObservedObject var controller: StickmanController

    private var bodyColor: Color {
        let rgb = controller.kind.colorRGB
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    // Constantes de ajuste de la CAPA DE DIBUJO (bucle de parecido,
    // ronda 2 + fusion 2026-11-11): se miden contra los criterios del
    // plano aprobado y se afinan sin tocar los clips. Ver LOOP.md.
    enum ViewTuning {
        /// Tirón del punto de control de la curva de cada miembro:
        /// 2.0 = la curva pasa exactamente por la articulación.
        static let limbPull: CGFloat = 2.0
        /// ESCALA GLOBAL DE LA FIGURA: 0,8 (el usuario, 2026-11-11:
        /// «hazlo un poco más pequeño, que en la pantalla del teléfono
        /// es complicado»). UNICA constante de escala: la aplican
        /// jointPoints (todas las articulaciones), el trazo y la
        /// cabeza; el PiP (FloatingStickman) y el widget la espejan.
        /// Las PROPORCIONES (%) no cambian con la escala.
        static let figureScale: CGFloat = 0.8
        /// Proporciones hacia los modelos del usuario (su foto «ASÍ»
        /// y el .nodes decodificado en stickman-nodes/NODES_SPEC.md:
        /// cabeza-anillo Ø 225-238 uds — más ancha que una pierna de
        /// 183,6 —, piernas 183,6 > torso 145,7): cabeza al 33-37 %
        /// del alto y piernas largas con torso corto. Factores sobre
        /// los offsets de los clips (los clips NO se tocan):
        /// - torsoFactor: cuello x1,06 (pierna/torso 1,33 -> 1,26,
        ///   el ratio del .nodes).
        /// - headOffFactor: la cabeza se aleja del cuello x1,28 para
        ///   que el anillo GRANDE asiente sobre el cuello.
        /// Las piernas son la referencia (factor 1,0) y los brazos se
        /// dejan como están (ningún mandato los nombra; tocarlos
        /// arriesga la lectura de las 124 poses).
        static let torsoFactor: CGFloat = 1.06
        static let headOffFactor: CGFloat = 1.28
        /// Diametro del anillo de la cabeza, en unidades de pose
        /// (antes de figureScale). R10 (2026-11-12): la MEDICION
        /// ESTRICTA sobre el render con Ø 52 daba 31,5 % del alto —
        /// por debajo del 33-37 % de los dos modelos del usuario (su
        /// foto «ASÍ» y el .nodes) — y el usuario volvio a decir que
        /// «no se parece». Ø 58 lo lleva a ~35 % estricto, el centro
        /// del rango. (La ronda 2 lo dejó en 39 buscando el 23-26 %
        /// del primer plano; el .nodes y la foto definitiva mandan.)
        static let headDiameter: CGFloat = 58
        /// Trazo del anillo de la cabeza, en unidades de pose: 8,5
        /// (~16 % del Ø; el .nodes da ~14 %, el plano de foto ~23 %:
        /// compromiso documentado). El trazo del CUERPO sale de
        /// kind.lineWidth x figureScale = 8 (~6,5 % del alto, dentro
        /// del 5-8 % de ambos modelos).
        static let headStroke: CGFloat = 8.5
        /// Vuelo sostenido: bamboleo vertical (arreglo 5).
        static let flightBobAmp: CGFloat = 1.3
        /// Vuelo sostenido: estela de piernas con retardo (arreglo 5).
        static let flightLegTrail: CGFloat = 2.4
    }

    // V10 · MOTOR PROCEDURAL: el solucionador vive en la vista y
    // persiste entre frames (posiciones/velocidades de muelle, angulo
    // de giro). Se resuelve UNA vez por frame en drawScene y
    // jointPoints/drawStickman consumen la pose ya resuelta.
    @State private var procBody = ProceduralBody()

    private func procContext(_ c: StickmanController) -> ProceduralContext {
        ProceduralContext(
            action: c.action, surfaceIsFloor: c.surface == .floor, facing: c.facing,
            gaitPhase01: c.gaitPhase01, speedNorm: c.speedNorm, moveSpeed: c.moveSpeed,
            animTime: c.animTime, time: c.phase, velocityY: c.velocityY,
            isAirborne: c.isAirborne, isJumpWindingUp: c.isJumpWindingUp,
            isSkidding: c.isSkidding, isTurning: c.isTurning, isWallSliding: c.isWallSliding,
            pinchLean: c.pinchLean, microActivity: c.microActivity,
            hasCinematicPose: c.cinematicPose != nil)
    }

    /// La pose del frame: la resuelta por el motor procedural; si por
    /// lo que sea aun no hay (primer frame), la muestreada del clip.
    private func resolvedPose() -> SkeletonPose {
        procBody.framePose ?? currentPose()
    }

    var body: some View {
        Canvas { context, size in
            drawScene(context: &context, size: size)
        }
        .allowsHitTesting(false)   // los toques los gestiona SOLO el gesto del lienzo en ContentView
    }

    // MARK: Posicion en pantalla segun la superficie

    /// x del personaje (en pared, pegado al borde; si no, su x).
    private func screenX(size: CGSize) -> CGFloat {
        switch controller.surface {
        case .wallLeft: return 30
        case .wallRight: return size.width - 30
        default: return controller.x
        }
    }
    /// Linea de "suelo" (pies) en coordenadas de pantalla.
    /// En el techo es el borde superior y el cuerpo cuelga INVERTIDO.
    private func feetY(size: CGSize) -> CGFloat {
        let groundY = size.height - 10
        switch controller.surface {
        case .ceiling: return 6
        case .wallLeft, .wallRight: return groundY - controller.heightAboveGround
        default: return groundY - controller.platformHeight - controller.heightAboveGround
        }
    }
    private var isFlipped: Bool { controller.surface == .ceiling }

    // MARK: Escena completa

    private func drawScene(context: inout GraphicsContext, size: CGSize) {
        let groundY = size.height - 10
        let c = controller
        // V10: resolver la pose del frame ANTES de dibujar nada, para
        // que efectos de poder, fantasmas y cuerpo compartan la misma
        // pose resuelta (generadores procedurales + muelles).
        _ = procBody.resolve(context: procContext(c), clipPose: { currentPose() })
        let cx = screenX(size: size)
        let effectiveGround = feetY(size: size)

        drawPlatforms(context: &context, size: size, groundY: groundY)
        if let frozenX = c.frozenPatchX { drawFrozenPatch(context: &context, x: frozenX, groundY: groundY) }
        drawUserStrokes(context: &context, groundY: groundY)
        for object in c.objects where object.id != c.hidingObjectID {
            drawObject(context: &context, object: object, groundY: groundY, stickmanX: cx, effectiveGround: effectiveGround)
        }

        // Aura del despertar: SOLO mientras usa un poder o vuela (en los
        // videos el aura ESTRELLA al despertar y al atacar; en reposo no
        // hay huevo amarillo permanente). Pegada al cuerpo, naranja suave.
        if c.isAwakened && (c.action == .usingPower || c.action == .flying) {
            var aura = context
            aura.opacity = 0.10 + 0.04 * sin(c.phase * 6)
            let rect = CGRect(x: cx - 50 * ViewTuning.figureScale, y: effectiveGround - 158 * ViewTuning.figureScale, width: 100 * ViewTuning.figureScale, height: 158 * ViewTuning.figureScale)
            aura.fill(Path(ellipseIn: rect), with: .color(.orange))
        }
        // Imagenes fantasma de la supervelocidad
        if c.activePower == .superSpeed {
            drawStickman(context: &context, cx: cx - c.facing * 34, ground: effectiveGround, size: size, opacity: 0.22)
            drawStickman(context: &context, cx: cx - c.facing * 68, ground: effectiveGround, size: size, opacity: 0.10)
        }
        drawPowerEffects(context: &context, size: size, groundY: groundY, effectiveGround: effectiveGround)
        // Cinematicas: el cuerpo puede ocultarse (transicion de Nacimiento)
        if !c.cinematicHidden {
            drawStickman(context: &context, cx: cx, ground: effectiveGround, size: size, opacity: 1.0)
        }
        // El objeto tras el que se esconde se dibuja DELANTE de el
        if let hid = c.hidingObjectID, let object = c.objects.first(where: { $0.id == hid }) {
            drawObject(context: &context, object: object, groundY: groundY, stickmanX: cx, effectiveGround: effectiveGround)
        }
        // RONDA 2 · arreglo 1: SIN caja de seleccion sobre el personaje.
        // Al agarrarlo/arrastrarlo ya no aparece el marco azul con asas de
        // editor: lo que se ve es su pose de agarrado/debate (clips
        // grabbed/escapeShake/escapeBurst via currentPose). La caja como
        // prop de historia sobrevive SOLO en la cinematica «Escape»,
        // dibujada por CinematicEngine (prop .selectionBox), no aqui.
        drawParticles(context: &context, groundY: groundY)
        // Guias visuales de superficies: techo y paredes tenues
        var guides = Path()
        guides.move(to: CGPoint(x: 0, y: 6)); guides.addLine(to: CGPoint(x: size.width, y: 6))
        context.stroke(guides, with: .color(.gray.opacity(0.30)), style: StrokeStyle(lineWidth: 2, dash: [3, 5]))
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
            let bounce = controller.action == .playingBall ? CGFloat(abs(sin(object.bouncePhase))) * 20 : 0
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
                // Sobre su cabeza, a la altura de SUS manos: la caja y
                // su altura escalan con la figura (0,8).
                let bs = 42 * ViewTuning.figureScale
                ctx.stroke(Path(CGRect(x: stickmanX - bs / 2, y: effectiveGround - 176 * ViewTuning.figureScale, width: bs, height: bs)), with: .color(.purple), lineWidth: 4)
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
            // La misma llama en capas del arreglo 2, en vertical
            drawLayeredFlame(context: &context, origin: CGPoint(x: ox, y: groundY - 14),
                             axis: CGPoint(x: 0, y: -1),
                             baseLength: 40, baseWidth: 26, time: controller.phase * 2.2, intensity: 0.9)
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
        let t = controller.phase
        // Vida propia (antes era una estatua clavada en el suelo):
        // respira con un bob suave, cambia el peso de un pie a otro,
        // deambula unos pasos alrededor de su sitio y saluda sin parar.
        let bob = CGFloat(sin(t * 2.2)) * 1.6
        let x = ox + CGFloat(sin(t * 0.13)) * 10
        let shift = CGFloat(sin(t * 1.1)) * 2.2
        let hip = CGPoint(x: x, y: groundY - 44 + bob)
        let neck = CGPoint(x: x, y: groundY - 76 + bob)
        let head = CGPoint(x: x + CGFloat(sin(t * 0.7)) * 2, y: groundY - 92 + bob)
        var p = Path()
        p.move(to: hip); p.addLine(to: neck)
        p.move(to: hip); p.addLine(to: CGPoint(x: x - 12 + shift, y: groundY))
        p.move(to: hip); p.addLine(to: CGPoint(x: x + 12 - shift, y: groundY))
        let wave = CGFloat(sin(t * 7)) * 7
        let sway = CGFloat(sin(t * 1.7)) * 3
        p.move(to: neck); p.addLine(to: CGPoint(x: x - 16, y: groundY - 62 + bob + sway))
        p.move(to: neck); p.addLine(to: CGPoint(x: x + 18, y: groundY - 96 + wave))
        context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        context.stroke(Path(ellipseIn: CGRect(x: head.x - 13, y: head.y - 13, width: 26, height: 26)), with: .color(color), lineWidth: 4.5)
    }

    // MARK: Efectos de poder (fuego / laser / hielo / onda de choque)

    private func drawPowerEffects(context: inout GraphicsContext, size: CGSize, groundY: CGFloat, effectiveGround: CGFloat) {
        guard controller.action == .usingPower || controller.action == .flying, let power = controller.activePower else { return }
        let c = controller
        // Ojo y mano REALES de la pose (con la escala 0,8 y la cabeza
        // grande, los antiguos -128/-88 fijos quedaban flotando muy
        // por encima de la figura): el laser sale del centro del
        // anillo y el hielo/el puñetazo de la mano derecha real.
        let jp = jointPoints(cx: c.x, ground: effectiveGround)
        let head = jp.head
        let hand = jp.handR
        switch power {
        case .eyeLaser:
            // RONDA 2 · arreglo 3: haz con nucleo brillante y halo,
            // y chispas en el punto de impacto (fuera la linea fina).
            if let target = c.objects.first(where: { $0.state == .intact && !$0.kind.isCreature }) {
                let impact = CGPoint(x: target.x, y: groundY - 46 + CGFloat(sin(c.animTime * 34)) * 1.2)
                drawLaserBeam(context: &context, from: head, to: impact, time: c.animTime)
            }
        case .fireBreath:
            // RONDA 2 · arreglo 2: llama VIVA en capas (fuera el cono
            // plano), anclada en la mano delantera real y con la
            // envolvente del clip firePose: carga (0-0.36) -> sostenido
            // -> recuperacion, con parpadeo ligado al tiempo del clip.
            let j = jointPoints(cx: c.x, ground: effectiveGround)
            let frontHand = (j.handR.x - j.handL.x) * c.facing >= 0 ? j.handR : j.handL
            let clipDur = max(0.1, AnimationLibrary.clip(forPower: .fireBreath).duration)
            let ph = c.animTime.truncatingRemainder(dividingBy: clipDur) / clipDur
            var intensity: CGFloat = 1
            if ph < 0.36 { intensity = 0.30 + 0.70 * CGFloat(ph / 0.36) }
            else if ph > 0.82 { intensity = max(0.35, 1 - CGFloat((ph - 0.82) / 0.18) * 0.65) }
            drawLayeredFlame(context: &context, origin: frontHand,
                             axis: CGPoint(x: c.facing, y: -0.06),
                             baseLength: 68, baseWidth: 30, time: c.animTime, intensity: intensity)
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

    // MARK: Llama en capas y haz laser (ronda 2, arreglos 2 y 3)

    /// Silueta de llama en forma de gota: sale de `origin` en direccion
    /// `axis` (unitaria), vientre perpendicular de ancho `width` y punta
    /// desviada `wobble` en perpendicular. Dos cuadraticas (borde a borde).
    private func flamePath(origin: CGPoint, axis: CGPoint, length: CGFloat, width: CGFloat, wobble: CGFloat) -> Path {
        let perp = CGPoint(x: -axis.y, y: axis.x)
        func pt(_ along: CGFloat, _ side: CGFloat, _ wob: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + axis.x * along + perp.x * (side + wob),
                    y: origin.y + axis.y * along + perp.y * (side + wob))
        }
        var p = Path()
        p.move(to: origin)
        p.addQuadCurve(to: pt(length, 0, wobble), control: pt(length * 0.42, -width / 2, wobble * 0.35))
        p.addQuadCurve(to: origin, control: pt(length * 0.42, width / 2, wobble * 0.35))
        p.closeSubpath()
        return p
    }

    /// Llama viva en capas: exterior naranja, media amarilla, nucleo
    /// claro. El tamano respira con `time` (la fase del clip de fuego) y
    /// la punta parpadea; chispas deterministas salen disparadas (ciclo
    /// ligado al tiempo, sin estado entre frames).
    private func drawLayeredFlame(context: inout GraphicsContext, origin: CGPoint, axis: CGPoint, baseLength: CGFloat, baseWidth: CGFloat, time: Double, intensity: CGFloat) {
        let fl = 0.88 + 0.12 * CGFloat(sin(time * 23)) + 0.05 * CGFloat(sin(time * 41 + 1.3))
        let len = max(4, baseLength * intensity * fl)
        let wob = CGFloat(sin(time * 29)) * 4.5 * intensity
        let layers: [(CGFloat, CGFloat, Color, Double)] = [
            (1.0, 1.0, Color(red: 1.0, green: 0.40, blue: 0.04), 0.85),
            (0.72, 0.62, Color(red: 1.0, green: 0.70, blue: 0.10), 0.90),
            (0.45, 0.34, Color(red: 1.0, green: 0.93, blue: 0.55), 0.95),
        ]
        for (lf, wf, col, op) in layers {
            var fctx = context; fctx.opacity = op
            fctx.fill(flamePath(origin: origin, axis: axis, length: len * lf, width: baseWidth * wf, wobble: wob * lf), with: .color(col))
        }
        let perp = CGPoint(x: -axis.y, y: axis.x)
        for i in 0..<7 {
            let seed = Double(i) * 0.6180339887
            let cycle = (time * 1.35 + seed).truncatingRemainder(dividingBy: 1)
            let along = len * CGFloat(0.25 + 0.85 * cycle)
            let side = CGFloat(sin(seed * 21.7)) * baseWidth * 0.45 * CGFloat(0.3 + cycle)
            let center = CGPoint(x: origin.x + axis.x * along + perp.x * side,
                                 y: origin.y + axis.y * along + perp.y * side - CGFloat(cycle) * 6)
            let r = 1.1 + 2.1 * CGFloat(1 - cycle)
            var sctx = context; sctx.opacity = (1 - cycle) * 0.9
            sctx.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                      with: .color(i % 2 == 0 ? Color(red: 1, green: 0.78, blue: 0.25) : Color(red: 1, green: 0.55, blue: 0.1)))
        }
    }

    /// Haz laser con nucleo brillante y halo: halo ancho tenue, cuerpo
    /// rojo, nucleo casi blanco, resplandor en el ojo y en el impacto, y
    /// chispas que saltan del punto de impacto.
    private func drawLaserBeam(context: inout GraphicsContext, from: CGPoint, to: CGPoint, time: Double) {
        var beam = Path(); beam.move(to: from); beam.addLine(to: to)
        var halo = context; halo.opacity = 0.16
        halo.stroke(beam, with: .color(.red), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        var mid = context; mid.opacity = 0.45
        mid.stroke(beam, with: .color(.red), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var core = context; core.opacity = 0.95
        core.stroke(beam, with: .color(Color(red: 1, green: 0.97, blue: 0.97)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        var glow = context; glow.opacity = 0.75
        glow.fill(Path(ellipseIn: CGRect(x: from.x - 3.5, y: from.y - 3.5, width: 7, height: 7)), with: .color(.white))
        let ir = 6 + CGFloat(sin(time * 40)) * 1.8
        var iglow = context; iglow.opacity = 0.5
        iglow.fill(Path(ellipseIn: CGRect(x: to.x - ir, y: to.y - ir, width: ir * 2, height: ir * 2)), with: .color(Color(red: 1, green: 0.75, blue: 0.3)))
        for i in 0..<6 {
            let cycle = (time * 2.3 + Double(i) * 0.6180339887).truncatingRemainder(dividingBy: 1)
            let ang = Double(i) * 1.047 + sin(Double(i) * 7.3) * 0.45
            let len = CGFloat(5 + 10 * cycle)
            var spark = Path()
            spark.move(to: to)
            spark.addLine(to: CGPoint(x: to.x + CGFloat(cos(ang)) * len, y: to.y + CGFloat(sin(ang)) * len))
            var sctx = context; sctx.opacity = (1 - cycle) * 0.85
            sctx.stroke(spark, with: .color(Color(red: 1, green: 0.72, blue: 0.25)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
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
        // Cinematicas: si la escena impone una pose, manda ella
        if let cinematic = c.cinematicPose { return cinematic }
        // Superficies primero: la pose manda el ancla
        if c.surface == .ceiling {
            if c.action == .hangingCeiling { return AnimationLibrary.hangCeil.sample(at: c.animTime) }
            // v7: agarrado arriba y columpiandose, el balanceo es swingRope
            if c.action == .swingingRope { return AnimationLibraryV7.swingRope.sample(at: c.animTime) }
            return AnimationLibrary.swingCeil.sample(at: c.gaitPhase01 * AnimationLibrary.swingCeil.duration)
        }
        if c.surface.isWall {
            if c.action == .hangingWall { return AnimationLibrary.hangWall.sample(at: c.animTime) }
            if c.action == .wallClimbing { return AnimationLibrary.climb.sample(at: c.gaitPhase01 * AnimationLibrary.climb.duration * 1.4) }
        }
        if c.isSkidding { return AnimationLibrary.skid.sample(at: c.skidElapsed) }
        if c.isTurning && [.walking, .running, .fleeing].contains(c.action) {
            return AnimationLibrary.turn.sample(at: c.turnElapsed)
        }
        if c.isWallSliding { return AnimationLibrary.wallSlide.sample(at: min(c.animTime, 0.6)) }
        if c.isJumpWindingUp { return AnimationLibrary.jumpCrouch.sample(at: c.animTime) }
        if (c.action == .jumping || c.action == .thrown || c.action == .dropping) && c.isAirborne {
            if c.action == .thrown { return AnimationLibrary.thrownSpin.sample(at: c.animTime) }
            if c.velocityY > 80 { return AnimationLibrary.jumpStretch.sample(at: min(c.animTime, 0.3)) }
            return AnimationLibrary.fallPose.sample(at: c.animTime)
        }
        // v6: supervelocidad = rafaga horizontal (flyDash), no el sprint normal
        if c.action == .running, c.activePower == .superSpeed {
            return AnimationLibrary.flyDash.sample(at: c.animTime)
        }
        switch c.action {
        case .walking, .running, .fleeing, .playingBall, .chasingFinger:
            // Blend caminar<->correr por velocidad REAL, fase de zancada ligada a la velocidad
            let walkPose = AnimationLibrary.walk.sample(at: c.gaitPhase01 * AnimationLibrary.walk.duration)
            let runPose = AnimationLibrary.run.sample(at: c.gaitPhase01 * AnimationLibrary.run.duration)
            return walkPose.lerped(to: runPose, t: c.speedNorm)
        case .climbing:
            return AnimationLibrary.climb.sample(at: c.gaitPhase01 * AnimationLibrary.climb.duration * 1.4)
        case .usingPower:
            // v8: con el despertar activo, el fuego se anuncia cargando la
            // bola entre las palmas (fireCharge) y la superfuerza levanta
            // el bloque ENORME por encima de la cabeza (liftHuge).
            if c.activePower == .fireBreath, c.isAwakened, c.animTime < 1.5 {
                return AnimationLibraryV8.fireCharge.sample(at: c.animTime)
            }
            if c.activePower == .superStrength, c.animTime < 1.7 {
                return AnimationLibraryV8.liftHuge.sample(at: c.animTime)
            }
            if let power = c.activePower { return AnimationLibrary.clip(forPower: power).sample(at: c.animTime) }
            return AnimationLibrary.powerPose.sample(at: c.animTime)
        case .landing:
            // v7: despierto, el aterrizaje es de heroe (heroLanding)
            if c.isAwakened { return AnimationLibraryV7.heroLanding.sample(at: c.animTime) }
            return AnimationLibrary.landing.sample(at: c.animTime)
        case .sitting:
            // v8/v9: sentado, a veces gira solo la cabeza (sitSpinHead);
            // sin silla intacta cerca, se sienta cruzado en el suelo (sitCrossed)
            if c.microActivity == "mira a un lado" { return AnimationLibraryV8.sitSpinHead.sample(at: c.animTime) }
            let chairNear = c.objects.contains { $0.kind == .chair && $0.state == .intact && abs($0.x - c.x) < 60 }
            if !chairNear { return AnimationLibraryV9.sitCrossed.sample(at: c.animTime) }
            return AnimationLibrary.sit.sample(at: c.animTime)
        case .grabbed, .escaping:
            // v3 pose pinch: se estira/inclina hacia el lado del tiron (spec: 7 variantes)
            var pose = AnimationLibrary.clip(for: c.action).sample(at: c.animTime)
            pose.hipDX += c.pinchLean * 7
            pose.headOff.x += c.pinchLean * 5
            pose.handL.x += c.pinchLean * 6
            pose.handR.x += c.pinchLean * 6
            return pose
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
        let pose = resolvedPose()
        let f = c.facing
        let flip = isFlipped
        // ESCALA 0,8 + PROPORCIONES (ViewTuning): todos los offsets de
        // la pose se escalan por cadena al construir las articulaciones
        // (piernas x figureScale; cuello con torsoFactor; cabeza con
        // headOffFactor). Los pies siguen cayendo EXACTOS sobre la
        // linea de apoyo: cadera y pie escalan por el mismo factor.
        let fs = ViewTuning.figureScale
        func sp(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * fs, y: p.y * fs) }
        let neckOff = CGPoint(x: pose.neckOff.x * fs, y: pose.neckOff.y * ViewTuning.torsoFactor * fs)
        let headOff = CGPoint(x: pose.headOff.x * fs, y: pose.headOff.y * ViewTuning.headOffFactor * fs)
        // Normal: pose calculada sobre la linea de pies `g0`.
        // Techo (flip): se calcula con suelo 0 y cada punto se REFLEJA
        // (y' = ancla - y): los pies quedan en el ancla y la cabeza abajo.
        let g0: CGFloat = flip ? 0 : ground
        func fromHip(_ p: CGPoint, hip: CGPoint) -> CGPoint { CGPoint(x: hip.x + p.x * f, y: hip.y + p.y) }
        func fromNeck(_ p: CGPoint, neck: CGPoint) -> CGPoint { CGPoint(x: neck.x + p.x * f, y: neck.y + p.y) }
        let hip0 = CGPoint(x: cx + pose.hipDX * f * fs, y: g0 - pose.hipHeight * fs)
        let neck0 = fromHip(neckOff, hip: hip0)
        let head0 = fromNeck(headOff, neck: neck0)
        var j = JointPoints(
            hip: hip0, neck: neck0, head: head0,
            elbowL: fromNeck(sp(pose.elbowL), neck: neck0), handL: fromNeck(sp(pose.handL), neck: neck0),
            elbowR: fromNeck(sp(pose.elbowR), neck: neck0), handR: fromNeck(sp(pose.handR), neck: neck0),
            kneeL: fromHip(sp(pose.kneeL), hip: hip0), footL: fromHip(sp(pose.footL), hip: hip0),
            kneeR: fromHip(sp(pose.kneeR), hip: hip0), footR: fromHip(sp(pose.footR), hip: hip0))
        // RONDA 2 · arreglo 5: vuelo sostenido con oscilacion suave,
        // aplicada en la VISTA sobre la pose muestreada (los clips no se
        // tocan): bamboleo vertical lento, balanceo lateral que crece
        // hacia la cabeza y estela de piernas con retardo de fase, para
        // que no se traslade como una tabla rigida.
        if c.action == .flying && !flip {
            let t = c.animTime
            // Amplitudes escaladas con la figura (fs): son bamboleo
            // DEL cuerpo, no del mundo.
            let bob = CGFloat(sin(t * 1.6)) * ViewTuning.flightBobAmp * fs
            let sway = CGFloat(sin(t * 2.1)) * fs
            let legLag = CGFloat(sin(t * 2.1 - 1.15))
            func shift(_ p: CGPoint, _ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: p.x + dx, y: p.y + dy) }
            j.hip = shift(j.hip, sway * 0.8, bob)
            j.neck = shift(j.neck, sway * 1.5, bob)
            j.head = shift(j.head, sway * 2.1, bob)
            j.elbowL = shift(j.elbowL, sway * 1.8, bob)
            j.handL = shift(j.handL, sway * 2.0, bob)
            j.elbowR = shift(j.elbowR, sway * 1.8, bob)
            j.handR = shift(j.handR, sway * 2.0, bob)
            j.kneeL = shift(j.kneeL, sway * 0.9, bob + legLag * 1.1 * fs)
            j.kneeR = shift(j.kneeR, sway * 0.9, bob - legLag * 1.1 * fs)
            j.footL = shift(j.footL, sway * 0.7, bob + legLag * ViewTuning.flightLegTrail * fs)
            j.footR = shift(j.footR, sway * 0.7, bob - legLag * ViewTuning.flightLegTrail * fs)
        }
        // V10: GIRO DEL CUERPO ENTERO alrededor de la cadera (el
        // vuelco del lanzado y la inclinacion del salto): el angulo lo
        // integra el solucionador — giro con velocidad angular y
        // recuperacion elastica al aterrizar. En el techo no se
        // aplica: alli manda el ancla invertida.
        if !flip && procBody.bodyAngle != 0 {
            let ca = CGFloat(cos(Double(procBody.bodyAngle)))
            let sa = CGFloat(sin(Double(procBody.bodyAngle)))
            func rot(_ p: CGPoint) -> CGPoint {
                let dx = p.x - j.hip.x, dy = p.y - j.hip.y
                return CGPoint(x: j.hip.x + dx * ca - dy * sa, y: j.hip.y + dx * sa + dy * ca)
            }
            j = JointPoints(hip: j.hip, neck: rot(j.neck), head: rot(j.head),
                            elbowL: rot(j.elbowL), handL: rot(j.handL), elbowR: rot(j.elbowR), handR: rot(j.handR),
                            kneeL: rot(j.kneeL), footL: rot(j.footL), kneeR: rot(j.kneeR), footR: rot(j.footR))
        }
        if flip {
            func m(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: ground - p.y) }
            j = JointPoints(hip: m(j.hip), neck: m(j.neck), head: m(j.head),
                            elbowL: m(j.elbowL), handL: m(j.handL), elbowR: m(j.elbowR), handR: m(j.handR),
                            kneeL: m(j.kneeL), footL: m(j.footL), kneeR: m(j.kneeR), footR: m(j.footR))
        }
        // SEPARACION MINIMA DE PIERNAS (feedback 23:20, prioridad 2:
        // «piernas en bucle/lagrima en poses invertidas y el pino»).
        // Medido sobre los datos: el pino y colgarse del techo YA
        // traen las piernas separadas (curvas a >= 18 u); la fusion
        // en una mancha con bucle ocurre en los clips de piernas
        // ARRASTRADAS JUNTAS (picado, pose de vuelo, dash, agarrado
        // al dedo, columpio de cuerda: rodillas a 3-6 u, pies a
        // 4-7 u) y en las interpolaciones entre keyframes: con trazo
        // 8-10, dos curvas a < 8 u se leen como UNA pierna gorda con
        // un lazo en la cadera. Guarda en la VISTA (los clips no se
        // tocan): si las piernas van juntas y SIN cruzar y el torso
        // no esta tumbado (dormir de lado las apila a proposito), se
        // separan simetricamente lo justo para que se lean DOS.
        let torsoTumbado = abs(j.neck.x - j.hip.x) > (j.hip.y - j.neck.y) + 6
        let piernasCruzadas = (j.footR.x - j.footL.x) * f < -1 || (j.kneeR.x - j.kneeL.x) * f < -1
        if !torsoTumbado && !piernasCruzadas {
            func separar(_ a: inout CGPoint, _ b: inout CGPoint, hasta minD: CGFloat) {
                let dx = b.x - a.x, dy = b.y - a.y
                let d = hypot(dx, dy)
                guard d < minD else { return }
                let ux = d > 0.01 ? dx / d : 1
                let uy = d > 0.01 ? dy / d : 0
                let push = (minD - d) / 2
                a = CGPoint(x: a.x - ux * push, y: a.y - uy * push)
                b = CGPoint(x: b.x + ux * push, y: b.y + uy * push)
            }
            separar(&j.kneeL, &j.kneeR, hasta: 11 * fs + 2)
            separar(&j.footL, &j.footR, hasta: 13 * fs + 2)
        }
        return j
    }

    private func drawStickman(context: inout GraphicsContext, cx: CGFloat, ground: CGFloat, size: CGSize, opacity: Double) {
        let c = controller
        let f = c.facing
        var ctx = context; ctx.opacity = opacity
        let j = jointPoints(cx: cx, ground: ground)
        let pose = resolvedPose()
        let color: Color = c.action == .drawn ? .gray : bodyColor
        // Trazo del cuerpo: el del personaje x escala global (10 x 0,8
        // = 8, ~6,5 % del alto: dentro del 5-8 % de los modelos).
        let lw = c.kind.lineWidth * ViewTuning.figureScale

        // Miembros CURVOS como trazos de pincel (el plano del usuario:
        // brazos y piernas son arcos suaves, no segmentos rectos con
        // angulo de marioneta). Cada miembro es una cuadratica de
        // extremo a extremo cuyo control (2*articulacion - punto medio)
        // hace que la curva PASE por la articulacion: la pose manda lo
        // mismo, pero sin codos/rodillas duros.
        func limb(_ path: inout Path, _ a: CGPoint, _ joint: CGPoint, _ b: CGPoint) {
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let pull = ViewTuning.limbPull
            let control = CGPoint(x: mid.x + (joint.x - mid.x) * pull, y: mid.y + (joint.y - mid.y) * pull)
            path.move(to: a); path.addQuadCurve(to: b, control: control)
        }
        var body = Path()
        body.move(to: j.hip); body.addLine(to: j.neck)
        limb(&body, j.hip, j.kneeL, j.footL)
        limb(&body, j.hip, j.kneeR, j.footR)
        limb(&body, j.neck, j.elbowL, j.handL)
        limb(&body, j.neck, j.elbowR, j.handR)
        ctx.stroke(body, with: .color(color), style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))

        // Cabeza de ANILLO hueco GRANDE (ViewTuning.headDiameter, ya
        // en pantalla = diametro x escala). El squash del clip se
        // AMORTIGUA en la cabeza (0.93–1.07): el anillo se deforma
        // un pelin, no se vuelve gelatina.
        let sq = min(1.07, max(0.93, pose.squash))
        let headH = ViewTuning.headDiameter * ViewTuning.figureScale * sq
        let headW = ViewTuning.headDiameter * ViewTuning.figureScale * (1 + (1 - sq) * 0.55)
        ctx.stroke(Path(ellipseIn: CGRect(x: j.head.x - headW / 2, y: j.head.y - headH / 2, width: headW, height: headH)),
                   with: .color(color), lineWidth: ViewTuning.headStroke * ViewTuning.figureScale)

        // Herramientas/objetos EN LA MANO segun la accion. Los props
        // que lleva EN LA MANO escalan con la figura (fs); los del
        // mundo (botones de teclear, el peso que empuja, la onda del
        // puñetazo al suelo) quedan como están: no son su cuerpo.
        let fs = ViewTuning.figureScale
        let hand = j.handR
        let dir = CGPoint(x: hand.x - j.elbowR.x, y: hand.y - j.elbowR.y)
        let len = max(1, hypot(dir.x, dir.y))
        let unit = CGPoint(x: dir.x / len, y: dir.y / len)
        if c.action == .sword || (c.shieldKind == .sword && c.action == .blocking) {
            let tip = CGPoint(x: hand.x + unit.x * 48 * fs, y: hand.y + unit.y * 48 * fs)
            var sword = Path(); sword.move(to: hand); sword.addLine(to: tip)
            ctx.stroke(sword, with: .color(.gray), lineWidth: 4)
            var guardP = Path()
            guardP.move(to: CGPoint(x: hand.x - unit.y * 7 * fs, y: hand.y + unit.x * 7 * fs))
            guardP.addLine(to: CGPoint(x: hand.x + unit.y * 7 * fs, y: hand.y - unit.x * 7 * fs))
            ctx.stroke(guardP, with: .color(.brown), lineWidth: 4)
        }
        if c.action == .drawingObject {
            // Lapiz grande cogido con las dos manos (como en los videos)
            let tip = CGPoint(x: hand.x + f * 16 * fs, y: hand.y + 30 * fs)
            var pencil = Path(); pencil.move(to: CGPoint(x: hand.x - f * 10 * fs, y: hand.y - 16 * fs)); pencil.addLine(to: tip)
            ctx.stroke(pencil, with: .color(Color(red: 0.95, green: 0.75, blue: 0.15)), lineWidth: 7)
            var tipP = Path(); tipP.move(to: CGPoint(x: hand.x + f * 11 * fs, y: hand.y + 21 * fs)); tipP.addLine(to: tip)
            ctx.stroke(tipP, with: .color(.black), lineWidth: 3)
        }
        if c.action == .usingTool {
            // Goma rosa en la mano
            ctx.stroke(Path(CGRect(x: hand.x - 9 * fs, y: hand.y - 6 * fs, width: 18 * fs, height: 12 * fs)), with: .color(.pink), lineWidth: 4)
        }
        if c.action == .hammering {
            let grip = hand
            let headC = CGPoint(x: grip.x + unit.x * 26 * fs, y: grip.y + unit.y * 26 * fs)
            var handle = Path(); handle.move(to: CGPoint(x: grip.x - unit.x * 8 * fs, y: grip.y - unit.y * 8 * fs)); handle.addLine(to: headC)
            ctx.stroke(handle, with: .color(.brown), lineWidth: 4.5)
            var headP = Path()
            headP.move(to: CGPoint(x: headC.x - unit.y * 11 * fs, y: headC.y + unit.x * 11 * fs))
            headP.addLine(to: CGPoint(x: headC.x + unit.y * 11 * fs, y: headC.y - unit.x * 11 * fs))
            ctx.stroke(headP, with: .color(.gray), lineWidth: 8)
        }
        if c.shieldKind == .block && c.action == .blocking {
            // Bloque de la interfaz usado como ESCUDO delante del cuerpo
            // (anclado al centro del torso, no a una altura fija).
            let shieldCenter = CGPoint(x: cx + f * 34 * fs, y: (j.hip.y + j.neck.y) / 2)
            ctx.stroke(Path(CGRect(x: shieldCenter.x - 19 * fs, y: shieldCenter.y - 24 * fs, width: 38 * fs, height: 48 * fs)), with: .color(.purple), lineWidth: 4.5)
        }
        // Props de las acciones nuevas (v7/v8/v9): sin ellos el mimo no se lee
        if c.action == .eating {
            // Merienda dibujada en la mano que sube a la boca
            ctx.fill(Path(ellipseIn: CGRect(x: hand.x - 7 * fs, y: hand.y - 7 * fs, width: 14 * fs, height: 14 * fs)), with: .color(Color(red: 0.45, green: 0.75, blue: 0.35)))
        }
        if c.action == .drinking {
            // Vaso en la mano
            ctx.stroke(Path(CGRect(x: hand.x - 6 * fs, y: hand.y - 12 * fs, width: 12 * fs, height: 14 * fs)), with: .color(Color(red: 0.3, green: 0.6, blue: 0.9)), lineWidth: 3)
        }
        if c.action == .snatching || c.action == .conducting {
            // Herramienta arrebatada / lapiz-batuta: palo fino en la mano
            var baton = Path(); baton.move(to: hand); baton.addLine(to: CGPoint(x: hand.x + unit.x * 34 * fs, y: hand.y + unit.y * 34 * fs))
            ctx.stroke(baton, with: .color(Color(red: 0.95, green: 0.75, blue: 0.15)), lineWidth: 4)
        }
        if c.action == .typing {
            // Dos botones de la interfaz bajo sus manos freneticas
            for dx in [-26.0, 8.0] {
                ctx.stroke(Path(CGRect(x: cx + dx, y: ground - 12, width: 30, height: 10)), with: .color(.gray), lineWidth: 2.5)
            }
        }
        if c.action == .pushingHeavy {
            // El peso que empuja: bloque grande delante, a ras de suelo
            ctx.stroke(Path(CGRect(x: cx + f * 30 - 24, y: ground - 46, width: 48, height: 46)), with: .color(.gray), lineWidth: 4.5)
        }
        if c.action == .carryingLoaded || c.action == .throwingLoaded {
            // La carga sobre la cabeza (el objeto que sujetan las manos en alto)
            ctx.stroke(Path(CGRect(x: j.head.x - 17 * fs, y: j.head.y - 52 * fs, width: 34 * fs, height: 30 * fs)), with: .color(Color(red: 0.6, green: 0.45, blue: 0.3)), lineWidth: 4)
        }
        if c.action == .groundPounding, c.animTime > 0.55, c.animTime < 1.1 {
            // Onda de choque del punetazo al suelo (impacto a los 0.64 s)
            let r = 20 + (c.animTime - 0.55) * 130
            var wave = Path(); wave.addEllipse(in: CGRect(x: cx - r, y: ground - 7, width: r * 2, height: 14))
            ctx.stroke(wave, with: .color(.orange.opacity(0.7)), lineWidth: 3)
        }
        _ = size
    }
}
