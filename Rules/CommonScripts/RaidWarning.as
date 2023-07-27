void onInit(CRules@ this)
{
	this.addCommandID("arena finish");
}

void onRestart(CRules@ this)
{
	this.set_u32("alert time", 0);
	this.set_string("current alert", "");
}


void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("arena finish"))
	{
		Sound::Play("RaidWarning.ogg");
		string name;
		u16 streak;
		if (!params.saferead_string(name) || !params.saferead_u16(streak)) 
			return;

		CPlayer@ player = getPlayerByUsername(name);

		if (player is null)
			return;

		string alert = getTranslatedString("Player {PLAYER} won the arena (streak {STREAK})!")
			.replace("{STREAK}", ""+streak)
			.replace("{PLAYER}", player.getCharacterName());
		this.set_string("current alert", alert);
		this.set_u32("alert time", getGameTime());
	}
}

string get_font(string file_name, s32 size)
{
    string result = file_name+"_"+size;
    if (!GUI::isFontLoaded(result)) {
        string full_file_name = CFileMatcher(file_name+".ttf").getFirst();
        // TODO(hobey): apparently you cannot load multiple different sizes of a font from the same font file in this api?
        GUI::LoadFont(result, full_file_name, size, true);
    }
    return result;
}

void onRender(CRules@ this)
{
	float screen_size_x = getDriver().getScreenWidth();
    float screen_size_y = getDriver().getScreenHeight();
	float resolution_scale = screen_size_y / 720.f; // NOTE(hobey): scaling relative to 1280x720
	string phrase_font_name              = get_font("GenShinGothic-P-Medium", s32(24.f * resolution_scale));
	GUI::SetFont(phrase_font_name);
	if (getGameTime() - this.get_u32("alert time") < 30 * 3)
	{
		string alert = this.get_string("current alert");

		GUI::DrawTextCentered(alert, Vec2f(getScreenWidth() / 2, getScreenHeight() / 3 - 70.0f),
			        SColor(255, 255, 55, 55));
	}
}