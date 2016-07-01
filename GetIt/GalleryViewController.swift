//
//  GalleryController.swift
//  GetIt
//
//  Created by Sayed Khader on 2016-03-16.
//  Copyright © 2016 GetIt. All rights reserved.
//

import Haneke
import Foundation
import UIKit


class GalleryViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var pageControl: UIPageControl!
    
    //var pageImages: [UIImage] = []
    var pageImageUrls: [String] = []
    var pageViews: [UIImageView?] = []
    var colors: [UIColor] = [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor(), UIColor.yellowColor(), UIColor.purpleColor()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        let pageCount = pageImageUrls.count
        
        pageControl.currentPage = 0
        pageControl.numberOfPages = pageCount
        
        for _ in 0..<pageCount {
            pageViews.append(nil)
        }
        
        let pageScrollViewSize = scrollView.frame.size
        scrollView.contentSize = CGSize(width: pageScrollViewSize.width * CGFloat(pageImageUrls.count),
                                        height: pageScrollViewSize.height)
        loadVisiblePages()
        scrollView.delegate = self
        
    }
    
    func loadPage(page: Int) {
        if page < 0 || page >= pageImageUrls.count {
            return
        }
        if let _ = pageViews[page] {
            // do nothing, view already loaded
        } else {
            var frame = scrollView.bounds
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0.0
            
            let newPageView = UIImageView()//image: pageImages[page])
            newPageView.contentMode = .ScaleAspectFit
            newPageView.frame = frame
            //newPageView.backgroundColor = colors[page]
            scrollView.addSubview(newPageView)

            pageViews[page] = newPageView
        }
        pageViews[page]!.hnk_setImageFromURL(NSURL(string:pageImageUrls[page])!)

    }
    
    @IBAction func dismissGallery(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            
        }
        
    }
    
    func purgePage(page: Int) {
        if page < 0 || page >= pageImageUrls.count {
            return
        }
        if let pageView = pageViews[page] {
            pageView.removeFromSuperview()
            pageViews[page] = nil
        }
    }
    
    func loadVisiblePages() {
        
        // first determine which page is presently visible
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        
        
        pageControl.currentPage = page
        
        // find which pages to load
        let firstPage = page-1
        let lastPage = page+1
        
        // purge everything before first page
        for index in 0 ..< firstPage {
            purgePage(index)
        }
        
        // load pages in range
        for index in firstPage...lastPage {
            loadPage(index)
        }
        
        // purge everything after last page
        for index in lastPage + 1 ..< pageImageUrls.count {
            purgePage(index)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        loadVisiblePages()
    }
    
}