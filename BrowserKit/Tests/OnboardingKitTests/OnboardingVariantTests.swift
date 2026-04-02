// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing
@testable import OnboardingKit

struct OnboardingVariantTests {
    @Test
    func test_shouldShowBrandRefreshUI() {
        #expect(!OnboardingVariant.legacy.shouldShowBrandRefreshUI)
        #expect(!OnboardingVariant.modern.shouldShowBrandRefreshUI)
        #expect(OnboardingVariant.japan.shouldShowBrandRefreshUI)
        #expect(OnboardingVariant.brandRefresh.shouldShowBrandRefreshUI)
    }
}
