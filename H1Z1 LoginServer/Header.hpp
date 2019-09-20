#pragma once
#include <Windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include <sys/types.h>
#include <sstream>
#include <iomanip>
#include "loguru.hpp"
#include "LoginServer.hpp"

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
	std::shared_ptr<c_h1z1_loginserver> m_h1z1 = std::make_shared< c_h1z1_loginserver >();

	bool setup()
	{
		if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0)
			return false;

		LOG_F(INFO, "Windows connection established.");

		datagram_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
		if (datagram_socket == INVALID_SOCKET)
			return false;

		LOG_F(INFO, "Socket created.");

		memset((void*)& socket_information, '\0', sizeof(struct sockaddr_in));

		socket_information.sin_family = AF_INET;
		socket_information.sin_port = htons(port);
		socket_information.sin_addr.S_un.S_addr = inet_addr(ip.c_str());

		if (bind(datagram_socket, (struct sockaddr*) & socket_information, sizeof(struct sockaddr_in)) == SOCKET_ERROR)
			return false;

		LOG_F(INFO, "IP binded.");

		return true;
	}

	void listen()
	{
		memset(buffer, '\0', sizeof(buffer)); // Clear the buffer before getting the next message

		static int client_length = sizeof(struct sockaddr_in); // Don't need to do this each time

		received_bytes = recvfrom(datagram_socket, (char*)buffer, max_buffer_length, 0, (struct sockaddr*) & client_information, &client_length);

		if (received_bytes > 0) // Data received, handle it
		{
			m_h1z1->_socket = datagram_socket;
			m_h1z1->_length = client_length;
			m_h1z1->_information = (struct sockaddr*) & client_information;
			m_h1z1->_buffer = (unsigned char*)buffer;

			m_h1z1->OnMessage(datagram_socket, client_information, client_length, (unsigned char*)buffer, received_bytes);
		}
	}

private:

	std::string ip;
	int port;

	WSAData wsa_data;

	SOCKET datagram_socket;

	struct sockaddr_in socket_information;
	struct sockaddr_in client_information;

	int received_bytes;

	char buffer[max_buffer_length];

};