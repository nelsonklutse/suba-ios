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

- (void)handleGetStarted:(NSNotification *)notif;

@end

@implementation SBWelcomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetStarted:) name:kGetStartedNotification object:nil];
    
    [self buildIntro];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kGetStartedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Build MYBlurIntroductionView

-(void)buildIntro{
    
    //Create custom panel with events
    SBWelcomePanel *welcomePanel = [[SBWelcomePanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"Welcome"];
    
    FriendsPanel *friendsPanel = [[FriendsPanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"FriendsIntro"];
    
    PrivatePanel *privatePanel = [[PrivatePanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"PrivateStreamIntro"];
    
    PublicPanel *publicPanel = [[PublicPanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"PublicStreamIntro"];
    
    FinalPanel *finalPanel = [[FinalPanel alloc] initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"FinalIntro"];
    
    //Add panels to an array
    NSArray *panels = @[welcomePanel,friendsPanel,privatePanel,publicPanel,finalPanel];
    
    //Create the introduction view and set its delegate
    MYBlurIntroductionView *introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    introductionView.delegate = self;
    introductionView.BackgroundImageView.image = [UIImage imageNamed:@"newBackground"];
    //[introductionView setBackgroundColor:[UIColor colorWithRed:217.0f/255.0f green:77.0f/255.0f blue:20.0f/255.0f alpha:1]];
    
    [introductionView setBackgroundColor:[UIColor clearColor]];
    
    [introductionView.RightSkipButton removeFromSuperview];
    
    CGRect oldPageControlFrame = introductionView.PageControl.frame;
    CGRect newPageControl = CGRectMake(oldPageControlFrame.origin.x, oldPageControlFrame.origin.y-85,oldPageControlFrame.size.width, oldPageControlFrame.size.height);
    
    introductionView.PageControl.frame = newPageControl;
    
    
    //Build the introduction with desired panels
    [introductionView buildIntroductionWithPanels:panels];
    
    //Add the introduction to your view
    [self.view addSubview:introductionView];
}

#pragma mark - MYIntroduction Delegate

-(void)introduction:(MYBlurIntroductionView *)introductionView didChangeToPanel:(MYIntroductionPanel *)panel withIndex:(NSInteger)panelIndex{
    
    //DLog(@"Introduction did change to panel %ld", (long)panelIndex);
    
    //You can edit introduction view properties right from the delegate method!
    //If it is the first panel, change the color to green!
    if (panelIndex == 0) {
        //[introductionView setBackgroundColor:[UIColor colorWithRed:217.0f/255.0f green:77.0f/255.0f blue:20.0f/255.0f alpha:1]];
        
        [introductionView setBackgroundColor:[UIColor clearColor]];
    }
    //If it is the second panel, change the color to blue!
    else if (panelIndex == 1){
        //[introductionView setBackgroundColor:[UIColor colorWithRed:217.0f/255.0f green:77.0f/255.0f blue:20.0f/255.0f alpha:1]];
        
        [introductionView setBackgroundColor:[UIColor clearColor]];
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


-(void)handleGetStarted:(NSNotification *)notif
{
    
   [self performSegueWithIdentifier:@"GetStartedScreen" sender:nil];
}


@end
