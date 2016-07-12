/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit

struct ButtonToastUX {
    static let ToastDismissAfter = 4.0
    static let ToastPadding = 15.0
    static let ToastButtonPadding:CGFloat = 10.0
    static let ToastDelay = 0.9
    static let ToastButtonBorderRadius:CGFloat = 5
    static let ToastButtonBorderWidth:CGFloat = 1
}

class ButtonToast: UIView {
    
    private var dismissed = false
    private var completionHandler: ((Bool) -> Void)?
    private lazy var toast: UIView = {
        let toast = UIView()
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        return toast
    }()
    private var animationConstraint: Constraint?
    private lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ButtonToast.handleTap(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()
    
    init(labelText: String, buttonText:String, completion:(buttonPressed: Bool) -> Void) {
        super.init(frame: CGRect.zero)
        completionHandler = completion
        
        self.clipsToBounds = true
        self.addSubview(createView(labelText, buttonText: buttonText))
        
        toast.snp_makeConstraints { make in
            make.left.right.height.equalTo(self)
            animationConstraint = make.top.equalTo(self).offset(SimpleToastUX.ToastHeight).constraint
        }
        self.snp_makeConstraints { make in
            make.height.equalTo(SimpleToastUX.ToastHeight)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createView(_ labelText: String, buttonText: String) -> UIView {
        let label = UILabel()
        label.textColor = UIColor.white()
        label.font = SimpleToastUX.ToastFont
        label.text = labelText
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        toast.addSubview(label)
        
        let button = UIButton()
        button.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
        button.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
        button.layer.borderColor = UIColor.white().cgColor
        button.setTitle(buttonText, for: UIControlState())
        button.titleLabel?.font = SimpleToastUX.ToastFont
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(ButtonToast.buttonPressed(_:)))
        button.addGestureRecognizer(recognizer)
        
        toast.addSubview(button)
        
        label.snp_makeConstraints { (make) in
            make.leading.equalTo(toast).offset(ButtonToastUX.ToastPadding)
            make.centerY.equalTo(toast)
            make.trailing.equalTo(button.snp_leading)
        }
        
        button.snp_makeConstraints { (make) in
            make.trailing.equalTo(toast).offset(-ButtonToastUX.ToastPadding)
            make.centerY.equalTo(toast)
            make.width.equalTo(button.titleLabel!.intrinsicContentSize().width + 2*ButtonToastUX.ToastButtonPadding)
        }
        
        return toast
    }
    
    private func dismiss(_ buttonPressed: Bool) {
        guard dismissed == false else {
            return
        }
        dismissed = true
        superview?.removeGestureRecognizer(gestureRecognizer)
        
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
                self.animationConstraint?.updateOffset(SimpleToastUX.ToastHeight)
                self.layoutIfNeeded()
            },
            completion: { finished in
                self.removeFromSuperview()
                if(!buttonPressed) {
                    self.completionHandler?(false)
                }
            }
        )
    }
    
    func showToast() {
        layoutIfNeeded()
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
                self.animationConstraint?.updateOffset(0)
                self.layoutIfNeeded()
            },
            completion: { finished in
                let dispatchTime = DispatchTime.now() + Double(Int64(SimpleToastUX.ToastDismissAfter * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.after(when: dispatchTime, block: {
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
