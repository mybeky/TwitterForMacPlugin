//
//  TwitterForMacPlugins.h
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/9/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ReadLaterClient

- (id)initWithUsername:(NSString *)username password:(NSString *)password;
- (void)verifyCredentials:(id)callback;
- (void)addURL:(NSString *)link summary:(NSString *)summary status:(id)status callback:(id)callback;

@end

@protocol TwitterAppDelegate

- (void)_growlNotificationWithObjects:(NSArray *)objects fromAccount:(id)account notificationName:(id)name priority:(int)priority title:(id)title multiTitle:(id)multiTitle;

@end

@protocol ABKeychain

+ (id)setPassword:(NSString *)password forUsername:(NSString *)username serviceName:(NSString *)service;
+ (NSString *)passwordForUsername:(NSString *)username serviceName:(NSString *)service error:(NSError **)error;

@end

@interface TwitterForMacPlugins : NSObject <NSTextFieldDelegate>

@property (assign) IBOutlet NSWindow *readLaterLoginSheet;
@property (assign) IBOutlet NSButton *addReadLaterServiceButton;
@property (assign) IBOutlet NSButton *cancelReadLaterServiceButton;
@property (assign) IBOutlet NSTextField *readLaterUsernameField;
@property (assign) IBOutlet NSSecureTextField *readLaterPasswordField;
@property (assign) IBOutlet NSImageView *readLaterServiceIcon;
@property (assign) IBOutlet NSProgressIndicator *readLaterVerifyIndicator;
@property (assign) IBOutlet NSTextField *readLaterLoginFailedTip;
@property (nonatomic, retain) NSPopUpButton *readLaterServicesPopUpButton;

@property (nonatomic, retain) NSObject<ReadLaterClient> *readLaterClient;

+ (TwitterForMacPlugins *) sharedInstance;

@property (nonatomic, assign) id account;

- (void)changeReadLaterService:(NSPopUpButton *)sender;
- (IBAction)cancelReadLaterLoginSheet:(id)sender;
- (IBAction)verifyReadLaterLogin:(id)sender;
- (void)readLaterServiceLoginFailed;
- (void)readLaterServiceLoginSuccess;

@end
