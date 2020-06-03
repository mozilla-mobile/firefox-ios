/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit

struct TabTrayV2ControllerUX {
    static let cornerRadius = CGFloat(4.0)
    static let screenshotMarginLeftRight = CGFloat(20.0)
    static let screenshotMarginTopBottom = CGFloat(6.0)
    static let textMarginTopBottom = CGFloat(18.0)
}

class TabTrayV2ViewController: UIViewController{
    let tableView = UITableView()
    lazy var viewModel = TabTrayV2ViewModel(viewController: self)
    fileprivate let sectionHeaderIdentifier = "SectionHeader"
    
    lazy var toolbar: TrayToolbar = {
        let toolbar = TrayToolbar()
        toolbar.addTabButton.addTarget(self, action: #selector(didTapToolbarAddTab), for: .touchUpInside)
        toolbar.deleteButton.addTarget(self, action: #selector(didTapToolbarDelete), for: .touchUpInside)
        return toolbar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.addSubview(toolbar)
        
        tableView.register(TabTableViewCell.self, forCellReuseIdentifier: TabTableViewCell.identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        navigationItem.title = Strings.TabTrayV2Title
        
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.safeArea.left)
            make.right.equalTo(view.safeArea.right)
            make.bottom.equalTo(toolbar.snp.top)
            make.top.equalTo(self.view.safeArea.top)
        }

        toolbar.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }
    }
}

extension TabTrayV2ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TabTableViewCell.identifier, for: indexPath)
        guard let tabCell = cell as? TabTableViewCell else { return cell }
        tabCell.closeButton.addTarget(self, action: #selector(onCloseButton(_ :)), for: .touchUpInside)
        tabCell.separatorInset = UIEdgeInsets.zero
        
        viewModel.configure(cell: tabCell, for: indexPath)
        
        return tabCell
    }
    
    @objc func onCloseButton(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPosition) {
            viewModel.removeTab(forIndex: indexPath)
        }
    }
    
    @objc func didTapToolbarAddTab(_ sender: UIButton) {
        viewModel.addTab()
        dismissTabTray()
    }
    
    @objc func didTapToolbarDelete(_ sender: UIButton) {
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.AppMenuCloseAllTabsTitleString, style: .default, handler: { _ in self.viewModel.closeTabsForCurrentTray() }), accessibilityIdentifier: "TabTrayController.deleteButton.closeAll")
        controller.addAction(UIAlertAction(title: Strings.CancelString, style: .cancel, handler: nil), accessibilityIdentifier: "TabTrayController.deleteButton.cancel")
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        present(controller, animated: true, completion: nil)
    }
    
    func hideDisplayedTabs( completion: @escaping () -> Void) {
           let cells = tableView.visibleCells

           UIView.animate(withDuration: 0.2,
                          animations: {
                               cells.forEach {
                                   $0.alpha = 0
                               }
                           }, completion: { _ in
                               cells.forEach {
                                   $0.alpha = 1
                                   $0.isHidden = true
                               }
                               completion()
                           })
       }
    
    func dismissTabTray() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension TabTrayV2ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRowAt(index: indexPath)
        dismissTabTray()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderIdentifier) as? ThemedTableSectionHeaderFooterView, viewModel.numberOfRowsInSection(section: section) != 0 else {
            return nil
        }
        headerView.titleLabel.text = viewModel.getSectionDateHeader(section)
        headerView.applyTheme()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == TabSection(rawValue: section)?.rawValue && viewModel.numberOfRowsInSection(section: section) != 0 ? UITableView.automaticDimension : 0
    }
}

class TabTableViewCell: UITableViewCell {
    static let identifier = "tabCell"
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.sizeToFit()
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        guard let screenshotView = imageView,
            let websiteTitle = textLabel,
            let urlLabel = detailTextLabel
            else { return }
        
        screenshotView.contentMode = .scaleAspectFill
        screenshotView.clipsToBounds = true
        screenshotView.layer.cornerRadius = TabTrayV2ControllerUX.cornerRadius
        screenshotView.layer.borderWidth = 1
        screenshotView.layer.borderColor = UIColor.Photon.Grey30.cgColor

        urlLabel.textColor = UIColor.Photon.Grey40
        
        screenshotView.snp.makeConstraints { make in
            make.height.width.equalTo(68)
            make.leading.equalToSuperview().offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.screenshotMarginTopBottom)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.screenshotMarginTopBottom)
        }
        
        websiteTitle.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.textMarginTopBottom)
            make.bottom.equalTo(urlLabel.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.trailing.equalToSuperview()
            make.top.equalTo(websiteTitle.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.textMarginTopBottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
