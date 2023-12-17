;----------------------------------------------------------------
;	X68k High-speed Assembler
;		ワークエリア定義
;		< work.s >
;
;		Copyright 1990-1994  by Y.Nakamura
;			  1996-2023  by M.Kamada
;----------------------------------------------------------------

	.include	has.equ


;----------------------------------------------------------------
;	ワークエリア
;----------------------------------------------------------------
	.offset	0

;----------------------------------------------------------------
;	メモリ管理
MEMPTR::	.ds.l	1	;ワークエリアの開始アドレス
MEMLIMIT::	.ds.l	1	;メモリ不足で中断する限界のアドレス
TEMPPTR::	.ds.l	1	;ワークエリアの未使用領域へのポインタ
CMDLINEPTR::	.ds.l	1	;コマンドライン文字列へのポインタ

WORKCLRST::			;(ここから先のワークが0で初期化される)

;----------------------------------------------------------------
;	ファイル管理
INCPATHPTR::	.ds.l	1	;INCPATHPTR/INCPATHCMDへのポインタ
INCPATHENV::	.ds.l	1	;環境変数で指定されたインクルードパス名のリスト
INCPATHCMD::	.ds.l	1	;コマンドラインで指定されたインクルードパス名のリスト
TEMPPATH::	.ds.l	1	;テンポラリパス名へのポインタ
PRNWIDTH::	.ds.w	1	;PRNファイルの表示幅
PRNPAGEL::	.ds.w	1	;PRNファイル1ページの行数
PRNCODEWIDTH::	.ds.w	1	;PRNファイルのコード部の幅
PRNTITLE::	.ds.l	1	;PRNファイルのタイトル文字列へのポインタ
PRNSUBTTL::	.ds.l	1	;PRNファイルのサブタイトル文字列へのポインタ

SOURCENAME::	.ds.b	20	;ソースファイル名(拡張子を除く)
SOURCEFILE::	.ds.l	1	;ソースファイル名へのポインタ
INPFILE::	.ds.l	1	;入力ファイル名へのポインタ(ソース/インクルードファイル)
OBJFILE::	.ds.l	1	;オブジェクトファイル名へのポインタ
PRNFILE::	.ds.l	1	;PRNファイル名へのポインタ
SYMFILE::	.ds.l	1	;シンボルファイル名へのポインタ

INPFILPTR::	.ds.l	1	;入力ファイルポインタ(SOURCEPTR/INCLDPTR)へのポインタ
OUTFILPTR::	.ds.l	1	;出力ファイルポインタ(TEMPFILPTR/OBJFILPTR)へのポインタ
SOURCEPTR::	.ds.b	F_PTRLEN	;ソースファイルポインタ
INCLDPTR::	.ds.b	F_PTRLEN	;インクルードファイルポインタ
TEMPFILPTR::	.ds.b	F_PTRLEN	;テンポラリファイルポインタ
OBJFILPTR::	.ds.b	F_PTRLEN	;オブジェクトファイルポインタ

PRNHANDLE::	.ds.w	1	;PRN/シンボルファイルのファイルハンドル
PRNMPAGE::	.ds.w	1	;PRNファイルのメインページ数(0ならSymbols)
PRNSPAGE::	.ds.w	1	;PRNファイルのサブページ数
PRNCOUNT::	.ds.w	1	;PRNファイルの行数カウンタ
PRNDATE::	.ds.b	20	;PRNファイルの作成日時
	.even

REQFILPTR::	.ds.l	1	;requestファイル名のポインタチェイン先頭
REQFILEND::	.ds.l	1	;requestファイル名のポインタチェイン末尾

INCLDNEST::	.ds.w	1	;インクルードファイルのネスティング
INCLDINFPTR::	.ds.l	1	;オープン前のファイル情報へのポインタ
INCLDINF::	.ds.b	INCLDMAXNEST*12		;オープン前のファイル情報
	.even

;----------------------------------------------------------------
;	ハッシュテーブル・シンボルテーブル関係
	.quad
SYMHASHPTR::	.ds.l	1	;シンボルハッシュテーブルへのポインタ
CMDHASHPTR::	.ds.l	1	;命令ハッシュテーブルへのポインタ

SYMTBLBEGIN::	.ds.l	1	;最初のシンボルテーブルブロックへのポインタ
SYMTBLCURBGN::	.ds.l	1	;現在のシンボルテーブルブロックへのポインタ
SYMTBLPTR::	.ds.l	1	;最後に使用したシンボルテーブルへのポインタ
SYMTBLCOUNT::	.ds.w	1	;残りのシンボルテーブル数

;----------------------------------------------------------------
;	オプションスイッチ他フラグ
MAKEPRN::	.ds.b	1	;PRNファイルを作成するならtrue			(-p)
ALLXREF::	.ds.b	1	;未定義シンボルをXREFするならtrue		(-u)
ALLXDEF::	.ds.b	1	;全シンボルをXDEFするならtrue			(-d)
OPTIMIZE::	.ds.b	1	;前方参照の最適化をしないならtrue		(-n)
SYMLEN8::	.ds.b	1	;シンボル長を8文字にするならtrue		(-8)
MAKESYM::	.ds.b	1	;シンボルファイルを作成するならtrue		(-x)
NOPAGEFF::	.ds.b	1	;PRNファイルのページングをしないならtrue	(-f)
DISPTITLE::	.ds.b	1	;起動時にタイトルを表示しないならtrue		(-l)
WARNLEVEL::	.ds.b	1	;ワーニング出力レベル(0～4)			(-w)
EXTSHORT::	.ds.b	1	;外部参照オフセットのデフォルトがロングならtrue	(-e)
MAKESYMDEB::	.ds.b	1	;SCD用デバッグ情報を出力するならtrue		(-g)
COMPATMODE::	.ds.b	1	;HAS v2.xと互換のある最適化を行うならtrue	(-c)
LONGABS::	.ds.b	1	;ロングワードのPC間接を絶対ロングにするならtrue	(-b)
PCTOABSL::	.ds.b	1	;-b2または-b4のときtrue
PCTOABSLNOTALL::	.ds.b	1	;-b4でないときtrue
PCTOABSLCAN::	.ds.b	1	;-b4でなくてlea/pea/jmp/jsrのときtrue
ABSLTOOPC::	.ds.b	1	;絶対ロングを(d,OPC)にするならtrue		(-1)
ABSLTOOPCCAN::	.ds.b	1	;ABSLTOOPCを無効化する

G2ASMODE::	.ds.b	1	;g2asモード
MAKESCD::	.ds.b	1	;SCD用シンボル情報を出力するならtrue
MAKERSECT::	.ds.b	1	;相対セクション情報を出力するならtrue
COMPATSWA::	.ds.b	1	;(HAS v2.x互換) -aスイッチが指定されたらtrue
COMPATSWQ::	.ds.b	1	;(HAS v2.x互換) -qスイッチが指定されたらtrue
ISPRNSTDOUT::	.ds.b	1	;PRNファイル作成先が標準出力ならtrue

NOABSSHORT::	.ds.b	1	;絶対ショートに対応しないならtrue
NOQUICK::	.ds.b	1	;クイックイミディエイトへの変換をしないならtrue
NONULDISP::	.ds.b	1	;0(An)→(An)への変換をしないならtrue
NOBRACUT::	.ds.b	1	;次の命令へのbra命令を削除しないならtrue

OPTMOVEA::	.ds.b	1	;MOVEAを最適化しないならtrue
OPTCLR::	.ds.b	1	;CLRを最適化するならtrue
OPTADDASUBA::	.ds.b	1	;ADDA/SUBAを最適化するならtrue
OPTCMPA::	.ds.b	1	;CMPAを最適化するならtrue
OPTLEA::	.ds.b	1	;LEAを最適化するならtrue
OPTSIZESET::	.ds.b	1	;サイズ指定のコピー
OPTASL::	.ds.b	1	;ASLを最適化するならtrue
OPTCMP0::	.ds.b	1	;CMP#0を最適化するならtrue
OPTMOVE0::	.ds.b	1	;MOVE#0を最適化するならtrue
OPTCMPI0::	.ds.b	1	;CMPI#0を最適化するならtrue
OPTSUBADDI0::	.ds.b	1	;SUBI/ADDI#0を最適化するならtrue
OPTBSR::	.ds.b	1	;直後へのbsrをpeaにするならtrue
OPTJMPJSR::	.ds.b	1	;jmp/jsrを最適化するならtrue
BRATOJBRA::	.ds.b	1	;BRA/BSR/BccをJBRA/JBSR/JBccにするならtrue
	.even
X_FSCC::	.ds.w	1	;FScc→FBcc
X_MOVEP::	.ds.w	1	;MOVEP展開(展開するCPUのビットが1)

MAKEALIGN::	.ds.b	1	;拡張アラインメント情報を出力するならtrue
MAXALIGN::	.ds.b	1	;ソース中で使用された最大のアライン値(2^n)

;----------------------------------------------------------------
;	アセンブルコード
	.even
DSPADRCODE::	.ds.b	1	;処理中の実効アドレスが(d,An)/(d,PC)ならtrue
DSPADRDEST::	.ds.b	1	;処理中の実効アドレスがデスティネーションならtrue

	.align	4
ICPUNUMBER::	.ds.l	1	;CPU番号の初期値(68000など)
ICPUTYPE::	.ds.w	1	;CPUタイプの初期値(C000など)
CPUNUMBER::	.ds.l	1	;現在のCPU番号(68000など)
	.even
CPUTYPE::	.ds.b	1	;現在のCPUタイプ
CPUTYPE2::	.ds.b	1	;ColdFireのタイプ

EXTSIZE::	.ds.b	1	;外部参照/未定シンボルのデータサイズ(SZ_WORD or SZ_LONG)
EXTSIZEFLG::	.ds.b	1	;外部参照/未定シンボルのデータサイズがSZ_LONGならtrue
	.even
EXTLEN::	.ds.l	1	;外部参照/未定シンボルのデータサイズ(2 or 4)
FPCPID::	.ds.w	1	;浮動小数点コプロセッサID(b9～11)

;----------------------------------------------------------------
;	命令解釈
ASMPASS::	.ds.b	1	;現在のアセンブルパス(1～3)
ISASMEND::	.ds.b	1	;ソースリストで.endが現れたらtrue

ISMACRO::	.ds.b	1	;処理中の命令がマクロならtrue
CMDOPSIZE::	.ds.b	1	;処理中の命令のオペレーションサイズ(-1ならサイズなし)
	.quad
CMDTBLPTR::	.ds.l	1	;処理中の命令・マクロのシンボルテーブルへのポインタ

;----------------------------------------------------------------
;	ラベル定義
LOCALLENMAX::	.ds.w	1	;数字ローカルラベルの最大桁数(1～4)
LOCALNUMMAX::	.ds.w	1	;数字ローカルラベルの最大番号+1(10～10000)
	.quad
LOCALMAXPTR::	.ds.l	1	;ローカルラベルの次に使用する番号のテーブルへのポインタ
LABNAMEPTR::	.ds.l	1	;これから定義するラベルへのポインタ
LABNAMELEN::	.ds.w	1	;これから定義するラベルの長さ(無ければ-1)
LABXDEF::	.ds.b	1	;これから定義するラベルを外部定義するならtrue
	.even

;----------------------------------------------------------------
;	条件アセンブル
IFNEST::	.ds.w	1	;条件アセンブルのネスティング
IFSKIPNEST::	.ds.w	1	;.ifの不成立部読み飛ばしのネスティング
ISIFSKIP::	.ds.b	1	;.ifの不成立部の読み飛ばし中ならtrue
	.even

;----------------------------------------------------------------
;	ロケーションカウンタ
	.quad
LOCATION::	.ds.l	1	;現在のセクションのロケーションカウンタ
LTOPLOC::	.ds.l	1	;処理中の行頭のロケーションカウンタ'*'
LASTSYMLOC::	.ds.l	1	;最後にラベルに定義したロケーションカウンタ
LCURLOC::	.ds.l	1	;現在処理中のロケーションカウンタ'$'
LOCOFFSET::	.ds.l	1	;最適化時のロケーションオフセット
SECTION::	.ds.b	1	;現在のセクション番号
ORGNUM::	.ds.b	1	;現在のorgセクション番号
	.quad
LOCCTRBUF::	.ds.l	N_SECTIONS	;各セクションのロケーションカウンタ
LOCOFFSETBUF::	.ds.l	N_SECTIONS	;各セクションの最適化ロケーションオフセット
ORGNUMBUF::	.ds.b	N_SECTIONS	;各セクションのorgセクション番号

OFFSYMMOD::	.ds.b	1	;0=offsymでない,-1=offsymでシンボルなし,1=offsymでシンボルあり
	.quad
OFFSYMVAL::	.ds.l	1	;offsymで初期値を与えるシンボルがあるときの初期値
OFFSYMSYM::	.ds.l	1	;offsymで初期値を与えるシンボル
OFFSYMTMP::	.ds.l	1	;offsymで初期値を与えるシンボルがあるときに
				;初期値を与えるシンボルの位置の
				;ロケーションカウンタを格納する仮のシンボル
OFFSYMNUM::	.ds.w	1	;ハッシュ関数値を分散させるためのカウンタ

;----------------------------------------------------------------
;	オブジェクト出力
ISOBJOUT::	.ds.b	1	;オブジェクト出力を抑制するならtrue
	.even
OBJLENCTR::	.ds.l	1	;オブジェクトファイル長カウンタ
OBJCONCTR::	.ds.w	1	;定数オブジェクト出力カウンタ
OBJCONBUF::	.ds.b	256	;定数オブジェクト出力バッファ

;----------------------------------------------------------------
;	オペランド解釈
EXPRSIZE::	.ds.b	1	;式に指定されたサイズ
EXPRISSTR::	.ds.b	1	;式が文字列を含むならtrue
	.even
EXPRSPSAVE::	.ds.l	1	;sp値保存用

RPNSTACK::	.ds.w	256	;逆ポーランド式変換/演算用スタック
ROFSTSYMNO::	.ds.w	1	;オフセット付き外部参照でのシンボル番号
EXPRORGNUM::	.ds.w	1	;式のorgセクション番号

OPRBUFPTR::	.ds.l	1	;オペランドの中間コード変換バッファ/文字列処理用ワークへのポインタ
RPNBUF::
EABUF1::	.ds.b	EABUFSIZE	;実効アドレス解釈バッファ
EABUF2::	.ds.b	EABUFSIZE	;	〃

RPNSIZEEX::	.ds.b	1	;式のサイズ
	.even
RPNLENEX::	.ds.w	1	;逆ポーランド式の長さ(-1なら定数/0なら式がない)
RPNBUFEX::	.ds.w	128	;逆ポーランド式バッファ/定数値

;----------------------------------------------------------------
;	エラー処理
NUMOFERR::	.ds.w	1	;Fatal errorの数
SPSAVE::	.ds.l	1	;エラー処理後のspの値
ERRRET::	.ds.l	1	;エラー処理後の戻りアドレス
ERRMESSYM::	.ds.l	1	;エラーメッセージに埋め込むシンボル

;----------------------------------------------------------------
;	ソフトウェアエミュレーションのチェック
SOFTFLAG::	.ds.w	1	;ソフトウェアエミュレーションかどうか

;----------------------------------------------------------------
;	エラッタ
F43GTEST::	.ds.b	1	;F43G対策を行うか
	.quad
F43GPTR::	.ds.l	1	;次に使用するレコードへのポインタ
F43GREC::	.ds.b	16*5
;	.ds.l	1	;直後の命令のレコードへのポインタ(固定)
;	.ds.l	1	;直前の命令のレコードへのポインタ(固定)
;	.ds.l	4	;T_NOPを挿入した位置(-1=1番目ではない)
;	.ds.b	1	;5命令の中で該当するものを示すフラグ(0=いずれも該当しない)
;	.ds.b	1	;使用しているアドレスレジスタのフラグ(2～5番目に該当するとき)
;	.ds.b	2

IGNORE_ERRATA::	.ds.b	1	;-1=エラッタの対策を禁止

;----------------------------------------------------------------
;	シンボルの上書き禁止の強化
OWSET::		.ds.b	1	;-1=setの上書き禁止を強化する
OWOFFSYM::	.ds.b	1	;-1=offsymの上書き禁止を強化する

;----------------------------------------------------------------
;プレデファインシンボル
	.even
CPUSYMBOL::	.ds.l	1	;プレデファインシンボルCPUのシンボルテーブルへのポインタ
STARTCPU::	.ds.l	1	;アセンブル開始時のCPU指定

ASSEMBLEDATE::	.ds.l	1	;_GETDATEの返却値
ASSEMBLETIM2::	.ds.l	1	;_GETTIM2の返却値

PREDEFINE::	.ds.b	1	;プレデファインシンボルを使うならtrue
		.even

;----------------------------------------------------------------
;	PRNファイル
	.quad
LINENUM::	.ds.l	1	;処理中の行番号
LINEPTR::	.ds.l	1	;処理中の行バッファを指すポインタ
LINEBUFPTR::	.ds.l	1	;処理中の行の読み込みバッファへのポインタ

PRNLATR::	.ds.w	1	;処理中の行の場所(0:ソース/1:インクルード/2:マクロ展開)
PAGEFLG::	.ds.w	1	;PRNファイルの改ページフラグ
PFILFLG::	.ds.b	1	;PRNファイル中のファイル名表示フラグ
ISNLIST::	.ds.b	1	;.nlistならtrue
ISLALL::	.ds.b	1	;.lallならtrue
PADVFLG::	.ds.b	1	;現在の行がPRNファイルに先行出力済みならtrue
	.even
PRNLPTR::	.ds.l	1	;PRNファイルコード部を指すポインタ
PRNCODE::	.ds.b	512	;PRNファイルコード部のバッファ
		.ds.b	2	;エンドコード用のダミー

;----------------------------------------------------------------
;	マクロ定義・展開
MACLOCSNO::	.ds.w	1	;マクロ登録でのローカルシンボル番号
MACSYMPTR::	.ds.l	1	;定義中のマクロのシンボル属性テーブルアドレス
REPTSKIPNEST::	.ds.w	1	;登録時のrept/irp/irpc命令のネスティング
MACDEFEND::	.ds.l	1	;マクロ/irp/irpc登録時のパラメータ終了位置へのポインタ
MACMODE::	.ds.b	1	;現在登録中の命令が(0:マクロ/正:irp,irpc/負:rept)
ISMACDEF::	.ds.b	1	;現在マクロ等を定義中ならtrue
	.even

MACNEST::	.ds.w	1	;マクロ展開のネスティング
MACREPTNEST::	.ds.w	1	;マクロ/rept展開のネスティング
REPTCOUNT::	.ds.w	1	;rept展開の繰り返し回数(マクロなら0)
IRPPARAPTR::	.ds.l	1	;irp/irpc展開の実引数リストへのポインタ(rept展開なら0)
MACLOCSMAX::	.ds.w	1	;今までに使用したローカルシンボルの最大番号
MACLOCSBGN::	.ds.w	1	;現在のマクロ展開で使用するローカルシンボルの開始番号
MACLBGNPTR::	.ds.l	1	;現在展開中のマクロ行の開始位置へのポインタ
MACLPTR::	.ds.l	1	;現在展開中のマクロ行へのポインタ
MACINFPTR::	.ds.l	1	;マクロ展開ネスティング前の情報へのポインタ
MACINF::	.ds.b	MACROMAXNEST*24	;マクロ展開ネスティング前の情報
MACSIZE::	.ds.b	1	;現在展開中のマクロのサイズ指定
MACCOUNT::	.ds.b	1	;マクロの引数の個数
	.even
MACPARAPTR::	.ds.l	1	;マクロ引数バッファへのポインタ
MACPARAEND::	.ds.l	1	;マクロ引数バッファ終端へのポインタ
MACPARABUF::	.ds.b	2048	;マクロ登録/展開用引数バッファ

;----------------------------------------------------------------
;	SCDデバッグ情報
SCDFILE::	.ds.l	1	;SCDソースファイル名へのポインタ
SCDFILENUM::	.ds.l	1	;SCDソースファイル名の延長テーブルオフセット
NUMOFLN::	.ds.l	1	;行番号データの数
EXNAMELEN::	.ds.l	1	;シンボル名延長部の長さ
EXNAMEPTR::	.ds.l	1	;シンボル名延長部チェインの先頭
NUMOFSCD::	.ds.l	1	;拡張シンボル情報の数
NUMOFTAG::	.ds.l	1	;タグ情報の数
NUMOFFNC::	.ds.l	1	;関数情報の数
NUMOFLOC::	.ds.l	1	;ローカル変数情報の数
NUMOFSECT::	.ds.l	1	;セクション情報の数(=6)
NUMOFGLB::	.ds.l	1	;グローバル変数情報の数
SCDTEMP::	.ds.b	SCD_TBLLEN	;拡張シンボル情報の一時バッファ

SCDATTRIB::	.ds.b	1	;拡張シンボル属性($1x:ﾀｸﾞ/$2x:関数)
SCDATRPREV::	.ds.b	1	;1つ前の拡張シンボル属性
SCDLN::		.ds.w	1	;最後に使用した.ln行番号

SCDLNPTR::	.ds.l	1	;SCD行番号データへのポインタ
SCDDATAPTR::	.ds.l	1	;SCD拡張シンボル情報へのポインタ
LNOFST::	.ds.l	1	;次の行番号データへのオフセット
GLBDEFNUM::	.ds.l	1	;グローバル変数の位置
TAGDEFNUM::	.ds.l	1	;タグ定義開始位置
FNCDEFNUM::	.ds.l	1	;関数定義開始位置
FNCBFNUM::	.ds.l	1	;関数開始番号
FNCBBNUM::	.ds.l	1	;ブロック開始番号チェインの末尾
TAGBEGIN::	.ds.l	1	;タグ情報開始番号(tag検索用)

;----------------------------------------------------------------
;	オブジェクトファイル生成
DSBSIZE::	.ds.l	1	;.ds.bで確保する領域のサイズ
XREFSYMNO::	.ds.l	1	;外部参照シンボルの番号
ISXDEFMOD::	.ds.b	1	;外部定義シンボルの修正の必要があればtrue
ISUNDEFSYM::	.ds.b	1	;未定義シンボルがあればtrue
	.even

;----------------------------------------------------------------
;	最適化
OPTFLAG::	.ds.b	1	;最適化が行なわれたならtrue
OPTCOUNT::	.ds.b	1	;最適化回数カウント
OPTMOREFLG::	.ds.b	1	;1回目の最適化ならESZ_OPT|SZ_LONG(伸長後の縮小を許可する)
	.even

OPTEXTPOS::	.ds.l	1	;拡張ワードのテンポラリファイル位置
OPTEXTCODE::	.ds.w	1	;修正する拡張ワード
OPTDSPPOS::	.ds.l	1	;命令コードのテンポラリファイル位置
OPTDSPCODE::	.ds.w	1	;修正する命令コード(ディスプレースメントの最適化用)

;----------------------------------------------------------------
LOCSYMBUF::	.ds.b	LOCSYMBUFSIZE+256	;マクロ内のローカルシンボル名のバッファ
				;(1つのマクロ定義で使えるローカルシンボルの最大サイズ)

	.fail	$8000<=$	;この手前のシンボルは(d16,a6)で参照できる

;----------------------------------------------------------------
;	ハッシュテーブル本体
	.quad
SYMHASHTBL::	.ds.l	SYMHASHSIZE	;シンボルハッシュテーブル
CMDHASHTBL::	.ds.l	CMDHASHSIZE	;命令ハッシュテーブル

;----------------------------------------------------------------
	.quad
WORKSIZE::


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
	.end

;----------------------------------------------------------------
;
;	Revision 3.7  2023-07-06 12:00:00  M.Kamada
;	+90 環境変数HASの-iをコマンドラインの-iの後に検索する
;
;	Revision 3.6  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 3.5  2016-01-01 12:00:00  M.Kamada
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 3.4  1999  4/24(Sat) 02:55:54 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;
;	Revision 3.3  1999  3/19(Fri) 16:03:39 M.Kamada
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;
;	Revision 3.2  1999  3/ 4(Thu) 02:34:33 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 quad追加
;	+82 F43GRECのサイズを14→16バイト
;	+82 スタックエリアのサイズを1024→4096バイト
;
;	Revision 3.1  1999  2/27(Sat) 23:46:12 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 3.0  1999  2/25(Thu) 04:57:20 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;	+80 setでset以外で定義されたシンボルの上書き禁止
;
;	Revision 2.9  1998 10/10(Sat) 02:35:31 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 2.8  1998  8/18(Tue) 20:02:35 M.Kamada
;	+72 .sizemの第2引数のローカルシンボルにマクロの引数の個数を定義する
;
;	Revision 2.7  1998  4/13(Mon) 04:29:15 M.Kamada
;	+64 エラッタの対策を禁止するスイッチを追加
;
;	Revision 2.6  1998  3/31(Tue) 02:09:48 M.Kamada
;	+63 jmp/jsrを最適化する
;
;	Revision 2.5  1998  1/24(Sat) 17:18:30 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 2.4  1998  1/10(Sat) 15:35:59 M.Kamada
;	+56 -f43gを削除
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 2.3  1998  1/ 5(Mon) 01:04:04 M.Kamada
;	+55 -b[n]
;
;	Revision 2.2  1997 10/13(Mon) 02:11:04 M.Kamada
;	+51 直後へのbsr→pea
;	+52 jmp/jsrを最適化する
;
;	Revision 2.1  1997  9/22(Mon) 03:13:09 M.Kamada
;	+47 movepとfsccのエミュレーションを拡充
;
;	Revision 2.0  1997  9/15(Mon) 03:59:07 M.Kamada
;	+45 shiftのためにマクロの引数の展開方法を変更
;
;	Revision 1.9  1997  9/17(Wed) 17:44:36 M.Kamada
;	+44 software emulationの命令を展開する
;
;	Revision 1.8  1997  7/ 8(Tue) 14:31:07 M.Kamada
;	+39 -1の挙動を修正する
;
;	Revision 1.7  1997  6/26(Thu) 22:05:59 M.Kamada
;	+33 プレデファインシンボルCPUに対応する
;	+34 プレデファインシンボル__DATE__,__TIME__に対応する
;	+35 CMP.bwl #0,Dn→TST.bwl Dn
;	+36 MOVE.bw #0,Dn→CLR.bw Dn
;	+37 -up,-dpでプレデファインシンボルの禁止,許可
;	+38 CMPI.bwl #0,<ea>→TST.bwl <ea>
;
;	Revision 1.6  1997  4/ 5(Sat) 18:43:26 M.Kamada
;	+24 MOVEAを最適化する
;	+25 CLRを最適化する
;	+26 ADDA/CMPA/SUBAを最適化する
;	+28 LEAを最適化する
;	+29 ASLを最適化する
;
;	Revision 1.5  1997  3/14(Fri) 22:59:17 M.Kamada
;	+18 サイズ指定のない定数でない絶対ロングを(d,OPC)にする
;	+20 -1の挙動を修正
;
;	Revision 1.4  1996 11/13(Wed) 18:21:16 M.Kamada
;	+07 F43G対策
;
;	Revision 1.3  1994/06/09  14:23:34  nakamura
;	バグフィックスにともなうワークの追加。
;
;	Revision 1.2  1994/03/06  02:53:50  nakamura
;	仕様拡張に伴うワークエリアの追加
;
;	Revision 1.1  1994/02/13  15:31:52  nakamura
;	Initial revision
;
;
