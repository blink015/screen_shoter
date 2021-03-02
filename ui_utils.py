import os
import time
from typing import List
from subprocess import Popen, PIPE

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


if __name__ == "__main__":
    # uu = UiUtils()
    # uu.sprint(("abc", "sdfsdfdf"), "[header]", 4)
    # print(uu.sinput("asdf: "))

    UiUtils.sprint(("abc", "sdfsdfdf"), "[header]", 4)
    print(UiUtils.sinput("asdf: "))
