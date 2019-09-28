#include "Stream.h"


Stream::Stream()
{
	_raw = 0;
	_size = 0;
	_pos = 0;
}

Stream::Stream(std::istream* str)
{
	str->seekg(0, std::istream::end);
	_size = (uint32)str->tellg();
	str->seekg(0, std::istream::beg);

	_raw = new byte[_size];
	str->read((char*)_raw, _size);
	_pos = 0;
}

Stream::Stream(uint16 size)
{
	_size = size;
	_raw = (byte*)malloc(size);
	memset((void*)_raw, 0, _size);
	_pos = 0;
}

Stream::Stream(byte* data, uint16 size)
{
	_size = size;
	_pos = 0;
	_raw = new byte[_size];
	if (memcpy_s((void*)_raw, _size, (const void*)data, _size) != 0)
	{
		if (_raw)
		{
			delete[] _raw;
			_raw = 0;

		}
		return;
	}
}

Stream::Stream(Stream& d)
{
	_size = _pos = 0;
	_raw = nullptr;

	Resize(d._size);
	Write(d._raw, d._size);
}

Stream::~Stream()
{
	if (_raw)
	{
		delete[] _raw;
		_raw = 0;
	}
	_size = 0;
	_pos = 0;
}


//WRITE_*******************************************************
void Stream::Resize(uint16 size)
{
	if (size <= 0 || _size + size > (uint16)STREAM_MAX_SIZE)
		return;

	if (!_raw)
	{
		_raw = new byte[size];
		_size = size;
		memset((void*)_raw, 0, _size);
	}
	else
	{
		uint16 newSize = _size + size;
		byte* newRaw = (byte*)realloc((void*)_raw, newSize);

		memset((void*)& newRaw[_size], 0, size);
		_size = newSize;
		_raw = newRaw;
	}
}

void Stream::Write(byte* data, uint16 size)
{
	if (_size + size > (uint16)STREAM_MAX_SIZE) //0xffff because the packets header has only 2 bytes [00 00] for the size
		return;

	int16 allocSzie = size - _size + _pos;

	if (allocSzie > 0)
		Resize(allocSzie);

	if (memcpy_s((void*)& _raw[_pos], size, (const void*)data, size) != 0) return;


	if (allocSzie > 0)
	{
		_pos = _size;
	}
	else {
		_pos += size;
	}
}

void Stream::WriteString(std::string s, bool reverse)
{
	byte* data = new byte[s.size() * 2];
	byte* pos = &data[0];

	for (size_t i = 0; i < s.size(); i++)
	{
		if (!reverse)
		{
			pos[0] = (byte)s[i];
			pos[1] = 0x00;
		}
		else
		{
			pos[1] = (byte)s[i];
			pos[0] = 0x00;
		}
		pos += 2;
	}

	Write(data, (uint32)(s.size() * 2));
	WriteInt16(0); // string end
}

void Stream::WriteUInt8(byte val)
{
	Write(&val, 1);
}

void Stream::WriteInt16(int16 data)
{
	byte shortBytes[2];
	shortBytes[1] = (data & 0xff);
	shortBytes[0] = ((data >> 8) & 0xff);

	Write(shortBytes, 2);
}

void Stream::WriteUInt16(uint16 val)
{
	byte shortBytes[2];
	shortBytes[1] = (val & 0xff);
	shortBytes[0] = ((val >> 8) & 0xff);
	Write(shortBytes, 2);
}

void Stream::WriteInt32(int32 data)
{
	byte intBytes[4];
	intBytes[3] = data & 0x000000ff;
	intBytes[2] = (data & 0x0000ff00) >> 8;
	intBytes[1] = (data & 0x00ff0000) >> 16;
	intBytes[0] = (data & 0xff000000) >> 24;

	Write(intBytes, 4);
}

void Stream::WriteUInt32(int32 data)
{
	byte intBytes[4];
	intBytes[3] = data & 0x000000ff;
	intBytes[2] = (data & 0x0000ff00) >> 8;
	intBytes[1] = (data & 0x00ff0000) >> 16;
	intBytes[0] = (data & 0xff000000) >> 24;

	Write(intBytes, 4);
}

void Stream::WriteInt64(int64 data)
{
	byte intBytes[8];

	intBytes[7] = ((data >> 0) & 0xff);
	intBytes[6] = ((data >> 8) & 0xff);
	intBytes[5] = ((data >> 16) & 0xff);
	intBytes[4] = ((data >> 24) & 0xff);
	intBytes[3] = ((data >> 32) & 0xff);
	intBytes[2] = ((data >> 40) & 0xff);
	intBytes[1] = ((data >> 48) & 0xff);
	intBytes[0] = ((data >> 56) & 0xff);

	Write(intBytes, 8);
}

void Stream::WriteUInt64(uint64 data)
{
	byte intBytes[8];

	intBytes[7] = ((data >> 0) & 0xff);
	intBytes[6] = ((data >> 8) & 0xff);
	intBytes[5] = ((data >> 16) & 0xff);
	intBytes[4] = ((data >> 24) & 0xff);
	intBytes[3] = ((data >> 32) & 0xff);
	intBytes[2] = ((data >> 40) & 0xff);
	intBytes[1] = ((data >> 48) & 0xff);
	intBytes[0] = ((data >> 56) & 0xff);

	Write(intBytes, 8);
}

void Stream::WriteFloat(float val)
{
	Write(reinterpret_cast<byte*>(&val), 4);
}

void Stream::WriteDouble(double val)
{
	byte* doubleBytes = reinterpret_cast<byte*>(&val);
	Write(doubleBytes, 4);
}

void Stream::Read(byte * out_buffer, uint16 size)
{
	if (size > _size - _pos)
	{
		int16 temp = (_size - _pos);

		memcpy_s((void*)out_buffer, size, (const void*)& _raw[_pos], temp);
		_pos = temp;

		return;
	}
	memcpy_s((void*)out_buffer, size, (const void*)& _raw[_pos], size);
	_pos += size;
}

char Stream::ReadInt8()
{
	return _raw[_pos++];
}

byte Stream::ReadUInt8()
{
	return _raw[_pos++];
}

int16 Stream::ReadInt16()
{
	if (_pos > _size - 2)
		return -1;

	//int16 out = (_raw[_pos + 1] << 8) | _raw[_pos];
	int16 out = (_raw[_pos] << 8) | _raw[_pos + 1];
	_pos += 2;
	return out;

}

uint16 Stream::ReadUInt16()
{
	if (_pos > _size - 2)
		return -1;

	//uint16 out = (_raw[_pos + 1] << 8) | _raw[_pos];
	uint16 out = (_raw[_pos] << 8) | _raw[_pos + 1];
	_pos += 2;
	return out;
}

int32 Stream::ReadInt32()
{
	if (_size - 4 < _pos)
		return INT_MAX;

	//int32 out = ((_raw[_pos + 3] << 24) | (_raw[_pos + 2] << 16) | (_raw[_pos + 1] << 8) | _raw[_pos]);
	int32 out = ((_raw[_pos] << 24) | (_raw[_pos + 1] << 16) | (_raw[_pos + 2] << 8) | _raw[_pos + 3]);
	_pos += 4;

	return out;
}

uint32 Stream::ReadUInt32()
{
	if (_size - 4 < _pos)
		return INT_MAX;

	//uint32 out = ((_raw[_pos + 3] << 24) | (_raw[_pos + 2] << 16) | (_raw[_pos + 1] << 8) | _raw[_pos]);
	uint32 out = (_raw[_pos] << 24) | (_raw[_pos + 1] << 16) | (_raw[_pos + 2] << 8) | _raw[_pos + 3];

	_pos += 4;

	return out;
}

int64 Stream::ReadInt64()
{
	if (_size < _pos + 8)
		return INT64_MAX;

	int64 l = 0;
	for (uint8 i = 0; i < 8; i++) {
		l = l | ((unsigned long long)_raw[_pos + i] << (8 * i));
	}
	_pos += 8;
	return l;
}

uint64 Stream::ReadUInt64()
{
	if (_size < _pos + 8)
		return INT64_MAX;

	uint64 l = 0;
	for (uint8 i = 0; i < 8; i++) {
		l = l | ((unsigned long long)_raw[_pos + i] << (8 * i));
	}
	_pos += 8;
	return l;
}

float Stream::ReadFloat()
{
	if (_size < _pos + 4)
		return FLT_MAX;

	float out = *(float*)(&_raw[_pos]);
	_pos += 4;
	return out;
}

double Stream::ReadDouble()
{
	if (_size < _pos + 4)
		return FLT_MAX;

	double out = *(double*)(&_raw[_pos]);
	_pos += 4;
	return out;
}

std::string Stream::ReadUTF16StringBigEdianToASCII() {

	std::string out;
	int32 count = 0;
	for (size_t i = _pos; i < _size; i += 2)
	{
		if (_raw[i] == 0x00 && _raw[i + 1] == 0x00)
			break;
		count += 2;
		out.push_back(_raw[i]);
	}
	count += 2;
	_pos += count;

	return out;
}

std::string Stream::ReadASCIIString()
{
	if (_size - _pos < 1)
		return "-1";

	std::string out;
	int32 kk = 0;
	for (size_t i = _pos; i < _size; i++)
	{
		if (_raw[i] != 0x00)
		{
			if (_raw[i] != '\r' || _raw[i] != '\n')
			{
				out += (char)_raw[i];
			}
			kk++;
		}
		else
			break;
	}
	_pos += kk;
	return out;
}

bool Stream::ReadASCIIStringTo(byte * out, uint16 max_len)
{
	if (!out)
		return false;

	std::string text = ReadUTF16StringBigEdianToASCII();
	if (text.size() > max_len)
		return false;


	return memcpy(out, text.c_str(), text.size() + 1) ? true : false;
}

std::string Stream::ReadUTF16StringLittleEdianToASCII()
{
	std::string out;
	for (size_t i = _pos; i < _size; i += 2)
	{
		if (_raw[i] == 0x00 && _raw[i + 1] == 0x00)
			break;

		out.push_back(_raw[i + 1]);
	}
	_pos += (uint16)(out.size() * 2) + 2;

	return out;
}

void Stream::Clear()
{
	if (_raw)
	{
		delete[] _raw;
		_raw = 0;
	}
	_size = 0;
	_pos = 0;
}

uint16 Stream::SetEnd()
{
	_pos = _size;
	return _pos;
}

uint16 Stream::SetFront()
{
	_pos = 0;
	return 0;

}

uint16 Stream::NextPos()
{
	uint16 tempPos = _pos;
	WriteInt16(0);
	return tempPos;
}
