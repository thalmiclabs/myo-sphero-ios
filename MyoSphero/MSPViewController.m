//
//  MSPViewController.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2013-09-16.
//  Copyright (c) 2013 Thalmic Labs. All rights reserved.
//

#import "MSPViewController.h"
#import "MSPLookAndFeel.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"
#import "RobotKit/RKRobotControl.h"

#import <MyoKit/MyoKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MSPViewController()

@property (nonatomic, readonly) TLMMyo *myo;
@property (nonatomic, strong) TLMPose *lastPose;
@property (nonatomic, readonly) TLMPoseType waveLeft;
@property (nonatomic, readonly) TLMPoseType waveRight;
@property (nonatomic, readonly) BOOL isCalibrating;
@property (nonatomic, readwrite) BOOL isMyoEnabled;

@property (nonatomic, readwrite) TLMEulerAngles *referenceEulerAngles;
@property (nonatomic, readwrite) double relativePitch;
@property (nonatomic, readwrite) double relativeRoll;
@property (nonatomic, readwrite) double relativeYaw;
@property (nonatomic, readwrite) double calibrationHeading;

@property (nonatomic, strong) RKRobotControl *robotControl;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *enableMyoButton;

- (IBAction)enableMyoTapped:(UIButton *)sender;

@end

@implementation MSPViewController

#pragma mark - View Lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    [self observerNotifications];
    [self setupRobotConnection];
    [self updateUIForMyoState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupRobotConnection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)appWillTerminate {
    /*When the application is ending we need to close the connection to the robot*/
    [self closeRobotConnection];
}

#pragma mark - Instance Methods

- (void)observerNotifications {
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

- (void)updateUIForMyoState {
    if (!self.robotControl) {
        self.statusLabel.text = @"Please connect Sphero.";
    } else if (!self.myo) {
        self.statusLabel.text = @"Please connect a Myo.";
    } else if (self.myo.arm == TLMArmUnknown && self.myo.state == TLMMyoConnectionStateConnected) {
        self.statusLabel.text = @"Please perform the Sync Gesture.";
    } else if (!self.isMyoEnabled) {
        self.statusLabel.text = @"Myo Disabled";
    } else if (self.isCalibrating) {
        self.statusLabel.text = @"Calibrating Sphero";
    } else {
        self.statusLabel.text = @"Controlling Sphero";
    }

    // Enable Myo button
    if (self.isMyoEnabled) {
        [self.enableMyoButton setTitle:@"Disable Myo" forState:UIControlStateNormal];
        self.enableMyoButton.backgroundColor = [MSPLookAndFeel thalmicBlue];
    } else {
        [self.enableMyoButton setTitle:@"Enable Myo" forState:UIControlStateNormal];
        self.enableMyoButton.backgroundColor = [MSPLookAndFeel disabledGrey];
    }
}

#pragma mark - Sphero Methods

#pragma mark Robot Lifecycle

- (void)handleRobotOnline {
    /*The robot is now online, we can begin sending commands*/
    self.robotControl = [[RKRobotControl alloc] initWithRobot:[[RKRobotProvider sharedRobotProvider] robot]];
    self.calibrationHeading = 0;
    [self updateUIForMyoState];
}

- (void)handleRobotOffline {
    self.robotControl = nil;
    [self updateUIForMyoState];
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
}

#pragma mark - Myo Methods

- (void)onMyoAvailable {
    [self shouldCalibrateRobot:YES];
    self.isMyoEnabled = YES;
    [self updateUIForMyoState];
}

- (void)onMyoUnavailable {
    [self.robotControl rollAtHeading:self.calibrationHeading velocity:0.0];
    [self updateUIForMyoState];
}

#pragma mark Helper Methods

- (TLMMyo *)myo {
    return [[[TLMHub sharedHub] myoDevices] firstObject];
}

- (TLMPoseType)waveLeft {
    return (self.myo.arm == TLMArmLeft ? TLMPoseTypeWaveOut : TLMPoseTypeWaveIn);
}

- (TLMPoseType)waveRight {
    return (self.myo.arm == TLMArmLeft ? TLMPoseTypeWaveIn : TLMPoseTypeWaveOut);
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

#pragma mark NSNotificationCenter Methods

- (void)didReceiveOrientation:(NSNotification*)notification {

    if(!self.myo || !self.isMyoEnabled || !self.robotControl) {
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

    if(!self.myo || !self.isMyoEnabled || !self.robotControl) {
        return;
    }

    switch (poseType) {
        case TLMPoseTypeDoubleTap:
            if (isBeginning) {
                if (!self.isCalibrating) {
                    [self shouldCalibrateRobot:!self.isCalibrating];
                    [self updateUIForMyoState];
                    [self.myo indicateUserAction];
                    self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
                }
            }
            break;
        case TLMPoseTypeFingersSpread:
            if (isBeginning) {
                if (self.isCalibrating) {
                    [self shouldCalibrateRobot:!self.isCalibrating];
                    [self updateUIForMyoState];
                    [self.myo indicateUserAction];
                    self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
                }
            }
        case TLMPoseTypeFist:
            if (isBeginning) {
                self.referenceEulerAngles = [TLMEulerAngles anglesWithQuaternion:self.myo.orientation.quaternion];
            }
            // Indicate user action for both beginning and end of fist.
            [self.myo indicateUserAction];
            break;

        default:
            break;
    }
}

- (void)didReceiveSyncGesture:(NSNotification *)notification {
    [self updateUIForMyoState];
}

- (void)didReceiveUnsyncGesture:(NSNotification *)notification {
    [self onMyoUnavailable];
}

#pragma mark - IBAction Methods

- (IBAction)enableMyoTapped:(UIButton *)sender {
    self.isMyoEnabled = !self.isMyoEnabled;
    [self updateUIForMyoState];
}

@end
