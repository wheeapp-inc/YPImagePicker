//
//  WYPImagePicker.swift
//  WheeApp
//
//  Created by Tymofii Dolenko on 1/7/19.
//  Copyright © 2019 Whee Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Stevia

extension YPLibraryVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}
extension YPSelectionsGalleryVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}
extension YPAlbumVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}
extension YPCropVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}

extension YPPhotoFiltersVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}

extension YPVideoFiltersVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .white
    }
}

public class WYPImagePicker: ColorableNavigationController {
    
    let albumsManager = YPAlbumsManager()
    
    private var _didFinishPicking: (([YPMediaItem], Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: [YPMediaItem], _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
    public weak var imagePickerDelegate: YPImagePickerDelegate?
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return YPImagePickerConfiguration.shared.preferredStatusBarStyle
    }
    
    // This nifty little trick enables us to call the single version of the callbacks.
    // This keeps the backwards compatibility keeps the api as simple as possible.
    // Multiple selection becomes available as an opt-in.
    private func didSelect(items: [YPMediaItem]) {
        _didFinishPicking?(items, false)
    }
    
    enum Mode {
        case library
        case camera
    }
    
    var mode = Mode.camera
    
    let loadingView = YPLoadingView()
    private let libraryVC: YPLibraryVC!
    private let cameraVC: WYPCameraVC!
    
    var currentController: UIViewController {
        return controllerFor(mode: mode)
    }
    
    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        self.init(configuration: YPImagePickerConfiguration.shared)
    }
    
    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        YPImagePickerConfiguration.shared = configuration
        libraryVC = YPLibraryVC()
        cameraVC = WYPCameraVC()
        super.init(nibName: nil, bundle: nil)
        libraryVC.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        cameraVC?.didCancel = { [weak self] in
            self?._didFinishPicking?([], true)
        }
        cameraVC?.didSelectLibrary = { [weak self] in
            guard let libraryVC = self?.libraryVC else { return }
            self?.pushViewController(libraryVC, animated: true)
        }
        cameraVC?.didCapturePhoto = { [weak self] img in
            self?.onSelectItems([YPMediaItem.photo(p: YPMediaPhoto(image: img,
                                                                          fromCamera: true))])
        }
        
        viewControllers = [cameraVC]
        setupLoadingView()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = .black
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateMode(with: currentController)
    }
    
    deinit {
        print("Picker deinited 👍")
    }
    
    func modeFor(vc: UIViewController) -> Mode {
        switch vc {
        case is YPLibraryVC:
            return .library
        case is WYPCameraVC:
            return .camera
        default:
            return .camera
        }
    }
    
    func controllerFor(mode: Mode) -> UIViewController {
        switch mode {
        case .camera:
            return cameraVC
        case .library:
            return libraryVC
        }
    }
    
    func updateMode(with vc: UIViewController) {
        stopCurrentCamera()
        
        // Set new mode
        mode = modeFor(vc: vc)
        
        // Re-trigger permission check
        if let vc = vc as? YPLibraryVC {
            vc.checkPermission()
        } else if let cameraVC = vc as? WYPCameraVC {
            cameraVC.start()
        } else if let videoVC = vc as? YPVideoCaptureVC {
            videoVC.start()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.updateUI()
        }
    }
    
    func stopCurrentCamera() {
        switch mode {
        case .library:
            libraryVC?.pausePlayer()
        case .camera:
            cameraVC?.stopCamera()
        }
    }
    
    func updateUI() {
        let vc = currentController
        
        // Update Nav Bar state.
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        
        switch mode {
        case .library:
            self.setTitleViewWithTitle(aTitle: self.libraryVC?.title ?? "")
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                                   style: .done,
                                                                   target: self,
                                                                   action: #selector(done))
            vc.navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
            
            // Disable Next Button until minNumberOfItems is reached.
            vc.navigationItem.rightBarButtonItem?.isEnabled = libraryVC!.selection.count >= YPConfig.library.minNumberOfItems || libraryVC.firstSelection != nil
            
        case .camera:
            setTitleViewFlashIcon()
            vc.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func setTitleViewFlashIcon() {
        let vc = currentController
        // Update Nav Bar state.
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        vc.navigationItem.leftBarButtonItem?.tintColor = .white
        
        vc.navigationItem.titleView = cameraVC.flashButton
        
        cameraVC.flashButton.centerVertically()
        cameraVC.flashButton.size(24).centerHorizontally()
    }
    
    func setTitleViewWithTitle(aTitle: String) {
        let vc = currentController
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        
        let label = UILabel()
        label.text = aTitle
        // Use standard font by default.
        label.font = UIFont.boldSystemFont(ofSize: 17)
        
        // Use custom font if set by user.
        if let navBarTitleFont = UINavigationBar.appearance().titleTextAttributes?[.font] as? UIFont {
            // Use custom font if set by user.
            label.font = navBarTitleFont
        }
        // Use custom textColor if set by user.
        if let navBarTitleColor = UINavigationBar.appearance().titleTextAttributes?[.foregroundColor] as? UIColor {
            label.textColor = navBarTitleColor
        }
        
        if YPConfig.library.options != nil {
            titleView.sv(
                label
            )
            |-(>=8)-label.centerHorizontally()-(>=8)-|
            align(horizontally: label)
        } else {
            let arrow = UIImageView()
            arrow.image = YPConfig.icons.arrowDownIcon
            
            let attributes = UINavigationBar.appearance().titleTextAttributes
            if let attributes = attributes, let foregroundColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
                arrow.tintColor = foregroundColor
            }
            
            let button = UIButton()
            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
            button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)
            
            titleView.sv(
                label,
                arrow,
                button
            )
            button.fillContainer()
            |-(>=8)-label.centerHorizontally()-arrow-(>=8)-|
            align(horizontally: label-arrow)
        }
        
        label.firstBaselineAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -14).isActive = true
        
        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        vc.navigationItem.titleView = titleView
    }
    
    private func setupLoadingView() {
        view.sv(
            loadingView
        )
        loadingView.fillContainer()
        loadingView.alpha = 0
    }
    
    @objc
    func navBarTapped() {
        let vc = YPAlbumVC(albumsManager: albumsManager)
        let navVC = UINavigationController(rootViewController: vc)
        
        vc.didSelectAlbum = { [weak self] album in
            self?.libraryVC?.setAlbum(album)
            self?.libraryVC?.title = album.title
            self?.libraryVC?.refreshMediaRequest()
            self?.setTitleViewWithTitle(aTitle: album.title)
            self?.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    @objc
    func close() {
        // Cancelling exporting of all videos
        if let libraryVC = libraryVC {
            libraryVC.mediaManager.forseCancelExporting()
        }
        self._didFinishPicking?([],true)
    }
    
    // When pressing "Next"
    @objc
    func done() {
        guard let libraryVC = libraryVC else { print("⚠️ YPPickerVC >>> YPLibraryVC deallocated"); return }
        
        libraryVC.doAfterPermissionCheck { [weak self] in
            libraryVC.selectedMedia(photoCallback: { photo in
                self?.onSelectItems([YPMediaItem.photo(p: photo)])
            }, videoCallback: { video in
                self?.onSelectItems([YPMediaItem
                    .video(v: video)])
            }, multipleItemsCallback: { items in
                self?.onSelectItems(items)
            })
        }
    }
}

extension WYPImagePicker {
    func onSelectItems(_ items: [YPMediaItem]) {
        let showsFilters = YPConfig.showsFilters
        
        // Use Fade transition instead of default push animation
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        self.view.layer.add(transition, forKey: nil)
        
        // Multiple items flow
        if items.count > 1 {
            if YPConfig.library.skipSelectionsGallery {
                self.didSelect(items: items)
                return
            } else {
                let selectionsGalleryVC = YPSelectionsGalleryVC(items: items) { _, items in
                    self.didSelect(items: items)
                }
                
                self.pushViewController(selectionsGalleryVC, animated: true)
                return
            }
        }
        
        // One item flow
        let item = items.first!
        switch item {
        case .photo(let photo):
            let completion = { [weak self] (photo: YPMediaPhoto) in
                guard let `self` = self else { return }
                let mediaItem = YPMediaItem.photo(p: photo)
                // Save new image or existing but modified, to the photo album.
                if YPConfig.shouldSaveNewPicturesToAlbum {
                    let isModified = photo.modifiedImage != nil
                    if photo.fromCamera || (!photo.fromCamera && isModified) {
                        YPPhotoSaver.trySaveImage(photo.image, inAlbumNamed: YPConfig.albumName)
                    }
                }
                self.didSelect(items: [mediaItem])
            }
            
            weak var _self = self
            func showCropVC(photo: YPMediaPhoto, completion: @escaping (_ aphoto: YPMediaPhoto) -> Void) {
                guard let `self` = _self else { return }
                if case let YPCropType.rectangle(ratio) = YPConfig.showsCrop {
                    let cropVC = YPCropVC(image: photo.image, ratio: ratio)
                    cropVC.didFinishCropping = { croppedImage in
                        photo.modifiedImage = croppedImage
                        completion(photo)
                    }
                    
                    _self.pushViewController(cropVC, animated: true)
                } else {
                    completion(photo)
                }
            }
            
            if showsFilters {
                let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                                                isFromSelectionVC: false)
                // Show filters and then crop
                filterVC.didSave = { [weak self] outputMedia in
                    guard let `self` = self else { return }
                    if case let YPMediaItem.photo(outputPhoto) = outputMedia {
                        showCropVC(photo: outputPhoto, completion: completion)
                    }
                }
                
                self.pushViewController(filterVC, animated: true)
            } else {
                showCropVC(photo: photo, completion: completion)
            }
        case .video(let video):
            if showsFilters {
                let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                                                               isFromSelectionVC: false)
                videoFiltersVC.didSave = { [weak self] outputMedia in
                    self?.didSelect(items: [outputMedia])
                }
                
                self.pushViewController(videoFiltersVC, animated: true)
            } else {
                self.didSelect(items: [YPMediaItem.video(v: video)])
            }
        }
    }
}

extension WYPImagePicker: ImagePickerDelegate {
    func noPhotos() {
        self.imagePickerDelegate?.noPhotos()
    }
}

extension WYPImagePicker: YPLibraryViewDelegate {
    
    public func libraryViewStartedLoading() {
        libraryVC?.isProcessing = true
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.libraryVC?.v.fadeInLoader()
            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
            self.updateUI()
        }
    }
    
    public func libraryViewFinishedLoading() {
        libraryVC?.isProcessing = false
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.libraryVC?.v.hideLoader()
            self.updateUI()
        }
    }
    
    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.updateUI()
        }
    }
    
    public func noPhotosForOptions() {
        self.dismiss(animated: true) { [weak self] in
            guard let `self` = self else { return }
            self.noPhotos()
        }
    }
}

extension YPLibraryVC {
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.navigationController as? WYPImagePicker)?.updateMode(with: self)
    }
    
}

extension WYPCameraVC {
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.navigationController as? WYPImagePicker)?.updateMode(with: self)
        v.shotButton.isEnabled = true
    }
    
}
