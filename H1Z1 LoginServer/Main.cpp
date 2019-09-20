#include <Windows.h>
#include <iostream>
#include <memory>
#include "Header.hpp"

const std::string g_ip = "127.0.0.1";
const int g_port = 20042;

int main()
{

	SetConsoleTitleA("H1Z1 LoginServer");

	auto m_server = std::make_shared< c_udp_server >(g_ip, g_port);

	if (!m_server->setup())
	{
		WSACleanup();
		std::cout << "Can't setup the server!" << std::endl;
		system("pause");
		return false;
	}

	while (true)
		m_server->listen();
}