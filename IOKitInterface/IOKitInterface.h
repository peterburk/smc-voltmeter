/*
IOKitInterface.h
 
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

#ifndef IOKitInterface_h
#define IOKitInterface_h

#include <Carbon/Carbon.h>
#include <string>

class tIOKitInterface
{
public:

	tIOKitInterface() { }
	~tIOKitInterface() { }
	
	static const std::string&	mGetMachineModel(); 
	static const std::string&	mGetSerialNumber();
	static const std::string&	mGetBusSpeed();
	static const std::string&	mGetCPUVersion();
	static const std::string&	mGetCPUSpeed();
	static const std::string&	mGetCPUInfo();
	static const std::string&	mGetCPUTimebaseFrequency();
	static const std::string&	mGetEthernetMACAddress();
	static const std::string&	mGetBlackBoxStorageSerialNumber();
	static const std::string&	mGetBlackBoxModel();
	static const std::string&	mGetBlackBoxRevision();
	
protected:

	static std::string	IOKitResults; 
	static char			result[256];
	static int			resultLen;
}; 

#endif
