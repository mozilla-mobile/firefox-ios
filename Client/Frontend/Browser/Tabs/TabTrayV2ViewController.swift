/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

struct TabTrayV2ControllerUX {
    static let CornerRadius = CGFloat(4.0)
}

class TabTrayV2ViewController: UIViewController{
    let tableView = UITableView()
    lazy var viewModel = TabTrayV2ViewModel(viewController: self)
        fileprivate let SectionHeaderIdentifier2 = "SectionHeader"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        tableView.register(TableViewCell.self, forCellReuseIdentifier: TableViewCell.identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier2)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.identifier, for: indexPath)
        let tabCell = cell as! TableViewCell
        tabCell.closeButton.addTarget(self, action: #selector(onCloseButton(_ :)), for: .touchUpInside)
        
        viewModel.configure(cell: tabCell, for: indexPath)
        tabCell.imageView?.snp.makeConstraints { make in
            make.height.width.equalTo(68)
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
        }
        
        tabCell.textLabel?.snp.makeConstraints { make in
            make.leading.equalTo(tabCell.imageView!.snp.trailing).offset(20)
            make.top.equalToSuperview().offset(18)
            make.bottom.equalTo(tabCell.detailTextLabel!.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        tabCell.detailTextLabel?.snp.makeConstraints { make in
            make.leading.equalTo(tabCell.imageView!.snp.trailing).offset(20)
            make.trailing.equalToSuperview()
            make.top.equalTo(tabCell.textLabel!.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-18)
        }
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
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier2) as? ThemedTableSectionHeaderFooterView, viewModel.numberOfRowsInSection(section: section) != 0 else {
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

class TableViewCell: UITableViewCell {
    static let identifier = "cell"
    static let BorderWidth: CGFloat = 3
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.sizeToFit()
        return button
    }()
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
       
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = TabTrayV2ControllerUX.CornerRadius
        imageView?.layer.borderWidth = 1
        imageView?.layer.borderColor = UIColor.Photon.Grey30.cgColor
        
        textLabel?.lineBreakMode = .byWordWrapping

        detailTextLabel?.textColor = UIColor.Photon.Grey40

    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
