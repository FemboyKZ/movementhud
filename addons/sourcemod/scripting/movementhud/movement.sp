int gI_MouseX[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1];
int gI_GroundTicks[MAXPLAYERS + 1];

bool gB_DidJump[MAXPLAYERS + 1];
bool gB_DidPerf[MAXPLAYERS + 1];
bool gB_DidJumpBug[MAXPLAYERS + 1];
bool gB_DidCrouchJump[MAXPLAYERS + 1];

bool gB_DidTakeoff[MAXPLAYERS + 1];
float gF_TakeoffSpeed[MAXPLAYERS + 1];

float gF_OldSpeed[MAXPLAYERS + 1];
float gF_CurrentSpeed[MAXPLAYERS + 1];
float gF_LastJumpInput[MAXPLAYERS + 1];

float gF_JumpStartOrigin[MAXPLAYERS + 1][3];
float gF_JumpStartTime[MAXPLAYERS + 1];

static bool OldOnGround[MAXPLAYERS + 1];
static MoveType OldMoveType[MAXPLAYERS + 1];

HUDInfo gH_BotInfo[MAXPLAYERS + 1];
bool gB_GotBotInfo[MAXPLAYERS + 1];

bool gB_FirstTickGain[MAXPLAYERS + 1];

#define MAX_TRACKED_TICKS 16
float gF_SpeedChange[MAXPLAYERS + 1][MAX_TRACKED_TICKS];

// =====[ LISTENERS ]=====

void OnPlayerRunCmd_TrackMovement(int client)
{
    gF_OldSpeed[client] = Movement_GetSpeed(client);
}

void OnClientPutInServer_Movement(int client)
{
    ResetTakeoff(client);

    gI_MouseX[client] = 0;
    gI_Buttons[client] = 0;
    gI_GroundTicks[client] = 0;

    gF_CurrentSpeed[client] = 0.0;
    gF_LastJumpInput[client] = 0.0;

    gF_JumpStartTime[client] = 0.0;
    gF_JumpStartOrigin[client] = view_as<float>({0.0, 0.0, 0.0});

    OldOnGround[client] = false;
    OldMoveType[client] = MOVETYPE_NONE;

    gB_GotBotInfo[client] = false;
}

void OnPlayerRunCmdPost_Movement(int client, int buttons, const int mouse[2], int tickcount)
{
    gI_MouseX[client] = mouse[0];

    if (IsFakeClient(client) && gB_GOKZReplays)
    {
        gB_GotBotInfo[client] = !!GOKZ_RP_GetPlaybackInfo(client, gH_BotInfo[client]);
    }

    if (gB_GotBotInfo[client])
    {
        gF_CurrentSpeed[client] = gH_BotInfo[client].Speed;
        gI_Buttons[client] = gH_BotInfo[client].Buttons;
        
        if (gH_BotInfo[client].Jumped || (gH_BotInfo[client].Buttons & IN_JUMP && gH_BotInfo[client].IsTakeoff))
        {
            gB_DidJump[client] = true;
        }
        if (gH_BotInfo[client].HitJB)
        {
            gB_DidJumpBug[client] = true;
        }
    }
    else
    {
        gF_CurrentSpeed[client] = GetSpeed(client);
        gI_Buttons[client] = buttons;
    }
    TrackMovement(client, tickcount);
}

bool JumpedRecently(int client)
{
    return (GetEngineTime() - gF_LastJumpInput[client]) <= 0.10;
}

// =====[ PRIVATE ]=====

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
    gB_DidJump[client] = true;
    gB_DidJumpBug[client] = Movement_GetJumpbugged(client);
    if (jumpbug)
    {
        DoTakeoff(client, true);
    }
}

static void TrackMovement(int client, int tickcount)
{
    if (IsJumping(client))
    {
        gF_LastJumpInput[client] = GetEngineTime();
    }

    MoveType moveType = GetEntityMoveType(client);
    if (moveType != MOVETYPE_WALK)
    {
        // Can't airstrafe without the right movetype.
        gB_FirstTickGain[client] = false;
    }

    bool onGround = gB_GotBotInfo[client] ? gH_BotInfo[client].OnGround : IsOnGround(client);

    if (onGround)
    {
        ResetTakeoff(client);
        gI_GroundTicks[client]++;
    }
    else
    {
        // Just left a ladder.
        if (moveType != OldMoveType[client]
            && OldMoveType[client] == MOVETYPE_LADDER)
        {
            DoTakeoff(client, false);
            // Ladderjump is also a jump.
            gB_DidJump[client] = true;
        }

        // Jumped or fell off a ledge, probably.
        if (OldOnGround[client] && moveType != MOVETYPE_LADDER)
        {
            DoTakeoff(client, gB_DidJump[client]);
        }

        gI_GroundTicks[client] = 0;
    }

    gF_SpeedChange[client][tickcount % MAX_TRACKED_TICKS] = gF_CurrentSpeed[client] - gF_OldSpeed[client];

    OldOnGround[client] = onGround;
    OldMoveType[client] = moveType;
}

static bool IsJumping(int client)
{
	return (gI_Buttons[client] & IN_JUMP == IN_JUMP);
}

static bool IsDucking(int client)
{
    return (gI_Buttons[client] & IN_DUCK == IN_DUCK);
}

static bool IsOnGround(int client)
{
	return (GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND);
}

static float GetSpeed(int client)
{
    return Movement_GetSpeed(client);
}

static void ResetTakeoff(int client)
{
    gB_DidTakeoff[client] = false;
    gF_TakeoffSpeed[client] = 0.0;

    gB_DidJump[client] = false;
    gB_DidPerf[client] = false;
    gB_DidJumpBug[client] = false;
    gB_DidCrouchJump[client] = false;
    gB_FirstTickGain[client] = false;
}

static void DoTakeoff(int client, bool didJump)
{
    bool didPerf = gB_GotBotInfo[client] ? gH_BotInfo[client].HitPerf : GOKZ_GetHitPerf(client);
    float takeoffSpeed = gB_GotBotInfo[client] ? gH_BotInfo[client].Speed : Movement_GetTakeoffSpeed(client);

    Call_OnMovementTakeoff(client, didJump, didPerf, takeoffSpeed);

    gB_DidPerf[client] = didPerf;
    gB_DidTakeoff[client] = gB_GotBotInfo[client] ? gH_BotInfo[client].IsTakeoff : true;
    gF_TakeoffSpeed[client] = takeoffSpeed;

    Movement_GetOrigin(client, gF_JumpStartOrigin[client]);
    gF_JumpStartTime[client] = GetEngineTime();

    if (didJump)
    {
        gB_DidCrouchJump[client] = IsDucking(client);
    }

    gB_FirstTickGain[client] = gF_CurrentSpeed[client] > gF_OldSpeed[client];
}
