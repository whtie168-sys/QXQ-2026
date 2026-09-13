//
//  VoiceCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "SMIOUEJMediaMessageCell.h"

#define kVoiceMessageStartPlaying @"kVoiceMessageStartPlaying"
#define kVoiceMessagePlayStoped @"kVoiceMessagePlayStoped"


@interface SMIOUEJVoiceCell : SMIOUEJMediaMessageCell
@property (nonatomic, strong)UIImageView *tzboeuVoiceBtn;
@property (nonatomic, strong)UILabel *tzboeuDurationLabel;
@property (nonatomic, strong)UIView *tzboeuUnplayedView;
@end
