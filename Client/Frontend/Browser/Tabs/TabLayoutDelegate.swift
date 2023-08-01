// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var tabPeekDelegate: TabPeekDelegate?
    var lastYOffset: CGFloat = 0
    var tabDisplayManager: TabDisplayManager

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
            return GridTabViewController.UX.compactNumberOfColumnsThin
        } else {
            return GridTabViewController.UX.numberOfColumnsWide
        }
    }

    init(tabDisplayManager: TabDisplayManager, traitCollection: UITraitCollection) {
        self.tabDisplayManager = tabDisplayManager
        self.traitCollection = traitCollection
        super.init()
    }

    private func cellHeightForCurrentDevice() -> CGFloat {
        if traitCollection.verticalSizeClass == .compact ||
            traitCollection.horizontalSizeClass == .compact {
            return GridTabViewController.UX.textBoxHeight * 6
        } else {
            return GridTabViewController.UX.textBoxHeight * 8
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch TabDisplaySection(rawValue: section) {
        case .regularTabs:
            if let groups = tabDisplayManager.tabGroups, !groups.isEmpty {
                return sectionHeaderSize
            }
        default: return .zero
        }

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
        return GridTabViewController.UX.margin
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let margin = GridTabViewController.UX.margin * CGFloat(numberOfColumns + 1)
        let calculatedWidth = collectionView.bounds.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right - margin
        let cellWidth = floor(calculatedWidth / CGFloat(numberOfColumns))

        switch TabDisplaySection(rawValue: indexPath.section) {
        case .inactiveTabs:
            return calculateInactiveTabSizeHelper(collectionView)

        case .groupedTabs:
            let width = collectionView.frame.size.width
            if let groupCount = tabDisplayManager.tabGroups?.count, groupCount > 0 {
                let height: CGFloat = GroupedTabCellProperties.CellUX.defaultCellHeight * CGFloat(groupCount)
                return CGSize(width: width >= 0 ? Int(width) : 0, height: Int(height))
            } else {
                return CGSize(width: 0, height: 0)
            }

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

        let closeAllButtonHeight = InactiveTabCell.UX.CloseAllTabRowHeight
        let headerHeightWithRoundedCorner = InactiveTabCell.UX.HeaderAndRowHeight + InactiveTabCell.UX.RoundedContainerPaddingClosed
        var totalHeight = headerHeightWithRoundedCorner
        let width: CGFloat = collectionView.frame.size.width - InactiveTabCell.UX.InactiveTabTrayWidthPadding
        let inactiveTabs = inactiveTabViewModel.inactiveTabs

        // Calculate height based on number of tabs in the inactive tab section section
        let calculatedInactiveTabsTotalHeight = (InactiveTabCell.UX.HeaderAndRowHeight * CGFloat(inactiveTabs.count)) +
        InactiveTabCell.UX.RoundedContainerPaddingClosed +
        InactiveTabCell.UX.RoundedContainerAdditionalPaddingOpened + closeAllButtonHeight

        totalHeight = tabDisplayManager.isInactiveViewExpanded ? calculatedInactiveTabsTotalHeight : headerHeightWithRoundedCorner

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
                top: GridTabViewController.UX.margin,
                left: GridTabViewController.UX.margin + collectionView.safeAreaInsets.left,
                bottom: GridTabViewController.UX.margin,
                right: GridTabViewController.UX.margin + collectionView.safeAreaInsets.right)

        case .inactiveTabs:
            guard !tabDisplayManager.isPrivate,
                  tabDisplayManager.inactiveViewModel?.inactiveTabs.count ?? 0 > 0
            else { return .zero }

            return UIEdgeInsets(equalInset: GridTabViewController.UX.margin)

        case .groupedTabs:
            guard tabDisplayManager.shouldEnableGroupedTabs,
                  tabDisplayManager.tabGroups?.count ?? 0 > 0
            else { return .zero }

            return UIEdgeInsets(equalInset: GridTabViewController.UX.margin)
        }
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabViewController.UX.margin
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

        let tabVC = TabPeekViewController(tab: tab, delegate: tabPeekDelegate)
        if let browserProfile = tabDisplayManager.profile as? BrowserProfile,
           let pickerDelegate = tabPeekDelegate as? DevicePickerViewControllerDelegate {
            tabVC.setState(withProfile: browserProfile, clientPickerDelegate: pickerDelegate)
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: { return tabVC },
                                          actionProvider: tabVC.contextActions(defaultActions:))
    }
}
