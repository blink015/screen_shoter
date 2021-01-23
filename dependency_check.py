from subprocess import Popen, PIPE


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


if __name__ == "__main__":
    dc = DependencyCheck()
    print(dc.dependency_check)
    print(dc.msg)

