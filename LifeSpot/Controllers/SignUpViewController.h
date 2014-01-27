//
//  SignUpViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>


#define UserEmailKey @"UserEmailKey"
#define UserNameKey  @"UserNameKey"


@interface SignUpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;


- (IBAction)signUp:(UIButton *)sender;

@end
