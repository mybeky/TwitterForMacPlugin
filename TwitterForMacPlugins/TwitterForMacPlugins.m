//
//  TwitterForMacPlugins.m
//  TwitterForMacPlugins
//
//  Created by mybeky on 6/9/12.
//  Copyright (c) 2012 mybeky. All rights reserved.
//

#import <objc/runtime.h>
#import "TwitterForMacPlugins.h"

NSString * const kInstagramHost = @"instagr.am";

@implementation NSObject(TwitterForMacPlugins)

+ (BOOL)_isImageServiceLink:(NSURL *)aURL
{
    NSLog(@"%@", aURL);
    if (aURL && [aURL.absoluteString
         rangeOfString:@"instagr.am/p/"].location != NSNotFound) {
        return YES;
    }
    return NO;
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
    NSLog(@"%@", image);
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
    
}

+ (TwitterForMacPlugins *)sharedInstance
{
    static TwitterForMacPlugins *instance = nil;
    
    if (instance == nil)
        instance = [[TwitterForMacPlugins alloc] init];
    
    return instance;
}

@end
