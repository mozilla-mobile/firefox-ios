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
    var setCategoryCalls: [CategoryCallParams] = []
    var setActiveCalls: [(Bool, AVAudioSession.SetActiveOptions)] = []

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
        setActiveCalls.append((active, options))
    }
}

final class MockAudioEngine: AudioEngineProvider, @unchecked Sendable {
    // Use a real AVAudioEngine only to provide a valid inputNode
    private let engine = AVAudioEngine()

    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    var inputNode: AVAudioInputNode {
        engine.inputNode
    }

    func prepare() {
        prepareCallCount += 1
    }

    func start() throws {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}
