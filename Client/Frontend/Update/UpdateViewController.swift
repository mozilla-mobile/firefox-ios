/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import Leanplum

// Update view UX constants
struct UpdateViewControllerUX {
    struct DoneButton {
        static let paddingTop = 20
        static let paddingRight = 20
        static let height = 20
    }
     
    struct ImageView {
        static let paddingTop = 50
        static let paddingLeft = 18
        static let height = 70
    }
    
    struct TitleLabel {
        static let paddingTop = 15
        static let paddingLeft = 18
        static let height = 40
    }
    
    struct MidTableView {
        static let cellIdentifier = "UpdatedCoverSheetTableViewCellIdentifier"
        static let paddingTop = 20
        static let paddingBottom = -10
    }
    
    struct StartBrowsingButton {
        static let colour = UIColor.Photon.Blue50
        static let cornerRadius:CGFloat = 10
        static let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let height = 46
        static let edgeInset = 18
    }
}

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
    // Public constants 
    let viewModel:UpdateViewModel = UpdateViewModel()
    static let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return UpdateViewController.theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return UpdateViewController.theme == .dark ? .black : .white
    }
    private lazy var updatesTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.register(UpdateCoverSheetTableViewCell.self, forCellReuseIdentifier: UpdateViewControllerUX.MidTableView.cellIdentifier)
        tableView.backgroundColor = fxBackgroundThemeColour
        tableView.separatorStyle = .none
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    private lazy var titleImageView: UIImageView = {
        let imgView = UIImageView(image: viewModel.updateCoverSheetModel?.titleImage)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.updateCoverSheetModel?.titleText
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 34)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.SettingsSearchDoneButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    private lazy var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UpdateViewControllerUX.StartBrowsingButton.font
        button.layer.cornerRadius = UpdateViewControllerUX.StartBrowsingButton.cornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UpdateViewControllerUX.StartBrowsingButton.colour
        return button
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
        setupTopView()
        setupMidView()
        setupBottomView()
    }
    
    private func initialViewSetup() {
        self.view.backgroundColor = fxBackgroundThemeColour
        
        // Initialize
        self.view.addSubview(doneButton)
        self.view.addSubview(titleImageView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(startBrowsingButton)
        self.view.addSubview(updatesTableView)
    }
    
    private func setupTopView() {
        // Done button target setup
        doneButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)
        
        // Done button constraints setup
        // This button is located at top right hence top, right and height
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(UpdateViewControllerUX.DoneButton.paddingTop)
            make.right.equalToSuperview().inset(UpdateViewControllerUX.DoneButton.paddingRight)
            make.height.equalTo(UpdateViewControllerUX.DoneButton.height)
        }
        
        // The top imageview constraints setup
        // This imageview is located at the top left of the view hence top, left, height, width
        titleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UpdateViewControllerUX.ImageView.paddingLeft)
            make.top.equalTo(view.snp.topMargin).inset(UpdateViewControllerUX.ImageView.paddingTop)
            make.height.width.equalTo(UpdateViewControllerUX.ImageView.height)
        }
        
        // Top title label constraints setup
        // This is the bigger tittle that is located right below the top image hence left, right, height and top (relating to imageview)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleImageView.snp.bottom).offset(UpdateViewControllerUX.TitleLabel.paddingTop)
            make.left.equalToSuperview().inset(UpdateViewControllerUX.TitleLabel.paddingLeft)
            make.right.equalToSuperview()
            make.height.equalTo(UpdateViewControllerUX.TitleLabel.height)
        }
    }
    
    private func setupMidView() {
        // Mid tableview setup
        // Mid tableview hosts the items for updated cover sheet
        self.updatesTableView.delegate = self
        self.updatesTableView.dataSource = self
        // Mid tableview constraints
        // The tableview sits b/w top and bottom view hence top, bottom constraints with equal width of the superview
        self.updatesTableView.snp.makeConstraints({ make in
            make.top.equalTo(titleLabel.snp.bottom).offset(UpdateViewControllerUX.MidTableView.paddingTop)
            make.bottom.equalTo(startBrowsingButton.snp.top).offset(UpdateViewControllerUX.MidTableView.paddingBottom)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        })
    }
    
    private func setupBottomView() {
        // Bottom start browsing target setup
        startBrowsingButton.addTarget(self, action: #selector(startBrowsing), for: .touchUpInside)
        
        // Bottom start button constraints
        // Bottom start button sits at the bottom of the screen with some padding on left and right hence left, right, bottom, height
        startBrowsingButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewControllerUX.StartBrowsingButton.edgeInset)
            let h = view.frame.height
            // On large iPhone screens, bump this up from the bottom
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (h > 800 ? 60 : 20)
            make.bottom.equalToSuperview().inset(offset)
            make.height.equalTo(UpdateViewControllerUX.StartBrowsingButton.height)
        }
    }
    
    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        LeanPlumClient.shared.track(event: .dismissedUpdateCoverSheet)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedUpdateCoverSheet)
    }
    
    @objc private func startBrowsing() {
        viewModel.startBrowsing?()
        LeanPlumClient.shared.track(event: .dismissUpdateCoverSheetAndStartBrowsing)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: UpdateViewControllerUX.MidTableView.cellIdentifier, for: indexPath) as? UpdateCoverSheetTableViewCell
        let currentLastItem = viewModel.updates[indexPath.row]
        cell?.updateCoverSheetCellDescriptionLabel.text = currentLastItem.updateText
        cell?.updateCoverSheetCellImageView.image = currentLastItem.updateImage
        cell?.fxThemeSupport()
        return cell!
    }
}
