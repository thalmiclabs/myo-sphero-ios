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

//---------
// TLMPose
//---------

/** Represents a hand pose detected by a TLMMyo. */
@interface TLMPose : NSObject <NSCopying>

/**
   Represents different hand poses.
 */
typedef NS_ENUM (NSInteger, TLMPoseType) {
    TLMPoseTypeRest,            /**< Rest pose.*/
    TLMPoseTypeFist,            /**< User is making a fist.*/
    TLMPoseTypeWaveIn,          /**< User has an open palm rotated towards the posterior of their wrist.*/
    TLMPoseTypeWaveOut,         /**< User has an open palm rotated towards the anterior of their wrist.*/
    TLMPoseTypeFingersSpread,   /**< User has an open palm with their fingers spread away from each other.*/
    TLMPoseTypeDoubleTap,       /**< User taps their thumb to their middle finger twice.*/
    TLMPoseTypeUnknown = 0xffff /**< Unknown pose.*/
};

/** The TLMMyo posting the pose. */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/** The pose being recognized. */
@property (nonatomic, readonly) TLMPoseType type;

/** The time the pose was recognized. */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
