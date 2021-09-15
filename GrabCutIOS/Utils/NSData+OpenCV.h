//
//  NSData+OpenCV.h
//  GrabCutIOS
//
//  Created by Daniil  on 22.03.2021.
//  Copyright © 2021 EunchulJeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData_OpenCV : NSObject

- (NSData *)NSDataFromCVMat:(cv::Mat)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end

NS_ASSUME_NONNULL_END
