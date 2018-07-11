//
//  SingleFileDataSource.swift
//  Previewer
//
//  Created by WangWei on 2017/12/18.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import Foundation
import QuickLook

internal protocol SingleFileDataSourceDelegate: class {
    func singleFileDataSourceDownloadDidBegin()
    func singleFileDataSourceDownloadDidComplete()
    func singleFileDataSourceDownloadDidFail()
    func singleFileDataSourceDownloadProgressDidUpdate(withReceivedSize receivedSize: Int64, totalSize: Int64)
}

internal extension SingleFileDataSourceDelegate {
    func singleFileDataSourceDownloadDidBegin() {}
    func singleFileDataSourceDownloadDidComplete() {}
    func singleFileDataSourceDownloadDidFail() {}
    func singleFileDataSourceDownloadProgressDidUpdate(withReceivedSize receivedSize: Int64, totalSize: Int64) {}
}

internal class SingleFileDataSource {
    weak var owner: QLPreviewController?
    private (set) var resource: FileResourceConvertible
    private (set) var downloader: Downloader
    weak var delegate: SingleFileDataSourceDelegate?
    
    init(resource: FileResourceConvertible) {
        self.downloader = Downloader()
        self.resource = resource
    }
    
    private func downloadFileAndRefresh() {
        let cacheURL = URL(fileURLWithPath: resource.cachePath)
        delegate?.singleFileDataSourceDownloadDidBegin()
        downloader.downloadFile(with: resource.url,
                                destinationURL: cacheURL,
                                progressHandler: { [weak self] (receivedSize, totalSize) in
                                    // update progress
                                    self?.delegate?.singleFileDataSourceDownloadProgressDidUpdate(withReceivedSize: receivedSize,
                                                                                                  totalSize: totalSize)
        },
                                completionHandler: { [weak self] (error, _) in
                                    // complete
                                    if error != nil {
                                        self?.delegate?.singleFileDataSourceDownloadDidFail()
                                    } else {
                                        self?.owner?.refreshCurrentPreviewItem()
                                        self?.delegate?.singleFileDataSourceDownloadDidComplete()
                                    }
        })
    }
}

extension SingleFileDataSource: QLPreviewControllerDataSource {
    internal func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    internal func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if resource.isLocal {
            return resource.defaultPreviewItem
        } else if resource.isCached {
            return resource.cachePreviewItem
        } else {
            downloadFileAndRefresh()
            return resource.cachePreviewItem
        }
    }
}
