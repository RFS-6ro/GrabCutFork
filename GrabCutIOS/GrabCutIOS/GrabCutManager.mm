#import "GrabCutManager.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

using namespace cv;

@implementation GrabCutManager

Mat mask, bgModel,fgModel;

//- (Mat)cvMatFromUIImage:(UIImage *)image
//{
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
//    CGFloat cols = image.size.width;
//    CGFloat rows = image.size.height;
//
//    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
//
//    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
//                                                    cols,                       // Width of bitmap
//                                                    rows,                       // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault); // Bitmap info flags
//
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
//    CGContextRelease(contextRef);
//
//    return cvMat;
//}
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols,rows;
    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    else{
        cols = image.size.width;
        rows = image.size.height;

    }


    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);


    cv::Mat cvMatTest;
    cv::transpose(cvMat, cvMatTest);

    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {

    }
    else{
        return cvMat;

    }
    cvMat.release();

    cv::flip(cvMatTest, cvMatTest, 1);


    return cvMatTest;
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
            
            if (red == 255 && green == 255 && blue == 255 && alpha == 255) {
                data[mask.cols * y + x] = GC_PR_FGD;
                countFGD++;
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


//-(UIImage *)UIImageFromCVMat:(Mat)cvMat
//{
//    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
//    CGColorSpaceRef colorSpace;
//    CGBitmapInfo info = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
//    if (cvMat.elemSize() == 1) {
//        colorSpace = CGColorSpaceCreateDeviceGray();
//    } else if (cvMat.elemSize() == 3) {
//        colorSpace = CGColorSpaceCreateDeviceRGB();
//    } else if (cvMat.elemSize() == 4) {
//        colorSpace = CGColorSpaceCreateDeviceRGB();
//        info = kCGImageAlphaLast | kCGBitmapByteOrderDefault;
//    }
//
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
//
//    // Creating CGImage from Mat
//    CGImageRef imageRef = CGImageCreate(cvMat.cols,                //width
//                                        cvMat.rows,                //height
//                                        8,                         //bits per component
//                                        8 * cvMat.elemSize(),      //bits per pixel
//                                        cvMat.step[0],             //bytesPerRow
//                                        colorSpace,                //colorspace
//                                        info,                      //bitmap info
//                                        provider,                  //CGDataProviderRef
//                                        NULL,                      //decode
//                                        false,                     //should interpolate
//                                        kCGRenderingIntentDefault  //intent
//                                        );
//
//
//    // Getting UIImage from CGImage
//    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(colorSpace);
//
//    return finalImage;
//}

- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
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
                                        kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,// bitmap info
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

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols,rows;
    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    else{
        cols = image.size.width;
        rows = image.size.height;

    }


    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);


    cv::Mat cvMatTest;
    cv::transpose(cvMat, cvMatTest);

    if  (image.imageOrientation == UIImageOrientationLeft
         || image.imageOrientation == UIImageOrientationRight) {

    }
    else{
        return cvMat;

    }
    cvMat.release();

    cv::flip(cvMatTest, cvMatTest, 1);


    return cvMatTest;
}

-(UIImage *)UIImageWithTransparencyFromCVMat:(cv::Mat) cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    CGBitmapInfo info = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    if (cvMat.elemSize() != 4) {
        throw nil;
    }
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    info = (kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    
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
                    fgd++;
                }else if(data[index] == GC_BGD){
                    result = Vec4b(0,0,0,maxValue);
                    bgd++;
                }else if(data[index] == GC_PR_FGD){
                    result = Vec4b(maxValue,maxValue,maxValue,0);
                    pfgd++;
                }else if(data[index] == GC_PR_BGD){
                    result = Vec4b(0,0,0,maxValue);
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
        bitmapInfo,                 //bitmap info
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

-(UIImage*) grabCut:(UIImage*)sourceImage Resized:(UIImage*)resizedImage Rectangle:(CGRect)rect Mask:(UIImage*)maskImage iterationCount:(int)iterCount{
    
    cv::Mat img=[self cvMatFromUIImage:resizedImage];
    NSLog(@"img: %d %d", img.cols, img.rows);
    cv::cvtColor(img , img , COLOR_RGBA2RGB);
    
    
    if (maskImage)
    {
        cv::Mat1b markers=[self cvMatMaskerFromUIImage:maskImage];
        cv::Rect rectangle(0,0,0,0);
        // GrabCut segmentation
        cv::grabCut(img, markers, rectangle, bgModel, fgModel, iterCount, cv::GC_INIT_WITH_MASK);
    }
    else
    {
        cv::Rect rectangle(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        // GrabCut segmentation
        cv::grabCut(img, mask, rectangle, bgModel, fgModel, iterCount, cv::GC_INIT_WITH_RECT);
    }
    
    cv::Mat tempMask;
    cv::compare(mask,cv::GC_PR_FGD,tempMask,cv::CMP_EQ);
    
    [self cropContours:&tempMask];
    
    cv::Mat srcImg=[self cvMatFromUIImage:sourceImage];
    NSLog(@"srcImg: %d %d", srcImg.cols, srcImg.rows);
    
    // Generate output image
    cv::Mat foreground(srcImg.size() ,CV_8UC4,
                       cv::Scalar(255,255,255,255));
    
    tempMask=tempMask&1;
    
    NSLog(@"tempMask before: %d %d", tempMask.cols, tempMask.rows);
    cv::resize(tempMask, tempMask, srcImg.size());
    NSLog(@"tempMask after: %d %d", tempMask.cols, tempMask.rows);
    //[self resizeImage:tempMask size:sourceImage.size()]
    srcImg.copyTo(foreground, tempMask);
    
//    cv::cvtColor(foreground, foreground, COLOR_RGB2BGRA);
    
    uint8_t* data = (uint8_t*)foreground.data;
    
    long _r = 0, _g = 0, _b = 0, _a = 0;
    
    for(int x = 0; x < foreground.cols; x++){
        for( int y = 0; y < foreground.rows; y++){
            NSUInteger index = ((foreground.cols  * y) + x ) * 4;
//
            uint8_t B = data[index + 0];
            uint8_t G = data[index + 1];
            uint8_t R = data[index + 2];
            uint8_t A = data[index + 3];
//
            if (B == 255) {
                _b++;
            }
            
            if (G == 255) {
                _g++;
            }
            
            if (R == 255) {
                _r++;
            }
            
            if (A == 255) {
                _a++;
            }
            if (R == 255 && G == 255 && B == 255) {
                data[index + 3] = 0;
            }
        }
    }
    
    NSLog(@"%ld %ld %ld %ld %d %d", _b, _g, _r, _a, foreground.cols, foreground.rows);
    _r = 0; _g = 0; _b = 0; _a = 0;
    
        for(int x = 0; x < foreground.cols; x++){
            for( int y = 0; y < foreground.rows; y++){
                NSUInteger index = ((foreground.cols  * y) + x ) * 4;
    //
                uint8_t B = data[index + 0];
                uint8_t G = data[index + 1];
                uint8_t R = data[index + 2];
                uint8_t A = data[index + 3];
    //
                if (B == 255) {
                    _b++;
                }
                
                if (G == 255) {
                    _g++;
                }
                
                if (R == 255) {
                    _r++;
                }
                
                if (A == 255) {
                    _a++;
    //                data[index + 3] = 0;
                }
            }
        }
        NSLog(@"%ld %ld %ld %ld %d %d", _b, _g, _r, _a, foreground.cols, foreground.rows);
//
    UIImage* image = [self UIImageWithTransparencyFromCVMat:(foreground)];
    UIImage* pngImage = [UIImage imageWithData:UIImagePNGRepresentation(image)];
//    UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil);  // save to photo album
    return pngImage;
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

-(UIImage*) smoothWhiteBounds:(UIImage*)sourceImage
{
    Mat mat = [self cvMatFromUIImage: sourceImage];
    cv::GaussianBlur(mat, mat, cv::Size(5, 5), 0);
    UIImage* resultImage = [self UIImageFromCVMat:mat];
    return resultImage;
}
@end
