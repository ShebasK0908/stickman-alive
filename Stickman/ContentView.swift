import SwiftUI

// MARK: - Escena: un programa de animacion falso tipo Adobe Animate
// El stickman vive AHI dentro: lienzo, toolbar, timeline y botones son su mundo.
//
// v2 — POR QUE LA TOOLBAR DE LA v1 NO RESPONDIA (diagnostico):
//  1) Era un VStack de Image(systemName:) SIN botones: puro dibujo.
//  2) El lienzo llevaba un DragGesture(minimumDistance: 0) que lo
//     interpretaba TODO como cursor/arrastre, y no existia ningun modo
//     lapiz/goma ni trazos en el modelo.
// SOLUCION v2: la toolbar es una columna de Buttons REALES, en un HStack
// HERMANO del lienzo (fuera del GeometryReader y de su gesto), cada uno
// de >=52 pt. El unico gesto es el del lienzo, y se RAMIFICA por el modo
// activo: cursor = agarrar/tocar, lapiz = trazo, goma = borrar. Nunca
// hay dos gestos compitiendo y el stickman no puede robar toques de la
// toolbar porque Canvas tiene allowsHitTesting(false) y la toolbar esta
// fisicamente fuera del area del gesto.

struct ContentView: View {
    @StateObject private var controller = StickmanController()

    @State private var showBrain = false
    @State private var showConsole = false
    @State private var consoleCount = 0
    @State private var consoleFinishedWait = 0.0
    @State private var cursorPoint: CGPoint? = nil
    @State private var draggingStickman = false
    @State private var dragChecked = false
    @State private var strokeStarted = false

    private let tickTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let consoleTimer = Timer.publish(every: 0.028, on: .main, in: .common).autoconnect()

    private let consoleText = """
    $ python3 bring_to_life.py
    import stickman
    stickman = dibujar(color = "naranja")
    stickman.awake()   # esto es broma, como en el video ;)
    > DESPERTANDO...
    """

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if showBrain { brainPanel }
            stage
            modeStatusRow
            timeline
            suggestionBar
            Text("Las órdenes son sugerencias: tiene su propio cerebro e IA para defenderse de tu dedo.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
        }
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .onReceive(consoleTimer) { _ in typeConsole() }
        .onChange(of: controller.dragEscapeSignal) { _ in
            // El stickman se ha escapado del agarre: soltamos el gesto local
            draggingStickman = false
            dragChecked = false
        }
    }

    // MARK: Barra superior

    private var topBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 11, height: 11)
            Circle().fill(Color.yellow).frame(width: 11, height: 11)
            Circle().fill(Color.green).frame(width: 11, height: 11)
            Text("Animate — stickman_vivo.fla")
                .font(.subheadline.bold()).foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            if controller.isChosenOne {
                Text("⚡ CHOSEN ONE")
                    .font(.caption.bold()).foregroundColor(.black)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.yellow).cornerRadius(6)
            }
            Text(controller.isAlive ? controller.emotion.rawValue : "Sin vida")
                .font(.caption).foregroundColor(.white.opacity(0.85))
            Button(showBrain ? "🧠▲" : "🧠") { showBrain.toggle() }
                .font(.headline)
                .accessibilityLabel("Ver su cerebro")
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color(red: 0.23, green: 0.23, blue: 0.26))
    }

    // MARK: Panel del cerebro + IA tactil

    private var brainPanel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("🧠 Su cerebro").font(.caption.bold()).foregroundColor(.white)
                Spacer()
                if controller.isResting {
                    Text("Descansando: \(Int(controller.restSecondsLeft)) s").font(.caption).foregroundColor(.cyan)
                } else {
                    Text("Descanso en \(Int(controller.secondsUntilRest)) s · Plan: \(controller.currentPlanName)")
                        .font(.caption).foregroundColor(.white.opacity(0.85)).lineLimit(1)
                }
            }
            driveRow("Energía", controller.drives.energy, .green)
            driveRow("Curiosidad", controller.drives.curiosity, .blue)
            driveRow("Ganas de jugar", controller.drives.playfulness, .pink)
            driveRow("Travesura", controller.drives.mischief, .purple)
            driveRow("Sociabilidad", controller.drives.sociability, .orange)
            driveRow("Aburrimiento", controller.drives.boredom, .gray)
            driveRow("Enfado", controller.drives.anger, .red)
            driveRow("Acoso (IA)", controller.harassmentLevel, .pink)
            Text("IA: \(controller.lastDecision) · Velocidad: \(Int(controller.moveSpeed)) pt/s · Ahora: \(controller.microActivity) · Piensa: \(controller.thought.isEmpty ? "—" : controller.thought)")
                .font(.caption2).foregroundColor(.white.opacity(0.75)).lineLimit(2)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(red: 0.20, green: 0.20, blue: 0.23))
    }

    private func driveRow(_ label: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.8)).frame(width: 92, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * CGFloat(min(100, max(0, value))) / 100)
                }
            }
            .frame(height: 7)
            Text("\(Int(value))").font(.caption2).foregroundColor(.white.opacity(0.8)).frame(width: 24, alignment: .trailing)
        }
    }

    // MARK: Escenario principal (toolbar REAL + lienzo)

    private var stage: some View {
        HStack(spacing: 0) {
            toolbar
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.white)
                    gridOverlay(size: geo.size)
                    StickmanCanvasView(controller: controller)
                        .offset(x: controller.shakeAmount > 0 ? CGFloat(sin(controller.phase * 72)) * controller.shakeAmount * 0.35 : 0)
                    bubble(size: geo.size)
                    if let cursor = cursorPoint, controller.toolMode == .cursor {
                        Image(systemName: "cursorarrow")
                            .font(.system(size: 34))
                            .foregroundColor(.black)
                            .shadow(radius: 2)
                            .rotationEffect(.degrees(controller.isGrabbingFinger ? sin(controller.phase * 18) * 14 : 0))
                            .position(x: cursor.x, y: cursor.y)
                    }
                    if !controller.isAlive && !showConsole {
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
                    controller.tick(deltaTime: 1.0 / 60.0, stageWidth: geo.size.width)
                }
            }
        }
        .frame(maxHeight: .infinity)
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
            actionToolButton(icon: "trash", label: "Borrar todo") { controller.clearAllStrokes() }
            actionToolButton(icon: "arrow.uturn.backward", label: "Deshacer", disabled: !controller.canUndoStrokes) { controller.undoStrokeAction() }
            Spacer()
            // Indicador decorativo de la herramienta que EL ha robado alguna vez (sin hit-testing)
            Image(systemName: "paintbrush")
                .font(.system(size: 15))
                .foregroundColor(controller.action == .usingTool ? .orange : .white.opacity(0.3))
                .frame(width: 40, height: 30)
        }
        .padding(.top, 10)
        .frame(width: 60)
        .background(Color(red: 0.25, green: 0.25, blue: 0.28))
    }

    private func toolButton(mode: ToolMode) -> some View {
        let active = controller.toolMode == mode
        return Button {
            controller.toolMode = mode
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

    // MARK: Fila de estado del modo (feedback visible de que el boton funciono)

    private var modeStatusRow: some View {
        HStack(spacing: 6) {
            Image(systemName: controller.toolMode.icon).font(.caption.bold())
            Text(controller.toolMode.hint).font(.caption.bold()).lineLimit(1)
            Spacer()
            if !controller.userStrokes.isEmpty {
                Text("\(controller.userStrokes.count) trazo(s)").font(.caption2).foregroundColor(.white.opacity(0.7))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(controller.toolMode == .cursor ? Color(red: 0.23, green: 0.23, blue: 0.26) : Color.orange.opacity(0.85))
    }

    @ViewBuilder
    private func bubble(size: CGSize) -> some View {
        let text = controller.thought.isEmpty ? controller.action.bubbleText : controller.thought
        if controller.isAlive && !text.isEmpty {
            Text(text)
                .font(.callout.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 3)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.6), lineWidth: 1))
                .position(
                    x: min(max(controller.x, 84), size.width - 84),
                    y: max(28, size.height - 10 - controller.platformHeight - controller.heightAboveGround - 188)
                )
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
                controller.bringToLife()
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
                let world = worldPoint(value.location, size: size)
                switch controller.toolMode {
                case .pencil:
                    if !strokeStarted {
                        strokeStarted = true
                        controller.beginUserStroke(at: world)
                    } else {
                        controller.appendUserStrokePoint(world)
                    }
                case .eraser:
                    controller.eraseAt(world)
                case .cursor:
                    cursorPoint = value.location
                    controller.fingerMoved(toWorldPoint: world)
                    if !dragChecked {
                        dragChecked = true
                        let stickmanY = size.height - 10 - controller.platformHeight - controller.heightAboveGround - 70
                        let dx = value.location.x - controller.x
                        let dy = value.location.y - stickmanY
                        if dx * dx + dy * dy < 92 * 92 && controller.isAlive {
                            draggingStickman = true
                            controller.beginDrag()
                        }
                    }
                    if draggingStickman {
                        let groundY = size.height - 10
                        let above = groundY - (value.location.y + 42) - controller.platformHeight
                        controller.drag(to: value.location.x, aboveGround: above)
                    }
                }
            }
            .onEnded { value in
                let world = worldPoint(value.location, size: size)
                switch controller.toolMode {
                case .pencil:
                    controller.appendUserStrokePoint(world)
                    controller.finishUserStroke()
                    strokeStarted = false
                case .eraser:
                    controller.eraseAt(world)
                case .cursor:
                    cursorPoint = value.location
                    if draggingStickman {
                        let vx = (value.predictedEndTranslation.width - value.translation.width) * 3.2
                        let vy = (value.predictedEndTranslation.height - value.translation.height) * 3.2
                        controller.endDrag(velocity: CGSize(width: vx, height: vy))
                    } else if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                        let tapSpeed = hypot(value.predictedEndTranslation.width - value.translation.width,
                                             value.predictedEndTranslation.height - value.translation.height) * 3.2
                        controller.reactToTap(atWorldX: value.location.x, fingerSpeed: tapSpeed)
                    }
                    controller.fingerReleased()
                }
                draggingStickman = false
                dragChecked = false
            }
    }

    // MARK: Linea de tiempo

    private var timeline: some View {
        HStack(spacing: 2) {
            ForEach(0..<28, id: \.self) { frame in
                Rectangle()
                    .fill(frame == Int(controller.phase * 12) % 28 ? Color.red : (frame % 5 == 0 ? Color.white.opacity(0.55) : Color.white.opacity(0.22)))
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
                suggestionButton("👋 Saludar") { controller.suggest(.waving) }
                suggestionButton("🕺 Bailar") { controller.suggest(.dancing) }
                suggestionButton("⤴️ Saltar") { controller.jump() }
                suggestionButton("⚔️ Espada") { controller.suggest(.sword) }
                suggestionButton("🪑 Sentarse") { controller.suggest(.sitting) }
                suggestionButton("💤 Dormir") { controller.suggestSleep() }
                suggestionButton("⚡ Chosen One") { controller.suggestChosenOne() }
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
                .background(controller.isAlive ? Color.orange : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!controller.isAlive)
    }
}
