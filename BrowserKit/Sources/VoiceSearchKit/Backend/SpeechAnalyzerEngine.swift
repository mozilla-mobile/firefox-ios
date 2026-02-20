// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// TODO: FXIOS-14934 - remove preconcurrency
@preconcurrency import AVFoundation
import Speech
import Common
import CoreMedia

/// A transcription engine built on iOS 26's `SpeechAnalyzer` + `SpeechTranscriber`.
///
/// Responsibilities:
/// - Request/check microphone + speech permissions
/// - Configure the audio session for recording
/// - Capture microphone audio via `AVAudioEngine` and feed it into `SpeechAnalyzer`
/// - Stream transcription results through an `AsyncThrowingStream` continuation
///
/// This type is an `@MainActor` class to keep audio/transcription state safe across concurrent calls.
@available(iOS 26.0, *)
@MainActor
final class SpeechAnalyzerEngine: TranscriptionEngine {
    // TODO: FXIOS-14882 - Refactor audio portion to be in its own manager
    private let audioEngine: AudioEngineProvider
    private let audioSession: AudioSessionProvider

    private let authorizer: AuthorizeProvider
    private let locale: Locale

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?

    private var resultsTask: Task<Void, Error>?

    init(
        locale: Locale = Locale.current,
        audioEngine: AudioEngineProvider = AVAudioEngine(),
        audioSession: AudioSessionProvider = AVAudioSession(),
        authorizer: AuthorizeProvider? = nil
    ) {
        self.audioEngine = audioEngine
        self.audioSession = audioSession
        self.authorizer = authorizer ?? AuthorizationHandler(audioSession: audioSession)
        self.locale = locale
    }

    func prepare() async throws {
        guard await isPermissionGranted() else {
            throw SpeechError.permissionDenied
        }
        try configureAudioSession()
    }

    // TODO: FXIOS-14878 - Refactor and extract similar audio code for both speech framework
    /// Starts transcription and streams results through `continuation`.
    ///
    /// This method:
    /// 1) resolves a supported locale
    /// 2) creates a transcriber + analyzer
    /// 3) ensures the speech model is installed (downloads if needed)
    /// 4) prepares the analyzer with a compatible audio format
    /// 5) starts analyzer + results tasks
    /// 6) starts microphone capture and feeds audio buffers into the analyzer input stream
    ///
    /// - Parameter continuation: Receives incremental and final `SpeechResult` values.
    func start(continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation) async throws {
        // TODO: Use LocaleProvider instead
        let resolvedLocale = try await resolveLocale(with: locale)

        let transcriber = SpeechTranscriber(
            locale: resolvedLocale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.transcriptionConfidence]
        )
        self.transcriber = transcriber

        try await ensureModelAvailable(transcriber: transcriber, locale: resolvedLocale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let targetFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        guard let targetFormat else {
            throw SpeechError.noAudioFormat
        }

        try await analyzer.prepareToAnalyze(in: targetFormat)

        // Build analyzer input stream; mic capture yields audio buffers into `inputContinuation`.
        let stream = AsyncStream<AnalyzerInput> { continuation in
            self.inputContinuation = continuation
        }

        try await analyzer.start(inputSequence: stream)

        resultsTask = Task { [weak self] in
            guard let self, let transcriber = self.transcriber else { return }
            do {
                for try await result in transcriber.results {
                    let chunk = String(result.text.characters)
                    let speechResult = SpeechResult(
                        text: chunk,
                        isFinal: result.isFinal
                    )
                    continuation.yield(speechResult)
                    if result.isFinal {
                        continuation.finish()
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }

        // Start microphone capture and feed `AnalyzerInput(buffer:)` into the stream.
        try startAudioCapture(with: targetFormat)
    }

    func stop() async throws {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        inputContinuation?.finish()
        inputContinuation = nil

        try await analyzer?.finalizeAndFinishThroughEndOfInput()

        resultsTask = nil

        transcriber = nil
        analyzer = nil
    }

    private func isPermissionGranted() async -> Bool {
        let isMicAuthorized = await authorizer.isMicrophonePermissionAuthorized()
        let isSpeechAuthorized = await authorizer.isSpeechPermissionAuthorized()
        return isMicAuthorized && isSpeechAuthorized
    }

    // MARK: - Audio Related
    // TODO: FXIOS-14882 - Refactor audio portion to be in its own manager
    private func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Starts microphone capture and yields buffers into the analyzer input stream.
    ///
    /// If the microphone format differs from the analyzer format, audio is converted before being sent.
    private func startAudioCapture(with targetFormat: AVAudioFormat) throws {
        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)

        guard let continuation = inputContinuation else {
            throw SpeechError.noInputContinuation
        }

        let converter: AVAudioConverter?
        if inputFormat != targetFormat {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        } else {
            converter = nil
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            guard let self else { return }
            do {
                let converted = try self.convertIfNeeded(buffer, to: targetFormat, with: converter)
                continuation.yield(AnalyzerInput(buffer: converted))
            } catch {
                // TODO: FXIOS-14931 Add logger
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    nonisolated private func convertIfNeeded(
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

    private func resolveLocale(with currentLocale: Locale) async throws -> Locale {
        if let supported = await SpeechTranscriber.supportedLocale(equivalentTo: currentLocale) {
            return supported
        } else {
            throw SpeechError.unableToSupportLocale
        }
    }

    /// Ensures a speech model is available for `locale`.
    ///
    /// If the locale is supported but not installed, this will download and install the model.
    private func ensureModelAvailable(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw SpeechError.unableToSupportLocale
        }

        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }

    private func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    private func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    private func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            try await downloader.downloadAndInstall()
        }
    }
}
