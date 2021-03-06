//
//  ViewController.swift
//  JXLook
//
//  Created by Yung-Luen Lan on 2021/1/18.
//

import Cocoa
import os

class ViewController: NSViewController {
    
    static let minSize = CGSize(width: 200, height: 200)
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var clipView: CenterClipView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var zoomToFit: Bool = true {
        didSet {
            clipView.centersDocumentView = !zoomToFit
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.allowsMagnification = true
    }

    override func viewWillAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.willMagnify), name: NSScrollView.willStartLiveMagnifyNotification, object: self.scrollView)
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var representedObject: Any? {
        didSet {
            if let doc = representedObject as? Document, let img = doc.image {
                self.imageView.image = img

                let window = self.view.window!
                let windowTitle = window.frame.height - scrollView.frame.height
                let maxWindowFrame = window.constrainFrameRect(CGRect(origin: CGPoint.zero, size: CGSize(width: img.size.width, height: img.size.height + windowTitle)), to: window.screen)
                let maxContentSize = CGSize(width: maxWindowFrame.width, height: maxWindowFrame.height - windowTitle)

                window.minSize = ViewController.minSize
                window.minSize.height += windowTitle
                // less than min size
                if img.size.width <= ViewController.minSize.width && img.size.height <= ViewController.minSize.height
                {
                    self.zoomToFit = false
                    window.setContentSize(ViewController.minSize)
                    imageView.frame = CGRect(origin: .zero, size: img.size)
                } else if img.size.width > maxContentSize.width || img.size.height > maxContentSize.height
                { // at least one side larger than max window dimension, needs to scale down
                    self.zoomToFit = true
                    let ratio = min((maxContentSize.width) / img.size.width , (maxContentSize.height) / img.size.height)
                    let newSize = CGSize(width: max(ViewController.minSize.width, img.size.width * ratio), height: max(ViewController.minSize.height, img.size.height * ratio))
                    window.setContentSize(CGSize(width: newSize.width - 2, height: newSize.height - 2))
                    imageView.frame = CGRect(origin: CGPoint.zero, size: newSize)
                } else
                {
                    self.zoomToFit = true
                    window.setContentSize(CGSize(width: maxContentSize.width, height: maxContentSize.height))
                    imageView.frame = CGRect(origin: CGPoint.zero, size: maxContentSize)
                }
            }
        }
    }
    
    override func viewDidLayout() {
        if zoomToFit {
            scrollView.magnification = 1.0
            imageView.frame.size = scrollView.frame.size
        }
    }
    
    @objc func willMagnify(_ notification: NSNotification) {
        self.zoomToFit = false
    }
    
    @IBAction func zoomImageToActualSize(_ sender: Any!) {
        if let doc = self.representedObject as? Document, let img = doc.image {
            zoomToFit = false
            imageView.frame.size = img.size
            scrollView.magnification = 1.0
            // TODO: adjust the window size
        }
    }
    
    @IBAction func zoomImageToFit(_ sender: Any!) {
        zoomToFit = true
        self.viewDidLayout()
    }
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.zoomImageToFit) {
            menuItem.state = zoomToFit ? .on : .off
            return !zoomToFit
        } else if menuItem.action == #selector(self.zoomImageToActualSize) {
            print(self.scrollView.magnification)
            if let doc = self.representedObject as? Document, let img = doc.image {
                let isActualSize = self.scrollView.magnification == 1.0 && self.imageView.frame.size == img.size
                menuItem.state = isActualSize ? .on : .off
                return !isActualSize
            }
            return false;
        }
        return true
    }
}

