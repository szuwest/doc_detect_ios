//
//  OpenCVUtil.h
//  DemoWithStaticLib
//
//  Created by fengjian on 2018/4/11.
//  Copyright © 2018年 fengjian. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

// copy code from https://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
@interface OpenCVUtil : NSObject

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;

@end
