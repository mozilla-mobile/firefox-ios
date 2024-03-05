/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class InstructionsView: UIView {

    private lazy var settingsInstructionView: InstructionView = {
        let settingsIcon = UIImage(named: "instructions-cog")!
        let instructionView = InstructionView(text: UIConstants.strings.instructionToOpenSafari, image: settingsIcon)
        instructionView.translatesAutoresizingMaskIntoConstraints = false
        return instructionView
    }()

    private lazy var safariInstructionView: InstructionView = {
        let safariIcon = UIImage(named: "instructions-safari")!
        let safariInstructionView = InstructionView(text: UIConstants.strings.safariInstructionsExtensions, image: safariIcon)
        safariInstructionView.translatesAutoresizingMaskIntoConstraints = false
        return safariInstructionView
    }()

    private lazy var enableInstructionView: InstructionView = {
        let toggleIcon = UIImage(named: "instructions-switch")!
        let enableInstructionView = InstructionView(text: String(format: UIConstants.strings.safariInstructionsEnable, AppInfo.productName), image: toggleIcon)
        enableInstructionView.translatesAutoresizingMaskIntoConstraints = false
        return enableInstructionView
    }()

    init() {
        super.init(frame: CGRect.zero)

        addSubview(settingsInstructionView)
        addSubview(safariInstructionView)
        addSubview(enableInstructionView)

        NSLayoutConstraint.activate([
            settingsInstructionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            settingsInstructionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            settingsInstructionView.topAnchor.constraint(equalTo: self.topAnchor),

            safariInstructionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            safariInstructionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            safariInstructionView.topAnchor.constraint(equalTo: settingsInstructionView.bottomAnchor, constant: UIConstants.layout.settingsViewOffset),

            enableInstructionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            enableInstructionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            enableInstructionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            enableInstructionView.topAnchor.constraint(equalTo: safariInstructionView.bottomAnchor, constant: UIConstants.layout.settingsViewOffset)

        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class InstructionView: UIView {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var label: SmartLabel = {
        let label = SmartLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .body18
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    init(text: String, image: UIImage) {
        super.init(frame: CGRect.zero)

        imageView.image = image
        label.text = text
        addSubview(imageView)
        addSubview(label)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: UIConstants.layout.settingsInstructionImageViewHeight),
            imageView.widthAnchor.constraint(equalToConstant: UIConstants.layout.settingsInstructionImageViewWidth),

            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: UIConstants.layout.settingsPadding),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
