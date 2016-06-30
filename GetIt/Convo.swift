//
//  Convo.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-25.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation


struct Convo {
    
    let userAvatar : String
    let userName : String // other user's name
    let userId : Int // other user's id
    let messages: [Message] // ordered list of messages
    let intentId: Int
    let intentStatus: Int
    let intentUserId: Int
    let itemName: String
    let itemId: Int
    let itemPrice: Float
    
    init?(userName: String, userId: Int, intentId: Int, intentStatus: Int, intentUserId: Int, itemName: String,
          itemId: Int, itemPrice: Float, userAvatar: String, messages: [Message]) {
        self.userName = userName
        self.userId = userId
        self.messages = messages
        self.intentId = intentId
        self.intentStatus = intentStatus
        self.intentUserId = intentUserId
        self.itemPrice = itemPrice
        self.itemId = itemId
        self.itemName = itemName
        self.userAvatar = userAvatar
    }
    
    
    
}