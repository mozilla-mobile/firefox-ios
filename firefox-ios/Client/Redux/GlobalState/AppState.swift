// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct AppState: StateType, Sendable {
    let presentedComponents: PresentedComponentsState

    static let reducer: Reducer<Self> = { state, action in
        return AppState(
            presentedComponents: PresentedComponentsState.reducer(state.presentedComponents, action)
        )
    }

    func componentState<S: ScreenState>(_ s: S.Type,
                                        for component: AppComponent,
                                        window: WindowUUID?) -> S? {
        return presentedComponents.components
            .compactMap {
                switch ($0, component) {
                case (.browserViewController(let state), .browserViewController): return state as? S
                case (.homepage(let state), .homepage): return state as? S
                case (.mainMenu(let state), .mainMenu): return state as? S
                case (.microsurvey(let state), .microsurvey): return state as? S
                case (.remoteTabsPanel(let state), .remoteTabsPanel): return state as? S
                case (.tabsPanel(let state), .tabsPanel): return state as? S
                case (.tabPeek(let state), .tabPeek): return state as? S
                case (.tabsTray(let state), .tabsTray): return state as? S
                case (.termsOfUse(let state), .termsOfUse): return state as? S
                case (.themeSettings(let state), .themeSettings): return state as? S
                case (.toolbar(let state), .toolbar): return state as? S
                case (.searchEngineSelection(let state), .searchEngineSelection): return state as? S
                case (.trackingProtection(let state), .trackingProtection): return state as? S
                case (.passwordGenerator(let state), .passwordGenerator): return state as? S
                case (.nativeErrorPage(let state), .nativeErrorPage): return state as? S
                case (.shortcutsLibrary(let state), .shortcutsLibrary): return state as? S
                case (.translationSettings(let state), .translationSettings): return state as? S
                default: return nil
                }
            }.first(where: {
                // Most screens should be filtered based on the specific identifying UUID.
                // This is necessary to allow us to have more than 1 of the same type of
                // screen in Redux at the same time. If no UUID is provided we return `first`.
                guard let expectedUUID = window else { return true }
                // Generally this should be considered a code smell, attempting to select the
                // screen for an .unavailable window is nonsensical and may indicate a bug.
                guard expectedUUID != .unavailable else { return true }

                return $0.windowUUID == expectedUUID
            })
    }

    static func defaultState(from state: AppState) -> AppState {
        return AppState(presentedComponents: state.presentedComponents)
    }
}

extension AppState {
    init() {
        presentedComponents = PresentedComponentsState()
    }
}

@MainActor
let middlewares = [
    FeltPrivacyMiddleware().privacyManagerProvider,
    MainMenuMiddleware().mainMenuProvider,
    MessageCardMiddleware().messageCardProvider,
    MicrosurveyMiddleware().microsurveyProvider,
    MicrosurveyPromptMiddleware().microsurveyProvider,
    RemoteTabsPanelMiddleware().remoteTabsPanelProvider,
    TabManagerMiddleware().tabsPanelProvider,
    ThemeManagerMiddleware().themeManagerProvider,
    ToolbarMiddleware().toolbarProvider,
    SearchEngineSelectionMiddleware().searchEngineSelectionProvider,
    TopSitesMiddleware().topSitesProvider,
    TrackingProtectionMiddleware().trackingProtectionProvider,
    PasswordGeneratorMiddleware().passwordGeneratorProvider,
    MerinoMiddleware().pocketSectionProvider,
    NativeErrorPageMiddleware().nativeErrorPageProvider,
    WallpaperMiddleware().wallpaperProvider,
    BookmarksMiddleware().bookmarksProvider,
    HomepageMiddleware(notificationCenter: NotificationCenter.default).homepageProvider,
    StartAtHomeMiddleware().startAtHomeProvider,
    ShortcutsLibraryMiddleware().shortcutsLibraryProvider,
    SummarizerMiddleware().summarizerProvider,
    TermsOfUseMiddleware().termsOfUseProvider,
    TranslationsMiddleware().translationsProvider,
    PrivateLockMiddleware().lockProvider,
    TranslationSettingsMiddleware().translationSettingsProvider
]

// In order for us to mock and test the middlewares easier,
// we change the store to be instantiated as a variable.
// For non testing builds, we leave the store as a constant.
#if TESTING
@MainActor
var store: any DefaultDispatchStore<AppState> = Store(
    state: AppState(),
    reducer: AppState.reducer,
    middlewares: AppConstants.isRunningUnitTest ? [] : middlewares
)
#else
@MainActor
let store: any DefaultDispatchStore<AppState> = Store(state: AppState(),
                                                      reducer: AppState.reducer,
                                                      middlewares: middlewares)
#endif
