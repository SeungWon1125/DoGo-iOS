//
//  LinkPreviewService.swift
//  DuGo-iOS
//
//  Created by 김승원 on 20/9/26.
//

import Foundation
import UIKit

struct LinkPreview {
    let title: String?
    let imageData: Data?
    let price: Int?
}

enum LinkPreviewError: LocalizedError {
    case invalidLink
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidLink:
            "대표 사진을 가져올 수 없는 링크예요"
        case .invalidResponse:
            "웹사이트에서 대표 사진을 찾지 못했어요"
        }
    }
}

struct LinkPreviewService {
    // MARK: - Methods

    func fetch(from rawLink: String) async throws -> LinkPreview {
        let link = rawLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pageURL = URL(string: link),
            let scheme = pageURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            pageURL.host != nil
        else {
            throw LinkPreviewError.invalidLink
        }

        var request = URLRequest(url: pageURL)
        request.timeoutInterval = 15
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        let (htmlData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            htmlData.count <= 2_000_000,
            let html = String(data: htmlData, encoding: .utf8)
                ?? String(data: htmlData, encoding: .unicode)
        else {
            throw LinkPreviewError.invalidResponse
        }

        let title =
            metadataValue(named: "og:title", in: html)
            ?? metadataValue(named: "twitter:title", in: html)
            ?? pageTitle(in: html)
        let imagePath =
            metadataValue(named: "og:image", in: html)
            ?? metadataValue(named: "twitter:image", in: html)
        let imageURL = imagePath.flatMap {
            URL(string: decodedHTML($0), relativeTo: pageURL)?.absoluteURL
        }
        let imageData = try? await loadImage(from: imageURL)
        try Task.checkCancellation()

        return LinkPreview(
            title: title.map(decodedHTML),
            imageData: imageData,
            price: productPrice(in: html)
        )
    }

    // MARK: - Private Methods

    private func productPrice(in html: String) -> Int? {
        for prefix in ["product:price:", "og:price:"] {
            if let currency = metadataValue(named: prefix + "currency", in: html),
                let amount = metadataValue(named: prefix + "amount", in: html),
                let price = LinkPriceParser.krwAmount(amount, currency: currency)
            {
                return price
            }
        }

        for script in matches(for: #"(?is)<script\b[^>]*>.*?</script\s*>"#, in: html) {
            guard let openingEnd = script.firstIndex(of: ">"),
                attribute(named: "type", in: String(script[...openingEnd]))?.lowercased()
                    == "application/ld+json",
                let closing = script.range(of: "</script", options: [.backwards, .caseInsensitive])
            else { continue }
            let json = String(script[script.index(after: openingEnd)..<closing.lowerBound])
            guard let data = json.data(using: .utf8),
                let value = try? JSONSerialization.jsonObject(with: data),
                let price = LinkPriceParser.productPrice(in: value)
            else { continue }
            return price
        }
        return nil
    }

    private func loadImage(from url: URL?) async throws -> Data? {
        guard let url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("image/avif,image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            data.count <= 12_000_000,
            let image = UIImage(data: data)
        else {
            return nil
        }

        return resizedJPEGData(from: image)
    }

    private func metadataValue(named name: String, in html: String) -> String? {
        let metaTags = matches(for: #"(?is)<meta\b[^>]*>"#, in: html)

        for tag in metaTags {
            let key =
                attribute(named: "property", in: tag)
                ?? attribute(named: "name", in: tag)
                ?? attribute(named: "itemprop", in: tag)

            if key?.lowercased() == name.lowercased(),
                let content = attribute(named: "content", in: tag),
                !content.isEmpty
            {
                return content
            }
        }

        return nil
    }

    private func pageTitle(in html: String) -> String? {
        guard let title = matches(for: #"(?is)<title[^>]*>\s*(.*?)\s*</title>"#, in: html).first
        else {
            return nil
        }

        return
            title
            .replacingOccurrences(of: #"(?is)</?[^>]+>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func attribute(named name: String, in tag: String) -> String? {
        let pattern = #"(?i)\b\#(name)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([^\s>]+))"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
            let match = expression.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag))
        else {
            return nil
        }

        for index in 1...3 {
            let range = match.range(at: index)
            if range.location != NSNotFound,
                let swiftRange = Range(range, in: tag)
            {
                return String(tag[swiftRange])
            }
        }

        return nil
    }

    private func matches(for pattern: String, in value: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(value.startIndex..., in: value)

        return expression.matches(in: value, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: value) else { return nil }
            return String(value[swiftRange])
        }
    }

    private func decodedHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    func resizedJPEGData(from image: UIImage) -> Data? {
        let maximumDimension: CGFloat = 1_200
        let sourceSize = image.size
        let ratio = min(1, maximumDimension / max(sourceSize.width, sourceSize.height))
        let targetSize = CGSize(width: sourceSize.width * ratio, height: sourceSize.height * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let resizedImage = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.82)
    }
}
