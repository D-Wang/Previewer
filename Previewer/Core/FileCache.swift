//
//  FileCache.swift
//  Previewer
//
//  Created by WangWei on 2017/12/18.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit

open class FileCache {
    public static let `default` = FileCache(name: "default")
    
    private (set) var name: String?
    private (set) var diskCachePath: String
    private (set) var fileManager: FileManager
    private let ioQueue: DispatchQueue
    open var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    
    public init(name: String, path: String? = nil) {
        if name.isEmpty {
            fatalError("[Previewer] You should specify a name for the cache.")
        }
        self.name = name
        let cacheName = "com.dwang.Previewer.FileCache.\(name)"
        diskCachePath = FileCache.buildDiskCachePath(withName: cacheName, path: path)
        
        let ioQueueName = "com.dwang.Previewer.FileCache.ioQueue.\(name)"
        ioQueue = DispatchQueue(label: ioQueueName)
        fileManager = FileManager()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cleanExpiredCache),
                                               name: .UIApplicationWillTerminate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(backgroundCleanExpireCache),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }
    
    private class func buildDiskCachePath(withName name: String, path: String?) -> String {
        let dstPath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent(name)
    }
    
    func cachePath(for url: URL, fileName: String? = nil, fileType: String? = nil, fileKey: String? = nil) -> String {
        let wrapperDirectoryName = fileKey ?? cacheWrapperDirectoryName(forKey: url.cacheKey)
        var cacheName = fileName?.replacingOccurrences(of: "/", with: ":") ?? url.lastPathComponent
        if cacheName.isEmpty {
            cacheName = "unnamed_file"
        }
        var pathExtension = (cacheName as NSString).pathExtension
        if pathExtension.isEmpty {
            pathExtension = fileType ?? url.pathExtension
            if !pathExtension.isEmpty {
                cacheName = (cacheName as NSString).appendingPathExtension(pathExtension)!
            }
        }
        return ((diskCachePath as NSString)
            .appendingPathComponent(wrapperDirectoryName) as NSString)
            .appendingPathComponent(cacheName)
    }
    
    func isCached(forPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    func cacheWrapperDirectoryName(forKey key: String) -> String {
        return key.md5
    }
    
    func clearDiskCache(completion handler: (() -> Void)? = nil) {
        do {
            try fileManager.removeItem(atPath: diskCachePath)
        } catch _ {}
    }
    
    @objc func cleanExpiredCache() {
        clearDiskCache(completion: nil)
    }
    
    @objc func backgroundCleanExpireCache() {
        let sharedApplication = UIApplication.shared
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = sharedApplication.beginBackgroundTask {
            endBackgroundTask(&backgroundTask!)
        }
        
        clearExpiredCache {
            endBackgroundTask(&backgroundTask!)
        }
    }
    
    func clearExpiredCache(completion handler: (() -> Void)? = nil) {
        let urlsToDelete = findExpiredFiles()
        
        ioQueue.async {
            for fileURL in urlsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                } catch _ {}
            }
        }
    }
    
    private func findExpiredFiles() -> [URL] {
        let cacheURL = URL(fileURLWithPath: diskCachePath)
        let resourceKeys: Set<URLResourceKey> = [.contentAccessDateKey]
        let expiredDate: Date? = maxCachePeriodInSecond < 0 ? nil : Date(timeIntervalSinceNow: -maxCachePeriodInSecond)
        
        var urlsToDelete = [URL]()
        for fileURL in (try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? [] {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                
                if let expiredDate = expiredDate,
                    let lastAccessDate = resourceValues.contentAccessDate,
                    lastAccessDate.compare(expiredDate) == .orderedAscending {
                    urlsToDelete.append(fileURL)
                }
            } catch _ {}
        }
        return urlsToDelete
    }
}
