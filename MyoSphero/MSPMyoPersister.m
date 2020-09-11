// Copyright 2015 Google LLC
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

#import "MSPMyoPersister.h"
#import <MyoKit/MyoKit.h>

#define PAIRED_DEVICE_IDENTIFIER @"PAIRED_DEVICE_IDENTIFIER"

@implementation MSPMyoPersister

#pragma mark - Constructors/Destructors

+ (instancetype)instance {
    static MSPMyoPersister *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });

    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self subscribeToNotifications];
        [self attachToPairedMyo];
    }
    return self;
}

#pragma mark - Instance Methods

- (void)attachToPairedMyo {
    NSUUID *identifier = [self pairedIdentifier];
    if (identifier) {
        [[TLMHub sharedHub] attachByIdentifier:identifier];
    }
}

- (void)subscribeToNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAttachToMyo:)
                                                 name:TLMHubDidAttachDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDetachFromMyo:)
                                                 name:TLMHubDidDetachDeviceNotification
                                               object:nil];
}

#pragma mark User Defaults

- (void)storeIdentifier:(NSUUID *)identifier {
    dispatch_async([MSPMyoPersister userDefaultsQueue], ^{
        [[NSUserDefaults standardUserDefaults] setObject:identifier.UUIDString forKey:PAIRED_DEVICE_IDENTIFIER];
    });
}

- (NSUUID *)pairedIdentifier {
    __block NSUUID *identifier = nil;
    dispatch_sync([MSPMyoPersister userDefaultsQueue], ^{
        NSString *identifierString = [[NSUserDefaults standardUserDefaults] objectForKey:PAIRED_DEVICE_IDENTIFIER];
        if (identifierString) {
            identifier = [[NSUUID alloc] initWithUUIDString:identifierString];
        }
    });
    return identifier;
}

#pragma mark - Class Methods

+ (dispatch_queue_t)userDefaultsQueue {
    static dispatch_queue_t _userDefaultsQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _userDefaultsQueue = dispatch_queue_create("com.thalmic.myo-persister", DISPATCH_QUEUE_SERIAL);
    });

    return _userDefaultsQueue;
}

#pragma mark - NSNotification Methods

- (void)didAttachToMyo:(NSNotification *)notification {
    TLMMyo *myo = [[[TLMHub sharedHub] myoDevices] firstObject];
    [self storeIdentifier:myo.identifier];
}

- (void)didDetachFromMyo:(NSNotification *)notification {
    [self storeIdentifier:nil];
}

@end
