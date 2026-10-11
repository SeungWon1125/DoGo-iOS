//
//  WishDraft.swift
//  DuGo-iOS
//
//  Created by 김승원 on 19/9/26.
//

import Foundation

struct WishDraft {
    var link = ""
    var title = ""
    var category = WishCategory.other.rawValue
    var price = ""
    var reason = ""
    var imageData: Data?
    var hasReviewDate = true
    var reviewDate =
        Calendar.current.date(
            byAdding: .day,
            value: 3,
            to: Calendar.current.startOfDay(for: .now)
        ) ?? .now
    var wantsReminder = false

    init(item: WishItem? = nil) {
        guard let item else { return }
        link = item.link
        title = item.title
        category = item.categoryRaw
        price = item.price.map(String.init) ?? ""
        reason = item.reason
        imageData = item.imageData
        hasReviewDate = item.reviewAt != nil
        reviewDate = item.reviewAt ?? reviewDate
        wantsReminder = item.wantsReminder
    }

    func validated(previousReviewDate: Date? = nil) throws -> (
        link: URL, title: String, price: Int?
    ) {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme), let host = url.host, !host.isEmpty
        else {
            throw DraftError.invalidLink
        }
        let amount =
            price
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "원", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedPrice: Int?
        if amount.isEmpty {
            parsedPrice = nil
        } else if let value = Int(amount), value >= 0 {
            parsedPrice = value
        } else {
            throw DraftError.invalidPrice
        }
        if hasReviewDate && reviewDate <= .now && reviewDate != previousReviewDate {
            throw DraftError.pastDate
        }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return (url, name.isEmpty ? host : name, parsedPrice)
    }
}

enum DraftError: LocalizedError {
    case invalidLink, invalidPrice, pastDate
    var errorDescription: String? {
        switch self {
        case .invalidLink: "http 또는 https로 시작하는 상품 링크를 넣어주세요"
        case .invalidPrice: "가격은 0 이상의 정수로 입력해주세요"
        case .pastDate: "다시 볼 날짜를 현재보다 나중으로 정해주세요"
        }
    }
}
