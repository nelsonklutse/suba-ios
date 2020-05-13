//
//  CommentsViewController.m
//  Suba
//
//  Created by Kwame Nelson on 11/27/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//


#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"
#import "User.h"
#import "Photo.h"
#import "TPKeyboardAvoidingScrollView.h"
#import <PHFComposeBarView/PHFComposeBarView.h>

@interface CommentsViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,PHFComposeBarViewDelegate>

@property (copy,nonatomic) NSString *commentToAdd;
@property (strong,nonatomic) PHFComposeBarView *composeBarView;

@property (weak, nonatomic) IBOutlet UITextView *commentContainer;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *commentsIndicator;

@property (weak, nonatomic) IBOutlet UIButton *sendCommentButton;

- (void)showComments;
- (void)moveCommentsTextField:(NSNotification*)notification;

- (IBAction)sendComment:(id)sender;

@end

@implementation CommentsViewController

/*-(instancetype)init
{
    return [super initWithTableViewStyle:UITableViewStylePlain];
}


+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}*/



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self.avoidingScrollView contentSizeToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillToggle:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillToggle:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    if (!self.comments) {
        [self showComments];
    }
    
    
    
    self.commentContainer.text = @"Add a comment...";
    self.commentContainer.textColor = [UIColor lightGrayColor];
    self.sendCommentButton.enabled = NO;
    
    CGRect viewBounds = [[self view] bounds];
    CGRect frame = CGRectMake(0.0f,
                              viewBounds.size.height - PHFComposeBarViewInitialHeight,
                              viewBounds.size.width,
                              PHFComposeBarViewInitialHeight);
    
    _composeBarView = [[PHFComposeBarView alloc] initWithFrame:frame];
    //[_composeBarView setMaxCharCount:160];
    [_composeBarView setMaxLinesCount:5];
    [_composeBarView setPlaceholder:@"Add a comment..."];
    [_composeBarView setDelegate:self];
    
    //DLog(@"compose bar frame: %@",NSStringFromCGRect(composeBarView.bounds));
    
    [self.view addSubview:_composeBarView];
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.commentContainer becomeFirstResponder];
}


-(void)updateTableViewWithComment:(NSDictionary *)comment
{
    [self.comments addObject:comment];
    [self.commentsTableView reloadData];
    
    
    /*[self.commentsTableView beginUpdates];
    
    [self.commentsTableView reloadRowsAtIndexPaths:[self.commentsTableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationBottom];
     
     [self.commentsTableView endUpdates];*/
}


-(void)commentOnPhoto:(NSDictionary *)comment
{
    [self.commentsIndicator startAnimating];

    User *currentUser = [User currentlyActiveUser];
    NSDictionary *params = @{@"comment": self.commentToAdd, @"photoId": self.photoId, @"userId" : currentUser.userID};
    
    DLog(@"Commenting on photo with comment Params: %@",params);
    
    [FBAppEvents logEvent:@"Photo_Commented_On"];
    
    [currentUser commentOnPhoto:params completion:^(id results, NSError *error) {
        if (!error) {
            // Process if there is no error
            [self updateTableViewWithComment:results[@"comment"]];
        }
        
        [self.commentsIndicator stopAnimating];
    }];
}


- (void)showComments
{
    [self.commentsIndicator startAnimating];
  [Photo showCommentsForPhotoWithID:_photoId completion:^(id results, NSError *error){
      if(!error){
          self.comments = [NSMutableArray arrayWithArray:results[@"photoComments"]];
          //DLog(@"Comments: %@",self.comments);
          
          [self.commentsTableView reloadData];
      }else{
          DLog(@"Could not load comments");
      }
      
      [self.commentsIndicator stopAnimating];
  }];
}



- (IBAction)sendComment:(id)sender {

    self.commentToAdd = self.commentContainer.text;
    self.commentContainer.text = @"Add a comment...";
    self.commentContainer.textColor = [UIColor lightGrayColor];
    self.sendCommentButton.enabled = NO;
    [self.commentContainer resignFirstResponder];
    
    NSDictionary *comment = nil;
    
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        
        DLog(@"%@\n %@\n %@\n%@",[AppHelper profilePhotoURL],[AppHelper firstName],[AppHelper lastName],self.commentToAdd);
       comment = @{
          @"authorImage":[AppHelper profilePhotoURL],
          @"authorName":[NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]],
          @"commentText" : self.commentToAdd,
          @"timestamp" : @"now"
          };
        
    }else{
          comment = @{@"authorImage":[AppHelper profilePhotoURL],
                      
          @"authorName":[NSString stringWithFormat:@"%@",[AppHelper userName]],
          @"commentText" : self.commentToAdd,
          @"timestamp" : @"now"
          };
    }
    
    [self commentOnPhoto:comment];
}



#pragma mark - TableView Datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.comments count];
} 


/*-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"height- %f",[self heightForBasicCellAtIndexPath:indexPath]);
    return [self heightForBasicCellAtIndexPath:indexPath];
}*/



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self basicCellAtIndexPath:indexPath];
}


- (CommentsTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CommentsCellIdentifer = @"CommentsCell";
    CommentsTableViewCell *commentsCell = [self.commentsTableView dequeueReusableCellWithIdentifier:CommentsCellIdentifer forIndexPath:indexPath];
    
    //[self configureBasicCell:cell atIndexPath:indexPath];
    
    NSDictionary *commentInfo = self.comments[indexPath.row];
    
    NSURL *authorImage = [NSURL URLWithString:commentInfo[@"authorImage"]];
    
    [commentsCell.userImageView setImageWithURL:authorImage placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    commentsCell.commentUserName.text = commentInfo[@"authorName"];
    commentsCell.comment.text = commentInfo[@"commentText"];
    commentsCell.commentTimestamp.text = commentInfo[@"howLong"];

    
    return commentsCell;
}


- (void)configureBasicCell:(CommentsTableViewCell *)commentsCell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *commentInfo = self.comments[indexPath.row];
    
    NSURL *authorImage = [NSURL URLWithString:commentInfo[@"authorImage"]];
    
    [commentsCell.userImageView setImageWithURL:authorImage placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    commentsCell.commentUserName.text = commentInfo[@"authorName"];
    commentsCell.comment.text = commentInfo[@"commentText"];
    
    //[commentsCell.comment sizeToFit];
    
    commentsCell.commentTimestamp.text = commentInfo[@"howLong"];
    
    /*CGSize maxSize = CGSizeMake(commentsCell.comment.frame.size.width, MAXFLOAT);
    
    CGRect labelRect = [commentsCell.comment.text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName:commentsCell.comment.font} context:nil];
    
    DLog(@"size %@", NSStringFromCGSize(labelRect.size));*/
    
}


- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *const CommentsCellIdentifer = @"CommentsCell";
    static CommentsTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sizingCell = [self.commentsTableView dequeueReusableCellWithIdentifier:CommentsCellIdentifer];
    });
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height + 1.0f; // Add 1.0f for the cell separator height
}


-(void)moveCommentsTextField:(NSNotification *)notification
{
    /*NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    DLog(@"ScrollView new frame -  %@",NSStringFromCGRect(self.movingScrollView.frame));
    
    [UIView animateWithDuration:.25 animations:^{
        [self.movingScrollView setContentOffset:CGPointMake(self.movingScrollView.frame.origin.x,keyboardFrameBeginRect.size.height+self.movingScrollView.frame.size.height+200)];
    }];
    
    
    
    DLog(@"Keyboard frame: %@\nScrollView new frame -  %@",NSStringFromCGRect(keyboardFrameBeginRect),NSStringFromCGRect(self.movingScrollView.frame));*/
}


- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    self.commentContainer.text = @"";
    self.commentContainer.textColor = [UIColor blackColor];
    
    /*[UIView animateWithDuration:.25 animations:^{
        [self.movingScrollView setContentOffset:CGPointMake(self.movingScrollView.frame.origin.x,260+self.movingScrollView.frame.size.height+200)];
    }];

    [self.movingScrollView setContentOffset:CGPointMake(self.movingScrollView.frame.origin.x,260-self.movingScrollView.frame.size.height) animated:YES];
    DLog();*/
    
    return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    return YES;
}


- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > 0) {
        self.sendCommentButton.enabled = YES;
    }else{
        self.sendCommentButton.enabled = NO;
    }
   
}


/*-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [scrollView clipsToBounds];
}*/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_composeBarView resignFirstResponder];
    //DLog(@"Which scrollview: %@",[scrollView class]);
    
    //DLog(@"Compose view frame: %@",NSStringFromCGRect(_composeBarView.frame));
}


#pragma mark - PHFCompose Bar Delegate
- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView
{
    [_composeBarView resignFirstResponder];
    
    //DLog(@"text %@\ntext: %@",_composeBarView.text,_composeBarView.textView.text);
    self.commentToAdd = _composeBarView.text;
    [_composeBarView setText:@"" animated:YES];
    [_composeBarView setPlaceholder:@"Add a comment..."];
    
    //self.commentContainer.text = @"Add a comment...";
    //self.commentContainer.textColor = [UIColor lightGrayColor];
    //self.sendCommentButton.enabled = NO;
    //[self.commentContainer resignFirstResponder];
    
    NSDictionary *comment = nil;
    
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        
        DLog(@"%@\n %@\n %@\n%@",[AppHelper profilePhotoURL],[AppHelper firstName],[AppHelper lastName],self.commentToAdd);
        comment = @{
                    @"authorImage":[AppHelper profilePhotoURL],
                    @"authorName":[NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]],
                    @"commentText" : self.commentToAdd,
                    @"timestamp" : @"now"
                    };
    }else{
        comment = @{@"authorImage":[AppHelper profilePhotoURL],
                    @"authorName":[NSString stringWithFormat:@"%@",[AppHelper userName]],
                    @"commentText" : self.commentToAdd,
                    @"timestamp" : @"now"
                    };
    }
    
    [self commentOnPhoto:comment];
    

}


- (void)composeBarView:(PHFComposeBarView *)composeBarView
   willChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame
              duration:(NSTimeInterval)duration
        animationCurve:(UIViewAnimationCurve)animationCurve
{
    
}


- (void)keyboardWillToggle:(NSNotification *)notification{
    NSDictionary* userInfo = [notification userInfo];
    
    NSValue* keyboardFrameBegin = [userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    DLog(@"keyboardFrameBegin -  %@",NSStringFromCGRect(keyboardFrameBeginRect));
    //DLog(@"We are toggling");
    
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    
    //DLog(@"Start Frame: %@\nEnd frame: %@",NSStringFromCGRect(startFrame),NSStringFromCGRect(endFrame));
    
    NSInteger signCorrection = -1;
    
    
    CGFloat sizeChange = (startFrame.origin.y - endFrame.origin.y) * signCorrection;
    
    //CGFloat sizeChange = UIInterfaceOrientationIsLandscape([self interfaceOrientation]) ? widthChange : heightChange;
    
    CGRect newContainerFrame = _composeBarView.frame;
    newContainerFrame.origin.y += sizeChange;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         DLog(@"New frame: %@",NSStringFromCGRect(newContainerFrame));
                         
                         [_composeBarView setFrame:newContainerFrame];
                     }
                     completion:NULL];
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
