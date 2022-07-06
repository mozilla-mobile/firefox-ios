// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// TODO: Preparing services to be injected (https://mozilla-hub.atlassian.net/browse/FXIOS-4381) & actually
/// injecting at those points (https://mozilla-hub.atlassian.net/browse/FXIOS-4152) will come in a later PR.

import Foundation
import os.log
import Dip
import Storage

/// This is our concrete dependency container. It holds all dependencies / services the app would need through
/// a session.
class AppContainer: ServiceProvider {

    static let shared: ServiceProvider = AppContainer()

    /// The item holding registered services.
    private var container: DependencyContainer?

    init() {
        container = bootstrapContainer()
    }

    /// Any services needed by the client can be resolved by calling this and passing the type.
    func resolve<T>(type: T.Type) -> T {
        do {
            return try container?.resolve(T.self) as! T
        } catch {
            /// If a service we've thought was registered but can't be resolved, this is likely an issue within
            /// bootstrapping. Double check your registrations and their types.
            os_log(.error, "Could not resolve the requested type!")

            /// We've made bad assumptions, and there's something very wrong with container setup! This is fatal.
            fatalError("\(error)")
        }
    }

    // MARK: - Misc helpers

    /// Prepares the container by registering all services for the app session.
    /// - Returns: A bootstrapped `DependencyContainer`.
    private func bootstrapContainer() -> DependencyContainer {
        return DependencyContainer { container in
            do {
                unowned let container = container

                container.register(.eagerSingleton) {
                    BrowserProfile(
                        localName: "profile",
                        syncDelegate: UIApplication.shared.syncDelegate) as Profile
                }

                /// TabManager can remain a singleton until we support multiple scenes.
                container.register(.singleton) {
                    TabManager(
                        profile: try container.resolve(),
                        imageStore: DiskImageStore(
                            files: (try container.resolve() as Profile).files,
                            namespace: "TabManagerScreenshots",
                            quality: UIConstants.ScreenshotQuality))
                }

                try container.bootstrap()
            } catch {
                os_log(.error, "We couldn't resolve something inside the container!")

                /// If resolution of one item fails, the entire object graph won't be resolved. This is a fatal error.
                fatalError("\(error)")
            }
        }
    }

}
