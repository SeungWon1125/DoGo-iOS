//
//  DuGoSheet.swift
//  DuGo-iOS
//

import SwiftUI

enum DuGoSheetHeight {
    case medium
    case large

    // MARK: - Computed Properties

    fileprivate var detent: PresentationDetent {
        switch self {
        case .medium: .medium
        case .large: .large
        }
    }
}

struct DuGoSheet<Content: View, Footer: View>: View {
    // MARK: - Properties

    private let height: DuGoSheetHeight
    private let isWorking: Bool
    private let scrollsContent: Bool
    private let showsFooter: Bool
    private let closeAction: () -> Void
    private let content: Content
    private let footer: Footer

    // MARK: - Initializer

    init(
        height: DuGoSheetHeight,
        isWorking: Bool = false,
        scrollsContent: Bool = false,
        showsFooter: Bool = true,
        closeAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.height = height
        self.isWorking = isWorking
        self.scrollsContent = scrollsContent
        self.showsFooter = showsFooter
        self.closeAction = closeAction
        self.content = content()
        self.footer = footer()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if scrollsContent {
                    ScrollView {
                        sheetContent
                    }
                } else {
                    sheetContent
                }

                if showsFooter {
                    footer
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DuGoTheme.background.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기", action: closeAction)
                        .tint(DuGoTheme.ink)
                        .disabled(isWorking)
                }
            }
        }
        .presentationDetents([height.detent])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isWorking)
    }

    // MARK: - Subviews

    private var sheetContent: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
    }
}

extension DuGoSheet where Footer == EmptyView {
    // MARK: - Initializer

    init(
        height: DuGoSheetHeight,
        isWorking: Bool = false,
        scrollsContent: Bool = false,
        closeAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            height: height,
            isWorking: isWorking,
            scrollsContent: scrollsContent,
            showsFooter: false,
            closeAction: closeAction,
            content: content,
            footer: { EmptyView() }
        )
    }
}

struct DuGoSheetActions: View {
    // MARK: - Properties

    private let primaryTitle: String
    private let isLoading: Bool
    private let secondaryTitle: String?
    private let primaryAction: () -> Void
    private let secondaryAction: (() -> Void)?

    // MARK: - Initializer

    init(
        primaryTitle: String,
        isLoading: Bool = false,
        secondaryTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.primaryTitle = primaryTitle
        self.isLoading = isLoading
        self.secondaryTitle = secondaryTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            DuGoPrimaryButton(
                title: primaryTitle,
                isLoading: isLoading,
                action: primaryAction
            )

            if let secondaryTitle, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryTitle)
                        .applyDuGoFont(.button14Medium)
                        .foregroundStyle(DuGoTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
        }
    }
}

struct DuGoActionSheet: View {
    // MARK: - Properties

    private let height: DuGoSheetHeight
    private let heading: String
    private let message: String
    private let primaryTitle: String
    private let isLoading: Bool
    private let secondaryTitle: String?
    private let primaryAction: () -> Void
    private let secondaryAction: (() -> Void)?
    private let closeAction: () -> Void

    // MARK: - Initializer

    init(
        height: DuGoSheetHeight = .medium,
        heading: String,
        message: String,
        primaryTitle: String,
        isLoading: Bool = false,
        secondaryTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil,
        closeAction: @escaping () -> Void
    ) {
        self.height = height
        self.heading = heading
        self.message = message
        self.primaryTitle = primaryTitle
        self.isLoading = isLoading
        self.secondaryTitle = secondaryTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.closeAction = closeAction
    }

    // MARK: - Body

    var body: some View {
        DuGoSheet(
            height: height,
            isWorking: isLoading,
            closeAction: closeAction
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(heading)
                    .applyDuGoFont(.display24SemiBold)
                    .foregroundStyle(DuGoTheme.ink)

                Text(message)
                    .applyDuGoFont(.body16Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            DuGoSheetActions(
                primaryTitle: primaryTitle,
                isLoading: isLoading,
                secondaryTitle: secondaryTitle,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction
            )
        }
    }
}
