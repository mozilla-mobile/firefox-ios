// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Redux
import Shared

@MainActor
final class MerinoMiddleware {
    private let merinoManager: MerinoManagerProvider
    private let homepageTelemetry: HomepageTelemetry
    private let logger: Logger

    init(
        merinoManager: MerinoManagerProvider = AppContainer.shared.resolve(),
        homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.merinoManager = merinoManager
        self.homepageTelemetry = homepageTelemetry
        self.logger = logger
    }

    lazy var pocketSectionProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            HomepageMiddlewareActionType.didBecomeActive,
            MerinoActionType.toggleShowSectionSetting:
            self.getHomepageStoriesAndUpdateState(for: action)
        case MerinoActionType.tapOnHomepageMerinoCell:
            self.sendOpenPocketItemTelemetry(for: action)
        case MerinoActionType.viewedSection:
            self.homepageTelemetry.sendPocketSectionCounter()
        case ContextMenuActionType.tappedOnOpenNewPrivateTab:
            self.sendOpenInPrivateTelemetry(for: action)
        default:
            break
        }
    }

    private func getHomepageStoriesAndUpdateState(for action: Action) {
        let requestID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[Merino] middleware request start id=\(requestID) action=\(action.actionType) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState)",
            level: .info,
            category: .homepage
        )
        Task {
            let merinoStories = await merinoManager.getMerinoItems(source: .homepage)
            let durationMs = FreezeDiag.durationMs(since: start)
            self.logger.log(
                "\(FreezeDiag.prefix)[Merino] middleware request end id=\(requestID) durationMs=\(durationMs) storyCount=\(merinoStories.stories?.count ?? 0) hasCategories=\(merinoStories.categories?.isEmpty == false) appState=\(FreezeDiag.applicationState)",
                level: durationMs > 3000 ? .warning : .info,
                category: .homepage
            )
            self.logger.log(
                "\(FreezeDiag.prefix)[Merino] middleware dispatch retrievedUpdatedHomepageStories id=\(requestID) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState)",
                level: FreezeDiag.isApplicationActive ? .debug : .warning,
                category: .homepage
            )
            store.dispatch(
                MerinoAction(
                    merinoStoryResponse: merinoStories,
                    windowUUID: action.windowUUID,
                    actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
                )
            )
        }
    }

    private func sendOpenPocketItemTelemetry(for action: Action) {
        guard let config = (action as? MerinoAction)?.telemetryConfig else {
            self.logger.log(
                "Unable to retrieve config for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        self.homepageTelemetry.sendTapOnPocketStoryCounter(position: config.position, isZeroSearch: config.isZeroSearch)
    }

    private func sendOpenInPrivateTelemetry(for action: Action) {
        guard case .merino = (action as? ContextMenuAction)?.menuType else {
            self.logger.log(
                "Unable to retrieve section for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        self.homepageTelemetry.sendOpenInPrivateTabEventForPocket()
    }
}
