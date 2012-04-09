; RUN: llc < %s -march=dcpu16 | not grep {UNREACHABLE|ERROR}
target datalayout = "e-p:16:16:16-i1:8:8-i8:8:8-i16:16:16-i32:16:16"
target triple = "dcpu16"

define i16 @hailstone() nounwind {
entry:
  %retval = alloca i16, align 2
  %x = alloca i16, align 2
  store i16 0, i16* %x, align 2
  %0 = load i16* %x, align 2
  %and = and i16 %0, 1
  %tobool = icmp ne i16 %and, 0
  br i1 %tobool, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  store i16 0, i16* %retval
  br label %return

if.else:                                          ; preds = %entry
  store i16 1, i16* %retval
  br label %return

return:                                           ; preds = %if.else, %if.then
  %1 = load i16* %retval
  ret i16 %1
}
