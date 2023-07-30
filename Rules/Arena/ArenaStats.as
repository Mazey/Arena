#define SERVER_ONLY

const string DIR = "Arena/";

enum StatType
{
	KILLS = 0,
	MATCHES,
	STREAK,
	DEATHS
};

string[] statNames = 
{
	"_kills_stat",
	"_matches_stat",
	"_streak_stat",
	"_deaths_stat"
};

// save stats to Cache

void statNewPlayerJoined(CRules@ this, CPlayer@ player)
{
	if (player is null) 
		return;

	// check if player has stats
	ConfigFile@ cfg = ConfigFile();
	u16 kills = 0;
	u16 streak = 0;
	u16 matches = 0;
	u16 deaths = 0;

	if (!cfg.loadFile("../Cache/" + DIR + player.getUsername() + ".cfg"))
	{
		for (uint i = 0; i < statNames.length; i++)
		{
			cfg.add_u16(statNames[i].substr(1, statNames[i].length() - 6), 0);
		}
		cfg.saveFile(DIR + player.getUsername() + ".cfg");
	}
	else
	{
		kills = cfg.read_u16(statNames[KILLS].substr(1, statNames[KILLS].length() - 6));
		streak = cfg.read_u16(statNames[STREAK].substr(1, statNames[STREAK].length() - 6));
		matches = cfg.read_u16(statNames[MATCHES].substr(1, statNames[MATCHES].length() - 6));
		deaths = cfg.read_u16(statNames[DEATHS].substr(1, statNames[DEATHS].length() - 6));
	}

	// set stats to rule props
	this.set_u16(player.getUsername() + statNames[KILLS], kills);
	this.set_u16(player.getUsername() + statNames[STREAK], streak);
	this.set_u16(player.getUsername() + statNames[MATCHES], matches);
	this.set_u16(player.getUsername() + statNames[DEATHS], deaths);
}

void addStat(ArenaPlayer@ player, StatType stat)
{
	if (player is null) 
		return; // left?
		
	CRules@ rules = getRules();
	
	if (!rules.exists(player.username + statNames[stat]))
		return; // wtf? but cba to print

	rules.add_u16(player.username + statNames[stat], 1);
}

void updateStreakStat(ArenaPlayer@ player, u16 streak)
{
	if (player is null) 
		return;

	CRules@ rules = getRules();
	
	if (!rules.exists(player.username + statNames[STREAK]))
		return;

	if (streak > rules.get_u16(player.username + statNames[STREAK]))
		rules.set_u16(player.username + statNames[STREAK], streak);
}

void saveStats(ArenaPlayer@[] players)
{
	CRules@ rules = getRules();

	for (uint i = 0; i < players.length; i++)
	{
		ArenaPlayer@ player = players[i];
		if (player is null) continue;

		ConfigFile@ cfg = ConfigFile();
		for (uint j = 0; j < statNames.length; j++)
		{
			if (!rules.exists(player.username + statNames[j]))
				continue;

			cfg.add_u16(statNames[j].substr(1, statNames[j].length() - 6), rules.get_u16(player.username + statNames[j]));
		}
		cfg.saveFile(DIR + player.username + ".cfg");
	}
}