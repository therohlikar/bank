Config = {}
Config.openMenuKey = 38 --[E]
Config.maxAvailableAccounts = 5
Config.maxCards = 10

Config.defaultPerms = {
    ["balance"] = true,
    ["withdraw_take"] = true,
    ["withdraw_put"] = true,
    ["transfer"] = true,
    ["changetype"] = false,
    ["changeowner"] = false,
    ["changename"] = false,
    ["access"] = false,
    ["invoices"] = true,
    ["payinvoice"] = false,
    ["delete"] = false,
    ["cards"] = false
}

Config.idChars = {
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
}

Config.banks = {
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = 150.21488952636, ['y'] = -1040.4517822266, ['z'] = 29.37410736084
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = -350.95333862304, ['y'] = -49.429664611816, ['z'] = 49.042568206788
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = 314.43438720704, ['y'] = -278.61486816406, ['z'] = 54.170795440674
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = -1212.6108398438, ['y'] = -330.69589233398, ['z'] = 37.787036895752
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = -2962.4875488282, ['y'] = 483.02117919922, ['z'] = 15.703112602234
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = 1175.0009765625, ['y'] = 2706.8015136718, ['z'] = 38.094074249268
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 5.0, 
        ["range"] = 1.05
    },
    { 
        ["company"] = "fleeca", 
        ["coords"] = { 
            ['x'] = -111.97465515136, ['y'] = 6469.060546875, ['z'] = 31.626707077026
        },
        ["available"] = true,
        ["hidden"] = false,
        ["label"] = "[E] FLEECA BANK",
        ["mType"] = 25, 
        ["mColor"] = { 
            r = 90, 
            g = 175, 
            b = 44, 
            a = 0.6
        }, 
        ["distance"] = 15.0,
        ["range"] = 1.05
    }
}

Config.blips = {
    ["fleeca"] = {
        ["bType"] = 207, 
        ["bScale"] = 0.8, 
        ["bColor"] = 0, -- 2
        ["bDisplay"] = 3,
        ["bLabel"] = "FLEECA BANK"
    },
    ["maze"] = {
        ["bType"] = 207, 
        ["bScale"] = 0.6, 
        ["bColor"] = 0, -- 1
        ["bDisplay"] = 3,
        ["bLabel"] = "MAZE BANK"
    }
}

Config.ATMs = {"prop_atm_01", "prop_atm_02", "prop_atm_03", "prop_fleeca_atm"}