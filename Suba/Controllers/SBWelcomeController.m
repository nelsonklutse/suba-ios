//
//  SBWelcomeController.m
//  Suba
//
//  Created by Kwame Nelson on 12/2/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "SBWelcomeController.h"
#import "SBWelcomePanel.h"
#import "FriendsPanel.h"
#import "PrivatePanel.h"
#import "PublicPanel.h"
#import "FinalPanel.h"

@interface SBWelcomeController ()
@property (retain, nonatomic) IBOutlet UIButton *nextOrGetStartedButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (weak, nonatomic) IBOutlet UIView *introView;
@property (strong,nonatomic) MYBlurIntroductionView *introductionView;
- (IBAction)showGetStartedScreen:(id)sender;

- (IBAction)showNextPanel:(id)sender;
- (IBAction)startIntro:(UIStoryboardSegue *)sender;

@end

@implementation SBWelcomeController

- (IBAction)showGetStartedScreen:(id)sender
{
    [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
}


- (IBAction)showNextPanel:(id)sender
{
    
    
    if (_introductionView.CurrentPanelIndex == 3){
        
        DLog(@"Curremt panel index: %i",_introductionView.CurrentPanelIndex);
        //[self.nextOrGetStartedButton.titleLabel sizeToFit];
        [self.nextOrGetStartedButton setTitle:@"Hop in!" forState:UIControlStateNormal];
        [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
        
        
    }else{
        DLog(@"Curremt panel index: %i",_introductionView.CurrentPanelIndex);
       [self.nextOrGetStartedButton setTitle:@"Next" forState:UIControlStateNormal];
        
        [_introductionView changeToPanelAtIndex:(_introductionView.CurrentPanelIndex % 4) + 1];
        //[self.nextOrGetStartedButton.titleLabel sizeToFit];
    }
}



- (IBAction)startIntro:(UIStoryboardSegue *)sender{

}

/*-(void)awakeFromNib
{
    [super awakeFromNib];
    [self.nextOrGetStartedButton setTitle:@"Next" forState:UIControlStateNormal];
    //[self.nextOrGetStartedButton.titleLabel setTextColor:[UIColor blackColor]];
}*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.nextOrGetStartedButton setTitle:@"Next" forState:UIControlStateNormal];
    
    DLog("Root view bounds - %@\n Introduction view - %@",NSStringFromCGRect(self.view.frame),NSStringFromCGRect(self.introView.frame));
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"newBackground"]];
    //[self.nextOrGetStartedButton.titleLabel setTextColor:[UIColor blackColor]];
    
    // Change the frame for the next and skip button
   
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        
        CGRect newNextButtonframe = CGRectMake(20,_introductionView.frame.size.height + 5 , 130, 25);
        self.nextOrGetStartedButton.frame = newNextButtonframe;
        
        [self.nextOrGetStartedButton setFrame:newNextButtonframe];
        DLog(@"Frames: %@",NSStringFromCGRect(self.nextOrGetStartedButton.frame));
        
        //CGRect skipButtonFrame = self.skipButton.frame;
        CGRect newSkipButtonFrame = CGRectMake(170,_introductionView.frame.size.height + 5 , 130, 25);
        self.skipButton.frame = newSkipButtonFrame;
        
    }
    
    
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self buildIntro];
    
    if (_introductionView && _introductionView.CurrentPanelIndex != 3){
        
        [self.nextOrGetStartedButton setTitle:@"Next" forState:UIControlStateNormal];
        
    }else{
        
        //[self.nextOrGetStartedButton.titleLabel sizeToFit];
        [self.nextOrGetStartedButton setTitle:@"Hop in!" forState:UIControlStateNormal];
        [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
    }
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        
        CGRect newNextButtonframe = CGRectMake(20,_introductionView.frame.size.height + 5 , 130, 25);
        self.nextOrGetStartedButton.frame = newNextButtonframe;
        [self.nextOrGetStartedButton setFrame:newNextButtonframe];
         DLog(@"Frames: %@",NSStringFromCGRect(self.nextOrGetStartedButton.frame));
        
        //CGRect skipButtonFrame = self.skipButton.frame;
        CGRect newSkipButtonFrame = CGRectMake(170,_introductionView.frame.size.height + 5 , 130, 25);
        self.skipButton.frame = newSkipButtonFrame;
        
    }
    
   

}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:kGetStartedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Build MYBlurIntroductionView

-(void)buildIntro{
    
    SBWelcomePanel *welcomePanel;FriendsPanel *friendsPanel;PrivatePanel *privatePanel;PublicPanel *publicPanel;
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        CGRect panelFrame = CGRectMake(0, 0,self.view.frame.size.width,360);
        //Create custom panel with events
        welcomePanel = [[SBWelcomePanel alloc] initWithFrame:panelFrame nibNamed:@"WelcomeSmall"];
        
        friendsPanel = [[FriendsPanel alloc] initWithFrame:panelFrame nibNamed:@"FriendSmall"];
        
        privatePanel = [[PrivatePanel alloc] initWithFrame:panelFrame nibNamed:@"PrivateStreamSmall"];
        
        publicPanel = [[PublicPanel alloc] initWithFrame:panelFrame nibNamed:@"PublicStreamSmall"];
        
        //Create the introduction view and set its delegate
        _introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,430)];
        
        _introductionView.clipsToBounds = YES;
        
    }else{
        //Create custom panel with events
        welcomePanel = [[SBWelcomePanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, 450) nibNamed:@"Welcome"];
        
        friendsPanel = [[FriendsPanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width,450) nibNamed:@"FriendsIntro"];
        
        privatePanel = [[PrivatePanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width,450) nibNamed:@"PrivateStreamIntro"];
        
        publicPanel = [[PublicPanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width,450) nibNamed:@"PublicStreamIntro"];
        
        //Create the introduction view and set its delegate
        _introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,450)];
        
        _introductionView.clipsToBounds = YES;
    }
    
    _introductionView.delegate = self;
    
    [_introductionView.RightSkipButton removeFromSuperview];
    
    CGRect oldPageControlFrame = _introductionView.PageControl.frame;
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        
      CGRect newPageControl = CGRectMake(oldPageControlFrame.origin.x, oldPageControlFrame.origin.y-35,oldPageControlFrame.size.width, oldPageControlFrame.size.height);
        
        _introductionView.PageControl.frame = newPageControl;
        
    }else{
        
        CGRect newPageControl = CGRectMake(oldPageControlFrame.origin.x, oldPageControlFrame.origin.y+10,oldPageControlFrame.size.width, oldPageControlFrame.size.height);
        
        _introductionView.PageControl.frame = newPageControl;
    }
    
    //Add panels to an array
    NSArray *panels = @[welcomePanel,friendsPanel,privatePanel,publicPanel];
    
    //Build the introduction with desired panels
    [_introductionView buildIntroductionWithPanels:panels];
    
    //Add the introduction to your view
    [self.introView addSubview:_introductionView];
}


#pragma mark - MYIntroduction Delegate
- (void)introduction:(MYBlurIntroductionView *)introductionView didChangeToPanel:(MYIntroductionPanel *)panel withIndex:(NSInteger)panelIndex{
    
    if (panelIndex == 3){
        self.nextOrGetStartedButton.titleLabel.font = [UIFont systemFontOfSize:15];
        self.nextOrGetStartedButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.nextOrGetStartedButton setTitle:@"Hop in!" forState:UIControlStateNormal];
        //[self.nextOrGetStartedButton.titleLabel sizeToFit];
        
    }else{
        [self.nextOrGetStartedButton setTitle:@"Next" forState:UIControlStateNormal];
        //[self.nextOrGetStartedButton.titleLabel sizeToFit];
    }
}


-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType
{
    [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void)handleGetStarted
{
    
   [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
}


@end
