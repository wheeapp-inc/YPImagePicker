//
//  WYPLibraryView.swift
//  YPImagePicker
//
//  Created by Tymofii Dolenko on 1/26/19.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

final class WYPLibraryView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let maxNumberWarningView = UIView()
    let maxNumberWarningLabel = UILabel()
    let progressView = UIProgressView()
    let line = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sv(
            line
        )
        
        layout(
            |line| ~ 1
        )
        
        line.backgroundColor = .white
        
        setupMaxNumberOfItemsView()
        setupProgressBarView()
    }
    
    /// At the bottom there is a view that is visible when selected a limit of items with multiple selection
    func setupMaxNumberOfItemsView() {
        // View Hierarchy
        sv(
            maxNumberWarningView.sv(
                maxNumberWarningLabel
            )
        )
        
        // Layout
        |maxNumberWarningView|.bottom(0)
        if #available(iOS 11.0, *) {
            maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
            maxNumberWarningLabel.centerHorizontally().top(11)
        } else {
            maxNumberWarningView.height(40)
            maxNumberWarningLabel.centerInContainer()
        }
        
        // Style
        maxNumberWarningView.backgroundColor = UIColor(r: 246, g: 248, b: 248)
        maxNumberWarningLabel.font = UIFont(name: "Helvetica Neue", size: 14)
        maxNumberWarningView.isHidden = true
    }
    
    /// When video is processing this bar appears
    func setupProgressBarView() {
        sv(
            progressView
        )
        
        progressView.height(5)
        progressView.Top == line.Top
        progressView.Width == line.Width
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = YPConfig.colors.progressBarTrackColor
        progressView.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        progressView.isHidden = true
        progressView.isUserInteractionEnabled = false
    }
}

// MARK: - UI Helpers

extension WYPLibraryView {
    
    class func xibView() -> YPLibraryView? {
        let bundle = Bundle(for: YPPickerVC.self)
        let nib = UINib(nibName: "YPLibraryView",
                        bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? YPLibraryView
        return xibView
    }
    
    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let `self` = self else { return }
            self.progressView.layoutIfNeeded()
        }
    }
    
    func cellSize() -> CGSize {
        let size = UIScreen.main.bounds.width/4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }
}
