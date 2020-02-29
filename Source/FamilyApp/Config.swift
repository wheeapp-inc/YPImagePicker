//
//  WYPImagePicker+Config.swift
//  YPImagePicker
//
//  Created by Tymofii Dolenko on 29.02.2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit

public enum WYPImagePickerMode {
    case camera
    case photo
    case video
}

public extension YPImagePickerConfiguration {
    
    static func wheeConfig(for startScreen: WYPImagePickerMode) -> YPImagePickerConfiguration {
        var config = YPImagePickerConfiguration()
        
        switch startScreen {
        case .camera:
            config.library.mediaType = .photoAndVideo
            config.startOnScreen = .photo
        case .photo:
            config.library.mediaType = .photo
            config.startOnScreen = .library
        case .video:
            config.library.mediaType = .video
            config.startOnScreen = .library
        }
        
        config.hidesBottomBar = true
        config.library.maxNumberOfItems = 10
        
        config.onlySquareImagesFromCamera = false
        
        config.hidesStatusBar = false
        
        config.colors.tintColor = #colorLiteral(red: 0.2039999962, green: 0.5960000157, blue: 0.8590000272, alpha: 1)
        config.colors.photoVideoScreenBackground = .black
        
        config.library.showsGrid = false
        config.library.isMultiselectEnabledByDefault = true
        config.library.shouldCropToSquareByDefault = false
        return config
    }
    
}

