//
//  K12ImageBrowserViewController.h
//  TakePhoto
//
//  Created by mengkai on 15/10/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
@class K12PictureBrowserController;
@protocol K12PictureBrowserControllerDelegate <NSObject>
- (void)pictureBrowserController:(K12PictureBrowserController *)controller didConfirmImage:(UIImage *)image;
@end

@interface K12PictureBrowserController : UIViewController <UIScrollViewDelegate>
{
    UIImage *_image;
    UIScrollView *_scrollView;
    UIImageView *_imageView;
    BOOL _statusBarHidden;
    UIToolbar *_toolBar;
    
    BOOL _showBottomBar;
}

- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, assign) BOOL showBottomBar;
@property (nonatomic, weak) id <K12PictureBrowserControllerDelegate> delegate;
@end
