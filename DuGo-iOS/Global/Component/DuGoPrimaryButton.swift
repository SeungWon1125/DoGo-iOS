//
//  DuGoPrimaryButton.swift
//  DuGo-iOS
//
//  Created by 김승원 on 20/9/26.
//

import SwiftUI

struct DuGoPrimaryButton: View {
    // MARK: - Properties

    private let title: String
    private let isEnabled: Bool
    private let isLoading: Bool
    private let height: CGFloat
    private let font: DuGoFont
    private let action: () -> Void

    // MARK: - Initializer

    init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        height: CGFloat = 52,
        font: DuGoFont = .button16Medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.height = height
        self.font = font
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .applyDuGoFont(font)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(DuGoTheme.onAccent)
                }
            }
            .foregroundStyle(DuGoTheme.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                isEnabled ? DuGoTheme.accent : DuGoTheme.secondary.opacity(0.4),
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}
