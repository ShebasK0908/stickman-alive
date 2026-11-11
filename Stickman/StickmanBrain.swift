import Foundation
import SwiftUI

// MARK: - Cerebro complejo del stickman
//
// Arquitectura (ver README):
//   Percepcion  -> lee dedo/cursor (posicion, velocidad, acercamiento),
//                  objetos vivos, interfaz, tiempo sin interaccion
//   Impulsos    -> 7 dimensiones que evolucionan y COMPITEN entre si
//   Emocion     -> se deriva de los impulsos + memoria corta
//   IA tactil   -> percibe -> decide -> anima: curiosidad, saludo, huida,
//                  esquiva, bloqueo, agarrar el dedo, contraataque,
//                  esconderse, usar objetos como escudo/arma
//   Planificador-> construye planes multi-paso (cola de pasos)
//   Descanso    -> ciclo obligatorio: 120 s de actividad -> 15-20 s de descanso
// El controlador (StickmanEngine) ejecuta todo esto con el motor de
// locomocion y los clips de StickmanAnimation.

// MARK: Herramientas del usuario (toolbar real de la v2)

enum ToolMode: String, CaseIterable {
    case cursor, pencil, eraser
    var label: String {
        switch self {
        case .cursor: return "Cursor"
        case .pencil: return "Lápiz"
        case .eraser: return "Goma"
        }
    }
    var icon: String {
        switch self {
        case .cursor: return "cursorarrow"
        case .pencil: return "pencil"
        case .eraser: return "eraser"
        }
    }
    var hint: String {
        switch self {
        case .cursor: return "Modo: Cursor — agarra al stickman, arrástralo o tócalo"
        case .pencil: return "Modo: Lápiz — dibuja con el dedo en el lienzo"
        case .eraser: return "Modo: Goma — arrastra sobre trazos u objetos para borrarlos"
        }
    }
}

/// Un trazo libre dibujado por el USUARIO con el lapiz.
/// Puntos en coordenadas de mundo: x = horizontal, y = altura sobre el suelo.
struct UserStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
}

// MARK: Personaje (SOLO uno: The Second Coming)

/// v4: la app es de UN solo personaje, The Second Coming, por decision del
/// usuario. Se mantiene el tipo como identidad (color, trazo, arranque e
/// impulsos iniciales de su personalidad: poderoso y desafiante,
/// travesura y energia altas; se enfada y se luce).
enum CharacterKind {
    case secondComing

    var displayName: String { "The Second Coming" }
    var shortName: String { "TSC" }
    /// Color del trazo: naranja (241,129,12), como TSC en los videos (AvA 4).
    var colorRGB: (r: Double, g: Double, b: Double) { (0.945, 0.506, 0.047) }
    var startX: CGFloat { 190 }
    var lineWidth: CGFloat { 10.0 }

    var initialDrives: Drives {
        Drives(energy: 92, curiosity: 58, playfulness: 58, mischief: 56, sociability: 50, boredom: 8, anger: 5)
    }
}

// MARK: Superficies navegables (roaming 360° estilo Shimeji)

/// Superficie a la que el personaje esta ANCLADO. El motor de
/// superficies manda: la gravedad y la pose dependen de ella.
/// - floor: suelo, plataformas falsas (timeline/botones) y trazos del usuario.
/// - wallLeft/wallRight: pared del lienzo (trepar, colgarse, descolgarse).
/// - ceiling: techo del lienzo, camina BOCA ABAJO con balanceo (swing).
enum StickSurface: String {
    case floor, wallLeft, wallRight, ceiling
    var isWall: Bool { self == .wallLeft || self == .wallRight }
}

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

// MARK: Percepcion del dedo (para la IA de interaccion/defensa)

struct FingerTracker {
    private(set) var present: Bool = false
    private(set) var point: CGPoint = .zero        // y = altura sobre el suelo
    private(set) var speed: CGFloat = 0            // pt/s (suavizada)
    private(set) var approachSpeed: CGFloat = 0    // pt/s acortando distancia al stickman (>0 = se acerca)
    private var lastPoint: CGPoint? = nil
    private var lastTime: Double = 0
    private var lastDistance: CGFloat? = nil

    mutating func update(point newPoint: CGPoint, stickmanX: CGFloat, stickmanHeight: CGFloat, now: Double) {
        present = true
        point = newPoint
        let dist = hypot(newPoint.x - stickmanX, newPoint.y - stickmanHeight)
        if let lp = lastPoint, now > lastTime {
            let dt = now - lastTime
            let v = hypot(newPoint.x - lp.x, newPoint.y - lp.y) / CGFloat(dt)
            speed = speed * 0.55 + v * 0.45
            if let ld = lastDistance {
                let closing = (ld - dist) / CGFloat(dt)
                approachSpeed = approachSpeed * 0.55 + closing * 0.45
            }
        }
        lastPoint = newPoint; lastTime = now; lastDistance = dist
    }

    mutating func release(now: Double) {
        present = false
        lastPoint = nil; lastDistance = nil
        speed = 0; approachSpeed = 0
        lastTime = now
    }

    func distance(toStickmanX sx: CGFloat, height: CGFloat) -> CGFloat {
        hypot(point.x - sx, point.y - height)
    }
    /// El dedo baja "a por el" si esta por encima y descendiendo hacia su cabeza/cuerpo
    var isDescendingOntoHim: Bool { present && point.y > 90 }
}

// MARK: Decisiones de la IA tactil

enum InteractionDecision: String {
    case none = "—"
    case curious = "acercarse curioso"
    case greet = "saludar"
    case flee = "huir corriendo"
    case dodgeDuck = "esquivar agachándose"
    case dodgeRoll = "esquivar rodando"
    case leanBack = "esquivar arqueándose"
    case sidestep = "paso lateral"
    case jumpOver = "saltar por encima del dedo"
    case block = "bloquear"
    case grabFinger = "agarrar el dedo"
    case counterAttack = "contraatacar"
    case miniAwakening = "mini despertar"
    case hide = "esconderse"
    case shield = "usar objeto como escudo/arma"

    var thought: String {
        switch self {
        case .none: return ""
        case .curious: return "¿qué quieres?"
        case .greet: return "¡hola!"
        case .flee: return "¡a mí no me pillas!"
        case .dodgeDuck: return "¡eh!"
        case .dodgeRoll: return "¡no me atrapas!"
        case .leanBack: return "¡casi!"
        case .sidestep: return "¡por aquí no!"
        case .jumpOver: return "¡por encima!"
        case .block: return "¡eh! ¡para!"
        case .grabFinger: return "¡te tengo, dedo!"
        case .counterAttack: return "¡toma! ¡y toma!"
        case .miniAwakening: return "¡YA ESTÁ BIEN!"
        case .hide: return "aquí no me ves..."
        case .shield: return "¡con mi escudo!"
        }
    }
}

/// Cerebro tactil: puntua la amenaza y elige reaccion.
/// Amistoso = lento y un solo toque. Hostil = rapido, persiguiendo, agarrando.
struct InteractionBrain {
    /// 0...100: sube con acoso (agarres, persecucion, toques bruscos) y decae con calma o juego suave.
    var harassment: Double = 0
    var grabAttempts: Int = 0
    private var lastGrabTime: Double = -10

    mutating func registerGrabAttempt(now: Double) {
        if now - lastGrabTime < 6 { grabAttempts += 1 } else { grabAttempts = 1 }
        lastGrabTime = now
        harassment = min(100, harassment + 16)
    }
    mutating func registerFastApproach() { harassment = min(100, harassment + 7) }
    mutating func registerRoughTap() { harassment = min(100, harassment + 9) }
    mutating func registerKindness() { harassment = max(0, harassment - 22); grabAttempts = 0 }
    mutating func tick(dt: Double, fingerPresent: Bool) {
        // Con calma decae; si el dedo esta encima, decae mas despacio
        harassment = max(0, harassment - dt * (fingerPresent ? 2.5 : 7.0))
        if harassment < 20 { grabAttempts = 0 }
    }

    /// Decide en tiempo real. `energy` baja favorece esconderse; sociabilidad alta, saludar.
    func decide(finger: FingerTracker, stickmanX: CGFloat, stickmanHeight: CGFloat,
                drives: Drives, hasShieldObject: Bool, hasHidingSpot: Bool) -> InteractionDecision {
        guard finger.present else { return .none }
        let dist = finger.distance(toStickmanX: stickmanX, height: stickmanHeight)
        let fast = finger.speed > 340
        let closingFast = finger.approachSpeed > 240

        // Muy cerca y viniendo rapido: defensa inmediata, escala con el acoso
        if dist < 74 && (closingFast || fast) {
            if harassment > 78 { return .miniAwakening }
            if harassment > 52 { return .counterAttack }
            if hasShieldObject && harassment > 30 { return .shield }
            if drives.energy < 30 && hasHidingSpot { return .hide }
            // Esquiva variada: agacharse, rodar, arquearse, paso lateral o saltar por encima
            switch (Int(harassment) + Int(dist)) % 5 {
            case 0: return .dodgeDuck
            case 1: return .dodgeRoll
            case 2: return .leanBack
            case 3: return .sidestep
            default: return .jumpOver
            }
        }
        // Le han intentado agarrar varias veces seguidas: forcejea / contraataca
        if dist < 96 && grabAttempts >= 2 {
            return harassment > 60 ? .counterAttack : .grabFinger
        }
        // Cerca pero sin violencia: guardia si hay acoso previo, si no curiosidad
        if dist < 110 {
            if harassment > 38 { return .block }
            if fast { return .flee }
            return drives.sociability > 45 ? .greet : .curious
        }
        // A media distancia acercandose rapido: se prepara / huye si ya hay acoso
        if dist < 190 && closingFast {
            return harassment > 30 ? .flee : .block
        }
        return .none
    }
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
    var targetX: CGFloat = -1         // v3: -1 = sin destino; si no, camina/corre hasta esa x (y el paso puede terminar al llegar)
    var surfaceGoal: StickSurface? = nil // v3: al empezar el paso, anclarse a esta superficie
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
            PlanStep(action: .drawingObject, duration: 1.4, thought: "voy a hacerme un rincón", objectToDraw: .chair),
            PlanStep(action: .drawingObject, duration: 1.4, thought: "", objectToDraw: .table),
            PlanStep(action: .walking, duration: 1.4, thought: ""),
            PlanStep(action: .sitting, duration: 4.0, thought: "así, cómodo")
        ])
    }
    static func exploreUI() -> Plan {
        Plan(name: "Explorar la interfaz", steps: [
            PlanStep(action: .walking, duration: 1.6, thought: "¿qué hay por allí?"),
            PlanStep(action: .climbing, duration: 2.2, thought: "¡subo a la línea de tiempo!", targetPlatform: 46),
            PlanStep(action: .snatching, duration: 1.0, thought: "¡esa herramienta es mía!"),
            PlanStep(action: .usingTool, duration: 2.4, thought: "esta herramienta es mía ahora"),
            PlanStep(action: .walking, duration: 1.4, thought: "", targetPlatform: 0),
            PlanStep(action: .climbing, duration: 2.0, thought: "y ahora... ¡a los botones!", targetPlatform: 104),
            PlanStep(action: .typing, duration: 2.4, thought: "tecleo como un loco"),
            PlanStep(action: .proud, duration: 1.8, thought: "estoy encima de la interfaz 😎")
        ])
    }
    static func playBall() -> Plan {
        Plan(name: "Jugar con mi pelota", steps: [
            PlanStep(action: .drawingObject, duration: 1.3, thought: "me dibujo una pelota", objectToDraw: .ball),
            PlanStep(action: .playingBall, duration: 5.0, thought: "¡a jugar solo!")
        ])
    }
    static func drawFriend() -> Plan {
        Plan(name: "Dibujar un amigo", steps: [
            PlanStep(action: .drawingObject, duration: 1.8, thought: "quiero un amigo", objectToDraw: .friend),
            PlanStep(action: .withFriend, duration: 4.5, thought: "¡hola, amigo!")
        ])
    }
    static func drawCreature() -> Plan {
        let kind: DrawnObjectKind = Bool.random() ? .bird : .dog
        if kind == .bird {
            return Plan(name: "Dibujar un pajarito", steps: [
                PlanStep(action: .drawingObject, duration: 1.8, thought: "dibujo un pajarito...", objectToDraw: kind),
                PlanStep(action: .releasingBird, duration: 2.4, thought: "¡vuela, vuela!"),
                PlanStep(action: .inspecting, duration: 2.8, thought: "¿qué es esto?"),
                PlanStep(action: .celebrating, duration: 1.6, thought: "")
            ])
        }
        return Plan(name: "Dibujar un perrito", steps: [
            PlanStep(action: .drawingObject, duration: 1.8, thought: "dibujo un perrito...", objectToDraw: kind),
            PlanStep(action: .withFriend, duration: 4.5, thought: "¡ha cobrado vida!"),
            PlanStep(action: .pettingCreature, duration: 2.6, thought: "buen chico..."),
            PlanStep(action: .feedingCreature, duration: 2.2, thought: "toma, come"),
            PlanStep(action: .bowing, duration: 1.8, thought: "gracias, gracias")
        ])
    }
    static func buildHouse() -> Plan {
        Plan(name: "Mi puertita", steps: [
            PlanStep(action: .drawingObject, duration: 1.7, thought: "una puertita para mí", objectToDraw: .doorHouse),
            PlanStep(action: .hammering, duration: 1.8, thought: "y unos clavos", objectToDraw: .hammer),
            PlanStep(action: .pushingHeavy, duration: 1.6, thought: "esto lo empujo aquí"),
            PlanStep(action: .proud, duration: 2.0, thought: "mi casa"),
            PlanStep(action: .walking, duration: 1.2, thought: "")
        ])
    }
    static func drawSwordAndFence() -> Plan {
        Plan(name: "Esgrima", steps: [
            PlanStep(action: .drawingObject, duration: 1.4, thought: "me dibujo una espada", objectToDraw: .sword),
            PlanStep(action: .sword, duration: 4.4, thought: "¡en guardia!")
        ])
    }
    static func trainSecondComing() -> Plan {
        Plan(name: "Entrenar como Second Coming", steps: [
            PlanStep(action: .powerPose, duration: 1.5, thought: "a despertar...", power: nil),
            PlanStep(action: .flying, duration: 3.0, thought: "¡a volar!", power: .flight),
            PlanStep(action: .jetFlight, duration: 2.2, thought: "¡vuelo propulsado!"),
            PlanStep(action: .usingPower, duration: 2.0, thought: "¡láser!", power: .eyeLaser),
            PlanStep(action: .chargingFireball, duration: 1.5, thought: "cargo la bola de fuego..."),
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
            PlanStep(action: .impatient, duration: 2.2, thought: "¿y ahora qué?"),
            PlanStep(action: .drawingObject, duration: 1.3, thought: "", objectToDraw: .chair),
            PlanStep(action: .sitting, duration: 4.0, thought: "me siento un rato")
        ])
    }
    static func happyRoutine() -> Plan {
        Plan(name: "Está contento", steps: [
            PlanStep(action: .waving, duration: 2.0, thought: "¡hola!"),
            PlanStep(action: .dancing, duration: 3.4, thought: "♪ a bailar ♪"),
            PlanStep(action: .celebrating, duration: 1.6, thought: ""),
            PlanStep(action: .clapping, duration: 1.7, thought: "¡bravo!"),
            PlanStep(action: .laughing, duration: 1.8, thought: "¡ja, ja!")
        ])
    }
    static func moodyRoutine() -> Plan {
        Plan(name: "Está molesto", steps: [
            PlanStep(action: .stomping, duration: 2.2, thought: "¡grr!"),
            PlanStep(action: .shrugging, duration: 1.2, thought: "yo paso"),
            PlanStep(action: .walkingBack, duration: 1.8, thought: "me voy... pero te vigilo")
        ])
    }

    // MARK: Planes NUEVOS de la integracion (clips v7/v8/v9)

    /// Calma: medita levitando (clip meditate de la v7).
    static func calmRoutine() -> Plan {
        Plan(name: "Meditar", steps: [
            PlanStep(action: .meditating, duration: 4.6, thought: "mmm... calma"),
            PlanStep(action: .proud, duration: 1.6, thought: "en paz")
        ])
    }
    /// Ejercicio en el lienzo: flexiones, comba y el pino de show.
    static func exerciseRoutine() -> Plan {
        Plan(name: "Ejercicio", steps: [
            PlanStep(action: .exercising, duration: 3.0, thought: "¡una, dos...!"),
            PlanStep(action: .jumpRoping, duration: 2.1, thought: "¡y la comba!"),
            PlanStep(action: .handstanding, duration: 2.9, thought: "¡mirad, el pino!"),
            PlanStep(action: .celebrating, duration: 1.4, thought: "")
        ])
    }
    /// Se dibuja una merienda y se la come (clips eatSnack/drinkSip de la v7;
    /// el alimento/vaso lo dibuja la vista en su mano).
    static func snackRoutine() -> Plan {
        Plan(name: "Merienda", steps: [
            PlanStep(action: .eating, duration: 3.4, thought: "¡a comer!"),
            PlanStep(action: .drinking, duration: 1.8, thought: "y algo de beber")
        ])
    }
    /// Vida misma: un estornudo con todo su suspense (clip sneeze de la v7).
    static func sneezeRoutine() -> Plan {
        Plan(name: "Estornudo", steps: [
            PlanStep(action: .sneezing, duration: 1.35, thought: "¡achís!")
        ])
    }
    /// Hipo irregular: dos hipos por ciclo, 2 ciclos (clip hiccup de la v7).
    static func hiccupRoutine() -> Plan {
        Plan(name: "Hipo", steps: [
            PlanStep(action: .hiccuping, duration: 5.8, thought: "hip... hip...")
        ])
    }
    /// Tiene frio: se abraza y tiembla (clip shiver de la v8).
    static func shiverRoutine() -> Plan {
        Plan(name: "Tiene frío", steps: [
            PlanStep(action: .shivering, duration: 2.4, thought: "¡brr, qué frío!")
        ])
    }
    /// Sin interaccion en mucho rato: suplica atencion (clip beg de la v8).
    static func begRoutine() -> Plan {
        Plan(name: "Suplicar atención", steps: [
            PlanStep(action: .begging, duration: 2.6, thought: "hazme caso..."),
            PlanStep(action: .beckoning, duration: 1.6, thought: "ven, anda")
        ])
    }
    /// Con 2+ criaturas vivas cerca, las dirige con el lapiz-batuta (clip conduct de la v9).
    static func conductRoutine() -> Plan {
        Plan(name: "Dirigir la orquesta", steps: [
            PlanStep(action: .conducting, duration: 3.0, thought: "¡orquesta, a la una...!"),
            PlanStep(action: .bowing, duration: 1.8, thought: "gracias, gracias")
        ])
    }
    /// Se dibuja un caballo y cabalga el lienzo (clip rideHorse de la v9;
    /// el caballo es mimo: la vista no lo dibuja, el avance lo pone el motor).
    static func horseRoutine(stageWidth: CGFloat) -> Plan {
        let target: CGFloat = Bool.random() ? 70 : stageWidth - 70
        return Plan(name: "Cabalgata", steps: [
            PlanStep(action: .drawingObject, duration: 1.6, thought: "me dibujo un caballo"),
            PlanStep(action: .ridingHorse, duration: 4.2, thought: "¡a cabalgar!", targetX: target)
        ])
    }

    // MARK: v3 — Roaming 360° (planes de superficies, estilo Shimeji)

    /// Sube por una pared hasta el techo, se cuelga, camina boca abajo
    /// y se descuelga. `toLeft` elige la pared. Las x destino son
    /// aproximadas: el motor de superficies hace las transiciones.
    static func climbWallAndCeiling(toLeft: Bool, stageWidth: CGFloat) -> Plan {
        let wallX: CGFloat = toLeft ? 44 : stageWidth - 44
        return Plan(name: toLeft ? "Trepar pared izq. y techo" : "Trepar pared dcha. y techo", steps: [
            PlanStep(action: .walking, duration: 3.2, thought: "voy a trepar por ahí", targetX: wallX),
            PlanStep(action: .pullingUp, duration: 0.9, thought: "", surfaceGoal: toLeft ? .wallLeft : .wallRight),
            PlanStep(action: .wallClimbing, duration: 3.4, thought: "¡subo, subo!"),
            PlanStep(action: .hangingWall, duration: Double.random(in: 1.6...3.4), thought: "un descansito aquí colgado"),
            PlanStep(action: .oneHandHanging, duration: 3.0, thought: "con una mano, sobrado"),
            PlanStep(action: .wallClimbing, duration: 3.0, thought: ""),
            PlanStep(action: .ceilingWalking, duration: Double.random(in: 2.6...4.2), thought: "¡boca abajo!", surfaceGoal: .ceiling),
            PlanStep(action: .swingingRope, duration: 2.8, thought: "¡a columpiarme!"),
            PlanStep(action: .hangingCeiling, duration: Double.random(in: 1.4...2.8), thought: ""),
            PlanStep(action: .dropping, duration: 1.2, thought: "¡me suelto!")
        ])
    }
    /// Solo hasta mitad de pared, colgarse un rato y descolgarse (ClimbHalfway + FallFromWall).
    static func climbHalfway(toLeft: Bool, stageWidth: CGFloat) -> Plan {
        let wallX: CGFloat = toLeft ? 44 : stageWidth - 44
        return Plan(name: "Trepar a medias", steps: [
            PlanStep(action: .sneaking, duration: 3.0, thought: "con sigilo...", targetX: wallX),
            PlanStep(action: .pullingUp, duration: 0.9, thought: "", surfaceGoal: toLeft ? .wallLeft : .wallRight),
            PlanStep(action: .wallClimbing, duration: 1.7, thought: ""),
            PlanStep(action: .hangingWall, duration: Double.random(in: 1.8...3.6), thought: "desde aquí se ve todo"),
            PlanStep(action: .dropping, duration: 1.2, thought: "")
        ])
    }
    /// Sentarse en un borde con las piernas colgando (SitWhileDanglingLegs):
    /// duracion IRREGULAR a proposito, como en la spec (patron 8/2/5).
    static func dangleOnEdge(stageWidth: CGFloat) -> Plan {
        let edgeX = Bool.random() ? CGFloat(118) : stageWidth - 138
        return Plan(name: "Piernas colgando", steps: [
            PlanStep(action: .walking, duration: 2.6, thought: "", targetX: edgeX),
            PlanStep(action: .climbing, duration: 1.6, thought: "", targetPlatform: 46),
            PlanStep(action: .tightroping, duration: 2.6, thought: "equilibrio..."),
            PlanStep(action: .dangling, duration: Double.random(in: 5.0...11.0), thought: "piernas colgando..."),
            PlanStep(action: .pullingUp, duration: 0.8, thought: ""),
            PlanStep(action: .walking, duration: 1.6, thought: "", targetPlatform: 0)
        ])
    }
    /// Tumbarse un rato (LieDown) y levantarse de un bote (Bounce).
    static func lieDownPlan() -> Plan {
        Plan(name: "Tumbarse", steps: [
            PlanStep(action: .yawning, duration: 1.4, thought: "un ratito tumbado"),
            PlanStep(action: .lyingDown, duration: Double.random(in: 3.5...6.5), thought: ""),
            PlanStep(action: .bouncing, duration: 0.9, thought: "¡arriba!")
        ])
    }

    /// Elige un plan pesando los impulsos que compiten + la memoria corta.
    /// Un solo personaje (The Second Coming); el catalogo es el de la v3 sin los
    /// planes sociales ni los unicos de Victim, que salieron con el duo.
    static func choosePlan(drives: Drives, memory: ShortMemory, perception: Perception) -> Plan {
        var candidates: [(weight: Double, plan: Plan)] = []
        candidates.append((weight: 18 + drives.curiosity * 0.5, plan: exploreUI()))
        candidates.append((weight: 14 + drives.playfulness * 0.5, plan: playBall()))
        candidates.append((weight: 12 + drives.sociability * 0.25, plan: drawCreature()))
        candidates.append((weight: 12, plan: buildCorner()))
        candidates.append((weight: 9, plan: buildHouse()))
        candidates.append((weight: 8, plan: drawSwordAndFence()))
        candidates.append((weight: 10 + drives.curiosity * 0.3, plan: wander()))
        // v3 roaming 360 y vida de bordes (ambos personajes)
        candidates.append((weight: 13 + drives.curiosity * 0.35, plan: climbWallAndCeiling(toLeft: Bool.random(), stageWidth: perception.stageWidth)))
        candidates.append((weight: 9, plan: climbHalfway(toLeft: Bool.random(), stageWidth: perception.stageWidth)))
        candidates.append((weight: 10 + drives.boredom * 0.2, plan: dangleOnEdge(stageWidth: perception.stageWidth)))
        candidates.append((weight: 7 + drives.boredom * 0.25, plan: lieDownPlan()))
        // El "amigo dibujado" de AvA 4 sigue: es un objeto que cobra vida, no un segundo personaje
        candidates.append((weight: 10 + drives.sociability * 0.55 + Double(memory.kindPlays) * 4, plan: drawFriend()))
        // Integracion v7/v8/v9: vida nueva del repertorio ampliado
        candidates.append((weight: 6 + drives.playfulness * 0.25, plan: exerciseRoutine()))
        candidates.append((weight: 7 + drives.boredom * 0.2, plan: snackRoutine()))
        candidates.append((weight: 2.5, plan: sneezeRoutine()))
        candidates.append((weight: 2.0, plan: hiccupRoutine()))
        candidates.append((weight: 2.0, plan: shiverRoutine()))
        if drives.energy < 42 { candidates.append((weight: 11, plan: calmRoutine())) }
        if drives.playfulness > 50 { candidates.append((weight: 6, plan: horseRoutine(stageWidth: perception.stageWidth))) }
        if perception.aliveObjectKinds.filter({ $0.isCreature }).count >= 2 {
            candidates.append((weight: 13, plan: conductRoutine()))
        }
        if perception.timeSinceLastInteraction > 45 {
            candidates.append((weight: 15, plan: begRoutine()))
        }
        if drives.boredom > 55 { candidates.append((weight: 26, plan: boredRoutine())) }
        if drives.playfulness > 58 || drives.sociability > 62 { candidates.append((weight: 22, plan: happyRoutine())) }
        if drives.anger > 48 { candidates.append((weight: 20 + drives.anger * 0.3, plan: moodyRoutine())) }

        // Poderes de The Second Coming: travesura / enfado / memoria -> despertar
        let powerWeight = drives.mischief * 0.45 + drives.anger * 0.6 + Double(memory.annoyances) * 7
        if powerWeight > 24 {
            candidates.append((weight: powerWeight, plan: Bool.random() ? trainSecondComing() : showOffPowers()))
        }

        let total = candidates.reduce(0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<max(total, 1))
        for c in candidates { roll -= c.weight; if roll <= 0 { return c.plan } }
        return wander()
    }
}
