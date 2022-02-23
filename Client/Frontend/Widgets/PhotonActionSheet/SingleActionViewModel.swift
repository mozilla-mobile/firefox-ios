// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// One row on the PhotonActionSheet table view can contain more than one item
struct PhotonRowActions {
    var items: [SingleActionViewModel]
    init(_ items: [SingleActionViewModel]) {
        self.items = items
    }

    init(_ item: SingleActionViewModel) {
        self.items = [item]
    }
}

// MARK: - SingleActionViewModel
class SingleActionViewModel {

    enum IconAlignment {
        case left
        case right
    }

    // MARK: - Properties
    private(set) var text: String?
    private(set) var iconString: String?
    private(set) var iconURL: URL?
    private(set) var iconType: PhotonActionSheetIconType
    private(set) var iconAlignment: IconAlignment
    private(set) var iconTint: UIColor?

    var isEnabled: Bool // Used by toggles like nightmode to switch tint color
    private(set) var bold: Bool = false
    private(set) var tabCount: String?
    private(set) var tapHandler: ((SingleActionViewModel) -> Void)?
    private(set) var badgeIconName: String?

    // Flip the cells for the main menu (hamburger menu) since content needs to appear at the bottom
    // Both cells and tableview are flipped so content already appears at bottom when the menu is opened.
    // This avoids having to scroll the table view.
    public var isFlipped: Bool = false

    public var tintColor: UIColor?

    // Enable title customization beyond what the interface provides,
    public var customRender: ((_ title: UILabel, _ contentView: UIView) -> Void)?

    // Enable height customization
    public var customHeight: ((SingleActionViewModel) -> CGFloat)?

    // Normally the icon name is used, but if there is no icon, this is used.
    public var accessibilityId: String?

    // MARK: - Initializers
    init(title: String,
         alternateTitle: String? = nil,
         text: String? = nil,
         iconString: String? = nil,
         iconURL: URL? = nil,
         iconType: PhotonActionSheetIconType = .Image,
         iconAlignment: IconAlignment = .left,
         iconTint: UIColor? = nil,
         isEnabled: Bool = false,
         badgeIconNamed: String? = nil,
         bold: Bool? = false,
         tabCount: String? = nil,
         tapHandler: ((SingleActionViewModel) -> Void)? = nil) {

        self.title = title
        self.alternateTitle = alternateTitle
        self.iconString = iconString
        self.iconURL = iconURL
        self.iconType = iconType
        self.iconAlignment = iconAlignment
        self.isEnabled = isEnabled
        self.tapHandler = tapHandler
        self.text = text
        self.bold = bold ?? false
        self.tabCount = tabCount
        self.badgeIconName = badgeIconNamed
    }

    // MARK: - MultiRowSetup

    // Title used by default
    private(set) var title: String

    // Alternate title is the title used when the layout changed on multiple items row
    private(set) var alternateTitle: String?

    // Current title looks at the layout direction
    // Horizontal uses the default title, vertical uses the alternate title
    var currentTitle: String {
        return multipleItemsSetup.axis == .horizontal ? title : alternateTitle ?? title
    }

    // The layout changes when there's multiple items in a row,
    // and there's not enough space in one row to show the labels without truncating
    var multipleItemsSetup = MultipleItemsSetup()
    struct MultipleItemsSetup {
        var isMultiItems = false
        var axis: NSLayoutConstraint.Axis = .horizontal
    }

    // MARK: Conveniance
    var items: PhotonRowActions {
        return PhotonRowActions(self)
    }
}
