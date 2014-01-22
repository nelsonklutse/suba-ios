//
//  PasswordChangeViewController.m
//  LifeSpots
//
//  Created by Agana-Nsiire Agana on 10/23/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "PasswordChangeViewController.h"
#import "User.h"

typedef void (^PasswordSavedCompletion) ();


@interface PasswordChangeViewController ()<UITextFieldDelegate>

@property (strong,nonatomic) NSString *currentPass;
@property (strong,nonatomic) NSString *nwPass;
@property (strong,nonatomic) NSString *confirmedPass;

@property (weak, nonatomic) IBOutlet UITextField *currentPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *nwPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *confirmedPasswordField;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *savePasswordBarButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *changingPasswordIndicator;

@property (weak, nonatomic) IBOutlet UIView *savingChangesView;
- (IBAction)savePasswordAction:(id)sender;
- (void)changePassword:(PasswordSavedCompletion)completion;
@end

@implementation PasswordChangeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)changePassword:(PasswordSavedCompletion)completion
{
    if ([self.currentPass isEqualToString:@""]) {
        [AppHelper showNotificationWithMessage:@"Current password cannot be empty"
                                          type:kSUBANOTIFICATION_ERROR
                              inViewController:self
                               completionBlock:nil];
        return;
    }
    
    if ([self.nwPass isEqualToString:@""]) {
        [AppHelper showNotificationWithMessage:@"New password cannot be empty"
                                          type:kSUBANOTIFICATION_ERROR
                              inViewController:self
                               completionBlock:nil];
        return;
    }
    
    if ([self.confirmedPass isEqualToString:@""]) {
        [AppHelper showNotificationWithMessage:@"Please confirm your password"
                                          type:kSUBANOTIFICATION_ERROR
                              inViewController:self
                               completionBlock:nil];
        return;
    }
    
    // All fields have been filled
    User *user = [User currentlyActiveUser];
   
    [user changePassOld:self.currentPass
                newPass:self.nwPass
             completion:^(id results, NSError *error) {
                 DLog(@"Password results from server - %@",results);
                 if (error) {
                     DLog(@"Error - %@",error);
                     [AppHelper showNotificationWithMessage:@"There was a problem saving your password" type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
                 }else{
                     if ([results[STATUS] isEqualToString:ALRIGHT]) {
                         completion();
                     }
                     
                     if ([results objectForKey:@"error"]) {
                         [AppHelper showNotificationWithMessage:[results objectForKey:@"error"] type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
                     }
                 }
                 
    }];
}





#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.currentPasswordField) {
        [self.nwPasswordField becomeFirstResponder];
    }
    
    if (textField == self.nwPasswordField) {
        [self.confirmedPasswordField becomeFirstResponder];
    }
    if (textField == self.confirmedPasswordField) {
        // Change Password
        [self performSelectorOnMainThread:@selector(savePasswordAction:)
                               withObject:self.savePasswordBarButton
                            waitUntilDone:YES];
    }
    
    return  YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    
    if (![self.currentPasswordField.text isEqualToString:@""] && ![self.nwPasswordField.text isEqualToString:@""] && ![self.confirmedPasswordField.text isEqualToString:@""]) {
        self.savePasswordBarButton.enabled = YES;
    }else{
        self.savePasswordBarButton.enabled = NO;
    }
    
    return YES;
}



- (IBAction)savePasswordAction:(id)sender{
   
        self.currentPass = self.currentPasswordField.text;
        self.nwPass = self.nwPasswordField.text;
        self.confirmedPass = self.confirmedPasswordField.text;

    DLog(@"Old pass - %@\nNew Pass -%@\nConfirmed pass - %@",self.currentPass,self.nwPass,self.confirmedPass);
    if ([self.nwPass isEqualToString:self.confirmedPass]) {
        [AppHelper showLoadingDataView:self.savingChangesView indicator:self.changingPasswordIndicator flag:YES];
        [self changePassword:^{
            [AppHelper showNotificationWithMessage:@"Password changed successfully" type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
            
            //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"UNWIND_TO_PROFILE_SETTINGS_SEGUE" sender:nil];
            
            //});
            [AppHelper showLoadingDataView:self.savingChangesView indicator:self.changingPasswordIndicator flag:NO];
        }];
    }else{
        [AppHelper showNotificationWithMessage:@"Passwords do not match" type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
        
        return;
    }
    
    
}
@end
