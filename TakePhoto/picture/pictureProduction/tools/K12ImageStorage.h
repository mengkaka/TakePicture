//
//  K12ImageStorage.h
//  wenku-k12
//
//  Created by mengkai on 15/10/29.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AssetsLibrary;
@import Photos;

@interface K12ImageStorage : NSObject
+ (void)writeImageToPhotoLibraryIOS7AndBefor:(UIImage *__nullable)image completionBlock:(nullable void(^)(NSURL *__nullable assetURL, NSError *__nullable error))completionBlock;
+ (void)writeImageToPhotoLibraryIOS8AndLater:(UIImage *__nullable)image completionBlock:(nullable void(^)(BOOL success, NSError *__nullable error))completionBlock;

+ (void)writeImageToPhotoLibrary:(UIImage *__nullable)image completionBlock:(nullable void(^)(BOOL success, NSError *__nullable error))completionBlock;
@end
