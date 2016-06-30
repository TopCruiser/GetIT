//
//  ViewController.swift
//  GetIt
//
//  Created by a on 2016-02-08.
//  Copyright © 2016 GetIt. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit


class ViewController: UIViewController,FBSDKLoginButtonDelegate {
    
    @IBOutlet var titleView : UITextView!
    
    let fbUserIdConstant = "FB_USER_ID"
    let fbUserAvatarConstant = "FB_USER_AVATAR"
    let fbUsernameConstant = "FB_USER_NAME"

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        let prefs = NSUserDefaults.standardUserDefaults()
        if let _ = prefs.stringForKey(fbUserIdConstant) {
            
            presentExploreView();
            
        }  else {
            
            
            let loginButton : FBSDKLoginButton = FBSDKLoginButton()
            loginButton.center = self.view.center
            loginButton.readPermissions = ["public_profile", "email"]//, "user_friends"]
            loginButton.delegate = self
            self.view.addSubview(loginButton)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     * segue to explore view
     */
    func presentExploreView() {
        print("Presenting Explore View");
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        performSegueWithIdentifier("presentExploreView", sender: nil)
    }
    
    func getUserProfile() {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
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
                let avatarUrl : NSString = retData.valueForKey("url") as! NSString
                print("avatar url is: \(avatarUrl)")
                let prefs = NSUserDefaults.standardUserDefaults()
                prefs.setObject(avatarUrl, forKey: self.fbUserAvatarConstant)
                prefs.synchronize()
            }
        })
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil){
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            let fbUserId : String! = result.token.userID;
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setObject(fbUserId, forKey: fbUserIdConstant)
            prefs.synchronize()
            getUserProfile();
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
           // if result.grantedPermissions.contains("email")
            //{
                // Do work
            //}
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
        //self.navigationController?.popViewControllerAnimated(true)
        //self.navigationController?.popViewControllerAnimated(true)
        // TODO: Clear local user data and go back to login view
    }


}

