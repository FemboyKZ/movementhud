
MHudEnumPreference UpdateSpeed;
MHudBoolPreference DisableInFreeCamera;

static const char Speeds[UpdateSpeed_COUNT][] =
{
    "Fastest",
    "Fast",
    "Normal",
	"Slow",
	"Slowest"
};


// CS:GO's HUD text system only supports 6 channels (MAX_NETMESSAGE in hl2sdk message.cpp).
// Each CreateHudSynchronizer() claims a channel. Elements sharing a sync object will
// overwrite each other since ShowSyncHudText reuses the same channel for the same object.
// Current budget: Speed(1) + Keys(1) + Indicators(1) + DistPred(1) = 4/6 channels.
void OnPluginStart_Elements()
{
    OnPluginStart_Elements_Mode_Speed();
    OnPluginStart_Elements_Other_Speed();

    OnPluginStart_Elements_Mode_Keys();
    OnPluginStart_Elements_Other_Keys();

    OnPluginStart_Elements_Mode_Indicators();
    OnPluginStart_Elements_Other_Indicators();

    OnPluginStart_Elements_Mode_DistPred();
    OnPluginStart_Elements_Other_DistPred();

    UpdateSpeed = new MHudEnumPreference("update_speed", "Update Speed", Speeds, sizeof(Speeds) - 1, UpdateSpeed_Fastest);
    DisableInFreeCamera = new MHudBoolPreference("disable_in_freecam", "Disable HUD in Free Camera", false);
}

bool ShouldUpdateHUD(int client)
{
    if (DisableInFreeCamera.GetBool(client) && IsClientInFreeCamera(client))
    {
        return false;
    }

    return (client + GetGameTickCount()) % (UpdateSpeed.GetInt(client) + 1) == 0;
}

float GetTextHoldTimeMHUD(int client)
{
    return GetTextHoldTime(UpdateSpeed.GetInt(client) + 1);
}