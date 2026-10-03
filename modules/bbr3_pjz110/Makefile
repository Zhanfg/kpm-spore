# SPDX-License-Identifier: GPL-2.0-or-later
obj-m := bbr3_pjz110.o
bbr3_pjz110-y := tcp_bbr3.o

# KPatch-Next owns the runtime loader, not the Linux module loader.
# Avoid compiler/runtime dependencies that KPatch-Next does not export.
ccflags-y += -fno-stack-protector
ccflags-y += -fno-unwind-tables -fno-asynchronous-unwind-tables
