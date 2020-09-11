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

#import <UIKit/UIKit.h>

/**
   A View Controller which scans and connects to TLMMyos in the vicinity. TLMMyos that are connected through this
   view controller will be paired as well. Needs to be embedded in a UINavigationController. To connect, tap a TLMMyo
   in the list. To disconnect, tap a connected TLMMyo. To remove the device from the list, slide the cell to the left.
   Once removed, the device can be discovered again by clicking scan. If a Myo's firmware verison is out of date, a
   yellow circle will appear beside it. This Myo cannot be connected until the firmware version is updated.
 */
@interface TLMSettingsViewController : UITableViewController

/**
   Returns a UINavigationController that contains the TLMSettingsViewController. You can present this modally.
 */
+ (UINavigationController *)settingsInNavigationController;

/**
   Returns a UIPopoverController that contains a TLMSettingsViewController. You must maintain a strong reference to the
   popover once it is presented.
 */
+ (UIPopoverController *)settingsInPopoverController;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
    __attribute__((unavailable("initWithCoder not available. Use init.")));

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
    __attribute__((unavailable("initWithNibName not available. Use init.")));

- (instancetype)initWithStyle:(UITableViewStyle)style
    __attribute__((unavailable("initWithStyle not available. Use init.")));

@end
