#pragma once
#include <windows.h>
#include <string>
#include <iostream>
#include <chrono>
#include <map>
#include <ctime	>

enum OPCodes
{
	SessionRequest = 0x01,
	SessionReply = 0x02,
	MultiPacket = 0x03,
	Disconnect = 0x05,
	Ping = 0x06,
	NetStatusRequest = 0x07,
	NetStatusReply = 0x08,
	Data = 0x09,
	DataFragment = 0x0D,
	OutOfOrder = 0x11,
	Ack = 0x15,
	MultiMessage = 0x19,
	FatalError = 0x1D,
	FatalErrorReply = 0x1E
};

enum LoginServer_PacketName
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
	int32_t m_dHTTPPort;
	int32_t m_dGatewayPort;
	int32_t m_dZonePort;
	int32_t m_dClientNum;

	class CLIENT;
	std::map<int, CLIENT*> clientList;

	SOCKET _socket;
	int _socketsize;
	struct sockaddr_in _socketinformation;

	void Init();
	void HandleMultiPacket(unsigned char* _packet, size_t _size);
	void HandleData(unsigned char* _packet, size_t _size);
	void HandleDataFragment(unsigned char* _packet, size_t _size);
	void HandleDisconnect(unsigned char* _packet, size_t _size);
	void KickSession(unsigned long _sessionId);
	void HandleSessionRequest(unsigned char* _packet, size_t _size);
	void HandlePacket(unsigned char* _packet, size_t _size);
	int SendPacket(unsigned char* b, int size);
	int16_t GetOpCode(unsigned char*);

	static H1Z1* GetInstance();

};

class H1Z1::CLIENT
{
private:
	bool SessionStarted;
	unsigned long SessionID;
	uint16_t BufferSize;
	uint16_t CRCSeed;
	bool Encryptable;
	bool Compressable;

	// Server properties
	int ClientID = -1;
	int LastInteraction;
	bool Encrypted;
public:

	void StartSession(unsigned long _sessionId, uint16_t _udpBufferSize);

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

	int GetLastInteraction();

	void Interact();

};
