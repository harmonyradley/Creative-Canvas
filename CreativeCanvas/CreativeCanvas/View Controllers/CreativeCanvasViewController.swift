//
//  CreativeCanvasViewController.swift
//  Created by Harmony Radley on 7/27/20.
//  Copyright © 2020 Harmony Radley. All rights reserved.
//
import UIKit
import PencilKit
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
class CreativeCanvasViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var imageView: UIImageView!
    // MARK: - Drawing Properties

    var drawing = PKDrawing() // Save drawing

    // MARK: - Image Propterties
    private let context = CIContext(options: nil)
    var originalImage: UIImage? {
        didSet {
            updateImage()
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
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
    }
    // MARK: - Pencil Kit Methods

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
            imageView.image = originalImage
        } else {
            imageView.image = nil
        }
    }

    func presentImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            NSLog("The photo library is not available")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    // Making the drawing and image save together..
    func myImage(from canvas: PKCanvasView) -> UIImage {
        let backgroundImage = imageView.image!
        let finalImageWidth = canvas.bounds.size.width
        let finalImageHeight = canvas.bounds.size.height
        let finalImageSize = canvas.bounds.size
        UIGraphicsBeginImageContextWithOptions(finalImageSize, false, UIScreen.main.scale)
        let backgroundY = (finalImageHeight / 2) - (backgroundImage.size.height / 2)
        backgroundImage.draw(in: CGRect(x: 0, y: backgroundY, width: backgroundImage.size.width, height: backgroundImage.size.height))
        let foregroundImage = canvas.drawing.image(from: CGRect(x: 0, y: 0, width: finalImageWidth, height: finalImageHeight), scale: UIScreen.main.scale)
        foregroundImage.draw(in: CGRect(x: 0, y: 0, width: finalImageWidth, height: finalImageHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    // MARK: - IBActions
    @IBAction func SaveButtonTapped(_ sender: Any) {
        // Save to camera roll
        saveButtonTappedAlert()
        let imageWithDrawing = myImage(from: canvasView)
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)
        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        let drawingImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: drawingImage!)
            PHAssetChangeRequest.creationRequestForAsset(from: imageWithDrawing)
        }, completionHandler: {success, error in
            // deal with success or error
        })
    }

    // image scaling to canvasview
    @IBAction func addPhotoButtonTapped(_ sender: Any) {
        presentImagePicker()
    }
}

// MARK: - Extenstions
extension CreativeCanvasViewController: PKCanvasViewDelegate, PKToolPickerObserver {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX: CGFloat = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
        let offsetY: CGFloat = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)
        imageView.frame.size = CGSize(width: self.view.bounds.width * scrollView.zoomScale, height: self.view.bounds.height * scrollView.zoomScale)
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension CreativeCanvasViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            originalImage = resizeImage(image: selectedImage, targetSize: CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height))
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
