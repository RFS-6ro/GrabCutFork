//
//  GrabCutManager.m
//  OpenCVTest
//
//  Created by EunchulJeon on 2015. 8. 29..
//  Copyright (c) 2015 Naver Corp.
//  @Author Eunchul Jeon
//

#import "GrabCutManager.h"
#import "CvFilters.h"
#import <opencv2/opencv.hpp>

using namespace cv;

@implementation GrabCutManager

Mat mask, bgModel,fgModel;


- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNone | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (Mat1b)cvMatMaskerFromUIImage:(UIImage *) image{
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t*) calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    //    Mat1b markers((int)height, (int)width);
    //    markers.setTo(GC_PR_BGD);
    cv::Mat1b markers = mask;
    uint8_t* data = (uint8_t*)markers.data;
    
    int countFGD=0, countBGD=0, countRem = 0;
    
    for(int x = 0; x < mask.cols; x++){
        for( int y = 0; y < mask.rows; y++){
            NSUInteger byteIndex = ((mask.cols  * y) + x ) * 4;
            uint8_t red   = rawData[byteIndex];
            uint8_t green = rawData[byteIndex + 1];
            uint8_t blue  = rawData[byteIndex + 2];
            uint8_t alpha = rawData[byteIndex + 3];
            
            //NSLog(@"pixel : %d a : %d r : %d g : %d b ", alpha, red, green, blue);
            if (red == 255 && green == 255 && blue == 255 && alpha == 255) {
                data[mask.cols * y + x] = GC_PR_FGD;//не срабатывает и не находит белых точек. Нужно найти какой код будет обозначать белые полосы и все должно быть ок.
                countFGD++;                      //Что ты будешь делать с ошибкой, которая сейчас на экране - хуй знает, проблемы завтрашнего меня
            } else if (red == 0 && green == 0 && blue == 0 && alpha == 255) {
                data[mask.cols * y + x] = GC_BGD;
                countBGD++;
            } else {
                countRem++;
            }
        }
    }
    
    free(rawData);
    
    return markers;
}


-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    CGBitmapInfo info = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else if (cvMat.elemSize() == 3) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    } else if (cvMat.elemSize() == 4) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        info = kCGImageAlphaLast | kCGBitmapByteOrderDefault;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                //width
                                        cvMat.rows,                //height
                                        8,                         //bits per component
                                        8 * cvMat.elemSize(),      //bits per pixel
                                        cvMat.step[0],             //bytesPerRow
                                        colorSpace,                //colorspace
                                        info,                      //bitmap info
                                        provider,                  //CGDataProviderRef
                                        NULL,                      //decode
                                        false,                     //should interpolate
                                        kCGRenderingIntentDefault  //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
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
                    result = Vec4b(maxValue,maxValue,maxValue,0);
//                    cvMat.at<Vec4b>(Point(x,y)) = Vec4b(0,0,0,255);
                    fgd++;
                }else if(data[index] == GC_BGD){
                    result = Vec4b(0,0,0,maxValue);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(255,255,255,255);
                    bgd++;
                }else if(data[index] == GC_PR_FGD){
                    result = Vec4b(maxValue,maxValue,maxValue,0);
    //                cvMat.at<Vec4b>(Point(x,y)) = Vec4b(0,0,0,255);
                    pfgd++;
                }else if(data[index] == GC_PR_BGD){
                    result = Vec4b(0,0,0,maxValue);
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
    
    return cvMat;
}


-(void) resetManager{
    mask.setTo(GC_PR_BGD);
    mask.setTo(0);
    bgModel.setTo(0);
    fgModel.setTo(0);
}




//-(void) getGrabCuttedMask:(Mat)img foregroundBound:(CGRect)rect{
//    rectangle = rect;//;
//
//    // GrabCut segmentation
//    grabCut(img,                    // input image
//                mask,                   // segmentation result
//            cv::Rect(rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height),              // rectangle containing foreground
//                bgModel,fgModel,        // models
//                5,                      // number of iterations
//                GC_INIT_WITH_RECT); // use rectangle
////    uint8_t* rawData = mask.data;
////    for(int x = 0; x < img.cols; x++){
////        for( int y = 0; y < img.rows; y++){
////            NSUInteger byteIndex = ((img.cols  * y) + x );
////            uint8_t intensity = rawData[byteIndex];
////
////            if(intensity != 0){
////                NSLog(@"intensity : %d x : %d y : %d", intensity,x,y);
////            }
////        }
////    }
//    // Get the pixels marked as likely foreground
////    [self resultMaskToMatrix:sourceImage.size];
////
////    Mat result;
////
////    CvFilters::cropContours(&mask);
////    cvtColor(mask,mask,COLOR_GRAY2BGR);//#change mask to a 3 channel image
////    Mat mask_out;
////    subtract(img, mask, mask_out);
////    subtract(mask, mask_out, mask_out);//    UIImage* MatToUIImage(const Mat& image)
////
////    Mat cvMat = CvFilters::makeTransparent(img);
////    return [self UIImageFromCVMat:[self resultMaskToMatrix:sourceImage.size]];
//}




//-(void) doGrabCutWithMask:(Mat)img maskImage:(UIImage*)maskImage{
//    [self cvMatMaskerFromUIImage:maskImage];
//
//    grabCut(img, mask, cv::Rect(rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height), bgModel, fgModel, 5, GC_INIT_WITH_MASK);
//
//    uint8_t* maskDataPtr = (uint8_t*)mask.data;
//
//    for (int i = 0; i < mask.rows; i++)
//    {
//        for (int j = 0; j < mask.cols; j++)
//        {
//            int32_t index = i * mask.cols + j;
//
//            uint8_t maskRectIntensity = maskDataPtr[index]; // Gray
//
//            if (maskRectIntensity == (uint8_t)GC_FGD || maskRectIntensity == (uint8_t)GC_PR_FGD)
//            {
//                maskDataPtr[index] = (uint8_t)255;//GC_FGD;
////                NSLog(@"intensity : %d x : %d y : %d", 255,i,j);
//            }
//            else
//            {
//                maskDataPtr[index] = (uint8_t)0;//GC_BGD;
//            }
//        }
//    }
//
//    CvFilters::cropContours(&mask);
//
//    // Generate output image
//
////    Mat foreground(img.size(), CV_8UC3);
//    //return MatToUIImage(CvFilters::makeTransparent(mask));
//
////    img.copyTo(foreground, mask);
////    foreground.convertTo(foreground, CV_32FC3, 1.0/255);
////    multiply(foreground, img, img);
//
//
////    cvtColor(mask,mask,COLOR_GRAY2BGR);//#change mask to a 3 channel image
////    Mat mask_out;
////    subtract(img, mask, mask_out);
////    subtract(mask, mask_out, mask_out);//    UIImage* MatToUIImage(const Mat& image)
////
////    Mat cvMat = CvFilters::makeTransparent(img);
////    return [self UIImageFromCVMat: mask];
////    return [self UIImageFromCVMat:[self resultMaskToMatrix:sourceImage.size]];
////    UIImage* resultImage = MatToUIImage(CvFilters::makeTransparent(foreground));
////    UIImage* resultImage=[self UIImageFromCVMat:CvFilters::makeTransparent(foreground)];//[self resultMaskToMatrix:sourceImage.size]];
////    UIImageWriteToSavedPhotosAlbum(resultImage,nil,nil,nil);
//
////    return [self UIImageFromCVMat: cvMat];
//
//
//
////    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation([self UIImageFromCVMat: cvMat])];    // rewrap
////    UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil);  // save to photo album
////    return pngImage;
//}




-(UIImage *)CorrectUIImageFromCVMat:(cv::Mat)cvMat {
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
//    UIImage* resultImage =
    Mat img=[self cvMatFromUIImage:sourceImage];
    Mat imImg;
    cvtColor(img, imImg, CV_RGBA2RGB);
//    maskImage == nullptr ?
//            [self getGrabCuttedMask:imImg foregroundBound:rect] :
//            [self doGrabCutWithMask:imImg maskImage:maskImage];

//    return resultImage;

    Mat tempMask = [self resultMaskToMatrix:sourceImage.size :255];
    
//            uint8_t* transparentImgPtr = (uint8_t*)tempMask.data;
//
//            for (int i = 0; i < tempMask.rows; i++)
//            {
//                for (int j = 0; j < tempMask.cols; j++)
//                {
//                    uint32_t index = i * tempMask.cols * 4 + j * 4;
//                    uint8_t r = transparentImgPtr[index + 0]; // r
//                    uint8_t g = transparentImgPtr[index + 1]; // g
//                    uint8_t b = transparentImgPtr[index + 2]; // b
//
//                    NSLog(@"pixel %d %d %d", r, g, b);
//                }
//            }
    CvFilters::cropContours(&tempMask);
//    UIImage* masked = [self UIImageFromCVMat:mask];
//    UIImage* image = [self masking:relativeTo mask:masked];
//    cvtColor(mask,mask,COLOR_GRAY2RGB);
    cvtColor(img, img, CV_RGBA2BGRA);
    multiply(tempMask, img, img);
    
    UIImage* image = [self CorrectUIImageFromCVMat:(img)];//CvFilters::makeTransparent
    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation(image)];    // rewrap
    UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil);  // save to photo album
    return pngImage;
    
    return [self CorrectUIImageFromCVMat:img];
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

-(UIImage*) doGrabCut:(UIImage*)sourceImage foregroundBound:(CGRect)rect iterationCount:(int) iterCount{
    cv::Mat img=[self cvMatFromUIImage:sourceImage];
    cv::cvtColor(img , img , CV_RGBA2RGB);
    cv::Rect rectangle(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    // GrabCut segmentation
    cv::grabCut(img,    // input image
                mask,      // segmentation result
                rectangle,   // rectangle containing foreground
                bgModel,fgModel, // models
                iterCount,           // number of iterations
                cv::GC_INIT_WITH_RECT); // use rectangle
    // Get the pixels marked as likely foreground
    
//    Mat tempMask = [self resultMaskToMatrix:sourceImage.size :255];
    
    cv::Mat tempMask;
    cv::compare(mask,cv::GC_PR_FGD,tempMask,cv::CMP_EQ);
    
//    uint8_t* transparentImgPtr = (uint8_t*)tempMask.data;
//    uint8_t* transparentPtr = (uint8_t*)mask.data;
//
//    for (int i = 0; i < tempMask.rows; i++)
//    {
//        for (int j = 0; j < tempMask.cols; j++)
//        {
//            uint32_t index = i * tempMask.cols * 4 + j * 4;
//            uint8_t transparentImgIntensityb = transparentImgPtr[index + 0]; // b
//            uint8_t transparentImgIntensityg = transparentImgPtr[index + 1]; // g
//            uint8_t transparentImgIntensityr = transparentImgPtr[index + 2]; // r
//
//            uint8_t transparentIntensityb = transparentPtr[index + 0]; // b
//            uint8_t transparentIntensityg = transparentPtr[index + 1]; // g
//            uint8_t transparentIntensityr = transparentPtr[index + 2]; // r
//
//
//            NSLog(@"Count %d %d %d : %d %d %d",
//                  transparentImgIntensityb,
//                  transparentImgIntensityg,
//                  transparentImgIntensityr,
//                  transparentIntensityb,
//                  transparentIntensityg,
//                  transparentIntensityr);
//        }
//    }

    CvFilters::cropContours(&tempMask);
//    uint8_t* transparentImgPtr = (uint8_t*)tempMask.data;
//
//    for (int i = 0; i < tempMask.rows; i++)
//    {
//        for (int j = 0; j < tempMask.cols; j++)
//        {
//            uint32_t index = i * tempMask.cols * 4 + j * 4;
//            uint8_t r = transparentImgPtr[index + 0]; // r
//            uint8_t g = transparentImgPtr[index + 1]; // g
//            uint8_t b = transparentImgPtr[index + 2]; // b
//
//            NSLog(@"pixel %d %d %d", r, g, b);
//        }
//    }
    // Generate output image
    cv::Mat foreground(img.size(),CV_8UC3,
                       cv::Scalar(255,255,255));
    
    tempMask=tempMask&1;
    img.copyTo(foreground, tempMask);
    
    UIImage* resultImage = [self UIImageFromCVMat:foreground];
    
//    cv::Mat tempMask;
//    cv::compare(mask,cv::GC_PR_FGD,tempMask,cv::CMP_EQ);
//    // Generate output image
//    cv::Mat foreground(img.size(),CV_8UC3,
//                       cv::Scalar(255,255,255));
//
//    tempMask=tempMask&1;
//
//    UIImage* resultImage = [self UIImageFromCVMat:tempMask];
    
//    img.copyTo(foreground, tempMask);
    
//    UIImage* resultImage=[self UIImageFromCVMat:foreground];
    
    UIImage* image = [self UIImageFromCVMat:(foreground)];//CvFilters::makeTransparent
    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation(image)];    // rewrap
    UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil);  // save to photo album
    return pngImage;
    return resultImage;
}

-(UIImage*) doGrabCutWithMask:(UIImage*)sourceImage maskImage:(UIImage*)maskImage iterationCount:(int) iterCount{
    cv::Mat img=[self cvMatFromUIImage:sourceImage];
    cv::cvtColor(img , img , CV_RGBA2RGB);
    
    cv::Mat1b markers=[self cvMatMaskerFromUIImage:maskImage];
    cv::Rect rectangle(0,0,0,0);
    // GrabCut segmentation
    cv::grabCut(img, markers, rectangle, bgModel, fgModel, iterCount, cv::GC_INIT_WITH_MASK);
    
    cv::Mat tempMask;
    cv::compare(mask,cv::GC_PR_FGD,tempMask,cv::CMP_EQ);
    
//    uint8_t* transparentImgPtr = (uint8_t*)tempMask.data;
//    uint8_t* transparentPtr = (uint8_t*)mask.data;
//    
//    for (int i = 0; i < tempMask.rows; i++)
//    {
//        for (int j = 0; j < tempMask.cols; j++)
//        {
//            uint32_t index = i * tempMask.cols * 4 + j * 4;
//            uint8_t transparentImgIntensityb = transparentImgPtr[index + 0]; // b
//            uint8_t transparentImgIntensityg = transparentImgPtr[index + 1]; // g
//            uint8_t transparentImgIntensityr = transparentImgPtr[index + 2]; // r
//            
//            uint8_t transparentIntensityb = transparentPtr[index + 0]; // b
//            uint8_t transparentIntensityg = transparentPtr[index + 1]; // g
//            uint8_t transparentIntensityr = transparentPtr[index + 2]; // r
//            
//            
//            NSLog(@"Count %d %d %d : %d %d %d",
//                  transparentImgIntensityb,
//                  transparentImgIntensityg,
//                  transparentImgIntensityr,
//                  transparentIntensityb,
//                  transparentIntensityg,
//                  transparentIntensityr);
//        }
//    }
    CvFilters::cropContours(&tempMask);
//    uint8_t* transparentImgPtr = (uint8_t*)tempMask.data;
//
//    for (int i = 0; i < tempMask.rows; i++)
//    {
//        for (int j = 0; j < tempMask.cols; j++)
//        {
//            uint32_t index = i * tempMask.cols * 4 + j * 4;
//            uint8_t r = transparentImgPtr[index + 0]; // r
//            uint8_t g = transparentImgPtr[index + 1]; // g
//            uint8_t b = transparentImgPtr[index + 2]; // b
//
//            NSLog(@"pixel %d %d %d", r, g, b);
//        }
//    }
    // Generate output image
    cv::Mat foreground(img.size(),CV_8UC3,
                       cv::Scalar(255,255,255));
    
    tempMask=tempMask&1;
    img.copyTo(foreground, tempMask);
    
    UIImage* resultImage=[self UIImageFromCVMat:foreground];
    
    //    UIImage* resultImage =[self UIImageFromCVMat:[self maskImageToMatrix:sourceImage.size]];
    
    
    //    UIImage* resultImage=[self UIImageFromCVMat:[self maskImageToMatrix:sourceImage.size]];
    //    cv::Mat1b mask_fgpf = ( markers == cv::GC_FGD) | ( markers == cv::GC_PR_FGD);
    //    // and copy all the foreground-pixels to a temporary image
    //    cv::Mat3b tmp = cv::Mat3b::zeros(img.rows, img.cols);
    //    img.copyTo(tmp, mask_fgpf);
    
    
    //    UIImage* resultImage=[self UIImageFromCVMat:tmp];
    
    UIImage* image = [self UIImageFromCVMat:(foreground)];//CvFilters::makeTransparent
    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation(image)];    // rewrap
    UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil);  // save to photo album
    return pngImage;
    return resultImage;
}

-(UIImage*) smoothWhiteBounds:(UIImage*)sourceImage
{
    Mat mat = [self cvMatFromUIImage: sourceImage];
    cv::GaussianBlur(mat, mat, cv::Size(5, 5), 0);
    UIImage* resultImage = [self UIImageFromCVMat:mat];
    return resultImage;
}
@end
