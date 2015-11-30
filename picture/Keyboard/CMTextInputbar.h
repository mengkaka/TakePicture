//
//  CMTextInputbar.h
//  ChunMiao
//
//  Created by super on 14-12-4.
//  Copyright (c) 2014年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextView.h"

#define kTextInputbarMinimumHeight 44.0
#define kAccessoryViewHeight 38.0
#define kTextViewVerticalPadding 5.0
#define kTextViewHorizontalPadding 8.0

@interface CMTextInputbar : UIToolbar

@property (nonatomic, strong) SLKTextView *textView;
@property (nonatomic, strong) UIButton *sendButton;


@property (nonatomic, readwrite) BOOL showSendButton;
@property (nonatomic, readwrite) BOOL autoHideSendButton;

@property (nonatomic, readwrite) NSString *placeholder;

- (void)cleanText;
- (void)setSendTextTarget:(id)target action:(SEL)action;

@end
