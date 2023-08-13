#!/usr/bin/env python
"""
{
    "Author" : "Vamsi krishna",
    "Desc"   : "
                - This script generates MySQL's CREATE TABLE statement from sdi file
                - Provide the file with contents of sdi file as first argument
                - Output is directed to STDOUT
                "
}
"""

import json
import sys

# CONSTANTS
COLLATIONS = {
    1: {"collation": " big5_chinese_ci", "charset": " big5"},
    2: {"collation": " latin2_czech_cs", "charset": " latin2"},
    3: {"collation": " dec8_swedish_ci", "charset": " dec8"},
    4: {"collation": " cp850_general_ci", "charset": " cp850"},
    5: {"collation": " latin1_german1_ci", "charset": " latin1"},
    6: {"collation": " hp8_english_ci", "charset": " hp8"},
    7: {"collation": " koi8r_general_ci", "charset": " koi8r"},
    8: {"collation": " latin1_swedish_ci", "charset": " latin1"},
    9: {"collation": " latin2_general_ci", "charset": " latin2"},
    10: {"collation": " swe7_swedish_ci", "charset": " swe7"},
    11: {"collation": " ascii_general_ci", "charset": " ascii"},
    12: {"collation": " ujis_japanese_ci", "charset": " ujis"},
    13: {"collation": " sjis_japanese_ci", "charset": " sjis"},
    14: {"collation": " cp1251_bulgarian_ci", "charset": " cp1251"},
    15: {"collation": " latin1_danish_ci", "charset": " latin1"},
    16: {"collation": " hebrew_general_ci", "charset": " hebrew"},
    18: {"collation": " tis620_thai_ci", "charset": " tis620"},
    19: {"collation": " euckr_korean_ci", "charset": " euckr"},
    20: {"collation": " latin7_estonian_cs", "charset": " latin7"},
    21: {"collation": " latin2_hungarian_ci", "charset": " latin2"},
    22: {"collation": " koi8u_general_ci", "charset": " koi8u"},
    23: {"collation": " cp1251_ukrainian_ci", "charset": " cp1251"},
    24: {"collation": " gb2312_chinese_ci", "charset": " gb2312"},
    25: {"collation": " greek_general_ci", "charset": " greek"},
    26: {"collation": " cp1250_general_ci", "charset": " cp1250"},
    27: {"collation": " latin2_croatian_ci", "charset": " latin2"},
    28: {"collation": " gbk_chinese_ci", "charset": " gbk"},
    29: {"collation": " cp1257_lithuanian_ci", "charset": " cp1257"},
    30: {"collation": " latin5_turkish_ci", "charset": " latin5"},
    31: {"collation": " latin1_german2_ci", "charset": " latin1"},
    32: {"collation": " armscii8_general_ci", "charset": " armscii8"},
    33: {"collation": " utf8mb3_general_ci", "charset": " utf8mb3"},
    34: {"collation": " cp1250_czech_cs", "charset": " cp1250"},
    35: {"collation": " ucs2_general_ci", "charset": " ucs2"},
    36: {"collation": " cp866_general_ci", "charset": " cp866"},
    37: {"collation": " keybcs2_general_ci", "charset": " keybcs2"},
    38: {"collation": " macce_general_ci", "charset": " macce"},
    39: {"collation": " macroman_general_ci", "charset": " macroman"},
    40: {"collation": " cp852_general_ci", "charset": " cp852"},
    41: {"collation": " latin7_general_ci", "charset": " latin7"},
    42: {"collation": " latin7_general_cs", "charset": " latin7"},
    43: {"collation": " macce_bin", "charset": " macce"},
    44: {"collation": " cp1250_croatian_ci", "charset": " cp1250"},
    45: {"collation": " utf8mb4_general_ci", "charset": " utf8mb4"},
    46: {"collation": " utf8mb4_bin", "charset": " utf8mb4"},
    47: {"collation": " latin1_bin", "charset": " latin1"},
    48: {"collation": " latin1_general_ci", "charset": " latin1"},
    49: {"collation": " latin1_general_cs", "charset": " latin1"},
    50: {"collation": " cp1251_bin", "charset": " cp1251"},
    51: {"collation": " cp1251_general_ci", "charset": " cp1251"},
    52: {"collation": " cp1251_general_cs", "charset": " cp1251"},
    53: {"collation": " macroman_bin", "charset": " macroman"},
    54: {"collation": " utf16_general_ci", "charset": " utf16"},
    55: {"collation": " utf16_bin", "charset": " utf16"},
    56: {"collation": " utf16le_general_ci", "charset": " utf16le"},
    57: {"collation": " cp1256_general_ci", "charset": " cp1256"},
    58: {"collation": " cp1257_bin", "charset": " cp1257"},
    59: {"collation": " cp1257_general_ci", "charset": " cp1257"},
    60: {"collation": " utf32_general_ci", "charset": " utf32"},
    61: {"collation": " utf32_bin", "charset": " utf32"},
    62: {"collation": " utf16le_bin", "charset": " utf16le"},
    63: {"collation": " binary", "charset": " binary"},
    64: {"collation": " armscii8_bin", "charset": " armscii8"},
    65: {"collation": " ascii_bin", "charset": " ascii"},
    66: {"collation": " cp1250_bin", "charset": " cp1250"},
    67: {"collation": " cp1256_bin", "charset": " cp1256"},
    68: {"collation": " cp866_bin", "charset": " cp866"},
    69: {"collation": " dec8_bin", "charset": " dec8"},
    70: {"collation": " greek_bin", "charset": " greek"},
    71: {"collation": " hebrew_bin", "charset": " hebrew"},
    72: {"collation": " hp8_bin", "charset": " hp8"},
    73: {"collation": " keybcs2_bin", "charset": " keybcs2"},
    74: {"collation": " koi8r_bin", "charset": " koi8r"},
    75: {"collation": " koi8u_bin", "charset": " koi8u"},
    76: {"collation": " utf8mb3_tolower_ci", "charset": " utf8mb3"},
    77: {"collation": " latin2_bin", "charset": " latin2"},
    78: {"collation": " latin5_bin", "charset": " latin5"},
    79: {"collation": " latin7_bin", "charset": " latin7"},
    80: {"collation": " cp850_bin", "charset": " cp850"},
    81: {"collation": " cp852_bin", "charset": " cp852"},
    82: {"collation": " swe7_bin", "charset": " swe7"},
    83: {"collation": " utf8mb3_bin", "charset": " utf8mb3"},
    84: {"collation": " big5_bin", "charset": " big5"},
    85: {"collation": " euckr_bin", "charset": " euckr"},
    86: {"collation": " gb2312_bin", "charset": " gb2312"},
    87: {"collation": " gbk_bin", "charset": " gbk"},
    88: {"collation": " sjis_bin", "charset": " sjis"},
    89: {"collation": " tis620_bin", "charset": " tis620"},
    90: {"collation": " ucs2_bin", "charset": " ucs2"},
    91: {"collation": " ujis_bin", "charset": " ujis"},
    92: {"collation": " geostd8_general_ci", "charset": " geostd8"},
    93: {"collation": " geostd8_bin", "charset": " geostd8"},
    94: {"collation": " latin1_spanish_ci", "charset": " latin1"},
    95: {"collation": " cp932_japanese_ci", "charset": " cp932"},
    96: {"collation": " cp932_bin", "charset": " cp932"},
    97: {"collation": " eucjpms_japanese_ci", "charset": " eucjpms"},
    98: {"collation": " eucjpms_bin", "charset": " eucjpms"},
    99: {"collation": " cp1250_polish_ci", "charset": " cp1250"},
    101: {"collation": " utf16_unicode_ci", "charset": " utf16"},
    102: {"collation": " utf16_icelandic_ci", "charset": " utf16"},
    103: {"collation": " utf16_latvian_ci", "charset": " utf16"},
    104: {"collation": " utf16_romanian_ci", "charset": " utf16"},
    105: {"collation": " utf16_slovenian_ci", "charset": " utf16"},
    106: {"collation": " utf16_polish_ci", "charset": " utf16"},
    107: {"collation": " utf16_estonian_ci", "charset": " utf16"},
    108: {"collation": " utf16_spanish_ci", "charset": " utf16"},
    109: {"collation": " utf16_swedish_ci", "charset": " utf16"},
    110: {"collation": " utf16_turkish_ci", "charset": " utf16"},
    111: {"collation": " utf16_czech_ci", "charset": " utf16"},
    112: {"collation": " utf16_danish_ci", "charset": " utf16"},
    113: {"collation": " utf16_lithuanian_ci", "charset": " utf16"},
    114: {"collation": " utf16_slovak_ci", "charset": " utf16"},
    115: {"collation": " utf16_spanish2_ci", "charset": " utf16"},
    116: {"collation": " utf16_roman_ci", "charset": " utf16"},
    117: {"collation": " utf16_persian_ci", "charset": " utf16"},
    118: {"collation": " utf16_esperanto_ci", "charset": " utf16"},
    119: {"collation": " utf16_hungarian_ci", "charset": " utf16"},
    120: {"collation": " utf16_sinhala_ci", "charset": " utf16"},
    121: {"collation": " utf16_german2_ci", "charset": " utf16"},
    122: {"collation": " utf16_croatian_ci", "charset": " utf16"},
    123: {"collation": " utf16_unicode_520_ci", "charset": " utf16"},
    124: {"collation": " utf16_vietnamese_ci", "charset": " utf16"},
    128: {"collation": " ucs2_unicode_ci", "charset": " ucs2"},
    129: {"collation": " ucs2_icelandic_ci", "charset": " ucs2"},
    130: {"collation": " ucs2_latvian_ci", "charset": " ucs2"},
    131: {"collation": " ucs2_romanian_ci", "charset": " ucs2"},
    132: {"collation": " ucs2_slovenian_ci", "charset": " ucs2"},
    133: {"collation": " ucs2_polish_ci", "charset": " ucs2"},
    134: {"collation": " ucs2_estonian_ci", "charset": " ucs2"},
    135: {"collation": " ucs2_spanish_ci", "charset": " ucs2"},
    136: {"collation": " ucs2_swedish_ci", "charset": " ucs2"},
    137: {"collation": " ucs2_turkish_ci", "charset": " ucs2"},
    138: {"collation": " ucs2_czech_ci", "charset": " ucs2"},
    139: {"collation": " ucs2_danish_ci", "charset": " ucs2"},
    140: {"collation": " ucs2_lithuanian_ci", "charset": " ucs2"},
    141: {"collation": " ucs2_slovak_ci", "charset": " ucs2"},
    142: {"collation": " ucs2_spanish2_ci", "charset": " ucs2"},
    143: {"collation": " ucs2_roman_ci", "charset": " ucs2"},
    144: {"collation": " ucs2_persian_ci", "charset": " ucs2"},
    145: {"collation": " ucs2_esperanto_ci", "charset": " ucs2"},
    146: {"collation": " ucs2_hungarian_ci", "charset": " ucs2"},
    147: {"collation": " ucs2_sinhala_ci", "charset": " ucs2"},
    148: {"collation": " ucs2_german2_ci", "charset": " ucs2"},
    149: {"collation": " ucs2_croatian_ci", "charset": " ucs2"},
    150: {"collation": " ucs2_unicode_520_ci", "charset": " ucs2"},
    151: {"collation": " ucs2_vietnamese_ci", "charset": " ucs2"},
    159: {"collation": " ucs2_general_mysql500_ci", "charset": " ucs2"},
    160: {"collation": " utf32_unicode_ci", "charset": " utf32"},
    161: {"collation": " utf32_icelandic_ci", "charset": " utf32"},
    162: {"collation": " utf32_latvian_ci", "charset": " utf32"},
    163: {"collation": " utf32_romanian_ci", "charset": " utf32"},
    164: {"collation": " utf32_slovenian_ci", "charset": " utf32"},
    165: {"collation": " utf32_polish_ci", "charset": " utf32"},
    166: {"collation": " utf32_estonian_ci", "charset": " utf32"},
    167: {"collation": " utf32_spanish_ci", "charset": " utf32"},
    168: {"collation": " utf32_swedish_ci", "charset": " utf32"},
    169: {"collation": " utf32_turkish_ci", "charset": " utf32"},
    170: {"collation": " utf32_czech_ci", "charset": " utf32"},
    171: {"collation": " utf32_danish_ci", "charset": " utf32"},
    172: {"collation": " utf32_lithuanian_ci", "charset": " utf32"},
    173: {"collation": " utf32_slovak_ci", "charset": " utf32"},
    174: {"collation": " utf32_spanish2_ci", "charset": " utf32"},
    175: {"collation": " utf32_roman_ci", "charset": " utf32"},
    176: {"collation": " utf32_persian_ci", "charset": " utf32"},
    177: {"collation": " utf32_esperanto_ci", "charset": " utf32"},
    178: {"collation": " utf32_hungarian_ci", "charset": " utf32"},
    179: {"collation": " utf32_sinhala_ci", "charset": " utf32"},
    180: {"collation": " utf32_german2_ci", "charset": " utf32"},
    181: {"collation": " utf32_croatian_ci", "charset": " utf32"},
    182: {"collation": " utf32_unicode_520_ci", "charset": " utf32"},
    183: {"collation": " utf32_vietnamese_ci", "charset": " utf32"},
    192: {"collation": " utf8mb3_unicode_ci", "charset": " utf8mb3"},
    193: {"collation": " utf8mb3_icelandic_ci", "charset": " utf8mb3"},
    194: {"collation": " utf8mb3_latvian_ci", "charset": " utf8mb3"},
    195: {"collation": " utf8mb3_romanian_ci", "charset": " utf8mb3"},
    196: {"collation": " utf8mb3_slovenian_ci", "charset": " utf8mb3"},
    197: {"collation": " utf8mb3_polish_ci", "charset": " utf8mb3"},
    198: {"collation": " utf8mb3_estonian_ci", "charset": " utf8mb3"},
    199: {"collation": " utf8mb3_spanish_ci", "charset": " utf8mb3"},
    200: {"collation": " utf8mb3_swedish_ci", "charset": " utf8mb3"},
    201: {"collation": " utf8mb3_turkish_ci", "charset": " utf8mb3"},
    202: {"collation": " utf8mb3_czech_ci", "charset": " utf8mb3"},
    203: {"collation": " utf8mb3_danish_ci", "charset": " utf8mb3"},
    204: {"collation": " utf8mb3_lithuanian_ci", "charset": " utf8mb3"},
    205: {"collation": " utf8mb3_slovak_ci", "charset": " utf8mb3"},
    206: {"collation": " utf8mb3_spanish2_ci", "charset": " utf8mb3"},
    207: {"collation": " utf8mb3_roman_ci", "charset": " utf8mb3"},
    208: {"collation": " utf8mb3_persian_ci", "charset": " utf8mb3"},
    209: {"collation": " utf8mb3_esperanto_ci", "charset": " utf8mb3"},
    210: {"collation": " utf8mb3_hungarian_ci", "charset": " utf8mb3"},
    211: {"collation": " utf8mb3_sinhala_ci", "charset": " utf8mb3"},
    212: {"collation": " utf8mb3_german2_ci", "charset": " utf8mb3"},
    213: {"collation": " utf8mb3_croatian_ci", "charset": " utf8mb3"},
    214: {"collation": " utf8mb3_unicode_520_ci", "charset": " utf8mb3"},
    215: {"collation": " utf8mb3_vietnamese_ci", "charset": " utf8mb3"},
    223: {"collation": " utf8mb3_general_mysql500_ci", "charset": " utf8mb3"},
    224: {"collation": " utf8mb4_unicode_ci", "charset": " utf8mb4"},
    225: {"collation": " utf8mb4_icelandic_ci", "charset": " utf8mb4"},
    226: {"collation": " utf8mb4_latvian_ci", "charset": " utf8mb4"},
    227: {"collation": " utf8mb4_romanian_ci", "charset": " utf8mb4"},
    228: {"collation": " utf8mb4_slovenian_ci", "charset": " utf8mb4"},
    229: {"collation": " utf8mb4_polish_ci", "charset": " utf8mb4"},
    230: {"collation": " utf8mb4_estonian_ci", "charset": " utf8mb4"},
    231: {"collation": " utf8mb4_spanish_ci", "charset": " utf8mb4"},
    232: {"collation": " utf8mb4_swedish_ci", "charset": " utf8mb4"},
    233: {"collation": " utf8mb4_turkish_ci", "charset": " utf8mb4"},
    234: {"collation": " utf8mb4_czech_ci", "charset": " utf8mb4"},
    235: {"collation": " utf8mb4_danish_ci", "charset": " utf8mb4"},
    236: {"collation": " utf8mb4_lithuanian_ci", "charset": " utf8mb4"},
    237: {"collation": " utf8mb4_slovak_ci", "charset": " utf8mb4"},
    238: {"collation": " utf8mb4_spanish2_ci", "charset": " utf8mb4"},
    239: {"collation": " utf8mb4_roman_ci", "charset": " utf8mb4"},
    240: {"collation": " utf8mb4_persian_ci", "charset": " utf8mb4"},
    241: {"collation": " utf8mb4_esperanto_ci", "charset": " utf8mb4"},
    242: {"collation": " utf8mb4_hungarian_ci", "charset": " utf8mb4"},
    243: {"collation": " utf8mb4_sinhala_ci", "charset": " utf8mb4"},
    244: {"collation": " utf8mb4_german2_ci", "charset": " utf8mb4"},
    245: {"collation": " utf8mb4_croatian_ci", "charset": " utf8mb4"},
    246: {"collation": " utf8mb4_unicode_520_ci", "charset": " utf8mb4"},
    247: {"collation": " utf8mb4_vietnamese_ci", "charset": " utf8mb4"},
    248: {"collation": " gb18030_chinese_ci", "charset": " gb18030"},
    249: {"collation": " gb18030_bin", "charset": " gb18030"},
    250: {"collation": " gb18030_unicode_520_ci", "charset": " gb18030"},
    255: {"collation": " utf8mb4_0900_ai_ci", "charset": " utf8mb4"},
    256: {"collation": " utf8mb4_de_pb_0900_ai_ci", "charset": " utf8mb4"},
    257: {"collation": " utf8mb4_is_0900_ai_ci", "charset": " utf8mb4"},
    258: {"collation": " utf8mb4_lv_0900_ai_ci", "charset": " utf8mb4"},
    259: {"collation": " utf8mb4_ro_0900_ai_ci", "charset": " utf8mb4"},
    260: {"collation": " utf8mb4_sl_0900_ai_ci", "charset": " utf8mb4"},
    261: {"collation": " utf8mb4_pl_0900_ai_ci", "charset": " utf8mb4"},
    262: {"collation": " utf8mb4_et_0900_ai_ci", "charset": " utf8mb4"},
    263: {"collation": " utf8mb4_es_0900_ai_ci", "charset": " utf8mb4"},
    264: {"collation": " utf8mb4_sv_0900_ai_ci", "charset": " utf8mb4"},
    265: {"collation": " utf8mb4_tr_0900_ai_ci", "charset": " utf8mb4"},
    266: {"collation": " utf8mb4_cs_0900_ai_ci", "charset": " utf8mb4"},
    267: {"collation": " utf8mb4_da_0900_ai_ci", "charset": " utf8mb4"},
    268: {"collation": " utf8mb4_lt_0900_ai_ci", "charset": " utf8mb4"},
    269: {"collation": " utf8mb4_sk_0900_ai_ci", "charset": " utf8mb4"},
    270: {"collation": " utf8mb4_es_trad_0900_ai_ci", "charset": " utf8mb4"},
    271: {"collation": " utf8mb4_la_0900_ai_ci", "charset": " utf8mb4"},
    273: {"collation": " utf8mb4_eo_0900_ai_ci", "charset": " utf8mb4"},
    274: {"collation": " utf8mb4_hu_0900_ai_ci", "charset": " utf8mb4"},
    275: {"collation": " utf8mb4_hr_0900_ai_ci", "charset": " utf8mb4"},
    277: {"collation": " utf8mb4_vi_0900_ai_ci", "charset": " utf8mb4"},
    278: {"collation": " utf8mb4_0900_as_cs", "charset": " utf8mb4"},
    279: {"collation": " utf8mb4_de_pb_0900_as_cs", "charset": " utf8mb4"},
    280: {"collation": " utf8mb4_is_0900_as_cs", "charset": " utf8mb4"},
    281: {"collation": " utf8mb4_lv_0900_as_cs", "charset": " utf8mb4"},
    282: {"collation": " utf8mb4_ro_0900_as_cs", "charset": " utf8mb4"},
    283: {"collation": " utf8mb4_sl_0900_as_cs", "charset": " utf8mb4"},
    284: {"collation": " utf8mb4_pl_0900_as_cs", "charset": " utf8mb4"},
    285: {"collation": " utf8mb4_et_0900_as_cs", "charset": " utf8mb4"},
    286: {"collation": " utf8mb4_es_0900_as_cs", "charset": " utf8mb4"},
    287: {"collation": " utf8mb4_sv_0900_as_cs", "charset": " utf8mb4"},
    288: {"collation": " utf8mb4_tr_0900_as_cs", "charset": " utf8mb4"},
    289: {"collation": " utf8mb4_cs_0900_as_cs", "charset": " utf8mb4"},
    290: {"collation": " utf8mb4_da_0900_as_cs", "charset": " utf8mb4"},
    291: {"collation": " utf8mb4_lt_0900_as_cs", "charset": " utf8mb4"},
    292: {"collation": " utf8mb4_sk_0900_as_cs", "charset": " utf8mb4"},
    293: {"collation": " utf8mb4_es_trad_0900_as_cs", "charset": " utf8mb4"},
    294: {"collation": " utf8mb4_la_0900_as_cs", "charset": " utf8mb4"},
    296: {"collation": " utf8mb4_eo_0900_as_cs", "charset": " utf8mb4"},
    297: {"collation": " utf8mb4_hu_0900_as_cs", "charset": " utf8mb4"},
    298: {"collation": " utf8mb4_hr_0900_as_cs", "charset": " utf8mb4"},
    300: {"collation": " utf8mb4_vi_0900_as_cs", "charset": " utf8mb4"},
    303: {"collation": " utf8mb4_ja_0900_as_cs", "charset": " utf8mb4"},
    304: {"collation": " utf8mb4_ja_0900_as_cs_ks", "charset": " utf8mb4"},
    305: {"collation": " utf8mb4_0900_as_ci", "charset": " utf8mb4"},
    306: {"collation": " utf8mb4_ru_0900_ai_ci", "charset": " utf8mb4"},
    307: {"collation": " utf8mb4_ru_0900_as_cs", "charset": " utf8mb4"},
    308: {"collation": " utf8mb4_zh_0900_as_cs", "charset": " utf8mb4"},
    309: {"collation": " utf8mb4_0900_bin", "charset": " utf8mb4"},
    310: {"collation": " utf8mb4_nb_0900_ai_ci", "charset": " utf8mb4"},
    311: {"collation": " utf8mb4_nb_0900_as_cs", "charset": " utf8mb4"},
    312: {"collation": " utf8mb4_nn_0900_ai_ci", "charset": " utf8mb4"},
    313: {"collation": " utf8mb4_nn_0900_as_cs", "charset": " utf8mb4"},
    314: {"collation": " utf8mb4_sr_latn_0900_ai_ci", "charset": " utf8mb4"},
    315: {"collation": " utf8mb4_sr_latn_0900_as_cs", "charset": " utf8mb4"},
    316: {"collation": " utf8mb4_bs_0900_ai_ci", "charset": " utf8mb4"},
    317: {"collation": " utf8mb4_bs_0900_as_cs", "charset": " utf8mb4"},
    318: {"collation": " utf8mb4_bg_0900_ai_ci", "charset": " utf8mb4"},
    319: {"collation": " utf8mb4_bg_0900_as_cs", "charset": " utf8mb4"},
    320: {"collation": " utf8mb4_gl_0900_ai_ci", "charset": " utf8mb4"},
    321: {"collation": " utf8mb4_gl_0900_as_cs", "charset": " utf8mb4"},
    322: {"collation": " utf8mb4_mn_cyrl_0900_ai_ci", "charset": " utf8mb4"},
    323: {"collation": " utf8mb4_mn_cyrl_0900_as_cs", "charset": " utf8mb4"}
}


# Classes
class ColumnBuilder:
    """
    This class is for generating column definitions

    Attributes:
        column_name
        column_type
        is_nullable
        is_auto_increment
        default_value_utf8_null
        default_value_utf8
        default_value_null
        hidden
        is_explicit_collation
        collation_id
        sql_column_def

    Methods:
        build_col_def(): Returns generated column definition

    #### MySQL Column Definition
    #### https://dev.mysql.com/doc/refman/8.0/en/create-table.html
    This is the column definition syntax of MySQL

    column_definition: {
    data_type [NOT NULL | NULL] [DEFAULT {literal | (expr)} ]
      [VISIBLE | INVISIBLE]
      [AUTO_INCREMENT] [UNIQUE [KEY]] [[PRIMARY] KEY]
      [COMMENT 'string']
      [COLLATE collation_name]
      [COLUMN_FORMAT {FIXED | DYNAMIC | DEFAULT}]
      [ENGINE_ATTRIBUTE [=] 'string']
      [SECONDARY_ENGINE_ATTRIBUTE [=] 'string']
      [STORAGE {DISK | MEMORY}]
      [reference_definition]
      [check_constraint_definition]
    | data_type
      [COLLATE collation_name]
      [GENERATED ALWAYS] AS (expr)
      [VIRTUAL | STORED] [NOT NULL | NULL]
      [VISIBLE | INVISIBLE]
      [UNIQUE [KEY]] [[PRIMARY] KEY]
      [COMMENT 'string']
      [reference_definition]
      [check_constraint_definition]
    }
    """

    def __init__(self, json_column_def):
        self.column_name = json_column_def["name"]
        self.column_type = json_column_def["column_type_utf8"]
        self.is_nullable = json_column_def["is_nullable"]
        self.is_auto_increment = json_column_def["is_auto_increment"]
        self.default_value_utf8_null = json_column_def["default_value_utf8_null"]
        self.default_value_utf8 = json_column_def["default_value_utf8"]
        self.default_value_null = json_column_def["default_value_null"]
        self.hidden = json_column_def["hidden"]
        self.is_explicit_collation = json_column_def["is_explicit_collation"]
        self.collation_id = json_column_def["collation_id"]
        self.sql_column_def = []

    # Commneted to retain code for future improvements
    # def get_collation_info(self, collation_id):
    #     collation = COLLATIONS[collation_id]["collation"]
    #     charset = COLLATIONS[collation_id]["charset"]
    #     return collation, charset

    def build_col_def(self):
        if self.column_name:
            self.sql_column_def.append(self.column_name)

        if self.column_type:
            self.sql_column_def.append(self.column_type)

        if not self.is_nullable:
            self.sql_column_def.append("NOT NULL")
            if not self.default_value_utf8_null:
                self.sql_column_def.append(f"DEFAULT '{self.default_value_utf8}'")

        if self.default_value_null:
            self.sql_column_def.append("DEFAULT NULL")

        if self.hidden == 4:
            self.sql_column_def.append("INVISIBLE")

        if self.is_auto_increment:
            self.sql_column_def.append("AUTO_INCREMENT")

        # Commented to retain code for future improvements
        # if self.is_explicit_collation:
        #     collation, charset = self.get_collation_info(self.collation_id)
        #     self.sql_column_def.append(f"character set {charset.upper()} collate {collation.upper()}")

        return ' '.join(map(str, self.sql_column_def))


class TableBuilder:
    """
    This class if for generating table definition header and footer

    Attributes:
        name
        engine
        collation_id

    Methods:
        generate_header(): returns "CREATE TABLE IF NOT EXISTS <table_name> ("
        generate_footer(): return ") ENGINE=<engine_name> DEFAULT CHARSET = <charset>;"
    """

    def __init__(self, dd_object):
        self.name = dd_object["name"]
        self.engine = dd_object["engine"]
        self.collation_id = dd_object["collation_id"]

    def generate_header(self):
        return f"CREATE TABLE IF NOT EXISTS {self.name} ("

    def generate_footer(self):
        charset = COLLATIONS[self.collation_id]["charset"]
        return f") ENGINE={self.engine} DEFAULT CHARSET={charset};"


if __name__ == "__main__":
    JSON_FILE = sys.argv[1]

    with open(JSON_FILE) as f:
        data = json.load(f)

    ALL_COLUMNS = []
    TABLE_BUILDER = TableBuilder(data["dd_object"])
    TABLE_HEADER = TABLE_BUILDER.generate_header()
    TABLE_FOOTER = TABLE_BUILDER.generate_footer()

    print(TABLE_HEADER)
    for col in data["dd_object"]["columns"]:
        new_col = ColumnBuilder(col)
        col_def = new_col.build_col_def()
        ALL_COLUMNS.append(col_def)
    print(',\n'.join(map(str, ALL_COLUMNS)))
    print(TABLE_FOOTER)
