// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol UnleashProtocol {
    /// Checks if a toggle with the given name exists and is enabled.
    /// - Parameter name: The name of the toggle.
    /// - Returns: `true` if the toggle is enabled, `false` otherwise.
    static func isEnabled(_ flag: Unleash.Toggle.Name) -> Bool
}

public enum Unleash: UnleashProtocol {

    public typealias Context = [String: String]

    static var model = Model()
    private static let queue = DispatchQueue(label: "com.ecosia.ModelManagerQueue")
    static var rules: [RefreshingRule] = []
    static var currentDeviceRegion: String {
        Locale.current.regionIdentifierLowercasedWithFallbackValue
    }

    public static func queryParameters(appVersion: String) -> Context {
        ["userId": model.id.uuidString,
         "appName": "iOS",
         "appVersion": appVersion,
         "versionOnInstall": User.shared.versionOnInstall,
         "environment": Environment.current.urlProvider.unleash,
         "market": User.shared.marketCode.rawValue,
         "deviceRegion": currentDeviceRegion,
         "personalCounterSearches": "\(User.shared.searchCount)"]
    }

    /// Starts the Unleash feature management session.
    /// - Parameters:
    ///   - client: The HTTP client to use for network requests. Default is `URLSessionHTTPClient`.
    ///   - request: The base request to be used for the session. Default is `nil`.
    ///   - env: The environment for the session. Default is `.production`.
    ///   - force: Indicates whether to force a refresh even if the model is not expired. Default is `false`.
    /// - Returns: The updated `Model` after starting the session.
    /// - Throws: An error if the session fails to start or save the model.
    public static func start(client: HTTPClient = URLSessionHTTPClient(),
                             request: BaseRequest? = nil,
                             env: Environment = .production,
                             appVersion: String) async throws -> Model {
        return try await withCheckedThrowingContinuation({ continuation in
            Self.queue.async {
                Task {
                    do {
                        // Load from filesystem if not already happened
                        if model.updated.timeIntervalSince1970 == 0 {
                            await load().map({ Self.model = $0 })
                        }

                        // Call backend to refresh the model
                        Self.model = try await refresh(client: client,
                                                       request: request,
                                                       model: model,
                                                       env: env,
                                                       appVersion: appVersion)

                        // Save the updated model to the filesystem
                        try await save(Self.model)
                        continuation.resume(returning: self.model)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        })
    }

    public static func isEnabled(_ name: Toggle.Name) -> Bool {
        model[name]?.enabled ?? false
    }

    /// Retrieves the variant of a toggle with the given name.
    /// - Parameter name: The name of the toggle.
    /// - Returns: The variant of the toggle if it exists, otherwise a default disabled variant.
    public static func getVariant(_ name: Toggle.Name) -> Variant {
        model[name]?.variant ?? Variant(name: "disabled", enabled: false, payload: nil)
    }

    /// Refreshes the Unleash model by making a network request to the backend.
    /// - Parameters:
    ///   - client: The HTTP client to use for network requests. Default is `URLSessionHTTPClient`.
    ///   - request: The base request to be used for refreshing the model. Default is `nil`.
    ///   - model: The current model.
    ///   - env: The environment for the session.
    ///   - appVersion: The package's hosting app version (`CFShortVersionString`)
    /// - Returns: The latest available `Model` after refreshing.
    /// - Throws: An error if the model fails to refresh or update.
    static func refresh(client: HTTPClient = URLSessionHTTPClient(),
                        request: BaseRequest? = nil,
                        model: Model,
                        env: Environment,
                        appVersion: String) async throws -> Model {

        guard shouldRefresh else {
            // Return the cached model if refresh is not required
            return model
        }

        // Create a request to refresh the model from the backend
        let unleashRemoteRequest = UnleashStartRequest(etag: model.etag, queryParameters: Unleash.queryParameters(appVersion: appVersion))

        // Initialize the Unleash feature management session
        let unleashSessionInitializer = UnleashFeatureManagementSessionInitializer(client: client,
                                                                                   request: request ?? unleashRemoteRequest,
                                                                                   model: model)

        // Start the session and get the latest available model
        var latestAvailableModel: Unleash.Model = try await unleashSessionInitializer.startSession()!
        latestAvailableModel.updated = .init()
        latestAvailableModel.appVersion = appVersion
        latestAvailableModel.deviceRegion = currentDeviceRegion
        return latestAvailableModel
    }

    /// Resets the Unleash feature management session and returns the initial model.
    /// - Parameters:
    ///   - client: The HTTP client to use for network requests. Default is `URLSessionHTTPClient`.
    ///   - env: The environment for the session.
    /// - Returns: The initial `Model` after resetting the session.
    /// - Throws: An error if the session fails to reset or save the model.
    public static func reset(client: HTTPClient = URLSessionHTTPClient(),
                             env: Environment,
                             appVersion: String) async throws -> Model {
        Self.model = .init()
        try await save(Self.model)
        let unleashRemoteRequest = UnleashStartRequest(etag: model.etag, queryParameters: Unleash.queryParameters(appVersion: appVersion))
        return try await start(client: client,
                               request: unleashRemoteRequest,
                               env: env,
                               appVersion: appVersion)
    }

    /// Loads the model from the filesystem.
    /// - Returns: The loaded `Model` if successful, otherwise `nil`.
    static func load() async -> Model? {
        try? JSONDecoder().decode(Model.self, from: .init(contentsOf: FileManager.unleash))
    }

    /// Saves the model to the filesystem.
    /// - Parameter model: The model to be saved.
    /// - Throws: An error if the model fails to be encoded or saved.
    static func save(_ model: Model) async throws {
        try JSONEncoder().encode(model).write(to: FileManager.unleash, options: .atomic)
    }

    /// Determines whether the model should be refreshed based on its refreshing context providers.
    static var shouldRefresh: Bool {
        return rules.contains(where: { $0.shouldRefresh })
    }
}
