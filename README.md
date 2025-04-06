# Hexadecimal File Viewer (x86 Assembly, MS-DOS)

This is a 16-bit x86 Assembly project written for the MS-DOS environment. The program reads the contents of one or more files and displays them in hexadecimal format. It includes features such as file offset display, multi-file support, pagination with dynamic screen updates, and enhanced user experience with timestamps and file paths.

---

## 👤 Author

**Aliaksei Zimnitski**  
Date: *26.02.2025*

---

## ✅ Features

- ✅ Hexadecimal output of file content (byte-by-byte)
- ✅ Offset counter printed at the start of each line
- ✅ Supports multiple input files (via command-line)
- ✅ Optional pagination with `-p` flag (20 lines per screen)
- ✅ Timestamp and full file path shown during pagination
- ✅ Handles newline characters and line wrapping
- ✅ External procedures for modularity:
  - `print_hex` – prints a byte in hexadecimal
  - `print_date` – prints current date/time
  - `print_dec` – prints offset values in decimal format
- ✅ Fully commented in English

---

## 🛠 Compilation & Execution Instructions

In MS-DOS or DOSBox:

```asm
1) tasm main.asm      ; Assemble main module
2) tasm hex.asm       ; Assemble print_hex procedure
3) tasm dec.asm       ; Assemble print_dec procedure
4) tasm date.asm      ; Assemble print_date procedure
5) tlink main hex dec date
6) main -h                     ; Show help
7) main -p file1.txt file2.txt ; Paginate multiple files
```

---

## 🧠 How It Works

- Uses DOS interrupts (`int 21h`) for file I/O and text output
- Reads file contents in 128-byte chunks
- Tracks the file offset to label each hex-dump line
- Every 70 characters or 20 lines, inserts a page break
- On `-p`, displays timestamp and file path before continuing

---

## 📄 Command-Line Usage

```dos
main [-h] [-p] <file1> [file2] [...]
```

- `-h`     → Show help message
- `-p`     → Enable pagination
- `<file>` → One or more file names to display

**Example:**
```dos
main -p data1.txt data2.txt
```

---

## 🧪 Testing Notes

Tested with:
- Empty files ✅
- Files > 64KB (offset wraps due to 16-bit counter) ✅
- Long file paths ✅
- Missing files or permission issues → Error handler triggered ✅

---

## 🔍 Known Limitations

- Cannot process files over 64KB without offset overflow
- Terminal width fixed to 70 characters
- Only ASCII-compatible input is properly rendered

---

## 💡 Possible Enhancements

- Use extended memory (XMS/EMS) for larger files
- Implement keyboard navigation (next/prev page)
- Add binary and ASCII views alongside hexadecimal
- Allow filtering or highlighting bytes


