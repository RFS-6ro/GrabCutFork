//
//  GrabCutManager.h
//  OpenCVTest
//
//  Created by EunchulJeon on 2015. 8. 29..
//  Copyright (c) 2015 Naver Corp.
//  @Author Eunchul Jeon
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/highgui/highgui_c.h>
#import <opencv2/core/core_c.h>
using namespace cv;


@interface GrabCutManager : NSObject{
    cv::Mat mask; // segmentation (4 possible values)
    cv::Mat bgModel,fgModel; // the models (internally used)
    cv::Rect rectangle;
}
-(UIImage*) grabCut:(UIImage*)img Rectangle:(CGRect)rect Mask:(UIImage*)mask RelativeTo:(UIImage*)relativeTo;
-(void) resetManager;
@end
