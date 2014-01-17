//
//  InvitesViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kSuba = 0,
    kFacebook,
    kPhoneContacts
} InviteType;

@interface InvitesViewController : UIViewController
@property (strong,nonatomic) NSDictionary *spotToInviteUserTo;
@end
