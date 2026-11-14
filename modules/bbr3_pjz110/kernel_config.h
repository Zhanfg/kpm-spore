#pragma once
/* PJZ110 / OnePlus SM8750 Android 16 BBRv3 capability map.
 * Pinned to OnePlus common-kernel source:
 * e1b346b6b4f4096eb342ae3684838a942fd6f6c4
 */
#define HAVE_TCP_ECN_OK 1
#define HAVE_TCP_CONG_NEEDS_ECN 1
#define HAVE_CA_EVENT_ECN_IS_CE 1

#define HAVE_RATE_SAMPLE_LOSSES 1
#define HAVE_RATE_SAMPLE_PRIOR_IN_FLIGHT 1
#define HAVE_RATE_SAMPLE_DELIVERED_CE 1

#define HAVE_TCP_SOCK_DELIVERED_CE 1
#define HAVE_TCP_SOCK_IS_SACK_RENEG 1
#define HAVE_TCP_SOCK_LOST 1
#define HAVE_TCP_SOCK_LOST_OUT 1
#define HAVE_TCP_SOCK_PRIOR_CWND 1
#define HAVE_TCP_SOCK_TCP_CLOCK_CACHE 1
#define HAVE_TCP_SOCK_ECN_FLAGS 1
#define HAVE_TCP_SOCK_SND_CWND 1

#define HAVE_SKB_CB_TX_DELIVERED_MSTAMP 1
#define HAVE_SKB_CB_TX_IS_APP_LIMITED 1

#define HAVE_TCP_SND_CWND 1
#define HAVE_TCP_SND_CWND_SET 1
#define HAVE_TCP_STAMP_US_DELTA 1
#define HAVE_TCP_MIN_RTT 1

#define HAVE_GET_RANDOM_U32_BELOW 1

/* Keep native PLB declarations visible; call sites are redirected to local
 * no-op shims because PLB is optional for this device-targeted compatibility
 * port and we do not want a hard runtime dependency on private PLB helpers.
 */
#define HAVE_TCP_PLB_STATE 1
#define HAVE_TCP_PLB_SCALE 1
#define HAVE_TCP_PLB_UPDATE_STATE 1
#define HAVE_TCP_PLB_CHECK_REHASH 1
#define HAVE_TCP_PLB_UPDATE_STATE_UPON_RTO 1

#define HAVE_ICSK_CA_PRIV 1
