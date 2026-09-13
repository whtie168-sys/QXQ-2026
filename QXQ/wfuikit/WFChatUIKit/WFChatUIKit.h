//
//  WFChatUIKit.h
//  WFChatUIKit
//
//  Created by WF Chat on 2018/10/23.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for WFChatUIKit.
FOUNDATION_EXPORT double WFChatUIKitVersionNumber;

//! Project version string for WFChatUIKit.
FOUNDATION_EXPORT const unsigned char WFChatUIKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WFChatUIKit/PublicHeader.h>


#import <WFChatUIKit/Predefine.h>
#import <WFChatUIKit/AIOIUEHMessageListVC.h>
#import <WFChatUIKit/DUVOHJNGroupInfoVC.h>
#import <WFChatUIKit/FCNUOEYForwardVC.h>
#import <WFChatUIKit/LUDHIOWIVFilesVC.h>

#import <WFChatUIKit/QrCodeHelper.h>
#import <WFChatUIKit/JUAHODJNKBrowserVC.h>

#import <WFChatUIKit/AIOIUEHMediaMessageDownloader.h>
#import <WFChatUIKit/WDCARFaceBoard.h>
#import <WFChatUIKit/LUDHIOWIVEnum.h>
#import <WFChatUIKit/UIView+Toast.h>


#import <WFChatUIKit/MWPhotoBrowser.h>

#import <WFChatUIKit/AIOIUEHConfigManager.h>

#import <WFChatUIKit/AIOIUEHAppServiceProvider.h>
#import <WFChatUIKit/DUVOHJNGroupAnnouncement.h>
#import <WFChatUIKit/AIOIUEHFavoriteItem.h>

#import <WFChatUIKit/JUAHODJNKBubbleTipView.h>
#import <WFChatUIKit/UITabBar+badge.h>
#import <WFChatUIKit/AIOIUEHUtilities.h>

#import <WFChatUIKit/AIOIUEHCompositeMessageVC.h>
#import <WFChatUIKit/WDCARLocationViewController.h>
#import <WFChatUIKit/WDCARLocationPoint.h>


#import <WFChatUIKit/LBXScanVideoZoomView.h>
#import <WFChatUIKit/LBXScanViewController.h>

#import <WFChatUIKit/LBXPermission.h>
#import <WFChatUIKit/LBXPermissionSetting.h>
#import <WFChatUIKit/LBXAlertAction.h>

#import <WFChatUIKit/LBXScanViewStyle.h>
#import <WFChatUIKit/StyleDIY.h>
#import <WFChatUIKit/AIOIUEHImage.h>

#import <WFChatUIKit/LUDHIOWIVOrganization.h>
#import <WFChatUIKit/LUDHIOWIVEmployee.h>
#import <WFChatUIKit/LUDHIOWIVEmployeeEx.h>
#import <WFChatUIKit/LUDHIOWIVOrgRelationship.h>
#import <WFChatUIKit/LUDHIOWIVOrganizationEx.h>
#import <WFChatUIKit/LUDHIOWIVOrganizationCache.h>
#import <WFChatUIKit/LUDHIOWIVOrgServiceProvider.h>


#import <WFChatUIKit/HNWOUIDSeletedUserVC.h>
#import <WFChatUIKit/KxMenu.h>
#import <WFChatUIKit/UIImage+ERCategory.h>
#import <WFChatUIKit/QOEUAPinyinUtility.h>
#import <WFChatUIKit/HNWOUIDContactTVCell.h>
#import <WFChatUIKit/UIImage+ERCategory.h>
#import <WFChatUIKit/UIColor+YH.h>
#import <WFChatUIKit/AIOIUEHImage.h>
#import <WFChatUIKit/DUVOHJNFriendRequestVC.h>
#import <WFChatUIKit/DUVOHJNSearchGroupTVCell.h>
#import <WFChatUIKit/DUVOHJNConversationTVCell.h>
#import <WFChatUIKit/DUVOHJNConversationSearchTableVC.h>

#import <WFChatUIKit/JUAHODJNKAddFriendVC.h>
#import <WFChatUIKit/HNWOUIDNewFriendTVCell.h>
#import <WFChatUIKit/HNWOUIDContactSelectTVCell.h>
#import <WFChatUIKit/LUDHIOWIVOrganizationViewController.h>
#import <WFChatUIKit/pinyin.h>
#import <WFChatUIKit/LBXScanNative.h>
#import <WFChatUIKit/LBXScanTypes.h>

#import <WFChatUIKit/WDCARChatInputBar.h>
#import <WFChatUIKit/AIOIUEHMessageModel.h>
#import <WFChatUIKit/SMIOUEJMessageCellBase.h>  // SMIOUEJMultiCallOngoingExpendedCell removed: voip feature

#import <WFChatUIKit/SMIOUEJMessageCell.h>
#import <WFChatUIKit/SMIOUEJMediaMessageCell.h>
#import <WFChatUIKit/SMIOUEJArticlesCell.h>

#import <WFChatUIKit/SMIOUEJImageCell.h>
#import <WFChatUIKit/SMIOUEJTextCell.h>
#import <WFChatUIKit/SMIOUEJVoiceCell.h>
#import <WFChatUIKit/SMIOUEJLocationCell.h>
#import <WFChatUIKit/SMIOUEJFileCell.h>
#import <WFChatUIKit/SMIOUEJInformationCell.h>
#import <WFChatUIKit/SMIOUEJCallSummaryCell.h>
#import <WFChatUIKit/SMIOUEJStickerCell.h>
#import <WFChatUIKit/SMIOUEJVideoCell.h>
#import <WFChatUIKit/SMIOUEJRecallCell.h>
#import <WFChatUIKit/SMIOUEJCardCell.h>
#import <WFChatUIKit/SMIOUEJCompositeCell.h>
#import <WFChatUIKit/SMIOUEJLinkCell.h>
#import <WFChatUIKit/SMIOUEJRichNotificationCell.h>

#import <WFChatUIKit/JUAHODJNKBrowserVC.h>
#import <WFChatUIKit/WDCARChatInputBar.h>
#import <WFChatUIKit/JUAHODJNKImagePreviewViewController.h>
#import <WFChatUIKit/DUVOHJNReceiptVC.h>
// #import <WFChatUIKit/SMIOUEJMultiCallOngoingCell.h>  // removed: voip feature

#import <WFChatUIKit/JUAHODJNKAttributedLabel.h>

#import <WFChatUIKit/DUVOHJNConversationSearchTVCell.h>

#import <WFChatUIKit/DUVOHJNSelectNoDisturbingTimeVC.h>
#import <WFChatUIKit/FCNUOEYShareMessageView.h>
#import <WFChatUIKit/UIView+TYAlertView.h>
#import <WFChatUIKit/TYAlertController.h>
#import <WFChatUIKit/TYAlertView.h>
#import <WFChatUIKit/TYShowAlertView.h>
