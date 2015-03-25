//
//  SBTransitionAnimator.h
//  Suba
//
//  Created by Kwame Nelson on 2/12/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@property CGRect endTransitionFrame;
@property CGRect beginTransitionFrame;

@end

