#!/usr/bin/env python3

import re
import sys

def detect_end_comment_pattern(line, group_word):
    end_pattern_regex = r"([^\s\w])(\1+)(\s+{})$".format(re.escape(group_word))
    match = re.search(end_pattern_regex, line)
    if match:
        return len(match.group(2)) + 1
    else:
        return None

def is_line_commented(line, n):
    lead_comment_regex = r"^(\s*)([^\s\w]{{{},}})".format(n-1)
    return re.match(lead_comment_regex, line) is not None

def toggle_comment_on_line(line, n, is_commented):
    if is_commented:
        new_line = re.sub(r"^[^\s\w]{" + str(n-1) + r"}\s?", "", line, 1)
    else:
        indentation = re.match(r"^(\s*)", line).group(1)
        new_line = f"{indentation}{'#' * (n-1)} {line.lstrip()}"
    return new_line

def toggle_comments_with_dynamic_n(lines, group_word):
    toggled_lines = []

    for line in lines:
        n = detect_end_comment_pattern(line, group_word)
        if n:
            is_commented = is_line_commented(line, n)
            toggled_line = toggle_comment_on_line(line, n, is_commented)
            toggled_lines.append(toggled_line)
        else:
            toggled_lines.append(line)

    return toggled_lines

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: toggle_comments.py <file_path> <group_word>")
        sys.exit(1)

    file_path = sys.argv[1]
    group_word = sys.argv[2]

    # Perhaps in the future we can simply use stdin/stdout
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        toggled_lines = toggle_comments_with_dynamic_n(lines, group_word)

        for line in toggled_lines:
            print(line, end='')
    except Exception as e:
        print(f"Error processing file: {e}")
        sys.exit(2)
