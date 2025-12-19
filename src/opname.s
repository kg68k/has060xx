;----------------------------------------------------------------
;	X68k High-speed Assembler
;		オペコード名テーブル
;		< opname.s >
;
;		Copyright 1990-94  by Y.Nakamura
;			  1996-99  by M.Kamada
;			  2025     by TcbnErik
;----------------------------------------------------------------

	.include	has.equ
	.include	register.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	オペコード名テーブル
;----------------------------------------------------------------
tablebody	.macro

	optbl	'move',	    ~move,	$0000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'moveq',    ~moveq,	$7000,C000|C010|C020|C030|C040|C060,        SZL
	optbl	'movea',    ~movea,	$2040,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'movem',    ~movem,	$4880,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'lea',	    ~lea,	$41C0,C000|C010|C020|C030|C040|C060,        SZL
	optbl	'pea',	    ~peajsrjmp,	$4840,C000|C010|C020|C030|C040|C060,        SZL
	optbl	'jsr',	    ~jmpjsr,	$4E80,C000|C010|C020|C030|C040|C060,SZNO
	optbl	'jmp',	    ~jmpjsr,	$4EC0,C000|C010|C020|C030|C040|C060,SZNO
;GASコード
;	optbl	'mov',	    ~move,	$0000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
;	optbl	'movq',	    ~moveq,	$7000,C000|C010|C020|C030|C040|C060,        SZL
;	optbl	'mova',	    ~movea,	$2040,C000|C010|C020|C030|C040|C060,    SZW|SZL
;	optbl	'movm',	    ~movem,	$4880,C000|C010|C020|C030|C040|C060,    SZW|SZL

	pstbl	'even',     ~~even
	pstbl	'quad',	    ~~quad
	pstbl	'align',    ~~align
	pstbls	'dc',	    ~~dc,	SZB|SZW|SZL|SZS|SZD|SZX|SZP
	pstbls	'ds',	    ~~ds,	SZB|SZW|SZL|SZS|SZD|SZX|SZP
	pstbls	'dcb',	    ~~dcb,	SZB|SZW|SZL|SZS|SZD|SZX|SZP
;GASコード
;	pstbl	'byte',	    ~~byte
;	pstbl	'short',    ~~short
;	pstbl	'long',	    ~~long

	pstbl	'equ',	    ~~equ
	pstbl	'set',	    ~~set
	pstbl	'reg',	    ~~reg

	optbl	'bra',	    ~bcc,	$6000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bt',	    ~bcc,	$6000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bsr',	    ~bcc,	$6100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bhi',	    ~bcc,	$6200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bls',	    ~bcc,	$6300,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bcc',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bhs',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bcs',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'blo',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bne',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnz',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'beq',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bze',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bvc',	    ~bcc,	$6800,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bvs',	    ~bcc,	$6900,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bpl',	    ~bcc,	$6A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bmi',	    ~bcc,	$6B00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bge',	    ~bcc,	$6C00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'blt',	    ~bcc,	$6D00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bgt',	    ~bcc,	$6E00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'ble',	    ~bcc,	$6F00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS

	optbl	'bnls',	    ~bcc,	$6200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnhi',	    ~bcc,	$6300,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bncs',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnlo',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bncc',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnhs',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bneq',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnze',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnne',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnnz',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnvs',	    ~bcc,	$6800,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnvc',	    ~bcc,	$6900,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnmi',	    ~bcc,	$6A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnpl',	    ~bcc,	$6B00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnlt',	    ~bcc,	$6C00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnge',	    ~bcc,	$6D00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bnle',	    ~bcc,	$6E00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'bngt',	    ~bcc,	$6F00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS

	optbln	'rts',	    ~noopr,	$4E75,C000|C010|C020|C030|C040|C060,SZNO

	optbl	'dbra',     ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,    SZW

	optbl	'clr',	    ~clr,	$4200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'neg',	    ~negnot,	$4400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'not',	    ~negnot,	$4600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'tst',	    ~tst,	$4A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL

	optbl	'cmp',	    ~cmp,	$B000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'cmpi',     ~cmpi,	$0C00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'cmpa',     ~cmpa,	$B0C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'cmpm',     ~cmpm,	$B108,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'sub',	    ~subadd,	$9000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'subq',     ~subaddq,	$5100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'subi',     ~subaddi,	$0400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'suba',     ~sbadcpa,	$90C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'add',	    ~subadd,	$D000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'addq',     ~subaddq,	$5000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'addi',     ~subaddi,	$0600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'adda',     ~sbadcpa,	$D0C0,C000|C010|C020|C030|C040|C060,    SZW|SZL

	optbl	'or',	    ~orand,	$8000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'ori',	    ~orandeori, $0000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'and',	    ~orand,	$C000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'andi',     ~orandeori, $0200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'eor',	    ~eor,	$B100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'eori',     ~orandeori, $0A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL

	optbl	'link',     ~link,	$4E50,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'unlk',     ~unlk,	$4E58,C000|C010|C020|C030|C040|C060,SZNO

	optbl	'exg',	    ~exg,	$C100,C000|C010|C020|C030|C040|C060,        SZL
	optbl	'ext',	    ~ext,	$4880,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'extb',     ~extb,	$49C0,		C020|C030|C040|C060,        SZL
	optbl	'swap',     ~swap,	$4840,C000|C010|C020|C030|C040|C060,    SZW

	optbl	'asr',	    ~sftrot,	$E000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'asl',	    ~asl,	$E100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'lsr',	    ~sftrot,	$E008,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'lsl',	    ~sftrot,	$E108,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'roxr',     ~sftrot,	$E010,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'roxl',     ~sftrot,	$E110,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'ror',	    ~sftrot,	$E018,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'rol',	    ~sftrot,	$E118,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL

	optbl	'bchg',     ~bchclst,	$0040,C000|C010|C020|C030|C040|C060,SZB|SZL
	optbl	'bclr',     ~bchclst,	$0080,C000|C010|C020|C030|C040|C060,SZB|SZL
	optbl	'bset',     ~bchclst,	$00C0,C000|C010|C020|C030|C040|C060,SZB|SZL
	optbl	'btst',     ~btst,	$0000,C000|C010|C020|C030|C040|C060,SZB|SZL

	optbl	'st',	    ~scc,	$50C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sf',	    ~scc,	$51C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'shi',	    ~scc,	$52C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sls',	    ~scc,	$53C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'scc',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'shs',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'scs',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'slo',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sne',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snz',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'seq',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sze',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'svc',	    ~scc,	$58C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'svs',	    ~scc,	$59C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'spl',	    ~scc,	$5AC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'smi',	    ~scc,	$5BC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sge',	    ~scc,	$5CC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'slt',	    ~scc,	$5DC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sgt',	    ~scc,	$5EC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sle',	    ~scc,	$5FC0,C000|C010|C020|C030|C040|C060,SZB

	optbl	'snf',	    ~scc,	$50C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snt',	    ~scc,	$51C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snls',	    ~scc,	$52C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snhi',	    ~scc,	$53C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sncs',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snlo',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sncc',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snhs',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sneq',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snze',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snne',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snnz',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snvs',	    ~scc,	$58C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snvc',	    ~scc,	$59C0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snmi',	    ~scc,	$5AC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snpl',	    ~scc,	$5BC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snlt',	    ~scc,	$5CC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snge',	    ~scc,	$5DC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'snle',	    ~scc,	$5EC0,C000|C010|C020|C030|C040|C060,SZB
	optbl	'sngt',	    ~scc,	$5FC0,C000|C010|C020|C030|C040|C060,SZB

	optbl	'divu',     ~divmul,	$80C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'divs',     ~divmul,	$81C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'mulu',     ~divmul,	$C0C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'muls',     ~divmul,	$C1C0,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'divul',    ~divl,	$0000,		C020|C030|C040|C060,        SZL
	optbl	'divsl',    ~divl,	$0800,		C020|C030|C040|C060,        SZL

	optbl	'dbt',	    ~dbcc,	$50C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbf',	    ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbhi',     ~dbcc,	$52C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbls',     ~dbcc,	$53C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbcc',     ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbhs',     ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbcs',     ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dblo',     ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbne',     ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnz',     ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbeq',     ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbze',     ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbvc',     ~dbcc,	$58C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbvs',     ~dbcc,	$59C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbpl',     ~dbcc,	$5AC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbmi',     ~dbcc,	$5BC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbge',     ~dbcc,	$5CC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dblt',     ~dbcc,	$5DC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbgt',     ~dbcc,	$5EC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dble',     ~dbcc,	$5FC8,C000|C010|C020|C030|C040|C060,    SZW

	optbl	'dbnf',	    ~dbcc,	$50C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnt',	    ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnls',    ~dbcc,	$52C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnhi',    ~dbcc,	$53C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbncs',    ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnlo',    ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbncc',    ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnhs',    ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbneq',    ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnze',    ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnne',    ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnnz',    ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnvs',    ~dbcc,	$58C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnvc',    ~dbcc,	$59C8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnmi',    ~dbcc,	$5AC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnpl',    ~dbcc,	$5BC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnlt',    ~dbcc,	$5CC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnge',    ~dbcc,	$5DC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbnle',    ~dbcc,	$5EC8,C000|C010|C020|C030|C040|C060,    SZW
	optbl	'dbngt',    ~dbcc,	$5FC8,C000|C010|C020|C030|C040|C060,    SZW

	optbl	'subx',     ~subaddx,	$9100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'addx',     ~subaddx,	$D100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'negx',     ~negnot,	$4000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL

	optbl	'sbcd',     ~sabcd,	$8100,C000|C010|C020|C030|C040|C060,SZB
	optbl	'abcd',     ~sabcd,	$C100,C000|C010|C020|C030|C040|C060,SZB
	optbl	'nbcd',     ~scc,	$4800,C000|C010|C020|C030|C040|C060,SZB

	optbl	'bftst',    ~bftst,	$E8C0,		C020|C030|C040|C060,SZNO
	optbl	'bfextu',   ~bfextffo,	$E9C0,		C020|C030|C040|C060,SZNO
	optbl	'bfchg',    ~bfchclst,	$EAC0,		C020|C030|C040|C060,SZNO
	optbl	'bfexts',   ~bfextffo,	$EBC0,		C020|C030|C040|C060,SZNO
	optbl	'bfclr',    ~bfchclst,	$ECC0,		C020|C030|C040|C060,SZNO
	optbl	'bfffo',    ~bfextffo,	$EDC0,		C020|C030|C040|C060,SZNO
	optbl	'bfset',    ~bfchclst,	$EEC0,		C020|C030|C040|C060,SZNO
	optbl	'bfins',    ~bfins,	$EFC0,		C020|C030|C040|C060,SZNO

	optbl	'trap',     ~trap,	$4E40,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'illegal',  ~noopr,	$4AFC,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'reset',    ~noopr,	$4E70,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'nop',	    ~noopr,	$4E71,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'rte',	    ~noopr,	$4E73,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'trapv',    ~noopr,	$4E76,C000|C010|C020|C030|C040|C060,SZNO
	optbln	'rtr',	    ~noopr,	$4E77,C000|C010|C020|C030|C040|C060,SZNO
	optbl	'stop',     ~stop,	$4E72,C000|C010|C020|C030|C040|C060,SZNO
	optbl	'lpstop',   ~lpstop,	$F800,			       C060,    SZW

	optbl	'rtd',	    ~rtd,	$4E74,	   C010|C020|C030|C040|C060,SZNO

	optbl	'chk',	    ~chk,	$4100,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'tas',	    ~tas,	$4AC0,C000|C010|C020|C030|C040|C060,SZB

	optbl	'movep',    ~movep,	$0108,C000|C010|C020|C030|C040|C060,    SZW|SZL
	optbl	'moves',    ~moves,	$0E00,	   C010|C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'movec',    ~movec,	$4E7A,	   C010|C020|C030|C040|C060,        SZL
	optbl	'bkpt',     ~bkpt,	$4848,	   C010|C020|C030|C040|C060,SZNO
;GASコード
;	optbl	'movp',	    ~movep,	$0108,C000|C010|C020|C030|C040|C060,    SZW|SZL
;	optbl	'movs',	    ~moves,	$0E00,	   C010|C020|C030|C040|C060,SZB|SZW|SZL
;	optbl	'movc',	    ~movec,	$4E7A,	   C010|C020|C030|C040|C060,        SZL

	optbl	'cas',	    ~cas,	$08C0,		C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'cas2',     ~cas2,	$08FC,		C020|C030|C040|C060,    SZW|SZL
	optbl	'cmp2',     ~cmpchk2,	$0000,		C020|C030|C040|C060,SZB|SZW|SZL
	optbl	'chk2',     ~cmpchk2,	$0800,		C020|C030|C040|C060,SZB|SZW|SZL

	optbl	'pack',     ~packunpk,	$8140,		C020|C030|C040|C060,SZNO
	optbl	'unpk',     ~packunpk,	$8180,		C020|C030|C040|C060,SZNO

	optbln	'trapt',    ~trapcc,	$50F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapf',    ~trapcc,	$51F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'traphi',   ~trapcc,	$52F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapls',   ~trapcc,	$53F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapcc',   ~trapcc,	$54F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'traphs',   ~trapcc,	$54F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapcs',   ~trapcc,	$55F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'traplo',   ~trapcc,	$55F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapne',   ~trapcc,	$56F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnz',   ~trapcc,	$56F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapeq',   ~trapcc,	$57F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapze',   ~trapcc,	$57F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapvc',   ~trapcc,	$58F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapvs',   ~trapcc,	$59F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trappl',   ~trapcc,	$5AF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapmi',   ~trapcc,	$5BF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapge',   ~trapcc,	$5CF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'traplt',   ~trapcc,	$5DF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapgt',   ~trapcc,	$5EF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'traple',   ~trapcc,	$5FF8,		C020|C030|C040|C060,    SZW|SZL

	optbln	'trapnf',   ~trapcc,	$50F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnt',   ~trapcc,	$51F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnls',  ~trapcc,	$52F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnhi',  ~trapcc,	$53F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapncs',  ~trapcc,	$54F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnlo',  ~trapcc,	$54F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapncc',  ~trapcc,	$55F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnhs',  ~trapcc,	$55F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapneq',  ~trapcc,	$56F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnze',  ~trapcc,	$56F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnne',  ~trapcc,	$57F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnnz',  ~trapcc,	$57F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnvs',  ~trapcc,	$58F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnvc',  ~trapcc,	$59F8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnmi',  ~trapcc,	$5AF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnpl',  ~trapcc,	$5BF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnlt',  ~trapcc,	$5CF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnge',  ~trapcc,	$5DF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapnle',  ~trapcc,	$5EF8,		C020|C030|C040|C060,    SZW|SZL
	optbln	'trapngt',  ~trapcc,	$5FF8,		C020|C030|C040|C060,    SZW|SZL

	optbl	'callm',    ~callm,	$06C0,		C020,               SZNO
	optbl	'rtm',	    ~rtm,	$06C0,		C020,               SZNO

	optbl	'move16',   ~move16,	$F600,                    C040|C060,SZNO
;GASコード
;	optbl	'mov16',    ~move16,	$F600,                    C040|C060,SZNO

	optbl	'jbra',	    ~jbcc,	$6000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbt',	    ~jbcc,	$6000,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbsr',	    ~jbcc,	$6100,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbhi',	    ~jbcc,	$6200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbls',	    ~jbcc,	$6300,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbcc',	    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbhs',	    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbcs',	    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jblo',	    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbne',	    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnz',	    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbeq',	    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbze',	    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbvc',	    ~jbcc,	$6800,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbvs',	    ~jbcc,	$6900,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbpl',	    ~jbcc,	$6A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbmi',	    ~jbcc,	$6B00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbge',	    ~jbcc,	$6C00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jblt',	    ~jbcc,	$6D00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbgt',	    ~jbcc,	$6E00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jble',	    ~jbcc,	$6F00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnls',    ~jbcc,	$6200,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnhi',    ~jbcc,	$6300,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbncs',    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnlo',    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbncc',    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnhs',    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbneq',    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnze',    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnne',    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnnz',    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnvs',    ~jbcc,	$6800,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnvc',    ~jbcc,	$6900,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnmi',    ~jbcc,	$6A00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnpl',    ~jbcc,	$6B00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnlt',    ~jbcc,	$6C00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnge',    ~jbcc,	$6D00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbnle',    ~jbcc,	$6E00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS
	optbl	'jbngt',    ~jbcc,	$6F00,C000|C010|C020|C030|C040|C060,SZB|SZW|SZL|SZS

	pstbl	'rept',     ~~rept
	pstbl	'irp',	    ~~irp
	pstbl	'irpc',     ~~irpc

	pstbl	'xdef',     ~~xdef
	pstbl	'xref',     ~~xref
	pstbl	'globl',    ~~globl
	pstbl	'entry',    ~~xdef
	pstbl	'public',   ~~xdef
	pstbl	'extrn',    ~~xref
	pstbl	'external', ~~xref
	pstbl	'global',   ~~globl
	pstbl	'extern',   ~~extern

	pstbl	'text',     ~~text
	pstbl	'data',     ~~data
	pstbl	'bss',	    ~~bss
	pstbl	'comm',     ~~comm
	pstbl	'stack',    ~~stack
	pstbl	'offset',   ~~offset
	pstbl	'offsym',   ~~offsym

	pstbl	'macro',    ~~macro
	pstbl	'exitm',    ~~exitm
	pstbl	'endm',     ~~endm
	pstbl	'local',    ~~local
	pstbl	'sizem',    ~~sizem

	pstbl	'if',	    ~~if
	pstbl	'ifne',     ~~if
	pstbl	'iff',	    ~~iff
	pstbl	'ifeq',     ~~iff
	pstbl	'ifdef',    ~~ifdef
	pstbl	'ifndef',   ~~ifndef
	pstbl	'else',     ~~else
	pstbl	'elseif',   ~~elseif
	pstbl	'elif',     ~~elseif
	pstbl	'endif',    ~~endif
	pstbl	'endc',     ~~endif

	pstbl	'end',	    ~~end

	pstbl	'insert',   ~~insert

	pstbl	'include',  ~~include
	pstbl	'request',  ~~request

	pstbl	'list',     ~~list
	pstbl	'nlist',    ~~nlist
	pstbl	'lall',     ~~lall
	pstbl	'sall',     ~~sall

	pstbl	'width',    ~~width
	pstbl	'page',     ~~page
	pstbl	'title',    ~~title
	pstbl	'subttl',   ~~subttl
	pstbl	'comment',  ~~comment
	pstbl	'fail',     ~~fail
	pstbl	'cpu',	    ~~cpu
	pstbl	'org',	    ~~org

	pstbl	'file',     ~~file
	pstbl	'ln',	    ~~ln
	pstbl	'def',	    ~~def
	pstbl	'endef',    ~~endef
	pstbl	'val',	    ~~val
	pstbl	'scl',	    ~~scl
	pstbl	'type',     ~~type
	pstbl	'tag',	    ~~tag
	pstbl	'line',     ~~line
	pstbl	'size',     ~~size
	pstbl	'dim',	    ~~dim

	pstbl	'fpid',	    ~~fpid
	pstbl	'pragma',   ~~pragma
	pstbls	'fequ',     ~~fequ,		    SZS|SZD|SZX|SZP
	pstbls	'fset',     ~~fset,		    SZS|SZD|SZX|SZP

	optbl	'fmove',    ~fmove,	$0000,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
;GASコード追加
;	optbl	'fmov',	    ~fmove,	$0000,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fint',     ~fint,	$0001,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsinh',    ~funarys,	$0002,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fintrz',   ~fint,	$0003,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsqrt',    ~funary,	$0004,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'flognp1',  ~funarys,	$0006,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fetoxm1',  ~funarys,	$0008,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'ftanh',    ~funarys,	$0009,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fatan',    ~funarys,	$000A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fasin',    ~funarys,	$000C,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fatanh',   ~funarys,	$000D,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsin',     ~funarys,	$000E,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'ftan',     ~funarys,	$000F,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fetox',    ~funarys,	$0010,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'ftwotox',  ~funarys,	$0011,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'ftentox',  ~funarys,	$0012,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'flogn',    ~funarys,	$0014,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'flog10',   ~funarys,	$0015,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'flog2',    ~funarys,	$0016,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fabs',     ~fabsneg,	$0018,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fcosh',    ~funarys,	$0019,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fneg',     ~fabsneg,	$001A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'facos',    ~funarys,	$001C,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fcos',     ~funarys,	$001D,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fgetexp',  ~funarys,	$001E,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fgetman',  ~funarys,	$001F,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP

	optbl	'ftst',     ~ftst,	$003A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fcmp',     ~fcmp,	$0038,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP

	optbl	'fdiv',     ~fopr,	$0020,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fmod',     ~fopr,	$0021,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fadd',     ~fopr,	$0022,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fmul',     ~fopr,	$0023,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsgldiv',  ~fsgl,	$0024,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'frem',     ~fopr,	$0025,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fscale',   ~fopr,	$0026,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsglmul',  ~fsgl,	$0027,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsub',     ~fopr,	$0028,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP

	optbl	'fssqrt',   ~funary,	$0041,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdsqrt',   ~funary,	$0045,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsabs',    ~funary,	$0058,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdabs',    ~funary,	$005C,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsneg',    ~funary,	$005A,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdneg',    ~funary,	$005E,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsmove',   ~fopr,	$0040,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdmove',   ~fopr,	$0044,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsdiv',    ~fopr,	$0060,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fddiv',    ~fopr,	$0064,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsadd',    ~fopr,	$0062,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdadd',    ~fopr,	$0066,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fsmul',    ~fopr,	$0063,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdmul',    ~fopr,	$0067,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fssub',    ~fopr,	$0068,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fdsub',    ~fopr,	$006C,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
;GASコード
;	optbl	'fsmov',    ~fopr,	$0040,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP
;	optbl	'fdmov',    ~fopr,	$0044,C040|C060,     SZB|SZW|SZL|SZS|SZD|SZX|SZP

	optbl	'fsincos',  ~fsincos,	$0030,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP
	optbl	'fmovecr',  ~fmovecr,	$5C00,C040|C060|CFPP,                    SZX
	optbl	'fmovem',   ~fmovem,	$C000,C040|C060|CFPP,        SZL|SZX
	optbln	'fnop',     ~fnop,	$F080,C040|C060|CFPP,SZNO
	optbl	'fsave',    ~fsave,	$F100,C040|C060|CFPP,SZNO
	optbl	'frestore', ~frestore,	$F140,C040|C060|CFPP,SZNO
;GASコード
;	optbl	'fmovcr',   ~fmovecr,	$5C00,C040|C060|CFPP,            SZX
;	optbl	'fmovm',    ~fmovem,	$C000,C040|C060|CFPP,        SZL|SZX

	optbl	'fbf',	    ~fbcc,	$F080,C040|C060|CFPP,    SZW|SZL
	optbl	'fbeq',     ~fbcc,	$F081,C040|C060|CFPP,    SZW|SZL
	optbl	'fbogt',    ~fbcc,	$F082,C040|C060|CFPP,    SZW|SZL
	optbl	'fboge',    ~fbcc,	$F083,C040|C060|CFPP,    SZW|SZL
	optbl	'fbolt',    ~fbcc,	$F084,C040|C060|CFPP,    SZW|SZL
	optbl	'fbole',    ~fbcc,	$F085,C040|C060|CFPP,    SZW|SZL
	optbl	'fbogl',    ~fbcc,	$F086,C040|C060|CFPP,    SZW|SZL
	optbl	'fbor',     ~fbcc,	$F087,C040|C060|CFPP,    SZW|SZL
	optbl	'fbun',     ~fbcc,	$F088,C040|C060|CFPP,    SZW|SZL
	optbl	'fbueq',    ~fbcc,	$F089,C040|C060|CFPP,    SZW|SZL
	optbl	'fbugt',    ~fbcc,	$F08A,C040|C060|CFPP,    SZW|SZL
	optbl	'fbuge',    ~fbcc,	$F08B,C040|C060|CFPP,    SZW|SZL
	optbl	'fbult',    ~fbcc,	$F08C,C040|C060|CFPP,    SZW|SZL
	optbl	'fbule',    ~fbcc,	$F08D,C040|C060|CFPP,    SZW|SZL
	optbl	'fbne',     ~fbcc,	$F08E,C040|C060|CFPP,    SZW|SZL
	optbl	'fbt',	    ~fbcc,	$F08F,C040|C060|CFPP,    SZW|SZL
	optbl	'fbra',     ~fbcc,	$F08F,C040|C060|CFPP,    SZW|SZL
	optbl	'fbsf',     ~fbcc,	$F090,C040|C060|CFPP,    SZW|SZL
	optbl	'fbseq',    ~fbcc,	$F091,C040|C060|CFPP,    SZW|SZL
	optbl	'fbgt',     ~fbcc,	$F092,C040|C060|CFPP,    SZW|SZL
	optbl	'fbge',     ~fbcc,	$F093,C040|C060|CFPP,    SZW|SZL
	optbl	'fblt',     ~fbcc,	$F094,C040|C060|CFPP,    SZW|SZL
	optbl	'fble',     ~fbcc,	$F095,C040|C060|CFPP,    SZW|SZL
	optbl	'fbgl',     ~fbcc,	$F096,C040|C060|CFPP,    SZW|SZL
	optbl	'fbgle',    ~fbcc,	$F097,C040|C060|CFPP,    SZW|SZL
	optbl	'fbngle',   ~fbcc,	$F098,C040|C060|CFPP,    SZW|SZL
	optbl	'fbngl',    ~fbcc,	$F099,C040|C060|CFPP,    SZW|SZL
	optbl	'fbnle',    ~fbcc,	$F09A,C040|C060|CFPP,    SZW|SZL
	optbl	'fbnlt',    ~fbcc,	$F09B,C040|C060|CFPP,    SZW|SZL
	optbl	'fbnge',    ~fbcc,	$F09C,C040|C060|CFPP,    SZW|SZL
	optbl	'fbngt',    ~fbcc,	$F09D,C040|C060|CFPP,    SZW|SZL
	optbl	'fbsne',    ~fbcc,	$F09E,C040|C060|CFPP,    SZW|SZL
	optbl	'fbst',     ~fbcc,	$F09F,C040|C060|CFPP,    SZW|SZL

	optbl	'fdbf',     ~fdbcc,	$0000,C040|C060|CFPP,SZNO
	optbl	'fdbra',    ~fdbcc,	$0000,C040|C060|CFPP,SZNO
	optbl	'fdbeq',    ~fdbcc,	$0001,C040|C060|CFPP,SZNO
	optbl	'fdbogt',   ~fdbcc,	$0002,C040|C060|CFPP,SZNO
	optbl	'fdboge',   ~fdbcc,	$0003,C040|C060|CFPP,SZNO
	optbl	'fdbolt',   ~fdbcc,	$0004,C040|C060|CFPP,SZNO
	optbl	'fdbole',   ~fdbcc,	$0005,C040|C060|CFPP,SZNO
	optbl	'fdbogl',   ~fdbcc,	$0006,C040|C060|CFPP,SZNO
	optbl	'fdbor',    ~fdbcc,	$0007,C040|C060|CFPP,SZNO
	optbl	'fdbun',    ~fdbcc,	$0008,C040|C060|CFPP,SZNO
	optbl	'fdbueq',   ~fdbcc,	$0009,C040|C060|CFPP,SZNO
	optbl	'fdbugt',   ~fdbcc,	$000A,C040|C060|CFPP,SZNO
	optbl	'fdbuge',   ~fdbcc,	$000B,C040|C060|CFPP,SZNO
	optbl	'fdbult',   ~fdbcc,	$000C,C040|C060|CFPP,SZNO
	optbl	'fdbule',   ~fdbcc,	$000D,C040|C060|CFPP,SZNO
	optbl	'fdbne',    ~fdbcc,	$000E,C040|C060|CFPP,SZNO
	optbl	'fdbt',     ~fdbcc,	$000F,C040|C060|CFPP,SZNO
	optbl	'fdbsf',    ~fdbcc,	$0010,C040|C060|CFPP,SZNO
	optbl	'fdbseq',   ~fdbcc,	$0011,C040|C060|CFPP,SZNO
	optbl	'fdbgt',    ~fdbcc,	$0012,C040|C060|CFPP,SZNO
	optbl	'fdbge',    ~fdbcc,	$0013,C040|C060|CFPP,SZNO
	optbl	'fdblt',    ~fdbcc,	$0014,C040|C060|CFPP,SZNO
	optbl	'fdble',    ~fdbcc,	$0015,C040|C060|CFPP,SZNO
	optbl	'fdbgl',    ~fdbcc,	$0016,C040|C060|CFPP,SZNO
	optbl	'fdbgle',   ~fdbcc,	$0017,C040|C060|CFPP,SZNO
	optbl	'fdbngle',  ~fdbcc,	$0018,C040|C060|CFPP,SZNO
	optbl	'fdbngl',   ~fdbcc,	$0019,C040|C060|CFPP,SZNO
	optbl	'fdbnle',   ~fdbcc,	$001A,C040|C060|CFPP,SZNO
	optbl	'fdbnlt',   ~fdbcc,	$001B,C040|C060|CFPP,SZNO
	optbl	'fdbnge',   ~fdbcc,	$001C,C040|C060|CFPP,SZNO
	optbl	'fdbngt',   ~fdbcc,	$001D,C040|C060|CFPP,SZNO
	optbl	'fdbsne',   ~fdbcc,	$001E,C040|C060|CFPP,SZNO
	optbl	'fdbst',    ~fdbcc,	$001F,C040|C060|CFPP,SZNO

	optbl	'fsf',	    ~fscc,	$0000,C040|C060|CFPP,SZB
	optbl	'fseq',     ~fscc,	$0001,C040|C060|CFPP,SZB
	optbl	'fsogt',    ~fscc,	$0002,C040|C060|CFPP,SZB
	optbl	'fsoge',    ~fscc,	$0003,C040|C060|CFPP,SZB
	optbl	'fsolt',    ~fscc,	$0004,C040|C060|CFPP,SZB
	optbl	'fsole',    ~fscc,	$0005,C040|C060|CFPP,SZB
	optbl	'fsogl',    ~fscc,	$0006,C040|C060|CFPP,SZB
	optbl	'fsor',     ~fscc,	$0007,C040|C060|CFPP,SZB
	optbl	'fsun',     ~fscc,	$0008,C040|C060|CFPP,SZB
	optbl	'fsueq',    ~fscc,	$0009,C040|C060|CFPP,SZB
	optbl	'fsugt',    ~fscc,	$000A,C040|C060|CFPP,SZB
	optbl	'fsuge',    ~fscc,	$000B,C040|C060|CFPP,SZB
	optbl	'fsult',    ~fscc,	$000C,C040|C060|CFPP,SZB
	optbl	'fsule',    ~fscc,	$000D,C040|C060|CFPP,SZB
	optbl	'fsne',     ~fscc,	$000E,C040|C060|CFPP,SZB
	optbl	'fst',	    ~fscc,	$000F,C040|C060|CFPP,SZB
	optbl	'fssf',     ~fscc,	$0010,C040|C060|CFPP,SZB
	optbl	'fsseq',    ~fscc,	$0011,C040|C060|CFPP,SZB
	optbl	'fsgt',     ~fscc,	$0012,C040|C060|CFPP,SZB
	optbl	'fsge',     ~fscc,	$0013,C040|C060|CFPP,SZB
	optbl	'fslt',     ~fscc,	$0014,C040|C060|CFPP,SZB
	optbl	'fsle',     ~fscc,	$0015,C040|C060|CFPP,SZB
	optbl	'fsgl',     ~fscc,	$0016,C040|C060|CFPP,SZB
	optbl	'fsgle',    ~fscc,	$0017,C040|C060|CFPP,SZB
	optbl	'fsngle',   ~fscc,	$0018,C040|C060|CFPP,SZB
	optbl	'fsngl',    ~fscc,	$0019,C040|C060|CFPP,SZB
	optbl	'fsnle',    ~fscc,	$001A,C040|C060|CFPP,SZB
	optbl	'fsnlt',    ~fscc,	$001B,C040|C060|CFPP,SZB
	optbl	'fsnge',    ~fscc,	$001C,C040|C060|CFPP,SZB
	optbl	'fsngt',    ~fscc,	$001D,C040|C060|CFPP,SZB
	optbl	'fssne',    ~fscc,	$001E,C040|C060|CFPP,SZB
	optbl	'fsst',     ~fscc,	$001F,C040|C060|CFPP,SZB

	optbln	'ftrapf',   ~ftrapcc,	$0000,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapeq',  ~ftrapcc,	$0001,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapogt', ~ftrapcc,	$0002,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapoge', ~ftrapcc,	$0003,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapolt', ~ftrapcc,	$0004,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapole', ~ftrapcc,	$0005,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapogl', ~ftrapcc,	$0006,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapor',  ~ftrapcc,	$0007,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapun',  ~ftrapcc,	$0008,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapueq', ~ftrapcc,	$0009,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapugt', ~ftrapcc,	$000A,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapuge', ~ftrapcc,	$000B,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapult', ~ftrapcc,	$000C,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapule', ~ftrapcc,	$000D,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapne',  ~ftrapcc,	$000E,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapt',   ~ftrapcc,	$000F,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapsf',  ~ftrapcc,	$0010,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapseq', ~ftrapcc,	$0011,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapgt',  ~ftrapcc,	$0012,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapge',  ~ftrapcc,	$0013,C040|C060|CFPP,    SZW|SZL
	optbln	'ftraplt',  ~ftrapcc,	$0014,C040|C060|CFPP,    SZW|SZL
	optbln	'ftraple',  ~ftrapcc,	$0015,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapgl',  ~ftrapcc,	$0016,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapgle', ~ftrapcc,	$0017,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapngle',~ftrapcc,	$0018,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapngl', ~ftrapcc,	$0019,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapnle', ~ftrapcc,	$001A,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapnlt', ~ftrapcc,	$001B,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapnge', ~ftrapcc,	$001C,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapngt', ~ftrapcc,	$001D,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapsne', ~ftrapcc,	$001E,C040|C060|CFPP,    SZW|SZL
	optbln	'ftrapst',  ~ftrapcc,	$001F,C040|C060|CFPP,    SZW|SZL

	optbl	'cinvl',    ~cinvpushlp,$F408,C040|C060,          SZNO
	optbl	'cinvp',    ~cinvpushlp,$F410,C040|C060,          SZNO
	optbl	'cinva',    ~cinvpusha, $F418,C040|C060,          SZNO
	optbl	'cpushl',   ~cinvpushlp,$F428,C040|C060,          SZNO
	optbl	'cpushp',   ~cinvpushlp,$F430,C040|C060,          SZNO
	optbl	'cpusha',   ~cinvpusha, $F438,C040|C060,          SZNO

	optbln	'pflusha',  ~pflusha,	$F518,CMMU|C030|C040|C060,SZNO
	optbl	'pflush',   ~pflush,	$F508,CMMU|C030|C040|C060,SZNO
	optbln	'pflushan', ~pflushan,	$F510,		C040|C060,SZNO
	optbl	'pflushn',  ~pflushn,	$F500,		C040|C060,SZNO

	optbl	'pflushs',  ~pflushs,	$3400,CMMU,               SZNO
	optbl	'pflushr',  ~pflushr,	$A000,CMMU,               SZNO

	optbl	'pmove',    ~pmove,	$0000,CMMU|C030,	  SZB|SZW|SZL|SZD|SZQ
	optbl	'pmovefd',  ~pmovefd,	$0100,	   C030,	      SZW|SZL|SZQ
	optbl	'ploadr',   ~ploadwr,	$2200,CMMU|C030,	  SZNO
	optbl	'ploadw',   ~ploadwr,	$2000,CMMU|C030,	  SZNO
	optbl	'ptestw',   ~ptestwr,	$8000,CMMU|C030|C040,	  SZNO
	optbl	'ptestr',   ~ptestwr,	$8200,CMMU|C030|C040,	  SZNO
	optbl	'plpaw',    ~pflushn,	$F588,		     C060,SZNO
	optbl	'plpar',    ~pflushn,	$F5C8,		     C060,SZNO
	optbl	'psave',    ~psave,	$F100,CMMU,		  SZNO
	optbl	'prestore', ~prestore,	$F140,CMMU,		  SZNO
	optbl	'pvalid',   ~pvalid,	$2800,CMMU,			  SZL
;GASコード
;	optbl	'pmov',	    ~pmove,	$0000,CMMU|C030,	  SZB|SZW|SZL|SZD|SZQ
;	optbl	'pmovfd',   ~pmovefd,	$0100,	   C030,	      SZW|SZL|SZQ

	optbl	'pbbs',     ~pbcc,	$F080,CMMU,		      SZW|SZL
	optbl	'pbbc',     ~pbcc,	$F081,CMMU,		      SZW|SZL
	optbl	'pbls',     ~pbcc,	$F082,CMMU,		      SZW|SZL
	optbl	'pblc',     ~pbcc,	$F083,CMMU,		      SZW|SZL
	optbl	'pbss',     ~pbcc,	$F084,CMMU,		      SZW|SZL
	optbl	'pbsc',     ~pbcc,	$F085,CMMU,		      SZW|SZL
	optbl	'pbas',     ~pbcc,	$F086,CMMU,		      SZW|SZL
	optbl	'pbac',     ~pbcc,	$F087,CMMU,		      SZW|SZL
	optbl	'pbws',     ~pbcc,	$F088,CMMU,		      SZW|SZL
	optbl	'pbwc',     ~pbcc,	$F089,CMMU,		      SZW|SZL
	optbl	'pbis',     ~pbcc,	$F08A,CMMU,		      SZW|SZL
	optbl	'pbic',     ~pbcc,	$F08B,CMMU,		      SZW|SZL
	optbl	'pbgs',     ~pbcc,	$F08C,CMMU,		      SZW|SZL
	optbl	'pbgc',     ~pbcc,	$F08D,CMMU,		      SZW|SZL
	optbl	'pbcs',     ~pbcc,	$F08E,CMMU,		      SZW|SZL
	optbl	'pbcc',     ~pbcc,	$F08F,CMMU,		      SZW|SZL

	optbl	'pdbbs',    ~pdbcc,	$0000,CMMU,		      SZW
	optbl	'pdbbc',    ~pdbcc,	$0001,CMMU,		      SZW
	optbl	'pdbls',    ~pdbcc,	$0002,CMMU,		      SZW
	optbl	'pdblc',    ~pdbcc,	$0003,CMMU,		      SZW
	optbl	'pdbss',    ~pdbcc,	$0004,CMMU,		      SZW
	optbl	'pdbsc',    ~pdbcc,	$0005,CMMU,		      SZW
	optbl	'pdbas',    ~pdbcc,	$0006,CMMU,		      SZW
	optbl	'pdbac',    ~pdbcc,	$0007,CMMU,		      SZW
	optbl	'pdbws',    ~pdbcc,	$0008,CMMU,		      SZW
	optbl	'pdbwc',    ~pdbcc,	$0009,CMMU,		      SZW
	optbl	'pdbis',    ~pdbcc,	$000A,CMMU,		      SZW
	optbl	'pdbic',    ~pdbcc,	$000B,CMMU,		      SZW
	optbl	'pdbgs',    ~pdbcc,	$000C,CMMU,		      SZW
	optbl	'pdbgc',    ~pdbcc,	$000D,CMMU,		      SZW
	optbl	'pdbcs',    ~pdbcc,	$000E,CMMU,		      SZW
	optbl	'pdbcc',    ~pdbcc,	$000F,CMMU,		      SZW

	optbl	'psbs',     ~pscc,	$0000,CMMU,		  SZB
	optbl	'psbc',     ~pscc,	$0001,CMMU,		  SZB
	optbl	'psls',     ~pscc,	$0002,CMMU,		  SZB
	optbl	'pslc',     ~pscc,	$0003,CMMU,		  SZB
	optbl	'psss',     ~pscc,	$0004,CMMU,		  SZB
	optbl	'pssc',     ~pscc,	$0005,CMMU,		  SZB
	optbl	'psas',     ~pscc,	$0006,CMMU,		  SZB
	optbl	'psac',     ~pscc,	$0007,CMMU,		  SZB
	optbl	'psws',     ~pscc,	$0008,CMMU,		  SZB
	optbl	'pswc',     ~pscc,	$0009,CMMU,		  SZB
	optbl	'psis',     ~pscc,	$000A,CMMU,		  SZB
	optbl	'psic',     ~pscc,	$000B,CMMU,		  SZB
	optbl	'psgs',     ~pscc,	$000C,CMMU,		  SZB
	optbl	'psgc',     ~pscc,	$000D,CMMU,		  SZB
	optbl	'pscs',     ~pscc,	$000E,CMMU,		  SZB
	optbl	'pscc',     ~pscc,	$000F,CMMU,		  SZB

	optbln	'ptrapbs',  ~ptrapcc,	$0000,CMMU,		      SZW|SZL
	optbln	'ptrapbc',  ~ptrapcc,	$0001,CMMU,		      SZW|SZL
	optbln	'ptrapls',  ~ptrapcc,	$0002,CMMU,		      SZW|SZL
	optbln	'ptraplc',  ~ptrapcc,	$0003,CMMU,		      SZW|SZL
	optbln	'ptrapss',  ~ptrapcc,	$0004,CMMU,		      SZW|SZL
	optbln	'ptrapsc',  ~ptrapcc,	$0005,CMMU,		      SZW|SZL
	optbln	'ptrapas',  ~ptrapcc,	$0006,CMMU,		      SZW|SZL
	optbln	'ptrapac',  ~ptrapcc,	$0007,CMMU,		      SZW|SZL
	optbln	'ptrapws',  ~ptrapcc,	$0008,CMMU,		      SZW|SZL
	optbln	'ptrapwc',  ~ptrapcc,	$0009,CMMU,		      SZW|SZL
	optbln	'ptrapis',  ~ptrapcc,	$000A,CMMU,		      SZW|SZL
	optbln	'ptrapic',  ~ptrapcc,	$000B,CMMU,		      SZW|SZL
	optbln	'ptrapgs',  ~ptrapcc,	$000C,CMMU,		      SZW|SZL
	optbln	'ptrapgc',  ~ptrapcc,	$000D,CMMU,		      SZW|SZL
	optbln	'ptrapcs',  ~ptrapcc,	$000E,CMMU,		      SZW|SZL
	optbln	'ptrapcc',  ~ptrapcc,	$000F,CMMU,		      SZW|SZL

	.endm


;----------------------------------------------------------------
;	オペコード名
;----------------------------------------------------------------
	.fail	sizeofCPUTYPE.ne.2

optbl	.macro	opname,addr,opcode,arch,size	;オペコードテーブル定義マクロ
	.fail	(arch).and.$ff		;下位バイトは現在使用していないので省略
	.dc.b	opname,0,0,(arch)>>8,.notb.(size)
	.endm

optbln	.macro	opname,addr,opcode,arch,size	;(オペランドなし命令用)
	.fail	(arch).and.$ff		;下位バイトは現在使用していないので省略
	.dc.b	opname,0,-1,(arch)>>8,.notb.(size)
	.endm

pstbl	.macro	psname,addr		;疑似命令テーブル定義マクロ
	.dc.b	psname,0,0,0,.notb.(SZNO)
	.endm

pstbls	.macro	psname,addr,size	;(サイズ付き疑似命令用)
	.dc.b	psname,0,0,0,.notb.(size)
	.endm

opcode_tbl::
	tablebody
	.dc.b	0
	.even


;----------------------------------------------------------------
;	アドレス・命令コード
;----------------------------------------------------------------
optbl	.macro	opname,addr,opcode,arch,size	;オペコードテーブル定義マクロ
	.dc.w	opcode
	.dc.l	addr-(*)
	.endm

optbln	.macro	opname,addr,opcode,arch,size	;(オペランドなし命令用)
	.dc.w	opcode
	.dc.l	addr-(*)
	.endm

pstbl	.macro	psname,addr			;疑似命令テーブル定義マクロ
	.dc.w	0
	.dc.l	addr-(*)
	.endm

pstbls	.macro	psname,addr,size		;(サイズ付き疑似命令用)
	.dc.w	0
	.dc.l	addr-(*)
	.endm

opadr_tbl::
	tablebody


;----------------------------------------------------------------
	.end
