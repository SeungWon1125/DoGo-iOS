//
//  FirebaseConfigurator.swift
//  DuGo-iOS
//
//  Created by 김승원 on 8/10/26.
//

import FirebaseCore
import Foundation
import OSLog

enum FirebaseConfigurator {
    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "app.seungwon.dugo",
        category: "firebase"
    )

    private(set) static var isConfigured = false

    // MARK: - Methods

    static func configure() {
        if FirebaseApp.app() != nil {
            isConfigured = true
            return
        }

#if DUGO_DEV
        let resourceName = "GoogleService-Info-Dev"
#else
        let resourceName = "GoogleService-Info"
#endif

        guard
            let path = Bundle.main.path(forResource: resourceName, ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            logger.notice("\(resourceName).plist was not found")
            return
        }

        FirebaseApp.configure(options: options)
        isConfigured = true
    }
}
