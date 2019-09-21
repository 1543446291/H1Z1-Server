#include <Windows.h>
class c_h1z1_loginserver
{
public:

	//void SendData(std::string data);
	void OnMessage(SOCKET socket, struct sockaddr_in client_information, int client_lenght, unsigned char* received_data, int received_bytes);

	SOCKET _socket;
	int _length;
	struct sockaddr* _information;
	unsigned char* _buffer;
};