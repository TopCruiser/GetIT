//
//  UserAvatar.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-04.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation

struct UserAvatar {
    
    let user: User?
    let url: String
    let id: Int
    
    init?(url: String, id: Int, user: User?) {
        self.user = user
        self.url = url
        self.id = id
    }

    
}