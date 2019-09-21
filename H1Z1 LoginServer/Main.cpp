#define WIN32_LEAN_AND_MEAN 
#include "httplib.h"

#include <Windows.h>
#include <iostream>
#include <memory>
#include "Header.hpp"


const std::string g_ip = "127.0.0.1";
const int g_port = 20042;
const int g_portapi = 8080;

DWORD WINAPI LoginServerAPI(LPVOID arg)
{
	httplib::Server svr;

	svr.Get("/hi", [](const httplib::Request & req, httplib::Response & res) {
		res.set_content("Hello World!", "text/plain");
	});

	svr.Get("/stop", [&](const httplib::Request & req, httplib::Response & res) {
		svr.stop();
	});

	svr.listen(g_ip.c_str(), g_portapi);
	return 0;
}

int main()
{
	//LOG_SCOPE_F(INFO, "Hello world");
	SetConsoleTitleA("H1Z1 LoginServer");

	auto m_server = std::make_shared< c_udp_server >(g_ip, g_port);
	HANDLE th = CreateThread(NULL, 0, LoginServerAPI, 0, 0, 0);

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