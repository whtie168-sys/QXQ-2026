//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "SMIOUEJImageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>

@interface SMIOUEJImageCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@property(nonatomic, strong) UILabel *captionLabel;
@end

@implementation SMIOUEJImageCell

+ (void)resolveImageMetadataIfNeeded:(WFCCImageMessageContent *)imgContent {
    if (!imgContent || !CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        return;
    }

    UIImage *sourceImage = nil;
    if (imgContent.localPath.length) {
        sourceImage = [UIImage imageWithContentsOfFile:imgContent.localPath];
    }

    if (!sourceImage && imgContent.remoteUrl.length) {
        NSString *cacheKey = nil;
        if (imgContent.thumbParameter.length) {
            cacheKey = [[NSString stringWithFormat:@"%@?%@", imgContent.remoteUrl, imgContent.thumbParameter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            cacheKey = [imgContent.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        }
        if (cacheKey.length) {
            sourceImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:cacheKey];
        }
    }

    if (!sourceImage) {
        return;
    }

    imgContent.size = sourceImage.size;
    if (!imgContent.thumbnail) {
        imgContent.thumbnail = [WFCCUtilities generateThumbnail:sourceImage withWidth:120 withHeight:120];
    }
}

- (void)refreshLayoutForLoadedImage:(UIImage *)image {
    if (!image) {
        return;
    }

    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)self.model.message.content;
    BOOL sizeChanged = NO;
    CGSize oldSize = CGSizeZero;
    if (!CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        oldSize = imgContent.size;
    }

    UIImage *thumbnailImage = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    if (!imgContent.thumbnail || !CGSizeEqualToSize(imgContent.thumbnail.size, thumbnailImage.size)) {
        imgContent.thumbnail = thumbnailImage;
        sizeChanged = YES;
    }

    if (CGSizeEqualToSize(imgContent.size, CGSizeZero) || !CGSizeEqualToSize(imgContent.size, image.size)) {
        imgContent.size = image.size;
        sizeChanged = YES;
    }

    if (!sizeChanged || CGSizeEqualToSize(oldSize, image.size)) {
        return;
    }

    UICollectionView *collectionView = nil;
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            collectionView = (UICollectionView *)view;
            break;
        }
        view = view.superview;
    }

    if (!collectionView) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView performWithoutAnimation:^{
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView performBatchUpdates:nil completion:nil];
            [collectionView layoutIfNeeded];
        }];
    });
}

+ (CGSize)baseImageSizeForModel:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msgModel.message.content;
    [self resolveImageMetadataIfNeeded:imgContent];
    CGSize size = CGSizeMake(120, 120);
    if (!CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        size = [WFCCUtilities imageScaleSize:imgContent.size targetSize:CGSizeMake(120, 120) thumbnailPoint:nil];
    } else if(imgContent.thumbnail) {
        size = imgContent.thumbnail.size;
    } else {
        size = CGSizeMake(120, 120);
    }
    
    
    // 该逻辑0126新增 主要是为视频缩略图压缩成120规格所定义
    if (size.height == 301 || size.width == 301) {
        if (size.height == 301) {
            size = CGSizeMake(size.width/301.0*120.0, 120.0);
        }else {
            size = CGSizeMake(120.0, size.height/301.0*120.0);
        }
    }else {
        if (size.height > width || size.width > width) {
            float scale = MIN(width/size.height, width/size.width);
            size = CGSizeMake(size.width * scale, size.height * scale);
        }
    }
    return size;
}

+ (CGSize)sizeForClientArea:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGSize mediaSize = [self baseImageSizeForModel:msgModel withViewWidth:width];
    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msgModel.message.content;
    CGSize sourceSize = CGSizeEqualToSize(imgContent.size, CGSizeZero) ? mediaSize : imgContent.size;
    CGSize displaySize = [SMIOUEJMediaMessageCell mediaDisplaySizeForSourceSize:sourceSize
                                                               constrainedWidth:width];
    NSString *caption = [SMIOUEJMediaMessageCell mediaCaptionForModel:msgModel];
    if (caption.length == 0) {
        return displaySize;
    }

    CGFloat displayWidth = MIN(width, MAX(180.0, displaySize.width));
    CGSize captionSize = [SMIOUEJMediaMessageCell mediaCaptionSizeForModel:msgModel
                                                          constrainedWidth:MAX(1, displayWidth - 16)];
    return CGSizeMake(displayWidth, ceil(displaySize.height + 8 + captionSize.height + 8));
}

- (void)setModel:(AIOIUEHMessageModel *)model {
    [super setModel:model];
    

    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)model.message.content;
    [[self class] resolveImageMetadataIfNeeded:imgContent];
    NSString *caption = [SMIOUEJMediaMessageCell mediaCaptionForModel:model];
    if (caption.length > 0) {
        CGSize clientSize = self.tzboeuContentArea.bounds.size;
        CGSize captionSize = [SMIOUEJMediaMessageCell mediaCaptionSizeForModel:model
                                                              constrainedWidth:MAX(1, clientSize.width - 16)];
        CGSize sourceSize = CGSizeEqualToSize(imgContent.size, CGSizeZero) ? imgContent.thumbnail.size : imgContent.size;
        CGSize displaySize = [SMIOUEJMediaMessageCell mediaDisplaySizeForSourceSize:sourceSize
                                                                   constrainedWidth:clientSize.width];
        CGFloat contentX = model.message.direction == MessageDirection_Send ? 8 : 16;
        CGFloat mediaX = contentX + MAX(0, (clientSize.width - displaySize.width) / 2.0);
        self.tzboeuThumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        self.tzboeuThumbnailView.frame = CGRectMake(mediaX, 6, displaySize.width, displaySize.height);
        self.captionLabel.hidden = NO;
        self.captionLabel.text = caption;
        UIColor *captionColor = [UIColor colorWithWhite:0.12 alpha:1];
        if (model.message.direction == MessageDirection_Receive) {
            if (@available(iOS 13.0, *)) {
                captionColor = UIColor.labelColor;
            }
        }
        self.captionLabel.textColor = captionColor;
        self.captionLabel.frame = CGRectMake(contentX + 8,
                                             CGRectGetMaxY(self.tzboeuThumbnailView.frame) + 6,
                                             MAX(1, clientSize.width - 16),
                                             captionSize.height);
    } else {
        self.captionLabel.hidden = YES;
        self.captionLabel.text = nil;
        CGSize clientSize = self.tzboeuContentArea.bounds.size;
        CGFloat contentX = model.message.direction == MessageDirection_Send ? 8.0 : 16.0;
        self.tzboeuThumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        self.tzboeuThumbnailView.frame = CGRectMake(contentX, 6.0, clientSize.width, clientSize.height);
    }
    if (!imgContent.thumbnail && imgContent.thumbParameter) {
        
        NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@?%@", imgContent.remoteUrl, imgContent.thumbParameter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (!url) {
            self.tzboeuThumbnailView.image = nil;
        } else {
            // 使用 AvoidAutoSetImage 避免闪烁
            [self.trewqPortraitView sd_setImageWithURL:url
                                     placeholderImage:nil
                                              options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                              context:@{
                SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
            }
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    [self refreshLayoutForLoadedImage:image];
                    self.tzboeuThumbnailView.alpha = 1.0;
                    self.tzboeuThumbnailView.image = image;
                } else {
                    self.tzboeuThumbnailView.image = nil;
                }
            }];
        }
        
    } else {
        
        NSString *escaped = [imgContent.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:escaped];
        
        if (!url) {
            self.tzboeuThumbnailView.image = nil;
        } else {
            // 使用 AvoidAutoSetImage 避免闪烁
            [self.tzboeuThumbnailView sd_setImageWithURL:url
                                     placeholderImage:nil
                                              options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                              context:@{
                SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
            }
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    [self refreshLayoutForLoadedImage:image];
                    self.tzboeuThumbnailView.alpha = 1.0;
                    self.tzboeuThumbnailView.image = image;
                } else {
                    self.tzboeuThumbnailView.image = nil;
                }
            }];
        }
    }
}

- (UIImageView *)tzboeuThumbnailView {
    if (!_tzboeuThumbnailView) {
        _tzboeuThumbnailView = [[UIImageView alloc] init];
        _tzboeuThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        _tzboeuThumbnailView.clipsToBounds = YES;
        [self.tzboeuBubbleView addSubview:_tzboeuThumbnailView];
    }
    return _tzboeuThumbnailView;
}

- (UILabel *)captionLabel {
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.font = [UIFont systemFontOfSize:15];
        _captionLabel.numberOfLines = 0;
        _captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _captionLabel.textAlignment = NSTextAlignmentLeft;
        _captionLabel.accessibilityIdentifier = @"mediaMessageCaption";
        [self.tzboeuBubbleView addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (void)setMaskImage:(UIImage *)maskImage{
    [super setMaskImage:maskImage];
    if (_shadowMaskView) {
        [_shadowMaskView removeFromSuperview];
    }
    _shadowMaskView = [[UIImageView alloc] initWithImage:maskImage];
    
    CGRect frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x - 1, self.tzboeuBubbleView.frame.origin.y - 1, self.tzboeuBubbleView.frame.size.width + 2, self.tzboeuBubbleView.frame.size.height + 2);
    _shadowMaskView.frame = frame;
    [self.contentView addSubview:_shadowMaskView];
    [self.contentView bringSubviewToFront:self.tzboeuBubbleView];
    
}

- (UIView *)getProgressParentView {
    return self.tzboeuThumbnailView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.tzboeuThumbnailView sd_cancelCurrentImageLoad];
    self.tzboeuThumbnailView.image = nil;
    self.captionLabel.text = nil;
    self.captionLabel.hidden = YES;
}
@end
