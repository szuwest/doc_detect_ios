//
//  ViewController.swift
//  DocDetect
//
//  Created by kk on 2020/3/27.
//  Copyright © 2020 wegene. All rights reserved.
//

import UIKit

let HW_RATIO  = (64.0/48.0)

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: PreviewView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    private var previousInferenceTimeMs: TimeInterval = Date.distantPast.timeIntervalSince1970 * 1000
    private let delayBetweenInferencesMs: Double = 100
    
    private lazy var cameraCapture = CameraFeedManager(previewView: cameraView)
    private lazy var detectManager = DetectManager()
    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.modelInfo, threadCount: 2)
    
    private var cameraFrameSize: CGSize?
    private var previewSize: CGSize?
    private var points: Array<Any>?
    var stop = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraCapture.delegate = self
        self.imageView.contentMode = .scaleAspectFit
    }

      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    #if !targetEnvironment(simulator)
        cameraCapture.checkCameraConfigurationAndStartSession()
    #endif
        stop = false
      }

    #if !targetEnvironment(simulator)
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraCapture.stopSession()
      }
    #endif
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//      return .lightContent
//    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        let containerW = self.view.frame.width
//        let containerH = containerW * CGFloat(HW_RATIO)
//        cameraView.frame = CGRect(x: 0, y: 50, width: containerW, height: containerH)
        cameraView.frame = self.view.frame
        previewSize = cameraView.frame.size
    }
    
    func showCropImage(image: UIImage) {
        let vc = CropImgViewController()
        vc.cropImage = image
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true) {
            
        }
    }
}

// MARK: - CameraFeedManagerDelegate Methods
extension ViewController: CameraFeedManagerDelegate {

  func didOutput(pixelBuffer: CVImageBuffer) {
    if cameraFrameSize == nil {
        let resolution = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        print("frame size=\(resolution), previewSize=\(previewSize ?? CGSize(width: 0, height: 0))")
        self.cameraFrameSize = resolution
    }
    if (stop) {
        return
    }
//    let currentTimeMs = Date().timeIntervalSince1970 * 1000
//    guard (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs else { return }
//    previousInferenceTimeMs = currentTimeMs

    // Pass the pixel buffer to TensorFlow Lite to perform inference.
    if let result = modelDataHandler?.runModel(onFrame: pixelBuffer) {
        print("infer time=\(result.inferenceTime)")
        let image = detectManager.convertData(toImage: result.edgeImage)
        let processResult = detectManager.processEdgeImg(result.edgeImage)
        if (processResult.fourPoints.count == 4) {
            var fourP = [CGPoint]()
            for i in 0..<processResult.fourPoints.count {
                let value = processResult.fourPoints[i] as! NSValue
                fourP.append(detectManager.converPoint(value.cgPointValue, to: previewSize!))
            }
            DispatchQueue.main.async {
                self.cameraView.points = fourP
            }
            
            if (self.points != nil) {
                let similar = CropUtil.isQuadSimilar(self.points!, withPoints: processResult.fourPoints)
                if (similar) {
                    var newPoints = Array<CGPoint>()
                    for i in 0..<processResult.fourPoints.count {
                        let value = processResult.fourPoints[i] as! NSValue
                        newPoints.append(detectManager.converPoint(value.cgPointValue, to: cameraFrameSize!))
                    }
                    let cropImage = detectManager.cropImageBuffer(pixelBuffer, withPoints: newPoints)
                    stop = true
                    DispatchQueue.main.async {
                        self.showCropImage(image: cropImage)
                        self.points = nil
                    }
                }
            }
            self.points = processResult.fourPoints
        } else {
            DispatchQueue.main.async {
                self.cameraView.points = nil
            }
        }
        DispatchQueue.main.async {
            self.imageView.image = image//result.scaleImage
            var info = "infer time = \(result.inferenceTime)"
            info = info + "\nopencvTime=\(processResult.processTime)"
            self.infoLabel.text = info
        }
    }
    
//    detectManager.processFrame(pixelBuffer)
  }

  // MARK: Session Handling Alerts
  func sessionWasInterrupted(canResumeManually resumeManually: Bool) {

    // Updates the UI when session is interupted.

  }

  func sessionInterruptionEnded() {
    // Updates UI once session interruption has ended.

  }

  func sessionRunTimeErrorOccured() {
    // Handles session run time error by updating the UI and providing a button if session can be manually resumed.

  }

  func presentCameraPermissionsDeniedAlert() {
    let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
      UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(settingsAction)

    present(alertController, animated: true, completion: nil)

  }

  func presentVideoConfigurationErrorAlert() {
    let alert = UIAlertController(title: "Camera Configuration Failed", message: "There was an error while configuring camera.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    self.present(alert, animated: true)
  }
    
}

