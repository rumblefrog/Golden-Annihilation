/**
MIT License

Copyright (c) 2017 RumbleFrog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#pragma semicolon 1

#define PLUGIN_AUTHOR "Fishy"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Golden Annihilation",
	author = PLUGIN_AUTHOR,
	description = "A simple plugin that turns ragdoll into golden statue",
	version = PLUGIN_VERSION,
	url = "https://keybase.io/rumblefrog"
};

public void OnPluginStart()
{
	CreateConVar("ga_version", PLUGIN_VERSION, "Golden Annihilation Version Control", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_NOTIFY);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	
	RegAdminCmd("ga_permission", CmdVoid, ADMFLAG_RESERVATION);
}

public Action CmdVoid(int iClient, int iArgs)
{
	return Plugin_Handled;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (iAttacker == 0 || iAttacker == iClient || !CheckCommandAccess(iAttacker, "ga_permission", ADMFLAG_RESERVATION))
		return;
	
	int iVteam = GetClientTeam(iClient);
	int iVclass = view_as<int>(TF2_GetPlayerClass(iClient));
	int iEnt = CreateEntityByName("tf_ragdoll");
	float fClientOrigin[3];
	
	SetEntPropVector(iEnt, Prop_Send, "m_vecRagdollOrigin", fClientOrigin); 
	SetEntProp(iEnt, Prop_Send, "m_iPlayerIndex", iClient);
	SetEntProp(iEnt, Prop_Send, "m_iTeam", iVteam);
	SetEntProp(iEnt, Prop_Send, "m_iClass", iVclass);
	SetEntProp(iEnt, Prop_Send, "m_bGoldRagdoll", 1);
	
	DataPack hPack = CreateDataPack();
	
	WritePackCell(hPack, iClient);
	WritePackCell(hPack, iEnt);
	
	DispatchSpawn(iEnt);
	
	CreateTimer(0.0, RemoveBody, hPack);
	CreateTimer(10.0, RemoveRagedoll, iEnt);
}

public Action RemoveBody(Handle timer, any hPack)
{
	ResetPack(hPack);
	
	int iClient = ReadPackCell(hPack);
	int iEnt = ReadPackCell(hPack);
	
	int BodyRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	
	if(IsValidEdict(BodyRagdoll))
	{
		RemoveEdict(BodyRagdoll);
		SetEntPropEnt(iClient, Prop_Send, "m_hRagdoll", iEnt);
	}
}

public Action RemoveRagedoll(Handle timer, any iEnt)
{
	if(IsValidEntity(iEnt))
	{
		char Classname[64];
		GetEdictClassname(iEnt, Classname, sizeof(Classname));
		if(StrEqual(Classname, "tf_ragdoll", false))
		{
			RemoveEdict(iEnt);
		}
	}
}