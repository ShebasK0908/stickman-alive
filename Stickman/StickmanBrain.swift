import Foundation
import SwiftUI

// MARK: - Cerebro complejo del stickman
//
// Arquitectura (ver README):
//   Percepcion  -> lee dedo/cursor, objetos vivos, interfaz, tiempo sin interaccion
//   Impulsos    -> 7 dimensiones que evolucionan y COMPITEN entre si
//   Emocion     -> se deriva de los impulsos + memoria corta
//   Planificador-> construye planes multi-paso (cola de pasos)
//   Descanso    -> ciclo obligatorio: 120 s de actividad -> 15-20 s de descanso
// El controlador (StickmanEngine) ejecuta el plan paso a paso con la fisica.

// MARK: Percepcion

struct Perception {
    var fingerX: CGFloat? = nil          // Donde esta el dedo/cursor, si esta tocando
    var fingerIsClose: Bool = false
    var timeSinceLastInteraction: Double = 0
    var aliveObjectKinds: [DrawnObjectKind] = []
    var reachableUI: [String] = ["toolbar", "timeline", "botones", "lienzo"]
    var stickmanX: CGFloat = 0
    var stageWidth: CGFloat = 390
}

// MARK: Impulsos

struct Drives {
    var energy: Double = 82        // 0...100, baja con la actividad, se recupera descansando
    var curiosity: Double = 55     // ganas de explorar la interfaz
    var playfulness: Double = 60   // ganas de jugar
    var mischief: Double = 35      // travesura: sube si se aburre o le molestan
    var sociability: Double = 55   // ganas de saludar / tener un amigo
    var boredom: Double = 10       // sube si no pasa nada
    var anger: Double = 0          // sube si le tocan mucho / le lanzan

    mutating func evolve(dt: Double, resting: Bool, interacting: Bool) {
        let r = dt / 60.0 // ritmo por minuto, suave
        if resting {
            energy = min(100, energy + dt * 2.2)
            anger = max(0, anger - dt * 1.5)
            boredom = max(0, boredom - dt * 1.0)
        } else {
            energy = max(5, energy - r * 3.5)
            boredom = min(100, boredom + (interacting ? -r * 18 : r * 9))
            curiosity = min(100, curiosity + r * 2.0)
            anger = max(0, anger - r * 6)
        }
        if interacting { boredom = max(0, boredom - dt * 0.8) }
        playfulness = min(100, max(10, playfulness + (interacting ? r * 4 : -r * 1)))
        sociability = min(100, max(10, sociability + r * 1.2))
        mischief = min(100, max(0, mischief + (boredom > 65 ? r * 5 : -r * 1.5)))
    }

    mutating func registerAnnoyance() { anger = min(100, anger + 16); mischief = min(100, mischief + 6) }
    mutating func registerKindPlay() { sociability = min(100, sociability + 7); playfulness = min(100, playfulness + 6); anger = max(0, anger - 5) }
}

// MARK: Emocion derivada

enum Emotion: String {
    case furioso = "Furioso"
    case enfadado = "Enfadado"
    case dormido = "Con sueño"
    case aburrido = "Aburrido"
    case travieso = "Travieso"
    case curioso = "Curioso"
    case contento = "Contento"
    case tranquilo = "Tranquilo"

    static func derive(from d: Drives, resting: Bool) -> Emotion {
        if resting || d.energy < 18 { return .dormido }
        if d.anger > 72 { return .furioso }
        if d.anger > 45 { return .enfadado }
        if d.boredom > 70 { return .aburrido }
        if d.mischief > 62 { return .travieso }
        if d.curiosity > 68 { return .curioso }
        if d.playfulness > 62 || d.sociability > 68 { return .contento }
        return .tranquilo
    }
}

// MARK: Memoria corta

struct ShortMemory {
    var annoyances: Int = 0      // veces que le han molestado hace poco
    var kindPlays: Int = 0       // veces que han jugado bien hace poco
    private var decayTimer: Double = 0

    mutating func tick(dt: Double) {
        decayTimer += dt
        if decayTimer > 20 { // cada 20 s olvida un poco
            decayTimer = 0
            if annoyances > 0 { annoyances -= 1 }
            if kindPlays > 0 { kindPlays -= 1 }
        }
    }
}

// MARK: Planes multi-paso

struct PlanStep {
    var action: StickmanAction
    var duration: Double
    var thought: String = ""
    var objectToDraw: DrawnObjectKind? = nil
    var power: Power? = nil
    var targetPlatform: CGFloat = -1  // -1 = suelo; si no, altura de plataforma destino
}

struct Plan {
    var name: String
    var steps: [PlanStep]
    var currentIndex: Int = 0
    var stepTimer: Double = 0

    var currentStep: PlanStep? { steps.indices.contains(currentIndex) ? steps[currentIndex] : nil }
    var isFinished: Bool { currentIndex >= steps.count }
    mutating func advance() { currentIndex += 1; stepTimer = 0 }
}

enum PlanLibrary {
    static func buildCorner() -> Plan {
        Plan(name: "Construir mi rincón", steps: [
            PlanStep(action: .drawingObject, duration: 1.2, thought: "voy a hacerme un rincón", objectToDraw: .chair),
            PlanStep(action: .drawingObject, duration: 1.2, thought: "", objectToDraw: .table),
            PlanStep(action: .walking, duration: 1.4, thought: ""),
            PlanStep(action: .sitting, duration: 4.0, thought: "así, cómodo")
        ])
    }
    static func exploreUI() -> Plan {
        Plan(name: "Explorar la interfaz", steps: [
            PlanStep(action: .walking, duration: 1.6, thought: "¿qué hay por allí?"),
            PlanStep(action: .climbing, duration: 2.2, thought: "¡subo a la línea de tiempo!", targetPlatform: 46),
            PlanStep(action: .usingTool, duration: 2.4, thought: "esta herramienta es mía ahora"),
            PlanStep(action: .walking, duration: 1.4, thought: "", targetPlatform: 0),
            PlanStep(action: .climbing, duration: 2.0, thought: "y ahora... ¡a los botones!", targetPlatform: 104),
            PlanStep(action: .proud, duration: 1.8, thought: "estoy encima de la interfaz 😎")
        ])
    }
    static func playBall() -> Plan {
        Plan(name: "Jugar con mi pelota", steps: [
            PlanStep(action: .drawingObject, duration: 1.1, thought: "me dibujo una pelota", objectToDraw: .ball),
            PlanStep(action: .playingBall, duration: 5.0, thought: "¡a jugar solo!")
        ])
    }
    static func drawFriend() -> Plan {
        Plan(name: "Dibujar un amigo", steps: [
            PlanStep(action: .drawingObject, duration: 1.6, thought: "quiero un amigo", objectToDraw: .friend),
            PlanStep(action: .withFriend, duration: 4.5, thought: "¡hola, amigo!")
        ])
    }
    static func buildHouse() -> Plan {
        Plan(name: "Mi puertita", steps: [
            PlanStep(action: .drawingObject, duration: 1.5, thought: "una puertita para mí", objectToDraw: .doorHouse),
            PlanStep(action: .proud, duration: 2.0, thought: "mi casa"),
            PlanStep(action: .walking, duration: 1.2, thought: "")
        ])
    }
    static func trainChosenOne() -> Plan {
        Plan(name: "Entrenar como Chosen One", steps: [
            PlanStep(action: .powerPose, duration: 1.4, thought: "modo Chosen One...", power: nil),
            PlanStep(action: .flying, duration: 3.0, thought: "¡a volar!", power: .flight),
            PlanStep(action: .usingPower, duration: 2.0, thought: "¡láser!", power: .eyeLaser),
            PlanStep(action: .usingPower, duration: 2.0, thought: "¡fuego!", power: .fireBreath),
            PlanStep(action: .proud, duration: 2.0, thought: "aterrizo orgulloso")
        ])
    }
    static func showOffPowers() -> Plan {
        Plan(name: "Lucirse con poderes", steps: [
            PlanStep(action: .powerPose, duration: 1.2, thought: "mirad esto...", power: nil),
            PlanStep(action: .usingPower, duration: 1.8, thought: "¡superpuñetazo!", power: .superPunch),
            PlanStep(action: .running, duration: 2.2, thought: "¡supervelocidad!", power: .superSpeed),
            PlanStep(action: .usingPower, duration: 2.2, thought: "¡qué fuerte soy!", power: .superStrength),
            PlanStep(action: .proud, duration: 1.8, thought: "sí, soy yo")
        ])
    }
    static func wander() -> Plan {
        Plan(name: "Deambular", steps: [
            PlanStep(action: .walking, duration: Double.random(in: 2.0...3.6), thought: ""),
            PlanStep(action: .idle, duration: 1.6, thought: ""),
            PlanStep(action: .walking, duration: Double.random(in: 1.6...3.0), thought: "")
        ])
    }
    static func boredRoutine() -> Plan {
        Plan(name: "Rutina de aburrimiento", steps: [
            PlanStep(action: .yawning, duration: 1.6, thought: "qué aburrimiento..."),
            PlanStep(action: .drawingObject, duration: 1.1, thought: "", objectToDraw: .chair),
            PlanStep(action: .sitting, duration: 4.0, thought: "me siento un rato")
        ])
    }
    static func happyRoutine() -> Plan {
        Plan(name: "Está contento", steps: [
            PlanStep(action: .waving, duration: 2.0, thought: "¡hola!"),
            PlanStep(action: .dancing, duration: 3.4, thought: "♪ a bailar ♪")
        ])
    }

    /// Elige un plan pesando los impulsos que compiten + la memoria corta.
    static func choosePlan(drives: Drives, memory: ShortMemory, perception: Perception) -> Plan {
        var candidates: [(weight: Double, plan: Plan)] = []
        candidates.append((weight: 18 + drives.curiosity * 0.5, plan: exploreUI()))
        candidates.append((weight: 14 + drives.playfulness * 0.5, plan: playBall()))
        candidates.append((weight: 10 + drives.sociability * 0.55 + Double(memory.kindPlays) * 4, plan: drawFriend()))
        candidates.append((weight: 12, plan: buildCorner()))
        candidates.append((weight: 9, plan: buildHouse()))
        candidates.append((weight: 10 + drives.curiosity * 0.3, plan: wander()))
        if drives.boredom > 55 { candidates.append((weight: 26, plan: boredRoutine())) }
        if drives.playfulness > 58 || drives.sociability > 62 { candidates.append((weight: 22, plan: happyRoutine())) }
        // Poderes: travesura / enfado / memoria de molestias -> Chosen One
        let powerWeight = drives.mischief * 0.45 + drives.anger * 0.6 + Double(memory.annoyances) * 7
        if powerWeight > 24 {
            candidates.append((weight: powerWeight, plan: Bool.random() ? trainChosenOne() : showOffPowers()))
        }
        let total = candidates.reduce(0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<max(total, 1))
        for c in candidates { roll -= c.weight; if roll <= 0 { return c.plan } }
        return wander()
    }
}
