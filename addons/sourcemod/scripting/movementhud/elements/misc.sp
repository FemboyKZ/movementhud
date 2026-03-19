
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


void OnPluginStart_Elements_Mode()
{
    OnPluginStart_Elements_Mode_Speed();
    OnPluginStart_Elements_Mode_Keys();
    OnPluginStart_Elements_Mode_Indicators();
    OnPluginStart_Elements_Mode_DistPred();
}

void OnPluginStart_Elements_Other()
{
    OnPluginStart_Elements_Other_Speed();
    OnPluginStart_Elements_Other_Keys();
    OnPluginStart_Elements_Other_Indicators();

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