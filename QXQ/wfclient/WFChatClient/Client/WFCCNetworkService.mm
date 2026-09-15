//
//  WFCCNetworkService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCNetworkService.h"
#import "SRIMNetworkService.h"

const NSString *SDKVERSION = @"0.1";

NSString *kGroupInfoUpdated = @"kGroupInfoUpdated";
NSString *kGroupMemberUpdated = @"kGroupMemberUpdated";
NSString *kUserInfoUpdated = @"kUserInfoUpdated";
NSString *kFriendListUpdated = @"kFriendListUpdated";
NSString *kFriendRequestUpdated = @"kFriendRequestUpdated";
NSString *kSettingUpdated = @"kSettingUpdated";
NSString *kChannelInfoUpdated = @"kChannelInfoUpdated";
NSString *kUserOnlineStateUpdated = @"kUserOnlineStateUpdated";
NSString *kSecretChatStateUpdated = @"kSecretChatStateUpdated";
NSString *kSecretMessageStartBurning = @"kSecretMessageStartBurning";
NSString *kSecretMessageBurned = @"kSecretMessageBurned";

@interface WFCCNetworkService () <SRIMConnectionStatusDelegate, SRIMConnectToServerDelegate, SRIMTrafficDataDelegate, SRIMReceiveMessageDelegate, SRIMOnlineEventDelegate>
@property(nonatomic, assign, readwrite) ConnectionStatus currentConnectionStatus;
@property(nonatomic, assign, readwrite) long long serverDeltaTime;
@property(nonatomic, assign) BOOL tcpShortLink;
@end

@implementation WFCCNetworkService

+ (WFCCNetworkService *)sharedInstance {
    static WFCCNetworkService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[WFCCNetworkService alloc] init];
    });
    return sharedService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        SRIMNetworkService *service = [SRIMNetworkService sharedInstance];
        service.connectionStatusDelegate = self;
        service.connectToServerDelegate = self;
        service.trafficDataDelegate = self;
        service.receiveMessageDelegate = self;
        service.onlineEventDelegate = self;
        _currentConnectionStatus = (ConnectionStatus)service.currentConnectionStatus;
    }
    return self;
}

+ (void)startLog {
}

+ (void)stopLog {
}

+ (NSArray<NSString *> *)getLogFilesPath {
    return @[];
}

- (BOOL)isLogined {
    return [SRIMNetworkService sharedInstance].isLogined;
}

- (NSString *)userId {
    NSString *srimUserId = [SRIMNetworkService sharedInstance].userId;
    return srimUserId.length ? srimUserId : _userId;
}

- (void)useSM4 {
}

- (void)useAES256 {
}

- (void)useTcpShortLink {
    self.tcpShortLink = YES;
}

- (BOOL)isTcpShortLink {
    return self.tcpShortLink;
}

- (void)noUseFts {
}

- (void)setLiteMode:(BOOL)isLiteMode {
}

- (NSString *)getClientId {
    return [[SRIMNetworkService sharedInstance] getClientId];
}

- (int64_t)connect:(NSString *)userId token:(NSString *)token {
    self.userId = userId;
    return [[SRIMNetworkService sharedInstance] connect:userId token:token];
}

- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession {
    [[SRIMNetworkService sharedInstance] disconnect:disablePush clearSession:clearSession];
}

- (void)setServerAddress:(NSString *)host {
    [[SRIMNetworkService sharedInstance] setServerAddress:host port:0];
}

- (void)setDeviceToken:(NSString *)token {
    self.pushToken = token;
}

- (void)setDeviceToken:(NSString *)token pushType:(int)pushType {
    self.pushToken = token;
}

- (void)setVoipDeviceToken:(NSString *)token {
}

- (void)addReceiveMessageFilter:(id<ReceiveMessageFilter>)filter {
    [[SRIMNetworkService sharedInstance] addReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter];
}

- (void)removeReceiveMessageFilter:(id<ReceiveMessageFilter>)filter {
    [[SRIMNetworkService sharedInstance] removeReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter];
}

- (void)forceConnect:(NSUInteger)second {
    [[SRIMNetworkService sharedInstance] forceConnect:second];
}

- (void)cancelForceConnect {
    [[SRIMNetworkService sharedInstance] cancelForceConnect];
}

- (void)setBackupAddressStrategy:(int)strategy {
}

- (void)setBackupAddress:(NSString *)host port:(int)port {
}

- (void)setProtoUserAgent:(NSString *)userAgent {
}

- (void)addHttpHeader:(NSString *)header value:(NSString *)value {
}

- (void)setProxyInfo:(NSString *)host ip:(NSString *)ip port:(int)port username:(NSString *)username password:(NSString *)password {
}

- (NSString *)getProtoRevision {
    return @"srim";
}

#pragma mark - SRIM Delegates

- (void)onConnectionStatusChanged:(int)status {
    self.currentConnectionStatus = (ConnectionStatus)status;
    if ([self.connectionStatusDelegate respondsToSelector:@selector(onConnectionStatusChanged:)]) {
        [self.connectionStatusDelegate onConnectionStatusChanged:self.currentConnectionStatus];
    }
}

- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port {
    if ([self.connectToServerDelegate respondsToSelector:@selector(onConnectToServer:ip:port:)]) {
        [self.connectToServerDelegate onConnectToServer:host ip:ip port:port];
    }
}

- (void)onTrafficData:(int64_t)send recv:(int64_t)recv {
    if ([self.trafficDataDelegate respondsToSelector:@selector(onTrafficData:recv:)]) {
        [self.trafficDataDelegate onTrafficData:send recv:recv];
    }
}

- (void)onReceiveMessage:(NSArray *)messages hasMore:(BOOL)hasMore {
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onReceiveMessage:hasMore:)]) {
        [self.receiveMessageDelegate onReceiveMessage:messages hasMore:hasMore];
    }
}

- (void)onRecallMessage:(long long)messageUid {
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onRecallMessage:)]) {
        [self.receiveMessageDelegate onRecallMessage:messageUid];
    }
}

- (void)onDeleteMessage:(long long)messageUid {
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onDeleteMessage:)]) {
        [self.receiveMessageDelegate onDeleteMessage:messageUid];
    }
}

- (void)onMessageDelivered:(NSArray *)delivereds {
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onMessageDelivered:)]) {
        [self.receiveMessageDelegate onMessageDelivered:delivereds];
    }
}

- (void)onMessageReaded:(NSArray *)readeds {
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onMessageReaded:)]) {
        [self.receiveMessageDelegate onMessageReaded:readeds];
    }
}

- (void)onOnlineEvent:(NSArray<NSDictionary *> *)events {
    if ([self.onlineEventDelegate respondsToSelector:@selector(onOnlineEvent:)]) {
        [self.onlineEventDelegate onOnlineEvent:(NSArray *)events];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserOnlineStateUpdated object:events];
}

@end
