static Handle HudSync;

MHudEnumPreference SpeedMode;
MHudXYPreference SpeedPosition;
MHudRGBPreference SpeedNormalColor;
MHudRGBPreference SpeedPerfColor;
MHudEnumPreference SpeedTakeoff;
MHudEnumPreference SpeedColorBySpeed;
MHudEnumPreference SpeedRounding;
MHudRGBPreference SpeedGainColor;
MHudRGBPreference SpeedLossColor;
MHudRGBPreference SpeedJBColor;

static const char Modes[SpeedMode_COUNT][] =
{
    "Disabled",
    "As decimal",
    "As whole number"
};

static const char Roundings[Round_COUNT][] =
{
    "Round down",
    "Round to nearest",
    "Round up"
};

static const char Takeoff[Takeoff_COUNT][] =
{
    "Disabled",
    "Jumps only",
    "Enabled"
};

static const char SpeedColors[SpeedKeyColor_COUNT][] =
{
    "Disabled",
    "Color by current speed",
    "Color by gain (Instant)",
    "Color by gain (Average)"
};

void OnPluginStart_Elements_Mode_Speed()
{
    SpeedMode = new MHudEnumPreference("speed_mode", "Speed - Mode", Modes, sizeof(Modes) - 1, SpeedMode_None);
    SpeedPosition = new MHudXYPreference("speed_position", "Speed - Position", -1, 725);
}

void OnPluginStart_Elements_Other_Speed()
{
    HudSync = CreateHudSynchronizer();

    SpeedNormalColor = new MHudRGBPreference("speed_color_normal", "Speed - Normal Color", 255, 255, 255);
    SpeedPerfColor = new MHudRGBPreference("speed_color_perf", "Speed - Perfect Bhop Color", 0, 255, 0);
    SpeedTakeoff = new MHudEnumPreference("speed_takeoff", "Speed - Show Takeoff", Takeoff, sizeof(Takeoff) - 1, Takeoff_Jump);
    SpeedRounding = new MHudEnumPreference("speed_rounding", "Speed - Rounding", Roundings, sizeof(Roundings) - 1, Round_Down);
    SpeedColorBySpeed = new MHudEnumPreference("speed_color_by_speed", "Speed - Color by Speed", SpeedColors, sizeof(SpeedColors) - 1, SpeedKeyColor_None);
    SpeedGainColor = new MHudRGBPreference("speed_color_gain", "Speed - Gain Color", 0, 255, 0);
    SpeedLossColor = new MHudRGBPreference("speed_color_loss", "Speed - Loss Color", 255, 0, 0);
    SpeedJBColor = new MHudRGBPreference("speed_color_jb", "Speed - Jump Bug Color", 0, 255, 0);
}

void OnGameFrame_Element_Speed(int client, int target)
{
    int mode = SpeedMode.GetInt(client);
    if (mode == SpeedMode_None)
    {
        return;
    }
    int rounding = SpeedRounding.GetInt(client);
    float speed = gF_CurrentSpeed[target];
    
    int showTakeoff = SpeedTakeoff.GetInt(client);
    int colorBySpeed = SpeedColorBySpeed.GetInt(client);

    float xy[2];
    SpeedPosition.GetXY(client, xy);

    int rgb[3];
    switch (colorBySpeed)
    {
        case SpeedKeyColor_None:
        {
            MHudRGBPreference colorPreference;
            if (gB_GotBotInfo[target])
            {
                colorPreference = gH_BotInfo[target].HitPerf && !gH_BotInfo[target].OnGround
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }
            else
            {
                colorPreference = gB_DidPerf[target]
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }

            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_Speed:
        {
            GetColorBySpeed(speed, rgb);
        }
        case SpeedKeyColor_GainInstant:
        {
            MHudRGBPreference colorPreference;
            if (gF_CurrentSpeed[client] - gF_OldSpeed[client] > 0.1)
            {
                colorPreference = SpeedGainColor;
            }
            else if (gF_CurrentSpeed[client] - gF_OldSpeed[client] < -0.1)
            {
                colorPreference = SpeedLossColor;
            }
            else 
            {
                colorPreference = gB_DidPerf[target]
                    ? SpeedPerfColor
                    : SpeedNormalColor;
            }
            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_GainAverage:
        {
            MHudRGBPreference colorPreference = gB_DidPerf[target]
                ? SpeedPerfColor
                : SpeedNormalColor;
            colorPreference.GetRGB(client, rgb);
            float gainTicks;
            int gainRGB[3];
            
            for (int i = 0; i < MAX_TRACKED_TICKS; i++)
            {
                if (gF_SpeedChange[client][i] > 0.1)
                {
                    gainTicks += 1.0;
                }
                else if (gF_SpeedChange[client][i] < -0.1)
                {
                    gainTicks -= 1.0;
                }
            }
            
            if (gainTicks >= 0)
            {
                SpeedGainColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, gainTicks/MAX_TRACKED_TICKS, rgb);
            }
            else
            {
                SpeedLossColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, -gainTicks/MAX_TRACKED_TICKS, rgb);
            }
        }
    }

    if (gB_DidJumpBug[target])
    {
        SpeedJBColor.GetRGB(client, rgb);
    }

    Call_OnDrawSpeed(client, xy, rgb);
    
    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    if (mode == SpeedMode_Float)
    {
        if (showTakeoff == Takeoff_None || !gB_DidTakeoff[target] || (showTakeoff == Takeoff_Jump && !gB_DidJump[target]))
        {
            ShowSyncHudText(client, HudSync, "%.2f", speed);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%.2f\n(%.2f)", speed, gF_TakeoffSpeed[target]);
        }
    }
    else
    {
        int speedInt;
        int takeoffSpeedInt;
        switch (rounding)
        {
            case Round_Down:
            {
                // Prevent speed flickering
                speedInt = RoundToFloor(speed);
                if (speed - speedInt >= 0.999)
                {
                    speedInt++;
                }
                takeoffSpeedInt = RoundToFloor(gF_TakeoffSpeed[target]);
                if (gF_TakeoffSpeed[target] - takeoffSpeedInt >= 0.999)
                {
                    takeoffSpeedInt++;
                }
            }
            case Round_Nearest:
            {
                speedInt = RoundToNearest(speed);
                takeoffSpeedInt = RoundToNearest(gF_TakeoffSpeed[target]);
            }
            case Round_Up:
            {
                speedInt = RoundToCeil(speed);
                takeoffSpeedInt = RoundToCeil(gF_TakeoffSpeed[target]);
            }
        }
        if (showTakeoff == Takeoff_None || !gB_DidTakeoff[target] || (showTakeoff == Takeoff_Jump && !gB_DidJump[target]))
        {
            ShowSyncHudText(client, HudSync, "%d", speedInt);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%d\n(%d)", speedInt, takeoffSpeedInt);
        }
    }
}
