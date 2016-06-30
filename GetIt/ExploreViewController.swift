//
//  HomeViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-02-29.
//  Copyright © 2016 GetIt. All rights reserved.
//


import UIKit

class ExploreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var categoryTable: UITableView!
    @IBOutlet weak var listingTypeControl: UITabBar!
    
    let dbWrapper : DBWrapper = DBWrapper.sharedInstance
    let searchController = UISearchController(searchResultsController: nil)
    var activeSubcategories : [Category]?
    var activeCategoryItems : [Item]?
    var activeCategoryParent: Category?
    var tappedItem: Item?
     let highlightGreenColor = UIColor(red: CGFloat(50.0/255.0), green: CGFloat(172.0/255.0), blue: CGFloat(68.0/255.0), alpha: CGFloat(1.0))
     let backgroundGrayColor = UIColor.lightGrayColor()
     
    var currentListingType = 0 {
        didSet {
            activeCategoryItems = (activeCategory?.getItems(dbWrapper, listingType: currentListingType))
            categoryTable.reloadData()
        }
    }
    var activeCategory : Category? {
        didSet {
            activeSubcategories = (activeCategory?.getSubcategories(self.dbWrapper))!
            activeCategoryParent = (activeCategory?.getParent(self.dbWrapper))!
            activeCategoryItems = (activeCategory?.getItems(self.dbWrapper, listingType: currentListingType))!
            categoryTable.reloadData()
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        categoryTable.delegate = self
        categoryTable.dataSource = self
        activeCategory = dbWrapper.categories[0]
        listingTypeControl.selectedItem = listingTypeControl.items![0]
        listingTypeControl.delegate = self
        let numberOfItems = CGFloat(listingTypeControl.items!.count)
        let tabBarItemSize = CGSize(width: listingTypeControl.frame.width / numberOfItems, height: listingTypeControl.frame.height+20)
        //listingTypeControl.items.
        //listingTypeControl.backgroundImage = UIImage.imageWithColor(UIColor.lightGrayColor(), size: tabBarItemSize).resizableImageWithCapInsets(UIEdgeInsetsZero)
        //listingTypeControl.selectionIndicatorImage = UIImage.imageWithColor(UIColor.lightGrayColor(), size: tabBarItemSize).resizableImageWithCapInsets (UIEdgeInsetsZero)

        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
          categoryTable.tableHeaderView = searchController.searchBar
          self.categoryTable.separatorColor = UIColor.clearColor()
    }
     
     override func awakeFromNib() {


     }
    
    override func viewWillAppear(animated: Bool) {
        func x() {}
     func s() {
          if (self.activeCategory != nil) {
          
               self.activeCategory = self.dbWrapper.getCategoryByName((self.activeCategory?.name)!)
          }
     }
        dbWrapper.downloadCategories(s,onFailure: x)
        //categoryTable.reloadData()
     let item1 = listingTypeControl.items![0],
     item2 = listingTypeControl.items![1];
     
     
     item1.setTitleTextAttributes([NSForegroundColorAttributeName: highlightGreenColor,
          NSFontAttributeName:UIFont(name: "HelveticaNeue-Medium", size: 17)!], forState:.Selected)
     item1.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor(),
          NSFontAttributeName:UIFont(name: "HelveticaNeue-Light", size: 14)!], forState:.Normal)
     item2.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor(),
          NSFontAttributeName:UIFont(name: "HelveticaNeue-Light", size: 14)!], forState:.Normal)
        self.categoryTable.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height);
     item2.setTitleTextAttributes([NSForegroundColorAttributeName: highlightGreenColor,
          NSFontAttributeName:UIFont(name: "HelveticaNeue-Medium", size: 17)!], forState:.Selected)
           // remove default border
    }
    
    override func viewDidAppear(animate: Bool) {
    }
    
    override func viewDidLayoutSubviews() {
        listingTypeControl.frame.size.width = self.view.frame.width + 20
        listingTypeControl.frame.origin.x = -20
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let index = indexPath.row
        //var height : CGFloat?
        let height : CGFloat
        
        if searchController.active || ( activeCategoryParent != nil && index > activeSubcategories?.count) {
            height = 320// self.categoryTable.frame.width
        } else {
            height = 55
        }
        
        return height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell
        
        if searchController.active || ( activeCategoryParent != activeCategory && indexPath.row > activeSubcategories!.count) {
            
            // rendering an item row
            
            let itemCell = tableView.dequeueReusableCellWithIdentifier("itemCellView", forIndexPath: indexPath) as! ItemCellView
               let itemIndex : Int
          if searchController.active {
               itemIndex = indexPath.row
          } else {
               itemIndex = indexPath.row - activeSubcategories!.count - 1 // note if there are ever products in the root this will break

          }
            let item = activeCategoryItems![itemIndex]
            itemCell.renderItemData(item, userLocation: dbWrapper.user.location)
            
            cell = itemCell
            
        } else {
            
            let categoryCell = tableView.dequeueReusableCellWithIdentifier("categoryCellView", forIndexPath: indexPath) as! CategoryCellView
            
            if activeCategoryParent != activeCategory && indexPath.row == 0 {
                
                //categoryCell.categoryNameView.text = "Return to \(activeCategoryParent!.name)"
                categoryCell.showReturn()
                
            } else {
                
                let categoryIndex : Int
                
                if (activeCategoryParent != activeCategory) {
                    categoryIndex = indexPath.row - 1
                } else {
                    categoryIndex = indexPath.row
                }
                
                let category : Category = activeSubcategories![categoryIndex]
                
                categoryCell.categoryNameView.text = category.name
                categoryCell.showCategory()
            }
            cell = categoryCell

            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        var editable : Bool = false
        
        let (item, _) = getListItem(indexPath)
        
        if let _ = item {
            editable = item?.user_id == dbWrapper.user.id
        }
        return editable
    }
    
    func getListItem(indexPath: NSIndexPath) -> (Item?,Category?) {
        var row = indexPath.row
        var c : Category?
        var i : Item?
        
        if row == 0 && activeCategoryParent != nil {
            // do nothing
        } else {
            
            if activeCategoryParent != nil {
                row -= 1
            }
            
            if row < activeSubcategories?.count {
                c = activeSubcategories![row]
            } else {
                i = activeCategoryItems![row-(activeSubcategories?.count)!]
            }
        }
        
        return (i, c)
    }
    
     func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            let pending = UIAlertController(title: "Deleting Listing", message: nil, preferredStyle: .Alert)
            
            //create an activity indicator
            let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
            indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //add the activity indicator as a subview of the alert controller's view
            pending.view.addSubview(indicator)
            indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
            indicator.startAnimating()
            presentViewController(pending, animated: false, completion: { 
                
            })

            let (item, category) = getListItem(indexPath)
            func onSuccess() {
                pending.dismissViewControllerAnimated(true, completion: {
                })
                func vv() {}
                func categorySuccess() {
                    let cs : Category = self.activeCategory!
                    self.activeCategory = cs
                }
                
                self.dbWrapper.downloadCategories(categorySuccess, onFailure: vv)

            }
            func onFailure() {
                pending.dismissViewControllerAnimated(true, completion: {
                    
                })
                let alert = UIAlertController(title: "Bruh", message: "Server error, please try again soon.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            dbWrapper.deleteItemOnServer(item!, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let subcategoryCount, itemCount : Int
        
        if (activeSubcategories != nil) {
            if activeCategoryParent != activeCategory {
                subcategoryCount = (activeSubcategories?.count)! + 1
            } else {
                subcategoryCount = (activeSubcategories?.count)!
            }
        } else {
            subcategoryCount = 0
        }
        
        if activeCategoryItems != nil {
            itemCount = (activeCategoryItems?.count)!
        } else {
            itemCount = 0
        }
          if searchController.active {
               return (activeCategoryItems?.count)!
          } else {
               return subcategoryCount + itemCount
          }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var categoryIndex = indexPath.row
        
        if activeCategoryParent != activeCategory && categoryIndex > activeSubcategories!.count {
            
            let itemIndex = categoryIndex - activeSubcategories!.count - 1
            let item = activeCategoryItems![itemIndex]
            
            tappedItem = item
            performSegueWithIdentifier("itemDetailViewSegue", sender: self)
            
        } else {
            
            if categoryIndex == 0 && activeCategoryParent != activeCategory {
                activeCategory = activeCategoryParent
            } else {
                
                if (activeCategoryParent != activeCategory) {
                    categoryIndex--
                }
                
                activeCategory = activeSubcategories![categoryIndex]
            }
            
            //categoryTable.reloadData()

            
        }
        print("\(activeCategory!.name) selected")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let itemDetailViewController = segue.destinationViewController as! ItemDetailViewController
                itemDetailViewController.item = tappedItem
    }
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        let imgStore = listingTypeControl.backgroundImage
        listingTypeControl.backgroundImage = listingTypeControl.selectionIndicatorImage
        listingTypeControl.selectionIndicatorImage = imgStore;
        
        //listingTypeControl.backgroundImage = UIImage.imageWithColor(UIColor(hex:0xD7291A)!, size: tabBarItemSize).resizableImageWithCapInsets(UIEdgeInsetsZero)
        //listingTypeControl.selectionIndicatorImage = UIImage.imageWithColor(UIColor(hex:0x5AAA14)!, size: tabBarItemSize).resizableImageWithCapInsets (UIEdgeInsetsZero)
        
        let selectedType : Int
        if item.title == "Rent" {
            selectedType = 0
        } else {
            selectedType = 1
        }
        currentListingType = selectedType
        //print("\(currentListingType) selected")
    }
     
     func updateSearchResultsForSearchController(searchController: UISearchController) {
          
          let searchText = searchController.searchBar.text?.lowercaseString
          
          if searchText?.characters.count > 0 {
               activeCategoryItems = dbWrapper.items.filter{ $0.name.lowercaseString.containsString(searchText!) }
               categoryTable.reloadData()
          } else {
               activeCategory = dbWrapper.category0
          }
     }
}




