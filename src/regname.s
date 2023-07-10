;----------------------------------------------------------------
;	X68k High-speed Assembler
;		レジスタ名テーブル
;		< regname.s >
;
;	$Id: regname.s,v 1.7  1999  6/ 9(Wed) 21:05:13 M.Kamada Exp $
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
;	レジスタ名テーブル
;----------------------------------------------------------------
regtbl	.macro	regname,regcode,type
	.dc.b	regname,0,((type)>>8).and.$FF,(type).and.$FF,regcode
	.endm

reg_tbl::
	regtbl	'd0',	REG_D0,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd1',	REG_D1,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd2',	REG_D2,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd3',	REG_D3,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd4',	REG_D4,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd5',	REG_D5,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd6',	REG_D6,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'd7',	REG_D7,		C000|C010|C020|C030|C040|C060|C520|C530|C540

	regtbl	'a0',	REG_A0,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a1',	REG_A1,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a2',	REG_A2,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a3',	REG_A3,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a4',	REG_A4,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a5',	REG_A5,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a6',	REG_A6,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'a7',	REG_A7,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'sp',	REG_A7,		C000|C010|C020|C030|C040|C060|C520|C530|C540

	regtbl	'zpc',	REG_ZPC,		  C020|C030|C040|C060

	regtbl	'pc',	REG_PC,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'ccr',	REG_CCR,	C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'sr',	REG_SR,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'usp',	REG_USP,	C000|C010|C020|C030|C040|C060

	regtbl	'fp0',	REG_FP0,			    C040|C060|CFPP
	regtbl	'fp1',	REG_FP1,			    C040|C060|CFPP
	regtbl	'fp2',	REG_FP2,			    C040|C060|CFPP
	regtbl	'fp3',	REG_FP3,			    C040|C060|CFPP
	regtbl	'fp4',	REG_FP4,			    C040|C060|CFPP
	regtbl	'fp5',	REG_FP5,			    C040|C060|CFPP
	regtbl	'fp6',	REG_FP6,			    C040|C060|CFPP
	regtbl	'fp7',	REG_FP7,			    C040|C060|CFPP

	regtbl	'sfc',	REG_SFC,	     C010|C020|C030|C040|C060
	regtbl	'dfc',	REG_DFC,	     C010|C020|C030|C040|C060
	regtbl	'vbr',	REG_VBR,	     C010|C020|C030|C040|C060|C520|C530|C540

	regtbl	'msp',	REG_MSP,		  C020|C030|C040
	regtbl	'isp',	REG_ISP,		  C020|C030|C040
	regtbl	'cacr',	REG_CACR,		  C020|C030|C040|C060|C520|C530|C540
	regtbl	'caar',	REG_CAAR,		  C020|C030

	regtbl	'buscr',REG_BUSCR,				 C060
	regtbl	'pcr',	REG_PCR,				 C060

	regtbl	'fpcr',	REG_FPCR,			    C040|C060|CFPP
	regtbl	'fpsr',	REG_FPSR,			    C040|C060|CFPP
	regtbl	'fpiar',REG_FPIAR,			    C040|C060|CFPP

	regtbl	'r0',	REG_D0,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r1',	REG_D1,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r2',	REG_D2,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r3',	REG_D3,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r4',	REG_D4,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r5',	REG_D5,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r6',	REG_D6,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r7',	REG_D7,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r8',	REG_A0,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r9',	REG_A1,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r10',	REG_A2,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r11',	REG_A3,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r12',	REG_A4,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r13',	REG_A5,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r14',	REG_A6,		C000|C010|C020|C030|C040|C060|C520|C530|C540
	regtbl	'r15',	REG_A7,		C000|C010|C020|C030|C040|C060|C520|C530|C540

	regtbl	'zd0',	REG_ZD0,		  C020|C030|C040|C060
	regtbl	'zd1',	REG_ZD1,		  C020|C030|C040|C060
	regtbl	'zd2',	REG_ZD2,		  C020|C030|C040|C060
	regtbl	'zd3',	REG_ZD3,		  C020|C030|C040|C060
	regtbl	'zd4',	REG_ZD4,		  C020|C030|C040|C060
	regtbl	'zd5',	REG_ZD5,		  C020|C030|C040|C060
	regtbl	'zd6',	REG_ZD6,		  C020|C030|C040|C060
	regtbl	'zd7',	REG_ZD7,		  C020|C030|C040|C060
	regtbl	'za0',	REG_ZA0,		  C020|C030|C040|C060
	regtbl	'za1',	REG_ZA1,		  C020|C030|C040|C060
	regtbl	'za2',	REG_ZA2,		  C020|C030|C040|C060
	regtbl	'za3',	REG_ZA3,		  C020|C030|C040|C060
	regtbl	'za4',	REG_ZA4,		  C020|C030|C040|C060
	regtbl	'za5',	REG_ZA5,		  C020|C030|C040|C060
	regtbl	'za6',	REG_ZA6,		  C020|C030|C040|C060
	regtbl	'za7',	REG_ZA7,		  C020|C030|C040|C060
	regtbl	'zsp',	REG_ZA7,		  C020|C030|C040|C060
	regtbl	'zr0',	REG_ZD0,		  C020|C030|C040|C060
	regtbl	'zr1',	REG_ZD1,		  C020|C030|C040|C060
	regtbl	'zr2',	REG_ZD2,		  C020|C030|C040|C060
	regtbl	'zr3',	REG_ZD3,		  C020|C030|C040|C060
	regtbl	'zr4',	REG_ZD4,		  C020|C030|C040|C060
	regtbl	'zr5',	REG_ZD5,		  C020|C030|C040|C060
	regtbl	'zr6',	REG_ZD6,		  C020|C030|C040|C060
	regtbl	'zr7',	REG_ZD7,		  C020|C030|C040|C060
	regtbl	'zr8',	REG_ZA0,		  C020|C030|C040|C060
	regtbl	'zr9',	REG_ZA1,		  C020|C030|C040|C060
	regtbl	'zr10',	REG_ZA2,		  C020|C030|C040|C060
	regtbl	'zr11',	REG_ZA3,		  C020|C030|C040|C060
	regtbl	'zr12',	REG_ZA4,		  C020|C030|C040|C060
	regtbl	'zr13',	REG_ZA5,		  C020|C030|C040|C060
	regtbl	'zr14',	REG_ZA6,		  C020|C030|C040|C060
	regtbl	'zr15',	REG_ZA7,		  C020|C030|C040|C060

	regtbl	'opc',	REG_OPC,	C000|C010|C020|C030|C040|C060|C520|C530|C540

	regtbl	'crp',	REG_CRP,		       C030|CMMU
	regtbl	'srp',	REG_SRP,		       C030|C040|C060|CMMU
	regtbl	'tc',	REG_TC,			       C030|C040|C060|CMMU
	regtbl	'tcr',	REG_TC,					      C520|C530|C540
	regtbl	'tt0',	REG_TT0,		       C030
	regtbl	'tt1',	REG_TT1,		       C030
	regtbl	'mmusr',REG_MMUSR,		       C030|C040|CMMU
	regtbl	'psr',	REG_MMUSR,		       C030|C040|CMMU

	regtbl	'urp',	REG_URP,			    C040|C060
	regtbl	'itt0',	REG_ITT0,			    C040|C060
	regtbl	'itt1',	REG_ITT1,			    C040|C060
	regtbl	'dtt0',	REG_DTT0,			    C040|C060
	regtbl	'dtt1',	REG_DTT1,			    C040|C060
	regtbl	'acr0',	REG_ITT0,				      C520|C530|C540
	regtbl	'acr1',	REG_ITT1,				      C520|C530|C540
	regtbl	'acr2',	REG_DTT0,				      C520|C530|C540
	regtbl	'acr3',	REG_DTT1,				      C520|C530|C540
	regtbl	'rombar',	REG_ROMBAR,			      C520|C530|C540
	regtbl	'rambar',	REG_RAMBAR0,			      C520|C530|C540
	regtbl	'rambar0',	REG_RAMBAR0,			      C520|C530|C540
	regtbl	'rambar1',	REG_RAMBAR1,			      C520|C530|C540
	regtbl	'mbar',	REG_MBAR,				      C520|C530|C540
	regtbl	'acc',	REG_ACC,				      C520|C530|C540
	regtbl	'macsr',	REG_MACSR,			      C520|C530|C540
	regtbl	'mask',	REG_MASK,				      C520|C530|C540

	regtbl	'nc',	REG_NC,				    C040|C060
	regtbl	'dc',	REG_DC,				    C040|C060
	regtbl	'ic',	REG_IC,				    C040|C060
	regtbl	'bc',	REG_BC,				    C040|C060|C520|C530|C540

	regtbl	'drp',	REG_DRP,	CMMU
	regtbl	'cal',	REG_CAL,	CMMU
	regtbl	'val',	REG_VAL,	CMMU
	regtbl	'scc',	REG_SCC,	CMMU
	regtbl	'ac',	REG_AC,		CMMU
	regtbl	'pcsr',	REG_PCSR,	CMMU
	regtbl	'bad0',	REG_BAD0,	CMMU
	regtbl	'bad1',	REG_BAD1,	CMMU
	regtbl	'bad2',	REG_BAD2,	CMMU
	regtbl	'bad3',	REG_BAD3,	CMMU
	regtbl	'bad4',	REG_BAD4,	CMMU
	regtbl	'bad5',	REG_BAD5,	CMMU
	regtbl	'bad6',	REG_BAD6,	CMMU
	regtbl	'bad7',	REG_BAD7,	CMMU
	regtbl	'bac0',	REG_BAC0,	CMMU
	regtbl	'bac1',	REG_BAC1,	CMMU
	regtbl	'bac2',	REG_BAC2,	CMMU
	regtbl	'bac3',	REG_BAC3,	CMMU
	regtbl	'bac4',	REG_BAC4,	CMMU
	regtbl	'bac5',	REG_BAC5,	CMMU
	regtbl	'bac6',	REG_BAC6,	CMMU
	regtbl	'bac7',	REG_BAC7,	CMMU

	.dc.b	0


;----------------------------------------------------------------
;	演算子名テーブル
;----------------------------------------------------------------
opname_tbl::
	.dc.b	'neg',0		;$01	-
	.dc.b	'pos',0		;$02	+
	.dc.b	'not',0		;$03
	.dc.b	'high',0	;$04
	.dc.b	'low',0		;$05
	.dc.b	'highw',0	;$06
	.dc.b	'loww',0	;$07
	.dc.b	'nul',0		;$08
	.dc.b	'mul',0		;$09	*
	.dc.b	'div',0		;$0A	/
	.dc.b	'mod',0		;$0B
	.dc.b	'shr',0		;$0C	>>
	.dc.b	'shl',0		;$0D	<< .<<.
	.dc.b	'asr',0		;$0E	   .>>.
	.dc.b	'sub',0		;$0F	-
	.dc.b	'add',0		;$10	+
	.dc.b	'eq',0		;$11	=  ==
	.dc.b	'ne',0		;$12	<> !=
	.dc.b	'lt',0		;$13	<
	.dc.b	'le',0		;$14	<=
	.dc.b	'gt',0		;$15	>
	.dc.b	'ge',0		;$16	>=
	.dc.b	'slt',0		;$17	.<.
	.dc.b	'sle',0		;$18	.<=.
	.dc.b	'sgt',0		;$19	.>.
	.dc.b	'sge',0		;$1A	.>=.
	.dc.b	'and',0		;$1B	&
	.dc.b	'xor',0		;$1C	^ .eor.
	.dc.b	'or',0		;$1D	|

	.dc.b	'notb',0	;	.notb.
	.dc.b	'notw',0	;	.notw.

	.dc.b	'sizeof',0	;	.sizeof.
	.dc.b	'defined',0	;	.defined.

	.dc.b	'<<',0
	.dc.b	'>>',0
	.dc.b	'<=',0
	.dc.b	'>=',0
	.dc.b	'<',0
	.dc.b	'>',0
	.dc.b	'eor',0
	.dc.b	-1

opconv_tbl::
	.dc.b	OP_SHL,OP_ASR,OP_SLE,OP_SGE,OP_SLT,OP_SGT,OP_XOR
	.even


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;	$Log: regname.s,v $
;	Revision 1.7  1999  6/ 9(Wed) 21:05:13 M.Kamada
;	+85 演算子.notb./.notw.を追加
;
;	Revision 1.6  1999  2/28(Sun) 00:31:06 M.Kamada
;	+82 ColdFireのときCPUSHLがアセンブルできなかった
;
;	Revision 1.5  1999  2/27(Sat) 23:44:58 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.4  1999  2/23(Tue) 02:26:27 M.Kamada
;	+80 ColdFire対応
;	+80 .sizeof.と.defined.を追加
;
;	Revision 1.3  1996 11/13(Wed) 15:33:45 M.Kamada
;	+02 68060対応
;		BUSCRとPCRを追加
;
;	Revision 1.2  1994/03/05  12:20:52  nakamura
;	レジスタ名zd0～zd7,za0～za7,opcを追加
;
;	Revision 1.1  1994/02/13  14:17:46  nakamura
;	Initial revision
;
;
