//
//  SwitchInputTableViewCell.swift
//  XRViewer
//
//  Created by Roberto Garrido on 29/1/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

class SwitchInputTableViewCell: UITableViewCell {

    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
