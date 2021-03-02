import os
import sys
import re
from collections import OrderedDict
from config import Config
from ui_utils import UiUtils


class Integrate():
    def __init__(self) -> None:
        self.config = Config()

    def integrate(self) -> None:
        """
        integreate each .py into a sigle executable file

        :return:
        """
        script_path = "/".join(os.path.abspath(sys.argv[0]).split("/")[:-1])
        script_files = ["config.py",
                        "dependency_check.py",
                        "device_getter.py",
                        "shot_utils.py",
                        "ui_utils.py",
                        "",
                        "main.py", ]  # files to integrate one by one (a "main.py" at last is necessary)
        from_locals = ["from {} import".format(x[:-3]) for x in script_files if x]  # used to exclude local imports
        output_file = "screen_shoter.py.command"
        output_path_file = "{}/{}".format(script_path, output_file)

        # create file, add execute privilege
        os.popen("touch {}".format(output_path_file))
        os.popen("chmod 777 {}".format(output_path_file))
        soft_link_path = "~/Desktop/{}".format(output_file)
        os.popen("ln -sf {} {}".format(output_path_file, soft_link_path))  # create soft link on Desktop for test

        # read files into dict/list
        imports = OrderedDict()  # remove duplication
        from_imports = OrderedDict()
        code_lines = []

        recording = True  # exclude the block below if __name__ == "__main__:":
        for file in script_files:
            if file:
                with open("{}/{}".format(script_path, file)) as temp:
                    for line in temp:
                        if line.startswith("import"):
                            recording = True
                            imports[line] = ""
                        elif line.startswith("from"):
                            recording = True
                            head = re.match(r"from.+import", line).group()
                            if head not in from_locals:
                                from_imports[line] = ""
                        elif line.startswith("if __name__ == "):
                            if not file == "main.py":
                                recording = False
                            else:
                                code_lines.append(line)  # keep the block below if __name__ == "__main__:" of main.py
                        elif recording:
                            code_lines.append(line)

        # handle continuous blanklines
        lines_to_del = []
        for i in range(1, len(code_lines) - 1):
            if re.match(r"^ *\n$", code_lines[i]) \
                    and re.match(r"^ *\n$", code_lines[i - 1]) \
                    and (not code_lines[i + 1].startswith("class")) \
                    and (not code_lines[i + 1].startswith("if __name__")):
                lines_to_del.append(i)

        lines_to_del.sort(reverse=True)
        for line_num in lines_to_del:
            code_lines.pop(line_num)

        # write list into file
        with open(output_path_file, 'w') as f:
            f.writelines("{}\n".format(self.config.interpreter_path))  # specify interpreter first
            f.writelines("# https://github.com/blink015/screen_shoter\n")
            for k in imports.keys():
                f.writelines(k)
            for k in from_imports.keys():
                f.writelines(k)
            # f.writelines("\n\n")
            for line in code_lines:
                f.writelines(line)
            # f.writelines("\n")

        UiUtils.sprint("done~")


if __name__ == "__main__":
    ig = Integrate()
    ig.integrate()
