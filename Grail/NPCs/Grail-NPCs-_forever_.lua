--
--	Grail NPCs
--	Written by scott@mithrandir.com
--
--	UTF-8 file
--

if not Grail.usesForeverQuests then return end

local _, release, _, interface = GetBuildInfo()
release = tonumber(release)
interface = tonumber(interface)

Grail_NPCs_File_Version = 001

if Grail.npcsVersionNumber >= Grail_NPCs_File_Version then return end
Grail.npcsVersionNumber = Grail_NPCs_File_Version

Grail.npcs = {}

local G = Grail.npcs

-- No Forever NPC data has been captured yet.  This file exists so Forever
-- has its own NPC database, kept separate from Modern and Classic, ready
-- to receive codes as they're discovered during play.  See the code legend
-- in Grail-NPCs-_classic_.lua for the NPC code format.

if release >= 0 then
G[1992]={'1438:57.72,45.09'}
G[2077]={'1438:59.92,42.48'}
G[2078]={'1438:55.95,57.29'}
G[2079]={'1438:58.70,44.26'}
G[2081]={'1438:56.00,59.52'}
G[2082]={'1438:57.81,41.66'}
G[2083]={'1438:56.08,57.72'}
G[2151]={'1438:55.65,58.38'}
G[3514]={'1438:59.07,39.44'}
G[3515]={'1438:56.14,61.71'}
G[3567]={'1438:55.57,56.95'}
G[3595]={'1438:59.18,40.45'}
G[3596]={'1438:58.66,40.45'}
G[3600]={'1438:55.56,56.75'}
G[3608]={'1438:55.51,57.15'}
G[6736]={'1438:55.62,59.79'}
G[6780]={'1438:61.16,47.63'}
G[8583]={'1438:60.90,41.97'}
G[8584]={'1438:54.59,32.99'}
G[249363]={'2521:47.29,21.89'}
G[251361]={'2521:42.06,23.49'}
G[251362]={'2521:42.83,23.39'}
G[251363]={'2521:43.37,23.99'}
G[251368]={'2521:43.42,24.78'}
G[251371]={'2521:43.33,24.92'}
G[251373]={'2521:41.66,23.33'}
G[251487]={'2521:42.61,24.39'}
G[257554]={'2521:43.79,24.05'}
G[263113]={'2521:43.64,24.04'}
G[265811]={'1438:57.57,56.64'}
G[1654846]={'1438:59.08,39.53'}
end

-- End of NPCs
