;----------------------------------------------------------------
;	X68k High-speed Assembler
;		長距離分岐用の中継地点
;		< trampoline.s >
;
;		Copyright 2026       by TcbnErik
;----------------------------------------------------------------

	.include	has.equ

asmpass3_::	bra	asmpass3
makesymfile_::	bra	makesymfile
chkdtsize_::	bra	chkdtsize

crlf_msg::	.dc.b	CRLF,0


;----------------------------------------------------------------
	.end
