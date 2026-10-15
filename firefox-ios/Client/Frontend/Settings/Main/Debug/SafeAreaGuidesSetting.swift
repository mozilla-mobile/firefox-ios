// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class SafeAreaGuidesSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "SafeAreaGuidesSetting.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "DUO safe area guide")
    }

    override var accessoryType: UITableViewCell.AccessoryType {
        return (settings.view.window as? BrowserWindow)?.showsSafeAreaDebugGuides == true ? .checkmark : .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let window = settings.view.window as? BrowserWindow else { return }
        window.showsSafeAreaDebugGuides.toggle()
        settings.tableView.reloadData()
    }
}

@MainActor
final class SafeAreaDebugGuides {
    let layer = CALayer()
    private let unsafeArea = CAShapeLayer()
    private let reservedArea = CAShapeLayer()

    init() {
        layer.zPosition = 10_000
        layer.masksToBounds = true
        unsafeArea.fillColor = UIColor.red.withAlphaComponent(0.35).cgColor
        unsafeArea.fillRule = .evenOdd
        reservedArea.fillColor = UIColor.blue.withAlphaComponent(0.35).cgColor
        layer.addSublayer(unsafeArea)
        layer.addSublayer(reservedArea)
    }

    func update(in view: UIView) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        layer.frame = view.bounds
        let localBounds = CGRect(origin: .zero, size: view.bounds.size)
        unsafeArea.frame = localBounds
        reservedArea.frame = localBounds
        let safeRect = localBounds.inset(by: view.safeAreaInsets).intersection(localBounds)
        let unsafePath = UIBezierPath(rect: localBounds)
        if !safeRect.isEmpty {
            unsafePath.append(UIBezierPath(rect: safeRect))
        }
        unsafeArea.path = unsafePath.cgPath

        let reservedPath = UIBezierPath()
        // Temporary api gate until we are able to build with Xcode 27.1 in Bitrise
        // This api does not exist in Xcode 27.0, and both SDKs use the same
        // Swift compiler which makes it hard to distinguish.
        #if XCODE_2710 || XCODE_2720
        if #available(iOS 27.1, *) {
            let regions = view.reservedRegions(kind: .occlusion) + view.reservedRegions(kind: .division)
            for region in regions where region.isActive {
                let frame = region.frame.offsetBy(dx: -view.bounds.minX, dy: -view.bounds.minY)
                    .intersection(localBounds)
                if !frame.isEmpty {
                    reservedPath.append(UIBezierPath(rect: frame))
                }
            }
        }
        // This error will remind us to remove those checks once new Xcode versions show up.
        #elseif !XCODE_MAJOR_2600 && !XCODE_2700
        #error("Update the Xcode version checks for reservedRegions in SafeAreaGuidesSetting.swift.")
        #endif
        reservedArea.path = reservedPath.cgPath
    }
}
