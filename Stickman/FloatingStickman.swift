import SwiftUI
import AVKit
import AVFoundation
import CoreMedia
import CoreVideo

// MARK: - Modo flotante (Picture-in-Picture) — v5
//
// The Second Coming en una ventanita que flota sobre las demas apps.
// Implementacion con AVPictureInPictureController +
// AVSampleBufferDisplayLayer: renderizamos NUESTRA escena (el mismo
// sistema de poses por keyframes de StickmanAnimation.swift) a un
// CVPixelBuffer de 640x360 a ~30 fps y lo encolamos como si fuera un
// video. Dentro de la ventana lleva una vida simple y autonoma:
// camina de un lado a otro, se para, se sienta en el borde inferior,
// duerme una siesta y de vez en cuando suelta un poder (fuego/laser).
//
// NO usa el StickmanController principal: es un motor mini propio,
// para que la ventanita viva aunque la escena principal este en pausa.

// MARK: Motor mini de la escena flotante

final class FloatingSceneEngine {
    enum Mode { case walk, idle, sit, sleep, power }

    let width: CGFloat = 640
    let height: CGFloat = 360
    /// Linea de suelo (coordenadas de pantalla, y hacia abajo).
    let ground: CGFloat = 322

    private(set) var mode: Mode = .walk
    private(set) var powerIsFire = true
    var animTime: Double = 0
    var x: CGFloat = 150
    var facing: CGFloat = 1

    private var modeTime: Double = 0
    private var modeDuration: Double = 5
    private var gaitTime: Double = 0

    func update(dt: Double) {
        animTime += dt
        modeTime += dt
        if mode == .walk {
            x += facing * 62 * CGFloat(dt)
            gaitTime += dt * 62 / 52
            if x > width - 90 { x = width - 90; facing = -1 }
            if x < 90 { x = 90; facing = 1 }
        }
        if modeTime >= modeDuration { nextMode() }
    }

    private func nextMode() {
        modeTime = 0
        let options: [Mode] = [.walk, .idle, .walk, .sit, .power, .walk, .sleep]
        var next = options.randomElement() ?? .walk
        if next == mode { next = (mode == .walk) ? .idle : .walk }
        if next == .power { powerIsFire.toggle() }
        if next == .sleep { x = min(max(x, 130), width - 130) } // que no se salga tumbado
        mode = next
        switch next {
        case .walk: modeDuration = Double.random(in: 4...7)
        case .idle: modeDuration = Double.random(in: 2...3.5)
        case .sit: modeDuration = Double.random(in: 3.5...5.5)
        case .sleep: modeDuration = Double.random(in: 5...7)
        case .power: modeDuration = 1.9
        }
    }

    // V10: la ventanita comparte el motor procedural de la vista
    // principal (mismo solucionador, misma marcha generada): camina e
    // idle pasan por los generadores; sentarse/dormir/poderes siguen
    // saliendo de sus clips pero a traves de los muelles (peso).
    private let procBody = ProceduralBody()

    func currentPose() -> SkeletonPose {
        var ctx = ProceduralContext(action: .idle, time: animTime)
        ctx.facing = facing
        ctx.animTime = animTime
        switch mode {
        case .walk:
            ctx.action = .walking
            ctx.gaitPhase01 = (gaitTime / 0.8).truncatingRemainder(dividingBy: 1)
            if ctx.gaitPhase01 < 0 { ctx.gaitPhase01 += 1 }
            ctx.speedNorm = 0.12
            ctx.moveSpeed = 62
        case .idle:
            ctx.action = .idle
        case .sit:
            ctx.action = .sitting
        case .sleep:
            ctx.action = .sleeping
        case .power:
            ctx.action = .usingPower
        }
        return procBody.resolve(context: ctx, clipPose: { clipPose() })
    }

    private func clipPose() -> SkeletonPose {
        switch mode {
        case .walk: return AnimationLibrary.walk.sample(at: gaitTime)
        case .idle: return AnimationLibrary.idle.sample(at: animTime)
        case .sit: return AnimationLibrary.sit.sample(at: animTime)
        case .sleep: return AnimationLibrary.sleep.sample(at: animTime)
        case .power:
            return powerIsFire
                ? AnimationLibrary.firePose.sample(at: animTime)
                : AnimationLibrary.laserPose.sample(at: animTime)
        }
    }
}

// MARK: Render a CVPixelBuffer con CoreGraphics (misma matematica de
// articulaciones que StickmanView, pero dibujando en un CGContext)

enum FloatingRenderer {
    static let pixelWidth = 640
    static let pixelHeight = 360

    static func makePixelBuffer() -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, pixelWidth, pixelHeight,
                                         kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pb)
        return status == kCVReturnSuccess ? pb : nil
    }

    private struct Joints {
        var hip, neck, head, elbowL, handL, elbowR, handR, kneeL, footL, kneeR, footR: CGPoint
    }

    private static func joints(pose: SkeletonPose, cx: CGFloat, ground: CGFloat, facing: CGFloat) -> Joints {
        // ESPEJO de StickmanView.jointPoints: escala global 0,8 y
        // factores de proporcion (torso x1,06, cabeza x1,28) de
        // ViewTuning — mantener en sync con StickmanView.swift.
        let fs: CGFloat = 0.8
        func sp(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * fs, y: p.y * fs) }
        let neckOff = CGPoint(x: pose.neckOff.x * fs, y: pose.neckOff.y * 1.06 * fs)
        let headOff = CGPoint(x: pose.headOff.x * fs, y: pose.headOff.y * 1.28 * fs)
        func fromHip(_ p: CGPoint, hip: CGPoint) -> CGPoint { CGPoint(x: hip.x + p.x * facing, y: hip.y + p.y) }
        func fromNeck(_ p: CGPoint, neck: CGPoint) -> CGPoint { CGPoint(x: neck.x + p.x * facing, y: neck.y + p.y) }
        let hip = CGPoint(x: cx + pose.hipDX * facing * fs, y: ground - pose.hipHeight * fs)
        let neck = fromHip(neckOff, hip: hip)
        let head = fromNeck(headOff, neck: neck)
        var j = Joints(hip: hip, neck: neck, head: head,
                      elbowL: fromNeck(sp(pose.elbowL), neck: neck), handL: fromNeck(sp(pose.handL), neck: neck),
                      elbowR: fromNeck(sp(pose.elbowR), neck: neck), handR: fromNeck(sp(pose.handR), neck: neck),
                      kneeL: fromHip(sp(pose.kneeL), hip: hip), footL: fromHip(sp(pose.footL), hip: hip),
                      kneeR: fromHip(sp(pose.kneeR), hip: hip), footR: fromHip(sp(pose.footR), hip: hip))
        // Separacion minima de piernas, espejo de la guarda de
        // StickmanView.jointPoints (piernas arrastradas juntas que se
        // funden en una mancha): mismas reglas y umbrales.
        let torsoTumbado = abs(j.neck.x - j.hip.x) > (j.hip.y - j.neck.y) + 6
        let piernasCruzadas = (j.footR.x - j.footL.x) * facing < -1 || (j.kneeR.x - j.kneeL.x) * facing < -1
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

    static func draw(engine: FloatingSceneEngine, into pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        guard let ctx = CGContext(data: base, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return }

        // Trabajamos en coordenadas de pantalla (y hacia abajo), como SwiftUI.
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)

        let sceneW = engine.width
        let ground = engine.ground

        // Fondo: el lienzo blanco de la app, con su linea de suelo.
        ctx.setFillColor(CGColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: sceneW, height: engine.height))
        ctx.setStrokeColor(CGColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 0.55))
        ctx.setLineWidth(2.5)
        ctx.move(to: CGPoint(x: 0, y: ground))
        ctx.addLine(to: CGPoint(x: sceneW, y: ground))
        ctx.strokePath()

        let pose = engine.currentPose()
        let j = joints(pose: pose, cx: engine.x, ground: ground, facing: engine.facing)
        let ink = CGColor(red: 0.945, green: 0.506, blue: 0.047, alpha: 1)

        // Aura cuando suelta un poder: pegada al cuerpo, sin huevo gigante
        if engine.mode == .power {
            let auraAlpha = 0.12 + 0.04 * sin(engine.animTime * 6)
            ctx.setFillColor(CGColor(red: 1.0, green: 0.85, blue: 0.1, alpha: CGFloat(auraAlpha)))
            ctx.fillEllipse(in: CGRect(x: engine.x - 55 * 0.8, y: ground - 170 * 0.8, width: 110 * 0.8, height: 170 * 0.8))
        }

        // Efectos de poder
        if engine.mode == .power {
            if engine.powerIsFire {
                // RONDA 2 · arreglo 2 (espejo de la vista principal):
                // llama VIVA en capas con la envolvente del clip
                // firePose y chispas; fuera el triangulo plano.
                let hand = j.handR
                let clipDur = max(0.1, AnimationLibrary.firePose.duration)
                let ph = engine.animTime.truncatingRemainder(dividingBy: clipDur) / clipDur
                var inten = 1.0
                if ph < 0.36 { inten = 0.30 + 0.70 * (ph / 0.36) }
                else if ph > 0.82 { inten = max(0.35, 1 - (ph - 0.82) / 0.18 * 0.65) }
                let fl = 0.88 + 0.12 * sin(engine.animTime * 23) + 0.05 * sin(engine.animTime * 41 + 1.3)
                let len = CGFloat(76 * inten * fl)
                let wob = CGFloat(sin(engine.animTime * 29)) * 4 * CGFloat(inten)
                let axis = CGPoint(x: engine.facing, y: -0.06)
                let perp = CGPoint(x: -axis.y, y: axis.x)
                func flameLayer(_ lf: CGFloat, _ wf: CGFloat, _ col: CGColor) {
                    let L = len * lf
                    let W: CGFloat = 30 * wf
                    func pt(_ along: CGFloat, _ side: CGFloat, _ w: CGFloat) -> CGPoint {
                        CGPoint(x: hand.x + axis.x * along + perp.x * (side + w),
                                y: hand.y + axis.y * along + perp.y * (side + w))
                    }
                    let p = CGMutablePath()
                    p.move(to: hand)
                    p.addQuadCurve(to: pt(L, 0, wob * lf), control: pt(L * 0.42, -W / 2, wob * lf * 0.35))
                    p.addQuadCurve(to: hand, control: pt(L * 0.42, W / 2, wob * lf * 0.35))
                    p.closeSubpath()
                    ctx.setFillColor(col)
                    ctx.addPath(p)
                    ctx.fillPath()
                }
                flameLayer(1.0, 1.0, CGColor(red: 1, green: 0.40, blue: 0.04, alpha: 0.85))
                flameLayer(0.72, 0.62, CGColor(red: 1, green: 0.70, blue: 0.10, alpha: 0.90))
                flameLayer(0.45, 0.34, CGColor(red: 1, green: 0.93, blue: 0.55, alpha: 0.95))
                // Chispas deterministas ligadas al tiempo
                for i in 0..<6 {
                    let seed = Double(i) * 0.6180339887
                    let cycle = (engine.animTime * 1.35 + seed).truncatingRemainder(dividingBy: 1)
                    let along = len * CGFloat(0.25 + 0.85 * cycle)
                    let side = CGFloat(sin(seed * 21.7)) * 13 * CGFloat(0.3 + cycle)
                    let cxp = hand.x + axis.x * along + perp.x * side
                    let cyp = hand.y + axis.y * along + perp.y * side - CGFloat(cycle) * 6
                    let r = CGFloat(1.1 + 2.1 * (1 - cycle))
                    ctx.setFillColor(CGColor(red: 1, green: 0.72, blue: 0.25, alpha: CGFloat((1 - cycle) * 0.9)))
                    ctx.fillEllipse(in: CGRect(x: cxp - r, y: cyp - r, width: r * 2, height: r * 2))
                }
            } else {
                // RONDA 2 · arreglo 3 (espejo): nucleo blanco anadido
                // y chispas en el extremo del haz.
                let head = j.head
                let end = CGPoint(x: head.x + engine.facing * 300, y: head.y + 6 + CGFloat(sin(engine.animTime * 30)) * 2)
                ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.30))
                ctx.setLineWidth(11)
                ctx.move(to: head); ctx.addLine(to: end); ctx.strokePath()
                ctx.setStrokeColor(CGColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.95))
                ctx.setLineWidth(4)
                ctx.move(to: head); ctx.addLine(to: end); ctx.strokePath()
                ctx.setStrokeColor(CGColor(red: 1, green: 0.98, blue: 0.98, alpha: 0.95))
                ctx.setLineWidth(1.8)
                ctx.move(to: head); ctx.addLine(to: end); ctx.strokePath()
                for i in 0..<6 {
                    let cycle = (engine.animTime * 2.3 + Double(i) * 0.6180339887).truncatingRemainder(dividingBy: 1)
                    let ang = Double(i) * 1.047 + sin(Double(i) * 7.3) * 0.45
                    let slen = CGFloat(5 + 10 * cycle)
                    ctx.setStrokeColor(CGColor(red: 1, green: 0.72, blue: 0.25, alpha: CGFloat((1 - cycle) * 0.85)))
                    ctx.setLineWidth(2)
                    ctx.move(to: end)
                    ctx.addLine(to: CGPoint(x: end.x + CGFloat(cos(ang)) * slen, y: end.y + CGFloat(sin(ang)) * slen))
                    ctx.strokePath()
                }
            }
        }

        // Cuerpo: miembros CURVOS como trazo de pincel, igual que en la
        // app (cuadratica que pasa por la articulacion, sin angulo duro)
        func limb(_ path: CGMutablePath, _ a: CGPoint, _ joint: CGPoint, _ b: CGPoint) {
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let pull: CGFloat = 2.0   // espejo de ViewTuning.limbPull (StickmanView): mantener en sync
            let control = CGPoint(x: mid.x + (joint.x - mid.x) * pull, y: mid.y + (joint.y - mid.y) * pull)
            path.move(to: a); path.addQuadCurve(to: b, control: control)
        }
        let body = CGMutablePath()
        body.move(to: j.hip); body.addLine(to: j.neck)
        limb(body, j.hip, j.kneeL, j.footL)
        limb(body, j.hip, j.kneeR, j.footR)
        limb(body, j.neck, j.elbowL, j.handL)
        limb(body, j.neck, j.elbowR, j.handR)
        ctx.setStrokeColor(ink)
        ctx.setLineWidth(8)   // 10 x escala 0,8 (espejo de la app)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(body)
        ctx.strokePath()

        // Cabeza de ANILLO hueco, con el squash AMORTIGUADO (0.93–1.07)
        // (diametro espejo de ViewTuning.headDiameter en StickmanView,
        // ya multiplicado por la escala 0,8: 58 x 0,8 — R10, cabeza
        // al ~35 % estricto del alto, como en los modelos del usuario)
        let headD: CGFloat = 58 * 0.8
        let sq = min(1.07, max(0.93, pose.squash))
        let headH = headD * sq
        let headW = headD * (1 + (1 - sq) * 0.55)
        ctx.setStrokeColor(ink)
        ctx.setLineWidth(8.5 * 0.8)   // espejo de ViewTuning.headStroke x escala
        ctx.strokeEllipse(in: CGRect(x: j.head.x - headW / 2, y: j.head.y - headH / 2, width: headW, height: headH))

        // "Z" de sueno: tres trazos que suben y se desvanecen (se dibujan
        // como polilineas, sin depender de texto/CoreText en este contexto)
        if engine.mode == .sleep {
            for i in 0..<3 {
                let cycle = (engine.animTime * 0.45 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let zx = j.head.x - 26 + CGFloat(cycle) * 20
                let zy = j.head.y - 30 - CGFloat(cycle) * 34
                let s = CGFloat(5 + cycle * 5)
                ctx.setStrokeColor(CGColor(red: 0.25, green: 0.45, blue: 0.85, alpha: CGFloat(0.85 * (1 - cycle))))
                ctx.setLineWidth(2.4)
                ctx.move(to: CGPoint(x: zx - s, y: zy - s))
                ctx.addLine(to: CGPoint(x: zx + s, y: zy - s))
                ctx.addLine(to: CGPoint(x: zx - s, y: zy + s))
                ctx.addLine(to: CGPoint(x: zx + s, y: zy + s))
                ctx.strokePath()
            }
        }
    }
}

// MARK: Gestor del PiP

final class FloatingPiPManager: NSObject, ObservableObject {
    static let shared = FloatingPiPManager()

    let displayLayer = AVSampleBufferDisplayLayer()

    @Published private(set) var isFloating = false  // el PiP esta en pantalla
    @Published private(set) var isEnabled = false   // el usuario lo ha activado (renderizando)

    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    private var pipController: AVPictureInPictureController?
    private var timer: DispatchSourceTimer?
    private let renderQueue = DispatchQueue(label: "dev.stickman.alive.pip", qos: .userInitiated)
    private let engine = FloatingSceneEngine()
    private var frameIndex: Int64 = 0
    private var firstPTS: CMTime?
    private var playing = true

    private override init() { super.init() }

    func toggle() {
        isEnabled ? disable() : enable()
    }

    func enable() {
        guard isSupported else { return }
        configureAudioSession()
        if pipController == nil {
            let source = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: displayLayer,
                playbackDelegate: self)
            let controller = AVPictureInPictureController(contentSource: source)
            controller.delegate = self
            controller.canStartPictureInPictureAutomaticallyFromInline = true
            pipController = controller
        }
        isEnabled = true
        startTimerIfNeeded()
        // Dejamos que lleguen unos frames antes de abrir la ventanita.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.isEnabled else { return }
            if self.pipController?.isPictureInPictureActive != true {
                self.pipController?.startPictureInPicture()
            }
        }
    }

    func disable() {
        isEnabled = false
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        }
        stopTimer()
    }

    private func configureAudioSession() {
        // PiP exige una sesion de audio en modo playback (aunque no suene nada).
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [])
        try? session.setActive(true)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        frameIndex = 0
        firstPTS = nil
        let t = DispatchSource.makeTimerSource(queue: renderQueue)
        t.schedule(deadline: .now(), repeating: .milliseconds(33)) // ~30 fps
        t.setEventHandler { [weak self] in self?.produceFrame() }
        t.activate()
        timer = t
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func produceFrame() {
        if displayLayer.status == .failed {
            displayLayer.flush()
            firstPTS = nil
            frameIndex = 0
        }
        guard displayLayer.isReadyForMoreMediaData else { return }
        engine.update(dt: 1.0 / 30.0)
        guard let pixelBuffer = FloatingRenderer.makePixelBuffer() else { return }
        FloatingRenderer.draw(engine: engine, into: pixelBuffer)

        var formatDescription: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription) == noErr,
              let formatDescription else { return }

        if firstPTS == nil { firstPTS = CMClockGetTime(CMClockGetHostTimeClock()) }
        let pts = firstPTS! + CMTime(value: frameIndex, timescale: 30)
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30),
                                        presentationTimeStamp: pts,
                                        decodeTimeStamp: .invalid)
        var sampleBuffer: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            formatDescription: formatDescription, sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer) == noErr,
              let sampleBuffer else { return }

        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
           CFArrayGetCount(attachments) > 0 {
            let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dict,
                                 Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        displayLayer.enqueue(sampleBuffer)
        frameIndex += 1
    }
}

// MARK: Delegados de PiP

extension FloatingPiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isFloating = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isFloating = false
        if !isEnabled { stopTimer() }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        isFloating = false
    }
}

extension FloatingPiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    setPlaying playing: Bool) {
        self.playing = playing
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        !playing
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    skipByInterval skipInterval: CMTime,
                                    completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// MARK: Vista anfitriona de la capa de video (2x2, casi invisible):
// el PiP necesita que la AVSampleBufferDisplayLayer exista en la
// jerarquia de vistas para poder "despegar" como ventana flotante.

struct PiPLayerHost: UIViewRepresentable {
    let layer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        layer.frame = uiView.bounds
    }
}
