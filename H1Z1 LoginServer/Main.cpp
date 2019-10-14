#define WIN32_LEAN_AND_MEAN 
#include "httplib.hpp"

#include <Windows.h>
#include "Header.hpp"
#include "TempStuff.hpp"
#include "UdpServer.hpp"
#include "Stream.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

std::clock_t start;
DWORD WINAPI m_httpserver(LPVOID arg);

void ApplicationClosing()
{
	std::map<int, H1Z1::CLIENT*>::iterator it = H1Z1::GetInstance()->clientList.begin();

	while (it != H1Z1::GetInstance()->clientList.end())
	{
		auto sessionID = it->first;

		H1Z1::CLIENT* count = it->second;

		H1Z1::GetInstance()->KickSession(sessionID);

		// Increment the Iterator to point to next entry
		it++;
	}

	Sleep(4000);
	return;
}

int main()
{
	start = std::clock();

	H1Z1::GetInstance()->Init();

	auto m_LoginServer = std::make_shared< c_udp_server >(H1Z1::GetInstance()->m_sLoginServerAddress, H1Z1::GetInstance()->m_dLoginServerPort);
	auto m_GatewayServer = std::make_shared< c_udp_server >(H1Z1::GetInstance()->m_sGatewayServerAddress, H1Z1::GetInstance()->m_dGatewayPort);
	//auto m_ZoneServer = std::make_shared< c_udp_server >(H1Z1::GetInstance()->m_sServerAddress, H1Z1::GetInstance()->m_dZonePort);
	auto m_HTTPServer = CreateThread(NULL, 0, m_httpserver, 0, 0, 0);

	switch (m_LoginServer->setup())
	{
	case 0:
		printf("[LoginServer] INVALID_SOCKET\n");
		break;
	case 1:
		printf("[LoginServer] SOCKET_ERROR\n");
		break;
	default:
		printf("[LoginServer] Server set up on port %d\n", H1Z1::GetInstance()->m_dLoginServerPort);
	}

	switch (m_GatewayServer->setup())
	{
	case 0:
		printf("[GatewayServer] INVALID_SOCKET\n");
		break;
	case 1:
		printf("[GatewayServer] SOCKET_ERROR\n");
		break;
	default:
		printf("[GatewayServer] Server set up on port %d\n", H1Z1::GetInstance()->m_dGatewayPort);
	}

// 	switch (m_ZoneServer->setup())
// 	{
// 	case 0:
// 		printf("[ZoneServer] INVALID_SOCKET\n");
// 		break;
// 	case 1:
// 		printf("[ZoneServer] SOCKET_ERROR\n");
// 		break;
// 	default:
// 		printf("[ZoneServer] Server set up\n");
// 	}

	printf("\n\n");

	while (true) {
		m_LoginServer->listen();
		m_GatewayServer->listen();
// 		m_ZoneServer->listen();
	}
}

DWORD WINAPI m_httpserver(LPVOID arg)
{
	httplib::Server svr;

	svr.Get("/", [](const httplib::Request & req, httplib::Response & res) {
		const char json[] = "{\"Uptime\":0,\"Clients\":0,\"Zones\":0,\"Maintenance\":{\"Mode\":false,\"Reason\":\"Server is being updated.\"}}";

		rapidjson::Document document;

		document.Parse(json);
		assert(document.IsObject());
		const rapidjson::Value& Maintenance = document["Maintenance"];
		assert(Maintenance.IsObject());

		//Update the server info api

		document["Uptime"].SetFloat((std::clock() - start) / (double)CLOCKS_PER_SEC);
		document["Clients"].SetInt(H1Z1::GetInstance()->clientList.size());
		document["Zoneservers"].SetInt(0);

		//printf("reason: %s\n", attributes["Reason"].GetString());
		rapidjson::StringBuffer buffer;
		rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
		document.Accept(writer);

		res.set_content(buffer.GetString(), "text/plain");
	});


	svr.listen(H1Z1::GetInstance()->m_sLoginServerAddress.c_str(), H1Z1::GetInstance()->m_dHTTPPort);
	return 0;
}
