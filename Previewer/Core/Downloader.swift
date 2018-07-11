//
//  Downloader.swift
//  Previewer
//
//  Created by WangWei on 2017/12/18.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit
import Alamofire

typealias DownloadProgressHandler = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)
typealias DownloadCompletionHandler = ((_ error: Error?, _ url: URL) -> Void)

class Downloader {
    private var downloadReqests = [URL: DownloadRequest]()
    var cancelRequestsOnDeinit = true
    
    init() {
    }
    
    deinit {
        if cancelRequestsOnDeinit {
            cancelAllRequest()
        }
    }
    
    func downloadFile(with url: URL,
                      destinationURL: URL,
                      progressHandler: DownloadProgressHandler? = nil,
                      completionHandler: DownloadCompletionHandler? = nil) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destinationURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        let request = download(url,
                               method: .get,
                               parameters: nil,
                               encoding: JSONEncoding.default,
                               headers: nil,
                               to: destination)
            .downloadProgress { (progress) in
                progressHandler?(progress.completedUnitCount, progress.totalUnitCount)
            }
            .response { [weak self] (response) in
                if let error = response.error {
                    completionHandler?(error, url)
                } else {
                    completionHandler?(nil, url)
                }
                self?.removeRequest(for: url)
        }
        
        downloadReqests[url] = request
    }
    
    func removeRequest(for url: URL) {
        downloadReqests.removeValue(forKey: url)
    }
    
    func cancelAllRequest() {
        downloadReqests.values.forEach { (request) in
            request.cancel()
        }
    }
}
