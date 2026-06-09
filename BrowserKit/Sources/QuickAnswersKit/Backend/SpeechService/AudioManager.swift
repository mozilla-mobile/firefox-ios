// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import AVFoundation
import Common
import Speech

/// This manager centralizes common audio operations used by different speech transcription engines.
/// Manages audio session configuration, audio engine lifecycle, and microphone capture.
final class AudioManager: AudioManagerProtocol {
    private let audioEngine: AudioEngineProvider
    private let audioSession: AudioSessionProvider
    private let logger: Logger

    init(
        audioEngine: AudioEngineProvider = AVAudioEngine(),
        audioSession: AudioSessionProvider = AVAudioSession(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.audioEngine = audioEngine
        self.audioSession = audioSession
        self.logger = logger
    }

    func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func prepareAndStartEngine() throws {
        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopEngine() {
        audioEngine.stop()
        audioEngine.audioInputNode.removeTap(onBus: 0)
    }

    /// Starts capturing microphone audio without format conversion.
    func startCapture(
        bufferSize: AVAudioFrameCount = 4096,
        handler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) {
        let inputNode = audioEngine.audioInputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format, block: handler)
    }

    /// Starts capturing microphone audio with optional format conversion.
    /// If the microphone's native format differs from the target format, audio buffers
    /// are automatically converted before being passed to the handler.
    func startCapture(
        targetFormat: AVAudioFormat,
        bufferSize: AVAudioFrameCount = 4096,
        handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) {
        let inputNode = audioEngine.audioInputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let converter: AVAudioConverter?
        if inputFormat != targetFormat {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        } else {
            converter = nil
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                let convertedBuffer = try self.convertIfNeeded(buffer, to: targetFormat, with: converter)
                handler(convertedBuffer)
            } catch {
                logger.log(
                    "Error thrown trying to convert buffer via AudioManager.",
                    level: .warning,
                    category: .speech
                )
            }
        }
    }

    // MARK: - Private Helpers
    /// Converts an audio buffer to a target format if a converter is provided.
    /// If no converter is provided, returns the original buffer unchanged.
    private func convertIfNeeded(
        _ buffer: AVAudioPCMBuffer,
        to targetFormat: AVAudioFormat,
        with converter: AVAudioConverter?
    ) throws -> AVAudioPCMBuffer {
        guard let converter else { return buffer }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outFrameCapacity) else {
            throw SpeechError.failedToAllocateBuffer
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)
        if let error { throw error }

        return outBuffer
    }
}
