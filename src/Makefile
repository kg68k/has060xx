# Makefile for HAS060.X

# COMMAND.X を前提としています


VER = 91

LZH_B = HAS060$(VER).LZH
LZH_S = HASSRC$(VER).LZH
LZH_D = HASDAT$(VER).LZH


AS = has060 -c4 -u
# -sUNIX_NEWLINE=1 …メッセージの改行コードを$0Aにする
# -sEUCMES=1 …メッセージをEUCで出力する
# -sEUCSRC=1 …ソースをEUCで受け付ける

LK = lk -e4 -x

ARC = lha a -t
ARC2 = lha u -t


BIN = README.DOC HAS060.DOC HAS060.X DEBUGGED.DOC KNOWNBUG.DOC \
	HISTORY.DOC PROJECTS.DOC \
	HANOI.S K_MACRO.MAC

SRC1 = Makefile doscall.mac \
	cputype.equ eamode.equ error2.equ has.equ register.equ \
	symbol.equ tmpcode.equ
SRC2 = doasm.s eamode.s encode.s error.s error2.s expr.s \
	fexpr.s file.s macro.s main.s misc.s objgen.s opname.s \
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

OBJ = main.o optimize.o doasm.o file.o misc.o symbol.o \
	error2.o pseudo.o expr.o macro.o encode.o \
	eamode.o objgen.o error.o regname.o fexpr.o opname.o work.o


all:	HAS060.X

lzh:	$(LZH_B) $(LZH_S) $(LZH_D)


clean:
	command if exist *.o del *.o /y


HAS060.X:	$(OBJ)
	$(LK) -o HAS060.X $(OBJ) > lk.out


$(LZH_B):	$(BIN)
	command if exist $(LZH_B) del $(LZH_B)
	$(ARC) $(LZH_B) $(BIN)

$(LZH_S):	$(SRC)
	command if exist $(LZH_S) del $(LZH_S)
	$(ARC) $(LZH_S) $(SRC1)
	$(ARC2) $(LZH_S) $(SRC2)

$(LZH_D):	$(DAT)
	command if exist $(LZH_D) del $(LZH_D)
	$(ARC) $(LZH_D) $(DAT)


doasm.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ error2.equ doasm.s
	$(AS) doasm.s

eamode.o:	has.equ cputype.equ eamode.equ register.equ \
		tmpcode.equ symbol.equ eamode.s
	$(AS) eamode.s

encode.o:	has.equ tmpcode.equ register.equ symbol.equ \
		encode.s
	$(AS) encode.s

error.o:	doscall.mac has.equ tmpcode.equ error.s
	$(AS) error.s

error2.o:	has.equ error2.s
	$(AS) error2.s

expr.o:		has.equ register.equ tmpcode.equ symbol.equ expr.s
	$(AS) expr.s

fexpr.o:	has.equ register.equ tmpcode.equ symbol.equ fexpr.s
	$(AS) fexpr.s

file.o:		doscall.mac has.equ tmpcode.equ error2.equ file.s
	$(AS) file.s

macro.o:	has.equ cputype.equ register.equ tmpcode.equ \
		symbol.equ macro.s
	$(AS) macro.s

main.o:		doscall.mac has.equ symbol.equ register.equ \
		cputype.equ error2.equ main.s
	$(AS) main.s

misc.o:		doscall.mac has.equ register.equ misc.s
	$(AS) misc.s

objgen.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ objgen.s
	$(AS) objgen.s

opname.o:	has.equ cputype.equ register.equ opname.s
	$(AS) opname.s

optimize.o:	has.equ symbol.equ register.equ tmpcode.equ \
		cputype.equ eamode.equ error2.equ optimize.s
	$(AS) optimize.s

pseudo.o:	doscall.mac has.equ cputype.equ register.equ \
		tmpcode.equ symbol.equ pseudo.s
	$(AS) pseudo.s

regname.o:	has.equ cputype.equ register.equ regname.s
	$(AS) regname.s

symbol.o:	has.equ symbol.equ tmpcode.equ symbol.s
	$(AS) symbol.s

work.o:		has.equ work.s
	$(AS) work.s
