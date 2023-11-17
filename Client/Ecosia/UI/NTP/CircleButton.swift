/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Common

class CircleButton: ToolbarButton {
    enum Config {
        case search
        case newTab
        
        var image: String {
            switch self {
            case .search: return "searchUrl"
            case .newTab: return "nav-add"
            }
        }
        var shouldHideCircle: Bool {
            switch self {
            case .search: return false
            case .newTab: return true
            }
        }
        var accessibilityLabel: String {
            switch self {
            case .search: return .TabToolbarSearchAccessibilityLabel
            case .newTab: return .TabTrayButtonNewTabAccessibilityLabel
            }
        }
    }

    let circle = UIView()
    var config: Config = .search {
        didSet {
            setup()
        }
    }
    private var margin: CGFloat = 8
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    convenience init(config: Config, margin: CGFloat = 8) {
        self.init(frame: .zero)
        self.config = config
        self.margin = margin
        setup()
    }

    private func setup() {
        setImage(.templateImageNamed(config.image), for: .normal)
        circle.isUserInteractionEnabled = false
        addSubview(circle)
        sendSubviewToBack(circle)
        accessibilityLabel = config.accessibilityLabel
        accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.TabToolbar.circleButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = bounds.height - margin
        circle.bounds = .init(size: .init(width: height, height: height))
        circle.layer.cornerRadius = circle.bounds.height / 2
        circle.center = .init(x: bounds.width/2, y: bounds.height/2)
        circle.isHidden = config.shouldHideCircle
    }
    
    override func applyTheme(theme: Theme) {
        circle.backgroundColor = .legacyTheme.ecosia.tertiaryBackground
        tintColor = config.shouldHideCircle ? .legacyTheme.ecosia.primaryText : .legacyTheme.ecosia.primaryButton
        selectedTintColor = .legacyTheme.ecosia.primaryButtonActive
        unselectedTintColor = tintColor
    }
}
