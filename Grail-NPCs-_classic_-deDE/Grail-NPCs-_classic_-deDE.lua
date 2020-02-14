--
--
--	UTF-8 file
--

if GetLocale() ~= "deDE" then return end
local G = Grail.npc.name
local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

if release >= 0 then
G[0]='Selbst'
G[1000031]='Alte Löwenstatue'
G[1000033]='Verschlossene Truhe'
G[1000034]='Alter Henkelkrug'
G[1000035]='Schließkiste des Captains'
G[1000036]='Zerbrochenes Fass'
G[1000047]='GESUCHT: Lieutenant Fangor'
G[1000055]='Ein halb aufgefressener Körper'
G[1000056]='Rolfs Leichnam'
G[1000059]='Lockerer Erdhaufen'
G[1000060]='GESUCHT: Gath’Ilzogg'
G[1000061]='Ein verwittertes Grab'
G[1000068]='Steckbrief'
G[1000076]='Ein leerer Krug'
G[1000256]='GESUCHT'
G[1000257]='Verdächtiges Fass'
G[1000259]='Halb vergrabenes Fass'
G[1000261]='Beschädigte Kiste'
G[1000269]='Bewachtes Fass mit Donnerbier'
G[1000270]='Unbewachtes Fass mit Donnerbier'
G[1000287]='Buchhalter Herods Aufzeichnungen'
G[1000288]='Buchhalter Herods Geldkassette'
G[1000711]='GESUCHT!'
G[1001557]='Lilliths Esstisch'
G[1001561]='Versiegelte Kiste'
G[1001585]='Sprengladung'
G[1001586]='Kiste mit Kerzen'
G[1001593]='Boot mit Leichen'
G[1001599]='Flaches Grab'
G[1001609]='Katapult der Dragonmaw'
G[1001627]='Kiste aus Dalaran'
G[1001728]='Staubiger Teppich'
G[1001740]='Dokumente des Syndikats'
G[1001763]='GESUCHT'
G[1001765]='Abgenutzte Holztruhe'
G[1001767]='Helculars Grab'
G[1002008]='Gefährlich!'
G[1002059]='Eine Zwergenleiche'
G[1002076]='Blubbernder Kessel'
G[1002083]='Blutsegelkorrespondenz'
G[1002289]='Defektes Rettungsboot'
G[1002382]='Objekte'
G[1002553]='Eine glitschige Rolle'
G[1002555]='Modrige Rolle'
G[1002556]='Cortellos Schatz'
G[1002560]='Halb vergrabene Flasche'
G[1002652]='Ebenezer Rustlockes Leichnam'
G[1002688]='Hauptstein'
G[1002701]='Regenbogenfarbene Splitter'
G[1002702]='Stein der inneren Bindung'
G[1002703]='Trollbanes Grabmal'
G[1002713]='Steckbriefbrett'
G[1002734]='Durchnässte Truhe'
G[1002868]='Zerknitterte Karte'
G[1002875]='Ramponiertes Zwergenskelett'
G[1002908]='Versiegelte Vorratskiste'
G[1003080]='Objekte'
G[1003238]='Chens leeres Fässchen'
G[1003239]='Benedicts Truhe'
G[1003643]='Alte Schließkiste'
G[1003972]='GESUCHT'
G[1004141]='Steuerkonsole'
G[1006751]='Sonderbare fruchtbeladene Pflanze'
G[1006752]='Sonderbare wedelbestückte Pflanze'
G[1007510]='Sprießender Wedel'
G[1010076]='Wahrsageschale'
G[1012666]='Twilight-Foliant'
G[1017182]='Dröhnkiste 827'
G[1017183]='Dröhnkiste 411'
G[1017184]='Dröhnkiste 323'
G[1017185]='Dröhnkiste 525'
G[1019024]='Verborgener Schrein'
G[1020805]='Rizzles Pläne'
G[1020985]='Lockerer Dreck'
G[1020992]='Schwarzer Schild'
G[1021015]='Hufabdrücke'
G[1021042]='Abzeichen der Wache von Theramore'
G[1024776]='Yurivs Grabstein'
G[1032569]='Galens Geldkassette'
G[1035251]='Karnitols Truhe'
G[1050961]='Malem-Truhe'
G[1051708]='Elizas Graberde'
G[1089931]='Bath’rahs Kessel'
G[1112888]='Staubiges Regal'
G[1112948]='Verschlossene Geldkassette der INTREPID'
G[1113791]='Kohlenpfanne von Everfount'
G[1138492]='Splitter von Myzrael'
G[1141980]='Geisterhafte Schließkassette'
G[1142071]='Ei-O-Mat'
G[1142151]='Versiegeltes Fass'
G[1142179]='Solarsal Pavillon'
G[1142194]='Piratenschatz!'
G[1144063]='Equinex-Monolith'
G[1148498]='Altar von Suntara'
G[1148504]='Ein verdächtiger Grabstein'
G[1156561]='Steckbrief'
G[1161504]='Ein kleines Pack'
G[1161505]='Ein havariertes Floß'
G[1164909]='Havariertes Ruderboot'
G[1164953]='Große Lederrucksäcke'
G[1164955]='Nördlicher Kristallpylon'
G[1164956]='Westlicher Kristallpylon'
G[1164957]='Östlicher Kristallpylon'
G[1173265]='Hölzernes Plumpsklo'
G[1173327]='Verderbte Windblüte'
G[1174594]='Verderbte Liedblume'
G[1174600]='Verderbte Windblüte'
G[1174682]='Vorsicht, Pterrordax!'
G[1174709]='Verderbte Windblüte'
G[1175226]='Gestrandete Meereskreatur'
G[1175227]='Gestrandete Meereskreatur'
G[1175230]='Gestrandete Meereskreatur'
G[1175233]='Gestrandete Meereskreatur'
G[1175524]='Geheimnisvoller roter Kristall'
G[1175704]='Angesengter Brief'
G[1175894]='Janices Paket'
G[1175925]='Plumpsklo'
G[1176190]='Gestrandete Meeresschildkröte'
G[1176191]='Gestrandete Meeresschildkröte'
G[1176196]='Gestrandete Meeresschildkröte'
G[1176197]='Gestrandete Meeresschildkröte'
G[1176198]='Gestrandete Meeresschildkröte'
G[1176361]='Geißelkessel'
G[1176392]='Geißelkessel'
G[1176393]='Geißelkessel'
G[1177289]='Geißelkessel'
G[1177491]='Termitenfass'
G[1177786]='Rackmores Truhe'
G[1177787]='Rackmores Logbuch'
G[1179485]='Beschädigte Falle'
G[1180024]='[Mysterious Deadmines Chest]'
G[1180025]='Geheimnisvoller Heuhaufen des Osttals'
G[1180055]='Geheimnisvolle Schatztruhe aus den Höhlen des Wehklagens'
G[1180056]='Geheimnisvoller Baumstumpf'
G[1180570]='Bierfässchen'
G[1180633]='Kristallträne'
G[1180715]='Tannenzweigkonservierer'
G[1180743]='Sorgfältig verpacktes Geschenk'
G[1180746]='Leicht geschütteltes Geschenk'
G[1180747]='Fröhlich verpacktes Geschenk'
G[1180748]='Tickendes Geschenk'
G[1180793]='Festtagsgeschenk'
G[1181073]='Duftender Kessel'
end

--	End of localized NPC names
