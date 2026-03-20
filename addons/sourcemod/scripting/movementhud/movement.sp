int gI_MouseX[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1];
int gI_GroundTicks[MAXPLAYERS + 1];

bool gB_DidJump[MAXPLAYERS + 1];
bool gB_DidPerf[MAXPLAYERS + 1];
bool gB_DidJumpBug[MAXPLAYERS + 1];
bool gB_DidCrouchJump[MAXPLAYERS + 1];
bool gB_DidEdgeBug[MAXPLAYERS + 1];

bool gB_DidTakeoff[MAXPLAYERS + 1];
float gF_TakeoffSpeed[MAXPLAYERS + 1];

float gF_OldSpeed[MAXPLAYERS + 1];
float gF_CurrentSpeed[MAXPLAYERS + 1];
float gF_LastJumpInput[MAXPLAYERS + 1];
float gF_OldVerticalVelocity[MAXPLAYERS + 1];

float gF_JumpStartOrigin[MAXPLAYERS + 1][3];
float gF_JumpStartTime[MAXPLAYERS + 1];
float gF_JumpAirTime[MAXPLAYERS + 1];

static bool OldOnGround[MAXPLAYERS + 1];
static MoveType OldMoveType[MAXPLAYERS + 1];

HUDInfo gH_BotInfo[MAXPLAYERS + 1];
bool gB_GotBotInfo[MAXPLAYERS + 1];

bool gB_FirstTickGain[MAXPLAYERS + 1];

float gF_JumpStamina[MAXPLAYERS + 1];

#define MAX_TRACKED_TICKS 16
#define PREDICTION_EXTRA_AIRTIME 1
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
    gF_OldVerticalVelocity[client] = 0.0;

    gF_CurrentSpeed[client] = 0.0;
    gF_LastJumpInput[client] = 0.0;

    gF_JumpStartTime[client] = 0.0;
    gF_JumpAirTime[client] = 0.0;
    gF_JumpStartOrigin[client] = view_as<float>({0.0, 0.0, 0.0});

    OldOnGround[client] = false;
    OldMoveType[client] = MOVETYPE_NONE;

    gB_GotBotInfo[client] = false;
    gB_DidEdgeBug[client] = false;
    gF_JumpStamina[client] = 0.0;
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

public Action Movement_OnJumpPre(int client, float origin[3], float velocity[3])
{
    gF_JumpStamina[client] = GetEntPropFloat(client, Prop_Send, "m_flStamina");
    return Plugin_Continue;
}

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

    // Edge bug detection
    float velocity[3];
    Movement_GetVelocity(client, velocity);
    float currentVerticalVel = velocity[2];

    // Detect edge bug: was falling (< -50), velocity became ~0, not on ground, and not on ladder
    if (gF_OldVerticalVelocity[client] < -100.0 && 
        FloatAbs(currentVerticalVel) < 10.0 && 
        !onGround &&
        moveType != MOVETYPE_LADDER)
    {
        gB_DidEdgeBug[client] = true;
    }

    gF_OldVerticalVelocity[client] = currentVerticalVel;

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
    gB_DidEdgeBug[client] = false;
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

    float stamina = gB_GotBotInfo[client] ? 0.0 : gF_JumpStamina[client];
    gF_JumpAirTime[client] = ComputeJumpAirTime(gB_DidCrouchJump[client], stamina);

    gB_FirstTickGain[client] = gF_CurrentSpeed[client] > gF_OldSpeed[client];
}

static float ComputeJumpAirTime(bool isCrouchJump, float stamina = 0.0)
{
    // Simulate the full jump trajectory to determine total air time.
    // Matches CS:GO's split-gravity model from the Source SDK:
    //   1. StartGravity: velocity -= half_gravity
    //   2. Position update: position += velocity * tick_interval
    //   3. FinishGravity: velocity -= half_gravity
    //
    // CJ: CheckJumpButton SETs velocity to impulse (overwrites StartGravity)
    //     Player crouches in air → origin rises 9u → must descend 9u extra to land
    // Normal: CheckJumpButton ADDs impulse to post-StartGravity velocity
    //     No crouch offset → lands at takeoff height
    float tickInterval = GetTickInterval();
    float gravity = FindConVar("sv_gravity").FloatValue;
    float halfGravity = gravity * 0.5 * tickInterval;
    float impulse = FindConVar("sv_jump_impulse").FloatValue; // 301.993377

    // Stamina reduces jump velocity: modifier = clamp(1.0 - stamina / 100.0, 0.0, 1.0)
    // In CS:GO SDK, CheckJumpButton multiplies velocity by this modifier after setting/adding impulse.
    float staminaMod = 1.0 - stamina / 100.0;
    if (staminaMod < 0.0) staminaMod = 0.0;
    if (staminaMod > 1.0) staminaMod = 1.0;

    float velocity;
    if (isCrouchJump)
    {
        // CJ: vel = impulse * staminaMod (SET, overwrites StartGravity deduction)
        velocity = impulse * staminaMod;
    }
    else
    {
        // Normal: vel = (0 - half_g + impulse) * staminaMod
        // StartGravity already ran, then impulse is added, then stamina multiplies the whole thing.
        velocity = (impulse - halfGravity) * staminaMod;
    }

    float position = 0.03125; // SURFACE_EPSILON

    // Players always crouch in air in KZ, so origin is +9u above ground.
    // Landing when crouched origin returns to ground level → must descend 9u extra.
    float landingHeight = -9.0;
    bool wasAbove = false;
    int tickCount = 0;

    while (tickCount < 1000)
    {
        velocity -= halfGravity;
        position += velocity * tickInterval;
        velocity -= halfGravity;

        if (position > landingHeight + 2.0)
        {
            wasAbove = true;
        }

        tickCount++;

        if (position <= landingHeight + 2.0 && wasAbove)
        {
            break;
        }
    }

    return (tickCount + PREDICTION_EXTRA_AIRTIME) * tickInterval;
}
