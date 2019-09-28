#pragma once
#include <string>

namespace Utils
{
	enum {
		DisconnectReasonIcmpError = 0,
		DisconnectReasonTimeout = 1,
		DisconnectReasonNone = 2,
		DisconnectReasonOtherSideTerminated = 3,
		DisconnectReasonManagerDeleted = 4,
		DisconnectReasonConnectFail = 5,
		DisconnectReasonApplication = 6,
		DisconnectReasonUnreachableConnection = 7,
		DisconnectReasonUnacknowledgedTimeout = 8,
		DisconnectReasonNewConnectionAttempt = 9,
		DisconnectReasonConnectionRefused = 10,
		DisconnectReasonConnectErro = 11,
		DisconnectReasonConnectingToSelf = 12,
		DisconnectReasonReliableOverflow = 13,
		DisconnectReasonApplicationReleased = 14,
		DisconnectReasonCorruptPacket = 15,
		DisconnectReasonProtocolMismatch = 16
	};

	const char* GetDisconnectReason(uint16_t _reasonId);

	void Hexdump(void* ptr, int buflen);
}