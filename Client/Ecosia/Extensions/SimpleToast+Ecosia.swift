// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension SimpleToast {
    
    enum AccessoryImage {
        case named(String), view(UIView)
    }
    
    @discardableResult
    // Ecosia: Migrated to be able to customize the accessory image shown, as well as bottom inset
    func showAlertWithText(
        _ text: String,
        image: AccessoryImage,
        bottomContainer: UIView,
        bottomInset: CGFloat? = nil
    ) -> SimpleToast {
        let toast = self.createView(text: text, image: image)
        toast.layer.cornerRadius = 10
        toast.layer.masksToBounds = true

        bottomContainer.addSubview(toast)
        toast.snp.makeConstraints { (make) in
            make.left.equalTo(bottomContainer).offset(CGFloat(16))
            make.right.equalTo(bottomContainer).offset(-CGFloat(16))
            make.height.equalTo(Toast.UX.toastHeight)
            make.bottom.equalTo(bottomContainer).offset(-((bottomInset ?? 0) + CGFloat(12)))
        }
        animate(toast)
        return self
    }
    
    fileprivate func createView(text: String, image: AccessoryImage) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        stack.layer.cornerRadius = 10
        stack.backgroundColor = UIColor.legacyTheme.ecosia.quarternaryBackground

        let toast = UILabel()
        toast.text = text
        toast.numberOfLines = 1
        toast.textColor = UIColor.legacyTheme.ecosia.primaryTextInverted
        toast.font = UIFont.preferredFont(forTextStyle: .body)
        toast.adjustsFontForContentSizeCategory = true
        toast.adjustsFontSizeToFitWidth = true
        toast.textAlignment = .left
        toast.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let imageView: UIView
        
        switch image {
        case let .named(name):
            imageView = UIImageView(image: .init(named: name)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = UIColor.legacyTheme.ecosia.toastImageTint
            imageView.contentMode = .scaleAspectFit
            imageView.setContentHuggingPriority(.required, for: .horizontal)
        case let .view(view):
            imageView = view
        }

        let leftSpace = UIView()
        leftSpace.widthAnchor.constraint(equalToConstant: 8).isActive = true
        stack.addArrangedSubview(leftSpace)
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(toast)
        let rightSpace = UIView()
        rightSpace.widthAnchor.constraint(equalToConstant: 8).isActive = true
        stack.addArrangedSubview(rightSpace)
        return stack
    }
}
