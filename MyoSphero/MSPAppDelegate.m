// Copyright 2013 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
