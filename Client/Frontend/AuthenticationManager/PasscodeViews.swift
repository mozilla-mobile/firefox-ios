/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

private struct PasscodeUX {
    static let TitleVerticalSpacing: CGFloat = 32
    static let DigitSize: CGFloat = 30
    static let TopMargin: CGFloat = 80
    static let PasscodeFieldSize = CGSize(width: 160, height: 32)
    static let PasscodeFieldVerticalOffset: CGFloat = 100
}

@objc protocol PasscodeInputViewDelegate: AnyObject {
    func passcodeInputView(_ inputView: PasscodeInputView, didFinishEnteringCode code: String)
}

/// A custom, keyboard-able view that displays the blank/filled digits when entrering a passcode.
class PasscodeInputView: UIView, UIKeyInput {
    weak var delegate: PasscodeInputViewDelegate?

    var digitFont: UIFont = UIConstants.PasscodeEntryFont

    let blankCharacter: Character = "-"

    let filledCharacter: Character = "•"

    fileprivate let passcodeSize: Int

    fileprivate var inputtedCode: String = ""

    fileprivate var blankDigitString: NSAttributedString {
        return NSAttributedString(string: "\(blankCharacter)", attributes: [NSAttributedString.Key.font: digitFont])
    }

    fileprivate var filledDigitString: NSAttributedString {
        return NSAttributedString(string: "\(filledCharacter)", attributes: [NSAttributedString.Key.font: digitFont])
    }

    @objc var keyboardType: UIKeyboardType = .numberPad
    @objc var keyboardAppearance: UIKeyboardAppearance = ThemeManager.instance.currentName == .dark ? .dark : .default

    init(frame: CGRect, passcodeSize: Int) {
        self.passcodeSize = passcodeSize
        super.init(frame: frame)
        isOpaque = false
    }

    convenience init(passcodeSize: Int) {
        self.init(frame: .zero, passcodeSize: passcodeSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    func resetCode() {
        inputtedCode = ""
        setNeedsDisplay()
    }

    @objc var hasText: Bool {
        return !inputtedCode.isEmpty
    }

    @objc func insertText(_ text: String) {
        guard inputtedCode.count < passcodeSize else {
            return
        }

        inputtedCode += text
        setNeedsDisplay()
        if inputtedCode.count == passcodeSize {
            delegate?.passcodeInputView(self, didFinishEnteringCode: inputtedCode)
        }
    }

    // Required for implementing UIKeyInput
    @objc func deleteBackward() {
        guard !inputtedCode.isEmpty else {
            return
        }

        inputtedCode.remove(at: inputtedCode.index(before: inputtedCode.endIndex))
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let circleSize = CGSize(width: 14, height: 14)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(1)
        context.setStrokeColor(UIColor.theme.general.passcodeDot.cgColor)
        context.setFillColor(UIColor.theme.general.passcodeDot.cgColor)

        (0..<passcodeSize).forEach { index in
            let offset = floor(rect.width / CGFloat(passcodeSize))
            var circleRect = CGRect(size: circleSize)
            circleRect.center = CGPoint(x: (offset * CGFloat(index + 1))  - offset / 2, y: rect.height / 2)

            if index < inputtedCode.count {
                context.fillEllipse(in: circleRect)
            } else {
                context.strokeEllipse(in: circleRect)
            }
        }
    }
}

/// A pane that gets displayed inside the PasscodeViewController that displays a title and a passcode input field.
class PasscodePane: UIView {
    let codeInputView: PasscodeInputView

    var codeViewCenterConstraint: Constraint?
    var containerCenterConstraint: Constraint?

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIConstants.DefaultChromeFont
        label.isAccessibilityElement = true
        label.textColor = UIColor.theme.tableView.rowText
        return label
    }()

    fileprivate let centerContainer = UIView()

    override func accessibilityElementCount() -> Int {
        return 1
    }

    override func accessibilityElement(at index: Int) -> Any? {
        switch index {
        case 0:     return titleLabel
        default:    return nil
        }
    }

    init(title: String? = nil, passcodeSize: Int = 4) {
        codeInputView = PasscodeInputView(passcodeSize: passcodeSize)
        super.init(frame: .zero)
        backgroundColor = UIColor.theme.tableView.headerBackground

        titleLabel.text = title
        centerContainer.addSubview(titleLabel)
        centerContainer.addSubview(codeInputView)
        addSubview(centerContainer)

        centerContainer.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            containerCenterConstraint = make.centerY.equalTo(self).constraint
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(centerContainer)
            make.top.equalTo(centerContainer)
            make.bottom.equalTo(codeInputView.snp.top).offset(-PasscodeUX.TitleVerticalSpacing)
        }

        codeInputView.snp.makeConstraints { make in
            codeViewCenterConstraint = make.centerX.equalTo(centerContainer).constraint
            make.bottom.equalTo(centerContainer).offset(-PasscodeUX.PasscodeFieldVerticalOffset)
            make.size.equalTo(PasscodeUX.PasscodeFieldSize)
        }
        layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func shakePasscode() {
        UIView.animate(withDuration: 0.1, animations: {
                self.codeViewCenterConstraint?.update(offset: -10)
                self.layoutIfNeeded()
        }, completion: { complete in
            UIView.animate(withDuration: 0.1, animations: {
                self.codeViewCenterConstraint?.update(offset: 0)
                self.layoutIfNeeded()
            })
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func keyboardWillShow(_ sender: Notification) {
        guard let keyboardFrame = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue else {
            return
        }

        UIView.animate(withDuration: 0.1, animations: {
            self.containerCenterConstraint?.update(offset: -keyboardFrame.height/2)
            self.layoutIfNeeded()
        })
    }

    @objc func keyboardWillHide(_ sender: Notification) {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerCenterConstraint?.update(offset: 0)
            self.layoutIfNeeded()
        })
    }
}
