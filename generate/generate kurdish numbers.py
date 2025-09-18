#!/usr/bin/python3
# Kurdish Kurmanji translations for 0–10, teens, tens, and hundreds
kurmanji_words_0_10 = [
    "sifir", "yek", "du", "sê", "çar", "pênc", "şeş", "heft", "heşt", "neh", "deh"
]

kurmanji_teens = [
    "yazdeh", "duwazdeh", "sêzdeh", "çardeh", "pazdeh",
    "şazdeh", "hevdeh", "hejdeh", "nozdeh"
]

kurmanji_tens = [
    "", "", "bîst", "sih", "çil", "pêncî", "şêst", "heftê", "heştê", "nod"
]

kurmanji_hundreds = [
    "", "sed", "du sed", "sê sed", "çar sed",
    "pênc sed", "şeş sed", "heft sed", "heşt sed", "neh sed"
]

def number_to_kurmanji(n):
    if n <= 10:
        return kurmanji_words_0_10[n]
    elif 11 <= n <= 19:
        return kurmanji_teens[n - 11]
    elif 20 <= n <= 99:
        tens = n // 10
        ones = n % 10
        if ones == 0:
            return kurmanji_tens[tens]
        else:
            return kurmanji_tens[tens] + " û " + kurmanji_words_0_10[ones]
    elif 100 <= n <= 999:
        hundreds = n // 100
        remainder = n % 100
        if remainder == 0:
            return kurmanji_hundreds[hundreds]
        else:
            return kurmanji_hundreds[hundreds] + " û " + number_to_kurmanji(remainder)
    elif 1000 <= n <= 10999:
        thousands = n // 1000
        remainder = n % 1000
        if remainder == 0:
            return kurmanji_words_0_10[thousands] + " hezar"
        else:
            return kurmanji_words_0_10[thousands] + " hezar û " + number_to_kurmanji(remainder)
    else:
        return ""

# Arabic numeral representation
def to_arabic_numeral(n):
    arabic_digits = "٠١٢٣٤٥٦٧٨٩"
    return ''.join(arabic_digits[int(d)] for d in str(n))

# Generate and save the file
lines = []
for i in range(2001):
    arabic_num = to_arabic_numeral(i)
    kurmanji_word = number_to_kurmanji(i)
    lines.append(f"{i}\t{arabic_num}\t{kurmanji_word}")

with open("numbers_0_to_10000_kurmanji.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

lines = []
with open("winter_inserts_numbers_0_to_10000_kurmanji.sql", "w", encoding="utf-8") as f:
    f.write("delete from winter_translate_attributes where model_type='Acorn\\Exam\\Models\\ScoreName' and locale='ku';\n")
for i in range(2001):
    arabic_num = to_arabic_numeral(i)
    kurmanji_word = number_to_kurmanji(i)
    sql = "insert into winter_translate_attributes(locale, model_id, model_type, attribute_data)"
    sql = sql + f" select 'ku', id, 'Acorn\\Exam\\Models\\ScoreName', '{{\"name\":\"{kurmanji_word}\",\"description\":\"\"}}'"
    sql = sql + f" from acorn_exam_score_names where score = {i};"
    lines.append(sql)

with open("winter_inserts_numbers_0_to_10000_kurmanji.sql", "a", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("File numbers_0_to_10000_kurmanji.txt has been created!")
