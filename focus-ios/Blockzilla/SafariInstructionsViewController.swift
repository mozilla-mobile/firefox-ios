/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SafariInstructionsViewController: UIViewController {
    private let detector = BlockerEnabledDetector.makeInstance()
    private let disabledStateView = DisabledStateView()

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.colors.background

        view.addSubview(disabledStateView)

        disabledStateView.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalTo(view)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateEnabledState), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func updateEnabledState() {
        detector.detectEnabled(view) { enabled in
            if enabled {
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
}

private class DisabledStateView: UIView {
    init() {
        super.init(frame: CGRect.zero)

        let label = SmartLabel()
        label.text = UIConstants.strings.safariInstructionsNotEnabled
        label.textColor = UIConstants.colors.focusRed
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        addSubview(label)

        let instructionsView = InstructionsView()
        addSubview(instructionsView)

        let image = UIImageView(image: #imageLiteral(resourceName: "enabled-no"))
        addSubview(image)

        image.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self)
            make.size.lessThanOrEqualTo(650/7)
            make.width.equalTo(image.snp.height)
        }

        label.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(image.snp.bottom).offset(50)
        }

        instructionsView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.width.equalTo(250)
            make.top.equalTo(label.snp.bottom).offset(50)
            make.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
