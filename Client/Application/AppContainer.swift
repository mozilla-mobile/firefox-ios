// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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

    private init() {
        container = bootstrapContainer()
    }

    /// Any services needed by the client can be resolved by calling this.
    func resolve<T>() -> T {
        do {
            return try container?.resolve(T.self) as! T
        } catch {
            /// If a service we thought was registered can't be resolved, this is likely an issue within
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
                    return BrowserProfile(
                        localName: "profile",
                        syncDelegate: UIApplication.shared.syncDelegate
                    ) as Profile
                }

                /// TabManager access should be through the container, since we'll support multiple scenes.
                container.register(.singleton) {
                    return TabManager(
                        profile: try container.resolve(),
                        imageStore: DiskImageStore(
                            files: (try container.resolve() as Profile).files,
                            namespace: "TabManagerScreenshots",
                            quality: UIConstants.ScreenshotQuality)
                    )
                }

                container.register(.singleton) {
                    return DefaultThemeManager(appDelegate: UIApplication.shared.delegate) as ThemeManager
                }

                container.register(.singleton) {
                    return RatingPromptManager(profile: try container.resolve())
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
