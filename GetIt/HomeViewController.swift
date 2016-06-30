//
//  HomeViewController.swift
//  GetIt
//
//  Created by a on 2016-02-15.
//  Copyright © 2016 GetIt. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var profileDisplayControl: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let dbWrapper = DBWrapper.sharedInstance
    var tappedItem: Item?
    
    override  func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
        func success() {
            tableView.reloadData()
        }
        dbWrapper.onItemsReady(success)
    }
    
    
    @IBAction func profileButtonClicked(sender: AnyObject) {
        print("profile button clicked")
        performSegueWithIdentifier("ListViewToProfile", sender: nil)
        
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
      func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "itemCellView"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ItemCellView
        
        // Fetches the appropriate meal for the data source layout.
        //let item = items[indexPath.row]
        let item = dbWrapper.items[indexPath.row]
        cell.renderItemData(item, userLocation: dbWrapper.user.location)
        
        return cell
    }
    
      func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dbWrapper.items.count
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let itemDetailViewController = segue.destinationViewController as! ItemDetailViewController
        itemDetailViewController.item = tappedItem
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let itemIndex = indexPath.row
        let item = dbWrapper.items[itemIndex]
        tappedItem = item
        performSegueWithIdentifier("itemDetailViewFromHomeSegue", sender: self)
            
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let index = indexPath.row
        //var height : CGFloat?
        let height : CGFloat
        
        height = 320// self.categoryTable.frame.width
 
        
        return height
    }
}
