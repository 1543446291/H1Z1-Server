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
	this->m_dHTTPPort = 80;
	this->m_dGatewayPort = 20043;
	this->m_dZonePort = 1000;
	this->m_dUdpLength = 512;
}

int H1Z1::SendPacket(unsigned char* b, int size)
{	
	return sendto(this->_socket, (const char*)b, size, 0, (const struct sockaddr*) & this->_socketinformation, this->_socketsize);
}

void H1Z1::HandleMultiPacket(unsigned char* _packet, size_t _size)
{
	throw std::logic_error("The method or operation is not implemented.");
}

void H1Z1::HandleData(unsigned char* _packet, size_t _size)
{
	throw std::logic_error("The method or operation is not implemented.");
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

void H1Z1::KickSession(unsigned long _sessionId)
{
	//Basically, we send a broken packet the game can't handle to crash the game.
	Stream KickPacket;
	KickPacket.WriteInt16(OPCodes::SessionReply);
	KickPacket.WriteUInt32(_sessionId);
	KickPacket.WriteUInt32(99);
	KickPacket.WriteUInt32(0);
	KickPacket.WriteUInt8(512);
	KickPacket.WriteUInt16(2);
	KickPacket.WriteUInt32(3);

	H1Z1::SendPacket(KickPacket._raw, KickPacket._size);
}

void H1Z1::HandleSessionRequest(unsigned char* _packet, size_t _size)
{
	//TODO: use a struct like packet system(auto packet = new (struct LoginRequest)_packet;)
	Stream SessionReq(_packet, _size);

	auto packetID	= SessionReq.ReadInt16();
	auto unknown	= SessionReq.ReadInt32();
	auto sessionID	= SessionReq.ReadUInt32();
	auto udpLength	= SessionReq.ReadUInt32();
	auto protocol	= SessionReq.ReadASCIIString();

	printf("[Info] SessionRequest from {%X}\n", sessionID);

#ifdef LOG
	//printf("[%d] sessionID {%X} crcLenght {%d} udpLength {%d} protocol {%s}\n", packetID, sessionID, crcLength, udpLength, protocol.c_str());
#endif

	if (!this->m_sProtocol.compare(protocol))
	{
		clientList[sessionID] = new H1Z1::CLIENT(); //Create a new user and use his sessionID as an Id
		//TODO: Update the HTTP API to show the number of connected clients
		bool _encryptable = false;
		bool _compressable = true;

		clientList[sessionID]->StartSession(sessionID, udpLength);
		clientList[sessionID]->SetCompressable(_compressable);
		clientList[sessionID]->SetEncryptable(_encryptable);

		Stream packet;

		packet.WriteInt16(OPCodes::SessionReply);
		packet.WriteUInt32(sessionID);
		packet.WriteUInt32(0); //CRCSeed
		packet.WriteUInt8(2);
		packet.WriteUInt8(1);
		packet.WriteUInt32(2);
		packet.WriteUInt8(0);
		packet.WriteUInt32(3);

		Utils::Hexdump(packet._raw, packet._size);

		if(H1Z1::SendPacket(packet._raw, packet._size))
			printf("[Info] SessionReply sent to {%X}\n", sessionID);
	}
	else
	{
		printf("[Warning] a client tried to connect with a wrong protocol (server: %s client: %s)\n", this->m_sProtocol.c_str(), protocol.c_str());

		H1Z1::KickSession(sessionID);

		printf("[Info] kicked {%X} reason: DisconnectReasonProtocolMismatch\n", sessionID);

		delete this->clientList[sessionID];
		clientList.erase(sessionID);
	}
}

void H1Z1::HandleDataFragment(unsigned char* _packet, size_t _size)
{
// 	var data = new Buffer(4 + ((compression && !isSubPacket) ? 1 : 0) + packet.data.length),
// 		offset = 0;
// 	data.writeUInt16BE(0x0D, offset);
// 	offset += 2;
// 	if (compression) {
// 		data.writeUInt8(0, offset);
// 		offset += 1;
// 	}
// 	data.writeUInt16BE(packet.sequence, offset);
// 	offset += 2;
// 	packet.data.copy(data, offset);
// 	if (!isSubPacket) {
// 		data = appendCRC(data, crcSeed);
// 	}

	Stream data(_packet, _size);

	auto packetID = data.ReadInt16();
	auto sequence = data.ReadUInt16();
	auto fragmentEnd = data._raw - 0;

}

void H1Z1::HandlePacket(unsigned char* _packet, size_t _size)
{
	int16_t opCode = GetOpCode(_packet);
	//if (!_sender.HasSession())
	//{
	//	if (opCode != OPCodes::SESSION_REQUEST)
	//	{
	//		// TODO: Handle this to avoid DoS attacks on the head server
	//		return;
	//	}
	//}

	//TODO: Verify packet size before trying to handle it
	switch (opCode)
	{
	case OPCodes::SessionRequest:
		HandleSessionRequest(_packet, _size);
		break;
	case OPCodes::MultiPacket:
		HandleMultiPacket(_packet, _size);
		break;
	case OPCodes::Disconnect:
		if (_size == 11) //Make sure the packet size is equal to the one we're handling
			HandleDisconnect(_packet, _size);
		break;
	case OPCodes::Ping:
		//TODO: send a PONG reply
		printf("[Info] server received a ping\n");
		break;
	case OPCodes::Data:
		HandleData(_packet, _size);
		break;
	case OPCodes::DataFragment:
		//TODO: Handle it, this is the next step
		HandleDataFragment(_packet, _size);
		break;
	case OPCodes::Ack:

		break;
	case OPCodes::NetStatusRequest:
		printf("[Info] server received a net status request\n");
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

H1Z1* H1Z1::GetInstance()
{
	if (!m_pInstance)
		m_pInstance = new H1Z1();

	return m_pInstance;
}