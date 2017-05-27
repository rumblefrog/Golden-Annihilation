/*
 *  Golden Annihilation - A simple plugin that turns ragdoll into golden statue
 *  
 *  Copyright (C) 2017 RumbleFrog
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#define PLUGIN_AUTHOR "Fishy"
#define PLUGIN_VERSION "1.0.2"

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
			RemoveEdict(iEnt);
	}
}