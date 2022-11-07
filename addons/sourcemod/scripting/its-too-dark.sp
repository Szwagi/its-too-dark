#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "its-too-dark", 
	author = "Szwagi", 
	version = "v1.0.0", 
	url = "https://github.com/szwagi/its-too-dark"
};

#define MENU_INC_BLOOM_SCALE "MENU_INC_BLOOM_SCALE"
#define MENU_DEC_BLOOM_SCALE "MENU_DEC_BLOOM_SCALE"
#define MENU_INC_AUTOEXPOSURE_MIN "MENU_INC_AUTOEXPOSURE_MIN"
#define MENU_DEC_AUTOEXPOSURE_MIN "MENU_DEC_AUTOEXPOSURE_MIN"
#define MENU_INC_AUTOEXPOSURE_MAX "MENU_INC_AUTOEXPOSURE_MAX"
#define MENU_DEC_AUTOEXPOSURE_MAX "MENU_DEC_AUTOEXPOSURE_MAX"
#define MENU_INC_RATE "MENU_INC_RATE"
#define MENU_DEC_RATE "MENU_DEC_RATE"

int gI_Tonemap[MAXPLAYERS + 1];
ConVar gCV_sv_skyname;

public void OnPluginStart()
{
    gCV_sv_skyname = FindConVar("sv_skyname");

    RegConsoleCmd("sm_skybox", CommandSkybox, "Change skybox");
    RegConsoleCmd("sm_skyname", CommandSkybox, "Change skybox");
    RegConsoleCmd("sm_tonemap", CommandTonemap, "Change tonemap");
}

public void OnClientConnected(int client)
{
    gI_Tonemap[client] = -1;
}

public void OnClientDisconnect(int client)
{
    if (gI_Tonemap[client] != -1)
    {
        AcceptEntityInput(gI_Tonemap[client], "kill");
        gI_Tonemap[client] = -1;
    }
}

public Action CommandSkybox(int client, int args)
{
    if (args == 0)
    {
        Menu menu = new Menu(SkyboxMenuHandler);
        menu.SetTitle("Skybox");
        menu.AddItem("sky_hr_aztec", "Aztec");
        menu.AddItem("cs_baggage_skybox_", "Baggage");
        menu.AddItem("nukeblank", "Blank");
        menu.AddItem("sky_csgo_cloudy01", "Cloudy");
        menu.AddItem("sky_cs15_daylight01_hdr", "Daylight 1");
        menu.AddItem("sky_cs15_daylight02_hdr", "Daylight 2");
        menu.AddItem("sky_cs15_daylight03_hdr", "Daylight 3");
        menu.AddItem("sky_cs15_daylight04_hdr", "Daylight 4");
        menu.AddItem("sky_day02_05", "Daylight 5");
        menu.AddItem("sky_dust", "Dust");
        menu.AddItem("embassy", "Embassy");
        menu.AddItem("italy", "Italy");
        menu.AddItem("jungle", "Jungle");
        menu.AddItem("sky_lunacy", "Lunacy");
        menu.AddItem("sky_csgo_night02", "Night 1");
        menu.AddItem("sky_csgo_night02b", "Night 2");
        menu.AddItem("office", "Office");
        menu.AddItem("cs_tibet", "Tibet");
        menu.AddItem("sky_venice", "Venice");
        menu.AddItem("vertigo", "Vertigo");
        menu.AddItem("vertigoblue_hdr", "Vertigo Blue");
        menu.AddItem("vietnam", "Vietnam");
        menu.Display(client, 0);
    }
    else
    {
        char skyname[64];
        GetCmdArgString(skyname, sizeof(skyname));
        gCV_sv_skyname.ReplicateToClient(client, skyname);
        PrintToChat(client, "Skybox set to %s.", skyname);
    }
    return Plugin_Handled;
}

public int SkyboxMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char skyname[64];
        if (menu.GetItem(param2, skyname, sizeof(skyname)))
        {
            gCV_sv_skyname.ReplicateToClient(param1, skyname);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

int GetOrCreateTonemap(int client)
{
    if (gI_Tonemap[client] != -1)
    {
        return gI_Tonemap[client];
    }

    int tonemap = CreateEntityByName("env_tonemap_controller");
    if (tonemap != -1)
    {
        if (DispatchSpawn(tonemap))
        {
            ActivateEntity(tonemap);

            SetEntProp(tonemap, Prop_Send, "m_bUseCustomBloomScale", 1);
            SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMin", 1);
            SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMax", 1);
            SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale", 1.0);
            SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin", 0.75);
            SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax", 1.25);

            int master = GetEntPropEnt(client, Prop_Send, "m_hTonemapController");
            if (master != -1)
            {
                if (GetEntProp(master, Prop_Send, "m_bUseCustomBloomScale"))
                {
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale", GetEntPropFloat(master, Prop_Send, "m_flCustomBloomScale"));
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScaleMinimum", GetEntPropFloat(master, Prop_Send, "m_flCustomBloomScaleMinimum"));
                }

                if (SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMin", GetEntProp(master, Prop_Send, "m_bUseCustomAutoExposureMin")))
                {
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin", GetEntPropFloat(master, Prop_Send, "m_flCustomAutoExposureMin"));
                }

                if (SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMax", GetEntProp(master, Prop_Send, "m_bUseCustomAutoExposureMax")))
                {
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax", GetEntPropFloat(master, Prop_Send, "m_flCustomAutoExposureMax"));
                }

                SetEntPropFloat(tonemap, Prop_Send, "m_flBloomSaturation", GetEntPropFloat(master, Prop_Send, "m_flBloomSaturation"));
                SetEntPropFloat(tonemap, Prop_Send, "m_flBloomExponent", GetEntPropFloat(master, Prop_Send, "m_flBloomExponent"));
                SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapPercentBrightPixels", GetEntPropFloat(master, Prop_Send, "m_flTonemapPercentBrightPixels"));
                SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapPercentTarget", GetEntPropFloat(master, Prop_Send, "m_flTonemapPercentTarget"));
                SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapMinAvgLum", GetEntPropFloat(master, Prop_Send, "m_flTonemapMinAvgLum"));
                SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate", GetEntPropFloat(master, Prop_Send, "m_flTonemapRate"));
            }
            
            gI_Tonemap[client] = tonemap;
            SDKHook(client, SDKHook_PostThinkPost, PostThinkPostSetTonemap);

            return tonemap;
        }
        AcceptEntityInput(tonemap, "kill");
    }
    return -1;
}

public void PostThinkPostSetTonemap(int client)
{
    SetEntPropEnt(client, Prop_Send, "m_hTonemapController", gI_Tonemap[client]);
}

void DisplayTonemapMenu(int client, int firstItem = 0)
{
    int tonemap = GetOrCreateTonemap(client);
    if (tonemap != -1)
    {
        Menu menu = new Menu(TonemapMenuHandler);

        char title[128];
        FormatEx(title, sizeof(title), "%s: %.3f\n%s: %.3f\n%s: %.3f\n%s: %.3f\n ",
            "Bloom Scale", GetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale"),
            "Auto Exposure Min", GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin"),
            "Auto Exposure Max", GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax"),
            "Auto Exposure Rate", GetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate"));

        menu.SetTitle(title);

        menu.AddItem(MENU_INC_BLOOM_SCALE, "Bloom Scale +");
        menu.AddItem(MENU_DEC_BLOOM_SCALE, "Bloom Scale -");
        menu.AddItem(MENU_INC_AUTOEXPOSURE_MIN, "Auto Exposure Min +");
        menu.AddItem(MENU_DEC_AUTOEXPOSURE_MIN, "Auto Exposure Min -");
        menu.AddItem(MENU_INC_AUTOEXPOSURE_MAX, "Auto Exposure Max +");
        menu.AddItem(MENU_DEC_AUTOEXPOSURE_MAX, "Auto Exposure Max -");
        menu.AddItem(MENU_INC_RATE, "Auto Exposure Rate +");
        menu.AddItem(MENU_DEC_RATE, "Auto Exposure Rate -");

        menu.DisplayAt(client, firstItem, 0);
    }
}

public float IncValueAndRound(float num, float addMul)
{
    return RoundFloat((num + addMul) / addMul) * addMul;
}

public float Clamp(float num, float min, float max)
{
    if (num < min) return min;
    if (num > max) return max;
    return num;
}

public int TonemapMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        int tonemap = GetOrCreateTonemap(param1);
        if (tonemap != -1)
        {
            char info[64];
            if (menu.GetItem(param2, info, sizeof(info)))
            {
                if (StrEqual(info, MENU_INC_BLOOM_SCALE))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale");
                    float newValue = IncValueAndRound(oldValue, 0.1);
                    newValue = Clamp(newValue, 0.0, 100.0);

                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale", newValue);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScaleMinimum", newValue);
                }
                else if (StrEqual(info, MENU_DEC_BLOOM_SCALE))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale");
                    float newValue = IncValueAndRound(oldValue, -0.1);
                    newValue = Clamp(newValue, 0.0, 100.0);

                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScale", newValue);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomBloomScaleMinimum", newValue);
                }
                else if (StrEqual(info, MENU_INC_AUTOEXPOSURE_MIN))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin");
                    float newValue = IncValueAndRound(oldValue, 0.1);
                    newValue = Clamp(newValue, 0.0, 100.0);

                    SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMin", 1);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin", newValue);
                }
                else if (StrEqual(info, MENU_DEC_AUTOEXPOSURE_MIN))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin");
                    float newValue = IncValueAndRound(oldValue, -0.1);
                    newValue = Clamp(newValue, 0.0, 100.0);

                    SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMin", 1);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMin", newValue);
                }
                else if (StrEqual(info, MENU_INC_AUTOEXPOSURE_MAX))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax");
                    float newValue = IncValueAndRound(oldValue, 0.1);
                    newValue = Clamp(newValue, 0.1, 100.0);

                    SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMax", 1);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax", newValue);
                }
                else if (StrEqual(info, MENU_DEC_AUTOEXPOSURE_MAX))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax");
                    float newValue = IncValueAndRound(oldValue, -0.1);
                    newValue = Clamp(newValue, 0.1, 100.0);

                    SetEntProp(tonemap, Prop_Send, "m_bUseCustomAutoExposureMax", 1);
                    SetEntPropFloat(tonemap, Prop_Send, "m_flCustomAutoExposureMax", newValue);
                }
                else if (StrEqual(info, MENU_INC_RATE))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate");
                    float newValue = IncValueAndRound(oldValue, 0.1);
                    newValue = Clamp(newValue, 0.1, 100.0);

                    SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate", newValue);
                }
                else if (StrEqual(info, MENU_DEC_RATE))
                {
                    float oldValue = GetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate");
                    float newValue = IncValueAndRound(oldValue, -0.1);
                    newValue = Clamp(newValue, 0.1, 100.0);

                    SetEntPropFloat(tonemap, Prop_Send, "m_flTonemapRate", newValue);
                }
            }
        }

        DisplayTonemapMenu(param1, menu.Selection);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action CommandTonemap(int client, int args)
{
    DisplayTonemapMenu(client);
    return Plugin_Handled;
}
