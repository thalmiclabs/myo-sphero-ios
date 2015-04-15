//
//  TLMLockEvent.h
//  MyoKit
//
//  Copyright (C) 2014 Thalmic Labs Inc.
//  Distributed under the Myo SDK license agreement. See LICENSE.txt.
//

#import <Foundation/Foundation.h>

@class TLMMyo;

@interface TLMLockEvent : NSObject <NSCopying>

/** The TLMMyo for this lock event. */
@property (nonatomic, weak, readonly) TLMMyo *myo;

/** The time of the lock event. */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@end
