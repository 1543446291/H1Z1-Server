/*
	Credit to Chris, Joshsora for his project on github (LibSOE) and Jacob S for his work.
*/

#include <Windows.h>
#include "Header.hpp"
#include "TempStuff.hpp"
#include "UdpServer.hpp"
#include "Stream.h"

int main()
{
	H1Z1::CLIENT a;
	H1Z1::GetInstance()->Init();

	auto m_server = std::make_shared< c_udp_server >(H1Z1::GetInstance()->m_sServerAddress, H1Z1::GetInstance()->m_dServerPort);

	switch (m_server->setup())
	{
	case 0:
		printf("[Error] INVALID_SOCKET\n");
		break;
	case 1:
		printf("[Error] SOCKET_ERROR\n");
		break;
	default:
		printf("[Info] Server set up\n");
	}

	while (true)
		m_server->listen();
}