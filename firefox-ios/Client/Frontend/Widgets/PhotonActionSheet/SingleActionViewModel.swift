// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum PhotonActionSheetIconType: Sendable {
    case Image
    case URL
    case TabsButton
    case None
}

// One row on the PhotonActionSheet table view can contain more than one item
struct PhotonRowActions {
    let items: [SingleActionViewModel]
    init(_ items: [SingleActionViewModel]) {
        self.items = items
    }

    init(_ item: SingleActionViewModel) {
        self.items = [item]
    }
}

// MARK: - SingleActionViewModel
struct SingleActionViewModel: Sendable {
    enum IconAlignment {
        case left
        case right
    }

    // MARK: - Properties
    let text: String?
    let iconString: String?
    let iconURL: URL?
    let iconType: PhotonActionSheetIconType
    let allowIconScaling: Bool
    let iconAlignment: IconAlignment
    let needsIconActionableTint: Bool

    let bold: Bool
    let tabCount: String?
    let tapHandler: (@MainActor (SingleActionViewModel) -> Void)?

    let isEnabled: Bool // Used by toggles like night mode to switch tint color
    // Flip the cells for the main menu (hamburger menu) since content needs to appear at the bottom
    // Both cells and tableview are flipped so content already appears at bottom when the menu is opened.
    // This avoids having to scroll the table view.
    let isFlipped: Bool

    // Enable title customization beyond what the interface provides,
    let customRender: (@MainActor (_ title: UILabel, _ contentView: UIView) -> Void)?

    // Enable height customization
    let customHeight: (@MainActor (SingleActionViewModel) -> CGFloat)?

    // Normally the icon name is used, but if there is no icon, this is used.
    let accessibilityId: String?

    // MARK: - Initializers
    init(title: String,
         text: String? = nil,
         iconString: String? = nil,
         iconURL: URL? = nil,
         iconType: PhotonActionSheetIconType = .Image,
         allowIconScaling: Bool = false,
         iconAlignment: IconAlignment = .left,
         needsIconActionableTint: Bool = false,
         isEnabled: Bool = false,
         bold: Bool? = false,
         tabCount: String? = nil,
         isFlipped: Bool = false,
         tapHandler: (@MainActor (SingleActionViewModel) -> Void)? = nil,
         customRender: (@MainActor (_ title: UILabel, _ contentView: UIView) -> Void)? = nil,
         customHeight: (@MainActor (SingleActionViewModel) -> CGFloat)? = nil,
         accessibilityId: String? = nil
    ) {
        self.title = title
        self.iconString = iconString
        self.iconURL = iconURL
        self.iconType = iconType
        self.iconAlignment = iconAlignment
        self.allowIconScaling = allowIconScaling
        self.needsIconActionableTint = needsIconActionableTint
        self.isEnabled = isEnabled
        self.tapHandler = tapHandler
        self.text = text
        self.bold = bold ?? false
        self.tabCount = tabCount
        self.isFlipped = isFlipped
        self.customRender = customRender
        self.customHeight = customHeight
        self.accessibilityId = accessibilityId
    }

    static func copy(
        _ vmodel: SingleActionViewModel,
        isEnabled: Bool? = nil,
        isFlipped: Bool? = nil
    ) -> SingleActionViewModel {
        return SingleActionViewModel(
            title: vmodel.title,
            text: vmodel.text,
            iconString: vmodel.iconString,
            iconURL: vmodel.iconURL,
            iconType: vmodel.iconType,
            allowIconScaling: vmodel.allowIconScaling,
            iconAlignment: vmodel.iconAlignment,
            needsIconActionableTint: vmodel.needsIconActionableTint,
            isEnabled: isEnabled ?? vmodel.isEnabled,
            bold: vmodel.bold,
            tabCount: vmodel.tabCount,
            isFlipped: isFlipped ?? vmodel.isFlipped,
            tapHandler: vmodel.tapHandler
        )
    }

    // MARK: - MultiRowSetup

    // Title used by default
    private(set) var title: String

    // Current title looks at the layout direction
    // Horizontal uses the default title, vertical uses the alternate title
    var currentTitle: String {
        return title
    }

    // MARK: Convenience
    var items: PhotonRowActions {
        return PhotonRowActions(self)
    }
}
