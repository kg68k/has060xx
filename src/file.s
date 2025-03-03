;----------------------------------------------------------------
;	X68k High-speed Assembler
;		ファイル入出力
;		< file.s >
;
;	$Id: file.s,v 1.4  1999  2/27(Sat) 23:41:32 M.Kamada Exp $
;
;		Copyright 1990-94  by Y.Nakamura
;			  1996-99  by M.Kamada
;			  2025     by TcbnErik
;----------------------------------------------------------------

	.include	doscall.mac
	.include	has.equ
	.include	tmpcode.equ
	.include	error2.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	ファイル管理ルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;	ファイルを読み込みモードでオープンする
;	in :a0=ファイル名へのポインタ /INPFILPTR=入力ファイルポインタへのポインタ
;	out:d0.w=オープンしたファイルハンドル(エラーなら負の数)
readopen::
	move.l	a0,(INPFILE,a6)
	move.l	a1,-(sp)
	movea.l	(INPFILPTR,a6),a1
	clr.w	-(sp)			;'r'
	pea.l	(a0)
	DOS	_OPEN
	addq.l	#6,sp
	move.w	d0,(F_HANDLE,a1)
	move.l	a0,(F_NAMEPTR,a1)
	clr.l	(F_TOPOFST,a1)
	clr.l	(F_DATALEN,a1)
	clr.l	(F_PTROFST,a1)
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	ファイルを新たに作成する(実際には準備をするだけ)
;	in :a0=ファイル名へのポインタ /OUTFILPTR=出力ファイルポインタへのポインタ
;	out:---
createopen::
	move.l	a1,-(sp)
	movea.l	(OUTFILPTR,a6),a1
	move.l	a0,(F_NAMEPTR,a1)
	clr.l	(F_TOPOFST,a1)
	clr.l	(F_DATALEN,a1)
	clr.l	(F_PTROFST,a1)
	move.w	#-1,(F_HANDLE,a1)	;ファイルはまだ実際に作られていない
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	出力ファイル(PRNファイルなど)をオープンする
;	in :a0=ファイル名へのポインタ
;	out:d0.w=オープンしたファイルハンドル(エラーなら負の数)
prnopen::
	move.w	#$20,-(sp)		;ファイル属性(Archive)
	pea.l	(a0)
	DOS	_CREATE			;ファイルを作成する
	addq.l	#6,sp
	tst.l	d0
	bpl	prnopen9
	move.w	#1,-(sp)		;書き込みモード
	pea.l	(a0)
	DOS	_OPEN			;(_CREATEだとCONなどのオープンができないから)
	addq.l	#6,sp
	tst.l	d0
	bmi	filopenabort		;ファイルオープンに失敗
	move.w	d0,-(sp)
	clr.w	-(sp)
	DOS	_IOCTRL
	addq.l	#2,sp
	btst.l	#1,d0
	beq	prnopen8
	st.b	(ISPRNSTDOUT,a6)	;オープンしたファイルは標準出力
	st.b	(NOPAGEFF,a6)
	DOS	_CLOSE
	move.w	#STDOUT,(sp)
prnopen8:
	move.w	(sp)+,d0
prnopen9:
	rts

;----------------------------------------------------------------
;	入力ファイルをクローズする
;	in :---
;	out:---
inpclose::
	move.l	a1,-(sp)
	movea.l	(INPFILPTR,a6),a1
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_CLOSE
	addq.l	#2,sp
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	出力ファイルをクローズする
;	in :---
;	out:---
outclose::
	move.l	a1,-(sp)
	movea.l	(OUTFILPTR,a6),a1
	bsr	writebuf		;ファイルバッファをフラッシュする
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_CLOSE
	addq.l	#2,sp
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	インクルードファイルをオープンする
;	in :a0=ファイル名へのポインタ
;	out:d0.w=オープンできたら0
openincld::
	cmpi.w	#INCLDMAXNEST,(INCLDNEST,a6)
	bcc	tooinclderr		;ネスティングが深すぎる
	movem.l	a0-a2,-(sp)
	lea.l	(INCLDPTR,a6),a1	;インクルードファイルポインタ
	lea.l	(INCLDINF,a6),a2
	tst.w	(INCLDNEST,a6)
	beq	openincld1
	movea.l	(INCLDINFPTR,a6),a2	;2重以上のネスティングの場合
	move.l	(F_TOPOFST,a1),d0
	add.l	(F_PTROFST,a1),d0	;ファイルポインタ位置を得る
	move.l	d0,(a2)+
	move.l	(F_NAMEPTR,a1),(a2)+
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_CLOSE			;ファイルをクローズする
	addq.l	#2,sp
openincld1:
	move.l	(LINENUM,a6),(a2)+
	move.l	a2,(INCLDINFPTR,a6)
	move.l	a1,(INPFILPTR,a6)	;入力ファイルを切り替える
	bsr	readopen
	clr.l	(LINENUM,a6)
	addq.w	#1,(INCLDNEST,a6)
	tst.w	d0
	bmi	openincld9
	moveq.l	#0,d0
	movem.l	(sp)+,a0-a2
	rts

openincld9:				;ファイルオープンに失敗
	bsr	closeincld
	moveq.l	#-1,d0
	movem.l	(sp)+,a0-a2
	rts

;----------------------------------------------------------------
;	インクルードファイルをクローズする
;	in :---
;	out:---
closeincld::
	movem.l	d0/a0-a2,-(sp)
	lea.l	(INCLDPTR,a6),a1
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_CLOSE			;ファイルをクローズする
	addq.l	#2,sp
	movea.l	(INCLDINFPTR,a6),a2
	move.l	-(a2),(LINENUM,a6)
	subq.w	#1,(INCLDNEST,a6)
	beq	closeincld1		;元のソースファイルに戻った
	move.l	-(a2),a0
	bsr	readopen		;1つ前のインクルードファイルをオープンする
	move.l	-(a2),(F_TOPOFST,a1)
	clr.w	-(sp)
	move.l	(a2),-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;それまでの読み込み位置までシークする
	addq.l	#8,sp
	clr.l	(F_DATALEN,a1)
	bsr	readbuf			;ファイルバッファの内容をもとに戻す
	move.l	a2,(INCLDINFPTR,a6)
	movem.l	(sp)+,d0/a0-a2
	rts

closeincld1:				;元のソースファイルに戻ってきた
	move.l	a2,(INCLDINFPTR,a6)
	lea.l	(SOURCEPTR,a6),a0
	move.l	a0,(INPFILPTR,a6)
	move.l	(SOURCEFILE,a6),(INPFILE,a6)
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;	指定されたインクルードファイルを検索する
;	in :a0=ファイル名へのポインタ
;	out:d0.w=0ならファイルが見つかった/a0=見つかったファイル名へのポインタ(パス名付き)
srchincld::
	link	a5,#-128
	movem.l	a1-a3,-(sp)
	movea.l	a0,a2
	lea.l	(-128,a5),a0		;カレントディレクトリからファイルを検索する
	bsr	srchinclds
	beq	srchincld7

	lea	(INCPATHCMD,a6),a3	;コマンドラインの -i path からファイルを検索する
	bsr	srchincldilist
	beq	srchincld7

	lea	(INCPATHENV,a6),a3	;環境変数の -i path からファイルを検索する
	bsr	srchincldilist
	beq	srchincld7

	lea.l	(-128,a5),a0		;環境変数'include'のパスからファイルを検索する
	movea.l	a0,a1
	pea.l	(a0)
	clr.l	-(sp)
	pea.l	(env_incld,pc)
	bsr	getenv			;DOS _GETENV
	lea.l	(12,sp),sp
	tst.l	d0
	bmi	srchincld6		;環境変数が設定されていない
	bsr	pathcpy
	bsr	srchinclds
	beq	srchincld7
srchincld6:				;ファイルが見つからなかった
	moveq.l	#-1,d0
	bra	srchincld9

srchincld7:				;ファイルが見つかった
	movea.l	(TEMPPTR,a6),a0
	movea.l	a0,a1
	lea.l	(-128,a5),a2
srchincld8:
	move.b	(a2)+,(a1)+
	bne	srchincld8
	move.l	a1,(TEMPPTR,a6)
	bsr	memcheck
	moveq.l	#0,d0
srchincld9:
	movem.l	(sp)+,a1-a3
	unlk	a5
	rts

srchincldilistlp:
	movea.l	d0,a3
	movea.l	(4,a3),a1		;パス名
	lea	(-128,a5),a0
	bsr	pathcpy
	bsr	srchinclds
	beq	9f
srchincldilist:
	move.l	(a3),d0
	bne	srchincldilistlp	;次の'-i'パスを検索する
	moveq	#-1,d0
9:	rts

srchinclds:				;ファイルがあるかどうかをチェック
	movea.l	a2,a1
	bsr	strcpy			;ファイル名を転送
	clr.w	-(sp)
	pea.l	(-128,a5)
	DOS	_OPEN			;オープンしてみる
	addq.l	#6,sp
	tst.l	d0
	bmi	srchinclds2		;ファイルがない
	move.w	d0,-(sp)
	DOS	_CLOSE			;ファイルがあったのでクローズする
	addq.l	#2,sp
	moveq.l	#0,d0
srchinclds2:
	rts

;----------------------------------------------------------------
;	テンポラリファイル名を作成する
;	in :---
;	out:a0=作成したファイル名へのポインタ
maketmpname::
	move.l	a1,-(sp)
	movea.l	(TEMPPTR,a6),a0
	movem.l	d0-d2/a0,-(sp)
	movea.l	(TEMPPATH,a6),a1
	tst.b	(a1)
	bne	maketmpname2		;/tの指定があった場合
	movea.l	a0,a1
	pea.l	(a0)
	clr.l	-(sp)
	pea.l	(env_temp,pc)
	bsr	getenv			;DOS _GETENV
					;環境変数'temp'の内容を読み出す
	lea.l	(12,sp),sp
	tst.l	d0
	bmi	maketmpname25		;環境変数'temp'が定義されていない
maketmpname2:
	bsr	pathcpy
maketmpname25:
	lea.l	(temp_name,pc),a1
	bsr	strcpy			;テンポラリファイル名を転送
	addq.l	#1,a0
	move.l	a0,(TEMPPTR,a6)
maketmpname9:
	movem.l	(sp)+,d0-d2/a0-a1
	rts

env_incld:
	.dc.b	'include',0
env_temp:
	.dc.b	'temp',0
temp_name:
	.dc.b	'tmp000.$$$',0
	.even

;----------------------------------------------------------------
;	オブジェクトバッファに1ロングワードのデータを出力する
;	in :d0.l=書き込みデータ
;	out:---
wrt1lobj::
	swap.w	d0
	bsr	wrt1wobj
	swap.w	d0

;----------------------------------------------------------------
;	オブジェクトバッファに1ワードのデータを出力する
;	in :d0.w=書き込みデータ
;	out:---
wrt1wobj::
	move.w	d0,-(sp)
	lsr.w	#8,d0
	bsr	wrt1bobj
	move.w	(sp)+,d0

;----------------------------------------------------------------
;	オブジェクトバッファに1バイトのデータを出力する
;	in :d0.b=書き込みデータ
;	out:---
wrt1bobj::
	addq.l	#1,(LOCATION,a6)
wrt1bobj0::				;(ロケーションカウンタは変更しない)
	tst.b	(ISOBJOUT,a6)
	bne	wrt1bobj9
	movem.l	d1/a0,-(sp)
	move.w	(OBJCONCTR,a6),d1
	cmp.w	#$0100,d1
	bcs	wrt1bobj1
	bsr	flushobj
	clr.w	d1
wrt1bobj1:
	lea.l	(OBJCONBUF,a6),a0
	move.b	d0,(a0,d1.w)
	addq.w	#1,(OBJCONCTR,a6)
	movem.l	(sp)+,d1/a0
wrt1bobj9:
wrtobjd0w1:
	rts

;----------------------------------------------------------------
;	オブジェクトバッファをフラッシュ後、必要なら出力ファイルへデータを書き込む
;	in :d0.w=書き込みデータ
;	out:---
wrtobjd0w::
	tst.b	(ISOBJOUT,a6)
	bne.s	wrtobjd0w1
	bsr	flushobj
	bra	tmpwrtd0w

;----------------------------------------------------------------
;	必要なら出力ファイルへデータを書き込む
;	in :d0.l=書き込みデータ
;	out:---
wrtd0l::
	swap.w	d0
	bsr	wrtd0w
	swap.w	d0

;----------------------------------------------------------------
;	必要なら出力ファイルへデータを書き込む
;	in :d0.w=書き込みデータ
;	out:---
wrtd0w::
	tst.b	(ISOBJOUT,a6)
	bne.s	wrtobjd0w1

;----------------------------------------------------------------
;	出力ファイルへデータを書き込む
;	in :d0.w=書き込みデータ
;	out:---
tmpwrtd0w:
	movem.l	d0/a1,-(sp)
	movea.l	(OUTFILPTR,a6),a1
	move.l	(F_PTROFST,a1),d0
	cmp.l	(F_BUFLEN,a1),d0
	bcs	tmpwrtd0w1
	bsr	writebuf		;バッファがいっぱいになったので書き出す
	moveq.l	#0,d0			;(F_PTROFST,a1)
tmpwrtd0w1:
	add.l	(F_BUFPTR,a1),d0
	addq.l	#2,(F_PTROFST,a1)
	addq.l	#2,(F_DATALEN,a1)
	movea.l	d0,a1
	move.w	(2,sp),(a1)
	movem.l	(sp)+,d0/a1
	addq.l	#2,(OBJLENCTR,a6)	;オブジェクトファイル長
	rts

;----------------------------------------------------------------
;	テンポラリファイルからデータを読み込む
;	in :---
;	out:d0.l=読み込みデータ
tmpreadd0l::
	bsr	tmpreadd0w
	move.w	d0,-(sp)
	bsr	tmpreadd0w
	swap.w	d0
	move.w	(sp)+,d0
	swap.w	d0
	rts

;----------------------------------------------------------------
;	テンポラリファイルからデータを読み込む
;	in :---
;	out:d0.w=読み込みデータ
tmpreadd0w::
	move.l	a1,-(sp)
	move.l	(F_PTROFST+TEMPFILPTR,a6),d0
	cmp.l	(F_DATALEN+TEMPFILPTR,a6),d0
	bcs	tmpreadd0w1
	lea.l	(TEMPFILPTR,a6),a1
	bsr	readbuf			;バッファが空なので読み出す
	subq.l	#1,d0
	bmi	tmpreadd0w9		;エラー発生/ファイルが終了
	moveq.l	#0,d0			;(F_PTROFST,a1)
tmpreadd0w1:
	add.l	(F_BUFPTR+TEMPFILPTR,a6),d0
	addq.l	#2,(F_PTROFST+TEMPFILPTR,a6)
	movea.l	d0,a1
	move.w	(a1),d0
tmpreadd0w9:
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	オブジェクトバッファをフラッシュする
;	in :---
;	out:---
flushobj::
	movem.l	d0-d1/a0,-(sp)
	move.w	(OBJCONCTR,a6),d0
	beq	flushobj2		;バッファが空
	move.w	d0,d1
	subq.w	#1,d0
	or.w	#T_CONST,d0
	bsr	tmpwrtd0w
	lea.l	(OBJCONBUF,a6),a0
flushobj1:
	move.w	(a0)+,d0
	bsr	tmpwrtd0w
	subq.w	#2,d1
	bhi	flushobj1
	clr.w	(OBJCONCTR,a6)
flushobj2:
	movem.l	(sp)+,d0-d1/a0
	rts

;----------------------------------------------------------------
;	ファイルバッファへデータを読み込む
;	in :a1=ファイルポインタへのポインタ
;	out:d0.l=実際に読み込んだバイト数(エラーなら負の数)
readbuf:
	move.l	(F_DATALEN,a1),d0
	add.l	d0,(F_TOPOFST,a1)
	move.l	(F_BUFLEN,a1),-(sp)	;読み込みサイズ
	move.l	(F_BUFPTR,a1),-(sp)	;ファイルバッファへのポインタ
	move.w	(F_HANDLE,a1),-(sp)	;ファイルハンドル
	DOS	_READ
	lea.l	(10,sp),sp
	move.l	d0,(F_DATALEN,a1)
	clr.l	(F_PTROFST,a1)
	rts

;----------------------------------------------------------------
;	ファイルバッファ内のデータを書き込む
;	in :a1=ファイルポインタへのポインタ
;	out:--- (エラーならプログラムを中断する)
writebuf::
	move.l	d0,-(sp)
	tst.l	(F_PTROFST,a1)
	beq	writebuf9		;ファイルバッファが空
	tst.w	(F_HANDLE,a1)
	bpl	writebuf8		;ファイルはすでに作成されている

;最初の書き込みならファイルを作成する
	move.w	#$20,-(sp)		;ファイル属性(Archive)
	move.l	(F_NAMEPTR,a1),-(sp)
	pea.l	(TEMPFILPTR,a6)
	cmpa.l	(sp)+,a1
	bne	1f			;出力ファイルの作成
	DOS	_VERNUM			;テンポラリファイルの作成
	cmp.w	#$020F,d0
	bcc	3f
	.dc.w	$FF5a			;DOS _MAKETMP (～v2.03)
	bra	@f
3:	.dc.w	$FF8a			;DOS _MAKETMP (v2.15～)
	bra	@f
1:	DOS	_CREATE
@@:
	addq.l	#6,sp
	tst.l	d0
	bpl	writebuf1
	lea.l	(TEMPFILPTR,a6),a0
	cmpa.l	a0,a1			;ファイルオープンに失敗
	beq	tmpopenabort
	movea.l	(F_NAMEPTR,a1),a0
	bra	filopenabort

writebuf1:
	move.w	d0,(F_HANDLE,a1)
writebuf8:
	move.l	(F_PTROFST,a1),-(sp)	;バッファ内の有効データ長
	move.l	(F_BUFPTR,a1),-(sp)	;ファイルバッファへのポインタ
	move.w	(F_HANDLE,a1),-(sp)	;ファイルハンドル
	DOS	_WRITE
	lea.l	(10,sp),sp
	cmp.l	(F_PTROFST,a1),d0
	bne	devfulabort		;書き込みに失敗した
	add.l	d0,(F_TOPOFST,a1)
	clr.l	(F_PTROFST,a1)
	clr.l	(F_DATALEN,a1)
writebuf9:
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	テンポラリファイルのポインタを進める
;	in :d0.w=進めるバイト数
;	out:---
tempskip::
	ext.l	d0
tempskip1:
	add.l	(F_PTROFST+TEMPFILPTR,a6),d0
	cmp.l	(F_DATALEN+TEMPFILPTR,a6),d0
	bcs	tempskip9
	sub.l	(F_DATALEN+TEMPFILPTR,a6),d0
	movem.l	d0/a1,-(sp)
	lea.l	(TEMPFILPTR,a6),a1
	bsr	readbuf			;進めたポインタがバッファからはみだした
	movem.l	(sp)+,d1/a1
	exg.l	d0,d1
	subq.l	#1,d1
	bpl	tempskip1
tempskip9:
	move.l	d0,(F_PTROFST+TEMPFILPTR,a6)
	rts

;----------------------------------------------------------------
;	ファイルを修正する(書き込み専用)
fmodifyw::
	cmp.l	(F_TOPOFST,a1),d1
	blo	fmodifyw1
;バッファに残っているとき
	movem.l	d1/a1,-(sp)
	sub.l	(F_TOPOFST,a1),d1
	movea.l	(F_BUFPTR,a1),a1
	move.w	d0,(a1,d1.l)
	movem.l	(sp)+,d1/a1
	rts

;バッファに残っていないとき
fmodifyw1:
	move.l	d0,-(sp)

	clr.w	-(sp)
	move.l	d1,-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;修正位置まで移動
	addq.l	#8,sp

	pea.l	2.w
	pea.l	(6,sp)			;(修正データの位置)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_WRITE			;ファイルを修正
	lea.l	(10,sp),sp

	clr.w	-(sp)
	move.l	(F_TOPOFST,a1),-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;もとの位置まで戻る
	addq.l	#8,sp

	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	ファイルを修正する
;	in :a1=ファイルポインタへのポインタ
;	    d0.w=修正データ/d1.l=修正するファイル位置
;	out:---
fmodify::
	tst.w	(F_HANDLE,a1)
	bpl	fmodify1
	move.l	a1,-(sp)
	movea.l	(F_BUFPTR,a1),a1	;ファイルが作られていないのでバッファ内を修正する
	move.w	d0,(a1,d1.l)
	movea.l	(sp)+,a1
	rts

fmodify1:				;実際のファイル内を修正する
	move.l	d0,-(sp)
	clr.w	-(sp)
	move.l	d1,-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;修正位置まで移動
	addq.l	#8,sp

	pea.l	2.w
	pea.l	(6,sp)			;(修正データの位置)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_WRITE			;ファイルを修正
	lea.l	(10,sp),sp

	clr.w	-(sp)
	move.l	(F_TOPOFST,a1),d0
	add.l	(F_DATALEN,a1),d0
	move.l	d0,-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;もとの位置まで戻る
	addq.l	#8,sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	テンポラリファイルを削除する
;	in :---
;	out:---
tempdelete::
	movem.l	d0/a1,-(sp)
	lea.l	(TEMPFILPTR,a6),a1
	tst.w	(F_HANDLE,a1)
	bmi	tempdelete9		;ファイルが作られていないので削除の必要なし
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_CLOSE			;テンポラリファイルをクローズ
	addq.l	#2,sp
	move.l	(F_NAMEPTR,a1),-(sp)
	DOS	_DELETE			;クローズしたファイルを削除する
	addq.l	#4,sp
tempdelete9:
	movem.l	(sp)+,d0/a1
	rts

;----------------------------------------------------------------
;	ファイルバッファをフラッシュする
;	in :a1=ファイルポインタへのポインタ
;	out:---
fflush::
	tst.w	(F_HANDLE,a1)
	bpl	writebuf		;ファイルバッファをフラッシュ
	rts				;ファイルが作られていないのでフラッシュの必要なし

;----------------------------------------------------------------
;	ファイルの先頭にシークする
;	in :a1=ファイルポインタへのポインタ
;	out:---
frewind::
	move.l	d0,-(sp)
	tst.w	(F_HANDLE,a1)
	bmi	frewind1		;ファイルは実際には作られていない
	tst.l	(F_TOPOFST,a1)
	beq	frewind1		;読み込みファイルがバッファ内に収まっている
	clr.w	-(sp)
	clr.l	-(sp)
	move.w	(F_HANDLE,a1),-(sp)
	DOS	_SEEK			;ファイル先頭にシーク
	addq.l	#8,sp
	clr.l	(F_DATALEN,a1)		;バッファ内のデータを無効にする
frewind1:
	clr.l	(F_TOPOFST,a1)
	clr.l	(F_PTROFST,a1)
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	ソース行を1行読み込む
;	in :---
;	out:(LINEBUF～)=入力行
;	    d0.w=入力行が 0:ソースファイルから/1:インクルードファイルから/2:マクロ展開
;		 (ファイルが終了/エラーなら -1)
getline::
getline0:
	tst.b	(ISASMEND,a6)
	bne	getline9		;ソースファイルは終了済
	tst.w	(MACREPTNEST,a6)
	bne	getline2
	addq.l	#1,(LINENUM,a6)
	bsr	readline
	tst.w	d0
	bmi	@f

	tst.w	(INCLDNEST,a6)
	sne.b	d0
	neg.b	d0			;インクルードファイルからの読み込みならd0.w=1
	rts
@@:
	tst.w	(INCLDNEST,a6)
	bne	getline1
	st.b	(ISASMEND,a6)		;ソースファイルが終了した
getline9:
	moveq.l	#-1,d0
	rts

getline1:				;インクルードファイルが終了した
	bsr	closeincld
	cmpi.b	#1,(ASMPASS,a6)
	bne	getline0
	move.w	#T_INCLDEND,d0
	bsr	wrtobjd0w
	bra	getline0

getline2:				;マクロ定義行/rept繰り返し部の読み込み
	bsr	macexline
	tst.w	d0
	bmi	getline0
	moveq.l	#2,d0
	rts

;----------------------------------------------------------------
;	ファイルから1行読み込む
;	in :---
;	out:(LINEBUF～)=入力行 /d0.l=エラーなら負の数
readline:
	movem.l	d1-d3/a0-a2,-(sp)
	movea.l	(LINEBUFPTR,a6),a0
	move.l	a0,(LINEPTR,a6)
	movea.l	(INPFILPTR,a6),a1
	movea.l	(F_BUFPTR,a1),a2
	move.l	(F_PTROFST,a1),d3
	move.l	(F_DATALEN,a1),d2
	adda.l	d3,a2
	move.l	d2,d1
	sub.l	d3,d1
	addq.l	#1,d1
	move.w	#MAXLINELEN-2,d3
readline1:
	subq.l	#1,d1
	bhi	readline2
	bsr	readbuf			;バッファが空なので読み込む
	subq.l	#1,d0
	bmi	readline8
	move.l	(F_DATALEN,a1),d1
	move.l	d1,d2
	movea.l	(F_BUFPTR,a1),a2
readline2:
	move.b	(a2)+,d0
	cmp.b	#CR,d0
	beq	readline3		;CRは読み飛ばす
	cmp.b	#LF,d0
	beq	readline5
	cmp.b	#EOF,d0
	beq	readline4
	move.b	d0,(a0)+
readline3:
	dbra	d3,readline1
	bra	readline5		;1行が最大長を超えた

readline4:				;EOF
	cmp.w	#MAXLINELEN-2,d3
	beq	readline8		;行頭のEOFならそこでファイル終了
readline5:				;LF
	clr.b	(a0)
	moveq.l	#0,d0
readline9:
	subq.l	#1,d1
	sub.l	d1,d2
	move.l	d2,(F_PTROFST,a1)
	movem.l	(sp)+,d1-d3/a0-a2
	rts

readline8:				;エラー/ファイルの終了
	moveq.l	#-1,d0
	bra	readline9


;----------------------------------------------------------------
	.end
