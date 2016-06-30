//
//  ConvoViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-05-05.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit


class ConvoViewController : UIViewController, LGChatControllerDelegate, PayPalPaymentDelegate  {
    
    var convo : Convo?
    var dbWrapper = DBWrapper.sharedInstance
    @IBOutlet weak var offerButton: UIButton!
    @IBOutlet weak var backButton: UIButton!

    @IBOutlet weak var containerView: UIView!
    
    var acceptCreditCards: Bool = true {
        didSet {
            payPalConfig.acceptCreditCards = acceptCreditCards
        }
    }
    var environment:String = PayPalEnvironmentNoNetwork {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnectWithEnvironment(newEnvironment)
            }
        }
    }
    var payPalConfig = PayPalConfiguration() // default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        payPalConfig.acceptCreditCards = acceptCreditCards;
        payPalConfig.merchantName = "GetIt Inc."
        payPalConfig.merchantPrivacyPolicyURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
        payPalConfig.languageOrLocale = NSLocale.preferredLanguages()[0]
        payPalConfig.payPalShippingAddressOption = .PayPal;
        
        dbWrapper.markMessagesRead((convo?.userId)!)
        
        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        PayPalMobile.preconnectWithEnvironment(environment)
        setupOfferButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        launchChatController()
    }
    
    
    func respondToIntent(intentId: Int, decision: Int) {
        
        let pending = UIAlertController(title: "Sending Reply To The Buyer", message: nil, preferredStyle: .Alert)
        
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
        indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        pending.view.addSubview(indicator)
        indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        presentViewController(pending, animated: true, completion: {
            
        })
        
        
        func onSuccess() {
            pending.dismissViewControllerAnimated(true, completion: nil)
        }
        func onFailure() {
            pending.dismissViewControllerAnimated(true, completion: nil)
            
        }
        
        dbWrapper.respondToPurchaseIntent(intentId, decision: decision, onSuccess: onSuccess, onFailure: onFailure)
    }

    func setupOfferButton() {
        
        let intentStatus = convo?.intentStatus
        
        var intentText = ""
        
        if intentStatus == 0 && convo?.intentUserId != dbWrapper.user.id {
            
            intentText = "Respond To Offer"
        
        } else if intentStatus == 1 {
            
            intentText = "Make Payment"
        
        } else if intentStatus == 3 && convo?.intentUserId != dbWrapper.user.id {
            intentText = "Rate Seller"
        }
        
        if intentText.characters.count > 0 {
            offerButton.setTitle(intentText, forState: .Normal)
            offerButton.hidden = false
        } else {
            offerButton.hidden = true
        }
        //backButton.hidden = false
    }
    
    func rateSeller(rating: Int) {
        
        
        let pending = UIAlertController(title: "Saving Your Rating...", message: nil, preferredStyle: .Alert)
        
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
        indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        pending.view.addSubview(indicator)
        indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        presentViewController(pending, animated: true, completion: {
            
        })
        
        
        func onSuccess() {
            pending.dismissViewControllerAnimated(true, completion: nil)
            self.offerButton.hidden = true
        }
        func onFailure() {
            pending.dismissViewControllerAnimated(true, completion: {
                let msg = "Couldn't save rating. Try again soon."
                let alert = UIAlertController(title: "Sorry", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)

            })
            
        }
        
        dbWrapper.rateItem((self.convo?.intentId)!, rating: rating, onSuccess: onSuccess, onFailure: onFailure)
        
    }
    
    @IBAction func handleOfferAction(sender: AnyObject) {
        
        if convo!.intentStatus == 0 && convo?.intentUserId != dbWrapper.user.id {
            
            
            let actionMenu = UIAlertController(title: nil, message: "Do you want to...", preferredStyle: .ActionSheet)
            let acceptAction = UIAlertAction(title: "Accept Offer", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.respondToIntent((self.convo?.intentId)!, decision: 1)
            })
            let declineAction = UIAlertAction(title: "Decline Offer", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.respondToIntent((self.convo?.intentId)!, decision: -1)
            })
            /*let replyAction = UIAlertAction(title: "Send Message Reply", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
            })*/
            
            actionMenu.addAction(acceptAction)
            actionMenu.addAction(declineAction)
            //actionMenu.addAction(replyAction)
            
            self.presentViewController(actionMenu, animated: true, completion: nil)
        } else if convo?.intentStatus == 1 {
            
            let intentStatus = convo?.intentStatus
            let itemName = convo?.itemName,
            itemPrice = convo?.itemPrice,
            itemId = convo?.itemId
            
            let itemCost = NSDecimalNumber(float: itemPrice!).decimalNumberByRoundingAccordingToBehavior( NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundUp, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            
            let item1 = PayPalItem(name: itemName!, withQuantity: 1, withPrice: itemCost, withCurrency: "USD", withSku: String(itemId))
            
            let items = [item1]
            let subtotal = PayPalItem.totalPriceForItems(items)
            
            // Optional: include payment details
            let shipping = NSDecimalNumber(string: "0.00")
            let tax = NSDecimalNumber(string: "0.00")
            let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
            let total = subtotal.decimalNumberByAdding(shipping)
                .decimalNumberByAdding(tax)
                .decimalNumberByRoundingAccordingToBehavior( NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundUp, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
            
            let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: itemName!, intent: .Sale)
            
            payment.items = items
            payment.paymentDetails = paymentDetails
            
            if (payment.processable) {
                let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
                presentViewController(paymentViewController!, animated: true, completion: nil)
            } else {
                // This particular payment will always be processable. If, for
                // example, the amount was negative or the shortDescription was
                // empty, this payment wouldn't be processable, and you'd want
                // to handle that here.
                print("Payment not processalbe: \(payment)")
            }
        } else if convo?.intentStatus == 3 {
            let actionMenu = UIAlertController(title: nil, message: "How many stars do you give the seller?", preferredStyle: .ActionSheet)
            for i in 1...6 {
                
                let title : String
                
                if i == 6 {
                    title = "Cancel"
                } else {
                    title = "\(i)"
                }
                
                let rate = UIAlertAction(title: "\(title)", style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    if i < 6 {
                        self.rateSeller(i)
                    }
                })
                actionMenu.addAction(rate)
            }
            self.presentViewController(actionMenu, animated: true, completion: nil)
        }
        
    }
    // MARK: Launch Chat Controller

    
    func launchChatController() {
        let chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "User")
        chatController.title = "Simple Chat"
        //let helloWorld = LGChatMessage(content: "Hello World!", sentBy: .User)
        chatController.messages = (convo?.messages.map{
            let u : LGChatMessage.SentBy
            if $0.author_id == self.dbWrapper.user.id {
                u = LGChatMessage.SentBy.User
            } else {
                u = LGChatMessage.SentBy.Opponent
            }
            return LGChatMessage(content: $0.body, sentBy: u) })!
        chatController.delegate = self
        addChildViewController(chatController)
        chatController.view.frame = containerView.frame
        containerView.addSubview(chatController.view)
        chatController.didMoveToParentViewController(self)
        chatController.view.userInteractionEnabled = true
        chatController.inputView?.layoutSubviews()
        
        let width = NSLayoutConstraint(item: chatController.view, attribute: .Width, relatedBy: .Equal, toItem: containerView, attribute: .Width, multiplier: 1.0, constant: 0)
        let height = NSLayoutConstraint(item: chatController.view, attribute: .Height, relatedBy: .Equal, toItem: containerView, attribute: .Height, multiplier: 0.8, constant: 0)
        containerView.userInteractionEnabled = true
        //let v = chatController.inputView
        //chatController.inputView?.removeFromSuperview()
        //chatController.view.addSubview(v!)
        
        //containerView.addConstraint(width)
        //containerView.addConstraint(height)
        
       /* NSLayoutConstraint *width =[NSLayoutConstraint
            constraintWithItem:button
            attribute:NSLayoutAttributeWidth
            relatedBy:0
            toItem:coverForScrolView
            attribute:NSLayoutAttributeWidth
            multiplier:1.0
            constant:0];
        NSLayoutConstraint *height =[NSLayoutConstraint
            constraintWithItem:button
            attribute:NSLayoutAttributeHeight
            relatedBy:0
            toItem:coverForScrolView
            attribute:NSLayoutAttributeHeight
            multiplier:1.0
            constant:0];*/
        
        //self.addSubview(chatController.view, toView: containerView)
        /*presentViewController(chatController, animated: true) {
         
         
        }*/
      //  self.navigationController?.pushViewController(chatController, animated: true)
    }
        // MARK: LGChatControllerDelegate
    
    func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage) {
        print("Did Add Message: \(message.content)")
    }
    
    func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool {
       
        
        let pending = UIAlertController(title: "Sending...", message: nil, preferredStyle: .Alert)
        
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
        indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        pending.view.addSubview(indicator)
        indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        presentViewController(pending, animated: true, completion: {
            
        })
        
        func onSuccess(c: Convo) {
            pending.dismissViewControllerAnimated(true) {
                // get max created_on of the present messages and add any newer ones
                let maxId = self.convo?.messages.map{ $0.id }.maxElement()
                // TODO: implement this onChange for self.convo property
                let newMessages = c.messages.filter { $0.id > maxId }
                for m in newMessages {
                    let u : LGChatMessage.SentBy
                    if m.author_id == self.dbWrapper.user.id {
                        u = LGChatMessage.SentBy.User
                    } else {
                        u = LGChatMessage.SentBy.Opponent
                    }
                    chatController.addNewMessage(LGChatMessage(content: m.body, sentBy: u))
                }
            }
        }
        
        func onFailure() {
            pending.dismissViewControllerAnimated(true) {
                let msg = "Couldn't send message, lease try again soon."
                let alert = UIAlertController(title: "Sorry", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        dbWrapper.sendMessage(message.content, recipient_id: (convo?.userId)!, onSuccess: onSuccess, onFailure: onFailure)
        
        return false
    }
    
    @IBAction func returnToMessagesView(sender: AnyObject) {
        dismissViewControllerAnimated(true) { 
            
            
        }
    }
    
    // MARK: Paypal
    
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController) {
        print("PayPal Payment Cancelled")
        //resultText = ""
        //successView.hidden = true
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController, didCompletePayment completedPayment: PayPalPayment) {
        print("PayPal Payment Success !")
        paymentViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            // send completed confirmaion to your server
            print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")
            let pending = UIAlertController(title: "Capturing Payment", message: "Please stand by.", preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            self.presentViewController(pending, animated: true, completion: {
            })
            
            
            func onSuccess() {
                pending.dismissViewControllerAnimated(true, completion: {
                    self.dismissViewControllerAnimated(true, completion: {
                    })
                })
                // update convo to ensure item can't be paid for again
                
            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: nil)
                
            }
            // TODO: IMPLEMENT FAILURE DETECTION to see if status of payment was failed
            let paymentId = completedPayment.confirmation["response"]!["id"] as! String
            self.dbWrapper.capturePayment((self.convo?.intentId)!, paypalId: paymentId, onSuccess: onSuccess, onFailure: onFailure)
            
            
        })
    }

}
