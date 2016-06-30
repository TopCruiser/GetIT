//
//  MessageCellView.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-25.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit

class MessageCellView: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UITextView!
    @IBOutlet weak var messageText: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userName.editable = false;
        messageText.selectable = false
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderData(convo: Convo) {
        userName.text = convo.userName
        messageText.text = convo.messages[0].body
        userImage.hnk_setImageFromURL(NSURL(string:convo.userAvatar)!)
    }

}