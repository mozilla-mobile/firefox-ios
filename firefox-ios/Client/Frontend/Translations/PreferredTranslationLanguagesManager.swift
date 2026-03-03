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

    /// Persists a new ordered language list.
    func save(languages: [String]) {
        guard let data = try? JSONEncoder().encode(languages),
              let json = String(data: data, encoding: .utf8) else {
            logger.log(
                "Failed to encode preferred translation languages.",
                level: .warning,
                category: .translations
            )
            return
        }
        prefs.setString(json, forKey: PrefsKeys.Settings.translationPreferredLanguages)
    }

    // MARK: - Private

    private func loadStoredLanguages() -> [String]? {
        guard let json = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages),
              let data = json.data(using: .utf8),
              let languages = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return languages
    }

    /// Builds the initial language list by intersecting `Locale.preferredLanguages` with
    /// `supportedTargetLanguages`. Device language is always first.
    private func buildInitialLanguages(supportedTargetLanguages: [String]) -> [String] {
        let supportedSet = Set(supportedTargetLanguages)

        // Extract base language codes (e.g. "en-US" → "en") and filter against supported list.
        let preferred = Locale.preferredLanguages
            .compactMap { tag -> String? in
                let base = Locale(identifier: tag).languageCode ?? tag
                return supportedSet.contains(base) ? base : nil
            }

        // Deduplicate while preserving order.
        var seen = Set<String>()
        return preferred.filter { seen.insert($0).inserted }
    }
}
