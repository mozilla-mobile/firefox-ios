
import Foundation
import Shared

public struct ClipboardBarToastUX {
    static let ToastDelay = 4.0
}

protocol ClipboardBarDisplayHandlerDelegate: class {
    func shouldDisplayClipboardBar(_ clipboardBar: ButtonToast)
}

class ClipboardBarDisplayHandler {
    weak var delegate: ClipboardBarDisplayHandlerDelegate?
    weak var settingsDelegate: SettingsDelegate?

    private var sessionStarted = true
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    var clipboardToast: ButtonToast?

    
    init(prefs: Prefs, settingsDelegate: SettingsDelegate) {
        self.prefs = prefs
        self.settingsDelegate = settingsDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }
    
    private func shouldDisplayBar() -> Bool {
        if !sessionStarted || UIPasteboard.general.copiedURL == nil || wasClipboardURLAlreadyDisplayed() {
            return false
        }
        sessionStarted = false
        lastDisplayedURL = UIPasteboard.general.copiedURL?.absoluteString
        return true
    }
    
    //If we already displayed this URL on the previous session
    //We shouldn't display it again
    private func wasClipboardURLAlreadyDisplayed() -> Bool {
        guard let clipboardURL = UIPasteboard.general.copiedURL?.absoluteString ,
            let savedURL = lastDisplayedURL else {
                return false
        }
        if clipboardURL == savedURL {
            return true
        }
        return false
    }
    
    func checkIfShouldDisplayBar() {
        if shouldDisplayBar() {
            if let absoluteString = UIPasteboard.general.copiedURL?.absoluteString {
                
                clipboardToast = ButtonToast(labelText: Strings.GoToCopiedLink, descriptionText: absoluteString,  buttonText: Strings.GoButtonTittle, completion: { (buttonPressed) in
                    if !buttonPressed {
                        return
                    }
                    
                    if let url = URL(string: absoluteString) {
                        self.settingsDelegate?.settingsOpenURLInNewTab(url)
                    }
                })
                
                if let toast = clipboardToast {
                    delegate?.shouldDisplayClipboardBar(toast)
                }
            }
        }
    }
}
