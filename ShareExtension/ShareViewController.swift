//
//  ShareViewController.swift
//  ShareExtension
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    // MARK: - Properties

    private let composer = ShareComposerModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let content = ShareComposerView(
            model: composer,
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
            },
            onSaved: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        )
        let hostingController = UIHostingController(rootView: content)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
        preferredContentSize = CGSize(width: 0, height: 640)

        Task {
            composer.isReadingLink = true
            defer { composer.isReadingLink = false }
            guard let url = await sharedWebURL() else {
                composer.errorMessage = "공유한 내용에서 링크를 찾지 못했어요"
                return
            }
            composer.link = url.absoluteString
        }
    }

    // MARK: - Private Methods

    private func sharedWebURL() async -> URL? {
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        for item in items {
            for provider in item.attachments ?? [] {
                for type in [UTType.url.identifier, UTType.plainText.identifier] {
                    guard provider.hasItemConformingToTypeIdentifier(type) else { continue }
                    let url: URL? = await withCheckedContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: type, options: nil) { value, _ in
                            continuation.resume(returning: Self.webURL(from: value))
                        }
                    }
                    if let url {
                        return url
                    }
                }
            }
            if let text = item.attributedContentText?.string,
                let url = Self.webURL(from: text)
            {
                return url
            }
        }
        return nil
    }

    // MARK: - Type Methods

    nonisolated private static func webURL(from value: Any?) -> URL? {
        if let url = value as? URL {
            return validated(url)
        }
        if let url = value as? NSURL {
            return validated(url as URL)
        }

        let text: String?
        if let string = value as? String {
            text = string
        } else if let data = value as? Data {
            text = String(data: data, encoding: .utf8)
        } else {
            text = nil
        }

        guard let text else { return nil }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?.matches(in: text, range: range)
            .compactMap { $0.url.flatMap(validated) }
            .first
    }

    nonisolated private static func validated(_ url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else { return nil }
        return url
    }
}
