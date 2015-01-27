//
//  CommentsViewController.h
//  Suba
//
//  Created by Kwame Nelson on 11/27/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TPKeyboardAvoidingScrollView;
//@class TPKeyboardAvoidingTableView;

@interface CommentsViewController : UIViewController

@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *avoidingScrollView;

@property (retain, nonatomic) IBOutlet UITableView *commentsTableView;

@property(strong,nonatomic) NSString *photoId;
@property(strong,nonatomic) NSMutableArray *comments;

@end
