#pragma once

#include <Windows.h>
#include <iostream>
#include "Settings.hpp"
#include <string_view>

class H1Z1 {
	public:

	class CLIENT_INFO {
	public:
		std::string sName;
		int16_t nId;
	};

	bool Init(SOCKET a, unsigned char* b)
	{
		_socket = a;
		_buffer = b;

		return true;
	}
	/*
		Function:	 Hexdump
		Description: Print the hex dump of a buffer.
	*/
	void Hexdump(unsigned char* ptr, int buflen);

	/*
		Function:	 IsEqual
		Description: Check if the data contain the pattern.
	*/
	bool IsEqual(const void* pattern, const void* data);

	/*
		Function:	 IsClientProtocolSupported
		Description: Check the client UDP protocol version.
	*/

	bool IsClientProtocolSupported();

	unsigned char* _buffer;
	unsigned char* _copybuffer;
	SOCKET _socket;
	int _onlineclients = 0;
	int _zoneservers = 0;

	static H1Z1* GetInstance();

private:
	H1Z1();
	~H1Z1();

	static H1Z1* m_pInstance;
};