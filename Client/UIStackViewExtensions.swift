// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

private let log = Logger.browserLogger

extension UIStackView {

    func toggleStackViewVisibility(show: Bool) {
        guard show else {
            self.isHidden = true
            return
        }

        UIView.animate(withDuration: 0.1, animations: { self.isHidden = false })
    }

    func addArrangedViewToTop(_ view: UIView, animated: Bool = true, completion: (() -> Void)? = nil) {
        insertArrangedView(view, position: 0, animated: animated, completion: completion)
    }

    func addArrangedViewToBottom(_ view: UIView, animated: Bool = true, completion: (() -> Void)? = nil) {
        let animateClosure = { self.addArrangedSubview(view) }
        animateAddingView(view, animateClosure: animateClosure, animated: animated, completion: completion)
    }

    func insertArrangedView(_ view: UIView, position: Int, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard position <= arrangedSubviews.count, position >= 0 else {
            log.warning("Couldn't insert subview \(view.debugDescription) into stackview \(self.debugDescription)")
            return
        }

        let animateClosure = { self.insertArrangedSubview(view, at: position) }
        animateAddingView(view, animateClosure: animateClosure, animated: animated, completion: completion)
    }

    func removeArrangedView(_ view: UIView, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.removeArrangedSubview(view)
            view.removeFromSuperview()
        })
    }

    func removeAllArrangedViews() {
        self.arrangedSubviews.forEach {
            self.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func animateAddingView(_ view: UIView,
                                   animateClosure: @escaping () -> Void,
                                   animated: Bool = true,
                                   completion: (() -> Void)?) {
        view.layoutIfNeeded()

        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            animateClosure()
        }, completion: { _ in
            completion?()
        })
    }
}
