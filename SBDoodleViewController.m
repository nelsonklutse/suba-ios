//
//  SBViewController.m
//  Doodling
//
//  Created by Drew on 6/25/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import "SBDoodleViewController.h"

@interface SBDoodleViewController ()

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
	// Do any additional setup after loading the view, typically from a nib.

    self.undoManager = [[NSUndoManager alloc] init];
    self.currentColor = kRedColor;
    
    [self.currentColorView setActiveOnButton:self.redColorButton];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(handleLongPress:)];
    [self.undoButton addGestureRecognizer:longPress];

    [self.undoButton setEnabled:NO];
    
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
    UIImage *image = self.imageView.image;
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum: didFinishSavingWithError: contextInfo:), nil);
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message;
    NSString *title;
    if (!error) {
        title = NSLocalizedString(@"SaveSuccessTitle", @"");
        message = NSLocalizedString(@"SaveSuccessMessage", @"");
    } else {
        title = NSLocalizedString(@"SaveFailedTitle", @"");
        message = [error description];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
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

@end
