.686
.MODEL FLAT, C
include         \masm32\include\kernel32.inc
include         \masm32\include\user32.inc
includelib      \masm32\lib\kernel32.lib
includelib      \masm32\lib\user32.lib

.stack
.const

STRSIZE		db 100

.data

Handle		dd 0
buff		db 41 dup(0)
errmsg		db 13, 10, 'UNKNOWN FORMAT CPECIFIER', 13, 10
errlen		dd 26

.code

EDGE		equ 2147483647
MAXINT		equ 4294967295

NUMPREP  	macro
			std
			mov edi, offset buff + 40
			call getpar
			cmp edx, EDGE			;граница отрицательных
			ja negat
			jmp prepend

negat:		call wrimin
			mov eax, [ebp-4]
			mov edx, MAXINT						;максимальный int 
			sub edx, eax
			inc edx
prepend:	
			endm

WRITE		macro len, ptr
			push 0
			push 0
			push len
			push ptr
			push handle
			call WriteConsole
			endm

; --------------------------------------------------
;printf without %f but with% b
;parametrs (as usual printf) gets from stack from right to left
;destroy	---
;---------------------------------------------------
aprintf		proc

			push ebp
			push eax
			push ecx
			push edx
			push edi
			push esi
			mov ebp, esp
			mov esi, [ebp+28]
			add ebp, 32			;parametrs offset 
			
			push -11			;STD_OUTPUT_HANDLE
			call GetStdHandle
			mov handle, eax
			xor eax, eax

			cld
			call manag

			pop esi 
			pop edi 
			pop edx 
			pop ecx 
			pop eax 
			pop ebp
			ret
aprintf		endp

; --------------------------------------------------
;manages format string calling printing functions
;
;parametrs	esi - pointer to format string
;
;destroy	eax ecx edx edi esi
;---------------------------------------------------

manag       proc

repman:		mov al, [esi]
			cmp al, 0
			je endman
			cmp al, '%'	
			je ncon
			call wricon
			jmp repman

ncon:		inc esi
			lodsb		
			
			shl eax, 2
			call JT[eax]
			jmp repman

endman:		ret

JT			dd 37 dup (prerr)		
			dd prproc
			dd 60 dup (prerr)
			dd prbin
			dd prchar
			dd prdec 
			dd 3 dup (prerr)
			dd prhex
			dd 6 dup (prerr)
			dd proct
			dd 3 dup (prerr)
			dd prstr
			dd 12 dup (prerr)

manag		endp

; --------------------------------------------------
; ends aprintf with error 
;
; destroy	
; ---------------------------------------------------

prerr		proc
			
			;WRITE errlen, offset errmsg
			;add esp, 4

			ret
prerr		endp

; --------------------------------------------------
; prints decimal number from ebp (parametr for aprintf) 
;
; destroy	eax, edx, ecx, edi, ebp
; ---------------------------------------------------

prdec		proc
			NUMPREP
			mov ecx, 10
			mov eax, edx

rep10:		xor edx, edx
			div ecx	
			xchg eax, edx
			add eax, '0'
			stosb
			xchg eax, edx
			cmp eax, 0
			jne rep10
				
			call wrin
				
			cld
			ret
prdec		endp

; --------------------------------------------------
; prints binary number from ebp (parametr for aprintf)
;
; destroy	eax, edx, edi, ebp
; -------------------------------------------------- -

prbin		proc
			NUMPREP

rep2:		mov eax, edx
			and eax, 1b
			add eax, '0'
			stosb
			shr edx, 1
			cmp edx, 0
			jne rep2
			
			call wrin	
			cld
			ret
prbin		endp

; --------------------------------------------------
; prints octal number from ebp (parametr for aprintf)
;
; destroy	eax, edx, edi, ebp
; ---------------------------------------------------

proct		proc
			NUMPREP
	
rep8:		mov eax, edx
			and eax, 111b
			add eax, '0'
			stosb
			shr edx, 3
			cmp edx, 0
			jne rep8

			call wrin	
			cld
			ret
proct		endp

; --------------------------------------------------
; prints hexadecimal number from ebp (parametr for aprintf)
;
; destroy	eax, edx, edi, ebp
; ---------------------------------------------------

prhex		proc
			NUMPREP

rep16:		mov eax, edx
			and eax, 1111b
			cmp eax, 10
			jge jge10
			add eax, '0'
back:		stosb
			shr edx, 4
			cmp edx, 0
			jne rep16
	
			call wrin		
			cld
			ret

jge10:		add eax, 'A' - 10
			jmp back
			
prhex		endp

; --------------------------------------------------
; prints %
;
; destroy	
; -------------------------------------------------- 

prproc		proc
			
			mov buff, '%'
			
			WRITE 1, offset buff
			ret

			ret
prproc		endp

; --------------------------------------------------
; prints char from ebp (parametr for aprintf)
;
; destroy	ebp
; -------------------------------------------------- 

prchar		proc

			WRITE 1, ebp
			add ebp, 4

			ret
prchar		endp

; --------------------------------------------------
; prints string from ebp(parametr for aprintf)
;
; destroy	edx, edi, eax, ecx, ebp
; --------------------------------------------------

prstr		proc

			call getpar
			mov edi, edx
			xor eax, eax
			mov cx, word ptr STRSIZE 
			repne scasb
			call wristr

			ret
prstr		endp

; --------------------------------------------------
; writes char from esi (pointer)
;
; destroy	esi
; ---------------------------------------------------

wricon		proc
			
			WRITE 1, esi	
			inc esi

			ret
wricon		endp

; --------------------------------------------------
; writes minus
;
; destroy	
; ---------------------------------------------------

wrimin		proc
			mov buff, '-'
			
			WRITE 1, offset buff
			ret
wrimin		endp

; --------------------------------------------------
; writes number from edi(pointer) 
;
; destroy	edi, edx
; --------------------------------------------------

wrin		proc

			inc edi
			mov edx, offset buff + 41
			sub edx, edi

			WRITE edx, edi
			ret
wrin		endp

; --------------------------------------------------
; writes (STRSIZE - ecx) characters from (edi - STRSIZE) (pointer) 
;
; destroy	edi, edx
; ---------------------------------------------------

wristr		proc

			mov edx, dword ptr STRSIZE
			sub dx, cx
			sub di, dx
			dec dx

			WRITE edx, edi
			ret
wristr		endp

; --------------------------------------------------
; gets parametr for aprintf from stack to edx
;
; destroy	edx, ebp
; ---------------------------------------------------

getpar		proc
 			
			mov edx, [ebp]
			add ebp, 4

			ret
getpar		endp
END