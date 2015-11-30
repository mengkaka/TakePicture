//
//  K12MistakenWriteController.h
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "K12TextInputManager.h"

@class K12OfflineMistakenWriteController;
@protocol K12OfflineMistakenWriteControllerDelegate <NSObject>
- (void)offlineMistakenWriteController:(K12OfflineMistakenWriteController *)controller willUploadWithSummary:(NSString *)summary withImages:(NSArray *)images; //要上传时回调
- (void)offlineMistakenWriteControllerDidCancel:(K12OfflineMistakenWriteController *)controller; //取消以后回调
- (void)offlineMistakenWriteControllerWillAddMistakenImage:(K12OfflineMistakenWriteController *)controller; //继续添加照片回调
@end

@interface K12OfflineMistakenWriteController : UIViewController
{
    K12TextInputManager *_inputManager;
    NSMutableArray *_imageSet;
    
    UIScrollView *_scrollView;
    UIView *_scrollContentView;
}
- (void)addMistakenImage:(UIImage *)image;
@property (nonatomic, weak) id <K12OfflineMistakenWriteControllerDelegate> delegate;
@end
