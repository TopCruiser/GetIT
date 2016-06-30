//
//  ItemViewController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-02-29.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit
import Haneke

class ItemViewController : UncoveredContentViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewTwo: UIImageView!
    @IBOutlet weak var imageViewThree: UIImageView!
    @IBOutlet weak var itemNameView: UITextField!
    @IBOutlet weak var priceView: UITextField!
    @IBOutlet weak var listingTypeView: UISegmentedControl!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var itemCategoriesView: UITableView!
    @IBOutlet var categoryField : AutoCompleteTextField!
    @IBOutlet weak var chooseCategoryButton: UIButton!
    @IBOutlet weak var categoryPickTableView: UITableView!
    @IBOutlet weak var categoryPickerPopup: UIView!

    
    var activeImageView : UIImageView?
    let imagePicker = UIImagePickerController()
    var selectedImages : [UIImage] = []
    var dbWrapper = DBWrapper.sharedInstance
    
    var activeItemCategories : [Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
       // itemCategoriesView.delegate = self
        //itemCategoriesView.dataSource = self
        categoryPickTableView.delegate = self
        categoryPickTableView.dataSource = self
        categoryPickTableView.separatorStyle = .None
        categoryField.delegate = self
        imageView.layer.borderColor = UIColor(red: CGFloat(0/255.0), green: CGFloat(0/255.0), blue: CGFloat(60/255.0), alpha: CGFloat(0.1)).CGColor
        imageViewTwo.layer.borderColor = UIColor(red: CGFloat(0/255.0), green: CGFloat(0/255.0), blue: CGFloat(60/255.0), alpha: CGFloat(0.1)).CGColor
        imageViewThree.layer.borderColor = UIColor(red: CGFloat(0/255.0), green: CGFloat(0/255.0), blue: CGFloat(60/255.0), alpha: CGFloat(0.1)).CGColor
        chooseCategoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        chooseCategoryButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 30.0, 0.0, 30.0)
        
        activeImageView = imageView
        
        descriptionView.delegate = self
        
    }
    override func viewWillAppear(animated: Bool) {
  //      categoryField.enableAttributedText = true
        //categoryField.maximumAutoCompleteCount = dbWrapper.categories.count
        //categoryField.autoCompleteTableHeight = CGFloat(categoryField.maximumAutoCompleteCount * 60)
        categoryField.autoCompleteTextColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
        categoryField.autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)
        categoryField.autoCompleteCellHeight = 35.0
        categoryField.maximumAutoCompleteCount = 20
        categoryField.hidesWhenSelected = true
        categoryField.hidesWhenEmpty = true
        categoryField.enableAttributedText = true
        var attributes = [String:AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12.0)
        categoryField.autoCompleteAttributes = attributes
        setCategoryAutocomplete()
        
        categoryField.onTextChange = {[weak self] text in
            if !text.isEmpty{
                let idx = text.startIndex.advancedBy(text.characters.count)
                //print("\(idx)")
                let filteredCategories = self!.dbWrapper.categories.filter{
                    if $0.name.characters.count >= text.characters.count {
                        //print($0.name.substringToIndex(idx))
                        return text.lowercaseString ==  $0.name.substringToIndex(idx).lowercaseString }
                    else {
                        return false
                    }
                }
                self!.categoryField.autoCompleteStrings = filteredCategories.map{ $0.name }
            }
        }
        categoryField.onSelect = {[weak self] text, indexPath in
            
            let c = self?.dbWrapper.getCategoryByName((self?.categoryField.autoCompleteStrings![indexPath.row])!)
            
            self!.activeItemCategories.append(c!)
            self!.categoryField.text = ""
            
        }

    }
    
    func setCategoryAutocomplete() {
        let categoryNames = dbWrapper.categories.map{ $0.name }
        categoryField.autoCompleteStrings = categoryNames

    }
    
    
    @IBAction func addCategory(sender: AnyObject) {
        let newCategoryName = categoryField.text
        var errMsg = ""
        if newCategoryName?.characters.count > 0 {
            
            let pickedCategory = dbWrapper.getCategoryByName(newCategoryName!)
            
            if pickedCategory != nil {
                
                let itemTest = activeItemCategories.filter{$0.name == newCategoryName}
                
                if itemTest.count > 0 {
                    
                    errMsg = "This item is already in \(newCategoryName!)"
                    
                } else {
                    
                    //setCategoryAutocomplete()
                }
                
                
            } else {
                errMsg = "Please select a category from the suggestions."
            }
            
        } else {
            //
        }
        
        if errMsg.characters.count > 0 {
            
            let alert = UIAlertController(title: "Note", message: errMsg, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)

        }
        
    }
    
    func switchToExploreView() {
        
        self.tabBarController?.selectedIndex = 2;
        
    }
    
    func clearFields() {
        
        let img = UIImage(named: "iconPhotoCamera")
        
        imageView.image = img
        imageViewTwo.image = img
        imageViewThree.image = img
        imageViewTwo.hidden = true
        imageViewThree.hidden = true
        imageView.contentMode = .Center
        imageViewTwo.contentMode = .Center
        imageViewThree.contentMode = .Center
        activeImageView = imageView
        itemNameView.text = ""
        priceView.text = ""
        descriptionView.text = ""
        activeItemCategories = [ ]
        listingTypeView.selectedSegmentIndex = 0
        selectedImages = [ ]
        chooseCategoryButton.setTitle("Choose Category", forState: .Normal)
        
    }
    
    func isListingValid() -> Bool {
        
        var errFields : [String] = [ ]
        
        if selectedImages.count == 0 {
            errFields.append("Item Picture")
        }
        if (itemNameView.text?.characters.count == 0) {
            errFields.append("Item Name")
        }
        if (descriptionView.text?.characters.count == 0) {
            errFields.append("Description")
        }
        if priceView.text?.characters.count == 0 {
            errFields.append("Price")
        }
        
        var errMsg = ""
        
        if errFields.count > 0 {
            
            errMsg = "The following fields are required:\n"
            
            for (idx, field) in errFields.enumerate() {
                errMsg += field;
                if idx < errFields.count - 1 {
                    errMsg += ","
                }
                errMsg += "\n"
            }
        } else if activeItemCategories.count == 0 {
            errMsg += "Please provide at least one category for your item listing"
        } else if (dbWrapper.user.id <= 0) {
            errMsg += "Please login before you can post an item"
        } else if !dbWrapper.user.hasPaypalProfile {
            errMsg += "Please setup your PayPal profile under user settings before listing an item."
        }
        
        if errMsg.characters.count > 0 {
            let alert = UIAlertController(title: "Note", message: errMsg, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)

            return false;
        }
        return true
    }
    
    @IBAction func pictureTapped(sender: AnyObject) {
        
        if selectedImages.count < 3 {
            
            
            let actionSheet = UIAlertController(title: nil, message: "Picture source", preferredStyle: .ActionSheet)
            let libraryAction = UIAlertAction(title: "My Photos", style: .Default, handler: { (UIAlertAction) in
                self.imagePicker.sourceType = .PhotoLibrary
                self.presentViewController(self.imagePicker, animated: true) { () -> Void in}

            })
            let cameraAction = UIAlertAction(title: "Camera", style: .Default, handler: { (UIAlertAction) in
                self.imagePicker.sourceType = .Camera
                self.presentViewController(self.imagePicker, animated: true) { () -> Void in}
                
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            actionSheet.addAction(libraryAction)
            actionSheet.addAction(cameraAction)
            actionSheet.addAction(cancelAction)
            self.presentViewController(actionSheet, animated: true, completion: { 
                
                
            })
            
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            activeImageView!.contentMode = .ScaleToFill
            activeImageView!.image = pickedImage
            selectedImages.append(pickedImage)
            if selectedImages.count == 1 {
               imageViewTwo.hidden = false
                activeImageView = imageViewTwo
            } else if selectedImages.count == 2 {
                imageViewThree.hidden = false
                activeImageView = imageViewThree
            }
        }
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    func displaySavedConfirmation() {
        let alert = UIAlertController(title: "Success", message: "Your item has been listed!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    func displayServerError() {
        let alert = UIAlertController(title: "Bruh", message: "Server error, please try again soon.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func persistListing() {
        
        let pending = UIAlertController(title: "Saving Listing", message: nil, preferredStyle: .Alert)
        
        //create an activity indicator
        let indicator = UIActivityIndicatorView(frame: pending.view.bounds)
        indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        //add the activity indicator as a subview of the alert controller's view
        pending.view.addSubview(indicator)
        indicator.userInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        
        self.presentViewController(pending, animated: true, completion: nil)
        
        let newItem = Item(name: itemNameView.text!, pics: selectedImages,
                           cost: (priceView.text! as NSString).floatValue,
                           user_id: dbWrapper.user.id, description: descriptionView.text!,
                           type: listingTypeView.selectedSegmentIndex,
                           latitude: Float(CGFloat(dbWrapper.user.location.coordinate.latitude)), longitude: Float(CGFloat(dbWrapper.user.location.coordinate.longitude)), id: -1, pictureUrls: [],
                           sellerAvatarUrl: "http://refinerysource.com/wp-content/uploads/2013/01/avatar.png", sellerName: self.dbWrapper.user.name)
        func showSaveCompleted() {
            pending.dismissViewControllerAnimated(true, completion: {
                
                
            })
            clearFields()
            displaySavedConfirmation()
            //switchToExploreView()
        }
        func showSaveFailed() {
            displayServerError()
            pending.dismissViewControllerAnimated(true, completion: {})
        }
        
        dbWrapper.saveItemToServer(newItem!, categories: activeItemCategories, onSuccess: showSaveCompleted, onFailure: showSaveFailed)
        
        /*dbWrapper.addItem(newItem!, inCategories: activeItemCategories)*/
        
    }
    @IBAction func postItem(sender: AnyObject) {
        
        if isListingValid() {
            persistListing()
        }
        
    }
    
    func displayAddCategory() {

        func addCategoryField(textField: UITextField!) {
            textField.placeholder = "Category"
            //categoryField = textField
        }
        func categoryEntered(alert: UIAlertAction!) {
            let newCategoryName = categoryField.text
            if (activeItemCategories.filter{ $0.name == newCategoryName }).count == 0 {
                let c = dbWrapper.getCategoryByName(newCategoryName!)
                activeItemCategories.append(c!)
            }
        }
        
        let newCategoryPrompt = UIAlertController(title: "Add a category.", message: "Your item will appear under this category listing", preferredStyle:  UIAlertControllerStyle.Alert)
        newCategoryPrompt.addTextFieldWithConfigurationHandler(addCategoryField)
        newCategoryPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler:  nil))
        newCategoryPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: categoryEntered))
        presentViewController(newCategoryPrompt, animated: true, completion: nil)
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "categoryCellView"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CategoryCellView
        let category = dbWrapper.categories[indexPath.row+1]
        cell.renderCategory(category)
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dbWrapper.categories.count - 1
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = dbWrapper.categories[indexPath.row+1]
        activeItemCategories = [c]
        chooseCategoryButton.setTitle(c.name , forState: .Normal)
        showCategoriesPopup(self)
    }
    /*func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row > 1 {
            return true
        }
        return false
    }*
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            activeItemCategories.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }*/
    func textFieldDidChange(textField: UITextField) {
        if textField.text?.characters.count > 0 {
            //setCategoryAutocomplete()
        }
    }
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    override func textFieldShouldReturn(tf: UITextField) -> Bool {
        tf.resignFirstResponder()
        return false
    }
  
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        let t = textView.text
        if textView == descriptionView && t == "Explain your item" {
            textView.text = ""
        }
        return true
    }
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        let t = textView.text
        if textView == descriptionView &&
            t.characters.count == 0 {
            textView.text = "Explain your item"
        }
        return true
    }
    
    @IBAction func showCategoriesPopup(sender: AnyObject) {
        categoryPickerPopup.hidden = !categoryPickerPopup.hidden
    }
    
    
}