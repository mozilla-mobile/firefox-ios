// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

/// Base event type protocol. Conforming types must be hashable.
public protocol AppEventType: Hashable { }

public enum AppEvent: AppEventType {
    // MARK: - Global App Events

    // Events: Startup flow
    case startupFlowComplete

    // Sub-Events for Startup Flow
    case profileInitialized
    case preLaunchDependenciesComplete
    case postLaunchDependenciesComplete
    case accountManagerInitialized
    case browserIsReady

    // Activities: Profile Syncing
    case profileSyncing

    // MARK: - Browser Events

    // Activities: Browser
    case browserUpdatedForAppActivation(WindowUUID)

    // Activities: Tabs
    case tabRestoration(WindowUUID)
}
