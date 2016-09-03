//
//  NSString+SHString.m
//  Shared
//
//  Created by Brian Bernberg on 2/11/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "NSString+SHString.h"

#define FULL_RANGE NSMakeRange(0, [self length])

@implementation NSString (SHString)

-(BOOL)isEqualToInsensitive:(NSString *)string {
    NSString *compString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *selfTrimmed = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return ([selfTrimmed localizedCaseInsensitiveCompare:compString] == NSOrderedSame);
}

- (CGFloat)heightForStringUsingWidth:(CGFloat)width andFont:(UIFont *)font {
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGRect rect = [self boundingRectWithSize:CGSizeMake(width, 9999.f)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                                  attributes:@{NSFontAttributeName : font,
                                               NSParagraphStyleAttributeName : paragraphStyle}
                                     context:nil];

    return ceil(rect.size.height);
}

- (NSString *)stringByTrimmingWhitespace {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
@end

@implementation NSAttributedString (GameChangerMedia)

- (CGSize) sizeConstrainedToSize:(CGSize)size {
  return [self boundingRectWithSize: size
                            options: NSStringDrawingUsesLineFragmentOrigin
                            context: nil].size;
}

- (CGSize) sizeGivenWidth:(CGFloat)width {
  return [self sizeConstrainedToSize: CGSizeMake(width, CGFLOAT_MAX)];
}

- (CGSize)integralSizeGivenSize:(CGSize)size {
  CGSize ret = [self sizeConstrainedToSize:size];
  ret.width = ceilf(ret.width);
  ret.height = ceilf(ret.height);
  return ret;
}

- (CGFloat) integralHeightGivenWidth:(CGFloat)width {
  return ceilf([self sizeGivenWidth: width].height);
}

@end

@implementation NSMutableAttributedString (Shared)

- (void) addAttributeForFont: (UIFont*) font {
  [self addAttributeForFont: font range: FULL_RANGE];
}

- (void) addAttributeForFont: (UIFont*) font range: (NSRange) range {
  [self addAttribute: NSFontAttributeName value: font range: range];
}

- (void) addAttributeForTextColor: (UIColor*) textColor range:(NSRange)range {
  [self addAttribute: NSForegroundColorAttributeName value: textColor range: range];
}

- (void) addAttributeForTextColor: (UIColor*) textColor {
  [self addAttributeForTextColor: textColor range: FULL_RANGE];
}

@end
