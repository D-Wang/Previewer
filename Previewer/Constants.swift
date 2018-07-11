//
//  Constants.swift
//  Previewer
//
//  Created by WangWei on 2017/7/31.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit

struct Previewer {
    static var maxVisibleItems = 3
}

struct Style {
    static var maxZoomScale: CGFloat = 3
    static var minZoomScale: CGFloat = 1
    static var pageSpacing: CGFloat = 20
}

struct PanGesture {
    static var maxAllowAngleOffset: CGFloat = 30
    static var dismissAnimationDuration: CGFloat = 0.3
}
