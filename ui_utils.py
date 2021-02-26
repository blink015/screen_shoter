import os
from typing import Tuple

class UiUtils():
    """
    custom print and input method.
    """
    def __init__(self) -> None:
        pass

    def sprint(self, content: Tuple or str, header: str = "", indent_blank: int = 0, sep: str = ' ', end: str = '\n') -> None:
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

    def sinput(self, prompt: str) -> str:
        """
        input "q" to close terminal.
        Terminal, Preferences > Profiles > Shell > When the shell exits > Close the window.

        :param prompt: prompt
        :return: the input
        """
        inputt = input(prompt)
        if inputt.lower() == "q":
            return os.popen("exit").readline()
        else:
            return inputt


if __name__ == "__main__":
    uu = UiUtils()
    print(uu.sinput("asdf: "))
    uu.sprint(("abc", "sdfsdfdf"), "[header]", 4)
