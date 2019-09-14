//
//  PHAssetExtention.swift
//  YPImagePicker
//
//  Created by Philip Dolenko on 9/14/19.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import AVFoundation


extension PHAsset {
    func isGIFImage() -> Bool {
        
        var value = false
        
        if let identifier = self.value(forKey: "uniformTypeIdentifier") as? String
        {
            if identifier == kUTTypeGIF as String
            {
                value = true
            }
        }
        
        return value
    }
    
    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
