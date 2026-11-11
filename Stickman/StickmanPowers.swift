import Foundation
import SwiftUI

// MARK: - Poderes como The Chosen One

enum Power: String, CaseIterable {
    case flight        // Volar / despegar con estela
    case fireBreath    // Fuego por manos/boca: quema un objeto dibujado
    case eyeLaser      // Laser por los ojos: corta un objeto por la mitad
    case ice           // Hielo: congela un objeto o un tramo del suelo
    case superPunch    // Superpunetazo + onda de choque: sacude la interfaz
    case superStrength // Superfuerza: levanta y mueve un bloque de la interfaz
    case superSpeed    // Supervelocidad: imagenes fantasma
    case createDestroy // Energia para crear / destruir objetos dibujados

    var label: String {
        switch self {
        case .flight: return "Volar"
        case .fireBreath: return "Fuego"
        case .eyeLaser: return "Láser"
        case .ice: return "Hielo"
        case .superPunch: return "Superpuñetazo"
        case .superStrength: return "Superfuerza"
        case .superSpeed: return "Supervelocidad"
        case .createDestroy: return "Crear/destruir"
        }
    }
}

// MARK: - Objetos dibujados por el propio stickman

enum DrawnObjectKind: String, CaseIterable {
    case sword, ball, chair, table, doorHouse, friend, block, target
    var label: String {
        switch self {
        case .sword: return "espada"; case .ball: return "pelota"; case .chair: return "silla"
        case .table: return "mesa"; case .doorHouse: return "puertita"; case .friend: return "amigo"
        case .block: return "bloque"; case .target: return "blanco"
        }
    }
}

enum DrawnObjectState: String {
    case intact, burning, burnt, frozen, cutInHalf, lifted, gone
}

struct DrawnObject: Identifiable {
    let id = UUID()
    var kind: DrawnObjectKind
    var x: CGFloat              // posicion en el lienzo (relativa al suelo)
    var state: DrawnObjectState = .intact
    var bouncePhase: Double = 0 // para la pelota
}

// MARK: - Sistema de particulas simple (Canvas)

enum ParticleKind { case fire, smoke, ice, spark, trail, zzz, energy, sweat }

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint       // x absoluta aproximada; y = altura sobre el suelo (negativo = arriba NO: usamos offset, ver vista)
    var velocity: CGVector
    var life: Double            // segundos restantes
    var maxLife: Double
    var size: CGFloat
    var kind: ParticleKind

    var opacity: Double { max(0, life / maxLife) }
    var color: Color {
        switch kind {
        case .fire: return .orange
        case .smoke: return .gray
        case .ice: return Color(red: 0.55, green: 0.85, blue: 1.0)
        case .spark: return .yellow
        case .trail: return Color(red: 1.0, green: 0.55, blue: 0.15)
        case .zzz: return .blue
        case .energy: return Color(red: 1.0, green: 0.35, blue: 0.1)
        case .sweat: return .cyan
        }
    }
}

struct ParticleSystem {
    var particles: [Particle] = []

    mutating func emit(origin: CGPoint, kind: ParticleKind, count: Int, spread: CGFloat = 60, baseVelocity: CGVector = CGVector(dx: 0, dy: -40)) {
        for _ in 0..<count {
            let jitterX = CGFloat.random(in: -spread...spread)
            let jitterY = CGFloat.random(in: -spread...spread) * 0.4
            let life = Double.random(in: 0.35...0.9)
            particles.append(Particle(position: CGPoint(x: origin.x + jitterX * 0.3, y: origin.y + jitterY * 0.3),
                                      velocity: CGVector(dx: baseVelocity.dx + jitterX, dy: baseVelocity.dy + jitterY),
                                      life: life, maxLife: life,
                                      size: CGFloat.random(in: 3...8), kind: kind))
        }
        if particles.count > 260 { particles.removeFirst(particles.count - 260) }
    }

    mutating func tick(dt: Double) {
        for i in particles.indices {
            particles[i].life -= dt
            particles[i].position.x += particles[i].velocity.dx * CGFloat(dt)
            particles[i].position.y += particles[i].velocity.dy * CGFloat(dt)
            particles[i].velocity.dy -= 30 * CGFloat(dt) // leve deriva hacia arriba en coordenadas de altura
        }
        particles.removeAll { $0.life <= 0 }
    }
}
