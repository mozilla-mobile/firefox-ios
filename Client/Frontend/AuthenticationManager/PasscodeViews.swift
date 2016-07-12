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
    func passcodeInputView(_ inputView: PasscodeInputView, didFinishEnteringCode code: String)
}

/// A custom, keyboard-able view that displays the blank/filled digits when entrering a passcode.
class PasscodeInputView: UIView, UIKeyInput {
    weak var delegate: PasscodeInputViewDelegate?

    var digitFont: UIFont = UIConstants.PasscodeEntryFont

    let blankCharacter: Character = "-"

    let filledCharacter: Character = "•"

    private let passcodeSize: Int

    private var inputtedCode: String = ""

    private var blankDigitString: AttributedString {
        return AttributedString(string: "\(blankCharacter)", attributes: [NSFontAttributeName: digitFont])
    }

    private var filledDigitString: AttributedString {
        return AttributedString(string: "\(filledCharacter)", attributes: [NSFontAttributeName: digitFont])
    }

    @objc var keyboardType: UIKeyboardType = .numberPad

    init(frame: CGRect, passcodeSize: Int) {
        self.passcodeSize = passcodeSize
        super.init(frame: frame)
        isOpaque = false
    }

    convenience init(passcodeSize: Int) {
        self.init(frame: CGRect.zero, passcodeSize: passcodeSize)
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

    @objc func insertText(_ text: String) {
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

        inputtedCode.remove(at: inputtedCode.index(before: inputtedCode.endIndex))
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let circleSize = CGSize(width: 14, height: 14)

        (0..<passcodeSize).forEach { index in
            let context = UIGraphicsGetCurrentContext()
            context?.setLineWidth(1)
            context.setStrokeColor(UIConstants.PasscodeDotColor.CGColor)
            context.setFillColor(UIConstants.PasscodeDotColor.CGColor)

            let offset = floor(rect.width / CGFloat(passcodeSize))
            var circleRect = CGRect(origin: CGPoint.zero, size: circleSize)
            circleRect.center = CGPoint(x: (offset * CGFloat(index + 1))  - offset / 2, y: rect.height / 2)

            if index < inputtedCode.characters.count {
                context?.fillEllipse(in: circleRect)
            } else {
                context?.strokeEllipse(in: circleRect)
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

    override func accessibilityElement(at index: Int) -> AnyObject? {
        switch index {
        case 0:     return titleLabel
        default:    return nil
        }
    }

    init(title: String? = nil) {
        super.init(frame: CGRect.zero)
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
        NotificationCenter.default.addObserver(self, selector: #selector(PasscodePane.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PasscodePane.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    func shakePasscode() {
        UIView.animate(withDuration: 0.1, animations: {
                self.codeViewCenterConstraint?.updateOffset(-10)
                self.layoutIfNeeded()
        }) { complete in
            UIView.animate(withDuration: 0.1) {
                self.codeViewCenterConstraint?.updateOffset(0)
                self.layoutIfNeeded()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func keyboardWillShow(_ sender: Notification) {
        guard let keyboardFrame = (sender as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey]?.cgRectValue else {
            return
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.containerCenterConstraint?.updateOffset(-keyboardFrame.height/2)
            self.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(_ sender: Notification) {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerCenterConstraint?.updateOffset(0)
            self.layoutIfNeeded()
        })
    }
}
