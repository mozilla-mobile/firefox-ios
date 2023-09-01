// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import os.log
import Dip

/// This is our concrete dependency container. It holds all dependencies / services the app would need through
/// a session.
public class AppContainer: ServiceProvider {
    public static let shared: ServiceProvider = AppContainer()

    /// The item holding registered services.
    private var container = DependencyContainer()

    /// Any services needed by the client can be resolved by calling this.
    public func resolve<T>() -> T {
        do {
            return try container.resolve(T.self) as! T
        } catch {
            // If a service we thought was registered can't be resolved, this is likely an issue within
            // bootstrapping. Double check your registrations and their types.
            // We've made bad assumptions, and there's something very wrong with container setup! This is fatal.
            fatalError("\(error)")
        }
    }

    /// Register a service in the container
    public func register<T>(service: T) {
        do {
            container.register(.eagerSingleton) { () -> T in
                return service
            }
        }
    }

    public func bootstrap() {
        do {
            try container.bootstrap()
        } catch {
            // If resolution of one item fails, the entire object graph won't be resolved. This is a fatal error.
            fatalError("\(error)")
        }
    }

    public func reset() {
        container.reset()
    }
}
