//
//  NSData+OpenCV.mm
//  GrabCutIOS
//
//  Created by Daniil  on 22.03.2021.
//  Copyright © 2021 EunchulJeon. All rights reserved.
//

#import "NSData+OpenCV.h"

@implementation NSData_OpenCV

// cv::Mat from NSMutableData
- (cv::Mat)CVMat {

    UIImage *image = nil;//[UIImage imageWithData:self];

CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
CGFloat cols = image.size.width;
CGFloat rows = image.size.height;

cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                cols,                       // Width of bitmap
                                                rows,                       // Height of bitmap
                                                8,                          // Bits per component
                                                cvMat.step[0],              // Bytes per row
                                                colorSpace,                 // Colorspace
                                                kCGImageAlphaNoneSkipLast |
                                                kCGBitmapByteOrderDefault); // Bitmap info flags

CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
CGContextRelease(contextRef);

return cvMat;
}

- (cv::Mat)CVGrayscaleMat {

    UIImage *image = nil;//[UIImage imageWithData:self];

CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
CGFloat cols = image.size.width;
CGFloat rows = image.size.height;

cv::Mat cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channel

CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                cols,                       // Width of bitmap
                                                rows,                       // Height of bitmap
                                                8,                          // Bits per component
                                                cvMat.step[0],              // Bytes per row
                                                colorSpace,                 // Colorspace
                                                kCGImageAlphaNone |
                                                kCGBitmapByteOrderDefault); // Bitmap info flags

CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
CGContextRelease(contextRef);
CGColorSpaceRelease(colorSpace);

return cvMat;
}

// NSData from cv::Mat
- (NSData *)NSDataFromCVMat:(cv::Mat)cvMat {

return [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];

/*
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];

    CGColorSpaceRef colorSpace;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 // width
                                        cvMat.rows,                                 // height
                                        8,                                          // bits per component
                                        8 * cvMat.elemSize(),                       // bits per pixel
                                        cvMat.step[0],                              // bytesPerRow
                                        colorSpace,                                 // colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   // CGDataProviderRef
                                        NULL,                                       // decode
                                        false,                                      // should interpolate
                                        kCGRenderingIntentDefault                   // intent
                                        );


    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return UIImageJPEGRepresentation(finalImage, 1.0);
 */

}
@end
