#include <sdkhooks>
#include <sdktools>
#include <topmenus>
#include <sourcemod>
#include <clientprefs>
#include <movementapi>
#include <json>
#include <base64>
#include <gokz>
#include <gokz/core>
#include <gokz/hud>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/replays>

#pragma semicolon 1
#pragma newdecls required

bool gB_IsReady;
bool gB_GOKZReplays;

#include <movementhud>

#include "movementhud/utils.sp"
#include "movementhud/movement.sp"
#include "movementhud/elements/misc.sp"
#include "movementhud/elements/keys.sp"
#include "movementhud/elements/speed.sp"
#include "movementhud/elements/indicators.sp"
#include "movementhud/elements/distpred.sp"

#include "movementhud/preferences.sp"
#include "movementhud/preferences_code.sp"
#include "movementhud/preferences_menu.sp"
#include "movementhud/preferences_defaults.sp"
#include "movementhud/preferences_chatinput.sp"

#include "movementhud/commands.sp"
#include "movementhud/api/natives.sp"
#include "movementhud/api/forwards.sp"

#include "movementhud/gokz.sp"

public Plugin myinfo =
{
	name = "MovementHUD",
	author = "Sikari, zer0.k, cinyan10, jvnipers",
	description = "Provides customizable displays for movement, FKZ version",
	version = MHUD_VERSION,
	url = MHUD_SOURCE_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("MovementHUD");

	OnAskPluginLoad2_Natives();
	OnAskPluginLoad2_Forwards();
	return APLRes_Success;
}

public void OnPluginStart()
{
	OnPluginStart_Commands();
	OnPluginStart_Preferences();
	OnPluginStart_PreferencesDefaults();

	OnPluginStart_Elements_Mode();
	OnPluginStart_Elements_Other();

	OnPluginStart_PreferencesCode();

	Call_OnReady();
	gB_IsReady = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnAllPluginsLoaded()
{
	gB_GOKZReplays = LibraryExists("gokz-replays");
}

public void OnLibraryAdded(const char[] name)
{
	gB_GOKZReplays = gB_GOKZReplays || StrEqual(name, "gokz-replays");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZReplays = gB_GOKZReplays && !StrEqual(name, "gokz-replays");
}

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_Movement(client);
	OnClientPutInServer_Preferences(client);
	OnClientPutInServer_PreferencesMenu(client);
	OnClientPutInServer_PreferencesChatInput(client);
}

public void OnClientCookiesCached(int client)
{
	OnClientCookiesCached_Preferences(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_TrackMovement(client);
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_Movement(client, buttons, mouse, tickcount);
}

public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || !ShouldUpdateHUD(client)) continue;
		int target = GetSpectedOrSelf(client);

		OnGameFrame_Element_Keys(client, target);
		OnGameFrame_Element_Speed(client, target);
		OnGameFrame_Element_Indicators(client, target);
		OnGameFrame_Element_DistPred(client, target);
	}
}