// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

class SearchEngineSelectionViewController: UIViewController, BottomSheetChild {
    // MARK: - Properties
    var themeManager: ThemeManager
    weak var coordinator: SearchEngineSelectionCoordinator?
    private let windowUUID: WindowUUID
    private let logger: Logger

    // MARK: - UI/UX elements
    private lazy var placeholderView: UILabel = .build { view in
        view.text = "Some content can go here 😀"
        view.numberOfLines = 0
        view.textAlignment = .center
    }

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.logger = logger
        super.init(nibName: nil, bundle: nil)

        // TODO
        // ...
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        view.addSubview(placeholderView)
        NSLayoutConstraint.activate([
            placeholderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func willDismiss() {
        // TODO
    }
}
