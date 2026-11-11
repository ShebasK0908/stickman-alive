import SwiftUI
import AVKit
import AVFoundation
import CoreMedia
import CoreVideo

// MARK: - Modo flotante (Picture-in-Picture) — v5
//
// The Chosen One en una ventanita que flota sobre las demas apps.
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

    func currentPose() -> SkeletonPose {
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
        func fromHip(_ p: CGPoint, hip: CGPoint) -> CGPoint { CGPoint(x: hip.x + p.x * facing, y: hip.y + p.y) }
        func fromNeck(_ p: CGPoint, neck: CGPoint) -> CGPoint { CGPoint(x: neck.x + p.x * facing, y: neck.y + p.y) }
        let hip = CGPoint(x: cx + pose.hipDX * facing, y: ground - pose.hipHeight)
        let neck = fromHip(pose.neckOff, hip: hip)
        let head = fromNeck(pose.headOff, neck: neck)
        return Joints(hip: hip, neck: neck, head: head,
                      elbowL: fromNeck(pose.elbowL, neck: neck), handL: fromNeck(pose.handL, neck: neck),
                      elbowR: fromNeck(pose.elbowR, neck: neck), handR: fromNeck(pose.handR, neck: neck),
                      kneeL: fromHip(pose.kneeL, hip: hip), footL: fromHip(pose.footL, hip: hip),
                      kneeR: fromHip(pose.kneeR, hip: hip), footR: fromHip(pose.footR, hip: hip))
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
        let ink = CGColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)

        // Aura amarilla cuando suelta un poder
        if engine.mode == .power {
            let auraAlpha = 0.16 + 0.06 * sin(engine.animTime * 6)
            ctx.setFillColor(CGColor(red: 1.0, green: 0.85, blue: 0.1, alpha: auraAlpha))
            ctx.fillEllipse(in: CGRect(x: engine.x - 70, y: ground - 180, width: 140, height: 180))
        }

        // Efectos de poder
        if engine.mode == .power {
            if engine.powerIsFire {
                let flicker = CGFloat(sin(engine.animTime * 22)) * 9
                let hand = j.handR
                let tipX = hand.x + engine.facing * (74 + flicker)
                let flame = CGMutablePath()
                flame.move(to: hand)
                flame.addLine(to: CGPoint(x: tipX, y: hand.y - 15))
                flame.addLine(to: CGPoint(x: hand.x + engine.facing * 58, y: hand.y + 16))
                flame.closeSubpath()
                ctx.setFillColor(CGColor(red: 1.0, green: 0.45, blue: 0.05, alpha: 0.8))
                ctx.addPath(flame)
                ctx.fillPath()
            } else {
                let head = j.head
                let end = CGPoint(x: head.x + engine.facing * 300, y: head.y + 6 + CGFloat(sin(engine.animTime * 30)) * 2)
                ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.30))
                ctx.setLineWidth(11)
                ctx.move(to: head); ctx.addLine(to: end); ctx.strokePath()
                ctx.setStrokeColor(CGColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.95))
                ctx.setLineWidth(4)
                ctx.move(to: head); ctx.addLine(to: end); ctx.strokePath()
            }
        }

        // Cuerpo: mismos trazos redondos que en la app
        let body = CGMutablePath()
        body.move(to: j.hip); body.addLine(to: j.neck)
        body.move(to: j.hip); body.addLine(to: j.kneeL); body.addLine(to: j.footL)
        body.move(to: j.hip); body.addLine(to: j.kneeR); body.addLine(to: j.footR)
        body.move(to: j.neck); body.addLine(to: j.elbowL); body.addLine(to: j.handL)
        body.move(to: j.neck); body.addLine(to: j.elbowR); body.addLine(to: j.handR)
        ctx.setStrokeColor(ink)
        ctx.setLineWidth(7)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(body)
        ctx.strokePath()

        // Cabeza LLENA, con el squash del clip (nuestro dibujo de siempre)
        let headH = 40 * pose.squash
        let headW = 40 * (1 + (1 - pose.squash) * 0.55)
        ctx.setFillColor(ink)
        ctx.fillEllipse(in: CGRect(x: j.head.x - headW / 2, y: j.head.y - headH / 2, width: headW, height: headH))

        // "Z" de sueno: tres trazos que suben y se desvanecen (se dibujan
        // como polilineas, sin depender de texto/CoreText en este contexto)
        if engine.mode == .sleep {
            for i in 0..<3 {
                let cycle = (engine.animTime * 0.45 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let zx = j.head.x - 26 + CGFloat(cycle) * 20
                let zy = j.head.y - 30 - CGFloat(cycle) * 34
                let s = CGFloat(5 + cycle * 5)
                ctx.setStrokeColor(CGColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 0.85 * (1 - cycle)))
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
        guard displayLayer.readyForMoreMediaData else { return }
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
