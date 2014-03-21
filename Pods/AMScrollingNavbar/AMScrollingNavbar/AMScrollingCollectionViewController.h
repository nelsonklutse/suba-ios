//
//  AMScollingCollectionViewController.h
//  ScrollingNavbarDemo
//
//  Created by David on 28/12/2013.
//  Copyright (c) 2013 Andrea Mazzini. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMScrollingCollectionViewController : UICollectionViewController
/**-----------------------------------------------------------------------------
 * @name AMScrollingNavbarTableViewController
 * -----------------------------------------------------------------------------
 */

/** Scrolling init method
 *
 * Enables the scrolling on a generic UIView.
 *
 * @param scrollableView The UIView where the scrolling is performed.
 */
- (void)followScrollView:(UIView*)scrollableView;

/** Navbar slide down
 *
 * Manually show the navbar
 */
- (void)showNavbar;

/** Navbar refresh
 *
 * Use this method when you manually change the navbar items to re-enable the fadeout
 */
- (void)refreshNavbar;
@end
