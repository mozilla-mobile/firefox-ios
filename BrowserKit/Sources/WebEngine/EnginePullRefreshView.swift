// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public typealias EnginePullRefreshViewType = EnginePullRefreshView.Type

public protocol EnginePullRefreshView: UIView {
    func configure(with scrollView: UIScrollView, onRefresh: @escaping () -> Void)
}

extension UIRefreshControl: EnginePullRefreshView {
    public func configure(with scrollView: UIScrollView, onRefresh: @escaping () -> Void) {
        scrollView.refreshControl = self
        addAction(UIAction(handler: { _ in onRefresh() }),
                  for: .valueChanged)
    }
}
