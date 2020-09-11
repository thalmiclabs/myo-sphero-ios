// Copyright 2014 Google LLC
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

#import <Foundation/Foundation.h>

@class TLMMyo;

/**
 Represents EMG sensor data at a particular time from each of the 8 sensors located on a TLMMyo.
 */
@interface TLMEmgEvent : NSObject <NSCopying>

/**
 The TLMMyo that recorded the EMG data.
 */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/**
 An array of NSNumbers representing the EMG data.
 */
@property (nonatomic, strong, readonly) NSArray *rawData;

/**
 The timestamp associated with the EMG data.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
