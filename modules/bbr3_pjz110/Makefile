# SPDX-License-Identifier: GPL-2.0-or-later
obj-m := bbr3_pjz110.o
bbr3_pjz110-y := tcp_bbr3.o

# KPM code is relocated by KPatch-Next, not by the Linux module loader.
# Remove compiler/runtime features that would add unsupported kernel-module
# dependencies or metadata.
ccflags-y += -fno-stack-protector
ccflags-y += -fno-asynchronous-unwind-tables -fno-unwind-tables
ccflags-y += -mbranch-protection=none
