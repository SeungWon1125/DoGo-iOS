//
//  WebDocumentView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 8/10/26.
//

import SwiftUI
@preconcurrency import WebKit

struct WebDocumentView: View {
    // MARK: - Properties

    let title: String
    let url: URL

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadIdentifier = UUID()

    // MARK: - Body

    var body: some View {
        ZStack {
            DuGoWebView(
                url: url,
                reloadIdentifier: reloadIdentifier,
                isLoading: $isLoading,
                errorMessage: $errorMessage
            )

            if isLoading {
                ProgressView()
                    .tint(DuGoTheme.accent)
            }

            if let errorMessage {
                errorView(message: errorMessage)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .dugoScreen()
    }

    // MARK: - Subviews

    private func errorView(message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(DuGoTheme.secondary)

            VStack(spacing: 6) {
                Text("문서를 불러오지 못했어요")
                    .applyDuGoFont(.body16Medium)
                    .foregroundStyle(DuGoTheme.ink)

                Text(message)
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("다시 시도") {
                errorMessage = nil
                isLoading = true
                reloadIdentifier = UUID()
            }
            .buttonStyle(.borderedProminent)
            .tint(DuGoTheme.accent)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .dugoRoundedSurface(cornerRadius: 18)
        .padding(.horizontal, 24)
    }
}

private struct DuGoWebView: UIViewRepresentable {
    // MARK: - Properties

    let url: URL
    let reloadIdentifier: UUID
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.load(url, in: webView, reloadIdentifier: reloadIdentifier)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.load(url, in: webView, reloadIdentifier: reloadIdentifier)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: DuGoWebView
        private var loadedIdentifier: UUID?

        init(parent: DuGoWebView) {
            self.parent = parent
        }

        func load(
            _ url: URL,
            in webView: WKWebView,
            reloadIdentifier: UUID
        ) {
            guard loadedIdentifier != reloadIdentifier else { return }

            loadedIdentifier = reloadIdentifier
            webView.load(URLRequest(url: url))
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation?
        ) {
            parent.isLoading = true
            parent.errorMessage = nil
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation?
        ) {
            parent.isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil else { return nil }

            webView.load(navigationAction.request)
            return nil
        }

        private func handle(_ error: Error) {
            let error = error as NSError
            guard error.code != NSURLErrorCancelled else { return }

            parent.isLoading = false
            parent.errorMessage = "네트워크 연결을 확인하고 다시 시도해 주세요"
        }
    }
}
