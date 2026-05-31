#include <amxmodx>

#define PLUGIN_NAME "MHUD Main Menu"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_AUTHOR "7yPh00N"

new const MENU_MAIN[] = "MHUD Menu"

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    register_clcmd("say /mhud", "cmd_mhudmenu")
    register_clcmd("say_team /mhud", "cmd_mhudmenu")
    register_clcmd("say mhud", "cmd_mhudmenu")
    register_clcmd("say_team mhud", "cmd_mhudmenu")
    
    register_menucmd(register_menuid(MENU_MAIN), (1<<0)|(1<<1)|(1<<2)|(1<<9), "handle_mhudmenu")
}

public cmd_mhudmenu(id)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED
    show_mhudmenu(id)
    return PLUGIN_HANDLED
}

stock show_mhudmenu(id)
{
    new text[512]
    formatex(text, charsmax(text), "\rMovement-HUD^n^n")
    formatex(text, charsmax(text), "%s\yhttps://github.com/7yPh00N/Movement-HUD^n^n", text)
    formatex(text, charsmax(text), "%s\r1. \wMHUD Speed^n", text)
    formatex(text, charsmax(text), "%s\r2. \wInput Overlay^n", text)
    formatex(text, charsmax(text), "%s\r3. \wDistance Prediction^n^n", text)
    formatex(text, charsmax(text), "%s\r0. \wExit", text)
    show_menu(id, (1<<0)|(1<<1)|(1<<2)|(1<<9), text, -1, MENU_MAIN)
}

public handle_mhudmenu(id, key)
{
    switch (key)
    {
        case 0: client_cmd(id, "say /mspeeds")
        case 1: client_cmd(id, "say /mkeys")
        case 2: client_cmd(id, "say /dps")
    }
}