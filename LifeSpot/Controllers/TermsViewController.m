//
//  TermsViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/23/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "TermsViewController.h"

@interface TermsViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *viewWeb;

@property (weak, nonatomic) IBOutlet UIProgressView *pageLoadProgressView;



@end

@implementation TermsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.pageLoadProgressView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.pageLoadProgressView.hidden = NO;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.urlToLoad];
    DLog(@"URL - %@",self.urlToLoad);
    [self.viewWeb loadRequest:request progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        self.pageLoadProgressView.progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
        if (self.pageLoadProgressView.progress == 1) {
            self.pageLoadProgressView.hidden = YES;
        }
    } success: nil
        failure:^(NSError *error) {
        
        [AppHelper showNotificationWithMessage:@"There was a problem loading the webpage.Please try again later." type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
    }];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [AppHelper showNotificationWithMessage:@"There was a problem loading content" type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
}

@end
