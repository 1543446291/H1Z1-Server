#pragma once
#include <Windows.h>
#include <iostream>
#include <string_view>
#include <string_view>

class H1Z1 {
public:

	class CLIENT_INFO {
	public:
		std::string sName;
		int16_t nId;
	};

	/*
		Function:	 Hexdump
		Description: Print the hex dump of a buffer.
	*/
	void Hexdump(void* ptr, int buflen)
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
		Function:	 GetDataBetween
		Description: Create a new array with a specific start and end based on an existing array.
	*/
	unsigned char* GetDataBetween(unsigned char* original, int start_index, int num_of_bytes_to_copy)
	{
		unsigned char* data = 0;

		memcpy(data, original + start_index, num_of_bytes_to_copy);
		return data;
	}

	/*
		Function:	 IsClientProtocolSupported
		Description: Check the client UDP protocol version.
	*/
	bool IsClientProtocolSupported(unsigned char* data)
	{
		std::string serverProtocol(SupportedProtocol); // retrieve the server protocol version
		memcpy(data, data + 14, 10);

		std::string clientProtocol(reinterpret_cast<char*>(data));

		std::size_t found = serverProtocol.find(clientProtocol);
		if (serverProtocol.compare(clientProtocol) == 0)
			return true;
		else
			return false;
	}

private:

};