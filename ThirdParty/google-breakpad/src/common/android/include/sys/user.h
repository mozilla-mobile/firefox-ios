// Copyright (c) 2012, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef GOOGLE_BREAKPAD_COMMON_ANDROID_INCLUDE_SYS_USER_H
#define GOOGLE_BREAKPAD_COMMON_ANDROID_INCLUDE_SYS_USER_H

// The purpose of this file is to glue the mismatching headers (Android NDK vs
// glibc) and therefore avoid doing otherwise awkward #ifdefs in the code.
// The following quirks are currently handled by this file:
// - MIPS: Keep using forked definitions of user.h structs. The definition in
//   the NDK is completely different.
//   Internal bug b/18097715
// - i386: Use the Android NDK but alias user_fxsr_struct > user_fpxregs_struct.
// - Other platforms: Just use the Android NDK unchanged.

#ifdef __mips__
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#define EF_REG0 6
#define EF_REG1 7
#define EF_REG2 8
#define EF_REG3 9
#define EF_REG4 10
#define EF_REG5 11
#define EF_REG6 12
#define EF_REG7 13
#define EF_REG8 14
#define EF_REG9 15
#define EF_REG10 16
#define EF_REG11 17
#define EF_REG12 18
#define EF_REG13 19
#define EF_REG14 20
#define EF_REG15 21
#define EF_REG16 22
#define EF_REG17 23
#define EF_REG18 24
#define EF_REG19 25
#define EF_REG20 26
#define EF_REG21 27
#define EF_REG22 28
#define EF_REG23 29
#define EF_REG24 30
#define EF_REG25 31

/*
 * k0/k1 unsaved
 */
#define EF_REG26 32
#define EF_REG27 33
#define EF_REG28 34
#define EF_REG29 35
#define EF_REG30 36
#define EF_REG31 37

/*
 * Saved special registers
 */
#define EF_LO 38
#define EF_HI 39
#define EF_CP0_EPC 40
#define EF_CP0_BADVADDR 41
#define EF_CP0_STATUS 42
#define EF_CP0_CAUSE 43

struct user_regs_struct {
  unsigned long long regs[32];
  unsigned long long lo;
  unsigned long long hi;
  unsigned long long epc;
  unsigned long long badvaddr;
  unsigned long long status;
  unsigned long long cause;
};

struct user_fpregs_struct {
  unsigned long long regs[32];
  unsigned int fpcsr;
  unsigned int fir;
};

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#else  //  __mips__

#include_next <sys/user.h>

#ifdef __i386__
#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
typedef struct user_fxsr_struct user_fpxregs_struct;
#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus
#endif  // __i386__

#endif  // __mips__

#endif  // GOOGLE_BREAKPAD_COMMON_ANDROID_INCLUDE_SYS_USER_H
