static Handle DistPredHudSync;

MHudBoolPreference DistPredMode;
MHudXYPreference DistPredPosition;
MHudRGBPreference DistPredColor;
MHudBoolPreference DistPredTierColor;

// GOKZ jumpstat tier RGB colors (from sourcemod-colors.inc)
static int DistPredTierRGB[DISTANCETIER_COUNT][3] =
{
    { 204, 204, 204 }, // None - grey
    { 204, 204, 204 }, // Meh - grey
    { 153, 204, 255 }, // Impressive - blue
    { 62, 255, 62 },   // Perfect - green
    { 139, 0, 0 },     // Godlike - darkred
    { 255, 215, 0 },   // Ownage - gold
    { 218, 112, 214 }  // Wrecker - orchid
};

// Tier distance thresholds loaded from GOKZ config
// Indexed by [jumpType][mode][tier]
static float gF_DistPredTiers[JUMPTYPE_COUNT - 3][MODE_COUNT][DISTANCETIER_COUNT];
static bool gB_DistPredTiersLoaded;

// Track current jump type per player (set by GOKZ_JS_OnTakeoff)
static int gI_DistPredJumpType[MAXPLAYERS + 1] = { JumpType_LongJump, ... };

void OnPluginStart_Elements_Mode_DistPred()
{
    DistPredMode = new MHudBoolPreference("distpred_mode", "Distance Prediction - Mode", false);
    DistPredPosition = new MHudXYPreference("distpred_position", "Distance Prediction - Position", -1, 625);
}

void OnPluginStart_Elements_Other_DistPred()
{
    DistPredHudSync = CreateHudSynchronizer();

    DistPredColor = new MHudRGBPreference("distpred_color", "Distance Prediction - Color", 255, 80, 0);
    DistPredTierColor = new MHudBoolPreference("distpred_tier_color", "Distance Prediction - Use Tier Colors", false);
}

void OnMapStart_DistPredTiers()
{
    gB_DistPredTiersLoaded = LoadDistPredTiers();
}

void OnClientPutInServer_DistPred(int client)
{
    gI_DistPredJumpType[client] = JumpType_LongJump;
}

public void GOKZ_JS_OnTakeoff(int client, int jumpType)
{
    gI_DistPredJumpType[client] = jumpType;
}

static bool LoadDistPredTiers()
{
    KeyValues kv = new KeyValues("tiers");
    if (!kv.ImportFromFile(JS_CFG_TIERS))
    {
        delete kv;
        return false;
    }

    for (int jumpType = 0; jumpType < JUMPTYPE_COUNT - 3; jumpType++)
    {
        if (!kv.JumpToKey(gC_JumpTypeKeys[jumpType]))
        {
            delete kv;
            return false;
        }

        for (int mode = 0; mode < MODE_COUNT; mode++)
        {
            if (!kv.JumpToKey(gC_ModeKeys[mode]))
            {
                delete kv;
                return false;
            }

            for (int tier = DistanceTier_Meh; tier < DISTANCETIER_COUNT; tier++)
            {
                gF_DistPredTiers[jumpType][mode][tier] = kv.GetFloat(gC_DistanceTierKeys[tier], 0.0);
            }

            kv.GoBack(); // back from mode
        }

        kv.GoBack(); // back from jumpType
    }

    delete kv;
    return true;
}

static int GetDistPredTier(float distance, int jumpType, int mode)
{
    // Only tiered jump types have thresholds (exclude Fall, Other, Invalid)
    if (jumpType < 0 || jumpType >= JUMPTYPE_COUNT - 3)
    {
        jumpType = JumpType_LongJump;
    }

    int tier = DistanceTier_None;
    while (tier + 1 < DISTANCETIER_COUNT && distance >= gF_DistPredTiers[jumpType][mode][tier + 1])
    {
        tier++;
    }
    return tier;
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
    float remaining = gF_JumpAirTime[target] - elapsed;

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
    if (DistPredTierColor.GetBool(client) && gB_DistPredTiersLoaded)
    {
        int mode = GOKZ_GetCoreOption(target, Option_Mode);
        int tier = GetDistPredTier(totalDistance, gI_DistPredJumpType[target], mode);
        rgb[0] = DistPredTierRGB[tier][0];
        rgb[1] = DistPredTierRGB[tier][1];
        rgb[2] = DistPredTierRGB[tier][2];
    }
    else
    {
        DistPredColor.GetRGB(client, rgb);
    }

    float xy[2];
    DistPredPosition.GetXY(client, xy);

    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);
    ShowSyncHudText(client, DistPredHudSync, "%.1f", totalDistance);
}
