#define WIN32_LEAN_AND_MEAN 
#include "httplib.h"
#include "Settings.hpp"

#include <Windows.h>
#include <iostream>
#include <memory>
#include "Header.hpp"
#include "H1Z1.hpp"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include <iostream>

std::clock_t start;
std::string servers;

DWORD WINAPI m_httpserver(LPVOID arg)
{
	httplib::Server svr;

	svr.Get("/", [](const httplib::Request & req, httplib::Response & res) {
		const char json[] = "{\"Uptime\":0,\"Clients\":0,\"Zoneservers\":0,\"Maintenance\":{\"Mode\":false,\"Reason\":\"Server is being updated.\"}}";
		
		rapidjson::Document document;

		document.Parse(json);
		assert(document.IsObject());
		const rapidjson::Value& Maintenance = document["Maintenance"];
		assert(Maintenance.IsObject());

		//Update the server info api

		document["Uptime"].SetFloat((std::clock() - start) / (double)CLOCKS_PER_SEC);
		document["Clients"].SetInt(H1Z1::GetInstance()->_onlineclients);
		document["Zoneservers"].SetInt(H1Z1::GetInstance()->_zoneservers);

		//printf("reason: %s\n", attributes["Reason"].GetString());
		rapidjson::StringBuffer buffer;
		rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
		document.Accept(writer);

		res.set_content(buffer.GetString(), "text/plain");
	});

	svr.Get("/servers", [](const httplib::Request & req, httplib::Response & res) {
		res.set_content(servers.c_str(), "text/plain");
	});

	svr.listen(ServerAddress, HttpPort);
	return 0;
}

int main()
{
	start = std::clock(); //start the uptime timer (store the actual time into start)
	std::ifstream t("servers.json");
	std::string _servers((std::istreambuf_iterator<char>(t)),
		std::istreambuf_iterator<char>());
	servers.assign(_servers);

	auto m_server = std::make_shared< c_udp_server >(ServerAddress, ServerPort);
	HANDLE th = CreateThread(NULL, 0, m_httpserver, 0, 0, 0);

	if (!m_server->setup())
	{
		LPSTR errString = NULL;
		FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, 0, WSAGetLastError(), 0, (LPSTR)& errString, 0, 0);

		LOG_F(ERROR, "[Winsock] %s", errString);
		LocalFree(errString);

		WSACleanup();
		getchar();
		return false;
	}


	while (true)
		m_server->listen();
}