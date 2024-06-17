/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SafariInstructionsViewController: UIViewController {
    private let detector = BlockerEnabledDetector()

    private lazy var disabledStateView: DisabledStateView = {
        let disabledStateView = DisabledStateView()
        disabledStateView.translatesAutoresizingMaskIntoConstraints = false
        return disabledStateView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .accent

        view.addSubview(disabledStateView)

        NSLayoutConstraint.activate([
            disabledStateView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.layout.settingsViewOffset),
            disabledStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            disabledStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(updateEnabledState), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    func updateEnabledState() {
        detector.detectEnabled(view) { enabled in
            if enabled {
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
}

private class DisabledStateView: UIView {
    private lazy var label: SmartLabel = {
        let label = SmartLabel()
        label.text = UIConstants.strings.safariInstructionsNotEnabled
        label.textColor = UIColor.extensionNotEnabled
        label.font = .body18Bold
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var instructionsView: InstructionsView = {
        let instructionsView = InstructionsView()
        instructionsView.translatesAutoresizingMaskIntoConstraints = false
        return instructionsView
    }()

    private lazy var image: UIImageView = {
        let disableStateIcon = UIImage(named: "enabled-no")!
        let image = UIImageView(image: disableStateIcon)
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    init() {
        super.init(frame: CGRect.zero)

        addSubview(label)
        addSubview(instructionsView)
        addSubview(image)

        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            image.topAnchor.constraint(equalTo: self.topAnchor),
            image.heightAnchor.constraint(equalToConstant: UIConstants.layout.settingsSafariViewImageSize),
            image.widthAnchor.constraint(equalTo: image.heightAnchor),

            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: UIConstants.layout.settingsViewOffset),

            instructionsView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            instructionsView.widthAnchor.constraint(equalToConstant: UIConstants.layout.settingsInstructionViewWidth),
            instructionsView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: UIConstants.layout.settingsViewOffset),
            instructionsView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
