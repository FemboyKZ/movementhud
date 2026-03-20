enum
{
    Category_Speed = 0,
    Category_Keys,
    Category_Indicators,
    Category_DistPred,
    Category_General
};

static bool gB_InAdvMode[MAXPLAYERS + 1];
static bool gB_FromMainMenu[MAXPLAYERS + 1];
static int gI_CategoryFilter[MAXPLAYERS + 1];

void OnClientPutInServer_PreferencesMenu(int client)
{
    gB_InAdvMode[client] = false;
    gB_FromMainMenu[client] = false;
    gI_CategoryFilter[client] = Category_Speed;
}

static int GetPreferenceCategory(const char[] id)
{
    if (strncmp(id, "speed_", 6) == 0) return Category_Speed;
    if (strncmp(id, "keys_", 5) == 0) return Category_Keys;
    if (strncmp(id, "indicators_", 11) == 0) return Category_Indicators;
    if (strncmp(id, "distpred_", 9) == 0) return Category_DistPred;
    return Category_General;
}

static void GetCategoryName(int category, char[] buffer, int maxlength)
{
    switch (category)
    {
        case Category_Speed: strcopy(buffer, maxlength, "Speed Display");
        case Category_Keys: strcopy(buffer, maxlength, "Key Display");
        case Category_Indicators: strcopy(buffer, maxlength, "Indicators");
        case Category_DistPred: strcopy(buffer, maxlength, "Distance Prediction");
        case Category_General: strcopy(buffer, maxlength, "General");
    }
}

static void GetCategoryPrefix(int category, char[] buffer, int maxlength)
{
    switch (category)
    {
        case Category_Speed: strcopy(buffer, maxlength, "Speed - ");
        case Category_Keys: strcopy(buffer, maxlength, "Keys - ");
        case Category_Indicators: strcopy(buffer, maxlength, "Indicators - ");
        case Category_DistPred: strcopy(buffer, maxlength, "Distance Prediction - ");
        default: buffer[0] = '\0';
    }
}

void DisplayMainMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Main);
    menu.SetTitle("MovementHUD %.20s\n%s\n ", MHUD_VERSION, MHUD_SOURCE_URL);

    menu.AddItem("1", "Simple preferences");
    menu.AddItem("2", "Advanced preferences");
    //menu.AddItem("3", "Preferences helpers & tools");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayCategoryMenu(int client, bool advanced)
{
    gB_InAdvMode[client] = advanced;
    gB_FromMainMenu[client] = true;

    Menu menu = new Menu(MenuHandler_Category);
    menu.SetTitle("MovementHUD %.20s\n%s\nSelect a category:\n ", MHUD_VERSION, MHUD_SOURCE_URL);

    menu.AddItem("0", "Speed Display");
    menu.AddItem("1", "Key Display");
    menu.AddItem("2", "Indicators");
    menu.AddItem("3", "Distance Prediction");
    menu.AddItem("4", "General");

    menu.ExitButton = true;
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayPreferencesMenu(int client, bool advanced, bool fromMainMenu = false, int displayAt = 0)
{
    gB_InAdvMode[client] = advanced;
    gB_FromMainMenu[client] = fromMainMenu;

    int category = gI_CategoryFilter[client];

    char categoryName[32];
    GetCategoryName(category, categoryName, sizeof(categoryName));

    char categoryPrefix[32];
    GetCategoryPrefix(category, categoryPrefix, sizeof(categoryPrefix));
    int prefixLen = strlen(categoryPrefix);

    Menu menu = new Menu(MenuHandler_Preferences);
    menu.SetTitle("MovementHUD %.20s\n%s\n%s\n ", MHUD_VERSION, MHUD_SOURCE_URL, categoryName);

    for (int i = 0; i < g_Preferences.Length; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        if (GetPreferenceCategory(preference.Id) != category)
        {
            continue;
        }

        char display[256];

        // Strip category prefix from name for cleaner display
        char name[64];
        if (prefixLen > 0 && strncmp(preference.Name, categoryPrefix, prefixLen) == 0)
        {
            strcopy(name, sizeof(name), preference.Name[prefixLen]);
        }
        else
        {
            strcopy(name, sizeof(name), preference.Name);
        }

        // Show raw values if in custom mode
        if (advanced)
        {
            char value[MHUD_MAX_VALUE];
            GetPreferenceValue(client, preference, value);

            Format(display, sizeof(display), "%s: %s", name, value);
        }
        else
        {
            bool hasCapability = Call_DisplayHandler(client, preference, display, sizeof(display));
            if (!hasCapability)
            {
                continue;
            }

            Format(display, sizeof(display), "%s: %s", name, display);
        }

        bool isCorePreference = preference.OwningPlugin == GetMyHandle();
        if (!isCorePreference)
        {
            Format(display, sizeof(display), "[Third-Party] %s", display);
        }

        menu.AddItem(preference.Id, display);
    }

    menu.ExitButton = true;
    menu.ExitBackButton = true;
    menu.DisplayAt(client, displayAt, MENU_TIME_FOREVER);
}

void RedisplayPreferencesMenu(int client, int displayAt = 0)
{
    DisplayPreferencesMenu(client, gB_InAdvMode[client], gB_FromMainMenu[client], displayAt);
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char selection[2];
        menu.GetItem(param2, selection, sizeof(selection));

        bool advanced = selection[0] == '2';
        DisplayCategoryMenu(param1, advanced);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public int MenuHandler_Category(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char selection[4];
        menu.GetItem(param2, selection, sizeof(selection));

        gI_CategoryFilter[param1] = StringToInt(selection);
        DisplayPreferencesMenu(param1, gB_InAdvMode[param1], true);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayMainMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public int MenuHandler_Preferences(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char id[MHUD_MAX_ID];
        menu.GetItem(param2, id, sizeof(id));

        Preference preference;

        bool found = GetPreferenceById(id, preference);
        if (!found)
        {
            return 0;
        }

        if (gB_InAdvMode[param1])
        {
            WaitForPreferenceChatInputFromClient(param1, id, menu.Selection);
            return 0;
        }

        char value[MHUD_MAX_VALUE];

        bool hasCapability = Call_GetNextHandler(param1, preference, value);
        if (hasCapability)
        {
            SetPreferenceValue(param1, preference, value);
        }

        RedisplayPreferencesMenu(param1, menu.Selection);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayCategoryMenu(param1, gB_InAdvMode[param1]);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}
