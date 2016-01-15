/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class InstructionsView: UIView {
    init() {
        super.init(frame: CGRectZero)

        let settingsText = NSLocalizedString("Open Settings App", comment: "Label for instructions to enable shown on the second introduction screen")
        let safariText = NSLocalizedString("Tap Safari, then select Content Blockers", comment: "Label for instructions to enable shown on the second introduction screen")
        let enableText = String(format: NSLocalizedString("Enable %@", comment: "Label for instructions to enable shown on the second introduction screen"), AppInfo.ProductName)

        let settingsInstruction = InstructionView(text: settingsText, image: UIImage(named: "instructions-cog")!)
        let safariInstruction = InstructionView(text: safariText, image: UIImage(named: "instructions-safari")!)
        let enableInstruction = InstructionView(text: enableText, image: UIImage(named: "instructions-switch")!)

        addSubview(settingsInstruction)
        addSubview(safariInstruction)
        addSubview(enableInstruction)

        let instructionOffset = 50

        settingsInstruction.snp_makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }

        safariInstruction.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(settingsInstruction.snp_bottom).offset(instructionOffset)
        }

        enableInstruction.snp_makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.top.equalTo(safariInstruction.snp_bottom).offset(instructionOffset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class InstructionView: UIView {
    init(text: String, image: UIImage) {
        super.init(frame: CGRectZero)

        let imageView = UIImageView()
        imageView.image = image
        addSubview(imageView)

        let label = UILabel()
        label.text = text
        label.textColor = UIConstants.Colors.DefaultFont
        label.numberOfLines = 0
        label.font = UIConstants.Fonts.DefaultFontMedium
        label.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        addSubview(label)

        imageView.snp_makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.equalTo(image.size.width)
            make.height.equalTo(image.size.height)
        }

        label.snp_makeConstraints { make in
            make.leading.equalTo(imageView.snp_trailing).offset(30)
            make.trailing.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}