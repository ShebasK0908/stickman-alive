import Foundation
import SwiftUI

// MARK: - Acciones del stickman (estados autonomos y reactivos)

enum StickmanAction: String, CaseIterable {
    case drawn, awakening, idle, walking, running, jumping, dancing, waving
    case sitting, sword, fighting, scared, thrown, sleeping
    case climbing      // Trepa por la interfaz (timeline / botones)
    case usingTool     // Curiosear / robar una herramienta de la toolbar
    case drawingObject // Dibujando un objeto propio
    case playingBall   // Jugando solo con su pelota
    case withFriend    // Interactuando con el amigo que ha dibujado
    case yawning       // Bosteza de aburrimiento
    case resting       // Descanso obligatorio (ciclo de 2 min)
    case denying       // Niega con la cabeza: no obedece la sugerencia
    case proud         // Orgulloso, pecho fuera
    case powerPose     // Pose de poder: entra el Modo Chosen One
    case flying        // Volando con estela
    case usingPower    // Usando el poder activo (ver activePower)

    var bubbleText: String {
        switch self {
        case .drawn: return ""
        case .awakening: return "¿Eh...? ¡Estoy vivo!"
        case .idle: return ""
        case .walking: return ""
        case .running: return "¡a correr!"
        case .jumping: return "¡yupiii!"
        case .dancing: return "♪ ♫ ♪"
        case .waving: return "¡hola, animador!"
        case .sitting: return ""
        case .sword: return "¡en guardia!"
        case .fighting: return "¡ven aquí, dedo!"
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
        case .powerPose: return "modo Chosen One..."
        case .flying: return "¡a volaaar!"
        case .usingPower: return ""
        }
    }
}

// MARK: - Controlador: fisica + ejecutor del cerebro

final class StickmanController: ObservableObject {

    // Posicion y fisica basica
    @Published var x: CGFloat = 180
    @Published var heightAboveGround: CGFloat = 0   // sobre la plataforma actual
    @Published var platformHeight: CGFloat = 0      // 0 suelo, 46 timeline, 104 botones
    @Published var action: StickmanAction = .drawn
    @Published var isAlive: Bool = false
    @Published var facing: CGFloat = 1
    @Published var phase: Double = 0
    @Published var swordProgress: Double = 0

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
    private var plan: Plan? = nil
    private var pausedPlan: Plan? = nil
    private var planStepStarted = false
    private var planGapTimer: Double = 0

    private enum Mode { case plan, override, physics }
    private var mode: Mode = .plan
    private var overrideTimer: Double = 0

    private var velocityY: CGFloat = 0
    private var velocityX: CGFloat = 0
    private let gravity: CGFloat = 1500
    private let walkSpeed: CGFloat = 58

    private var thoughtTimer: Double = 0
    private var microTimer: Double = 0
    private var emitTimer: Double = 0
    private var chosenAuraTimer: Double = 0
    private var frozenTimer: Double = 0
    private var tapTimestamps: [Double] = []
    private var elapsed: Double = 0
    private var lastWidth: CGFloat = 390

    var isAirborne: Bool { heightAboveGround > 0.5 || velocityY > 0 }
    var secondsUntilRest: Double { max(0, 120 - activitySeconds) }

    private func setThought(_ text: String) {
        thought = text
        thoughtTimer = text.isEmpty ? 0 : 3.0
    }

    // MARK: Darle vida

    func bringToLife() {
        guard !isAlive else { return }
        isAlive = true
        action = .awakening
        mode = .override; overrideTimer = 2.4
        setThought("¡estoy vivo! ¿qué es todo esto?")
        drives.curiosity = 75
    }

    // MARK: SUGERENCIAS del usuario (no ordenes: a veces obedece, a veces no)

    func suggest(_ suggested: StickmanAction) {
        guard isAlive, !isResting else { return }
        perception.timeSinceLastInteraction = 0
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
            let alternatives: [StickmanAction] = [.dancing, .walking, .sitting, .sword, .waving]
            let alt = alternatives.randomElement() ?? .walking
            startOverride(alt, duration: durationFor(alt))
            if alt == .sword { ensureObject(.sword); swordProgress = 0; setThought("¡yo quiero la espada!") }
            else { setThought("mejor hago otra cosa") }
        }
    }

    func suggestChosenOne() {
        guard isAlive, !isResting else { return }
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
        default: return 2.5
        }
    }

    private func startOverride(_ a: StickmanAction, duration: Double) {
        action = a; mode = .override; overrideTimer = duration
        if a == .walking || a == .running, Bool.random() { facing = facing * -1 }
    }

    private func suggestJump() {
        if Double.random(in: 0...1) <= obedienceProbability(for: .jumping) {
            guard !isAirborne else { return }
            velocityY = 640; action = .jumping; mode = .physics
        } else {
            startOverride(.denying, duration: 1.3); setThought("no, ahora no salto")
        }
    }

    func jump() { suggestJump() }

    // MARK: Interaccion tactil: el dedo ES el cursor del animador

    func fingerMoved(to fingerX: CGFloat) {
        perception.fingerX = fingerX
        perception.fingerIsClose = abs(fingerX - x) < 80
        perception.timeSinceLastInteraction = 0
    }

    func reactToTap(at touchX: CGFloat) {
        guard isAlive, !isResting else { return }
        fingerMoved(to: touchX)
        tapTimestamps.append(elapsed); tapTimestamps.removeAll { elapsed - $0 > 6 }
        if tapTimestamps.count >= 5 { // le estan molestando mucho
            memory.annoyances += 1; drives.registerAnnoyance(); tapTimestamps.removeAll()
        }
        let distance = touchX - x
        if drives.anger > 72 {
            plan = PlanLibrary.showOffPowers(); planStepStarted = false; mode = .plan
            setThought("¡YA ESTÁ BIEN! ¡CHOSEN ONE!")
        } else if abs(distance) < 70 {
            startOverride(.scared, duration: 0.9)
            facing = distance >= 0 ? -1 : 1; velocityX = facing * 250; mode = .override
            setThought("¡eh! ¡cuidado!")
        } else if abs(distance) < 190 {
            facing = distance >= 0 ? 1 : -1
            startOverride(.fighting, duration: 1.7)
            setThought(Bool.random() ? "¡ese dedo es mío!" : "¡ven aquí, dedo!")
        } else {
            facing = distance >= 0 ? 1 : -1
            startOverride(.walking, duration: abs(distance) / walkSpeed)
        }
    }

    func beginDrag() {
        guard isAlive else { return }
        action = .thrown; mode = .physics; velocityX = 0; velocityY = 0
        perception.timeSinceLastInteraction = 0
    }
    func drag(to newX: CGFloat, aboveGround: CGFloat) { x = newX; heightAboveGround = max(0, aboveGround) }
    func endDrag(velocity: CGSize) {
        guard isAlive else { return }
        velocityX = velocity.width; velocityY = -velocity.height
        action = .thrown; mode = .physics
        if abs(velocity.width) + abs(velocity.height) > 900 {
            memory.annoyances += 1; drives.registerAnnoyance(); setThought("¡no soy un juguete!")
        } else { drives.registerKindPlay() }
    }

    // MARK: Objetos que el mismo dibuja

    private func ensureObject(_ kind: DrawnObjectKind) {
        if let idx = objects.firstIndex(where: { $0.kind == kind && $0.state != .gone }) {
            objects[idx].x = clampedObjectX(x + facing * 58); objects[idx].state = .intact
        } else {
            objects.append(DrawnObject(kind: kind, x: clampedObjectX(x + facing * 58)))
        }
        if objects.count > 6 { objects.removeFirst(objects.count - 6) }
        if kind == .sword { swordProgress = 0 }
    }
    private func clampedObjectX(_ v: CGFloat) -> CGFloat { min(max(36, v), lastWidth - 36) }
    private func nearestIntactObjectIndex() -> Int? {
        objects.indices.filter { objects[$0].state == .intact }
            .min(by: { abs(objects[$0].x - x) < abs(objects[$1].x - x) })
    }

    // MARK: Poderes

    private func activatePower(_ power: Power) {
        activePower = power
        isChosenOne = true; chosenAuraTimer = 7
        switch power {
        case .flight: action = .flying
        case .superSpeed: action = .running
        case .fireBreath, .eyeLaser, .ice, .createDestroy:
            if let idx = nearestIntactObjectIndex() { facing = objects[idx].x >= x ? 1 : -1 }
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

    // MARK: Bucle principal (60 fps desde la vista)

    func tick(deltaTime dt: Double, stageWidth: CGFloat) {
        lastWidth = stageWidth
        phase += dt; elapsed += dt
        particleSystem.tick(dt: dt); particles = particleSystem.particles
        guard isAlive else { return }

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

        // Aura Chosen One
        if chosenAuraTimer > 0 { chosenAuraTimer -= dt; if chosenAuraTimer <= 0, activePower == nil { isChosenOne = false } }
        if frozenTimer > 0 { frozenTimer -= dt; if frozenTimer <= 0 { frozenPatchX = nil } }
        if shakeAmount > 0 { shakeAmount = max(0, shakeAmount - dt * 26) }
        if swordProgress < 1, action == .sword { swordProgress = min(1, swordProgress + dt / 0.8) }

        // ------- DESCANSO -------
        if isResting {
            restSecondsLeft -= dt
            drives.evolve(dt: dt, resting: true, interacting: false)
            emotion = Emotion.derive(from: drives, resting: true)
            emitTimer += dt
            if emitTimer > 0.9 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x, y: 118), kind: .zzz, count: 1, spread: 8, baseVelocity: CGVector(dx: 8, dy: 26)); particles = particleSystem.particles }
            if restSecondsLeft <= 0 { endRest() }
            return
        }

        // Temporizador de actividad -> descanso a los 120 s
        activitySeconds += dt
        if activitySeconds >= 120 { startRest(); return }

        // Cerebro: impulsos, memoria, percepcion, emocion
        perception.timeSinceLastInteraction += dt
        perception.stickmanX = x; perception.stageWidth = stageWidth
        perception.aliveObjectKinds = objects.filter { $0.state == .intact }.map { $0.kind }
        drives.evolve(dt: dt, resting: false, interacting: perception.timeSinceLastInteraction < 5)
        memory.tick(dt: dt)
        emotion = Emotion.derive(from: drives, resting: false)

        // ------- FISICA (saltos / lanzamientos) -------
        if mode == .physics || isAirborne {
            if action != .flying {
                velocityY -= gravity * CGFloat(dt)
                heightAboveGround += velocityY * CGFloat(dt)
                x += velocityX * CGFloat(dt); velocityX *= 0.98
                if heightAboveGround <= 0 {
                    heightAboveGround = 0; velocityY = 0; velocityX = 0
                    action = .idle; mode = .plan; planGapTimer = 0.4
                }
            }
        }

        // ------- MODO OVERRIDE (reacciones y sugerencias aceptadas) -------
        if mode == .override {
            overrideTimer -= dt
            applyHorizontalMovement(dt: dt)
            if overrideTimer <= 0 { mode = .plan; if plan == nil { planGapTimer = 0.3 } }
            clampToStage(stageWidth)
            return
        }

        // ------- PLANIFICADOR -------
        if mode == .plan {
            if plan == nil {
                planGapTimer -= dt
                action = .idle
                if planGapTimer <= 0 {
                    plan = PlanLibrary.choosePlan(drives: drives, memory: memory, perception: perception)
                    planStepStarted = false
                    currentPlanName = plan?.name ?? "Sin plan"
                }
            } else if let current = plan, let step = current.currentStep {
                if !planStepStarted {
                    planStepStarted = true
                    action = step.action
                    if let obj = step.objectToDraw { ensureObject(obj) }
                    if let power = step.power { activatePower(power) }
                    else if step.action == .powerPose { isChosenOne = true; chosenAuraTimer = 7 }
                    if step.action == .flying { activatePower(.flight) }
                    if !step.thought.isEmpty { setThought(step.thought) }
                }
                plan!.stepTimer += dt
                executeStep(step, dt: dt)
                if plan!.stepTimer >= step.duration {
                    if let power = step.power { finishPower(power) }
                    if step.action == .flying, activePower == .flight { activePower = nil }
                    plan!.advance(); planStepStarted = false
                    if plan!.isFinished { plan = nil; currentPlanName = "Decidiendo..."; planGapTimer = Double.random(in: 0.4...1.0) }
                }
            }
        }
        clampToStage(stageWidth)
    }

    private func executeStep(_ step: PlanStep, dt: Double) {
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
            heightAboveGround = 112 + CGFloat(sin(phase * 2.1)) * 16
            x += facing * 95 * CGFloat(dt)
            if x > lastWidth - 50 || x < 50 { facing *= -1 }
            if emitTimer > 0.06 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x - facing * 18, y: 60), kind: .trail, count: 2, spread: 10, baseVelocity: CGVector(dx: -Double(facing) * 60, dy: -8)) }
        case .eyeLaser:
            if emitTimer > 0.12 { emitTimer = 0; if let idx = nearestIntactObjectIndex() { emit(atObjectX: objects[idx].x, kind: .spark, count: 3) } }
        case .ice:
            if emitTimer > 0.1 { emitTimer = 0; particleSystem.emit(origin: CGPoint(x: x + facing * 30, y: 84), kind: .ice, count: 3, spread: 20, baseVelocity: CGVector(dx: Double(facing) * 110, dy: 0)) }
        default: break
        }
        particles = particleSystem.particles
        applyHorizontalMovement(dt: dt)

        // Pelota: la persigue y la patea suavemente
        if action == .playingBall, let idx = objects.firstIndex(where: { $0.kind == .ball && $0.state == .intact }) {
            facing = objects[idx].x >= x ? 1 : -1
            if abs(objects[idx].x - x) < 34 { objects[idx].x = clampedObjectX(objects[idx].x + facing * 46) ; objects[idx].bouncePhase += 1 }
        }
        if let idx = objects.firstIndex(where: { $0.kind == .ball }) { objects[idx].bouncePhase += dt * 3 }
    }

    private func applyHorizontalMovement(dt: Double) {
        switch action {
        case .walking: x += facing * walkSpeed * CGFloat(dt)
        case .running: x += facing * (activePower == .superSpeed ? 335 : walkSpeed * 2.6) * CGFloat(dt)
        case .scared: x += velocityX * CGFloat(dt); velocityX *= 0.90
        case .fighting: x += sin(phase * 10) * 24 * CGFloat(dt) * facing
        case .playingBall: x += facing * walkSpeed * 1.25 * CGFloat(dt)
        case .climbing: x += facing * walkSpeed * 0.5 * CGFloat(dt)
        default: break
        }
    }

    private func clampToStage(_ width: CGFloat) {
        let margin: CGFloat = 34
        if x < margin { x = margin; facing = 1 }
        else if x > width - margin { x = width - margin; facing = -1 }
    }
}
