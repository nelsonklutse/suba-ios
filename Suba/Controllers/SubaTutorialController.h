//
//  SubaTutorialController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 2/2/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>


@interface SubaTutorialController : UIViewController<GPPSignInDelegate>



//- (IBAction)unwindBackToCreateAccount:(UIStoryboardSegue *)segue;
- (void)showSignUpOptions;
@end
