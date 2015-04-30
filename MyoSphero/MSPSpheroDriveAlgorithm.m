//
//  MSPSpheroDriveAlgorithm.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2015-04-29.
//  Copyright (c) 2015 Thalmic Labs. All rights reserved.
//

#import "MSPSpheroDriveAlgorithm.h"
#import "MSPLookAndFeel.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"
#import "RobotKit/RKRobotControl.h"
#import <MyoKit/MyoKit.h>

@interface MSPSpheroDriveAlgorithm()

@property (nonatomic, readwrite) TLMEulerAngles *referenceEulerAngles;
@property (nonatomic, readwrite) double relativePitch;
@property (nonatomic, readwrite) double relativeRoll;
@property (nonatomic, readwrite) double relativeYaw;
@property (nonatomic, readwrite) double calibrationHeading;
@property (nonatomic, readwrite) double lastCalibrationHeading;

@property (nonatomic, strong) RKRobotControl *robotControl;
@property (nonatomic, readonly) TLMMyo *myo;
@property (nonatomic, strong) TLMPose *lastPose;

@end

@implementation MSPSpheroDriveAlgorithm

#pragma mark - Constuctors

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupNotifications];
        [self setupRobotConnection];
    }
    return  self;
}

#pragma mark - App Lifecycle 

- (void)appWillTerminate {
    /*When the application is ending we need to close the connection to the robot*/
    [self closeRobotConnection];
}

#pragma mark - Instance Methods

- (BOOL)spheroConnected {
    return self.robotControl != nil;
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
                                             selector:@selector(didReceiveSyncGesture:)
                                                 name:TLMMyoDidReceiveArmSyncEventNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveUnsyncGesture:)
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRobotOnline)
                                                 name:RKDeviceConnectionOnlineNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRobotOffline)
                                                 name:RKDeviceConnectionOfflineNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

#pragma mark - Sphero Methods

#pragma mark Robot Lifecycle

- (void)handleRobotOnline {
    /*The robot is now online, we can begin sending commands*/
    self.robotControl = [[RKRobotControl alloc] initWithRobot:[[RKRobotProvider sharedRobotProvider] robot]];
    self.calibrationHeading = 0;
    [self shouldCalibrateRobot:YES];
    [self.delegate didUpdateState];
}

- (void)handleRobotOffline {
    self.robotControl = nil;
    [self.delegate didUpdateState];
}

-(void)setupRobotConnection {
    /*Try to connect to the robot*/
    // If this doesn't work, try isRobotAvailable
    if ([[RKRobotProvider sharedRobotProvider] isRobotAvailable] && ![[RKRobotProvider sharedRobotProvider] isRobotConnected]) {
        [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    }
}

- (void)closeRobotConnection {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setRobotGlowColor:[UIColor whiteColor]];
    if([self.robotControl calibrating]) {
        [self.robotControl stopCalibrated:YES];
    }
    self.robotControl = nil;
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
}

#pragma mark Robot Interaction Methods

- (NSString *)spheroName {
    return self.robotControl.robot.name.uppercaseString;
}

- (BOOL)isCalibrating {
    return [self.robotControl calibrating];
}

- (void)setRobotGlowColor:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    [RKRGBLEDOutputCommand sendCommandWithRed:red green:green blue:blue];
}

- (void)shouldCalibrateRobot:(BOOL)shouldCalibrate {
    if(!self.isCalibrating && shouldCalibrate) {
        [self.robotControl startCalibration];
        [self setRobotGlowColor:[MSPLookAndFeel calibrationYellow]];
        [self.robotControl rollAtHeading:self.calibrationHeading velocity:0.0];
    } else if(self.isCalibrating && !shouldCalibrate) {
        [self.robotControl stopCalibrated:YES];
        [self setRobotGlowColor:[MSPLookAndFeel thalmicBlue]];
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
    [self.robotControl rollAtHeading:self.calibrationHeading velocity:0.0];
    [self.delegate didUpdateState];
}

- (void)didReceiveOrientation:(NSNotification*)notification {

    if(!self.myo || !self.robotControl) {
        return;
    }

    TLMOrientationEvent *orientation = notification.userInfo[kTLMKeyOrientationEvent];
    [self calculateRelativeEulerAnglesForQuaternion:orientation.quaternion];

    double inputRoll = MIN(MAX(self.relativeRoll/45.0, -1), 1);
    double inputPitch = MIN(MAX(self.relativePitch/45.0, -1), 1);

    double heading = atan(inputRoll/inputPitch)*180/M_PI;
    double velocity = sqrt(inputRoll*inputRoll + inputPitch*inputPitch)/2;

    if(velocity > 0.55) velocity = 0;
    velocity = MIN(MAX(velocity, 0.0), 0.5);
    if(velocity < 0.10) velocity = 0;

    if(inputPitch < 0) heading += 180;

    heading -= self.relativeYaw;

    //bound the headings
    if(heading < 0) heading += 360;
    if(heading > 360) heading -= 360;

    if(self.isCalibrating) {
        if (self.myo.pose.type == TLMPoseTypeFist) {
            self.calibrationHeading = self.relativeRoll * 3;

            while (self.calibrationHeading < 0) self.calibrationHeading += 360;
            while (self.calibrationHeading > 360) self.calibrationHeading -= 360;

            [self.robotControl rotateToHeading:self.calibrationHeading];
        }
    } else {
        [self.robotControl rollAtHeading:heading velocity:velocity];
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

    if(!self.myo || !self.robotControl) {
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
                }
                // Indicate user action for both beginning and end of fist.
                [self.myo indicateUserAction];
            }
            break;

        default:
            break;
    }
}

- (void)didReceiveSyncGesture:(NSNotification *)notification {
    [self.delegate didUpdateState];
}

- (void)didReceiveUnsyncGesture:(NSNotification *)notification {
    [self onMyoUnavailable];
}

@end
