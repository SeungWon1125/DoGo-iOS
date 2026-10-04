import Combine
import Foundation
import OSLog

@MainActor
final class AppVersionMonitor: ObservableObject {
    // MARK: - Types

    private struct AppVersion: Comparable {
        let components: [Int]

        init?(_ value: String) {
            let parts = value.split(separator: ".", omittingEmptySubsequences: false)
            guard !parts.isEmpty else { return nil }

            var components: [Int] = []
            for part in parts {
                guard
                    !part.isEmpty,
                    part.utf8.allSatisfy({ (48...57).contains($0) }),
                    let number = Int(part)
                else {
                    return nil
                }
                components.append(number)
            }

            while components.count > 1 && components.last == 0 {
                components.removeLast()
            }
            self.components = components
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            for index in 0..<max(lhs.components.count, rhs.components.count) {
                let left = index < lhs.components.count ? lhs.components[index] : 0
                let right = index < rhs.components.count ? rhs.components[index] : 0
                if left != right { return left < right }
            }
            return false
        }
    }

    private struct LookupResponse: Decodable {
        let results: [StoreApp]
    }

    private struct StoreApp: Decodable {
        let bundleId: String
        let version: String
        let trackViewUrl: URL
    }

    private enum CacheKey {
        static let version = "dugo.latestVerifiedStoreVersion"
        static let url = "dugo.latestVerifiedStoreURL"
    }

    // MARK: - Properties

    @Published private(set) var isUpdateRequired = false
    @Published var isAlertPresented = false

    private(set) var appStoreURL: URL?
    private var isChecking = false

    private let logger = Logger(subsystem: "app.seungwon.dugo", category: "updates")

    // MARK: - Initializer

    init() {
        guard
            let installed = Self.installedVersion,
            let cachedString = UserDefaults.standard.string(forKey: CacheKey.version),
            let cached = AppVersion(cachedString),
            let urlString = UserDefaults.standard.string(forKey: CacheKey.url),
            let url = URL(string: urlString),
            Self.isAppStoreURL(url)
        else {
            return
        }

        appStoreURL = url
        isUpdateRequired = cached > installed
        isAlertPresented = isUpdateRequired
    }

    // MARK: - Methods

    func checkForUpdate() async {
        guard !isChecking else { return }
        guard let installed = Self.installedVersion else { return }
        guard let bundleID = Bundle.main.bundleIdentifier else { return }

        isChecking = true
        defer { isChecking = false }

        do {
            let storeApp = try await fetchStoreApp(bundleID: bundleID)
            guard let storeVersion = AppVersion(storeApp.version) else { return }
            guard Self.isAppStoreURL(storeApp.trackViewUrl) else { return }

            let cachedString = UserDefaults.standard.string(forKey: CacheKey.version)
            let cachedVersion = cachedString.flatMap(AppVersion.init)
            let cachedURLString = UserDefaults.standard.string(forKey: CacheKey.url)
            let cachedURL = cachedURLString.flatMap(URL.init(string:))
            if
                let cachedVersion,
                let cachedURL,
                Self.isAppStoreURL(cachedURL),
                cachedVersion > storeVersion
            {
                appStoreURL = cachedURL
                isUpdateRequired = cachedVersion > installed
                isAlertPresented = isUpdateRequired
                return
            }

            UserDefaults.standard.set(storeApp.version, forKey: CacheKey.version)
            UserDefaults.standard.set(storeApp.trackViewUrl.absoluteString, forKey: CacheKey.url)
            appStoreURL = storeApp.trackViewUrl
            isUpdateRequired = storeVersion > installed
            isAlertPresented = isUpdateRequired
        } catch {
            logger.error("App Store version lookup failed: \(error.localizedDescription)")
        }
    }

    func presentAlertIfNeeded() {
        if isUpdateRequired {
            isAlertPresented = true
        }
    }

    // MARK: - Private Methods

    private func fetchStoreApp(bundleID: String) async throws -> StoreApp {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        components.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: "kr"),
            URLQueryItem(name: "entity", value: "software")
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard
            let response = response as? HTTPURLResponse,
            (200..<300).contains(response.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        let lookup = try JSONDecoder().decode(LookupResponse.self, from: data)
        guard let storeApp = lookup.results.first(where: { $0.bundleId == bundleID }) else {
            throw URLError(.resourceUnavailable)
        }
        return storeApp
    }

    private static var installedVersion: AppVersion? {
        guard
            let string = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        else {
            return nil
        }
        return AppVersion(string)
    }

    private static func isAppStoreURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.lowercased() == "apps.apple.com"
    }
}
