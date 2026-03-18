Handle g_IndicatorsHudSync;

MHudBoolPreference IndicatorsMode;
MHudRGBPreference IndicatorsColor;
MHudXYPreference IndicatorsPosition;

MHudBoolPreference IndicatorsJBEnabled;
MHudBoolPreference IndicatorsCJEnabled;
MHudBoolPreference IndicatorsPBEnabled;

MHudBoolPreference IndicatorsAbbreviations;

MHudBoolPreference IndicatorsFTGEnabled;

void OnPluginStart_Elements_Mode_Indicators()
{
    IndicatorsMode = new MHudBoolPreference("indicators_mode", "Indicators - Mode", true);
    IndicatorsPosition = new MHudXYPreference("indicators_position", "Indicators - Position", 550, 725);
}

void OnPluginStart_Elements_Other_Indicators()
{
    g_IndicatorsHudSync = CreateHudSynchronizer();

    IndicatorsColor = new MHudRGBPreference("indicators_color", "Indicators - Color", 0, 255, 0);
    IndicatorsJBEnabled = new MHudBoolPreference("indicators_jb_enabled", "Indicators - Jump Bug", false);
    IndicatorsCJEnabled = new MHudBoolPreference("indicators_cj_enabled", "Indicators - Crouch Jump", false);
    IndicatorsPBEnabled = new MHudBoolPreference("indicators_pb_enabled", "Indicators - Perfect Bhop", false);
    IndicatorsFTGEnabled = new MHudBoolPreference("indicators_ftg", "Indicators - First Tick Gain", false);
    IndicatorsAbbreviations = new MHudBoolPreference("indicators_abbrs", "Indicators - Abbreviations", true);
}

void OnGameFrame_Element_Indicators(int client, int target)
{
    bool draw = IndicatorsMode.GetBool(client);
    bool drawJB = IndicatorsJBEnabled.GetBool(client) && gB_DidJumpBug[target];
    bool drawCJ = IndicatorsCJEnabled.GetBool(client) && gB_DidCrouchJump[target];
    bool drawPB = IndicatorsPBEnabled.GetBool(client) && gB_DidPerf[target];
    bool drawFTG = IndicatorsFTGEnabled.GetBool(client) && gB_FirstTickGain[target];

    // Nothing enabled
    if (!draw || (!drawJB && !drawCJ && !drawPB && !drawFTG))
    {
        return;
    }

    int rgb[3];
    IndicatorsColor.GetRGB(client, rgb);

    float xy[2];
    IndicatorsPosition.GetXY(client, xy);

    Call_OnDrawIndicators(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    bool useAbbr = IndicatorsAbbreviations.GetBool(client);

    char buffer[64];
    if (drawJB)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "JB" : "JUMPBUG"
        );
    }

    if (drawCJ)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "CJ" : "CROUCH JUMP"
        );
    }

    if (drawPB)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "PERF" : "PERFECT BHOP"
        );
    }

    if (drawFTG)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "G" : "FIRST TICK GAIN"
        );
    }
    ShowSyncHudText(client, g_IndicatorsHudSync, "%s", buffer);
}
