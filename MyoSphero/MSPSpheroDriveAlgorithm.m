//
//  MSPSpheroDriveAlgorithm.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2015-04-29.
//  Copyright (c) 2015 Thalmic Labs. All rights reserved.
//

#import "MSPSpheroDriveAlgorithm.h"
#import "MSPLookAndFeel.h"
#import <RobotKit/RobotKit.h>
#import <RobotUIKit/RobotUIKit.h>
#import <MyoKit/MyoKit.h>

@interface MSPSpheroDriveAlgorithm()

@property (nonatomic, readwrite) TLMEulerAngles *referenceEulerAngles;
@property (nonatomic, readwrite) double relativePitch;
@property (nonatomic, readwrite) double relativeRoll;
@property (nonatomic, readwrite) double relativeYaw;
@property (nonatomic, readwrite) double calibrationHeading;
@property (nonatomic, readwrite) double lastCalibrationHeading;

@property (atomic, strong) RKConvenienceRobot *robot;
@property (nonatomic, readwrite) BOOL isCalibrating;
@property (nonatomic, readonly) TLMMyo *myo;
@property (nonatomic, strong) TLMPose *lastPose;

@end

@implementation MSPSpheroDriveAlgorithm

#pragma mark - Constuctors

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupNotifications];
        [[RKRobotDiscoveryAgent sharedAgent] setMaxConnectedRobots:1];
        [RKRobotDiscoveryAgent startDiscovery];
    }
    return  self;
}

#pragma mark - App Lifecycle 

- (void)appWillEnterForeground {
    [RKRobotDiscoveryAgent startDiscovery]; // Might be unnecessary
}

- (void)appWillTerminate {
    [self disconnectSphero];
}

#pragma mark - Instance Methods

- (BOOL)spheroConnected {
    return self.robot != nil;
}

- (BOOL)myoConnected {
    return self.myo != nil && self.myo.state == TLMMyoConnectionStateConnected;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoAvailable)
                                                 name:TLMHubDidAttachDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoUnavailable)
                                                 name:TLMHubDidDetachDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoAvailable)
                                                 name:TLMHubDidConnectDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoUnavailable)
                                                 name:TLMHubDidDisconnectDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoAvailable)
                                                 name:TLMMyoDidReceiveArmSyncEventNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMyoUnavailable)
                                                 name:TLMMyoDidReceiveArmUnsyncEventNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientation:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePose:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    [[RKRobotDiscoveryAgent sharedAgent] addNotificationObserver:self
                                                        selector:@selector(handleRobotStateChangeNotification:)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

#pragma mark - Sphero Methods

#pragma mark Robot Lifecycle

- (void)handleRobotStateChangeNotification:(RKRobotChangedStateNotification *)notification {
    switch(notification.type) {
        case RKRobotConnecting:
            break;
        case RKRobotOnline: {
            RKConvenienceRobot *convenience = [RKConvenienceRobot convenienceWithRobot:notification.robot];
            self.robot = convenience;
            [RKRobotDiscoveryAgent stopDiscovery];
            [self shouldCalibrateRobot:YES];
            break;
        }
        case RKRobotDisconnected:
            self.robot = nil;
            [RKRobotDiscoveryAgent startDiscovery];
            break;
        default:
            break;
    }
    [self.delegate didUpdateState];
}

- (void)disconnectSphero {
    [self.robot disconnect];
    [RKRobotDiscoveryAgent disconnectAll];
    self.robot = nil;
    [self.delegate didUpdateState];
}

#pragma mark Robot Interaction Methods

- (NSString *)spheroName {
    return self.robot.name.uppercaseString;
}

- (void)setRobotGlowColor:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    [self.robot setLEDWithRed:red green:green blue:blue];
}

- (void)shouldCalibrateRobot:(BOOL)shouldCalibrate {
    if (!self.isCalibrating && shouldCalibrate) {
        [self.robot calibrating:YES];
        [self setRobotGlowColor:[MSPLookAndFeel calibrationYellow]];
        [self.robot driveWithHeading:self.calibrationHeading andVelocity:0.0];
        self.isCalibrating = YES;
    } else if (self.isCalibrating && !shouldCalibrate) {
        [self.robot calibrating:NO];
        [self.robot setZeroHeading];
        [self setRobotGlowColor:[MSPLookAndFeel thalmicBlue]];
        self.isCalibrating = NO;
    }
    [self.delegate didUpdateState];
}

#pragma mark - Myo Methods

- (TLMMyo *)myo {
    return [[[TLMHub sharedHub] myoDevices] firstObject];
}

- (NSString *)myoName {
    return self.myo.name.uppercaseString;
}

- (void)calculateRelativeEulerAnglesForQuaternion:(TLMQuaternion)quaternion {
    TLMEulerAngles *currentEulerAngles = [TLMEulerAngles anglesWithQuaternion:quaternion];

    BOOL towardsElbow = self.myo.xDirection == TLMArmXDirectionTowardElbow;

    self.relativePitch = (towardsElbow ? -1 : 1) * currentEulerAngles.pitch.degrees;
    self.relativeRoll = (towardsElbow ? -1 : 1) * (currentEulerAngles.roll.degrees - self.referenceEulerAngles.roll.degrees);
    self.relativeYaw = currentEulerAngles.yaw.degrees - self.referenceEulerAngles.yaw.degrees;

    self.relativeRoll = [self boundRelativeValue:self.relativeRoll];
    self.relativeYaw = [self boundRelativeValue:self.relativeYaw];
}

- (double)boundRelativeValue:(double)value {
    if (value > 180) {
        return value -= 360;
    } else if (value < -180) {
        return value += 360;
    }
    return value;
}

#pragma mark - NSNotification Methods

- (void)onMyoAvailable {
    [self shouldCalibrateRobot:YES];
    [self.delegate didUpdateState];
}

- (void)onMyoUnavailable {
    [self shouldCalibrateRobot:YES];
    [self.delegate didUpdateState];
}

- (void)didReceiveOrientation:(NSNotification*)notification {

    if (![self myoConnected] || ![self spheroConnected]) {
        return;
    }

    TLMOrientationEvent *orientation = notification.userInfo[kTLMKeyOrientationEvent];
    [self calculateRelativeEulerAnglesForQuaternion:orientation.quaternion];

    double inputRoll = MIN(MAX(self.relativeRoll/45.0, -1), 1);
    double inputPitch = MIN(MAX(self.relativePitch/45.0, -1), 1);

    double heading = atan(inputRoll/inputPitch)*180/M_PI;
    double velocity = sqrt(inputRoll*inputRoll + inputPitch*inputPitch)/2;

    if (velocity > 0.55) velocity = 0;
    velocity = MIN(MAX(velocity, 0.0), 0.5);
    if (velocity < 0.10) velocity = 0;

    if (inputPitch < 0) heading += 180;

    heading -= self.relativeYaw;

    //bound the headings
    if (heading < 0) heading += 360;
    if (heading > 360) heading -= 360;

    if (self.isCalibrating) {
        if (self.myo.pose.type == TLMPoseTypeFist) {
            self.calibrationHeading = (self.relativeRoll * 3) + self.lastCalibrationHeading;

            while (self.calibrationHeading < 0) self.calibrationHeading += 360;
            while (self.calibrationHeading > 360) self.calibrationHeading -= 360;

            //RKSetHeadingCommand *command = [RKSetHeadingCommand commandWithHeading:self.calibrationHeading];
            //[self.robot sendCommand:command];
            [self.robot driveWithHeading:self.calibrationHeading andVelocity:0.0];
        }
    } else {
        [self.robot driveWithHeading:heading andVelocity:velocity];
    }
}

- (void)didReceivePose:(NSNotification*)notification {
    TLMPose *pose = notification.userInfo[kTLMKeyPose];

    if (self.lastPose) {
        [self didReceivePose:self.lastPose.type isBeginning:NO];
    }
    [self didReceivePose:pose.type isBeginning:YES];
    self.lastPose = pose;
}

- (void)didReceivePose:(TLMPoseType)poseType isBeginning:(BOOL)isBeginning {

    if (![self myoConnected] || ![self spheroConnected]) {
        return;
    }

    switch (poseType) {
        case TLMPoseTypeDoubleTap:
            if (isBeginning) {
                if (!self.isCalibrating) {
                    [self shouldCalibrateRobot:!self.isCalibrating];
                    [self.myo indicateUserAction];
                    self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
                }
            }
            break;
        case TLMPoseTypeFingersSpread:
            if (isBeginning) {
                if (self.isCalibrating) {
                    [self shouldCalibrateRobot:!self.isCalibrating];
                    [self.myo indicateUserAction];
                    self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
                }
            }
            break;
        case TLMPoseTypeFist:
            if (self.isCalibrating) {
                if (isBeginning) {
                    self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
                } else {
                    self.lastCalibrationHeading = self.calibrationHeading;
                }
                // Indicate user action for both beginning and end of fist.
                [self.myo indicateUserAction];
            }
            break;

        default:
            break;
    }
}

@end
