#define CLIENT_ONLY

#include "ScoreboardCommon.as";
#include "ArenaCommon.as";
#include "HSVToRGB.as";

const SColor c_regular = color_white;
const SColor c_dark = SColor(0xffc0c0c0);
const SColor c_dead = SColor(255, 155, 155, 155);
const SColor c_active = SColor(225, 80, 225, 95);
const SColor c_inactive = SColor(255, 225, 95, 80);

const string ONGOING_ICON = "GUI/MenuItems.png";
const u8 ONGOING_ICON_NO = 12;

const string CROWN_ICON = "GUI/AccoladeBadges.png";
const u8 CROWN_ICON_NO = 8;

InterfaceArenaInstance@[] interface_arena;

void onInit(CRules@ this)
{
	this.addCommandID(ARENA_UPDATE_INT_ID);
	this.addCommandID(ARENA_DESTROY_INT_ID);
	this.addCommandID(ARENA_WINNER_INT_ID);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(ARENA_UPDATE_INT_ID))
	{
		InterfaceArenaInstance@ instance = InterfaceArenaInstance(); // u8 id, string player, string player, bool ongoing

		u8 id;
		string player1;
		string player2;
		bool ongoing;

		if (!params.saferead_u8(id))
			return;

		if (!params.saferead_string(player2))
			return;

		if (!params.saferead_string(player1))
			return;
		
		if (!params.saferead_bool(ongoing))
			return;
		
		instance.id = id;
		instance.players.push_back(player1);
		instance.players.push_back(player2);
		instance.ongoing = ongoing;
		
		interface_arena.push_back(instance);
	}
	else if (cmd == this.getCommandID(ARENA_DESTROY_INT_ID))
	{
		interface_arena.clear();
	}
	else if (cmd == this.getCommandID(ARENA_WINNER_INT_ID))
	{
		u8 id;
		string winner;

		if (!params.saferead_u8(id))
			return;

		if (!params.saferead_string(winner))
			return;

		for (u8 i = 0; i < interface_arena.length(); i++)
		{
			if (interface_arena[i].id == id)
			{
				interface_arena[i].setWinner(winner);
				break;
			}
		}
	}
}

bool render_more = false;

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	GUI::SetFont("menu");

	u8 arena_amount = interface_arena.length();

	if (arena_amount == 0)
		return;

	s32 screen_width = getScreenWidth();

	f32 ongoing_width = Maths::Min(screen_width * .25f, 324.0f);
	f32 ongoing_height = 48.0f;
	f32 padding = 8.0f;

	Vec2f tl(8, 8);

	CPlayer@[] spectators;

	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}
		

		if (!this.exists(p.getUsername()+"current_arena"))
		{
			print("player " + p.getUsername() + " has no arena prop but is not spectating");
			// probably just joined
			spectators.push_back(p);
		}
	}

	f32 queue_height = 32;

	//draw spectator board
	if (spectators.length > 0)
	{
		//draw spectators
		Vec2f br(tl.x + ongoing_width, tl.y + queue_height);

		if (render_more)
			br.x = getScreenWidth() / 2;
		
		f32 specy = tl.y + queue_height * 0.25;
		GUI::DrawPane(tl, br, c_dark);

		Vec2f textdim;
		string s = getTranslatedString("Queued:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(tl.x + 5, specy), c_regular);

		f32 specx = tl.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < br.x - 100)
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
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), c_regular);
				break;
			}
		}

		tl.y = br.y + padding;
	}

	for (u8 i = 0; i < arena_amount; i++)
	{
		tl.y += padding;

		tl.y = renderMatch(tl, ongoing_width, ongoing_height, interface_arena[i]);
	}

	if (render_more)
	{
		Vec2f br = Vec2f(getScreenWidth() / 2, tl.y);
		tl = Vec2f(tl.x + ongoing_width + padding, 2 * padding + queue_height);
		GUI::DrawPane(tl, br, c_dark);
		GUI::SetFont("menuoption");

		string streak_text = "Top streak";
		string rank_text = "Ranking";

		Vec2f streak_dimension;
		GUI::GetTextDimensions(streak_text, streak_dimension);
		GUI::DrawButton(Vec2f(tl.x + padding, tl.y - 2 * padding + 4), Vec2f(tl.x + 3 * padding + streak_dimension.x, tl.y + 4));
		GUI::DrawTextCentered(streak_text, Vec2f(tl.x + 3 * padding / 2 + streak_dimension.x / 2, tl.y - padding + 2), c_regular);
		//GUI::DrawLine2D(Vec2f(tl.x + 2 * padding + streak_dimension.x / 2, tl.y + 4), Vec2f(tl.x + 2 * padding + streak_dimension.x / 2, br.y), c_dark);

		Vec2f rank_dimension;
		GUI::GetTextDimensions(rank_text, rank_dimension);
		GUI::DrawButton(Vec2f(tl.x + 4 * padding + streak_dimension.x, tl.y - 2 * padding + 4), Vec2f(tl.x + 6 * padding + streak_dimension.x + rank_dimension.x, tl.y + 4));
		GUI::DrawTextCentered(rank_text, Vec2f(tl.x + 4.5 * padding + streak_dimension.x + rank_dimension.x / 2, tl.y - padding + 2), c_regular);
		//GUI::DrawLine2D(Vec2f(tl.x + 5 * padding + streak_dimension.x + rank_dimension.x / 2, tl.y + 4), Vec2f(tl.x + 5 * padding + streak_dimension.x + rank_dimension.x / 2, br.y), c_dark);

		for (u8 i = 0; i < arena_amount; i++)
		{
			// get centre of this renderMatch object
			f32 y_offset = i * (ongoing_height + padding);
			Vec2f center = Vec2f(tl.x + ongoing_width / 2, tl.y + y_offset + ongoing_height / 2 - 1);

			GUI::DrawLine2D(Vec2f(tl.x + padding, center.y + padding / 2), Vec2f(br.x - padding, center.y + padding / 2), c_dead);
			GUI::DrawLine2D(Vec2f(tl.x + padding, center.y + ongoing_height / 2 + padding / 2), Vec2f(br.x - padding, center.y + ongoing_height / 2 + padding / 2), c_dead);
		}
	}

	render_more = false;
}

float renderMatch(Vec2f tl, f32 width, f32 height, InterfaceArenaInstance@ instance)
{
	f32 padding = 4.0f;

	Vec2f br = tl + Vec2f(width, height);
	Vec2f center = Vec2f((tl.x + br.x) / 2, (tl.y + br.y) / 2 - 1);

	GUI::DrawPane(tl, br, c_dark);
	GUI::SetFont("menuoption");

	// arena name
	f32 arena_name_width = 76.0f;
	GUI::DrawButton(tl + Vec2f(padding, padding), tl + Vec2f(padding + arena_name_width, height / 2));
	GUI::DrawTextCentered("Arena " + (instance.id + 1), tl + Vec2f(padding / 2 + arena_name_width / 2, height / 4 + padding / 2), c_regular);

	// status text below arena name button
	GUI::DrawButton(tl + Vec2f(padding + 4, height / 2), tl + Vec2f(padding + arena_name_width - 4, height - padding));
	if (instance.ongoing)
		GUI::DrawTextCentered("Ongoing", tl + Vec2f(padding / 2 + arena_name_width / 2, height * 3 / 4 - padding / 2 - 2), c_active);
	else
		GUI::DrawTextCentered("Finished", tl + Vec2f(padding / 2 + arena_name_width / 2, height * 3 / 4 - padding / 2 - 2), c_inactive);

	// centered "vs."
	GUI::DrawTextCentered("vs", Vec2f(padding + arena_name_width + 24, center.y), c_regular);

	GUI::SetFont("menu");

	// participants
	f32 player_width = width - arena_name_width - padding * 2;
	f32 player_height = height / 2 - padding * 2;

	string name1 = instance.players[0];
	string name2 = instance.players[1];

	CPlayer@ player = getPlayerByUsername(name1);
	if (player !is null)
		name1 = player.getCharacterName();
	
	@player = getPlayerByUsername(name2);
	if (player !is null)
		name2 = player.getCharacterName();
	
	CRules@ rules = getRules();
	string winner_name = rules.get_string(ARENA_WINNER);
	s8 winner_pos = instance.players.find(winner_name);

	GUI::DrawText(name1, tl + Vec2f(arena_name_width + padding * 2, padding), (instance.ongoing ? c_regular : (instance.winner == 0 ? c_active : c_dead)));
	GUI::DrawLine2D(Vec2f(tl.x + arena_name_width + padding * 2, center.y - padding), Vec2f(br.x - 2 * padding, center.y - padding), (instance.id == 0 && winner_pos == 0 ? HSVToRGB(2 * getGameTime() % 360, 1.0f, 1.0f) : c_dead));

	GUI::DrawText(name2, tl + Vec2f(arena_name_width + padding * 2, height / 2 + padding), (instance.ongoing ? c_regular : (instance.winner == 1 ? c_active : c_dead)));
	GUI::DrawLine2D(Vec2f(tl.x + arena_name_width + padding * 2, br.y - padding), Vec2f(br.x - 2 * padding, br.y - padding), (instance.id == 0 && winner_pos == 1 ? HSVToRGB(2 * getGameTime() % 360, 1.0f, 1.0f) : c_dead));

	if (instance.id == 0 && winner_pos > -1)
	{
		u16 streak = rules.get_u16(ARENA_WINNER_STREAK);
		f32 crown_height = padding + height / 2 * winner_pos;
		Vec2f crown_offset = Vec2f(-32, 8);

		if (streak > 0)
			GUI::DrawTextCentered("" + streak, Vec2f(br.x - padding - 12, crown_height + 16), HSVToRGB(2 * getGameTime() % 360, 1.0f, 1.0f));
	
		GUI::DrawIcon(CROWN_ICON, CROWN_ICON_NO, Vec2f(16, 16), Vec2f(br.x - padding, crown_height) + crown_offset, 0.5f);
	}

	return br.y;
}

void onRenderScoreboard(CRules@ this) // noob game tbh
{
	render_more = true;

	GUI::SetFont("menuoption");
	drawServerInfo();
}