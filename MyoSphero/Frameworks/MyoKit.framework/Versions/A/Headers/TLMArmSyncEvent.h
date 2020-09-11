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

@interface TLMArmSyncEvent : NSObject <NSCopying>

/**
 An enum representing the arm location of a TLMMyo.
 */
typedef NS_ENUM (NSInteger, TLMArm) {
    TLMArmUnknown,  /**< Myo location is not known.*/
    TLMArmRight,    /**< Myo is on the right arm.*/
    TLMArmLeft      /**< Myo is on the left arm.*/
};

/**
 An enum representing the direction of the +x axis of a TLMMyo.
 */
typedef NS_ENUM (NSInteger, TLMArmXDirection) {
    TLMArmXDirectionUnknown,        /**< Myo's +x axis is not known.*/
    TLMArmXDirectionTowardWrist,    /**< Myo's +x axis is pointing toward the user's wrist.*/
    TLMArmXDirectionTowardElbow     /**< Myo's +x axis is pointing toward the user's elbow.*/
};

/**
 The TLMMyo that has been synced with an arm.
 */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/**
 The arm that the Myo armband is on.
 */
@property (nonatomic, readonly) TLMArm arm;

/**
 The +x axis direction of the Myo armband relative to a user's arm.
 */
@property (nonatomic, readonly) TLMArmXDirection xDirection;

/**
 The timestamp associated with the arm sync event.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
