//
//  K12FocusAndExposureView.h
//  TakePhoto
//
//  Created by mengkai on 15/9/24.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class K12CameraFocusView;
@protocol K12CameraFocusViewDelegate <NSObject>
- (void)cameraFocusView:(K12CameraFocusView *)cameraFocusView userWillFocussingPoint:(CGPoint)point;
- (void)cameraFocusView:(K12CameraFocusView *)cameraFocusView userWillLockFocusPoint:(CGPoint)point;
@end

@interface K12CameraFocusView : UIView
{
    UITapGestureRecognizer *_tapGesture;
    UILongPressGestureRecognizer *_longPressGesture;
}
@property (nonatomic, weak) id <K12CameraFocusViewDelegate> delegate;   //代理回调

- (void)autoFocusWithFocusPoint:(CGPoint)point; //声明当前自动对焦所对应焦点
- (void)userFocussingDidSucceed; //用户选择对焦成功
- (void)userFocussingDidFailed;  //用户选择对焦失败
- (void)userLockFocusDidSucceed; //用户锁定对焦成功
- (void)userLockFocusDidFailed;  //用户锁定对焦失败
@end