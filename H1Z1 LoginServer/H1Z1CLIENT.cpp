#include "H1Z1.hpp"
#include "Stream.h"

bool H1Z1::CLIENT::HasSession()
{
	return this->SessionStarted;
}

unsigned long H1Z1::CLIENT::GetSessionID()
{
	return this->SessionID;
}

uint16_t H1Z1::CLIENT::GetBufferSize()
{
	return this->BufferSize;
}

uint16_t H1Z1::CLIENT::GetCRCSeed()
{
	return this->CRCSeed;
}

bool H1Z1::CLIENT::IsEncrypted()
{
	return this->Encrypted;
}

void H1Z1::CLIENT::SetEncryptable(bool _encryptable)
{
	Encryptable = _encryptable;
}

void H1Z1::CLIENT::ToggleEncryption()
{
	if (Encryptable)
	{
		Encrypted = !Encrypted;
	}
}

bool H1Z1::CLIENT::IsCompressable()
{
	return this->Compressable;
}

void H1Z1::CLIENT::SetCompressable(bool _compressable)
{
	Compressable = _compressable;
}

int H1Z1::CLIENT::GetLastInteraction()
{
	return LastInteraction;
}

void H1Z1::CLIENT::Interact()
{
	LastInteraction = std::time(nullptr);;
}

void H1Z1::CLIENT::StartSession(unsigned long _sessionId, uint16_t _udpBufferSize)
{
	printf("[Info] session started for {%X}\n", _sessionId);
	// Generate a CRC Seed for this session
	this->CRCSeed = std::rand();

	// Session variables
	this->SessionID = _sessionId;
	this->BufferSize = _udpBufferSize;
	this->LastInteraction = std::time(nullptr); //unix timestamp
	this->SessionStarted = true;

	Compressable = true;
	Encryptable = false;
	Encrypted = false;
}