// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The `EngineProviderManager` ensures only one engine can exists per application
actor EngineProviderManager {
    static let shared = EngineProviderManager()

    private var dependencyManager = EngineDependencyManager()
    private var engineProvider: EngineProvider?

    func getProvider() async -> EngineProvider {
        if let existing = engineProvider {
            return existing
        }

        guard let provider = await EngineProvider(dependencyManager: dependencyManager) else {
            fatalError("No engine provider could be created, this is a fatal error")
        }
        self.engineProvider = provider
        return provider
    }
}
