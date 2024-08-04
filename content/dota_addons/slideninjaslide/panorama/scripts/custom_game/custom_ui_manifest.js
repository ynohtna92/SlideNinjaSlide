GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );	// Glyph
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );	// Courier
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );	// Quick buy
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );			// Heroes and team score at the top of the HUD
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );	// flyout scoreboard
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );			// Endgame scoreboard

// These lines set up the panorama colors used by each team (for game select/setup, etc)
GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#0080D0;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#D02020;";

if (Game.GetMapInfo().map_display_name == "run_gay_run")
{
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#FF00FF;";
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#FF00FF;";
}

// These lines set up the panorama colors used by each player on the top scoreboard
GameUI.CustomUIConfig().player_colors = {}
GameUI.CustomUIConfig().player_colors[0] = "#3375FF;";
GameUI.CustomUIConfig().player_colors[1] = "#57E19A;";
GameUI.CustomUIConfig().player_colors[2] = "#AA00A0;";
GameUI.CustomUIConfig().player_colors[3] = "#D3CB14;";
GameUI.CustomUIConfig().player_colors[4] = "#D65705;";
GameUI.CustomUIConfig().player_colors[5] = "#D26496;";
GameUI.CustomUIConfig().player_colors[6] = "#829650;";
GameUI.CustomUIConfig().player_colors[7] = "#64BEC8;";
GameUI.CustomUIConfig().player_colors[8] = "#056E32;";
GameUI.CustomUIConfig().player_colors[9] = "#825005;";
GameUI.CustomUIConfig().player_colors[10] = "#DC74A8;";
GameUI.CustomUIConfig().player_colors[11] = "#748030;";
GameUI.CustomUIConfig().player_colors[12] = "#58BCD4;";
GameUI.CustomUIConfig().player_colors[13] = "#00701C;";
GameUI.CustomUIConfig().player_colors[14] = "#885400;";
GameUI.CustomUIConfig().player_colors[15] = "#F37AF3;";
GameUI.CustomUIConfig().player_colors[16] = "#F00000;";
GameUI.CustomUIConfig().player_colors[17] = "#F88000;";
GameUI.CustomUIConfig().player_colors[18] = "#E0B818;";
GameUI.CustomUIConfig().player_colors[19] = "#A0FF60;";