//
//  AppController.m
//  GraphKitDemo
//
//  Created by Dave Jewell on 06/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import "AppController.h"
#import "smc.h"

@implementation AppController

- (void) createDummyData
{
	_dummyNumbers = [[NSMutableArray arrayWithObjects:	[NSNumber numberWithDouble: 20],
																							nil] retain];
	
	_dummyTimes =	[[NSMutableArray arrayWithObjects:	[NSNumber numberWithDouble: 0],
																							nil] retain];
}

- (Class) dataSetClass
{
	// Available: GRXYDataSet, GRPieDataSet, GRAreaDataSet, GRLineDataSet, GRColumnDataSet
	return [GRLineDataSet class];
}

- (void) awakeFromNib
{
	[self createDummyData];
	
	GRDataSet * dataSet = [[[self dataSetClass] alloc] initWithOwnerChart: _chartView];
	[dataSet setProperty: [NSNumber numberWithInt: 1] forKey: GRDataSetDrawPlotLine];
	//[dataSet setProperty: [NSNumber numberWithInt: 90] forKey: GRDataSetPieStartAngle];
	
	[_chartView setProperty: [NSNumber numberWithInt: 0] forKey: GRChartDrawBackground];
	
	// Force the Y-axis to display from zero
	GRAxes * axes = [_chartView axes];
	[axes setProperty: [NSNumber numberWithInt: 19] forKey: @"GRAxesYPlotMin"];
	[axes setProperty: [NSNumber numberWithInt: 20] forKey: @"GRAxesFixedYPlotMin"];
	
	[_chartView addDataSet: dataSet loadData: YES];
	[dataSet release];
    
    smc_init();
    
    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self selector:@selector(SMCPrintVoltage) userInfo:nil repeats:YES];

    
}


// Delegate methods for GRChartView

- (NSInteger) chart: (GRChartView *) chartView numberOfElementsForDataSet: (GRDataSet *) dataSet
{
	return [_dummyNumbers count];
}

- (double) chart: (GRChartView *) chartView yValueForDataSet: (GRDataSet *) dataSet element: (NSInteger) element
{
	return [[_dummyNumbers objectAtIndex: element] doubleValue];
}

- (NSColor *) chart: (GRChartView *) chartView colorForDataSet: (GRDataSet *) dataSet element: (NSInteger) element
{
	return [_dummyTimes objectAtIndex: 0];
	//return [_dummyTimes objectAtIndex: element];
}


- (void) SMCPrintVoltage
{
    SMCVal_t      val;
    struct timespec tim, tim2;
    tim.tv_sec  = 0;
    // 300 ms
    //    tim.tv_nsec = 300000000L;
    
    //while (1)
    //{
    memset(&val, 0, sizeof(SMCVal_t));
    SMCReadKey("VD0R", &val);
    
    //    printVal(val);
    
    //printf("%.8f %u\n", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 1024.0, (unsigned)time(NULL));
    
    NSNumber* thisValueDouble = [NSNumber numberWithDouble:((SInt16)ntohs(*(UInt16*)val.bytes)) / 1024.0];
    NSNumber* thisTimeDouble = [NSNumber numberWithDouble:(unsigned)time(NULL)];
    
    NSString* thisValueString = [NSString stringWithFormat:@"%@ %u", thisValueDouble, (unsigned)time(NULL)];
    
    // Set the current voltage
    [voltageLabel setStringValue:thisValueString];
    
    // Append to the voltage history
    NSString* pastVoltages = [voltageHistory string];
    pastVoltages = [NSString stringWithFormat:@"%@\n%@", pastVoltages, thisValueString];
    [voltageHistory setString:pastVoltages];
    
    [_dummyNumbers addObject:thisValueDouble];
    //[_dummyTimes addObject:thisTimeDouble];

	//GRDataSet * dataSet = [[[self dataSetClass] alloc] initWithOwnerChart: _chartView];
	//[dataSet setProperty: [NSNumber numberWithInt: 1] forKey: GRDataSetDrawPlotLine];
	//[dataSet setProperty: [NSNumber numberWithInt: 90] forKey: GRDataSetPieStartAngle];
	
	//[_chartView setProperty: [NSNumber numberWithInt: 0] forKey: GRChartDrawBackground];
	
	// Force the Y-axis to display from zero
	//GRAxes * axes = [_chartView axes];
	//[axes setProperty: [NSNumber numberWithInt: 0] forKey: @"GRAxesYPlotMin"];
	//[axes setProperty: [NSNumber numberWithInt: 1] forKey: @"GRAxesFixedYPlotMin"];
	
    [_chartView reloadData];
	
	//[_chartView addDataSet: dataSet loadData: YES];
	//[dataSet release];
    
    
    //nanosleep(&tim , &tim2);
    //sleep (1);
    //}
}


io_connect_t g_conn = 0;

int g_keyInfoCacheCount = 0;
OSSpinLock g_keyInfoSpinLock = 0;


// Cache the keyInfo to lower the energy impact of SMCReadKey() / SMCReadKey2()
#define KEY_INFO_CACHE_SIZE 100
struct {
    UInt32 key;
    SMCKeyData_keyInfo_t keyInfo;
} g_keyInfoCache[KEY_INFO_CACHE_SIZE];

void _ultostr(char *str, UInt32 val)
{
    str[0] = '\0';
    sprintf(str, "%c%c%c%c",
            (unsigned int) val >> 24,
            (unsigned int) val >> 16,
            (unsigned int) val >> 8,
            (unsigned int) val);
}

UInt32 _strtoul(char *str, int size, int base)
{
    UInt32 total = 0;
    int i;
    
    for (i = 0; i < size; i++)
    {
        if (base == 16)
            total += str[i] << (size - 1 - i) * 8;
        else
            total += ((unsigned char) (str[i]) << (size - 1 - i) * 8);
    }
    return total;
}


kern_return_t SMCCall2(int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure,io_connect_t conn)
{
    size_t   structureInputSize;
    size_t   structureOutputSize;
    structureInputSize = sizeof(SMCKeyData_t);
    structureOutputSize = sizeof(SMCKeyData_t);
    
    return IOConnectCallStructMethod(conn, index, inputStructure, structureInputSize, outputStructure, &structureOutputSize);
}



// Provides key info, using a cache to dramatically improve the energy impact of smcFanControl
kern_return_t SMCGetKeyInfo(UInt32 key, SMCKeyData_keyInfo_t* keyInfo, io_connect_t conn)
{
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    kern_return_t result = kIOReturnSuccess;
    int i = 0;
    
    OSSpinLockLock(&g_keyInfoSpinLock);
    
    for (; i < g_keyInfoCacheCount; ++i)
    {
        if (key == g_keyInfoCache[i].key)
        {
            *keyInfo = g_keyInfoCache[i].keyInfo;
            break;
        }
    }
    
    if (i == g_keyInfoCacheCount)
    {
        // Not in cache, must look it up.
        memset(&inputStructure, 0, sizeof(inputStructure));
        memset(&outputStructure, 0, sizeof(outputStructure));
        
        inputStructure.key = key;
        inputStructure.data8 = SMC_CMD_READ_KEYINFO;
        
        result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
        if (result == kIOReturnSuccess)
        {
            *keyInfo = outputStructure.keyInfo;
            if (g_keyInfoCacheCount < KEY_INFO_CACHE_SIZE)
            {
                g_keyInfoCache[g_keyInfoCacheCount].key = key;
                g_keyInfoCache[g_keyInfoCacheCount].keyInfo = outputStructure.keyInfo;
                ++g_keyInfoCacheCount;
            }
        }
    }
    
    OSSpinLockUnlock(&g_keyInfoSpinLock);
    
    return result;
}




kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val)
{
    return SMCReadKey2(key, val, g_conn);
}

kern_return_t SMCReadKey2(UInt32Char_t key, SMCVal_t *val,io_connect_t conn)
{
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));
    
    inputStructure.key = _strtoul(key, 4, 16);
    sprintf(val->key, key);
    
    result = SMCGetKeyInfo(inputStructure.key, &outputStructure.keyInfo, conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;
    
    result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure,conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    
    return kIOReturnSuccess;
}


kern_return_t SMCOpen(io_connect_t *conn)
{
    kern_return_t result;
    mach_port_t   masterPort;
    io_iterator_t iterator;
    io_object_t   device;
    
	IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceGetMatchingServices() = %08x\n", result);
        return 1;
    }
    
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0)
    {
        printf("Error: no SMC found\n");
        return 1;
    }
    
    result = IOServiceOpen(device, mach_task_self(), 0, conn);
    IOObjectRelease(device);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceOpen() = %08x\n", result);
        return 1;
    }
    
    return kIOReturnSuccess;
}

kern_return_t SMCClose(io_connect_t conn)
{
    return IOServiceClose(conn);
}

void smc_init(){
	SMCOpen(&g_conn);
}

void smc_close(){
	SMCClose(g_conn);
}



@end
