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

/** A representation of an angle in either degrees and radians */
@interface TLMAngle : NSObject <NSCopying>

/** The angle represented in degrees */
@property (nonatomic, readonly) double degrees;

/** The angle represented in radians */
@property (nonatomic, readonly) double radians;

- (instancetype)init __attribute__((unavailable("init not available, use either initWithRadians or initWithDegrees")));

/**
   Initialize angle with radians
   @param aRadian
 */
- (instancetype)initWithRadians:(double)aRadian;

/**
   Initialize angle with degrees
   @param aDegree
 */
- (instancetype)initWithDegrees:(double)aDegree;

/**
   Initialize angle with another angle
   @param anAngle
 */
- (instancetype)initWithAngle:(TLMAngle *)anAngle;

@end
