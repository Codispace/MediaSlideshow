//
//  FullScreenSlideshowViewController.swift
//  MediaSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

@objcMembers
open class FullScreenSlideshowViewController: UIViewController {

    open var slideshow: MediaSlideshow = {
        let slideshow = MediaSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFit
        let pageIndicator = UIPageControl()
        pageIndicator.currentPageIndicatorTintColor = UIColor.darkGray
        pageIndicator.pageIndicatorTintColor = UIColor.lightGray
        pageIndicator.hidesForSinglePage = true
        slideshow.pageIndicator = pageIndicator
        slideshow.pageIndicatorPosition = PageIndicatorPosition(horizontal: .center, vertical: .bottom)
        // turns off the timer
        slideshow.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]

        return slideshow
    }()

    /// Close button 
    open var closeButton = UIButton()
    
    public var isHideCloseButtonForVideo = false

    /// Close button frame
    open var closeButtonFrame: CGRect?

    /// Closure called on page selection
    open var pageSelected: ((_ page: Int) -> Void)?

    /// Index of initial image
    open var initialPage: Int = 0

    /// Datasource
    open var sources: [MediaSource] {
        slideshow.sources
    }

    /// Background color
    open var backgroundColor = UIColor.white

    /// Enables/disable zoom
    open var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }

    fileprivate var isInit = true

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        slideshow.delegate = self
        self.modalPresentationStyle = .custom
        if #available(iOS 13.0, *) {
            // Use KVC to set the value to preserve backwards compatiblity with Xcode < 11
            self.setValue(true, forKey: "modalInPresentation")
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor
        slideshow.backgroundColor = backgroundColor

        view.addSubview(slideshow)

        // close button configuration
        if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "xmark"), for: UIControlState())
            closeButton.tintColor = .black
        } else {
            // Fallback on earlier versions
        }
        closeButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: UIControlEvents.touchUpInside)
        view.addSubview(closeButton)
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isInit {
            isInit = false
            slideshow.setCurrentPage(initialPage, animated: false)
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        slideshow.slides.forEach { $0.willBeRemoved() }

        // Prevents broken dismiss transition when image is zoomed in
        if let zoomable = slideshow.currentSlide as? ZoomableMediaSlideshowSlide {
            zoomable.zoomOut()
        }
    }

    open override func viewDidLayoutSubviews() {
        if !isBeingDismissed {
            let safeAreaInsets: UIEdgeInsets
            if #available(iOS 11.0, *) {
                safeAreaInsets = view.safeAreaInsets
            } else {
                safeAreaInsets = UIEdgeInsets.zero
            }

            closeButton.frame = closeButtonFrame ?? CGRect(x: max(10, safeAreaInsets.left), y: max(10, safeAreaInsets.top), width: 40, height: 40)
        }

        slideshow.frame = view.frame
    }

    public func setMediaSources(_ sources: [MediaSource]) {
        slideshow.setMediaSources(sources)
    }

    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.currentPage)
        }

        dismiss(animated: true, completion: nil)
    }
}
extension FullScreenSlideshowViewController: MediaSlideshowDelegate {
    public func mediaSlideshow(_ mediaSlideshow: MediaSlideshow, didChangeCurrentPageTo page: Int) {
        if isHideCloseButtonForVideo {
            let isAVSource = sources[page] is AVSource
            UIView.animate(withDuration: 0.3) {
                self.slideshow.pageIndicator?.view.alpha = isAVSource ? 0.0 : 1.0
                self.closeButton.alpha = isAVSource ? 0.0 : 1.0
            }
        }
    }
}
