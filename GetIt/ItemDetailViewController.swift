//
//  ItemDetailViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-03-03.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit

class ItemDetailViewController : UIViewController {
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemNameView: UITextView!
    @IBOutlet weak var itemPriceView: UITextView!
    @IBOutlet weak var listingTypeView: UISegmentedControl!
    @IBOutlet weak var itemDescriptionView: UITextView!
    @IBOutlet weak var purchaseItem: UIButton!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var sellerNameView: UITextView!
    @IBOutlet weak var sellerAvatarView: UIImageView!
    @IBOutlet weak var sellectLocationView: UITextView!
    @IBOutlet weak var sellerLocationLine1View: UITextView!
    @IBOutlet weak var buyItemButton: UITextView!
    
    
    var item : Item?
    var itemWatchId = 0;
    let dbWrapper : DBWrapper = DBWrapper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderItemData()
        setupPurchaseButton()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (itemWatchId == 0) {
            checkItemWatched()
        }
    }
    
    /*
     * - if itemm belongs to logged in user, disable purchase button
     */
    func setupPurchaseButton() {
     
        if item?.user_id == dbWrapper.user.id {
            //purchaseItem.hidden = true
        }
        
    }
    
    func checkItemWatched() {
        
        func onSuccess(watchId: Int) {
            
            itemWatchId = watchId
            
            if watchId > 0 {
                self.watchButton.setTitle("Unwatch", forState: .Normal)
            } else {
                self.watchButton.setTitle("Watch", forState: .Normal)
            }
            self.watchButton.hidden = false
            
        }
        dbWrapper.checkItemWatched(item!.id, onSuccess: onSuccess)
    }
    
    
    func renderItemData() {
        
        //itemImageView.image = item?.pics[0]
        itemImageView.hnk_setImageFromURL(NSURL(string: (item?.pictureUrls[0])!)!)
        sellerAvatarView.hnk_setImageFromURL(NSURL(string: (item?.sellerAvatarUrl)!)!)
        sellerNameView.text = item?.sellerName
        itemNameView.text = item?.name
        let cost = item?.cost
        itemPriceView.text = "\(cost!)"
        itemDescriptionView.text = item?.description
        //listingTypeView.selectedSegmentIndex = (item?.listingType)!
        watchButton.hidden = true
    }
    
    @IBAction func triggerReturnToHome(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        /*if segue.identifier == "itemToConvo" {
            let cv = segue.destinationViewController as! ConvoViewController
            let c = Convo(userName: (item?.sellerName)!, userId: (item?.user_id)!, intentId: -1, intentStatus: -1, intentUserId: self.dbWrapper.user.id, itemName: (item?.name)!, itemId: (item?.id)!, itemPrice: (item?.cost)!, messages: [])
            cv.convo = c
        } else*/
        
        if (segue.identifier == "itemToSellerProfile") {
            
            let userProfileController = segue.destinationViewController as! ProfileViewController
            userProfileController.selectedUserId = (item?.user_id)!
            
        } else if (segue.identifier != "itemToSellerProfile") {
        
            let galleryViewController = segue.destinationViewController as! GalleryViewController
        //galleryViewController.pageImages = (item?.pics)!
            galleryViewController.pageImageUrls = (item?.pictureUrls)!
        }
    }
    
    @IBAction func pictureTapped(sender: AnyObject) {
        
        self.performSegueWithIdentifier("itemDetailToGallery", sender: self)

        
    }
    @IBAction func purchaseButtonTapped(sender: AnyObject) {
        
        var err = ""
        
        if dbWrapper.user.id <= 0 {
            err = "Please login before purchasing an item."
        } else if !dbWrapper.user.hasPaypalProfile {
            err = "Please connect PayPal before making a purchase."
        }
        
        if err.characters.count > 0 {
            let alert = UIAlertController(title: "Sorry", message: err, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            
            let pending = UIAlertController(title: "Sending request to seller.", message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            presentViewController(pending, animated: true, completion: {})
            
            func onSuccess() {
                
                pending.dismissViewControllerAnimated(true, completion: {                 let msg = "The buyer has received your request and should reply shortly."
                    let alert = UIAlertController(title: "Good news.", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    //self.purchaseItem.hidden = true
                    self.buyItemButton.userInteractionEnabled = false
                
                })
                

            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: {
                    let msg = "Unable to process your request, please try again soon"
                    let alert = UIAlertController(title: "Sorry", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)       })

            }
            
            dbWrapper.sendPurchaseIntent(item!.id, onSuccess: onSuccess, onFailure: onFailure)
            
        }
        
    }
    
    @IBAction func toggleWatchItem(sender: AnyObject) {
        
        let watchMessage : String?
        
        if itemWatchId > 0 {
            watchMessage = "Unwatching item..."
        } else {
            watchMessage = "Watchimg item..."
        }
        
        if let _ = watchMessage {
            
            let pending = UIAlertController(title: watchMessage, message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            func onSuccess(newWatchId: Int) {
                pending.dismissViewControllerAnimated(true, completion: {
                    let newTitle : String
                    if self.itemWatchId > 0 {
                        newTitle = "Watch"
                    } else {
                        newTitle = "Unwatch"
                    }
                    self.watchButton.setTitle(newTitle, forState: .Normal)
                    self.itemWatchId = newWatchId
                })
            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: {
                    let msg = "Couldn't watch item, please retry soon."
                    let alert = UIAlertController(title: "Sorry", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
            presentViewController(pending, animated: true, completion: {

                self.dbWrapper.toggleWatch(self.itemWatchId, itemId: self.item!.id, onSuccess: onSuccess, onFailure: onFailure)
            
            })

            
          
        }
     
        
    }
    
    @IBAction func sendUserMessage(sender: AnyObject) {
        
        if dbWrapper.user.id <= 0 || dbWrapper.user.id == item?.user_id {
            return
        }
        
        //performSegueWithIdentifier("itemToConvo", sender: self)
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
                self.dbWrapper.sendMessage(msg!, recipient_id: (self.item?.user_id)!, onSuccess: onSuccess, onFailure: onFailure)
            }
        }))
        passwordPrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Write your message here"
            inputTextField = textField
        })
        
        presentViewController(passwordPrompt, animated: true, completion: nil)
    }
    
    
    @IBAction func sellerInfoTapped(sender: AnyObject) {
        
        self.performSegueWithIdentifier("itemToSellerProfile", sender: self)

        
    }
    
}