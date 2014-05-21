//
//  Comment.m
//  LifeSpot
//
//  Created by Kwame Nelson on 5/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "Comment.h"
#import "Photo.h"
#import "User.h"

@interface Comment()

@property (copy,nonatomic) User *user;
@property (copy,nonatomic) Photo *lastName;

@property (copy,nonatomic) NSString *text;
@property (strong,nonatomic) NSDate *date;
@property (strong,nonatomic) NSString *name;
@property (strong,nonatomic) UIImage *image;

@end

@implementation Comment

+ (instancetype)commentWithProperties:(NSDictionary*)commentInfo
{
    return [[Comment alloc] initWithProperties:commentInfo];
}


- (id)initWithProperties:(NSDictionary *)commentInfo
{
    self = [super init];
    if (self) {
        [self setText:commentInfo[@"commentText"]];
        [self setDate:commentInfo[@"commentDate"]];
        [self setName:commentInfo[@"authorName"]];
        [self setImage:commentInfo[@"authorImage"]];
    }
    return self;
}

- (NSString *)commentText
{
    return self.text;
}

//This is the date when the comment was posted.
- (NSDate *)postDate
{
    return self.date;
}

//This is the name that will be displayed for whoever posted the comment.
- (NSString *)authorName
{
    return self.name;
}

//This is an image of the person who posted the comment
- (UIImage *)authorAvatar
{
    return self.image;
}
@end
