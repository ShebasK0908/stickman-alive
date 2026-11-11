import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget de pantalla de inicio — v5
//
// The Chosen One vive en la pantalla de inicio. Dibujo 100% procedural
// con SwiftUI Canvas (mismas proporciones y cabeza llena que en la app:
// cadera a 56, cuello a -42, cabeza a -23, cabeza solida de 40).
//
// Las poses ROTAN por la timeline (de pie, caminando, sentado,
// durmiendo, pose de poder) y los botones (iOS 17+, App Intents)
// eligen la pose que manda al principio: Saludar / Correr / Fuego.
//
// SIN App Groups a proposito (no romper la instalacion con SideStore):
// el estado se guarda en el UserDefaults PROPIO de la extension, que
// es lo unico que el widget necesita — el widget no comparte estado
// con la app. Al tocar el cuerpo del widget se abre la app.

// MARK: Poses del widget

enum WidgetPoseKind: String, CaseIterable {
    case standing, walking, sitting, sleeping, power, wave, running, fire

    var caption: String {
        switch self {
        case .standing: return "De pie, vigilando"
        case .walking: return "De paseo por tu pantalla"
        case .sitting: return "Sentado en el borde"
        case .sleeping: return "Durmiendo... no molestar"
        case .power: return "¡Modo Chosen One!"
        case .wave: return "¡Hola, animador!"
        case .running: return "¡A correr!"
        case .fire: return "¡Fuego!"
        }
    }
}

/// Pose del esqueleto con las mismas proporciones que SkeletonPose
/// de la app (offsets respecto a cadera/cuello, y hacia abajo).
private struct WPose {
    var hipHeight: CGFloat = 56
    var hipDX: CGFloat = 0
    var neckOff = CGPoint(x: 0, y: -42)
    var headOff = CGPoint(x: 0, y: -23)
    var elbowL = CGPoint(x: -17, y: 19)
    var handL = CGPoint(x: -20, y: 40)
    var elbowR = CGPoint(x: 17, y: 19)
    var handR = CGPoint(x: 20, y: 40)
    var kneeL = CGPoint(x: -11, y: 27)
    var footL = CGPoint(x: -13, y: 56)
    var kneeR = CGPoint(x: 11, y: 27)
    var footR = CGPoint(x: 13, y: 56)
    var squash: CGFloat = 1
}

private func widgetPose(_ kind: WidgetPoseKind, phase t: Double) -> WPose {
    var p = WPose()
    switch kind {
    case .standing:
        p.hipHeight = 56 + CGFloat(sin(t * 1.7)) * 1.3 // respira
        p.handL.y += CGFloat(sin(t * 1.7)) * 1.6
        p.handR.y += CGFloat(sin(t * 1.7 + 0.6)) * 1.6
    case .walking, .running:
        let run = kind == .running
        let s = CGFloat(sin(t * (run ? 8.4 : 5.4)))
        let stride: CGFloat = run ? 24 : 18
        p.footL = CGPoint(x: s * stride, y: 56 - max(0, s) * (run ? 12 : 9))
        p.footR = CGPoint(x: -s * stride, y: 56 - max(0, -s) * (run ? 12 : 9))
        p.kneeL = CGPoint(x: s * stride * 0.5, y: 27 - max(0, s) * 5)
        p.kneeR = CGPoint(x: -s * stride * 0.5, y: 27 - max(0, -s) * 5)
        p.handL = CGPoint(x: -20 + s * 11, y: run ? 34 : 40)
        p.handR = CGPoint(x: 20 - s * 11, y: run ? 34 : 40)
        p.hipHeight = (run ? 53 : 54) + abs(CGFloat(cos(t * (run ? 8.4 : 5.4)))) * 2
        if run { p.neckOff = CGPoint(x: 7, y: -41); p.headOff = CGPoint(x: 3, y: -23) }
    case .sitting:
        // La pose "sentado" de la app, tal cual
        p.hipHeight = 26
        p.neckOff = CGPoint(x: 0, y: -34)
        p.kneeL = CGPoint(x: -16, y: 6); p.footL = CGPoint(x: -16, y: 26)
        p.kneeR = CGPoint(x: 16, y: 6); p.footR = CGPoint(x: 16, y: 26)
        p.handL = CGPoint(x: -10, y: 24); p.handR = CGPoint(x: 10, y: 24)
    case .sleeping:
        // La pose "dormir" de la app: tumbado de lado, respira lento
        p.hipHeight = 11 + CGFloat(sin(t * 1.8)) * 0.7
        p.neckOff = CGPoint(x: -32, y: -3)
        p.headOff = CGPoint(x: -19, y: -2)
        p.footL = CGPoint(x: 44, y: 9); p.kneeL = CGPoint(x: 22, y: 5)
        p.footR = CGPoint(x: 42, y: 3); p.kneeR = CGPoint(x: 20, y: 1)
        p.handL = CGPoint(x: -10, y: 8); p.handR = CGPoint(x: -16, y: 6)
    case .power:
        p.hipHeight = 58
        p.neckOff = CGPoint(x: -2, y: -44)
        p.headOff = CGPoint(x: 0, y: -24)
        p.elbowL = CGPoint(x: -24, y: 4); p.handL = CGPoint(x: -31, y: -17)
        p.elbowR = CGPoint(x: 24, y: 4); p.handR = CGPoint(x: 31, y: -17)
        p.kneeL = CGPoint(x: -13, y: 28); p.footL = CGPoint(x: -16, y: 58)
        p.kneeR = CGPoint(x: 13, y: 28); p.footR = CGPoint(x: 16, y: 58)
        p.squash = 1.03
    case .wave:
        p.hipHeight = 56 + CGFloat(sin(t * 1.7)) * 1.0
        p.elbowR = CGPoint(x: 20, y: -8)
        p.handR = CGPoint(x: 27 + CGFloat(sin(t * 7)) * 6, y: -28)
    case .fire:
        p.hipHeight = 55
        p.neckOff = CGPoint(x: 4, y: -40)
        p.elbowR = CGPoint(x: 24, y: 10)
        p.handR = CGPoint(x: 41, y: 16)
        p.elbowL = CGPoint(x: -18, y: 16)
        p.handL = CGPoint(x: -24, y: 34)
    }
    return p
}

// MARK: Dibujo (Canvas)

private struct StickmanCanvas: View {
    let kind: WidgetPoseKind
    let phase: Double

    var body: some View {
        Canvas { ctx, size in
            let scale: CGFloat = min(size.width, size.height) / 150
            ctx.translateBy(x: size.width / 2, y: size.height - 4)
            ctx.scaleBy(x: scale, y: scale)

            let pose = widgetPose(kind, phase: phase)
            let f: CGFloat = 1
            func fromHip(_ p: CGPoint, hip: CGPoint) -> CGPoint { CGPoint(x: hip.x + p.x * f, y: hip.y + p.y) }
            func fromNeck(_ p: CGPoint, neck: CGPoint) -> CGPoint { CGPoint(x: neck.x + p.x * f, y: neck.y + p.y) }
            let hip = CGPoint(x: pose.hipDX * f, y: -pose.hipHeight)
            let neck = fromHip(pose.neckOff, hip: hip)
            let head = fromNeck(pose.headOff, neck: neck)
            let elbowL = fromNeck(pose.elbowL, neck: neck), handL = fromNeck(pose.handL, neck: neck)
            let elbowR = fromNeck(pose.elbowR, neck: neck), handR = fromNeck(pose.handR, neck: neck)
            let kneeL = fromHip(pose.kneeL, hip: hip), footL = fromHip(pose.footL, hip: hip)
            let kneeR = fromHip(pose.kneeR, hip: hip), footR = fromHip(pose.footR, hip: hip)

            // Suelo
            var floor = Path()
            floor.move(to: CGPoint(x: -size.width / scale / 2 + 4, y: 0))
            floor.addLine(to: CGPoint(x: size.width / scale / 2 - 4, y: 0))
            ctx.stroke(floor, with: .color(.gray.opacity(0.5)), lineWidth: 2.5 / scale * 1.6)

            // Aura del modo poder / fuego
            if kind == .power || kind == .fire {
                var aura = ctx
                aura.opacity = 0.18
                aura.fill(Path(ellipseIn: CGRect(x: -58, y: -168, width: 116, height: 168)), with: .color(.yellow))
            }
            // Llama del boton Fuego
            if kind == .fire {
                let flicker = CGFloat(sin(phase * 22)) * 7
                var flame = Path()
                flame.move(to: handR)
                flame.addLine(to: CGPoint(x: handR.x + 62 + flicker, y: handR.y - 13))
                flame.addLine(to: CGPoint(x: handR.x + 48, y: handR.y + 14))
                flame.closeSubpath()
                var fctx = ctx
                fctx.opacity = 0.85
                fctx.fill(flame, with: .color(.orange))
            }

            let ink = Color(red: 0.07, green: 0.07, blue: 0.07)
            var body = Path()
            body.move(to: hip); body.addLine(to: neck)
            body.move(to: hip); body.addLine(to: kneeL); body.addLine(to: footL)
            body.move(to: hip); body.addLine(to: kneeR); body.addLine(to: footR)
            body.move(to: neck); body.addLine(to: elbowL); body.addLine(to: handL)
            body.move(to: neck); body.addLine(to: elbowR); body.addLine(to: handR)
            ctx.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round))

            // Cabeza llena, como en la app
            let headH = 40 * pose.squash
            let headW = 40 * (1 + (1 - pose.squash) * 0.55)
            ctx.fill(Path(ellipseIn: CGRect(x: head.x - headW / 2, y: head.y - headH / 2, width: headW, height: headH)),
                     with: .color(ink))
        }
    }
}

// MARK: Timeline

struct StickmanEntry: TimelineEntry {
    let date: Date
    let pose: WidgetPoseKind
}

struct StickmanProvider: TimelineProvider {
    private static let poseKey = "stickman.widget.pose"

    static func selectedPose() -> WidgetPoseKind {
        WidgetPoseKind(rawValue: UserDefaults.standard.string(forKey: poseKey) ?? "") ?? .standing
    }

    static func saveSelectedPose(_ kind: WidgetPoseKind) {
        UserDefaults.standard.set(kind.rawValue, forKey: poseKey)
    }

    func placeholder(in context: Context) -> StickmanEntry {
        StickmanEntry(date: Date(), pose: .standing)
    }

    func getSnapshot(in context: Context, completion: @escaping (StickmanEntry) -> Void) {
        completion(StickmanEntry(date: Date(), pose: Self.selectedPose()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StickmanEntry>) -> Void) {
        // La pose elegida con los botones manda primero; despues la
        // rotacion de siempre: de pie, caminando, sentado, durmiendo, poder.
        let rotation: [WidgetPoseKind] = [.standing, .walking, .sitting, .sleeping, .power]
        let now = Date()
        var entries = [StickmanEntry(date: now, pose: Self.selectedPose())]
        for i in 1...5 {
            let date = Calendar.current.date(byAdding: .minute, value: i * 8, to: now) ?? now
            entries.append(StickmanEntry(date: date, pose: rotation[i % rotation.count]))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: Botones (App Intents, iOS 17+)

enum PoseOption: String, AppEnum {
    case wave, run, fire

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Pose" }
    static var caseDisplayRepresentations: [PoseOption: DisplayRepresentation] {
        [.wave: "Saludar", .run: "Correr", .fire: "Fuego"]
    }

    var widgetPose: WidgetPoseKind {
        switch self {
        case .wave: return .wave
        case .run: return .running
        case .fire: return .fire
        }
    }
}

struct SetPoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Cambiar la pose de The Chosen One"

    @Parameter(title: "Pose") var pose: PoseOption

    init() {}
    init(pose: PoseOption) { self.pose = pose }

    func perform() async throws -> some IntentResult {
        StickmanProvider.saveSelectedPose(pose.widgetPose)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: Vista del widget

struct StickmanWidgetEntryView: View {
    var entry: StickmanEntry
    @Environment(\.widgetFamily) private var family

    private var phase: Double { entry.date.timeIntervalSinceReferenceDate }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                StickmanCanvas(kind: entry.pose, phase: phase)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if family == .systemMedium {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("The Chosen One")
                            .font(.headline)
                            .lineLimit(1)
                        Text(entry.pose.caption)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        Text("Toca para abrir la app")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: 128, alignment: .leading)
                }
            }
            if family == .systemMedium {
                HStack(spacing: 8) {
                    poseButton(.wave, "👋 Saludar")
                    poseButton(.run, "🏃 Correr")
                    poseButton(.fire, "🔥 Fuego")
                }
            }
        }
        .padding(10)
        .containerBackground(Color(white: 0.97), for: .widget)
    }

    private func poseButton(_ option: PoseOption, _ label: String) -> some View {
        Button(intent: SetPoseIntent(pose: option)) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Widget

struct StickmanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StickmanWidget", provider: StickmanProvider()) { entry in
            StickmanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("The Chosen One")
        .description("Tu stickman vive en la pantalla de inicio: rota de poses y responde a los botones.")
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}

@main
struct StickmanWidgetBundle: WidgetBundle {
    var body: some Widget {
        StickmanWidget()
    }
}
