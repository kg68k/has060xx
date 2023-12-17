;----------------------------------------------------------------
;	X68k High-speed Assembler
;		実行命令のアセンブル処理
;		< doasm.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2023  by M.Kamada
;			  2023       by TcbnErik
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
;	d1.wのレジスタ番号を命令コードのフィールドb2-b0にセット
SETREGL	.macro
	and.w	#$0007,d1
	or.w	d1,d7
	.endm

;----------------------------------------------------------------
;	d1.wのレジスタ番号を命令コードのフィールドb11-b9にセット
SETREGH	.macro
	and.w	#$0007,d1
	ror.w	#7,d1
	or.w	d1,d7
	.endm

;----------------------------------------------------------------
;	d7.wの命令コードを出力する
OPOUT	.macro
	move.w	d7,d0
	bsr	wrt1wobj
	.endm

;----------------------------------------------------------------
;	d7.wの命令コードを出力する(実効アドレス書き換え用)
DSPOPOUT	.macro
	tst.b	(DSPADRCODE,a6)
	beq	@skip1			;(d,An)/(d,PC)ではない
	move.w	#T_DSPCODE,d0
	bsr	wrtobjd0w
	move.w	d7,d0
	bsr	wrtd0w
	addq.l	#2,(LOCATION,a6)
	bra	@skip2
@skip1:
	move.w	d7,d0
	bsr	wrt1wobj
@skip2:
	.endm

;----------------------------------------------------------------
;	d7.wの命令コードを出力する+rts
OPOUTrts	.macro
	move.w	d7,d0
	bra	wrt1wobj
	.endm

;----------------------------------------------------------------
;	オペランドの区切りをチェックする
CHKLIM	.macro
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	iloprerr
	.endm


;----------------------------------------------------------------
;	パス1(命令のアセンブル)
;----------------------------------------------------------------
asmpass1::
	move.b	#1,(ASMPASS,a6)
	lea.l	(TEMPFILPTR,a6),a0
	move.l	a0,(OUTFILPTR,a6)
	bsr	maketmpname		;テンポラリファイル作成準備
	bsr	createopen		;テンポラリファイルをオープンする
	bsr	setsymdebfile		;'-g'スイッチ指定時のファイル名準備

	sf.b	(ISASMEND,a6)
	clr.l	(LINENUM,a6)
	sf.b	(ISOBJOUT,a6)
	clr.w	(OBJCONCTR,a6)
	sf.b	(ISIFSKIP,a6)

	clr.w	(IFNEST,a6)
	clr.w	(INCLDNEST,a6)
	clr.w	(MACNEST,a6)
	clr.w	(MACREPTNEST,a6)
	clr.w	(MACLOCSMAX,a6)
	clr.w	(SCDATTRIB,a6)		;(SCDATTRIB & SCDATRPREV)
	clr.w	(SCDLN,a6)
	sf.b	(ISMACDEF,a6)

	move.l	(TEMPPTR,a6),d0		;数字ローカルラベルの番号のテーブルを初期化
	doquad	d0
	movea.l	d0,a0
	move.w	(LOCALNUMMAX,a6),d1	;必ず偶数
	add.w	d1,d1
	lea.l	(a0,d1.w),a1
	move.l	a1,(TEMPPTR,a6)
	bsr	memcheck
	move.l	a0,(LOCALMAXPTR,a6)
	moveq.l	#0,d0
	lsr.w	#2,d1
	subq.w	#1,d1
asmpass101:
	move.l	d0,(a0)+
	dbra	d1,asmpass101

	bsr	resetlocctr		;ロケーションカウンタの初期化

	moveq.l	#-1,d0
	move.l	d0,(LASTSYMLOC,a6)

	move.l	sp,(SPSAVE,a6)
	lea.l	(asm1loop9,pc),a0
	move.l	a0,(ERRRET,a6)

	move.l	(ICPUNUMBER,a6),d1
	bsr	cputype_update
	bra	asm1loop9

asm1loop:
	or.w	#T_LINE,d0
	bsr	wrtobjd0w		;1行開始
	move.l	(LOCATION,a6),(LTOPLOC,a6)
	bsr	encodeline		;命令・オペランドのコード化
	bsr	asmline			;命令のアセンブル
	bsr	deflabel		;必要ならラベルを定義する
asm1loop9:
	bsr	getline			;1行読み込み
	tst.w	d0
	bpl	asm1loop

	lea.l	(asm1loop91,pc),a0
	move.l	a0,(ERRRET,a6)
	move.w	(IFNEST,a6),d0
	clr.w	(IFNEST,a6)
	tst.w	d0
	bne	misiferr_eof		;.ifの途中でソースが終了した
asm1loop91:

	lea.l	(asm1loop92,pc),a0
	move.l	a0,(ERRRET,a6)
	bsr	offsymtailchk		;offsymが正常に終了しているかどうか確認する
					;a1を破壊する
asm1loop92:

	moveq.l	#SECT_TEXT,d0
	bsr	chgsection		;.textセクションに戻す
	clr.w	d0			;move.w #T_EOF,d0
	bsr	wrtobjd0w		;ファイル終了
	lea.l	(TEMPFILPTR,a6),a1
	bsr	fflush			;テンポラリファイルをフラッシュする
	rts


;----------------------------------------------------------------
;	1命令アセンブル
;----------------------------------------------------------------
asmline::
	clr.w	(DSPADRCODE,a6)		;(DSPADRCODE & DSPADRDEST)

	move.l	(CMDTBLPTR,a6),(ERRMESSYM,a6)	;エラーメッセージに埋め込むシンボル
						;(0の場合もある)

	tst.b	(ISMACRO,a6)
	bne	domacro			;マクロ命令

	move.l	(CMDTBLPTR,a6),d0
	beq	asmline9		;命令がない
	movea.l	d0,a1

	tst.w	(SYM_ARCH,a1)		;命令のCPUタイプ
	beq	dopseudo		;0なら疑似命令

	tst.b	(SYM_NOOPR,a1)
	bne	asmline1		;オペランドを取らない命令

	move.l	a1,-(sp)
	movea.l	(LINEPTR,a6),a0
	bsr	encodeopr
	move.l	(sp)+,a1

asmline1:
	btst.b	#0,(LOCATION+3,a6)
	beq	asmline2
	bsr	alignwarn_op		;偶数境界に合っていないのでワーニングを出す

asmline2:
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(EABUF1,a6),a4
	lea.l	(EABUF2,a6),a5

	move.w	(SYM_OPCODE,a1),d7	;命令コード基本パターン
	move.l	(SYM_FUNC,a1),a2
	clr.w	(SOFTFLAG,a6)
	clr.b	(ABSLTOOPCCAN,a6)
	sf.b	(PCTOABSLCAN,a6)
	jsr	(a2)			;処理ルーチンへジャンプ
asm1skipbase:
	tst.w	(a0)
	bne	asm1toomanyopr		;行が終了していない

asm1skipofst	equ	(*)-asm1skipbase
;ここではa0を破壊してよい
;F43G対策
	tst.b	(F43GTEST,a6)
	beq	asm1nofp
;5番目の命令ならば1番目に付けたNOPを有効にする
	movea.l	(F43GPTR,a6),a0
	btst.b	#4,(12,a0)		;5番目の命令か?
	beq	asm1notfifth
	movea.l	(a0),a0			;1番目
;一致したのでT_NOPDEATHをT_NOPALIVEに変更する
	movem.l	d1/a1,-(sp)
	move.w	#T_NOPALIVE+1,d0
	move.l	(8,a0),d1		;T_NOPDEATHの位置
	lea.l	(TEMPFILPTR,a6),a1
	bsr	fmodifyw
	movem.l	(sp)+,d1/a1
	movea.l	(F43GPTR,a6),a0
asm1notfifth:
;<a0.l:F43GPTR(a6)
;次のレコードを用意する
	movea.l	(a0),a0			;次のレコード
	move.l	a0,(F43GPTR,a6)
;	clr.l	8(a0)
	clr.w	(12,a0)
asm1nofp:

asmline9:
	rts

asm1toomanyopr:
	cmpi.w	#','|OT_CHAR,(a0)
	beq	iloprerr_too_many	;引数が多すぎる
	bra	iloprerr		;tst (0,a0)+などの不正なオペランド


;----------------------------------------------------------------
;	実効アドレスデータの出力
;----------------------------------------------------------------

;----------------------------------------------------------------
;	実効アドレスに必要なデータを出力する
;	in :a1=実効アドレス解釈バッファへのポインタ
;	out:---
eadataout:
	moveq.l	#0,d0
	move.b	(EADTYPE,a1),d0
	beq	ead_none
	add.w	d0,d0
	move.w	(eajmp_tbl,pc,d0.w),d0
	move.l	(RPNBUF1,a1),d1
	tst.w	(RPNLEN1,a1)
	jmp	(eajmp_tbl,pc,d0.w)

ead_none:
	rts

eajmp_tbl:
	.dc.w	ead_none-eajmp_tbl	;Dn/An
	.dc.w	ead_none-eajmp_tbl	;(An)/(An)+/-(An)
	.dc.w	ead_dspadr-eajmp_tbl	;(d,An)
	.dc.w	ead_idxadr-eajmp_tbl	;(d,An,Rn)
	.dc.w	ead_bdadr-eajmp_tbl	;(bd,An,Rn)
	.dc.w	ead_memadr-eajmp_tbl	;([bd,An,Rn],od)
	.dc.w	ead_dsppc-eajmp_tbl	;(d,PC)
	.dc.w	ead_idxpc-eajmp_tbl	;(d,PC,Rn)
	.dc.w	ead_bdpc-eajmp_tbl	;(bd,PC,Rn)
	.dc.w	ead_mempc-eajmp_tbl	;([bd,PC,Rn],od)
	.dc.w	ead_abslw-eajmp_tbl	;xxxx.l/xxxx.w
	.dc.w	ead_imm-eajmp_tbl	;#xxxx

;----------------------------------------------------------------
ead_dspadr:				;(d,An)
	bmi	ead_dspadr5
	move.w	#T_DSPADR,d0		;式の場合
	move.b	(DSPADRDEST,a6),d0	;(move デスティネーション対策)
ead_dspadr0:
	bsr	wrtobjd0w
	addq.l	#2,(LOCATION,a6)
	tst.b	(RPNSIZE1,a1)
	bmi	ead_dspadr1
	moveq.l	#SZ_WORD,d0		;(ワードディスプレースメント確定)
ead_outrpn:
	move.w	(RPNLEN1,a1),d1
	lea.l	(RPNBUF1,a1),a1
	bra	wrtrpn			;式を出力する

ead_dspadr1:				;(ディスプレースメントサイズ未定)
	moveq.l	#SZ_WORD|ESZ_OPT,d0	;(最適化対象)
	tst.b	(EXTSIZEFLG,a6)
	beq	ead_outrpn
	moveq.l	#SZ_LONG|ESZ_OPT,d0	;(最適化対象)
	addq.l	#4,(LOCATION,a6)	;デフォルトが.lなら2+4バイト
	bra	ead_outrpn

ead_dspadr5:				;定数の場合(ワードディスプレースメント確定)
	move.l	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	beq	wrt1wobj		;-$8000～$7FFF
	cmp.l	#$00010000,d1
	bcc	ilrelerr_outside	;$10000以上
	bsr	shvalwarn_d16		;$8000～$FFFF
	bra	wrt1wobj

;----------------------------------------------------------------
ead_idxadr:				;(d,An,Rn)
	bmi	ead_idxadr5
	move.w	#T_IDXADR,d0		;式の場合
ead_idxadr0:
	bsr	wrtobjd0w
	addq.l	#2,(LOCATION,a6)
	move.w	(EXTCODE,a1),d0
	bsr	wrtd0w			;拡張ワード
	tst.b	(RPNSIZE1,a1)
	bmi	ead_idxadr1
	moveq.l	#SZ_SHORT,d0		;(ショートディスプレースメント確定)
	bra	ead_outrpn

ead_idxadr1:				;(ディスプレースメントサイズ未定)
	moveq.l	#SZ_SHORT|ESZ_OPT,d0	;(最適化対象)
	tst.b	(EXTSIZEFLG,a6)
	beq	ead_outrpn		;-eスイッチなしの場合のデフォルトは.s
	moveq.l	#SZ_LONG|ESZ_OPT,d0	;(最適化対象)
	add.l	#4,(LOCATION,a6)
	bra	ead_outrpn

ead_idxadr5:				;定数の場合(ショートディスプレースメント確定)
	move.l	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d1,d0
	beq	ead_idxadr6		;-$80～$7F
	cmp.l	#$00000100,d1
	bcc	ilrelerr_outside	;$100以上
	bsr	shvalwarn_d8		;$80～$FF
ead_idxadr6:
	and.w	#$00FF,d0
	or.w	(EXTCODE,a1),d0		;ディスプレースメントを拡張ワードと合成
	bra	wrt1wobj

;----------------------------------------------------------------
ead_bdadr:				;(bd,An,Rn)
	move.w	#T_EXTCODE,d0
	bsr	wrtobjd0w
	move.w	(EXTCODE,a1),d0
	bsr	wrtd0w			;拡張ワード
	addq.l	#2,(LOCATION,a6)

	tst.w	(RPNLEN1,a1)
	bmi	ead_bdadr5
	beq	ead_bdadr9		;ベースディスプレースメントがない
	move.w	#T_BDADR,d0		;式の場合
ead_bdadr0:
	bsr	wrtobjd0w
	move.b	(RPNSIZE1,a1),d0
	bmi	ead_bdadr1
	bsr	getdtsize		;(ディスプレースメントサイズ指定あり)
	add.l	d0,(LOCATION,a6)
	move.b	(RPNSIZE1,a1),d0
	bra	ead_outrpn		;(ワード or ロングワード)

ead_bdadr1:				;(ディスプレースメントサイズ未定)
	move.l	(EXTLEN,a6),d0
	add.l	d0,(LOCATION,a6)
	move.b	(EXTSIZE,a6),d0
	or.b	#ESZ_OPT,d0		;(最適化対象)
	bra	ead_outrpn

ead_bdadr5:				;定数の場合
	cmpi.b	#SZ_WORD,(RPNSIZE1,a1)
	beq	ead_dspadr5		;ワードディスプレースメント
	move.l	d1,d0
	bra	wrt1lobj

ead_bdadr9:
	rts

;----------------------------------------------------------------
ead_memadr:				;([bd,An,Rn],od)
	move.l	a1,-(sp)
	bsr	ead_bdadr		;ベースディスプレースメントの処理
ead_memadr0:
	movea.l	(sp)+,a1
	tst.w	(RPNLEN2,a1)
	bmi	ead_memadr5
	beq	ead_memadr9		;アウタディスプレースメントがない
	move.w	#T_OD,d0		;式の場合
	bsr	wrtobjd0w
	move.b	(RPNSIZE2,a1),d0
	bmi	ead_memadr1
	bsr	getdtsize		;(ディスプレースメントサイズ指定あり)
	add.l	d0,(LOCATION,a6)
	move.b	(RPNSIZE2,a1),d0	;(ワード or ロングワード)
ead_outodrpn:
	move.w	(RPNLEN2,a1),d1
	lea.l	(RPNBUF2,a1),a1
	bra	wrtrpn			;式を出力する

ead_memadr1:				;(ディスプレースメントサイズ未定)
	move.l	(EXTLEN,a6),d0
	add.l	d0,(LOCATION,a6)
	move.b	(EXTSIZE,a6),d0
	or.b	#ESZ_OPT,d0		;(最適化対象)
	bra	ead_outodrpn

ead_memadr5:				;定数の場合
	move.l	(RPNBUF2,a1),d1
	cmpi.b	#SZ_WORD,(RPNSIZE2,a1)
	beq	ead_dspadr5		;ワードディスプレースメント
	move.l	d1,d0
	bra	wrt1lobj

ead_memadr9:
	rts

;----------------------------------------------------------------
ead_dsppc:				;(d,PC)
	bmi	ead_dsppc5
	move.w	#T_DSPPC,d0		;式の場合
	tst.b	(OPTIONALPC,a1)
	beq	ead_dspadr0
	move.w	#T_DSPOPC,d0		;(絶対ロングへの変換可能なPC)
	bsr	wrtobjd0w
	addq.l	#2,(LOCATION,a6)
	moveq.l	#SZ_WORD|ESZ_OPT,d0	;(最適化対象)
	tst.b	(EXTSHORT,a6)		;(68000/68010でも有効)
	beq	ead_outrpn
	moveq.l	#SZ_LONG|ESZ_OPT,d0	;(最適化対象)
	addq.l	#2,(LOCATION,a6)	;デフォルトが.lなら4バイト
	bra	ead_outrpn

ead_dsppc5:				;定数の場合
	move.l	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	bne	ilrelerr_outside
	bra	wrt1wobj		;-$8000～$7FFF

;----------------------------------------------------------------
ead_idxpc:				;(d,PC,Rn)
	bmi	ead_idxpc5
	move.w	#T_IDXPC,d0		;式の場合
	bra	ead_idxadr0

ead_idxpc5:				;定数の場合
	move.l	d1,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d1,d0
	bne	ilrelerr_outside
	and.w	#$00FF,d0		;-$80～$7F
	or.w	(EXTCODE,a1),d0		;ディスプレースメントを拡張ワードと合成
	bra	wrt1wobj

;----------------------------------------------------------------
ead_bdpc:				;(bd,PC,Rn)
	move.w	(EXTCODE,a1),d0
	andi.w	#EXW_BS,d0
	bne	ead_bdadr		;ZPCはAnと同じ扱い

	move.w	#T_EXTCODE,d0
	bsr	wrtobjd0w
	move.w	(EXTCODE,a1),d0
	bsr	wrtd0w			;拡張ワード
	addq.l	#2,(LOCATION,a6)

	tst.w	(RPNLEN1,a1)
	bmi	ead_bdpc5
	beq	ead_bdpc9		;ベースディスプレースメントがない
	move.w	#T_BDPC,d0		;式の場合
	bra	ead_bdadr0

ead_bdpc5:				;定数の場合
	cmpi.b	#SZ_WORD,(RPNSIZE1,a1)
	beq	ead_dsppc5		;ワードディスプレースメント
	move.l	d1,d0
	bra	wrt1lobj

ead_bdpc9:
	rts

;----------------------------------------------------------------
ead_mempc:				;([bd,PC,Rn],od)
	move.l	a1,-(sp)
	bsr	ead_bdpc		;ベースディスプレースメントの処理
	bra	ead_memadr0

;----------------------------------------------------------------
ead_abslw:				;xxxx.l/xxxx.w
	bmi	ead_abslw5
	cmpi.b	#SZ_WORD,(RPNSIZE1,a1)	;式の場合
	beq	ead_abslw1
	addq.l	#4,(LOCATION,a6)	;絶対ロング
	moveq.l	#ESZ_ABS|SZ_LONG,d0
	bra	ead_outrpn

ead_abslw1:				;絶対ショート
	addq.l	#2,(LOCATION,a6)
	moveq.l	#ESZ_ABS|SZ_WORD,d0
	bra	ead_outrpn

ead_abslw5:				;定数の場合
	cmpi.b	#SZ_WORD,(RPNSIZE1,a1)
	beq	ead_abslw6
	bsr	abswarn			;絶対ロング
	move.l	d1,d0
	bra	wrt1lobj

ead_abslw6:				;絶対ショート
	move.l	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	beq	ead_abslw7		;-$8000～$7FFF
	cmp.l	#$00010000,d1
	bcc	ilvalueerr		;$10000以上
	bsr	shvalwarn_absw		;$8000～$FFFF
ead_abslw7:
	bsr	absshwarn
	bra	wrt1wobj

;----------------------------------------------------------------
ead_imm0:
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	ead_imm01
	tst.b	(EAIMMCNT,a1)		;(cmpi.b #1-1,(EAIMMCNT,a1))
	bne	iloprerr		;.lでオペランドが2つ以上あればエラー
ead_imm01:
	tst.w	(RPNLEN1,a1)
ead_imm:				;#xxxx
	bmi	ead_imm5
	move.b	(CMDOPSIZE,a6),d0	;式の場合
	cmp.b	#SZ_LONG,d0
	bne	ead_imm1
	addq.l	#2,(LOCATION,a6)	;.l
ead_imm1:
	addq.l	#2,(LOCATION,a6)	;.b/.w
	bra	ead_outrpn

ead_imm5:				;定数の場合
	move.b	(CMDOPSIZE,a6),d0
	bra	wrtimm			;データを出力する

;----------------------------------------------------------------
;5番目のチェック
;ソフトウェアエミュレーションはあらかじめ弾いておくこと
;<EACODE(a1):モード*8+レジスタ
f43g_fifth::
	cmpi.w	#%010_000,(EACODE,a1)
	blo	f43g_fifth1
	cmpi.w	#%110_111,(EACODE,a1)
	bhi	f43g_fifth1
;アドレッシングモードチェックなし
f43g_fifthadr::
	tst.b	(F43GTEST,a6)
	beq	f43g_fifth1
;any form of address register indirect addressing mode
	move.l	a0,-(sp)
	movea.l	(F43GPTR,a6),a0
	movea.l	(4,a0),a0		;直前のレコード
	btst.b	#3,(12,a0)
	beq	f43g_fifth2		;直前が4番目ではない
	movea.l	(4,a0),a0		;3番目のレコード
	move.w	(EACODE,a1),d0		;今回のレジスタ番号(下位3ビット)
	btst.b	d0,(13,a0)		;3番目のレジスタ番号と比較
	beq	f43g_fifth2		;レジスタ番号が異なる
	movea.l	(F43GPTR,a6),a0
	or.b	#%10000,(12,a0)		;5番目に該当する
;	bset.b	d0,13(a0)		;レジスタ番号(不要)
f43g_fifth2:
	movea.l	(sp)+,a0
f43g_fifth1:
	rts

;----------------------------------------------------------------
;4番目と5番目のチェック
;<d7.w:浮動小数点命令コード(下位6ビットがモードとレジスタ)
f43g_fourth::
	tst.b	(F43GTEST,a6)
	beq	f43g_fourth1
	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	f43g_fourth1
	moveq.l	#%111_111,d0
	and.w	d7,d0			;アドレッシングモード
	cmp.w	#%010_000,d0
	blo	f43g_fourth1
	cmp.w	#%110_111,d0
	bhi	f43g_fourth1
;any form of address register indirect addressing mode
	move.l	a0,-(sp)
	movea.l	(F43GPTR,a6),a0
	movea.l	(4,a0),a0		;直前のレコード
	moveq.l	#%01100,d0
	and.b	(12,a0),d0
	beq	f43g_fourth2		;直前が3番目と4番目のいずれでもない
	movea.l	(4,a0),a0		;2つ前のレコード
	btst.b	d7,(13,a0)		;2つ前のレジスタ番号と比較
	beq	f43g_fourth2		;レジスタ番号が異なる
	movea.l	(F43GPTR,a6),a0
	add.b	d0,d0
	or.b	d0,(12,a0)		;4番目または5番目に該当する
;	bset.b	d7,13(a0)		;レジスタ番号(不要)
f43g_fourth2:
	movea.l	(sp)+,a0
f43g_fourth1:
	rts

;----------------------------------------------------------------
;	浮動小数点実効アドレスに必要なデータを出力する
;	in :a1=実効アドレス解釈バッファへのポインタ
;	out:---
fpeadataout:
;d7.wにDSPOPOUTで出力した命令コード(1ワード目)が残っていること
	bsr	f43g_fourth		;4番目のチェック
	moveq.l	#0,d0
	move.b	(EADTYPE,a1),d0
	beq	fpead_reg		;レジスタ直接
	add.w	d0,d0
	move.w	(fpeajmp_tbl,pc,d0.w),d0
	move.l	(RPNBUF1,a1),d1
	tst.w	(RPNLEN1,a1)
	jmp	(fpeajmp_tbl,pc,d0.w)

fpeajmp_tbl:
	.dc.w	fpead_reg-fpeajmp_tbl	;Dn/An
	.dc.w	ead_none-fpeajmp_tbl	;(An)/(An)+/-(An)
	.dc.w	ead_dspadr-fpeajmp_tbl	;(d,An)
	.dc.w	ead_idxadr-fpeajmp_tbl	;(d,An,Rn)
	.dc.w	ead_bdadr-fpeajmp_tbl	;(bd,An,Rn)
	.dc.w	ead_memadr-fpeajmp_tbl	;([bd,An,Rn],od)
	.dc.w	ead_dsppc-fpeajmp_tbl	;(d,PC)
	.dc.w	ead_idxpc-fpeajmp_tbl	;(d,PC,Rn)
	.dc.w	ead_bdpc-fpeajmp_tbl	;(bd,PC,Rn)
	.dc.w	ead_mempc-fpeajmp_tbl	;([bd,PC,Rn],od)
	.dc.w	ead_abslw-fpeajmp_tbl	;xxxx.l/xxxx.w
	.dc.w	fpead_imm-fpeajmp_tbl	;#xxxx

;----------------------------------------------------------------
fpead_reg:				;Dn/An
	cmpi.b	#SZ_SHORT,(CMDOPSIZE,a6)
	bhi	ilsizeerr		;サイズが.d/.x/.p/省略ならエラー
	rts

;----------------------------------------------------------------
fpead_imm:				;#xxxx 浮動小数点データを出力する
	move.b	(CMDOPSIZE,a6),d0
	cmp.b	#SZ_SINGLE,d0
	bcs	ead_imm0		;扱うデータが整数の場合
	bsr	getfplen		;データ長を得る
	move.w	d1,d3			;データ長-1
	move.b	(EAIMMCNT,a1),d0
	bmi	fpead_imm2		;浮動小数点実数表記の場合
	cmp.b	d3,d0
	bne	iloprerr_internalfp2	;浮動小数点数の内部表現の長さが合いません
fpead_imm2:
;#xxxxでサイズが.xまたは.pのときソフトウェアエミュレーション
	cmp.b	#2,d3
	bne	fpead_imm3
	move.w	(CPUTYPE,a6),d0
	and.w	#C040|C060,d0
	beq	fpead_imm4
	and.w	(SOFTFLAG,a6),d0
	bne	fpead_imm4
	bsr	softwarn
fpead_imm4:
	ori.w	#C040|C060,(SOFTFLAG,a6)
fpead_imm3:
	movea.l	a1,a2
	lea.l	(RPNBUF1,a2),a1
	bsr	fpead_immout		;.s/.d/.x/.p
	subq.b	#1,d3
	bcs	fpead_imm9
	lea.l	(RPNBUF2,a2),a1
	bsr	fpead_immout		;.d/.x/.p
	subq.b	#1,d3
	bcs	fpead_imm9
	lea.l	(RPNBUFEX,a6),a1
	bra	fpead_immout		;.x/.p

fpead_imm9:
	rts

fpead_immout:
	move.w	(RPNLEN1-RPNBUF1,a1),d1
	bmi	fpead_immout5
	addq.l	#4,(LOCATION,a6)	;式の場合
	moveq.l	#SZ_LONG,d0
	bra	wrtrpn

fpead_immout5:				;定数の場合
	move.l	(a1),d0
	bra	wrt1lobj


;----------------------------------------------------------------
;	テンポラリデータの出力
;----------------------------------------------------------------

;----------------------------------------------------------------
;	テンポラリにイミディエイトデータオブジェクトを出力する
;	in :d0.b=サイズ/d1.l=データ
;	out:---
wrtimm::
	move.b	d0,d2
	bsr	chkdtsize
	move.l	d1,d0
	cmp.b	#SZ_SHORT,d2
	beq	wrt1bobj		;.s
	cmp.b	#SZ_LONG,d2
	bne	wrt1wobj		;.b/.w
	bra	wrt1lobj		;.l

;----------------------------------------------------------------
;	データが各サイズの範囲内かどうかを調べる
;	in :d1.l=データ/d2.b=サイズ
;	out:---
chkdtsize::
	and.b	#$03,d2
	move.l	d1,d0
	cmp.b	#SZ_LONG,d2
	beq	chkdtsize2		;.l
	cmp.b	#SZ_WORD,d2
	beq	chkdtsize1		;.w
	ext.w	d0			;.b/.s(実際には.dc.bで使用される)
	ext.l	d0
	cmp.l	d1,d0
	beq	chkdtsize2		;-$80～$7F
	cmp.l	#$00000100,d1
	bcc	overflowerr		;$100以上
	rts

chkdtsize1:				;.w
	ext.l	d0
	cmp.l	d1,d0
	beq	chkdtsize2		;-$8000～$7FFF
	cmp.l	#$00010000,d1
	bcc	overflowerr		;$10000以上
chkdtsize2:
	rts

;----------------------------------------------------------------
;	逆ポーランド式をファイルに出力する
;	in :a1=逆ポーランド式へのポインタ
;	    d0.b=値のサイズ/d1.w=逆ポーランド式のワード数
;	out:---
wrtrpn::
	and.w	#$00FF,d0
	cmp.w	#3,d1
	bne	wrtrpn1
	cmp.w	#RPN_SYMBOL,(a1)
	bne	wrtrpn1
	or.w	#T_SYMBOL,d0		;シンボルのみの場合
	bsr	wrtobjd0w
	move.l	(2,a1),d0		;シンボルへのポインタ
	bra	wrtd0l

wrtrpn1:				;逆ポーランド式を出力
	or.w	#T_RPN,d0
	bsr	wrtobjd0w
	subq.w	#1,d1			;(エンドコード$0000は出力しない)
	move.w	d1,d0
	bsr	wrtd0w			;式の長さ
wrtrpn2:
	move.w	(a1)+,d0
	bsr	wrtd0w
	dbra	d1,wrtrpn2
	rts

;----------------------------------------------------------------
;	命令のオペレーションサイズを得る
getopsize:
	moveq.l	#0,d0
	move.b	(CMDOPSIZE,a6),d0
	bpl	getopsize9
	moveq.l	#SZ_WORD,d0		;省略時は.w
	move.b	d0,(CMDOPSIZE,a6)
getopsize9:
	rts

;----------------------------------------------------------------
;	オペレーションサイズを命令コードのフィールドb7-b6にセット
setopsize:
	moveq.l	#0,d0
	move.b	(CMDOPSIZE,a6),d0
	bpl	setopsize9
	moveq.l	#SZ_WORD,d0		;省略時は.w
	move.b	d0,(CMDOPSIZE,a6)
setopsize9:
	ror.b	#2,d0
	or.w	d0,d7
	rts

;----------------------------------------------------------------
;	浮動小数点オペレーションサイズをコプロセッサ命令ワードにセット
setfpopsize:
	moveq.l	#0,d0
	move.b	(CMDOPSIZE,a6),d0
	bpl	setfpopsize9
	moveq.l	#SZ_EXTEND,d0		;省略時は.x
	move.b	d0,(CMDOPSIZE,a6)
setfpopsize9:
	add.w	d0,d0
	or.w	(setfpop_tbl,pc,d0.w),d6
;.pは68040,68060ではソフトウェアエミュレーション
	cmpi.b	#SZ_PACKED,(CMDOPSIZE,a6)
	bne	setfpopsize10
	ori.w	#C040|C060,(SOFTFLAG,a6)
setfpopsize10:
	rts

setfpop_tbl:				;サイズコードテーブル
	.dc.w	$1800,$1000,$0000,$0400,$1400,$0800,$0C00


;----------------------------------------------------------------
;	命令のアセンブル処理
;----------------------------------------------------------------

;----------------------------------------------------------------
;	illegal/nop/reset/rte/rtr/rts/trapv	(オペランドを持たない命令)
~noopr::
	OPOUT
	addq.l	#asm1skipofst,(sp)	;行末のチェックは行わない
	rts

;----------------------------------------------------------------
;	ext	Dn
~ext::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	bsr	getopsize		;サイズを得る
	addq.w	#1,d0
	ror.b	#2,d0
	or.w	d0,d7			;b8-b6:.w=%010/.l=%011
	OPOUTrts

;----------------------------------------------------------------
;	extb	Dn
~extb::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
;	swap	Dn
~swap::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
;	unlk	An
~unlk::
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
;	exg	Rn,Rn
~exg::
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	move.w	d1,d6
	CHKLIM
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	cmpi.w	#REG_A0,d6
	bcc	~exg1
	cmpi.b	#REG_A0,d1
	bcc	~exg3
	or.w	#$0040,d7		;Dn,Dn
	bra	~exg9

~exg1:
	cmpi.b	#REG_A0,d1
	bcs	~exg2
	or.w	#$0048,d7		;An,An
	bra	~exg9

~exg2:					;An,Dn
	exg.l	d1,d6
~exg3:					;Dn,An
	or.w	#$0088,d7
~exg9:
	SETREGL
	move.w	d6,d1
	SETREGH
	OPOUTrts

;----------------------------------------------------------------
;	or/and	Dn,<ea>/<ea>,Dn
~orand::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	move.w	d0,d6
	and.w	#EG_DATA,d0		;データモード
	beq	iladrerr
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bne	~orand5
	SETREGH				;<ea>,Dn
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	DSPOPOUT
	bra	eadataout

~orand5:
	cmp.w	#EA_IMM,d6		;#xx,<ea>
	beq	~orand_i
	cmp.w	#EA_DN,d6
	bne	iladrerr
	ori.w	#$0100,d7		;Dn,<ea>
	move.w	(EACODE,a1),d1
	SETREGH
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~orand_i:				;or/and #xx,<ea> → ori/andi
	lsr.w	#5,d7
	andi.w	#$0200,d7
	bra	~orandeori1

;----------------------------------------------------------------
;	eor	Dn,<ea>
~eor::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~eor_i
	SETREGH
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~eor_i:					;eor #xx,<ea> → eori
	move.w	#$0A00,d7
;	bra	~orandeori

;----------------------------------------------------------------
;	ori/andi/eori	#xx,<ea>/#xx,CCR/#xx,SR
~orandeori::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
~orandeori1:
	move.w	(a0),d0
	cmp.w	#REG_CCR|OT_REGISTER,d0
	beq	~orandeori_ccr		;ori/andi/eori to CCR
	cmp.w	#REG_SR|OT_REGISTER,d0
	beq	~orandeori_sr		;ori/andi/eori to SR
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
;ori/andi/eori/or #imm/and #imm
	tst.b	(CPUTYPE2,a6)
	beq	~orandeori11
	and.w	#EA_DN,d0
	beq	iladrerr
~orandeori11:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	movea.l	a4,a1
	bsr	eadataout
	movea.l	a5,a1
	bra	eadataout

~orandeori_ccr:				;#xx,CCR
	move.b	(CMDOPSIZE,a6),d0
	bmi	~orandeori_ccr1		;サイズが省略された
;	cmp.b	#SZ_BYTE,d0		;上でd0.bにmove.bした直後なのでtst.bは不要
	bne	ilsizeerr_ccr
~orandeori_ccr1:
	clr.b	(CMDOPSIZE,a6)		;move.b #SZ_BYTE,(CMDOPSIZE,a6)
	tst.w	(RPNLEN1,a1)
	bpl	~orandeori_sr1		;定数でない
	move.w	#$00E0,d1		;未定義のビットが1
	cmp.w	#$0200,d7		;andi to ccr
	beq	~orandeori_sr04
	bra	~orandeori_sr03

~orandeori_sr:				;#xx,SR
	bsr	getopsize		;サイズを得る
	cmp.b	#SZ_WORD,d0
	bne	ilsizeerr_sr		;.wのみ
	ori.w	#$0040,d7
	tst.w	(RPNLEN1,a1)
	bpl	~orandeori_sr1		;定数でない
	move.w	#$08E0,d1		;未定義のビットが1
;000～010にはMがない
	move.w	#C020|C030|C040|C060|C520|C530|C540,d0
	and.w	(CPUTYPE,a6),d0
	bne	~orandeori_sr01
	or.w	#$1000,d1		;000～010にはMがない
~orandeori_sr01:
	and.w	#C020|C030|C040,d0
	bne	~orandeori_sr02
	or.w	#$4000,d1		;000～010と060とColdFireにはT0がない
~orandeori_sr02:
;d1.w:未定義のビットが1
	cmp.w	#$0240,d7		;andi to sr
	beq	~orandeori_sr04
~orandeori_sr03:
	and.w	(RPNBUF1+2,a1),d1
	beq	~orandeori_sr1
	bra	~orandeori_sr05

~orandeori_sr04:
	not.w	d1
	or.w	(RPNBUF1+2,a1),d1
	not.w	d1
	beq	~orandeori_sr1
~orandeori_sr05:
	bsr	insigbitwarn
~orandeori_sr1:
	ori.w	#EAC_IMM,d7
	addq.l	#2,a0
	OPOUT
	bra	eadataout

;----------------------------------------------------------------
;	cmpm	(An)+,(An)+
~cmpm::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_INCADR,d0
	bne	iladrerr		;(An)+でなければエラー
	CHKLIM
~cmpm1:
	movea.l	a5,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_INCADR,d0
	bne	iladrerr		;(An)+でなければエラー
	move.w	(EACODE,a4),d1
	SETREGL
	move.w	(EACODE,a5),d1
	SETREGH
	bsr	setopsize		;オペレーションサイズのセット
	movea.l	a4,a1
	bsr	f43g_fifthadr		;5番目のチェック
	movea.l	a5,a1
	bsr	f43g_fifthadr		;5番目のチェック
	OPOUTrts

;----------------------------------------------------------------
;	cmp	<ea>,Dn
~cmp::
;5200/5300はcmp.b/cmp.w/cmpa.w/cmpi.b/cmpi.w不可
	move.w	#C520|C530,d0
	and.w	(CPUTYPE,a6),d0
	beq	~cmp00
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	ilsizeerr_cf_long	;サイズ省略時もエラー
~cmp00:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	move.w	d0,d6			;(すべてのモード)
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~cmp_cnv
	SETREGH
	bsr	setopsize		;オペレーションサイズのセット
	tst.b	(OPTCMP0,a6)
	beq	~cmp99			;CMP#0の最適化に対応しない
	cmpi.w	#%111_100,(EACODE,a1)
	bne	~cmp99			;#immでないので最適化できない
	tst.b	(RPNSIZE1,a1)
	bpl	~cmp99			;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a1)
	bpl	~cmp99			;#immが定数でないので最適化できない
	tst.l	(RPNBUF1,a1)
	bne	~cmp99			;#immが0でないので最適化できない
	move.w	d7,d0
	and.w	#$00C0,d0		;サイズ
	and.w	#$0E00,d7		;レジスタ番号
	rol.w	#7,d7
	or.w	d7,d0
	or.w	#$4A00,d0		;TST.bwl Dn
	bra	wrt1wobj

~cmp99:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~cmp_cnv:				;cmp → cmpm/cmpa/cmpi
	bsr	getareg			;アドレスレジスタオペランドを得る
	beq	~cmp_a
	cmp.w	#EA_IMM,d6
	beq	~cmp_i
	cmp.w	#EA_INCADR,d6
	beq	~cmp_m
	bra	iladrerr

~cmp_a:					;cmp <ea>,An → cmpa
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	ilsizeerr_an		;.bならエラー
	move.w	#$B0C0,d7
	bra	~sbadcpa1

~cmp_i:					;cmp #xx,<ea> → cmpi
	move.w	#$0C00,d7
	bra	~cmpi1

~cmp_m:					;cmp (An)+,(An)+ → cmpm
	move.w	#$B108,d7
	bra	~cmpm1

;----------------------------------------------------------------
;	sub/add	Dn,<ea>/<ea>,Dn
~subadd::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	move.w	d0,d5
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	move.w	d0,d6
	cmp.w	#EA_IMM,d5
	beq	~subadd_q
~subadd1:
	cmp.w	#EA_DN,d6
	beq	~subadd5
	cmp.w	#EA_AN,d6
	beq	~subadd_a
	and.w	#EG_MEM&EG_ALT,d6	;メモリ・可変モード
	beq	iladrerr
	cmp.w	#EA_DN,d5
	bne	~subadd_i
	or.w	#$0100,d7		;Dn,<ea>
	move.w	(EACODE,a4),d1
	SETREGH
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~subadd5:				;<ea>,Dn
	move.w	(EACODE,a5),d1
	SETREGH
	bsr	setopsize		;オペレーションサイズのセット
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~subadd_q:				;#xx,<ea>
	tst.b	(NOQUICK,a6)
	bmi	~subadd1		;クイックイミディエイト変換はしない
	tst.w	(RPNLEN1,a4)
	bpl	~subadd1		;イミディエイト値が得られない
	tst.b	(RPNSIZE1,a4)
	bpl	~subadd1		;サイズが指定されている
	move.l	(RPNBUF1,a4),d0
	beq	~subadd1
	cmp.l	#8,d0
	bhi	~subadd1
	not.w	d7			;sub/add #1～8,<ea> → subq/addq
	lsr.w	#6,d7
	and.w	#$0100,d7
	or.w	#$5000,d7
	move.w	d6,d0
	bra	~subaddq1

~subadd_a:				;sub/add <ea>,An → suba/adda
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	ilsizeerr_an		;.bならエラー
	or.w	#$00C0,d7
	move.w	(EACODE,a5),d1
	movea.l	a4,a1
	bra	~sbadcpa1

~subadd_i:				;sub/add #xx,<ea> → subi/addi
	cmp.w	#EA_IMM,d5
	bne	iladrerr
	lsr.w	#5,d7
	and.w	#$0200,d7
	or.w	#$0400,d7
	move.w	d6,d0
	bra	~subaddi1

;----------------------------------------------------------------
;	suba/adda/cmpa	<ea>,An
;5200/5300はcmp.b/cmp.w/cmpa.w/cmpi.b/cmpi.w不可
~cmpa::
	move.w	#C520|C530,d0
	and.w	(CPUTYPE,a6),d0
	beq	~sbadcpa
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	ilsizeerr_cf_long	;サイズ省略時もエラー
;	bra	~sbadcpa

~sbadcpa::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	CHKLIM
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
~sbadcpa1:
	SETREGH
	cmpi.w	#%111_100,(EACODE,a1)
	bne	~sbadcpa199		;#immでないので最適化できない
	tst.b	(RPNSIZE1,a1)
	bpl	~sbadcpa199		;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a1)
	bpl	~sbadcpa199		;定数でないので最適化できない
	btst.l	#13,d7
	bne	~sbadcpa1cp		;CMPA
;ADDA/SUBA
	tst.b	(OPTADDASUBA,a6)
	beq	~sbadcpa199		;ADDA/SUBAの最適化に対応しない
	move.l	(RPNBUF1,a1),d0
	beq	~sbadcpa1zero		;imm=0
	btst.l	#14,d7
	beq	~sbadcpa1sb		;SUBA
;ADDA
~sbadcpa1ad:
	moveq.l	#8,d1
	cmp.l	d1,d0
	bgt	~sbadcpa1adw
	tst.l	d0
	bpl	~sbadcpa1adq
	moveq.l	#-8,d1
	cmp.l	d1,d0
	blt	~sbadcpa1adw
	neg.l	d0
;ADDA/SUBA→SUBQ
~sbadcpa1sbq:
	move.w	#$5148,d1		;SUBQ.W #imm,An
	bra	~sbadcpa1q

~sbadcpa1zero:
;imm=0
	rts

;ADDA.L #$00008000,An/SUBA.L #$FFFF8000,An→SUBA.W #$8000,An
~sbadcpa18000:
	and.w	#$0E00,d7
	move.w	d7,d0
	or.w	#$90FC,d0		;SUBA.W #imm,An
	bsr	wrt1wobj
	move.w	#$8000,d0
	bra	wrt1wobj

;ADDA→LEA
~sbadcpa1adw:
	move.l	(RPNBUF1,a1),d1
	bra	~sbadcpa1w

;SUBA→LEA
~sbadcpa1sbw:
	moveq.l	#0,d1
	sub.l	(RPNBUF1,a1),d1
;ADDA/SUBA→LEA
~sbadcpa1w:
;ADDA.L #32768,An → SUBA.W #-32768,An は可
;ADDA.W #32768,An → SUBA.W #-32768,An は不可
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~sbadcpa1w001
	cmp.l	#$00008000,d1
	beq	~sbadcpa18000
~sbadcpa1w001:
;ADDA.L #-32768,An → LEA.L (-32768,An),An は可
;ADDA.W #-32768,An → LEA.L (-32768,An),An は可
;SUBA.L #32768,An → LEA.L (-32768,An),An は可
;SUBA.W #32768,An → LEA.L (-32768,An),An は不可
	cmpi.l	#-32768,d1
	bne	~sbadcpa1w002
	btst.l	#14,d7
	bne	~sbadcpa1w002
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~sbadcpa199
~sbadcpa1w002:
	move.l	d1,d0
	ext.l	d1
	cmp.l	d0,d1
	bne	~sbadcpa199
	move.w	#$41E8,d0		;LEA.L (d16,An),An
	and.w	#$0E00,d7
	or.w	d7,d0
	rol.w	#7,d7
	or.w	d7,d0
	bsr	wrt1wobj
	move.w	d1,d0
	bra	wrt1wobj

~sbadcpa1sb:
;SUBA
	moveq.l	#8,d1
	cmp.l	d1,d0
	bgt	~sbadcpa1sbw
	tst.l	d0
	bpl	~sbadcpa1sbq
	moveq.l	#-8,d1
	cmp.l	d1,d0
	blt	~sbadcpa1sbw
	neg.w	d0
;ADDA/SUBA→ADDQ
~sbadcpa1adq:
	move.w	#$5048,d1		;ADDQ.W #imm,An
~sbadcpa1q:
	and.w	#$0007,d0		;8→0
	ror.w	#7,d0			;imm
	or.w	d1,d0
	and.w	#$0E00,d7
	rol.w	#7,d7			;reg
	or.w	d7,d0
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)	;.Lが指定されていなければワーニングを出す
	beq	wrt1wobj
	bsr	shortwarn
	bra	wrt1wobj

~sbadcpa1cp:
;CMPA
	tst.b	(OPTCMPA,a6)
	beq	~sbadcpa199		;CMPAの最適化に対応しない
					;CMPA.L #d16,Anの最適化も同時にスキップ
	move.l	(RPNBUF1,a1),d1
	bne	~sbadcpa1cp1
	bra68	d0,~sbadcpa1cp1
;ColdFireにもTST.wl Anはある
;68020以上のときCMPA.{W|L} #0,An→TST.L An
	and.w	#$0E00,d7
	rol.w	#7,d7
	move.w	d7,d0			;reg
	or.w	#$4A88,d0		;TST.L An
	bra	wrt1wobj

~sbadcpa1cp1:
	move.l	d1,d0
	ext.l	d1
	cmp.l	d0,d1
	bne	~sbadcpa199		;$FFFF8000≦imm≦$00007FFFでない
	tst.b	(OPTCMPA,a6)
	beq	~sbadcpa199		;CMPAの最適化に対応しない
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~sbadcpa199		;.Lでないので最適化できない
					;(サイズ省略時も.Wなので不可)
	move.b	#SZ_WORD,(CMDOPSIZE,a6)	;{CMPA|SUBA}.L #imm,An
					;→{CMPA|SUBA}.W #imm,An
					;short addressingのワーニングは出さない
	bra	~sbadcpa5

~sbadcpa199:
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	beq	~sbadcpa2
	move.b	#SZ_WORD,(CMDOPSIZE,a6)	;.w
	btst.l	#13,d7
	bne	~sbadcpa199cp		;CMPA
	bsr	shortwarn
	bra	~sbadcpa5

~sbadcpa199cp
	bsr	shortwarn_cmpa
	bra	~sbadcpa5

~sbadcpa2:
	ori.w	#$0100,d7		;.l
~sbadcpa5:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	cmpi	#xx,<ea>
~cmpi::
;5200/5300はcmp.b/cmp.w/cmpa.w/cmpi.b/cmpi.w不可
	move.w	#C520|C530,d0
	and.w	(CPUTYPE,a6),d0
	beq	~cmpi00
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	ilsizeerr_cf_long	;サイズ省略時もエラー
~cmpi00:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
~cmpi1:
	movea.l	a5,a1
;ColdFireはcmpiでPC相対不可
	move.w	#C020|C030|C040|C060,d1
	and.w	(CPUTYPE,a6),d1
	bne	~cmpi0
	st.b	(ABSLTOOPCCAN,a6)	;cmpiは68000ではPC相対が使えない
~cmpi0:
	bsr	geteamode		;実効アドレスオペランドを得る
	bra68	d1,~cmpi050
	and.w	#EG_DATA&(.not.EA_IMM),d0	;データモード(#xx以外)
	bra	~cmpi051

~cmpi050:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
~cmpi051:
	beq	iladrerr
;ColdFireはcmpi #immはdnのみ
	tst.b	(CPUTYPE2,a6)
	beq	~cmpi052
	and.w	#EA_DN,d0
	beq	iladrerr
~cmpi052:
	tst.b	(OPTCMPI0,a6)
	beq	~subaddi2		;CMPI#0の最適化に対応しない
	tst.b	(RPNSIZE1,a4)
	bpl	~subaddi2		;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a4)
	bpl	~subaddi2		;#immが定数でないので最適化できない
	tst.l	(RPNBUF1,a4)
	bne	~subaddi2		;#immが0でないので最適化できない
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
;CMPI.bwl #0,<ea>→TST.bwl <ea>
	eori.w	#$0C00.eor.$4A00,d7	;CMPI→TST
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	movea.l	a5,a1
	bra	eadataout

;----------------------------------------------------------------
;	subi/addi	#xx,<ea>
~subaddi::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
~subaddi1:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
;addi/subi/cmpi/add #imm/sub #imm/cmp #
	tst.b	(CPUTYPE2,a6)
	beq	~subaddi11
	and.w	#EA_DN,d0
	beq	iladrerr
~subaddi11:
	tst.b	(OPTSUBADDI0,a6)
	beq	~subaddi2		;SUBI/ADDI#0の最適化に対応しない
	tst.b	(RPNSIZE1,a4)
	bpl	~subaddi2		;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a4)
	bpl	~subaddi2		;#immが定数でないので最適化できない
	move.l	(RPNBUF1,a4),d0
	beq	~subaddi2		;#immが1～8でないので最適化できない(-8～-1はフラグ変化が違う)
	cmp.l	#8,d0
	bhi	~subaddi2		;#immが1～8でないので最適化できない(-8～-1はフラグ変化が違う)
	not.w	d7			;SUBI/ADDI→SUBQ/ADDQ
	lsr.w	#1,d7
	and.w	#$0100,d7
	or.w	#$5000,d7
	bra	~subaddq2

~subaddi2:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	movea.l	a4,a1
	bsr	eadataout
	movea.l	a5,a1
	bra	eadataout

~sftrot_imm:				;<sftrot> #xx,Dn
	movea.l	a4,a1
	tst.w	(RPNLEN1,a1)
	bpl	~subaddq_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d1
	beq	ilsfterr
	cmp.l	#8,d1
	bhi	ilsfterr		;1～8の範囲外
	bra	~sftrot_imm_99

~sftrot_expr:
	move.w	#T_CODERPN|TCR_IMM8S,d0	;式の場合
	bra	~subaddq_expr1

;----------------------------------------------------------------
;	subq/addq	#xx,<ea>
~subaddq::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
~subaddq1:
	and.w	#EG_ALT,d0		;可変モード
	beq	iladrerr
	cmp.w	#EA_AN,d0
	bne	~subaddq2
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	beq	~subaddq2
	bsr	shortwarn
~subaddq2:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	movea.l	a4,a1
	tst.w	(RPNLEN1,a1)
	bpl	~subaddq_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d1
	beq	ilquickerr_addsubq
	cmp.l	#8,d1
	bhi	ilquickerr_addsubq	;1～8の範囲外
~sftrot_imm_99:
	SETREGH
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	movea.l	a5,a1
	bra	eadataout

~subaddq_expr:
	move.w	#T_CODERPN|TCR_IMM8,d0	;式の場合
~subaddq_expr1:
	addq.l	#2,(LOCATION,a6)
	bsr	wrtobjd0w
	move.w	d7,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	bsr	ead_outrpn
	movea.l	a5,a1
	bra	eadataout

;----------------------------------------------------------------
;	move	<ea>,<ea>/CCR,<ea>/<ea>,CCR/SR,<ea>/<ea>,SR/USP,An/An,USP
~move::
	move.w	(a0),d0
	cmp.w	#REG_SR|OT_REGISTER,d0
	beq	~move_frsr		;move from SR
	cmp.w	#REG_CCR|OT_REGISTER,d0
	beq	~move_frccr		;move from CCR
	cmp.w	#REG_USP|OT_REGISTER,d0
	beq	~move_frusp		;move from USP
	tst.b	(CPUTYPE2,a6)
	beq	~move000
	cmp.w	#REG_ACC|OT_REGISTER,d0
	beq	~move_fracc		;move from ACC
	cmp.w	#REG_MACSR|OT_REGISTER,d0
	beq	~move_frmacsr		;move from MACSR
	cmp.w	#REG_MASK|OT_REGISTER,d0
	beq	~move_frmask		;move from MASK
~move000:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	move.w	d0,d6
	CHKLIM
	move.w	(a0),d0
	cmp.w	#REG_SR|OT_REGISTER,d0
	beq	~move_tosr		;move to SR
	cmp.w	#REG_CCR|OT_REGISTER,d0
	beq	~move_toccr		;move to CCR
	cmp.w	#REG_USP|OT_REGISTER,d0
	beq	~move_tousp		;move to USP
	tst.b	(CPUTYPE2,a6)
	beq	~move001
	cmp.w	#REG_ACC|OT_REGISTER,d0
	beq	~move_toacc		;move to ACC
	cmp.w	#REG_MACSR|OT_REGISTER,d0
	beq	~move_tomacsr		;move to MACSR
	cmp.w	#REG_MASK|OT_REGISTER,d0
	beq	~move_tomask		;move to MASK
~move001:
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_AN,d0
	beq	~move_a			;move <ea>,An
	cmp.w	#EA_IMM,d6
	beq	~move_q			;move #xx,<ea>
~move1:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
;move <src>,<dst>
;move <src>,anは除外済み
;<src>がdn/an/(an)/(an)+/-(an)ならば制約なし
;<src>が(d16,an)/(d16,pc)ならば<dst>は(d8,an,xi)/xxx.w/xxx.l不可
;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#immならば<dst>は(d8,an,xi)/xxx.w/xxx.l不可
;  5200/5300のとき(d16,an)も不可
;  5400のとき(d16,an)はmove.l #imm,(d16,an)のときだけ不可
;d6=<src>のアドレッシングモード
;d0=<dst>のアドレッシングモード
	tst.b	(CPUTYPE2,a6)
	beq	~move109
;ColdFire
	move.w	d6,d7
	and.w	#EA_DN|EA_AN|EA_ADR|EA_INCADR|EA_DECADR,d7
	bne	~move109		;<src>がdn/an/(an)/(an)+/-(an)
;<src>が(d16,an)/(d16,pc)/(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
	move.w	d0,d7
	and.w	#EA_IDXADR|EA_ABSW|EA_ABSL,d7
	bne	iladrerr		;<src>が(d16,an)/(d16,pc)/(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
					;<dst>が(d8,an,xi)/xxx.w/xxx.l
;<src>が(d16,an)/(d16,pc)/(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
;<dst>がdn/(an)/(an)+/-(an)/(d16,an)
	move.w	d6,d7
	and.w	#EA_DSPADR|EA_DSPPC,d7
	bne	~move109		;<src>が(d16,an)/(d16,pc)
					;<dst>がdn/(an)/(an)+/-(an)/(d16,an)
;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
;<dst>がdn/(an)/(an)+/-(an)/(d16,an)
	move.w	d0,d7
	and.w	#EA_DSPADR,d7
	beq	~move109		;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
					;<dst>がdn/(an)/(an)+/-(an)
;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
;<dst>が(d16,an)
	move.w	#C520|C530,d7
	and.w	(CPUTYPE,a6),d7
	bne	iladrerr		;5200/5300
					;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
					;<dst>が(d16,an)
;5400
;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l/#imm
;<dst>が(d16,an)
	move.w	d6,d7
	and.w	#EA_IMM,d7
	beq	~move109		;5400
					;<src>が(d8,an,xi)/(d8,pc,xi)/xxx.w/xxx.l
					;<dst>が(d16,an)
;5400
;<src>が#imm
;<dst>が(d16,an)
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	beq	iladrerr		;5400
					;move.l #imm,(d16,an)
~move109:
	bsr	getopsize
	move.w	d0,d7
	beq	~move2			;.b
	eori.w	#$0003,d7
~move2:
	addq.w	#1,d7			;オペレーションサイズ .b:%01/.w:%11/.l:%10
	ror.w	#4,d7
	move.w	(EACODE,a5),d0		;デスティネーション実効アドレス
	move.w	d0,d1
	and.w	#$0038,d0		;モード
	and.w	#$0007,d1		;レジスタ
	lsl.w	#3,d0
	ror.w	#7,d1
	or.w	d0,d7
	or.w	d1,d7
	or.w	(EACODE,a4),d7		;ソース実効アドレス
	movea.l	a4,a1
	bsr	f43g_fifth		;5番目のチェック(ソース)
	movea.l	a5,a1
	bsr	f43g_fifth		;5番目のチェック(デスティネーション)
	DSPOPOUT
	movea.l	a4,a1
	bsr	eadataout		;ソースのデータ
	st.b	(DSPADRDEST,a6)
	movea.l	a5,a1
	bsr	eadataout		;デスティネーションのデータ
	sf.b	(DSPADRDEST,a6)
	rts

~move_a:				;move <ea>,An → movea
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	ilsizeerr_an		;.bならエラー
	move.w	#$2040,d7
	move.w	(EACODE,a5),d1
	movea.l	a4,a1
	bra	~movea1

~move_q:				;move.l #-$80～$7F,Dn → moveq
	cmp.w	#EA_DN,d0
	bne	~move1
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	beq	~move_q1		;ロングならmoveqの変換へ
;MOVE.bw #imm,Dn
	tst.b	(OPTMOVE0,a6)
	beq	~move1			;MOVE#0の最適化に対応しない
	tst.b	(RPNSIZE1,a4)
	bpl	~move1			;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a4)
	bpl	~move1			;#immが定数でないので最適化できない
	tst.l	(RPNBUF1,a4)
	bne	~move1			;#immが0でないので最適化できない
;MOVE.bw #0,Dn
	moveq.l	#7,d0
	and.w	(EACODE,a5),d0		;レジスタ
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	~move_q0b
	or.w	#$0040,d0		;.bでなければワード(サイズが省略された場合も含む)
~move_q0b:
	or.w	#$4200,d0		;CLR.bw Dn
	bra	wrt1wobj

~move_q1:
	tst.b	(NOQUICK,a6)
	bmi	~move1			;クイックイミディエイト変換はしない
	tst.w	(RPNLEN1,a4)
	bpl	~move1			;イミディエイト値が得られない
	tst.b	(RPNSIZE1,a4)
	bpl	~move1			;サイズが指定されている
	move.l	(RPNBUF1,a4),d1
	move.l	d1,d2
	ext.w	d1
	ext.l	d1
	cmp.l	d1,d2
	bne	~move1
	move.w	#$7000,d7
	move.w	(EACODE,a5),d1
	movea.l	a4,a1
	bra	~moveq1

~move_frsr:				;move SR,<ea>
	move.w	#$40C0,d7
	bra	~move_frccr1

~move_frccr:				;move CCR,<ea>
;ColdFireにもMOVE from CCRはある
	move.w	(CPUTYPE,a6),d0
	and.w	#C000,d0
	bne	iladrerr		;68000では使用できない
	move.w	#$42C0,d7
~move_frccr1:
	addq.l	#2,a0
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
;MOVE SR/CCR,Dx
	tst.b	(CPUTYPE2,a6)
	beq	~move_frccr11
	and.w	#EA_DN,d0
	beq	iladrerr
~move_frccr11:
	bsr	getopsize
	cmp.b	#SZ_WORD,d0
	bne	ilsizeerr_movefrsr
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~move_tosr:				;move <ea>,SR
	move.w	#$46C0,d7
	bra	~move_tosrccr200

~move_toccr:				;move <ea>,CCR
	move.w	#$44C0,d7
~move_tosrccr200:
	addq.l	#2,a0
	and.w	#EG_DATA,d6		;データモード
	beq	iladrerr
;MOVE Dx/#imm,SR/CCR
	tst.b	(CPUTYPE2,a6)
	beq	~move_tosrccr2001
	and.w	#EA_DN|EA_IMM,d6	;レジスタ番号注意
	beq	iladrerr
~move_tosrccr2001:
	bsr	getopsize
	cmp.b	#SZ_WORD,d0
	bne	ilsizeerr_movetosr
	move.w	d6,d0
	and.w	#EA_IMM,d0
	beq	~move_tosrccr209
	move.w	d7,d0			;$44C0=ccr,$46C0=sr
	bsr	insigbitchk
~move_tosrccr209:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック(ソース)
	DSPOPOUT
	bra	eadataout

~move_frusp:				;move USP,An
	move.w	#$4E68,d7
	addq.l	#2,a0
	CHKLIM
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
~move_frusp1:
	SETREGL
~move_frusp11:
	move.b	(CMDOPSIZE,a6),d0
	bmi	~move_frusp2
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr_moveusp
~move_frusp2:
	OPOUTrts

~move_tousp:				;move An,USP
	tst.b	(IGNORE_ERRATA,a6)
	bne	~move_tousp0
	cmpi.b	#SECT_TEXT,(SECTION,a6)
	bne	~move_tousp0
	bsr	deflabel		;必要ならラベルを定義する
	move.w	#-1,(LABNAMELEN,a6)
	move.l	(LTOPLOC,a6),d0		;行頭のロケーションカウンタ'*'
	cmp.l	(LASTSYMLOC,a6),d0	;最後にラベル定義したロケーションカウンタ
	bne	~move_tousp0
	move.w	#$2048,d0		;MOVEA.L A0,A0
	bsr	wrt1wobj
	bsr	movetouspwarn
~move_tousp0:
	move.w	#$4E60,d7
	addq.l	#2,a0
	cmp.w	#EA_AN,d6
	bne	iladrerr
	move.w	(EACODE,a1),d1
	bra	~move_frusp1

;move from ACC
~move_fracc:
	move.w	#$A180,d7
~move_fracc1:
	addq.l	#2,a0
	CHKLIM
~move_fracc2:
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	or.w	d1,d7
	bra	~move_frusp11

;move from MACSR
~move_frmacsr:
	move.w	#$A980,d7
	addq.l	#2,a0
	CHKLIM
	cmpi.w	#REG_CCR|OT_REGISTER,(a0)
	bne	~move_fracc2
;move from MACSR to CCR
	move.w	#$A9C0,d7
	addq.l	#2,a0
	bra	~move_frusp11

;move from MASK
~move_frmask:
	move.w	#$AD80,d7
	bra	~move_fracc1

;move to ACC
~move_toacc:
	move.w	#$A100,d7
~move_toacc1:
	addq.l	#2,a0
	and.w	#EA_DN|EA_AN|EA_IMM,d6
	beq	iladrerr
	move.b	(CMDOPSIZE,a6),d0
	bpl	~move_toacc2
	moveq.l	#SZ_LONG,d0		;省略時は.l
	move.b	d0,(CMDOPSIZE,a6)	;#immがあるので必要
~move_toacc2:
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr_cf_acc
	or.w	(EACODE,a1),d7
	OPOUT				;(d16,an)/(d16,pc)はないのでDSPOPOUTでなくてよい
	bra	eadataout		;#immがあるので必要

;move to MACSR
~move_tomacsr:
	move.w	#$A900,d7
	bra	~move_toacc1

;move to MASK
~move_tomask:
	move.w	#$AD00,d7
	bra	~move_toacc1

;	MAC.wl Ry.ul,Rx.ul
;	MAC.wl Ry.ul,Rx.ul,<<|>>
;	MSAC.wl Ry.ul,Rx.ul
;	MSAC.wl Ry.ul,Rx.ul,<<|>>
~msac::
	move.w	#$0100,d6
	bra	~mac1
~mac::
	clr.w	d6
~mac1:
	bsr	getreg			;Ry
	bmi	iladrerr
	ror.b	#3,d1			;0000000032100004
	lsl.w	#4,d1			;0000321000040000
	lsl.b	#2,d1			;0000321004000000
	or.w	d1,d7			;Ry
	bsr	getul
	add.w	d1,d1			;bit6→bit7
	or.w	d1,d6			;U/LY
	CHKLIM
	bsr	getreg			;Rx
	bmi	iladrerr
	or.w	d1,d7			;Rx
	bsr	getul
	or.w	d1,d6			;U/LX
	cmpi.w	#','|OT_CHAR,(a0)
	bne	~mac2			;SFなし
	addq.l	#2,a0
	bsr	getsf
	bmi	iloprerr
	or.w	d1,d6			;SF
~mac2:
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~mac3			;省略時はワード
	or.w	#$0800,d6		;ロング
~mac3:
	OPOUT
	move.w	d6,d0
	bra	wrt1wobj

;	MACL.wl Ry.ul,Rx.ul,<ea>,Rw
;	MACL.wl Ry.ul,Rx.ul,<ea>&,Rw
;	MACL.wl Ry.ul,Rx.ul,<<|>>,<ea>,Rw
;	MACL.wl Ry.ul,Rx.ul,<<|>>,<ea>&,Rw
;	MSACL.wl Ry.ul,Rx.ul,<ea>,Rw
;	MSACL.wl Ry.ul,Rx.ul,<ea>&,Rw
;	MSACL.wl Ry.ul,Rx.ul,<<|>>,<ea>,Rw
;	MSACL.wl Ry.ul,Rx.ul,<<|>>,<ea>&,Rw
~msacl::
	move.w	#$0100,d6
	bra	~macl1
~macl::
	clr.w	d6
~macl1:
	bsr	getreg			;Ry
	bmi	iladrerr
	ror.w	#4,d1
	or.w	d1,d6			;Ry
	bsr	getul
	add.w	d1,d1			;bit6→bit7
	or.w	d1,d6			;U/LY
	CHKLIM
	bsr	getreg			;Rx
	bmi	iladrerr
	or.w	d1,d6			;Rx
	bsr	getul
	or.w	d1,d6			;U/LX
	CHKLIM
	bsr	getsf
	bmi	~macl2
	or.w	d1,d6			;SF
	CHKLIM
~macl2:
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~macl3			;省略時はワード
	or.w	#$0800,d6		;ロング
~macl3:
	movea.l	a4,a1
	bsr	geteamode_noopc		;<ea>
	and.w	#EA_ADR|EA_INCADR|EA_DECADR|EA_DSPADR,d0
	beq	iladrerr
	bsr	getmam
	or.w	d1,d6			;MAM
	CHKLIM
	bsr	getreg
	bmi	iladrerr
	ror.b	#3,d1			;0000000032100004
	lsl.w	#4,d1			;0000321000040000
	lsl.b	#2,d1			;0000321004000000
	or.w	d1,d7			;Rw
	or.w	(EACODE,a1),d7		;<ea>
	DSPOPOUT			;(d16,an)があるのでOPOUTは不可
	move.w	d6,d0
	bsr	wrt1wobj
	bra	eadataout

;$0000='.l',$0040='.u',省略時は.lとみなす
getul:
	move.w	(a0)+,d0
	moveq.l	#$40,d1
	cmp.w	#'u'|OT_MAC,d0		;.u
	beq	getul1
	clr.w	d1
	cmp.w	#OT_SIZE|SZ_LONG,d0	;.l
	beq	getul1
	subq.l	#2,a0
getul1:
	rts

;$0200='<<',$0600='>>'
getsf:
	move.w	(a0),d0
	move.w	#$0200,d1
	cmp.w	#'<'|OT_CHAR,d0
	beq	getsf1
	move.w	#$0600,d1
	cmp.w	#'>'|OT_CHAR,d0
	bne	getsf2
getsf1:
	cmp.w	(2,a0),d0
	bne	getsf2
	addq.l	#4,a0
	rts

getsf2:
	moveq.l	#-1,d1
	rts

;$0000=&なし,$0020=&あり
getmam:
	clr.w	d1
	cmpi.w	#'&'|OT_CHAR,(a0)
	bne	getmam2
getmam1:
	addq.l	#2,a0
	moveq.l	#$20,d1
getmam2:
	rts

;----------------------------------------------------------------
;	movea	<ea>,An
~movea::
	move.w	(a0),d0
	cmp.w	#REG_USP|OT_REGISTER,d0
	beq	~move_frusp		;move from USP
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	CHKLIM
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
~movea1:
	SETREGH
	tst.b	(OPTMOVEA,a6)
	beq	~movea199		;MOVEAの最適化に対応しない
	move.w	(EACODE,a1),d0
	cmp.w	#%001_000,d0
	blo	~movea100
	cmp.w	#%001_111,d0
	bls	~movea130		;MOVEA.L Am,An
~movea100:
	cmpi.w	#%111_100,d0
	bne	~movea199		;#immでないので最適化できない
	tst.b	(RPNSIZE1,a1)
	bpl	~movea199		;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a1)
	bpl	~movea199		;定数でないので最適化できない
	move.l	(RPNBUF1,a1),d0
	beq	~leaabs0		;MOVEA.? #0,An→SUBA.L An,An
	ext.l	d0
	cmp.l	(RPNBUF1,a1),d0
	bne	~movea199		;$FFFF8000≦imm≦$00007FFFでない
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~movea199		;.Lでないので最適化できない
					;(サイズ省略時も.Wなので不可)
	move.b	#SZ_WORD,(CMDOPSIZE,a6)	;MOVEA.L #imm,An→MOVEA.W #imm,An
	ori.w	#$1000,d7		;short addressingのワーニングは出さない
	bra	~movea5

~movea130:
;MOVEA.? Am,An
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~movea199		;.Lでないので最適化できない
					;(サイズ省略時も.Wなので不可)
	ror.w	#7,d0
	eor.w	d7,d0
	and.w	#$0E00,d0
	bne	~movea199		;レジスタ番号が違う
	rts				;MOVEA.L An,An

~movea199:
	bsr	getopsize		;サイズを得る
	cmp.b	#SZ_WORD,d0
	bne	~movea5
	ori.w	#$1000,d7		;.w
	bsr	shortwarn
~movea5:
	or.w	(EACODE,a1),d7
;2番目と3番目のチェック
f43g_second::
	tst.b	(F43GTEST,a6)
	beq	f43g_second1
	btst.l	#12,d7
	bne	~movea6			;.w
;movea.l <ea>,an
	cmpi.w	#%010_000,(EACODE,a1)
	blo	~movea6			;movea.l rn,an
;	cmpi.w	#%111_100,EACODE(a1)
;	beq	~movea6			;movea.l #imm,an
;#immは関係ないはずだが念のため
;movea.l {mem},an
	move.l	a0,-(sp)		;a0は破壊しないこと
	movea.l	(F43GPTR,a6),a0
	movea.l	(4,a0),a0		;直前のレコード
	moveq.l	#%00011,d0
	and.b	(12,a0),d0
	beq	~movea7			;直前が1番目と2番目のいずれでもない
	movea.l	(a0),a0			;今回のレコード
	add.b	d0,d0
	or.b	d0,(12,a0)		;2番目または3番目に該当する
	move.w	d7,d0
	rol.w	#7,d0
	bset.b	d0,(13,a0)		;デスティネーションのレジスタ番号
~movea7:
	movea.l	(sp)+,a0
~movea6:
	bsr	f43g_fifth		;5番目のチェック
f43g_second1:
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	moveq	#xx,Dn
~moveq::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
~moveq1:
	SETREGH
	tst.w	(RPNLEN1,a1)
	bpl	~moveq_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d0
	move.l	d0,d1
	ext.w	d0
	ext.l	d0
	cmp.l	d0,d1
	beq	~moveq5
	cmp.l	#$00000100,d1
	bcc	ilquickerr_moveq	;-$80～$FFの範囲外
~moveq5:
	move.b	d0,d7
	OPOUTrts

~moveq_expr:
	addq.l	#2,(LOCATION,a6)	;式の場合
	move.w	#T_CODERPN|TCR_MOVEQ,d0
	bsr	wrtobjd0w
	move.w	d7,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	bra	ead_outrpn

;----------------------------------------------------------------
;	clr	<ea>
~clr::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_DN,d0
	bne	~clr99			;Dnでないので最適化できない
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~clr99			;.Lでないので最適化できない
					;(サイズ省略時も.Wなので不可)
	tst.b	(OPTCLR,a6)
	beq	~clr99			;CLRの最適化に対応しない
	bran68	d1,~clr99		;68020以上ならば最適化しない
	move.w	#$7000,d7
	move.w	(EACODE,a1),d1
	SETREGH
	OPOUTrts

~clr99:
	cmp.w	#EA_AN,d0
;ColdFireでもclrはdnのみではない
	bne	~clr_negnot1
	move.w	#$90C0,d7		;clr An → suba An,An
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	ilsizeerr_an		;.bならエラー
	move.w	(EACODE,a1),d1
	andi.w	#$0007,d1
	bra	~sbadcpa1

;ColdFireでもclrはdnのみではない
~clr_negnot1:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	bra	~negnot11

;----------------------------------------------------------------
;	neg/negx/not	<ea>
~negnot::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
~negnot1:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
;neg/negx/not
	tst.b	(CPUTYPE2,a6)
	beq	~negnot11
	and.w	#EA_DN,d0
	beq	iladrerr
~negnot11:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	tst	<ea>
~tst::
	movea.l	a4,a1
;ColdFireでもtstはPC相対可
	bran68	d1,~tst0
	st.b	(ABSLTOOPCCAN,a6)	;tstは68000ではPC相対が使えない
~tst0:
	bsr	geteamode		;実効アドレスオペランドを得る
;ColdFireでもtstはすべてのモード
	bran68	d1,~tst1		;68000/68010以外ならすべてのモード
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
~tst1:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	jmp/jsr	<ea>
~jmpjsr::
	tst.b	(OPTJMPJSR,a6)
	beq	~peajsrjmp		;JMP/JSRの最適化に対応しない
	move.b	(PCTOABSLNOTALL,a6),(PCTOABSLCAN,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_ABSL,d0
	beq	~jmpjsr_absl
	cmp.w	#EA_DSPPC,d0
	bne	~pea99
;jmp/jsr dpcのとき
	tst.b	(OPTSIZESET,a6)		;(RPNSIZE1,a1)は不可
	bpl	~pea99			;サイズ指定がある(jmp (xxx.w,pc)など)
	tst.w	(RPNLEN1,a1)
	bpl	~jmpjsr_to_jbrajbsr	;ディスプレースメントが定数ではない
;jmp/jsr (xxx,pc)
	moveq.l	#2,d1			;d0は使用中
	cmp.l	(RPNBUF1,a1),d1
	bne	~pea99			;2以外の定数(jmp (-2,pc)など)
;jmp/jsr (2,pc)
	cmp.w	#$4E80,d7		;jsrか?
	beq	~jmpjsr_pea
;jmp (2,pc)
	rts				;jmp (2,pc)は削除
~jmpjsr_pea:
;jsr (2,pc)
	move.l	#$487A_0002,d0		;jsr (2,pc)はpea (2,pc)に最適化
	bra	wrt1lobj

;jmp/jsr abslのとき
~jmpjsr_absl:
	tst.b	(OPTSIZESET,a6)		;RPNSIZE1(a1)は不可
	bpl	~pea99			;サイズ指定がある(jmp label.lなど)
	tst.w	(RPNLEN1,a1)
	bmi	~pea99			;定数(jmp $FF0038など)
;jmp/jsr label
~jmpjsr_to_jbrajbsr:
	sf.b	(OPTIONALPC,a1)		;OPCの処理が行われないようにする
	cmp.w	#$4E80,d7		;jsrか?
	beq	~jmpjsr_jbsr
;jmp label
	move.w	#$6000,d7		;jmpをjbraにする
	bra	~jbcc1

~jmpjsr_jbsr:
;jsr label
	move.w	#$6100,d7		;jsrをjbsrにする
	bra	~jbcc1

;----------------------------------------------------------------
;	pea/jsr/jmp	<ea>
~peajsrjmp::
	move.b	(PCTOABSLNOTALL,a6),(PCTOABSLCAN,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
~pea99:
	and.w	#EG_CTRL,d0		;制御モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	mov3q.l #imm,<ea>
~mov3q::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode_noopc
	and.w	#EG_ALT,d0		;可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	movea.l	a4,a1
	tst.w	(RPNLEN1,a1)
	bpl	~mov3q_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d1
	beq	ilquickerr_mov3q	;-1,1～7の範囲外
	bpl	~mov3q1
	addq.l	#1,d1
~mov3q1:
	cmp.l	#7,d1
	bhi	ilquickerr_mov3q	;-1,1～7の範囲外
	SETREGH
	DSPOPOUT
	movea.l	a5,a1
	bra	eadataout

~mov3q_expr:
	move.w	#T_CODERPN|TCR_IMM3Q,d0
	bra	~subaddq_expr1

;----------------------------------------------------------------
;	mvs/mvz <ea>,dn
~mvsmvz::
	movea.l	a4,a1
	bsr	geteamode
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
	bsr	setopsize		;0=byteまたは1=wordのみ
	or.w	(EACODE,a1),d7
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	wddata <ea>
~wddata::
	movea.l	a4,a1
	bsr	geteamode_noopc
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	wdebug <ea>
~wdebug::
	movea.l	a4,a1
	bsr	geteamode_noopc
	and.w	#EA_ADR|EA_DSPADR,d0
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	#$0003,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
~tas::
	tst.b	(CPUTYPE2,a6)
	beq	~scc
;ColdFire,5400のみ
	movea.l	a4,a1
	bsr	geteamode_noopc
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	bra	~scc01

;----------------------------------------------------------------
;	s<cc>/nbcd/tas	<ea>
~scc::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	tst.b	(CPUTYPE2,a6)
	beq	~scc01
	and.w	#EA_DN,d0
	beq	iladrerr
~scc01:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	dec/inc	<ea>
~decinc::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_ALT,d0		;可変モード
	beq	iladrerr
	cmp.w	#EA_AN,d0
	bne	~decinc1
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	beq	~decinc1
	bsr	shortwarn
~decinc1:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	chk	<ea>,Dn
~chk::
	tst.b	(CMDOPSIZE,a6)
	bpl	~chk99
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
~chk99:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_DATA,d0		;データモード
	beq	iladrerr
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~chk1
	bra68	d0,ilsizeerr_000_long	;68000/68010では.lは使えない
	bra	~chk2

~chk1:
	ori.w	#$0080,d7		;.w
~chk2:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	lea	<ea>,An
~lea::
	move.b	(PCTOABSLNOTALL,a6),(PCTOABSLCAN,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_CTRL,d0		;制御モード
	beq	iladrerr
	CHKLIM
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
	or.w	(EACODE,a1),d7
	tst.b	(OPTLEA,a6)
	beq	~lea199			;LEAの最適化に対応しない
	cmpi.b	#EAD_ABSLW,(EADTYPE,a1)
	beq	~leaabs			;LEA 0,An→SUBA.L An,An
	move.w	d7,d0
	ror.w	#7,d0
	eor.w	d7,d0
	and.w	#$0E00,d0
	bne	~lea199			;レジスタ番号が異なるので最適化できない
	moveq.l	#%111_000,d0
	and.w	d7,d0
	cmp.w	#EAC_ADR,d0
	beq	~leanop			;LEA (An),An→削除
	cmp.w	#EAC_DSPADR,d0
	bne	~lea199			;(d,An)でないので最適化できない
	tst.w	(RPNLEN1,a1)
	bpl	~lea199			;定数でないので最適化できない
	tst.b	(OPTSIZESET,a6)
	bpl	~lea199			;サイズ指定があるので最適化しない
	move.l	(RPNBUF1,a1),d0
	beq	~leanop			;LEA (0,An),An→削除
	bpl	~leaaddq
~leasubq:
	moveq.l	#-8,d1
	cmp.l	d1,d0
	blt	~lea199			;-8より小さい
;LEA→SUBQ
	neg.w	d0
	move.w	#$5148,d1
	bra	~leaq

~leaaddq:
	moveq.l	#8,d1
	cmp.l	d1,d0
	bgt	~lea199			;8より大きい
;LEA→ADDQ
	move.w	#$5048,d1
~leaq:
	rol.w	#7,d7
	and.w	#$0007,d7		;レジスタ番号
	or.w	d7,d1
	and.w	#$0007,d0		;8→0
	ror.w	#7,d0
	or.w	d1,d0
	bra	wrt1wobj

;LEA.L (An),An/LEA.L (0,An),An
~leanop:
	rts

;LEA.L ABS,An
~leaabs:
	tst.b	(OPTSIZESET,a6)
	bpl	~lea199			;サイズ指定がある
	tst.w	(RPNLEN1,a1)
	bpl	~lea199			;定数でない
	move.l	(RPNBUF1,a1),d0
	bne	~lea199
	bsr	abswarn
;LEA.L 0,An/MOVEA.? #0,An→SUBA.L An,An
~leaabs0:
	move.w	d7,d1
	and.w	#$0E00,d1
	move.w	#$91C8,d7		;SUBA.L An,An
	or.w	d1,d7
	rol.w	#7,d1
	or.w	d1,d7
	OPOUTrts

~lea199:
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	chk2/cmp2	<ea>,Rn
~cmpchk2::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_CTRL,d0		;制御モード
	beq	iladrerr
	CHKLIM
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	ror.w	#4,d1
	or.w	d7,d1
	move.w	#$00C0,d7
	bsr	getopsize		;サイズを得る
	ror.w	#7,d0			;サイズフィールドはb10-b9
	or.w	d0,d7
	or.w	(EACODE,a1),d7
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~cmpchk21
	bsr	softwarn
~cmpchk21:
;ソフトウェアエミュレーションなのでエラッタのチェックは不要
	DSPOPOUT			;命令コードの出力
	move.w	d1,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
;	asl	Dn,Dn/#xx,Dn/<ea>
~asl::
	clr.b	(EADTYPE,a5)		;(subq/addqのイミディエイトオペランド対策)
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	move.w	d0,d6
	tst.w	(a0)
	beq	~sftrot_ea		;<sftrot> <ea>
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	bsr	setopsize		;オペレーションサイズのセット
	cmp.w	#EA_IMM,d6
	bne	~sftrot_not_imm
~asl_imm:
	tst.b	(OPTASL,a6)
	beq	~sftrot_imm		;ASLの最適化に対応しない
	move.w	#C060,d0
	and.w	(CPUTYPE,a6),d0
	bne	~sftrot_imm		;68060ならば最適化しない
	tst.b	(RPNSIZE1,a1)
	bpl	~sftrot_imm		;#immにサイズ指定があるので最適化しない
	tst.w	(RPNLEN1,a1)
	bpl	~sftrot_imm		;定数でないので最適化できない
	moveq.l	#1,d0
	cmp.l	(RPNBUF1,a1),d0
	bne	~sftrot_imm		;1以外は最適化できない
	moveq.l	#$0007,d0
	and.w	d7,d0
	move.w	d0,d1
	lsl.w	#3,d0
	or.b	(CMDOPSIZE,a6),d0	;0,1,2のいずれか(-1は1に変更済み)
	lsl.w	#6,d0
	or.w	d1,d0
	or.w	#$D000,d0		;ADD Dn,Dn
	bra	wrt1wobj

;----------------------------------------------------------------
;	as?/ls?/rox?/ro?	Dn,Dn/#xx,Dn/<ea>
~sftrot::
	clr.b	(EADTYPE,a5)		;(subq/addqのイミディエイトオペランド対策)
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	move.w	d0,d6
	tst.w	(a0)
	beq	~sftrot_ea		;<sftrot> <ea>
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	bsr	setopsize		;オペレーションサイズのセット
	cmp.w	#EA_IMM,d6
	beq	~sftrot_imm		;<sftrot> #xx,Dn (subq/addqと同じ)
~sftrot_not_imm:
	cmp.w	#EA_DN,d6
	bne	iladrerr
	move.w	(EACODE,a1),d1		;<sftrot> Dn,Dn
	SETREGH
	or.w	#$0020,d7
	OPOUTrts

~sftrot_ea:				;<sftrot> <ea>
	cmp.w	#EA_DN,d0
	bne	~sftrot_ea1
	or.w	#$0200,d7		;<sftrot> Dn → <sftrot> #1,Dn
	move.w	(EACODE,a1),d1
	SETREGL
	bsr	setopsize		;オペレーションサイズのセット
	OPOUTrts

~sftrot_ea1:
;dnは既に除外してある
	tst.b	(CPUTYPE2,a6)
	bne	iladrerr
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	bsr	getopsize
	cmp.b	#SZ_WORD,d0
	bne	ilsizeerr_sftrotmem
	move.w	d7,d0
	and.w	#$0018,d0		;シフト・ローテイトタイプ
	rol.w	#6,d0
	or.w	#$00C0,d0
	or.w	d0,d7
	and.w	#$FFC0,d7
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	bchg/bclr/bset	Dn,<ea>/#xx,<ea>
~bchclst::
	move.w	#EG_DATA&EG_ALT,d6	;データ・可変モード
	st.b	(ABSLTOOPCCAN,a6)
	bra	~btst1

;----------------------------------------------------------------
;	btst	Dn,<ea>/#xx,<ea>
~btst::
	move.w	#EG_DATA,d6		;データモード
~btst1:
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~btst5
	SETREGH
	or.w	#$0100,d7		;Dn,<ea>
	CHKLIM
	movea.l	a5,a1
;btstは68000でもPC相対が使える
	bsr	geteamode		;実効アドレスオペランドを得る
	move.b	#SZ_LONG,d1		;<ea>がDnの場合サイズは.l
	cmp.w	#EA_DN,d0
	beq	~btst2
	clr.b	d1			;move.b #SZ_BYTE,d1
					;<ea>がDn以外の場合サイズは.b
	and.w	d6,d0			;データ(btst)/データ・可変(bchg/bclr/bset)モード
	beq	iladrerr
~btst2:
	move.b	(CMDOPSIZE,a6),d6
	bmi	~btst3
	cmp.b	d1,d6
	beq	~btst3
	tst.b	d1			;cmp.b #SZ_BYTE,d1
	beq	ilsizeerr_bitmem
	bra	ilsizeerr_bitreg
~btst3:
	move.b	d1,(CMDOPSIZE,a6)
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~btst5:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
;ColdFireはbchg/bclr/bset/btst #imm,<ea>は(d8,an,ix)不可
	tst.b	(CPUTYPE2,a6)
	beq	~btst50
	and.w	#.not.EA_IDXADR,d6
~btst50:
	or.w	#$0800,d7		;#xx,<ea>
	CHKLIM
	movea.l	a5,a1
;btstは68000でもPC相対が使える
	bsr	geteamode		;実効アドレスオペランドを得る
	move.b	#SZ_LONG,d1		;<ea>がDnの場合サイズは.l
	cmp.w	#EA_DN,d0
	beq	~btst6
	clr.b	d1			;move.b #SZ_BYTE,d1
					;<ea>がDn以外の場合サイズは.b
	and.w	#.not.EA_IMM,d6		;#xx,#xxはエラー
	and.w	d6,d0			;データ(btst)/データ・可変(bchg/bclr/bset)モード
	beq	iladrerr
~btst6:
	move.b	(CMDOPSIZE,a6),d6
	bmi	~btst7
	cmp.b	d1,d6
	beq	~btst7
	tst.b	d1			;cmp.b #SZ_BYTE,d1
	beq	ilsizeerr_bitmem
	bra	ilsizeerr_bitreg
~btst7:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	clr.b	(CMDOPSIZE,a6)		;move.b #SZ_BYTE,(CMDOPSIZE,a6)
	movea.l	a4,a1
	bsr	eadataout		;ビット番号を出力
	movea.l	a5,a1
	bra	eadataout

;----------------------------------------------------------------
;	bfchg/bfclr/bfset	<ea>{of:wd}	(68020/68030/68040)
~bfchclst::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#(EG_CTRL&EG_ALT)|EA_DN,d0	;制御・可変モードまたはDn
	beq	iladrerr
	movea.l	a5,a1
	bsr	getbitfield		;ビットフィールド指定を得る
	move.w	d0,d6
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bsr	bfdataout
	movea.l	a4,a1
	bra	eadataout

;----------------------------------------------------------------
;	ビットフィールドデータを出力する
bfdataout:
	movea.l	a5,a1
	tst.w	(RPNLEN1,a1)		;オフセット
	bne	bfdataout5
	tst.w	(RPNLEN2,a1)		;幅
	bne	bfdataout1
	move.w	d6,d0			;両方とも定数/レジスタの場合
	bra	wrt1wobj		;特殊オペランドの出力

bfdataout1:
	addq.l	#2,(LOCATION,a6)
	move.w	#T_BITFIELD|TBF_WD,d0	;幅が式の場合
	bsr	wrtobjd0w
	move.w	d6,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	move.w	(RPNLEN2,a1),d1
	lea.l	(RPNBUF2,a1),a1
	bra	wrtrpn			;式を出力する

bfdataout5:
	addq.l	#2,(LOCATION,a6)
	tst.w	(RPNLEN2,a1)		;幅
	bne	bfdataout6
	move.w	#T_BITFIELD|TBF_OF,d0	;オフセットが式の場合
	bsr	wrtobjd0w
	move.w	d6,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	move.w	(RPNLEN1,a1),d1
	lea.l	(RPNBUF1,a1),a1
	bra	wrtrpn			;式を出力する

bfdataout6:
	move.w	#T_BITFIELD|TBF_OFWD,d0	;オフセット・幅とも式の場合
	bsr	wrtobjd0w
	move.w	d6,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	move.w	(RPNLEN1,a1),d1
	lea.l	(RPNBUF1,a1),a1
	bsr	wrtrpn			;式を出力する
	movea.l	a5,a1
	moveq.l	#0,d0			;(サイズは無関係)
	move.w	(RPNLEN2,a1),d1
	lea.l	(RPNBUF2,a1),a1
	bra	wrtrpn			;式を出力する

;----------------------------------------------------------------
;	bftst	<ea>{of:wd}		(68020/68030/68040)
~bftst::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_CTRL|EA_DN,d0	;制御モードまたはDn
	beq	iladrerr
	movea.l	a5,a1
	bsr	getbitfield		;ビットフィールド指定を得る
	move.w	d0,d6
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bsr	bfdataout
	movea.l	a4,a1
	bra	eadataout

;----------------------------------------------------------------
;	bfexts/bfextu/bfffo	<ea>{of:wd},Dn	(68020/68030/68040)
~bfextffo::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_CTRL|EA_DN,d0	;制御モードまたはDn
	beq	iladrerr
	movea.l	a5,a1
	bsr	getbitfield		;ビットフィールド指定を得る
	move.w	d0,d6
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	ror.w	#4,d1
	or.w	d1,d6
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bsr	bfdataout
	movea.l	a4,a1
	bra	eadataout

;----------------------------------------------------------------
;	bfins	Dn,<ea>{of:wd}		(68020/68030/68040)
~bfins::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	ror.w	#4,d1
	move.w	d1,d6
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#(EG_CTRL&EG_ALT)|EA_DN,d0	;制御・可変モードまたはDn
	beq	iladrerr
	movea.l	a5,a1
	bsr	getbitfield		;ビットフィールド指定を得る
	or.w	d0,d6
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bsr	bfdataout
	movea.l	a4,a1
	bra	eadataout

;----------------------------------------------------------------
;	pack/unpk	-(An),-(An),#xx/Dn,Dn,#xx	(68020/68030/68040)
~packunpk::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~packunpk5
	SETREGL
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
~packunpk1:
	SETREGH
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	OPOUT
	move.b	#SZ_WORD,(CMDOPSIZE,a6)	;データはワード固定
	bra	eadataout

~packunpk5:				;-(An),-(An),#xx
	ori.w	#$0008,d7
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_DECADR,d0
	bne	iladrerr		;-(An)でなければエラー
	bsr	f43g_fifthadr		;5番目のチェック
	move.w	(EACODE,a1),d1
	SETREGL
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_DECADR,d0
	bne	iladrerr		;-(An)でなければエラー
	bsr	f43g_fifthadr		;5番目のチェック
	move.w	(EACODE,a1),d1
	bra	~packunpk1

;----------------------------------------------------------------
;	subx/addx	Dn,Dn/-(An),-(An)
~subaddx::
	bsr	setopsize		;オペレーションサイズのセット
;	bra	~sabcd			;後の処理はsbcd/abcdと同じ

;----------------------------------------------------------------
;	sbcd/abcd	Dn,Dn/-(An),-(An)
~sabcd::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~sabcd5
	SETREGL
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
	OPOUTrts

~sabcd5:
;subx/addx -(an),-(an)
	tst.b	(CPUTYPE2,a6)
	bne	iladrerr
	or.w	#$0008,d7
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_DECADR,d0
	bne	iladrerr		;-(An)でなければエラー
	bsr	f43g_fifthadr		;5番目のチェック
	move.w	(EACODE,a1),d1
	SETREGL
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_DECADR,d0
	bne	iladrerr		;-(An)でなければエラー
	bsr	f43g_fifthadr		;5番目のチェック
	move.w	(EACODE,a1),d1
	SETREGH
	OPOUTrts

;----------------------------------------------------------------
;	divs/divu/muls/mulu	<ea>,Dn/<ea>,Dh(Dr):Dl(Dq)
~divmul::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_DATA,d0		;データモード
	beq	iladrerr
	move.w	d0,d6
	CHKLIM
	bsr	getopsize		;サイズを得る
	cmp.b	#SZ_LONG,d0
	beq	~divmul1		;.l
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	bra	eadataout

~divmul1:
	bra68	d0,ilsizeerr_000_long	;68000/68010では.lは使えない
;divu/divs/mulu/muls.l <ea>,Dn
;ColdFireでは64ビットは使えないが.lは使える
;ColdFireはdn,(an),(an)+,-(an),(d16,an)のみ
	tst.b	(CPUTYPE2,a6)
	beq	~divmul11
	and.w	#EA_DN|EA_ADR|EA_INCADR|EA_DECADR|EA_DSPADR,d6	;レジスタ番号注意
	beq	iladrerr
~divmul11:
	move.w	d7,d6
	andi.w	#$4000,d7
	eori.w	#$4000,d7
	lsr.w	#8,d7
	ori.w	#$4C00,d7		;命令コード
	andi.w	#$0100,d6
	lsl.w	#3,d6			;特殊オペランド
	bsr	getdregp		;データレジスタペアオペランドを得る
	beq	~divmul2
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	move.w	d1,d2			;<ea>,Dl(Dq)
	bra	~divmul3

~divmul2:				;<ea>,Dh(Dr):Dl(Dq)
;ColdFireでは64ビットは使えない
	tst.b	(CPUTYPE2,a6)
	bne	iladrerr
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~divmul4
	bsr	softwarn
~divmul4:
	or.w	#$0400,d6		;64bit
~divmul3:
	or.w	d1,d6			;Dh(Dr)をセット
	ror.w	#4,d2
	or.w	d2,d6			;Dl(Dq)をセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
;	divsl/divul	<ea>,Dr:Dq	(68020/68030/68040)
~divl::
	move.b	#SZ_LONG,(CMDOPSIZE,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_DATA,d0		;データモード
	beq	iladrerr
	CHKLIM
	move.w	d7,d6
	move.w	#$4C40,d7		;命令コード
	bsr	getdregp		;データレジスタペアオペランドを得る
	beq	~divmul3
	bra	iladrerr

;----------------------------------------------------------------
;	cas	Dc,Du,<ea>		(68020/68030/68040)
~cas::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	move.w	d1,d6			;Dc
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	lsl.w	#6,d1
	or.w	d1,d6			;Du
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	bsr	getopsize		;サイズを得る
	addq.w	#1,d0
	ror.w	#7,d0
	or.w	d0,d7			;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
;	cas2	Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)	(68020/68030/68040)
~cas2::
	bsr	getdregp		;データレジスタペアオペランドを得る
	bmi	iladrerr
	move.w	d1,d6			;Dc1
	move.w	d2,d5			;Dc2
	CHKLIM
	bsr	getdregp		;データレジスタペアオペランドを得る
	bmi	iladrerr
	lsl.w	#6,d1
	lsl.w	#6,d2
	or.w	d1,d6			;Du1
	or.w	d2,d5			;Du2
	CHKLIM
	bsr	getregpp		;レジスタ間接ペアオペランドを得る
	bmi	iladrerr
	ror.w	#4,d1
	ror.w	#4,d2
	or.w	d1,d6			;Rn1
	or.w	d2,d5			;Rn2
	bsr	getopsize		;サイズを得る
	addq.w	#1,d0
	ror.w	#7,d0
	or.w	d0,d7			;オペレーションサイズのセット
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~cas21
	bsr	softwarn
~cas21:
;ソフトウェアエミュレーションなのでエラッタのチェックは不要
	OPOUT				;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	move.w	d5,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
;	link	An,#xx
~link::
;ColdFireでもlinkは.wのみ(除外済み)
	bran68	d0,~link1
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)	;68000/68010のlinkはワードのみ
	beq	ilsizeerr_000_long	;.lなのでエラー
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
~link1:
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	move.b	(CMDOPSIZE,a6),d0
	cmp.b	#SZ_WORD,d0
	beq	~linkw
	cmp.b	#SZ_LONG,d0
	beq	~linkl
	tst.w	(RPNLEN1,a1)
	bpl	~link_expr
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
	move.l	(RPNBUF1,a1),d1
	move.l	d1,d0
	ext.l	d0
	cmp.l	d1,d0
	beq	~linkw
	move.b	#SZ_LONG,(CMDOPSIZE,a6)
~linkl:					;link.l
	and.w	#$0007,d7
	or.w	#$4808,d7
~linkw:					;link.w
	OPOUT
	bra	eadataout

~link_expr:				;式の場合
	move.w	#T_LINK,d0
	move.b	d7,d0
	and.b	#7,d0			;アドレスレジスタ番号
	bsr	wrtobjd0w
	move.l	(EXTLEN,a6),d0
	addq.l	#2,d0
	add.l	d0,(LOCATION,a6)
	move.b	(EXTSIZE,a6),d0
	or.b	#ESZ_OPT,d0		;(最適化対象)
	bra	ead_outrpn

;----------------------------------------------------------------
;	movem	<list>,<ea>/<ea>,<list>
~movem::
	moveq	#0,d5			;-1レジスタリストが#imm形式(<list>,<ea>のみ)
	moveq	#0,d6			;0なら#immの値が確定済

	bsr	getreglist		;レジスタリストオペランドを得る
	bpl	@f
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	~movem5
	moveq	#-1,d5
	tst.w	(RPNLEN1,a1)
	spl	d6
	bpl	@f			;式の値が未確定
	move.l	(RPNBUF1,a1),d1
	cmp.l	#$10000,d1
	bcc	overflowerr
@@:
	move.w	d1,-(sp)
	CHKLIM				;<list>,<ea>
	movea.l	a5,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
;movem <list>,<ea>
;ColdFireは(an),(d16,an)のみ
	tst.b	(CPUTYPE2,a6)
	beq	~movem00
	and.w	#EA_ADR|EA_DSPADR,d0
	beq	iladrerr
~movem00:
	move.w	(sp)+,d1
	move.w	d0,d2
	and.w	#EG_CTRL&EG_ALT,d2	;制御・可変モード
	bne	~movem6
	cmp.w	#EA_DECADR,d0		;-(An)
	bne	iladrerr
	tst.b	d5
	bne	~movem6
	moveq.l	#0,d0			;-(An)の場合はレジスタリストを反転する
	moveq.l	#16-1,d2
~movem1:
	roxl.w	#1,d1
	roxr.w	#1,d0
	dbra	d2,~movem1
	move.w	d0,d1
	bra	~movem6

~movem5:				;<ea>,<list>
	ori.w	#$0400,d7
	and.w	#EG_CTRL|EA_INCADR,d0	;制御モードまたは(An)+
	beq	iladrerr
;movem <ea>,<list>
;ColdFireは(an),(d16,an)のみ
	tst.b	(CPUTYPE2,a6)
	beq	~movem51
	and.w	#EA_ADR|EA_DSPADR,d0
	beq	iladrerr
~movem51:
	CHKLIM
	bsr	getreglist		;レジスタリストオペランドを得る
	bpl	@f
	movea.l	a5,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr
	tst.w	(RPNLEN1,a1)
	spl	d6
	bpl	@f			;式の値が未確定
	move.l	(RPNBUF1,a1),d1
	cmp.l	#$10000,d1
	bcc	overflowerr
@@:
~movem6:
	movea.l	a4,a1
	move.l	a5,d5
	btst.l	#10,d7
	bne	@f			;<ea>,<list>
	exg.l	d5,a1			;<list>,<ea>
@@:
	bsr	getopsize		;サイズを得る
	cmpi.b	#SZ_WORD,d0
	beq	~movem7
	ori.w	#$0040,d7		;.l
~movem7:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT			;命令コードの出力
	tst.b	d6
	bne	1f
	move.w	d1,d0			;レジスタリスト
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	2f
1:
	exg.l	d5,a1			;レジスタリストが#式
	moveq.l	#SZ_WORD,d0
	bsr	ead_imm1
	exg.l	d5,a1
2:
	bra	eadataout

;----------------------------------------------------------------
;	movep	Dn,(d,An)/(d,An),Dn
~movep::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	~movep5
	or.w	#$0080,d7		;Dn,(d,An)
	SETREGH
	CHKLIM
	bsr	getdspadr
	bra	~movep8

~movep5:				;(d,An),Dn
	bsr	getdspadr
	CHKLIM
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGH
~movep8:
	move.w	(X_MOVEP,a6),d0		;MOVEPを展開するCPUのビットが1
	and.w	(CPUTYPE,a6),d0
	beq	~movep99		;展開しない
;movepのマクロ展開
;ディスプレースメントが1ワードにおさまらないときanを変更する
;(+側だけなのでaddq.l #8,anとsubq.l #8,anで挟んでディスプレースメントから8引けばよい)
	tst.w	(RPNLEN1,a1)
	bpl	~movep99		;dが定数でない
;d7.w=0000_ddd_1_w_s_001_aaa
	moveq.l	#%0000_000_0_0_0_000_111,d0
	and.w	d7,d0			;0000_000_0_0_0_000_aaa
	subq.w	#7,d0
	beq	~movep99		;a7は処理できない
	move.w	(RPNBUF1+2,a1),d2	;d
	ext.l	d2			;符号拡張しておく
	moveq.l	#0,d3			;ゲタ
;				-(SP)
	move.w	#%0100_0000_11_100_111,d0	;MOVE.W SR,-(SP)
	move.w	#C000,d6
	and.w	(CPUTYPE,a6),d6
	bne	~movep950
;				-(SP)
	move.w	#%0100_0010_11_100_111,d0	;MOVE.W CCR,-(SP)
~movep950:
	bsr	wrt1wobj
;d7.w=0000_ddd_1_w_s_001_aaa
	tst.b	d7			;wをテスト
	bmi	~movep91		;w=1:write
;w=0:read
;MOVEP.wl (d,An),Dn
;d7.w=0000_ddd_1_w_s_001_aaa
~movep90:
	move.w	d7,d6				;0000_ddd_1_w_s_001_aaa
	and.w	#%0000_111_000_000_111,d6	;0000_ddd_000_000_aaa
	lsr.w	#8,d7
	lsr.w	#1,d7				;0000_000_000_000_ddd
	or.w	#%1110_000_1_01_001_000,d7	;LSL.W #8,Dn
;d7.w=LSL.W #8,Dn
	bsr	~movep90dsp		;MOVE.B (d,An),Dn
	bsr	~movep902dsp		;LSL.W #8,Dn;MOVE.B (d+2,An),Dn
	bsr	getopsize
	subq.b	#SZ_LONG,d0
	bne	~movep92		;ロングでなければすべてワード
;MOVEP.L (d,An),Dn
~movep901:
;			LSL.W #8,Dn	→	SWAP.W Dn
	eor.w	#%1110_000_1_01_001_000.eor.%0100100001000_000,d7	;SWAP.W Dn
	bsr	~movep902dsp		;LSL.W #8,Dn;MOVE.B (d+4,An),Dn
;			SWAP.W Dn	→	LSL.W #8,Dn
	eor.w	#%0100100001000_000.eor.%1110_000_1_01_001_000,d7	;LSL.W #8,Dn
	bsr	~movep902dsp		;LSL.W #8,Dn;MOVE.B (d+6,An),Dn
	bra	~movep92

;dを2増やしてから,d7を出力して,MOVE.B (d,An),Dnを出力する
~movep902dsp:
	addq.l	#2,d2
	move.w	d7,d0
	bsr	wrt1wobj		;LSL.W #8,Dn
;MOVE.B (d,An),Dnを出力する
;d2.l=d
;d6.w=0000_ddd_000_000_aaa
~movep90dsp:
	move.w	d6,d0			;0000_ddd_000_000_aaa
	move.w	d2,d1
	beq	~movep90dsp0		;ディスプレースメントが0
	ext.l	d1
	cmp.l	d2,d1
	beq	~movep90dsp1		;ディスプレースメントがオーバーフローしていない
;ディスプレースメントがオーバーフローしている
;020～060のときは(bd,An)を出力する
	move.w	#C020|C030|C040|C060,d0
	and.w	(CPUTYPE,a6),d0
	bne	~movep90dsp2		;020～060のときは(bd,An)を出力する
;020～060ではないので,Anを8増やしてディスプレースメントを8減らす
;d6.w=0000_ddd_000_000_aaa
	moveq.l	#%0000_000_000_000_111,d0
	and.w	d6,d0			;0000_000_000_000_aaa
;		        Dn   .L   An
	or.w	#%0101_000_0_10_001_000,d0	;ADDQ.L #8,An
	bsr	wrt1wobj
	moveq.l	#8,d3			;ゲタ
	subq.l	#8,d2			;d
	move.w	d6,d0			;0000_ddd_000_000_aaa
;MOVE.B (d,An),Dn
;d0.w=0000_ddd_000_000_aaa
~movep90dsp1:
;		     .B    Dn    (d,An)
	or.w	#%00_01_000_000_101_000,d0	;MOVE.B (d,An),Dn
	bsr	wrt1wobj
	move.w	d2,d0			;d
	bra	wrt1wobj

;MOVE.B (An),Dn
;d0.w=0000_ddd_000_000_aaa
~movep90dsp0:
;		     .B    Dn     (An)
	or.w	#%00_01_000_000_010_000,d0	;MOVE.B (An),Dn
	bra	wrt1wobj

;MOVE.B Dn,(bd,An)
;d6.w=0000_ddd_000_000_aaa
~movep90dsp2:
	move.w	d6,d0			;0000_ddd_000_000_aaa
;		     .B    Dn    (bd,An)
	or.w	#%00_01_000_000_110_000,d0	;MOVE.B (bd,An),Dn
;d0とfull formatの拡張ワードを出力して終わり
~movep90dsp21:
	bsr	wrt1wobj
;		 D/A REGISTER W/L SCALE 1 BS IS BDSIZE 0 I/IS
	move.w	#%0____000_____0___00___1_0__1____11___0_000,d0
	bsr	wrt1wobj
	move.l	d2,d0
	bra	wrt1lobj

;MOVE.B Dn,(bd,An)
;d6.w=0000_ddd_000_000_aaa
~movep91dsp2:
	move.w	d6,d0			;0000_ddd_000_000_aaa
	ror.w	#7,d0			;0000_aaa_000_0dd_d00
	lsr.b	#2,d0			;0000_aaa_000_000_ddd
;		     .B (bd,An)   Dn
	or.w	#%00_01_000_110_000_000,d0	;MOVE.B Dn,(bd,An)
	bra	~movep90dsp21		;d0とfull formatの拡張ワードを出力して終わり

;MOVE.B Dn,(An)
;d0.w=0000_ddd_000_000_aaa
~movep91dsp0:
	ror.w	#7,d0			;0000_aaa_000_0dd_d00
	lsr.b	#2,d0			;0000_aaa_000_000_ddd
;		     .B   (An)     Dn
	or.w	#%00_01_000_010_000_000,d0	;MOVE.B Dn,(An)
	bra	wrt1wobj

;dを2増やして,d7.wを出力してから,MOVE.B Dn,(d,An)を出力する
~movep912dsp:
	addq.l	#2,d2
;d7.wを出力してから,MOVE.B Dn,(d,An)を出力する
;d2.l=d
;d6.w=0000_ddd_000_000_aaa
~movep91dsp:
	move.w	d7,d0
	bsr	wrt1wobj		;ROL.wl #8,Dn
	move.w	d6,d0
	move.w	d2,d1
	beq	~movep91dsp0		;ディスプレースメントが0
	ext.l	d1
	cmp.l	d2,d1
	beq	~movep91dsp1		;ディスプレースメントがオーバーフローしていない
;ディスプレースメントがオーバーフローしている
;020～060のときは(bd,An)を出力する
	move.w	#C020|C030|C040|C060,d0
	and.w	(CPUTYPE,a6),d0
	bne	~movep91dsp2		;020～060のときは(bd,An)を出力する
;020～060ではないので,Anを8増やしてディスプレースメントを8減らす
;d6.w=0000_ddd_000_000_aaa
	moveq.l	#%0000_000_000_000_111,d0
	and.w	d6,d0			;0000_000_000_000_aaa
;		        Dn   .L   An
	or.w	#%0101_000_0_10_001_000,d0	;ADDQ.L #8,An
	bsr	wrt1wobj
	moveq.l	#8,d3			;ゲタ
	subq.l	#8,d2			;d
	move.w	d6,d0			;0000_ddd_000_000_aaa
;MOVE.B Dn,(d16,An)
;d0.w=0000_ddd_000_000_aaa
~movep91dsp1
	ror.w	#7,d0			;0000_aaa_000_0dd_d00
	lsr.b	#2,d0			;0000_aaa_000_000_ddd
;		     .B  (d,An)   Dn
	or.w	#%00_01_000_101_000_000,d0	;MOVE.B Dn,(d,An)
	bsr	wrt1wobj
	move.w	d2,d0			;d
	bra	wrt1wobj

;w=1:write
;MOVEP.wl Dn,(d,An)
;d7.w=0000_ddd_1_w_s_001_aaa
~movep91:
	move.w	d7,d6			;0000_ddd_1_w_s_001_aaa
	and.w	#%0000_111_000_000_111,d6	;0000_ddd_000_000_aaa
	lsr.w	#8,d7
	lsr.w	#1,d7			;0000_000_000_000_ddd
	bsr	getopsize
	subq.b	#SZ_LONG,d0
	beq	~movep911		;ロングでなければすべてワード
;MOVEP.W Dn,(d,An)
~movep910:
	or.w	#%1110_000_1_01_011_000,d7	;ROL.W #8,Dn
;d7.w=ROL.W #8,Dn
	bsr	~movep91dsp		;ROL.W #8,Dn;MOVE.B Dn,(d,An)
	bsr	~movep912dsp		;ROL.W #8,Dn;MOVE.B Dn,(d+2,An)
	bra	~movep92

;MOVEP.L Dn,(d,An)
~movep911:
	or.w	#%1110_000_1_10_011_000,d7	;ROL.L #8,Dn
;d7.w=ROL.L #8,Dn
	bsr	~movep91dsp		;ROL.L #8,Dn;MOVE.B Dn,(d,An)
	bsr	~movep912dsp		;ROL.L #8,Dn;MOVE.B Dn,(d+2,An)
	bsr	~movep912dsp		;ROL.L #8,Dn;MOVE.B Dn,(d+4,An)
	bsr	~movep912dsp		;ROL.L #8,Dn;MOVE.B Dn,(d+6,An)
~movep92:
;MOVEP展開終わり
;Anをずらしたときは元に戻す
	tst.w	d3
	beq	~movep921
	moveq.l	#%0000_000_000_000_111,d0
	and.w	d6,d0			;0000_000_000_000_aaa
;		        Dn   .L   An
	or.w	#%0101_000_1_10_001_000,d0	;SUBQ.L #8,An
	bsr	wrt1wobj
~movep921:
;MOVE.W (SP)+,CCR
;				(SP)+
	move.w	#%0100_0100_11_011_111,d0	;MOVE.W (SP)+,CCR
	bra	wrt1wobj

~movep99:
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~movep10
	bsr	softwarn
~movep10:
;ソフトエミュレーションなのでエラッタのチェックは不要
	bsr	getopsize		;サイズを得る
	cmpi.b	#SZ_WORD,d0
	beq	~movep9
	ori.w	#$0040,d7		;.l
~movep9:
	OPOUT
	move.b	#SZ_WORD,(RPNSIZE1,a1)	;サイズは必ず.w
	bra	eadataout

;----------------------------------------------------------------
getdspadr:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_DSPADR,d0
	beq	getdspadr1
	cmp.w	#EA_ADR,d0
	bne	iladrerr		;(d,An)/(An)でなければエラー
	move.b	#EAD_DSPADR,(EADTYPE,a1)
	move.w	#-1,(RPNLEN1,a1)
	clr.l	(RPNBUF1,a1)		;(An)→(0,An)
getdspadr1:
	move.w	(EACODE,a1),d1
	SETREGL
	rts

;----------------------------------------------------------------
;	moves	Rn,<ea>/<ea>,Rn		(68010/68020/68030/68040)
~moves::
	bsr	getreg			;レジスタオペランドを得る
	bmi	~moves1
	ror.w	#4,d1			;Rn,<ea>
	move.w	d1,d6
	or.w	#$0800,d6
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	bra	~moves2

~moves1:				;<ea>,Rn
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_MEM&EG_ALT,d0	;メモリ・可変モード
	beq	iladrerr
	CHKLIM
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	ror.w	#4,d1
	move.w	d1,d6
~moves2:
	bsr	setopsize		;オペレーションサイズのセット
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	bra	eadataout

;----------------------------------------------------------------
;	movec	Rc,Rn/Rn,Rc		(68010/68020/68030/68040)
~movec::
	bsr	getreg			;レジスタオペランドを得る
	bmi	~movec1
	ori.w	#$0001,d7		;Rn,Rc
	CHKLIM
	move.w	d1,d2
	bsr	getcreg
	bmi	iladrerr
	bra	~movec2

~movec1:				;Rc,Rn
;ColdFireのMOVECはwrite only
	tst.b	(CPUTYPE2,a6)
	bne	iladrerr
	bsr	getcreg
	bmi	iladrerr
	move.w	d1,d2
	CHKLIM
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	exg.l	d1,d2
~movec2:
	OPOUT				;命令コードの出力
	ror.w	#4,d2
	or.w	d2,d1
	move.w	d1,d0
	bsr	wrt1wobj		;特殊オペランドの出力
	rts

;----------------------------------------------------------------
;	bra/bsr/b<cc> 	<label>
~bcc::
;68000/68010/5200/5300にはロングディスプレースメントはない
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bne	~bcc00
	move.w	#C000|C010,d0
	and.w	(CPUTYPE,a6),d0
	bne	ilsizeerr_000_bccl
	move.w	#C520|C530,d0
	and.w	(CPUTYPE,a6),d0
	bne	ilsizeerr_cf_bccl
~bcc00:
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_ABSL,d0
	bne	iladrerr		;絶対ロングでなければエラー
	tst.w	(RPNLEN1,a1)
	bmi	ilrelerr_const		;<label>が定数ならエラー

	tst.b	(CMDOPSIZE,a6)
	bpl	~bcc_size		;サイズが指定された
	tst.b	(BRATOJBRA,a6)
	bne	~jbcc1			;-bスイッチがあるなら bra→jbra
	move.w	#T_BRA,d0
	bsr	wrtobjd0w
	move.w	d7,d0			;命令コード
	bsr	wrtd0w

	move.l	(EXTLEN,a6),d0
	addq.l	#2,d0
	add.l	d0,(LOCATION,a6)
	move.b	(EXTSIZE,a6),d0
	or.b	#ESZ_OPT,d0		;(最適化対象)
	bra	ead_outrpn

~bcc_size:
	move.w	#T_BRA,d0
	bsr	wrtobjd0w
	move.w	d7,d0			;命令コード
	bsr	wrtd0w
	addq.l	#2,(LOCATION,a6)
	move.b	(CMDOPSIZE,a6),d0
	cmp.b	#SZ_SHORT,d0
	beq	~bcc_size2
	tst.b	d0			;cmp.b #SZ_BYTE,d0
	bne	~bcc_size1
	move.b	#SZ_SHORT,(CMDOPSIZE,a6)	;SZ_BYTE→SZ_SHORT
	bra	~bcc_size2

~bcc_size1:
	bsr	getdtsize		;(ディスプレースメントサイズ指定あり)
	add.l	d0,(LOCATION,a6)
~bcc_size2:
	move.b	(CMDOPSIZE,a6),d0
	bra	ead_outrpn

;----------------------------------------------------------------
;	jbra/jbsr/jb<cc> <label>
~jbcc::
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
					;OPCに変更しない
	cmp.w	#EA_ABSL,d0
	bne	~jbcc5			;絶対ロングでなければjmp/jsrに決定
	tst.w	(RPNLEN1,a1)
	bmi	ilrelerr_const		;<label>が定数ならエラー
	move.b	(CMDOPSIZE,a6),d0
	bmi	~jbcc0_99		;サイズ指定なし
	subq.b	#SZ_LONG,d0
	bne	~bcc_size
;jbra.l/jbsr.l/jbcc.l
	move.w	#$4EB9,d0		;→jsr
	cmp.w	#$6100,d7
	beq	~jbcc0_jsr		;jbsr.l
	blo	~jbcc0_jmp		;jbra.l
;jbcc.l
	move.w	d7,d0			;命令コード
	eori.w	#$0106,d0		;条件を逆にしてjmpを飛び越える
	bsr	wrt1wobj
~jbcc0_jmp:
	move.w	#$4EF9,d0		;→jmp
~jbcc0_jsr:
	bsr	wrt1wobj
	bra	eadataout

~jbcc0_99:
~jbcc1:
	move.w	#T_JBRA,d0
	bsr	wrtobjd0w
	move.w	d7,d0			;命令コード
	bsr	wrtd0w
	moveq.l	#4,d1			;デフォルトが.wなら4バイト
	moveq.l	#ESZ_OPT|SZ_WORD,d0	;(最適化対象)
	tst.b	(EXTSHORT,a6)
	beq	~jbcc9
	moveq.l	#ESZ_OPT|SZ_LONG,d0	;(最適化対象)
	moveq.l	#6,d1			;jbra/jbsrは6バイト
	cmp.w	#$6100,d7
	bls	~jbcc9
	moveq.l	#8,d1			;jb<cc>は8バイト
~jbcc9:
	add.l	d1,(LOCATION,a6)
	bra	ead_outrpn

~jbcc5:					;絶対ロング以外のjbra/jbsrはjmp/jsrに決定
	and.w	#EG_CTRL,d0		;制御モード
	beq	iladrerr
	move.w	d7,d0
	move.w	#$4E80,d7		;(jsrの命令コード)
	cmp.w	#$6100,d0
	beq	~jbcc7			;jbsr → jsr
	bcs	~jbcc6			;jbra → jmp
	eori.w	#$0106,d0		;b<cc> → b</cc> $+8 & jmp
	bsr	wrt1wobj		;命令コードを出力する
~jbcc6:
	move.w	#$4EC0,d7		;(jmpの命令コード)
~jbcc7:
	or.w	(EACODE,a1),d7
	bsr	f43g_fifth		;5番目のチェック(不要?)
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	dbra/db<cc>	Dn,<label>
~dbcc::
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_ABSL,d0
	bne	iladrerr		;絶対ロングでなければエラー
	OPOUT
	tst.w	(RPNLEN1,a1)
	bmi	ilrelerr_const		;<label>が定数ならエラー
	move.b	#EAD_DSPPC,(EADTYPE,a1)	;(d,PC)と同じ処理を行う
	move.b	#SZ_WORD,(RPNSIZE1,a1)	;サイズは必ず.w
	sf.b	(OPTIONALPC,a1)		;OPCの処理が行われないようにする
	bra	eadataout

;----------------------------------------------------------------
;	trap	#xx
~trap::	
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	~trap_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d0
	cmp.l	#$10,d0
	bcc	ilvalueerr		;$10以上ならエラー
	or.w	d0,d7
	OPOUTrts

~trap_expr:
	addq.l	#2,(LOCATION,a6)	;式の場合
	move.w	#T_CODERPN|TCR_TRAP,d0
	bsr	wrtobjd0w
	move.w	d7,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	bra	ead_outrpn

;----------------------------------------------------------------
;	bkpt	#xx			(68010/68020/68030/68040)
~bkpt::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	~bkpt_expr		;式の値が未確定
	move.l	(RPNBUF1,a1),d0
	cmp.l	#8,d0
	bcc	ilvalueerr		;8以上ならエラー
	or.w	d0,d7
	OPOUTrts

~bkpt_expr:
	addq.l	#2,(LOCATION,a6)	;式の場合
	move.w	#T_CODERPN|TCR_BKPT,d0
	bsr	wrtobjd0w
	move.w	d7,d0
	bsr	wrtd0w
	moveq.l	#0,d0			;(サイズは無関係)
	bra	ead_outrpn

;----------------------------------------------------------------
;	trap<cc>	#xx		(68020/68030/68040)
~trapcc::
	bsr	gettrapccopr
	bra	eadataout

;----------------------------------------------------------------
;	trap<cc>,ftrap<cc>,ptrap<cc>のオペランドを得る
gettrapccopr:
	movea.l	(LINEPTR,a6),a0
	move.b	(a0),d0
	cmp.b	#'*',d0
	beq	gettrapccopr5
	cmp.b	#';',d0			;拡張モードのコメント
	beq	gettrapccopr5

	movem.w	d6-d7,-(sp)
	bsr	encodeopr		;オペランドをコード化する
	movem.w	(sp)+,d6-d7
	movea.l	(OPRBUFPTR,a6),a0
	lea.l	(EABUF1,a6),a1
	tst.w	(a0)
	beq	gettrapccopr5		;オペランドなし
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	bsr	getopsize		;サイズを得る
	addq.w	#1,d0			;b2-b0:.w=%010/.l=%011
	or.w	d0,d7
	OPOUTrts

gettrapccopr5:				;オペランドのないtrapcc
	tst.b	(CMDOPSIZE,a6)
	bpl	ilsizeerr_trapcc	;サイズなしでなければエラー
	addq.l	#asm1skipofst,(4,sp)	;スタック注意
					;行末のチェックは行わない
	lea.l	(EABUF1,a6),a1
	clr.b	(EADTYPE,a1)		;オペランドはない
	ori.w	#$0004,d7
	OPOUTrts

;----------------------------------------------------------------
;	stop	#xx
~stoprtd::
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	bsr	insigbitchksr
	OPOUT
	bra	eadataout

;----------------------------------------------------------------
;	rtd	#xx
~rtd::
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	OPOUT
	bra	eadataout

;----------------------------------------------------------------
;	lpstop	#xx
~lpstop::
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	bsr	insigbitchksr
	OPOUT
	move.w	#$01C0,d0
	bsr	wrt1wobj
	bra	eadataout

;----------------------------------------------------------------
insigbitchksr:
	move.w	#$46C0,d0
;d0:$44C0=ccr,$46C0=sr
insigbitchk:
	tst.w	(RPNLEN1,a1)
	bpl	insigbitchk2
	sub.w	#$4600,d0
	subx.w	d0,d0			;$FFFF=ccr,$0000=sr
	clr.b	d0			;$FF00=ccr,$0000=sr
	or.w	#$08E0,d0		;$FFE0=ccr,$08E0=sr
	and.w	(RPNBUF1+2,a1),d0
	bne	insigbitwarn
;000～010にはMがない
	move.w	#C020|C030|C040|C060|C520|C530|C540,d0
	and.w	(CPUTYPE,a6),d0
	bne	insigbitchk1
	btst.b	#12-8,(RPNBUF1+3-1,a1)	;000～010にはMがない
	bne	insigbitwarn
insigbitchk1:
;000～010と060とColdFireにはT0がない
	and.w	#C020|C030|C040,d0
	bne	insigbitchk2
	btst.b	#14-8,(RPNBUF1+3-1,a1)	;000～010と060とColdFireにはT0がない
	bne	insigbitwarn
insigbitchk2:
	rts

;----------------------------------------------------------------
;	callm	#xx,<ea>		(68020)
~callm::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_CTRL,d0		;制御モード
	beq	iladrerr
	clr.b	(CMDOPSIZE,a6)		;move.b #SZ_BYTE,(CMDOPSIZE,a6)
	or.w	(EACODE,a1),d7
	DSPOPOUT
	movea.l	a4,a1
	bsr	eadataout
	movea.l	a5,a1
	bra	eadataout

;----------------------------------------------------------------
;	rtm	Rn			(68020)
~rtm::
	bsr	getreg			;レジスタオペランドを得る
	bmi	iladrerr
	or.w	d1,d7
	OPOUTrts

;----------------------------------------------------------------
;	move16	(An)+,(An)+/xx,(An)/xx,(An)+/(An),xx/(An)+,xx	(68040)
~move16::
	movea.l	a4,a1
	movea.l	a4,a2
	bsr	getabsl
	move.w	d0,d2
	swap.w	d2
	CHKLIM
	movea.l	a5,a1
	bsr	getabsl
	move.w	d0,d2
	cmp.l	#EA_INCADR<<16|EA_INCADR,d2
	beq	~move16m
	cmp.w	#EA_ABSL,d2
	beq	~move161
	or.w	#$0008,d7		;xx,(An)/xx,(An)+
	swap.w	d2
	exg.l	a1,a2
	cmp.w	#EA_ABSL,d2
	bne	iladrerr
~move161:				;(An),xx/(An)+,xx
	swap.w	d2
	cmp.w	#EA_INCADR,d2
	beq	~move162		;(An)+
	cmp.w	#EA_ADR,d2
	bne	iladrerr
	or.w	#$0010,d7		;(An)
~move162:
	move.w	(EACODE,a2),d1
	SETREGL
	OPOUT
	bra	eadataout

~move16m:				;(An)+,(An)+
	or.w	#$0020,d7
	move.w	(EACODE,a4),d1
	SETREGL
	OPOUT				;命令コードの出力
	move.w	(EACODE,a5),d0
	and.w	#$0007,d0
	ror.w	#4,d0
	or.w	#$8000,d0
	bra	wrt1wobj		;特殊オペランドの出力

;----------------------------------------------------------------
getabsl:
	movem.l	d2/a2,-(sp)
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	clr.b	(ABSLTOOPCCAN,a6)
	movem.l	(sp)+,d2/a2
	move.w	d0,d1
	and.w	#EA_ABSL|EA_ABSW,d0
	beq	getabsl9		;xxxx.l/xxxx.wでなければなにもしない
	move.w	#EAC_ABSL,(EACODE,a1)
	move.b	#SZ_LONG,(RPNSIZE1,a1)
	move.w	#EA_ABSL,d1
getabsl9:
	bsr	f43g_fifth		;5番目のチェック
	move.w	d1,d0
	rts


;----------------------------------------------------------------
;	浮動小数演算命令
;----------------------------------------------------------------

;----------------------------------------------------------------
;	ftst	<ea>/FPn
~ftst::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~ftst1
	bsr	softwarn
~ftst1:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	move.b	(CMDOPSIZE,a6),d0
	bmi	fpeadataout
	cmp.b	#SZ_SINGLE,d0
	bcc	fpeadataout
;.b/.w/.l
	bra	fpeadataout_nop

;----------------------------------------------------------------
;	fabs/fneg	<ea>,FPn/FPn,FPn/FPn
~fabsneg::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	tst.w	(a0)
	beq	~fabsneg1		;オペランドは1つのみ
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1
	or.w	d1,d6
	bra	~fabsneg2

~fabsneg1:				;オペランドが1つの場合
	btst.l	#14,d6
	bne	iladrerr		;オペランドが実効アドレスならエラー
	move.w	d6,d1			;ソースとデスティネーションFPレジスタは同じ
	and.w	#$1C00,d1
	lsr.w	#3,d1
	or.w	d1,d6
~fabsneg2:
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fabsneg3
	bsr	softwarn
~fabsneg3:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力

	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	fpeadataout
	move.b	(CMDOPSIZE,a6),d0
	bmi	fpeadataout
	cmp.b	#SZ_SINGLE,d0
	bcc	fpeadataout
;.b/.w/.l
	bra	fpeadataout_nop

;----------------------------------------------------------------
;	fint/fintrz	<ea>,FPn/FPn,FPn/FPn
~fint::
;fint/fintrzは68040ではソフトウェアエミュレーション
	ori.w	#C040,(SOFTFLAG,a6)
	bra	~funary

;----------------------------------------------------------------
;	f<unary>	<ea>,FPn/FPn,FPn/FPn
~funarys::
;fsinh/flognp1/fetoxm1/ftanh/fatan/fasin/fatanh/fsin/ftan/fetox/ftwotox/ftentox
;flogn/flog10/flog2/fcosh/facos/fcos/fgetexp/fgetmanは68040,68060では
;ソフトウェアエミュレーション
	ori.w	#C040|C060,(SOFTFLAG,a6)
;	bra	~funary

;----------------------------------------------------------------
;	f<unary>	<ea>,FPn/FPn,FPn/FPn
~funary::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	tst.w	(a0)
	beq	~funary1		;オペランドは1つのみ
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1
	or.w	d1,d6
	bra	~funary2

~funary1:				;オペランドが1つの場合
	btst.l	#14,d6
	bne	iladrerr		;オペランドが実効アドレスならエラー
	move.w	d6,d1			;ソースとデスティネーションFPレジスタは同じ
	and.w	#$1C00,d1
	lsr.w	#3,d1
	or.w	d1,d6
~funary2:
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~funary3
	bsr	softwarn
~funary3:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	fpeadataout
	bra	fpeadataout_nop

;----------------------------------------------------------------
;	fcmp	<ea>,FPn/FPn,FPn
~fcmp::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1
	or.w	d1,d6
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fcmp1
	bsr	softwarn
~fcmp1:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力

	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	fpeadataout
	move.b	(CMDOPSIZE,a6),d0
	bmi	fpeadataout
	cmp.b	#SZ_SINGLE,d0
	bcc	fpeadataout
;.b/.w/.l
	bra	fpeadataout_nop

;----------------------------------------------------------------
;	fsgldiv/fsglmul	<ea>,FPn/FPn,FPn
~fsgl::
;fsgldiv,fsglmulは68040ではソフトウェアエミュレーション
	ori.w	#C040,(SOFTFLAG,a6)
;	bra	~fopr

;----------------------------------------------------------------
;	f<opr>	<ea>,FPn/FPn,FPn
~fopr::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1
	or.w	d1,d6
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fopr1
	bsr	softwarn
~fopr1:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	fpeadataout
fpeadataout_nop:
;F43G対策
	tst.b	(F43GTEST,a6)
	beq	fpeadataout
	bsr	fpeadataout
	bsr	flushobj		;GETFPTRが正しい値を返すために必要
;コプロセッサ命令の直後にT_NOPDEATHを出力しておく
	move.l	a0,-(sp)		;a0を破壊しないこと
	movea.l	(F43GPTR,a6),a0
	GETFPTR	TEMPFILPTR,d0		;現在のファイルポインタ
	move.l	d0,(8,a0)		;T_NOPDEATHを挿入した位置
	ori.b	#%00001,(12,a0)		;1番目の命令に該当する
	movea.l	(sp)+,a0
	move.w	#T_NOPDEATH+1,d0
	bsr	wrtobjd0w
	move.w	#$4E71,d0		;NOP
	bsr	wrtd0w
	addq.l	#2,(LOCATION,a6)
	rts

;----------------------------------------------------------------
;	fsincos	<ea>,FPc:FPs/FPn,FPc:FPs
~fsincos::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpopr		;<ea>/FPオペランドを得る
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	or.w	d1,d6			;FPc
	cmp.w	#':'|OT_CHAR,(a0)+
	bne	iladrerr
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1			;FPs
	or.w	d1,d6
	move.w	#C040|C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~fsincos1
	bsr	softwarn
~fsincos1:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	fpeadataout

;----------------------------------------------------------------
;	浮動小数点実効アドレス/データレジスタオペランドを得る
getfpopr:
	movea.l	a4,a1
	bsr	getfpreg		;浮動小数点データレジスタを得る
	beq	getfpopr5
	or.w	#$4000,d6		;<ea>
	bsr	getfpeamode		;実効アドレスオペランドを得る
	and.w	#EG_DATA,d0		;データモード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	bra	setfpopsize		;浮動小数点オペレーションサイズのセット

getfpopr5:				;FPn
	move.b	#EAD_NONE,(EADTYPE,a1)	;データは不要
	ror.w	#6,d1
	or.w	d1,d6			;ソースレジスタのセット
	move.b	(CMDOPSIZE,a6),d0
	bmi	getfpopr6
	cmp.b	#SZ_EXTEND,d0
	bne	ilsizeerr_fpn		;.x以外のサイズはエラー
getfpopr6:
	rts

;----------------------------------------------------------------
;	fmove	FPn,FPn/<ea>,FPn/FPn,<ea>/FPn,<ea>{Dn}/FPn,<ea>{#x}/<ea>,FPcr/FPcr,<ea>
~fmove::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	move.w	(a0),d0
	cmp.w	#REG_FPCR|OT_REGISTER,d0
	bcs	~fmove1
	cmp.w	#REG_FPIAR|OT_REGISTER,d0
	bls	~fmove_frcr		;fmove FPcr,<ea>
~fmove1:
	bsr	getfpreg		;浮動小数点データレジスタを得る
	beq	~fmove5			;fmove FPn,<ea>/FPn
					;fmove <ea>,FPn/FPcr
	movea.l	a4,a1
	or.w	#$4000,d6		;<ea>
	bsr	getfpeamode		;実効アドレスオペランドを得る
	move.w	d0,d2
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	~fmove_tocr		;fmove <ea>,FPcr

	lsl.w	#7,d1			;fmove <ea>,FPn
	or.w	d1,d6
	and.w	#EG_DATA,d2		;データモード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	bsr	setfpopsize		;浮動小数点オペレーションサイズのセット
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fmove10
	bsr	softwarn
~fmove10:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	move.w	#C060,d0
	and.w	(SOFTFLAG,a6),d0
	bne	fpeadataout
	move.b	(CMDOPSIZE,a6),d0
	bmi	fpeadataout
	cmp.b	#SZ_SINGLE,d0
	bcc	fpeadataout
;.b/.w/.l
	bra	fpeadataout_nop

~fmove5:				;fmove FPn,<ea>/FPn
	ror.w	#6,d1
	or.w	d1,d6			;ソースレジスタのセット
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	beq	~fmove8			;fmove FPn,FPn

	lsr.w	#3,d6			;fmove FPn,<ea>
	and.w	#$0380,d6
	or.w	#$6000,d6		;コプロセッサ命令ワード
	movea.l	a4,a1
	bsr	getfpeamode_noopc	;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	bsr	setfpopsize		;浮動小数点オペレーションサイズのセット
	cmpi.b	#SZ_PACKED,(CMDOPSIZE,a6)
	bne	~fmove6
	bsr	getkfactor		;.pの場合,kファクタを得る
~fmove6:
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fmove11
	bsr	softwarn
~fmove11:
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	fpeadataout

~fmove8:				;fmove FPn,FPn
	lsl.w	#7,d1
	or.w	d1,d6
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmove9
	cmp.b	#SZ_EXTEND,d0
	bne	ilsizeerr_fpn		;.x以外のサイズはエラー
~fmove9:
	OPOUT
	move.w	d6,d0
	bra	wrt1wobj		;コプロセッサ命令ワードの出力

~fmove_frcr:				;fmove FPcr,<ea>
	move.w	#$A000,d6		;コプロセッサ命令ワード
	addq.l	#2,a0
	sub.w	#REG_FPCR|OT_REGISTER,d0
	move.w	#$1000,d1
	lsr.w	d0,d1			;FP制御レジスタの選択
	or.w	d1,d6
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmove_frcr1
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr_fpcr		;.l以外のサイズはエラー
~fmove_frcr1:
	move.b	#SZ_LONG,(CMDOPSIZE,a6)
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_AN,d0
	bne	~fmove_frcr2
	cmp.w	#$A400,d6		;アドレスレジスタ直接が使えるのはFPIARのみ
	bne	iladrerr
	bra	~fmove_frcr3

~fmove_frcr2:
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
~fmove_frcr3:
	or.w	(EACODE,a1),d7
	bsr	f43g_fourth		;4番目と5番目のチェック
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	eadataout

~fmove_tocr:				;fmove <ea>,FPcr
	move.w	#$8000,d6		;コプロセッサ命令ワード
	move.w	(a0)+,d0
	sub.w	#REG_FPCR|OT_REGISTER,d0
	bcs	iloprerr
	cmp.w	#REG_FPIAR-REG_FPCR,d0
	bhi	iloprerr		;オペランドがFPCR/FPSR/FPIARでない
	move.w	#$1000,d1
	lsr.w	d0,d1			;FP制御レジスタの選択
	or.w	d1,d6
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmove_tocr1
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr_fpcr		;.l以外のサイズはエラー
~fmove_tocr1:
	move.b	#SZ_LONG,(CMDOPSIZE,a6)
	cmp.w	#EA_AN,d2
	bne	~fmove_tocr2
	cmp.w	#$8400,d6		;アドレスレジスタ直接が使えるのはFPIARのみ
	bne	iladrerr
~fmove_tocr2:
	or.w	(EACODE,a1),d7
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	fpeadataout

;----------------------------------------------------------------
;	fmovem	<list>,<ea>/Dn,<ea>/<ea>,<list>/<ea>,Dn
~fmovem::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	bsr	getfpreglist		;FPデータレジスタリストオペランドを得る
	beq	~fmovem6
	bsr	getfpcreglist		;FP制御レジスタリストオペランドを得る
	beq	~fmovem_c5
	bsr	getdreg			;データレジスタオペランドを得る
	beq	~fmovem5

	movea.l	a4,a1			;<ea>,<list>/Dn
	bsr	getfpeamode		;実効アドレスオペランドを得る
	move.w	d0,-(sp)
	CHKLIM
	bsr	getfpcreglist		;FP制御レジスタリストオペランドを得る
	beq	~fmovem_c1
	and.w	#EG_CTRL|EA_INCADR,(sp)+	;制御モードまたは(An)+
	beq	iladrerr
	bsr	getfpreglist		;FPデータレジスタリストオペランドを得る
	beq	~fmovem2
	bsr	getdreg			;データレジスタオペランドを得る
	bne	iladrerr
~fmovem1:				;<ea>,Dn 動的レジスタリスト
	ori.w	#C040|C060,(SOFTFLAG,a6)
	lsl.w	#4,d1
	or.w	d1,d6
	or.w	#$1800,d6
	bra	~fmovem9

~fmovem2:				;<ea>,<list> 静的レジスタリスト
	or.w	d1,d6
	or.w	#$1000,d6
	bra	~fmovem9

~fmovem5:				;Dn,<ea> 動的レジスタリスト
	ori.w	#C040|C060,(SOFTFLAG,a6)
	move.w	d1,(EACODE,a4)
	lsl.w	#4,d1
	or.w	d1,d6
	or.w	#$3800,d6
	CHKLIM
	bsr	getfpcreglist		;FP制御レジスタリストオペランドを得る
	bne	~fmovem7
	clr.w	(SOFTFLAG,a6)
	movea.l	a4,a1			;Dn,<list> だった場合
	move.b	#EAD_NONEREG,(EADTYPE,a1)
	move.w	#EA_DN,-(sp)
	bra	~fmovem_c1

~fmovem6:				;<list>,<ea> 静的レジスタリスト
	or.w	d1,d6
	or.w	#$3000,d6
	CHKLIM
~fmovem7:
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	move.w	d0,d2
	and.w	#EG_CTRL&EG_ALT,d2	;制御・可変モード
	bne	~fmovem9
	cmp.w	#EA_DECADR,d0		;-(An)
	bne	iladrerr
	and.w	#.not.$1000,d6
	btst.l	#11,d6
	bne	~fmovem9
	moveq.l	#8-1,d2			;静的レジスタリストの場合は反転する
~fmovem8:
	roxl.b	#1,d6
	roxr.b	#1,d1
	dbra	d2,~fmovem8
	move.b	d1,d6
~fmovem9:
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmovem10
	cmp.b	#SZ_EXTEND,d0
	bne	ilsizeerr_fmovemfpn	;.xでなければエラー
~fmovem10:
	or.w	(EACODE,a1),d7
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fmovem11
	bsr	softwarn
~fmovem11:
	bsr	f43g_fourth		;4番目と5番目のチェック
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	eadataout

~fmovem_c1:				;<ea>,FPcr
	move.w	#$8000,d6		;コプロセッサ命令ワード
	or.w	d1,d6
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmovem_c2
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr_fmovemfpcr	;.l以外のサイズはエラー
~fmovem_c2:
	move.w	(sp)+,d0
	cmp.w	#EA_DN,d0
	beq	~fmovem_c8
	cmp.w	#EA_AN,d0
	beq	~fmovem_c9
	cmp.w	#EA_IMM,d0
	bne	~fmovem_c7
	cmp.b	(EAIMMCNT,a1),d2	;イミディエイトの場合
	bne	iloprerr		;データ数とレジスタ数が一致しなければエラー
;2個以上のFPcrに対するfmovem.l #imm,FPcrはソフトウェアエミュレーション
	tst.b	d2
	beq	~fmovem_c201
	ori.w	#C040|C060,(SOFTFLAG,a6)
~fmovem_c201:
	add.b	#SZ_SINGLE,d2
	move.b	d2,(CMDOPSIZE,a6)
	bra	~fmovem_c7

~fmovem_c5:				;FPcr,<ea>
	move.w	#$A000,d6		;コプロセッサ命令ワード
	or.w	d1,d6
	move.b	(CMDOPSIZE,a6),d0
	bmi	~fmovem_c6
	cmp.b	#SZ_LONG,d0
	bne	ilsizeerr		;.l以外のサイズはエラー
~fmovem_c6:
	move.b	#SZ_LONG,(CMDOPSIZE,a6)
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_DN,d0
	beq	~fmovem_c8
	cmp.w	#EA_AN,d0
	beq	~fmovem_c9
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
~fmovem_c7:
	or.w	(EACODE,a1),d7
	move.w	(CPUTYPE,a6),d0
	and.w	(SOFTFLAG,a6),d0
	beq	~fmovem_c10
	bsr	softwarn
~fmovem_c10:
	bsr	f43g_fourth		;4番目と5番目のチェック
	DSPOPOUT
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ命令ワードの出力
	bra	fpeadataout

~fmovem_c8:				;データレジスタ直接の場合
	move.w	d6,d0			;データレジスタ直接が使えるのは
	and.w	#$1C00,d0		;レジスタが1つのときのみ
	move.w	d0,d1
	subq.w	#1,d1
	and.w	d1,d0
	beq	~fmovem_c7
	bra	iladrerr

~fmovem_c9::				;アドレスレジスタ直接の場合
	move.w	d6,d0
	and.w	#$1C00,d0
	cmp.w	#$0400,d0		;アドレスレジスタ直接が使えるのはFPIARのみ
	beq	~fmovem_c7
	bra	iladrerr

;----------------------------------------------------------------
;	fmovecr	#cc,FPn
~fmovecr::
	move.w	d7,d6			;コプロセッサ命令ワード
	move.w	#$F000,d7		;命令コード
	or.w	(FPCPID,a6),d7		;コプロセッサID

	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	exprerr			;定数が得られなければエラー
	move.l	(RPNBUF1,a1),d1
	cmp.l	#$7F,d1			;ROMオフセットは$00～$7F
	bhi	ilvalueerr
	or.w	d1,d6
	CHKLIM
	bsr	getfpreg		;浮動小数点データレジスタを得る
	bmi	iladrerr
	lsl.w	#7,d1
	or.w	d1,d6
;fmovecrはソフトウェアエミュレーション
	move.w	#C040|C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~fmovecr1
	bsr	softwarn
~fmovecr1:
	OPOUT				;命令コードの出力
	move.w	d6,d0
	bra	wrt1wobj		;コプロセッサ命令ワードの出力

;----------------------------------------------------------------
;	fnop
~fnop::
	or.w	(FPCPID,a6),d7		;コプロセッサID
	OPOUT				;命令コードの出力
	addq.l	#asm1skipofst,(sp)	;行末のチェックは行わない
	moveq.l	#0,d0
	bra	wrt1wobj

;----------------------------------------------------------------
;	fb<cc>	<label>
~fbcc::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cpbcc:
	or.w	d0,d7
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_ABSL,d0
	bne	iladrerr		;絶対ロングでなければエラー
	tst.w	(RPNLEN1,a1)
	bmi	ilrelerr_const		;<label>が定数ならエラー

	move.w	#T_CPBRA,d0
	bsr	wrtobjd0w
	move.w	d7,d0			;命令コード
	bsr	wrtd0w
	move.b	(CMDOPSIZE,a6),d0
	bpl	~cpbcc_size		;サイズが指定された
	move.l	(EXTLEN,a6),d0
	addq.l	#2,d0
	add.l	d0,(LOCATION,a6)
	move.b	(EXTSIZE,a6),d0
	or.b	#ESZ_OPT,d0		;(最適化対象)
	bra	ead_outrpn

~cpbcc_size:
	bsr	getdtsize
	addq.l	#2,d0
	add.l	d0,(LOCATION,a6)
	move.b	(CMDOPSIZE,a6),d0
	bra	ead_outrpn

;----------------------------------------------------------------
;	fdb<cc>	Dn,<label>
~fdbcc::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cpdbcc:
	move.w	d7,d6			;コプロセッサ条件ワード
	move.w	#$F048,d7		;命令コード
	or.w	d0,d7
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	cmp.w	#EA_ABSL,d0
	bne	iladrerr		;絶対ロングでなければエラー
;fdbccは68060ではソフトウェアエミュレーション
;cpdbccもここを通るがこのままでよい
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~fdbcc1
	bsr	softwarn
~fdbcc1:
	OPOUT				;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ条件ワードの出力
	tst.w	(RPNLEN1,a1)
	bmi	ilrelerr_const		;<label>が定数ならエラー
	move.b	#EAD_DSPPC,(EADTYPE,a1)	;(d,PC)と同じ処理を行う
	move.b	#SZ_WORD,(RPNSIZE1,a1)	;サイズは必ず.w
	sf.b	(OPTIONALPC,a1)		;OPCの処理が行われないようにする
	bra	eadataout

;----------------------------------------------------------------
;	frestore	<ea>
~frestore::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cprestore:
	or.w	d0,d7
	move.w	#EG_CTRL|EA_INCADR,d6	;制御モードまたは(An)+
	bra	~cpsave1

;----------------------------------------------------------------
;	fsave	<ea>
~fsave::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cpsave:
	or.w	d0,d7
	move.w	#(EG_CTRL&EG_ALT)|EA_DECADR,d6	;制御・可変モードまたは-(An)
~cpsave1:
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	d6,d0
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT
	bra	eadataout

;----------------------------------------------------------------
;	fs<cc>	<ea>
~fscc::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cpscc:
	move.w	d7,d6			;コプロセッサ条件ワード
	move.w	#$F040,d7		;命令コード
	or.w	d0,d7
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_DATA&EG_ALT,d0	;データ・可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	move.w	(X_FSCC,a6),d0		;FScc→FBcc
	and.w	(CPUTYPE,a6),d0
	beq	~fscc99			;展開しない
;fscc dnのマクロ展開(fscc eaはeaを2回出力することになるので保留)
;	fscc	.macro	dn
;		st.b	dn
;		fbcc.w	@true		;(*)+2+4
;		sf.b	dn
;	@true:
;		.endm
;コプロセッサ条件ワードが$0010以上のときはBSUNの処理を伴うので簡単には展開できない
;NANでないときだけ展開して,NANのときは060SPに任せる
;		fbun.w	1f		;NANのときは060SPを使う
;		st.b	d0		;SET
;		fbcc.w	2f
;		sf.b	d0		;CLEAR(clr.bはccrが変化してしまうので使えない)
;		.dc.w	$51FB		;TRAPF.L #immで次の2ワードをスキップする
;	1:	fscc.b	d0		;060SP
;	2:
	moveq.l	#%111_000,d0
	and.w	d7,d0
	bne	~fscc99			;dnでないので展開しない
	cmp.w	#16,d6
	bhs	~fscc_1			;BSUNの処理を伴う
;BSUNの処理を伴わない
	tst.w	d6
	beq	~fscc_0			;FSFのとき
	moveq.l	#%000_111,d0
	and.w	d7,d0			;n
;			cc        Dn
	or.w	#%0101_0000_11_000_000,d0	;ST.B Dn
	cmp.w	#15,d6
	beq	wrt1wobj		;FSTのとき
	bsr	wrt1wobj
	move.w	#$0E00,d0
	and.w	d7,d0			;id
;			id    s   cc
	or.w	#%1111_000_01_0_000000,d0	;FBcc.W
	or.w	d6,d0			;condition
	bsr	wrt1wobj
	moveq.l	#4,d0
	bsr	wrt1wobj
~fscc_0:
	moveq.l	#%000_111,d0
	and.w	d7,d0			;n
;			cc        Dn
	or.w	#%0101_0001_11_000_000,d0	;SF.B Dn
	bra	wrt1wobj

;BSUNの処理を伴う
~fscc_1:
	move.w	#$0E00,d0
	and.w	d7,d0			;id
;			id    s   cc
	or.w	#%1111_000_01_0_001000,d0	;FBUN.W
	bsr	wrt1wobj
	moveq.l	#10,d0
	bsr	wrt1wobj
	moveq.l	#%000_111,d0
	and.w	d7,d0			;n
;			cc        Dn
	or.w	#%0101_0000_11_000_000,d0	;ST.B Dn
	move.w	#$0E00,d0
	and.w	d7,d0			;id
;			id    s   cc
	or.w	#%1111_000_01_0_000000,d0	;FBcc.W
	or.w	d6,d0			;condition
	bsr	wrt1wobj
	moveq.l	#10,d0
	bsr	wrt1wobj
	moveq.l	#%000_111,d0
	and.w	d7,d0			;n
;			cc        Dn
	or.w	#%0101_0001_11_000_000,d0	;SF.B Dn
	bsr	wrt1wobj
;			cc          s
	move.w	#%0101_0001_1111101_1,d0	;TRAPF.L
	bsr	wrt1wobj
	move.w	d7,d0			;FScc.B Dn
	bsr	wrt1wobj
	move.w	d6,d0
	bra	wrt1wobj

~fscc99:
;fsccは68060ではソフトウェアエミュレーション
;cpsccもここを通るがこのままでよい
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~fscc1
	bsr	softwarn
~fscc1:
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ条件ワードの出力
	bra	eadataout

;----------------------------------------------------------------
;	ftrap<cc>	#xx
~ftrapcc::
	move.w	(FPCPID,a6),d0		;コプロセッサID
~cptrapcc:
	move.w	d7,d6			;コプロセッサ条件ワード
	move.w	#$F078,d7		;命令コード
	or.w	d0,d7
	bsr	gettrapccopr
;ftrapccは68060ではソフトウェアエミュレーション
;cptrapccもここを通るがこのままでよい
	move.w	#C060,d0
	or.w	d0,(SOFTFLAG,a6)
	and.w	(CPUTYPE,a6),d0
	beq	~ftrapcc1
	bsr	softwarn
~ftrapcc1:
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサ条件ワードの出力
	bra	eadataout


;----------------------------------------------------------------
;	68040/68060キャッシュ制御命令
;----------------------------------------------------------------

;----------------------------------------------------------------
;	cinva/cpusha	<caches>	(68040)
~cinvpusha::
	bsr	getcache		;キャッシュ選択を得る
	or.w	d1,d7
	OPOUTrts

;----------------------------------------------------------------
;	cinv[lp]/cpush[lp]	<caches>,(An)	(68040)
~cinvpushlp::
;ColdFireのcpushl (An)はcpushl BC,(An)に相当する
	tst.b	(CPUTYPE2,a6)
	bne	~cinvpushlp1
;ColdFireでないときNC/DC/IC/BCが必要
	bsr	getcache		;キャッシュ選択を得る
	bra	~cinvpushlp2

~cinvpushlp1:
;ColdFireのときBCのみでBCは省略可能
	move.w	#$00C0,d1		;BC
	cmpi.w	#REG_BC|OT_REGISTER,(a0)
	bne	~cinvpushlp3
	addq.l	#2,a0
~cinvpushlp2:
	CHKLIM
~cinvpushlp3:
	or.w	d1,d7
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_ADR,d0
	bne	iladrerr		;(An)でなければエラー
	move.w	(EACODE,a1),d1
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
getcache:
	move.w	(a0)+,d0
	clr.w	d1
	cmp.w	#REG_NC|OT_REGISTER,d0
	beq	getcache9
	move.w	#$0040,d1
	cmp.w	#REG_DC|OT_REGISTER,d0
	beq	getcache9
	move.w	#$0080,d1
	cmp.w	#REG_IC|OT_REGISTER,d0
	beq	getcache9
	move.w	#$00C0,d1
	cmp.w	#REG_BC|OT_REGISTER,d0
	bne	iladrerr
getcache9:
	rts


;----------------------------------------------------------------
;	PMMU制御命令
;----------------------------------------------------------------

;----------------------------------------------------------------
;	pmove	MRn,<ea>/<ea>,MRn	(68851/68030)
~pmove::
	move.l	#((EG_CTRL&EG_ALT)<<16)|(EG_CTRL&EG_ALT),d5
	move.w	(CPUTYPE,a6),d1		;68030では MRn,<ea>/<ea>,MRn とも制御・可変モード
	and.w	#CMMU,d1
	beq	~pmove1
	move.l	#(EG_ALT<<16)|$FFFF,d5	;68851では MRn,<ea> は可変モード/<ea>,MRn はすべて
~pmove1:
	bsr	getmreg
	bmi	~pmove5
	or.w	#$0200,d7		;MRn,<ea>
	or.w	d1,d7
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	move.w	d0,d6
	swap.w	d5
	and.w	d5,d0			;可変 or 制御・可変
	beq	iladrerr
	bra	~pmove6
~pmove5:				;<ea>,MRn
	movea.l	a4,a1
	cmp.b	#SZ_LONG,(CMDOPSIZE,a6)
	bls	~pmove501		;.B/.W/.Lが指定されたときはgeteamodeでよい
	cmpi.w	#'#'|OT_CHAR,(a0)
	bne	~pmove501		;イミディエイト以外はgeteamodeでよい
	clr.w	(RPNLEN1,a1)
	clr.w	(RPNLEN2,a1)
;1個目
	addq.l	#2,a0			;#
	cmpi.w	#OT_VALUEQ,(a0)
	bne	~pmove502		;符号つき32bitにおさまっていれば普通に1つ取得
	tst.l	(2,a0)			;上位32bit
	beq	~pmove502		;上位32bitが0ならば普通に1つ取得
	move.b	(2+4,a0),d0		;下位32bitの最上位バイト
	add.b	d0,d0
	subx.l	d0,d0			;下位32bit>=ならば0,下位32bit<0ならば-1
	cmp.l	(2,a0),d0		;上位32bitが下位32bitの符号拡張と一致するか
	beq	~pmove502		;上位32bitが下位32bitの符号拡張ならば普通に1つ取得
	cmpi.w	#','|OT_CHAR,(2+4+4,a0)
	beq	~pmove506
	cmpi.w	#SZ_QUAD|OT_SIZE,(2+4+4,a0)
	bne	~pmove502		;64bit整数の後ろに.q以外の何かが書いてある
	cmpi.w	#','|OT_CHAR,(2+4+4+2,a0)
	bne	~pmove502		;64bit整数の後ろに.q以外の何かが書いてある
~pmove506:
	moveq.l	#-1,d0
	move.w	d0,(RPNLEN1,a1)
	move.w	d0,(RPNLEN2,a1)
	addq.l	#2,a0			;OT_VALUEQ
	move.l	(a0)+,(RPNBUF1,a1)	;上位32bit
	move.l	(a0)+,(RPNBUF2,a1)	;下位32bit
	cmpi.w	#OT_SIZE|SZ_QUAD,(a0)
	bne	~pmove507
	addq.l	#2,a0
~pmove507:
	bra	~pmove508

~pmove502:
	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr		;1個目
	tst.w	d0
	bmi	iloprerr		;#で始まっていてquadでもないのに1個も取得できない
	movea.l	a0,a3
	moveq.l	#1-1,d3
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	~pmove503		;1個で終わり
;2個目
	cmpi.w	#'#'|OT_CHAR,(a0)
	bne	~pmove504
	addq.l	#2,a0
~pmove504:
	cmpi.w	#OT_VALUEQ,(a0)
	bne	~pmove505		;符号つき32bitにおさまっていれば普通に1つ取得
	tst.l	(2,a0)			;上位32bit
	beq	~pmove505		;上位32bitが0ならば普通に1つ取得
	move.b	(2+4,a0),d0		;下位32bitの最上位バイト
	add.b	d0,d0
	subx.l	d0,d0			;下位32bit>=ならば0,下位32bit<0ならば-1
	cmp.l	(2,a0),d0		;上位32bitが下位32bitの符号拡張と一致するか
	bne	~pmove503		;上位32bitが下位32bitの符号拡張ではない
					;2個目が32bitにおさまらないと3個になってしまうので
					;イミディエイトオペランドの続きとはみなさない
~pmove505:
	lea.l	(RPNBUF2,a1),a2
	bsr	geteaexpr		;2個目
	tst.w	d0
	bmi	~pmove503		;2個目はなかった
~pmove508:
	movea.l	a0,a3
	moveq.l	#2-1,d3
~pmove503:
	movea.l	a3,a0
	move.b	d3,(EAIMMCNT,a1)
	move.w	#EAC_IMM,(EACODE,a1)
	move.b	#EAD_IMM,(EADTYPE,a1)
	move.w	#EA_IMM,d0
	bra	~pmove599

~pmove501:
	clr.b	(EAIMMCNT,a1)
	bsr	geteamode
~pmove599:
	move.w	d0,d6
	and.w	d5,d0			;すべてのモード or 制御・可変
	beq	iladrerr
	CHKLIM
	bsr	getmreg			;PMMUレジスタを得る
	bmi	iladrerr
	or.w	d1,d7
~pmove6:
	cmpi.b	#SZ_QUAD,(CMDOPSIZE,a6)
	bne	~pmove9
	and.w	#EA_DN|EA_AN,d6		;レジスタ直接はCRP,SRP,DRPに対しては使えない
	bne	iladrerr
~pmove9:
	cmp.w	#$6100,d7		;pmovefd <ea>,MMUSR ならエラー
	beq	iladrerr
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	cmpi.b	#EAD_IMM,(EADTYPE,a1)
	bne	eadataout
	cmpi.b	#SZ_QUAD,(CMDOPSIZE,a6)	;68881のDOUBLEはQUADに変換済み
	beq	~pmove90
	tst.b	(EAIMMCNT,a1)
	bne	iloprerr		;quad以外は1個だけ
	bra	eadataout

;PMOVEfd #imm,CRP/SRP/DRP
~pmove90:
	tst.w	(RPNLEN1,a1)
	bpl	iloprerr		;定数以外は不可
	tst.b	(EAIMMCNT,a1)
	beq	~pmove91		;データが1個しかないとき
	tst.w	(RPNLEN2,a1)
	bpl	iloprerr		;定数以外は不可
	move.l	(RPNBUF1,a1),d0
	bsr	wrt1lobj
	move.l	(RPNBUF2,a1),d0
	bra	wrt1lobj

~pmove91:
	move.l	(RPNBUF1,a1),d0		;下位32bit
	add.l	d0,d0
	subx.l	d0,d0			;上位32bitは下位32bitを符号拡張して求める
	bsr	wrt1lobj		;($00000000FFFFFFFFはencode.sでOT_VALUEQになっている)
	move.l	(RPNBUF1,a1),d0		;下位32bit
	bra	wrt1lobj

;----------------------------------------------------------------
;	pmovefd	<ea>,MRn		(68030)
~pmovefd::
	move.w	#EG_CTRL&EG_ALT,d5
	bra	~pmove5			;<ea>,MRn のみ

;----------------------------------------------------------------
;	PMMUレジスタを得る
getmreg:
	move.w	(a0),d0
	move.b	d0,d1
	clr.b	d0
	cmp.w	#OT_REGISTER,d0
	bne	getmreg9
	cmp.b	#REG_BAD0,d1
	bcs	getmreg4
	cmp.b	#REG_BAC7,d1
	bls	getmreg_ba
getmreg4:
	lea.l	(getmtbl,pc),a1
getmreg5:
	move.b	(a1)+,d0
	beq	getmreg9
	cmp.b	d0,d1
	beq	getmreg6
	addq.l	#2,a1
	bra	getmreg5

getmreg6:
	move.b	(a1)+,d0
	bpl	getmreg7
	moveq.l	#SZ_QUAD,d0		;CRP,SRP,DRPの場合
	move.w	(CPUTYPE,a6),d1
	and.w	#CMMU,d1
	beq	getmreg7		;68030なら.qのみ
	cmpi.b	#SZ_DOUBLE,(CMDOPSIZE,a6)
	beq	getmreg8		;68851なら.qか.d
getmreg7:
	move.b	(CMDOPSIZE,a6),d1
	bmi	getmreg8
	cmp.b	d0,d1
	bne	ilsizeerr
getmreg8:
	move.b	d0,(CMDOPSIZE,a6)
	move.b	(a1)+,d1
	lsl.w	#8,d1
	addq.l	#2,a0
	moveq.l	#0,d0
	rts

getmreg9:				;PMMUレジスタが得られなかった
	moveq.l	#-1,d0
	rts

getmreg_ba:				;BADn,BACnの場合
	move.b	d1,d0
	and.w	#$0007,d1
	lsl.w	#2,d1
	or.w	#$7000,d1		;BAD0～BAD7
	cmp.b	#REG_BAC0,d0
	bcs	getmreg_ba1
	or.w	#$0400,d1		;BAC0～BAC7
getmreg_ba1
	move.b	(CMDOPSIZE,a6),d0
	bmi	getmreg_ba9
	cmp.b	#SZ_WORD,d0
	bne	ilsizeerr
getmreg_ba9:
	move.b	#SZ_WORD,(CMDOPSIZE,a6)
	addq.l	#2,a0
	moveq.l	#0,d0
	rts

getmtbl:
	.dc.b	REG_TC,  SZ_LONG,$40
	.dc.b	REG_DRP, SZ_NONE,$44
	.dc.b	REG_SRP, SZ_NONE,$48
	.dc.b	REG_CRP, SZ_NONE,$4C
	.dc.b	REG_CAL, SZ_BYTE,$50
	.dc.b	REG_VAL, SZ_BYTE,$54
	.dc.b	REG_SCC, SZ_BYTE,$58
	.dc.b	REG_AC,  SZ_WORD,$5C

	.dc.b	REG_PSR, SZ_WORD,$60
	.dc.b	REG_PCSR,SZ_WORD,$64

	.dc.b	REG_TT0, SZ_LONG,$08
	.dc.b	REG_TT1, SZ_LONG,$0C
	.dc.b	0
	.even

;----------------------------------------------------------------
;	pflusha				(68851/68030/68040)
~pflusha::
	move.w	(CPUTYPE,a6),d1
	and.w	#C040|C060,d1
	bne	~pflushan
	addq.l	#asm1skipofst,(sp)	;行末のチェックは行わない
	move.w	#$F000,d0		;68851/68030のpflusha
	bsr	wrt1wobj		;命令コードの出力
	move.w	#$2400,d0
	bra	wrt1wobj		;コプロセッサコマンドワードの出力

;----------------------------------------------------------------
;	pflushan			(68040)
~pflushan::
	OPOUT
	addq.l	#asm1skipofst,(sp)	;行末のチェックは行わない
	rts

;----------------------------------------------------------------
;	pflush	<fc>,#xx/<fc>,#xx,<ea>/(An)	(68851/68030/68040)
~pflush::
	move.w	(CPUTYPE,a6),d1
	and.w	#C040|C060,d1
	bne	~pflushn
	move.w	#$3000,d7		;68851/68030のpflush
	bra	~pflushs

;----------------------------------------------------------------
;	pflushn/plpaw/plpar	(An)	(68040)
~pflushn::
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_ADR,d0
	bne	iladrerr		;(An)でなければエラー
	move.w	(EACODE,a1),d1
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
;	pflushs	<fc>,#xx/<fc>,#xx,<ea>	(68851)
~pflushs::
	bsr	getfc			;fcを得る
	or.w	d1,d7
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	exprerr			;定数が得られなければエラー
	moveq.l	#7,d0			;68030では0～7
	move.w	(CPUTYPE,a6),d1
	and.w	#CMMU,d1
	beq	~pflushs1
	moveq.l	#15,d0			;68881では0～15
~pflushs1:
	move.l	(RPNBUF1,a1),d1
	cmp.l	d0,d1
	bhi	ilvalueerr
	lsl.w	#5,d1
	or.w	d1,d7
	tst.w	(a0)
	bne	~pflushs2
	move.w	#$F000,d0		;<fc>,#xx
	bsr	wrt1wobj		;命令コードの出力
	move.w	d7,d0
	bra	wrt1wobj		;コプロセッサコマンドワードの出力

~pflushs2:
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	CHKLIM
	or.w	#$0800,d6		;<fc>,#xx,<ea>
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_CTRL&EG_ALT,d0	;制御・可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7		;アドレッシングモードをセット
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	bra	eadataout

;----------------------------------------------------------------
;	ploadw/ploadr	<fc>,<ea>	(68851/68030)
~ploadwr::
	bsr	getfc			;fcを得る
	or.w	d1,d7
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_CTRL&EG_ALT,d0	;制御・可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	bra	eadataout

;----------------------------------------------------------------
;	ptestw/ptestr	<fc>,<ea>,#xx/<fc>,<ea>,#xx,An/(An)	(68851/68030/68040)
~ptestwr::
	move.w	(CPUTYPE,a6),d1
	and.w	#C040,d1
	bne	~ptestwr40
	bsr	getfc			;fcを得る 68851/68030のptestw/ptestr
	or.w	d1,d7
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	CHKLIM
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_CTRL&EG_ALT,d0	;制御・可変モード
	beq	iladrerr
	CHKLIM
	movea.l	a5,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	exprerr			;定数が得られなければエラー
	move.l	(RPNBUF1,a1),d1
	cmp.l	#7,d1
	bhi	ilvalueerr		;0～7でなければエラー
	ror.w	#6,d1
	or.w	d1,d6
	tst.w	(a0)
	beq	~ptestwr1		;<fc>,<ea>,#xx
	CHKLIM
	or.w	#$0100,d6		;<fc>,<ea>,#xx,An
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
	lsl.w	#5,d1
	or.w	d1,d6
~ptestwr1:
	movea.l	a4,a1
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	bra	eadataout

~ptestwr40:				;68040のptestw/ptestr
	lsr.w	#4,d7
	and.w	#$0020,d7
	or.w	#$F548,d7		;命令コード
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_ADR,d0
	bne	iladrerr		;(An)でなければエラー
	move.w	(EACODE,a1),d1
	SETREGL
	OPOUTrts

;----------------------------------------------------------------
getfc:
	move.w	(a0)+,d0
	moveq.l	#$0000,d1
	cmp.w	#REG_SFC|OT_REGISTER,d0	;SFC
	beq	getfc9
	moveq.l	#$0001,d1
	cmp.w	#REG_DFC|OT_REGISTER,d0	;DFC
	beq	getfc9
	subq.l	#2,a0
	bsr	getdreg			;データレジスタオペランドを得る
	bmi	getfc5
	or.w	#$0008,d1
	rts

getfc5:
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	cmp.w	#EA_IMM,d0
	bne	iladrerr		;#xxでなければエラー
	tst.w	(RPNLEN1,a1)
	bpl	exprerr			;定数が得られなければエラー
	moveq.l	#7,d0			;68030では0～7
	move.w	(CPUTYPE,a6),d1
	and.w	#CMMU,d1
	beq	getfc6
	moveq.l	#15,d0			;68881では0～15
getfc6:
	move.l	(RPNBUF1,a1),d1
	cmp.l	d0,d1
	bhi	ilvalueerr
	or.w	#$0010,d1
getfc9:
	rts

;----------------------------------------------------------------
;	pflushr	<ea>			(68851)
~pflushr::
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	movea.l	a4,a1
	bsr	geteamode		;実効アドレスオペランドを得る
	and.w	#EG_MEM,d0		;メモリモード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	bra	eadataout

;----------------------------------------------------------------
;	pvalid	VAL,<ea>/An,<ea>	(68851)
~pvalid::
	cmp.w	#REG_VAL|OT_REGISTER,(a0)+
	beq	~pvalid1		;VAL,<ea>
	subq.l	#2,a0
	or.w	#$0400,d7		;An,<ea>
	bsr	getareg			;アドレスレジスタオペランドを得る
	bmi	iladrerr
	SETREGL
~pvalid1:
	CHKLIM
	move.w	d7,d6			;コプロセッサコマンドワード
	move.w	#$F000,d7		;命令コード
	movea.l	a4,a1
	bsr	geteamode_noopc		;実効アドレスオペランドを得る
	and.w	#EG_CTRL&EG_ALT,d0	;制御・可変モード
	beq	iladrerr
	or.w	(EACODE,a1),d7
	DSPOPOUT			;命令コードの出力
	move.w	d6,d0
	bsr	wrt1wobj		;コプロセッサコマンドワードの出力
	bra	eadataout

;----------------------------------------------------------------
;	pb<cc>	<label>			(68851)
~pbcc::
	moveq.l	#0,d0			;MMUのコプロセッサIDは0
	bra	~cpbcc

;----------------------------------------------------------------
;	pdb<cc>	Dn,<label>		(68851)
~pdbcc::
	moveq.l	#0,d0
	bra	~cpdbcc

;----------------------------------------------------------------
;	prestore	<ea>		(68851)
~prestore::
	moveq.l	#0,d0
	bra	~cprestore

;----------------------------------------------------------------
;	psave	<ea>			(68851)
~psave::
	moveq.l	#0,d0
	bra	~cpsave

;----------------------------------------------------------------
;	ps<cc>	<ea>			(68851)
~pscc::
	moveq.l	#0,d0
	bra	~cpscc

;----------------------------------------------------------------
;	ptrap<cc>	#xx		(68851)
~ptrapcc::
	moveq.l	#0,d0
	bra	~cptrapcc


;----------------------------------------------------------------
	.end


;----------------------------------------------------------------
;
;	Revision 5.2  2023-07-07 12:00:00  M.Kamada
;	+91 -c4のときADDA.W/SUBA.W #$8000,Anが間違って変換される不具合
;
;	Revision 5.1  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 5.0  2016-01-01 12:00:00  M.Kamada
;	+88 ワーニング「整数を浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;
;	Revision 4.9  1999 11/17(Wed) 03:19:02 M.Kamada
;	+87 tst (0,a0)+が「オペランドが多すぎます」になる
;
;	Revision 4.8  1999 10/ 8(Fri) 17:12:16 M.Kamada
;	+86 ilsizeerrを細分化
;
;	Revision 4.7  1999  3/19(Fri) 16:02:11 M.Kamada
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;
;	Revision 4.6  1999  2/28(Sun) 17:57:44 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 if成立部のままファイルが終わったとき異常動作する不具合を修正
;
;	Revision 4.5  1999  2/28(Sun) 00:32:44 M.Kamada
;	+82 ColdFireのときCPUSHLがアセンブルできなかった
;
;	Revision 4.4  1999  2/27(Sat) 23:38:09 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 4.3  1999  2/24(Wed) 20:00:29 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 4.2  1999  2/13(Sat) 20:57:17 M.Kamada
;	+79 rtdでinsignificant bitが出る
;
;	Revision 4.1  1998  8/ 2(Sun) 16:26:30 M.Kamada
;	+71 -1のときFMOVE FPn,<label>がエラーになる
;
;	Revision 4.0  1998  7/ 5(Sun) 20:42:58 M.Kamada
;	+67 STOP/LPSTOP #<data> で無意味なビットが立っていたらワーニングを出す
;
;	Revision 3.9  1998  5/24(Sun) 20:03:40 M.Kamada
;	+66 ANDI to SR/CCRで未定義ビットをクリアしようとしたらワーニングを出す
;
;	Revision 3.8  1998  4/13(Mon) 04:32:06 M.Kamada
;	+64 move An,USPの行にラベルがあるとI11対策が行われない
;	+64 エラッタの対策を禁止するスイッチを追加
;
;	Revision 3.7  1998  3/31(Tue) 03:59:26 M.Kamada
;	+61 MOVE/ORI/EORI #<imm>,SR/CCR で無意味なビットが立っていたらワーニングを出す
;	+62 MOVEP.L (d,An),Dnの展開にSWAPを使う
;	+63 jmp/jsrを最適化する
;
;	Revision 3.6  1998  2/ 8(Sun) 00:57:07 M.Kamada
;	+59 jbra/jbsr/jbccにサイズを指定できる
;
;	Revision 3.5  1998  1/10(Sat) 16:01:56 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 3.4  1998  1/ 5(Mon) 01:04:23 M.Kamada
;	+55 -b[n]
;
;	Revision 3.3  1997 10/30(Thu) 02:56:58 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;	+52 -c0でもCMPA.wl #0,Anが最適化される不具合
;
;	Revision 3.2  1997 10/12(Sun) 23:31:56 M.Kamada
;	(+52 jmp/jsrを最適化する)
;
;	Revision 3.1  1997 10/12(Sun) 16:17:17 M.Kamada
;	+51 bra @f;.rept 30;fadd.x fp0,fp0;.endm;@@:のbraが最適化されないバグを修正
;
;	Revision 3.0  1997 10/ 6(Mon) 04:28:25 M.Kamada
;	+50 シフトローテートの#immが範囲外のときillegal quick size errorになる
;
;	Revision 2.9  1997  9/24(Wed) 02:50:10 M.Kamada
;	+48 ASLの最適化は68040でも行う
;
;	Revision 2.8  1997  9/23(Tue) 22:25:35 M.Kamada
;	+47 movepとfsccのエミュレーションを拡充
;
;	Revision 2.7  1997  9/15(Mon) 16:34:22 M.Kamada
;	+46 error.sを分離,T_EOF=0,SZ_BYTE=0で最適化,move#0も最適化
;
;	Revision 2.6  1997  9/17(Wed) 22:31:56 M.Kamada
;	+44 software emulationの命令を展開する
;
;	Revision 2.5  1997  9/ 7(Sun) 18:37:11 M.Kamada
;	+42 ADDI/SUBI #d3,<ea>→ADDQ/SUBQ #d3,<ea>
;
;	Revision 2.4  1997  7/16(Wed) 22:22:43 M.Kamada
;	+40 FMOVEM.L #imm,FPcrがsoftware emulationになるバグを除去
;
;	Revision 2.3  1997  7/ 9(Wed) 02:30:03 M.Kamada
;	+39 -1の挙動を修正
;
;	Revision 2.2  1997  6/25(Wed) 12:29:57 M.Kamada
;	+35 CMP.bwl #0,Dn→TST.bwl Dn
;	+36 MOVE.bw #0,Dn→CLR.bw Dn
;	+38 CMPI.bwl #0,<ea>→TST.bwl <ea>
;
;	Revision 2.1  1997  4/ 5(Sat) 18:44:20 M.Kamada
;	+21 サイズ指定のない定数でない絶対ロングを(d,OPC)にする
;	+22 btst Dn,<ea>が3バイトになるバグを除去
;	+24 MOVEAを最適化する
;	+25 CLRを最適化する
;	+26 ADDA/CMPA/SUBAを最適化する
;	+28 LEAを最適化する
;	+29 ASLを最適化する
;
;	Revision 2.0  1997  2/28(Fri) 13:06:58 M.Kamada
;	+16 ptestr/ptestwは68060不可
;	+17 chk #imm,dnのオペコードが3バイトになるバグを除去
;
;	Revision 1.9  1997  2/ 2(Sun) 14:35:15 M.Kamada
;	+14 fmove.x #0,#0,#0,fp0などで68030でもsoftware emulationが出るバグを除去
;
;	Revision 1.8  1997  2/ 1(Sat) 23:38:16 M.Kamada
;	+12 「divsl #255,d0:d0」のコードが5バイトになるバグを除去
;
;	Revision 1.7  1996 12/26(Thu) 00:30:16 M.Kamada
;	+02 68060対応
;		divs/divu/muls/muluの64bitは68060不可
;		lpstop追加
;		plpaw/plparはpflushnを利用
;		pflusha/pflush/ptestw/ptestrに68060判定を追加
;	+07 F43G対策
;		後からtrapcc/ftrapccのオペランドなしのスタック操作を修正した
;	+08 ソフトウェアエミュレーションの検出
;	+10 OPTIONALPCをワークから実行アドレス解釈バッファへ移動
;		move (d,opc),(d,an)の不具合解消
;
;	Revision 1.6  1994/07/28  13:55:08  nakamura
;	pflusha,pflushan命令にコメントをつけるとエラーになるバグを修正
;	pflush,pflushs命令が異常なコードを出力することのあるバグを修正
;
;	Revision 1.5  1994/07/12  14:24:40  nakamura
;	データサイズコード.qへの対応
;	若干のバグフィックス
;
;	Revision 1.4  1994/06/26  13:05:08  nakamura
;	db<cc>/fdb<cc>がOPTIONALPCをクリアしないバグを修正。
;	cmpi命令の実効アドレスモードチェックが甘かったのを修正。
;
;	Revision 1.3  1994/04/09  14:01:00  nakamura
;	jbra/jbsr/jb<cc>命令で絶対ロング以外のアドレッシングを使用可能にした。
;
;	Revision 1.2  1994/03/06  03:02:24  nakamura
;	新設命令jbra,jbsr,jbccおよびopcの処理追加
;
;	Revision 1.1  1994/02/13  13:35:36  nakamura
;	Initial revision
;
;
