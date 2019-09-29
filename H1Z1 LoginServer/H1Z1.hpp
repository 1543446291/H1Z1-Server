#pragma once
#include <windows.h>
#include <string>
#include <iostream>
#include <chrono>
#include <map>

enum OPCodes
{
	SESSION_REQUEST = 0x01,
	SESSION_RESPONSE = 0x02,
	MULTI = 0x03,
	DISCONNECT = 0x05,
	PING = 0x06,
	NET_STATUS_REQUEST = 0x07,
	NET_STATUS_RESPONSE = 0x08,
	RELIABLE_DATA = 0x09,
	FRAGMENTED_RELIABLE_DATA = 0x0D,
	OUT_OF_ORDER_RELIABLE_DATA = 0x11,
	ACK_RELIABLE_DATA = 0x15,
	MULTI_MESSAGE = 0x19,
	FATAL_ERROR = 0x1D,
	FATAL_ERROR_RESPONSE = 0x1E
};

enum PacketName
{
	LoginRequest,
	LoginReply,
	Logout,
	ForceDisconnect,
	CharacterCreateRequest,
	CharacterCreateReply,
	CharacterLoginRequest,
	CharacterLoginReply,
	CharacterDeleteRequest,
	CharacterDeleteReply,
	CharacterSelectInfoRequest,
	CharacterSelectInfoReply,
	ServerListRequest,
	ServerListReply,
	ServerUpdate,
	TunnelAppPacketClientToServer,
	TunnelAppPacketServerToClient,
	CharacterTransferRequest,
	CharacterTransferReply
};

class H1Z1
{
private:
	H1Z1();
	~H1Z1();

	static H1Z1* m_pInstance;

public:

	std::string m_sProtocol;
	uint16_t m_dUdpLength;
	std::string m_sServerAddress;
	int32_t m_dServerPort;
	int32_t m_dGatewayPort;
	int32_t m_dZonePort;
	int32_t m_dClientNum;

	class CLIENT;
	std::map<int, CLIENT*> clientList;

	SOCKET _socket;
	int _socketsize;
	struct sockaddr_in _socketinformation;

	void Init();
	void HandleFragmentedReliableData(unsigned char* _packet, size_t _size);
	void HandleDisconnect(unsigned char* _packet, size_t _size);
	void HandleSessionRequest(unsigned char* _packet, size_t _size);
	void HandlePacket(unsigned char* _packet, size_t _size);


	int SendPacket(unsigned char* b, int size);

	static H1Z1* GetInstance();

	int16_t GetOpCode(unsigned char*);
};

class H1Z1::CLIENT
{
private:
	bool SessionStarted;
	unsigned long SessionID;
	uint16_t CRCLength;
	uint16_t BufferSize;
	uint16_t CRCSeed;
	bool Encryptable;
	bool Compressable;

	// Server properties
	int ClientID = -1;
	int LastInteraction;
	bool Encrypted;
public:

	void StartSession(uint16_t _crcLength, unsigned long _sessionId, uint16_t _udpBufferSize);

	bool HasSession();

	uint16_t GetCRCLength();

	unsigned long GetSessionID();

	uint16_t GetBufferSize();

	uint16_t GetCRCSeed();

	bool IsEncrypted();

	void SetEncryptable(bool _encryptable);

	void ToggleEncryption();

	bool IsCompressable();

	void SetCompressable(bool _compressable);

	void Disconnect(int16_t _reason, bool _client = false);

	int GetLastInteraction();

	void Interact();

};
