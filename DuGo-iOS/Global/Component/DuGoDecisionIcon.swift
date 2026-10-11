//
//  DuGoDecisionIcon.swift
//  DuGo-iOS
//
//  Created by 김승원 on 1/10/26.
//

import SwiftUI

struct DuGoDecisionIcon: View {
    // MARK: - Properties

    private let decision: WishDecision
    private let size: CGFloat
    private let color: Color

    // MARK: - Initializer

    init(
        decision: WishDecision,
        size: CGFloat,
        color: Color = DuGoTheme.ink
    ) {
        self.decision = decision
        self.size = size
        self.color = color
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: decision.symbol)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
