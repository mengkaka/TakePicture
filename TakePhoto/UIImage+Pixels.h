//
//  UIImage+Pixels.h
//  TakePhoto
//
//  Created by mengkai on 15/9/29.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreMedia;

@interface UIImage (Pixels)
- (unsigned char*) grayscalePixels;
- (const unsigned char*) rgbaPixels;
- (UIColor *)averageColor;
- (double)luminance;

+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
+ (double)luminanceWithSampleBuffer:(CMSampleBufferRef) sampleBuffer;

//static double CVImageBufferGetLuminance(CVImageBufferRef imageBuffer);
@end
