/*
 * SourceMod CSGO Murder
 * by: Hypr
 *
 * This file is part of the CSGO Murder project.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

int g_iKiller;

public void _Deaths_CVars() {
	gc_iBlind = AutoExecConfig_CreateConVar("sm_murder_blinded", "8", "The time in seconds a bystander gets blind if he/she kills an innocent.", FCVAR_NOTIFY);
}

public void _Deaths_OnPlayerDeath(Event event) {
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsMurderer(victim) && IsValidClient(g_iKiller)) { // If the murderer was killed
		CPrintToChatAll("%s %t", g_sPrefix, "Murderer Killed", g_iKiller);
		CPrintToChatAll("%s %t", g_sPrefix, "Murderer Reveal", victim);
		g_iKiller = -1;
		CS_TerminateRound(5.0, CSRoundEnd_Draw);
	} else if(IsMurderer(victim) && !IsValidClient(g_iKiller)) { // If murderer suicided
		CPrintToChatAll("%s %t", g_sPrefix, "Murderer Died Mysteriously");
		CPrintToChatAll("%s %t", g_sPrefix, "Murderer Reveal", victim);
		g_iKiller = -1;
		CS_TerminateRound(5.0, CSRoundEnd_Draw);
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(!IsValidClient(victim) || !IsValidClient(attacker))
		return Plugin_Continue;
		
	int iWeapon = GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY);
	
	if(IsDetective(attacker) && !IsMurderer(victim)) { // Detective killed innocent
		
		CS_DropWeapon(attacker, iWeapon, true, true);
		CooldownClient(attacker); // Prevent client from picking up weapon for the specified time
		
		_RDM_OnTakeDamage(victim, attacker); // Execute RDM Prevention if enabled
		
		CPrintToChatAll("%s %t", g_sPrefix, "Killed Innocent", attacker);
		
		PerformBlind(attacker);
		
		attacker = victim;
		damage *= 100;
		
		return Plugin_Changed;
	}
	
	if(IsMurderer(attacker)) {
		attacker = victim;
		damage *= 100.0;
		_Smoke_OnPlayerDeath();
		
		return Plugin_Changed;
	}
	if(IsMurderer(victim)) {
		g_iKiller = attacker;
		attacker = victim;
		damage *= 100;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void PerformBlind(int client) {
	if(IsValidClient(client)) {
		ShowRoleOverlay(client, OVERLAY_BLIND);
		CreateTimer(gc_iBlind.FloatValue, BlindTimer, client);
	}
}

public Action BlindTimer(Handle timer, int client) {
	if(IsValidClient(client))
		ShowRoleOverlay(client, OVERLAY_NONE);
}