import SwiftUI

struct ForceUpdateGate<Content: View>: View {
    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @StateObject private var monitor = AppVersionMonitor()

    private let content: Content

    // MARK: - Initializer

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .allowsHitTesting(!monitor.isUpdateRequired)
            .alert("업데이트가 필요해요", isPresented: $monitor.isAlertPresented) {
                Button("업데이트") {
                    openAppStore()
                }
                .tint(DuGoTheme.accent)
            } message: {
                Text("두고를 계속 사용하려면 최신 버전으로 업데이트해 주세요")
            }
            .task {
                await monitor.checkForUpdate()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                monitor.presentAlertIfNeeded()
                Task { await monitor.checkForUpdate() }
            }
    }

    // MARK: - Methods

    private func openAppStore() {
        guard let url = monitor.appStoreURL else {
            monitor.presentAlertIfNeeded()
            return
        }

        openURL(url) { accepted in
            guard !accepted else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                monitor.presentAlertIfNeeded()
            }
        }
    }
}
