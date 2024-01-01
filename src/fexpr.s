;----------------------------------------------------------------
;	X68k High-speed Assembler
;		浮動小数点演算
;		< fexpr.s >
;
;	$Id: fexpr.s,v 1.9  2016-01-01 12:00:00  M.Kamada Exp $
;
;		Copyright 1990-1994  by Y.Nakamura
;		          1997-2016  by M.Kamada
;		          2024       by TcbnErik
;----------------------------------------------------------------

	.include	has.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	浮動小数点式を計算する
;	in :a0 = コード化した式を指すポインタ / (CMDOPSIZE) = 結果のサイズ
;	out:d0:d1:d2 = 結果
calcfexpr::
	movem.l	d3-d7/a1,-(sp)
	bsr	calcfex_xoror		;式の値を得る(拡張精度実数で計算する)
	pea.l	(calcfexpr9,pc)
	move.b	(CMDOPSIZE,a6),d7	;結果を必要な精度に変換する
	cmpi.b	#SZ_SHORT,d7
	beq	xtos
	cmpi.b	#SZ_DOUBLE,d7
	beq	xtod
	cmpi.b	#SZ_PACKED,d7
	beq	xtop
	addq.l	#4,sp
	swap.w	d0			;(SZ_EXTEND)
	clr.w	d0
calcfexpr9:
	movem.l	(sp)+,d3-d7/a1
	rts

;----------------------------------------------------------------
calcfex_xoror:				;xor/or
	bsr	calcfex_and
calcfex_xoror1:
	move.w	(a0),d7
	move.w	#OP_XOR|OT_OPERATOR,d6
	cmp.w	d6,d7
	beq	calcfex_xoror3
	cmp.w	#'^'|OT_CHAR,d7
	beq	calcfex_xoror3
	move.w	#OP_OR|OT_OPERATOR,d6
	cmp.w	d6,d7
	beq	calcfex_xoror3
	cmp.w	#'|'|OT_CHAR,d7
	beq	calcfex_xoror3
	rts

calcfex_xoror3:
	lea.l	(calcfex_and,pc),a1
	bsr	calcfex_intop2
	bra	calcfex_xoror1

;----------------------------------------------------------------
calcfex_and:				;and
	bsr	calcfex_cmp
calcfex_and1:
	move.w	(a0),d7
	move.w	#OP_AND|OT_OPERATOR,d6
	cmp.w	d6,d7
	beq	calcfex_and3
	cmp.w	#'&'|OT_CHAR,d7
	beq	calcfex_and3
	rts

calcfex_and3:
	lea.l	(calcfex_cmp,pc),a1
	bsr	calcfex_intop2
	bra	calcfex_and1

;----------------------------------------------------------------
calcfex_cmp:				;比較
	bsr	calcfex_addsub
calcfex_cmp1:
	move.l	(a0),d6
	swap.w	d6
	move.w	d6,d7
	clr.b	d7			;and.w #$FF00,d7
	cmp.w	#OT_OPERATOR,d7
	bne	calcfex_cmp11
	cmp.b	#OP_EQ,d6
	blo	calcfex_cmp10
	cmp.b	#OP_SGE,d6
	bls	calcfex_cmp2
calcfex_cmp10:
	rts

calcfex_cmp11:
	move.l	d6,d7
	moveq.l	#OP_EQ,d6
	cmp.l	#('='|OT_CHAR)+(('='|OT_CHAR)<<16),d7
	beq	calcfex_cmp22
	cmp.w	#'='|OT_CHAR,d7
	beq	calcfex_cmp2
	moveq.l	#OP_NE,d6
	cmp.l	#('<'|OT_CHAR)+(('>'|OT_CHAR)<<16),d7
	beq	calcfex_cmp22
	cmp.l	#('!'|OT_CHAR)+(('='|OT_CHAR)<<16),d7
	beq	calcfex_cmp22
	moveq.l	#OP_LE,d6
	cmp.l	#('<'|OT_CHAR)+(('='|OT_CHAR)<<16),d7
	beq	calcfex_cmp22
	moveq.l	#OP_GE,d6
	cmp.l	#('>'|OT_CHAR)+(('='|OT_CHAR)<<16),d7
	beq	calcfex_cmp22
	moveq.l	#OP_LT,d6
	cmp.w	#'<'|OT_CHAR,d7
	beq	calcfex_cmp2
	moveq.l	#OP_GT,d6
	cmp.w	#'>'|OT_CHAR,d7
	beq	calcfex_cmp2
	rts

calcfex_cmp22:
	addq.l	#2,a0
calcfex_cmp2:
	lea.l	(calcfex_addsub,pc),a1
	bsr	calcfex_op2
	bra	calcfex_cmp1

;----------------------------------------------------------------
calcfex_addsub:				;加減算
	bsr	calcfex_muldiv
calcfex_addsub1:
	move.w	(a0),d7
	moveq.l	#OP_ADD,d6
	cmp.w	#'+'|OT_CHAR,d7
	beq	calcfex_addsub2
	moveq.l	#OP_SUB,d6
	cmp.w	#'-'|OT_CHAR,d7
	beq	calcfex_addsub2
	rts

calcfex_addsub2:
	lea.l	(calcfex_muldiv,pc),a1
	bsr	calcfex_op2
	bra	calcfex_addsub1

;----------------------------------------------------------------
calcfex_muldiv:				;乗除算
	bsr	calcfex_unary
calcfex_muldiv1:
	move.l	(a0),d6
	swap.w	d6
	move.w	d6,d7
	clr.b	d7			;and.w #$FF00,d7
	cmp.w	#OT_OPERATOR,d7
	bne	calcfex_muldiv11
.if 0
	cmp.b	#OP_MOD,d6
.else
	cmp.b	#OP_SHR,d6
.endif
	blo	calcfex_muldiv10
	cmp.b	#OP_ASR,d6
	bls	calcfex_muldiv3
calcfex_muldiv10:
	rts

calcfex_muldiv11:
	move.l	d6,d7
	moveq.l	#OP_MUL,d6
	cmp.w	#'*'|OT_CHAR,d7
	beq	calcfex_muldiv2
	moveq.l	#OP_DIV,d6
	cmp.w	#'/'|OT_CHAR,d7
	beq	calcfex_muldiv2
	moveq.l	#OP_SHR,d6
	cmp.l	#('>'|OT_CHAR)+(('>'|OT_CHAR)<<16),d7
	beq	calcfex_muldiv32
	moveq.l	#OP_SHL,d6
	cmp.l	#('<'|OT_CHAR)+(('<'|OT_CHAR)<<16),d7
	beq	calcfex_muldiv32
	rts

calcfex_muldiv22:
	addq.l	#2,a0
calcfex_muldiv2:
	lea.l	(calcfex_unary,pc),a1
	bsr	calcfex_op2
	bra	calcfex_muldiv1

calcfex_muldiv32:
	addq.l	#2,a0
calcfex_muldiv3:
	lea.l	(calcfex_unary,pc),a1
	bsr	calcfex_intop2
	bra	calcfex_muldiv1

;----------------------------------------------------------------
calcfex_unary:				;単項式
	move.w	(a0),d7
	cmp.w	#'-'|OT_CHAR,d7
	beq	calcfex_neg
	cmp.w	#'+'|OT_CHAR,d7
	beq	calcfex_prime0
	move.b	d7,d6
	clr.b	d7			;and.w #$FF00,d7
	cmp.w	#OT_OPERATOR,d7
	bne	calcfex_prime
	cmp.b	#OP_NOT,d6
	blo	calcfex_prime
	cmp.b	#OP_NUL,d6
	bls	calcfex_unary_intop1
	cmp.b	#OP_NOTB,d6
	blo	calcfex_prime
calcfex_unary_intop1:
	lea.l	(calcfex_prime,pc),a1
	bra	calcfex_intop1

calcfex_neg:
	pea.l	(xneg,pc)
;	bra	calcfex_prime0
;----------------------------------------------------------------
calcfex_prime0:
	addq.l	#2,a0
calcfex_prime:				;一次式
	move.w	(a0)+,d6
	cmp.w	#'('|OT_CHAR,d6
	beq	calcfex_paren
	move.w	d6,d7
	clr.b	d6			;and.w #$FF00,d6
	sub.w	d6,d7			;and.w #$00FF,d7
	cmp.w	#OT_REAL,d6
	beq	calcfex_real
	cmp.w	#OT_VALUEB,d6
	beq	calcfex_valueb
	cmp.w	#OT_VALUEW,d6
	beq	calcfex_valuew
	cmp.w	#OT_VALUE,d6
	beq	calcfex_value
	cmp.w	#OT_VALUEQ,d6
	beq	calcfex_valueq
	cmp.w	#OT_SYMBOL,d6
	beq	calcfex_symbol
	cmp.w	#OT_STR,d6
	bne	exprerr			;文字列でなければエラー
	tst.w	d7
	beq	exprerr			;ヌルストリング→エラー
	cmp.w	#4,d7
	bhi	exprerr			;4文字より長い→エラー
	subq.w	#1,d7
	moveq.l	#0,d0			;文字列
calcfex_str:
	asl.l	#8,d0
	move.b	(a0)+,d0
	dbra	d7,calcfex_str
	move.l	a0,d1
	doeven	d1
	movea.l	d1,a0
	bsr	ltox
	bra	calcfex_size

calcfex_real:				;浮動小数点実数値
	move.w	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	bra	calcfex_size

calcfex_valueq:
	move.l	(a0)+,d1		;上位32bit
	move.l	(a0)+,d0		;下位32bit
	bsr	qtox
	bra	calcfex_size

calcfex_value:				;数値
	move.l	(a0)+,d0
	bsr	ltox
	bra	calcfex_size

calcfex_valuew:
	moveq.l	#0,d0
	move.w	(a0)+,d0
	bsr	ltox
	bra	calcfex_size

calcfex_valueb:
	moveq.l	#0,d0
	move.b	d7,d0
	bsr	ltox
	bra	calcfex_size

calcfex_symbol:				;シンボル
	movea.l	(a0)+,a1
	cmpi.b	#ST_REAL,(SYM_TYPE,a1)	;浮動小数点実数シンボル
	beq	calcfex_symreal
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a1)	;(ST_VALUE or ST_LOCAL)
	bhi	exprerr
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	blo	exprerr			;値が定まっていない
	tst.b	(SYM_SECTION,a1)	;(cmpi.b #SECT_ABS,(SYM_SECTION,a1))
	bne	exprerr			;定数でない
	move.l	(SYM_VALUE,a1),d0
	bsr	ltox
	bra	calcfex_size

calcfex_symreal:
	move.b	(SYM_FSIZE,a1),d7	;シンボルのサイズ
	bmi	calcfex_symreal01	;シンボルが定義されていない
	move.l	(SYM_FVPTR,a1),a1	;シンボル値へのポインタ
	movem.l	(a1),d0-d2		;シンボル値を得る
	subq.b	#SZ_SINGLE,d7
	beq	calcfex_symreal_single
	subq.b	#SZ_DOUBLE-SZ_SINGLE,d7
	beq	calcfex_symreal_double
	subq.b	#SZ_PACKED-SZ_DOUBLE,d7
	beq	calcfex_symreal_packed
	swap.w	d0
	bsr	normalize
	bra	calcfex_size

calcfex_symreal01:
;ここでは(SYM_TYPE,a1)=ST_REALなのでローカルシンボルは考えなくてよい
	move.l	a1,(ERRMESSYM,a6)
	bra	undefsymerr

calcfex_symreal_single:
	bsr	stox
	bra	calcfex_size

calcfex_symreal_double:
	bsr	dtox
	bra	calcfex_size

calcfex_symreal_packed:
	bsr	ptox
	bra	calcfex_size

calcfex_paren:
	bsr	calcfex_xoror
	cmpi.w	#')'|OT_CHAR,(a0)+
	bne	exprerr			;括弧が閉じていない
;サイズ指定を処理する
calcfex_size:
	cmpi.b	#OT_SIZE>>8,(a0)
	beq	calcfex_size_0		;サイズ指定あり
calcfex_size_extend:			;何もしない
	rts

calcfex_size_0:
	move.w	(a0)+,d6
	subq.b	#SZ_WORD,d6
	bcs	calcfex_size_byte
	beq	calcfex_size_word
	subq.b	#SZ_SHORT-SZ_WORD,d6
	bcs	calcfex_size_long
;	beq	calcfex_size_single
	subq.b	#SZ_DOUBLE-SZ_SHORT,d6
	bcs	calcfex_size_single
	beq	calcfex_size_double
	subq.b	#SZ_PACKED-SZ_DOUBLE,d6
	bcs	calcfex_size_extend
	beq	calcfex_size_packed
;.qの処理
calcfex_size_quad:
	bsr	calcfex_size_int
	cmp.w	#63,d6
	bgt	overflowerr		;絶対値が2^64以上
	beq	calcfex_size_int_max
	rts

;.lの処理
calcfex_size_long:
	bsr	calcfex_size_int
	cmp.w	#31,d6
	bgt	overflowerr		;絶対値が2^32以上
	beq	calcfex_size_int_max
	rts

;.wの処理
calcfex_size_word:
	bsr	calcfex_size_int
	cmp.w	#15,d6
	bgt	overflowerr		;絶対値が2^16以上
	beq	calcfex_size_int_max
	rts

;.bの処理
calcfex_size_byte:
	bsr	calcfex_size_int
	cmp.w	#7,d6
	bgt	overflowerr		;絶対値が2^8以上
	beq	calcfex_size_int_max
	rts

calcfex_size_int_max:
	tst.w	d0
	bpl	overflowerr		;2^63以上
	tst.l	d2
	bne	overflowerr		;-2^63未満
	cmp.l	#$80000000,d1
	bne	overflowerr		;-2^63未満
	rts

;整数に丸める
;	アンダーフローは0
;	INFやNANはエラー
;<d0.w:d1.l:d2.l:拡張精度浮動小数点数
;>d6.w:指数部(ベースは0,仮数部の符号は含まず)
calcfex_size_int:
	move.w	d0,d6
	and.w	#$7FFF,d6
	sub.w	#$3FFF,d6		;小数点の位置
	bsr	calcfex_rn		;整数に丸める
	move.w	d0,d6			;丸めた後の指数部をテストしなければならない
					;(丸めた結果1になったり整数範囲内にぎりぎり
					;入り切る数を許すため)
	and.w	#$7FFF,d6
	cmp.w	#$7FFF,d6
	beq	calcfex_size_int_error	;INFかNAN
	sub.w	#$3FFF,d6
	bpl	calcfex_size_int_done	;絶対値が1以上(上限はチェックしない)
	addq.l	#4,sp			;calcfex_size_{quad/long/word/byte}から抜ける
	and.w	#$8000,d0		;アンダーフロー(非正規化数を含む)
	moveq.l	#0,d1
	moveq.l	#0,d2
calcfex_size_int_done:
	rts

calcfex_size_int_error:
	tst.l	d1
	bne	ilvalueerr		;NANは整数化できない
	tst.l	d2
	bne	ilvalueerr		;NANは整数化できない
	bra	overflowerr		;INFならオーバーフロー

;.dの処理
calcfex_size_double:
	moveq.l	#52,d6			;小数点以下52ビットまで(53ビット目を0捨1入する)
	move.w	d0,d7
	and.w	#$7FFF,d7
	sub.w	#$3FFF-$3FE,d7
	bpl	calcfex_size_double_0
	add.w	d7,d6			;非正規化数の場合はビット数を減らす
					;非正規化数以下ならば負数が指定される
calcfex_size_double_0:
	bsr	calcfex_rn
	move.w	d0,d6
	and.w	#$7FFF,d6
	cmp.w	#$3FFF+$3FF,d6
	bhi	calcfex_size_real_inf
	rts				;非正規化数以下はcalcfex_rnで0になっており,
					;0捨1入で指数部が減ることはないので,
					;ここではアンダーフローや0をチェックしなくてよい

;.sの処理
calcfex_size_single:
	moveq.l	#23,d6			;小数点以下23ビットまで(24ビット目を0捨1入する)
	move.w	d0,d7
	and.w	#$7FFF,d7
	sub.w	#$3FFF-$7E,d7
	bpl	calcfex_size_single_0
	add.w	d7,d6			;非正規化数の場合はビット数を減らす
					;非正規化数以下ならば負数が指定される
calcfex_size_single_0:
	bsr	calcfex_rn
	move.w	d0,d6
	and.w	#$7FFF,d6
	cmp.w	#$3FFF+$7F,d6
	bhi	calcfex_size_real_inf
	rts				;非正規化数以下はcalcfex_rnで0になっており,
					;0捨1入で指数部が減ることはないので,
					;ここではアンダーフローや0をチェックしなくてよい

;doubleやsingleへの変換でオーバーフローするとき
;エラーは出さない
calcfex_size_real_inf:
	or.w	#$7FFF,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	rts

;.pの処理
calcfex_size_packed:
	bsr	xtop
	bra	ptox

;拡張精度実数をRounding Nearestで丸める
;<d0.w:d1.l:d2.l:拡張精度実数
;<d6.w:仮数部の小数点以下何ビットのところで丸めるか
;	-1  0  1  2  28 29 30 31  32  33  34  60 61 62 ← d6.w
;	  31 30 29 …  2  1  0  31  30  29  …  2  1  0
;	 |         d1         ||            d2         |
;	整数ならば小数点の位置
;	この位置の右側から左側へ0捨1入する
;	この位置の右側が1000…のときは左の位が0になるように丸める
;>d0.w:d1.l:d2.l:結果
;?d6.l/d7.l
calcfex_rn::
	cmp.w	#$7FFF,d0
	bge	calcfex_rn_done		;INFとNANはそのまま
	cmp.w	#$FFFF,d0
	bcc	calcfex_rn_done		;INFとNANはそのまま
	cmp.w	#-1,d6			;指数部が-1でも1に繰り上がることがある
	blt	calcfex_rn_zero		;d1がすべて0.25以下(非正規化数を含む)
	moveq.l	#30,d7
	sub.w	d6,d7
;d7=0.5のビット(0～31)
;	31  30  29  28  2 1 0 -1  -2  -3  -4  -30 -31 -32 ← d7.w
;	  31  30  29  … 2 1 0  31  30  29  …   2   1   0
;	 |            d1      ||            d2            |
	bmi	calcfex_rn_1		;0.5のビットがd2側にある
;0.5のビットがd1にある
;d7=0.5のビット(0～31)
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビット(0～31)
;d6=0.5のビットだけセット
	btst.l	d7,d1			;0.5のビットをテスト
	bne	calcfex_rn_2		;0.5のビットが立っている
;0.5のビットがd1側にあり0.5のビットが立っていないので切り捨てる
;d6=0.5のビットだけセット
	moveq.l	#0,d2
;0.5のビットがd1側にあり小数部が0.5で1のビットが0なので切り捨てる
;繰り上げたが仮数部が溢れなかった
;d2=0
;d6=0.5のビットだけセット
calcfex_rn_5:
	neg.l	d6			;0.5以上のマスク
	add.l	d6,d6			;1以上のマスク(0のことがある)
	beq	calcfex_rn_zero
	and.l	d6,d1
calcfex_rn_done:
	rts

;0.5のビットがd2側にある
;d7=0.5のビット(0～31)
;	-1  -2  -3  -4  -30 -31 -32 ← d7.w
;	  31  30  29  …   2   1   0
;	 |            d2            |
calcfex_rn_1:
	add.w	#32,d7
;d7=0.5のビット(0～31)
;	31  30  29  28  2  1 0 ← d7.w
;	  31  30  29  …  2 1 0
;	 |            d2       |
	bmi	calcfex_rn_done		;0.5のビットがd2よりも右にあるので何もしない
;d7=0.5のビット(0～31)
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビットだけセット
;d6=0.5のビットだけセット
	btst.l	d7,d2			;0.5のビットをテスト
	bne	calcfex_rn_12		;0.5のビットが立っている
;0.5のビットがd2側にあり0.5のビットが立っていないので切り捨てる
;d6=0.5のビットだけセット
calcfex_rn_15:
	neg.l	d6			;0.5以上のマスク
	add.l	d6,d6			;1以上のマスク(0のことがある)
	and.l	d6,d2
	rts

;0またはアンダーフロー
calcfex_rn_zero:
	and.w	#$8000,d0		;符号だけ残す
	moveq.l	#0,d1
	moveq.l	#0,d2
	rts

;0.5のビットがd1側にあり0.5のビットが立っている
;d6=0.5のビットだけセット
;d7=0.5のビット(0～31)
calcfex_rn_2:
	tst.l	d2
	bne	calcfex_rn_3		;小数部が0.5ではないので繰り上げる
;d2=0
	subq.l	#1,d6			;0.25以下のマスク
	and.l	d1,d6			;0.25以下のビットが立っているか
	bne	calcfex_rn_7		;小数部が0.5ではないので繰り上げる
;0.5のビットがd1側にあり小数部が0.5なので0.5の丸めを行う
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビットだけセット
;d6=0.5のビットだけセット
	addq.b	#1,d7			;1のビット(1～32)
;d7=1のビット(0～31)
	cmp.b	#32,d7
	beq	calcfex_rn_zero		;1のビットがないので切り捨てたら0になる
	btst.l	d7,d1			;1のビットをテスト
	bne	calcfex_rn_4		;1のビットが1なので繰り上げる
;0.5のビットがd1側にあり小数部が0.5で1のビットが0なので切り捨てる
	bra	calcfex_rn_5

;0.5のビットがd2側にあり小数部が0.5で1のビットがd1側にある
;d7=32
calcfex_rn_18:
	btst.l	d7,d1			;1のビットをテスト
	bne	calcfex_rn_16		;1のビットが1なので繰り上げる
;0.5のビットがd2側にあり小数部が0.5で1のビットがd1側にあり1のビットが0なので切り捨てる
	moveq.l	#0,d2
	rts

;0.5のビットがd2側にあり0.5のビットが立っている
;d6=0.5のビットだけセット
;d7=0.5のビット(0～31)
calcfex_rn_12:
	subq.l	#1,d6			;0.25以下のマスク
	and.l	d2,d6			;0.25以下のビットが立っているか
	bne	calcfex_rn_17		;小数部が0.5ではないので繰り上げる
;0.5のビットがd2側にあり小数部が0.5なので0.5の丸めを行う
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビットだけセット
;d6=0.5のビットだけセット
	addq.b	#1,d7			;1のビット(1～32)
;d7=1のビット(1～32)
	cmp.b	#32,d7
	beq	calcfex_rn_18		;1のビットがd1側にある
	btst.l	d7,d2			;1のビットをテスト
	bne	calcfex_rn_14		;1のビットが1なので繰り上げる
	bra	calcfex_rn_15

;0.5のビットがd2側にあり0.5のビットが立っているが小数部が0.5ではないので繰り上げる
calcfex_rn_17:
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビットだけセット
;0.5のビットがd2側にあり小数部が0.5で1のビットが立っているので繰り上げる
;d6=0.5のビットだけセット
calcfex_rn_14:
	add.l	d6,d2			;繰り上げる
	bcc	calcfex_rn_15
;0.5のビットがd2側にあり繰り上げたらd2が溢れた
;0.5のビットがd2側にあり小数部が0.5で1のビットがd1側にあり1のビットが立っているので繰り上げる
calcfex_rn_16:
	moveq.l	#1,d6
;0.5のビットがd1側にあり0.5のビットが立っているが小数部が0.5ではないので繰り上げる
;d6=0.5のビットだけセット
calcfex_rn_3:
	moveq.l	#0,d2
	bra	calcfex_rn_4

;0.5のビットがd1側にあり0.5のビットが立っているが小数部が0.5ではないので繰り上げる
;d2=0
;d7=0.5のビット(0～31)
calcfex_rn_7:
	moveq.l	#0,d6
	bset.l	d7,d6			;0.5のビットだけセット
;0.5のビットがd1側にあり小数部が0.5で1のビットが1なので繰り上げる
;d2=0
;d6=0.5のビットだけセット
calcfex_rn_4:
	add.l	d6,d1			;繰り上げる
	bcc	calcfex_rn_5		;仮数部が溢れなかった
;0.5のビットがd1側にあり繰り上げたら仮数部が溢れた
;d2=0
	addq.w	#1,d0			;INFやNANは最初に除いてあるので,
					;指数部が溢れることはない
	cmp.w	#$7FFF,d0
	beq	calcfex_rn_overflow	;オーバーフローした
	cmp.w	#$FFFF,d0
	beq	calcfex_rn_overflow	;オーバーフローした
	moveq.l	#1,d1			;仮数部は%1000…になる
	ror.l	#1,d1
	rts

;オーバーフローした
;d0=$7FFFまたは$FFFF
;d2=0
calcfex_rn_overflow:
	moveq.l	#0,d1
	rts

;----------------------------------------------------------------
;単項整数演算
;<d6.b:演算子番号
;<a1.l:演算子の右側の式を計算するルーチンのアドレス
calcfex_intop1:
	addq.l	#2,a0
	move.b	d6,-(sp)
	jsr	(a1)
	bsr	xtol_overflow_check
	bra	calcfex_intop0

;二項整数演算
;<d6.b:演算子番号
;<a1.l:演算子の右側の式を計算するルーチンのアドレス
calcfex_intop2:
	addq.l	#2,a0
	bsr	xtol_overflow_check
	move.b	d6,-(sp)
	move.l	d0,-(sp)		;披演算数
	jsr	(a1)
	bsr	xtol_overflow_check
	move.l	d0,d1			;演算数
	move.l	(sp)+,d0
calcfex_intop0:
	clr.w	d6
	move.b	(sp)+,d6
	bsr	calcfex_opjmp
	bra	ltox

xtol_overflow_check:
	bsr	xtol
	tst.w	d1
	bmi	overflowerr
	rts

;二項演算
;<d6.b:演算子番号
;<a1.l:演算子の右側の式を計算するルーチンのアドレス
calcfex_op2:
	addq.l	#2,a0
	move.b	d6,-(sp)
	movem.l	d0-d2,-(sp)
	jsr	(a1)
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	movem.l	(sp)+,d0-d2
	clr.w	d6
	move.b	(sp)+,d6
calcfex_opjmp:
	add.w	d6,d6			;演算子番号*2
	move.w	(fexjp_tbl-2*OP_NOT,pc,d6.w),d6
	jmp	(fexjp_tbl,pc,d6.w)

fexjp_tbl:
	.dc.w	fex_not-fexjp_tbl	;.not.
	.dc.w	fex_high-fexjp_tbl	;.high.
	.dc.w	fex_low-fexjp_tbl	;.low.
	.dc.w	fex_highw-fexjp_tbl	;.highw.
	.dc.w	fex_loww-fexjp_tbl	;.loww.
	.dc.w	fex_nul-fexjp_tbl	;.nul.
	.dc.w	xmul-fexjp_tbl		;*	(二項演算子)
	.dc.w	xdiv-fexjp_tbl		;/
	.dc.w	-1			;.mod.
	.dc.w	fex_shr-fexjp_tbl	;.shr.(>>)
	.dc.w	fex_shl-fexjp_tbl	;.shl.(<<)
	.dc.w	fex_asr-fexjp_tbl	;.asr.
	.dc.w	xsub-fexjp_tbl		;-
	.dc.w	xadd-fexjp_tbl		;+
	.dc.w	fex_eq-fexjp_tbl	;.eq.(=,==)
	.dc.w	fex_ne-fexjp_tbl	;.ne.(<>,!=)
	.dc.w	fex_lt-fexjp_tbl	;.lt.(<)
	.dc.w	fex_le-fexjp_tbl	;.le.(<=)
	.dc.w	fex_gt-fexjp_tbl	;.gt.(>)
	.dc.w	fex_ge-fexjp_tbl	;.ge.(>=)
	.dc.w	fex_lt-fexjp_tbl	;.slt.
	.dc.w	fex_le-fexjp_tbl	;.sle.
	.dc.w	fex_gt-fexjp_tbl	;.sgt.
	.dc.w	fex_ge-fexjp_tbl	;.sge.
	.dc.w	fex_and-fexjp_tbl	;.and.(&)
	.dc.w	fex_xor-fexjp_tbl	;.xor.(^)
	.dc.w	fex_or-fexjp_tbl	;.or.(|)
	.dc.w	fex_notb-fexjp_tbl	;.notb.
	.dc.w	fex_notw-fexjp_tbl	;.notw.

fex_not:
	not.l	d0
	rts

fex_notb:
	not.b	d0
	bra	fex_low

fex_high:
	lsr.l	#8,d0
fex_low:
	and.l	#$000000FF,d0
	rts

fex_notw:
	not.w	d0
fex_loww:
	swap.w	d0
fex_highw:
	clr.w	d0
	swap.w	d0
	rts

fex_nul:
	moveq.l	#0,d0
	rts

fex_shr:
	lsr.l	d1,d0
	rts

fex_shl:
	lsl.l	d1,d0
	rts

fex_asr:
	asr.l	d1,d0
	rts

fex_eq:
	bsr	fex_cmp
	beq	fex_true
fex_false:
	moveq.l	#0,d0			;d0:d1:d2 = 0.0
	moveq.l	#0,d1
	moveq.l	#0,d2
	rts

fex_true:
	move.w	#$BFFF,d0		;d0:d1:d2 = -1.0
	move.l	#$80000000,d1
	moveq.l	#0,d2
	rts

fex_ne:
	bsr	fex_cmp
	bne	fex_true
	bra	fex_false

fex_lt:
	bsr	fex_cmp
	blo	fex_true
	bra	fex_false

fex_le:
	bsr	fex_cmp
	bls	fex_true
	bra	fex_false

fex_gt:
	bsr	fex_cmp
	bhi	fex_true
	bra	fex_false

fex_ge:
	bsr	fex_cmp
	bhs	fex_true
	bra	fex_false

fex_cmp:
	ext.l	d0			;符号を上位ワードへ
	ext.l	d3
	move.w	#$7FFF,d6
	and.w	d6,d0
	beq	fex_cmp_za		;(0または非正規化数)-?
fex_cmp1:
	cmp.w	d6,d0
	beq	fex_cmp_nia		;(INFまたはNAN)-?
fex_cmp2:
	and.w	d6,d3
	beq	fex_cmp_zb		;?-(0または非正規化数)
fex_cmp3:
	cmp.w	d6,d3
	beq	fex_cmp_nib		;?-(INFまたはNAN)
fex_cmp4:
;指数部の符号を除去する
;非正規化数は一時的に正規化されているので+$3FFFでは足りない
;INFが$7FFFになっているので+$8000よりも大きな数を加えてはならない
	add.w	#$8000,d0
	add.w	#$8000,d3
	tst.l	d0
	bmi	fex_cmp6		;負数-?
;正数-?
	tst.l	d3
	bmi	fex_cmp7		;正数-負数
;正数-正数
	cmp.w	d3,d0
	bne	fex_cmp59
	cmp.l	d4,d1
	bne	fex_cmp59
	cmp.l	d5,d2
fex_cmp59:
	rts

;負数-?
fex_cmp6:
	tst.l	d3
	bpl	fex_cmp8		;負数-正数
;負数-負数
	cmp.w	d0,d3
	bne	fex_cmp69
	cmp.l	d1,d4
	bne	fex_cmp69
	cmp.l	d2,d5
fex_cmp69:
	rts

;正数-負数
fex_cmp7:
	moveq.l	#1,d0
	rts

;負数-正数
fex_cmp8:
	moveq.l	#-1,d0
	rts

fex_cmp_za:				;(0または非正規化数)-?
	move.l	d1,d6
	or.l	d2,d6
	beq	fex_cmp1		;0-?
fex_cmp_za1:				;非正規化数を一時的に正規化する
	tst.l	d1
	bmi	fex_cmp1
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bra	fex_cmp_za1

fex_cmp_nia:				;(INFまたはNAN)-?
	add.l	d1,d1
	or.l	d2,d1
	bne	fex_cmp_nan		;NAN-?
	cmp.l	d3,d0			;符号つきで比較
	bne	fex_cmp2		;INF-?
	bra	fex_cmp_nan		;INF-INF=NANまたは(-INF)-(-INF)=NAN

fex_cmp_zb:				;?-(0または非正規化数)
	move.l	d4,d6
	or.l	d5,d6
	beq	fex_cmp3		;?-0
fex_cmp_zb1:				;非正規化数を一時的に正規化する
	tst.l	d4
	bmi	fex_cmp3
	subq.w	#1,d0
	add.l	d5,d5
	addx.l	d4,d4
	bra	fex_cmp_zb1

fex_cmp_nib:				;?-(INFまたはNAN)
	add.l	d4,d4
	or.l	d5,d4
	beq	fex_cmp4		;?-INF
;	bra	fex_cmp_nan		;?-NAN
fex_cmp_nan:
	move.w	#$7FFF,d0		;比較不能なのでNANを返す
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	addq.l	#4,sp			;true/falseを破棄
	rts

fex_and:
	and.l	d1,d0
	rts

fex_xor:
	eor.l	d1,d0
	rts

fex_or:
	or.l	d1,d0
	rts

;----------------------------------------------------------------
;	拡張精度実数演算ルーチン
;
;	d0: b31～b16	(未使用)
;	    b15		= 仮数部符号
;	    b14～b0	= 指数部
;	d1,d2		= 仮数部
;----------------------------------------------------------------

;----------------------------------------------------------------
;	浮動小数文字列を拡張精度実数に変換する
;	in :a0 = 変換文字列へのポインタ
;	out:d0:d1:d2 = 結果(d0.l=-1ならエラー)
strtox::
	move.l	a0,-(sp)
	movem.l	d3-d7/a1-a4,-(sp)
	suba.l	a4,a4			;最初の0の並びを除いた桁数。必要以上に桁数が多いと10の累乗の誤差がかさむので23桁目以降を0と見なす
	suba.l	a3,a3			;末尾の0の数。次の数字を加える前に掛ける10の指数-1
	bsr	getsign			;仮数部符号を得る
	move.w	d7,-(sp)
	moveq.l	#0,d6
	cmpi.b	#'.',(a0)
	bne	strtox1
	addq.l	#1,a0
	moveq.l	#-1,d6
	moveq.l	#$20,d7
	or.b	(a0),d7
	cmp.b	#'e',d7
	bne	strtox1
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	bra	strtox8

strtox1:
	bsr	getdigit		;最初の1桁を得る
	bmi	strtox99		;数値でなければエラー
	move.l	d7,d0
	beq	strtox101
	addq.l	#1,a4			;0でなければ桁数カウント開始
strtox101:
	bsr	ltox
	bra	strtox3

strtox2:
	tst.l	d7
	bne	strtox21		;次の数字は0ではない
;次の数字は0
	cmpa.l	#0,a4
	beq	strtox201		;0以外の数字が出てきていない
	addq.l	#1,a4			;最初の0の並びを除いた桁数
strtox201:
	addq.l	#1,a3			;末尾の0の数
	bra	strtox22

;次の数字は0ではない
strtox21:
	addq.l	#1,a4			;最初の0の並びを除いた桁数
	cmpa.l	#23,a4
	bcc	strtox201		;23桁目以降を0と見なす
	movem.l	d0-d2,-(sp)
	move.w	#$3FFF,d0
	move.l	#$80000000,d1
	moveq.l	#0,d2
	lea.l	(decexptblp+2*12,pc),a1
	lea.l	(decmantblp+8*12,pc),a2
	move.l	a3,d3
	addq.l	#1,d3
strtox211:
	lsr.l	#1,d3
	movea.l	d3,a3
	bcc	strtox212
	move.w	(a1),d3
	movem.l	(a2),d4-d5
	bsr	xmul
strtox212:
	subq.l	#2,a1
	subq.l	#8,a2
	move.l	a3,d3
	bne	strtox211
;<d0-d2:10^(a3+1)
	suba.l	a3,a3
	movem.l	(sp)+,d3-d5
	bsr	xmul
	move.w	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	move.l	d7,d0
	bsr	ltox
	bsr	xadd
strtox22:
	tst.l	d6
	bpl	strtox3
	subq.w	#1,d6
strtox3:
	bsr	getdigit
	bpl	strtox2
	move.b	(a0),d7
	cmp.b	#'.',d7
	bne	strtox4
	tst.l	d6
	bmi	strtox9			;2つ目の小数点ならそこで終了する
	addq.l	#1,a0
	move.w	#-1,d6
	swap.w	d6
	bra	strtox3

strtox4:
	or.b	#$20,d7
	cmp.b	#'e',d7
	bne	strtox9			;指数部はない
strtox8:
	addq.l	#1,a0
	bsr	getsign			;指数部符号を得る
	move.w	d7,d3
	bsr	getdigit		;最初の1桁を得る
	bmi	strtox99		;数値でなければエラー
	move.w	d7,d4
	bra	strtox6

strtox5:
	add.w	d4,d4
	move.w	d4,d5
	add.w	d4,d4
	add.w	d4,d4
	add.w	d5,d4			;d4.l *= 10
	add.w	d7,d4
strtox6:
	bsr	getdigit
	bpl	strtox5
	tst.w	d3
	bmi	strtox7
	add.w	d4,d6			;指数部は正
	bra	strtox9

strtox7:
	sub.w	d4,d6			;指数部は負

strtox9:
	add.l	a3,d6			;末尾の0の数だけ戻す
	beq	strtox10		;指数部は0
	movem.l	d0-d2,-(sp)
	move.w	#$3FFF,d0
	move.l	#$80000000,d1
	moveq.l	#0,d2			;d0:d1:d2 = 1.0
	moveq.l	#13-1,d7
	lea.l	(decexptblp,pc),a1
	lea.l	(decmantblp,pc),a2
	tst.w	d6
	bmi	strtox_m
					;10進指数から10^nを得る
strtox_p:				;正の指数(1.0以上)の場合
	rol.w	#3-1,d6
strtox_p1:
	move.w	(a1)+,d3
	movem.l	(a2)+,d4-d5
	add.w	d6,d6
	bpl	strtox_p2
	bsr	xmul			;10の累乗を掛ける
strtox_p2:
	dbra	d7,strtox_p1
	movem.l	(sp)+,d3-d5		;仮数部
	bsr	xmul			;仮数部×(10^指数部)
	bra	strtox10

strtox_m:				;負の指数(1.0未満)の場合
	neg.w	d6
	rol.w	#3-1,d6
strtox_m1:
	move.w	(a1)+,d3
	movem.l	(a2)+,d4-d5
	add.w	d6,d6
	bpl	strtox_m2
	bsr	xmul			;10の累乗を掛ける
strtox_m2:
	dbra	d7,strtox_m1
	move.l	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	movem.l	(sp)+,d0-d2		;仮数部
	bsr	xdiv			;仮数部÷(10^指数部)

strtox10:
	tst.w	(sp)+
	bpl	strtox11
	or.w	#$8000,d0		;仮数部符号は負
strtox11:
	swap.w	d0
	clr.w	d0
	swap.w	d0
	movem.l	(sp)+,d3-d7/a1-a4
	addq.l	#4,sp			;スタック補正
	rts

strtox99:				;エラーの場合
	moveq.l	#-1,d0
	addq.l	#2,sp			;スタック補正
	movem.l	(sp)+,d3-d7/a1-a4
	movea.l	(sp)+,a0		;ポインタを元に戻す
	rts

;----------------------------------------------------------------
;	符号を得る
getsign:
	move.b	(a0),d7
	cmp.b	#'-',d7
	beq	getsignn
	cmp.b	#'+',d7
	bne	getsignp
	addq.l	#1,a0
getsignp:
	moveq.l	#0,d7
	rts

getsignn:
	addq.l	#1,a0
	moveq.l	#-1,d7
	rts

;----------------------------------------------------------------
;	数字を1桁得る
getdigit:
	moveq.l	#0,d7
	move.b	(a0)+,d7
	cmp.b	#'_',d7
	beq	getdigit
	sub.b	#'0',d7
	bcs	getdigit9
	cmp.b	#9,d7
	bhi	getdigit9
	tst.w	d7
	rts

getdigit9:
	subq.l	#1,a0
	moveq.l	#-1,d7
	rts

;----------------------------------------------------------------
;	符号を反転する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0:d1:d2 = 結果
xneg::
	bchg.l	#15,d0			;仮数部符号を反転する
	rts

;----------------------------------------------------------------
;	2数を比較する(A-B)
;	in :d0:d1:d2 = 拡張精度実数値A
;	    d3:d4:d5 = 拡張精度実数値B
;	out:ccr = 結果
xcmp::
	move.l	d6,-(sp)
	tst.w	d0
	bmi	xcmp_m			;A<0のとき
	tst.w	d3
	bmi	xcmp_hiz
	cmp.w	d3,d0
	bcs	xcmp_lo
	bhi	xcmp_hi
	cmp.l	d4,d1
	bcs	xcmp_lo
	bhi	xcmp_hi
	cmp.l	d5,d2
	bcs	xcmp_lo
	bhi	xcmp_hi
	move.w	#$0004,ccr		;A=B
	move.l	(sp)+,d6
	rts

xcmp_m:					;A>0のとき
	tst.w	d3
	bpl	xcmp_loz
	cmp.w	d3,d0
	bcs	xcmp_hi
	bhi	xcmp_lo
	cmp.l	d4,d1
	bcs	xcmp_hi
	bhi	xcmp_lo
	cmp.l	d5,d2
	bcs	xcmp_hi
	bhi	xcmp_lo
xcmp_eq:
	move.w	#$0004,ccr		;A=B
	move.l	(sp)+,d6
	rts

xcmp_hiz:
	move.w	d0,d6
	or.w	d3,d6
	and.w	#$7FFF,d6
	bne	xcmp_hi
	move.l	d1,d6
	or.l	d2,d6
	or.l	d4,d6
	or.l	d5,d6
	beq	xcmp_eq			;-0.0 == +0.0
xcmp_hi:
	move.w	#$0000,ccr		;A>B
	move.l	(sp)+,d6
	rts

xcmp_loz:
	move.w	d0,d6
	or.w	d3,d6
	and.w	#$7FFF,d6
	bne	xcmp_lo
	move.l	d1,d6
	or.l	d2,d6
	or.l	d4,d6
	or.l	d5,d6
	beq	xcmp_eq			;-0.0 == +0.0
xcmp_lo:
	move.w	#$0009,ccr		;A<B
	move.l	(sp)+,d6
	rts

;----------------------------------------------------------------
;	2数を減算する(A=A-B)
;	in :d0:d1:d2 = 拡張精度実数値A
;	    d3:d4:d5 = 拡張精度実数値B
;	out:d0:d1:d2 = 結果
xsub::
	movem.l	d3-d7,-(sp)
	bchg.l	#15,d3			;仮数部符号を反転する
	bra	xadd0			;A-B = A+(-B)

;----------------------------------------------------------------
;	2数を加算する(A=A+B)
;	in :d0:d1:d2 = 拡張精度実数値A
;	    d3:d4:d5 = 拡張精度実数値B
;	out:d0:d1:d2 = 結果
xadd::
	movem.l	d3-d7,-(sp)
xadd0:
	move.w	d0,d6
	eor.w	d3,d6
	swap.w	d6
	move.w	d0,d6
	move.w	#$7FFF,d7
	and.w	d7,d0
	beq	xadd_za			;A=0 or 非正規化数
	cmp.w	d7,d0
	beq	xadd_nia		;A=NAN or ±INF
xadd1:
	and.w	d7,d3
	beq	xadd_zb			;B=0 or 非正規化数
	cmp.w	d7,d3
	beq	xadd_nib		;B=NAN or ±INF
xadd2:
	tst.l	d6
	bmi	xadd_s			;AとBの符号が異なる(減算)

;----------------------------------------------------------------
;	符号の同じ数の加算
xadd_a:
	cmp.w	d3,d0
	beq	xadd_ae			;AとBの指数が同じ
	bgt	xadd_a1			;A>Bのとき(一時正規化数のため符号付き比較)
	exg.l	d0,d3			;A<Bなら2数を交換する
	exg.l	d1,d4
	exg.l	d2,d5
xadd_a1:
	add.l	d2,d2			;A <<= 1 (仮数部整数ビットを削除)
	addx.l	d1,d1
	move.w	d0,d7
	sub.w	d3,d7
	subq.w	#2,d7
	bcs	xadd_a5			;Aが1桁大きい
	cmp.w	#64-1,d7
	bcc	xadd_a6			;64桁以上大きければAをそのまま返す
xadd_a2:				;Aと小数点位置を合わせる
	lsr.l	#1,d4
	roxr.l	#1,d5
	dbra	d7,xadd_a2
xadd_a5:
	move.w	d5,d3
	lsr.w	#1,d3			;最下位ビットを取り出す(→X)
	addx.l	d5,d2			;A += B(Bの最下位ビットを丸める)
	addx.l	d4,d1
	bcc	xadd_a6			;桁上がりしていない
	addq.w	#1,d0			;指数が1桁増える
	cmp.w	#$7FFF,d0
	beq	xadd_infa		;オーバーフロー
	moveq.l	#0,d3
	lsr.l	#1,d1			;A /= 2
	roxr.l	#1,d2
	move.w	d2,d3			;最下位ビットを丸める
	and.w	#$0001,d3
	addx.l	d3,d2
	moveq.l	#0,d3
	addx.l	d3,d1
xadd_a6:
	move.w	#$0010,ccr		;X=1
	roxr.l	#1,d1			;結果の整数ビットを付け加える
	roxr.l	#1,d2			;(シフト前の最下位ビットは必ず0)
	bra	xadd_ae0		;一時正規化数なら正規化数に戻してAを返す

xadd_ae:				;AとBの指数が同じとき
	addq.w	#1,d0			;指数が1桁増える
	cmp.w	#$7FFF,d0
	beq	xadd_infa		;オーバーフロー
	add.l	d5,d2			;A += B
	addx.l	d4,d1			;(整数ビットが立っているので必ずキャリー)
	roxr.l	#1,d1			;A /= 2
	roxr.l	#1,d2
	moveq.l	#0,d3			;丸めを行う
	roxl.w	#1,d3			;シフトではみだした最下位ビット
	add.l	d3,d2			;最下位ビットを切り上げる(0捨1入)
	moveq.l	#0,d3
	addx.l	d3,d1
xadd_ae0:
	tst.w	d0
	bpl	xadd_ae5		;結果が正規化数の場合
xadd_ae1:				;一時正規化数を非正規化数に戻す
	addq.w	#1,d0
	lsr.l	#1,d1
	roxr.l	#1,d2
	tst.w	d0
	bne	xadd_ae1
	moveq.l	#0,d3			;丸めを行う
	roxl.w	#1,d3			;シフトではみだした最下位ビット
	add.l	d3,d2			;最下位ビットを切り上げる(0捨1入)
	moveq.l	#0,d3
	addx.l	d3,d1
xadd_ae5:
	tst.w	d6			;Aと同じ符号
	bpl	xadd_ae9
	or.w	#$8000,d0
xadd_ae9:
	movem.l	(sp)+,d3-d7
	rts

xadd_infa:				;INFになった(Aと同じ符号)
	tst.w	d6
	bpl	xadd_infa1
	or.w	#$8000,d0
xadd_infa1:
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

;----------------------------------------------------------------
;	符号の異なる数の加算
xadd_s:
	cmp.w	d3,d0
	beq	xadd_se			;AとBの指数が同じ
	bgt	xadd_s1			;A>Bのとき(一時正規化数のため符号付き比較)
	exg.l	d0,d3			;A<Bなら2数を交換して符号を反転する
	exg.l	d1,d4
	exg.l	d2,d5
	not.w	d6
xadd_s1:
	add.l	d2,d2			;A <<= 1	(仮数部整数ビットを削除)
	addx.l	d1,d1
	move.w	d0,d7
	sub.w	d3,d7
	subq.w	#2,d7
	bcs	xadd_s5			;Aが1桁大きい
	cmp.w	#64-1,d7
	bcc	xadd_s6			;64桁以上大きければAをそのまま返す
xadd_s2:				;Aと小数点位置を合わせる
	lsr.l	#1,d4
	roxr.l	#1,d5
	dbra	d7,xadd_s2
xadd_s5:
	move.w	d5,d3
	lsr.w	#1,d3			;最下位ビットを取り出す(→X)
	subx.l	d5,d2			;A -= B(Bの最下位ビットを丸める)
	subx.l	d4,d1
	bcc	xadd_s6			;桁下がりしていない
	subq.w	#1,d0			;指数が1桁減る
	bra	xadd_se1		;一時正規化数なら正規化数に戻してAを返す

xadd_s6:
	move.w	#$0010,ccr		;X=1
	roxr.l	#1,d1			;結果の整数ビットを付け加える
	roxr.l	#1,d2			;(シフト前の最下位ビットは必ず0)
	bra	xadd_se1		;一時正規化数なら正規化数に戻してAを返す

xadd_se:				;AとBの指数が同じとき
	sub.l	d5,d2			;A -= B
	subx.l	d4,d1
	bhi	xadd_se1
	neg.l	d2			;A<Bだったので符号を反転する
	negx.l	d1
	beq	xadd_sez		;結果が0になった
	not.w	d6
xadd_se1:
	tst.w	d0
	bmi	xadd_ae1		;一時正規化数を非正規化数に戻す
	beq	xadd_se5		;すでに正規化/非正規化されている
	tst.l	d1
	bmi	xadd_se5		;正規化されている
xadd_se2:
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bmi	xadd_se5		;正規化が終了した
	subq.w	#1,d3
	bne	xadd_se2		;指数部が0になったら正規化を中断する
xadd_se5:
	tst.w	d6			;Aと同じ符号
	bpl	xadd_se9
	or.w	#$8000,d0
xadd_se9:
	movem.l	(sp)+,d3-d7
	rts

xadd_sez:				;結果が0になった
	moveq.l	#0,d0			;+0.0
	movem.l	(sp)+,d3-d7
	rts

xadd_za:				;A=0 or 非正規化数
	move.l	d1,d7
	or.l	d2,d7
	bne	xadd_za1
	move.l	d3,d0			;0+B = B
	move.l	d4,d1
	move.l	d5,d2
	move.w	#$7FFF,d7
	and.w	d7,d3
	beq	xadd_z			;0+0 or 非正規化数
	cmp.w	d7,d3
	beq	xadd_nib		;0+NAN or 0+INF
	movem.l	(sp)+,d3-d7
	rts

xadd_z:
	or.l	d4,d3
	beq	xadd_z9			;0+0
	move.w	d6,d0			;0+非正規化数
	swap.w	d6
	eor.w	d6,d0
	and.w	#$8000,d0		;Bの符号
	movem.l	(sp)+,d3-d7
	rts

xadd_z9:				;0+0
	move.w	d6,d0			;(-0.0)+(-0.0)=-0.0
	swap.w	d6			;それ以外は +0.0
	not.w	d6
	and.w	d6,d0
	and.w	#$8000,d0
	movem.l	(sp)+,d3-d7
	rts

xadd_za1:				;非正規化数を一時的に正規化する
	move.w	#$7FFF,d7
xadd_za2:
	tst.l	d1
	bmi	xadd1
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bra	xadd_za2

xadd_nia:				;A=NAN or ±INF
	add.l	d1,d1
	or.l	d2,d1
	bne	xadd_n			;仮数部が0でないならNAN
	and.w	d7,d3			;Bの指数
	cmp.w	d7,d3
	bne	xadd_ni9		;INF+B = INF
	add.l	d4,d4
	or.l	d5,d4
	bne	xadd_n			;仮数部が0でないならNAN
	tst.l	d6
	bmi	xadd_n			;INF-INF = NAN	(AとBの符号が異なる)
xadd_ni9:				;Aをそのまま返す
	move.w	d6,d0
	movem.l	(sp)+,d3-d7
	rts

xadd_zb:				;B=0 or 非正規化数
	move.l	d4,d7
	or.l	d5,d7
	beq	xadd_ae0		;A+0 = Aを返す(一時正規化数なら非正規仮数に戻す)
xadd_zb1:				;非正規化数を一時的に正規化する
	tst.l	d4
	bmi	xadd2
	subq.w	#1,d3
	add.l	d5,d5
	addx.l	d4,d4
	bra	xadd_zb1

xadd_nib:				;B=NAN or ±INF
	add.l	d4,d4
	or.l	d5,d4
	bne	xadd_n			;仮数部が0でないならNAN
	move.l	(sp),d0			;A+INF = INF (Bの符号)
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

xadd_n:					;NANを返す
	move.w	#$7FFF,d0
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	movem.l	(sp)+,d3-d7
	rts

;----------------------------------------------------------------
;	2数を乗算する(A=A*B)
;	in :d0:d1:d2 = 拡張精度実数値A
;	    d3:d4:d5 = 拡張精度実数値B
;	out:d0:d1:d2 = 結果
xmul::
	movem.l	d3-d7,-(sp)
	move.w	d0,d6
	eor.w	d3,d6			;結果の符号
	move.w	#$7FFF,d7
	and.w	d7,d0
	beq	xmul_za			;A=0 or 非正規化数
	cmp.w	d7,d0
	beq	xmul_nia		;A=NAN or ±INF
xmul1:
	and.w	d7,d3
	beq	xmul_zb			;B=0 or 非正規化数
	cmp.w	d7,d3
	beq	xmul_nib		;B=NAN or ±INF
xmul2:
	movem.w	d0/d3/d6,-(sp)		;A1234 * B1234

;			A1  A2  A3  A4
;		     × B1  B2  B3  B4
;		    -------------------
;			        44H 44L
;			    34H 34L
;			24H 24L
;		    14H 14L 43H 43L
;			33H 33L
;		    23H 23L
;		13H 13L 42H 42L
;		    32H 32L
;		22H 22L
;	    12H 12L 41H 41L
;		31H 31L
;	    21H 21L
;	11H 11L
;	===d5== ===d6== =d7=

	move.w	d1,d7
	mulu.w	d5,d7			;A2*B4
	clr.w	d7
	swap.w	d7
	move.w	d2,d6			;24H
	mulu.w	d4,d6			;A4*B2
	clr.w	d6
	swap.w	d6
	add.l	d6,d7			;42H
	swap.w	d2			;A43
	move.l	d5,d6
	swap.w	d6
	mulu.w	d2,d6			;A3*B3
	clr.w	d6
	swap.w	d6
	add.l	d6,d7			;33H

	move.l	d1,d6
	swap.w	d6
	mulu.w	d5,d6			;A1*A4
	add.l	d6,d7			;14L
	move.l	d7,d6
	clr.w	d6
	addx.w	d6,d6			;14H(+桁上げ)
	swap.w	d6

	swap.w	d5
	move.w	d1,d3
	mulu.w	d5,d3			;A2*B3
	add.w	d3,d7			;23L
	clr.w	d3
	swap.w	d3
	addx.l	d3,d6			;23H(+桁上げ)

	move.w	d4,d3
	mulu.w	d2,d3			;A3*B2
	add.w	d3,d7			;32L
	clr.w	d3
	swap.w	d3
	addx.l	d3,d6			;32H(+桁上げ)

	move.l	d1,d3
	swap.w	d3
	mulu.w	d3,d5			;A1*B3
	mulu.w	d4,d3			;A1*B2
	move.w	d1,d0
	mulu.w	d4,d0			;A2*B2
	add.l	d5,d0			;13HL+22HL
	moveq.l	#0,d5
	addx.w	d5,d5			;(桁上げ)
	add.l	d0,d6
	move.l	d3,d0
	swap.w	d3
	clr.w	d0
	swap.w	d0
	addx.l	d0,d5			;12H(+桁上げ)

	swap.w	d4
	move.w	d2,d0
	swap.w	d2
	mulu.w	d4,d2			;A4*B1
	add.w	d2,d7			;41L
	swap.w	d2
	move.w	d2,d3
	addx.l	d3,d6			;12L:41H(+桁上げ)
	move.l	d1,d3
	swap.w	d3
	mulu.w	d4,d3			;A1*B1
	addx.l	d3,d5			;11HL(+桁上げ)

	mulu.w	d4,d0			;A3*B1
	add.l	d0,d6			;31HL
	moveq.l	#0,d3
	addx.l	d3,d5			;(桁上げ)

	mulu.w	d4,d1			;A2*B1
	swap.w	d1
	move.w	d1,d3
	clr.w	d1
	add.l	d1,d6			;21L
	addx.l	d3,d5			;21H(+桁上げ)

	move.l	d5,d1
	move.l	d6,d2
	movem.w	(sp)+,d0/d3/d6
	ext.l	d0			;(一時正規化数なら指数が負なので)
	ext.l	d3
	add.l	d3,d0			;指数を加える
	sub.l	#$3FFF-1,d0		;バイアスを引く
	tst.l	d1
	bmi	xmul5
	subq.l	#1,d0			;正規化する
	add.w	d7,d7
	roxl.l	#1,d2
	roxl.l	#1,d1
xmul5:
	tst.w	d7			;最下位ビットで丸めを行う
	bpl	xmul6
	moveq.l	#0,d3
	addq.l	#1,d2
	addx.l	d3,d1
	bcc	xmul6
	addq.l	#1,d0			;丸めで桁上がりした
	move.l	#$80000000,d1		;(結果は$80000000_00000000)
xmul6:
	cmp.w	#$7FFF,d0		;(ワード範囲に収まる)
	bcs	xmul8			;結果の指数が範囲内
	beq	xmul_i
	cmp.w	#-64,d0
	bgt	xmul7			;一時正規化数の範囲内
	tst.l	d0
	bmi	xmul_z			;値がアンダーフローした	→0
	bra	xmul_i			;  オーバーフロー	→INF

xmul7:					;一時正規化数を非正規化数に戻す
	addq.w	#1,d0
	lsr.l	#1,d1
	roxr.l	#1,d2
	tst.w	d0
	bne	xmul7
	moveq.l	#0,d3			;丸めを行う
	roxl.w	#1,d3			;シフトではみだした最下位ビット
	add.l	d3,d2			;最下位ビットを切り上げる(0捨1入)
	moveq.l	#0,d3
	addx.l	d3,d1
xmul8:
	tst.w	d6			;結果の符号
	bpl	xmul9
	or.w	#$8000,d0
xmul9:
	movem.l	(sp)+,d3-d7
	rts

xmul_za:				;A=0 or 非正規化数
	move.l	d1,d7
	or.l	d2,d7
	bne	xmul_za1		;非正規化数の場合
	move.w	#$7FFF,d7
	and.w	d7,d3
	cmp.w	d7,d3
	beq	xmul_n			;0*NAN or 0*INF = NAN
xmul_z:
	move.w	d6,d0			;0*B = 0
	and.w	#$8000,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

xmul_za1:				;非正規化数を一時的に正規化する
	move.w	#$7FFF,d7
xmul_za2:
	tst.l	d1
	bmi	xmul1
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bra	xmul_za2

xmul_nia:				;A=NAN or ±INF
	add.l	d1,d1
	or.l	d2,d1
	bne	xmul_n			;仮数部が0でないならNAN
	and.w	d7,d3			;Bの指数
	beq	xmul_nia1		;B=0 or 非正規化数
	cmp.w	d7,d3
	bne	xmul_i			;INF*B = INF
	add.l	d4,d4
	or.l	d5,d4
	bne	xmul_n			;仮数部が0でないならNAN
xmul_i:					;INFを返す
	move.w	d6,d0
	or.w	#$7FFF,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

xmul_nia1:				;B=0 or 非正規化数
	move.l	d4,d7
	or.l	d5,d7
	beq	xmul_n			;INF*0 = NAN
	bra	xmul_i			;INF*非正規化数 = INF

xmul_zb:				;B=0 or 非正規化数
	move.l	d4,d7
	or.l	d5,d7
	beq	xmul_z			;A*0 = 0
xmul_zb1:				;非正規化数を一時的に正規化する
	tst.l	d4
	bmi	xmul2
	subq.w	#1,d3
	add.l	d5,d5
	addx.l	d4,d4
	bra	xmul_zb1

xmul_nib:				;B=NAN or ±INF
	add.l	d4,d4
	or.l	d5,d4
	beq	xmul_i			;A*INF = INF
xmul_n:					;NANを返す
	move.w	#$7FFF,d0
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	movem.l	(sp)+,d3-d7
	rts

;----------------------------------------------------------------
;	2数を除算する(A=A/B)
;	in :d0:d1:d2 = 拡張精度実数値A
;	    d3:d4:d5 = 拡張精度実数値B
;	out:d0:d1:d2 = 結果
xdiv::
	movem.l	d3-d7,-(sp)
	move.w	d0,d6
	eor.w	d3,d6			;結果の符号
	move.w	#$7FFF,d7
	and.w	d7,d0
	beq	xdiv_za			;A=0 or 非正規化数
	cmp.w	d7,d0
	beq	xdiv_nia		;A=NAN or ±INF
xdiv1:
	and.w	d7,d3
	beq	xdiv_zb			;B=0 or 非正規化数
	cmp.w	d7,d3
	beq	xdiv_nib		;B=NAN or ±INF
xdiv2:
	ext.l	d0			;(一時正規化数なら指数が負なので)
	ext.l	d3
	sub.l	d3,d0			;指数を引く
	add.l	#$3FFF,d0		;バイアスを加える

	moveq.l	#0,d3
	cmp.l	d4,d1
	bne	xdiv3
	cmp.l	d5,d2
xdiv3:
	bcc	xdiv4
	moveq.l	#0,d7			;A<B
	subq.l	#1,d0
	bra	xdiv5

xdiv4:					;A>B
	moveq.l	#1,d7
	sub.l	d5,d2
	subx.l	d4,d1
xdiv5:					;除算ループ
	add.l	d7,d7
	addx.l	d3,d3
	bcs	xdiv8			;除算終了
	add.l	d2,d2			;余り<<1
	addx.l	d1,d1
	bcs	xdiv7
	cmp.l	d4,d1
	bcs	xdiv5
	bne	xdiv7
	cmp.l	d5,d2
	bcs	xdiv5
xdiv7:
	sub.l	d5,d2
	subx.l	d4,d1
	addq.w	#1,d7
	bra	xdiv5

xdiv8:
	roxr.l	#1,d3
	roxr.l	#1,d7
	add.l	d2,d2
	addx.l	d1,d1
	bcs	xdiv9
	cmp.l	d4,d1
	bcs	xdiv10
	bne	xdiv9
	cmp.l	d5,d2
	bcs	xdiv10
xdiv9:
	moveq.l	#0,d1
	addq.l	#1,d7
	addx.l	d1,d3
	bcc	xdiv10
	addq.l	#1,d0			;丸めで桁上がりした
	move.l	#$80000000,d3		;(結果は$80000000_00000000)

xdiv10:
	move.l	d3,d1
	move.l	d7,d2
	cmp.w	#$7FFF,d0		;(ワード範囲に収まる)
	bcs	xdiv24			;結果の指数が範囲内
	cmp.w	#-64,d0
	bgt	xdiv23			;一時正規化数の範囲内
	tst.l	d0
	bmi	xdiv_z			;値がアンダーフローした	→0
	bra	xdiv_i			;  オーバーフロー	→INF

xdiv23:					;一時正規化数を非正規化数に戻す
	addq.w	#1,d0
	lsr.l	#1,d1
	roxr.l	#1,d2
	tst.w	d0
	bne	xdiv23
	moveq.l	#0,d3			;丸めを行う
	roxl.w	#1,d3			;シフトではみだした最下位ビット
	add.l	d3,d2			;最下位ビットを切り上げる(0捨1入)
	moveq.l	#0,d3
	addx.l	d3,d1
xdiv24:
	tst.w	d6			;結果の符号
	bpl	xdiv25
	or.w	#$8000,d0
xdiv25:
	movem.l	(sp)+,d3-d7
	rts

xdiv_za:				;A=0 or 非正規化数
	move.l	d1,d7
	or.l	d2,d7
	bne	xdiv_za5		;非正規化数の場合
	move.w	#$7FFF,d7
	and.w	d7,d3			;Bの指数
	beq	xdiv_za1		;B=0 or 非正規化数
	cmp.w	d7,d3
	bne	xdiv_z			;0/B = 0
	add.l	d4,d4
	or.l	d5,d4
	bne	xdiv_n			;仮数部が0でないならNAN
xdiv_z:
	move.w	d6,d0			;0/B = 0
	and.w	#$8000,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

xdiv_za1:				;B=0 or 非正規化数
	move.l	d4,d7
	or.l	d5,d7
	bne	xdiv_z			;0/非正規化数 = 0
	bra	xdiv_n			;0/0 = NAN

xdiv_za5:				;非正規化数を一時的に正規化する
	move.w	#$7FFF,d7
xdiv_za6:
	tst.l	d1
	bmi	xdiv1
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bra	xdiv_za6

xdiv_nia:				;A=NAN or ±INF
	add.l	d1,d1
	or.l	d2,d1
	bne	xdiv_n			;仮数部が0でないならNAN
	and.w	d7,d3			;Bの指数
	cmp.w	d7,d3
	beq	xdiv_n			;INF/NAN, INF/INF = NAN
xdiv_i:					;INFを返す
	move.w	d6,d0
	or.w	#$7FFF,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7
	rts

xdiv_zb:				;B=0 or 非正規化数
	move.l	d4,d7
	or.l	d5,d7
	beq	xdiv_i			;A/0 = INF
xdiv_zb1:				;非正規化数を一時的に正規化する
	tst.l	d4
	bmi	xdiv2
	subq.w	#1,d3
	add.l	d5,d5
	addx.l	d4,d4
	bra	xdiv_zb1

xdiv_nib:				;B=NAN or ±INF
	add.l	d4,d4
	or.l	d5,d4
	beq	xdiv_z			;A/INF = 0
xdiv_n:					;NANを返す
	move.w	#$7FFF,d0
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	movem.l	(sp)+,d3-d7
	rts

;----------------------------------------------------------------
;	正規化する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0:d1:d2 = 結果
normalize:
	move.l	d3,-(sp)
	move.w	d0,d3
	and.w	#$7FFF,d3
	beq	normalize9		;指数部が0ならなにもしない
	cmp.w	#$7FFF,d3
	beq	normalize_ni		;NAN or ±INF
	tst.l	d1
	bmi	normalize9		;すでに正規化されている
	bne	normalize1
	tst.l	d2
	beq	normalize_z		;仮数部が0なら0
normalize1:
	subq.w	#1,d0
	add.l	d2,d2
	addx.l	d1,d1
	bmi	normalize9		;正規化が終了した
	subq.w	#1,d3
	bne	normalize1		;指数部が0になったら正規化を中断する
normalize9:
	move.l	(sp)+,d3
	rts

normalize_z:				;0
	and.w	#$8000,d0
	bra	normalize9

normalize_ni:				;NAN or ±INF
	add.l	d1,d1
	or.l	d2,d1
	beq	normalize9		;INF
normalize_n:				;NAN
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	bra	normalize9

;----------------------------------------------------------------
;	64bit整数を拡張精度に変換する
;	in :d1:d0 = 64bit整数
;	out:d0:d1:d2 = 結果
qtox:
	move.l	d0,d2
	or.l	d1,d2
	beq	qtox9			;0
	tst.l	d1
	beq	qtox3			;d1=0なので下位32bitを拡張精度にする
	bpl	qtox2
;負数
	neg.l	d0
	negx.l	d1
	bsr	qtox1
	bchg.l	#15,d0
qtox9:
	rts

;d1=0なので下位32bitを拡張精度にする
qtox3:
	moveq.l	#0,d2
	move.l	d0,d1
	bra	ltox1

qtox1:
	tst.l	d1
	beq	qtox3			;d1=0なので下位32bitを拡張精度にする
;d1=0ではない
qtox2:
	move.l	d0,d2
	beq	qtox4			;d0=0なので上位32bitだけシフトする
;d1,d0共に0でないので全体をシフトする
	move.l	#$3FFF+63,d0		;指数部は2^63
	tst.l	d1
	bra	qtox7

qtox6:
	add.l	d2,d2
	addx.l	d1,d1
qtox7:
	dbmi	d0,qtox6
	rts

;d0=0なので上位32bitだけシフトする
qtox4:
;d2=0
	move.l	d1,d0
	swap.w	d0
	tst.w	d0
	beq	qtox5
	move.l	#$3FFF+63,d0		;指数部は2^63
	tst.l	d1
	bra	ltox3

qtox5:
	move.l	#$3FFF+47,d0		;指数部は2^47
	tst.w	d1
	bra	ltox7

;----------------------------------------------------------------
;	ロングワード整数を拡張精度に変換する
;	in :d0 = ロングワード整数値
;	out:d0:d1:d2 = 結果
ltox::
	moveq.l	#0,d2
	move.l	d0,d1
	beq	ltox9			;0の場合
	bpl	ltox1
	neg.l	d0			;負数なら変換後に符号ビットをセットする
	move.l	d0,d1
	bsr	ltox1
	bchg.l	#15,d0
ltox9:
	rts

ltox1:
	swap.w	d0
	tst.w	d0
	beq	ltox5
	move.l	#$3FFF+31,d0		;指数部は2^31
	tst.l	d1
	bra	ltox3

ltox2:
	add.l	d1,d1			;左シフトして正規化する
ltox3:
	dbmi	d0,ltox2
	rts

ltox5:					;$00000001～$0000FFFFの場合
	move.l	#$3FFF+15,d0		;指数部は2^15
	tst.w	d1
	bra	ltox7

ltox6:
	add.w	d1,d1			;左シフトして正規化する
ltox7:
	dbmi	d0,ltox6
	swap.w	d1
	rts

;----------------------------------------------------------------
;	単精度実数を拡張精度に変換する
;	in :d0 = 単精度実数値
;	out:d0:d1:d2 = 結果
stox::
	move.l	d0,d1
	move.l	d0,d2
	add.l	d2,d2			;符号ビット
	moveq.l	#0,d2
	roxr.w	#1,d2
	and.l	#$007FFFFF,d1		;仮数部
	swap.w	d0
	lsr.w	#7,d0			;d0.b=指数部
	tst.b	d0
	beq	stox_zn			;0 or 非正規化数
	cmp.b	#$FF,d0
	beq	stox_ni			;NAN or ±INF
	lsl.l	#8,d1			;正規化数
	bset.l	#31,d1			;仮数部整数ビット
	move.b	d0,d2
	add.w	#$3FFF-$7F,d2
	move.l	d2,d0			;指数部
	moveq.l	#0,d2
	rts

stox_zn:				;0 or 非正規化数
	move.l	d2,d0			;指数部
	tst.l	d1
	beq	stox_z			;0
	lsl.l	#8,d1			;非正規化数
	add.w	#$3FFF-$7F+1,d0
	moveq.l	#0,d2
	bra	normalize		;正規化する

stox_z:
	rts

stox_ni:				;NAN or ±INF
	or.w	#$7FFF,d2
	move.l	d2,d0			;指数部
	tst.l	d1
	beq	stox_i			;INF
	moveq.l	#-1,d1			;NANを返す
	moveq.l	#-1,d2
	rts

stox_i:
	moveq.l	#0,d1			;INFを返す
	moveq.l	#0,d2
	rts

;----------------------------------------------------------------
;	倍精度実数を拡張精度に変換する
;	in :d0:d1 = 倍精度実数値
;	out:d0:d1:d2 = 結果
dtox::
	move.l	d3,-(sp)
	move.l	d0,d2
	clr.w	d0
	swap.w	d0
	add.l	d0,d0
	lsr.w	#5,d0			;符号ビットと指数部を分離する
	and.l	#$000FFFFF,d2
	tst.w	d0
	beq	dtox_zn			;0 or 非正規化数
	cmp.w	#$7FF,d0
	beq	dtox_ni			;NAN or ±INF
	bset.l	#$14,d2			;整数ビット
	move.l	d1,d3
	move.w	d2,d3
	lsr.l	#5,d2
	ror.l	#5,d1
	ror.l	#5,d3
	swap.w	d1
	and.w	#$F800,d1
	swap.w	d2
	swap.w	d3
	move.w	d3,d2			;lsl #11,d2:d3 (整数ビットを最上位に上げる)
	exg.l	d1,d2
	add.w	#$3FFF-$3FF,d0
	add.w	d0,d0
	lsr.l	#1,d0			;符号ビットを付け加える
dtox_z:
	move.l	(sp)+,d3
	rts

dtox_zn:				;0 or 非正規化数
	lsr.l	#1,d0			;符号ビットを付け加える
	move.l	d2,d3
	or.l	d1,d3
	beq	dtox_z			;0
	add.w	#$3FFF-$3FF+12,d0	;非正規化数
	exg.l	d1,d2
	move.l	(sp)+,d3
	bra	normalize		;正規化する

dtox_ni:				;NAN or ±INF
	move.w	#$FFFF,d0
	lsr.l	#1,d0			;符号ビットを付け加える
	move.l	d2,d3
	or.l	d1,d3
	beq	dtox_i			;INF
	moveq.l	#-1,d1			;NANを返す
	moveq.l	#-1,d2
	move.l	(sp)+,d3
	rts

dtox_i:
	moveq.l	#0,d1			;INFを返す
	moveq.l	#0,d2
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;	パックドデシマルを拡張精度実数に変換する
;	in :d0:d1:d2 = パックドデシマル
;	out:d0:d1:d2 = 結果
ptox::
	movem.l	d3-d7/a0-a1,-(sp)
	swap.w	d0
	move.w	d0,-(sp)
	and.w	#$7FFF,d0
	cmp.w	#$7FFF,d0
	beq	ptox_ni			;NAN or ±INF
	clr.w	d0
	swap.w	d0
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5			;d3:d4:d5 = +0.0
	move.l	d2,-(sp)
	move.l	d1,d7
	moveq.l	#8+1-1,d6
	bra	ptox2

ptox1:					;BCD16～8桁目を変換する
	move.w	#$4002,d3
	move.l	#$A0000000,d4
	moveq.l	#0,d5			;d3:d4:d5 = +10.0
	bsr	xmul
	move.w	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	rol.l	#4,d7
	moveq.l	#0,d0
	move.w	d7,d0
ptox2:
	and.w	#$000F,d0
	cmp.w	#9,d0
	bls	ptox3
	moveq.l	#0,d0			;BCDの範囲外なら0
ptox3:
	bsr	ltox
	bsr	xadd
	dbra	d6,ptox1

	move.l	(sp)+,d7
	moveq.l	#8-1,d6
ptox4:					;BCD7～0桁目を変換する
	move.w	#$4002,d3
	move.l	#$A0000000,d4
	moveq.l	#0,d5			;d3:d4:d5 = +10.0
	bsr	xmul
	move.w	d0,d3
	move.l	d1,d4
	move.l	d2,d5
	rol.l	#4,d7
	moveq.l	#0,d0
	move.w	d7,d0
	and.w	#$000F,d0
	cmp.w	#9,d0
	bls	ptox5
	moveq.l	#0,d0			;BCDの範囲外なら0
ptox5:
	bsr	ltox
	bsr	xadd
	dbra	d6,ptox4

	move.w	(sp),d3			;10進指数を2進変換する
	movem.l	d0-d2,-(sp)		;仮数部
	rol.w	#4,d3
	moveq.l	#3-1,d6
	moveq.l	#0,d7
ptox_e1:
	add.w	d7,d7
	move.w	d7,d5
	add.w	d7,d7
	add.w	d7,d7
	add.w	d5,d7			;d7.w *= 10
	rol.w	#4,d3
	move.w	d3,d5
	and.w	#$000F,d5
	cmp.w	#9,d5
	bls	ptox_e2
	moveq.l	#0,d5
ptox_e2:
	add.w	d5,d7
	dbra	d6,ptox_e1
	and.w	#$4000,d3
	beq	ptox_e3			;指数部符号は正
	neg.w	d7			;指数部符号を反転する
ptox_e3:				;(d7.w = -999～999)
	move.w	#$3FFF,d0
	move.l	#$80000000,d1
	moveq.l	#0,d2			;d0:d1:d2 = 1.0
	sub.w	#16,d7			;仮数変換時の補正(d7.w = -1015～983)
	moveq.l	#10-1,d6
	tst.w	d7
	bmi	ptox_m
					;10進指数から10^nを得る
ptox_p:					;正の指数(1.0以上)の場合
	lea.l	(decexptblp+3*2,pc),a0	;10^512から開始
	lea.l	(decmantblp+3*8,pc),a1
	rol.w	#6-1,d7			;(必ず1024以下なので指数上位6bitは無視)
ptox_p1:
	move.w	(a0)+,d3
	movem.l	(a1)+,d4-d5
	add.w	d7,d7
	bpl	ptox_p2
	bsr	xmul			;10の累乗を掛ける
ptox_p2:
	dbra	d6,ptox_p1
	bra	ptox_8

ptox_m:					;負の指数(1.0未満)の場合
	lea.l	(decexptblm+3*2,pc),a0	;10^-512から開始
	lea.l	(decmantblm+3*8,pc),a1
	neg.w	d7
	rol.w	#6-1,d7			;(必ず1024以下なので指数上位6bitは無視)
ptox_m1:
	move.w	(a0)+,d3
	movem.l	(a1)+,d4-d5
	add.w	d7,d7
	bpl	ptox_m2
	bsr	xmul			;10の累乗を掛ける
ptox_m2:
	dbra	d6,ptox_m1

ptox_8:
	movem.l	(sp)+,d3-d5		;仮数部
	bsr	xmul			;仮数部×(10^指数部)
	tst.w	(sp)+
	bpl	ptox_9
	or.w	#$8000,d0		;仮数部符号は負
ptox_9:
	movem.l	(sp)+,d3-d7/a0-a1
	rts

ptox_ni:				;NAN or ±INF
	move.w	(sp)+,d0
	add.l	d1,d1
	or.l	d2,d1
	bne	ptox_n			;仮数部が0でないならNAN
ptox_i:					;INF
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7/a0-a1
	rts

ptox_n:					;NAN
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	movem.l	(sp)+,d3-d7/a0-a1
	rts

;----------------------------------------------------------------
;	拡張精度実数をロングワード整数に変換する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0 = 結果
;	    d1 = オーバーフローなどで変換できなければ-1
xtol::
	move.w	d0,d2			;符号をセーブする
	swap.w	d2
	and.w	#$7FFF,d0
	beq	xtol_z			;0 or 非正規化数→0
	move.w	#$3FFF+31,d2
	sub.w	d0,d2
	bcs	xtol_e			;オーバーフロー
	cmp.w	#31,d2
	bhi	xtol_z			;アンダーフロー→0
	lsr.l	d2,d1			;仮数部をシフトする
	bmi	xtol5
	tst.l	d2			;符号を付け加える
	bpl	xtol1
	neg.l	d1			;負数の場合
xtol1:
	move.l	d1,d0
	moveq.l	#0,d1			;変換できた
	rts

xtol5:					;2147483648～4294967297
	tst.l	d2
	bpl	xtol1			;正数の場合
	cmp.l	#$80000000,d1		;$80000000の場合だけ特別扱いする
	beq	xtol1
xtol_e:					;エラー
	moveq.l	#-1,d0
	moveq.l	#-1,d1
	rts

xtol_z:					;0 or アンダーフロー
	moveq.l	#0,d0
	moveq.l	#0,d1
	rts

;----------------------------------------------------------------
;	拡張精度実数を単精度に変換する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0 = 結果
xtos::
	move.w	d0,-(sp)		;符号をセーブする
	and.w	#$7FFF,d0
	beq	xtos_z			;0 or 非正規化数
	cmp.w	#$3FFF+$FF-$7F,d0
	bcc	xtos_ni			;NAN or ±INF or オーバーフロー
	sub.w	#$3FFF-$7F,d0
	bhi	xtos5			;変換後は正規化数になる
	beq	xtos6			;変換後は非正規化数になる
	neg.w	d0
	cmp.w	#23,d0
	bhi	xtos_z			;非正規化の範囲外なので0になる
	lsr.l	d0,d1
	moveq.l	#0,d0			;非正規化数の指数は0になる
	bra	xtos6

xtos5:
	add.l	d1,d1			;仮数部整数ビットを削除する
xtos6:
	btst.l	#31-23,d1		;23ビット目で丸めを行う
	beq	xtos_7			;(IEEEのRounding to Nearestだと,0.5は最下位
	add.l	#1<<(31-23),d1		; ビットが偶数になるように丸めるのが正しいが,
	bcc	xtos_7			; ここでは0.5は必ず無限大方向に丸められる)
	addq.w	#1,d0
	cmp.w	#$FF,d0
	beq	xtos_i			;丸めの結果オーバーフローした
xtos_7:
	move.b	d0,d1			;指数部を付け加える
	ror.l	#8,d1
	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d1			;符号ビットを付け加える
	move.l	d1,d0
	rts

xtos_z:					;0 or 非正規化数
	moveq.l	#0,d0			;拡張精度での非正規化数は0になる
	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d0			;符号ビットを付け加える
	rts

xtos_ni:				;NAN or ±INF or オーバーフロー
	cmp.w	#$7FFF,d0
	bne	xtos_i			;オーバーフロー → INF
	add.l	d1,d1
	or.l	d2,d1
	beq	xtos_i
xtos_n:
	moveq.l	#-1,d0			;NAN
	bra	xtos_i9

xtos_i:
	move.l	#$FF000000,d0		;INF
xtos_i9:
	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d0			;符号ビットを付け加える
	rts

;----------------------------------------------------------------
;	拡張精度実数を倍精度に変換する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0:d1 = 結果
xtod::
	move.w	d0,-(sp)		;符号をセーブする
	and.w	#$7FFF,d0
	beq	xtod_z			;0 or 非正規化数
	cmp.w	#$3FFF+$7FF-$3FF,d0
	bcc	xtod_ni			;NAN or ±INF or オーバーフロー
	sub.w	#$3FFF-$3FF,d0
	bhi	xtod5			;変換後は正規化数になる
	beq	xtod6			;変換後は非正規化数になる

	neg.w	d0
	cmp.w	#52,d0
	bhi	xtod_z			;非正規化の範囲外なので0になる
	subq.w	#1,d0
xtod1:
	lsr.l	#1,d1
	roxr.l	#1,d2
	dbra	d0,xtod1
	moveq.l	#0,d0			;非正規化数の指数は0になる
	bra	xtod6

xtod5:
	add.l	d2,d2			;仮数部整数ビットを削除する
	addx.l	d1,d1
xtod6:
	btst.l	#31-(52-32),d2		;52ビット目で丸めを行う
	beq	xtod_7			;(IEEEのRounding to Nearestだと,0.5は最下位
	add.l	#1<<(31-(52-32)),d2	; ビットが偶数になるように丸めるのが正しいが,
	bcc	xtod_7			; ここでは0.5は必ず無限大方向に丸められる)
	addq.l	#1,d1
	bcc	xtod_7
	addq.w	#1,d0
	cmp.w	#$7FF,d0
	beq	xtod_i			;丸めの結果オーバーフローした
xtod_7:
	and.l	#$FFFFF000,d2		;仮数部不要ビットをクリアする
	or.w	d0,d2			;指数部を付け加える
	swap.w	d2
	swap.w	d1
	move.l	d2,d0
	move.w	d1,d0
	move.w	d2,d1

	move.l	d1,d2
	move.w	d0,d2
	rol.l	#5,d0
	rol.l	#5,d1
	rol.l	#5,d2
	and.w	#$001F,d0
	and.w	#$FFE0,d1
	or.w	d0,d1
	move.w	d2,d0

	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d0			;符号ビットを付け加える
	roxr.l	#1,d1
	rts

xtod_z:					;0 or 非正規化数
	moveq.l	#0,d0			;拡張精度での非正規化数は0になる
	moveq.l	#0,d1
	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d0			;符号ビットを付け加える
	rts

xtod_ni:				;NAN or ±INF or オーバーフロー
	cmp.w	#$7FFF,d0
	bne	xtod_i			;オーバーフロー → INF
	add.l	d1,d1
	or.l	d2,d1
	beq	xtod_i
xtod_n:
	moveq.l	#-1,d0			;NAN
	moveq.l	#-1,d1
	bra	xtod_i9

xtod_i:
	move.l	#$FF000000,d0		;INF
	moveq.l	#0,d1
xtod_i9:
	lsl.w	(sp)+			;保存してあった符号を調べる
	roxr.l	#1,d0			;符号ビットを付け加える
	rts

;----------------------------------------------------------------
;	拡張精度実数をパックドデシマルに変換する
;	in :d0:d1:d2 = 拡張精度実数値
;	out:d0:d1:d2 = 結果
xtop::
	link	a6,#-18
	movem.l	d3-d7/a0-a1,-(sp)
	move.w	d0,d6
	move.w	#$7FFF,d7
	and.w	d7,d6
	beq	xtop_zn			;0 or 非正規化数
	cmp.w	d7,d6
	beq	xtop_ni			;NAN or ±INF
xtop1:
	move.w	d0,-(sp)		;仮数部符号
	move.w	d6,d0
	move.w	#4096*2,d6
	moveq.l	#0,d7
	cmp.w	#$3FFF,d0
	bcs	xtop_m			;1.0未満の場合

	lea.l	(decmantblp,pc),a0	;1.0以上の場合
	lea.l	(decexptblp,pc),a1	;1.0以上10.0未満の値に補正する
xtop_p1:
	move.w	(a1)+,d3		;10進指数テーブルから数値を得る
	beq	xtop_man
	movem.l	(a0)+,d4-d5
	lsr.w	#1,d6
	cmp.w	d3,d0
	bcs	xtop_p1
	bhi	xtop_p3
	cmp.l	d4,d1
	bne	xtop_p2
	cmp.l	d5,d2
xtop_p2:
	bcs	xtop_p1
xtop_p3:				;テーブルの値より大きいならその逆数を掛ける
	add.w	d6,d7
	move.w	(decexptblm-(decexptblp+2),a1),d3
	movem.l	(decmantblm-(decmantblp+8),a0),d4-d5
	bsr	xmul
	bra	xtop_p1

xtop_m:
	lea.l	(decmantblm,pc),a0	;1.0未満の場合
	lea.l	(decexptblm,pc),a1	;0.1以上1.0未満の値に補正する
xtop_m1:
	move.w	(a1)+,d3		;10進指数テーブルから数値を得る
	beq	xtop_man0
	movem.l	(a0)+,d4-d5
	lsr.w	#1,d6
	cmp.w	d3,d0
	bhi	xtop_m1
	bcs	xtop_m3
	cmp.l	d4,d1
	bne	xtop_m2
	cmp.l	d5,d2
xtop_m2:
	bcc	xtop_m1
xtop_m3:				;テーブルの値より小さいならその逆数を掛ける
	sub.w	d6,d7
	move.w	(decexptblp-(decexptblm+2),a1),d3
	movem.l	(decmantblp-(decmantblm+8),a0),d4-d5
	bsr	xmul
	bra	xtop_m1

xtop_man0:				;0.1以上1.0未満
	subq.w	#1,d7
	move.w	#$4002,d3
	move.l	#$A0000000,d4
	moveq.l	#0,d5
	bsr	xmul			;10倍する

xtop_man:				;1.0以上10.0未満の仮数部を10進数に変換する
	sub.w	#$3FFE,d0
	move.l	d1,d4
	clr.w	d4
	move.l	d2,d3
	move.w	d1,d3
	lsl.l	d0,d1
	lsl.l	d0,d2
	rol.l	d0,d3
	rol.l	d0,d4
	move.w	d3,d1			;lsl d0,d4:d1:d2 小数点の位置を合わせる
	lea.l	(-17,a6),a0
	movea.l	a0,a1
	move.b	d4,(a0)+		;10進仮数整数部

	moveq.l	#17-1,d0
	bra	xtop_man2

xtop_man1:
	move.b	d3,(a0)+
xtop_man2:
	moveq.l	#0,d3
	add.l	d2,d2
	addx.l	d1,d1
	addx.w	d3,d3			;lsl d3:d1:d2
	move.l	d1,d4
	move.l	d2,d5
	move.w	d3,d6
	add.l	d5,d5
	addx.l	d4,d4
	addx.w	d6,d6			;lsl d6:d4:d5
	add.l	d5,d5
	addx.l	d4,d4
	addx.w	d6,d6			;lsl d6:d4:d5
	add.l	d5,d2
	addx.l	d4,d1
	addx.w	d6,d3			;add d6:d4:d5,d3:d1:d2 (mulu #10,d3:d1:d2)
	dbra	d0,xtop_man1

	cmp.w	#-4933,d7
	bge	xtop_mrof
	move.w	d7,d0			;-4933以下の指数なら非正規化する
	move.w	#-4933,d7
	add.w	#4933,d0
	moveq.l	#17-1,d2
	moveq.l	#0,d3
	cmp.w	#-17,d0
	blt	xtop_man5		;-4933-17以下の指数なら0
	lea.l	(1,a0,d0.w),a1
	move.b	-(a1),d3		;BCD最下位
	moveq.l	#17,d1
	add.w	d0,d1
	bra	xtop_man4

xtop_man3:
	move.b	-(a1),-(a0)		;仮数部をシフトする
xtop_man4:
	dbra	d1,xtop_man3
	move.w	d0,d2
	neg.w	d2
	subq.w	#1,d2
xtop_man5:
	clr.b	-(a0)			;仮数部上位に0を入れる
	dbra	d2,xtop_man5
	movea.l	a6,a0
	lea.l	(-17,a6),a1

xtop_mrof:				;BCD最下位を四捨五入する
	cmp.w	#5,d3
	bcs	xtop_mrof3
	moveq.l	#17-1,d0
xtop_mrof1:
	move.b	-(a0),d1
	addq.b	#1,d1
	cmp.b	#9,d1
	bls	xtop_mrof2
	clr.b	(a0)
	dbra	d0,xtop_mrof1
	addq.w	#1,d7			;四捨五入によって桁上がりした
	subq.l	#1,a0
	movea.l	a0,a1
	moveq.l	#1,d1
xtop_mrof2:
	move.b	d1,(a0)
xtop_mrof3:				;BCDをパックする
	moveq.l	#0,d0
	move.b	(a1)+,d0		;10進仮数整数部
	moveq.l	#16-1,d3
xtop_mrof4:
	move.l	d2,d4
	move.w	d1,d4
	lsl.l	#4,d2
	lsl.l	#4,d1
	rol.l	#4,d4
	move.w	d4,d1
	move.b	(a1)+,d4
	or.b	d4,d2
	dbra	d3,xtop_mrof4

xtop_exp:				;指数部を作成する
	moveq.l	#0,d3
	move.w	d7,d3			;指数
	bpl	xtop_exp1
	neg.w	d3			;指数は負
xtop_exp1:
	lsl.w	#4,d0
	divu.w	#1000,d3		;1000の位を得る
	or.w	d3,d0
	ror.w	#4,d0
	swap.w	d0
	clr.w	d3
	swap.w	d3
	divu.w	#100,d3			;100の位を得る
	or.w	d3,d0
	rol.w	#4,d0
	clr.w	d3
	swap.w	d3
	divu.w	#10,d3			;10の位を得る
	or.w	d3,d0
	rol.w	#4,d0
	swap.w	d3
	or.w	d3,d0			;1の位
	tst.w	d7
	bpl	xtop_exp2
	or.w	#$4000,d0		;指数部符号は負
xtop_exp2:
	tst.w	(sp)+
	bpl	xtop_exp3
	or.w	#$8000,d0		;仮数部符号は負
xtop_exp3:
	swap.w	d0
	movem.l	(sp)+,d3-d7/a0-a1
	unlk	a6
	rts

xtop_zn:				;0 or 非正規化数
	move.l	d1,d7
	or.l	d2,d7
	bne	xtop1
xtop_z:					;0の場合
	swap.w	d0
	clr.w	d0
	movem.l	(sp)+,d3-d7/a0-a1
	unlk	a6
	rts

xtop_ni:				;NAN or ±INF
	add.l	d1,d1
	or.l	d2,d1
	bne	xtop_n			;仮数部が0でないならNAN
xtop_i:					;INF
	swap.w	d0
	clr.w	d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	movem.l	(sp)+,d3-d7/a0-a1
	unlk	a6
	rts

xtop_n:					;NAN
	swap.w	d0
	clr.w	d0
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	movem.l	(sp)+,d3-d7/a0-a1
	unlk	a6
	rts

;----------------------------------------------------------------
;	10進指数変換用テーブル
decmantblp:
	.dc.l	$C4605202,$8A20979B	;10^4096
	.dc.l	$9E8B3B5D,$C53D5DE5	;10^2048
	.dc.l	$C9767586,$81750C17	;10^1024
	.dc.l	$E319A0AE,$A60E91C7	;10^512
	.dc.l	$AA7EEBFB,$9DF9DE8E	;10^256
	.dc.l	$93BA47C9,$80E98CE0	;10^128
	.dc.l	$C2781F49,$FFCFA6D5	;10^64
	.dc.l	$9DC5ADA8,$2B70B59E	;10^32
	.dc.l	$8E1BC9BF,$04000000	;10^16
	.dc.l	$BEBC2000,$00000000	;10^8
	.dc.l	$9C400000,$00000000	;10^4
	.dc.l	$C8000000,$00000000	;10^2
	.dc.l	$A0000000,$00000000	;10^1

decexptblp:
	.dc.w	$7525			;10^4096
	.dc.w	$5A92			;10^2048
	.dc.w	$4D48			;10^1024
	.dc.w	$46A3			;10^512
	.dc.w	$4351			;10^256
	.dc.w	$41A8			;10^128
	.dc.w	$40D3			;10^64
	.dc.w	$4069			;10^32
	.dc.w	$4034			;10^16
	.dc.w	$4019			;10^8
	.dc.w	$400C			;10^4
	.dc.w	$4005			;10^2
	.dc.w	$4002			;10^1
	.dc.w	0

decmantblm:
	.dc.l	$A6DD04C8,$D2CE9FDE	;10^-4096
	.dc.l	$CEAE534F,$34362DE4	;10^-2048
	.dc.l	$A2A682A5,$DA57C0BE	;10^-1024
	.dc.l	$9049EE32,$DB23D21C	;10^-512
	.dc.l	$C0314325,$637A193A	;10^-256
	.dc.l	$DDD0467C,$64BCE4A0	;10^-128
	.dc.l	$A87FEA27,$A539E9A5	;10^-64
	.dc.l	$CFB11EAD,$453994BA	;10^-32
	.dc.l	$E69594BE,$C44DE15B	;10^-16
	.dc.l	$ABCC7711,$8461CEFD	;10^-8
	.dc.l	$D1B71758,$E219652C	;10^-4
	.dc.l	$A3D70A3D,$70A3D70A	;10^-2
	.dc.l	$CCCCCCCC,$CCCCCCCD	;10^-1

decexptblm:
	.dc.w	$0AD8			;10^-4096
	.dc.w	$256B			;10^-2048
	.dc.w	$32B5			;10^-1024
	.dc.w	$395A			;10^-512
	.dc.w	$3CAC			;10^-256
	.dc.w	$3E55			;10^-128
	.dc.w	$3F2A			;10^-64
	.dc.w	$3F94			;10^-32
	.dc.w	$3FC9			;10^-16
	.dc.w	$3FE4			;10^-8
	.dc.w	$3FF1			;10^-4
	.dc.w	$3FF8			;10^-2
	.dc.w	$3FFB			;10^-1
	.dc.w	0


;----------------------------------------------------------------
	.end
