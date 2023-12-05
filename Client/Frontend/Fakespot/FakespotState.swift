// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool

<<<<<<< HEAD
    init(_ appState: AppState) {
        guard let fakespotState = store.state.screenState(FakespotState.self, for: .fakespot) else {
            self.init()
            return
        }

        self.init(isOpenOnProductPage: fakespotState.isOpenOnProductPage)
=======
    init(_ appState: BrowserViewControllerState) {
        self.init(isOpen: appState.fakespotState.isOpen,
                  sidebarOpenForiPadLandscape: appState.fakespotState.sidebarOpenForiPadLandscape)
>>>>>>> f8565a9a1 (Refactor FXIOS-7812 [v121] Fakespot - iPad - sidebar open/close state resets itself when user changes from landscape to portrait mode (#17587))
    }

    init() {
        self.init(isOpen: false, sidebarOpenForiPadLandscape: false)
    }

    init(isOpen: Bool, sidebarOpenForiPadLandscape: Bool) {
        self.isOpen = isOpen
        self.sidebarOpenForiPadLandscape = sidebarOpenForiPadLandscape
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakespotAction.pressedShoppingButton:
            return FakespotState(isOpen: !state.isOpen,
                                 sidebarOpenForiPadLandscape: !state.isOpen)
        case FakespotAction.show:
            return FakespotState(isOpen: true,
                                 sidebarOpenForiPadLandscape: true)
        case FakespotAction.dismiss:
            return FakespotState(isOpen: false,
                                 sidebarOpenForiPadLandscape: false)
        case FakespotAction.setAppearanceTo(let isEnabled):
            return FakespotState(isOpen: isEnabled,
                                 sidebarOpenForiPadLandscape: state.sidebarOpenForiPadLandscape)
        default:
            return state
        }
    }
}
