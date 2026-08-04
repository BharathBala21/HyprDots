#!/usr/bin/env python3
import sys
import os
import json
import time

NOTES_DIR = os.path.expanduser("~/.local/share/tide-island")
NOTES_FILE = os.path.join(NOTES_DIR, "notes.json")

DEFAULT_NOTES = [
    {
        "id": "note_welcome",
        "title": "Welcome to Tide Notepad! 📝",
        "content": "Welcome to your Tide-Island Notch Notepad!\n\n• Type your notes freely — auto-saves as you type.\n• Organize using categories: Work, Personal, Ideas, Todo.\n• Pin important notes to keep them at the top.\n• Click 'Copy' to send any note directly to your clipboard.\n• Trigger via shortcut or from the Utilities island swipe menu!",
        "category": "Ideas",
        "pinned": True,
        "updated_at": int(time.time())
    },
    {
        "id": "note_shortcuts",
        "title": "Quick Shortcuts & Tips ⚡",
        "content": "Keyboard Shortcuts:\n- Ctrl+N : Create a new note\n- Ctrl+S : Force save note\n- Ctrl+F : Focus search bar\n- Esc    : Close notepad notch\n\nEnjoy clean & fast note-taking directly from your Dynamic Island!",
        "category": "Todo",
        "pinned": False,
        "updated_at": int(time.time() - 60)
    }
]

def ensure_file():
    if not os.path.exists(NOTES_DIR):
        os.makedirs(NOTES_DIR, exist_ok=True)
    if not os.path.exists(NOTES_FILE):
        with open(NOTES_FILE, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_NOTES, f, indent=2)

def load_notes():
    ensure_file()
    try:
        with open(NOTES_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, list):
                return data
    except Exception as e:
        sys.stderr.write(f"Error reading notes: {e}\n")
    return DEFAULT_NOTES

def save_notes(payload_str):
    ensure_file()
    try:
        data = json.loads(payload_str)
        tmp_file = NOTES_FILE + ".tmp"
        with open(tmp_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_file, NOTES_FILE)
        print("OK")
    except Exception as e:
        sys.stderr.write(f"Error saving notes: {e}\n")
        print("ERROR")

def main():
    if len(sys.argv) < 2:
        print(json.dumps(load_notes(), indent=2))
        return

    cmd = sys.argv[1]
    if cmd == "list":
        print(json.dumps(load_notes()))
    elif cmd == "save":
        if len(sys.argv) > 2:
            payload = sys.argv[2]
        else:
            payload = sys.stdin.read()
        save_notes(payload)
    else:
        print(json.dumps(load_notes()))

if __name__ == "__main__":
    main()
