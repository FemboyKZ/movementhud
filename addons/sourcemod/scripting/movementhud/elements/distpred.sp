MHudBoolPreference DistPredMode;
MHudXYPreference DistPredPosition;
MHudRGBPreference DistPredColor;

#define JUMP_AIRTIME 0.7812 // CS:GO CJ 128t

void OnPluginStart_Elements_Mode_DistPred()
{
    DistPredMode = new MHudBoolPreference("distpred_mode", "Distance Prediction - Mode", false);
    DistPredPosition = new MHudXYPreference("distpred_position", "Distance Prediction - Position", -1, 625);
}

void OnPluginStart_Elements_Other_DistPred()
{
    DistPredColor = new MHudRGBPreference("distpred_color", "Distance Prediction - Color", 255, 80, 0);
}

void OnGameFrame_Element_DistPred(int client, int target)
{
    if (!DistPredMode.GetBool(client))
    {
        return;
    }

    bool onGround = gB_GotBotInfo[target] ? gH_BotInfo[target].OnGround : Movement_GetOnGround(target);
    if (onGround)
    {
        return;
    }

    float elapsed = GetEngineTime() - gF_JumpStartTime[target];
    float remaining = JUMP_AIRTIME - elapsed;

    if (remaining <= 0.0)
    {
        return;
    }

    float currOrigin[3];
    Movement_GetOrigin(target, currOrigin);

    float velocity[3];
    Movement_GetVelocity(target, velocity);

    float predX = currOrigin[0] + velocity[0] * remaining;
    float predY = currOrigin[1] + velocity[1] * remaining;

    float dx = predX - gF_JumpStartOrigin[target][0];
    float dy = predY - gF_JumpStartOrigin[target][1];
    float totalDistance = SquareRoot(dx * dx + dy * dy) + 32.0;

    int rgb[3];
    DistPredColor.GetRGB(client, rgb);

    float xy[2];
    DistPredPosition.GetXY(client, xy);

    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);
    ShowSyncHudText(client, g_IndicatorsHudSync, "%.1f", totalDistance);
}
