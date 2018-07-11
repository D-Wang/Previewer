//
//  ExampleViewController.swift
//  Example
//
//  Created by WangWei on 2017/7/24.
//  Copyright © 2017年 WangWei. All rights reserved.
//  sample files from: http://www.sample-videos.com
//

import UIKit
import Kingfisher

let kExamplePhotos = ["https://www.sample-videos.com/img/Sample-jpg-image-50kb.jpg",
                      "https://www.sample-videos.com/img/Sample-png-image-100kb.png",
                      "https://www.sample-videos.com/img/Sample-png-image-1mb.png",
                      "https://www.sample-videos.com/gif/1.gif"]

let kExampleFiles = ["Sample_pdf.pdf": "http://www.sample-videos.com/pdf/Sample-pdf-5mb.pdf",
                     "Sample_doc.doc": "http://www.sample-videos.com/doc/Sample-doc-file-500kb.doc",
                     "Sample_ppt.ppt": "http://www.sample-videos.com/ppt/Sample-PPT-File-1000kb.ppt",
                     "Sample_jpg.jpg": "http://www.sample-videos.com/img/Sample-jpg-image-500kb.jpg",
                     "Sample_video.mp4": "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_10mb.mp4",
                     "Sample_audio.mp3": "http://www.sample-videos.com/audio/mp3/wave.mp3",
                     "Sample_xls.xls": "http://www.sample-videos.com/xls/Sample-Spreadsheet-1000-rows.xls"]

class ExampleViewController: UITableViewController {
    
    var exampleFileKeys = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Example"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(onTapClear))
        exampleFileKeys = Array(kExampleFiles.keys).sorted()
    }
    
    @objc private func onTapClear() {
        FileCache.default.clearDiskCache()
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
    
    @objc private func onTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onTapMore() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.message = "Previewer"
        alertController.addAction(UIAlertAction(title: "Save To Album", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: nil))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        presentedViewController?.present(alertController, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? kExamplePhotos.count : exampleFileKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TableViewCell")
        if indexPath.section == 0 {
            cell.textLabel?.text = kExamplePhotos[indexPath.row]
        } else {
            cell.textLabel?.text = exampleFileKeys[indexPath.row]
        }
        cell.textLabel?.lineBreakMode = .byTruncatingMiddle
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let resources: [ImageResource] = kExamplePhotos.compactMap {
                guard let url = URL(string: $0) else { return nil }
                return ImageResource(imageUrl: url, thumbnail: nil, thumbnailUrl: nil)
            }
            let previewer = PreviewerController(resources: resources)
            previewer.initialPageIndex = indexPath.row
            previewer.modalPresentationStyle = .overCurrentContext
            present(previewer, animated: true, completion: nil)
        } else {
            let key = exampleFileKeys[indexPath.row]
            guard let fileURL = URL(string: kExampleFiles[key]!) else {
                return
            }

            let resource = FileResource(url: fileURL, fileName: key, fileType: nil, fileKey: nil)
            let previewer = FilePreviewController(resource: resource)
            previewer.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close_icon"), style: .plain, target: self, action: #selector(onTapClose))
            previewer.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "more_icon"), style: .plain, target: self, action: #selector(onTapMore))
            previewer.disableSystemShare = true
            let navigation = UINavigationController(navigationBarClass: nil, toolbarClass: CustomToolbar.self)
            navigation.viewControllers = [previewer]
            navigation.view.backgroundColor = .white
            navigation.toolbar.tintColor = .black
            navigation.navigationBar.tintColor = .black
            present(navigation, animated: true, completion: nil)
        }
    }
}

