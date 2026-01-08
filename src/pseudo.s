;----------------------------------------------------------------
;	X68k High-speed Assembler
;		疑似命令のアセンブル処理
;		< pseudo.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2016  by M.Kamada
;			  2025       by TcbnErik
;----------------------------------------------------------------

	.include	has.equ
	.include	doscall.mac
	.include	cputype.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	疑似命令のアセンブル処理
;----------------------------------------------------------------
dopseudo::
	movea.l	(LINEPTR,a6),a0
	move.l	(SYM_FUNC,a1),a2
	jmp	(a2)			;処理ルーチンへジャンプ

;----------------------------------------------------------------
;	オペランドの値を計算する
calcopr:
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	bra	calcrpn

;----------------------------------------------------------------
;	オペランドの値を計算する(定数でなければエラー)
calcconst::
	bsr	encodeopr
	bsr	calcopr
	tst.w	d0
	bne	iloprerr		;<式>が定数でない
	rts

;----------------------------------------------------------------
;	ifの条件式の値を得る
ifcond:
	bsr	encodeopr
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr		;<式>が定数でない
pseudo_tail_check:
	tst.w	(a0)
	bne	iloprerr_pseudo_tail
	rts

;----------------------------------------------------------------
iloprerr_pseudo_tail:
	cmpi.w	#','|OT_CHAR,(a0)	;行が終了していない
	beq	iloprerr_pseudo_many
	bra	iloprerr

;----------------------------------------------------------------
;	.align	<式>[,<パディング値>]
~~align::
	tst.b	(OFFSYMMOD,a6)
	bgt	offsymalignerr		;.offsymでシンボル指定があるときアラインメント処理できない
	bsr	calcconst
	move.l	d1,d2
	moveq.l	#2,d0
	cmp.l	d0,d2
	bcs	ilvalueerr		;<式>が0か1ならエラー
	move.w	#T_ALIGN|$FF,d0
~~align1:
	addq.b	#1,d0
	lsr.l	#1,d2
	bcc	~~align1
	bne	ilvalueerr		;2の累乗でないのでエラー
	cmp.b	#8,d0
	bhi	ilvalueerr		;2^8(=256)より大きければエラー
	move.w	(a0)+,d2
	beq	~~align4		;パディング値の指定がない
	cmp.w	#','|OT_CHAR,d2
	bne	iloprerr
	movem.l	d0-d1,-(sp)
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr		;<式>が定数でない
	moveq.l	#SZ_WORD,d2
	bsr	chkdtsize		;式の値がワードの範囲内か調べる
	tst.w	(a0)
	bne	iloprerr_pseudo_tail
	move.l	d1,d3
	movem.l	(sp)+,d0-d1
	bra	~~align5

~~align4:
	moveq.l	#0,d3			;パディング値
	cmpi.b	#SECT_TEXT,(SECTION,a6)
	bne	~~align5
	move.w	#$4E71,d3		;.textセクションでは境界をnopで埋める
~~align5:
	tst.b	(SECTION,a6)
	beq	~~align6
	st.b	(MAKEALIGN,a6)		;オブジェクトファイルにアラインメント情報を出力する
	cmp.b	(MAXALIGN,a6),d0
	bls	~~align6
	move.b	d0,(MAXALIGN,a6)	;ソース中で最大のアライン値の場合
~~align6:
	bsr	wrtobjd0w
	move.w	d3,d0
	bsr	wrtd0w			;パディング値
	subq.l	#1,d1
	move.l	(LOCATION,a6),d0
	move.l	d0,d2
	add.l	d1,d0
	not.l	d1
	and.l	d1,d0
	move.l	d0,(LOCATION,a6)
	move.l	d0,(LTOPLOC,a6)
	sub.l	d2,d0			;パディング長
	bra	wrtd0w			;(最大255bytesなのでワードでOk)

;----------------------------------------------------------------
;	.quad
~~quad::
	tst.b	(OFFSYMMOD,a6)
	bgt	offsymalignerr		;.offsymでシンボル指定があるときアラインメント処理できない
	move.w	#T_ALIGN|2,d0		;.quad = .align 4(=2^2)
	moveq.l	#4,d1
	bra	~~align4

;----------------------------------------------------------------
;	.even
~~even::
	tst.b	(OFFSYMMOD,a6)
	bgt	offsymalignerr		;.offsymでシンボル指定があるときアラインメント処理できない
	btst.b	#0,(LOCATION+3,a6)
	beq	~~even1
	moveq.l	#0,d0
	bsr	wrt1bobj		;$00を出力して偶数境界に合わせる
	addq.l	#1,(LTOPLOC,a6)
~~even1:
	rts

;----------------------------------------------------------------
f43gcut::
	tst.b	(F43GTEST,a6)
	beq	f43gcut1
	move.l	a0,-(sp)
	movea.l	(F43GPTR,a6),a0
	movea.l	(a0),a0			;次のレコード
	move.l	a0,(F43GPTR,a6)
;	clr.l	(8,a0)
	clr.w	(12,a0)
	movea.l	(sp)+,a0
f43gcut1:
	rts

;----------------------------------------------------------------
;	.dc[.<サイズ>]	<式>[,<式>,…]
~~dc::
	bsr	f43gcut
	bsr	encodeopr
	move.b	(CMDOPSIZE,a6),d0
	bmi	~~dc0
	cmp.b	#SZ_SINGLE,d0
	bcc	dodcreal		;浮動小数点実数の.dc
	tst.b	d0
	bne	~~dc1
	move.b	#SZ_SHORT,(CMDOPSIZE,a6)	;.b→.s
	bra	~~dc2

~~dc0:
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
~~dc1:
~~dc2:
	movea.l	(OPRBUFPTR,a6),a0
~~dc3:
	bsr	dodcparam		;パラメータ1つについて処理
	move.w	(a0)+,d0
	beq	~~dc9
	cmp.w	#','|OT_CHAR,d0
	beq	~~dc3
	bra	iloprerr

~~dc9:
	rts

;----------------------------------------------------------------
;	.dcのパラメータ1つの処理
dodcparam:
	move.w	(a0),d0
	beq	iloprerr		;パラメータがない
	cmp.w	#','|OT_CHAR,d0
	beq	dodcparam9		;','のみ
	and.w	#$FF00,d0
	cmp.w	#OT_STR,d0		;文字列
	bne	dodcnum
dodcparam01:
	movea.l	a0,a1
	moveq.l	#0,d0
	move.b	(1,a0),d0		;文字列長
	cmpi.b	#OT_STR_WORDLEN,d0
	bne	@f
	move.w	(2,a0),d0		;$ffの場合のみ、続くワードが文字列長
	addq.l	#2,d0
@@:
	addq.l	#3,d0
	bclr.l	#0,d0
	adda.l	d0,a1			;文字列の終了アドレス
	move.w	(a1),d0
	beq	dodcstr			;文字列のみの場合
	cmp.w	#','|OT_CHAR,d0
	beq	dodcstr
	and.w	#$FF00,d0
	cmp.w	#OT_STR,d0
	bne	dodcnum
	bsr	dodcstr			;とりあえず1番目の文字列を処理しておく
	bra	dodcparam01

dodcnum:				;パラメータ式
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式が変換できない
	move.w	d1,d2
	bsr	calcrpn
	move.w	d0,d3
	move.b	(EXPRSIZE,a6),d0	;式のサイズ
	bpl	dodcnum11
	cmpi.b	#OT_SIZE>>8,(a0)
	bne	dodcnum1		;式に後続するサイズ指定がない
	move.w	(a0)+,d0		;式に後続するサイズ
dodcnum11:
	tst.b	d0			;cmp.b #SZ_BYTE,d0
	bne	dodcnum0
	move.b	#SZ_SHORT,d0		;.b→.s
	bra	dodcnum3

dodcnum0:
	cmp.b	#SZ_SINGLE,d0
	bcc	ilsizeerr		;実数は受け付けない(.bの意味になっていた.sも不可)
	bra	dodcnum2		;サイズ指定がある

dodcnum1:
	move.b	(CMDOPSIZE,a6),d0	;サイズ指定がないので.dcのサイズを使う
dodcnum2:
	cmp.b	#SZ_SHORT,d0
	beq	dodcnum3
	btst.b	#0,(LOCATION+3,a6)
	beq	dodcnum3
	bsr	alignwarn		;偶数境界に合っていないのでワーニングを出す
dodcnum3:
	tst.w	d3
	beq	wrtimm			;定数ならファイルに出力
	cmp.b	#SZ_SHORT,d0
	beq	dodcnumb
	cmp.b	#SZ_WORD,d0
	beq	dodcnumw
	add.l	#2,(LOCATION,a6)	;.l
dodcnumw:
	add.l	#1,(LOCATION,a6)
dodcnumb:
	add.l	#1,(LOCATION,a6)
	move.w	d2,d1			;式のワード数
	bra	wrtrpn			;式をファイルに出力

dodcstr:				;パラメータ文字列
	move.w	(a0)+,d1		;d1.b=文字列長
	and.w	#$00FF,d1
	beq	dodcstrlw9		;ヌルストリング
	cmp.w	#OT_STR_WORDLEN,d1
	bne	@f
	move.w	(a0)+,d1		;$ffの場合のみ、続くワードが文字列長
@@:
	move.b	(CMDOPSIZE,a6),d2
	cmp.b	#SZ_SHORT,d2
	beq	dodcstrb
	ext.w	d2			;.w/.lでの文字列書き込み
	add.w	d2,d2
	subq.w	#1,d2
dodcstrlw:
	moveq.l	#0,d0
	move.w	d2,d3
dodcstrlw1:
	lsl.l	#8,d0
	move.b	(a0)+,d0
	subq.w	#1,d1
	dbeq	d3,dodcstrlw1
	cmpi.b	#SZ_WORD,(CMDOPSIZE,a6)
	beq	dodcstrlw2
	bsr	wrt1lobj
	bra	dodcstrlw3

dodcstrlw2:
	bsr	wrt1wobj
dodcstrlw3:
	tst.w	d1
	bne	dodcstrlw
dodcstrlw9:
	move.l	a0,d0
	doeven	d0
	movea.l	d0,a0
dodcparam9:
	rts

dodcstrb:				;.bでの文字列書き込み
	move.b	(a0)+,d0
	bsr	wrt1bobj
	subq.w	#1,d1
	bne	dodcstrb
	bra	dodcstrlw9

;----------------------------------------------------------------
;	浮動小数点実数の.dc
dodcreal:
	btst.b	#0,(LOCATION+3,a6)
	beq	dodcreal1
	bsr	alignwarn		;偶数境界に合っていないのでワーニングを出す
dodcreal1:
	movea.l	(OPRBUFPTR,a6),a0
	tst.w	(a0)
	beq	iloprerr		;パラメータがない
dodcreal2:
	lea.l	(RPNBUFEX,a6),a3	;オペランド用バッファ
	bsr	getdcreal		;浮動小数点実数オペランドを得る
dodcreal3:
	move.l	(a3)+,d0
	bsr	wrt1lobj		;得られたデータを出力する
	dbra	d5,dodcreal3
	move.w	(a0)+,d0
	beq.s	dodcreal9
	cmp.w	#','|OT_CHAR,d0
	beq	dodcreal2
	bra	iloprerr

;----------------------------------------------------------------
;	浮動小数点実数オペランドを一つ得る
getdcreal:
	movea.l	a3,a4
	move.b	(CMDOPSIZE,a6),d0
	bsr	getfplen		;データ長を得る
	move.w	d0,d4
	move.w	d1,d3
	move.w	d1,d5
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bpl	getdcreal7		;内部表現形式の値を得る
	bsr	calcfexpr		;浮動小数点式を得る
	movem.l	d0-d2,(a3)
dodcreal9:
	rts

getdcreal7:
	tst.w	d3
	bne	getdcreal6		;倍精度または拡張精度
	bsr	internalfpwarn		;整数を単精度浮動小数点数の内部表現と見なします
	bra	getdcreal6

getdcreal5:
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	iloprerr_internalfp	;浮動小数点数の内部表現の長さが合いません
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	iloprerr		;式が得られない
getdcreal6:
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr_not_fixed	;式が定数でない
	move.l	d1,(a4)+
	dbra	d3,getdcreal5
~~dcb9:
	rts

;----------------------------------------------------------------
;	.dcb[.<サイズ>]	<長さ>,<式>
~~dcb::
	bsr	encodeopr
	tst.b	(CMDOPSIZE,a6)
	beq	~~dcb1			;.bの場合
	btst.b	#0,(LOCATION+3,a6)
	beq	~~dcb1
	bsr	alignwarn		;偶数境界に合っていないのでワーニングを出す
~~dcb1:
	bsr	calcopr
	tst.w	d0
	bne	ilvalueerr		;<長さ>が定数でない
	tst.l	d1
	beq.s	~~dcb9			;<長さ>が0の場合は何もしない
	cmp.l	#$01000000,d1
	bhi	ilvalueerr		;<長さ>は1～16M
	move.l	d1,-(sp)
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	iloprerr		;,<式>がない
	cmpi.b	#SZ_SINGLE,(CMDOPSIZE,a6)
	bge	~~dcb10			;浮動小数点実数の.dcb
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	move.l	(sp),d0			;<長さ>
	move.b	(CMDOPSIZE,a6),d2
	bmi	~~dcb2
	bne	~~dcb3
	move.b	#SZ_SHORT,(CMDOPSIZE,a6)	;.b→.s
	bra	~~dcb7

~~dcb2:
	move.b	#SZ_WORD,(CMDOPSIZE,a6)	;省略時は.w
	bra	~~dcb6

~~dcb3:
	cmp.b	#SZ_WORD,d2
	beq	~~dcb6
	add.l	d0,d0			;.l
~~dcb6:
	add.l	d0,d0			;.w
~~dcb7:
	add.l	d0,(LOCATION,a6)
	move.w	#T_DCB,d0
	bsr	wrtobjd0w
	move.l	(sp)+,d0
	bsr	wrtd0l			;長さ
	move.b	(CMDOPSIZE,a6),d0
	bra	wrtrpn

~~dcb10:				;浮動小数点実数の.dcb
	lea.l	(RPNBUFEX,a6),a3	;オペランド用バッファ
	bsr	getdcreal		;浮動小数点実数オペランドを得る
	move.w	d5,d4
	move.l	(sp),d0			;<長さ>
	lsl.l	#2,d0
~~dcb11:
	add.l	d0,(LOCATION,a6)
	dbra	d5,~~dcb11
	move.w	#T_FDCB,d0
	move.b	d4,d0			;データ長-1
	bsr	wrtobjd0w
	move.l	(sp)+,d0
	bsr	wrtd0l			;長さ
	moveq.l	#3-1,d1
~~dcb12:
	move.l	(a3)+,d0
	bsr	wrtd0l			;シンボル値
	dbra	d1,~~dcb12
	rts

;----------------------------------------------------------------
;	.ds[.<サイズ>]	<長さ>
~~ds::
	bsr	deflabel		;行頭のラベルを定義
	move.w	#-1,(LABNAMELEN,a6)
	bsr	encodeopr
	bsr	calcopr
	tst.w	d0
	bne	ilvalueerr		;<長さ>が定数でない
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	tst.l	d1
	bmi	ds_iloprerr_ds_negative
~~ds_0:
	move.b	(CMDOPSIZE,a6),d0
	bmi	~~ds_w
	tst.b	d0			;cmp.b #SZ_BYTE,d0
	beq	~~ds_b
	cmp.b	#SZ_WORD,d0
	beq	~~ds_w
	cmp.b	#SZ_LONG,d0
	beq	~~ds_l
	cmp.b	#SZ_SINGLE,d0
	beq	~~ds_s
	cmp.b	#SZ_DOUBLE,d0
	beq	~~ds_d
	move.l	d1,d2			;.x/.p	(12bytes)
	add.l	d2,d1
	add.l	d2,d1			;3×4=12倍
	bra	~~ds_l

~~ds_d:					;.d	(8bytes)
	add.l	d1,d1
~~ds_l:					;.l/.s	(4bytes)
~~ds_s:
	add.l	d1,d1
~~ds_w:					;.w	(2bytes)
	add.l	d1,d1
	btst.b	#0,(LOCATION+3,a6)
	beq	~~ds_b
	bsr	alignwarn		;偶数境界に合っていないのでワーニングを出す
~~ds_b:					;.b	(1byte)
	add.l	d1,(LOCATION,a6)
	move.w	#T_DS,d0
	bsr	wrtobjd0w
	move.l	d1,d0
	bra	wrtd0l			;長さ(バイト単位)

ds_iloprerr_ds_negative:
	move.b	(SECTION,a6),d0
	subq.b	#SECT_TEXT,d0
	beq	iloprerr_ds_negative
	subq.b	#SECT_DATA-SECT_TEXT,d0
	beq	iloprerr_ds_negative
	bsr	ds_negative_warn
	bra	~~ds_0

;----------------------------------------------------------------
;	.fpid	<式>	(0～7)
~~fpid::
	bsr	calcconst
	tst.l	d1
	bmi	~~fpid9
	cmp.l	#7,d1
	bhi	ilvalueerr
	ror.w	#7,d1			;コプロセッサIDフィールドはb9～11
	move.w	d1,(FPCPID,a6)
	rts

~~fpid9:				;負の値が指定されたらFPP命令を禁止する
	andi.w	#CFPP.xor.$FFFF,(CPUTYPE,a6)
	rts

;----------------------------------------------------------------
;	.pragma	<最適化指定オペランド>
~~pragma::
	rts

;----------------------------------------------------------------
;	<シンボル>	fset[.<サイズ>]	<式>
~~fset::
	moveq.l	#ST_REAL,d2
	bsr	defltopsym		;行頭のシンボルを定義する
	bra	~~fequ1

;----------------------------------------------------------------
;	<シンボル>	fequ[.<サイズ>]	<式>
~~fequ::
	moveq.l	#ST_REAL,d2
	bsr	defltopsym		;行頭のシンボルを定義する
	tst.w	d2
	bmi	pseudo_redeferr_a1	;すでに定義済み
~~fequ1:
	movea.l	a1,a2			;シンボルテーブルへのポインタ
	move.l	(TEMPPTR,a6),d0
	doquad	d0
	movea.l	d0,a3
	move.l	d0,(SYM_FVPTR,a2)	;シンボル値へのポインタ
	addq.l	#8,d0
	addq.l	#4,d0			;(最大で12bytes)
	move.l	d0,(TEMPPTR,a6)
	bsr	memcheck
	st.b	(SYM_FSIZE,a2)		;(move.b #-1,(SYM_FSIZE,a2))
	movea.l	(OPRBUFPTR,a6),a0
	bsr	getdcreal		;浮動小数点実数オペランドを得る
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	move.w	#T_FEQUSET,d0		;fequ/fset
	move.b	d4,(SYM_FSIZE,a2)	;サイズ
	move.b	d4,d0
	bsr	wrtobjd0w
	move.l	a2,d0
	bsr	wrtd0l			;シンボルへのポインタ
	move.l	(SYM_FVPTR,a2),a1
	moveq.l	#3-1,d1
~~fequ6:
	move.l	(a1)+,d0
	bsr	wrtd0l			;シンボル値
	dbra	d1,~~fequ6
	rts

;----------------------------------------------------------------
;	行頭のシンボルを定義する
defltopsym:
	move.w	d2,-(sp)
	bsr	encodeopr
	move.w	(LABNAMELEN,a6),d1
	bmi	nosymerr_pseudo		;定義すべきシンボルがない
	move.w	#-1,(LABNAMELEN,a6)	;定義するのでラベルを取り消す
	movea.l	(LABNAMEPTR,a6),a0
	bsr	isdefdsym
	move.w	(sp)+,d2
	tst.w	d0
	bne	defsymbol		;未登録なら新しく登録する
	cmp.b	(SYM_TYPE,a1),d2	;シンボルのタイプ
	bne	defltopsym02		;タイプの異なるシンボルと重複している
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
	bne	defltopsym99
	cmpi.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)
	beq	defltopsym01		;プレデファインシンボルを再定義しようとした
defltopsym99:
	moveq.l	#-1,d2
	rts

defltopsym01:
	move.l	a1,(ERRMESSYM,a6)
	bra	redeferr_predefine

defltopsym02:
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
	bne	pseudo_ilsymerr_a1	;タイプの異なるシンボルと重複している
	cmpi.b	#SA_UNDEF,(SYM_ATTRIB,a1)
	bne	pseudo_ilsymerr_a1	;タイプの異なるシンボルと重複している
	move.l	a1,(ERRMESSYM,a6)
	bra	ilsymerr_lookfor	;シンボルの前方参照の条件と矛盾している

;----------------------------------------------------------------
pseudo_ilsymerr_a1:
	move.l	a1,(ERRMESSYM,a6)
	move.b	(SYM_TYPE,a1),d0
	beq	ilsymerr_value		;ST_VALUE
	subq.b	#ST_REAL,d0
	bcs	ilsymerr_local		;ST_LOCAL
	beq	ilsymerr_real		;ST_REAL
	subq.b	#ST_REGSYM-ST_REAL,d0
	beq	ilsymerr_regsym		;ST_REGSYM
	bra	ilsymerr_register	;ST_REGISTER

;----------------------------------------------------------------
pseudo_redeferr_a0:
	move.l	a0,(ERRMESSYM,a6)
	bra	redeferr

;----------------------------------------------------------------
pseudo_redeferr_a1:
	move.l	a1,(ERRMESSYM,a6)
	bra	redeferr

;----------------------------------------------------------------
;	<シンボル>	set	<式>
~~set::
	moveq.l	#ST_VALUE,d2
	bsr	defltopsym		;行頭のシンボルを定義する
	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	beq	~~set1			;未定義
	tst.b	(SYM_FIRST,a1)
	blt	~~set1			;setで定義されている
	move.l	a1,(ERRMESSYM,a6)
	tst.b	(OWSET,a6)
	bne	redeferr_set
	bsr	redefwarn_set
~~set1:
	st.b	(SYM_FIRST,a1)
	moveq.l	#-1,d2
	bra	~~equ1

;----------------------------------------------------------------
;	<シンボル>	equ	<式>
~~equ::
	moveq.l	#ST_VALUE,d2
	bsr	defltopsym		;行頭のシンボルを定義する
	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	bne	pseudo_redeferr_a1	;定義済シンボルならエラー
	sf.b	(SYM_FIRST,a1)
	moveq.l	#0,d2
~~equ1:
	cmpi.b	#SECT_RLCOMM,(SYM_EXTATR,a1)
	bcc	pseudo_redeferr_a1	;.xref/.commシンボルだった
	movea.l	a1,a2			;シンボルテーブルへのポインタ
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bne	exprerr			;式が数値のみではないのでエラー
	move.w	d1,d3			;式のワード数
	bsr	calcrpn
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	movea.l	a2,a1
	tst.b	d0
	bne	~~equ2			;式が定数でない
	clr.w	(SYM_SECTION,a1)	;(SYM_ORGNUM)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	move.l	d1,(SYM_VALUE,a1)	;シンボル値
	move.w	#T_EQUCONST,d0		;定数のequ/set
	bsr	wrtobjd0w
	move.l	a1,d0
	bsr	wrtd0l			;シンボルへのポインタ
	move.l	d1,d0
	bsr	wrtd0l			;シンボル値
	bra	~~equ3

~~equ2:
	move.b	#SA_NODET,(SYM_ATTRIB,a1)	;値が未定のシンボル
	move.w	#T_EQUEXPR,d0		;式・アドレスのequ/set
	bsr	wrtobjd0w
	move.l	a1,d0
	bsr	wrtd0l			;シンボルへのポインタ
	lea.l	(RPNBUF,a6),a1
	move.w	d3,d1			;式のワード数
	moveq.l	#SZ_LONG,d0
	bsr	wrtrpn			;式を出力
~~equ3:
	tst.b	(LABXDEF,a6)
	beq	~~equ9			;外部定義はしない
	movea.l	a2,a1
	move.b	#SECT_XDEF,(SYM_EXTATR,a1)
~~equ9:
	rts

;----------------------------------------------------------------
;	<シンボル>	reg	<レジスタリスト>
~~reg::
	moveq.l	#ST_REGSYM,d2
	bsr	defltopsym		;行頭のシンボルを定義する
	movea.l	(OPRBUFPTR,a6),a2
	move.l	(TEMPPTR,a6),d0
	doeven	d0
	movea.l	d0,a0
	move.l	d0,(SYM_DEFINE,a1)	;定義内容へのポインタ
	clr.w	d1
~~reg3:
	move.w	(a2)+,d0
	move.w	d0,(a0)+
	beq	~~reg9			;中間コードが終了
	addq.w	#1,d1
	moveq.l	#0,d2
	move.b	d0,d2
	clr.b	d0
	cmp.w	#OT_VALUEW,d0
	beq	~~reg5
	cmp.w	#OT_LOCALREF,d0
	beq	~~reg5
	cmp.w	#OT_VALUE,d0
	beq	~~reg6
	cmp.w	#OT_SYMBOL,d0
	beq	~~reg6
	cmp.w	#OT_VALUEQ,d0
	beq	~~reg8
	cmp.w	#OT_REAL,d0
	beq	~~reg7
	cmp.w	#OT_STR,d0
	bne	~~reg3
	tst.b	d2			;文字列
	beq	~~reg3			;ヌルストリング
	cmp.b	#OT_STR_WORDLEN,d2
	bne	~~reg4
	move.w	(a2)+,d2		;$ffの場合のみ、続くワードが文字列長
	move.w	d2,(a0)+
	addq.w	#1,d1
~~reg4:
	move.w	(a2)+,(a0)+		;文字列の内容を転送
	addq.w	#1,d1
	subq.w	#2,d2
	bhi	~~reg4
	bra	~~reg3

~~reg5:					;16bit数値/ローカルラベル参照
	move.w	(a2)+,(a0)+
	addq.w	#1,d1
	bra	~~reg3

~~reg6:					;32bit数値/シンボル
	move.l	(a2)+,(a0)+
	addq.w	#2,d1
	bra	~~reg3

~~reg7:					;浮動小数点実数
	move.w	(a2)+,(a0)+
	move.l	(a2)+,(a0)+
	move.l	(a2)+,(a0)+
	addq.w	#5,d1
	bra	~~reg3

~~reg8:					;64bit数値
	move.l	(a2)+,(a0)+
	move.l	(a2)+,(a0)+
	addq.w	#4,d1
	bra	~~reg3

~~reg9:					;定義内容をすべて転送した
	move.l	a0,(TEMPPTR,a6)
	move.w	d1,(SYM_DEFLEN,a1)	;中間コードのワード数
	bra	memcheck

;----------------------------------------------------------------
;	.xdef	<シンボル>[,<シンボル>,…]
~~xdef::
	moveq.l	#SECT_XDEF,d2
	bra	~~globl1

;---------------------------------------------------------------
;	.xref	<シンボル>[,<シンボル>,…]
~~xref::
	moveq.l	#SECT_XREF,d2
	bra	~~globl1

;---------------------------------------------------------------
;	.globl	<シンボル>[,<シンボル>,…]
~~globl::
	moveq.l	#SECT_GLOBL,d2
~~globl1:
	move.w	d2,-(sp)
	bsr	encodeopr
	move.w	(sp)+,d2
	movea.l	(OPRBUFPTR,a6),a1
~~globl2:
	move.w	(a1)+,d0
	cmp.w	#OT_SYMBOL,d0
	bne	iloprerr		;シンボル以外の記述はエラー
	move.l	(a1)+,a0		;シンボルテーブルへのポインタ
	tst.b	(SYM_TYPE,a0)		;cmpi.b #ST_VALUE,(SYM_TYPE,a0)
	bne	iloprerr		;数値シンボルでないのでエラー
	cmpi.b	#SA_PREDEFINE,(SYM_ATTRIB,a0)
	beq	~~globl00		;プレデファインシンボルは外部宣言できない
	move.b	(SYM_EXTATR,a0),d1
	beq	~~globl3
	cmp.b	#SECT_RLCOMM,d1
	bcs	pseudo_redeferr_a0
	cmp.b	#SECT_COMM,d1
	bhi	pseudo_redeferr_a0	;すでに外部宣言されている(.comm以外)
~~globl3:
	tst.b	(SYM_ATTRIB,a0)
	beq	~~globl4		;未定義シンボル
	cmpi.b	#SECT_XREF,d2
	beq	pseudo_redeferr_a0	;定義済シンボルに対する.xrefはエラー
~~globl4:
	move.b	d2,(SYM_EXTATR,a0)	;外部宣言属性をセット
	cmpi.b	#SECT_XDEF,d2
	bne	~~globl5
	move.w	#T_XDEF,d0
	bsr	wrtobjd0w
	move.l	a0,d0			;シンボルへのポインタ
	bsr	wrtd0l
~~globl5:
	move.w	(a1)+,d0
	beq	~~globl9
	cmp.w	#','|OT_CHAR,d0
	beq	~~globl2		;まだシンボルがある
	bra	iloprerr

~~globl9:
	rts

~~globl00:
	move.l	a0,(ERRMESSYM,a6)
	cmp.b	#SECT_XDEF,d2
	beq	ilsymerr_predefxdef
	cmp.b	#SECT_XREF,d2
	beq	ilsymerr_predefxref
	cmp.b	#SECT_GLOBL,d2
	bra	ilsymerr_predefglobl

;---------------------------------------------------------------
;	.rcomm/.rlcomm
~~rcomm::
	move.w	#SECT_RCOMM,d2
	bra	~~comm1

~~rlcomm::
	move.w	#SECT_RLCOMM,d2
	bra	~~comm1

;---------------------------------------------------------------
;	.comm	<シンボル>,<式>
~~comm::
	move.w	#SECT_COMM,d2
~~comm1:
	move.w	d2,-(sp)
	bsr	encodeopr
	move.w	(sp)+,d2
	movea.l	(OPRBUFPTR,a6),a1
	move.w	(a1)+,d0
	cmp.w	#OT_SYMBOL,d0
	bne	iloprerr		;シンボル以外の記述はエラー
	move.l	(a1)+,a0		;シンボルテーブルへのポインタ
	tst.b	(SYM_TYPE,a0)		;cmpi.b #ST_VALUE,(SYM_TYPE,a0)
	bne	iloprerr		;数値シンボルでないのでエラー
	tst.b	(SYM_ATTRIB,a0)
	bne	pseudo_redeferr_a0	;定義済シンボルならエラー
;プレデファインシンボルは上で弾かれるのでこのままでよい
	move.b	d2,(SYM_EXTATR,a0)
	cmpi.w	#','|OT_CHAR,(a1)+
	bne	iloprerr		;,<式>がない
	move.l	a0,-(sp)
	movea.l	a1,a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	tst.b	(EXPRISSTR,a6)
	bne	iloprerr		;式に文字列を含んでいた
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr		;式が定数でない
	tst.l	d1
	ble	ilvalueerr		;式が負か0だった
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	movea.l	(sp)+,a0
	move.l	d1,(SYM_VALUE,a0)	;コモンエリアサイズをセット
	rts

;---------------------------------------------------------------
;	.text
~~text::
	moveq.l	#SECT_TEXT,d0
~~text1:
;offsymの終了はセクションの変更が完了してから行うこと
;d0=セクション
	move.b	(OFFSYMMOD,a6),-(sp)
	sf.b	(OFFSYMMOD,a6)
	bsr	chgsection
	or.w	#T_SECT,d0		;セクション変更
	bsr	wrtobjd0w
	tst.b	(sp)+
	bgt	offsymtailchk1
	rts

;---------------------------------------------------------------
;	.data
~~data::
	moveq.l	#SECT_DATA,d0
	bra	~~text1

;---------------------------------------------------------------
;	.bss
~~bss::
	moveq.l	#SECT_BSS,d0
	bra	~~text1

;---------------------------------------------------------------
;	.stack
~~stack::
	moveq.l	#SECT_STACK,d0
	bra	~~text1

;---------------------------------------------------------------
~~rdata::
	moveq.l	#SECT_RDATA,d0
~~rdata1:
	st.b	(MAKERSECT,a6)
	bra	~~text1

~~rbss::
	moveq.l	#SECT_RBSS,d0
	bra	~~rdata1

~~rstack::
	moveq.l	#SECT_RSTACK,d0
	bra	~~rdata1

~~rldata::
	moveq.l	#SECT_RLDATA,d0
	bra	~~rdata1

~~rlbss::
	moveq.l	#SECT_RLBSS,d0
	bra	~~rdata1

~~rlstack::
	moveq.l	#SECT_RLSTACK,d0
	bra	~~rdata1

;---------------------------------------------------------------
;	.offsym	<初期値>,<シンボル>
~~offsym::
	move.b	(OFFSYMMOD,a6),-(sp)
	move.l	(OFFSYMTMP,a6),-(sp)
	st.b	(OFFSYMMOD,a6)		;offsymでシンボルなし
	bsr	calcconst		;d1=初期値
	cmpi.w	#','|OT_CHAR,(a0)
	bne	~~offsym1
	addq.l	#2,a0
	move.l	d1,(OFFSYMVAL,a6)	;初期値
	cmpi.w	#OT_SYMBOL,(a0)+
	bne	iloprerr
	movea.l	(a0)+,a1
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
;初期値を与えるシンボルの状態を確認する
;定義済みでもエラーにしない
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
	bne	pseudo_ilsymerr_a1	;タイプの異なるシンボルと重複している
	cmpi.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)
	beq	pseudo_redeferr_a1
	cmpi.b	#SECT_RLCOMM,(SYM_EXTATR,a1)
	bcc	pseudo_redeferr_a1	;.xref/.commシンボルだった
	move.l	a1,(OFFSYMSYM,a6)	;初期値を与えるシンボル
;仮のシンボルを用意する
	move.l	#(SYMHASHSIZE-1)<<16,d1	;上位ワードがローカルシンボル番号と一致しないこと
					;ただしSYMHASHSIZE*65536以上にすると
					;isdefdlocsymでオーバーフローするので注意
	move.w	(OFFSYMNUM,a6),d1	;ハッシュ関数値を分散させるためのカウンタ
	addq.w	#1,(OFFSYMNUM,a6)
	bsr	isdefdlocsym		;ハッシュチェインの検索
					;既存のシンボルとは絶対に一致しない
	bsr	deflocsymbol		;ローカルシンボルを登録する
	move.l	a1,(OFFSYMTMP,a6)	;初期値を与えるシンボルの位置の
					;ロケーションカウンタを格納する仮のシンボル
	move.b	#SA_NODET,(SYM_ATTRIB,a1)	;定義されたが値が定まっていない
					;ここでは式や値を出力しない
	moveq.l	#SECT_ABS,d0
	bsr	chgsection
	clr.l	(LOCATION,a6)
	clr.l	(LTOPLOC,a6)
	move.w	#T_OFFSYM,d0
	bsr	wrtobjd0w
	move.l	(OFFSYMVAL,a6),d0	;初期値
	bsr	wrtd0l
	move.l	(OFFSYMSYM,a6),d0	;シンボル
	bsr	wrtd0l
	move.l	a1,d0			;仮シンボル
	bsr	wrtd0l
	move.b	#1,(OFFSYMMOD,a6)	;初期値をシンボルに与える
	bra	~~offsym2

~~offsym1:
;d1=初期値
	bsr	~~offset1		;シンボルがなければ.offsetと同じ
~~offsym2:
	movea.l	(sp)+,a1		;元のOFFSYMTMP(a6)
	tst.b	(sp)+
	bgt	offsymtailchk2		;.offsymの終了処理
	rts

;offsymが正常に終了しているかどうか確認する
;a1を破壊する
offsymtailchk::
	tst.b	(OFFSYMMOD,a6)
	ble	offsymtailchk9		;offsymでないか,シンボルがない
offsymtailchk1:
	movea.l	(OFFSYMTMP,a6),a1
;a1=セクション変更前の仮のシンボル
offsymtailchk2:
	cmpi.b	#SA_NODET,(SYM_ATTRIB,a1)
	beq	offsymtailchk01		;値が定まっていなければエラー
;仮シンボルはST_LOCALなのでobjgen.sでエラーメッセージが出ることはない
offsymtailchk9:
	rts

offsymtailchk01:
	move.l	(OFFSYMSYM,a6),(ERRMESSYM,a6)
	bra	undefsymerr

;---------------------------------------------------------------
;	.offset	<式>
~~offset::
	move.b	(OFFSYMMOD,a6),-(sp)
	sf.b	(OFFSYMMOD,a6)
	bsr	calcconst
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	bsr	~~offset1
	tst.b	(sp)+
	bgt	offsymtailchk1
	rts

;d1=式の値
~~offset1:
	moveq.l	#SECT_ABS,d0
	bsr	chgsection
	move.l	d1,(LOCATION,a6)
	move.l	d1,(LTOPLOC,a6)
	move.w	#T_OFFSET,d0
	bsr	wrtobjd0w
	move.l	d1,d0			;オフセット値
	bra	wrtd0l

;---------------------------------------------------------------
;	.if	<式>
~~if::
	bsr	ifcond
	tst.l	d1
	seq.b	d0			;式が非零ならd0.b=0
~~if1:
	addq.w	#1,(IFNEST,a6)
	tst.b	d0
	beq	~~if9			;d0.b=0なら条件が成立
~~if2:
	bsr	skipfault		;条件不成立部のソースを読み飛ばす
	cmp.w	#2,d0
	bne	~~if9			;else/endifの場合
	bsr	ifcond			;elseifの場合
	tst.l	d1
	seq.b	d0
	tst.b	d0
	bne	~~if2			;再び不成立になった
~~if9:
	rts

;---------------------------------------------------------------
;	.iff	<式>
~~iff::
	bsr	ifcond
	tst.l	d1
	sne.b	d0			;式が零ならd0.b=0
	bra	~~if1

;---------------------------------------------------------------
;	.ifdef	<シンボル>
~~ifdef::
	bsr	symdefchk		;シンボルが登録済ならd0.b=0
	bra	~~if1

;---------------------------------------------------------------
;	.ifndef	<シンボル>
~~ifndef::
	bsr	symdefchk
	not.b	d0			;シンボルが未登録ならd0.b=0
	bra	~~if1

;---------------------------------------------------------------
;	シンボルが登録済かどうかを調べる
symdefchk:
	bsr	getword
	tst.w	d2
	bmi	iloprerr		;シンボルがない
	move.b	(a1)+,d0
	beq	symdefchk2
	cmp.b	#',',d0
	beq	iloprerr_pseudo_many	;引数が多すぎる
	cmp.b	#' ',d0
	bhi	iloprerr		;シンボル以外の文字が繋がっている
symdefchk1:
	move.b	(a1)+,d0
	beq	symdefchk2
	cmp.b	#' ',d0
	bls	symdefchk1
	cmp.b	#',',d0			;シンボルの後の空白の先の先頭の文字
	beq	iloprerr_pseudo_many	;引数が多すぎる
symdefchk2:
	subq.l	#1,a1
	move.l	a1,(LINEPTR,a6)
	bra	isdefdsym

;---------------------------------------------------------------
;	.ifの条件不成立部のソースを読み飛ばす
skipfault:
	bsr	deflabel		;行頭にラベルがあったら定義しておく
	clr.w	(IFSKIPNEST,a6)
	st.b	(ISIFSKIP,a6)		;エラーチェック等はしない
skipfault1:
	bsr	getline			;1行読み込み
	tst.w	d0
	bmi	skipfault9		;読み飛ばし中にソースが終了してしまった
	or.w	#T_LINE,d0		;1行開始
	bsr	wrtobjd0w
	bsr	encodeline		;ラベルの処理と命令のコード化
	tst.b	(ISMACRO,a6)
	bne	skipfault1		;マクロ命令
	move.l	(CMDTBLPTR,a6),d0
	beq	skipfault1		;命令がない
	movea.l	d0,a1
	move.l	(SYM_FUNC,a1),a1
	lea.l	(~~if,pc),a2
	cmpa.l	a1,a2
	beq	skipfif
	lea.l	(~~iff,pc),a2
	cmpa.l	a1,a2
	beq	skipfif
	lea.l	(~~ifdef,pc),a2
	cmpa.l	a1,a2
	beq	skipfif
	lea.l	(~~ifndef,pc),a2
	cmpa.l	a1,a2
	beq	skipfif
	lea.l	(~~else,pc),a2
	cmpa.l	a1,a2
	beq	skipfelse
	lea.l	(~~elseif,pc),a2
	cmpa.l	a1,a2
	beq	skipfelif
	lea.l	(~~endif,pc),a2
	cmpa.l	a1,a2
	beq	skipfendif
	bra	skipfault1

skipfault9:
	clr.w	(IFNEST,a6)		;処理を強制終了させる
	sf.b	(ISIFSKIP,a6)
	bra	misiferr_eof

skipfif:				;if/iff/ifdef/ifndef
	addq.w	#1,(IFSKIPNEST,a6)
	bra	skipfault1

skipfelse:				;else
	tst.w	(IFSKIPNEST,a6)
	bne	skipfault1
	moveq.l	#1,d0
	bra	skipfend

skipfelif:				;elseif
	tst.w	(IFSKIPNEST,a6)
	bne	skipfault1
	moveq.l	#2,d0
	bra	skipfend

skipfendif:				;endif
	tst.w	(IFSKIPNEST,a6)
	beq	skipfendif1
	subq.w	#1,(IFSKIPNEST,a6)
	bra	skipfault1

skipfendif1:
	subq.w	#1,(IFNEST,a6)
	moveq.l	#0,d0
skipfend:
	sf.b	(ISIFSKIP,a6)
	move.w	#-1,(LABNAMELEN,a6)
	rts

;---------------------------------------------------------------
;	.else
~~else::
	tst.w	(IFNEST,a6)
	beq	misiferr_else
	bsr	skipfault
	cmp.w	#2,d0
	beq	misiferr_else_elseif	;elseの後にelseifがあった
	rts

;---------------------------------------------------------------
;	.elseif	<式>
~~elseif::
	tst.w	(IFNEST,a6)
	beq	misiferr_elseif
	bsr	skipfault
	subq.w	#1,d0
	beq	~~else
	bcc	~~elseif
	rts

;---------------------------------------------------------------
;	.endif
~~endif::
	tst.w	(IFNEST,a6)
	beq	misiferr_endif
	subq.w	#1,(IFNEST,a6)
	rts

;---------------------------------------------------------------
;	.end	[<ラベル>]
~~end::
	st.b	(ISASMEND,a6)
	move.b	(a0),d0
	cmp.b	#'*',d0
	beq	~~end9
	cmp.b	#';',d0
	beq	~~end9
	bsr	encodeopr
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	tst.w	(a0)
	beq	~~end9			;開始アドレス指定がなかった
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	move.w	d1,d2
	tst.b	(EXPRISSTR,a6)
	bne	iloprerr		;式に文字列を含んでいた
	bsr	calcrpn
	tst.w	d0
	beq	iloprerr		;<式>がアドレスでない
	tst.w	(a0)
	bne	iloprerr_pseudo_tail	;行が終了していない
	move.w	#T_END,d0
	bsr	wrtobjd0w
	moveq.l	#SZ_LONG,d0
	move.w	d2,d1
	bra	wrtrpn			;式の出力

~~end9:
	rts

;---------------------------------------------------------------
;	.insert	<ファイル名>[,<オフセット>,<サイズ>]
~~insert::
	tst.b	(a0)
	beq	iloprerr		;ファイル名の指定がない
	movea.l	(OPRBUFPTR,a6),a1
~~insert1:
	move.b	(a0)+,d0
	move.b	d0,(a1)+
	cmp.b	#',',d0
	beq	~~insert2
	cmp.b	#' ',d0
	bhi	~~insert1
~~insert2:
	subq.l	#1,a0
	clr.b	(-1,a1)

	clr.w	-(sp)
	move.l	(OPRBUFPTR,a6),-(sp)
	DOS	_OPEN
	addq.l	#6,sp
	move.l	d0,d3			;d3=ファイルハンドル
	bmi	nofileerr		;ファイルが見つからない

	move.l	d3,-(sp)
	bsr	encodeopr
	move.l	(sp)+,d3

	tst.b	(ISOBJOUT,a6)
	bne	~~insert2_1
	bsr	flushobj		;オブジェクトバッファをフラッシュする
~~insert2_1:

	moveq.l	#0,d2			;オフセット
	moveq.l	#-1,d1			;サイズ

	movea.l	(OPRBUFPTR,a6),a0
	cmpi.w	#','|OT_CHAR,(a0)
	bne	~~insert4
~~insert_param_loop:
	bsr	~~insert_calcopr
	move.l	d1,d2			;d2=オフセット

	moveq.l	#-1,d1			;サイズ

	cmpi.w	#','|OT_CHAR,(a0)
	bne	~~insert4
	bsr	~~insert_calcopr
					;d1=残りのサイズ
~~insert4:
	tst.l	d1
	beq	~~insert8
	movea.l	d1,a1			;a1=指定されたサイズ

	clr.w	-(sp)
	move.l	d2,-(sp)		;オフセット
	move.w	d3,-(sp)
	DOS	_SEEK
	addq.l	#8,sp
	tst.l	d0
	bmi	~~insert_seek_error	;指定された位置までシークできない

~~insert_read_loop:
	movea.w	#256,a2			;今回転送するサイズ
	cmp.l	a2,d1
	bcc	~~insert6
	move.l	d1,a2			;d1>=256でなければd1だけ転送する
~~insert6:
	move.l	a2,-(sp)		;今回のサイズ
	pea.l	(OBJCONBUF,a6)		;オブジェクトバッファに直接読み出す
	move.w	d3,-(sp)
	DOS	_READ
	lea.l	(10,sp),sp
	tst.l	d0
	bmi	~~insert_size_error	;指定されたサイズを読み出せない
	cmp.l	a2,d0
	beq	~~insert7		;今回のサイズを読み出せた
	cmpa.w	#-1,a1
	bne	~~insert_size_error	;サイズが指定されたのに,
					;今回のサイズを読み出せなかった.
					;つまり,指定されたサイズを読み出せない
	movea.l	d0,a2			;サイズが指定されていないので,
	move.l	a2,d1			;今回で終わりにする
~~insert7:
	add.l	d0,(LOCATION,a6)	;ロケーションカウンタを更新する

	tst.b	(ISOBJOUT,a6)
	bne	~~insert7_1
	move.w	d0,(OBJCONCTR,a6)	;オブジェクトのサイズを指定する(0～256)
	bsr	flushobj		;オブジェクトを出力する
	tst.b	(MAKEPRN,a6)
	beq	~~insert7_0
	move.w	#T_PRNADV,d0
	bsr	wrtobjd0w
~~insert7_0:
~~insert7_1:

	sub.l	a2,d1			;残りのサイズ
	bne	~~insert_read_loop
~~insert8:
	cmpi.w	#','|OT_CHAR,(a0)
	beq	~~insert_param_loop

~~insert_close:
	move.w	d3,-(sp)
	DOS	_CLOSE
	addq.l	#2,sp
	rts

~~insert_calcopr:
	addq.l	#2,a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式変換に失敗
	bsr	calcrpn
	tst.w	d0
	bne	ilvalueerr		;定数でない
	rts

~~insert_seek_error:
~~insert_size_error:
	bsr	~~insert_close
	bra	ilvalueerr

;---------------------------------------------------------------
;	.include	<ファイル名>
~~include::
	tst.b	(a0)
	beq	iloprerr		;ファイル名の指定がない
	movea.l	(OPRBUFPTR,a6),a1
~~include1:
	move.b	(a0)+,d0
	move.b	d0,(a1)+
	cmp.b	#' ',d0
	bhi	~~include1
	clr.b	(-1,a1)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	srchincld		;インクルードファイルを検索
	tst.w	d0
	bmi	nofileerr
	bsr	openincld
	tst.w	d0
	bmi	nofileerr
	move.w	#T_INCLD,d0
	bsr	wrtobjd0w
	move.l	a0,d0
	bra	wrtd0l			;ファイル名へのポインタ

;---------------------------------------------------------------
;	.request	<ファイル名>[,<ファイル名>,…]
~~request::
	tst.b	(a0)
	beq	iloprerr		;ファイル名の指定がない
~~request1:
	move.l	(TEMPPTR,a6),d0
	doeven	d0
	movea.l	(REQFILEND,a6),a1
	move.l	d0,(a1)
	move.l	d0,(REQFILEND,a6)
	movea.l	d0,a1
	clr.l	(a1)+
	bsr	getpara
	move.l	a1,(TEMPPTR,a6)
	tst.w	d0
	bne	~~request1
	move.l	a0,(LINEPTR,a6)
	bra	memcheck

;---------------------------------------------------------------
;	.list
~~list::
	moveq.l	#1,d0
~~list1:
	or.w	#T_LIST,d0
	bra	wrtobjd0w

;---------------------------------------------------------------
;	.nlist
~~nlist::
	moveq.l	#2,d0
	bra	~~list1

;---------------------------------------------------------------
;	.sall
~~sall::
	moveq.l	#3,d0
	bra	~~list1

;---------------------------------------------------------------
;	.lall
~~lall::
	moveq.l	#4,d0
	bra	~~list1

;---------------------------------------------------------------
;	.width	<式>
~~width::
	bsr	calcconst		;<式>の値は80～255
	cmp.l	#256,d1
	bcc	ilvalueerr
	cmp.w	#80,d1
	bcs	ilvalueerr
	and.w	#$FFF8,d1
	move.w	d1,(PRNWIDTH,a6)
	rts

;---------------------------------------------------------------
;	.page	[+/<式>]
~~page::
	bsr	encodeopr
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	~~page2			;式変換に失敗
	tst.b	(EXPRISSTR,a6)
	bne	iloprerr		;式に文字列を含んでいた
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr		;<式>が定数でない
	tst.l	d1
	bmi	~~page1
	cmp.l	#256,d1
	bcc	ilvalueerr
	cmp.w	#10,d1
	bcs	ilvalueerr
	move.w	d1,(PRNPAGEL,a6)	;<式>の値は10～255
	rts

~~page1:
	move.w	#-1,(PRNPAGEL,a6)
	rts

~~page2:
	moveq.l	#0,d0
	movea.l	(LINEPTR,a6),a0
	cmpi.b	#'+',(a0)
	bne	~~page3
	moveq.l	#1,d0			;.page +
~~page3:
	or.w	#T_PAGE,d0
	bra	wrtobjd0w

;---------------------------------------------------------------
;	.title	<文字列>
~~title::
	movea.l	(TEMPPTR,a6),a1
	move.l	a1,(PRNTITLE,a6)
~~title1:				;タイトル文字列を得る
	move.b	(a0)+,(a1)+
	bne	~~title1
	move.l	a1,(TEMPPTR,a6)
	bra	memcheck

;---------------------------------------------------------------
;	.subttl	<文字列>
~~subttl::
	movea.l	(TEMPPTR,a6),a1
	move.w	#T_SUBTTL,d0
	bsr	wrtobjd0w
	move.l	a1,d0
	bsr	wrtd0l
	bra	~~title1

;---------------------------------------------------------------
;	.comment	<文字列>
~~comment::
	bsr	deflabel		;行頭にラベルがあったら定義しておく
	move.w	#-1,(LABNAMELEN,a6)
	movea.l	(OPRBUFPTR,a6),a1
	tst.b	(a0)
	beq	~~comment85		;文字列がなければ次の一行のみをコメントとする
~~comment1:				;コメント終了文字列を得る
	move.b	(a0)+,d0
	cmp.b	#' ',d0
	bls	~~comment2
	move.b	d0,(a1)+
	bra	~~comment1

~~comment2:
	clr.b	(a1)
~~comment3:
	bsr	getline			;1行読み込み
	tst.w	d0
	bmi	~~comment9		;読み飛ばし中にソースが終了してしまった
	or.w	#T_LINE,d0		;1行開始
	bsr	wrtobjd0w
	movea.l	(LINEBUFPTR,a6),a0
~~comment4:
	bsr	skipspc
	tst.b	(a0)
	beq	~~comment3
	movea.l	(OPRBUFPTR,a6),a1
~~comment5:
	move.b	(a1)+,d0
	beq	~~comment6
	cmp.b	(a0)+,d0
	beq	~~comment5
	bra	~~comment7

~~comment6
	cmpi.b	#' ',(a0)+
	bls	~~comment9
~~comment7:
	subq.l	#1,a0
~~comment8:
	cmpi.b	#' ',(a0)+
	bhi	~~comment8
	subq.l	#1,a0
	bra	~~comment4

~~comment85:				;1行のみをコメントとする
	bsr	getline			;1行読み込み
	tst.w	d0
	bmi	~~comment9		;読み飛ばし中にソースが終了してしまった
	or.w	#T_LINE,d0		;1行開始
	bsr	wrtobjd0w
~~comment9:
	rts

;---------------------------------------------------------------
;	.fail	<式>
~~fail::
	bsr	ifcond
	tst.l	d1
	bne	forcederr
	rts

;---------------------------------------------------------------
;	.cpu	<式>
~~cpu::
	bsr	calcconst
	pea.l	(pseudo_tail_check,pc)	;最後に行の終了をチェックする
					;よって以降でa0を破壊してはならない
	bsr	cputype_update
	bmi	featureerr_cpu
	rts
~~cpu_68000::
	move.l	#68000,d1
	bra	cputype_update
~~cpu_68010::
	move.l	#68010,d1
	bra	cputype_update
~~cpu_68020::
	move.l	#68020,d1
	bra	cputype_update
~~cpu_68030::
	move.l	#68030,d1
	bra	cputype_update
~~cpu_68040::
	move.l	#68040,d1
	bra	cputype_update
~~cpu_68060::
	move.l	#68060,d1
	bra	cputype_update
~~cpu_5200::
	move.l	#5200,d1
	bra	cputype_update
~~cpu_5300::
	move.l	#5300,d1
	bra	cputype_update
~~cpu_5400::
	move.l	#5400,d1
	bra	cputype_update


;---------------------------------------------------------------
;CPU番号をCPUタイプに変換する
;<d1.l:CPU番号(68000など)
;>d0.l:CPUタイプ(C000など,-1=エラー)
cputype_convert::
	moveq.l	#0,d0
	move.w	#C000,d0
	cmp.l	#68000,d1
	beq	8f
	move.w	#C010,d0
	cmp.l	#68010,d1
	beq	8f
	move.w	#C020|CFPP|CMMU,d0
	cmp.l	#68020,d1
	beq	8f
	move.w	#C030|CFPP,d0
	cmp.l	#68030,d1
	beq	8f
	move.w	#C040,d0
	cmp.l	#68040,d1
	beq	8f
	move.w	#C060,d0
	cmp.l	#68060,d1
	beq	8f
	move.w	#C520,d0
	cmp.l	#5200,d1
	beq	8f
	move.w	#C530,d0
	cmp.l	#5300,d1
	beq	8f
	move.w	#C540,d0
	cmp.l	#5400,d1
	beq	8f
	moveq.l	#-1,d0
8:	tst.l	d0
	rts

;---------------------------------------------------------------
;CPU番号を受け取ってCPUを更新する
;	アセンブル開始時にCPU番号の初期値(-mまたはデフォルト)をICPUNUMBERに保存しておく
;	パス1の開始時にd1=ICPUNUMBERで呼び出す
;	パス1の.cpuでd1=引数で呼び出す
;	パス2以降はT_CPUでCPUTYPEだけ更新する
;
;	CPUNUMBERを設定する
;	CPUTYPEを設定する
;	プレデファインシンボルCPUを更新するためのオブジェクトを出力する
;	プレデファインシンボルCPUを更新する
;	68000/68010または外部参照のデフォルトがワードのとき
;		ディスプレースメントのサイズをワードにする
;	68000/68010以外で外部参照のデフォルトがロングのとき
;		ディスプレースメントのサイズをロングにする
;	68040/68060のとき
;		FPUIDを1にする
;	68000/68010のとき
;		浮動小数点命令を書けないのでF43G対策を終了する
;	68020/68030/68040/68060のとき
;		浮動小数点命令を書けるのでF43G対策を開始する
;	CPUTYPEを出力する
;
;<d1.l:CPU番号(68000など)
;>d0.l:0=正常終了,-1=エラー
cputype_update::
	movem.l	d1-d2,-(sp)
	bsr	cputype_convert
	bmi	98f			;エラー
;<d0.l:CPUタイプ(C000など)
;--------------------------------
;CPUNUMBERを設定する
	move.l	d1,(CPUNUMBER,a6)	;CPUNUMBER
;--------------------------------
;CPUTYPEを設定する
	move.l	d0,d2			;CPUTYPE
	move.w	d2,(CPUTYPE,a6)
;--------------------------------
;CPUTYPEを出力する
	move.w	#T_CPU+1,d0
	bsr	wrtobjd0w
	move.w	d2,d0			;CPUTYPE
	bsr	wrtd0w
;--------------------------------
;プレデファインシンボルCPUを更新するためのオブジェクトを出力する
	bsr	~~cpu_changesymbol
;--------------------------------
;プレデファインシンボルCPUを更新する
	move.l	d1,-(sp)		;CPUNUMBER
	bsr	~~cpu_setsymbol
	addq.l	#4,sp
;--------------------------------
	move.l	d2,d0			;CPUTYPE
	and.w	#C000|C010,d0
	bne	1f
	tst.b	(EXTSHORT,a6)
	bne	2f
1:
;68000/68010または外部参照のデフォルトがワードのとき
;ディスプレースメントのサイズをワードにする
	sf.b	(EXTSIZEFLG,a6)
	move.b	#SZ_WORD,(EXTSIZE,a6)
	move.l	#2,(EXTLEN,a6)
	bra	3f
2:
;68000/68010以外で外部参照のデフォルトがロングのとき
;ディスプレースメントのサイズをロングにする
	st.b	(EXTSIZEFLG,a6)
	move.b	#SZ_LONG,(EXTSIZE,a6)
	move.l	#4,(EXTLEN,a6)
3:
;--------------------------------
	move.l	d2,d0			;CPUTYPE
	and.w	#C040|C060,d0
	beq	3f
;68040/68060のとき
;FPUIDを1にする
	move.w	#1<<9,(FPCPID,a6)
3:
;--------------------------------
	move.l	d2,d0			;CPUTYPE
	and.w	#C020|C030|C040|C060,d0
	bne	2f
;68000/68010のとき
;浮動小数点命令を書けないのでF43G対策を終了する
	bsr	f43gcut			;F43G対策のシーケンスをカットする
	sf.b	(F43GTEST,a6)		;F43G対策を行わない
	bra	3f
2:
;68020/68030/68040/68060のとき
;浮動小数点命令を書けるのでF43G対策を開始する
	tst.b	(F43GTEST,a6)
	bne	19f
	tst.b	(IGNORE_ERRATA,a6)
	seq.b	(F43GTEST,a6)
;IGNORE_ERRATAがONでもレコードは初期化すること
;(-k1 -m68060 -k0のとき-k0ではレコードを初期化しないから)
;レコードが初期化されていなければ初期化する
	movem.l	d0/a0,-(sp)
	lea.l	(F43GREC,a6),a0
	move.l	a0,(F43GPTR,a6)
	moveq.l	#5-1,d0
11:
;	clr.l	(8,a0)
	clr.w	(12,a0)
	lea.l	(-16,a0),a0
	move.l	a0,(16+4,a0)
	lea.l	(16*2,a0),a0
	move.l	a0,(-16,a0)
	dbra	d0,11b
	lea.l	(F43GREC,a6),a0
	move.l	a0,(16*4,a0)
	lea.l	(F43GREC+16*4,a6),a0
	move.l	a0,(-16*4+4,a0)
	movem.l	(sp)+,d0/a0
19:
3:
;--------------------------------
	moveq.l	#0,d0
98:	tst.l	d0
	movem.l	(sp)+,d1-d2
	rts

;---------------------------------------------------------------
;<d1.l:CPU
~~cpu_changesymbol:
	tst.l	(CPUSYMBOL,a6)
	beq	~~cpu_changesymbol9
	move.l	d0,-(sp)
	move.w	#T_EQUCONST,d0
	bsr	wrtobjd0w
	move.l	(CPUSYMBOL,a6),d0
	bsr	wrtd0l
	move.l	d1,d0
	bsr	wrtd0l
	move.l	(sp)+,d0
~~cpu_changesymbol9:
	rts

;---------------------------------------------------------------
;<4(sp).l:CPU
~~cpu_setsymbol:
	tst.l	(CPUSYMBOL,a6)
	beq	~~cpu_setsymbol9
	move.l	a1,-(sp)
	movea.l	(CPUSYMBOL,a6),a1
	move.l	(4+4,sp),(SYM_VALUE,a1)
	movea.l	(sp)+,a1
~~cpu_setsymbol9:
	rts

;---------------------------------------------------------------
;	.org	<式>
~~org::
	bsr	calcconst
	move.l	d1,(LOCATION,a6)	;ロケーションカウンタを変更
	addq.b	#1,(ORGNUM,a6)
	move.w	#T_ORG,d0
	bsr	wrtobjd0w
	move.l	d1,d0
	bra	wrtd0l			;カウンタ値


;---------------------------------------------------------------
;	SCD対応疑似命令のアセンブル処理
;---------------------------------------------------------------

;---------------------------------------------------------------
;	アセンブラシンボリックデバッグ用にファイル名の出力準備をする
setsymdebfile::
	tst.b	(MAKESYMDEB,a6)
	beq	checksymdeb9		;'-g'スイッチは指定されていない
	movea.l	(TEMPPTR,a6),a1
	movea.l	(SOURCEFILE,a6),a2	;ソースファイル名へのポインタ
	move.l	a2,(SCDFILE,a6)
	bra	~~file3

;---------------------------------------------------------------
;	テンポラリにシンボリックデバッグコードを出力するかチェックする
checksymdeb:
	tst.b	(MAKESCD,a6)
	beq	checksymdeb8		;SCDフラグが立っていない
checksymdeb1:
	tst.b	(MAKESYMDEB,a6)
	beq	checksymdeb9
checksymdeb8:
	addq.l	#4,sp			;'-g'スイッチがあるので,SCD疑似命令は無視する
checksymdeb9:
	rts

;---------------------------------------------------------------
;	.file	"<ファイル名>"
~~file::
	bsr	checksymdeb1		;'-g'スイッチのチェック
	cmpi.b	#'"',(a0)+
	bne	iloprerr
	movea.l	(TEMPPTR,a6),a1
	movea.l	a1,a2			;ファイル名をバッファに保存する
	moveq.l	#0,d1			;ファイル長
~~file1:
	move.b	(a0)+,d0
	cmp.b	#'"',d0
	beq	~~file2
	cmp.b	#' ',d0
	bls	iloprerr
	move.b	d0,(a1)+
	addq.w	#1,d1
	bra	~~file1

~~file2:
	clr.b	(a1)+
	move.l	a1,(TEMPPTR,a6)
	st.b	(MAKESCD,a6)		;SCDフラグを立てる
	move.l	a2,(SCDFILE,a6)		;ファイル名へのポインタ
	clr.l	(SCDFILENUM,a6)		;シンボル延長テーブルは使用しない
	cmpi.w	#14,d1
	bls	memcheck
~~file3:				;ファイル名が14文字以上の場合
	movea.l	a2,a0
	move.l	a1,d0
	doeven	d0
	movea.l	d0,a4
	move.l	(EXNAMEPTR,a6),d0
	bne	~~file5
	move.l	a4,(EXNAMEPTR,a6)	;最初の延長シンボルの場合
	lea.l	(10,a4),a2
	move.l	a2,(a4)+		;チェインをつなぐ
	clr.l	(a4)+			;先頭からのオフセット
	clr.w	(a4)+			;文字列本体(ヌルストリング)
	clr.l	(a4)+			;次の延長シンボルへのポインタ
	moveq.l	#2,d1
	move.l	d1,(a4)+		;オフセット(=2)
	move.l	d1,(SCDFILENUM,a6)	;(オフセット0は延長テーブルを使用しないという
	bra	~~def35			;意味なので,ダミーのテーブルを作成する)

~~file5:
	movea.l	d0,a3
	move.l	(a3),d0
	bne	~~file3			;シンボル名チェインの末尾を探す
	move.l	a4,(a3)			;チェインをつなぐ
	clr.l	(a4)+			;次の延長シンボルへのポインタ
	move.l	(EXNAMELEN,a6),d1
	move.l	d1,(a4)+		;延長テーブル先頭からのオフセット
	move.l	d1,(SCDFILENUM,a6)
	bra	~~def35			;文字列本体をバッファに格納する

;---------------------------------------------------------------
;	.ln	<行番号>[,<ロケーション値>]
~~ln::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	calcconst
	move.w	d1,d3
	cmp.l	#$10000,d1
	bcc	ilvalueerr		;行番号は16bit
	lea.l	(RPNBUF,a6),a1
	move.w	(a0)+,d0
	beq	~~ln2			;ロケーション値が省略された
	cmp.w	#',',d0
	bne	iloprerr
	bsr	convrpn			;ロケーション値の指定があった場合
	tst.w	d0
	bmi	exprerr			;式が変換できない
	tst.b	(EXPRISSTR,a6)
	bne	iloprerr		;式に文字列を含んでいた
~~ln1:
	addq.l	#1,(NUMOFLN,a6)
	move.w	#T_LN,d0
	bsr	wrtobjd0w
	move.w	d3,(SCDLN,a6)
	move.w	d3,d0
	bsr	wrtd0w
	moveq.l	#2,d0
	bra	wrtrpn			;式の出力

~~ln2:
	move.w	#RPN_LOCATION,(a1)	;現在のロケーションカウンタ値
	moveq.l	#1,d1
	bra	~~ln1

;---------------------------------------------------------------
;	.def	<シンボル名>
~~def::
	bsr	checksymdeb		;'-g'スイッチのチェック
	cmpi.b	#' ',(a0)
	bls	iloprerr		;オペランドがない
	lea.l	(SCDTEMP,a6),a1
	moveq.l	#9-1,d0
~~def1:
	clr.l	(a1)+			;拡張シンボル一時バッファをクリア
	dbra	d0,~~def1
	move.w	(SCDLN,a6),(SCD_SIZE+SCDTEMP,a6)	;????
	clr.w	(SCDLN,a6)
	movea.l	a0,a2
	lea.l	(SCD_NAME+SCDTEMP,a6),a1
	movea.l	a1,a3
	moveq.l	#8,d1
~~def2:
	move.b	(a2)+,d0
	cmp.b	#' ',d0
	bls	~~def4
	move.b	d0,(a3)+
	dbra	d1,~~def2
	clr.b	-(a3)			;シンボル名が8文字以上の場合
	clr.l	(a1)+
	lea.l	(EXNAMEPTR,a6),a3
~~def31:				;シンボル名チェインを1つたどる
	move.l	(a3),d0
	beq	~~def34
	movea.l	d0,a3
	lea.l	(8,a3),a4
	movea.l	a0,a2
~~def32:				;すでに同名のシンボルがあるかどうかを調べる
	move.b	(a2)+,d0
	cmp.b	#' ',d0
	bls	~~def33
	cmp.b	(a4)+,d0
	beq	~~def32
	bra	~~def31

~~def33:
	tst.b	(a4)
	bne	~~def31
	move.l	(4,a3),(a1)		;同名のシンボルが存在した
	rts

~~def34:				;同名のシンボルがないので新たに登録する
	move.l	(TEMPPTR,a6),d0
	addq.l	#1,d0
	bclr.l	#0,d0
	movea.l	d0,a4
	move.l	a4,(a3)			;チェインをつなぐ
	clr.l	(a4)+			;次の延長シンボルへのポインタ
	move.l	(EXNAMELEN,a6),d1
	move.l	d1,(a4)+		;延長テーブル先頭からのオフセット
	move.l	d1,(a1)
~~def35:				;文字列本体を格納する
	move.b	(a0)+,d0
	move.b	d0,(a4)+
	addq.l	#1,d1
	cmp.b	#' ',d0
	bhi	~~def35
	clr.b	(-1,a4)
	move.l	a4,(TEMPPTR,a6)
	addq.l	#1,d1
	bclr.l	#0,d1
	move.l	d1,(EXNAMELEN,a6)
	bra	memcheck

~~def4:					;特殊シンボルかどうかをチェック
	lea.l	(scdsp_name,pc),a1
~~def5:
	lea.l	(SCD_NAME+SCDTEMP,a6),a0
~~def6:
	move.b	(a1)+,d0
	cmp.b	(a0)+,d0
	bne	~~def8
	tst.b	d0
	bne	~~def6
	move.b	(a1),(SCDATTRIB,a6)	;特殊シンボルコード
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	rts

~~def7:
	addq.l	#1,a1
~~def8:
	tst.b	(-1,a1)
	bne	~~def7
	addq.l	#1,a1
	tst.b	(a1)
	bne	~~def5
	rts				;特殊シンボルでない

;---------------------------------------------------------------
;	.endef
~~endef::
	bsr	checksymdeb		;'-g'スイッチのチェック
	move.b	(SCDATTRIB,a6),d2
	move.b	d2,d0
	andi.b	#$0F,d0
	bne	~~endef1
	move.w	(SCD_TYPE+SCDTEMP,a6),d1
	andi.w	#$0030,d1
	cmpi.w	#$0020,d1		;関数
	beq	~~endef04
	move.b	(SCD_SCL+SCDTEMP,a6),d1
	moveq.l	#$11,d2			;タグ定義開始
	cmpi.b	#10,d1			;structタグ
	beq	~~endef05
	cmpi.b	#12,d1			;unionタグ
	beq	~~endef05
	cmpi.b	#15,d1			;enumタグ
	beq	~~endef05
	moveq.l	#$50,d2
	cmpi.b	#2,d1			;extern変数
	beq	~~endef1
	cmpi.b	#80,d1			;extern変数(SXhas remote)
	beq	~~endef1
	cmpi.b	#82,d1			;extern変数(SXhas relocate)
	beq	~~endef1
	move.b	(SCDATTRIB,a6),d2	;static変数/その他
	bne	~~endef1
	moveq.l	#$30,d2
	bra	~~endef1

~~endef04:
	moveq.l	#$21,d2			;関数定義開始
	addq.l	#1,(NUMOFLN,a6)
~~endef05:
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	move.w	(SCDATTRIB,a6),d0
	move.b	d2,d0
	ror.w	#8,d0
	move.w	d0,(SCDATTRIB,a6)
~~endef1:
	cmp.b	#$2F,d2
	beq	~~endef5		;.scl -1 の場合データ出力はしない
	moveq.l	#T_ENDEFS>>8,d0
	moveq.l	#0,d3
	move.b	(SCD_LEN+SCDTEMP,a6),d3
	add.w	d3,d0
	lsl.w	#8,d0			;オブジェクトコードT_ENDEFS/T_ENDEFL
	addq.l	#1,d3			;使用するテーブル長
	move.b	d2,d0			;データ型
	bsr	wrtobjd0w
	lea.l	(SCD_NAME+SCDTEMP,a6),a0
	moveq.l	#4-1,d1
~~endef2:
	move.w	(a0)+,d0
	bsr	wrtd0w			;シンボル名を出力
	dbra	d1,~~endef2
	addq.l	#6,a0
	move.w	(a0)+,d0
	bsr	wrtd0w			;.type
	move.w	(a0)+,d0
	bsr	wrtd0w			;.scl
	tst.b	d0
	beq	~~endef4
	addq.l	#4,a0
	moveq.l	#6-1,d1
~~endef3:
	move.w	(a0)+,d0
	bsr	wrtd0w			;ロングデータの場合.size/.line/.dimを出力
	dbra	d1,~~endef3
~~endef4:
	and.w	#$00F0,d2
	lsr.w	#2,d2
	lea.l	(NUMOFSCD,a6),a0
	add.l	d3,(a0)			;使用したテーブル長だけカウンタを進める
	add.l	d3,(a0,d2.w)
~~endef5:
	move.w	(SCDATTRIB,a6),d0
	move.w	#$F0FF,d1
	and.w	d0,d1
	andi.w	#$0F00,d0
	cmpi.w	#$0F00,d0
	bne	~~endef6
	lsl.w	#8,d1			;タグ/関数定義の終了
~~endef6:
	move.w	d1,(SCDATTRIB,a6)
	rts

;---------------------------------------------------------------
;	.val	<式>
~~val::
	bsr	checksymdeb		;'-g'スイッチのチェック
	cmpi.b	#'.',(a0)
	bne	~~val1
	cmpi.b	#' ',(1,a0)
	bhi	~~val1
	move.b	#'*',(a0)		;.val .   → .val *
~~val1:
	bsr	encodeopr
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式が変換できない
	move.w	#T_VAL,d0
	bsr	wrtobjd0w
	moveq.l	#2,d0
	bra	wrtrpn			;式の出力

;---------------------------------------------------------------
;	.scl	<式>
~~scl::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	calcconst
	cmp.l	#-1,d1
	beq	~~scl9
	cmp.l	#$100,d1
	bcc	ilvalueerr
	move.b	d1,(SCD_SCL+SCDTEMP,a6)
	rts

~~scl9:					;.scl -1 (関数定義の終了)
	move.b	#$2F,(SCDATTRIB,a6)	;.endefでの出力はしない
	move.w	#T_SCL,d0
	bra	wrtobjd0w

;---------------------------------------------------------------
;	.type	<式>
~~type::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	calcconst
	cmp.l	#$10000,d1
	bcc	ilvalueerr
	move.w	d1,(SCD_TYPE+SCDTEMP,a6)
	and.w	#$0030,d1
	cmp.w	#$0030,d1		;配列
	beq	~~type8
	cmp.w	#$0020,d1		;関数
	bne	~~type9
~~type8:
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
~~type9:
	rts

;---------------------------------------------------------------
;	.tag	<タグ名>
~~tag::
	bsr	checksymdeb		;'-g'スイッチのチェック
	movea.l	(TEMPPTR,a6),a1
	move.w	#T_TAG,d0
	bsr	wrtobjd0w
	move.l	a1,d0			;タグ名へのポインタ
	bsr	wrtd0l
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	bra	~~title1		;指定されたタグ名をメモリに格納する

;---------------------------------------------------------------
;	.line	<式>
~~line::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	calcconst
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	move.w	d1,(SCD_SIZE+SCDTEMP,a6)
	rts

;---------------------------------------------------------------
;	.size	<式>
~~size::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	calcconst
	tst.l	d1
	beq	~~size9
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	move.l	d1,(SCD_SIZE+SCDTEMP,a6)
~~size9:
	rts

;---------------------------------------------------------------
;	.dim	<式1>[,<式2>…]
~~dim::
	bsr	checksymdeb		;'-g'スイッチのチェック
	bsr	encodeopr
	move.b	#1,(SCD_LEN+SCDTEMP,a6)	;テーブルはロングデータ
	moveq.l	#4-1,d2
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(SCD_DIM+SCDTEMP,a6),a2
~~dim1:
	lea.l	(RPNBUF,a6),a1
	bsr	convrpn
	tst.w	d0
	bmi	exprerr			;式が変換できない
	tst.b	(EXPRISSTR,a6)
	bne	iloprerr		;式に文字列を含んでいた
	bsr	calcrpn
	tst.w	d0
	bne	iloprerr		;式が定数でない
	move.w	d1,(a2)+
	cmp.w	#',',(a0)+
	bne	~~dim2
	dbra	d2,~~dim1
~~dim2:
	tst.w	-(a0)
	bne	iloprerr
	rts

;---------------------------------------------------------------
;	SCD用特殊シンボル名
scdsp_name:	.dc.b	'.eos',0,$1F,'.bb',0,$2B,'.eb',0,$2C,'.bf',0,$2D,'.ef',0,$2E,0
	.even


;---------------------------------------------------------------
	.end
