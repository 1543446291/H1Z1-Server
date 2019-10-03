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
	std::atexit(ApplicationClosing);

	start = std::clock();

	H1Z1::GetInstance()->Init();

	auto m_server = std::make_shared< c_udp_server >(H1Z1::GetInstance()->m_sServerAddress, H1Z1::GetInstance()->m_dServerPort);
	auto m_HTTPServer = CreateThread(NULL, 0, m_httpserver, 0, 0, 0);

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
		document["Clients"].SetInt(H1Z1::GetInstance()->clientList.size());
		document["Zoneservers"].SetInt(0);

		//printf("reason: %s\n", attributes["Reason"].GetString());
		rapidjson::StringBuffer buffer;
		rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
		document.Accept(writer);

		res.set_content(buffer.GetString(), "text/plain");
	});


	svr.listen(H1Z1::GetInstance()->m_sServerAddress.c_str(), H1Z1::GetInstance()->m_dHTTPPort);
	return 0;
}
