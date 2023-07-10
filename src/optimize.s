;----------------------------------------------------------------
;	X68k High-speed Assembler
;		パス2(前方参照の最適化)
;		< optimize.s >
;
;		Copyright 1990-94  by Y.Nakamura
;		          1996-99  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	symbol.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	cputype.equ
	.include	eamode.equ
	.include	error2.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	パス2(前方参照の最適化)
;----------------------------------------------------------------
asmpass2::
	move.b	#2,(ASMPASS,a6)
	tst.b	(OPTIMIZE,a6)
	bne	asmpass29		;/nの指定があったので何もしない

	clr.b	(OPTCOUNT,a6)
	move.b	#SZ_LONG|ESZ_OPT,(OPTMOREFLG,a6)
asmpass21:
	move.l	(CPUSYMBOL,a6),d0
	beq	asmpass219
	movea.l	d0,a1
	move.l	(STARTCPU,a6),(SYM_VALUE,a1)
asmpass219:
	addq.b	#1,(OPTCOUNT,a6)
	sf.b	(OPTFLAG,a6)
	lea.l	(TEMPFILPTR,a6),a1
	bsr	frewind			;テンポラリファイル先頭に移動
	bsr	resetlocctr		;ロケーションカウンタの初期化

	suba.l	a5,a5			;(LOCATION,a6)
	suba.l	a4,a4			;(LOCOFFSET,a6)
	bsr	dopass2			;最適化を実行する
	move.l	a5,(LOCATION,a6)
	move.l	a4,(LOCOFFSET,a6)
	moveq.l	#SECT_TEXT,d0
	bsr	chgsection		;textセクションに戻す
	move.b	#SZ_LONG,(OPTMOREFLG,a6)
	tst.b	(OPTFLAG,a6)
	bne	asmpass21
asmpass29:
	rts

;----------------------------------------------------------------
dopass2:
  .if 89<=verno060
	move.w	(ICPUTYPE,a6),(CPUTYPE,a6)	;CPUTYPE,CPUTYPE2
  .endif
	bsr	tmpreadd0w
	move.w	d0,d1
	beq	dopass29		;テンポラリファイル終了
dopass21:
	clr.b	d1
	sub.w	d1,d0
	ror.w	#6,d1
	jsr	(pass2_tbl-4,pc,d1.w)
	bsr	tmpreadd0w
	move.w	d0,d1
	bne	dopass21
dopass29:
	rts

;----------------------------------------------------------------
;	テンポラリファイルコード処理アドレス
pass2_tbl:
	bra.w	linetop		;01	1行開始
	bra.w	symdata		;02	シンボル値
	bra.w	rpndata		;03	逆ポーランド式

	bra.w	dispadr		;04	(d,An)
	bra.w	disppc		;05	(d,PC)
	bra.w	indexadr	;06	(d,An,Rn)
	bra.w	indexpc		;07	(d,PC,Rn)
	bra.w	extcode		;08	拡張ワード
	bra.w	bdadr		;09	アドレスレジスタ間接ベースディスプレースメント
	bra.w	bdpc		;0A	PC間接ベースディスプレースメント
	bra.w	odisp		;0B	アウタディスプレースメント

	bra.w	bracmd		;0C	bra/bsr/b<cc>.s/.w/.l
	bra.w	cpbracmd	;0D	cpb<cc>.w/.l
	bra.w	dspcode		;0E	(d,An)/(d,PC)の命令コード
	bra.w	coderpn		;0F	命令コード埋め込み式データ
	bra.w	constdata	;10	アドレス非依存データ
	bra.w	bitfield	;11	ビットフィールド式データ
	bra.w	dscmd		;12	.ds
	bra.w	dcbcmd		;13	.dcb
	bra.w	aligncmd	;14	アラインメントの調整
	bra.w	sectchg		;15	セクション変更
	bra.w	ofstcmd		;16	.offset
	bra.w	equconst	;17	定数の.equ/.set
	bra.w	equexpr		;18	式・アドレスの.equ/.set
	bra.w	xdefcmd		;19	.xdef
	bra.w	prnctrl		;1A	リスト出力制御
	bra.w	pagecmd		;1B	.page
	bra.w	subttlcmd	;1C	.subttl
	bra.w	orgcmd		;1D	.org
	bra.w	endcmd		;1E	.end
	bra.w	incldopen	;1F	includeファイル開始
	bra.w	incldend	;20	includeファイル終了
	bra.w	macdef		;21	マクロ定義開始
	bra.w	macext		;22	マクロ展開開始
	bra.w	exitmcmd	;23	.exitm
	bra.w	reptcmd		;24	.rept展開開始
	bra.w	irpcmd		;25	.irp/.irpc展開開始
	bra.w	mdefbgn		;26	マクロ等定義開始
	bra.w	mdefend		;27	マクロ等定義終了
	bra.w	lncmd		;28	.ln
	bra.w	valcmd		;29	.val
	bra.w	tagcmd		;2A	.tag
	bra.w	scdshort	;2B	.endef(短形式)
	bra.w	scdlong		;2C	.endef(長形式)
	bra.w	funcend		;2D	.scl -1(関数定義終了)

	bra.w	fequset		;2E	.fequ/.fset
	bra.w	symdef		;2F	シンボル定義
	bra.w	fdcbcmd		;30	.dcb(浮動小数点実数)
	bra.w	jbracmd		;31	jbra/jbsr/jb<cc>
	bra.w	dispopc		;32	(d,OPC)
	bra.w	linkcmd		;33	link.w/.l

	bra.w	nopdeath	;34	削除すべきNOP
	bra.w	nopalive	;35	挿入されたNOP

	bra.w	prnadv		;36	PRNファイルへの先行出力

	bra.w	offsymcmd	;37	.offsym

	bra.w	error		;38	エラー発生

  .if 89<=verno060
	bra.w	cputype		;39	.cpu
  .endif

;----------------------------------------------------------------
nopdeath:				;34xx 削除すべきNOP
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w		;NOP
	cmp.w	#$4E71,d0
	beq	nopdeath_nul
	rts

nopdeath_nul:
;NOPは消滅するのでロケーションカウンタを増やさなくてよい
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,a4			;最適化によって減ったバイト数
	clr.w	d0
	move.l	d3,d1
	bra	fmodify

;----------------------------------------------------------------
nopalive:				;35xx 挿入されたNOP
	bra	constdata

  .if 89<=verno060
;----------------------------------------------------------------
cputype:				;39xx .cpu
	bsr	tmpreadd0w
	move.w	d0,(CPUTYPE,a6)		;CPUTYPE,CPUTYPE2
	rts
  .endif

;----------------------------------------------------------------
prnctrl:				;1Axx リスト出力制御
pagecmd:				;1Bxx .page
incldend:				;20xx includeファイル終了
exitmcmd:				;23xx .exitm
mdefbgn:				;26xx マクロ等定義開始
mdefend:				;27xx マクロ等定義終了
funcend:				;2Dxx .scl -1(関数定義終了)
prnadv:					;36xx PRNファイルへの先行出力
	rts				;何もしない

;----------------------------------------------------------------
detequ:					;17xx 値の確定している.equ
xdefcmd:				;19xx .xdef
subttlcmd:				;1Cxx .subttl
incldopen:				;1Fxx includeファイル開始
tagcmd:					;2Axx .tag
error:					;38xx エラー発生
	moveq.l	#2*2,d0
	bra	tempskip		;2ワード読み飛ばす

;----------------------------------------------------------------
macext:					;22xx マクロ展開開始
reptcmd:				;24xx .rept展開開始
	moveq.l	#3*2,d0
	bra	tempskip		;3ワード読み飛ばす

;----------------------------------------------------------------
macdef:					;21xx マクロ定義開始
	moveq.l	#4*2,d0
	bra	tempskip		;4ワード読み飛ばす

;----------------------------------------------------------------
irpcmd:					;25xx .irp/.irpc展開開始
	moveq.l	#5*2,d0
	bra	tempskip		;5ワード読み飛ばす

;----------------------------------------------------------------
scdshort:				;2Bxx .endef(短形式)
	moveq.l	#6*2,d0
	bra	tempskip		;6ワード読み飛ばす

;----------------------------------------------------------------
fequset:				;2Exx .fequ/.fset
	moveq.l	#8*2,d0
	bra	tempskip		;8ワード読み飛ばす

;----------------------------------------------------------------
scdlong:				;2Cxx .endef(長形式)
	moveq.l	#12*2,d0
	bra	tempskip		;12ワード読み飛ばす

;----------------------------------------------------------------
linetop:				;01xx 行開始コード
	move.l	a5,(LTOPLOC,a6)
	rts

;----------------------------------------------------------------
symdata:				;02xx シンボル値
	bsr	getdtsize
	add.l	d0,a5
	moveq.l	#2*2,d0
	bra	tempskip

;----------------------------------------------------------------
rpndata:				;03xx 逆ポーランド式
	bsr	getdtsize
	add.l	d0,a5
rpndata1:
	bsr	tmpreadd0w
	addq.w	#1,d0
	add.w	d0,d0
	bra	tempskip		;式を読み飛ばす

;----------------------------------------------------------------
lncmd:					;28xx .ln
	moveq.l	#1*2,d0
	bsr	tempskip		;命令コードを読み飛ばす
;	bra	skipexpr

;----------------------------------------------------------------
endcmd:					;1Exx .end
valcmd:					;29xx .val
skipexpr:				;後続のシンボル値/式を読み飛ばす
	bsr	tmpreadd0w
skipexpr1:
	and.w	#$FF00,d0
	cmp.w	#T_SYMBOL,d0
	bne	rpndata1		;式が続く場合
	moveq.l	#2*2,d0			;シンボル値が続く場合
	bra	tempskip

;----------------------------------------------------------------
constdata:				;10xx アドレス非依存データ
	addq.w	#1,d0
	ext.l	d0
	add.l	d0,a5
	addq.w	#1,d0
	bclr.l	#0,d0
	bra	tempskip		;あとに続くデータを読み飛ばす

;----------------------------------------------------------------
bitfield:				;11xx ビットフィールド式データ
	move.w	d0,d1
	addq.l	#2,a5
	moveq.l	#1*2,d0
	bsr	tempskip		;命令コードを読み飛ばす
	cmp.b	#TBF_OFWD,d1
	bne	skipexpr		;後続の式が1つの場合
	bsr	skipexpr
	bra	skipexpr

;----------------------------------------------------------------
dscmd:					;12xx .ds
	bsr	tmpreadd0l		;長さを読み出す
	add.l	d0,a5
	rts

;----------------------------------------------------------------
dcbcmd:					;13xx .dcb
	bsr	tmpreadd0w		;長さを読み出す
	move.w	d0,d1
	bsr	tmpreadd0w
	move.w	d0,d2
	bsr	getdtsize
	addq.w	#1,d1
	mulu.w	d0,d1			;生成するデータのサイズ
	add.l	d1,a5
	move.w	d2,d0
	bra	skipexpr1

;----------------------------------------------------------------
fdcbcmd:				;30xx .dcb(浮動小数点実数)
	move.w	d0,d1			;データ長
	bsr	tmpreadd0w		;長さを読み出す
	ext.l	d0
	addq.l	#1,d0
	add.l	d0,d0
	add.l	d0,d0
	moveq.l	#0,d2
fdcbcmd1:
	add.l	d0,d2
	dbra	d1,fdcbcmd1
	add.l	d2,a5
	moveq.l	#6*2,d0
	bra	tempskip		;6ワード読み飛ばす

;----------------------------------------------------------------
symdef:					;2Fxx シンボル定義
	bsr	tmpreadd0l		;シンボルへのポインタ
	move.l	d0,a0
	move.l	(LTOPLOC,a6),(SYM_VALUE,a0)
	move.b	(OPTCOUNT,a6),(SYM_OPTCOUNT,a0)
	rts

;----------------------------------------------------------------
equconst:				;17xx 定数の.equ/.set
	bsr	tmpreadd0l		;シンボルへのポインタ
	move.l	d0,a0
	bsr	tmpreadd0l		;シンボル値
	move.l	d0,(SYM_VALUE,a0)
	clr.w	(SYM_SECTION,a0)	;(SYM_ORGNUM)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a0)
	rts

;----------------------------------------------------------------
equexpr:				;18xx 式・アドレスの.equ/.set
	bsr	tmpreadd0l		;シンボルへのポインタ
	move.l	d0,a0
	bsr	tmpreadd0w
	bsr	calctmpexpr		;後続の式の値を得る
	cmp.w	#$00FF,d0
	bcc	equexpr9		;シンボル値が確定しない
	move.b	d0,(SYM_SECTION,a0)
	move.l	d1,(SYM_VALUE,a0)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a0)
	move.b	(OPTCOUNT,a6),(SYM_OPTCOUNT,a0)
equexpr9:
	rts

;----------------------------------------------------------------
aligncmd:				;14xx アラインメントの調整
	moveq.l	#1,d1
	lsl.l	d0,d1
	subq.l	#1,d1			;d1=2^d0 - 1
	move.l	a5,d2
	move.l	d2,d3
	add.l	d1,d2
	not.l	d1
	and.l	d1,d2
	movea.l	d2,a5
	sub.l	d3,d2
	bsr	tmpreadd0w		;パディングワードは読み飛ばす
	GETFPTR	TEMPFILPTR,d1		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w		;前回のパディング長を読み出す
	sub.w	d2,d0			;最適化によって減ったバイト数
	adda.w	d0,a4
	move.w	d2,d0
	bra	fmodify			;ロケーションカウンタ値を修正する

;----------------------------------------------------------------
sectchg:				;15xx セクション変更
;offsymでシンボルなしのときも0になってしまうが
;パス2以降では二重定義エラーは出ないはずなので無視する
	sf.b	(OFFSYMMOD,a6)
	move.l	a5,(LOCATION,a6)
	move.l	a4,(LOCOFFSET,a6)
	bsr	chgsection
	movea.l	(LOCATION,a6),a5
	movea.l	(LOCOFFSET,a6),a4
	rts

;----------------------------------------------------------------
offsymcmd:				;37xx .offsym
	move.l	a5,(LOCATION,a6)
	move.l	a4,(LOCOFFSET,a6)
	moveq.l	#0,d0
	bsr	chgsection
	bsr	tmpreadd0l		;初期値を読み出す
	move.l	d0,(OFFSYMVAL,a6)
	bsr	tmpreadd0l		;シンボルを読み出す
	move.l	d0,(OFFSYMSYM,a6)
	bsr	tmpreadd0l		;仮シンボルを読み出す
	move.l	d0,(OFFSYMTMP,a6)
	move.b	#1,(OFFSYMMOD,a6)	;offsymでシンボルあり
	suba.l	a5,a5
	suba.l	a4,a4
	rts

;----------------------------------------------------------------
ofstcmd:				;16xx .offset
	move.l	a5,(LOCATION,a6)
	move.l	a4,(LOCOFFSET,a6)
	moveq.l	#0,d0
	bsr	chgsection
	bsr	tmpreadd0l		;オフセット値を読み出す
	move.l	d0,a5
	suba.l	a4,a4
	rts

;----------------------------------------------------------------
orgcmd:					;1Dxx .org
	bsr	tmpreadd0l		;ロケーションカウンタ値を読み出す
	move.l	d0,a5
	suba.l	a4,a4
	addq.b	#1,(ORGNUM,a6)
	rts

;----------------------------------------------------------------
extcode:				;08xx 拡張ワード
	addq.l	#2,a5
	GETFPTR	TEMPFILPTR,d0		;現在のファイルポインタ位置を得る
	move.l	d0,(OPTEXTPOS,a6)
	bsr	tmpreadd0w		;拡張ワードを読み出す
	move.w	d0,(OPTEXTCODE,a6)
	rts

;----------------------------------------------------------------
dspcode:				;0Exx (d,An)/(d,PC)の命令コード
	addq.l	#2,a5
	GETFPTR	TEMPFILPTR,d0		;現在のファイルポインタ位置を得る
	move.l	d0,(OPTDSPPOS,a6)
	bsr	tmpreadd0w		;命令コードを読み出す
	move.w	d0,(OPTDSPCODE,a6)
	rts

;----------------------------------------------------------------
coderpn:				;0Fxx 命令コード埋め込み式データ
	addq.l	#2,a5
	GETFPTR	TEMPFILPTR,d0		;現在のファイルポインタ位置を得る
	move.l	d0,(OPTDSPPOS,a6)
	bsr	tmpreadd0w		;命令コードを読み出す
	move.w	d0,(OPTDSPCODE,a6)
	bra	skipexpr

;----------------------------------------------------------------
dispadr:				;04xx (d,An)
	move.b	d0,d5			;(moveデスティネーションならtrue)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	dispadr5		;最適化対象コードの場合
	beq	skipexpr1		;(ディスプレースメントはサプレスされている)
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
dispadr1:
	cmpi.b	#SZ_WORD,d2
	bne	dispadr2
	addq.l	#2,a5			;ディスプレースメントサイズが.wの場合
	rts

dispadr2:
	addq.l	#6,a5			;			     .lの場合
dispadr9:
	rts

dispadr8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	dispadr1

dispadr5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	beq	dispadr6
	cmp.b	#SECT_RDATA,d0
	bcc	dispadr8		;定数でない場合は最適化できない
	bra	dispadr5_l

dispadr6:
	move.l	d1,d0			;(tst.l d1 & move.w d1,d0)
	beq	dispadr5_nul
	bra68	d4,dispadr5_w		;68000/68010なら0でなければ.w
	tst.b	(CPUTYPE2,a6)
	bne	dispadr5_w
	ext.l	d0
	cmp.l	d0,d1
	beq	dispadr5_w
dispadr5_l:
	addq.l	#6,a5
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	dispadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#4,a4			;(.w→.lのみ)
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(d,An)→(bd,An)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	tst.b	d5
	bne	dispadr5_l1
	and.w	#.not.$0038,d0
	or.w	#EAC_BDADR,d0
	move.w	d0,(OPTDSPCODE,a6)
	bra	fmodify

dispadr5_l1:				;moveのデスティネーション実効アドレス
	and.w	#.not.$01C0,d0
	or.w	#EAC_BDADR<<3,d0
	bra	fmodify

dispadr5_w:
	addq.l	#2,a5
	moveq.l	#SZ_WORD|ESZ_OPT,d0
	cmp.b	d0,d2
	beq	dispadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#4,a4			;(.l→.wのみ)
	move.b	d0,d2			;(後で伸びる場合がある)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(bd,An)→(d,An)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	tst.b	d5
	bne	dispadr5_w1
	and.w	#.not.$0038,d0
	or.w	#EAC_DSPADR,d0
	move.w	d0,(OPTDSPCODE,a6)
	bra	fmodify

dispadr5_w1:				;moveのデスティネーション実効アドレス
	and.w	#.not.$01C0,d0
	or.w	#EAC_DSPADR<<3,d0
	bra	fmodify

dispadr5_nul:
	tst.b	(NONULDISP,a6)
	bne	dispadr5_w
	st.b	(OPTFLAG,a6)		;最適化が行われた
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	dispadr5_nul1
	addq.l	#6,a4			;.l→0の場合
	bra	dispadr5_nul2

dispadr5_nul1:
	addq.l	#2,a4			;.w→0の場合
dispadr5_nul2:
	move.w	d2,d0
	clr.b	d0			;ディスプレースメントサプレス確定
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(bd,An)/(d,An)→(An)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	tst.b	d5
	bne	dispadr5_nul5
	and.w	#.not.$0038,d0
	or.w	#EAC_ADR,d0
	move.w	d0,(OPTDSPCODE,a6)
	bra	fmodify

dispadr5_nul5:				;moveのデスティネーション実効アドレス
	and.w	#.not.$01C0,d0
	or.w	#EAC_ADR<<3,d0
	bra	fmodify

;----------------------------------------------------------------
disppc:					;05xx (d,PC)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	disppc5			;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
disppc1:
	cmpi.b	#SZ_WORD,d2
	bne	disppc2
	addq.l	#2,a5			;ディスプレースメントサイズが.wの場合
	rts

disppc2:
	addq.l	#6,a5			;			     .lの場合
disppc9:
	rts

disppc8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	disppc1

disppc5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	bmi	disppc8			;値が未定なので最適化できない
	bne	disppc6
	move.w	d1,d0			;定数の場合
	ext.l	d0
	cmp.l	d0,d1
	beq	disppc5_w
	bra	disppc5_l

disppc6:				;アドレス値の場合
	cmp.b	(SECTION,a6),d0
	bne	disppc8			;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	disppc5_w
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	disppc5_l		;$8000以上なら.w→.l
	cmp.l	#$8004,d1
	bcs	disppc5_w		;$8004未満なら.l→.w
	addq.l	#6,a5
	rts

disppc5_l:
	addq.l	#6,a5
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	disppc9			;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#4,a4			;(.w→.lのみ)
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(d,PC)→(bd,PC)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	and.w	#.not.$003F,d0
	or.w	#EAC_BDPC,d0
	bra	fmodify

disppc5_w:
	addq.l	#2,a5
	moveq.l	#SZ_WORD|ESZ_OPT,d0
	cmp.b	d0,d2
	beq	disppc9			;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#4,a4			;(.l→.wのみ)
	move.b	d0,d2			;(後で伸びる場合がある)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(bd,An)→(d,An)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	and.w	#.not.$003F,d0
	or.w	#EAC_DSPPC,d0
	bra	fmodify

;----------------------------------------------------------------
dispopc:				;32xx (d,OPC)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	dispopc5		;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
dispopc1:
	cmpi.b	#SZ_WORD,d2
	bne	dispopc2
	addq.l	#2,a5			;ディスプレースメントサイズが.wの場合
	rts

dispopc2:
	addq.l	#4,a5			;-2			     .lの場合
dispopc9:
	rts

dispopc8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	dispopc1

dispopc5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	bmi	dispopc8		;値が未定なので最適化できない
	bne	dispopc6
	move.w	d1,d0			;定数の場合
	ext.l	d0
	cmp.l	d0,d1
	beq	dispopc5_w
	bra	dispopc5_l

dispopc6:				;アドレス値の場合
	cmp.b	(SECTION,a6),d0
	bne	dispopc8		;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	dispopc5_w
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	dispopc5_l		;$8000以上なら.w→.l
	cmp.l	#$8002,d1		;-2
	bcs	dispopc5_w		;$8002未満なら.l→.w
	addq.l	#4,a5			;-2
	rts

dispopc5_l:
	addq.l	#4,a5			;-2
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	dispopc9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#2,a4			;-2(.w→.lのみ)
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(d,PC)→xxxx.lの変更を行う
	move.l	(OPTDSPPOS,a6),d1
	and.w	#.not.$003F,d0
	or.w	#EAC_ABSL,d0		;-2
	bra	fmodify

dispopc5_w:
	addq.l	#2,a5
	moveq.l	#SZ_WORD|ESZ_OPT,d0
	cmp.b	d0,d2
	beq	dispopc9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,a4			;-2(.l→.wのみ)
	move.b	d0,d2			;(後で伸びる場合がある)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTDSPCODE,a6),d0	;(bd,An)→(d,An)の変更を行う
	move.l	(OPTDSPPOS,a6),d1
	and.w	#.not.$003F,d0
	or.w	#EAC_DSPPC,d0
	bra	fmodify

;----------------------------------------------------------------
indexadr:				;06xx (d,An,Rn)
	bsr	tmpreadd0w		;拡張ワードは読み飛ばす(pass 3で変更する)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	indexadr5		;最適化対象コードの場合
indexadr0:
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
indexadr1:
	ext.w	d2
	move.b	(indexadr_tbl,pc,d2.w),d2
	adda.w	d2,a5
indexadr9:
	rts

indexadr_tbl:	.dc.b	-1,4,6,2

indexadr8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	indexadr1

indexadr5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	beq	indexadr6
	cmp.b	#SECT_RDATA,d0
	bcc	indexadr8		;定数でない場合は最適化できない
	bra	indexadr5_l

indexadr6:				;定数の場合
	move.b	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	indexadr5_s
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	indexadr5_w
indexadr5_l:
	addq.l	#6,a5
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	indexadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#2,a4			;.w→.l
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	indexdar5_l1
	subq.l	#2,a4			;.s→.l
indexdar5_l1:
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bra	fmodify

indexadr5_w:
	addq.l	#4,a5
	move.w	d2,d0
	move.l	d3,d1
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	indexadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	indexadr5_w1
	subq.l	#2,a4			;.s→.wの場合
	move.b	#SZ_WORD,d0		;(サイズが伸びてしまった場合はこれ以上最適化しない)
	tst.b	(OPTMOREFLG,a6)
	bpl	fmodify
	move.b	#SZ_WORD|ESZ_OPT,d0	;最初の1回ならさらに最適化できる
	bra	fmodify

indexadr5_w1:
	addq.l	#2,a4			;.l→.wの場合
	move.b	#SZ_WORD|ESZ_OPT,d0	;(後で伸びる場合がある)
	bra	fmodify

indexadr5_s:
	addq.l	#2,a5
	cmp.b	#SZ_SHORT|ESZ_OPT,d2
	beq	indexadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	move.b	d2,d0
	bsr	getdtsize
	add.l	d0,a4
	move.w	d2,d0
	move.b	#SZ_SHORT|ESZ_OPT,d0	;(後で伸びる場合がある)
	move.l	d3,d1
	bra	fmodify

;----------------------------------------------------------------
indexpc:				;07xx (d,PC,Rn)
	bsr	tmpreadd0w		;拡張ワードは読み飛ばす(pass 3で変更する)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bpl	indexadr0
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	bmi	indexadr8		;定数でない場合は最適化できない
	beq	indexadr6		;定数の場合
	cmp.b	(SECTION,a6),d0		;アドレス値の場合
	bne	indexadr8		;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	move.b	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	indexadr5_s
	move.b	d2,d4
	and.b	#3,d4
	ext.w	d4
	moveq.l	#0,d0
	move.b	(indexpc_tbl1,pc,d4.w),d0
	cmp.l	d0,d1
	bcs	indexadr5_s		;$82未満なら.w→.s / $84未満なら.l→.s
	cmp.l	#-$8000,d1
	blt	indexadr5_l
	add.w	d4,d4
	move.w	(indexpc_tbl2,pc,d4.w),d0
	cmp.l	d0,d1
	blt	indexadr5_w		;$7FFE未満なら.s→.w / $8002未満なら.l→.w
	bra	indexadr5_l

indexpc_tbl1:	.dc.b	-1,$82,$84,$80
indexpc_tbl2:	.dc.w	-1,$8002,$8000,$7FFE

;----------------------------------------------------------------
odisp:					;0Bxx アウタディスプレースメント
	moveq.l	#$0003,d5
	bra	bdodadr

;----------------------------------------------------------------
bdadr:					;09xx アドレスレジスタ間接ベースディスプレースメント
	moveq.l	#$0030,d5
bdodadr:
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	bdodadr5		;最適化対象コードの場合
	beq	skipexpr1		;(ディスプレースメントはサプレスされている)
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
bdodadr1:
	cmpi.b	#SZ_WORD,d2
	bne	bdodadr2
	addq.l	#2,a5			;ディスプレースメントサイズが.wの場合
	rts

bdodadr2:
	addq.l	#4,a5			;			     .lの場合
bdodadr9:
	rts

bdodadr8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	bdodadr1

bdodadr5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	beq	bdodadr6
	cmp.b	#SECT_RDATA,d0
	bcc	bdodadr8		;定数でない場合は最適化できない
	bra	bdodadr5_l

bdodadr6:				;定数の場合
	move.l	d1,d0			;(tst.l d1 & move.w d1,d0)
	beq	bdodadr5_nul
	ext.l	d0
	cmp.l	d0,d1
	beq	bdodadr5_w
bdodadr5_l:
	addq.l	#4,a5
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	bdodadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#2,a4			;(.w→.lのみ)
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTEXTCODE,a6),d0	;拡張ワードの変更を行う
	move.l	(OPTEXTPOS,a6),d1
	move.w	#EXW_BDL|EXW_ODL,d2
	and.w	d5,d2
	not.w	d5
	and.w	d5,d0
	or.w	d2,d0
	move.w	d0,(OPTEXTCODE,a6)
	bra	fmodify

bdodadr5_w:
	addq.l	#2,a5
	moveq.l	#SZ_WORD|ESZ_OPT,d0
	cmp.b	d0,d2
	beq	bdodadr9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,a4			;(.l→.wのみ)
	move.b	d0,d2			;(後で伸びる場合がある)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTEXTCODE,a6),d0	;拡張ワードの変更を行う
	move.l	(OPTEXTPOS,a6),d1
	move.w	#EXW_BDW|EXW_ODW,d2
	and.w	d5,d2
	not.w	d5
	and.w	d5,d0
	or.w	d2,d0
	move.w	d0,(OPTEXTCODE,a6)
	bra	fmodify

bdodadr5_nul:
	tst.b	(NONULDISP,a6)
	bne	bdodadr5_w
	st.b	(OPTFLAG,a6)		;最適化が行われた
	move.b	d2,d0
	bsr	getdtsize
	add.l	d0,a4
	move.w	d2,d0
	clr.b	d0			;ディスプレースメントサプレス確定
	move.l	d3,d1
	bsr	fmodify
	move.w	(OPTEXTCODE,a6),d0	;拡張ワードの変更を行う
	move.l	(OPTEXTPOS,a6),d1
	move.w	#EXW_BDNUL|EXW_ODNUL,d2
	and.w	d5,d2
	not.w	d5
	and.w	d5,d0
	or.w	d2,d0
	move.w	d0,(OPTEXTCODE,a6)
	bra	fmodify

;----------------------------------------------------------------
bdpc:					;0Axx PC間接ベースディスプレースメント
	moveq.l	#$0030,d5
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	bdpc5			;最適化対象コードの場合
	beq	skipexpr1		;(ベースディスプレースメントはサプレスされている)
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
	bra	bdodadr1

bdpc5:					;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	bmi	bdodadr8		;定数でない場合は最適化できない
	beq	bdodadr6		;定数の場合
	cmp.b	(SECTION,a6),d0		;アドレス値の場合
	bne	bdodadr8		;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	addq.l	#2,d1
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bdodadr5_w
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	bdodadr5_l		;$8000以上なら.w→.l
	cmp.l	#$8002,d1
	bcs	bdodadr5_w		;$8002未満なら.l→.w
	addq.l	#4,a5
	rts

;----------------------------------------------------------------
linkcmd:				;33xx link.w/.l
	addq.l	#2,a5
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	linkcmd5		;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
linkcmd1:
	cmpi.b	#SZ_WORD,d2
	beq	linkcmd2
	addq.l	#2,a5			;ディスプレースメントサイズが.lの場合
linkcmd2:
	addq.l	#2,a5			;			     .wの場合
linkcmd9:
	rts

linkcmd8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	linkcmd1

linkcmd5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	beq	linkcmd6
	cmp.b	#SECT_RDATA,d0
	bcc	linkcmd8		;定数でない場合は最適化できない
	bra	linkcmd5_l

linkcmd6:
	move.l	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	linkcmd5_w
linkcmd5_l:
	addq.l	#4,a5
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	beq	linkcmd9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	subq.l	#2,a4			;(.w→.lのみ)
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bra	fmodify

linkcmd5_w:
	addq.l	#2,a5
	moveq.l	#SZ_WORD|ESZ_OPT,d0
	cmp.b	d0,d2
	beq	linkcmd9		;最適化前のサイズと同じなので何もしない
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,a4			;(.l→.wのみ)
	move.b	d0,d2			;(後で伸びる場合がある)
	move.w	d2,d0
	move.l	d3,d1
	bra	fmodify

;----------------------------------------------------------------
bracmd:					;0Cxx bra/bsr/b<cc>.s/.w/.l
	bsr	tmpreadd0w		;命令コード
bracmd0:
	move.w	d0,d5
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	bracmd5			;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
	and.b	#3,d2			;$40を消す
bracmd1:
	ext.w	d2
	move.b	(bracmd_tbl,pc,d2.w),d2
	adda.w	d2,a5
	rts

bracmd_tbl:	.dc.b	0,4,6,2

bracmd8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	bracmd1

bracmd5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	ble	bracmd8			;値がアドレス値でないので最適化できない
	cmp.b	(SECTION,a6),d0		;アドレス値の場合
	bne	bracmd8			;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	subq.l	#2,d1			;(命令コードの分)
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	bracmd5_w
bracmd6:
	cmp.b	#SZ_SHORT|ESZ_OPT,d2
	beq	bracmd5_s
	cmp.b	#ESZ_OPT,d2
	beq	bracmd5_nul

bracmd5_l:				;.l→…
	moveq.l	#4,d0
	cmp.l	d0,d1
	beq	bracmd7_nul		;次の命令へのブランチの場合
	move.b	#SZ_SHORT|ESZ_OPT,d2
	moveq.l	#4,d4
	move.w	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_s
	cmp.l	#$84,d1
	bcs	bracmd7_s		;$84未満なら.l→.s
	move.b	#SZ_WORD|ESZ_OPT,d2
	moveq.l	#2,d4
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_w
	cmp.l	#$8002,d1
	bcs	bracmd7_w		;$8002未満なら.l→.w
	addq.l	#6,a5			;サイズが変化しない
	rts

bracmd5_w:				;.w→…
	moveq.l	#2,d0
	cmp.l	d0,d1
	beq	bracmd7_nul		;次の命令へのブランチの場合
	move.b	#SZ_SHORT|ESZ_OPT,d2
	moveq.l	#2,d4
	move.w	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_s
	cmp.l	#$82,d1
	bcs	bracmd7_s		;$82未満なら.w→.s

	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	bne	bracmd7_l		;.w→.l
	addq.l	#4,a5			;サイズが変化しない
	rts

bracmd5_s:				;.s→…
	tst.l	d1
	beq	bracmd7_nul		;次の命令へのブランチの場合
	move.b	#SZ_WORD,d2
	moveq.l	#-2,d4
	move.b	d1,d0
	ext.w	d0
	cmp.w	d0,d1
	bne	bracmd7_w		;.s→.w(.s→.lはありえない)
	addq.l	#2,a5			;サイズが変化しない
bracmd9:
	rts

bracmd5_nul:				;0→…
	moveq.l	#-2,d0
	cmp.l	d0,d1
	beq	bracmd9			;サイズが変化しない
	tst.l	d1
	beq	bracmd7_w0		;次の命令へのブランチ
	move.b	#SZ_SHORT,d2		;サイズが伸びたらそこで確定する
	moveq.l	#-2,d4			;(0→.l/0→.wはありえない)
bracmd7_s:				;→.s
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,a5
	add.l	d4,a4
	move.w	d2,d0
	move.l	d3,d1
	bra	fmodify

bracmd7_w0:				;次の命令へのブランチの場合(0→.w)
	moveq.l	#-2,d1
bracmd7_w1:				;次の命令へのブランチをサプレスしない場合
	move.l	d1,d4
	subq.l	#2,d4			;.s:-2/.w:0/.l:2bytes縮小
	move.b	#SZ_WORD,d2
bracmd7_w:				;→.w
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#4,a5
	add.l	d4,a4
	move.w	d2,d0
	move.l	d3,d1
	bra	fmodify

bracmd7_l:				;.w→.l
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#6,a5
	subq.l	#2,a4
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bra	fmodify

;直後へのbra/bcc/bsr
bracmd7_nul:
	addq.l	#2,d1
;d1.l:元のサイズ(.s=2,.w=4,bra.l=6,jbra.l=8)
	cmp.w	#$6100,d5
	beq	bracmd7_nul_bsr
	tst.b	(NOBRACUT,a6)
	bne	bracmd7_nul_bcc
;直後へのbcc/braを削除するとき
	st.b	(OPTFLAG,a6)		;最適化が行われた
	adda.l	d1,a4			;→nul
					;命令がなくなるのでa5(ロケーションカウンタ)は増やさない
	move.w	d2,d0
	move.b	#ESZ_OPT,d0		;次回も必ず最適化対象とする
	move.l	d3,d1
	bra	fmodify

;直後へのbsrなので.wにしてpeaに変換するとき
bracmd7_nul_bsr:
	move.b	#SZ_WORD|$40,d2		;$40は直後へのbsr
	bra	bracmd7_nul_b

;直後へのbra/bccでNOBRACUT=trueなので.wで出力するとき
bracmd7_nul_bcc:
	move.b	#SZ_WORD,d2		;bsrではないので$40をセットしないこと
					;(objgenが$40を直後へのbsrと判断する)
bracmd7_nul_b:
	subq.l	#4,d1			;.s=-2,.w=0,bra.l=2,jbra.l=4
	beq	bracmd7_nul_b_w
	st.b	(OPTFLAG,a6)		;.w→.wのときはサイズが変化しない
bracmd7_nul_b_w:
	adda.l	d1,a4			;→.w
	addq.l	#4,a5			;.w固定
	move.w	d2,d0
	move.l	d3,d1
	bra	fmodify

;----------------------------------------------------------------
jbracmd:				;31xx jbra/jbsr/jb<cc>
	bsr	tmpreadd0w		;命令コード
	cmp.w	#$6100,d0
	bls	bracmd0			;jbra/jbsrはbra/bsrと同じ
	move.w	d0,d5
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	jbracmd5		;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
jbracmd1:
	ext.w	d2
	move.b	(jbracmd_tbl,pc,d2.w),d2
	adda.w	d2,a5
	rts

jbracmd_tbl:	.dc.b	0,4,8,2

jbracmd8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	jbracmd1

jbracmd5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	ble	jbracmd8		;値がアドレス値でないので最適化できない
	cmp.b	(SECTION,a6),d0		;アドレス値の場合
	bne	jbracmd8		;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	subq.l	#2,d1			;(命令コードの分)
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	jbracmd5_w
	cmp.b	#SZ_LONG|ESZ_OPT,d2
	bne	bracmd6			;.w/.l以外はb<cc>と同じ

jbracmd5_l:				;.l→…
	moveq.l	#6,d0			;+2
	cmp.l	d0,d1
	beq	bracmd7_nul		;次の命令へのブランチの場合
	move.b	#SZ_SHORT|ESZ_OPT,d2
	moveq.l	#6,d4			;+2
	move.w	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_s
	cmp.l	#$86,d1
	bcs	bracmd7_s		;+2 $86未満なら.l→.s
	move.b	#SZ_WORD|ESZ_OPT,d2
	moveq.l	#4,d4			;+2
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_w
	cmp.l	#$8004,d1
	bcs	bracmd7_w		;+2 $8004未満なら.l→.w
	addq.l	#8,a5			;+2 サイズが変化しない
	rts

jbracmd5_w:				;.w→…
	moveq.l	#2,d0
	cmp.l	d0,d1
	beq	bracmd7_nul		;次の命令へのブランチの場合
	move.b	#SZ_SHORT|ESZ_OPT,d2
	moveq.l	#2,d4
	move.w	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	bracmd7_s
	cmp.l	#$82,d1
	bcs	bracmd7_s		;$82未満なら.w→.s

	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	bne	jbracmd7_l		;.w→.l
	addq.l	#4,a5			;サイズが変化しない
	rts

jbracmd7_l:				;.w→.l
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#8,a5			;+2
	subq.l	#2,a4
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bra	fmodify

;----------------------------------------------------------------
cpbracmd:				;0Dxx cpb<cc>.w/.l
	bsr	tmpreadd0w		;命令コードは読み飛ばす(pass 3で変更する)
	GETFPTR	TEMPFILPTR,d3		;現在のファイルポインタ位置を得る
	bsr	tmpreadd0w
	move.w	d0,d2
	tst.b	d0
	bmi	cpbracmd5		;最適化対象コードの場合
	bsr	skipexpr1		;最適化対象でないので後続の式を読み飛ばす
cpbracmd1:				;(命令サプレスで確定することはない)
	cmpi.b	#SZ_WORD,d2
	bne	cpbracmd2
	addq.l	#4,a5			;ディスプレースメントサイズが.wの場合
	rts

cpbracmd2:
	addq.l	#6,a5			;			     .lの場合
	rts

cpbracmd8:				;最適化できない場合
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	move.w	d2,d0
	move.l	d3,d1
	bsr	fmodify
	bra	cpbracmd1

cpbracmd5:				;最適化対象コード
	bsr	calctmpexpr		;後続の式の値を計算する
	tst.b	d0
	ble	cpbracmd8		;値がアドレス値でないので最適化できない
	cmp.b	(SECTION,a6),d0		;アドレス値の場合
	bne	cpbracmd8		;セクションが違うので最適化できない
	sub.l	a5,d1			;現在のアドレスからの相対値
	subq.l	#2,d1			;(命令コードの分)
	cmp.b	#SZ_WORD|ESZ_OPT,d2
	beq	cpbracmd5_w
	cmp.b	#ESZ_OPT,d2
	beq	cpbracmd5_nul
cpbracmd5_l:				;.l→…
	moveq.l	#4,d0
	cmp.l	d0,d1
	beq	cpbracmd7_nul		;次の命令へのブランチ
	move.b	#SZ_WORD|ESZ_OPT,d2
	moveq.l	#2,d4			;縮む場合に後退するバイト数
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	beq	cpbracmd7_w
	cmp.l	#$8002,d1
	bcs	cpbracmd7_w		;$8002未満なら.l→.w
	addq.l	#6,a5			;サイズが変化しない
	rts

cpbracmd5_w:				;.w→…
	moveq.l	#2,d0
	cmp.l	d0,d1
	beq	cpbracmd7_nul		;次の命令へのブランチ
	move.w	d1,d0
	ext.l	d0
	cmp.l	d0,d1
	bne	cpbracmd7_l
	addq.l	#4,a5			;サイズが変化しない
cpbracmd9:
	rts

cpbracmd5_nul:				;0→…
	moveq.l	#-2,d0
	cmp.l	d0,d1
	beq	cpbracmd9		;サイズが変化しない
	move.b	#SZ_WORD,d2		;サイズが伸びたらそこで確定する
	moveq.l	#-4,d4			;(0→.lはありえない)
cpbracmd7_w:				;→.w
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#4,a5
	add.l	d4,a4
	move.w	d2,d0
	move.l	d3,d1
	bra	fmodify

cpbracmd7_l:				;.w→.l
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#6,a5
	subq.l	#2,a4
	move.w	d2,d0
	move.b	(OPTMOREFLG,a6),d0	;(最初のみESZ_OPT)
	move.l	d3,d1
	bra	fmodify

cpbracmd7_nul:				;→0(ブランチ命令がサプレスされる場合)
	tst.b	(NOBRACUT,a6)
	beq	cpbracmd7_nul1
	move.l	d1,d4
	subq.l	#2,d4
	move.b	#SZ_WORD,d2
	bra	cpbracmd7_w

cpbracmd7_nul1:
	st.b	(OPTFLAG,a6)		;最適化が行われた
	addq.l	#2,d1
	add.l	d1,a4
	move.w	d2,d0
	move.b	#ESZ_OPT,d0		;次回も必ず最適化対象とする
	move.l	d3,d1
	bra	fmodify


;----------------------------------------------------------------
;	サブルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;	テンポラリファイルからシンボル番号・式を読み込み、その値を得る
;	in :d0.w=シンボル値/式を表わすテンポラリファイルコード
;	out:d0.w=結果の属性(0:定数/1～4:アドレス値(セクション番号)/
;			    $FFFF:未定/$01FF:オフセット付き外部参照/$02FF:外部参照値)
;	    d1.l=結果の値
calctmpexpr:
	move.l	a1,-(sp)
	and.w	#$FF00,d0
	cmp.w	#T_SYMBOL,d0
	bne	calctmpexpr5

	bsr	tmpreadd0l		;シンボル値が続く場合
	movea.l	d0,a1
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a1)	;(ST_VALUE or ST_LOCAL)
	bhi	calctmpexpr9		;数値シンボルでない
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	blo	calctmpexpr9		;未定義シンボル

	clr.w	d0
	move.b	(SYM_SECTION,a1),d0
	beq	calctmpexpr2
	cmp.b	(SECTION,a6),d0
	bne	calctmpexpr2
	move.b	(SYM_ORGNUM,a1),d1
	cmp.b	(ORGNUM,a6),d1
	bne	calctmpexpr2
	move.b	(SYM_OPTCOUNT,a1),d1
	cmp.b	(OPTCOUNT,a6),d1
	beq	calctmpexpr2
	move.l	(SYM_VALUE,a1),d1
	sub.l	a4,d1
	movea.l	(sp)+,a1
	rts

calctmpexpr2:
	move.l	(SYM_VALUE,a1),d1
	movea.l	(sp)+,a1
	rts

calctmpexpr5:
	move.l	a5,(LOCATION,a6)
	move.l	a4,(LOCOFFSET,a6)
	bsr	tmpreadd0w		;式が続く場合
	move.w	d0,d1			;逆ポーランド式の長さ
	lea.l	(OPRBUF,a6),a1
calctmpexpr6:
	bsr	tmpreadd0w		;式本体を読み込む
	move.w	d0,(a1)+
	dbra	d1,calctmpexpr6
	clr.w	(a1)+			;(エンドコード)
	lea.l	(OPRBUF,a6),a1
	bsr	calcrpn			;読み込んだ式を計算する
	movea.l	(sp)+,a1
	rts

calctmpexpr9:
	moveq.l	#-1,d0			;値が未定
	movea.l	(sp)+,a1
	rts


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;
;	Revision 2.6  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 2.5  1999  3/ 2(Tue) 17:04:08 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 T_ERRORを$FF00から通常のコードに変更
;
;	Revision 2.4  1999  2/27(Sat) 23:44:02 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.3  1999  2/24(Wed) 22:03:04 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.2  1998 10/10(Sat) 01:53:40 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 2.1  1997 10/13(Mon) 15:36:35 M.Kamada
;	+51 直後へのbsr→pea
;	+52 jmp/jsrを最適化する
;
;	Revision 2.0  1997 10/12(Sun) 18:50:14 M.Kamada
;	+50 fadd.d (sp),fp0;bra @f;nop;@@:のbraが最適化されないバグを修正
;	+51 bra @f;.rept 30;fadd.x fp0,fp0;.endm;@@:のbraが最適化されないバグを修正
;
;	Revision 1.9  1997  9/14(Sun) 16:30:23 M.Kamada
;	+46 error.sを分離
;
;	Revision 1.8  1997  6/25(Wed) 13:37:15 M.Kamada
;	+33 プレデファインシンボルCPUに対応する
;	+34 プレデファインシンボルに対応
;
;	Revision 1.7  1997  2/ 1(Sat) 23:31:32 M.Kamada
;	+13 bdpcの最適化処理のバグを修正
;
;	Revision 1.6  1996 12/15(Sun) 01:30:51 M.Kamada
;	+07 F43G対策
;		削除すべきNOPの処理を追加した
;
;	Revision 1.5  1994/07/12  14:58:40  nakamura
;	link命令に対する最適化処理を追加した
;
;	Revision 1.4  1994/03/06  11:31:16  nakamura
;	jbra,jbsr,jbccおよびopcに対する最適化処理の追加
;
;	Revision 1.3  1994/02/24  12:13:12  nakamura
;	32KB以上後方へのブランチの最適化に失敗するのを修正した。
;
;	Revision 1.2  1994/02/20  13:52:18  nakamura
;	次の命令へのbsrの最適化に失敗するバグを修正。
;
;	Revision 1.1  1994/02/16  15:33:32  nakamura
;	Initial revision
;
;
