// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary

/// A `UIHostingController` subclass that automatically adjusts its size to fit its SwiftUI `View` content.
/// It also conforms to `BottomSheetChild` for use in bottom sheet contexts, allowing for dismissal handling.
class SelfSizingHostingController<Content>: UIHostingController<Content>, BottomSheetChild where Content: View {
    var controllerWillDismiss: () -> Void = {}
    /// Ensures the view controller dynamically adjusts its size to its content after layout changes.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize() // Adjusts size based on content.
    }

    /// Placeholder for bottom sheet dismissal handling. Override to add custom behavior.
    public func willDismiss() {
        self.controllerWillDismiss()
    }
}
