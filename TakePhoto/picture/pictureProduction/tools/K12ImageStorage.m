//
//  K12ImageStorage.m
//  wenku-k12
//
//  Created by mengkai on 15/10/29.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12ImageStorage.h"

#ifndef IOS8_OR_LATER
#define IOS8_OR_LATER    ([[UIDevice currentDevice].systemVersion compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)
#endif

@implementation K12ImageStorage
static ALAssetsLibrary *defultAssetsLibrary__ = nil;
+ (ALAssetsLibrary *)defultAssetsLibrary{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defultAssetsLibrary__ = [[ALAssetsLibrary alloc]init];
    });
    return defultAssetsLibrary__;
}

static PHAssetCollection *defultAssetCollection__ = nil;
+ (PHAssetCollection *)defultAssetCollection{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defultAssetCollection__ = [[PHAssetCollection alloc]init];
    });
    return defultAssetCollection__;
}

+ (void)writeImageToPhotoLibraryIOS7AndBefor:(UIImage *__nullable)image completionBlock:(nullable void(^)(NSURL *__nullable assetURL, NSError *__nullable error))completionBlock{
    [self.defultAssetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:completionBlock];
}

+ (void)writeImageToPhotoLibraryIOS8AndLater:(UIImage *)image completionBlock:(nullable void(^)(BOOL success, NSError *__nullable error))completionBlock{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        // Request editing the album.
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.defultAssetCollection];
        
        // Get a placeholder for the new asset and add it to the album editing request.
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        
    } completionHandler:completionBlock];
}


+ (void)writeImageToPhotoLibrary:(UIImage *__nullable)image completionBlock:(nullable void(^)(BOOL success, NSError *__nullable error))completionBlock{
    if(!IOS8_OR_LATER){
        [self writeImageToPhotoLibraryIOS8AndLater:image completionBlock:completionBlock];
    }else{
        [self writeImageToPhotoLibraryIOS7AndBefor:image completionBlock:^(NSURL * _Nullable assetURL, NSError * _Nullable error) {
            if(completionBlock){
                completionBlock((error==nil)?YES:NO , error);
            }
        }];
    }
}
@end
