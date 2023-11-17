// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

/* Ecosia: Update ToolbarButton to allow ThemeApplicable
   functions to be overridden
class ToolbarButton: UIButton {
 */
class ToolbarButton: UIButton, ThemeApplicable {
    // MARK: - Variables
    
    // Ecosia: Modify accessors
    // private var selectedTintColor: UIColor!
    // private var unselectedTintColor: UIColor!
    var selectedTintColor: UIColor!
    var unselectedTintColor: UIColor!
    private var disabledTintColor: UIColor!

    // Optionally can associate a separator line that hide/shows along with the button
    weak var separatorLine: UIView?

    override open var isHighlighted: Bool {
        didSet {
            self.tintColor = isHighlighted ? selectedTintColor : unselectedTintColor
        }
    }

    override open var isEnabled: Bool {
        didSet {
            self.tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        }
    }

    override var tintColor: UIColor! {
        didSet {
            self.imageView?.tintColor = self.tintColor
        }
    }

    override var isHidden: Bool {
        didSet {
            separatorLine?.isHidden = isHidden
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        selectedTintColor = tintColor
        unselectedTintColor = tintColor
        imageView?.contentMode = .scaleAspectFit
        configuration = .plain()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
/* Ecosia: Update ToolbarButton to allow ThemeApplicable
       functions to be overridden
}

// MARK: - Theme protocols

extension ToolbarButton: ThemeApplicable {
    func applyTheme(theme: Theme) {
        selectedTintColor = theme.colors.actionPrimary
        disabledTintColor = theme.colors.iconDisabled
        unselectedTintColor = theme.colors.iconPrimary
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        imageView?.tintColor = tintColor
    }
}
*/
    // MARK: - Theme protocols

    func applyTheme(theme: Theme) {
        /* Ecosia: Update colors
        selectedTintColor = theme.colors.actionPrimary
        disabledTintColor = theme.colors.iconDisabled
         */
        selectedTintColor = .legacyTheme.ecosia.primaryBrand
        disabledTintColor = UIColor.Photon.Grey30
        unselectedTintColor = theme.colors.iconPrimary
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        // Ecosia: Unneded as set in didSet{} accessor
        // imageView?.tintColor = tintColor
    }
}
