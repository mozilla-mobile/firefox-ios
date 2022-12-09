/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Combine
import UIComponents

public class BrowserToolbar: UIView {
    private let backgroundLoading = GradientBackgroundView()
    private let backgroundDark = UIView()
    private let backgroundBright = UIView()
    private let stackView = UIStackView()

    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setImage(.backActive, for: .normal)
        backButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        backButton.accessibilityLabel = UIConstants.strings.browserBack
        backButton.isEnabled = false
        return backButton
    }()

    private lazy var forwardButton: UIButton = {
        let forwardButton = UIButton()
        forwardButton.setImage(.forwardActive, for: .normal)
        forwardButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        forwardButton.accessibilityLabel = UIConstants.strings.browserForward
        forwardButton.isEnabled = false
        return forwardButton
    }()

    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(.delete, for: .normal)
        deleteButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        deleteButton.isEnabled = false
        return deleteButton
    }()

    private lazy var contextMenuButton: UIButton = {
        let contextMenuButton = UIButton()
        contextMenuButton.setImage(.hamburgerMenu, for: .normal)
        contextMenuButton.tintColor = .primaryText
        if #available(iOS 14.0, *) {
            contextMenuButton.showsMenuAsPrimaryAction = true
            contextMenuButton.menu = UIMenu(children: [])
        }
        contextMenuButton.accessibilityLabel = UIConstants.strings.browserSettings
        contextMenuButton.accessibilityIdentifier = "HomeView.settingsButton"
        contextMenuButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        NSLayoutConstraint.activate([
            contextMenuButton.widthAnchor.constraint(equalToConstant: UIConstants.layout.contextMenuIconSize),
            contextMenuButton.heightAnchor.constraint(equalToConstant: UIConstants.layout.contextMenuIconSize)
        ])
        return contextMenuButton
    }()

    public var contextMenuButtonAnchor: UIView { contextMenuButton }
    public var deleteButtonAnchor: UIView { deleteButton }

    let viewModel: URLBarViewModel
    private var cancellables = Set<AnyCancellable>()

    public init(viewModel: URLBarViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        bindButtonActions()
        bindViewModelEvents()

        let background = UIView()
        background.backgroundColor = .foundation
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)

        stackView.distribution = .fillEqually

        stackView.addArrangedSubview(backButton)
        stackView.addArrangedSubview(forwardButton)
        stackView.addArrangedSubview(deleteButton)
        stackView.addArrangedSubview(contextMenuButton)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: UIConstants.layout.browserToolbarHeight)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindButtonActions() {
        backButton
            .publisher(event: .touchUpInside)
            .sink { [unowned self] _ in
                self.viewModel
                    .viewActionSubject
                    .send(.backButtonTap)
            }
            .store(in: &cancellables)

        forwardButton
            .publisher(event: .touchUpInside)
            .sink { [unowned self] _ in
                self.viewModel
                    .viewActionSubject
                    .send(.forwardButtonTap)
            }
            .store(in: &cancellables)

        deleteButton
            .publisher(event: .touchUpInside)
            .sink { [unowned self] _ in
                self.viewModel
                    .viewActionSubject
                    .send(.deleteButtonTap)
            }
            .store(in: &cancellables)

        let event: UIControl.Event
        if #available(iOS 14.0, *) {
            event = .menuActionTriggered
        } else {
            event = .touchUpInside
        }
        contextMenuButton.publisher(event: event)
            .sink { [unowned self] _ in
                self.viewModel.viewActionSubject.send(.contextMenuTap(anchor: self.contextMenuButton))
            }
            .store(in: &cancellables)

    }

    private func bindViewModelEvents() {
        viewModel
            .$canGoBack
            .sink { [backButton] in
                backButton.isEnabled = $0
                backButton.alpha = $0 ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
            }
            .store(in: &cancellables)

        viewModel
            .$canGoForward
            .sink { [forwardButton] in
                forwardButton.isEnabled = $0
                forwardButton.alpha = $0 ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
            }
            .store(in: &cancellables)

        viewModel
            .$canDelete
            .sink { [deleteButton] in
                deleteButton.isEnabled = $0
                deleteButton.alpha = $0 ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
            }
            .store(in: &cancellables)
    }
}
