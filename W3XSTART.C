/***************************************************************
	W3XStart.C - An In-Memory patch for starting Win 3.xx in
	MS-DOS 8.00.

	Just run this program after MS-DOS is booted and before
	Win 3.xx is start by the win.com.
	It is the INT 2FH AX=1605H handler that needs fixing. We
	applied the W3XStart patch strategy.

	Copyright(C) 2022 - Dr. Pufeng Du

	LICENSE:
	W3XSTART.EXE is free software: you can redistribute it
	and/or modify it under the terms of the GNU General
	Public License as published by the Free Software
	Foundation, either version 2 of the License, or (at
	your option) any later version.
	This program is distributed in the hope that it will
	be useful, but WITHOUT ANY WARRANTY; without even the
	implied warranty of MERCHANTABILITY or FITNESS FOR A
	PARTICULAR PURPOSE. See the GNU General Public License
	for more details.
	You should have received a copy of the GNU General
	Public License along with this program. If not, see
	<https://www.gnu.org/licenses/>.

	Compile:
		This program can be compiled using Microsoft Quick
		C 2.5.

***************************************************************/

#include <stdio.h>
typedef unsigned char _far *fpbyte;
typedef unsigned int uint;
typedef unsigned char byte;
typedef byte *pbyte;

// Search below in HMA
// 81 FF 00 04 73 06 BE
// 04 00 E9 EF FD 50 32
// C0 86 06 5C 0F 0A C0
// 58 74 EE
// Replace with
// 81 FF 00 03 73 06 BE
// 04 00 E9 EF FD 50 32
// C0 86 06 5C 0F 0A C0
// 58 90 90

int fillbytes (fpbyte s, pbyte t, uint tl) {
	int i = 0;
	for (i = 0; i < tl; i ++) {
		*(s + i) = *(t + i);
	}
	return 0;
}

//Brute force string search, KMP can be used for optimization
int findbytes (fpbyte s, uint len, pbyte t, uint tl) {
	int i = 0, j = 0, flag = 0;
	for (i = 0; i < len; i ++) {
		flag = 0;
		for (j = 0; j < tl; j ++) {
			if (*(s + i + j) != *(t + j)) {
				flag = 1;
				break;
			}
		}
		if (flag)
			continue;
		else
			return i;
	}
	return 0;
}

int main(){
	int i = 0, r = 0;
	fpbyte s = (fpbyte)0xffff0000;
	unsigned int sl = 0xffff;
	char sb[] = {
		0x81, 0xFF, 0x00, 0x04, 0x73, 0x06,
		0xBE, 0x04, 0x00, 0xE9, 0xEF, 0xFD,
		0x50, 0x32, 0xC0, 0x86, 0x06, 0x5C,
		0x0F, 0x0A, 0xC0, 0x58, 0x74, 0xEE
	};
	char tb[] = {
        0x81, 0xFF, 0x00, 0x03, 0x73, 0x06,
		0xBE, 0x04, 0x00, 0xE9, 0xEF, 0xFD,
		0x50, 0x32, 0xC0, 0x86, 0x06, 0x5C,
		0x0F, 0x0A, 0xC0, 0x58, 0x90, 0x90
	};

	// This program is of common use for any in memory patches
	// Just prepare the former four elements
	// s - The search begin and this address;
	// sl - The length of search area;
	// sb - The byte sequence to search;
	// tb - The byte sequence to put in;

	r = findbytes(s, sl, sb, sizeof(sb));
	if (r) {
    	printf ("Pattern was found at %Fp + %X\n", s, r);
		fillbytes (s + r, tb, sizeof(tb));
		printf ("Patch applied.\n");
	}
	else {
		printf("Pattern was not found.\n");
	}

	return 0;
}











