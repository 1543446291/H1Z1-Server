#include <Windows.h>
#include "H1Z1.hpp"
#include "Utils.hpp"
#include "Stream.h"
#include "UdpServer.hpp"

H1Z1* H1Z1::m_pInstance;

H1Z1::H1Z1()
{
}

H1Z1::~H1Z1()
{
}

/*
	The init function setup the LoginServer/GatewayServer/ZoneServer infos
*/
void H1Z1::Init()
{
	this->m_sProtocol.assign("LoginUdp_9");
	this->m_sServerAddress.assign("127.0.0.1");
	this->m_dServerPort = 20042;
	this->m_dGatewayPort = 20043;
	this->m_dZonePort = 1000;
	this->m_dUdpLength = 512;
}

int H1Z1::SendPacket(unsigned char* b, int size)
{	
	return sendto(this->_socket, (const char*)b, size, 0, (const struct sockaddr*) & this->_socketinformation, this->_socketsize);
}

void H1Z1::HandleDisconnect(unsigned char* _packet, size_t _size)
{
	Stream Disconnect(_packet, _size);

	auto packetID = Disconnect.ReadInt16();
	auto null1 = Disconnect.ReadInt8();
	auto sessionID = Disconnect.ReadUInt32();
	auto disconnectReason = Disconnect.ReadUInt16();

	if (sessionID == this->clientList[sessionID]->GetSessionID())
	{
		delete this->clientList[sessionID];
		clientList.erase(sessionID);

		printf("[Info] {%X} disconnected, reason: %s\n", sessionID, Utils::GetDisconnectReason(disconnectReason)); //TODO: handle the different disconnect reason, maybe store the disconnection type into a database
	}
}

void H1Z1::HandleSessionRequest(unsigned char* _packet, size_t _size)
{
	//TODO: use a struct like packet system(auto packet = new (struct SessionRequest)_packet;)
	Stream SessionReq(_packet, _size);

	auto packetID	= SessionReq.ReadInt16();
	auto unknown	= SessionReq.ReadInt32();
	auto sessionID	= SessionReq.ReadUInt32();
	auto crcLength	= SessionReq.ReadUInt16();
	auto udpLength	= SessionReq.ReadUInt16();
	auto protocol	= SessionReq.ReadASCIIString();

	printf("[Info] SessionRequest from {%X}\n", sessionID);

#ifdef LOG
	//printf("[%d] sessionID {%X} crcLenght {%d} udpLength {%d} protocol {%s}\n", packetID, sessionID, crcLength, udpLength, protocol.c_str());
#endif

	if (!this->m_sProtocol.compare(protocol))
	{
		clientList[sessionID] = new H1Z1::CLIENT(); //Create a new user and use his sessionID as an Id

		bool _encryptable = false;
		bool _compressable = true;

		clientList[sessionID]->StartSession(crcLength, sessionID, udpLength);
		clientList[sessionID]->SetCompressable(_compressable);
		clientList[sessionID]->SetEncryptable(_encryptable);

		Stream packet;

		packet.WriteInt16(OPCodes::SESSION_RESPONSE);
		packet.WriteUInt32(sessionID);
		packet.WriteUInt8(99);
		packet.WriteUInt8(99);
		packet.WriteUInt8(99);
		packet.WriteUInt8(99);
		packet.WriteUInt16(513);
		packet.WriteInt32(2);
		packet.WriteInt32(0);
		packet.WriteUInt8(3);

		if(H1Z1::SendPacket(packet._raw, packet._size))
			printf("[Info] SessionReply sent to {%X}\n", sessionID);
	}
	else
	{
		printf("[Warning] a client tried to connect with a wrong protocol (server: %s client: %s)\n", this->m_sProtocol.c_str(), protocol.c_str());

		Stream packet;

		packet.WriteInt16(OPCodes::DISCONNECT);
		packet.WriteUInt8(0);
		packet.WriteUInt32(sessionID);
		packet.WriteUInt16(Utils::DisconnectReasonProtocolMismatch);
		packet.WriteUInt16(/*XorCRCTruncated*/0); //Useless 

		if (H1Z1::SendPacket(packet._raw, packet._size))
			printf("[Warning] disconnected {%X} reason: DisconnectReasonProtocolMismatch\n", sessionID);

		closesocket(this->_socket);


		//auto it = this->clientList.find(sessionID);
		//if (it != this->clientList.end())

		delete this->clientList[sessionID];
		clientList.erase(sessionID);


		//TODO: - Server.RemoveClient(sender);
	}

}

void H1Z1::HandlePacket(unsigned char* _packet, size_t _size)
{
	int16_t opCode = GetOpCode(_packet);
	//if (!_sender.HasSession())
	//{
	//	if (opCode != OPCodes::SESSION_REQUEST)
	//	{
	//		// TODO: Handle this to avoid DoS attacks
	//		return;
	//	}
	//}

	//TODO: Verify packet size before trying to handle it
	switch (opCode)
	{
	case OPCodes::SESSION_REQUEST:
		HandleSessionRequest(_packet, _size);
		break;
	case OPCodes::MULTI:

		break;
	case OPCodes::DISCONNECT:
		HandleDisconnect(_packet, _size);
		break;
	case OPCodes::PING:
		//TODO: PONG
		break;
	case OPCodes::RELIABLE_DATA:

		break;
	case OPCodes::FRAGMENTED_RELIABLE_DATA:
		//TODO: Handle it, this is the next step
		HandleFragmentedReliableData(_packet, _size);

		break;
	case OPCodes::ACK_RELIABLE_DATA:
		//sender.DataChannel.Receive(packet);
		break;

	default:
		printf("[Warning] Received Unknown packet %d!\n", opCode);
		break;
	}
}

int16_t H1Z1::GetOpCode(unsigned char* _packet)
{
	Stream packet(_packet, sizeof _packet);
	
	return packet.ReadInt16();
}

void H1Z1::HandleFragmentedReliableData(unsigned char* _packet, size_t _size)
{
	//Utils::Hexdump(_packet, _size);
	//TODO: Handle the packet, find how it is constructed (maybe encrypted)
}

H1Z1* H1Z1::GetInstance()
{
	if (!m_pInstance)
		m_pInstance = new H1Z1();

	return m_pInstance;
}