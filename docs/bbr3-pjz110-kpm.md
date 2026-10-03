# BBRv3 PJZ110 KPM

This module is a direct KPM port of the BBRv3 path previously used by
\`Zhanfg/TCP_Optimiser_RS\` for OnePlus 13 / PJZ110.

## Provenance

- OnePlus common kernel: \`e1b346b6b4f4096eb342ae3684838a942fd6f6c4\`
  - public PJZ110 16.0.9.401 source
- BBRv3: \`hrimfaxi/tcp_bbr_modules@c5c557584175b5fed8939bf91ec249aed158597d\`
- KPM name: \`kpm-bbr3-pjz110\`
- Version: \`1.0.0-alpha1\`

This is the real BBRv3 congestion-control implementation. It is not the
stock BBR implementation renamed to \`bbr3\`.

## Why KPM

The previous \`.ko\` route depended on GKI/KMI symbol CRCs and exact module ABI.
The KPM port keeps the BBRv3 TCP data path but resolves the small set of
ABI-sensitive kernel services at runtime through KernelPatch kallsyms.

The build fails if unexpected ordinary kernel symbols remain unresolved.

## Runtime gate

The module refuses registration unless it can resolve the required runtime
symbols and the kernel banner identifies Linux 6.6 + android15.

The public OnePlus source currently lags the user's PJZ110 16.0.10.501 OTA,
so this alpha must be verified on-device before enabling at boot.

## Load / verify

After loading the KPM, verify:

\`\`\`sh
cat /proc/sys/net/ipv4/tcp_available_congestion_control
cat /proc/sys/net/ipv4/tcp_congestion_control
\`\`\`

Expected after registration:

\`\`\`text
... bbr3 ...
\`\`\`

Switching the default CC can then be done through the existing
TCP_Optimiser_RS runtime or ordinary sysctl tooling.

KPM control command:

\`\`\`text
status
\`\`\`

returns registration state, active BBRv3 socket count, ECN mode and runtime
bridge state.

## Important lifecycle limitation

**Do not hot-unload this alpha. Reboot to remove it.**

Current KernelPatch invokes KPM exit callbacks while holding an RCU read lock
and frees the KPM regardless of the exit return value. Linux
\`tcp_unregister_congestion_control()\` waits for an RCU grace period and
existing TCP sockets may retain congestion-control callback pointers.

That combination makes generic hot-unload unsafe for a KPM that provides a
\`tcp_congestion_ops\` implementation. The exit callback therefore reports
\`-EBUSY\`; this version is intentionally treated as reboot-only.

Do not configure boot auto-load until a manual load has passed the PJZ110
runtime validation.
