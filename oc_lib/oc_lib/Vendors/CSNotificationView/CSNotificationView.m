//
//  CSNotificationView.m
//  CSNotificationView
//
//  Created by Christian Schwarz on 01.09.13.
//  Copyright (c) 2013 Christian Schwarz. Check LICENSE.md.
//

#import "CSNotificationView.h"
#import "CSNotificationView_Private.h"

#import "CSLayerStealingBlurView.h"
#import "CSNativeBlurView.h"

@implementation CSNotificationView

#pragma mark + quick presentation

+ (void)showInKeyWindowTintColor:(UIColor *)tintColor
             image:(UIImage*)image
           message:(NSString*)message
          duration:(NSTimeInterval)duration
{
    NSAssert(message, @"'message' must not be nil.");
    
    //如果有正在显示的 则需要等待上一个CSNotificationView消失
    UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
    CSNotificationView *preCSNotificationView = (CSNotificationView *)[keyWindow viewWithTag:kCSNotificationViewTag];
    
    if (preCSNotificationView)return;
    
    
    
    __block CSNotificationView* note = [[CSNotificationView alloc] init];
    note.tag = kCSNotificationViewTag;
    note.tintColor = tintColor;
    note.image = image;
    note.textLabel.text = message;
    
    
    
    void (^completion)() = ^{[note setVisible:NO animated:YES completion:nil];};
    
    [note setVisible:YES animated:YES completion:^{
        double delayInSeconds = duration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            completion();
        });
    }];
    
}

+ (void)showInKeyWindowTintColor:(UIColor *)tintColor
                        font:(UIFont*)font
               textAlignment:(NSTextAlignment)textAlignment
                       image:(UIImage*)image
                     message:(NSString*)message
                    duration:(NSTimeInterval)duration
{
    NSAssert(message, @"'message' must not be nil.");
    
    __block CSNotificationView* note = [[CSNotificationView alloc] init];
    note.tintColor = tintColor;
    note.image = image;
    note.textLabel.font = font;
    note.textLabel.textAlignment = textAlignment;
    note.textLabel.text = message;
    
    void (^completion)() = ^{[note setVisible:NO animated:YES completion:nil];};
    [note setVisible:YES animated:YES completion:^{
        double delayInSeconds = duration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            completion();
        });
    }];
    
}

+ (void)showInKeyWindowWithStyle:(CSNotificationViewStyle)style
           message:(NSString *)message
{
    
    
    [CSNotificationView showInKeyWindowTintColor:
                         [CSNotificationView blurTintColorForStyle:style]
                             image:[CSNotificationView imageForStyle:style]
                           message:message
                          duration:kCSNotificationViewDefaultShowDuration];
    
}

+(void)ShowNotificationViewStyleSuccessInWindow:(NSString *)message
{
    [self showInKeyWindowWithStyle:CSNotificationViewStyleSuccess
                                     message:message];
}

+(void)ShowNotificationViewStyleErrorInWindow:(NSString *)message
{
    [self showInKeyWindowWithStyle:CSNotificationViewStyleError
                       message:message];}

#pragma mark + creators

+ (CSNotificationView*)notificationViewWithTintColor:(UIColor*)tintColor
                                                          image:(UIImage*)image
                                                        message:(NSString*)message
{
    
    CSNotificationView* note = [[CSNotificationView alloc] init];
    note.tintColor = tintColor;
    note.image = image;
    note.textLabel.text = message;
    
    return note;
}

#pragma mark - lifecycle

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        //Blur view
        {
            
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
                //Use native effects
                self.blurView = [[CSNativeBlurView alloc] initWithFrame:CGRectZero];
            } else {
                //Use layer stealing
                self.blurView = [[CSLayerStealingBlurView alloc] initWithFrame:CGRectZero];
            }
            
            self.blurView.userInteractionEnabled = NO;
            self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
            self.blurView.clipsToBounds = NO;
            [self insertSubview:self.blurView atIndex:0];
            
        }
        
        //Content views
        {
            //textLabel
            {
                _textLabel = [[UILabel alloc] init];
                
                _textLabel.textColor = [UIColor whiteColor];
                _textLabel.backgroundColor = [UIColor clearColor];
                _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
            
                _textLabel.numberOfLines = 2;
                _textLabel.minimumScaleFactor = 0.6;
                _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                
                UIFontDescriptor* textLabelFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
                _textLabel.font = [UIFont fontWithDescriptor:textLabelFontDescriptor size:17.0f];
                _textLabel.adjustsFontSizeToFitWidth = YES;
                
                [self addSubview:_textLabel];
            }
            //symbolView
            {
                [self updateSymbolView];
            }
        }
        
        //Interaction
        {
            //Tap gesture
            self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapInView:)];
            [self addGestureRecognizer:self.tapRecognizer];
        }

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}



#pragma mark - layout

- (void)updateConstraints
{
    [self removeConstraints:self.constraints];
    
    NSDictionary* bindings = @{@"blurView":self.blurView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[blurView]|"
                                                                 options:0 metrics:nil views:bindings]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-1)-[blurView]-(-1)-|"
                                                                 options:0 metrics:nil views:bindings]];

    
    CGFloat symbolViewWidth = self.symbolView.tag != kCSNotificationViewEmptySymbolViewTag ?
                                kCSNotificationViewSymbolViewSidelength : 0.0f;
    CGFloat symbolViewHeight = kCSNotificationViewSymbolViewSidelength;
    
    NSDictionary* metrics =
        @{@"symbolViewWidth": [NSNumber numberWithFloat:symbolViewWidth],
          @"symbolViewHeight":[NSNumber numberWithFloat:symbolViewHeight]};
    
    [self addConstraints:[NSLayoutConstraint
        constraintsWithVisualFormat:@"H:|-(4)-[_symbolView(symbolViewWidth)]-(5)-[_textLabel]-(10)-|"
                            options:0
                            metrics:metrics
                              views:NSDictionaryOfVariableBindings(_textLabel, _symbolView)]];
    
    [self addConstraints:[NSLayoutConstraint
        constraintsWithVisualFormat:@"V:[_symbolView(symbolViewHeight)]"
                            options:0
                            metrics:metrics
                                views:NSDictionaryOfVariableBindings(_symbolView)]];
    
    [self addConstraint:[NSLayoutConstraint
                constraintWithItem:_symbolView
                         attribute:NSLayoutAttributeBottom
                         relatedBy:NSLayoutRelationEqual
                            toItem:self
                         attribute:NSLayoutAttributeBottom
                         multiplier:1.0f constant:-3]];
    
    [self addConstraint:[NSLayoutConstraint
        constraintWithItem:_textLabel
                 attribute:NSLayoutAttributeCenterY
                 relatedBy:NSLayoutRelationEqual
                    toItem:_symbolView
                 attribute:NSLayoutAttributeCenterY
                multiplier:1.0f constant:0]];
    
    [super updateConstraints];
}

#pragma mark - tint color

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    [self.blurView setBlurTintColor:tintColor];
    self.contentColor = [self legibleTextColorForBlurTintColor:tintColor];
}

#pragma mark - interaction

-(void)handleTapInView:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.tapHandler && tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.tapHandler();
    }
}

#pragma mark - presentation

- (void)setVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)())completion
{
    
    
    if (_visible != visible) {
        
        NSTimeInterval animationDuration = animated ? 0.3 : 0.0;
        
        CGRect startFrame, endFrame;
        [self animationFramesForVisible:visible startFrame:&startFrame endFrame:&endFrame];
        
        if (!self.superview) {
            self.frame = startFrame;
            
            UIWindow* keyboardWindow = [UIApplication sharedApplication].keyWindow;
            [keyboardWindow addSubview:self];
        }
        
        __block typeof(self) weakself = self;
        [UIView animateWithDuration:animationDuration animations:^{
            [weakself setFrame:endFrame];
        } completion:^(BOOL finished) {
            
            if (!visible) {
                [weakself removeFromSuperview];
            }
            if (completion) {
                completion();
            }
        }];
        
        _visible = visible;
    } else if (completion) {
        completion();
    }
}

- (void)animationFramesForVisible:(BOOL)visible startFrame:(CGRect*)startFrame endFrame:(CGRect*)endFrame
{
    if (startFrame) *startFrame = visible ? [self hiddenFrame]:[self visibleFrame];
    if (endFrame) *endFrame = visible ? [self visibleFrame] : [self hiddenFrame];
}

- (void)dismissWithStyle:(CSNotificationViewStyle)style message:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated
{
    NSParameterAssert(message);

    __block typeof(self) weakself = self;
    [UIView animateWithDuration:0.1 animations:^{

        weakself.showingActivity = NO;
        weakself.image = [CSNotificationView imageForStyle:style];
        weakself.textLabel.text = message;
        weakself.tintColor = [CSNotificationView blurTintColorForStyle:style];
        
    } completion:^(BOOL finished) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakself setVisible:NO animated:animated completion:nil];
        });
    }];
}

#pragma mark - frame calculation

//Workaround as there is a bug: sometimes, when accessing topLayoutGuide, it will render contentSize of UITableViewControllers to be {0, 0}


- (CGRect)visibleFrame
{

    
    CGFloat topLayoutGuideLength = 0;  //[self topLayoutGuideLengthCalculation];
    
    NSArray *windowArray = [[UIApplication sharedApplication] windows];
    UIWindow* keyboardWindow = windowArray[windowArray.count-1];

    CGSize transformedSize = CGSizeApplyAffineTransform(keyboardWindow.frame.size, keyboardWindow.transform);
    CGRect displayFrame = CGRectMake(0, 0, fabs(transformedSize.width),
                                     kCSNotificationViewHeight + topLayoutGuideLength);
    
    return displayFrame;
}

- (CGRect)hiddenFrame
{

    
    CGFloat topLayoutGuideLength = 0; // [self topLayoutGuideLengthCalculation];
    
    NSArray *windowArray = [[UIApplication sharedApplication] windows];
    UIWindow* keyboardWindow = windowArray[windowArray.count-1];

    CGSize transformedSize = CGSizeApplyAffineTransform(keyboardWindow.frame.size, keyboardWindow.transform);
    CGRect offscreenFrame = CGRectMake(0, -kCSNotificationViewHeight - topLayoutGuideLength,
                                       fabs(transformedSize.width),
                                       kCSNotificationViewHeight + topLayoutGuideLength);
    
    return offscreenFrame;
}

- (CGSize)intrinsicContentSize
{
    CGRect currentRect = self.visible ? [self visibleFrame] : [self hiddenFrame];
    return currentRect.size;
}

#pragma mark - symbol view

- (void)updateSymbolView
{
    [self.symbolView removeFromSuperview];
    
    if (self.isShowingActivity) {
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicator.color = self.contentColor;
        [indicator startAnimating];
        _symbolView = indicator;
    } else if (self.image) {
        //Generate UIImageView for symbolView
        UIImageView* imageView = [[UIImageView alloc] init];
        imageView.opaque = NO;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = [self imageFromAlphaChannelOfImage:self.image replacementColor:self.contentColor];
        _symbolView = imageView;
    } else {
        _symbolView = [[UIView alloc] initWithFrame:CGRectZero];
        _symbolView.tag = kCSNotificationViewEmptySymbolViewTag;
    }
    _symbolView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_symbolView];
    [self setNeedsUpdateConstraints];

}

#pragma mark -- image

- (void)setImage:(UIImage *)image
{
    if (![_image isEqual:image]) {
        _image = image;
        [self updateSymbolView];
    }
}

#pragma mark -- activity

- (void)setShowingActivity:(BOOL)showingActivity
{
    if (_showingActivity != showingActivity) {
        _showingActivity = showingActivity;
        [self updateSymbolView];
    }
}


#pragma mark - content color

- (void)setContentColor:(UIColor *)contentColor
{
    if (![_contentColor isEqual:contentColor]) {
        _contentColor = contentColor;
        self.textLabel.textColor = _contentColor;
        [self updateSymbolView];
    }
}

#pragma mark helpers

- (UIColor*)legibleTextColorForBlurTintColor:(UIColor*)blurTintColor
{
    CGFloat r, g, b, a;
    BOOL couldConvert = [blurTintColor getRed:&r green:&g blue:&b alpha:&a];
    
    UIColor* textColor = [UIColor whiteColor];
    
    CGFloat average = (r+g+b)/3.0; //Not considering alpha here, transperency is added by toolbar
    if (couldConvert && average > 0.65) //0.65 is mostly gut-feeling
    {
        textColor = [[UIColor alloc] initWithWhite:0.2 alpha:1.0];
    }
    
    return textColor;
}

- (UIImage*)imageFromAlphaChannelOfImage:(UIImage*)image replacementColor:(UIColor*)tintColor
{
    if (!image) return nil;
    NSParameterAssert([tintColor isKindOfClass:[UIColor class]]);
 
    //Credits: https://gist.github.com/omz/1102091
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(c, [tintColor CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (UIImage*)imageForStyle:(CSNotificationViewStyle)style
{
    UIImage* matchedImage = nil;

    switch (style) {
        case CSNotificationViewStyleSuccess:
        {
            NSString *checkmark = [[NSBundle mainBundle] pathForResource:@"checkmark" ofType:@"png"];
            matchedImage = [UIImage imageWithContentsOfFile:checkmark];
            break;
        }
        case CSNotificationViewStyleError:
        {
            NSString *exclamationMark = [[NSBundle mainBundle] pathForResource:@"exclamationMark" ofType:@"png"];
            matchedImage = [UIImage imageWithContentsOfFile:exclamationMark];
            break;
        }
        default:
            break;
    }
    return matchedImage;
}

+ (UIColor*)blurTintColorForStyle:(CSNotificationViewStyle)style
{
    UIColor* blurTintColor;
    switch (style) {
        case CSNotificationViewStyleSuccess:
            blurTintColor = [UIColor colorWithRed:0.21 green:0.72 blue:0.00 alpha:1.0];
            break;
        case CSNotificationViewStyleError:
            blurTintColor = [UIColor redColor];
            break;
        default:
            break;
    }
    return blurTintColor;
}

@end
