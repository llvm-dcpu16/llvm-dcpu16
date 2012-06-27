//===--- AlignOf.h - Portable calculation of type alignment -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the AlignOf function that computes alignments for
// arbitrary types.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_SUPPORT_ALIGNOF_H
#define LLVM_SUPPORT_ALIGNOF_H

#include "llvm/Support/Compiler.h"
#include <cstddef>

namespace llvm {

template <typename T>
struct AlignmentCalcImpl {
  char x;
  T t;
private:
  AlignmentCalcImpl() {} // Never instantiate.
};

/// AlignOf - A templated class that contains an enum value representing
///  the alignment of the template argument.  For example,
///  AlignOf<int>::Alignment represents the alignment of type "int".  The
///  alignment calculated is the minimum alignment, and not necessarily
///  the "desired" alignment returned by GCC's __alignof__ (for example).  Note
///  that because the alignment is an enum value, it can be used as a
///  compile-time constant (e.g., for template instantiation).
template <typename T>
struct AlignOf {
  enum { Alignment =
         static_cast<unsigned int>(sizeof(AlignmentCalcImpl<T>) - sizeof(T)) };

  enum { Alignment_GreaterEqual_2Bytes = Alignment >= 2 ? 1 : 0 };
  enum { Alignment_GreaterEqual_4Bytes = Alignment >= 4 ? 1 : 0 };
  enum { Alignment_GreaterEqual_8Bytes = Alignment >= 8 ? 1 : 0 };
  enum { Alignment_GreaterEqual_16Bytes = Alignment >= 16 ? 1 : 0 };

  enum { Alignment_LessEqual_2Bytes = Alignment <= 2 ? 1 : 0 };
  enum { Alignment_LessEqual_4Bytes = Alignment <= 4 ? 1 : 0 };
  enum { Alignment_LessEqual_8Bytes = Alignment <= 8 ? 1 : 0 };
  enum { Alignment_LessEqual_16Bytes = Alignment <= 16 ? 1 : 0 };

};

/// alignOf - A templated function that returns the minimum alignment of
///  of a type.  This provides no extra functionality beyond the AlignOf
///  class besides some cosmetic cleanliness.  Example usage:
///  alignOf<int>() returns the alignment of an int.
template <typename T>
inline unsigned alignOf() { return AlignOf<T>::Alignment; }


/// \brief Helper for building an aligned character array type.
///
/// This template is used to explicitly build up a collection of aligned
/// character types. We have to build these up using a macro and explicit
/// specialization to cope with old versions of MSVC and GCC where only an
/// integer literal can be used to specify an alignment constraint. Once built
/// up here, we can then begin to indirect between these using normal C++
/// template parameters.
template <size_t Alignment> struct AlignedCharArrayImpl {};
template <> struct AlignedCharArrayImpl<0> {
  typedef char type;
};
#if __has_feature(cxx_alignas)
#define LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(x) \
  template <> struct AlignedCharArrayImpl<x> { \
    typedef char alignas(x) type; \
  }
#elif defined(__clang__) || defined(__GNUC__)
#define LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(x) \
  template <> struct AlignedCharArrayImpl<x> { \
    typedef char type __attribute__((aligned(x))); \
  }
#elif defined(_MSC_VER)
#define LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(x) \
  template <> struct AlignedCharArrayImpl<x> { \
    typedef __declspec(align(x)) char type; \
  }
#else
# error No supported align as directive.
#endif

LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(1);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(2);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(4);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(8);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(16);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(32);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(64);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(128);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(512);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(1024);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(2048);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(4096);
LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT(8192);
// Any larger and MSVC complains.
#undef LLVM_ALIGNEDCHARARRAY_TEMPLATE_ALIGNMENT

/// \brief This class template exposes a typedef for type containing a suitable
/// aligned character array to hold elements of any of up to four types.
///
/// These types may be arrays, structs, or any other types. The goal is to
/// produce a union type containing a character array which, when used, forms
/// storage suitable to placement new any of these types over. Support for more
/// than four types can be added at the cost of more boiler plate.
template <typename T1,
          typename T2 = char, typename T3 = char, typename T4 = char>
class AlignedCharArray {
  class AlignerImpl {
    T1 t1; T2 t2; T3 t3; T4 t4;

    AlignerImpl(); // Never defined or instantiated.
  };
  union SizerImpl {
    char arr1[sizeof(T1)], arr2[sizeof(T2)], arr3[sizeof(T3)], arr4[sizeof(T4)];
  };

public:
  // Sadly, Clang and GCC both fail to align a character array properly even
  // with an explicit alignment attribute. To work around this, we union
  // the character array that will actually be used with a struct that contains
  // a single aligned character member. Tests seem to indicate that both Clang
  // and GCC will properly register the alignment of a struct containing an
  // aligned member, and this alignment should carry over to the character
  // array in the union.
  union union_type {
    // This is the only member of the union which should be used by clients:
    char buffer[sizeof(SizerImpl)];

    // This member of the union only exists to force the alignment.
    struct {
      typename llvm::AlignedCharArrayImpl<AlignOf<AlignerImpl>::Alignment>::type
        nonce_inner_member;
    } nonce_member;
  };
};

} // end namespace llvm
#endif
