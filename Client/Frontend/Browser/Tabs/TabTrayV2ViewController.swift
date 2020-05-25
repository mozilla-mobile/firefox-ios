/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

struct TabTrayV2ControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let ScreenshotMarginLeftRight = CGFloat(20.0)
    static let ScreenshotMarginTopBottom = CGFloat(6.0)
    static let TextMarginTopBottom = CGFloat(18.0)
}

class TabTrayV2ViewController: UIViewController{
    let tableView = UITableView()
    lazy var viewModel = TabTrayV2ViewModel(viewController: self)
    fileprivate let sectionHeaderIdentifier = "SectionHeader"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        tableView.register(TabTableViewCell.self, forCellReuseIdentifier: TabTableViewCell.identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
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
        guard let tabCell = cell as? TabTableViewCell,
            let imageView = tabCell.imageView,
            let textLabel = tabCell.textLabel,
            let detailTextLabel = tabCell.detailTextLabel
            else { return cell }
        tabCell.closeButton.addTarget(self, action: #selector(onCloseButton(_ :)), for: .touchUpInside)
        
        viewModel.configure(cell: tabCell, for: indexPath)
        
        return tabCell
    }
    
    @objc func onCloseButton(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to:tableView)
        if let indexPath = tableView.indexPathForRow(at:buttonPosition) {
            viewModel.removeTab(forIndex: indexPath)
        }
    }
}

extension TabTrayV2ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRowAt(index: indexPath)
        navigationController?.popViewController(animated: false)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderIdentifier) as? ThemedTableSectionHeaderFooterView, viewModel.numberOfRowsInSection(section: section) != 0 else {
            return nil
        }

        let section = TabSection(rawValue: section)
        headerView.titleLabel.text = section?.description.uppercased()

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
            let url = detailTextLabel
            else { return }
        
        screenshotView.contentMode = .scaleAspectFill
        screenshotView.clipsToBounds = true
        screenshotView.layer.cornerRadius = TabTrayV2ControllerUX.CornerRadius
        screenshotView.layer.borderWidth = 1
        screenshotView.layer.borderColor = UIColor.Photon.Grey30.cgColor
        
        websiteTitle.lineBreakMode = .byWordWrapping

        url.textColor = UIColor.Photon.Grey40
        
        screenshotView.snp.makeConstraints { make in
            make.height.width.equalTo(68)
            make.leading.equalToSuperview().offset(TabTrayV2ControllerUX.ScreenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.ScreenshotMarginTopBottom)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.ScreenshotMarginTopBottom)
        }
        
        websiteTitle.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(TabTrayV2ControllerUX.ScreenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.TextMarginTopBottom)
            make.bottom.equalTo(detailTextLabel!.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        url.snp.makeConstraints { make in
            make.leading.equalTo(imageView!.snp.trailing).offset(TabTrayV2ControllerUX.ScreenshotMarginLeftRight)
            make.trailing.equalToSuperview()
            make.top.equalTo(textLabel!.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.TextMarginTopBottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
