//
//  OBAPickerTextField.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAFixedHeightPickerTextField.h"
#import "Three20UI/UIViewAdditions.h"
#import "Three20UINavigator/TTGlobalNavigatorMetrics.h"


@implementation OBAFixedHeightPickerTextField

- (void)updateHeight {
    
}

- (void)doneAction {
    [self resignFirstResponder];
}

- (NSString*)labelForObject:(id)object {
    NSString * label = [super labelForObject:object];
    if ([label length] > 20) {
        label = [NSString stringWithFormat:@"%@...", [label substringToIndex:17]];
    }
    return label;
}

- (CGRect)rectForSearchResults:(BOOL)withKeyboard {
    UIView* superview = self.superviewForSearchResults;
    CGFloat y = superview.ttScreenY;
    //CGFloat visibleHeight = [self heightWithLines:1];
    CGFloat visibleHeight = 50;
    CGFloat keyboardHeight = withKeyboard ? TTKeyboardHeight() : 0;
    CGFloat tableHeight = TTScreenBounds().size.height - (y + visibleHeight + keyboardHeight);
    //CGFloat bot = self.bottom;
    CGFloat bot = 117;
    return CGRectMake(0, bot, superview.frame.size.width, tableHeight+1);
}

@end
