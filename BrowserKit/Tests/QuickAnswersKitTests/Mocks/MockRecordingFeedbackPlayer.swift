// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

@MainActor
final class MockRecordingFeedbackPlayer: RecordingFeedbackPlayer {
    var playRecordingStartCalledCount = 0
    var playRecordingEndCalledCount = 0

    func playRecordingStart() async {
        playRecordingStartCalledCount += 1
    }

    func playRecordingEnd() {
        playRecordingEndCalledCount += 1
    }
}
