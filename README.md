# Custom Decals
A SourceMod plugin for TF2 which allows players to apply custom decals to eligible weapons and cosmetics.

# Requirements
- [TF2Items](https://forums.alliedmods.net/showthread.php?t=115100)
- [TF2Attributes](https://github.com/FlaminSarge/tf2attributes)
- [TF2 Econ Data](https://github.com/nosoop/SM-TFEconData)

# Commands
- `sm_forcedecal <#userid|name> <UGC ID>` - Admin command (ADMFLAG_GENERIC) which applies a decal to a specified player's item
- `sm_decal <UGC ID>` - User command which applies a decal to your own item
- `sm_decalhelp` - Displays the below help message in-game

# Usage
1. Get a 128x128 image (same image used for colored decals)
2. [Make a TF2 guide](https://steamcommunity.com/sharedfiles/editguide/?appid=440) and upload the image as an icon (branding image)
3. Save the guide and preview it (WITHOUT publishing it!)
4. Copy the icon URL. The URL MUST start with steamuserimages...
3. Copy the number after the /ugc/ part, for example: `steamuserimages-a.akamaihd.net/ugc/123456789123456789/...`
4. Wait 15-30 seconds then run the command. Example command: `sm_decal 123456789123456789`
