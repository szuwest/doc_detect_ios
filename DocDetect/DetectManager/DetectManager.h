//
//  DetectManager.h
//  DocDetect
//
//  Created by kk on 2020/3/31.
//  Copyright © 2020 wegene. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define HED_INPUT_WIDTH 256

//@protocol DetectManagerDelegate <NSObject>
//
//@optional
//
//- (void)onDectectDoc:(UIImage *_Nonnull)image;
//
//
//@end

@interface ProcessResult : NSObject

@property (nonatomic, assign) double processTime;

@property (nonatomic, copy) NSArray* _Nonnull  fourPoints;

@end

NS_ASSUME_NONNULL_BEGIN

@interface DetectManager : NSObject

//@property (nonatomic, weak) id<DetectManagerDelegate> delegate;

- (UIImage *)processFrame:(CVImageBufferRef)imgBufferRef;

//专门为TensorFlow输出的结构转为image用的
- (UIImage *)convertDataToImage:(NSData *)data;

//根据HED网络得出的边缘图，找出四边形的4个顶点
- (ProcessResult *_Nonnull)processEdgeImg:(NSData *)edgeImageData;

//将从HED边缘图上的坐标转换成别的坐标
- (CGPoint)converPoint:(CGPoint)point toSize:(CGSize)size;

//根据4个点裁剪在视频帧中裁剪出图片
- (UIImage *)cropImageBuffer: (CVImageBufferRef)imgBufferRef withPoints:(NSArray *)points;

@end

NS_ASSUME_NONNULL_END
