//
//  EmptyPlaceholderCell.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/20/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

class EmptyPlaceholderCell: UITableViewCell {
    
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        learnMoreButton.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
