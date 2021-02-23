from subprocess import Popen, PIPE
from collections import OrderedDict
from typing import List, Dict
from config import Config


class DeviceGetter:
    """
    get devices and their info through adb / ideviceinstaller, save to OrderedDict like:
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
        # ProductType and common name of iPhone. From internet, error may exists
        self.product_type_name = self.config.product_type_name
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
            android_devices[serialno]["os_version"] = other_infos["ro.build.version.release"]

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


if __name__ == "__main__":
    dg = DeviceGetter()
    print(dg.devices)
