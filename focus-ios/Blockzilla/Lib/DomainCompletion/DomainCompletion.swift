/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias AutoCompleteSuggestions = [String]

public protocol AutocompleteSource {
    var enabled: Bool { get }
    func getSuggestions() -> AutoCompleteSuggestions
}

public enum CompletionSourceError: Error {
    case invalidUrl
    case duplicateDomain
    case indexOutOfRange
}

public typealias CustomCompletionResult = Result<Void, CompletionSourceError>

public protocol CustomAutocompleteSource: AutocompleteSource {
    func add(suggestion: String) -> CustomCompletionResult
    func add(suggestion: String, atIndex: Int) -> CustomCompletionResult
    func remove(at index: Int) -> CustomCompletionResult
}

public class CustomCompletionSource: CustomAutocompleteSource {
    private lazy var regex = try! NSRegularExpression(pattern: "^(\\s+)?(?:https?:\\/\\/)?(?:www\\.)?", options: [.caseInsensitive])
    var enableCustomDomainAutocomplete: () -> Bool
    var getCustomDomainSetting: () -> AutoCompleteSuggestions
    var setCustomDomainSetting: ([String]) -> Void

    public init(
        enableCustomDomainAutocomplete: @escaping () -> Bool,
        getCustomDomainSetting: @escaping () -> AutoCompleteSuggestions,
        setCustomDomainSetting: @escaping ([String]) -> Void
    ) {
        self.enableCustomDomainAutocomplete = enableCustomDomainAutocomplete
        self.getCustomDomainSetting = getCustomDomainSetting
        self.setCustomDomainSetting = setCustomDomainSetting
    }

    public var enabled: Bool { return enableCustomDomainAutocomplete() }

    public func getSuggestions() -> AutoCompleteSuggestions {
        return getCustomDomainSetting()
    }

    public func add(suggestion: String) -> CustomCompletionResult {
        var sanitizedSuggestion = regex.stringByReplacingMatches(in: suggestion, options: [], range: NSRange(location: 0, length: suggestion.count), withTemplate: "")

        guard !sanitizedSuggestion.isEmpty else { return .failure(.invalidUrl) }

        guard sanitizedSuggestion.contains(".") else { return .failure(.invalidUrl) }

        // Drop trailing slash, otherwise URLs will end with two when added from quick add URL menu action
        if sanitizedSuggestion.suffix(1) == "/" {
            sanitizedSuggestion = String(sanitizedSuggestion.dropLast())
        }

        var domains = getSuggestions()
        guard !domains.contains(where: { domain in
            domain.compare(sanitizedSuggestion, options: .caseInsensitive) == .orderedSame
        }) else { return .failure(.duplicateDomain) }

        domains.append(sanitizedSuggestion)
        setCustomDomainSetting(domains)

        return .success(())
    }

    public func add(suggestion: String, atIndex: Int) -> CustomCompletionResult {
        let sanitizedSuggestion = regex.stringByReplacingMatches(in: suggestion, options: [], range: NSRange(location: 0, length: suggestion.count), withTemplate: "")

        guard !sanitizedSuggestion.isEmpty else { return .failure(.invalidUrl) }

        var domains = getSuggestions()
        guard !domains.contains(sanitizedSuggestion) else { return .failure(.duplicateDomain) }

        domains.insert(sanitizedSuggestion, at: atIndex)
        setCustomDomainSetting(domains)

        return .success(())
    }

    public func remove(at index: Int) -> CustomCompletionResult {
        var domains = getSuggestions()

        guard domains.count > index else { return .failure(.indexOutOfRange) }
        domains.remove(at: index)
        setCustomDomainSetting(domains)

        return .success(())
    }
}

class TopDomainsCompletionSource: AutocompleteSource {
    var enableDomainAutocomplete: () -> Bool

    init(
        enableDomainAutocomplete: @escaping () -> Bool
    ) {
        self.enableDomainAutocomplete = enableDomainAutocomplete
    }
    var enabled: Bool { return  enableDomainAutocomplete() }

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
                if matchedDomain.contains("/") {
                    return String(matchedDomain)
                }
                return matchedDomain + "/"
            }
        }

        return nil
    }
}
