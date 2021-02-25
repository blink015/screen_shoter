import os
import sys
import time
import shutil
import re
from typing import List
from pprint import pprint
from dependency_check import DependencyCheck
from device_getter import DeviceGetter
from shot_utils import ShotUtils
from config import Config


class ScreenShoter:
    """
    main class
    todo, lots of error handler to add...
    todo, future? get device crash log???
    """
    def __init__(self):
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
                print("please select your target device:")
                counter = 1
                for k, v in self.devices.items():
                    if v["os"] == "Android" or v["os"] == "iOS":  # in case of display infos separately
                        print("{}. name: {}\tos: {}\tos_version: {}".
                              format(counter, v["product_name"].ljust(21, " "),
                                     v["os"].ljust(9, " "), v["os_version"]))
                    else:
                        raise Exception("no 'os' attribute found within devices's dict.")
                    counter += 1
                number = input("type number({}-{}) here to select: ".format(1, len(self.devices)))
                return number
        else:
            print("no device/simulator found...")
            res = input("press enter to retry: ")
            return res

    def device_select_interface(self):
        """
        no device UI / select device UI
        specify device by set the instance variable
        """
        print("please select your target device:")
        counter = 1
        for k, v in self.devices.items():
            if v["os"] == "Android" or v["os"] == "iOS":  # in case of display infos separately
                print("{}. name: {}\tos: {}\tos_version: {}".format(counter, v["product_name"].ljust(21, " "),
                             v["os"].ljust(9, " "), v["os_version"]))
            else:
                raise Exception("no 'os' attribute found within devices's dict.")
            counter += 1

    def verify_input(self, input_str: str, lower_limit: int, upper_limit: int) -> bool:
        """
        varify if the input string is int like
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
            # print("[][][][][][][][]:" + repr(input_str))  ####
            if input_str == "":
                # print("##################")  ####
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
        choose one device, saved to instance variable
        todo: distinguish the "None" that no device, and the "None" that only one device???
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
                    number_str = input(input_desc)
                    if self.verify_input(number_str, 1, len(self.devices)):
                        self.device_id = list(self.devices.keys())[int(number_str) - 1]
                        break
                    elif number_str == "":
                        print("reloading devices..."); time.sleep(0.7)
                        self.devices = DeviceGetter().devices
                    else:
                        print("a valid number is need{}".format("."*counter)); time.sleep(1)
            else:
                print("no device/simulator found...")
                input("press enter to retry: ")
                print("reloading devices..."); time.sleep(0.7)
                self.devices = DeviceGetter().devices

            counter += 1

    def choose_command(self) -> int:
        """
        main UI, choose one option to do something
        """
        cur_device_dict = self.devices[self.device_id]
        os.system("clear")  # clear screen
        print("current deivce: {}   {} {}".format(cur_device_dict["product_name"],
                                                  cur_device_dict["os"], cur_device_dict["os_version"], ))
        print("choose your option below: ")
        print("1. to take screencap;")
        print("2. to take screenrecord (Android only!);")
        print("9. to change target device/simulator;")
        print("0. to display current config;")

        while True:
            num = input("your choice: ")
            try:
                num = int(num)
                if num in [1, 2, 9, 0]:
                    break
                else:
                    raise Exception
            except Exception as e:
                print("please try again...")
        return num

    def rename_file(self):
        """
        call the rename_file method of ShotUtils
        """
        msg = "print enter to continue, type a new name to rename file: "
        while True:
            new_name = input(msg)
            if not new_name:
                break
            else:
                if self.shot_utils.rename_file(new_name):
                    break
                else:
                    print("please try to type an valid file name...")

    def main(self):
        """
        todo: include all code block of main method within try...except...?
              on error start next round?
        todoX: "press "q" to quit any where", add one input like method
                  q then sys.exit(); add a bit describe, sleep before quit?
                  NO need, must set shell preference in order to close window after "exit"
        todo: refine the code: function's docstring, class's docstring, class's Config...
        todo?: self.print(from, indent), from adb/py/..., indent is int
        todo: remove abandoned methods in some time
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
                    print("only one device detected...")
                    input("press enter to continue:")
                self.device_select()
            elif cmd_serial == 0:  # show all configs
                os.system("clear")
                header_lines = ["all configs displayed below, ",
                                "you can change them manually within source code: ",
                                "class Config, method __init__ ...",
                                " -------------------------------------------", ]  # in order to calculate rows occupied
                print("\n".join(header_lines))
                # self.config.print_config(4)  # why using specific value???
                self.config.print_config(len(header_lines))
            else:
                raise Exception("unexpected cmd_serial occuried...")

            counter += 1


if __name__ == "__main__":
    ss = ScreenShoter()
    # ss.main()  # moved to __init__ method
