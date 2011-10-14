//
//  ViewController.m
//  Keyboard Helper Demo
//
//  Created by Andrew Mackenzie-Ross on 14/10/11.
//  Copyright (c) 2011 mackross.net. All rights reserved.
//

#import "ViewController.h"
@implementation ViewController


// See nib files for how GTKeyboardHelper is implemented in this project.
// For more customisation of behaviour and information on how to support multiple orientations see header file <GTKeyboardHelper/GTKeyboardHelper.h>
//
// Tested on iOS 4.3 and above. Uses gesture recognises and therefore definitely wont work on iOS 3.x

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
