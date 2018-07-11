//
//  PhotoView.swift
//  Previewer
//
//  Created by WangWei on 2017/7/27.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit
import Kingfisher

// TO-DO: remove autolayout
class PhotoView: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    private var resource: ImageResource!
    
    private (set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private var imageViewLeading: NSLayoutConstraint!
    private var imageViewTrailing: NSLayoutConstraint!
    private var imageViewTop: NSLayoutConstraint!
    private var imageViewBottom: NSLayoutConstraint!
    
    private (set) var averageColor: UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// should relayout when layoutSubviews is called rather than using AutoLayout
//    override func layoutSubviews() {
//        zoomToFit()
//        super.layoutSubviews()
//    }
    
    func frameDidChanged() {
        zoomToFit()
    }
    
    private func config() {
        delegate = self
        bounces = false
        isScrollEnabled = true
        maximumZoomScale = Style.maxZoomScale
        minimumZoomScale = Style.minZoomScale
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        // config imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        configImageViewConstraint()
        
        configGesture()
    }
    
    private func configImageViewConstraint() {
        imageViewLeading = NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0)
        imageViewTrailing = NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)
        imageViewTop = NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        imageViewBottom = NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        addConstraints([imageViewLeading, imageViewTrailing, imageViewTop, imageViewBottom])
    }
    
    private func configGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    @objc private func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: imageView)
        zoomImageView(from: touchPoint)
    }
    
    // PhotoView reuse
    func prepareForReuse() {
        setZoomScale(minimumZoomScale, animated: false)
        imageView.image = nil
    }
    
    // config PhotoView with ImageResource
    func set(_ resource: ImageResource) {
        self.resource = resource
        loadResource()
    }
    
    private func loadResource() {
        let setImage: (UIImage?) -> Void = { [weak self] (image) in
            self?.imageView.image = image
            self?.zoomToFit()
            self?.averageColor = image?.avarageColor
        }
        
        if let image = resource.localImage {
            setImage(image)
        } else {
            if let thumbnail = resource.localThumbnail {
                setImage(thumbnail)
            }
            // load image from remote
            // TO-DO: remove Kingfisher dependency
            guard let url = resource.url else { return }
            KingfisherManager.shared.retrieveImage(
                with: url,
                options: nil,
                progressBlock: { (receivedSize, totalSize) in
                    // TO-DO: handle progress update
                },
                completionHandler: { (image, error, type, url) in
                    if let image = image {
                        DispatchQueue.main.async {
                            setImage(image)
                        }
                    }
            })
        }
    }
    
    private func zoomToFit() {
        guard let size = imageView.image?.size else { return }
        
        let minZoom = min(frame.width / size.width, frame.height / size.height)
        let maxZoom = max(max(frame.width / size.width, frame.height / size.height), Style.maxZoomScale)
        
        minimumZoomScale = minZoom
        maximumZoomScale = maxZoom
        
        // force scrollViewDidZoom to fire
        zoomScale = minZoom
        updateImageViewConstraintToFit()
    }
    
    private func zoomImageView(from point: CGPoint) {
        if minimumZoomScale != zoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            zoomImageViewToFit(from: point)
        }
    }
    
    private func updateImageViewConstraintToFit() {
        guard let size = imageView.image?.size else { return }
        
        do {
            let padding = max((frame.width - size.width * zoomScale) / 2, 0)
            imageViewLeading.constant = padding
            imageViewTrailing.constant = padding
        }
        
        do {
            let padding = max((frame.height - size.height * zoomScale) / 2, 0)
            imageViewTop.constant = padding
            imageViewBottom.constant = padding
        }
        layoutIfNeeded()
    }
    
    private func zoomImageViewToFit(from point: CGPoint) {
        guard let imageSize = imageView.image?.size else { return }
        
        var factor: CGFloat = 2
        
        let xScale = frame.width / imageSize.width
        let yScale = frame.height / imageSize.height
        
        let minScale = min(xScale, yScale)
        let maxScale = max(xScale, yScale)
        
        if minScale > 1 {
            factor = max(factor, maxScale)
        } else {
            factor = max(factor, maxScale / minScale)
        }
        
        let newWidth = frame.width / (factor * minimumZoomScale)
        let newHeight = frame.height / (factor * minimumZoomScale)
        let zoomRect = CGRect(x: point.x - newWidth / 2,
                              y: point.y - newHeight / 2,
                              width: newWidth,
                              height: newHeight)
        zoom(to: zoomRect, animated: true)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateImageViewConstraintToFit()
    }
}
