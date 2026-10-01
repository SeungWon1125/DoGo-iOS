//
//  DuGoDecisionTag.swift
//  DuGo-iOS
//

import SwiftUI

struct DuGoDecisionTag: View {
    // MARK: - Properties

    private let decision: WishDecision
    private let color: Color

    // MARK: - Initializer

    init(decision: WishDecision, color: Color) {
        self.decision = decision
        self.color = color
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            DuGoDecisionIcon(
                decision: decision,
                size: 14,
                color: color
            )

            Text(decision.rawValue)
                .applyDuGoFont(.caption12Medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background {
            Capsule()
                .fill(color.opacity(0.10))
                .dugoShadow(.subtle)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(decision.rawValue)
    }
}
