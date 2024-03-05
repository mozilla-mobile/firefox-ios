// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import UIKit

public enum URLViewAction {
    case contextMenuTap(anchor: UIButton)
    case backButtonTap
    case forwardButtonTap
    case stopButtonTap
    case reloadButtonTap
    case deleteButtonTap
    case shieldIconButtonTap
    case dragInteractionStarted
    case pasteAndGo
}

public enum ShieldIconStatus: Equatable {
    case on
    case off
    case connectionNotSecure
}

public class URLBarViewModel {
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var canDelete: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var connectionState: ShieldIconStatus = .on
    @Published public var loadingProgres: Double = 0

    internal var viewActionSubject = PassthroughSubject<URLViewAction, Never>()
    public var viewActionPublisher: AnyPublisher<URLViewAction, Never> { viewActionSubject.eraseToAnyPublisher() }

    lazy var domainCompletion = DomainCompletion(
        completionSources: [
            TopDomainsCompletionSource(enableDomainAutocomplete: enableDomainAutocomplete),
            CustomCompletionSource(
                enableCustomDomainAutocomplete: enableCustomDomainAutocomplete,
                getCustomDomainSetting: getCustomDomainSetting,
                setCustomDomainSetting: setCustomDomainSetting)
        ]
    )

    var enableCustomDomainAutocomplete: () -> Bool
    var getCustomDomainSetting: () -> AutoCompleteSuggestions
    var setCustomDomainSetting: ([String]) -> Void
    var enableDomainAutocomplete: () -> Bool

    public init(
        enableCustomDomainAutocomplete: @escaping () -> Bool,
        getCustomDomainSetting: @escaping () -> AutoCompleteSuggestions,
        setCustomDomainSetting: @escaping ([String]) -> Void,
        enableDomainAutocomplete: @escaping () -> Bool
    ) {
        self.enableCustomDomainAutocomplete = enableCustomDomainAutocomplete
        self.getCustomDomainSetting = getCustomDomainSetting
        self.setCustomDomainSetting = setCustomDomainSetting
        self.enableDomainAutocomplete = enableDomainAutocomplete
    }

    public func resetToDefaults() {
        canGoBack = false
        canGoForward = false
        canDelete = false
        isLoading = false
        loadingProgres = 0
    }
}
