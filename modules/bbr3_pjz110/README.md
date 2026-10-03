# ⚠️ UNSAFE — DO NOT LOAD ON DEVICE

**This experimental BBRv3 KPM caused a hard device failure on PJZ110, including a Qualcomm 9008/EDL recovery event. Do not load any generated `.kpm` artifact from this branch.**

The implementation is retained only for postmortem analysis. Runtime loading is suspended until the design is replaced with an ABI-safe approach validated against the exact running kernel build.

# PJZ110 BBRv3 KPM

Real BBRv3 data path packaged as a KPatch-Next-compatible KernelPatch Module for OnePlus 13 (PJZ110) Linux 6.6.

## Source pins

- BBRv3: `hrimfaxi/tcp_bbr_modules@c5c557584175b5fed8939bf91ec249aed158597d`
- OnePlus kernel capability map: `android_kernel_common_oneplus_sm8750@e1b346b6b4f4096eb342ae3684838a942fd6f6c4`

This is not a renamed BBRv1 implementation. The full upstream `tcp_bbr3.c` algorithm is retained.

## KPM adaptation

- replaces Linux `module_init/module_exit` with `KPM_INIT/KPM_EXIT`
- constrains undefined ELF symbols to the KPatch-Next ABI (`kver` + exported `kallsyms_lookup_name`)
- resolves Linux kernel data/functions (`jiffies`, allocator, RNG, TCP registration) at KPM init time
- resolves `tcp_register_congestion_control` and `tcp_unregister_congestion_control` through KernelPatch kallsyms
- preserves the previously verified PJZ110 compatibility map
- keeps the previous safe fallback for trimmed PLB / ACK helpers
- registers the congestion-control name `bbr3`
- supports optional load arg `ecn_low=1`
- refuses kernels outside Linux 6.6

## Build

```sh
cmake -B build
cmake --build build --target bbr3_pjz110
```

Output:

```
build/bbr3_pjz110/bbr3_pjz110.kpm
```

## Runtime verification

After loading, verify from Android shell:

```sh
cat /proc/sys/net/ipv4/tcp_available_congestion_control
cat /proc/sys/net/ipv4/tcp_congestion_control
```

Expected available list contains `bbr3`. Switching the default CC remains a userspace policy action; the KPM only registers/unregisters the algorithm.

## Safety

This build is intentionally PJZ110-specific. Do not autoload it on unrelated 6.6 kernels until their TCP structure/API compatibility has been verified.

### Important: do not unload after use

KPatch-Next frees a KPM after calling its exit callback and does not provide Linux module refcount semantics. Existing TCP sockets may still hold congestion-control function pointers after `tcp_unregister_congestion_control()`.

For that reason, once `bbr3` has been selected by any live socket, **do not unload this KPM during the same boot**. Restore the default congestion-control policy if needed, then reboot before removing/replacing the KPM.
