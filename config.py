import shutil
import math
import os
from ui_utils import UiUtils


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


if __name__ == "__main__":
    cfg = Config()
    cfg.print_config(4)
