/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SnapKit
import UIKit
import Storage

private enum LibraryViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 50
}

class LibraryViewController: UIViewController {
    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]

    weak var delegate: LibraryPanelDelegate?

    fileprivate lazy var buttonContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.clipsToBounds = true
        stackView.accessibilityNavigationStyle = .combined
        stackView.accessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history, remote tabs, reading list).")
        return stackView
    }()

    fileprivate var controllerContainerView = UIView()
    fileprivate var buttons: [LibraryPanelButton] = []

    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?

    init(profile: Profile) {
        self.profile = profile

        self.panelDescriptors = LibraryPanels(profile: profile).enabledPanels

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.browser.background
        self.edgesForExtendedLayout = []

        view.addSubview(buttonContainerView)
        view.addSubview(controllerContainerView)

        buttonContainerView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeArea.bottom)
            make.leading.trailing.equalTo(self.view).inset(14)
            make.height.equalTo(LibraryViewControllerUX.ButtonContainerHeight)
        }

        controllerContainerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.view)
            make.bottom.equalTo(buttonContainerView.snp.top)
        }

        updateButtons()
        applyTheme()
        if selectedPanel == nil {
            selectedPanel = .bookmarks
        }
    }

    var selectedPanel: LibraryPanelType? = nil {
        didSet {
            if oldValue == selectedPanel {
                // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
                return
            }

            if let index = oldValue?.rawValue {
                if index < buttons.count {
                    let currentButton = buttons[index]
                    currentButton.isSelected = false
                }
            }

            hideCurrentPanel()

            if let index = selectedPanel?.rawValue {
                if index < buttons.count {
                    let newButton = buttons[index]
                    newButton.isSelected = true
                }

                if index < panelDescriptors.count {
                    panelDescriptors[index].setup()
                    if let panel = self.panelDescriptors[index].viewController, let navigationController = self.panelDescriptors[index].navigationController {
                        let accessibilityLabel = self.panelDescriptors[index].accessibilityLabel
                        setupLibraryPanel(panel, accessibilityLabel: accessibilityLabel)
                        self.showPanel(navigationController)
                    }
                }
            }
            self.updateButtonTints()
        }
    }

    func setupLibraryPanel(_ panel: UIViewController, accessibilityLabel: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.title = accessibilityLabel
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.currentName == .dark ? .lightContent : .default
    }

    fileprivate func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: false)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(panel.view)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.didMove(toParent: self)
    }

    @objc func tappedButton(_ sender: UIButton!) {
        for (index, button) in buttons.enumerated() where button == sender {
            let newSelectedPanel = LibraryPanelType(rawValue: index)

            // If we're already on the selected panel and the user has
            // tapped for a second time, pop it to the root view controller.
            if newSelectedPanel == selectedPanel {
                let panel = self.panelDescriptors[safe: index]?.navigationController
                panel?.popToRootViewController(animated: true)
            }

            selectedPanel = newSelectedPanel
            if selectedPanel == .bookmarks {
                TelemetryWrapper.recordEvent(category: .action, method: .view, object: .bookmarksPanel, value: .homePanelTabButton)
            } else if selectedPanel == .downloads {
                TelemetryWrapper.recordEvent(category: .action, method: .view, object: .downloadsPanel, value: .homePanelTabButton)
            }
            break
        }
    }

    fileprivate func updateButtons() {
        for panel in panelDescriptors {
            let button = LibraryPanelButton()
            button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
            if let image = UIImage.templateImageNamed(panel.imageName) {
                button.setImage(image, for: .normal)
            }

            button.nameLabel.text = panel.accessibilityLabel
            button.accessibilityLabel = panel.accessibilityLabel
            button.accessibilityIdentifier = panel.accessibilityIdentifier
            buttons.append(button)
            self.buttonContainerView.addArrangedSubview(button)
        }
    }

    func updateButtonTints() {
        for (index, button) in self.buttons.enumerated() {
            let image: String
            if index == self.selectedPanel?.rawValue {
                button.tintColor = self.buttonSelectedTintColor
                button.nameLabel.textColor = self.buttonSelectedTintColor
                image = panelDescriptors[index].activeImageName
            } else {
                button.tintColor = self.buttonTintColor
                button.nameLabel.textColor = self.buttonTintColor
                image = panelDescriptors[index].imageName
            }

            if let image = UIImage.templateImageNamed(image) {
                button.setImage(image, for: .normal)
            }
        }
    }
}

// MARK: UIAppearance
extension LibraryViewController: Themeable {
    func applyTheme() {
        panelDescriptors.forEach { item in
            (item.viewController as? Themeable)?.applyTheme()
        }
        buttonContainerView.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        view.backgroundColor = UIColor.theme.homePanel.toolbarBackground
        buttonTintColor = UIColor.theme.homePanel.toolbarTint
        buttonSelectedTintColor = UIColor.theme.homePanel.toolbarHighlight
        updateButtonTints()
    }
}
