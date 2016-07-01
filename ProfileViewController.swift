//
//  ProfileViewController.swift
//  GetIt
//
//  Created by a on 2016-02-17.
//  Copyright © 2016 GetIt. All rights reserved.
//

import CoreLocation
import UIKit
import Haneke

class ProfileViewController: UncoveredContentViewController, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var ageView: UITextField!
    @IBOutlet weak var locationView: UITextView!
    @IBOutlet weak var nameView: UITextView!
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bioView: UITextView!
    @IBOutlet weak var settingsButton: UIImageView!
    @IBOutlet weak var messagesButton: UIImageView!
    @IBOutlet weak var messagesBar: UIView!
    @IBOutlet weak var newMessageIndicator: UIView!
    @IBOutlet weak var getitIconView: UIImageView!
    @IBOutlet weak var backButton: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingLine: UITextView!
    @IBOutlet weak var shopButton: UIImageView!
    @IBOutlet weak var cartButton: UIImageView!
    @IBOutlet weak var shoppingCartText: UITextView!
    @IBOutlet weak var myShopText: UITextView!
    
    @IBOutlet weak var messageCountView: UITextField!
    
    var dbWrapper = DBWrapper.sharedInstance
    weak var agePicker : UIPickerView!
    let imagePicker = UIImagePickerController()
    var selectedUserId: Int = -1
    var selectedUser : User?
    
    let fbUserIdConstant = "FB_USER_ID"
    let fbUserAvatarConstant = "FB_USER_AVATAR"
    let fbUsernameConstant = "FB_USER_NAME"
    let userAgeConstant = "USER_AGE"
    let locationConstant = "USER_LOCATION"
    let bioConstant = "USER_BIO"
    let BIO_PLACEHOLDER = "Please enter a short description"
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedUserId <= 0 {
            imagePicker.delegate = self
            renderUserData(dbWrapper.user)
            renderAge();
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        //renderUserData()
        if selectedUserId > 0 {
            backButton.hidden = false
            getitIconView.hidden = true
            nameView.userInteractionEnabled = false
            bioView.userInteractionEnabled = false
            settingsButton.hidden = true
            //messagesBar.hidden = true
            //shopButton.hidden = true
            cartButton.hidden = true
            shoppingCartText.hidden = true
        } else {
            backButton.hidden = true
            backButton.userInteractionEnabled = true
            getitIconView.hidden = false
            settingsButton.hidden = false
            nameView.userInteractionEnabled = true
            bioView.userInteractionEnabled = true
            settingsButton.hidden = false
            //messagesBar.hidden = false
            cartButton.hidden = false
            shoppingCartText.hidden = false
            //shopButton.hidden = false
        }

        downloadUserProfile()
        //avatarView.layer.borderWidth = 1
        //avatarView.layer.masksToBounds = false
        
        
        newMessageIndicator.layer.masksToBounds = false
        newMessageIndicator.layer.borderColor = UIColor.blackColor().CGColor
        newMessageIndicator.layer.cornerRadius = newMessageIndicator.frame.height/2
        newMessageIndicator.clipsToBounds = true
        
        bioView.delegate = self
        
    
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }

    override func viewDidLayoutSubviews() {
        //let screenBounds = UIScreen.mainScreen().bounds.width
       // locationIcon.center = CGPointMake(screenBounds - 20, locationIcon.center.y)
        //locationActivityIndicator.center = CGPointMake(screenBounds - 50, locationActivityIndicator.center.y)
        locationActivityIndicator.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    func downloadUserProfile() {
        
        var userId = selectedUserId
        if selectedUserId <= 0 {
            userId = dbWrapper.user.id
        }
        
        if userId > 0 {
            func onSuccess(user: User) {
                selectedUser = user
                renderUserData(user)
                if user.messageCount > 0 && userId == self.dbWrapper.user.id {
                    newMessageIndicator.hidden = false
                } else {
                    //newMessageIndicator.hidden = true
                    //messageCountView.hidden = true
                }
            }
            func onFailure() {
                
            }
            dbWrapper.viewControllerDownloadUserProfile(userId, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func renderUserData(user: User) {
        renderAvatarImage(user)
        renderProfileData(user)
    }
    
    func donePicker() {
        let newAge = 18 + agePicker.selectedRowInComponent(0)
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(newAge, forKey: userAgeConstant)
        prefs.synchronize()
        ageView.text = String(18+agePicker.selectedRowInComponent(0))
        ageView.resignFirstResponder()
    }
    
    func cancel() {
        ageView.resignFirstResponder()
    }
    
    /*
     * if we have an age render it, and select picker
     */
    func renderAge() {
        let locationTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.locationControl(_:)))
        locationTapRecognizer.numberOfTapsRequired = 1
        locationIcon.userInteractionEnabled = true
        locationIcon.addGestureRecognizer(locationTapRecognizer)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ProfileViewController.donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ProfileViewController.donePicker))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.userInteractionEnabled = true
        
        let pickerView = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        pickerView.backgroundColor = .whiteColor()
        pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        agePicker = pickerView
        //ageView.inputView = pickerView
        //ageView.inputAccessoryView = toolBar
        
    }
    @IBAction func backToItem(sender: AnyObject) {
        dismissViewControllerAnimated(true) { 
            
            self.selectedUserId = -1

        }
    }
    @IBAction func triggerSettingssSegue(sender: AnyObject) {
        performSegueWithIdentifier("profileToSettings", sender: self)
        
    }
    @IBAction func triggerStoreSegue(sender: AnyObject) {
        performSegueWithIdentifier("profileToStore", sender: self)
    }
    @IBAction func triggerBasketSegue(sender: AnyObject) {
        performSegueWithIdentifier("profileToBasket", sender: self)

    }
    
    
    
    func locationControl(sender:UITapGestureRecognizer) {
        print("location control")
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationActivityIndicator.hidden = false
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        let geoCoder = CLGeocoder()
        
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject([manager.location!.coordinate.latitude, manager.location!.coordinate.longitude], forKey: self.locationConstant)
        prefs.synchronize()
        
        geoCoder.reverseGeocodeLocation(manager.location!) { (placemarks, error) -> Void in
            
            var placemark: CLPlacemark!
            placemark = placemarks?[0]
            print("locations = \(locValue.latitude) \(locValue.longitude)")
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
            self.locationView.text = locationString
            print("location string: \(locationString)")

        }
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
        locationActivityIndicator.stopAnimating()
    }
    
    func renderAvatarImage(u: User?) {
        avatarView.contentMode = .ScaleAspectFill
        let avatarUser: User?
        
        if u != nil && u?.avatars.count > 0 {
            avatarUser = u
        } else if dbWrapper.user.avatars.count > 0 {
            avatarUser = dbWrapper.user
        } else {
            avatarUser = nil
        }
        
        if avatarUser != nil {
            func onSuccess(img: UIImage) {
                self.avatarView.image = cropToBounds(img, width: Double(self.avatarView.frame.height), height: Double(self.avatarView.frame.height))
                avatarView.layer.masksToBounds = false
                avatarView.layer.borderColor = UIColor.blackColor().CGColor
                avatarView.layer.cornerRadius = avatarView.frame.height/2
                avatarView.clipsToBounds = true
            }

            avatarView.hnk_setImageFromURL(NSURL(string:avatarUser!.avatars[0].url)!, success: onSuccess)
        }
        
    }
    
    
    func renderProfileData(u:User?) {
        
        let renderUser : User

        
        if u != nil {
            renderUser = u!
        } else {
            renderUser = dbWrapper.user
        }
        
        let shopTitle : String
        if renderUser.id == dbWrapper.user.id {
            shopTitle = "My Shop"
        } else {
            shopTitle = "\(renderUser.name)'s Shop"
        }
        myShopText.text = shopTitle
        
        nameView.text = renderUser.name
        renderUser.renderLocationText(locationView)
        
        let bio = renderUser.bio
        
        if bio.characters.count > 0 {
            bioView.text = dbWrapper.user.bio
            
        } else {
            bioView.text = "Please enter a short bio"
        }
        
        let rating  = renderUser.rating,
            ratingCount = renderUser.ratingCount
        
        let ratingLine = "Rating \(Int(rating*100))% (\(ratingCount) Voted)"
        
        self.ratingLine.text = ratingLine
        self.ratingView.rating = round(rating*5)
        
        
        
    }
    
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 82
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(18 + row);
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //ageView.text = String(18+row);
    }
    
    func animateTextField(textView: UITextView, up: Bool) {
        let d = 160
        let dur = 0.3
        
        let movement : CGFloat = CGFloat(up ? -d : d)
        
        UIView.beginAnimations("anim", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(dur)
        self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        UIView.commitAnimations()
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        let prefs = NSUserDefaults.standardUserDefaults()

        animateTextField(textView, up: true)
        
        if let _ = prefs.objectForKey(bioConstant) as? String {
            
        } else {
            textView.text = ""
        }
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        animateTextField(textView, up: false)
        
        switch textView {
        case bioView:
            print(1)
            // something
        default:
            print(2)
            // no-op break
        }
        
        if textView.text.characters.count > 0 {
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setObject(textView.text, forKey: bioConstant)
            prefs.synchronize()
        }
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "profileToGallery" {
            let galleryViewController = segue.destinationViewController as! GalleryViewController
            galleryViewController.pageImageUrls = dbWrapper.user.avatars.map{ $0.url }
        } else if segue.identifier == "profileToStore" {
            let store  = segue.destinationViewController as! StoreViewController
            var userId = dbWrapper.user.id
            if selectedUserId > 0 {
                userId = selectedUserId
            }
            store.user = selectedUser
        }
    }
    
    
    @IBAction func triggerGallerySegue(sender: AnyObject) {
        
        let actionMenu = UIAlertController(title: nil, message: "Do you want to...", preferredStyle: .ActionSheet)
        let galleryAction = UIAlertAction(title: "View Gallery", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
                self.performSegueWithIdentifier("profileToGallery", sender: self)
            })
        let newPictureAction = UIAlertAction(title: "Add avatar", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true) { () -> Void in
                
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        actionMenu.addAction(galleryAction)
        actionMenu.addAction(newPictureAction)
        actionMenu.addAction(cancelAction)
        
        self.presentViewController(actionMenu, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let pending = UIAlertController(title: "Saving Listing", message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            

            func onSuccess() {
                pending.dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Success", message: "Your avatar has been uploaded.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                //avatarView.image = pickedImage
            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Bruh", message: "Server error, please try again soon.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                //pending.dismissViewControllerAnimated(<#T##flag: Bool##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
            }
            presentViewController(pending, animated: true, completion: {
            })
            dbWrapper.saveAvatar(pickedImage, onSuccess: onSuccess, onFailure: onFailure)

            //dbWrapper.addUserAvatar(pickedImage)
        }
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    @IBAction func triggerMessagesSegue(sender: AnyObject) {
        
        if selectedUserId <= 0 && dbWrapper.user.id > 0 {
        
            performSegueWithIdentifier("profileToMessages", sender: self)
        
        } else {
            
            if dbWrapper.user.id <= 0 || dbWrapper.user.id == selectedUserId {
                return
            }
            
            var inputTextField: UITextField?
            let passwordPrompt = UIAlertController(title: "Direct Message", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            passwordPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            passwordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Now do whatever you want with inputTextField (remember to unwrap the optional)
                let pending = UIAlertController(title: "Sending...", message: nil, preferredStyle: .Alert)
                
                //create an activity indicator
                let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
                indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                
                //add the activity indicator as a subview of the alert controller's view
                pending.view.addSubview(indicator)
                indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
                indicator.startAnimating()
                self.presentViewController(pending, animated: true, completion: {
                    
                })
                
                func onSuccess(c: Convo) {
                    let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
                    dispatch_after(time, dispatch_get_main_queue()) {
                        //put your code which should be executed with a delay here
                        pending.dismissViewControllerAnimated(true) {
                            // get max created_on of the present messages and add any newer ones
                        }
                    }
                    pending.title = "Sent!"
                    
                    
                }
                
                func onFailure() {
                    
                    pending.dismissViewControllerAnimated(true) {
                        let msg = "Couldn't send message, lease try again soon."
                        let alert = UIAlertController(title: "Sorry", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                let msg = inputTextField?.text
                if msg?.characters.count > 0 {
                    self.dbWrapper.sendMessage(msg!, recipient_id: self.selectedUserId, onSuccess: onSuccess, onFailure: onFailure)
                }
            }))
            passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "Write your message here"
                inputTextField = textField
            })
            
            presentViewController(passwordPrompt, animated: true, completion: nil)

            
        }
        
    }
    
}