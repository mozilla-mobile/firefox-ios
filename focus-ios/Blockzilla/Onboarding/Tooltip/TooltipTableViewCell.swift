//
//  TooltipTableViewCell.swift
//  Blockzilla
//
//  Created by catalin.neculaide on 25.02.2022.
//  Copyright © 2022 Mozilla. All rights reserved.
//

import UIKit

class TooltipTableViewCell: UITableViewCell {

    private var tooltip = TooltipView()
    weak var delegate: TooltipViewDelegate?
    
    convenience init(title: String, body: String, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String? = nil) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tooltip)
        tooltip.set(title: title, body: body)
        tooltip.delegate = self
        tooltip.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TooltipTableViewCell: TooltipViewDelegate {
    func didTapTooltipDismissButton() {
        delegate?.didTapTooltipDismissButton()
    }
}
