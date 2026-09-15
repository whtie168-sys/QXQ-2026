//
//  GroupInfoViewController.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "DUVOHJNGroupInfoVC.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "AIOIUEHConfigManager.h"
#import "AIOIUEHImage.h"
#import "AIOIUEHMessageListVC.h"
#import "UIView+Toast.h"

@interface DUVOHJNGroupInfoVC ()
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@property (nonatomic, strong)UIImageView *groupProtraitView;
@property (nonatomic, strong)UILabel *grouptzboeuNameLabel;
@property (nonatomic, strong)NSArray<WFCCGroupMember *> *members;
@property (nonatomic, strong)UIButton *btn;
@property (nonatomic, assign)BOOL isJoined;
@end

@implementation DUVOHJNGroupInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray<WFCCGroupInfo *> *groupInfoList = note.userInfo[@"groupInfoList"];
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if ([ws.groupId isEqualToString:groupInfo.target]) {
                ws.groupInfo = groupInfo;
                break;
            }
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            ws.members = [[WFCCGroupDB sharedManager] getGroupMembers:ws.groupId];
        }
        
    }];
    
    self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.groupId refresh:NO];
    self.view.backgroundColor = [UIColor whiteColor];
    self.members = [[WFCCGroupDB sharedManager] getGroupMembers:self.groupId];
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if(groupInfo) {
        if(groupInfo.portrait.length) {
            [self.groupProtraitView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                               context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        }
        
        self.grouptzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%ld)", groupInfo.displayName, groupInfo.memberCount];
    }
}

- (void)setMembers:(NSArray<WFCCGroupMember *> *)members {
    _members = members;
    __block BOOL isContainMe = NO;
    [members enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            *stop = YES;
            isContainMe = YES;
        }
    }];
    
    if(!isContainMe) {
        __weak typeof(self)ws = self;
        [[AIOIUEHConfigManager globalManager].appServiceProvider getGroupMembersForPortrait:self.groupId success:^(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers) {
            [ws onGetGroupMember:groupMembers];
        } error:^(int error_code) {
            NSLog(@"error");
        }];
    }
    self.isJoined = isContainMe;
}

- (void)onGetGroupMember:(NSArray<NSDictionary<NSString *, NSString *> *> *)groupMembers {
    if(!self.groupInfo.portrait.length) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *imagePath = [WFCCUtilities getGroupGridPortrait:self.groupId memberPortraits:groupMembers width:50 defaultUserPortrait:^UIImage *(NSString *userId) {
                return [AIOIUEHImage imageNamed:@"groupIcon"];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.groupProtraitView.image = [UIImage imageWithContentsOfFile:imagePath];
            });
        });   
    }
}

- (void)setIsJoined:(BOOL)isJoined {
    _isJoined = isJoined;
    if (isJoined) {
        [self.btn setTitle:WFCString(@"StartChat") forState:UIControlStateNormal];
    } else {
        [self.btn setTitle:WFCString(@"StartChat") forState:UIControlStateNormal];
    }
}

- (void)onButtonPressed:(id)sender {
    if (self.isJoined) {
        AIOIUEHMessageListVC *mvc = [[AIOIUEHMessageListVC alloc] init];
        mvc.conversation = [[WFCCConversation alloc] init];
        mvc.conversation.type = Group_Type;
        mvc.conversation.target = self.groupId;
        mvc.conversation.line = 0;
        
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    } else {
        __weak typeof(self) ws = self;
        NSString *memberExtra = nil;
//        if(self.sourceType) {
//            NSDictionary *extraDict;
//            if(self.sourceTargetId.length) {
//                extraDict = @{@"s"/*source*/:@{@"t"/*type*/:@(self.sourceType), @"i"/*targetId*/:self.sourceTargetId}};
//            } else {
//                extraDict = @{@"s"/*source*/:@{@"t"/*type*/:@(self.sourceType)}};
//            }
//            
//            NSData *extraData = [NSJSONSerialization dataWithJSONObject:extraDict
//                                                                                   options:kNilOptions
//                                                                                     error:nil];
//            memberExtra = [[NSString alloc] initWithData:extraData encoding:NSUTF8StringEncoding];
//
//        }
        [[WFCCIMService sharedWFCIMService] addMembers:@[[WFCCNetworkService sharedInstance].userId] toGroup:self.groupId memberExtra:memberExtra notifyLines:@[@(0)] notifyContent:nil success:^{
            [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:YES];
            ws.isJoined = YES;
            [ws onButtonPressed:nil];
        } error:^(int error_code) {
            [self.view makeToast:@"无权操作..."];
        }];
    }
}

- (UIButton *)btn {
    if (!_btn) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _btn = [[UIButton alloc] initWithFrame:CGRectMake(width/2 - 80, 300.0, 160, 44)];
        _btn.layer.masksToBounds = YES;
        _btn.layer.cornerRadius = 8.f;
        [self.view addSubview:_btn];
        [_btn setBackgroundColor:RGBCOLOR(92, 226, 83)];
        [_btn addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return _btn;
}

- (UILabel *)grouptzboeuNameLabel {
    if (!_grouptzboeuNameLabel) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _grouptzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/2 - 100, 220, 200, 24)];
        _grouptzboeuNameLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_grouptzboeuNameLabel];
    }
    return _grouptzboeuNameLabel;
}

- (UIImageView *)groupProtraitView {
    if (!_groupProtraitView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _groupProtraitView = [[UIImageView alloc] initWithFrame:CGRectMake(width/2 - 40.0, 120, 80.0, 80.0)];
        _groupProtraitView.layer.cornerRadius = 40.0;
        [self.view addSubview:_groupProtraitView];
    }
    return _groupProtraitView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
