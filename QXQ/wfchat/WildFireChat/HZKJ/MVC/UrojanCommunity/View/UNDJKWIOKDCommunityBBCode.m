//
//  UNDJKWIOKDCommunityBBCode.m
//  WildFireChat
//

#import "UNDJKWIOKDCommunityBBCode.h"

@interface UNDJKWIOKDCommunityBBCodeToken : NSObject

@property (nonatomic, assign) NSRange range;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign, getter=isClosing) BOOL closing;
@property (nonatomic, assign, getter=isSyntaxValid) BOOL syntaxValid;
@property (nonatomic, assign, getter=isMatched) BOOL matched;

@end

@implementation UNDJKWIOKDCommunityBBCodeToken
@end

@implementation UNDJKWIOKDCommunityBBCode

+ (NSAttributedString *)attributedStringFromString:(NSString *)string
                                          baseFont:(UIFont *)baseFont
                                         textColor:(UIColor *)textColor {
    NSString *source = string ?: @"";
    source = [[source stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]
              stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];

    NSArray<UNDJKWIOKDCommunityBBCodeToken *> *tokens = [self tokensInString:source baseFont:baseFont];
    NSMutableArray<UNDJKWIOKDCommunityBBCodeToken *> *activeTokens = [NSMutableArray array];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    NSUInteger cursor = 0;

    for (UNDJKWIOKDCommunityBBCodeToken *token in tokens) {
        if (token.range.location > cursor) {
            NSString *text = [source substringWithRange:NSMakeRange(cursor, token.range.location - cursor)];
            [self appendText:text
                    toResult:result
                activeTokens:activeTokens
                    baseFont:baseFont
                   textColor:textColor];
        }

        if (token.isMatched) {
            if (token.isClosing) {
                if (activeTokens.count > 0 &&
                    [activeTokens.lastObject.tag isEqualToString:token.tag]) {
                    [activeTokens removeLastObject];
                }
            } else {
                [activeTokens addObject:token];
            }
        } else {
            NSString *rawTag = [source substringWithRange:token.range];
            [self appendText:rawTag
                    toResult:result
                activeTokens:activeTokens
                    baseFont:baseFont
                   textColor:textColor];
        }
        cursor = NSMaxRange(token.range);
    }

    if (cursor < source.length) {
        [self appendText:[source substringFromIndex:cursor]
                toResult:result
            activeTokens:activeTokens
                baseFont:baseFont
               textColor:textColor];
    }
    return result;
}

+ (NSArray<UNDJKWIOKDCommunityBBCodeToken *> *)tokensInString:(NSString *)string
                                                    baseFont:(UIFont *)baseFont {
    static NSRegularExpression *tagExpression;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"\\[\\s*(/?)\\s*(b|i|u|s|font|size|color)\\s*(?:=\\s*([^\\]\\r\\n]+?))?\\s*\\]";
        tagExpression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                   error:nil];
    });

    NSArray<NSTextCheckingResult *> *matches =
        [tagExpression matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSMutableArray<UNDJKWIOKDCommunityBBCodeToken *> *tokens =
        [NSMutableArray arrayWithCapacity:matches.count];

    for (NSTextCheckingResult *match in matches) {
        UNDJKWIOKDCommunityBBCodeToken *token = [[UNDJKWIOKDCommunityBBCodeToken alloc] init];
        token.range = match.range;
        token.closing = [self substringForRange:[match rangeAtIndex:1] inString:string].length > 0;
        token.tag = [[self substringForRange:[match rangeAtIndex:2] inString:string] lowercaseString];
        token.value = [self normalizedValue:[self substringForRange:[match rangeAtIndex:3] inString:string]];
        token.syntaxValid = [self tokenHasValidSyntax:token baseFont:baseFont];
        [tokens addObject:token];
    }

    NSMutableArray<NSNumber *> *openingIndexes = [NSMutableArray array];
    for (NSInteger index = 0; index < tokens.count; index++) {
        UNDJKWIOKDCommunityBBCodeToken *token = tokens[index];
        if (!token.isSyntaxValid) {
            continue;
        }
        if (!token.isClosing) {
            [openingIndexes addObject:@(index)];
            continue;
        }

        NSNumber *openingIndex = openingIndexes.lastObject;
        if (!openingIndex) {
            continue;
        }
        UNDJKWIOKDCommunityBBCodeToken *openingToken = tokens[openingIndex.integerValue];
        if (![openingToken.tag isEqualToString:token.tag]) {
            continue;
        }
        openingToken.matched = YES;
        token.matched = YES;
        [openingIndexes removeLastObject];
    }
    return tokens;
}

+ (NSString *)substringForRange:(NSRange)range inString:(NSString *)string {
    if (range.location == NSNotFound || NSMaxRange(range) > string.length) {
        return @"";
    }
    return [string substringWithRange:range];
}

+ (NSString *)normalizedValue:(NSString *)value {
    NSString *result = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (result.length >= 2) {
        unichar first = [result characterAtIndex:0];
        unichar last = [result characterAtIndex:result.length - 1];
        if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
            result = [result substringWithRange:NSMakeRange(1, result.length - 2)];
            result = [result stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
    }
    return result;
}

+ (BOOL)tokenHasValidSyntax:(UNDJKWIOKDCommunityBBCodeToken *)token
                   baseFont:(UIFont *)baseFont {
    if (token.isClosing) {
        return token.value.length == 0;
    }
    if ([token.tag isEqualToString:@"b"] ||
        [token.tag isEqualToString:@"i"] ||
        [token.tag isEqualToString:@"u"] ||
        [token.tag isEqualToString:@"s"]) {
        return token.value.length == 0;
    }
    if ([token.tag isEqualToString:@"font"]) {
        return token.value.length > 0 && token.value.length <= 100 &&
            [token.value rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"[]\r\n"]].location == NSNotFound;
    }
    if ([token.tag isEqualToString:@"size"]) {
        BOOL valid = NO;
        [self pointSizeForValue:token.value baseSize:baseFont.pointSize valid:&valid];
        return valid;
    }
    if ([token.tag isEqualToString:@"color"]) {
        return [self colorForValue:token.value] != nil;
    }
    return NO;
}

+ (void)appendText:(NSString *)text
          toResult:(NSMutableAttributedString *)result
      activeTokens:(NSArray<UNDJKWIOKDCommunityBBCodeToken *> *)activeTokens
          baseFont:(UIFont *)baseFont
         textColor:(UIColor *)textColor {
    if (text.length == 0) {
        return;
    }
    NSDictionary<NSAttributedStringKey, id> *attributes =
        [self attributesForActiveTokens:activeTokens baseFont:baseFont textColor:textColor];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:attributes]];
}

+ (NSDictionary<NSAttributedStringKey, id> *)attributesForActiveTokens:
        (NSArray<UNDJKWIOKDCommunityBBCodeToken *> *)activeTokens
                                                                  baseFont:(UIFont *)baseFont
                                                                 textColor:(UIColor *)textColor {
    BOOL bold = NO;
    BOOL italic = NO;
    BOOL underline = NO;
    BOOL strikethrough = NO;
    NSString *fontValue = nil;
    CGFloat pointSize = baseFont.pointSize;
    UIColor *foregroundColor = textColor;

    for (UNDJKWIOKDCommunityBBCodeToken *token in activeTokens) {
        if ([token.tag isEqualToString:@"b"]) {
            bold = YES;
        } else if ([token.tag isEqualToString:@"i"]) {
            italic = YES;
        } else if ([token.tag isEqualToString:@"u"]) {
            underline = YES;
        } else if ([token.tag isEqualToString:@"s"]) {
            strikethrough = YES;
        } else if ([token.tag isEqualToString:@"font"]) {
            fontValue = token.value;
        } else if ([token.tag isEqualToString:@"size"]) {
            BOOL valid = NO;
            CGFloat parsedSize = [self pointSizeForValue:token.value baseSize:baseFont.pointSize valid:&valid];
            if (valid) {
                pointSize = parsedSize;
            }
        } else if ([token.tag isEqualToString:@"color"]) {
            UIColor *parsedColor = [self colorForValue:token.value];
            if (parsedColor) {
                foregroundColor = parsedColor;
            }
        }
    }

    UIFont *font = [self fontForFamilyValue:fontValue pointSize:pointSize] ?: [baseFont fontWithSize:pointSize];
    UIFontDescriptorSymbolicTraits baseTraits = baseFont.fontDescriptor.symbolicTraits;
    UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
    if (bold || (baseTraits & UIFontDescriptorTraitBold)) {
        traits |= UIFontDescriptorTraitBold;
    }
    if (italic || (baseTraits & UIFontDescriptorTraitItalic)) {
        traits |= UIFontDescriptorTraitItalic;
    }
    UIFontDescriptor *descriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
    if (descriptor) {
        UIFont *styledFont = [UIFont fontWithDescriptor:descriptor size:pointSize];
        if (styledFont) {
            font = styledFont;
        }
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineSpacing = 4;

    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: foregroundColor,
        NSParagraphStyleAttributeName: paragraphStyle
    } mutableCopy];
    if (underline) {
        attributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
    }
    if (strikethrough) {
        attributes[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
    }
    return attributes;
}

+ (UIFont *)fontForFamilyValue:(NSString *)value pointSize:(CGFloat)pointSize {
    if (value.length == 0) {
        return nil;
    }
    static NSDictionary<NSString *, NSString *> *fontAliases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fontAliases = @{
            @"sans-serif": @"HelveticaNeue",
            @"serif": @"TimesNewRomanPSMT",
            @"monospace": @"Menlo-Regular",
            @"arial": @"ArialMT",
            @"helvetica": @"HelveticaNeue",
            @"times new roman": @"TimesNewRomanPSMT",
            @"courier new": @"CourierNewPSMT",
            @"pingfang sc": @"PingFangSC-Regular",
            @"microsoft yahei": @"PingFangSC-Regular",
            @"微软雅黑": @"PingFangSC-Regular",
            @"simsun": @"SongtiSC-Regular",
            @"宋体": @"SongtiSC-Regular",
            @"simhei": @"PingFangSC-Regular",
            @"黑体": @"PingFangSC-Regular"
        };
    });

    for (NSString *rawCandidate in [value componentsSeparatedByString:@","]) {
        NSString *candidate = [self normalizedValue:rawCandidate];
        if (candidate.length == 0) {
            continue;
        }
        NSString *fontName = fontAliases[candidate.lowercaseString] ?: candidate;
        UIFont *font = [UIFont fontWithName:fontName size:pointSize];
        if (font) {
            return font;
        }
        NSArray<NSString *> *familyFonts = [UIFont fontNamesForFamilyName:candidate];
        if (familyFonts.count > 0) {
            font = [UIFont fontWithName:familyFonts.firstObject size:pointSize];
            if (font) {
                return font;
            }
        }
    }
    return nil;
}

+ (CGFloat)pointSizeForValue:(NSString *)value
                    baseSize:(CGFloat)baseSize
                       valid:(BOOL *)valid {
    NSString *normalized = [self normalizedValue:value].lowercaseString;
    NSDictionary<NSString *, NSNumber *> *keywordScales = @{
        @"xx-small": @0.65,
        @"x-small": @0.75,
        @"small": @0.85,
        @"medium": @1.0,
        @"large": @1.2,
        @"x-large": @1.5,
        @"xx-large": @2.0
    };
    NSNumber *scale = keywordScales[normalized];
    if (scale) {
        if (valid) {
            *valid = YES;
        }
        return MIN(MAX(baseSize * scale.doubleValue, 9), 40);
    }

    NSArray<NSNumber *> *legacySizes = @[@10, @12, @14, @16, @20, @24, @30];
    NSInteger legacyValue = normalized.integerValue;
    if (normalized.length == 1 && legacyValue >= 1 && legacyValue <= 7) {
        if (valid) {
            *valid = YES;
        }
        return legacySizes[legacyValue - 1].doubleValue;
    }

    CGFloat multiplier = 1;
    NSString *numberString = normalized;
    if ([normalized hasSuffix:@"px"] || [normalized hasSuffix:@"pt"]) {
        numberString = [normalized substringToIndex:normalized.length - 2];
    } else if ([normalized hasSuffix:@"em"]) {
        numberString = [normalized substringToIndex:normalized.length - 2];
        multiplier = baseSize;
    } else if ([normalized hasSuffix:@"%"]) {
        numberString = [normalized substringToIndex:normalized.length - 1];
        multiplier = baseSize / 100.0;
    }

    double number = 0;
    BOOL hasNumber = [self scanDoubleFromString:numberString value:&number];
    CGFloat pointSize = number * multiplier;
    BOOL isValid = hasNumber && pointSize > 0;
    if (valid) {
        *valid = isValid;
    }
    return isValid ? MIN(MAX(pointSize, 9), 40) : baseSize;
}

+ (UIColor *)colorForValue:(NSString *)value {
    NSString *normalized = [self normalizedValue:value].lowercaseString;
    static NSDictionary<NSString *, NSString *> *namedColors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        namedColors = @{
            @"black": @"#000000", @"silver": @"#c0c0c0", @"gray": @"#808080",
            @"white": @"#ffffff", @"maroon": @"#800000", @"red": @"#ff0000",
            @"purple": @"#800080", @"fuchsia": @"#ff00ff", @"green": @"#008000",
            @"lime": @"#00ff00", @"olive": @"#808000", @"yellow": @"#ffff00",
            @"navy": @"#000080", @"blue": @"#0000ff", @"teal": @"#008080",
            @"aqua": @"#00ffff", @"orange": @"#ffa500"
        };
    });
    normalized = namedColors[normalized] ?: normalized;

    if ([normalized hasPrefix:@"#"]) {
        NSString *hex = [normalized substringFromIndex:1];
        if (hex.length == 3 || hex.length == 4) {
            NSMutableString *expanded = [NSMutableString stringWithCapacity:hex.length * 2];
            for (NSUInteger index = 0; index < hex.length; index++) {
                unichar character = [hex characterAtIndex:index];
                [expanded appendFormat:@"%C%C", character, character];
            }
            hex = expanded;
        }
        if (hex.length != 6 && hex.length != 8) {
            return nil;
        }
        unsigned long long rgba = 0;
        NSScanner *scanner = [NSScanner scannerWithString:hex];
        if (![scanner scanHexLongLong:&rgba] || !scanner.isAtEnd) {
            return nil;
        }
        CGFloat red = ((rgba >> (hex.length == 8 ? 24 : 16)) & 0xff) / 255.0;
        CGFloat green = ((rgba >> (hex.length == 8 ? 16 : 8)) & 0xff) / 255.0;
        CGFloat blue = ((rgba >> (hex.length == 8 ? 8 : 0)) & 0xff) / 255.0;
        CGFloat alpha = hex.length == 8 ? (rgba & 0xff) / 255.0 : 1;
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }

    BOOL isRGBA = [normalized hasPrefix:@"rgba("] && [normalized hasSuffix:@")"];
    BOOL isRGB = [normalized hasPrefix:@"rgb("] && [normalized hasSuffix:@")"];
    if (!isRGB && !isRGBA) {
        return nil;
    }
    NSUInteger prefixLength = isRGBA ? 5 : 4;
    NSString *componentString =
        [normalized substringWithRange:NSMakeRange(prefixLength, normalized.length - prefixLength - 1)];
    NSArray<NSString *> *components = [componentString componentsSeparatedByString:@","];
    if (components.count != (isRGBA ? 4 : 3)) {
        return nil;
    }

    CGFloat rgbaComponents[4] = {0, 0, 0, 1};
    for (NSUInteger index = 0; index < 3; index++) {
        NSString *component = [components[index] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        BOOL percentage = [component hasSuffix:@"%"];
        if (percentage) {
            component = [component substringToIndex:component.length - 1];
        }
        double number = 0;
        if (![self scanDoubleFromString:component value:&number]) {
            return nil;
        }
        number = percentage ? number * 2.55 : number;
        if (number < 0 || number > 255) {
            return nil;
        }
        rgbaComponents[index] = number / 255.0;
    }
    if (isRGBA) {
        double alpha = 0;
        NSString *component = [components[3] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (![self scanDoubleFromString:component value:&alpha] || alpha < 0 || alpha > 1) {
            return nil;
        }
        rgbaComponents[3] = alpha;
    }
    return [UIColor colorWithRed:rgbaComponents[0]
                           green:rgbaComponents[1]
                            blue:rgbaComponents[2]
                           alpha:rgbaComponents[3]];
}

+ (BOOL)scanDoubleFromString:(NSString *)string value:(double *)value {
    NSString *normalized = [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (normalized.length == 0) {
        return NO;
    }
    NSScanner *scanner = [NSScanner scannerWithString:normalized];
    double number = 0;
    if (![scanner scanDouble:&number] || !scanner.isAtEnd) {
        return NO;
    }
    if (value) {
        *value = number;
    }
    return YES;
}

@end
