// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ExperimentsSettingsView: UIView {
    let customRemoteSettingsTextField: UITextField = .build { textField in
        textField.placeholder = "URL to remote settings JSON"
        textField.borderStyle = .roundedRect
    }

    let reloadButton: UIButton = .build { button in
        button.setImage(UIImage(named: "nav-refresh"), for: .normal)
    }

    let usePreviewPrompt: UITextView = .build { prompt in
        prompt.text = "Use Preview Collection (requires restart)"
    }

    let usePreviewToggle: UISwitch = .build()

    let customExperimentDataTextView: UITextView = .build { textView in
        textView.layer.cornerRadius = 8
        textView.textContainer.lineFragmentPadding = 8.0
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.2).cgColor
    }

    let updateButton: UIButton = .build { button in
        button.setTitle("Reset", for: .normal)
        button.backgroundColor = .systemRed
    }

    private let gapView: UIView = .build { view in
        view.backgroundColor = .systemRed
    }

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .systemBackground

        addSubviews(customRemoteSettingsTextField, reloadButton, usePreviewPrompt,
                    usePreviewToggle, customExperimentDataTextView, updateButton, gapView)
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            reloadButton.heightAnchor.constraint(equalTo: customRemoteSettingsTextField.heightAnchor),
            reloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            reloadButton.widthAnchor.constraint(equalTo: reloadButton.heightAnchor),
            reloadButton.topAnchor.constraint(equalTo: customRemoteSettingsTextField.topAnchor),
            customRemoteSettingsTextField.heightAnchor.constraint(equalToConstant: 44.0),
            customRemoteSettingsTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0),
            customRemoteSettingsTextField.trailingAnchor.constraint(equalTo: reloadButton.leadingAnchor, constant: -8.0),
            customRemoteSettingsTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8.0),
            usePreviewPrompt.topAnchor.constraint(equalTo: customRemoteSettingsTextField.bottomAnchor, constant: 8.0),
            usePreviewPrompt.heightAnchor.constraint(equalToConstant: 44.0),
            usePreviewPrompt.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0),
            usePreviewPrompt.trailingAnchor.constraint(equalTo: usePreviewToggle.leadingAnchor, constant: -8.0),
            usePreviewPrompt.bottomAnchor.constraint(equalTo: customExperimentDataTextView.topAnchor, constant: 8.0),
            usePreviewToggle.topAnchor.constraint(equalTo: customRemoteSettingsTextField.bottomAnchor, constant: 8.0),
            usePreviewToggle.heightAnchor.constraint(equalToConstant: 44.0),
            usePreviewToggle.leadingAnchor.constraint(equalTo: usePreviewPrompt.trailingAnchor, constant: 8.0),
            usePreviewToggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            usePreviewToggle.bottomAnchor.constraint(equalTo: customExperimentDataTextView.topAnchor, constant: 8.0),
            customExperimentDataTextView.topAnchor.constraint(equalTo: usePreviewPrompt.bottomAnchor, constant: 8.0),
            customExperimentDataTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0),
            customExperimentDataTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            customExperimentDataTextView.bottomAnchor.constraint(equalTo: updateButton.topAnchor, constant: -8.0),
            updateButton.heightAnchor.constraint(equalToConstant: 44.0),
            updateButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            updateButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            updateButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            gapView.topAnchor.constraint(equalTo: updateButton.bottomAnchor),
            gapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gapView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
