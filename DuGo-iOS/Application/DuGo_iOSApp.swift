//
//  DuGo_iOSApp.swift
//  DuGo-iOS
//
//  Created by 김승원 on 19/9/26.
//

import OSLog
import SwiftData
import SwiftUI

@main
struct DuGo_iOSApp: App {

    // MARK: - Properties

    @StateObject private var reminders: ReminderManager
    private let container: ModelContainer?

    // MARK: - Initializer

    init() {
        let manager = ReminderManager()
        manager.start()
        _reminders = StateObject(wrappedValue: manager)
        do {
            let schema = Schema([WishItem.self, DecisionRecord.self])
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            let storeURL = appSupport.appendingPathComponent("DoGo.store")
            let configuration = ModelConfiguration(
                "DoGo",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            Logger(subsystem: "won.DoGo-iOS", category: "storage").error(
                "Storage initialization failed: \(error.localizedDescription)"
            )
            container = nil
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            SplashContainer {
                if let container {
                    ContentView(context: container.mainContext, reminders: reminders)
                        .modelContainer(container)
                } else {
                    ContentUnavailableView(
                        "보관함을 열지 못했어요",
                        systemImage: "externaldrive.badge.exclamationmark",
                        description: Text("앱을 다시 실행해주세요 문제가 계속되면 저장 공간을 확인해주세요")
                    )
                }
            }
        }
    }
}
