#!/bin/bash
thisTime=`date +%s`;
thisVoltage=`/Users/peter/bin/System/Voltmeter/smc -l | grep "VD0R" | cut -d ' ' -f 7`
echo "$thisTime,$thisVoltage" >> "/Users/peter/bin/System/Voltmeter/dcLog.txt"
