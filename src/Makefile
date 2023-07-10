# Makefile for HAS060X.X


AS = has060 -c4 -u
# -sUNIX_NEWLINE=1 …メッセージの改行コードを$0Aにする
# -sEUCMES=1 …メッセージをEUCで出力する
# -sEUCSRC=1 …ソースをEUCで受け付ける

LK = hlk -e4 -x


BIN = README.DOC HAS060.DOC HAS060.X DEBUGGED.DOC KNOWNBUG.DOC \
	HISTORY.DOC PROJECTS.DOC \
	HANOI.S K_MACRO.MAC

SRC1 = Makefile doscall.mac \
	cputype.equ eamode.equ error2.equ has.equ register.equ \
	symbol.equ tmpcode.equ
SRC2 = doasm.s eamode.s encode.s error.s error2.s expr.s \
	fexpr.s file.s hupair.s macro.s main.s misc.s objgen.s opname.s \
	optimize.s pseudo.s regname.s symbol.s work.s

SRC = $(SRC1) $(SRC2)

DAT = M68K.DOC COLDFIRE.DOC


#link順序に注意
#opname.s→macro.s(irp,irpc)は$7FFFを超えてもリンカがワーニングを出さない?
#*+46でerror2.equとerror2.sを新たに追加した
#*+52でdoasmのorandの最初のgeteamodeがオーバーフロー
#*+63でwrt～が届かなくなったのでencode.sのdeflabelをencode.sの先頭に移動
#*+66でencode.sからmisc.sにあるgetfplenへの参照がオーバーフロー
#*+80でopadr_tbl内のオフセットをロングにしたのでopname.oをwork.oの直前に移動
#*+80でfile.oとmisc.oをdoasm.oの後ろに移動
#*+80でdoasm.sのchkdtsizeをobjgen.sにコピー
#*+83でsymbol.sの先頭のreg_tblが届かなくなったのでfexpr.oとregname.oを入れ換え

OBJ = main.o hupair.o optimize.o doasm.o file.o misc.o symbol.o \
	error2.o pseudo.o expr.o macro.o encode.o \
	eamode.o objgen.o error.o regname.o fexpr.o opname.o work.o


all:	has060x.x


clean:
	rm -f $(OBJ) has060x.x


has060x.x:	$(OBJ)
	$(LK) -o $@ $(OBJ)


doasm.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ error2.equ doasm.s
eamode.o:	has.equ cputype.equ eamode.equ register.equ \
		tmpcode.equ symbol.equ eamode.s
encode.o:	has.equ tmpcode.equ register.equ symbol.equ \
		encode.s
error.o:	doscall.mac has.equ tmpcode.equ error.s
error2.o:	has.equ error2.s
expr.o:		has.equ register.equ tmpcode.equ symbol.equ expr.s
fexpr.o:	has.equ register.equ tmpcode.equ symbol.equ fexpr.s
file.o:		doscall.mac has.equ tmpcode.equ error2.equ file.s
hupair.o:	hupair.s
macro.o:	has.equ cputype.equ register.equ tmpcode.equ \
		symbol.equ macro.s
main.o:		doscall.mac has.equ symbol.equ register.equ \
		cputype.equ error2.equ main.s
misc.o:		doscall.mac has.equ register.equ misc.s
objgen.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ objgen.s
opname.o:	has.equ cputype.equ register.equ opname.s
optimize.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ error2.equ optimize.s
pseudo.o:	doscall.mac has.equ cputype.equ register.equ \
		tmpcode.equ symbol.equ pseudo.s
regname.o:	has.equ cputype.equ register.equ regname.s
symbol.o:	has.equ symbol.equ tmpcode.equ symbol.s
work.o:		has.equ work.s

%.o: %.s
	$(AS) $<
