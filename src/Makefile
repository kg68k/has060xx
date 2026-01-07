# Makefile for HAS060X.X


AS = has060 -c4 -u
# -sUNIX_NEWLINE …メッセージの改行コードを$0Aにする

LK = hlk -e4 -x

U8TOSJ = u8tosj

ARCHIVE_ZIP = hasx.zip
DOCS = CHANGELOG.txt README.txt

BIN = README.DOC HAS060.DOC HAS060.X DEBUGGED.DOC KNOWNBUG.DOC \
	HISTORY.DOC PROJECTS.DOC \
	HANOI.S K_MACRO.MAC

SRC1 = Makefile doscall.mac eamode.equ error2.equ has.equ register.equ \
	symbol.equ tmpcode.equ work.equ
SRC2 = doasm.s eamode.s encode.s error.s error2.s expr.s \
	fexpr.s file.s hupair.s macro.s main.s misc.s objgen.s opname.s \
	optimize.s pseudo.s regname.s symbol.s trampoline.s

SRC = $(SRC1) $(SRC2)


#link順序に注意

OBJ = main.o hupair.o optimize.o doasm.o file.o misc.o symbol.o \
	error2.o trampoline.o pseudo.o expr.o macro.o encode.o \
	eamode.o objgen.o error.o regname.o fexpr.o opname.o


all:	has060x.x

.PHONY: clean archive

clean:
	rm -f $(OBJ) has060x.x CHANGELOG.txt


has060x.x:	$(OBJ)
	$(LK) -o $@ $(OBJ)


doasm.o:	has.equ symbol.equ register.equ tmpcode.equ eamode.equ error2.equ work.equ doasm.s
eamode.o:	has.equ eamode.equ register.equ tmpcode.equ symbol.equ work.equ eamode.s
encode.o:	has.equ tmpcode.equ register.equ symbol.equ work.equ encode.s
error.o:	has.equ doscall.mac tmpcode.equ work.equ error.s
error2.o:	has.equ error2.s
expr.o:		has.equ register.equ tmpcode.equ symbol.equ work.equ expr.s
fexpr.o:	has.equ register.equ tmpcode.equ symbol.equ work.equ fexpr.s
file.o:		has.equ doscall.mac tmpcode.equ error2.equ work.equ file.s
hupair.o:	has.equ work.equ hupair.s
macro.o:	has.equ register.equ tmpcode.equ symbol.equ work.equ macro.s
main.o:		has.equ doscall.mac symbol.equ register.equ error2.equ work.equ version.equ main.s
misc.o:		has.equ doscall.mac register.equ work.equ misc.s
objgen.o:	has.equ symbol.equ register.equ tmpcode.equ eamode.equ work.equ objgen.s
opname.o:	has.equ register.equ opname.s
optimize.o:	has.equ symbol.equ register.equ tmpcode.equ eamode.equ error2.equ work.equ optimize.s
pseudo.o:	has.equ doscall.mac register.equ tmpcode.equ symbol.equ work.equ pseudo.s
regname.o:	has.equ register.equ regname.s
symbol.o:	has.equ symbol.equ tmpcode.equ work.equ symbol.s

%.o: %.s
	$(AS) $<


ifdef SRC_DIR
archive: $(ARCHIVE_ZIP)
else
archive: ../srcdir.txt
	$(if $(SRC_DIR_IS_DEFINED),$(error SRC_DIR is empty.))
	make $@ SRC_DIR_IS_DEFINED=yes SRC_DIR=$(shell cat ../srcdir.txt)
../srcdir.txt:
	$(error file 'srcdir.txt' created by src2build is required.)
endif

$(ARCHIVE_ZIP): $(DOCS) has060x.x
	rm -f $@
	zip -9 $@ $^

CHANGELOG.txt: $(SRC_DIR)/../CHANGELOG.md
	rm -f $@
	$(U8TOSJ) < $^ > $@

README.txt: $(SRC_DIR)/../README.md
	rm -f $@
	$(U8TOSJ) < $^ > $@

