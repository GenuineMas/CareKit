//
//  OCKAdherenceChartView.m
//  CareKit
//
//  Created by Yuan Zhu on 2/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKGroupedBarChartView.h"
#import "OCKChartLegendView.h"


// #define LAYOUT_DEBUG 1

static const CGFloat BarPointSize = 8.0;

@interface OCKGroupedBarChartBar : NSObject

@property (nonatomic, copy) NSNumber *value;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) UIColor *color;

@end

@implementation OCKGroupedBarChartBar
@end

@interface OCKGroupedBarChartBarGroup : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray<OCKGroupedBarChartBar *> *bars;

@end

@implementation OCKGroupedBarChartBarGroup
@end

@interface OCKGroupedBarChartBarType : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIColor *color;

@end

@implementation OCKGroupedBarChartBarType
@end


@interface OCKChartBarView : UIView

- (instancetype)initWithBar:(OCKGroupedBarChartBar *)bar maxValue:(double)maxValue;

@property (nonatomic, strong) OCKGroupedBarChartBar *bar;

- (void)animationWithDuration:(NSTimeInterval)duration;

@end

@implementation OCKChartBarView {
    double _maxValue;
    UIView *_barView;
    CAShapeLayer *_barLayer;
    UILabel *_valueLabel;
}

- (instancetype)initWithBar:(OCKGroupedBarChartBar *)bar maxValue:(double)maxValue {
    self = [super init];
    if (self) {
        _maxValue = maxValue;
        _bar = bar;
        [self prepareView];
    }
    return self;
}

- (void)animationWithDuration:(NSTimeInterval)duration {
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @0;
        animation.toValue = @1;
        animation.duration = duration * _bar.value.doubleValue/_maxValue;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];;
        animation.fillMode = kCAFillModeBoth;
        animation.removedOnCompletion = true;
        
        [_barLayer addAnimation:animation forKey:animation.keyPath];
    }
    
    {
        CGPoint position = CGPointMake(_valueLabel.layer.position.x, _valueLabel.layer.position.y);
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
        
        animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, position.y)];
        animation.toValue = [NSValue valueWithCGPoint:position];
        
        animation.duration = duration * _bar.value.doubleValue/_maxValue;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];;
        animation.fillMode = kCAFillModeBoth;
        animation.removedOnCompletion = true;
        
        [_valueLabel.layer addAnimation:animation forKey:animation.keyPath];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat barWidth = _barView.bounds.size.width;
    CGFloat barHeight = _barView.bounds.size.height;
    if (_barLayer == nil || _barLayer.bounds.size.width != barWidth) {
        
        [_barLayer removeFromSuperlayer];
        _barLayer = [[CAShapeLayer alloc] init];
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(0, barHeight/2)];
        [path addLineToPoint:CGPointMake(barWidth, barHeight/2)];
        path.lineWidth = barHeight;
        
        _barLayer.path = path.CGPath;
        _barLayer.strokeColor = _bar.color.CGColor;
        _barLayer.lineWidth = barHeight;
        [_barView.layer addSublayer:_barLayer];
    }
}


- (void)prepareView {
    
    _barView = [UIView new];
#if LAYOUT_DEBUG
    _barView.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.2];
#endif
    _barView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _valueLabel = [UILabel new];
    _valueLabel.text = _bar.text;
    _valueLabel.textColor = _bar.color;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.font = [UIFont systemFontOfSize:BarPointSize];
    
    [self addSubview:_barView];
    [self addSubview:_valueLabel];
    
    NSDictionary *views = @{@"barView":_barView, @"valueLabel":_valueLabel};
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[barView]-10.0-[valueLabel]"
                                                          options:NSLayoutFormatDirectionLeadingToTrailing
                                                          metrics:nil
                                                            views:views]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_barView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:0.88*_bar.value.doubleValue/_maxValue
                                                         constant:0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_barView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:BarPointSize]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_valueLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_barView
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.5]];
    
    [_valueLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[barView]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
    
}

@end

@interface OCKGroupedBarChartBarGroupView : UIView

- (instancetype)initWithGroup:(OCKGroupedBarChartBarGroup *)group maxValue:(double)maxValue;

@property (nonatomic, strong) OCKGroupedBarChartBarGroup *group;

@property (nonatomic, strong) UIView *labelBox;

- (void)animationWithDuration:(NSTimeInterval)duration;

@end

@implementation OCKGroupedBarChartBarGroupView {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UIView *_barBox;
    double _maxValue;
}

- (instancetype)initWithGroup:(OCKGroupedBarChartBarGroup *)group maxValue:(double)maxValue {
    NSParameterAssert(group);
    self = [super init];
    if (self) {
        _group = group;
        _maxValue = maxValue;
        [self prepareView];
    }
    return self;
}

- (void)animationWithDuration:(NSTimeInterval)duration {
    for (OCKChartBarView *barView in _barBox.subviews) {
        [barView animationWithDuration:duration];
    }
}

- (void)prepareView {
    
    _labelBox = [UIView new];
    _labelBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_labelBox];
    
    _titleLabel = [UILabel new];
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.text = _group.title;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:12.0];
    [_labelBox addSubview:_titleLabel];
    
    _textLabel = [UILabel new];
    _textLabel.text = _group.text;
    _textLabel.adjustsFontSizeToFitWidth = YES;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.font = [UIFont systemFontOfSize:10.0];
    _textLabel.textColor = [UIColor lightGrayColor];
    [_labelBox addSubview:_textLabel];
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *labels = @{@"_titleLabel":_titleLabel, @"_textLabel":_textLabel};
    
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_textLabel
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_titleLabel
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_labelBox
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_textLabel
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0 constant:0.0]];
    
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:labels]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_textLabel]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:labels]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_textLabel
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    _barBox = [UIView new];
    _barBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_barBox];
    
    NSDictionary *boxes = @{@"_barBox":_barBox, @"_labelBox":_labelBox};
    
#if LAYOUT_DEBUG
    _barBox.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.1];
    _labelBox.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.1];
#endif
    
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_labelBox]-[_barBox]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:boxes]];
    
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_barBox
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_barBox
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0 constant:0.0]];
    
    [_barBox setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [_labelBox setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    for (OCKGroupedBarChartBar *bar in _group.bars) {
        OCKChartBarView *barView = [[OCKChartBarView alloc] initWithBar:bar maxValue:_maxValue];
        barView.translatesAutoresizingMaskIntoConstraints = NO;
        UIView *viewAbove = _barBox.subviews.lastObject;
        [_barBox addSubview:barView];

#if LAYOUT_DEBUG
        barView.backgroundColor = [UIColor lightGrayColor];
#endif
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[barView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:@{@"barView": barView}]];
        
        
        if (viewAbove) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0 constant:0.0]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeHeight
                                                               multiplier:1.0 constant:0.0]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_barBox
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0 constant:0.0]];
            
           
        }
    }
    
    if (_barBox.subviews.lastObject) {
        OCKChartBarView *barView = _barBox.subviews.lastObject;
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_barBox
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:barView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0 constant:0.0]];
        
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}


@end

@interface OCKGroupedBarChartView ()

@end

@implementation OCKGroupedBarChartView {
    NSMutableArray<OCKGroupedBarChartBarGroup *> *_barGroups;
    NSMutableArray<OCKGroupedBarChartBarType *> *_barTypes;
    
    NSMutableArray<NSLayoutConstraint *> *_constraints;
    
    UIView *_groupsBox;
    OCKChartLegendView *_legendsView;
    
    BOOL _shouldInvalidateLegendViewIntrinsicContentSize;
    
    double _maxValue;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (void)setDataSource:(id<OCKGroupedBarChartViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    if (_dataSource) {
        NSUInteger barsPerGroup = [_dataSource numberOfDataSeriesInChartView:self];
        
        _barTypes = [NSMutableArray new];
        for (NSUInteger barIndex = 0; barIndex < barsPerGroup; barIndex++) {
            OCKGroupedBarChartBarType *barType = [OCKGroupedBarChartBarType new];
            barType.color = [_dataSource chartView:self colorForDataSeries:barIndex];
            barType.name = [_dataSource chartView:self nameForDataSeries:barIndex];
            [_barTypes addObject:barType];
        }
        
        NSUInteger numberOfGroups = [_dataSource numberOfCategoriesPerDataSeriesInChartView:self];
        
        _maxValue = 0;
        _barGroups = [NSMutableArray new];
        for (NSUInteger groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
            OCKGroupedBarChartBarGroup *barGroup = [OCKGroupedBarChartBarGroup new];
            barGroup.title = [_dataSource chartView:self titleForCategory:groupIndex];
            if ([_dataSource respondsToSelector:@selector(chartView:subtitleForCategory:)]) {
                barGroup.text = [_dataSource chartView:self subtitleForCategory:groupIndex];
            }
            
            NSMutableArray *bars = [NSMutableArray new];
            for (NSUInteger barIndex = 0; barIndex < barsPerGroup; barIndex++) {
                OCKGroupedBarChartBar *bar = [OCKGroupedBarChartBar new];
                bar.value = [_dataSource chartView:self valueForCategory:groupIndex inDataSeries:barIndex];
                if (bar.value.doubleValue > _maxValue) {
                    _maxValue = bar.value.doubleValue;
                }
                bar.text = [_dataSource chartView:self valueStringForCategory:groupIndex inDataSeries:barIndex];
                bar.color = _barTypes[barIndex].color;
                [bars addObject:bar];
            }
            
            barGroup.bars = [bars copy];
            
            [_barGroups addObject:barGroup];
        }
    }
    [self recreateViews];
}

- (void)animateWithDuration:(NSTimeInterval)duration {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (OCKGroupedBarChartBarGroupView *groupView in _groupsBox.subviews) {
            [groupView animationWithDuration:duration];
        }
    });

}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_shouldInvalidateLegendViewIntrinsicContentSize) {
        _shouldInvalidateLegendViewIntrinsicContentSize = NO;
        [_legendsView invalidateIntrinsicContentSize];
    }
}

- (void)recreateViews {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    _constraints = [NSMutableArray new];
    
    _groupsBox = [UIView new];
    _groupsBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_groupsBox];
    
    
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_groupsBox]|"
                                                                              options:NSLayoutFormatDirectionLeadingToTrailing
                                                                              metrics:nil
                                                                                views:@{@"_groupsBox": _groupsBox}]];
    
    
    
    _legendsView = [[OCKChartLegendView alloc] initWithTitles:[_barTypes valueForKeyPath:@"name"] colors:[_barTypes valueForKeyPath:@"color"] ];
    _legendsView.labelFont = [UIFont systemFontOfSize:10.0];
    _legendsView.translatesAutoresizingMaskIntoConstraints = NO;
#if LAYOUT_DEBUG
    _legendsView.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
#endif
    _shouldInvalidateLegendViewIntrinsicContentSize = YES;
    [self addSubview:_legendsView];
    
    [_constraints addObject:[NSLayoutConstraint constraintWithItem:_legendsView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0 constant:0.0]];
    
    [_constraints addObject:[NSLayoutConstraint constraintWithItem:_legendsView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0 constant:10.0]];
    
    [_constraints addObject:[NSLayoutConstraint constraintWithItem:_legendsView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0 constant:0.0]];
    
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_groupsBox]-[_legendsView]|"
                                                                              options:NSLayoutFormatDirectionLeadingToTrailing
                                                                              metrics:nil
                                                                                views:@{@"_groupsBox": _groupsBox, @"_legendsView": _legendsView}]];
    
    
    for (OCKGroupedBarChartBarGroup *barGroup in _barGroups) {
        OCKGroupedBarChartBarGroupView *groupView = [[OCKGroupedBarChartBarGroupView alloc] initWithGroup:barGroup maxValue:_maxValue];
        groupView.translatesAutoresizingMaskIntoConstraints = NO;
#if LAYOUT_DEBUG
        groupView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
#endif
        OCKGroupedBarChartBarGroupView *viewAbove = _groupsBox.subviews.lastObject;
        [_groupsBox addSubview:groupView];
        
        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[groupView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:@{@"groupView": groupView}]];
        
        if (viewAbove) {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0 constant:0.0]];
            
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:viewAbove
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1.0 constant:0.0]];
            
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView.labelBox
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:viewAbove.labelBox
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0 constant:0.0]];
            
        } else {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_groupsBox
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0 constant:2.0]];
            
           
        }
        
        [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_groupsBox
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1.0 constant:0.0]];
    
    }
    
    if (self.subviews.lastObject) {
        UIView *lastView = _groupsBox.subviews.lastObject;
        [_constraints addObject:[NSLayoutConstraint constraintWithItem:lastView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_groupsBox
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0 constant:0.0]];
        
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
    
}


@end