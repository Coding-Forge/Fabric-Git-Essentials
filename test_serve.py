#!/usr/bin/env python3
import os
from pathlib import Path

# Same logic as serve.py
ROOT = Path(__file__).resolve().parent

print(f"ROOT = {ROOT}")
print(f"CWD when started = {os.getcwd()}")

tool_file = ROOT / "tools" / "enterprise-standards-builder" / "index.html"
print(f"\nFile path = {tool_file}")
print(f"File exists = {tool_file.exists()}")
print(f"File size = {tool_file.stat().st_size if tool_file.exists() else 'N/A'}")

if tool_file.exists():
    content = tool_file.read_text(encoding='utf-8')
    has_button = 'saveToRepo' in content
    print(f"Contains 'saveToRepo' = {has_button}")
    if has_button:
        # Find and print the line
        for i, line in enumerate(content.split('\n'), 1):
            if 'saveToRepo' in line:
                print(f"  Line {i}: {line[:80]}...")
                break
else:
    print("File does not exist!")
