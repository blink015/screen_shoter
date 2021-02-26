# screen_shoter
![Action screenshot](docs/img_1.png)

Screen Shoter is a tool (script) runs in terminal of macbook, which aimed to make it easier taking screenshot for mobile devices.  

Android & iOS supported.

## Getting started

### Requirement

* Macbook & zsh shell (not verified in other shells yet)
* python3
* adb (Android SDK Platform-tools)
* libimobiledevice
* Enable developer mode then turn on usb debugging of Android real device

### Download

You need noly one single file, **screen_shoter.py.command**, to run this tool. Other files were used for develop.  

Download this file, or simply copy the code to a text file.

## Usage

First Add executable permissions to the file:  
```
chmod +x [path]
```

Then Make sure device(s) connected to computer (via usb). If the device is connected for the first time, allow debuging (Android) or trust computer (iOS).  

Now Double click **screen_shoter.py.command**, script will start to run in terminal, then follow the guide to use.

Besides, you can scroll down to find history messages, they were not really earsed.

### Config

Options were stored in instance variables of class *Config*. You can modify them manually. Open **screen_shoter.py.command** in a text editor, class *Config* lies at the beginning. All options and their description listed within the *\_\_init\_\_* method.

| Some Options               | Description                                               |
| -------------------------- | --------------------------------------------------------- |
| `self.interpreter_path`    | Set the python interpreter                                |
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
