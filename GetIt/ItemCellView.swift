//
//  ItemCellView.swift
//  GetIt
//
//  Created by a on 2016-02-15.
//  Copyright © 2016 GetIt. All rights reserved.
//

import UIKit
import CoreLocation


class ItemCellView: UITableViewCell {
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemNameView: UITextView!    
    @IBOutlet weak var costView: UITextView!
    @IBOutlet weak var distanceView: UITextView!
    @IBOutlet weak var userAvatarView: UIImageView!
    
    @IBOutlet weak var userNameView: UITextView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        itemImageView.userInteractionEnabled = false
        itemNameView.userInteractionEnabled = false
        itemNameView.scrollEnabled = false
        costView.scrollEnabled = false
        costView.userInteractionEnabled = false
        //costView.textColor = UIColor(colorLiteralRed: 43/255, green: 249/255, blue: 61/255, alpha: 1)
        distanceView.scrollEnabled = false
        distanceView.editable = false
    }
    
    func renderItemData(item: Item, userLocation: CLLocation) {
        //self.itemImageView.image = item.pics[0]
        self.itemImageView.hnk_setImageFromURL(NSURL(string:item.pictureUrls[0])!)
        self.itemNameView.text = item.name
        self.costView.text = "$\(item.cost)"
        self.distanceView?.text = item.distanceString(fromLocation: userLocation)
        self.userAvatarView.hnk_setImageFromURL(NSURL(string:item.sellerAvatarUrl)!)
        self.userNameView.text = item.sellerName
    }
}
