
enum DisconnectReason
{
	DisconnectReasonNone,
	DisconnectReasonConnectionRefused,
	DisconnectReasonTooManyConnections,
	DisconnectReasonApplication,
	DisconnectReasonTimeout,
	DisconnectReasonApplicationReleased,
	DisconnectReasonSocketError,
	DisconnectReasonSocketErrorDuringNegotiation,
	DisconnectReasonOtherSideTerminated,
	DisconnectReasonManagerDeleted,
	DisconnectReasonConnectError,
	DisconnectReasonConnectFail,
	DisconnectReasonLogicalPacketTooShort,
	DisconnectReasonLogicalPacketTooLong,
	DisconnectReasonConnectTimeout,
	DisconnectReasonConnectionReset,
	DisconnectReasonConnectionAborted,
	DisconnectReasonDnsFailure,
	DisconnectReasonUnableToCreateSocket,
	DisconnectReasonUnableToConfigureSocket,
	UnknownReason
};
