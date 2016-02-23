/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
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
        let offset = floor(rect.width / CGFloat(passcodeSize))
        let size = CGSize(width: offset, height: rect.height)
        let containerRect = CGRect(origin: CGPointZero, size: size)
        // Chop up our rect into n containers and draw each digit centered inside.
        (0..<passcodeSize).forEach { index in
            let characterToDraw = index < inputtedCode.characters.count ? filledDigitString : blankDigitString
            var boundingRect = characterToDraw.boundingRectWithSize(size, options: [], context: nil)
            boundingRect.center = containerRect.center
            boundingRect = CGRectApplyAffineTransform(boundingRect, CGAffineTransformMakeTranslation(floor(CGFloat(index) * offset), 0))
            characterToDraw.drawInRect(boundingRect)
        }
    }
}

/// A pane that gets displayed inside the PasscodeViewController that displays a title and a passcode input field.
class PasscodePane: UIView {
    let codeInputView = PasscodeInputView(passcodeSize: 4)

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
            make.top.equalTo(self).offset(PasscodeUX.TopMargin)
        }

        titleLabel.snp_makeConstraints { make in
            make.centerX.equalTo(centerContainer)
            make.top.equalTo(centerContainer)
            make.bottom.equalTo(codeInputView.snp_top).offset(-PasscodeUX.TitleVerticalSpacing)
        }

        codeInputView.snp_makeConstraints { make in
            make.centerX.equalTo(centerContainer)
            make.bottom.equalTo(centerContainer)
            make.size.equalTo(PasscodeUX.PasscodeFieldSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}