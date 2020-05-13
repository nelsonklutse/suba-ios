//
//  EnterInviteCodeViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 5/27/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "EnterInviteCodeViewController.h"
#import "PhotoStreamViewController.h"
#import "SubaTutorialController.h"
#import "User.h"

@interface EnterInviteCodeViewController ()<UITextFieldDelegate>
//@property (copy,nonatomic) NSString *inviteCode;
@property (weak, nonatomic) IBOutlet UIButton *enterStreamButton;
@property (weak, nonatomic) IBOutlet UIScrollView *movableScrollView;
@property (weak, nonatomic) IBOutlet UITextField *inviteCodeTextField;

- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)enterStream:(id)sender;
@end

@implementation EnterInviteCodeViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /*DLog(@"Outside");
    if ([AppHelper inviteCodeDetails] && self.inviteCode) {
        DLog(@"Inside");
        [self performSegueWithIdentifier:@"InviteCodeSegue" sender:[AppHelper inviteCodeDetails]];
    }*/
    self.navigationController.navigationBarHidden = YES;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITextfield Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Send person to album here
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.enterStreamButton.enabled = YES;
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Move the textfield up to give space for user to continue
    
    [self.movableScrollView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
    //DLog(@"Moved scrollview");
    return YES;
}



- (IBAction)dismissKeyboard:(id)sender
{
    
}

- (IBAction)enterStream:(id)sender
{
    [AppHelper setUserStatus:kSUBA_USER_STATUS_ANONYMOUS];
    
    self.inviteCode = self.inviteCodeTextField.text;
    //DLog(@"Invite Code - %@",self.inviteCode);
    [User enterInviteCodeToJoinStream:@{@"streamCode": self.inviteCode} completion:^(NSDictionary *results, NSError *error){
        if (!error){  // InviteCodeSegue
            
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                [AppHelper saveInviteCodeDetails:results]; 
               [self performSegueWithIdentifier:@"InviteCodeSegue" sender:results];
                
            }else{
                [AppHelper showAlert:@"Oops!" message:@"Looks like that invite code is incorrect. Try again?" buttons:@[@"Try again"] delegate:nil];
            }
        }
    }];
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"InviteCodeSegue"]) {
        
        PhotoStreamViewController *pVC = segue.destinationViewController;
        pVC.spotID = sender[@"streamId"]; 
        pVC.spotName = sender[@"streamName"];
        pVC.numberOfPhotos = [sender[@"photos"] integerValue];
        
        //DLog(@"Spotid - %@\nSpotName - %@\nNumber of photos - %i",pVC.spotID,pVC.spotName,pVC.numberOfPhotos);
        
    }
}



@end
