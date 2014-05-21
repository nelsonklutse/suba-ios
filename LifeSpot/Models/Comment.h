//
//  Comment.h
//  LifeSpot
//
//  Created by Kwame Nelson on 5/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EBPhotoCommentProtocol.h>

@class Photo;
@class User; 

@interface Comment : NSObject<EBPhotoCommentProtocol>

@property (copy,nonatomic,readonly) User *user;
@property (copy,nonatomic,readonly) Photo *photo;

@property (copy,nonatomic,readonly) NSString *text;
@property (strong,nonatomic,readonly) NSDate *date;
@property (strong,nonatomic,readonly) NSString *name;
@property (strong,nonatomic,readonly) UIImage *image;


+ (instancetype)commentWithProperties:(NSDictionary*)commentInfo;
- (id)initWithProperties:(NSDictionary *)commentInfo;
@end