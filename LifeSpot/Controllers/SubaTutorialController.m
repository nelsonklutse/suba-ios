//
//  SubaTutorialController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 2/2/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SubaTutorialController.h"
#import "TermsViewController.h"

@interface SubaTutorialController ()

@end

@implementation SubaTutorialController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AgreeTermsSegue"]) {
        TermsViewController *termsVC = segue.destinationViewController;
        if ([sender integerValue] == 5) {
            //DLog(@"Want to see terms");
            termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
            termsVC.navigationItem.title = @"Terms";
        }else if ([sender integerValue] == 10) {
            //DLog(@"Want to see privacy");
            termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
            termsVC.navigationItem.title = @"Privacy";
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
