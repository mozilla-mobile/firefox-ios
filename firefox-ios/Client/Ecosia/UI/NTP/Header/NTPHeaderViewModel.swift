// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SwiftUI
import Ecosia
import Combine

final class NTPHeaderViewModel: ObservableObject {
    struct UX {
        static let topInset: CGFloat = 24
    }

    // MARK: - Properties
    internal weak var delegate: NTPHeaderDelegate?
    internal var theme: Theme
    private let windowUUID: WindowUUID
    let profile: Profile
    private(set) var auth: EcosiaAuth
    var onTapAction: ((UIButton) -> Void)?
    private let authStateProvider = EcosiaAuthUIStateProvider.shared
    private var cancellables = Set<AnyCancellable>()

    var seedCount: Int { authStateProvider.seedCount }
    var isLoggedIn: Bool { authStateProvider.isLoggedIn }
    var userAvatarURL: URL? { authStateProvider.avatarURL }
    var balanceIncrement: Int? { authStateProvider.balanceIncrement }
    var shouldAnimateSeed: Bool { balanceIncrement != nil }
    @Published var showSeedSparkles: Bool = false

    private var levelUpObserver: NSObjectProtocol?

    // MARK: - Initialization
    init(profile: Profile,
         theme: Theme,
         windowUUID: WindowUUID,
         auth: EcosiaAuth,
         delegate: NTPHeaderDelegate? = nil) {
        self.profile = profile
        self.theme = theme
        self.windowUUID = windowUUID
        self.auth = auth
        self.delegate = delegate

        // Forward objectWillChange notifications from authStateProvider
        // This ensures SwiftUI knows to update the view when auth state changes
        authStateProvider.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        setupLevelUpObserver()
    }

    deinit {
        if let observer = levelUpObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupLevelUpObserver() {
        levelUpObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountLevelUp,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerSeedSparkles()
        }
    }

    private func triggerSeedSparkles() {
        showSeedSparkles = true

        // Turn off sparkles after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showSeedSparkles = false
        }
    }

    // MARK: - Public Methods

    func openAISearch() {
        delegate?.headerOpenAISearch()
        Analytics.shared.aiSearchNTPButtonTapped()
    }

    func performLogin() {
        auth.login()
    }

    func performLogout() {
        EcosiaLogger.auth.info("Performing immediate logout without confirmation")
        auth.logout()
    }

    @MainActor
    func refreshSeedState() {
        authStateProvider.refreshSeedState()
    }
}

// MARK: HomeViewModelProtocol
extension NTPHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .header
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topInset,
            leading: 0,
            bottom: 0,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        return true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize, isPortrait: Bool, device: UIUserInterfaceIdiom) {
        // No data refresh needed for multi-purpose header
    }
}

extension NTPHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 16.0, *) {
            guard let headerCell = cell as? NTPHeader else { return cell }
            headerCell.configure(with: self, windowUUID: windowUUID)
            return headerCell
        }
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        // This cell handles its own button actions, no cell selection needed
    }
}
