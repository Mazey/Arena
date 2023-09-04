// loads a classic KAG .PNG map
// fileName is "" on client!

#include "BasePNGLoader.as";
#include "MinimapHook.as";

// Arena custom map colors
namespace arena_colors
{
	enum color
	{
		alpha_arena = 0xFF91BEE1
	};
}

//the loader
class ArenaPNGLoader : PNGLoader
{
	ArenaPNGLoader()
	{
		super();
	}

	//override this to extend functionality per-pixel.
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);
		
		u8 alpha = pixel.getAlpha();

		if(alpha < 255)
		{
			alpha &= ~0x80;
			const Vec2f position = getSpawnPosition(map, offset);

			switch (pixel.color | 0xFF000000)
			{
				case arena_colors::alpha_arena:
				{
					autotile(offset);
					CBlob@ ruin = spawnBlob(map, "tdm_spawn", 0, Vec2f(0, -20) + position, true);

					ruin.set_u8("level", alpha);
					print("created ruin level " + alpha);
				} break;
			};
		}
	}
};

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING ARENA PNG MAP " + fileName);

	ArenaPNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map, fileName);
}