//
//  UNDJKWIOKDPlaceholderTextView.m
//  WildFireChat
//
//  Created by wtb on 2026/4/18.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "UNDJKWIOKDPlaceholderTextView.h"


@interface UNDJKWIOKDPlaceholderTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation UNDJKWIOKDPlaceholderTextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self buildPlaceholderLabel];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildPlaceholderLabel {
    self.placeholderColor = RGBA(0x888888);
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.numberOfLines = 0;
    self.placeholderLabel.textColor = self.placeholderColor;
    self.placeholderLabel.userInteractionEnabled = NO;
    [self addSubview:self.placeholderLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:self];
    [self updatePlaceholderVisibility];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = [placeholder copy];
    self.placeholderLabel.text = placeholder;
    [self updatePlaceholderVisibility];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    self.placeholderLabel.textColor = placeholderColor;
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    self.placeholderLabel.font = font;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self updatePlaceholderVisibility];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self updatePlaceholderVisibility];
}

- (void)textDidChange {
    [self updatePlaceholderVisibility];
}

- (void)updatePlaceholderVisibility {
    self.placeholderLabel.hidden = self.text.length > 0;
}

@end
