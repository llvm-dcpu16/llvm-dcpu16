; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @am1(i16* %a, i16 %b) nounwind {
	store i16 %b, i16* %a
	ret void
}
; CHECK: :am1
; CHECK:		SET     [A], B

@foo = external global i16

define void @am2(i16 %a) nounwind {
	store volatile i16 %a, i16* inttoptr(i16 32 to i16*)
	ret void
}
; CHECK: :am2
; CHECK:		SET     [0x20], A

define void @am3(i16* nocapture %p, i16 %a) nounwind readonly {
	%1 = getelementptr inbounds i16* %p, i16 2
	store i16 %a, i16* %1
	ret void
}
; CHECK: :am3
; CHECK:		SET     [A+0x2], B


