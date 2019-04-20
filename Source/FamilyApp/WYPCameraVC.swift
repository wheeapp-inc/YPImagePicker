//
//  WYPImagePicker.swift
//  ActiveLabel
//
//  Created by Tymofii Dolenko on 1/7/19.
//

import UIKit
import AVFoundation
import Photos

public class WYPCameraVC: UIViewController, YPPermissionCheckable, UIGestureRecognizerDelegate {
    
    public var didCancel: (()->())?
    public var didSelectLibrary: (()->())?
    public var didCapturePhoto: ((UIImage) -> Void)?
    let photoCapture = newPhotoCapture()
    let v: WYPCameraView!
    let flashButton: UIButton!
    override public func loadView() { view = v }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public required init() {
        self.v = WYPCameraView(overlayView: YPConfig.overlayView)
        self.flashButton = UIButton()
        super.init(nibName: nil, bundle: nil)
        title = YPConfig.wordings.cameraTitle
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        flashButton.setImage(YPConfig.icons.flashOffIcon, for: .normal)
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)

        v.libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        
        // Focus
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusTapped(_:)))
        tapRecognizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
    }
    
    func start() {
        doAfterPermissionCheck { [weak self] in
            guard let strongSelf = self else {
                return
            }
            self?.photoCapture.start(with: strongSelf.v.previewViewContainer, completion: {
                DispatchQueue.main.async {
                    self?.refreshFlashButton()
                }
            })
        }
    }
    
    @objc
    func cancelTapped() {
        didCancel?()
    }
    
    @objc
    func libraryTapped() {
        didSelectLibrary?()
    }
    
    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        doAfterPermissionCheck { [weak self] in
            self?.focus(recognizer: recognizer)
        }
    }
    
    func focus(recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: v.previewViewContainer)
        
        // Focus the capture
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        photoCapture.focus(on: newPoint)
        
        // Animate focus view
        v.focusView.center = point
        YPHelper.configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        YPHelper.animateFocusView(v.focusView)
    }
    
    func stopCamera() {
        photoCapture.stopCamera()
    }
    
    @objc
    func flipButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.photoCapture.flipCamera()
            DispatchQueue.main.async {
                self?.refreshFlashButton()
            }
        }
    }
    
    @objc
    func shotButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.shoot()
        }
    }
    
    func shoot() {
        // Prevent from tapping multiple times in a row
        // causing a crash
        v.shotButton.isEnabled = false
        
        photoCapture.shoot { [weak self] imageData in
            
            guard let `self` = self else { return }
            
            guard let data = imageData else {
                self.v.shotButton.isEnabled = true
                return
            }
            
            guard let shotImage = UIImage(data: data) else {
                self.v.shotButton.isEnabled = true
                return
            }
            
            self.photoCapture.stopCamera()
            
            var image = shotImage
            // Crop the image if the output needs to be square.
            if YPConfig.onlySquareImagesFromCamera {
                image = self.cropImageToSquare(image)
            }
            
            // Flip image if taken form the front camera.
            if let device = self.photoCapture.device, device.position == .front {
                let noOrietationImage = image.resetOrientation()
                guard let cgImage = noOrietationImage.cgImage else { return }
                image = UIImage.init(cgImage: cgImage, scale: noOrietationImage.scale, orientation: UIImage.Orientation.upMirrored)
            }
            
            DispatchQueue.main.async {
                let noOrietationImage = image.resetOrientation()
                self.didCapturePhoto?(noOrietationImage.resizedImageIfNeeded())
            }
        }
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        var imageWidth = image.size.width
        var imageHeight = image.size.height
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            // Swap width and height if orientation is landscape
            imageWidth = image.size.height
            imageHeight = image.size.width
        default:
            break
        }
        
        // The center coordinate along Y axis
        let rcy = imageHeight * 0.5
        let rect = CGRect(x: rcy - imageWidth * 0.5, y: 0, width: imageWidth, height: imageWidth)
        let imageRef = image.cgImage?.cropping(to: rect)
        return UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
    }
    
    // Used when image is taken from the front camera.
    func flipImage(image: UIImage!) -> UIImage! {
        let imageSize: CGSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.rotate(by: CGFloat(Double.pi/2.0))
        ctx.translateBy(x: 0, y: -imageSize.width)
        ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
        ctx.draw(image.cgImage!, in: CGRect(x: 0.0,
                                            y: 0.0,
                                            width: imageSize.width,
                                            height: imageSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc
    func flashButtonTapped() {
        photoCapture.tryToggleFlash()
        refreshFlashButton()
    }
    
    func refreshFlashButton() {
        let flashImage = photoCapture.currentFlashMode.flashImage()
        flashButton.setImage(flashImage, for: .normal)
        flashButton.isHidden = !photoCapture.hasFlash
    }

}

extension WYPCameraVC: NavigationBarColorable {
    public var navigationBarTintColor: UIColor? {
        return .black
    }
}
