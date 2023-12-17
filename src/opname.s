;----------------------------------------------------------------
;	X68k High-speed Assembler
;		オペコード名テーブル
;		< opname.s >
;
;	$Id: opname.s,v 2.7  1999  2/27(Sat) 23:43:43 M.Kamada Exp $
;
;		Copyright 1990-94  by Y.Nakamura
;			  1996-99  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	cputype.equ
	.include	register.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	オペコード名テーブル
;----------------------------------------------------------------
tablebody	.macro

	optbl	'move',	    ~move,	$0000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
	optbl	'moveq',    ~moveq,	$7000,C000|C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
	optbl	'movea',    ~movea,	$2040,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbl	'movem',    ~movem,	$4880,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,        SZL
	optbl	'lea',	    ~lea,	$41C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
	optbl	'pea',	    ~peajsrjmp,	$4840,C000|C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
	optbl	'jsr',	    ~jmpjsr,	$4E80,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbl	'jmp',	    ~jmpjsr,	$4EC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
;GASコード
;	optbl	'mov',	    ~move,	$0000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
;	optbl	'movq',	    ~moveq,	$7000,C000|C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
;	optbl	'mova',	    ~movea,	$2040,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
;	optbl	'movm',	    ~movem,	$4880,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,        SZL

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

	optbl	'bra',	    ~bcc,	$6000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bt',	    ~bcc,	$6000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bsr',	    ~bcc,	$6100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bhi',	    ~bcc,	$6200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bls',	    ~bcc,	$6300,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bcc',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bhs',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bcs',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'blo',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bne',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnz',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'beq',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bze',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bvc',	    ~bcc,	$6800,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bvs',	    ~bcc,	$6900,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bpl',	    ~bcc,	$6A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bmi',	    ~bcc,	$6B00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bge',	    ~bcc,	$6C00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'blt',	    ~bcc,	$6D00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bgt',	    ~bcc,	$6E00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'ble',	    ~bcc,	$6F00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS

	optbl	'bnls',	    ~bcc,	$6200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnhi',	    ~bcc,	$6300,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bncs',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnlo',	    ~bcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bncc',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnhs',	    ~bcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bneq',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnze',	    ~bcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnne',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnnz',	    ~bcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnvs',	    ~bcc,	$6800,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnvc',	    ~bcc,	$6900,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnmi',	    ~bcc,	$6A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnpl',	    ~bcc,	$6B00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnlt',	    ~bcc,	$6C00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnge',	    ~bcc,	$6D00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bnle',	    ~bcc,	$6E00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'bngt',	    ~bcc,	$6F00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS

	optbln	'rts',	    ~noopr,	$4E75,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO

	optbl	'dbra',     ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,                   SZW,    SZNO

	optbl	'clr',	    ~clr,	$4200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
	optbl	'neg',	    ~negnot,	$4400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'not',	    ~negnot,	$4600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'tst',	    ~tst,	$4A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL

	optbl	'cmp',	    ~cmp,	$B000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
	optbl	'cmpi',     ~cmpi,	$0C00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
	optbl	'cmpa',     ~cmpa,	$B0C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbl	'cmpm',     ~cmpm,	$B108,C000|C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'sub',	    ~subadd,	$9000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'subq',     ~subaddq,	$5100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'subi',     ~subaddi,	$0400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'suba',     ~sbadcpa,	$90C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,        SZL
	optbl	'add',	    ~subadd,	$D000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'addq',     ~subaddq,	$5000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'addi',     ~subaddi,	$0600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'adda',     ~sbadcpa,	$D0C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,        SZL

	optbl	'or',	    ~orand,	$8000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'ori',	    ~orandeori, $0000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'and',	    ~orand,	$C000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'andi',     ~orandeori, $0200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'eor',	    ~eor,	$B100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'eori',     ~orandeori, $0A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL

	optbl	'link',     ~link,	$4E50,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW
	optbl	'unlk',     ~unlk,	$4E58,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO

	optbl	'exg',	    ~exg,	$C100,C000|C010|C020|C030|C040|C060,                       SZL,SZNO
	optbl	'ext',	    ~ext,	$4880,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbl	'extb',     ~extb,	$49C0,		C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
	optbl	'swap',     ~swap,	$4840,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW,        SZW

	optbl	'asr',	    ~sftrot,	$E000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'asl',	    ~asl,	$E100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'lsr',	    ~sftrot,	$E008,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'lsl',	    ~sftrot,	$E108,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'roxr',     ~sftrot,	$E010,C000|C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'roxl',     ~sftrot,	$E110,C000|C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'ror',	    ~sftrot,	$E018,C000|C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'rol',	    ~sftrot,	$E118,C000|C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO

	optbl	'bchg',     ~bchclst,	$0040,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZL,    SZB|SZL
	optbl	'bclr',     ~bchclst,	$0080,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZL,    SZB|SZL
	optbl	'bset',     ~bchclst,	$00C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZL,    SZB|SZL
	optbl	'btst',     ~btst,	$0000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZL,    SZB|SZL

	optbl	'st',	    ~scc,	$50C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sf',	    ~scc,	$51C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'shi',	    ~scc,	$52C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sls',	    ~scc,	$53C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'scc',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'shs',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'scs',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'slo',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sne',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snz',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'seq',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sze',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'svc',	    ~scc,	$58C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'svs',	    ~scc,	$59C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'spl',	    ~scc,	$5AC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'smi',	    ~scc,	$5BC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sge',	    ~scc,	$5CC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'slt',	    ~scc,	$5DC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sgt',	    ~scc,	$5EC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sle',	    ~scc,	$5FC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB

	optbl	'snf',	    ~scc,	$50C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snt',	    ~scc,	$51C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snls',	    ~scc,	$52C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snhi',	    ~scc,	$53C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sncs',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snlo',	    ~scc,	$54C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sncc',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snhs',	    ~scc,	$55C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sneq',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snze',	    ~scc,	$56C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snne',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snnz',	    ~scc,	$57C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snvs',	    ~scc,	$58C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snvc',	    ~scc,	$59C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snmi',	    ~scc,	$5AC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snpl',	    ~scc,	$5BC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snlt',	    ~scc,	$5CC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snge',	    ~scc,	$5DC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'snle',	    ~scc,	$5EC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB
	optbl	'sngt',	    ~scc,	$5FC0,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB,        SZB

	optbl	'divu',     ~divmul,	$80C0,C000|C010|C020|C030|C040|C060|C530|C540,         SZW|SZL,    SZW|SZL
	optbl	'divs',     ~divmul,	$81C0,C000|C010|C020|C030|C040|C060|C530|C540,         SZW|SZL,    SZW|SZL
	optbl	'mulu',     ~divmul,	$C0C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbl	'muls',     ~divmul,	$C1C0,C000|C010|C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbl	'divul',    ~divl,	$0000,		C020|C030|C040|C060,                       SZL,SZNO
	optbl	'divsl',    ~divl,	$0800,		C020|C030|C040|C060,                       SZL,SZNO
;ColdFireのremu/remsには未対応
;	optbl	'remu',     ~divmul,	$????,                              C530|C540,     SZNO,           SZW|SZL
;	optbl	'rems',     ~divmul,	$????,                              C530|C540,     SZNO,           SZW|SZL

	optbl	'dbt',	    ~dbcc,	$50C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbf',	    ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbhi',     ~dbcc,	$52C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbls',     ~dbcc,	$53C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbcc',     ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbhs',     ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbcs',     ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dblo',     ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbne',     ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnz',     ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbeq',     ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbze',     ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbvc',     ~dbcc,	$58C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbvs',     ~dbcc,	$59C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbpl',     ~dbcc,	$5AC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbmi',     ~dbcc,	$5BC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbge',     ~dbcc,	$5CC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dblt',     ~dbcc,	$5DC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbgt',     ~dbcc,	$5EC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dble',     ~dbcc,	$5FC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO

	optbl	'dbnf',	    ~dbcc,	$50C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnt',	    ~dbcc,	$51C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnls',    ~dbcc,	$52C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnhi',    ~dbcc,	$53C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbncs',    ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnlo',    ~dbcc,	$54C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbncc',    ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnhs',    ~dbcc,	$55C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbneq',    ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnze',    ~dbcc,	$56C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnne',    ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnnz',    ~dbcc,	$57C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnvs',    ~dbcc,	$58C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnvc',    ~dbcc,	$59C8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnmi',    ~dbcc,	$5AC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnpl',    ~dbcc,	$5BC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnlt',    ~dbcc,	$5CC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnge',    ~dbcc,	$5DC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbnle',    ~dbcc,	$5EC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO
	optbl	'dbngt',    ~dbcc,	$5FC8,C000|C010|C020|C030|C040|C060,         SZW,    SZNO

	optbl	'subx',     ~subaddx,	$9100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'addx',     ~subaddx,	$D100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL
	optbl	'negx',     ~negnot,	$4000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,        SZL

	optbl	'sbcd',     ~sabcd,	$8100,C000|C010|C020|C030|C040|C060,               SZB,        SZNO
	optbl	'abcd',     ~sabcd,	$C100,C000|C010|C020|C030|C040|C060,               SZB,        SZNO
	optbl	'nbcd',     ~scc,	$4800,C000|C010|C020|C030|C040|C060,               SZB,        SZNO

	optbl	'bftst',    ~bftst,	$E8C0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfextu',   ~bfextffo,	$E9C0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfchg',    ~bfchclst,	$EAC0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfexts',   ~bfextffo,	$EBC0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfclr',    ~bfchclst,	$ECC0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfffo',    ~bfextffo,	$EDC0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfset',    ~bfchclst,	$EEC0,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'bfins',    ~bfins,	$EFC0,		C020|C030|C040|C060,               SZNO,       SZNO

	optbl	'trap',     ~trap,	$4E40,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbln	'illegal',  ~noopr,	$4AFC,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbln	'reset',    ~noopr,	$4E70,C000|C010|C020|C030|C040|C060,               SZNO,       SZNO
	optbln	'nop',	    ~noopr,	$4E71,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbln	'rte',	    ~noopr,	$4E73,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbln	'trapv',    ~noopr,	$4E76,C000|C010|C020|C030|C040|C060,               SZNO,       SZNO
	optbln	'rtr',	    ~noopr,	$4E77,C000|C010|C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'stop',     ~stoprtd,	$4E72,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZNO,       SZNO
	optbl	'lpstop',   ~lpstop,	$F800,			       C060,                   SZW,    SZNO

	optbl	'mac',      ~mac,	$A000,				    C520|C530|C540,SZNO,           SZW|SZL
	optbl	'macl',     ~macl,	$A080,				    C520|C530|C540,SZNO,           SZW|SZL
	optbl	'msac',     ~msac,	$A000,				    C520|C530|C540,SZNO,           SZW|SZL
	optbl	'msacl',    ~msacl,	$A080,				    C520|C530|C540,SZNO,           SZW|SZL
	optbln	'halt',     ~noopr,	$4AC8,				    C520|C530|C540,SZNO,       SZNO
	optbln	'pulse',    ~noopr,	$4ACC,				    C520|C530|C540,SZNO,       SZNO
	optbl	'wddata',   ~wddata,	$FB00,				    C520|C530|C540,SZNO,       SZB|SZW|SZL
	optbl	'wdebug',   ~wdebug,	$FBC0,				    C520|C530|C540,SZNO,               SZL
	optbl	'mov3q',    ~mov3q,	$A140,					      C540,SZNO,               SZL
	optbl	'mvs',      ~mvsmvz,	$7100,					      C540,SZNO,       SZB|SZW
	optbl	'mvz',      ~mvsmvz,	$7180,					      C540,SZNO,       SZB|SZW
	optbl	'sats',     ~extb,	$4C80,					      C540,SZNO,               SZL

	optbl	'rtd',	    ~rtd,	$4E74,	   C010|C020|C030|C040|C060,               SZNO,       SZNO

	optbl	'chk',	    ~chk,	$4100,C000|C010|C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbl	'tas',	    ~tas,	$4AC0,C000|C010|C020|C030|C040|C060|C540,          SZB,        SZB

	optbl	'movep',    ~movep,	$0108,C000|C010|C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbl	'moves',    ~moves,	$0E00,	   C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'movec',    ~movec,	$4E7A,	   C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL
	optbl	'bkpt',     ~bkpt,	$4848,	   C010|C020|C030|C040|C060,               SZNO,       SZNO
;GASコード
;	optbl	'movp',	    ~movep,	$0108,C000|C010|C020|C030|C040|C060,                   SZW|SZL,SZNO
;	optbl	'movs',	    ~moves,	$0E00,	   C010|C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
;	optbl	'movc',	    ~movec,	$4E7A,	   C010|C020|C030|C040|C060|C520|C530|C540,        SZL,        SZL

	optbl	'cas',	    ~cas,	$08C0,		C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'cas2',     ~cas2,	$08FC,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbl	'cmp2',     ~cmpchk2,	$0000,		C020|C030|C040|C060,               SZB|SZW|SZL,SZNO
	optbl	'chk2',     ~cmpchk2,	$0800,		C020|C030|C040|C060,               SZB|SZW|SZL,SZNO

	optbl	'pack',     ~packunpk,	$8140,		C020|C030|C040|C060,               SZNO,       SZNO
	optbl	'unpk',     ~packunpk,	$8180,		C020|C030|C040|C060,               SZNO,       SZNO

	optbln	'trapt',    ~trapcc,	$50F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapf',    ~trapcc,	$51F8,		C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbln	'traphi',   ~trapcc,	$52F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapls',   ~trapcc,	$53F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapcc',   ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'traphs',   ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapcs',   ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'traplo',   ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapne',   ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnz',   ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapeq',   ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapze',   ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapvc',   ~trapcc,	$58F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapvs',   ~trapcc,	$59F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trappl',   ~trapcc,	$5AF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapmi',   ~trapcc,	$5BF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapge',   ~trapcc,	$5CF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'traplt',   ~trapcc,	$5DF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapgt',   ~trapcc,	$5EF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'traple',   ~trapcc,	$5FF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO

	optbln	'trapnf',   ~trapcc,	$50F8,		C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbln	'trapnt',   ~trapcc,	$51F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnls',  ~trapcc,	$52F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnhi',  ~trapcc,	$53F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapncs',  ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnlo',  ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapncc',  ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnhs',  ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapneq',  ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnze',  ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnne',  ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnnz',  ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnvs',  ~trapcc,	$58F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnvc',  ~trapcc,	$59F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnmi',  ~trapcc,	$5AF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnpl',  ~trapcc,	$5BF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnlt',  ~trapcc,	$5CF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnge',  ~trapcc,	$5DF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapnle',  ~trapcc,	$5EF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'trapngt',  ~trapcc,	$5FF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO

	optbln	'tpt',    ~trapcc,	$50F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpf',    ~trapcc,	$51F8,		C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbln	'tphi',   ~trapcc,	$52F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpls',   ~trapcc,	$53F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpcc',   ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tphs',   ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpcs',   ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tplo',   ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpne',   ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnz',   ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpeq',   ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpze',   ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpvc',   ~trapcc,	$58F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpvs',   ~trapcc,	$59F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tppl',   ~trapcc,	$5AF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpmi',   ~trapcc,	$5BF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpge',   ~trapcc,	$5CF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tplt',   ~trapcc,	$5DF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpgt',   ~trapcc,	$5EF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tple',   ~trapcc,	$5FF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnf',   ~trapcc,	$50F8,		C020|C030|C040|C060|C520|C530|C540,    SZW|SZL,    SZW|SZL
	optbln	'tpnt',   ~trapcc,	$51F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnls',  ~trapcc,	$52F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnhi',  ~trapcc,	$53F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpncs',  ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnlo',  ~trapcc,	$54F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpncc',  ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnhs',  ~trapcc,	$55F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpneq',  ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnze',  ~trapcc,	$56F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnne',  ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnnz',  ~trapcc,	$57F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnvs',  ~trapcc,	$58F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnvc',  ~trapcc,	$59F8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnmi',  ~trapcc,	$5AF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnpl',  ~trapcc,	$5BF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnlt',  ~trapcc,	$5CF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnge',  ~trapcc,	$5DF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpnle',  ~trapcc,	$5EF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO
	optbln	'tpngt',  ~trapcc,	$5FF8,		C020|C030|C040|C060,                   SZW|SZL,SZNO

	optbl	'callm',    ~callm,	$06C0,		C020,			           SZNO,       SZNO
	optbl	'rtm',	    ~rtm,	$06C0,		C020,			           SZNO,       SZNO

	optbl	'move16',   ~move16,	$F600,			  C040|C060,               SZNO,       SZNO
;GASコード
;	optbl	'mov16',    ~move16,	$F600,			  C040|C060,               SZNO,       SZNO

	optbl	'dec',	    ~decinc,	$5300,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL
	optbl	'inc',	    ~decinc,	$5200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL,SZB|SZW|SZL

	optbl	'jbra',	    ~jbcc,	$6000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbt',	    ~jbcc,	$6000,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbsr',	    ~jbcc,	$6100,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbhi',	    ~jbcc,	$6200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbls',	    ~jbcc,	$6300,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbcc',	    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbhs',	    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbcs',	    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jblo',	    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbne',	    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnz',	    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbeq',	    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbze',	    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbvc',	    ~jbcc,	$6800,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbvs',	    ~jbcc,	$6900,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbpl',	    ~jbcc,	$6A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbmi',	    ~jbcc,	$6B00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbge',	    ~jbcc,	$6C00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jblt',	    ~jbcc,	$6D00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbgt',	    ~jbcc,	$6E00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jble',	    ~jbcc,	$6F00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnls',    ~jbcc,	$6200,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnhi',    ~jbcc,	$6300,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbncs',    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnlo',    ~jbcc,	$6400,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbncc',    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnhs',    ~jbcc,	$6500,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbneq',    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnze',    ~jbcc,	$6600,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnne',    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnnz',    ~jbcc,	$6700,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnvs',    ~jbcc,	$6800,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnvc',    ~jbcc,	$6900,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnmi',    ~jbcc,	$6A00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnpl',    ~jbcc,	$6B00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnlt',    ~jbcc,	$6C00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnge',    ~jbcc,	$6D00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbnle',    ~jbcc,	$6E00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS
	optbl	'jbngt',    ~jbcc,	$6F00,C000|C010|C020|C030|C040|C060|C520|C530|C540,SZB|SZW|SZL|SZS,SZB|SZW|SZL|SZS

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

	pstbl	'rdata',    ~~rdata
	pstbl	'rbss',     ~~rbss
	pstbl	'rstack',   ~~rstack
	pstbl	'rcomm',    ~~rcomm
	pstbl	'rldata',   ~~rldata
	pstbl	'rlbss',    ~~rlbss
	pstbl	'rlstack',  ~~rlstack
	pstbl	'rlcomm',   ~~rlcomm

	pstbl	'68000',    ~~cpu_68000
	pstbl	'68010',    ~~cpu_68010
	pstbl	'68020',    ~~cpu_68020
	pstbl	'68030',    ~~cpu_68030
	pstbl	'68040',    ~~cpu_68040
	pstbl	'68060',    ~~cpu_68060
	pstbl	'5200',     ~~cpu_5200
	pstbl	'5300',     ~~cpu_5300
	pstbl	'5400',     ~~cpu_5400

	pstbl	'fpid',	    ~~fpid
	pstbl	'pragma',   ~~pragma
	pstbls	'fequ',     ~~fequ,		    SZS|SZD|SZX|SZP
	pstbls	'fset',     ~~fset,		    SZS|SZD|SZX|SZP


	optbl	'fmove',    ~fmove,	$0000,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
;GASコード追加
;	optbl	'fmov',	    ~fmove,	$0000,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fint',     ~fint,	$0001,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsinh',    ~funarys,	$0002,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fintrz',   ~fint,	$0003,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsqrt',    ~funary,	$0004,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'flognp1',  ~funarys,	$0006,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fetoxm1',  ~funarys,	$0008,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'ftanh',    ~funarys,	$0009,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fatan',    ~funarys,	$000A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fasin',    ~funarys,	$000C,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fatanh',   ~funarys,	$000D,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsin',     ~funarys,	$000E,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'ftan',     ~funarys,	$000F,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fetox',    ~funarys,	$0010,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'ftwotox',  ~funarys,	$0011,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'ftentox',  ~funarys,	$0012,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'flogn',    ~funarys,	$0014,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'flog10',   ~funarys,	$0015,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'flog2',    ~funarys,	$0016,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fabs',     ~fabsneg,	$0018,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fcosh',    ~funarys,	$0019,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fneg',     ~fabsneg,	$001A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'facos',    ~funarys,	$001C,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fcos',     ~funarys,	$001D,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fgetexp',  ~funarys,	$001E,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fgetman',  ~funarys,	$001F,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO

	optbl	'ftst',     ~ftst,	$003A,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fcmp',     ~fcmp,	$0038,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO

	optbl	'fdiv',     ~fopr,	$0020,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fmod',     ~fopr,	$0021,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fadd',     ~fopr,	$0022,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fmul',     ~fopr,	$0023,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsgldiv',  ~fsgl,	$0024,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'frem',     ~fopr,	$0025,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fscale',   ~fopr,	$0026,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsglmul',  ~fsgl,	$0027,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsub',     ~fopr,	$0028,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO

	optbl	'fssqrt',   ~funary,	$0041,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdsqrt',   ~funary,	$0045,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsabs',    ~funary,	$0058,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdabs',    ~funary,	$005C,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsneg',    ~funary,	$005A,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdneg',    ~funary,	$005E,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsmove',   ~fopr,	$0040,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdmove',   ~fopr,	$0044,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsdiv',    ~fopr,	$0060,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fddiv',    ~fopr,	$0064,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsadd',    ~fopr,	$0062,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdadd',    ~fopr,	$0066,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fsmul',    ~fopr,	$0063,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdmul',    ~fopr,	$0067,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fssub',    ~fopr,	$0068,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fdsub',    ~fopr,	$006C,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
;GASコード
;	optbl	'fsmov',    ~fopr,	$0040,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
;	optbl	'fdmov',    ~fopr,	$0044,C040|C060,	SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO

	optbl	'fsincos',  ~fsincos,	$0030,C040|C060|CFPP,SZB|SZW|SZL|SZS|SZD|SZX|SZP,SZNO
	optbl	'fmovecr',  ~fmovecr,	$5C00,C040|C060|CFPP,		    SZX,SZNO
	optbl	'fmovem',   ~fmovem,	$C000,C040|C060|CFPP,		SZL|SZX,SZNO
	optbln	'fnop',     ~fnop,	$F080,C040|C060|CFPP,SZNO,              SZNO
	optbl	'fsave',    ~fsave,	$F100,C040|C060|CFPP,SZNO,              SZNO
	optbl	'frestore', ~frestore,	$F140,C040|C060|CFPP,SZNO,              SZNO
;GASコード
;	optbl	'fmovcr',   ~fmovecr,	$5C00,C040|C060|CFPP,		    SZX,SZNO
;	optbl	'fmovm',    ~fmovem,	$C000,C040|C060|CFPP,		SZL|SZX,SZNO

	optbl	'fbf',	    ~fbcc,	$F080,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbeq',     ~fbcc,	$F081,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbogt',    ~fbcc,	$F082,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fboge',    ~fbcc,	$F083,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbolt',    ~fbcc,	$F084,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbole',    ~fbcc,	$F085,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbogl',    ~fbcc,	$F086,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbor',     ~fbcc,	$F087,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbun',     ~fbcc,	$F088,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbueq',    ~fbcc,	$F089,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbugt',    ~fbcc,	$F08A,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbuge',    ~fbcc,	$F08B,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbult',    ~fbcc,	$F08C,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbule',    ~fbcc,	$F08D,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbne',     ~fbcc,	$F08E,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbt',	    ~fbcc,	$F08F,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbra',     ~fbcc,	$F08F,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbsf',     ~fbcc,	$F090,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbseq',    ~fbcc,	$F091,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbgt',     ~fbcc,	$F092,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbge',     ~fbcc,	$F093,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fblt',     ~fbcc,	$F094,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fble',     ~fbcc,	$F095,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbgl',     ~fbcc,	$F096,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbgle',    ~fbcc,	$F097,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbngle',   ~fbcc,	$F098,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbngl',    ~fbcc,	$F099,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbnle',    ~fbcc,	$F09A,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbnlt',    ~fbcc,	$F09B,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbnge',    ~fbcc,	$F09C,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbngt',    ~fbcc,	$F09D,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbsne',    ~fbcc,	$F09E,C040|C060|CFPP,    SZW|SZL,SZNO
	optbl	'fbst',     ~fbcc,	$F09F,C040|C060|CFPP,    SZW|SZL,SZNO

	optbl	'fdbf',     ~fdbcc,	$0000,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbra',    ~fdbcc,	$0000,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbeq',    ~fdbcc,	$0001,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbogt',   ~fdbcc,	$0002,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdboge',   ~fdbcc,	$0003,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbolt',   ~fdbcc,	$0004,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbole',   ~fdbcc,	$0005,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbogl',   ~fdbcc,	$0006,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbor',    ~fdbcc,	$0007,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbun',    ~fdbcc,	$0008,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbueq',   ~fdbcc,	$0009,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbugt',   ~fdbcc,	$000A,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbuge',   ~fdbcc,	$000B,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbult',   ~fdbcc,	$000C,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbule',   ~fdbcc,	$000D,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbne',    ~fdbcc,	$000E,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbt',     ~fdbcc,	$000F,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbsf',    ~fdbcc,	$0010,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbseq',   ~fdbcc,	$0011,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbgt',    ~fdbcc,	$0012,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbge',    ~fdbcc,	$0013,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdblt',    ~fdbcc,	$0014,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdble',    ~fdbcc,	$0015,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbgl',    ~fdbcc,	$0016,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbgle',   ~fdbcc,	$0017,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbngle',  ~fdbcc,	$0018,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbngl',   ~fdbcc,	$0019,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbnle',   ~fdbcc,	$001A,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbnlt',   ~fdbcc,	$001B,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbnge',   ~fdbcc,	$001C,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbngt',   ~fdbcc,	$001D,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbsne',   ~fdbcc,	$001E,C040|C060|CFPP,SZNO,       SZNO
	optbl	'fdbst',    ~fdbcc,	$001F,C040|C060|CFPP,SZNO,       SZNO

	optbl	'fsf',	    ~fscc,	$0000,C040|C060|CFPP,SZB,        SZNO
	optbl	'fseq',     ~fscc,	$0001,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsogt',    ~fscc,	$0002,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsoge',    ~fscc,	$0003,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsolt',    ~fscc,	$0004,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsole',    ~fscc,	$0005,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsogl',    ~fscc,	$0006,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsor',     ~fscc,	$0007,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsun',     ~fscc,	$0008,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsueq',    ~fscc,	$0009,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsugt',    ~fscc,	$000A,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsuge',    ~fscc,	$000B,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsult',    ~fscc,	$000C,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsule',    ~fscc,	$000D,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsne',     ~fscc,	$000E,C040|C060|CFPP,SZB,        SZNO
	optbl	'fst',	    ~fscc,	$000F,C040|C060|CFPP,SZB,        SZNO
	optbl	'fssf',     ~fscc,	$0010,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsseq',    ~fscc,	$0011,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsgt',     ~fscc,	$0012,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsge',     ~fscc,	$0013,C040|C060|CFPP,SZB,        SZNO
	optbl	'fslt',     ~fscc,	$0014,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsle',     ~fscc,	$0015,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsgl',     ~fscc,	$0016,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsgle',    ~fscc,	$0017,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsngle',   ~fscc,	$0018,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsngl',    ~fscc,	$0019,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsnle',    ~fscc,	$001A,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsnlt',    ~fscc,	$001B,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsnge',    ~fscc,	$001C,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsngt',    ~fscc,	$001D,C040|C060|CFPP,SZB,        SZNO
	optbl	'fssne',    ~fscc,	$001E,C040|C060|CFPP,SZB,        SZNO
	optbl	'fsst',     ~fscc,	$001F,C040|C060|CFPP,SZB,        SZNO

	optbln	'ftrapf',   ~ftrapcc,	$0000,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapeq',  ~ftrapcc,	$0001,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapogt', ~ftrapcc,	$0002,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapoge', ~ftrapcc,	$0003,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapolt', ~ftrapcc,	$0004,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapole', ~ftrapcc,	$0005,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapogl', ~ftrapcc,	$0006,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapor',  ~ftrapcc,	$0007,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapun',  ~ftrapcc,	$0008,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapueq', ~ftrapcc,	$0009,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapugt', ~ftrapcc,	$000A,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapuge', ~ftrapcc,	$000B,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapult', ~ftrapcc,	$000C,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapule', ~ftrapcc,	$000D,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapne',  ~ftrapcc,	$000E,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapt',   ~ftrapcc,	$000F,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapsf',  ~ftrapcc,	$0010,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapseq', ~ftrapcc,	$0011,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapgt',  ~ftrapcc,	$0012,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapge',  ~ftrapcc,	$0013,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftraplt',  ~ftrapcc,	$0014,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftraple',  ~ftrapcc,	$0015,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapgl',  ~ftrapcc,	$0016,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapgle', ~ftrapcc,	$0017,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapngle',~ftrapcc,	$0018,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapngl', ~ftrapcc,	$0019,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapnle', ~ftrapcc,	$001A,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapnlt', ~ftrapcc,	$001B,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapnge', ~ftrapcc,	$001C,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapngt', ~ftrapcc,	$001D,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapsne', ~ftrapcc,	$001E,C040|C060|CFPP,    SZW|SZL,SZNO
	optbln	'ftrapst',  ~ftrapcc,	$001F,C040|C060|CFPP,    SZW|SZL,SZNO

	optbl	'cinvl',    ~cinvpushlp,$F408,			  C040|C060,               SZNO,       SZNO
	optbl	'cinvp',    ~cinvpushlp,$F410,			  C040|C060,               SZNO,       SZNO
	optbl	'cinva',    ~cinvpusha, $F418,			  C040|C060,               SZNO,       SZNO
	optbl	'cpushl',   ~cinvpushlp,$F428,			  C040|C060|C520|C530|C540,SZNO,       SZNO
	optbl	'cpushp',   ~cinvpushlp,$F430,			  C040|C060,               SZNO,       SZNO
	optbl	'cpusha',   ~cinvpusha, $F438,			  C040|C060,               SZNO,       SZNO

	optbln	'pflusha',  ~pflusha,	$F518,CMMU|C030|C040|C060,               SZNO,       SZNO
	optbl	'pflush',   ~pflush,	$F508,CMMU|C030|C040|C060,               SZNO,       SZNO
	optbln	'pflushan', ~pflushan,	$F510,		C040|C060,               SZNO,       SZNO
	optbl	'pflushn',  ~pflushn,	$F500,		C040|C060,               SZNO,       SZNO

	optbl	'pflushs',  ~pflushs,	$3400,CMMU,		       SZNO,       SZNO
	optbl	'pflushr',  ~pflushr,	$A000,CMMU,		       SZNO,       SZNO

	optbl	'pmove',    ~pmove,	$0000,CMMU|C030,	  SZB|SZW|SZL|SZD|SZQ,SZNO
	optbl	'pmovefd',  ~pmovefd,	$0100,	   C030,	      SZW|SZL|SZQ,    SZNO
	optbl	'ploadr',   ~ploadwr,	$2200,CMMU|C030,	  SZNO,               SZNO
	optbl	'ploadw',   ~ploadwr,	$2000,CMMU|C030,	  SZNO,               SZNO
	optbl	'ptestw',   ~ptestwr,	$8000,CMMU|C030|C040,	  SZNO,               SZNO
	optbl	'ptestr',   ~ptestwr,	$8200,CMMU|C030|C040,	  SZNO,               SZNO
	optbl	'plpaw',    ~pflushn,	$F588,		     C060,SZNO,               SZNO
	optbl	'plpar',    ~pflushn,	$F5C8,		     C060,SZNO,               SZNO
	optbl	'psave',    ~psave,	$F100,CMMU,		  SZNO,               SZNO
	optbl	'prestore', ~prestore,	$F140,CMMU,		  SZNO,               SZNO
	optbl	'pvalid',   ~pvalid,	$2800,CMMU,			  SZL,        SZNO
;GASコード
;	optbl	'pmov',	    ~pmove,	$0000,CMMU|C030,	  SZB|SZW|SZL|SZD|SZQ,SZNO
;	optbl	'pmovfd',   ~pmovefd,	$0100,	   C030,	      SZW|SZL|SZQ,    SZNO

	optbl	'pbbs',     ~pbcc,	$F080,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbbc',     ~pbcc,	$F081,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbls',     ~pbcc,	$F082,CMMU,		      SZW|SZL,        SZNO
	optbl	'pblc',     ~pbcc,	$F083,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbss',     ~pbcc,	$F084,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbsc',     ~pbcc,	$F085,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbas',     ~pbcc,	$F086,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbac',     ~pbcc,	$F087,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbws',     ~pbcc,	$F088,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbwc',     ~pbcc,	$F089,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbis',     ~pbcc,	$F08A,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbic',     ~pbcc,	$F08B,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbgs',     ~pbcc,	$F08C,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbgc',     ~pbcc,	$F08D,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbcs',     ~pbcc,	$F08E,CMMU,		      SZW|SZL,        SZNO
	optbl	'pbcc',     ~pbcc,	$F08F,CMMU,		      SZW|SZL,        SZNO

	optbl	'pdbbs',    ~pdbcc,	$0000,CMMU,		      SZW,            SZNO
	optbl	'pdbbc',    ~pdbcc,	$0001,CMMU,		      SZW,            SZNO
	optbl	'pdbls',    ~pdbcc,	$0002,CMMU,		      SZW,            SZNO
	optbl	'pdblc',    ~pdbcc,	$0003,CMMU,		      SZW,            SZNO
	optbl	'pdbss',    ~pdbcc,	$0004,CMMU,		      SZW,            SZNO
	optbl	'pdbsc',    ~pdbcc,	$0005,CMMU,		      SZW,            SZNO
	optbl	'pdbas',    ~pdbcc,	$0006,CMMU,		      SZW,            SZNO
	optbl	'pdbac',    ~pdbcc,	$0007,CMMU,		      SZW,            SZNO
	optbl	'pdbws',    ~pdbcc,	$0008,CMMU,		      SZW,            SZNO
	optbl	'pdbwc',    ~pdbcc,	$0009,CMMU,		      SZW,            SZNO
	optbl	'pdbis',    ~pdbcc,	$000A,CMMU,		      SZW,            SZNO
	optbl	'pdbic',    ~pdbcc,	$000B,CMMU,		      SZW,            SZNO
	optbl	'pdbgs',    ~pdbcc,	$000C,CMMU,		      SZW,            SZNO
	optbl	'pdbgc',    ~pdbcc,	$000D,CMMU,		      SZW,            SZNO
	optbl	'pdbcs',    ~pdbcc,	$000E,CMMU,		      SZW,            SZNO
	optbl	'pdbcc',    ~pdbcc,	$000F,CMMU,		      SZW,            SZNO

	optbl	'psbs',     ~pscc,	$0000,CMMU,		  SZB,                SZNO
	optbl	'psbc',     ~pscc,	$0001,CMMU,		  SZB,                SZNO
	optbl	'psls',     ~pscc,	$0002,CMMU,		  SZB,                SZNO
	optbl	'pslc',     ~pscc,	$0003,CMMU,		  SZB,                SZNO
	optbl	'psss',     ~pscc,	$0004,CMMU,		  SZB,                SZNO
	optbl	'pssc',     ~pscc,	$0005,CMMU,		  SZB,                SZNO
	optbl	'psas',     ~pscc,	$0006,CMMU,		  SZB,                SZNO
	optbl	'psac',     ~pscc,	$0007,CMMU,		  SZB,                SZNO
	optbl	'psws',     ~pscc,	$0008,CMMU,		  SZB,                SZNO
	optbl	'pswc',     ~pscc,	$0009,CMMU,		  SZB,                SZNO
	optbl	'psis',     ~pscc,	$000A,CMMU,		  SZB,                SZNO
	optbl	'psic',     ~pscc,	$000B,CMMU,		  SZB,                SZNO
	optbl	'psgs',     ~pscc,	$000C,CMMU,		  SZB,                SZNO
	optbl	'psgc',     ~pscc,	$000D,CMMU,		  SZB,                SZNO
	optbl	'pscs',     ~pscc,	$000E,CMMU,		  SZB,                SZNO
	optbl	'pscc',     ~pscc,	$000F,CMMU,		  SZB,                SZNO

	optbln	'ptrapbs',  ~ptrapcc,	$0000,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapbc',  ~ptrapcc,	$0001,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapls',  ~ptrapcc,	$0002,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptraplc',  ~ptrapcc,	$0003,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapss',  ~ptrapcc,	$0004,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapsc',  ~ptrapcc,	$0005,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapas',  ~ptrapcc,	$0006,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapac',  ~ptrapcc,	$0007,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapws',  ~ptrapcc,	$0008,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapwc',  ~ptrapcc,	$0009,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapis',  ~ptrapcc,	$000A,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapic',  ~ptrapcc,	$000B,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapgs',  ~ptrapcc,	$000C,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapgc',  ~ptrapcc,	$000D,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapcs',  ~ptrapcc,	$000E,CMMU,		      SZW|SZL,        SZNO
	optbln	'ptrapcc',  ~ptrapcc,	$000F,CMMU,		      SZW|SZL,        SZNO

	.endm


;----------------------------------------------------------------
;	オペコード名
;----------------------------------------------------------------
optbl	.macro	opname,addr,opcode,arch,size,size2	;オペコードテーブル定義マクロ
	.dc.b	opname,0,0,((arch)>>8).and.$FF,(arch).and.$FF,(size).xor.$FF,(size2).xor.$FF
	.endm

optbln	.macro	opname,addr,opcode,arch,size,size2	;(オペランドなし命令用)
	.dc.b	opname,0,-1,((arch)>>8).and.$FF,(arch).and.$FF,(size).xor.$FF,(size2).xor.$FF
	.endm

pstbl	.macro	psname,addr		;疑似命令テーブル定義マクロ
	.dc.b	psname,0,0,0,0,SZNO.xor.$FF,SZNO.xor.$FF
	.endm

pstbls	.macro	psname,addr,size	;(サイズ付き疑似命令用)
	.dc.b	psname,0,0,0,0,(size).xor.$FF,(size).xor.$FF
	.endm

opcode_tbl::
	tablebody
	.dc.b	0
	.even


;----------------------------------------------------------------
;	アドレス・命令コード
;----------------------------------------------------------------
optbl	.macro	opname,addr,opcode,arch,size,size2	;オペコードテーブル定義マクロ
	.dc.w	opcode
	.dc.l	addr-(*)
	.endm

optbln	.macro	opname,addr,opcode,arch,size,size2	;(オペランドなし命令用)
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
