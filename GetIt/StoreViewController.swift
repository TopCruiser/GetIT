//
//  StoreViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-05-16.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit


class StoreViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var itemTableView: UITableView!
    let dbWrapper : DBWrapper = DBWrapper.sharedInstance
    var tappedItem: Item?
    var user: User?
    @IBOutlet weak var shopTitle: UITextView!

    
    var items : [Item] = [] {
        didSet {
            itemTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        itemTableView.delegate = self
        itemTableView.dataSource = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if dbWrapper.user.id == user!.id {
            shopTitle.text = "My Shop"
        } else {
            shopTitle.text = "\(user!.name)'s Shop"
        }
        
        func onSuccess(items: [Item]) {
            self.items = items
        }
        func onFailure() {
            // display failure message
        }
        
        dbWrapper.getStoreItems(user!.id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @IBAction func returnToProfile(sender: AnyObject) {
    
    dismissViewControllerAnimated(true) { 
        
        
        }
    
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell
        
        let itemCell = tableView.dequeueReusableCellWithIdentifier("itemCellView", forIndexPath: indexPath) as! ItemCellView
        let item = items[indexPath.row]
        itemCell.renderItemData(item, userLocation: dbWrapper.user.location)
        cell = itemCell
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 320
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        tappedItem = item
        performSegueWithIdentifier("storeItemDetailViewSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let itemDetailViewController = segue.destinationViewController as! ItemDetailViewController
        itemDetailViewController.item = tappedItem
        
    }



}