import Foundation
import SwiftUI
import UIKit

// MARK: - Motor de cinematicas de The Second Coming (capa NUEVA, desde cero)
//
// Creacion propia del proyecto: ningun asset externo, ningun frame de
// terceros. Las escenas (CinematicScenes.swift) son guiones nuestros que
// se interpretan con el rig y los clips que ya existen en la app
// (SkeletonPose / AnimationClip / AnimationLibrary de StickmanAnimation).
//
// BIBLIA DE MOVIMIENTO (peticion del usuario, 2026-11-11): la coreografia
// se apoya en los clips y TIEMPOS del pase v6 (ver CHANGELOG-ANIM.md de
// stickman-anim-v6): la carrera pesada simetrica de `run` (0.60 s, contactos
// en 0.00/0.30), la rafaga `fightCombo` (3.6 s: jab-jab-cross-patada-
// barrido, impactos en 0.41/0.64/1.04/1.67/2.18, holds de impacto mas
// largos que las anticipaciones), el forcejeo `escapeShake` en 3 fases
// (2.6 s) + `escapeBurst` (0.85 s), y los poderes como carga -> descarga
// seca -> sostenido con temblor -> recuperacion (`chargePower` estalla a
// 1.62 s; `firePose` descarga a 0.40 s; `laserPose` dispara a ~0.34 s;
// `superPunchPose` impacta a 0.58 s con vibracion 0.58-0.70). Los beats de
// las escenas referencian esos clips y alinean haptica/particulas con
// esas marcas, como pide el punto 5 de "Limites honestos" del changelog.
// NO se copian fotogramas ni escenas de las peliculas: es el lenguaje de
// movimiento aplicado a guiones propios, como el resto del proyecto.
//
// ARQUITECTURA (como se acopla sin reescribir el proyecto):
//  - CinematicPlayer: reloj PROPIO de escena (con timeScale para camara
//    lenta). Interpreta los Beat de una CinematicScene y escribe en el
//    personaje a traves del protocolo CinematicStage.
//  - El cerebro autonomo se PAUSA con `cinematicHold` (parche minimo en
//    StickmanEngine.tick: tras actualizar fase/animTime/particular del
//    controlador, si el hold esta activo se sale sin pensar ni moverse).
//    Los clips siguen avanzando porque animTime se actualiza ANTES del
//    corte, y la pose cinematografica se impone con `cinematicPose`
//    (parche minimo en StickmanView.currentPose). Ver INTEGRATION.md.
//  - Al terminar (o saltar), el player quita el hold, limpia la pose y
//    el personaje retoma su vida autonoma EN EL MISMO SITIO (no se
//    restaura su x: la escena lo deja donde lo dejo, como pide la spec).
//  - Regla de oro de la spec: TODAS las escenas duran <= 45 s y el boton
//    "Saltar" esta siempre visible mientras dura la escena.

// MARK: Identidad y disparadores

enum CinematicSceneID: String, CaseIterable, Identifiable {
    case nacimiento
    case escapeDeLaCaja
    case dueloConElDedo
    case despertarSecondComing
    case elSueno
    case dibujamosJuntos

    var id: String { rawValue }
}

/// Como se dispara una escena la PRIMERA vez (despues queda en el menu).
/// Es descriptivo: quien evalua cada condicion es CinematicCoordinator,
/// con los ganchos documentados en INTEGRATION.md (no hay APIs inventadas:
/// cada disparador cuelga de algo que el proyecto ya hace).
enum CinematicTrigger: String {
    case firstLaunch          // primera apertura: sustituye a bringToLife() en el flujo de la consola falsa
    case freeModeUnlock       // al desbloquear el modo libre completo (gancho explicito del coordinador)
    case repeatedGrabs        // el usuario le agarra/arrastra varias veces seguidas (gancho en beginDrag)
    case firstAwakeningActivation // primer toque al boton "Awakening" (gancho en la barra de sugerencias)
    case sleepCycles          // tras varios ciclos de aburrimiento/dormir (el coordinador cuenta entradas en .sleeping)
    case kindDrawing          // tras dibujar varias cosas en modo lapiz sin pegarle (ganchos en el gesto)
}

// MARK: Piezas de un beat

enum CinematicHaptic {
    case light, medium, heavy, selection, success, warning
}

/// Donde nace una rafaga de particulas de la capa cinematografica.
/// Coordenadas del mundo del proyecto: x en puntos de pantalla e
/// y = altura sobre el suelo (el mismo convenio que ParticleSystem y
/// StickmanView.drawParticles: pantalla y = groundY - altura).
enum CinematicAnchor {
    case character          // a los pies del personaje
    case head               // sobre la cabeza (~150 pt)
    case hands              // delante, a la altura de las manos (~88 pt)
    case feet               // en el suelo, pegado a los pies
    case groundFront        // en el suelo, 60 pt por delante (segun facing)
}

/// Props que dibuja la CAPA cinematografica (Canvas propio, todo trazo
/// generado en codigo). No son los DrawnObject del mundo: son atrezo de
/// escena. Los que deben sobrevivir a la escena (caja rota, casita) se
/// entregan al decorado persistente con callbacks, no con estos props.
enum CinematicProp: String {
    case pencil             // cursor-lapiz que dibuja a TSC en Nacimiento
    case finger             // el dedo/cursor antagonista del Duelo
    case selectionBox       // la caja de seleccion que encierra a TSC en Escape
    case hammer             // el martillo recien dibujado, apoyado junto a el
    case groundCrack        // grieta en el suelo tras el superpunetazo
    case dreamGiant         // burbuja de sueno: el, gigante
    case dreamFlight        // burbuja de sueno: el, volando entre nubes de trazo
    case drawnPencil        // el lapiz que TSC ofrece en Dibujamos juntos
    case userPencil         // el lapiz del usuario que termina la casita
}

/// Estado vivo de un prop en escena (lo publica el player para la vista).
struct CinematicPropState: Identifiable {
    var prop: CinematicProp
    var dx: CGFloat           // desplazamiento horizontal respecto a la x del personaje
    var height: CGFloat       // altura sobre el suelo del personaje
    var scale: CGFloat = 1
    var progress: Double = 0  // uso por prop: grieta de la caja, apertura de la grieta del suelo, tamano de la burbuja...
    var id: String { prop.rawValue }
}

/// Callbacks de "resultado en el mundo": son lo UNICO que el salto de
/// escena aplica tambien al avanzar rapido (si el usuario salta, la
/// historia queda como si la escena hubiera pasado).
enum CinematicCallback {
    case bornAlive            // Nacimiento: darle vida de verdad (bringToLife del controlador)
    case hideCharacter(Bool)  // ocultar/mostrar el cuerpo real (lo dibuja la capa mientras "nace")
    case unlockAwakening         // Despertar: los poderes quedan desbloqueados en el modo libre
    case ensureRock           // Despertar: garantiza un objeto del mundo (.block) como "roca" para laser/fuego
    case persistentBrokenBox  // Escape: la esquina rota de la caja queda como prop en el mundo
    case persistentHouse      // Dibujamos: la casita dibujada entre los dos queda en el mundo
}

/// Fuente de la pose mientras dura la escena. El player la muestrea con
/// SU reloj y la impone via `cinematicPose` del controlador.
enum CinematicPoseSource {
    case followStage                       // sin imposicion: manda la accion real del controlador (p. ej. tras bringToLife)
    case action(StickmanAction)            // clip de AnimationLibrary.clip(for:) muestreado por el player
    case clip(AnimationClip)               // clip suelto de la libreria (hitReact y otros sin accion propia comoda)
    case pose(SkeletonPose)                // pose estatica exacta (el "trazo" antes de nacer, la sonrisa)
}

enum CinematicBeatAction {
    // Personaje
    case poseSource(CinematicPoseSource)
    case stageAction(StickmanAction)       // solo efectos laterales de la vista (la caja al ser agarrado/escapar, etc.)
    case setPower(Power?)                  // activePower del controlador (+ accion .usingPower si hay poder)
    case setAura(Bool)                     // isAwakened visible (aura de la vista)
    case face(CGFloat)                     // facing: 1 derecha, -1 izquierda
    // Movimiento y camara (con duracion: son "spans", no instantes)
    case moveTo(fraction: Double, duration: Double, easing: AnimEasing)   // x como fraccion del ancho del lienzo
    case heightTo(CGFloat, duration: Double, easing: AnimEasing)          // heightAboveGround
    case camera(scale: Double, focusX: Double, focusY: Double, duration: Double)
    case letterbox(Double, duration: Double)                              // 0 = sin bandas, 1 = bandas completas
    case timeScale(Double, duration: Double)                              // camara lenta / acelerada del reloj de escena
    // Presentacion (instantes, salvo subtitle que dura lo que dice)
    case subtitle(String, seconds: Double)
    case haptic(CinematicHaptic)
    case particles(kind: ParticleKind, count: Int, anchor: CinematicAnchor)
    // Props de la capa
    case propShow(CinematicProp, dx: CGFloat, height: CGFloat, scale: CGFloat)
    case propHide(CinematicProp)
    case propMove(CinematicProp, dx: CGFloat, height: CGFloat, duration: Double, easing: AnimEasing)
    case propProgress(CinematicProp, Double)
    // Revelados progresivos especiales
    case drawProgress(Double, duration: Double)   // Nacimiento: cuanto del cuerpo lleva dibujado el lapiz (0...1)
    case houseProgress(Double, duration: Double)  // Dibujamos: cuanto de la casita lleva trazado (0...1)
    // Flujo
    case label(String)                            // destino de saltos internos (tregua, despertar del sueno)
    case offerTruce                               // Duelo: muestra el boton "Tregua" hasta que se resuelve o caduca
    case callback(CinematicCallback)

    /// Si este beat debe aplicarse tambien cuando el usuario SALTA la
    /// escena o se salta a una etiqueta: son los que dejan resultado.
    var isWorldOutcome: Bool {
        switch self {
        case .callback(.bornAlive), .callback(.unlockAwakening),
             .callback(.persistentBrokenBox), .callback(.persistentHouse),
             .callback(.hideCharacter):
            return true
        default:
            return false
        }
    }
}

/// Rama de un beat: casi todos son `.always`; el Duelo usa las otras
/// dos para que la salida "con tregua" y la salida "sin tregua"
/// compartan la misma linea temporal sin pisarse (ver CinematicScenes).
enum CinematicBranch {
    case always, onlyTruce, onlyNoTruce
}

/// Un beat de guion: en el instante `time` (segundos de RELOJ DE ESCENA,
/// ya con timeScale aplicado) ocurre `action`. Los beats con duracion
/// (spans) se interpolan desde ese instante.
struct CinematicBeat {
    var time: Double
    var action: CinematicBeatAction
    var note: String = ""
    var branch: CinematicBranch = .always

    init(_ time: Double, _ action: CinematicBeatAction, note: String = "", branch: CinematicBranch = .always) {
        self.time = time
        self.action = action
        self.note = note
        self.branch = branch
    }
}

struct CinematicScene: Identifiable {
    let id: CinematicSceneID
    let title: String
    let synopsis: String
    let trigger: CinematicTrigger
    /// Duracion total declarada (la spec pone ~20-40 s por escena).
    let duration: Double
    let beats: [CinematicBeat]

    var idString: String { id.rawValue }

    /// Fin real: lo declarado o el ultimo beat, lo que llegue mas lejos.
    var effectiveDuration: Double {
        let lastBeatEnd = beats.map { $0.time }.max() ?? 0
        return max(duration, lastBeatEnd)
    }
}

// MARK: - Vistas en UserDefaults y desbloqueos

enum CinematicSeenStore {
    private static func key(_ id: CinematicSceneID) -> String { "tco.cinematics.seen.\(id.rawValue)" }
    static func isSeen(_ id: CinematicSceneID) -> Bool { UserDefaults.standard.bool(forKey: key(id)) }
    static func markSeen(_ id: CinematicSceneID) { UserDefaults.standard.set(true, forKey: key(id)) }
    static func resetAll() {
        for id in CinematicSceneID.allCases { UserDefaults.standard.removeObject(forKey: key(id)) }
        UserDefaults.standard.removeObject(forKey: awakeningKey)
    }

    private static let awakeningKey = "tco.cinematics.awakeningUnlocked"
    static var awakeningUnlocked: Bool {
        get { UserDefaults.standard.bool(forKey: awakeningKey) }
        set { UserDefaults.standard.set(newValue, forKey: awakeningKey) }
    }
    /// Maestro de disparadores automaticos (las escenas del menu siempre van).
    private static let autoKey = "tco.cinematics.autoTriggers"
    static var autoTriggersEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: autoKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: autoKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: autoKey) }
    }
}

// MARK: - Decorado persistente (lo que las escenas dejan en el mundo)
//
// La caja rota de Escape y la casita de Dibujamos tienen que SEGUIR en el
// lienzo cuando la escena termina. Viven aqui, como fracciones del ancho
// (asi sobreviven a cambios de tamano de pantalla y a relanzamientos:
// se guardan en UserDefaults). La capa cinematografica las dibuja
// siempre, tambien sin escena en curso.

final class CinematicWorldDecor: ObservableObject {
    static let shared = CinematicWorldDecor()

    @Published private(set) var brokenBoxFraction: Double?
    @Published private(set) var houseFraction: Double?

    private let boxKey = "tco.cinematics.decor.brokenBoxFraction"
    private let houseKey = "tco.cinematics.decor.houseFraction"

    init() {
        let d = UserDefaults.standard
        brokenBoxFraction = d.object(forKey: boxKey) != nil ? d.double(forKey: boxKey) : nil
        houseFraction = d.object(forKey: houseKey) != nil ? d.double(forKey: houseKey) : nil
    }

    func placeBrokenBox(atFraction fraction: Double) {
        brokenBoxFraction = fraction
        UserDefaults.standard.set(fraction, forKey: boxKey)
    }
    func placeHouse(atFraction fraction: Double) {
        houseFraction = fraction
        UserDefaults.standard.set(fraction, forKey: houseKey)
    }
    func clearAll() {
        brokenBoxFraction = nil
        houseFraction = nil
        UserDefaults.standard.removeObject(forKey: boxKey)
        UserDefaults.standard.removeObject(forKey: houseKey)
    }
}

// MARK: - Acople con el personaje: protocolo CinematicStage
//
// Interfaz estrecha y explicita entre el motor de cinematicas y el
// controlador del proyecto. Todo lo que usa son miembros que
// StickmanController YA expone (x, facing, heightAboveGround,
// platformHeight, surface, action, activePower, isAwakened, isAlive,
// bringToLife) MAS dos propiedades nuevas que hay que anadirle
// (`cinematicHold` y `cinematicPose`, parche de 2 lineas en
// StickmanEngine.swift) y un wrapper publico para `ensureObject`
// (privado hoy). Los tres parches estan copiados tal cual en
// INTEGRATION.md; sin ellos este fichero no compila, a proposito:
// es el contrato de integracion, no una API inventada en silencio.

protocol CinematicStage: AnyObject {
    var stageX: CGFloat { get set }
    var stageFacing: CGFloat { get set }
    var stageHeight: CGFloat { get set }
    var stagePlatformHeight: CGFloat { get }
    var stageIsAlive: Bool { get }
    var stageAction: StickmanAction { get }
    func stageSnapToFloor()
    func stageSetAction(_ action: StickmanAction)
    func stageSetPower(_ power: Power?)
    func stageSetAura(_ on: Bool)
    func stageBringToLife()
    func stageEnsureObject(_ kind: DrawnObjectKind)
    func stageSetHold(_ on: Bool)
    func stageSetPoseOverride(_ pose: SkeletonPose?)
    func stageSetHidden(_ hidden: Bool)
}

extension StickmanController: CinematicStage {
    var stageX: CGFloat {
        get { x }
        set { x = newValue }
    }
    var stageFacing: CGFloat {
        get { facing }
        set { setFacing(newValue) }
    }
    var stageHeight: CGFloat {
        get { heightAboveGround }
        set { heightAboveGround = newValue }
    }
    var stagePlatformHeight: CGFloat { platformHeight }
    var stageIsAlive: Bool { isAlive }
    var stageAction: StickmanAction { action }

    /// Aproximacion con miembros publicos de lo que hace el privado
    /// `snapToFloor()` (superficie suelo, sin plataforma). INTEGRATION
    /// propone como parche preferido quitarle el `private` a
    /// snapToFloor y llamar a eso; mientras tanto, esto basta porque
    /// las escenas empiezan siempre desde el suelo.
    func stageSnapToFloor() {
        surface = .floor
        platformHeight = 0
    }
    func stageSetAction(_ a: StickmanAction) { action = a }
    func stageSetPower(_ power: Power?) {
        activePower = power
        if power != nil { action = .usingPower }
    }
    func stageSetAura(_ on: Bool) { isAwakened = on }
    func stageBringToLife() { bringToLife() }
    func stageEnsureObject(_ kind: DrawnObjectKind) { cinematicEnsureObject(kind) }
    func stageSetHold(_ on: Bool) { cinematicHold = on }
    func stageSetPoseOverride(_ pose: SkeletonPose?) { cinematicPose = pose }
    func stageSetHidden(_ hidden: Bool) { cinematicHidden = hidden }
}

// MARK: - Camara cinematografica
//
// La "camara" es una transformacion del lienzo: escala + punto de foco
// (en fracciones del tamano). La vista de integracion la aplica sobre
// StickmanCanvasView (ver INTEGRATION.md); el player solo la interpola.

struct CinematicCamera: Equatable {
    var scale: CGFloat = 1
    var focusX: Double = 0.5
    var focusY: Double = 0.5

    static let identity = CinematicCamera()

    func lerped(to other: CinematicCamera, t: CGFloat) -> CinematicCamera {
        func l(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }
        func ld(_ a: Double, _ b: Double) -> Double { a + (b - a) * Double(t) }
        return CinematicCamera(scale: l(scale, other.scale),
                               focusX: ld(focusX, other.focusX),
                               focusY: ld(focusY, other.focusY))
    }
}

// MARK: - Reproductor

final class CinematicPlayer: ObservableObject {

    // Estado publicado para la capa cinematografica
    @Published private(set) var isPlaying = false
    @Published private(set) var scene: CinematicScene?
    @Published private(set) var elapsed: Double = 0          // reloj de escena (ya lleva timeScale)
    @Published private(set) var letterbox: Double = 0        // 0...1
    @Published private(set) var camera: CinematicCamera = .identity
    @Published private(set) var currentSubtitle: String?
    @Published private(set) var props: [CinematicPropState] = []
    @Published private(set) var fxParticles: [Particle] = []
    @Published private(set) var drawProgress: Double = 0     // Nacimiento
    @Published private(set) var houseProgress: Double = 0    // Dibujamos juntos
    @Published private(set) var truceOffered = false
    /// Fotograma del personaje, espejo del escenario (para que la capa
    /// dibuje props/particulas donde el esta sin observar el controlador).
    @Published private(set) var frameX: CGFloat = 0
    @Published private(set) var frameHeight: CGFloat = 0
    @Published private(set) var framePlatform: CGFloat = 0
    @Published private(set) var frameFacing: CGFloat = 1
    @Published private(set) var seenIDs: Set<String> = []

    /// Se llama UNA vez al terminar o saltar la escena (tras soltar el hold).
    var onSceneFinished: ((CinematicSceneID, Bool) -> Void)?   // (id, fueSaltada)

    private weak var stage: CinematicStage?
    private var stageWidth: CGFloat = 390

    private var beatIndex = 0
    private var spans: [ActiveSpan] = []
    private var timeScale: Double = 1
    private var poseSource: CinematicPoseSource = .followStage
    private var poseSourceStart: Double = 0
    private var subtitleUntil: Double = 0
    private var fx = ParticleSystem()
    private var truceWindowUntil: Double = 0
    private var tookTruce = false
    private var finished = true

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    init() {
        refreshSeen()
    }

    func refreshSeen() {
        seenIDs = Set(CinematicSceneID.allCases.filter { CinematicSeenStore.isSeen($0) }.map { $0.rawValue })
    }

    var progress: Double {
        guard let s = scene, s.effectiveDuration > 0 else { return 0 }
        return min(1, elapsed / s.effectiveDuration)
    }

    // MARK: Arranque / cierre

    func begin(scene newScene: CinematicScene, stage: CinematicStage, stageWidth: CGFloat) {
        guard !isPlaying else { return }
        self.scene = newScene
        self.stage = stage
        self.stageWidth = stageWidth
        elapsed = 0
        beatIndex = 0
        spans.removeAll()
        timeScale = 1
        poseSource = .followStage
        poseSourceStart = 0
        currentSubtitle = nil
        subtitleUntil = 0
        props.removeAll()
        fx = ParticleSystem()
        fxParticles = []
        drawProgress = 0
        houseProgress = 0
        truceOffered = false
        tookTruce = false
        letterbox = 0
        camera = .identity
        finished = false
        isPlaying = true

        stage.stageSnapToFloor()
        stage.stageSetHold(true)
        // Nacimiento empieza con el cuerpo real oculto: lo "dibuja" la capa.
        if newScene.id == .nacimiento { stage.stageSetHidden(true) }
        syncFrame()
        impactMedium.prepare()
        impactHeavy.prepare()
        notify.prepare()
    }

    private func finish(skipped: Bool) {
        guard isPlaying, !finished else { return }
        finished = true
        let id = scene?.id
        // Devuelve el personaje a su vida: sin pose impuesta, sin hold,
        // en el mismo sitio donde la escena lo dejo (spec).
        stage?.stageSetPoseOverride(nil)
        stage?.stageSetPower(nil)
        stage?.stageSetHidden(false)
        stage?.stageSetHold(false)
        if let id = id {
            CinematicSeenStore.markSeen(id)
            refreshSeen()
        }
        isPlaying = false
        currentSubtitle = nil
        truceOffered = false
        props.removeAll()
        letterbox = 0
        camera = .identity
        if let id = id { onSceneFinished?(id, skipped) }
        scene = nil
    }

    /// Boton/gesto de saltar: SIEMPRE disponible. Aplica solo los beats
    /// con resultado en el mundo y termina (regla de oro de la spec).
    func skip() {
        guard isPlaying, let s = scene else { return }
        for beat in s.beats where beat.time >= elapsed && beat.action.isWorldOutcome {
            applyInstant(beat.action, replay: true)
        }
        finish(skipped: true)
    }

    /// Tregua del Duelo: salta a la etiqueta "tregua" si la escena la tiene.
    func acceptTruce() {
        guard isPlaying, truceOffered else { return }
        truceOffered = false
        tookTruce = true
        gotoLabel("tregua")
    }

    /// Toque del usuario sobre la capa: en El sueno, despertar antes de tiempo.
    func handleOverlayTap() {
        guard isPlaying, scene?.id == .elSueno else { return }
        if let labelTime = labelTime("despertar"), elapsed < labelTime {
            gotoLabel("despertar")
        }
    }

    private func labelTime(_ name: String) -> Double? {
        scene?.beats.first(where: {
            if case .label(let l) = $0.action { return l == name }
            return false
        })?.time
    }

    private func gotoLabel(_ name: String) {
        guard isPlaying, let target = labelTime(name) else { return }
        resync(toTime: target)
    }

    /// Reconstruye el estado como si la escena hubiera llegado a `target`
    /// sin reproducir sonidos/haptica/particulas: se usa al saltar a una
    /// etiqueta (tregua / despertar). Los spans ya terminados se fijan en
    /// su valor final; los que estan en vuelo se re-arman con lo que les
    /// queda; los props se reconstruyen desde cero.
    private func resync(toTime target: Double) {
        guard let s = scene, let stage = stage else { return }
        props.removeAll()
        currentSubtitle = nil
        poseSource = .followStage
        poseSourceStart = target
        spans.removeAll()
        elapsed = target
        beatIndex = 0
        var cameraNow = CinematicCamera.identity
        var letterboxNow: Double = 0
        for beat in s.beats {
            // Avanza el indice hasta el primer beat posterior al destino.
            if beat.time <= target { beatIndex += 1 }
            switch beat.action {
            case .poseSource(let source) where beat.time <= target:
                poseSource = source
                poseSourceStart = beat.time
            case .stageAction(let a) where beat.time <= target:
                stage.stageSetAction(a)
            case .setPower(let p) where beat.time <= target:
                stage.stageSetPower(p)
            case .setAura(let on) where beat.time <= target:
                stage.stageSetAura(on)
            case .face(let f) where beat.time <= target:
                stage.stageFacing = f
            case .callback(_) where beat.time <= target && beat.action.isWorldOutcome:
                applyInstant(beat.action, replay: true)
            case .moveTo(let fraction, let duration, let easing) where beat.time + duration <= target:
                stage.stageX = CGFloat(fraction) * stageWidth
                _ = easing
            case .heightTo(let h, let duration, _) where beat.time + duration <= target:
                stage.stageHeight = h
            case .camera(let sc, let fx, let fy, let duration) where beat.time + duration <= target:
                cameraNow = CinematicCamera(scale: CGFloat(sc), focusX: fx, focusY: fy)
                _ = duration
            case .letterbox(let amount, let duration) where beat.time + duration <= target:
                letterboxNow = amount
                _ = duration
            case .drawProgress(let v, let duration) where beat.time + duration <= target:
                drawProgress = v
                _ = duration
            case .houseProgress(let v, let duration) where beat.time + duration <= target:
                houseProgress = v
                _ = duration
            case .propShow(let prop, let dx, let height, let scale) where beat.time <= target:
                upsertProp(CinematicPropState(prop: prop, dx: dx, height: height, scale: scale))
            case .propHide(let prop) where beat.time <= target:
                props.removeAll { $0.prop == prop }
            case .propProgress(let prop, let v) where beat.time <= target:
                if let i = props.firstIndex(where: { $0.prop == prop }) { props[i].progress = v }
            case .propMove(let prop, let dx, let height, let duration, _) where beat.time + duration <= target:
                if let i = props.firstIndex(where: { $0.prop == prop }) {
                    props[i].dx = dx
                    props[i].height = height
                }
                _ = duration
            default:
                break
            }
        }
        camera = cameraNow
        letterbox = letterboxNow
        // Re-arma los spans que quedan en vuelo en el destino.
        for beat in s.beats where beat.time <= target {
            let spanDuration: Double?
            switch beat.action {
            case .moveTo(_, let d, _), .heightTo(_, let d, _), .camera(_, _, _, let d),
                 .letterbox(_, let d), .timeScale(_, let d), .drawProgress(_, let d),
                 .houseProgress(_, let d), .propMove(_, _, _, let d, _):
                spanDuration = d
            default:
                spanDuration = nil
            }
            if let d = spanDuration, beat.time + d > target {
                startSpan(for: beat, alreadyElapsed: target - beat.time)
            }
        }
        syncFrame()
    }

    // MARK: Reloj propio

    /// Lo llama el coordinador una vez por fotograma (60 fps), DESPUES
    /// del tick del controlador (que con el hold activo solo avanza
    /// fase/animTime/particulas del mundo).
    func tick(deltaTime dt: Double, stageWidth: CGFloat) {
        guard isPlaying, let s = scene, let stage = stage else { return }
        self.stageWidth = stageWidth

        // timeScale: los spans de escala se evaluan con dt real.
        updateSpans(dt: dt, kinds: [.timeScale])
        let rate = timeScale
        let sdt = dt * rate                     // delta en tiempo de escena
        elapsed += sdt

        // Beats instantaneos cuyo instante ya llego (respetando la rama).
        while beatIndex < s.beats.count && s.beats[beatIndex].time <= elapsed {
            let beat = s.beats[beatIndex]
            beatIndex += 1
            let branchOK = beat.branch == .always
                || (beat.branch == .onlyTruce && tookTruce)
                || (beat.branch == .onlyNoTruce && !tookTruce)
            if branchOK { dispatch(beat) }
        }

        // Spans en curso (en tiempo de escena).
        updateSpans(dt: sdt, kinds: [.moveX, .height, .camera, .letterbox, .drawProgress, .houseProgress, .propMove])

        // Subtitulo: caduca por reloj de escena.
        if let _ = currentSubtitle, elapsed > subtitleUntil { currentSubtitle = nil }

        // Ventana de tregua: si caduca sin aceptarla, el duelo sigue su guion.
        if truceOffered && elapsed > truceWindowUntil { truceOffered = false }

        // Pose impuesta: muestreada con el reloj de escena.
        if !finished {
            stage.stageSetPoseOverride(currentOverridePose())
        }

        // Particulas propias de la capa (ParticleSystem del proyecto).
        fx.tick(dt: sdt)
        fxParticles = fx.particles

        syncFrame()

        if elapsed >= s.effectiveDuration {
            finish(skipped: false)
        }
    }

    private func syncFrame() {
        guard let stage = stage else { return }
        frameX = stage.stageX
        frameHeight = stage.stageHeight
        framePlatform = stage.stagePlatformHeight
        frameFacing = stage.stageFacing
    }

    private func currentOverridePose() -> SkeletonPose? {
        let t = elapsed - poseSourceStart
        switch poseSource {
        case .followStage:
            return nil
        case .action(let a):
            return AnimationLibrary.clip(for: a).sample(at: t)
        case .clip(let clip):
            return clip.sample(at: t)
        case .pose(let pose):
            return pose
        }
    }

    // MARK: Beats

    private func dispatch(_ beat: CinematicBeat) {
        switch beat.action {
        case .poseSource(_), .stageAction(_), .setPower(_), .setAura(_), .face(_), .subtitle(_, _), .haptic(_), .particles(_, _, _), .propShow(_, _, _, _), .propHide(_), .propProgress(_, _), .label(_), .offerTruce, .callback(_):
            applyInstant(beat.action, replay: false)
        case .moveTo(_, _, _), .heightTo(_, _, _), .camera(_, _, _, _), .letterbox(_, _), .timeScale(_, _), .drawProgress(_, _), .houseProgress(_, _), .propMove(_, _, _, _, _):
            startSpan(for: beat, alreadyElapsed: 0)
        }
    }

    private func applyInstant(_ action: CinematicBeatAction, replay: Bool) {
        guard let stage = stage else { return }
        switch action {
        case .poseSource(let source):
            poseSource = source
            poseSourceStart = elapsed
        case .stageAction(let a):
            stage.stageSetAction(a)
        case .setPower(let p):
            stage.stageSetPower(p)
        case .setAura(let on):
            stage.stageSetAura(on)
        case .face(let f):
            stage.stageFacing = f
        case .subtitle(let text, let seconds):
            if !replay {
                currentSubtitle = text
                subtitleUntil = elapsed + seconds
            }
        case .haptic(let kind):
            if !replay { fireHaptic(kind) }
        case .particles(let kind, let count, let anchor):
            if !replay {
                fx.emit(origin: anchorPoint(anchor), kind: kind, count: count,
                        spread: 46, baseVelocity: CGVector(dx: 0, dy: 26))
            }
        case .propShow(let prop, let dx, let height, let scale):
            upsertProp(CinematicPropState(prop: prop, dx: dx, height: height, scale: scale))
        case .propHide(let prop):
            props.removeAll { $0.prop == prop }
        case .propProgress(let prop, let v):
            if let i = props.firstIndex(where: { $0.prop == prop }) { props[i].progress = v }
        case .label(_):
            break
        case .offerTruce:
            if !replay {
                truceOffered = true
                truceWindowUntil = elapsed + 3.0
            }
        case .callback(let cb):
            applyCallback(cb, stage: stage)
        default:
            break
        }
    }

    private func applyCallback(_ cb: CinematicCallback, stage: CinematicStage) {
        switch cb {
        case .bornAlive:
            stage.stageSetHidden(false)
            stage.stageBringToLife()
        case .hideCharacter(let hidden):
            stage.stageSetHidden(hidden)
        case .unlockAwakening:
            CinematicSeenStore.awakeningUnlocked = true
            stage.stageSetAura(true)
        case .ensureRock:
            stage.stageEnsureObject(.block)
        case .persistentBrokenBox:
            CinematicWorldDecor.shared.placeBrokenBox(atFraction: Double(stage.stageX / max(1, stageWidth)) + 0.10)
        case .persistentHouse:
            // La casita se dibuja 92 pt a su derecha durante la escena:
            // el decorado persistente va en ese mismo sitio.
            CinematicWorldDecor.shared.placeHouse(atFraction: Double((stage.stageX + 92) / max(1, stageWidth)))
        }
    }

    private func anchorPoint(_ anchor: CinematicAnchor) -> CGPoint {
        guard let stage = stage else { return .zero }
        let baseHeight = stage.stagePlatformHeight + stage.stageHeight
        switch anchor {
        case .character:
            return CGPoint(x: stage.stageX, y: baseHeight + 56)
        case .head:
            return CGPoint(x: stage.stageX, y: baseHeight + 150)
        case .hands:
            return CGPoint(x: stage.stageX + stage.stageFacing * 42, y: baseHeight + 88)
        case .feet:
            return CGPoint(x: stage.stageX, y: baseHeight + 6)
        case .groundFront:
            return CGPoint(x: stage.stageX + stage.stageFacing * 60, y: baseHeight + 10)
        }
    }

    private func fireHaptic(_ kind: CinematicHaptic) {
        switch kind {
        case .light: impactLight.impactOccurred()
        case .medium: impactMedium.impactOccurred()
        case .heavy: impactHeavy.impactOccurred()
        case .selection: selection.selectionChanged()
        case .success: notify.notificationOccurred(.success)
        case .warning: notify.notificationOccurred(.warning)
        }
    }

    private func upsertProp(_ state: CinematicPropState) {
        if let i = props.firstIndex(where: { $0.prop == state.prop }) {
            props[i] = state
        } else {
            props.append(state)
        }
    }

    // MARK: Spans (interpolaciones con reloj de escena)

    private enum SpanKind { case moveX, height, camera, letterbox, timeScale, drawProgress, houseProgress, propMove }

    private struct ActiveSpan {
        var kind: SpanKind
        var startTime: Double        // instante de escena en que arranco el beat
        var duration: Double
        var easing: AnimEasing
        // valores (segun kind)
        var fromX: CGFloat = 0, toX: CGFloat = 0
        var fromH: CGFloat = 0, toH: CGFloat = 0
        var fromCam = CinematicCamera.identity, toCam = CinematicCamera.identity
        var fromD: Double = 0, toD: Double = 0
        var prop: CinematicProp?
        var fromDX: CGFloat = 0, fromHeight: CGFloat = 0
    }

    private func startSpan(for beat: CinematicBeat, alreadyElapsed: Double) {
        guard let stage = stage else { return }
        var span: ActiveSpan?
        switch beat.action {
        case .moveTo(let fraction, let duration, let easing):
            span = ActiveSpan(kind: .moveX, startTime: beat.time, duration: duration, easing: easing,
                              fromX: stage.stageX, toX: CGFloat(fraction) * stageWidth)
        case .heightTo(let h, let duration, let easing):
            span = ActiveSpan(kind: .height, startTime: beat.time, duration: duration, easing: easing,
                              fromH: stage.stageHeight, toH: h)
        case .camera(let sc, let fx, let fy, let duration):
            span = ActiveSpan(kind: .camera, startTime: beat.time, duration: duration, easing: .easeInOut,
                              fromCam: camera, toCam: CinematicCamera(scale: CGFloat(sc), focusX: fx, focusY: fy))
        case .letterbox(let amount, let duration):
            span = ActiveSpan(kind: .letterbox, startTime: beat.time, duration: duration, easing: .easeInOut,
                              fromD: letterbox, toD: amount)
        case .timeScale(let value, let duration):
            span = ActiveSpan(kind: .timeScale, startTime: beat.time, duration: max(0.01, duration), easing: .linear,
                              fromD: timeScale, toD: value)
        case .drawProgress(let v, let duration):
            span = ActiveSpan(kind: .drawProgress, startTime: beat.time, duration: duration, easing: .linear,
                              fromD: drawProgress, toD: v)
        case .houseProgress(let v, let duration):
            span = ActiveSpan(kind: .houseProgress, startTime: beat.time, duration: duration, easing: .linear,
                              fromD: houseProgress, toD: v)
        case .propMove(let prop, let dx, let height, let duration, let easing):
            if let current = props.first(where: { $0.prop == prop }) {
                span = ActiveSpan(kind: .propMove, startTime: beat.time, duration: duration, easing: easing,
                                  prop: prop, fromDX: current.dx, fromHeight: current.height)
                span?.toX = dx
                span?.toH = height
            }
        default:
            break
        }
        if var span = span {
            // Al re-armar en un resync, el span ya lleva parte recorrida:
            // se descuenta moviendo su instante de arranque hacia atras.
            span.startTime = elapsed - alreadyElapsed
            spans.append(span)
        }
    }

    private func updateSpans(dt: Double, kinds: [SpanKind]) {
        guard let stage = stage else { return }
        var remaining: [ActiveSpan] = []
        for span in spans {
            if !kinds.contains(span.kind) {
                remaining.append(span)
                continue
            }
            let spanElapsed = elapsed - span.startTime
            let raw = span.duration > 0.001 ? spanElapsed / span.duration : 1
            let f = CGFloat(span.easing.apply(min(1, max(0, raw))))
            switch span.kind {
            case .moveX:
                stage.stageX = span.fromX + (span.toX - span.fromX) * f
            case .height:
                stage.stageHeight = span.fromH + (span.toH - span.fromH) * f
            case .camera:
                camera = span.fromCam.lerped(to: span.toCam, t: f)
            case .letterbox:
                letterbox = span.fromD + (span.toD - span.fromD) * Double(f)
            case .timeScale:
                timeScale = span.fromD + (span.toD - span.fromD) * Double(f)
            case .drawProgress:
                drawProgress = span.fromD + (span.toD - span.fromD) * Double(f)
            case .houseProgress:
                houseProgress = span.fromD + (span.toD - span.fromD) * Double(f)
            case .propMove:
                if let prop = span.prop, let i = props.firstIndex(where: { $0.prop == prop }) {
                    props[i].dx = span.fromDX + (span.toX - span.fromDX) * f
                    props[i].height = span.fromHeight + (span.toH - span.fromHeight) * f
                }
            }
            if raw < 1 { remaining.append(span) }
        }
        spans = remaining
    }
}

// MARK: - Coordinador: disparadores y ciclo de vida
//
// Sustituye la llamada a `tco.tick(...)` de ContentView por la suya
// (ver INTEGRATION.md): si hay escena, el controlador recibe su tick
// normal (con el hold, solo avanza relojes) y despues avanza el player;
// si no hay escena, evalua los disparadores que se pueden observar
// desde fuera (entradas en .sleeping) y deja pasar el tick normal.

final class CinematicCoordinator: ObservableObject {
    let player = CinematicPlayer()
    let decor = CinematicWorldDecor.shared

    private weak var controller: StickmanController?
    private var stageSize: CGSize = CGSize(width: 390, height: 600)

    // Contadores de disparadores (solo memoria de sesion, a proposito)
    private var grabTimestamps: [Date] = []
    private var kindStrokeCount = 0
    private var sleepEntryCount = 0
    private var lastStageAction: StickmanAction = .drawn
    private var lastAutoPlay: [CinematicSceneID: Date] = [:]
    private var freeModeUnlockNotified = false

    func attach(controller: StickmanController) {
        self.controller = controller
        lastStageAction = controller.action
        player.onSceneFinished = { [weak self] id, _ in
            self?.lastAutoPlay[id] = Date()
        }
    }

    /// Tick unico de la escena (60 fps). Llamar en el mismo sitio donde
    /// hoy ContentView llama a `tco.tick(deltaTime:stageWidth:stageHeight:)`.
    func tick(deltaTime dt: Double, stageWidth: CGFloat, stageHeight: CGFloat) {
        guard let c = controller else { return }
        stageSize = CGSize(width: stageWidth, height: stageHeight)
        c.tick(deltaTime: dt, stageWidth: stageWidth, stageHeight: stageHeight)
        if player.isPlaying {
            player.tick(deltaTime: dt, stageWidth: stageWidth)
        } else {
            observeTriggers(controller: c)
        }
    }

    // MARK: Reproduccion

    @discardableResult
    func play(_ scene: CinematicScene) -> Bool {
        guard let c = controller, !player.isPlaying else { return false }
        player.begin(scene: scene, stage: c, stageWidth: stageSize.width)
        return player.isPlaying
    }

    @discardableResult
    func play(id: CinematicSceneID) -> Bool {
        play(CinematicCatalog.scene(id))
    }

    /// Flujo de "Darle vida": la primera vez, la consola falsa desemboca
    /// en Nacimiento (que llama a bringToLife desde dentro, en su beat
    /// .bornAlive); si ya se vio, vida normal directa.
    func birthFlow() {
        guard let c = controller else { return }
        if CinematicSeenStore.autoTriggersEnabled && !CinematicSeenStore.isSeen(.nacimiento) {
            if play(id: .nacimiento) { return }
        }
        c.bringToLife()
    }

    // MARK: Ganchos de disparadores (los llama ContentView, ver INTEGRATION)

    /// Cada vez que el usuario agarra al personaje (beginDrag del gesto).
    /// 3 agarres en menos de 12 s -> Duelo con el dedo (con enfriamiento).
    func noteGrab() {
        guard CinematicSeenStore.autoTriggersEnabled, !player.isPlaying else { return }
        let now = Date()
        grabTimestamps.append(now)
        grabTimestamps.removeAll { now.timeIntervalSince($0) > 12 }
        if grabTimestamps.count >= 3 {
            grabTimestamps.removeAll()
            if autoCooldownPassed(.dueloConElDedo, seconds: 90) {
                play(id: .dueloConElDedo)
            }
        }
    }

    /// Un trazo amable terminado en modo lapiz (sin pegarle).
    func noteKindStrokeFinished() {
        guard CinematicSeenStore.autoTriggersEnabled, !player.isPlaying else { return }
        kindStrokeCount += 1
        if kindStrokeCount >= 3 {
            kindStrokeCount = 0
            if autoCooldownPassed(.dibujamosJuntos, seconds: 120) {
                play(id: .dibujamosJuntos)
            }
        }
    }

    /// Pegarle (toque brusco / arrastre con lanzamiento) rompe la racha amable.
    func noteRoughTouch() {
        kindStrokeCount = 0
    }

    /// Boton "Awakening" de la barra de sugerencias: la primera vez es
    /// la escena Despertar; despues, comportamiento normal del proyecto.
    func noteAwakenButton() {
        guard let c = controller else { return }
        if CinematicSeenStore.autoTriggersEnabled && !CinematicSeenStore.isSeen(.despertarSecondComing) {
            if play(id: .despertarSecondComing) { return }
        }
        c.suggestAwakening()
    }

    /// El proyecto no tiene hoy una bandera unica de "modo libre
    /// completo": quien integre decide el momento (INTEGRATION sugiere
    /// el primer uso del modo flotante PiP) y llama a esto una vez.
    func noteFreeModeUnlocked() {
        guard !freeModeUnlockNotified else { return }
        freeModeUnlockNotified = true
        guard CinematicSeenStore.autoTriggersEnabled,
              !CinematicSeenStore.isSeen(.escapeDeLaCaja),
              !player.isPlaying else { return }
        play(id: .escapeDeLaCaja)
    }

    // MARK: Observacion pasiva

    private func observeTriggers(controller c: StickmanController) {
        // El sueno: contar ENTRADAS en .sleeping (ciclos de dormir de
        // verdad, no el descanso obligatorio .resting). A la tercera,
        // si toca, la escena entra sola (la vista ya lo esta durmiendo:
        // la escena arranca con el durmiendo, sin teletransporte raro).
        if c.action == .sleeping && lastStageAction != .sleeping {
            sleepEntryCount += 1
            if sleepEntryCount >= 3 {
                sleepEntryCount = 0
                if CinematicSeenStore.autoTriggersEnabled && autoCooldownPassed(.elSueno, seconds: 600) {
                    play(id: .elSueno)
                }
            }
        }
        lastStageAction = c.action
    }

    private func autoCooldownPassed(_ id: CinematicSceneID, seconds: TimeInterval) -> Bool {
        guard let last = lastAutoPlay[id] else { return true }
        return Date().timeIntervalSince(last) > seconds
    }
}

// MARK: - Capa cinematografica (overlay)
//
// Se coloca SOBRE el lienzo (StickmanCanvasView) y dentro del mismo
// espacio de coordenadas. Dibuja: decorado persistente, bandas de cine,
// props, la figura "a medio dibujar" de Nacimiento, la burbuja de El
// sueno, la casita en curso, particulas propias y subtitulos. Botones:
// Saltar (siempre), Tregua (cuando el Duelo la ofrece). Sin escena en
// curso solo dibuja el decorado y no intercepta toques.

struct CinematicOverlayView: View {
    @ObservedObject var player: CinematicPlayer
    @ObservedObject var decor: CinematicWorldDecor

    init(coordinator: CinematicCoordinator) {
        self.player = coordinator.player
        self.decor = coordinator.decor
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, size in
                    drawDecor(context: &context, size: size)
                    if player.isPlaying {
                        drawCinematicLayer(context: &context, size: size)
                    }
                }
                .allowsHitTesting(false)

                if player.isPlaying {
                    letterboxBars(size: geo.size)
                    subtitleView(size: geo.size)
                    skipButton
                    if player.truceOffered { truceButton(size: geo.size) }
                    if player.scene?.id == .elSueno {
                        // Toque = despertarle (salta a la etiqueta "despertar").
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { player.handleOverlayTap() }
                    }
                }
            }
        }
    }

    // MARK: Piezas de interfaz

    private func letterboxBars(size: CGSize) -> some View {
        let barHeight = size.height * 0.11 * CGFloat(player.letterbox)
        return VStack(spacing: 0) {
            Rectangle().fill(Color.black).frame(height: barHeight)
            Spacer()
            Rectangle().fill(Color.black).frame(height: barHeight)
        }
        .allowsHitTesting(false)
        .animation(.linear(duration: 0.1), value: player.letterbox)
    }

    private func subtitleView(size: CGSize) -> some View {
        VStack {
            Spacer()
            if let text = player.currentSubtitle {
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color.black.opacity(0.72))
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.bottom, size.height * 0.11 + 18)
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { player.skip() }) {
                    HStack(spacing: 5) {
                        Text("Saltar")
                        Image(systemName: "forward.fill")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 13).padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                }
                .padding(.top, 10).padding(.trailing, 12)
                .accessibilityLabel("Saltar cinematica")
            }
            Spacer()
        }
    }

    private func truceButton(size: CGSize) -> some View {
        VStack {
            Spacer()
            Button(action: { player.acceptTruce() }) {
                Text("🤝 Tregua")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(Color.yellow)
                    .cornerRadius(18)
                    .shadow(radius: 5)
            }
            .padding(.bottom, size.height * 0.11 + 64)
        }
    }

    // MARK: Dibujo (Canvas)

    private func groundY(size: CGSize) -> CGFloat { size.height - 10 }
    private func charGroundY(size: CGSize) -> CGFloat {
        groundY(size: size) - player.framePlatform - player.frameHeight
    }

    private func drawDecor(context: inout GraphicsContext, size: CGSize) {
        let gy = groundY(size: size)
        if let fraction = decor.brokenBoxFraction {
            drawBrokenBox(context: &context, cx: CGFloat(fraction) * size.width, groundY: gy)
        }
        if let fraction = decor.houseFraction {
            drawHouse(context: &context, cx: CGFloat(fraction) * size.width, groundY: gy, progress: 1)
        }
    }

    private func drawCinematicLayer(context: inout GraphicsContext, size: CGSize) {
        let gy = groundY(size: size)
        let cgy = charGroundY(size: size)
        let cx = player.frameX

        // La casita de Dibujamos se traza sobre el personaje (a su lado).
        if player.scene?.id == .dibujamosJuntos && player.houseProgress > 0 {
            drawHouse(context: &context, cx: cx + 92, groundY: gy, progress: player.houseProgress)
        }

        // Nacimiento: el cuerpo a medio dibujar (la capa lo pinta; el real esta oculto).
        if player.scene?.id == .nacimiento && player.drawProgress > 0 && player.drawProgress < 1 {
            drawBeingDrawn(context: &context, cx: cx, groundY: cgy, progress: player.drawProgress)
        }

        for prop in player.props {
            drawProp(context: &context, prop: prop, cx: cx, charGroundY: cgy, size: size)
        }

        // Particulas propias (mismo convenio que StickmanView.drawParticles).
        for particle in player.fxParticles {
            var ctx = context
            ctx.opacity = particle.opacity
            let center = CGPoint(x: particle.position.x, y: gy - particle.position.y)
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - particle.size / 2, y: center.y - particle.size / 2,
                                            width: particle.size, height: particle.size)),
                     with: .color(particle.color))
        }
    }

    private func drawProp(context: inout GraphicsContext, prop: CinematicPropState, cx: CGFloat, charGroundY: CGFloat, size: CGSize) {
        let x = cx + prop.dx
        let gy = groundY(size: size)
        let baseY = gy - prop.height
        switch prop.prop {
        case .selectionBox:
            // La misma caja de seleccion azul de la vista principal, con grieta segun progress.
            var box = Path()
            box.addRect(CGRect(x: cx - 46, y: charGroundY - 150, width: 92, height: 150))
            context.stroke(box, with: .color(.blue.opacity(0.8)), style: StrokeStyle(lineWidth: 1.8, dash: [6, 4]))
            for corner in [CGPoint(x: cx - 46, y: charGroundY - 150), CGPoint(x: cx + 46, y: charGroundY - 150),
                           CGPoint(x: cx - 46, y: charGroundY), CGPoint(x: cx + 46, y: charGroundY)] {
                context.fill(Path(ellipseIn: CGRect(x: corner.x - 3.5, y: corner.y - 3.5, width: 7, height: 7)), with: .color(.blue))
            }
            if prop.progress > 0 {
                var crack = Path()
                let topY = charGroundY - 150
                crack.move(to: CGPoint(x: cx + 46, y: topY + 6))
                crack.addLine(to: CGPoint(x: cx + 34, y: topY + 26))
                if prop.progress > 0.35 { crack.addLine(to: CGPoint(x: cx + 42, y: topY + 48)) }
                if prop.progress > 0.65 { crack.addLine(to: CGPoint(x: cx + 30, y: topY + 74)) }
                context.stroke(crack, with: .color(.blue), lineWidth: 2.2)
            }
        case .pencil:
            // Cursor-lapiz: triangulo de madera + punta, inclinado, con vaiven de trazo.
            let bob = CGFloat(sin(player.elapsed * 7)) * 3
            var p = Path()
            let tip = CGPoint(x: x, y: baseY + bob)
            p.move(to: tip)
            p.addLine(to: CGPoint(x: tip.x + 10, y: tip.y - 26))
            p.addLine(to: CGPoint(x: tip.x + 24, y: tip.y - 20))
            p.addLine(to: CGPoint(x: tip.x + 13, y: tip.y + 4))
            p.closeSubpath()
            context.fill(p, with: .color(Color(red: 0.98, green: 0.75, blue: 0.25)))
            var lead = Path()
            lead.move(to: tip); lead.addLine(to: CGPoint(x: tip.x + 5, y: tip.y - 9)); lead.addLine(to: CGPoint(x: tip.x + 10, y: tip.y - 2)); lead.closeSubpath()
            context.fill(lead, with: .color(.black))
        case .finger:
            // El dedo antagonista: cursor grande del proyecto, hecho trazo.
            var p = Path()
            let w: CGFloat = 17 * prop.scale
            let top = baseY - 74 * prop.scale
            p.move(to: CGPoint(x: x - w * 0.4, y: baseY))
            p.addLine(to: CGPoint(x: x - w * 0.4, y: top + 26 * prop.scale))
            p.addQuadCurve(to: CGPoint(x: x + w * 0.4, y: top + 26 * prop.scale),
                           control: CGPoint(x: x, y: top - 8 * prop.scale))
            p.addLine(to: CGPoint(x: x + w * 0.4, y: baseY))
            context.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 4.5 * prop.scale, lineCap: .round))
            var nail = Path()
            nail.addEllipse(in: CGRect(x: x - w * 0.22, y: top + 8 * prop.scale, width: w * 0.44, height: 13 * prop.scale))
            context.stroke(nail, with: .color(.black), lineWidth: 2.5)
        case .hammer:
            var p = Path()
            p.move(to: CGPoint(x: x - 6, y: gy)); p.addLine(to: CGPoint(x: x + 6, y: gy - 20))
            context.stroke(p, with: .color(.brown), lineWidth: 3.5)
            context.stroke(Path(CGRect(x: x, y: gy - 29, width: 18, height: 10)), with: .color(.gray), lineWidth: 3.5)
        case .groundCrack:
            let spread = CGFloat(prop.progress) * 64
            var p = Path()
            p.move(to: CGPoint(x: x - spread, y: gy - 1))
            p.addLine(to: CGPoint(x: x - spread * 0.4, y: gy - 4))
            p.addLine(to: CGPoint(x: x, y: gy - 1))
            p.addLine(to: CGPoint(x: x + spread * 0.5, y: gy - 5))
            p.addLine(to: CGPoint(x: x + spread, y: gy - 2))
            context.stroke(p, with: .color(.black), lineWidth: 2.2)
            var branch = Path()
            branch.move(to: CGPoint(x: x, y: gy - 1)); branch.addLine(to: CGPoint(x: x + spread * 0.25, y: gy + 3))
            context.stroke(branch, with: .color(.black), lineWidth: 1.6)
        case .dreamGiant, .dreamFlight:
            drawDreamBubble(context: &context, headX: cx, charGroundY: charGroundY, flight: prop.prop == .dreamFlight, progress: prop.progress)
        case .drawnPencil, .userPencil:
            var p = Path()
            let base = CGPoint(x: x, y: baseY)
            p.move(to: base)
            p.addLine(to: CGPoint(x: base.x + 6, y: base.y - 17))
            p.addLine(to: CGPoint(x: base.x + 16, y: base.y - 12))
            p.addLine(to: CGPoint(x: base.x + 8, y: base.y + 3))
            p.closeSubpath()
            let color: Color = prop.prop == .drawnPencil ? .orange : Color(red: 0.2, green: 0.5, blue: 0.95)
            context.fill(p, with: .color(color))
        }
    }

    /// La figura "a medio dibujar" de Nacimiento: 6 trazos propios
    /// (cabeza, torso, brazo I, brazo D, pierna I, pierna D) que se
    /// revelan en orden segun `progress`. Al llegar a 1, el beat
    /// .bornAlive muestra el cuerpo real y esta figura desaparece.
    private func drawBeingDrawn(context: inout GraphicsContext, cx: CGFloat, groundY: CGFloat, progress: Double) {
        let hip = CGPoint(x: cx, y: groundY - 56)
        let neck = CGPoint(x: cx, y: groundY - 98)
        let headC = CGPoint(x: cx, y: groundY - 121)
        let tremor = progress > 0.82 ? CGFloat(sin(player.elapsed * 26)) * 1.6 : 0
        let segments: [(CGPoint, CGPoint)] = [
            (neck, CGPoint(x: hip.x, y: hip.y)),                                        // torso (la cabeza es arco aparte)
            (neck, CGPoint(x: cx - 20 + tremor, y: groundY - 58)),
            (neck, CGPoint(x: cx + 20 - tremor, y: groundY - 58)),
            (hip, CGPoint(x: cx - 13, y: groundY)),
            (hip, CGPoint(x: cx + 13, y: groundY)),
        ]
        // Trazo 0: la cabeza (arco). Trazos 1-5: los segmentos.
        let headFraction = min(1, max(0, progress * 6))
        if headFraction > 0 {
            var head = Path()
            head.addArc(center: CGPoint(x: headC.x + tremor * 0.4, y: headC.y), radius: 20,
                        startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * headFraction), clockwise: false)
            context.stroke(head, with: .color(Color(red: 0.945, green: 0.506, blue: 0.047)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        }
        for i in segments.indices {
            let f = min(1, max(0, progress * 6 - Double(i + 1)))
            if f <= 0 { continue }
            let a = segments[i].0
            let b = segments[i].1
            var p = Path()
            p.move(to: a)
            p.addLine(to: CGPoint(x: a.x + (b.x - a.x) * CGFloat(f), y: a.y + (b.y - a.y) * CGFloat(f)))
            context.stroke(p, with: .color(Color(red: 0.945, green: 0.506, blue: 0.047)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        }
    }

    private func drawBrokenBox(context: inout GraphicsContext, cx: CGFloat, groundY: CGFloat) {
        // La esquina rota que queda en el mundo tras Escape.
        var p = Path()
        p.move(to: CGPoint(x: cx - 40, y: groundY))
        p.addLine(to: CGPoint(x: cx - 40, y: groundY - 62))
        p.addLine(to: CGPoint(x: cx - 14, y: groundY - 62))
        p.addLine(to: CGPoint(x: cx - 22, y: groundY - 38))
        p.addLine(to: CGPoint(x: cx - 8, y: groundY - 22))
        p.addLine(to: CGPoint(x: cx - 26, y: groundY))
        context.stroke(p, with: .color(.blue.opacity(0.55)), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
    }

    /// Casita de trazo (la misma silueta que el doorHouse del mundo, a
    /// mayor tamano): se revela por tramos segun `progress`:
    /// paredes -> tejado -> puerta -> ventana/chimenea.
    private func drawHouse(context: inout GraphicsContext, cx: CGFloat, groundY: CGFloat, progress: Double) {
        let w: CGFloat = 96, h: CGFloat = 74
        let left = cx - w / 2, right = cx + w / 2, top = groundY - h
        func seg(_ upto: Double, _ draw: (inout Path) -> Void) {
            guard progress > upto - 0.25 else { return }
            var p = Path()
            draw(&p)
            context.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        }
        seg(0.25) { p in p.move(to: CGPoint(x: left, y: groundY)); p.addLine(to: CGPoint(x: left, y: top)); p.addLine(to: CGPoint(x: right, y: top)); p.addLine(to: CGPoint(x: right, y: groundY)) }
        seg(0.50) { p in p.move(to: CGPoint(x: left - 8, y: top)); p.addLine(to: CGPoint(x: cx, y: top - 24)); p.addLine(to: CGPoint(x: right + 8, y: top)) }
        seg(0.75) { p in p.addRect(CGRect(x: cx - 11, y: groundY - 34, width: 22, height: 34)) }
        seg(1.0) { p in
            p.addRect(CGRect(x: left + 12, y: top + 14, width: 16, height: 16))
            p.move(to: CGPoint(x: right - 20, y: top - 14)); p.addLine(to: CGPoint(x: right - 20, y: top - 26)); p.addLine(to: CGPoint(x: right - 8, y: top - 26))
        }
        if progress >= 1 {
            var sun = Path()
            sun.addEllipse(in: CGRect(x: right + 16, y: top - 34, width: 17, height: 17))
            context.stroke(sun, with: .color(Color(red: 0.95, green: 0.7, blue: 0.15)), lineWidth: 3)
        }
    }

    private func drawDreamBubble(context: inout GraphicsContext, headX: CGFloat, charGroundY: CGFloat, flight: Bool, progress: Double) {
        let r: CGFloat = 52
        let center = CGPoint(x: headX + 74, y: charGroundY - 196)
        var ctx = context
        ctx.opacity = 0.92
        ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(Color(red: 0.45, green: 0.65, blue: 0.95)), lineWidth: 2.5)
        ctx.fill(Path(ellipseIn: CGRect(x: headX + 28, y: charGroundY - 148, width: 13, height: 13)), with: .color(Color(red: 0.45, green: 0.65, blue: 0.95).opacity(0.7)))
        ctx.fill(Path(ellipseIn: CGRect(x: headX + 42, y: charGroundY - 162, width: 19, height: 19)), with: .color(Color(red: 0.45, green: 0.65, blue: 0.95).opacity(0.8)))
        // Mini-figura dentro de la burbuja (trazo azul, como un sueno).
        let s: CGFloat = flight ? 0.55 : 0.95   // gigante = figura grande apretada; vuelo = figura pequena entre nubes
        let hip = CGPoint(x: center.x, y: center.y + 16 * s)
        let neck = CGPoint(x: center.x, y: center.y - 14 * s)
        var p = Path()
        p.move(to: hip); p.addLine(to: neck)
        p.move(to: hip); p.addLine(to: CGPoint(x: center.x - 13 * s, y: center.y + 34 * s))
        p.move(to: hip); p.addLine(to: CGPoint(x: center.x + 13 * s, y: center.y + 34 * s))
        if flight {
            p.move(to: neck); p.addLine(to: CGPoint(x: center.x - 22 * s, y: center.y - 22 * s))
            p.move(to: neck); p.addLine(to: CGPoint(x: center.x + 22 * s, y: center.y - 22 * s))
            for dx in [-30.0, 6.0, 30.0] {
                let cy = center.y + CGFloat(30 + (dx == 6.0 ? -38 : 0))
                p.move(to: CGPoint(x: center.x + CGFloat(dx) - 12, y: cy))
                p.addQuadCurve(to: CGPoint(x: center.x + CGFloat(dx) + 12, y: cy), control: CGPoint(x: center.x + CGFloat(dx), y: cy - 9))
            }
        } else {
            p.move(to: neck); p.addLine(to: CGPoint(x: center.x - 18 * s, y: center.y + 8 * s))
            p.move(to: neck); p.addLine(to: CGPoint(x: center.x + 18 * s, y: center.y + 8 * s))
        }
        ctx.stroke(p, with: .color(Color(red: 0.3, green: 0.55, blue: 0.9)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        // Cabeza HUECA (anillo, interior vacio): es el diseno de SU TSC
        // (correccion del usuario 2026-11-11, DISENO-TCO.md), no llena.
        ctx.stroke(Path(ellipseIn: CGRect(x: center.x - 11 * s, y: center.y - 36 * s, width: 22 * s, height: 22 * s)),
                   with: .color(Color(red: 0.3, green: 0.55, blue: 0.9)), lineWidth: 3.2)
    }
}

// MARK: - Menu "Cinematicas"
//
// Lista de las 6 escenas con su estado (vista / sin ver), duracion y
// boton de reproduccion. Se presenta como sheet desde ContentView
// (ver INTEGRATION.md). Reproducir cierra el menu y arranca la escena.

struct CinematicMenuView: View {
    @ObservedObject var coordinator: CinematicCoordinator
    @ObservedObject var player: CinematicPlayer
    @Environment(\.presentationMode) private var presentationMode

    init(coordinator: CinematicCoordinator) {
        self.coordinator = coordinator
        self.player = coordinator.player
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Escenas de The Second Coming")) {
                    ForEach(CinematicCatalog.all) { scene in
                        HStack(spacing: 10) {
                            Image(systemName: player.seenIDs.contains(scene.id.rawValue) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(player.seenIDs.contains(scene.id.rawValue) ? .green : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scene.title).font(.headline)
                                Text(scene.synopsis)
                                    .font(.caption).foregroundColor(.secondary)
                                    .lineLimit(2)
                                Text("~\(Int(scene.duration)) s · \(player.seenIDs.contains(scene.id.rawValue) ? "Vista" : "Sin ver")")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                                coordinator.play(scene)
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                            }
                            .accessibilityLabel("Reproducir \(scene.title)")
                        }
                        .padding(.vertical, 3)
                    }
                }
                Section(footer: Text("Las escenas se disparan solas la primera vez (nacer, desbloquear poderes, portarse mal con el dedo...). Desde aqui puedes repetirlas cuando quieras. Todas se pueden saltar.")) {
                    Toggle("Disparos automaticos", isOn: Binding(
                        get: { CinematicSeenStore.autoTriggersEnabled },
                        set: { CinematicSeenStore.autoTriggersEnabled = $0 }
                    ))
                }
            }
            .navigationTitle("Cinemáticas")
            .navigationBarItems(trailing: Button("Cerrar") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
