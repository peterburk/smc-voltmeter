/*
IOKitInterface.cpp
 
Copyright (C) 2005 Vince Tagle <vtagle@newsguy.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
*/

#include "IOKitInterface.h"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IOEthernetController.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
//#include <IOKit/storage/ata/IOATAStorageDefines.h>
//#include <IOKit/storage/ata/ATASMARTLib.h>
//#include <IOKit/network/IONetworkInterface.h>

std::string	tIOKitInterface::IOKitResults; 
char tIOKitInterface::result[256];
int tIOKitInterface::resultLen;

void GetIORegistryProperty( char *result, int *resultLen, char *serviceClass, CFStringRef key, bool useParent )
{
	mach_port_t machPort;
	kern_return_t kernResult = IOMasterPort( MACH_PORT_NULL, &machPort );
	
	// No result yet
	*resultLen = 0;

	// if we got the master port
	if ( kernResult == KERN_SUCCESS )
	{
		// create a dictionary matching IOPlatformExpertDevice
		CFMutableDictionaryRef classesToMatch = IOServiceMatching( serviceClass );

		// if we are successful
		if (classesToMatch)
		{
			// get the matching services iterator
			io_iterator_t iterator;
			kernResult = IOServiceGetMatchingServices( machPort, classesToMatch, &iterator );

			// if we succeeded
			if ( (kernResult == KERN_SUCCESS) && iterator )
			{
				io_object_t serviceObj;
				bool done = false;
				do
				{
					// get the next item out of the dictionary
					serviceObj = IOIteratorNext( iterator );

					// if it is not NULL
					if (serviceObj)
					{
						if ( useParent )
						{
							kernResult = IORegistryEntryGetParentEntry( serviceObj, kIOServicePlane, &serviceObj );
							if ( kernResult != KERN_SUCCESS )
							{
								printf("IORegistryEntryGetParentEntry Failed\n");
							}
						}
						
						CFTypeRef data = IORegistryEntryCreateCFProperty(
							serviceObj, key, kCFAllocatorDefault, 0 );

						if (data != NULL)
						{
							if ( CFGetTypeID(data) == CFDataGetTypeID() )
							{
								*resultLen = CFDataGetLength((CFDataRef)data);
								const UInt8* rawdata = CFDataGetBytePtr((CFDataRef)data);
								memcpy(result, rawdata, *resultLen);
							}
							else if ( CFGetTypeID(data) == CFStringGetTypeID() )
							{
								*resultLen = CFStringGetLength((CFStringRef)data);
								const char *rawdata = CFStringGetCStringPtr( (CFStringRef)data, kCFStringEncodingMacRoman );
								strcpy(result, rawdata);
							}

							// Original sample had this +13 stuff in it, perhaps to separate order and serial numbers
//							char dataBuffer[256];
//							memcpy(dataBuffer, rawdata, datalen);
//							sprintf(result, "%s%s", dataBuffer+13, dataBuffer);

							CFRelease(data);
							done = true;
						}
					}
				} while (serviceObj != NULL && done == false);

				IOObjectRelease(serviceObj);
			}
		}
	}
}

void GetHDRegistryInfo(std::string& result, CFStringRef blackBoxProperty)
{
	mach_port_t machPort;
	kern_return_t kernResult = IOMasterPort( MACH_PORT_NULL, &machPort );
	
	// No result yet

	// if we got the master port
	if ( kernResult == KERN_SUCCESS )
	{
		// create a dictionary matching IOPlatformExpertDevice
		CFMutableDictionaryRef classesToMatch = IOServiceMatching( "IOATABlockStorageDevice" );

		// if we are successful
		if (classesToMatch)
		{
			// get the matching services iterator
			io_iterator_t iterator;
			kernResult = IOServiceGetMatchingServices( machPort, classesToMatch, &iterator );

			// if we succeeded
			if ( (kernResult == KERN_SUCCESS) && iterator )
			{
				io_object_t serviceObj;
				bool done = false;
				do
				{
					// get the next item out of the dictionary
					serviceObj = IOIteratorNext( iterator );

					// if it is not NULL
					if (serviceObj)
					{
						CFMutableDictionaryRef dict = NULL;
						IOReturn err = IORegistryEntryCreateCFProperties(
							serviceObj, &dict, kCFAllocatorDefault, 0 );

						if ( err == kIOReturnSuccess )
						{
							CFStringRef product;
							CFDictionaryRef deviceDict = NULL;
							deviceDict = (CFDictionaryRef)CFDictionaryGetValue(
								dict, CFSTR(kIOPropertyDeviceCharacteristicsKey) );
							product = (CFStringRef)CFDictionaryGetValue( deviceDict, blackBoxProperty );
							
							const char* productStr = CFStringGetCStringPtr(product, kCFStringEncodingMacRoman); 
							if ( productStr )
							{
								result = productStr; 
							}

							CFRelease(dict);
							//CFRelease(deviceDict);
							done = true;
						}
					}
				} while (serviceObj != NULL && done == false);

				IOObjectRelease(serviceObj);
			}
		}
	}
}

const std::string& tIOKitInterface::mGetMachineModel()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformExpertDevice", CFSTR("model"), false );
	IOKitResults = &result[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetSerialNumber()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformExpertDevice", CFSTR("serial-number"), false );
	IOKitResults = &result[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetBusSpeed()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformExpertDevice", CFSTR("clock-frequency"), false );
	
	char tempBuffer[256]; 
	sprintf(tempBuffer, "%#x", *(int*)result); 
	IOKitResults = &tempBuffer[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetCPUVersion()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformDevice", CFSTR("cpu-version"), false );
	
	char tempBuffer[256]; 
	sprintf(tempBuffer, "%#x", *(int*)result); 
	IOKitResults = &tempBuffer[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetCPUSpeed()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformDevice", CFSTR("clock-frequency"), false );
	
	char tempBuffer[256]; 
	sprintf(tempBuffer, "%#x", *(int*)result); 
	IOKitResults = &tempBuffer[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetCPUInfo()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformDevice", CFSTR("cpu-info"), false );
	
	char tempBuffer[256]; 
	sprintf(tempBuffer, "%#x", *(int*)result); 
	IOKitResults = &tempBuffer[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetCPUTimebaseFrequency()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "IOPlatformDevice", CFSTR("timebase-frequency"), false );
	
	char tempBuffer[256]; 
	sprintf(tempBuffer, "%#x", *(int*)result); 
	IOKitResults = &tempBuffer[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetEthernetMACAddress()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, kIOEthernetInterfaceClass, CFSTR(kIOMACAddress), true );
	
	IOKitResults = ""; 
	char tempBuffer[256]; 
	int loop;
	for ( loop = 0; loop < resultLen; loop++ )
	{
		sprintf(tempBuffer, "%02x", (unsigned char)result[loop]);
		IOKitResults += &tempBuffer[0];
		
		if ( loop < resultLen - 1 )
		{
			IOKitResults += ':';
		}
	}
	
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetBlackBoxStorageSerialNumber()
{
	result[0] = 0;
	GetIORegistryProperty( result, &resultLen, "ATADeviceNub", CFSTR("device serial"), false );
	IOKitResults = &result[0]; 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetBlackBoxModel()
{
	GetHDRegistryInfo(IOKitResults, CFSTR(kIOPropertyProductNameKey)); 
	return IOKitResults; 
}

const std::string& tIOKitInterface::mGetBlackBoxRevision()
{
	GetHDRegistryInfo(IOKitResults, CFSTR(kIOPropertyProductRevisionLevelKey)); 
	return IOKitResults;
}
