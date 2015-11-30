//
//  K12FocusViewControl.h
//  TakePhoto
//
//  Created by mengkai on 15/9/28.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class K12CameraFocusViewControl;
@protocol K12FocusViewControlDelegate <NSObject>
- (void)cameraFocusViewControl:(K12CameraFocusViewControl *)focusViewControl userWillFocussingPoint:(CGPoint)point;
- (void)cameraFocusViewControl:(K12CameraFocusViewControl *)focusViewControl userWillLockFocusPoint:(CGPoint)point;
@end

@interface K12CameraFocusViewControl : NSObject
{
    __weak UIView *_containerView;
    UITapGestureRecognizer *_tapGesture;
    UILongPressGestureRecognizer *_longPressGesture;
}
@property (readonly) UITapGestureRecognizer *tapGesture;
@property (readonly) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, weak) id <K12FocusViewControlDelegate> delegate;   //代理回调

+ (instancetype)focusViewControlWithView:(UIView *)view;
- (void)setFocusViewControlEnabled:(BOOL)enable;

- (void)autoFocusWithFocusPoint:(CGPoint)point; //声明当前自动对焦所对应焦点
- (void)userFocussingDidSucceed; //用户选择对焦成功
- (void)userFocussingDidFailed;  //用户选择对焦失败
- (void)userLockFocusDidSucceed; //用户锁定对焦成功
- (void)userLockFocusDidFailed;  //用户锁定对焦失败
@end

/** 对焦小视图 */
@interface K12CameraFocusCrucialView : UIView
@end