// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

@available(iOS 16.0, *)
@MainActor
public final class EcosiaAccountAvatarViewModel: ObservableObject {

    @Published public var avatarURL: URL?
    @Published public var progress: Double
    @Published public var showSparkles = false
    @Published public var currentLevelNumber: Int
    @Published public var seedCount: Int = 0

    private let authStateProvider: EcosiaAuthUIStateProvider
    private var cancellables = Set<AnyCancellable>()
    private var progressObserver: NSObjectProtocol?
    private var levelUpObserver: NSObjectProtocol?
    private var previousSeedCount: Int = 0

    private struct UX {
        static let defaultProgress: Double = 0.25
        static let defaultLevel: Int = 1
        static let levelUpDuration: TimeInterval = 2.0
    }

    public init(
        avatarURL: URL? = nil,
        progress: Double = 0.25,
        seedCount: Int = 0,
        levelNumber: Int = 1,
        authStateProvider: EcosiaAuthUIStateProvider = .shared
    ) {
        self.authStateProvider = authStateProvider
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress))
        self.seedCount = seedCount
        self.previousSeedCount = seedCount
        self.currentLevelNumber = levelNumber

        setupInitialState()
        setupObservers()
    }

    deinit {
        [progressObserver, levelUpObserver].forEach {
            if let observer = $0 {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        cancellables.removeAll()
    }

    public func updateAvatarURL(_ url: URL?) {
        avatarURL = url
    }

    public func updateProgress(_ newProgress: Double) {
        let clampedProgress = max(0.0, min(1.0, newProgress))
        progress = clampedProgress
        }

#if DEBUG
    /// Manual level up for testing/previews only
    public func levelUp() {
        progress = 1.0
        triggerSparkles(duration: UX.levelUpDuration)

        Task {
            try await Task.sleep(for: .seconds(UX.levelUpDuration))
            progress = 0.0
        }
    }
#endif

    public func triggerSparkles(duration: TimeInterval = 4.0) {
        showSparkles = true

        Task {
            try await Task.sleep(for: .seconds(duration))
            showSparkles = false
        }
    }

    /// Updates avatar progress based on AccountVisitResponse
    public func updateFromBalanceResponse(_ response: AccountVisitResponse) {
        let newSeedCount = response.seeds.totalAmount
        let newLevelNumber = response.growthPoints.level.number
        let newProgress = response.progressToNextLevel

        // Update seed count
        previousSeedCount = seedCount
        seedCount = newSeedCount

        // Update level and progress from API
        currentLevelNumber = newLevelNumber
        progress = newProgress

        // Check for level up using growth points
        if response.didLevelUp {
            triggerLevelUpAnimation(targetProgress: newProgress)
            EcosiaLogger.accounts.info("User leveled up to level \(newLevelNumber) via growth points")
        }

        EcosiaLogger.accounts.info("Avatar received balance update: seeds=\(newSeedCount), level=\(newLevelNumber), progress=\(newProgress)")
    }

    /// Updates seed count manually (for local/offline scenarios - logged-out users)
    /// Note: Logged-out users collect seeds but cannot level up. Leveling requires authentication.
    public func updateSeedCount(_ newSeedCount: Int) {
        previousSeedCount = seedCount
        seedCount = newSeedCount
        // No level calculation for logged-out users - they don't participate in the leveling system
        EcosiaLogger.accounts.info("Seed count updated to \(newSeedCount) (logged-out, no leveling)")
    }

    private func triggerLevelUpAnimation(targetProgress: Double) {
        progress = 1.0
        triggerSparkles(duration: UX.levelUpDuration)

        Task {
            try await Task.sleep(for: .seconds(UX.levelUpDuration))
            progress = targetProgress
        }
    }

    private func setupInitialState() {
        avatarURL = authStateProvider.avatarURL
    }

    private func setupObservers() {
        // Subscribe to avatarURL changes from centralized provider
        authStateProvider.$avatarURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newAvatarURL in
                self?.avatarURL = newAvatarURL
            }
            .store(in: &cancellables)

        // Subscribe to isLoggedIn changes to reset progress when logging out
        authStateProvider.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                guard let self = self else { return }
                if !isLoggedIn {
                    self.progress = UX.defaultProgress
                }
            }
            .store(in: &cancellables)

        // Keep existing notification-based observers for progress and level-up
        progressObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleProgressUpdate(notification)
        }

        levelUpObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAccountLevelUp,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleLevelUp(notification)
        }
    }

    nonisolated private func handleProgressUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newProgress = userInfo[EcosiaAccountNotificationKeys.progress] as? Double else {
            return
        }

        Task { @MainActor in
            updateProgress(newProgress)
        }
    }

    nonisolated private func handleLevelUp(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newLevel = userInfo[EcosiaAccountNotificationKeys.newLevel] as? Int,
              let newProgress = userInfo[EcosiaAccountNotificationKeys.newProgress] as? Double else {
            return
        }

        Task { @MainActor in
            currentLevelNumber = newLevel
            triggerLevelUpAnimation(targetProgress: newProgress)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
extension EcosiaAccountAvatarViewModel {
    static func preview(
        avatarURL: URL? = URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
        progress: Double = 0.75,
        showSparkles: Bool = false
    ) -> EcosiaAccountAvatarViewModel {
        let viewModel = EcosiaAccountAvatarViewModel(
            avatarURL: avatarURL,
            progress: progress
        )

        if showSparkles {
            viewModel.showSparkles = true
        }

        return viewModel
    }
}
#endif
