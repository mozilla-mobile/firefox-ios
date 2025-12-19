// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine
import Common

/// Centralized, reactive authentication state provider for consistent UI state across all components
/// This eliminates the need for individual components to manage their own auth state observers
public class EcosiaAuthUIStateProvider: ObservableObject {

    /// Auth0 gives us back a Gravatar URL when no profile picture URL is provided from a resource (e.g. Sign In with Apple)
    /// We want to strip it, therefore we track the URL
    private let gravatarURL = URL(string: "https://s.gravatar.com/avatar/")

    // MARK: - Published Properties

    /// Current authentication status
    @Published public private(set) var isLoggedIn: Bool = false

    /// Current user profile information
    @Published public private(set) var userProfile: UserProfile?

    /// Current seed count (server-based for logged in users, local for guests)
    /// Initialized with local storage value to prevent flickering on app launch
    @Published public private(set) var seedCount: Int = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

    /// Current user avatar URL
    @Published public private(set) var avatarURL: URL?

    /// Current username for display
    @Published public private(set) var username: String?

    /// Balance increment for animations (temporary state)
    @Published public private(set) var balanceIncrement: Int?

    /// Current level number (from API for logged-in users, 1 for logged-out)
    @Published public private(set) var currentLevelNumber: Int = 1

    /// Current progress towards next level (from API for logged-in users, default 0.25 for initial state)
    @Published public private(set) var currentProgress: Double = 0.25

    /// Error state for register visit failures (read-only externally, set only by this class)
    @Published public private(set) var hasRegisterVisitError: Bool = false

    // MARK: - Private Properties

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private var seedProgressObserver: NSObjectProtocol?
    private let accountsProvider: AccountsProviderProtocol
    /// Normalizing the avatar to match Web's Product behaviour.
    /// Our Auth Provider (Auth0) sends us a Gravatar URL when no profile image is retrieved from a user
    /// (e.g. Apple Sign In). As of now, we replace it with our tree-image in `EcosiaAvatar` by not setting any URL
    private var normalizedAvatarURL: URL? {
        guard userProfile?.pictureURL?.baseDomain != gravatarURL?.baseDomain else { return nil }
        return userProfile?.pictureURL
    }
    private static var seedProgressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self

    // MARK: - Singleton

    /// Factory for creating accounts provider - can be configured before first access
    public static var accountsProviderFactory: () -> AccountsProviderProtocol = { AccountsProvider() }

    /// Shared instance for app-wide auth state
    public static let shared = EcosiaAuthUIStateProvider(accountsProvider: accountsProviderFactory())

    public init(accountsProvider: AccountsProviderProtocol) {
        self.accountsProvider = accountsProvider

        // Initialize state synchronously to prevent flickering
        self.isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        self.userProfile = EcosiaAuthenticationService.shared.userProfile
        self.avatarURL = normalizedAvatarURL
        self.username = userProfile?.name

        // If logged out, ensure seed count is loaded (already done in property initializer)
        // If logged in, seed count will be updated from API in initializeState()

        setupAuthStateMonitoring()
        initializeState()
    }

    deinit {
        if let observer = authStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = userProfileObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = seedProgressObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Interface

    /// Computed property for user display text
    public var userDisplayText: String {
        username ?? String.localized(.guestUser)
    }

    /// Computed property for level display text
    /// Returns level number and name for logged-in users, empty string for logged-out users
    public var levelDisplayText: String {
        let levelNumber = currentLevelNumber
        let levelName = GrowthPointsLevelSystem.levelName(for: levelNumber)
        return "\(String.localized(.level)) \(levelNumber) - \(levelName)"
    }

    /// Computed property for level progress (0.0 to 1.0)
    /// Returns progress from API for logged-in users, 0.25 default for initial/logged-out state
    public var levelProgress: Double {
        guard isLoggedIn else {
            return 0.25 // Default progress for logged-out users
        }
        return currentProgress
    }

    // MARK: - Private Methods

    private func setupAuthStateMonitoring() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleAuthStateChange(notification)
            }
        }

        // Listen for user profile updates
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleUserProfileUpdate()
            }
        }

        // Listen for seed progress updates (for logged-out users)
        seedProgressObserver = NotificationCenter.default.addObserver(
            forName: UserDefaultsSeedProgressManager.progressUpdatedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleSeedProgressUpdate()
            }
        }
    }

    /// Initializes the state based on authentication status.
    private func initializeState() {
        Task {
            await refreshSeedState()
        }
    }

    private func handleAuthStateChange(_ notification: Notification) async {
        // Handle specific auth actions (business logic can be nonisolated)
        if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType {
            switch actionType {
            case .userLoggedIn:
                EcosiaLogger.accounts.info("User logged in - registering visit")
                registerVisitIfNeeded()
            case .userLoggedOut:
                EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
                await resetToLocalSeedCollection()
                await handleLocalSeedCollection()
            case .authStateLoaded:
                break // State already updated above
            }
        }
    }

    @MainActor
    private func handleUserProfileUpdate() {
        Task { @MainActor in
            isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        }
        userProfile = EcosiaAuthenticationService.shared.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }

    @MainActor
    private func handleSeedProgressUpdate() {
        // Only handle for logged-out users
        guard !isLoggedIn else { return }

        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        // If seed count increased, show animation
        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            EcosiaLogger.accounts.info("Seed progress updated for logged-out user: \(seedCount) → \(newSeedCount) (+\(increment))")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Seed Count Management

    /// Registers a user visit to fetch the latest balance from the backend.
    ///
    /// Only proceeds if a valid access token is available (user is logged in).
    /// Updates the balance and level information on success.
    /// Sets `hasRegisterVisitError` to `true` on failure.
    private func registerVisitIfNeeded() {
        Task {
            do {
                guard let accessToken = EcosiaAuthenticationService.shared.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
                    return
                }

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)
                await updateBalance(response)

                // Clear error on success
                await MainActor.run {
                    hasRegisterVisitError = false
                }
            } catch {
                EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")

                // Set error state
                await MainActor.run {
                    hasRegisterVisitError = true
                }
            }
        }
    }

    @MainActor
    private func updateBalance(_ response: AccountVisitResponse) {
        let newSeedCount = response.seeds.totalAmount
        let newLevelNumber = response.growthPoints.level.number
        let newProgress = response.progressToNextLevel

        // Update level and progress from API
        currentLevelNumber = newLevelNumber
        currentProgress = newProgress

        // Trigger level-up animation if user leveled up
        if response.didLevelUp {
            EcosiaLogger.accounts.info("Level up detected: triggering animation for level \(newLevelNumber)")
            triggerLevelUpAnimation()
        }

        if let increment = response.seedsIncrement {
            EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(newSeedCount) (+\(increment)), level=\(newLevelNumber), progress=\(newProgress)")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(newSeedCount), level=\(newLevelNumber), progress=\(newProgress)")
            seedCount = newSeedCount
        }
    }

    @MainActor
    private func animateBalanceChange(from oldValue: Int, to newValue: Int, increment: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.balanceIncrement = increment

            withAnimation(.easeIn(duration: 0.3)) {
                self.seedCount = newValue
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.linear(duration: 0.57)) {
                    self.balanceIncrement = nil
                }
            }
        }
    }

    @MainActor
    private func triggerLevelUpAnimation() {
        EcosiaAccountNotificationCenter.postLevelUp(
            newLevel: currentLevelNumber,
            newProgress: currentProgress
        )
    }

    /// Resets to local seed collection system after logout.
    ///
    /// Resets seeds to 0, level to 1, and clears lastAppOpenDate to allow immediate seed collection.
    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")

        Self.seedProgressManagerType.resetLocalSeedProgress()

        seedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()
        currentLevelNumber = 1
        currentProgress = 0.25
    }

    /// Handles daily seed collection for logged-out users.
    ///
    /// Collects one seed per day and animates the increment if a new seed was collected.
    @MainActor
    private func handleLocalSeedCollection() {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        Self.seedProgressManagerType.collectDailySeed()
        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Public Methods

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: Registers a visit to fetch latest balance from server
    /// - For logged-out users: Checks and collects daily seed
    @MainActor
    public func refreshSeedState() {
        if isLoggedIn {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-in user (server fetch)")
            registerVisitIfNeeded()
        } else {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-out user (daily seed check)")
            handleLocalSeedCollection()
        }
    }

    // MARK: - Debug Methods

    /// Debug method to simulate balance updates for testing animations
    /// This allows QA to test seed addition and level-up animations without server calls
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugUpdateBalance(_ response: AccountVisitResponse) {
        updateBalance(response)
        EcosiaLogger.accounts.info("Debug: Balance updated via debug method")
    }

    /// Debug method to directly trigger level-up animation without mock data
    /// This allows QA to test the level-up sparkle animation independently
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugTriggerLevelUpAnimation() {
        triggerLevelUpAnimation()
        EcosiaLogger.accounts.info("Debug: Level-up animation triggered directly")
    }

    /// Debug method to directly add seeds with animation for logged-in users
    /// This allows QA to test seed increment animations without mock responses
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugAddSeeds(_ count: Int) {
        let currentSeeds = seedCount
        let newSeeds = currentSeeds + count
        animateBalanceChange(from: currentSeeds, to: newSeeds, increment: count)
        EcosiaLogger.accounts.info("Debug: Added \(count) seeds for logged-in user (\(currentSeeds) → \(newSeeds))")
    }
}
