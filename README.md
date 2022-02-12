# IO8EMMOK
A driver to allow loading of EMM386.EXE in MS-DOS 8.00 real mode

_THIS DRIVER IS DESIGNED ONLY FOR MS-DOS 8.00, NOT OTHERS._

Version 1.3

# Condition

- MS-DOS 8.00 real mode
- KBC (8042) / "Normal" A20 Gate control
- Follow GNU GPL v2 license

# Install
Put IO8EMMOK.SYS in your DOS directory

Enable the real-mode DOS. Use any patch for that purpose.

DO NOT apply patch in this thread.
https://msfn.org/board/topic/183250-how-to-disable-the-built-in-xms-driver-in-windows-mes-iosys

Add the following line as the FIRST line in your config.sys

```
DEVICE=C:\DOS\IO8EMMOK.SYS
```

You may load your EMM386.EXE after the above line, with any parameter. 

```
DEVICE=C:\DOS\EMM386.EXE [ANY PARAMETERS]
```

Without the IO8EMMOK, MS-DOS 8.00 will hang when loading EMM386.EXE. 
Now, reboot your system. The system will not hang again. Enjoy.

# Compile
Use MASM 6.15 to compile the source code.

# Note
 - __READ__ the source code comments to get more information, regarding how and why this program works, how this program is design and implemented, and copyright information.
 - Branch 1.3 can load Windows 3.xx in enhanced mode, with W3XStart patch, without restrictions on serial mouse. PS/2 mouse is working now.
 - The W3XStart.COM is a hotfix patch. It modify memory, not the file. No need to decompress IO.SYS. Call this patch properly in your AUTOEXEC.BAT.
 - Please cite or reference these programs with the author's title and name: Dr. Pu-Feng Du.

# WIN386.EXE patch method

For Windows For Workgroup 3.11. Use hex editor to do the following replace

Find 

``` 
 66 c7 46 49 ff ff
```

Replace

```
 6a ff 8f 46 49 90
```
 
 There will be two replacements, together.
