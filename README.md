# screen_shoter
![Action screenshot](docs/img_1.png)

Screen Shoter is a tool (script) runs in terminal of macbook, which aimed to make it easier taking screenshot for mobile devices.  

Android & iOS supported.

## Getting started

### Requirement

* Macbook & zsh shell (not verified in other shells yet)
* python3
* adb (Android SDK Platform-tools)  <br>*adb commands like "adb devices" could be used to make sure the Android device is connected.
* libimobiledevice  <br>*libimobiledevice commands like "adb devices" could be used to make sure the iOS device is connected.


### Usage

#### Download

You need noly one single file,**screen_shoter.py.command**, to run this tool. Other files were used for develop.  

Download this file, or simply copy the code to a text file and rename it.

#### Specify interpreter

Open the file, Specify the Python interpreter in the firest line, something like:
```
#!/usr/bin/env python3
```
#### Add permission

First Add executable permissions to the file:  
```
chmod +x [path]
```
#### Run

Now Double click **screen_shoter.py.command**, script will start to run in terminal, then follow the guide to use.

Besides, you can scroll down to find history messages, they were not really earsed.

### Config

Options were stored in instance variables of class *Config*. You can modify them manually. Open **screen_shoter.py.command** in a text editor, class *Config* lies at the beginning. All options and their description listed within the *\_\_init\_\_* method.

Here are some options:

| Option                     | Description                                               |
| -------------------------- | --------------------------------------------------------- |
| `self.default_save_path`   | Where to save screenshot                                  |
| `self.resolution_setting`  | Set the resolution of screenrecord (for Android)          |
| `self.time_limit`          | Set the max length of screenrecord (for Android)          |
| `self.interface`           | Skip initial_interface if set to 2                        |
| `self.product_type_name`   | Common name of iPhone corresponding to the product_type   |

## Note

Screenrecord is not supported for iOS devices.

A few Android devices may not support taking screenrecord using adb command... You could run this command in terminal to verify (Press Control + C to stop recording):
```
adb shell screenrecord /sdcard/demo.mp4
```
