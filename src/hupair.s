;----------------------------------------------------------------
;	HAS060X.X
;		HUPAIRデコード
;		< hupair.s >
;
;		Copyright 2023  by TcbnErik
;----------------------------------------------------------------

	.cpu	68000
	.text


;----------------------------------------------------------------
;	HUPAIRデコード
;	in :a0=文字列へのポインタ
;	out:a0=デコードした引数列へのポインタ
;	    a1=デコードした引数列の終了位置
dechupair::
	movem.l	d0-d1/a5,-(sp)
	movea.l	(TEMPPTR,a6),a5

	moveq	#' ',d0
@@:	cmp.b	(a0)+,d0
	beq	@b
	subq.l	#1,a0
	bsr	strlen
	addq.l	#1,d1			;デコードに必要な最大バッファサイズ
	add.l	a5,d1
	move.l	d1,(TEMPPTR,a6)
	bsr	memcheck

	lea	(a5),a1
dechuplp1:
	tst.b	(a0)
	beq	dechupend		;引数なし
dechuplp2:
	move.b	(a0)+,d0
	move.b	d0,(a1)+
	beq	dechupend
	cmpi.b	#' ',d0
	beq	dechupspc
	cmpi.b	#'"',d0
	beq	@f
	cmpi.b	#"'",d0
	bne	dechuplp2
@@:
	subq.l	#1,a1			;書き込んだ開始クオート文字を取り消す
	move.b	d0,d1
dechuplp3:
	move.b	(a0)+,d0
	move.b	d0,(a1)+
	beq	dechupend		;クオート中にNUL文字
	cmp.b	d0,d1
	bne	dechuplp3		;通常文字、"～"中の'、'～'中の"
	subq.l	#1,a1			;書き込んだ終了クオート文字を取り消す
	bra	dechuplp2		;クオート終了
dechupspc:
	clr.b	(-1,a1)			;スペースなら引数区切り
@@:	cmp.b	(a0)+,d0		;d0.b=' ' 連続するスペースを飛ばす
	beq	@b
	subq.l	#1,a0
	bra	dechuplp1
dechupend:
	move.l	a1,(TEMPPTR,a6)		;引数列の終了位置
	lea	(a5),a0			;引数列の開始位置
	movem.l	(sp)+,d0-d1/a5
	rts


;----------------------------------------------------------------
	.end
