Handle g_IndicatorsHudSync;

MHudBoolPreference IndicatorsMode;
MHudRGBPreference IndicatorsColor;
MHudRGBPreference IndicatorsJBColor;
MHudRGBPreference IndicatorsPBColor;
MHudXYPreference IndicatorsPosition;

MHudBoolPreference IndicatorsJBEnabled;
MHudBoolPreference IndicatorsCJEnabled;
MHudBoolPreference IndicatorsPBEnabled;
MHudBoolPreference IndicatorsEBEnabled;

MHudBoolPreference IndicatorsAbbreviations;

MHudBoolPreference IndicatorsFTGEnabled;
MHudBoolPreference IndicatorsCrouchEnabled;

void OnPluginStart_Elements_Mode_Indicators()
{
    IndicatorsMode = new MHudBoolPreference("indicators_mode", "Indicators - Mode", true);
    IndicatorsPosition = new MHudXYPreference("indicators_position", "Indicators - Position", 550, 725);
}

void OnPluginStart_Elements_Other_Indicators()
{
    g_IndicatorsHudSync = CreateHudSynchronizer();

    IndicatorsJBEnabled = new MHudBoolPreference("indicators_jb_enabled", "Indicators - Jump Bug", false);
    IndicatorsCJEnabled = new MHudBoolPreference("indicators_cj_enabled", "Indicators - Crouch Jump", false);
    IndicatorsPBEnabled = new MHudBoolPreference("indicators_pb_enabled", "Indicators - Perfect Bhop", false);
    IndicatorsEBEnabled = new MHudBoolPreference("indicators_eb_enabled", "Indicators - Edge Bug", false);
    IndicatorsFTGEnabled = new MHudBoolPreference("indicators_ftg", "Indicators - First Tick Gain", false);
    IndicatorsCrouchEnabled = new MHudBoolPreference("indicators_crouch", "Indicators - Crouch Status", false);
    IndicatorsAbbreviations = new MHudBoolPreference("indicators_abbrs", "Indicators - Abbreviations", true);
    IndicatorsColor = new MHudRGBPreference("indicators_color", "Indicators - Color", 0, 255, 0);
    IndicatorsJBColor = new MHudRGBPreference("indicators_jb_color", "Indicators - Jump Bug Color", 0, 255, 0);
    IndicatorsPBColor = new MHudRGBPreference("indicators_pb_color", "Indicators - Perfect Bhop Color", 0, 255, 0);
}

void OnGameFrame_Element_Indicators(int client, int target)
{
    bool draw = IndicatorsMode.GetBool(client);
    bool drawJB = IndicatorsJBEnabled.GetBool(client) && gB_DidJumpBug[target];
    bool drawCJ = IndicatorsCJEnabled.GetBool(client) && gB_DidCrouchJump[target];
    bool drawPB = IndicatorsPBEnabled.GetBool(client) && gB_DidPerf[target];
    bool drawEB = IndicatorsEBEnabled.GetBool(client) && gB_DidEdgeBug[target];
    bool drawFTG = IndicatorsFTGEnabled.GetBool(client) && gB_FirstTickGain[target];
    bool isCrouched = (GetEntityFlags(target) & FL_DUCKING == FL_DUCKING);
    bool isInAir = !(GetEntityFlags(target) & FL_ONGROUND == FL_ONGROUND);
    bool notHoldingCrouch = !(gI_Buttons[target] & IN_DUCK == IN_DUCK);
    bool drawCrouch = IndicatorsCrouchEnabled.GetBool(client) && isCrouched && isInAir && notHoldingCrouch;

    // Nothing enabled
    if (!draw || (!drawJB && !drawCJ && !drawPB && !drawEB && !drawFTG && !drawCrouch))
    {
        return;
    }

    int rgb[3];
    if (drawJB)
    {
        IndicatorsJBColor.GetRGB(client, rgb);
    }
    else if (drawPB)
    {
        IndicatorsPBColor.GetRGB(client, rgb);
    }
    else
    {
        IndicatorsColor.GetRGB(client, rgb);
    }

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

    if (drawEB)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "EB" : "EDGE BUG"
        );
    }

    if (drawFTG)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "G" : "FIRST TICK GAIN"
        );
    }

    if (drawCrouch)
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "C" : "CROUCHED"
        );
    }
    ShowSyncHudText(client, g_IndicatorsHudSync, "%s", buffer);
}
