;----------------------------------------------------------------
;	X68k High-speed Assembler
;		オブジェクトファイル生成
;		< objgen.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2015  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	symbol.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	cputype.equ
	.include	eamode.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	パス3(オブジェクトファイルの生成)
;----------------------------------------------------------------
asmpass3::
	move.b	#3,(ASMPASS,a6)
	tst.b	(MAKEPRN,a6)
	beq	asmpass31
	lea.l	(SOURCEPTR,a6),a1
	bsr	frewind			;ソースファイル先頭に移動
	move.l	a1,(INPFILPTR,a6)
asmpass31:
	move.l	(CPUSYMBOL,a6),d0
	beq	asmpass319
	movea.l	d0,a1
	move.l	(STARTCPU,a6),(SYM_VALUE,a1)
asmpass319:
	lea.l	(TEMPFILPTR,a6),a1
	bsr	frewind			;テンポラリファイル先頭に移動
	lea.l	(OBJFILPTR,a6),a0
	move.l	a0,(OUTFILPTR,a6)
	movea.l	(OBJFILE,a6),a0
	bsr	createopen		;オブジェクトファイルのオープン

	clr.w	(NUMOFERR,a6)
	sf.b	(ISASMEND,a6)
	clr.l	(DSBSIZE,a6)
	clr.l	(OBJLENCTR,a6)
	sf.b	(ISOBJOUT,a6)
	clr.w	(OBJCONCTR,a6)

	clr.w	(IFNEST,a6)
	clr.w	(INCLDNEST,a6)
	clr.w	(MACNEST,a6)
	clr.w	(MACREPTNEST,a6)
	clr.w	(MACLOCSMAX,a6)
	sf.b	(ISNLIST,a6)
	clr.w	(PAGEFLG,a6)
	sf.b	(ISMACDEF,a6)

	move.w	(ICPUTYPE,a6),(CPUTYPE,a6)	;CPUTYPE,CPUTYPE2

	bsr	makeobjhead		;オブジェクトヘッダの作成
	bsr	resetlocctr		;ロケーションカウンタの初期化
	bsr	outaligninfo		;アラインメント情報の出力
	bsr	outxrefdef		;外部シンボルの出力
	bsr	dopass3			;パス3の実行
	bsr	xdefmodify		;外部定義シンボル出力の修正
	bsr	prnsymtbl		;シンボル名テーブルの出力
	bsr	prnundefsym		;未定義シンボルリストの出力
	bsr	inpclose		;ファイルのクローズ
	bsr	outclose
	rts


;----------------------------------------------------------------
;	オブジェクトファイルのヘッダを作成する
;----------------------------------------------------------------
makeobjhead:
	move.w	#$D000,d0		;D000 [ファイルサイズ] ファイル名～ 00
	bsr	wrtd0w
	moveq.l	#0,d0
	bsr	wrtd0l
	lea.l	(SOURCENAME,a6),a0
	bsr	wrtstr
	lea.l	(section_name,pc),a0
	lea.l	(LOCCTRBUF,a6),a1
	moveq.l	#4-1,d1
	move.w	#$C001,d2
	tst.b	(MAKERSECT,a6)
	beq	makeobjhead1
	moveq.l	#10-1,d1		;相対セクションを使用した場合
makeobjhead1:
	move.w	d2,d0
	bsr	wrtd0w			;C0[セクション番号] [オブジェクト長] セクション名～ 00
	move.l	(a1)+,d0		;ロケーションカウンタ値
	bsr	wrtd0l
	bsr	wrtstr			;セクション名
	addq.b	#1,d2
	dbra	d1,makeobjhead1
	move.l	(REQFILPTR,a6),d0
	beq	makeobjhead9		;requestファイルがない
makeobjhead2:
	movea.l	d0,a1
	move.w	#$E001,d0		;E001 requestファイル名～ 00
	bsr	wrtd0w
	lea.l	(4,a1),a0
	bsr	wrtstr
	move.l	(a1),d0
	bne	makeobjhead2
makeobjhead9:
	rts

section_name:				;セクション名
	.dc.b	'text',0,'data',0,'bss',0,'stack',0
	.dc.b	'rdata',0,'rbss',0,'rstack',0,'rldata',0,'rlbss',0,'rlstack',0
	.even


;----------------------------------------------------------------
;	アラインメント情報を出力する
;----------------------------------------------------------------
outaligninfo:
	move.b	(MAKEALIGN,a6),d0
	or.b	(MAKESYMDEB,a6),d0
	beq	outaligninfo9		;アラインメント情報もデバッグ情報も不要
	tst.b	(MAKEALIGN,a6)
	bne	outaligninfo1		;デバッグ情報のみが必要な場合は,
	move.b	#1,(MAXALIGN,a6)		;アライン値は2^1=2とする。
outaligninfo1:
	movea.l	(LINEBUFPTR,a6),a0
	move.b	#'*',(a0)+		;'*'+ファイル名+'*' というシンボルを作成する
	movea.l	(SOURCEFILE,a6),a1
	bsr	strcpy
	move.b	#'*',(a0)+
	clr.b	(a0)+
	move.w	#$B204,d0		;B204 [アライン値] '*'+ファイル名+'*' ～ 00
	bsr	wrtd0w
	moveq.l	#0,d0
	move.b	(MAXALIGN,a6),d0
	bsr	wrtd0l
	movea.l	(LINEBUFPTR,a6),a0
	bra	wrtstr

outaligninfo9:
	rts


;----------------------------------------------------------------
;	外部参照・定義シンボルを出力する
;----------------------------------------------------------------
outxrefdef:
	clr.l	(XREFSYMNO,a6)
	sf.b	(ISXDEFMOD,a6)
	sf.b	(ISUNDEFSYM,a6)

	move.l	(SYMTBLBEGIN,a6),d3
	beq	outxrefdef9		;シンボルが一つもない
outxrefdef1:
	movea.l	d3,a1
	move.w	#SYMEXTCOUNT-1,d2	;1つのテーブルブロック中のシンボル数
	move.l	(a1)+,d3
	bne	outxrefdef2		;まだ続きのブロックがある
	sub.w	(SYMTBLCOUNT,a6),d2	;最後のブロックの場合

outxrefdef2:
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
	bne	outxrefdef7		;数値シンボル以外なら何もしない

	move.b	(SYM_EXTATR,a1),d0
	cmpi.b	#SECT_XDEF,d0
	beq	outxdef			;外部定義シンボル
	cmpi.b	#SECT_XREF,d0
	beq	outxref			;外部参照シンボル
	cmpi.b	#SECT_GLOBL,d0
	beq	outglobl		;globlシンボル
	tst.b	d0
	bne	outcomm			;コモンシンボル

	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	beq	outxrefdef3
	tst.b	(ALLXDEF,a6)		;定義済シンボルの場合
	bne	outxdef0		;/dオプションがあれば外部定義にする
	bra	outxrefdef8

outxrefdef3:
	tst.b	(ALLXREF,a6)		;未定義シンボルの場合
	bne	outxref0		;/uオプションがあれば外部参照にする
outxrefdef5:
	st.b	(ISUNDEFSYM,a6)		;未定義シンボルの場合
outxrefdef8:
	lea.l	(SYM_TBLLEN,a1),a1	;次のシンボルアドレス
	dbra	d2,outxrefdef2
	tst.l	d3
	bne	outxrefdef1		;続きのテーブルブロックがある

	cmp.l	#$8000,(XREFSYMNO,a6)
	bcc	toomanyexabort		;外部参照シンボルが多すぎるので中止する
outxrefdef9:
	rts

outxrefdef7:
	cmpi.b	#ST_REAL,(SYM_TYPE,a1)
	bne	outxrefdef8
	tst.b	(SYM_FSIZE,a1)
	bpl	outxrefdef8
	st.b	(ISUNDEFSYM,a6)		;未定義の浮動小数点実数シンボルの場合
	bra	outxrefdef8

outglobl:				;globlシンボルの出力
	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	beq	outxref0		;未定義なら外部参照にする

outxdef0:
;??で始まるシンボルを外部定義にしない
	movea.l	(SYM_NAME,a1),a0	;文字列の先頭
	cmpi.b	#'?',(a0)+
	bne	outxdef0x
	cmpi.b	#'?',(a0)+
	beq	outxrefdef8
outxdef0x:
	move.b	#SECT_XDEF,(SYM_EXTATR,a1)
outxdef:				;外部定義シンボルの出力
	cmpi.b	#SA_NODET,(SYM_ATTRIB,a1)
	bcs	outxrefdef5		;未定義ならエラー
	bhi	outxdef1
	st.b	(ISUNDEFSYM,a6)
	st.b	(ISXDEFMOD,a6)		;未確定値なので後で修正する
outxdef1:
	GETFPTR	OBJFILPTR,d0		;現在のファイルポインタを得る
	move.l	d0,(SYM_NEXT,a1)	;シンボル値の修正用
	move.b	(SYM_SECTION,a1),d1
	bsr	outsymbol
	bra	outxrefdef8

outxref0:
	move.b	#SECT_XREF,(SYM_EXTATR,a1)
outxref:				;外部参照シンボルの出力
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	addq.l	#1,(XREFSYMNO,a6)	;シンボル番号を付ける
	move.l	(XREFSYMNO,a6),(SYM_VALUE,a1)
	moveq.l	#SECT_XREF,d1
	move.b	d1,(SYM_SECTION,a1)
	bsr	outsymbol
	bra	outxrefdef8

outcomm:				;コモンシンボルの出力
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	move.b	d0,d1
	move.b	d0,(SYM_SECTION,a1)
	bsr	outsymbol
	addq.l	#1,(XREFSYMNO,a6)	;出力後にシンボル番号を付ける
	move.l	(XREFSYMNO,a6),(SYM_VALUE,a1)
	bra	outxrefdef8

outsymbol:				;シンボルの出力
	move.w	#$B200,d0		;B2[セクション番号] [値] シンボル名～ 00
	move.b	d1,d0
	bsr	wrtd0w
	move.l	(SYM_VALUE,a1),d0	;xdef:シンボル値/xref:シンボル番号/comm:エリアサイズ
	bsr	wrtd0l
	movea.l	(SYM_NAME,a1),a0
	bra	wrtstr


;----------------------------------------------------------------
;	外部定義シンボルの修正
;----------------------------------------------------------------
xdefmodify:
	tst.b	(ISXDEFMOD,a6)
	beq	xdefmodify9		;外部定義シンボルの修正は不要
	sf.b	(ISUNDEFSYM,a6)

	move.l	(SYMTBLBEGIN,a6),d3
	beq	xdefmodify9		;シンボルが一つもない
xdefmodify1:
	movea.l	d3,a0
	move.w	#SYMEXTCOUNT-1,d2	;1つのテーブルブロック中のシンボル数
	move.l	(a0)+,d3
	bne	xdefmodify2		;まだ続きのブロックがある
	sub.w	(SYMTBLCOUNT,a6),d2	;最後のブロックの場合

xdefmodify2:
	tst.b	(SYM_TYPE,a0)		;cmpi.b #ST_VALUE,(SYM_TYPE,a0)
	bne	xdefmodify7		;数値シンボル以外なら何もしない

	cmpi.b	#SECT_XDEF,(SYM_EXTATR,a0)
	beq	xdefdomodify		;外部定義シンボル
	tst.b	(SYM_ATTRIB,a0)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	bne	xdefmodify5
xdefmodify3:
	st.b	(ISUNDEFSYM,a6)		;未定義シンボルの場合
xdefmodify5:
	lea.l	(SYM_TBLLEN,a0),a0	;次のシンボルアドレス
	dbra	d2,xdefmodify2
	tst.l	d3
	bne	xdefmodify1		;続きのテーブルブロックがある
xdefmodify9:
	rts

xdefmodify7:
	cmpi.b	#ST_REAL,(SYM_TYPE,a0)
	bne	xdefmodify5
	tst.b	(SYM_FSIZE,a0)
	bpl	xdefmodify5
	st.b	(ISUNDEFSYM,a6)		;未定義の浮動小数点実数シンボルの場合
	bra	xdefmodify5

xdefdomodify:
	cmpi.b	#SA_NODET,(SYM_ATTRIB,a0)
	bls	xdefmodify3		;未確定ならエラー
	lea.l	(OBJFILPTR,a6),a1
	move.l	(SYM_NEXT,a0),d1
	move.w	#$B200,d0		;B2[セクション番号] [値] シンボル名～ 00
	move.b	(SYM_SECTION,a0),d0	;セクション番号を書き込む
	bsr	fmodify
	move.l	(SYM_VALUE,a0),d0	;シンボル値を書き込む
	addq.l	#2,d1
	swap.w	d0
	bsr	fmodify
	addq.l	#2,d1
	swap.w	d0
	bsr	fmodify
	bra	xdefmodify5


;----------------------------------------------------------------
;	パス3の実行(オブジェクトの出力)
;----------------------------------------------------------------
dopass3:
	move.l	sp,(SPSAVE,a6)
	lea.l	(dopass31,pc),a0
	move.l	a0,(ERRRET,a6)
	st.b	(PFILFLG,a6)
	bsr	scdinit			;SCDデータ用ワークの初期化
	clr.l	(LINENUM,a6)		;行番号カウンタをリセット
dopass31:
	move.l	(LOCATION,a6),(LCURLOC,a6)
	bsr	tmpreadd0w
	move.w	d0,d1
	beq	dopass32		;テンポラリファイル終了
dopass315:
	clr.b	d1
	sub.w	d1,d0
	ror.w	#6,d1
	jsr	(pass3_tbl-4,pc,d1.w)
	move.l	(LOCATION,a6),(LCURLOC,a6)
	bsr	tmpreadd0w
	move.w	d0,d1
	bne	dopass315
dopass32:
	sf.b	(ISOBJOUT,a6)		;(offsetセクションで終了した時のため)
	bsr	outobj1w		;0000:オブジェクトファイル終了
	bsr	scdout			;SCDデータの出力
	lea.l	(OBJFILPTR,a6),a1
	bsr	fflush			;オブジェクトファイルバッファをフラッシュ
	move.l	(OBJLENCTR,a6),d0	;オブジェクトファイル長を書き込む
	moveq.l	#2,d1
	swap.w	d0
	bsr	fmodify
	moveq.l	#4,d1
	swap.w	d0
	bsr	fmodify
	tst.b	(MAKEPRN,a6)
	bne	prnline			;PRNファイル最終行を出力
	rts

;----------------------------------------------------------------
;	テンポラリファイルコード処理アドレス
pass3_tbl:
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

	bra.w	cputype		;39	.cpu

;----------------------------------------------------------------
error:
	move.w	d0,d3
	bsr	tmpreadd0l		;(ERRMESSYM,a6)
	exg.l	d0,d3			;d0.w=エラーコード
					;d3.l=シンボル(0=シンボルなし)
	bra	errout_d3

;----------------------------------------------------------------
nopdeath:				;34xx 削除すべきNOP
	bra	tmpreadd0w		;1ワード読み飛ばす(既に0になっているはず)

;----------------------------------------------------------------
nopalive:				;35xx 挿入されたNOP
	bsr	f43gwarn
	bra	constdata

;----------------------------------------------------------------
cputype:				;39xx .cpu
	bsr	tmpreadd0w
	move.w	d0,(CPUTYPE,a6)		;CPUTYPE,CPUTYPE2
	rts

;----------------------------------------------------------------
symdef:					;2FXX シンボル定義
	bra	tmpreadd0l

;----------------------------------------------------------------
dspcode:				;0Exx (d,An)/(d,PC)の命令コード
extcode:				;08xx 拡張ワード
	moveq.l	#2-1,d0
;	bra	constdata		;拡張ワードを出力する

;----------------------------------------------------------------
constdata:				;10xx アドレス非依存データ
	move.w	d0,d1
constdata1:
	bsr	tmpreadd0w
	subq.w	#2,d1
	bcs	constdata2		;残り1or2バイトでデータが終わる
	bsr	out1wobj
	addq.l	#2,(LOCATION,a6)
	bra	constdata1

constdata2:
	addq.w	#1,d1
	bne	constdata3
	bsr	out1wobj		;偶数バイトでデータが終わる場合
	addq.l	#2,(LOCATION,a6)
	rts

constdata3:				;奇数バイトでデータが終わる場合
	lsr.w	#8,d0
	bsr	out1bobj
	addq.l	#1,(LOCATION,a6)
	rts

;----------------------------------------------------------------
prnadv:					;36xx PRNファイルへの先行出力
	tst.b	(MAKEPRN,a6)
	bne	prnlineadv
	rts

;----------------------------------------------------------------
linetop:				;01xx 1行開始
	tst.b	(MAKEPRN,a6)
	bne	linetop5
	cmp.b	#$02,d0
	bcc	linetop1		;マクロ展開中は行番号を変更しない
	addq.l	#1,(LINENUM,a6)
linetop1:
	move.l	(LOCATION,a6),(LTOPLOC,a6)
	tst.b	(MAKESYMDEB,a6)
	bne	linetop7		;'-g'スイッチが指定された場合
	rts

linetop5:				;リスティングを行う場合
	bsr	prnline			;前の1行を出力
	move.w	(PAGEFLG,a6),d0
	beq	linetop6
	and.w	#$FF,d0
	bsr	prnnextpage		;改ページする
	clr.w	(PAGEFLG,a6)
linetop6:
	bsr	getline
	move.w	d0,(PRNLATR,a6)
	bra	linetop1

linetop7:				;デバッグ用行番号情報を出力する
	tst.b	d0
	bne	linetop9		;.includeファイル中/マクロ展開中では出力しない
	cmpi.b	#SECT_TEXT,(SECTION,a6)
	bne	linetop9		;.textセクション以外では出力しない
	movea.l	(SCDLNPTR,a6),a0
	adda.l	(LNOFST,a6),a0
	move.l	(LOCATION,a6),(a0)+	;ロケーション
	move.l	(LINENUM,a6),d0
	move.w	d0,(a0)+		;行番号
	addq.l	#6,(LNOFST,a6)
	addq.l	#1,(NUMOFLN,a6)
linetop9:
	rts

;----------------------------------------------------------------
symdata:				;02xx シンボル値
	move.w	d0,d2
	bsr	getdtsize
	add.l	d0,(LOCATION,a6)
	bsr	tmpreadsym		;シンボル値を得る
	bra	outobjexpr

;----------------------------------------------------------------
rpndata:				;03xx 逆ポーランド式
	move.w	d0,d2
	bsr	getdtsize
	add.l	d0,(LOCATION,a6)
	bsr	tmpreadexpr		;式の値を得る
	bra	outobjexpr

;----------------------------------------------------------------
dispadr:				;04xx (d,An)
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ディスプレースメントがサプレスされた
	or.b	#ESZ_ADR,d2
	addq.l	#2,(LOCATION,a6)
	cmp.b	#ESZ_ADR|SZ_WORD,d2	;ディスプレースメントサイズ
	beq	dispadr_w
dispadr_l:				;ディスプレースメントがロングワードなので
	addq.l	#4,(LOCATION,a6)	;ベースディスプレースメント扱いになる
	bra68	d0,dispadr_lerr
;ColdFireではベースディスプレースメントは不可
	tst.b	(CPUTYPE2,a6)
	bne	dispadr_lerr
	move.w	#EXW_FULL|EXW_BDL|EXW_IS,d0	;ロングワードの場合の拡張ワード
	bsr	out1wobj		;拡張ワードを出力する
	move.w	d2,d0
dispadr_w:
	bsr	tmpreadsymex1
	bra	outobjexpr

dispadr_lerr:				;68000/68010なら32bitオフセットは使用できない
	bsr	tmpreadsymex1		;ディスプレースメントを読み飛ばす
	bra	exprerr

;----------------------------------------------------------------
indexadr:				;06xx (d,An,Rn)
	bsr	tmpreadd0w		;拡張ワードを読み込む
	move.w	d0,d2
	bsr	tmpreadd0w
	exg.l	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	or.b	#ESZ_ADR,d2
	cmp.b	#ESZ_ADR|SZ_SHORT,d2	;ディスプレースメントサイズ
	beq	indexadr_s
	cmp.b	#ESZ_ADR|SZ_LONG,d2
	beq	indexadr_l
indexadr_w:
	addq.l	#4,(LOCATION,a6)
	or.w	#EXW_FULL|EXW_BDW,d0
	bra	indexadr_l1

indexadr_l:
	addq.l	#6,(LOCATION,a6)
	or.w	#EXW_FULL|EXW_BDL,d0
indexadr_l1:
	bsr	out1wobj		;拡張ワードを出力する
	bra	indexadr2

indexadr_s:
	addq.l	#2,(LOCATION,a6)
	lsr.w	#8,d0
	bsr	out1bobj		;拡張ワードの上位を出力する
indexadr2:
	move.w	d2,d0
	bsr	tmpreadsymex1
	bra	outobjexpr

;----------------------------------------------------------------
bdadr:					;09xx アドレスレジスタ間接ベースディスプレースメント
odisp:					;0Bxx アウタディスプレースメント
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ディスプレースメントがサプレスされた
	or.b	#ESZ_ADR,d2
	addq.l	#2,(LOCATION,a6)
	cmp.b	#ESZ_ADR|SZ_LONG,d2	;ディスプレースメントサイズ
	bne	bdadr_w
bdadr_l:
	addq.l	#2,(LOCATION,a6)
bdadr_w:
	bsr	tmpreadsymex1
	bra	outobjexpr

;----------------------------------------------------------------
disppc:					;05xx (d,PC)
	move.l	(LOCATION,a6),d5	;(PC間接の基準アドレス)
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	addq.l	#2,(LOCATION,a6)
	cmp.b	#SZ_WORD,d2		;ディスプレースメントサイズ
	beq	outpcdisp
	addq.l	#4,(LOCATION,a6)
	move.w	#EXW_FULL|EXW_BDL|EXW_IS,d0	;ロングワードの場合の拡張ワード
	bsr	out1wobj		;拡張ワードを出力する
	move.w	d2,d0
	bra	outpcdisp

;----------------------------------------------------------------
dispopc:				;32xx (d,OPC)
	move.l	(LOCATION,a6),d5	;(PC間接の基準アドレス)
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	addq.l	#2,(LOCATION,a6)
	cmp.b	#SZ_WORD,d2		;ディスプレースメントサイズ
	beq	outpcdisp
	addq.l	#2,(LOCATION,a6)	;(d,PC)→xxxx.l
	bsr	tmpreadsymex1
	bra	outobjexpr

;----------------------------------------------------------------
indexpc:				;07xx (d,PC,Rn)
	move.l	(LOCATION,a6),d5	;(PC間接の基準アドレス)
	bsr	tmpreadd0w		;拡張ワードを読み込む
	move.w	d0,d2
	bsr	tmpreadd0w
	exg.l	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	cmp.b	#SZ_SHORT,d2		;ディスプレースメントサイズ
	beq	indexpc_s
	cmp.b	#SZ_LONG,d2
	beq	indexpc_l
indexpc_w:
	addq.l	#4,(LOCATION,a6)
	or.w	#EXW_FULL|EXW_BDW,d0
	bra	indexpc_l1

indexpc_l:
	addq.l	#6,(LOCATION,a6)
	or.w	#EXW_FULL|EXW_BDL,d0
indexpc_l1:
	bsr	out1wobj		;拡張ワードを出力する
	bra	indexpc2

indexpc_s:
	addq.l	#2,(LOCATION,a6)
	lsr.w	#8,d0
	bsr	out1bobj		;拡張ワードの上位を出力する
indexpc2:
	move.w	d2,d0
	bra	outpcdisp

;----------------------------------------------------------------
bdpc:					;0Axx PC間接ベースディスプレースメント
	move.l	(LOCATION,a6),d5
	subq.l	#2,d5			;(PC間接の基準アドレス(拡張ワードのアドレス))
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ディスプレースメントがサプレスされた
	addq.l	#2,(LOCATION,a6)
	cmp.b	#SZ_LONG,d2		;ディスプレースメントサイズ
	bne	outpcdisp
	addq.l	#2,(LOCATION,a6)
	bra	outpcdisp

;----------------------------------------------------------------
linkcmd:				;33xx link.w/.l
	move.l	(LOCATION,a6),d5
	addq.l	#2,d5
	move.l	d5,(LCURLOC,a6)		;('$'のアドレス)
	move.w	d0,d3
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	cmp.b	#SZ_WORD,d2		;ディスプレースメントサイズ
	beq	link_w
link_l:
	addq.l	#2,(LOCATION,a6)
	or.w	#$4808,d3		;link.lの命令コード
	bra	link9

link_w:
	or.w	#$4E50,d3		;link.wの命令コード
link9:
	move.w	d3,d0
	bsr	out1wobj		;命令コードを出力する
	addq.l	#4,(LOCATION,a6)
	move.w	d2,d0
	bsr	tmpreadsymex1
	bra	outobjexpr

;----------------------------------------------------------------
jbracmd:				;31xx jbra/jbsr/jb<cc>
	move.l	(LOCATION,a6),d5
	addq.l	#2,d5			;(ディスプレースメントの基準アドレス)
	bsr	tmpreadd0w		;命令コードを読み込む
	move.w	d0,d3
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ブランチ命令がサプレスされた
	cmp.b	#SZ_LONG,d2		;ディスプレースメントサイズ
	bne	bracmd1			;.lでなければbra/bsr/b<cc>
	move.w	#$4EB9,d1		;(jsrの命令コード)
	cmp.w	#$6100,d3
	beq	jbracmd9		;bsr → jsr
	bcs	jbracmd8		;bra → jmp
	eori.w	#$0106,d3		;b<cc> → b</cc> $+8 & jmp
	move.w	d3,d0
	bsr	out1wobj		;命令コードを出力する
	addq.l	#2,(LOCATION,a6)
jbracmd8:
	move.w	#$4EF9,d1		;(jmpの命令コード)
jbracmd9:
	move.w	d1,d0
	bsr	out1wobj		;命令コードを出力する
	addq.l	#6,(LOCATION,a6)
	move.w	d2,d0
	bsr	tmpreadsymex1
	tst.w	d0			;値のセクション
	beq	ilrelerr_const		;定数ならエラー
	bra	outobjexpr

;----------------------------------------------------------------
bracmd:					;0Cxx bra/bsr/b<cc>.s/.w/.l
	move.l	(LOCATION,a6),d5
	addq.l	#2,d5			;(ディスプレースメントの基準アドレス)
	bsr	tmpreadd0w		;命令コードを読み込む
	move.w	d0,d3
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ブランチ命令がサプレスされた
bracmd1:
	cmp.b	#SZ_SHORT,d2		;ディスプレースメントサイズ
	beq	bracmd_s
	cmp.b	#SZ_WORD,d2
	beq	bracmd_w_test
bracmd_l:
	addq.l	#2,(LOCATION,a6)
	st.b	d3			;下位ワードが$FFならロングワードブランチ
bracmd_w:				;下位ワードが$00ならワードブランチ
	move.w	d3,d0
	bsr	out1wobj		;命令コードを出力する
	addq.l	#4,(LOCATION,a6)
	move.w	d2,d0
	bra	outpcbra

bracmd_s:
	addq.l	#2,(LOCATION,a6)
	move.w	d3,d0
	lsr.w	#8,d0
	bsr	out1bobj		;命令コードを出力する
	move.w	d2,d0
	bra	outpcbra

;ここはjbsrも使う
bracmd_w_test:
	tst.b	(OPTBSR,a6)
	beq	bracmd_w		;直後へのbsrを最適化しない
	cmp.b	#SZ_WORD|$40,d0
	bne	bracmd_w		;直後へのbsrではない
	addq.l	#4,(LOCATION,a6)
	move.w	d2,d0
	st.b	d3
	bsr	tmpreadsymex1
;アドレス値以外や他のセクションへのオフセットは最適化の対象ではないので,
;直後へのbsrのフラグが立たず,ここにはこない
;	move.w	d0,d4			;値のセクション
;	beq	ilrelerr_const		;定数ならエラー
;	cmp.b	SECTION(a6),d4
;	bne	bracmd_w_rsect		;他のセクションへのオフセット
	sub.l	d5,d1			;現在のアドレスからの相対値
	move.l	d1,d0
	subq.l	#2,d0
	bne	bracmd_w_bsr		;alignなどの影響で間があいてしまっている
bracmd_w_pea:
	move.l	#$487A_0002,d0
	bsr	out1lobj		;pea (2,pc)
	bra	prnpccode

;直後へのbsrがalignのパディングを跨ぐときは,peaに置き換えてはならない.
;peaに変えてしまうと,alignのパディング部分を実行するタイミングが変化してしまい,
;alignのパディングが何か意味のあるコードだった場合に問題が生じる可能性がある.
bracmd_w_bsr:
	move.w	#$6100,d0
	bsr	out1wobj		;bsr.w
	bra	outpcdisp_w

;bracmd_w_rsect:
;	move.w	#$6100,d0
;	bsr	out1wobj
;	bra	outpcdisp5

;----------------------------------------------------------------
cpbracmd:				;0Dxx cpb<cc>.w/.l
	move.l	(LOCATION,a6),d5
	addq.l	#2,d5			;(ディスプレースメントの基準アドレス)
	bsr	tmpreadd0w		;命令コードを読み込む
	move.w	d0,d3
	bsr	tmpreadd0w
	move.w	d0,d2
	and.b	#3,d2			;(ESZ_OPTビットをクリア)
	beq	tmpreadsymex1		;ブランチ命令がサプレスされた
	cmp.b	#SZ_WORD,d2		;ディスプレースメントサイズ
	beq	cpbracmd_w
cpbracmd_l:
	addq.l	#2,(LOCATION,a6)
	or.w	#$0040,d3		;b6=1ならロングワードブランチ
cpbracmd_w:				;b6=0ならワードブランチ
	move.w	d3,d0
	bsr	out1wobj		;命令コードを出力する
	addq.l	#4,(LOCATION,a6)
	move.w	d2,d0
;	bra	outpcbra

;----------------------------------------------------------------
;	PC間接オフセットを出力する
;	in :d0.w=T_SYMBOL or T_RPN/d2.b=サイズ/d5.l=基準アドレス
outpcbra:				;bra/cpbra命令
	st.b	d3
	bsr	tmpreadsymex1
	move.w	d0,d4			;値のセクション
	bne	outpcdisp0
	bra	ilrelerr_const		;定数ならエラー

outpcdisp:				;PC間接アドレッシング
	sf.b	d3
	bsr	tmpreadsymex1
	move.w	d0,d4			;値のセクション
	beq	outpcdisp1		;定数の場合
outpcdisp0:
	cmp.b	(SECTION,a6),d4
	bne	outpcdisp5		;他のセクションへのオフセット
	sub.l	d5,d1			;現在のアドレスからの相対値
outpcdisp1:
	cmp.b	#SZ_SHORT,d2		;ディスプレースメントサイズ
	beq	outpcdisp_s
	cmp.b	#SZ_LONG,d2
	beq	outpcdisp_l
outpcdisp_w:
	move.l	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	bne	ilrelerr_outside	;16bitオフセットの範囲外
	bsr	out1wobj
	bra	prnpccode

outpcdisp_l:
	bra68	d0,ilrelerr_outside	;68000/68010なら32bitオフセットは使用できない
;ColdFireでは32ビットのオフセットは不可
	tst.b	(CPUTYPE2,a6)
	bne	ilrelerr_outside
	move.l	d1,d0
	bsr	out1lobj
	bra	prnpccode

outpcdisp_s:
	move.l	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d1,d0
	bne	ilrelerr_outside	;8bitオフセットの範囲外
	tst.b	d3
	beq	outpcdisp_s1
	tst.b	d1			;ブランチオフセットの場合
	beq	ilrelerr_outside	;(オフセットが$00ならエラー)
	cmp.b	#$FF,d1
	beq	ilrelerr_outside	;(オフセットが$FFならエラー)
outpcdisp_s1:
	bsr	out1bobj
	bra	prnpccode

outpcdisp5:				;他のセクションへのオフセット
	bsr	prnextcode
	cmp.w	#SECT_XREF,d4
	beq	outpcdisp8		;外部参照値へのオフセット
	bhi	outpcdisp7
	bsr	prnopccode
outpcdisp7:
	bsr	outobjrpn		;逆ポーランド式を出力
	move.w	#$8000,d0		;現在のロケーションカウンタ値をスタックに積む
	move.b	(SECTION,a6),d0
	bsr	outobj1w
	move.l	d5,d0
	bsr	wrtd0l
	move.w	#$A00F,d0		;スタック内の減算(オフセットを求める)
	bsr	wrtd0w

	move.w	#$9300,d0
	cmp.b	#SZ_SHORT,d2
	beq	wrtd0w
	move.w	#$9900,d0
	cmp.b	#SZ_WORD,d2
	beq	wrtd0w
	move.w	#$9200,d0
	bra	wrtd0w

outpcdisp8:				;外部参照値へのオフセット
	move.w	#$6B00,d0		;ショートオフセット
	cmp.b	#SZ_SHORT,d2
	beq	outpcdisp9
	move.w	#$6500,d0		;ワードオフセット
	cmp.b	#SZ_WORD,d2
	bne	outpcdisp7		;(ロングワードオフセットがないため)
outpcdisp9:
	move.b	(SECTION,a6),d0
	bsr	outobj1w
	move.l	d5,d0
	bsr	wrtd0l
	move.w	d1,d0			;外部参照番号
	bra	wrtd0w

;----------------------------------------------------------------
;	PC間接データをPRNファイルに出力する
prnpccode:
	tst.b	(MAKEPRN,a6)
	beq	prnpccode9
	movea.l	(PRNLPTR,a6),a0
	move.b	#'_',(a0)+
	move.l	d1,d0
	add.l	d5,d0
	bsr	convhex8
	move.b	#-1,(a0)+
	move.l	a0,(PRNLPTR,a6)
prnpccode9:
	rts

;----------------------------------------------------------------
;	他のセクションへのオフセットをPRNファイルに出力する
prnopccode:
	tst.b	(MAKEPRN,a6)
	beq	prnopccode9
	movea.l	(PRNLPTR,a6),a0		;'_(xx)xxxxxxxx'
	move.b	#'_',(a0)+
	move.b	#'(',(a0)+
	move.b	d4,d0
	bsr	convhex2		;セクション番号
	move.b	#')',(a0)+
	move.l	d1,d0
	bsr	convhex8
	move.b	#-1,(a0)+
	move.l	a0,(PRNLPTR,a6)
prnopccode9:
	rts

;----------------------------------------------------------------
coderpn:				;0Fxx 命令コード埋め込み式データ
	move.w	d0,d1
	addq.l	#2,(LOCATION,a6)
	bsr	tmpreadd0w		;命令コードを読み込む
	move.w	d0,d3
	subq.w	#1,d1
	bmi	cmdimm8			;TCR_IMM8
	beq	cmdimm8s		;TCR_IMM8S
	subq.w	#2,d1
	bmi	cmdmoveq		;TCR_MOVEQ
	subq.w	#1,d1
	bmi	cmdtrap			;TCR_TRAP
	subq.w	#1,d1
	bmi	cmdbkpt			;TCR_BKPT
;	bra	cmdimm3q		;TCR_IMM3Q

cmdimm3q:				;mov3q
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	tst.l	d1
	beq	ilquickerr_mov3q	;-1,1～7の範囲外
	bpl	cmdimm81
	addq.l	#1,d1
	bra	cmdimm81

cmdimm8s:				;sftrot
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	subq.l	#1,d1
	cmp.l	#8,d1
	bcc	ilquickerr_sftrot	;クイックサイズの範囲外
	bra	cmdimm82

cmdimm8:				;subq,addq,...
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	subq.l	#1,d1
cmdimm81:
	cmp.l	#8,d1
	bcc	ilquickerr_addsubq	;クイックサイズの範囲外
cmdimm82:
	addq.w	#1,d1
	and.w	#$0007,d1
	ror.w	#7,d1
	or.w	d3,d1			;命令コードと合成
	move.w	d1,d0
	bra	out1wobj

cmdimmer:
	cmp.w	#SECT_COMM,d0
	bls	ilvalueerr		;アドレス値ならエラー
	bra	featureerr_xref		;外部参照値は未サポート

cmdmoveq:				;moveq
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdmoveq5		;定数でない場合
	move.l	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d1,d0
	beq	cmdmoveq1		;-$80～$7Fの場合
	cmp.l	#$100,d1
	bcc	ilquickerr_moveq	;$100以上はエラー
cmdmoveq1:
	exg.l	d0,d3
	move.b	d3,d0			;命令コードと合成
	bra	out1wobj

cmdmoveq5:
	cmp.w	#SECT_COMM,d0
	bls	ilvalueerr		;アドレス値ならエラー
	exg.l	d0,d3
	lsr.w	#8,d0
	bsr	out1bobj		;命令コードを出力
	exg.l	d0,d3
	moveq.l	#SZ_SHORT,d2
	bra	outobjexpr

cmdtrap:				;trap
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	cmp.l	#16,d1
	bcc	ilvalueerr		;値は0～15まで
	or.w	d3,d1			;命令コードと合成
	move.w	d1,d0
	bra	out1wobj

cmdbkpt:				;bkpt
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	cmp.l	#8,d1
	bcc	ilvalueerr		;値は0～8まで
	or.w	d3,d1			;命令コードと合成
	move.w	d1,d0
	bra	out1wobj

;----------------------------------------------------------------
bitfield:				;11xx ビットフィールド式データ
	move.w	d0,d1
	addq.l	#2,(LOCATION,a6)
	bsr	tmpreadd0w		;命令コードを読み込む
	move.w	d0,d3
	subq.w	#1,d1
	bpl	bitfield1
	bsr	bitfgetof		;TBF_OF(オフセットが式)
	move.w	d3,d0
	bra	out1wobj

bitfield1:
	subq.w	#1,d1
	bpl	bitfield2
	bsr	bitfgetwd		;TBF_WD(幅が式)
	move.w	d3,d0
	bra	out1wobj

bitfield2:
	bsr	bitfgetof		;TBF_OFWD(オフセット・幅とも式)
	bsr	bitfgetwd
	move.w	d3,d0
	bra	out1wobj

bitfgetof:				;オフセットを得る
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	cmp.l	#31,d1
	bhi	ilvalueerr		;オフセット値は0～31
	lsl.w	#6,d1
	or.w	d1,d3
	rts

bitfgetwd:				;幅を得る
	bsr	tmpreadsymex		;後続のデータを読み込む
	tst.w	d0
	bne	cmdimmer		;定数でない場合
	tst.l	d1
	beq	ilvalueerr		;幅は1～32
	cmp.l	#32,d1
	bhi	ilvalueerr
	and.w	#31,d1
	or.w	d1,d3
	rts

;----------------------------------------------------------------
dscmd:					;12xx .ds
	bsr	tmpreadd0l
	add.l	d0,(LOCATION,a6)
	tst.b	(ISOBJOUT,a6)
	bne	dscmd1
	add.l	d0,(DSBSIZE,a6)
dscmd1:
	rts

;----------------------------------------------------------------
dcbcmd:					;13xx .dcb
	bsr	tmpreadd0w		;データの個数
	move.w	d0,d3
	bsr	tmpreadd0w
	move.w	d0,d2
	bsr	getdtsize		;データサイズを得る
	move.w	d3,d4
	addq.w	#1,d4
	mulu.w	d4,d0			;生成するデータのサイズ
	add.l	d0,(LOCATION,a6)	;必要なサイズだけカウンタを進める
	move.l	d0,d5
	move.w	d2,d0
	bsr	tmpreadsymex1

	tst.b	(MAKEPRN,a6)
	beq	dcbcmd1
	cmp.l	#128,d5
	bcc	dcbcmd5
dcbcmd1:
	movem.l	d0-d3,-(sp)
	bsr	outobjexpr		;データを出力
	movem.l	(sp)+,d0-d3
	dbra	d3,dcbcmd1
	rts

dcbcmd5:				;PRNファイル出力時、データが128bytes以上の場合
	movea.l	(PRNLPTR,a6),a0
	lea.l	(dcb_msg,pc),a1
	bsr	strcpy			;'value= '
	move.l	a0,(PRNLPTR,a6)
dcbcmd6:
	movem.l	d0-d3,-(sp)
	bsr	outobjexpr		;データを出力
	sf.b	(MAKEPRN,a6)		;(PRNファイルに出力されるのは最初の1つだけ)
	movem.l	(sp)+,d0-d3
	dbra	d3,dcbcmd6
dcbcmd65:
	st.b	(MAKEPRN,a6)
	movea.l	(PRNLPTR,a6),a0
	lea.l	(dcb_msg2,pc),a1
	move.b	#-1,(a0)+		;(PRNファイルコード部を改行)
	bsr	strcpy			;'count= '
	move.l	d5,d0			;出力バイト数
	cmp.l	#$FFFF,d0
	bhi	dcbcmd7
	bsr	convhex4
	bra	dcbcmd8

dcbcmd7:
	bsr	convhex8
dcbcmd8:
	bsr	strcpy			;'bytes'
	move.b	#-1,(a0)+
	move.l	a0,(PRNLPTR,a6)
	rts

dcb_msg:	.dc.b	'value= ',0
dcb_msg2:	.dc.b	'count= ',0,'bytes',0
	.even

;----------------------------------------------------------------
fdcbcmd:				;30xx .dcb(浮動小数点実数)
	move.w	d0,d1			;データ長
	move.w	d0,d4
	bsr	tmpreadd0w		;データの個数
	move.w	d0,d3
	ext.l	d0
	addq.l	#1,d0
	add.l	d0,d0
	add.l	d0,d0
	moveq.l	#0,d2
fdcbcmd1:
	add.l	d0,d2
	dbra	d1,fdcbcmd1
	add.l	d2,(LOCATION,a6)		;必要なサイズだけカウンタを進める
	movea.l	(OPRBUFPTR,a6),a2
	movea.l	a2,a1
	moveq.l	#3-1,d1
fdcbcmd2:
	bsr	tmpreadd0l		;データを読み出す
	move.l	d0,(a1)+
	dbra	d1,fdcbcmd2
	tst.b	(MAKEPRN,a6)
	beq	fdcbcmd3
	cmp.l	#128,d2
	bcc	fdcbcmd5
fdcbcmd3:
	move.w	d4,d1
	movea.l	a2,a1
fdcbcmd4:
	move.l	(a1)+,d0
	bsr	out1lobj		;データを出力
	dbra	d1,fdcbcmd4
	dbra	d3,fdcbcmd3
	rts

fdcbcmd5:				;PRNファイル出力時、データが128bytes以上の場合
	movea.l	(PRNLPTR,a6),a0
	lea.l	(dcb_msg,pc),a1
	bsr	strcpy			;'value= '
	move.l	a0,(PRNLPTR,a6)
	move.l	d2,d5			;出力バイト数
fdcbcmd6:
	move.w	d4,d1
	movea.l	a2,a1
fdcbcmd7:
	move.l	(a1)+,d0
	bsr	out1lobj		;データを出力
	dbra	d1,fdcbcmd7
	sf.b	(MAKEPRN,a6)		;(PRNファイルに出力されるのは最初の1つだけ)
	dbra	d3,fdcbcmd6
	bra	dcbcmd65

;----------------------------------------------------------------
aligncmd:				;14xx アラインメントの調整
	moveq.l	#1,d1
	lsl.l	d0,d1
	subq.l	#1,d1			;d1=2^d0 - 1
	move.l	(LOCATION,a6),d2
	move.l	d2,d0
	add.l	d1,d2
	not.l	d1
	and.l	d2,d1
	move.l	d1,(LOCATION,a6)
	sub.l	d0,d1
	lsr.w	#1,d1
	bcc	aligncmd1
	moveq.l	#0,d0			;まず2バイト境界を調整する
	bsr	out1bobj
aligncmd1:
	bsr	tmpreadd0w		;パディング値を読み込む
	bra	aligncmd3

aligncmd2:
	bsr	out1wobj
aligncmd3:
	dbra	d1,aligncmd2
	bra	tmpreadd0w		;パディング長は読み飛ばす

;----------------------------------------------------------------
sectchg:				;15xx セクション変更
	bsr	chgsection
;offsymでシンボルなしのときも0になってしまうが
;パス2以降では二重定義エラーは出ないはずなので無視する
	sf.b	(OFFSYMMOD,a6)
	move.l	(LOCATION,a6),(LTOPLOC,a6)	;prnlineで使う
	sf.b	(ISOBJOUT,a6)
	or.w	#$2000,d0		;20xx 0000 0000 :セクション変更
	bsr	outobj1w
	moveq.l	#0,d0
	bra	wrtd0l

;----------------------------------------------------------------
offsymcmd:				;37xx .offsym
	clr.w	d0
	bsr	chgsection		;offsetセクションに変更
	tst.l	(DSBSIZE,a6)
	beq	offsymcmd1
	bsr	outdsb
offsymcmd1:
	bsr	flushobj		;オブジェクトバッファをフラッシュ
	st.b	(ISOBJOUT,a6)		;以後のオブジェクト出力を抑制
	bsr	tmpreadd0l		;初期値を読み出す
	move.l	d0,(OFFSYMVAL,a6)
	bsr	tmpreadd0l		;シンボルを読み出す
	move.l	d0,(OFFSYMSYM,a6)
	bsr	tmpreadd0l		;仮シンボルを読み出す
	move.l	d0,(OFFSYMTMP,a6)
	move.b	#1,(OFFSYMMOD,a6)	;offsymでシンボルあり
	clr.l	(LOCATION,a6)
	clr.l	(LTOPLOC,a6)		;prnlineで使う
	rts

;----------------------------------------------------------------
ofstcmd:				;16xx .offset
	clr.w	d0
	bsr	chgsection		;offsetセクションに変更
	tst.l	(DSBSIZE,a6)
	beq	ofstcmd1
	bsr	outdsb
ofstcmd1:
	bsr	flushobj		;オブジェクトバッファをフラッシュ
	st.b	(ISOBJOUT,a6)		;以後のオブジェクト出力を抑制
	bsr	tmpreadd0l
	move.l	d0,(LOCATION,a6)
	rts

;----------------------------------------------------------------
equconst:				;17xx 定数の.equ/.set
	bsr	tmpreadd0l		;シンボルへのポインタ
	move.l	d0,a0
	bsr	tmpreadd0l		;シンボル値
	move.l	d0,(SYM_VALUE,a0)
	clr.w	(SYM_SECTION,a0)	;(SYM_ORGNUM)
	move.l	d0,d1
	moveq.l	#SECT_ABS,d0
equconst1:
	tst.b	(MAKEPRN,a6)
	beq	equconst9
	movea.l	(PRNLPTR,a6),a0
	move.b	#'=',(a0)+
	tst.b	d0
	beq	equconst2
	move.b	#'(',(a0)+
	bsr	convhex2
	move.b	#')',(a0)+
equconst2:
	move.l	d1,d0
	bsr	convhex8
	move.l	a0,(PRNLPTR,a6)
equconst9:
	rts

;----------------------------------------------------------------
equexpr:				;18xx 式・アドレスの.equ/.set
	bsr	tmpreadd0l		;シンボルへのポインタ
	move.l	d0,-(sp)
	bsr	tmpreadsymex
	movea.l	(sp)+,a0
	cmp.w	#$00FF,d0
	bcc	equexpr9		;シンボル値が確定しない
	move.b	d0,(SYM_SECTION,a0)
	move.l	d1,(SYM_VALUE,a0)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a0)
	bra	equconst1

equexpr9:
	clr.b	(SYM_SECTION,a0)
	clr.l	(SYM_VALUE,a0)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a0)
	bra	iloprerr_not_fixed	;値が確定しないのでエラー

;----------------------------------------------------------------
fequset:				;2Exx .fequ/.fset
	move.w	d0,d1
	bsr	tmpreadd0l		;シンボルへのポインタ
	movea.l	d0,a1
	move.b	d1,(SYM_FSIZE,a1)	;シンボルのサイズ
	movea.l	(SYM_FVPTR,a1),a0	;シンボル値へのポインタ
	moveq.l	#3-1,d1
fequset1:
	bsr	tmpreadd0l
	move.l	d0,(a0)+		;シンボル値を読み込む
	dbra	d1,fequset1
	tst.b	(MAKEPRN,a6)
	beq	fequcmd9
	movea.l	(PRNLPTR,a6),a0
	move.b	#'=',(a0)+
	moveq.l	#0,d0
	move.b	(SYM_FSIZE,a1),d0	;シンボルのサイズ
	movea.l	(SYM_FVPTR,a1),a2	;シンボル値へのポインタ
	bsr	getfplen		;データ長を得る
fequcmd2:
	move.l	(a2)+,d0
	bsr	convhex8
	dbra	d1,fequcmd2
	move.l	a0,(PRNLPTR,a6)
fequcmd9:
	rts

;----------------------------------------------------------------
xdefcmd:				;19xx .xdef
	bsr	tmpreadd0l		;シンボルへのポインタ
	movea.l	d0,a1
	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYM_ATTRIB,a1))
	beq	xdefcmd01		;xdefされたシンボルが未定義
	rts

xdefcmd01:
;ローカルシンボルは外部定義できないので考えなくてよい
	move.l	a1,(ERRMESSYM,a6)
	bra	undefsymerr

;----------------------------------------------------------------
prnctrl:				;1Axx リスト出力制御
	subq.w	#1,d0
	beq	prnlist
	subq.w	#1,d0
	beq	prnnlist
	subq.w	#1,d0
	beq	prnsall
	subq.w	#1,d0
	beq	prnlall
	rts

prnlist:				;.list
	sf.b	(ISNLIST,a6)
	rts

prnnlist:				;.nlist
	st.b	(ISNLIST,a6)
	rts

prnsall:				;.sall
	sf.b	(ISLALL,a6)
	rts

prnlall:				;.lall
	st.b	(ISLALL,a6)
	rts

;----------------------------------------------------------------
pagecmd:				;1Bxx .page
	or.w	#$FF00,d0
	move.w	d0,(PAGEFLG,a6)
	rts

;----------------------------------------------------------------
subttlcmd:				;1Cxx .subttl
	bsr	tmpreadd0l
	move.l	d0,(PRNSUBTTL,a6)
	rts

;----------------------------------------------------------------
orgcmd:					;1Dxx .org
	bsr	tmpreadd0l		;ロケーションカウンタ値を読み出す
	move.l	d0,(LOCATION,a6)
	tst.b	(MAKEPRN,a6)
	beq	orgcmd9
	movea.l	(PRNLPTR,a6),a0
	move.b	#'=',(a0)+
	bsr	convhex8
	move.l	a0,(PRNLPTR,a6)
orgcmd9:
	rts

;----------------------------------------------------------------
endcmd:					;1Exx .end
	bsr	tmpreadsymex
	tst.w	d0
	bmi	iloprerr_not_fixed	;未確定値ならエラー
	beq	iloprerr		;定数ならエラー
	tst.b	d0
	bmi	iloprerr_end_xref	;外部参照値ならエラー
	move.w	d0,d2
	move.w	#$E000,d0
	bsr	outobj1w
	move.w	d2,d0			;実行開始セクション
	bsr	wrtd0w
	move.l	d1,d0			;実行開始アドレス
	bra	wrtd0l

;----------------------------------------------------------------
incldopen:				;1Fxx includeファイル開始
	bsr	tmpreadd0l		;ファイル名へのポインタ
	tst.b	(MAKEPRN,a6)
	bne	incldopen5
	movea.l	(INCLDINFPTR,a6),a0
	tst.w	(INCLDNEST,a6)
	bne	incldopen3
	lea.l	(INCLDINF,a6),a0
incldopen3:
	move.l	(LINENUM,a6),(a0)+	;処理中の行番号を退避する
	move.l	(INPFILE,a6),(a0)+
	move.l	a0,(INCLDINFPTR,a6)
	move.l	d0,(INPFILE,a6)
	addq.w	#1,(INCLDNEST,a6)
	clr.l	(LINENUM,a6)
	rts

incldopen5:
	move.l	d0,-(sp)
	bsr	prnline
	movea.l	(sp)+,a0
	bsr	openincld
	st.b	(PFILFLG,a6)		;ファイル名を付ける
	rts

;----------------------------------------------------------------
incldend:				;20xx includeファイル終了
	tst.b	(MAKEPRN,a6)
	bne	incldend5
	movea.l	(INCLDINFPTR,a6),a0	;退避してあった行番号を戻す
	move.l	-(a0),(INPFILE,a6)
	move.l	-(a0),(LINENUM,a6)
	move.l	a0,(INCLDINFPTR,a6)
	subq.w	#1,(INCLDNEST,a6)
	rts

incldend5:
	bsr	prnline
	bsr	closeincld
	st.b	(PFILFLG,a6)		;ファイル名を付ける
	rts

;----------------------------------------------------------------
macdef:					;21xx マクロ定義開始
	bsr	tmpreadd0l
	movea.l	d0,a0			;シンボルへのポインタ
	bsr	tmpreadd0l
	move.l	d0,(SYM_DEFINE,a0)	;定義内容へのポインタ
	rts

;----------------------------------------------------------------
macext:					;22xx マクロ展開開始
	tst.b	(MAKEPRN,a6)
	beq	macext5
	move.b	d0,-(sp)		;オペレーションサイズ

	bsr	tmpreadd0l		;シンボルへのポインタ
	movea.l	d0,a0
	move.l	a0,-(sp)
	movea.l	(SYM_DEFINE,a0),a0
	clr.w	d0
	bsr	exmacsetup		;マクロ展開準備
	movea.l	(sp)+,a0
	move.b	(sp)+,(MACSIZE,a6)	;オペレーションサイズ
	move.w	(SYM_MACLOCS,a0),d0
	add.w	d0,(MACLOCSMAX,a6)
	movea.l	(LINEBUFPTR,a6),a0
	moveq.l	#0,d1
	bsr	tmpreadd0w		;マクロ引数リストの開始位置
	move.w	d0,d1
	adda.l	d1,a0

	movea.l	(MACPARAEND,a6),a1
	bsr	defmacpara
	move.l	a1,(MACPARAEND,a6)
	rts

macext5:
	moveq.l	#3*2,d0
	bra	tempskip

;----------------------------------------------------------------
exitmcmd:				;23xx .exitm
	tst.b	(MAKEPRN,a6)
	bne	macexexitm
	rts

;----------------------------------------------------------------
reptcmd:				;24xx .rept展開開始
	tst.b	(MAKEPRN,a6)
	beq	reptcmd9
	bsr	tmpreadd0w
	move.w	d0,d1
	bsr	tmpreadd0l
	movea.l	d0,a0
	move.w	d1,d0
	suba.l	a1,a1
	bra	exmacsetup		;次の行からrept開始

reptcmd9:
	moveq.l	#3*2,d0
	bra	tempskip

;----------------------------------------------------------------
irpcmd:					;25xx .irp/.irpc展開開始
	tst.b	(MAKEPRN,a6)
	beq	irpcmd9
	bsr	tmpreadd0w
	move.w	d0,d1
	bsr	tmpreadd0l
	movea.l	d0,a1
	bsr	tmpreadd0l
	movea.l	d0,a0
	move.w	d1,d0
	bra	exmacsetup		;次の行からirp/irpc開始

irpcmd9:
	moveq.l	#5*2,d0
	bra	tempskip

;----------------------------------------------------------------
mdefbgn:				;26xx マクロ等定義開始
	st.b	(ISMACDEF,a6)
	rts

;----------------------------------------------------------------
mdefend:				;27xx マクロ等定義終了
	sf.b	(ISMACDEF,a6)
	rts


;----------------------------------------------------------------
;	SCDデータ用ワークの初期化
;----------------------------------------------------------------
scdinit:
	tst.b	(MAKESCD,a6)
	bne	scdinit01
	tst.b	(MAKESYMDEB,a6)
	bne	scdinit0
	rts				;SCDコードは出力しない

scdinit0:				;'-g'スイッチが指定された場合
	move.l	(LINENUM,a6),d0
	addq.l	#1,d0
	move.l	d0,(NUMOFLN,a6)
	moveq.l	#6,d0			;関数本体,.bf,.efの分
	move.l	d0,(NUMOFSCD,a6)	;拡張シンボル情報の数
	move.l	d0,(NUMOFFNC,a6)
scdinit01:
	move.l	(TEMPPTR,a6),d2
	doeven	d2
	movea.l	d2,a0
	move.l	d2,(SCDLNPTR,a6)	;行番号データ用ワーク
	move.l	(NUMOFLN,a6),d0
	add.l	d0,d0
	move.l	d0,d1
	add.l	d0,d0
	add.l	d1,d0			;d0×6
	add.l	d0,d2
	move.l	d2,(SCDDATAPTR,a6)	;拡張シンボル情報用ワーク
	move.l	(NUMOFSCD,a6),d0
	addq.l	#8,d0			;.file,.text,.data,.bssの分
	add.l	d0,d0
	move.l	d0,d1
	lsl.l	#3,d0
	add.l	d1,d0			;d0×$12
	move.l	d0,(NUMOFSCD,a6)	;使用する拡張シンボル情報のサイズ
	add.l	d0,d2
	move.l	d2,(TEMPPTR,a6)
	bsr	memcheck
scdinit1:
	clr.l	(a0)+			;確保したワークをクリア
	cmp.l	a0,d2
	bhi	scdinit1
	lea.l	(NUMOFTAG,a6),a0	;タグ/関数/変数データ数をデータ開始番号にする
	moveq.l	#5-1,d0
	moveq.l	#2,d1			;最初の番号は2(.fileの次)
scdinit2:
	move.l	(a0),d2
	move.l	d1,(a0)+
	add.l	d2,d1
	dbra	d0,scdinit2
	move.l	(NUMOFTAG,a6),(TAGBEGIN,a6)
	move.l	(NUMOFGLB,a6),(GLBDEFNUM,a6)
	clr.l	(LNOFST,a6)
	tst.b	(MAKESYMDEB,a6)
	beq	scdtempclr
	moveq.l	#2,d0			;'-g'スイッチが指定された場合
	movea.l	(SCDLNPTR,a6),a0
	move.l	d0,(a0)+		;行番号データ最初のエントリを作成する
	clr.w	(a0)+
	moveq.l	#6,d0
	move.l	d0,(LNOFST,a6)
	moveq.l	#1,d0
	move.l	d0,(NUMOFLN,a6)
scdtempclr:				;SCDデータ一時バッファをクリア
	lea.l	(SCDTEMP,a6),a0
	moveq.l	#(SCD_TBLLEN/4)-1,d0
scdtempclr1:
	clr.l	(a0)+
	dbra	d0,scdtempclr1
	move.w	#-2,(SCD_SECT+SCDTEMP,a6)
	rts

;----------------------------------------------------------------
;	SCDデータ番号から対応するバッファのアドレスを得る
getscdadr:
	movea.l	(SCDDATAPTR,a6),a0
	add.l	d0,d0
	move.l	d0,d1
	lsl.l	#3,d0
	add.l	d1,d0			;d0×$12
	adda.l	d0,a0
	rts

;----------------------------------------------------------------
lncmd:					;28xx .ln
	bsr	tmpreadd0w		;行番号
	move.w	d0,d3
	bsr	tmpreadsymex		;ロケーション
	cmpi.b	#SECT_TEXT,d0
	bne	iloprerr		;.textセクション以外ならエラー
	movea.l	(SCDLNPTR,a6),a0
	adda.l	(LNOFST,a6),a0
	move.l	d1,(a0)+
	move.w	d3,(a0)+
	addq.l	#6,(LNOFST,a6)
	rts

;----------------------------------------------------------------
valcmd:					;29xx .val
	bsr	tmpreadsymex		;式の値を得る
	cmp.w	#$FF,d0
	bhi	iloprerr
	tst.w	d0
	bne	valcmd1
	moveq.l	#-1,d0			;定数の場合(スタックフレームのオフセット値など)
valcmd1:
	move.l	d1,(SCD_VAL+SCDTEMP,a6)
	move.w	d0,(SCD_SECT+SCDTEMP,a6)
	rts

;----------------------------------------------------------------
tagcmd:					;2Axx .tag
	bsr	tmpreadd0l
	movea.l	d0,a1			;タグ名へのポインタ
	move.l	(TAGBEGIN,a6),d0
	bsr	tagsearch
	tst.l	d0
	beq	tagcmd9
	moveq.l	#2,d0
	bsr	tagsearch
	tst.l	d0
	bne	iloprerr		;タグ名が存在しない
tagcmd9:
	rts

tagsearch:				;タグ定義中から該当するタグを探す
	move.l	d0,d2
	bsr	getscdadr
	move.b	(SCD_SCL,a0),d0
	cmp.b	#10,d0			;struct
	beq	tagsearch1
	cmp.b	#12,d0			;union
	beq	tagsearch1
	cmp.b	#15,d0			;enum
	bne	tagsearch9		;タグではない
tagsearch1:
	movea.l	a0,a2
	movea.l	a1,a3
	tst.l	(a0)
	bne	tagsearch4
	move.l	(4,a0),d0		;シンボル名が8文字以上
	movea.l	(EXNAMEPTR,a6),a2
tagsearch2:
	cmp.l	(4,a2),d0
	beq	tagsearch3
	movea.l	(a2),a2
	bra	tagsearch2

tagsearch3:
	addq.l	#8,a2
tagsearch4:
	move.b	(a2)+,d0
	cmp.b	(a3)+,d0
	bne	tagsearch5
	tst.b	d0
	bne	tagsearch4
	move.l	d2,(SCD_TAG+SCDTEMP,a6)	;タグが見つかった
	moveq.l	#0,d0
	rts

tagsearch5:				;タグ名が違う
	move.l	(SCD_NEXT,a0),d0
	bne	tagsearch		;次のタグへ
tagsearch9:
	moveq.l	#-1,d0			;該当するタグ名が見つからなかった
	rts

;----------------------------------------------------------------
scdshort:				;2Bxx .endef(短形式)
scdlong:				;2Cxx .endef(長形式)
	move.w	d0,d2			;データのタイプ
	lea.l	(SCDTEMP,a6),a0
	moveq.l	#4-1,d1
scddata1:
	bsr	tmpreadd0w		;シンボル名
	move.w	d0,(a0)+
	dbra	d1,scddata1
	addq.l	#6,a0
	moveq.l	#2-1,d1
scddata2:
	bsr	tmpreadd0w		;type/scl
	move.w	d0,(a0)+
	dbra	d1,scddata2
	tst.b	d0
	beq	scddata4
	addq.l	#4,a0			;ロングデータの場合
	moveq.l	#6-1,d1
scddata3:
	bsr	tmpreadd0w		;size/line/dim
	move.w	d0,(a0)+
	dbra	d1,scddata3
scddata4:
	cmpi.b	#16,(SCD_SCL+SCDTEMP,a6)
	bne	scddata5
	move.w	#-2,(SCD_SECT+SCDTEMP,a6)	;enumメンバ名のセクション(存在しない)
scddata5:
	move.w	d2,d0
	move.w	d2,d1
	and.w	#$F0,d0
	cmp.w	#$10,d0
	beq	scddttag		;タグ
	cmp.w	#$20,d0
	beq	scddtfnc		;関数
scddata6:				;データを書き込む
	and.w	#$00F0,d2
	lsr.w	#2,d2
	lea.l	(NUMOFSCD,a6),a1
	move.l	(a1,d2.w),d0
	bsr	getscdadr
	lea.l	(SCDTEMP,a6),a2
	move.b	(SCD_LEN,a2),d0
	ext.w	d0
scddata7:
	moveq.l	#9-1,d1
scddata8:
	move.w	(a2)+,(a0)+
	dbra	d1,scddata8
	addq.l	#1,(a1,d2.w)
	dbra	d0,scddata7
	bra	scdtempclr

scddttag:
	and.w	#$0F,d1
	beq	scddata6
	subq.w	#1,d1
	bne	scdtagend
	move.l	(NUMOFTAG,a6),(TAGDEFNUM,a6)	;タグ定義開始
	bra	scddata6

scdtagend:				;タグ定義終了
	bsr	scddata6		;.eosデータを書き込む
	move.l	(TAGDEFNUM,a6),d0
	bsr	getscdadr
	move.l	(NUMOFTAG,a6),(SCD_NEXT,a0)	;タグ定義チェインをつなぐ
	rts

scddtfnc:
	and.w	#$0F,d1
	beq	scddata6
	subq.w	#1,d1
	beq	scdfncbgn
	sub.w	#$B-1,d1
	beq	scdfncbb
	subq.w	#1,d1
	beq	scdfnceb
	subq.w	#1,d1
	beq	scdfncbf
	bra	scdfncef

scdfncbgn:				;関数定義開始
	move.l	(NUMOFFNC,a6),(FNCDEFNUM,a6)
	move.l	(NUMOFTAG,a6),(TAGBEGIN,a6)	;(関数外の同じタグ名に対応するため)
	clr.l	(FNCBBNUM,a6)
	movea.l	(LNOFST,a6),a0
	move.l	a0,(SCD_DIM+SCDTEMP,a6)
	adda.l	(SCDLNPTR,a6),a0
	move.l	(NUMOFFNC,a6),(a0)+
	clr.w	(a0)+
	addq.l	#6,(LNOFST,a6)
	bra	scddata6

scdfncbb:				;ブロック開始
	move.l	(FNCBBNUM,a6),(SCD_NEXT+SCDTEMP,a6)
	move.l	(NUMOFFNC,a6),(FNCBBNUM,a6)
	bra	scddata6

scdfnceb:				;ブロック終了
	bsr	scddata6		;.ebデータを書き込む
	move.l	(FNCBBNUM,a6),d0
	bsr	getscdadr
	move.l	(SCD_NEXT,a0),(FNCBBNUM,a6)	;ブロックチェインを一つ削る
	move.l	(NUMOFFNC,a6),(SCD_NEXT,a0)	;.bbに.ebの次の位置を書き込む
	rts

scdfncbf:				;関数開始
	move.l	(NUMOFFNC,a6),(FNCBFNUM,a6)
	bra	scddata6

scdfncef:				;関数終了
	move.l	(FNCBFNUM,a6),d0
	bsr	getscdadr
	move.l	(NUMOFFNC,a6),(SCD_NEXT,a0)	;.bfに.efの位置を書き込む
	bra	scddata6

;----------------------------------------------------------------
funcend:				;2Dxx .scl -1(関数定義終了)
	move.l	(FNCDEFNUM,a6),d0
	bsr	getscdadr
	move.l	(NUMOFFNC,a6),(SCD_NEXT,a0)	;関数定義チェインをつなぐ
	move.l	(LOCATION,a6),d0
	sub.l	(SCD_VAL,a0),d0
	move.l	d0,(SCD_SIZE,a0)	;関数サイズを書き込む
	move.l	#2,(TAGBEGIN,a6)
	rts


;----------------------------------------------------------------
;	SCDデータの出力
;----------------------------------------------------------------
scdout:
	tst.b	(MAKESCD,a6)
	bne	scdout01
	tst.b	(MAKESYMDEB,a6)
	bne	scdout0
	rts				;SCDコードは出力しない

scdout0:
	move.l	(NUMOFFNC,a6),d0	;'-g'スイッチが指定された場合
	bsr	getscdadr		;関数,.bf,.efのエントリを作成する
	movea.l	a0,a2
	move.l	(SCDFILENUM,a6),(4,a2)	;関数名はソースファイル名とする
	moveq.l	#SECT_TEXT,d0
	move.w	d0,(SCD_SECT,a2)		;セクション .text (関数)
	move.w	d0,(SCD_SECT+SCD_TBLLEN,a2)	;		  (.bf)
	move.w	d0,(SCD_SECT+SCD_TBLLEN*2,a2)	;		  (.ef)
	move.w	#$20,(SCD_TYPE,a2)	;データ型 void() (関数)
	move.w	#$0301,(SCD_SCL,a2)	;記憶クラス static (関数)
	move.w	#$6501,d0
	move.w	d0,(SCD_SCL+SCD_TBLLEN,a2)	;記憶クラス.bf/.ef(.bf)
	move.w	d0,(SCD_SCL+SCD_TBLLEN*2,a2)	;		  (.ef)
	moveq.l	#SECT_TEXT,d0
	bsr	chgsection		;.textセクションのサイズを得る
	move.l	(LOCATION,a6),d0
	move.l	d0,(SCD_SIZE,a2)	;サイズ(関数)
	move.l	d0,(SCD_VAL+SCD_TBLLEN*2,a2)	;シンボル値(.ef)
	moveq.l	#8,d0
	move.l	d0,(SCD_NEXT,a2)	;次の関数エントリ(関数)
	moveq.l	#6,d0
	move.l	d0,(SCD_NEXT+SCD_TBLLEN,a2)	;対応する.efの位置(.bf)
	move.w	#1,(SCD_SIZE+SCD_TBLLEN,a2)	;最初の行番号(.bf)
	move.l	(LINENUM,a6),d0
	move.w	d0,(SCD_SIZE+SCD_TBLLEN*2,a2)	;行数(.ef)
	lea.l	(scdstr_bfef,pc),a1
	lea.l	(SCD_TBLLEN,a2),a0
	bsr	strcpy			;シンボル名'.bf'
	lea.l	(SCD_TBLLEN*2,a2),a0
	bsr	strcpy			;シンボル名'.ef'
scdout01:
	bsr	scdtempclr
	lea.l	(scdsect_name,pc),a3	;.fileエントリを準備
	move.l	(GLBDEFNUM,a6),(SCD_VAL+SCDTEMP,a6)
	move.w	#$6701,(SCD_SCL+SCDTEMP,a6)
	movea.l	(SCDFILE,a6),a0
	movea.l	a0,a2
	lea.l	(SCD_TAG+SCDTEMP,a6),a1
	moveq.l	#14-1,d0
scdout1:				;ファイル名フィールドにファイル名を格納
	move.b	(a0)+,(a1)+
	dbeq	d0,scdout1
	beq	scdout15
	tst.b	(a0)
	beq	scdout15		;14文字ちょうどの場合
	movea.l	a1,a0
scdout12:				;ファイル名が14文字以上の場合
	move.b	(a2)+,d0
	beq	scdout15
	cmp.b	#'.',d0
	bne	scdout12		;拡張子部分を探す
	moveq.l	#3,d0
scdout13:
	tst.b	(a2)+
	dbeq	d0,scdout13
	bne	scdout15		;拡張子が3文字以上
	subq.l	#1,a2
scdout14:				;拡張子が3文字以下なら,
	move.b	-(a2),d0		;ファイル名+拡張子になるようにする
	move.b	d0,-(a0)
	cmp.b	#'.',d0
	bne	scdout14
	move.l	(SCDFILENUM,a6),(a1)
scdout15:
	moveq.l	#0,d0
	bsr	scdsectout		;.fileを出力
	moveq.l	#SECT_ABS,d0
	bsr	chgsection
	move.l	(NUMOFLN,a6),(SCD_SIZE+SCDTEMP,a6)
	moveq.l	#3-1,d3
	lea.l	(LOCCTRBUF,a6),a4
	moveq.l	#0,d2			;それまでのセクションサイズの合計
	moveq.l	#SECT_TEXT,d4
	move.l	(NUMOFSECT,a6),d5
scdout2:
	move.l	d2,(SCD_VAL+SCDTEMP,a6)
	move.w	d4,(SCD_SECT+SCDTEMP,a6)
	move.w	#$7801,(SCD_SCL+SCDTEMP,a6)
	move.l	(a4),(SCD_TAG+SCDTEMP,a6)	;そのセクションのサイズ
	add.l	(a4)+,d2
	move.l	d5,d0
	bsr	scdsectout		;.text/.data/.bssを出力
	addq.w	#1,d4
	addq.l	#2,d5
	dbra	d3,scdout2
	move.l	(LNOFST,a6),d0		;行番号データ長
	bsr	wrtd0l
	move.l	(NUMOFSCD,a6),d0	;拡張シンボルデータ長
	bsr	wrtd0l
	move.l	(EXNAMELEN,a6),d0	;シンボル名延長データ長
	bsr	wrtd0l
	movea.l	(SCDLNPTR,a6),a0	;行番号データを出力
	move.l	(LNOFST,a6),d1
	beq	scdout30		;(行番号データがない)
scdout3:
	move.w	(a0)+,d0
	bsr	wrtd0w
	subq.l	#2,d1
	bhi	scdout3
scdout30:
	movea.l	(SCDDATAPTR,a6),a0	;拡張シンボルデータを出力
	move.l	(NUMOFSCD,a6),d1
scdout31:
	move.w	(a0)+,d0
	bsr	wrtd0w
	subq.l	#2,d1
	bhi	scdout31
	lea.l	(EXNAMEPTR,a6),a0	;シンボル名延長データを出力
scdout4:
	move.l	(a0),d0
	beq	scdout9			;延長データが終了した
	movea.l	d0,a0
	lea.l	(8,a0),a1		;データ本体
scdout5:
	clr.w	d0
	move.b	(a1)+,d0
	beq	scdout6
	lsl.w	#8,d0
	move.b	(a1)+,d0
	beq	scdout6
	bsr	wrtd0w
	bra	scdout5

scdout6:
	bsr	wrtd0w
	bra	scdout4

scdout9:
	rts

scdsectout:
	lea.l	(SCDTEMP,a6),a1
	movea.l	a1,a2
scdsectout1:				;セクション名を書き込む
	move.b	(a3)+,(a2)+
	bne	scdsectout1
	bsr	getscdadr
	moveq.l	#18-1,d1		;拡張シンボル情報バッファに出力する
scdsectout2:
	move.w	(a1)+,(a0)+
	dbra	d1,scdsectout2
	bra	scdtempclr

scdsect_name:				;SCDに出力するセクション名
	.dc.b	'.file',0,'.text',0,'.data',0,'.bss',0

scdstr_bfef:
	.dc.b	'.bf',0,'.ef',0
	.even


;----------------------------------------------------------------
;	シンボル名テーブルの出力
;----------------------------------------------------------------
prnsymtbl:
	tst.b	(MAKEPRN,a6)
	beq	prnsymtbl9
	tst.b	(ISNLIST,a6)
	bne	prnsymtbl9
	bsr	makesymptr		;シンボルへのポインタテーブルを作成する
	moveq.l	#-1,d0
	bsr	prnnextpage		;改ページする
	bsr	prnsymtable		;シンボル名テーブルを表示する
prnsymtbl9:
	rts

;----------------------------------------------------------------
;	シンボルへのポインタテーブルを作成し、昇順にソートする
makesymptr:
	move.l	(TEMPPTR,a6),d0
	doquad	d0
	move.l	d0,(TEMPPTR,a6)
	movea.l	d0,a3
	movea.l	(MEMLIMIT,a6),a4
	movea.l	a3,a0			;ポインタテーブルの先頭アドレス

	move.l	(SYMTBLBEGIN,a6),d3
	beq	makesymptr9		;シンボルが一つもない
makesymptr1:
	movea.l	d3,a1
	move.w	#SYMEXTCOUNT-1,d2	;1つのテーブルブロック中のシンボル数
	move.l	(a1)+,d3
	bne	makesymptr2		;まだ続きのブロックがある
	sub.w	(SYMTBLCOUNT,a6),d2	;最後のブロックの場合
makesymptr2:
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
	bne	makesymptr5		;数値シンボル以外なら何もしない
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	blo	makesymptr5		;値が確定していなければ何もしない
	move.l	a1,(a3)+		;シンボルへのポインタ
	cmp.l	a3,a4
	bcc	makesymptr5
	addq.l	#4,sp			;メモリが無くなったので
	rts				;シンボルテーブルは作成しない

makesymptr5:
	lea.l	(SYM_TBLLEN,a1),a1	;次のシンボルアドレス
	dbra	d2,makesymptr2
	tst.l	d3
	bne	makesymptr1		;続きのテーブルブロックがある
makesymptr9:
	clr.l	(a3)			;ポインタテーブルの終端

sortsymptr:
	move.l	a6,-(sp)
	moveq.l	#$FFFFFFFC,d2		;下位2ビットマスク
	clr.l	-(sp)			;スタックボトム
	bra	sortsymptr1

sortsymptr0:				;スタックから区間両端のデータを得る
	movea.l	d0,a0
	movea.l	(sp)+,a3
sortsymptr1:
	move.l	a3,d0
	sub.l	a0,d0			;区間サイズ
	lsr.l	#1,d0
	and.w	d2,d0			;and.l
	beq	sortsymptr9		;区間が1になったので分割終了

	lea.l	(a0,d0.l),a4		;区間中央
	move.l	a4,d1
	movea.l	(a4),a5
	movea.l	(SYM_NAME,a5),a5
	movea.l	a0,a1
	movea.l	a3,a2
	bra	sortsymptr3

sortsymptr2:				;データを交換する
	move.l	-(a1),d0
	move.l	(a2),(a1)+
	move.l	d0,(a2)
sortsymptr3:				;先頭から交換対象データを検索
	movea.l	(a1)+,a4
	movea.l	(SYM_NAME,a4),a4
	movea.l	a5,a6
sortsymptr4:
	move.b	(a6)+,d0
	beq	sortsymptr5
	cmp.b	(a4)+,d0
	bhi	sortsymptr3
	beq	sortsymptr4
sortsymptr5:				;末尾から交換対象データを検索
	movea.l	-(a2),a4
	movea.l	(SYM_NAME,a4),a4
	movea.l	a5,a6
sortsymptr6:
	move.b	(a4)+,d0
	beq	sortsymptr65
	cmp.b	(a6)+,d0
	bhi	sortsymptr5
	beq	sortsymptr6
sortsymptr65:
	cmpa.l	a1,a2			;ポインタが交差するまで繰り返し
	bcc	sortsymptr2
	subq.l	#4,a1
	cmpa.l	d1,a1			;短い方の区間を先に処理する
	bcc	sortsymptr8

sortsymptr7:				;先頭の方を先に処理する
	movem.l	a1/a3,-(sp)
	movea.l	a1,a3
	bra	sortsymptr1

sortsymptr8:				;末尾の方を先に処理する
	movem.l	a0/a1,-(sp)
	movea.l	a1,a0
	bra	sortsymptr1

sortsymptr9:
	move.l	(sp)+,d0
	bne	sortsymptr0
	movea.l	(sp)+,a6
	rts

;----------------------------------------------------------------
;	シンボル名テーブルを表示
prnsymtable:
	lea.l	(crlf_msg,pc),a0
	bsr	prnlout
	lea.l	(seg1_msg,pc),a0
	bsr	prnlout
	lea.l	(seg2_msg,pc),a0
	bsr	prnlout
	tst.b	(MAKERSECT,a6)
	beq	prnsymtable01
	lea.l	(seg21_msg,pc),a0
	bsr	prnlout
prnsymtable01:
	lea.l	(crlf_msg,pc),a0
	bsr	prnlout
	bsr	prnlout
	lea.l	(seg3_msg,pc),a0
	bsr	prnlout
	movea.l	(TEMPPTR,a6),a1		;ポインタテーブルの先頭アドレス
	moveq.l	#0,d1
	move.w	(PRNWIDTH,a6),d1
	divu.w	#21,d1			;1行に表示できるシンボルの数
	subq.w	#1,d1
prnsymtable1:
	movea.l	(OPRBUFPTR,a6),a0
	move.w	d1,d2
prnsymtable2:				;' xxxxxxxx(xx) xxxxxxxx '
	move.l	(a1)+,d0
	beq	prnsymtable9		;全シンボルを表示した
	movea.l	d0,a2
	move.b	#' ',(a0)+
	move.l	(SYM_VALUE,a2),d0
	bsr	convhex8		;シンボル値
	bsr	prnsymsec		;セクション名
	move.b	#' ',(a0)+
	movea.l	(SYM_NAME,a2),a3
	moveq.l	#8-1,d0
prnsymtable3:
	move.b	(a3)+,(a0)+		;シンボル名(先頭8文字)
	dbeq	d0,prnsymtable3
	bne	prnsymtable5
	subq.l	#1,a0
prnsymtable4:
	move.b	#' ',(a0)+
	dbra	d0,prnsymtable4
prnsymtable5:
	dbra	d2,prnsymtable2
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	prnlout			;1行分を表示
	bra	prnsymtable1

prnsymtable9:
	cmp.w	d1,d2
	beq	prnsymtable0
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	prnlout			;最後の1行を表示
prnsymtable0:
	lea.l	(crlf_msg,pc),a0
	bra	prnlout

;----------------------------------------------------------------
;	セクション名を表示
prnsymsec:
	move.b	(SYM_SECTION,a2),d0
	beq	prnsymabs		;定数
	cmp.b	#SECT_XREF,d0
	beq	prnsymext		;.xref
	cmp.b	#SECT_COMM,d0
	beq	prnsymcom		;.comm
	cmp.b	#SECT_RCOMM,d0
	beq	prnsymrcom		;.rcomm
	cmp.b	#SECT_RLCOMM,d0
	beq	prnsymrlcom		;.rlcomm
	move.b	#'(',(a0)+
	bsr	convhex2		;セクション番号
	move.b	#')',(a0)+
	rts

prnsymabs:
	lea.l	(abs_msg,pc),a3
	bra	prnsymout

prnsymext:
	lea.l	(ext_msg,pc),a3
	bra	prnsymout

prnsymcom:
	lea.l	(com_msg,pc),a3
	bra	prnsymout

prnsymrcom:
	lea.l	(rcom_msg,pc),a3
	bra	prnsymout

prnsymrlcom:
	lea.l	(rlcom_msg,pc),a3
prnsymout:
	moveq.l	#4-1,d0
prnsymout1:
	move.b	(a3)+,(a0)+
	dbra	d0,prnsymout1
	rts

seg1_msg:	mes	'セグメントテーブル'
		.dc.b	CRLF,0
seg2_msg:	.dc.b	' 01 text     02 data     03 bss      04 stack   ',0
seg21_msg:	.dc.b	CRLF
		.dc.b	'             05 rdata    06 rbss     07 rstack  ',CRLF
		.dc.b	'             08 rldata   09 rlbss    0A rlstack ',0
seg3_msg:	mes	'シンボルテーブル'
		.dc.b	CRLF,0
abs_msg:	.dc.b	' abs'
ext_msg:	.dc.b	' ext'
com_msg:	.dc.b	' com'
rcom_msg:	.dc.b	' rcm'
rlcom_msg:	.dc.b	' rlc'
undef_msg:	mes	'未定義シンボル'
		.dc.b	CRLF,0
	.even


;----------------------------------------------------------------
;	未定義シンボルリストの出力
;----------------------------------------------------------------
prnundefsym:
	tst.b	(ISUNDEFSYM,a6)
	beq	prnundefsym9
	lea.l	(undef_msg,pc),a0
	bsr	prnstdout

	move.l	(SYMTBLBEGIN,a6),d3
	beq	prnundefsym9		;シンボルが1つもない
prnundefsym1:
	movea.l	d3,a2
	move.w	#SYMEXTCOUNT-1,d2	;1つのテーブルブロック中のシンボル数
	move.l	(a2)+,d3
	bne	prnundefsym2		;まだ続きのブロックがある
	sub.w	(SYMTBLCOUNT,a6),d2	;最後のブロックの場合

prnundefsym2:
	tst.b	(SYM_TYPE,a2)		;cmpi.b #ST_VALUE,(SYM_TYPE,a2)
	bne	prnundefsym7		;数値シンボル以外なら何もしない
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a2)
	bcc	prnundefsym8		;確定済みシンボル
prnundefsym3:
	movea.l	(LINEBUFPTR,a6),a0
	movea.l	(SYM_NAME,a2),a1
	bsr	strcpy
	lea.l	(crlf_msg,pc),a1
	bsr	strcpy
	clr.b	(a0)
	movea.l	(LINEBUFPTR,a6),a0
	bsr	prnstdout
prnundefsym8:
	lea.l	(SYM_TBLLEN,a2),a2	;次のシンボルアドレス
	dbra	d2,prnundefsym2
	tst.l	d3
	bne	prnundefsym1		;続きのテーブルブロックがある
prnundefsym9:
	rts

prnundefsym7:
	cmpi.b	#ST_REAL,(SYM_TYPE,a2)
	bne	prnundefsym8
	tst.b	(SYM_FSIZE,a2)
	bpl	prnundefsym8
	bra	prnundefsym3		;未定義の浮動小数点実数シンボルの場合


;----------------------------------------------------------------
;	PRNファイル作成ルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;仮出力ルーチン
;	仮出力済みでなければ従来のprnlineの処理を行って仮出力済みフラグをセット
;	仮出力済みのときは1行目からprn1line4から
;注意:仮出力を使うときは行の最後のデータまで仮出力を使って出力すること
prnlineadv:
	tst.b	(PFILFLG,a6)
	bne	prnfname
	tst.b	(ISNLIST,a6)
	bne	prnline9		;.nlistされているので行を表示しない
	cmpi.w	#2,(PRNLATR,a6)
	bne	prnlineadv1
	tst.b	(ISLALL,a6)
	beq	prnline9		;.sallでのマクロ展開行は表示しない
prnlineadv1:
	tst.b	(PADVFLG,a6)
	bne	prnlineadv2
	st.b	(PADVFLG,a6)
	bsr	prn1line
	bra	prnline9

prnlineadv2:
	movea.l	(PRNLPTR,a6),a1
	clr.b	(a1)
	lea.l	(PRNCODE,a6),a1
prnlineadv3:
	tst.b	(a1)
	ble	prnline9
	move.w	#15-1,d0
	movea.l	(OPRBUFPTR,a6),a0
prnlineadv4:
	move.b	#' ',(a0)+
	dbra	d0,prnlineadv4
	bsr	prn1code		;コード部を出力
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	prnlout
	bra	prnlineadv3

;----------------------------------------------------------------
;	1行出力する
prnline:
	tst.b	(PFILFLG,a6)
	bne	prnfname		;ファイル名を表示する
	tst.b	(ISNLIST,a6)
	bne	prnline9		;.nlistされているので行を表示しない
	cmpi.w	#2,(PRNLATR,a6)
	bne	prnline1
	tst.b	(ISLALL,a6)
	beq	prnline9		;.sallでのマクロ展開行は表示しない
prnline1:
;	仮出力済みでなければ従来のprnlineと同じ
;	仮出力済みのときは出力せずに仮出力済みフラグをリセット
	tst.b	(PADVFLG,a6)
	beq	prnline2
	sf.b	(PADVFLG,a6)
	rts

prnline2:
	bsr	prn1line
prnline9:
	lea.l	(PRNCODE,a6),a0
	move.l	a0,(PRNLPTR,a6)
	rts

;----------------------------------------------------------------
;	PRNファイルのファイル名行を表示する
prnfname::
	sf.b	(PFILFLG,a6)
	movea.l	(OPRBUFPTR,a6),a2
	move.b	#'<',(a2)+		;'< ～ >'
	movea.l	(INPFILE,a6),a0
	bsr	getfilename
prnfname1:
	move.b	(a1)+,(a2)+
	bne	prnfname1
	move.b	#'>',(-1,a2)
  .if UNIX_NEWLINE=0
	move.b	#CR,(a2)+
  .endif
	move.b	#LF,(a2)+
	clr.b	(a2)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	prnlout
	bra	prnline9

;----------------------------------------------------------------
;	PRNファイル1行を表示する
prn1line:
	movea.l	(PRNLPTR,a6),a0
	clr.b	(a0)
	movea.l	(OPRBUFPTR,a6),a0
	move.l	(LINENUM,a6),d0
	moveq.l	#5,d1			;(5桁でゼロサプレス)
	bsr	convdec			;'xxxxx '(行番号)
	move.b	#' ',(a0)+
	move.l	(LTOPLOC,a6),d0
	tst.b	(OFFSYMMOD,a6)
	ble	prn1line02
	movea.l	(OFFSYMTMP,a6),a1
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)
	beq	prn1line01
	moveq.l	#0,d0			;エラーのときは0にしておく
	bra	prn1line02

prn1line01:
	add.l	(OFFSYMVAL,a6),d0	;+初期値
	sub.l	(SYM_VALUE,a1),d0	;-仮シンボル値
prn1line02:
	bsr	convhex8		;'xxxxxxxx '(ロケーションカウンタ)
	moveq.l	#' ',d0
	cmpi.w	#2,(PRNLATR,a6)
	bne	prn1line1
	moveq.l	#'*',d0			;マクロ展開中
prn1line1:
	move.b	d0,(a0)+
	lea.l	(PRNCODE,a6),a1
	movea.l	(LINEBUFPTR,a6),a2
prn1line2:
	bsr	prn1code		;コード部を出力
	bsr	prn1srce		;ソース部を出力
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
	movea.l	(OPRBUFPTR,a6),a0
	bsr	prnlout
prn1line3:
	tst.b	(a1)+
	bmi	prn1line3
	bne	prn1line4
	tst.b	(a2)
	beq	prn1line9
prn1line4:
	subq.l	#1,a1
	move.w	#15-1,d0		;2行以上にまたがる場合
	movea.l	(OPRBUFPTR,a6),a0
prn1line5:
	move.b	#' ',(a0)+
	dbra	d0,prn1line5
	bra	prn1line2

prn1line9:
	rts

prn1code:				;コード部を出力
	move.w	(PRNCODEWIDTH,a6),d0	;PRNファイルのコード部の幅
	subq.w	#1,d0
prn1code1:
	move.b	(a1)+,(a0)+
	dble	d0,prn1code1
	bgt	prn1code5
	subq.l	#1,a0			;コード部が途中で終了
	subq.l	#1,a1
	addq.w	#1,d0
prn1code2:
	move.b	#' ',(a0)+
	dbra	d0,prn1code2
	rts

prn1code5:				;コード部が次の行に続く
	move.b	#' ',d0
	tst.b	(a1)
	ble	prn1code6
	tst.b	(1,a1)
	bgt	prn1code6
	move.b	(a1)+,d0
prn1code6:
	move.b	d0,(a0)+
	rts

prn1srce:				;ソース部を出力
	clr.w	d0
	move.w	(PRNWIDTH,a6),d2	;全体
	sub.w	(PRNCODEWIDTH,a6),d2	;コード
	sub.w	#5+1+8+1+1,d2		;行番号,空白,アドレス,空白,(コード),空白
prn1srce1:
	move.b	(a2)+,d1
	beq	prn1srce9
	bmi	prn1srce2
	cmp.b	#TAB,d1
	bne	prn1srce5
	addq.w	#8,d0			;TABコードの場合
	and.w	#$FFF8,d0
	bra	prn1srce6

prn1srce2:
  .if EUCSRC=0
	cmp.b	#$A0,d1
	bcs	prn1srce3
	cmp.b	#$E0,d1
	bcs	prn1srce5
  .else
	bra	prn1srce5		;EUC
  .endif
prn1srce3:				;漢字コードの場合
	addq.w	#2,d0
	cmp.w	d2,d0
	bhi	prn1srce9
	move.b	d1,(a0)+
	move.b	(a2)+,d1
	beq	prn1srce9
	bra	prn1srce6

prn1srce5:
	addq.w	#1,d0
prn1srce6:
	move.b	d1,(a0)+
	cmp.w	d2,d0
	bcs	prn1srce1
	rts

prn1srce9:
	subq.l	#1,a2
	rts


;----------------------------------------------------------------
;	シンボルファイル作成ルーチン
;----------------------------------------------------------------
makesymfile::
	lea.l	(sym_msg,pc),a0
	bsr	prnlout

	move.l	(SYMTBLBEGIN,a6),d3
	beq	makesymfile9		;シンボルが1つもない
makesymfile1:
	movea.l	d3,a2
	move.w	#SYMEXTCOUNT-1,d2	;1つのテーブルブロック中のシンボル数
	move.l	(a2)+,d3
	bne	makesymfile2		;まだ続きのブロックがある
	sub.w	(SYMTBLCOUNT,a6),d2	;最後のブロックの場合
makesymfile2:
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a2)
	beq	makesymfile8		;ローカルシンボルなら何もしない
	movea.l	(LINEBUFPTR,a6),a0
	movea.l	(SYM_NAME,a2),a1
	moveq.l	#16,d1
makesymfile3:
	subq.w	#1,d1
	move.b	(a1)+,(a0)+		;シンボル名を転送
	bne	makesymfile3
	subq.l	#1,a0
	tst.w	d1
	bmi	makesymfile5
makesymfile4:
	move.b	#' ',(a0)+		;余りをスペースで埋める
	dbra	d1,makesymfile4
makesymfile5:
	move.b	#' ',(a0)+
	move.b	#':',(a0)+
	move.b	#' ',(a0)+

	move.b	(SYM_TYPE,a2),d0
	cmp.b	#ST_REAL,d0
	beq	makesymreal
	cmp.b	#ST_REGSYM,d0
	beq	makesymreg
	cmp.b	#ST_MACRO,d0
	beq	makesymmac
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a2)
	bcs	makesymundef

	lea.l	(symabs_msg,pc),a1
	move.b	(SYM_EXTATR,a2),d0
	beq	makesymabs
	cmp.b	#SECT_XREF,d0
	beq	makesymext
	cmp.b	#SECT_COMM,d0
	beq	makesymcom
	cmp.b	#SECT_RCOMM,d0
	beq	makesymrcom
	cmp.b	#SECT_RLCOMM,d0
	beq	makesymrlcom
	bra	makesymglobl

makesymext:
	lea.l	(symext_msg,pc),a1
	bra	makesymcom1

makesymcom:
	lea.l	(symcom_msg,pc),a1
	bra	makesymcom1

makesymrcom:
	lea.l	(symrcom_msg,pc),a1
	bra	makesymcom1

makesymrlcom:
	lea.l	(symrlcom_msg,pc),a1
makesymcom1:
	bsr	strcpy
	lea.l	(symno_msg,pc),a1
	bsr	strcpy
	move.l	(SYM_VALUE,a2),d0
	bsr	convhex4
	bra	makesymfile7

makesymglobl:
	lea.l	(symglb_msg,pc),a1
makesymabs:
	bsr	strcpy
	move.b	#' ',(a0)+
	clr.w	d0
	move.b	(SYM_SECTION,a2),d0
	mulu.w	#6,d0
	lea.l	(symsec_msg,pc,d0.w),a1
	bsr	strcpy
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.l	(SYM_VALUE,a2),d0
	bsr	convhex8
	bra	makesymfile7

makesymundef:
	lea.l	(symudf_msg,pc),a1
	bra	makesymmac1

makesymreal:
	tst.b	(SYM_FSIZE,a2)
	bmi	makesymundef		;シンボルは未定義
	lea.l	(symreal_msg,pc),a1
	bra	makesymmac1

makesymreg:
	lea.l	(symreg_msg,pc),a1
	bra	makesymmac1

makesymmac:
	lea.l	(symmac_msg,pc),a1
makesymmac1:
	bsr	strcpy

makesymfile7:
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
	movea.l	(LINEBUFPTR,a6),a0
	bsr	prnlout
makesymfile8:
	lea.l	(SYM_TBLLEN,a2),a2	;次のシンボルアドレス
	dbra	d2,makesymfile2
	tst.l	d3
	bne	makesymfile1		;続きのテーブルブロックがある
makesymfile9:
	rts

symsec_msg:
	.dc.b	'abs  ',0,'text ',0,'data ',0,'bss  ',0,'stack',0
	.dc.b	'rdata',0,'rbss ',0,'rstck',0,'rldta',0,'rlbss',0,'rlstk',0
sym_msg:
	.dc.b	'SYMBOL           : class    section location',CRLF,CRLF,0
symabs_msg:	.dc.b	'absolute',0
symglb_msg:	.dc.b	'global  ',0
symext_msg:	.dc.b	'external',0
symcom_msg:	.dc.b	'common  ',0
symrcom_msg:	.dc.b	'rcommon ',0
symrlcom_msg:	.dc.b	'rlcommon',0
symudf_msg:	.dc.b	'(undefined)',0
symreg_msg:	.dc.b	'(register list)',0
symmac_msg:	.dc.b	'(macro)',0
symreal_msg:	.dc.b	'(float)',0
symno_msg:	.dc.b	'         No. ',0
	.even


;----------------------------------------------------------------
;	サブルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;	テンポラリファイルからシンボル番号・式を読み込み、その値を得る
;	in :---
;	out:d0.w=結果の属性(0:定数/1～4:アドレス値(セクション番号)/
;			    $FF:外部参照値/$FE:コモンシンボル/
;			    $FFFF:未定/$01FF:オフセット付き外部参照/$02FF:外部参照値)
;	    d1.l=結果の値/d2.w=サイズ
tmpreadsymex:
	bsr	tmpreadd0w
	move.w	d0,d2
tmpreadsymex1:
	and.w	#$FF00,d0
	cmp.w	#T_SYMBOL,d0
	bne	tmpreadexpr

;----------------------------------------------------------------
;	テンポラリファイルからシンボル番号を読み込み、その値を得る
;	in :---
;	out:d0.w=結果の属性/d1.l=結果の値
tmpreadsym:
	movea.l	(OPRBUFPTR,a6),a0
	move.w	#RPN_SYMBOL,(a0)+
	bsr	tmpreadd0l
	move.l	d0,(a0)+
	clr.w	(a0)+

;----------------------------------------------------------------
;	最終的なシンボル値を得る
;	in :d0.l=シンボルへのポインタ
;	out:d0.w=結果の属性/d1.l=結果の値
getsymdata:
	movea.l	d0,a0
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a0)	;(ST_VALUE or ST_LOCAL)
	bhi	exprerr			;数値シンボルでない
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a0)
	blo	getsymdata01		;未定義シンボル
	clr.w	d0
	move.b	(SYM_SECTION,a0),d0
	move.l	(SYM_VALUE,a0),d1
	rts

getsymdata01:
	cmpi.b	#ST_LOCAL,(SYM_TYPE,a0)	;ローカルシンボルには名前がないので
	beq	getsymdata02		;メッセージを分ける必要がある
	move.l	a0,(ERRMESSYM,a6)
	bra	undefsymerr

getsymdata02:
	cmpi.w	#100,(SYM_LOCALNO,a0)
	blo	undefsymerr_local
	bra	undefsymerr_offsym

;----------------------------------------------------------------
;	テンポラリファイルから逆ポーランド式を読み込み、その値を得る
;	in :---
;	out:d0.w=結果の属性/d1.l=結果の値
tmpreadexpr:
	bsr	tmpreadd0w
	move.w	d0,d1			;逆ポーランド式の長さ
	movea.l	(OPRBUFPTR,a6),a1
tmpreadexpr1:
	bsr	tmpreadd0w		;式本体を読み込む
	move.w	d0,(a1)+
	dbra	d1,tmpreadexpr1
	clr.w	(a1)+			;(エンドコード)
	movea.l	(OPRBUFPTR,a6),a1
	bra	calcrpn			;読み込んだ式を計算する

;----------------------------------------------------------------
;	式・シンボル値をファイルに出力する
;	in :d0.w=データの存在するセクション/d1.l=データ/d2.w=データのサイズ
;	out:---
outobjexpr:
	tst.w	d0
	beq	outobjconst		;定数
	bmi	iloprerr_not_fixed	;値が未確定
	cmp.b	#SECT_RLCOMM,d0
	bcs	outobjadrs		;アドレス値

	cmp.w	#$01FF,d0
	beq	outobjrofst		;オフセット付き外部参照値
	cmp.w	#$02FF,d0
	beq	outobjrexpr		;外部参照を含む演算

	bsr	prnextcode		;外部参照値の出力
	move.w	#$4000,d3
	bsr	outobjcom
	move.w	d1,d0
	bra	wrtd0w			;シンボル番号を出力する

;----------------------------------------------------------------
;	定数の出力
outobjconst:
	cmp.b	#ESZ_ABS,d2
	bcc	outobjcon_abs
outobjcon_imm:				;イミディエイトデータ
	bsrl	chkdtsize,d0
	move.l	d1,d0
	cmp.b	#SZ_SHORT,d2
	beq	out1bobj		;.s
	cmp.b	#SZ_LONG,d2
	bne	out1wobj		;.b/.w
	bra	out1lobj		;.l

outobjcon_abs:				;絶対アドレッシングデータ
	cmp.b	#ESZ_ADR,d2
	bcc	outobjcon_adr
	cmp.b	#ESZ_ABS|SZ_LONG,d2
	beq	outobjcon_absl
outobjcon_absw:
	move.w	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	beq	outobjcon_absw1
	cmp.l	#$00010000,d1
	bcc	overflowerr
	bsr	shvalwarn_d16
outobjcon_absw1:
	bsr	absshwarn
	bra	out1wobj

outobjcon_absl:
	bsr	abswarn
	move.l	d1,d0
	bra	out1lobj		;.l

outobjcon_adr:				;アドレスレジスタ間接ディスプレースメント
	cmp.b	#ESZ_ADR|SZ_SHORT,d2
	beq	outobjcon_adrs
	cmp.b	#ESZ_ADR|SZ_WORD,d2
	beq	outobjcon_adrw
	move.l	d1,d0
	bra	out1lobj		;.l

outobjcon_adrs:
	move.b	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d1,d0
	beq	out1bobj
	cmp.l	#$00000100,d1
	bcc	overflowerr
	bsr	shvalwarn_d8
	bra	out1bobj

outobjcon_adrw:
	move.w	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	beq	out1wobj
	cmp.l	#$00010000,d1
	bcc	overflowerr
	bsr	shvalwarn_d16
	bra	out1wobj

;----------------------------------------------------------------
;	アドレス値の出力
outobjadrs:
	and.w	#3,d2
	cmp.b	#SECT_RDATA,d0
	bcc	outobjadrs1		;相対セクションではエラーにしない
	cmp.b	#SZ_LONG,d2
	bne	iladrerr		;.l以外はエラー
outobjadrs1:
	tst.b	(MAKEPRN,a6)
 	beq	outobjadrs9
	movea.l	(PRNLPTR,a6),a0		;'(xx)xxxxxxxx'
	move.b	#'(',(a0)+
	bsr	convhex2		;セクション番号
	move.b	#')',(a0)+
	move.w	d0,-(sp)
	move.l	d1,d0
	cmp.b	#SZ_LONG,d2
	beq	outobjadrs3
	cmp.b	#SZ_WORD,d2
	beq	outobjadrs2
	bsr	convhex2
	bra	outobjadrs4

outobjadrs2:
	bsr	convhex4
	bra	outobjadrs4

outobjadrs3:
	bsr	convhex8
outobjadrs4:
	move.b	#-1,(a0)+
	move.l	a0,(PRNLPTR,a6)
	move.w	(sp)+,d0
outobjadrs9:
	move.w	#$4000,d3
	bsr	outobjcom
	move.l	d1,d0
	bra	wrtd0l

;----------------------------------------------------------------
;	オフセット付き外部参照値の出力
outobjrofst:
	bsr	prnextcode
	move.w	#$5000,d3
	bsr	outobjcom
	move.w	(ROFSTSYMNO,a6),d0
	bsr	wrtd0w
	move.l	d1,d0
	bra	wrtd0l

;----------------------------------------------------------------
;	外部参照値を含む式の出力
outobjrexpr:
	bsr	prnextcode
	bsr	outobjrpn
	move.w	d2,d0
	and.w	#3,d0
	lsl.w	#8,d0
	or.w	#$9000,d0
	bra	outobj1w

;----------------------------------------------------------------
prnextcode:				;外部参照データをPRNファイルに出力する
	tst.b	(MAKEPRN,a6)
	beq	prnextcode9
	movea.l	(PRNLPTR,a6),a0
	move.w	d0,-(sp)
	move.w	d2,d0
	bsr	getdtsize
	add.w	d0,d0
	subq.w	#1,d0
prnextcode1:
	move.b	#'?',(a0)+
	dbra	d0,prnextcode1
	move.l	a0,(PRNLPTR,a6)
	move.w	(sp)+,d0
prnextcode9:
	rts

;----------------------------------------------------------------
;	オブジェクトファイルの逆ポーランド式を出力する
;	in :---
;	out:---
outobjrpn:
	movea.l	(OPRBUFPTR,a6),a1
outobjrpn1:
	move.w	(a1)+,d0
	beq	outobjrpn9		;式が終了(RPN_END)
	move.w	d0,d1
	and.w	#$FF00,d1
	cmp.w	#RPN_VALUEB,d1
	beq	outobjrpnb		;.b
	cmp.w	#RPN_VALUEW,d1
	beq	outobjrpnw		;.w
	cmp.w	#RPN_VALUE,d1
	beq	outobjrpnl		;.l
	cmp.w	#RPN_SYMBOL,d1
	beq	outobjrpnsym		;シンボル
	cmp.w	#RPN_LOCATION,d1
	beq	outobjrpnloc		;現在のロケーションカウンタ値
	cmp.w	#RPN_OPERATOR,d1
	bne	exprerr
	and.w	#$00FF,d0		;演算子
	or.w	#$A000,d0
	bsr	outobj1w
	bra	outobjrpn1

outobjrpn9:
	rts

outobjrpnb:				;数値データ
	moveq.l	#0,d1
	move.b	d0,d1
	bra	outobjrpncon

outobjrpnw:
	moveq.l	#0,d1
	move.w	(a1)+,d1
	bra	outobjrpncon

outobjrpnl:
	move.l	(a1)+,d1
outobjrpncon:				;定数値を演算スタックに積むコード
	move.w	#$8000,d0
	bsr	outobj1w
outobjrpncon1:
	move.l	d1,d0
	swap.w	d0
	bsr	outobj1w
	swap.w	d0
	bsr	outobj1w
	bra	outobjrpn1

outobjrpnsym:				;シンボル
	move.l	(a1)+,d0
	bsr	getsymdata
	or.w	#$8000,d0
	bsr	outobj1w
	cmp.b	#SECT_RLCOMM,d0
	bcs	outobjrpncon1
	move.w	d1,d0			;外部参照値の場合、参照番号を出力
	bsr	outobj1w
	bra	outobjrpn1

outobjrpnloc:				;現在のロケーションカウンタ値
	move.l	(LTOPLOC,a6),d1		;'*'
	tst.b	d0
	beq	outobjrpnloc1
	move.l	(LCURLOC,a6),d1		;'$'
outobjrpnloc1:
	move.w	#$8000,d0
	move.b	(SECTION,a6),d0
	bsr	outobj1w
	bra	outobjrpncon1

;----------------------------------------------------------------
;	セクション番号/サイズを含めたオブジェクトファイルコマンドを出力する
;	in :d0.b=セクション番号/d2.w=データサイズ/d3.w=オブジェクトファイルコマンド
;	out:---
outobjcom:
	movem.w	d0/d2,-(sp)
	exg.l	d0,d3
	move.b	d3,d0
	and.w	#$0003,d2
	lsl.w	#8,d2
	or.w	d2,d0
	bsr	outobj1w
	movem.w	(sp)+,d0/d2
	rts

;----------------------------------------------------------------
;	文字列をファイルに出力する
;	in :a0=文字列へのポインタ
;	out:a0=文字列終了位置へのポインタ
wrtstr:
	move.w	d0,-(sp)
wrtstr1:
	clr.w	d0
	move.b	(a0)+,d0
	beq	wrtstr9
	lsl.w	#8,d0
	move.b	(a0)+,d0
	beq	wrtstr9
	bsr	wrtd0w
	bra	wrtstr1

wrtstr9:
	bsr	wrtd0w
	move.w	(sp)+,d0
	rts

;----------------------------------------------------------------
;	オブジェクトを1ロングワード出力する
;	in :d0.l=出力データ
;	out:---
out1lobj:
	swap.w	d0
	bsr	out1wobj
	swap.w	d0

;----------------------------------------------------------------
;	オブジェクトを1ワード出力する
;	in :d0.w=出力データ
;	out:---
out1wobj:
	move.w	d0,-(sp)
	lsr.w	#8,d0
	bsr	out1bobj
	move.w	(sp)+,d0

;----------------------------------------------------------------
;	オブジェクトを1バイト出力する
;	in :d0.b=出力データ
;	out:---
out1bobj:
	tst.l	(DSBSIZE,a6)
	beq	out1bobj1
	bsr	outdsb
out1bobj1:
	tst.b	(MAKEPRN,a6)
	beq	out1bobj2
	move.l	a0,-(sp)
	movea.l	(PRNLPTR,a6),a0
	bsr	convhex2
	move.l	a0,(PRNLPTR,a6)
	movea.l	(sp)+,a0
out1bobj2:
	bra	wrt1bobj0		;(ロケーションカウンタは変更しない)

;----------------------------------------------------------------
;	オブジェクト出力後、1ワード出力する
;	in :d0.w=出力データ
;	out:---
outobj1w:
	tst.l	(DSBSIZE,a6)
	beq	wrtobjd0w
	bsr	outdsb
	bra	wrtobjd0w

;----------------------------------------------------------------
;	.ds.bのデータを出力する
;	in :---
;	out:---
outdsb:
	move.l	d0,-(sp)
	move.w	#$3000,d0		;3000 [長さ] :.ds.b
	bsr	wrtobjd0w
	move.l	(DSBSIZE,a6),d0
	bsr	wrtd0l
	clr.l	(DSBSIZE,a6)
	move.l	(sp)+,d0
	rts


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;
;	Revision 3.1  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 3.0  2016-01-01 12:00:00  M.Kamada
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 2.9  1999 10/ 8(Fri) 21:52:11 M.Kamada
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;	+86 '%s に外部参照値は指定できません'
;
;	Revision 2.8  1999  3/ 3(Wed) 14:47:01 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 メッセージを日本語化
;	+82 T_ERRORを$FF00から通常のコードに変更
;	+82 doeven→doquad
;
;	Revision 2.7  1999  2/27(Sat) 23:43:22 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.6  1999  2/25(Thu) 03:37:23 M.Kamada
;	+80 objgen.sのchkdtsizeの参照をbsrlに変更
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.5  1998 10/10(Sat) 02:34:36 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 2.4  1998  1/24(Sat) 17:56:16 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 2.3  1998  1/ 9(Fri) 22:25:16 M.Kamada
;	+56 -f43gを削除
;
;	Revision 2.2  1997 10/13(Mon) 15:40:56 M.Kamada
;	+51 直後へのbsr→pea
;	+52 jmp/jsrを最適化する
;
;	Revision 2.1  1997  9/15(Mon) 16:05:17 M.Kamada
;	+46 ST_VALUE=0で最適化
;
;	Revision 2.0  1997  9/14(Sun) 18:46:52 M.Kamada
;	+45 $opsize,shift
;
;	Revision 1.9  1997  6/25(Wed) 13:39:30 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;	+34 プレデファインシンボルに対応
;
;	Revision 1.8  1996 11/13(Wed) 15:28:40 M.Kamada
;	+04 ??で始まるシンボルを外部定義にしない
;		??で始まるシンボルを外部定義にしない
;
;	Revision 1.7  1994/07/13  14:10:16  nakamura
;	若干のバグフィックス
;
;	Revision 1.6  1994/04/25  14:33:58  nakamura
;	最適化を行わないときに不正なオブジェクトファイルを出力することのあるバグを修正。
;
;	Revision 1.5  1994/04/12  15:09:08  nakamura
;	-m68000/68010で(d,An)が最適化されないことがあるバグを修正。
;
;	Revision 1.4  1994/03/10  15:54:40  nakamura
;	次の命令へのブランチを削除すると暴走するバグを修正
;
;	Revision 1.3  1994/03/06  13:03:06  nakamura
;	68000,68010モードで32bitディスプレースメントを出力してしまうバグをfix
;	.ln疑似命令がひとつもないソースをアセンブルすると異常なSCDコードを出力するバグをfix
;	jbra,jbsr,jbccおよびopcに対する処理を追加
;	'$'が正しいロケーションカウンタ値を指さないことがあるバグをfix
;	エラー発生時にラベルの定義値とロケーションアドレスがずれるバグをfix
;
;	Revision 1.2  1994/02/20  14:25:22  nakamura
;	シンボルテーブルポインタの偶数境界調整を忘れていたので修正。
;
;	Revision 1.1  1994/02/15  12:12:58  nakamura
;	Initial revision
;
;
