/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef _PJZ110_BBR3_KPM_ABI_H_
#define _PJZ110_BBR3_KPM_ABI_H_

/*
 * Minimal KernelPatch Module ABI declarations.
 * Keep this header independent from KernelPatch's trimmed Linux headers so
 * the BBRv3 core can compile against the full pinned OnePlus kernel tree.
 */

#ifndef __user
#define __user
#endif

#define KPM_INFO(field, value, limit)                               \
    _Static_assert(sizeof(value) <= (limit), "KPM info too long"); \
    static const char __kpm_info_##field[] __attribute__((used))    \
    __attribute__((section(".kpm.info"), aligned(1))) = #field "=" value

#define KPM_NAME_LEN 32
#define KPM_VERSION_LEN 32
#define KPM_LICENSE_LEN 32
#define KPM_AUTHOR_LEN 32
#define KPM_DESCRIPTION_LEN 512

#define KPM_NAME(x) KPM_INFO(name, x, KPM_NAME_LEN)
#define KPM_VERSION(x) KPM_INFO(version, x, KPM_VERSION_LEN)
#define KPM_LICENSE(x) KPM_INFO(license, x, KPM_LICENSE_LEN)
#define KPM_AUTHOR(x) KPM_INFO(author, x, KPM_AUTHOR_LEN)
#define KPM_DESCRIPTION(x) KPM_INFO(description, x, KPM_DESCRIPTION_LEN)

typedef long (*kpm_initcall_t)(const char *args, const char *event, void *reserved);
typedef long (*kpm_exitcall_t)(void *reserved);

#define KPM_INIT(fn) \
    static kpm_initcall_t __kpm_initcall_##fn __attribute__((used, section(".kpm.init"))) = fn
#define KPM_EXIT(fn) \
    static kpm_exitcall_t __kpm_exitcall_##fn __attribute__((used, section(".kpm.exit"))) = fn

/* Symbols exported by the KernelPatch runtime to KPM relocations. */
extern unsigned int kver;

#endif
