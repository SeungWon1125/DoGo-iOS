//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 김승원 on 1/10/26.
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
            guard let content = await sharedContent() else {
                composer.errorMessage = "공유한 내용에서 링크를 찾지 못했어요"
                return
            }
            composer.applySharedContent(
                url: content.url,
                title: content.title,
                price: content.price,
                imageData: content.imageData
            )
        }
    }

    // MARK: - Private Methods

    private func sharedContent() async -> SharedContent? {
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        var sharedURL: URL?
        var sharedTitle: String?
        var capturedImageData: Data?
        var sharedTexts: [String] = []

        for item in items {
            if sharedTitle == nil {
                sharedTitle = Self.cleanedTitle(item.attributedTitle?.string)
            }
            if let text = item.attributedContentText?.string, !text.isEmpty {
                sharedTexts.append(text)
            }

            for provider in item.attachments ?? [] {
                if capturedImageData == nil {
                    capturedImageData = await sharedImageData(from: provider)
                }

                for type in [UTType.url.identifier, UTType.plainText.identifier] {
                    guard provider.hasItemConformingToTypeIdentifier(type) else { continue }
                    let value: Any? = await withCheckedContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: type, options: nil) { value, _ in
                            continuation.resume(returning: value)
                        }
                    }

                    if sharedURL == nil {
                        sharedURL = Self.webURL(from: value)
                    }
                    if let text = Self.text(from: value), !text.isEmpty {
                        sharedTexts.append(text)
                    }
                }
            }

            if sharedURL == nil {
                sharedURL = sharedTexts.lazy.compactMap(Self.webURL(from:)).first
            }
        }

        guard let sharedURL else { return nil }
        let combinedText = sharedTexts.joined(separator: "\n")

        return SharedContent(
            url: sharedURL,
            title: sharedTitle ?? Self.title(from: combinedText),
            price: Self.price(from: combinedText),
            imageData: capturedImageData
        )
    }

    private func sharedImageData(from provider: NSItemProvider) async -> Data? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            return nil
        }

        let value: Any? = await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) {
                value,
                _ in
                continuation.resume(returning: value)
            }
        }

        let image: UIImage?
        if let sharedImage = value as? UIImage {
            image = sharedImage
        } else if let data = value as? Data {
            image = UIImage(data: data)
        } else if let url = value as? URL,
            let data = try? Data(contentsOf: url)
        {
            image = UIImage(data: data)
        } else {
            image = nil
        }

        return image.flatMap { LinkPreviewService().resizedJPEGData(from: $0) }
    }

    // MARK: - Type Methods

    nonisolated private static func text(from value: Any?) -> String? {
        if let string = value as? String {
            return string
        }
        if let attributedString = value as? NSAttributedString {
            return attributedString.string
        }
        if let data = value as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

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

    nonisolated private static func cleanedTitle(_ value: String?) -> String? {
        LinkPreviewService.usableProductTitle(value)
    }

    nonisolated private static func title(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let withoutLinks = detector?.matches(in: text, range: range).reversed().reduce(text) {
            result,
            match in
            guard let matchRange = Range(match.range, in: result) else { return result }
            var result = result
            result.removeSubrange(matchRange)
            return result
        } ?? text

        return withoutLinks
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { LinkPreviewService.usableProductTitle($0) }
            .first { line in
                price(from: line) == nil
                    && !line.lowercased().hasPrefix("http")
            }
    }

    nonisolated private static func price(from text: String) -> Int? {
        let patterns = [
            #"(?:₩|KRW\s*)([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})"#,
            #"([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})\s*원"#,
        ]

        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern),
                let match = expression.firstMatch(
                    in: text,
                    range: NSRange(text.startIndex..., in: text)
                ),
                let amountRange = Range(match.range(at: 1), in: text),
                let amount = Int(text[amountRange].replacingOccurrences(of: ",", with: ""))
            else { continue }
            return amount
        }
        return nil
    }

    private struct SharedContent {
        let url: URL
        let title: String?
        let price: Int?
        let imageData: Data?
    }
}
