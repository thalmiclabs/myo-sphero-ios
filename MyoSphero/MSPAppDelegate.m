//
//  MSPAppDelegate.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2013-09-16.
//  Copyright (c) 2013 Thalmic Labs. All rights reserved.
//

#import "MSPAppDelegate.h"
#import "MSPViewController.h"
#import "MSPMyoPersister.h"
#import <MyoKit/MyoKit.h>

@implementation MSPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Helps launch faster.
    [self performSelector:@selector(delayedApplicationDidFinishLaunchingWithOptions:)
               withObject:launchOptions
               afterDelay:0.1];

    return YES;
}

- (void)delayedApplicationDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [MSPMyoPersister instance];
    [[TLMHub sharedHub] setApplicationIdentifier:@"com.thalmic.ios.Myo-Sphero"];
    [[TLMHub sharedHub] setShouldNotifyInBackground:YES];
    [[TLMHub sharedHub] setLockingPolicy:TLMLockingPolicyNone];
}
							
- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

@end
