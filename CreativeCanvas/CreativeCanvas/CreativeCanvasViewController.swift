//
//  ViewController.swift
//  CreativeCanvas
//
//  Created by Harmony Radley on 7/27/20.
//  Copyright © 2020 Harmony Radley. All rights reserved.
//

import UIKit
import PencilKit
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

class CreativeCanvasViewController: UIViewController {

    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var imageView: UIImageView!

    let canvasWidth: CGFloat = 770
    let canvasOverscrollHight: CGFloat = 500
    // Save drawing
    var drawing = PKDrawing()

    // Image Properties
    private let context = CIContext(options: nil)

    var originalImage: UIImage? {
        didSet {
            // We want to scale down the image to make it easier to filter until the user is ready to save the image
            guard let image = originalImage else { return }

            // height and width of the image view
            var scaledSize = imageView.bounds.size

            // 1, 2, or 3
            let scale = UIScreen.main.scale

            scaledSize = CGSize(width: scaledSize.width * scale,
                                height: scaledSize.height * scale)

            // `imageByScaling` is coming from the UIImage+Scaling.swift
            let scaledImage = image.imageByScaling(toSize: scaledSize)

            self.scaledImage = scaledImage
        }
    }

    var scaledImage: UIImage? {
        didSet {
            imageView.image = scaledImage
        }
    }

    // MARK: - View Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.delegate = self
        canvasView.drawing = drawing
        originalImage = imageView.image

        canvasView.alwaysBounceVertical = true
        canvasView.allowsFingerDrawing = true

        if let window = parent?.view.window,
            let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)

            canvasView.becomeFirstResponder()
        }
    }

    // rotate our device, it will reset the canvas view
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale

        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }

    // MARK: - Pencil Kit Methods
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeForDrawing()
    }

    func updateContentSizeForDrawing() {
        let drawing = canvasView.drawing
        let contentHeight: CGFloat

        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + self.canvasOverscrollHight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }

        canvasView.contentSize = CGSize(width: canvasWidth * canvasView.zoomScale, height: contentHeight)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    func saveButtonTappedAlert() {
        let alert = UIAlertController(title: "Great Drawing!", message: "Your drawing has been saved to your camera roll!", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)

    }

    // MARK: - Core Image Methods

    func image(byFiltering image: UIImage) -> UIImage {
           guard let cgImage = image.cgImage else { return image}

           let ciImage = CIImage(cgImage: cgImage)

           let filter = CIFilter.photoEffectNoir()

           filter.inputImage = ciImage

           guard let outputImage = filter.outputImage else { return image }

           guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }

           return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
       }

    func updateImage() {
        if let originalImage = originalImage {

            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)

            imageView.image = image(byFiltering: originalImage.imageByScaling(toSize: scaledSize)!)

        } else {
            imageView.image = nil
        }
    }
    func presentImagePicker() {

            // Make sure the photo library is available to use in the first place
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                NSLog("The photo library is not available")
                return
            }

            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self

            present(imagePicker, animated: true, completion: nil)
        }

    // MARK: - IBActions

    @IBAction func SaveButtonTapped(_ sender: Any) {
        // Save to camera roll
        saveButtonTappedAlert()
        guard let originalImage = originalImage else { return }
        let filteredImage = image(byFiltering: originalImage)

        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)

        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if image != nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
                PHAssetChangeRequest.creationRequestForAsset(from: filteredImage)
            }, completionHandler: {success, error in
                // deal with success or error
            })
        }
    }

    @IBAction func addPhotoButtonTapped(_ sender: Any) {
        presentImagePicker()
    }
}

// MARK: - Extenstions

extension CreativeCanvasViewController: PKCanvasViewDelegate, PKToolPickerObserver {

}

extension CreativeCanvasViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let selectedImage = info[.originalImage] as? UIImage {
            originalImage = selectedImage
        }

        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}
