#include "Requirements.as"
#include "ShopCommon.as"

// initial costs
const u16 c_moto = 5;
const u16 c_amoto = 7;
const u16 c_truck = 12;
const u16 c_truckbig = 20;
const u16 c_pszh = 15;
const u16 c_btr = 25;
const u16 c_bradley = 40;
const u16 c_m60 = 45;
const u16 c_bc25t = 45;
const u16 c_t10 = 70;
const u16 c_maus = 125;
const u16 c_arti = 60;
const u16 c_harti = 20;
const u16 c_bf109 = 35;
const u16 c_bomber = 65;
const u16 c_uh1 = 50;
const u16 c_ah1 = 60;
const u16 c_barge = 10;
const u16 c_armory = 30;
const u16 c_mgun = 8;
const u16 c_ftw = 12;
const u16 c_c4 = 10;
const u16 c_jav = 15;
const u16 c_apsniper = 20;
// common
const string b = "blob";
const string s = "mat_scrap";
const string ds = "Scrap";
// names
const string n_moto = "Build a Motorcycle";
const string n_amoto = "Build a Motorcycle with machinegun";
const string n_truck = "Build a Truck";
const string n_truckbig = "Build a Cargo Truck";
const string n_pszh = "Build a PSZH-4 Light APC";
const string n_btr = "Build a BTR-82A Medium APC";
const string n_bradley = "Build a Braldey-M1A2 Heavy APC";
const string n_m60 = "Build a M60 Medium Tank";
const string n_bc25t = "Build a Bat.-Cht. 25t Light Tank";
const string n_t10 = "Build a T10 Heavy Tank";
const string n_maus = "Build a Maus Super Heavy Tank";
const string n_arti = "Build an Artillery";
const string n_harti = "Build an Infantry Mortar";
const string n_bf109 = "Build a Fighter plane";
const string n_bomber = "Build a Heavy Bomber plane";
const string n_uh1 = "Build a UH-1 Versatile Helicopter";
const string n_ah1 = "Build a AH-1 Destroyer Helicopter";
const string n_barge = "Build a Barge";
const string n_armory = "Build an Armory Truck";
const string n_mgun = "Construct a Heavy Machinegun";
const string n_ftw = "Construct a Firethrower";
const string n_c4 = "Construct a C-4 Explosive";
const string n_jav = "Construct a Javelin Missile launcher";
const string n_apsniper = "Armor-Penetrating Sniper Rifle.";
// descriptions
const string d_moto = "Speedy transport.";
const string d_amoto = "Armed motorcycle.";
const string d_truck = "Lightweight transport.\n\nUses Ammunition.";
const string d_truckbig = "A modernized truck. Commonly used for gang battles.\n\nUses Ammunition.";
const string d_pszh = "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.";
const string d_btr = "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.";
const string d_bradley = "Heavy and armed with a medium cannon APC.\n\nPowerful engine, fast, good elevation angles\nWeak armor\n\nUses 14.5mm and optionally HEAT warheads.";
const string d_m60 = "Medium tank.\n\nPowerful engine, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.";
const string d_bc25t = "Light tank.\n\nFast, excellent elevation angles, 4 shells in loading cassette\nWeak engine, weak turret (weakpoint)\n\nUses 105mm";
const string d_t10 = "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.";
const string d_maus = "Super heavy tank.\n\nThick armor, best turret armor, big cannon high-explosive damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm";
const string d_arti = "A long-range, slow and fragile artillery.\n\nUses Bombs.";
const string d_harti = "A short-range, less powerful but mobile mortar.\n\nUses Bombs.";
const string d_bf109 = "Fighter plane.\nUses Ammunition.";
const string d_bomber = "Heavy Bomber plane.\nUses Bombs.";
const string d_uh1 = "A helicopter with heavy machinegun.\nPress SPACEBAR to launch missiles";
const string d_ah1 = "A destroyer-helicopter with a protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch Rockets.\nPress LMB to release homing missile decoy.";
const string d_barge = "An armored boat for transporting vehicles across water.";
const string d_armory = "Supply truck.\nAllows to switch class and perk.";
const string d_mgun = "Heavy machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";
const string d_ftw = "Fire thrower.\nCan be attached to and detached from some vehicles.\n\nUses Special Ammunition.";
const string d_c4 = "A strong explosive, very effective against blocks and doors.\n\nTakes some time after activation to explode.\nYou can deactivate it as well.";
const string d_jav = "Homing Missile launcher.";
const string d_apsniper = "Armor-Penetrating Sniper Rifle.\nPenetrates non-solid blocks and flesh. Can reach tank crew through armor.\n\nUses Special Ammunition.";
// blobnames
const string bn_moto = "motorcycle";
const string bn_amoto = "armedmotorcycle";
const string bn_truck = "techtruck";
const string bn_truckbig = "techbigtruck";
const string bn_pszh = "pszh4";
const string bn_btr = "btr82a";
const string bn_bradley = "bradley";
const string bn_m60 = "m60";
const string bn_bc25t = "bc25t";
const string bn_t10 = "t10";
const string bn_maus = "maus";
const string bn_arti = "artillery";
const string bn_harti = "mortar";
const string bn_bf109 = "bf109";
const string bn_bomber = "bomberplane";
const string bn_uh1 = "uh1";
const string bn_ah1 = "ah1";
const string bn_barge = "barge";
const string bn_armory = "armory";
const string bn_mgun = "heavygun";
const string bn_ftw = "firethrower";
const string bn_c4 = "c4";
const string bn_jav = "launcher_javelin";
const string bn_apsniper = "apsniper";
// icon tokens
const string t_moto = "$"+bn_moto+"$";
const string t_amoto = "$"+bn_amoto+"$";
const string t_truck = "$"+bn_truck+"$";
const string t_truckbig = "$"+bn_truckbig+"$";
const string t_pszh = "$"+bn_pszh+"$";
const string t_btr = "$"+bn_btr+"$";
const string t_bradley = "$"+bn_bradley+"$";
const string t_m60 = "$"+bn_m60+"$";
const string t_bc25t = "$"+bn_bc25t+"$";
const string t_t10 = "$"+bn_t10+"$";
const string t_maus = "$"+bn_maus+"$";
const string t_arti = "$"+bn_arti+"$";
const string t_harti = "$"+bn_harti+"$";
const string t_bf109 = "$"+bn_bf109+"$";
const string t_bomber = "$"+bn_bomber+"$";
const string t_uh1 = "$"+bn_uh1+"$";
const string t_ah1 = "$"+bn_ah1+"$";
const string t_barge = "$"+bn_barge+"$";
const string t_armory = "$"+bn_armory+"$";
const string t_mgun = "$icon_mg$";
const string t_ftw = "$icon_ft$";
const string t_c4 = "$"+bn_c4+"$";
const string t_jav = "$icon_jav$";
const string t_apsniper = "$"+bn_apsniper+"$";

void makeShopItem(CBlob@ this, string[] params, int cost, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	ShopItem@ s = addShopItem(this, params[0], params[1], params[2], params[3], inv, crate);
	if (inv || crate || dim.x > 1 || dim.y > 1)
	{
		s.customButton = true;
		s.buttonwidth = dim.x;
		s.buttonheight = dim.y;
	}
	AddRequirement(s.requirements, params[4], params[5], params[6], cost);
}