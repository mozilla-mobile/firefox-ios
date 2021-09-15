/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import LocalAuthentication

class TipManager {
    
    @UserDefault(key: TipKey.releaseTip, defaultValue: true)
    static var releaseTip: Bool
    
    @UserDefault(key: TipKey.shortcutsTip, defaultValue: true)
    static var shortcutsTip: Bool
    
    @UserDefault(key: TipKey.sitesNotWorkingTip, defaultValue: true)
    static var sitesNotWorkingTip: Bool
    
    @UserDefault(key: TipKey.siriFavoriteTip, defaultValue: true)
    static var siriFavoriteTip: Bool
    
    @UserDefault(key: TipKey.biometricTip, defaultValue: true)
    static var biometricTip: Bool
    
    @UserDefault(key: TipKey.shareTrackersTip, defaultValue: true)
    static var shareTrackersTip: Bool
    
    @UserDefault(key: TipKey.siriEraseTip, defaultValue: true)
    static var siriEraseTip: Bool
    
    @UserDefault(key: TipKey.requestDesktopTip, defaultValue: true)
    static var requestDesktopTip: Bool
    

    struct Tip: Equatable {
        enum ScrollDestination {
            case siri
            case biometric
            case siriFavorite
        }
        
        enum Action {
            case visit(topic: SupportTopic)
            case showSettings(destination: ScrollDestination)
        }
        
        let title: String
        let description: String?
        let identifier: String
        let action: Action?
        let canShow: () -> Bool

        init(
            title: String,
            description: String? = nil,
            identifier: String,
            action: Action? = nil,
            canShow: @escaping () -> Bool
        ) {
            self.title = title
            self.identifier = identifier
            self.description = description
            self.action = action
            self.canShow = canShow
        }

        static func == (lhs: Tip, rhs: Tip) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }

    enum TipKey {
        static let releaseTip = "releaseTip"
        static let shortcutsTip = "shortcutsTip"
        static let sitesNotWorkingTip = "sitesNotWorkingTip"
        static let biometricTip = "biometricTip"
        static let siriFavoriteTip = "siriFavoriteTip"
        static let shareTrackersTip = "shareTrackersTip"
        static let requestDesktopTip = "requestDesktopTip"
        static let siriEraseTip = "siriEraseTip"
    }

    static let shared = TipManager()
    private var tips: [Tip] {
        var tips = [
            releaseTip,
            shortcutsTip,
            sitesNotWorkingTip,
            requestDesktopTip,
            siriFavoriteTip,
            siriEraseTip,
            shareTrackersTip
        ]
        if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            tips.append(biometricTip)
        }
        return tips
    }
    
    private var availableTips: [Tip] {
        guard canShowTips else { return [] }
        guard Settings.getToggle(.showHomeScreenTips) else { return [] }
        return tips.filter { $0.canShow() }
    }
    
    private let laContext = LAContext()

    private init() { }

    private lazy var releaseTip = Tip(
        title: String(format: UIConstants.strings.releaseTipTitle, AppInfo.config.productName),
        description: String(format: UIConstants.strings.releaseTipDescription, AppInfo.config.productName),
        identifier: TipKey.releaseTip,
        action: .visit(topic: .whatsNew),
        canShow: { TipManager.releaseTip }
    )
    
    private lazy var shortcutsTip = Tip(
        title: UIConstants.strings.shortcutsTipTitle,
        description: String(format: UIConstants.strings.shortcutsTipDescription, AppInfo.config.productName),
        identifier: TipKey.shortcutsTip,
        canShow: { TipManager.shortcutsTip }
    )

    private lazy var sitesNotWorkingTip = Tip(
        title: UIConstants.strings.sitesNotWorkingTipTitle,
        description: UIConstants.strings.sitesNotWorkingTipDescription,
        identifier: TipKey.sitesNotWorkingTip,
        canShow: { TipManager.sitesNotWorkingTip }
    )

    private lazy var biometricTip: Tip = {
        let description = laContext.biometryType == .faceID
            ? UIConstants.strings.biometricTipFaceIdDescription
            : UIConstants.strings.biometricTipTouchIdDescription
        
        return Tip(
            title: UIConstants.strings.biometricTipTitle,
            description: description,
            identifier: TipKey.biometricTip,
            action: .showSettings(destination: .biometric),
            canShow: { TipManager.biometricTip }
        )
    }()

    private lazy var requestDesktopTip = Tip(
        title: UIConstants.strings.requestDesktopTipTitle,
        description: UIConstants.strings.requestDesktopTipDescription,
        identifier: TipKey.requestDesktopTip,
        canShow: { TipManager.requestDesktopTip }
    )

    private lazy var siriFavoriteTip = Tip(
        title: UIConstants.strings.siriFavoriteTipTitle,
        description: UIConstants.strings.siriFavoriteTipDescription,
        identifier: TipKey.siriFavoriteTip,
        action: .showSettings(destination: .siri),
        canShow: { TipManager.siriFavoriteTip && self.isiOS12 }
    )

    private lazy var siriEraseTip = Tip(
        title: UIConstants.strings.siriEraseTipTitle,
        description: UIConstants.strings.siriEraseTipDescription,
        identifier: TipKey.siriEraseTip,
        action: .showSettings(destination: .siriFavorite),
        canShow: { TipManager.siriEraseTip && self.isiOS12 }
    )

    /// Return a string representing the trackers tip. It will include the current number of trackers blocked, formatted as a decimal.
    func shareTrackersDescription() -> String {
        let numberOfTrackersBlocked = NSNumber(integerLiteral: UserDefaults.standard.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return String(format: UIConstants.strings.shareTrackersTipDescription, formatter.string(from: numberOfTrackersBlocked) ?? "0")
    }
    
    private var shareTrackersTip: Tip {
        Tip(
            title: UIConstants.strings.shareTrackersTipTitle,
            description: shareTrackersDescription(),
            identifier: TipKey.shareTrackersTip,
            canShow: { UserDefaults.standard.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey) >= 10 }
        )
    }

    func fetchFirstTip() -> Tip? { availableTips.first }
    
    private var isiOS12: Bool {
        guard #available(iOS 12.0, *) else { return false }
        return true
    }

    var canShowTips: Bool { NSLocale.current.languageCode == "en" && !AppInfo.isKlar }
    
    func getTip(after: Tip) -> Tip? {
        if let index = availableTips.firstIndex(where: { $0.identifier == after.identifier }) {
                let after = index == availableTips.count - 1 ? availableTips[0] : availableTips[index + 1]
                return after
            }
        return nil
    }
    
    func getTip(before: Tip) -> Tip? {
        if let index = availableTips.firstIndex(where: { $0.identifier == before.identifier }) {
            let before = index == 0 ? availableTips.last : availableTips[index - 1]
            return before
        }
        return nil
    }
    
    var numberOfTips: Int { availableTips.count }
    
    func currentIndex(for tip: Tip) -> Int {
        if let index = availableTips.firstIndex(where: { $0.identifier == tip.identifier }) {
            return index
        }
        return 0
    }
}
