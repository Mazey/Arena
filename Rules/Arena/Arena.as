#define SERVER_ONLY

#include "ArenaCommon.as";
#include "ArenaStats.as";

ArenaInstance[] Arena;
ArenaPlayer@[] new_queue; // new players who didn't play last round
ArenaPlayer@[] priority_queue; // players who played last round

void onInit(CRules@ this)
{
	if (!this.exists("default class"))
		this.set_string("default class", "knight");

	if (!this.exists("restart_rules_after_game_time"))
		this.set_s32("restart_rules_after_game_time", cooldown);

	this.set_s32("restart_rules_after_game", getGameTime() + cooldown);

	if (!this.exists(ARENA_WINNER))
	{
		this.set_string(ARENA_WINNER, "null");
		this.Sync(ARENA_WINNER, true);
	}
	
	if (!this.exists(ARENA_WINNER_STREAK))
	{
		this.set_u16(ARENA_WINNER_STREAK, 0);
		this.Sync(ARENA_WINNER_STREAK, true);
	}

	this.addCommandID(ARENA_UPDATE_INT_ID);
	this.addCommandID(ARENA_DESTROY_INT_ID);
	this.addCommandID(ARENA_WINNER_INT_ID);
}

void onTick(CRules@ this)
{
	bool arena_active = (Arena.length() > 0);

	if (getPlayersCount() < 2)
	{
		this.SetGlobalMessage("Not enough players to start arena!");
	}
	else
	{
		this.SetGlobalMessage("");
	}
	
	if (arena_active)
	{
		if (getGameTime() % 30 == 0)
			this.set_s32("restart_rules_after_game", getGameTime() + this.get_s32("restart_rules_after_game_time"));

		bool active_match = false;
		for(u8 i = 0; i < Arena.length(); i++)
		{
			ArenaInstance@ instance = Arena[i];

			if (instance.ongoing)
				active_match = true;
		}
		
		if (!active_match)
		{
			endArena();
		}
	}
	else
	{
		if (priority_queue.length() + new_queue.length() >= 2)
		{
			s32 timeToEnd = this.get_s32("restart_rules_after_game") - getGameTime();

			if (timeToEnd > 0)
			{
				this.SetGlobalMessage("Next arena in " + (timeToEnd / 30) + " seconds");
			}
			else
			{
				startArena();
			}
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	player.server_setTeamNum(this.getSpectatorTeamNum());

	string username = player.getUsername();

	bool was_playing = false;

	for (u8 i = 0; i < priority_queue.length(); i++)
	{
		if (priority_queue[i].username == username)
		{
			was_playing = true;
			break;
		}
	}

	for (u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];

		for (u8 j = 0; j < instance.players.length(); j++)
		{
			if (instance.players[j].username == username)
			{
				was_playing = true;
				break;
			}
		}
	}

	if (!was_playing)
		new_queue.push_back(ArenaPlayer(username, 0));

	statNewPlayerJoined(this, player);

	
	
	// ///// TEST ARENAS
	// CBitStream bt;

	// bt.write_u8(0); // arena id

	// string player1 = "none";
	// string player2 = "none";

	// bt.write_string(player2); // player 2
	// bt.write_string(player1); // player 1
	// bt.write_bool(true); // ongoing

	// getRules().SendCommand(getRules().getCommandID(ARENA_UPDATE_INT_ID), bt);
	// getRules().SendCommand(getRules().getCommandID(ARENA_UPDATE_INT_ID), bt);
	// getRules().SendCommand(getRules().getCommandID(ARENA_UPDATE_INT_ID), bt);
	// /////
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
	bool is_queued = false;
	for(u8 i = 0; i < new_queue.length(); i++)
	{
		if (new_queue[i].username == player.getUsername())
		{
			new_queue.removeAt(i);
			is_queued = true;
			break;
		}
	}

	for(u8 i = 0; i < priority_queue.length(); i++)
	{
		if (priority_queue[i].username == player.getUsername())
		{
			priority_queue.removeAt(i);
			is_queued = true;
			break;
		}
	}

	if (!is_queued)
		onPlayerLost(this, player, true);
}

void onPlayerLost(CRules@ this, CPlayer@ player, bool leaver = false)
{
	if (player is null)
		return;

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

					ArenaPlayer@ winner = instance.players[1 - victim];
					ArenaPlayer@ loser = instance.players[victim];

					if (arenaPlayers() >= MIN_PLAYERS)
					{
						addStat(winner, KILLS);
						addStat(winner, MATCHES);
						addStat(loser, DEATHS);
						addStat(loser, MATCHES);
						
						if (i == 0)
						{
							string arena_winner = this.get_string(ARENA_WINNER);

							if (arena_winner != winner.username)
							{
								this.set_u16(ARENA_WINNER_STREAK, 1);
								this.Sync(ARENA_WINNER_STREAK, true);

								this.set_string(ARENA_WINNER, winner.username);
								this.Sync(ARENA_WINNER, true);
							}
							else
							{
								u16 streak = this.get_u16(ARENA_WINNER_STREAK);

								streak++;

								this.set_u16(ARENA_WINNER_STREAK, streak);
								this.Sync(ARENA_WINNER_STREAK, true);
							}
						}
					}
					else if (i == 0)
					{
						this.set_u16(ARENA_WINNER_STREAK, 0);
						this.Sync(ARENA_WINNER_STREAK, true);

						this.set_string(ARENA_WINNER, winner.username);
						this.Sync(ARENA_WINNER, true);
					}

					CBitStream bt;
					bt.write_u8(i);
					bt.write_string(winner.username);

					this.SendCommand(getRules().getCommandID(ARENA_WINNER_INT_ID), bt);

					instance.FinishMatch(winner, loser);
				}
			}
		}
	}
}

void populateFromQueue(ArenaPlayer@[]& queue)
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
				getRules().set_u8(p.getUsername() + ARENA_PLAYER_CURRENT, i);
				getRules().Sync(p.getUsername() + ARENA_PLAYER_CURRENT, true);

				u8 teamnum = p.getTeamNum();

				if (teamnum == getRules().getSpectatorTeamNum())
				{			
					u8 random_team = XORRandom(8);
					p.server_setTeamNum(random_team);
				}
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

	populateFromQueue(priority_queue);
	populateFromQueue(new_queue);

	getRules().SendCommand(getRules().getCommandID(ARENA_DESTROY_INT_ID), CBitStream());

	for(u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];
		instance.StartMatch();

		CBitStream bt;
		bt.write_u8(instance.id); // arena id

		u8 player_amount = instance.players.length();

		string player1 = player_amount > 0 && instance.players[0] != null ? instance.players[0].username : "none";
		string player2 = player_amount > 1 && instance.players[1] != null ? instance.players[1].username : "none";

		bt.write_string(player2); // player 2
		bt.write_string(player1); // player 1
		bt.write_bool(instance.ongoing); // ongoing

		getRules().SendCommand(getRules().getCommandID(ARENA_UPDATE_INT_ID), bt);
	}
	
	getRules().set_s32("restart_rules_after_game", getGameTime() + cooldown);
}

void endArena()
{
	CRules@ rules = getRules();

	if (rules.exists(ARENA_WINNER))
	{
		CBitStream bt;

		string username = rules.get_string(ARENA_WINNER);

		bt.write_string(username);

		if (arenaPlayers() >= MIN_PLAYERS)
		{
			u16 streak = rules.get_u16(ARENA_WINNER_STREAK);
			bt.write_u16(streak);

			updateStreakStat(username, streak);

			rules.SendCommand(rules.getCommandID(ARENA_FINISH_ID), bt);
		}
		else
		{
			rules.SendCommand(rules.getCommandID(ARENA_FINISH_NO_STATS_ID), bt);
		}
	}

	ArenaPlayer@[] last_match_players;

	// add all players to priority queue
	for(u8 i = 0; i < Arena.length(); i++)
	{
		ArenaInstance@ instance = Arena[i];

		for(u8 j = 0; j < instance.players.length(); j++)
		{
			ArenaPlayer@ player = instance.players[j];

			last_match_players.push_back(player);

			if (getPlayerByUsername(player.username) is null)
				continue;

			player.arena_weight += player.result_value;
			player.result_value = 0;
			priority_queue.push_back(player);
		}
	}

	priority_queue.sortAsc();

	saveStats(last_match_players);

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

u8 arenaPlayers()
{
	// print total of people in the arena
	u8 total = 0;
	for(u8 i = 0; i < Arena.length(); i++)
	{
		total += Arena[i].players.length();
	}

	return total;
}