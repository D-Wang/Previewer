//
//  PreviewerController.swift
//  Previewer
//
//  Created by WangWei on 2017/7/25.
//  Copyright © 2017年 WangWei. All rights reserved.
//

import UIKit

public class PreviewerController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    private static let maxVisibleItems = 3
    private var scrollView = UIScrollView()
    
    private var resources: [ImageResource]
    // visible photo views should be no more than 4
    private var visiblePhotoViews: [PhotoView] = []
    
    // reusable items
    private var reusablePhotoViews = Set<PhotoView>()
    
    private var backgroundView = UIView()
    private var snapshotInitialFrame: CGRect = .zero
    private var panningPhotoView: PhotoView?
    private var snapshot: UIView?
    
    private (set) var currentPageIndex: Int = 0
    var initialPageIndex: Int = 0
    
    init(resources: [ImageResource]) {
        self.resources = resources
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationCapturesStatusBarAppearance = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        configBasicUI()
        configGesture()
        addAllPhotos()
    }
    
    public override func viewWillLayoutSubviews() {
        // TO-DO: invalid layout
        super.viewWillLayoutSubviews()
        print("contentOffset: \(scrollView.contentOffset)")
//        layoutVisiblePhotos()
    }
    
    private func configBasicUI() {
        configBackgroundView()
        configScrollView()
    }
    
    private func configBackgroundView() {
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        backgroundView.frame = view.frame
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = .white
    }
    
    private func configScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let scrollViewSize = CGSize(width: view.frame.width + Style.pageSpacing,
                                    height: view.frame.height)
        scrollView.frame = CGRect(origin: .zero, size: scrollViewSize)
        scrollView.backgroundColor = UIColor.clear
        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = true
        scrollView.delegate = self
        updateContentSize()
        view.addSubview(scrollView)
    }
    
    private func configPhotoView(atIndex index: Int) {
        guard 0 ..< resources.count ~= index else { return }
        guard self.photoView(atIndex: index) == nil else { return }
        
        let photoView = dequeuePhotoView(atIndex: index)
        photoView.set(resources[index])
        scrollView.addSubview(photoView)
        visiblePhotoViews.append(photoView)
    }
    
    private func addAllPhotos() {
        guard !resources.isEmpty else { return }
        currentPageIndex = initialPageIndex
        let photoView = dequeuePhotoView(atIndex: currentPageIndex)
        photoView.set(resources[currentPageIndex])
        scrollView.addSubview(photoView)
        visiblePhotoViews.append(photoView)
        scrollView.contentOffset = CGPoint(x: CGFloat(currentPageIndex) * scrollView.bounds.width, y: 0)
    }
    
    private func layoutVisiblePhotos() {
        scrollView.contentOffset = CGPoint(x: CGFloat(currentPageIndex) * scrollView.bounds.width, y: 0)
        visiblePhotoViews.forEach { photoView in
            let index = photoView.tag
            let newFrame = view.bounds.offsetBy(dx: CGFloat(index) * scrollView.bounds.width,
                                                dy: 0)
            photoView.frame = newFrame
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.layoutVisiblePhotos()
            self.visiblePhotoViews.forEach { $0.frameDidChanged() }
        }, completion: { (_) in
            self.updateContentSize()
        })
    }
    
    private func updateContentSize() {
        let contentWidth = scrollView.bounds.width * CGFloat(resources.count)
        scrollView.contentSize = CGSize(width: contentWidth, height: view.frame.height)
    }
    
    private func photoView(at location: CGPoint) -> PhotoView? {
        let index = Int(floor(location.x / scrollView.bounds.width))
        return photoView(atIndex: index)
    }
    
    // handle gesture
    private func configGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }
    
    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began:
            beginPanToDismiss(at: gesture.location(in: scrollView))
        case .changed:
            updatePanToDismss(translation: translation)
        default:
            let velocity = gesture.velocity(in: view)
            guard let center = snapshot?.center else { return }
            let viewHeight = view.frame.height
            if center.y > viewHeight * 0.9
                || center.y < viewHeight * 0.1
                || (velocity.y > 100 && translation.y > 0)
                || (velocity.y < -100 && translation.y < 0) {
                completePanToDismiss(velocity: velocity, translation: translation)
            } else {
                cancelPanToDismiss(velocity: velocity, translation: translation)
            }
        }
    }
    
    private func beginPanToDismiss(at location: CGPoint) {
        guard let photoView = photoView(at: location) else { return }
        
        let imageView = photoView.imageView
        if let snapshot = imageView.snapshotView(afterScreenUpdates: false) {
            self.snapshot = snapshot
            view.addSubview(snapshot)
            photoView.isHidden = true
            snapshot.frame = photoView.convert(imageView.frame, to: view)
            snapshotInitialFrame = snapshot.frame
        }
        panningPhotoView = photoView
    }
    
    private func updatePanToDismss(translation: CGPoint) {
        let initFrame = snapshotInitialFrame
        snapshot?.center = CGPoint(x: initFrame.midX,
                                   y: initFrame.midY + translation.y)
        let alpha = 1 - min(1, fabs(translation.y) / view.frame.height)
        backgroundView.alpha = alpha
    }
    
    private func completePanToDismiss(velocity: CGPoint, translation: CGPoint) {
        let progress = min(1, fabs(translation.y) / view.frame.height)
        let duration = PanGesture.dismissAnimationDuration * (1 - progress)
        let direction: CGFloat = translation.y > 0 ? 1 : -1
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            self.snapshot?.frame.origin.y = self.view.frame.height * direction
            self.backgroundView.alpha = 0
        }, completion: { (_) in
            self.snapshot?.removeFromSuperview()
            self.snapshot = nil
            self.snapshotInitialFrame = .zero
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    private func cancelPanToDismiss(velocity: CGPoint, translation: CGPoint) {
        let duration = PanGesture.dismissAnimationDuration
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            self.snapshot?.frame = self.snapshotInitialFrame
            self.backgroundView.alpha = 1
        }, completion: { (_) in
            self.panningPhotoView?.isHidden = false
            self.snapshot?.removeFromSuperview()
            self.snapshot = nil
            self.snapshotInitialFrame = .zero
        })
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPageIfNeeded()
        let scope = max(0, currentPageIndex - 1) ... min(currentPageIndex + 1, resources.count)
        scope.forEach { (index) in
            configPhotoView(atIndex: index)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recyclePhotoViewIfPossible()
    }
    
    private func updateCurrentPageIfNeeded() {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        if page != currentPageIndex && 0 ..< resources.count ~= page {
            currentPageIndex = page
        }
    }
    
    private func recyclePhotoViewIfPossible() {
        let visibleRect = view.bounds.offsetBy(dx: CGFloat(currentPageIndex) * scrollView.frame.width,
                                                     dy: 0)
        let offsetY = scrollView.frame.width
        var viewsToRemove = [PhotoView]()
        visiblePhotoViews.forEach {
            if $0.frame.maxX <= visibleRect.minX - offsetY
                || $0.frame.minX > visibleRect.maxX + offsetY {
                viewsToRemove.append($0)
                recycleReusablePhotoView($0)
            }
        }
        visiblePhotoViews = visiblePhotoViews.filter { !viewsToRemove.contains($0) }
    }
}

// Reuse PhotoView logic
extension PreviewerController {
    
    private func photoView(atIndex index: Int) -> PhotoView? {
        return visiblePhotoViews.filter { $0.tag == index }.first
    }
    
    private func dequeuePhotoView(atIndex index: Int) -> PhotoView {
        let ret: PhotoView
        let retFrame = view.bounds.offsetBy(dx: CGFloat(index) * scrollView.frame.width,
                                            dy: 0)
        if reusablePhotoViews.isEmpty {
            // initialize new one
            ret = PhotoView(frame: retFrame)
        } else {
            ret = reusablePhotoViews.removeFirst()
            ret.frame = retFrame
        }
        ret.tag = index
        return ret
    }
    
    private func recycleReusablePhotoView(_ photoView: PhotoView) {
        photoView.tag = -1
        photoView.removeFromSuperview()
        photoView.prepareForReuse()
        reusablePhotoViews.insert(photoView)
    }
}
