/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

private struct PasscodeUX {
    static let TitleVerticalSpacing: CGFloat = 32
    static let DigitSize: CGFloat = 30
    static let TopMargin: CGFloat = 80
    static let PasscodeFieldSize: CGSize = CGSize(width: 160, height: 32)
}

@objc protocol PasscodeInputViewDelegate: class {
    func passcodeInputView(inputView: PasscodeInputView, didFinishEnteringCode code: String)
}

/// A custom, keyboard-able view that displays the blank/filled digits when entrering a passcode.
class PasscodeInputView: UIView, UIKeyInput {
    weak var delegate: PasscodeInputViewDelegate?

    var digitFont: UIFont = UIConstants.PasscodeEntryFont

    let blankCharacter: Character = "-"

    let filledCharacter: Character = "•"

    private let passcodeSize: Int

    private var inputtedCode: String = ""

    private var blankDigitString: NSAttributedString {
        return NSAttributedString(string: "\(blankCharacter)", attributes: [NSFontAttributeName: digitFont])
    }

    private var filledDigitString: NSAttributedString {
        return NSAttributedString(string: "\(filledCharacter)", attributes: [NSFontAttributeName: digitFont])
    }

    @objc var keyboardType: UIKeyboardType = .NumberPad

    init(frame: CGRect, passcodeSize: Int) {
        self.passcodeSize = passcodeSize
        super.init(frame: frame)
        opaque = false
    }

    convenience init(passcodeSize: Int) {
        self.init(frame: CGRectZero, passcodeSize: passcodeSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    func resetCode() {
        inputtedCode = ""
        setNeedsDisplay()
    }

    @objc func hasText() -> Bool {
        return inputtedCode.characters.count > 0
    }

    @objc func insertText(text: String) {
        guard inputtedCode.characters.count < passcodeSize else {
            return
        }

        inputtedCode += text
        setNeedsDisplay()
        if inputtedCode.characters.count == passcodeSize {
            delegate?.passcodeInputView(self, didFinishEnteringCode: inputtedCode)
        }
    }

    // Required for implementing UIKeyInput
    @objc func deleteBackward() {
        guard inputtedCode.characters.count > 0 else {
            return
        }

        inputtedCode.removeAtIndex(inputtedCode.endIndex.predecessor())
        setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        let circleSize = CGSize(width: 14, height: 14)

        (0..<passcodeSize).forEach { index in
            let context = UIGraphicsGetCurrentContext()
            CGContextSetLineWidth(context, 1)
            CGContextSetStrokeColorWithColor(context, UIConstants.PasscodeDotColor.CGColor)
            CGContextSetFillColorWithColor(context, UIConstants.PasscodeDotColor.CGColor)

            let offset = floor(rect.width / CGFloat(passcodeSize))
            var circleRect = CGRect(origin: CGPointZero, size: circleSize)
            circleRect.center = CGPoint(x: (offset * CGFloat(index + 1))  - offset / 2, y: rect.height / 2)

            if index < inputtedCode.characters.count {
                CGContextFillEllipseInRect(context, circleRect)
            } else {
                CGContextStrokeEllipseInRect(context, circleRect)
            }
        }
    }
}

/// A pane that gets displayed inside the PasscodeViewController that displays a title and a passcode input field.
class PasscodePane: UIView {
    let codeInputView = PasscodeInputView(passcodeSize: 4)

    var codeViewCenterConstraint: Constraint?
    var containerCenterConstraint: Constraint?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIConstants.DefaultChromeFont
        label.isAccessibilityElement = true
        return label
    }()

    private let centerContainer = UIView()

    override func accessibilityElementCount() -> Int {
        return 1
    }

    override func accessibilityElementAtIndex(index: Int) -> AnyObject? {
        switch index {
        case 0:     return titleLabel
        default:    return nil
        }
    }

    init(title: String? = nil) {
        super.init(frame: CGRectZero)
        backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        titleLabel.text = title
        centerContainer.addSubview(titleLabel)
        centerContainer.addSubview(codeInputView)
        addSubview(centerContainer)

        centerContainer.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            containerCenterConstraint = make.centerY.equalTo(self).constraint
        }

        titleLabel.snp_makeConstraints { make in
            make.centerX.equalTo(centerContainer)
            make.top.equalTo(centerContainer)
            make.bottom.equalTo(codeInputView.snp_top).offset(-PasscodeUX.TitleVerticalSpacing)
        }

        codeInputView.snp_makeConstraints { make in
            codeViewCenterConstraint = make.centerX.equalTo(centerContainer).constraint
            make.bottom.equalTo(centerContainer)
            make.size.equalTo(PasscodeUX.PasscodeFieldSize)
        }
        layoutIfNeeded()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PasscodePane.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PasscodePane.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }

    func shakePasscode() {
        UIView.animateWithDuration(0.1, animations: {
                self.codeViewCenterConstraint?.updateOffset(-10)
                self.layoutIfNeeded()
        }) { complete in
            UIView.animateWithDuration(0.1) {
                self.codeViewCenterConstraint?.updateOffset(0)
                self.layoutIfNeeded()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        guard let keyboardFrame = sender.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue else {
            return
        }
        
        UIView.animateWithDuration(0.1, animations: {
            self.containerCenterConstraint?.updateOffset(-keyboardFrame.height/2)
            self.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        UIView.animateWithDuration(0.1, animations: {
            self.containerCenterConstraint?.updateOffset(0)
            self.layoutIfNeeded()
        })
    }
}