// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Dip

/// We follow the Dependency Injection pattern with containers, currently tied to `Dip` framework.
///
/// For any container based approach, we need:
/// - to create the container and make it accessible
/// - register our services
/// - have the client easily register them
/// - have the client easily resolve them
///
/// These are minimum requirements. Container creation varies based on the framework
/// used - that detail can be kept out of here. However, every service provider is expected
/// to resolve services. 
public protocol ServiceProvider {
    func resolve<T>() -> T
    func register<T>(service: T)
    func bootstrap()
    func reset()
}
