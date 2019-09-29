#pragma once
#include <Windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <sstream>

#pragma comment(lib, "ws2_32.lib")

const int max_buffer_length = 0x4000;

struct message_data
{
	char buffer[max_buffer_length];
	std::chrono::system_clock::time_point current_time;
};

class c_udp_server
{
public:

	c_udp_server(std::string ip, int port) { this->ip = ip; this->port = port; } // Constructor
	~c_udp_server() { closesocket(datagram_socket); } // Deconstructor

	int setup()
	{
		if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0)
			return false;

		datagram_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
		if (datagram_socket == INVALID_SOCKET)
			return 0;


		memset((void*)& socket_information, '\0', sizeof(struct sockaddr_in));

		socket_information.sin_family = AF_INET;
		socket_information.sin_port = htons(port);
		socket_information.sin_addr.S_un.S_addr = inet_addr(ip.c_str());

		if (bind(datagram_socket, (struct sockaddr*) & socket_information, sizeof(struct sockaddr_in)) == SOCKET_ERROR)
			return 1;

		return 2;
	}

	void listen()
	{
		//printf("Clients: %d\n", H1Z1::GetInstance()->clientList.size());

		memset(buffer, '\0', sizeof(buffer));

		static int client_length = sizeof(struct sockaddr_in);

		received_bytes = recvfrom(datagram_socket, (char*)buffer, max_buffer_length, 0, (struct sockaddr*) & client_information, &client_length);

		if (received_bytes > 0)
		{	
			H1Z1::GetInstance()->_socket = datagram_socket;
			H1Z1::GetInstance()->_socketsize = client_length;
			H1Z1::GetInstance()->_socketinformation = client_information;

			H1Z1::GetInstance()->HandlePacket((unsigned char*)buffer, received_bytes);
		}
	}

private:

	std::string ip;
	int port;

	WSAData wsa_data;
	int client_length;
	SOCKET datagram_socket;

	struct sockaddr_in socket_information;
	struct sockaddr_in client_information;

	int received_bytes;

	char buffer[max_buffer_length];
};