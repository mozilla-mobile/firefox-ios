// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

//extension FxNimbus: FxNimbusProtocol {}
//
//protocol FxNimbusProtocol {
//    static var shared: FxNimbus { get }
//    var features: Features { get }
//}
//
//class MockFxNimbus: FxNimbusProtocol {
//    let features = Features()
//
//    static let shared = FxNimbus()
//}
//
//class MockNimbusFeatures: Features {
////    public lazy var tabTrayFeature = MockTabTrayFeature()
////    public lazy var homescreen = MockHomescreenFeature()
//}
//
//class MockHomescreenFeature {
//    var sectionsEnabled = [HomeScreenSection: Bool]()
//}
//
//class MockTabTrayFeature {
//    var sectionsEnabled = [TabTraySection: Bool]()
//}
//

// MARK: Test code only
//class MockNimbusFeatures: NimbusFeatures {
//    lazy var tabTrayFeature: String = {
//        "I am a potato"
//    }()
//
//    lazy var homeScreen: String = {
//        "I am a turnip"
//    }()
//}
//
//class FxNimbusMock: FxNimbusProtocol {
//    static var nimbusShared: FxNimbusProtocol = FxNimbusMock()
//    var nimbusFeatures: NimbusFeatures = MockNimbusFeatures()
//}
//
//
//// How to use. Yes it sucks
//let nimbusFeatures1 = FxNimbusMock.nimbusShared.nimbusFeatures.tabTrayFeature
//let nimbusFeatures2 = FxNimbusMock.nimbusShared.nimbusFeatures.homeScreen


