;----------------------------------------------------------------
;	X68k High-speed Assembler
;		シンボル管理
;		< symbol.s >
;
;	$Id: symbol.s,v 1.8  1999 10/ 8(Fri) 21:49:32 M.Kamada Exp $
;
;		Copyright 1990-94  by Y.Nakamura
;			  1999     by M.Kamada
;			  2025     by TcbnErik
;----------------------------------------------------------------

	.include	has.equ
	.include	symbol.equ
	.include	tmpcode.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	マクロ定義
;----------------------------------------------------------------

;----------------------------------------------------------------
;	ハッシュ関数の計算
;	in :a2=文字列へのポインタ/d2.w=文字列長-1
;	out:d0.l=ハッシュ関数値		(d3を破壊)
hashfnc	.macro	hashsize_minus_1
	moveq.l	#0,d0
@loop:
	moveq.l	#$20,d3			;(大文字・小文字の違いは無視)
	or.b	(a2)+,d3
	add.w	d3,d0
	ror.w	#3,d0
	sub.w	d3,d0
	dbra	d2,@loop
	and.l	hashsize_minus_1,d0	;d0.l=シンボルのハッシュ関数値
	.endm


;----------------------------------------------------------------
;	予約済みシンボルの初期化
;----------------------------------------------------------------
defressym::
	move.l	(TEMPPTR,a6),d0
	doquad	d0			;念のため
	movea.l	d0,a3
	lea.l	(reg_tbl,pc),a2		;レジスタ名シンボルの初期化
	move.l	#SYMHASHSIZE-1,d5	;ロングにすること
	movea.l	(SYMHASHPTR,a6),a5
defressym1:
	movea.l	a2,a0
	moveq.l	#-2,d1
defressym2:
	addq.w	#1,d1
	tst.b	(a2)+
	bne	defressym2
	bsr	getsymchain
	move.l	a3,(a1)
	clr.l	(a3)+			;$00 SYM_NEXT
	move.l	a0,(a3)+		;$04 SYM_NAME
	move.w	#ST_REGISTER<<8,(a3)+	;$08 SYM_TYPE,$09 空き
;a2が奇数番地のことがあるので.wにしないこと
	move.b	(a2)+,(a3)+		;$0A SYM_ARCH
	move.b	(a2)+,(a3)+		;$0B SYM_ARCH2
	move.b	(a2)+,(a3)+		;$0C SYM_REGNO
	addq.l	#3,a3			;$10 ロングワード境界に合わせる
	tst.b	(a2)
	bne	defressym1

	llea	opcode_tbl,a2		;命令名シンボルの初期化
	llea	opadr_tbl,a4
	move.l	#CMDHASHSIZE-1,d5	;ロングにすること
	movea.l	(CMDHASHPTR,a6),a5
defressym3:
	movea.l	a2,a0
	moveq.l	#-2,d1
defressym4:
	addq.w	#1,d1
	tst.b	(a2)+
	bne	defressym4
	bsr	getsymchain
	move.l	a3,(a1)
	clr.l	(a3)+			;$00 SYM_NEXT
	move.l	a0,(a3)+		;$04 SYM_NAME
	move.b	#ST_OPCODE,(a3)+	;$08 SYM_TYPE
	move.b	(a2)+,(a3)+		;$09 SYM_NOOPR
;a2が奇数番地のことがあるので.wや.lにしないこと
	move.b	(a2)+,(a3)+		;$0A SYM_ARCH
	move.b	(a2)+,(a3)+		;$0B SYM_ARCH2
	move.b	(a2)+,(a3)+		;$0C SYM_SIZE
	move.b	(a2)+,(a3)+		;$0D SYM_SIZE2
	move.w	(a4)+,(a3)+		;$0E SYM_OPCODE
	move.l	(a4)+,d0
	lea.l	(-4,a4,d0.l),a0
	move.l	a0,(a3)+		;$10 SYM_FUNC
					;$14
	tst.b	(a2)
	bne	defressym3

	move.l	a3,(TEMPPTR,a6)
	bra	memcheck

;----------------------------------------------------------------
;	シンボルテーブルチェインの末尾を得る
getsymchain:
	move.l	a2,-(sp)
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	hashfnc	d5			;シンボルハッシュ関数値を計算
	lsl.l	#2,d0
	add.l	a5,d0			;シンボルハッシュテーブルアドレス
	movea.l	d0,a1
getsymchain1:
	tst.l	(a1)			;(SYM_NEXT(a1))
	beq	getsymchain2
	movea.l	(a1),a1
	bra	getsymchain1

getsymchain2:
	movea.l	(sp)+,a2
	rts


;----------------------------------------------------------------
;	シンボルテーブルの検索
;----------------------------------------------------------------

;----------------------------------------------------------------
;	名前がシンボルとして登録済かどうか調べる
;	in :a0=文字列へのポインタ/d1.w=文字列長-1
;	out:d0.l=登録済なら0 /a1=シンボルテーブルへのポインタ
;		 未登録なら-1/a1=ハッシュテーブル未使用部へのポインタ
;	    d1.w=/8が指定されていたら文字列長を修正
isdefdsym::
	movem.l	d2-d3/a2-a3,-(sp)
	tst.b	(SYMLEN8,a6)
	beq	isdefdsym1
	cmp.w	#8-1,d1
	bls	isdefdsym1
	moveq.l	#8-1,d1			;/8が指定されていた場合8文字目以降は無視
isdefdsym1:
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	hashfnc	#SYMHASHSIZE-1		;シンボルハッシュ関数値を計算
	lsl.l	#2,d0
	add.l	(SYMHASHPTR,a6),d0	;シンボルハッシュテーブルアドレス
	movea.l	d0,a1
isdefdsym3:
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	isdefdsym9		;未登録だった
	movea.l	d0,a1
	move.b	(SYM_TYPE,a1),d3	;シンボルタイプ
	bpl	isdefdsym5		;ユーザー定義シンボル
	move.w	(SYM_ARCH,a1),d3	;予約シンボル(命令/レジスタ名)の場合
	beq	isdefdsym35		;疑似命令の場合
	and.w	(CPUTYPE,a6),d3
	beq	isdefdsym3		;現在のCPUタイプと合致しないので無視
isdefdsym35:
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
isdefdsym4:
	move.b	(a2)+,d0
;	tolower	d0			;予約シンボルは大文字・小文字を区別しない
	ori.w	#$20,d0			;(0～9,A～Z以外の文字は考慮しなくてよい)
	cmp.b	(a3)+,d0
	dbne	d2,isdefdsym4
	bne	isdefdsym3		;シンボル名が一致しなかった
	tst.b	(a3)
	bne	isdefdsym3		;	〃
	moveq.l	#0,d0			;一致した場合
	movem.l	(sp)+,d2-d3/a2-a3
	rts

isdefdsym5:				;ユーザー定義シンボル
	cmpi.b	#ST_LOCAL,d3
	beq	isdefdsym3		;ローカルラベルなら無視
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
isdefdsym6:
	cmpm.b	(a2)+,(a3)+
	dbne	d2,isdefdsym6
	bne	isdefdsym3		;シンボル名が一致しなかった
	tst.b	(a3)
	bne	isdefdsym3		;	〃
	moveq.l	#0,d0			;一致した場合
	movem.l	(sp)+,d2-d3/a2-a3
	rts

isdefdsym9:				;未登録だった場合
	moveq.l	#-1,d0
	movem.l	(sp)+,d2-d3/a2-a3
	rts

;----------------------------------------------------------------
;	名前がマクロとして登録済かどうか調べる
;	in :a0=マクロ名へのポインタ/d1.w=マクロ名長-1
;	out:d0.l=登録済なら0 /a1=シンボルテーブルへのポインタ
;		 未登録なら-1/a1=新しいシンボル属性テーブルへのポインタ
;	    d1.w=/8が指定されていたら文字列長を修正
isdefdmac::
	tst.b	(SYMLEN8,a6)
	beq	isdefdmac1
	cmp.w	#8-1,d1
	bls	isdefdmac1
	moveq.l	#8-1,d1			;/8が指定されていた場合8字目以降は無視
isdefdmac1:
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	hashfnc	#CMDHASHSIZE-1		;命令ハッシュ関数値を計算
	lsl.l	#2,d0
	add.l	(CMDHASHPTR,a6),d0	;命令ハッシュテーブルアドレス
	movea.l	d0,a1
	movea.l	d0,a4			;シンボルテーブルチェインの先頭
isdefdmac3:
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	isdefdmac9		;未登録だった
	movea.l	d0,a1
	cmpi.b	#ST_MACRO,(SYM_TYPE,a1)	;シンボルタイプ
	bne	isdefdmac3		;マクロ名でない	(isdefdmac9)
	move.w	d1,d2			;文字列長-1
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
isdefdmac4:
	move.b	(a2)+,d0
	bmi	isdefdmac10		;半角カタカナ/2バイト文字
	tolower	d0			;マクロ名は大文字・小文字を区別しない
isdefdmac5:
	cmp.b	(a3)+,d0
	dbne	d2,isdefdmac4
	bne	isdefdmac3		;シンボル名が一致しなかった
isdefdmac6:
	tst.b	(a3)
	bne	isdefdmac3		;	〃
	moveq.l	#0,d0			;一致した場合
	rts

isdefdmac9:				;未登録だった場合
	movea.l	a4,a1			;シンボルテーブルはポインタチェインの先頭に作成する
	moveq.l	#-1,d0
	rts

isdefdmac10:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	isdefdmac11
	cmp.b	#$A0,d0
	bcc	isdefdmac5		;半角カタカナ
  .else
	bra	isdefdmac5		;EUC
  .endif
isdefdmac11:				;2バイト文字
	cmp.b	(a3)+,d0
	bne	isdefdmac3
	subq.w	#1,d2
	bcs	isdefdmac6
	move.b	(a2)+,d0		;2バイト文字の2バイト目
	bra	isdefdmac5

;----------------------------------------------------------------
;	ローカルラベルが登録済かどうか調べる
;	in :d1.l=ローカルラベル番号
;	out:d0.l=登録済なら0 /a1=シンボルテーブルへのポインタ
;		 未登録なら-1/a1=ハッシュテーブル未使用部へのポインタ
isdefdlocsym::
	move.l	d1,d0
	swap.w	d0
	lsl.w	#5,d0
	eor.w	d1,d0
	and.l	#SYMHASHSIZE-1,d0	;ロングにすること
	lsl.l	#2,d0
	add.l	(SYMHASHPTR,a6),d0	;シンボルのハッシュテーブルアドレス
	movea.l	d0,a1
isdefdlocsym1:
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	isdefdlocsym9		;未登録だった
	movea.l	d0,a1
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a1)	;シンボルタイプ
	bne	isdefdlocsym1		;ローカルラベルでない
	cmp.l	(SYM_NAME,a1),d1
	bne	isdefdlocsym1		;番号が違う
	moveq.l	#0,d0			;一致した場合
	rts

isdefdlocsym9:				;未登録だった場合
	moveq.l	#-1,d0
	rts


;----------------------------------------------------------------
;	命令・マクロ名の検索
;----------------------------------------------------------------

;----------------------------------------------------------------
;	文字列が命令,マクロがどうかを調べる(マクロ優先)
;	in :a0=文字列へのポインタ/d1.w=文字列長-1
;	out:d0.w=命令,マクロなら0
getmaccmd::
	movem.l	d2-d4/a1-a3,-(sp)
	moveq.l	#0,d0
	move.b	(a0),d2
	beq	getmaccmd99
	cmp.b	#'*',d2
	beq	getmaccmd99
	cmp.b	#';',d2			;拡張モードのコメント
	beq	getmaccmd99
getmaccmd0:
	cmp.b	#'=',d2
	bne	getmaccmd1
	lea.l	(getmacset,pc),a0	;'=' → 'set'
	moveq.l	#3-1,d1
getmaccmd1:
	move.w	d1,d4
	tst.b	(SYMLEN8,a6)
	beq	getmaccmd2
	cmp.w	#8-1,d4
	bls	getmaccmd2
	moveq.l	#8-1,d4			;/8が指定されていた場合マクロは8字目以降を無視
getmaccmd2:
	move.w	d4,d2			;文字列長-1(8文字目まで)
	movea.l	a0,a2			;文字列へのポインタ
	hashfnc	#CMDHASHSIZE-1		;命令ハッシュ関数値を計算
	lsl.l	#2,d0
	add.l	(CMDHASHPTR,a6),d0	;命令ハッシュテーブルアドレス
	movea.l	d0,a1
getmaccmd5:
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	getmaccmd80		;シンボルが見つからない
	movea.l	d0,a1
	tst.b	(SYM_TYPE,a1)		;シンボルタイプ
	bmi	getmaccmd21		;予約シンボル(命令)
	move.w	d4,d2			;(/8が指定されていたら8文字目までしか比較しない)
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
getmaccmd6:
	move.b	(a2)+,d0
	bmi	getmaccmd10		;半角カタカナ/2バイト文字
	tolower	d0			;マクロ名は大文字・小文字を区別しない
getmaccmd7:
	cmp.b	(a3)+,d0
	dbne	d2,getmaccmd6
	bne	getmaccmd5		;シンボル名が一致しなかった
getmaccmd8:
	tst.b	(a3)
	bne	getmaccmd5		;	〃
getmaccmd70:				;マクロ名を見つけた
	move.l	a1,(CMDTBLPTR,a6)	;シンボルテーブルへのポインタ
	st.b	(ISMACRO,a6)
	moveq.l	#0,d0
	movem.l	(sp)+,d2-d4/a1-a3
	rts

getmaccmd10:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getmaccmd11
	cmp.b	#$A0,d0
	bcc	getmaccmd7		;半角カタカナ
  .else
	bra	getmaccmd7		;EUC
  .endif
getmaccmd11:				;2バイト文字
	cmp.b	(a3)+,d0
	bne	getmaccmd5
	subq.w	#1,d2
	bcs	getmaccmd8
	move.b	(a2)+,d0		;2バイト文字の2バイト目
	bra	getmaccmd7

getmaccmd20:				;テーブルチェインから命令を検索する
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	getmaccmd80		;シンボルが見つからない
	movea.l	d0,a1
getmaccmd21:
	move.w	(SYM_ARCH,a1),d3	;予約シンボル(命令/レジスタ名)の場合
	beq	getmaccmd215		;疑似命令の場合
	and.w	(CPUTYPE,a6),d3
	beq	getmaccmd20		;現在のCPUタイプと合致しないので無視
getmaccmd215:
	move.w	d1,d2			;(/8の指定に関わらず全文字比較する)
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
getmaccmd22:
	move.b	(a2)+,d0
;	tolower	d0			;予約シンボルは大文字・小文字を区別しない
	ori.w	#$20,d0			;(0～9,A～Z以外の文字は考慮しなくてよい)
	cmp.b	(a3)+,d0
	dbne	d2,getmaccmd22
	bne	getmaccmd20		;シンボル名が違う
	tst.b	(a3)
	bne	getmaccmd20		;	〃
getmaccmd90:
	move.l	a1,(CMDTBLPTR,a6)	;シンボルテーブルへのポインタ
	sf.b	(ISMACRO,a6)
	moveq.l	#0,d0
	movem.l	(sp)+,d2-d4/a1-a3
	rts

getmaccmd99:				;命令・マクロが指定されていない
	clr.l	(CMDTBLPTR,a6)
	moveq.l	#0,d0
	movem.l	(sp)+,d2-d4/a1-a3
	rts

getmaccmd80:				;該当する命令・マクロがない
	clr.l	(CMDTBLPTR,a6)
	moveq.l	#-1,d0
	movem.l	(sp)+,d2-d4/a1-a3
	rts

getmacset:	.dc.b	'set'
		.even

;----------------------------------------------------------------
;	文字列が命令,マクロがどうかを調べる(命令優先)
;	in :a0=文字列へのポインタ/d1.w=文字列長-1
;	out:d0.w=命令,マクロなら0
getcmdmac::
	movem.l	d2-d4/a1-a3,-(sp)
	moveq.l	#0,d0
	move.b	(a0),d2
	beq	getmaccmd99
	cmp.b	#'*',d2
	beq	getmaccmd99
	cmp.b	#';',d2			;拡張モードのコメント
	beq	getmaccmd99
getcmdmac0:
	cmp.b	#'=',d2
	bne	getcmdmac1
	lea.l	(getmacset,pc),a0	;'=' → 'set'
	moveq.l	#3-1,d1
getcmdmac1:
	move.w	d1,d4
	tst.b	(SYMLEN8,a6)
	beq	getcmdmac2
	cmp.w	#8-1,d4
	bls	getcmdmac2
	moveq.l	#8-1,d4			;/8が指定されていた場合マクロは8字目以降を無視
getcmdmac2:
	move.w	d4,d2			;文字列長-1(8文字目まで)
	movea.l	a0,a2			;文字列へのポインタ
	hashfnc	#CMDHASHSIZE-1		;命令ハッシュ関数値を計算
	lsl.l	#2,d0
	add.l	(CMDHASHPTR,a6),d0	;命令ハッシュテーブルアドレス
	movea.l	d0,a1
	movea.l	d0,a5
getcmdmac5:				;テーブルチェインから命令を検索する
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	getcmdmac9		;シンボルが見つからない
	movea.l	d0,a1
	tst.b	(SYM_TYPE,a1)		;シンボルタイプ
	bpl	getcmdmac5		;マクロ名は無視する
	bra	getcmdmac7

getcmdmac6:
	move.l	(a1),d0			;(SYM_NEXT(a1))
	beq	getcmdmac9		;シンボルが見つからない→マクロとして再検索
	movea.l	d0,a1
getcmdmac7:
	move.w	(SYM_ARCH,a1),d3	;予約シンボル(命令/レジスタ名)の場合
	beq	getcmdmac75		;疑似命令の場合
	and.w	(CPUTYPE,a6),d3
	beq	getcmdmac6		;現在のCPUタイプと合致しないので無視
getcmdmac75:
	move.w	d1,d2			;(/8の指定に関わらず全文字比較する)
	movea.l	a0,a2			;文字列へのポインタ
	movea.l	(SYM_NAME,a1),a3
getcmdmac8:
	move.b	(a2)+,d0
;	tolower	d0			;予約シンボルは大文字・小文字を区別しない
	ori.w	#$20,d0			;(0～9,A～Z以外の文字は考慮しなくてよい)
	cmp.b	(a3)+,d0
	dbne	d2,getcmdmac8
	bne	getcmdmac6		;シンボル名が違う
	tst.b	(a3)
	bne	getcmdmac6		;	〃
	bra	getmaccmd90		;命令を見つけた

getcmdmac9:				;マクロとして再検索する
	movea.l	a5,a1
	bra	getmaccmd5


;----------------------------------------------------------------
;	シンボルテーブルの作成
;----------------------------------------------------------------

;----------------------------------------------------------------
;	文字列の名前のシンボルテーブルを作成する
;	in :a0=文字列へのポインタ/d1.w=文字列長-1
;	    a1=ハッシュテーブル未使用部へのポインタ
;	    d2.b=シンボルテーブルタイプ
;	out:a1=シンボルテーブルへのポインタ
defsymbol::
	movem.l	a2-a3,-(sp)
	movea.l	(TEMPPTR,a6),a2
	movea.l	a2,a3			;シンボル名へのポインタ
defsymbol1:
	move.b	(a0)+,(a3)+		;シンボル名をワークにコピー
	dbra	d1,defsymbol1
	clr.b	(a3)+
	move.l	a3,(TEMPPTR,a6)
	bsr	getsymtbl
	move.l	a0,(a1)			;ハッシュチェインをつなぐ
	movea.l	a0,a1
	move.b	d2,(SYM_TYPE,a1)
	move.l	a2,(SYM_NAME,a1)
	movem.l	(sp)+,a2-a3
	bra	memcheck

;----------------------------------------------------------------
;	シンボルテーブルのアドレスを得る
getsymtbl:
	subq.w	#1,(SYMTBLCOUNT,a6)
	bmi	getsymtbl1		;現在のシンボルテーブルブロックを使い尽くした
	movea.l	(SYMTBLPTR,a6),a0
	lea.l	(SYM_TBLLEN,a0),a0	;テーブルブロックの次のアドレスを得る
	move.l	a0,(SYMTBLPTR,a6)
	rts

getsymtbl1:				;シンボルテーブルブロックを拡張する
	move.l	(TEMPPTR,a6),d0
	doquad	d0
	movea.l	(SYMTBLCURBGN,a6),a0
	move.l	d0,(a0)			;シンボルテーブルブロックのチェインをつなぐ
	move.l	d0,(SYMTBLCURBGN,a6)
	movea.l	d0,a0
	add.l	#SYM_TBLLEN*SYMEXTCOUNT+4,d0
	move.l	d0,(TEMPPTR,a6)
	bsr	memcheck
	move.l	d1,-(sp)
	moveq.l	#0,d1
	move.w	#SYM_TBLLEN*SYMEXTCOUNT/16,d0
getsymtbl2:
  .rept 16/4
	move.l	d1,(a0)+		;拡張したブロックをクリアする
  .endm
	dbra	d0,getsymtbl2
	move.l	(sp)+,d1
	move.w	#SYMEXTCOUNT-1,(SYMTBLCOUNT,a6)
	movea.l	(SYMTBLCURBGN,a6),a0
	addq.l	#4,a0
	move.l	a0,(SYMTBLPTR,a6)
	rts

;----------------------------------------------------------------
;	文字列の名前のマクロ名シンボルテーブルを作成する
;	in :a0=文字列へのポインタ/d1.w=文字列長-1
;	    a1=ハッシュテーブル未使用部へのポインタ(ポインタチェインの先頭)
;	out:a1=シンボルテーブルへのポインタ
defmacsymbol::
	movem.l	a2-a3,-(sp)
	movea.l	(TEMPPTR,a6),a2
	movea.l	a2,a3			;シンボル名へのポインタ
defmacsymbol1:
	move.b	(a0)+,d0
	bmi	defmacsymbol5
	tolower	d0
defmacsymbol2:
	move.b	d0,(a3)+
	dbra	d1,defmacsymbol1
defmacsymbol3:
	clr.b	(a3)+
	move.l	a3,(TEMPPTR,a6)
	bsr	getsymtbl
	move.l	(a1),d0
	move.l	a0,(a1)			;ポインタチェインの先頭になる
	move.l	a0,a1
	move.l	d0,(a1)			;(SYM_NEXT(a1))
	move.b	#ST_MACRO,(SYM_TYPE,a1)
	move.l	a2,(SYM_NAME,a1)
	movem.l	(sp)+,a2-a3
	bra	memcheck

defmacsymbol5:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	defmacsymbol6
	cmp.b	#$A0,d0
	bcc	defmacsymbol2		;半角カタカナ
  .else
	bra	defmacsymbol2		;EUC
  .endif
defmacsymbol6:				;2バイト文字
	move.b	d0,(a3)+
	subq.w	#1,d1
	bmi	defmacsymbol3
	move.b	(a0)+,d0
	bra	defmacsymbol2

;----------------------------------------------------------------
;	ローカルラベルのシンボルテーブルを作成する
;	in :d1.l=ローカルラベル番号
;	   :a1=ハッシュテーブル未使用部へのポインタ
;	out:a1=シンボルテーブルへのポインタ
deflocsymbol::
	bsr	getsymtbl
	move.l	a0,(a1)
	movea.l	a0,a1
	move.b	#ST_LOCAL,(SYM_TYPE,a1)
	move.l	d1,(SYM_LOCALNO,a1)	;ローカルシンボル番号
	rts

;----------------------------------------------------------------
;	与えられた文字列をシンボルとして登録する
;	in :a0=文字列へのポインタ(asciz)
;	    d2.b=シンボルテーブルタイプ
;	out:a1=シンボルテーブルへのポインタ
defstrsymbol::
	bsr	strlen
	subq.l	#1,d1			;文字列長-1
	movea.l	a0,a2
	bsr	isdefdsym
	tst.w	d0
	beq	defstrsymbol9		;すでに登録済だった
	clr.b	(1,a2,d1.l)		;(/8が指定された場合のため)
	bsr	getsymtbl
	move.l	a0,(a1)
	movea.l	a0,a1
	move.b	d2,(SYM_TYPE,a1)
	move.l	a2,(SYM_NAME,a1)
defstrsymbol9:
	rts


;----------------------------------------------------------------
	.end
