 PAGE 255,240
.686
;-
;-
;-
;=============================================
; copyright 2005, aa, Adrian Hafizh & Inge DR.
; Property of PT SOFTINDO Jakarta.
; All rights reserved.
;
; mail,to:@[zero_inge]AT@-y.a,h.o.o.@DOTcom,
; mail,to:@[aa]AT@-s.o.f.t,i.n.d.o.@DOTnet
; http://delphi.softindo.net
;---------------------------------------------
; MDX5A Version 1.1.0 - 20091121
; This is a fork from legacy mdx5.asm, calculate MD5 only (no MD4)
; with significant speed enhancement, usage and compatibility
;
; USAGE:
; 1. call mdx5init
;      argument is pointer to 16 bytes MD5 digest
; 2. call mdx5fetch for zero, one or more blocks of 64 bytes
;      arguments are:
;        1. pointer to 16 bytes MD5 digest
;        2. pointer to data blocks of 64 bytes
;        3. count of blocks
; 3. call mdx5finalize for the last blocks whose length is
;    less than 64 bytes (including 0 length block, if the
;    total size is perfectly 64 bytes fold or the total
;    length itself was 0)
;      arguments are:
;        1. pointer to 16 bytes MD5 digest
;        2. pointer to last data block (0-63 bytes data tail) (last)
;        3. original/total data size/length in bytes (int64 or long long)
;           passed via stack as a pair of DWORDs, intel's BigEndian scheme,
;           which is simply an int64 type in Delphi
; 4. done. result in 16 bytes MD5 digest
;
; - Also provided:
;   - function: mdx5calc 
;     Calculate md5 of buffer/memory (max.4GB), doing all steps above in one go. 
;     for the whole data that completely resides in memory (also mem-mapped files).
;
;     This function is all you need most of the time -- like 95%+ of all cases :),
;     but if you don't need this convenience, define "nofun": /Dnofun
;
; - Excerpted form binhex library with slight modification/adjustment:
;   - function: bin2hex, to enable, define "binhex": /Dbin2hex
;   - function: base64encode, to enable, define "base64e": /Dbase64e
;
; - Default state is compatible with TASM, and with CDECL calling convention
;   Compile: tasm32 mdx5a.asm
;
; - To be succesfully assembled with MASM, symbol "MASM" must be defined
;   Compile: ml /c /Dmasm mdx5a.asm  (must also use arg /c = no linking)
;
; - To be compiled as .DLL, "DLL" must be defined to be compiled with STDCALL
;   Compile-TASM: tasm32 /Ddll mdx5a.asm
;   Compile-MASM: ml /c /Dmasm /Ddll mdx5a.asm
;
; Credits:
;   https://en.wikipedia.org/wiki/MD5 (tweak for F5 macro)
;   https://www.nayuki.io/page/fast-md5-hash-implementation-in-x86-assembly
;

; purge masm
; default is TASM (though I don't recommended it, so much trouble for even
; simpe substitution of one str to another, which actually is exactly what
; to be expected most from a MACRO assembler, rather we have to build nested
; ifdef else and REPEATING the nearly identical line, absolutely defeating
; the very objective/function of MACRO assembler)

; for %c in (t m) do
;   mklink md5a_"%c"asm.asm md5a.asm

ifdef masm
  ;if masm eq 1
  option prologue:none, epilogue:none
  ; ml /nologo /c /Fl //Dmasm=1 md5a_masm.asm
  TBIN equ <;%BIN>
  ;endif
else ; default is TASM
  ; tasm32 /q /c /la /mx /m8 md5a_tasm.asm
  TBIN equ <%BIN>
endif

; :: convert to ELF32 to be compiled by TinyC, and disassemble to be reviewed
; for %c in (t m) do
;   objconv -felf32 -nu md5a_"%c"asm.obj md5a_"%c"asm.o
;   obj2asm md5a_"%c"asm.obj > dis-"%c"asm
;
; ::change watcom's format "100h[ebx]" to "[ebx+100h]"
; sed -i"" -e "/\([ %tab%,]\)\([0-9A-Fh]\+\)\[\(...\)\]/s//\1[\3+\2]/" ^
;          -e "/\([ %tab%,]\)-\([0-9A-Fh]\+\)\[\(...\)\]/s//\1[\3\2]/" dis-?asm
;
; :: both converted result objs are virtually identical, different only in style,
; :: eg. tasm assembled to [eax+ebx], while masm assembled to [ebx+eax]

;; not so MAGIC NUMBERS1
A00 = 067452301h
B00 = 0efcdab89h
C00 = 098badcfeh
D00 = 010325476h

;; MAGIC NUMBERS2
;; 4294967296 times abs(sin(i)), where i is in radians
;; grouped according to associated macro's block
;; (I wonder why didn't they using pi number directly instead of 1/r cycle)
;;

;; MD5:  A = B + ((A + FUNC(b, c, d) + X + t) <<< s)
;; MD4:  A = A + FUNC(b, c, d) + X + t) <<< s

tmp equ esi
tmx equ ebp

F5 macro  @@A, @@B, @@C, @@D, @@X, @@s, @@t
; Result in: @@A, Modified: @@B
; A = B + ((A + FUNC1(b, c, d) + X + t) <<< s)
	; FUNC1(b, c, d) = (b and c) or ((not b) and d)
	; tweak documented in https://en.wikipedia.org/wiki/MD5
	; for  0..15, F := d xor (b and (c xor d))
	; for 16..31, F := c xor (d and (b xor c)) - not used
	mov tmp, @@C
	mov tmx, @@X
	xor tmp, @@D
	add @@A, tmx
	and tmp, @@B
	add @@A, @@t
	xor tmp, @@D
	add @@A, tmp
	rol @@A, @@s
	add @@A, @@B
endm

G5 macro  @@A, @@B, @@C, @@D, @@X, @@s, @@t
; A = B + ((A + FUNC2(b, c, d) + X + t) <<< s)
	; FUNC2(b, c, d) = (b and d) or (c and (not d))
	mov tmp, @@D
	mov tmx, @@X
	not tmp
	add @@A, tmx
	mov tmx, @@D
	and tmp, @@C
	and tmx, @@B
	add @@A, @@t
	or tmp, tmx
	add @@A, tmp
	rol @@A, @@s
	add @@A, @@B
endm

H5 macro  @@A, @@B, @@C, @@D, @@X, @@s, @@t
; A = B + ((A + FUNC3(b, c, d) + X + t) <<< s)
	; FUNC3(b, c, d) = b xor c xor d
	mov tmx, @@X
	mov tmp, @@C
	add @@A, tmx
	xor tmp, @@D
	add @@A, @@t
	xor tmp, @@B
	add @@A, tmp
	rol @@A, @@s
	add @@A, @@B
endm

I5 macro  @@A, @@B, @@C, @@D, @@X, @@s, @@t
; A = B + ((A + FUNC4(b, c, d) + X + t) <<< s)
	; FUNC4(b, c, d) = c xor (b or (not d))
	mov tmp, @@D
	mov tmx, @@X
	not tmp
	add @@A, tmx
	or tmp, @@B
	add @@A, @@t
	xor tmp, @@C
	add @@A, tmp
	rol @@A, @@s
	add @@A, @@B
endm

ifdef DLL
  ArgSize4 = 4
  ArgSize8 = 8
  ArgSize12 = 12
  ArgSize16 = 16
  CCALL equ stdcall
  ended equ <end LibMain>
else
  ArgSize4 = 0
  ArgSize8 = 0
  ArgSize12 = 0
  ArgSize16 = 0
  CCALL equ C
  ended equ end
endif

FUNS1 macro Name, ARGS, @@vis
.code
align 4
scope equ <private>
ifnb <@@vis>
  if @@vis eq 1
	scope equ <>
    PUBLIC Name
  else
  endif
else
endif

  ifdef masm
      Name proc CCALL scope ARGS
  else
    ifdef DLL
      Name proc stdcall scope
    else
; if using CC such as "C" tasm will insert ENTER upon entering proc
      Name proc NOLANGUAGE scope
    endif
    arg ARGS
  endif

endm

.model FLAT
.code

  TDigest struc
    dtA dd ?
    dtB dd ?
    dtC dd ?
    dtD dd ?
  TDigest ends

FUNS1 <mdx5init>, PDigest:dword, 1
;__mdx5init proc near ;; (var PDigest:eax)
TBIN 24                                    
  mov eax,[esp+4]
  XDigest equ <[eax].TDigest>
    mov XDigest.dtA, A00
    mov XDigest.dtB, B00
    mov XDigest.dtC, C00
    mov XDigest.dtD, D00
    ret ArgSize4
ifdef VSTUPID
  mov eax,PDigest; // VS warns about not using PDigest
endif
TBIN 0
mdx5init endp

A equ eax
B equ ebx
G equ ecx
D equ edx
E equ dword ptr [edi]

FUNS1 mdx5fetch, <PDigest:dword, PBuffer64:dword, Count:dword>, 1
  ; ==================================================================
  ; Param1:PDigest:DWORD, Param2:PBuffer64:DWORD Param3:Count:DWORD
  ; ==================================================================
TBIN 24
  push ebp
  mov ebp,esp
  push ebx
  push edi
  push esi

  mov esi, PDigest
  push esi; SAVE THIS!

  mov edi, PBuffer64
  mov ebp, Count

  mov A, [esi.TDigest.dtA]
  mov B, [esi.TDigest.dtB]
  mov G, [esi.TDigest.dtC]
  mov D, [esi.TDigest.dtD]

@@BigLoop:
  mov esi, [esp]
  mov [esi.TDigest.dtA], A
  mov [esi.TDigest.dtB], B
  mov [esi.TDigest.dtC], G
  mov [esi.TDigest.dtD], D

  sub ebp,1
  jae @@BLstart
  jmp @@BLdone

@@BLstart: push ebp

  S0 = 07h
  S1 = 0Ch
  S2 = 11h
  S3 = 16h

  F5 A, B, G, D, <E[4*00]>, S0, 0d76aa478h ; Step 1
  F5 D, A, B, G, <E[4*01]>, S1, 0e8c7b756h ; Step 2
  F5 G, D, A, B, <E[4*02]>, S2, 0242070dbh ; Step 3
  F5 B, G, D, A, <E[4*03]>, S3, 0c1bdceeeh ; Step 4
  F5 A, B, G, D, <E[4*04]>, S0, 0f57c0fafh ; Step 5
  F5 D, A, B, G, <E[4*05]>, S1, 04787c62ah ; Step 6
  F5 G, D, A, B, <E[4*06]>, S2, 0a8304613h ; Step 7
  F5 B, G, D, A, <E[4*07]>, S3, 0fd469501h ; Step 8
  F5 A, B, G, D, <E[4*08]>, S0, 0698098d8h ; Step 9
  F5 D, A, B, G, <E[4*09]>, S1, 08b44f7afh ; Step 10
  F5 G, D, A, B, <E[4*10]>, S2, 0ffff5bb1h ; Step 11
  F5 B, G, D, A, <E[4*11]>, S3, 0895cd7beh ; Step 12
  F5 A, B, G, D, <E[4*12]>, S0, 06b901122h ; Step 13
  F5 D, A, B, G, <E[4*13]>, S1, 0fd987193h ; Step 14
  F5 G, D, A, B, <E[4*14]>, S2, 0a679438eh ; Step 15
  F5 B, G, D, A, <E[4*15]>, S3, 049b40821h ; Step 16

  S0 = 05h
  S1 = 09h
  S2 = 0Eh
  S3 = 14h
  G5 A, B, G, D, <E[4*01]>, S0, 0f61e2562h ; Step 17
  G5 D, A, B, G, <E[4*06]>, S1, 0c040b340h ; Step 18
  G5 G, D, A, B, <E[4*11]>, S2, 0265e5a51h ; Step 19
  G5 B, G, D, A, <E[4*00]>, S3, 0e9b6c7aah ; Step 20
  G5 A, B, G, D, <E[4*05]>, S0, 0d62f105dh ; Step 21
  G5 D, A, B, G, <E[4*10]>, S1, 002441453h ; Step 22
  G5 G, D, A, B, <E[4*15]>, S2, 0d8a1e681h ; Step 23
  G5 B, G, D, A, <E[4*04]>, S3, 0e7d3fbc8h ; Step 24
  G5 A, B, G, D, <E[4*09]>, S0, 021e1cde6h ; Step 25
  G5 D, A, B, G, <E[4*14]>, S1, 0c33707d6h ; Step 26
  G5 G, D, A, B, <E[4*03]>, S2, 0f4d50d87h ; Step 27
  G5 B, G, D, A, <E[4*08]>, S3, 0455a14edh ; Step 28
  G5 A, B, G, D, <E[4*13]>, S0, 0a9e3e905h ; Step 29
  G5 D, A, B, G, <E[4*02]>, S1, 0fcefa3f8h ; Step 30
  G5 G, D, A, B, <E[4*07]>, S2, 0676f02d9h ; Step 31
  G5 B, G, D, A, <E[4*12]>, S3, 08d2a4c8ah ; Step 32

  S0 = 04h
  S1 = 0Bh
  S2 = 10h
  S3 = 17h
  H5 A, B, G, D, <E[4*05]>, S0, 0fffa3942h ; Step 33
  H5 D, A, B, G, <E[4*08]>, S1, 08771f681h ; Step 34
  H5 G, D, A, B, <E[4*11]>, S2, 06d9d6122h ; Step 35
  H5 B, G, D, A, <E[4*14]>, S3, 0fde5380ch ; Step 36
  H5 A, B, G, D, <E[4*01]>, S0, 0a4beea44h ; Step 37
  H5 D, A, B, G, <E[4*04]>, S1, 04bdecfa9h ; Step 38
  H5 G, D, A, B, <E[4*07]>, S2, 0f6bb4b60h ; Step 39
  H5 B, G, D, A, <E[4*10]>, S3, 0bebfbc70h ; Step 30
  H5 A, B, G, D, <E[4*13]>, S0, 0289b7ec6h ; Step 41
  H5 D, A, B, G, <E[4*00]>, S1, 0eaa127fah ; Step 42
  H5 G, D, A, B, <E[4*03]>, S2, 0d4ef3085h ; Step 43
  H5 B, G, D, A, <E[4*06]>, S3, 004881d05h ; Step 44
  H5 A, B, G, D, <E[4*09]>, S0, 0d9d4d039h ; Step 45
  H5 D, A, B, G, <E[4*12]>, S1, 0e6db99e5h ; Step 46
  H5 G, D, A, B, <E[4*15]>, S2, 01fa27cf8h ; Step 47
  H5 B, G, D, A, <E[4*02]>, S3, 0c4ac5665h ; Step 48

  S0 = 06h
  S1 = 0Ah
  S2 = 0Fh
  S3 = 15h
  I5 A, B, G, D, <E[4*00]>, S0, 0f4292244h ; Step 49
  I5 D, A, B, G, <E[4*07]>, S1, 0432aff97h ; Step 50
  I5 G, D, A, B, <E[4*14]>, S2, 0ab9423a7h ; Step 51
  I5 B, G, D, A, <E[4*05]>, S3, 0fc93a039h ; Step 52
  I5 A, B, G, D, <E[4*12]>, S0, 0655b59c3h ; Step 53
  I5 D, A, B, G, <E[4*03]>, S1, 08f0ccc92h ; Step 54
  I5 G, D, A, B, <E[4*10]>, S2, 0ffeff47dh ; Step 55
  I5 B, G, D, A, <E[4*01]>, S3, 085845dd1h ; Step 56
  I5 A, B, G, D, <E[4*08]>, S0, 06fa87e4fh ; Step 57
  I5 D, A, B, G, <E[4*15]>, S1, 0fe2ce6e0h ; Step 58
  I5 G, D, A, B, <E[4*06]>, S2, 0a3014314h ; Step 59
  I5 B, G, D, A, <E[4*13]>, S3, 04e0811a1h ; Step 50
  I5 A, B, G, D, <E[4*04]>, S0, 0f7537e82h ; Step 61
  I5 D, A, B, G, <E[4*11]>, S1, 0bd3af235h ; Step 62
  I5 G, D, A, B, <E[4*02]>, S2, 02ad7d2bbh ; Step 63
  I5 B, G, D, A, <E[4*09]>, S3, 0eb86d391h ; Step 64

@@DoneTransform: pop ebp

  mov esi, [esp]
  add edi, 64

  add A, [esi.TDigest.dtA]
  add B, [esi.TDigest.dtB]
  add G, [esi.TDigest.dtC]
  add D, [esi.TDigest.dtD]

  jmp @@BigLoop

@@BLdone:
  pop esi
  pop esi
  pop edi
  pop ebx
  pop ebp

  ret ArgSize12
TBIN 0
mdx5fetch endp

ifndef nofun
align 4
FUNS1 mdx5calc, <PDigest:dword, PBuffer:dword, LengthLo:dword>, 1
; This is a tight CDECL/STDCALL function to calculate md5 of buffer/memory
; in one go (max.4GB), can also be very useful to calc mem-mapped files.
  mov eax, [esp+4]  ; PDigest
  mov edx, [esp+8]  ; Buffer
  mov ecx, [esp+12] ; Length
  ; Init
    mov dword ptr [eax], A00
    mov dword ptr [eax+4], B00
    mov dword ptr [eax+8], C00
    mov dword ptr [eax+12], D00
  shr ecx, 6        ; block-count
  jz @@donefetch
  push ecx          ; count
  push edx          ; buffer
  push eax          ; digest
  ;push OFFSET @@next
  ;jmp __mdx5fetch
  call mdx5fetch
@@next:
ifdef DLL
  mov eax, [esp-12] ; digest
  mov edx, [esp-8]  ; buffer
  mov ecx, [esp-4]  ; block-count
else
  pop eax           ; digest
  pop edx           ; buffer
  pop ecx           ; block-count
endif
@@donefetch label near
  shl ecx,6          ; block count in bytes
  push 0             ; LengthHi
  add edx, ecx       ; forward buffer block*count -size
  mov ecx, [esp+16]  ; LengthLo	now pushed-down from +12 to +16
  push ecx
  push edx
  push eax
  call __mdx_finalization
ifndef DLL
  add esp,16
endif
  ret ArgSize12;
ifdef VSTUPID
  mov eax,LengthLo; //VS warns about not using LengthLo
  mov eax,PBuffer;  //VS warns about not using PBuffer
  mov eax,PDigest;  //VS warns about not using PDigest
endif
mdx5calc endp
endif

TBIN 0
TRUE = 1
FALSE = 0
MDxCSize = size TMDxChunk; 64
MDxCMask = MDxCSize - 1; 63

TBIN 24
  TMDxChunk struc ;// MD5_Context
    DataPadding    db 56 dup (?)
    DataLength_Lo  dd ?
    DataLength_Hi  dd ?
  TMDxChunk ends
TBIN 0

; public functions automatically prefixed with an underscore
; by the ML linker but label is not
;_mdx5Finalize label near
;_mdx5Finalizer label near

__mdx_finalization label near
FUNS1 mdx5finalize, <PDigest:dword, PBuffer64:dword, lengthLo:dword, lengthHi:dword>, 1

TBIN 24
  LOCAL Buf[2]:TMDxChunk;// = LocalSize

@@mdxFinalizeStart:
  push ebp             ; since we're using local storage
  mov ebp, esp         ; stack-pointer must be adjusted here
  sub esp, MDxCSize*2;// LocalSize   ; add esp, -LocalSize

  ;push ebx
  push esi
  push edi

ifdef DEBUG ; fillup buffer so we can clearly see changes
  lea edi,Buf
  mov ecx,MDxCSize*2/4
  xor eax,eax
  not eax
  rep stosd
endif

  mov esi, PDigest
  mov edx, PBuffer64

  mov ecx, LengthLo
  mov eax, LengthHi

  shld eax,ecx,3 ;// eax:ecx = length in bits
  shl ecx,3

  ; put length bits in Buf and Buf.copy
  mov dword ptr Buf.DataLength_Lo, ecx            ; Buf[00+56]
  mov dword ptr Buf[+MDxCSize].DataLength_Lo, ecx ; Buf[64+56]

  movzx ecx,byte ptr LengthLo

  mov dword ptr Buf.DataLength_Hi, eax            ; Buf[00+56+4]
  mov dword ptr Buf[+MDxCSize].DataLength_Hi, eax ; Buf[64+56+4]
  
  and ecx,63
  lea edi, Buf ; long journey for edi from here..

  push ecx     ; length mod 64
  ;mov byte ptr Buf[ecx], 80h

  shr ecx,2
  jz @@zeropad

@@moveDwords:
  mov eax,[edx]
  add edx,4
  mov [edi],eax
  add edi,4
  sub ecx,1
  jg @@moveDwords; @b

@@zeropad:
  mov ecx,[esp]
  and ecx,3
  jz @@moveDone

@@moveBytes:
  mov al,[edx]
  add edx,1
  mov [edi],al
  add edi,1
  sub ecx,1
  jg @@moveBytes; @b

@@moveDone:
  pop eax; //mov eax,[esp]
  xor ecx,ecx; // ecx should aready clear, just in case.
  sub eax,56
  setge cl
  jl @@onetrip
  sub eax, MDxCSize ;// md5_context size = 64

@@onetrip:
  mov byte ptr[edi],80h
  add edi,1
  not eax ;// = neg(eax)-1 = neg(eax+1); not(-1) = 0
  jz @@dona_1 ;// only 1

  push eax ;// | (length mod 64) -56  (-64)? | - 1
  xor edx,edx
  and eax,3
  jz @@prefilled

@@zfillb:;// zero fill bytes
  mov byte ptr [edi],dl
  add edi,1
  sub eax,1
  jg @@zfillb;

@@prefilled: ;//prepare for zero fill dwords
  pop eax
  shr eax,2
  jz @@dona_1

@@zfilld:;// zero fill dwords
  mov [edi],edx
  add edi,4
  sub eax,1
  jg @@zfilld;

@@dona_1:

@@done_mdxf:
  add ecx,1
  ;//mov eax, esi
  lea edx, Buf
  push ecx
  push edx
  push esi
  call mdx5fetch

ifndef DLL
  add esp,4*3
endif

@@end_mdxf:
  pop edi
  pop esi
  ;pop ebx
  mov esp, ebp
  pop ebp
  ret ArgSize16
TBIN 0
mdx5finalize endp

ifdef binhex
; *************************************************************************
; cut and pasted from binhex library, https://github.com/dbat/binhex
; *************************************************************************
;.data
align 4
  hexLo db "0123456789abcdef"
  hexUp db "0123456789ABCDEF"

FUNS1 bin2hex, <source:DWORD, dest:DWORD, count:DWORD, uppercase: BYTE>, 1
;public __bin2hex
;__bin2hex proc source:DWORD, dest:DWORD, count:DWORD, uppercase: BYTE
; translate data to its hexadecimal representation
; dest must have enough capacity twice of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
push ebp
mov ebp,esp
    push ebx
    push esi
    push edi

    mov esi, source
    mov edi, dest
    mov ecx, count
    movzx ebx, byte ptr uppercase
    lea esi, [esi+ecx-1]                  ; end of source (tail)
    lea edi, [edi+ecx*2-2]                ; end of dest (tail)

    test ebx,ebx              ; uppercase?
    setne bl                  ; if yes
    shl ebx, 4                ; shift lookup to the next paragraph
    ;movzx ebx,bl              ; just in case

    xor eax,eax
    lea ebx, [ebx + hexLo]

  @@Loop_b2h:
    sub ecx, 1                          ; at the end of data?
    jl @@Done_b2h                       ; out

  @@Begin_b2h:
    movzx edx, byte ptr [esi]           ; get byte
    mov al, byte ptr [esi]              ; get byte copy
    shr dl, 4                           ; get hi nibble -> become lo byte / swapped
    and al, 0fh                         ; get lo nibble -> become hi byte / swapped
    mov dl, byte ptr [ebx+edx]
    mov dh, byte ptr [ebx+eax]
    sub esi, 1
    mov [edi], dx                       ; put translated str
    sub edi, 2
    jmp @@Loop_b2h

  @@Done_b2h:
    pop edi
    pop esi
    pop ebx
pop ebp
    ret ArgSize16
bin2hex endp
endif

ifdef base64e
;.data
align 4
base64encode_table db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

FUNS1 base64encode, <source:DWORD, dest:DWORD, count:DWORD>, 1
;public __base64encode
;__base64encode proc source:DWORD, dest:DWORD, count:DWORD
; translate data to its base64 digit representation RFC3548
; returns EAX: bytes encoded = (count + 2) / 3 * 4, always divisible by 4
;
; This function using backward direction scan
;
; count MUST be divisible by 3 for incomplete translation/conversion
; (ie. not a complete source, more data expected to come)
;
; no check, dest must have enough capacity 4/3 x of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
@@preStart_enc64:
    mov ecx,[esp+12] ;//mov ecx,count
    test ecx,ecx
    ;//jz @@ZeroCount
    jnz @@Start_enc64
    ;//@@ZeroCount:
    xor eax,eax
    ret ArgSize12

@@Start_enc64:
push ebp
mov ebp,esp
    push ebx
    push esi
    push edi

    mov esi, source
    mov edi, dest
    mov eax, ecx
    mov ecx, 3

    xor edx, edx
    div ecx

    ; calculate result count
    ; xor ecx,ecx
    test edx,edx
    setnz cl
    add ecx,eax
    shl ecx,2					; dest count = 4 x eax
    push ecx 					; put result in stack

    mov ebx, offset base64encode_table;//lea ebx, base64encode_table
    lea esi, [esi+eax*2-3]		; end of source (tail)
    lea edi, [edi+eax*4-4]		; end of dest (tail)
    add esi,eax					; src count = 3 x eax

    push ebp ; using ebp, any disturbance will throw a very nasty error!
    mov ebp, eax
    xor eax,eax
    test edx,edx
    jz @@Loop_enc64;			; rem:0 => divisible by 3

  @@Fixtail_enc64:
    ; caution ----------------------------------------------------------
    ; watch out for referenced mem. when source and dest are equal!
    ; do not write to the block mem before calculation is really done
    ;-------------------------------------------------------------------
    movzx eax, byte ptr [esi+3]
    shr al, 2
    mov ecx,"===="

    mov cl, byte ptr [ebx+eax]
    mov al, byte ptr [esi+3]			; refetch

    and al, 3		; only 2 bits needed
    shl al, 4		; (hi portion of ch#2)

    cmp dl,1
    mov dl, byte ptr [esi+3+1]
    mov ch, byte ptr [ebx+eax]
    ; caution ----------------------------------------------------------
    ;-- mov ch, byte ptr [esi+3+1]	; if src/dest equal, these two lines -
    ;-- mov [edi+4+1], cl		;  might refer to the same address
    ;-------------------------------------------------------------------
    mov dh, dl  			; copy
    mov [edi+4], ecx		; write, at last
    jz @@Loop_enc64; 		; done for rem:1

  @@Fixtail2_enc64:
    ;mov [edi+4+2], dx		; write, at last

    and dh, 15	; only 4 bits needed for hi part of Ch#3
    shr dl, 4	; lo part of Ch#2
    shl dh, 2	; hi part of Ch#3
    or al, dl	; al had hi part of Ch#2
    movzx edx, dh
    mov al, byte ptr [ebx+eax]
    mov dl, byte ptr [ebx+edx]

    mov [edi+4+1], al			; write 1 byte = 2 b64
    mov [edi+4+2], dl			; write 1 byte = 2 b64
    ;jmp @@Loop_enc64

  @@Loop_enc64:
    sub ebp,1                      ; at the end of data?
    jl @@Done_enc64                 ; out

  @@Begin_enc64: ; 3 bytes round ; OK but weird
    ; fetch wth big-endian scheme, but must be stored as little-endian
    ;= mov edx,[esi]		; might get stalled -unaligned4
    ;= bswap edx		; edx: big endian string (3bytes)
    ;= shr edx,8		; 00:[esi]:[esi+1]:[esi+2]
    mov dh, byte ptr [esi]
    mov dl, byte ptr [esi+1]
    movzx eax, byte ptr [esi+2]		; get 3rd-byte
    shl edx,8
    mov dl,al
    and al,63
    shr edx,6                           ; arithmatic ops use big-endian value
    mov ch, byte ptr [ebx+eax]          ; storing use little-endian scheme
    mov al,dl				; fetch
    and al,63
    shr edx,6
    mov cl, byte ptr [ebx+eax]
    mov al,dl				; fetch 3rd b64
    shr edx,6
    and al,63
    and dl,63
    mov ah, byte ptr [ebx+eax]
    mov al, byte ptr [ebx+edx]
    sub esi,3
    mov [edi], ax
    mov [edi+2], cx
    sub edi,4
    jmp @@Loop_enc64                           ;

  @@Done_enc64:
    pop ebp
    pop eax		; result count should be divisible by 4
    pop edi
    pop esi
    pop ebx
pop ebp
ret ArgSize12 
ifdef VSTUPID
  mov eax, count; //VS warns about not using Cunt
endif
base64encode endp
endif

ifdef DLL
FUNS1 LibMain, <hInstDLL:dword, reason:dword, unused:dword>, 1
  mov eax,1
  ret 12
LibMain endp
endif

ended



