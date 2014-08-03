//
//  SBSelectionView.h
//  Doodling
//
//  Created by Drew on 7/2/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBSelectionView : UIView

- (void)setActiveOnButton:(UIButton *)button;

- (void)animateToSelectedButton:(CGPoint)position;

@end
