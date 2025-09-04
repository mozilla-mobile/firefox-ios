// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A configuration container for a summarizer.
public struct SummarizerConfig: Equatable, Sendable {
    public let instructions: String
    // FIXME: FXIOS-13417 We should strongly type options in the future so they can be any Sendable & Hashable
    /// NOTE: options is intentionally untyped to allow for flexibility in the configuration.
    /// There are two main reasons for this. 
    /// 1. The hosted model that is using an OpenAI-like API that has a lot of different parameters that can be tuned, 
    ///    and we want to allow for easy experimentation with these parameters.
    /// 2. The Apple foundation model is a new API that may introduce additional parameters or change existing ones.
    /// Options can include things like temperature, max tokens, and other model-specific settings.
    public nonisolated(unsafe) let options: [String: AnyHashable]
    public static let defaultConfig =
        SummarizerConfig(instructions: SummarizerModelInstructions.defaultInstructions, options: [:])

    public init(instructions: String, options: [String: AnyHashable]) {
        self.instructions = instructions
        self.options = options
    }

    /// Returns a new config by merging the current config with another config.
    /// The current config takes precedence over the other config.
    public func merging(with other: SummarizerConfig) -> SummarizerConfig {
        let mergedInstructions = self.instructions.isEmpty ? other.instructions : self.instructions
        let mergedOptions = self.options.merging(other.options) { current, _ in current }
        return SummarizerConfig(instructions: mergedInstructions, options: mergedOptions)
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
extension SummarizerConfig {
    func toGenerationOptions() -> GenerationOptions {
        return GenerationOptions(
            sampling: options["sampling"] as? GenerationOptions.SamplingMode,
            temperature: options["temperature"] as? Double,
            maximumResponseTokens: options["maximumResponseTokens"] as? Int
        )
    }
}
#endif
