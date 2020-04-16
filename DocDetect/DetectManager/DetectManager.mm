//
//  DetectManager.m
//  DocDetect
//
//  Created by kk on 2020/3/31.
//  Copyright © 2020 wegene. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "fm_ocr_scanner.hpp"
#import "OpenCVUtil.h"
#import "CropUtil.h"
#import "DetectManager.h"

@implementation ProcessResult

- (instancetype)init {
    self = [super init];
    _fourPoints = [NSMutableArray new];
    return self;
}

@end

@implementation DetectManager

- (UIImage *)processFrame:(CVImageBufferRef)imgBufferRef {
    cv::Mat imgMat = [self cvMatFromBuffer:imgBufferRef];
    //    //转为灰度图矩阵
    //    cv::Mat matGray;
    //    cv::cvtColor(mat, matGray, cv::COLOR_BGR2GRAY);
    return [OpenCVUtil UIImageFromCVMat:imgMat];
}

//Buffer转为OpenCV矩阵
- (cv::Mat)cvMatFromBuffer:(CVImageBufferRef)buffer {
    CVImageBufferRef pixelBuffer = buffer;
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    //取得高宽，以及数据起始地址
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    //转为OpenCV矩阵
    cv::Mat mat = cv::Mat(bufferHeight,bufferWidth,CV_8UC4,pixel,CVPixelBufferGetBytesPerRow(pixelBuffer));
    
    //结束处理
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    return mat;
}

- (UIImage *)convertDataToImage:(NSData *)data {
//    NSLog(@"data.count=%lu",(unsigned long)data.length);
    cv::Mat outputMat = cv::Mat(256, 256, CV_32FC1, (float *)data.bytes);
    cv::Mat gray_image;
    outputMat.convertTo(gray_image, CV_8UC1, 255.0);
    return [OpenCVUtil UIImageFromCVMat:gray_image];
}

- (ProcessResult *)processEdgeImg:(NSData *)edgeImageData{
    cv::Mat outputMat = cv::Mat(256, 256, CV_32FC1, (float *)edgeImageData.bytes);
    
    double startTime = [[NSDate date] timeIntervalSince1970];
    auto tuple = ProcessEdgeImage(outputMat);
    NSTimeInterval opencvTime = ([[NSDate date] timeIntervalSince1970] - startTime) * 1000;
    NSLog(@"opencvTime=%f", opencvTime);
    ProcessResult *result = [[ProcessResult alloc] init];
    result.processTime = opencvTime;
    auto find_rect = std::get<0>(tuple);
    auto cv_points = std::get<1>(tuple);
    
    NSMutableArray *fourPoints = [[NSMutableArray alloc] initWithCapacity:4];
    if (find_rect == true) {
        for(int i = 0; i < cv_points.size(); i++) {
            cv::Point cv_point = cv_points[i];
            CGPoint point = CGPointMake(cv_point.x , cv_point.y);
            [fourPoints addObject:[NSValue valueWithCGPoint:point]];
        }
    }
    result.fourPoints = fourPoints;
    return result;
}

- (CGPoint)converPoint:(CGPoint)point toSize:(CGSize)size {
    return CGPointMake(point.x * size.width / HED_INPUT_WIDTH, point.y * size.height / HED_INPUT_WIDTH);
}

static std::vector<cv::Point> converToCVPoints(NSArray * points) {
    std::vector<cv::Point> cvPoints;
    for (NSValue *item : points) {
        CGPoint p = item.CGPointValue;
        cv::Point point(p.x, p.y);
        cvPoints.push_back(point);
    }
    return cvPoints;
}

+ (double)getDistance:(cv::Point)point1 withPoint:(cv::Point)point2 {
    return getPointsDistance(point1.x, point1.y, point2.x, point2.y);
}

static double getPointsDistance(float x1, float y1, float x2, float y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

- (UIImage *)cropImageBuffer: (CVImageBufferRef)imgBufferRef withPoints:(NSArray *)points {
    cv::Mat srcBitmapMat = [self cvMatFromBuffer:imgBufferRef];
    std::vector<cv::Point> cvPoints = converToCVPoints(points);
    cv::Point leftTop = cvPoints[0];
    cv::Point rightTop = cvPoints[1];
    cv::Point rightBottom = cvPoints[2];
    cv::Point leftBottom = cvPoints[3];
    
    cv::Mat dstBitmapMat;
    int cropWith = (int)([DetectManager getDistance:leftTop withPoint:rightTop] + [DetectManager getDistance:leftBottom withPoint:rightBottom]) / 2;
    int cropHeight = (int)([DetectManager getDistance:leftTop withPoint:leftBottom] + [DetectManager getDistance:rightTop withPoint:rightBottom]) / 2;
    dstBitmapMat = cv::Mat::zeros(cropHeight, cropWith, srcBitmapMat.type());
    std::vector<cv::Point2f> srcTriangle;
    std::vector<cv::Point2f> dstTriangle;

    srcTriangle.push_back(cv::Point2f(leftTop.x, leftTop.y));
    srcTriangle.push_back(cv::Point2f(rightTop.x, rightTop.y));
    srcTriangle.push_back(cv::Point2f(leftBottom.x, leftBottom.y));
    srcTriangle.push_back(cv::Point2f(rightBottom.x, rightBottom.y));

    dstTriangle.push_back(cv::Point2f(0, 0));
    dstTriangle.push_back(cv::Point2f(cropWith, 0));
    dstTriangle.push_back(cv::Point2f(0, cropHeight));
    dstTriangle.push_back(cv::Point2f(cropWith, cropHeight));

    cv::Mat transform = getPerspectiveTransform(srcTriangle, dstTriangle);
    warpPerspective(srcBitmapMat, dstBitmapMat, transform, dstBitmapMat.size());

    return [OpenCVUtil UIImageFromCVMat:dstBitmapMat];
}

@end
