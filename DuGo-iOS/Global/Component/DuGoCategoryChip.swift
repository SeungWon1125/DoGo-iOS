//
//  DuGoCategoryChip.swift
//  DuGo-iOS
//
//  Created by 김승원 on 20/9/26.
//

import SwiftUI

struct DuGoCategoryChip: View {
    // MARK: - Properties

    private let category: String?
    private let isSelected: Bool
    private let action: () -> Void

    // MARK: - Initializer

    init(
        category: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: performWithoutAnimation) {
            Text(category ?? "전체")
                .applyDuGoFont(isSelected ? .button14Medium : .body14Regular)
                .padding(.horizontal, 17)
                .frame(minHeight: 40)
                .foregroundStyle(isSelected ? DuGoTheme.onAccent : DuGoTheme.secondary)
                .background {
                    Capsule()
                        .fill(isSelected ? DuGoTheme.accent : DuGoTheme.surface)
                        .dugoShadow(.subtle)
                }
        }
        .buttonStyle(.plain)
        .animation(nil, value: isSelected)
    }

    private func performWithoutAnimation() {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            action()
        }
    }
}
