//
//  AppController.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 06/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRChartView.h"
#import "GRPieDataSet.h"
#import "GRXYDataSet.h"
#import "GRAreaDataSet.h"
#import "GRLineDataSet.h"
#import "GRColumnDataSet.h"
#import "GRAxes.h"

@interface AppController : NSObject 
{
	IBOutlet	GRChartView * _chartView;
	NSMutableArray * _dummyNumbers;
	NSMutableArray * _dummyTimes;
    IBOutlet NSTextView *voltageHistory;
    IBOutlet NSTextField *voltageLabel;
}

@end
