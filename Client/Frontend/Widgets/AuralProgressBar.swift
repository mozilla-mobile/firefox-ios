/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AVFoundation
import Shared
import XCGLogger

private let log = Logger.browserLogger

private struct AuralProgressBarUX {
    static let TickPeriod = 1.0
    static let TickDuration = 0.03
    // VoiceOver's second tone of "screen changed" sound is approx. 1107-8 kHz, so make it C#6 which is 1108.73
    static let VoiceOverScreenChangedSecondToneFrequency = 1108.73
    // VoiceOver "screen changed" sound is two tones, let's denote them g1 and c2 (that is dominant and tonic). Then make TickFrequency to be f1 to make it subdominant and create a cadence (but it is quite spoiled by the pitch-varying progress sounds...). f1 is 5th halftone in a scale c1-c2.
    static let TickFrequency = AuralProgressBarUX.VoiceOverScreenChangedSecondToneFrequency * exp2(-1 + 5.0/12.0)
    static let TickVolume = 0.2
    static let ProgressDuration = 0.02
    static let ProgressStartFrequency = AuralProgressBarUX.TickFrequency
    static let ProgressEndFrequency = AuralProgressBarUX.TickFrequency * 2
    static let ProgressVolume = 0.03
    static let TickProgressPanSpread = 0.25
}

class AuralProgressBar {
    private class UI {
        let engine: AVAudioEngine
        let progressPlayer: AVAudioPlayerNode
        let tickPlayer: AVAudioPlayerNode
        // lazy initialize tickBuffer because of memory consumption (~350 kB)
        var _tickBuffer: AVAudioPCMBuffer?
        var tickBuffer: AVAudioPCMBuffer {
            if _tickBuffer == nil {
                _tickBuffer = UI.tone(tickPlayer.outputFormatForBus(0), pitch: AuralProgressBarUX.TickFrequency, volume: AuralProgressBarUX.TickVolume, duration: AuralProgressBarUX.TickDuration, period: AuralProgressBarUX.TickPeriod)
            }
            return _tickBuffer!
        }

        init() {
            engine = AVAudioEngine()

            tickPlayer = AVAudioPlayerNode()
            tickPlayer.pan = -Float(AuralProgressBarUX.TickProgressPanSpread)
            engine.attachNode(tickPlayer)

            progressPlayer = AVAudioPlayerNode()
            progressPlayer.pan = +Float(AuralProgressBarUX.TickProgressPanSpread)
            engine.attachNode(progressPlayer)

            connectPlayerNodes()

            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleAudioEngineConfigurationDidChangeNotification:"), name: AVAudioEngineConfigurationChangeNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleAudioSessionInterruptionNotification:"), name: AVAudioSessionInterruptionNotification, object: nil)
        }

        deinit {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioEngineConfigurationChangeNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionInterruptionNotification, object: nil)
        }

        func connectPlayerNodes() {
            let mainMixer = engine.mainMixerNode
            engine.connect(tickPlayer, to: mainMixer, format: mainMixer.outputFormatForBus(0))
            engine.connect(progressPlayer, to: mainMixer, format: tickBuffer.format)
        }

        func disconnectPlayerNodes() {
            engine.disconnectNodeOutput(tickPlayer)
            engine.disconnectNodeOutput(progressPlayer)
        }

        func startEngine() {
            if !engine.running {
                do {
                    try engine.start()
                } catch {
                    log.error("Unable to start AVAudioEngine: \(error)")
                }
            }
        }

        @objc func handleAudioSessionInterruptionNotification(notification: NSNotification) {
            if let interruptionTypeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt {
                if let interruptionType = AVAudioSessionInterruptionType(rawValue: interruptionTypeValue) {
                    switch interruptionType {
                    case .Began:
                        tickPlayer.stop()
                        progressPlayer.stop()
                    case .Ended:
                        if let interruptionOptionValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                            let interruptionOption = AVAudioSessionInterruptionOptions(rawValue: interruptionOptionValue)
                            if interruptionOption == .ShouldResume {
                                startEngine()
                            }
                        }
                    }
                }
            }
        }

        @objc func handleAudioEngineConfigurationDidChangeNotification(notification: NSNotification) {
            disconnectPlayerNodes()
            connectPlayerNodes()
        }

        func start() {
            do {
                try engine.start()
                tickPlayer.play()
                progressPlayer.play()
                tickPlayer.scheduleBuffer(tickBuffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Loops) { }
            } catch {
                log.error("Unable to start AVAudioEngine. Tick & Progress player will not play : \(error)")
            }
        }

        func stop() {
            progressPlayer.stop()
            tickPlayer.stop()
            engine.stop()
        }

        func playProgress(progress: Double) {
            // using exp2 and log2 instead of exp and log as "log" clashes with XCGLogger.log
            let pitch = AuralProgressBarUX.ProgressStartFrequency * exp2(log2(AuralProgressBarUX.ProgressEndFrequency/AuralProgressBarUX.ProgressStartFrequency) * progress)
            let buffer = UI.tone(progressPlayer.outputFormatForBus(0), pitch: pitch, volume: AuralProgressBarUX.ProgressVolume, duration: AuralProgressBarUX.ProgressDuration)
            progressPlayer.scheduleBuffer(buffer, atTime: nil, options: .Interrupts) { }
        }

        class func tone(format: AVAudioFormat, pitch: Double, volume: Double, duration: Double, period: Double? = nil) -> AVAudioPCMBuffer {
            // adjust durations to the nearest lower multiple of one pitch frequency's semiperiod to have tones end gracefully with 0 value
            let duration = Double(Int(duration * 2*pitch)) / (2*pitch)
            let pitchFrames = Int(duration * format.sampleRate)
            let frames = Int((period ?? duration) * format.sampleRate)
            let buffer = AVAudioPCMBuffer(PCMFormat: format, frameCapacity: AVAudioFrameCount(frames))
            buffer.frameLength = buffer.frameCapacity
            for channel in 0..<Int(format.channelCount) {
                let channelData = buffer.floatChannelData[channel]
                var i = 0
                for frame in 0..<frames {
                    // TODO: consider some attack-sustain-release to make the tones sound little less "sharp" and robotic
                    var val = 0.0
                    if frame < pitchFrames {
                        val = volume * sin(pitch*Double(frame)*2*M_PI/format.sampleRate)
                    }
                    channelData[i] = Float(val)
                    i += buffer.stride
                }
            }
            return buffer
        }
    }

    private let ui = UI()

    var progress: Double? {
        didSet {
            if !hidden {
                if oldValue == nil && progress != nil {
                    ui.start()
                } else if oldValue != nil && progress == nil {
                    ui.stop()
                }

                if let progress = progress {
                    ui.playProgress(progress)
                }
            }
        }
    }

    var hidden: Bool = true {
        didSet {
            if hidden != oldValue {
                if hidden {
                    ui.stop()
                    ui._tickBuffer = nil
                } else {
                    if let progress = progress {
                        ui.start()
                        ui.playProgress(progress)
                    }
                }
            }
        }
    }
}