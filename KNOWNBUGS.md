# 既知の不具合

## ベースディスプレースメントにサイズを指定しないと「オフセットが範囲外です」になることがある
```
.cpu 68020
b:
  lea (a,pc,d0.l),a0
  .dcb.w 32758/2,$4e71
  lea (b,pc,d0.l),a0
a:
  .dc $ff00
```
あるいは
```
.cpu 68020
  moveq #0,d0
  tst.b (foo,pc,d0.l)  ;Error: オフセットが範囲外です
  tst.b (bar,pc,d0.l)

; tst.b (foo,pc,d0.l)  ;barに.lをつければOK
; tst.b (bar.l,pc,d0.l)

; tst.b (foo+1,pc,d0.l)  ;foo+1またはfoo-1にしてもOK
; tst.b (bar,pc,d0.l)
  .dc $ff00

  .ds.b 32755
foo: .ds.b 9
bar: .ds.b 1
.end
```

eamode.s `geteapm_idx5:`の`bpl geteapm_idx9`を`bpl geteapm_bd`に変えると
エラーは出なくなるが、最適化の際に`(bd,pc,idx) ;bd=0`から`(d8,pc,idx)`への格下げが
行われないためアセンブル結果が異なる。
