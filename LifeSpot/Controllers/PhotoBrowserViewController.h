//
//  PhotoBrowserViewController.h
//  Suba
//
//  Created by Kwame Nelson on 2/12/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum{
    kEmail = 0,
    kContacts
}TagType;


@interface PhotoBrowserViewController : UIViewController

@property (strong,nonatomic) NSString *imageURL;
@property (strong,nonatomic) NSString *streamId;
@end
