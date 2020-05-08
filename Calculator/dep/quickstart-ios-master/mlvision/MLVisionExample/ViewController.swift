//
//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
// [START import_vision]
import Firebase
// [END import_vision]

/// Main view controller class.
@objc(ViewController)
class ViewController:  UIViewController, UINavigationControllerDelegate {
  /// Firebase vision instance.
  // [START init_vision]
  lazy var vision = Vision.vision()
  // [END init_vision]

  /// A string holding current results from detection.
  var resultsText = ""

  /// An overlay view that displays detection annotations.
  private lazy var annotationOverlayView: UIView = {
    precondition(isViewLoaded)
    let annotationOverlayView = UIView(frame: .zero)
    annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
    return annotationOverlayView
  }()

  /// An image picker for accessing the photo library or camera.
  var imagePicker = UIImagePickerController()
    
  // Image counter.
  var currentImage = 0

  // MARK: - IBOutlets

  @IBOutlet fileprivate weak var detectorPicker: UIPickerView!
  @IBOutlet fileprivate weak var imageView: UIImageView!
  @IBOutlet fileprivate weak var photoCameraButton: UIBarButtonItem!
  @IBOutlet fileprivate weak var videoCameraButton: UIBarButtonItem!
  @IBOutlet weak var detectButton: UIBarButtonItem!

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    imageView.image = UIImage(named: Constants.images[currentImage])
    imageView.addSubview(annotationOverlayView)
    NSLayoutConstraint.activate([
      annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
      annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
      annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
      annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
      ])

    imagePicker.delegate = self
    imagePicker.sourceType = .photoLibrary

    detectorPicker.delegate = self
    detectorPicker.dataSource = self

    if !UIImagePickerController.isCameraDeviceAvailable(.front) &&
      !UIImagePickerController.isCameraDeviceAvailable(.rear) {
      photoCameraButton.isEnabled = false
      videoCameraButton.isEnabled = false
    }

    let defaultRow = (DetectorPickerRow.rowsCount / 2) - 1
    detectorPicker.selectRow(defaultRow, inComponent: 0, animated: false)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.navigationBar.isHidden = true
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    navigationController?.navigationBar.isHidden = false
  }

  // MARK: - IBActions

  @IBAction func detect(_ sender: Any) {
    clearResults()
    let row = detectorPicker.selectedRow(inComponent: 0)
    if let rowIndex = DetectorPickerRow(rawValue: row) {
      switch rowIndex {
      case .detectFaceOnDevice:
        detectFaces(image: imageView.image)
      case .detectTextOnDevice:
        detectTextOnDevice(image: imageView.image)
      case .detectBarcodeOnDevice:
        detectBarcodes(image: imageView.image)
      case .detectImageLabelsOnDevice:
        detectLabels(image: imageView.image)
      case .detectTextInCloud:
        detectTextInCloud(image: imageView.image)
      case .detectDocumentTextInCloud:
        detectDocumentTextInCloud(image: imageView.image)
      case .detectImageLabelsInCloud:
        detectCloudLabels(image: imageView.image)
      case .detectLandmarkInCloud:
        detectCloudLandmarks(image: imageView.image)
      }
    } else {
      print("No such item at row \(row) in detector picker.")
    }
  }

  @IBAction func openPhotoLibrary(_ sender: Any) {
    imagePicker.sourceType = .photoLibrary
    present(imagePicker, animated: true)
  }

  @IBAction func openCamera(_ sender: Any) {
    guard UIImagePickerController.isCameraDeviceAvailable(.front) ||
      UIImagePickerController.isCameraDeviceAvailable(.rear)
      else {
        return
    }
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true)
  }
    
  @IBAction func changeImage(_ sender: Any) {
    clearResults()
    currentImage = (currentImage + 1) % Constants.images.count
    imageView.image = UIImage(named: Constants.images[currentImage])
  }

  // MARK: - Private

  /// Removes the detection annotations from the annotation overlay view.
  private func removeDetectionAnnotations() {
    for annotationView in annotationOverlayView.subviews {
      annotationView.removeFromSuperview()
    }
  }

  /// Clears the results text view and removes any frames that are visible.
  private func clearResults() {
    removeDetectionAnnotations()
    self.resultsText = ""
  }

  private func showResults() {
    let resultsAlertController = UIAlertController(
      title: "Detection Results",
      message: nil,
      preferredStyle: .actionSheet
    )
    resultsAlertController.addAction(
      UIAlertAction(title: "OK", style: .destructive) { _ in
        resultsAlertController.dismiss(animated: true, completion: nil)
      }
    )
    resultsAlertController.message = resultsText
    resultsAlertController.popoverPresentationController?.barButtonItem = detectButton
    resultsAlertController.popoverPresentationController?.sourceView = self.view
    present(resultsAlertController, animated: true, completion: nil)
    print(resultsText)
  }

  /// Updates the image view with a scaled version of the given image.
  private func updateImageView(with image: UIImage) {
    let orientation = UIApplication.shared.statusBarOrientation
    var scaledImageWidth: CGFloat = 0.0
    var scaledImageHeight: CGFloat = 0.0
    switch orientation {
    case .portrait, .portraitUpsideDown, .unknown:
      scaledImageWidth = imageView.bounds.size.width
      scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
    case .landscapeLeft, .landscapeRight:
      scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
      scaledImageHeight = imageView.bounds.size.height
    }
    DispatchQueue.global(qos: .userInitiated).async {
      // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
      var scaledImage = image.scaledImage(
        withSize: CGSize(width: scaledImageWidth, height: scaledImageHeight)
      )
      scaledImage = scaledImage ?? image
      guard let finalImage = scaledImage else { return }
      DispatchQueue.main.async {
        self.imageView.image = finalImage
      }
    }
  }

  private func transformMatrix() -> CGAffineTransform {
    guard let image = imageView.image else { return CGAffineTransform() }
    let imageViewWidth = imageView.frame.size.width
    let imageViewHeight = imageView.frame.size.height
    let imageWidth = image.size.width
    let imageHeight = image.size.height

    let imageViewAspectRatio = imageViewWidth / imageViewHeight
    let imageAspectRatio = imageWidth / imageHeight
    let scale = (imageViewAspectRatio > imageAspectRatio) ?
      imageViewHeight / imageHeight :
      imageViewWidth / imageWidth

    // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
    // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
    let scaledImageWidth = imageWidth * scale
    let scaledImageHeight = imageHeight * scale
    let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
    let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

    var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
    transform = transform.scaledBy(x: scale, y: scale)
    return transform
  }

  private func pointFrom(_ visionPoint: VisionPoint) -> CGPoint {
    return CGPoint(x: CGFloat(visionPoint.x.floatValue), y: CGFloat(visionPoint.y.floatValue))
  }

    private func addContours(forFace face: VisionFace, transform: CGAffineTransform) {
        // Face
        if let faceContour = face.contour(ofType: .face) {
            for point in faceContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }

        // Eyebrows
        if let topLeftEyebrowContour = face.contour(ofType: .leftEyebrowTop) {
            for point in topLeftEyebrowContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let bottomLeftEyebrowContour = face.contour(ofType: .leftEyebrowBottom) {
            for point in bottomLeftEyebrowContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let topRightEyebrowContour = face.contour(ofType: .rightEyebrowTop) {
            for point in topRightEyebrowContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let bottomRightEyebrowContour = face.contour(ofType: .rightEyebrowBottom) {
            for point in bottomRightEyebrowContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }

        // Eyes
        if let leftEyeContour = face.contour(ofType: .leftEye) {
            for point in leftEyeContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius                )
            }
        }
        if let rightEyeContour = face.contour(ofType: .rightEye) {
            for point in rightEyeContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }

        // Lips
        if let topUpperLipContour = face.contour(ofType: .upperLipTop) {
            for point in topUpperLipContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let bottomUpperLipContour = face.contour(ofType: .upperLipBottom) {
            for point in bottomUpperLipContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let topLowerLipContour = face.contour(ofType: .lowerLipTop) {
            for point in topLowerLipContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let bottomLowerLipContour = face.contour(ofType: .lowerLipBottom) {
            for point in bottomLowerLipContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }

        // Nose
        if let noseBridgeContour = face.contour(ofType: .noseBridge) {
            for point in noseBridgeContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
        if let noseBottomContour = face.contour(ofType: .noseBottom) {
            for point in noseBottomContour.points {
                let transformedPoint = pointFrom(point).applying(transform);
                UIUtilities.addCircle(
                    atPoint: transformedPoint,
                    to: annotationOverlayView,
                    color: UIColor.yellow,
                    radius: Constants.smallDotRadius
                )
            }
        }
    }

  private func addLandmarks(forFace face: VisionFace, transform: CGAffineTransform) {
    // Mouth
    if let bottomMouthLandmark = face.landmark(ofType: .mouthBottom) {
      let point = pointFrom(bottomMouthLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.largeDotRadius
      )
    }
    if let leftMouthLandmark = face.landmark(ofType: .mouthLeft) {
      let point = pointFrom(leftMouthLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.largeDotRadius
      )
    }
    if let rightMouthLandmark = face.landmark(ofType: .mouthRight) {
      let point = pointFrom(rightMouthLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.red,
        radius: Constants.largeDotRadius
      )
    }

    // Nose
    if let noseBaseLandmark = face.landmark(ofType: .noseBase) {
      let point = pointFrom(noseBaseLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.yellow,
        radius: Constants.largeDotRadius
      )
    }

    // Eyes
    if let leftEyeLandmark = face.landmark(ofType: .leftEye) {
      let point = pointFrom(leftEyeLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.cyan,
        radius: Constants.largeDotRadius
      )
    }
    if let rightEyeLandmark = face.landmark(ofType: .rightEye) {
      let point = pointFrom(rightEyeLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.cyan,
        radius: Constants.largeDotRadius
      )
    }

    // Ears
    if let leftEarLandmark = face.landmark(ofType: .leftEar) {
      let point = pointFrom(leftEarLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.purple,
        radius: Constants.largeDotRadius
      )
    }
    if let rightEarLandmark = face.landmark(ofType: .rightEar) {
      let point = pointFrom(rightEarLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.purple,
        radius: Constants.largeDotRadius
      )
    }

    // Cheeks
    if let leftCheekLandmark = face.landmark(ofType: .leftCheek) {
      let point = pointFrom(leftCheekLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.orange,
        radius: Constants.largeDotRadius
      )
    }
    if let rightCheekLandmark = face.landmark(ofType: .rightCheek) {
      let point = pointFrom(rightCheekLandmark.position)
      let transformedPoint = point.applying(transform)
      UIUtilities.addCircle(
        atPoint: transformedPoint,
        to: annotationOverlayView,
        color: UIColor.orange,
        radius: Constants.largeDotRadius
      )
    }
  }

  private func process(_ visionImage: VisionImage, with textRecognizer: VisionTextRecognizer?) {
    textRecognizer?.process(visionImage) { text, error in
      guard error == nil, let text = text else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Text recognizer failed with error: \(errorString)"
        self.showResults()
        return
      }
      // Blocks.
      for block in text.blocks {
        let transformedRect = block.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.purple
        )

        // Lines.
        for line in block.lines {
          let transformedRect = line.frame.applying(self.transformMatrix())
          UIUtilities.addRectangle(
            transformedRect,
            to: self.annotationOverlayView,
            color: UIColor.orange
          )

          // Elements.
          for element in line.elements {
            let transformedRect = element.frame.applying(self.transformMatrix())
            UIUtilities.addRectangle(
              transformedRect,
              to: self.annotationOverlayView,
              color: UIColor.green
            )
            let label = UILabel(frame: transformedRect)
            label.text = element.text
            label.adjustsFontSizeToFitWidth = true
            self.annotationOverlayView.addSubview(label)
          }
        }
      }
      self.resultsText += "\(text.text)\n"
      self.showResults()
    }
  }

  private func process(
    _ visionImage: VisionImage,
    with documentTextRecognizer: VisionDocumentTextRecognizer?
    ) {
    documentTextRecognizer?.process(visionImage) { text, error in
      guard error == nil, let text = text else {
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Document text recognizer failed with error: \(errorString)"
        self.showResults()
        return
      }
      // Blocks.
      for block in text.blocks {
        let transformedRect = block.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.purple
        )

        // Paragraphs.
        for paragraph in block.paragraphs {
          let transformedRect = paragraph.frame.applying(self.transformMatrix())
          UIUtilities.addRectangle(
            transformedRect,
            to: self.annotationOverlayView,
            color: UIColor.orange
          )

          // Words.
          for word in paragraph.words {
            let transformedRect = word.frame.applying(self.transformMatrix())
            UIUtilities.addRectangle(
              transformedRect,
              to: self.annotationOverlayView,
              color: UIColor.green
            )

            // Symbols.
            for symbol in word.symbols {
              let transformedRect = symbol.frame.applying(self.transformMatrix())
              UIUtilities.addRectangle(
                transformedRect,
                to: self.annotationOverlayView,
                color: UIColor.cyan
              )
              let label = UILabel(frame: transformedRect)
              label.text = symbol.text
              label.adjustsFontSizeToFitWidth = true
              self.annotationOverlayView.addSubview(label)
            }
          }
        }
      }
      self.resultsText += "\(text.text)\n"
      self.showResults()
    }
  }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {

  // MARK: - UIPickerViewDataSource

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return DetectorPickerRow.componentsCount
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return DetectorPickerRow.rowsCount
  }

  // MARK: - UIPickerViewDelegate

  func pickerView(
    _ pickerView: UIPickerView,
    titleForRow row: Int,
    forComponent component: Int
    ) -> String? {
    return DetectorPickerRow(rawValue: row)?.description
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    clearResults()
  }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate {

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String: Any]
    ) {
    clearResults()
    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      updateImageView(with: pickedImage)
    }
    dismiss(animated: true)
  }
}

/// Extension of ViewController for On-Device and Cloud detection.
extension ViewController {

  // MARK: - Vision On-Device Detection

  /// Detects faces on the specified image and draws a frame around the detected faces using
  /// On-Device face API.
  ///
  /// - Parameter image: The image.
  func detectFaces(image: UIImage?) {
    guard let image = image else { return }

    // Create a face detector with options.
    // [START config_face]
    let options = VisionFaceDetectorOptions()
    options.landmarkMode = .all
    options.classificationMode = .all
    options.performanceMode = .accurate
    options.contourMode = .all
    // [END config_face]

    // [START init_face]
    let faceDetector = vision.faceDetector(options: options)
    // [END init_face]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_faces]
    faceDetector.process(visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device face detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Faces detected
      // [START_EXCLUDE]
      self.resultsText = features.map { feature -> String in
        let transform = self.transformMatrix()
        let transformedRect = feature.frame.applying(transform)
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        self.addLandmarks(forFace: feature, transform: transform)
        self.addContours(forFace: feature, transform: transform)

        let headEulerAngleY = feature.hasHeadEulerAngleY ? feature.headEulerAngleY.description : "NA"
        let headEulerAngleZ = feature.hasHeadEulerAngleZ ? feature.headEulerAngleZ.description : "NA"
        let leftEyeOpenProbability = feature.hasLeftEyeOpenProbability ? feature.leftEyeOpenProbability.description : "NA"
        let rightEyeOpenProbability = feature.hasRightEyeOpenProbability ? feature.rightEyeOpenProbability.description : "NA"
        let smilingProbability = feature.hasSmilingProbability ? feature.smilingProbability.description : "NA"
        let output = """
                     Frame: \(feature.frame)
                     Head Euler Angle Y: \(headEulerAngleY)
                     Head Euler Angle Z: \(headEulerAngleZ)
                     Left Eye Open Probability: \(leftEyeOpenProbability)
                     Right Eye Open Probability: \(rightEyeOpenProbability)
                     Smiling Probability: \(smilingProbability)
                     """
        return "\(output)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_faces]
  }

  /// Detects barcodes on the specified image and draws a frame around the detected barcodes using
  /// On-Device barcode API.
  ///
  /// - Parameter image: The image.
  func detectBarcodes(image: UIImage?) {
    guard let image = image else { return }

    // Define the options for a barcode detector.
    // [START config_barcode]
    let format = VisionBarcodeFormat.all
    let barcodeOptions = VisionBarcodeDetectorOptions(formats: format)
    // [END config_barcode]

    // Create a barcode detector.
    // [START init_barcode]
    let barcodeDetector = vision.barcodeDetector(options: barcodeOptions)
    // [END init_barcode]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_barcodes]
    barcodeDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device barcode detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // [START_EXCLUDE]
      self.resultsText = features.map { feature in
        let transformedRect = feature.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "DisplayValue: \(feature.displayValue ?? ""), RawValue: " +
        "\(feature.rawValue ?? ""), Frame: \(feature.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_barcodes]
  }

  /// Detects labels on the specified image using On-Device label API.
  ///
  /// - Parameter image: The image.
  func detectLabels(image: UIImage?) {
    guard let image = image else { return }

    // [START config_label]
    let options = VisionLabelDetectorOptions(
      confidenceThreshold: Constants.labelConfidenceThreshold
    )
    // [END config_label]

    // [START init_label]
    let labelDetector = vision.labelDetector(options: options)
    // [END init_label]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_label]
    labelDetector.detect(in: visionImage) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "On-Device label detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // [START_EXCLUDE]
      self.resultsText = features.map { feature -> String in
        return "Label: \(String(describing: feature.label)), " +
          "Confidence: \(feature.confidence), " +
          "EntityID: \(String(describing: feature.entityID))"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_label]
  }

  /// Detects text on the specified image and draws a frame around the recognized text using the
  /// On-Device text recognizer.
  ///
  /// - Parameter image: The image.
  func detectTextOnDevice(image: UIImage?) {
    guard let image = image else { return }

    // [START init_text]
    let onDeviceTextRecognizer = vision.onDeviceTextRecognizer()
    // [END init_text]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    self.resultsText += "Running On-Device Text Recognition...\n"
    process(visionImage, with: onDeviceTextRecognizer)
  }

  // MARK: - Vision Cloud Detection

  /// Detects text on the specified image and draws a frame around the recognized text using the
  /// Cloud text recognizer.
  ///
  /// - Parameter image: The image.
  func detectTextInCloud(image: UIImage?) {
    guard let image = image else { return }

    // [START config_text_cloud]
    let options = VisionCloudTextRecognizerOptions()
    options.modelType = .dense
    // [END config_text_cloud]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START init_text_cloud]
    let cloudTextRecognizer = vision.cloudTextRecognizer(options: options)
    // Or, to use the default settings:
    // let cloudTextRecognizer = vision.cloudTextRecognizer()
    // [END init_text_cloud]
    self.resultsText += "Running Cloud Text Recognition...\n"
    process(visionImage, with: cloudTextRecognizer)
  }

  /// Detects document text on the specified image and draws a frame around the recognized text
  /// using the Cloud document text recognizer.
  ///
  /// - Parameter image: The image.
  func detectDocumentTextInCloud(image: UIImage?) {
    guard let image = image else { return }

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START init_document_text_cloud]
    let cloudDocumentTextRecognizer = vision.cloudDocumentTextRecognizer()
    // [END init_document_text_cloud]

    self.resultsText += "Running Cloud Document Text Recognition...\n"
    process(visionImage, with: cloudDocumentTextRecognizer)
  }

  /// Detects landmarks on the specified image and draws a frame around the detected landmarks using
  /// cloud landmark API.
  ///
  /// - Parameter image: The image.
  func detectCloudLandmarks(image: UIImage?) {
    guard let image = image else { return }

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // Create a landmark detector.
    // [START config_landmark_cloud]
    let options = VisionCloudDetectorOptions()
    options.modelType = .latest
    options.maxResults = 20
    // [END config_landmark_cloud]

    // [START init_landmark_cloud]
    let cloudDetector = vision.cloudLandmarkDetector(options: options)
    // Or, to use the default settings:
    // let cloudDetector = vision.cloudLandmarkDetector()
    // [END init_landmark_cloud]

    // [START detect_landmarks_cloud]
    cloudDetector.detect(in: visionImage) { landmarks, error in
      guard error == nil, let landmarks = landmarks, !landmarks.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud landmark detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Recognized landmarks
      // [START_EXCLUDE]
      self.resultsText = landmarks.map { landmark -> String in
        let transformedRect = landmark.frame.applying(self.transformMatrix())
        UIUtilities.addRectangle(
          transformedRect,
          to: self.annotationOverlayView,
          color: UIColor.green
        )
        return "Landmark: \(String(describing: landmark.landmark ?? "")), " +
          "Confidence: \(String(describing: landmark.confidence ?? 0) ), " +
          "EntityID: \(String(describing: landmark.entityId ?? "") ), " +
        "Frame: \(landmark.frame)"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
    // [END detect_landmarks_cloud]
  }

  /// Detects labels on the specified image using cloud label API.
  ///
  /// - Parameter image: The image.
  func detectCloudLabels(image: UIImage?) {
    guard let image = image else { return }

    // [START init_label_cloud]
    let labelDetector = vision.cloudLabelDetector()
    // Or, to change the default settings:
    // let labelDetector = Vision.vision().cloudLabelDetector(options: options)
    // [END init_label_cloud]

    // Define the metadata for the image.
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)

    // Initialize a VisionImage object with the given UIImage.
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    // [START detect_label_cloud]
    labelDetector.detect(in: visionImage) { labels, error in
      guard error == nil, let labels = labels, !labels.isEmpty else {
        // [START_EXCLUDE]
        let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
        self.resultsText = "Cloud label detection failed with error: \(errorString)"
        self.showResults()
        // [END_EXCLUDE]
        return
      }

      // Labeled image
      // START_EXCLUDE
      self.resultsText = labels.map { label -> String in
        "Label: \(String(describing: label.label ?? "")), " +
          "Confidence: \(label.confidence ?? 0), " +
        "EntityID: \(label.entityId ?? "")"
        }.joined(separator: "\n")
      self.showResults()
      // [END_EXCLUDE]
    }
  }
  // [END detect_label_cloud]
}

// MARK: - Enums

private enum DetectorPickerRow: Int {
  case detectFaceOnDevice = 0,
  detectTextOnDevice,
  detectBarcodeOnDevice,
  detectImageLabelsOnDevice,
  detectTextInCloud,
  detectDocumentTextInCloud,
  detectImageLabelsInCloud,
  detectLandmarkInCloud

  static let rowsCount = 8
  static let componentsCount = 1

  public var description: String {
    switch self {
    case .detectFaceOnDevice:
      return "Face On-Device"
    case .detectTextOnDevice:
      return "Text On-Device"
    case .detectBarcodeOnDevice:
      return "Barcode On-Device"
    case .detectImageLabelsOnDevice:
      return "Image Labeling On-Device"
    case .detectTextInCloud:
      return "Text in Cloud"
    case .detectDocumentTextInCloud:
      return "Document Text in Cloud"
    case .detectImageLabelsInCloud:
      return "Image Labeling in Cloud"
    case .detectLandmarkInCloud:
      return "Landmarks in Cloud"
    }
  }
}

private enum Constants {
  static let images = ["grace_hopper.jpg", "barcode_128.png", "qr_code.jpg", "beach.jpg",
                       "image_has_text.jpg", "liberty.jpg"]
  static let modelExtension = "tflite"
  static let localModelName = "mobilenet"
  static let quantizedModelFilename = "mobilenet_quant_v1_224"

  static let detectionNoResultsMessage = "No results returned."
  static let failedToDetectObjectsMessage = "Failed to detect objects in image."

  static let labelConfidenceThreshold: Float = 0.75
  static let smallDotRadius: CGFloat = 5.0
  static let largeDotRadius: CGFloat = 10.0
  static let lineColor = UIColor.yellow.cgColor
  static let fillColor = UIColor.clear.cgColor
}
