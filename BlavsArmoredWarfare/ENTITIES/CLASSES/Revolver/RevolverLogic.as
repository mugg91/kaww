#include "ThrowCommon.as";
#include "KnockedCommon.as";
#include "RunnerCommon.as";
#include "ShieldCommon.as";
#include "BombCommon.as";
#include "Hitters.as";
#include "Recoil.as";
#include "RevolverCommon.as";

void onInit(CBlob@ this)
{
	this.set_u32("mag_bullets_max", 6); // mag size
	//this.set_u32("total_ammo", 36); // ???

	this.set_u32("mag_bullets", this.get_u32("mag_bullets_max"));

	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.Tag("player");
	this.Tag("flesh");
	this.addCommandID("sync_reload_to_server");

	this.set_u8("hitmarker", 0);
	this.set_s8("reloadtime", 0); // for server
	this.set_u32("end_stabbing", 0);

	this.set_s8("charge_time", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);

	this.set_u8("recoil_count", 0);
	this.set_s8("recoil_direction", 0);
	this.set_u8("inaccuracy", 0);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -80.0f));

	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot bullet");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";	
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached())
	{
		if (customData == Hitters::explosion)
			return damage*0.05f;
		else if (customData == Hitters::arrow)
			return damage*0.5f;
		else return 0;
	}
	if (hitterBlob.getName() == "ballista_bolt")
	{
		bool at_bunker = false;
		Vec2f pos = this.getPosition();
		Vec2f hit_pos = hitterBlob.getPosition();

		if (!getMap().rayCastSolidNoBlobs(pos, hit_pos))
		{
			HitInfo@[] infos;
			Vec2f hitvec = hit_pos - pos;

			if (getMap().getHitInfosFromRay(pos, -hitvec.Angle(), hitvec.getLength(), this, @infos))
			{
				for (u16 i = 0; i < infos.length; i++)
				{
					CBlob@ hi = infos[i].blob;
					if (hi is null) continue;
					if (hi.hasTag("bunker") || hi.hasTag("tank")) 
					{
						return damage * 0.1f;
					}
					else if (hi is hitterBlob) return damage;
				}
			}
		}

		if (at_bunker) return 0;
		else if (customData == Hitters::explosion && hitterBlob.getName() != "grenade")
		{
			return damage * 0.15f;
		}
	}

	return damage;
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (!getNet().isServer()) { return; }
	if (aimangle < 0.0f) { aimangle += 360.0f; }

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = 16.0f;

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null) // blob
			{
				if (b.hasTag("ignore sword")) continue;
				if (b.getTeamNum() == this.getTeamNum()) return;
				if (b.getName() == "wooden_platform" || b.hasTag("door")) damage *= 1.5;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!dontHitMore)
				{
					this.server_Hit(b, hi.hitpos, Vec2f(0,0), damage, type, true); 
					
					// end hitting if we hit something solid, don't if its flesh
				}
			}
		}
	}
}

void ManageGun(CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars)
{
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && !ismyplayer)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			responsible = p.isBot();
		}
	}

	CControls@ controls = this.getControls();
	CSprite@ sprite = this.getSprite();
	s8 charge_time = archer.charge_time; //this.get_s32("my_chargetime");
	bool isStabbing = archer.isStabbing;
	bool isReloading = this.get_bool("isReloading"); //archer.isReloading;
	u8 charge_state = archer.charge_state;
	bool just_action1 = this.isKeyJustPressed(key_action1) && this.get_u32("dont_change_zoom") < getGameTime(); // binoculars thing
	bool is_action1 = this.isKeyPressed(key_action1);
	bool was_action1 = this.wasKeyPressed(key_action1);
	if (this.isKeyJustPressed(key_action3) && !isReloading && this.get_u32("end_stabbing") < getGameTime())
	{
		this.set_u32("end_stabbing", getGameTime()+18);
		this.Tag("attacking");
	}
	if (this.hasTag("attacking"))
	{
		f32 attackarc = 50.0f;
		DoAttack(this, 2.0f, (this.isFacingLeft() ? 180.0f : 0.0f), attackarc, Hitters::sword);
		this.Untag("attacking");
	}
	if (this.get_u32("end_stabbing") > getGameTime())
	{
		just_action1 = false;
		is_action1 = false;
		was_action1 = false;
	}
	const bool pressed_action2 = this.isKeyPressed(key_action2);
	bool menuopen = getHUD().hasButtons();
	Vec2f pos = this.getPosition();

	if (!this.isOnGround())
	{
		this.set_u8("inaccuracy", this.get_u8("inaccuracy") + 7);
		if (this.get_u8("inaccuracy") > inaccuracycap) { this.set_u8("inaccuracy", inaccuracycap); }
		this.setVelocity(Vec2f(this.getVelocity().x*0.87f, this.getVelocity().y));
	}
	
	if (this.isKeyPressed(key_action2))
	{
		this.Untag("scopedin");

		if (!isReloading && !menuopen || this.hasTag("attacking"))
		{
			moveVars.walkFactor *= 0.65f;
			this.Tag("scopedin");
		}
	}
	else
	{
		this.Untag("scopedin");
	}

	// reload
	//if (getGameTime()%90==0) printf("mag"+this.get_u32("mag_bullets"));
	//if (getGameTime()%90==0) printf("max"+this.get_u32("mag_bullets_max"));
	if (charge_time == 0 && controls !is null && !archer.isReloading && controls.isKeyJustPressed(KEY_KEY_R) && this.get_u32("mag_bullets") < this.get_u32("mag_bullets_max"))
	{
		CInventory@ inv = this.getInventory();
		if (inv !is null && inv.getItem("mat_7mmround") !is null)
		{
			charge_time = reloadtime;
			//archer.isReloading = true;
			isReloading = true;
			this.set_bool("isReloading", true);

			CBitStream params; // sync to server
			if (isClient())
			{
				params.write_s8(charge_time);
				this.SendCommand(this.getCommandID("sync_reload_to_server"), params);
			}
		}
		else if (ismyplayer)
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.85);
		}
	}
	if (isServer() && this.hasTag("sync_reload"))
	{
		s8 reload = charge_time > 0 ? charge_time : this.get_s8("reloadtime");
		if (reload > 0)
		{
			charge_time = reload;
			//archer.isReloading = true;
			this.set_bool("isReloading", true);
			this.Sync("isReloading", true);
			isReloading = true;
			this.Untag("sync_reload");
		}
	}
	// shoot
	if (charge_time == 0 && semiauto ? just_action1 : this.isKeyPressed(key_action1))
	{
		moveVars.walkFactor *= 0.5f;
		moveVars.jumpFactor *= 0.7f;
		moveVars.canVault = false;

		if (charge_time == 0 && isStabbing == false)
		{
			if (menuopen) return;
			if (isReloading) return;

			charge_state = ArcherParams::readying;

			if (this.get_u32("mag_bullets") <= 0)
			{
				charge_state = ArcherParams::no_ammo;

				if (ismyplayer && !this.wasKeyPressed(key_action1))
				{
					this.getSprite().PlaySound("EmptyGun.ogg", 0.4);
				}
			}
			else
			{
				if (ismyplayer)
				{
					this.AddForce(Vec2f(this.getAimPos() - this.getPosition()) * (this.hasTag("scopedin") ? -recoilforce/1.6 : -recoilforce));

					float angle = Maths::ATan2(this.getAimPos().y - this.getPosition().y, this.getAimPos().x - this.getPosition().x) * 180 / 3.14159;
					angle += -0.099f + (XORRandom(2) * 0.01f);

					if (this.isFacingLeft())
					{
						ParticleAnimated("Muzzleflash", this.getPosition() + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, this.isFacingLeft()?90:270) + Vec2f(0.0f, -0.05f), angle, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
					}
					else
					{
						ParticleAnimated("Muzzleflashflip", this.getPosition() + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, this.isFacingLeft()?90:270) + Vec2f(0.0f, -0.05f), angle + 180, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
					}

					ClientFire(this, charge_time);
				}
				else
				{
					sprite.SetEmitSoundVolume(0.5f);
				}
				charge_time = delayafterfire;
				charge_state = ArcherParams::fired;
			}
		}
		else
		{
			charge_time--;

				if (charge_time <= 0)
				{
					charge_time = 0;
					if (isReloading)
					{
						// reload
						CInventory@ inv = this.getInventory();
						if (inv !is null)
						{
							//printf(""+need_ammo);
							//printf(""+current);
							for (u8 i = 0; i < 20; i++)
							{
								u32 current = this.get_u32("mag_bullets");
								u32 max = this.get_u32("mag_bullets_max");
								u32 miss = max-current;
								CBlob@ mag;
								for (u8 i = 0; i < inv.getItemsCount(); i++)
								{
									CBlob@ b = inv.getItem(i);
									if (b is null || b.getName() != "mat_7mmround" || b.hasTag("dead")) continue;
									@mag = @b;
									break;
								}
								if (mag !is null)
								{
									u16 quantity = mag.getQuantity();
									if (quantity <= miss)
									{
										//printf("a");
										//printf(""+miss);
										//printf(""+quantity);
										this.add_u32("mag_bullets", quantity);
										mag.Tag("dead");
										if (isServer()) mag.server_Die();
										continue;
									}
									else
									{
										this.set_u32("mag_bullets", max);
										if (isServer()) mag.server_SetQuantity(quantity - miss);
										break;
									}
								}
								else break;
							}
						}
					}
					archer.isStabbing = false;
					archer.isReloading = false;

					this.set_bool("isReloading", false);
				}

			}
		}
		else
		{
			charge_time--;

				if (charge_time <= 0)
				{
					charge_time = 0;
					if (isReloading)
					{
						// reload
						CInventory@ inv = this.getInventory();
						if (inv !is null)
						{
							//printf(""+need_ammo);
							//printf(""+current);
							for (u8 i = 0; i < 20; i++)
							{
								u32 current = this.get_u32("mag_bullets");
								u32 max = this.get_u32("mag_bullets_max");
								u32 miss = max-current;
								CBlob@ mag;
								for (u8 i = 0; i < inv.getItemsCount(); i++)
								{
									CBlob@ b = inv.getItem(i);
									if (b is null || b.getName() != "mat_7mmround" || b.hasTag("dead")) continue;
									@mag = @b;
									break;
								}
								if (mag !is null)
								{
									u16 quantity = mag.getQuantity();
									if (quantity <= miss)
									{
										//printf("a");
										//printf(""+miss);
										//printf(""+quantity);
										this.add_u32("mag_bullets", quantity);
										mag.Tag("dead");
										if (isServer()) mag.server_Die();
										continue;
									}
									else
									{
										//printf("e");
										this.set_u32("mag_bullets", max);
										if (isServer()) mag.server_SetQuantity(quantity - miss);
										break;
									}
								}
								else break;
							}
						}
						if (isServer()) this.set_s8("reloadtime", 0);
					}

					archer.isStabbing = false;
					archer.isReloading = false;

					this.set_bool("isReloading", false);
				}

		if (this.getPlayer() !is null)
		{
			bool sprint = this.getHealth() >= this.getInitialHealth() * 0.75f && this.isOnGround() && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
			if (sprint)
			{
				if (!this.hasTag("sprinting"))
				{
					if (isClient())
					{
						Vec2f pos = this.getPosition();
						CMap@ map = getMap();

						ParticleAnimated("DustSmall.png", pos-Vec2f(0, -3.75f), Vec2f(this.isFacingLeft() ? 1.0f : -1.0f, -0.1f), 0.0f, 0.75f, 2, XORRandom(70) * -0.00005f, true);
					}
				}
				
				this.Tag("sprinting");
				moveVars.walkFactor *= this.getPlayer().hasTag("Max Speed") ? 1.3f : 1.2f;
				moveVars.walkSpeedInAir = 3.15f;
				moveVars.jumpFactor *= this.getPlayer().hasTag("Max Speed") ? 1.3f : 1.0f;
			}
			else
			{
				this.Untag("sprinting");
				moveVars.walkFactor *= this.getPlayer().hasTag("Max Speed") ? 1.3f : 1.0f;
				moveVars.walkSpeedInAir = 2.5f;
				moveVars.jumpFactor *= this.getPlayer().hasTag("Max Speed") ? 1.3f : 1.0f;
			}
		}
	}

	// inhibit movement
	if (charge_time > 0)
	{
		if (isReloading)
		{
			this.set_u8("inaccuracy", 0);
			moveVars.walkFactor *= 0.55f;
		}
		if (isStabbing)
		{
			moveVars.walkFactor *= 0.2f;
			moveVars.jumpFactor *= 0.8f;
		}
	}

	if (this.get_u8("hitmarker") > 0)
	{
		this.set_u8("hitmarker", this.get_u8("hitmarker")-1);

		if (this.get_u8("hitmarker") == 20)
		{
			this.set_u8("hitmarker", 0);
		}
	}

	if (this.get_u8("recoil_count") > 0)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				Recoil(this, local, this.get_u8("recoil_count")/3, this.isFacingLeft() ? 1 : -1);
			}
		}

		this.set_u8("recoil_count", Maths::Floor(this.get_u8("recoil_count") / lengthofrecoilarc));
	}

	if (this.get_u8("inaccuracy") > 0)
	{
		s8 testnum = (this.get_u8("inaccuracy") - 5);
		if (testnum < 0)
		{
			this.set_u8("inaccuracy", 0);
		}
		else
		{
			this.set_u8("inaccuracy", this.get_u8("inaccuracy") - 5);
		}
		
		if (this.get_u8("inaccuracy") > inaccuracycap) {this.set_u8("inaccuracy", inaccuracycap);}
	}
	
	if (responsible)
	{
		// set cursor
		if (ismyplayer && !getHUD().hasButtons())
		{
			int frame = 0;

			if (this.get_u8("inaccuracy") == 0)
			{
				getHUD().SetCursorFrame(0);
			}
			else
			{
				frame = Maths::Floor(this.get_u8("inaccuracy") / 5);

				if (frame > 9)
				{
					frame = 9;
				}
				getHUD().SetCursorFrame(frame);
			}
		}

		// activate/throw
		//if (this.isKeyJustPressed(key_action3))
		//{
		//	client_SendThrowOrActivateCommand(this);
		//}
	}

	archer.charge_time = charge_time;
	archer.charge_state = charge_state;
}

void onTick(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		archer.charge_time = 0;
		getHUD().SetCursorFrame(0);
		return;
	}

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	ManageGun(this, archer, moveVars);

	if (!this.isOnGround()) // ladders sometimes dont work
	{
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			if (blobs[i] !is null && blobs[i].getName() == "ladder")
			{
				if (this.isOverlapping(blobs[i])) 
				{
					this.getShape().getVars().onladder = true;
					break;
				}
			}
		}
	}
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire(CBlob@ this, const s8 charge_time)
{
	if (canSend(this))
	{
		Vec2f targetVector = this.getAimPos() - this.getPosition();
		f32 targetDistance = targetVector.Length();
		f32 targetFactor = targetDistance / 367.0f;

		ShootBullet(this, this.getPosition() - Vec2f(0,2), this.getAimPos() + Vec2f(-(2 + this.get_u8("inaccuracy")) + XORRandom(4 + this.get_u8("inaccuracy"))*targetFactor, -(2 + this.get_u8("inaccuracy")) + XORRandom(4 + this.get_u8("inaccuracy")))*targetFactor, 17.59f * bulletvelocity);

		CMap@ map = getMap();
		ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -0.0f), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		
		CPlayer@ p = getLocalPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				CPlayer@ ply = local.getPlayer();

				if (ply !is null && ply.isMyPlayer())
				{
					f32 mod = 0.5; // make some smart stuff here?
					if (this.isKeyPressed(key_action2)) mod *= 0.25;

					ShakeScreen((Vec2f(recoilx - XORRandom(recoilx*2) + 1, -recoily + XORRandom(recoily) + 1) * mod), recoillength*mod, this.getInterpolatedPosition());
					ShakeScreen(28*mod, 12*mod, this.getPosition());

					this.set_u8("recoil_count", this.isKeyPressed(key_action2) ? recoilcursor*adscushionamount : recoilcursor);               //freq //ampt
					this.set_s8("recoil_direction", (20 - XORRandom(41)) / sidewaysrecoildamp);

					//this.set_u8("recoil_count", recoilcursor);               //freq //ampt
					//this.set_s8("recoil_direction", ((Maths::Sin(getGameTime()*0.1)/0.06f) + (20 - XORRandom(41))) / sidewaysrecoildamp);


					this.set_u8("inaccuracy", this.get_u8("inaccuracy") + inaccuracypershot * (this.hasTag("sprinting")?2.0f:1.0f));
				}
			}
		}
	}
}

void ShootBullet(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	if (canSend(this))
	{
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);

		this.SendCommand(this.getCommandID("shoot bullet"), params);
	}
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	CBlob@ proj = server_CreateBlobNoInit("bullet");
	if (proj !is null)
	{
		proj.SetDamageOwnerPlayer(this.getPlayer());
		proj.Init();

		proj.set_f32("bullet_damage_body", damage_body);
		proj.set_f32("bullet_damage_head", damage_head);
		proj.IgnoreCollisionWhileOverlapped(this);
		proj.server_setTeamNum(this.getTeamNum());
		proj.setVelocity(arrowVel);
		proj.getShape().setDrag(proj.getShape().getDrag() * 0.3f);
		proj.setPosition(arrowPos);
	}
	return proj;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer)) return;

		if (getNet().isServer())
		{
			CBlob@ proj = CreateProj(this, arrowPos, arrowVel);
			proj.server_SetTimeToDie(1.5);
		}

		if (this.get_u32("mag_bullets") > 0) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
		if (this.get_u32("mag_bullets") > this.get_u32("mag_bullets_max")) this.set_u32("mag_bullets", this.get_u32("mag_bullets_max"));

		this.getSprite().PlaySound(shootsfx, 1.4f, 0.95f + XORRandom(15) * 0.01f);
		//this.set_u32("total_ammo", this.get_u32("total_ammo") - 1);
	}
	else if (cmd == this.getCommandID("sync_reload_to_server"))
	{
		if (isClient())
		{
			this.getSprite().PlaySound(reloadsfx, 0.8);
			for (uint i = 0; i < 6; i++)
			{
				makeGibParticle(
				"EmptyShellSmall",      		            // file name
				this.getPosition() + Vec2f(this.isFacingLeft() ? -6.0f : 6.0f, 0.0f), // position
				Vec2f(this.isFacingLeft() ? 1.0f+(0.1f * XORRandom(10) - 0.5f) : -1.0f-(0.1f * XORRandom(10) - 0.5f), 0.0f), // velocity
				0,                                  // column
				0,                                  // row
				Vec2f(16, 16),                      // frame size
				0.2f,                               // scale?
				0,                                  // ?
				"ShellCasing",                      // sound
				this.get_u8("team_color"));         // team number
			}
		}
		if (isServer())
		{
			s8 reload = params.read_s8();
			this.set_s8("reloadtime", reload);
			//printf("Synced to server: "+this.get_s8("reloadtime"));
			this.Tag("sync_reload");
			//this.Sync("isReloading", true);
		}

		this.set_bool("isReloading", true);
	}
}

bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{
		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;
	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();
}