// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UnifiedSearchKit

extension SearchEngineElement {
    init(fromSearchEngine searchEngine: OpenSearchEngine, withAction action: @escaping () -> Void) {
        self.init(
            title: searchEngine.shortName,
            image: searchEngine.image,
            a11yLabel: searchEngine.shortName,
            a11yHint: nil,
            a11yId: AccessibilityIdentifiers.UnifiedSearch.BottomSheetRow.engine,
            action: action
        )
    }
}
