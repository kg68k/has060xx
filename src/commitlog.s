;cputype.equ
;----------------------------------------------------------------
;	$Log: cputype.equ,v $
;	Revision 1.4  1999  2/27(Sat) 23:37:36 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.3  1999  2/20(Sat) 17:33:03 M.Kamada
;	+80 ColdFire対応
;
;	Revision 1.2  1996 11/13(Wed) 15:19:26 M.Kamada
;	68060を追加
;
;	Revision 1.1  1994/02/13  14:28:10  nakamura
;	Initial revision
;
;

;doasm.s
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

;eamode.equ
;----------------------------------------------------------------
;	$Log: eamode.equ,v $
;	Revision 1.2  1999  2/27(Sat) 23:38:34 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.1  1994/02/13  14:31:42  nakamura
;	Initial revision
;
;

;eamode.s
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

;encode.s
;----------------------------------------------------------------
;	$Log: encode.s,v $
;	Revision 3.2  1999 10/ 8(Fri) 21:48:40 M.Kamada
;	+86 外部参照宣言したシンボルを行頭ラベルとして再定義しようとするとバスエラーになる不具合
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 EUC対応準備
;
;	Revision 3.1  1999  6/ 9(Wed) 20:14:38 M.Kamada
;	+85 演算子!=を有効にする
;
;	Revision 3.0  1999  3/19(Fri) 16:30:23 M.Kamada
;	+83 「ローカルラベルの参照が不正です」を追加
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;	+83 foo=.low.～などがエラーになる不具合を回避
;
;	Revision 2.9  1999  3/ 2(Tue) 20:45:47 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 skiphasspcを廃止
;	+82 getwordを最適化
;
;	Revision 2.8  1999  2/27(Sat) 23:39:29 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.7  1999  2/25(Thu) 04:59:19 M.Kamada
;	+80 ColdFire対応
;	+80 .sizeof.追加
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.6  1998  8/22(Sat) 15:44:53 M.Kamada
;	+75 数字ローカルラベルが定義できなくなっていた
;
;	Revision 2.5  1998  8/20(Thu) 23:47:22 M.Kamada
;	+74 .if不成立部に間違ったローカルラベル(999:など)があるとエラーが出る 
;
;	Revision 2.4  1998  3/31(Tue) 02:18:51 M.Kamada
;	+63 wrt～が届かなくなったのでencode.sのdeflabelをソースの先頭に移動
;
;	Revision 2.3  1998  1/24(Sat) 21:12:06 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 2.2  1998  1/10(Sat) 15:59:06 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 2.1  1997 11/ 1(Sat) 19:58:30 M.Kamada
;	+53 1.wがエラーになる不具合
;
;	Revision 2.0  1997 10/28(Tue) 17:11:16 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;	+52 記述された整数が64bitを超えたらエラー
;	+52 1.E+10がエラーになる不具合
;
;	Revision 1.9  1997  9/15(Mon) 16:47:07 M.Kamada
;	+46 ST_VALUE=0で最適化,aslも最適化
;
;	Revision 1.8  1997  7/20(Sun) 03:12:08 M.Kamada
;	+41 リロケートできない所を修正
;
;	Revision 1.7  1997  6/24(Tue) 22:15:40 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;
;	Revision 1.6  1997  5/12(Mon) 22:27:15 M.Kamada
;	+31 行頭にcpusha dcと書くとエラーになる不都合を修正
;
;	Revision 1.5  1997  3/20(Thu) 16:04:35 M.Kamada
;	+11 2桁の数字ローカルラベルが使えるようにした
;	+23 terminator not foundをエラーに
;
;	Revision 1.4  1994/07/10  11:10:54  nakamura
;	コメント開始キャラクタの追加('#')
;	データサイズコード'.q'の追加
;
;	Revision 1.3  1994/06/09  15:07:10  nakamura
;	シンボルに'$'を使えるようにした。
;
;	Revision 1.2  1994/02/24  11:24:22  nakamura
;	ローカルラベル最後のコロンを忘れると二重定義でエラーになるのを修正した。
;
;	Revision 1.1  1994/02/15  11:55:44  nakamura
;	Initial revision
;
;

;error.s
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

;error2.equ
;----------------------------------------------------------------
;	$Log: error2.equ,v $
;	Revision 1.8  1999 10/ 8(Fri) 21:04:55 M.Kamada
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 '%s に外部参照値は指定できません'
;	+86 foo fequ fooのエラーメッセージがおかしい
;
;	Revision 1.7  1999  6/ 9(Wed) 23:38:51 M.Kamada
;	+85 .offsymでシンボル指定があるとき.even/.quad/.alignをエラーにする
;	+85 .dsの引数が負数のとき.text/.dataセクションではエラー,その他はワーニング
;
;	Revision 1.6  1999  4/24(Sat) 03:14:59 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;
;	Revision 1.5  1999  3/16(Tue) 03:46:59 M.Kamada
;	+83 「ローカルラベルの参照が不正です」を追加
;
;	Revision 1.4  1999  3/ 2(Tue) 20:47:41 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 疑似命令のパラメータが多すぎる場合のエラーチェックを強化
;
;	Revision 1.3  1999  2/27(Sat) 23:40:10 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.2  1998  3/30(Mon) 21:22:54 M.Kamada
;	+61 warning: insignificant bitを追加
;
;	Revision 1.1  1998  1/10(Sat) 15:45:44 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 1.0  1997  9/14(Sun) 16:34:09 M.Kamada
;	+46 error.sを分離
;	Initial revision
;
;

;error2.s
;----------------------------------------------------------------
;	$Log: error2.s,v $
;	Revision 2.0  2016-01-01 12:00:00  M.Kamada
;	+88 ワーニング「整数を単精度浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;
;	Revision 1.9  1999 10/ 8(Fri) 21:05:30 M.Kamada
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 改行コードの変更に対応
;	+86 '%s に外部参照値は指定できません'
;	+86 foo fequ fooのエラーメッセージがおかしい
;
;	Revision 1.8  1999  6/ 9(Wed) 23:40:08 M.Kamada
;	+85 .offsymでシンボル指定があるとき.even/.quad/.alignをエラーにする
;	+85 .dsの引数が負数のとき.text/.dataセクションではエラー,その他はワーニング
;
;	Revision 1.7  1999  4/24(Sat) 03:15:15 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;
;	Revision 1.6  1999  3/16(Tue) 03:47:26 M.Kamada
;	+83 「ローカルラベルの参照が不正です」を追加
;
;	Revision 1.5  1999  3/ 2(Tue) 20:47:20 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 疑似命令のパラメータが多すぎる場合のエラーチェックを強化
;
;	Revision 1.4  1999  2/27(Sat) 23:40:33 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.3  1998  3/30(Mon) 21:21:58 M.Kamada
;	+61 warning: insignificant bitを追加
;
;	Revision 1.2  1998  1/10(Sat) 15:45:18 M.Kamada
;	+56 MOVE to USPのエラッタを回避
;
;	Revision 1.1  1997 10/28(Tue) 16:40:34 M.Kamada
;	+52 記述された整数が64bitを超えたらエラー
;
;	Revision 1.0  1997  9/14(Sun) 16:36:41 M.Kamada
;	+46 error.sを分離
;	Initial revision
;
;

;expr.s
;----------------------------------------------------------------
;	$Log: expr.s,v $
;	Revision 2.3  2016-01-01 12:00:00  M.Kamada
;	+88 
;
;	Revision 2.2  1999  6/ 9(Wed) 22:59:26 M.Kamada
;	+85 演算子.notb./.notw.を追加
;
;	Revision 2.1  1999  3/19(Fri) 15:26:42 M.Kamada
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;
;	Revision 2.0  1999  2/28(Sun) 20:09:14 M.Kamada
;	+82 エラーメッセージを日本語化
;
;	Revision 1.9  1999  2/27(Sat) 23:40:53 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.8  1999  2/24(Wed) 21:45:56 M.Kamada
;	+80 .sizeof.と.defined.を追加
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 1.7  1997 11/23(Sun) 15:58:06 M.Kamada
;	+54 浮動小数点イミディエイトの分割表記に負の整数を書けない不具合
;
;	Revision 1.6  1997 10/26(Sun) 16:36:13 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;
;	Revision 1.5  1994/07/10  15:04:26  nakamura
;	若干のバグフィックス
;
;	Revision 1.4  1994/06/09  14:30:56  nakamura
;	括弧内に浮動小数点実数があった場合のスタック補正のバグを修正。
;
;	Revision 1.3  1994/05/29  10:04:56  nakamura
;	パス2で正しい式の値が得られないことがあるバグを修正
;
;	Revision 1.2  1994/03/06  09:10:26  nakamura
;	'$'が正しいロケーションカウンタ値を指さないことがあるバグをfix
;
;	Revision 1.1  1994/02/15  16:00:04  nakamura
;	Initial revision
;
;

;fexpr.s
;----------------------------------------------------------------
;	$Log: fexpr.s,v $
;	Revision 1.9  2016-01-01 12:00:00  M.Kamada
;	+88 文字列→浮動小数点数変換で正確に表現できる数に誤差が入る不具合
;
;	Revision 1.8  1999 10/ 6(Wed) 14:54:26 M.Kamada
;	+86 浮動小数点数を含む式で+符号が使えなかった
;	+86 浮動小数点数を含む式で加算と減算が逆になっていた
;
;	Revision 1.7  1999  6/ 9(Wed) 22:51:03 M.Kamada
;	+85 演算子.notb./.notw.を追加
;	+85 浮動小数点数を含む式で単項整数演算子が使えなかった
;
;	Revision 1.6  1999  3/15(Mon) 02:21:03 M.Kamada
;	+83 浮動小数点数を含む式で比較と整数の演算子が使えるようにする
;
;	Revision 1.5  1999  2/28(Sun) 20:08:46 M.Kamada
;	+82 エラーメッセージを日本語化
;
;	Revision 1.4  1999  2/27(Sat) 23:41:11 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.3  1997 10/28(Tue) 16:44:21 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;	+52 .DC.X 0.0+$FFFF9999がC00E00009999FFFF00000000になる不具合
;	+52 浮動小数点数のサイズ指定を可能にする
;	+52 .E+10が浮動小数点実数と判断されない不具合
;
;	Revision 1.2  1997  6/24(Tue) 22:01:51 M.Kamada
;	+34 プレデファインシンボルに対応
;
;	Revision 1.1  1994/02/16  16:25:10  nakamura
;	Initial revision
;
;

;file.s
;----------------------------------------------------------------
;	$Log: file.s,v $
;	Revision 1.4  1999  2/27(Sat) 23:41:32 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.3  1997  9/28(Sun) 19:19:13 M.Kamada
;	+49 includeをカレント→スイッチ→環境変数の順序に変更
;
;	Revision 1.2  1997  9/14(Sun) 16:28:23 M.Kamada
;	+46 error.sを分離
;
;	Revision 1.1  1994/02/15  12:21:10  nakamura
;	Initial revision
;
;

;has.equ
;----------------------------------------------------------------
;
;	Revision 5.2  2023-07-07 12:00:00  M.Kamada
;	+91 -c4のときADDA.W/SUBA.W #$8000,Anが間違って変換される不具合
;	+91 使用法のasをhas060に変更、環境変数の説明に(-iは後ろ)を追加
;
;	Revision 2.1  2023-07-06 12:00:00  M.Kamada
;	+90 環境変数HASの-iをコマンドラインの-iの後に検索する
;
;	Revision 2.0  2016-08-07 12:00:00  M.Kamada
;	+89 060turbo で 060high 1 のとき 16MB を超えるメモリを確保できる
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 1.45  2016-01-01 12:00:00  M.Kamada
;	+88 title_msgの著作権表示をmain.sからhas.equに移動
;	+88 タイトルメッセージが80文字に収まるように著作権表示をコンパクトに
;	+88 PRNファイルの日付をYYYY-MM-DDに変更
;	+88 .offsymにシンボルがないとき.offsetに遷移するとバスエラーが発生する不具合
;	+88 文字列→浮動小数点数変換で正確に表現できる数に誤差が入る不具合
;	+88 ワーニング「整数を単精度浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 1.44  1999 11/17(Wed) 03:59:32 M.Kamada
;	+87 tst (0,a0)+が「オペランドが多すぎます」になる
;
;	Revision 1.43  1999 10/ 8(Fri) 20:06:23 M.Kamada
;	+86 外部参照宣言したシンボルを行頭ラベルとして再定義しようとするとバスエラーになる不具合
;	+86 ilsymerrを細分化
;	+86 ilsizeerrを細分化
;	+86 浮動小数点数を含む式で+符号が使えなかった
;	+86 浮動小数点数を含む式で加算と減算が逆になっていた
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;	+86 '%s に外部参照値は指定できません'
;	+86 foo fequ fooのエラーメッセージがおかしい
;
;	Revision 1.42  1999  6/ 9(Wed) 23:35:36 M.Kamada
;	+85 .offsymでシンボル指定があるとき.even/.quad/.alignをエラーにする
;	+85 演算子!=を有効にする
;	+85 演算子.notb./.notw.を追加
;	+85 .dsの引数が負数のとき.text/.dataセクションではエラー,その他はワーニング
;
;	Revision 1.41  1999  4/28(Wed) 22:21:33 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;	+84 1つのマクロでローカルシンボルを254個以上登録できる
;
;	Revision 1.40  1999  3/16(Tue) 03:32:21 M.Kamada
;	+83 疑似命令のパラメータが間違っているときに多すぎると表示されることがあった
;	+83 浮動小数点数を含む式で比較と整数の演算子が使えるようにする
;	+83 -o./fooのとき.oが補完されなかった
;	+83 エラーメッセージ中の疑似命令の先頭に'.'を付ける
;	+83 数字ローカルラベルを4桁まで対応
;
;	Revision 1.39  1999  3/ 3(Wed) 14:42:55 M.Kamada
;	+82 ColdFireのときCPUSHLがアセンブルできなかった
;	+82 ハッシュテーブルのサイズを2のべき乗にしてdivuを除去
;	+82 doquadマクロ追加
;
;	Revision 1.38  1999  2/27(Sat) 23:41:58 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.37  1999  2/23(Tue) 02:27:47 M.Kamada
;	+80 ColdFire対応
;	+80 lleaマクロ追加
;	+80 .sizeof.と.defined.を追加
;
;	Revision 1.36  1999  2/11(Thu) 02:49:05 M.Kamada
;	+79 .dcの個別のサイズ指定で.w/.l以外を指定したときの挙動がおかしい
;
;	Revision 1.35  1998 11/19(Thu) 22:01:56 M.Kamada
;	+78 -k0と-nを併用すると誤動作するため後から指定した方を有効にする
;
;	Revision 1.34  1998 10/10(Sat) 00:51:53 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 1.33  1998  8/26(Wed) 13:27:30 M.Kamada
;	+76 マクロ内ローカルシンボル@～を2個以上定義すると誤動作する
;
;	Revision 1.32  1998  8/22(Sat) 15:45:47 M.Kamada
;	+75 数字ローカルラベルが定義できなくなっていた
;
;	Revision 1.31  1998  8/20(Thu) 23:18:41 M.Kamada
;	+74 マクロ定義中の@～を自動的にローカル宣言する
;
;	Revision 1.30  1998  8/19(Wed) 00:22:30 M.Kamada
;	+73 .dcのデータに個別にサイズを指定できる
;
;	Revision 1.29  1998  8/18(Tue) 19:35:57 M.Kamada
;	+72 .sizemの第2引数のローカルシンボルにマクロの引数の個数を定義する
;
;	Revision 1.28  1998  8/ 2(Sun) 16:30:34 M.Kamada
;	+71 -1のときFMOVE FPn,<label>がエラーになる
;
;	Revision 1.27  1998  7/29(Wed) 02:33:11 M.Kamada
;	+70 .INSERTの引数に10進数以外の数値を指定したときの不具合を修正
;
;	Revision 1.26  1998  7/14(Tue) 01:20:12 M.Kamada
;	+68 .insertを追加
;	+69 プレデファインシンボル__HAS__と__HAS060__を追加
;
;	Revision 1.25  1998  7/ 5(Sun) 20:43:47 M.Kamada
;	+67 STOP/LPSTOP #<data> で無意味なビットが立っていたらワーニングを出す
;
;	Revision 1.24  1998  5/24(Sun) 19:42:22 M.Kamada
;	+66 ANDI to SR/CCRで未定義ビットをクリアしようとしたらワーニングを出す
;	+66 -y[n]のnを書くと常に-y0になる不具合を修正
;
;	Revision 1.22  1998  4/13(Mon) 04:17:36 M.Kamada
;	+64 move An,USPの行にラベルがあるとI11対策が行われない
;
;	Revision 1.21  1998  3/31(Tue) 02:03:17 M.Kamada
;	+61 MOVE #<imm>,SR/CCR で無意味なビットが立っていたらワーニングを出す
;	+62 MOVEP.L (d,An),Dnの展開にSWAPを使う
;	+63 jmp/jsrを最適化する
;
;	Revision 1.20  1998  3/27(Fri) 06:30:06 M.Kamada
;	+60 .OFFSETセクションでDSの引数に行頭のシンボルを使えないバグ
;
;	Revision 1.19  1998  2/ 8(Sun) 00:59:50 M.Kamada
;	+59 jbra/jbsr/jbccにサイズを指定できる
;
;	Revision 1.18  1998  1/25(Sun) 21:15:12 M.Kamada
;	+58 逆条件ニモニックとelifを追加
;
;	Revision 1.17  1998  1/24(Sat) 17:11:40 M.Kamada
;	+57 バージョン変更
;
;	Revision 1.16  1998  1/ 9(Fri) 22:21:42 M.Kamada
;	+56 バージョン変更
;
;	Revision 1.15  1998  1/ 3(Sat) 22:33:19 M.Kamada
;	+55 バージョン変更
;
;	Revision 1.15  1997 11/23(Sun) 16:00:01 M.Kamada
;	+99 バージョン変更
;		バージョン変更
;
;	Revision 1.14  1997  9/15(Mon) 15:29:52 M.Kamada
;	+45 アセンブル条件追加
;
;	Revision 1.13  1997  9/14(Sun) 02:55:29 M.Kamada
;	+99 バージョン変更
;		バージョン変更
;
;	Revision 1.12  1997  6/24(Tue) 21:56:16 M.Kamada
;	+34 プレデファインシンボルの定義属性SA_PREDEFINEを追加
;
;	Revision 1.11  1997  6/24(Tue) 17:53:21 M.Kamada
;	+99 バージョン変更
;		バージョン変更
;
;	Revision 1.10  1994/07/28  12:43:42  nakamura
;	若干のバグ修正
;
;	Revision 1.9  1994/07/08  16:00:42  nakamura
;	コメントキャラクタ,データサイズ追加
;	link命令の最適化処理追加
;	バグフィックス など
;
;	Revision 1.8  1994/06/09  14:20:04  nakamura
;	バグ修正,シンボルに使用できる文字の拡張('$')。
;
;	Revision 1.7  1994/04/25  14:35:12  nakamura
;	若干のバグ修正
;
;	Revision 1.6  1994/04/09  14:07:36  nakamura
;	若干のバグ修正。
;	jbra/jbsr/jb<cc>命令で絶対ロング以外のアドレッシングを使用可能にした。
;
;	Revision 1.5  1994/03/10  16:15:18  nakamura
;	次の命令へのブランチを削除すると暴走するバグを修正
;
;	Revision 1.4  1994/03/01  13:57:50  nakamura
;	バグフィックスおよび仕様拡張
;
;	Revision 1.3  1994/02/24  12:16:02  nakamura
;	*** empty log message ***
;
;	Revision 1.2  1994/02/20  14:52:20  nakamura
;	*** empty log message ***
;
;	Revision 1.1  1994/02/13  14:32:56  nakamura
;	Initial revision
;
;

;macro.s
;----------------------------------------------------------------
;	$Log: macro.s,v $
;	Revision 2.2  1999 10/ 8(Fri) 21:51:41 M.Kamada
;	+86 EUC対応準備
;
;	Revision 2.1  1999  4/28(Wed) 22:21:13 M.Kamada
;	+84 マクロ内のローカルシンボルが多すぎるとバスエラーが出る不具合を修正
;	+84 1つのマクロでローカルシンボルを254個以上登録できる
;
;	Revision 2.0  1999  3/ 2(Tue) 20:20:23 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 skiphasspcを廃止
;
;	Revision 1.9  1999  2/27(Sat) 23:42:25 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.8  1998  8/26(Wed) 13:26:52 M.Kamada
;	+76 マクロ内ローカルシンボル@～を2個以上定義すると誤動作する
;
;	Revision 1.7  1998  8/21(Fri) 03:14:51 M.Kamada
;	+74 マクロ定義中の@～を自動的にローカル宣言する
;
;	Revision 1.6  1998  8/18(Tue) 20:03:08 M.Kamada
;	+72 .sizemの第2引数のローカルシンボルにマクロの引数の個数を定義する
;
;	Revision 1.5  1998  1/24(Sat) 22:07:35 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 1.4  1997  9/15(Mon) 15:58:48 M.Kamada
;	+46 ST_VALUE=0で最適化
;
;	Revision 1.3  1997  9/15(Mon) 03:58:42 M.Kamada
;	+45 マクロ名$oprcntでパラメータ数,マクロ名$opsizeでサイズ指定を参照,shift新設
;
;	Revision 1.2  1997  6/24(Tue) 22:01:14 M.Kamada
;	+34 プレデファインシンボルに対応
;
;	Revision 1.1  1994/02/13  14:38:38  nakamura
;	Initial revision
;
;

;main.s
;----------------------------------------------------------------
;
;	Revision 4.2  2023-07-07 12:00:00  M.Kamada
;	+91 使用法のasをhas060に変更、環境変数の説明に(-iは後ろ)を追加
;
;	Revision 4.1  2023-07-06 12:00:00  M.Kamada
;	+90 環境変数HASの-iをコマンドラインの-iの後に検索する
;
;	Revision 4.0  2016-08-07 12:00:00  M.Kamada
;	+89 060turbo で 060high 1 のとき 16MB を超えるメモリを確保できる
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 3.9  2016-01-01 12:00:00  M.Kamada
;	+88 title_msgの著作権表示をmain.sからhas.equに移動
;	+88 タイトルメッセージが80文字に収まるように著作権表示をコンパクトに
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 3.8  1999 10/ 8(Fri) 17:33:03 M.Kamada
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;
;	Revision 3.7  1999  3/19(Fri) 16:18:43 M.Kamada
;	+83 -o./fooのとき.oが補完されなかった
;	+83 "致命的な"を除去
;	+83 使用法に環境変数HASの先頭が'*'の場合について記述
;	+83 数字ローカルラベルの最大桁数を4桁まで選択可能
;
;	Revision 3.6  1999  3/ 3(Wed) 14:39:51 M.Kamada
;	+82 ヘルプメッセージのスイッチの並び順を変更
;	+82 Fatal error(s)メッセージを日本語化
;	+82 使用法の -f や -w の表示を変更
;	+82 doeven→doquad
;
;	Revision 3.5  1999  2/27(Sat) 23:42:45 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 3.4  1999  2/25(Thu) 05:02:40 M.Kamada
;	+80 Copyright表示が-98になっていた
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;	+80 setでset以外で定義されたシンボルの上書き禁止
;
;	Revision 3.3  1999  2/13(Sat) 20:35:01 M.Kamada
;	+79 .R形式にするとメモリが極端に不足しているとき直後のブロックを破壊する可能性がある
;	+79 メモリが極端に不足しているときバスエラーが出る可能性がある
;	+79 コマンドラインに'='で始まる単語があるとハングアップする
;	+79 ソースファイル名が2つあるときエラーにする
;
;	Revision 3.2  1998 11/19(Thu) 23:46:21 M.Kamada
;	+78 -k0と-nを併用すると誤動作するため後から指定した方を有効にする
;
;	Revision 3.1  1998  7/14(Tue) 02:43:56 M.Kamada
;	+69 プレデファインシンボル__HAS__と__HAS060__を追加
;	+69 crlf_msgを内蔵
;
;	Revision 3.0  1998  5/24(Sun) 18:28:43 M.Kamada
;	+66 -y[n]のnを書くと常に-y0になる不具合を修正
;
;	Revision 2.9  1998  4/13(Mon) 04:51:03 M.Kamada
;	+64 エラッタの対策を禁止するスイッチを追加
;
;	Revision 2.8  1998  3/31(Tue) 02:09:02 M.Kamada
;	+63 jmp/jsrを最適化する
;
;	Revision 2.7  1998  1/25(Sun) 21:53:31 M.Kamada
;	+58 逆条件ニモニックとelifを追加
;
;	Revision 2.6  1998  1/ 9(Fri) 22:22:27 M.Kamada
;	+56 -f43gを削除
;
;	Revision 2.5  1998  1/ 5(Mon) 01:10:43 M.Kamada
;	+55 -b[n]
;	+55 -1をg2asに合わせる
;	+55 ヘルプの命令を大文字に
;
;	Revision 2.4  1997 10/28(Tue) 02:53:25 M.Kamada
;	+52 -callの直後の1文字が'='でないと無視される不具合
;
;	Revision 2.3  1997 10/13(Mon) 02:12:15 M.Kamada
;	+51 直後へのbsr→pea
;	+52 JMP/JSRを最適化する
;
;	Revision 2.2  1997  9/28(Sun) 19:56:57 M.Kamada
;	+49 -mの後にスペースがあるとエラーになる
;	+49 -cmnemonicを指定するとアドレスエラーが出ることがある
;	+49 -cmnemonicを-c<mnemonic>に,他のスイッチも<>で囲んでみた
;	+49 -up,-dp廃止,代わりに-y[n]を使用
;
;	Revision 2.1  1997  9/23(Tue) 03:32:58 M.Kamada
;	+47 movepとfsccのエミュレーションを拡充
;
;	Revision 2.0  1997  9/15(Mon) 16:01:22 M.Kamada
;	+46 error.sを分離,ST_VALUE=0で最適化
;
;	Revision 1.9  1997  9/17(Wed) 22:36:55 M.Kamada
;	+43 -c0ですべての最適化を禁止する
;	+44 software emulationの命令を展開する
;
;	Revision 1.8  1997  7/ 9(Wed) 02:36:17 M.Kamada
;	+39 -1の挙動を修正
;
;	Revision 1.7  1997  6/26(Thu) 22:09:48 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;	+34 プレデファインシンボル__DATE__,__TIME__に対応
;	+35 CMP.bwl #0,Dn→TST.bwl Dn
;	+36 MOVE.bw #0,Dn→CLR.bw Dn
;	+37 -up,-dpでプレデファインシンボルの禁止,許可
;	+38 CMPI.bwl #0,<ea>→TST.bwl <ea>
;
;	Revision 1.6  1997  3/29(Sat) 21:25:18 M.Kamada
;	+24 MOVEAを最適化する
;	+25 CLRを最適化する
;	+26 ADDA/CMPA/SUBAを最適化する
;	+27 -c4で拡張最適化許可
;	+28 LEAを最適化する
;	+29 ASLを最適化する
;
;	Revision 1.5  1997  3/14(Fri) 02:46:08 M.Kamada
;	+18 サイズ指定のない定数でない絶対ロングを(d,OPC)にする
;
;	Revision 1.4  1997  2/ 2(Sun) 17:03:15 M.Kamada
;	+15 -c1ならばNONULDISPだけセットする
;		-wとlevelの間の空白を認めない
;		-fとf,m,w,pの間の空白を認めない
;
;	Revision 1.3  1996 11/13(Wed) 15:27:30 M.Kamada
;	+00 DEBUG追加
;		テンポラリファイルを削除しない
;	+99 タイトル変更
;	+02 68060対応
;		ヘルプメッセージ変更
;	+05 デフォルトのターゲットMPUを常に68000にする
;		デフォルトのターゲットMPUを常に68000にする
;		ヘルプメッセージ変更
;	+06 環境変数HASをコマンドラインの前に挿入する
;		環境変数HASをコマンドラインの前に挿入する
;		ヘルプメッセージ変更
;
;	Revision 1.2  1994/03/06  03:16:24  nakamura
;	オプションスイッチの追加その他
;
;	Revision 1.1  1994/02/16  15:38:18  nakamura
;	Initial revision
;
;

;misc.s
;----------------------------------------------------------------
;	$Log: misc.s,v $
;	Revision 2.2  2016-01-01 12:00:00  M.Kamada
;	+88 PRNファイルの日付をYYYY-MM-DDに変更
;
;	Revision 2.1  1999 10/ 8(Fri) 21:50:20 M.Kamada
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;
;	Revision 2.0  1999  3/ 2(Tue) 20:19:49 M.Kamada
;	+82 skiphasspcを廃止
;
;	Revision 1.9  1999  2/27(Sat) 23:43:05 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.8  1999  2/24(Wed) 19:44:39 M.Kamada
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 1.7  1998  7/14(Tue) 02:03:58 M.Kamada
;	+69 getfplenが奇数アドレスにあった
;
;	Revision 1.6  1998  5/25(Mon) 01:58:08 M.Kamada
;	+66 encode.sからmisc.s内のgetfplenが届かない
;
;	Revision 1.5  1998  5/14(Thu) 16:03:12 M.Kamada
;	+65 hasでアセンブルできなかった
;
;	Revision 1.4  1997 10/29(Wed) 21:23:10 M.Kamada
;	+52 crlf_msgを内蔵
;
;	Revision 1.3  1997  9/14(Sun) 16:06:33 M.Kamada
;	+45 数値→16進文字列変換を高速化
;
;	Revision 1.2  1997  6/25(Wed) 02:35:32 M.Kamada
;	+34 プレデファインシンボル__DATE__,__TIME__に対応する
;	+37 -up,-dpでプレデファインシンボルの禁止,許可
;
;	Revision 1.1  1994/02/16  15:44:18  nakamura
;	Initial revision
;
;

;objgen.s
;----------------------------------------------------------------
;
;	Revision 3.1  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 3.0  2016-01-01 12:00:00  M.Kamada
;	+88 -fの5番目の引数でPRNファイルのコード部の幅を指定
;
;	Revision 2.9  1999 10/ 8(Fri) 21:52:11 M.Kamada
;	+86 改行コードの変更に対応
;	+86 EUC対応準備
;	+86 '%s に外部参照値は指定できません'
;
;	Revision 2.8  1999  3/ 3(Wed) 14:47:01 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 メッセージを日本語化
;	+82 T_ERRORを$FF00から通常のコードに変更
;	+82 doeven→doquad
;
;	Revision 2.7  1999  2/27(Sat) 23:43:22 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.6  1999  2/25(Thu) 03:37:23 M.Kamada
;	+80 objgen.sのchkdtsizeの参照をbsrlに変更
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.5  1998 10/10(Sat) 02:34:36 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 2.4  1998  1/24(Sat) 17:56:16 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 2.3  1998  1/ 9(Fri) 22:25:16 M.Kamada
;	+56 -f43gを削除
;
;	Revision 2.2  1997 10/13(Mon) 15:40:56 M.Kamada
;	+51 直後へのbsr→pea
;	+52 jmp/jsrを最適化する
;
;	Revision 2.1  1997  9/15(Mon) 16:05:17 M.Kamada
;	+46 ST_VALUE=0で最適化
;
;	Revision 2.0  1997  9/14(Sun) 18:46:52 M.Kamada
;	+45 $opsize,shift
;
;	Revision 1.9  1997  6/25(Wed) 13:39:30 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;	+34 プレデファインシンボルに対応
;
;	Revision 1.8  1996 11/13(Wed) 15:28:40 M.Kamada
;	+04 ??で始まるシンボルを外部定義にしない
;		??で始まるシンボルを外部定義にしない
;
;	Revision 1.7  1994/07/13  14:10:16  nakamura
;	若干のバグフィックス
;
;	Revision 1.6  1994/04/25  14:33:58  nakamura
;	最適化を行わないときに不正なオブジェクトファイルを出力することのあるバグを修正。
;
;	Revision 1.5  1994/04/12  15:09:08  nakamura
;	-m68000/68010で(d,An)が最適化されないことがあるバグを修正。
;
;	Revision 1.4  1994/03/10  15:54:40  nakamura
;	次の命令へのブランチを削除すると暴走するバグを修正
;
;	Revision 1.3  1994/03/06  13:03:06  nakamura
;	68000,68010モードで32bitディスプレースメントを出力してしまうバグをfix
;	.ln疑似命令がひとつもないソースをアセンブルすると異常なSCDコードを出力するバグをfix
;	jbra,jbsr,jbccおよびopcに対する処理を追加
;	'$'が正しいロケーションカウンタ値を指さないことがあるバグをfix
;	エラー発生時にラベルの定義値とロケーションアドレスがずれるバグをfix
;
;	Revision 1.2  1994/02/20  14:25:22  nakamura
;	シンボルテーブルポインタの偶数境界調整を忘れていたので修正。
;
;	Revision 1.1  1994/02/15  12:12:58  nakamura
;	Initial revision
;
;

;opname.s
;----------------------------------------------------------------
;	$Log: opname.s,v $
;	Revision 2.7  1999  2/27(Sat) 23:43:43 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.6  1999  2/24(Wed) 19:40:03 M.Kamada
;	+80 ColdFire対応
;	+80 TPcc,TPNcc表記追加
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.5  1999  2/13(Sat) 20:58:33 M.Kamada
;	+79 rtdでinsignificant bitが出る
;
;	Revision 2.4  1998  7/13(Mon) 21:58:42 M.Kamada
;	+68 .insertを追加
;
;	Revision 2.3  1998  3/31(Tue) 02:41:10 M.Kamada
;	+63 jmp/jsrを最適化する
;
;	Revision 2.2  1998  2/ 8(Sun) 00:17:58 M.Kamada
;	+59 jbra/jbsr/jbccにサイズを指定できる
;
;	Revision 2.1  1998  1/25(Sun) 20:52:08 M.Kamada
;	+58 bccなどの逆条件ニモニックとelifを追加
;
;	Revision 2.0  1998  1/24(Sat) 17:40:33 M.Kamada
;	+57 疑似命令.sizemを追加
;
;	Revision 1.9  1997 10/12(Sun) 23:36:56 M.Kamada
;	+52 jmp/jsrを最適化する
;
;	Revision 1.8  1997  9/14(Sun) 15:26:55 M.Kamada
;	+45 マクロ名$oprcntでパラメータ数,マクロ名$opsizeでサイズ指定を参照,shift新設
;
;	Revision 1.7  1997  5/26(Mon) 03:31:05 M.Kamada
;	+32 lpstop.wを許可
;
;	Revision 1.6  1997  3/29(Sat) 21:23:37 M.Kamada
;	+29 ASLを最適化する
;
;	Revision 1.5  1997  2/27(Thu) 16:12:01 M.Kamada
;	+02 68060対応
;		lpstop/68060/plpaw/plpar追加
;		plpaw/plparはpflushnを利用
;		movep/cas2/cmp2/chk2は68060不可
;	+08 ソフトウェアエミュレーション
;	+16 ptestr/ptestwは68060不可
;	+99 GASコード用意(現在無効)
;		mov/movq/mova/movm
;		byte/short/long
;		movp/movs/movc
;		mov16
;		fmov
;		fsmov
;		fdmov
;		fmovcr/fmovm
;		pmov/pmovfd
;
;	Revision 1.4  1994/07/28  12:40:48  nakamura
;	pflusha,pflushanがオペランドなしになっていなかったので修正した。
;
;	Revision 1.3  1994/07/10  15:41:08  nakamura
;	オペランドなし命令への対応を変更した
;
;	Revision 1.2  1994/03/05  07:28:20  nakamura
;	命令コードjbra,jbsr,jbccの追加
;
;	Revision 1.1  1994/02/13  13:33:48  nakamura
;	Initial revision
;
;

;optimize.s
;----------------------------------------------------------------
;
;	Revision 2.6  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 2.5  1999  3/ 2(Tue) 17:04:08 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 T_ERRORを$FF00から通常のコードに変更
;
;	Revision 2.4  1999  2/27(Sat) 23:44:02 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 2.3  1999  2/24(Wed) 22:03:04 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 2.2  1998 10/10(Sat) 01:53:40 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 2.1  1997 10/13(Mon) 15:36:35 M.Kamada
;	+51 直後へのbsr→pea
;	+52 jmp/jsrを最適化する
;
;	Revision 2.0  1997 10/12(Sun) 18:50:14 M.Kamada
;	+50 fadd.d (sp),fp0;bra @f;nop;@@:のbraが最適化されないバグを修正
;	+51 bra @f;.rept 30;fadd.x fp0,fp0;.endm;@@:のbraが最適化されないバグを修正
;
;	Revision 1.9  1997  9/14(Sun) 16:30:23 M.Kamada
;	+46 error.sを分離
;
;	Revision 1.8  1997  6/25(Wed) 13:37:15 M.Kamada
;	+33 プレデファインシンボルCPUに対応する
;	+34 プレデファインシンボルに対応
;
;	Revision 1.7  1997  2/ 1(Sat) 23:31:32 M.Kamada
;	+13 bdpcの最適化処理のバグを修正
;
;	Revision 1.6  1996 12/15(Sun) 01:30:51 M.Kamada
;	+07 F43G対策
;		削除すべきNOPの処理を追加した
;
;	Revision 1.5  1994/07/12  14:58:40  nakamura
;	link命令に対する最適化処理を追加した
;
;	Revision 1.4  1994/03/06  11:31:16  nakamura
;	jbra,jbsr,jbccおよびopcに対する最適化処理の追加
;
;	Revision 1.3  1994/02/24  12:13:12  nakamura
;	32KB以上後方へのブランチの最適化に失敗するのを修正した。
;
;	Revision 1.2  1994/02/20  13:52:18  nakamura
;	次の命令へのbsrの最適化に失敗するバグを修正。
;
;	Revision 1.1  1994/02/16  15:33:32  nakamura
;	Initial revision
;
;

;pseudo.s
;---------------------------------------------------------------
;
;	Revision 2.1  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 2.0  2016-01-01 12:00:00  M.Kamada
;	+88 .offsymにシンボルがないとき.offsetに遷移するとバスエラーが発生する不具合
;	+88 ワーニング「整数を単精度浮動小数点数の内部表現と見なします」を追加
;	+88 エラー「浮動小数点数の内部表現の長さが合いません」を追加
;
;	Revision 1.21  1999 10/ 8(Fri) 21:00:37 M.Kamada
;	+86 ilsymerrを細分化
;	+86 '%s に外部参照値は指定できません'
;	+86 foo fequ fooのエラーメッセージがおかしい
;
;	Revision 1.20  1999  6/ 9(Wed) 23:37:40 M.Kamada
;	+85 .offsymでシンボル指定があるとき.even/.quad/.alignをエラーにする
;	+85 .dsの引数が負数のとき.text/.dataセクションではエラー,その他はワーニング
;
;	Revision 1.19  1999  3/15(Mon) 18:20:37 M.Kamada
;	+83 疑似命令のパラメータが間違っているときに多すぎると表示されることがあった
;	+83 .cpuの引数が間違っているとき多すぎるほうのエラーが優先していた
;
;	Revision 1.18  1999  3/ 3(Wed) 15:04:45 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 疑似命令のパラメータが多すぎる場合のエラーチェックを強化
;	+82 doeven→doquad
;	+82 F43GRECのサイズを14→16バイト
;
;	Revision 1.17  1999  2/27(Sat) 23:44:21 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.16  1999  2/25(Thu) 05:50:36 M.Kamada
;	+80 ColdFire対応
;	+80 .dcで文字列を連結して記述できる
;	+80 .offsym <初期値>,<シンボル>
;	+80 setでset以外で定義されたシンボルの上書き禁止
;	+80 +79の.DCのサイズの個別指定の修正が不十分だった
;
;	Revision 1.15  1999  2/11(Thu) 02:50:24 M.Kamada
;	+79 .dcの個別のサイズ指定で.w/.l以外を指定したときの挙動がおかしい
;
;	Revision 1.14  1998 10/10(Sat) 01:50:32 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 1.13  1998  8/19(Wed) 00:19:52 M.Kamada
;	+73 .dcのデータに個別にサイズを指定できる
;
;	Revision 1.12  1998  7/29(Wed) 02:32:33 M.Kamada
;	+70 .INSERTの引数に10進数以外の数値を指定したときの不具合を修正
;
;	Revision 1.11  1998  7/14(Tue) 00:19:35 M.Kamada
;	+68 .insertを追加
;
;	Revision 1.10  1998  5/14(Thu) 15:59:24 M.Kamada
;	+65 .endの右に注釈が書けなかった
;
;	Revision 1.9  1998  4/13(Mon) 04:47:07 M.Kamada
;	+64 エラッタの対策を禁止するスイッチを追加
;
;	Revision 1.8  1998  3/27(Fri) 06:30:55 M.Kamada
;	+60 .OFFSETセクションでDSの引数に行頭のシンボルを使えないバグ
;
;	Revision 1.7  1997 10/22(Wed) 02:52:55 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;
;	Revision 1.6  1997 10/12(Sun) 16:47:22 M.Kamada
;	+51 .align 1がエラーにならないバグ
;	+51 .OFFSETセクションで.ALIGNを使った場合でも最大アライン値が更新されるバグ
;
;	Revision 1.5  1997  9/15(Mon) 16:36:55 M.Kamada
;	+46 ST_VALUE=0,SZ_BYTE=0で最適化
;
;	Revision 1.4  1997  6/25(Wed) 00:27:23 M.Kamada
;	+33 プレデファインシンボルCPUに対応
;	+34 プレデファインシンボルに対応
;
;	Revision 1.3  1996 12/12(Thu) 16:59:39 M.Kamada
;	+02 68060対応
;		cpuに68060を追加
;		68060追加
;	+03 dcb/dsなどのオペランドの式に文字列を含んでいてもよいことにした
;
;	Revision 1.2  1994/03/06  02:54:56  nakamura
;	68000,68010モードでの-eスイッチの扱いを少し変更
;
;	Revision 1.1  1994/02/13  13:33:28  nakamura
;	Initial revision
;
;

;register.equ
;----------------------------------------------------------------
;	$Log: register.equ,v $
;	Revision 1.6  1999  2/27(Sat) 23:44:40 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.5  1999  2/21(Sun) 00:44:30 M.Kamada
;	+80 ColdFire対応
;
;	Revision 1.4  1996 11/13(Wed) 15:33:01 M.Kamada
;	BUSCRとPCRを追加
;
;	Revision 1.3  1994/07/10  11:03:02  nakamura
;	データサイズコード'.q'の追加
;
;	Revision 1.2  1994/03/05  05:15:10  nakamura
;	新設疑似レジスタに対する定義値の追加
;
;	Revision 1.1  1994/02/13  14:30:40  nakamura
;	Initial revision
;
;

;regname.s
;----------------------------------------------------------------
;	$Log: regname.s,v $
;	Revision 1.7  1999  6/ 9(Wed) 21:05:13 M.Kamada
;	+85 演算子.notb./.notw.を追加
;
;	Revision 1.6  1999  2/28(Sun) 00:31:06 M.Kamada
;	+82 ColdFireのときCPUSHLがアセンブルできなかった
;
;	Revision 1.5  1999  2/27(Sat) 23:44:58 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.4  1999  2/23(Tue) 02:26:27 M.Kamada
;	+80 ColdFire対応
;	+80 .sizeof.と.defined.を追加
;
;	Revision 1.3  1996 11/13(Wed) 15:33:45 M.Kamada
;	+02 68060対応
;		BUSCRとPCRを追加
;
;	Revision 1.2  1994/03/05  12:20:52  nakamura
;	レジスタ名zd0～zd7,za0～za7,opcを追加
;
;	Revision 1.1  1994/02/13  14:17:46  nakamura
;	Initial revision
;
;

;symbol.equ
;----------------------------------------------------------------
;	$Log: symbol.equ,v $
;	Revision 1.5  1999  3/ 3(Wed) 14:36:30 M.Kamada
;	+82 SYM_VALUEをSYM_FIRSTの後ろに移動してロングワード境界に
;	+82 SYM_FVPTRをロングワード境界に
;
;	Revision 1.4  1999  2/27(Sat) 23:45:17 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.3  1999  2/25(Thu) 04:35:44 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;	+80 setでset以外で定義されたシンボルの上書き禁止
;
;	Revision 1.2  1994/07/10  12:45:50  nakamura
;	オペランドなし命令への対応を変更した
;
;	Revision 1.1  1994/02/06  05:36:20  nakamura
;	Initial revision
;
;

;symbol.s
;----------------------------------------------------------------
;	$Log: symbol.s,v $
;	Revision 1.8  1999 10/ 8(Fri) 21:49:32 M.Kamada
;	+86 EUC対応準備
;
;	Revision 1.7  1999  3/16(Tue) 03:40:18 M.Kamada
;	+83 数字ローカルラベルを4桁まで対応
;
;	Revision 1.6  1999  3/ 3(Wed) 17:36:25 M.Kamada
;	+82 レジスタ名シンボルが奇数番地から始まっていたので修正
;	+82 ハッシュテーブルのサイズを2のべき乗にしてdivuを除去
;	+82 doeven→doquad
;
;	Revision 1.5  1999  2/27(Sat) 23:45:36 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.4  1999  2/20(Sat) 17:37:32 M.Kamada
;	+80 ColdFire対応
;
;	Revision 1.3  1994/07/10  12:46:16  nakamura
;	オペランドなし命令への対応の変更
;
;	Revision 1.2  1994/04/05  13:07:20  nakamura
;	マクロ名に2バイト文字を使用したマクロの展開ができないバグを修正した。
;
;	Revision 1.1  1994/02/13  14:18:06  nakamura
;	Initial revision
;
;

;tmpcode.equ
;----------------------------------------------------------------
;
;	Revision 2.2  2016-08-07 12:00:00  M.Kamada
;	+89 BRA.L の後に .CPU 68000 があるとアセンブルできない不具合
;
;	Revision 2.1  1999  3/ 2(Tue) 16:53:11 M.Kamada
;	+82 エラーメッセージを日本語化
;	+82 T_ERRORを$FF00から通常のコードに変更
;
;	Revision 2.0  1999  2/27(Sat) 23:45:53 M.Kamada
;	+81 ソースリストのフォーマットを変更(実行ファイルは+80とまったく同じ)
;
;	Revision 1.9  1999  2/24(Wed) 21:01:04 M.Kamada
;	+80 ColdFire対応
;	+80 .offsym <初期値>,<シンボル>
;
;	Revision 1.8  1998 10/10(Sat) 01:51:49 M.Kamada
;	+77 -pのとき.INSERTで1度に256バイト以上読み出すと誤動作する
;
;	Revision 1.7  1997 10/21(Tue) 16:29:08 M.Kamada
;	+52 PMOVE.D #imm,CRPが正しくアセンブルできない不具合
;
;	Revision 1.6  1997 10/12(Sun) 23:31:09 M.Kamada
;	+52 jmp/jsrを最適化する
;
;	Revision 1.5  1997  9/15(Mon) 15:27:28 M.Kamada
;	+45 shift
;
;	Revision 1.4  1996 12/15(Sun) 01:12:11 M.Kamada
;	+07 F43G対策
;		削除すべきNOPのテンポラリコードを追加
;
;	Revision 1.3  1994/07/11  15:20:16  nakamura
;	link命令の最適化用テンポラリコード追加
;
;	Revision 1.2  1994/03/05  14:09:30  nakamura
;	仕様拡張に伴うテンポラリコードの追加
;
;	Revision 1.1  1994/02/13  14:32:34  nakamura
;	Initial revision
;
;

;work.s
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
