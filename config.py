class Config:
    """
    save the config infos
    """
    def __init__(self):
        self.interface = 2  # which interface tobe used, 1 is default, 2 is simple version
        self.default_save_path = "~/Desktop/"  # default saveing path
        self.default_name_base = "demo"  # default name of screenshot / screenrecord
