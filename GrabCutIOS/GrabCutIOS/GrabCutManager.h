//
//  GrabCutManager.h
//  OpenCVTest
//
//  Created by EunchulJeon on 2015. 8. 29..
//  Copyright (c) 2015 Naver Corp.
//  @Author Eunchul Jeon
//

//#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import "GrabCutManager.h"
//#import <opencv2/imgproc/imgproc_c.h>
//#import <opencv2/highgui/highgui_c.h>
//#import <opencv2/core/core_c.h>
//#import <opencv2/opencv.hpp>
//#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

@interface GrabCutManager : NSObject{
    CGRect rectangle;
}
-(UIImage*) grabCut:(UIImage*)img Rectangle:(CGRect)rect Mask:(UIImage*)mask RelativeTo:(UIImage*)relativeTo;
-(void) resetManager;


-(UIImage*) doGrabCut:(UIImage*)sourceImage foregroundBound:(CGRect) rect iterationCount:(int)iterCount;
-(UIImage*) doGrabCutWithMask:(UIImage*)sourceImage maskImage:(UIImage*)maskImage iterationCount:(int) iterCount;
-(UIImage*) smoothWhiteBounds:(UIImage*)sourceImage;
@end
