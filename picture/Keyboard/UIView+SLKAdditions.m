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

#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

@implementation UIView (SLKAdditions)

- (void)animateLayoutIfNeededWithBounce:(BOOL)bounce options:(UIViewAnimationOptions)options animations:(void (^)(void))animations
{
    NSTimeInterval duration = bounce ? 0.5 : 0.2;
    [self animateLayoutIfNeededWithDuration:duration bounce:bounce options:options animations:animations];
}

- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce options:(UIViewAnimationOptions)options animations:(void (^)(void))animations
{
    if (bounce) {
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:options
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
    else {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:options
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
}

- (NSArray *)constraintsForAttribute:(NSLayoutAttribute)attribute{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    return [self.constraints filteredArrayUsingPredicate:predicate];
}

- (NSLayoutConstraint *)constraintForView:(UIView *)view andAttribute:(NSLayoutAttribute)attribute{
    /*NSArray *array = [self constraintsForAttribute:attribute];
    if(!array || !array.count){
        return nil;
    }*/
    
    NSLayoutConstraint *layout = nil;
    for (NSLayoutConstraint *constraint in self.constraints) {
        if(constraint.firstItem == view && constraint.firstAttribute == attribute){
            layout = constraint;
        }
    }
    
    if(!layout){
        for (NSLayoutConstraint *constraint in self.constraints) {
            if(constraint.secondItem == view && constraint.secondAttribute == attribute){
                layout = constraint;
            }
        }
    }
    
    return layout;
}

@end
