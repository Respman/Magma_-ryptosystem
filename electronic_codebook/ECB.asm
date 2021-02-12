extern printf

section .data
	sys_open equ 5
	sys_close equ 6
	sys_write equ 4
	sys_read equ 3
	sys_creat equ 8
	sys_lseek equ 19

	SEEK_SET equ 0

	O_RDONLY equ 0
	O_WRONLY equ 1

	input_f dd 0
	output_f dd 0

	Errmsg_args db "wrong amount of args", 0x0A, 0
	Errlen_args db $-Errmsg_args
	Errmsg_open db "can't open file", 0x0A, 0
	Errlen_open db $-Errmsg_open
	p_fmt db "left_block %x, right_block %x", 0x0A, 0
	p_fmt_tmp db "right_block = %x", 0x0A, 0

	key: times 8 dd 0
; Нелинейное биективное преобразование по ГОСТ Р 34.12-2015
	sbox db 12, 4, 6, 2, 10, 5, 11, 9, 14, 8, 13, 7, 0, 3, 15, 1,
		 db 6, 8, 2, 3, 9, 10, 5, 12, 1, 14, 4, 7, 11, 13, 0, 15,
		 db 11, 3, 5, 8, 2, 15, 10, 13, 14, 1, 7, 4, 12, 9, 6, 0,   
		 db 12, 8, 2, 1, 13, 4, 15, 6, 7, 0, 10, 5, 3, 14, 9, 11,
		 db 7, 15, 5, 10, 8, 1, 6, 13, 0, 9, 3, 14, 11, 4, 2, 12,
		 db 5, 13, 15, 6, 9, 2, 12, 10, 11, 7, 8, 1, 4, 3, 14, 0, 
		 db 8, 14, 2, 5, 6, 9, 1, 12, 15, 4, 11, 0, 13, 10, 3, 7,     
		 db 1, 7, 14, 13, 0, 5, 8, 3, 4, 15, 10, 6, 9, 12, 11, 2
	left_block dd 0
	right_block dd 0
	enc_left_block dd 0
	enc_right_block dd 0
	tmp_block dd 0

	k dd 0
	padding dd 0


section .text
global main


magma:
	push 	ebp
	mov 	ebp, esp
	
	mov 	dword [enc_right_block], 0

xor_right_block_and_key:
	
	cmp 	dword [k], 23
	jnl 	else_
	
	inc 	dword [k]
	mov 	edx, dword [k]
	and 	edx, 0x7

	jmp 	skip
else_:
	
	inc 	dword [k]
	mov 	edx, 31
	sub 	edx, dword [k]

skip:
	
	mov 	eax, dword [right_block]
	mov 	dword [enc_left_block], eax

	mov 	eax, dword [key + 4*edx]
	add 	dword [right_block], eax
	
	mov 	cx, 8
permut:
	
	mov 	dx, cx
	dec 	cx

	mov 	eax, 0xf
	
	test 	cx, cx
	jz 		skip_shl_1
	push 	cx
shl_1:
	shl 	eax, 4
	loop 	shl_1
	pop 	cx
skip_shl_1:

	mov 	ebx, dword [right_block]
	and 	ebx, eax

	test 	cx, cx
	jz 		skip_shr_1
	push 	cx
shr_1:
	shr 	ebx, 4
	loop 	shr_1
	pop 	cx
skip_shr_1:

	movsx 	esi, dx
	dec 	esi
	shl 	esi, 4

	movsx 	ebx, byte [sbox + esi + ebx]
	
	test 	cx, cx
	jz 		skip_shl_2
	push 	cx
shl_2:
	shl 	ebx, 4
	loop 	shl_2
	pop 	cx
skip_shl_2:

	add 	dword [enc_right_block], ebx
	mov 	cx, dx

	loop permut


	rol 	dword [enc_right_block], 11
	mov 	eax, dword [left_block]
	xor 	dword [enc_right_block], eax

	mov 	eax, dword [enc_left_block]
	mov 	dword [left_block], eax

	mov 	eax, dword [enc_right_block]
	mov 	dword [right_block], eax


	mov 	esp, ebp
	pop 	ebp
	ret


main:

	mov 	ecx, [esp + 4]
	cmp 	ecx, 4
	jne 	fail_args

	mov 	ecx, [esp + 8]
	mov 	ebx, [ecx + 4]
	mov 	eax, sys_open
	mov 	ecx, O_RDONLY
	xor 	edx, edx
	int 	0x80
	cmp 	eax, 0
	jng 	fail_open
	mov 	[input_f], eax

	mov 	ecx, [esp + 8]
	mov 	eax, sys_creat
	mov 	ebx, [ecx + 8]
	mov 	ecx, 0777
	int 	0x80
	cmp 	eax, 0
	jng 	fail_open
	mov 	[output_f], eax


preparing_keys:
	xor 	ecx, ecx
	mov 	edx, 0
	mov 	esi, [esp + 8]
	mov 	esi, [esi + 12]

next_key:
	mov 	cl, 8

infill_key:
	
	mov 	eax, edx
	shl 	eax, 3
	add 	eax, 8
	movsx 	ebx, cl
	sub 	eax, ebx
	movsx 	eax, byte [esi + eax]

	cmp 	eax, 97
	jge 	true_
	sub 	eax, 48
	jmp 	skip_
true_:
	sub 	eax, 87
skip_:

	mov		bl, cl
	dec 	cl	
	shl 	cl, 2

	shl 	eax, cl
	mov 	cl, bl
	
	add 	dword [key + 4*edx], eax
	
	loop	infill_key
	
	inc 	edx
	cmp 	edx, 8
	jne	 	next_key


read_block:
	
	mov 	dword [left_block], 0
	mov 	dword [right_block], 0
	mov 	dword [padding], 8
	mov 	eax, sys_read
	mov 	ebx, [input_f]
	mov 	ecx, left_block
	mov 	edx, 4
	int 	0x80	
	
	pushad
	
	sub 	dword [padding], eax

	mov 	eax, sys_read
	mov 	ebx, [input_f]
	mov 	ecx, right_block
	mov 	edx, 4
	int 	0x80	
	
	sub 	dword [padding], eax

	popad

	cmp 	eax, 0
	je		close_all


normalize_block:

	mov 	al, byte [left_block]
	mov 	bl, byte [left_block + 3]
	mov 	byte [left_block], bl
	mov 	byte [left_block + 3], al

	mov 	al, byte [left_block + 1]
	mov 	bl, byte [left_block + 2]
	mov 	byte [left_block + 1], bl
	mov 	byte [left_block + 2], al

	mov 	al, byte [right_block]
	mov 	bl, byte [right_block + 3]
	mov 	byte [right_block], bl
	mov 	byte [right_block + 3], al

	mov 	al, byte [right_block + 1]
	mov 	bl, byte [right_block + 2]
	mov 	byte [right_block + 1], bl
	mov 	byte [right_block + 2], al

	cmp 	dword [padding], 0
	je 		skip_padding
	mov 	eax, dword [padding]
	add 	dword [right_block], eax 
skip_padding:


encrypt:

	mov 	dword [k], -1

	mov 	ecx, 31
lp:
	pushad
	call 	magma
	popad
	loop 	lp

	mov 	eax, dword [right_block]
	mov 	dword [tmp_block], eax
	
	pushad
	call 	magma
	popad

	mov 	eax, dword [right_block]
	mov 	dword [left_block], eax
	
	mov 	eax, dword [tmp_block]
	mov 	dword [right_block], eax


re_normalize_block:

	mov 	al, byte [left_block]
	mov 	bl, byte [left_block + 3]
	mov 	byte [left_block], bl
	mov 	byte [left_block + 3], al

	mov 	al, byte [left_block + 1]
	mov 	bl, byte [left_block + 2]
	mov 	byte [left_block + 1], bl
	mov 	byte [left_block + 2], al

	mov 	al, byte [right_block]
	mov 	bl, byte [right_block + 3]
	mov 	byte [right_block], bl
	mov 	byte [right_block + 3], al

	mov 	al, byte [right_block + 1]
	mov 	bl, byte [right_block + 2]
	mov 	byte [right_block + 1], bl
	mov 	byte [right_block + 2], al


write_block:

	mov 	eax, sys_write
	mov 	ebx, [output_f]
	mov 	ecx, left_block
	mov 	edx, 4
	int 	0x80

	mov 	eax, sys_write
	mov 	ebx, [output_f]
	mov 	ecx, right_block
	mov 	edx, 4
	int 	0x80

	jmp 	read_block


close_all:
	mov 	eax, sys_close
	mov 	ebx, [input_f]
	int 	0x80

	mov 	eax, sys_close
	mov 	ebx, [output_f]
	int 	0x80


exit:
	mov 	eax, 1
	int 	0x80

fail_args:
	mov 	eax, sys_write
	mov 	ebx, 1
	mov 	ecx, Errmsg_args
	mov 	edx, Errlen_args
	int 	0x80
	jmp 	exit

fail_open:
	mov 	eax, sys_write
	mov 	ebx, 1
	mov 	ecx, Errmsg_open
	mov 	edx, Errlen_open
	int 	0x80
	jmp 	exit
