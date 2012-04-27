; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @sccweqand(i16 %a, i16 %b) nounwind {
	%t1 = and i16 %a, %b
	%t2 = icmp eq i16 %t1, 0
	%t3 = zext i1 %t2 to i16
	ret i16 %t3
}
; CHECK: sccweqand
; CHECK:	AND A, B
; CHECK:	SET B, 0x0
; CHECK:	IFE A, 0x0
; CHECK:	SET B, 0x1
; CHECK:	SET A, B

define i16 @sccwneand(i16 %a, i16 %b) nounwind {
	%t1 = and i16 %a, %b
	%t2 = icmp ne i16 %t1, 0
	%t3 = zext i1 %t2 to i16
	ret i16 %t3
}
; CHECK: sccwneand
; CHECK:        AND     A, B
; CHECK:        SET     B, 0x0
; CHECK:        IFN     A, 0x0
; CHECK:        SET     B, 0x1
; CHECK:        SET     A, B

define i16 @sccwne(i16 %a, i16 %b) nounwind {
	%t1 = icmp ne i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwne
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFN     C, B
; CHECK:        SET     A, 0x1

define i16 @sccweq(i16 %a, i16 %b) nounwind {
	%t1 = icmp eq i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccweq
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFE     C, B
; CHECK:        SET     A, 0x1

define i16 @sccwugt(i16 %a, i16 %b) nounwind {
	%t1 = icmp ugt i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwugt
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFG     C, B
; CHECK:        SET     A, 0x1

define i16 @sccwuge(i16 %a, i16 %b) nounwind {
	%t1 = icmp uge i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwuge
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x1
; CHECK:        IFL     C, B
; CHECK:        SET     A, 0x0

define i16 @sccwult(i16 %a, i16 %b) nounwind {
	%t1 = icmp ult i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwult
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFL     C, B
; CHECK:        SET     A, 0x1

define i16 @sccwule(i16 %a, i16 %b) nounwind {
	%t1 = icmp ule i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwule
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x1
; CHECK:        IFG     C, B
; CHECK:        SET     A, 0x0

define i16 @sccwsgt(i16 %a, i16 %b) nounwind {
	%t1 = icmp sgt i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwsgt
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFA     C, B
; CHECK:        SET     A, 0x1

define i16 @sccwsge(i16 %a, i16 %b) nounwind {
	%t1 = icmp sge i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwsge
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x1
; CHECK:        IFU     C, B
; CHECK:        SET     A, 0x0

define i16 @sccwslt(i16 %a, i16 %b) nounwind {
	%t1 = icmp slt i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwslt
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x0
; CHECK:        IFU     C, B
; CHECK:        SET     A, 0x1

define i16 @sccwsle(i16 %a, i16 %b) nounwind {
	%t1 = icmp sle i16 %a, %b
	%t2 = zext i1 %t1 to i16
	ret i16 %t2
}
; CHECK:sccwsle
; CHECK:        SET     C, A
; CHECK:        SET     A, 0x1
; CHECK:        IFA     C, B
; CHECK:        SET     A, 0x0
