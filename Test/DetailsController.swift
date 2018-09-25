//
//  ViewController.swift
//  Test
//
//  Created by Claudio Vega on 9/11/18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import UIKit

class DetailsController: UIViewController {
    var laptop: LaptopModel?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = laptop?.title
        titleLabel.text = laptop?.title
        descriptionLabel.text = laptop?.description
        guard let imageURL = laptop?.imageURL else { return }
        imageView.image = AssetsClient.shared.image(dataForURL: imageURL)
        if imageView.image != nil { return }
        AssetsClient.shared.fetch(URL: imageURL, completionHandler: {
            (data: Data?) in
            if let data = data, let image = UIImage(data: data) {
                self.imageView.image = image
            }
        })
    }
}

