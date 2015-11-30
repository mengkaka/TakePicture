//
//  K12TextInputManager.h
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "K12TextInputbar.h"

extern NSString * const K12TextInputBarHeightDidchangeNotification;
extern NSString * const K12TextInputBarAnimationDurationUserInfoKey;
extern NSString * const K12TextInputBarHeightUserInfoKey;

@interface K12TextInputManager : NSObject
{
    __weak UIView *_superview;
    K12TextInputbar *_textInputBar;
    
    NSLayoutConstraint *_textInputBarHC;
    NSLayoutConstraint *_textInputBarBC;
}
@property (nonatomic, readonly) K12TextInputbar *textInputBar;

+ (instancetype)defultManager;
+ (instancetype)managerWithSuperView:(UIView *)view;

@property(nonatomic, assign) NSInteger maxTextLength;
@property (nonatomic, readwrite) NSString *placeholder;
@property (nonatomic, readonly)  BOOL keyBoardIsShowing;

@property (nonatomic, getter=buttonIsHidden)BOOL buttonHidden; //顶部按钮是否隐藏
@property (nonatomic, getter=isShowCharacterNumber)BOOL showCharacterNumber;   //是否显示字符数量 默认不显示

- (void)present;
- (void)dismiss;
@end
