//
//  SBViewController.m
//  Doodling
//
//  Created by Nelson Klutse on 6/25/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import "SBDoodleViewController.h"
#import <IonIcons.h>
#import <ionicons-codes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "S3PhotoFetcher.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <DACircularProgressView.h>


@interface SBDoodleViewController ()
@property (weak, nonatomic) IBOutlet UIButton *closeDoodleViewButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (strong,atomic) ALAssetsLibrary *library;

- (IBAction)closeDoodleViewAction:(id)sender;
- (IBAction)saveImage:(id)sender;
@end

@implementation SBDoodleViewController

#define kRedColor @[@1.0, @0.0, @0.0, @1.0]
#define kOrangeColor @[@1.0, @(127.f/255), @0.0, @1.0]
#define kYellowColor @[@1.0, @1.0, @0.0, @1.0]
#define kGreenColor @[@0.0, @1.0, @0.0, @1.0]
#define kCyanColor @[@0.0, @1.0, @1.0, @1.0]
#define kBlueColor @[@0.0, @0.0, @1.0, @1.0]
#define kPurpleColor @[@(127.f/255), @0, @(127.f/255), @1.0]

@synthesize currentPoint = _currentPoint;
@synthesize previousPoint = _previousPoint;
@synthesize currentColor = _currentColor;
@synthesize undoManager = _undoManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.saveButton.enabled = NO;
    self.library = [[ALAssetsLibrary alloc] init];
    
    self.undoManager = [[NSUndoManager alloc] init];
    self.currentColor = kRedColor;
    
    [self.currentColorView setActiveOnButton:self.redColorButton];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(handleLongPress:)];
    [self.undoButton addGestureRecognizer:longPress];

    [self.undoButton setEnabled:NO];
    
    self.imageView.image = self.imageToRemix;
    
    /*UIImage *closeButtonImage = [IonIcons imageWithIcon:icon_ios7_close_empty iconColor:[UIColor whiteColor] iconSize:40 imageSize:CGSizeMake(70, 60)];
    
    UIImage *saveButtonImage = [IonIcons imageWithIcon:icon_ios7_upload_outline iconColor:[UIColor whiteColor] iconSize:43 imageSize:CGSizeMake(70, 60)];
    
    [self.closeDoodleViewButton setBackgroundImage:closeButtonImage forState:UIControlStateNormal];
    [self.saveButton setBackgroundImage:saveButtonImage forState:UIControlStateNormal];*/
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.imageView.image = self.imageToRemix;
    if (self.imageToRemix == nil) {
        
        
        DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                                initWithFrame:CGRectMake((self.imageView.bounds.size.width/2) - 20, (self.imageView.bounds.size.height/2) - 20, 40.0f, 40.0f)];
        progressView.thicknessRatio = .1f;
        progressView.roundedCorners = YES;
        progressView.trackTintColor = [UIColor blackColor];
        progressView.progressTintColor = [UIColor whiteColor];
        [self.view addSubview:progressView];
        
        [[S3PhotoFetcher s3FetcherWithBaseURL]
         downloadPhoto:self.imageToRemixURL to:self.imageView
         placeholderImage:self.imageView.image
         progressView:progressView
         downloadOption:SDWebImageRefreshCached
         completion:^(id results, NSError *error) {
             //if (!error) {
                 [progressView removeFromSuperview];
            // }else{
              //   [AppHelper showAlert:@"" message:@"There was an error downloading photo" buttons:@[@"OK"] delegate:nil];
             //}
             
        }];

        
        /*[self.imageView setImageWithURL:[NSURL URLWithString:self.imageToRemixURL] placeholderImage:self.imageView.image options:SDWebImageRefreshCached];*/
    }
    DLog(@"Image to remix - %@",self.imageToRemix);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self performSelector:@selector(handleLongPress:)];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Doodling magic

//begin the touch. store the initial point because I want to connect it to the last
//touch point
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.undoManager == nil){
        self.undoManager = [[NSUndoManager alloc] init];
    }
    [self.undoManager beginUndoGrouping];
    [self setImageUndoably:self.imageView.image];
    
    if ([self.undoManager canUndo]){
        [self.undoButton setEnabled:YES];
    }
    
}


//When touch is moving, draw the image dynamically
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    self.saveButton.enabled = YES;
    UITouch *touch = [touches anyObject];
    
    @autoreleasepool {
        self.previousPoint = [touch previousLocationInView:self.imageView];
        self.currentPoint = [touch locationInView:self.imageView];
        
        UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, YES, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGSize imageSize = self.imageView.image.size;
        CGSize viewSize = self.imageView.bounds.size; // size in which you want to draw
        
        float hfactor = imageSize.width / viewSize.width;
        float vfactor = imageSize.height / viewSize.height;
        
        float factor = fmax(hfactor, vfactor);
        
        // Divide the size by the greater of the vertical or horizontal shrinkage factor
        float newWidth = imageSize.width / factor;
        float newHeight = imageSize.height / factor;
        
        CGRect newRect = CGRectMake((viewSize.width-newWidth)/2, (viewSize.height-newHeight)/2, newWidth, newHeight);
        
        [self.imageView.image drawInRect:newRect];
        
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetRGBStrokeColor(ctx, [[self.currentColor objectAtIndex:0] floatValue],
                                   [[self.currentColor objectAtIndex:1] floatValue],
                                   [[self.currentColor objectAtIndex:2] floatValue],
                                   [[self.currentColor objectAtIndex:3] floatValue]);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, self.previousPoint.x, self.previousPoint.y);
        CGContextAddLineToPoint(ctx, self.currentPoint.x, self.currentPoint.y);
        CGContextStrokePath(ctx);
        self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    };
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.undoManager endUndoGrouping];
}

- (IBAction)selectRedColor:(id)sender {
    self.currentColor = kRedColor;
    [self.currentColorView setActiveOnButton:self.redColorButton];
}

- (IBAction)selectOrangeColor:(id)sender {
    self.currentColor = kOrangeColor;
    [self.currentColorView setActiveOnButton:self.orangeColorButton];
}

- (IBAction)selectYellowColor:(id)sender {
    self.currentColor = kYellowColor;
    [self.currentColorView setActiveOnButton:self.yellowColorButton];
}

- (IBAction)selectGreenColor:(id)sender {
    self.currentColor = kGreenColor;
    [self.currentColorView setActiveOnButton:self.greenColorButton];
}

- (IBAction)selectCyanColor:(id)sender {
    self.currentColor = kCyanColor;
    [self.currentColorView setActiveOnButton:self.cyanColorButton];
}

- (IBAction)selectBlueColor:(id)sender {
    self.currentColor = kBlueColor;
    [self.currentColorView setActiveOnButton:self.blueColorButton];
}

- (IBAction)selectPurpleColor:(id)sender {
    self.currentColor = kPurpleColor;
    [self.currentColorView setActiveOnButton:self.purpleColorButton];
}

- (void) setImageUndoably:(UIImage *)theImage {
    [[self.undoManager prepareWithInvocationTarget:self]
     setImageUndoably: self.imageView.image];
    
    if (self.undoManager.isUndoing) { // animate
        UIViewAnimationOptions opt =
        UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.4 delay:0.1 options:opt animations:^{
            self.imageView.image = theImage;
        } completion:nil];
    } else { // just do it
        self.imageView.image = theImage;
    }
    
}

- (IBAction)undo:(id)sender {
    
    if ([self.undoManager canUndo]){
        [self.undoManager undo];
    } else {
        //clear context
        [self.undoManager removeAllActions];
        [self.undoButton setEnabled:NO];
        //disable button
    }
}

- (IBAction)saveImage:(id)sender{
    // Save in a Suba folder
    UIImage *image = self.imageView.image;
    //UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum: didFinishSavingWithError: contextInfo:), nil);
    [self saveImageToCustomPhotoAlbum:image];
    
}


- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (!error) {
        //[AppHelper showNotificationWithMessage:@"Photo saved to gallery" type:CSNotificationViewStyleSuccess //inViewController:self completionBlock:^{
        
            self.savedPhoto = image;
            DLog(@"Context info - %@",contextInfo);
            [self performSegueWithIdentifier:@"RemixPhotoDoneSegue" sender:nil];
      //  }];
        
    } /*else {
        [AppHelper showNotificationWithMessage:error.description type:CSNotificationViewStyleSuccess inViewController:self completionBlock:^{
            [self performSegueWithIdentifier:@"RemixPhotoDoneSegue" sender:nil];
        }];
        
    }*/
    
}


- (void)handleLongPress:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        while ([self.undoManager canUndo]) {
            [self.undoManager undo];
        }

        if (![self.undoManager canUndo]){
            [self.undoManager removeAllActions];
            [self.undoButton setEnabled:NO];
        }
    }
}


- (IBAction)closeDoodleViewAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)saveImageToCustomPhotoAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba Photos" completion:^(NSURL *assetURL, NSError *error) {
                [Flurry logEvent:@"Doodle_Saved"];
        self.imageAssetURL = assetURL;
        self.savedPhoto = photo;
        
        [self performSegueWithIdentifier:@"RemixPhotoDoneSegue" sender:nil];

        //NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        /*AFURLSessionManager *manager = [SubaAPIClient sharedInstance];
        
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                           [SubaAPIClient subaAPIBaseURL],@"spot/picture/doodle"]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        //[manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
        
        NSProgress *progress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        [progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request
                                                                   fromFile:assetURL progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error){
                                                                       
            DLog(@"Fraction complete - %f = \nTotal completed - %lld",progress.fractionCompleted,progress.totalUnitCount);
                                                                     
            if (error){
                //completion(nil,error);
            } else {
                //completion(responseObject,nil);
                //[self performSegueWithIdentifier:@"RemixPhotoDoneSegue" sender:nil];
            }
        }];
        
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromData:info[@"fileData"] progress:(NSProgress *__autoreleasing *)progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                completion(nil,error);
            } else {
                completion(responseObject,nil);
            }
        }];
        
        [uploadTask resume];*/
    
    }failure:^(NSError *error){
        [AppHelper showAlert:@"Save image error"
                     message:@"There was an error uploading the photo"
                     buttons:@[@"OK"]
                    delegate:nil];
    }];

}



@end
