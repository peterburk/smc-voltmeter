# SMC Voltmeter

<img class="aligncenter" alt="SMC Voltmeter Logo" src="https://raw.githubusercontent.com/peterburk/smc-voltmeter/master/SMC_Voltmeter_Screenshot.png" width="128">


SMC Voltmeter is an app to watch the input voltage on your MagSafe port, log it, graph it, and trigger scripts based on the voltage changing.

Download it here: 

https://raw.githubusercontent.com/peterburk/smc-voltmeter/master/SMC_Voltmeter.zip

1. Can I measure other voltages except for the power supply?
Yes!
Get a MagSafe wire, cut it in half, and plug in anything you want.
Any voltage less than 8.5V will not trigger the MacBook Pro to charge. Therefore it is safe to measure voltages of most battery-powered devices.
This can be used as a simple analogue sensor, and the scripts let you change things on your computer based on the input.
For example, this app could be used with a variable resistor to change the system volume.
2. How fast can the voltmeter update?
I’ve done many experiments with a command-line tool based on SMCFanControl, and the fastest that I could get it to run was 1 sample per second.
3. What kinds of scripts can I run?

Bash scripts are triggered by the voltage going up or down. If you want to write a more complex script, make it in another file and call that script instead.
Behind the scenes, this uses AppleScript and “do shell script”, which is easier to code than NSTask. Tweak the source code if you want to change that.
4. What are the time and voltage sensitivity settings?

Detecting if the voltage goes up or down is a simple comparison. But that might trigger too often: “flapping”.
The voltage sensitivity is the number of volts that the input must change before an up or down event is triggered.
The last value is not always the one used. An average of several past values can be used instead, by changing the time sensitivity. Note that if you set the time sensitivity to 2 seconds, the last value is the average of the last 2 seconds, and the value before that was the 2 seconds before that -> you need data from 4 seconds ago.
5. How do I change the Cocoa source code to read other values from the kernel?

For that, you’ll need the Cocoa source as an Xcode project. Download it here:
SMC Voltmeter Source
Some other values you can access from the SMC are listed here:
http://www.parhelia.ch/blog/statics/k3_keys.html
6. What about a command-line version?
This version isn’t as well-commented or documented as the graphical version, but here’s the code.

https://raw.githubusercontent.com/peterburk/smc-voltmeter/master/smcVoltmeterCmd.zip


7. Can I read the SMC’s data sheet?
Yes. Look on iFixit for your model.
Mine is the Retina MacBook Pro 15″, with a Cypress Semiconductor CY8C24794-24LTXI Programmable System-on-Chip (https://www.cypress.com/?mpn=CY8C24794-24LTXI).
8. This was inspired by several existing apps, and development was much easier thanks to the open-source code of the first two:
SMCFanControl (http://www.eidac.de/?cat=40)
GraphKitDemo (http://www.theregister.co.uk/2008/03/11/mac_secrets_preferences/)
iStat (https://bjango.com/mac/istatmenus/)
