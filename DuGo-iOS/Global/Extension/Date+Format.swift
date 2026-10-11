//
//  Date+Format.swift
//  DuGo-iOS
//
//  Created by 김승원 on 1/10/26.
//

import Foundation

extension Date {
    func dugoFormattedDate(includingTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = includingTime ? "yyyy.MM.dd HH:mm" : "yyyy.MM.dd"

        return formatter.string(from: self)
    }
}

extension Int {
    var dugoFormattedPrice: String {
        formatted(
            .number
                .grouping(.automatic)
                .locale(Locale(identifier: "ko_KR"))
        ) + "원"
    }
}
