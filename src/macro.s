;----------------------------------------------------------------
;	X68k High-speed Assembler
;		マクロ展開処理
;		< macro.s >
;
;	$Id: macro.s,v 2.2  1999 10/ 8(Fri) 21:51:41 M.Kamada Exp $
;
;		Copyright 1990-94  by Y.Nakamura
;		          1997-99  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	cputype.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	マクロ定義疑似命令のアセンブル処理
;----------------------------------------------------------------

;----------------------------------------------------------------
;	<シンボル>	macro	[<仮引数リスト>]
~~macro::
	move.b	(a0),d0
	cmp.b	#'*',d0
	beq	~~macro1
	cmp.b	#';',d0			;拡張モードのコメント
	bne	~~macro2
~~macro1:				;仮引数リストの位置にコメントがあった場合
	tst.b	(a0)+
	bne	~~macro1
	subq.l	#1,a0
	move.l	a0,(LINEPTR,a6)
~~macro2:
	move.w	(LABNAMELEN,a6),d1
	bmi	nosymerr_macro		;マクロ名がない
	move.w	#-1,(LABNAMELEN,a6)	;定義するのでラベルを取り消す
	movea.l	(LABNAMEPTR,a6),a0
	bsr	isdefdmac
	tst.w	d0
	beq	~~macro5
	bsr	defmacsymbol		;新しく登録する
~~macro5:
	move.w	#T_MACDEF,d0
	bsr	wrtobjd0w
	move.l	a1,d0			;シンボルへのポインタ
	bsr	wrtd0l
	move.l	(TEMPPTR,a6),d0
	bsr	wrtd0l			;定義内容へのポインタ
	move.l	d0,(SYM_DEFINE,a1)
	move.l	a1,(MACSYMPTR,a6)
	movea.l	(LINEPTR,a6),a0
	lea.l	(LOCSYMBUF,a6),a1	;(マクロ仮引数リスト登録バッファ)
	bsr	defpara			;マクロ仮引数リストの登録
	move.l	a1,(MACDEFEND,a6)
	clr.w	(MACLOCSNO,a6)
	clr.b	(MACMODE,a6)		;定義するのはマクロ
	bra	defmacro		;マクロ定義のメインルーチンへ

;----------------------------------------------------------------
;	exitm
~~exitm::
	tst.w	(MACNEST,a6)
	beq	mismacerr_exitm		;マクロ展開中でなければエラー
	move.w	#T_EXITM,d0
	bsr	wrtobjd0w
	bra	macexexitm		;展開中のマクロを終了させる

;----------------------------------------------------------------
;	endm
~~endm::				;(~~endm != ~~localにする)
	bra	mismacerr_endm		;マクロ定義ルーチン外ではエラー

;----------------------------------------------------------------
;	local	<シンボル>[,<シンボル>,…]
~~local::
	bra	mismacerr_local		;マクロ定義ルーチン外ではエラー

;----------------------------------------------------------------
;	sizem	<シンボル>
~~sizem::
	bra	mismacerr_sizem		;マクロ定義ルーチン外ではエラー


;----------------------------------------------------------------
;	拡張疑似命令のアセンブル処理
;----------------------------------------------------------------

;----------------------------------------------------------------
;	.rept	<式>
~~rept::
	bsr	deflabel		;行頭にラベルがあったら定義しておく
	bsr	calcconst
	tst.l	d1			;繰り返し回数(1～65535回)
	beq	~~reptskip
	cmp.l	#$10000,d1
	bcc	ilvalueerr
	move.l	(TEMPPTR,a6),-(sp)
	move.w	d1,-(sp)
	move.b	#-1,(MACMODE,a6)
	bsr	defmacro		;繰り返す行の内容を読み込む
	move.w	#T_REPT,d0
	bsr	wrtobjd0w
	move.w	(sp),d0			;繰り返し回数
	bsr	wrtd0w
	move.l	(2,sp),d0		;繰り返し内容へのポインタ
	bsr	wrtd0l
	move.w	(sp)+,d0
	move.l	(sp)+,a0
	suba.l	a1,a1
	bra	exmacsetup		;次の行からrept開始

~~reptskip:				;0回の繰り返し→繰り返し行をスキップする
	move.b	#-1,(MACMODE,a6)
	bra	defmacro		;繰り返す行の内容を読み込む

;----------------------------------------------------------------
;	.irp	<仮引数>,<実引数>[,<実引数>…]
~~irp0:
	tst.b	(a0)
	beq	iloprerr		;引数がない
	lea.l	(LOCSYMBUF,a6),a1	;(仮引数リスト登録バッファ)
	st.b	(a1)+			;$FF $00 $01
	sf.b	(a1)+
	move.b	#$01,(a1)+
	bsr	getpara			;仮引数を得る
	clr.b	(a1)
	tst.w	d0
	beq	~~irp00			;実引数がない
	moveq.l	#0,d1
	movea.l	(TEMPPTR,a6),a1
	rts

~~irp00:
	addq.l	#4,sp			;(スタック補正)
	bra	~~reptskip

~~irp::
	bsr	deflabel		;行頭にラベルがあったら定義しておく
	bsr	~~irp0			;仮引数を得る
	move.l	a1,-(sp)
~~irp1:
	addq.w	#1,d1
	bsr	getmacpara		;実引数リストを得る
	tst.w	d0
	bne	~~irp1
~~irp2:
	move.l	a1,(TEMPPTR,a6)
	move.l	a1,-(sp)
	move.w	d1,-(sp)		;実引数の数
	move.b	#1,(MACMODE,a6)
	bsr	defmacro		;繰り返す行の内容を読み込む
	move.w	#T_IRP,d0
	bsr	wrtobjd0w
	move.w	(sp),d0			;繰り返し回数
	bsr	wrtd0w
	move.l	(6,sp),d0		;実引数リストへのポインタ
	bsr	wrtd0l
	move.l	(2,sp),d0		;繰り返し内容へのポインタ
	bsr	wrtd0l
	move.w	(sp)+,d0
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	bra	exmacsetup		;次の行からirp/irpc開始

;----------------------------------------------------------------
;	.irpc	<仮引数>,<文字列>
~~irpc::
	bsr	deflabel		;行頭にラベルがあったら定義しておく
	bsr	~~irp0
	move.l	a1,-(sp)

	moveq.l	#0,d1
	move.b	(a0)+,d2
	cmp.b	#'"',d2
	beq	~~irpc1
	cmp.b	#"'",d2
	beq	~~irpc1
	moveq.l	#0,d2
	subq.l	#1,a0
~~irpc1:				;実引数文字列を文字ごとに分解する
	move.b	(a0)+,d0
	bmi	~~irpc3
	beq	~~irpc8
	cmp.b	d0,d2
	beq	~~irpc9
	tst.b	d2
	bne	~~irpc2			;('～' / "～" に囲まれたスペースは実引数)
	cmp.b	#' ',d0
	bls	~~irpc9
~~irpc2:
	move.b	d0,(a1)+
	clr.b	(a1)+
	addq.w	#1,d1
	bra	~~irpc1

~~irpc3:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	~~irpc4
	cmp.b	#$A0,d0
	bcc	~~irpc2			;半角カタカナ
  .else
	bra	~~irpc2			;EUC
  .endif
~~irpc4:				;2バイト文字
	addq.w	#1,d1
	move.b	d0,(a1)+
	move.b	(a0)+,(a1)+		;2バイト文字の2バイト目
	beq	~~irpc8
	clr.b	(a1)+
	bra	~~irpc1

~~irpc8:
	tst.b	d2
	bne	~~irpc91
~~irpc9:
	tst.w	d1
	beq	~~irp00			;実引数がない
	bra	~~irp2

~~irpc91:
;'～'や"～"が閉じていない
	cmp.b	#"'",d2
	beq	termerr_singlequote
	bra	termerr_doublequote


;----------------------------------------------------------------
;	マクロ/rept/irp/irpc命令の登録処理
;----------------------------------------------------------------
;マクロのサイズ指定を格納するローカルシンボルを.sizem疑似命令で登録.
;.sizemは.localとほぼ同じで,マクロの内部で使用可能,更新も可能.
;マクロ登録の時点で.sizemをローカルシンボル番号$FFFFで登録.
;マクロ展開の時点で.sizemのローカルシンボルがあればそこにサイズを格納する.
;マクロの引数の個数を登録するローカルシンボルのローカルシンボル番号は$FFFE
defmacro:
	move.w	#T_MDEFBGN,d0		;マクロ等定義開始
	bsr	wrtobjd0w
	st.b	(ISIFSKIP,a6)		;エラーチェック等はしない
	st.b	(ISMACDEF,a6)
	clr.w	(REPTSKIPNEST,a6)
defmacro1:
	bsr	getline			;1行読み込み
	tst.w	d0
	bmi	defmacro9		;定義中にソースが終了してしまった
	or.w	#T_LINE,d0		;1行開始
	bsr	wrtobjd0w
	bsr	encodeline		;ラベルの処理と命令のコード化
	tst.b	(ISMACRO,a6)
	bne	defmacro2		;マクロ命令
	move.l	(CMDTBLPTR,a6),d0
	beq	defmacro2		;命令がない
	movea.l	d0,a1
	move.l	(SYM_FUNC,a1),a1
	lea.l	(~~macro,pc),a2
	cmpa.l	a1,a2
	beq	defmacnest
	lea.l	(~~endm,pc),a2
	cmpa.l	a1,a2
	beq	defmacend
	lea.l	(~~local,pc),a2
	cmpa.l	a1,a2
	beq	defmaclocal
	lea.l	(~~sizem,pc),a2
	cmpa.l	a1,a2
	beq	defmacsizem
	lea.l	(~~rept,pc),a2
	cmpa.l	a1,a2
	beq	defmacnest
	lea.l	(~~irp,pc),a2
	cmpa.l	a1,a2
	beq	defmacnest
	lea.l	(~~irpc,pc),a2
	cmpa.l	a1,a2
	beq	defmacnest
defmacro2:
	bsr	defmacline		;マクロ行1行のコード置換・登録
	bra	defmacro1

;----------------------------------------------------------------
;	定義中にソースが終了してしまった
defmacro9:
	st.b	(ISASMEND,a6)		;処理を強制終了させる
defmacro99:
	move.w	#T_MDEFEND,d0		;マクロ等定義終了
	bsr	wrtobjd0w
	sf.b	(ISIFSKIP,a6)
	sf.b	(ISMACDEF,a6)
	bra	mismacerr_eof

;----------------------------------------------------------------
;	macro/rept/irp/irpcによる定義のネスト
defmacnest:
;REPTSKIPNESTを増やす前にネストの開始行を展開しておかないと,
;ネストの開始行にローカルラベルがあったときに困る
	bsr	defmacline		;マクロ行1行のコード置換・登録
	addq.w	#1,(REPTSKIPNEST,a6)
	bra	defmacro1

;----------------------------------------------------------------
;	endm
defmacend:
	subq.w	#1,(REPTSKIPNEST,a6)
	bcc	defmacro2		;ネスティングしているreptに対応するendm
defmacend1:
	movea.l	(TEMPPTR,a6),a0
	st.b	(a0)+			;終了コード $FF $00 $00
	sf.b	(a0)+
	sf.b	(a0)+
	move.l	a0,(TEMPPTR,a6)
	sf.b	(ISIFSKIP,a6)
	tst.b	(MACMODE,a6)
	bne	defmacend9		;rept/irp/irpc定義の場合
	movea.l	(MACSYMPTR,a6),a0
	move.w	(MACLOCSNO,a6),(SYM_MACLOCS,a0)	;ローカルシンボルの数
defmacend9:
	move.w	#-1,(LABNAMELEN,a6)	;endm行にラベルがあったら無視する
	move.w	#T_MDEFEND,d0		;マクロ等定義終了
	bsr	wrtobjd0w
	sf.b	(ISMACDEF,a6)
	rts

;----------------------------------------------------------------
;	local	<シンボル>[,<シンボル>,…]
defmaclocal:
	tst.b	(MACMODE,a6)
	bne	defmacro2		;rept/irp/irpc登録中は無視
	movea.l	(LINEPTR,a6),a0
	movea.l	(MACDEFEND,a6),a1
	move.l	a6,d0
	add.l	#LOCSYMBUF+LOCSYMBUFSIZE,d0
	cmpa.l	d0,a1
	bcc	defmac_locsymover
	tst.b	(a0)
	beq	defmaclocal9		;引数リストがない
defmaclocal1:
	move.b	#$FE,(a1)+		;(ローカルシンボルマーク)
	addq.w	#1,(MACLOCSNO,a6)
	move.b	(MACLOCSNO,a6),(a1)+	;high
	move.b	(MACLOCSNO+1,a6),(a1)+	;low
	bsr	getpara			;$FE [ローカルシンボル番号high,low] パラメータ名～ $00
	tst.w	d0
	bne	defmaclocal1
defmaclocal9:
	clr.b	(a1)
	move.l	a1,(MACDEFEND,a6)
	bra	defmacro1

;----------------------------------------------------------------
;1つのマクロの中のローカルシンボルが多すぎて登録できないとき
defmac_locsymover:
	st.b	(ISASMEND,a6)		;処理を強制終了させる
	move.w	#T_MDEFEND,d0		;マクロ等定義終了
	bsr	wrtobjd0w
	sf.b	(ISIFSKIP,a6)
	sf.b	(ISMACDEF,a6)
	bra	toomanylocsymerr

;----------------------------------------------------------------
;	sizem	<シンボル>
defmacsizem:
	tst.b	(MACMODE,a6)
	bne	defmacro2		;rept/irp/irpc登録中は無視
	movea.l	(LINEPTR,a6),a0
	movea.l	(MACDEFEND,a6),a1
	move.l	a6,d0
	add.l	#LOCSYMBUF+LOCSYMBUFSIZE,d0
	cmpa.l	d0,a1
	bcc	defmac_locsymover
	tst.b	(a0)
	beq	defmacsizem9		;引数リストがない
	move.b	#$FE,(a1)+		;(ローカルシンボルマーク)
;.sizemのシンボルは??xxxxにならないのでMACLOCSNO(a6)を増やさなくてよい
	st.b	(a1)+			;サイズ用のローカルシンボル
	st.b	(a1)+
	bsr	getpara			;$FE $FF $FF パラメータ名～ $00
	tst.w	d0
	beq	defmacsizem8		;第2引数がない
	move.b	#$FE,(a1)+		;(ローカルシンボルマーク)
;.sizemのシンボルは??xxxxにならないのでMACLOCSNO(a6)を増やさなくてよい
	st.b	(a1)+			;引数の個数用のローカルシンボル
	move.b	#$FE,(a1)+
	bsr	getpara			;$FE $FF $FE パラメータ名～ $00
defmacsizem8:
					;余計なパラメータは無視する
defmacsizem9:
	clr.b	(a1)
	move.l	a1,(MACDEFEND,a6)
	bra	defmacro1

;----------------------------------------------------------------
;	マクロ行1行のコード置換・登録
defmacline:
	movea.l	(LINEBUFPTR,a6),a0
	movea.l	(TEMPPTR,a6),a2
	tst.b	(MACMODE,a6)
	bpl	defmacline1
defmacline0:
	move.b	(a0)+,(a2)+		;rept登録中なら行の内容を転送するのみ
	bne	defmacline0
	move.l	a2,(TEMPPTR,a6)
	bra	memcheck

defmacline1:
	move.b	(a0),d0
	beq	defmacline9		;行が終了した
	cmp.b	#"'",d0
	beq	defmacstr
	cmp.b	#'"',d0
	beq	defmacstr
	cmp.b	#'&',d0
	bne	defmacline2
	addq.l	#1,a0
	cmp.b	#'&',(a0)
	bne	defmacline1
	move.b	(a0)+,(a2)+		;'&&'→'&'
	bra	defmacline1

defmacline2:
	lea.l	(LOCSYMBUF,a6),a4	;(仮引数リスト登録バッファ)
	movea.l	a0,a3
defmacline3:
	movea.l	a3,a0
	move.b	(a4)+,d3		;$FF(仮引数)/$FE(ローカルシンボル)
	beq	defmacline7
	move.b	(a4)+,d4		;引数/ローカルシンボル番号
	lsl.w	#8,d4
	move.b	(a4)+,d4		;ローカルシンボル番号のlow
;macroの中にreptがあったとき困るので省略
;	tst.w	REPTSKIPNEST(a6)
;	beq	defmacline4		;ネストしていない
;	cmpi.b	#'@',(a4)		;macroがネストしているとき@～は置換しない
;	beq	defmacline5
defmacline4:
	bsr	getword			;登録されている仮引数と比較する
defmacline41:
	cmpm.b	(a0)+,(a4)+
	dbne	d1,defmacline41
	bne	defmacline5
	tst.b	(a4)
	bne	defmacline4		;(2語以上の仮引数)
	move.b	d3,(a2)+		;置換すべき仮引数が見つかった
	ror.w	#8,d4
	move.b	d4,(a2)+
	rol.w	#8,d4
	move.b	d4,(a2)+
	bra	defmacline1

defmacline5:
	subq.l	#1,a4
defmacline6:
	tst.b	(a4)+
	bne	defmacline6
	bra	defmacline3

defmacline7:				;置換すべき仮引数が見つからなかった
	bsr	getword
	tst.b	(MACMODE,a6)
	bne	defmacline8		;rept/irp/irpc登録中は無視
;macroの中にreptがあったとき困るので省略
;	tst.w	REPTSKIPNEST(a6)
;	bne	defmacline8		;ネストの内側の定義中は無視
	cmpi.b	#'@',(a0)
	bne	defmacline8		;@で始まっていない
	move.b	(1,a0),d0		;2文字目
	cmp.b	#'@',d0
	beq	defmacline8		;@@～(これは3文字以上でもキャンセルすること)
	cmp.w	#1,d1			;単語の長さ-1(単語がないときも0)
	blo	defmacline8		;1文字しかない
	bhi	defmacline71		;3文字以上
	or.b	#$20,d0			;@で始まる2文字のとき2文字目を確認
	cmp.b	#'b',d0
	beq	defmacline8		;@b
	cmp.b	#'f',d0
	beq	defmacline8		;@f
defmacline71:
;@～をローカルシンボルとマクロの本体に登録
	movea.l	(MACDEFEND,a6),a1
	move.l	a6,d0
	add.l	#LOCSYMBUF+LOCSYMBUFSIZE,d0
	cmpa.l	d0,a1
	bcc	defmac_locsymover
	moveq.l	#$FE,d0			;(ローカルシンボルマーク)
	move.b	d0,(a1)+		;ローカルシンボルに登録
	move.b	d0,(a2)+		;マクロの本体に登録
	addq.w	#1,(MACLOCSNO,a6)
	move.b	(MACLOCSNO,a6),(a1)+	;ローカルシンボル番号
	move.b	(MACLOCSNO+1,a6),(a1)+
	move.b	(MACLOCSNO,a6),(a2)+	;ローカルシンボル番号
	move.b	(MACLOCSNO+1,a6),(a2)+
defmacline72:
	move.b	(a0)+,(a1)+		;@～
	dbra	d1,defmacline72
	clr.b	(a1)+
	clr.b	(a1)
	move.l	a1,(MACDEFEND,a6)
	bra	defmacline1

defmacline8:
	move.b	(a0)+,(a2)+
	dbra	d1,defmacline8
	bra	defmacline1

defmacline9:				;行が終了
	clr.b	(a2)+
	move.l	a2,(TEMPPTR,a6)
	bra	memcheck

defmacstr:				;文字列の処理
	move.b	d0,d1
	move.b	(a0)+,(a2)+
defmacstr1:
	move.b	(a0)+,d0
	beq	defmacline9		;文字列の途中で行が終了した
	bmi	defmacstr10
	cmp.b	#'&',d0
	beq	defmacstr3
	move.b	d0,(a2)+
	cmp.b	d0,d1
	bne	defmacstr1
	bra	defmacline1		;文字列が終了

defmacstr3:				;文字列中の'&～'は置換の対象とする
	lea.l	(LOCSYMBUF,a6),a1	;(仮引数リスト登録バッファ)
defmacstr4:
	move.b	(a1)+,d2		;$FF(仮引数)/$FE(ローカルシンボル)
	beq	defmacstr8
	move.b	(a1)+,d3		;引数/ローカルシンボル番号high
	lsl.w	#8,d3
	move.b	(a1)+,d3		;low
	movea.l	a0,a3
defmacstr5:				;登録されている仮引数と比較する
	move.b	(a1)+,d0
	beq	defmacstr9
	cmp.b	(a3)+,d0
	beq	defmacstr5
defmacstr6:
	tst.b	(a1)+
	bne	defmacstr6
	bra	defmacstr4

defmacstr8:				;置換すべき仮引数が見つからなかった
	move.b	#'&',(a2)+
	bra	defmacstr1

defmacstr9:				;置換すべき仮引数が見つかった
	move.b	d2,(a2)+
	ror.w	#8,d3
	move.b	d3,(a2)+		;high
	rol.w	#8,d3
	move.b	d3,(a2)+		;low
	movea.l	a3,a0
	bra	defmacstr1

defmacstr10:
	move.b	d0,(a2)+
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	defmacstr11
	cmp.b	#$A0,d0
	bcc	defmacstr1		;半角カナの場合
  .else
	bra	defmacstr1		;EUC
  .endif
defmacstr11:
	move.b	(a0)+,d0		;2バイト文字の2バイト目
	beq	defmacline9		;2バイト目が$00の場合
	move.b	d0,(a2)+
	bra	defmacstr1


;----------------------------------------------------------------
;	マクロ命令のアセンブル処理
;----------------------------------------------------------------
domacro::
	move.w	#T_MACEXT,d0
	move.b	(CMDOPSIZE,a6),d0	;オペレーションサイズ
	bsr	wrtobjd0w		;マクロ展開開始
	movea.l	(CMDTBLPTR,a6),a1
	move.l	a1,d0
	bsr	wrtd0l			;シンボルテーブルへのポインタ
	move.l	(LINEPTR,a6),d0
	movea.l	(LINEBUFPTR,a6),a0
	sub.l	a0,d0
	bsr	wrtd0w			;引数へのオフセット
	move.l	a1,-(sp)
	movea.l	(SYM_DEFINE,a1),a0	;定義内容へのポインタ
	clr.w	d0
	bsr	exmacsetup		;マクロ展開準備
	movea.l	(sp)+,a1
	move.b	(CMDOPSIZE,a6),(MACSIZE,a6)	;オペレーションサイズ
	move.w	(SYM_MACLOCS,a1),d0
	add.w	d0,(MACLOCSMAX,a6)
	movea.l	(LINEPTR,a6),a0
	movea.l	(MACPARAEND,a6),a1
	bsr	defmacpara		;マクロ実引数リストの登録
	move.l	a1,(MACPARAEND,a6)
	rts


;----------------------------------------------------------------
;	マクロ命令展開処理
;----------------------------------------------------------------

;----------------------------------------------------------------
;	マクロ展開の準備をする
;	in :d0.w=繰り返し回数(0ならマクロ)
;	    a0=登録行へのポインタ/a1=実引数リストへのポインタ(irp/irpc展開の場合)
exmacsetup::
	move.w	(MACREPTNEST,a6),d1
	cmp.w	#MACROMAXNEST,d1
	bcc	exmacsetup9		;マクロのネストが深すぎる
	tst.w	d1
	bne	exmacsetup1
	lea.l	(MACINF,a6),a2		;最初のマクロ展開の場合
	move.l	a2,(MACINFPTR,a6)
	lea.l	(MACPARABUF,a6),a2
	move.l	a2,(MACPARAPTR,a6)
	move.l	a2,(MACPARAEND,a6)
	clr.b	(a2)
exmacsetup1:
	movea.l	(MACINFPTR,a6),a2	;それまでの情報を保存する
	move.l	(MACLBGNPTR,a6),(a2)+	;	展開開始行ポインタ
	move.l	(MACLPTR,a6),(a2)+	;	現在の展開行ポインタ
	move.l	(MACPARAPTR,a6),(a2)+	;	実引数バッファポインタ
	move.w	(MACLOCSBGN,a6),(a2)+	;	ローカルシンボル開始番号
	move.w	(IFNEST,a6),(a2)+	;	ifネスティングレベル
	move.w	(REPTCOUNT,a6),(a2)+	;	繰り返し回数
	move.l	(IRPPARAPTR,a6),(a2)+	;	irp/irpc実引数リストポインタ
	move.b	(MACSIZE,a6),(a2)+	;
	move.b	(MACCOUNT,a6),(a2)+	;
	move.l	a2,(MACINFPTR,a6)
	move.l	a0,(MACLPTR,a6)		;マクロ定義行へのポインタ
	move.l	a0,(MACLBGNPTR,a6)
	addq.w	#1,(MACREPTNEST,a6)
	move.l	(MACPARAEND,a6),(MACPARAPTR,a6)
	move.w	(MACLOCSMAX,a6),(MACLOCSBGN,a6)
	move.w	d0,(REPTCOUNT,a6)
	beq	exmacsetup3
exmacsetup2:
	move.l	a1,d0
	bne	exmacsetup4
	rts				;rept展開の場合

exmacsetup3:				;マクロ展開の場合
	addq.w	#1,(MACNEST,a6)
	rts

exmacsetup4:				;irp/irpc展開の場合
	movea.l	(MACPARAPTR,a6),a0
	st.b	(a0)+			;(第一引数)$FF $00 $01
	sf.b	(a0)+
	move.b	#$01,(a0)+
	bsr	strcpy			;引数リストから1つ得る
	move.l	a1,(IRPPARAPTR,a6)
	addq.l	#1,a0
	clr.b	(a0)
	move.l	a0,(MACPARAEND,a6)
	rts

exmacsetup9:				;マクロ展開を中止してエラー発生
	clr.w	(MACREPTNEST,a6)
	clr.w	(MACNEST,a6)
	bra	macnesterr

;----------------------------------------------------------------
;	exitm命令の処理
macexexitm0:
	bsr	macexexit		;それまでにネストしているreptを抜けていく
macexexitm::
	tst.w	(REPTCOUNT,a6)
	bne	macexexitm0

;----------------------------------------------------------------
;	展開中のマクロのネスティングを1段浅くする
macexexit:
	movea.l	(MACINFPTR,a6),a0
	tst.w	(REPTCOUNT,a6)
	bne	macexexit1
	subq.w	#1,(MACNEST,a6)
macexexit1:
	movea.l	(MACPARAPTR,a6),a1
	move.l	a1,(MACPARAEND,a6)
	clr.b	(a1)
	move.b	-(a0),(MACCOUNT,a6)
	move.b	-(a0),(MACSIZE,a6)
	move.l	-(a0),(IRPPARAPTR,a6)
	move.w	-(a0),(REPTCOUNT,a6)
	move.w	-(a0),(IFNEST,a6)
	move.w	-(a0),(MACLOCSBGN,a6)
	move.l	-(a0),(MACPARAPTR,a6)
	move.l	-(a0),(MACLPTR,a6)
	move.l	-(a0),(MACLBGNPTR,a6)
	move.l	a0,(MACINFPTR,a6)
	subq.w	#1,(MACREPTNEST,a6)
	rts

;----------------------------------------------------------------
;	マクロ定義行を1行読み込み展開する
macexline::
	movem.l	d1-d3/a0-a2,-(sp)
	movea.l	(MACLPTR,a6),a2
	movea.l	(LINEBUFPTR,a6),a0
	moveq.l	#0,d3
macexline1:
	move.b	(a2)+,d0
	beq	macexline9
	bmi	macexline5
	tst.b	d3
	beq	macexline3
	cmp.b	d0,d3
	bne	macexline2
	moveq.l	#0,d3
macexline2
	move.b	d0,(a0)+
	bra	macexline1

macexline3:
	cmp.b	#'%',d0
	beq	macexlsym		;シンボル値
	cmp.b	#"'",d0
	beq	macexline4
	cmp.b	#'"',d0
	bne	macexline2
macexline4:
	move.b	d0,d3
	bra	macexline2

macexline5:
	cmp.b	#$FF,d0
	beq	macexlpara		;仮引数,終了コード
	cmp.b	#$FE,d0
	beq	macexllocs		;ローカルシンボル
	move.b	d0,(a0)+
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	macexline6
	cmp.b	#$A0,d0
	bcc	macexline1
  .else
	bra	macexline1		;EUC
  .endif
macexline6:				;2バイト文字の場合
	move.b	(a2)+,(a0)+
	bne	macexline1
	subq.l	#1,a0
macexline9:
	clr.b	(a0)+
	move.l	a2,(MACLPTR,a6)
	movem.l	(sp)+,d1-d3/a0-a2
	moveq.l	#0,d0
	rts

macexlendm:				;マクロ定義行の終了
	move.w	(REPTCOUNT,a6),d0
	beq	macexlendm1
	subq.w	#1,d0
	beq	macexlendm1
	move.w	d0,(REPTCOUNT,a6)
	move.l	(MACLBGNPTR,a6),(MACLPTR,a6)	;reptの次の繰り返しへ
	movea.l	(IRPPARAPTR,a6),a1
	bsr	exmacsetup2		;irp/irpcなら次の実引数へ
	bra	macexlendm2

macexlendm1:
	bsr	macexexit		;マクロのネスティングが1段浅くなる
macexlendm2:
	movem.l	(sp)+,d1-d3/a0-a2
	moveq.l	#-1,d0
	rts

macexlpara:				;仮引数
	move.b	(a2)+,d1		;high
	lsl.w	#8,d1
	move.b	(a2)+,d1		;low
	tst.w	d1
	beq	macexlendm		;endm行の場合
	bsr	macexlpara0
	tst.b	d0
	beq	macexline1		;対応する実引数がない
	bsr	strcpy			;実引数の内容を転送
	bra	macexline1

macexlpara0:				;実引数リストから対応する実引数を検索する
	movem.l	d1-d2,-(sp)
	move.b	d1,d2			;low
	lsr.w	#8,d1			;high
	movea.l	(MACPARAPTR,a6),a1
	bra	macexlpara2

macexlpara05:
	addq.l	#1,a1
macexlpara1:				;次の実引数へ
	tst.b	(a1)+
	bne	macexlpara1
macexlpara2:
	move.b	(a1)+,d0
	beq	macexlpara3		;実引数リストが終了した
	cmp.b	(a1)+,d1		;high
	bne	macexlpara05
	cmp.b	(a1)+,d2		;low
	bne	macexlpara1		;引数番号が違う
macexlpara3:
	movem.l	(sp)+,d1-d2
	rts

macexllocs:				;ローカルシンボル
	move.b	(a2)+,d0		;high
	lsl.w	#8,d0
	move.b	(a2)+,d0		;low
	cmp.w	#$FFFE,d0
	bcc	macexllocs3
	move.b	#'?',(a0)+		;シンボル名を'??xxxx'(xxxx=4桁の16進数)に置換する
	move.b	#'?',(a0)+
	add.w	(MACLOCSBGN,a6),d0
	bsr	convhex4
	bra	macexline1

macexllocs3:
	bne	macexllocs1
	moveq.l	#0,d0
	move.b	(MACCOUNT,a6),d0
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	bra	macexline1

macexllocs1:
	clr.w	d0
	move.b	(MACSIZE,a6),d0
	bpl	macexllocs2
	move.b	#' ',(a0)+		;サイズ指定なし
	move.b	#' ',(a0)+
	bra	macexline1

macexllocs2:
	move.b	#'.',(a0)+		;サイズ指定あり
	move.b	(macexllocs9,pc,d0.w),(a0)+
	bra	macexline1

macexllocs9:
	.dc.b	'bwlsdxpq'
	.even

macexlsym:				;シンボル値
	exg.l	a0,a2
	tst.b	(ISMACDEF,a6)
	bne	macexlsym9		;macro/rept/irp/irpcの登録中
	cmpi.b	#$FF,(a0)
	bne	macexlsym1
	move.b	(1,a0),d1		;仮引数の場合…引数番号を得るhigh
	lsl.w	#8,d1
	move.b	(2,a0),d1		;low
	bsr	macexlpara0
	tst.b	d0
	beq	macexlsym9		;対応する引数がない
	move.l	a0,-(sp)
	movea.l	a1,a0
	bsr	strlen
	subq.l	#1,d1
	bsr	isdefdsym		;その引数はシンボルとして登録されているか?
	movea.l	(sp)+,a0
	bra	macexlsym2

macexlsym1:
	bsr	getword			;'%'の後の語を抜き出す
	tst.w	d2
	bmi	macexlsym9		;語が抜き出せない
	bsr	isdefdsym		;その語はシンボルとして登録されているか?
macexlsym2:
	tst.w	d0
	bmi	macexlsym9		;登録されていない
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;数値シンボルか?
	bne	macexlsym9
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;シンボルは定義済みか?
	blo	macexlsym9
	tst.b	(SYM_SECTION,a1)	;シンボルは定数か?
	bne	macexlsym9
	exg.l	a0,a2
	move.l	(SYM_VALUE,a1),d0	;シンボルの値
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	exg.l	a0,a2
	bsr	getword
	movea.l	a1,a0
	exg.l	a0,a2
	bra	macexline1

macexlsym9:
	exg.l	a0,a2
	move.b	#'%',(a0)+
	bra	macexline1

;----------------------------------------------------------------
;	マクロ引数リストを登録する
;	in :a0=引数リストへのポインタ
;	    a1=引数リス登録バッファへのポインタ
;	out:a0=引数リスト終了位置へのポインタ
;	    a1=登録後のバッファへのポインタ
defmacpara::
	clr.w	d1
	move.b	(a0),d0
	beq	defmacpara9		;引数リストがない
defmacpara1:
	st.b	(a1)+			;(引数マーク)
	addq.w	#1,d1
	ror.w	#8,d1
	move.b	d1,(a1)+		;high
	rol.w	#8,d1
	move.b	d1,(a1)+		;low
	bsr	getmacpara		;$FF [引数番号high,low] パラメータ名～ $00
	tst.w	d0
	bne	defmacpara1
defmacpara9:
	move.b	d1,(MACCOUNT,a6)	;マクロの引数の個数
	clr.b	(a1)
	rts

;----------------------------------------------------------------
;	マクロ引数リスト1つを得る
;	in :a0=引数リストへのポインタ/a1=引数バッファへのポインタ
;	out:d0.l=0ならその引数で終了
getmacpara::
	cmpi.b	#'<',(a0)		;'<～>'文字列をそのまま通す
	beq	getmacparars
	moveq.l	#0,d3			;'(～)','[～]','{～}'のネスティング
getmacpara0:
	move.b	(a0)+,d0
	move.b	d0,(a1)+		;区切りがくるまで転送する
	bmi	getmacpara2
	cmp.b	#"'",d0			;'～',"～"は文字列
	beq	getmacparastr
	cmp.b	#'"',d0
	beq	getmacparastr
	cmp.b	#'(',d0			;括弧の始まり
	beq	getmacparapb
	cmp.b	#'[',d0
	beq	getmacparapb
	cmp.b	#'{',d0
	beq	getmacparapb
	cmp.b	#')',d0			;括弧の終わり
	beq	getmacparape
	cmp.b	#']',d0
	beq	getmacparape
	cmp.b	#'}',d0
	beq	getmacparape
	cmp.b	#'%',d0			;シンボル値
	beq	getmacparasym
	cmp.b	#'!',d0			;1文字をそのまま通す
	beq	getmacpararc
	cmp.b	#',',d0
	beq	getmacpara1
	cmp.b	#' ',d0
	bhi	getmacpara0
	bra	getpara1

getmacpara1:
	tst.w	d3
	beq	getpara5
	bra	getmacpara0

getmacpara2:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getmacpara3
	cmp.b	#$A0,d0
	bcc	getmacpara0		;半角カナの場合
  .else
	bra	getmacpara0		;EUC
  .endif
getmacpara3:
	move.b	(a0)+,d0		;2バイト文字の2バイト目
	move.b	d0,(a1)+
	bne	getmacpara0
	bra	getpara1		;2バイト目が$00の場合

getmacparastr:				;文字列の処理
	move.b	(a0)+,d2
	move.b	d2,(a1)+
	beq	getmacparastr01		;行が終わってしまった
	bmi	getmacparastr1
	cmp.b	d2,d0
	bne	getmacparastr
	bra	getmacpara0

getmacparastr1:
  .if EUCSRC=0
	cmp.b	#$E0,d2
	bcc	getmacparastr2
	cmp.b	#$A0,d2
	bcc	getmacparastr		;半角カナの場合
  .else
	bra	getmacparastr		;EUC
  .endif
getmacparastr2:
	move.b	(a0)+,d2		;2バイト文字の2バイト目
	move.b	d2,(a1)+
	bne	getmacparastr
	bra	iloprerr		;2バイト目が$00の場合

getmacparastr01:
	cmp.b	#"'",d0
	beq	termerr_singlequote
	bra	termerr_doublequote

getmacparapb:				;括弧の始まり
	addq.w	#1,d3
	bra	getmacpara0

getmacparape:				;括弧の終わり
	subq.w	#1,d3
	bcc	getmacpara0
	moveq.l	#0,d3			;')',']','}'の数が多かった
	bra	getmacpara0

getmacpararc:
	move.b	(a0)+,d0		;'!'のあとの1文字はそのまま通す
	move.b	d0,(-1,a1)
	beq	iloprerr		;'!'で行が終了した
	bpl	getmacpara0
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getmacpararc1
	cmp.b	#$A0,d0
	bcc	getmacpara0		;半角カナの場合
  .else
	bra	getmacpara0		;EUC
  .endif
getmacpararc1:
	move.b	(a0)+,d0		;2バイト文字の2バイト目
	move.b	d0,(a1)+
	bne	getmacpara0
	bra	iloprerr		;2バイト目が$00の場合

getmacparasym:				;シンボル値
	movem.l	d1/a1,-(sp)
	bsr	getword			;'%'の後の語を抜き出す
	tst.w	d2
	bmi	getmacparasym9		;語が抜き出せない
	bsr	isdefdsym		;その語はシンボルとして登録されているか?
	tst.w	d0
	bmi	getmacparasym9		;登録されていない
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;数値シンボルか?
	bne	getmacparasym9
	cmpi.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;シンボルは定義済みか/
	blo	getmacparasym9
	tst.b	(SYM_SECTION,a1)	;シンボルは定数か?
	bne	getmacparasym9
	move.l	(SYM_VALUE,a1),d0	;シンボルの値
	moveq.l	#0,d1			;(左詰め)
	movea.l	a0,a1
	movea.l	(4,sp),a0
	subq.l	#1,a0
	bsr	convdec
	move.l	a0,(4,sp)		;数値の終了位置
	movea.l	a1,a0
	bsr	getword
	movea.l	a1,a0
getmacparasym9:
	movem.l	(sp)+,d1/a1
	bra	getmacpara0

getmacparars:				;'<～>'の間の文字列はそのまま通す
	addq.l	#1,a0
getmacparars1:
	move.b	(a0)+,d0
getmacparars2:
	move.b	d0,(a1)+
	beq	termerr_bracket		;対応する'>'がないまま行が終了した
	bmi	getmacparars3
	cmp.b	#'>',d0
	bne	getmacparars1
	move.b	(a0)+,d0
	cmp.b	#',',d0
	beq	getpara5		;文字列が'>'で終了し、次のパラメータがある
	cmp.b	#' ',d0
	bhi	getmacparars2		;'>'の後に文字が続くときは終端記号でない
	bra	getpara1

getmacparars3:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getmacparars4
	cmp.b	#$A0,d0
	bcc	getmacparars1		;半角カナの場合
  .else
	bra	getmacparars1		;EUC
  .endif
getmacparars4:
	move.b	(a0)+,d0		;2バイト文字の2バイト目
	move.b	d0,(a1)+
	bne	getmacparars1
	bra	iloprerr

;----------------------------------------------------------------
;	引数リストを登録する
;	in :a0=引数リストへのポインタ
;	    a1=引数リス登録バッファへのポインタ
;	out:a0=引数リスト終了位置へのポインタ
;	    a1=登録後のバッファへのポインタ
defpara::
	clr.w	d1
	move.b	(a0),d0
	beq	defpara9		;引数リストがない
defpara1:
	st.b	(a1)+			;(引数マーク)
	addq.w	#1,d1			;引数番号は1～
	ror.w	#8,d1
	move.b	d1,(a1)+		;high
	rol.w	#8,d1
	move.b	d1,(a1)+		;low
	bsr	getpara			;$FF [引数番号high,low] パラメータ名～ $00
	tst.w	d0
	bne	defpara1
defpara9:
	clr.b	(a1)
	rts

;----------------------------------------------------------------
;	引数リスト1つを得る
;	in :a0=引数リストへのポインタ/a1=引数バッファへのポインタ
;	out:d0.l=0ならその引数で終了
getpara::
	move.b	(a0)+,d0
	move.b	d0,(a1)+		;区切りがくるまで転送する
	bmi	getpara2
	cmp.b	#',',d0
	beq	getpara5
	cmp.b	#' ',d0
	bhi	getpara
getpara1:
	clr.b	(-1,a1)
	subq.l	#1,a0
	bsr	skipspc
	moveq.l	#-1,d0
	cmp.b	#',',(a0)+
	bne	getpara9
	bra	skipspc			;まだ引数が続く

getpara9:
	moveq.l	#0,d0
	rts

getpara2:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getpara3
	cmp.b	#$A0,d0
	bcc	getpara			;半角カナの場合
  .else
	bra	getpara			;EUC
  .endif
getpara3:
	move.b	(a0)+,d0		;2バイト文字の2バイト目
	move.b	d0,(a1)+
	bne	getpara
	bra	getpara1		;2バイト目が$00の場合

getpara5:
	clr.b	(-1,a1)
	moveq.l	#-1,d0
	bra	skipspc			;まだ引数が続く


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;	$Log: macro.s,v $
;	Revision 2.2  1999 10/ 8(Fri) 21:51:41 M.Kamada
;	+86 EUC対応準備
;
;	Revision 2.1  1999  4/28(Wed) 22:21:13 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;	+84 1つのマクロでローカルシンボルを254個以上登録できる
;
;	Revision 2.0  1999  3/ 2(Tue) 20:20:23 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 skiphasspcを廃止
;
;	Revision 1.9  1999  2/27(Sat) 23:42:25 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.8  1998  8/26(Wed) 13:26:52 M.Kamada
;	+76 マクロ内ローカルシンボル@～を2個以上定義すると誤動作する
;
;	Revision 1.7  1998  8/21(Fri) 03:14:51 M.Kamada
;	+74 マクロ定義中の@～を自動的にローカル宣言する
;
;	Revision 1.6  1998  8/18(Tue) 20:03:08 M.Kamada
;	+72 .sizemの第2引数のローカルシンボルにマクロの引数の個数を定義する
;
;	Revision 1.5  1998  1/24(Sat) 22:07:35 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 1.4  1997  9/15(Mon) 15:58:48 M.Kamada
;	+46 ST_VALUE=0で最適化
;
;	Revision 1.3  1997  9/15(Mon) 03:58:42 M.Kamada
;	+45 マクロ名$oprcntでパラメータ数,マクロ名$opsizeでサイズ指定を参照,shift新設
;
;	Revision 1.2  1997  6/24(Tue) 22:01:14 M.Kamada
;	+34 プレデファインシンボルに対応
;
;	Revision 1.1  1994/02/13  14:38:38  nakamura
;	Initial revision
;
;
