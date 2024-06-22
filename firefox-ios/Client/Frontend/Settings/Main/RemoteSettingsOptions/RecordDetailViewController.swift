// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class RecordDetailViewController: UIViewController {
    private var recordDetails: String
    private lazy var textView: UITextView = .build { textViewVal in
        textViewVal.isEditable = false
    }
    
    init(recordDetails: String) {
        self.recordDetails = recordDetails
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
    }

    private func setupTextView() {
        textView.text = recordDetails
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.backgroundColor = .systemBackground
    }
}
