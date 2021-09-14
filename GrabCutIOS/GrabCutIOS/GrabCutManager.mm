//
//  GrabCutManager.m
//  OpenCVTest
//
//  Created by EunchulJeon on 2015. 8. 29..
//  Copyright (c) 2015 Naver Corp.
//  @Author Eunchul Jeon
//

#import "GrabCutManager.h"
#import <opencv2/opencv.hpp>

using namespace cv;

@implementation GrabCutManager

Mat mask, bgModel,fgModel;

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
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

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
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

- (void)cvMatMaskerFromUIImage:(UIImage *) image{
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    //    cv::Mat1b markers((int)height, (int)width);
    //    markers.setTo(cv::GC_PR_BGD);
//    cv::Mat1b markers = mask;
    uchar* data =  mask.data;
    
    int countFGD=0, countBGD=0, countRem = 0;
    
    for(int x = 0; x < width; x++){
        for( int y = 0; y < height; y++){
            NSUInteger byteIndex = ((image.size.width  * y) + x ) * 4;
            UInt8 red   = rawData[byteIndex];
            UInt8 green = rawData[byteIndex + 1];
            UInt8 blue  = rawData[byteIndex + 2];
            UInt8 alpha = rawData[byteIndex + 3];
            
            if(red == 255 && green == 255 && blue == 255){
                data[width*y + x] = cv::GC_FGD;
                countFGD++;
            }else if(red == 0 && green == 0 && blue == 0 && alpha != 0){
                data[width*y + x] = cv::GC_BGD;
                countBGD++;
            }else{
                countRem++;
            }
        }
    }
    
    free(rawData);
    
//    NSLog(@"Count %d %d %d sum : %d width*height : %d", countFGD, countBGD, countRem, countFGD+countBGD + countRem, width*height);
    
//    return markers;
}


-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

-(Mat3b) maskImageToMatrix:(CGSize)imageSize{
    int cols = imageSize.width;
    int rows = imageSize.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC3); // 8 bits per component, 4 channels (color channels + alpha)
    cvMat.setTo(0);
    
    uchar* data = mask.data;
    
    int fgd,bgd,pfgd,pbgd;
    fgd = 0;
    bgd = 0;
    pfgd = 0;
    pbgd = 0;
    
    for(int y = 0; y < rows; y++){
        for( int x = 0; x < cols; x++){
            int index = cols*y+x;
            if(data[index] == GC_FGD){
                cvMat.at<Vec3b>(cv::Point(x,y)) = Vec3b(255,0,0);
                fgd++;
            }else if(data[index] == GC_BGD){
                cvMat.at<Vec3b>(cv::Point(x,y)) = Vec3b(0,255,0);
                bgd++;
            }else if(data[index] == GC_PR_FGD){
                cvMat.at<Vec3b>(cv::Point(x,y)) = Vec3b(0,0,255);
                pfgd++;
            }else if(data[index] == GC_PR_BGD){
                cvMat.at<Vec3b>(cv::Point(x,y)) = Vec3b(255,255,0);
                pbgd++;
            }
        }
    }
    
    NSLog(@"fgd : %d bgd : %d pfgd : %d pbgd : %d total : %d width*height : %d", fgd,bgd,pfgd,pbgd, fgd+bgd+pfgd+pbgd, cols*rows);
    
    return cvMat;
}

-(Mat4b) resultMaskToMatrix:(CGSize)imageSize{
    int cols = imageSize.width;
    int rows = imageSize.height;

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    cvMat.setTo(0);

    uchar* data = mask.data;

    int fgd,bgd,pfgd,pbgd;
    fgd = 0;
    bgd = 0;
    pfgd = 0;
    pbgd = 0;

    for(int y = 0; y < rows; y++){
        for( int x = 0; x < cols; x++){
            int index = cols*y+x;
            if(data[index] == GC_FGD){
                cvMat.at<Vec4b>(cv::Point(x,y)) = Vec4b(0,0,0,255);
                fgd++;
            }else if(data[index] == GC_BGD){
                cvMat.at<Vec4b>(cv::Point(x,y)) = Vec4b(255,255,255,255);
                bgd++;
            }else if(data[index] == GC_PR_FGD){
                cvMat.at<Vec4b>(cv::Point(x,y)) = Vec4b(0,0,0,255);
                pfgd++;
            }else if(data[index] == GC_PR_BGD){
                cvMat.at<Vec4b>(cv::Point(x,y)) = Vec4b(255,255,255,255);
                pbgd++;
            }
        }
    }

    NSLog(@"fgd : %d bgd : %d pfgd : %d pbgd : %d total : %d width*height : %d", fgd,bgd,pfgd,pbgd, fgd+bgd+pfgd+pbgd, cols*rows);

    return cvMat;
}


-(void) resetManager{
    mask.setTo(cv::GC_PR_BGD);
    bgModel.setTo(0);
    fgModel.setTo(0);
}

-(void) cropContours:(Mat *) img
{
    try
    {
        threshold(*img, *img, 1, 255, 0);
        medianBlur(*img, *img, 5);
        threshold(*img, *img, 225, 255, 0);
    }
    catch (const std::exception&)
    {
        NSLog(@"crop contours went wrong");
    }
}

-(Mat4b) resultMaskToMatrix:(CGSize)imageSize :(int)maxValue{
    int cols = imageSize.width;
    int rows = imageSize.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    cvMat.setTo(0);
  
        uint8_t* data = mask.data;
    
        int fgd = 0;
        int bgd = 0;
        int pfgd = 0;
        int pbgd = 0;
    
        uint8_t * cvMatPtr = (uint8_t *)cvMat.data;
        for(int y = 0; y < rows; y++){
            for( int x = 0; x < cols; x++){
                
                int index = cols*y+x;
    
                Vec4b result;
    
                if(data[index] == GC_FGD){
                    result = Vec4b(0,0,0,maxValue);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(0,0,0,255);
                    fgd++;
                }else if(data[index] == GC_BGD){
                    result = Vec4b(maxValue,maxValue,maxValue,maxValue);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(255,255,255,255);
                    bgd++;
                }else if(data[index] == GC_PR_FGD){
                    result = Vec4b(0,0,0,maxValue);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(0,0,0,255);
                    pfgd++;
                }else if(data[index] == GC_PR_BGD){
                    result = Vec4b(maxValue,maxValue,maxValue,maxValue);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(255,255,255,255);
                    pbgd++;
                }
                else
                {
                    continue;
                }
    
                cvMatPtr[index * 4 + 0] = result[0]; // b
                cvMatPtr[index * 4 + 1] = result[1]; // g
                cvMatPtr[index * 4 + 2] = result[2]; // r
                cvMatPtr[index * 4 + 3] = result[3]; // a
            }
        }
    
//    NSLog(@"fgd : %d bgd : %d pfgd : %d pbgd : %d total : %d width*height : %d", fgd,bgd,pfgd,pbgd, fgd+bgd+pfgd+pbgd, cols*rows);
    
    return cvMat;
}

-(void) getGrabCuttedMask:(Mat)img foregroundBound:(CGRect)rect{
    rectangle = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  
    // GrabCut segmentation
    grabCut(img,                    // input image
                mask,               // segmentation result
                rectangle,          // rectangle containing foreground
                bgModel,fgModel,    // models
                5,                  // number of iterations
                GC_INIT_WITH_RECT); // use rectangle
}


-(void) doGrabCutWithMask:(Mat)img maskImage:(UIImage*)maskImage{
    [self cvMatMaskerFromUIImage:maskImage];
    
    grabCut(img, mask, rectangle, bgModel, fgModel, 5, GC_INIT_WITH_MASK);
    
    uint8_t* maskRectPtr = (uint8_t*)mask.data;
    
    for (int i = 0; i < mask.rows; i++)
    {
        for (int j = 0; j < mask.cols; j++)
        {
            int32_t index = i * mask.cols + j;
            
            uint8_t maskRectIntensity = maskRectPtr[index]; // Gray

            if (maskRectIntensity == (uint8_t)GC_FGD || maskRectIntensity == (uint8_t)GC_PR_FGD)
            {
                maskRectPtr[index] = (uint8_t)255;//GC_FGD;
//                NSLog(@"intensity : %d x : %d y : %d", 255,i,j);
            }
            else
            {
                maskRectPtr[index] = (uint8_t)0;//GC_BGD;
            }
        }
    }
    
    [self cropContours:&mask];
}

-(UIImage *)CorrectUIImageFromCVMat:(Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];

    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        // OpenCV defaults to either BGR or ABGR. In CoreGraphics land,
        // this means using the "32Little" byte order, and potentially
        // skipping the first pixel. These may need to be adjusted if the
        // input matrix uses a different pixel format.
        bitmapInfo = kCGBitmapByteOrder32Little | (
            cvMat.elemSize() == 3? kCGImageAlphaNone : kCGImageAlphaNoneSkipFirst
        );
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(
        cvMat.cols,                 //width
        cvMat.rows,                 //height
        8,                          //bits per component
        8 * cvMat.elemSize(),       //bits per pixel
        cvMat.step[0],              //bytesPerRow
        colorSpace,                 //colorspace
        bitmapInfo,                 // bitmap info
        provider,                   //CGDataProviderRef
        NULL,                       //decode
        false,                      //should interpolate
        kCGRenderingIntentDefault   //intent
    );

    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

-(UIImage*) grabCut:(UIImage*)sourceImage Rectangle:(CGRect)rect Mask:(UIImage*)maskImage RelativeTo:(UIImage*)relativeTo {
    Mat img=[self cvMatFromUIImage:sourceImage];
    Mat imImg;
    cvtColor(img, imImg, COLOR_RGBA2RGB);
    
    UIImage* resultImage;
    
    rectangle = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    if (maskImage == nullptr) {
        cv::grabCut(imImg,              // input image
                mask,                   // segmentation result
                rectangle,              // rectangle containing foreground
                bgModel, fgModel,       // models
                5,                      // number of iterations
                cv::GC_INIT_WITH_RECT); // use rectangle
        
        // Get the pixels marked as likely foreground
        resultImage = [self UIImageFromCVMat:[self resultMaskToMatrix:sourceImage.size]];
    } else {
        maskImage = [self resizeImage:maskImage size:relativeTo.size];
        [self cvMatMaskerFromUIImage:maskImage];
        
        // GrabCut segmentation
        cv::grabCut(imImg, mask, rectangle, bgModel, fgModel, 5, cv::GC_INIT_WITH_MASK);
        
        Mat tempMask;
        compare(mask, cv::GC_PR_FGD, tempMask, cv::CMP_EQ);
        // Generate output image
        Mat foreground(img.size(), CV_8UC3, Scalar(255,255,255));
        
        tempMask=tempMask&1;
        imImg.copyTo(foreground, tempMask);
        resultImage=[self UIImageFromCVMat:foreground];
    }
    
    resultImage = [self masking:relativeTo mask:[self resizeImage:resultImage size:relativeTo.size]];
    return resultImage;
//    ?
//            [self getGrabCuttedMask:imImg foregroundBound:rect] :
//            [self doGrabCutWithMask:imImg maskImage:maskImage];

//    return resultImage;

//    Mat tempMask = [self resultMaskToMatrix:sourceImage.size :255];
//    [self cropContours:&tempMask];
//    UIImage* masked = [self UIImageFromCVMat:tempMask];
//    UIImage* image = [self masking:relativeTo mask:masked];
//    cvtColor(mask,mask,COLOR_GRAY2RGB);
//    cvtColor(img, img, COLOR_RGBA2BGRA);
//    multiply(tempMask, img, img);
//    UIImage* transparentImage = [self TransparentUIImageFromCVMat:(img)];//CvFilters::makeTransparent
////    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation(image)];    // rewrap
//    UIImageWriteToSavedPhotosAlbum(transparentImage, nil, nil, nil);  // save to photo album
//    return pngImage;
//    return  image;
//    return [self CorrectUIImageFromCVMat:img];
}

-(UIImage*) resizeImage:(UIImage*)image size:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), [image CGImage]);
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

-(UIImage *) masking:(UIImage*)sourceImage mask:(UIImage*) maskImage{
    //Mask Image
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([sourceImage CGImage], mask);
    CGImageRelease(mask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:masked];
    
    CGImageRelease(masked);
    
    return maskedImage;
}

//-(UIImage*) doGrabCut:(UIImage*)sourceImage foregroundBound:(CGRect)rect iterationCount:(int) iterCount{
//    Mat img=[self cvMatFromUIImage:sourceImage];
//    cvtColor(img , img , CV_RGBA2RGB);
//    Rect rectangle(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//
//    // GrabCut segmentation
//    grabCut(img,                      // input image
//            mask,                     // segmentation result
//            rectangle,                // rectangle containing foreground
//            bgModel,fgModel,          // models
//            iterCount,                // number of iterations
//            cv::GC_INIT_WITH_RECT);   // use rectangle
//
//    // Get the pixels marked as likely foreground
//    UIImage* resultImage = [self UIImageFromCVMat:[self resultMaskToMatrix:sourceImage.size]];
//
//    return resultImage;
//}
//
//-(UIImage*) doGrabCutWithMask:(UIImage*)sourceImage maskImage:(UIImage*)maskImage iterationCount:(int) iterCount{
//    Mat img=[self cvMatFromUIImage:sourceImage];
//    cvtColor(img , img , CV_RGBA2RGB);
//
//    Mat1b markers=[self cvMatMaskerFromUIImage:maskImage];
//    Rect rectangle(0,0,0,0);
//
//    // GrabCut segmentation
//    grabCut(img, markers, rectangle, bgModel, fgModel, iterCount, cv::GC_INIT_WITH_MASK);
//
//    Mat tempMask;
//    compare(mask,cv::GC_PR_FGD,tempMask,cv::CMP_EQ);
//    // Generate output image
//    Mat foreground(img.size(),CV_8UC3,
//                       Scalar(255,255,255));
//
//    tempMask=tempMask&1;
//    img.copyTo(foreground, tempMask);
//
//    UIImage* resultImage=[self UIImageFromCVMat:foreground];
//
//    return resultImage;
//}
@end
