/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class CircleButton: ToolbarButton {
    struct Config {
        let hideCircle: Bool
        let image: String
        let margin: CGFloat

        static var search: Config {
            return .init(hideCircle: false, image: "search", margin: 8)
        }

        static var newTab: Config {
            return .init(hideCircle: true, image: "nav-add", margin: 8)
        }
    }

    let circle = UIView()
    var config: Config = .search {
        didSet {
            setup()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    convenience init(config: Config) {
        self.init(frame: .zero)
        self.config = config
        setup()
    }

    private func setup() {
        setImage(UIImage(named: config.image), for: .normal)
        circle.isUserInteractionEnabled = false
        addSubview(circle)
        sendSubviewToBack(circle)
        applyTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = bounds.height - config.margin
        circle.bounds = .init(size: .init(width: height, height: height))
        circle.layer.cornerRadius = circle.bounds.height / 2
        circle.center = .init(x: bounds.width/2, y: bounds.height/2)
        circle.isHidden = config.hideCircle
    }

    override func applyTheme() {
        circle.backgroundColor = UIColor.theme.ecosia.tertiaryBackground
        tintColor = config.hideCircle ? .theme.ecosia.primaryText : .theme.ecosia.primaryButton
        selectedTintColor = UIColor.theme.ecosia.primaryButtonActive
        unselectedTintColor = tintColor
    }
}
