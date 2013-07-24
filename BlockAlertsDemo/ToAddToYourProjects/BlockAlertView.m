//
//  BlockAlertView.m
//
//

#import "BlockAlertView.h"
#import "BlockBackground.h"
#import "BlockUI.h"

@implementation BlockAlertView

@synthesize view = _view;
@synthesize backgroundImage = _backgroundImage;
@synthesize vignetteBackground = _vignetteBackground;
@synthesize direction = _direction;

static UIImage *background = nil;
static UIImage *backgroundlandscape = nil;
static UIFont *titleFont = nil;
static UIFont *messageFont = nil;
static UIFont *buttonFont = nil;


#pragma mark - init

+ (void)initialize
{
    if (self == [BlockAlertView class])
    {
        background = [UIImage imageNamed:kAlertViewBackground];
        background = [[background stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight] retain];
        
        backgroundlandscape = [UIImage imageNamed:kAlertViewBackgroundLandscape];
        backgroundlandscape = [[backgroundlandscape stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight] retain];
        
        titleFont = [kAlertViewTitleFont retain];
        messageFont = [kAlertViewMessageFont retain];
        buttonFont = [kAlertViewButtonFont retain];
    }
}

+ (BlockAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message
{
    return [[[BlockAlertView alloc] initWithTitle:title message:message] autorelease];
}

+ (void)showInfoAlertWithTitle:(NSString *)title message:(NSString *)message
{
    BlockAlertView *alert = [[BlockAlertView alloc] initWithTitle:title message:message];
    [alert setCancelButtonWithTitle:NSLocalizedString(@"Dismiss", nil) block:nil];
    [alert show];
    [alert release];
}

+ (void)showErrorAlert:(NSError *)error
{
    BlockAlertView *alert = [[BlockAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The operation did not complete successfully: %@", nil), error]];
    [alert setCancelButtonWithTitle:@"Dismiss" block:nil];
    [alert show];
    [alert release];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (void)addComponents:(CGRect)frame {
    if (_title)
    {
        CGSize size = [_title sizeWithFont:titleFont
                         constrainedToSize:CGSizeMake(frame.size.width-kAlertViewBorder*2, 1000)
                             lineBreakMode:NSLineBreakByWordWrapping];
        
        UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewBorder, _height, frame.size.width-kAlertViewBorder*2, size.height)];
        labelView.font = titleFont;
        labelView.numberOfLines = 0;
        labelView.lineBreakMode = NSLineBreakByWordWrapping;
        labelView.textColor = kAlertViewTitleTextColor;
        labelView.backgroundColor = [UIColor clearColor];
        labelView.textAlignment = NSTextAlignmentCenter;
        labelView.shadowColor = kAlertViewTitleShadowColor;
        labelView.shadowOffset = kAlertViewTitleShadowOffset;
        labelView.text = _title;
        [_view addSubview:labelView];
        [labelView release];
        
        _height += size.height + kAlertViewBorder;
    }
    
    if (_message)
    {
        CGSize size = [_message sizeWithFont:messageFont
                           constrainedToSize:CGSizeMake(frame.size.width-kAlertViewBorder*2, 1000)
                               lineBreakMode:NSLineBreakByWordWrapping];
        
        UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewBorder, _height, frame.size.width-kAlertViewBorder*2, size.height)];
        labelView.font = messageFont;
        labelView.numberOfLines = 0;
        labelView.lineBreakMode = NSLineBreakByWordWrapping;
        labelView.textColor = kAlertViewMessageTextColor;
        labelView.backgroundColor = [UIColor clearColor];
        labelView.textAlignment = NSTextAlignmentCenter;
        labelView.shadowColor = kAlertViewMessageShadowColor;
        labelView.shadowOffset = kAlertViewMessageShadowOffset;
        labelView.text = _message;
        [_view addSubview:labelView];
        [labelView release];
        
        _height += size.height + kAlertViewBorder;
    }
}

- (void)setupDisplay
{
    [[_view subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    
    UIWindow *parentView = [BlockBackground sharedInstance];
    CGRect frame = parentView.bounds;
    frame.origin.x = floorf((frame.size.width - background.size.width) * 0.5);
    frame.size.width = background.size.width;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        frame.size.width += 150;
        frame.origin.x -= 75;
    }
    
    _view.frame = frame;
    
    _height = kAlertViewBorder + 15;
    
    if (NeedsLandscapePhoneTweaks) {
        _height -= 15; // landscape phones need to trimmed a bit
    }

    [self addComponents:frame];

    if (_shown)
        [self show];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    self = [super init];
    
    if (self)
    {
        _title = [title copy];
        _message = [message copy];
        
        _view = [[UIView alloc] init];
        
        _view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        _blocks = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(setupDisplay) 
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification 
                                                   object:nil];   
        
        if ([self class] == [BlockAlertView class])
            [self setupDisplay];
        
        _vignetteBackground = NO;
        
        _direction = BlockAnimateFromTop;
    }
    
    return self;
}

- (void)dealloc 
{
    [_title release];
    [_message release];
    [_backgroundImage release];
    [_view release];
    [_blocks release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title color:(NSString*)color block:(void (^)())block 
{
    [_blocks addObject:[NSArray arrayWithObjects:
                        block ? [[block copy] autorelease] : [NSNull null],
                        title,
                        color,
                        nil]];
}

- (void)addButtonWithTitle:(NSString *)title block:(void (^)())block 
{
    [self addButtonWithTitle:title color:@"gray" block:block];
}

- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)())block 
{
    [self addButtonWithTitle:title color:@"black" block:block];
}

- (void)setDestructiveButtonWithTitle:(NSString *)title block:(void (^)())block
{
    [self addButtonWithTitle:title color:@"red" block:block];
}

- (void)addButtonWithTitle:(NSString *)title imageIdentifier:(NSString*)identifier block:(void (^)())block {
    [self addButtonWithTitle:title color:identifier block:block];
}

- (void)show
{
    _shown = YES;
    
    BOOL isSecondButton = NO;
    NSUInteger index = 0;
    for (NSUInteger i = 0; i < _blocks.count; i++)
    {
        NSArray *block = [_blocks objectAtIndex:i];
        NSString *title = [block objectAtIndex:1];
        NSString *color = [block objectAtIndex:2];

        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button.png", color]];
        image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
        
        UIImage *highlightedImage = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button-highlighted.png", color]];
        
        highlightedImage = [highlightedImage stretchableImageWithLeftCapWidth:(int)(highlightedImage.size.width+1)>>1 topCapHeight:0];
        
        CGFloat maxHalfWidth = floorf((_view.bounds.size.width-kAlertViewBorder*3)*0.5);
        CGFloat width = _view.bounds.size.width-kAlertViewBorder*2;
        CGFloat xOffset = kAlertViewBorder;
        if (isSecondButton)
        {
            width = maxHalfWidth;
            xOffset = width + kAlertViewBorder * 2;
            isSecondButton = NO;
        }
        else if (i + 1 < _blocks.count)
        {
            // In this case there's another button.
            // Let's check if they fit on the same line.
            CGSize size = [title sizeWithFont:buttonFont 
                                  minFontSize:10 
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width-kAlertViewBorder*2 
                                lineBreakMode:NSLineBreakByClipping];
            
            if (size.width < maxHalfWidth - kAlertViewBorder)
            {
                // It might fit. Check the next Button
                NSArray *block2 = [_blocks objectAtIndex:i+1];
                NSString *title2 = [block2 objectAtIndex:1];
                size = [title2 sizeWithFont:buttonFont 
                                minFontSize:10 
                             actualFontSize:nil
                                   forWidth:_view.bounds.size.width-kAlertViewBorder*2 
                              lineBreakMode:NSLineBreakByClipping];
                
                if (size.width < maxHalfWidth - kAlertViewBorder)
                {
                    // They'll fit!
                    isSecondButton = YES;  // For the next iteration
                    width = maxHalfWidth;
                }
            }
        }
        else if (_blocks.count  == 1)
        {
            // In this case this is the ony button. We'll size according to the text
            CGSize size = [title sizeWithFont:buttonFont
                                  minFontSize:10
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width-kAlertViewBorder*2
                                lineBreakMode:NSLineBreakByClipping];
            
            size.width = MAX(size.width, 80);
            if (size.width + 2 * kAlertViewBorder < width)
            {
                width = size.width + 2 * kAlertViewBorder;
                xOffset = floorf((_view.bounds.size.width - width) * 0.5);
            }
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(xOffset, _height, width, kAlertButtonHeight);
        button.titleLabel.font = buttonFont;
        if (IOS_LESS_THAN_6) {
#pragma clan diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            button.titleLabel.minimumFontSize = 10;
#pragma clan diagnostic pop
        }
        else {
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.adjustsLetterSpacingToFitWidth = YES;
            button.titleLabel.minimumScaleFactor = 0.1;
        }
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.shadowOffset = kAlertViewButtonShadowOffset;
        button.backgroundColor = [UIColor clearColor];
        button.tag = i+1;
        
        [button setBackgroundImage:image forState:UIControlStateNormal];
        if (highlightedImage)
        {
            [button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        }
        [button setTitleColor:kAlertViewButtonTextColor forState:UIControlStateNormal];
        [button setTitleShadowColor:kAlertViewButtonShadowColor forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal];
        button.accessibilityLabel = title;
        
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [_view addSubview:button];
        
        if (!isSecondButton)
            _height += kAlertButtonHeight + kAlertViewBorder;
        
        index++;
    }

    //_height += 10;  // Margin for the shadow // not sure where this came from, but it's making things look strange (I don't see a shadow, either)
    
    if (_height < background.size.height)
    {
        CGFloat offset = background.size.height - _height;
        _height = background.size.height;
        CGRect frame;
        for (NSUInteger i = 0; i < _blocks.count; i++)
        {
            UIButton *btn = (UIButton *)[_view viewWithTag:i+1];
            frame = btn.frame;
            frame.origin.y += offset;
            btn.frame = frame;
        }
    }
    
    CGRect frame = _view.frame;
    frame.size.height = _height;
    switch (_direction) {
        case BlockAnimateFromTop:
            frame.origin.y = - _height;
            break;
            
        case BlockAnimateFromBottom:
            frame.origin.y = _height * 2;
            break;
            
        case BlockAnimateFromLeft:
            frame.origin.y = floorf(([BlockBackground sharedInstance].bounds.size.height - _height) * 0.5);
            frame.origin.x = -frame.size.width;
            break;
            
        case BlockAnimateFromRight:
            frame.origin.y = floorf(([BlockBackground sharedInstance].bounds.size.height - _height) * 0.5);
            frame.origin.x = frame.size.width * 2;
            break;
            
        case BlockAnimateFadeIn:
            frame.origin.y = floorf(([BlockBackground sharedInstance].bounds.size.height - _height) * 0.5);
            break;
            
        default:
            frame.origin.y = -_height;
            break;
    }
    _view.frame = frame;
    
    UIImageView *modalBackground = [[UIImageView alloc] initWithFrame:_view.bounds];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        modalBackground.image = backgroundlandscape;
    else
        modalBackground.image = background;

    modalBackground.contentMode = UIViewContentModeScaleToFill;
    modalBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_view insertSubview:modalBackground atIndex:0];
    [modalBackground release];
    
    if (_backgroundImage)
    {
        [BlockBackground sharedInstance].backgroundImage = _backgroundImage;
        [_backgroundImage release];
        _backgroundImage = nil;
    }
    
    [BlockBackground sharedInstance].vignetteBackground = _vignetteBackground;
    [[BlockBackground sharedInstance] addToMainWindow:_view];

    _cancelBounce = NO;
    
    __block CGPoint firstPoint = _view.center;
    __block CGPoint secondPoint = _view.center;
    
    switch (_direction) {
        case BlockAnimateFromTop:
            firstPoint.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5) + kAlertViewBounce;
            secondPoint.y = firstPoint.y - kAlertViewBounce;
            break;
            
        case BlockAnimateFromBottom:
            firstPoint.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5) - kAlertViewBounce;
            secondPoint.y = firstPoint.y + kAlertViewBounce;
            break;
            
        case BlockAnimateFromLeft:
            firstPoint.x = floorf([BlockBackground sharedInstance].bounds.size.width * 0.5) + kAlertViewBounce;
            secondPoint.x = firstPoint.x - kAlertViewBounce;
            break;
            
        case BlockAnimateFromRight:
            firstPoint.x = floorf([BlockBackground sharedInstance].bounds.size.width * 0.5) - kAlertViewBounce;
            secondPoint.x = firstPoint.x + kAlertViewBounce;
            break;
            
        case BlockAnimateFadeIn:
            [self animateFadeIn];
            break;
            
        default:
            firstPoint.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5) - kAlertViewBounce;
            secondPoint.y = firstPoint.y - kAlertViewBounce;
            break;
    }
    if (_direction != BlockAnimateFadeIn) {
        [self animateEnteringAlertTo:firstPoint thenTo:secondPoint];
    }
    
    [self retain];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated 
{
    _shown = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (buttonIndex >= 0 && buttonIndex < [_blocks count])
    {
        id obj = [[_blocks objectAtIndex: buttonIndex] objectAtIndex:0];
        if (![obj isEqual:[NSNull null]])
        {
            ((void (^)())obj)();
        }
    }
    
    if (animated)
    {
        CGPoint firstPoint = _view.center;
        CGPoint secondPoint = _view.center;
        CGRect frame = _view.frame;
        
        switch (_direction) {
            case BlockAnimateFromTop:
                firstPoint.y += kAlertViewBounce;
                secondPoint.y = -frame.size.height - kAlertViewBounce;
                break;
                
            case BlockAnimateFromBottom:
                firstPoint.y -= kAlertViewBounce;
                secondPoint.y = (frame.size.height * 2) + kAlertViewBounce;
                break;
                
            case BlockAnimateFromLeft:
                firstPoint.x += kAlertViewBounce;
                secondPoint.x = -frame.size.width - kAlertViewBounce;
                break;
                
            case BlockAnimateFromRight:
                firstPoint.x -= kAlertViewBounce;
                secondPoint.x = (frame.size.width * 2) + kAlertViewBounce;
                break;
                
            case BlockAnimateFadeIn:
                [self animateFadeOut];
                break;
                
            default:
                firstPoint.y += kAlertViewBounce;
                secondPoint.y = -frame.size.height - kAlertViewBounce;
                break;
        }
        if (_direction != BlockAnimateFadeIn) {
            [self animateExitingAlertTo:firstPoint thenTo:secondPoint];
        }
    }
    else
    {
        [[BlockBackground sharedInstance] removeView:_view];
        [_view release]; _view = nil;
        [self autorelease];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Animations
- (void)animateEnteringAlertTo:(CGPoint)firstPoint thenTo:(CGPoint)secondPoint
{
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [BlockBackground sharedInstance].alpha = 1.0f;
                         _view.center = firstPoint;
                     }
                     completion:^(BOOL finished) {
                         if (_cancelBounce) return;
                         
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:0
                                          animations:^{
                                              _view.center = secondPoint;
                                          }
                                          completion:^(BOOL finished) {
                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"AlertViewFinishedAnimations" object:self];
                                          }];
                     }];
}

- (void)animateExitingAlertTo:(CGPoint)firstPoint thenTo:(CGPoint)secondPoint
{
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:0
                     animations:^{
                         _view.center = firstPoint;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.4
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              _view.center = secondPoint;
                                              [[BlockBackground sharedInstance] reduceAlphaIfEmpty];
                                          }
                                          completion:^(BOOL finished) {
                                              [[BlockBackground sharedInstance] removeView:_view];
                                              [_view release]; _view = nil;
                                              [self autorelease];
                                          }];
                     }];
}

- (void)animateFadeIn
{
    NSLog(@"fadingin");
    [UIView animateWithDuration:0.4 animations:^{
        [BlockBackground sharedInstance].alpha = 1.0f;
    }
    completion:^(BOOL finished) {
         [[NSNotificationCenter defaultCenter] postNotificationName:@"AlertViewFinishedAnimations" object:self];
    }];
}

- (void)animateFadeOut
{
    [UIView animateWithDuration:0.4 animations:^{
        [[BlockBackground sharedInstance] reduceAlphaIfEmpty];
    }
    completion:^(BOOL finished) {
        [[BlockBackground sharedInstance] removeView:_view];
        [_view release]; _view = nil;
        [self autorelease];
    }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Action

- (void)buttonClicked:(id)sender 
{
    /* Run the button's block */
    int buttonIndex = [(UIButton *)sender tag] - 1;
    [self dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

@end
