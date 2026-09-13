//
//  UNDJKWIOKDCommunityBBCode.h
//  WildFireChat
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Renders the display-only BBCode subset used by community articles.
@interface UNDJKWIOKDCommunityBBCode : NSObject

+ (NSAttributedString *)attributedStringFromString:(nullable NSString *)string
                                          baseFont:(UIFont *)baseFont
                                         textColor:(UIColor *)textColor;

@end

NS_ASSUME_NONNULL_END
