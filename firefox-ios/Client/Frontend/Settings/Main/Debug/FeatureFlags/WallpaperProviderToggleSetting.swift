// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A debug setting row for switching the active wallpaper provider (Pexels/Unsplash).
final class WallpaperProviderToggleSetting: Setting {
    private let onChange: () -> Void

    override var style: UITableViewCell.CellStyle { return .value1 }
    override var status: NSAttributedString? {
        let current = WallpaperProviderManager.shared.activeProviderType
        return NSAttributedString(string: current.displayName)
    }

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        super.init(title: NSAttributedString(string: "Active Provider"))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Wallpaper Provider",
            message: "Choose the active wallpaper provider",
            preferredStyle: .actionSheet
        )
        for provider in WallpaperProviderType.allCases {
            let isCurrent = WallpaperProviderManager.shared.activeProviderType == provider
            let title = isCurrent ? "✓ \(provider.displayName) (current)" : provider.displayName
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                WallpaperProviderManager.shared.switchProvider(to: provider)
                self.onChange()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController,
           let source = navigationController?.topViewController?.view {
            popover.sourceView = source
            popover.sourceRect = CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 0, height: 0)
        }
        navigationController?.present(alert, animated: true)
    }
}
