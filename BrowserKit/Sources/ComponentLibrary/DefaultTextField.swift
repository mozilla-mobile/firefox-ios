// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class DefaultTextField: UITextField, ThemeApplicable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clearButtonMode = .whileEditing
        font = UIFont.preferredFont(forTextStyle: .body)
        replaceClearButtonIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func replaceClearButtonIcon() {
        guard let clearButton = value(forKey: "clearButton") as? UIButton else { return }
        clearButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
        clearButton.setImage(UIImage(named: StandardImageIdentifiers.Large.crossCircleFill),
                             for: .normal)
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
    }
}

@available(iOS 17, *)
#Preview {
    let textField = DefaultTextField()
    textField.backgroundColor = .red.withAlphaComponent(0.2)
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.widthAnchor.constraint(equalToConstant: 300).isActive = true
    textField.heightAnchor.constraint(equalToConstant: 100).isActive = true
    return textField
}
