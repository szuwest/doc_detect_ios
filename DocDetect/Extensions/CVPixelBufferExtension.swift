// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

import UIKit
import Accelerate

extension CVPixelBuffer {

  /**
   Returns thumbnail by cropping pixel buffer to biggest square and scaling the cropped image to
   model dimensions.
   */
  func centerThumbnail(ofSize size: CGSize ) -> CVPixelBuffer? {

    let imageWidth = CVPixelBufferGetWidth(self)
    let imageHeight = CVPixelBufferGetHeight(self)
    let pixelBufferType = CVPixelBufferGetPixelFormatType(self)

    assert(pixelBufferType == kCVPixelFormatType_32BGRA)

    let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
    let imageChannels = 4

    let thumbnailSize = min(imageWidth, imageHeight)
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

    var originX = 0
    var originY = 0

    if imageWidth > imageHeight {
      originX = (imageWidth - imageHeight) / 2
    }
    else {
      originY = (imageHeight - imageWidth) / 2
    }

    // Finds the biggest square in the pixel buffer and advances rows based on it.
    guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self)?.advanced(
        by: originY * inputImageRowBytes + originX * imageChannels) else {
      return nil
    }

    // Gets vImage Buffer from input image
    var inputVImageBuffer = vImage_Buffer(
        data: inputBaseAddress, height: UInt(thumbnailSize), width: UInt(thumbnailSize),
        rowBytes: inputImageRowBytes)

    let thumbnailRowBytes = Int(size.width) * imageChannels
    guard  let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else {
      return nil
    }

    // Allocates a vImage buffer for thumbnail image.
    var thumbnailVImageBuffer = vImage_Buffer(data: thumbnailBytes, height: UInt(size.height), width: UInt(size.width), rowBytes: thumbnailRowBytes)

    // Performs the scale operation on input image buffer and stores it in thumbnail image buffer.
    let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVImageBuffer, nil, vImage_Flags(0))

    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

    guard scaleError == kvImageNoError else {
      return nil
    }

    let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in

      if let pointer = pointer {
        free(UnsafeMutableRawPointer(mutating: pointer))
      }
    }

    var thumbnailPixelBuffer: CVPixelBuffer?

    // Converts the thumbnail vImage buffer to CVPixelBuffer
    let conversionStatus = CVPixelBufferCreateWithBytes(
        nil, Int(size.width), Int(size.height), pixelBufferType, thumbnailBytes,
        thumbnailRowBytes, releaseCallBack, nil, nil, &thumbnailPixelBuffer)

    guard conversionStatus == kCVReturnSuccess else {

      free(thumbnailBytes)
      return nil
    }

    return thumbnailPixelBuffer
  }

  static func buffer(from image: UIImage) -> CVPixelBuffer? {
    let attrs = [
      kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
      kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
    ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     Int(image.size.width),
                                     Int(image.size.height),
                                     kCVPixelFormatType_32BGRA,
                                     attrs,
                                     &pixelBuffer)

    guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
      return nil
    }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    let pixelData = CVPixelBufferGetBaseAddress(buffer)

    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pixelData,
                                  width: Int(image.size.width),
                                  height: Int(image.size.height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: rgbColorSpace,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
      return nil
    }

    context.translateBy(x: 0, y: image.size.height)
    context.scaleBy(x: 1.0, y: -1.0)

    UIGraphicsPushContext(context)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    UIGraphicsPopContext()

    return pixelBuffer
  }

    // Convert CMSampleBuffer to CGImage
    static func convertCVPixelBuffer2UIImage(_ imageBuffer: CVPixelBuffer) -> UIImage {
        let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
        //需要处理成设备像素大小
        let image:UIImage = UIImage.init(cgImage: cgImage)
//        print("image size ", image.size)
        return image
    }
    
    
    func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                           cropX: Int,
                           cropY: Int,
                           cropWidth: Int,
                           cropHeight: Int,
                           scaleWidth: Int,
                           scaleHeight: Int) -> CVPixelBuffer? {

      CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
      guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
        print("Error: could not get pixel buffer base address")
        return nil
      }
      let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
      let offset = cropY*srcBytesPerRow + cropX*4
      var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                    height: vImagePixelCount(cropHeight),
                                    width: vImagePixelCount(cropWidth),
                                    rowBytes: srcBytesPerRow)

      let destBytesPerRow = scaleWidth*4
      guard let destData = malloc(scaleHeight*destBytesPerRow) else {
        print("Error: out of memory")
        return nil
      }
      var destBuffer = vImage_Buffer(data: destData,
                                     height: vImagePixelCount(scaleHeight),
                                     width: vImagePixelCount(scaleWidth),
                                     rowBytes: destBytesPerRow)

      let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
      CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
      if error != kvImageNoError {
        print("Error:", error)
        free(destData)
        return nil
      }

      let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
          free(UnsafeMutableRawPointer(mutating: ptr))
        }
      }

      let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
      var dstPixelBuffer: CVPixelBuffer?
      let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight,
                                                pixelFormat, destData,
                                                destBytesPerRow, releaseCallback,
                                                nil, nil, &dstPixelBuffer)
      if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destData)
        return nil
      }
      return dstPixelBuffer
    }

}
