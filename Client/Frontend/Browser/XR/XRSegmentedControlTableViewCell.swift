//
//  SegmentedControlTableViewCell.swift
//  XRViewer
//
//  Created by Anthony Morales on 2/28/19.
//  Copyright © 2019 Mozilla. All rights reserved.
//

import UIKit

class SegmentedControlTableViewCell: UITableViewCell {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
