// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabDisplayViewState {
    var isPrivateTabs: Bool
    var isInactiveTabEmpty: Bool
    var isInactiveTabsExpanded = false
}

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
    }

    var tabDisplayState: TabDisplayViewState
    var inactiveTabsSectionManager: InactiveTabsSectionManager
    var theme: Theme?
    static let defaultIdentifier = "DefaultCollectionReusableView"

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds,
                                              collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(cellType: InactiveTabsCell.self)
        collectionView.register(
            InactiveTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier)
        collectionView.register(
            InactiveTabsFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: InactiveTabsFooterView.cellIdentifier)
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: TabDisplayView.defaultIdentifier)

        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dragInteractionEnabled = true
        // TODO: FXIOS-6926 Create TabDisplayManager and update delegates
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        return collectionView
    }()

    override init(frame: CGRect) {
        tabDisplayState = TabDisplayViewState(isPrivateTabs: false,
                                              isInactiveTabEmpty: false,
                                              isInactiveTabsExpanded: true)
        self.inactiveTabsSectionManager = InactiveTabsSectionManager(collectionViewWidth: 393)
        super.init(frame: frame)
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
            let section = self.getSectionLayout(sectionIndex)
            switch section {
            case .inactiveTabs:
                return self.inactiveTabsSectionManager.layoutSection(layoutEnvironment)
            }
        }
        return layout
    }

    private func getSectionLayout(_ sectionIndex: Int) -> TabDisplaySection {
        guard let section = TabDisplaySection(rawValue: sectionIndex) else { return .inactiveTabs }

        return section
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
        collectionView.backgroundColor = theme.colors.layer3
    }

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return TabDisplaySection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch TabDisplaySection(rawValue: section) {
        case .inactiveTabs:
            // Hide inactive tray if there are no inactive tabs or if is PrivateTabs
            guard !tabDisplayState.isInactiveTabEmpty,
                  !tabDisplayState.isPrivateTabs else { return 0 }

            return tabDisplayState.isInactiveTabsExpanded ? inactiveTabsSectionManager.items.count : 0
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath)
    -> UICollectionReusableView {
        switch TabDisplaySection(rawValue: indexPath.section) {
        case .inactiveTabs:
            if kind == UICollectionView.elementKindSectionHeader,
               let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier,
                for: indexPath) as? InactiveTabsHeaderView {
                view.state = tabDisplayState.isInactiveTabsExpanded ? .down : .trailing
                if let theme = theme {
                    view.applyTheme(theme: theme)
                }
                view.moreButton.isHidden = false
                view.moreButton.addTarget(self,
                                          action: #selector(toggleInactiveTab),
                                          for: .touchUpInside)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                  action: #selector(toggleInactiveTab))
                view.addGestureRecognizer(tapGestureRecognizer)
                return view
            } else if kind == UICollectionView.elementKindSectionFooter,
                      tabDisplayState.isInactiveTabsExpanded,
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

        default: return collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: TabDisplayView.defaultIdentifier,
            for: indexPath)
        }
        return collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: TabDisplayView.defaultIdentifier,
            for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InactiveTabsCell.cellIdentifier, for: indexPath) as? InactiveTabsCell
        else { return UICollectionViewCell() }

        cell.configure(text: inactiveTabsSectionManager.items[indexPath.row])
        if let theme = theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    @objc
    func toggleInactiveTab() {
        toggleInactiveTabSection(hasExpanded: !tabDisplayState.isInactiveTabsExpanded)
    }

    func toggleInactiveTabSection(hasExpanded: Bool) {
        tabDisplayState.isInactiveTabsExpanded = hasExpanded
        collectionView.reloadData()
    }
}
