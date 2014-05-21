//
//  CleverInvitesViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 4/29/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
     kEmail = 0,
    kContacts,
    kTwitter,
    kFacebook
}InviteType;


@interface CleverInvitesViewController : UIViewController

@property InviteType inviteType;

@end
