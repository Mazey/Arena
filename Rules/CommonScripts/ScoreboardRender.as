#include "ScoreboardCommon.as";
#include "Accolades.as";
#include "ColoredNameToggleCommon.as";
#include "HSVToRGB.as";

CPlayer@ hoveredPlayer;
Vec2f hoveredPos;

int hovered_accolade = -1;
int hovered_age = -1;
int hovered_tier = -1;
bool draw_age = false;
bool draw_tier = false;

float scoreboardMargin = 52.0f;
float scrollOffset = 0.0f;
float scrollSpeed = 4.0f;
float maxMenuWidth = 700;
float screenMidX = getScreenWidth()/2;

bool mouseWasPressed2 = false;

string[] age_description = {
	"New Player - Welcome them to the game!",
	//first month
	"This player has 1 to 2 weeks of experience",
	"This player has 2 to 3 weeks of experience",
	"This player has 3 to 4 weeks of experience",
	//first year
	"This player has 1 to 2 months of experience",
	"This player has 2 to 3 months of experience",
	"This player has 3 to 6 months of experience",
	"This player has 6 to 9 months of experience",
	"This player has 9 to 12 months of experience",
	//cake day
	"Cake Day - it's this player's KAG Birthday!",
	//(gap in the sheet)
	"", "", "", "", "", "",
	//established player
	"This player has 1 year of experience",
	"This player has 2 years of experience",
	"This player has 3 years of experience",
	"This player has 4 years of experience",
	"This player has 5 years of experience",
	"This player has 6 years of experience",
	"This player has 7 years of experience",
	"This player has 8 years of experience",
	"This player has 9 years of experience",
	"This player has over a decade of experience"
};

string[] tier_description = {
	"", //f2p players, no description
	"This player is a Squire Supporter",
	"This player is a Knight Supporter",
	"This player is a Royal Guard Supporter",
	"This player is a Round Table Supporter"
};

//returns the bottom
float drawScoreboard(CPlayer@ localplayer, CPlayer@[] players, Vec2f topleft, u8 arena_id, bool align_right)
{
	if (players.size() <= 0)
		return topleft.y;

	CRules@ rules = getRules();
	Vec2f orig = topleft; //save for later

	f32 lineheight = 16;
	f32 padheight = 2;
	f32 stepheight = lineheight + padheight;
	Vec2f bottomright = Vec2f_zero;

	if (align_right)
	{
		bottomright = Vec2f(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + (players.length + 5.5) * stepheight);
		topleft.x = screenMidX + 26;
	}
	else
	{
		bottomright = Vec2f(Maths::Max(screenMidX - 26, topleft.x+maxMenuWidth), topleft.y + (players.length + 5.5) * stepheight);
		topleft.x = Maths::Max(100, screenMidX-maxMenuWidth);
	}

	GUI::DrawPane(topleft, bottomright, SColor(230, 190- arena_id * 5, arena_id * 15, arena_id * 15));

	//offset border
	topleft.x += stepheight;
	bottomright.x -= stepheight;
	topleft.y += stepheight;

	GUI::SetFont("menu");

	//draw team info
	GUI::DrawText(getTranslatedString("Arena: {ARENA}").replace("{ARENA}", "" + (arena_id + 1)), topleft, SColor(0xffffffff));

	topleft.y += stepheight * 2;

	const int accolades_start = 770;
	const int age_start = accolades_start + 80;

	draw_age = false;
	for(int i = 0; i < players.length; i++) {
		if (players[i].getRegistrationTime() > 0) {
			draw_age = true;
			break;
		}
	}

	draw_tier = false;
	for(int i = 0; i < players.length; i++) {
		if (players[i].getSupportTier() > 0) {
			draw_tier = true;
			break;
		}
	}
	const int tier_start = (draw_age ? age_start : accolades_start) + 70;

	//draw player table header
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x + 40, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 140, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 85, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 40, topleft.y), SColor(0xffffffff));
	if(arena_id == 0)
	{
		GUI::DrawText(getTranslatedString("Streak"), Vec2f(bottomright.x - 265, topleft.y), HSVToRGB(getGameTime() % 360, 1.0f, 1.0f));
	}
	if(draw_age)
	{
		GUI::DrawText(getTranslatedString("Age | "), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	}
	if(draw_tier)
	{
		GUI::DrawText(getTranslatedString("Tier"), Vec2f(bottomright.x - 200, topleft.y), SColor(0xffffffff));
	}

	topleft.y += stepheight * 0.5f;

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

	//draw players
	for (u32 i = 0; i < players.length; i++)
	{
		CPlayer@ p = players[i];

		topleft.y += stepheight;
		bottomright.y = topleft.y + lineheight;

		bool playerHover = mousePos.y > topleft.y && mousePos.y < topleft.y + 15;

		Vec2f lineoffset = Vec2f(0, -2);

		u32 underlinecolor = 0xff404040;
		u32 playercolour = (p.getBlob() is null || p.getBlob().hasTag("dead")) ? 0xff505050 : 0xff808080;
		if (playerHover)
		{
			playercolour = 0xffcccccc;
			@hoveredPlayer = p;
			hoveredPos = topleft;
			hoveredPos.x = bottomright.x - 150;
		}

		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, SColor(underlinecolor));
		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));

		string username = p.getUsername();

		string playername = p.getCharacterName();
		string clantag = p.getClantag();

		if(getSecurity().isPlayerNameHidden(p) && getLocalPlayer() !is p)
		{
			if(isAdmin(getLocalPlayer()))
			{
				playername = username + "(hidden: " + clantag + " " + playername + ")";
				clantag = "";

			}
			else
			{
				playername = username;
				clantag = "";
			}

		}

		//head icon

		//TODO: consider maybe the skull emoji for dead players?
		int headIndex = 0;
		string headTexture = "";
		int teamIndex = p.getTeamNum();

		CBlob@ b = p.getBlob();
		if (b !is null)
		{
			headIndex = b.get_s32("head index");
			headTexture = b.get_string("head texture");
			teamIndex = b.get_s32("head team");
		}

		if (headTexture != "")
		{
			GUI::DrawIcon(headTexture, headIndex, Vec2f(16, 16), topleft + Vec2f(40, -12), 1.0f, teamIndex);
		}

		//have to calc this from ticks
		s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);

		//how much room to leave for names and clantags
		float name_buffer = 56.0f;
		Vec2f clantag_actualsize(0, 0);

		//render the player + stats
		SColor namecolour = getNameColour(p);

		//draw name alone
		string name = playername;
		if (name != username)
		{
			name += " (" + username + ")";
		}

		GUI::DrawText(name, topleft + Vec2f(name_buffer + 24, 0), namecolour);

		//draw account age indicator
		if (draw_age)
		{
			int regtime = p.getRegistrationTime();
			if (regtime > 0)
			{
				int reg_month = Time_Month(regtime);
				int reg_day = Time_MonthDate(regtime);
				int reg_year = Time_Year(regtime);

				int days = Time_DaysSince(regtime);

				int age_icon_start = 32;
				int icon = 0;
				//less than a month?
				if (days < 28)
				{
					int week = days / 7;
					icon = week;
				}
				else
				{
					//we use 30 day "months" here
					//for simplicity and consistency of badge allocation
					int months = days / 30;
					if (months < 12)
					{
						switch(months) {
							case 0:
							case 1:
								icon = 0;
								break;
							case 2:
								icon = 1;
								break;
							case 3:
							case 4:
							case 5:
								icon = 2;
								break;
							case 6:
							case 7:
							case 8:
								icon = 3;
								break;
							case 9:
							case 10:
							case 11:
							default:
								icon = 4;
								break;
						}
						icon += 4;
					}
					else
					{
						//figure out birthday
						int month_delta = Time_Month() - reg_month;
						int day_delta = Time_MonthDate() - reg_day;
						int birthday_delta = -1;

						if (month_delta < 0 || month_delta == 0 && day_delta < 0)
						{
							birthday_delta = -1;
						}
						else if (month_delta == 0 && day_delta == 0)
						{
							birthday_delta = 0;
						}
						else
						{
							birthday_delta = 1;
						}

						//check if its cake day
						if (birthday_delta == 0)
						{
							icon = 9;
						}
						else
						{
							//check if we're in the extra "remainder" days from using 30 month days
							if(days < 366)
							{
								//(9 months badge still)
								icon = 8;
							}
							else
							{
								//years delta
								icon = (Time_Year() - reg_year) - 1;
								//before or after birthday?
								if (birthday_delta == -1)
								{
									icon -= 1;
								}
								//ensure sane
								icon = Maths::Clamp(icon, 0, 9);
								//shift line
								icon += 16;
							}
						}
					}
				}

				float x = bottomright.x - age_start + 8;
				float extra = 8;
				GUI::DrawIcon("AccoladeBadges", age_icon_start + icon, Vec2f(16, 16), Vec2f(topleft.x + 8, topleft.y), 0.5f, p.getTeamNum());

				if (playerHover && mousePos.x > x - extra && mousePos.x < x + 16 + extra)
				{
					hovered_age = icon;
				}
			}

		}

		//draw support tier
		if(draw_tier)
		{
			int tier = p.getSupportTier();

			if(tier > 0)
			{
				int tier_icon_start = 15;
				float x = bottomright.x - tier_start + 8;
				float extra = 8;
				GUI::DrawIcon("AccoladeBadges", tier_icon_start + tier, Vec2f(16, 16), Vec2f(bottomright.x - 200, topleft.y), 0.5f, p.getTeamNum());

				if (playerHover && mousePos.x > x - extra && mousePos.x < x + 16 + extra)
				{
					hovered_tier = tier;
				}
			}

		}
		
		if (arena_id == 0 && rules.exists(p.getUsername()+"arena streak"))
		{
			u16 streak = rules.get_u16(p.getUsername()+"arena streak");
			if (streak > 0)
			{
				GUI::DrawText("" + streak, Vec2f(bottomright.x - 265, topleft.y), HSVToRGB(getGameTime() % 360, 1.0f, 1.0f));
			}
		}

		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 140, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getKills(), Vec2f(bottomright.x - 85, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getDeaths(), Vec2f(bottomright.x - 40, topleft.y), SColor(0xffffffff));
	}

	// username copied text, goes at bottom to overlay above everything else
	uint durationLeft = rules.get_u16("client_copy_time");

	if ((durationLeft + 64) > getGameTime())
	{
		durationLeft = getGameTime() - durationLeft;
		DrawFancyCopiedText(rules.get_string("client_copy_name"), rules.get_Vec2f("client_copy_pos"), durationLeft);
	}

	return topleft.y;

}

void onRenderScoreboard(CRules@ this)
{
	//sort players
	CPlayer@[] participants;
	CPlayer@[] spectators;
	u8[] arena_numbers;
	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		bool inserted = false;
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}

		if (this.exists(p.getUsername()+"current_arena"))
		{
			u8 arena = this.get_u8(p.getUsername()+"current_arena");
			if (arena_numbers.find(arena) == -1)
			{
				arena_numbers.push_back(arena);
			}

			participants.push_back(p);
		}
		else
		{
			warn("player " + p.getUsername() + " has no arena prop but is not spectating");
		}
	}

	arena_numbers.sortAsc();

	//draw board

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
		return;
	int localTeam = localPlayer.getTeamNum();
	if (localTeam != 0 && localTeam != 1)
		localTeam = 0;

	@hoveredPlayer = null;

	Vec2f topleft(Maths::Max( 100, screenMidX/2-maxMenuWidth), 150);
	drawServerInfo(40);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//(reset)
	hovered_accolade = -1;
	hovered_age = -1;
	hovered_tier = -1;

	//draw spectator board
	if (spectators.length > 0)
	{
		//draw spectators
		f32 stepheight = 16;
		Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + stepheight * 2);

		topleft.x = Maths::Max(100, screenMidX-maxMenuWidth);
		f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectators.length - 1)
					name += ",";
				GUI::GetTextDimensions(name, textdim);
				SColor namecolour = getNameColour(p);
				GUI::DrawText(name, Vec2f(specx, specy), namecolour);
				specx += textdim.x + 10;
			}
			else
			{
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), SColor(0xffaaaaaa));
				break;
			}
		}

		topleft.y += 52;
	}

	//draw the scoreboards
	bool do_x = false;
	for (u8 i = 0; i < arena_numbers.length; i++)
	{
		CPlayer@[] arena_participants;
		for (u32 j = 0; j < participants.length; j++)
		{
			CPlayer@ p = participants[j];
			if (this.get_u8(p.getUsername()+"current_arena") == arena_numbers[i])
			{
				arena_participants.push_back(p);
			}
		}

		if (arena_participants.length == 0)
			continue;

		f32 old_y = topleft.y;
		topleft.y = drawScoreboard(localPlayer, arena_participants, topleft, i, do_x);
		
		if (!do_x)
		{
			topleft.y = old_y;
			do_x = true;
		}
		else
		{
			topleft.y += 52;
			do_x = false;
		}
	}
	
	topleft.y += 52;

	float scoreboardHeight = topleft.y + scrollOffset;
	float screenHeight = getScreenHeight();
	CControls@ controls = getControls();

	if(scoreboardHeight > screenHeight) {
		Vec2f mousePos = controls.getMouseScreenPos();

		float fullOffset = (scoreboardHeight + scoreboardMargin) - screenHeight;

		if(scrollOffset < fullOffset && mousePos.y > screenHeight*0.83f) {
			scrollOffset += scrollSpeed;
		}
		else if(scrollOffset > 0.0f && mousePos.y < screenHeight*0.16f) {
			scrollOffset -= scrollSpeed;
		}

		scrollOffset = Maths::Clamp(scrollOffset, 0.0f, fullOffset);
	}

	drawPlayerCard(hoveredPlayer, hoveredPos);

	drawHoverExplanation(hovered_accolade, hovered_age, hovered_tier, Vec2f(getScreenWidth() * 0.5, topleft.y));

	mouseWasPressed2 = controls.mousePressed2; 
}

void drawHoverExplanation(int hovered_accolade, int hovered_age, int hovered_tier, Vec2f centre_top)
{
	if( //(invalid/"unset" hover)
		(hovered_accolade < 0
		 || hovered_accolade >= accolade_description.length) &&
		(hovered_age < 0
		 || hovered_age >= age_description.length) &&
		(hovered_tier < 0
		 || hovered_tier >= tier_description.length)
	) {
		return;
	}

	string desc = getTranslatedString(
		(hovered_accolade >= 0) ?
			accolade_description[hovered_accolade] :
			hovered_age >= 0 ?
				age_description[hovered_age] :
				tier_description[hovered_tier]
	);

	Vec2f size(0, 0);
	GUI::GetTextDimensions(desc, size);

	Vec2f tl = centre_top - Vec2f(size.x / 2, 0);
	Vec2f br = tl + size;

	//margin
	Vec2f expand(8, 8);
	tl -= expand;
	br += expand;

	GUI::DrawPane(tl, br, SColor(0xffffffff));
	GUI::DrawText(desc, tl + expand, SColor(0xffffffff));
}

void onTick(CRules@ this)
{
	if(isServer() && this.getCurrentState() == GAME)
	{
		this.add_u32("match_time", 1);
		this.Sync("match_time", true);
	}
}

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if(isServer())
	{
		this.set_u32("match_time", 0);
		this.Sync("match_time", true);
		getMapName(this);
	}
}

void getMapName(CRules@ this)
{
	CMap@ map = getMap();
	if(map !is null)
	{
		string[] name = map.getMapName().split('/');	 //Official server maps seem to show up as
		string mapName = name[name.length() - 1];		 //``Maps/CTF/MapNameHere.png`` while using this instead of just the .png
		mapName = getFilenameWithoutExtension(mapName);  // Remove extension from the filename if it exists

		this.set_string("map_name", mapName);
		this.Sync("map_name",true);
	}
}

void DrawFancyCopiedText(string username, Vec2f mousePos, uint duration)
{
	string text = "Username copied: " + username;
	Vec2f pos = mousePos - Vec2f(0, duration);
	int col = (255 - duration * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - duration * 4), col, col, col));
}
