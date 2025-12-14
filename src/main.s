;----------------------------------------------------------------
;	X68k High-speed Assembler
;		メインルーチン
;		< main.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2023  by M.Kamada
;			  2025       by TcbnErik
;----------------------------------------------------------------

	.include	doscall.mac
	.include	has.equ
	.include	symbol.equ
	.include	register.equ
	.include	error2.equ
	.include	work.equ
	.include	version.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	メインプログラム
;----------------------------------------------------------------
asmmain::
	bra.s	@f
	.dc.b	'#HUPAIR',0
@@:
	move.l	#STACKBTM-asmmain,d0
	lea.l	(asmmain,pc,d0.l),sp	;lea.l (STACKBTM,pc),sp
	move.l	#WORKBEGIN-asmmain,d0
	lea.l	(asmmain,pc,d0.l),a6	;lea.l (WORKBEGIN,pc),a6

	bsr	meminit			;メモリ領域の確保
	bsr	workinit		;ワークエリアの初期化
	bsr	g2asmode
	bsr	defressym		;予約済みシンボルの初期化
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
	bsr	prnpaging1		;タイトル行を出力
asmmain1:
	bsr	asmpass1		;パス1
	bsr	asmpass2		;パス2
	bsrl	asmpass3,d0		;パス3
	bsr	tempdelete		;テンポラリファイルの削除
	tst.l	(NUMOFERR,a6)
	beq	asmmain2
	move.w	#1,-(sp)		;エラーがあった場合の終了コード
	move.l	(OBJFILE,a6),-(sp)
	DOS	_DELETE			;オブジェクトファイルを削除する
	addq.l	#4,sp
	lea.l	(beep_msg,pc),a0
	bsr	printmsg		;ビープ音を鳴らす
	movea.l	(LINEBUFPTR,a6),a0
	lea.l	(fatal_msg1,pc),a1
	bsr	strcpy
	move.l	(NUMOFERR,a6),d0
	moveq.l	#0,d1			;(左詰め)
	bsr	convdec
	lea.l	(fatal_msg2,pc),a1
	bsr	strcpy
	clr.b	(a0)
	movea.l	(LINEBUFPTR,a6),a0
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
	lea.l	(crlf_msg,pc),a0
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

title_msg::
	.dc.b	'HAS060X.X ',version_x, ' ',copyright_x,CRLF
	.dc.b	'  based on '
	.dc.b	'X68k High-speed Assembler v',version,' ',copyright,CRLF,0

usage_msg:
	.dc.b	'使用法: has060x [スイッチ] ファイル名',CRLF
	.dc.b	TAB,'-1',TAB,TAB
	.dc.b	'絶対ロング→PC間接(-b1と-eを伴う)',CRLF
;-8 シンボルの識別長を8バイトにする(廃止)
;-a 絶対ショートアドレス形式対応(-c2時のみ有効)
	.dc.b	TAB,'-b[n]',TAB,TAB
	.dc.b	'PC間接→絶対ロング(0=[禁止],[1]=68000,2=MEM,3=1+2,4=ALL,5=1+4)',CRLF
	.dc.b	TAB,'-c[n]',TAB,TAB
	.dc.b	'最適化(0=禁止(-k1を伴う),1=(d,An)を禁止,[2]=v2互換,3=[v3互換],4=許可)',CRLF
	.dc.b	TAB,'-c<mnemonic>',TAB
	.dc.b	'software emulationの命令を展開する(FScc/MOVEP)',CRLF
	.dc.b	TAB,'-d',TAB,TAB
	.dc.b	'すべてのシンボルを外部定義にする',CRLF
	.dc.b	TAB,'-e',TAB,TAB
	.dc.b	'外部参照オフセットのデフォルトをロングワードにする',CRLF
	.dc.b	TAB,'-f[f,m,w,p,c]',TAB
	.dc.b	'リストファイルのフォーマット',CRLF
	.dc.b	TAB,TAB,TAB
	.dc.b	'(改ページ[0],マクロ展開[0],幅[96],ページ行数[58],コード幅[16])',CRLF
	.dc.b	TAB,'-g',TAB,TAB
	.dc.b	'SCD用デバッグ情報の出力',CRLF
	.dc.b	TAB,'-i <path>',TAB
	.dc.b	'インクルードパス指定',CRLF
	.dc.b	TAB,'-j[n]',TAB,TAB
	.dc.b	'シンボルの上書き禁止条件の強化(0=しない,1=SET,2=OFFSYM,[3]=[1+2])',CRLF
	.dc.b	TAB,'-k[n]',TAB,TAB
	.dc.b	'68060のエラッタ対策(0=[する](-nは無効),[1]=しない)',CRLF
	.dc.b	TAB,'-l',TAB,TAB
	.dc.b	'起動時にタイトルを表示する',CRLF
	.dc.b	TAB,'-m <680x0>',TAB
	.dc.b	'アセンブル対象CPUの指定([68000]～68060)',CRLF
	.dc.b	TAB,'-n',TAB,TAB
	.dc.b	'パス1で確定できないサイズの最適化を省略する(-k1を伴う)',CRLF
	.dc.b	TAB,'-o <name>',TAB
	.dc.b	'オブジェクトファイル名',CRLF
	.dc.b	TAB,'-p [file]',TAB
	.dc.b	'リストファイル作成',CRLF
;-q クイックイミディエイト形式への変換禁止(-c2時のみ有効)
;-r 相対セクション命令の許可(廃止)
	.dc.b	TAB,'-s <n>',TAB,TAB
	.dc.b	'数字ローカルラベルの最大桁数の指定(1～[4])',CRLF
	.dc.b	TAB,'-s <symbol>[=n]',TAB
	.dc.b	'シンボルの定義',CRLF
	.dc.b	TAB,'-t <path>',TAB
	.dc.b	'テンポラリパス指定',CRLF
	.dc.b	TAB,'-u',TAB,TAB
	.dc.b	'未定義シンボルを外部参照にする',CRLF
	.dc.b	TAB,'-w[n]',TAB,TAB
	.dc.b	'ワーニングレベルの指定(0=全抑制,1,[2],3,4=[全通知])',CRLF
	.dc.b	TAB,'-x [file]',TAB
	.dc.b	'シンボルの出力',CRLF
	.dc.b	TAB,'-y[n]',TAB,TAB
	.dc.b	'プレデファインシンボル(0=[禁止],[1]=許可)',CRLF
;-z HAS拡張機能のワーニング禁止(廃止)
	.dc.b	TAB,'-_',TAB,TAB
	.dc.b	"外部定義・外部参照シンボルの先頭に'_'を挿入する",CRLF
	.dc.b	'    環境変数 HAS の内容がコマンドラインの手前(-iは後ろ)に挿入されます',CRLF
	.dc.b	0

multifile_msg:	.dc.b	'複数のファイル名は指定できません',CRLF
		.dc.b	0

no_msg:		.dc.b	'エラーはありません',CRLF,0
fatal_msg1:	.dc.b	'エラーが ',0
fatal_msg2:	.dc.b	' 個ありました．アセンブルを中止します',CRLF,0

env_has:	.dc.b	'HAS',0		;コマンドラインに追加する環境変数名
env_g2as:	.dc.b	'G2AS',0
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

	move.l	#$7FFFFFFF,-(sp)	;試しに060turbo.sysで拡張された
	DOS	_MALLOC3		;DOSコールで確保してみる
	and.l	d0,(sp)
	DOS	_MALLOC3
	move.l	d0,(sp)+
	bpl	meminit1		;確保できたならそれを使う

	move.l	#$FFFFFF,-(sp)
	DOS	_MALLOC			;メモリを最大限確保
	and.l	d0,(sp)
	DOS	_MALLOC			;あるだけのメモリを確保
	move.l	d0,(sp)+
	bmi	nomemabort		;メモリが全く確保出来ない
meminit1:
	move.l	d0,(MEMPTR,a6)		;未使用領域の開始アドレス
	movea.l	d0,a0
	move.l	(-8,a0),d0		;	     終了アドレス
	sub.l	#$400,d0
	move.l	d0,(MEMLIMIT,a6)
	rts


;----------------------------------------------------------------
;	ワークエリアの初期化
;----------------------------------------------------------------
workinit:
	move.l	(MEMPTR,a6),(TEMPPTR,a6)

	lea.l	(nulstr,pc),a0
	move.l	a0,(TEMPPATH,a6)
	move.l	a0,(PRNTITLE,a6)
	move.l	a0,(PRNSUBTTL,a6)

	st.b	(NOPAGEFF,a6)
	move.w	#96,(PRNWIDTH,a6)
	move.w	#58,(PRNPAGEL,a6)
	move.w	#16,(PRNCODEWIDTH,a6)
	move.w	#1,(PRNMPAGE,a6)
	lea.l	(REQFILPTR,a6),a0
	move.l	a0,(REQFILEND,a6)
	move.l	#6,(NUMOFSECT,a6)
	st.b	(WARNLEVEL,a6)		;-w255相当(全通知) 厳密にするならmove.b #4,...

	bsr	option_j_all

	move.l	#68000,(ICPUNUMBER,a6)
	move.w	#1<<9,(FPCPID,a6)

	move.w	#4,(LOCALLENMAX,a6)
	move.w	#10000,(LOCALNUMMAX,a6)

	lea.l	(LOCSYMBUFEND,a6),a0
	move.l	a0,(LOCSYMENDPTR,a6)

	leawork	SYMHASHTBL,a0
	move.l	a0,(SYMHASHPTR,a6)
	leawork	CMDHASHTBL,a0
	move.l	a0,(CMDHASHPTR,a6)

	clr.w	(SYMTBLCOUNT,a6)
	lea.l	(SYMTBLBEGIN,a6),a0
	move.l	a0,(SYMTBLCURBGN,a6)

	lea.l	(LINEBUF,a6),a0
	move.l	a0,(LINEBUFPTR,a6)
	leawork	OPRBUF,a0
	move.l	a0,(OPRBUFPTR,a6)

	move.l	(TEMPPTR,a6),d0
	doquad	d0			;ロングワード境界に合わせる
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

	bra	memcheck

;----------------------------------------------------------------
;	g2asモードの初期化
;----------------------------------------------------------------
g2asmode:
	move.l	(asmmain-$100+$c4,pc),d0			;実行ファイルのファイル名
	ori.l	#$20002020,d0
	cmpi.l	#'g2as',d0
	bne	9f
	st	(G2ASMODE,a6)
	bsr	option_c_4
	bra	option_1
9:
	rts

;----------------------------------------------------------------
;	プレデファインシンボルの初期化
;----------------------------------------------------------------
predefinesymbol:
	tst.b	(PREDEFINE,a6)
	beq	predefinesymbol99

	;現時点でCPUTYPEは設定されておらず0なので参照しないこと
	;値は各パスの開始時に設定するので、ここでは仮の値でよい
	moveq.l	#0,d0
	lea.l	(symbol_cpu,pc),a0
	bsr	def_predefinesymbol
	ztst.b	ST_VALUE,(SYM_TYPE,a1)	;シンボルのタイプ
	bne	@f			;定義できなかった(念のため)
	move.l	a1,(CPUSYMBOL,a6)
@@:
	lea.l	(symbol_date,pc),a0
	moveq.l	#$07,d0
	and.w	(ASSEMBLEDATE,a6),d0	;|........|........|........|.....www|
	lsl.w	#5,d0			;|........|........|........|www.....|
	swap.w	d0			;|........|www.....|........|........|
	move.w	(ASSEMBLEDATE+2,a6),d0	;|........|www.....|yyyyyyym|mmmddddd|
	add.l	#1980<<9,d0		;|........|wwwYYYYY|YYYYYYYm|mmmddddd|
	lsl.l	#7,d0			;|.wwwYYYY|YYYYYYYY|mmmmdddd|d.......|
	lsr.w	#4,d0			;|.wwwYYYY|YYYYYYYY|....mmmm|ddddd...|
	lsr.b	#3,d0			;|.wwwYYYY|YYYYYYYY|....mmmm|...ddddd|
	bsr	def_predefinesymbol
	lea.l	(symbol_time,pc),a0
	move.l	(ASSEMBLETIM2,a6),d0
	bsr	def_predefinesymbol

	lea.l	(symbol_has,pc),a0
	move.l	#verno,d0		;309
	bsr	def_predefinesymbol
	lea.l	(symbol_has060,pc),a0
	move.l	#verno060,d0		;69～
	bsr	def_predefinesymbol
	lea.l	(symbol_has060x,pc),a0
	move.l	#verno_x,d0
	bsr	def_predefinesymbol
predefinesymbol99:
	rts

;<d0.l:値
;<a0.l:文字列
;>a1.l:シンボルテーブル
def_predefinesymbol:
	move.l	d0,-(sp)
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defstrsymbol		;新しく登録する
	ztst.b	ST_VALUE,(SYM_TYPE,a1)	;シンボルのタイプ
	bne	@f			;定義できなかった(念のため)

	move.b	#SA_PREDEFINE,(SYM_ATTRIB,a1)	;プレデファインシンボル
	zclr.b	SECT_ABS,(SYM_SECTION,a1)	;セクション番号
	move.l	(sp),(SYM_VALUE,a1)		;値
@@:	addq.l	#4,sp
	rts

symbol_cpu:	.dc.b	'CPU',0
symbol_date:	.dc.b	'__DATE__',0
symbol_time:	.dc.b	'__TIME__',0
symbol_has:	.dc.b	'__HAS__',0
symbol_has060:	.dc.b	'__HAS060__',0
symbol_has060x:	.dc.b	'__HAS060X__',0
	.even


;----------------------------------------------------------------
;	コマンドラインの解釈を行う
;----------------------------------------------------------------
docmdline:
	movea.l	(TEMPPTR,a6),a0		;コマンドラインより先に環境変数HASを解釈する
	clr.b	(a0)
	move.l	a0,-(sp)
	clr.l	-(sp)
	lea.l	(env_has,pc),a2
	tst.b	(G2ASMODE,a6)
	beq	@f
	addq.l	#env_g2as-env_has,a2
@@:
	pea.l	(a2)
	bsr	getenv
	lea.l	(12,sp),sp
	cmpi.b	#'*',(a0)
	bne	docmdline1
	addq.l	#1,a0			;環境変数の先頭の'*'は無視('/'は常にスイッチにしない)
docmdline1:
	bsr	dechupair
	lea	(INCPATHENV,a6),a2
	bsr	docmdline3

	movea.l	(CMDLINEPTR,a6),a0
	bsr	dechupair
	lea	(INCPATHCMD,a6),a2
	bsr	docmdline3
					;コマンドラインが終了
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
	bsr	has_filename_ext	;a0=SOURCEFILE
	tst.b	d0
	bne	docmdline14		;ソースファイルに拡張子の指定あり

	movea.l	d2,a1			;拡張子が省略された場合
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
docmdline3end:
	rts

docmdline3:
	move.l	a2,(INCPATHPTR,a6)
	lea	(a1),a5
docmdline3lp:
	cmpa.l	a5,a0
	bcc	docmdline3end		;全ての引数を処理した
	move.b	(a0),d0
	beq	docmdline3next		;空文字列の引数
	cmpi.b	#'-',d0
	bne	@f
	bsr	optionsw
	bra	docmdline3lp
@@:
	move.l	(SOURCEFILE,a6),d0
	beq	@f
	cmp.l	(PRNFILE,a6),d0
	beq	@f
	cmp.l	(SYMFILE,a6),d0
	bne	multifile		;ソースファイル名が2つある
@@:
	move.l	a0,(SOURCEFILE,a6)
docmdline3next:
@@:	tst.b	(a0)+
	bne	@b
	bra	docmdline3lp

;----------------------------------------------------------------
;	ファイル名に拡張子があるか調べる
;	in :a0=ドライブ・パス名付きファイル名へのポインタ
;	out:d0.l=0なら拡張子なし、d0.l='.'なら拡張子あり
has_filename_ext:
	movem.l	d1/a0-a1,-(sp)
	bsr	getfilename
	moveq	#0,d0
	moveq	#'.',d1
@@:
	cmp.b	(a1)+,d1		;ドットファイル(.foo)の先頭の.を
	beq	@b			;拡張子として扱わない
	subq.l	#1,a1
@@:
	move.b	(a1)+,d0
	beq	@f
	cmp.b	d0,d1
	bne	@b
@@:
	movem.l	(sp)+,d1/a0-a1
	rts

;----------------------------------------------------------------
;	オプションスイッチの処理
optionsw:
	addq.l	#1,a0
optionsw1:
	move.b	(a0)+,d0
	beq	optionsw0
	moveq.l	#'z'-'a'+1,d2		;アルファベット以外を先に判別
	cmpi.b	#'1',d0
	beq	@f
	addq.w	#1,d2
	cmpi.b	#'_',d0
	beq	@f

	moveq.l	#$20,d2
	or.b	d0,d2			;小文字化
	subi	#'a',d2
	cmpi	#'z'-'a',d2
	bhi	usage			;該当するオプションスイッチがない
@@:
	add	d2,d2
	move	(optjp_tbl,pc,d2.w),d2
	jsr	(optjp_tbl,pc,d2.w)
	bra	optionsw1
optionsw0:
	rts

;----------------------------------------------------------------
;	オプションスイッチのジャンプテーブル
optjp_tbl:
	.irpc	ch,abcdefghijklmnopqrstuvwxyz1
	.dc.w	option_&ch-optjp_tbl
	.endm
	.dc.w	option_underscore-optjp_tbl

;----------------------------------------------------------------
;	-t path		テンポラリパス指定
option_t:
	bsr	getcmdstring
	move.l	a0,(TEMPPATH,a6)
	bra	skipstring

skipstring:
@@:	tst.b	(a0)+
	bne	@b
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;	-i path		インクルードパス指定
option_i:
	movea.l	(INCPATHPTR,a6),a1	;INCPATHENV/INCPATHCMD
	bra	option_i1
option_i2:
	movea.l	d0,a1
option_i1:
	move.l	(a1),d0			;パス名チェインを1つたどる
	bne	option_i2

	move.l	(TEMPPTR,a6),d0		;チェインの終端
	doquad	d0
	move.l	d0,(a1)			;1つチェインを追加する
	move.l	d0,a1
	clr.l	(a1)+			;次のチェイン(現時点では終端)
	bsr	getcmdstring
	move.l	a0,(a1)+		;パス名
	move.l	a1,(TEMPPTR,a6)
	bra	skipstring

;----------------------------------------------------------------
;	-o name		オブジェクトファイル名
option_o:
	bsr	getcmdstring
	move.l	a0,(OBJFILE,a6)
	move.l	a0,-(sp)		;パスをスキップしてから'.'を検索する
	bsr	has_filename_ext
	tst.b	d0
	bne	9f			;拡張子あり

	movea.l	(OBJFILE,a6),a0		;拡張子が省略されたら.oを加える
	lea	(dot_o,pc),a1
	bsr	strdupcat
	move.l	d0,(OBJFILE,a6)
9:
	movea.l	(sp)+,a0
	bra	skipstring

dot_o:
	.dc.b	'.o',0
	.even

strdupcat:
	movem.l	d1/a0-a3,-(sp)
	movea.l	(TEMPPTR,a6),a2
	lea	(a2),a3
	bsr	strlen
	adda.l	d1,a3
	exg	a0,a1
	bsr	strlen
	adda.l	d1,a3
	addq.l	#1,a3
	move.l	a3,(TEMPPTR,a6)
	bsr	memcheck

	move.l	a2,d0			;新しい文字列のポインタ
@@:	move.b	(a1)+,(a2)+
	bne	@b
	subq.l	#1,a2
@@:	move.b	(a0)+,(a2)+
	bne	@b
	movem.l	(sp)+,d1/a0-a3
	rts

;----------------------------------------------------------------
;	-p [file]	リストファイル作成
option_p:
	st.b	(MAKEPRN,a6)
	lea.l	(PRNFILE,a6),a2
option_p1:
	tst.b	(a0)
	bne	option_p5		;-pFILE の場合
@@:
	addq.l	#1,a0
	cmpa.l	a5,a0
	bcc	option_p9		;コマンドラインの末尾に -p
	tst.b	(a0)
	beq	@b
@@:
	cmp.b	#'-',(a0)
	beq	option_p9		;-p -? ならファイル名指定なし

	tst.l	(SOURCEFILE,a6)		;-p FILE の場合、ソースファイル名の可能性あり
	bne	@f
	move.l	a0,(SOURCEFILE,a6)
@@:
option_p5:
	move.l	a0,(a2)
	bra	skipstring
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
	bsr	getcmdstring
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
	lea	(a0),a1
@@:	tst.b	(a1)+
	bne	@b
	pea	(-1,a1)			;-sの処理が終わったらオプション解釈を終了して次の引数へ

	moveq	#'=',d0
	cmp.b	(a0),d0
	beq	usage
	bsr	strsplit
	bsr	strlen
	clr	d1
	tst.l	d1
	bne	usage			;シンボル名が長すぎる

	move.l	a0,a2			;シンボル名
	move.l	a1,a0			;= の直後の文字列
	moveq.l	#0,d1
	moveq.l	#0,d7
	move.l	a0,d0
	beq	option_s1		;=num の指定がない(=0 とみなす)
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
	move.l	d1,-(sp)
	movea.l	a2,a0
	moveq.l	#ST_VALUE,d2		;数値シンボル
	bsr	defstrsymbol		;新しく登録する
	ztst.b	ST_VALUE,(SYM_TYPE,a1)	;シンボルのタイプ
	bne	usage			;タイプの異なるシンボルと重複している

	move.b	#SA_DEFINE,(SYM_ATTRIB,a1)	;定義済シンボル
	clr.b	(SYM_SECTION,a1)	;セクション番号
	move.l	(sp)+,(SYM_VALUE,a1)	;シンボル値
	movea.l	(sp)+,a0
	rts

strsplit:
	move.l	a0,-(sp)
	suba.l	a1,a1			;検索文字の次のアドレス(なければ 0)
@@:
	tst.b	(a0)
	beq	9f
	cmp.b	(a0)+,d0
	bne	@b
	lea	(a0),a1			;検索文字が見つかった
	clr.b	-(a0)
9:
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
;	-l		起動時にタイトルを表示する
option_l:
	st.b	(DISPTITLE,a6)
	rts

;----------------------------------------------------------------
;	-e		外部参照オフセットのデフォルトをロングワードにする
option_e:
	st.b	(EXTSHORT,a6)
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
	clr.b	(OPTIMIZE,a6)		;前方参照の最適化を許可
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
	clr.b	(COMPATMODE,a6)		;v2非互換
	clr.b	(NOABSSHORT,a6)		;絶対ショートへの変換を許可
	clr.b	(NOQUICK,a6)		;クイックイミディエイトへの変換を許可
	clr.b	(NONULDISP,a6)		;ディスプレースメントの削除を許可
	clr.b	(NOBRACUT,a6)		;分岐命令の削除を許可
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
	clr.b	(COMPATMODE,a6)		;v2非互換
	st.b	(NOABSSHORT,a6)		;絶対ショートへの変換を禁止
	st.b	(NOQUICK,a6)		;クイックイミディエイトへの変換を禁止
	st.b	(NONULDISP,a6)		;ディスプレースメントの削除を禁止
	st.b	(NOBRACUT,a6)		;分岐命令の削除を禁止
;拡張された最適化を禁止
option_c_exoff:
	clr.b	(OPTCLR,a6)		;CLRを最適化する
	clr.b	(OPTMOVEA,a6)		;MOVEAを最適化する
	clr.b	(OPTADDASUBA,a6)	;ADDA/CMPA/SUBAを最適化する
	clr.b	(OPTCMPA,a6)		;ADDA/CMPA/SUBAを最適化する
	clr.b	(OPTLEA,a6)		;LEAを最適化する
	clr.b	(OPTASL,a6)		;ASLを最適化する
	clr.b	(OPTCMP0,a6)		;CMP.bwl #0,Dn→TST.bwl Dn
	clr.b	(OPTMOVE0,a6)		;MOVE.bw #0,Dn→CLR.bw Dn
	clr.b	(OPTCMPI0,a6)		;CMPI.bwl #0,<ea>→TST.bwl <ea>
	clr.b	(OPTSUBADDI0,a6)	;ADDI/SUBI #d3,<ea>→ADDQ/SUBQ #d3,<ea>
	clr.b	(OPTBSR,a6)		;直後へのbsrをpeaにする
	clr.b	(OPTJMPJSR,a6)		;jmp/jsrを最適化する
	rts

option_c_x::
	tst.b	(a0)
	beq	option_c_2
option_c_x0:
	movea.l	(LINEBUFPTR,a6),a1
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
	movea.l	(LINEBUFPTR,a6),a1
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
	move.w	#$ff00,d0		;moveq.l #-1,d0は不可
	;厳密には C000|C020|C030|C040|C060 だと思うが、ほかの st.b と揃えている
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
	cmp.b	#',',d0
	beq	option_c_x0
	tst.b	-(a0)			;読んだ文字が=や,ではなくNULなら、リターン後に
	bne	usage			;スイッチ列の終了として扱われるようにa0をNULに戻す
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
	clr.b	(PCTOABSLNOTALL,a6)
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
	clr.b	(LONGABS,a6)
	clr.b	(BRATOJBRA,a6)
	rts

option_b1:
	bsr	option_b4_0
	bsr	option_b1_1
option_b2_0:
	clr.b	(PCTOABSL,a6)
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
	bsr	getcmdstring
	bsr	getcmdnum
	bmi	usage

	bsr	cputype_convert
	bmi	usage			;その他の数値はエラーにする
	move.l	d1,(ICPUNUMBER,a6)
	rts

;----------------------------------------------------------------
;	-j[n]
option_j:
	bsr	getcmdnum
	bpl	option_j_1
option_j_all:
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
	clr.b	(IGNORE_ERRATA,a6)
	clr.b	(OPTIMIZE,a6)
	rts

option_k_1:
	st.b	(IGNORE_ERRATA,a6)
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
	clr.b	(PREDEFINE,a6)
	rts

;----------------------------------------------------------------
;	-_		外部定義・外部参照シンボルの先頭に'_'を挿入する

option_underscore:
	move.b	#'_',(LEADINGSYMCHAR,a6)
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

;----------------------------------------------------------------
;	コマンドラインから文字列を得る
@@:
	addq.l	#1,a0			;次の引数を返す
	cmpa.l	a5,a0
	bcc	usage
getcmdstring:
	tst.b	(a0)
	beq	@b
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
@@:	cmp.b	#'.',(a1)		;ドットファイル(.foo)の先頭の.を
	bne	@f			;拡張子として扱わない
	move.b	(a1)+,(a0)+
	bra	@b
@@:
	move.b	(a1)+,d0
	beq	tfrfilename9
	cmp.b	#'.',d0
	beq	tfrfilename9
	move.b	d0,(a0)+
	bra	@b

tfrfilename9:
	clr.b	(a0)
	move.l	(sp)+,a1
	rts

;----------------------------------------------------------------
;	コマンドラインのエラー
multifile:
	pea	(multifile_msg,pc)
	bra	error

;----------------------------------------------------------------
;	オプションスイッチで割り当てられていない文字

option_h:
option_r:
option_v:
option_z:
	bra	usage

;----------------------------------------------------------------
;	使用法を表示して終了する
usage:
	pea	(usage_msg,pc)
error:
	lea.l	(title_msg,pc),a0
	bsr	printmsg
	movea.l	(sp)+,a0
	bsr	printmsg
	move.w	#1,-(sp)
	DOS	_EXIT2


;----------------------------------------------------------------
	.bss

	.quad
WORKBEGIN::	.ds.b	WORKSIZE	;ワークエリア本体


;----------------------------------------------------------------
;	スタックエリア
;----------------------------------------------------------------

	.stack

	.quad
	.ds.b	4096			;スタックエリア
STACKBTM::


;----------------------------------------------------------------
	.end	asmmain
