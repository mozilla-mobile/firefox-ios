/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class InstructionsView: UIView {
    init() {
        super.init(frame: CGRect.zero)

        let settingsInstruction = InstructionView(text: UIConstants.strings.safariInstructionsOpen, image: #imageLiteral(resourceName: "instructions-cog"))
        let safariInstruction = InstructionView(text: UIConstants.strings.safariInstructionsContentBlockers, image: #imageLiteral(resourceName: "instructions-safari"))
        let enableInstruction = InstructionView(text: String(format: UIConstants.strings.safariInstructionsEnable, AppInfo.productName), image: #imageLiteral(resourceName: "instructions-switch"))

        addSubview(settingsInstruction)
        addSubview(safariInstruction)
        addSubview(enableInstruction)

        let instructionOffset = 50

        settingsInstruction.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }

        safariInstruction.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(settingsInstruction.snp.bottom).offset(instructionOffset)
        }

        enableInstruction.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.top.equalTo(safariInstruction.snp.bottom).offset(instructionOffset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class InstructionView: UIView {
    init(text: String, image: UIImage) {
        super.init(frame: CGRect.zero)

        let imageView = UIImageView()
        imageView.image = image
        addSubview(imageView)

        let label = SmartLabel()
        label.text = text
        label.textColor = UIConstants.colors.defaultFont
        label.numberOfLines = 0
        label.font = UIConstants.fonts.safariInstruction
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        addSubview(label)

        imageView.snp.makeConstraints { make in
            make.leading.centerY.equalTo(self)
            make.width.equalTo(image.size.width)
            make.height.equalTo(image.size.height)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(30)
            make.trailing.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
