/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import LocalAuthentication

class TipManager {
    
    struct Tip: Equatable {
        var title: String
        var description: String?
        var identifier: String
        var showVc: Bool
        
        init(title: String, description: String? = nil, identifier: String, showVc: Bool = false) {
            self.title = title
            self.identifier = identifier
            self.description = description
            self.showVc = showVc
        }
        
        static func == (lhs: Tip, rhs: Tip) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    class TipKey {
        static let autocompleteTip = "autocompleteTip"
        static let sitesNotWorkingTip = "sitesNotWorkingTip"
        static let biometricTip = "biometricTip"
        static let siriFavoriteTip = "siriFavoriteTip"
        static let shareTrackersTip = "shareTrackersTip"
        static let requestDesktopTip = "requestDesktopTip"
        static let siriEraseTip = "siriEraseTip"
    }
    
    static let shared = TipManager()
    private var possibleTips: [Tip]
    private let laContext = LAContext()
    var currentTip: Tip?
    
    init() {
        possibleTips = [Tip]()
        addAllTips()
    }
    
    private func addAllTips() {
        possibleTips.append(autocompleteTip)
        possibleTips.append(sitesNotWorkingTip)
        possibleTips.append(requestDesktopTip)
        possibleTips.append(siriFavoriteTip)
        possibleTips.append(siriEraseTip)
        possibleTips.append(shareTrackersTip)
        if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            possibleTips.append(biometricTip)
        }
    }
    
    lazy var autocompleteTip = Tip(title: UIConstants.strings.autocompleteTipTitle, description: UIConstants.strings.autocompleteTipDescription, identifier: TipKey.autocompleteTip)
    
    lazy var sitesNotWorkingTip = Tip(title: UIConstants.strings.sitesNotWorkingTipTitle, description: UIConstants.strings.sitesNotWorkingTipDescription, identifier: TipKey.sitesNotWorkingTip)
    
    lazy var biometricTip: Tip = {
        if laContext.biometryType == .faceID {
            return Tip(title: UIConstants.strings.biometricTipTitle, description: UIConstants.strings.biometricTipFaceIdDescription, identifier: TipKey.biometricTip, showVc: true)
        } else {
            return Tip(title: UIConstants.strings.biometricTipTitle, description: UIConstants.strings.biometricTipTouchIdDescription, identifier: TipKey.biometricTip, showVc: true)
        }
    }()
    
    lazy var requestDesktopTip = Tip(title: UIConstants.strings.requestDesktopTipTitle, description: UIConstants.strings.requestDesktopTipDescription, identifier: TipKey.requestDesktopTip)
    
    lazy var siriFavoriteTip = Tip(title: UIConstants.strings.siriFavoriteTipTitle, description: UIConstants.strings.siriFavoriteTipDescription, identifier: TipKey.siriFavoriteTip, showVc: true)
    
    lazy var siriEraseTip = Tip(title: UIConstants.strings.siriEraseTipTitle, description: UIConstants.strings.siriEraseTipDescription, identifier: TipKey.siriEraseTip, showVc: true)
    
    lazy var shareTrackersTip = Tip(title: UIConstants.strings.shareTrackersTipTitle, identifier: TipKey.shareTrackersTip)
    
    func fetchTip() -> Tip? {
        guard let tip = possibleTips.randomElement(), let indexToRemove = possibleTips.index(of: tip) else { return nil }
        if tip.identifier != TipKey.shareTrackersTip {
            possibleTips.remove(at: indexToRemove)
        }
        if canShowTip(with: tip.identifier) {
            return tip
        } else {
            return fetchTip()
        }
    }
    
    private func canShowTip(with id: String) -> Bool {
        let defaults = UserDefaults.standard
        switch id {
        case TipKey.siriFavoriteTip, TipKey.siriEraseTip:
            guard #available(iOS 12.0, *) else { return false }
        case TipKey.shareTrackersTip:
            guard UserDefaults.standard.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey) >= 10 else { return false }
        default:
            break
        }
        return defaults.bool(forKey: id)
    }
}
