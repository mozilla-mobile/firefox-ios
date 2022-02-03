// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIStackView {

    func toggleStackViewVisibility(show: Bool) {
        guard show else {
            self.isHidden = true
            return
        }

        UIView.animate(withDuration: 0.1, animations: { self.isHidden = false })
    }

    func addArrangedViewToTop(_ view: UIView, animated: Bool = true, completion: @escaping () -> Void) {
        view.layoutIfNeeded()

        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.insertArrangedSubview(view, at: 0)
        }, completion: { _ in
            completion()
        })
    }

    func addArrangedViewToBottom(_ view: UIView, animated: Bool = true, completion: @escaping () -> Void) {
        view.layoutIfNeeded()

        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.addArrangedSubview(view)
        }, completion: { _ in
            completion()
        })
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
}
