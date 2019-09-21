#include "H1Z1.hpp"

H1Z1* H1Z1::m_pInstance;

H1Z1::H1Z1()
{
}

H1Z1::~H1Z1()
{
}

void H1Z1::Hexdump(unsigned char* ptr, int buflen)
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

bool H1Z1::IsEqual(const void* pattern, const void* data)
{
	return (memcmp(pattern, data, sizeof(pattern)) == 0);
}

bool H1Z1::IsClientProtocolSupported()
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

H1Z1* H1Z1::GetInstance()
{
	if (!m_pInstance)
		m_pInstance = new H1Z1();

	return m_pInstance;
}