//
//  NSString+SHString.h
//  Shared
//
//  Created by Brian Bernberg on 2/11/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHString)
-(BOOL)isEqualToInsensitive:(NSString *)string;
// This method assumes truncating last word and word wrapping
- (CGFloat)heightForStringUsingWidth:(CGFloat)width andFont:(UIFont *)font;
- (NSString *)stringByTrimmingWhitespace;
@end

@interface NSAttributedString (Shared)

- (CGFloat) integralHeightGivenWidth:(CGFloat)width;

@end

@interface NSMutableAttributedString (Shared)

- (void) addAttributeForFont:(UIFont *)font;
- (void) addAttributeForTextColor:(UIColor *)textColor;

@end
