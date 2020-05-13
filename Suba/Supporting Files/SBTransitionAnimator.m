//
//  SBTransitionAnimator.m
//  Suba
//
//  Created by Kwame Nelson on 2/12/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import "SBTransitionAnimator.h"

@implementation SBTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.2f;
}



- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect beginFrame = self.beginTransitionFrame;
    
    
    if (self.presenting) {
        //fromViewController.view.userInteractionEnabled = NO;
        //[transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        toViewController.view.frame = beginFrame;
        DLog(@"begin frame - %@",NSStringFromCGRect(beginFrame));
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            toViewController.view.frame = fromViewController.view.frame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        toViewController.view.userInteractionEnabled = YES;
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            
            fromViewController.view.frame = self.beginTransitionFrame;
            DLog(@"Dismiss frame: %@",NSStringFromCGRect(fromViewController.view.frame));
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    
}

@end

