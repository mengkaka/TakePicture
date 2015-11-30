//
//  K12TextInputbar.h
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextView.h"

static CGFloat kTextInputbarMinimumHeight = 68;
static CGFloat kTextInputbarTopActionButtonHeight = 45;
static CGFloat kTextInputbarCharacterNumberHeight = 12;

static CGFloat kTextViewVerticalPadding = 2.0;
static CGFloat kTextViewHorizontalPadding = 5.0;

@interface K12TextInputbar : UIToolbar
{
    UIView *_lineView1;
    UIView *_lineView2;
    
    UILabel *_characterNumerLabel;
}
@property (nonatomic, strong) SLKTextView *textView;     //下面的输入框
@property (nonatomic, strong) UIButton *topActionButton; //输入框上面按钮
@property (nonatomic, readwrite) NSString *placeholder;  //place holder

@property (nonatomic, getter=buttonIsHidden)BOOL buttonHidden; //顶部按钮是否隐藏
- (void)setButtonHidden:(BOOL)buttonHidden animated:(BOOL)animated;

@property (nonatomic, assign) NSInteger maxCharacterNumber;   //最大字符数量 默认100
@property (nonatomic, assign, readonly) NSInteger currentCharacterNumber;   //当前字符数量 默认0
@property (nonatomic, getter=isShowCharacterNumber)BOOL showCharacterNumber;   //是否显示字符数量 默认不显示
- (void)setShowCharacterNumber:(BOOL)showCharacterNumber animated:(BOOL)animated;

- (void)cleanText;  //清除文本
@end
