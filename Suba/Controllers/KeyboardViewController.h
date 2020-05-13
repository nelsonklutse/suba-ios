//
//  KeyboardViewController.h
//  Suba
//
//  Created by Kwame Nelson on 12/4/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TPKeyboardAvoidingScrollView;

@interface KeyboardViewController : UIViewController
@property (retain, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *avoidingscrollview;

@end
