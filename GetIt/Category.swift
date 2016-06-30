//
//  Category.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-03-01.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Foundation
import UIKit

struct Category : Equatable {
    
    let name: String
    let parentCategoryId: Int
    let id: Int
    
    init(categoryName: String, parentId: Int, id: Int) {
        parentCategoryId = parentId
        name = categoryName
        self.id = id
    }
    
    func getSubcategories(db : DBWrapper) -> [Category] {
        return db.categories.filter{ $0.parentCategoryId == self.id }
    }
    func getItems(db: DBWrapper, listingType: Int) -> [Item] {
        let categoryItems : [CategoryItem]
        categoryItems = db.categoryItems.filter{ $0.category == self
                                                    && ($0.item.listingType == listingType
                                                        || $0.item.listingType == Item.bothType)}
        return categoryItems.map{ $0.item }
    }
    func getParent(db: DBWrapper) -> Category? {
        let parentCategory : Category?
        if parentCategoryId == 0 {
            parentCategory = self
        } else {
            if db.categories.count > 0 {
            parentCategory = db.categories.filter{$0.id == self.parentCategoryId}[0]
            } else {
                parentCategory = self
            }
        }
        return parentCategory
    }
}
func ==(lhs: Category, rhs: Category) -> Bool {
    return lhs.name == rhs.name
}