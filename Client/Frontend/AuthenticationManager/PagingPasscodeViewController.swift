/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
private let PaneSwipeDuration: NSTimeInterval = 0.3

/// Base class for implementing a Passcode configuration screen with multiple 'panes'.
class PagingPasscodeViewController: BasePasscodeViewController {
    private lazy var pager: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.userInteractionEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    var panes = [PasscodePane]()
    var currentPaneIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pager)
        panes.forEach { pager.addSubview($0) }
        pager.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        panes.enumerate().forEach { index, pane in
            pane.frame = CGRect(origin: CGPoint(x: CGFloat(index) * pager.frame.width, y: 0), size: pager.frame.size)
        }
        pager.contentSize = CGSize(width: CGFloat(panes.count) * pager.frame.width, height: pager.frame.height)
        scrollToPaneAtIndex(currentPaneIndex)
        panes[currentPaneIndex].codeInputView.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
}

extension PagingPasscodeViewController {
    func scrollToNextAndSelect() -> PasscodePane {
        scrollToNextPane()
        panes[currentPaneIndex].codeInputView.becomeFirstResponder()
        return panes[currentPaneIndex]
    }

    func scrollToPreviousAndSelect() -> PasscodePane {
        scrollToPreviousPane()
        panes[currentPaneIndex].codeInputView.becomeFirstResponder()
        return panes[currentPaneIndex]
    }

    func resetAllInputFields() {
        panes.forEach { $0.codeInputView.resetCode() }
    }

    func scrollToNextPane() {
        guard (currentPaneIndex + 1) < panes.count else {
            return
        }
        currentPaneIndex += 1
        scrollToPaneAtIndex(currentPaneIndex)
    }

    func scrollToPreviousPane() {
        guard (currentPaneIndex - 1) >= 0 else {
            return
        }
        currentPaneIndex -= 1
        scrollToPaneAtIndex(currentPaneIndex)
    }

    func scrollToPaneAtIndex(index: Int) {
        UIView.animateWithDuration(PaneSwipeDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pager.contentOffset = CGPoint(x: CGFloat(self.currentPaneIndex) * self.pager.frame.width, y: 0)
        }, completion: nil)
    }
}