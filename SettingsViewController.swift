//
//  SettingsViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-06.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit
import FBSDKLoginKit


class SettingsViewController : UIViewController, PayPalProfileSharingDelegate, FBSDKLoginButtonDelegate {
    @IBOutlet weak var connectPaypalButton: UIButton!
    @IBOutlet weak var paypalConnectedText: UIButton!
    @IBOutlet weak var facebookContainer: UIView!
    
    let fbUserIdConstant = "FB_USER_ID"
    let fbUserAvatarConstant = "FB_USER_AVATAR"
    let fbUsernameConstant = "FB_USER_NAME"
    let userAgeConstant = "USER_AGE"
    let locationConstant = "USER_LOCATION"
    let bioConstant = "USER_BIO"
    
    var dbWrapper = DBWrapper.sharedInstance
    var paypalConfig = PayPalConfiguration()
    var environment:String = PayPalEnvironmentSandbox {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnectWithEnvironment(newEnvironment)
            }
        }
    }
    
    @IBAction func triggerPaypalAuth(sender: AnyObject) {
        
        let scopes = [kPayPalOAuth2ScopeOpenId, kPayPalOAuth2ScopeEmail]
        let profileSharingViewController = PayPalProfileSharingViewController(scopeValues: NSSet(array: scopes) as Set<NSObject>, configuration: paypalConfig, delegate: self)
        presentViewController(profileSharingViewController!, animated: true, completion: nil)
        
    }
    func userDidCancelPayPalProfileSharingViewController(profileSharingViewController: PayPalProfileSharingViewController) {
        print("PayPal Profile Sharing Authorization Canceled")
        //successView.hidden = true
        profileSharingViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    func payPalProfileSharingViewController(profileSharingViewController: PayPalProfileSharingViewController, userDidLogInWithAuthorization profileSharingAuthorization: [NSObject : AnyObject]) {
        print("PayPal Profile Sharing Authorization Success!")
        
        // send authorization to your server
        
        profileSharingViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            //self.resultText = profileSharingAuthorization.description
            //self.showSuccess()
            
            let pending = UIAlertController(title: "Saving Paypal Authorization", message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            
            self.presentViewController(pending, animated: true, completion: nil)

            
            func onSuccess() {
                pending.dismissViewControllerAnimated(true, completion: { 
                    
                    
                })
                self.renderPaypalControl()
            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: { 
                    let alert = UIAlertController(title: "Failed To Save Paypal Profile", message: "Please try again soon.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
            
            self.dbWrapper.savePaypalAuthorizationToServer(profileSharingAuthorization, onSuccess: onSuccess, onFailure: onFailure)
        })
        
    }
    override func viewDidAppear(animated: Bool) {
        
        if (dbWrapper.user.id <= 0) {
            let loginButton : FBSDKLoginButton = FBSDKLoginButton()
            loginButton.center = self.view.center
            loginButton.readPermissions = ["public_profile", "email"]//, "user_friends"]
            loginButton.delegate = self
            loginButton.center =  CGPointMake(self.facebookContainer.center.x, 25)
            //loginButton.center = self.facebookContainer.convertPoint(facebookContainer.center, toView: loginButton)
            
            
            self.facebookContainer.addSubview(loginButton)
            
            //self.view.addSubview(loginButton)
        }
        renderPaypalControl()

    }
    
    func renderPaypalControl() {
    
        if dbWrapper.user.id > 0 && !dbWrapper.user.hasPaypalProfile {
            
            connectPaypalButton.hidden = false
            paypalConfig.merchantName = "GetIt"
            paypalConfig.merchantPrivacyPolicyURL = NSURL(string:"http://getit.sykhader.com/privacy")
            paypalConfig.merchantUserAgreementURL = NSURL(string:"http://getit.sykhader.com/user")
            paypalConfig.forceDefaultsInSandbox = true
            paypalConfig.rememberUser = true
            PayPalMobile.preconnectWithEnvironment(environment)
            
        } else if dbWrapper.user.hasPaypalProfile {
            connectPaypalButton.hidden = true
            paypalConnectedText.hidden = false
        } else if dbWrapper.user.id <= 0 {
            connectPaypalButton.hidden = true
            paypalConnectedText.hidden = true
        }
        
    }
    
    
    func getUserProfile() {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me?fields=id,email,name", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
            } else {
                print("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                print("User Name is: \(userName)")
                
                let prefs = NSUserDefaults.standardUserDefaults()
                prefs.setObject(userName, forKey: self.fbUsernameConstant)
                prefs.synchronize()
                let userUpdateJson = JSON(["user_id": self.dbWrapper.user.id, "name": userName])

                self.dbWrapper.saveUserProperties(userUpdateJson)
                self.dbWrapper.computedUser = nil
                //self.renderUserData()
                //let userEmail : NSString = result.valueForKey("email") as! NSString
                //print("User Email is: \(userEmail)")
            }
        })
        let profilePicRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/picture?type=large&redirect=false", parameters: nil)
        
        profilePicRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil) {
                // Process error
                print("Error: \(error)")
            } else {
                print("fetched user: \(result)")
                let retData : AnyObject = result.valueForKey("data")!
                let avatarUrl : NSString = "-1,\(retData.valueForKey("url") as! NSString)"// retData.valueForKey("url") as! NSString
                print("avatar url is: \(avatarUrl)")
                let prefs = NSUserDefaults.standardUserDefaults()
                prefs.setObject(avatarUrl, forKey: self.fbUserAvatarConstant)
                var avatarUrls : [String] = [ ]
                if prefs.objectForKey(self.dbWrapper.getItUserAvatarsConstant) != nil {
                    avatarUrls = prefs.objectForKey(self.dbWrapper.getItUserAvatarsConstant) as! [String]
                }
                
                if (avatarUrls.filter{ $0.componentsSeparatedByString(",")[0] == "-1" }).count == 0 {
                    avatarUrls.append(avatarUrl as String)
                }
                prefs.setValue(avatarUrls, forKey: self.dbWrapper.getItUserAvatarsConstant)
                prefs.synchronize()
                self.dbWrapper.computedUser = nil
            }
        })
    }
    
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        if ((error) != nil){
            // Process error
        } else if result.isCancelled {
            // Handle cancellations
        } else {
            
            func fail() {
                
            }
            func success() {
                getUserProfile();
                backToProfile(self)
            }
            
            let fbUserId : String! = result.token.userID;
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setObject(fbUserId, forKey: fbUserIdConstant)
            prefs.synchronize()
            dbWrapper.logUserIn(fbUserId, onSuccess: success, onFailure: fail)
        }
        
    }
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.removeObjectForKey(fbUserIdConstant)
        prefs.removeObjectForKey(fbUserAvatarConstant)
        prefs.removeObjectForKey(userAgeConstant)
        prefs.removeObjectForKey(bioConstant)
        prefs.removeObjectForKey(fbUsernameConstant)
        prefs.synchronize()
    }

    
    @IBAction func backToProfile(sender: AnyObject) {
  
        
        
        
    dismissViewControllerAnimated(true) { 
        
        
        
        }
        
    }
    
}
