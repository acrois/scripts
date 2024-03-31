#!/usr/bin/env python3

import re
import sys

def detect_end_comment_pattern(line, group_word):
    """Detects the end-of-line comment pattern and returns the number of comment characters."""
    end_pattern_regex = r"([^\s\w])(\1+)(\s+{})$".format(re.escape(group_word))
    match = re.search(end_pattern_regex, line)
    if match:
        return len(match.group(2)) + 1
    else:
        return None

def is_line_commented(line, n):
    """Determines if a line is already commented based on leading comment characters."""
    lead_comment_regex = r"^(\s*)([^\s\w]{{{},}})".format(n-1)
    return re.match(lead_comment_regex, line) is not None

def toggle_comment_on_line(line, n, is_commented, enforce_state=None):
    """Toggles comment status of a line, with an option to enforce a specific state."""
    # Determine whether to add or remove comments based on the enforce_state and current state
    if enforce_state is not None:
        should_comment = enforce_state and not is_commented
        should_uncomment = not enforce_state and is_commented
    else:
        # Toggle the comment if no enforce_state is provided
        should_comment = not is_commented
        should_uncomment = is_commented

    if should_comment:
        # Add n-1 leading comment characters if the line should be commented
        indentation = re.match(r"^(\s*)", line).group(1)
        new_line = f"{indentation}{'#' * (n-1)} {line.lstrip()}"
    elif should_uncomment:
        # Remove leading comment characters if the line should be uncommented
        new_line = re.sub(r"^[^\s\w]{" + str(n-1) + r"}\s?", "", line, 1)
    else:
        # Leave the line unchanged if it already meets the desired state
        new_line = line

    return new_line

def toggle_comments_with_dynamic_n(lines, group_word, enforce_state=None):
    """Orchestrates the toggling process based on the specified group word and optional state enforcement."""
    toggled_lines = []

    for line in lines:
        n = detect_end_comment_pattern(line, group_word)
        if n:
            is_commented = is_line_commented(line, n)
            toggled_line = toggle_comment_on_line(line, n, is_commented, enforce_state)
            toggled_lines.append(toggled_line)
        else:
            toggled_lines.append(line)

    return toggled_lines

if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: toggle_comment.py <file_path> <group_word> [enforce_commented]")
        sys.exit(1)

    file_path = sys.argv[1]
    group_word = sys.argv[2]
    enforce_state = None if len(sys.argv) == 3 else sys.argv[3].lower() in ['true', '1', 'yes']

    # Perhaps in the future we can simply use stdin/stdout
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        toggled_lines = toggle_comments_with_dynamic_n(lines, group_word, enforce_state)

        for line in toggled_lines:
            print(line, end='')
    except Exception as e:
        print(f"Error processing file: {e}")
        sys.exit(2)
