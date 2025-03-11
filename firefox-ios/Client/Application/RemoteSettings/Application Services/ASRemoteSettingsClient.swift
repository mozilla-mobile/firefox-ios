// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Account
import Common
import Shared

final class ASSearchEngineSelector {
    private let engineSelector = SearchEngineSelector()
    private let service: RemoteSettingsService

    init(service: RemoteSettingsService) {
        self.service = service
    }

    func fetchSearchEngines(locale: String,
                            region: String,
                            completion: @escaping ((RefinedSearchConfig?, Error?) -> Void)) {
         do {
             try engineSelector.useRemoteSettingsServer(service: service, applyEngineOverrides: false)

             // TODO: What happens if the locale or region changes during app runtime?
             let env = SearchUserEnvironment(locale: locale,
                                             region: region,
                                             updateChannel: SearchUpdateChannel.release,
                                             distributionId: "",    // Confirmed with AS: leave empty, no distr on iOS
                                             experiment: "",        // Confirmed with AS: leave empty
                                             appName: .firefoxIos,
                                             version: AppInfo.appVersion,
                                             deviceType: UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .smartphone)


             // TODO: Temporary synbc to make sure we're getting data
             let profile: Profile = AppContainer.shared.resolve()
             try? profile.remoteSettingsService?.sync()


             let filtered = try engineSelector.filterEngineConfiguration(userEnvironment: env)
             completion(filtered, nil)
         } catch {
             completion(nil, error)
         }
    }
}

enum ASRemoteSettingsEnvironment {
    case prod
    case development

    var bucketName: String {
        switch self {
        case .prod: return "main"
        case .development: return "preview" // Note: some threads/docs reference "preview" others say "main-preview" ?? -mr
        }
    }

    var server: RemoteSettingsServer {
        switch self {
        case .prod: return .prod
        case .development: return .dev
        }
    }

    func makeConfig() -> RemoteSettingsConfig2 {
        return RemoteSettingsConfig2(server: self.server,
                                     bucketName: self.bucketName)
    }
}

final class ASRemoteSettingsContext {
    private static let storageDirectoryName = "remote_settings_cache"
    private let logger: Logger
    private let fileManager: FileManager

    init(logger: Logger = DefaultLogger.shared, fileManager: FileManager = FileManager.default) {
        self.logger = logger
        self.fileManager = fileManager
    }

    func `default`() -> RemoteSettingsContext {
        // TODO: These hardcoded strings will need to be updated eventually
        return RemoteSettingsContext(appName: "Firefox iOS",
                                     appId: AppInfo.bundleIdentifier,
                                     channel: AppConstants.buildChannel.rawValue,
                                     appVersion: AppInfo.appVersion,
                                     appBuild: nil,
                                     architecture: nil,
                                     deviceManufacturer: nil,
                                     deviceModel: nil,
                                     locale: "en-US",
                                     os: "iOS",
                                     osVersion: "17.6.1",
                                     androidSdkVersion: nil,
                                     debugTag: nil,
                                     installationDate: nil,
                                     homeDirectory: defaultStorageDirectory(),
                                     customTargetingAttributes: nil)
    }

    func defaultStorageDirectory() -> String {
        guard var appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory,
                                                            in: .userDomainMask).first else {
            // We always expect a valid path to support directory. Rather than fatalError() here
            // we return a root directory path. This won't be writable, however and will result
            // in a non-fatal error when AS attempts to persist the .sql to this dir.
            logger.log("No app support directory", level: .fatal, category: .storage)
            return "/"
        }
        appSupportPath.appendPathComponent(Self.storageDirectoryName)
        let path = appSupportPath.path

        if !fileManager.fileExists(atPath: path, isDirectory: nil) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: false)
        }

        return path
    }
}

