//
//  K12TextInputManager.m
//  TakePhoto
//
//  Created by mengkai on 15/10/19.
//  Copyright © 2015年 baidu. All rights reserved.
//

#import "K12TextInputManager.h"
#import "UIView+SLKAdditions.h"
#import "UITextView+SLKAdditions.h"
#import "SLKUIConstants.h"

NSString * const K12TextInputBarHeightDidchangeNotification = @"K12.TextInputBar.HeightDidchange.Notification";
NSString * const K12TextInputBarAnimationDurationUserInfoKey = @"K12.TextInputBar.AnimationDuration.UserInfoKey";
NSString * const K12TextInputBarHeightUserInfoKey = @"K12.TextInputBar.Height.UserInfoKey";

@implementation K12TextInputManager
#pragma mark - init
+ (instancetype)defultManager{
    static id defultManager__ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defultManager__ = [self managerWithSuperView:[UIApplication sharedApplication].keyWindow];
    });
    return defultManager__;
}

+ (instancetype)managerWithSuperView:(UIView *)superview{
    NSAssert(superview, NSLocalizedString(@"", @"CMInputManager must specify superview"));
    K12TextInputManager *manager = [[K12TextInputManager alloc] initWithSuperview:superview];
    return manager;
}

- (id)init{
    return nil;
}

- (void)dealloc{
    [self unregisterNotifications];
}

- (id)initWithSuperview:(UIView *)superview{
    if(self = [super init]){
        _superview = superview;
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    [self.superview addSubview:self.textInputBar];
    [self setupConstraints];
    [self registerNotifications];
}

- (void)registerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:self.textInputBar.textView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.textInputBar.textView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark - getter
- (K12TextInputbar *)textInputBar{
    if(!_textInputBar){
        _textInputBar = [K12TextInputbar new];
        _textInputBar.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textInputBar;
}

- (BOOL)keyBoardIsShowing{
    return (self.textInputBarBC.constant >= 0);
}

- (__weak UIView *)superview{
    return _superview;
}

- (NSLayoutConstraint *)textInputBarHC{
    return _textInputBarHC;
}

- (NSLayoutConstraint *)textInputBarBC{
    return _textInputBarBC;
}

- (void)setPlaceholder:(NSString *)placeholder{
    self.textInputBar.placeholder = placeholder;
}

- (NSString *)placeholder{
    return self.textInputBar.placeholder;
}

- (BOOL)buttonIsHidden{
    return self.textInputBar.buttonIsHidden;
}

- (void)setButtonHidden:(BOOL)buttonHidden{
    [self.textInputBar setButtonHidden:buttonHidden animated:NO];

    [self textDidUpdate:YES];
    //发送高度改变通知
    //[self postTextInputBarHeightDidchangeNotificationWithAnimationDuration:0];
}

- (BOOL)isShowCharacterNumber{
    return self.textInputBar.isShowCharacterNumber;
}

- (void)setShowCharacterNumber:(BOOL)showCharacterNumber{
    [self.textInputBar setShowCharacterNumber:showCharacterNumber animated:NO];
    [self.superview layoutIfNeeded];
    
    //发送高度改变通知
    [self postTextInputBarHeightDidchangeNotificationWithAnimationDuration:0];
}

#pragma mark - auto layout
- (void)setupConstraints{
    NSDictionary *views = @{@"textInputBar": self.textInputBar};
    NSDictionary *metrics = @{@"barHeight":@(self.textInputBar.intrinsicContentSize.height)};
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInputBar]|" options:0 metrics:nil views:views]];
    [self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[textInputBar(barHeight)]-(==0)-|" options:0 metrics:metrics views:views]];
    
    _textInputBarHC = [self.superview constraintForView:self.textInputBar andAttribute:NSLayoutAttributeHeight];
    _textInputBarBC = [self.superview constraintForView:self.textInputBar andAttribute:NSLayoutAttributeBottom];
    
    self.textInputBarHC.constant = [self appropriateInputbarHeight];
    [self.superview layoutIfNeeded];
}

- (CGFloat)appropriateInputbarHeight{
    CGFloat height = 0.0;
    
    if (self.textInputBar.textView.numberOfLines == 1) {
        height = [self minimumInputbarHeight];
    }else if (self.textInputBar.textView.numberOfLines < self.textInputBar.textView.maxNumberOfLines) {
        height += [self currentInputbarHeight];
    }else{
        height += [self maximumInputbarHeight];
    }
    
    if (height < [self minimumInputbarHeight]) {
        height = [self minimumInputbarHeight];
    }
    
    return roundf(height);
}

- (CGFloat)maximumInputbarHeight{
    CGFloat height = [self deltaInputbarHeight];
    
    height += roundf(self.textInputBar.textView.font.lineHeight*self.textInputBar.textView.maxNumberOfLines);
    //height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)minimumInputbarHeight{
    return self.textInputBar.intrinsicContentSize.height;
}

- (CGFloat)currentInputbarHeight{
    CGFloat height = [self deltaInputbarHeight];
    
    height += roundf(self.textInputBar.textView.font.lineHeight*self.textInputBar.textView.numberOfLines);
    //height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)deltaInputbarHeight{
    return self.textInputBar.intrinsicContentSize.height-self.textInputBar.textView.font.lineHeight;
}

#pragma mark - action
- (void)didChangeTextViewText:(NSNotification *)notification{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textInputBar.textView]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)willShowOrHideKeyboard:(NSNotification *)notification{
    if (self.textInputBar.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Skips this if it's not the expected textView.
    //    if (![self.textInputBar.textView isFirstResponder]) {
    //        return;
    //    }
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat keyboardHeight = MIN(CGRectGetWidth(endFrame), CGRectGetHeight(endFrame));
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    // Updates the height constraints' constant
    self.textInputBarBC.constant = show ? keyboardHeight : 0.0;
    
    //发送高度改变通知
    [self postTextInputBarHeightDidchangeNotificationWithAnimationDuration:duration];
    
    if(show){
        [self.cache addObject:self];
    }else{
        [self.cache removeObject:self];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.superview animateLayoutIfNeededWithDuration:duration
                                               bounce:NO
                                              options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                           animations:NULL];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification{
    
}

- (void)textDidUpdate:(BOOL)animated{
    CGFloat inputbarHeight = [self appropriateInputbarHeight];
    if (inputbarHeight != self.textInputBarHC.constant)
    {
        CGFloat animationDuration = 0.0;
        self.textInputBarHC.constant = inputbarHeight;
        if (animated) {
            BOOL bounces = (IOS7_OR_LATER?[self.textInputBar.textView isFirstResponder]:NO);
            animationDuration = (bounces ? 0.5 : 0.2);
            [self.superview animateLayoutIfNeededWithBounce:bounces
                                                    options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                                 animations:^{
                                                     [self.textInputBar.textView scrollToCaretPositonAnimated:NO];
                                                 }];
        }else {
            [self.superview layoutIfNeeded];
        }
        
        //发送高度改变通知
        [self postTextInputBarHeightDidchangeNotificationWithAnimationDuration:animationDuration];
    }
}

//发送高度改变通知
- (void)postTextInputBarHeightDidchangeNotificationWithAnimationDuration:(NSTimeInterval)duration{
    NSDictionary *userInfo = @{K12TextInputBarAnimationDurationUserInfoKey : @(duration),
                               K12TextInputBarHeightUserInfoKey : @(self.textInputBarBC.constant+self.textInputBarHC.constant)};
    [[NSNotificationCenter defaultCenter]postNotificationName:K12TextInputBarHeightDidchangeNotification object:self userInfo:userInfo];
}

#pragma mark - control

+(NSMutableSet *)cache{
    static NSMutableSet *cache__ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache__ = [NSMutableSet set];
    });
    return cache__;
}

- (NSMutableSet *)cache{
    return self.class.cache;
}

- (void)present{
    [self.cache addObject:self];
    if(![self.textInputBar.textView isFirstResponder]){
        [self.textInputBar.textView becomeFirstResponder];
    }
}

- (void)dismiss{
    [self.cache removeObject:self];
    if([self.textInputBar.textView isFirstResponder]){
        [self.textInputBar.textView resignFirstResponder];
    }
}

@end
