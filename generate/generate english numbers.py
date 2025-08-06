#!/usr/bin/python3
# pip install inflect
import inflect

p = inflect.engine()

def to_arabic_numeral(n):
    arabic_digits = "٠١٢٣٤٥٦٧٨٩"
    return ''.join(arabic_digits[int(d)] for d in str(n))

lines = []
for i in range(10001):
    english_word = p.number_to_words(i)
    arabic_num = to_arabic_numeral(i)
    lines.append(f"{i}\t{arabic_num}\t{english_word}")

with open("numbers_0_to_10000_english.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

lines = []
with open("winter_inserts_numbers_0_to_10000_english.sql", "w", encoding="utf-8") as f:
    f.write("delete from acorn_exam_score_names;\n")
for i in range(10001):
    arabic_num = to_arabic_numeral(i)
    english_word = p.number_to_words(i)
    sql = "insert into acorn_exam_score_names(score, name)"
    sql = sql + f" select {i}, '{english_word}';"
    lines.append(sql)

with open("winter_inserts_numbers_0_to_10000_english.sql", "a", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("File numbers_0_to_10000_english.txt has been created!")
