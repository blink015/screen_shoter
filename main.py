import os
import sys
import time
import shutil
from typing import List
from pprint import pprint
from dependency_check import DependencyCheck
from device_getter import DeviceGetter
from config import Config

# static方法，定义Android截图类，iOS截图类，还是都放到main.py里？

# 其他类先固定方法，加不加_，固定后好引用
# 该加static的加一下，比如Android截图/截屏类，方便引用

class ScreenShoter:
    """
    main class
    todo, lots of error handler to add...
    """
    def __init__(self):
        self.config = Config()
        self.dependency_check = DependencyCheck()
        self.devices = DeviceGetter().devices

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
        self.main()

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

    def split_msg(self, strr: str, terminal_width: int) -> List:
        """
        according to terminal's column num, split long str to shorter ones
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

    def initial_interface(self) -> None:
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

    def initial_interface_simple(self) -> None:
        """
        in case of odd UI...
        :return:
        """
        print("\n" + self.dependency_check.msg)
        input("press enter to start: ")

    def main(self):
        # 判断是否有多个设备，是进入选择页，否进入主界面







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
