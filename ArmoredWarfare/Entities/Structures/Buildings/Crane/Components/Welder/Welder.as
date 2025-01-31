#include "Hitters.as";
#include "MaterialCommon.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
}

const u8 repair_rate = 22;

void onTick(CBlob@ this)
{
	bool active = this.hasTag("active");
	bool attached = this.hasTag("attached");
	bool timing = (getGameTime()+this.getNetworkID())%repair_rate==0;

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.SetRelativeZ(attached ? -55.0f : 0.0f);

		if (active)
		{
			if (XORRandom(5)==0) ParticleAnimated("LargeSmokeGray", this.getPosition(), Vec2f(XORRandom(11)*0.01f, 0).RotateBy(XORRandom(360)), 0, 0.25f + XORRandom(31) * 0.01f, 2 + XORRandom(3), -0.0031f, true);
			if (getGameTime()%4==0) sprite.PlaySound("welder_loop.ogg", 0.5f, 1.0f+XORRandom(6)*0.01f);

			if (timing)
			{
				sprite.PlaySound("welder_use.ogg", 1.0f, 0.75f+XORRandom(21)*0.01f);
				for (u8 i = 0; i < 10+XORRandom(10); i++)
				{
					sparks(this.getPosition()-Vec2f(4,4)+Vec2f(XORRandom(8),XORRandom(8)), XORRandom(360), 1.0f+XORRandom(51)*0.01f, SColor(255, 255, 255, XORRandom(125)));
				}
			}
		}
	}

	if (!isServer()) return;
	if (active && timing)
	{
		u8 team = this.getTeamNum();
		
		CBlob@[] repair;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @repair);

		for (u16 i = 0; i < repair.size(); i++)
		{
			CBlob@ blob = repair[i];
			if (blob !is null)
			{
				if (blob.hasTag("vehicle") || blob.hasTag("bunker") || blob.hasTag("structure") || blob.hasTag("door") || blob.hasTag("repairable"))
				{
					if (blob.hasTag("respawn") || blob.hasTag("never_repair")) continue; // dont repair outposts
					if (team == blob.getTeamNum() || blob.getTeamNum() >= 7)
					{
						float repair_amount = 0.5f;

						if (blob.hasTag("bunker"))
						{
							repair_amount *= 4;
						}
						else if (blob.hasTag("structure"))
						{
							repair_amount *= 20;
						}
						else if (blob.hasTag("machinegun"))
						{
							repair_amount *= 7.5f;
						}
						else if (blob.hasTag("vehicle"))
						{
							repair_amount *= 2;
						}
						else if (blob.hasTag("door"))
						{
							repair_amount *= blob.getInitialHealth()/5;
						}

						if (blob.getHealth() + repair_amount <= blob.getInitialHealth())
			            {
			                blob.server_SetHealth(blob.getHealth() + repair_amount);//Add the repair amount.

							break;
			            }
			            else //Repair amount would go above the inital health (max health). 
			            {
			                blob.server_SetHealth(blob.getInitialHealth());//Set health to the inital health (max health)
			            }
			    	}
			    }
			}
		}
	}
	this.setAngleDegrees(this.get_f32("angle"));
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 15+XORRandom(30));
}