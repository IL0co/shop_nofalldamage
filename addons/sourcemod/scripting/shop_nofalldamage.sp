
#include <sourcemod>
#include <sdkhooks>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "[SHOP] No Fall Damage",
	author	  	= "iLoco",
	description = "",
	version	 	= "1.0.0",
	url			= "iLoco#7631"
};

#define SHOP_CATEGORY_ID	"ability"
#define SHOP_ITEM_ID		"nofalldamage"

ConVar cvar_Price, cvar_SellPrice, cvar_Duration;
ItemId gItemId;
bool iEnable[MAXPLAYERS+1];

public void VIP_OnVIPLoaded()
{
	Shop_UnregisterMe();
}

public void OnPluginStart()
{
	(cvar_Price = CreateConVar("sm_shop_nofalldamage_price", "1000", "Цена предмета")).AddChangeHook(Hook_OnConVarChanged);
	(cvar_SellPrice = CreateConVar("sm_shop_nofalldamage_sellprice", "500", "Цена продажи предмета")).AddChangeHook(Hook_OnConVarChanged);
	(cvar_Duration = CreateConVar("sm_shop_nofalldamage_duration", "72000", "Длительность предмета в секундах")).AddChangeHook(Hook_OnConVarChanged);
	AutoExecConfig(true, "shop_nofalldamage", "shop");
	
	if(Shop_IsStarted())
		Shop_Started();

	for(int i = 1; i <= MaxClients; i++)	if(IsClientAuthorized(i) && IsClientInGame(i))
		OnClientPostAdminCheck(i);

	LoadTranslations("shop_nofalldamage.phrases");
}

public void Hook_OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(gItemId == INVALID_ITEM)
		return;

	if(cvar == cvar_Price)
		Shop_SetItemPrice(gItemId, cvar.IntValue);
	else if(cvar == cvar_SellPrice)
		Shop_SetItemSellPrice(gItemId, cvar.IntValue);
	else if(cvar == cvar_Duration)
		Shop_SetItemValue(gItemId, cvar.IntValue);
}

public void OnClientPostAdminCheck(int client)
{
	iEnable[client] = false;

	if(!IsFakeClient(client))
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(iEnable[client] && damagetype & DMG_FALL)
		return Plugin_Handled;

	return Plugin_Continue;
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory(SHOP_CATEGORY_ID, "Способности", "", CallBack_Shop_OnCategoryDisplay);
	
	if(Shop_StartItem(category_id, SHOP_ITEM_ID))
	{
		Shop_SetInfo("Защита от падения", "", cvar_Price.IntValue, cvar_SellPrice.IntValue, Item_Togglable, cvar_Duration.IntValue);
		Shop_SetCallbacks(CallBack_Shop_OnItemRegistered, CallBack_Shop_OnItemToggled, _, CallBack_Shop_OnItemDisplay);
		Shop_EndItem();
	}
}

public bool CallBack_Shop_OnCategoryDisplay(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "Menu. Categry Display", client);
	return true;
}

public bool CallBack_Shop_OnItemDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "Menu. Item Display", client);
	return true;
}

public void CallBack_Shop_OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	gItemId = item_id;
}

public ShopAction CallBack_Shop_OnItemToggled(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	iEnable[client] = !isOn;

	if (isOn || elapsed)
		return Shop_UseOff;

	return Shop_UseOn;
}
