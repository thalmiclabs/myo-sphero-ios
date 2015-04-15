//
//  TLMEmgEvent.h
//  MyoKit
//
//  Copyright (C) 2014 Thalmic Labs Inc.
//  Distributed under the Myo SDK license agreement. See LICENSE.txt.
//

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
