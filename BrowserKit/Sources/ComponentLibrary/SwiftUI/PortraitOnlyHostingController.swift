// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A UIHostingController that locks the interface to portrait orientation only.
///
/// Usage: `PortraitOnlyHostingController(rootView: MySwiftUIView())`
@available(iOS 13.0, *)
public class PortraitOnlyHostingController<Content: View>: UIHostingController<Content> {
    override public init(rootView: Content) {
        super.init(rootView: rootView)
    }

    @MainActor
    public dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Restricts orientation to portrait only
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    /// Prevents automatic rotation
    override public var shouldAutorotate: Bool {
        return false
    }

    /// Sets portrait as the preferred presentation orientation
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}
