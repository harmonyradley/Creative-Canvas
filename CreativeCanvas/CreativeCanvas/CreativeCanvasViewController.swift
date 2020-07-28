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

class CreativeCanvasViewController: UIViewController {

    @IBOutlet var canvasView: PKCanvasView!
   

    let canvasWidth: CGFloat = 770
    let canvasOverscrollHight: CGFloat = 500

    // Save drawing
    var drawing = PKDrawing()

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.delegate = self
        canvasView.drawing = drawing

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

    // MARK: - Methods
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

    // MARK: - Bar Button Items Methods

    @IBAction func SaveButtonTapped(_ sender: Any) {
        // Save to camera roll
        saveButtonTappedAlert()
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)

        canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if image != nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
            }, completionHandler: {success, error in
                // deal with success or error
            })
        }
    }

    func saveButtonTappedAlert() {
        let alert = UIAlertController(title: "Great Drawing!", message: "Your drawing has been saved to your camera roll!", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)

    }


    @IBAction func AddPhotoButtonTapped(_ sender: Any) {

    }

}

extension CreativeCanvasViewController: PKCanvasViewDelegate, PKToolPickerObserver {

}
