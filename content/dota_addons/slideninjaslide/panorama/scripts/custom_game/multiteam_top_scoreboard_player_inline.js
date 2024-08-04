function PortraitClicked()
{
    Players.PlayerPortraitClicked( $.GetContextPanel().GetAttributeInt( "player_id", -1 ), GameUI.IsControlDown(), GameUI.IsAltDown() );
}