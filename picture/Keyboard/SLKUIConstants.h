//
//   Copyright 2014 Slack Technologies, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com

#define UI_IS_LANDSCAPE         ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight)
#define UI_IS_IPAD              ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define UI_IS_IPHONE            ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define UI_IS_IPHONE4           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height < 568.0)
#define UI_IS_IPHONE5           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)
#define UI_IS_IPHONE6           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0)
#define UI_IS_IPHONE6PLUS       (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0 || [[UIScreen mainScreen] bounds].size.width == 736.0) // Both orientations
#define UI_IS_IOS8_AND_HIGHER   ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)

#ifndef HEXRGBCOLOR
#define HEXRGBCOLOR(h) ([UIColor colorWithRed:(((h)>>16)&0xFF)/255.0 green:(((h)>>8)&0xFF)/255.0 blue:((h)&0xFF)/255.0 alpha:1])
#endif

#ifndef IOS7_OR_LATER
#define IOS7_OR_LATER    ([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#endif

#ifndef IOS8_OR_LATER
#define IOS8_OR_LATER    ([[UIDevice currentDevice].systemVersion compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)
#endif

typedef NS_ENUM(NSUInteger, SLKQuicktypeBarMode) {
    SLKQuicktypeBarModeHidden,
    SLKQuicktypeBarModeCollapsed,
    SLKQuicktypeBarModeExpanded ,
};


inline static CGFloat minimumKeyboardHeight()
{
    if (UI_IS_IPAD) {
        if (UI_IS_LANDSCAPE) return 352.f;
        else return 264.f;
    }
    if (UI_IS_IPHONE6PLUS) {
        if (UI_IS_LANDSCAPE) return 162.f;
        else return 226.f;
    }
    else {
        if (UI_IS_LANDSCAPE) return 162.f;
        else return 216.f;
    }
}

inline static CGFloat quicktypeBarHeightForMode(SLKQuicktypeBarMode mode)
{
    if (UI_IS_IPAD) {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 10.f;
                
            case SLKQuicktypeBarModeExpanded :
                return 39.f;
        }
    }
    if (UI_IS_IPHONE6PLUS) {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 9.f;
                
            case SLKQuicktypeBarModeExpanded :
                if (UI_IS_LANDSCAPE) return 32.f;
                else return 45.f;
        }
    }
    else {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 8.f;
                
            case SLKQuicktypeBarModeExpanded :
                if (UI_IS_LANDSCAPE) return 31.f;
                else return 37.f;
        }
    }
}

inline static SLKQuicktypeBarMode SLKQuicktypeBarModeForHeight(CGFloat height)
{
    if (height > 0.f && height <= 10.f) {
        return SLKQuicktypeBarModeCollapsed;
    }
    
    if (height > 10.f && height <= 45.f) {
        return SLKQuicktypeBarModeExpanded ;
    }
    
    return SLKQuicktypeBarModeHidden;
}

inline static NSString *NSStringFromSLKQuicktypeBarMode(SLKQuicktypeBarMode mode)
{
    switch (mode) {
        case SLKQuicktypeBarModeHidden:
            return @"Hidden";
            
        case SLKQuicktypeBarModeCollapsed:
            return @"Collapsed";
            
        case SLKQuicktypeBarModeExpanded:
            return @"Expanded";
    }
}
