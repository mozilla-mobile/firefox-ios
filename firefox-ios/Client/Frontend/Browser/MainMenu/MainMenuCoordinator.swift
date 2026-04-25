// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SummarizeKit

protocol MainMenuCoordinatorDelegate: AnyObject {
    @MainActor
    func editBookmarkForCurrentTab()

    @MainActor
    func showLibraryPanel(_ panel: Route.HomepanelSection)

    @MainActor
    func showSettings(at destination: Route.SettingsSection)

    @MainActor
    func showFindInPage()

    @MainActor
    func showSignInView(fxaParameters: FxASignInViewParameters?)

    @MainActor
    func updateZoomPageBarVisibility()

    @MainActor
    func presentSavePDFController()

    @MainActor
    func presentSiteProtections()

    @MainActor
    func showPrintSheet()

    @MainActor
    func showReaderMode()

    /// Open the share sheet to share the currently selected `Tab`.
    @MainActor
    func showShareSheetForCurrentlySelectedTab()

    @MainActor
    func showSummarizePanel(_ trigger: SummarizerTrigger, config: SummarizerConfig?)
}

class MainMenuCoordinator: BaseCoordinator, LegacyFeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var navigationHandler: MainMenuCoordinatorDelegate?

    let windowUUID: WindowUUID
    private let profile: Profile

    init(
        router: Router,
        windowUUID: WindowUUID,
        profile: Profile
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        super.init(router: router)
    }

    func startWithNavController() {
        let mainMenuViewController = createMainMenuViewController()

        let mainMenuNavController = UINavigationController(rootViewController: mainMenuViewController)
        mainMenuNavController.isNavigationBarHidden = true

        if let sheetPresentationController = mainMenuNavController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
        }
        mainMenuNavController.sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        mainMenuNavController.sheetPresentationController?.prefersGrabberVisible = true
        router.present(mainMenuNavController, animated: true, completion: nil)
    }

    func start() {
        router.setRootViewController(
            createMainMenuViewController(),
            hideBar: true
        )
    }

    func dismissDetailViewController() {
        router.popViewController(animated: true)
    }

    func removeCoordinatorFromParent() {
        parentCoordinator?.didFinish(from: self)
    }

    func dismissMenuModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        removeCoordinatorFromParent()
    }

    func navigateTo(_ destination: MenuNavigationDestination, animated: Bool) {
        router.dismiss(animated: animated, completion: { [weak self] in
            guard let self else { return }

            self.handleDestination(destination)

            removeCoordinatorFromParent()
        })
    }

    private func handleDestination(_ destination: MenuNavigationDestination) {
        switch destination.destination {
        case .bookmarks:
            navigationHandler?.showLibraryPanel(.bookmarks)

        case .downloads:
            navigationHandler?.showLibraryPanel(.downloads)

        case .editBookmark:
            navigationHandler?.editBookmarkForCurrentTab()

        case .findInPage:
            navigationHandler?.showFindInPage()

        case .history:
            navigationHandler?.showLibraryPanel(.history)

        case .passwords:
            navigationHandler?.showSettings(at: .password)

        case .readerView:
            // TODO: FXIOS-15099 Refactor showReaderMode with NavigationBrowserAction
            navigationHandler?.showReaderMode()

        case .settings:
            navigationHandler?.showSettings(at: .general)

        case .syncSignIn:
            let fxaParameters = FxASignInViewParameters(
                launchParameters: FxALaunchParams(entrypoint: .browserMenu, query: [:]),
                flowType: .emailLoginFlow,
                referringPage: .appMenu
            )
            navigationHandler?.showSignInView(fxaParameters: fxaParameters)

        case .printSheet:
            navigationHandler?.showPrintSheet()

        case .shareSheet:
            navigationHandler?.showShareSheetForCurrentlySelectedTab()

        case .saveAsPDF:
            navigationHandler?.presentSavePDFController()

        case .zoom:
            navigationHandler?.updateZoomPageBarVisibility()

        case .siteProtections:
            navigationHandler?.presentSiteProtections()

        case .defaultBrowser:
            DefaultApplicationHelper().openSettings()

        case .webpageSummary(let config):
            navigationHandler?.showSummarizePanel(.mainMenu, config: config)

        case .translatePage:
            let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID)
            let translationConfig = toolbarState?.addressToolbar.translationConfiguration
            let isTranslated = translationConfig?.state == .active
            let translatedLanguage = translationConfig?.translatedToLanguage
            let isSingleLanguageFlow = if let translationConfig {
                !translationConfig.isMultiLanguageFlow
            } else {
                false
            }
            let prefs = profile.prefs
            Task {
                let manager = PreferredTranslationLanguagesManager(prefs: prefs)
                let supported = await ASTranslationModelsFetcher.shared.fetchSupportedTargetLanguages()
                let languages = manager.preferredLanguages(supportedTargetLanguages: supported)
                let pageLanguage = isTranslated
                    ? translationConfig?.sourceLanguage
                    : (try? await TranslationsService().detectPageLanguage(for: windowUUID))
                let filteredLanguages = languages.filter { $0 != pageLanguage && $0 != translatedLanguage }
                if isSingleLanguageFlow, let language = filteredLanguages.first, !isTranslated {
                    store.dispatch(TranslationLanguageSelectedAction(
                        windowUUID: windowUUID,
                        targetLanguage: language,
                        actionType: TranslationsActionType.didSelectTargetLanguage
                    ))
                } else {
                    store.dispatch(GeneralBrowserAction(
                        translationLanguages: filteredLanguages,
                        isPageTranslated: isTranslated,
                        translatedToLanguage: translatedLanguage,
                        windowUUID: windowUUID,
                        actionType: GeneralBrowserActionType.showTranslationLanguagePicker
                    ))
                }
            }
        }
    }

    // MARK: - Private helpers

    private func createMainMenuViewController() -> MainMenuViewController {
        let mainMenuViewController = MainMenuViewController(windowUUID: windowUUID, profile: profile)
        mainMenuViewController.coordinator = self
        return mainMenuViewController
    }
}
