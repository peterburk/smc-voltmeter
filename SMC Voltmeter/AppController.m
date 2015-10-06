//
//  AppController.m
//  SMC Voltmeter
//  Peter Burkimsher
//  peterburk@gmail.com
//  2015-04-20
//
//  SMC part based on SMCFanControl
//  Graphing part based on GraphKitDemo from Dave Jewell/CocoaSecrets.
//
//

#import "AppController.h"
#import "smc.h"

/*
 * AppController: Everything happens in here
 */
@implementation AppController

/*
 * createDummyData: Initialise arrays for graphing
 */
- (void) createDummyData
{
//	_voltageValues = [[NSMutableArray arrayWithObjects:	[NSNumber numberWithDouble: 20],
    _voltageValues = [[NSMutableArray arrayWithObjects:
																							nil] retain];
	
	_dummyTimes =	[[NSMutableArray arrayWithObjects:	[NSNumber numberWithDouble: 0],
																							nil] retain];
}

/*
 * dataSetClass: Make the graph a line, rather than a pie chart or column graph
 * @return Class GRLineDataSet, from the undocumented GraphKit
 */
- (Class) dataSetClass
{
	// Available: GRXYDataSet, GRPieDataSet, GRAreaDataSet, GRLineDataSet, GRColumnDataSet
	return [GRLineDataSet class];
}

/*
 * awakeFromNib: Start the app, initialising arrays and the SMC kernel calls
 */
- (void) awakeFromNib
{
    // Set default values for the triggering fields
    [triggerVoltageField setStringValue:@"1.0"];
    [triggerTimeField setStringValue:@"1"];
    
    [downCommandField setStringValue:@"osascript -e \\\"tell application \\\\\\\"Finder\\\\\\\" to display dialog \\\\\\\"down\\\\\\\"\\\""];
    
    [upCommandField setStringValue:@"osascript -e \\\"tell application \\\\\\\"Finder\\\\\\\" to display dialog \\\\\\\"up\\\\\\\"\\\""];
    
    // Set up the arrays for graphing
	[self createDummyData];
	
    // Set up the graph
///	GRDataSet * dataSet = [[[self dataSetClass] alloc] initWithOwnerChart: _chartView];
	GRXYDataSet * dataSet = [[[self dataSetClass] alloc] initWithOwnerChart: _chartView];
	[dataSet setProperty: [NSNumber numberWithInt: 1] forKey: GRDataSetDrawPlotLine];
	//[dataSet setProperty: [NSNumber numberWithInt: 90] forKey: GRDataSetPieStartAngle];
    
    
    // Hide markers
    [dataSet setProperty: [NSNumber numberWithInt: 0] forKey: @"GRDataSetDrawMarkers"];

	[_chartView setProperty: [NSNumber numberWithInt: 0] forKey: GRChartDrawBackground];
    
    // Background colour
	//[_chartView setProperty:[NSColor blackColor] forKey:@"GRChartBackgroundColor"];
    
    // No shadow on data line
    [_chartView setProperty:[NSNumber numberWithInt:0] forKey:@"GRDataSetDrawShadow"];

    
	// Force the Y-axis to display from 19, because the voltage is usually around 20V. Comment out to autoscale. 
	// GRAxes * axes = [_chartView axes];
	//[axes setProperty: [NSNumber numberWithInt: 19] forKey: @"GRAxesYPlotMin"];
	//[axes setProperty: [NSNumber numberWithInt: 20] forKey: @"GRAxesFixedYPlotMin"];
	
    // Add the data to the chart
	[_chartView addDataSet: dataSet loadData: YES];
	[dataSet release];
    
    // Initialise the SMC kernel calls
    smc_init();
    
    // Refresh the voltage measurement every second (the SMC section doesn't support any faster, I've tried)
    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self selector:@selector(SMCPrintVoltage) userInfo:nil repeats:YES];

    
} // end awakeFromNib


// Delegate methods for GRChartView

/*
 * numberOfElementsForDataSet: Set the chart size based on the number of items in the array
 * @param GRChartView* chartView: The graph itself
 *        GRDataSet* dataSet: The data set of the graph
 * @return NSInteger: The count of numbers in the array (not the data set?)
 */
- (NSInteger) chart: (GRChartView *) chartView numberOfElementsForDataSet: (GRDataSet *) dataSet
{
	return [_voltageValues count];
} // end numberOfElementsForDataSet

/*
 * yValueForDataSet: Set the chart's Y axis based on the value of the element selected
 * @param GRChartView* chartView: The graph itself
 *        GRDataSet* yValueForDataSet: The data set of the graph
 *        NSInteger element: The offset in the array of the element to base the Y axis off. 
 * @return double: The value of the item in the array
 */
- (double) chart: (GRChartView *) chartView yValueForDataSet: (GRDataSet *) dataSet element: (NSInteger) element
{
	return [[_voltageValues objectAtIndex: element] doubleValue];
} // end yValueForDataSet


/*
 * colorForDataSet: Set the chart's colour (unused)
 * @param GRChartView* chartView: The graph itself
 *        GRDataSet* yValueForDataSet: The data set of the graph
 *        NSInteger element: The offset in an array of colours. 
 * @return NSColor: The colour for this element
 */
- (NSColor *) chart: (GRChartView *) chartView colorForDataSet: (GRDataSet *) dataSet element: (NSInteger) element
{
	return [_dummyTimes objectAtIndex: 0];
	//return [_dummyTimes objectAtIndex: element];
} // end colorForDataSet

/*
 * checkTriggers: Look at the sampled data to see if we should run a command.
 */
- (void) checkTriggers
{
    // Find the length of the array
    NSInteger numberReadings = [_voltageValues count];

    // Minus one for the last item in the array
    numberReadings = numberReadings - 1;
    
    // The start of the range that we should average
    NSInteger triggerTimeValue = [triggerTimeField integerValue];
    NSInteger itemTwoStart = numberReadings - triggerTimeValue;
    
    // Don't try to read before 0 in the array
    if (itemTwoStart < 0)
    {
        itemTwoStart = 0;
    }
    
    // The average value of the second reading
    double itemTwoValue = 0;
    
    // Sum the values for the second reading
    for (int currentItem = itemTwoStart; currentItem < numberReadings; currentItem++)
    {
        // Record the current value within the range
        double thisValue = [[_voltageValues objectAtIndex:currentItem] doubleValue];
        
        // Add the value to the second item value
        itemTwoValue = itemTwoValue + thisValue;
    }
    
    // Take the average of the second reading
    itemTwoValue = itemTwoValue / triggerTimeValue;
    
    // Read the value of item one, the item before item two
    NSInteger itemOneStart = itemTwoStart - triggerTimeValue;
    
    // Don't try to read before 0 in the array
    if (itemOneStart < 0)
    {
        itemOneStart = 0;
    }
    
    // The average value of the first reading
    double itemOneValue = 0;
    
    // Sum the values for the first reading
    for (int currentItem = itemOneStart; currentItem < itemTwoStart; currentItem++)
    {
        // Record the current value within the range
        double thisValue = [[_voltageValues objectAtIndex:currentItem] doubleValue];
        
        // Add the value to the first item value
        itemOneValue = itemOneValue + thisValue;
    }
    
    // Take the average of the first reading
    itemOneValue = itemOneValue / triggerTimeValue;

    
    // How much voltage difference should cause a trigger?
    double triggerVoltage = [[triggerVoltageField stringValue] doubleValue];
    
    
    // If item one is greater than item two, the voltage went down
    if (itemOneValue > itemTwoValue)
    {
        // If the difference is larger than the trigger voltage change
        if ((itemOneValue - itemTwoValue) > triggerVoltage)
        {
            // Debug log to the history field
            //[self addToHistory:[NSString stringWithFormat:@"down %f %f", itemOneValue, itemTwoValue]];
            
            // Run a script when the voltage goes down
            [self changeDown];
        } // end if the voltage change is large enough
        
    } // end if moving down
    
    
    // If item two is greater than item one, the voltage went up
    if (itemTwoValue > itemOneValue)
    {
        // If the difference is larger than the trigger voltage change
        if ((itemTwoValue - itemOneValue) > triggerVoltage)
        {
            // Debug log to the history field
            //[self addToHistory:[NSString stringWithFormat:@"up %f %f", itemOneValue, itemTwoValue]];
            
            // Run a script when the voltage goes up
            [self changeUp];
        } // end if the voltage change is large enough
        
    } // end if moving up
    
} // end checkTriggers


/*
 * changeDown: Run a command when the voltage changes downwards.
 */
- (void) changeDown
{
    
    // A shell script wrapped in AppleScript wrapped in Cocoa. Nasty, but cleaner than NSTask.
    NSString *downScriptFieldValue = [downCommandField stringValue];
    
    NSString *downScript = [NSString stringWithFormat:@"do shell script \"%@\"", downScriptFieldValue];

    // Debug log
    //[self addToHistory:downScript];
    
    NSAppleScript *downScriptAS = [[NSAppleScript alloc] initWithSource: downScript];
    NSAppleEventDescriptor* returnValue = [downScriptAS executeAndReturnError:nil];
    
    [downScriptAS release];

} // end changeDown


/*
 * changeUp: Run a command when the voltage changes upwards.
 */
- (void) changeUp
{
    // A shell script wrapped in AppleScript wrapped in Cocoa. Nasty, but cleaner than NSTask.
    NSString *upScriptFieldValue = [upCommandField stringValue];
    
    NSString *upScript = [NSString stringWithFormat:@"do shell script \"%@\"", upScriptFieldValue];
    
    // Debug log
    //[self addToHistory:upScript];
    
    NSAppleScript *upScriptAS = [[NSAppleScript alloc] initWithSource: upScript];
    NSAppleEventDescriptor* returnValue = [upScriptAS executeAndReturnError:nil];
    
} // end changeUp


/*
 * addToHistory: Adds a string to the history field.
 */
- (void) addToHistory: (NSString*) thisValueString
{
    NSString* pastVoltages = [voltageHistory string];
    pastVoltages = [NSString stringWithFormat:@"%@\n%@", pastVoltages, thisValueString];
    [voltageHistory setString:pastVoltages];
} // end addToHistory


/*
 * SMCPrintVoltage: Ask the kernel for the current voltage at the MagSafe port, and put it on the graph. 
 */
- (void) SMCPrintVoltage
{
    // The value of the voltage reading
    SMCVal_t      val;
    // The itime when the voltage was read. 
    //struct timespec tim;
    //struct timespec tim2;
    //tim.tv_sec  = 0;
    // 300 ms
    //    tim.tv_nsec = 300000000L;
    
    //while (1)
    //{
    
    // Read the value of the MagSafe input voltage using SMC functions. 
    memset(&val, 0, sizeof(SMCVal_t));
    SMCReadKey("VD0R", &val);
    
    //    printVal(val);
    
    //printf("%.8f %u\n", ((SInt16)ntohs(*(UInt16*)val.bytes)) / 1024.0, (unsigned)time(NULL));
    
    // Convert the voltage reading to a readable number.
    NSNumber* thisValueDouble = [NSNumber numberWithDouble:((SInt16)ntohs(*(UInt16*)val.bytes)) / 1024.0];
    
    // Also record a timestamp. 
    NSNumber* thisTimeDouble = [NSNumber numberWithDouble:(unsigned)time(NULL)];
    
    // Put the measurement and timestamp together into a string. 
    NSString* thisValueString = [NSString stringWithFormat:@"%@ %@", thisValueDouble, thisTimeDouble];
    
    // Set the current voltage label
    [voltageLabel setStringValue:thisValueString];
    
    // Append the reading to the voltage history text field. 
    [self addToHistory:thisValueString];
    
    // Add the reading to the voltage array
    [_voltageValues addObject:thisValueDouble];
    
    // We don't really care about timestamps so much. 
    //[_dummyTimes addObject:thisTimeDouble];
    
    // Check for triggering conditions
    [self checkTriggers];
    
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
} // end SMCPrintVoltage


// The kernel connection
io_connect_t g_conn = 0;

// Cache kernel calls
int g_keyInfoCacheCount = 0;
OSSpinLock g_keyInfoSpinLock = 0;


// Cache the keyInfo to lower the energy impact of SMCReadKey() / SMCReadKey2()
#define KEY_INFO_CACHE_SIZE 100
struct {
    UInt32 key;
    SMCKeyData_keyInfo_t keyInfo;
} g_keyInfoCache[KEY_INFO_CACHE_SIZE];

/*
 * _ultostr: Convert UInt32 values to four-character strings
 * @param char* str: The string to set with the integer value
 *        UInt32: The integer to turn into a string
 */
void _ultostr(char *str, UInt32 val)
{
    // Start the string with a blank character
    str[0] = '\0';
    
    // Build the string using shifted values
    sprintf(str, "%c%c%c%c",
            (unsigned int) val >> 24,
            (unsigned int) val >> 16,
            (unsigned int) val >> 8,
            (unsigned int) val);
} // end _ultostr


/*
 * _strtoul: Convert string values to integers
 * @param char* str: The string with the integer value to read
 *        int size: The number of bytes of the integer
 *        int base: The base of the integer
 * @return UInt32: The integer result
 */
UInt32 _strtoul(char *str, int size, int base)
{
    // Add the values into a total
    UInt32 total = 0;
    int currentByte;
    
    // For every byte in the integer
    for (currentByte = 0; currentByte < size; currentByte++)
    {
        // Support hex conversion instead of string conversion
        if (base == 16)
        {
            total += str[currentByte] << (size - 1 - currentByte) * 8;
        } else {
            total += ((unsigned char) (str[currentByte]) << (size - 1 - currentByte) * 8);
        } // end if hex
        
    } // end for every byte in the integer
    
    // Return the integer value of the string
    return total;
    
} // end _strtoul

/*
 * SMCCall2: Make a kernel-level call to the SMC. 
 * @param int index: The memory index to read.
 *        SMCKeyData_t *inputStructure: The structure of the item we're trying to read.
 *        SMCKeyData_t *outputStructure: The structure of the item we're trying to read. 
 *        io_connect_t conn: The kernel connection.
 * @return kern_return_t: The result of the kernel call.
 */
kern_return_t SMCCall2(int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure,io_connect_t conn)
{
    // The size of the input and output structures
    size_t   structureInputSize;
    size_t   structureOutputSize;
    structureInputSize = sizeof(SMCKeyData_t);
    structureOutputSize = sizeof(SMCKeyData_t);
    
    // Call the kernel with the structures as givens
    return IOConnectCallStructMethod(conn, index, inputStructure, structureInputSize, outputStructure, &structureOutputSize);
} // end SMCCall2


/*
 * SMCGetKeyInfo: Provides key info (not the value), using a cache to dramatically improve the energy impact of smcFanControl.
 * @param UInt32 key: The key (name) of the SMC item to read. 
 *        SMCKeyData_keyInfo_t* keyInfo: Information about the structure of the key we need. 
 *        io_connect_t conn: The kernel connection.
 * @return kern_return_t: The result of the kernel call. 
 */
kern_return_t SMCGetKeyInfo(UInt32 key, SMCKeyData_keyInfo_t* keyInfo, io_connect_t conn)
{
    // Set up input and output structures for storing the result
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    
    // Hopefully the SMC result will be successful, if we set everything up correctly.
    kern_return_t result = kIOReturnSuccess;
    
    // Check the cache
    int currentItem = 0;
    
    OSSpinLockLock(&g_keyInfoSpinLock);
    
    for (; currentItem < g_keyInfoCacheCount; ++currentItem)
    {
        if (key == g_keyInfoCache[currentItem].key)
        {
            *keyInfo = g_keyInfoCache[currentItem].keyInfo;
            break;
        }
    } // end for the key being in the cache
    
    // If the reading we want is not in the cache, query the kerne;
    if (currentItem == g_keyInfoCacheCount)
    {
        // Not in cache, must look it up.
        memset(&inputStructure, 0, sizeof(inputStructure));
        memset(&outputStructure, 0, sizeof(outputStructure));
        
        // Set up the structure
        inputStructure.key = key;
        inputStructure.data8 = SMC_CMD_READ_KEYINFO;
        
        // Make a kernel call to read the information about the key. 
        result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
        
        // If it was successful, save the result and update the cache
        if (result == kIOReturnSuccess)
        {
            // Set the result in the output structure
            *keyInfo = outputStructure.keyInfo;
            
            // Update the cache
            if (g_keyInfoCacheCount < KEY_INFO_CACHE_SIZE)
            {
                g_keyInfoCache[g_keyInfoCacheCount].key = key;
                g_keyInfoCache[g_keyInfoCacheCount].keyInfo = outputStructure.keyInfo;
                ++g_keyInfoCacheCount;
            }
        } // end if it was successful
        
    } // end cache
    
    OSSpinLockUnlock(&g_keyInfoSpinLock);
    
    // Return the value read from the SMC
    return result;
} // end SMCGetKeyInfo



/*
 * SMCReadKey: Calls SMCReadKey2 with the global kernel connection.
 * @param UInt32Char_t key: The key (name) of the SMC item to read. 
 *        SMCVal_t *val: Information about the structure of the value we need.
 * @return kern_return_t: The result of the kernel call. 
 */
kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val)
{
    return SMCReadKey2(key, val, g_conn);
} // end SMCReadKey


/*
 * SMCReadKey2: Provides key info. 
 * @param UInt32Char_t key: The key (name) of the SMC item to read.
 *        SMCVal_t *val: Information about the structure of the key we need.
 *        io_connect_t conn: The kernel connection.
 * @return kern_return_t: The result of the kernel call.
 */
kern_return_t SMCReadKey2(UInt32Char_t key, SMCVal_t *val,io_connect_t conn)
{
    // Store the result of the kernel call
    kern_return_t result;
    
    // The structure of the kernel call request and result
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    // Allocate memory for the kernel call
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));
    
    // Encode the string of the input structure to an integer in hex. 
    inputStructure.key = _strtoul(key, 4, 16);
    sprintf(val->key, key);
    
    // Get information about the key's structure
    result = SMCGetKeyInfo(inputStructure.key, &outputStructure.keyInfo, conn);
    
    // If the kernel call failed, return the error
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    // Build the output structure from the result and the input structure.
    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;
    
    // Request the key's value from the kernel. 
    result = SMCCall2(KERNEL_INDEX_SMC, &inputStructure, &outputStructure,conn);
    
    // If the kernel call failed, return the error
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    // Copy the result to the output structure
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    
    return kIOReturnSuccess;
} // end SMCReadKey2

/*
 * SMCOpen: Open a kernel connection to the SMC. 
 * @param io_connect_t conn: The SMC connection.
 * @return kern_return_t: The result of the kernel call.
 */
kern_return_t SMCOpen(io_connect_t *conn)
{
    // The result
    kern_return_t result;
    
    // The ports to connect to the kernel and SMC
    mach_port_t   masterPort;
    io_iterator_t iterator;
    io_object_t   device;
    
    // Connect to the kernel
	IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    // Find the SMC
    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    
    // Error finding the service
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceGetMatchingServices() = %08x\n", result);
        return 1;
    }
    
    // Connect to the SMC using the next available port
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    
    // Error finding the SMC
    if (device == 0)
    {
        printf("Error: no SMC found\n");
        return 1;
    }
    
    // Connect to the service on the SMC. 
    result = IOServiceOpen(device, mach_task_self(), 0, conn);
    IOObjectRelease(device);
    
    // Error connecting to the service
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceOpen() = %08x\n", result);
        return 1;
    }
    
    // Return the result
    return kIOReturnSuccess;
} // end SMCOpen

/*
 * SMCClose: Close the kernel connection.
 * @param io_connect_t conn: The kernel connection to close. 
 * @return kern_return_t: The result of the kernel call.
 */
kern_return_t SMCClose(io_connect_t conn)
{
    return IOServiceClose(conn);
} // end SMCClose

/*
 * smc_init: Open a connection to the SMC
 */
void smc_init()
{
	SMCOpen(&g_conn);
} // end smc_init

/*
 * smc_close: Open a connection to the SMC
 */
void smc_close()
{
	SMCClose(g_conn);
} // end smc_close



// end implementation AppController
@end
