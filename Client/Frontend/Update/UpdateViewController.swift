/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

/* The layout for update view controller.
    
 |----------------|
 |            Done|
 |Image           | (Top View)
 |                |
 |Title Multiline |
 |----------------|
 |(TableView)     |
 |                |
 | [img] Descp.   | (Mid View)
 |                |
 | [img] Descp.   |
 |                |
 |                |
 |----------------|
 |                |
 |                |
 |    [Button]    | (Bottom View)
 |----------------|
 
 */

class UpdateViewController: UIViewController {

    // Update view UX constants
    struct UX {
        static let doneButtonPadding: CGFloat = 20
        static let doneButtonHeight: CGFloat = 20
        static let imagePaddingTop: CGFloat = 50
        static let imagePaddingLeft: CGFloat = 18
        static let imageSize: CGFloat = 70
        static let titlePaddingTop: CGFloat = 15
        static let titlePaddingLeft: CGFloat = 18
        static let titleHeight: CGFloat = 40
        static let cellIdentifier = "UpdatedCoverSheetTableViewCellIdentifier"
        static let tableViewPaddingTop: CGFloat = 20
        static let tableViewPaddingBottom: CGFloat = -10

        static let primaryButtonColour = UIColor.Photon.Blue50
        static let primaryButtonCornerRadius: CGFloat = 10
        static let primaryButtonFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let primaryButtonHeight: CGFloat = 46
        static let primaryButtonEdgeInset: CGFloat = 18
    }

    // Public constants 
    var viewModel: UpdateViewModel
    static let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal

    // MARK: - Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return UpdateViewController.theme == .dark ? .white : .black
    }

    private var fxBackgroundThemeColour: UIColor {
        return UpdateViewController.theme == .dark ? .black : .white
    }

    private lazy var updatesTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.register(UpdateCoverSheetTableViewCell.self, forCellReuseIdentifier: UX.cellIdentifier)
        tableView.backgroundColor = fxBackgroundThemeColour
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var titleImageView: UIImageView = .build { imgView in
        imgView.image = self.viewModel.updateCoverSheetModel?.titleImage
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = self.viewModel.updateCoverSheetModel?.titleText
        label.textColor = self.fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 34)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var doneButton: UIButton = .build { button in
        button.setTitle(.SettingsSearchDoneButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(self.dismissAnimated), for: .touchUpInside)
    }

    private lazy var startBrowsingButton: UIButton = .build { button in
        button.setTitle(.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UX.primaryButtonFont
        button.layer.cornerRadius = UX.primaryButtonCornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UX.primaryButtonColour
        button.addTarget(self, action: #selector(self.startBrowsing), for: .touchUpInside)
    }

    init(viewModel: UpdateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    private func setupView() {
        view.backgroundColor = fxBackgroundThemeColour
        view.addSubviews(doneButton, titleImageView, titleLabel, startBrowsingButton, updatesTableView)
        updatesTableView.delegate = self
        updatesTableView.dataSource = self

        // Bottom start button constraints
        // Bottom start button sits at the bottom of the screen with some padding on left and right hence left, right, bottom, height
        let h = view.frame.height
        // On large iPhone screens, bump this up from the bottom
        let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (h > 800 ? 60 : 20)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: UX.doneButtonPadding),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.doneButtonPadding),
            doneButton.heightAnchor.constraint(equalToConstant: UX.doneButtonHeight),

            titleImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.imagePaddingLeft),
            titleImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: UX.imagePaddingTop),
            titleImageView.heightAnchor.constraint(equalToConstant: UX.imageSize),
            titleImageView.widthAnchor.constraint(equalToConstant: UX.imageSize),

            titleLabel.topAnchor.constraint(equalTo: titleImageView.bottomAnchor, constant: UX.titlePaddingTop),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.titlePaddingLeft),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: UX.titleHeight),

            updatesTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.tableViewPaddingTop),
            updatesTableView.bottomAnchor.constraint(equalTo: startBrowsingButton.topAnchor, constant: UX.tableViewPaddingBottom),
            updatesTableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            updatesTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            startBrowsingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.primaryButtonEdgeInset),
            startBrowsingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.primaryButtonEdgeInset),
            startBrowsingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset),
            startBrowsingButton.heightAnchor.constraint(equalToConstant: UX.primaryButtonHeight)
        ])
    }

    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedUpdateCoverSheet)
    }

    @objc private func startBrowsing() {
        viewModel.startBrowsing?()
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissUpdateCoverSheetAndStartBrowsing)
    }
}

extension UpdateViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.updates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UX.cellIdentifier, for: indexPath) as? UpdateCoverSheetTableViewCell
        let currentLastItem = viewModel.updates[indexPath.row]
        cell?.updateCoverSheetCellDescriptionLabel.text = currentLastItem.updateText
        cell?.updateCoverSheetCellImageView.image = currentLastItem.updateImage
        cell?.fxThemeSupport()
        return cell!
    }
}
