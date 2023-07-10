;----------------------------------------------------------------
;	X68k High-speed Assembler
;		行のコード化と解釈
;		< encode.s >
;
;	$Id: encode.s,v 3.2  1999 10/ 8(Fri) 21:48:40 M.Kamada Exp $
;
;		Copyright 1990-94  by Y.Nakamura
;			  1997-99  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	tmpcode.equ
	.include	register.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	ラベルを定義する
deflabel00:
;	move.l	a1,(ERRMESSYM,a6)
	move.b	(SYM_TYPE,a1),d0
;	beq	ilsymerr_value		;ST_VALUE
	subq.b	#ST_REAL,d0
	bcs	ilsymerr_local		;ST_LOCAL
	beq	ilsymerr_real		;ST_REAL
	subq.b	#ST_REGSYM-ST_REAL,d0
	beq	ilsymerr_regsym		;ST_REGSYM
	bra	ilsymerr_register	;ST_REGISTER

deflabel::
	movem.l	d0-d2/a0-a2,-(sp)
	tst.b	(ISIFSKIP,a6)
	bne	deflabel9		;.if不成立部の読み飛ばし中なので定義の必要なし
	move.w	(LABNAMELEN,a6),d1
	bmi	deflabel9		;定義するラベルがない
	movea.l	(LABNAMEPTR,a6),a0
deflabel7:
	bsr	isdefdsym
	tst.w	d0
	beq	deflabel8		;すでに登録済
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defsymbol		;新しく登録する
	sf.b	(SYM_FIRST,a6)
	bra	deflabel85

deflabel8:
	move.l	a1,(ERRMESSYM,a6)
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;シンボルのタイプ
	bne	deflabel00		;タイプの異なるシンボルと重複している
;offsymのときはプレデファインシンボルでなければ二重定義エラーを出さない
	tst.b	(SYM_ATTRIB,a1)		;(cmpi.b #SA_UNDEF,(SYMATTRIB,a1))
	beq	deflabel81		;未定義なので問題なし
	cmpi.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)
	beq	redeferr_predefine	;プレデファインシンボルだった
;SA_NODET/SA_DEFINE
	tst.b	(OFFSYMMOD,a6)
	beq	redeferr		;offsym中でないので二重定義エラー
	tst.b	(SYM_FIRST,a1)
	bgt	deflabel81
	tst.b	(OWOFFSYM,a6)		;offsymのシンボルでない
	bne	redeferr_offsym
	bsr	redefwarn_offsym
deflabel81:
	cmpi.b	#SECT_RLCOMM,(SYM_EXTATR,a1)
	bcc	redeferr		;.xref/.commシンボルだった
deflabel85:
	tst.b	(OFFSYMMOD,a6)
	beq	deflabel850
	bgt	deflabel_offsym		;offsymでシンボルあり
	move.b	#1,(SYM_FIRST,a1)	;offsymのシンボル
deflabel850:
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	move.l	(LTOPLOC,a6),d0		;ロケーションカウンタ値
	move.l	d0,(SYM_VALUE,a1)
	cmpi.b	#SECT_TEXT,(SECTION,a6)
	bne	deflabel851
	move.l	d0,(LASTSYMLOC,a6)	;テキストセクションで最後に
					;ラベルに定義したロケーションカウンタ値
deflabel851:
	move.b	(ORGNUM,a6),(SYM_ORGNUM,a1)
	move.b	(SECTION,a6),(SYM_SECTION,a1)	;セクション番号
	beq	deflabel88		;(定数ならT_SYMDEFは不要)
	move.w	#T_SYMDEF,d0
	bsr	wrtobjd0w		;シンボル定義
	move.l	a1,d0
	bsr	wrtd0l			;シンボルへのポインタ
deflabel88:
	tst.b	(LABXDEF,a6)
	beq	deflabel9
	move.b	#SECT_XDEF,(SYM_EXTATR,a1)	;外部定義する
deflabel9:
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;a1=行頭のシンボル
deflabel_offsym:
	move.b	#1,(SYM_FIRST,a1)	;offsymのシンボル
	cmpa.l	(OFFSYMSYM,a6),a1
	beq	deflabel_offsym1
;初期値を与えるシンボルでないとき
	movea.l	a1,a2
;現在のシンボル(変数)=現在のロケーションカウンタ(定数)+初期値(定数)-仮シンボル値(変数)
;RPNを作る
	move.l	(LTOPLOC,a6),d1		;現在のロケーションカウンタ
	add.l	(OFFSYMVAL,a6),d1	;+初期値
	lea.l	(RPNBUF,a6),a1
	move.w	#RPN_VALUE,(a1)+
	move.l	d1,(a1)+		;現在のロケーションカウンタ+初期値
	move.w	#RPN_SYMBOL,(a1)+
	move.l	(OFFSYMTMP,a6),(a1)+	;-仮シンボル
	move.w	#OP_SUB|RPN_OPERATOR,(a1)+	;オペレータ
	clr.w	(a1)			;エンドコード(move.w #RPN_END,(a1))
	lea.l	(RPNBUF,a6),a1
	bsr	calcrpn
	movea.l	a2,a1
	tst.w	d0
	beq	deflabel_offsym2	;定数だった
;定数でなかった
	move.b	#SA_NODET,(SYM_ATTRIB,a1)	;値が未定のシンボル
	move.w	#T_EQUEXPR,d0		;式・アドレスのequ/set
	bsr	wrtobjd0w
	move.l	a1,d0
	bsr	wrtd0l			;シンボルへのポインタ
	lea.l	(RPNBUF,a6),a1
	moveq.l	#7,d1			;式のワード数
	moveq.l	#SZ_LONG,d0
	bsr	wrtrpn			;式を出力
	movea.l	a2,a1
	bra	deflabel88

;初期値を与えるシンボルのとき
deflabel_offsym1:
	movea.l	a1,a2
;初期値を与えるシンボルの位置のロケーションカウンタを格納する仮のシンボルを確定
	movea.l	(OFFSYMTMP,a6),a1
	clr.w	(SYM_SECTION,a1)	;(SYM_ORGNUM)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	move.l	(LTOPLOC,a6),(SYM_VALUE,a1)	;ロケーションカウンタ値
;初期値を与えるシンボルを確定
	move.l	(OFFSYMVAL,a6),d1	;初期値
	movea.l	a2,a1
;d1=値
;a1=シンボル
deflabel_offsym2:
	clr.w	(SYM_SECTION,a1)	;(SYM_ORGNUM)
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	move.l	d1,(SYM_VALUE,a1)	;シンボル値
;アセンブルリストに表示するため初期値を出力しておく
	move.w	#T_EQUCONST,d0		;定数のequ/set
	bsr	wrtobjd0w
	move.l	a1,d0
	bsr	wrtd0l			;シンボルへのポインタ
	move.l	d1,d0
	bsr	wrtd0l			;シンボル値
	bra	deflabel88


;----------------------------------------------------------------
;	行のラベル解釈、命令のコード化
;----------------------------------------------------------------
encodeline::
	movea.l	(LINEBUFPTR,a6),a0
	movea.l	a0,a2
	sf.b	(LABXDEF,a6)
	move.w	#-1,(LABNAMELEN,a6)
	bsr	skipspc
	move.b	(a0),d0			;行が終了
	beq	encodecmd99
	cmp.b	#'*',d0			;コメント
	beq	encodecmd99
	cmp.b	#';',d0			;拡張モードのコメント
	beq	encodecmd99
	cmp.b	#'#',d0
	beq	encodecmd99
encodeline1:
	cmp.b	#'.',d0			;.xxxx 命令
	beq	encodecmd1
	tst.b	(ISIFSKIP,a6)
	beq	encodeline2
	movea.l	a0,a1			;ifスキップ中の場合
	moveq.l	#-2,d1			;ラベルを読み飛ばす
encodeline01:
	addq.w	#1,d1
	move.b	(a1)+,d0
	cmp.b	#'.',d0
	beq	encodeline02
	cmp.b	#':',d0
	beq	encodeline02
	cmp.b	#' ',d0
	bhi	encodeline01
encodeline02:
	subq.l	#1,a1
	tst.w	d1
	bmi	encodecmd9
	bra	encodeline3

encodeline2:
	bsr	getword
	tst.w	d2
	bmi	encodecmd9		;ラベル/命令として使用できない文字
encodeline3:
	cmpi.b	#':',(a1)
	beq	encodeline8		;xxxx: ラベル
	cmpi.b	#' ',(a2)		;行がスペースで始まったか?
	bls	encodecmd3		; xxxx 命令
	move.l	a0,(LABNAMEPTR,a6)	;(ラベルの場合)
	move.w	d1,(LABNAMELEN,a6)
	bsr	getmaccmd		;xxxx ラベル/命令(マクロ優先)
	tst.w	d0
	beq	encodeline4
	move.b	(a0),d0			;ラベルの場合
	cmpi.b	#'@',d0
	beq	deflocal11
	cmpi.b	#'9',d0
	bls	deflocal21
	movea.l	a1,a0
	bsr	skipspc
	bra	encodecmd		;続く命令の処理へ

encodeline4:				;命令の可能性がある
	movea.l	a1,a0
	bsr	skipspc
	cmpi.b	#'.',(a0)
	bne	encodeline45
	addq.l	#1,a0			;xxxx.xxxx … 2語目が命令なら1語目はラベル
	bra	encodeline46

encodeline45:
;1語目がcinv/cpush/pmoveで':'がなくて2語目が'.'で始まっていなければ,
;1語目は命令だったことにする
	movea.l	(CMDTBLPTR,a6),a1	;d1/a1は次のgetwordで破壊するので使える
	move.l	(SYM_FUNC,a1),d1
;getwordがa1を破壊するのでa1を使う
	lea.l	(encodeline,pc),a1
	sub.l	a1,d1
	cmp.l	#~cinvpusha-encodeline,d1
	beq	encodeline5		;1語目がcinv/cpushなので1語目は命令
	cmp.l	#~cinvpushlp-encodeline,d1
	beq	encodeline5		;1語目がcinv/cpushなので1語目は命令
	cmp.l	#~pmove-encodeline,d1
	beq	encodeline5		;1語目がpmoveなので1語目は命令
encodeline46:
	bsr	getword
	bsr	getmaccmd
	tst.w	d0
	bne	encodeline5
	tst.l	(CMDTBLPTR,a6)		;2語目も命令→1語目は命令と同名のラベル
	bne	encodecmd5
encodeline5:
	movea.l	(LABNAMEPTR,a6),a0
	move.w	#-1,(LABNAMELEN,a6)	;ラベルの取り消し
	bra	encodecmd2		;1語目が命令だった

;----------------------------------------------------------------
;	':'付きラベルの定義
encodeline8:
	move.b	(a0),d0
	cmpi.b	#'@',d0
	beq	deflocal10
	cmpi.b	#'9',d0
	bls	deflocal20
encodeline10:
	addq.l	#1,a1
	cmpi.b	#':',(a1)
	bne	encodeline11
	addq.l	#1,a1
	st.b	(LABXDEF,a6)		;xxxx:: 外部定義ラベル
encodeline11:
	move.l	a0,(LABNAMEPTR,a6)
	move.w	d1,(LABNAMELEN,a6)
	movea.l	a1,a0
	bsr	skipspc
	cmpi.b	#'.',(a0)
	beq	encodecmd1		;xxxx: .xxxx
	bsr	getword
	tst.w	d2
	bmi	encodecmd3
	cmpi.b	#':',(a1)
	bne	encodecmd3		;xxxx: xxxx
	bsr	deflabel		;xxxx: xxxx: 最初のラベルを定義
	sf.b	(LABXDEF,a6)
	bra	encodeline10

;----------------------------------------------------------------
;	命令のコード化
encodecmd:
	cmp.b	#'.',(a0)
	bne	encodecmd2
encodecmd1:				;'.'で始まる名前は命令優先
	addq.l	#1,a0
	bsr	getword
	bsr	getcmdmac		;命令優先
	bra	encodecmd4

encodecmd2:
	bsr	getword
encodecmd3:
	bsr	getmaccmd		;マクロ優先
encodecmd4:
	tst.w	d0
	bne	encodecmd9		;命令・マクロの誤り
	tst.l	(CMDTBLPTR,a6)
	beq	encodecmd99		;命令がない
encodecmd5:				;オペレーションサイズを得る
	st.b	(CMDOPSIZE,a6)		;(move.b #SZ_NONE,(CMDOPSIZE,a6))
	movea.l	a1,a0
	cmpi.b	#'.',(a0)
	bne	encodecmd7		;オペレーションサイズがない
	moveq.l	#$20,d0
	or.b	(1,a0),d0
	moveq.l	#SZ_BYTE,d1
	cmp.b	#'b',d0			;.b
	beq	encodecmd6
	moveq.l	#SZ_WORD,d1
	cmp.b	#'w',d0			;.w
	beq	encodecmd6
	moveq.l	#SZ_LONG,d1
	cmp.b	#'l',d0			;.l
	beq	encodecmd6
	moveq.l	#SZ_SHORT,d1
	cmp.b	#'s',d0			;.s (short/single)
	beq	encodecmd6
	moveq.l	#SZ_DOUBLE,d1
	cmp.b	#'d',d0			;.d
	beq	encodecmd6
	moveq.l	#SZ_EXTEND,d1
	cmp.b	#'x',d0			;.x
	beq	encodecmd6
	moveq.l	#SZ_PACKED,d1
	cmp.b	#'p',d0			;.p
	beq	encodecmd6
	moveq.l	#SZ_QUAD,d1
	cmp.b	#'q',d0			;.q
	bne	encodecmd7		;サイズ名が存在しない
encodecmd6:				;サイズ指定があった
	moveq.l	#0,d0			;foo=.low.～などがエラーになるのを避ける
	move.b	(2,a0),d0		;サイズの直後の文字
	lea.l	(wordtbl,pc),a1		;語の中に許される文字のテーブル
	tst.b	(a1,d0.w)
	bne	encodecmd7		;語が続いているのでサイズと見なさない
	move.b	d1,(CMDOPSIZE,a6)
	addq.l	#2,a0
	movea.l	(CMDTBLPTR,a6),a1
	cmpi.b	#ST_MACRO,(SYM_TYPE,a1)
	beq	encodecmd7
	move.b	(SYM_SIZE,a1),d0
	tst.b	(CPUTYPE2,a6)
	beq	encodecmd61
	move.b	(SYM_SIZE2,a1),d0	;ColdFireのとき使えるサイズ
encodecmd61:
	moveq.l	#1,d2
	lsl.b	d1,d2
	and.b	d0,d2
	beq	encodecmd7
	tst.b	(ISIFSKIP,a6)		;ifスキップ中のエラー→命令を飛ばして何もしない
	beq	encodecmd71		;指定できないサイズ
encodecmd7:
	bsr	skipspc
	move.l	a0,(LINEPTR,a6)
	rts

encodecmd71:
	move.l	a1,(ERRMESSYM,a6)
	tst.w	(SYM_ARCH,a1)
	beq	encodecmd72
	addq.b	#1,d0			;$FFか?
	bne	ilsizeerr_op		;サイズを指定できる命令
	bra	ilsizeerr_op_no		;$FF:サイズを指定できない命令
encodecmd72:
	addq.b	#1,d0			;$FFか?
	bne	ilsizeerr_pseudo	;サイズを指定できない疑似命令
	bra	ilsizeerr_pseudo_no	;$FF:サイズを指定できない疑似命令

encodecmd9:
	tst.b	(ISIFSKIP,a6)		;ifスキップ中のエラー→命令を飛ばして何もしない
	beq	badopeerr
encodecmd99:				;命令がない場合
	sf.b	(ISMACRO,a6)
	clr.l	(CMDTBLPTR,a6)
	move.l	a0,(LINEPTR,a6)
	rts

;----------------------------------------------------------------
;	ローカルラベルの定義
deflocal10:				;'@@:'
	addq.l	#1,a1
deflocal11:
	tst.b	(ISIFSKIP,a6)
	bne	deflocal30		;.if不成立部の読み飛ばし中なので定義の必要なし
	cmp.w	#2-1,d1
	bne	badopeerr_local
	cmp.b	#'@',(1,a0)
	bne	badopeerr_local		;'@@'でない
	moveq.l	#0,d1
	bra	deflocal5

deflocal30:
	move.w	#-1,(LABNAMELEN,a6)	;ラベルの取り消し
	movea.l	a1,a0
	bsr	skipspc
	bra	encodecmd		;.if不成立部の読み飛ばし中なので定義の必要なし

deflocal20:				;'0:'～'9:'
	addq.l	#1,a1
deflocal21:
	tst.b	(ISIFSKIP,a6)
	bne	deflocal30		;.if不成立部の読み飛ばし中なので定義の必要なし
	move.w	#256-('9'+1),d0		;上位バイトを0にすること
	add.b	(a0)+,d0
	bpl	badopeerr_local
	add.b	#10,d0
	bmi	badopeerr_local
	tst.w	d1
	beq	deflocal22		;1文字
	cmp.w	(LOCALLENMAX,a6),d1
	bcc	badopeerr_local		;最大桁数を越えている?
deflocal211:
	move.w	d0,d2			;×1
	add.w	d0,d0			;×2
	add.w	d0,d0			;×4
	add.w	d2,d0			;×5
	add.w	d0,d0			;×10
	move.w	#256-('9'+1),d2		;上位バイトを0にすること
	add.b	(a0)+,d2
	bpl	badopeerr_local
	add.b	#10,d2
	bmi	badopeerr_local
	add.w	d2,d0
	subq.w	#1,d1
	bne	deflocal211
deflocal22:
	move.w	d0,d1
deflocal5:
	move.w	#-1,(LABNAMELEN,a6)	;ラベルの取り消し
	movea.l	a1,a0			;ラベルの直後(':'があるときは':'の直後)
	bsr	skipspc
	pea.l	(encodecmd,pc)		;(ラベル定義後のジャンプ先)
	movem.l	d0-d2/a0-a2,-(sp)
	movea.l	(LOCALMAXPTR,a6),a2
	move.w	d1,d2
	add.w	d2,d2
	swap.w	d1
	move.w	(a2,d2.w),d1
	addq.w	#1,(a2,d2.w)		;ローカル番号を進める
	bsr	isdefdlocsym
	tst.w	d0
	beq	deflabel85		;すでに登録済み
	bsr	deflocsymbol
	bra	deflabel85		;ラベル定義を行なう(終わったら命令の処理へ)


;----------------------------------------------------------------
;	オペランドのコード化
;----------------------------------------------------------------
;	in :a0=オペランド文字列へのポインタ
;	out:(OPRBUF-)=コード化されたオペランド
encodeopr::
	movea.l	(OPRBUFPTR,a6),a2
	tst.b	(ISIFSKIP,a6)
	bne	encodeopr99
encodeopr1:
	move.b	(a0),d0
	cmp.b	#' ',d0
	bls	encodeopr9
	cmp.b	#'.',d0
	beq	encodeexop		;演算子
encodeopr2:
	bsr	getnum
	tst.w	d0
	beq	encodenum		;数値が得られた
	bpl	encodereal		;浮動小数点実数が得られた
	bsr	getword
	tst.w	d2
	bpl	encodesymr		;語が抜き出せた
encodeopr3:
	move.b	(a0)+,d0
	cmp.b	#"'",d0
	beq	encodestr		;文字列
	cmp.b	#'"',d0
	beq	encodestr		;文字列
	cmp.b	#'!',d0
	beq	encodeinreal		;浮動小数点実数内部表記
encodeopr5:
	clr.b	(a2)+			;1文字のキャラクタ(move.b #OT_CHAR>>8,(a2)+)
	move.b	d0,(a2)+
	cmp.b	#',',d0
	bne	encodeopr1
	bsr	skipspc			;','の後のスペースをスキップ
	bra	encodeopr1

encodeopr9:				;オペランド終了チェック
	bsr	skipspc
	move.b	(a0)+,d0
	cmp.b	#',',d0			;スペース後の','を認識する
	bne	encodeopr99
	move.w	#','|OT_CHAR,(a2)+
	bsr	skipspc
	bra	encodeopr1

encodeopr99:				;オペランドが終了した
	clr.w	(a2)			;(move.w #OT_EOL,(a2))
	rts

;----------------------------------------------------------------
;	演算子のコード化
encodeexop:
	addq.l	#1,a0
	bsr	getword
	tst.w	d2
	beq	encodesize		;1文字→サイズ指定
	moveq.l	#1,d1
	lea.l	(opname_tbl,pc),a4
encodeexop1:
	movea.l	a0,a3
encodeexop2:
	move.b	(a4)+,d0
	beq	encodeexop4
	moveq.l	#$20,d2
	or.b	(a3)+,d2
	cmp.b	d0,d2
	beq	encodeexop2
encodeexop3:				;次の演算子へ
	tst.b	(a4)+
	bne	encodeexop3
encodeexop35:
	addq.b	#1,d1
	tst.b	(a4)
	bpl	encodeexop1
encodeexop_real:			;演算子が存在しない
	subq.l	#1,a0			;浮動小数点実数の可能性あり
	bsr	strtox			;文字列を実数に変換する
	tst.l	d0
	bmi	exprerr			;変換できなければエラー
	move.w	d0,d3
	bra	encodereal

encodeexop4:				;演算子の場合
	cmpi.b	#'.',(a3)+
	bne	encodeexop35		;演算子名が終わっていない
	movea.l	a3,a0
	cmp.b	#OPCOUNT,d1
	bcs	encodeexop5
	sub.b	#OPCOUNT,d1
	lea.l	(opconv_tbl,pc),a4
	move.b	(a4,d1.w),d1		;演算子コードを変換
encodeexop5:
	or.w	#OT_OPERATOR,d1		;演算子
	move.w	d1,(a2)+
	bra	encodeopr1

;----------------------------------------------------------------
;	サイズ指定のコード化
encodesize:
	moveq.l	#$20,d0
	or.b	(a0),d0
	move.w	#OT_SIZE|SZ_BYTE,d2
	cmp.b	#'b',d0			;.b
	beq	encodesize1
	addq.b	#SZ_WORD-SZ_BYTE,d2
	cmp.b	#'w',d0			;.w
	beq	encodesize1
	addq.b	#SZ_LONG-SZ_WORD,d2
	cmp.b	#'l',d0			;.l
	beq	encodesize1
	addq.b	#SZ_SHORT-SZ_LONG,d2
	cmp.b	#'s',d0			;.s (short/single)
	beq	encodesize1
	addq.b	#SZ_DOUBLE-SZ_SHORT,d2
	cmp.b	#'d',d0			;.d
	beq	encodesize1
	addq.b	#SZ_EXTEND-SZ_DOUBLE,d2
	cmp.b	#'x',d0			;.x
	beq	encodesize1
	addq.b	#SZ_PACKED-SZ_EXTEND,d2
	cmp.b	#'p',d0			;.p
	beq	encodesize1
	addq.b	#SZ_QUAD-SZ_PACKED,d2
	cmp.b	#'q',d0			;.q
	beq	encodesize1
	move.w	#OT_MAC|'u',d2
	cmp.b	#'u',d0			;.u
	bne	encodeexop_real		;サイズ名が存在しない
encodesize1:
	move.w	d2,(a2)+
	movea.l	a1,a0
	bra	encodeopr1

;----------------------------------------------------------------
;	数値データのコード化
encodenum:
	move.l	d1,d0
	add.l	d0,d0
	moveq.l	#0,d0
	addx.l	d2,d0			;d1>=0かつd2=0またはd1<0かつd2=-1ならば0
	beq	encodenum02		;32bitで入り切る
	tst.l	d2			;d2=0でもd1の符号拡張になっていなければ,
	beq	encodenum01		;OT_VALUEQで64bit出力する
					;浮動小数点数に変換するときd2=0かつd1<0は
					;正の整数として変換されるようにするため
	move.l	(CMDTBLPTR,a6),d0
	beq	overflowerr		;命令がない
	movea.l	d0,a1
	move.b	(SYM_SIZE,a1),d0	;使えないサイズのビットが1
	tst.b	(CPUTYPE2,a6)
	beq	encodenum00
	move.b	(SYM_SIZE2,a1),d0	;ColdFireで使えないサイズのビットが1
encodenum00:
	tst.b	d0
	bpl	encodenum01		;SZQがあればPMOVEfd
	and.b	#SZS|SZD|SZX|SZP,d0
	bne	overflowerr		;浮動小数点命令でない
	move.b	(CMDOPSIZE,a6),d0
	subq.b	#SZ_SHORT,d0
	blo	overflowerr		;サイズ省略/.s/.d/.x/.p/.qのいずれかではない
encodenum01:
	move.w	#OT_VALUEQ,(a2)+	;64bit数値
	move.l	d2,(a2)+		;上位32bit
	move.l	d1,(a2)+		;下位32bit
	bra	encodeopr1

encodenum02:
	cmp.l	#$100,d1
	bcs	encodenum2
	cmp.l	#$10000,d1
	bcs	encodenum1
	move.w	#OT_VALUE,(a2)+		;32bit数値
	move.l	d1,(a2)+
	bra	encodeopr1

encodenum1:
	move.w	#OT_VALUEW,(a2)+	;16bit数値
	move.w	d1,(a2)+
	bra	encodeopr1

encodenum2:
	or.w	#OT_VALUEB,d1		;8bit数値
	move.w	d1,(a2)+
	bra	encodeopr1

;----------------------------------------------------------------
;	浮動小数点実数データのコード化
encodereal:
	move.w	#OT_REAL,(a2)+		;実数データ
	move.w	d3,(a2)+		;指数部
	move.l	d1,(a2)+		;仮数部上位
	move.l	d2,(a2)+		;      下位
	bra	encodeopr1

;----------------------------------------------------------------
;	シンボル・レジスタ名のコード化
encodesymr:
	cmp.w	#1,d1
	bne	encodesymr2
	move.w	#OT_REGISTER|REG_D0,d2	;2文字の場合
	moveq.l	#$20,d0
	or.b	(a0),d0
	cmp.b	#'d',d0			;Dn?
	beq	encodesymr1
	move.b	#REG_A0,d2
	cmp.b	#'a',d0			;An?
	beq	encodesymr1
	cmp.b	#'s',d0			;SP?
	bne	encodesymr2
	moveq.l	#$20,d0
	or.b	(1,a0),d0
	cmp.b	#'p',d0
	bne	encodesymr2
	move.w	#OT_REGISTER|REG_SP,(a2)+
	movea.l	a1,a0
	bra	encodeopr1

encodesymr1:				;dn,anの場合
	move.b	(1,a0),d0
	sub.b	#'0',d0
	bcs	encodesymr2
	cmp.b	#7,d0
	bhi	encodesymr2
	add.b	d0,d2
	move.w	d2,(a2)+		;レジスタ名
	movea.l	a1,a0
	bra	encodeopr1

encodesymr2:
	move.b	(a0),d0			;ラベルの場合
	cmpi.b	#'@',d0
	beq	encodelocal10		;'@...'はローカルラベル参照
	cmpi.b	#'9',d0
	bls	encodelocal20		;'[0-9]...'はローカルラベル参照
	move.l	a1,-(sp)
	bsr	isdefdsym		;定義済みシンボルかどうかチェック
	tst.w	d0
	bne	encodesymr5
	move.b	(SYM_TYPE,a1),d1	;シンボルタイプ
	bmi	encodereg		;レジスタ名
	cmpi.b	#ST_REGSYM,d1
	beq	encoderegsym		;regシンボル
encodesym:
	move.w	#OT_SYMBOL,(a2)+	;シンボル
	move.l	a1,(a2)+		;シンボルテーブルへのポインタ
	movea.l	(sp)+,a0
	bra	encodeopr1

encodesymr5:				;未定義シンボルの場合
	moveq.l	#ST_VALUE,d2
	bsr	defsymbol		;シンボルを登録
	sf.b	(SYM_FIRST,a6)
	bra	encodesym

encodereg:				;レジスタ名
	move.w	#OT_REGISTER,d0
	move.b	(SYM_REGNO,a1),d0
	move.w	d0,(a2)+
	movea.l	(sp)+,a0
	bra	encodeopr1

encoderegsym:				;regシンボル
	move.w	(SYM_DEFLEN,a1),d0
	movea.l	(SYM_DEFINE,a1),a0
encoderegsym1:
	move.w	(a0)+,(a2)+		;定義内容を転送
	dbra	d0,encoderegsym1
	subq.l	#2,a2
	movea.l	(sp)+,a0
	bra	encodeopr1

;----------------------------------------------------------------
;	ローカルラベル参照を得る
encodelocal10:				;@f/@b
	moveq.l	#0,d0
	subq.w	#1,d1
	bmi	iloprerr_local		;'@'1文字ならエラー
	and.w	#$00FF,d1
	move.w	d1,d2
encodelocal11:
	cmpi.b	#'@',(a0)+
	dbne	d2,encodelocal11
	bne	iloprerr_local		;最後の一文字以外がすべて'@'でなければエラー
encodelocal12:
	moveq.l	#$20,d2
	or.b	(a0)+,d2
	cmpi.b	#'f',d2			;'@f' = 0,1,2,…
	beq	encodelocal15
	cmpi.b	#'b',d2			;'@b' = -1,-2,-3,…
	bne	iloprerr_local		;'@f','@b'でなければエラー
	not.b	d1			;neg.b d1;subq.b #1,d1
encodelocal15:
	ori.w	#OT_LOCALREF,d1		;ローカルラベル参照
	move.w	d1,(a2)+
	move.w	d0,(a2)+
	movea.l	a1,a0
	bra	encodeopr1

encodelocal20:				;0f～9f/0b～9b
	cmp.b	#'$',d0
	beq	encodeopr3		;'$'は現在のロケーションカウンタ
	move.w	#256-('9'+1),d0		;上位バイトを0にすること
	add.b	(a0)+,d0
	bpl	iloprerr
	add.b	#10,d0
	bmi	iloprerr
	subq.w	#2-1,d1			;-1=1文字(0桁),0=2文字(1桁),
					;1=3文字(2桁),2=4文字(3桁),3=5文字(4桁)
	beq	encodelocal12		;1桁なので'f'または'b'のチェックへ
	bcs	iloprerr_local		;1文字以下はエラー
	move.w	d1,d2
	addq.w	#2-1,d2			;0=1文字(0桁),1=2文字(1桁),
					;2=3文字(2桁),3=4文字(3桁),4=5文字(4桁)
	cmp.w	(LOCALLENMAX,a6),d2
	bhi	iloprerr_local		;最大桁数を越えている?
encodelocal21:
	move.w	d0,d2			;×1
	add.w	d0,d0			;×2
	add.w	d0,d0			;×4
	add.w	d2,d0			;×5
	add.w	d0,d0			;×10
	move.w	#256-('9'+1),d2		;上位バイトを0にすること
	add.b	(a0)+,d2
	bpl	iloprerr_local
	add.b	#10,d2
	bmi	iloprerr_local
	add.w	d2,d0
	subq.w	#1,d1
	bne	encodelocal21
;	clr.w	d1
	bra	encodelocal12		;d1.w=0

;----------------------------------------------------------------
;	文字列データのコード化
encodestr:
	movea.l	a0,a1
	moveq.l	#-1,d1
encodestr1:
	addq.w	#1,d1
	move.b	(a0)+,d2
	beq	encodestr4
	bmi	encodestr5
	cmp.b	d0,d2
	bne	encodestr1
encodestr2:
	move.w	#OT_STR,d0		;文字列
	move.b	d1,d0
	move.w	d0,(a2)+
	tst.w	d1
	beq	encodeopr1		;ヌルストリング
	subq.w	#1,d1
	bset.l	#0,d1			;(d1.w = even(d1.w) - 1)
encodestr3:
	move.b	(a1)+,(a2)+
	dbra	d1,encodestr3
	bra	encodeopr1

encodestr5:
  .if EUCSRC=0
	cmp.b	#$A0,d2
	bcs	encodestr6
	cmp.b	#$E0,d2
	bcs	encodestr1		;半角カタカナ
  .else
	bra	encodestr1		;EUC
  .endif
encodestr6:
	addq.w	#1,d1
	tst.b	(a0)+			;2バイト文字の2バイト目
	bne	encodestr1
encodestr4:
	subq.l	#1,a0			;文字列の途中で行が終了してしまった
	cmp.b	#'"',d0
	beq	termerr_doublequote
	bra	termerr_singlequote

;----------------------------------------------------------------
;	浮動小数点実数の内部表記を得る('!xxxx....')
encodeinreal:
	cmpi.b	#'=',(a0)
	beq	encodeopr5		;!=
	move.l	(CMDTBLPTR,a6),d0
	beq	encodeopr5		;命令がない
	movea.l	d0,a1
	moveq.l	#0,d0
	moveq.l	#2-1,d3
	tst.b	(SYM_SIZE,a1)		;使えないサイズのビットが1
	bpl	encodeinreal1		;SZQがあればPMOVEfd
	moveq.l	#SZS|SZD|SZX|SZP,d0
	and.b	(SYM_SIZE,a1),d0	;使えないサイズのビットが1
	bne	encodeopr5		;浮動小数点命令でない
	move.b	(CMDOPSIZE,a6),d0
	bsr	getfplen
	move.w	d1,d3
	bmi	iloprerr		;データサイズが.s/.d/.x/.pでないのでエラー
	moveq.l	#0,d0
encodeinreal1:
	moveq.l	#0,d1
	moveq.l	#8-1,d2
encodeinreal2:
	move.b	(a0)+,d0		;16進数の1桁を得る
	cmp.b	#'_',d0
	beq	encodeinreal2
	sub.b	#'0',d0
	bcs	encodeinreal5
	cmp.b	#9,d0
	bls	encodeinreal3		;0～9
	or.b	#$20,d0
	sub.b	#'a'-('9'+1),d0
	cmp.b	#10,d0			;a～f
	bcs	encodeinreal5
	cmp.b	#15,d0
	bhi	encodeinreal5
encodeinreal3:
	asl.l	#4,d1
	add.l	d0,d1
	dbra	d2,encodeinreal2
	move.w	#OT_VALUE,(a2)+		;32bit数値
	move.l	d1,(a2)+
	move.w	#','|OT_CHAR,(a2)+
	subq.w	#1,d3
	bra	encodeinreal1

encodeinreal5:
	addq.w	#1,d3
	bne	iloprerr		;サイズと内部表記の長さが合わない
	cmp.w	#8-1,d2
	bne	iloprerr		;8桁の倍数でないのでエラー
	subq.l	#2,a2			;(最後の','は不要)
	subq.l	#1,a0
	bra	encodeopr1

;----------------------------------------------------------------
;	オペランドとして与えられた数値を得る
;	in :a0=文字列へのポインタ
;	out:d0.l=数値が得られれば0/浮動小数点実数が得られれば1/エラーなら-1
;	    d2.l:d1.l=得られた数値     /d3.w:d1.l:d2.l=得られた実数値
getnum::
	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2			;上位32bit
	movea.l	a0,a1
	move.b	(a0)+,d0		;1文字目を得る
	cmp.b	#'0',d0
	beq	getnum5			;0...
	bcs	getnum1
	cmp.b	#'9',d0
	bls	getdec			;1～9…10進数
getnum1:
	cmp.b	#'$',d0
	beq	gethex
	cmp.b	#'@',d0
	beq	getoct
	cmp.b	#'%',d0
	beq	getbin
getnum99:
	movea.l	a1,a0			;数値が無かったのでポインタを戻す
	moveq.l	#-1,d0
	rts

getnum5:				;'0'で始まる場合
	move.b	(a0)+,d0
	cmp.b	#'x',d0
	beq	gethex			;0x...
	cmp.b	#'o',d0
	beq	getoct			;0o...
	cmp.b	#'b',d0
	beq	getbin			;0b...
	cmp.b	#'f',d0
	beq	getreal			;0f...
	bra	getdec3			;'0'で始まる10進数

getdec:					;xxxx 10進数
	sub.b	#'0',d0
getdec1:
;d2:d1を10倍してd0を加える
	tst.l	d2
	bne	getdec1_1
	cmp.l	#$19999998,d1		;$19999999以上は10倍して9加えると溢れる
	bls	getdec1_2
getdec1_1:
	add.l	d1,d1
	addx.l	d2,d2			;d2:d1=元のd2:d1*2
	bcs	getdec1_4
	moveq.l	#0,d3
	add.l	d1,d0
	addx.l	d2,d3			;d3:d0=元のd2:d1*2+元のd0
	bcs	getdec1_4
	add.l	d1,d1
	addx.l	d2,d2			;d2:d1=元のd2:d1*4
	bcs	getdec1_4
	add.l	d1,d1
	addx.l	d2,d2			;d2:d1=元のd2:d1*8
	bcs	getdec1_4
	add.l	d0,d1
	addx.l	d3,d2			;d2:d1=元のd2:d1*10+元のd0
	bcc	getdec1_3
getdec1_4:
	bra	getdec4

getdec1_2:
	add.l	d1,d1			;d1=元のd1*2
	add.l	d1,d0			;d0=元のd1*2+元のd0
	lsl.l	#2,d1			;d1=元のd1*8
	add.l	d0,d1			;d1=元のd1*10+元のd0
					;10倍する前に$19999998以下に制限してあるので溢れない
getdec1_3:
	moveq.l	#0,d0			;上位を破壊したのでクリアしておく
getdec2:
	move.b	(a0)+,d0
getdec3:
	cmp.b	#'_',d0
	beq	getdec2
	sub.b	#'0',d0
	bcs	getdec9
	cmp.b	#9,d0
	bls	getdec1
getdec9:				;数値が終了した
	cmp.b	#'.'-'0',d0
	beq	getdecreal		;xxxx. は浮動小数点実数の可能性あり
	or.b	#$20,d0
	sub.b	#'a'-'0',d0
	bcs	getdec99
	cmp.b	#'z'-'a',d0
	bls	getdecreal1
getdec99:
	subq.l	#1,a0
	moveq.l	#0,d0
	rts

;記述された整数が64bitを超えたら整数としてはエラーだが
;	['0'-'9']*{{'.'['0'-'9']+}|{['.']'e'['+'|'-']['0'-'9']+}}
;を伴っていれば実数としては有効
getdec4:
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	getdec4
	sub.b	#'0',d0
	bcs	getdec5
	cmp.b	#10,d0
	bcs	getdec4			;数字をスキップする
getdec5:
	cmp.b	#'.'-'0',d0
	beq	getdec6			;小数点があれば直後が数字または指数
	or.b	#$20,d0
	cmp.b	#'e'-'0',d0
	beq	getdec7
	bra	ilinterr		;数字の直後が小数点でも指数でもない

getdec6:
	move.b	(a0)+,d0
	sub.b	#'0',d0
	bcs	ilinterr		;小数点の直後が数字でも指数でもない
	cmp.b	#10,d0
	bcs	getdec8			;小数点の直後が数字なので実数
	or.b	#$20,d0
	cmp.b	#'e'-'0',d0
	bne	ilinterr		;小数点の直後が数字でも指数でもない
getdec7:
	move.b	(a0)+,d0
	cmp.b	#'+',d0
	beq	getdec71
	cmp.b	#'-',d0
	bne	getdec72
getdec71:
	move.b	(a0)+,d0		;eの直後が+か-
getdec72:
	sub.b	#'0',d0
	bcs	ilinterr		;指数が完成していない
	cmp.b	#10,d0
	bcc	ilinterr		;指数が完成していない
getdec8:
	movem.l	d1-d2/a0,-(sp)
	movea.l	a1,a0
	bsr	strtox			;文字列を実数に変換する
	tst.l	d0
	bmi	ilinterr		;実数でもなかった
	lea.l	(12,sp),sp		;実数だった
	move.w	d0,d3
	moveq.l	#1,d0
	rts

getdecreal:				;数値が浮動小数点実数かどうか調べる
;ここは['0'-'9']+'.'の直後
;['0'-'9']*{{'.'['0'-'9']+}|{['.']'e'['+'|'-']['0'-'9']+}}ならば実数
;.eだけで判断してしまうと後で.e??.という演算子が作られたときに困るはずなので,
;指数部が完成しているかどうかを正しくチェックすること
	move.b	(a0),d0
	sub.b	#'0',d0
	bcs	getdec99		;小数点の直後が数字ではないので整数
	cmp.b	#10,d0
	bcs	getdecreal5		;小数点の直後が数字なので実数
	or.b	#$20,d0
	cmp.b	#'e'-'0',d0
	bne	getdec99		;小数点の直後が数字でも指数でもないので整数
	move.b	(1,a0),d0
	cmp.b	#'+',d0
	beq	getdecreal01
	cmp.b	#'-',d0
	bne	getdecreal02
getdecreal01:
	move.b	(2,a0),d0		;eの直後が+か-
getdecreal02:
	sub.b	#'0',d0
	bcs	getdec99		;指数が完成していない
	cmp.b	#10,d0
	bcc	getdec99		;指数が完成していない
	bra	getdecreal5

getdecreal1:
	cmp.b	#'e'-'a',d0		;xxxxE は浮動小数点実数
	bne	getnum99		;xxxx[A-Z]は数値ではない(ローカルラベル参照)
getdecreal5:
	movem.l	d1-d2/a0,-(sp)
	movea.l	a1,a0
	bsr	strtox			;文字列を実数に変換する
	tst.l	d0
	bmi	getdecreal9		;変換できなかった
	lea.l	(12,sp),sp
	move.w	d0,d3
	moveq.l	#1,d0
	rts

getdecreal9:				;変換できなかったので整数とする
	movem.l	(sp)+,d1-d2/a0
	bra	getdec99

getreal:				;0f.... 浮動小数点実数
	bsr	strtox			;文字列を実数に変換する
	tst.l	d0
	bmi	getnum99		;変換できなかった
	move.w	d0,d3
	moveq.l	#1,d0
	rts

gethex:					;$xxxx 16進数
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	gethex
	sub.b	#'0',d0			;'$'直後の1文字が16進数でなければエラー
	bcs	getnum99
	cmp.b	#9,d0
	bls	gethex5			;0～9
	or.b	#$20,d0
	sub.b	#'a'-('9'+1),d0
	cmp.b	#10,d0			;a～f
	bcs	getnum99
	cmp.b	#15,d0
	bhi	getnum99
gethex5:
	cmp.l	#$10000000,d2
	bcc	ilinterr
	rol.l	#4,d1
	moveq.l	#$0F,d3
	lsl.l	#4,d2
	and.b	d1,d3
	or.b	d3,d2
	eor.b	d3,d1
	or.b	d0,d1
gethex6:
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	gethex6
	sub.b	#'0',d0
	bcs	getnum9
	cmp.b	#9,d0
	bls	gethex5			;0～9
	or.b	#$20,d0
	sub.b	#'a'-('9'+1),d0
	cmp.b	#10,d0			;a～f
	bcs	getnum9
	cmp.b	#15,d0
	bls	gethex5
;	bra	getnum9

getnum9:				;数値が終了した
	subq.l	#1,a0
	moveq.l	#0,d0
	rts

getoct:					;@xxxx 8進数
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	getoct
	sub.b	#'0',d0			;'@'直後の1文字が8進数でなければエラー
	bcs	getnum99
	cmp.b	#7,d0
	bhi	getnum99		;0～7
getoct5:
	cmp.l	#$20000000,d2
	bcc	ilinterr
	rol.l	#3,d1
	moveq.l	#$07,d3
	lsl.l	#3,d2
	and.b	d1,d3
	or.b	d3,d2
	eor.b	d3,d1
	or.b	d0,d1
getoct6:
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	getoct6
	sub.b	#'0',d0
	bcs	getnum9
	cmp.b	#7,d0
	bls	getoct5			;0～7
	bra	getnum9

getbin:					;%xxxx 2進数
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	getbin
	sub.b	#'0',d0			;'%'直後の1文字が2進数でなければエラー
	bcs	getnum99
	cmp.b	#1,d0
	bhi	getnum99		;0～1
getbin5:
	add.l	d1,d1
	addx.l	d2,d2
	bcs	ilinterr
	or.b	d0,d1
getbin6:
	move.b	(a0)+,d0
	cmp.b	#'_',d0
	beq	getbin6
	sub.b	#'0',d0
	bcs	getnum9
	cmp.b	#1,d0
	bls	getbin5			;0～1
	bra	getnum9


;----------------------------------------------------------------
;	サブルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;	文字列から1語を抜き出す
;	in :a0=文字列を指すポインタ
;	out:a1=抜き出した語の次の文字を指すポインタ
;	    d1.w=抜き出した語の長さ-1/d2.w=語として抜き出せない文字なら-1
getword::
	moveq.l	#0,d0
	movea.l	a0,a1
	moveq.l	#-2,d1
getword1:
	move.b	(a1)+,d0
	move.b	(wordtbl,pc,d0.w),d0
	beq	getword8		;語に使えない文字
	bgt	getword1		;語に使える文字
	tst.b	(a1)+			;2バイト文字の1バイト目
	bne	getword1
getword8:
	add.w	a1,d1
	sub.w	a0,d1			;語の長さ-1
	move.w	d1,d2
	bpl	getword9
	clr.w	d1
	rts

getword9:
	subq.l	#1,a1
	rts

wordtbl:				;語の中に許される文字のテーブル
	.dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;
	.dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;
	.dc.b	0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0		;    $           
	.dc.b	1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1		;0123456789     ?
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;@ABCDEFGHIJKLMNO
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,0,1,0,0,1		;PQRSTUVWXYZ \  _
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;`abcdefghijklmno
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0		;pqrstuvwxyz   ~
  .if EUCSRC=0
	.dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	.dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	.dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
  .else
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	.dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .endif


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;	$Log: encode.s,v $
;	Revision 3.2  1999 10/ 8(Fri) 21:48:40 M.Kamada
;	+86 外部参照宣言したシンボルを行頭ラベルとして再定義しようとするとバスエラーになる不具合
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 EUC対応準備
;
;	Revision 3.1  1999  6/ 9(Wed) 20:14:38 M.Kamada
;	+85 演算子!=を有効にする
;
;	Revision 3.0  1999  3/19(Fri) 16:30:23 M.Kamada
;	+83 「ローカルラベルの参照が不正です」を追加
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;	+83 foo=.low.～などがエラーになる不具合を回避
;
;	Revision 2.9  1999  3/ 2(Tue) 20:45:47 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 skiphasspcを廃止
;	+82 getwordを最適化
;
;	Revision 2.8  1999  2/27(Sat) 23:39:29 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.7  1999  2/25(Thu) 04:59:19 M.Kamada
;	+80 ColdFire対応
;	+80 .sizeof.追加
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.6  1998  8/22(Sat) 15:44:53 M.Kamada
;	+75 数字ローカルラベルが定義できなくなっていた
;
;	Revision 2.5  1998  8/20(Thu) 23:47:22 M.Kamada
;	+74 .if不成立部に間違ったローカルラベル(999:など)があるとエラーが出る 
;
;	Revision 2.4  1998  3/31(Tue) 02:18:51 M.Kamada
;	+63 wrt～が届かなくなったのでencode.sのdeflabelをソースの先頭に移動
;
;	Revision 2.3  1998  1/24(Sat) 21:12:06 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 2.2  1998  1/10(Sat) 15:59:06 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 2.1  1997 11/ 1(Sat) 19:58:30 M.Kamada
;	+53 1.wがエラーになる不具合
;
;	Revision 2.0  1997 10/28(Tue) 17:11:16 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;	+52 記述された整数が64bitを超えたらエラー
;	+52 1.E+10がエラーになる不具合
;
;	Revision 1.9  1997  9/15(Mon) 16:47:07 M.Kamada
;	+46 ST_VALUE=0で最適化,aslも最適化
;
;	Revision 1.8  1997  7/20(Sun) 03:12:08 M.Kamada
;	+41 リロケートできない所を修正
;
;	Revision 1.7  1997  6/24(Tue) 22:15:40 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;
;	Revision 1.6  1997  5/12(Mon) 22:27:15 M.Kamada
;	+31 行頭にcpusha dcと書くとエラーになる不都合を修正
;
;	Revision 1.5  1997  3/20(Thu) 16:04:35 M.Kamada
;	+11 2桁の数字ローカルラベルが使えるようにした
;	+23 terminator not foundをエラーに
;
;	Revision 1.4  1994/07/10  11:10:54  nakamura
;	コメント開始キャラクタの追加('#')
;	データサイズコード'.q'の追加
;
;	Revision 1.3  1994/06/09  15:07:10  nakamura
;	シンボルに'$'を使えるようにした。
;
;	Revision 1.2  1994/02/24  11:24:22  nakamura
;	ローカルラベル最後のコロンを忘れると二重定義でエラーになるのを修正した。
;
;	Revision 1.1  1994/02/15  11:55:44  nakamura
;	Initial revision
;
;
