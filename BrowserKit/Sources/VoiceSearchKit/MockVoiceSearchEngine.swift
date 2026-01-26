// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol VoiceSearchDelegate {
    
}

/// Mock implementation of VoiceSearchManager for testing and UI preview
@MainActor
final class MockVoiceSearchEngine {
    var delegate: VoiceSearchDelegate?

    private(set) var isRecording = false
    private var currentMockIndex = 0

    /// Mock phrases that will be "recognized" in sequence
    public var mockPhrases: [String] = [
        "What is the weather today",
        "How to make pizza",
        "Best restaurants near me",
        "JavaScript tutorials",
        "Swift programming guide"
    ]

    /// Delay between starting recording and returning the first result (in seconds)
    public var mockDelay: TimeInterval = 1.5

    /// Whether to automatically stop after returning a result
    public var autoStopAfterResult: Bool = true

    public init() {}

    // MARK: - VoiceSearchManager

    public func requestAuthorization() async -> Bool {
        // Simulate a small delay for permission request
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return true
    }

    public func startRecording() async throws {
        guard !isRecording else { return }

        isRecording = true
//        delegate?.voiceSearchDidStartRecording()

        // Simulate speech recognition after a delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

            guard isRecording else { return }

            // Get next mock phrase
            let phrase = mockPhrases[currentMockIndex % mockPhrases.count]
            currentMockIndex += 1

            // Send partial results first (simulate real-time recognition)
            let words = phrase.split(separator: " ")
            var partialText = ""

            for (index, word) in words.enumerated() {
                guard isRecording else { break }

                partialText += (partialText.isEmpty ? "" : " ") + String(word)

//                let result = VoiceSearchResult(
//                    text: partialText,
//                    isFinal: false,
//                    confidence: 0.8
//                )
//
//                delegate?.voiceSearchDidReceiveResult(result)

                // Small delay between words
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }

            // Send final result
            if isRecording {
//                let finalResult = VoiceSearchResult(
//                    text: phrase,
//                    isFinal: true,
//                    confidence: 0.95
//                )
//
//                delegate?.voiceSearchDidReceiveResult(finalResult)

                if autoStopAfterResult {
                    stopRecording()
                }
            }
        }
    }

    public func stopRecording() {
        guard isRecording else { return }

        isRecording = false
//        delegate?.voiceSearchDidStopRecording()
    }
}
