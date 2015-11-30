//
//  CMTextInputbar.m
//  ChunMiao
//
//  Created by super on 14-12-4.
//  Copyright (c) 2014年 baidu. All rights reserved.
//

#import "CMTextInputbar.h"
#import "UIView+SLKAdditions.h"
#import "UITextView+SLKAdditions.h"
#import "SLKUIConstants.h"

@interface CMTextInputbar ()<UITextViewDelegate>
{
    __weak id  _sendTextTarget;
           SEL _sendTextAction;
}
@property (nonatomic, strong) NSLayoutConstraint *sendButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@end

@implementation CMTextInputbar

- (id)init{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.textView];
}

- (void)commonInit{
    self.translucent = NO;
    
    if (!IOS7_OR_LATER) {
        self.tintColor = HEXRGBCOLOR(0xffffff);
    }
    
    self.showSendButton = YES;
    self.autoHideSendButton = YES;
    
    [self addSubview:self.sendButton];
    [self addSubview:self.textView];
    
    [self setupViewConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:self.textView];
}

#pragma mark - getter
- (UIButton *)sendButton{
    if (!_sendButton){
//        if (IOS7_OR_LATER) {
             _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
//            [_sendButton setBackgroundImage:[[UIImage imageNamed:@"Group_join_btn_bg_click.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)] forState:UIControlStateNormal];
            [_sendButton setTitleColor:HEXRGBCOLOR(0x30be49) forState:UIControlStateNormal];
//        }else
//        {
//            [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        }
        
        _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
        _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        _sendButton.enabled = NO;
        
        [_sendButton addTarget:self action:@selector(didSendRightButton:) forControlEvents:UIControlEventTouchUpInside];
        
        
        [_sendButton setTitle:NSLocalizedString(@"发送", nil) forState:UIControlStateNormal];
        
    }
    return _sendButton;
}

- (SLKTextView *)textView{
    if (!_textView){
        _textView = [SLKTextView new];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:17.0];
        _textView.placeholderColor = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1];
        _textView.maxNumberOfLines = [self defaultNumberOfLines];
        
        _textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        _textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.keyboardType = UIKeyboardTypeDefault;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, -1, 0, 1);
        _textView.delegate = self;
        
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.borderWidth = 0.5;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
        
        // Registers the loupe gesture to detect when it will become visible
        for (UIGestureRecognizer *gesture in _textView.gestureRecognizers) {
            if ([gesture isKindOfClass:NSClassFromString(@"UIVariableDelayLoupeGesture")]) {
                [gesture addTarget:self action:@selector(willShowLoupe:)];
            }
        }
    }
    return _textView;
}

- (CGFloat)appropriateRightButtonWidth{
    NSString *title = [self.sendButton titleForState:UIControlStateNormal];
    CGSize sendButtonSize = CGSizeZero;
    if(IOS7_OR_LATER){
        sendButtonSize = [title sizeWithAttributes:@{NSFontAttributeName: self.sendButton.titleLabel.font}];
    }else{
        sendButtonSize = [title sizeWithFont:self.sendButton.titleLabel.font];
    }
    
    if(!self.showSendButton){
        return 0.0;
    }
    
    if (self.autoHideSendButton) {
        if (![self canPressSendButton]) {
            return 0.0;
        }
    }
    return sendButtonSize.width+kTextViewHorizontalPadding;
}

- (CGFloat)appropriateRightButtonMargin{
    if(!self.showSendButton){
        return 0.0;
    }
    
    if (self.autoHideSendButton) {
        if (![self canPressSendButton]) {
            return 0.0;
        }
    }
    
    return kTextViewHorizontalPadding;
}

- (NSString *)placeholder{
    return self.textView.placeholder;
}

#pragma mark - Setters
- (void)setAutoHideRightButton:(BOOL)hide{
    if(!self.showSendButton){
        _autoHideSendButton = hide;
        return;
    }
    
    if (self.autoHideSendButton != hide) {
        _autoHideSendButton = hide;
    }
    
    self.sendButtonWC.constant = [self appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self appropriateRightButtonMargin];
    [self layoutIfNeeded];
}

- (void)setShowSendButton:(BOOL)showSendButton{
    if(self.showSendButton != showSendButton){
        _showSendButton = showSendButton;
    }
    
    if(_showSendButton){
        self.textView.returnKeyType = UIReturnKeyDefault;
    }else{
        self.textView.returnKeyType = UIReturnKeySend;
    }
    
    self.sendButtonWC.constant = [self appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self appropriateRightButtonMargin];
    [self layoutIfNeeded];
}

- (void)setPlaceholder:(NSString *)placeholder{
    self.textView.placeholder = placeholder;
}

#pragma mark - Magnifying Glass handling

- (void)willShowLoupe:(UIGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.textView.loupeVisible = YES;
    }else {
        self.textView.loupeVisible = NO;
    }
    
    // We still need to notify a selection change in the textview after the magnifying class is dismissed
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self textViewDidChangeSelection:self.textView];
    }
}

#pragma mark - action
- (void)cleanText{
    self.textView.text = @"";
}

- (void)didSendRightButton:(UIButton *)sender{
    [self callDelegateMethodAction];
}

- (void)setSendTextTarget:(id)target action:(SEL)action{
    _sendTextTarget = target;
    _sendTextAction = action;
}

- (void)callDelegateMethodAction{
    if(_sendTextTarget && _sendTextAction && [_sendTextTarget respondsToSelector:_sendTextAction]){
        NSMethodSignature *sig= [[_sendTextTarget class] instanceMethodSignatureForSelector:_sendTextAction];
        NSInvocation *invocation=[NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:_sendTextTarget];
        [invocation setSelector: _sendTextAction];
        id sself = self;
        id string = self.textView.text;
        if(sig.numberOfArguments == 4){
            [invocation setArgument:&sself atIndex:2];
            [invocation setArgument:&string atIndex:3];
        }else if(sig.numberOfArguments == 3){
            [invocation setArgument:&string atIndex:2];
        }
        [invocation invoke];
    }
}

#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize{
    return CGSizeMake(UIViewNoIntrinsicMetric, kTextInputbarMinimumHeight);
}

+ (BOOL)requiresConstraintBasedLayout{
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        
        if(self.showSendButton){
            //Detected break. Should insert new line break manually.
            [textView insertNewLineBreak];
        }else{
            [self didSendRightButton:self.sendButton];
        }
        
        return NO;
    }
    else {
        NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
        
        return YES;
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView{
    if (self.textView.isLoupeVisible) {
        return;
    }
    
    NSDictionary *userInfo = @{@"range": [NSValue valueWithRange:textView.selectedRange]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectionDidChangeNotification object:self.textView userInfo:userInfo];
}

- (void)didChangeTextView:(NSNotification *)notification{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    if(self.showSendButton){
        self.sendButton.enabled = [self canPressSendButton];
    }
    
    if (self.showSendButton && self.autoHideSendButton){
        CGFloat sendButtonNewWidth = [self appropriateRightButtonWidth];
        
        if (self.sendButtonWC.constant == sendButtonNewWidth) {
            return;
        }
        
        self.sendButtonWC.constant = sendButtonNewWidth;
        self.rightMarginWC.constant = [self appropriateRightButtonMargin];
        
        if (sendButtonNewWidth > 0) {
            [self.sendButton sizeToFit];
        }
        
        BOOL bounces = (IOS7_OR_LATER?[self.textView isFirstResponder]:NO);
        
        [self animateLayoutIfNeededWithBounce:bounces
                                      options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                                   animations:NULL];
    }
}

- (BOOL)canPressSendButton{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return text.length > 0 ? YES : NO;
}

#pragma mark - auto layout
- (NSUInteger)defaultNumberOfLines{
    if (UI_IS_IPAD) {
        return 8;
    }
    if (UI_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}

- (void)setupViewConstraints{
    [self.sendButton sizeToFit];
    CGFloat rightVerMargin = (self.intrinsicContentSize.height - CGRectGetHeight(self.sendButton.frame)) / 2.0;
    
    NSDictionary *views = @{@"textView": self.textView,
                            @"sendButton": self.sendButton,
                            };
    
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                              @"ver" : @(kTextViewVerticalPadding),
                              @"rightVerMargin" : @(rightVerMargin),
                              @"minTextViewHeight" : @(self.textView.intrinsicContentSize.height),
                              };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[textView]-(==hor)-[sendButton(0)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightVerMargin)-[sendButton]-(<=rightVerMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=ver)-[textView(==minTextViewHeight@250)]-(==ver)-|" options:0 metrics:metrics views:views]];
    
    self.sendButtonWC = [self constraintForView:self.sendButton andAttribute:NSLayoutAttributeWidth];
    self.rightMarginWC = [self constraintForView:self andAttribute:NSLayoutAttributeTrailing];

    self.sendButtonWC.constant = [self appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self appropriateRightButtonMargin];
    [self layoutIfNeeded];
}

@end
