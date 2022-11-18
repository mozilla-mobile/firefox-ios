// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIResponder {

    /// Use this method to walk the responder chain until you find your desired object.
    func walkChainUntil<T: UIResponder>(visiting responder: T.Type) -> T? {
        return sequence(first: self, next: { $0.next })
            .first(where: { $0 is T }) as? T
    }

    /// Outputs the entire responder chain from the leaf upwards.
    ///
    /// Debugging method.
    func responderChain() -> String {
        guard let next = next else {
            return String(describing: self)
        }

        return String(describing: self) + "----->" + next.responderChain()
    }

}
