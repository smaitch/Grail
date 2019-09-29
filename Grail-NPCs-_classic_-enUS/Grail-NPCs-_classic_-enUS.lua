--
--
--	UTF-8 file
--

if GetLocale() ~= "enUS" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[0]='Self'
G[1]=ADVENTURE_JOURNAL
G[1000031]='Old Lion Statue'
G[1000033]='Locked Chest'
G[1000034]='Old Jug'
G[1000035]="Captain's Footlocker"
G[1000036]='Broken Barrel'
G[1000047]='Wanted: Lieutenant Fangore'
G[1000055]='A half-eaten body'
G[1000056]="Rolf's corpse"
G[1000059]='Mound of loose dirt'
G[1000060]="Wanted: Gath'Ilzogg"
G[1000061]='A Weathered Grave'
G[1000068]='Wanted Poster'
G[1000256]='WANTED'
G[1000257]='Suspicious Barrel'
G[1000259]='Half-buried Barrel'
G[1000261]='Damaged Crate'
G[1000270]='Unguarded Thunder Ale Barrel'
G[1001561]='Sealed Crate'
G[1001585]='Explosive Charge'
G[1001609]='Dragonmaw Catapult'
G[1002059]='A Dwarven Corpse'
G[1002652]="Ebenezer Rustlocke's Corpse"
G[1002734]='Waterlogged Chest'
G[1003643]='Old Footlocker'
G[1004141]='Control Console'
G[1006751]='Strange Fruited Plant'
G[1006752]='Strange Fronded Plant'
G[1007510]='Sprouted Frond'
G[1010076]='Scrying Bowl'
G[1012666]='Twilight Tome'
G[1017182]='Buzzbox 827'
G[1017183]='Buzzbox 411'
G[1017184]='Buzzbox 323'
G[1017185]='Buzzbox 525'
G[1019024]='Hidden Shrine'
G[1051708]="Eliza's Grave Dirt"
G[1112948]="Intrepid's Locked Strongbox"
G[1113791]='Brazier of Everfount'
G[1142151]='Sealed Barrel'
G[1156561]='Wanted Poster'
G[1175226]='Beached Sea Creature'
G[1175227]='Beached Sea Creature'
G[1175233]='Beached Sea Creature'
G[1175524]='Mysterious Red Crystal'
G[1176190]='Beached Sea Turtle'
G[1176191]='Beached Sea Turtle'
G[1176196]='Beached Sea Turtle'
G[1176197]='Beached Sea Turtle'
G[1176198]='Beached Sea Turtle'
end

--	End of localized NPC names
