// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class TabDisplayView: UIView,
                      ThemeApplicable,
                      UICollectionViewDataSource,
                      UICollectionViewDelegate,
                      UICollectionViewDelegateFlowLayout {
    struct UX {
        static let cornerRadius: CGFloat = 6.0
    }

    enum TabDisplaySection: Int, CaseIterable {
        case inactiveTabs
        case tabs
    }

    private(set) var state: TabViewState
    private var inactiveTabsSectionManager: InactiveTabsSectionManager
    private var tabsSectionManager: TabsSectionManager
    var theme: Theme?

    private var shouldHideInactiveTabs: Bool {
        guard !state.isPrivateMode else { return true }

        return state.inactiveTabs.isEmpty
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds,
                                              collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(cellType: TabCell.self)
        collectionView.register(cellType: InactiveTabsCell.self)
        collectionView.register(
            InactiveTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier)
        collectionView.register(
            InactiveTabsFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: InactiveTabsFooterView.cellIdentifier)

        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dragInteractionEnabled = true
        // TODO: FXIOS-6926 Create TabDisplayManager and update delegates
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        return collectionView
    }()

    public init(state: TabViewState) {
        self.state = state
        self.inactiveTabsSectionManager = InactiveTabsSectionManager()
        self.tabsSectionManager = TabsSectionManager()
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self else { return nil }

            // If on private mode or regular mode but without inactive
            // tabs we return only the tabs layout
            guard !shouldHideInactiveTabs else {
                return self.tabsSectionManager.layoutSection(layoutEnvironment)
            }

            let section = self.getSectionLayout(sectionIndex)
            switch section {
            case .inactiveTabs:
                return self.inactiveTabsSectionManager.layoutSection(
                    layoutEnvironment,
                    isExpanded: state.isInactiveTabsExpanded)
            case .tabs:
                return self.tabsSectionManager.layoutSection(layoutEnvironment)
            }
        }
        return layout
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
        collectionView.backgroundColor = theme.colors.layer3
    }

    // MARK: - Private helpers
    private func getSectionLayout(_ sectionIndex: Int) -> TabDisplaySection {
        guard let section = TabDisplaySection(rawValue: sectionIndex) else { return .tabs }

        return section
    }

    private func getTabDisplay(for section: Int) -> TabDisplaySection {
        guard !shouldHideInactiveTabs else { return .tabs }

        return TabDisplaySection(rawValue: section) ?? .tabs
    }

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard !shouldHideInactiveTabs else { return 1 }

        return TabDisplaySection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch getTabDisplay(for: section) {
        case .inactiveTabs:
            return state.isInactiveTabsExpanded ? state.inactiveTabs.count : 0
        case .tabs:
            guard !state.tabs.isEmpty else { return 0 }

            return state.tabs.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath)
    -> UICollectionReusableView {
        let reusableView = UICollectionReusableView()

        switch getTabDisplay(for: indexPath.section) {
        case .inactiveTabs:
            if kind == UICollectionView.elementKindSectionHeader,
               let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier,
                for: indexPath) as? InactiveTabsHeaderView {
                view.state = state.isInactiveTabsExpanded ? .down : .trailing
                if let theme = theme {
                    view.applyTheme(theme: theme)
                }
                view.moreButton.isHidden = false
                view.moreButton.addTarget(self,
                                          action: #selector(toggleInactiveTab),
                                          for: .touchUpInside)
                view.accessibilityLabel = state.isInactiveTabsExpanded ?
                    .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionOpenedAccessibilityTitle :
                    .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionClosedAccessibilityTitle
                let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                  action: #selector(toggleInactiveTab))
                view.addGestureRecognizer(tapGestureRecognizer)
                return view
            } else if kind == UICollectionView.elementKindSectionFooter,
                      state.isInactiveTabsExpanded,
                      let footerView = collectionView.dequeueReusableSupplementaryView(
                       ofKind: UICollectionView.elementKindSectionFooter,
                       withReuseIdentifier: InactiveTabsFooterView.cellIdentifier,
                       for: indexPath) as? InactiveTabsFooterView {
                if let theme = theme {
                    footerView.applyTheme(theme: theme)
                }
                footerView.buttonClosure = {}
                return footerView
            }

        default: return reusableView
        }
        return reusableView
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
        switch getTabDisplay(for: indexPath.section) {
        case .inactiveTabs:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InactiveTabsCell.cellIdentifier, for: indexPath) as? InactiveTabsCell
            else { return UICollectionViewCell() }

            cell.configure(text: state.inactiveTabs[indexPath.row])
            if let theme = theme {
                cell.applyTheme(theme: theme)
            }
            return cell
        case .tabs:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCell.cellIdentifier, for: indexPath) as? TabCell
            else { return UICollectionViewCell() }

            let tabState = TabCellState(isSelected: false,
                                        isPrivate: false,
                                        isFxHomeTab: false,
                                        tabTitle: "\(indexPath.row)",
                                        url: nil,
                                        screenshot: nil,
                                        hasHomeScreenshot: false,
                                        margin: 0)
            cell.configure(with: tabState, theme: theme)
            return cell
        }
    }

    @objc
    func toggleInactiveTab() {
        toggleInactiveTabSection(hasExpanded: !state.isInactiveTabsExpanded)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func toggleInactiveTabSection(hasExpanded: Bool) {
        state.isInactiveTabsExpanded = hasExpanded
        collectionView.reloadData()
    }
}
