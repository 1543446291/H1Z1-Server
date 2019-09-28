#include <Windows.h>
#include "H1Z1.hpp"
#include "Utils.hpp"
#include "Stream.h"
#include "UdpServer.hpp"

#define LOG

H1Z1* H1Z1::m_pInstance;

H1Z1::H1Z1()
{
}

H1Z1::~H1Z1()
{
}

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

void H1Z1::HandleDisconnect(H1Z1::CLIENT _sender, unsigned char* _packet, size_t _size)
{
	Stream Disconnect(_packet, _size);

	auto packetID = Disconnect.ReadInt16();
	auto null1 = Disconnect.ReadInt8();
	auto sessionID = Disconnect.ReadUInt32();
	auto disconnectReason = Disconnect.ReadUInt16();

	if (sessionID == _sender.GetSessionID())
	{
		//TODO: - Server.RemoveClient(sender);
	}

	printf("%s", Utils::GetDisconnectReason(disconnectReason)); //TODO: handle the different disconnect reason, maybe store the disconnection type into a database
}

void H1Z1::HandleSessionRequest(H1Z1::CLIENT _sender, unsigned char* _packet, size_t _size)
{
	//TODO: use a struct like packet system(auto packet = new (struct SessionRequest)_packet;)

	Stream SessionReq(_packet, _size);

	auto packetID	= SessionReq.ReadInt16();
	auto unknown	= SessionReq.ReadInt32();
	auto sessionID	= SessionReq.ReadUInt32();
	auto crcLength	= SessionReq.ReadUInt16();
	auto udpLength	= SessionReq.ReadUInt16();
	auto protocol	= SessionReq.ReadASCIIString();

#ifdef LOG
	//printf("[%d] sessionID {%X} crcLenght {%d} udpLength {%d} protocol {%s}\n", packetID, sessionID, crcLength, udpLength, protocol.c_str());
#endif

	if (!this->m_sProtocol.compare(protocol))
	{
		bool _encryptable = false;
		bool _compressable = true;

		_sender.StartSession(crcLength, sessionID, udpLength);
		_sender.SetCompressable(_compressable);
		_sender.SetEncryptable(_encryptable);

		/*TODO:
		Server.AddNewClient(sender);
		*/

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

		H1Z1::SendPacket(packet._raw, packet._size);
		printf("Packet sent\n");
		//TODO: Server.SendPacket(_sender, packet);
	}
	else
	{
		printf("[Warning] a client tried to connect with a wrong protocol (server: %s client: %s)\n", this->m_sProtocol.c_str(), protocol.c_str());

		Stream packet;

		packet.WriteInt16(OPCodes::DISCONNECT);
		packet.WriteUInt8(0);
		packet.WriteUInt32(sessionID);
		packet.WriteUInt16(Utils::DisconnectReasonProtocolMismatch);
		packet.WriteUInt16(/*XorCRCTruncated*/0);


		//TODO: - Server.RemoveClient(sender);
		//		- Send the data
	}

}

void H1Z1::HandlePacket(H1Z1::CLIENT _sender, unsigned char* _packet, size_t _size)
{
	int16_t opCode = GetOpCode(_packet); //We retrieve the opcode
	printf("%X\n", opCode);
	if (!_sender.HasSession()) //verify if the user has a session
	{
		if (opCode != OPCodes::SESSION_REQUEST)
		{
			// TODO: Handle this to avoid DoS attacks
			return;
		}
	}

	switch (opCode)
	{
	case OPCodes::SESSION_REQUEST:
		HandleSessionRequest(_sender, _packet, _size);
		break;
	case OPCodes::MULTI:

		break;
	case OPCodes::DISCONNECT:
		HandleDisconnect(_sender, _packet, _size);
		break;
	case OPCodes::PING:

		break;
	case OPCodes::RELIABLE_DATA:

		break;
	case OPCodes::FRAGMENTED_RELIABLE_DATA:
		//TODO: Handle it, this is the next step
		HandleFragmentedReliableData(_sender, _packet, _size);

		break;
	case OPCodes::ACK_RELIABLE_DATA:
		//sender.DataChannel.Receive(packet);
		break;

	default:
		printf("Received Unknown packet %d!\n", opCode);
		break;
	}
}

int16_t H1Z1::GetOpCode(unsigned char* _packet)
{
	Stream packet(_packet, sizeof _packet);
	
	return packet.ReadInt16();
}

void H1Z1::HandleFragmentedReliableData(CLIENT _sender, unsigned char* _packet, size_t _size)
{
	Utils::Hexdump(_packet, _size);
	throw std::logic_error("The method or operation is not implemented.");
}

H1Z1* H1Z1::GetInstance()
{
	if (!m_pInstance)
		m_pInstance = new H1Z1();

	return m_pInstance;
}