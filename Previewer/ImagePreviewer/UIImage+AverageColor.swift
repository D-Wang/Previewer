//
//  UIImage+AverageColor.swift
//  Previewer
//
//  Created by WangWei on 2017/7/31.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit

extension UIImage {
    var avarageColor: UIColor {
        let context = CIContext(options: nil)
        let ciImage = CIImage(image: self)
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter?.outputImage else {
            return UIColor.black
        }
        let cgImage = context.createCGImage(output, from: output.extent)
        
        guard let pixelData = cgImage?.dataProvider?.data else {
            return UIColor.black
        }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let r = CGFloat(data[0]) / 255.0
        let g = CGFloat(data[1]) / 255.0
        let b = CGFloat(data[2]) / 255.0
        let a = CGFloat(data[3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
