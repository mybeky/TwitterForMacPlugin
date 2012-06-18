//
//  ReadLaterPostStatus.h
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/17/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ReadLaterGrowlMock : NSObject

@property (nonatomic, assign) id iconData;

- (ReadLaterGrowlMock *)initWithAccount:(id)account;
- (BOOL)growlPrimeIconData;
- (NSString *)growlTitle;
- (NSString *)growlDescription;
- (id)growlContextWithAccount:(id)arg1 notificationName:(id)arg2;
- (id)growlIconData;
- (NSString *)growlIdentifier;

@end
