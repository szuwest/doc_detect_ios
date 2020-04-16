// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import AVFoundation

/**
 Displays a preview of the image being processed. By default, this uses the device's camera frame,
 but will use a still image copied from clipboard if `shouldUseClipboardImage` is set to true.
 */
class PreviewView: UIView {

    var points: [CGPoint]? {
        didSet {
            updateQuad()
        }
    }
    var shapeLayer = CAShapeLayer.init()
    
  var previewLayer: AVCaptureVideoPreviewLayer {
    guard let layer = layer as? AVCaptureVideoPreviewLayer else {
      fatalError("Layer expected is of type VideoPreviewLayer")
    }
    return layer
  }

  var session: AVCaptureSession? {
    get {
      return previewLayer.session
    }
    set {
      previewLayer.session = newValue
    }
  }

  override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }

    func drawQuadrilateral() -> UIBezierPath {
        let  BzPath = UIBezierPath.init()
        if let points = self.points {
            BzPath.move(to: points[0])
            BzPath.addLine(to: points[1])
            BzPath.addLine(to: points[2])
            BzPath.addLine(to: points[3])
            BzPath.close()
        }
        return BzPath
    }
    
    func updateQuad() {
        if shapeLayer.superlayer == nil {
            self.layer.addSublayer(shapeLayer)
        }
        
         shapeLayer.path = self.drawQuadrilateral().cgPath
         // 设置路径的颜色
         shapeLayer.strokeColor = UIColor.yellow.cgColor
         // 设置路径围成区域的填充色
        shapeLayer.fillColor = UIColor.init(white: 1, alpha: 0.4).cgColor
         // 设置路径的宽度
         shapeLayer.lineWidth = 1
         // 向绘制的View上添加 layer
    }
}
