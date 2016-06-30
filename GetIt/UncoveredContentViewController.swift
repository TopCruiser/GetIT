//
//  UncoveredContentViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-02-29.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit

class UncoveredContentViewController: UIViewController {
    var activeField: UIView?
    var changedY = false
    var keyboardHeight: CGFloat = 300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
    }
    
    func keyboardWillShow(sender: NSNotification) {
        let kbSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        
        keyboardHeight = kbSize!.height
        var aRect = self.view.frame;
        aRect.size.height = aRect.size.height - kbSize!.height - CGFloat(20);
        
        if activeField != nil  { //&& !CGRectContainsPoint(aRect, activeField!.frame.origin) {
            if (!changedY) {
                self.view.frame.origin.y -= keyboardHeight
            }
            changedY = true
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        if changedY {
            self.view.frame.origin.y += keyboardHeight
        }
        changedY = false
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    @IBAction func textFieldEditingDidBegin(sender: UITextField){
        //println("did begin")
        activeField = sender
    }
    
    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        //println("did end")
        activeField = nil
    }
    
     func textFieldShouldReturn(tf: UITextField!) -> Bool {
        tf.resignFirstResponder()
        return true;
    }
}