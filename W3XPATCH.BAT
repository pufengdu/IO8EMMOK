@echo off
:: This is the W3XStart patch for MS-DOS 8.0
:: Already adapted to MS-DOS 8.0
:: This is a memory based patch,
:: so, you need to run this every time system reboots.
:: This patch does not modify any system files.
:: It only modify memory.
:: There is no need to decompress the IO.SYS,
:: as the patch happens in the memory
:: This patch relies only on standard DOS utilities
:: including DEBUG.EXE and FIND.EXE
:: Make sure these tools are in your path
:: Make sure you use COMMAND.COM as your shell

if (%W3XSTART%)==(1) GOTO EXIT
echo Loading W3XStart for MS-DOS 8.00 in memory patch...
echo s ffff:0000 ffff 81 FF 00 04 73 06 BE 04 00 E9 EF FD 50 32 C0 86 06 5C 0F 0A C0 58 74 EE > w3xd8.dsc
echo q >> w3xd8.dsc
echo rcx > w3xd8cut.dsc
echo 2 >> w3xd8cut.dsc
echo w >> w3xd8cut.dsc
echo q >> w3xd8cut.dsc
echo e > w3xd82.dsc
debug w3xd82.dsc < w3xd8cut.dsc > NUL
debug < w3xd8.dsc > w3xd8.tmp
type w3xd8.tmp | find /V "-" >> w3xd82.dsc
echo 81 FF 00 03 73 06 BE 04 00 E9 EF FD 50 32 C0 86 06 5C 0F 0A C0 58 90 90 >> w3xd82.dsc
echo q >> w3xd82.dsc
debug < w3xd82.dsc > NUL
del *.dsc
del *.tmp
SET W3XSTART=1
GOTO END

:EXIT
echo Memory patch flag found, no need to run.
:END
