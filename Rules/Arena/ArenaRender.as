
#define CLIENT_ONLY

funcdef void MAP_LOADER_CALLBACK();
u8 max_arenas = 0;
ArenaOverlay[] overlays;

void onInit(CRules@ this)
{
    ReloadOverlays();
    MAP_LOADER_CALLBACK@ callback = @ReloadOverlays;
    this.set("MAP_LOADER_CALLBACK", @callback);

    Texture::createFromFile("pixel", "pixel.png");

    Render::addScript(Render::layer_postworld, "ArenaRender.as", "RenderArena", 0.0f);
}

void ReloadOverlays()
{
    CBlob@[] ruins;
	if (!getBlobsByName("tdm_spawn", ruins))
	{
		return;
	}
	max_arenas = ruins.length() / 2;
    Vec2f map_size = getMap().getMapDimensions();
    //print("map_size: " + map_size);
    uint height_step = map_size.y / max_arenas;
    Vec2f start_pos = Vec2f_zero;
    Vec2f end_pos = Vec2f(map_size.x, height_step);

    overlays.clear();
    for(int i = 0; i < max_arenas; i++)
    {
        overlays.push_back(ArenaOverlay(i, start_pos, end_pos));
        start_pos.y += height_step;
        end_pos.y += height_step;
    }
}

void onTick(CRules@ this)
{
    for(int i = 0; i < overlays.size(); i++)
    {
        overlays[i].Update();
    }
}

void RenderArena(int id)
{
    for(int i = 0; i < overlays.size(); i++)
    {
        overlays[i].Render();
    }
}

class ArenaOverlay
{
    u8 id;
    Vec2f start_pos;
    Vec2f end_pos;
    Vertex[] verts;
    uint16[] indices;
    bool draw;

    ArenaOverlay(u8 _id, Vec2f _start_pos, Vec2f _end_pos)
    {
        id = _id;
        start_pos = _start_pos;
        end_pos = _end_pos;
        draw = false;

        Vertex[] _verts = {
            Vertex(start_pos.x, end_pos.y, 1000.0f, 0.0f, 0.0f, color_black),
            Vertex(start_pos.x, start_pos.y, 1000.0f, 0.0f, 1.0f, color_black),
            Vertex(end_pos.x, start_pos.y, 1000.0f, 1.0f, 1.0f, color_black),
            Vertex(end_pos.x, end_pos.y, 1000.0f, 1.0f, 0.0f, color_black)
        };
        verts = _verts;

        uint16[] _indices = {
            0, 1, 2, 2, 3, 0
        };
        indices = _indices;
    }

    void Update()
    {
        CBlob@ player_blob = getLocalPlayerBlob();

        // dont render if spectator
        if (player_blob is null)
        {
            draw = false;
            return;
        }

        // dont render if in bounds
        if(player_blob.getPosition().x > start_pos.x && player_blob.getPosition().x < end_pos.x
            && player_blob.getPosition().y > start_pos.y && player_blob.getPosition().y < end_pos.y)
        {
            draw = false;
            return;
        }

        // in any other case we render
        draw = true;
    }

    void Render()
    {
        if (draw)
        {
            Render::RawTrianglesIndexed("pixel", verts, indices);
        }
    }
}