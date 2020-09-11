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
#import "TLMMath.h"

@class TLMMyo;

/**
   Represents the current accelerometer values reported by a TLMMyo's accelerometer. Units are in Gs.
 */
@interface TLMAccelerometerEvent : NSObject <NSCopying>

/**
   The TLMMyo associated with the acceleration event.
 */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/**
   A vector representing the TLMMyo's acceleration (in Gs).
 */
@property (nonatomic, readonly) TLMVector3 vector;

/**
   The timestamp associated with the acceleration event.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
