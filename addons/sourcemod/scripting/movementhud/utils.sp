void GetColorBySpeed(float speed, int rgb[3])
{
    int x = RoundFloat(speed / 50.0) * 32;
    if (x >= 256)
    {
        rgb = { 0, 255, 0 };
        return;
    }

    rgb[0] = (255 - x);
    rgb[1] = x;
    rgb[2] = 0;
}

bool IsClientInFreeCamera(int client)
{
    if (GetClientTeam(client) != 1) // not spectating
    {
        return false;
    }

    int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    return mode == 6; // OBS_MODE_ROAMING
}

int GetSpectedOrSelf(int client)
{
    int team = GetClientTeam(client);
    if (team != 1) // not spectating, replace with define/enum please
    {
        return client;
    }

    // TODO: Enum for this?
    int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (mode != 4 && mode != 5) // Not first or third person
    {
        return client;
    }

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if (target == -1) // not spectating anyone
    {
        return client;
    }

    return target;
}

void StripColorBytes(char[] buffer, int maxlength)
{
    int pos = 0;
    char[] output = new char[maxlength];

    int len = strlen(buffer);

    for (int i = 0; i < len; i++)
    {
        bool isColor = buffer[i] >= '\x01' && buffer[i] <= '\x10';
        if (!isColor)
        {
            output[pos++] = buffer[i];
        }
    }

    strcopy(buffer, maxlength, output);
}

void ColorLerp(int rgbFrom[3], int rgbTo[3], float t, int rgbOut[3])
{
    for (int i = 0; i < 3; i++)
    {
        rgbOut[i] = RoundToNearest(rgbFrom[i] * (1 - t) + rgbTo[i] * t);
    }
}