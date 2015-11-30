//
//  CMInputManager.h
//  ChunMiao
//
//  Created by super on 14-12-4.
//  Copyright (c) 2014年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CMInputManager;
@protocol CMInputManagerDelegate <NSObject>
- (void)inputManagerWillShowKeyboard:(CMInputManager *)manager;
- (void)inputManager:(CMInputManager *)manager willSendText:(NSString *)text;
- (void)inputManagerDidHiddenKeyboard:(CMInputManager *)manager;
@end

@interface CMInputManager : NSObject

@property (nonatomic, weak)NSObject <CMInputManagerDelegate> *delegate;

+ (instancetype)defultManager;
+ (instancetype)managerWithSuperView:(UIView *)view;

@property (nonatomic, strong)UIButton *sendButton;
@property(nonatomic, assign)NSInteger maxTextLength;

@property (nonatomic, readwrite) NSString *placeholder;

@property (nonatomic, readwrite) BOOL showSendButton;
@property (nonatomic, readwrite) BOOL autoHideSendButton;
@property (nonatomic, assign)    BOOL showInputViewWhenHiddenKeyboard;
@property (nonatomic, readonly)  BOOL keyBoardIsShowing;

- (void)cleanText;

- (void)present;
- (void)dismiss;

@end
