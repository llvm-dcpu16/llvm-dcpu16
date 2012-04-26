; RUN: llc -O1 < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @func2(i16 %n) nounwind {
entry:
  ret i16 %n
}

define i16 @func() nounwind readnone {
entry:
  %call = tail call i16 @func2(i16 5)
  %call1 = tail call i16 @func2(i16 6)
  %add = add i16 %call1, %call
  ret i16 %add
}

; CHECK: :func
; CHECK: SET	A, 0x5
; CHECK: JSR	func2
; CHECK: SET	X, A
; CHECK: SET	A, 0x6
; CHECK: JSR	func2
; CHECK: ADD	A, X