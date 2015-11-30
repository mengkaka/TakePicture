//
//  K12PictureCuttingTransitioning.h
//  TakePhoto
//
//  Created by mengkai on 15/10/21.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, K12ModalPresentingType) {
    K12ModalPresentingTypePresent,
    K12ModalPresentingTypeDismiss
};

@interface K12PictureCuttingTransitioning : NSObject<UIViewControllerAnimatedTransitioning>
- (void)resetImageView:(UIImageView *)imageView andPresentingType:(K12ModalPresentingType)type;
@end
