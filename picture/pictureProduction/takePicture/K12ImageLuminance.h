//
//  K12ImageLuminance.h
//  TakePhoto
//
//  Created by mengkai on 15/9/30.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreMedia;

@interface UIImage (Pixels)
- (unsigned char*) grayscalePixels;
- (const unsigned char*) rgbaPixels;
- (UIColor *)averageColor;
- (double)luminance;
@end

@interface K12ImageLuminance : NSObject
+ (double)luminanceWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (double)luminanceWithCVImageBuffer:(CVImageBufferRef)imageBuffer;
@end
