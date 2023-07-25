#define SERVER_ONLY

#include "ArenaCommon.as";

ArenaInstance@[] Arena;
ArenaPlayer@[] new_queue; // new players who didn't play last round
ArenaPlayer@[] priority_queue; // players who played last round

void onInit(CRules@ this)
{
	if (!this.exists("default class"))
	{
		this.set_string("default class", "knight");
	}
}

void onTick(CRules@ this)
{
	if (getPlayersCount() < 2)
	{
		this.SetGlobalMessage("Not enough players to start arena!");
	}
	else
	{
		this.SetGlobalMessage("");
	}

	if (Arena.length() <= 0 && priority_queue.length() + new_queue.length() >= 2)
	{
		startArena();
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	player.server_setTeamNum(this.getSpectatorTeamNum());

	new_queue.push_back(ArenaPlayer(player.getUsername(), 0));

}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	// delete the blob (corpse)
	CBlob@ blob = victim.getBlob();
	if (blob !is null)
	{
		blob.server_Die();
	}

	onPlayerLost(this, victim);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	bool is_new = false;
	for(u8 i = 0; i < new_queue.length(); i++)
	{
		if (new_queue[i].username == player.getUsername())
		{
			new_queue.removeAt(i);
			is_new = true;
			break;
		}
	}

	if (!is_new)
	{
		onPlayerLost(this, player, true);
	}
}

void onPlayerLost(CRules@ this, CPlayer@ player, bool leaver = false)
{
	if (player is null)
		return;
		
	bool active_match = false;
	for(u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];

		for (u8 j = 0; j < instance.players.length(); j++)
		{
			if (instance.players[j].username == player.getUsername())
			{
				if (instance.ongoing)
				{
					s8 victim = j;

					instance.FinishMatch(instance.players[1 - victim], instance.players[victim]);
				}

				if (leaver)
					instance.players.removeAt(j);
			}
		}

		if (instance.ongoing)
			active_match = true;
	}
	
	if (!active_match)
	{
		endArena();
	}
}

void populateFromQueue(ArenaPlayer@[]@ &in queue)
{
	if (queue.length() <= 0)
		return;

	for(u8 i = 0; i < Arena.length(); i++)
	{
		while (Arena[i].canAddPlayer() && queue.length() > 0)
		{
			ArenaPlayer@ player = queue[0];
			player.arena_weight = i;
			Arena[i].AddPlayer(player);

			CPlayer@ p = getPlayerByUsername(player.username);
			if (p !is null)
			{
				p.set_u8("current_arena", i);
			}

			queue.removeAt(0);

			if (queue.length() <= 0)
				break;
		}

	}
}

void startArena()
{
	setupArena();

	populateFromQueue(@priority_queue);
	populateFromQueue(@new_queue);

	for(u8 i = 0; i < Arena.length(); i++)
	{
		Arena[i].StartMatch();
	}
}

void endArena()
{
	// add all players to priority queue
	for(u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];

		for(u8 j = 0; j < instance.players.length(); j++)
		{
			ArenaPlayer@ player = instance.players[j];

			if (getPlayerByUsername(player.username) is null)
				continue;

			player.arena_weight += player.result_value;
			player.result_value = 0;
			priority_queue.push_back(player);
		}
	}

	priority_queue.sortAsc();

	Arena.clear();
}

void setupArena()
{
	CMap@ map = getMap();

	CBlob@[] ruins;
	if (!getBlobsByName("tdm_spawn", ruins))
	{
		return;
	}

	u8 max_arenas_needed = (1 + priority_queue.length() + new_queue.length()) / 2;
	u8 max_arenas = ruins.length() / 2;

	if (max_arenas_needed < max_arenas)
		max_arenas = max_arenas_needed;

	print("max arenas: " + max_arenas);

	for(u8 i = 0; i < max_arenas; i++)
	{
		Arena.push_back(ArenaInstance(i));
	}

	for(u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];

		for(u8 j = 0; j < ruins.length(); j++)
		{
			if (instance.id == ruins[j].get_u8("level"))
			{
				print ("adding arena " + i + " spawn (ruins " + j + ")");
				instance.AddSpawn(ruins[j].getPosition());
			}
		}
	}
}