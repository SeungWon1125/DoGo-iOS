//
//  DuGoGreeting.swift
//  DuGo-iOS
//
//  Created by 김승원 on 20/9/26.
//

import Foundation

enum DuGoGreeting {
    static let openingMessages = [
        "사고 싶은 마음,\n잠시 여기에",
        "지금 결정하지 않아도\n괜찮아요",
        "마음이 가는 것을,\n조금 더 두고 봐요",
        "오늘의 끌림을\n천천히 살펴봐요",
        "충분히 고민한 선택은,\n어떤 것이든 괜찮아요",
        "지금의 설렘,\n잠깐 담아두고 가요",
    ]

    static var randomOpeningMessage: String {
        openingMessages.randomElement() ?? "사고 싶은 마음,\n잠시 여기"
    }
}
