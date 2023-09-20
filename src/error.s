;----------------------------------------------------------------
;	X68k High-speed Assembler
;		エラー・ワーニング処理
;		< error.s >
;
;	$Id: error.s,v 2.4  2016-01-01 12:00:00  M.Kamada Exp $
;
;		Copyright 1990-1994  by Y.Nakamura
;		          1997-2016  by M.Kamada
;----------------------------------------------------------------

	.include	doscall.mac
	.include	has.equ
	.include	tmpcode.equ
	.include	symbol.equ

	.cpu	68000
	.text


;----------------------------------------------------------------
;	エラー・ワーニング処理ルーチン
;----------------------------------------------------------------

;----------------------------------------------------------------
;	ワーニング処理ルーチン
;----------------------------------------------------------------

warntbl	.macro
	warn	1,4,abswarn,		'絶対アドレッシングです'
	warn	1,4,absshwarn,		'絶対ショートアドレッシングです'
	warn	1,3,shortwarn,		'アドレスレジスタを %s.w で更新しています'
	warn	1,3,shortwarn_cmpa,	'アドレスレジスタを %s.w で比較しています'
	warn	1,3,shvalwarn_absw,	'絶対ショートアドレスが -$8000～$7FFF の範囲外です'
	warn	1,3,shvalwarn_d16,	'オフセットが -32768～32767 の範囲外です'
	warn	1,3,shvalwarn_d8,	'オフセットが -128～127 の範囲外です'
	warn	1,1,reglwarn,		'レジスタリストの表記が不正です'
	warn	1,1,alignwarn,		'%s のデータのアラインメントが不正です'
	warn	1,1,alignwarn_op,	'命令が奇数アドレスに配置されました'
	warn	1,1,softwarn,		'%s はソフトウェアエミュレーションで実行されます'
	warn	1,1,f43gwarn,		'浮動小数点命令の直後に NOP を挿入しました (エラッタ対策)'
	warn	1,1,movetouspwarn,	'MOVE to USP の直前に MOVEA.L A0,A0 を挿入しました (エラッタ対策)'
	warn	1,1,insigbitwarn,	'CCR/SR の未定義のビットを操作しています'
	warn	1,1,indexszwarn,	'インデックスのサイズが指定されていません'
	warn	1,1,redefwarn_set,	'シンボル %s を .set(=) で上書きしました'
	warn	1,1,redefwarn_offsym,	'シンボル %s を .offsym で上書きしました'
	warn	1,1,ds_negative_warn,	'%s の引数が負数です'
	warn	1,1,internalfpwarn,	'整数を単精度浮動小数点数の内部表現と見なします'

	.endm

warn	.macro	cnt,lvl,lab,str
lab::
  .if cnt+0
	movem.l	d0-d1,-(sp)
	moveq.l	#n,d0
n = n+(cnt+0)
	moveq.l	#lvl,d1
	bra	warnout
  .endif
	.endm

n = 0
	warntbl

warnout:
	cmp.b	(WARNLEVEL,a6),d1
	bhi	warnout9
warnout1:
	movem.l	d3/a0-a2,-(sp)
	add.w	d0,d0			;ワーニング番号×2
	move.w	(warn_msg_tbl,pc,d0.w),d0
	lea.l	(warn_msg_tbl,pc,d0.w),a2
	move.l	(ERRMESSYM,a6),d3
	moveq.l	#0,d1
	bsr	printerr
	cmpi.b	#3,(ASMPASS,a6)
	bne	warnout2
	tst.b	(MAKEPRN,a6)
	beq	warnout8
warnout2:				;パス1/パス3でPRNファイルを作成する場合は
	move.w	#STDOUT,-(sp)
	move.l	(LINEBUFPTR,a6),-(sp)	;行の内容も表示する
	DOS	_FPUTS
	pea.l	(crlf_msg,pc)
	DOS	_PRINT
	lea.l	(10,sp),sp
warnout8:
	movem.l	(sp)+,d3/a0-a2
warnout9:
	movem.l	(sp)+,d0-d1
warnout99:
	rts

warn	.macro	cnt,lvl,lab,str
  .if cnt+0
	.dc.w	m_&lab-warn_msg_tbl
  .endif
	.endm

warn_msg_tbl:
	warntbl

warn	.macro	cnt,lvl,lab,str
  .if cnt+0
m_&lab:
	mes	str
	.dc.b	0
  .endif
	.endm

	warntbl
	.even


;----------------------------------------------------------------
;	エラー処理ルーチン
;----------------------------------------------------------------

errtbl	.macro
	error	1,forcederr,		'.fail によるエラー'
	error	1,redeferr,		'シンボル %s は既に定義されています'
	error	1,redeferr_predefine,	'プレデファインシンボル %s を再定義しようとしました'
	error	1,redeferr_set,		'シンボル %s は .set(=) 以外で定義されています'
	error	1,redeferr_offsym,	'シンボル %s は .offsym 以外で定義されています'
	error	1,badopeerr,		'命令が解釈できません'
	error	1,badopeerr_local,	'ローカルラベルの記述が不正です'
	error	1,badopeerr_locallen,	'ローカルラベルの桁数が多すぎるため定義できません'
	error	0,ilsymerr_value
	error	0,ilsymerr_local
	error	0,ilsymerr_real
	error	1,ilsymerr_regsym,	'シンボル %s は種類が異なるので使えません'
	error	1,ilsymerr_register,	'シンボル %s はレジスタ名なので使えません'
	error	1,ilsymerr_predefxdef,	'プレデファインシンボル %s は外部定義宣言できません'
	error	1,ilsymerr_predefxref,	'プレデファインシンボル %s は外部参照宣言できません'
	error	1,ilsymerr_predefglobl,	'プレデファインシンボル %s はグローバル宣言できません'
	error	1,ilsymerr_lookfor,	'シンボル %s の定義が参照方法と矛盾しています'
	error	1,exprerr,		'記述が間違っています'
	error	1,exprerr_ea,		'実効アドレスが解釈できません'
	error	1,exprerr_cannotscale,	'スケールファクタは指定できません'
	error	1,exprerr_scalefactor,	'スケールファクタの指定が間違っています'
	error	1,exprerr_fullformat,	'フルフォーマットのアドレッシングは使えません'
	error	1,exprerr_immediate,	'イミディエイトデータが解釈できません'
	error	1,regerr,		'指定できないレジスタです'
	error	1,regerr_opc,		'このアドレッシングでは opc は使えません'
	error	1,iladrerr,		'指定できないアドレッシングです'
	error	0,ilsizeerr_op		;'命令 %s には指定できないサイズです'
	error	0,ilsizeerr_pseudo	;'疑似命令 %s には指定できないサイズです'
	error	0,ilsizeerr_moveusp	;'MOVE USP はロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_cf_acc	;'MOVE ACC はロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_fpn		;'浮動小数点レジスタ直接アドレッシングは拡張サイズのみ指定可能です'
	error	0,ilsizeerr_fprn	;'汎用レジスタ直接アドレッシングはロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_fpcr	;'FPCR/FPIAR/FPSR はロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_fmovemfpn	;'FMOVEM FPn は拡張サイズのみ指定可能です'
	error	0,ilsizeerr_fmovemfpcr	;'FMOVEM FPcr はロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_cf_long	;'5200/5300 ではロングワードサイズのみ指定可能です'
	error	0,ilsizeerr_cf_bccl	;'5200/5300 ではロングワードサイズの相対分岐はできません'
	error	1,ilsizeerr,		'指定できないサイズです'
	error	0,ilsizeerr_pseudo_no
	error	1,ilsizeerr_op_no,	'%s にはサイズを指定できません'
	error	1,ilsizeerr_ccr,	'%s to CCR はバイトサイズのみ指定可能です'
	error	1,ilsizeerr_sr,		'%s to SR はワードサイズのみ指定可能です'
	error	1,ilsizeerr_an,		'アドレスレジスタはバイトサイズでアクセスできません'
	error	1,ilsizeerr_movetosr,	'MOVE to CCR/SR はワードサイズのみ指定可能です'
	error	1,ilsizeerr_movefrsr,	'MOVE from CCR/SR はワードサイズのみ指定可能です'
	error	1,ilsizeerr_000_long,	'68000/68010 ではロングワードサイズは指定できません'
	error	1,ilsizeerr_sftrotmem,	'メモリに対するシフト・ローテートはワードサイズのみ指定可能です'
	error	1,ilsizeerr_bitmem,	'メモリに対するビット操作はバイトサイズのみ指定可能です'
	error	1,ilsizeerr_bitreg,	'データレジスタに対するビット操作はロングワードサイズのみ指定可能です'
	error	1,ilsizeerr_000_bccl,	'68000/68010 ではロングワードサイズの相対分岐はできません'
	error	1,ilsizeerr_trapcc,	'オペランドのない TRAPcc にはサイズを指定できません'
	error	1,iloprerr,		'不正なオペランドです'
	error	1,iloprerr_not_fixed,	'引数が確定していません'
	error	1,iloprerr_too_many,	'%s のオペランドが多すぎます'
	error	1,iloprerr_pseudo_many,	'%s の引数が多すぎます'
	error	1,iloprerr_local,	'ローカルラベルの参照が不正です'
	error	1,iloprerr_locallen,	'ローカルラベルの桁数が多すぎるため参照できません'
	error	1,iloprerr_ds_negative,	'%s の引数が負数です'
	error	1,iloprerr_end_xref,	'.end に外部参照値は指定できません'
	error	1,iloprerr_internalfp,	'浮動小数点数の内部表現の長さが合いません'
	error	1,undefsymerr,		'シンボル %s が未定義です'
	error	1,undefsymerr_local,	'ローカルラベルが未定義です'
	error	1,undefsymerr_offsym,	'値を確定できません'
	error	1,divzeroerr,		'0 で除算しました'
	error	1,ilrelerr_outside,	'オフセットが範囲外です'
	error	1,ilrelerr_const,	'定数ではなくアドレス値が必要です'
	error	1,overflowerr,		'オーバーフローしました'
	error	1,ilvalueerr,		'不正な値です'
	error	1,ilquickerr_addsubq,	'データが 1～8 の範囲外です'
	error	1,ilquickerr_moveq,	'データが -128～127 の範囲外です'
	error	1,ilquickerr_mov3q,	'データが -1,1～7 の範囲外です'
	error	0,ilquickerr_sftrot
	error	1,ilsfterr,		'シフト・ローテートのカウントが 1～8 の範囲外です'
	error	1,featureerr_cpu,	'未対応の cpu です'
	error	1,featureerr_xref,	'外部参照値の埋め込みはできません'
	error	1,nosymerr_macro,	'マクロ名がありません'
	error	1,nosymerr_pseudo,	'%s で定義するシンボルがありません'
	error	1,tooinclderr,		'.include のネストが深すぎます'
	error	1,nofileerr,		'%s するファイルが見つかりません'
	error	1,mismacerr_exitm,	'マクロ展開中ではないのに %s があります'
	error	0,mismacerr_endm
	error	0,mismacerr_local
	error	1,mismacerr_sizem,	'マクロ定義中ではないのに %s があります'
	error	1,mismacerr_eof,	'.endm が足りません'
	error	1,toomanylocsymerr,	'1 つのマクロの中のローカルシンボルが多すぎます'
	error	1,macnesterr,		'マクロのネストが深すぎます'
	error	0,misiferr_else
	error	0,misiferr_elseif
	error	1,misiferr_endif,	'%s に対応する .if がありません'
	error	1,misiferr_else_elseif,	'.else の後に .elseif があります'
	error	1,misiferr_eof,		'.endif が足りません'
	error	1,termerr_doublequote,	'"～"が閉じていません'
	error	1,termerr_singlequote,	"'～'が閉じていません"
	error	1,termerr_bracket,	'<～>が閉じていません'
	error	1,ilinterr,		'整数の記述が間違っています'
	error	1,offsymalignerr,	'.offsym 中に %s は指定できません'
	.endm

error	.macro	cnt,lab,str
lab::
  .if cnt+0
	moveq.l	#n,d0
n = n+(cnt+0)
	bra	errout
  .endif
	.endm

n = 0
	errtbl

errout::
	move.l	(ERRMESSYM,a6),d3
errout_d3::
	cmpi.b	#3,(ASMPASS,a6)
	beq	errout9			;パス3以外ではエラーメッセージを出力しない
	or.w	#T_ERROR,d0		;T_ERROR|エラー番号
	bsrl	wrtobjd0w,d2		;ファイルにエラーコードを出力
	move.w	(ERRMESSYM+0,a6),d0
	bsrl	wrtobjd0w,d2		;エラーメッセージに埋め込むシンボル
	move.w	(ERRMESSYM+2,a6),d0
	bsrl	wrtobjd0w,d2
	bra	errout91		;パス3ではテンポラリコードを出力する必要はない

errout9:
	add.w	d0,d0			;エラー番号×2
	move.w	(err_msg_tbl,pc,d0.w),d0
	lea.l	(err_msg_tbl,pc,d0.w),a2
	moveq.l	#1,d1
	bsr	printerr
errout91:
	addq.w	#1,(NUMOFERR,a6)
	movea.l	(SPSAVE,a6),sp
	move.l	(ERRRET,a6),-(sp)
	rts				;エラー処理から復帰

error	.macro	cnt,lab,str
  .if cnt+0
	.dc.w	m_&lab-err_msg_tbl
  .endif
	.endm

err_msg_tbl:
	errtbl

error	.macro	cnt,lab,str
  .if cnt+0
m_&lab:
	.dc.b	str,0
  .endif
	.endm

	errtbl
	.even

;----------------------------------------------------------------
;	エラー・ワーニングメッセージを出力する
;<d1.w:0='Warning',1='Error'
;<d3.l:(ERRMESSYM,a6),%sがあるメッセージではd3=0は不可
;<a2.l:メッセージ文字列へのポインタ
printerr:
	link	a5,#-128
	movem.l	d0/d3/a0-a1,-(sp)
	lea.l	(-128,a5),a0
	movea.l	(INPFILE,a6),a1		;ファイル名へのポインタ
	moveq.l	#16,d0
printerr1:
	subq.w	#1,d0
	move.b	(a1)+,(a0)+		;ファイル名を転送
	bne	printerr1
	subq.l	#1,a0
	tst.w	d0
	bmi	printerr3
printerr2:
	move.b	#' ',(a0)+		;余りをスペースで埋める
	dbra	d0,printerr2
printerr3:
	move.b	#' ',(a0)+
	move.w	d1,-(sp)
	move.l	(LINENUM,a6),d0
	moveq.l	#5,d1			;(5桁でゼロサプレス)
	cmp.l	#100000,d0
	bcs	printerr4
	moveq.l	#0,d1			;6桁以上になるなら左詰め
printerr4:
	move.l	d2,-(sp)
	bsrl	convdec,d2		;行番号
	move.l	(sp)+,d2
	move.w	(sp)+,d1
	lea.l	(warn_msg,pc),a1
	tst.w	d1
	beq	printerr5
	lea.l	(error_msg,pc),a1
printerr5:
	bsr	strcpy
	movea.l	a2,a1
	bra	printerr51

printerr50:
	move.b	d0,(a0)+
printerr51:
	move.b	(a1)+,d0
	beq	printerr53
	cmp.b	#'%',d0
	bne	printerr50
	cmpi.b	#'s',(a1)
	bne	printerr50
	addq.l	#1,a1
	exg.l	d3,a1
	cmpi.b	#ST_OPCODE,(SYM_TYPE,a1)
	bne	printerr52		;命令でない
	tst.w	(SYM_ARCH,a1)
	bne	printerr52		;疑似命令でない
	move.b	#'.',(a0)+		;疑似命令の先頭に'.'を付ける
printerr52:
	movea.l	(SYM_NAME,a1),a1
	bsr	strcpy
	movea.l	d3,a1
	bra	printerr51

printerr53:
  .if UNIX_NEWLINE=0
	move.b	#CR,(a0)+
  .endif
	move.b	#LF,(a0)+
	clr.b	(a0)
printerr6:
	lea.l	(-128,a5),a0
	bsrl	prnstdout,d0		;標準出力・PRNファイルにエラーメッセージを表示
	movem.l	(sp)+,d0/d3/a0-a1
	unlk	a5
	rts

strcpy:
	move.b	(a1)+,(a0)+
	bne	strcpy
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;	エラー・ワーニングメッセージ
warn_msg:	.dc.b	': Warning: ',0
error_msg:	.dc.b	': Error: ',0

crlf_msg::	.dc.b	CRLF,0
	.even


;----------------------------------------------------------------
	.end

;----------------------------------------------------------------
;	$Log: error.s,v $
;	Revision 2.4  2016-01-01 12:00:00  M.Kamada
;	+88 ワーニング「整数を単精度浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;
;	Revision 2.3  1999 10/ 8(Fri) 21:04:21 M.Kamada
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;	+86 '%s に外部参照値は指定できません'
;	+86 foo fequ fooのエラーメッセージがおかしい
;
;	Revision 2.2  1999  6/ 9(Wed) 23:37:52 M.Kamada
;	+85 .offsymでシンボル指定があるとき.even/.quad/.alignをエラーにする
;	+85 .dsの引数が負数のとき.text/.dataセクションではエラー,その他はワーニング
;
;	Revision 2.1  1999  4/24(Sat) 03:14:35 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;
;	Revision 2.0  1999  3/16(Tue) 03:46:21 M.Kamada
;	+83 エラーメッセージ中の疑似命令の先頭に'.'を付ける
;	+83 「ローカルラベルの参照が不正です」を追加
;
;	Revision 1.9  1999  3/ 6(Sat) 21:50:58 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 疑似命令のパラメータが多すぎる場合のエラーチェックを強化
;	+82 error.sの構造を変更
;
;	Revision 1.8  1999  2/27(Sat) 23:39:49 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.7  1998  3/30(Mon) 21:37:41 M.Kamada
;	+61 warning: insignificant bitを追加
;
;	Revision 1.6  1998  1/10(Sat) 15:44:52 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 1.5  1997 10/29(Wed) 21:51:23 M.Kamada
;	+52 記述された整数が64bitを超えたらエラー
;	+52 misc.sの相対呼び出しをロングに
;	+52 strcpyを内蔵
;
;	Revision 1.4  1997  9/14(Sun) 16:25:55 M.Kamada
;	+46 error.sを分離
;
;	Revision 1.3  1997  3/20(Thu) 15:52:18 M.Kamada
;	+23 terminator not foundをエラーに
;
;	Revision 1.2  1996 12/15(Sun) 14:13:22 M.Kamada
;	+02 68060対応
;		ソフトウェアエミュレーションのワーニングを追加
;	+07 F43G対策
;		F43G対策のワーニングを追加
;
;	Revision 1.1  1994/02/13  14:10:18  nakamura
;	Initial revision
;
;
