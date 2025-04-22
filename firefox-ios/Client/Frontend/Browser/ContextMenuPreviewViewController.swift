// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class ContextMenuPreviewViewController: UIViewController {
    private struct UX {
        static let heightMultiplier: CGFloat = 0.8
    }

    private var hasSetPreferredContentSize = false

    // Allows the view controller to resize once it knows it's current size1111
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasSetPreferredContentSize else { return }
        hasSetPreferredContentSize = true

        let currentSize = view.bounds.size
        preferredContentSize = CGSize(width: currentSize.width, height: currentSize.height * UX.heightMultiplier)
    }
}
