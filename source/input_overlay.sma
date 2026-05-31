#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME "Input Overlay"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_AUTHOR "7yPh00N"

new bool:g_KeyDisplayEnabled[33]
new g_FrameCount[33]
new g_JumpFrame[33]
new g_WAReleaseDiff[33]
new g_WDReleaseDiff[33]
new g_SAReleaseDiff[33]
new g_SDReleaseDiff[33]
new bool:g_WAPressed[33]
new bool:g_WDPressed[33]
new bool:g_SAPressed[33]
new bool:g_SDPressed[33]
new bool:g_InCombo[33]
new bool:g_WAReleased[33]
new bool:g_WDReleased[33]
new bool:g_SAReleased[33]
new bool:g_SDReleased[33]
new g_KeyHistory[33][12][5]
new g_HistoryHead[33]
new g_HistorySize[33]
new g_ReleasedKey[33]
new g_ReleasedKeyDiff[33]
new const MENU_KEY[] = "KeyMenu"
new Float:g_KeyY[33]
new Float:g_LastPosX[33]
new g_FirstFrame[33]
new bool:g_FastMovement[33]

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
    register_clcmd("say /mkey", "cmd_toggle_keys")
    register_clcmd("say_team /mkey", "cmd_toggle_keys")
    register_clcmd("say mkey", "cmd_toggle_keys")
    register_clcmd("say_team mkey", "cmd_toggle_keys")
    register_clcmd("say /mkeys", "cmd_keymenu")
    register_clcmd("say_team /mkeys", "cmd_keymenu")
    register_clcmd("say mkeys", "cmd_keymenu")
    register_clcmd("say_team mkeys", "cmd_keymenu")
    register_menucmd(register_menuid(MENU_KEY), (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), "handle_keymenu")
    
    for (new i = 0; i < 33; i++)
    {
        g_KeyDisplayEnabled[i] = true
        g_KeyY[i] = 0.85
        g_FrameCount[i] = 0
        g_JumpFrame[i] = 0
        g_WAReleaseDiff[i] = 0
        g_WDReleaseDiff[i] = 0
        g_SAReleaseDiff[i] = 0
        g_SDReleaseDiff[i] = 0
        g_WAPressed[i] = false
        g_WDPressed[i] = false
        g_SAPressed[i] = false
        g_SDPressed[i] = false
        g_InCombo[i] = false
        g_WAReleased[i] = false
        g_WDReleased[i] = false
        g_SAReleased[i] = false
        g_SDReleased[i] = false
        g_HistoryHead[i] = 0
        g_HistorySize[i] = 0
        g_ReleasedKey[i] = 0
        g_ReleasedKeyDiff[i] = 0
        g_LastPosX[i] = 0.0
        g_FirstFrame[i] = 1
        g_FastMovement[i] = false
    }
    
    LoadInputSettings(0)
}

public client_connect(id)
{
    LoadInputSettings(id)
    g_FrameCount[id] = 0
    g_JumpFrame[id] = 0
    g_WAReleaseDiff[id] = 0
    g_WDReleaseDiff[id] = 0
    g_SAReleaseDiff[id] = 0
    g_SDReleaseDiff[id] = 0
    g_WAPressed[id] = false
    g_WDPressed[id] = false
    g_SAPressed[id] = false
    g_SDPressed[id] = false
    g_InCombo[id] = false
    g_WAReleased[id] = false
    g_WDReleased[id] = false
    g_SAReleased[id] = false
    g_SDReleased[id] = false
    g_HistoryHead[id] = 0
    g_HistorySize[id] = 0
    g_ReleasedKey[id] = 0
    g_ReleasedKeyDiff[id] = 0
    g_LastPosX[id] = 0.0
    g_FirstFrame[id] = 1
    g_FastMovement[id] = false
}

public cmd_toggle_keys(id)
{
    if (!is_user_connected(id)) return PLUGIN_HANDLED;
    g_KeyDisplayEnabled[id] = !g_KeyDisplayEnabled[id];
    client_print_color(id, id, "^4[7yPh00N]^1 Key Display: %s", g_KeyDisplayEnabled[id] ? "^3ON" : "^3OFF");
    return PLUGIN_HANDLED;
}

public fw_PlayerPreThink(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return FMRES_IGNORED;
    
    g_FrameCount[id]++
    
    new Float:currPosX
    pev(id, pev_origin, currPosX)
    
    if (!g_FirstFrame[id])
    {
        new Float:deltaX = floatabs(currPosX - g_LastPosX[id])
        if (deltaX > 50.0)
            g_FastMovement[id] = true
    }
    g_LastPosX[id] = currPosX
    g_FirstFrame[id] = 0
    
    new buttons = pev(id, pev_button)
    new oldbuttons = pev(id, pev_oldbuttons)
    new oldHead = g_HistoryHead[id]
    
    g_KeyHistory[id][g_HistoryHead[id]][0] = (oldbuttons & IN_FORWARD) ? 1 : 0
    g_KeyHistory[id][g_HistoryHead[id]][1] = (oldbuttons & IN_BACK) ? 1 : 0
    g_KeyHistory[id][g_HistoryHead[id]][2] = (oldbuttons & IN_MOVELEFT) ? 1 : 0
    g_KeyHistory[id][g_HistoryHead[id]][3] = (oldbuttons & IN_MOVERIGHT) ? 1 : 0
    g_KeyHistory[id][g_HistoryHead[id]][4] = g_FrameCount[id] - 1
    
    g_HistoryHead[id] = (g_HistoryHead[id] + 1) % 12
    if (g_HistorySize[id] < 12)
        g_HistorySize[id]++
    
    new bool:keyW = !!(buttons & IN_FORWARD)
    new bool:keyS = !!(buttons & IN_BACK)
    new bool:keyA = !!(buttons & IN_MOVELEFT)
    new bool:keyD = !!(buttons & IN_MOVERIGHT)
    new bool:keyC = !!(buttons & IN_DUCK)
    new bool:keyJ = !!(buttons & IN_JUMP)
    
    new bool:oldKeyW = !!(oldbuttons & IN_FORWARD)
    new bool:oldKeyS = !!(oldbuttons & IN_BACK)
    new bool:oldKeyA = !!(oldbuttons & IN_MOVELEFT)
    new bool:oldKeyD = !!(oldbuttons & IN_MOVERIGHT)
    new bool:oldKeyJ = !!(oldbuttons & IN_JUMP)
    
    new bool:onGround = !!(pev(id, pev_flags) & FL_ONGROUND)
    
    new bool:isWA = keyW && keyA
    new bool:isWD = keyW && keyD
    new bool:isSA = keyS && keyA
    new bool:isSD = keyS && keyD
    
    new bool:wasWA = oldKeyW && oldKeyA
    new bool:wasWD = oldKeyW && oldKeyD
    new bool:wasSA = oldKeyS && oldKeyA
    new bool:wasSD = oldKeyS && oldKeyD

    if (g_ReleasedKey[id] != 0)
    {
        switch (g_ReleasedKey[id])
        {
            case 1: // A
            {
                if (!oldKeyA && keyA)
                {
                    g_ReleasedKey[id] = 0;
                    g_ReleasedKeyDiff[id] = 0;
                }
            }
            case 2: // W
            {
                if (!oldKeyW && keyW)
                {
                    g_ReleasedKey[id] = 0;
                    g_ReleasedKeyDiff[id] = 0;
                }
            }
            case 3: // S
            {
                if (!oldKeyS && keyS)
                {
                    g_ReleasedKey[id] = 0;
                    g_ReleasedKeyDiff[id] = 0;
                }
            }
            case 4: // D
            {
                if (!oldKeyD && keyD)
                {
                    g_ReleasedKey[id] = 0;
                    g_ReleasedKeyDiff[id] = 0;
                }
            }
        }
    }
    
    if ((keyJ && !oldKeyJ) && onGround)
    {
        g_JumpFrame[id] = g_FrameCount[id]
        
        g_WAReleased[id] = false
        g_WDReleased[id] = false
        g_SAReleased[id] = false
        g_SDReleased[id] = false
        g_WAReleaseDiff[id] = 0
        g_WDReleaseDiff[id] = 0
        g_SAReleaseDiff[id] = 0
        g_SDReleaseDiff[id] = 0
        g_ReleasedKey[id] = 0
        g_ReleasedKeyDiff[id] = 0
        g_FastMovement[id] = false
        
        new bool:skipHistory = false
        
        if (!skipHistory && (oldKeyW && !keyW) && oldKeyA)
        {
            g_WAReleased[id] = true
            g_WAReleaseDiff[id] = 0
            g_ReleasedKey[id] = 2
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyA && !keyA) && oldKeyW)
        {
            g_WAReleased[id] = true
            g_WAReleaseDiff[id] = 0
            g_ReleasedKey[id] = 1
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyW && !keyW) && oldKeyD)
        {
            g_WDReleased[id] = true
            g_WDReleaseDiff[id] = 0
            g_ReleasedKey[id] = 2
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyD && !keyD) && oldKeyW)
        {
            g_WDReleased[id] = true
            g_WDReleaseDiff[id] = 0
            g_ReleasedKey[id] = 4
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyS && !keyS) && oldKeyA)
        {
            g_SAReleased[id] = true
            g_SAReleaseDiff[id] = 0
            g_ReleasedKey[id] = 3
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyA && !keyA) && oldKeyS)
        {
            g_SAReleased[id] = true
            g_SAReleaseDiff[id] = 0
            g_ReleasedKey[id] = 1
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyS && !keyS) && oldKeyD)
        {
            g_SDReleased[id] = true
            g_SDReleaseDiff[id] = 0
            g_ReleasedKey[id] = 3
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        else if (!skipHistory && (oldKeyD && !keyD) && oldKeyS)
        {
            g_SDReleased[id] = true
            g_SDReleaseDiff[id] = 0
            g_ReleasedKey[id] = 4
            g_ReleasedKeyDiff[id] = 0
            skipHistory = true
        }
        
        if (!skipHistory)
        {
            new searchCount = g_HistorySize[id] - 1
            if (searchCount > 10) searchCount = 10
            
            new startIdx = oldHead
            for (new i = 0; i < searchCount; i++)
            {
                new histIdx = (startIdx - 1 - i + 12) % 12
                if (histIdx < 0 || histIdx >= 12)
                    continue
                
                new prevFrame = g_KeyHistory[id][histIdx][4]
                if (prevFrame <= 0)
                    continue
                
                new diff = prevFrame - g_JumpFrame[id] + 1
                if (diff < -10 || diff >= 0)
                    continue
                
                new prevW = g_KeyHistory[id][histIdx][0]
                new prevS = g_KeyHistory[id][histIdx][1]
                new prevA = g_KeyHistory[id][histIdx][2]
                new prevD = g_KeyHistory[id][histIdx][3]
                
                if (g_ReleasedKey[id] == 0)
                {
                    if (prevW && !keyW && prevA)
                    {
                        g_WAReleased[id] = true
                        g_WAReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 2
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevW && !keyW && prevD)
                    {
                        g_WDReleased[id] = true
                        g_WDReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 2
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevA && !keyA && prevS)
                    {
                        g_SAReleased[id] = true
                        g_SAReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 1
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevA && !keyA && prevW)
                    {
                        g_WAReleased[id] = true
                        g_WAReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 1
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevS && !keyS && prevA)
                    {
                        g_SAReleased[id] = true
                        g_SAReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 3
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevS && !keyS && prevD)
                    {
                        g_SDReleased[id] = true
                        g_SDReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 3
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevD && !keyD && prevW)
                    {
                        g_WDReleased[id] = true
                        g_WDReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 4
                        g_ReleasedKeyDiff[id] = diff
                    }
                    else if (prevD && !keyD && prevS)
                    {
                        g_SDReleased[id] = true
                        g_SDReleaseDiff[id] = diff
                        g_ReleasedKey[id] = 4
                        g_ReleasedKeyDiff[id] = diff
                    }
                }
            }
        }
    }
    
    if (g_JumpFrame[id] > 0)
    {
        if (g_ReleasedKey[id] == 0)
        {
            if (isWA || wasWA)
            {
                if (!keyW && oldKeyW)
                {
                    g_WAReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_WAReleased[id] = true
                    g_ReleasedKey[id] = 2
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
                else if (!keyA && oldKeyA)
                {
                    g_WAReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_WAReleased[id] = true
                    g_ReleasedKey[id] = 1
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
            }
            if (isWD || wasWD)
            {
                if (!keyW && oldKeyW)
                {
                    g_WDReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_WDReleased[id] = true
                    g_ReleasedKey[id] = 2
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
                else if (!keyD && oldKeyD)
                {
                    g_WDReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_WDReleased[id] = true
                    g_ReleasedKey[id] = 4
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
            }
            if (isSA || wasSA)
            {
                if (!keyS && oldKeyS)
                {
                    g_SAReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_SAReleased[id] = true
                    g_ReleasedKey[id] = 3
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
                else if (!keyA && oldKeyA)
                {
                    g_SAReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_SAReleased[id] = true
                    g_ReleasedKey[id] = 1
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
            }
            if (isSD || wasSD)
            {
                if (!keyS && oldKeyS)
                {
                    g_SDReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_SDReleased[id] = true
                    g_ReleasedKey[id] = 3
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
                else if (!keyD && oldKeyD)
                {
                    g_SDReleaseDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                    g_SDReleased[id] = true
                    g_ReleasedKey[id] = 4
                    g_ReleasedKeyDiff[id] = g_FrameCount[id] - g_JumpFrame[id]
                }
            }
        }
    }
    
    if (g_ReleasedKey[id] != 0 && (g_ReleasedKeyDiff[id] >= 100 || g_ReleasedKeyDiff[id] <= -100))
    {
        g_ReleasedKey[id] = 0;
        g_ReleasedKeyDiff[id] = 0;
    }
    
    new key_text[64]
    new top_row[32], bottom_row[32]
    
    if (keyC)
        formatex(top_row, charsmax(top_row), "C")
    else
        formatex(top_row, charsmax(top_row), " ")
    
    new releaseKey = g_ReleasedKey[id]
    new releaseDiff = g_ReleasedKeyDiff[id]
    
    new diffStr[8]
    if (releaseDiff > 0)
        formatex(diffStr, charsmax(diffStr), "%d", releaseDiff)
    else if (releaseDiff < 0)
        formatex(diffStr, charsmax(diffStr), "%d", releaseDiff)
    else if (releaseDiff == 0 && releaseKey != 0)
        formatex(diffStr, charsmax(diffStr), "0")
    
    // 第一行：C, W/数字, J
    if (releaseKey == 2 && !keyW && !g_FastMovement[id])
    {
        formatex(top_row, charsmax(top_row), "%s   %s", top_row, diffStr)
    }
    else
    {
        if (keyW)
            formatex(top_row, charsmax(top_row), "%s   W", top_row)
        else
            formatex(top_row, charsmax(top_row), "%s   –", top_row)
    }
    
    if (keyJ)
        formatex(top_row, charsmax(top_row), "%s   J", top_row)
    else
        formatex(top_row, charsmax(top_row), "%s    ", top_row)
    
    // 底部行：A, S, D
    new a_display[8], s_display[8], d_display[8]
    
    // A键显示
    if (releaseKey == 1 && !keyA && !g_FastMovement[id])
        formatex(a_display, charsmax(a_display), "%s", diffStr)
    else
        formatex(a_display, charsmax(a_display), "%s", keyA ? "A" : "–")
    
    // S键显示
    if (releaseKey == 3 && !keyS && !g_FastMovement[id])
        formatex(s_display, charsmax(s_display), "%s", diffStr)
    else
        formatex(s_display, charsmax(s_display), "%s", keyS ? "S" : "–")
    
    // D键显示
    if (releaseKey == 4 && !keyD && !g_FastMovement[id])
        formatex(d_display, charsmax(d_display), "%s", diffStr)
    else
        formatex(d_display, charsmax(d_display), "%s", keyD ? "D" : "–")
    
    // 根据是否负数调整空格数量
    new spacer1[4], spacer2[4]
    if (a_display[0] == '-')
        formatex(spacer1, charsmax(spacer1), "  ")
    else
        formatex(spacer1, charsmax(spacer1), "   ")
    
    if (d_display[0] == '-')
        formatex(spacer2, charsmax(spacer2), "  ")
    else
        formatex(spacer2, charsmax(spacer2), "   ")
    
    formatex(bottom_row, charsmax(bottom_row), "%s%s%s%s%s", a_display, spacer1, s_display, spacer2, d_display)
    
    formatex(key_text, charsmax(key_text), "%s^n%s", top_row, bottom_row)
    
    new hud_r = 255, hud_g = 255, hud_b = 255
    
    new bool:noKeysInAir = !keyW && !keyS && !keyA && !keyD
    
    if ((keyA && keyD) || (keyW && keyS) || (!onGround && noKeysInAir))
    {
        hud_r = 255
        hud_g = 0
        hud_b = 0
    }
    
    if (g_JumpFrame[id] > 0 && g_ReleasedKeyDiff[id] > 0 && g_ReleasedKey[id] == 0)
    {
        hud_r = 255
        hud_g = 0
        hud_b = 0
    }
    
    new bool:isCombo = (keyW && keyA) || (keyW && keyD) || (keyS && keyA) || (keyS && keyD)
    
    if ((g_JumpFrame[id] > 0 && !onGround && g_ReleasedKeyDiff[id] == 0) || (g_JumpFrame[id] == g_FrameCount[id] && isCombo))
    {
        hud_r = 255
        hud_g = 0
        hud_b = 0
    }
    
    if (!onGround)
    {
        new bool:singleW = keyW && !keyA && !keyD && !keyS
        new bool:singleS = keyS && !keyA && !keyD && !keyW
        new bool:singleA = keyA && !keyW && !keyS && !keyD
        new bool:singleD = keyD && !keyW && !keyS && !keyA
        
        if (singleW || singleS || singleA || singleD)
        {
            hud_r = 255
            hud_g = 255
            hud_b = 255
        }
    }
    
    new observers[33], obs_count = 0
    GetObservers(id, observers, obs_count)
    
    if (g_KeyDisplayEnabled[id])
    {
        set_dhudmessage(hud_r, hud_g, hud_b, -1.0, g_KeyY[id], 0, 0.0, 0.011, 0.0, 0.0)
        for (new k = 0; k < obs_count; k++)
            show_dhudmessage(observers[k], key_text)
    }
    else
    {
        for (new k = 0; k < obs_count; k++)
        {
            if (observers[k] != id)
            {
                set_dhudmessage(hud_r, hud_g, hud_b, -1.0, g_KeyY[id], 0, 0.0, 0.011, 0.0, 0.0)
                show_dhudmessage(observers[k], key_text)
            }
        }
    }
    
    return FMRES_IGNORED;
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

public cmd_keymenu(id)
{
    if (!is_user_connected(id)) return PLUGIN_HANDLED;
    show_keymenu(id);
    return PLUGIN_HANDLED;
}

stock show_keymenu(id)
{
    new text[512]
    formatex(text, charsmax(text), "\rInput Overlay^n^n")
    if (g_KeyDisplayEnabled[id])
        formatex(text, charsmax(text), "%s\r1. \wGlobal - \yON^n^n", text)
    else
        formatex(text, charsmax(text), "%s\r1. \wGlobal - \rOFF^n^n", text)
    formatex(text, charsmax(text), "%s\r2. \wY - 0.01^n", text)
    formatex(text, charsmax(text), "%s\r3. \wY + 0.01^n", text)
    formatex(text, charsmax(text), "%s\r4. \yDefault Y (0.85)^n^n", text)
    formatex(text, charsmax(text), "%s\r5. \ySave Settings^n^n", text)
    formatex(text, charsmax(text), "%s\r0. \wBack", text)
    show_menu(id, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), text, -1, MENU_KEY)
}

public handle_keymenu(id, key)
{
    if (key == 9) { client_cmd(id, "say /mhud"); return; }
    switch (key)
    {
        case 0: { g_KeyDisplayEnabled[id] = !g_KeyDisplayEnabled[id]; show_keymenu(id); }
        case 1:
        {
            g_KeyY[id] -= 0.01;
            if (g_KeyY[id] < 0.0) g_KeyY[id] = 0.0;
            show_keymenu(id);
        }
        case 2:
        {
            g_KeyY[id] += 0.01;
            if (g_KeyY[id] > 1.0) g_KeyY[id] = 1.0;
            show_keymenu(id);
        }
        case 3: { g_KeyY[id] = 0.85; show_keymenu(id); }
        case 4: { SaveInputSettings(id); show_keymenu(id); }
    }
}

stock SaveInputSettings(id=0)
{
    new configsdir[64]
    get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
    new szFile[128]
    formatex(szFile, charsmax(szFile), "%s/input_overlay.ini", configsdir)
    
    new fp = fopen(szFile, "wt")
    if (fp)
    {
        fprintf(fp, "enable_input_overlay %d^n", g_KeyDisplayEnabled[id] ? 1 : 0)
        fprintf(fp, "hud_input_overlay_y %.2f^n", g_KeyY[id])
        
        fclose(fp)
        if (id != 0)
            client_print_color(id, id, "^4[7yPh00N]^1 Settings Saved in ^4input_overlay.ini")
    }
    else
    {
        if (id != 0)
            client_print_color(id, print_team_red, "^3[7yPh00N] Save Failed!!")
    }
}

stock LoadInputSettings(id=0)
{
    new configsdir[64]
    get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir))
    new szFile[128]
    formatex(szFile, charsmax(szFile), "%s/input_overlay.ini", configsdir)
    
    new bool:temp_Enabled = true
    new Float:temp_Y = 0.85
    
    if (!file_exists(szFile))
    {
        if (id == 0) SaveInputSettings(0)
        if (id != 0)
        {
            g_KeyDisplayEnabled[id] = temp_Enabled
            g_KeyY[id] = temp_Y
        }
        return
    }
    
    new data[128], len
    new line = 0
    while (read_file(szFile, line, data, charsmax(data), len))
    {
        trim(data)
        if (data[0] == 0 || data[0] == '/') { line++; continue; }
        
        new key[32], arg1[32], arg2[32]
        new count = parse(data, key, charsmax(key), arg1, charsmax(arg1), arg2, charsmax(arg2))
        
        if (equal(key, "enable_input_overlay") && count >= 2)
            temp_Enabled = (str_to_num(arg1) == 1)
        else if (equal(key, "hud_input_overlay_y") && count >= 2)
        {
            new Float:fy = str_to_float(arg1)
            if (fy >= 0.0 && fy <= 1.0) temp_Y = fy
        }
        line++
    }
    
    if (id != 0)
    {
        g_KeyDisplayEnabled[id] = temp_Enabled
        g_KeyY[id] = temp_Y
    }
}