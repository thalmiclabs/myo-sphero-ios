//
//  MSPViewController.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2013-09-16.
//  Copyright (c) 2013 Thalmic Labs. All rights reserved.
//

#import "MSPViewController.h"
#import "MSPSpheroDriveAlgorithm.h"
#import <MyoKit/MyoKit.h>

@interface MSPViewController() <MSPSpheroDriveAlgorithmDelegate>

@property (nonatomic, strong) MSPSpheroDriveAlgorithm *driveAlgorithm;

@property (weak, nonatomic) IBOutlet UIButton *addSpheroButton;
@property (weak, nonatomic) IBOutlet UIButton *addMyoButton;
@property (weak, nonatomic) IBOutlet UIImageView *spheroImageView;
@property (weak, nonatomic) IBOutlet UIImageView *spheroConnectedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *myoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *spheroCheckmark;
@property (weak, nonatomic) IBOutlet UIImageView *myoCheckmark;
@property (weak, nonatomic) IBOutlet UILabel *spheroLabel;
@property (weak, nonatomic) IBOutlet UILabel *myoLabel;
@property (weak, nonatomic) IBOutlet UILabel *spheroStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *myoStateLabel;

@end

@implementation MSPViewController

#pragma mark - View Lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    self.driveAlgorithm = [[MSPSpheroDriveAlgorithm alloc] init];
    self.driveAlgorithm.delegate = self;
    [self updateUIForMyoState];
}

#pragma mark - Instance Methods

- (void)updateUIForMyoState {

    BOOL spheroConnected = self.driveAlgorithm.spheroConnected;
    BOOL myoConnected = self.driveAlgorithm.myoConnected;
    BOOL bothConnected = spheroConnected && myoConnected;

    // Visibility
    [self.addSpheroButton setSelected:spheroConnected];
    [self.spheroCheckmark setHidden:!spheroConnected];
    [self.spheroImageView setHighlighted:spheroConnected];
    [self.spheroImageView setHidden:bothConnected];
    [self.spheroConnectedImageView setHidden:!bothConnected];
    [self.spheroConnectedImageView setHighlighted:!self.driveAlgorithm.isCalibrating];
    [self.spheroStateLabel setHidden:!spheroConnected];

    [self.addMyoButton setSelected:myoConnected];
    [self.myoCheckmark setHidden:!myoConnected];
    [self.myoImageView setHighlighted:myoConnected];
    [self.myoStateLabel setHidden:!myoConnected];

    // Colors
    [self.spheroLabel setTextColor:spheroConnected ? [UIColor whiteColor] : [UIColor blackColor]];
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
    if (spheroConnected) {
        [self.spheroLabel setText:self.driveAlgorithm.spheroName];
    } else {
        [self.spheroLabel setText:@"CONNECT SPHERO..."];
    }
}

#pragma mark - Myo Methods

- (TLMMyo *)myo {
    return [[[TLMHub sharedHub] myoDevices] firstObject];
}

#pragma mark - MSPSpheroDriveAlgorithmDelegate Methods

- (void)didUpdateState {
    [self updateUIForMyoState];
}

#pragma mark - IBAction Methods

- (IBAction)addSpheroTapped:(UIButton *)sender {

    if ([sender isSelected]) {
        [self.driveAlgorithm disconnectSphero];
    } else {
        NSString *title = @"Connect Sphero";
        NSString *message = @"Connect Sphero in the iOS Settings app. Go to Settings > Bluetooth and tap on Sphero in the list of devices.";
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
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
