#!/usr/bin/env python3
# https://github.com/blink015/screen_shoter
import shutil
import math
import os
import time
import traceback
import sys
import re
from subprocess import Popen, PIPE
from collections import OrderedDict
from typing import List, Dict
from typing import List


class Config():
    """
    save the config infos.
    todo: add some data verifications? in case invalid be set...
    """
    def __init__(self):
        self.interpreter_path = "#!/usr/bin/env python3"  # first line, set python interpreter
        self.default_save_path = "~/Desktop/"  # default saveing path
        self.default_name_base = "demo"  # default name of screenshot
        self.default_suffix_img = ".png"  # screencap image format
        self.default_suffix_video = ".mp4"  # screenrecord video format
        self.resolution_setting = 3  # 0, 1, 2, 3, 4 represents full, 2/3, half, 1/3, 1/4 of full resolution seperately
                                     # float(0-1) supported, like 0.8, 0.5(namely half of full resolution), 0.3, ...
        self.time_limit = 0  # maximum screenrecord lehgth (in seconds), 0 means default 180s
        self.default_save_path_android = "/sdcard/"  # temp saving path on Android for screenshot
        self.interface = 1  # which interface tobe used, 1 is default, 2 is simple version
        # ProductType and common name of iPhone. From internet, error may exists...
        self.product_type_name = {"iPhone3,1": "iPhone 4", "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
                                  "iPhone4,1": "iPhone 4S", "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
                                  "iPhone5,3": "iPhone 5c", "iPhone5,4": "iPhone 5c", "iPhone6,1": "iPhone 5s",
                                  "iPhone6,2": "iPhone 5s", "iPhone7,1": "iPhone 6 Plus", "iPhone7,2": "iPhone 6",
                                  "iPhone8,1": "iPhone 6s", "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE",
                                  "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus", "iPhone9,3": "iPhone 7",
                                  "iPhone9,4": "iPhone 7 Plus", "iPhone10,1": "iPhone 8",
                                  "iPhone10,2": "iPhone 8 Plus", "iPhone10,3": "iPhone X",
                                  "iPhone10,4": "iPhone 8", "iPhone10,5": "iPhone 8 Plus", "iPhone10,6": "iPhone X",
                                  "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max",
                                  "iPhone11,6": "iPhone XS Max", "iPhone11,8": "iPhone XR",
                                  "iPhone12,1": "iPhone 11", "iPhone12,3": "iPhone 11 Pro",
                                  "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE2", }

    def _row_occupied(self, input_str: str) -> int:
        """
        calculate how many rows are need to display a string, based on the size of terminal.

        :param input_str: input string
        :return:
        """
        terminal_width = shutil.get_terminal_size().columns
        return math.ceil(len(input_str) / terminal_width)

    def print_config(self, desc_row_num: int) -> None:
        """
        print all configs, and their describe if exist.

        :param desc_row_num: rows to reserve for header lines
        :return:
        """
        describe = {"interface": "which interface tobe used, 1 is default, 2 is simple version",
                "default_save_path": "where to save screenshot",
                "default_name_base": "default name of screenshot",
                "resolution_setting": "set the resolution of screenrecord for Android, "
                                      "0, 1, 2, 3, 4 represents full, 2/3, half, 1/3, 1/4 of full resolution, "
                                      "float(0-1) supported, like 0.8, 0.5(namely half of full resolution), 0.3, ...",
                "time_limit": "max length of screenrecord",
                "": "",
                "product_type_name": "ProductType and common name of iPhone. From internet, error may exists...",}
        d_vars = vars(self)  # all attributes and their value
        terminal_height = shutil.get_terminal_size().lines

        l_vars = list(d_vars.items())
        indent = " >"
        rows = desc_row_num
        i = 0
        while i < len(l_vars):
            k = str(l_vars[i][0])
            v = str(l_vars[i][1])
            k_and_v = "{}{}:\t{}".format(indent, k, v)
            if k in describe:
                detail = "\n{} ({})".format(" "*len(indent), describe[k])
            else:
                detail = ""

            rows += (self._row_occupied(k_and_v) + self._row_occupied(detail))
            if rows < terminal_height:
                UiUtils.sprint(k_and_v + detail)
                i += 1
            else:
                choice = input("press enter to show more, q to go back:")  # can not use UiUtils.sinput here
                if choice == 'q':
                    return None
                os.system("clear")
                rows = 0
        UiUtils.sinput("press enter to continue: ")


class DependencyCheck():
    """
    check if adb and libimobiledevice installed.
    """
    def __init__(self):
        self.dependency_check = ""
        self.msg = ""

        adb_check = self._adb_check()
        libimobiledevice_check = self._libimobiledevice_check()
        if adb_check and libimobiledevice_check:
            self.dependency_check = "full"
            self.msg = "adb & libimobiledevice already installed."
        elif adb_check and (not libimobiledevice_check):
            self.dependency_check = "part"
            self.msg = "adb installed while libimobiledevice may not, iOS devices unsupport."
        elif (not adb_check) and libimobiledevice_check:
            self.dependency_check = "part"
            self.msg = "libimobiledevice installed while adb may not, Android devices unsupport."
        else:
            self.dependency_check = "none"
            self.msg = "both adb and libimobiledevice may [NOT] installed，ScreenShoter may not work.."

    def _adb_check(self) -> bool:
        """
        check adb installation.

        :return:
        """
        cmd = ["adb", "devices"]
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)
        temp = pp.communicate()
        res = temp[0].decode("utf-8")
        res = res.strip("\n ")
        if res.split("\n")[0] == "List of devices attached":
            return True
        else:
            return False

    def _libimobiledevice_check(self) -> bool:
        """
        check libimobiledevice installation.

        :return:
        """
        cmd = ["idevice_id", "-h"]
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)
        temp = pp.communicate()
        res = temp[0].decode("utf-8")
        res = res.strip("\n ")
        if res.split("\n")[0] == "Usage: idevice_id [OPTIONS] [UDID]":
            return True
        else:
            return False


class DeviceGetter:
    """
    get devices and their info using adb / libimobiledevice, save to an OrderedDict like:
    OrderedDict([('some_serialno', {'device_name': '/',
                                    'os': 'Android',
                                    'product_name': 'TKC-A7000',
                                    'product_type': '/',
                                    'os_version': '10'}
                 ),
                 ('some_udid', {'device_name': 'xxx's iPhone',
                                'os': 'iOS',
                                'os_version': '14.2',
                                'product_name': 'iPhone SE2',
                                'product_type': 'iPhone12,8'}
                 )])
    """
    def __init__(self):
        self.config = Config()
        self.product_type_name = self.config.product_type_name
        devices = OrderedDict()
        devices.update(self._get_android_devices())
        devices.update(self._get_ios_devices())
        self.devices = devices

    def _get_Popen_res(self, cmd: List[str]) -> str:
        """
        get the result of Popen.
        todo: distinguish stdout and stderr???

        :param cmd: list like command
        :return:
        """
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)
        temp = pp.communicate()
        res = temp[0].decode("utf-8")  # bytes > str
        res = res.strip("\n ")
        err = temp[1].decode("utf-8")
        err = err.strip("\n ")

        if res:
            return res
        else:
            return err

    def _get_android_devices_info(self, serialno: str) -> Dict:
        """
        get Android device's info.

        :param serialno: serialno obtained using adb devices
        :return:
        """
        infos = dict()

        k = "net.hostname"
        cmd = ["adb", "-s", serialno, "shell", "getprop", k]  # common name
        res = self._get_Popen_res(cmd)
        infos[k] = res

        k = "ro.build.version.release"
        cmd = ["adb", "-s", serialno, "shell", "getprop", k]  # Android version
        res = self._get_Popen_res(cmd)
        infos[k] = res

        return infos

    def _get_android_devices(self) -> Dict:
        """
        get Android devices list and their infos.

        :return:
        """
        cmd = ["adb", "devices"]
        res = self._get_Popen_res(cmd)
        res = res.split("\n")

        android_devices = dict()
        for i in range(len(res)):
            if i == 0:
                continue
            if res[i]:
                android_devices[res[i].split("\t")[0]] = dict()

        for serialno in android_devices.keys():
            android_devices[serialno]["os"] = "Android"
            other_infos = self._get_android_devices_info(serialno)
            android_devices[serialno]["device_name"] = "/"
            android_devices[serialno]["product_type"] = "/"
            android_devices[serialno]["product_name"] = other_infos["net.hostname"]
            android_devices[serialno]["os_version"] = other_infos["ro.build.version.release"]

        return android_devices

    def _get_ios_device_name(self, product_type: str) -> str:
        """
        transfer from ProductType to common name.

        :param product_type: iPhone's product type
        :return:
        """
        try:
            product_name = self.product_type_name[product_type]
        except KeyError as e:
            product_name = "{}(unidentified)".format(product_type)
        return product_name

    def _get_ios_device_info(self, udid: str) -> Dict:
        """
        get iOS device's info.

        :param udid: iPhone's udid
        :return:
        """
        cmd = ["ideviceinfo", "-u", "{}".format(udid)]  # no blank in command to be Popen; depend libimobiledevice
        res = self._get_Popen_res(cmd)
        res = res.split("\n")

        all_infos = dict()
        for line in res:
            if line:
                temp = line.split(": ")
                all_infos[temp[0]] = temp[1]

        infos = dict()
        infos["DeviceName"] = all_infos["DeviceName"]
        infos["ProductType"] = all_infos["ProductType"]
        infos["ProductName"] = self._get_ios_device_name(all_infos["ProductType"])  # original ProductName is always "iPhone OS"
        infos["ProductVersion"] = all_infos["ProductVersion"]

        return infos

    def _get_ios_devices(self) -> Dict:
        """
        get iOS devices list and their infos.

        :return:
        """
        cmd = ["idevice_id"]  # command of libimobiledevice
        res = self._get_Popen_res(cmd)
        res = res.split("\n")

        ios_devices = dict()
        for udid in res:
            if udid:
                udid = udid.split(" ")[0]
                ios_devices[udid] = dict()

        for udid in ios_devices.keys():
            ios_devices[udid]["os"] = "iOS"
            other_infos = self._get_ios_device_info(udid)
            ios_devices[udid]["device_name"] = other_infos["DeviceName"]
            ios_devices[udid]["product_type"] = other_infos["ProductType"]
            ios_devices[udid]["product_name"] = other_infos["ProductName"]
            ios_devices[udid]["os_version"] = other_infos["ProductVersion"]

        return ios_devices


class ShotUtils():
    """
    screencap, screenrecord, rename methods included.
    """
    def __init__(self) -> None:
        self.config = Config()
        self.default_save_path = self.config.default_save_path
        self.default_name_base = self.config.default_name_base
        self.default_save_path_android = self.config.default_save_path_android

        self.default_suffix_img = self.config.default_suffix_img
        self.default_suffix_video = self.config.default_suffix_video
        self.resolution_setting = self.config.resolution_setting
        self.time_limit = self.config.time_limit

        self.current_name = None

    def screencap(self, os: str, id: str) -> bool:
        """
        take screencap,, then pull to macbook.

        :param os: Android or iOS
        :param id: Android's serialno or iOS's udid
        :return:
        """
        UiUtils.sprint("taking screencap...")
        try:
            if os == "Android":
                if self._screencap_Android(id):
                    return True
                else:
                    UiUtils.sinput("press enter to continue...")  # is it appropriate here?
                    return False
            elif os == "iOS":
                if self._screencap_iOS(id):
                    return True
                else:
                    UiUtils.sinput("press enter to continue...")  # is it appropriate here?
                    return False
            # UiUtils.sinput("press enter to continue...")  # is it appropriate here?
        except Exception as e:
            traceback.print_exc()
            UiUtils.sprint("sorry, screencap failed for some reason, please try again...")
            UiUtils.sinput("press enter to continue...")  # is it appropriate???
            return False

    def _screencap_Android(self, serialno: str) -> bool:
        """
        take screencap of Android, then pull to macbook.

        :param serialno: Android's serialno obtained from adb devices
        :return:
        """
        cmd = ["adb", "-s", serialno, "shell", "screencap", "-p", "{}{}{}"
               .format(self.default_save_path_android, self.default_name_base, self.default_suffix_img)]
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)  # os.popen can not get error massage here
        res = pp.communicate()  # for this command, error message stored in res[1] if error uccured
        if res[1]:  # if error occured
            UiUtils.sprint("screencap failed...")
            UiUtils.sprint(res[1].decode("utf-8").strip("\n "), "[adb]")  #@#@#
            # UiUtils.sprint("[adb]{}".format(res[1].decode("utf-8").strip("\n ")))
            # UiUtils.sinput("press enter to continue...")
            return False
        else:  # pull to local and optionally rename
            UiUtils.sprint("screencap saved to device/emulator \"/sdcard/{}.png\""
                  .format(self.default_name_base))
            name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_img)
            if self._pull_from_android(serialno, name_safe, "screencap"):
                return True
            else:
                return False

    def _screencap_iOS(self, udid: str) -> bool:
        """
        take screencap of iOS (no need to pull like Android).

        :param udid: iPhone's udid
        :return:
        """
        name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_img)
        # res = os.popen("idevicescreenshot -u {} {}{}"
        #                .format(udid, self.default_save_path, name_safe)).read()
        pp = Popen("idevicescreenshot -u {} {}{}".format(udid, self.default_save_path, name_safe),
                   shell=True, stdout=PIPE, stderr=PIPE)  # shell=True is necessary here somehow...
        res = pp.communicate()[0].decode("utf-8").strip("\n ")  # success/error message all here
        res = res.strip("\n ")
        if "Screenshot saved to" in res:
            UiUtils.sprint(res, "[libimobiledevice]")  #@#@#
            # UiUtils.sprint("[libimobiledevice]{}".format(res))
            return True
        else:
            UiUtils.sprint("screencap failed...")
            UiUtils.sprint(res, "[libimobiledevice]")  #@#@#
            # UiUtils.sprint("[libimobiledevice]{}".format(res))
            return False

    def screenrecord(self, os: str, id: str) -> bool:
        """
        take screenrecord, then pull to macbook.

        :param os: Android or iOS
        :param id: Android's serialno or iOS's udid
        :return:
        """
        # UiUtils.sprint("taking screenrecord...")  # not appropriate here?
        try:
            if os == "Android":
                UiUtils.sprint("taking screenrecord...")
                if self._screenrecord_Android(id, self._get_resolution(id), self.time_limit):
                    return True
                else:
                    UiUtils.sinput("press enter to continue...")
                    return False
            else:
                self._screenrecord_iOS(id)
                return False  # iOS not support currently...
        except Exception as e:
            traceback.print_exc()
            UiUtils.sprint("sorry, screenrecord failed for some reason, please try again...")
            UiUtils.sinput("press enter to continue...")
            return False

    def _screenrecord_Android(self, serialno: str, resolution:str, time_limit:int) -> bool:
        """
        take screenrecord of Android, then pull to macbook.
        currently only the resolution and time_limit can be adjust (attribute of class Config).
        todo: add more command parameters if necessary...

        :param serialno:
        :param resolution:
        :param time_limit:
        :return:
        """
        if not resolution:  # fail to get resolution
            return False

        if int(time_limit) !=0:
            UiUtils.sprint("resolution:{}; max length:{}s".format(resolution, time_limit))
            UiUtils.sprint("PRESS Ctrl+C to STOP recording:")
            cmd = ["adb", "-s", serialno, "shell", "screenrecord",
                   "--size", resolution, "--time-limit", str(int(time_limit)), "{}{}{}"
                   .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video)]
        else:
            UiUtils.sprint("resolution: {}; max length: 180s (default)".format(resolution))
            UiUtils.sprint("PRESS Ctrl+C to STOP recording:")
            cmd = ["adb", "-s", serialno, "shell", "screenrecord",
                   "--size", resolution, "{}{}{}"
                   .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video)]

        res = "initial"  # the value will not be reassign after KeyboardInterrupt
        try:
            pp = Popen(cmd, stdout=PIPE, stderr=PIPE)  # os.popen can't get error message
            res = pp.communicate()  # error message in res[1] if exists
                                    # this line must included in KeyboardInterrupt???
        except KeyboardInterrupt as e:  # trigger KeyboardInterrupt to stop recording
            time.sleep(0.5)  # it seems easier to get unreconized video without sleep for a while...
            pass

        if res == "initial":
            UiUtils.sprint("\nscreenrecord saved to device/emulator \"{}{}{}\""
                  .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video))
        elif res[1]:  # error occured
            UiUtils.sprint("screencap failed...")
            UiUtils.sprint(res[1], "[adb]")  #@#@#
            # UiUtils.sprint("[adb]{}".format(res[1]))
            UiUtils.sinput("press enter to continue...")
            return False
        else:  # till max length
            UiUtils.sprint("max length reached...")
            UiUtils.sprint("screenrecord saved to device/emulator \"{}{}{}\""
                  .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video))

        name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_video)
        if self._pull_from_android(serialno, name_safe, "screenrecord"):
            return True
        else:
            return False

    def _screenrecord_iOS(self, udid: str) -> None:
        """
        libimobiledevice do NOT support take screenrecord of iOS...

        :param udid: iPhone's udid
        :return:
        """
        UiUtils.sprint("screenrecord for iOS is NOT SUPPORT by libimobiledevice...")
        UiUtils.sinput("press enter to continue...")

    def _pull_from_android(self, serialno: str, name_safe: str, shot_type: str) -> bool:
        """
        pull screencap/screenrecord from Android device to macbook.

        :param serialno: Android's serialno obtained from adb devices.
        :param name_safe: name of file to be saved
        :param shot_type: screencap or screenrecord
        :return:
        """
        suffix = ""
        if shot_type == "screencap":
            suffix = self.default_suffix_img
        elif shot_type == "screenrecord":
            suffix = self.default_suffix_video

        UiUtils.sprint("pulling to local...")
        res = os.popen("adb -s {} pull {}{}{} {}{}"
                       .format(serialno, self.default_save_path_android, self.default_name_base,
                               suffix, self.default_save_path, name_safe)).read()
        UiUtils.sprint(res, "[adb]", end="")  #@#@#
        # UiUtils.sprint("[adb]{}".format(res), end="")

        if not "error" in res:
            UiUtils.sprint("screenrecord finished, saved to \"{}{}\""
                  .format(self.default_save_path, name_safe))
            return True
        else:
            UiUtils.sprint("pulling failed...")
            return False

    def _get_safe_names(self, name: str, suffix: str) -> str:
        """
        get an "save_name" according to one file name and it's suffix, to avoid duplicate names.

        :param name: name tobe check
        :param suffix: suffix of the file
        :return:
        """
        existing_files = os.popen("ls -a {}".format(self.default_save_path)).readlines()
        for i in range(len(existing_files)):
            temp = len(existing_files[i])
            existing_files[i] = existing_files[i][:temp - 1]  # cut off the "\n" on end

        name_origin = name
        while True:
            name_suffix = name + suffix
            if name_suffix in existing_files:
                temp = name.split(name_origin)
                if not temp[1]:
                    name += "1"
                else:
                    name = name_origin + str(int(temp[1]) + 1)
            else:
                break

        self.current_name = name_suffix
        return name_suffix  # suffix already included

    def rename_file(self, new_name: str) -> bool:
        """
        rename file after saved to local.

        :param new_name: new file name
        :return:
        """
        old_name = self.current_name
        old_file = self.config.default_save_path + old_name
        suffix = "." + self.current_name.split(".")[-1]

        new_name_safe = self._get_safe_names(new_name, suffix)
        new_file = self.config.default_save_path + new_name_safe

        pp = Popen("mv {} {}".format(old_file, new_file),
                   shell=True, stdout=PIPE, stderr=PIPE)  # shell=True is necessary here somehow...
                                                          # os.popen can not get error message...
        res = pp.communicate()[1].decode("utf-8").strip("\n ")  # error message here if exists

        if res:
            UiUtils.sprint("rename failed...")
            UiUtils.sprint(res, "[terminal]")  #@#@#
            # UiUtils.sprint("[terminal]" + res)
            self.current_name = old_name  # do not forget to reset
            return False
        else:
            if new_name + suffix != new_name_safe:
                UiUtils.sprint("new name \"{}\" exists, add number at the end. ".format(new_name))
            UiUtils.sprint(".../{} renamed to .../{}".format(old_name, new_name_safe))
            UiUtils.sinput("press enter to continue...")
            return True

    def _get_resolution(self, serialno: str) -> str or bool:
        """
        calculate resolution that use to take screenrecord, e.g. 540x1170

        :param serialno: Android's serialno obtained from adb devices
        :return:
        """
        cmd = ["adb", "-s", serialno, "shell", "dumpsys", "window", "displays", "|", "grep", "init"]
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)  # os.popen can not get error message
        res = pp.communicate()  # expected output in res[0], while error message in res[1] if exists

        if res[1]:
            UiUtils.sprint("screencap failed...")
            UiUtils.sprint(res[1].decode("utf-8").strip("\n "), "[adb]")  #@#@#
            # UiUtils.sprint("[adb]{}".format(res[1].decode("utf-8").strip("\n ")))
            return False
        else:
            temp = res[0].decode("utf-8").strip("\n ").split(" ")[0]  # e.g. "init=1080x1920"
            resol_default = temp[5:len(temp)].split("x")  # e.g. ['1080', '2340']
            resol_default = [int(x) for x in resol_default]

            setting = self.resolution_setting
            if setting == 0:
                return "x".join([str(x) for x in resol_default])
            elif setting == 1:
                resol_two_third = [int(x * 2 / 3) for x in resol_default]
                return "x".join([str(x) for x in resol_two_third])
            elif setting == 2:
                resol_half = [int(x * 1 / 2) for x in resol_default]
                return "x".join([str(x) for x in resol_half])
            elif setting == 3:
                resol_one_third = [int(x * 1 / 3) for x in resol_default]
                return "x".join([str(x) for x in resol_one_third])
            elif setting == 4:
                resol_quarter = [int(x * 1 / 4) for x in resol_default]
                return "x".join([str(x) for x in resol_quarter])
            elif setting > 0 and setting < 1:
                resol_custom = [int(x * setting) for x in resol_default]
                return "x".join([str(x) for x in resol_custom])
            else:  # in case invalid setting
                return "x".join([str(x) for x in resol_default])


class UiUtils():
    """
    custom print and input method.
    """
    def __init__(self) -> None:
        pass

    @staticmethod
    def sprint(content: List or str, header: str = "", indent_blank: int = 0, sep: str = ' ', end: str = '\n') -> None:
        """
        optionally add header, indent when print.

        :param content: string to be print
        :param header: before content
        :param indent_blank: add how many blanks at the begining
        :param sep: sep of print
        :param end: end of print
        :return:
        """
        if isinstance(content, str):
            temp = content
        else:
            temp = sep.join(content)
        print(" " * indent_blank + header + temp, end = end)

    @staticmethod
    def sinput(prompt: str) -> str:
        """
        input "q" to close terminal.
        Terminal, Preferences > Profiles > Shell > When the shell exits > Close the window.

        :param prompt: prompt
        :return: the input
        """
        inputt = input(prompt)
        if inputt.lower() == "q":
            os.system("clear")
            UiUtils.sprint("exiting...")
            time.sleep(1.4)
            Popen("exit", stdin=PIPE, stdout=PIPE)  # os.popen JUST DO NOT WORK here ,like add shell=True
        else:
            return inputt


class ScreenShoter:
    """
    main class.
    todo, lots of error handler to add...
    todo, get device's crash log?...
    """
    def __init__(self) -> None:
        self.config = Config()
        self.dependency_check = DependencyCheck()
        self.devices = DeviceGetter().devices
        self.shot_utils = ShotUtils()

        self.default_save_path = self.config.default_save_path
        self.default_name_base = self.config.default_name_base
        self.device_id = ""  # specified device's serialno / udid

        # initial interface
        self.pre_interface()
        if self.config.interface == 1:
            self.initial_interface()
        else:
            self.initial_interface_simple()

        # main
        while True:
            try:
                self.main()
            except Exception as e:
                os.system("clear")
                traceback.print_exc()
                UiUtils.sprint("unknown error occured...")
                UiUtils.sinput("press enter to reload...")

    def pre_interface(self) -> None:
        """
        print some "log", just for fun...

        :return:
        """
        time_a = 0.06
        infos = ["init...", "reading config...", "dependency checking...", "accessing devices..."]
        for info in infos:
            UiUtils.sprint(info)
            time.sleep(time_a)
        time.sleep(0.4 - time_a)

    def split_msg(self, strr: str, terminal_width: int) -> List:
        """
        according to terminal's column num, split long str to shorter ones. just in case...

        :param strr: string to split
        :param terminal_width: terminal width in characters
        :return:
        """
        res = []
        i = 0
        while True:
            slice_lower = i * (terminal_width - 2)
            slice_uppper = (i + 1) * (terminal_width - 2)
            temp = strr[slice_lower:slice_uppper]
            if temp:
                res.append(temp)
            else:
                break
            i += 1
        return res

    def initial_interface(self) -> None:
        """
        create initial interface in terminal...

        :return:
        """
        terminal_height = shutil.get_terminal_size().lines  # os.get_...() will get and error...
        terminal_width = shutil.get_terminal_size().columns
        descriptions = ["Make it easier to take screenshot for mobile devices",
                        "Android & iOS supported"]
        dependency_check_msg = self.dependency_check.msg
        dependency_check_msg = self.split_msg(dependency_check_msg, terminal_width)  # List

        description_start = int(terminal_height / 3) + 1  # which line does description start
        dependency_check_start = terminal_height - 2 - len(dependency_check_msg) - 1  # dependency check message start
        first_interface = []
        for i in range(terminal_height):
            if i == 0:
                first_interface.append("—" * terminal_width)
            elif i < description_start:
                first_interface.append("|" + " " * (terminal_width - 2) + "|")
            elif i >= description_start and i <= (description_start + len(descriptions)):
                first_interface.append("|" + descriptions.pop(0).center(terminal_width - 2, " ") + "|")
            elif i > (description_start + len(descriptions)) and i < dependency_check_start:
                first_interface.append("|" + " " * (terminal_width - 2) + "|")
            elif i == dependency_check_start:
                first_interface.append("|" + " Dependency check:".ljust(terminal_width - 2, " ") + "|")
            elif i > dependency_check_start and i <= (dependency_check_start + len(dependency_check_msg) + 1):
                first_interface.append("|" + " " + dependency_check_msg.pop(0).ljust(terminal_width - 3, " ") + "|")
            elif i == terminal_height - 1:
                first_interface.append("—" * terminal_width)
            else:
                pass

        for i in range(len(first_interface)):
            UiUtils.sprint(first_interface[i])
        UiUtils.sinput(" press enter to start (\"q\" to quit anywhere): ")  # consider only one line here

    def initial_interface_simple(self) -> None:
        """
        in case of odd UI appears...

        :return:
        """
        UiUtils.sprint("\n" + self.dependency_check.msg)
        UiUtils.sinput("press enter to start (\"q\" to quit anywhere): ")

    def device_select_interface_abandon(self) -> str or None:
        """
        this method is abandoned
        no device UI / select device UI
        specify device by set the instance variable
        """
        os.system("clear")
        if self.devices:
            if len(self.devices) == 1:  # distinguish number of devices in main method, don't call this method if number is 1
                pass
                return None
            else:
                UiUtils.sprint("please select your target device:")
                counter = 1
                for k, v in self.devices.items():
                    if v["os"] == "Android" or v["os"] == "iOS":  # in case of display infos separately
                        UiUtils.sprint("{}. name: {}\tos: {}\tos_version: {}".
                                        format(counter, v["product_name"].ljust(21, " "),
                                        v["os"].ljust(9, " "), v["os_version"]))
                    else:
                        raise Exception("no 'os' attribute found within devices's dict.")
                    counter += 1
                number = UiUtils.sinput("type number({}-{}) here to select: ".format(1, len(self.devices)))
                return number
        else:
            UiUtils.sprint("no device/simulator found...")
            res = UiUtils.sinput("press enter to retry: ")
            return res

    def device_select_interface(self) -> None:
        """
        no device UI / select device UI. specify device by set the instance variable.

        :return:
        """
        UiUtils.sprint("please select your target device:")
        counter = 1
        for k, v in self.devices.items():
            if v["os"] == "Android" or v["os"] == "iOS":  # in case of display infos separately
                UiUtils.sprint("{}. name: {}\tos: {}\tos_version: {}".format(counter, v["product_name"].ljust(21, " "),
                                v["os"].ljust(9, " "), v["os_version"]))
            else:
                raise Exception("no 'os' attribute found within devices's dict.")
            counter += 1

    def verify_input(self, input_str: str, lower_limit: int, upper_limit: int) -> bool:
        """
        varify if the input string is int like.

        :param input_str: string to be verify
        :param lower_limit: int range start
        :param upper_limit: int range end
        :return:
        """
        try:
            if re.match(r"[0-9]+", input_str):  # is number
                if lower_limit <= int(input_str) <= upper_limit:
                    return True
                else:
                    return False
            else:
                return False
        except Exception as e:  # in case some werid input likt "0f" sometimes...
            return False

    def device_select_abandon(self) -> None:
        """
        this method ia abandoned
        choose one device, saved to instance variable
        todo: distinguish the "None" that no device, and the "None" that only one device???
        """
        counter = 1
        while True:
            input_str = self.device_select_interface_abandon()
            # UiUtils.sprint("[][][][][][][][]:" + repr(input_str))  ####
            if input_str == "":
                # UiUtils.sprint("##################")  ####
                self.devices = DeviceGetter().devices
            elif input_str is not None:  # multi devices
                input_ok = self.verify_input(input_str, 1, len(self.devices))
                if input_ok:
                    self.device_id = list(self.devices.keys())[int(input_str) - 1]
                    break
                else:
                    pass
            else:
                pass
            counter += 1

    def device_select(self) -> None:
        """
        choose one device, saved to instance variable.
        todo: distinguish the "None" that no device, and the "None" that only one device???

        :return:
        """
        counter = 1
        input_desc = "type number({}-{}) to select, type enter to reload devices: \n".format(1, len(self.devices))
        while True:
            os.system("clear")
            if self.devices:
                if len(self.devices) == 1:
                    self.device_id = list(self.devices.keys())[0]
                    break
                else:
                    # os.system("clear")
                    self.device_select_interface()
                    number_str = UiUtils.sinput(input_desc)
                    if self.verify_input(number_str, 1, len(self.devices)):
                        self.device_id = list(self.devices.keys())[int(number_str) - 1]
                        break
                    elif number_str == "":
                        UiUtils.sprint("reloading devices..."); time.sleep(0.7)
                        self.devices = DeviceGetter().devices
                    else:
                        UiUtils.sprint("a valid number is need{}".format("."*counter)); time.sleep(1)
            else:
                UiUtils.sprint("no device/simulator found...")
                UiUtils.sinput("press enter to retry: ")
                UiUtils.sprint("reloading devices..."); time.sleep(0.7)
                self.devices = DeviceGetter().devices

            counter += 1

    def choose_command(self) -> int:
        """
        main UI, choose option and to do something.

        :return:
        """
        cur_device_dict = self.devices[self.device_id]
        os.system("clear")  # clear screen
        UiUtils.sprint("current deivce: {}   {} {}"
                       .format(cur_device_dict["product_name"], cur_device_dict["os"], cur_device_dict["os_version"], ))
        UiUtils.sprint("choose your option below: ")
        UiUtils.sprint("1. to take screencap;")
        UiUtils.sprint("2. to take screenrecord (Android only!);")
        UiUtils.sprint("9. to change target device/simulator;")
        UiUtils.sprint("0. to display current config;")

        while True:
            num = UiUtils.sinput("your choice: ")
            try:
                num = int(num)
                if num in [1, 2, 9, 0]:
                    break
                else:
                    raise Exception
            except Exception as e:
                UiUtils.sprint("please try again...")
        return num

    def rename_file(self) -> None:
        """
        call the rename_file method of ShotUtils in a loop.

        :return:
        """
        msg = "print enter to continue, type a new name to rename file: "
        while True:
            new_name = input(msg)  # can't use UiUtils.sinput here
            if not new_name:
                break
            else:
                if self.shot_utils.rename_file(new_name):
                    break
                else:
                    UiUtils.sprint("please try to type an valid file name...")

    def main(self) -> None:
        """
        main method.
        todo: added UiUtils's sprint & sinput, search #@#@# if something goes wrong...
        todo: remove abandoned methods in some time...

        :return:
        """
        if len(self.devices) == 0:
            self.device_select()
        elif len(self.devices) == 1:
            self.device_id = list(self.devices.keys())[0]
        else:
            self.device_select()

        counter = 0
        while True:
            cmd_serial = self.choose_command()

            if cmd_serial == 1:  # take screencap
                if self.shot_utils.screencap(self.devices[self.device_id]["os"], self.device_id):
                    self.rename_file()
                else:
                    pass  # todo: error handle
            elif cmd_serial == 2:  # take screenrecord
                if self.shot_utils.screenrecord(self.devices[self.device_id]["os"], self.device_id):
                    self.rename_file()
                else:
                    pass  # todo: error handle
            elif cmd_serial == 9:  # change target deivce
                self.devices = DeviceGetter().devices
                if len(self.devices) == 1:
                    UiUtils.sprint("only one device detected...")
                    UiUtils.sinput("press enter to continue:")
                self.device_select()
            elif cmd_serial == 0:  # show all configs
                os.system("clear")
                header_lines = ["all configs displayed below, ",
                                "you can change them manually within source code: ",
                                "class Config, method __init__ ...",
                                " -------------------------------------------", ]  # in order to calculate rows occupied
                UiUtils.sprint("\n".join(header_lines))
                # self.config.print_config(4)  # why using specific value???
                self.config.print_config(len(header_lines))
            else:
                raise Exception("unexpected cmd_serial occuried...")

            counter += 1


if __name__ == "__main__":
    ss = ScreenShoter()
    # ss.main()  # moved to __init__ method
