// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation

@testable import VoiceSearchKit

final class MockAudioSession: AudioSessionProvider, @unchecked Sendable {
    let micPermission = true
    struct CategoryCallParams {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    struct ActiveCallParams {
        let active: Bool
        let options: AVAudioSession.SetActiveOptions
    }

    var setCategoryCalls: [CategoryCallParams] = []
    var setActiveCalls: [ActiveCallParams] = []

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        response(micPermission)
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        setCategoryCalls.append(
            CategoryCallParams(
                category: category,
                mode: mode,
                options: options
            )
        )
    }

    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws {
        setActiveCalls.append(ActiveCallParams(active: active, options: options))
    }
}
