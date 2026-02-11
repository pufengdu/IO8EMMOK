# IO8EMMOK
A driver to allow loading of EMM386.EXE in MS-DOS 8.00 real mode

_THIS DRIVER IS DESIGNED ONLY FOR MS-DOS 8.00, NOT OTHERS._

Version 1.3

# About running WFWG311

Well, some more notes are needed here. Running WFWG311 should not need EMM. XMM only should be enough to let WFWG311 to start. WFWG311 has its own EMM, the 86mmgr.vxd. Therefore, it seems like that EMM386.EXE should not be a "must load first" component. However, this is not the case in MS-DOS 8.00. As I have stated as comments in the code, the XMM in IO.SYS always resides in HMA, which is different to all older versions. Even with the IO8EMMOK.SYS, it will not support loading WFWG311 directly using XMM, as IO8EMMOK.SYS does not consider loading WFWG311 system VMs. But...

It will allow you to load WFWG311, if you have loaded EMM386.EXE before loading WFWG311. After loading EMM386.EXE, when WFWG311 is initializing, it imports global memroy map from EMM rather than XMM. See the below screenshot for WFWG311 running on MS-DOS 8.00.

![Enhanced Windows 3.xx](https://github.com/pufengdu/IO8EMMOK/blob/1.3/screenshot.png?raw=true)

Note: Do NOT waste your time trying to use QEMM386 / 386MAX to get similar things done. They do not work in MS-DOS 8.0.

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
 - __READ__ the source code comments to get more information, regarding how and why this program works, how this program is designed and implemented, and copyright information.
 - Branch 1.3 can load Windows 3.xx in enhanced mode, with W3XStart patch, without restrictions on serial mouse. PS/2 mouse is working now.
 - You may also need [WIN3XLDR](https://github.com/pufengdu/WIN3XLDR) to load Windows 3.x.
 - The W3XStart.COM is a hotfix patch. It modifies memory, not the file. No need to decompress IO.SYS. Call this patch properly in your AUTOEXEC.BAT.
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

 # Supplementary Notes

- Try to use the EMM386.EXE that comes with [WFWG](https://winworldpc.com/product/windows-3/wfw-311) or [PC-DOS 2000](https://winworldpc.com/product/pc-dos/2000). They are really good.

- DO NOT load high IO8EMMOK.SYS or W3XSTART.COM

 # Further reading

 You may be interested in this repo: https://github.com/pufengdu/RetroFuns 
