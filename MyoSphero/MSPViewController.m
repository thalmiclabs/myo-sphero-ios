// Copyright 2013 Google LLC
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

#import "MSPViewController.h"
#import "MSPSpheroDriveAlgorithm.h"
#import <MyoKit/MyoKit.h>

@interface MSPViewController() <MSPSpheroDriveAlgorithmDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) MSPSpheroDriveAlgorithm *driveAlgorithm;
@property (nonatomic, strong) UIAlertView *robotConnectAlertView;

@property (weak, nonatomic) IBOutlet UIButton *addSpheroButton;
@property (weak, nonatomic) IBOutlet UIButton *addMyoButton;
@property (weak, nonatomic) IBOutlet UIImageView *spheroImageView;
@property (weak, nonatomic) IBOutlet UIImageView *spheroConnectedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *ollieImageView;
@property (weak, nonatomic) IBOutlet UIImageView *myoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *spheroCheckmark;
@property (weak, nonatomic) IBOutlet UIImageView *myoCheckmark;
@property (weak, nonatomic) IBOutlet UILabel *spheroLabel;
@property (weak, nonatomic) IBOutlet UILabel *myoLabel;
@property (weak, nonatomic) IBOutlet UILabel *spheroStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *myoStateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *fistAndRotateIcon;
@property (weak, nonatomic) IBOutlet UIImageView *spreadFingersIcon;
@property (weak, nonatomic) IBOutlet UIImageView *panIcon;
@property (weak, nonatomic) IBOutlet UIImageView *doubleTapIcon;
@property (weak, nonatomic) IBOutlet UIImageView *connectedDots;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *poseContainerConstraint;

@end

@implementation MSPViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.driveAlgorithm = [[MSPSpheroDriveAlgorithm alloc] init];
    self.driveAlgorithm.delegate = self;
    [self updateUIForMyoState];
}

- (void)viewDidLayoutSubviews {
    if ([self is3Point5InchScreen]) {
        [self.connectedDots setHidden:YES];
        [self.iconSpacingConstraint setConstant:10];
        [self.poseContainerConstraint setConstant:80];
    }
}

#pragma mark - Instance Methods

- (void)updateUIForMyoState {

    BOOL spheroConnected = self.driveAlgorithm.spheroConnected;
    BOOL ollieConnected = self.driveAlgorithm.ollieConnected;
    BOOL robotConnected = spheroConnected || ollieConnected;
    BOOL myoConnected = self.driveAlgorithm.myoConnected;
    BOOL spheroAndMyoConnected = spheroConnected && myoConnected;
    BOOL ollieAndMyoConnected = ollieConnected && myoConnected;
    BOOL robotAndMyoConnected = robotConnected && myoConnected;

    // Ollie Images
    NSString *ollieImage = ollieAndMyoConnected ? @"calibrate_ollie" : @"ollie_faded";
    NSString *ollieHighlightedImage = ollieAndMyoConnected ? @"drive_ollie" : @"ollie";
    [self.ollieImageView setImage:[UIImage imageNamed:ollieImage]];
    [self.ollieImageView setHighlightedImage:[UIImage imageNamed:ollieHighlightedImage]];

    // Visibility
    [self.addSpheroButton setSelected:robotConnected];
    [self.spheroCheckmark setHidden:!robotConnected];
    [self.spheroImageView setHighlighted:spheroConnected];
    [self.spheroImageView setHidden:robotAndMyoConnected || ollieConnected];
    [self.spheroConnectedImageView setHidden:!(spheroAndMyoConnected)];
    [self.spheroConnectedImageView setHighlighted:!self.driveAlgorithm.isCalibrating];
    [self.ollieImageView setHidden:!ollieConnected];
    BOOL ollieHighlighted = ((ollieConnected && !myoConnected) ||
                             (ollieAndMyoConnected && !self.driveAlgorithm.isCalibrating));
    [self.ollieImageView setHighlighted:ollieHighlighted];
    [self.spheroStateLabel setHidden:!robotConnected];

    [self.addMyoButton setSelected:myoConnected];
    [self.myoCheckmark setHidden:!myoConnected];
    [self.myoImageView setHighlighted:myoConnected];
    [self.myoStateLabel setHidden:!myoConnected];

    // Colors
    [self.spheroLabel setTextColor:robotConnected ? [UIColor whiteColor] : [UIColor blackColor]];
    [self.myoLabel setTextColor:myoConnected ? [UIColor whiteColor] : [UIColor blackColor]];

    // Text
    if (self.driveAlgorithm.isCalibrating) {
        [self.spheroStateLabel setText: @"CALIBRATION MODE"];
    } else {
        [self.spheroStateLabel setText: @"DRIVE MODE"];
    }
    if (self.myo.arm == TLMArmUnknown && self.myo.state == TLMMyoConnectionStateConnected) {
        [self.myoStateLabel setText:@"PERFORM SYNC GESTURE"];
    } else {
        [self.myoStateLabel setText:@"MYO SYNCED"];
    }
    if (myoConnected) {
        [self.myoLabel setText:self.driveAlgorithm.myoName];
    } else {
        [self.myoLabel setText:@"CONNECT MYO..."];
    }
    if (robotConnected) {
        [self.spheroLabel setText:self.driveAlgorithm.robotName];
    } else {
        [self.spheroLabel setText:@"CONNECT SPHERO OR OLLIE..."];
    }

    // Alert View
    if (robotConnected && self.robotConnectAlertView.isVisible) {
        [self.robotConnectAlertView dismissWithClickedButtonIndex:0 animated:YES];
        self.robotConnectAlertView = nil;
    }
}

- (BOOL)is3Point5InchScreen {
    UIScreen *screen = [UIScreen mainScreen];
    return screen.bounds.size.height < 568;
}

#pragma mark - Myo Methods

- (TLMMyo *)myo {
    return [[[TLMHub sharedHub] myoDevices] firstObject];
}

#pragma mark - MSPSpheroDriveAlgorithmDelegate Methods

- (void)didUpdateState {
    [self updateUIForMyoState];
}

- (void)didMakeInputType:(InputType)type isBeginning:(BOOL)isBeginning {
    switch (type) {
        case InputTypeFistTwist:
            [self.fistAndRotateIcon setHighlighted:isBeginning];
            break;
        case InputTypeFingersSpread:
            [self.spreadFingersIcon setHighlighted:isBeginning];
            break;
        case InputTypePan:
            [self.panIcon setHighlighted:isBeginning];
            break;
        case InputTypeDoubleTap:
            [self.doubleTapIcon setHighlighted:isBeginning];
            break;
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.robotConnectAlertView = nil;
}

#pragma mark - IBAction Methods

- (IBAction)addSpheroTapped:(UIButton *)sender {

    if ([sender isSelected]) {
        [self.driveAlgorithm disconnectSphero];
    } else {
        NSString *title = @"Connect Sphero or Ollie";
        NSString *message = @"Connect Sphero in the iOS Settings app. Go to Settings > Bluetooth and tap on Sphero in the list of devices.\n\nConnect Ollie by bringing it close to your iOS device.";
        self.robotConnectAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
        [self.robotConnectAlertView show];
    }
}

- (IBAction)addMyoTapped:(UIButton *)sender {
    if ([sender isSelected]) {
        [[TLMHub sharedHub] detachFromMyo:self.myo];
    } else {
        UINavigationController *settingsNavController = [TLMSettingsViewController settingsInNavigationController];
        settingsNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;
        settingsNavController.navigationBar.translucent = NO;
        settingsNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        settingsNavController.navigationBar.tintColor = [UIColor colorWithRed:0.0/255.0
                                                                        green:188.0/255.0
                                                                         blue:221.0/255.0
                                                                        alpha:1.0];
        [self presentViewController:settingsNavController animated:YES completion:nil];
    }
}

@end
