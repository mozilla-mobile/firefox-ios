// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import UIKit

/// Plays the sound and the haptic feedback marking the start and the end of a voice recording.
@MainActor
protocol RecordingFeedbackPlayer {
    /// Returns once the start sound and its haptic have been triggered.
    func playRecordingStart() async
    func playRecordingEnd()
}

@MainActor
final class DefaultRecordingFeedbackPlayer: RecordingFeedbackPlayer {
    private let soundPlayer = RecordingSoundPlayer()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        Task { [soundPlayer] in
            await soundPlayer.preload()
        }
    }

    func playRecordingStart() async {
        await play(.start)
    }

    func playRecordingEnd() {
        Task {
            await play(.end)
        }
    }

    private func play(_ sound: RecordingSound) async {
        hapticGenerator.prepare()
        await soundPlayer.play(sound)
        hapticGenerator.impactOccurred()
    }
}

private enum RecordingSound: String, CaseIterable {
    case start = "record_start"
    case end = "record_end"
}

/// Keeps the blocking audio work off the main thread. The audio session is owned by the recording `AudioManager`.
private actor RecordingSoundPlayer {
    private struct UX {
        static let volume: Float = 0.5
    }

    private var players: [RecordingSound: AVAudioPlayer] = [:]

    func preload() {
        RecordingSound.allCases.forEach { _ = player(for: $0) }
    }

    func play(_ sound: RecordingSound) {
        guard let player = player(for: sound) else { return }
        player.currentTime = 0
        player.play()
    }

    private func player(for sound: RecordingSound) -> AVAudioPlayer? {
        if let player = players[sound] { return player }
        guard let url = Bundle.module.url(forResource: sound.rawValue, withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.volume = UX.volume
        player.prepareToPlay()
        players[sound] = player
        return player
    }
}
