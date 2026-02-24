// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct SummarizerLanguageExpansionConfiguration {
    let isFeatureEnabled: Bool
    /// Wether the summarizer supports summarizing with the web site language
    let isWebsiteDeviceLanguageSupported: Bool
    /// Whether the summarizer supports summarizing with the Device language
    let isDeviceLanguageSupported: Bool
    /// The supported Locales for the language expansion experiment
    let supportedLocales: [Locale]
}
