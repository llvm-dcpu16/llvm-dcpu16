; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @am1(i16* %a) nounwind {
	%1 = load i16* %a
	ret i16 %1
}
; CHECK: :am1
; CHECK:		SET     A, [A]

define i16 @am2() nounwind {
	%1 = load volatile i16* inttoptr(i16 32 to i16*)
	ret i16 %1
}
; CHECK: :am2
; CHECK:		SET     A, [0x20]

define i16 @am3(i16* %a) nounwind {
	%1 = getelementptr i16* %a, i16 2
	%2 = load i16* %1
	ret i16 %2
}
; CHECK: :am3
; CHECK:		SET     A, [A+0x2]
