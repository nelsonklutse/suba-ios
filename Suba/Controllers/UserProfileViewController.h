//
//  UserProfileViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserProfileViewController : UIViewController

@property (strong,nonatomic) NSString *userId;
@property BOOL shouldAutoInvite;

-(void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data completion:(GeneralCompletion)completionBlock;

@end
