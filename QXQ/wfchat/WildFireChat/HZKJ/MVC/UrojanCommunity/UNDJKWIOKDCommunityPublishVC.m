//
//  UNDJKWIOKDCommunityPublishVC.m
//  WUHOIBDK
//

#import "UNDJKWIOKDCommunityPublishVC.h"
#import "AppService.h"
#import "UNDJKWIOKDPlaceholderTextView.h"
#import "MBProgressHUD.h"
#import <WFChatClient/WFCCCommunity.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>

static NSInteger const kCommunityPublishImageCover = -1;

@interface UNDJKWIOKDCommunityPublishVC () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIButton *coverButton;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *coverPlaceholderLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UNDJKWIOKDPlaceholderTextView *summaryTextView;
@property (nonatomic, strong) UIStackView *sectionsStackView;
@property (nonatomic, strong) UIView *addSectionContainerView;
@property (nonatomic, strong) UIButton *addSectionButton;
@property (nonatomic, strong) UIView *linkContainerView;
@property (nonatomic, strong) UIButton *linkHeaderButton;
@property (nonatomic, strong) UIButton *linkToggleButton;
@property (nonatomic, strong) UITextField *linkTextField;
@property (nonatomic, strong) UITextField *linkUrlField;
@property (nonatomic, strong) NSLayoutConstraint *linkContainerHeightConstraint;
@property (nonatomic, strong) MBProgressHUD *submittingHUD;

@property (nonatomic, strong, nullable) UIImage *coverImage;
@property (nonatomic, copy) NSString *coverImageUrl;
@property (nonatomic, strong) NSMutableArray *sectionImages;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionImageUrls;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionTexts;
@property (nonatomic, strong) NSMutableArray<UITextView *> *sectionTextViews;
@property (nonatomic, assign) NSInteger pickingImageIndex;
@property (nonatomic, assign) BOOL submitting;
@property (nonatomic, assign) BOOL linkEnabled;

@end

@implementation UNDJKWIOKDCommunityPublishVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.sectionImages = [NSMutableArray array];
    self.sectionImageUrls = [NSMutableArray array];
    self.sectionTexts = [NSMutableArray array];
    self.sectionTextViews = [NSMutableArray array];
    self.pickingImageIndex = kCommunityPublishImageCover;
    [self buildViews];
    [self addKeyboardObservers];
    [self applyEditingArticleIfNeeded];
    [self updateSubmitState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)buildViews {
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton setTitle:LLLLLL(@"CommunityPublish_Cancel") forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = PINGFANG_M(16);
    [self.cancelButton addTarget:self action:@selector(cancelButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton setTitle:(self.articleToEdit ? LLLLLL(@"CommunityPublish_Update") : LLLLLL(@"CommunityPublish_Publish")) forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.submitButton setTitleColor:RGBA(0x999999) forState:UIControlStateDisabled];
    [self.submitButton setBackgroundImage:[UIImage imageWithColor:RGBA(0x2BDD30) size:CGSizeMake(52, 30) cornerRadius:4] forState:UIControlStateNormal];
    [self.submitButton setBackgroundImage:[UIImage imageWithColor:RGBA(0xF1F1F1) size:CGSizeMake(52, 30) cornerRadius:4] forState:UIControlStateDisabled];
    self.submitButton.titleLabel.font = PINGFANG_M(14);
    [self.submitButton addTarget:self action:@selector(submitButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    self.coverButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.coverButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverButton.backgroundColor = RGBA(0xF6F6F6);
    [self.coverButton addTarget:self action:@selector(coverButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.coverButton];

    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.image = [UIImage imageNamed:@"community_publish_cover_bg"];
    [self.coverButton addSubview:self.coverImageView];

    self.coverPlaceholderLabel = [[UILabel alloc] init];
    self.coverPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverPlaceholderLabel.text = LLLLLL(@"CommunityPublish_UploadCover");
    self.coverPlaceholderLabel.textColor = RGBA(0x878787);
    self.coverPlaceholderLabel.font = PINGFANG_M(15);
    self.coverPlaceholderLabel.textAlignment = NSTextAlignmentCenter;
    [self.coverButton addSubview:self.coverPlaceholderLabel];

    self.titleField = [[UITextField alloc] init];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.font = PINGFANG_M(16);
    self.titleField.textColor = RGBA(0x222222);
    self.titleField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LLLLLL(@"CommunityPublish_TitlePlaceholder")
                                                                            attributes:@{NSForegroundColorAttributeName: RGBA(0x2C2C2C),
                                                                                         NSFontAttributeName: self.titleField.font}];
    self.titleField.delegate = self;
    self.titleField.returnKeyType = UIReturnKeyDone;
    [self.titleField addTarget:self action:@selector(textDidChange) forControlEvents:UIControlEventEditingChanged];
    [self.contentView addSubview:self.titleField];

    self.summaryTextView = [[UNDJKWIOKDPlaceholderTextView alloc] init];
    self.summaryTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.summaryTextView.font = PINGFANG_M(16);
    self.summaryTextView.textColor = RGBA(0x222222);
    self.summaryTextView.placeholder = LLLLLL(@"CommunityPublish_SummaryPlaceholder");
    self.summaryTextView.placeholderColor = RGBA(0x888888);
    self.summaryTextView.delegate = self;
    self.summaryTextView.scrollEnabled = NO;
    self.summaryTextView.textContainerInset = UIEdgeInsetsZero;
    self.summaryTextView.textContainer.lineFragmentPadding = 0;
    [self.contentView addSubview:self.summaryTextView];

    self.sectionsStackView = [[UIStackView alloc] init];
    self.sectionsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sectionsStackView.axis = UILayoutConstraintAxisVertical;
    self.sectionsStackView.spacing = 14;
    [self.contentView addSubview:self.sectionsStackView];

    self.addSectionContainerView = [[UIView alloc] init];
    self.addSectionContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sectionsStackView addArrangedSubview:self.addSectionContainerView];

    self.addSectionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addSectionButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addSectionButton.backgroundColor = RGBA(0xF7F7F7);
    [self.addSectionButton setTitle:@"+" forState:UIControlStateNormal];
    [self.addSectionButton setTitleColor:RGBA(0x888888) forState:UIControlStateNormal];
    self.addSectionButton.titleLabel.font = [UIFont systemFontOfSize:38 weight:UIFontWeightLight];
    [self.addSectionButton addTarget:self action:@selector(addSectionButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.addSectionContainerView addSubview:self.addSectionButton];

    self.linkContainerView = [[UIView alloc] init];
    self.linkContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.linkContainerView];

    self.linkHeaderButton = [self createLinkHeaderButton];
    [self.linkHeaderButton addTarget:self action:@selector(linkHeaderButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.linkContainerView addSubview:self.linkHeaderButton];

    self.linkToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.linkToggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.linkToggleButton.layer.cornerRadius = 7;
    self.linkToggleButton.layer.borderWidth = 1;
    self.linkToggleButton.layer.borderColor = RGBA(0x999999).CGColor;
    self.linkToggleButton.titleLabel.font = PINGFANG_M(10);
    [self.linkToggleButton addTarget:self action:@selector(linkHeaderButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.linkContainerView addSubview:self.linkToggleButton];

    self.linkTextField = [self linkTextFieldWithPlaceholder:LLLLLL(@"CommunityPublish_LinkNamePlaceholder")];
    [self.linkContainerView addSubview:self.linkTextField];

    self.linkUrlField = [self linkTextFieldWithPlaceholder:LLLLLL(@"CommunityPublish_LinkUrlPlaceholder")];
    self.linkUrlField.keyboardType = UIKeyboardTypeURL;
    [self.linkContainerView addSubview:self.linkUrlField];
    [self updateLinkSectionState];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    self.linkContainerHeightConstraint = [self.linkContainerView.heightAnchor constraintEqualToConstant:40];
    [NSLayoutConstraint activateConstraints:@[
        [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14],
        [self.cancelButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:8],
        [self.cancelButton.widthAnchor constraintEqualToConstant:54],
        [self.cancelButton.heightAnchor constraintEqualToConstant:34],

        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14],
        [self.submitButton.centerYAnchor constraintEqualToAnchor:self.cancelButton.centerYAnchor],
        [self.submitButton.widthAnchor constraintEqualToConstant:52],
        [self.submitButton.heightAnchor constraintEqualToConstant:30],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.cancelButton.bottomAnchor constant:24],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],

        [self.coverButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.coverButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18],
        [self.coverButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18],
        [self.coverButton.heightAnchor constraintEqualToConstant:200],

        [self.coverImageView.topAnchor constraintEqualToAnchor:self.coverButton.topAnchor constant:66],
        [self.coverImageView.centerXAnchor constraintEqualToAnchor:self.coverButton.centerXAnchor],
        [self.coverImageView.heightAnchor constraintEqualToConstant:35],
        [self.coverImageView.widthAnchor constraintEqualToConstant:40],

        [self.coverPlaceholderLabel.topAnchor constraintEqualToAnchor:self.coverImageView.bottomAnchor constant:16],
        [self.coverPlaceholderLabel.centerXAnchor constraintEqualToAnchor:self.coverButton.centerXAnchor],

        [self.titleField.topAnchor constraintEqualToAnchor:self.coverButton.bottomAnchor constant:28],
        [self.titleField.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18],
        [self.titleField.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18],
        [self.titleField.heightAnchor constraintEqualToConstant:34],

        [self.summaryTextView.topAnchor constraintEqualToAnchor:self.titleField.bottomAnchor constant:16],
        [self.summaryTextView.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor],
        [self.summaryTextView.trailingAnchor constraintEqualToAnchor:self.titleField.trailingAnchor],
        [self.summaryTextView.heightAnchor constraintGreaterThanOrEqualToConstant:70],

        [self.sectionsStackView.topAnchor constraintEqualToAnchor:self.summaryTextView.bottomAnchor constant:28],
        [self.sectionsStackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],
        [self.sectionsStackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14],

        [self.addSectionContainerView.widthAnchor constraintEqualToAnchor:self.sectionsStackView.widthAnchor],
        [self.addSectionButton.topAnchor constraintEqualToAnchor:self.addSectionContainerView.topAnchor],
        [self.addSectionButton.leadingAnchor constraintEqualToAnchor:self.addSectionContainerView.leadingAnchor constant:4],
        [self.addSectionButton.bottomAnchor constraintEqualToAnchor:self.addSectionContainerView.bottomAnchor],
        [self.addSectionButton.widthAnchor constraintEqualToConstant:100],
        [self.addSectionButton.heightAnchor constraintEqualToConstant:100],

        [self.linkContainerView.topAnchor constraintEqualToAnchor:self.sectionsStackView.bottomAnchor constant:16],
        [self.linkContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18],
        [self.linkContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18],
        [self.linkContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-30],
        self.linkContainerHeightConstraint,

        [self.linkHeaderButton.topAnchor constraintEqualToAnchor:self.linkContainerView.topAnchor],
        [self.linkHeaderButton.leadingAnchor constraintEqualToAnchor:self.linkContainerView.leadingAnchor],
        [self.linkHeaderButton.trailingAnchor constraintEqualToAnchor:self.linkContainerView.trailingAnchor],
        [self.linkHeaderButton.heightAnchor constraintEqualToConstant:40],

        [self.linkToggleButton.trailingAnchor constraintEqualToAnchor:self.linkHeaderButton.trailingAnchor constant:-12],
        [self.linkToggleButton.centerYAnchor constraintEqualToAnchor:self.linkHeaderButton.centerYAnchor],
        [self.linkToggleButton.widthAnchor constraintEqualToConstant:14],
        [self.linkToggleButton.heightAnchor constraintEqualToConstant:14],

        [self.linkTextField.topAnchor constraintEqualToAnchor:self.linkHeaderButton.bottomAnchor constant:8],
        [self.linkTextField.leadingAnchor constraintEqualToAnchor:self.linkContainerView.leadingAnchor],
        [self.linkTextField.trailingAnchor constraintEqualToAnchor:self.linkContainerView.trailingAnchor],
        [self.linkTextField.heightAnchor constraintEqualToConstant:42],

        [self.linkUrlField.topAnchor constraintEqualToAnchor:self.linkTextField.bottomAnchor constant:8],
        [self.linkUrlField.leadingAnchor constraintEqualToAnchor:self.linkContainerView.leadingAnchor],
        [self.linkUrlField.trailingAnchor constraintEqualToAnchor:self.linkContainerView.trailingAnchor],
        [self.linkUrlField.heightAnchor constraintEqualToConstant:42],
    ]];
}

- (UIButton *)createLinkHeaderButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = RGBA(0xF6F6F6);
    button.layer.cornerRadius = 6;
    button.clipsToBounds = YES;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 38);
    [button setTitle:LLLLLL(@"CommunityPublish_AddLink") forState:UIControlStateNormal];
    [button setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
    button.titleLabel.font = PINGFANG_M(14);
    return button;
}

- (UITextField *)linkTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = placeholder;
    textField.font = PINGFANG_M(14);
    textField.textColor = RGBA(0x222222);
    textField.backgroundColor = RGBA(0xF6F6F6);
    textField.layer.cornerRadius = 6;
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    return textField;
}

- (void)linkHeaderButtonDidTap {
    self.linkEnabled = !self.linkEnabled;
    [self updateLinkSectionState];
}

- (void)updateLinkSectionState {
    self.linkTextField.hidden = !self.linkEnabled;
    self.linkUrlField.hidden = !self.linkEnabled;
    self.linkContainerHeightConstraint.constant = self.linkEnabled ? 140 : 40;
    self.linkToggleButton.backgroundColor = self.linkEnabled ? RGBA(0x2EC84D) : UIColor.clearColor;
    self.linkToggleButton.layer.borderColor = (self.linkEnabled ? RGBA(0x2EC84D) : RGBA(0x999999)).CGColor;
    [self.linkToggleButton setTitle:(self.linkEnabled ? @"✓" : @"") forState:UIControlStateNormal];
    [self.linkToggleButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    if (self.linkEnabled) {
        [self scrollViewToVisible:self.linkContainerView animated:YES];
    }
}

- (void)addKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedFrame));
    UIEdgeInsets inset = self.scrollView.contentInset;
    inset.bottom = overlap + 20;
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
    [self scrollCurrentFirstResponderIntoView];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets inset = UIEdgeInsetsZero;
    self.scrollView.contentInset = inset;
    self.scrollView.scrollIndicatorInsets = inset;
}

- (void)scrollCurrentFirstResponderIntoView {
    UIView *firstResponder = [self firstResponderInView:self.contentView];
    if (firstResponder) {
        [self scrollViewToVisible:firstResponder animated:YES];
    }
}

- (UIView *)firstResponderInView:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *firstResponder = [self firstResponderInView:subview];
        if (firstResponder) {
            return firstResponder;
        }
    }
    return nil;
}

- (void)scrollViewToVisible:(UIView *)view animated:(BOOL)animated {
    if (!view || !view.superview) {
        return;
    }
    [self.view layoutIfNeeded];
    CGRect rect = [view convertRect:view.bounds toView:self.scrollView];
    rect = CGRectInset(rect, 0, -24);
    [self.scrollView scrollRectToVisible:rect animated:animated];
}

- (void)cancelButtonDidTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)coverButtonDidTap {
    self.pickingImageIndex = kCommunityPublishImageCover;
    [self showImagePickerSheet];
}

- (void)addSectionButtonDidTap {
    if (self.sectionImages.count >= 3) {
        [self.view makeToast:LLLLLL(@"CommunityPublish_MaxSectionsTip") duration:1.2 position:CSToastPositionCenter];
        return;
    }
    self.pickingImageIndex = self.sectionImages.count;
    [self showImagePickerSheet];
}

- (void)sectionImageDidTap:(UITapGestureRecognizer *)gesture {
    UIImageView *imageView = (UIImageView *)gesture.view;
    if (!imageView.image) {
        return;
    }
    UIViewController *previewVC = [[UIViewController alloc] init];
    previewVC.view.backgroundColor = UIColor.blackColor;
    UIImageView *previewImageView = [[UIImageView alloc] initWithImage:imageView.image];
    previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    [previewVC.view addSubview:previewImageView];
    [NSLayoutConstraint activateConstraints:@[
        [previewImageView.topAnchor constraintEqualToAnchor:previewVC.view.topAnchor],
        [previewImageView.leadingAnchor constraintEqualToAnchor:previewVC.view.leadingAnchor],
        [previewImageView.trailingAnchor constraintEqualToAnchor:previewVC.view.trailingAnchor],
        [previewImageView.bottomAnchor constraintEqualToAnchor:previewVC.view.bottomAnchor],
    ]];
    [self presentViewController:previewVC animated:YES completion:nil];
}

- (void)sectionImageLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    NSInteger index = gesture.view.tag;
    if (index < 0 || index >= self.sectionImages.count) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Community_Delete") style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [self syncSectionTextsFromViews];
        [self.sectionImages removeObjectAtIndex:index];
        if (index < self.sectionImageUrls.count) {
            [self.sectionImageUrls removeObjectAtIndex:index];
        }
        if (index < self.sectionTexts.count) {
            [self.sectionTexts removeObjectAtIndex:index];
        }
        [self renderSections];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"CommunityPublish_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showImagePickerSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"CommunityPublish_TakePhoto") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"CommunityPublish_ChooseFromAlbum") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"CommunityPublish_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (!image) {
            return;
        }
        if (self.pickingImageIndex == kCommunityPublishImageCover) {
            self.coverImage = image;
            self.coverImageUrl = @"";
            [self.coverButton setBackgroundImage:[self imageByAspectFillImage:image targetSize:CGSizeMake(CGRectGetWidth(self.coverButton.bounds), CGRectGetHeight(self.coverButton.bounds))] forState:UIControlStateNormal];
            self.coverImageView.hidden = YES;
            self.coverPlaceholderLabel.hidden = YES;
        } else {
            if (self.pickingImageIndex < self.sectionImages.count) {
                self.sectionImages[self.pickingImageIndex] = image;
                if (self.pickingImageIndex < self.sectionImageUrls.count) {
                    self.sectionImageUrls[self.pickingImageIndex] = @"";
                }
            } else if (self.sectionImages.count < 3) {
                [self.sectionImages addObject:image];
                [self.sectionImageUrls addObject:@""];
                [self.sectionTexts addObject:@""];
            }
            [self renderSections];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollViewToVisible:self.addSectionButton animated:YES];
            });
        }
        [self updateSubmitState];
    }];
}

- (UIImage *)imageByAspectFillImage:(UIImage *)image targetSize:(CGSize)targetSize {
    if (!image || targetSize.width <= 0 || targetSize.height <= 0) {
        return image;
    }
    CGFloat scale = MAX(targetSize.width / image.size.width, targetSize.height / image.size.height);
    CGSize scaledSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    CGRect drawRect = CGRectMake((targetSize.width - scaledSize.width) / 2.0,
                                 (targetSize.height - scaledSize.height) / 2.0,
                                 scaledSize.width,
                                 scaledSize.height);
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, UIScreen.mainScreen.scale);
    [image drawInRect:drawRect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result ?: image;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)renderSections {
    [self syncSectionTextsFromViews];
    for (UIView *view in self.sectionsStackView.arrangedSubviews) {
        [self.sectionsStackView removeArrangedSubview:view];
        if (view != self.addSectionContainerView) {
            [view removeFromSuperview];
        }
    }
    [self.sectionTextViews removeAllObjects];

    for (NSInteger i = 0; i < self.sectionImages.count; i++) {
        UIView *sectionView = [[UIView alloc] init];
        sectionView.translatesAutoresizingMaskIntoConstraints = NO;

        id imageObject = i < self.sectionImages.count ? self.sectionImages[i] : nil;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[imageObject isKindOfClass:UIImage.class] ? imageObject : nil];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        imageView.tag = i;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sectionImageDidTap:)]];
        [imageView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sectionImageLongPressed:)]];
        [sectionView addSubview:imageView];
        if (![imageObject isKindOfClass:UIImage.class] && i < self.sectionImageUrls.count) {
            [imageView sd_setImageWithURL:URL(self.sectionImageUrls[i]) placeholderImage:nil options:SDWebImageScaleDownLargeImages];
        }

        UNDJKWIOKDPlaceholderTextView *textView = [[UNDJKWIOKDPlaceholderTextView alloc] init];
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.font = PINGFANG_M(14);
        textView.textColor = RGBA(0x222222);
        textView.placeholder = LLLLLL(@"CommunityPublish_SummaryPlaceholder");
        textView.placeholderColor = RGBA(0x888888);
        textView.text = i < self.sectionTexts.count ? self.sectionTexts[i] : @"";
        textView.delegate = self;
        textView.scrollEnabled = NO;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        [sectionView addSubview:textView];
        [self.sectionTextViews addObject:textView];

        [NSLayoutConstraint activateConstraints:@[
            [imageView.topAnchor constraintEqualToAnchor:sectionView.topAnchor],
            [imageView.leadingAnchor constraintEqualToAnchor:sectionView.leadingAnchor],
            [imageView.widthAnchor constraintEqualToConstant:100],
            [imageView.heightAnchor constraintEqualToConstant:100],

            [textView.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:20],
            [textView.leadingAnchor constraintEqualToAnchor:sectionView.leadingAnchor],
            [textView.trailingAnchor constraintEqualToAnchor:sectionView.trailingAnchor],
            [textView.heightAnchor constraintGreaterThanOrEqualToConstant:80],
            [textView.bottomAnchor constraintEqualToAnchor:sectionView.bottomAnchor],
        ]];
        [self.sectionsStackView addArrangedSubview:sectionView];
    }
    self.addSectionContainerView.hidden = self.sectionImages.count >= 3;
    [self.sectionsStackView addArrangedSubview:self.addSectionContainerView];
}

- (void)syncSectionTextsFromViews {
    if (self.sectionTextViews.count == 0) {
        return;
    }
    for (NSInteger i = 0; i < self.sectionTextViews.count; i++) {
        if (i < self.sectionTexts.count) {
            self.sectionTexts[i] = self.sectionTextViews[i].text ?: @"";
        }
    }
}

- (void)applyEditingArticleIfNeeded {
    if (!self.articleToEdit) {
        return;
    }

    [self.submitButton setTitle:LLLLLL(@"CommunityPublish_Update") forState:UIControlStateNormal];
    self.titleField.text = self.articleToEdit.title ?: @"";
    self.summaryTextView.text = self.articleToEdit.summary ?: @"";
    self.coverImageUrl = self.articleToEdit.cover ?: @"";
    if (self.coverImageUrl.length > 0) {
        self.coverImageView.hidden = YES;
        self.coverPlaceholderLabel.hidden = YES;
        __weak typeof(self) weakSelf = self;
        [[SDWebImageManager sharedManager] loadImageWithURL:URL(self.coverImageUrl)
                                                    options:SDWebImageScaleDownLargeImages
                                                   progress:nil
                                                  completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (!image || !finished) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.coverButton setBackgroundImage:[weakSelf imageByAspectFillImage:image targetSize:CGSizeMake(CGRectGetWidth(weakSelf.coverButton.bounds), CGRectGetHeight(weakSelf.coverButton.bounds))] forState:UIControlStateNormal];
            });
        }];
    }

    [self.sectionImages removeAllObjects];
    [self.sectionImageUrls removeAllObjects];
    [self.sectionTexts removeAllObjects];
    for (id item in self.articleToEdit.contents) {
        WFCCCommunityContent *content = nil;
        if ([item isKindOfClass:WFCCCommunityContent.class]) {
            content = item;
        } else if ([item isKindOfClass:NSDictionary.class]) {
            content = [WFCCCommunityContent mj_objectWithKeyValues:item];
        }
        if (!content || content.imageUrl.length == 0 || self.sectionImages.count >= 3) {
            continue;
        }
        [self.sectionImages addObject:NSNull.null];
        [self.sectionImageUrls addObject:content.imageUrl ?: @""];
        [self.sectionTexts addObject:content.text ?: @""];
    }
    [self renderSections];

    self.linkEnabled = self.articleToEdit.linkText.length > 0 || self.articleToEdit.linkUrl.length > 0;
    self.linkTextField.text = self.articleToEdit.linkText ?: @"";
    self.linkUrlField.text = self.articleToEdit.linkUrl ?: @"";
    [self updateLinkSectionState];
}

- (void)textDidChange {
    [self updateSubmitState];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self scrollViewToVisible:textField animated:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self scrollViewToVisible:textView animated:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    NSInteger index = [self.sectionTextViews indexOfObject:textView];
    if (index != NSNotFound && index < self.sectionTexts.count) {
        self.sectionTexts[index] = textView.text ?: @"";
    }
    [self updateSubmitState];
}

- (NSString *)trimmedString:(NSString *)string {
    return [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
}

- (void)updateSubmitState {
    BOOL hasCover = self.coverImage || self.coverImageUrl.length > 0;
    BOOL valid = hasCover && [self trimmedString:self.titleField.text].length > 0 && [self trimmedString:self.summaryTextView.text].length > 0;
    self.submitButton.enabled = valid && !self.submitting;
}

- (void)submitButtonDidTap {
    if (!self.submitButton.enabled || self.submitting) {
        return;
    }
    self.submitting = YES;
    [self updateSubmitState];
    [self.view endEditing:YES];
    [self syncSectionTextsFromViews];
    [self showSubmittingHUD];

    __weak typeof(self) weakSelf = self;
    [self prepareImageUrlsWithCompletion:^(NSString *coverUrl, NSArray<NSString *> *sectionUrls, NSString *errorMessage) {
        if (errorMessage.length > 0) {
            weakSelf.submitting = NO;
            [weakSelf hideSubmittingHUD];
            [weakSelf updateSubmitState];
            [weakSelf.view makeToast:errorMessage duration:1.2 position:CSToastPositionCenter];
            return;
        }
        [weakSelf submitArticleWithCoverUrl:coverUrl sectionImageUrls:sectionUrls];
    }];
}

- (void)prepareImageUrlsWithCompletion:(void(^)(NSString *coverUrl, NSArray<NSString *> *sectionUrls, NSString *errorMessage))completion {
    __weak typeof(self) weakSelf = self;
    void (^prepareSections)(NSString *) = ^(NSString *coverUrl) {
        [weakSelf prepareSectionImageUrlsAtIndex:0 urls:[NSMutableArray array] completion:^(NSArray<NSString *> *sectionUrls, NSString *errorMessage) {
            completion(coverUrl, sectionUrls, errorMessage);
        }];
    };

    if (self.coverImage) {
        [self uploadImage:self.coverImage index:0 completion:^(NSString *url, NSString *errorMessage) {
            if (errorMessage.length > 0) {
                completion(nil, nil, errorMessage);
                return;
            }
            prepareSections(url ?: @"");
        }];
        return;
    }

    if (self.coverImageUrl.length > 0) {
        prepareSections(self.coverImageUrl);
        return;
    }

    completion(nil, nil, LLLLLL(@"CommunityPublish_ImageUploadFailed"));
}

- (void)prepareSectionImageUrlsAtIndex:(NSInteger)index urls:(NSMutableArray<NSString *> *)urls completion:(void(^)(NSArray<NSString *> *sectionUrls, NSString *errorMessage))completion {
    if (index >= self.sectionImages.count) {
        completion(urls, nil);
        return;
    }

    id imageObject = self.sectionImages[index];
    if ([imageObject isKindOfClass:UIImage.class]) {
        [self uploadImage:imageObject index:index + 1 completion:^(NSString *url, NSString *errorMessage) {
            if (errorMessage.length > 0) {
                completion(nil, errorMessage);
                return;
            }
            [urls addObject:url ?: @""];
            [self prepareSectionImageUrlsAtIndex:index + 1 urls:urls completion:completion];
        }];
        return;
    }

    NSString *existingUrl = index < self.sectionImageUrls.count ? self.sectionImageUrls[index] : @"";
    [urls addObject:existingUrl ?: @""];
    [self prepareSectionImageUrlsAtIndex:index + 1 urls:urls completion:completion];
}

- (void)uploadImage:(UIImage *)image index:(NSInteger)index completion:(void(^)(NSString *url, NSString *errorMessage))completion {
    NSData *data = UIImageJPEGRepresentation(image, 0.82);
    if (!data) {
        completion(nil, LLLLLL(@"CommunityPublish_ImageProcessFailed"));
        return;
    }

    NSString *fileName = [NSString stringWithFormat:@"community_%lld_%ld.jpg", (long long)(NSDate.date.timeIntervalSince1970 * 1000), (long)index];
    [[AppService sharedAppService] generateUploadFile:fileName success:^(NSString *uploadUrl, NSString *requestUrl) {
        [[AppService sharedAppService] uploadData:data url:uploadUrl remoteUrl:requestUrl success:^(NSString *remoteUrl) {
            completion(remoteUrl ?: @"", nil);
        } progress:nil fail:^(__unused int error_code) {
            completion(nil, LLLLLL(@"CommunityPublish_ImageUploadFailed"));
        }];
    } error:^(__unused int errCode, NSString *message) {
        completion(nil, message.length > 0 ? message : LLLLLL(@"CommunityPublish_ImageUploadFailed"));
    }];
}

- (void)uploadImages:(NSArray<UIImage *> *)images completion:(void(^)(NSArray<NSString *> *urls, NSString *errorMessage))completion {
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    [self uploadImages:images index:0 urls:urls completion:completion];
}

- (void)uploadImages:(NSArray<UIImage *> *)images index:(NSInteger)index urls:(NSMutableArray<NSString *> *)urls completion:(void(^)(NSArray<NSString *> *urls, NSString *errorMessage))completion {
    if (index >= images.count) {
        completion(urls, nil);
        return;
    }

    UIImage *image = images[index];
    NSData *data = UIImageJPEGRepresentation(image, 0.82);
    if (!data) {
        completion(nil, LLLLLL(@"CommunityPublish_ImageProcessFailed"));
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"community_%lld_%ld.jpg", (long long)(NSDate.date.timeIntervalSince1970 * 1000), (long)index];
    [[AppService sharedAppService] generateUploadFile:fileName success:^(NSString *uploadUrl, NSString *requestUrl) {
        [[AppService sharedAppService] uploadData:data url:uploadUrl remoteUrl:requestUrl success:^(NSString *remoteUrl) {
            [urls addObject:remoteUrl ?: @""];
            [self uploadImages:images index:index + 1 urls:urls completion:completion];
        } progress:nil fail:^(__unused int error_code) {
            completion(nil, LLLLLL(@"CommunityPublish_ImageUploadFailed"));
        }];
    } error:^(__unused int errCode, NSString *message) {
        completion(nil, message.length > 0 ? message : LLLLLL(@"CommunityPublish_ImageUploadFailed"));
    }];
}

- (void)submitArticleWithCoverUrl:(NSString *)coverUrl sectionImageUrls:(NSArray<NSString *> *)sectionImageUrls {
    if (coverUrl.length == 0) {
        self.submitting = NO;
        [self hideSubmittingHUD];
        [self updateSubmitState];
        [self.view makeToast:LLLLLL(@"CommunityPublish_ImageUploadFailed") duration:1.2 position:CSToastPositionCenter];
        return;
    }

    NSMutableArray *contents = [NSMutableArray array];
    for (NSInteger i = 0; i < self.sectionImages.count; i++) {
        NSString *imageUrl = i < sectionImageUrls.count ? sectionImageUrls[i] : @"";
        NSString *text = i < self.sectionTexts.count ? [self trimmedString:self.sectionTexts[i]] : @"";
        if (imageUrl.length > 0) {
            [contents addObject:@{@"imageUrl": imageUrl, @"text": text ?: @""}];
        }
    }

    NSMutableDictionary *param = [@{
        @"cover": coverUrl ?: @"",
        @"title": [self trimmedString:self.titleField.text],
        @"summary": [self trimmedString:self.summaryTextView.text],
        @"contents": contents
    } mutableCopy];
    if (self.articleToEdit.articleId.length > 0) {
        param[@"articleId"] = @([self.articleToEdit.articleId longLongValue]);
    }

    NSString *linkText = [self trimmedString:self.linkTextField.text];
    NSString *linkUrl = [self trimmedString:self.linkUrlField.text];
    if (self.linkEnabled && (linkText.length > 0 || linkUrl.length > 0)) {
        param[@"linkText"] = linkText;
        param[@"linkUrl"] = linkUrl;
    }

    __weak typeof(self) weakSelf = self;
    void (^successBlock)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.submitting = NO;
            [weakSelf hideSubmittingHUD];
            if (weakSelf.publishSuccessBlock) {
                weakSelf.publishSuccessBlock();
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    };
    void (^errorBlock)(int, NSString *) = ^(__unused int errCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.submitting = NO;
            [weakSelf hideSubmittingHUD];
            [weakSelf updateSubmitState];
            [weakSelf.view makeToast:(message.length > 0 ? message : LLLLLL(@"CommunityPublish_PublishFailed")) duration:1.2 position:CSToastPositionCenter];
        });
    };
    if (self.articleToEdit) {
        [[AppService sharedAppService] communityArticleUpdate:param success:successBlock error:errorBlock];
    } else {
        [[AppService sharedAppService] communityArticleCreate:param success:successBlock error:errorBlock];
    }
}

- (void)showSubmittingHUD {
    if (self.submittingHUD) {
        return;
    }
    self.submittingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.submittingHUD.removeFromSuperViewOnHide = YES;
    self.submittingHUD.label.text = LLLLLL(@"CommunityPublish_Publishing");
}

- (void)hideSubmittingHUD {
    [self.submittingHUD hideAnimated:YES];
    self.submittingHUD = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
