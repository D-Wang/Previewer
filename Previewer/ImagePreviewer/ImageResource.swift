//
//  ImageResource.swift
//  Previewer
//
//  Created by WangWei on 2017/7/24.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit
import Kingfisher

protocol ImageResourceConvertible {
    var image: UIImage? { get }
    var url: URL? { get }
    var thumbnail: UIImage? { get }
    var thumbnailUrl: URL? { get }
    // Cache releated
    var isImageCached: Bool { get }
    var localImage: UIImage? { get }
    var localThumbnail: UIImage? { get }
}

extension ImageResourceConvertible {
    var isImageCached: Bool {
        guard let cacheKey = url?.cacheKey else { return false }
        return ImageCache.default.imageCachedType(forKey: cacheKey).cached
    }
    
    // This method can block UI
    var localImage: UIImage? {
        if image != nil { return image }
        guard let cacheKey = url?.cacheKey else { return nil }
        return ImageCache.default.retrieveImageInMemoryCache(forKey: cacheKey)
            ?? ImageCache.default.retrieveImageInDiskCache(forKey: cacheKey)
    }
    
    var localThumbnail: UIImage? {
        if thumbnail != nil { return thumbnail }
        guard let cacheKey = thumbnailUrl?.cacheKey else { return nil }
        return ImageCache.default.retrieveImageInMemoryCache(forKey: cacheKey)
            ?? ImageCache.default.retrieveImageInDiskCache(forKey: cacheKey)
    }
}

struct ImageResource: ImageResourceConvertible {
    var image: UIImage?
    var url: URL?
    var thumbnail: UIImage?
    var thumbnailUrl: URL?
    
    init(imageUrl: URL, thumbnail: UIImage?, thumbnailUrl: URL?) {
        self.url = imageUrl
        self.thumbnail = thumbnail
        self.thumbnailUrl = thumbnailUrl
    }
    
    init(image: UIImage, thumbnail: UIImage?, thumbnailUrl: URL?) {
        self.image = image
        self.thumbnail = thumbnail
        self.thumbnailUrl = thumbnailUrl
    }
}

extension URL {
    var cacheKey: String {
        return absoluteString
    }
}
