;----------------------------------------------------------------
;	X68k High-speed Assembler
;		メインルーチン
;		< main.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2023  by M.Kamada
;----------------------------------------------------------------

	.include	DOSCALL.MAC
	.include	has.equ
	.include	symbol.equ
	.include	register.equ
	.include	cputype.equ
	.include	error2.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	メインプログラム
;----------------------------------------------------------------
asmmain::
	move.l	#STACKBTM-asmmain,d0
	lea.l	(asmmain,pc,d0.l),sp	;lea.l (STACKBTM,pc),sp
	move.l	#WORKBEGIN-asmmain,d0
	lea.l	(asmmain,pc,d0.l),a6	;lea.l (WORKBEGIN,pc),a6
	bsr	meminit			;メモリ領域の確保
	bsr	workinit		;ワークエリアの初期化
	bsr	defressym		;予約済みシンボルの初期化
	bsr	cpuinit			;CPUモードの初期化
	bsr	makeprndate		;日時文字列の作成
	bsr	docmdline		;コマンドラインの解釈
	bsr	predefinesymbol		;プレデファインシンボルの定義
	tst.b	(DISPTITLE,a6)
	beq	asmmain0
	lea.l	(title_msg,pc),a0
	bsr	printmsg
asmmain0:
	lea.l	(SOURCEPTR,a6),a0
	move.l	a0,(INPFILPTR,a6)
	movea.l	(SOURCEFILE,a6),a0
	bsr	readopen		;ソースファイルをオープンする
	tst.l	d0
	bmi	filopenabort
	tst.b	(MAKEPRN,a6)
	beq	asmmain1
	movea.l	(PRNFILE,a6),a0
	bsr	prnopen			;PRNファイルをオープンする
	move.w	d0,(PRNHANDLE,a6)
asmmain1:
	bsr	asmpass1		;パス1
	bsr	asmpass2		;パス2
	bsrl	asmpass3,d0		;パス3
	bsr	tempdelete		;テンポラリファイルの削除
	tst.w	(NUMOFERR,a6)
	beq	asmmain2
	move.w	#1,-(sp)		;エラーがあった場合の終了コード
	move.l	(OBJFILE,a6),-(sp)
	DOS	_DELETE			;オブジェクトファイルを削除する
	addq.l	#4,sp
	lea.l	(beep_msg,pc),a0
	bsr	printmsg		;ビープ音を鳴らす
	lea.l	(LINEBUF,a6),a0
	lea.l	(fatal_msg1,pc),a1
	bsr	strcpy
	move.w	(NUMOFERR,a6),d0
	ext.l	d0
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	lea.l	(fatal_msg2,pc),a1
	bsr	strcpy
	clr.b	(a0)
	lea.l	(LINEBUF,a6),a0
	bra	asmmain3

asmmain2:
	clr.w	-(sp)			;エラーがなかった場合の終了コード
	lea.l	(no_msg,pc),a0
	tst.b	(DISPTITLE,a6)
	beq	asmmain4
asmmain3:
	bsr	printmsg
asmmain4:
	tst.b	(MAKEPRN,a6)
	beq	asmmain6
	tst.b	(ISPRNSTDOUT,a6)
	bne	asmmain6
	bsr	prnlout
	tst.b	(NOPAGEFF,a6)
	bne	asmmain5
	st.b	(NOPAGEFF,a6)
	lea.l	(pageff_msg,pc),a0
	bsr	prnlout
asmmain5:
	move.w	(PRNHANDLE,a6),-(sp)
	DOS	_CLOSE			;PRNファイルのクローズ
	addq.l	#2,sp
asmmain6:
	st.b	(NOPAGEFF,a6)
	tst.b	(MAKESYM,a6)
	beq	asmmain9
	move.l	(SYMFILE,a6),d1
	beq	asmmain8		;ファイル名省略→標準出力へ
	movea.l	d1,a0
	bsr	prnopen			;シンボルファイルをオープンする
	move.w	d0,(PRNHANDLE,a6)
	movea.l	(SOURCEFILE,a6),a0
	bsr	getfilename
	movea.l	a1,a0
	bsr	prnlout
	lea.l	(main_crlf_msg,pc),a0
	bsr	prnlout
	bsrl	makesymfile,d0		;シンボルファイルの作成
	move.w	d0,-(sp)
	DOS	_CLOSE			;シンボルファイルのクローズ
	addq.l	#2,sp
	bra	asmmain9

asmmain8:
	move.w	#STDOUT,(PRNHANDLE,a6)

	bsrl	makesymfile,d0		;シンボルファイルを標準出力へ出力
asmmain9:
	DOS	_EXIT2


;----------------------------------------------------------------
;	アセンブラの表示メッセージ
;----------------------------------------------------------------
main_crlf_msg:
	.dc.b	CRLF,0

title_msg::
	.dc.b	'X68k High-speed Assembler v',version,' ',copyright,CRLF,0

usage_msg:
  .if 91<=verno060
	mes	'使用法: has060 [スイッチ] ファイル名'
  .else
	mes	'使用法: as [スイッチ] ファイル名'
  .endif
	.dc.b	CRLF
	.dc.b	TAB,'-1',TAB,TAB
	mes	'絶対ロング→PC間接(-b1と-eを伴う)'
	.dc.b	CRLF
	.dc.b	TAB,'-8',TAB,TAB
	mes	'シンボルの識別長を8バイトにする'
	.dc.b	CRLF
;-a 絶対ショートアドレス形式対応(-c2時のみ有効)
	.dc.b	TAB,'-b[n]',TAB,TAB
	mes	'PC間接→絶対ロング(0=[禁止],[1]=68000,2=MEM,3=1+2,4=ALL,5=1+4)'
	.dc.b	CRLF
	.dc.b	TAB,'-c[n]',TAB,TAB
	mes	'最適化(0=禁止(-k1を伴う),1=(d,An)を禁止,[2]=v2互換,3=[v3互換],4=許可)'
	.dc.b	CRLF
	.dc.b	TAB,'-c<mnemonic>',TAB
	mes	'software emulationの命令を展開する(FScc/MOVEP)'
	.dc.b	CRLF
	.dc.b	TAB,'-d',TAB,TAB
	mes	'すべてのシンボルを外部定義にする'
	.dc.b	CRLF
	.dc.b	TAB,'-e',TAB,TAB
	mes	'外部参照オフセットのデフォルトをロングワードにする'
	.dc.b	CRLF
	.dc.b	TAB,'-f[f,m,w,p,c]',TAB
	mes	'リストファイルのフォーマット'
	.dc.b	CRLF
	.dc.b	TAB,TAB,TAB
	mes	'(改ページ[1],マクロ展開[0],幅[136],ページ行数[58],コード幅[16])'
	.dc.b	CRLF
	.dc.b	TAB,'-g',TAB,TAB
	mes	'SCD用デバッグ情報の出力'
	.dc.b	CRLF
	.dc.b	TAB,'-i <path>',TAB
	mes	'インクルードパス指定'
	.dc.b	CRLF
	.dc.b	TAB,'-j[n]',TAB,TAB
	mes	'シンボルの上書き禁止条件の強化(bit0:[1]=SET,bit1:[1]=OFFSYM)'
	.dc.b	CRLF
	.dc.b	TAB,'-k[n]',TAB,TAB
	mes	'68060のエラッタ対策(0=[する](-nは無効),[1]=しない)'
	.dc.b	CRLF
	.dc.b	TAB,'-l',TAB,TAB
	mes	'起動時にタイトルを表示する'
	.dc.b	CRLF
	.dc.b	TAB,'-m <680x0|5x00>',TAB
	mes	'アセンブル対象CPUの指定([68000]～68060/5200～5400)'
	.dc.b	CRLF
	.dc.b	TAB,'-n',TAB,TAB
	mes	'パス1で確定できないサイズの最適化を省略する(-k1を伴う)'
	.dc.b	CRLF
	.dc.b	TAB,'-o <name>',TAB
	mes	'オブジェクトファイル名'
	.dc.b	CRLF
	.dc.b	TAB,'-p [file]',TAB
	mes	'リストファイル作成'
	.dc.b	CRLF
;-q クイックイミディエイト形式への変換禁止(-c2時のみ有効)
;-r 相対セクション命令の許可(廃止)
	.dc.b	TAB,'-s <n>',TAB,TAB
	mes	'数字ローカルラベルの最大桁数の指定(1～[4])'
	.dc.b	CRLF
	.dc.b	TAB,'-s <symbol>[=n]',TAB
	mes	'シンボルの定義'
	.dc.b	CRLF
	.dc.b	TAB,'-t <path>',TAB
	mes	'テンポラリパス指定'
	.dc.b	CRLF
	.dc.b	TAB,'-u',TAB,TAB
	mes	'未定義シンボルを外部参照にする'
	.dc.b	CRLF
	.dc.b	TAB,'-w[n]',TAB,TAB
	mes	'ワーニングレベルの指定(0=全抑制,1,[2],3,4=[全通知])'
	.dc.b	CRLF
	.dc.b	TAB,'-x [file]',TAB
	mes	'シンボルの出力'
	.dc.b	CRLF
	.dc.b	TAB,'-y[n]',TAB,TAB
	mes	'プレデファインシンボル(0=[禁止],[1]=許可)'
	.dc.b	CRLF
;-z HAS拡張機能のワーニング禁止(廃止)
  .if 91<=verno060
	mes	'    環境変数 HAS の内容がコマンドラインの手前(-iは後ろ)に挿入されます'
  .else
	mes	'    環境変数 HAS の内容がコマンドラインの手前に挿入されます'
  .endif
	.dc.b	CRLF
	mes	'    環境変数 HAS の先頭が '
	.dc.b	"'*'"
	mes	' のとき '
	.dc.b	"'/'"
	mes	' をスイッチと見なしません'
	.dc.b	CRLF
	.dc.b	0

no_msg:		mes	'エラーはありません'
		.dc.b	CRLF
		.dc.b	0
fatal_msg1:	mes	'エラーが '
		.dc.b	0
fatal_msg2:	mes	' 個ありました．アセンブルを中止します'
		.dc.b	CRLF
		.dc.b	0
env_has:	.dc.b	'HAS',0		;コマンドラインに追加する環境変数名
nulstr:		.dc.b	0
	.even


;----------------------------------------------------------------
;	メモリ領域の確保
;----------------------------------------------------------------
meminit:					;lea.l $10(a0),a0
	move.l	#STACKBTM-asmmain+$F0,-(sp)	;suba.l a0,a1
	pea.l	($10,a0)			;movem.l a0-a1,-(sp)
	DOS	_SETBLOCK		;メモリブロックを解放
	addq.l	#8,sp
	tst.l	d0
	bmi	nomemabort
;CMDLINEPTR(a6)の更新を_SETBLOCKのエラーチェック後に行う
	addq.l	#1,a2
	move.l	a2,(CMDLINEPTR,a6)	;コマンドライン文字列へのポインタ
  .if 89<=verno060
	moveq.l	#1,d0
	.cpu	68020
	and.b	*-3(pc,d0.w*2),d0	;0=68000,1=68020以上
	.cpu	68000
	beq	meminit2
	move.w	#$8000,d1		;_SYS_STATのバージョンを確認する
	moveq.l	#$AC,d0			;_SYS_STAT
	trap	#15
	cmpa.l	#'060T',a1
	beq	meminit3		;060turboのとき
meminit2:
  .endif
	move.l	#$FFFFFF,-(sp)
	DOS	_MALLOC			;メモリを最大限確保
	addq.l	#4,sp
	tst.l	d0
	bpl	meminit1		;(こんなことはありえないが…)
	and.l	#$FFFFFF,d0
	move.l	d0,-(sp)
	DOS	_MALLOC			;あるだけのメモリを確保
	addq.l	#4,sp
	tst.l	d0
	bmi	nomemabort		;メモリが全く確保出来ない
meminit1:
	move.l	d0,(MEMPTR,a6)		;未使用領域の開始アドレス
	movea.l	d0,a0
	move.l	(-8,a0),d0		;	     終了アドレス
	sub.l	#$400,d0
	move.l	d0,(MEMLIMIT,a6)
	rts

  .if 89<=verno060
;060turboのとき16MBを超えるメモリを確保できる
meminit3:
	move.l	#$7FFFFFFF,-(sp)
	DOS	_MALLOC3
	addq.l	#4,sp
	tst.l	d0
	bpl	meminit1
	and.l	#$7FFFFFFF,d0
	move.l	d0,-(sp)
	DOS	_MALLOC3
	addq.l	#4,sp
	tst.l	d0
	bmi	nomemabort
	bra	meminit1
  .endif


;----------------------------------------------------------------
;	ワークエリアの初期化
;----------------------------------------------------------------
workinit:
	lea.l	(WORKCLRST,a6),a0
	move.w	#(WORKSIZE-WORKCLRST)/2-1,d0
workinit1:
	clr.w	(a0)+
	dbra	d0,workinit1
	move.l	(MEMPTR,a6),(TEMPPTR,a6)

	clr.l	(INCLUDEPATH,a6)
  .if 90<=verno060
	clr.l	(ENVINCLUDE,a6)
  .endif
	lea.l	(nulstr,pc),a0
	move.l	a0,(TEMPPATH,a6)
	move.l	a0,(PRNTITLE,a6)
	move.l	a0,(PRNSUBTTL,a6)

	move.w	#136,(PRNWIDTH,a6)
	move.w	#58,(PRNPAGEL,a6)
	move.w	#16,(PRNCODEWIDTH,a6)
	move.w	#1,(PRNMPAGE,a6)
	lea.l	(REQFILPTR,a6),a0
	move.l	a0,(REQFILEND,a6)
	move.l	#6,(NUMOFSECT,a6)
	move.b	#-1,(WARNLEVEL,a6)

	move.w	#1<<9,(FPCPID,a6)

	move.w	#4,(LOCALLENMAX,a6)
	move.w	#10000,(LOCALNUMMAX,a6)

	move.l	#SYMHASHTBL,d0
	lea.l	(a6,d0.l),a0
	move.l	a0,(SYMHASHPTR,a6)
	move.l	#CMDHASHTBL,d0
	lea.l	(a6,d0.l),a0
	move.l	a0,(CMDHASHPTR,a6)

	clr.w	(SYMTBLCOUNT,a6)
	lea.l	(SYMTBLBEGIN,a6),a0
	clr.l	(a0)
	move.l	a0,(SYMTBLCURBGN,a6)

	move.l	(TEMPPTR,a6),d0
	doeven	d0			;ロングワード境界に合わせる
	move.l	(MEMLIMIT,a6),d1
	sub.l	d0,d1			;d1=未使用領域のサイズ
	move.l	d1,d2
;	lsr.l	#2,d2			;(未使用領域の1/4)
	lsr.l	#1,d2			;(未使用領域の1/2)
	sub.l	d2,d1
	and.l	#$FFFFE000,d1		;d1=ファイルバッファに使用するメモリ
	cmp.l	#8192,d1
	bcc	workinit2
	move.l	#8192,d1		;メモリが不足している場合に最低限確保するバッファ
workinit2:
	lsr.l	#2,d1			;1/4
	move.l	d1,d2
	lsr.l	#1,d1			;1/8
	add.l	d1,d2			;ファイルバッファの3/8をソース用に充てる
	move.l	d0,(F_BUFPTR+SOURCEPTR,a6)	;ソースファイルバッファが決定
	move.l	d2,(F_BUFLEN+SOURCEPTR,a6)
	add.l	d2,d0
	move.l	d0,(F_BUFPTR+TEMPFILPTR,a6)	;テンポラリファイルバッファが決定
	move.l	d2,(F_BUFLEN+TEMPFILPTR,a6)
	add.l	d2,d0
	move.l	d0,(F_BUFPTR+INCLDPTR,a6)	;インクルードファイルバッファが決定
	move.l	d1,(F_BUFLEN+INCLDPTR,a6)
	add.l	d1,d0
	move.l	d0,(F_BUFPTR+OBJFILPTR,a6)	;オブジェクトファイルバッファが決定
	move.l	d1,(F_BUFLEN+OBJFILPTR,a6)
	add.l	d1,d0
	move.l	d0,(TEMPPTR,a6)		;それ以降がシンボル名・マクロ登録用ワーク

	bsr	memcheck
	rts


;----------------------------------------------------------------
;	プレデファインシンボルの初期化
;----------------------------------------------------------------
predefinesymbol:
	tst.b	(PREDEFINE,a6)
	beq	predefinesymbol99

	lea.l	(symbol_cpu,pc),a0
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defstrsymbol		;新しく登録する
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;シンボルのタイプ
	bne	predefinesymbol1	;定義できなかった(念のため)
	move.l	a1,(CPUSYMBOL,a6)
	move.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)	;プレデファインシンボル
	clr.b	(SYM_SECTION,a1)	;セクション番号
	move.b	(CPUTYPE2,a6),d0
	beq	predefinesymbol00
	movea.l	#5200,a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(5300-5200,a0),a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(5400-5300,a0),a0
	bra	predefinesymbol0

predefinesymbol00:
	move.b	(CPUTYPE,a6),d0		;CPUTYPEから初期値を決定する
	movea.l	#68000,a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(68010-68000,a0),a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(68020-68010,a0),a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(68030-68020,a0),a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(68040-68030,a0),a0
	lsr.b	#1,d0
	bcs	predefinesymbol0
	lea.l	(68060-68040,a0),a0
predefinesymbol0:
	move.l	a0,(SYM_VALUE,a1)	;CPU
	move.l	a0,(STARTCPU,a6)
predefinesymbol1:

	pea.l	(symbol_date,pc)
	moveq.l	#$07,d0
	and.w	(ASSEMBLEDATE,a6),d0	;|........|........|........|.....www|
	lsl.w	#5,d0			;|........|........|........|www.....|
	swap.w	d0			;|........|www.....|........|........|
	move.w	(ASSEMBLEDATE+2,a6),d0	;|........|www.....|yyyyyyym|mmmddddd|
	add.l	#1980<<9,d0		;|........|wwwYYYYY|YYYYYYYm|mmmddddd|
	lsl.l	#7,d0			;|.wwwYYYY|YYYYYYYY|mmmmdddd|d.......|
	lsr.w	#4,d0			;|.wwwYYYY|YYYYYYYY|....mmmm|ddddd...|
	lsr.b	#3,d0			;|.wwwYYYY|YYYYYYYY|....mmmm|...ddddd|
	move.l	d0,-(sp)
	bsr	def_predefinesymbol
	pea.l	(symbol_time,pc)
	move.l	(ASSEMBLETIM2,a6),-(sp)
	bsr	def_predefinesymbol
	lea.l	(8+8,sp),sp

	pea.l	(symbol_has,pc)
	pea.l	(verno).w		;309
	bsr	def_predefinesymbol
	pea.l	(symbol_has060,pc)
	pea.l	(verno060).w		;69～
	bsr	def_predefinesymbol
	lea.l	(8+8,sp),sp

predefinesymbol99:
	rts

;<4(sp).l:値
;<8(sp).l:文字列
def_predefinesymbol:
	movea.l	(8,sp),a0		;文字列
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defstrsymbol		;新しく登録する
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;シンボルのタイプ
	bne	def_predefinesymbol_9	;定義できなかった(念のため)
	move.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)	;プレデファインシンボル
	clr.b	(SYM_SECTION,a1)	;セクション番号
	move.l	(4,sp),(SYM_VALUE,a1)	;値
def_predefinesymbol_9:
	rts

symbol_cpu:	.dc.b	'CPU',0
symbol_date:	.dc.b	'__DATE__',0
symbol_time:	.dc.b	'__TIME__',0
symbol_has:	.dc.b	'__HAS__',0
symbol_has060:	.dc.b	'__HAS060__',0
	.even


;----------------------------------------------------------------
;	CPUモードの初期化
;----------------------------------------------------------------
cpuinit:
  .if 89<=verno060
	move.l	#68000,(ICPUNUMBER,a6)
	move.w	#C000,(ICPUTYPE,a6)
	rts
  .else
	sf.b	(F43GTEST,a6)
cpuinit1:
	move.l	#~~cpu_68000-cpuinit1,d0
	jmp	(cpuinit1,pc,d0.l)
  .endif


;----------------------------------------------------------------
;	コマンドラインの解釈を行う
;----------------------------------------------------------------
docmdline:
	movea.l	(CMDLINEPTR,a6),a0
	movea.l	(TEMPPTR,a6),a1
;環境変数HASをコマンドラインの手前に入れる
	clr.b	(a1)
	move.l	a1,-(sp)
	clr.l	-(sp)
	pea.l	(env_has,pc)
	bsr	getenv
	lea.l	(12,sp),sp
	cmpi.b	#'*',(a1)
	bne	docmdline1
	move.b	#' ',(a1)
	st.b	(SWITCHCHAR,a6)		;環境変数の先頭に'*'があったら'/'をスイッチにしない
docmdline1:
	tst.b	(a1)+
	bne	docmdline1
	move.b	#' ',(-1,a1)		;環境変数HASの後ろにコマンドラインをつなぐ
  .if 90<=verno060
	move.l	a1,(ENVBOUNDARY,a6)
  .endif
docmdline2:
	move.b	(a0)+,(a1)+
	bne	docmdline2
	movea.l	(TEMPPTR,a6),a0
	move.l	a1,(TEMPPTR,a6)
docmdline3:
	bsr	optionsw
	tst.b	d0
	beq	docmdline10
	subq.l	#1,a0
	bsr	getcmdstring		;ソースファイル名を得る
	move.l	(SOURCEFILE,a6),d0
	beq	docmdline39
	cmp.l	(PRNFILE,a6),d0
	beq	docmdline39
	cmp.l	(SYMFILE,a6),d0
	bne	usage			;ソースファイル名が2つある
docmdline39:
	move.l	a1,(SOURCEFILE,a6)
	bra	docmdline3

docmdline10:				;コマンドラインが終了
  .if 90<=verno060
	lea.l	(INCLUDEPATH,a6),a1
	bra	docmdline102
docmdline101:
	movea.l	d0,a1
docmdline102:
	move.l	(a1),d0
	bne	docmdline101
	move.l	(ENVINCLUDE,a6),(a1)	;ENVINCLUDEをINCLUDEPATHの後ろに繋ぐ
  .endif
	move.l	(SOURCEFILE,a6),d2
	beq	usage			;ソースファイルの指定がないので使用法を表示
	movea.l	d2,a0
	cmp.l	(PRNFILE,a6),d2
	bne	docmdline11
	clr.l	(PRNFILE,a6)		;-p [file]の形でソースファイルが指定された
docmdline11:
	cmp.l	(SYMFILE,a6),d2
	bne	docmdline12
	clr.l	(SYMFILE,a6)		;-x [file]の形でソースファイルが指定された
docmdline12:
	bsr	getfilename
docmdline122:
	move.b	(a1)+,d0
	beq	docmdline13
	cmp.b	#'.',d0
	bne	docmdline122
	bra	docmdline14

docmdline13:				;拡張子が省略された場合
	movea.l	d2,a1
	movea.l	(TEMPPTR,a6),a0
	move.l	a0,(SOURCEFILE,a6)
	clr.w	-(sp)			;'r'
	pea.l	(a0)
	bsr	strcpy
	move.b	#'.',(a0)+
	movea.l	a0,a2
	move.b	#'h',(a0)+
	move.b	#'a',(a0)+
	move.b	#'s',(a0)+
	clr.b	(a0)+
	DOS	_OPEN			;拡張子'.has'でオープンしてみる
	addq.l	#6,sp
	tst.l	d0
	bmi	docmdline135
	move.w	d0,-(sp)
	DOS	_CLOSE			;ファイルがあったのでクローズ
	addq.l	#2,sp
	bra	docmdline139

docmdline135:				;'.has'のファイルがないので拡張子は'.s'
	move.b	#'s',(a2)+
	clr.b	(a2)+
	movea.l	a2,a0
docmdline139
	move.l	a0,(TEMPPTR,a6)
docmdline14:
	movea.l	(SOURCEFILE,a6),a0
	bsr	getfilename		;a1=ソースファイル名へのポインタ
	lea.l	(SOURCENAME,a6),a0
	bsr	tfrfilename
	tst.l	(OBJFILE,a6)
	bne	docmdline15
	movea.l	(TEMPPTR,a6),a0		;オブジェクトファイル名の指定がない
	move.l	a0,(OBJFILE,a6)
	bsr	tfrfilename
	move.b	#'.',(a0)+
	move.b	#'o',(a0)+
	clr.b	(a0)+
	move.l	a0,(TEMPPTR,a6)
docmdline15:
	tst.l	(PRNFILE,a6)
	bne	docmdline99
	movea.l	(TEMPPTR,a6),a0		;PRNファイル名の指定がない
	move.l	a0,(PRNFILE,a6)
	bsr	tfrfilename
	move.b	#'.',(a0)+
	move.b	#'p',(a0)+
	move.b	#'r',(a0)+
	move.b	#'n',(a0)+
	clr.b	(a0)+
	move.l	a0,(TEMPPTR,a6)
docmdline99:
	tst.b	(COMPATMODE,a6)
	beq	docmdline999
	move.b	(COMPATSWA,a6),d0	;HAS v2.x互換モードの場合,-a/-qスイッチを認識する
	not.b	d0
	move.b	d0,(NOABSSHORT,a6)
	move.b	(COMPATSWQ,a6),(NOQUICK,a6)
docmdline999:
	rts

;----------------------------------------------------------------
;	オプションスイッチの処理
optionsw:
	bsr	skipspc
	move.b	(a0)+,d0
	cmp.b	#'-',d0
	beq	optionsw1
	tst.b	(SWITCHCHAR,a6)
	bne	optionsw0		;'/'をスイッチに使用しない場合
	cmp.b	#'/',d0
	beq	optionsw1
optionsw0:
	rts

optionsw1:
	move.b	(a0),d0
	cmp.b	#' ',d0
	bls	optionsw
	addq.l	#1,a0
	lea.l	(opt_switch,pc),a1
	moveq.l	#-1,d2
	cmp.b	#'Z',d0
	bhi	optionsw2
	cmp.b	#'A',d0
	bcs	optionsw2
	or.b	#$20,d0			;小文字化
optionsw2:
	move.b	(a1)+,d1
	beq	usage			;該当するオプションスイッチがない
	addq.w	#1,d2
	cmp.b	d1,d0
	bne	optionsw2
	add.w	d2,d2
	move.w	(optjp_tbl,pc,d2.w),d2
	jsr	(optjp_tbl,pc,d2.w)
	bra	optionsw1

;----------------------------------------------------------------
;	オプションスイッチのジャンプテーブル
opt_switch:
	.dc.b	'toipnwud8msxaqflzregcb1ykj',0
	.even
optjp_tbl:
	.dc.w	option_t-optjp_tbl,option_o-optjp_tbl
	.dc.w	option_i-optjp_tbl,option_p-optjp_tbl
	.dc.w	option_n-optjp_tbl,option_w-optjp_tbl
	.dc.w	option_u-optjp_tbl,option_d-optjp_tbl
	.dc.w	option_8-optjp_tbl,option_m-optjp_tbl
	.dc.w	option_s-optjp_tbl,option_x-optjp_tbl
	.dc.w	option_a-optjp_tbl,option_q-optjp_tbl
	.dc.w	option_f-optjp_tbl,option_l-optjp_tbl
	.dc.w	option_z-optjp_tbl,option_r-optjp_tbl
	.dc.w	option_e-optjp_tbl,option_g-optjp_tbl
	.dc.w	option_c-optjp_tbl,option_b-optjp_tbl
	.dc.w	option_1-optjp_tbl
	.dc.w	option_y-optjp_tbl
	.dc.w	option_k-optjp_tbl
	.dc.w	option_j-optjp_tbl

;----------------------------------------------------------------
;	-t path		テンポラリパス指定
option_t:
	bsr	skipspc
	bsr	getcmdstring
	move.l	a1,(TEMPPATH,a6)
	rts

;----------------------------------------------------------------
;	-i path		インクルードパス指定
option_i:
	lea.l	(INCLUDEPATH,a6),a1
  .if 90<=verno060
	cmpa.l	(ENVBOUNDARY,a6),a0
	bcc	option_i1
	lea.l	(ENVINCLUDE,a6),a1
  .endif
option_i1:
	move.l	(a1),d0			;パス名チェインを1つたどる
	bne	option_i2
	move.l	(TEMPPTR,a6),d0		;チェインの終端
	addq.l	#1,d0
	bclr.l	#0,d0
	move.l	d0,(a1)			;1つチェインを追加する
	move.l	d0,a1
	clr.l	(a1)
	addq.l	#4,d0
	move.l	d0,(TEMPPTR,a6)
	bsr	skipspc
	bsr	getcmdstring		;パス名を得る
	rts

option_i2:
	movea.l	d0,a1
	bra	option_i1

;----------------------------------------------------------------
;	-o name		オブジェクトファイル名
option_o:
	bsr	skipspc
	bsr	getcmdstring
	move.l	a1,(OBJFILE,a6)
	move.l	a0,-(sp)		;パスをスキップしてから'.'を検索する
	movea.l	a1,a0
	bsr	getfilename
	movea.l	(sp)+,a0
option_o1:
	move.b	(a1)+,d0
	beq	option_o2
	cmp.b	#'.',d0
	bne	option_o1
	rts

option_o2:				;拡張子が省略されたら.oを加える
	move.b	#'.',(-1,a1)
	move.b	#'o',(a1)+
	clr.b	(a1)+
	move.l	a1,(TEMPPTR,a6)
	rts

;----------------------------------------------------------------
;	-p [file]	リストファイル作成
option_p:
	st.b	(MAKEPRN,a6)
	lea.l	(PRNFILE,a6),a2
option_p1:
	move.b	(a0),d0
	beq	option_p2
	cmp.b	#' ',d0
	bls	option_p3
	bsr	getcmdstring		;-p[file]の場合
	move.l	a1,(a2)
option_p2:
	rts

option_p3:				;-p [file]の場合(ソースファイル名の可能性有り)
	bsr	skipspc
	move.b	(a0),d0
	beq	option_p2
	cmp.b	#'-',d0
	beq	option_p9
	tst.b	(SWITCHCHAR,a6)
	bne	option_p4		;'/'をスイッチに使用しない場合
	cmp.b	#'/',d0
	beq	option_p9
option_p4:
	bsr	getcmdstring
	move.l	a1,(a2)
	tst.l	(SOURCEFILE,a6)
	bne	option_p2
	move.l	a1,(SOURCEFILE,a6)
	rts

option_p9:
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;	-x [file]	シンボルファイル作成
option_x:
	st.b	(MAKESYM,a6)
	lea.l	(SYMFILE,a6),a2
	bra	option_p1

;----------------------------------------------------------------
;	-s symbol[=num]	シンボルの定義
option_s:
	bsr	skipspc
	bsr	getcmdnum
	bmi	option_s02
;シンボルの先頭が数字で1～4以外のときはエラー
	move.l	d1,d0
	beq	usage			;0
	subq.l	#4,d1
	bhi	usage			;5以上
	cmpi.b	#'=',(a0)
	beq	usage
	move.w	d0,(LOCALLENMAX,a6)	;最大桁数
	add.w	d0,d0
	move.w	(option_s01-2,pc,d0.w),(LOCALNUMMAX,a6)	;最大番号+1
	rts

option_s01:
	.dc.w	10,100,1000,10000

option_s02:
	cmpi.b	#'=',(a0)
	beq	usage
	move.w	#'=',-(sp)
	bsr	getcmdstring_stop
	addq.l	#2,sp
	move.l	a1,a2
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d7
	cmpi.b	#'=',(a0)
	bne	option_s1
	addq.l	#1,a0			;=num の指定があった
	cmpi.b	#'-',(a0)
	bne	option_s0
	st.b	d7
	addq.l	#1,a0
option_s0:
	bsr	getcmdnum
	bmi	usage			;数値が得られない
	tst.b	d7
	beq	option_s1
	neg.l	d1
option_s1:
	move.l	a0,-(sp)
	move.l	d1,-(sp)
	movea.l	a2,a0
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defstrsymbol		;新しく登録する
	tst.b	(SYM_TYPE,a1)		;cmpi.b #ST_VALUE,(SYM_TYPE,a1)
					;シンボルのタイプ
	bne	usage			;タイプの異なるシンボルと重複している
	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	clr.b	(SYM_SECTION,a1)	;セクション番号
	move.l	(sp)+,(SYM_VALUE,a1)	;シンボル値
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;	-f		リストファイルのフォーマット指定
option_f:
	movea.l	a0,a1
	bsr	getcmdnum
	beq	option_f1
	cmpi.b	#',',(a0)
	beq	option_f2
	st.b	(NOPAGEFF,a6)		;-f のみならページング禁止
	movea.l	a1,a0
	rts

option_f1:
	tst.l	d1
	seq.b	(NOPAGEFF,a6)		;ページングモード
option_f2:
	bsr	getnextnum
	tst.w	d0
	bmi	option_f3
	tst.l	d1
	sne.b	(ISLALL,a6)		;マクロ展開モード
option_f3:
	bsr	getnextnum
	tst.w	d0
	bmi	option_f4
	cmp.l	#256,d1
	bcc	usage
	cmp.w	#80,d1
	bcs	usage
	and.w	#$FFF8,d1
	move.w	d1,(PRNWIDTH,a6)	;表示幅
option_f4:
	bsr	getnextnum
	tst.w	d0
	bmi	option_f5
	cmp.l	#256,d1
	bcc	usage
	cmp.w	#10,d1
	bcs	usage
	move.w	d1,(PRNPAGEL,a6)	;ページ行数
option_f5:
	bsr	getnextnum
	tst.w	d0
	bmi	option_f6
	cmp.l	#65,d1
	bcc	usage
	cmp.w	#4,d1
	bcs	usage
	and.w	#$FFFC,d1
	move.w	d1,(PRNCODEWIDTH,a6)	;コード部の幅
option_f6:
	rts

;----------------------------------------------------------------
;	-w [level]	ワーニング出力レベルの指定
option_w:
	movea.l	a0,a1
	bsr	getcmdnum
	beq	option_w1
	move.b	#2,(WARNLEVEL,a6)	;-w のみ…ワーニング出力レベルは2
	movea.l	a1,a0
	rts

option_w1:
	cmp.l	#4,d1
	bhi	usage
	move.b	d1,(WARNLEVEL,a6)
	rts

;----------------------------------------------------------------
;	-n		最適化の禁止
option_n:
	st.b	(OPTIMIZE,a6)
	st.b	(IGNORE_ERRATA,a6)
	sf.b	(F43GTEST,a6)
	rts

;----------------------------------------------------------------
;	-u		未定義シンボルを外部参照にする
option_u:
	st.b	(ALLXREF,a6)
	rts

;----------------------------------------------------------------
;	-d		すべてのシンボルを外部定義にする
option_d:
	st.b	(ALLXDEF,a6)
	rts

;----------------------------------------------------------------
;	-8		シンボルの識別長を8バイトにする
option_8:
	st.b	(SYMLEN8,a6)
	rts

;----------------------------------------------------------------
;	-l		起動時にタイトルを表示する
option_l:
	st.b	(DISPTITLE,a6)
	rts

;----------------------------------------------------------------
;	-e		外部参照オフセットのデフォルトをロングワードにする
option_e:
	st.b	(EXTSHORT,a6)
	bra68	d0,option_e1		;68000/68010ならフラグセットのみ
	st.b	(EXTSIZEFLG,a6)
	move.b	#SZ_LONG,(EXTSIZE,a6)
	move.l	#4,(EXTLEN,a6)
option_e1:
	rts

;----------------------------------------------------------------
;	-g		SCD.X用デバッグ情報を出力する
option_g:
	st.b	(MAKESYMDEB,a6)
	rts

;----------------------------------------------------------------
;	-c		HAS v2.xと互換のある最適化を行う
option_c:
	bsr	getcmdnum
	bmi	option_c_x		;-cの直後が数字でない
	subq.l	#1,d1
	bcs	option_c_0
	beq	option_c_1
	subq.l	#2,d1
	bcs	option_c_2
	beq	option_c_3
	subq.l	#2,d1
	bcc	usage			;0～4でない
;-c4 すべての最適化を許可
option_c_4:
	sf.b	(OPTIMIZE,a6)		;前方参照の最適化を許可
;拡張された最適化を許可
	st.b	(OPTCLR,a6)		;CLRを最適化する
	st.b	(OPTMOVEA,a6)		;MOVEAを最適化する
	st.b	(OPTADDASUBA,a6)	;ADDA/CMPA/SUBAを最適化する
	st.b	(OPTCMPA,a6)		;ADDA/CMPA/SUBAを最適化する
	st.b	(OPTLEA,a6)		;LEAを最適化する
	st.b	(OPTASL,a6)		;ASLを最適化する
	st.b	(OPTCMP0,a6)		;CMP.bwl #0,Dn→TST.bwl Dn
	st.b	(OPTMOVE0,a6)		;MOVE.bw #0,Dn→CLR.bw Dn
	st.b	(OPTCMPI0,a6)		;CMPI.bwl #0,<ea>→TST.bwl <ea>
	st.b	(OPTSUBADDI0,a6)	;ADDI/SUBI #d3,<ea>→ADDQ/SUBQ #d3,<ea>
	st.b	(OPTBSR,a6)		;直後へのbsrをpeaにする
	st.b	(OPTJMPJSR,a6)		;jmp/jsrを最適化する
;v2互換を解除
option_c_2off:
	sf.b	(COMPATMODE,a6)		;v2非互換
	sf.b	(NOABSSHORT,a6)		;絶対ショートへの変換を許可
	sf.b	(NOQUICK,a6)		;クイックイミディエイトへの変換を許可
	sf.b	(NONULDISP,a6)		;ディスプレースメントの削除を許可
	sf.b	(NOBRACUT,a6)		;分岐命令の削除を許可
	rts

;-c3 v3互換
option_c_3:
	bsr	option_c_2off		;v2互換を解除
	bra	option_c_exoff		;拡張された最適化を禁止

;-c2 v2互換
option_c_2:
	st.b	(COMPATMODE,a6)		;NOABSSHORTとNOQUICKは-aと-qで決定する
	st.b	(NONULDISP,a6)
	st.b	(NOBRACUT,a6)
	bra	option_c_exoff		;拡張された最適化を禁止

;-c1 (d,An)の最適化を禁止
option_c_1:
	st.b	(NONULDISP,a6)
	rts

;-c0 すべての最適化を禁止
option_c_0:
	st.b	(OPTIMIZE,a6)		;前方参照の最適化を禁止
	st.b	(IGNORE_ERRATA,a6)
	sf.b	(F43GTEST,a6)
	sf.b	(COMPATMODE,a6)		;v2非互換
	st.b	(NOABSSHORT,a6)		;絶対ショートへの変換を禁止
	st.b	(NOQUICK,a6)		;クイックイミディエイトへの変換を禁止
	st.b	(NONULDISP,a6)		;ディスプレースメントの削除を禁止
	st.b	(NOBRACUT,a6)		;分岐命令の削除を禁止
;拡張された最適化を禁止
option_c_exoff:
	sf.b	(OPTCLR,a6)		;CLRを最適化する
	sf.b	(OPTMOVEA,a6)		;MOVEAを最適化する
	sf.b	(OPTADDASUBA,a6)	;ADDA/CMPA/SUBAを最適化する
	sf.b	(OPTCMPA,a6)		;ADDA/CMPA/SUBAを最適化する
	sf.b	(OPTLEA,a6)		;LEAを最適化する
	sf.b	(OPTASL,a6)		;ASLを最適化する
	sf.b	(OPTCMP0,a6)		;CMP.bwl #0,Dn→TST.bwl Dn
	sf.b	(OPTMOVE0,a6)		;MOVE.bw #0,Dn→CLR.bw Dn
	sf.b	(OPTCMPI0,a6)		;CMPI.bwl #0,<ea>→TST.bwl <ea>
	sf.b	(OPTSUBADDI0,a6)	;ADDI/SUBI #d3,<ea>→ADDQ/SUBQ #d3,<ea>
	sf.b	(OPTBSR,a6)		;直後へのbsrをpeaにする
	sf.b	(OPTJMPJSR,a6)		;jmp/jsrを最適化する
	rts

option_c_x::
	move.b	(a0),d0
	cmp.b	#' ',d0
	bls	option_c_2
option_c_x0:
	move.l	(TEMPPTR,a6),d0
	addq.l	#1,d0
	and.b	#$FE,d0
	movea.l	d0,a1
	moveq.l	#15-1,d1		;最大15文字
option_c_x1:
	move.b	(a0)+,d0
	cmp.b	#'0',d0
	blo	option_c_x2
	cmp.b	#'9',d0
	bls	option_c_x11
	cmp.b	#'A',d0
	blo	option_c_x2
	cmp.b	#'Z',d0
	bls	option_c_x10
	cmp.b	#'a',d0
	blo	option_c_x2
	cmp.b	#'z',d0
	bhi	option_c_x2
;	bra	option_c_x11

option_c_x10:
	or.b	#$20,d0
option_c_x11:
	move.b	d0,(a1)+
	dbra	d1,option_c_x1
	bra	usage			;長すぎる

option_c_x2:
	subq.l	#1,a0
	clr.b	(a1)
	move.l	(TEMPPTR,a6),d0
	addq.l	#1,d0
	and.b	#$FE,d0
	movea.l	d0,a1
;-cfscc[=6]
	cmpi.l	#'fscc',(a1)		;a1をインクリメントしないこと
	bne	option_c_x3
	tst.b	(4,a1)
	bne	option_c_x3
;FScc→FBcc
	lea.l	(X_FSCC,a6),a1		;FScc展開
	bra	option_c_y

option_c_x3:
;-cmovep[=6]
	cmpi.l	#'move',(a1)		;a1をインクリメントしないこと
	bne	option_c_x4
	cmpi.w	#'p'<<8,(4,a1)
	bne	option_c_x4
;MOVEP→MOVE
	lea.l	(X_MOVEP,a6),a1
option_c_y:
	st.b	(a1)			;すべて展開する
	move.b	(a0)+,d0
	cmp.b	#'=',d0
	bne	option_c_x96
	cmpi.b	#'6',(a0)+
	bne	usage
	move.w	#C060,(a1)		;68060のときだけ展開する
	bra	option_c_x99

option_c_x4:

;-cfximm
;F<op>.X #imm,FPn→(d,PC)

;-cfmovecr
;FMOVECR.X #imm,FPn→(d,PC)

;-call[=6]
	cmpi.l	#'all'<<8,(a1)
	bne	usage
;ALL
	st.b	d0			;moveq.l #-1,d0は不可
	cmpi.b	#'=',(a0)
	bne	option_c_x95
	addq.l	#1,a0
	cmpi.b	#'6',(a0)+
	bne	usage
	move.w	#C060,d0		;68060のときだけ
option_c_x95:
	move.w	d0,(X_FSCC,a6)		;FScc展開
	move.w	d0,(X_MOVEP,a6)		;MOVEP展開
option_c_x99:
	move.b	(a0)+,d0
option_c_x96:
	cmp.b	#' ',d0
	bls	option_c_x97		;0を含むのでa0をデクリメントしてから終了
	cmp.b	#',',d0
	bne	usage
	bra	option_c_x0

option_c_x97:
	subq.l	#1,a0
option_c_x98:
	rts

;----------------------------------------------------------------
;	-b[n]		PC間接→絶対ロング([1]=68000,2=mem,3=1+2,4=all,5=1+4)
;				0	[禁止]
;				[1]	(bd,PC)/Bcc.L	68000コード生成
;				2	(d,PC)<mem>	i-cache回避(lea/pea以外)
;				3	1+2
;				4	(d,PC)<all>	デバッグ用
;				5	1+4
option_b:
	bsr	getcmdnum
	bmi	option_b1
	subq.l	#1,d1
	bcs	option_b0
	beq	option_b1
	subq.l	#2,d1
	bcs	option_b2
	beq	option_b3
	subq.l	#2,d1
	bcs	option_b4
	bne	usage			;0～5でない
option_b5:
	bsr	option_b4_1
	bsr	option_b2_1		;5→7(allはmemを含む)
option_b1_1:
	st.b	(LONGABS,a6)
	st.b	(BRATOJBRA,a6)
	rts

option_b4:
	bsr	option_b2_1		;4→6(allはmemを含む)
	bsr	option_b1_0
option_b4_1:
	sf.b	(PCTOABSLNOTALL,a6)
	rts

option_b3:
	bsr	option_b4_0
	bsr	option_b1_1
option_b2_1:
	st.b	(PCTOABSL,a6)
	rts

option_b2:
	bsr	option_b4_0
	bsr	option_b2_1
option_b1_0:
	sf.b	(LONGABS,a6)
	sf.b	(BRATOJBRA,a6)
	rts

option_b1:
	bsr	option_b4_0
	bsr	option_b1_1
option_b2_0:
	sf.b	(PCTOABSL,a6)
	rts

option_b0:
	bsr	option_b2_0
	bsr	option_b1_0
option_b4_0:
	st.b	(PCTOABSLNOTALL,a6)
	rts

;----------------------------------------------------------------
;	-m nn		CPUモードの指定
option_m:
	bsr	skipspc
	bsr	getcmdnum
	bmi	usage
  .if 89<=verno060
	bsr	cputype_convert
	bmi	@f
	move.l	d1,(ICPUNUMBER,a6)
	move.w	d0,(ICPUTYPE,a6)
	rts
@@:
  .else
	cmp.l	#68000,d1
	beq	~~cpu_68000
	cmp.l	#68010,d1
	beq	~~cpu_68010
	cmp.l	#68020,d1
	beq	~~cpu_68020
	cmp.l	#68030,d1
	beq	~~cpu_68030
	cmp.l	#68040,d1
	beq	~~cpu_68040
	cmp.l	#68060,d1
	beq	~~cpu_68060
	cmp.l	#5200,d1
	beq	~~cpu_5200
	cmp.l	#5300,d1
	beq	~~cpu_5300
	cmp.l	#5400,d1
	beq	~~cpu_5400
  .endif

	cmp.l	#1000,d1
	bls	usage
	cmp.l	#32768,d1
	bcc	usage
	rts				;その他の数値(最大シンボル数指定)は何もしない

;----------------------------------------------------------------
;	-j[n]
option_j:
	bsr	getcmdnum
	bpl	option_j_1
	moveq.l	#-1,d1
option_j_1:
	lsr.l	#1,d1
	scs.b	(OWSET,a6)
	lsr.l	#1,d1
	scs.b	(OWOFFSYM,a6)
;無効なビットはエラーではなく無視する
	rts

;----------------------------------------------------------------
;	-k	エラッタの対策を禁止する
option_k:
	bsr	getcmdnum
	bmi	option_k_1
	cmp.l	#1,d1
	bhi	usage
	beq	option_k_1
option_k_0:
	sf.b	(IGNORE_ERRATA,a6)
	sf.b	(OPTIMIZE,a6)
	rts

option_k_1:
	st.b	(IGNORE_ERRATA,a6)
	sf.b	(F43GTEST,a6)
	rts

;----------------------------------------------------------------
;	-1		絶対ロングをoptional PC間接にする
option_1:
	st.b	(ABSLTOOPC,a6)		;絶対ロングをoptional PC間接にする
	bsr	option_e
	bra	option_b1

;----------------------------------------------------------------
;	-y[n]		プレデファインシンボル制御(0=[禁止],[1]=許可)
option_y:
	bsr	getcmdnum
	bmi	option_y_1
	subq.l	#1,d1
	bcs	option_y_0
	bne	usage
option_y_1:
	st.b	(PREDEFINE,a6)
	rts

option_y_0:
	sf.b	(PREDEFINE,a6)
	rts


;----------------------------------------------------------------
;	(ダミーのオプションスイッチ)

;	-a		絶対ショートアドレス形式対応モード
option_a:
	st.b	(COMPATSWA,a6)
	rts

;	-q		クイックイミディエイト形式への変換禁止
option_q:
	st.b	(COMPATSWQ,a6)
;	-z		HAS拡張機能のワーニング禁止
option_z:
;	-r		相対セクション命令を許可する
option_r:
	rts

;----------------------------------------------------------------
;	コマンドラインから文字列を得る
getcmdstring:
	clr.w	-(sp)
	bsr	getcmdstring_stop
	addq.l	#2,sp
	rts

getcmdstring_stop:
	tst.b	(a0)
	beq	usage
	movea.l	(TEMPPTR,a6),a1
	move.l	a1,-(sp)
getcmdstring1:
	move.b	(a0)+,d0
	cmp.b	#' ',d0
	bls	getcmdstring2
	cmp.b	(4+4+1,sp),d0
	beq	getcmdstring2
	move.b	d0,(a1)+
	bra	getcmdstring1

getcmdstring2:
	subq.l	#1,a0
	clr.b	(a1)+
	move.l	a1,(TEMPPTR,a6)
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	コマンドラインの数値を得る
getcmdnum:
	movem.l	a0-a1,-(sp)
	bsrl	getnum,d0
	beq	getcmdnum9
	movem.l	(sp)+,a0-a1
	moveq.l	#-1,d0
	rts

getcmdnum9:
	addq.l	#4,sp
	movea.l	(sp)+,a1
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;	コマンドラインの次の数値を得る
getnextnum:
	cmpi.b	#',',(a0)+
	beq	getcmdnum
	subq.l	#1,a0
	addq.l	#4,sp
	rts				;呼び出したサブルーチンをリターン

;----------------------------------------------------------------
;	拡張子を取り除いたファイル名を転送する
tfrfilename:
	move.l	a1,-(sp)
tfrfilename1:
	move.b	(a1)+,d0
	beq	tfrfilename9
	cmp.b	#'.',d0
	beq	tfrfilename9
	move.b	d0,(a0)+
	bra	tfrfilename1

tfrfilename9:
	clr.b	(a0)
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	使用法を表示して終了する
usage:
	lea.l	(title_msg,pc),a0
	bsr	printmsg
	lea.l	(usage_msg,pc),a0
	bsr	printmsg
	move.w	#1,-(sp)
	DOS	_EXIT2


;----------------------------------------------------------------
	.end	asmmain

;----------------------------------------------------------------
;
;	Revision 4.2  2023-07-07 12:00:00  M.Kamada
;	+91 使用法のasをhas060に変更、環境変数の説明に(-iは後ろ)を追加
;
;	Revision 4.1  2023-07-06 12:00:00  M.Kamada
;	+90 環境変数HASの-iをコマンドラインの-iの後に検索する
;
;	Revision 4.0  2016-08-07 12:00:00  M.Kamada
;	+89 060turbo で 060high 1 のとき 16MB を超えるメモリを確保できる
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 3.9  2016-01-01 12:00:00  M.Kamada
;	+88 title_msgの著作権表示をmain.sからhas.equに移動
;	+88 タイトルメッセージが80文字に収まるように著作権表示をコンパクトに
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 3.8  1999 10/ 8(Fri) 17:33:03 M.Kamada
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;
;	Revision 3.7  1999  3/19(Fri) 16:18:43 M.Kamada
;	+83 -o./fooのとき.oが補完されなかった
;	+83 "致命的な"を除去
;	+83 使用法に環境変数HASの先頭が'*'の場合について記述
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;
;	Revision 3.6  1999  3/ 3(Wed) 14:39:51 M.Kamada
;	+82 ヘルプメッセージのスイッチの並び順を変更
;	+82 Fatal error(s)メッセージを日本語化
;	+82 使用法の -f や -w の表示を変更
;	+82 doeven→doquad
;
;	Revision 3.5  1999  2/27(Sat) 23:42:45 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 3.4  1999  2/25(Thu) 05:02:40 M.Kamada
;	+80 Copyright表示が-98になっていた
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;	+80 setでset以外で定義されたシンボルの上書き禁止
;
;	Revision 3.3  1999  2/13(Sat) 20:35:01 M.Kamada
;	+79 .R形式にするとメモリが極端に不足しているとき直後のブロックを破壊する可能性がある
;	+79 メモリが極端に不足しているときバスエラーが出る可能性がある
;	+79 コマンドラインに'='で始まる単語があるとハングアップする
;	+79 ソースファイル名が2つあるときエラーにする
;
;	Revision 3.2  1998 11/19(Thu) 23:46:21 M.Kamada
;	+78 -k0と-nを併用すると誤動作するため後から指定した方を有効にする
;
;	Revision 3.1  1998  7/14(Tue) 02:43:56 M.Kamada
;	+69 プレデファインシンボル__HAS__と__HAS060__を追加
;	+69 crlf_msgを内蔵
;
;	Revision 3.0  1998  5/24(Sun) 18:28:43 M.Kamada
;	+66 -y[n]のnを書くと常に-y0になる不具合を修正
;
;	Revision 2.9  1998  4/13(Mon) 04:51:03 M.Kamada
;	+64 エラッタの対策を禁止するスイッチを追加
;
;	Revision 2.8  1998  3/31(Tue) 02:09:02 M.Kamada
;	+63 jmp/jsrを最適化する
;
;	Revision 2.7  1998  1/25(Sun) 21:53:31 M.Kamada
;	+58 逆条件ニモニックとelifを追加
;
;	Revision 2.6  1998  1/ 9(Fri) 22:22:27 M.Kamada
;	+56 -f43gを削除
;
;	Revision 2.5  1998  1/ 5(Mon) 01:10:43 M.Kamada
;	+55 -b[n]
;	+55 -1をg2asに合わせる
;	+55 ヘルプの命令を大文字に
;
;	Revision 2.4  1997 10/28(Tue) 02:53:25 M.Kamada
;	+52 -callの直後の1文字が'='でないと無視される不具合
;
;	Revision 2.3  1997 10/13(Mon) 02:12:15 M.Kamada
;	+51 直後へのbsr→pea
;	+52 JMP/JSRを最適化する
;
;	Revision 2.2  1997  9/28(Sun) 19:56:57 M.Kamada
;	+49 -mの後にスペースがあるとエラーになる
;	+49 -cmnemonicを指定するとアドレスエラーが出ることがある
;	+49 -cmnemonicを-c<mnemonic>に,他のスイッチも<>で囲んでみた
;	+49 -up,-dp廃止,代わりに-y[n]を使用
;
;	Revision 2.1  1997  9/23(Tue) 03:32:58 M.Kamada
;	+47 movepとfsccのエミュレーションを拡充
;
;	Revision 2.0  1997  9/15(Mon) 16:01:22 M.Kamada
;	+46 error.sを分離,ST_VALUE=0で最適化
;
;	Revision 1.9  1997  9/17(Wed) 22:36:55 M.Kamada
;	+43 -c0ですべての最適化を禁止する
;	+44 software emulationの命令を展開する
;
;	Revision 1.8  1997  7/ 9(Wed) 02:36:17 M.Kamada
;	+39 -1の挙動を修正
;
;	Revision 1.7  1997  6/26(Thu) 22:09:48 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;	+34 プレデファインシンボル__DATE__,__TIME__に対応
;	+35 CMP.bwl #0,Dn→TST.bwl Dn
;	+36 MOVE.bw #0,Dn→CLR.bw Dn
;	+37 -up,-dpでプレデファインシンボルの禁止,許可
;	+38 CMPI.bwl #0,<ea>→TST.bwl <ea>
;
;	Revision 1.6  1997  3/29(Sat) 21:25:18 M.Kamada
;	+24 MOVEAを最適化する
;	+25 CLRを最適化する
;	+26 ADDA/CMPA/SUBAを最適化する
;	+27 -c4で拡張最適化許可
;	+28 LEAを最適化する
;	+29 ASLを最適化する
;
;	Revision 1.5  1997  3/14(Fri) 02:46:08 M.Kamada
;	+18 サイズ指定のない定数でない絶対ロングを(d,OPC)にする
;
;	Revision 1.4  1997  2/ 2(Sun) 17:03:15 M.Kamada
;	+15 -c1ならばNONULDISPだけセットする
;		-wとlevelの間の空白を認めない
;		-fとf,m,w,pの間の空白を認めない
;
;	Revision 1.3  1996 11/13(Wed) 15:27:30 M.Kamada
;	+00 DEBUG追加
;		テンポラリファイルを削除しない
;	+99 タイトル変更
;	+02 68060対応
;		ヘルプメッセージ変更
;	+05 デフォルトのターゲットMPUを常に68000にする
;		デフォルトのターゲットMPUを常に68000にする
;		ヘルプメッセージ変更
;	+06 環境変数HASをコマンドラインの前に挿入する
;		環境変数HASをコマンドラインの前に挿入する
;		ヘルプメッセージ変更
;
;	Revision 1.2  1994/03/06  03:16:24  nakamura
;	オプションスイッチの追加その他
;
;	Revision 1.1  1994/02/16  15:38:18  nakamura
;	Initial revision
;
;
