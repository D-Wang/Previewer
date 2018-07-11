//
//  FilePreviewController.swift
//  Previewer
//
//  Created by WangWei on 2017/12/18.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit
import QuickLook

open class FilePreviewController: QLPreviewController {
    private var simpleDataSource: SingleFileDataSource
    fileprivate var loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    private var customNavigationItem = CustomNavigationItem()
    private var _navigationController: UINavigationController? {
        didSet {
            updateSystemShareStatus()
        }
    }
    
    var disableSystemShare = false {
        didSet {
            updateSystemShareStatus()
        }
    }
    
    open override var navigationItem: UINavigationItem {
        return customNavigationItem
    }
    
    public init(resource: FileResourceConvertible) {
        self.simpleDataSource = SingleFileDataSource(resource: resource)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = simpleDataSource
        self.delegate = self
        
        simpleDataSource.owner = self
        simpleDataSource.delegate = self
        navigationItem.title = simpleDataSource.resource.fileName
        
        customNavigationItem.preferredRightBarButtonItems = navigationItem.rightBarButtonItems
        customNavigationItem.preferredLeftBarButtonItems = navigationItem.leftBarButtonItems
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configActivityIndicatorView()
        if _navigationController == nil {
            _navigationController = navigationController ?? findEmbeddedNavigationController()
        }
    }
    
    private func configActivityIndicatorView() {
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.removeFromSuperview()
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
    }
    
    private func updateSystemShareStatus() {
        (_navigationController?.toolbar as? CustomToolbar)?.shouldFilterSystemShareButton = disableSystemShare
        customNavigationItem.shouldFilterSystemShareButton = disableSystemShare
    }
    
    private func findEmbeddedNavigationController() -> UINavigationController? {
        guard let layoutContainerView = view.subviews.first,
            String(describing: type(of: layoutContainerView)) == "UILayoutContainerView" else {
            return nil
        }
        return layoutContainerView.next as? UINavigationController
    }
}

extension FilePreviewController: SingleFileDataSourceDelegate {
    internal func singleFileDataSourceDownloadDidBegin() {
        loadingIndicatorView.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    internal func singleFileDataSourceDownloadDidComplete() {
        loadingIndicatorView.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    internal func singleFileDataSourceDownloadDidFail() {
        loadingIndicatorView.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension FilePreviewController: QLPreviewControllerDelegate { }
