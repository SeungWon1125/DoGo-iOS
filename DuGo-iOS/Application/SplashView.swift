//
//  SplashView.swift
//  DuGo-iOS
//

import SwiftUI

struct SplashContainer<Content: View>: View {
    // MARK: - Properties

    @State private var isShowingSplash = true

    private let content: Content

    // MARK: - Initializer

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            content

            if isShowingSplash {
                SplashView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                isShowingSplash = false
            }
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
