static Handle HudSync;

MHudEnumPreference KeysMode;
MHudXYPreference KeysPosition;
MHudRGBPreference KeysNormalColor;
MHudRGBPreference KeysOverlapColor;
MHudEnumPreference KeysMouseDirection;
MHudEnumPreference KeysColorBySpeed;
MHudEnumPreference KeysSpaceMode;
MHudRGBPreference KeysGainColor;
MHudRGBPreference KeysLossColor;

static const char Modes[KeysMode_COUNT][] =
{
    "Disabled",
    "Blanks as underscores",
    "Blanks invisible"
};

static const char SpacingModes[KeysSpaceMode_COUNT][] =
{
    "1080p FS",
    "1440p resized",
    "1440p native",
    "Legacy"
};

static const char KeysColors[SpeedKeyColor_COUNT][] =
{
    "Disabled",
    "Color by current speed",
    "Color by gain (Instant)",
    "Color by gain (Average)"
};

static const char KeysStyle[KeysMouseStyle_COUNT][] = 
{
    "Disabled",
    "Style 1",
    "Style 2"
}

void OnPluginStart_Elements_Mode_Keys()
{
    KeysMode = new MHudEnumPreference("keys_mode", "Keys - Mode", Modes, sizeof(Modes) - 1, KeysMode_None);
    KeysPosition = new MHudXYPreference("keys_position", "Keys - Position", -1, 800);
}

void OnPluginStart_Elements_Other_Keys()
{
    HudSync = CreateHudSynchronizer();

    KeysSpaceMode = new MHudEnumPreference("keys_spacing_mode", "Keys - Spacing Mode", SpacingModes, sizeof(SpacingModes) - 1, KeysSpaceMode_NativeHD);
    KeysMouseDirection = new MHudEnumPreference("keys_mouse_direction", "Keys - Mouse Direction", KeysStyle, sizeof(KeysStyle) - 1, KeyMouseStyle_Disabled);
    KeysColorBySpeed = new MHudEnumPreference("keys_color_by_speed", "Keys - Color by Speed", KeysColors, sizeof(KeysColors) - 1, SpeedKeyColor_None);
    KeysNormalColor = new MHudRGBPreference("keys_color_normal", "Keys - Normal Color", 255, 255, 255);
    KeysOverlapColor = new MHudRGBPreference("keys_color_overlap", "Keys - Overlap Color", 255, 0, 0);
    KeysGainColor = new MHudRGBPreference("keys_color_gain", "Keys - Gain Color", 0, 255, 0);
    KeysLossColor = new MHudRGBPreference("keys_color_loss", "Keys - Loss Color", 255, 0, 0);
}

void OnGameFrame_Element_Keys(int client, int target)
{
    int mode = KeysMode.GetInt(client);
    if (mode == KeysMode_None)
    {
        return;
    }

    int buttons = gI_Buttons[target];
    bool showJump = JumpedRecently(target);
    int colorBySpeed = KeysColorBySpeed.GetInt(client);
    int spaceMode = KeysSpaceMode.GetInt(client);

    float xy[2];
    KeysPosition.GetXY(client, xy);

    int rgb[3];
    switch (colorBySpeed)
    {
        case SpeedKeyColor_None:
        {
            MHudRGBPreference colorPreference = DidButtonsOverlap(buttons)
            ? KeysOverlapColor
            : KeysNormalColor;

            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_Speed:
        {
            float speed = gF_CurrentSpeed[target];
            GetColorBySpeed(speed, rgb);
        }
        case SpeedKeyColor_GainInstant:
        {
            MHudRGBPreference colorPreference;
            if (gF_CurrentSpeed[client] - gF_OldSpeed[client] > 0.1)
            {
                colorPreference = KeysGainColor;
            }
            else if (gF_CurrentSpeed[client] - gF_OldSpeed[client] < -0.1)
            {
                colorPreference = KeysLossColor;
            }
            else 
            {
                colorPreference = DidButtonsOverlap(buttons)
                    ? KeysOverlapColor
                    : KeysNormalColor;
            }
            colorPreference.GetRGB(client, rgb);
        }
        case SpeedKeyColor_GainAverage:
        {
            MHudRGBPreference colorPreference = DidButtonsOverlap(buttons)
                ? KeysOverlapColor
                : KeysNormalColor;
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
                KeysGainColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, gainTicks/MAX_TRACKED_TICKS, rgb);
            }
            else
            {
                KeysLossColor.GetRGB(client, gainRGB);
                ColorLerp(rgb, gainRGB, -gainTicks/MAX_TRACKED_TICKS, rgb);
            }
        }
    }


    Call_OnDrawKeys(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], GetTextHoldTimeMHUD(client), rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    int mouseDirectionStyle = KeysMouseDirection.GetInt(client);
    bool legacy = KeysSpaceMode.GetInt(client) == KeysSpaceMode_Legacy;
    char blank[2] = "";
    if (mode == KeysMode_NoBlanks)
    {
        Format(blank, sizeof(blank), "—");
    }
    switch (mouseDirectionStyle)
    {
        case KeyMouseStyle_Disabled:
        {
            if (legacy)
            {
                ShowSyncHudText(client, HudSync, "%s  %s  %s\n%s  %s  %s",
                    (buttons & IN_DUCK)       ? "C" : blank,
                    (buttons & IN_FORWARD)    ? "W" : blank,
                    (showJump)                ? "J" : blank,
                    (buttons & IN_MOVELEFT)   ? "A" : blank,
                    (buttons & IN_BACK)       ? "S" : blank,
                    (buttons & IN_MOVERIGHT)  ? "D" : blank
                );
            }
            else
            {
                ShowSyncHudText(client, HudSync, "%s%s%s\n%s%s%s",
                    GetKeyString(Char_Crouch, mode, spaceMode, !!(buttons & IN_DUCK)),
                    GetKeyString(Char_W, mode, spaceMode, !!(buttons & IN_FORWARD)),
                    GetKeyString(Char_Jump, mode, spaceMode, showJump),
                    GetKeyString(Char_A, mode, spaceMode, !!(buttons & IN_MOVELEFT)),
                    GetKeyString(Char_S, mode, spaceMode, !!(buttons & IN_BACK)),
                    GetKeyString(Char_D, mode, spaceMode, !!(buttons & IN_MOVERIGHT))
                );
            }
        }
        case KeysMouseStyle_Side:
        {
            int mouseX = gI_MouseX[target];
            if (legacy)
            {
                ShowSyncHudText(client, HudSync, "%s%s%s\n%s%s%s%s%s",
                    GetKeyString(Char_Crouch, mode, spaceMode, !!(buttons & IN_DUCK)),
                    GetKeyString(Char_W, mode, spaceMode, !!(buttons & IN_FORWARD)),
                    GetKeyString(Char_Jump, mode, spaceMode, showJump),
                    GetKeyString(Char_ArrLeft, mode, spaceMode, mouseX < 0),
                    GetKeyString(Char_A, mode, spaceMode, !!(buttons & IN_MOVELEFT)),
                    GetKeyString(Char_S, mode, spaceMode, !!(buttons & IN_BACK)),
                    GetKeyString(Char_D, mode, spaceMode, !!(buttons & IN_MOVERIGHT)),
                    GetKeyString(Char_ArrRight, mode, spaceMode, mouseX > 0)
                );
            }
            else
            {
                ShowSyncHudText(client, HudSync, "%s  %s  %s\n%s %s  %s  %s %s",
                    (buttons & IN_DUCK)       ? "C" : blank,
                    (buttons & IN_FORWARD)    ? "W" : blank,
                    (showJump)                ? "J" : blank,
                    (mouseX < 0)              ? "←" : blank,
                    (buttons & IN_MOVELEFT)   ? "A" : blank,
                    (buttons & IN_BACK)       ? "S" : blank,
                    (buttons & IN_MOVERIGHT)  ? "D" : blank,
                    (mouseX > 0)              ? "→" : blank
                );
            }
        }
        case KeysMouseStyle_Line:
        {
            int mouseX = gI_MouseX[target];
            if (legacy)
            {
                ShowSyncHudText(client, HudSync, "%s%s%s\n%s%s%s\n%s%s%s",
                    (buttons & IN_DUCK)       ? "C" : blank,
                    (buttons & IN_FORWARD)    ? "W" : blank,
                    (showJump)                ? "J" : blank,
                    (mouseX < 0)              ? "←" : blank,
                    GetKeyString(Char_Jump, KeysMode_NoBlanks, spaceMode, false), // Key doesn't matter.
                    (mouseX > 0)              ? "→" : blank,
                    (buttons & IN_MOVELEFT)   ? "A" : blank,
                    (buttons & IN_BACK)       ? "S" : blank,
                    (buttons & IN_MOVERIGHT)  ? "D" : blank
                );
            }
            else
            {
                ShowSyncHudText(client, HudSync, "%s%s%s\n%s%s%s\n%s%s%s",
                    GetKeyString(Char_Crouch, mode, spaceMode, !!(buttons & IN_DUCK)),
                    GetKeyString(Char_W, mode, spaceMode, !!(buttons & IN_FORWARD)),
                    GetKeyString(Char_Jump, mode, spaceMode, showJump),
                    GetKeyString(Char_ArrLeft, mode, spaceMode, mouseX < 0),
                    GetKeyString(Char_Jump, KeysMode_NoBlanks, spaceMode, false), // Key doesn't matter.
                    GetKeyString(Char_ArrRight, mode, spaceMode, mouseX > 0),
                    GetKeyString(Char_A, mode, spaceMode, !!(buttons & IN_MOVELEFT)),
                    GetKeyString(Char_S, mode, spaceMode, !!(buttons & IN_BACK)),
                    GetKeyString(Char_D, mode, spaceMode, !!(buttons & IN_MOVERIGHT))
                );
            }
        }
    }
}

static bool DidButtonsOverlap(int buttons)
{
    return buttons & (IN_FORWARD | IN_BACK) == (IN_FORWARD | IN_BACK)
        || buttons & (IN_MOVELEFT | IN_MOVERIGHT) == (IN_MOVELEFT | IN_MOVERIGHT);
}
