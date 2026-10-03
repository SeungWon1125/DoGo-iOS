//
//  SplashView.swift
//  DuGo-iOS
//

import SwiftUI

struct SplashContainer<Content: View>: View {
    // MARK: - Properties

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingSplash = true
    @State private var isFadingSplash = false
    @State private var isShowingContent = false

    private let content: Content

    // MARK: - Initializer

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DuGoTheme.background
                .ignoresSafeArea()

            if hasCompletedOnboarding || isShowingContent {
                content
            }

            if isShowingSplash {
                SplashView()
                    .ignoresSafeArea()
                    .opacity(isFadingSplash ? 0 : 1)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.45)) {
                isFadingSplash = true
            }

            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            isShowingContent = true
            isShowingSplash = false
        }
    }
}

struct SplashView: View {
    // MARK: - Body

    var body: some View {
        DuGoLogoImage(width: 70, height: 70)
            .foregroundStyle(.duGoAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DuGoTheme.background)
    }
}
