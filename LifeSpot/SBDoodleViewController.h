//
//  SBViewController.h
//  Doodling
//
//  Created by Drew on 6/25/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBSelectionView.h"
#import "SBColorButton.h"

@interface SBDoodleViewController : UIViewController
{
    NSUndoManager *undoManager;
}

@property (strong,nonatomic) UIImage *imageToRemix;
@property  NSInteger remixImageID;
@property (strong,nonatomic) UIImage *savedPhoto;
@property (strong,nonatomic) NSURL *imageAssetURL;

@property (assign, nonatomic) CGPoint currentPoint;
@property (assign, nonatomic) CGPoint previousPoint;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSArray *currentColor;
@property (weak, nonatomic) IBOutlet SBSelectionView *currentColorView;
@property (nonatomic,retain) NSUndoManager *undoManager;


@property (weak, nonatomic) IBOutlet UIButton *undoButton;

@property (weak, nonatomic) IBOutlet SBColorButton *redColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *orangeColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *yellowColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *greenColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *cyanColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *blueColorButton;
@property (weak, nonatomic) IBOutlet SBColorButton *purpleColorButton;

- (IBAction)selectRedColor:(id)sender;
- (IBAction)selectOrangeColor:(id)sender;
- (IBAction)selectYellowColor:(id)sender;
- (IBAction)selectGreenColor:(id)sender;
- (IBAction)selectCyanColor:(id)sender;
- (IBAction)selectBlueColor:(id)sender;
- (IBAction)selectPurpleColor:(id)sender;
- (IBAction)saveImage:(id)sender;
- (IBAction)undo:(id)sender;


@end
