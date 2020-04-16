//
//  PointUtil.h
//  DocDetect
//
//  Created by kk on 2020/4/3.
//  Copyright © 2020 wegene. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CropUtil : NSObject

+ (double)getDistance:(CGPoint)point1 withPoint:(CGPoint)point2;

+ (BOOL)isQuadSimilar:(NSArray *)fourPoints withPoints:(NSArray *)otherPoints;

@end

NS_ASSUME_NONNULL_END
