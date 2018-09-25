//
//  LaptopTableViewCell.swift
//  Test
//
//  Created by Claudio Vega on 15-09-18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import UIKit

class LaptopTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var thumbImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil 
    }
}
