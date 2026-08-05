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
        "title": "Markdown Quick Guide 📝",
        "content": "# Markdown Guide & Shortcuts\n\nUse these Markdown formats anywhere in your notes:\n\n• **Bold** : Surround text with `**bold**`\n• *Italic* : Surround text with `*italic*`\n• # Heading : Add `# ` at start of line\n• - Bullet List : Add `- ` at start of line\n• - [ ] Todo Task : Add `- [ ] ` for unchecked todo\n• - [x] Completed : Add `- [x] ` for checked todo\n• `Code` : Wrap code with backticks\n\nKeyboard Shortcuts:\n• Ctrl+N : New Note\n• Ctrl+S : Save Notes\n• Ctrl+F : Search Notes\n• Esc    : Close Notch",
        "pinned": True,
        "updated_at": int(time.time())
    },
    {
        "id": "note_todo",
        "title": "Daily Todo List ⚡",
        "content": "- [x] Setup Tide Notepad\n- [ ] Try typing **bold** and *italic* notes\n- [ ] Create personal and work notes\n- [ ] Toggle Auto-save setting",
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
