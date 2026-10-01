//
//  View+DuGoStyle.swift
//  DuGo-iOS
//

import SwiftUI

enum DuGoShadowStyle {
    case subtle
    case card
}

private enum DuGoBorderMode {
    static let isEnabled = false
}

private struct DuGoShadowModifier: ViewModifier {
    // MARK: - Properties

    @Environment(\.colorScheme) private var colorScheme

    let style: DuGoShadowStyle

    // MARK: - Computed Properties

    private var opacity: Double {
        switch (style, colorScheme) {
        case (.subtle, .dark): 0.12
        case (.card, .dark): 0.38
        case (.subtle, _): 0.05
        case (.card, _): 0.12
        }
    }

    private var radius: CGFloat {
        switch style {
        case .subtle: 4
        case .card: 12
        }
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .shadow(
                color: .black.opacity(opacity),
                radius: radius,
                y: 0
            )

            .shadow(
                color: colorScheme == .dark ? .white.opacity(0.04) : .clear,
                radius: 2,
                y: 0
            )
    }
}

private struct DuGoRoundedSurfaceModifier: ViewModifier {
    // MARK: - Properties

    let fill: Color
    let cornerRadius: CGFloat
    let borderColor: Color
    let lineWidth: CGFloat
    let clipsContent: Bool
    let shadowStyle: DuGoShadowStyle

    // MARK: - Body

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let styledContent = content.background {
            surfaceBackground(shape)
        }

        if clipsContent {
            decorate(
                content
                    .clipShape(shape)
                    .background { surfaceBackground(shape) },
                with: shape
            )
        } else {
            decorate(styledContent, with: shape)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func surfaceBackground(_ shape: RoundedRectangle) -> some View {
        if lineWidth > 0, !DuGoBorderMode.isEnabled {
            shape
                .fill(fill)
                .dugoShadow(shadowStyle)
        } else {
            shape.fill(fill)
        }
    }

    @ViewBuilder
    private func decorate<Content: View>(
        _ content: Content,
        with shape: RoundedRectangle
    ) -> some View {
        if lineWidth > 0, DuGoBorderMode.isEnabled {
            content.overlay {
                shape.strokeBorder(borderColor, lineWidth: lineWidth)
            }
        } else {
            content
        }
    }
}

extension View {
    // MARK: - Methods

    func dugoRoundedSurface(
        fill: Color = DuGoTheme.surface,
        cornerRadius: CGFloat = 13,
        borderColor: Color = DuGoTheme.border,
        lineWidth: CGFloat = 1,
        clipsContent: Bool = false,
        shadowStyle: DuGoShadowStyle = .subtle
    ) -> some View {
        modifier(
            DuGoRoundedSurfaceModifier(
                fill: fill,
                cornerRadius: cornerRadius,
                borderColor: borderColor,
                lineWidth: lineWidth,
                clipsContent: clipsContent,
                shadowStyle: shadowStyle
            )
        )
    }

    func dugoRoundedBorder(
        cornerRadius: CGFloat = 13,
        color: Color = DuGoTheme.border,
        lineWidth: CGFloat = 1
    ) -> some View {
        modifier(
            DuGoRoundedBorderModifier(
                cornerRadius: cornerRadius,
                color: color,
                lineWidth: lineWidth
            )
        )
    }

    func dugoShadow(_ style: DuGoShadowStyle = .card) -> some View {
        modifier(DuGoShadowModifier(style: style))
    }
}

private struct DuGoRoundedBorderModifier: ViewModifier {
    // MARK: - Properties

    let cornerRadius: CGFloat
    let color: Color
    let lineWidth: CGFloat

    // MARK: - Body

    @ViewBuilder
    func body(content: Content) -> some View {
        if DuGoBorderMode.isEnabled {
            content.overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(color, lineWidth: lineWidth)
            }
        } else {
            content
        }
    }
}
