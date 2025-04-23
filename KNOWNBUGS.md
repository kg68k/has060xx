# 既知の不具合

## ベースディスプレースメントにサイズを指定しないと「オフセットが範囲外です」になることがある
```
.cpu 68020
b:
  lea (a,pc,d0.l),a0
  .ds.b 32758
  lea (b,pc,d0.l),a0
a:
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

## .ifなどの条件不成立ブロック内で.commentが機能しない
```
.if 0  ;.if 1ならOK
  .comment end_of_comment
    .if
  end_of_comment
.endif
```

## .elseの後に.elseがあってもエラーにならない
```
.if 1
  moveq #1,d0
.else
  moveq #2,d0
.else
  moveq #3,d0
.endif
```

## .elseの後に.elseifがあってもエラーにならないことがある
```
.if 0
  moveq #1,d0
.else
  moveq #2,d0
.elseif 1
  moveq #3,d0
.endif
```
.elseが不成立の場合は直後の.elseifがエラーになるが、.elseが成立の場合はエラーにならない。

