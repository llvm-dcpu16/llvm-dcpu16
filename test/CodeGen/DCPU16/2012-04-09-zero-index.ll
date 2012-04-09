; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i1:8:8-i8:8:8-i16:16:16-i32:16:16"
target triple = "dcpu16"

define i16 @first(i16* %a) nounwind {
entry:
  %a.addr = alloca i16*, align 2
  store i16* %a, i16** %a.addr, align 2
  %0 = load i16** %a.addr, align 2
  %arrayidx = getelementptr inbounds i16* %0, i16 0
  %1 = load i16* %arrayidx, align 2
  ret i16 %1
}

; CHECK: :first
; CHECK: SET [{{.}}], {{.}}
; CHECK: SET {{.}}, [{{.}}]
