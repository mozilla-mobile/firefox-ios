// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum SearchSettingsModernAction: ModernAction {
    /// The Google Lens preference was toggled in Search Settings.
    case googleLensSettingDidChange

    /// The default search engine changed or the list of engines finished loading.
    case searchEngineDidChange
}
