//===-- DCPU16InstrInfo.td - DCPU16 Instruction defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the DCPU16 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "DCPU16InstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===----------------------------------------------------------------------===//
// Type Profiles.
//===----------------------------------------------------------------------===//
def SDT_DCPU16Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_DCPU16CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_DCPU16CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_DCPU16Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_DCPU16BrCC         : SDTypeProfile<0, 4, [SDTCisVT<0, i16>,
                                                  SDTCisSameAs<1, 0>,
                                                  SDTCisSameAs<2, 1>,
                                                  SDTCisVT<3, OtherVT>]>;
def SDT_DCPU16SelectCC     : SDTypeProfile<1, 5, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>,
                                                  SDTCisSameAs<2, 3>,
                                                  SDTCisSameAs<3, 4>,
                                                  SDTCisSameAs<4, 5>,
                                                  SDTCisVT<5, i16>]>;
def SDT_DCPU16BinOp        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>,
                                                  SDTCisI16<2>]>;

//===----------------------------------------------------------------------===//
// DCPU16 Specific Node Definitions.
//===----------------------------------------------------------------------===//
def DCPU16retflag  : SDNode<"DCPU16ISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;
def DCPU16retiflag : SDNode<"DCPU16ISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;

def DCPU16call     : SDNode<"DCPU16ISD::CALL", SDT_DCPU16Call,
                       [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def DCPU16callseq_start :
                     SDNode<"ISD::CALLSEQ_START", SDT_DCPU16CallSeqStart,
                       [SDNPHasChain, SDNPOutGlue]>;
def DCPU16callseq_end :
                     SDNode<"ISD::CALLSEQ_END",   SDT_DCPU16CallSeqEnd,
                       [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def DCPU16Wrapper  : SDNode<"DCPU16ISD::Wrapper", SDT_DCPU16Wrapper>;
def DCPU16brcc     : SDNode<"DCPU16ISD::BR_CC", SDT_DCPU16BrCC,
                       [SDNPHasChain]>;
def DCPU16selectcc : SDNode<"DCPU16ISD::SELECT_CC", SDT_DCPU16SelectCC, []>;
def DCPU16smul     : SDNode<"DCPU16ISD::SMUL", SDT_DCPU16BinOp,
                       [SDNPHasChain, SDNPOutGlue]>;
def DCPU16umul     : SDNode<"DCPU16ISD::UMUL", SDT_DCPU16BinOp,
                       [SDNPHasChain, SDNPOutGlue]>;

//===----------------------------------------------------------------------===//
// DCPU16 Operand Definitions.
//===----------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
}

// Operand for printing out a condition code.
def cc : Operand<i16> {
  let PrintMethod = "printCCOperand";
}

//===----------------------------------------------------------------------===//
// DCPU16 Complex Pattern Definitions.
//===----------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===----------------------------------------------------------------------===//
// Pattern Fragments
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//
// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber EX.
let Defs = [SP, EX], Uses = [SP] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(DCPU16callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(DCPU16callseq_end timm:$amt1, timm:$amt2)]>;
}

// $dst _can_ be $falseV
let Constraints = "@earlyclobber $dst" in {
  // TODO: add more combinations, in particular memory access
  def Select16rrrr : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, GEXR16:$lhs, GEXR16:$rhs, GEXR16:$trueV, GEXR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, GEXR16:$lhs, GEXR16:$rhs, GEXR16:$trueV, GEXR16:$falseV))]>;
  def Select16rirr : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, GEXR16:$lhs, i16imm:$rhs, GEXR16:$trueV, GEXR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, GEXR16:$lhs, imm:$rhs, GEXR16:$trueV, GEXR16:$falseV))]>;
  def Select16irrr : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, i16imm:$lhs, GEXR16:$rhs, GEXR16:$trueV, GEXR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, imm:$lhs, GEXR16:$rhs, GEXR16:$trueV, GEXR16:$falseV))]>;

  def Select16rrii : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, GEXR16:$lhs, GEXR16:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, GEXR16:$lhs, GEXR16:$rhs, imm:$trueV, imm:$falseV))]>;
  def Select16riii : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, GEXR16:$lhs, i16imm:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, GEXR16:$lhs, imm:$rhs, imm:$trueV, imm:$falseV))]>;
  def Select16irii : Pseudo<(outs GEXR16:$dst),
                  (ins cc:$cc, i16imm:$lhs, GEXR16:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GEXR16:$dst,
                    (DCPU16selectcc imm:$cc, imm:$lhs, GEXR16:$rhs, imm:$trueV, imm:$falseV))]>;
}

let neverHasSideEffects = 1 in
def NOP : Pseudo<(outs), (ins), "nop", []>;

//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

// FIXME: Provide proper encoding!
let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  def RET  : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "SET\t{PC, POP}",  [(DCPU16retflag)]>;
  def RETI : II16r<0x0, (outs), (ins), "RFI 0", [(DCPU16retiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// FIXME: expand opcode & cond field for branches!

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0, 0, (outs), (ins jmptarget:$dst),
                   "SET\t{PC, $dst}",
                   [(br bb:$dst)]>;
  let isIndirectBranch = 1 in {
    // Long branches
    def Bi  : I16ri<0, (outs), (ins i16imm:$brdst),
                    "br\t$brdst",
                    [(brind tblockaddress:$brdst)]>;
    def Br  : I16rr<0, (outs), (ins GEXR16:$brdst),
                    "SET\t{PC, $brdst}",
                    [(brind GEXR16:$brdst)]>;
    def Bm  : I16rm<0, (outs), (ins memsrc:$brdst),
                    "SET\t{PC, $brdst}",
                    [(brind (load addr:$brdst))]>;
  }
}

// Conditional branches
// TODO: add memory versions
def BR_CCrr : CJForm<0, 0,
   (outs), (ins cc:$cc, GEXR16:$lhs, GEXR16:$rhs, jmptarget:$dst),
   "$cc\t{$lhs, $rhs}\n"
   "\tSET\t{PC, $dst}",
   [(DCPU16brcc imm:$cc, GEXR16:$lhs, GEXR16:$rhs, bb:$dst)]>;
def BR_CCri : CJForm<0, 0,
   (outs), (ins cc:$cc, GEXR16:$lhs, i16imm:$rhs, jmptarget:$dst),
   "$cc\t{$lhs, $rhs}\n"
   "\tSET\t{PC, $dst}",
   [(DCPU16brcc imm:$cc, GEXR16:$lhs, imm:$rhs, bb:$dst)]>;
def BR_CCir : CJForm<0, 0,
   (outs), (ins cc:$cc, i16imm:$lhs, GEXR16:$rhs, jmptarget:$dst),
   "$cc\t{$lhs, $rhs}\n"
   "\tSET\t{PC, $dst}",
   [(DCPU16brcc imm:$cc, imm:$lhs, GEXR16:$rhs, bb:$dst)]>;
def BR_CCii : CJForm<0, 0,
   (outs), (ins cc:$cc, i16imm:$lhs, i16imm:$rhs, jmptarget:$dst),
   "$cc\t{$lhs, $rhs}\n"
   "\tSET\t{PC, $dst}",
   [(DCPU16brcc imm:$cc, imm:$lhs, imm:$rhs, bb:$dst)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. SP is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [EX],
      Uses = [SP] in {
    def CALLi     : II16i<0x0,
                          (outs), (ins i16imm:$dst, variable_ops),
                          "JSR\t$dst", [(DCPU16call imm:$dst)]>;
    def CALLr     : II16r<0x0,
                          (outs), (ins GEXR16:$dst, variable_ops),
                          "JSR\t$dst", [(DCPU16call GEXR16:$dst)]>;
    def CALLm     : II16m<0x0,
                          (outs), (ins memsrc:$dst, variable_ops),
                          "JSR\t${dst:mem}", [(DCPU16call (load addr:$dst))]>;
  }


//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//
let Defs = [SP], Uses = [SP], neverHasSideEffects=1 in {
let mayLoad = 1 in
def POP16r   : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                       (outs GEXR16:$reg), (ins), "SET\t{$reg, POP}", []>;

let mayStore = 1 in
def PUSH16r  : II16r<0x0,
                     (outs), (ins GEXR16:$reg), "SET\t{PUSH, $reg}",[]>;
}

//===----------------------------------------------------------------------===//
// Move Instructions

// FIXME: Provide proper encoding!
let neverHasSideEffects = 1 in {
def MOV16rr : I16rr<0x0,
                    (outs GEXR16:$dst), (ins GEXR16:$src),
                    "SET\t{$dst, $src}",
                    []>;
}

// FIXME: Provide proper encoding!
let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def MOV16ri : I16ri<0x0,
                    (outs GEXR16:$dst), (ins i16imm:$src),
                    "SET\t{$dst, $src}",
                    [(set GEXR16:$dst, imm:$src)]>;
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV16rm : I16rm<0x0,
                    (outs GEXR16:$dst), (ins memsrc:$src),
                    "SET\t{$dst, $src}",
                    [(set GEXR16:$dst, (load addr:$src))]>;
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV16rmi8 : I16rm<0x0,
                    (outs GEXR16:$dst), (ins memsrc:$src),
                    "SET\t{$dst, $src}",
                    [(set GEXR16:$dst, (zextloadi8 addr:$src))]>;
}

def MOV16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "SET\t{$dst, $src}",
                    [(store (i16 imm:$src), addr:$dst)]>;

def MOV16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GEXR16:$src),
                    "SET\t{$dst, $src}",
                    [(store GEXR16:$src, addr:$dst)]>;

def MOV16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "SET\t{$dst, $src}",
                    [(store (i16 (load addr:$src)), addr:$dst)]>;

//===----------------------------------------------------------------------===//
// Multiclasses for arithmetic instructions

multiclass BASIC_RR_IS_COM<bits<4> OpVal, string OpcStr, SDNode OpNode> {
  let Constraints = "$src = $dst", isCommutable = 1 in {
  def rr: I16rr<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, GEXR16:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, GEXR16:$src2)),
                     (implicit EX)]>;
  }
}

multiclass BASIC_RR_NON_COM<bits<4> OpVal, string OpcStr, SDNode OpNode> {
  let Constraints = "$src = $dst" in {
  def rr: I16rr<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, GEXR16:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, GEXR16:$src2)),
                     (implicit EX)]>;
  }
}

multiclass BASIC_NORMAL<bits<4> OpVal, string OpcStr, SDNode OpNode> {
  let Constraints = "$src = $dst" in {
  def rm: I16rm<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, (load addr:$src2))),
                     (implicit EX)]>;
  def ri: I16ri<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, imm:$src2)),
                     (implicit EX)]>;
  }
  let Constraints = "" in {
  def mr: I16mr<OpVal,
                    (outs), (ins memdst:$dst, GEXR16:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst), GEXR16:$src), addr:$dst),
                     (implicit EX)]>;
  def mi: I16mi<OpVal,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit EX)]>;
  def mm: I16mm<OpVal,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst),
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit EX)]>;
  }
  
  // FIXME! Wrong zero extend
  let Constraints = "$src = $dst", canFoldAsLoad = 1, isReMaterializable = 1 in {
  def rmi8 : I16rm<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
					OpcStr#"\t{$dst, $src}",
                    [(set GR16:$dst, (OpNode GR16:$src, (zextloadi8 addr:$src2))),
                     (implicit EX)]>;
  }  
}

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

let Defs = [EX] in {
  defm ADD16   : BASIC_RR_IS_COM <0x0, "ADD", add>,  BASIC_NORMAL<0x0, "ADD", add>;
  defm AND16   : BASIC_RR_IS_COM <0x0, "AND", and>,  BASIC_NORMAL<0x0, "AND", and>;
  defm OR16    : BASIC_RR_IS_COM <0x0, "BOR", or>,   BASIC_NORMAL<0x0, "BOR", or>;
  defm XOR16   : BASIC_RR_IS_COM <0x0, "XOR", xor>,  BASIC_NORMAL<0x0, "XOR", xor>;
  defm SUB16   : BASIC_RR_NON_COM<0x0, "SUB", sub>,  BASIC_NORMAL<0x0, "SUB", sub>;
  defm MUL16   : BASIC_RR_IS_COM <0x0, "MUL", mul>,  BASIC_NORMAL<0x0, "MUL", mul>;
  defm SMUL16  : BASIC_RR_IS_COM <0x0, "MLI", DCPU16smul>,
                   BASIC_NORMAL<0x0, "MLI", DCPU16smul>;
  defm UMUL16  : BASIC_RR_IS_COM <0x0, "MUL", DCPU16umul>,
                   BASIC_NORMAL<0x0, "MUL", DCPU16umul>;
  defm DIV16   : BASIC_RR_NON_COM<0x0, "DIV", udiv>, BASIC_NORMAL<0x0, "DIV", udiv>;
  defm DVI16   : BASIC_RR_NON_COM<0x0, "DVI", sdiv>, BASIC_NORMAL<0x0, "DVI", sdiv>;
  defm SRL16   : BASIC_RR_NON_COM<0x0, "SHR", srl>,  BASIC_NORMAL<0x0, "SHR", srl>;
  defm SRA16   : BASIC_RR_NON_COM<0x0, "ASR", sra>,  BASIC_NORMAL<0x0, "ASR", sra>;
  defm SHL16   : BASIC_RR_NON_COM<0x0, "SHL", shl>,  BASIC_NORMAL<0x0, "SHL", shl>;
  defm UREM16  : BASIC_RR_NON_COM<0x0, "MOD", urem>, BASIC_NORMAL<0x0, "MOD", urem>;
  defm SREM16  : BASIC_RR_NON_COM<0x0, "MDI", srem>, BASIC_NORMAL<0x0, "MDI", srem>;

  let Uses = [EX] in {
    defm ADC16   : BASIC_RR_IS_COM <0x0, "ADX", adde>, BASIC_NORMAL<0x0, "ADX", adde>;
    defm SBC16   : BASIC_RR_NON_COM<0x0, "SBX", sube>, BASIC_NORMAL<0x0, "SBX", sube>;
  }

} // Defs = [EX]


//===----------------------------------------------------------------------===//
// Non-Instruction Patterns

// GlobalAddress, ExternalSymbol
def : Pat<(i16 (DCPU16Wrapper tglobaladdr:$dst)), (MOV16ri tglobaladdr:$dst)>;
def : Pat<(i16 (DCPU16Wrapper texternalsym:$dst)), (MOV16ri texternalsym:$dst)>;
def : Pat<(i16 (DCPU16Wrapper tblockaddress:$dst)), (MOV16ri tblockaddress:$dst)>;
def : Pat<(i16 (DCPU16Wrapper tjumptable:$dst)), (MOV16ri tjumptable:$dst)>;

def : Pat<(add GR16:$src, (DCPU16Wrapper tglobaladdr :$src2)),
          (ADD16ri GR16:$src, tglobaladdr:$src2)>;
def : Pat<(add GR16:$src, (DCPU16Wrapper texternalsym:$src2)),
          (ADD16ri GR16:$src, texternalsym:$src2)>;
def : Pat<(add GR16:$src, (DCPU16Wrapper tblockaddress:$src2)),
          (ADD16ri GR16:$src, tblockaddress:$src2)>;
def : Pat<(add GR16:$src, (DCPU16Wrapper tjumptable:$src2)),
          (ADD16ri GR16:$src, tjumptable:$src2)>;

def : Pat<(store (i16 (DCPU16Wrapper tglobaladdr:$src)), addr:$dst),
          (MOV16mi addr:$dst, tglobaladdr:$src)>;
def : Pat<(store (i16 (DCPU16Wrapper texternalsym:$src)), addr:$dst),
          (MOV16mi addr:$dst, texternalsym:$src)>;
def : Pat<(store (i16 (DCPU16Wrapper tblockaddress:$src)), addr:$dst),
          (MOV16mi addr:$dst, tblockaddress:$src)>;
def : Pat<(store (i16 (DCPU16Wrapper tjumptable:$src)), addr:$dst),
          (MOV16mi addr:$dst, tjumptable:$src)>;

// calls
def : Pat<(DCPU16call (i16 tglobaladdr:$dst)),
          (CALLi tglobaladdr:$dst)>;
def : Pat<(DCPU16call (i16 texternalsym:$dst)),
          (CALLi texternalsym:$dst)>;

// add and sub always produce carry
def : Pat<(addc GR16:$src, GR16:$src2),
          (ADD16rr GR16:$src, GR16:$src2)>;
def : Pat<(addc GR16:$src, (load addr:$src2)),
          (ADD16rm GR16:$src, addr:$src2)>;
def : Pat<(addc GR16:$src, imm:$src2),
          (ADD16ri GR16:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR16:$src), addr:$dst),
          (ADD16mr addr:$dst, GR16:$src)>;
def : Pat<(store (addc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (ADD16mm addr:$dst, addr:$src)>;

def : Pat<(subc GR16:$src, GR16:$src2),
          (SUB16rr GR16:$src, GR16:$src2)>;
def : Pat<(subc GR16:$src, (load addr:$src2)),
          (SUB16rm GR16:$src, addr:$src2)>;
def : Pat<(subc GR16:$src, imm:$src2),
          (SUB16ri GR16:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR16:$src), addr:$dst),
          (SUB16mr addr:$dst, GR16:$src)>;
def : Pat<(store (subc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (SUB16mm addr:$dst, addr:$src)>;
