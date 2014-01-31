//
//  LoginViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "LoginViewController.h"
#import "User.h"

@interface LoginViewController ()<UITextFieldDelegate>
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *pass;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginSpinner;

- (void)loginUserWithEmail:(NSString *)email AndPassword:(NSString *)password;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loginBtn.enabled = NO;
	// Do any additional setup after loading the view.
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.userNameField becomeFirstResponder];
    [super viewWillAppear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginAction:(UIButton *)sender {
    self.userName = self.userNameField.text;
    self.pass = self.pwdField.text;
    [self loginUserWithEmail:self.userName AndPassword:self.pass];
    
}




#pragma mark - API Calls
-(void)loginUserWithEmail:(NSString *)email AndPassword:(NSString *)password{
    [self.loginSpinner startAnimating];
    
    [AppHelper loginUserWithEmailOrUserName:email
                                AndPassword:password
                            completionBlock:^(id results, NSError *error) {
                                
                                [self.loginSpinner stopAnimating];
                                
                                if (!error) {
                                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                                        //DLog(@"")
                                        [AppHelper savePreferences:results];
                                        [self performSegueWithIdentifier:@"FromLoginPersonalSpotsTab" sender:nil];
                                    }else{
                                        [AppHelper showAlert:results[STATUS] message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
                                    }

                                    
                                }else{
                                    DLog(@"Error - %@",error);
                                    [AppHelper showAlert:@"Login Failure" message:@"We could not log you in.Please check your login details" buttons:@[@"I'll check again"] delegate:nil];
                                }
                            }];
}




#pragma mark - Textfield delegate method
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userNameField) {
        [self.pwdField becomeFirstResponder];
    }
    
    if (textField == self.pwdField) { // if we are in the password field
        
        if (![self.pwdField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]){
            self.userName = self.userNameField.text;
            self.pass = self.pwdField.text;
            
            [self loginUserWithEmail:self.userName AndPassword:self.pass];
        }
    }
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.pwdField) {
        if (![self.userNameField.text isEqualToString:@""] && ![self.pwdField.text isEqualToString:@""]) {
            self.loginBtn.enabled = YES;
        }
    }
    return YES;
}



/*#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    DLog(@"encode");
    
    self.userName = self.userNameField.text;
    [coder encodeObject:self.userName forKey:EmailOrUserNameKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    DLog(@"decode");
    
    self.userName = [coder decodeObjectForKey:EmailOrUserNameKey];
    
}

-(void)applicationFinishedRestoringState
{
    // Inflate view from freezed state
    self.userNameField.text = self.userName;
}
*/


@end
