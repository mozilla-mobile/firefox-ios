/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit

struct ButtonToastUX {
    static let ToastPadding = 15.0
    static let ToastButtonPadding: CGFloat = 10.0
    static let ToastDelay = 0.9
    static let ToastButtonBorderRadius: CGFloat = 5
    static let ToastButtonBorderWidth: CGFloat = 1
}

private class HighlightableButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = UIColor.white
            } else {
                self.backgroundColor = UIColor.clear
            }
        }
    }
}

class ButtonToast: UIView {
    
    fileprivate var dismissed = false
    fileprivate var completionHandler: ((Bool) -> Void)?
    fileprivate lazy var toast: UIView = {
        let toast = UIView()
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        return toast
    }()
    fileprivate var animationConstraint: Constraint?
    fileprivate lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ButtonToast.handleTap(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()
    
    init(labelText: String, descriptionText: String? = nil, buttonText: String, completion:@escaping (_ buttonPressed: Bool) -> Void) {
        super.init(frame: CGRect.zero)
        completionHandler = completion
        
        self.clipsToBounds = true
        self.addSubview(createView(labelText, descriptionText: descriptionText, buttonText: buttonText))

        toast.snp.makeConstraints { make in
            make.left.right.height.equalTo(self)
            animationConstraint = make.top.equalTo(self).offset(SimpleToastUX.ToastHeight).constraint
        }
        self.snp.makeConstraints { make in
            make.height.equalTo(SimpleToastUX.ToastHeight)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func createView(_ labelText: String, descriptionText: String?, buttonText: String) -> UIView {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = SimpleToastUX.ToastFont
        label.text = labelText
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        toast.addSubview(label)
        
        let button = HighlightableButton()
        button.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
        button.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitle(buttonText, for: UIControlState())
        button.setTitleColor(self.toast.backgroundColor, for: .highlighted)
        button.titleLabel?.font = SimpleToastUX.ToastFont
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(ButtonToast.buttonPressed(_:)))
        button.addGestureRecognizer(recognizer)
        toast.addSubview(button)
        var descriptionLabel: UILabel?
        
        if let text = descriptionText {
            let textLabel = UILabel()
            textLabel.textColor = UIColor.white
            label.font = UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightRegular)
            textLabel.font = UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightRegular)
            textLabel.text = text
            textLabel.lineBreakMode = .byTruncatingTail
            toast.addSubview(textLabel)
            descriptionLabel = textLabel
        }
        
        if let description = descriptionLabel {
            label.snp.makeConstraints { (make) in
                make.leading.equalTo(toast).offset(ButtonToastUX.ToastPadding)
                make.top.equalTo(toast).offset(ButtonToastUX.ToastButtonPadding)
                make.trailing.equalTo(button.snp.leading)
            }
            description.snp.makeConstraints { (make) in
                make.leading.equalTo(toast).offset(ButtonToastUX.ToastPadding)
                make.bottom.equalTo(toast).offset(-ButtonToastUX.ToastButtonPadding)
                make.trailing.equalTo(button.snp.leading)
            }
        } else {
            label.snp.makeConstraints { (make) in
                make.leading.equalTo(toast).offset(ButtonToastUX.ToastPadding)
                make.centerY.equalTo(toast)
                make.trailing.equalTo(button.snp.leading)
            }
        }
        
        button.snp.makeConstraints { (make) in
            make.trailing.equalTo(toast).offset(-ButtonToastUX.ToastPadding)
            make.centerY.equalTo(toast)
            make.width.equalTo(button.titleLabel!.intrinsicContentSize.width + 2*ButtonToastUX.ToastButtonPadding)
        }
        
        return toast
    }
    
    fileprivate func dismiss(_ buttonPressed: Bool) {
        guard dismissed == false else {
            return
        }
        dismissed = true
        superview?.removeGestureRecognizer(gestureRecognizer)
        
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
                self.animationConstraint?.update(offset: SimpleToastUX.ToastHeight)
                self.layoutIfNeeded()
            },
            completion: { finished in
                self.removeFromSuperview()
                if !buttonPressed {
                    self.completionHandler?(false)
                }
            }
        )
    }
    
    func showToast(duration: Double = SimpleToastUX.ToastDismissAfter) {
        layoutIfNeeded()
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
                self.animationConstraint?.update(offset: 0)
                self.layoutIfNeeded()
            },
            completion: { finished in
                let dispatchTime = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.dismiss(false)
                })
            }
        )
    }
    
    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        self.completionHandler?(true)
        self.dismiss(true)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addGestureRecognizer(gestureRecognizer)
    }
    
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        dismiss(false)
    }
}
