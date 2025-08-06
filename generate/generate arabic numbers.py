#!/usr/bin/python3
# Arabic number words for 0-10 and basics
arabic_words_0_10 = [
    "صفر", "واحد", "اثنان", "ثلاثة", "أربعة",
    "خمسة", "ستة", "سبعة", "ثمانية", "تسعة", "عشرة"
]

arabic_tens = [
    "", "", "عشرون", "ثلاثون", "أربعون", "خمسون",
    "ستون", "سبعون", "ثمانون", "تسعون"
]

arabic_teens = [
    "أحد عشر", "اثنا عشر", "ثلاثة عشر", "أربعة عشر",
    "خمسة عشر", "ستة عشر", "سبعة عشر", "ثمانية عشر", "تسعة عشر"
]

arabic_hundreds = [
    "", "مائة", "مائتان", "ثلاثمائة", "أربعمائة",
    "خمسمائة", "ستمائة", "سبعمائة", "ثمانمائة", "تسعمائة"
]

arabic_thousands = [
    '',
    'ألف',
    'ألفان',
    'ثلاثة آلاف',
    'أربعة آلاف',
    'خمسة آلاف',
    'ستة آلاف',
    'سبعة آلاف',
    'ثمانية آلاف',
    'تسعة آلاف',
    'عشرة آلاف'
]

def number_to_arabic_words(n):
    if n <= 10:
        return arabic_words_0_10[n]
    elif 11 <= n <= 19:
        return arabic_teens[n-11]
    elif 20 <= n <= 99:
        tens = n // 10
        ones = n % 10
        if ones == 0:
            return arabic_tens[tens]
        else:
            return arabic_words_0_10[ones] + " و " + arabic_tens[tens]
    elif 100 <= n <= 999:
        hundreds = n // 100
        remainder = n % 100
        if remainder == 0:
            return arabic_hundreds[hundreds]
        else:
            return arabic_hundreds[hundreds] + " و " + number_to_arabic_words(remainder)
    elif 1000 <= n <= 10999:
        thousands = n // 1000
        remainder = n % 1000
        if remainder == 0:
            return arabic_thousands[thousands]
        else:
            return arabic_thousands[thousands] + " و " + number_to_arabic_words(remainder)
    else:
        return ""

def to_arabic_numeral(n):
    arabic_digits = "٠١٢٣٤٥٦٧٨٩"
    return ''.join(arabic_digits[int(d)] for d in str(n))

lines = []
for i in range(10001):
    arabic_num = to_arabic_numeral(i)
    arabic_word = number_to_arabic_words(i)
    lines.append(f"{i}\t{arabic_num}\t{arabic_word}")

with open("numbers_0_to_10000_arabic.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

lines = []
with open("winter_inserts_numbers_0_to_10000_arabic.sql", "w", encoding="utf-8") as f:
    f.write("delete from winter_translate_attributes where model_type='Acorn\\Exam\\Models\\ScoreName' and locale='ar';\n")
for i in range(10001):
    arabic_num = to_arabic_numeral(i)
    arabic_word = number_to_arabic_words(i)
    sql = "insert into winter_translate_attributes(locale, model_id, model_type, attribute_data)"
    sql = sql + f" select 'ar', id, 'Acorn\\Exam\\Models\\ScoreName', '{{\"name\":\"{arabic_word}\",\"description\":\"\"}}'"
    sql = sql + f" from acorn_exam_score_names where score = {i};"
    lines.append(sql)

with open("winter_inserts_numbers_0_to_10000_arabic.sql", "a", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("File numbers_0_to_10000_arabic.txt has been created!")
