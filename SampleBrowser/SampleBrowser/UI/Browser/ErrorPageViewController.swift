// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ErrorPageViewController: UIViewController {
    private lazy var errorLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: view.topAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func configure(errorMessage: String) {
        errorLabel.text = errorMessage
    }
}
