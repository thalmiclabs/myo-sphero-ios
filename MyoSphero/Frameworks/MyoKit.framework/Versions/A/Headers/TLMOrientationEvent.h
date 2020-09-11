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
#import "TLMEulerAngles.h"

@class TLMMyo;

/**
   Represents the orientation of a TLMMyo. The orientation is represented via a quaternion.
 */
@interface TLMOrientationEvent : NSObject <NSCopying>

/**
   The TLMMyo whose orientation changed.
 */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/**
   Orientation representation as a normalized quaternion.
 */
@property (nonatomic, readonly) TLMQuaternion quaternion;

/**
   The timestamp associated with the orientation.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
