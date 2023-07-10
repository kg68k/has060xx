;----------------------------------------------------------------
;	X68k High-speed Assembler
;		アドレッシングモードの解釈
;		< eamode.s >
;
;	$Id: eamode.s,v 2.8  2016-01-01 12:00:00  M.Kamada Exp $
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2016  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ
	.include	cputype.equ
	.include	eamode.equ
	.include	register.equ
	.include	tmpcode.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	レジスタオペランドの解釈
;----------------------------------------------------------------

;----------------------------------------------------------------
;	オペランドのデータレジスタを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタ番号
;		             得られなければ-1
getdreg::
	move.w	(a0)+,d1
	cmpi.w	#OT_REGISTER|REG_D0,d1
	bcs	getdreg9
	cmpi.w	#OT_REGISTER|REG_D7,d1
	bhi	getdreg9
	andi.w	#$0007,d1
	moveq.l	#0,d0
	rts

getdreg9:
	subq.l	#2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのアドレスレジスタを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタ番号
;		             得られなければ-1
getareg::
	move.w	(a0)+,d1
	cmpi.w	#OT_REGISTER|REG_A0,d1
	bcs	getareg9
	cmpi.w	#OT_REGISTER|REG_A7,d1
	bhi	getareg9
	andi.w	#$0007,d1
	moveq.l	#0,d0
	rts

getareg9:
	subq.l	#2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのデータ・アドレスレジスタを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタ番号
;		             得られなければ-1
getreg::
	move.w	(a0)+,d1
	cmpi.w	#OT_REGISTER|REG_D0,d1
	bcs	getreg9
	cmpi.w	#OT_REGISTER|REG_A7,d1
	bhi	getreg9
	andi.w	#$000F,d1
	moveq.l	#0,d0
	rts

getreg9:
	subq.l	#2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのデータレジスタ・ペアを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w:d2.w=レジスタ番号
;		             得られなければ-1
getdregp::
	move.l	a0,-(sp)
	bsr	getdreg			;データレジスタを得る
	bmi	getdregp9
	move.w	d1,d2
	cmpi.w	#':'|OT_CHAR,(a0)+
	bne	getdregp9
	bsr	getdreg			;データレジスタを得る
	bmi	getdregp9
	exg.l	d1,d2
	addq.l	#4,sp
	moveq.l	#0,d0
	rts

getdregp9:
	movea.l	(sp)+,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのレジスタ間接・ペアを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w:d2.w=レジスタ番号
;		             得られなければ-1
getregpp::
	move.l	a0,-(sp)
	cmpi.w	#'('|OT_CHAR,(a0)+
	bne	getregpp9
	bsr	getreg			;レジスタを得る
	bmi	getregpp9
	move.w	d1,d2
	cmpi.w	#')'|OT_CHAR,(a0)+
	bne	getregpp9
	cmpi.w	#':'|OT_CHAR,(a0)+
	bne	getregpp9
	cmpi.w	#'('|OT_CHAR,(a0)+
	bne	getregpp9
	bsr	getreg			;レジスタを得る
	bmi	getregpp9
	cmpi.w	#')'|OT_CHAR,(a0)+
	bne	getregpp9
	exg.l	d1,d2
	addq.l	#4,sp
	moveq.l	#0,d0
	rts

getregpp9:
	movea.l	(sp)+,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのレジスタリストを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタリスト
;		             得られなければ-1
getreglist::
	movea.l	a0,a2
	moveq.l	#0,d3			;レジスタリスト
	moveq.l	#-1,d4			;指定中のレジスタの最大番号
	moveq.l	#0,d5			;ワーニングを出力するかのフラグ
getreglist1:
	bsr	getreg
	bmi	getreglist99
	bset.l	d1,d3
	cmp.b	d4,d1
	bgt	getreglist2
	st.b	d5			;二重指定/逆順指定
	bra	getreglist3

getreglist2:
	move.b	d1,d4

getreglist3:
	move.w	(a0)+,d0
	cmp.w	#'/'|OT_CHAR,d0
	beq	getreglist1
	cmp.w	#'-'|OT_CHAR,d0
	bne	getreglist9

	move.b	d1,d2
	bsr	getreg
	bmi	getreglist99
	move.b	d1,d0
	eor.b	d2,d0
	andi.b	#$08,d0
	sne.b	d0			;Dn,Anの混在
	or.b	d0,d5
	cmp.b	d2,d1
	bhi	getreglist4
	exg.l	d1,d2
	bset.l	d2,d3
	st.b	d5			;逆順指定
	bra	getreglist5

getreglist4:
	addq.b	#1,d2
	bset.l	d2,d3
	sne.b	d0			;二重指定
	or.b	d0,d5
getreglist5:
	cmp.b	d2,d1
	bhi	getreglist4

	cmp.b	d4,d1
	bgt	getreglist6
	st.b	d5			;二重指定/逆順指定
	bra	getreglist7

getreglist6:
	move.b	d1,d4

getreglist7:
	move.w	(a0)+,d0
	cmp.w	#'/'|OT_CHAR,d0
	beq	getreglist1

getreglist9
	subq.l	#2,a0
	move.w	d3,d1
	tst.b	d5
	beq	getreglist91
	bsr	reglwarn		;レジスタリスト指定のワーニング
getreglist91
	moveq.l	#0,d0
	rts

getreglist99:
	movea.l	a2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドの制御レジスタを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=制御レジスタ番号
;		             得られなければ-1
getcreg::
	move.w	(a0)+,d1
	lea.l	(getctbl,pc),a1
getcreg1:
	move.w	(a1)+,d0
	beq	getcreg9		;制御レジスタが得られなかった
	cmp.b	d0,d1
	beq	getcreg2
	addq.l	#4,a1
	bra	getcreg1

getcreg2:
	move.w	(a1)+,d0
	and.w	(CPUTYPE,a6),d0
	beq	getcreg9
getcreg3:
	move.w	(a1)+,d1
	moveq.l	#0,d0
	rts

getcreg9:
	subq.l	#2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	制御レジスタコードテーブル
cregtbl	.macro	num,code,mpu
	.dc.w	$FF00+num,mpu,code
	.endm

getctbl:
;ColdFireに標準で実装されている制御レジスタはVBRのみ
	cregtbl	REG_SFC,	$0000,	C010|C020|C030|C040|C060
	cregtbl	REG_DFC,	$0001,	C010|C020|C030|C040|C060
	cregtbl	REG_CACR,	$0002,	     C020|C030|C040|C060|C520|C530|C540
	cregtbl	REG_USP,	$0800,	C010|C020|C030|C040|C060
	cregtbl	REG_VBR,	$0801,	C010|C020|C030|C040|C060|C520|C530|C540
	cregtbl	REG_CAAR,	$0802,	     C020|C030
	cregtbl	REG_MSP,	$0803,	     C020|C030|C040
	cregtbl	REG_ISP,	$0804,	     C020|C030|C040
	cregtbl	REG_TC,		$0003,		       C040|C060|C520|C530|C540
	cregtbl	REG_ITT0,	$0004,		       C040|C060|C520|C530|C540
	cregtbl	REG_ITT1,	$0005,		       C040|C060|C520|C530|C540
	cregtbl	REG_DTT0,	$0006,		       C040|C060|C520|C530|C540
	cregtbl	REG_DTT1,	$0007,		       C040|C060|C520|C530|C540
	cregtbl	REG_MMUSR,	$0805,		       C040
	cregtbl	REG_URP,	$0806,		       C040|C060
	cregtbl	REG_SRP,	$0807,		       C040|C060
	cregtbl	REG_BUSCR,	$0008,			    C060
	cregtbl	REG_PCR,	$0808,			    C060
	cregtbl	REG_PC,		$080F,				 C520|C530|C540
	cregtbl	REG_ROMBAR,	$0C00,				 C520|C530|C540
	cregtbl	REG_RAMBAR0,	$0C04,				 C520|C530|C540
	cregtbl	REG_RAMBAR1,	$0C05,				 C520|C530|C540
	cregtbl	REG_MBAR,	$0C0F,				 C520|C530|C540
	.dc.w	0

;----------------------------------------------------------------
;	オペランドのビットフィールド指定を得る
;	in :a0=コード化されたオペランドを指すポインタ
;	    a1=アドレッシングモード解釈バッファへのポインタ
;	out:a0=オペランドの終了位置を指す
;	    d0.w=得られた特殊オペランドデータ
getbitfield::
	movem.l	d1/d7/a2,-(sp)
	moveq.l	#0,d7
	clr.w	(RPNLEN1,a1)
	clr.w	(RPNLEN2,a1)
	cmp.w	#'{'|OT_CHAR,(a0)+	;オフセット
	bne	iladrerr
	bsr	getdreg			;データレジスタを得る
	bmi	getbitfield1
	lsl.w	#6,d1
	or.w	d1,d7
	or.w	#$0800,d7
	bra	getbitfield5

getbitfield1:
	lea.l	(RPNBUF1,a1),a2
	bsr	getbfvalue
	bmi	getbitfield5
	cmp.l	#31,d1
	bhi	ilvalueerr		;オフセット値は0～31
	lsl.w	#6,d1
	or.w	d1,d7
	clr.w	(RPNLEN1,a1)
getbitfield5:				;幅
	cmp.w	#':'|OT_CHAR,(a0)+
	bne	iladrerr
	bsr	getdreg			;データレジスタを得る
	bmi	getbitfield6
	or.w	d1,d7
	or.w	#$0020,d7
	bra	getbitfield9

getbitfield6:
	lea.l	(RPNBUF2,a1),a2
	bsr	getbfvalue
	bmi	getbitfield9
	tst.l	d1
	beq	ilvalueerr		;幅は1～32
	cmp.l	#32,d1
	bhi	ilvalueerr
	and.w	#31,d1
	or.w	d1,d7
	clr.w	(RPNLEN2,a1)
getbitfield9:
	cmp.w	#'}'|OT_CHAR,(a0)+
	bne	iladrerr
	move.w	d7,d0
	movem.l	(sp)+,d1/d7/a2
	rts

getbfvalue:				;ビットフィールドの値を得る
	cmp.w	#'#'|OT_CHAR,(a0)
	bne	getbfvalue1
	addq.l	#2,a0			;#nでもnでも可
getbfvalue1:
	bsr	geteaexpr
	tst.w	d0
	bmi	iladrerr
	tst.b	(RPNSIZE1-RPNBUF1,a2)
	bpl	ilsizeerr		;サイズ指定があればエラー
	tst.w	(RPNLEN1-RPNBUF1,a2)
	bpl	getbfvalue9		;式の値が得られなかった
	move.l	(a2),d1
	moveq.l	#0,d0
	rts

getbfvalue9:
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドの浮動小数点データレジスタを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタ番号
;		             得られなければ-1
getfpreg::
	move.w	(a0)+,d1
	cmpi.w	#OT_REGISTER|REG_FP0,d1
	bcs	getfpreg9
	cmpi.w	#OT_REGISTER|REG_FP7,d1
	bhi	getfpreg9
	andi.w	#$0007,d1
	moveq.l	#0,d0
	rts

getfpreg9:
	subq.l	#2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドの浮動小数点データレジスタリストを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタリスト
;		             得られなければ-1
getfpreglist::
	movea.l	a0,a2
	moveq.l	#0,d3			;レジスタリスト
	moveq.l	#-1,d4			;指定中のレジスタの最大番号
	moveq.l	#0,d5			;ワーニングを出力するかのフラグ
getfpreglist1:
	bsr	getfpreg
	bmi	getfpreglist99
	moveq.l	#7,d0
	sub.w	d1,d0			;(ビット順が逆なので)
	bset.l	d0,d3
	cmp.b	d4,d1
	bgt	getfpreglist2
	st.b	d5			;二重指定/逆順指定
	bra	getfpreglist3

getfpreglist2:
	move.b	d1,d4

getfpreglist3:
	move.w	(a0)+,d0
	cmp.w	#'/'|OT_CHAR,d0
	beq	getfpreglist1
	cmp.w	#'-'|OT_CHAR,d0
	bne	getfpreglist9

	move.b	d1,d2
	bsr	getfpreg
	bmi	getfpreglist99
	cmp.b	d2,d1
	bhi	getfpreglist4
	exg.l	d1,d2
	moveq.l	#7,d0
	sub.w	d2,d0			;(ビット順が逆なので)
	bset.l	d0,d3
	st.b	d5			;逆順指定
	bra	getfpreglist5

getfpreglist4:
	addq.b	#1,d2
	moveq.l	#7,d0
	sub.w	d2,d0			;(ビット順が逆なので)
	bset.l	d0,d3
	sne.b	d0			;二重指定
	or.b	d0,d5
getfpreglist5:
	cmp.b	d2,d1
	bhi	getfpreglist4

	cmp.b	d4,d1
	bgt	getfpreglist6
	st.b	d5			;二重指定/逆順指定
	bra	getfpreglist7

getfpreglist6:
	move.b	d1,d4

getfpreglist7:
	move.w	(a0)+,d0
	cmp.w	#'/'|OT_CHAR,d0
	beq	getfpreglist1

getfpreglist9
	subq.l	#2,a0
	move.w	d3,d1
	tst.b	d5
	beq	getfpreglist91
	bsr	reglwarn		;レジスタリスト指定のワーニング
getfpreglist91
	moveq.l	#0,d0
	rts

getfpreglist99:
	movea.l	a2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドの浮動小数点システム制御レジスタリストを得る
;	in :a0=コード化されたオペランドを指すポインタ
;	out:d0.w=オペランドが得られれば0 / d1.w=レジスタリスト / d2.w=レジスタ数-1
;		             得られなければ-1
getfpcreglist::
	movea.l	a0,a2
	moveq.l	#-1,d2			;指定されたレジスタ数
	moveq.l	#0,d3			;レジスタリスト
	moveq.l	#-1,d4			;指定中のレジスタの最大番号
	moveq.l	#0,d5			;ワーニングを出力するかのフラグ
getfpcreglist1:
	move.w	(a0)+,d1
	sub.w	#REG_FPCR|OT_REGISTER,d1
	bcs	getfpcreglist99
	cmp.w	#REG_FPIAR-REG_FPCR,d1
	bhi	getfpcreglist99		;オペランドがFPCR/FPSR/FPIARでない
	moveq.l	#2,d0
	sub.w	d1,d0			;(ビット順が逆なので)
	bset.l	d0,d3
	bne	getfpcreglist15
	addq.w	#1,d2
getfpcreglist15:
	cmp.b	d4,d1
	bgt	getfpcreglist2
	st.b	d5			;二重指定/逆順指定
	bra	getfpcreglist3

getfpcreglist2:
	move.b	d1,d4
getfpcreglist3:
	move.w	(a0)+,d0
	cmp.w	#'/'|OT_CHAR,d0
	beq	getfpcreglist1
getfpcreglist9
	subq.l	#2,a0
	move.w	d3,d1
	ror.w	#6,d1
	tst.b	d5
	beq	getfpcreglist91
	bsr	reglwarn		;レジスタリスト指定のワーニング
getfpcreglist91
	moveq.l	#0,d0
	rts

getfpcreglist99:
	movea.l	a2,a0
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;	オペランドのkファクタ指定を得る
;	in :a0=コード化されたオペランドを指すポインタ
;	    d6.w=コプロセッサ命令ワード
;	out:a0=オペランドの終了位置を指す
;	    d6.w=コプロセッサ命令ワード
getkfactor::
	cmp.w	#'{'|OT_CHAR,(a0)+
	bne	iladrerr
	bsr	getdreg			;データレジスタを得る
	bmi	getkfactor1
	lsl.w	#4,d1			;動的kファクタ {Dn}
	or.w	d1,d6
	or.w	#$1C00,d6
	bra	getkfactor9

getkfactor1:				;静的kファクタ {#n}
	cmp.w	#'#'|OT_CHAR,(a0)+
	bne	iladrerr
	lea.l	(RPNBUFEX,a6),a2
	bsr	geteaexpr
	tst.w	d0
	bmi	iladrerr
	tst.b	(RPNSIZEEX,a6)
	bpl	ilsizeerr		;サイズ指定があればエラー
	tst.w	(RPNLENEX,a6)
	bpl	iloprerr		;式の値が得られなかった
	move.l	(a2),d1
	cmp.l	#-64,d1			;kファクタは-64～63
	blt	ilvalueerr
	cmp.l	#63,d1
	bgt	ilvalueerr
	and.w	#$007F,d1
	or.w	d1,d6
getkfactor9:
	cmp.w	#'}'|OT_CHAR,(a0)+
	bne	iladrerr
	rts


;----------------------------------------------------------------
;	オペランドのアドレッシングモード解釈
;----------------------------------------------------------------

;----------------------------------------------------------------
;	式を逆ポーランド記法に変換し、バッファに格納する
;ここはgeteamodeとgetfpeamodeの両方で使う
;getfpeamodeでは内部表現最初の式を得るためにも使用するので、
;整数にすべきでないときはエラーを返すこと
;.qの処理
;	命令にSZQがあるときはエラーにせず無視する
;	命令にSZS|SZD|SZX|SZPがすべてあってサイズが.b/.w/lでないときは、
;	エラーにせず失敗して終了する(-1を返す)
geteaexpr::				;外部定義
	exg.l	a1,a2
	move.l	a0,-(sp)		;convrpnの前のa0を保存しておく
	bsr	convrpn			;式を変換する
	tst.w	d0
	bmi	geteaexpr5		;変換できなかった
	move.b	(EXPRSIZE,a6),d0		;式のサイズ指定
	cmpi.b	#OT_SIZE>>8,(a0)
	bne	geteaexpr1
	move.w	(a0)+,d0		;式の後にサイズ指定があればそれを優先
geteaexpr1:
	cmpi.b	#SZ_SHORT,d0
	blt	geteaexpr3		;.b/.w/.lならば素通り
geteaexpr2:
	move.l	a3,-(sp)
	tst.l	(CMDTBLPTR,a6)
	beq	ilsizeerr		;命令がないとき.b/.w/.l以外はエラー
	movea.l	(CMDTBLPTR,a6),a3
	cmpi.b	#SZ_QUAD,d0
	bne	geteaexpr6
	tst.b	(SYM_SIZE,a3)		;使えないサイズのビットが1
	bpl	geteaexpr4		;SZQがあるので.qを無視する
geteaexpr6:
	moveq.l	#SZS|SZD|SZX|SZP,d0
	and.b	(SYM_SIZE,a3),d0	;使えないサイズのビットが1
	bne	ilsizeerr		;浮動小数点命令ではないので.b/.w/.l以外はエラー
	move.l	(sp)+,a3
geteaexpr5:
	movea.l	(sp)+,a0		;a0を復元する
	moveq.l	#-1,d0			;整数としての処理を中止
	bra	geteaexpr9

geteaexpr4:
	movea.l	(sp)+,a3
geteaexpr3:
	addq.l	#4,sp			;convrpnの前のa0を捨てる
	move.w	d1,(RPNLEN1-RPNBUF1,a1)	;式の長さ
	move.b	d0,(RPNSIZE1-RPNBUF1,a1)	;サイズ指定を得る
	bsr	calcrpn			;変換した式を計算する
	tst.w	d0
	bne	geteaexpr8
	move.l	d1,(a1)			;式が定数の場合
	moveq.l	#-1,d1
	move.w	d1,(RPNLEN1-RPNBUF1,a1)	;式の長さ(定数)
geteaexpr8:
	moveq.l	#0,d0
geteaexpr9:
	exg.l	a1,a2
	rts

;----------------------------------------------------------------
;	コード化されたオペランドからアドレッシングモードを解釈する
;	in :a0=コード化されたオペランドを指すポインタ
;	    a1=アドレッシングモード解釈バッファへのポインタ
;	out:a0=オペランドの終了位置を指す
;	    d0.w=得られたアドレッシングモードビット
geteamode_noopc::
	st.b	(ABSLTOOPCCAN,a6)
geteamode::
	clr.w	(RPNLEN1,a1)
	clr.w	(RPNLEN2,a1)
	move.w	(a0),d0
	cmp.w	#'#'|OT_CHAR,d0
	beq	getea_imm		;#xxxx
	move.w	d0,d1
	and.w	#$FF00,d1
	cmp.w	#OT_REGISTER,d1
	beq	getea_reg		;レジスタ名
geteamode0:
	cmp.w	#'('|OT_CHAR,d0
	beq	geteamode_par		;(…
	cmp.w	#'-'|OT_CHAR,d0
	bne	geteanum

	cmp.w	#'('|OT_CHAR,(2,a0)
	bne	geteanum
	move.w	(4,a0),d1
	and.w	#$FF00,d1
	cmp.w	#OT_REGISTER,d1
	beq	getea_decadr		;-(Rn…

geteanum:
	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr
	tst.w	d0
	bmi	geteanum_par
	cmpi.w	#'('|OT_CHAR,(a0)
	bne	getea_abslw		;xxxx
	addq.l	#2,a0			;xxxx(…
	bra	geteapar

geteanum_par:
	cmp.w	#'('|OT_CHAR,(a0)+
	beq	geteapar		;(xxxx… ?
	bra	exprerr_ea		;該当するアドレッシングが存在しない

geteamode_par:
	move.w	(2,a0),d1
	and.w	#$FF00,d1
	cmp.w	#OT_REGISTER,d1
	bne	geteanum
	addq.l	#2,a0			;(Rn…
;	bra	geteapar

;----------------------------------------------------------------
;	'('で始まるアドレッシングの解釈
;	d2.w=上位:ベースレジスタ未指定:0/サプレス:1/指定済み:-1
;	     下位:ベースレジスタ番号(0～7)/PC間接なら-1
;	d3.w=上位:インデックスレジスタ番号,サイズ,スケール値
;	     下位:インデックスレジスタ未指定:0/サプレス:1/指定済み:-1
;	d4.w=上位:ポストインデックスなら-1/プリインデックスなら0
;	     下位:間接アドレッシング未使用:0/使用:1/指定中:-1
geteapar:
	moveq.l	#0,d2			;ベースレジスタ未指定
	moveq.l	#0,d3			;インデックスレジスタ未指定
	moveq.l	#0,d4			;間接アドレッシングなし
geteapar1:
	move.w	(a0),d0			;アドレッシングの要素を得る
	move.w	d0,d1
	and.w	#$FF00,d1
	cmp.w	#OT_REGISTER,d1
	beq	geteapar_reg		;レジスタ
	cmp.w	#'['|OT_CHAR,d0
	beq	geteapar_ind		;'['(間接アドレッシング指定開始)
					;式?
	tst.b	d4
	bmi	geteapar_bdexpr		;間接指定中ならベースディスプレースメント
	bne	geteapar_odexpr		;間接指定後ならアウタディスプレースメント
	tst.w	(RPNLEN1,a1)
	bne	geteapar_bd2expr	;ベースディスプレースメント指定済み

	lea.l	(RPNBUF1,a1),a2		;ベースorアウタディスプレースメント
	bsr	geteaexpr
	tst.w	d0
	bne	exprerr_ea
	move.w	(a0)+,d0
	cmp.w	#'['|OT_CHAR,d0
	bne	geteapar_next1
	bra	geteapar_ind3		;xxxx[… (ベースディスプレースメント確定)

geteapar_bdexpr:			;ベースディスプレースメントを得る
	tst.w	(RPNLEN1,a1)
	bne	exprerr_ea		;すでにディスプレースメント指定がある
	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr
	tst.w	d0
	bne	exprerr_ea
	bra	geteapar_next

geteapar_odexpr:			;アウタディスプレースメントを得る
	tst.w	(RPNLEN2,a1)
	bne	exprerr_ea		;すでにディスプレースメント指定がある
	lea.l	(RPNBUF2,a1),a2
	bsr	geteaexpr
	tst.w	d0
	bne	exprerr_ea
	bra	geteapar_next

geteapar_bd2expr:			;ベースディスプレースメントを得る
	tst.w	(RPNLEN2,a1)		;(式の指定は括弧の外)
	bne	exprerr_ea		;すでにディスプレースメント指定がある
	move.b	(RPNSIZE1,a1),(RPNSIZE2,a1)
	move.w	(RPNLEN1,a1),d0
	clr.w	(RPNLEN1,a1)		;ベースディスプレースメントを
	move.w	d0,(RPNLEN2,a1)		;	アウタディスプレースメントに変更する
	bpl	geteapar_bd2expr1
	move.l	(RPNBUF1,a1),(RPNBUF2,a1)
	bra	geteapar_bd2expr3

geteapar_bd2expr1:
	move.l	a1,-(sp)
	lea.l	(RPNBUF1,a1),a2
	lea.l	(RPNBUF2,a1),a1
geteapar_bd2expr2:
	move.w	(a2)+,(a1)+
	dbra	d0,geteapar_bd2expr2
	movea.l	(sp)+,a1
geteapar_bd2expr3:
	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr
	tst.w	d0
	bne	exprerr_ea
	cmp.w	#'['|OT_CHAR,(a0)+
	bne	exprerr_ea		;間接アドレッシングが始まらなければエラー
	bra	geteapar_ind3

geteapar_ind:				;間接アドレッシング開始('[')
	addq.l	#2,a0

	move.w	(RPNLEN1,a1),d0
	beq	geteapar_ind3		;ベースディスプレースメントは指定されていない
	move.b	(RPNSIZE1,a1),(RPNSIZE2,a1)
	clr.w	(RPNLEN1,a1)		;ベースディスプレースメントを
	move.w	d0,(RPNLEN2,a1)		;	アウタディスプレースメントに変更する
	bpl	geteapar_ind1
	move.l	(RPNBUF1,a1),(RPNBUF2,a1)
	bra	geteapar_ind3

geteapar_ind1:
	move.l	a1,-(sp)
	lea.l	(RPNBUF1,a1),a2
	lea.l	(RPNBUF2,a1),a1
geteapar_ind2:
	move.w	(a2)+,(a1)+
	dbra	d0,geteapar_ind2
	movea.l	(sp)+,a1

geteapar_ind3:
	tst.b	d4
	bne	exprerr_ea		;'['が二度指定された
	moveq.l	#-1,d4			;ポストインデックス付き間接アドレッシング
	tst.w	d2
	beq	geteapar1		;ベースレジスタはまだ指定されていない
	tst.b	d2
	bmi	exprerr_ea		;PCベースレジスタが指定済み(pc/zpc)
	tst.b	d3
	bne	exprerr_ea		;ベースレジスタ/インデックスレジスタとも指定済み
	addq.b	#8,d2			;ベースレジスタをインデックスレジスタに変更する
	rol.b	#4,d2
	rol.w	#8,d2
	move.w	d2,d3
	bsr	indexszwarn		;インデックスサイズ指定がない
	moveq.l	#0,d2			;ベースレジスタは未指定
	bra	geteapar1

geteapar_reg:
	addq.l	#2,a0
	cmp.w	#REG_D7|OT_REGISTER,d0
	bls	geteapar_idxreg		;D0～D7ならインデックスレジスタ
	cmp.w	#REG_A7|OT_REGISTER,d0
	bhi	geteapar_pcreg
	tst.w	d2
	bne	geteapar_idxreg		;ベースレジスタは指定済み
	tst.b	d4			;(bne & bpl)
	bgt	geteapar_idxreg		;間接アドレッシング指定の外
	move.w	(a0),d1			;A0～A7
	cmp.w	#'*'|OT_CHAR,d1		;An.?やAn*はインデックス
	beq	geteapar_idxreg		;An(インデックス)
	cmp.w	#OT_SIZE,d1
	bcc	geteapar_idxreg
	sub.w	#REG_A0|OT_REGISTER,d0
	moveq.l	#-1,d2
	move.b	d0,d2
	bra	geteapar_next

geteapar_pcreg:
	cmp.w	#REG_ZA7|OT_REGISTER,d0
	bls	geteapar_zreg		;レジスタサプレス(ZD0～ZD7,ZA0～ZA7)
	tst.b	d4			;(bne & bpl)
	bgt	exprerr_ea		;間接アドレッシング指定の外
	tst.w	d2
	beq	geteapar_pcreg1		;ベースレジスタはまだ指定されていない
	tst.b	d2
	bmi	exprerr_ea		;PCベースレジスタが指定済み(PC/ZPC)
	tst.b	d3
	bne	exprerr_ea		;ベースレジスタ/インデックスレジスタとも指定済み
	addq.b	#8,d2			;ベースレジスタをインデックスレジスタに変更する
	rol.b	#4,d2
	rol.w	#8,d2
	move.w	d2,d3
	bsr	indexszwarn		;インデックスサイズ指定がない
geteapar_pcreg1:
	st.b	(OPTIONALPC,a1)
	moveq.l	#-1,d2			;PC間接指定
	cmp.w	#REG_OPC|OT_REGISTER,d0
	beq	geteapar_next
	sf.b	(OPTIONALPC,a1)
	cmp.w	#REG_PC|OT_REGISTER,d0
	beq	geteapar_next
	move.w	#$01FF,d2		;PC間接ベースレジスタサプレス(ZPC)
	cmp.w	#REG_ZPC|OT_REGISTER,d0
	beq	geteapar_next
	bra	regerr			;PC,ZPCでなければエラー

geteapar_zreg:
	cmp.w	#REG_ZD7|OT_REGISTER,d0
	bls	geteapar_zidxreg	;ZD0～ZD7ならインデックスレジスタ
	tst.w	d2
	bne	geteapar_zidxreg	;ベースレジスタは指定済み
	tst.b	d4			;(bne & bpl)
	bgt	geteapar_zidxreg	;間接アドレッシング指定の外
	move.w	(a0),d1			;A0～A7
	cmp.w	#'*'|OT_CHAR,d1		;An.?やAn*はインデックス
	beq	geteapar_zidxreg	;An(インデックス)
	cmp.w	#OT_SIZE,d1
	bcc	geteapar_zidxreg
	sub.w	#REG_ZA0|OT_REGISTER-$0100,d0
	move.w	d0,d2
	bra	geteapar_next

geteapar_zidxreg:
	tst.b	d3
	bne	exprerr_ea		;インデックスレジスタは指定済み
	and.w	#$000F,d0
	ror.w	#4,d0
	move.w	d0,d3			;インデックスレジスタ
	move.b	#$01,d3
	bra	geteapar_idxreg0

geteapar_idxreg:
	tst.b	d3
	bne	exprerr_ea		;インデックスレジスタは指定済み
	and.w	#$000F,d0
	ror.w	#4,d0
	move.w	d0,d3			;インデックスレジスタ
	st.b	d3
geteapar_idxreg0:
	tst.b	d4
	bpl	geteapar_idxreg1
	move.w	#$00FF,d4		;間接アドレッシング中ならプリインデックス
geteapar_idxreg1:
	move.w	(a0)+,d0
	cmp.w	#SZ_WORD|OT_SIZE,d0	;Rn.w
	beq	geteapar_idxreg3
	cmp.w	#SZ_LONG|OT_SIZE,d0	;Rn.l
	beq	geteapar_idxreg2
	bsr	indexszwarn		;インデックスサイズ指定がない
	bra	geteapar_idxreg4	;ワードサイズで確定

geteapar_idxreg2:
	ori.w	#EXW_IDXL,d3		;インデックスサイズ
geteapar_idxreg3:
	move.w	(a0)+,d0
geteapar_idxreg4:
	cmpi.w	#'*'|OT_CHAR,d0		;Rn.?*
	bne	geteapar_next1		;スケール値はなし
	bra68	d1,exprerr_cannotscale	;68000にはスケール値はない
	lea.l	(RPNBUFEX,a6),a2	;Rn.?*n
	bsr	geteaexpr		;スケール値を得る
	tst.w	d0
	bne	exprerr_scalefactor	;得られなければエラー
	tst.b	(RPNSIZEEX,a6)
	bpl	ilsizeerr		;サイズ指定があればエラー
	tst.w	(RPNLENEX,a6)
	bpl	exprerr_scalefactor	;定数でなければエラー
	move.l	(RPNBUFEX,a6),d0
	moveq.l	#8,d1
	cmp.l	d1,d0
	bhi	exprerr_scalefactor	;1～8でなければエラー
	tst.b	(CPUTYPE2,a6)
	beq	geteapar_idxreg41
	moveq.l	#4,d1
	cmp.l	d1,d0
	bhi	exprerr_scalefactor	;ColdFireは1～4でなければエラー
geteapar_idxreg41:
	add.w	d0,d0
	move.w	(geteaindex_tbl,pc,d0.w),d0
	bmi	exprerr_scalefactor
	or.w	d0,d3			;スケールファクタ

geteapar_next:
	move.w	(a0)+,d0
geteapar_next1:
	cmp.w	#','|OT_CHAR,d0
	beq	geteapar1
	cmp.w	#')'|OT_CHAR,d0
	beq	geteapm			;アドレッシング指定終了
	cmp.w	#']'|OT_CHAR,d0
	bne	exprerr_ea
	neg.b	d4			;間接アドレッシング指定終了
	bgt	geteapar_next
	bra	exprerr_ea		;間接アドレッシング中ではなかった

geteaindex_tbl:				;スケールファクタ値テーブル
	.dc.w	-1,EXW_SCALE1,EXW_SCALE2,-1,EXW_SCALE4,-1,-1,-1,EXW_SCALE8

;----------------------------------------------------------------
;	得られたアドレッシングの要素からモードを得る
geteapm:
	move.b	(RPNSIZE1,a1),(OPTSIZESET,a6)	;サイズが指定されたかどうかを保存する
	tst.b	d4
	bmi	exprerr_ea		;間接アドレッシング指定中だった
	bne	geteapm_idx		;間接アドレッシング使用
	tst.b	d3
	bne	geteapm_idx		;インデックスレジスタ使用
	tst.w	d2
	bpl	geteapm_idx		;ベースレジスタサプレス
	tst.b	d2
	bmi	geteapm1		;PC間接( (PC)/(PC)+がないため )
	move.w	(RPNLEN1,a1),d0		;ベースディスプレースメントがなければ
	beq	getea_adr		; アドレスレジスタ間接形式 (An)/(An)+
	bpl	geteapm2
	tst.l	(RPNBUF1,a1)
	bne	geteapm2		;ディスプレースメントが0でない
	move.b	(RPNSIZE1,a1),d1
	bpl	geteapm3		;サイズ指定がある
	tst.b	(NONULDISP,a6)
	beq	getea_adr1		;(0,An) → (An)
	bra	geteapm9		;変換を行わない

geteapm1:
	move.w	(RPNLEN1,a1),d0
	beq	geteapm_idx		;ベースディスプレースメントがない (PC)
geteapm2:
	move.b	(RPNSIZE1,a1),d1
	bmi	geteapm5
geteapm3:
	cmpi.b	#SZ_WORD,d1
	beq	geteapm9		;ディスプレースメント付き (d,An)/(d,PC)
	cmpi.b	#SZ_LONG,d1
	beq	geteapm_idx
	bra	ilsizeerr		;サイズなし,.w,.lのいずれでもなければエラー

geteapm5:				;サイズ指定が省略された場合
	tst.w	d0
	bpl	geteapm99		;式の値が得られない場合
	sf.b	(OPTIONALPC,a1)		;定数の場合はOPCは無効
	bra68	d1,geteapm8		;68000/68010は常に.w(確定)
	tst.b	(CPUTYPE2,a6)
	bne	geteapm8		;ColdFireは常に.w(確定)
	move.l	(RPNBUF1,a1),d0
	move.w	d0,d1
	ext.l	d1
	cmp.l	d0,d1
	bne	geteapm_idx		;ワードディスプレースメントの範囲外
geteapm8:
	move.b	#SZ_WORD,(RPNSIZE1,a1)
geteapm9:
	tst.b	d2
	bpl	getea_dspadr		;ディスプレースメント付きアドレスレジスタ間接
	bra	getea_dsppc		;ディスプレースメント付きPC間接

geteapm99:				;ディスプレースメントサイズが未確定の場合
	tst.b	d2
	bmi	geteapm99pc
;	bra68	d1,getea_dspadrw	;68000/68010なら常に.w
;					;(サプレスされる場合があるので確定しない)
	st.b	(DSPADRCODE,a6)		;(実効アドレス変更のため命令コードを保存させる)
	tst.b	(EXTSIZEFLG,a6)
	beq	getea_dspadr		;デフォルトサイズは.w
	move.w	#EAC_BDADR,d0		;(後に最適化でEAC_DSPADRに変更される場合がある)
	bra	getea_dspadr0

geteapm99pc:				;PC間接の場合
	move.b	(LONGABS,a6),d1
	or.b	d1,(OPTIONALPC,a1)
	bne	geteapm99pc1		;(d,PC)→xxxx.lの変換を行う場合
	tst.b	(PCTOABSL,a6)
	bne	geteapm99pc2
	bra68	d1,getea_dsppcw		;68000/68010なら常に.w
	tst.b	(CPUTYPE2,a6)
	bne	getea_dsppcw		;ColdFireなら常に.w
	st.b	(DSPADRCODE,a6)		;(実効アドレス変更のため命令コードを保存させる)
	tst.b	(EXTSIZEFLG,a6)
	beq	getea_dsppc		;デフォルトサイズは.w
	move.w	#EAC_BDPC,(EACODE,a1)	;(後に最適化でEAC_DSPPCに変更される場合がある)
	bra	getea_dsppc0

geteapm99pc1:
;(d,pc)でサイズ指定なしで式の値が得られないとき
	tst.b	(PCTOABSL,a6)
	beq	geteapm99pc4
geteapm99pc2:
	tst.b	(PCTOABSLCAN,a6)
	bne	geteapm99pc3
;絶対ロングで確定する
	sf.b	(OPTIONALPC,a1)
	move.b	#EAD_ABSLW,(EADTYPE,a1)
	move.b	#SZ_LONG,(OPTSIZESET,a1)
	bra	getea_absl

geteapm99pc3:
	st.b	(OPTIONALPC,a1)
geteapm99pc4:
	st.b	(DSPADRCODE,a6)		;(実効アドレス変更のため命令コードを保存させる)
	tst.b	(EXTSHORT,a6)		;(68000/68010でも有効)
	beq	getea_dsppc		;デフォルトサイズは.w
	move.w	#EAC_ABSL,(EACODE,a1)	;(後に最適化でEAC_DSPPCに変更される場合がある)
	bra	getea_dsppc0

geteapm_idx:
	tst.b	d3			;インデックスレジスタ
	bmi	geteapm_idx1
	clr.b	d3			;インデックスレジスタサプレス(フルフォーマット)
	ori.w	#(EXW_IS.xor.$FF)|EXW_FULL,d3
	ext.w	d4			;(インデックス位置ビットは0にする)
geteapm_idx1:
	not.b	d3
	tst.w	d2
	bmi	geteapm_idx2
	ori.w	#EXW_BS|EXW_FULL,d3	;ベースレジスタサプレス(フルフォーマット)
geteapm_idx2:
	tst.b	d4
	bne	geteapm_od		;間接アドレッシング
	btst.l	#EXWB_FORMAT,d3
	bne	geteapm_bd		;フルフォーマットの場合
	move.w	(RPNLEN1,a1),d0
	beq	geteapm_idx3		;ベースディスプレースメントがない
	move.b	(RPNSIZE1,a1),d1
	bmi	geteapm_idx5
	cmpi.b	#SZ_WORD,d1		;.w/.lが指定されたらフルフォーマット
	beq	geteapm_bd
	cmpi.b	#SZ_LONG,d1
	beq	geteapm_bd
	bra	geteapm_idx8		;インデックス付き (d,An,Rn)/(d,PC,Rn)

geteapm_idx3:
	move.w	#-1,(RPNLEN1,a1)	;(An,Rn) → (0.s,An,Rn) / (PC,Rn) → (0.s,PC,Rn)
	clr.l	(RPNBUF1,a1)
	bra	geteapm_idx8

geteapm_idx5:				;サイズ指定が省略された場合
	bra68	d1,geteapm_idx8		;68000/68010なら常に.s
	tst.b	(CPUTYPE2,a6)
	bne	geteapm_idx8		;ColdFireなら常に.s
	tst.w	d0
	bpl	geteapm_idx9		;式の値が得られない場合
	move.l	(RPNBUF1,a1),d0
	move.b	d0,d1
	ext.w	d1
	ext.l	d1
	cmp.l	d0,d1
	bne	geteapm_bd		;8bitディスプレースメントの範囲外
geteapm_idx8:
	move.b	#SZ_SHORT,(RPNSIZE1,a1)
geteapm_idx9:
	tst.b	d2
	bpl	getea_idxadr		;インデックス付きアドレスレジスタ間接
	bra	getea_idxpc		;インデックス付きPC間接

geteapm_bd:
	bra68	d0,exprerr_fullformat	;68000/68010にはフルフォーマットはない
	tst.b	(CPUTYPE2,a6)
	bne	exprerr_fullformat	;ColdFireにはフルフォーマットはない
	ori.w	#EXW_FULL,d3		;フルフォーマット
	move.w	(RPNLEN1,a1),d0
	beq	geteapm_bdnul		;ベースディスプレースメントがない
	move.b	(RPNSIZE1,a1),d1
	bmi	geteapm_bd5
	cmpi.b	#SZ_WORD,d1
	beq	geteapm_bdw
	cmpi.b	#SZ_LONG,d1
	beq	geteapm_bdl
	bra	ilsizeerr		;サイズなし,.w,.lのいずれでもなければエラー

geteapm_bd5:				;サイズ指定が省略された場合
	tst.w	d0
	bpl	geteapm_bd99		;式の値が得られない場合
	move.l	(RPNBUF1,a1),d0
	bne	geteapm_bd6
	clr.w	(RPNLEN1,a1)		;ベースディスプレースメント値が0
geteapm_bdnul:
	or.w	#EXW_BDNUL,d3
	bra	geteapm_bd8

geteapm_bd6:
	move.w	d0,d1
	ext.l	d1
	cmp.l	d0,d1
	bne	geteapm_bd7
	move.b	#SZ_WORD,(RPNSIZE1,a1)
geteapm_bdw:
	or.w	#EXW_BDW,d3
	bra	geteapm_bd8

geteapm_bd7:				;ワードディスプレースメントの範囲外
	move.b	#SZ_LONG,(RPNSIZE1,a1)
geteapm_bdl:
	or.w	#EXW_BDL,d3
geteapm_bd8:
	tst.b	d4
	bne	geteapm_bd9		;間接アドレッシング
	tst.b	d2
	bpl	getea_bdadr		;ベースディスプレースメント付きアドレスレジスタ間接
	bra	getea_bdpc		;ベースディスプレースメント付きPC間接

geteapm_bd9:
	tst.b	d2
	bpl	getea_memadr		;ポスト/プリインデックス付きメモリ間接
	bra	getea_mempc		;ポスト/プリインデックス付きPCメモリ間接

geteapm_bd99:				;ディスプレースメントサイズが未確定の場合
	tst.b	(EXTSIZEFLG,a6)
	beq	geteapm_bdw		;デフォルトサイズは.w
	bra	geteapm_bdl		;デフォルトサイズは.l

geteapm_od:
	bra68	d0,exprerr_fullformat	;68000/68010にはフルフォーマットはない
	tst.b	(CPUTYPE2,a6)
	bne	exprerr_fullformat	;ColdFireにはフルフォーマットはない
	tst.w	d4
	bpl	geteapm_od1		;プリインデックス or インデックスレジスタサプレス
	ori.w	#EXW_POSTIDX,d3		;ポストインデックス
geteapm_od1:
	move.w	(RPNLEN2,a1),d0
	beq	geteapm_odnul		;アウタディスプレースメントがない
	move.b	(RPNSIZE2,a1),d1
	bmi	geteapm_od5
	cmpi.b	#SZ_WORD,d1
	beq	geteapm_odw
	cmpi.b	#SZ_LONG,d1
	beq	geteapm_odl
	bra	ilsizeerr		;サイズなし,.w,.lのいずれでもなければエラー

geteapm_od5:
	tst.w	d0
	bpl	geteapm_od99		;式の値が得られない場合
	move.l	(RPNBUF2,a1),d0
	bne	geteapm_od6
	clr.w	(RPNLEN2,a1)		;アウタディスプレースメント値が0
geteapm_odnul:
	or.w	#EXW_ODNUL,d3
	bra	geteapm_bd

geteapm_od6:
	move.w	d0,d1
	ext.l	d1
	cmp.l	d0,d1
	bne	geteapm_od7
	move.b	#SZ_WORD,(RPNSIZE2,a1)
geteapm_odw:
	or.w	#EXW_ODW,d3
	bra	geteapm_bd

geteapm_od7:				;ワードディスプレースメントの範囲外
	move.b	#SZ_LONG,(RPNSIZE2,a1)
geteapm_odl:
	or.w	#EXW_ODL,d3
	bra	geteapm_bd		;ベースディスプレースメントの処理へ

geteapm_od99:				;ディスプレースメントサイズが未確定の場合
	tst.b	(EXTSIZEFLG,a6)
	beq	geteapm_odw		;デフォルトサイズは.w
	bra	geteapm_odl		;デフォルトサイズは.l

;----------------------------------------------------------------
;	Dn/An		データ/アドレスレジスタ直接形式
getea_reg:
	addq.l	#2,a0
	ext.w	d0
	cmp.w	#REG_A7,d0
	bhi	regerr			;D0～D7,A0～A7でなければエラー
	move.w	d0,(EACODE,a1)
	move.b	#EAD_NONEREG,(EADTYPE,a1)	;データは不要
	cmp.w	#REG_A0,d0
	bcc	getea_reg1
	move.w	#EA_DN,d0		;データレジスタ直接
	rts

getea_reg1:
	tst.b	(CMDOPSIZE,a6)		;cmpi.b #SZ_BYTE,(CMDOPSIZE,a6)
	beq	ilsizeerr		;オペレーションサイズが.bならエラー
	move.w	#EA_AN,d0		;アドレスレジスタ直接
	rts

;----------------------------------------------------------------
;	(An)		アドレスレジスタ間接形式
getea_adr:
	cmp.w	#'+'|OT_CHAR,(a0)	;'+'か?
	beq	getea_incadr		;ポストインクリメント形式
getea_adr1:
	move.w	#EAC_ADR,d0
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.b	#EAD_NONE,(EADTYPE,a1)	;データは不要
	move.w	#EA_ADR,d0
	rts

;----------------------------------------------------------------
;	(An)+		ポストインクリメント・アドレスレジスタ間接形式
getea_incadr:
	addq.l	#2,a0
	move.w	#EAC_INCADR,d0
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.b	#EAD_NONE,(EADTYPE,a1)	;データは不要
	move.w	#EA_INCADR,d0
	rts

;----------------------------------------------------------------
;	-(An)		プリデクリメント・アドレスレジスタ間接形式
getea_decadr:
	addq.l	#4,a0
	move.w	(a0)+,d0
	cmp.w	#REG_A0|OT_REGISTER,d0	;A0～A7か?
	bcs	regerr
	cmp.w	#REG_A7|OT_REGISTER,d0
	bhi	regerr
	cmp.w	#')'|OT_CHAR,(a0)+	;')'か?
	bne	exprerr_ea
	sub.w	#REG_A0|OT_REGISTER,d0
	or.w	#EAC_DECADR,d0
	move.w	d0,(EACODE,a1)
	move.b	#EAD_NONE,(EADTYPE,a1)	;データは不要
	move.w	#EA_DECADR,d0
	rts

;----------------------------------------------------------------
;	(d,An)		ディスプレースメント付きアドレスレジスタ間接形式
getea_dspadrw:
	move.b	#SZ_WORD,(RPNSIZE1,a1)
getea_dspadr:
	move.w	#EAC_DSPADR,d0		;(後に最適化でEAC_BDADRに変更される場合がある)
getea_dspadr0:
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.b	#EAD_DSPADR,(EADTYPE,a1)
	move.w	#EA_DSPADR,d0
	rts

;----------------------------------------------------------------
;	(d,An,Rn)	インデックス付きアドレスレジスタ間接形式
getea_idxadr:
	move.w	#EAC_IDXADR,d0
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_IDXADR,(EADTYPE,a1)
	move.w	#EA_IDXADR,d0
	rts

;----------------------------------------------------------------
;	(bd,An,Rn)	ベースディスプレースメント付きアドレスレジスタ間接形式
getea_bdadr:
	move.w	#EAC_BDADR,d0
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_BDADR,(EADTYPE,a1)
	move.w	#EA_BDADR,d0
	rts

;----------------------------------------------------------------
;	([bd,An,Rn],od)	ポスト/プリインデックス付きメモリ間接
getea_memadr:
	move.w	#EAC_MEMADR,d0
	or.b	d2,d0			;(ベースレジスタ)
	move.w	d0,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_MEMADR,(EADTYPE,a1)
	move.w	#EA_MEMADR,d0
	rts

;----------------------------------------------------------------
;	xxxx		絶対ショート/ロングアドレス形式
getea_abslw:
	move.b	#EAD_ABSLW,(EADTYPE,a1)
	move.b	(RPNSIZE1,a1),d1
	move.b	d1,(OPTSIZESET,a6)	;サイズが指定されたかどうかを保存する
	bmi	getea_abslw1
	cmp.b	#SZ_LONG,d1		;.l
	beq	getea_absl
	cmp.b	#SZ_WORD,d1		;.w
	beq	getea_absw
	bra	ilsizeerr		;サイズ指定がおかしい

getea_abslw1:
	tst.b	(NOABSSHORT,a6)		;サイズ指定がない
	bne	getea_absl
	tst.w	(RPNLEN1,a1)		;絶対ショート対応モードの場合
	bpl	getea_absl1		;定数でない
	move.l	(RPNBUF1,a1),d1
	move.w	d1,d2
	ext.l	d2
	cmp.l	d2,d1
	bne	getea_absl		;絶対ショートの範囲外
getea_absw:				;絶対ショート
	move.b	#SZ_WORD,(RPNSIZE1,a1)
	move.w	#EAC_ABSW,(EACODE,a1)
	move.w	#EA_ABSW,d0
	rts

getea_absl1:				;絶対ロング/サイズ未定
	tst.b	(ABSLTOOPC,a6)
	bne	getea_absltoopc
getea_absl:				;絶対ロング/サイズ未定
	move.b	#SZ_LONG,(RPNSIZE1,a1)
	move.w	#EAC_ABSL,(EACODE,a1)
	move.w	#EA_ABSL,d0
	rts

getea_absltoopc:
	tst.b	(ABSLTOOPCCAN,a6)
	bne	getea_absl
	st.b	(OPTIONALPC,a1)
	moveq.l	#-1,d2			;PC間接指定
	bra	geteapm99pc1

;----------------------------------------------------------------
;	(d,PC)		ディスプレースメント付きPC間接形式
getea_dsppcw:
	move.b	#SZ_WORD,(RPNSIZE1,a1)
getea_dsppc:
	move.w	#EAC_DSPPC,(EACODE,a1)	;(後に最適化でEAC_BDPCに変更される場合がある)
getea_dsppc0:
	move.b	#EAD_DSPPC,(EADTYPE,a1)
	move.w	#EA_DSPPC,d0
	rts

;----------------------------------------------------------------
;	(d,PC,Rn)	インデックス付きPC間接形式
getea_idxpc:
	tst.b	(OPTIONALPC,a1)
	bne	regerr_opc		;(d,PC)以外のOPCはエラー
	move.w	#EAC_IDXPC,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_IDXPC,(EADTYPE,a1)
	move.w	#EA_IDXPC,d0
	rts

;----------------------------------------------------------------
;	(bd,PC,Rn)	ベースディスプレースメント付きPC間接形式
getea_bdpc:
	tst.b	(OPTIONALPC,a1)
	bne	regerr_opc		;(d,PC)以外のOPCはエラー
	move.w	#EAC_BDPC,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_BDPC,(EADTYPE,a1)
	move.w	#EA_BDPC,d0
	rts

;----------------------------------------------------------------
;	([bd,PC,Rn],od)	ポスト/プリインデックス付きPCメモリ間接
getea_mempc:
	tst.b	(OPTIONALPC,a1)
	bne	regerr_opc		;(d,PC)以外のOPCはエラー
	move.w	#EAC_MEMPC,(EACODE,a1)
	move.w	d3,(EXTCODE,a1)
	move.b	#EAD_MEMPC,(EADTYPE,a1)
	move.w	#EA_MEMPC,d0
	rts

;----------------------------------------------------------------
;	#xxxx		イミディエイト形式
getea_imm:
	addq.l	#2,a0
	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr
	tst.w	d0
	bmi	exprerr_immediate	;式変換に失敗
	cmpi.b	#SZ_SHORT,(RPNSIZE1,a1)
	beq	ilsizeerr		;.sはエラー
	move.w	#EAC_IMM,(EACODE,a1)
	move.b	#EAD_IMM,(EADTYPE,a1)
	move.w	#EA_IMM,d0
	rts

;----------------------------------------------------------------
;	浮動小数点実数アドレッシングモードを解釈する
;	in :a0=コード化されたオペランドを指すポインタ
;	    a1=アドレッシングモード解釈バッファへのポインタ
;	out:a0=オペランドの終了位置を指す
;	    d0.w=得られたアドレッシングモードビット
getfpeamode_noopc::
	st.b	(ABSLTOOPCCAN,a6)
getfpeamode::
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)	;.lだけ別扱い(fmove/fmovem対策)
	bcs	geteamode		;サイズが整数ならgeteamodeと同じ
	clr.w	(RPNLEN1,a1)
	clr.w	(RPNLEN2,a1)
	move.w	(a0),d0
	cmp.w	#'#'|OT_CHAR,d0
	beq	getfpea_imm
	move.w	d0,d1
	and.w	#$FF00,d1
	cmp.w	#OT_REGISTER,d1
	bne	geteamode0		;ほかのアドレス形式はgeteamodeと同じ

;----------------------------------------------------------------
;	Dn/An		データ/アドレスレジスタ直接形式
getfpea_reg:
	cmpi.b	#SZ_SHORT,(CMDOPSIZE,a6)
	ble	getea_reg		;サイズが.b/.w/.l/.s/省略ならgeteamodeと同じ
	bra	ilsizeerr		;.d/.x/.pはエラー

;----------------------------------------------------------------
;	#xxxx		イミディエイト形式
getfpea_imm::
	addq.l	#2,a0
	clr.w	(RPNLENEX,a6)

	lea.l	(RPNBUF1,a1),a2
	bsr	geteaexpr		;内部表現最初の式を得る
	tst.w	d0
	bmi	getfpea_immfp		;式変換に失敗→浮動小数点実数表記
	cmpi.b	#SZ_SINGLE,(CMDOPSIZE,a6)
	bne	getfpea_imm01
	bsr	internalfpwarn		;整数を単精度浮動小数点数の内部表現と見なします
getfpea_imm01:
	movea.l	a0,a3
	moveq.l	#1-1,d3
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	getfpea_imm9
	cmpi.w	#'#'|OT_CHAR,(a0)
	bne	getfpea_imm1
	addq.l	#2,a0
getfpea_imm1:				;#xxxx,#xxxx / #xxxx,xxxx
	lea.l	(RPNBUF2,a1),a2
	bsr	geteaexpr		;2つ目の式を得る
	tst.w	d0
	bmi	getfpea_imm9		;式変換に失敗
	movea.l	a0,a3
	moveq.l	#2-1,d3
	cmpi.w	#','|OT_CHAR,(a0)+
	bne	getfpea_imm9
	cmpi.w	#'#'|OT_CHAR,(a0)
	bne	getfpea_imm2
	addq.l	#2,a0
getfpea_imm2:				;#xxxx,#xxxx,#xxxx / #xxxx,xxxx,xxxx
	lea.l	(RPNBUFEX,a6),a2
	bsr	geteaexpr		;3つ目の式を得る
	tst.w	d0
	bmi	getfpea_imm9		;式変換に失敗
	movea.l	a0,a3
	moveq.l	#3-1,d3
getfpea_imm9:
	movea.l	a3,a0
	move.b	d3,(EAIMMCNT,a1)
	move.w	#EAC_IMM,(EACODE,a1)
	move.b	#EAD_IMM,(EADTYPE,a1)
	move.w	#EA_IMM,d0
	rts

getfpea_immfp:				;浮動小数点実数表記を得る
	cmpi.b	#SZ_LONG,(CMDOPSIZE,a6)
	bls	exprerr			;.b/.w/.lならエラー
	bsr	calcfexpr		;浮動小数点式を得る
	move.l	d0,(RPNBUF1,a1)
	move.l	d1,(RPNBUF2,a1)
	move.l	d2,(RPNBUFEX,a6)
	moveq.l	#-1,d0
	move.w	d0,(RPNLEN1,a1)
	move.w	d0,(RPNLEN2,a1)
	move.w	d0,(RPNLENEX,a6)
	move.b	d0,(EAIMMCNT,a1)
	move.w	#EAC_IMM,(EACODE,a1)
	move.b	#EAD_IMM,(EADTYPE,a1)
	move.w	#EA_IMM,d0
	rts


;----------------------------------------------------------------
	.end


;----------------------------------------------------------------
;	$Log: eamode.s,v $
;	Revision 2.8  2016-01-01 12:00:00  M.Kamada
;	+88 ワーニング「整数を単精度浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;
;	Revision 2.7  1999  3/ 1(Mon) 03:00:50 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 geteapar_idxreg2の直前にあった条件が不確定なbneをbraに変更
;
;	Revision 2.6  1999  2/28(Sun) 03:53:19 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.5  1999  2/20(Sat) 20:12:59 M.Kamada
;	+80 ColdFire対応
;
;	Revision 2.4  1998  8/ 2(Sun) 16:28:24 M.Kamada
;	+71 -1のときFMOVE FPn,<label>がエラーになる
;
;	Revision 2.3  1998  3/31(Tue) 03:13:34 M.Kamada
;	+63 jmp/jsrを最適化する
;
;	Revision 2.2  1998  1/ 5(Mon) 00:50:31 M.Kamada
;	+55 -b[n]
;
;	Revision 2.1  1997 10/29(Wed) 19:44:21 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;	+52 浮動小数点数のサイズ指定を可能にする
;
;	Revision 2.0  1997  9/15(Mon) 16:35:21 M.Kamada
;	+46 SZ_BYTE=0で最適化
;
;	Revision 1.9  1997  7/20(Sun) 01:56:08 M.Kamada
;	+41 スケールファクタの処理のバグを修正
;
;	Revision 1.8  1997  7/ 9(Wed) 02:30:26 M.Kamada
;	+39 -1の挙動を修正
;
;	Revision 1.7  1997  4/ 5(Sat) 18:42:57 M.Kamada
;	+28 LEAを最適化する
;
;	Revision 1.6  1997  3/14(Fri) 22:58:28 M.Kamada
;	+18 サイズ指定のない定数でない絶対ロングを(d,OPC)にする
;	+19 -1の挙動を修正
;	+20 -1の挙動を修正
;
;	Revision 1.5  1996 11/13(Wed) 15:25:30 M.Kamada
;	+02 68060対応
;		制御レジスタのテーブルを変更しBUSCR,PCRを追加
;
;	Revision 1.4  1994/07/11  14:23:52  nakamura
;	若干のバグフィックス
;
;	Revision 1.3  1994/04/12  15:10:38  nakamura
;	-m68000/68010で(d,An)が最適化されないことがあるバグを修正。
;
;	Revision 1.2  1994/03/06  03:09:22  nakamura
;	zd0～zd7,za0～za7,opcレジスタの処理を追加
;
;	Revision 1.1  1994/02/13  11:44:56  nakamura
;	Initial revision
;
;
