#pragma once
#include <Windows.h>
#include <iostream>
#include "Pattern.hpp"
#include "Reply.hpp"
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
		this->_socket = a;
		this->_buffer = b;

		return true;
	}
	/*
		Function:	 Hexdump
		Description: Print the hex dump of a buffer.
	*/
	void Hexdump(unsigned char* ptr, int buflen)
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

	/*
		Function:	 IsEqual
		Description: Check if the data contain the pattern.
	*/
	bool IsEqual(const void* pattern, const void* data)
	{
		return (memcmp(pattern, data, sizeof(pattern)) == 0);
	}

	/*
		Function:	 IsClientProtocolSupported
		Description: Check the client UDP protocol version.
	*/

	bool IsClientProtocolSupported()
	{
		_copybuffer = _buffer;

		std::string serverProtocol(SupportedProtocol); // retrieve the server protocol version
		memcpy(_copybuffer, _buffer + 14, 10); //TODO: make this cleaner (locate the complete protocol version string)
		std::string clientProtocol(reinterpret_cast<char*>(_copybuffer)); // retrieve the client protocol version
		std::size_t found = serverProtocol.find(clientProtocol);
		if (serverProtocol.compare(clientProtocol) == 0) {
			_copybuffer = NULL;
			return true;
		}
		else {
			return false;
		}
	}

private:
	unsigned char* _buffer;
	unsigned char* _copybuffer;
	SOCKET _socket;
};