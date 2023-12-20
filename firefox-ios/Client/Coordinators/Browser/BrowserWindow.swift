// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A unique identifier for a particular window in Firefox iOS.
/// On iPad this UUID corresponds to an individual window which
/// manages its own unique set of tabs. Multiple Firefox windows
/// can be run side-by-side on iPad (once multi-window is enabled). [FXIOS-7349]
public typealias WindowUUID = UUID
