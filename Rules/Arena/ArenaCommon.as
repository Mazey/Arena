const string ARENA_PROP = "Arena array";

shared class ArenaPlayer
{
	string username;
	s8 arena_weight;
	s8 result_value = 0; // 0 = no result, 1 = loss, -1 = win

	
	ArenaPlayer(string _username, s8 _arena_weight)
	{
		username = _username;
		arena_weight = _arena_weight;
	}

	int opCmp(const ArenaPlayer &in other)
	{
		return arena_weight - other.arena_weight;
	}
}

shared class ArenaInstance
{
	u8 id;
	bool ongoing = false;
	ArenaPlayer[] players;
	Vec2f[] spawns;
	
	ArenaInstance(u8 _id)
	{
		id = _id;
	}

	bool canAddPlayer()
	{
		return (players.length() < 2);
	}

	void AddPlayer(ArenaPlayer@ player)
	{
		players.push_back(player);
	}

	void AddSpawn(Vec2f pos)
	{
		spawns.push_back(pos);
	}

	void SpawnPlayers()
	{
		for(u8 i = 0; i < players.length(); i++)
		{
			CPlayer@ player = getPlayerByUsername(players[i].username);
			
			u8 random_team = XORRandom(8);

			if (i > 0)
			{
				CPlayer@ other_player = getPlayerByUsername(players[0].username);
				if (other_player !is null)
				{
					while (random_team == other_player.getTeamNum())
					{
						random_team = XORRandom(8);
					}
				}
			}

			player.server_setTeamNum(random_team);

			if (player !is null)
			{
				CBlob @blob = player.getBlob();

				if (blob !is null)
				{
					CBlob @blob = player.getBlob();
					blob.server_SetPlayer(null);
					blob.server_Die();
				}

				CBlob@ newBlob = server_CreateBlob(getRules().get_string("default class"), player.getTeamNum(), spawns[i]);
				newBlob.server_SetPlayer(player);
			}
		}
	}

	void StartMatch()
	{
		print("players in " + id + ": " + players.length());
		print("----");
		for(u8 i = 0; i < players.length(); i++)
		{
			print(players[i].username);
		}
		print("----");
		
		ongoing = true;

		switch (players.length())
		{
			case 1:
				print("arena " + id + " starting but has 1 player: " + players[0].username);
				SpawnPlayers();
				FinishMatch(players[0], null);
			break;
			case 2:
				print("arena " + id + " starting (" + players[0].username + " vs " + players[1].username + ")");
				SpawnPlayers();
			break;
		}
	}

	void FinishMatch(ArenaPlayer@ winner, ArenaPlayer@ loser = null)
	{
		ongoing = false;

		if (winner !is null)
			winner.result_value = -1;

		if (loser !is null)
			loser.result_value = 1;
	}
}