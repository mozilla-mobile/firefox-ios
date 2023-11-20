// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

final class FakespotUtilsTests: XCTestCase {
    func testIsPadInMultitasking_withIphone() {
        let device = UIUserInterfaceIdiom.phone
        let keyWindow = UIWindow.attachedKeyWindow!
        let subject = FakespotUtils()
        XCTAssertFalse(subject.isPadInMultitasking(device: device, window: keyWindow, viewSize: keyWindow.frame.size),
                       "Should return false for an iPhone")
    }

    func testIsPadInMultitasking_withIpad_fullScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let subject = FakespotUtils()
        XCTAssertFalse(subject.isPadInMultitasking(device: device, window: keyWindow, viewSize: keyWindow.frame.size),
                       "Should return false on iPad in full screen")
    }

    func testIsPadInMultitasking_withIpad_splitScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let subject = FakespotUtils()
        XCTAssertTrue(subject.isPadInMultitasking(device: device, window: keyWindow, viewSize: CGSize.zero),
                      "Should return true on iPad in split screen")
    }

    func testShouldDisplayInSidebar_withIphone() {
        let device = UIUserInterfaceIdiom.phone
        let keyWindow = UIWindow.attachedKeyWindow!
        let orientation = UIDeviceOrientation.portrait
        let subject = FakespotUtils()
        XCTAssertFalse(subject.shouldDisplayInSidebar(device: device,
                                                      window: keyWindow,
                                                      viewSize: keyWindow.frame.size,
                                                      orientation: orientation),
                       "Should return false for an iPhone")
    }

    func testShouldDisplayInSidebar_withIpad_landscape_fullScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let orientation = UIDeviceOrientation.landscapeLeft
        let subject = FakespotUtils()
        XCTAssertTrue(subject.shouldDisplayInSidebar(device: device,
                                                     window: keyWindow,
                                                     viewSize: keyWindow.frame.size,
                                                     orientation: orientation),
                      "Should return true on iPad in landscape in full screen")
    }

    func testShouldDisplayInSidebar_withIpad_landscape_splitScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let orientation = UIDeviceOrientation.landscapeRight
        let subject = FakespotUtils()
        XCTAssertFalse(subject.shouldDisplayInSidebar(device: device,
                                                      window: keyWindow,
                                                      viewSize: CGSize.zero,
                                                      orientation: orientation),
                       "Should return false on iPad in landscape in split screen")
    }

    func testShouldDisplayInSidebar_withIpad_portrait_fullScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let orientation = UIDeviceOrientation.portrait
        let subject = FakespotUtils()
        XCTAssertFalse(subject.shouldDisplayInSidebar(device: device,
                                                      window: keyWindow,
                                                      viewSize: keyWindow.frame.size,
                                                      orientation: orientation),
                       "Should return false on iPad in portrait in full screen")
    }

    func testShouldDisplayInSidebar_withIpad_portrait_splitScreen() {
        let device = UIUserInterfaceIdiom.pad
        let keyWindow = UIWindow.attachedKeyWindow!
        let orientation = UIDeviceOrientation.portrait
        let subject = FakespotUtils()
        XCTAssertFalse(subject.shouldDisplayInSidebar(device: device,
                                                      window: keyWindow,
                                                      viewSize: CGSize.zero,
                                                      orientation: orientation),
                       "Should return false on iPad in portrait in split screen")
    }
}
