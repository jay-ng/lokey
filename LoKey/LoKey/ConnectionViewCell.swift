//
//  ConnectionViewCell.swift
//  LoKey
//
//  Created by Will Steiner on 1/23/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class ConnectionViewCell: UITableViewCell {

    @IBOutlet var localKeyLabel: UILabel!
    @IBOutlet var connectionNameLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
