//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Chase on 27/01/2019.
//  Copyright © 2019 s0w4. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static let identifier = "PhotoCell"
    var imageUrl: String = ""
}
