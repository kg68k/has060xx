# HAS060X.X
HAS060.X version 3.09+91の改造版です。  
無保証につき各自の責任で使用して下さい。


## Known bugs
* HAS060.X - アセンブラ - プログラミング - ソフトウェアライブラリ - X68000 LIBRARY &gt;
  [既知の不具合](http://retropc.net/x68000/software/develop/as/has060/knownbug.htm)
* [KNOWNBUGS.md](KNOWNBUGS.md)


## Build
PCやネット上での取り扱いを用意にするために、src/内のファイルはUTF-8で記述されています。
X68000上でビルドする際には、UTF-8からShift_JISへの変換が必要です。

### u8tosjを使用する方法

あらかじめ、[u8tosj](https://github.com/kg68k/u8tosj)をビルドしてインストールしておいてください。

トップディレクトリで`make`を実行してください。以下の処理が行われます。
1. build/ディレクトリの作成。
2. src/内の各ファイルをShift_JISに変換してbuild/へ保存。

次に、カレントディレクトリをbuild/に変更し、`make`を実行してください。
実行ファイルが作成されます。

### u8tosjを使用しない方法

ファイルを適当なツールで適宜Shift_JISに変換してから`make`を実行してください。
UTF-8のままでは正しくビルドできませんので注意してください。


## License

改造元であるHAS060.Xの著作権については、HAS060.XのREADME.DOCの通りです。

> ━＜ 著作権について ＞━━━━━━━━━━━━━━━━━━━━━━━━━
> 
> 　基本的な部分の著作権は、HAS.X v3.09 の原作者の中村祐一氏にあります。
> 
> 　改造部分の著作権は、改造者（M.Kamada）にあります。

HAS060X.Xの改造部分の著作権は、改造者(TcbnErik)にあります。

配布規定についてはHAS060.Xに準じるものとします。


## Author
TcbnErik / https://github.com/kg68k/has060xx
