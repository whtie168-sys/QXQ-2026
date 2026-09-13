//
//  WOPMKDIOFZTUserInfoGenderView.m
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTUserInfoGenderView.h"
#import "AppDelegate.h"

@implementation WOPMKDIOFZTUserInfoGenderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}



- (void)setupUI {
    self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    
    _whiteV = [UIView new];
    _whiteV.translatesAutoresizingMaskIntoConstraints = NO;
    _whiteV.backgroundColor = [UIColor whiteColor];
    _whiteV.layer.cornerRadius = 20;
    [self addSubview:_whiteV];
    [NSLayoutConstraint activateConstraints:@[
        [_whiteV.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_whiteV.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_whiteV.heightAnchor constraintEqualToConstant:255],
        [_whiteV.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    UIButton *manB = [UIButton new];
    manB.translatesAutoresizingMaskIntoConstraints = NO;
    [manB setTitle:LLLLLL(@"Male") forState:UIControlStateNormal];
    manB.titleLabel.font = [UIFont systemFontOfSize:15];
    [manB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [manB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:manB];
    [NSLayoutConstraint activateConstraints:@[
        [manB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [manB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [manB.heightAnchor constraintEqualToConstant:55],
        [manB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor]
    ]];
    manB.tag = 0;
    
    UIButton *fmanB = [UIButton new];
    fmanB.translatesAutoresizingMaskIntoConstraints = NO;
    [fmanB setTitle:LLLLLL(@"Female") forState:UIControlStateNormal];
    fmanB.titleLabel.font = [UIFont systemFontOfSize:15];
    [fmanB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [fmanB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:fmanB];
    [NSLayoutConstraint activateConstraints:@[
        [fmanB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [fmanB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [fmanB.heightAnchor constraintEqualToConstant:55],
        [fmanB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55]
    ]];
    fmanB.tag = 1;

    UIButton *bmB = [UIButton new];
    bmB.translatesAutoresizingMaskIntoConstraints = NO;
    [bmB setTitle:LLLLLL(@"Other") forState:UIControlStateNormal];
    bmB.titleLabel.font = [UIFont systemFontOfSize:15];
    [bmB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [bmB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:bmB];
    [NSLayoutConstraint activateConstraints:@[
        [bmB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [bmB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [bmB.heightAnchor constraintEqualToConstant:55],
        [bmB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55*2]
    ]];
    bmB.tag = 2;

    UILabel *line = [UILabel new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor colorWithHexString:@"#F4F4F4"];
    [_whiteV addSubview:line];
    [NSLayoutConstraint activateConstraints:@[
        [line.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [line.heightAnchor constraintEqualToConstant:5],
        [line.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55*3]
    ]];

    UIButton *cancelB = [UIButton new];
    cancelB.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelB setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
    cancelB.titleLabel.font = [UIFont systemFontOfSize:15];
    [cancelB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [cancelB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:cancelB];
    [NSLayoutConstraint activateConstraints:@[
        [cancelB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [cancelB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [cancelB.heightAnchor constraintEqualToConstant:55],
        [cancelB.topAnchor constraintEqualToAnchor:line.bottomAnchor]
    ]];
    cancelB.tag = 3;
}

- (void)selectAct:(UIButton *)sender {
    if (sender.tag != 3) {
        self.gender = sender.tag;
                
        for (UIView *v in _whiteV.subviews) {
            if ([v isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton*)v;
                btn.backgroundColor = [UIColor clearColor];
            }
        }
        sender.backgroundColor = [UIColor colorWithHexString:@"#F4F4F4" alpha:0.88];
        if (_selectB) {
            _selectB(self.gender);
        }
    }

    [self dismis];
}

- (void)show:(NSInteger)gender {
    AppDelegate* dele = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [dele.window addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:dele.window.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:dele.window.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:dele.window.bottomAnchor],
        [self.topAnchor constraintEqualToAnchor:dele.window.topAnchor]
    ]];
    
    for (UIView *v in _whiteV.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton*)v;
            if (btn.tag == gender) {
                btn.backgroundColor = [UIColor colorWithHexString:@"#F4F4F4" alpha:0.88];
            }
        }
    }
    self.gender = gender;
}

- (void)dismis {
    [self removeFromSuperview];
}

@end
