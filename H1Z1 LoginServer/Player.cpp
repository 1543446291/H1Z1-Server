#include "Player.hpp"

Player::Player()
{
	_address = std::string("0.0.0.0");
	_protocol = std::string("LoginUdp_");
	_ping = 0.f;
}

Player::Player(std::string address, std::string protocol)
{
	_address = address;
	_protocol = protocol;
}

void Player::SetProtocol(std::string protocol)
{
	_protocol = protocol;
}

float Player::GetPing()
{
	return _ping;
}

