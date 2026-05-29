// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Which card the swipe view should land on the first time the section is
/// rendered. Computed by `WorldCupSectionState.defaultCard` from the
/// tournament phase, selected team, and the feed's best-match index.
enum WorldCupDefaultCard: Equatable, Hashable {
    /// The countdown / "follow your team" promo card. Only ever the default
    /// before the World Cup starts and only when no team is selected.
    case timer
    /// Index into `WorldCupSectionState.matches` of the card to land on.
    case match(Int)
}
