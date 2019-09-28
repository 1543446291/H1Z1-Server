#ifndef TYPEDEFS_H
#define TYPEDEFS_H


#include <vector>

#define  WIN32_LEAN_AND_MEAN

#define uint8 unsigned char

#define uint16 unsigned short

#define uint32 unsigned long

#define uint64 unsigned long long

#define int8 char

#define int16 short

#define int32 long

#define int64 long long

#define STRING const char*

#define ulong unsigned long

#define uint unsigned int

#define byte unsigned char

#define entityId uint64

#define wchar uint16

#define NAME_MAX 128

#define CONTINENT_NAME_MAX 64

#define slot_id uint32
#define item_eid uint64
#define item_id uint32

#ifndef WINAPI
#define WINAPI __stdcall
#endif

#define WORLD_STATE ulong

#define STACK_WHOLE 1
#define STACK_FRAGMENT 0


#define broadcast_clients	std::vector<uint32>
#define spawn_players_list	std::vector<uint32> 
#define player_list			std::vector<std::shared_ptr<player>>
#define visible_clusters	std::vector<std::shared_ptr<area_cluster>>
#define visible_zones		std::vector<std::shared_ptr<zone>>


#include <atomic>
#define a_load(x) x.load(std::memory_order_relaxed) 
#define a_store(x,v) x.store(v,std::memory_order_relaxed)

#include <memory>
class player;
#define p_ptr std::shared_ptr<player>

#endif // !TYPEDEFS_H
