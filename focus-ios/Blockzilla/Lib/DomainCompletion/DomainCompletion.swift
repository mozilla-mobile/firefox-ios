/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AutocompleteTextField

typealias AutoCompleteSuggestions = [String]

protocol AutocompleteSource {
    var enabled: Bool { get }
    func getSuggestions() -> AutoCompleteSuggestions
}

enum CompletionSourceError {
    case invalidUrl
    case duplicateDomain
    case indexOutOfRange

    var message: String {
        guard case .invalidUrl = self else { return "" }

        return UIConstants.strings.autocompleteAddCustomUrlError
    }
}

typealias CustomCompletionResult = Result<Void, CompletionSourceError>

protocol CustomAutocompleteSource: AutocompleteSource {
    func add(suggestion: String) -> CustomCompletionResult
    func add(suggestion: String, atIndex: Int) -> CustomCompletionResult
    func remove(at index: Int) -> CustomCompletionResult
}

class CustomCompletionSource: CustomAutocompleteSource {
    private lazy var regex = try! NSRegularExpression(pattern: "^(\\s+)?(?:https?:\\/\\/)?(?:www\\.)?", options: [.caseInsensitive])
    var enabled: Bool { return Settings.getToggle(.enableCustomDomainAutocomplete) }

    func getSuggestions() -> AutoCompleteSuggestions {
        return Settings.getCustomDomainSetting()
    }

    func add(suggestion: String) -> CustomCompletionResult {
        let sanitizedSuggestion = regex.stringByReplacingMatches(in: suggestion, options: [], range: NSMakeRange(0, suggestion.count), withTemplate: "")

        guard !sanitizedSuggestion.isEmpty else { return .error(.invalidUrl) }
        
        guard sanitizedSuggestion.contains(".") else { return .error(.invalidUrl) }

        var domains = getSuggestions()
        guard !domains.contains(sanitizedSuggestion) else { return .error(.duplicateDomain) }

        domains.append(sanitizedSuggestion)
        Settings.setCustomDomainSetting(domains: domains)

        return .success(())
    }

    func add(suggestion: String, atIndex: Int) -> CustomCompletionResult {
        let sanitizedSuggestion = regex.stringByReplacingMatches(in: suggestion, options: [], range: NSMakeRange(0, suggestion.count), withTemplate: "")

        guard !sanitizedSuggestion.isEmpty else { return .error(.invalidUrl) }

        var domains = getSuggestions()
        guard !domains.contains(sanitizedSuggestion) else { return .error(.duplicateDomain) }

        domains.insert(sanitizedSuggestion, at: atIndex)
        Settings.setCustomDomainSetting(domains: domains)

        return .success(())
    }

    func remove(at index: Int) -> CustomCompletionResult {
        var domains = getSuggestions()

        guard domains.count > index else { return .error(.indexOutOfRange) }
        domains.remove(at: index)
        Settings.setCustomDomainSetting(domains: domains)

        return .success(())
    }
}

class TopDomainsCompletionSource: AutocompleteSource {
    var enabled: Bool { return Settings.getToggle(.enableDomainAutocomplete) }

    private lazy var topDomains: [String] = {
        let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt")
        return try! String(contentsOfFile: filePath!).components(separatedBy: "\n")
    }()

    func getSuggestions() -> AutoCompleteSuggestions {
        return topDomains
    }
}

class DomainCompletion: AutocompleteTextFieldCompletionSource {
    private var completionSources: [AutocompleteSource]

    init(completionSources: [AutocompleteSource]) {
        self.completionSources = completionSources
    }

    func autocompleteTextFieldCompletionSource(_ autocompleteTextField: AutocompleteTextField, forText text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let domains = completionSources.lazy
            .filter({ $0.enabled }) // Only include domain sources that are enabled in settings
            .flatMap({ $0.getSuggestions() }) // Flatten all sources into a [String]

        for domain in domains {
            if let completion = self.completion(forDomain: domain, withText: text) {
                return completion
            }
        }

        return nil
    }

    private func completion(forDomain domain: String, withText text: String) -> String? {
        let domainWithDotPrefix: String = ".www.\(domain)"
        if let range = domainWithDotPrefix.range(of: ".\(text)", options: .caseInsensitive, range: nil, locale: nil) {
            // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
            // so make sure the result includes at least one ".".
            let range = domainWithDotPrefix.index(range.lowerBound, offsetBy: 1)
            let matchedDomain = domainWithDotPrefix[range...]

            if matchedDomain.contains(".") {
                return matchedDomain + "/"
            }
        }

        return nil
    }
}
