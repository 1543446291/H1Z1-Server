#define WIN32_LEAN_AND_MEAN 
#include "httplib.h"
#include "Settings.hpp"

#include <Windows.h>
#include <iostream>
#include <memory>
#include "Header.hpp"
#include "jsonlib.hpp"
#include "H1Z1.hpp"
std::clock_t start;


DWORD WINAPI m_httpserver(LPVOID arg)
{
	httplib::Server svr;

	svr.Get("/", [](const httplib::Request & req, httplib::Response & res) {
		json::JSON tempObject;
		tempObject["server"] = json::Object();
		tempObject["server"]["uptime"] = (std::clock() - start) / (double)CLOCKS_PER_SEC;
		tempObject["server"]["onlineclients"] = H1Z1::GetInstance()->_onlineclients;
		tempObject["server"]["clients"] = 0;
		tempObject["server"]["zoneservers"] = H1Z1::GetInstance()->_zoneservers;

		std::ostringstream stringStream;
		stringStream << tempObject << std::endl;

		res.set_content(stringStream.str(), "text/plain");
	});

	svr.Get("/servers", [](const httplib::Request & req, httplib::Response & res) {
		res.set_content("Hello World!", "text/plain");
	});

	svr.listen(ServerAddress, HttpPort);
	return 0;
}

int main()
{
	start = std::clock();
	LOG_SCOPE_FUNCTION(INFO);

	//LOG_SCOPE_F(INFO, "Hello world");
	SetConsoleTitleA("H1Z1 LoginServer");

	auto m_server = std::make_shared< c_udp_server >(ServerAddress, ServerPort);
	HANDLE th = CreateThread(NULL, 0, m_httpserver, 0, 0, 0);

	if (!m_server->setup())
	{
		WSACleanup();
		LPSTR errString = NULL;
		FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, 0, WSAGetLastError(), 0, (LPSTR)& errString, 0, 0);

		LOG_F(ERROR, "[Winsock] %s", errString);
		LocalFree(errString);
		getchar();
		return false;
	}


	while (true)
		m_server->listen();
}