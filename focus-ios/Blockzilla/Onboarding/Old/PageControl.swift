/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol PageControlDelegate {
    func incrementPage(_ pageControl: PageControl)
    func decrementPage(_ pageControl: PageControl)
}

class PageControl: UIView {

    var currentPage = 0 {
        didSet {
            selectIndex(currentPage)
        }
    }

    var numberOfPages = 0 {
        didSet {
            addPages()
        }
    }

    var stack = UIStackView()
    var delegate: PageControlDelegate?

    func addPages() {
        var buttonArray = [UIButton]()

        // Ensure we have at least one button
        if numberOfPages == 0 {
            return
        }

        for _ in 0..<numberOfPages {
            let button = UIButton(frame: UIConstants.layout.introViewButtonFrame)
            button.setImage(UIImage(imageLiteralResourceName: "page_indicator"), for: .normal)
            buttonArray.append(button)
        }

        // Enable the buttons to be tapped to switch to a new page
        buttonArray.forEach { button in
            button.addTarget(self, action: #selector(selected(sender:)), for: .touchUpInside)
        }

        stack = UIStackView(arrangedSubviews: buttonArray)
        stack.spacing = 20
        stack.distribution = .equalCentering
        stack.alignment = .center
        stack.accessibilityIdentifier = "Intro.stackView"

        currentPage = 0
    }

    func selectIndex(_ index: Int) {
        guard let buttons = stack.arrangedSubviews as? [UIButton] else { return }
        for button in buttons {
            button.isSelected = false
            button.alpha = 0.3
        }

        buttons[index].isSelected = true
        buttons[index].alpha = 1
    }

    @objc func selected(sender: UIButton) {
        guard let buttonSubviews = stack.arrangedSubviews as? [UIButton] else {
            return
        }

        guard let buttonIndex = buttonSubviews.firstIndex(of: sender) else {
            return
        }

        if buttonIndex > currentPage {
            currentPage += 1
            delegate?.incrementPage(self)
        } else if buttonIndex < currentPage {
            currentPage -= 1
            delegate?.decrementPage(self)
        }
    }
}
