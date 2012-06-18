//
//  TwitterForMacPlugins.m
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/9/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import <objc/runtime.h>
#import "TwitterForMacPlugins.h"
#import "ReadLaterGrowlMock.h"

#define kReadLaterServiceDefautsKey @"ReadLaterService"
#define kReadLaterServiceUsernameDefaultsKey @"ReadLaterServiceUsername"
#define kReadLaterServiceNameInstapaper @"Instapaper"
#define kReadLaterServiceNone 0
#define kReadLaterServiceInstapaper 1
#define kReadLaterServiceMenuTag 1989

@implementation NSObject(TwitterForMacPlugins)

+ (BOOL)_isImageServiceLink:(NSURL *)aURL
{
    if (aURL && [aURL.absoluteString
         rangeOfString:@"instagr.am/p/"].location != NSNotFound) {
        return YES;
    }
    return [self _isImageServiceLink:aURL];
}

+ (NSURL *)_fullSizeImageURLForURL:(NSURL *)linkURL
{
    NSString *urlString = linkURL.absoluteString;
    if ([urlString rangeOfString:@"instagr.am/p/"].location != NSNotFound) {
        NSString *imageURLString = [urlString
                                    stringByAppendingString:@"media/?size=l"];
        return [NSURL URLWithString:imageURLString];
    }
    return [self _fullSizeImageURLForURL:linkURL];
}

- (NSURL *)_url
{
    NSURL *expandedURL = [self valueForKey:@"expandedURL"];
    if (expandedURL) {
        return expandedURL;
    }
    return [self valueForKey:@"_url"];
}

- (void)_addMenuItemsForStatus:(id)status toMenu:(id)menu
{
    [self _addMenuItemsForStatus:status toMenu:menu];

    TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
    if (plugin.account == nil) {
        plugin.account = [self valueForKey:@"account"];
    }
    NSObject<ReadLaterClient> *readLaterClient = plugin.readLaterClient;
    NSMutableArray *links = [NSMutableArray array];
    if (readLaterClient != nil) {
        for (id url in [status valueForKeyPath:@"entities.urls"]) {
            NSURL *tcoURL = [url valueForKey:@"url"];
            NSURL *expandedURL = [url valueForKey:@"expandedURL"];
            if (expandedURL) {
                [links addObject:expandedURL.absoluteString];
            } else {
                [links addObject:tcoURL.absoluteURL];
            }
        }
    }
    if (links.count > 0) {
        NSUInteger indexToInsertMenu;
        for (NSMenuItem *item in [menu itemArray]) {
            if ([item.title isEqualToString:@"View on Twitter.com"]) {
                indexToInsertMenu = [[menu itemArray] indexOfObject:item] + 3;
            }
        }

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowDevelopMenu"]) {
            indexToInsertMenu += 2;
        }

        for (NSString *link in links) {
            NSMenuItem *item = [self _menuItemWithTitle:@"↪ Send to Instapaper" action:^{
                [readLaterClient addURL:link
                                summary:[status valueForKey:@"displayText"]
                                 status:status
                               callback:nil];
            }];

            [menu insertItem:item atIndex:indexToInsertMenu];
            indexToInsertMenu += 2;
        }
    }

    NSMenuItem *spearatorItem = [NSMenuItem separatorItem];
    [menu addItem:spearatorItem];

    NSString *itemTitle = [NSString stringWithFormat:@"via %@",
                           [status valueForKey:@"sourceName"]];
    NSString *sourceLink = [status valueForKey:@"sourceLink"];
    NSMenuItem *item = [self _menuItemWithTitle:itemTitle action:^{
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sourceLink]];
    }];

    [menu addItem:item];
}

- (id)_menuItemWithTitle:(id)title action:(id)block
{
    return [self _menuItemWithTitle:title action:block];
}

- (void)_verifyCredentialsResponse:(id)request info:(id)info
{
    NSString *response = [NSString stringWithUTF8String:
                          [(NSData *)[request valueForKey:@"data"] bytes]];
    TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
    if ([response isEqualToString:@"200"]) {
        [plugin readLaterServiceLoginSuccess];
    } else {
        [plugin readLaterServiceLoginFailed];
    }
    [self _verifyCredentialsResponse:request info:info];
}

- (void)_addURLResponse:(id)request info:(id)info;
{
    NSData *responseData = [request valueForKey:@"data"];
    NSString *response;

    if (responseData == nil) {
        response = @"Failed";
    } else {
        response = [NSString stringWithUTF8String:[responseData bytes]];
    }

    TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
    ReadLaterGrowlMock *postStatus = [[[ReadLaterGrowlMock alloc]
                                       initWithAccount:plugin.account] autorelease];
    NSArray *mockGrowlArray = [NSArray arrayWithObject:postStatus];
    NSString *growlTitle;
    if ([response isEqualToString:@"201"]) {
        growlTitle = @"Link Saved Successfully";
    } else {
        growlTitle = @"Link Not Saved";
    }
    NSObject<TwitterAppDelegate> *appDelegate = [NSApp delegate];
    [appDelegate _growlNotificationWithObjects:mockGrowlArray
                                   fromAccount:plugin.account
                              notificationName:@"Timeline"
                                      priority:1
                                         title:growlTitle
                                    multiTitle:nil];

    [self _addURLResponse:request info:info];
}

- (void)__setView:(NSView *)view animate:(BOOL)animate {
    if ([[self valueForKeyPath:@"window.toolbar.selectedItemIdentifier"]
         isEqualToString:@"General"] && [view viewWithTag:kReadLaterServiceMenuTag] == nil) {

        NSTextField *imageServiceLabel = [view.subviews objectAtIndex:1];
        NSTextField *menuBarIconLabel = [view.subviews objectAtIndex:5];
        NSTextField *menuBarPopUpButton = [view.subviews objectAtIndex:4];
        CGFloat heightToOffset = menuBarIconLabel.frame.origin.y - imageServiceLabel.frame.origin.y ;

        NSRect viewFrame = view.frame;
        viewFrame.size.height += heightToOffset;
        viewFrame.origin.y -= heightToOffset;
        view.frame = viewFrame;

        NSRect labelFrame = menuBarIconLabel.frame;

        NSPopUpButton *popUpButton = [[[NSPopUpButton alloc]
                                      initWithFrame:CGRectOffset(menuBarPopUpButton.frame, 0, -heightToOffset)
                                      pullsDown:NO] autorelease];
        [popUpButton addItemsWithTitles:[NSArray arrayWithObjects:@"None", @"Instapaper", nil]];
        popUpButton.tag = kReadLaterServiceMenuTag;

        NSUInteger readLaterService = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:kReadLaterServiceDefautsKey] intValue];

        [popUpButton selectItemAtIndex:readLaterService];

        TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
        popUpButton.target = plugin;
        popUpButton.action = @selector(changeReadLaterService:);
        plugin.readLaterServicesPopUpButton = popUpButton;
        [view addSubview:popUpButton];

        NSTextField *textField = [[[NSTextField alloc] init] autorelease];
        textField.alignment = NSRightTextAlignment;
        textField.stringValue = @"Read later service:";
        textField.backgroundColor = [NSColor clearColor];
        textField.font = imageServiceLabel.font;
        textField.textColor = imageServiceLabel.textColor;
        [textField setBordered:NO];
        [textField setEditable:NO];

        textField.frame = CGRectOffset(labelFrame, 0.0f, -heightToOffset);
        [view addSubview:textField];

        // Move some controls downwards
        for (NSInteger i = 2; i < view.subviews.count; ++i) {
            if (i == 4 || i == 5) {
                continue;
            }
            NSControl *subview = [view.subviews objectAtIndex:i];
            NSRect frame = subview.frame;
            frame.origin.y -= heightToOffset;
            subview.frame = frame;
        }
    }

    [self __setView:view animate:animate];
}

@end

@implementation TwitterForMacPlugins

@synthesize account;
@synthesize cancelReadLaterServiceButton;
@synthesize readLaterLoginSheet;
@synthesize addReadLaterServiceButton;
@synthesize readLaterUsernameField;
@synthesize readLaterPasswordField;
@synthesize readLaterServiceIcon;
@synthesize readLaterVerifyIndicator;
@synthesize readLaterLoginFailedTip;
@synthesize readLaterClient;
@synthesize readLaterServicesPopUpButton;

+ (void)load
{
    Class rootClass = [NSObject class];
    Class imageServiceClass = NSClassFromString(@"ABImageService");
    method_exchangeImplementations(class_getClassMethod(imageServiceClass, @selector(isImageServiceLink:)),
                                   class_getClassMethod(rootClass, @selector(_isImageServiceLink:)));

    method_exchangeImplementations(class_getClassMethod(imageServiceClass, @selector(fullSizeImageURLForURL:)),
                                   class_getClassMethod(rootClass, @selector(_fullSizeImageURLForURL:)));

    Class twitterEntitySetClass = NSClassFromString(@"TwitterEntityURL");
    method_exchangeImplementations(class_getInstanceMethod(twitterEntitySetClass, @selector(url)),
                                   class_getInstanceMethod(rootClass, @selector(_url)));

    Class statusListViewControllerClass = NSClassFromString(@"TMStatusListViewController");
    method_exchangeImplementations(class_getInstanceMethod(statusListViewControllerClass, @selector(addMenuItemsForStatus:toMenu:)),
                                   class_getInstanceMethod(rootClass, @selector(_addMenuItemsForStatus:toMenu:)));

    method_exchangeImplementations(class_getInstanceMethod(statusListViewControllerClass, @selector(menuItemWithTitle:action:)),
                                   class_getInstanceMethod(rootClass, @selector(_menuItemWithTitle:action:)));


    Class instapaperClass = NSClassFromString(@"Instapaper");
    method_exchangeImplementations(class_getInstanceMethod(instapaperClass, @selector(verifyCredentialsResponse:info:)),
                                   class_getInstanceMethod(rootClass, @selector(_verifyCredentialsResponse:info:)));
    method_exchangeImplementations(class_getInstanceMethod(instapaperClass, @selector(addURLResponse:info:)),
                                   class_getInstanceMethod(rootClass, @selector(_addURLResponse:info:)));


    Class preferencesControllerClass = NSClassFromString(@"TweetiePreferencesWindowController");
    method_exchangeImplementations(class_getInstanceMethod(preferencesControllerClass, @selector(_setView:animate:)),
                                   class_getInstanceMethod(rootClass, @selector(__setView:animate:)));

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger readLaterService = [[userDefaults objectForKey:kReadLaterServiceDefautsKey] intValue];

    if (readLaterService == kReadLaterServiceInstapaper) {
        NSString *username = [userDefaults objectForKey:kReadLaterServiceUsernameDefaultsKey];
        NSString *password = [NSClassFromString(@"ABKeychain")
                              passwordForUsername:username
                              serviceName:kReadLaterServiceNameInstapaper
                              error:nil];
        if (username && password) {
            TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
            plugin.readLaterClient = [[(NSObject<ReadLaterClient> *)[NSClassFromString(@"Instapaper") alloc]
                            initWithUsername:username
                            password:password] autorelease];
        } else {
            [userDefaults setObject:[NSNumber numberWithUnsignedInt:kReadLaterServiceNone]
                             forKey:kReadLaterServiceDefautsKey];
        }
    }
}

+ (TwitterForMacPlugins *)sharedInstance
{
    static TwitterForMacPlugins *instance = nil;

    if (instance == nil)
        instance = [[TwitterForMacPlugins alloc] init];

    return instance;
}

- (void)changeReadLaterService:(NSPopUpButton *)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger lastService = [[userDefaults objectForKey:kReadLaterServiceDefautsKey]
                              intValue];
    NSUInteger newService = sender.indexOfSelectedItem;

    if (newService == lastService) return;

    if (newService == kReadLaterServiceInstapaper) {
        if (self.readLaterLoginSheet == nil) {
            [NSBundle loadNibNamed:@"ReadLaterLoginPanel"
                             owner:self];
            NSString *iconPath = [[NSBundle bundleForClass:self.class]
                                  pathForImageResource:@"icon-instapaper.png"];
            self.readLaterServiceIcon.image = [[[NSImage alloc]
                                                initWithContentsOfFile:iconPath] autorelease];
        }
        [self.readLaterLoginFailedTip setHidden:YES];
        [self.readLaterVerifyIndicator setHidden:YES];
        [self.cancelReadLaterServiceButton setEnabled:YES];
        [self.addReadLaterServiceButton setEnabled:NO];
        [self.readLaterUsernameField setEnabled:YES];
        [self.readLaterPasswordField setEnabled:YES];
        self.readLaterUsernameField.stringValue = @"";
        self.readLaterPasswordField.stringValue = @"";
        [self.readLaterLoginSheet makeFirstResponder:self.readLaterUsernameField];

        [NSApp beginSheet:self.readLaterLoginSheet
           modalForWindow:sender.window
            modalDelegate:nil
           didEndSelector:nil
              contextInfo:NULL];
    } else if (newService == kReadLaterServiceNone) {
        [userDefaults setObject:[NSNumber numberWithUnsignedInt:newService]
                         forKey:kReadLaterServiceDefautsKey];
        self.readLaterClient = nil;
    }
}

- (IBAction)cancelReadLaterLoginSheet:(id)sender {
    if (self.readLaterClient == nil) {
        [self.readLaterServicesPopUpButton selectItemAtIndex:kReadLaterServiceNone];
    } else {
        [self.readLaterServicesPopUpButton selectItemAtIndex:kReadLaterServiceInstapaper];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *username = self.readLaterUsernameField.stringValue;
        NSString *password = self.readLaterPasswordField.stringValue;
        [userDefaults setObject:[NSNumber numberWithUnsignedInt:kReadLaterServiceInstapaper]
                         forKey:kReadLaterServiceDefautsKey];
        [userDefaults setObject:username
                         forKey:kReadLaterServiceUsernameDefaultsKey];
        [NSClassFromString(@"ABKeychain") setPassword:password
                                          forUsername:username
                                          serviceName:kReadLaterServiceNameInstapaper];
    }
    [self.readLaterVerifyIndicator setHidden:YES];
    [self.readLaterVerifyIndicator stopAnimation:sender];
    [NSApp endSheet:self.readLaterLoginSheet];
    [self.readLaterLoginSheet orderOut:sender];
}

- (IBAction)verifyReadLaterLogin:(id)sender {
    [self.readLaterUsernameField setEnabled:NO];
    [self.readLaterPasswordField setEnabled:NO];
    [self.readLaterVerifyIndicator setHidden:NO];
    [self.readLaterVerifyIndicator startAnimation:sender];
    [self.cancelReadLaterServiceButton setEnabled:NO];
    [self.addReadLaterServiceButton setEnabled:NO];
    self.readLaterClient = [[(NSObject<ReadLaterClient> *)[NSClassFromString(@"Instapaper") alloc]
                            initWithUsername:self.readLaterUsernameField.stringValue
                            password:self.readLaterPasswordField.stringValue] autorelease];
    [self.readLaterClient verifyCredentials:nil];
}

- (void)readLaterServiceLoginFailed
{
    [self.readLaterLoginFailedTip setHidden:NO];
    [self.readLaterUsernameField setEnabled:YES];
    [self.readLaterPasswordField setEnabled:YES];
    [self.readLaterVerifyIndicator setHidden:YES];
    [self.cancelReadLaterServiceButton setEnabled:YES];
    [self.addReadLaterServiceButton setEnabled:YES];
    self.readLaterClient = nil;
}

- (void)readLaterServiceLoginSuccess
{
    [self cancelReadLaterLoginSheet:nil];
}

#pragma mark - NSTextField Delegate Methods

- (void)controlTextDidChange:(NSNotification *)obj
{
    if (self.readLaterUsernameField.stringValue.length > 0
        && self.readLaterPasswordField.stringValue.length > 0) {
        [self.addReadLaterServiceButton setEnabled:YES];
    } else {
        [self.addReadLaterServiceButton setEnabled:NO];
    }
    [self.readLaterLoginFailedTip setHidden:YES];
}

@end
