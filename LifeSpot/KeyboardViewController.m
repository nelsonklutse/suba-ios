//
//  KeyboardViewController.m
//  Suba
//
//  Created by Kwame Nelson on 12/4/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "KeyboardViewController.h"
#import "TPKeyboardAvoidingScrollView.h"

@interface KeyboardViewController ()<UITextViewDelegate>


@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.avoidingscrollview contentSizeToFit];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
