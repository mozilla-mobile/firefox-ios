// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
public protocol ModalPresenter {
    func present(_ controller: UIViewController, animated: Bool)
    
    func canPresent() -> Bool
}

public class DefaultModalPresenter: ModalPresenter {
    weak var presenter: UIViewController?

    public init(presenter: UIViewController?) {
        self.presenter = presenter
    }

    public func present(_ controller: UIViewController, animated: Bool) {
        presenter?.present(controller, animated: animated)
    }

    public func canPresent() -> Bool {
        return presenter?.presentedViewController == nil
    }
}
