// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class LegacyTabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var tabPeekDelegate: LegacyTabPeekDelegate?
    var lastYOffset: CGFloat = 0
    var tabDisplayManager: LegacyTabDisplayManager

    var sectionHeaderSize: CGSize {
        CGSize(width: 50, height: 40)
    }

    enum ScrollDirection {
        case up
        case down
    }

    var traitCollection: UITraitCollection
    var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return LegacyGridTabViewController.UX.compactNumberOfColumnsThin
        } else {
            return LegacyGridTabViewController.UX.numberOfColumnsWide
        }
    }

    init(tabDisplayManager: LegacyTabDisplayManager, traitCollection: UITraitCollection) {
        self.tabDisplayManager = tabDisplayManager
        self.traitCollection = traitCollection
        super.init()
    }

    private func cellHeightForCurrentDevice() -> CGFloat {
        if traitCollection.verticalSizeClass == .compact ||
            traitCollection.horizontalSizeClass == .compact {
            return LegacyGridTabViewController.UX.textBoxHeight * 6
        } else {
            return LegacyGridTabViewController.UX.textBoxHeight * 8
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return .zero
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return LegacyGridTabViewController.UX.margin
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let margin = LegacyGridTabViewController.UX.margin * CGFloat(numberOfColumns + 1)
        let calculatedWidth = collectionView.bounds.width -
        collectionView.safeAreaInsets.left -
        collectionView.safeAreaInsets.right - margin
        let cellWidth = floor(calculatedWidth / CGFloat(numberOfColumns))

        switch TabDisplaySection(rawValue: indexPath.section) {
        case .inactiveTabs:
            return calculateInactiveTabSizeHelper(collectionView)

        case .regularTabs, .none:
            guard !tabDisplayManager.filteredTabs.isEmpty else { return CGSize(width: 0, height: 0) }
            return CGSize(width: cellWidth, height: self.cellHeightForCurrentDevice())
        }
    }

    private func calculateInactiveTabSizeHelper(_ collectionView: UICollectionView) -> CGSize {
        guard !tabDisplayManager.isPrivate,
              let inactiveTabViewModel = tabDisplayManager.inactiveViewModel,
              !inactiveTabViewModel.isActiveTabsEmpty
        else {
            return CGSize(width: 0, height: 0)
        }

        let closeAllButtonHeight = LegacyInactiveTabCell.UX.CloseAllTabRowHeight
        let roundedCornerHeaderHeight = LegacyInactiveTabCell.UX.HeaderAndRowHeight +
        LegacyInactiveTabCell.UX.RoundedContainerPaddingClosed
        var totalHeight = roundedCornerHeaderHeight
        let width: CGFloat = collectionView.frame.size.width - LegacyInactiveTabCell.UX.InactiveTabTrayWidthPadding
        let inactiveTabs = inactiveTabViewModel.inactiveTabs

        // Calculate height based on number of tabs in the inactive tab section section
        let calculatedInactiveTabsHeight = (LegacyInactiveTabCell.UX.HeaderAndRowHeight * CGFloat(inactiveTabs.count)) +
        LegacyInactiveTabCell.UX.RoundedContainerPaddingClosed +
        LegacyInactiveTabCell.UX.RoundedContainerAdditionalPaddingOpened + closeAllButtonHeight

        totalHeight = tabDisplayManager.isInactiveViewExpanded ? calculatedInactiveTabsHeight : roundedCornerHeaderHeight

        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGSize(width: collectionView.frame.size.width/1.5, height: totalHeight)
        } else {
            return CGSize(width: width >= 0 ? width : 0, height: totalHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        switch TabDisplaySection(rawValue: section) {
        case .regularTabs, .none:
            return UIEdgeInsets(
                top: LegacyGridTabViewController.UX.margin,
                left: LegacyGridTabViewController.UX.margin + collectionView.safeAreaInsets.left,
                bottom: LegacyGridTabViewController.UX.margin,
                right: LegacyGridTabViewController.UX.margin + collectionView.safeAreaInsets.right)

        case .inactiveTabs:
            guard !tabDisplayManager.isPrivate,
                  tabDisplayManager.inactiveViewModel?.inactiveTabs.count ?? 0 > 0
            else { return .zero }

            return UIEdgeInsets(equalInset: LegacyGridTabViewController.UX.margin)
        }
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return LegacyGridTabViewController.UX.margin
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard TabDisplaySection(rawValue: indexPath.section) == .regularTabs,
              let tab = tabDisplayManager.dataStore.at(indexPath.row)
        else { return nil }

        let tabVC = LegacyTabPeekViewController(tab: tab, delegate: tabPeekDelegate)
        if let browserProfile = tabDisplayManager.profile as? BrowserProfile,
           let pickerDelegate = tabPeekDelegate as? DevicePickerViewControllerDelegate {
            tabVC.setState(withProfile: browserProfile, clientPickerDelegate: pickerDelegate)
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: { return tabVC },
                                          actionProvider: tabVC.contextActions(defaultActions:))
    }
}
