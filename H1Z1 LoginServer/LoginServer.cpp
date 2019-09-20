#include "DisconnectReasons.hpp"
#include "ClientState.hpp"
#include "LoginServer.hpp"
#include "H1Z1.hpp"

H1Z1 hServer;

#define Packet unsigned char
Packet LoginRequestPattern[] = { 0x00, 0x01, 0x00, 0x00, 0x00 ,0x03 };
Packet LoginReply[] = { 0x00, 0x02, 0x99, 0x99, 0x99 ,0x99, 0x98,0x98, 0x98, 0x98, 0x02, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x03 };

bool Send(SOCKET a, const char* b, const sockaddr *c, int d) {
	sendto(a, (const char*)b, sizeof(b),
		0, (const struct sockaddr*) & c,
		d);
		return true;
}

void c_h1z1_loginserver::OnMessage(SOCKET socket, struct sockaddr_in client_information, int client_lenght, unsigned char* received_data, int received_bytes)
{
#ifdef TESTMODE
	hServer.Hexdump((unsigned char*)received_data, received_bytes);
#endif

	std::cout << "[Server] New client " << inet_ntoa(client_information.sin_addr) << std::endl;

	if (hServer.IsClientProtocolSupported(received_data)) { // Checking if the client game version is supported
		std::cout << "[Server] Client version correct" << std::endl;
	}
	else 
	{
		std::cout << "[Server] Client version incorrect, disconnecting the client" << std::endl;
		if (closesocket(socket)) // Disconnect the client here
			std::cout << "[Server] Disconnected the client." << std::endl;
		else
			std::cout << "[Server] Error!" << std::endl;
		
		return;
	}

	// Here we handle the received data from the client
	if (hServer.IsEqual(LoginRequestPattern, received_data)) { // Checking if the data looks like the Connection Request pattern

		std::cout << "[Client] Connection request from " << inet_ntoa(client_information.sin_addr) << std::endl;
		std::cout << "[Server] Sending a reply to " << inet_ntoa(client_information.sin_addr) << std::endl;

		// Seems like the game generate a UUID or a key used to identify him on the server-side, here it is
		LoginReply[2] = received_data[6];
		LoginReply[3] = received_data[7];
		LoginReply[4] = received_data[8];
		LoginReply[5] = received_data[9];

		//Now we reply to the client with his identifier
		if (sendto(socket, (const char*)LoginReply, sizeof(LoginReply), 0, (const struct sockaddr*) & client_information, client_lenght))
			std::cout << "[Server] Reply sent to " << inet_ntoa(client_information.sin_addr) << std::endl;
	}
}
