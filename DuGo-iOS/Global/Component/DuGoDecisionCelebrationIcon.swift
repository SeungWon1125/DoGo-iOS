//
//  DuGoDecisionCelebrationIcon.swift
//  DuGo-iOS
//

import SwiftUI

struct DuGoDecisionCelebrationIcon: View {
    // MARK: - Types

    private struct Particle: Identifiable {
        let id: Int
        let angle: Double
        let travelDistance: CGFloat
        let size: CGFloat
    }

    // MARK: - Properties

    private let decision: WishDecision
    @State private var isIconVisible = false
    @State private var areParticlesVisible = false
    @State private var areParticlesExpanded = false

    private let particleStartRadius: CGFloat = 41
    private let particleEndScale: CGFloat = 0.65
    private let particleAnimationDuration: Double = 0.40

    private let particles = [
        Particle(
            id: 0,
            angle: -90,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 1,
            angle: -45,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 2,
            angle: 0,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 3,
            angle: 45,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 4,
            angle: 90,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 5,
            angle: 135,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 6,
            angle: 180,
            travelDistance: 56,
            size: 8
        ),
        Particle(
            id: 7,
            angle: 225,
            travelDistance: 56,
            size: 8
        ),
    ]

    // MARK: - Initializer

    init(decision: WishDecision) {
        self.decision = decision
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                particleView(particle)
            }

            ZStack {
                Circle()
                    .fill(DuGoTheme.accent.opacity(0.12))

                DuGoDecisionIcon(
                    decision: decision,
                    size: 38,
                    color: DuGoTheme.accent
                )
            }
            .frame(width: 72, height: 72)
            .scaleEffect(isIconVisible ? 1 : 0.25)
            .opacity(isIconVisible ? 1 : 0)
        }
        .frame(width: 72, height: 72)
        .task(id: decision) {
            await playAnimation()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func particleView(_ particle: Particle) -> some View {
        let angle = particle.angle * .pi / 180
        let width = particle.size * 1.4
        let distance =
            particleStartRadius
            + (areParticlesExpanded ? particle.travelDistance : 0)
        let x = cos(angle) * distance
        let y = sin(angle) * distance

        Capsule()
            .fill(particleColor(for: particle.id))
            .frame(width: width, height: particle.size)
            .rotationEffect(.degrees(particle.angle))
            .offset(x: x, y: y)
            .scaleEffect(areParticlesExpanded ? particleEndScale : 1)
            .opacity(areParticlesVisible && !areParticlesExpanded ? 1 : 0)
            .animation(
                .easeOut(duration: particleAnimationDuration)
                    .delay(Double(particle.id % 3) * 0.025),
                value: areParticlesExpanded
            )
    }

    // MARK: - Methods

    @MainActor
    private func playAnimation() async {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isIconVisible = false
            areParticlesVisible = false
            areParticlesExpanded = false
        }

        await Task.yield()

        withAnimation(.spring(response: 0.48, dampingFraction: 0.40)) {
            isIconVisible = true
        }

        try? await Task.sleep(nanoseconds: 90_000_000)
        guard !Task.isCancelled else { return }

        withTransaction(transaction) {
            areParticlesVisible = true
        }

        await Task.yield()

        withAnimation {
            areParticlesExpanded = true
        }
    }

    private func particleColor(for id: Int) -> Color {
        switch id % 3 {
        case 0: DuGoTheme.accent
        case 1: DuGoTheme.accent
        default: DuGoTheme.accent.opacity(0.5)
        }
    }
}
