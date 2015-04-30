//
//  MSPSpheroDriveAlgorithm.h
//  MyoSphero
//
//  Created by Mark DiFranco on 2015-04-29.
//  Copyright (c) 2015 Thalmic Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MSPSpheroDriveAlgorithmDelegate <NSObject>

- (void)didUpdateState;

@end

@interface MSPSpheroDriveAlgorithm : NSObject

@property (nonatomic, readonly) BOOL myoConnected;
@property (nonatomic, readonly) BOOL spheroConnected;
@property (nonatomic, readonly) BOOL isCalibrating;

@property (nonatomic, assign) id<MSPSpheroDriveAlgorithmDelegate> delegate;

- (NSString *)spheroName;
- (NSString *)myoName;

@end
