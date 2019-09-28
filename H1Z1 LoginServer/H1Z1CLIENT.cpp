#include "H1Z1.hpp"

bool H1Z1::CLIENT::HasSession()
{
	return this->SessionStarted;
}

uint16_t H1Z1::CLIENT::GetCRCLength() 
{
	return this->CRCLength;
}

uint16_t H1Z1::CLIENT::GetSessionID()
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
	// Set our last interaction so we don't get destroyed
	LastInteraction = 0;
}

void H1Z1::CLIENT::StartSession(uint16_t _crcLength, uint16_t _sessionId, uint16_t _udpBufferSize)
{
	// Generate a CRC Seed for this session
	this->CRCSeed = std::rand();

	// Session variables
	this->CRCLength = _crcLength;
	this->SessionID = _sessionId;
	this->BufferSize = _udpBufferSize;
	this->SessionStarted = true;

	Compressable = true;
	Encryptable = false;
	Encrypted = false;
}