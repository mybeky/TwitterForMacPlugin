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

#define kImageSaveDirectoryKey @"ImageSaveDirectory"
#define kImageAssociationKey @"PreviewImage"
#define kImageTypeAssociationKey @"PreviewImageType"
#define kImageNameAssociationKey @"PreviewImageName"
#define kDragImageMaxWidth 480.0f
#define kDragImageMaxHeight 480.0f

@implementation NSObject(TwitterForMacPlugins)

+ (BOOL)_isImageServiceLink:(NSURL *)aURL
{
    BOOL isImage = NO;
    if (aURL && [aURL.absoluteString
         rangeOfString:@"instagr.am/p/"].location != NSNotFound) {
        isImage = YES;
    } else {
        isImage = [self _isImageServiceLink:aURL];
    }
    return isImage;
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

- (void)_imageResponse:(id)request info:(id)info
{
    if (request != nil) {
        NSURL *finalURL = [request valueForKey:@"finalURL"];
        NSUInteger imageType = [TwitterForMacPlugins imageTypeForURL:finalURL];
        NSString *imageName = [TwitterForMacPlugins imageNameForURL:finalURL];
        objc_setAssociatedObject(self, kImageTypeAssociationKey,
                                 [NSNumber numberWithUnsignedInt:imageType],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, kImageNameAssociationKey, imageName,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    [self _imageResponse:request info:info];
}

- (void)__didLoadImage:(id)image
{
    [self __didLoadImage:image];
    objc_setAssociatedObject(self, kImageAssociationKey,
                             [image valueForKey:@"nsImage"],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id contentView = [[[self valueForKeyPath:@"contentView.subviews"]
                       objectAtIndex:0] valueForKeyPath:@"rootView"];
    [contentView setValue:[TwitterForMacPlugins sharedInstance]
               forKeyPath:@"viewDelegate"];
}

- (id)_menuForEvent:(id)arg1
{
    id delegate = [self valueForKeyPath:@"rootView.viewDelegate"];
    if ([delegate respondsToSelector:@selector(contextMenuForView:)]) {
        return [delegate performSelector:@selector(contextMenuForView:)
                              withObject:self];
    }
    id menu = [self _menuForEvent:arg1];
    return menu;
}

- (NSDragOperation)_draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationCopy;
}

- (void)_mouseDragged:(NSEvent *)event
{
    if ([self valueForKeyPath:@"window.class"]
        == NSClassFromString(@"TMImageViewer")) {
        NSRect windowRect = [[event.window.contentView
                              valueForKey:@"frame"] rectValue];
        if (NSPointInRect(event.locationInWindow,
                          NSInsetRect(windowRect, 20.0f, 20.0f))) {
            NSImage *image = objc_getAssociatedObject(event.window, kImageAssociationKey);
            if (image) {
                TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
                [plugin willSaveImageInWindow:event.window];
                [((NSView *)self) dragPromisedFilesOfTypes:[NSArray arrayWithObject:NSPasteboardTypeTIFF]
                                                  fromRect:NSZeroRect
                                                    source:plugin
                                                 slideBack:YES
                                                     event:event];
            }
        }
    }
    [self _mouseDragged:event];
}

- (void)_dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack
{
    if (theEvent.window.class == NSClassFromString(@"TMImageViewer")) {

        NSImage *image = objc_getAssociatedObject(theEvent.window, kImageAssociationKey);
        NSSize imageSize = image.size;
        NSSize dragImageSize;
        if (imageSize.width > imageSize.height) {
            dragImageSize.width = MIN(imageSize.width, kDragImageMaxWidth);
            dragImageSize.height = imageSize.height * dragImageSize.width / imageSize.width;
        } else {
            dragImageSize.height = MIN(imageSize.height, kDragImageMaxHeight);
            dragImageSize.width = imageSize.width * dragImageSize.height / imageSize.height;
        }
        CGFloat ratio = dragImageSize.height / imageSize.height;

        NSImage *dragImage = [[NSImage alloc] initWithSize:imageSize];
        [dragImage lockFocus];
        [image dissolveToPoint:NSZeroPoint fraction:0.8];
        [dragImage unlockFocus];
        dragImage.scalesWhenResized = NO;
        dragImage.size = dragImageSize;

        NSPoint mouseLocation = theEvent.locationInWindow;
        NSPoint dragImageOrigin = NSMakePoint((mouseLocation.x - 20.0f) * (1 - ratio) + 20.0f,
                                              (mouseLocation.y - 20.0f) * (1 - ratio) + 20.0f);
        [self _dragImage:dragImage
                      at:dragImageOrigin
                  offset:NSZeroSize
                   event:theEvent
              pasteboard:pboard
                  source:sourceObject
               slideBack:slideBack];

        [dragImage release];
    } else {
       [self _dragImage:anImage
                     at:imageLoc
                 offset:mouseOffset
                  event:theEvent
             pasteboard:pboard
                 source:sourceObject
              slideBack:slideBack];
    }
}

- (BOOL)_performKeyEquivalent:(NSEvent *)event
{
    NSString *keyString = [event charactersIgnoringModifiers];
    NSUInteger keyModifierFlags = event.modifierFlags;
    if (event.window.class == NSClassFromString(@"TMImageViewer")) {
        NSString *imageName = objc_getAssociatedObject(event.window,
                                                       kImageNameAssociationKey);
        if (imageName == nil) {
            return [self _performKeyEquivalent:event];
        }
        if (keyModifierFlags & NSCommandKeyMask) {
            if ([keyString isEqualToString:@"s"]) {
                TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
                [plugin willSaveImageInWindow:event.window];
                [plugin saveImage:nil];
                return YES;
            } else if ([keyString isEqualToString:@"c"]) {
                TwitterForMacPlugins *plugin = [TwitterForMacPlugins sharedInstance];
                [plugin willSaveImageInWindow:event.window];
                [plugin copyImage:nil];
                return YES;
            }
        }
    }
    return [self _performKeyEquivalent:event];
}

@end

@implementation TwitterForMacPlugins

@synthesize account;
@synthesize currentImage;
@synthesize currentImageType;
@synthesize currentImageName;
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

    Class imageViewerClass = NSClassFromString(@"TMImageViewer");
    method_exchangeImplementations(class_getInstanceMethod(imageViewerClass, @selector(imageResponse:info:)),
                                   class_getInstanceMethod(rootClass, @selector(_imageResponse:info:)));
    method_exchangeImplementations(class_getInstanceMethod(imageViewerClass, @selector(_didLoadImage:)),
                                   class_getInstanceMethod(rootClass, @selector(__didLoadImage:)));

    Class abUINSViewClass = NSClassFromString(@"ABUINSView");
    method_exchangeImplementations(class_getInstanceMethod(abUINSViewClass, @selector(menuForEvent:)),
                                   class_getInstanceMethod(rootClass, @selector(_menuForEvent:)));
    method_exchangeImplementations(class_getInstanceMethod(abUINSViewClass, @selector(performKeyEquivalent:)),
                                   class_getInstanceMethod(rootClass, @selector(_performKeyEquivalent:)));
    method_exchangeImplementations(class_getInstanceMethod(abUINSViewClass, @selector(draggingSourceOperationMaskForLocal:)),
                                   class_getInstanceMethod(rootClass, @selector(_draggingSourceOperationMaskForLocal:)));
    method_exchangeImplementations(class_getInstanceMethod(abUINSViewClass, @selector(mouseDragged:)),
                                   class_getInstanceMethod(rootClass, @selector(_mouseDragged:)));
    method_exchangeImplementations(class_getInstanceMethod(abUINSViewClass, @selector(dragImage:at:offset:event:pasteboard:source:slideBack:)),
                                   class_getInstanceMethod(rootClass, @selector(_dragImage:at:offset:event:pasteboard:source:slideBack:)));

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

+ (NSUInteger)imageTypeForURL:(NSURL *)aURL
{
    NSString *urlString = aURL.absoluteString;
    NSBitmapImageFileType imageType = NSJPEGFileType;
    if ([urlString rangeOfString:@".png"
                         options:NSCaseInsensitiveSearch].location != NSNotFound) {
        imageType = NSPNGFileType;
    } else if ([urlString rangeOfString:@".jpg"
                                options:NSCaseInsensitiveSearch].location != NSNotFound) {
        imageType = NSJPEGFileType;
    } else if ([urlString rangeOfString:@".jpeg"
                                options:NSCaseInsensitiveSearch].location != NSNotFound) {
        imageType = NSJPEGFileType;
    }
    return imageType;
}


+ (NSString *)imageNameForURL:(NSURL *)aURL
{
    NSString *lastSegment = aURL.lastPathComponent;
    NSString *imageName = [[lastSegment componentsSeparatedByString:@"."]
                           objectAtIndex:0];
    return imageName;
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

#pragma mark - Image Related Methods

- (void)saveImage:(NSMenuItem *)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];

    NSWindow *imageWindow = [NSApp keyWindow];
    NSString *imageExtentsion = @"jpg";
    if (self.currentImageType == NSPNGFileType) {
        imageExtentsion = @"png";
    }
    NSString *imageFileName = [NSString stringWithFormat:@"%@.%@",
                               self.currentImageName, imageExtentsion];
    savePanel.nameFieldStringValue = imageFileName;
    savePanel.allowedFileTypes = [NSArray arrayWithObject:imageExtentsion];

    NSURL *lastDirectoryURL = [[NSUserDefaults standardUserDefaults]
                               URLForKey:kImageSaveDirectoryKey];

    if (lastDirectoryURL == nil) {
        lastDirectoryURL = [[NSFileManager defaultManager]
                            URLForDirectory:NSDesktopDirectory
                            inDomain:NSUserDomainMask
                            appropriateForURL:nil
                            create:NO
                            error:nil];
    }

    savePanel.directoryURL = lastDirectoryURL;

    [savePanel beginSheetModalForWindow:imageWindow
                      completionHandler:^(NSInteger result) {
                          if (result == NSFileHandlingPanelOKButton) {
                              [savePanel orderOut:self];
                              [self saveImage:self.currentImage toURL:savePanel.URL];
                          }
                      }];
}

- (void)copyImage:(NSMenuItem *)sender
{
    NSPasteboard *pastebaord = [NSPasteboard generalPasteboard];
    NSArray *imagesToCopy = [NSArray arrayWithObject:self.currentImage];;
    [pastebaord clearContents];
    [pastebaord writeObjects:imagesToCopy];
}

- (void)saveImage:(NSImage *)aImage toURL:(NSURL *)aURL
{
    NSRect repRect = NSMakeRect(0.0f, 0.0f, aImage.size.width, aImage.size.height);
    [aImage lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
                                   initWithFocusedViewRect:repRect];
    [aImage unlockFocus];
    NSArray *reps = [NSArray arrayWithObject:bitmapRep];
    [bitmapRep release];

    NSBitmapImageFileType imageType = NSJPEGFileType;
    if ([aURL.pathExtension isEqualToString:@"png"]) {
        imageType = NSPNGFileType;
    }

    NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:reps
                                                                  usingType:imageType
                                                                 properties:nil];
    [bitmapData writeToURL:aURL atomically:NO];

    [[NSUserDefaults standardUserDefaults] setURL:[aURL URLByDeletingLastPathComponent]
                                           forKey:kImageSaveDirectoryKey];
}

- (void)willSaveImageInWindow:(NSWindow *)window
{
    NSImage *image = objc_getAssociatedObject(window, kImageAssociationKey);
    NSNumber *imageType = objc_getAssociatedObject(window,
                                                   kImageTypeAssociationKey);
    NSString *imageName = objc_getAssociatedObject(window,
                                                   kImageNameAssociationKey);
    self.currentImage = image;
    self.currentImageType = imageType.unsignedIntValue;
    self.currentImageName = imageName;
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

#pragma mark - ImageViewer Delegate Methods

- (NSMenu *)contextMenuForView:(NSView *)view
{
    [self willSaveImageInWindow:view.window];

    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *copyMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy"
                                                      action:nil
                                               keyEquivalent:@"c"];
    copyMenuItem.target = self;
    copyMenuItem.action = @selector(copyImage:);

    NSMenuItem *saveMenuItem = [[NSMenuItem alloc] initWithTitle:@"Save As..."
                                                      action:nil
                                               keyEquivalent:@"s"];
    saveMenuItem.target = self;
    saveMenuItem.action = @selector(saveImage:);
    [menu addItem:copyMenuItem];
    [menu addItem:saveMenuItem];
    [copyMenuItem release];
    return [menu autorelease];
}

#pragma mark - NSDraggingSource Methods

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationCopy;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
    NSString *imageExtentsion = @"jpg";
    if (self.currentImageType == NSPNGFileType) {
        imageExtentsion = @"png";
    }

    NSString *imageFileName = [NSString stringWithFormat:@"%@.%@",
                               self.currentImageName, imageExtentsion];
    NSUInteger i = 1;
    NSURL *imageFileURL = [dropDestination
                           URLByAppendingPathComponent:imageFileName];
    while ([imageFileURL checkResourceIsReachableAndReturnError:nil]) {
        imageFileName = [NSString stringWithFormat:@"%@-%d.%@",
                         self.currentImageName, i++, imageExtentsion];
        imageFileURL = [dropDestination
                        URLByAppendingPathComponent:imageFileName];
    }

    [self saveImage:self.currentImage toURL:imageFileURL];

    return [NSArray arrayWithObject:imageFileName];
}

@end
