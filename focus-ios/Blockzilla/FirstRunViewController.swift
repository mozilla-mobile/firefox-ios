/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FirstRunViewController: UIViewController {
    override func viewDidLoad() {
        modalTransitionStyle = .crossDissolve

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.alignment = .center
        let attributes = [NSAttributedStringKey.paragraphStyle: style]

        let background = GradientBackgroundView(alpha: 0.2)
        view.addSubview(background)

        let wave = WaveView()
        view.addSubview(wave)

        let title = UILabel()
        title.font = UIConstants.fonts.firstRunTitle
        title.numberOfLines = 0
        title.textColor = .white
        title.attributedText = NSAttributedString(string: UIConstants.strings.firstRunTitle, attributes: attributes)
        view.addSubview(title)

        let message = UILabel()
        message.font = UIConstants.fonts.firstRunMessage
        message.numberOfLines = 0
        message.textColor = .white
        message.attributedText = NSAttributedString(string: UIConstants.strings.firstRunMessage, attributes: attributes)
        view.addSubview(message)

        let button = InsetButton()
        button.setTitle(UIConstants.strings.firstRunButton, for: .normal)
        button.setTitleColor(UIConstants.colors.firstRunButton, for: .normal)
        button.titleLabel?.font = UIConstants.fonts.firstRunButton
        button.backgroundColor = UIConstants.colors.firstRunButtonBackground
        button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIConstants.colors.firstRunButtonBorder.cgColor
        button.layer.cornerRadius = 3
        button.addTarget(self, action: #selector(didPressDismiss), for: .touchUpInside)
        button.accessibilityIdentifier = "FirstRunViewController.button"
        view.addSubview(button)

        let margin = 8
        let maxWidth = 315

        background.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        wave.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.height.equalTo(200)
        }

        title.snp.makeConstraints { make in
            make.top.equalTo(view.snp.centerY)
            make.top.equalTo(wave.snp.bottom).offset(30)
            make.centerX.equalTo(view)
            make.width.lessThanOrEqualTo(maxWidth)
            make.width.lessThanOrEqualTo(view).inset(margin)
        }

        message.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(20)
            make.centerX.equalTo(view)
            make.width.lessThanOrEqualTo(maxWidth)
            make.width.lessThanOrEqualTo(view).inset(margin)
        }

        button.snp.makeConstraints { make in
            make.top.equalTo(message.snp.bottom).offset(60)
            make.centerX.equalTo(view)
            make.width.lessThanOrEqualTo(maxWidth)
            make.width.lessThanOrEqualTo(view).inset(margin)
            make.width.equalTo(view).priority(500)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc private func didPressDismiss() {
        dismiss(animated: true, completion: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (UIDevice.current.userInterfaceIdiom == .phone) ? .portrait : .allButUpsideDown
    }
}
