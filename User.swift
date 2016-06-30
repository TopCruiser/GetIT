//
//  User.swift
//  GetIt
//
//  Created by a on 2016-02-15.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

struct User {
    
    let name: String
    let avatars: [UserAvatar]
    let location: CLLocation
    let bio: String
    let id: Int
    let hasPaypalProfile: Bool
    let messageCount: Int
    let rating : Double
    let ratingCount: Int

    
    init?(name: String, location: CLLocation, bio: String, id: Int, hasPaypalProfile: Bool, userAvatars: [UserAvatar], messageCount: Int, rating: Double, ratingCount: Int) {
        self.name = name
        self.location = location
        self.avatars = userAvatars
        self.bio = bio
        self.id = id
        self.hasPaypalProfile = hasPaypalProfile
        self.messageCount = messageCount
        self.rating = rating
        self.ratingCount = ratingCount
    }
    
    
    func renderLocationText(view: UITextView) -> Void {
        //let locValue:CLLocationCoordinate2D = location.coordinate
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
            
            var placemark: CLPlacemark!
            placemark = placemarks?[0]
            //print("locations = \(locValue.latitude) \(locValue.longitude)")
            var locationString = ""
            if let city = placemark.addressDictionary!["City"] as? String {
                locationString += city + " "
            }
            if let state = placemark.addressDictionary!["State"] as? String {
                locationString += state + ", "
            }
            if let country = placemark.addressDictionary!["Country"] as? String {
                locationString += country
            }
            view.text = locationString
            print("location string: \(locationString)")
        }
    }
    
    
}