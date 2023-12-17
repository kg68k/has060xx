;----------------------------------------------------------------
;	X68k High-speed Assembler
;		汎用サブルーチン/アボート処理
;		< misc.s >
;
;	$Id: misc.s,v 2.2  2016-01-01 12:00:00  M.Kamada Exp $
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2016  by M.Kamada
;----------------------------------------------------------------

	.include	doscall.mac
	.include	has.equ
	.include	register.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	DOSコール番号移動対策
getenv::
	link	a6,#0
	move.l	(16,a6),-(sp)
	move.l	(12,a6),-(sp)
	move.l	(8,a6),-(sp)
	DOS	_VERNUM
	cmp.w	#$020F,d0
	bcc	getenv1
	.dc.w	$FF53			;DOS _GETENV (～v2.03)
	bra	getenv9

getenv1:
	.dc.w	$FF83			;DOS _GETENV (v2.15～)
getenv9:
	unlk	a6
	rts


;----------------------------------------------------------------
;	ロケーションカウンタ操作
;----------------------------------------------------------------

;----------------------------------------------------------------
;	ロケーションカウンタをリセットする
;	in :---
;	out:---
resetlocctr::
	movem.l	d0/a0,-(sp)
	lea.l	(LOCCTRBUF,a6),a0
	move.w	#N_SECTIONS-1,d0
resetlocctr1:
	clr.l	(a0)+			;ロケーションカウンタをクリア
	dbra	d0,resetlocctr1
	move.w	#N_SECTIONS-1,d0
resetlocctr2:
	clr.l	(a0)+			;最適化ロケーションオフセットをクリア
	dbra	d0,resetlocctr2
	move.w	#N_SECTIONS-1,d0
resetlocctr3:
	clr.b	(a0)+			;orgセクション番号をクリア
	dbra	d0,resetlocctr3
	clr.l	(LOCATION,a6)
	clr.l	(LOCOFFSET,a6)
	clr.b	(ORGNUM,a6)
	move.b	#SECT_TEXT,(SECTION,a6)	;textセクションにする
	sf.b	(OFFSYMMOD,a6)
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;	セクションを切り替える
;	in :d0.b=切り替えるセクション番号
;	out:---
chgsection::
	movem.l	d0/a0,-(sp)
	move.b	(SECTION,a6),d0
	beq	chgsection1		;いままでoffsetセクションだった
	lea.l	(ORGNUMBUF,a6),a0
	move.b	(ORGNUM,a6),(-1,a0,d0.w)
	add.w	d0,d0
	add.w	d0,d0
	lea.l	(LOCCTRBUF,a6),a0
	move.l	(LOCATION,a6),(-4,a0,d0.w)	;旧セクションのカウンタを待避
	move.l	(LOCOFFSET,a6),(LOCOFFSETBUF-LOCCTRBUF-4,a0,d0.w)
chgsection1:
	move.w	(2,sp),d0
	move.b	d0,(SECTION,a6)
	beq	chgsection2		;これからoffsetセクションに変更する
	lea.l	(ORGNUMBUF,a6),a0
	move.b	(-1,a0,d0.w),(ORGNUM,a6)
	add.w	d0,d0
	add.w	d0,d0
	lea.l	(LOCCTRBUF,a6),a0
	move.l	(-4,a0,d0.w),(LOCATION,a6)	;新セクションのカウンタを取り出す
	move.l	(LOCOFFSETBUF-LOCCTRBUF-4,a0,d0.w),(LOCOFFSET,a6)
chgsection2:
	movem.l	(sp)+,d0/a0
	rts


;----------------------------------------------------------------
;	データサイズ
;----------------------------------------------------------------

;----------------------------------------------------------------
;	データ型のサイズを得る
;	in :d0.b=データ型
;	out:d0.l=データの占めるサイズ
getdtsize::
	and.l	#3,d0
	move.b	(dtsize_tbl,pc,d0.w),d0
	rts

dtsize_tbl:
	.dc.b	2,2,4,1
	.even


;----------------------------------------------------------------
;	文字列操作
;----------------------------------------------------------------

;----------------------------------------------------------------
;	スペース・タブをスキップする
;	in :a0=文字列へのポインタ
;	out:a0=文字列へのポインタ
skipspc::
	move.w	d0,-(sp)
skipspc1:
	move.b	(a0)+,d0
	beq	skipspc2
	cmp.b	#' ',d0
	bls	skipspc1
skipspc2:
	subq.l	#1,a0
	move.w	(sp)+,d0
skipspc9:
	rts

;----------------------------------------------------------------
;	文字列の長さを得る
;	in :a0=文字列へのポインタ
;	out:d1.l=文字列の長さ-1
strlen::
	move.l	a0,d1
@@:	tst.b	(a0)+
	bne	@b
	subq.l	#1,a0
	exg	d1,a0
	sub.l	a0,d1
	rts

;----------------------------------------------------------------
;	文字列をコピーする
;	in :a1=コピー元文字列へのポインタ/a0=コピー先文字列へのポインタ
;	out:a0=コピーした文字列の終了位置
strcpy::
	move.b	(a1)+,(a0)+
	bne	strcpy
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;	ドライブ名+パス名をコピーする
;	in :a1=コピー元文字列へのポインタ/a0=コピー先文字列へのポインタ
;	out:a0=コピーした文字列の終了位置
pathcpy::
	move.w	d0,-(sp)
	tst.b	(a1)
	beq	pathcpy9
pathcpy1:
	tst.b	(a1)
	beq	pathcpy5
	moveq.l	#0,d0
	move.b	(a1)+,d0
	move.b	d0,(a0)+
	bpl	pathcpy1
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	pathcpy2
	cmp.b	#$A0,d0
	bcc	pathcpy1		;半角カナの場合
  .else
	bra	pathcpy1		;EUC
  .endif
pathcpy2:
	lsl.w	#8,d0
	move.b	(a1)+,d0		;2バイト文字の2バイト目
	beq	pathcpy5
	move.b	d0,(a0)+
	bra	pathcpy1

pathcpy5:
	cmp.w	#'\',d0
	beq	pathcpy9
	cmp.w	#'/',d0
	beq	pathcpy9
	cmp.w	#':',d0
	beq	pathcpy9
pathcpy8:
	move.b	#'\',(a0)+		;パスの区切を追加する
pathcpy9:
	move.w	(sp)+,d0
	rts

;----------------------------------------------------------------
;	ドライブ+パス名からファイル名のみを取り出す
;	in :a0=ドライブ・パス名付きファイル名へのポインタ
;	out:a1=ファイル名のみへのポインタ
getfilename::
	move.w	d0,-(sp)
getfilename1:
	movea.l	a0,a1
	move.b	(a0)+,d0
	bmi	getfilename4
	beq	getfilename3
	cmp.b	#'.',d0
	beq	getfilename1
getfilename2:
	cmp.b	#':',d0
	beq	getfilename1
	cmp.b	#'\',d0
	beq	getfilename1
	cmp.b	#'/',d0
	beq	getfilename1
getfilename25:
	move.b	(a0)+,d0
	bmi	getfilename4
	bne	getfilename2
getfilename3:
	move.w	(sp)+,d0
	rts

getfilename4:
  .if EUCSRC=0
	cmp.b	#$E0,d0
	bcc	getfilename5
	cmp.b	#$A0,d0
	bcc	getfilename25		;半角カナの場合
  .else
	bra	getfilename25		;EUC
  .endif
getfilename5:
	tst.b	(a0)+
	bne	getfilename25
	bra	getfilename3


;----------------------------------------------------------------
;	致命的エラーによるアボート処理
;----------------------------------------------------------------

;----------------------------------------------------------------
;	使用メモリ量が足りるかをチェックする
;	in :---
;	out:---(メモリ不足ならプログラムを中断する)
memcheck::
	move.l	d0,-(sp)
	move.l	(MEMLIMIT,a6),d0
	cmp.l	(TEMPPTR,a6),d0
	bcs	nomemabort
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	メモリ不足
nomemabort::
	lea.l	(nomem_msg,pc),a0
	bra	abort

;----------------------------------------------------------------
;	書き込みに失敗
devfulabort::
	lea.l	(devful_msg,pc),a0
	bra	abort

;----------------------------------------------------------------
;	外部シンボルの数が32767を超えた
toomanyexabort::
	lea.l	(toomanyex_msg,pc),a0
	bra	abort

;----------------------------------------------------------------
;	テンポラリファイルオープンに失敗
tmpopenabort::
	lea.l	(temp_msg,pc),a0

;----------------------------------------------------------------
;	ファイルオープンに失敗(a0=ファイル名へのポインタ)
filopenabort::
	bsr	printmsg
	lea.l	(openerr_msg,pc),a0
abort:					;プログラム中断
	bsr	printmsg
	DOS	_ALLCLOSE		;全ファイルをクローズする
	lea.l	(beep_msg,pc),a0
	bsr	printmsg
	move.w	#1,-(sp)
	DOS	_EXIT2

nomem_msg:	mes	'Abort: メモリが不足しています'
		.dc.b	CRLF,0
devful_msg:	mes	'Abort: ディスクがいっぱいです'
		.dc.b	CRLF,0
toomanyex_msg:	mes	'Abort: 外部シンボルが多すぎます'
		.dc.b	CRLF,0
temp_msg:	mes	'テンポラリファイル'
		.dc.b	0
openerr_msg:	mes	'がオープンできません'
		.dc.b	CRLF,0
beep_msg::	.dc.b	BELL,0
	.even


;----------------------------------------------------------------
;	数値→文字列変換
;----------------------------------------------------------------

;----------------------------------------------------------------
;	d0.lを16進8桁の文字列に変換する
;	in :d0.l=変換する数値/a0=変換した文字列を格納するバッファ
;	out:a0=変換した文字列の最後を指す
convhex8::
	swap.w	d0
	bsr	convhex4
	swap.w	d0

;----------------------------------------------------------------
;	d0.wを16進4桁の文字列に変換する
;	in :d0.l=変換する数値/a0=変換した文字列を格納するバッファ
;	out:a0=変換した文字列の最後を指す
convhex4::
	rol.w	#8,d0
	bsr	convhex2
	rol.w	#8,d0

;----------------------------------------------------------------
;	d0.bを16進2桁の文字列に変換する
;	in :d0.l=変換する数値/a0=変換した文字列を格納するバッファ
;	out:a0=変換した文字列の最後を指す
convhex2::
	move.w	d0,-(sp)		;8
	lsr.w	#4,d0			;14
	bsr	convhex21		;18+61
	move.w	(sp),d0			;8
	bsr	convhex21		;18+61
	move.w	(sp)+,d0		;8
					;196
	rts

convhex21:
	and.w	#$0F,d0			;8
	add.w	#'0',d0			;8
	cmp.w	#'9',d0			;8
	bls	convhex22		;8|10
	addq.w	#7,d0			;8|0
convhex22:
	move.b	d0,(a0)+		;8
	rts				;16
					;61

;----------------------------------------------------------------
;	d0.lを10進文字列に変換する
;	in :d0.l=変換する数値/a0=変換した文字列を格納するバッファ
;	   :d1.w=変換桁数(負の数ならゼロサプレスしない/0なら左詰め)
;	out:a0=変換した文字列の最後を指す
convdec::
	movem.l	d0-d3/a1-a2,-(sp)
	moveq.l	#' ',d2
	tst.w	d1
	beq	convdec9		;左詰め
	bpl	convdec1
	moveq.l	#'0',d2
	neg.w	d1
convdec1:
	subq.w	#1,d1
	move.w	d1,d3
convdec2:				;変換桁数だけスペースを確保
	move.b	d2,(a0)+
	dbra	d3,convdec2
	link	a5,#-12
	lea.l	(-12,a5),a1
	clr.b	(a1)+
	bsr	convdecs		;左詰めで変換する
	movea.l	a0,a2
convdec3:				;右端から桁数だけ格納してゆく
	move.b	-(a1),d0
	beq	convdec4
	move.b	d0,-(a2)
	dbra	d1,convdec3
convdec4:
	unlk	a5
	movem.l	(sp)+,d0-d3/a1-a2
	rts

convdec9:				;左詰めの場合
	movea.l	a0,a1
	bsr	convdecs
	movea.l	a1,a0
	movem.l	(sp)+,d0-d3/a1-a2
	rts

convdecs:				;d0.lを(a1)から左詰めで変換する
	lea.l	(dectable,pc),a2
convdecs1:
	move.l	(a2)+,d2
	beq	convdecs9
	cmp.l	d0,d2
	bhi	convdecs1
convdecs2:
	moveq.l	#'0'-1,d3
convdecs3:
	addq.b	#1,d3
	sub.l	d2,d0
	bcc	convdecs3
	move.b	d3,(a1)+
	add.l	d2,d0
	move.l	(a2)+,d2
	bne	convdecs2
	rts

convdecs9:
	move.b	#'0',(a1)+
	rts

dectable:				;10進文字列変換用テーブル
	.dc.l	1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1,0


;----------------------------------------------------------------
;	メッセージ出力
;----------------------------------------------------------------

;----------------------------------------------------------------
;	標準エラー出力にメッセージを出力する
;	in :a0=表示文字列へのポインタ
;	out:---
printmsg::
	move.w	#STDERR,-(sp)
	pea.l	(a0)
	DOS	_FPUTS
	addq.l	#6,sp
	rts

;----------------------------------------------------------------
;	標準出力・PRNファイルにメッセージを出力する
;	in :a0=表示文字列へのポインタ
;	out:---
prnstdout::
	tst.b	(MAKEPRN,a6)
	beq	prnstdout1
	tst.b	(ISPRNSTDOUT,a6)
	bne	prnlout
	bsr	prnlout
prnstdout1:
	move.l	d0,-(sp)
	move.w	#STDOUT,-(sp)
	pea.l	(a0)
	DOS	_FPUTS
	addq.l	#6,sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;	PRNファイルにメッセージを出力する
;	in :a0=表示文字列へのポインタ
;	out:---
prnlout::
	tst.b	(NOPAGEFF,a6)
	bne	prnlout1
	bsr	prnpaging
prnlout1:
	move.l	d0,-(sp)
	move.w	(PRNHANDLE,a6),-(sp)
	pea.l	(a0)
	DOS	_FPUTS
	addq.l	#6,sp
	tst.l	d0
	beq	prnlout9
prnlout2:
	move.l	(sp)+,d0
	rts

prnlout9:
	tst.b	(a0)
	beq	prnlout2
	bra	devfulabort

;----------------------------------------------------------------
;	PRNファイルの改ページを行なう
;	in :d0.w=改ページのみなら0/メインページを増やすなら1/シンボルページなら-1
;	out:---
prnnextpage::
	tst.w	d0
	beq	prnnextpage9
	bmi	prnnextpage1
	addq.w	#1,(PRNMPAGE,a6)
	bra	prnnextpage2

prnnextpage1:
	clr.w	(PRNMPAGE,a6)
prnnextpage2:
	clr.w	(PRNSPAGE,a6)
prnnextpage9:
	move.w	#1,(PRNCOUNT,a6)
	rts

;----------------------------------------------------------------
;	必要ならPRNファイルのページングを行なう
;	in :---
;	out:---
prnpaging:
	subq.w	#1,(PRNCOUNT,a6)
	bhi	prnpaging9
	move.l	a0,-(sp)
	lea.l	(pageff_msg,pc),a0
	bsr	prnlout1		;改ページコードを出力
	movea.l	(sp)+,a0
prnpaging1::
	link	a5,#-80
	movem.l	d0-d1/a0-a1,-(sp)
	addq.w	#1,(PRNSPAGE,a6)
	move.w	(PRNPAGEL,a6),d0
	subq.w	#4+1,d0			;タイトル行が2行に増えた分も差し引く
	move.w	d0,(PRNCOUNT,a6)
	lea.l	(title_msg,pc),a0
	bsr	prnlout1		;タイトル行を出力
	movea.l	(PRNTITLE,a6),a1
	bsr	tfrtitle
	lea.l	(PRNDATE,a6),a1
	bsr	strcpy
	lea.l	(crlf_msg,pc),a1
	bsr	strcpy
	lea.l	(-80,a5),a0
	bsr	prnlout1		;タイトル文字列・日時を表示

	tst.b	(NOPAGEFF,a6)		;ページングしない場合は
	bne	prnpaging4		;サブタイトル文字列・ページ数を表示しない

	movea.l	(PRNSUBTTL,a6),a1
	bsr	tfrtitle
	move.w	(PRNMPAGE,a6),d0
	beq	prnpaging2
	lea.l	(page_msg,pc),a1
	bsr	strcpy
	ext.l	d0
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	move.b	#'-',(a0)+
	bra	prnpaging3

prnpaging2
	lea.l	(sym_msg,pc),a1
	bsr	strcpy
prnpaging3:
	move.w	(PRNSPAGE,a6),d0
	ext.l	d0
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	lea.l	(crlf_msg,pc),a1
	bsr	strcpy
	lea.l	(-80,a5),a0
	bsr	prnlout1		;サブタイトル文字列・ページ数を表示
	lea.l	(crlf_msg,pc),a0
	bsr	prnlout1
	cmpi.w	#1,(PRNSPAGE,a6)
	bne	prnpaging4
	tst.w	(PRNMPAGE,a6)
	beq	prnpaging4
	bsr	prnlout1
	subq.w	#1,(PRNCOUNT,a6)
prnpaging4:
	movem.l	(sp)+,d0-d1/a0-a1
	unlk	a5
prnpaging9:
	rts

tfrtitle:
	lea.l	(-80,a5),a0
	moveq.l	#56-1,d0
tfrtitle1:
	move.b	(a1)+,(a0)+
	dbeq	d0,tfrtitle1
	bne	tfrtitle9
	subq.l	#1,a0
tfrtitle2:
	move.b	#' ',(a0)+
	dbra	d0,tfrtitle2
tfrtitle9:
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts

pageff_msg::	.dc.b	FF,0
page_msg:	.dc.b	'Page ',0
sym_msg:	.dc.b	'Symbols-',0
	.even

;----------------------------------------------------------------
;	PRNファイルページング用の日時文字列を作成する
;	in :---
;	out:---
makeprndate::
	DOS	_GETDATE
	move.l	d0,(ASSEMBLEDATE,a6)	;(曜日(0=日)<<16)+((西暦年-1980)<<9)+(月<<5)+日
	DOS	_GETTIM2
	move.l	d0,(ASSEMBLETIM2,a6)	;(時<<16)+(分<<8)+秒

	lea.l	(PRNDATE,a6),a0

	move.l	(ASSEMBLEDATE,a6),d2	;00000000_00000WWW_YYYYYYYM_MMMDDDDD

	rol.w	#7,d2
	moveq.l	#$7F,d0
	and.w	d2,d0
	add.w	#1980,d0		;西暦年
	bsr	makeprndec4

	move.b	#'-',(a0)+

	rol.w	#4,d2
	moveq.l	#$0F,d0
	and.w	d2,d0			;月
	bsr	makeprndec

	move.b	#'-',(a0)+

	rol.w	#5,d2
	moveq.l	#$1F,d0
	and.w	d2,d0			;日
	bsr	makeprndec

	move.b	#' ',(a0)+

	move.l	(ASSEMBLETIM2,a6),d2	;00000000_000HHHHH_00MMMMMM_00SSSSSS

	swap.w	d2
	moveq.l	#$1F,d0
	and.w	d2,d0			;時
	bsr	makeprndec

	move.b	#':',(a0)+

	swap.w	d2
	rol.w	#8,d2
	moveq.l	#$3F,d0
	and.w	d2,d0			;分
	bsr	makeprndec

	move.b	#':',(a0)+

	rol.w	#8,d2
	moveq.l	#$3F,d0
	and.w	d2,d0			;秒
	bsr	makeprndec

	clr.b	(a0)
	rts

makeprndec:				;d0.wを10進2桁の文字列に変換する
	ext.l	d0
	moveq.l	#-2,d1			;(2桁でゼロサプレスしない)
	bra	convdec

makeprndec4:				;d0.wを10進4桁の文字列に変換する
	ext.l	d0
	moveq.l	#-4,d1			;(4桁でゼロサプレスしない)
	bra	convdec

crlf_msg:	.dc.b	CR,LF,0
	.even

;----------------------------------------------------------------
;	浮動小数点データ長を得る
;	in :d0.b=データ型
;	out:d1.w=データ長(ロングワードで)-1
getfplen::
	ext.w	d0
	bpl	getfplen1
	moveq.l	#SZ_EXTEND,d0		;サイズ省略時は.x
getfplen1:
	moveq.l	#0,d1
	move.b	(fsize_tbl,pc,d0.w),d1
	rts

fsize_tbl:
	.dc.b	-1,-1,-1		;(.b/.w/.l)
	.dc.b	(1-1),(2-1),(3-1),(3-1)	;.s/.d/.x/.p
	.even


;----------------------------------------------------------------
	.end
