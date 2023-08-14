#define CLIENT_ONLY

#include "ArenaCommon.as";
#include "HSVToRGB.as";

const SColor c_regular = color_white;
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

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	u8 arena_amount = interface_arena.length();

	if (arena_amount == 0)
		return;

	s32 screen_width = getScreenWidth();

	f32 width = Maths::Min(screen_width * .25f, 384.0f);
	f32 height = 48.0f;

	Vec2f tl(8, 8);

	for (u8 i = 0; i < arena_amount; i++)
	{
		tl.y = renderMatch(tl, width, height, i);

		tl.y += 6;
	}
}

float renderMatch(Vec2f tl, f32 width, f32 height, u8 arena_id)
{
	InterfaceArenaInstance@ instance = interface_arena[arena_id];

	f32 padding = 4.0f;

	Vec2f br = tl + Vec2f(width, height);
	Vec2f center = Vec2f((tl.x + br.x) / 2, (tl.y + br.y) / 2 - 1);

	GUI::SetFont("hud");

	GUI::DrawButton(tl, br);

	// arena name
	f32 arena_name_width = 76.0f;
	GUI::DrawButton(tl + Vec2f(padding, padding), tl + Vec2f(padding + arena_name_width, height / 2));
	GUI::DrawTextCentered("Arena " + (arena_id + 1), tl + Vec2f(padding / 2 + arena_name_width / 2, height / 4 + padding / 2), c_regular);

	// status text below arena name button
	GUI::DrawButton(tl + Vec2f(padding, height / 2), tl + Vec2f(padding + arena_name_width, height - padding));
	if (instance.ongoing)
		GUI::DrawTextCentered("Ongoing", tl + Vec2f(padding / 2 + arena_name_width / 2, height * 3 / 4 - padding / 2), c_active);
	else
		GUI::DrawTextCentered("Finished", tl + Vec2f(padding / 2 + arena_name_width / 2, height * 3 / 4 - padding / 2), c_inactive);

	// centered "vs."
	GUI::DrawTextCentered("- vs -", center, c_regular);

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
	GUI::DrawLine2D(Vec2f(tl.x + arena_name_width + padding * 3, center.y - padding), Vec2f(br.x - 2 * padding, center.y - padding), (arena_id == 0 && winner_pos == 0 ? HSVToRGB(2 * getGameTime() % 360, 1.0f, 1.0f) : c_dead));

	GUI::DrawText(name2, tl + Vec2f(arena_name_width + padding * 2, height / 2 + padding), (instance.ongoing ? c_regular : (instance.winner == 1 ? c_active : c_dead)));
	GUI::DrawLine2D(Vec2f(tl.x + arena_name_width + padding * 3, br.y - padding), Vec2f(br.x - 2 * padding, br.y - padding), (arena_id == 0 && winner_pos == 1 ? HSVToRGB(2 * getGameTime() % 360, 1.0f, 1.0f) : c_dead));

	if (arena_id == 0 && winner_pos > -1)
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