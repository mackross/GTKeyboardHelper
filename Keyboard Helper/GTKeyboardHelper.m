//
//  GTKeyboardHelper.m
//
//  Created by Andrew Mackenzie-Ross on 13/04/11.
//  Copyright (c) 2011 Andrew Mackenzie-Ross. All rights reserved.
//

#import "GTKeyboardHelper.h"

#define PADDING 5

//////////////////////////////////////////////////////////////////////////////////////////////////////
///  Private Interface
//////////////////////////////////////////////////////////////////////////////////////////////////////

@interface GTKeyboardHelper ()

@property (nonatomic, assign, getter = isResizedForKeyboard) BOOL resizedForKeyboard;
@property (nonatomic, assign) CGFloat frameChangeOffset;

- (void)setup;
- (void)beginKeyboardMonitoring;
- (void)endKeyboardMonitoring;
- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;
- (UIView*)findFirstResponderWithinView:(UIView*)view;
- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer;
- (void)addGestureRecognizers;
- (void)removeGestureRecognizers;
@end

//////////////////////////////////////////////////////////////////////////////////////////////////////
///  Implementation
//////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation GTKeyboardHelper

@synthesize resizedForKeyboard=resizedForKeyboard_;
@synthesize frameChangeOffset=frameChangeOffset_;
@synthesize autoFocusScrollPosition=autoFocusScrollPosition_;
@synthesize dismissKeyboardOnTouchOutside=dismissKeyboardOnTouchOutside_;
@synthesize dismissKeyboardOnScroll=dismissKeyboardOnScroll_;

- (void)setDismissKeyboardOnScroll:(BOOL)dismissKeyboardOnScroll 
{
    dismissKeyboardOnScroll_ = dismissKeyboardOnScroll;
    [self removeGestureRecognizers];
    [self addGestureRecognizers];
}
- (void)setDismissKeyboardOnTouchOutside:(BOOL)dismissKeyboardOnTouchOutside
{
    dismissKeyboardOnTouchOutside_=dismissKeyboardOnTouchOutside;
    [self removeGestureRecognizers];
    [self addGestureRecognizers];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// monitoring keyboard property

@synthesize monitoringKeyboard=monitoringKeyboard_;
- (BOOL)isMonitoringKeyboard 
{
    return monitoringKeyboard_;
}

- (void)setMonitoringKeyboard:(BOOL)monitoringKeyboard 
{
    if (monitoringKeyboard && !monitoringKeyboard_)
    {
        [self beginKeyboardMonitoring];
    }
    else if (!monitoringKeyboard && monitoringKeyboard_)
    {
        [self endKeyboardMonitoring];
        
        if (self.frameChangeOffset != 0)
        {
            // reverse any frame changes if monitoring is turned off
            CGRect myFrame = [self convertRect:self.bounds toView:self.superview];
            CGRect oldFrame = myFrame;
            oldFrame.size.height += self.frameChangeOffset;
            self.frame = oldFrame;

        }
    }
    monitoringKeyboard_ = monitoringKeyboard;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// notification setup

- (void)beginKeyboardMonitoring 
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)endKeyboardMonitoring 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// notification handling

- (void)keyboardWillShow:(NSNotification *)notification 
{
    UIView *firstResponder = [self findFirstResponderWithinView:self];
    
    if (firstResponder == nil) 
    {
        // do nothing if no first responder in the scroll view.
        return;
    }
    
    // these are adjusted with converRect:toView: which makes origin 0,0 of the superview the reference point
    CGRect keyboardFrame = [self.window convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.superview];
    CGRect myFrame = [self convertRect:self.bounds toView:self.superview];
    CGRect newFrame = myFrame;
    self.frameChangeOffset = (myFrame.size.height + myFrame.origin.y) - keyboardFrame.origin.y;
    
    if (self.frameChangeOffset <= 0) 
    {
        // do nothing except set the frameChangeOffset to 0 otherwise it will make frame smaller when the keyboardWillHide: method is called later.
        self.frameChangeOffset = 0;
        return;
    }
    
    // change the frame size (height) of the scroll view so that the keyboard is not covering any of the frame.
    // we then save this value in the private property frameChangeOffset so that later we can reverse the change in the keyboardWillHide: method.
    // we animate this change using the same settings as used by the keyboard animation. this will make everything work nicely.
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    newFrame.size.height -= self.frameChangeOffset;
    self.frame = newFrame;
    
    // auto focus on first responder
    [self autoFocusOnView:firstResponder withAutoScrollPosition:self.autoFocusScrollPosition];
    
   
    [UIView commitAnimations];
    
    [self addGestureRecognizers];

}

- (void)keyboardWillHide:(NSNotification *)notification 
{
    
    CGRect myFrame = [self convertRect:self.bounds toView:self.superview];
    CGRect newFrame = myFrame;
    
    // we reverse the frame change that occured in the keyboardWillShow: method. 
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    newFrame.size.height += self.frameChangeOffset;
    self.frame = newFrame;
    
    // if contentSize is same size or smaller as newFrame lets put it in the top left
    if (self.contentSize.height <= newFrame.size.height) 
    {
        [self setContentOffset:CGPointMake(self.contentOffset.x, 0) animated:YES];
    }
    
    [UIView commitAnimations];
    
    // set frameChangeOffset to 0 to reset the state of the monitor.
    self.frameChangeOffset = 0;
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// auto focus

- (void)autoFocusOnView:(UIView*)view withAutoScrollPosition:(GTKeyboardHelperAutoFocusScrollPosition)scrollPosition
{
    // we now position the first responder in the location specified by AutoFocusScrollPosition
    CGRect firstResponderFrame = [view convertRect:view.bounds toView:self];
    CGRect myFrame = self.frame;
    
    if (firstResponderFrame.size.height + (PADDING*2) < myFrame.size.height) 
    {
        // we will only move the content offset if the first responder is smaller than the new scrollview. otherwise the user experience feels jared.
        if (scrollPosition == GTKeyboardHelperAutoFocusScrollNone) {
            // do nothing
        }
        if (scrollPosition == GTKeyboardHelperAutoFocusScrollPositionTop) 
        {
            [self setContentOffset:CGPointMake(self.contentOffset.x, firstResponderFrame.origin.y - PADDING) animated:YES];
        }
        if (scrollPosition == GTKeyboardHelperAutoFocusScrollPositionBottom) 
        {
            CGFloat currentLocation = firstResponderFrame.origin.y + firstResponderFrame.size.height;
            if (currentLocation > myFrame.size.height + self.contentOffset.y) {
            CGFloat proposedLocation = firstResponderFrame.origin.y + firstResponderFrame.size.height + PADDING - myFrame.size.height;
            [self setContentOffset:CGPointMake(self.contentOffset.x, proposedLocation) animated:YES];
            }
        }
        if (scrollPosition == GTKeyboardHelperAutoFocusScrollPositionProportional)
        {
            // this is the default mode and it uses a factor to move the scroller to a height
            CGFloat verticalCenterFirstResponder = firstResponderFrame.origin.y + (firstResponderFrame.size.height / 2.0);
            CGFloat positionRatio = verticalCenterFirstResponder / self.contentSize.height;
            
            CGFloat flip = floor(positionRatio * 2 - 1);
            CGFloat proposedLocation = verticalCenterFirstResponder - (myFrame.size.height * positionRatio) + (flip * PADDING) + (flip * firstResponderFrame.size.height);
            
            proposedLocation = floor(proposedLocation);
            
            // 3.0 means that anything in the top third of the new frame doesn't move.
            CGFloat noMovePoint = myFrame.size.height / 3.0;
            
            if (verticalCenterFirstResponder - proposedLocation < noMovePoint)
            {
                proposedLocation = 0.0;
            }
            
            // now we check if the content offset will push the scrollview further up than it should go.
            if (proposedLocation < 0)
            {
                proposedLocation = 0.0;
            }
            if (proposedLocation > self.contentSize.height - myFrame.size.height)
            {
                proposedLocation = self.contentSize.height - myFrame.size.height;
            }
            
            // commit the product of these calculations
            [self setContentOffset:CGPointMake(self.contentOffset.x, proposedLocation) animated:YES];
            
        }
    }
}

- (UIView*)findFirstResponderWithinView:(UIView*)view 
{
    // search recursively for first responder
    for ( UIView *childView in view.subviews ) 
    {
        if ( [childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder] ) return childView;
        UIView *result = [self findFirstResponderWithinView:childView];
        if ( result ) return result;
    }
    return nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// keyboard hiding

- (void) addGestureRecognizers 
{
    if (self.frameChangeOffset == 0) return;
    if (!tap_&&dismissKeyboardOnTouchOutside_)
    {
        tap_ = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)] autorelease];
        [self addGestureRecognizer:tap_];
    }
    if (!pan_&&dismissKeyboardOnScroll_)
    {
        pan_ = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)] autorelease];
        pan_.delaysTouchesBegan = NO;
        pan_.delaysTouchesEnded = NO;
        pan_.cancelsTouchesInView = NO;
        [self addGestureRecognizer:pan_];
    }
    if (!swipe_&&dismissKeyboardOnScroll_)
    {
        swipe_ = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)] autorelease];
        swipe_.delaysTouchesBegan = NO;
        swipe_.delaysTouchesEnded = NO;
        swipe_.cancelsTouchesInView = NO;
        [self addGestureRecognizer:swipe_];
    }
    
}

- (void)removeGestureRecognizers
{
    [self removeGestureRecognizer:tap_];
    [self removeGestureRecognizer:pan_];
    [self removeGestureRecognizer:swipe_];
    tap_ = nil;
    pan_ = nil;
    swipe_ = nil;
}
- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (!([gestureRecognizer state]==UIGestureRecognizerStateBegan||[gestureRecognizer state]==UIGestureRecognizerStateEnded)) return;
    if (!monitoringKeyboard_) return;
    if (!dismissKeyboardOnTouchOutside_&&(gestureRecognizer==tap_)) return;
    if (!dismissKeyboardOnScroll_&&(gestureRecognizer==swipe_||gestureRecognizer==pan_)) return;
    [self removeGestureRecognizers];
    [[self findFirstResponderWithinView:self] resignFirstResponder];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
// object lifecycle

- (void)awakeFromNib 
{
    [self setup];
}

- (id)init
{
    self = [super init];
    if (self) 
    {
        [self setup];
    }
    return self;
}
- (void)setup 
{
    if ( CGSizeEqualToSize(self.contentSize, CGSizeZero) ) 
    {
        self.contentSize = self.bounds.size;
    }
    dismissKeyboardOnScroll_ = NO;
    dismissKeyboardOnTouchOutside_ = YES;
    autoFocusScrollPosition_ = GTKeyboardHelperAutoFocusScrollPositionProportional;
    monitoringKeyboard_ = YES;
    [self beginKeyboardMonitoring];
}
- (void)dealloc 
{
    tap_ = nil;
    pan_ = nil;
    swipe_ = nil;
    if (monitoringKeyboard_) [self endKeyboardMonitoring];
    [super dealloc];
}

@end
