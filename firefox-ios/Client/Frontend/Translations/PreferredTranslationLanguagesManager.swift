// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Manages the persisted ordered list of preferred translation language codes.
/// Shared data layer between the translation action sheet and future settings screen.
///
/// - Device language is always the first entry and cannot be removed.
/// - On first access, auto-populates from `Locale.preferredLanguages` intersected with `supportedTargetLanguages`.
@MainActor
final class PreferredTranslationLanguagesManager {
    private let prefs: Prefs
    private let logger: Logger

    init(prefs: Prefs, logger: Logger = DefaultLogger.shared) {
        self.prefs = prefs
        self.logger = logger
    }

    /// Returns the stored preferred language list, populating it on the first call if needed.
    /// `supportedTargetLanguages` is the authoritative list of languages we can translate TO.
    func preferredLanguages(supportedTargetLanguages: [String]) -> [String] {
        if let stored = loadStoredLanguages(), !stored.isEmpty {
            return stored
        }

        // First use: derive the list from iOS preferred languages.
        let initial = buildInitialLanguages(supportedTargetLanguages: supportedTargetLanguages)
        save(languages: initial)
        return initial
    }

    /// Appends a language code to the stored list and persists it.
    /// Returns the updated list.
    @discardableResult
    func addLanguage(_ code: String) -> [String] {
        var current = loadStoredLanguages() ?? []
        guard !current.contains(code) else { return current }
        current.append(code)
        save(languages: current)
        return current
    }

    /// Persists a new ordered language list.
    func save(languages: [String]) {
        prefs.setString(languages.joined(separator: ","), forKey: PrefsKeys.Settings.translationPreferredLanguages)
    }

    // MARK: - Language Matching

    /// Returns the most specific code in `supported` that matches a BCP-47 tag.
    /// Tries the full tag, then language + script subtag, then language alone.
    /// Required for languages where the script is meaningful (e.g. `zh-Hans` vs `zh`):
    /// Remote Settings stores `zh-Hans`, but `Locale(identifier:).languageCode` drops the script.
    nonisolated static func matchingSupportedCode(
        for bcp47Tag: String,
        in supported: Set<String>
    ) -> String? {
        if supported.contains(bcp47Tag) { return bcp47Tag }
        let parts = bcp47Tag.split(separator: "-")
        // BCP-47 script subtags are exactly 4 characters (e.g. "Hans", "Latn").
        if parts.count >= 2, parts[1].count == 4 {
            let languageScript = "\(parts[0])-\(parts[1])"
            if supported.contains(languageScript) { return languageScript }
        }
        if let language = parts.first, supported.contains(String(language)) {
            return String(language)
        }
        return nil
    }

    // MARK: - Private

    private func loadStoredLanguages() -> [String]? {
        guard let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages),
              !stored.isEmpty else { return nil }
        return stored.components(separatedBy: ",")
    }

    /// Builds the initial language list by intersecting `Locale.preferredLanguages` with
    /// `supportedTargetLanguages`. Device language is always first.
    private func buildInitialLanguages(supportedTargetLanguages: [String]) -> [String] {
        let supportedSet = Set(supportedTargetLanguages)

        let preferred = Locale.preferredLanguages
            .compactMap { tag in
                PreferredTranslationLanguagesManager.matchingSupportedCode(for: tag, in: supportedSet)
            }

        // Deduplicate while preserving order.
        var seen = Set<String>()
        return preferred.filter { seen.insert($0).inserted }
    }
}
