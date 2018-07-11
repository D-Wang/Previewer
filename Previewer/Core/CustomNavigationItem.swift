//
//  CustomNavigationItem.swift
//  Previewer
//
//  Created by WangWei on 2017/12/20.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit

class CustomNavigationItem: UINavigationItem {
    var shouldFilterSystemShareButton = false
    var preferredLeftBarButtonItems: [UIBarButtonItem]?
    var preferredRightBarButtonItems: [UIBarButtonItem]?
    
    override func setLeftBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        if preferredLeftBarButtonItems != nil {
            super.setLeftBarButtonItems(preferredLeftBarButtonItems, animated: animated)
        } else {
            super.setLeftBarButtonItems(items, animated: animated)
        }
    }
    
    override func setRightBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        if preferredRightBarButtonItems != nil {
            var newItems = preferredRightBarButtonItems ?? []
            let systemShareButton = items?.filter { $0.isSystemShareButton }.first
            if !shouldFilterSystemShareButton, let shareButton = systemShareButton {
                newItems.insert(shareButton, at: 0)
            }
            super.setRightBarButtonItems(newItems, animated: animated)
        } else {
            super.setRightBarButtonItems(items, animated: animated)
        }
    }
}

class CustomToolbar: UIToolbar {
    var shouldFilterSystemShareButton = false
    
    override func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        if shouldFilterSystemShareButton {
            super.setItems(items?.filter { !$0.isSystemShareButton }, animated: animated)
        } else {
            super.setItems(items, animated: animated)
        }
    }
}

extension UIBarButtonItem {
    var isSystemShareButton: Bool {
        guard let actionName = action?.description else {
            return false
        }
        let selectorName = "actionButtonTapped:"
        let selectorNameAfteriOS10 = "_actionButtonTapped:"
        return [selectorName, selectorNameAfteriOS10].contains(actionName)
    }
}
