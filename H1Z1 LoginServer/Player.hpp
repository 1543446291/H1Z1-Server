#pragma once
#include <string>

class Player
{
private:
	std::string _address;
	std::string _protocol;
	float _ping;

public:
	Player();
	const Player(std::string address, std::string protocol);
	Player(Player const& other);
	~Player();

	bool IsAlive();

	float GetPing();

	void SetProtocol(std::string protocol);
};