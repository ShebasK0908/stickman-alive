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
    case powerPose     // Pose de poder: entra el Modo Chosen One
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
        case .powerPose: return "modo Chosen One..."
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
//    contraatacar, mini-Chosen, esconderse, escudo) -> ejecuta el clip.
//  * HERRAMIENTAS DEL USUARIO reales: modos cursor/lapiz/goma; los
//    trazos del lapiz son persistentes y FISICOS (puede subirse a ellos).

final class StickmanController: ObservableObject {

    // v4: identidad del personaje (solo The Chosen One)
    let kind: CharacterKind

    init(kind: CharacterKind = .chosenOne) {
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

    // Poderes / Chosen One
    @Published var isChosenOne: Bool = false
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
    private var chosenAuraTimer: Double = 0
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

    // Deshacer (historial de trazos del usuario)
    private var strokeHistory: [[UserStroke]] = []

    var isAirborne: Bool { heightAboveGround > 0.5 || velocityY > 0 }
    var secondsUntilRest: Double { max(0, 120 - activitySeconds) }
    var speedNorm: CGFloat { min(1, moveSpeed / 170) }   // 0 = andar, 1 = correr

    private func setThought(_ text: String) {
        thought = text
        thoughtTimer = text.isEmpty ? 0 : 3.0
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
            if suggested == .sword { ensureObject(.sword); swordProgress = 0 }
            if Double.random(in: 0...1) < 0.35 { setThought("vale, lo hago") }
            drives.registerKindPlay(); memory.kindPlays += 1
        } else if Bool.random() {
            startOverride(.denying, duration: 1.5)
            setThought(suggested == .sleeping ? "no tengo sueño" : "no, ahora no")
        } else {
            let alternatives: [StickmanAction] = [.dancing, .walking, .sitting, .sword, .waving, .laughing, .celebrating]
            let alt = alternatives.randomElement() ?? .walking
            startOverride(alt, duration: durationFor(alt))
            if alt == .sword { ensureObject(.sword); swordProgress = 0; setThought("¡yo quiero la espada!") }
            else { setThought("mejor hago otra cosa") }
        }
    }

    func suggestChosenOne() {
        guard isAlive, !isResting, kind == .chosenOne else { return }
        let p = 0.35 + drives.mischief / 200 + drives.anger / 250
        if Double.random(in: 0...1) <= p {
            plan = Bool.random() ? PlanLibrary.trainChosenOne() : PlanLibrary.showOffPowers()
            planStepStarted = false; mode = .plan
            setThought("¡MODO CHOSEN ONE!")
        } else {
            startOverride(.denying, duration: 1.5)
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
        // Sin giros al azar: quien llama (sugerencia, IA o plan) ya ha fijado el rumbo con setFacing.
    }

    private func suggestJump() {
        if Double.random(in: 0...1) <= obedienceProbability(for: .jumping) {
            performJump(vx: 0)
        } else {
            startOverride(.denying, duration: 1.3); setThought("no, ahora no salto")
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
    var canUndoStrokes: Bool { !strokeHistory.isEmpty }

    /// Altura (mundo) de la plataforma que forma un trazo casi horizontal bajo x, si la hay.
    func strokeGroundHeight(at px: CGFloat) -> CGFloat? {
        var best: CGFloat? = nil
        for stroke in userStrokes {
            guard stroke.points.count > 1 else { continue }
            for i in 0..<(stroke.points.count - 1) {
                let a = stroke.points[i], b = stroke.points[i + 1]
                if abs(b.y - a.y) > 26 { continue }             // solo tramos caminables
                let minX = min(a.x, b.x) - 6, maxX = max(a.x, b.x) + 6
                if px < minX || px > maxX { continue }
                let span = b.x - a.x
                let y = span == 0 ? max(a.y, b.y) : a.y + (b.y - a.y) * (px - a.x) / span
                if best == nil || y > best! { best = y }
            }
        }
        return best
    }
    private func groundTotalHeight(at px: CGFloat) -> CGFloat {
        max(platformHeight, strokeGroundHeight(at: px) ?? 0)
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
        if drives.anger > 72 {
            plan = PlanLibrary.showOffPowers(); planStepStarted = false; mode = .plan
            setThought("¡YA ESTÁ BIEN! ¡CHOSEN ONE!")
        } else if abs(distance) < 46 {
            startOverride(.scared, duration: 0.9)
            setFacing(distance >= 0 ? -1 : 1); scaredBurstX = facing * 240
            setThought("¡eh! ¡cuidado!")
        } else if abs(distance) < 190 {
            setFacing(distance >= 0 ? 1 : -1)
            startOverride(.fighting, duration: 1.7)
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
        // Los poderes son de The Chosen One, el unico personaje (v4).
        guard kind == .chosenOne else { return }
        if surface != .floor { snapToFloor() }   // los poderes se usan desde el suelo
        activePower = power
        isChosenOne = true; chosenAuraTimer = 7
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
        if let paused = pausedPlan, Double.random(in: 0...1) < 0.55 {
            plan = paused; planStepStarted = false; setThought("sigo con lo mío")
        } else { plan = nil }
        pausedPlan = nil; mode = .plan; planGapTimer = 0.5
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
        // y TCO esta curioso, lo PERSIGUE corriendo por el suelo; al
        // llegar se sienta a mirarlo.
        if surface == .floor, chaseCooldown <= 0, !isChasingFinger {
            let distF = fingerTracker.distance(toStickmanX: x, height: platformHeight + heightAboveGround + 62)
            let wantsChase = drives.curiosity > 52
            if distF > 170 && distF < 460 && fingerTracker.speed < 300 && wantsChase
                && Double.random(in: 0...1) < 0.3 {
                isChasingFinger = true
                chaseCooldown = 9
                lastDecision = "perseguir el dedo (ChaseMouse)"
                setFacing(fingerTracker.point.x >= x ? 1 : -1)
                startOverride(.chasingFinger, duration: 2.6)
                setThought("¡a por ese dedo!")
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
        iaCooldown = 0.9
        let fingerX = fingerTracker.point.x
        switch decision {
        case .none: break
        case .curious:
            setFacing(fingerX >= x ? 1 : -1)
            if abs(fingerX - x) > 110 { startOverride(.walking, duration: 1.0) }
            else { startOverride(.idle, duration: 0.9) }
            setThought(decision.thought)
        case .greet:
            greetCooldown = 6
            setFacing(fingerX >= x ? 1 : -1)
            startOverride(.waving, duration: 1.6)
            setThought(decision.thought)
        case .flee:
            setFacing(fingerX >= x ? -1 : 1)
            startOverride(.fleeing, duration: 1.1)
            setThought(decision.thought)
        case .dodgeDuck:
            startOverride(.dodging, duration: 0.55)
            setThought(decision.thought)
        case .dodgeRoll:
            setFacing(fingerX >= x ? -1 : 1)
            dodgeBurst = 250; dodgeBurstTimer = 0.55
            startOverride(.rolling, duration: 0.62)
            setThought(decision.thought)
        case .jumpOver:
            setFacing(fingerX >= x ? 1 : -1)
            setThought(decision.thought)
            performJump(vx: facing * 250)
        case .block:
            setFacing(fingerX >= x ? 1 : -1)
            startOverride(.blocking, duration: 0.85)
            setThought(decision.thought)
        case .grabFinger:
            setFacing(fingerX >= x ? 1 : -1)
            startOverride(.grabbingFinger, duration: 1.2)
            isGrabbingFinger = true
            setThought(decision.thought)
        case .counterAttack:
            setFacing(fingerX >= x ? 1 : -1)
            startOverride(.fighting, duration: 2.6)
            setThought(decision.thought)
        case .miniChosen:
            setFacing(fingerX >= x ? 1 : -1)
            setThought(decision.thought)
            startOverride(.usingPower, duration: 0.9)
            activatePower(.superPunch)
            chosenAuraTimer = 2.5
        case .hide:
            if let idx = nearestIntactObjectIndex() {
                hideTargetX = objects[idx].x - facing * 6
                hideObjectID = objects[idx].id
                setFacing(objects[idx].x >= x ? 1 : -1)
                startOverride(.walking, duration: 2.0)
                setThought(decision.thought)
            } else {
                startOverride(.hiding, duration: 2.0)
                setThought(decision.thought)
            }
        case .shield:
            setFacing(fingerX >= x ? 1 : -1)
            shieldKind = objects.first(where: { ($0.kind == .block || $0.kind == .sword) && $0.state == .intact })?.kind
            startOverride(.blocking, duration: 1.3)
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

        // Pensamiento: caduca
        if thoughtTimer > 0 { thoughtTimer -= dt; if thoughtTimer <= 0 { thought = "" } }

        // Micro-actividad continua: nunca esta totalmente quieto
        microTimer -= dt
        if microTimer <= 0 {
            microTimer = Double.random(in: 2.2...4.0)
            let options = action == .resting || action == .sleeping
                ? ["respira", "zzz"] : ["respira", "mira a un lado", "parpadea", "se rasca la cabeza", "cambia el peso", "mira su bocadillo"]
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
                    chaseSitTimer = 2.6
                    startOverride(.sittingFacingFinger, duration: 2.6)
                    setThought("te miro, dedo...")
                }
            }
        }

        // Aura Chosen One
        if chosenAuraTimer > 0 { chosenAuraTimer -= dt; if chosenAuraTimer <= 0, activePower == nil { isChosenOne = false } }
        if frozenTimer > 0 { frozenTimer -= dt; if frozenTimer <= 0 { frozenPatchX = nil } }
        if shakeAmount > 0 { shakeAmount = max(0, shakeAmount - dt * 26) }
        if swordProgress < 1, action == .sword { swordProgress = min(1, swordProgress + dt / 0.8) }
        for i in objects.indices where objects[i].kind.isCreature { objects[i].bouncePhase += dt }

        // Escape del agarre: si le sujetan mas de ~2,2 s se sacude y escapa solo
        if isDragged {
            dragTime += dt
            if dragTime > 1.3 { action = .escaping }
            if dragTime >= 2.2 {
                isDragged = false
                dragEscapeSignal += 1
                memory.annoyances += 1; drives.registerAnnoyance()
                setThought("¡me escapo!")
                // v6: primero ROMPE la caja (escapeBurst, 0.85 s) y el
                // lanzamiento (330/390, como antes) se aplica al terminar
                // el clip, en la rama de expiracion del override de tick.
                startOverride(.escapeBurst, duration: 0.85)
                pendingEscapeThrow = (vx: (fingerTracker.point.x >= x ? -1 : 1) * 330, vy: 390)
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
                heightAboveGround += velocityY * CGFloat(dt)
                x += velocityX * CGFloat(dt); velocityX *= 0.985
                moveSpeed = 0
                let ground = groundTotalHeight(at: x) - platformHeight
                if heightAboveGround <= ground {
                    let impact = -velocityY
                    heightAboveGround = ground; velocityY = 0; velocityX = 0
                    isWallSliding = false
                    if jumpWindup <= 0 {
                        if impact > 980 { startOverride(.rolling, duration: 0.62); overrideLandingChain = .dizzy }
                        else if impact > 430 { startOverride(.landing, duration: 0.42) }
                        // v3 Bounce: a veces rebota de contento al aterrizar suave
                        else if Double.random(in: 0...1) < 0.22 { startOverride(.bouncing, duration: 0.9) }
                        else { action = .idle; mode = .plan; planGapTimer = 0.4 }
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
                startOverride(.hiding, duration: 2.4)
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
                } else {
                    mode = .plan; if plan == nil { planGapTimer = 0.3 }
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
                            if Double.random(in: 0...1) < 0.45 { detachAndFall() }
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
                    else if step.action == .powerPose, kind == .chosenOne { isChosenOne = true; chosenAuraTimer = 7 }
                    if step.action == .flying { activatePower(.flight) }
                    if !step.thought.isEmpty { setThought(step.thought) }
                }
                plan!.stepTimer += dt
                executeStep(step, dt: dt)
                if plan!.stepTimer >= step.duration || stepArrived {
                    if let power = step.power { finishPower(power) }
                    if step.action == .flying, activePower == .flight { activePower = nil }
                    plan!.advance(); planStepStarted = false
                    if plan!.isFinished { plan = nil; currentPlanName = "Decidiendo..."; planGapTimer = Double.random(in: 0.4...1.0) }
                }
            }
        }
        groundSnap(dt: dt)
        clampToStage(stageWidth)
    }

    private var overrideLandingChain: StickmanAction? = nil
    private var tripChainPending = false        // v6: tras trip (0.5 s) encadena getUp
    private var pendingEscapeThrow: (vx: CGFloat, vy: CGFloat)? = nil  // v6: lanzamiento al terminar escapeBurst

    /// Si el suelo (plataforma o trazo del usuario) sube/baja bajo sus pies, se ajusta o cae.
    private func groundSnap(dt: Double) {
        if action == .flying || action == .escapeBurst || isDragged { return }
        if surface != .floor { return }   // v3: anclado a pared/techo no hay suelo que ajustar
        let target = groundTotalHeight(at: x) - platformHeight
        if heightAboveGround < target - 1 {
            heightAboveGround = target      // sube a la plataforma/trazo (escalon)
        } else if heightAboveGround > target + 5 {
            velocityY = 0; mode = .physics   // el suelo desaparece: cae
            action = .jumping
        }
    }

    private func executeStep(_ step: PlanStep, dt: Double) {
        // v3: destino del paso (x fija)
        let destX: CGFloat? = step.targetX >= 0 ? step.targetX : nil
        if let dest = destX, surface == .floor,
           [.walking, .running, .usingTool].contains(step.action) {
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
            x += facing * moveSpeed * CGFloat(dt)
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
