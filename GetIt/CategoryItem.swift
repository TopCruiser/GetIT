//
//  CategoryItem.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-03-03.
//  Copyright © 2016 GetIt. All rights reserved.
//

struct CategoryItem {
    
    let item : Item
    let category: Category
    
    init(item: Item, category: Category) {
        self.item = item
        self.category = category
    }
    
}
