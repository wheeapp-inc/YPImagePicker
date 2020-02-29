//
//  ExampleViewController.swift
//  YPImagePickerExample
//
//  Created by Sacha DSO on 17/03/2017.
//  Copyright © 2017 Octopepper. All rights reserved.
//

import UIKit
import YPImagePicker
import AVFoundation
import AVKit
import Photos

class ExampleViewController: UIViewController {
    var selectedItems = [YPMediaItem]()

    let selectedImageV = UIImageView()
    let pickButton = UIButton()
    let resultsButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        selectedImageV.contentMode = .scaleAspectFit
        selectedImageV.frame = CGRect(x: 0,
                                      y: 0,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.height * 0.45)
        view.addSubview(selectedImageV)

        pickButton.setTitle("Pick", for: .normal)
        pickButton.setTitleColor(.black, for: .normal)
        pickButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        pickButton.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
        view.addSubview(pickButton)
        pickButton.center = view.center

        resultsButton.setTitle("Show selected", for: .normal)
        resultsButton.setTitleColor(.black, for: .normal)
        resultsButton.frame = CGRect(x: 0,
                                     y: UIScreen.main.bounds.height - 100,
                                     width: UIScreen.main.bounds.width,
                                     height: 100)
        resultsButton.addTarget(self, action: #selector(showResults), for: .touchUpInside)
        view.addSubview(resultsButton)
    }

    @objc
    func showResults() {
        if selectedItems.count > 0 {
            let gallery = YPSelectionsGalleryVC(items: selectedItems) { g, _ in
                g.dismiss(animated: true, completion: nil)
            }
            let navVC = UINavigationController(rootViewController: gallery)
            navVC.modalTransitionStyle = .coverVertical
            navVC.modalPresentationStyle = .overFullScreen
            self.present(navVC, animated: true, completion: nil)
        } else {
            print("No items selected yet.")
        }
    }

    // MARK: - Configuration
    @objc
    func showPicker() {
        let picker = WYPImagePicker(startOnScreen: .photo)

        /* Multiple media implementation */
        picker.didFinishPicking { [unowned picker] items, cancelled in
            
            if cancelled {
                print("Picker was canceled")
                picker.dismiss(animated: true, completion: nil)
                return
            }
            _ = items.map { print("🧀 \($0)") }
            
            self.selectedItems = items
            if let firstItem = items.first {
                switch firstItem {
                case .photo(let photo):
                    self.selectedImageV.image = photo.image
                    picker.dismiss(animated: true, completion: nil)
                case .video(let video):
                    self.selectedImageV.image = video.thumbnail
                    
                    let assetURL = video.url
                    let playerVC = AVPlayerViewController()
                    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
                    playerVC.player = player
                    playerVC.modalTransitionStyle = .coverVertical
                    playerVC.modalPresentationStyle = .overFullScreen
                    picker.dismiss(animated: true, completion: { [weak self] in
                        self?.present(playerVC, animated: true, completion: nil)
                        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
                    })
                }
            }
        }

        picker.modalTransitionStyle = .coverVertical
        picker.modalPresentationStyle = .overFullScreen
        
        present(picker, animated: true, completion: nil)
    }
}

// Support methods
extension ExampleViewController {
    /* Gives a resolution for the video by URL */
    func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}

public extension WYPImagePicker {
    
    convenience init(startOnScreen: WYPImagePickerMode = .camera) {
        self.init(configuration: .wheeConfig(for: startOnScreen))
        modalTransitionStyle = .coverVertical
        modalPresentationStyle = .overFullScreen
    }

    convenience init(startOnScreen: WYPImagePickerMode = .camera, maxNumberOfItems: Int) {
        var config: YPImagePickerConfiguration = .wheeConfig(for: startOnScreen)
        config.library.maxNumberOfItems = maxNumberOfItems
        config.library.isMultiselectEnabledByDefault = false
        self.init(configuration: config)
    }
}
