import os
import time
import traceback
from subprocess import Popen, PIPE
from config import Config


class ShotUtils():
    """
    screencap, screenrecord, rename methods included
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
        take screencap
        """
        print("taking screencap...")
        try:
            if os == "Android":
                self._screencap_Android(id)
            elif os == "iOS":
                self._screencap_iOS(id)
            # input("press enter to continue...")  # is it appropriate???
            return True
        except Exception as e:
            traceback.print_exc()
            print("sorry, screencap failed for some reason, please try again...")
            input("press enter to continue...")  # is it appropriate???
            return False

    def _screencap_Android(self, serialno: str) -> bool:
        """
        take screencap of Android, then pull to macbook
        """
        cmd = ["adb", "-s", serialno, "shell", "screencap", "-p", "{}{}{}"
               .format(self.default_save_path_android, self.default_name_base, self.default_suffix_img)]
        pp = Popen(cmd, stdout=PIPE, stderr=PIPE)  # os.popen can not get error massage here
        res = pp.communicate()  # for this command, error message stored in res[1] if error uccured
        if res[1]:  # if error occured
            print("screencap failed...")
            print("[adb]{}".format(res[1].decode("utf-8").strip("\n ")))
            # input("press enter to continue...")
            return False
        else:  # pull to local and optionally rename
            print("screencap saved to device/emulator \"/sdcard/{}.png\""
                  .format(self.default_name_base))
            name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_img)
            if self._pull_from_android(serialno, name_safe, "screencap"):
                return True
            else:
                return False

    def _screencap_iOS(self, udid: str) -> bool:
        """
        take screencap of iOS (no need to pull like Android)
        """
        name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_img)
        # res = os.popen("idevicescreenshot -u {} {}{}"
        #                .format(udid, self.default_save_path, name_safe)).read()
        pp = Popen("idevicescreenshot -u {} {}{}".format(udid, self.default_save_path, name_safe),
                   shell=True, stdout=PIPE, stderr=PIPE)  # shell=True is necessary here somehow...
        res = pp.communicate()[0].decode("utf-8").strip("\n ")  # success/error message all here
        res = res.strip("\n ")
        if "Screenshot saved to" in res:
            print("[libimobiledevice]{}".format(res))
            return True
        else:
            print("screencap failed...")
            print("[libimobiledevice]{}".format(res))
            return False

    def screenrecord(self, os: str, id: str) -> bool:
        """
        take screenrecord, then pull to macbook
        """
        # print("taking screenrecord...")
        try:
            if os == "Android":
                print("taking screenrecord...")
                self._screenrecord_Android(id, self._get_resolution(id), self.time_limit)
            else:
                self._screenrecord_iOS(id)
                return False  # not support currently...
            return True
        except Exception as e:
            traceback.print_exc()
            print("sorry, screenrecord failed for some reason, please try again...")
            input("press enter to continue...")
            return False

    def _screenrecord_Android(self, serialno: str, resolution:str, time_limit:int) -> bool:
        """
        take screenrecord of Android, then pull to macbook.
        currently the resolution and time_limit can be adjust (attribute of class Config).
        todo: add more parameters if necessary...
        """
        if int(time_limit) !=0:
            print("resolution:{}; max length:{}s".format(resolution, time_limit))
            print("PRESS Ctrl+C to STOP recording:")
            cmd = ["adb", "-s", serialno, "shell", "screenrecord",
                   "--size", resolution, "--time-limit", str(int(time_limit)), "{}{}{}"
                   .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video)]
        else:
            print("resolution: {}; max length: 180s (default)".format(resolution))
            print("PRESS Ctrl+C to STOP recording:")
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
            print("\nscreenrecord saved to device/emulator \"{}{}{}\""
                  .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video))
        elif res[1]:  # error occured
            print("screencap failed...")
            print("[adb]{}".format(res[1]))
            input("press enter to continue...")
            return False
        else:  # till max length
            print("max length reached...")
            print("screenrecord saved to device/emulator \"{}{}{}\""
                  .format(self.default_save_path_android, self.default_name_base, self.default_suffix_video))

        name_safe = self._get_safe_names(self.default_name_base, self.default_suffix_video)
        if self._pull_from_android(serialno, name_safe, "screenrecord"):
            return True
        else:
            return False

    def _screenrecord_iOS(self, udid: str) -> None:
        """
        ideviceinstaller do NOT support take screenrecord of iOS...
        """
        print("screenrecord for iOS is NOT SUPPORT by ideviceinstaller...")
        input("press enter to continue...")

    def _pull_from_android(self, serialno: str, name_safe: str, shot_type: str) -> bool:
        """
        pull screencap/screenrecord from android to macbook
        """
        suffix = ""
        if shot_type == "screencap":
            suffix = self.default_suffix_img
        elif shot_type == "screenrecord":
            suffix = self.default_suffix_video

        print("pulling to local...")
        res = os.popen("adb -s {} pull {}{}{} {}{}"
                       .format(serialno, self.default_save_path_android, self.default_name_base,
                               suffix, self.default_save_path, name_safe)).read()
        print("[adb]{}".format(res), end="")

        if not "error" in res:
            print("screenrecord finished, saved to \"{}{}\""
                  .format(self.default_save_path, name_safe))
            return True
        else:
            print("pulling failed...")
            return False

    def _get_safe_names(self, name: str, suffix: str) -> str:
        """
        get an "save_name" according to one file name and it's suffix, to avoid duplicate names
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
        rename file after saved to local
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
            print("rename failed...")
            print("[terminal]" + res)
            self.current_name = old_name  # do not forget to reset
            return False
        else:
            if new_name + suffix != new_name_safe:
                print("new name \"{}\" exists, add number at the end. ".format(new_name))
            print(".../{} renamed to .../{}".format(old_name, new_name_safe))
            input("press enter to continue...")
            return True

    def _get_resolution(self, serialno: str) -> str:
        """
        calculate resolution which used for screenrecord, e.g. 540x1170
        """
        res = os.popen("adb -s {} shell dumpsys window displays | grep init"
                       .format(serialno)).read()
        # e.g. "   init=1080x2340 440dpi cur=1080x2340 app=1080x2120 rng=1080x990-2250x2120"
        temp = res.strip().split(" ")[0]  # e.g. "init=1080x1920"
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


if __name__ == "__main__":
    su = ShotUtils()
    su.screencap("Android", "af699j76")
    su.screencap("iOS", "445CC7AB8D8F7A105CD90D04F65D29B3F945A814AFMQIQF")
    print("done~")
