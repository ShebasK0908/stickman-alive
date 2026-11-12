import Foundation
import SwiftUI

// MARK: - Acciones del stickman (estados autonomos y reactivos)

enum StickmanAction: String, CaseIterable {
    case drawn, awakening, idle, walking, running, fleeing, jumping, landing, rolling, dizzy
    case dancing, waving, sitting, sword, hammering, fighting, blocking, dodging
    case grabbingFinger, grabbed, escaping, squashed, scared, thrown, sleeping
    case climbing      // Trepa por la interfaz (timeline / botones)
    case usingTool     // Curiosear / robar una herramienta de la toolbar
    case drawingObject // Dibujando un objeto propio (con el lapiz grande, como en los videos)
    case playingBall   // Jugando solo con su pelota
    case withFriend    // Interactuando con el amigo/criatura que ha dibujado
    case yawning       // Bosteza de aburrimiento
    case resting       // Descanso obligatorio (ciclo de 2 min)
    case denying       // Niega con la cabeza: no obedece la sugerencia
    case proud         // Orgulloso, pecho fuera
    case laughing      // Se rie (hombros temblando)
    case celebrating   // Salto con brazos arriba
    case stomping      // Enfadado: pisoton y brazos cruzados
    case shrugging     // Se encoge de hombros
    case thumbsUp      // Pulgar arriba
    case hiding        // Escondido tras un objeto/interfaz
    case powerPose     // Pose de poder: entra el Modo Second Coming
    case flying        // Volando con estela
    case usingPower    // Usando el poder activo (ver activePower)
    // v3 — roaming 360° (superficies) y vida de bordes
    case wallClimbing  // Trepando por una pared (anclado a la pared)
    case ceilingWalking // Caminando boca abajo por el techo (swing)
    case hangingWall   // Colgado de una pared (HoldOntoWall)
    case hangingCeiling // Colgado del techo (HoldOntoCeiling)
    case dangling      // Sentado en un borde con las piernas colgando
    case pullingUp     // Subirse a un borde a pulso (PullUp)
    case tripping      // Tropezar (Trip)
    case bouncing      // Botar al levantarse (Bounce)
    case lyingDown     // Tumbado despierto (LieDown)
    case dropping      // Descolgarse / soltarse (FallFromWall / FallFromCeiling)
    // v3 — dedo (se mantiene en la v4)
    case chasingFinger // Perseguir el dedo del usuario (ChaseMouse)
    case sittingFacingFinger // Sentado mirando al dedo (SitAndFaceMouse)
    // v6 — clips nuevos cableados en la integracion de la auditoria
    case gettingUp     // Levantarse del suelo tras tropezar (clip getUp)
    case escapeBurst   // Romper la caja de seleccion al escapar del agarre (clip escapeBurst)
    // Integracion v7/v8/v9 — casos nuevos con disparador (el resto de clips
    // de las tandas vive en AnimationLibraryV7/V8/V9 y se usa por
    // refinamiento de la vista o queda en libreria, como hitReact en la v6)
    case jetFlight        // v7 flameJet: vuelo vertical propulsado por las manos
    case uppercut         // v7: gancho que levanta
    case flyingKick       // v7: patada voladora
    case tackling         // v7: placaje de hombro
    case snatching        // v7 snatchTool: arrebatar la herramienta
    case typing           // v7 typeFrenzy: teclear frenetico
    case pushingHeavy     // v7 pushHeavy: empujar peso con todo el cuerpo
    case peeking          // v7 peekCorner: asomarse a una esquina
    case crawling         // v7 crawl: avanzar a cuatro patas
    case swingingRope     // v7 swingRope: columpiarse agarrado arriba
    case meditating       // v7 meditate: meditar levitando
    case exercising       // v7 pushUps: flexiones
    case jumpRoping       // v7 jumpRope: saltar a la comba
    case eating           // v7 eatSnack: comerse una merienda dibujada
    case drinking         // v7 drinkSip: beber de un vaso dibujado
    case sneezing         // v7 sneeze: estornudo con suspense
    case hiccuping        // v7 hiccup: hipo irregular
    case walkingBack      // v8 walkBack: caminar hacia atras vigilando
    case sneaking         // v8 sneak: locomocion furtiva de puntillas
    case carryingLoaded   // v8 walkLoaded: caminar cargando peso en alto
    case throwingLoaded   // v9 throwLoaded: lanzar la carga que llevaba
    case fallingWithObject // v9 fallWithObject: caer abrazando la carga
    case handstanding     // v8 handstand: el pino completo
    case tightroping      // v8 tightrope: equilibrio en un borde fino
    case oneHandHanging   // v8 oneHandHang: colgarse de una sola mano
    case backKicking      // v8 backKick: patada trasera
    case kneeStriking     // v8 kneeStrike: rodillazo con agarre
    case elbowStriking    // v8 elbowStrike: codazo de distancia cero
    case headbutting      // v8 headbutt: cabezazo (tambien le duele)
    case leaningBack      // v8 leanBack: esquiva arqueandose
    case chargingFireball // v8 fireCharge: cargar la bola de fuego entre las palmas
    case diving           // v8 dive: picado desde el vuelo
    case clapping         // v8 clap: aplaudir
    case bowing           // v8 bow: reverencia
    case begging          // v8 beg: suplicar de rodillas
    case impatient        // v8: golpeteo de pie impaciente
    case shivering        // v8 shiver: temblar de frio abrazandose
    case beckoning        // v8 beckon: gesto «ven aqui»
    case highFiving       // v8 highFive: chocar los cinco con el dedo
    case groundPounding   // v9 groundPound: punetazo descendente al suelo
    case feinting         // v9 feint: amago de jab
    case sidestepping     // v9 sidestep: paso lateral de esquiva
    case parrying         // v9 palmParry: desviar con la palma
    case fingerShielding  // v9 fingerShield: atrincherarse tras el dedo
    case stretching       // v9 stretchSide: estiramiento lateral
    case noddingOff       // v9 nodOff: cabecear dormido de pie
    case sleepRolling     // v9 sleepRoll: rodar dormido al otro lado
    case inspecting       // v9 crouchInspect: agacharse a mirar una cosita
    case releasingBird    // v9 releaseBird: soltar la criatura voladora que dibujo
    case pettingCreature  // v9 petCreature: acariciar a su criatura
    case feedingCreature  // v9 feedCreature: dar de comer a su criatura
    case ridingHorse      // v9 rideHorse: trote a caballo (mimo)
    case conducting       // v9 conduct: dirigir a sus criaturas con el lapiz-batuta
    case wallJumping      // v9 wallJump: impulso desde la pared
    // v4: salen las acciones sociales del duo (chasingPeer, sparring,
    // hugging, hugged, hugOffer) y los unicos de Victim (lassoSpin,
    // stabbing, cursorSetup, working): la app es de UN personaje.

    var bubbleText: String {
        switch self {
        case .drawn: return ""
        case .awakening: return "¿Eh...? ¡Estoy vivo!"
        case .idle: return ""
        case .walking: return ""
        case .running: return "¡a correr!"
        case .fleeing: return "¡a mí no me pillas!"
        case .jumping: return "¡yupiii!"
        case .landing: return ""
        case .rolling: return "¡no me atrapas!"
        case .dizzy: return "todo da vueltas..."
        case .dancing: return "♪ ♫ ♪"
        case .waving: return "¡hola, animador!"
        case .sitting: return ""
        case .sword: return "¡en guardia!"
        case .hammering: return "clavo, clavo..."
        case .fighting: return "¡ven aquí, dedo!"
        case .blocking: return "¡eh! ¡para!"
        case .dodging: return "¡eh!"
        case .grabbingFinger: return "¡te tengo, dedo!"
        case .grabbed: return "¡suéltame!"
        case .escaping: return "¡me escapo!"
        case .squashed: return "¡auch!"
        case .scared: return "¡eh! ¡cuidado!"
        case .thrown: return "¡aaaaah!"
        case .sleeping: return "zzz..."
        case .climbing: return ""
        case .usingTool: return "esto ahora es mío"
        case .drawingObject: return ""
        case .playingBall: return ""
        case .withFriend: return ""
        case .yawning: return "qué aburrimiento..."
        case .resting: return "descanso..."
        case .denying: return "no, ahora no"
        case .proud: return ""
        case .laughing: return "¡ja, ja, ja!"
        case .celebrating: return "¡sí!"
        case .stomping: return "¡grr!"
        case .shrugging: return "yo qué sé"
        case .thumbsUp: return "¡bien!"
        case .hiding: return "aquí no me ves..."
        case .powerPose: return "a despertar..."
        case .flying: return "¡a volaaar!"
        case .usingPower: return ""
        case .wallClimbing: return ""
        case .ceilingWalking: return "¡boca abajo!"
        case .hangingWall: return ""
        case .hangingCeiling: return ""
        case .dangling: return ""
        case .pullingUp: return "¡arriba!"
        case .tripping: return "¡ay!"
        case .bouncing: return "¡boing!"
        case .lyingDown: return ""
        case .dropping: return "¡me suelto!"
        case .chasingFinger: return "¡ese dedo es mío!"
        case .sittingFacingFinger: return ""
        case .gettingUp: return ""
        case .escapeBurst: return "¡me escapo!"
        case .jetFlight: return "¡propulsión!"
        case .uppercut: return "¡gancho!"
        case .flyingKick: return "¡patada voladora!"
        case .tackling: return "¡placaje!"
        case .snatching: return "¡mío!"
        case .typing: return "tacatacataca..."
        case .pushingHeavy: return "¡empuja...!"
        case .peeking: return "¿hay alguien?"
        case .crawling: return ""
        case .swingingRope: return "¡columpio!"
        case .meditating: return "ooom..."
        case .exercising: return "¡una, dos...!"
        case .jumpRoping: return ""
        case .eating: return "ñam ñam"
        case .drinking: return "¡ahh!"
        case .sneezing: return "¡achís!"
        case .hiccuping: return "hip..."
        case .walkingBack: return "me voy... pero te vigilo"
        case .sneaking: return "con sigilo..."
        case .carryingLoaded: return "¡cómo pesa!"
        case .throwingLoaded: return "¡ahí va eso!"
        case .fallingWithObject: return "¡no lo suelto!"
        case .handstanding: return "¡mirad, el pino!"
        case .tightroping: return "equilibrio..."
        case .oneHandHanging: return "con una mano, sobrado"
        case .backKicking: return "¡patada trasera!"
        case .kneeStriking: return "¡rodillazo!"
        case .elbowStriking: return "¡codazo!"
        case .headbutting: return "¡cabezazo!"
        case .leaningBack: return "¡casi!"
        case .chargingFireball: return "cargo la bola..."
        case .diving: return "¡en picado!"
        case .clapping: return "¡bravo!"
        case .bowing: return "gracias, gracias"
        case .begging: return "hazme caso..."
        case .impatient: return "¿y ahora qué?"
        case .shivering: return "¡brr!"
        case .beckoning: return "ven, anda"
        case .highFiving: return "¡choca esos cinco!"
        case .groundPounding: return "¡al suelo!"
        case .feinting: return "¡amago!"
        case .sidestepping: return "¡por aquí no!"
        case .parrying: return "¡desviado!"
        case .fingerShielding: return "¡detrás de ti no me da!"
        case .stretching: return "qué bien sienta"
        case .noddingOff: return "zzz... ¿eh?"
        case .sleepRolling: return "zzz..."
        case .inspecting: return "¿qué es esto?"
        case .releasingBird: return "¡vuela, vuela!"
        case .pettingCreature: return "buen chico..."
        case .feedingCreature: return "toma, come"
        case .ridingHorse: return "¡a cabalgar!"
        case .conducting: return "¡orquesta!"
        case .wallJumping: return "¡desde la pared!"
        }
    }
}

// MARK: - Controlador v2
//
// Novedades frente a la v1:
//  * LOCOMOCION reescrita: velocidad con aceleracion/frenada, fase de
//    zancada ligada a la velocidad real, derrape al parar o girar en
//    seco, giro con paso cruzado, aterrizajes con rodar/mareo segun
//    impacto, deslizarse por la pared. Nada de "x += velocidad fija".
//  * IA TACTIL (StickmanBrain.InteractionBrain + FingerTracker):
//    percibe el dedo (distancia, velocidad, acercamiento) -> decide
//    (curioso, saludar, huir, esquivar, bloquear, agarrar el dedo,
//    contraatacar, mini-despertar, esconderse, escudo) -> ejecuta el clip.
//  * HERRAMIENTAS DEL USUARIO reales: modos cursor/lapiz/goma; los
//    trazos del lapiz son persistentes y FISICOS (puede subirse a ellos).

final class StickmanController: ObservableObject {

    // Identidad del personaje (solo The Second Coming)
    let kind: CharacterKind

    init(kind: CharacterKind = .secondComing) {
        self.kind = kind
        self.x = kind.startX
        self.drives = kind.initialDrives
    }

    // Posicion y fisica basica
    @Published var x: CGFloat = 180
    @Published var heightAboveGround: CGFloat = 0   // sobre la plataforma actual
    @Published var platformHeight: CGFloat = 0      // 0 suelo, 46 timeline, 104 botones
    // v3: superficie actual (roaming 360) y balanceo al ser agarrado
    @Published var surface: StickSurface = .floor
    @Published var pinchLean: CGFloat = 0           // -1..1: hacia donde tiran de el al arrastrarlo (pose pinch de la spec)
    @Published var isChasingFinger: Bool = false
    @Published var action: StickmanAction = .drawn
    @Published var isAlive: Bool = false
    @Published var facing: CGFloat = 1
    @Published var phase: Double = 0
    @Published var swordProgress: Double = 0

    // Locomocion (publicado para que la vista elija/blende clips)
    @Published var moveSpeed: CGFloat = 0           // velocidad horizontal actual (pt/s, >=0)
    @Published var gaitPhase01: Double = 0          // fase del ciclo de zancada 0..1
    @Published var isSkidding: Bool = false
    @Published var skidElapsed: Double = 0
    @Published var isTurning: Bool = false
    @Published var turnElapsed: Double = 0
    @Published var isWallSliding: Bool = false
    @Published var velocityY: CGFloat = 0
    @Published var animTime: Double = 0             // tiempo en la accion actual (para los clips)
    @Published var isJumpWindingUp: Bool = false

    // IA tactil (visible en el panel)
    @Published var lastDecision: String = "—"
    @Published var harassmentLevel: Double = 0
    @Published var hidingObjectID: UUID? = nil
    @Published var shieldKind: DrawnObjectKind? = nil
    @Published var isGrabbingFinger: Bool = false

    // Herramientas del usuario
    @Published var toolMode: ToolMode = .cursor
    @Published var userStrokes: [UserStroke] = []
    @Published var currentStroke: UserStroke? = nil

    // Cerebro (publicado para el panel de estado interno)
    @Published var drives = Drives()
    @Published var emotion: Emotion = .tranquilo
    @Published var thought: String = ""
    @Published var currentPlanName: String = "Sin plan"
    @Published var microActivity: String = "respira"
    @Published var isResting: Bool = false
    @Published var activitySeconds: Double = 0      // desde el ultimo descanso (objetivo 120)
    @Published var restSecondsLeft: Double = 0

    // Poderes / Despertar
    @Published var isAwakened: Bool = false
    @Published var activePower: Power? = nil
    @Published var shakeAmount: CGFloat = 0
    @Published var frozenPatchX: CGFloat? = nil

    // Mundo dibujado por el
    @Published var objects: [DrawnObject] = []
    @Published var particles: [Particle] = []

    // Internos
    private var particleSystem = ParticleSystem()
    private var memory = ShortMemory()
    private var perception = Perception()
    private var fingerTracker = FingerTracker()
    private var interactionBrain = InteractionBrain()
    private var plan: Plan? = nil
    private var pausedPlan: Plan? = nil
    private var planStepStarted = false
    private var planGapTimer: Double = 0

    private enum Mode { case plan, override, physics }
    private var mode: Mode = .plan
    private var overrideTimer: Double = 0

    private var velocityX: CGFloat = 0
    private let gravity: CGFloat = 1500

    private var thoughtTimer: Double = 0
    private var microTimer: Double = 0
    private var emitTimer: Double = 0
    private var awakeningAuraTimer: Double = 0
    private var frozenTimer: Double = 0
    private var tapTimestamps: [Double] = []
    private var elapsed: Double = 0
    private var lastWidth: CGFloat = 390
    private var lastHeight: CGFloat = 600

    // v3 internos: superficies y persecucion del dedo (se mantiene en v4)
    private var climbDir: CGFloat = 1               // +1 sube por la pared, -1 baja
    private var stepArrived: Bool = false           // el paso de plan llego a su destino
    private var chaseSitTimer: Double = -1          // al pillar el dedo, sentarse a mirarlo
    private var lastDragX: CGFloat = 0
    private var chaseCooldown: Double = 0
    private var tripCooldown: Double = 0

    // Locomocion interna
    private var skidTimer: Double = 0
    private var turnTimer: Double = 0
    private var lastAction: StickmanAction = .drawn
    private var jumpWindup: Double = 0
    private var pendingJumpVX: CGFloat = 0
    private var dodgeBurst: CGFloat = 0
    private var dodgeBurstTimer: Double = 0
    private var scaredBurstX: CGFloat = 0

    // IA interna
    private var iaTimer: Double = 0
    private var iaCooldown: Double = 0
    private var greetCooldown: Double = 0
    private var fastApproachThrottle: Double = 0
    private var hideTargetX: CGFloat? = nil
    private var hideObjectID: UUID? = nil

    // Arrastre
    private var isDragged: Bool = false
    private var dragTime: Double = 0
    @Published var dragEscapeSignal: Int = 0   // la vista lo observa para soltar el gesto

    // Cinematicas (CinematicEngine.swift): pausa del cerebro, pose impuesta, cuerpo oculto
    @Published var cinematicHold = false
    @Published var cinematicPose: SkeletonPose? = nil
    @Published var cinematicHidden = false

    // Deshacer (historial de trazos del usuario)
    private var strokeHistory: [[UserStroke]] = []

    var isAirborne: Bool { heightAboveGround > 0.5 || velocityY > 0 }
    var secondsUntilRest: Double { max(0, 120 - activitySeconds) }
    var speedNorm: CGFloat { min(1, moveSpeed / 170) }   // 0 = andar, 1 = correr

    private func setThought(_ text: String) {
        thought = text
        thoughtTimer = text.isEmpty ? 0 : 3.6  // R3-6 (B): el pensamiento se lee mas rato
    }

    func setFacing(_ f: CGFloat) {
        let nf: CGFloat = f >= 0 ? 1 : -1
        if nf != facing && moveSpeed > 45 && !isAirborne {
            turnTimer = 0.3; isTurning = true; turnElapsed = 0
        }
        facing = nf
    }

    // MARK: v3 — Motor de superficies

    /// Altura maxima trepable: el techo esta a `lastHeight - 170` sobre el suelo.
    private var ceilingClearance: CGFloat { max(120, lastHeight - 176) }

    /// Soltarse de pared/techo y caer con la fisica normal (FallFromWall/Ceiling).
    private func detachAndFall(thought text: String = "") {
        if surface == .ceiling { heightAboveGround = ceilingClearance }
        surface = .floor
        platformHeight = 0
        velocityY = 0; velocityX = 0
        action = .dropping; mode = .physics
        if !text.isEmpty { setThought(text) }
    }

    /// Arranque de un paso de plan que toca superficies (v3).
    private func startSurfaceStep(_ step: PlanStep) {
        // Descolgarse: desde pared conserva la altura; desde techo cae del todo.
        if step.action == .dropping {
            detachAndFall()
            return
        }
        if let goal = step.surfaceGoal {
            switch goal {
            case .wallLeft, .wallRight:
                surface = goal
                platformHeight = 0
                x = goal == .wallLeft ? 36 : lastWidth - 36
                climbDir = 1
            case .ceiling:
                // Solo se llega al techo coronando una pared; si no, se ignora.
                if surface.isWall { surface = .ceiling }
            case .floor:
                break
            }
        }
        // Trepar sin surfaceGoal (continuacion): direccion segun posicion
        if step.action == .wallClimbing, surface.isWall {
            climbDir = heightAboveGround > ceilingClearance - 24 ? -1 : 1
        }
    }

    /// Volver al suelo sin caida (al agarrarlo, al descansar, al usar un poder de suelo).
    private func snapToFloor() {
        surface = .floor; platformHeight = 0; heightAboveGround = 0
        velocityY = 0; isWallSliding = false
    }

    // v4: fuera las reacciones sociales del duo (beHugged / beSparred /
    // beRobbed / beSatBeside / onPeerUsedPower / onPeerProvoked /
    // onPeerStartedRest): no hay companero en escena.

    // MARK: Darle vida

    func bringToLife() {
        guard !isAlive else { return }
        isAlive = true
        action = .awakening
        mode = .override; overrideTimer = 2.8
        setThought("¡estoy vivo! ¿qué es todo esto?")
        drives.curiosity = 75
    }

    // MARK: SUGERENCIAS del usuario (no ordenes: a veces obedece, a veces no)

    func suggest(_ suggested: StickmanAction) {
        guard isAlive, !isResting else { return }
        perception.timeSinceLastInteraction = 0
        interactionBrain.registerKindness()
        if suggested == .jumping { suggestJump(); return }
        let probability = obedienceProbability(for: suggested)
        if Double.random(in: 0...1) <= probability {
            startOverride(suggested, duration: durationFor(suggested))
            // v9: tras dormir, a veces rueda dormido al otro lado (sleepRoll)
            if suggested == .sleeping { sleepRollPending = true }
            if suggested == .sword { ensureObject(.sword); swordProgress = 0 }
            if Double.random(in: 0...1) < 0.35 { setThought("vale, lo hago") }
            drives.registerKindPlay(); memory.kindPlays += 1
        } else if Bool.random() {
            startOverride(.denying, duration: 1.8)  // R3-6 (B): el "no" se ve mas rato (+20 %)
            setThought(suggested == .sleeping ? "no tengo sueño" : "no, ahora no")
        } else {
            let alternatives: [StickmanAction] = [.dancing, .walking, .sitting, .sword, .waving, .laughing, .celebrating]
            let alt = alternatives.randomElement() ?? .walking
            startOverride(alt, duration: durationFor(alt))
            if alt == .sword { ensureObject(.sword); swordProgress = 0; setThought("¡yo quiero la espada!") }
            else { setThought("mejor hago otra cosa") }
        }
    }

    func suggestAwakening() {
        guard isAlive, !isResting, kind == .secondComing else { return }
        let p = 0.35 + drives.mischief / 200 + drives.anger / 250
        if Double.random(in: 0...1) <= p {
            plan = Bool.random() ? PlanLibrary.trainSecondComing() : PlanLibrary.showOffPowers()
            planStepStarted = false; mode = .plan
            setThought("¡MODO SECOND COMING!")
        } else {
            startOverride(.denying, duration: 1.8)  // R3-6 (B): el "no" se ve mas rato (+20 %)
            setThought("hoy no me apetece lucirme")
        }
    }

    func suggestSleep() { suggest(.sleeping) }

    private func obedienceProbability(for a: StickmanAction) -> Double {
        var p = 0.68
        switch emotion {
        case .contento: p += 0.18
        case .enfadado: p -= 0.30
        case .furioso: p -= 0.45
        case .aburrido: p -= 0.08
        default: break
        }
        if drives.energy < 25 { p -= 0.18 }
        if a == .sleeping && drives.energy > 55 { p -= 0.25 }
        if a == .dancing && drives.playfulness > 55 { p += 0.15 }
        return min(0.92, max(0.12, p))
    }

    private func durationFor(_ a: StickmanAction) -> Double {
        switch a {
        case .waving: return 2.4
        case .dancing: return 4.5
        case .sitting, .sleeping: return 6.0
        case .sword: return 5.0
        case .walking, .running: return 3.0
        case .laughing, .celebrating: return 2.2
        default: return 2.5
        }
    }

    private func startOverride(_ a: StickmanAction, duration: Double) {
        action = a; mode = .override; overrideTimer = duration
        shieldKind = nil
        if a != .hiding { hidingObjectID = nil }
        // v6: una cadena pendiente solo sobrevive al arranque de su propio clip
        if a != .tripping { tripChainPending = false }
        if a != .escapeBurst { pendingEscapeThrow = nil }
        // Integracion v8/v9: cadenas de carga (carryingLoaded -> throwingLoaded)
        // y de sueno (sleeping -> sleepRoll)
        if a != .carryingLoaded { loadedChainPending = false }
        if a != .sleeping { sleepRollPending = false }
        // Sin giros al azar: quien llama (sugerencia, IA o plan) ya ha fijado el rumbo con setFacing.
    }

    private func suggestJump() {
        if Double.random(in: 0...1) <= obedienceProbability(for: .jumping) {
            performJump(vx: 0)
        } else {
            startOverride(.denying, duration: 1.55); setThought("no, ahora no salto")  // R3-6 (B): +19 %
        }
    }

    func jump() { suggestJump() }

    /// Salto con anticipacion: primero se agacha (clip jumpCrouch) y luego despega.
    private func performJump(vx: CGFloat) {
        guard !isAirborne, jumpWindup <= 0 else { return }
        if surface != .floor { snapToFloor() }   // v3: saltar lo despega de la pared/techo
        jumpWindup = 0.18
        pendingJumpVX = vx
        action = .jumping; mode = .physics
        isJumpWindingUp = true
    }

    // MARK: HERRAMIENTAS DEL USUARIO: lapiz / goma / deshacer

    func beginUserStroke(at worldPoint: CGPoint) {
        strokeHistory.append(userStrokes)
        if strokeHistory.count > 12 { strokeHistory.removeFirst() }
        currentStroke = UserStroke(points: [worldPoint])
    }
    func appendUserStrokePoint(_ worldPoint: CGPoint) {
        guard var s = currentStroke else { return }
        if let last = s.points.last, hypot(worldPoint.x - last.x, worldPoint.y - last.y) < 3 { return }
        s.points.append(worldPoint)
        currentStroke = s
    }
    func finishUserStroke() {
        guard let s = currentStroke else { return }
        currentStroke = nil
        userStrokes.append(s)
        if userStrokes.count > 40 { userStrokes.removeFirst(userStrokes.count - 40) }
        // Dibujarle algo es jugar suave: se calma y se interesa
        interactionBrain.registerKindness()
        drives.registerKindPlay()
        if isAlive, let first = s.points.first, abs(first.x - x) < 130 {
            setFacing(first.x >= x ? 1 : -1)
            if Double.random(in: 0...1) < 0.5 { setThought("¿qué dibujas?") }
            drives.curiosity = min(100, drives.curiosity + 8)
        }
    }
    /// Borra trazos y objetos del stickman cerca del punto (modo goma).
    func eraseAt(_ worldPoint: CGPoint) {
        var changed = false
        let kept = userStrokes.filter { stroke in
            !stroke.points.contains { hypot($0.x - worldPoint.x, $0.y - worldPoint.y) < 30 }
        }
        if kept.count != userStrokes.count { changed = true }
        for i in objects.indices where objects[i].state != .gone && !objects[i].kind.isCreature {
            if abs(objects[i].x - worldPoint.x) < 38 && worldPoint.y < 96 {
                objects[i].state = .gone; changed = true
            }
        }
        if changed {
            strokeHistory.append(userStrokes)
            if strokeHistory.count > 12 { strokeHistory.removeFirst() }
            userStrokes = kept
        }
    }
    func undoStrokeAction() {
        guard let previous = strokeHistory.popLast() else { return }
        userStrokes = previous
    }
    func clearAllStrokes() {
        guard !userStrokes.isEmpty else { return }
        strokeHistory.append(userStrokes)
        if strokeHistory.count > 12 { strokeHistory.removeFirst() }
        userStrokes = []
    }

    // MARK: Gancho para las cinematicas (CinematicEngine.swift)
    func cinematicEnsureObject(_ kind: DrawnObjectKind) { ensureObject(kind) }
    var canUndoStrokes: Bool { !strokeHistory.isEmpty }

    /// ¿Es este tramo de trazo CAMINABLE (suelo) y no pared?
    /// Pendiente RELATIVA por tramo: |dy| <= 0,5·|dx| + 0,75 (~27°).
    /// El filtro anterior era absoluto (|dy| > 26 = pared) y fallaba
    /// en los dos extremos (feedback 23:20, prioridad 1):
    /// - Un muro dibujado DESPACIO (puntos cada ~3 pt) colaba como
    ///   suelo: sus tramitos verticales pasaban el filtro y la parte
    ///   ALTA del muro se devolvia como suelo (atravesaba la silla
    ///   dibujada y «subia» por las paredes).
    /// - Una rampa dibujada RAPIDO (puntos lejos, |dy| > 26) no
    ///   registraba suelo en absoluto: caia entre plataformas.
    private func strokeSegmentWalkable(_ a: CGPoint, _ b: CGPoint) -> Bool {
        abs(b.y - a.y) <= abs(b.x - a.x) * 0.5 + 0.75
    }

    /// Altura (mundo) de la plataforma que forma un trazo caminable
    /// bajo x, si la hay. `notAbove` acota la busqueda a lo que puede
    /// pisar DESDE donde esta: sin tope, cualquier trazo horizontal
    /// por encima (la mesa dibujada sobre su cabeza) se convertia en
    /// su suelo y «subia» de golpe al pasar por debajo.
    func strokeGroundHeight(at px: CGFloat, notAbove cap: CGFloat = .greatestFiniteMagnitude) -> CGFloat? {
        var best: CGFloat? = nil
        for stroke in userStrokes {
            guard stroke.points.count > 1 else { continue }
            for i in 0..<(stroke.points.count - 1) {
                let a = stroke.points[i], b = stroke.points[i + 1]
                if !strokeSegmentWalkable(a, b) { continue }             // solo tramos caminables
                let minX = min(a.x, b.x) - 6, maxX = max(a.x, b.x) + 6
                if px < minX || px > maxX { continue }
                let span = b.x - a.x
                let y = span == 0 ? max(a.y, b.y) : a.y + (b.y - a.y) * min(1, max(0, (px - a.x) / span))
                if y > cap { continue }
                if best == nil || y > best! { best = y }
            }
        }
        return best
    }

    /// Suelo que forman los OBJETOS que el propio stickman dibuja
    /// (su silla, su mesa, su bloque): la parte de arriba se puede
    /// pisar igual que un trazo del usuario. Alturas y anchos = los
    /// del dibujo en StickmanView.drawObject.
    private func objectGroundHeight(at px: CGFloat, notAbove cap: CGFloat) -> CGFloat? {
        var best: CGFloat? = nil
        for o in objects where o.state == .intact {
            let top: CGFloat
            let halfW: CGFloat
            switch o.kind {
            case .chair: top = 22; halfW = 20
            case .table: top = 30; halfW = 30
            case .block: top = 38; halfW = 21
            default: continue
            }
            if top > cap { continue }
            if abs(px - o.x) <= halfW, best == nil || top > best! { best = top }
        }
        return best
    }

    /// Suelo total que se puede pisar en px: plataforma del mundo,
    /// trazos del usuario y objetos dibujados, siempre bajo `cap`.
    private func groundTotalHeight(at px: CGFloat, notAbove cap: CGFloat) -> CGFloat {
        var g = platformHeight
        if let s = strokeGroundHeight(at: px, notAbove: cap), s > g { g = s }
        if let o = objectGroundHeight(at: px, notAbove: cap), o > g { g = o }
        return g
    }

    /// Colision LATERAL con lo dibujado (feedback 23:20, prioridad 1:
    /// «chocar con los lados»): los tramos EMPINADOS de los trazos del
    /// usuario y los objetos altos (bloque, casita) son PAREDES. Si su
    /// borde delantero cruza la pared entre prevX y x, se queda pegado
    /// a ella. Solo caminando por el suelo: agarrado, escapando,
    /// volando o en el aire mandan el dedo y la fisica.
    private func collideWithDrawnWalls(prevX: CGFloat) {
        guard surface == .floor, !isAirborne, !isDragged else { return }
        guard action != .grabbed, action != .escaping, action != .flying else { return }
        let moved = x - prevX
        guard abs(moved) > 0.01 else { return }
        let dir: CGFloat = moved > 0 ? 1 : -1
        let halfBody: CGFloat = 10
        let feet = platformHeight + heightAboveGround
        let bodyTop = feet + 118   // ~su cabeza dibujada: por encima, pasa por debajo
        // Paredes de trazos: tramos NO caminables (empinados).
        for stroke in userStrokes {
            guard stroke.points.count > 1 else { continue }
            for i in 0..<(stroke.points.count - 1) {
                let a = stroke.points[i], b = stroke.points[i + 1]
                if strokeSegmentWalkable(a, b) { continue }
                let lo = min(a.y, b.y), hi = max(a.y, b.y)
                // La pared debe cruzar su cuerpo: lo que queda bajo
                // los pies es suelo/escalon; lo de mas arriba, aire.
                if hi < feet + 8 || lo > bodyTop { continue }
                // X de la pared a la altura de sus rodillas.
                let yTest = min(max(feet + 12, lo), hi)
                let t = (b.y - a.y) != 0 ? (yTest - a.y) / (b.y - a.y) : 0.5
                let wallX = a.x + (b.x - a.x) * min(1, max(0, t))
                if dir > 0 {
                    if prevX + halfBody <= wallX && x + halfBody > wallX { x = wallX - halfBody }
                } else {
                    if prevX - halfBody >= wallX && x - halfBody < wallX { x = wallX + halfBody }
                }
            }
        }
        // Paredes de objetos altos intactos: bloque (38) y casita (52).
        for o in objects where o.state == .intact {
            let top: CGFloat
            let halfW: CGFloat
            switch o.kind {
            case .block: top = 38; halfW = 21
            case .doorHouse: top = 52; halfW = 22
            default: continue
            }
            if feet >= top - 6 { continue }   // esta ENCIMA de el: es suelo, no pared
            let left = o.x - halfW, right = o.x + halfW
            if dir > 0 {
                if prevX + halfBody <= left && x + halfBody > left { x = left - halfBody }
            } else {
                if prevX - halfBody >= right && x - halfBody < right { x = right + halfBody }
            }
        }
    }

    // MARK: Interaccion tactil: el dedo ES el cursor del animador (modo cursor)

    /// Punto en coordenadas de mundo (x, altura sobre el suelo).
    func fingerMoved(toWorldPoint wp: CGPoint) {
        perception.fingerX = wp.x
        perception.fingerIsClose = abs(wp.x - x) < 80
        perception.timeSinceLastInteraction = 0
        fingerTracker.update(point: wp, stickmanX: x, stickmanHeight: platformHeight + heightAboveGround + 62, now: elapsed)
        // Acercamiento muy rapido a su cuerpo = acoso (con respiro para no contar 60 veces)
        if fastApproachThrottle <= 0, fingerTracker.approachSpeed > 300,
           fingerTracker.distance(toStickmanX: x, height: platformHeight + heightAboveGround + 62) < 140 {
            interactionBrain.registerFastApproach()
            fastApproachThrottle = 0.9
        }
    }
    func fingerReleased() {
        fingerTracker.release(now: elapsed)
        perception.fingerX = nil
    }

    func reactToTap(atWorldX touchX: CGFloat, fingerSpeed: CGFloat) {
        guard isAlive, !isResting else { return }
        perception.timeSinceLastInteraction = 0
        tapTimestamps.append(elapsed); tapTimestamps.removeAll { elapsed - $0 > 6 }
        if tapTimestamps.count >= 5 { // le estan molestando mucho
            memory.annoyances += 1; drives.registerAnnoyance(); tapTimestamps.removeAll()
        }
        let distance = touchX - x
        if fingerSpeed > 420 && abs(distance) < 56 {
            // Toque brusco encima: aplastado + acoso
            interactionBrain.registerRoughTap()
            startOverride(.squashed, duration: 0.6)
            setThought("¡auch!")
            return
        }
        if drives.anger > 85 {
            // v9: furia maxima -> punetazo descendente al suelo (groundPound, onda en 0.64)
            startOverride(.groundPounding, duration: 1.4)  // R3-6 (B): el golpe al suelo se ve mas (+22 %)
            shakeAmount = 12
            setThought("¡YA ESTÁ BIEN!")
        } else if drives.anger > 72 {
            plan = PlanLibrary.showOffPowers(); planStepStarted = false; mode = .plan
            setThought("¡YA ESTÁ BIEN! ¡SECOND COMING!")
        } else if abs(distance) < 46 {
            startOverride(.scared, duration: 1.45)  // R3-6 (B): el susto se ve mas rato (+21 %)
            setFacing(distance >= 0 ? -1 : 1); scaredBurstX = facing * 320
            setThought("¡eh! ¡cuidado!")
        } else if abs(distance) < 190 {
            setFacing(distance >= 0 ? 1 : -1)
            startOverride(.fighting, duration: 2.6)  // R3-6 (B): pelea con el dedo mas rato (+18 %)
            setThought(Bool.random() ? "¡ese dedo es mío!" : "¡ven aquí, dedo!")
        } else {
            setFacing(distance >= 0 ? 1 : -1)
            startOverride(.walking, duration: abs(distance) / 58)
        }
    }

    // Arrastre (agarrar al stickman): la IA cuenta intentos y el escapa solo
    func beginDrag() {
        guard isAlive else { return }
        if surface != .floor { snapToFloor() }   // v3: agarrarlo lo despega de pared/techo
        interactionBrain.registerGrabAttempt(now: elapsed)
        tripChainPending = false; pendingEscapeThrow = nil   // v6: agarrarlo corta las cadenas
        action = .grabbed; mode = .physics; velocityX = 0; velocityY = 0
        lastDragX = x; pinchLean = 0
        moveSpeed = 0
        isDragged = true; dragTime = 0
        perception.timeSinceLastInteraction = 0
        if interactionBrain.grabAttempts >= 2 { setThought("¡otra vez no!") }
    }
    func drag(to newX: CGFloat, aboveGround: CGFloat) {
        // v3: pose pinch de la spec — se inclina hacia el lado del tiron
        // (en la spec, 7 variantes por desplazamiento -50...+50 px).
        pinchLean = max(-1, min(1, (newX - lastDragX) / 26))
        lastDragX = newX
        x = newX; heightAboveGround = max(0, aboveGround)
    }
    func endDrag(velocity: CGSize) {
        guard isAlive else { return }
        isDragged = false
        velocityX = velocity.width; velocityY = -velocity.height
        action = .thrown; mode = .physics
        if abs(velocity.width) + abs(velocity.height) > 900 {
            memory.annoyances += 1; drives.registerAnnoyance(); setThought("¡no soy un juguete!")
        } else if dragTime < 0.5 {
            interactionBrain.registerKindness(); drives.registerKindPlay()
        } else { drives.registerKindPlay() }
    }

    // MARK: Objetos que el mismo dibuja

    private func ensureObject(_ kind: DrawnObjectKind) {
        if let idx = objects.firstIndex(where: { $0.kind == kind && $0.state != .gone }) {
            objects[idx].x = clampedObjectX(x + facing * 58); objects[idx].state = .intact
        } else {
            objects.append(DrawnObject(kind: kind, x: clampedObjectX(x + facing * 58)))
        }
        if objects.count > 7 { objects.removeFirst(objects.count - 7) }
        if kind == .sword { swordProgress = 0 }
    }
    private func clampedObjectX(_ v: CGFloat) -> CGFloat { min(max(36, v), lastWidth - 36) }
    private func nearestIntactObjectIndex() -> Int? {
        objects.indices.filter { objects[$0].state == .intact && !objects[$0].kind.isCreature }
            .min(by: { abs(objects[$0].x - x) < abs(objects[$1].x - x) })
    }

    // MARK: Poderes

    private func activatePower(_ power: Power) {
        // Los poderes son de The Second Coming, el unico personaje.
        guard kind == .secondComing else { return }
        if surface != .floor { snapToFloor() }   // los poderes se usan desde el suelo
        activePower = power
        isAwakened = true; awakeningAuraTimer = 7
        switch power {
        case .flight: action = .flying
        case .superSpeed: action = .running
        case .fireBreath, .eyeLaser, .ice, .createDestroy:
            if let idx = nearestIntactObjectIndex() { setFacing(objects[idx].x >= x ? 1 : -1) }
            if power == .fireBreath, let idx = nearestIntactObjectIndex() { objects[idx].state = .burning }
            if power == .createDestroy {
                if Bool.random(), let idx = nearestIntactObjectIndex() { objects[idx].state = .gone; emit(atObjectX: objects[idx].x, kind: .energy, count: 16) }
                else { ensureObject(Bool.random() ? .target : .block) }
            }
        case .superPunch:
            shakeAmount = 15
            emit(atObjectX: x + facing * 40, kind: .spark, count: 18)
            for i in objects.indices where objects[i].state == .intact { objects[i].x = clampedObjectX(objects[i].x + facing * 34) }
        case .superStrength:
            ensureObject(.block)
            if let idx = objects.firstIndex(where: { $0.kind == .block }) { objects[idx].state = .lifted }
        }
    }

    private func finishPower(_ power: Power) {
        switch power {
        case .fireBreath:
            if let idx = objects.firstIndex(where: { $0.state == .burning }) { objects[idx].state = .burnt }
        case .eyeLaser:
            if let idx = nearestIntactObjectIndex() { objects[idx].state = .cutInHalf; emit(atObjectX: objects[idx].x, kind: .spark, count: 12) }
        case .ice:
            if let idx = nearestIntactObjectIndex() { objects[idx].state = .frozen }
            else { frozenPatchX = x; frozenTimer = 9 }
        case .superStrength:
            if let idx = objects.firstIndex(where: { $0.kind == .block && $0.state == .lifted }) { objects[idx].state = .intact; objects[idx].x = clampedObjectX(x + facing * 70) }
            // v8/v9: a veces se lo lleva cargando (walkLoaded) y al soltarlo lo lanza (throwLoaded)
            if Double.random(in: 0...1) < 0.5 {
                startOverride(.carryingLoaded, duration: 2.0)
                loadedChainPending = true
                setThought("esto lo llevo yo")
            }
        default: break
        }
        if activePower == power { activePower = nil }
    }

    private func emit(atObjectX objectX: CGFloat, kind: ParticleKind, count: Int) {
        particleSystem.emit(origin: CGPoint(x: objectX, y: 70), kind: kind, count: count)
    }

    // MARK: Descanso obligatorio cada 2 minutos

    private func startRest() {
        if surface != .floor { snapToFloor() }   // v3: se descansa en el suelo
        tripChainPending = false; pendingEscapeThrow = nil   // v6: el descanso corta las cadenas
        isResting = true
        restSecondsLeft = Double.random(in: 15...20)
        pausedPlan = plan; plan = nil
        if objects.contains(where: { $0.kind == .chair && $0.state == .intact }) == false { ensureObject(.chair) }
        action = .resting; mode = .override
        setThought("descanso...")
        activePower = nil
    }
    private func endRest() {
        isResting = false; activitySeconds = 0; action = .idle
        drives.energy = max(drives.energy, 78)
        setThought("¡otra vez a ello!")
        // v9: al despertar, a veces se estira de lado a lado (stretchSide)
        if Double.random(in: 0...1) < 0.4 { startOverride(.stretching, duration: 2.4) }
        if let paused = pausedPlan, Double.random(in: 0...1) < 0.55 {
            plan = paused; planStepStarted = false; setThought("sigo con lo mío")
        } else { plan = nil }
        pausedPlan = nil; mode = .plan; planGapTimer = 0.25  // R3-2 (B): al despertar, vuelve antes a la accion
    }

    // MARK: IA tactil: percibe -> decide -> anima

    private func evaluateInteractionAI(dt: Double) {
        iaTimer -= dt; iaCooldown -= dt; greetCooldown -= dt
        fastApproachThrottle -= dt
        guard iaTimer <= 0 else { return }
        iaTimer = 0.12
        guard fingerTracker.present, toolMode == .cursor, !isDragged, !isResting,
              mode != .physics, iaCooldown <= 0 else { return }
        // No interrumpir animaciones con peso (rodar, aterrizar, mareo, celebracion...)
        let busy: Set<StickmanAction> = [.rolling, .landing, .dizzy, .grabbingFinger, .celebrating, .squashed, .escaping, .gettingUp, .escapeBurst]
        if busy.contains(action) { return }

        // ChaseMouse: si el dedo esta a media distancia, sin violencia
        // y TSC esta curioso, lo PERSIGUE corriendo por el suelo; al
        // llegar se sienta a mirarlo.
        if surface == .floor, chaseCooldown <= 0, !isChasingFinger {
            let distF = fingerTracker.distance(toStickmanX: x, height: platformHeight + heightAboveGround + 62)
            let wantsChase = drives.curiosity > 46  // R3-2 (B): persigue al dedo antes y desde mas lejos
            if distF > 150 && distF < 520 && fingerTracker.speed < 340 && wantsChase
                && Double.random(in: 0...1) < 0.55 {
                isChasingFinger = true
                chaseCooldown = 5
                lastDecision = "perseguir el dedo (ChaseMouse)"
                setFacing(fingerTracker.point.x >= x ? 1 : -1)
                startOverride(.chasingFinger, duration: 3.2)
                setThought("¡a por ese dedo!")
                return
            }
        }

        // v9 fingerShield: con acoso alto y el dedo quieto y cerca, se
        // atrinchera DETRAS del dedo en vez de huir o pelear.
        if interactionBrain.harassment > 48, fingerTracker.speed < 120 {  // R3-4 (B): se atrinchera tras el dedo antes
            let distF2 = fingerTracker.distance(toStickmanX: x, height: platformHeight + heightAboveGround + 62)
            if distF2 < 120, surface == .floor {
                lastDecision = "atrincherarse tras el dedo"
                iaCooldown = 1.4  // R3-6 (B): tras atrincherarse reacciona antes
                setFacing(fingerTracker.point.x >= x ? 1 : -1)
                startOverride(.fingerShielding, duration: 2.0)  // R3-6 (B): atrincherado mas rato (+18 %)
                setThought("¡detrás de ti no me da!")
                return
            }
        }

        let hasShield = objects.contains { ($0.kind == .block || $0.kind == .sword) && $0.state == .intact }
        let hasHiding = objects.contains { !$0.kind.isCreature && $0.state == .intact }
        let decision = interactionBrain.decide(
            finger: fingerTracker, stickmanX: x,
            stickmanHeight: platformHeight + heightAboveGround + 62,
            drives: drives, hasShieldObject: hasShield, hasHidingSpot: hasHiding)
        guard decision != .none else { return }
        if decision == .greet && greetCooldown > 0 { return }
        executeDecision(decision)
    }

    private func executeDecision(_ decision: InteractionDecision) {
        lastDecision = decision.rawValue
        iaCooldown = 0.55  // R3-2 (B): las reacciones se encadenan antes
        let fingerX = fingerTracker.point.x
        switch decision {
        case .none: break
        case .curious:
            setFacing(fingerX >= x ? 1 : -1)
            if abs(fingerX - x) > 110 {
                // v7/v8: a veces se asoma a espiar o le hace el gesto de «ven aqui»
                let roll = Double.random(in: 0...1)
                if roll < 0.35 { startOverride(.peeking, duration: 3.0) }  // R3-6 (B): espia mas rato (+15 %)
                else if roll < 0.6 { startOverride(.beckoning, duration: 1.9); setThought("ven, anda") }  // R3-6 (B): llama mas rato (+19 %)
                else { startOverride(.walking, duration: 1.2) }  // R3-6 (B): se acerca mas rato (+20 %)
            }
            else { startOverride(.idle, duration: 1.1) }  // R3-6 (B): se queda mirando mas rato (+22 %)
            setThought(decision.thought)
        case .greet:
            greetCooldown = 3.5  // R3-2 (B): saluda mas a menudo
            setFacing(fingerX >= x ? 1 : -1)
            // v8: la mitad de las veces choca los cinco en vez de saludar
            if Double.random(in: 0...1) < 0.6 {  // R3-4 (B): choca los cinco mas
                startOverride(.highFiving, duration: 1.7)  // R3-6 (B): el choque de manos se ve mas (+21 %)
                setThought("¡choca esos cinco!")
            } else {
                startOverride(.waving, duration: 1.9)  // R3-6 (B): saluda mas rato (+19 %)
                setThought(decision.thought)
            }
        case .flee:
            setFacing(fingerX >= x ? -1 : 1)
            startOverride(.fleeing, duration: 1.35)  // R3-6 (B): huye mas rato (+23 %)
            setThought(decision.thought)
        case .dodgeDuck:
            startOverride(.dodging, duration: 0.68)  // R3-6 (B): agachado mas rato (+24 %)
            setThought(decision.thought)
        case .dodgeRoll:
            setFacing(fingerX >= x ? -1 : 1)
            dodgeBurst = 300; dodgeBurstTimer = 0.55  // R3-2 (B): la esquiva rodando llega mas lejos
            startOverride(.rolling, duration: 0.75)  // R3-6 (B): rueda mas rato (+21 %)
            setThought(decision.thought)
        case .leanBack:
            startOverride(.leaningBack, duration: 1.1)  // R3-6 (B): arqueado mas rato (+22 %)
            setThought(decision.thought)
        case .sidestep:
            setFacing(fingerX >= x ? -1 : 1)
            dodgeBurst = 260; dodgeBurstTimer = 0.5  // R3-2 (B): el paso lateral llega mas lejos
            startOverride(.sidestepping, duration: 0.85)  // R3-6 (B): paso lateral mas rato (+21 %)
            setThought(decision.thought)
        case .jumpOver:
            setFacing(fingerX >= x ? 1 : -1)
            setThought(decision.thought)
            performJump(vx: facing * 250)
        case .block:
            setFacing(fingerX >= x ? 1 : -1)
            // v9: a veces desvia con la palma en vez de absorber el golpe (y queda cargado para contraatacar)
            if Double.random(in: 0...1) < 0.55 {  // R3-4 (B): desvia con la palma mas
                startOverride(.parrying, duration: 0.95)  // R3-6 (B): el desvio se ve mas (+19 %)
                setThought("¡desviado!")
            } else {
                startOverride(.blocking, duration: 1.05)  // R3-6 (B): en guardia mas rato (+24 %)
                setThought(decision.thought)
            }
        case .grabFinger:
            setFacing(fingerX >= x ? 1 : -1)
            startOverride(.grabbingFinger, duration: 1.9)  // R3-6 (B): agarra el dedo mas rato (+19 %)
            isGrabbingFinger = true
            setThought(decision.thought)
        case .counterAttack:
            setFacing(fingerX >= x ? 1 : -1)
            // Integracion v7/v8/v9: el contraataque rota entre la rafaga y
            // los golpes sueltos nuevos segun distancia y acoso acumulado.
            let dist = abs(fingerX - x)
            let pick = (Int(interactionBrain.harassment) + Int(dist)) % 7
            if dist > 120 {
                startOverride(.tackling, duration: 1.35)  // R3-6 (B): el placaje se ve mas (+23 %)
                setThought("¡placaje!")
            } else {
                switch pick {
                case 0: startOverride(.uppercut, duration: 1.25); setThought("¡gancho!")  // R3-6 (B): +19 %
                case 1: startOverride(.backKicking, duration: 1.1); setThought("¡patada trasera!")  // R3-6 (B): +22 %
                case 2: startOverride(.kneeStriking, duration: 1.05); setThought("¡rodillazo!")  // R3-6 (B): +24 %
                case 3: startOverride(.elbowStriking, duration: 0.95); setThought("¡codazo!")  // R3-6 (B): +19 %
                case 4: startOverride(.headbutting, duration: 1.15); setThought("¡cabezazo!")  // R3-6 (B): +21 %
                case 5: startOverride(.feinting, duration: 1.1); setThought("¡amago!")  // R3-6 (B): +22 %
                default: startOverride(.fighting, duration: 3.0); setThought(decision.thought)  // R3-6 (B): la rafaga dura mas (+15 %)
                }
            }
        case .miniAwakening:
            setFacing(fingerX >= x ? 1 : -1)
            setThought(decision.thought)
            startOverride(.usingPower, duration: 1.1)  // R3-6 (B): el superpunetazo se ve mas (+22 %)
            activatePower(.superPunch)
            awakeningAuraTimer = 3.0  // R3-6 (B): el aura dura mas (+20 %)
        case .hide:
            if let idx = nearestIntactObjectIndex() {
                hideTargetX = objects[idx].x - facing * 6
                hideObjectID = objects[idx].id
                setFacing(objects[idx].x >= x ? 1 : -1)
                startOverride(.walking, duration: 2.4)  // R3-6 (B): corre a esconderse mas rato (+20 %)
                setThought(decision.thought)
            } else {
                startOverride(.hiding, duration: 2.4)  // R3-6 (B): escondido mas rato (+20 %)
                setThought(decision.thought)
            }
        case .shield:
            setFacing(fingerX >= x ? 1 : -1)
            shieldKind = objects.first(where: { ($0.kind == .block || $0.kind == .sword) && $0.state == .intact })?.kind
            startOverride(.blocking, duration: 1.55)  // R3-6 (B): con escudo mas rato (+19 %)
            shieldKind = objects.first(where: { ($0.kind == .block || $0.kind == .sword) && $0.state == .intact })?.kind
            setThought(decision.thought)
        }
    }

    // MARK: Bucle principal (60 fps desde la vista)

    func tick(deltaTime dt: Double, stageWidth: CGFloat, stageHeight: CGFloat = 600) {
        lastWidth = stageWidth
        lastHeight = stageHeight
        phase += dt; elapsed += dt
        particleSystem.tick(dt: dt); particles = particleSystem.particles
        guard isAlive else { return }

        // Tiempo en la accion actual (reloj de los clips)
        if action != lastAction { animTime = 0; lastAction = action } else { animTime += dt }
        if isGrabbingFinger && action != .grabbingFinger { isGrabbingFinger = false }

        // Cinematicas: con el hold activo solo avanzan fase, animTime y
        // particulas (ya actualizados arriba); cerebro, planes y fisica
        // quedan congelados hasta que la escena devuelve el control.
        if cinematicHold { return }

        // Pensamiento: caduca
        if thoughtTimer > 0 { thoughtTimer -= dt; if thoughtTimer <= 0 { thought = "" } }

        // Micro-actividad continua: nunca esta totalmente quieto
        // R3-2 (B): micro-acciones casi el doble de frecuentes y mas visibles
        microTimer -= dt
        if microTimer <= 0 {
            microTimer = Double.random(in: 1.1...2.0)
            let options = action == .resting || action == .sleeping
                ? ["respira", "zzz"] : ["respira", "mira a un lado", "parpadea", "se rasca la cabeza", "cambia el peso", "mira su bocadillo", "mira al dedo", "se estira", "hace un gesto con la mano", "se sacude el polvo", "da un saltito"]
            microActivity = options.randomElement() ?? "respira"
        }

        // v3: enfriamientos
        if chaseCooldown > 0 { chaseCooldown -= dt }
        if tripCooldown > 0 { tripCooldown -= dt }
        // ChaseMouse: al pillar el dedo, se sienta a mirarlo (SitAndFaceMouse)
        if chaseSitTimer >= 0 {
            chaseSitTimer -= dt
            if fingerTracker.present { setFacing(fingerTracker.point.x >= x ? 1 : -1) }
            if chaseSitTimer < 0 { /* vuelve al plan normal */ }
        }
        if isChasingFinger {
            if !fingerTracker.present || action != .chasingFinger { isChasingFinger = false }
            else {
                setFacing(fingerTracker.point.x >= x ? 1 : -1)
                let d = fingerTracker.distance(toStickmanX: x, height: platformHeight + heightAboveGround + 62)
                if d < 74 {
                    isChasingFinger = false
                    chaseSitTimer = 3.4  // R3-2 (B): se queda mirando al dedo mas rato
                    startOverride(.sittingFacingFinger, duration: 3.4)
                    setThought("te miro, dedo...")
                }
            }
        }

        // Aura del despertar
        if awakeningAuraTimer > 0 { awakeningAuraTimer -= dt; if awakeningAuraTimer <= 0, activePower == nil { isAwakened = false } }
        if frozenTimer > 0 { frozenTimer -= dt; if frozenTimer <= 0 { frozenPatchX = nil } }
        if shakeAmount > 0 { shakeAmount = max(0, shakeAmount - dt * 26) }
        if swordProgress < 1, action == .sword { swordProgress = min(1, swordProgress + dt / 0.8) }
        for i in objects.indices where objects[i].kind.isCreature { objects[i].bouncePhase += dt }

        // Escape del agarre: si le sujetan mas de ~2,2 s se sacude y escapa solo
        if isDragged {
            dragTime += dt
            if dragTime > 0.9 { action = .escaping }  // R3-2 (B): el forcejeo se ve antes
            if dragTime >= 2.2 {
                isDragged = false
                dragEscapeSignal += 1
                memory.annoyances += 1; drives.registerAnnoyance()
                setThought("¡me escapo!")
                // v6: primero ROMPE la caja (escapeBurst, 0.85 s) y el
                // lanzamiento (330/390, como antes) se aplica al terminar
                // el clip, en la rama de expiracion del override de tick.
                startOverride(.escapeBurst, duration: 0.85)
                pendingEscapeThrow = (vx: (fingerTracker.point.x >= x ? -1 : 1) * 370, vy: 420)  // R3-2 (B): sale lanzado con mas fuerza
            }
            return
        }

        // ------- DESCANSO -------
        if isResting {
            restSecondsLeft -= dt
            drives.evolve(dt: dt, resting: true, interacting: false)
            emotion = Emotion.derive(from: drives, resting: true)
            updateLocomotion(dt: dt)
            emitTimer += dt
            if emitTimer > 0.9 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x, y: 118), kind: .zzz, count: 1, spread: 8, baseVelocity: CGVector(dx: 8, dy: 26)); particles = particleSystem.particles }
            if restSecondsLeft <= 0 { endRest() }
            return
        }

        // Temporizador de actividad -> descanso a los 120 s
        activitySeconds += dt
        if activitySeconds >= 120 { startRest(); return }

        // Cerebro: impulsos, memoria, percepcion, emocion, acoso
        perception.timeSinceLastInteraction += dt
        perception.stickmanX = x; perception.stageWidth = stageWidth
        perception.aliveObjectKinds = objects.filter { $0.state == .intact }.map { $0.kind }
        drives.evolve(dt: dt, resting: false, interacting: perception.timeSinceLastInteraction < 5)
        memory.tick(dt: dt)
        interactionBrain.tick(dt: dt, fingerPresent: fingerTracker.present)
        harassmentLevel = interactionBrain.harassment
        emotion = Emotion.derive(from: drives, resting: false)

        // IA tactil (solo con el dedo presente y sin fisicas en curso)
        evaluateInteractionAI(dt: dt)

        // ------- SALTO CON ANTICIPACION -------
        if jumpWindup > 0 {
            jumpWindup -= dt
            if jumpWindup <= 0 {
                isJumpWindingUp = false
                velocityY = 640; velocityX = pendingJumpVX
            }
        }

        // ------- FISICA (saltos / lanzamientos / caidas) -------
        // v3: anclado a pared/techo la altura NO es caida: manda la superficie.
        if (mode == .physics || isAirborne) && surface == .floor && action != .escapeBurst {
            if action != .flying {
                let atLeftWall = x <= 35, atRightWall = x >= stageWidth - 35
                isWallSliding = (atLeftWall || atRightWall) && velocityY < -60 && heightAboveGround > 4
                if isWallSliding { velocityY = max(velocityY, -135) }  // se desliza frenando contra la pared
                velocityY -= gravity * CGFloat(dt) * (isWallSliding ? 0.25 : 1)
                // v8 dive: cayendo muy rapido y despierto, entra en picado
                if velocityY < -700, isAwakened, action == .jumping { action = .diving }
                let feetBeforeFall = heightAboveGround   // pies ANTES de integrar la caida (para el tope)
                heightAboveGround += velocityY * CGFloat(dt)
                x += velocityX * CGFloat(dt); velocityX *= 0.985
                moveSpeed = 0
                // Tope: solo aterriza en superficies que ya estaban a
                // la altura de sus pies (o 2 pt por encima) ANTES de
                // caer este frame; nada de engancharse a un trazo que
                // le pasa por encima a mitad de caida.
                let ground = groundTotalHeight(at: x, notAbove: platformHeight + feetBeforeFall + 2) - platformHeight
                if heightAboveGround <= ground {
                    let impact = -velocityY
                    heightAboveGround = ground; velocityY = 0; velocityX = 0
                    isWallSliding = false
                    if jumpWindup <= 0 {
                        if impact > 980 { startOverride(.rolling, duration: 0.75); overrideLandingChain = .dizzy }  // R3-6 (B): rueda mas rato (+21 %)
                        // v7 crawl: a veces aterriza a cuatro patas y avanza arrastrandose
                        else if impact > 430, Double.random(in: 0...1) < 0.3 { startOverride(.crawling, duration: 1.1) }
                        else if impact > 430 { startOverride(.landing, duration: 0.42) }
                        // v3 Bounce: a veces rebota de contento al aterrizar suave
                        else if Double.random(in: 0...1) < 0.22 { startOverride(.bouncing, duration: 0.9) }
                        else { action = .idle; mode = .plan; planGapTimer = 0.2 }  // R3-2 (B)
                    }
                }
                clampToStage(stageWidth)
                return
            }
        }

        // ------- MODO OVERRIDE (reacciones, IA y sugerencias aceptadas) -------
        if mode == .override {
            overrideTimer -= dt
            updateLocomotion(dt: dt)
            // Escondite: al llegar al objeto, se agazapa tras el
            if let target = hideTargetX, action == .walking, abs(x - target) < 20 {
                hideTargetX = nil
                hidingObjectID = hideObjectID
                startOverride(.hiding, duration: 2.8)  // R3-6 (B): agazapado tras el objeto mas rato (+17 %)
                hidingObjectID = hideObjectID
            }
            if overrideTimer <= 0 {
                if let pending = pendingEscapeThrow {
                    // v6: fin de escapeBurst -> sale lanzado (como hacia antes del cableado)
                    pendingEscapeThrow = nil
                    velocityX = pending.vx; velocityY = pending.vy
                    action = .thrown; mode = .physics
                } else if overrideLandingChain == .dizzy {
                    overrideLandingChain = nil
                    startOverride(.dizzy, duration: 1.4)
                    setThought("todo da vueltas...")
                } else if tripChainPending {
                    // v6: trip acaba en la pose del suelo (0.5 s) -> encadena getUp
                    tripChainPending = false
                    startOverride(.gettingUp, duration: 1.05)
                } else if loadedChainPending {
                    // v9: fin de caminar cargado -> lanza la carga (throwLoaded, la vista suelta el objeto a 0.5)
                    loadedChainPending = false
                    startOverride(.throwingLoaded, duration: 1.2)
                    setThought("¡ahí va eso!")
                } else if sleepRollPending {
                    // v9: dormido, a veces rueda entero al otro lado sin despertarse (sleepRoll)
                    sleepRollPending = false
                    if Double.random(in: 0...1) < 0.5 {
                        startOverride(.sleepRolling, duration: 1.8)
                    } else {
                        mode = .plan; if plan == nil { planGapTimer = 0.15 }  // R3-2 (B)
                    }
                } else {
                    mode = .plan; if plan == nil { planGapTimer = 0.15 }  // R3-2 (B)
                }
            }
            groundSnap(dt: dt)
            clampToStage(stageWidth)
            return
        }

        // ------- PLANIFICADOR -------
        if mode == .plan {
            if plan == nil {
                planGapTimer -= dt
                // v3: anclado a pared/techo sin plan: espera colgado y, al
                // expirar el respiro entre planes, el motor de superficies
                // decide UNA vez (seguir trepando o descolgarse y caer).
                if surface != .floor {
                    if planGapTimer <= 0 {
                        planGapTimer = 0.8
                        if surface.isWall {
                            let roll = Double.random(in: 0...1)
                            if roll < 0.45 { detachAndFall() }
                            else if roll < 0.57 {
                                // v9 wallJump: se impulsa desde la pared en diagonal
                                let dirOut: CGFloat = surface == .wallLeft ? 1 : -1
                                surface = .floor; platformHeight = 0
                                velocityY = 300; velocityX = dirOut * 230
                                action = .wallJumping; mode = .physics
                                setThought("¡desde la pared!")
                            }
                            else {
                                climbDir = heightAboveGround < ceilingClearance * 0.5 ? 1 : -1
                                startOverride(.wallClimbing, duration: 2.2)
                            }
                        } else { // techo
                            if Double.random(in: 0...1) < 0.4 { detachAndFall() }
                            else { startOverride(.ceilingWalking, duration: 2.4) }
                        }
                    }
                    return
                }
                action = .idle
                moveSpeed = 0
                // v9 nodOff: con la energia baja se duerme DE PIE a ratos,
                // antes de llegar a tumbarse (pre-grado de sleep).
                if drives.energy < 32, Double.random(in: 0...1) < dt * 0.08 {
                    startOverride(.noddingOff, duration: 3.0)
                    setThought("zzz... ¿eh?")
                    groundSnap(dt: dt)
                    clampToStage(stageWidth)
                    return
                }
                if planGapTimer <= 0 {
                    plan = PlanLibrary.choosePlan(drives: drives, memory: memory, perception: perception)
                    planStepStarted = false
                    currentPlanName = plan?.name ?? "Sin plan"
                }
            } else if let current = plan, let step = current.currentStep {
                if !planStepStarted {
                    planStepStarted = true
                    stepArrived = false
                    action = step.action
                    startSurfaceStep(step)
                    if let obj = step.objectToDraw { ensureObject(obj) }
                    if let power = step.power { activatePower(power) }
                    else if step.action == .powerPose, kind == .secondComing { isAwakened = true; awakeningAuraTimer = 7 }
                    if step.action == .flying { activatePower(.flight) }
                    if !step.thought.isEmpty { setThought(step.thought) }
                }
                plan!.stepTimer += dt
                executeStep(step, dt: dt)
                if plan!.stepTimer >= step.duration || stepArrived {
                    if let power = step.power { finishPower(power) }
                    if step.action == .flying, activePower == .flight { activePower = nil }
                    plan!.advance(); planStepStarted = false
                    if plan!.isFinished { plan = nil; currentPlanName = "Decidiendo..."; planGapTimer = Double.random(in: 0.15...0.45) }  // R3-2 (B): menos pausa entre planes
                }
            }
        }
        groundSnap(dt: dt)
        clampToStage(stageWidth)
    }

    private var overrideLandingChain: StickmanAction? = nil
    private var tripChainPending = false        // v6: tras trip (0.5 s) encadena getUp
    private var pendingEscapeThrow: (vx: CGFloat, vy: CGFloat)? = nil  // v6: lanzamiento al terminar escapeBurst
    private var loadedChainPending = false      // v8/v9: tras carryingLoaded encadena throwingLoaded
    private var sleepRollPending = false        // v9: tras sleeping puede encadenar sleepRolling

    /// Si el suelo (plataforma o trazo del usuario) sube/baja bajo sus pies, se ajusta o cae.
    private func groundSnap(dt: Double) {
        if action == .flying || action == .escapeBurst || isDragged { return }
        if surface != .floor { return }   // v3: anclado a pared/techo no hay suelo que ajustar
        // Tope = sus pies + escalon SUBIBLE (26): el asiento de una
        // silla dibujada (~22) lo sube; el tablero de una mesa (~30+)
        // ya no — camina por debajo y choca con las patas (paredes).
        let stepUp: CGFloat = 26
        let target = groundTotalHeight(at: x, notAbove: platformHeight + heightAboveGround + stepUp) - platformHeight
        if heightAboveGround < target - 1 {
            heightAboveGround = target      // sube a la plataforma/trazo (escalon)
        } else if heightAboveGround > target + 5 {
            velocityY = 0; mode = .physics   // el suelo desaparece: cae
            // v9: si iba cargando, cae abrazando la carga (fallWithObject)
            action = action == .carryingLoaded ? .fallingWithObject : .jumping
        }
    }

    private func executeStep(_ step: PlanStep, dt: Double) {
        // v3: destino del paso (x fija)
        let destX: CGFloat? = step.targetX >= 0 ? step.targetX : nil
        if let dest = destX, surface == .floor,
           [.walking, .running, .usingTool, .sneaking, .ridingHorse].contains(step.action) {
            setFacing(dest >= x ? 1 : -1)
            if abs(dest - x) < 16 { stepArrived = true }
        }
        // Plataforma destino (trepar / bajar de la interfaz)
        if step.targetPlatform >= 0 {
            let target = step.targetPlatform
            if platformHeight < target { platformHeight = min(target, platformHeight + CGFloat(dt) * 52) }
            else if platformHeight > target { platformHeight = max(target, platformHeight - CGFloat(dt) * 52) }
        }
        // Emisiones continuas de poderes
        emitTimer += dt
        switch activePower {
        case .fireBreath:
            if emitTimer > 0.08 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x + facing * 34, y: 96), kind: .fire, count: 4, spread: 26, baseVelocity: CGVector(dx: Double(facing) * 130, dy: 6)) }
        case .flight:
            heightAboveGround = (112 - platformHeight) + CGFloat(sin(phase * 2.1)) * 16
            x += facing * 95 * CGFloat(dt)
            moveSpeed = 95
            if x > lastWidth - 50 || x < 50 { setFacing(facing * -1) }
            if emitTimer > 0.06 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x - facing * 18, y: 60), kind: .trail, count: 2, spread: 10, baseVelocity: CGVector(dx: -Double(facing) * 60, dy: -8)) }
        case .eyeLaser:
            if emitTimer > 0.12 { emitTimer = 0; if let idx = nearestIntactObjectIndex() { emit(atObjectX: objects[idx].x, kind: .spark, count: 3) } }
        case .ice:
            if emitTimer > 0.1 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x + facing * 30, y: 84), kind: .ice, count: 3, spread: 20, baseVelocity: CGVector(dx: Double(facing) * 110, dy: 0)) }
        default: break
        }
        particles = particleSystem.particles
        updateLocomotion(dt: dt)

        // Pelota: la persigue y la patea suavemente
        if action == .playingBall, let idx = objects.firstIndex(where: { $0.kind == .ball && $0.state == .intact }) {
            setFacing(objects[idx].x >= x ? 1 : -1)
            if abs(objects[idx].x - x) < 34 { objects[idx].x = clampedObjectX(objects[idx].x + facing * 46); objects[idx].bouncePhase += 1 }
        }
        if let idx = objects.firstIndex(where: { $0.kind == .ball }) { objects[idx].bouncePhase += dt * 3 }
    }

    // MARK: LOCOMOCION (reescrita en la v2)

    /// Velocidad deseada segun la accion: el cuerpo acelera/frena hasta ella.
    private func desiredSpeed() -> CGFloat {
        if dodgeBurstTimer > 0 { return dodgeBurst }
        switch action {
        case .walking: return 58
        case .running: return activePower == .superSpeed ? 335 : 152
        case .fleeing: return 218
        case .climbing: return 30
        case .playingBall: return 78
        case .fighting: return 24
        case .chasingFinger: return 196   // v3 ChaseMouse: Dash de la spec
        case .scared: return 0   // el retroceso va por scaredBurstX
        case .sneaking: return 26        // v8: sigilo de puntillas, lento de verdad
        case .walkingBack: return 40     // v8: hacia atras, prudente
        case .crawling: return 30        // v7: a cuatro patas
        case .carryingLoaded: return 34  // v8: cargado, pasos cortos
        case .ridingHorse: return 120    // v9: al trote
        default: return 0
        }
    }

    /// v3: locomocion ANCLADA a la superficie (pared / techo).
    /// Devuelve true si la superficie consume el movimiento este tick.
    private func updateSurfaceLocomotion(dt: Double) -> Bool {
        if surface.isWall {
            x = surface == .wallLeft ? 36 : lastWidth - 36
            moveSpeed = 0
            if action == .wallClimbing {
                heightAboveGround += climbDir * 46 * CGFloat(dt)
                gaitPhase01 += dt * 1.4
                if gaitPhase01 >= 1 { gaitPhase01 -= 1 }
                if climbDir > 0 && heightAboveGround >= ceilingClearance {
                    // Transicion de esquina pared -> techo
                    heightAboveGround = ceilingClearance
                    surface = .ceiling
                    action = .ceilingWalking
                    setThought("¡al techo!")
                } else if climbDir < 0 && heightAboveGround <= 0 {
                    heightAboveGround = 0
                    surface = .floor
                    action = .idle
                }
            }
            return true
        }
        if surface == .ceiling {
            moveSpeed = 0
            if action == .ceilingWalking {
                x += facing * 44 * CGFloat(dt)
                gaitPhase01 += dt * 1.1
                if gaitPhase01 >= 1 { gaitPhase01 -= 1 }
                // Transicion de esquina techo -> pared (baja por ella)
                if x <= 40 { x = 36; surface = .wallLeft; climbDir = -1; action = .wallClimbing; heightAboveGround = ceilingClearance }
                else if x >= lastWidth - 40 { x = lastWidth - 36; surface = .wallRight; climbDir = -1; action = .wallClimbing; heightAboveGround = ceilingClearance }
            }
            return true
        }
        return false
    }

    private func updateLocomotion(dt: Double) {
        // v3: si esta anclado a pared/techo, manda el motor de superficies
        if surface != .floor {
            if dodgeBurstTimer > 0 { dodgeBurstTimer -= dt; if dodgeBurstTimer <= 0 { dodgeBurst = 0 } }
            _ = updateSurfaceLocomotion(dt: dt)
            return
        }
        let xBeforeMove = x   // para la colision lateral con lo dibujado (al final)
        // v3 Trip: corriendo (o persiguiendo al dedo) puede tropezar, como en la spec
        if tripCooldown <= 0, moveSpeed > 145, action == .running || action == .chasingFinger {
            if Double.random(in: 0...1) < dt * 0.055 {
                tripCooldown = 14
                isChasingFinger = false
                // v6: trip dura 0.5 s y acaba en la pose del suelo; al expirar
                // el override, tick encadena el clip getUp (tripChainPending).
                startOverride(.tripping, duration: 0.5)
                tripChainPending = true
                dodgeBurst = 120; dodgeBurstTimer = 0.3
                setThought("¡ay! ¡he tropezado!")
                return
            }
        }
        if dodgeBurstTimer > 0 { dodgeBurstTimer -= dt; if dodgeBurstTimer <= 0 { dodgeBurst = 0 } }
        if turnTimer > 0 { turnTimer -= dt; turnElapsed = 0.3 - max(0, turnTimer); if turnTimer <= 0 { isTurning = false } }
        if skidTimer > 0 { skidTimer -= dt; skidElapsed = 0.42 - max(0, skidTimer); if skidTimer <= 0 { isSkidding = false } }

        let target = desiredSpeed()
        if target > moveSpeed {
            moveSpeed = min(target, moveSpeed + 320 * CGFloat(dt))         // acelera con peso
        } else if target < moveSpeed {
            // Frenada brusca desde correr -> DERRAPE con polvo
            if moveSpeed > 112 && target < 60 && skidTimer <= 0 && !isAirborne {
                isSkidding = true; skidTimer = 0.42; skidElapsed = 0
                particleSystem.emit(origin: CGPoint(x: x - facing * 10, y: 6), kind: .smoke, count: 6, spread: 14, baseVelocity: CGVector(dx: -Double(facing) * 40, dy: 18))
                particles = particleSystem.particles
            }
            moveSpeed = max(target, moveSpeed - (isSkidding ? 640 : 460) * CGFloat(dt))
        }
        if moveSpeed > 0.5 && !isAirborne {
            // v8: en walkingBack mira al destino pero AVANZA de espaldas
            let travelDir: CGFloat = action == .walkingBack ? -facing : facing
            x += travelDir * moveSpeed * CGFloat(dt)
            // Fase de zancada ligada a la velocidad: a mas velocidad, ciclo mas rapido y largo
            let strideLength = 62 + speedNorm * 38
            gaitPhase01 += Double(moveSpeed / strideLength) * dt
            if gaitPhase01 >= 1 { gaitPhase01 -= 1 }
        }
        if action == .scared && scaredBurstX != 0 {
            x += scaredBurstX * CGFloat(dt); scaredBurstX *= 0.88
            if abs(scaredBurstX) < 8 { scaredBurstX = 0 }
        }
        // Agarrando el dedo: se desplaza hacia el para colgarse de el
        if action == .grabbingFinger && fingerTracker.present {
            x += (fingerTracker.point.x - x) * CGFloat(min(1, dt * 7))
        }
        // Tras moverse: chocar con las paredes dibujadas (trazos
        // empinados y objetos altos), no atravesarlas.
        collideWithDrawnWalls(prevX: xBeforeMove)
    }

    private func clampToStage(_ width: CGFloat) {
        let margin: CGFloat = 34
        if surface != .floor {
            // v3: en pared/techo solo se limita el rango, sin forzar giros
            x = min(max(30, x), width - 30)
            return
        }
        if x < margin { x = margin; setFacing(1) }
        else if x > width - margin { x = width - margin; setFacing(-1) }
    }
}
