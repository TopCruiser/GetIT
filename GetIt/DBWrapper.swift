//
//  DBWrapper.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-02-29.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Alamofire
import UIKit
import CoreLocation

class DBWrapper {
    
    static let sharedInstance = DBWrapper()
    static let SERVER_URL = "http://getit.sykhader.com/"
    static let USER_API_URL = SERVER_URL + "user"
    static let CATEGORY_URL = SERVER_URL + "category"
    static let ITEM_URL = SERVER_URL + "item"
    static let AVATAR_URL = SERVER_URL + "avatar"
    static let PAYPAL_REFRESH_TOKEN_URL = SERVER_URL + "paypal"
    static let GET_ITEM_URL = SERVER_URL + "/api/getit"
    static let SELL_ITEM_URL = SERVER_URL + "/api/sellit"
    static let CONVO_URL = SERVER_URL + "/api/convos"
    static let CONFIRM_PAYMENT_URL = SERVER_URL + "/api/payment"
    static let MESSAGE_URL = SERVER_URL + "/api/message"
    static let MARK_READ_URL = SERVER_URL + "/api/read"
    static let WATCH_URL = SERVER_URL + "/api/watch"
    static let RATING_URL = SERVER_URL + "/api/rating"
    
    let fbUserIdConstant = "FB_USER_ID"
    let fbUserAvatarConstant = "FB_USER_AVATAR"
    let fbUsernameConstant = "FB_USER_NAME"
    let userAgeConstant = "USER_AGE"
    let locationConstant = "USER_LOCATION"
    let bioConstant = "USER_BIO"
    let getItUserIdConstant = "GETIT_USER_ID"
    let getItUserAvatarsConstant = "GETIT_AVATARS"
    let hasPaypalInfoConstant = "PAYPAL_PROFILE"
    
    var categories : [Category]
    let category0 = Category(categoryName: "Categories", parentId: 0, id: -1)
    var items : [Item]
    var categoryItems : [CategoryItem]
    var computedUser : User?
    var itemCallables: [()->()] = []
    
    
    class func getInstance() -> DBWrapper.Type{
        return self
    }

    var user : User {
        get {
            if (computedUser != nil) {
                return computedUser!
            } else {
                let prefs = NSUserDefaults.standardUserDefaults()
                
                //let fbAvatarUrl: String?
                let userName: String?
                let userLocation: CLLocation?
                let userBio: String?
                let userId: Int?
                let userAvatars: [UserAvatar]?
                let hasPaypalProfile: Bool?
                
                if prefs.objectForKey(hasPaypalInfoConstant) != nil {
                    hasPaypalProfile = prefs.objectForKey(hasPaypalInfoConstant) as? Bool
                } else {
                    hasPaypalProfile = false
                }

                if (prefs.objectForKey(getItUserAvatarsConstant)) != nil  {
                    let avatarUrls = prefs.objectForKey(getItUserAvatarsConstant) as! [String]
                    userAvatars = avatarUrls.map{ let urlParts = $0.componentsSeparatedByString(",")
                        return UserAvatar(url: urlParts[1], id: Int(urlParts[0])!, user: nil)! }
                } else {
                    userAvatars = []
                }
                if (userAvatars!.filter{ $0.id == -1 }).count == 0 && prefs.objectForKey(fbUserAvatarConstant) != nil {
                    let fburl : String = prefs.objectForKey(fbUserAvatarConstant) as! String!
                    let urlParts = fburl.componentsSeparatedByString(",")
                    userAvatars?.append(UserAvatar(url: urlParts[1], id: -1, user: nil)!)
                }

                
                if prefs.objectForKey(fbUsernameConstant) != nil {
                    userName = prefs.objectForKey(fbUsernameConstant) as? String
                } else{
                    userName = "Guest User"
                }
                
                if let coords = prefs.objectForKey(locationConstant) as?  [Double] {
                    userLocation = CLLocation(latitude: coords[0], longitude: coords[1])
                } else {
                    userLocation = CLLocation.init(latitude: 43.7, longitude: -79.4)
                }
                if let bio = prefs.objectForKey(bioConstant) as? String {
                    userBio = bio
                } else {
                    userBio = ""
                }
                if let id = prefs.objectForKey(getItUserIdConstant) as? Int {
                    userId = id
                } else {
                    userId = -1
                }
                
                computedUser =  User(name: userName!, location: userLocation!,  bio: userBio!, id: userId!, hasPaypalProfile: hasPaypalProfile!, userAvatars: userAvatars!, messageCount: 0, rating: 1.0, ratingCount: 1)!
                return computedUser!
            }

        }
    }
    
    init() {
        categories = [category0]
        items = [ ]
        categoryItems = [ ]
        
        downloadUserProfile()
        
        func onFailure() {
            // display dialog and prevent
            let alert = UIAlertController(title: "Internet Unreachable", message: "Please check the network and try again.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default, handler: { action in
                print("RETRYING NETWORK CONNECTION")
                func os() {}
                self.downloadCategories(os, onFailure: onFailure)
            }))
            UIApplication.sharedApplication().delegate?.window!!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        }
        func os() {}
        downloadCategories(os, onFailure:onFailure)
    }
    

    // MARK: BEGIN NETWORK FUNCTIONALITY
    
    // send facebook ID to server and persist user profile to disk
    func logUserIn(fbUSerId : String, onSuccess:()->(), onFailure:()->()) {

        let userURL = NSURL(string: DBWrapper.USER_API_URL)
        let loginData = JSON(["fb_user_id": fbUSerId])
        Alamofire.request(.POST, userURL!, parameters: loginData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let respJson = JSON(value)
                        print("user JSON: \(respJson)")
                        let userId: Int = respJson["id"].intValue
                        let hasPaypalInfo = respJson["has_paypal_info"].boolValue
                        let avatarUrls : [String] = respJson["avatars"].arrayValue.map { "\($0["id"]),\($0["url"])" }
                        let prefs = NSUserDefaults.standardUserDefaults()
                        prefs.setValue(userId, forKey: self.getItUserIdConstant)
                        prefs.setValue(avatarUrls, forKey: self.getItUserAvatarsConstant)
                        prefs.setValue(hasPaypalInfo, forKey: self.hasPaypalInfoConstant)
                        prefs.synchronize()
                        self.computedUser = nil
                        onSuccess()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }

    }
    
    /*
     * run callable when items are ready
     */
    func onItemsReady(callable: ()->()) {
        if self.items.count > 0 {
            callable()
        } else {
            itemCallables.append(callable)
        }
    }
    
    func downloadCategories(onSuccess:()->(), onFailure: ()->()) {
        do {
            let userURL = NSURL(string: DBWrapper.CATEGORY_URL)
            Alamofire.request(.GET, userURL!)
                .responseJSON { response in
                    debugPrint(response)
                    
                    switch response.result {
                    case .Success:
                        print("status code \(response.response!.statusCode)")
                        if let value = response.result.value {
                            let respJson = JSON(value)
                            self.items = [ ]
                            self.categories = [self.category0]
                            self.categoryItems = []
                            for (key,subJson):(String, JSON) in respJson {
                            //for category : JSON in respJson.arrayValue {
                                let parentId : Int
                                if subJson["parent_id"] != nil {
                                    parentId = subJson["parent_id"].intValue
                                } else {
                                    parentId = -1
                                }
                                let c : Category = Category(categoryName: subJson["name"].stringValue, parentId: parentId,
                                id: subJson["id"].intValue)
                                self.categories.append(c)
                                
                                for (itemKey, itemJson):(String, JSON) in subJson["items"] {
                                    let picUrls : [String] = itemJson["pictures"].arrayValue.map { $0["url"].stringValue }
                                    let i : Item = Item(name: itemJson["name"].stringValue, pics: [], cost: itemJson["cost"].floatValue, user_id: itemJson["user_id"].intValue, description: itemJson["description"].stringValue, type: itemJson["type"].intValue, latitude: itemJson["latitude"].floatValue, longitude: itemJson["longitude"].floatValue,
                                        id: itemJson["id"].intValue, pictureUrls: picUrls,
                                        sellerAvatarUrl: itemJson["seller_avatar"].stringValue,
                                        sellerName: itemJson["seller_name"].stringValue)!
                                    let ci : CategoryItem = CategoryItem(item: i, category: c)
                                    self.items.append(i)
                                    self.categoryItems.append(ci)
                                }
                                
                            }
                            onSuccess()
                            for callable in self.itemCallables {
                                callable()
                            }
                            self.itemCallables = []
                            print("categories JSON: \(respJson)")
                        }
                    case .Failure(let error):
                        if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                            onFailure()
                        }
                    }
            }
        } catch {
            
        }
        
        
    }
    
    func saveUserProperties(data: JSON) {
        do {
            let userURL = NSURL(string: DBWrapper.USER_API_URL + "/" + String(self.user.id))
            Alamofire.request(.PUT, userURL!, parameters: data.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let respJson = JSON(value)
                        print("user JSON: \(respJson)")
                    }
                case .Failure(let error):
                    print(error)
                }
                
                
            }
        } catch {
            
        }
    }

    func saveUserProfile(userJson: JSON) {
        // persist user profile from server
        let prefs = NSUserDefaults.standardUserDefaults()
        //let oldUrls = prefs.objectForKey(self.getItUserAvatarsConstant) as! [String]
        let avatarUrls : [String] = userJson["avatars"].arrayValue.map { "\($0["id"]),\($0["url"])" }
        //var avatars : [UserAvatar] = userJson["avatars"].arrayValue.map { UserAvatar(url: $0["url"].stringValue, id: $0["id"].intValue, user: nil)! }
        /*if oldUrls.count > 0 {
            avatarUrls.append(oldUrls[0])*/
        
        prefs.setValue(avatarUrls, forKey: self.getItUserAvatarsConstant)
        prefs.synchronize()
        self.computedUser = nil

    }
    // if we have a server-assigned user_id then download the latest profile
    func downloadUserProfile() {
        
        if self.user.id > 0 {
            let userURL = NSURL(string: (DBWrapper.USER_API_URL + "/\(self.user.id)"))
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            let request = NSURLRequest(URL: userURL!)
            let dataTask = session.dataTaskWithRequest(request) {
                (let data, let response, let error) in
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch (httpResponse.statusCode) {
                    case 200:
                        let jsonObject = JSON(data: data!)
                        self.saveUserProfile(jsonObject)
                    default:
                        print("ERROR: HTTP status code: \(httpResponse.statusCode)")
                    }
                } else {
                    print("ERROR: not a valid HTTP response")
                }
            }
            print("Fetching \(userURL)")
            dataTask.resume()
        } else {
            print("No user id detected")
        }
    }
    
    
    func viewControllerDownloadUserProfile(userId: Int, onSuccess: (User)->(), onFailure: ()->()) {
        let userProfileURL = NSURL(string: DBWrapper.USER_API_URL + "/\(userId)")
        Alamofire.request(.GET, userProfileURL!)
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .Success:
                    print("status code \(response.response!.statusCode)")
                    if let value = response.result.value {
                        let respJson = JSON(value)
                        let userLocation = CLLocation(latitude: respJson["latutide"].doubleValue, longitude: respJson["longitude"].doubleValue)
                        let avatars : [UserAvatar] = respJson["avatars"].arrayValue.map{ UserAvatar(url: $0["url"].stringValue, id: $0["id"].intValue, user: nil )!}
                        let u = User(name: respJson["name"].stringValue ,location: userLocation, bio: respJson["bio"].stringValue, id: respJson["id"].intValue, hasPaypalProfile: respJson["has_paypal_info"].boolValue, userAvatars: avatars, messageCount: respJson["message_count"].intValue,
                            rating: respJson["rating"].doubleValue, ratingCount: respJson["rating_count"].intValue)
                        onSuccess(u!)
                    } else {
                        onFailure()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }

    }
    
    func itemFromJson(json:JSON) -> Item {
        
        let picUrls : [String] = json["pictures"].arrayValue.map { $0["url"].string! }
        let i : Item = Item(name: json["name"].stringValue, pics: [], cost: json["cost"].floatValue, user_id: json["user_id"].intValue, description: json["description"].stringValue, type: json["type"].intValue, latitude: json["latitude"].floatValue, longitude: json["longitude"].floatValue, id: json["id"].intValue, pictureUrls: picUrls, sellerAvatarUrl: json["seller_avatar"].stringValue,
                            sellerName: json["seller_name"].stringValue)!
        return i

    }
    
    func savePaypalAuthorizationToServer(profileSharingAuthorization: [NSObject : AnyObject], onSuccess: ()->(), onFailure: ()->()) {
        do {
            let paypalData = JSON(["user_id": self.user.id, "code": profileSharingAuthorization["response"]!["code"] as! String ])
            Alamofire.request(.POST, DBWrapper.PAYPAL_REFRESH_TOKEN_URL,
                parameters: paypalData.object as! [String : AnyObject], encoding: .JSON)
                .responseJSON { response in
                    debugPrint(response)
                    print("status code \(response.response!.statusCode)")
                    switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            //let respJson = JSON(value)
                            //print("user JSON: \(respJson)")
                            let prefs = NSUserDefaults.standardUserDefaults()
                            prefs.setValue(true, forKey: self.hasPaypalInfoConstant)
                            prefs.synchronize()
                            self.computedUser = nil
                            onSuccess()
                        }
                    case .Failure(let error):
                        print(error)
                        onFailure()
                    }
            }
        } catch {
            onFailure()
        }
        
    }
    
    func saveItemToServer(i : Item, categories: [Category], onSuccess: () -> (), onFailure: () -> ()){
        
        
        Alamofire.upload(.POST, DBWrapper.ITEM_URL, multipartFormData: { multipartFormData in
            multipartFormData.appendBodyPart(data: i.name.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "name")
            multipartFormData.appendBodyPart(data: "\(i.cost)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "cost")
            multipartFormData.appendBodyPart(data: i.description.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "description")
            multipartFormData.appendBodyPart(data: "\(i.listingType)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "type")
            multipartFormData.appendBodyPart(data: "\(i.user_id)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "user_id")
            multipartFormData.appendBodyPart(data: "\(i.location.coordinate.longitude)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "longitude")
            multipartFormData.appendBodyPart(data: "\(i.location.coordinate.latitude)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "latitude")
            multipartFormData.appendBodyPart(data: "\(categories[0].id)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "category_id")
            for (idx, img) : (Int,UIImage) in i.pics.enumerate() {
                let imgData : NSData = UIImageJPEGRepresentation(img, 0.5)!
                multipartFormData.appendBodyPart(data: imgData, name: "pic\(idx)", fileName: "pic\(idx).jpg", mimeType: "image/jpeg")
            }
            }, encodingCompletion: { encodingResult in
        
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        let rawResp : NSString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)!
                        print(rawResp)
                        if response.response?.statusCode == 200 {
                            if let value = response.result.value {
                                if let json : JSON = JSON(value) {
                                    let serverItem = self.itemFromJson(json)
                                    for c in i.categories {
                                        self.categoryItems.append(CategoryItem(item: serverItem, category: c))
                                    }
                                }
                            }
                            onSuccess()
                        } else {
                            onFailure()
                        }
                 
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                    onFailure()
                }

        })
        
    }
    func deleteItemOnServer(i: Item, onSuccess:()->(), onFailure: ()->()) {
        let itemUrl : String = DBWrapper.ITEM_URL + "/\(i.id)"
        Alamofire.request(.DELETE, itemUrl)
            .responseJSON { response in
                debugPrint(response)
                if let error = response.result.error {
                    print("ERR FAILED HTTP DELETE \(itemUrl)")
                    print(error)
                    onFailure()
                } else {
                    onSuccess()
                }
        }
    }
    func saveAvatar(pickedImage:UIImage, onSuccess:()->(), onFailure:()->()) {
        
        Alamofire.upload(.POST, DBWrapper.AVATAR_URL, multipartFormData: { multipartFormData in
            let imgData : NSData = UIImageJPEGRepresentation(pickedImage, 0.5)!
            multipartFormData.appendBodyPart(data: "\(self.user.id)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "user_id")
                multipartFormData.appendBodyPart(data: imgData, name: "avatar", fileName: "useravatar.jpg", mimeType: "image/jpeg")
            }, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        if let rawResp : NSString = NSString(data: response.data!, encoding: NSUTF8StringEncoding)! {2
                            print(rawResp)
                            if response.response?.statusCode == 200 {
                                self.downloadUserProfile()
                                onSuccess()
                            } else {
                                onFailure()
                            }
                        } else {
                            onFailure()
                        }
                        
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                    onFailure()
                }
                
        })
        
    }
    
    func sendPurchaseIntent(itemId: Int, onSuccess: ()->(), onFailure:()->()) {
            let intentData = JSON(["user_id": self.user.id, "item_id": String(itemId) ])
            Alamofire.request(.POST, DBWrapper.GET_ITEM_URL,
                parameters: intentData.object as! [String : AnyObject], encoding: .JSON)
                .responseJSON { response in
                    debugPrint(response)
                    print("status code \(response.response!.statusCode)")
                    switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            //let respJson = JSON(value)
                            //print("user JSON: \(respJson)")
                            onSuccess()
                        }
                    case .Failure(let error):
                        print(error)
                        onFailure()
                    }
            }
    }
    
    func respondToPurchaseIntent(intentId: Int, decision: Int, onSuccess: ()->(), onFailure: ()->()) {
        let intentData = JSON(["intent_id": intentId, "decision": decision])
        Alamofire.request(.POST, DBWrapper.SELL_ITEM_URL,
            parameters: intentData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        //let respJson = JSON(value)
                        //print("user JSON: \(respJson)")
                        
                        onSuccess()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }
    }
    
    func capturePayment(intentId: Int, paypalId: String, onSuccess: ()->(), onFailure: ()->()) {
        
        let intentData = JSON(["intent_id": intentId, "paypal_id": paypalId])
        Alamofire.request(.POST, DBWrapper.CONFIRM_PAYMENT_URL,
            parameters: intentData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        //let respJson = JSON(value)
                        //print("user JSON: \(respJson)")
                        
                        onSuccess()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }
        
    }
    
    
    
    func getMessages(onSuccess:([Convo])->(), onFailure: ()->()) {
        
        let messagesUrl = NSURL(string: DBWrapper.CONVO_URL + "?user_id=\(self.user.id)")
        Alamofire.request(.GET, messagesUrl!)
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .Success:
                    print("status code \(response.response!.statusCode)")
                    if let value = response.result.value {
                        let respJson = JSON(value)
                        var cs : [Convo] = []
                        for (other_user_id,subJson):(String, JSON) in respJson {
                            //for category : JSON in respJson.arrayValue {
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            
                            let m : [Message] = subJson["m"].arrayValue.map { let d = dateFormatter.dateFromString(($0["timestamp"].stringValue as NSString).substringToIndex(19));
                                return Message(id: $0["id"].intValue, author_id: $0["author_id"].intValue, recipient_id: $0["recipient_id"].intValue, body: $0["body"].stringValue, unread: $0["unread"].intValue, timestamp: d!)!}
                            let uj : JSON = subJson["ou"]
                            let avatars = uj["avatars"].arrayValue.map{ $0["url"].stringValue }
                            var avatar = "";
                            if avatars.count > 0 {
                                avatar = avatars[0]
                            }
                            let c = Convo(userName: uj["name"].stringValue, userId: uj["id"].intValue, intentId: subJson["intent_id"].intValue,
                                intentStatus: subJson["intent_status"].intValue, intentUserId: subJson["intent_user_id"].intValue,
                                itemName: subJson["item_name"].stringValue, itemId: subJson["item_id"].intValue,
                                itemPrice: subJson["item_price"].floatValue, userAvatar: avatar,
                                messages: m)
                            cs.append(c!)
                        }
                        onSuccess(cs)
                        
                        print("categories JSON: \(respJson)")
                    } else{
                        onFailure()
                    }
                case .Failure(let error):
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        onFailure()
                    }
                }
        }
    }
    
    func markMessagesRead(authorId: Int) {
        let msgData = JSON(["recipient_id": self.user.id, "author_id": authorId])
        Alamofire.request(.PATCH, DBWrapper.MARK_READ_URL,
            parameters: msgData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        //onSuccess(c!)
                    } else {
                        //onFailure()
                    }
                case .Failure(let error):
                    print(error)
                    //onFailure()
                }
        }

    }
    
    func toggleWatch(itemWatchId: Int, itemId: Int, onSuccess: (Int)->(), onFailure: ()->()) {
    
        let url : String
        let method : Alamofire.Method
        let payload : JSON
        if itemWatchId > 0 {
            url = DBWrapper.WATCH_URL + "/" + String(itemWatchId)
            method = Alamofire.Method.DELETE
            payload = ["a":"b"]
        } else {
            url = DBWrapper.WATCH_URL
            method = Alamofire.Method.POST
            payload = ["user_id": self.user.id, "item_id": itemId]
        }

        Alamofire.request(method, url, parameters: payload.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("item watch satus code: \(response.response!.statusCode)")
                switch response.result {
                case.Success:
                    if let value = response.result.value {
                        let respItemId : Int
                        if itemWatchId == 0 {
                            let respJson = JSON(value)
                            respItemId = respJson["id"].intValue
                        } else {
                            respItemId = 0
                        }
                        onSuccess(respItemId)
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }
        
    }
    
    func getWatchItems(onSuccess: ([Item])->(), onFailure: () -> ()) {
        
        let messagesUrl = NSURL(string: DBWrapper.WATCH_URL + "?user_id=\(self.user.id)")
        Alamofire.request(.GET, messagesUrl!)
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .Success:
                    print("status code \(response.response!.statusCode)")
                    if let value = response.result.value {
                        
                        let respJson = JSON(value)
                        print("store items JSON: \(respJson)")
                        var items : [Item] = []
                        
                        for j : JSON in respJson.arrayValue {
                            let picUrls = j["pictures"].arrayValue.map { $0["url"].stringValue }
                            let i = Item(name: j["name"].stringValue, pics: [], cost: j["cost"].floatValue, user_id: j["user_id"].intValue, description: j["description"].stringValue, type: j["type"].intValue, latitude: j["latitude"].floatValue, longitude: j["longitude"].floatValue, id: j["id"].intValue, pictureUrls: picUrls,
                                sellerAvatarUrl: j["seller_avatar"].stringValue,
                                sellerName: j["seller_name"].stringValue)
                            items.append(i!)
                        }
                        onSuccess(items)
                    } else{
                        onFailure()
                    }
                case .Failure(let error):
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        onFailure()
                    }
                }
        }

        
    }
    
    func checkItemWatched(itemId: Int, onSuccess: (Int)->()) {
        let messagesUrl = NSURL(string: DBWrapper.WATCH_URL + "?user_id=\(self.user.id)")
        Alamofire.request(.GET, messagesUrl!)
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .Success:
                    print("status code \(response.response!.statusCode)")
                    if let value = response.result.value {
                        
                        let respJson = JSON(value)
                        let items = respJson.arrayValue.filter{ $0["id"].intValue == itemId }
                        let watchId : Int
                        if items.count > 0 {
                            watchId = items[0]["watch_id"].intValue
                        } else {
                            watchId = 0
                        }
                        
                        onSuccess(watchId)
                    }
                case .Failure(let error):
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        print("Get watch status for item \(itemId)")
                    }
                }
        }

    }
    
    func sendMessage(body: String, recipient_id: Int, onSuccess: (Convo)->(), onFailure: ()->()) {
        let msgData = JSON(["body": body, "user_id": self.user.id, "recipient_id": recipient_id])
        Alamofire.request(.POST, DBWrapper.MESSAGE_URL,
            parameters: msgData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let respJson = JSON(value)
                        //print("user JSON: \(respJson)")
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        let m : [Message] = respJson["m"].arrayValue.map { let d = dateFormatter.dateFromString(($0["timestamp"].stringValue as NSString).substringToIndex(19));
                            return Message(id: $0["id"].intValue, author_id: $0["author_id"].intValue, recipient_id: $0["recipient_id"].intValue, body: $0["body"].stringValue, unread: $0["unread"].intValue, timestamp: d!)!}
                        let uj : JSON = respJson["ou"]
                        let avatar = uj["avatars"].arrayValue.map{ $0["url"].stringValue }[0]

                        let c = Convo(userName: uj["name"].stringValue, userId: uj["id"].intValue, intentId: respJson["intent_id"].intValue,
                            intentStatus: respJson["intent_status"].intValue, intentUserId: respJson["intent_user_id"].intValue,
                            itemName: respJson["item_name"].stringValue, itemId: respJson["item_id"].intValue,
                            itemPrice: respJson["item_price"].floatValue, userAvatar: avatar, messages: m)
                        onSuccess(c!)
                    } else {
                        onFailure()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }
        
    }
    
    func rateItem(intentId: Int, rating: Int, onSuccess: ()->(), onFailure: ()->()) {
        
        let intentData = JSON(["intent_id": intentId, "rating": rating, "user_id": self.user.id])
        Alamofire.request(.POST, DBWrapper.RATING_URL,
            parameters: intentData.object as! [String : AnyObject], encoding: .JSON)
            .responseJSON { response in
                debugPrint(response)
                print("status code \(response.response!.statusCode)")
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        //let respJson = JSON(value)
                        //print("user JSON: \(respJson)")
                        
                        onSuccess()
                    }
                case .Failure(let error):
                    print(error)
                    onFailure()
                }
        }
        
    }

    
    func getStoreItems(userId: Int, onSuccess: ([Item])->(), onFailure: ()->()) {
        
        let messagesUrl = NSURL(string: DBWrapper.ITEM_URL + "?seller_id=\(userId)")
        Alamofire.request(.GET, messagesUrl!)
            .responseJSON { response in
                debugPrint(response)
                
                switch response.result {
                case .Success:
                    print("status code \(response.response!.statusCode)")
                    if let value = response.result.value {
                        
                        let respJson = JSON(value)
                        print("store items JSON: \(respJson)")
                        var items : [Item] = []
                        
                        for j : JSON in respJson.arrayValue {
                            let picUrls = j["pictures"].arrayValue.map { $0["url"].stringValue }
                            let i = Item(name: j["name"].stringValue, pics: [], cost: j["cost"].floatValue, user_id: j["user_id"].intValue, description: j["description"].stringValue, type: j["type"].intValue, latitude: j["latitude"].floatValue, longitude: j["longitude"].floatValue, id: j["id"].intValue, pictureUrls: picUrls,
                                sellerAvatarUrl: j["seller_avatar"].stringValue, sellerName: j["seller_name"].stringValue)
                            items.append(i!)
                        }
                        onSuccess(items)
                    } else{
                        onFailure()
                    }
                 case .Failure(let error):
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        onFailure()
                    }
                }
        }

        
    }

    
    // MARK: END NETWORK FUNCTIONALITY

    
    func addItem(i: Item, inCategories categories : [Category]) {
        items = items + [i]
        for c in categories {
            categoryItems.append(CategoryItem(item: i, category: c))
        }
    }
    
    func getRootCategories() -> [Category] {
        return categories.filter{ $0.parentCategoryId == nil || $0.parentCategoryId < 0 }
    }
    
    func getCategoryByName(name: String) -> Category? {
        
        let c : Category?
        
        let searchResults = categories.filter{ $0.name == name }
    
        if searchResults.count > 0{
            c = searchResults[0]
        } else {
            c = nil
        }
        return c
    }
    
    func addUserAvatar(name: String) {
        
    }
}