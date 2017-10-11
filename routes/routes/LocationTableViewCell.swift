//
//  LocationTableViewCell.swift
//  LoKey
//
//  Created by Will Steiner on 1/22/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
    
    @IBOutlet var locationNameLabel: UILabel!

    @IBOutlet var locationDistanceFromUser: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    


}
