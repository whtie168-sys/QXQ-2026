#ifndef WFCHATCLIENT_MARS_MESSAGEDB_COMPAT_H
#define WFCHATCLIENT_MARS_MESSAGEDB_COMPAT_H

#include <list>
#include <map>
#include <string>

namespace mars {
namespace stn {

class SendMsgCallback {
public:
    virtual ~SendMsgCallback() {}
};

class GeneralOperationCallback {
public:
    virtual ~GeneralOperationCallback() {}
    virtual void onSuccess() {}
    virtual void onFailure(int) {}
};

class GeneralStringCallback {
public:
    virtual ~GeneralStringCallback() {}
    virtual void onSuccess(const std::string &) {}
    virtual void onFailure(int) {}
};

class GeneralStringListCallback {
public:
    virtual ~GeneralStringListCallback() {}
    virtual void onSuccess(const std::list<std::string> &) {}
    virtual void onFailure(int) {}
};

class CreateGroupCallback {
public:
    virtual ~CreateGroupCallback() {}
    virtual void onSuccess(const std::string &) {}
    virtual void onFailure(int) {}
};

class CreateSecretChatCallback {
public:
    virtual ~CreateSecretChatCallback() {}
    virtual void onSuccess(const std::string &, int) {}
    virtual void onFailure(int) {}
};

class GetAuthorizedMediaUrlCallback {
public:
    virtual ~GetAuthorizedMediaUrlCallback() {}
    virtual void onSuccess(const std::string &, const std::string &) {}
    virtual void onFailure(int) {}
};

struct TMessageContent {
    int type = 0;
    std::string searchableContent;
    std::string pushContent;
    std::string content;
    std::string binaryContent;
    std::string localContent;
    std::string mentionedTargets;
    int mediaType = 0;
    std::string remoteMediaUrl;
    std::string localMediaPath;
    std::string extra;
};

struct TMessage {
    long messageId = 0;
    long long messageUid = 0;
    int conversationType = 0;
    std::string target;
    int line = 0;
    std::string from;
    int direction = 0;
    int status = 0;
    long long timestamp = 0;
    TMessageContent content;
};

struct TConversation {
    int conversationType = 0;
    std::string target;
    int line = 0;
    TMessage lastMessage;
    long long timestamp = 0;
    int unreadCount = 0;
    int unreadMention = 0;
    int unreadMentionAll = 0;
    int unreadMentionMe = 0;
    std::string draft;
};

struct TReadEntry {
    std::string userId;
    long long readDt = 0;
};

struct TUserInfo {
    std::string uid;
    std::string name;
    std::string displayName;
    std::string portrait;
    std::string mobile;
    std::string email;
    std::string address;
    std::string company;
    std::string social;
    std::string extra;
    int gender = 0;
    int type = 0;
    int deleted = 0;
    long long updateDt = 0;
};

struct TGroupInfo {
    std::string target;
    std::string name;
    std::string portrait;
    std::string owner;
    std::string extra;
    int type = 0;
    int memberCount = 0;
    int memberUpdateDt = 0;
    long long updateDt = 0;
};

struct TGroupMember {
    std::string groupId;
    std::string memberId;
    std::string alias;
    std::string extra;
    int type = 0;
    long long updateDt = 0;
};

struct TChannelInfo {
    std::string channelId;
    std::string name;
    std::string portrait;
    std::string owner;
    std::string desc;
    std::string extra;
    int status = 0;
    long long updateDt = 0;
};

struct TChatroomInfo {
    std::string chatroomId;
    std::string title;
    std::string desc;
    std::string portrait;
    int memberCount = 0;
    long long createDt = 0;
    long long updateDt = 0;
    std::string extra;
};

struct TChatroomMemberInfo {
    int memberCount = 0;
    int memberCountDelta = 0;
};

struct TUploadMediaUrlEntry {
    std::string uploadUrl;
    std::string downloadUrl;
    std::string backupUploadUrl;
    int type = 0;
};

struct TOnlineState {
    int platform = 0;
    int state = 0;
    long long lastSeen = 0;
    std::string customState;
};

struct TUserOnlineState {
    std::string userId;
    std::list<TOnlineState> states;
};

struct TFileRecord {
    std::string userId;
    std::string name;
    std::string url;
    long long size = 0;
    long long messageUid = 0;
    long long timestamp = 0;
    int conversationType = 0;
    std::string target;
    int line = 0;
};

struct TFriendRequest {
    std::string target;
    std::string reason;
    int direction = 0;
    int status = 0;
    long long timestamp = 0;
};

struct TUnreadCount {
    int unread = 0;
    int unreadMention = 0;
    int unreadMentionAll = 0;
    int unreadMentionMe = 0;
};

struct TSecretChatInfo {
    std::string targetId;
    int line = 0;
    int state = 0;
    long long burnTime = 0;
};

enum MessageStatus {
    Message_Status_Sending = 0
};

class MessageDB {
public:
    static MessageDB *Instance() {
        static MessageDB db;
        return &db;
    }

    std::list<TGroupMember> GetGroupMembers(const char *, bool) { return {}; }
    void GetGroupMembers(const char *, bool, void *) {}
    std::list<TGroupMember> GetGroupMembersByType(const char *, int) { return {}; }
    std::list<TGroupMember> GetGroupMembersByCount(const char *, int) { return {}; }
    TGroupMember GetGroupMember(const char *, const char *) { return TGroupMember(); }
    std::list<TGroupInfo> GetGroupInfos(const std::list<std::string> &, bool) { return {}; }
    std::string GetUserSetting(int, const char *) { return {}; }
    std::map<std::string, std::string> GetUserSettings(int) { return {}; }
    TChannelInfo GetChannelInfo(const char *, bool) { return TChannelInfo(); }
    TSecretChatInfo GetSecretChatInfo(const char *) { return TSecretChatInfo(); }
    void SetSecretChatBurnTime(const char *, int) {}
};

}
}

#endif
