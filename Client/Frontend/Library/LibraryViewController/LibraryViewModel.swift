//
//  LibraryViewModel.swift
//  Client
//
//  Created by Roux Buciu on 2021-05-21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

class LibraryViewModel {

    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]

    fileprivate var panelState = LibraryPanelViewState()
    var currentPanelState: LibraryPanelMainState {
        get { return panelState.currentState }
        set { panelState.currentState = newValue }
    }

    init(withProfile profile: Profile) {
        self.profile = profile
        self.panelDescriptors = LibraryPanels(profile: profile).enabledPanels
    }
}
