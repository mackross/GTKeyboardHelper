//
//  GTKeyboardHelper.h
//
//  Created by Andrew Mackenzie-Ross on 13/04/11.
//  Copyright (c) 2011 Andrew Mackenzie-Ross. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    GTKeyboardHelperAutoFocusScrollPositionProportional, // default - this should behave nicely
    GTKeyboardHelperAutoFocusScrollPositionBottom, // this forces the first responder even if the content offset is out of bounds
    GTKeyboardHelperAutoFocusScrollPositionTop, // this forces the first responder even if the content offset is out of bounds
    GTKeyboardHelperAutoFocusScrollNone, // this doesn't change the content offset but still does change the scroll views frame.
} GTKeyboardHelperAutoFocusScrollPosition;

//////////////////////////////////////////////////////////////////////////////////////////////////////
///  Public Interface
//////////////////////////////////////////////////////////////////////////////////////////////////////

@interface GTKeyboardHelper : UIScrollView {
    UITapGestureRecognizer *tap_;
    UIPanGestureRecognizer *pan_;
    UISwipeGestureRecognizer *swipe_;
}

/**
 Use this to force auto focus to occur on a view within the scroll view.
 This is automatically called on keyboard notifications. It might be used so that a next button on the keyboard moves
 the next first responder into view.
 */
- (void)autoFocusOnView:(UIView*)view withAutoScrollPosition:(GTKeyboardHelperAutoFocusScrollPosition)scrollPosition;

/**
 Use this to disable/enable keyboard monitoring.
 If weird things happen when pushing/popping view controllers consider setting to NO on viewWillDisappear: or viewDidDisappear:
 and YES on viewWillAppear: or viewDidAppear:
 */
@property (nonatomic, assign, getter = isMonitoringKeyboard) BOOL monitoringKeyboard; 

/**
 Use this to change the behaviour of the scroll views auto focus behaviour when the keyboard appears.
 */
@property (nonatomic, assign) GTKeyboardHelperAutoFocusScrollPosition autoFocusScrollPosition;

@property (nonatomic, assign) BOOL dismissKeyboardOnTouchOutside; // default YES
@property (nonatomic, assign) BOOL dismissKeyboardOnScroll; // default NO
@end


//////////////////////////////////////////////////////////////////////////////////////////////////////
///  Example Usage
//////////////////////////////////////////////////////////////////////////////////////////////////////


//      this is an example of how a resizing a container UIView (detailContainerView) of the GTKeyboardHelper (detailScrollView)  could work.
//      this assumes that self.detailContatinerView view is a UIView with the content that needs to be keyboard aware and that self.detailScrollView is an 
//      instance of GTKeyboardHelper.
//
//
//    - (void)viewDidLoad {
//      [super viewDidLoad];
//
//      [self.detailScrollView addSubview:self.detailContainerView];
//      [self.detailScrollView setContentSize:self.detailContainerView.frame.size];
//
//      [self setFrameOnDetailContainerViewForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
//
//    }
//
//
//    - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//     [self setFrameOnDetailContainerViewForInterfaceOrientation:toInterfaceOrientation];
//    }
//
//
//    - (void)setFrameOnDetailContainerViewForInterfaceOrientation:(UIInterfaceOrientation)intefaceOrientation {
//        if (UIInterfaceOrientationIsLandscape(intefaceOrientation)) 
//        {
//            [self.detailContainerView setFrame:CGRectMake(0.0, 0.0, 445.0, 704)];
//            [self.detailScrollView setContentSize:CGSizeMake(445, 704)];
//        }
//        else
//        {
//            [self.detailContainerView setFrame:CGRectMake(0.0, 0.0, 445.0, 960)];
//            [self.detailScrollView setContentSize:CGSizeMake(445, 960)];
//        }
//    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
///  Forces Linker to load GTKeyboardHelper
//////////////////////////////////////////////////////////////////////////////////////////////////////

// If this file is referenced in a project using #import <GTKeyboardHelper/GTKeyboardHelper.h> the following category will force the linker to load GTKeyboardHelper.

@interface GTKeyboardHelper (force_linking)
@end
@implementation GTKeyboardHelper (force_linking)
@end
