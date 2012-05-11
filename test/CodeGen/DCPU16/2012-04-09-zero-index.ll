; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
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
; CHECK: SET PEEK, {{.}}
; CHECK: SET {{.}}, [{{.}}]
