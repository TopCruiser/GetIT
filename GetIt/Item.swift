//
//  Item.swift
//  GetIt
//
//  Created by a on 2016-02-15.
//  Copyright © 2016 GetIt. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

struct Item {
    
    static let rentType = 0
    static let saleType = 1
    static let bothType = 2
        
    let name: String
    //let user: User
    let user_id: Int
    let cost: float_t;
    let pics: [UIImage]
    let description: String
    let categories: [Category] = [ ]
    let listingType: Int // 0 = rent, 1 = sale, 2 = both
    let location: CLLocation //
    let id: Int
    let pictureUrls: [String]
    let sellerAvatarUrl: String
    let sellerName: String
    
    init?(name: String, pics: [UIImage], cost: float_t, user_id: Int, description: String, type: Int, latitude: Float, longitude: Float, id: Int,
          pictureUrls: [String], sellerAvatarUrl: String, sellerName: String) {
        self.name = name
        self.pics = pics
        self.cost = cost
        self.user_id = user_id
        self.description = description
        self.listingType = type
        self.location = CLLocation(latitude:  CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        self.id = id
        self.pictureUrls = pictureUrls
        self.sellerAvatarUrl = sellerAvatarUrl
        self.sellerName = sellerName
    }
    
    func distanceString(fromLocation location: CLLocation) -> String {
        print("distance(\(self.location.coordinate), \(location.coordinate))")
        let distance = self.location.distanceFromLocation(location)
        if distance > 1000  {
            let kmRounded = String(format: "%.1f", distance/1000.0)
            return "\(kmRounded) km away"
        } else {
            return "< 1km"
        }
    }
    
}