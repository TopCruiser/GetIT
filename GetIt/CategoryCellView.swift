//
//  CategoryCellView.swift
//  GetIt
//  Created by a on 2016-02-15.
//  Copyright © 2016 GetIt. All rights reserved.

import UIKit


class CategoryCellView: UITableViewCell {

    
    @IBOutlet weak var categoryNameView: UITextView!
    @IBOutlet weak var rightCaret: UIImageView!
    
    @IBOutlet weak var sepView: UIView!
    @IBOutlet weak var returnView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        categoryNameView.editable = false;
        categoryNameView.selectable = false
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func renderCategory(category: Category) {
        categoryNameView.text = category.name
    }
    
    func showReturn() {
        returnView.hidden = false
        categoryNameView.hidden = true
        rightCaret.hidden = true
        sepView.hidden = true
        backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
    }
    func showCategory() {
        returnView.hidden = true
        categoryNameView.hidden = false
        rightCaret.hidden = false
        sepView.hidden = false
        backgroundColor = UIColor.whiteColor()
    }
    func renderAddCategory() {
        categoryNameView.text = "Choose Category"
    }
}
