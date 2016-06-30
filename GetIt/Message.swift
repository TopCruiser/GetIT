//
//  Message.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-25.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation

struct Message {
    let author_id: Int
    let recipient_id: Int
    let body: String
    let unread: Int
    let timestamp: NSDate
    let id: Int
    init?(id: Int, author_id: Int, recipient_id: Int, body: String, unread: Int, timestamp: NSDate) {
        self.author_id = author_id
        self.recipient_id = recipient_id
        self.body = body
        self.unread = unread
        self.timestamp = timestamp
        self.id = id
    }
}