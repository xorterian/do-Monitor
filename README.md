# do-Monitor

This is a Linux-based command-line tool which serves automated and programmable monitoring features on the subject of your iOS devices via VPN connection. It requires experience in the usage of linux and bash commands, having a simple, smart phone with the proper version of Android, mobile data or wi-fi connection, and tailscale installation. The promised solution is free, does not require root, and also works in distance as expected.

## Pre-requisites

I have not determined the complete range of devices that would able to work in the system, I can tell you on what I have tested it.
- Linux system with superuser authorities, wi-fi connection,
- Android phone (MIUI v14.0.5, Android v12 SKQ1.211...,)
You need to install the app Tailscale onto your phone. You also need to setup it from the command-line. Follow the instructions of the official website to see both of the computer and the phone.

You also need the software scrcpy which does the main job related to call recordings.

You need to get into the developer mode in the settings in your phone (does not need root). For the first time, you need to pair it with the computer on wi-fi in ADB connection. After that, you can switch back to mobile data and even to be in distance.

## Setup

To have the VPN connection, lets open Settings, VPN, and we should see the label Tailscale under the line Configuration. Ensure if it is on state "Always-on VPN", then get into the app to switch it on. Tailscale is needed to be switched on on the computer, that is, type the command "sudo tailscale up" into the command-line.

Be on the wi-fi on both the computer and the phone. For first time you need to:
- Get into the Additional settings / Developer options /  Wireless debugging, and switch it on temporary,
- then pair your device with a pairing code to the computer, for which, you need to type the prompt "adb pair 100.x.y.z:w", then give the code you can see on screen of the phone,
- then switch the tcp connection to another number with the prompt "adb tcpip 5555",
- then reconnect to the device with the IP address you can see on the screen above the pairing options: "adb connect 100.x.y.z:5555",
- and for now, you can switch from the wi-fi to mobile data, meaning your system will work in distance as well.

Now get back to the command-line. You can test if the ADB connection is alive. For example, just type the command "adb shell cmd notification post ussd_cmd "'This is a popup message.'" ". If it works, get to the directory of the do-Monitor, and now you are about to launch the bash code. Before it, note that, you need to grant the codes permissions with the command "chmod +x ./do-monitor.sh", and do the same with all the codes inside the directory "codes". Now you can launch do-Monitor with the prompt: "./do-monitor.sh".

You should test the software scrcpy as well, for say, with a command: "scrcpy --record test-01.mp4 --audio-source=voice-call". I wish to note that, at this point, it becomes important which version of Android you have, because some of them cannot make the records in both direction anymore.

For the first time, it requires data like the IP address of your device (you can check it in the Tailscale application), and some possible setup options including geolocation logging, call recording, customized USSD-like prompts, and so on. After in the command line you can see that the system is up, you can use it.

## Call records

You will be find your records on the directory "calls". Despite these are mp4 files, these are just sound files. You can convert them to mp3. Notice that, these have two channels: one is yours, the other one is the dialed partners. You can filter one of them out, or unify them into one channel.

When you dial a number, the do-Monitor reads this act out from the system log, and launches the programme scrcpy to record the call.

When you finish the call, the do-Monitor knows it similarly, and finishes the record as well, then the record file will be saves to the mentioned folder.

## Geolocations

If you setup do-Monitor to log your location, then the coordinates of your device will be saved into a csv file. With the default frequency, it logs your location in each minute. After the end of the process, it creates an interactive link which plots your moves onto the map. Thank University of Keene for the independent job.

Note that, if you stay at the same place, do-Monitor will not repeat the logging until you do not move again. It will also not save the csv, if you have only a single coordinates, for example, when you just wish to test the app coming with a lot of re-start.

## USSD-like commands

USSD stands for Unstructured Supplementary Service Data, which usually refers to an easy, quick code, the user can send to the local GSM towers. With these codes you can configure your phone or get information. For example, at my phone provider, you can hide your phone number after dialing the code "\*31#", and you can undo it with the code "\*30#". It is followed by the logic of Asterisk. I warn you to not play dialing random USSD codes! Only use the codes you know what it is for, because some of them are not public but could affect on GSM towers or other official objects.

The idea to have customized USSD-like codes means the following: you use a non-functional USSD code for personal usage which does not interfere with live, real USSD codes. You can create it, which can be your birthdate or anything like this. This is the PRIME code, and by default, it is 111222333. The next input is the number of the code separated with sign \*. In the "codes" directory you can see some example codes; most of them are bash codes. These are running on the computer. You also can give a further, possible input which is the parameter of the program separated with sign \*. The code is closed with sign \#. Although you launch them in a trichotome mode meaning it is either switch-on/setup or switch-off or get-information mode. In switch-on/setup mode you start the code with a simple \* sign, in swtich-off mode you start it with \# sign, and in get-information mode you start it with \*\# sign.

After you dialed a code like this, do-Monitor runs it, then returns its message, if any, in a popup message on your phone. For example, dialing the code "\#111222333\*3\*\6\#", you can switch the recording feature off, and with "\*111222333\*3\*\6\#" you can switch it back.

Feel free to modify the codes, and share it or contribute with me.

## Switch down

You can quit from the do-Monitor with the press of the buttons Ctrl + C. After the quit, it shuts the parallel processes down and saves the geolocations.

It remains on you to shut the Tailscale down on the computer with "sudo tailscale down", and on the phone (Settings / VPN / Tailscale), including switching the state "Always-on VPN" off as well.

## Further setups

It is possible that your phone pasue the app if it is seemed unused. To avoid this, go to the App info of the tailscale, the set Battery saver option to "No restriction". You can also try to force your phone to use mobile data to ensure it will not disconnect from the ADB connection. (Even if it happens for a short time, the do-Monitor keeps making attempts to reconnect to the device.)

## Legal usage

This project is designed for experimental, personal usage for home.

You can make tests on your own devices and on your own network. Its usage on other people's devices is highly unrecommended even if they agreed on it. It would be not just unethical but, in some countries, supposed to be against to law.

If you make call records with real persons, it is your responsibility to inform them in advance, ask for their agreement in advance, and to delete the records on time, not sharing it with third person or in public.
