//
//  MEAppDelegate.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEAppDelegate.h"
#import "MEModel.h"
#import <MagicalRecord/MagicalRecord.h>

@import NSURL_ParseQuery;

@implementation MEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MEModel sharedInstance];
        
    [self.window setTintColor:[UIColor whiteColor]];
    [application setApplicationSupportsShakeToEdit:YES];
    
    // Appirater Setup
    [Appirater setAppId:@"921847909"];
    [Appirater setDaysUntilPrompt:2];
    [Appirater setUsesUntilPrompt:4];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:3];
    [Appirater appLaunched:YES];
    [Appirater setDebug:NO];
    
    [[GAI sharedInstance] setTrackUncaughtExceptions:YES];
    [[GAI sharedInstance] setDispatchInterval:5];
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-35804692-6"];
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
    
    // Register for Push Notitications!!!!!!!!!!!

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{

}

- (NSString *)sanitizeChannelName:(NSString *)name
{
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"] invertedSet];
    return [[name componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{

}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [Appirater appEnteredForeground:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:reloadPurchaseableContentKey object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:reloadPurchaseableContentKey object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *args = [url parseQuery]; // memoji://?hiphoppack=1?watermark=1
        
        @try {
            for (NSString *key in args.keyEnumerator.allObjects) {
                BOOL enabled = [@([[args objectForKey:key] integerValue]) boolValue];
                // Hip Hop Pack
                if ([key isEqualToString:hipHopPackProductIdentifier]) {
                    [[MEModel sharedInstance] setHipHopPackEnabled:enabled];
                }
                // Holiday Pack
                if ([key isEqualToString:holidayPackProductIdentifier]) {
                    [[MEModel sharedInstance] setHolidayPackEnabled:enabled];
                }
                // Watermark
                else if ([key isEqualToString:watermarkProductIdentifier]){
                    [[MEModel sharedInstance] setWatermarkEnabled:enabled];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Invalid URL passed in.");
        }
    });
    return YES;
}

@end
