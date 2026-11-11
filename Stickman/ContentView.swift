import SwiftUI

// MARK: - Escena: un programa de animacion falso tipo Adobe Animate
// El stickman vive AHI dentro: lienzo, toolbar, timeline y botones son su mundo.

struct ContentView: View {
    @StateObject private var controller = StickmanController()

    @State private var showBrain = false
    @State private var showConsole = false
    @State private var consoleCount = 0
    @State private var consoleFinishedWait = 0.0
    @State private var cursorPoint: CGPoint? = nil
    @State private var draggingStickman = false
    @State private var dragChecked = false

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
            timeline
            suggestionBar
            Text("Toca el lienzo: el dedo es el cursor del animador. Arrástralo agarrándolo para lanzarlo. Las órdenes son sugerencias: tiene su propio cerebro.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
        }
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .onReceive(consoleTimer) { _ in typeConsole() }
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

    // MARK: Panel del cerebro (opcional, sutil)

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
            Text("Ahora: \(controller.microActivity) · Piensa: \(controller.thought.isEmpty ? "—" : controller.thought)")
                .font(.caption2).foregroundColor(.white.opacity(0.75)).lineLimit(1)
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

    // MARK: Escenario principal (toolbar + lienzo)

    private var stage: some View {
        HStack(spacing: 0) {
            toolbar
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // Lienzo blanco con rejilla tenue
                    Rectangle().fill(Color.white)
                    gridOverlay(size: geo.size)
                    StickmanCanvasView(controller: controller)
                        .offset(x: controller.shakeAmount > 0 ? CGFloat(sin(controller.phase * 72)) * controller.shakeAmount * 0.35 : 0)
                    bubble(size: geo.size)
                    if let cursor = cursorPoint {
                        Image(systemName: "cursorarrow")
                            .font(.system(size: 34))
                            .foregroundColor(.black)
                            .shadow(radius: 2)
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
    }

    private var toolbar: some View {
        let tools: [(String, String)] = [
            ("cursorarrow", "Seleccionar"), ("pencil", "Lápiz"), ("paintbrush", "Pincel"),
            ("eraser", "Goma"), ("textformat", "Texto"), ("square", "Rectángulo"), ("circle", "Círculo")
        ]
        return VStack(spacing: 13) {
            ForEach(tools, id: \.0) { tool in
                Image(systemName: tool.0)
                    .font(.system(size: 19))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(controller.action == .usingTool && tool.0 == "paintbrush" ? Color.orange : Color.clear)
                    .cornerRadius(7)
                    .accessibilityLabel(tool.1)
            }
            Spacer()
        }
        .padding(.top, 12)
        .frame(width: 48)
        .background(Color(red: 0.25, green: 0.25, blue: 0.28))
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

    // MARK: Gestos: el dedo es el cursor

    private func stageGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                cursorPoint = value.location
                controller.fingerMoved(to: value.location.x)
                if !dragChecked {
                    dragChecked = true
                    let stickmanY = size.height - 10 - controller.platformHeight - controller.heightAboveGround - 70
                    let dx = value.location.x - controller.x
                    let dy = value.location.y - stickmanY
                    if dx * dx + dy * dy < 85 * 85 && controller.isAlive {
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
            .onEnded { value in
                cursorPoint = value.location
                if draggingStickman {
                    let vx = (value.predictedEndTranslation.width - value.translation.width) * 3.2
                    let vy = (value.predictedEndTranslation.height - value.translation.height) * 3.2
                    controller.endDrag(velocity: CGSize(width: vx, height: vy))
                } else if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                    controller.reactToTap(at: value.location.x)
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
