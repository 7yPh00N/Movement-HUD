#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME "MHUD Speed"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_AUTHOR "7yPh00N"

new const MENU_SPEED[] = "SpeedMenu"

new bool:g_SpeedDisplayEnabled[33]
new Float:g_SpeedY[33]
new Float:g_SpeedHoldTime[33]
new g_SpeedColorGain[33][3]
new g_SpeedColorLoss[33][3]
new g_SpeedColorUnchanged[33][3]
new Float:g_PrevHorizontalSpeed[33]
new Float:g_TakeoffHorizontalSpeed[33]
new Float:g_TakeoffZ[33]
new Float:g_TakeoffWeaponSpeed[33]
new bool:g_IsJumpTakeoff[33]
new bool:g_InPrediction[33]
new bool:g_JumpFirstFrame[33]
new Float:g_DhudHoldTime = 0.011
new bool:g_SpeedEnabled[33]
new bool:g_PrestrafeEnabled[33]
new bool:g_GainLossEnabled[33]

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    register_clcmd("say /mspeed", "cmd_toggle_speed")
    register_clcmd("say_team /mspeed", "cmd_toggle_speed")
    register_clcmd("say mspeed", "cmd_toggle_speed")
    register_clcmd("say_team mspeed", "cmd_toggle_speed")
    register_clcmd("say /mhudspeed", "cmd_toggle_speed")
    register_clcmd("say_team /mhudspeed", "cmd_toggle_speed")
    register_clcmd("say mhudspeed", "cmd_toggle_speed")
    register_clcmd("say_team mhudspeed", "cmd_toggle_speed")
    register_clcmd("say /mspeeds", "cmd_speedmenu")
    register_clcmd("say_team /mspeeds", "cmd_speedmenu")
    register_clcmd("say mspeeds", "cmd_speedmenu")
    register_clcmd("say_team mspeeds", "cmd_speedmenu")
    register_menucmd(register_menuid(MENU_SPEED), (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), "handle_speedmenu")
    
    for (new i = 0; i < 33; i++)
    {
        g_SpeedDisplayEnabled[i] = true
        g_SpeedY[i] = 0.66
        g_SpeedHoldTime[i] = 0.011
        g_SpeedColorGain[i][0] = 20
        g_SpeedColorGain[i][1] = 255
        g_SpeedColorGain[i][2] = 150
        g_SpeedColorLoss[i][0] = 255
        g_SpeedColorLoss[i][1] = 70
        g_SpeedColorLoss[i][2] = 120
        g_SpeedColorUnchanged[i][0] = 255
        g_SpeedColorUnchanged[i][1] = 255
        g_SpeedColorUnchanged[i][2] = 255
        g_SpeedEnabled[i] = true
        g_PrestrafeEnabled[i] = true
        g_GainLossEnabled[i] = true
    }

    LoadServerConfig()
    LoadSpeedSettings(0)
}

public client_connect(id)
{
    g_SpeedDisplayEnabled[id] = true
    g_SpeedY[id] = 0.66
    g_SpeedHoldTime[id] = 0.011
    g_SpeedColorGain[id][0] = 20
    g_SpeedColorGain[id][1] = 255
    g_SpeedColorGain[id][2] = 150
    g_SpeedColorLoss[id][0] = 255
    g_SpeedColorLoss[id][1] = 70
    g_SpeedColorLoss[id][2] = 120
    g_SpeedColorUnchanged[id][0] = 255
    g_SpeedColorUnchanged[id][1] = 255
    g_SpeedColorUnchanged[id][2] = 255
    g_SpeedEnabled[id] = true
    g_PrestrafeEnabled[id] = true
    g_GainLossEnabled[id] = true
    g_PrevHorizontalSpeed[id] = 0.0
    g_TakeoffHorizontalSpeed[id] = 0.0
    g_InPrediction[id] = false
    g_JumpFirstFrame[id] = false
    
    LoadSpeedSettings(id)
}

public client_disconnected(id)
{
    g_InPrediction[id] = false
}

public cmd_toggle_speed(id)
{
    if (!is_user_connected(id)) return PLUGIN_HANDLED;
    g_SpeedDisplayEnabled[id] = !g_SpeedDisplayEnabled[id];
    client_print_color(id, id, "^4[7yPh00N]^1 Speed: %s", g_SpeedDisplayEnabled[id] ? "^3ON" : "^3OFF");
    SaveSpeedSettings(id);
    return PLUGIN_HANDLED;
}

public cmd_speedmenu(id)
{
    if (!is_user_connected(id)) return PLUGIN_HANDLED;
    show_speedmenu(id);
    return PLUGIN_HANDLED;
}

public client_PreThink(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return PLUGIN_CONTINUE;
    
    if (!g_SpeedDisplayEnabled[id])
        return PLUGIN_CONTINUE;
    
    new Float:velocity[3]
    pev(id, pev_velocity, velocity)
    new Float:origin[3]
    pev(id, pev_origin, origin)
    
    new Float:horiz = floatsqroot(velocity[0] * velocity[0] + velocity[1] * velocity[1])
    
    new buttons = pev(id, pev_button)
    new oldbuttons = pev(id, pev_oldbuttons)
    new onground = pev(id, pev_flags) & FL_ONGROUND
    
    if ((buttons & IN_JUMP && !(oldbuttons & IN_JUMP)) && onground)
    {
        new Float:weaponSpeed
        pev(id, pev_maxspeed, weaponSpeed)
        g_TakeoffHorizontalSpeed[id] = horiz
        g_TakeoffZ[id] = origin[2]
        g_TakeoffWeaponSpeed[id] = weaponSpeed
        g_IsJumpTakeoff[id] = true
        g_InPrediction[id] = true
        g_JumpFirstFrame[id] = true
    }
    else if ((buttons & IN_DUCK && !(oldbuttons & IN_DUCK)) && onground)
    {
        g_TakeoffHorizontalSpeed[id] = horiz
        g_TakeoffZ[id] = origin[2]
        g_IsJumpTakeoff[id] = false
        g_InPrediction[id] = true
        g_JumpFirstFrame[id] = true
    }
    
    new bool:isFirstFrame = g_JumpFirstFrame[id]
    
    if (g_InPrediction[id])
    {
        g_JumpFirstFrame[id] = false
        if (!onground)
        {
        }
        else if (g_PrevHorizontalSpeed[id] > 10.0 && horiz < 10.0)
        {
            g_InPrediction[id] = false
        }
    }
    
    new speed_r, speed_g, speed_b
    new Float:speedDiff = horiz - g_PrevHorizontalSpeed[id]
    if (speedDiff >= 0.01)
    {
        speed_r = g_SpeedColorGain[id][0]
        speed_g = g_SpeedColorGain[id][1]
        speed_b = g_SpeedColorGain[id][2]
    }
    else if (speedDiff <= -0.01)
    {
        speed_r = g_SpeedColorLoss[id][0]
        speed_g = g_SpeedColorLoss[id][1]
        speed_b = g_SpeedColorLoss[id][2]
    }
    else
    {
        speed_r = g_SpeedColorUnchanged[id][0]
        speed_g = g_SpeedColorUnchanged[id][1]
        speed_b = g_SpeedColorUnchanged[id][2]
    }
    
    new speed_text[64]
    new bool:shouldHideParen = (origin[2] <= g_TakeoffZ[id] - 18.0) || (onground && !isFirstFrame)
    new bool:showParen = isFirstFrame || !shouldHideParen
    
    if (!g_SpeedEnabled[id] && !g_PrestrafeEnabled[id] && !g_GainLossEnabled[id])
    {
        speed_text[0] = 0
    }
    else if (g_InPrediction[id] && showParen && (g_PrestrafeEnabled[id] || g_GainLossEnabled[id]))
    {
        new Float:displayTakeoffSpeed = g_TakeoffHorizontalSpeed[id]
        
        if (g_IsJumpTakeoff[id])
        {
            new Float:threshold = floatsqroot((g_TakeoffWeaponSpeed[id] * 1.2) * (g_TakeoffWeaponSpeed[id] * 1.2) - 4.0 * 4.0)
            
            if (g_TakeoffHorizontalSpeed[id] > threshold)
            {
                displayTakeoffSpeed = threshold * 0.8
            }
        }
        
        new Float:gain = horiz - displayTakeoffSpeed
        
        if (g_SpeedEnabled[id] && g_PrestrafeEnabled[id] && g_GainLossEnabled[id])
        {
            if (gain >= 0.0)
                formatex(speed_text, charsmax(speed_text), "%.2f^n(%.2f|+%.2f)", horiz, displayTakeoffSpeed, gain)
            else
                formatex(speed_text, charsmax(speed_text), "%.2f^n(%.2f|%.2f)", horiz, displayTakeoffSpeed, gain)
        }
        else if (g_SpeedEnabled[id] && g_PrestrafeEnabled[id])
        {
            formatex(speed_text, charsmax(speed_text), "%.2f^n(%.2f)", horiz, displayTakeoffSpeed)
        }
        else if (g_SpeedEnabled[id] && g_GainLossEnabled[id])
        {
            if (gain >= 0.0)
                formatex(speed_text, charsmax(speed_text), "%.2f^n(+%.2f)", horiz, gain)
            else
                formatex(speed_text, charsmax(speed_text), "%.2f^n(%.2f)", horiz, gain)
        }
        else if (g_PrestrafeEnabled[id] && g_GainLossEnabled[id])
        {
            if (gain >= 0.0)
                formatex(speed_text, charsmax(speed_text), "(%.2f|+%.2f)", displayTakeoffSpeed, gain)
            else
                formatex(speed_text, charsmax(speed_text), "(%.2f|%.2f)", displayTakeoffSpeed, gain)
        }
        else if (g_PrestrafeEnabled[id])
        {
            formatex(speed_text, charsmax(speed_text), "(%.2f)", displayTakeoffSpeed)
        }
        else if (g_GainLossEnabled[id])
        {
            if (gain >= 0.0)
                formatex(speed_text, charsmax(speed_text), "(+%.2f)", gain)
            else
                formatex(speed_text, charsmax(speed_text), "(%.2f)", gain)
        }
    }
    else if (g_SpeedEnabled[id])
    {
        formatex(speed_text, charsmax(speed_text), "%.2f", horiz)
    }
    else
    {
        speed_text[0] = 0
    }
    
    new observers[33], obs_count = 0
    GetObservers(id, observers, obs_count)
    
    set_dhudmessage(speed_r, speed_g, speed_b, -1.0, g_SpeedY[id], 0, 0.0, g_DhudHoldTime, 0.0, 0.0)
    for (new k = 0; k < obs_count; k++)
        show_dhudmessage(observers[k], speed_text)
    
    g_PrevHorizontalSpeed[id] = horiz
    
    return PLUGIN_CONTINUE;
}

stock GetObservers(jumper, observers[], &count)
{
    count = 0
    if (is_user_connected(jumper))
        observers[count++] = jumper
    for (new i = 1; i <= 32; i++)
    {
        if (i == jumper || !is_user_connected(i) || is_user_alive(i))
            continue
        if (pev(i, pev_iuser2) == jumper)
            observers[count++] = i
    }
}

stock show_speedmenu(id)
{
    new text[512]
    formatex(text, charsmax(text), "\rMHUD Speed^n^n")
    if (g_SpeedDisplayEnabled[id])
        formatex(text, charsmax(text), "%s\r1. \wGlobal - \yON^n^n", text)
    else
        formatex(text, charsmax(text), "%s\r1. \wGlobal - \rOFF^n^n", text)
    formatex(text, charsmax(text), "%s\r2. \wY - 0.01^n", text)
    formatex(text, charsmax(text), "%s\r3. \wY + 0.01^n", text)
    formatex(text, charsmax(text), "%s\r4. \yDefault Y (0.66)^n^n", text)
    if (g_SpeedEnabled[id])
        formatex(text, charsmax(text), "%s\r5. \wSpeed - \yON^n", text)
    else
        formatex(text, charsmax(text), "%s\r5. \wSpeed - \rOFF^n", text)
    if (g_PrestrafeEnabled[id])
        formatex(text, charsmax(text), "%s\r6. \wPrestrafe - \yON^n", text)
    else
        formatex(text, charsmax(text), "%s\r6. \wPrestrafe - \rOFF^n", text)
    if (g_GainLossEnabled[id])
        formatex(text, charsmax(text), "%s\r7. \wGain/Loss - \yON^n^n", text)
    else
        formatex(text, charsmax(text), "%s\r7. \wGain/Loss - \rOFF^n^n", text)
    formatex(text, charsmax(text), "%s\r8. \ySave Settings^n^n", text)
    formatex(text, charsmax(text), "%s\r0. \wBack", text)
    show_menu(id, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), text, -1, MENU_SPEED)
}

public handle_speedmenu(id, key)
{
    if (key == 9) { client_cmd(id, "say /mhud"); return; }
    switch (key)
    {
        case 0: { g_SpeedDisplayEnabled[id] = !g_SpeedDisplayEnabled[id]; show_speedmenu(id); }
        case 1:
        {
            g_SpeedY[id] -= 0.01;
            if (g_SpeedY[id] < 0.0) g_SpeedY[id] = 0.0;
            show_speedmenu(id);
        }
        case 2:
        {
            g_SpeedY[id] += 0.01;
            if (g_SpeedY[id] > 1.0) g_SpeedY[id] = 1.0;
            show_speedmenu(id);
        }
        case 3: { g_SpeedY[id] = 0.66; show_speedmenu(id); }
        case 4: { g_SpeedEnabled[id] = !g_SpeedEnabled[id]; show_speedmenu(id); }
        case 5: { g_PrestrafeEnabled[id] = !g_PrestrafeEnabled[id]; show_speedmenu(id); }
        case 6: { g_GainLossEnabled[id] = !g_GainLossEnabled[id]; show_speedmenu(id); }
        case 7: { SaveSpeedSettings(id); show_speedmenu(id); }
    }
}

stock SaveSpeedSettings(id=0)
{
    new configsdir[64]
    get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
    new szFile[128]
    formatex(szFile, charsmax(szFile), "%s/mhud_speed.ini", configsdir)
    
    new fp = fopen(szFile, "wt")
    if (fp)
    {
        new useId = (id == 0) ? 1 : id
        if (!is_user_connected(useId) && id == 0)
            useId = -1
        
        fprintf(fp, "enable_speed_hud %d^n", (useId != -1) ? (g_SpeedDisplayEnabled[useId] ? 1 : 0) : 1)
        fprintf(fp, "enable_speed_display %d^n", (useId != -1) ? (g_SpeedEnabled[useId] ? 1 : 0) : 1)
        fprintf(fp, "enable_prestrafe %d^n", (useId != -1) ? (g_PrestrafeEnabled[useId] ? 1 : 0) : 1)
        fprintf(fp, "enable_gainloss %d^n", (useId != -1) ? (g_GainLossEnabled[useId] ? 1 : 0) : 1)
        fprintf(fp, "hud_speed_y %.6f^n", (useId != -1) ? g_SpeedY[useId] : 0.66)
        fprintf(fp, "hud_speed_holdtime %.6f^n", g_DhudHoldTime)
        fprintf(fp, "hud_color_gain %d %d %d^n", (useId != -1) ? g_SpeedColorGain[useId][0] : 20, (useId != -1) ? g_SpeedColorGain[useId][1] : 255, (useId != -1) ? g_SpeedColorGain[useId][2] : 150)
        fprintf(fp, "hud_color_loss %d %d %d^n", (useId != -1) ? g_SpeedColorLoss[useId][0] : 255, (useId != -1) ? g_SpeedColorLoss[useId][1] : 70, (useId != -1) ? g_SpeedColorLoss[useId][2] : 120)
        fprintf(fp, "hud_color_unchanged %d %d %d^n", (useId != -1) ? g_SpeedColorUnchanged[useId][0] : 255, (useId != -1) ? g_SpeedColorUnchanged[useId][1] : 255, (useId != -1) ? g_SpeedColorUnchanged[useId][2] : 255)
        
        fclose(fp)
        if (id != 0)
            client_print_color(id, id, "^4[7yPh00N]^1 Settings Saved in ^4mhud_speed.ini")
    }
    else
    {
        if (id != 0)
            client_print_color(id, print_team_red, "^3[7yPh00N] Save Failed!!")
    }
}

stock LoadSpeedSettings(id=0)
{
    new configsdir[64]
    get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
    new szFile[128]
    formatex(szFile, charsmax(szFile), "%s/mhud_speed.ini", configsdir)
    
    new bool:temp_Enabled = true
    new bool:temp_SpeedEnabled = true
    new bool:temp_PrestrafeEnabled = true
    new bool:temp_GainLossEnabled = true
    new Float:temp_Y = 0.66
    new Float:temp_HoldTime = 0.011
    new temp_ColorGain[3] = {20, 255, 150}
    new temp_ColorLoss[3] = {255, 70, 120}
    new temp_ColorUnchanged[3] = {255, 255, 255}
    
    if (!file_exists(szFile))
    {
        if (id == 0) SaveSpeedSettings(0)
        if (id != 0) ApplySpeedSettings(id, temp_Enabled, temp_SpeedEnabled, temp_PrestrafeEnabled, temp_GainLossEnabled, temp_Y, temp_HoldTime, temp_ColorGain, temp_ColorLoss, temp_ColorUnchanged)
        return
    }
    
    new data[128], len
    new line = 0
    while (read_file(szFile, line, data, charsmax(data), len))
    {
        trim(data)
        if (data[0] == 0 || data[0] == '/') { line++; continue; }
        
        new key[32], arg1[32], arg2[32], arg3[32]
        new count = parse(data, key, charsmax(key), arg1, charsmax(arg1), arg2, charsmax(arg2), arg3, charsmax(arg3))
        
        if (equal(key, "enable_speed_hud") && count >= 2)
            temp_Enabled = (str_to_num(arg1) == 1)
        else if (equal(key, "enable_speed_display") && count >= 2)
            temp_SpeedEnabled = (str_to_num(arg1) == 1)
        else if (equal(key, "enable_prestrafe") && count >= 2)
            temp_PrestrafeEnabled = (str_to_num(arg1) == 1)
        else if (equal(key, "enable_gainloss") && count >= 2)
            temp_GainLossEnabled = (str_to_num(arg1) == 1)
        else if (equal(key, "hud_speed_y") && count >= 2)
        {
            new Float:fy = str_to_float(arg1)
            if (fy >= 0.0 && fy <= 1.0) temp_Y = fy
        }
        else if (equal(key, "hud_speed_holdtime") && count >= 2)
        {
            new Float:ft = str_to_float(arg1)
            if (ft >= 0.001 && ft <= 5.0) temp_HoldTime = ft
        }
        else if (equal(key, "hud_color_gain") && count >= 4)
        {
            temp_ColorGain[0] = str_to_num(arg1)
            temp_ColorGain[1] = str_to_num(arg2)
            temp_ColorGain[2] = str_to_num(arg3)
        }
        else if (equal(key, "hud_color_loss") && count >= 4)
        {
            temp_ColorLoss[0] = str_to_num(arg1)
            temp_ColorLoss[1] = str_to_num(arg2)
            temp_ColorLoss[2] = str_to_num(arg3)
        }
        else if (equal(key, "hud_color_unchanged") && count >= 4)
        {
            temp_ColorUnchanged[0] = str_to_num(arg1)
            temp_ColorUnchanged[1] = str_to_num(arg2)
            temp_ColorUnchanged[2] = str_to_num(arg3)
        }
        line++
    }
    
    if (id != 0)
        ApplySpeedSettings(id, temp_Enabled, temp_SpeedEnabled, temp_PrestrafeEnabled, temp_GainLossEnabled, temp_Y, temp_HoldTime, temp_ColorGain, temp_ColorLoss, temp_ColorUnchanged)
}

stock ApplySpeedSettings(id, bool:enabled, bool:speedEnabled, bool:prestrafeEnabled, bool:gainLossEnabled, Float:y, Float:holdtime, colorGain[], colorLoss[], colorUnchanged[])
{
    g_SpeedDisplayEnabled[id] = enabled
    g_SpeedEnabled[id] = speedEnabled
    g_PrestrafeEnabled[id] = prestrafeEnabled
    g_GainLossEnabled[id] = gainLossEnabled
    g_SpeedY[id] = y
    g_SpeedHoldTime[id] = holdtime
    g_SpeedColorGain[id][0] = colorGain[0]
    g_SpeedColorGain[id][1] = colorGain[1]
    g_SpeedColorGain[id][2] = colorGain[2]
    g_SpeedColorLoss[id][0] = colorLoss[0]
    g_SpeedColorLoss[id][1] = colorLoss[1]
    g_SpeedColorLoss[id][2] = colorLoss[2]
    g_SpeedColorUnchanged[id][0] = colorUnchanged[0]
    g_SpeedColorUnchanged[id][1] = colorUnchanged[1]
    g_SpeedColorUnchanged[id][2] = colorUnchanged[2]
}

stock LoadServerConfig()
{
    new configsdir[64]
    get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
    new szFile[128]
    formatex(szFile, charsmax(szFile), "%s/mhud_server.ini", configsdir)
  
    if (!file_exists(szFile))
    {
        g_DhudHoldTime = 0.011
        return
    }
  
    new data[128], len, line = 0
    while (read_file(szFile, line, data, charsmax(data), len))
    {
        trim(data)
        if (data[0] == 0 || data[0] == '/') { line++; continue; }
        new key[32], arg[32]
        parse(data, key, charsmax(key), arg, charsmax(arg))
        if (equal(key, "dhud_holdtime"))
            g_DhudHoldTime = str_to_float(arg)
        line++
    }
  
    if (g_DhudHoldTime < 0.001 || g_DhudHoldTime > 5.0) g_DhudHoldTime = 0.011
}