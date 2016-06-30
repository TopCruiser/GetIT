//
//  MessagesViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-04-25.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit

class MessagesViewController : UIViewController , UITableViewDataSource, UITableViewDelegate {
    
    var dbWrapper = DBWrapper.sharedInstance
    var convos : [Convo] = [ ]{
        didSet {
            messagesTable.reloadData()
        }
    }

    var pendingIntendId: Int = 0
    var selectedConvo: Convo?
    
    @IBOutlet weak var messagesTable: UITableView!

    
    override func viewDidLoad() {
        
        
        
        messagesTable.delegate = self
        messagesTable.dataSource = self
        self.messagesTable.separatorColor = UIColor.clearColor()

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (dbWrapper.user.id > 0 ) {
        
            let pending = UIAlertController(title: "Getting Messages", message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            func onSuccess(convos:[Convo]) {
                pending.dismissViewControllerAnimated(true, completion: nil)
                self.convos = convos
            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: nil)
                
            }
            presentViewController(pending, animated: true, completion: {
                 self.dbWrapper.getMessages(onSuccess, onFailure: onFailure)
            })
        }
    }

    
    @IBAction func backToProfile(sender: AnyObject) {
        
        dismissViewControllerAnimated(true) {
            
            
        }
    }
    
    /*func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        
        let index = indexPath.row
        //var height : CGFloat?
        let height : CGFloat
        
        if activeCategoryParent != nil && index > activeSubcategories?.count {
            height = 90
        } else {
            height = 40
        }
        
        return height
    }*/
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell
        
        let convo = convos[indexPath.row]
        let messageCell = tableView.dequeueReusableCellWithIdentifier("messageCellView", forIndexPath: indexPath) as! MessageCellView
        
        messageCell.renderData(convo)
        
        return messageCell
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return convos.count
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "messagesToConvo" {
            let cv = segue.destinationViewController as! ConvoViewController
            cv.convo = selectedConvo
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let convo = convos[indexPath.row]
        selectedConvo = convo
        performSegueWithIdentifier("messagesToConvo", sender: self)

        
        /*
        let intentId = convo.intentId;
        let intentStatus = convo.intentStatus
        let itemName = convo.itemName,
            itemPrice = convo.itemPrice,
        itemId = convo.itemId;
        
        if intentStatus == 0 && convo.intentUserId != dbWrapper.user.id {
        
            let actionMenu = UIAlertController(title: nil, message: "Do you want to...", preferredStyle: .ActionSheet)
            let acceptAction = UIAlertAction(title: "Accept Offer", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.respondToIntent(intentId, decision: 1)
            })
            let declineAction = UIAlertAction(title: "Decline Offer", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.respondToIntent(intentId, decision: -1)
            })
            let replyAction = UIAlertAction(title: "Send Message Reply", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            actionMenu.addAction(acceptAction)
            actionMenu.addAction(declineAction)
            actionMenu.addAction(replyAction)
            
            self.presentViewController(actionMenu, animated: true, completion: nil)

        } else if intentStatus == 1 {
            
            let itemCost = NSDecimalNumber(float: itemPrice).decimalNumberByRoundingAccordingToBehavior( NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundUp, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            
            let item1 = PayPalItem(name: itemName, withQuantity: 1, withPrice: itemCost, withCurrency: "USD", withSku: String(itemId))

            let items = [item1]
            let subtotal = PayPalItem.totalPriceForItems(items)
            
            // Optional: include payment details
            let shipping = NSDecimalNumber(string: "0.00")
            let tax = NSDecimalNumber(string: "0.00")
            let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
            let total = subtotal.decimalNumberByAdding(shipping)
                                .decimalNumberByAdding(tax)
                                .decimalNumberByRoundingAccordingToBehavior( NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundUp, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            
            let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: itemName, intent: .Sale)
            
            payment.items = items
            payment.paymentDetails = paymentDetails
            
            if (payment.processable) {
                pendingIntendId = intentId
                let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
                presentViewController(paymentViewController!, animated: true, completion: nil)
            } else {
                // This particular payment will always be processable. If, for
                // example, the amount was negative or the shortDescription was
                // empty, this payment wouldn't be processable, and you'd want
                // to handle that here.
                print("Payment not processalbe: \(payment)")
            }
        }*/
    }
    
   

    
}