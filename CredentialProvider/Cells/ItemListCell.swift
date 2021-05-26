//
//  ItemListCell.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/12/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

class ItemListCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.backgroundColor = highlighted ? UIColor.tableViewCellHighlighted : .white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
