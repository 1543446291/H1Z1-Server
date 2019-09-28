#include <Windows.h>
#include "Utils.hpp"

const char* Utils::GetDisconnectReason(uint16_t _reasonId)
{
	const char* _sReason = "null";

	switch (_reasonId)
	{
	case DisconnectReasonTimeout:
		_sReason = "DisconnectReasonTimeout";
		break;
	case DisconnectReasonNone:
		_sReason = "DisconnectReasonNone";
		break;
	case DisconnectReasonOtherSideTerminated:
		_sReason = "DisconnectReasonOtherSideTerminated";
		break;
	case DisconnectReasonManagerDeleted:
		_sReason = "DisconnectReasonManagerDeleted";
		break;
	case DisconnectReasonConnectFail:
		_sReason = "DisconnectReasonConnectFail";
		break;
	case DisconnectReasonApplication:
		_sReason = "DisconnectReasonApplication";
		break;
	case DisconnectReasonUnreachableConnection:
		_sReason = "DisconnectReasonUnreachableConnection";
		break;
	case DisconnectReasonUnacknowledgedTimeout:
		_sReason = "DisconnectReasonUnacknowledgedTimeout";
		break;
	case DisconnectReasonNewConnectionAttempt:
		_sReason = "DisconnectReasonNewConnectionAttempt";
		break;
	case DisconnectReasonConnectionRefused:
		_sReason = "DisconnectReasonConnectionRefused";
		break;
	case DisconnectReasonConnectErro:
		_sReason = "DisconnectReasonConnectErro";
		break;
	case DisconnectReasonConnectingToSelf:
		_sReason = "DisconnectReasonConnectingToSelf";
		break;
	case DisconnectReasonReliableOverflow:
		_sReason = "DisconnectReasonReliableOverflow";
		break;
	case DisconnectReasonApplicationReleased:
		_sReason = "DisconnectReasonApplicationReleased";
		break;
	case DisconnectReasonCorruptPacket:
		_sReason = "DisconnectReasonCorruptPacket";
		break;
	case DisconnectReasonProtocolMismatch:
		_sReason = "DisconnectReasonProtocolMismatch";
		break;
	}
	return _sReason;
}


void Utils::Hexdump(void* ptr, int buflen)
{
	unsigned char* buf = (unsigned char*)ptr;
	int i, j;
	for (i = 0; i < buflen; i += 16) {
		printf("%06x: ", i);
		for (j = 0; j < 16; j++)
			if (i + j < buflen)
				printf("%02x ", buf[i + j]);
			else
				printf("   ");
		printf(" ");
		for (j = 0; j < 16; j++)
			if (i + j < buflen)
				printf("%c", isprint(buf[i + j]) ? buf[i + j] : '.');
		printf("\n");
	}
}