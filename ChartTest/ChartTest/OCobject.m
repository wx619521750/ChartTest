//
//  OCobject.m
//  ChartTest
//
//  Created by Carlo on 1/23/26.
//

#import "OCobject.h"
#import <UIKit/UIKit.h>
#import "ChartTest-Swift.h"
@interface OCobject()<LineChartViewDelegate>

@end
@implementation OCobject

-(void)test{
    ChartPoint * point = [ChartPoint new];
    ChartModel *model = [[ChartModel alloc] initWithPoints:@[point] type:1];

    LineChartView *view = [LineChartView new];
    view.chartModel = model;
    [view changeDateModeWithMode:DateModeYear];
}

- (void)lineChartViewXRangeChangedWithMin:(double)min max:(double)max{
    
}

- (void)lineChartViewYRangeChangedWithMin:(double)min max:(double)max{
    
}
- (void)lineChartViewDateModeChangedWithMode:(enum DateMode)mode{
    
}
@end
