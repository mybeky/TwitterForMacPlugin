//
//  ReadLaterPostStatus.m
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/17/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import "ReadLaterGrowlMock.h"

@implementation ReadLaterGrowlMock

@synthesize iconData;

- (ReadLaterGrowlMock *)initWithAccount:(id)account
{
    self = [super init];
    if (self) {
        self.iconData = [account
                         valueForKeyPath:@"user.profileImage.imageData"];
    }
    return self;
}

- (BOOL)growlPrimeIconData
{
    return NO;
}

- (NSString *)growlTitle
{
    return nil;
}

- (NSString *)growlDescription
{
    return nil;
}

- (NSString *)growlIdentifier
{
    return [NSString stringWithFormat:@"%d", arc4random()];
}

- (id)growlIconData
{
    return self.iconData;
//    if (growlIconData == nil) {
//        growlIconData = [NSData dataWithContentsOfFile: 
//                         [[NSBundle bundleForClass:self.class] pathForImageResource:@"icon-instapaper.png"]];
//    }
    return nil;
}

- (id)growlContextWithAccount:(id)account notificationName:(id)name
{
    return nil;
}

@end
