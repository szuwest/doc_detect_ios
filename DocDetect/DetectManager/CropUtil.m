//
//  PointUtil.m
//  DocDetect
//
//  Created by kk on 2020/4/3.
//  Copyright © 2020 wegene. All rights reserved.
//

#import "CropUtil.h"
#import <math.h>

@implementation CropUtil

+ (double)getDistance:(CGPoint)point1 withPoint:(CGPoint)point2 {
    return getPointsDistance(point1.x, point1.y, point2.x, point2.y);
}

static double getPointsDistance(float x1, float y1, float x2, float y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

+ (BOOL)isQuadSimilar:(NSArray *)fourPoints withPoints:(NSArray *)otherPoints {
    if (fourPoints.count == 4 && otherPoints.count == 4) {
        BOOL similar = false;
        CGFloat OFFSET = 5;
        for (int i=0; i<4; i++) {
            CGPoint p1 = [fourPoints[i] CGPointValue];
            CGPoint p2 = [otherPoints[i] CGPointValue];
            CGFloat offsetX = fabs(p1.x - p2.x);
            CGFloat offsetY = fabs(p1.y - p2.y);
            NSLog(@"offsetX=%f, offsetY=%f", offsetX, offsetY);
            similar = (offsetX <= OFFSET && offsetY <= OFFSET);
            if (!similar) {
                break;
            }
        }
        return similar;
    }
    return NO;
}

//public static boolean isRectSimilar(Point[] fourPoints, Point[] otherPoints) {
//    if (CropUtils.checkPoints(fourPoints) && CropUtils.checkPoints(otherPoints)) {
//        boolean similar = false;
//        for (int i=0; i<4; i++) {
//            float xOffset = Math.abs(fourPoints[i].x - otherPoints[i].x);
//            float yOffset = Math.abs(fourPoints[i].y - otherPoints[i].y);
//            Log.d("DetectHelper", " point[" + i + "]" + " x offset=" + xOffset + " y offset=" + yOffset);
//            similar = xOffset <= OFFSET && yOffset <= OFFSET;
//            if (!similar) {
//                break;
//            }
//        }
//        return similar;
//    }
//    return false;
//}

@end
