//
//  DuGoConfirmationAlert.swift
//  DuGo-iOS
//

import SwiftUI

private struct DuGoConfirmationAlertModifier: ViewModifier {
    // MARK: - Properties

    let title: String
    let message: String
    let confirmTitle: String
    @Binding var isPresented: Bool
    let confirmAction: () -> Void

    // MARK: - Body

    func body(content: Content) -> some View {
        content.background {
            Color.clear
                .alert(title, isPresented: $isPresented) {
                    Button("취소", role: .cancel) {}

                    Button(confirmTitle, role: .destructive, action: confirmAction)
                } message: {
                    Text(message)
                }
                .tint(DuGoTheme.ink)
        }
    }
}

extension View {
    // MARK: - Methods

    func dugoConfirmationAlert(
        title: String,
        message: String,
        confirmTitle: String,
        isPresented: Binding<Bool>,
        confirmAction: @escaping () -> Void
    ) -> some View {
        modifier(
            DuGoConfirmationAlertModifier(
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                isPresented: isPresented,
                confirmAction: confirmAction
            )
        )
    }
}
