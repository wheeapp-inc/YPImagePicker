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
        return WheeThemeManager.shared.viewBackgroundColor
    }
}
extension YPSelectionsGalleryVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return WheeThemeManager.shared.viewBackgroundColor
    }
}
extension YPAlbumVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return WheeThemeManager.shared.viewBackgroundColor
    }
}
extension YPCropVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return WheeThemeManager.shared.viewBackgroundColor
    }
}

extension YPPhotoFiltersVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return WheeThemeManager.shared.viewBackgroundColor
    }
}

extension YPVideoFiltersVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return WheeThemeManager.shared.viewBackgroundColor
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
        view.setThemeManagerStyle()
        
        cameraVC?.didCancel = { [weak self] in
            self?._didFinishPicking?([], true)
        }
        cameraVC?.didSelectLibrary = { [weak self] in
            guard let `self` = self else { return }
            guard let libraryVC = self.libraryVC else { return }
            self.pushViewController(libraryVC, animated: true)
        }
        cameraVC?.didCapturePhoto = { [weak self] img in
            self?.onSelectItems([YPMediaItem.photo(p: YPMediaPhoto(image: img,
                                                                          fromCamera: true))])
        }
        
        // Select good mode
        if YPConfig.screens.contains(YPConfig.startOnScreen) {
            switch YPConfig.startOnScreen {
            case .library:
                viewControllers = [libraryVC]
            case .photo:
                viewControllers = [cameraVC]
            case .video:
                viewControllers = [libraryVC]
            }
        }
        
        setupLoadingView()
        navigationBar.isTranslucent = false
        configureViewForTheme()
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
        if let navBarTitleColor = navigationBar.titleTextAttributes?[.foregroundColor] as? UIColor {
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
            
            let attributes = navigationBar.titleTextAttributes
            if let attributes = attributes, let foregroundColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
                arrow.tintColor = foregroundColor
            }
            
            let button = UIButton()
            button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
            
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
        navVC.modalTransitionStyle = .coverVertical
        navVC.modalPresentationStyle = .overFullScreen
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
    
    func completeSelection(_ modifyedItems: [YPMediaItem], _ indexToModify: [Int], _ assets: [YPMediaItem]){
        var itemsDeepCopy = [YPMediaItem]()
        
        for index in 0...(assets.count - 1) {
            let item = assets[index]
            
            itemsDeepCopy.append(item)
        }
        
        
        for (index, element) in modifyedItems.enumerated(){
            let oldIndex = indexToModify[index]
            itemsDeepCopy[oldIndex] = element
        }
        self.didSelect(items: itemsDeepCopy)
    }
    
    func onSelectItems(_ assets: [YPMediaItem]) {
        
        var itemsToModify = [YPMediaItem]()
        var indexToModify = [Int]()
        
        for index in 0...(assets.count - 1) {
            let item = assets[index]
            
            switch assets[index] {
            case .photo(let photo):
                let photoIsGif = photo.asset?.isGIFImage() ?? false
                
                if !photoIsGif {
                    itemsToModify.append(item)
                    indexToModify.append(index)
                }
                break
            case .video(let video):
                itemsToModify.append(item)
                indexToModify.append(index)
                break
            }
        }
        
        if itemsToModify.isEmpty {
            self.didSelect(items: assets)
            return
        }
        
        let showsFilters = YPConfig.showsFilters
        
        // Use Fade transition instead of default push animation
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        self.view.layer.add(transition, forKey: nil)
        
        // Multiple items flow
        if itemsToModify.count > 1 {
            if YPConfig.library.skipSelectionsGallery {
                completeSelection(itemsToModify, indexToModify, assets)
                return
            } else {
                let selectionsGalleryVC = YPSelectionsGalleryVC(items: itemsToModify) {[weak self] _, items in
                    
                    self?.completeSelection(items, indexToModify, assets)
                }

                self.pushViewController(selectionsGalleryVC, animated: true)
                return
            }
        }
        
        // One item flow
        let item = itemsToModify.first!
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
                
                self.completeSelection([mediaItem], indexToModify, assets)
            }
            
            
            let showCrop: (YPMediaPhoto, @escaping (YPMediaPhoto) -> Void) -> Void = { [weak self] (photo: YPMediaPhoto, completion: @escaping (YPMediaPhoto)->Void) -> Void in
                guard let `self` = self else { return }
                
                
                if case let YPCropType.rectangle(ratio) = YPConfig.showsCrop {
                    let cropVC = YPCropVC(image: photo.image, ratio: ratio)
                    cropVC.didFinishCropping = { croppedImage in
                        
                        photo.modifiedImage = croppedImage
                        completion(photo)
                    }
                    
                    self.pushViewController(cropVC, animated: true)
                } else {
                    completion(photo)
                }
            }
            
            if showsFilters {
                let filterVC = YPPhotoFiltersVC(inputPhoto: photo,
                                                isFromSelectionVC: false)
                // Show filters and then crop
                filterVC.didSave = { outputMedia in
                    if case let YPMediaItem.photo(outputPhoto) = outputMedia {
                        showCrop(outputPhoto, completion)
                    }
                }
                
                self.pushViewController(filterVC, animated: true)
            } else {
                showCrop(photo, completion)
            }
        case .video(let video):
            if showsFilters {
                let videoFiltersVC = YPVideoFiltersVC.initWith(video: video,
                                                               isFromSelectionVC: false)
                videoFiltersVC.didSave = { [weak self] outputMedia in
                    self?.completeSelection([outputMedia], indexToModify, assets)
                }
                
                self.pushViewController(videoFiltersVC, animated: true)
            } else {
                self.completeSelection([YPMediaItem.video(v: video)], indexToModify, assets)
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

extension WYPImagePicker {
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            WheeThemeManager.shared.theme = view.traitCollection.userInterfaceStyle == .dark ? .dark : .light
            configureViewForTheme()
            NotificationCenter.default.post(name: .wheeThemeChanged, object: nil, userInfo: nil)
        }
    }
    
    func configureViewForTheme() {
        navigationBar.barTintColor = WheeThemeManager.shared.viewBackgroundColor
        navigationBar.tintColor = WheeThemeManager.shared.titleColor
        navigationBar.titleTextAttributes = [.foregroundColor: WheeThemeManager.shared.titleColor]
        updateUI()
    }
}

enum WheeTheme {
    case dark
    case light
}

extension Notification.Name {
    static let wheeThemeChanged = Notification.Name("wheeThemeChanged")
}

class WheeThemeManager {
    
    static let shared = WheeThemeManager()
    
    var viewBackgroundColor: UIColor = .black
    var viewBackgroundContrastColor: UIColor = .black
    var titleColor: UIColor = .black
    
    var theme: WheeTheme = .light {
        didSet {
            viewBackgroundColor = theme == .dark ? .black : .white
            viewBackgroundContrastColor = theme == .dark ? UIColor.init(r: 28.0/255.0, g: 28.0/255.0, b: 30.0/255.0) : .white
            titleColor = theme == .dark ? UIColor.white.withAlphaComponent(0.8) : .black
        }
    }
}

extension UIView {
    func registerListenerForThemeChange(callBack selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: .wheeThemeChanged, object: nil)
    }
}

extension UIViewController {
    func registerListenerForThemeChange(callBack selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: .wheeThemeChanged, object: nil)
    }
}

extension UIView {
    func setThemeManagerStyle() {
        // decide theme from system dark mode settings
        // TODO: override from user settings
        if #available(iOS 13.0, *) {
            WheeThemeManager.shared.theme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        } else {
            WheeThemeManager.shared.theme = .light
        }
    }
}
