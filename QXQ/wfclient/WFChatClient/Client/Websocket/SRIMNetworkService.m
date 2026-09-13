//
//  SRIMNetworkService.m
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "SRIMNetworkService.h"
#import "SRWebSocket.h"
#import "WFCCIMService.h"
#import "WFCCMessageDB.h"
#import "WFCCTextMessageContent.h"
#import "WFCCMessageContentFactory.h"
#import "WFCCNetworkService.h"
#import "WFCCConversationDB.h"
#import "WFCCGroupDB.h"
#import "WFCCImageMessageContent.h"
#import "WFCCVideoMessageContent.h"
#import "WFCCLocationMessageContent.h"
#import "WFCCFileMessageContent.h"
#import "WFCCUnknownMessageContent.h"
#import "WFCCStickerMessageContent.h"
#import "WFCCRecallMessageContent.h"
#import "WFCCCreateGroupNotificationContent.h"
#import "WFCCAddGroupeMemberNotificationContent.h"
#import "WFCCKickoffGroupMemberVisibleNotificationContent.h"
#import "WFCCQuitGroupVisibleNotificationContent.h"
#import "WFCCDismissGroupNotificationContent.h"
#import "WFCCTransferGroupOwnerNotificationContent.h"
#import "WFCCChangeGroupNameNotificationContent.h"
#import "WFCCModifyGroupAliasNotificationContent.h"
#import "WFCCChangeGroupPortraitNotificationContent.h"
#import "WFCCGroupMuteNotificationContent.h"
#import "WFCCGroupJoinTypeNotificationContent.h"
#import "WFCCGroupPrivateChatNotificationContent.h"
#import "WFCCGroupSetManagerNotificationContent.h"
#import "WFCCGroupMemberMuteNotificationContent.h"
#import "WFCCGroupMemberAllowNotificationContent.h"
#import "WFCCModifyGroupExtraNotificationContent.h"
#import "WFCCModifyGroupMemberExtraNotificationContent.h"
#import "WFCCGroupSettingsNotificationContent.h"
#import "WFCCAnnouncementMessageContent.h"
#import "WFCCCardMessageContent.h"
#import "SnowflakeIdGenerator.h"
#import "WFCCLinkMessageContent.h"
#import "WFCCSoundMessageContent.h"
#import "SRIMZlibDictionary.h"

#import "JSONHelper.h"
#import "Common.h"
#import <zlib.h>

static NSString * const kSRIMClientIdKey = @"srim.client.id";
static NSUInteger const kSRIMLogChunkLength = 800;
static NSUInteger const kSRIMZlibOutputChunkLength = 64 * 1024;

static inline void removePendingNotifyMessageByUid(NSMutableArray<WFCCMessage *> *messages, long long messageUid) {
    if (messages.count == 0 || messageUid <= 0) {
        return;
    }
    NSIndexSet *indexes = [messages indexesOfObjectsPassingTest:^BOOL(WFCCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.messageUid == messageUid;
    }];
    if (indexes.count > 0) {
        [messages removeObjectsAtIndexes:indexes];
    }
}


typedef NS_ENUM(NSInteger, SRIMConnectionStatus) {
    SRIMConnectionStatusTimeInconsistent   = -9,
    SRIMConnectionStatusNotLicensed        = -8,
    SRIMConnectionStatusKickedoff          = -7,
    SRIMConnectionStatusSecretKeyMismatch  = -6,
    SRIMConnectionStatusTokenIncorrect     = -5,
    SRIMConnectionStatusServerDown         = -4,
    SRIMConnectionStatusRejected           = -3,
    SRIMConnectionStatusLogout             = -2,
    SRIMConnectionStatusUnconnected        = -1,
    SRIMConnectionStatusConnecting         = 0,
    SRIMConnectionStatusConnected          = 1,
    SRIMConnectionStatusReceiving          = 2,
    SRIMConnectionStatusActiveDisconnect   = 3, //主动断开
};

@interface SRIMNetworkService() <SRWebSocketDelegate>
@property(nonatomic, strong) SRWebSocket *socket;
@property(nonatomic, copy)   NSString *host;
@property(nonatomic, assign) NSInteger port;
@property(nonatomic, copy)   NSString *token;
@property(nonatomic, copy)   NSString *userId;
//@property(nonatomic, assign) SRIMConnectionStatus currentConnectionStatus;
@property(nonatomic, assign) BOOL logined;
@property(nonatomic, strong) NSTimer *heartbeatTimer;
@property(nonatomic, strong) NSMutableArray<id<SRIMReceiveMessageFilter>> *filters;
@property(nonatomic, assign) int64_t bytesSend;
@property(nonatomic, assign) int64_t bytesRecv;

@property (nonatomic, strong) dispatch_queue_t msgProcessQueue;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingMessages;
@property (nonatomic, assign) BOOL batchScheduled;

@property (nonatomic, assign) long long loadLastId;
@property (nonatomic, assign) BOOL remoteMessageSyncInProgress;
@property (nonatomic, assign) long long remoteMessageSyncMaxServerTime;
@end

@implementation SRIMNetworkService

- (void)logLargeMessage:(NSString *)logText prefix:(NSString *)prefix {
    if (logText.length == 0) {
        NSLog(@"%@", prefix ?: @"");
        return;
    }

    NSUInteger length = logText.length;
    for (NSUInteger location = 0; location < length; location += kSRIMLogChunkLength) {
        NSUInteger chunkLength = MIN(kSRIMLogChunkLength, length - location);
        NSString *chunk = [logText substringWithRange:NSMakeRange(location, chunkLength)];
        NSLog(@"%@[%lu]: %@", prefix ?: @"", (unsigned long)(location / kSRIMLogChunkLength), chunk);
    }
}

- (NSString *)webSocketURLStringWithZlibFlag:(NSString *)urlString {
    if (urlString.length == 0 || [urlString rangeOfString:@"isZlib="].location != NSNotFound) {
        return urlString;
    }
    NSString *separator = [urlString rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&";
    return [urlString stringByAppendingFormat:@"%@isZlib=1", separator];
}

- (NSData *)zlibDictionaryData {
    return SRIMZlibDictionaryData();
}

- (BOOL)isPlainJSONPayloadData:(NSData *)data {
    if (data.length == 0) {
        return NO;
    }
    const uint8_t *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        uint8_t c = bytes[i];
        if (c == ' ' || c == '\n' || c == '\r' || c == '\t') {
            continue;
        }
        return c == '{' || c == '[';
    }
    return NO;
}

- (NSData *)inflateZlibPayloadData:(NSData *)data {
    if (data.length == 0) {
        return nil;
    }
    const uint8_t *bytes = data.bytes;
    if (bytes[0] != 0x78) {
        return nil;
    }

    NSLog(@"SRIMWS received zlib payload, compressed bytes: %lu", (unsigned long)data.length);

    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    stream.next_in = (Bytef *)data.bytes;
    stream.avail_in = (uInt)data.length;

    int status = inflateInit(&stream);
    if (status != Z_OK) {
        return nil;
    }

    NSMutableData *output = [NSMutableData dataWithLength:MAX(data.length * 4, kSRIMZlibOutputChunkLength)];
    NSData *dictionary = [self zlibDictionaryData];

    do {
        if (stream.total_out >= output.length) {
            output.length += kSRIMZlibOutputChunkLength;
        }
        stream.next_out = (Bytef *)output.mutableBytes + stream.total_out;
        stream.avail_out = (uInt)(output.length - stream.total_out);

        status = inflate(&stream, Z_NO_FLUSH);
        if (status == Z_NEED_DICT && dictionary.length > 0) {
            status = inflateSetDictionary(&stream, dictionary.bytes, (uInt)dictionary.length);
            if (status == Z_OK) {
                status = inflate(&stream, Z_NO_FLUSH);
            }
        }
    } while (status == Z_OK);

    if (status != Z_STREAM_END) {
        NSLog(@"SRIMWS inflate failed status: %d", status);
        inflateEnd(&stream);
        return nil;
    }

    output.length = stream.total_out;
    inflateEnd(&stream);
    NSLog(@"SRIMWS inflate success, compressed bytes: %lu, decompressed bytes: %lu",
          (unsigned long)data.length,
          (unsigned long)output.length);
    return output;
}

- (NSData *)payloadDataFromWebSocketMessage:(id)message {
    if ([message isKindOfClass:NSData.class]) {
        return message;
    } else if ([message isKindOfClass:NSString.class]) {
        return [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        return [[message description] dataUsingEncoding:NSUTF8StringEncoding];
    }
}

- (NSData *)decodedPayloadDataFromPayloadData:(NSData *)data {
    if ([self isPlainJSONPayloadData:data]) {
        return data;
    }
    NSData *inflated = [self inflateZlibPayloadData:data];
    return inflated ?: data;
}

- (void)refreshGroupInfoViaGroupService:(NSString *)groupId {
    Class groupServiceClass = NSClassFromString(@"GroupService");
    SEL sharedSelector = NSSelectorFromString(@"shared");
    SEL getGroupInfoSelector = NSSelectorFromString(@"getGroupInfo:refresh:success:error:");
    if (!groupServiceClass || ![groupServiceClass respondsToSelector:sharedSelector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id groupService = [groupServiceClass performSelector:sharedSelector];
#pragma clang diagnostic pop
    if (!groupService || ![groupService respondsToSelector:getGroupInfoSelector]) {
        return;
    }

    void (^successBlock)(id) = ^(id groupInfo) {
    };
    void (^errorBlock)(int, NSString *) = ^(int code, NSString *msg) {
    };

    NSMethodSignature *signature = [groupService methodSignatureForSelector:getGroupInfoSelector];
    if (!signature) {
        return;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = groupService;
    invocation.selector = getGroupInfoSelector;
    BOOL refresh = YES;
    [invocation setArgument:&groupId atIndex:2];
    [invocation setArgument:&refresh atIndex:3];
    [invocation setArgument:&successBlock atIndex:4];
    [invocation setArgument:&errorBlock atIndex:5];
    [invocation invoke];
}

+ (instancetype)sharedInstance {
    static SRIMNetworkService *ins;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ ins=[self new];});
    return ins;
}

- (instancetype)init {
    if (self=[super init]) {
        _filters=[NSMutableArray array];
//        _currentConnectionStatus=SRIMConnectionStatusUnconnected;
        
        _msgProcessQueue = dispatch_queue_create("com.wildfirechat.msgProcessQueue", DISPATCH_QUEUE_SERIAL);
        _pendingMessages = [NSMutableArray array];
        _batchScheduled = NO;
    }
    return self;
}

#pragma mark - Remote message offset

- (NSString *)remoteMessageOffsetKey {
    NSString *userId = self.userId;
    if (userId.length == 0) {
        userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    }
    if (userId.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"lastLoadRemoteMessageTs_%@", userId];
}

- (void)persistRemoteMessageOffset:(long long)serverTime {
    if (serverTime <= 0) {
        return;
    }

    @synchronized (self) {
        NSString *key = [self remoteMessageOffsetKey];
        if (key.length == 0) {
            return;
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        long long currentOffset = [[defaults objectForKey:key] longLongValue];
        if (serverTime > currentOffset) {
            [defaults setObject:@(serverTime) forKey:key];
        }
    }
}

- (void)beginRemoteMessageSync {
    @synchronized (self) {
        if (self.remoteMessageSyncInProgress) {
            return;
        }
        self.remoteMessageSyncInProgress = YES;
        self.remoteMessageSyncMaxServerTime = 0;
    }
}

- (void)cancelRemoteMessageSync {
    @synchronized (self) {
        self.remoteMessageSyncInProgress = NO;
        self.remoteMessageSyncMaxServerTime = 0;
    }
}

- (void)recordRemoteMessageServerTime:(long long)serverTime {
    if (serverTime <= 0) {
        return;
    }

    @synchronized (self) {
        if (self.remoteMessageSyncInProgress) {
            self.remoteMessageSyncMaxServerTime = MAX(self.remoteMessageSyncMaxServerTime, serverTime);
            return;
        }
    }
    [self persistRemoteMessageOffset:serverTime];
}

- (void)completeRemoteMessageSync {
    long long maxServerTime = 0;
    @synchronized (self) {
        if (!self.remoteMessageSyncInProgress) {
            return;
        }
        maxServerTime = self.remoteMessageSyncMaxServerTime;
        self.remoteMessageSyncInProgress = NO;
        self.remoteMessageSyncMaxServerTime = 0;
    }
    [self persistRemoteMessageOffset:maxServerTime];
}

- (void)setServerAddress:(NSString *)host port:(NSInteger)port {
    self.host=host;
    self.port=port;
}

- (NSString *)getClientId {
    NSString *cid = [[NSUserDefaults standardUserDefaults] stringForKey:kSRIMClientIdKey];
    if (!cid) {
        cid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:cid forKey:kSRIMClientIdKey];
    }
    return cid;
}

- (int64_t)connect:(NSString *)userId token:(NSString *)token {
    NSLog(@"开始websocket连接1111 %@",userId);
    [self cancelRemoteMessageSync];
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }
    
    self.userId = userId;
    self.token = token;
    self.logined = YES;
    [self changeStatus:SRIMConnectionStatusConnecting];
//    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"wss://%@@%ld/ws?uid=%@&token=%@&cid=%@", self.host,(long)self.port,userId,token,[self getClientId]]];
    NSString *urlString = [self webSocketURLStringWithZlibFlag:token];
    NSURL *url=[NSURL URLWithString:urlString];
    self.socket = [[SRWebSocket alloc] initWithURL:url];
    self.socket.delegate = self;
    [self.socket open];
    
    NSLog(@"开始websocket连接 %@",urlString);
    return 0;
}

- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession {
    [self cancelRemoteMessageSync];
    [self stopHeartbeat];
    [self.socket close];
    self.socket = nil;
    if (clearSession) {
        [self changeStatus:SRIMConnectionStatusActiveDisconnect];
    } else {
        self.logined = NO;
        [self changeStatus:SRIMConnectionStatusLogout];
    }
}

- (void)forceConnect:(NSUInteger)second { // 简化：立即心跳并在 N 秒后断开
    if (self.socket.readyState != SR_OPEN) return;
    [self sendJSON:@{ @"type":@"ping" }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cancelForceConnect];
    });
}

- (void)cancelForceConnect { /* no-op demo */ }

- (void)addReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter {
    if (filter) [self.filters addObject:filter];
}

- (void)removeReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter {
    if (!filter) return;
    [self.filters removeObject:filter];
}

- (void)sendJSON:(NSDictionary *)json {
    if (!json) return;
    if (self.socket.readyState != SR_OPEN) return;
    NSError *e=nil;
    NSData *data=[NSJSONSerialization dataWithJSONObject:json options:0 error:&e];
    if (!e) {
        self.bytesSend += data.length;
        [self.socket send:data];
        if ([self.trafficDataDelegate respondsToSelector:@selector(onTrafficData:recv:)]) {
            [self.trafficDataDelegate onTrafficData:self.bytesSend recv:self.bytesRecv];
        }
    }
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- webSocketDidOpen");
    // 先冻结游标，再发布“已连接”状态，避免补拉请求发出前的实时消息越过历史消息。
    [self beginRemoteMessageSync];
    [self changeStatus:SRIMConnectionStatusConnected];
    if ([self.connectToServerDelegate respondsToSelector:@selector(onConnectToServer:ip:port:)]) {
        [self.connectToServerDelegate onConnectToServer:self.host ip:@"" port:(int)self.port];
    }
    [self startHeartbeat];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- WebSocket fail: %@",error.debugDescription);

    [self stopHeartbeat];

    if (webSocket == self.socket) {
        [self cancelRemoteMessageSync];
        self.socket.delegate = nil;
        self.socket = nil;
        [self changeStatus:SRIMConnectionStatusUnconnected];
        [self retryConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- WebSocket closed");
    [self stopHeartbeat];

    //重新登录
    if (code == 1008) {
        [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
        return;
    }
    if (webSocket == self.socket) {
        [self cancelRemoteMessageSync];
        self.socket.delegate = nil;
        self.socket = nil;
        [self changeStatus:SRIMConnectionStatusUnconnected];
        [self retryConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"WebSocket received pong");
}

#pragma mark - Heartbeat & Reconnect
- (void)startHeartbeat {
    [self stopHeartbeat];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(ping) userInfo:nil repeats:YES];
}

- (void)stopHeartbeat {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer=nil;
}

- (void)ping {
    [self.socket sendPing:nil error:NULL];
//    [self sendJSON:@{ @"type":@"ping" }];
}

- (void)retryConnect {
    if (!self.logined) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.socket.readyState != SR_OPEN) {
            [self connect:self.userId token:self.token];
        }
    });
}

#pragma mark - helper
- (void)changeStatus:(SRIMConnectionStatus)status {
    _currentConnectionStatus = status;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kConnectionStatusChanged object:@(self.currentConnectionStatus)];
    if ([self.connectionStatusDelegate respondsToSelector:@selector(onConnectionStatusChanged:)]) {
        [self.connectionStatusDelegate onConnectionStatusChanged:status];
    }
}


/*
 {
   "type": 0, // 消息类型 0 消息(保证一定收到且有记录)  2 加好友/群请求(不保证一定收到)
   "to": //接收人的Code 登陆时会返回
   "messages": [] //消息体 只有 type = 0 时才有
   "request": {} //请求消息，只有 type = 2
 }
 //消息体结构
 {
 "from": "user123",             // 发送人 ID（字符串）
 "to": "user456",               // 接收人 ID（字符串）
 "uid": "msg-001",              // 消息的唯一 ID（字符串）
 "type": 0,                     // 消息类型（int）：0=文本，1=图片，2=音频，3=文件
 "message": "Hello, world!",    // 消息文本内容（type 为 0 时使用）
 "mimeType": "text/plain",      // 文件的 MIME 类型（仅在发送文件时使用）
 "remoteUrl": "https://example.com/file.png", // 文件或媒体的远程地址
 "sendTime": 1716972000000,     // 客户端发送时间（时间戳，单位：毫秒）
 "extra": "{\"font\":\"bold\"}",// 扩展字段，通常为 JSON 字符串格式（可自定义扩展信息）
 "dropTime": 0,                 // 消息丢弃时间（默认为 0，如未设置）
 "direction": 0                 // 消息方向：0=私聊 1=群聊
 }
 //请求消息
 {
 "from": "user123", // 发送人 ID（字符串）
 "to": "user456", // 接收人 ID（字符串）
 "type": 0,  // 0 好友 1 群组
 "reason": "加个好友，一起玩游戏" //备注
 }
 
 */
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *rawData = [self payloadDataFromWebSocketMessage:message];
    NSData *data = [self decodedPayloadDataFromPayloadData:rawData];
    self.bytesRecv += rawData.length;
    if ([self.trafficDataDelegate respondsToSelector:@selector(onTrafficData:recv:)]) {
        [self.trafficDataDelegate onTrafficData:self.bytesSend recv:self.bytesRecv];
    }
    
    // 2) 解析 JSON 并将原始消息 dict 入队（尽量快，阻塞越短越好）
    NSDictionary *json = nil;
    @try {
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    } @catch (NSException *ex) {
        json = nil;
    }
    if (![json isKindOfClass:[NSDictionary class]]) {
        return;
    }

    // 只把原始消息对象入队，真正的解析/存库在后台串行队列完成
    NSArray *jsonmessages = json[@"messages"];
    NSString *messageLog = [NSString stringWithFormat:@"******************** didReceiveMessage count: %lu, payload: %@",
                            (unsigned long)jsonmessages.count,
                            json];
    [self logLargeMessage:messageLog prefix:@"SRIMWS "];

    if (![jsonmessages isKindOfClass:[NSArray class]] || jsonmessages.count == 0) {
        // 处理 type==2 之类的控制消息也可以在这里单独处理（下面还有分支）
        NSString *type = [NSString stringWithFormat:@"%@", json[@"type"] ?: @""];
        if ([type intValue] == 2) {
            // 如果是 type==2 控制类消息（加好友/群通知），仍然在这里做快速处理并回到主线程发送通知
            NSDictionary *request = json[@"request"];
            if ([request isKindOfClass:[NSDictionary class]]) {
                int contentType = [request[@"type"] intValue];
                if (contentType == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"kTabBarClearBadgeNotification" object:@"1"];
                    });
                } else if (contentType == 1) {
                    // 群邀请之类（按你的原逻辑）
                    dispatch_async(self.msgProcessQueue, ^{
                        WFCCMessage *ret = [[WFCCMessage alloc] init];
                        ret.fromUser = @"group_message";
                        ret.serverTime = [[NSDate date] timeIntervalSince1970]*1000;
                        if (request[@"uid"]) {
                            id uidValue = request[@"uid"];
                            ret.messageUid = [uidValue longLongValue];
                        } else {
                            ret.messageUid = [[SnowflakeIdGenerator sharedGenerator] nextId];
                        }
                        ret.status = Message_Status_Sent;
                        ret.direction = MessageDirection_Receive;
                        WFCCConversation *conversation = [[WFCCConversation alloc] init];
                        conversation.type = Single_Type;
                        conversation.line = 0;
                        conversation.target = @"group_message";
                        ret.conversation = conversation;
                        WFCCTextMessageContent *content = [[WFCCTextMessageContent alloc] init];
                        content.text = [NSString stringWithFormat:@"%@邀请您加入群聊",[[WFCCUserDB sharedManager] getUserInfo:request[@"from"]].displayName];
                        ret.content = content;
                        [[WFCCMessageDB sharedManager] storeMessageAndUpdateConversation:ret];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
                        });
                    });
                }
            }
        }
        return;
    }
    
    // 把 messages 批量入队（仅把原始 dict 入队，快速返回）
    @synchronized (self.pendingMessages) {
        for (id obj in jsonmessages) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *cleanDict = [self cleanNullValue:obj]; // 复用你的 cleanNullValue
                [self.pendingMessages addObject:cleanDict];
            }
        }
    }
    
    // 调度批处理（防抖 / 分片）
    [self triggerBatchProcessingIfNeeded];
}

// ---------- 调度方法（节流/防抖） ----------
- (void)triggerBatchProcessingIfNeeded {
    @synchronized (self) {
        if (self.batchScheduled) return;
        self.batchScheduled = YES;
    }

    // 0.25 ~ 0.35 秒为合适折中，你可以调整为 0.2 / 0.3 根据实际需要
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @synchronized (self) {
            self.batchScheduled = NO;
        }
        [self processPendingMessages];
    });
}

// ---------- 批处理入口（在后台串行队列里执行真正的解析 + 存库） ----------
- (void)processPendingMessages {
    NSArray<NSDictionary *> *batch = nil;
    BOOL hasMorePending = NO;
    static const NSUInteger kMaxBatchCount = 120;

    @synchronized (self.pendingMessages) {
        if (self.pendingMessages.count == 0) return;

        NSUInteger drainCount = MIN(self.pendingMessages.count, kMaxBatchCount);
        batch = [self.pendingMessages subarrayWithRange:NSMakeRange(0, drainCount)];
        [self.pendingMessages removeObjectsInRange:NSMakeRange(0, drainCount)];
        hasMorePending = (self.pendingMessages.count > 0);
    }
    if (!batch || batch.count == 0) return;

    dispatch_async(self.msgProcessQueue, ^{
        NSMutableArray<WFCCMessage *> *toNotify = [NSMutableArray arrayWithCapacity:batch.count];

        NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        for (NSDictionary *cleanDict in batch) {
            @autoreleasepool {
                BOOL shouldSave = YES;
                WFCCMessage *ret = [[WFCCMessage alloc] init];
                ret.fromUser = cleanDict[@"from"];
            
            // 消息方向：0=私聊 1=群聊
            WFCCConversationType conversationType = (WFCCConversationType)[cleanDict[@"direction"] intValue];
            ret.conversation = [[WFCCConversation alloc] init];
            ret.conversation.type = conversationType;
            ret.conversation.line = 0;
            
            id uidValue = cleanDict[@"uid"];
            ret.messageUid = safeParseUint64(uidValue);
            id refValue = cleanDict[@"ref"];
            uint64_t parsedRef = safeParseUint64(refValue);
            long long operatedMessageUid = parsedRef > 0 ? (long long)parsedRef : 0;
            
            if (self.loadLastId == ret.messageUid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadWsEnd" object:nil];
                });
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end1 %lld",self.loadLastId);
                self.loadLastId = 0;
            }

            id pushTimeValue = cleanDict[@"pushTime"];
            ret.serverTime = [pushTimeValue longLongValue];

            NSArray *deviceIds = cleanDict[@"deviceIds"];
            NSMutableArray *toUsers = [[NSMutableArray alloc] init];
            for (NSDictionary *deviceDic in deviceIds) {
                NSString *user = deviceDic[@"uid"];
                [toUsers addObject:user];
            }
            if (conversationType == Single_Type || conversationType == SecretChat_Type) {
                ret.toUsers = @[cleanDict[@"to"]];
            } else {
                ret.toUsers = toUsers;
            }

            if ([ret.fromUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                ret.direction = MessageDirection_Send;
                ret.conversation.target = cleanDict[@"to"];
                // 顶层 ref 仅用于本地待发送消息回执匹配，未命中时让 DB 生成新的本地主键。
                ret.messageId = parsedRef > 0 ? parsedRef : 0;
            } else {
                ret.direction = MessageDirection_Receive;
                //单聊自来from，群聊自来to
                if (conversationType == Single_Type || conversationType == SecretChat_Type) {
                    ret.conversation.target = cleanDict[@"from"];
                } else if (conversationType == Group_Type || conversationType == Chatroom_Type || conversationType == Channel_Type)  {
                    ret.conversation.target = cleanDict[@"to"];
                }
                ret.messageId = 0;
            }
            ret.status = Message_Status_Sent;

            NSDictionary *extraDic;
            NSString *extra = cleanDict[@"extra"];
            if ([extra isKindOfClass:[NSString class]] && extra.length > 0) {
                extraDic = [JSONHelper jsonObjectFromString:extra];
            }

            int contentType = [cleanDict[@"type"] intValue];
            // 补拉起止标记的时间不能成为业务消息游标；其余消息在补拉结束前只记录在内存中。
            if (contentType != MESSAGE_LOAD_TIP && contentType != MESSAGE_LOAD_END_TIP) {
                [self recordRemoteMessageServerTime:ret.serverTime];
            }
            WFCCMessageContent *content = nil;
            // 构建 WFCCMessagePayload
            WFCCMessagePayload *payload;
            
            if (self.loadLastId != 0 && ret.messageUid == self.loadLastId) {
                //最后一条消息
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadWsEnd" object:nil];
                });
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end2 %lld",self.loadLastId);
                self.loadLastId = 0;
            }
            
            // 根据 type 创建对应子类
            if (contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                //文本消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCTextMessageContent alloc] init];
                
                //加好友通知
                if ([(NSString *)cleanDict[@"message"] containsString:@"欢迎加我好友"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                    });
                }
                
                //引用
                if (extraDic[@"ref"]) {
                    NSDictionary *quoteInfoDict = extraDic[@"ref"];
                    WFCCQuoteInfo *quoteInfo = [[WFCCQuoteInfo alloc] init];
                    quoteInfo.messageUid = [quoteInfoDict[@"messageUid"] longLongValue];
                    quoteInfo.userId = quoteInfoDict[@"userId"];
                    quoteInfo.userDisplayName = quoteInfoDict[@"userDisplayName"];
                    quoteInfo.messageDigest = quoteInfoDict[@"messageDigest"];
                    ((WFCCTextMessageContent *)content).quoteInfo = quoteInfo;
                }
            } else if (contentType == MESSAGE_CONTENT_TYPE_SOUND) {
                //语音消息
                content = [[WFCCSoundMessageContent alloc]init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_VOICE;
                if (extraDic[@"duration"]) {
                    NSString *duration = [NSString stringWithFormat:@"%@",extraDic[@"duration"]];
                    ((WFCCSoundMessageContent *)content).duration = [duration longLongValue];
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_IMAGE) {
                //图片消息
                content = [[WFCCImageMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_IMAGE;
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((WFCCImageMessageContent *)content).size = imgSize;
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_LOCATION) {
                //位置消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCLocationMessageContent alloc] init];
            }
            
            else if (contentType == MESSAGE_CONTENT_TYPE_FILE) {
                //文件消息
                content = [[WFCCFileMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_FILE;
                
                if (extraDic[@"file_name"]) {
                    ((WFCCFileMessageContent *)content).name = extraDic[@"file_name"];
                    //                        payload.searchableContent = extraDic[@"file_name"];
                }
                if (extraDic[@"file_size"]) {
                    NSString *size = [NSString stringWithFormat:@"%@",extraDic[@"file_size"]];
                    ((WFCCFileMessageContent *)content).size = [size integerValue];
                    //                        payload.content = size;
                }
                
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_VIDEO) {
                //视频消息
                content = [[WFCCVideoMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_VIDEO;
                if (extraDic[@"thumbnail"]) {
                    ((WFCCVideoMessageContent *)content).thumbnailUrl = extraDic[@"thumbnail"];
                }
                if (extraDic[@"duration"]) {
                    NSString *duration = [NSString stringWithFormat:@"%@",extraDic[@"duration"]];
                    ((WFCCVideoMessageContent *)content).duration = [duration longLongValue];
                }
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((WFCCVideoMessageContent *)content).size = imgSize;
                }
            }
  
            else if (contentType == MESSAGE_CONTENT_TYPE_STICKER) {
                //动态表情消息
                content = [[WFCCStickerMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_STICKER;
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((WFCCStickerMessageContent *)content).size = imgSize;
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_LINK) {
                //链接消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCLinkMessageContent alloc] init];
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_P_TEXT) {
                // 存储不计数文本消息，当前未实现展示，直接跳过避免影响消息流
                shouldSave = NO;
                continue;
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CARD) {
                //名片消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCCardMessageContent alloc] init];
                if (extraDic[@"targetId"]) {
                    ((WFCCCardMessageContent *)content).targetId = extraDic[@"targetId"];
                    payload.content = extraDic[@"targetId"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCCardMessageContent *)content).type = [extraDic[@"type"]intValue];
                }
                if (extraDic[@"name"]) {
                    ((WFCCCardMessageContent *)content).name = extraDic[@"name"];
                }
                if (extraDic[@"displayName"]) {
                    ((WFCCCardMessageContent *)content).displayName = extraDic[@"displayName"];
                }
                if (extraDic[@"portrait"]) {
                    ((WFCCCardMessageContent *)content).portrait = extraDic[@"portrait"];
                }
                if (extraDic[@"fromUser"]) {
                    ((WFCCCardMessageContent *)content).fromUser = extraDic[@"fromUser"];
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE) {
                // 组合消息，当前未实现展示，直接跳过避免影响消息流
                shouldSave = NO;
                continue;
            }
                
            else if (contentType == MESSAGE_CONTENT_TYPE_RICH_NOTIFICATION) {
                // 富通知消息，当前未实现展示，直接跳过避免影响消息流
                shouldSave = NO;
                continue;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ARTICLES) {
                // 文章消息，当前未实现展示，直接跳过避免影响消息流
                shouldSave = NO;
                continue;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                //撤回消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCRecallMessageContent alloc] init];
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_DELETE) {
                //删除消息，请勿直接发送此消息，此消息是服务器端删除时的同步消息
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_TIP) {
                //提醒消息
            }
                    
            else if (contentType == MESSAGE_Delete_Friend) {
                //删除好友
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCCardMessageContent alloc] init];
                
                if ([myuserId isEqualToString:cleanDict[@"from"]]) {
                    [[WFCCMessageDB sharedManager] deleteFriendAndRelatedData:cleanDict[@"to"]];
                }
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                });
            }
                    
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_CREATE_GROUP) {
                //创建群的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCCreateGroupNotificationContent alloc] init];
                NSString *groupId = extraDic[@"gid"];
                ((WFCCCreateGroupNotificationContent *)content).groupId = groupId;
                ((WFCCCreateGroupNotificationContent *)content).creator = extraDic[@"ownerUid"];
                ((WFCCCreateGroupNotificationContent *)content).groupName = extraDic[@"name"];
                if (groupId.length > 0) {
                    [self refreshGroupInfoViaGroupService:groupId];
                }
                
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER) {
                //加群的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCAddGroupeMemberNotificationContent alloc] init];
                NSString *groupId = extraDic[@"gid"];
                ((WFCCAddGroupeMemberNotificationContent *)content).groupId = groupId;
                ((WFCCAddGroupeMemberNotificationContent *)content).invitor = extraDic[@"invitor"];
                NSArray *invitees = nil;
                if (extraDic[@"invitees"]) {
                    invitees = extraDic[@"invitees"];
                    ((WFCCAddGroupeMemberNotificationContent *)content).invitees = invitees;
                }
                BOOL includesCurrentUser = [invitees isKindOfClass:[NSArray class]] && [invitees containsObject:myuserId];
                if (![invitees isKindOfClass:[NSArray class]] || invitees.count == 0) {
                    shouldSave = NO;
                }
                if (includesCurrentUser && groupId.length > 0) {
                    [self refreshGroupInfoViaGroupService:groupId];
                }
                //只有群主和管理员能看到
                if (shouldSave && ![self isGroupOwnerOrManager:ret.conversation]) {
                    WFCCConversationInfo *conversationInfo = [[WFCCConversationDB sharedManager] getConversationInfo:ret.conversation];
                    BOOL shouldCreateConversation = (includesCurrentUser && conversationInfo == nil);
                    shouldSave = shouldCreateConversation;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"gid"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER) {
                //踢出群成员的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCKickoffGroupMemberVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"kickedMembers"]) {
                    NSArray *kickedMembers = extraDic[@"kickedMembers"];
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).kickedMembers = kickedMembers;
                    //被踢的成员里包括自己
                    if ([kickedMembers containsObject:myuserId]) {
                        [[WFCCGroupDB sharedManager] deleteGroupFromDB:ret.conversation.target];
                        [[WFCCConversationDB sharedManager] removeConversation:ret.conversation clearMessage:YES];
                        shouldSave = NO;
                    }
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_QUIT_GROUP) {
                //退群的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCQuitGroupVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCQuitGroupVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"quitMember"]) {
                    ((WFCCQuitGroupVisibleNotificationContent *)content).quitMember = extraDic[@"quitMember"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_DISMISS_GROUP) {
                //解散群的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCDismissGroupNotificationContent alloc] init];
                ((WFCCDismissGroupNotificationContent *)content).groupId = extraDic[@"gid"];
                ((WFCCDismissGroupNotificationContent *)content).operateUser = extraDic[@"ownerUid"];
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER) {
                //转让群主的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCTransferGroupOwnerNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCTransferGroupOwnerNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCTransferGroupOwnerNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"owner"]) {
                    ((WFCCTransferGroupOwnerNotificationContent *)content).owner = extraDic[@"owner"];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_GROUP_NAME) {
                //修改群名称的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCChangeGroupNameNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCChangeGroupNameNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCChangeGroupNameNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"name"]) {
                    ((WFCCChangeGroupNameNotificationContent *)content).name = extraDic[@"name"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS) {
                //修改群昵称的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCModifyGroupAliasNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCModifyGroupAliasNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCModifyGroupAliasNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"alias"]) {
                    ((WFCCModifyGroupAliasNotificationContent *)content).alias = extraDic[@"alias"];
                }
                if (extraDic[@"memberId"]) {
                    ((WFCCModifyGroupAliasNotificationContent *)content).memberId = extraDic[@"memberId"];
                }
                
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_GROUP_PORTRAIT) {
                //修改群头像的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCChangeGroupPortraitNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCChangeGroupPortraitNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCChangeGroupPortraitNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_MUTE) {
                //修改群全局禁言的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupMuteNotificationContent alloc] init];
                if (extraDic[@"creator"]) {
                    ((WFCCGroupMuteNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupMuteNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCGroupMuteNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:nil];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_JOINTYPE) {
                //修改群加入权限的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupJoinTypeNotificationContent alloc] init];
                if (extraDic[@"type"]) {
                    ((WFCCGroupJoinTypeNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupJoinTypeNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((WFCCGroupJoinTypeNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:nil];
                });
                
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_PRIVATECHAT) {
                //修改群群成员私聊的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupPrivateChatNotificationContent alloc] init];
                if (extraDic[@"type"]) {
                    ((WFCCGroupPrivateChatNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupPrivateChatNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((WFCCGroupPrivateChatNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_SEARCHABLE) {
                // 修改群是否可搜索的通知消息，不展示也不入库，避免影响消息时间分组
                shouldSave = NO;
                continue;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_SET_MANAGER) {
                //修改群管理的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupSetManagerNotificationContent alloc] init];
                
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupSetManagerNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((WFCCGroupSetManagerNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCGroupSetManagerNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"memberIds"]) {
                    ((WFCCGroupSetManagerNotificationContent *)content).memberIds = extraDic[@"memberIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:nil];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_MUTE_MEMBER) {
                //禁言/取消禁言群成员的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupMemberMuteNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupMemberMuteNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"creator"]) {
                    ((WFCCGroupMemberMuteNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCGroupMemberMuteNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"targetIds"]) {
                    ((WFCCGroupMemberMuteNotificationContent *)content).targetIds = extraDic[@"targetIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMuteMemberWs object:extraDic[@"targetIds"]];
                });
            }
                    
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ALLOW_MEMBER) {
                //允许/取消允许群成员发言的通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupMemberAllowNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupMemberAllowNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"creator"]) {
                    ((WFCCGroupMemberAllowNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCGroupMemberAllowNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"targetIds"]) {
                    ((WFCCGroupMemberAllowNotificationContent *)content).targetIds = extraDic[@"targetIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:nil];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER_VISIBLE_NOTIFICATION) {
                //踢出群成员的可见通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCKickoffGroupMemberVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"kickedMembers"]) {
                    ((WFCCKickoffGroupMemberVisibleNotificationContent *)content).kickedMembers = extraDic[@"kickedMembers"];
                }
                
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_QUIT_GROUP_VISIBLE_NOTIFICATION) {
                //退群的可见通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCQuitGroupVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCQuitGroupVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"quitMember"]) {
                    ((WFCCQuitGroupVisibleNotificationContent *)content).quitMember = extraDic[@"quitMember"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    shouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_EXTRA) {
                //修改群组Extra通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCModifyGroupExtraNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCModifyGroupExtraNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCModifyGroupExtraNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"groupExtra"]) {
                    ((WFCCModifyGroupExtraNotificationContent *)content).groupExtra = extraDic[@"groupExtra"];
                }
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_MEMBER_EXTRA) {
                //修改群组成员Extra通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCModifyGroupMemberExtraNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCModifyGroupMemberExtraNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((WFCCModifyGroupMemberExtraNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"groupMemberExtra"]) {
                    ((WFCCModifyGroupMemberExtraNotificationContent *)content).groupMemberExtra = extraDic[@"groupMemberExtra"];
                }
                if (extraDic[@"memberId"]) {
                    ((WFCCModifyGroupMemberExtraNotificationContent *)content).memberId = extraDic[@"memberId"];
                }
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
                
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_SETTINGS) {
                //修改群组设置通知消息
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCGroupSettingsNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((WFCCGroupSettingsNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((WFCCGroupSettingsNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (extraDic[@"type"]) {
                    ((WFCCGroupSettingsNotificationContent *)content).type = [extraDic[@"type"] intValue];
                }
                if (extraDic[@"value"]) {
                    ((WFCCGroupSettingsNotificationContent *)content).value = [extraDic[@"value"] intValue];
                }
                
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:nil];
                });
            }
                    
            else if (contentType == GROUP_ANNOUNCEMENT_MESSAGE) {
                //群公告
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCAnnouncementMessageContent alloc] init];
                ((WFCCAnnouncementMessageContent *)content).text = cleanDict[@"message"];
                if (cleanDict[@"mentionedType"]) {
                    ((WFCCAnnouncementMessageContent *)content).mentionedType = [cleanDict[@"mentionedType"]intValue];
                }
                
                //新的群公告
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"New_Group_Announcement_Top" object:nil];
                });
            }
                    
            else if (contentType == GROUP_ANNOUNCEMENT_DELETE_MESSAGE) {
                //删除群公告
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Cancel_Group_Announcement_Top" object:nil];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_GROUP_MESSAGE_TOP) {
                //置顶
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Cancel_Group_Announcement_Top" object:nil];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_GROUP_MESSAGE_DELETE_TOP) {
                //取消置顶
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Cancel_Group_Announcement_Top" object:nil];
                });
            } else if (contentType == MESSAGE_LOAD_TIP) {
                //是load后，ws来的消息,通知会话页面显示接收中
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadWsStart" object:nil];
                });
                if (extraDic[@"lastId"]) {
                    //最后一条消息id
                    self.loadLastId = [extraDic[@"lastId"] longLongValue];
                    NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识begin %lld",self.loadLastId);
                }
            } else if (contentType == MESSAGE_LOAD_END_TIP) {
                shouldSave = NO;
                // 当前处理队列是串行的，到这里说明此前补拉消息均已完成解析和落库。
                [self completeRemoteMessageSync];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadWsEnd" object:nil];
                });
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end3 %lld",self.loadLastId);
            } else if (contentType == MESSAGE_Unkwon) {
                continue;
            } else if (contentType == MESSAGE_FRIENDINFO_CHANGE) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                continue;
            } else if (contentType == MESSAGE_READED) {
                shouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadWsEnd" object:nil];
                });
            } else if (contentType == MESSAGE_FRIEND_TAG_CHANGE) {
                
                continue;
            }
            
            else {
                payload = [[WFCCMessagePayload alloc] init];
                content = [[WFCCUnknownMessageContent alloc] init];
            }
            
            payload.contentType = contentType;
            if (cleanDict[@"message"]) {
                payload.searchableContent = cleanDict[@"message"];
            }
            if (cleanDict[@"content"]) {
                payload.content = cleanDict[@"content"];
            }
            if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                payload.content = cleanDict[@"from"];
                
                //此时的ref是撤回的message的messageuid，需要收到消息的时候，自行删除数据库
                [[WFCCMessageDB sharedManager] deleteMessageByUid:operatedMessageUid];
                removePendingNotifyMessageByUid(toNotify, operatedMessageUid);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(operatedMessageUid)];
                });
            } else if (contentType == MESSAGE_CONTENT_TYPE_DISMISS_GROUP) {
                //删除群组，删除会话，删除会话里的消息
                [[WFCCGroupDB sharedManager] deleteGroupFromDB:ret.conversation.target];
                [[WFCCConversationDB sharedManager] removeConversation:ret.conversation clearMessage:YES];
                shouldSave = NO;
                
            }
            payload.extra = cleanDict[@"extra"];
            payload.pushContent = cleanDict[@"pushContent"];
            
            // 调用 decode 方法让子类解析自己的字段
            if ([content respondsToSelector:@selector(decode:)]) {
                [content decode:payload];
            }
            ret.content = content;

            //删除消息不处理,typing消息不处理
            if (contentType == MESSAGE_CONTENT_TYPE_TYPING) {
                continue;
            }
            if (contentType == MESSAGE_CONTENT_TYPE_DELETE) {
                [[WFCCMessageDB sharedManager] deleteMessageByUid:operatedMessageUid];
                removePendingNotifyMessageByUid(toNotify, operatedMessageUid);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(operatedMessageUid)];
                });
                continue;
            }
            
            // 群主撤回 -> 直接删除，不生成提示
            if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                if (ret.conversation.type == Group_Type) {
                    WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:ret.conversation.target];
                    NSString *operatorId = payload.content;
                    if (groupInfo && [groupInfo.owner isEqualToString:operatorId]) {
                        continue;
                    }
                }
            }
            
            if (!ret) continue;
            if (!shouldSave) continue;

            // 3) 先判断消息位置，再决定是否通知
            WFCCMessagePosition pos = [[WFCCMessageDB sharedManager] judgeMessagePosition:ret];

            [[WFCCMessageDB sharedManager] storeMessageAndUpdateConversation:ret];
            // 原来你会发送 kMessageUpdated 每条消息，这里保持兼容
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:[NSNumber numberWithLongLong:ret.messageId]];
            });

            // 只有新消息或首次历史插入才通知前端显示
            if (pos == WFCCMessagePositionNew || pos == WFCCMessagePositionFirst) {
                [toNotify addObject:ret];
            }

            // 如果是别人发的消息，防抖上报已读（debounceUpdateReadTime 需要在主线程调）
            if (![ret.fromUser isEqualToString:myuserId]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self debounceUpdateReadTime:ret.conversation.target];
                });
            }
            }
        }

        // 统一在主线程通知 UI（批量）
        if (toNotify.count > 0) {
            NSArray<WFCCMessage *> *receivedMessages = [toNotify copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:receivedMessages userInfo:@{@"hasMore":@(NO)}];
                if ([self.receiveMessageDelegate respondsToSelector:@selector(onReceiveMessage:hasMore:)]) {
                    [self.receiveMessageDelegate onReceiveMessage:receivedMessages hasMore:NO];
                }
            });
        }

        // 仍有积压消息则继续调度下一批，避免单次长时间占用 CPU
        if (hasMorePending) {
            [self triggerBatchProcessingIfNeeded];
        }
    });
}


/*
「节流 + 防抖」混合机制（Throttle + Debounce）

消息频繁时，每隔一段时间（比如 10 秒）至少触发一次；

消息停止后，再延迟一点（3 秒）触发一次；

确保既不会太频繁上报，又不会因为消息太多而“永远不发”。
*/
- (void)debounceUpdateReadTime:(NSString *)groupId {
    if (groupId.length == 0) return;
    
    static NSMutableDictionary<NSString *, NSTimer *> *debounceTimers;
    static NSMutableDictionary<NSString *, NSDate *> *lastFireTimes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        debounceTimers = [NSMutableDictionary dictionary];
        lastFireTimes = [NSMutableDictionary dictionary];
    });
    
    // 获取上次触发时间
    NSDate *lastFireTime = lastFireTimes[groupId];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval last = [lastFireTime timeIntervalSince1970];
    
    // 如果距离上次触发超过10秒，立即发一次通知（节流）
    if (!lastFireTime || now - last > 5.0) {
        [self triggerUpdateReadTimeImmediately:groupId];
        lastFireTimes[groupId] = [NSDate date];
        return;
    }
    
    // 防抖逻辑（消息停下来后再触发）
    NSTimer *oldTimer = debounceTimers[groupId];
    if (oldTimer) {
        [oldTimer invalidate];
        [debounceTimers removeObjectForKey:groupId];
    }
    
    NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                         target:self
                                                       selector:@selector(triggerUpdateReadTimeNotification:)
                                                       userInfo:@{@"groupId": groupId}
                                                        repeats:NO];
    debounceTimers[groupId] = newTimer;
}

- (void)triggerUpdateReadTimeImmediately:(NSString *)groupId {
    if (groupId.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kGroupShouldUpdateReadTime"
                                                            object:nil
                                                          userInfo:@{@"groupId": groupId}];
    });
}

- (void)triggerUpdateReadTimeNotification:(NSTimer *)timer {
    NSString *groupId = timer.userInfo[@"groupId"];
    if (groupId.length == 0) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kGroupShouldUpdateReadTime"
                                                            object:nil
                                                          userInfo:@{@"groupId": groupId}];
    });
}

- (id)cleanNullValue:(id)obj {
    if (!obj || obj == [NSNull null] || [obj isKindOfClass:[NSNull class]]) {
        return nil;
    }

    // Dictionary
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            id cleanValue = [self cleanNullValue:value];
            if (cleanValue) {
                dict[key] = cleanValue;
            }
        }];
        return dict;
    }

    // Array
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id value in (NSArray *)obj) {
            id cleanValue = [self cleanNullValue:value];
            if (cleanValue) {
                [array addObject:cleanValue];
            }
        }
        return array;
    }

    // String
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return nil;

        NSString *lower = s.lowercaseString;
        static NSSet *nullStrings;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            nullStrings = [NSSet setWithObjects:
                           @"<null>", @"(null)", @"null", @"nil", @"undefined", nil];
        });

        if ([nullStrings containsObject:lower]) {
            return nil;
        }

        return s;
    }

    // 其他类型（NSNumber 等）原样返回
    return obj;
}

//群主或者管理员
- (BOOL)isGroupOwnerOrManager:(WFCCConversation *)conversation {
    if (conversation.type != Group_Type) {
        return false;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:conversation.target];
    if ([groupInfo.owner isEqualToString:userId]) {
        return YES;
    }
    __block BOOL isManager = false;
    NSArray<WFCCGroupMember *> *groupMembers = [[WFCCGroupDB sharedManager] getGroupMembers:conversation.target];
    [groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:conversation.target]) {
            if (obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

// Base64 转 UIImage
- (UIImage *)imageFromBase64:(NSString *)base64String {
    if (base64String.length == 0) {
        return nil;
    }
    
    // 如果带了 data:image/png;base64, 这样的前缀，先去掉
    NSRange commaRange = [base64String rangeOfString:@","];
    if (commaRange.location != NSNotFound) {
        base64String = [base64String substringFromIndex:commaRange.location + 1];
    }
    
    // 解码 Base64
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!imageData) {
        return nil;
    }
    
    // 转成 UIImage
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}


/// 安全转换任意对象到 uint64_t（IM / WS 场景专用）
static inline uint64_t safeParseUint64(id obj) {
    if (!obj || obj == [NSNull null]) {
        return 0;
    }

    // NSNumber（最可靠）
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj unsignedLongLongValue];
    }

    // NSString
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return 0;

        NSString *lower = s.lowercaseString;

        // 所有“语义 null”
        static NSSet *nullStrings;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            nullStrings = [NSSet setWithObjects:
                           @"<null>", @"(null)", @"null", @"nil", @"undefined", nil];
        });

        if ([nullStrings containsObject:lower]) {
            return 0;
        }

        // 必须是纯数字
        NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        if ([s rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
            return 0;
        }

        // 这里再用 strtoull，100% 安全
        return strtoull(s.UTF8String, NULL, 10);
    }

    // 其他任何类型，一律不信
    return 0;
}


@end
