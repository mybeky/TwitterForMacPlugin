//
//  TwitterForMacPlugins.m
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/9/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import <objc/runtime.h>
#import "TwitterForMacPlugins.h"

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

- (void)__didLoadImage:(id)image
{
    [self __didLoadImage:image];
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

@end

@implementation TwitterForMacPlugins

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
}

+ (TwitterForMacPlugins *)sharedInstance
{
    static TwitterForMacPlugins *instance = nil;
    
    if (instance == nil)
        instance = [[TwitterForMacPlugins alloc] init];
    
    return instance;
}

@end
