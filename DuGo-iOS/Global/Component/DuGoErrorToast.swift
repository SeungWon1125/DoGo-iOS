//
//  DuGoErrorToast.swift
//  DuGo-iOS
//
//  Created by 김승원 on 1/10/26.
//

import SwiftUI

struct DuGoErrorToast: View {
    // MARK: - Properties

    let message: String

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .applyDuGoFont(.body14Medium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(DuGoTheme.background)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 560, alignment: .leading)
        .background(
            DuGoTheme.ink,
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 12, y: 5)
    }
}

private struct DuGoErrorToastModifier: ViewModifier {
    // MARK: - Properties

    @Binding var message: String?
    @State private var visibleMessage: String?
    @State private var dismissTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let visibleMessage {
                    DuGoErrorToast(message: visibleMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity)
                        )
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
            }
            .onChange(of: message, initial: true) { _, newMessage in
                guard let newMessage, !newMessage.isEmpty else { return }
                present(newMessage)
            }
            .onDisappear {
                dismissTask?.cancel()
            }
    }

    // MARK: - Methods

    private func present(_ newMessage: String) {
        dismissTask?.cancel()

        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            visibleMessage = newMessage
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.2)) {
                if visibleMessage == newMessage {
                    visibleMessage = nil
                }
            }

            if message == newMessage {
                message = nil
            }
        }
    }
}

extension View {
    // MARK: - Methods

    func dugoErrorToast(message: Binding<String?>) -> some View {
        modifier(DuGoErrorToastModifier(message: message))
    }
}
