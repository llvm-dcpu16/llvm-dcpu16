; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @am1(i16 %x, i16* %a) nounwind {
	%1 = load i16* %a
	%2 = or i16 %1,%x
	ret i16 %2
}
; CHECK: :am1
; CHECK:		BOR     A, [B]

@foo = external global i16

define i16 @am2(i16 %x) nounwind {
	%1 = load volatile i16* inttoptr(i16 32 to i16*)
	%2 = or i16 %1,%x
	ret i16 %2
}
; CHECK: :am2
; CHECK:		BOR     A, [0x20]

define i16 @am3(i16 %x, i16* %a) nounwind {
	%1 = getelementptr i16* %a, i16 2
	%2 = load i16* %1
	%3 = or i16 %2,%x
	ret i16 %3
}
; CHECK: :am3
; CHECK:		BOR     A, [B+0x2]
