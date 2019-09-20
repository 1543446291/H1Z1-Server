#include <Windows.h>
#include <iostream>
#include <memory>
#include "Header.hpp"

const std::string g_ip = "127.0.0.1";
const int g_port = 20042;

int main()
{
	//LOG_SCOPE_F(INFO, "Hello world");
	SetConsoleTitleA("H1Z1 LoginServer");

	auto m_server = std::make_shared< c_udp_server >(g_ip, g_port);

	if (!m_server->setup())
	{
		WSACleanup();
		LOG_F(ERROR, "[Winsock] error");
		system("pause");
		return false;
	}


	while (true)
		m_server->listen();
}