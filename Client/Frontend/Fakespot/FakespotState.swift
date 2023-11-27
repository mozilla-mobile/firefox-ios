// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpen: Bool
    var sidebarOpenForiPadLandscape: Bool

    init(_ appState: AppState) {
        guard let fakespotState = store.state.screenState(FakespotState.self, for: .fakespot) else {
            self.init()
            return
        }

        self.init(isOpen: fakespotState.isOpen,
                  sidebarOpenForiPadLandscape: fakespotState.sidebarOpenForiPadLandscape)
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
        case FakespotAction.toggleAppearance:
            return FakespotState(isOpen: !state.isOpen,
                                 sidebarOpenForiPadLandscape: state.sidebarOpenForiPadLandscape)
        case FakespotAction.setAppearanceTo(let isEnabled):
            return FakespotState(isOpen: isEnabled,
                                 sidebarOpenForiPadLandscape: state.sidebarOpenForiPadLandscape)
        case FakespotAction.setSidebarOpenForiPadLandscapeTo(let isEnabled):
            return FakespotState(isOpen: state.isOpen, sidebarOpenForiPadLandscape: isEnabled)
        case FakespotAction.toggleSidebarOpenForiPadLandscape:
            return FakespotState(isOpen: state.isOpen,
                                 sidebarOpenForiPadLandscape: !state.sidebarOpenForiPadLandscape)
        default:
            return state
        }
    }
}
