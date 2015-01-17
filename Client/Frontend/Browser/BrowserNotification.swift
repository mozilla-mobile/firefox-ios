/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class BrowserNotification: UIView {

    private var errorLabel:UILabel!
    
    override init() {
        super.init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewDidInit()
    }

    private func viewDidInit() {
        self.backgroundColor = UIColor.whiteColor()
        self.alpha = 0.0

        errorLabel = UILabel()
        errorLabel.backgroundColor = UIColor.clearColor()
        errorLabel.textColor = UIColor.lightGrayColor()
        errorLabel.textAlignment = NSTextAlignment.Center
        errorLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        errorLabel.numberOfLines = 0
        self.addSubview(errorLabel)

        self.errorLabel.snp_remakeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(self).offset(-100)
        }
    }

    func showNotification(error: NSError?) {
        errorLabel.text = error?.localizedDescription
        errorLabel.text = self.fullDescriptionOf(error);
        showError()
    }
    
    func fullDescriptionOf(error: NSError?) -> String {
        var resultString = ""
        let errorNew = error!
        
        resultString += "code: \(errorNew.code)\n"
        resultString += "domain: \(errorNew.domain)\n"
        resultString += "userInfo: \(errorNew.userInfo)\n"
        resultString += "localizedDescription: \(errorNew.localizedDescription)\n"
        resultString += "localizedRecoveryOptions: \(errorNew.localizedRecoveryOptions)\n"
        resultString += "localizedRecoverySuggestion: \(errorNew.localizedRecoverySuggestion)\n"
        resultString += "localizedFailureReason: \(errorNew.localizedFailureReason)\n"
        resultString += "recoveryAttempter: \(errorNew.recoveryAttempter)\n"
        resultString += "helpAnchor: \(errorNew.helpAnchor)\n"
        
        return resultString
    }
    
    func hideNotification() {
        hideError()
    }
    
    private func showError() {
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 1.0
            }, completion: { (finished) -> Void in
                if (finished) {
                }
        })
    }
    
    private func hideError() {
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 0.0
            }, completion: { (finished) -> Void in
                if (finished) {
                }
        })
    }
    
    func SELdidClickSlideOut() {
        hideError()
    }
}
