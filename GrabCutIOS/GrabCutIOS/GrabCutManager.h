#import <Foundation/Foundation.h>
#import "GrabCutManager.h"
#import <UIKit/UIKit.h>

@interface GrabCutManager : NSObject{}
-(UIImage*) grabCut:(UIImage*)img Resized:(UIImage*)resizedImage Rectangle:(CGRect)rect Mask:(UIImage*)mask iterationCount:(int)iterCount;
-(void) resetManager;
-(UIImage*) smoothWhiteBounds:(UIImage*)sourceImage;
@end
