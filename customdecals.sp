#pragma semicolon 1
#pragma newdecls required

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

#define VERSION "1.1"

ArrayList g_DecalableItems;
ArrayList g_PlayerItems[33];

public Plugin myinfo =
{
	name = "Custom Decals",
	author = "brokenphilip",
	description = "Apply custom decals to weapons/cosmetics",
	version = VERSION,
	url = "https://github.com/brokenphilip/custom_decals"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_forcedecal", Cmd_ForceDecal, ADMFLAG_GENERIC, "Force add a decal to an existing cosmetic/weapon");

	RegConsoleCmd("sm_decal", Cmd_Decal, "Add a decal to an existing cosmetic/weapon");
	RegConsoleCmd("sm_decalhelp", Cmd_DecalHelp, "Explains how to use the decal command");

	for (int i = 0; i < MaxClients; i++)
		g_PlayerItems[i] = new ArrayList(sizeof(StringMap));
}

public void OnAllPluginsLoaded()
{
	g_DecalableItems = new ArrayList(sizeof(StringMap));

	ArrayList itemList = TF2Econ_GetItemList(FilterDecalableItems);
	
	for (int i = 0; i < itemList.Length; i++)
	{
		int item_idx = itemList.Get(i);

		char name[64];
		TF2Econ_GetItemName(item_idx, name, sizeof(name));

		StringMap sm = new StringMap();
		sm.SetString("name", name);
		sm.SetValue("item_index", item_idx);
		g_DecalableItems.Push(sm);
	}

	delete itemList;
}

public bool FilterDecalableItems(int iItemDefIndex, any data)
{
	char result[2];
	TF2Econ_GetItemDefinitionString(iItemDefIndex, "capabilities/can_customize_texture", result, sizeof(result));
	return StrEqual(result, "1");
}

public Action Cmd_ForceDecal(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcedecal <#userid|name> <UGC ID>");
		return Plugin_Handled;
	}

	char target[32], ugc[21];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, ugc, sizeof(ugc));

	if (!IsStrNumeric(ugc))
	{
		ReplyToCommand(client, "[SM] Invalid UGC ID, %s is not a valid number.", ugc);
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// torture to handle, not a fan of any implementation idea i've had so far
	if (target_count >= 2)
	{
		ReplyToCommand(client, "[SM] Multiple clients found, please specify.");
		return Plugin_Handled;
	}

	ShowItemMenu(client, target_list[0], ugc);
	return Plugin_Handled;
}

public Action Cmd_Decal(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_decal <UGC ID>");
		return Plugin_Handled;
	}
	
	char ugc[21];
	GetCmdArg(1, ugc, sizeof(ugc));

	if (!IsStrNumeric(ugc))
	{
		ReplyToCommand(client, "[SM] Invalid UGC ID, %s is not a valid number.", ugc);
		return Plugin_Handled;
	}

	ShowItemMenu(client, client, ugc);
	return Plugin_Handled;
}

public Action Cmd_DecalHelp(int client, any args)
{
	ReplyToCommand(client, "[SM] Displayed help in the console.");

	PrintToConsole(client, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
		"==========\n",
		"1. Get a 128x128 image (same image used for colored decals)\n",
		"2. Make a TF2 guide and upload the image as an icon (branding image):\n",
		"https://steamcommunity.com/sharedfiles/editguide/?appid=440\n",
		"3. Save the guide and preview it (WITHOUT publishing it!)\n",
		"4. Copy the icon URL. The URL MUST start with steamuserimages...\n",
		"3. Copy the number after the /ugc/ part, for example:\n",
		"steamuserimages-a.akamaihd.net/ugc/123456789123456789/...\n",
		"4. Wait 15-30 seconds then run the command. Example command:\n",
		"sm_decal 123456789123456789\n",
		"5. If the decal hasn't changed, check the console for a 'GetUGCDetails failed?' error\n",
		"Reasons include incorrect UGC ID (mistyped?), incorrect image size, not a TF2 guide,\n",
		"guide being published, or decal applied too soon\n",
		"==========");

	return Plugin_Handled;
}

public void ShowItemMenu(int client, int target, const char[] ugc)
{
	int len = g_PlayerItems[target].Length;
	int entity;
	StringMap sm;

	if (len == 0)
	{
		ReplyToCommand(client, "[SM] %N does not have any decal-able items equipped.", target);
		return;
	}
	else if (len == 1)
	{
		sm = g_PlayerItems[target].Get(0);
		sm.GetValue("ent_index", entity);

		if (ApplyDecal(entity, ugc))
			ReplyToCommand(client, "[SM] Applied decal for %N.", target);
		else
			ReplyToCommand(client, "[SM] Failed to apply decal, entity is invalid.");

		return;
	}

	char display[64], name[64];

	Menu menu = new Menu(OnItemMenuSelected);
	menu.SetTitle("Apply decal to:");

	for (int i = 0; i < len; i++)
	{
		sm = g_PlayerItems[target].Get(i);
		sm.GetString("name", name, sizeof(name));
		sm.GetValue("ent_index", entity);

		Format(display, sizeof(display), "%s | Ent #%d", name, entity);
		menu.AddItem(ugc, display);
	}

	menu.Display(client, 20);
}

public int OnItemMenuSelected(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		delete menu;
	
	else if (action == MenuAction_Select)
	{
		char ugc[21], display[64], entity_str[5];
		GetMenuItem(menu, item, ugc, sizeof(ugc), _, display, sizeof(display));

		strcopy(entity_str, sizeof(entity_str), display[FindCharInString(display, '#') + 1]);
		int entity = StringToInt(entity_str);

		if (ApplyDecal(entity, ugc))
		{
			int target = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			ReplyToCommand(client, "[SM] Applied decal for %N.", target);
		}
		else
			ReplyToCommand(client, "[SM] Failed to apply decal, entity is invalid.");
	}

	return 0;
}

public bool ApplyDecal(int entity, const char[] ugc)
{
	// checking again because we have no idea if the entity was for example deleted (tf2items will not catch that)
	if (!IsValidDecalableItem(entity))
		return false;

	int hi_lo[2];
	StringToInt64(ugc, hi_lo);

	float f_hi = view_as<float>(hi_lo[1]);
	float f_lo = view_as<float>(hi_lo[0]);

	TF2Attrib_SetByName(entity, "custom texture hi", f_hi);
	TF2Attrib_SetByName(entity, "custom texture lo", f_lo);

	return true;
}

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int index, int level, int quality, int entity)
{
	StringMap sm;
	char name[64];
	int item_idx;

	for (int i = 0; i < g_DecalableItems.Length; i++)
	{
		sm = g_DecalableItems.Get(i);
		sm.GetValue("item_index", item_idx);

		if (item_idx == index)
		{
			sm.GetString("name", name, sizeof(name));
			
			StringMap sm2 = new StringMap();
			sm2.SetString("name", name);
			sm2.SetValue("ent_index", entity);
			g_PlayerItems[client].Push(sm2);
			
			break;
		}
	}

	// Allow a short delay for the previous items to despawn
	CreateTimer(0.1, CheckItems, client);
}

public Action CheckItems(Handle timer, int client)
{
	StringMap sm;
	int entity;

	for (int i = 0; i < g_PlayerItems[client].Length; i++)
	{
		sm = g_PlayerItems[client].Get(i);
		sm.GetValue("ent_index", entity);

		if (!IsValidDecalableItem(entity))
		{
			g_PlayerItems[client].Erase(i);
			delete sm;

			// new element will take its place, test the same index again
			i--;
		}
	}

	return Plugin_Continue;
}

stock bool IsStrNumeric(char[] buf)
{
	for (int i = 0; i < strlen(buf); i++)
	{
		if (!IsCharNumeric(buf[i]))
			return false;
	}
	
	return true;
}

stock bool IsValidDecalableItem(int entity)
{
	if (!IsValidEntity(entity) || !HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
		return false;

	StringMap sm;
	int len = g_DecalableItems.Length;
	int item_idx;

	for (int i = 0; i < len; i++)
	{
		sm = g_DecalableItems.Get(i);
		sm.GetValue("item_index", item_idx);
		
		if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == item_idx)
			return true;
	}

	return false;
}
