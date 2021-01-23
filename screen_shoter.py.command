#!/usr/bin/env python3
import os
import sys
import time
import shutil
from subprocess import Popen, PIPE
from collections import OrderedDict
from typing import List, Dict
from typing import List
from pprint import pprint


class Config:
    """
    save the config infos
    """
    def __init__(self):
        self.interface = 2  # which interface tobe used, 1 is default, 2 is simple version
        self.default_save_path = "~/Desktop/"  # default saveing path
        self.default_name_base = "demo"  # default name of screenshot / screenrecord


class DependencyCheck:
    """
    check if adb and libimobiledevice installed
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
    get devices and their info through adb / ideviceinstaller, save to OrderedDict like:
    OrderedDict([('some_serialno', {'device_name': '/',
                                    'os': 'Android',
                                    'product_name': 'TKC-A7000',
                                    'product_type': '/',
                                    'product_version': '10'}
                 ),
                 ('some_udid', {'device_name': 'xxx's iPhone',
                                'os': 'iOS',
                                'os_version': '14.2',
                                'product_name': 'iPhone SE2',
                                'product_type': 'iPhone12,8'}
                 )])
    """
    def __init__(self):
        # ProductType and commen name of iPhone. From internet, error may exists
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
        devices = OrderedDict()
        devices.update(self._get_android_devices())
        devices.update(self._get_ios_devices())
        self.devices = devices

    def _get_Popen_res(self, cmd: List[str]) -> str:
        """
        get result of Popen
        ***todo, distinguish stdout and stderr??
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
        get Android device's info
        :param serialno:
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
        get Android devices list and their infos
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
            android_devices[serialno]["product_version"] = other_infos["ro.build.version.release"]

        return android_devices

    def _get_ios_device_name(self, product_type: str) -> str:
        """
        "translate" from ProductType to common name
        :return:
        """
        try:
            product_name = self.product_type_name[product_type]
        except KeyError as e:
            product_name = "{}(unidentified)".format(product_type)
        return product_name

    def _get_ios_device_info(self, udid: str) -> Dict:
        """
        get ios device's info
        :param udid:
        :return:
        """
        cmd = ["ideviceinfo", "-u", "{}".format(udid)]  # no blank in command to be Popen; depend libideviceinstaller
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
        get iOS devices list and their infos
        :return:
        """
        cmd = ["idevice_id"]  # command of libideviceinstaller
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

# static方法，定义Android截图类，iOS截图类，还是都放到main.py里？

# 其他类先固定方法，加不加_，固定后好引用
# 该加static的加一下，比如Android截图/截屏类，方便引用

class ScreenShoter:
    def __init__(self):
        self.config = Config()
        self.dependency_check = DependencyCheck()

        # initial interface
        self.pre_interface()
        if self.config.interface == 1:
            self.interface()
        else:
            self.interface_simple()

        self.devices = DeviceGetter().devices

        self.device_id = ""  # 记录当前选中的设备serialno/udid

        self.default_save_path = self.config.default_save_path  # 默认保存到的路径
        self.default_name_base = self.config.default_name_base  # 默认的基本名

    def pre_interface(self) -> None:
        """
        print some "log", just for fun...
        :return:
        """
        time_a = 0.06
        infos = ["init...", "reading config...", "dependency checking...", "accessing devices..."]
        for info in infos:
            print(info)
            time.sleep(time_a)
        time.sleep(0.4 - time_a)

    def interface(self) -> None:
        """
        create initial interface (in terminal...)
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
            print(first_interface[i])
        input(" press enter to start: ")

    def split_msg(self, strr: str, terminal_width: int) -> List:
        """
        according to the terminal column num, split long str to shorter ones
        just in case...
        :param strr:
        :param terminal_width:
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

    def interface_simple(self) -> None:
        """
        in case of odd UI...
        :return:
        """
        print("\n" + self.dependency_check.msg)
        input("press enter to start: ")

    def main(self):
        # 初始化

        # 正式开始循环？

        counter = 0  # 是

        while True:
            # 如果counter=0，进初始界面

            # 中间可重置为0，循环后，再次触发初始界面（但肯定不一样，第一次初始界面消不掉python版本等信息……

            counter += 1


if __name__ == "__main__":
    ss = ScreenShoter()
    # print(ss.dependency_check.dependency_check)
    # print(ss.dependency_check.msg)
    # print(ss.devices)
    # ss.main()
    # ss.interface()
