//
//  WYPCameraView.swift
//  ActiveLabel
//
//  Created by Tymofii Dolenko on 1/7/19.
//

import UIKit
import Stevia

class WYPCameraView: UIView, UIGestureRecognizerDelegate {
    
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    let previewViewContainer = UIView()
    let buttonsContainer = UIView()
    let flipButton = UIButton()
    let shotButton = UIButton()
    let libraryButton = UIButton()
    
    convenience init(overlayView: UIView? = nil) {
        self.init(frame: .zero)
        
        if let overlayView = overlayView {
            // View Hierarchy
            sv(
                previewViewContainer,
                overlayView,
                buttonsContainer.sv(
                    flipButton,
                    shotButton,
                    libraryButton
                )
            )
        } else {
            // View Hierarchy
            sv(
                previewViewContainer,
                buttonsContainer.sv(
                    flipButton,
                    shotButton,
                    libraryButton
                )
            )
        }
        
        // Layout
        let isIphone4 = UIScreen.main.bounds.height == 480
        
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        layout(
            0,
            |-sideMargin-previewViewContainer-sideMargin-|,
            0,
            |buttonsContainer|,
            0
        )
        
        previewViewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewViewContainer.addConstraint(NSLayoutConstraint(item: previewViewContainer, attribute: .height, relatedBy: .equal, toItem: previewViewContainer, attribute: .width, multiplier: 4/3, constant: 0))
        
        overlayView?.followEdges(previewViewContainer)
        
        buttonsContainer.Top == previewViewContainer.Bottom
        
        flipButton.centerVertically()
        |-(40+sideMargin)-flipButton.size(40)
        
        shotButton.centerVertically()
        shotButton.size(76).centerHorizontally()
        
        libraryButton.centerVertically()
        libraryButton.height(40).width(60)-(40+sideMargin)-|
        
        // Style
        buttonsContainer.backgroundColor = YPConfig.colors.photoVideoScreenBackground
        backgroundColor = YPConfig.colors.photoVideoScreenBackground
        previewViewContainer.backgroundColor = .black
        
        libraryButton.setTitle(YPConfig.wordings.libraryTitle, for: .normal)
        
        
        libraryButton.titleLabel?.font = YPConfig.fonts.buttonFont
        
        
        libraryButton.setTitleColor(.white, for: .normal)
        
        flipButton.setImage(YPConfig.icons.loopIcon, for: .normal)
        shotButton.setImage(YPConfig.icons.capturePhotoImage, for: .normal)
    }
}

