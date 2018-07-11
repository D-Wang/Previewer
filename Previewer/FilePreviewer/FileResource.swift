//
//  FileResource.swift
//  Previewer
//
//  Created by WangWei on 2017/12/18.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit
import QuickLook

public protocol FileResourceConvertible {
    var url: URL { get }
    var fileName: String? { get }
    var fileType: String? { get }
    var fileKey: String? { get }
    
    var isCached: Bool { get }
    var defaultPreviewItem: QLPreviewItem { get }
}

public extension FileResourceConvertible {
    // default implementation of isCached
    var isCached: Bool {
        return FileCache.default.isCached(forPath: cachePath)
    }
    
    var isLocal: Bool {
        return url.isFileURL
    }
    
    // default implementation to create previewItem
    var defaultPreviewItem: QLPreviewItem {
        return FilePreviewItem(resource: self)
    }
    
    var cachePreviewItem: QLPreviewItem {
        let cacheURL = URL(fileURLWithPath: cachePath)
        return FilePreviewItem(url: cacheURL, title: fileName)
    }
    
    var cachePath: String {
        guard !url.isFileURL else {
            return url.absoluteString
        }
        
        return FileCache.default.cachePath(for: url,
                                           fileName: fileName,
                                           fileType: fileName,
                                           fileKey: fileKey)
    }
}

public struct FileResource: FileResourceConvertible {
    public var fileName: String?
    public var url: URL
    public var fileType: String?
    public var fileKey: String?
    
    public init(url: URL, fileName: String?, fileType: String?, fileKey: String?) {
        self.url = url
        self.fileName = fileName
        self.fileType = fileType
        self.fileKey = fileKey
    }
}

open class FilePreviewItem: NSObject, QLPreviewItem {
    public var previewItemTitle: String?
    public var previewItemURL: URL?
    
    public init(resource: FileResourceConvertible) {
        super.init()
        self.previewItemTitle = resource.fileName
        self.previewItemURL = resource.url
    }
    
    public init(url: URL?, title: String?) {
        super.init()
        self.previewItemURL = url
        self.previewItemTitle = title
    }
}
