;----------------------------------------------------------------
;	X68k High-speed Assembler
;		逆ポーランド式変換と演算
;		< expr.s >
;
;	$Id: expr.s,v 2.3  2016-01-01 12:00:00  M.Kamada Exp $
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
;	逆ポーランド式への変換
;----------------------------------------------------------------

;----------------------------------------------------------------
;	式を逆ポーランド記法に変換する
;	in :a0=コード化した式を指すポインタ/a1=変換した式が入るバッファへのポインタ
;	out:d0.w=式のみで変換ができたら0/式が得られたら1/変換に失敗したら-1
;	    d1.w=変換した式のワード数-1
convrpn::
	movem.l	d2/a1-a3,-(sp)
	move.l	a0,-(sp)
	move.l	sp,(EXPRSPSAVE,a6)
	sf.b	(EXPRISSTR,a6)
	move.b	#SZ_NONE,(EXPRSIZE,a6)
	lea.l	(RPNSTACK,a6),a2
	moveq.l	#0,d1
	clr.b	(a2)+			;スタックボトムを設定
	bsr	convrpndo
	clr.w	(a1)			;エンドコード(move.w #RPN_END,(a1))
	tst.w	d0
	bpl	convrpn1
	move.l	(sp),a0			;式変換に失敗したのでポインタを戻す
convrpn1:
	addq.l	#4,sp
	movem.l	(sp)+,d2/a1-a3
	rts

;----------------------------------------------------------------
;	変換の実処理
convrpndo:
	bsr	convrpnnum		;数値を得る
	tst.w	d0
	bne	convrpndo9		;エラー
	move.w	(a0),d0
	beq	convrpndo1		;式が終了した
;	cmp.w	#')'|OT_CHAR,d0		;????
;	beq	convrpndo1		;????
	bsr	getoperator		;演算子を得る
	tst.w	d0
	beq	convrpndo
	bra	convrpndo2		;演算子がなかった

convrpndo1:				;式が終了した
	moveq.l	#0,d0
convrpndo2:				;演算子スタックに残っている演算子を取り出す
	move.w	#RPN_OPERATOR,d2
	bra	convrpndo8

convrpndo3:
	cmp.b	#OP_NOTB,d2
	blo	convrpndo39		;.notb./.notw.以外の演算子
	bhi	convrpndo31
	move.w	#OP_NOT|RPN_OPERATOR,(a1)+	;.notb.Xを(.not.X).and.$FFに変換する
	move.w	#$FF|RPN_VALUEB,(a1)+
	move.w	#OP_AND|RPN_OPERATOR,(a1)+
	addq.w	#3,d1
	bra	convrpndo8

convrpndo31:
	move.w	#OP_NOT|RPN_OPERATOR,(a1)+	;.notw.Xを(.not.X).and.$FFFFに変換する
	move.w	#RPN_VALUEW,(a1)+
	move.w	#$FFFF,(a1)+
	move.w	#OP_AND|RPN_OPERATOR,(a1)+
	addq.w	#4,d1
	bra	convrpndo8

convrpndo39:
	addq.w	#1,d1			;.notb./.notw.以外の演算子
	move.w	d2,(a1)+
convrpndo8:
	move.b	-(a2),d2
	bne	convrpndo3
convrpndo9:
	rts

;----------------------------------------------------------------
;	数値・単項演算子を得る
convrpnnum:
	move.w	(a0)+,d0
	beq	convrpnnum9		;式が終了してしまった
	cmp.w	#OT_VALUEB,d0
	bcs	convrpnnum_char		;キャラクタ
	cmp.w	#OT_VALUEW,d0
	bcs	convrpnnum_b
	beq	convrpnnum_w
	cmp.w	#OT_VALUE,d0
	beq	convrpnnum_l
	cmp.w	#OT_VALUEQ,d0
	beq	convrpnnum_q
	cmp.w	#OT_SYMBOL,d0
	bne	convrpnnum5
convrpnnum_sym:				;シンボル
	move.l	(a0)+,a3
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a3)	;(ST_VALUE or ST_LOCAL)
	bhi	convrpnnum_sym9		;数値シンボルでない
	move.w	#RPN_SYMBOL,(a1)+	;シンボル
	move.l	a3,(a1)+
	addq.w	#3,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_sym9:
	cmpi.b	#ST_REAL,(SYM_TYPE,a3)
	beq	convrpnnum_real		;浮動小数点実数式の場合
	moveq.l	#-1,d0
	rts

convrpnnum_q:
	tst.l	(a0)+
	beq	convrpnnum_q_int_1	;上位32bitが0
	move.b	(a0),d0			;下位32bitの最上位バイト
	add.b	d0,d0
	subx.l	d0,d0			;下位32bit>=ならば0,下位32bit<0ならば-1
	cmp.l	(-4,a0),d0		;上位32bitが下位32bitの符号拡張と一致するか
	bne	overflowerr		;上位32bitが0以外で下位32bitの符号拡張でもない
convrpnnum_q_int_1:
	move.w	#RPN_VALUE,(a1)+	;32bit数値
	move.l	(a0)+,(a1)+
	addq.w	#3,d1			;逆ポーランド変換後のワード数
	bra	convrpnnumsize

convrpnnum_l:
	move.w	d0,(a1)+		;32bit数値(RPN_VALUE)
	move.l	(a0)+,(a1)+
	addq.w	#3,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_w:
	move.w	d0,(a1)+		;16bit数値(RPN_VALUEW)
	move.w	(a0)+,(a1)+
	addq.w	#2,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_b:
	move.w	d0,(a1)+		;8bit数値(RPN_VALUEB)
	addq.w	#1,d1
convrpnnumsize:				;数値・シンボルに後続するサイズを得る
	move.w	(a0),d0
	andi.w	#$FF00,d0
	cmpi.w	#OT_SIZE,d0
	bne	convrpnnumsize9		;サイズ指定がなかった
	move.w	(a0)+,d0
	move.b	d0,(EXPRSIZE,a6)	;サイズ指定を得る
convrpnnumsize9:
	moveq.l	#0,d0
	rts

convrpnnum_char:			;キャラクタの場合(OT_CHAR)
	cmp.w	#'('|OT_CHAR,d0
	beq	convrpnnum_paren
	cmp.w	#'-'|OT_CHAR,d0
	beq	convrpnnum_neg
	cmp.w	#'+'|OT_CHAR,d0
	beq	convrpnnum_pos
	cmp.w	#'*'|OT_CHAR,d0
	beq	convrpnnum_loc1
	cmp.w	#'$'|OT_CHAR,d0
	beq	convrpnnum_loc2
convrpnnum_char9:
	moveq.l	#-1,d0
	rts

convrpnnum_paren:
	clr.b	(a2)+			;仮のスタックボトムを設定
	bsr	convrpndo		;括弧内について再帰的に処理をする
	tst.w	d0
;	bne	convrpnnum_char9	;括弧内でエラー
					;????
	bmi	convrpnnum_char9	;括弧内でエラー
	cmp.w	#')'|OT_CHAR,(a0)+
	bne	convrpnnum_char9	;括弧が閉じていない
	moveq.l	#0,d0
	rts

convrpnnum_neg:
	move.b	#OP_NEG,(a2)+		;演算子コードをスタックに積む
	bra	convrpnnum		;続く数値を得る

convrpnnum_pos:
	move.b	#OP_POS,(a2)+		;演算子コードをスタックに積む
	bra	convrpnnum		;続く数値を得る

convrpnnum_loc1:
	move.w	#RPN_LOCATION,(a1)+	;'*'=現在のロケーションカウンタ
	addq.w	#1,d1
	moveq.l	#0,d0			;(サイズチェックはしない)
	rts

convrpnnum_loc2:
	move.w	#RPN_LOCATION|1,(a1)+	;'$'
	addq.w	#1,d1
	moveq.l	#0,d0			;(サイズチェックはしない)
	rts

convrpnnum5:
	move.w	d0,d2
	andi.w	#$FF00,d2
	cmp.w	#OT_STR,d2
	beq	convrpnnum_str
	cmp.w	#OT_OPERATOR,d2
	beq	convrpnnum_unary
	cmp.w	#OT_LOCALREF,d2
	beq	convrpnnum_local
	cmp.w	#OT_REAL,d2
	beq	convrpnnum_real
convrpnnum9:
	moveq.l	#-1,d0
	rts

convrpnnum_str:
	st.b	(EXPRISSTR,a6)		;文字列
	and.w	#$00FF,d0
	beq	convrpnnum9		;ヌルストリング→エラー
	cmp.w	#4,d0
	bhi	convrpnnum9		;4文字より長い→エラー
	subq.w	#1,d0
	moveq.l	#0,d2
convrpnnum_str1:
	asl.l	#8,d2
	move.b	(a0)+,d2
	dbra	d0,convrpnnum_str1
	move.l	a0,d0
	doeven	d0
	movea.l	d0,a0
	move.w	#RPN_VALUE,(a1)+	;数値
	move.l	d2,(a1)+
	addq.w	#3,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_unary:
	cmp.b	#OPNOTLK,d0
	bcc	convrpnnum_unary1
	cmp.b	#OP_MUL,d0
	bcc	convrpnnum9		;二項演算子ならエラー
convrpnnum_unary0:
	move.b	d0,(a2)+		;演算子コードをスタックに積む
	bra	convrpnnum		;続く数値を得る

convrpnnum_unary1:
	cmp.b	#OP_SIZEOF,d0
	blo	convrpnnum_unary0	;.notb./.notw.
	beq	convrpnnum_sizeof	;.sizeof.
;	cmp.b	#OP_DEFINED,d0
;	bra	convrpnnum_defined	;.defined.

;.defined.
convrpnnum_defined:
	move.w	(a0)+,d0
	cmp.w	#OT_SYMBOL,d0
	bne	convrpnnum_defined1
;.defined.SYMBOL
	bsr	convrpnnum_defined2
convrpnnum_defined9:
	move.w	#OT_VALUE,(a1)+		;32bit数値で返す(-1になるなので8bitは不可)
	move.l	d0,(a1)+
	addq.w	#3,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_defined1:
	cmp.w	#'('|OT_CHAR,d0
	bne	convrpnnum9
;.defined.(SYMBOL)
	cmpi.w	#OT_SYMBOL,(a0)+
	bne	convrpnnum9
	bsr	convrpnnum_defined2
	cmpi.w	#')'|OT_CHAR,(a0)+
	bne	convrpnnum9
	bra	convrpnnum_defined9

convrpnnum_defined2:
	move.w	#OT_VALUEB,d0
	move.l	(a0)+,a3
	move.b	(SYM_ATTRIB,a3),d0	;cmpi.b #SA_UNDEF,SYM_ATTRIB(a3)
	neg.b	d0
	subx.l	d0,d0
	rts

;.sizeof.()
convrpnnum_sizeof:
	movem.l	d1-d7/a1-a6,-(sp)	;getreglistがいろいろ壊す
	clr.w	d7			;サイズの合計
	cmpi.w	#'('|OT_CHAR,(a0)+
	bne	convrpnnum_sizeof99
	cmpi.w	#')'|OT_CHAR,(a0)+
	beq	convrpnnum_sizeof99	;.sizeof.()=0
	subq.l	#2,a0
convrpnnum_sizeof1:
	cmpi.b	#OT_STR>>8,(a0)
	bne	convrpnnum_sizeof2
;.sizeof.('～')
convrpnnum_sizeof11:
	moveq.l	#0,d0
	addq.w	#1,a0
	move.b	(a0)+,d0		;文字列長
	cmp.b	#OT_STR_WORDLEN,d0
	bne	@f
	move.w	(a0)+,d0		;$ffの場合のみ、続くワードが文字列長
@@:
	add.w	d0,d7			;文字列長を加算
	addq.l	#1,d0
	and.w	#$FFFE,d0
	adda.l	d0,a0			;文字列の直後
	cmpi.b	#OT_STR>>8,(a0)
	beq	convrpnnum_sizeof11
	bra	convrpnnum_sizeof7

convrpnnum_sizeof2:
	bsr	getreglist
	bmi	convrpnnum_sizeof3
;.sizeof.(d0-d7/a0-a7)
	clr.w	d0
	clr.w	d2
	moveq.l	#16-1,d3
convrpnnum_sizeof21:
	add.w	d1,d1
	addx.w	d2,d0
	dbra	d3,convrpnnum_sizeof21
	bra	convrpnnum_sizeof6	;レジスタ数*4

;浮動小数点レジスタはC040|C060|CFPPでなければ解釈されないので,
;C000などでは.sizeof.(fp0-fp7)などは(ここでは制限していないが),
;結局エラーになる
convrpnnum_sizeof3:
	bsr	getfpreglist
	bmi	convrpnnum_sizeof4
;.sizeof.(fp0-fp7)
	clr.w	d0
	clr.w	d2
	moveq.l	#8-1,d3
convrpnnum_sizeof31:
	add.b	d1,d1
	addx.w	d2,d0
	dbra	d3,convrpnnum_sizeof31
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0			;レジスタ数*3
	bra	convrpnnum_sizeof6	;レジスタ数*12

convrpnnum_sizeof4:
	bsr	getfpcreglist
	bmi	convrpnnum_sizeof99
;.sizeof.(fpcr/fpsr/fpiar)
	move.w	d2,d0			;レジスタ数-1
	addq.w	#1,d0			;レジスタ数
;	bra	convrpnnum_sizeof6	;レジスタ数*4

convrpnnum_sizeof6:
	asl.w	#2,d0			;レジスタ数*4/*12
	add.w	d0,d7			;サイズを加算
convrpnnum_sizeof7:
	move.w	(a0)+,d0
	cmp.w	#','|OT_CHAR,d0
	beq	convrpnnum_sizeof1
	cmp.w	#')'|OT_CHAR,d0
	bne	convrpnnum_sizeof99
convrpnnum_sizeof8:
	move.w	d7,d0			;サイズの合計
	movem.l	(sp)+,d1-d7/a1-a6
	move.w	#OT_VALUEW,(a1)+	;16bit数値として出力,convrpnnum_wの使用は不可
	move.w	d0,(a1)+
	addq.w	#2,d1
	bra	convrpnnumsize		;後続のサイズをチェックする

convrpnnum_sizeof99:
	movem.l	(sp)+,d1-d7/a1-a6
	bra	convrpnnum9

convrpnnum_local:			;ローカルラベル
	move.w	(a0)+,d2
	movem.l	d1/a0-a1,-(sp)
	ext.w	d0			;相対位置を得る
	move.w	d2,d1
	add.w	d2,d2
	swap.w	d1
	movea.l	(LOCALMAXPTR,a6),a1
	move.w	(a1,d2.w),d1
	add.w	d0,d1			;参照するローカルラベル番号
	bsr	isdefdlocsym
	tst.w	d0
	beq	convrpnnum_local1
	bsr	deflocsymbol		;未定義なのでシンボルを登録
convrpnnum_local1:
	move.l	a1,d0
	movem.l	(sp)+,d1/a0-a1
	move.w	#RPN_SYMBOL,(a1)+	;シンボル
	move.l	d0,(a1)+
	addq.w	#3,d1
	moveq.l	#0,d0			;(サイズチェックはしない)
	rts

convrpnnum_real:
	move.l	(CMDTBLPTR,a6),d0
	beq	convrpnnum_real1	;命令がない
	movea.l	d0,a3
	move.b	(SYM_SIZE,a3),d0	;命令で使えないサイズのビットが1
	andi.b	#SZS|SZD|SZX|SZP,d0
	bne	convrpnnum_real1	;浮動小数点演算命令でない
	move.b	(CMDOPSIZE,a6),d0
	cmpi.b	#SZ_LONG,d0
	bls	convrpnnum_real1	;サイズが.b/.w/.l
;ここでSZ_SINGLEをエラーにしないとfmove.s #1.0,fp0の1.0が整数式として素通りしてしまい値ではなく内部表現が1になる
;SZ_SINGLEはSZ_SHORTと同じ値
;.b→.sの読み替えが行われるとdc.b 1.0がSZ_SHORT==SZ_SINGLEになるのでエラーになる
;	cmpi.b	#SZ_SHORT,d0
;	beq	convrpnnum_real1	;サイズが.b→.s
	moveq.l	#-1,d0			;浮動小数点演算のオペランドならエラーで帰る
	rts				;(整数化されないようにするため)

convrpnnum_real1:
	move.l	(EXPRSPSAVE,a6),sp	;スタック補正
	move.l	(sp)+,a0		;ポインタを元に戻す
	move.b	(CMDOPSIZE,a6),-(sp)
	move.b	#SZ_EXTEND,(CMDOPSIZE,a6)
	bsr	calcfexpr		;浮動小数点式を計算する
	move.b	(sp)+,(CMDOPSIZE,a6)
	swap.w	d0
	bsr	xtol			;ロングワード整数に変換する
	tst.w	d1
	bmi	overflowerr		;オーバーフロー
	movem.l	(sp)+,d2/a1-a3
	move.w	#RPN_VALUE,(a1)		;結果を整数として格納する
	move.l	d0,(2,a1)
	clr.w	(6,a1)
	moveq.l	#0,d0
	moveq.l	#4-1,d1			;ワード数-1
	rts

;----------------------------------------------------------------
;	二項演算子を得る
getoperator:
	bsr	convgetopr
	tst.w	d0
	bmi	getoperator9
	and.w	#$00FF,d0
getoperator1:
	moveq.l	#0,d2
	move.b	(-1,a2),d2		;演算スタックの内容
	move.b	(oprprior_tbl,pc,d2.w),d2
	cmp.b	(oprprior_tbl,pc,d0.w),d2
	bhi	getoperator2
	move.b	-(a2),d2		;スタック内の演算子の方が優先順位が高いので、
	or.w	#$0600,d2		;スタックから取り出す
	move.w	d2,(a1)+
	addq.w	#1,d1
	bra	getoperator1

getoperator2:				;スタック内より優先順位が高いので、
	move.b	d0,(a2)+		;得られた演算子をスタックに積む
	moveq.l	#0,d0
	rts

getoperator9:				;演算子が得られなかった
	moveq.l	#1,d0
	rts

oprprior_tbl:				;演算子の優先順位テーブル
	.dc.b	-1			;(スタックボトム)
	.dc.b	1,1,1,1,1,1,1,1		;1:-,+,not,high,low,highw,loww,nul
	.dc.b	2,2,2,2,2,2		;2:*,/,mod,shr,shl,asr
	.dc.b	3,3			;3:-,+
	.dc.b	4,4,4,4,4,4,4,4,4,4	;4:=,<>,<,<=,>,>=,...
	.dc.b	5,6,6			;5:and 6:xor,or
	.even

;----------------------------------------------------------------
;	演算子を得る
convgetopr:
	move.w	(a0)+,d2
	move.w	d2,d0
	and.w	#$FF00,d2
	beq	convgetopr2		;(cmp.w #OT_CHAR,d2)
	cmp.w	#OT_OPERATOR,d2
	bne	convgetopr7		;演算子ではない
	cmp.b	#OP_MUL,d0
	bcs	convgetopr7		;単項演算子ならエラー
	rts

convgetopr2:				;文字演算子の場合
	lea.l	(operator_tbl,pc),a3
convgetopr3:
	move.w	(a3)+,d2
	beq	convgetopr7
	cmp.b	d0,d2
	bne	convgetopr3
	ror.w	#8,d2
	move.b	d2,d0
	bpl	convgetopr9		;1文字の演算子の場合
	neg.b	d0
	subq.b	#1,d0
	bne	convgetopr4
	move.w	(a0)+,d2		;'<'で始まる演算子
	moveq.l	#OP_SHL,d0
	cmp.w	#'<'|OT_CHAR,d2
	beq	convgetopr9		;'<<'→.shl.
	moveq.l	#OP_NE,d0
	cmp.w	#'>'|OT_CHAR,d2
	beq	convgetopr9		;'<>'→.ne.
	moveq.l	#OP_LE,d0
	cmp.w	#'='|OT_CHAR,d2
	beq	convgetopr9		;'<='→.le.
	moveq.l	#OP_LT,d0
	bra	convgetopr8		;'<' →.lt.

convgetopr4:				;'>'で始まる演算子
	subq.b	#1,d0
	bne	convgetopr5
	move.w	(a0)+,d2
	moveq.l	#OP_SHR,d0
	cmp.w	#'>'|OT_CHAR,d2
	beq	convgetopr9		;'>>'→.shr.
	moveq.l	#OP_GE,d0
	cmp.w	#'='|OT_CHAR,d2
	beq	convgetopr9		;'>='→.ge.
	moveq.l	#OP_GT,d0
	bra	convgetopr8		;'>' →.gt.

convgetopr5:				;'='で始まる演算子
	subq.b	#1,d0
	bne	convgetopr6
	moveq.l	#OP_EQ,d0
	cmpi.w	#'='|OT_CHAR,(a0)+
	beq	convgetopr9		;'=='→.eq.
	bra	convgetopr8		;'=' →.eq.

convgetopr6:				;'!'で始まる演算子
	moveq.l	#OP_NE,d0
	cmpi.w	#'='|OT_CHAR,(a0)+
	beq	convgetopr9		;'!='→.ne.
	subq.l	#2,a0
convgetopr7:
	moveq.l	#-1,d0
convgetopr8:
	subq.l	#2,a0
convgetopr9:
	rts

operator_tbl:				;1文字演算子のテーブル
	.dc.b	OP_ADD,'+',OP_SUB,'-',OP_MUL,'*',OP_DIV,'/'
	.dc.b	OP_AND,'&',OP_XOR,'^',OP_OR,'|'
	.dc.b	-1,'<',-2,'>',-3,'=',-4,'!',0,0


;----------------------------------------------------------------
;	逆ポーランド式の計算
;----------------------------------------------------------------

;----------------------------------------------------------------
;	逆ポーランド式を計算する
;	in :a1=逆ポーランド式へのポインタ
;	out:d0.w=結果の属性(0:定数/1～4:アドレス値(セクション番号)/
;			    $FFFF:未定/$01FF:オフセット付き外部参照/$02FF:外部参照値)
;	    d1.l=結果の値
calcrpn::
	movem.l	d2-d6/a0-a2,-(sp)
	lea.l	(RPNSTACK,a6),a2
;	bra	calcrpn1

calcrpn1:
	move.w	(a1)+,d0
	move.w	d0,d1
	andi.w	#$FF00,d1
	cmp.w	#RPN_VALUE,d1
	bls	calcrpnvalue		;数値
	cmp.w	#RPN_SYMBOL,d1
	beq	calcrpnsym		;シンボル
	cmp.w	#RPN_LOCATION,d1
	beq	calcrpnlocctr		;ロケーションカウンタ値
	cmp.w	#RPN_OPERATOR,d1
	beq	calcrpnopr		;演算子
calcrpn9:
	move.w	-(a2),d0		;属性
	move.l	-(a2),d1		;結果
	movem.l	(sp)+,d2-d6/a0-a2
	rts

;----------------------------------------------------------------
;	未定義シンボルが登場
;<a0.l:シンボル
calcrpnundef:
	cmpi.b	#3,(ASMPASS,a6)
	beq	calcrpnundef01		;パス3で未定義ならエラー
	movem.l	(sp)+,d2-d6/a0-a2
	moveq.l	#0,d1
	moveq.l	#-1,d0
	rts

calcrpnundef01:
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a0)	;ローカルシンボルには名前がないので
	beq	calcrpnundef02		;メッセージを分ける必要がある
	move.l	a0,(ERRMESSYM,a6)
	bra	undefsymerr

calcrpnundef02:
	cmpi.w	#100,(SYM_LOCALNO,a0)
	blo	undefsymerr_local
	bra	undefsymerr_offsym

;----------------------------------------------------------------
;	外部参照を含む演算などリンカに処理を持ち越す場合
calcrpnref:
	movem.l	(sp)+,d0/d2-d6/a0-a2	;(スタックの補正)
	moveq.l	#0,d1
	move.w	#$02FF,d0
	rts

;----------------------------------------------------------------
;	シンボル
calcrpnsym:
	movea.l	(a1)+,a0
	cmpi.b	#SA_NODET,(SYM_ATTRIB,a0)
	bls	calcrpnundef		;未定義シンボル
	cmpi.b	#SECT_RLCOMM,(SYM_EXTATR,a0)
	bcs	calcrpnsym1
	moveq.l	#0,d0			;外部参照シンボル
	move.l	d0,(a2)+
	move.b	(SYM_EXTATR,a0),d0
	move.w	d0,(a2)+
	move.w	(SYM_VALUE+2,a0),(ROFSTSYMNO,a6)
	bra	calcrpn1

calcrpnsym1:
	cmpi.b	#2,(ASMPASS,a6)
	beq	calcrpnsym2
	move.l	(SYM_VALUE,a0),(a2)+	;定義済シンボル
	clr.w	d0
	move.b	(SYM_SECTION,a0),d0
	move.w	d0,(a2)+
	move.b	(SYM_ORGNUM,a0),(EXPRORGNUM,a6)
	bra	calcrpn1

calcrpnsym2:
	move.l	(SYM_VALUE,a0),d1
	clr.w	d0
	move.b	(SYM_SECTION,a0),d0
	beq	calcrpnsym3
	cmp.b	(SECTION,a6),d0
	bne	calcrpnsym3
	move.b	(SYM_ORGNUM,a0),d2
	cmp.b	(ORGNUM,a6),d2
	bne	calcrpnsym3
	move.b	(SYM_OPTCOUNT,a0),d2
	cmp.b	(OPTCOUNT,a6),d2
	beq	calcrpnsym3
	sub.l	(LOCOFFSET,a6),d1
calcrpnsym3:
	move.l	d1,(a2)+
	move.w	d0,(a2)+
	move.b	(SYM_ORGNUM,a0),(EXPRORGNUM,a6)
	bra	calcrpn1

;----------------------------------------------------------------
;	ロケーションカウンタ値
calcrpnlocctr:
	tst.b	d0
	beq	calcrpnlocctr1
	move.l	(LOCATION,a6),d0	;'$'
	cmpi.b	#3,(ASMPASS,a6)
	bne	calcrpnlocctr0
	move.l	(LCURLOC,a6),d0
	bra	calcrpnlocctr0

calcrpnlocctr1:
	move.l	(LTOPLOC,a6),d0		;'*'
calcrpnlocctr0:
	tst.b	(OFFSYMMOD,a6)
	ble	calcrpnlocctr2
	move.l	a1,-(sp)
	movea.l	(OFFSYMTMP,a6),a1
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	beq	calcrpnlocctr3
	movea.l	a1,a0
	movea.l	(sp)+,a1
	bra	calcrpnundef

calcrpnlocctr3:
	add.l	(OFFSYMVAL,a6),d0	;+初期値
	sub.l	(SYM_VALUE,a1),d0	;-仮シンボル値
	movea.l	(sp)+,a1
calcrpnlocctr2:
	move.l	d0,(a2)+
	clr.w	d0
	move.b	(SECTION,a6),d0
	move.w	d0,(a2)+
	move.b	(ORGNUM,a6),(EXPRORGNUM,a6)
	bra	calcrpn1

;----------------------------------------------------------------
;	数値
calcrpnvalue:
	cmp.w	#RPN_VALUEB,d1
	bcs	calcrpn9
	bne	calcrpnvalue1
	and.l	#$000000FF,d0		;8bit数値
	bra	calcrpnvalue9

calcrpnvalue1:
	cmp.w	#RPN_VALUEW,d1
	bne	calcrpnvalue2
	moveq.l	#0,d0			;16bit数値
	move.w	(a1)+,d0
	bra	calcrpnvalue9

calcrpnvalue2:
	move.l	(a1)+,d0		;32bit数値
calcrpnvalue9:
	move.l	d0,(a2)+
	clr.w	(a2)+			;(定数値)
	bra	calcrpn1

;----------------------------------------------------------------
;	演算子
calcrpnopr:
	moveq.l	#0,d4
	move.b	d0,d4
	move.w	-(a2),d2		;A
	move.l	-(a2),d0
	cmp.b	#OP_MUL,d4
	bcs	calcrpnopr1		;単項演算子 (opr)A
	move.l	d0,d1
	move.w	d2,d3
	move.w	-(a2),d2		;B B(opr)A
	move.l	-(a2),d0
calcrpnopr1:
	add.w	d4,d4
	move.w	(oprjp_tbl,pc,d4.w),d4
	jsr	(oprjp_tbl,pc,d4.w)
	move.l	d0,(a2)+
	move.w	d2,(a2)+
	bra	calcrpn1

;----------------------------------------------------------------
;	演算子処理のジャンプテーブル
oprjp_tbl:
	.dc.w	0			;(ダミー)
	.dc.w	_neg-oprjp_tbl		; -	(単項演算子)
	.dc.w	_pos-oprjp_tbl		; +
	.dc.w	_not-oprjp_tbl		;.not.
	.dc.w	_high-oprjp_tbl		;.high.
	.dc.w	_low-oprjp_tbl		;.low.
	.dc.w	_highw-oprjp_tbl	;.highw.
	.dc.w	_loww-oprjp_tbl		;.loww.
	.dc.w	_nul-oprjp_tbl		;.nul.
	.dc.w	_mul-oprjp_tbl		; *	(二項演算子)
	.dc.w	_div-oprjp_tbl		; /
	.dc.w	_mod-oprjp_tbl		;.mod.
	.dc.w	_shr-oprjp_tbl		;.shr.	(>>)
	.dc.w	_shl-oprjp_tbl		;.shl.	(<<)
	.dc.w	_asr-oprjp_tbl		;.asr.
	.dc.w	_sub-oprjp_tbl		; -
	.dc.w	_add-oprjp_tbl		; +
	.dc.w	_eq-oprjp_tbl		;.eq.	(=,==)
	.dc.w	_ne-oprjp_tbl		;.ne.	(<>,!=)
	.dc.w	_lt-oprjp_tbl		;.lt.	(<)
	.dc.w	_le-oprjp_tbl		;.le.	(<=)
	.dc.w	_gt-oprjp_tbl		;.gt.	(>)
	.dc.w	_ge-oprjp_tbl		;.ge.	(>=)
	.dc.w	_slt-oprjp_tbl		;.slt.
	.dc.w	_sle-oprjp_tbl		;.sle.
	.dc.w	_sgt-oprjp_tbl		;.sgt.
	.dc.w	_sge-oprjp_tbl		;.sge.
	.dc.w	_and-oprjp_tbl		;.and.	(&)
	.dc.w	_xor-oprjp_tbl		;.xor.	(^)
	.dc.w	_or-oprjp_tbl		;.or.	(|)

;----------------------------------------------------------------
;	単項演算子
_neg:
	neg.l	d0
_pos:
	tst.w	d2
	bne	calcrpnref		;定数以外に対する演算はリンカに持ち越す
	rts

_not:
	not.l	d0
	bra	_pos

_high:
	lsr.l	#8,d0
_low:
	and.l	#$000000FF,d0
	bra	_pos

_loww:
	swap.w	d0
_highw:
	clr.w	d0
	swap.w	d0
	bra	_pos

_nul:
	moveq.l	#0,d0
	bra	_pos

;----------------------------------------------------------------
;	二項演算子
_mul:
	or.w	d3,d2
	bne	calcrpnref		;定数同士でなければリンカに持ち越す
	move.l	d0,d4			;A(=d0)×B(=d1)
	eor.l	d1,d4
	tst.l	d0
	bpl	_mul1
	neg.l	d0			;A<0
_mul1:
	tst.l	d1
	bpl	_mul2
	neg.l	d1			;B<0
_mul2:
	move.l	d0,d2
	move.l	d0,d3
	mulu.w	d1,d0			;Al×Bl
	swap.w	d2
	mulu.w	d1,d2			;Ah×Bl
	swap.w	d2
	clr.w	d2
	add.l	d2,d0			;A×Bl
	swap.w	d1
	mulu.w	d1,d3			;Al×Bh
	swap.w	d3
	clr.w	d3
	add.l	d3,d0
	tst.l	d4
	bpl	_mul3
	neg.l	d0			;結果が負
_mul3:
	moveq.l	#0,d2
	rts

_div:
	or.w	d3,d2
	bne	calcrpnref		;定数同士でなければリンカに持ち越す
_divl:
	move.l	d0,d4			;A(=d0)÷B(=d1)
	move.l	d0,d5
	eor.l	d1,d4
	tst.l	d0
	bpl	_divl1
	neg.l	d0			;A<0
_divl1:
	tst.l	d1
	beq	divzeroerr		;除数が0
	bpl	_divl2
	neg.l	d1			;B<0
_divl2:
	moveq.l	#0,d2			;余り
	moveq.l	#0,d3			;商
	moveq.l	#32-1,d6
_divl3:
	add.l	d3,d3			;d2.l←d0.l←d3.l
	roxl.l	#1,d0
	roxl.l	#1,d2
	cmp.l	d1,d2
	bcs	_divl4
	sub.l	d1,d2
	addq.l	#1,d3
_divl4:
	dbra	d6,_divl3
	move.l	d3,d0
	tst.l	d4
	bpl	_divl5
	neg.l	d0			;結果が負
_divl5:
	move.l	d2,d1
	tst.l	d5
	bpl	_divl6
	neg.l	d1			;余りが負
_divl6:
	moveq.l	#0,d2
	rts

_mod:
	or.w	d3,d2
	bne	calcrpnref		;定数同士でなければリンカに持ち越す
	bsr	_divl
	move.l	d1,d0
	rts

_sub:
	cmp.w	#SECT_RLCOMM,d2
	bcc	_sub3
	cmp.w	#SECT_RLCOMM,d3
	bcc	calcrpnref		;<??>-<外部>
	cmp.w	d2,d3
	bne	_sub2
	tst.w	d2
	beq	_sub1
	cmpi.b	#1,(ASMPASS,a6)		;<アドレス>-<アドレス> (同じセクション)
	bne	_sub1
	tst.b	(OPTIMIZE,a6)
	beq	calcrpnref		;最適化をする場合のパス1なら保留
_sub1:
	moveq.l	#0,d2			;<定数>-<定数>
_sub15:
	sub.l	d1,d0
	rts

_sub2:					;セクションが違う場合
	tst.w	d2
	beq	calcrpnref		;<定数>-<アドレス>
	tst.w	d3
	bne	calcrpnref		;<アドレス>-<アドレス>
	cmpi.b	#1,(ASMPASS,a6)		;<アドレス>-<定数>
	bne	_sub15
	tst.b	(OPTIMIZE,a6)
	beq	calcrpnref		;最適化をする場合のパス1なら保留
	bra	_sub15

_sub3:
	tst.w	d3
	bne	calcrpnref		;<外部>-<外部>/<外部>-<アドレス>
	move.w	#$01FF,d2		;<外部>-<定数>(オフセット付き外部参照)
	bra	_sub15

_add:
	cmp.w	#SECT_RLCOMM,d2
	bcc	_add3			;<外部>+<??>
	cmp.w	#SECT_RLCOMM,d3
	bcc	_add4			;<??>+<外部>
	move.w	d3,d4
	or.w	d2,d4
	bne	_add1
	add.l	d1,d0			;<定数>+<定数>
	rts

_add1:
	tst.w	d3
	beq	_add2
	tst.w	d2
	bne	calcrpnref		;<アドレス>+<アドレス>
_add2:
	cmpi.b	#1,(ASMPASS,a6)		;<アドレス>+<定数>/<定数>+<アドレス>
	bne	_add25
	tst.b	(OPTIMIZE,a6)
	beq	calcrpnref		;最適化をする場合のパス1なら保留
_add25:
	add.l	d1,d0
	add.l	d3,d2
	rts

_add3:
	exg.l	d0,d1
	exg.l	d2,d3
_add4:
	cmp.w	#SECT_RLCOMM,d2
	bcc	calcrpnref		;<外部>+<外部>
	tst.w	d2
	bne	calcrpnref		;<アドレス>+<外部>
	add.l	d1,d0			;<定数>+<外部>
	move.w	#$01FF,d2		;(オフセット付き外部参照)
	rts

_shr:
	lsr.l	d1,d0
_shr9:
	or.w	d3,d2
	bne	calcrpnref		;定数同士でなければリンカに持ち越す
	rts

_shl:
	lsl.l	d1,d0
	bra	_shr9

_asr:
	asr.l	d1,d0
	bra	_shr9

_eq:
	cmp.l	d1,d0
	seq.b	d0
_eq9:
	ext.w	d0
	ext.l	d0
	bra	_shr9

_ne:
	cmp.l	d1,d0
	sne.b	d0
	bra	_eq9

_lt:
	cmp.l	d1,d0
	scs.b	d0
	bra	_eq9

_le:
	cmp.l	d1,d0
	sls.b	d0
	bra	_eq9

_gt:
	cmp.l	d1,d0
	shi.b	d0
	bra	_eq9

_ge:
	cmp.l	d1,d0
	scc.b	d0
	bra	_eq9

_slt:
	cmp.l	d1,d0
	slt.b	d0
	bra	_eq9

_sle:
	cmp.l	d1,d0
	sle.b	d0
	bra	_eq9

_sgt:
	cmp.l	d1,d0
	sgt.b	d0
	bra	_eq9

_sge:
	cmp.l	d1,d0
	sge.b	d0
	bra	_eq9

_and:
	and.l	d1,d0
	bra	_shr9

_xor:
	eor.l	d1,d0
	bra	_shr9

_or:
	or.l	d1,d0
	bra	_shr9


;----------------------------------------------------------------
	.end
