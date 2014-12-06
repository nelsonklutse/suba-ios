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

@interface CommentsViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *commentsTableView;
@property (copy,nonatomic) NSString *commentToAdd;

@property (weak, nonatomic) IBOutlet UIScrollView *movingScrollView;
@property (weak, nonatomic) IBOutlet UITextView *commentContainer;
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
    
    [self.avoidingScrollView contentSizeToFit];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveCommentsTextField:) name:UIKeyboardDidChangeFrameNotification object:nil];
    
    
    // Set up the comments view
    /*self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.inverted = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    */
    
    if (!self.comments) {
        [self showComments];
    }
    
    self.commentContainer.text = @"Write a comment";
    self.commentContainer.textColor = [UIColor lightGrayColor];
    self.sendCommentButton.enabled = NO;
    
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
    //[self updateTableViewWithComment:comment];

    User *currentUser = [User currentlyActiveUser];
    NSDictionary *params = @{@"comment": self.commentToAdd, @"photoId": self.photoId, @"userId" : currentUser.userID};
    
    DLog(@"Commenting on photo with comment Params: %@",params);
    
    [currentUser commentOnPhoto:params completion:^(id results, NSError *error) {
        if (!error) {
            // Process if there is no error
            [self updateTableViewWithComment:results[@"comment"]];
        }
    }];
}


-(void)showComments
{
  [Photo showCommentsForPhotoWithID:_photoId completion:^(id results, NSError *error){
      if(!error){
          self.comments = [NSMutableArray arrayWithArray:results[@"photoComments"]];
          DLog(@"Comments: %@",self.comments);
          
          [self.commentsTableView reloadData];
      }else{
          DLog(@"Could not load comments");
      }
  }];
}

- (IBAction)sendComment:(id)sender {
    
    self.commentContainer.text = @"";
    self.sendCommentButton.enabled = NO;
    
    NSDictionary *comment = nil;
    
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
       comment = @{@"authorImage":[AppHelper profilePhotoURL],
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


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 96; 
}





-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self basicCellAtIndexPath:indexPath];
}


- (CommentsTableViewCell *)basicCellAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CommentsCellIdentifer = @"CommentsCell";
    CommentsTableViewCell *cell = [self.commentsTableView dequeueReusableCellWithIdentifier:CommentsCellIdentifer forIndexPath:indexPath];
    
    [self configureBasicCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)configureBasicCell:(CommentsTableViewCell *)commentsCell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *commentInfo = self.comments[indexPath.row];
    
    DLog(@"Comment Info: %@",commentInfo);
    
    NSURL *authorImage = [NSURL URLWithString:commentInfo[@"authorImage"]];
    
    [commentsCell.userImageView setImageWithURL:authorImage placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    commentsCell.commentUserName.text = commentInfo[@"authorName"];
    commentsCell.comment.text = commentInfo[@"commentText"];
    commentsCell.commentTimestamp.text = commentInfo[@"howLong"];
    
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
    self.commentContainer.text = @"";
    self.commentContainer.textColor = [UIColor blackColor];
    
    /*[UIView animateWithDuration:.25 animations:^{
        [self.movingScrollView setContentOffset:CGPointMake(self.movingScrollView.frame.origin.x,260+self.movingScrollView.frame.size.height+200)];
    }];*/

    [self.movingScrollView setContentOffset:CGPointMake(self.movingScrollView.frame.origin.x,260-self.movingScrollView.frame.size.height) animated:YES];
    DLog();
    return YES;
}


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return YES;
}


-(void)textViewDidChange:(UITextView *)textView
{
    if(textView.text.length == 0){
        textView.textColor = [UIColor lightGrayColor];
        textView.text = @"Comment";
        self.sendCommentButton.enabled = NO;
        //[textView resignFirstResponder];
    }else{
       self.commentToAdd = textView.text;
       self.sendCommentButton.enabled = YES;
    }
    
    
    
    //DLog(@"Text: %@",textView.text);
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
