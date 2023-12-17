;----------------------------------------------------------------
;	X68k High-speed Assembler
;		エラーハンドル
;		< error2.s >
;
;	$Id: error2.s,v 2.0  2016-01-01 12:00:00  M.Kamada Exp $
;
;		Copyright 1997-2016  by M.Kamada
;		Copyright 2023       by TcbnErik
;----------------------------------------------------------------

	.include	has.equ


abswarn2::		bra	abswarn
absshwarn2::		bra	absshwarn
shortwarn2::		bra	shortwarn
shortwarn_cmpa2::	bra	shortwarn_cmpa
shvalwarn_absw2::	bra	shvalwarn_absw
shvalwarn_d162::	bra	shvalwarn_d16
shvalwarn_d82::		bra	shvalwarn_d8
reglwarn2::		bra	reglwarn
alignwarn2::		bra	alignwarn
alignwarn_op2::		bra	alignwarn_op
softwarn2::		bra	softwarn
f43gwarn2::		bra	f43gwarn
movetouspwarn2::	bra	movetouspwarn
insigbitwarn2::		bra	insigbitwarn
indexszwarn2::		bra	indexszwarn
redefwarn_set2::	bra	redefwarn_set
redefwarn_offsym2::	bra	redefwarn_offsym
ds_negative_warn2::	bra	ds_negative_warn
internalfpwarn2::	bra	internalfpwarn

forcederr2::		bra	forcederr
redeferr2::		bra	redeferr
redeferr_predefine2::	bra	redeferr_predefine
redeferr_set2::		bra	redeferr_set
redeferr_offsym2::	bra	redeferr_offsym
badopeerr2::		bra	badopeerr
badopeerr_local2::	bra	badopeerr_local
ilsymerr_value2::	bra	ilsymerr_value
ilsymerr_local2::	bra	ilsymerr_local
ilsymerr_real2::	bra	ilsymerr_real
ilsymerr_regsym2::	bra	ilsymerr_regsym
ilsymerr_register2::	bra	ilsymerr_register
ilsymerr_predefxdef2::	bra	ilsymerr_predefxdef
ilsymerr_predefxref2::	bra	ilsymerr_predefxref
ilsymerr_predefglobl2::	bra	ilsymerr_predefglobl
ilsymerr_lookfor2::	bra	ilsymerr_lookfor
exprerr2::		bra	exprerr
exprerr_ea2::		bra	exprerr_ea
exprerr_cannotscale2::	bra	exprerr_cannotscale
exprerr_scalefactor2::	bra	exprerr_scalefactor
exprerr_fullformat2::	bra	exprerr_fullformat
exprerr_immediate2::	bra	exprerr_immediate
regerr2::		bra	regerr
regerr_opc2::		bra	regerr_opc
iladrerr2::		bra	iladrerr

ilsizeerr_op2::		bra	ilsizeerr_op
ilsizeerr_pseudo2::	bra	ilsizeerr_pseudo
ilsizeerr_moveusp2::	bra	ilsizeerr_moveusp
ilsizeerr_cf_acc2::	bra	ilsizeerr_cf_acc
ilsizeerr_fpn2::	bra	ilsizeerr_fpn
ilsizeerr_fprn2::	bra	ilsizeerr_fprn
ilsizeerr_fpcr2::	bra	ilsizeerr_fpcr
ilsizeerr_fmovemfpn2::	bra	ilsizeerr_fmovemfpn
ilsizeerr_fmovemfpcr2::	bra	ilsizeerr_fmovemfpcr
ilsizeerr_cf_long2::	bra	ilsizeerr_cf_long
ilsizeerr_cf_bccl2::	bra	ilsizeerr_cf_bccl
ilsizeerr2::		bra	ilsizeerr
ilsizeerr_pseudo_no2::	bra	ilsizeerr_pseudo_no
ilsizeerr_op_no2::	bra	ilsizeerr_op_no
ilsizeerr_ccr2::	bra	ilsizeerr_ccr
ilsizeerr_sr2::		bra	ilsizeerr_sr
ilsizeerr_an2::		bra	ilsizeerr_an
ilsizeerr_movetosr2::	bra	ilsizeerr_movetosr
ilsizeerr_movefrsr2::	bra	ilsizeerr_movefrsr
ilsizeerr_000_long2::	bra	ilsizeerr_000_long
ilsizeerr_sftrotmem2::	bra	ilsizeerr_sftrotmem
ilsizeerr_bitmem2::	bra	ilsizeerr_bitmem
ilsizeerr_bitreg2::	bra	ilsizeerr_bitreg
ilsizeerr_000_bccl2::	bra	ilsizeerr_000_bccl
ilsizeerr_trapcc2::	bra	ilsizeerr_trapcc

iloprerr2::		bra	iloprerr
iloprerr_not_fixed2::	bra	iloprerr_not_fixed
iloprerr_too_many2::	bra	iloprerr_too_many
iloprerr_pseudo_many2::	bra	iloprerr_pseudo_many
iloprerr_local2::	bra	iloprerr_local
iloprerr_ds_negative2::	bra	iloprerr_ds_negative
iloprerr_end_xref2::	bra	iloprerr_end_xref
iloprerr_internalfp2::	bra	iloprerr_internalfp
undefsymerr2::		bra	undefsymerr
undefsymerr_local2::	bra	undefsymerr_local
undefsymerr_offsym2::	bra	undefsymerr_offsym
divzeroerr2::		bra	divzeroerr
ilrelerr_outside2::	bra	ilrelerr_outside
ilrelerr_const2::	bra	ilrelerr_const
overflowerr2::		bra	overflowerr
ilvalueerr2::		bra	ilvalueerr
ilquickerr_addsubq2::	bra	ilquickerr_addsubq
ilquickerr_moveq2::	bra	ilquickerr_moveq
ilquickerr_mov3q2::	bra	ilquickerr_mov3q
ilquickerr_sftrot2::	bra	ilquickerr_sftrot
ilsfterr2::		bra	ilsfterr
featureerr_cpu2::	bra	featureerr_cpu
featureerr_xref2::	bra	featureerr_xref
nosymerr_macro2::	bra	nosymerr_macro
nosymerr_pseudo2::	bra	nosymerr_pseudo
tooinclderr2::		bra	tooinclderr
nofileerr2::		bra	nofileerr
mismacerr_exitm2::	bra	mismacerr_exitm
mismacerr_endm2::	bra	mismacerr_endm
mismacerr_local2::	bra	mismacerr_local
mismacerr_sizem2::	bra	mismacerr_sizem
mismacerr_eof2::	bra	mismacerr_eof
toomanylocsymerr2::	bra	toomanylocsymerr
macnesterr2::		bra	macnesterr
misiferr_else2::	bra	misiferr_else
misiferr_elseif2::	bra	misiferr_elseif
misiferr_endif2::	bra	misiferr_endif
misiferr_else_elseif2::	bra	misiferr_else_elseif
misiferr_eof2::		bra	misiferr_eof
termerr_doublequote2::	bra	termerr_doublequote
termerr_singlequote2::	bra	termerr_singlequote
termerr_bracket2::	bra	termerr_bracket
ilinterr2::		bra	ilinterr
offsymalignerr2::	bra	offsymalignerr

errout2::		bra	errout

crlf_msg2::		.dc.b	CRLF,0


;----------------------------------------------------------------
	.end
