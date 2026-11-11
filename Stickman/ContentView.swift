import SwiftUI

// MARK: - Escena: un programa de animacion falso tipo Adobe Animate
// The Second Coming vive AHI dentro: lienzo, toolbar, timeline y botones son su mundo.
//
// v2 — POR QUE LA TOOLBAR DE LA v1 NO RESPONDIA (diagnostico):
//  1) Era un VStack de Image(systemName:) SIN botones: puro dibujo.
//  2) El lienzo llevaba un DragGesture(minimumDistance: 0) que lo
//     interpretaba TODO como cursor/arrastre, y no existia ningun modo
//     lapiz/goma ni trazos en el modelo.
// SOLUCION v2 (se mantiene en v3): la toolbar es una columna de Buttons
// REALES, en un HStack HERMANO del lienzo (fuera del GeometryReader y de
// su gesto), cada uno de >=52 pt. El unico gesto es el del lienzo, y se
// RAMIFICA por el modo activo: cursor = agarrar/tocar, lapiz = trazo,
// goma = borrar.
//
// UN solo personaje en escena — The Second Coming (naranja, poderes) —
// con su controlador y su cerebro. El gesto de arrastre lo agarra a el;
// el toque reacciona en el; los trazos del usuario son suyos.

struct ContentView: View {
    @StateObject private var tco = StickmanController(kind: .secondComing)
    @ObservedObject private var pip = FloatingPiPManager.shared
    @StateObject private var cinematics = CinematicCoordinator()

    @State private var showBrain = false
    @State private var showCinematicsMenu = false
    @State private var showConsole = false
    @State private var consoleCount = 0
    @State private var consoleFinishedWait = 0.0
    @State private var cursorPoint: CGPoint? = nil
    @State private var isDraggingHim = false
    @State private var dragChecked = false
    @State private var strokeStarted = false

    private let tickTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let consoleTimer = Timer.publish(every: 0.028, on: .main, in: .common).autoconnect()

    private let consoleText = """
    $ python3 bring_to_life.py
    import stickman
    tsc = dibujar(color = "naranja")   # The Second Coming
    tsc.awake()   # esto es broma, como en el video ;)
    > DESPERTANDO A THE SECOND COMING...
    """

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if showBrain { brainPanel }
            stage
            modeStatusRow
            timeline
            suggestionBar
            Text("Las órdenes son sugerencias: tiene su propio cerebro, roaming 360° e IA para defenderse de tu dedo.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
        }
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .onAppear { cinematics.attach(controller: tco) }
        .onReceive(consoleTimer) { _ in typeConsole() }
        .onChange(of: tco.dragEscapeSignal) { _ in if isDraggingHim { isDraggingHim = false; dragChecked = false } }
        .sheet(isPresented: $showCinematicsMenu) { CinematicMenuView(coordinator: cinematics) }
    }

    // MARK: Barra superior

    private var topBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 11, height: 11)
            Circle().fill(Color.yellow).frame(width: 11, height: 11)
            Circle().fill(Color.green).frame(width: 11, height: 11)
            Text("Animate — the_second_coming.fla")
                .font(.subheadline.bold()).foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            if tco.isAwakened {
                Text("⚡ SECOND COMING")
                    .font(.caption.bold()).foregroundColor(.black)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.yellow).cornerRadius(6)
            }
            Text(tco.isAlive ? "TSC: \(tco.emotion.rawValue)" : "Sin vida")
                .font(.caption).foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
            Button(showBrain ? "🧠▲" : "🧠") { showBrain.toggle() }
                .font(.headline)
                .accessibilityLabel("Ver su cerebro")
            Button("🎬") { showCinematicsMenu = true }
                .font(.headline)
                .accessibilityLabel("Cinemáticas")
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color(red: 0.23, green: 0.23, blue: 0.26))
    }

    // MARK: Panel del cerebro + IA tactil

    private var brainPanel: some View {
        brainColumn(tco, title: "🧠 The Second Coming (naranja)")
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color(red: 0.20, green: 0.20, blue: 0.23))
    }

    private func brainColumn(_ c: StickmanController, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.caption.bold()).foregroundColor(.white)
                Spacer()
                if c.isResting {
                    Text("💤 \(Int(c.restSecondsLeft))s").font(.caption2).foregroundColor(.cyan)
                } else {
                    Text("⏳\(Int(c.secondsUntilRest))s").font(.caption2).foregroundColor(.white.opacity(0.8))
                }
            }
            driveRow("Energía", c.drives.energy, .green)
            driveRow("Curiosid.", c.drives.curiosity, .blue)
            driveRow("Jugar", c.drives.playfulness, .pink)
            driveRow("Travesura", c.drives.mischief, .purple)
            driveRow("Social", c.drives.sociability, .orange)
            driveRow("Aburrim.", c.drives.boredom, .gray)
            driveRow("Enfado", c.drives.anger, .red)
            driveRow("Acoso IA", c.harassmentLevel, .pink)
            Text("Plan: \(c.currentPlanName) · \(c.microActivity) · \(c.surface.rawValue)")
                .font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(2)
            Text("IA: \(c.lastDecision)")
                .font(.caption2).foregroundColor(.white.opacity(0.7)).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func driveRow(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.8)).frame(width: 56, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * CGFloat(min(100, max(0, value))) / 100)
                }
            }
            .frame(height: 7)
            Text("\(Int(value))").font(.caption2).foregroundColor(.white.opacity(0.8)).frame(width: 22, alignment: .trailing)
        }
    }

    // MARK: Escenario principal (toolbar REAL + lienzo)

    private var stage: some View {
        HStack(spacing: 0) {
            toolbar
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.white)
                    // Anfitrion (2x2, invisible) de la capa del modo flotante:
                    // el PiP despega desde esta AVSampleBufferDisplayLayer.
                    PiPLayerHost(layer: pip.displayLayer)
                        .frame(width: 2, height: 2)
                        .opacity(0.02)
                        .allowsHitTesting(false)
                    gridOverlay(size: geo.size)
                    StickmanCanvasView(controller: tco)
                        .offset(x: shakeOffset)
                        // Camara de las cinematicas: zoom sobre el foco de la escena
                        .scaleEffect(cinematics.player.camera.scale,
                                     anchor: UnitPoint(x: CGFloat(cinematics.player.camera.focusX),
                                                       y: CGFloat(cinematics.player.camera.focusY)))
                    CinematicOverlayView(coordinator: cinematics)
                    bubble(for: tco, size: geo.size)
                    if let cursor = cursorPoint, tco.toolMode == .cursor {
                        Image(systemName: "cursorarrow")
                            .font(.system(size: 34))
                            .foregroundColor(.black)
                            .shadow(radius: 2)
                            .rotationEffect(.degrees(tco.isGrabbingFinger ? sin(tco.phase * 18) * 14 : 0))
                            .position(x: cursor.x, y: cursor.y)
                    }
                    if !tco.isAlive && !showConsole {
                        Button(action: startConsole) {
                            Text("▶ Darle vida")
                                .font(.title3.bold()).foregroundColor(.white)
                                .padding(.horizontal, 28).padding(.vertical, 15)
                                .background(Color.orange).cornerRadius(14)
                                .shadow(radius: 6)
                        }
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 + 92)
                    }
                    if showConsole { consoleOverlay(size: geo.size) }
                }
                .contentShape(Rectangle())
                .gesture(stageGesture(size: geo.size))
                .onReceive(tickTimer) { _ in
                    tco.tick(deltaTime: 1.0 / 60.0, stageWidth: geo.size.width, stageHeight: geo.size.height)
                    cinematics.tick(deltaTime: 1.0 / 60.0, stageWidth: geo.size.width, stageHeight: geo.size.height)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var shakeOffset: CGFloat {
        tco.shakeAmount > 0 ? CGFloat(sin(tco.phase * 72)) * tco.shakeAmount * 0.35 : 0
    }

    private func gridOverlay(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            var path = Path()
            var x: CGFloat = 0
            while x < canvasSize.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: canvasSize.height)); x += 28 }
            var y: CGFloat = 0
            while y < canvasSize.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: canvasSize.width, y: y)); y += 28 }
            context.stroke(path, with: .color(.gray.opacity(0.08)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    // MARK: Toolbar REAL (botones SwiftUI fuera del gesto del lienzo)

    private var toolbar: some View {
        VStack(spacing: 8) {
            toolButton(mode: .cursor)
            toolButton(mode: .pencil)
            toolButton(mode: .eraser)
            Divider().background(Color.white.opacity(0.25)).padding(.horizontal, 6)
            actionToolButton(icon: "trash", label: "Borrar todo") { tco.clearAllStrokes() }
            actionToolButton(icon: "arrow.uturn.backward", label: "Deshacer", disabled: !tco.canUndoStrokes) { tco.undoStrokeAction() }
            Spacer()
            Image(systemName: "paintbrush")
                .font(.system(size: 15))
                .foregroundColor(tco.action == .usingTool ? .orange : .white.opacity(0.3))
                .frame(width: 40, height: 30)
        }
        .padding(.top, 10)
        .frame(width: 60)
        .background(Color(red: 0.25, green: 0.25, blue: 0.28))
    }

    private func toolButton(mode: ToolMode) -> some View {
        let active = tco.toolMode == mode
        return Button {
            tco.toolMode = mode
        } label: {
            VStack(spacing: 2) {
                Image(systemName: mode.icon).font(.system(size: 20))
                Text(mode.label).font(.system(size: 8.5).bold())
            }
            .foregroundColor(active ? .white : .white.opacity(0.75))
            .frame(width: 52, height: 52)
            .background(active ? Color.orange : Color.white.opacity(0.08))
            .cornerRadius(10)
        }
        .accessibilityLabel("Modo \(mode.label)")
    }

    private func actionToolButton(icon: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 19))
                Text(label).font(.system(size: 8.5).bold())
            }
            .foregroundColor(disabled ? .white.opacity(0.3) : .white.opacity(0.9))
            .frame(width: 52, height: 52)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)
        }
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    // MARK: Fila de estado del modo

    private var modeStatusRow: some View {
        HStack(spacing: 6) {
            Image(systemName: tco.toolMode.icon).font(.caption.bold())
            Text(tco.toolMode.hint).font(.caption.bold()).lineLimit(1)
            Spacer()
            if !tco.userStrokes.isEmpty {
                Text("\(tco.userStrokes.count) trazo(s)").font(.caption2).foregroundColor(.white.opacity(0.7))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(tco.toolMode == .cursor ? Color(red: 0.23, green: 0.23, blue: 0.26) : Color.orange.opacity(0.85))
    }

    // Posicion en pantalla (para bocadillos y el agarre) segun superficie
    private func screenPos(of c: StickmanController, size: CGSize) -> CGPoint {
        let groundY = size.height - 10
        switch c.surface {
        case .ceiling: return CGPoint(x: c.x, y: 6)
        case .wallLeft: return CGPoint(x: 30, y: groundY - c.heightAboveGround)
        case .wallRight: return CGPoint(x: size.width - 30, y: groundY - c.heightAboveGround)
        default: return CGPoint(x: c.x, y: groundY - c.platformHeight - c.heightAboveGround)
        }
    }

    @ViewBuilder
    private func bubble(for c: StickmanController, size: CGSize) -> some View {
        let text = c.thought.isEmpty ? c.action.bubbleText : c.thought
        if c.isAlive && !text.isEmpty {
            let pos = screenPos(of: c, size: size)
            let bubbleY = c.surface == .ceiling ? min(size.height - 40, pos.y + 178) : max(28, pos.y - 188)
            Text(text)
                .font(.callout.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 3)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.6), lineWidth: 1))
                .position(x: min(max(pos.x, 84), size.width - 84), y: bubbleY)
        }
    }

    // MARK: Consola falsa de "darle vida"

    private func startConsole() {
        showConsole = true; consoleCount = 0; consoleFinishedWait = 0
    }

    private func typeConsole() {
        guard showConsole else { return }
        if consoleCount < consoleText.count {
            consoleCount += 2
        } else {
            consoleFinishedWait += 0.028
            if consoleFinishedWait > 0.55 {
                showConsole = false
                // El nacimiento pasa por las cinematicas (escena «Nacimiento»)
                cinematics.birthFlow()
            }
        }
    }

    private func consoleOverlay(size: CGSize) -> some View {
        let visible = String(consoleText.prefix(consoleCount))
        return Text(visible + "▌")
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.green)
            .multilineTextAlignment(.leading)
            .frame(width: min(size.width - 32, 360), alignment: .leading)
            .padding(12)
            .background(Color.black.opacity(0.92))
            .cornerRadius(10)
            .position(x: size.width / 2, y: size.height / 2 - 40)
    }

    // MARK: Gesto del lienzo: UN solo gesto, ramificado por modo

    private func worldPoint(_ location: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(x: location.x, y: (size.height - 10) - location.y)
    }

    private func stageGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // Durante una cinematica el lienzo es de la escena
                guard !cinematics.player.isPlaying else { return }
                let world = worldPoint(value.location, size: size)
                switch tco.toolMode {
                case .pencil:
                    if !strokeStarted {
                        strokeStarted = true
                        tco.beginUserStroke(at: world)
                    } else {
                        tco.appendUserStrokePoint(world)
                    }
                case .eraser:
                    tco.eraseAt(world)
                case .cursor:
                    cursorPoint = value.location
                    tco.fingerMoved(toWorldPoint: world)
                    if !dragChecked {
                        dragChecked = true
                        let pos = screenPos(of: tco, size: size)
                        let dx = value.location.x - pos.x
                        let dy = value.location.y - (pos.y - 70)
                        if dx * dx + dy * dy < 92 * 92 && tco.isAlive {
                            isDraggingHim = true
                            tco.beginDrag()
                            cinematics.noteGrab()   // cuenta para el «Duelo con el dedo»
                        }
                    }
                    if isDraggingHim {
                        let groundY = size.height - 10
                        let above = groundY - (value.location.y + 42) - tco.platformHeight
                        tco.drag(to: value.location.x, aboveGround: above)
                    }
                }
            }
            .onEnded { value in
                guard !cinematics.player.isPlaying else { isDraggingHim = false; dragChecked = false; return }
                let world = worldPoint(value.location, size: size)
                switch tco.toolMode {
                case .pencil:
                    tco.appendUserStrokePoint(world); tco.finishUserStroke()
                    cinematics.noteKindStrokeFinished()   // trazo amable terminado
                    strokeStarted = false
                case .eraser:
                    tco.eraseAt(world)
                case .cursor:
                    cursorPoint = value.location
                    if isDraggingHim {
                        let vx = (value.predictedEndTranslation.width - value.translation.width) * 3.2
                        let vy = (value.predictedEndTranslation.height - value.translation.height) * 3.2
                        tco.endDrag(velocity: CGSize(width: vx, height: vy))
                        // Soltarlo de un lanzamiento cuenta como trato brusco
                        if hypot(vx, vy) > 900 { cinematics.noteRoughTouch() }
                    } else if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                        let tapSpeed = hypot(value.predictedEndTranslation.width - value.translation.width,
                                             value.predictedEndTranslation.height - value.translation.height) * 3.2
                        tco.reactToTap(atWorldX: value.location.x, fingerSpeed: tapSpeed)
                    }
                    tco.fingerReleased()
                }
                isDraggingHim = false
                dragChecked = false
            }
    }

    // MARK: Linea de tiempo

    private var timeline: some View {
        HStack(spacing: 2) {
            ForEach(0..<28, id: \.self) { frame in
                Rectangle()
                    .fill(frame == Int(tco.phase * 12) % 28 ? Color.red : (frame % 5 == 0 ? Color.white.opacity(0.55) : Color.white.opacity(0.22)))
                    .frame(height: 18)
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 5)
        .background(Color(red: 0.21, green: 0.21, blue: 0.24))
    }

    // MARK: Barra de sugerencias (botones grandes, tactiles)

    private var suggestionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                suggestionButton("👋 Saludar") { tco.suggest(.waving) }
                suggestionButton("🕺 Bailar") { tco.suggest(.dancing) }
                suggestionButton("⤴️ Saltar") { tco.jump() }
                suggestionButton("⚔️ Espada") { tco.suggest(.sword) }
                suggestionButton("🪑 Sentarse") { tco.suggest(.sitting) }
                suggestionButton("💤 Dormir") { tco.suggestSleep() }
                suggestionButton("⚡ Second Coming") { cinematics.noteAwakenButton() }
                floatingButton
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
        }
        .background(Color(red: 0.23, green: 0.23, blue: 0.26))
    }

    private func suggestionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.bold()).foregroundColor(.white)
                .padding(.horizontal, 15).padding(.vertical, 12)
                .background(tco.isAlive ? Color.orange : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!tco.isAlive)
    }

    // MARK: Boton del modo flotante (v5): saca a TSC en una ventana PiP
    // que flota sobre las demas apps. No depende de que el personaje de
    // la escena principal este "vivo": la ventanita tiene su propio motor.

    private var floatingButton: some View {
        Button(action: {
            pip.toggle()
            // Activar el modo libre (PiP) puede desbloquear su escena
            if pip.isEnabled { cinematics.noteFreeModeUnlocked() }
        }) {
            Text(pip.isFloating ? "🪟 ¡Está flotando!" : "🪟 Modo flotante")
                .font(.callout.bold()).foregroundColor(.white)
                .padding(.horizontal, 15).padding(.vertical, 12)
                .background(pip.isSupported ? (pip.isEnabled ? Color.blue : Color.teal) : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!pip.isSupported)
        .accessibilityLabel("Modo flotante: ventana sobre las demás apps")
    }
}
