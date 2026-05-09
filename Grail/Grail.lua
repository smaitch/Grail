--
--	Grail
--	Written by scott@mithrandir.com
--
--	Version History
--		001	Initial version.
--		002	Converted to using a hooked function to register completed quests.
--			Made it so quests that never appear in the quest log can be marked completed assuming the quest data is up to date.
--			Condensed the debug statements.
--			Changed the architecture so extra information can be returned for failure conditions.
--			Switched ProfessionExceeds to be able to use localized names of professions.
--		003	Made it so Darkmoon Faire NPCs return the location based on where the Darkmoon Faire currently is.
--			Removed the QUEST_AUTOCOMPLETE event handling since it seems to be unneeded.
--			Added specialZones which allow mapping of GetZoneText() to things we prefer.
--			Removed the check for IsDaily() and IsWeekly() from the Status routine since they are marked as non-complete when reset happens.
--			Added IsYearly() because there are holiday quests that can be completed only once.
--			Resettable quests (daily/weekly/yearly) are now recorded specially so quests can be queried as to whether they have ever been completed using HasQuestEverBeenCompleted().
--			Added a notification system for accepting and completing quests.
--			Added API to get quests that are available during an event (holiday).
--		004	Corrected a problem where resettable quests could not be saved for initial use.
--			Augmented level checking to maximum level is checked as well.
--			Added a targetLevel parameter to filtering quests.
--			Made it so "Near" NPCs can have a specific zone associated with them which makes their return location table entry have the zone name and the word "Near".
--			Removed the need for specialZones since GetRealZoneText() does what we need.  Switched the use of GetZoneText() to GetRealZoneText().
--			ProfessionExceeds() now returns success and skill level, where skill level can be Grail.NO_SKILL if the player does not have that skill at all.
--			LocationNPC() now has more parameters to refine the locations returned.
--			LocationQuest() now makes use of LocationNPC() changes and can return the NPC name as well.
--		005	Quest titles that do not match our internal database are recorded, which helpfully gives us localizations as well.
--			Made it so repeatable quests are also recorded in the resettable quests list.
--			Did a little optimization by declaring some LUA functions local.
--			Made some quest traversal routines take an optional argument to force garbage collection, which greatly increases the time to return the desired data, but brings the footprint back down.
--			Added a routine to get the riding skill level.
--			Made it so QueryQuestsCompleted() is called at startup because the earlier assumption did not take into account that there was still another add-on that did it.
--			Made it so we call QueryQuestsCompleted() if GetQuestResetTime() indicates that quests have been reset.  LIMITATION: The check that triggers this only happens upon accepting or completing a quest.
--			Corrected a problem in ProfessionExceeds() where the comparison was incorrect.  Also made sure the skill exists before API is called.  Changed the value of Grail.NO_SKILL.
--			IsNPCAvailable() now can work with heroic NPCs in their instances.
--		006	Corrected a problem where the questResetTime variable was misspelled.
--			Made it so the SpecialQuests are cleaned out of the GrailDatabase properly.
--			Switched City of Ironforge to Ironforge to match GetRealZoneText() return value.
--			Added a table that contains the quests per zone to allow QuestsInZone() to return the cached information immediately.
--			Made it so a callback can be registered for quest abandoning.
--		007	Corrected a problem where a mismatch in title would cause a LUA error when attempting to record bad quest data.
--			Made it so the GrailDatabase gets its NewQuests and NewNPCs cleaned out properly.
--			Added a QuestName function so the name can be gotten without need for internal data structure knowledge.
--			Added Quest and NPC localizations for French, German, Russian and Spanish.
--		008	Changed hooking quest completing to actually get the current script associated instead of the global name for the script.
--			Corrected some problems where LUA errors would occur if the internal database did not know about a quest.
--			Added support for a quest to have a prerequisite quest in the quest log and not complete.
--			Added support for automatic quests to indicate the NPC that needs to be killed to initiate quest acceptance.
--			Added support for automatic quests that are obtained from entering a zone.
--			Added a zoneMapping table that maps zone IDs returned by GetCurrentMapAreaID() to those used internally.
--			Made it so Status can ignore prerequisite requirements of a quest.
--			Made LocationQuest also return the NPC ID as well as the other information it returns.
--			Restructured the posting of the abandon notification to be about 0.75 seconds after the button click because it seems the quest log does not actually remove it immediately.
--			Added capability to handle indirect items where another NPC drops the one that starts the quest.  The NPC name returned is an NPC that drops the item followed by the item name in parentheses.
--		009	Added more mappings from GetCurrentMapAreaID().
--			Corrected a problem where some parameter names in Status() were not the same as in the implementation, thereby ignoring their values.
--			Added a QuestLevel() function.
--			MeetsRequirementLevel() now returns the levels used to determine success.
--			Added some quest interrogation routines IsEscort(), IsDungeon(), IsRaid(), IsPVP(), IsGroup() and IsHeroic().
--			Added a QuestsInMap() function that uses a map ID.
--			Added a convenience function SingleMapLocationQuest().
--		010	Added an NPCName() function.
--			Added an IsTooltipNPC() which indicates what type of NPC we are dealing with for those that modify tooltips.
--			Added an AvailableBreadcrumbs() which returns breadcrumb quests available to be gotten for the specified quest.
--		011	Corrected an issue where ensuring all prerequisite quests were confirmed could have been inaccurate.
--			Added AncestorStatus() and made Status() call it so prerequisite quests are checked to ensure they can be completed otherwise the Status will be false.  For example, this makes
--			an entire quest chain unavailable if the race does not permit the first quest to be accepted.
--			Debugging has now been turned off by default.
--			A new feature called tracking has been provided to keep a little history of basic quest activity, but is off by default.
--			Changed the posting of abandon notifications to be about 1.0 seconds after the button click since there were times when 0.75 seconds was not enough, and made it a variable.
--			Added some clearing out of BadQuestData that has been added to the database.
--			Made clearing out of NewQuest data more robust.
--			Changed to have NPC locations use map area IDs.
--			Removed the zoneMapping and zones tables as part of the move to using map area IDs for all locations.
--			Made the quest index per map area computed at runtime for the latest most accurate data.
--		012	Made it so marking a quest complete only does so if the quest is not already complete.  This is just a precaution to handle an edge case.
--			Added the "/grail backup" and "/grail compare" commands to help find quest IDs for quests that do not enter the quest log.
--			Made it so special quests that never appear in the quest log can be recorded as complete when there is more than one quest with the same name as long as the NPC ID is different.
--			Made it so NPC locations return the dungeon level and the alias map ID.
--			Added a lot of quest/NPC information for the Midsummer Fire Festival.
--		013	Updated quests and NPCs for Firelands.
--			Did a bunch of localization.
--		014	Corrected some localization issues.
--			Updates quests and NPCs for Mount Hyjal and Firelands.
--			Corrected quest prerequisite information to remove cycles to make a DAG.
--			Added AncestorQuests() which returns a complicated table structure of prerequisite quests.
--		015	Made low level comparisons use Blizzard's own routine so grey quests appear properly.
--			Added more quest level information.
--			Updates to quests/NPCs for Firelands, Alliance Grizzly Hills, and Kezan.
--			Added processing to have holiday quests stored in their own map areas (besides where the quest givers are) so they can be viewed as a group.
--			Added the ability to handle PH: prerequisites that require a quest to have been completed sometime in the past (used with dailies that are triggers).
--			Added the ability to handle Xc codes which exclude classes (basically the opposite of Cc codes).
--		016	Updates to quests/NPCs for Gilneas, and Durotar.
--			Corrected a problem in MultipleUniqueMapLocationQuest() where the accept or turn in parameter was not being passed along properly.
--		017	Updated quest and NPC data to minimize problems with stack overflows, etc.
--			Made it so questgiver locations with NearXXX codes are ignored like Near.
--			Made it so AncestorStatus is now passed the same ignore flags as Status so any subsequent calls to Status will get passed them as well.
--			Added tables for the five continents' dungeons.
--		018	Set up basic structures to start support for ptBR localization when Brazilian version comes on line.
--			Updated a large number of localizations for quest names.
--			Updates to some Firelands quest/NPC information, as well as Zul'Drak, Tirisfal Glades, Redridge Mountains, Duskwood and Northern Stranglethorn.
--			Implemented support for Sx quest codes which are the logical opposite of Rx codes.
--			Corrected the implementation of Xx codes.
--			Made it so a nil value we sometimes get will no longer crash, but output something helpful.
--		019	Added support for PC: quest codes.
--			Updated some Alliance quest information for Northern Stranglethorn, Cape of Stranglethorn, Dustwallow Marsh, Dun Morogh, Loch Modan, Wetlands, Arathi Highlands, The Hinterlands, Western Plaguelands, Badlands, Searing Gorge, Burning Steppes, Swamp of Sorrows, Darkshore, Teldrassil, Hillsbrad Foothills, Azuremyst, Bloodmyst Isle, Zul'Drak and the capital cities.
--			Updated some quest information for Mulgore, Tirisfal Glades and Silverpine Forest.
--			Made it so AvailableBreadcrumbs() will return breadcrumbs that have prerequisites that can be fulfilled as well as ones that are currently available.
--			K codes for cooking, fishing, and Brewfest quests have been changed to level 0 to indicate the actual level is the same as the player accepting the quest.
--			The zone-specific Self NPCs are now automatically generated for each zone.
--			Changed Status() to return a "Level" failure last of all the checks.
--			Corrected a probem where DEATHKNIGHT was not properly used as the class type.
--			Made it so there is a "map area" that contains all the daily quests.
--			Made "map areas" to contain each of the quests only available to specific classes.
--			Made "map areas" to contain each of the quests only available to specific professions.
--			Made "map areas" to contain each of the quests only available to those with specific reputations with factions.
--			Added support for OAC: quest codes.
--			Added a StatusCode() routine that returns a bitmask of quest status.
--		020	Updates some quest/NPC information for Durotar, Desolace, Southern Barrens, Ironforge, Stonetalon Mountains, Eversong Woods, Eastern Plaguelands, Badlands, Zul'Drak and Ashenvale.
--			Added more support for StatusCode() to support some more bit values plus values from prerequisites.
--			When using StatusCode() quest status values are cached to avoid recomputing values.  The cached values are invalidated as appropriate based on environment and the values of the status.
--			Made IsLowLevel() never consider quests whose level is 0 as low-level since those quests' levels change to match the player level.
--			Removed the Ahn'Qiraj War Effort from the list of world events.
--			Marked Status() as deprecated API which will be removed in the future.
--			Changed the method by which abandoned quests have their notifications posted so the variable abandonedQuestId no longer exists.
--			Added support for LoremasterMapArea() API which provides the map area of the Loremaster achievement for which the quest qualifies.  Also added Grail.loremasterQuests[mapAreaId] tables which list the quests that are used for each Loremaster achievement.
--		021	Updates some quest/NPC information for Feralas, Northern Stranglethorn, Un'Goro Crater, Stormwind City, Ghostlands, Silvermoon City and Cape of Stranglethorn.
--			Updates quest/NPC information for Hallow's End and Day of the Dead.
--			Created caching structure for accessing some quest information to help reduce runtime footprint and increase speed.
--			Added support for OCC:, PLT: and PCT: quest codes.
--			Made QuestsInMap() able to return only quests that qualify for Loremaster.
--			Removed a number of debug slash commands and the functions that were supporting them.
--			Added the CreateRaceNameLocalizedGenderized() routine so race names can be displayed nicely.
--			Removed AncestorStatus(), QuestsWithCode() and Status() and some support routines.
--		022	Updates some quest/NPC information for Mugore, Thunder Bluff, Silverpine Forest, Durotar, Bloodmyst Isle and Azshara.
--			Updates quest/NPC information for Pilgrim's Bounty.
--			Corrected the Gnomeregan reputation name to not include Exiles.
--			Started recording found defects in a new format.
--			Created a system to record when reputation changes do not match what the internal database has.
--			Added the achievement information where quests are associated with specific achievements.
--			Updated the TOC to support Interface 40300.
--		023	Corrects the detection of the Mr Popularity guild perks.
--			Updates some quest/NPC information for Darkmoon Faire, Azshara, Elwynn Forest, class-specific ones and the Bwemba's Spirit line.
--			Adds the missing reputation names to the non-English clients (whose lack was causing addons that use reputation to fail).
--			Updates a lot of Portuguese data.
--			Fixes a problem where unknown quests were not being recorded correctly, causing a LUA error.
--			Fixes a problem where event handlers were not installed properly because Blizzard events cannot arrive in a guaranteed order.
--			Fixes a problem where AZ codes were not being processed properly, thereby resulting in quests with those codes to appear in the current map area instead of their proper one.
--			Fixes a problem where the new Darkmoon Faire quests would not be available on Darkmoon Island unless the UI was reloaded.
--		024	Updates some quest/NPC information for Azshara, Ashenvale, Stonetalon Mountains, Southern Barrens, Dalaran, Shattrath City and some dungeons.
--			Updates some Portuguese localizations.
--			Updates the CleanDatabase() routine to do more cleaning.
--			Makes it so slash commands are not forced to lower case.
--			Changes the way StatusCode() works to not mark a quest complete if it does not meet race, class, gender and/or faction requirements.  This is to work around Blizzard behavior where the server marks quests complete that could not possibly be done by a player.
--			Changes the way StatusCode() works to not mark level problems or invalidation problems with quests that are marked complete.
--			Fixes a problem where CleanDatabase() could attempt to access data that does not exist.
--			Fixes an infinite loop that is sometimes encountered using Blizzard's GetFactionInfo(), found by ArcaneTourist.
--		025	Updates some quest/NPC information for Southern Barrens, Durotar, Northern Barrens, Desolace and Dustwallow Marsh.
--			Adds a Christmas Week holiday that handles the quests in Winter Veil that only start appearing on Christmas Day.
--			Adds a feature to record NPC names that do not match those in the database.
--			Updates some Portuguese localizations.
--			Updates some other localizations, for Winter Veil.
--		026	Updates some quest/NPC information for Desolace, Azuremyst Isle, The Exodar, Azshara, Hillsbrad Foothills and Feralas.
--			Cleans up some Blizzard event handling, and moved some event handling Wholly was doing into here because it is the right place for them.
--			Updates some Portuguese localizations.
--			Fixes a problem where a LUA error was being thrown when invalidating part of the status cache when evaluating a quest status.
--			Adds support for world events achievements.
--		027	Updates some quest/NPC information for Feralas, Northern Barrens, Thousand Needles, Tanaris, Zul'Drak, Sholazar Basin, Storm Peaks, some dungeons and Uldum.
--			Updates some quest/NPC information for the Lunar Festival.
--			Updates some Portuguese localizations.
--		028	*** Will not work with Wholly 15 or older ***
--			Corrects the mapAreaMaximumReputationChange constant.
--			Revamps the location providing routines so only the new QuestLocations() and NPCLocations() are needed, REMOVING the older ones. 
--			Updates some quest/NPC information for Un'Goro Crater, Silithus, Burning Steppes, Kezan, The Lost Isles, Northern Barrens, Ashenvale, some dungeons and Winterspring.
--			Fixes detection of European servers to remove non-existent quests.
--			Updates some Portuguese localizations.
--			Makes _CleanDatabase() a little more intense with its cleaning.
--			Makes the system than checks for reputation gains a little more accurate.
--			Records actual quest completion for those quests that Blizzard marks complete with others in the server, so clients can know really which quest was done.
--			Implements a way to know when Blizzard uses internal marking mechanics (which differ from flag quests) to specify when quests are available.
--			Adds an architecture to support information about quests that are bugged.
--		029 *** Will not work with Wholly 16 or older ***
--			Splits out two load on demand addons to handle achievements and reputation gains.
--			Updates some quest/NPC information for the Lost Isles, Feralas and some dungeons.
--			Updates some localizations, primarily Portuguese, Korean and Simplified Chinese.
--			Corrects the problem where some daily quests that also have another aspect (e.g., PVP or dungeon) were not being shown as daily quests.
--			Updates the automatic quest level verification system to ensure quests that are considered to have a dynamic level actually do.
--          Adds basic structural support for the Italian localization.
--			Consolidates the internal use of prerequisite quest types into a unified technique, causing all QuestPrerequisite* API to be REMOVED other than QuestPrerequisites.
--			Fixes the problem where quests with AZ codes were not being added to the proper zone.
--			Fixes the problem where the status of quests that require other quests being in the quest log was not being displayed properly.
--			Adds the Kalu'ak Fishing Derby holiday.
--			Updates some quest/NPC information for the fishing contests.
--		030	Corrects a problem that manifests itself when running the ElvUI addon.
--		031	Corrects the internal checking of reputation gains to not include modifications when the reputation is lost.
--			Adds the verifynpcs slash command option.
--			Updates some localizations, primarily Portuguese and Korean.
--			Updates some quest/NPC information for Dun Morogh, Loch Modan, Wetlands, Vash'jir and Kelp'thar Forest.
--			Corrects the problem where quests with breadcrumbs were being marked as not complete after a reload.
--			Adds processing to startup to ensure Grail attempts to get the server quest status automatically.
--			Corrects AncestorStatusCode() to ignore non-quest prerequisites.
--			Adds the ability to have quests have items or lack of items as prerequisites.
--			Adds support for ODC: quest codes, which are used to mark other quests complete when a quest is turned in.
--			Adds the ability to have quests use the abandoned state of quests as prerequisites.
--		032	Adds some German translation from polzi.
--			Augments CanAcceptQuest() to include a parameter to ignore holiday requirements.
--			Updates some quest/NPC information for some dungeons, Oracles/Frenzyheart, Worgen starting areas, Tol Barad and others.
--			Changes the comparisons to completed quests to be more mathematically robust.
--			Corrects a problem where cleaning the database can cause a LUA error.
--		033	Updates some quest/NPC information for Blasted Lands, Eastern Plaguelands, Tirisfal Glades, Undercity, Winterspring, Zul'Aman and professions.
--			Adds some Spanish translation from Trisquite.
--			Changes the implementation of _ReputationExceeds() to use GetFactionInfoByID() instead of GetFactionInfo() since it seems there are times when the latter does not return proper values at startup.
--		034	Updates some quest/NPC information for Wandering Isle.
--			Creates new Grail.reputationExpansionMapping table to replace the original four tables which are deprecated and will be removed in version 035.
--			Updates Midsummer Fire Festival quest/NPC data, primarily the Portuguese localization.
--		035	Updates Midsummer Fire Festival localization for Korean, Spanish and German.
--			Updates more NPC/quest localizations.
--			Updates the quest recording subsystem to generate basic K codes.
--			Changes the reputation system to no longer use indirection, but Blizzard faction IDs.
--			Updates the quest recording subsystem to record faction rewards on quest acceptance, and turns off recording faction rewards when quests are turned in.
--			Corrects the problem where quests that start automatically when entering a zone can appear improperly in the current zone (based on the current zone name).
--			Changes the technique by which the server is queried for completed quests since API has been changed for MoP.
--			Updates some quest/NPC information for Valley of the Four Winds and Krasarang Wilds.
--			Makes it so B codes are automatically generated from the quests with O codes, so the vast majority of B codes need not be present in the data file.
--			Adds the ability to create profession prerequisite codes (vice the normally supported profession requirements).
--		036	Fixes the problem where accepting and abandoning a quest with a breadcrumb was not setting the breadcrumb status properly.
--			Fixes the problem where quests could be considered to fail prerequisites if the only prerequisites were quests requiring presence in the quest log.
--			Updates some quest/NPC information for MoP beta, including Night Elf and Draenei starter zones.
--			Updates quest information to allow marking quests Scenario and Legendary.
--			Removes Grail.bitMaskQuestNonLevel as the internal data structures have changed, no longer requiring this.
--			Adds HasQuestEverBeenAccepted() to be able to handle O type prerequisites.
--			Removes Grail.reputationBlizzardMapping since it is no longer needed because of the use of Blizzard faction IDs.
--		037	Updates some quest/NPC information for Twilight Highlands, Deepholm, Uldum, Sholazar Basin and Mount Hyjal.
--			Adds DisplayableQuestPrerequisites() so flag quests can be bypassed, showing their requirements instead.
--			Adds some Italian localization.
--			Adds support for account-wide quests.
--		038	Adds some Italian localization and quest localization updates for release 16030.
--			Updates some quest/NPC information for Jade Forest, Northern Stranglethorn, Vale of Eternal Blossoms and Echo Isles.
--			Adds ability for a quest to have prerequisites of a general skill, used by battle pets for example.
--			Refines meeting prerequisites when part of the requirements includes possessing an item.
--		039	Updates some quest/NPC information for Vale of Eternal Blossoms, Kun-Lai Summit, Borean Tundra, Dread Wastes and Valley of the Four Winds.
--			Adds support for prerequisites to be able to have OR requirements within an AND requirement, instead of just outside them.
--			Adds support for CanAcceptQuest() to not allow bugged quests to be acceptable.
--			Replaces the raceMapping, raceNameFemaleMapping, raceNameMapping and raceToBitMapping tables with races.  These older ones will be removed in version 40.
--		040	Updates some quest/NPC information for Howling Fjord, Jade Forest, Krasarang Wilds, Townlong Steppes, Valley of the Four Winds, Kun-Lai Summit and Vale of Eternal Blossoms.
--			Removes the raceMapping, raceNameFemaleMapping, raceNameMapping and raceToBitMapping tables.
--			Changes the format for reputation change logging.
--			Adds reputationLevelMapping table that Wholly was using because it will be changed as more information is known, and there should be no need for Wholly to need to change.
--		041	Adds support for quests having prerequisites of having ever experienced a buff.
--			Changes the internal representation of NPC information to separate the NPC names to make the data more "normal".
--			Augments the way the reputationLevelMapping table provides information so it can provide specific numeric values over the minimum reputation.
--			Adds the ability to have quests grouped so able to invalidate groups based on daily counts, or make prerequisites of a number of quests from a group.
--			Updates some quest/NPC information for Tillers, Golden Lotus, Order of the Cloud Serpent, Shado-Pan, August Celestials, Anglers and Klaxxi dailies.
--			Adds very basic quest information for 5.1 PTR quests from 2012-10-25.
--			Adds the ability to invalidate a quest by accepting a quest from a quest group.
--			Adds the ability for quests to have a prerequisite of a maximum reputation.
--			Adds code that abandons processing the server completed quests if the return results do not represent the total number of quests completed as compared to the locally stored count.
--		042	Corrects an initialization problem that would cause a Lua error if dailyQuests were not gotten before evaluated.
--		043	Corrects the prerequisites for the Chi-Ji champion dailies.
--			Updates the Shado-Pan dailies' NPCs.
--			Updates some quest/NPC information for Jade Forest, Kun-Lai Summit, Durotar and the dailies available in 5.1.
--			Updates the TOC to support interface 50100.
--		044	Removes the Grail-Zones.lua file since the names are now gotten from the runtime.
--			Puts in support for "/grail events" allowing control over processing of some Blizzard events received while in combat until after combat.
--			Updates some quest/NPC information for Operation: Shieldwall.
--			Removes the Grail.xml and rewrites the startup to account for its lack.
--			Adds very basic quest information for 5.2 PTR quests from 2013-01-02.
--			Removes the quests on Yojamba Isle since there are no NPCs there.
--			Updates some Netherstorm quests for Aldor/Scryers information.
--			Updates some quest localizations for Simplified Chinese.
--		045	Updates to Isle of Thunder King/Isle of Giants quests from 5.2 PTR.
--			Updates some Traditional Chinese localizations.
--			Updates some quest/NPC information.
--			Updates the technique where a quest is invalidated to properly include not being able to fulfill all prerequisites that include groups.
--			Puts quests whose start location does not map directly to a specific zone into their own "Other" map area.
--			Augments the API that returns NPC locations to include created and mailbox flags.
--		046	Updates some quest/NPC information.
--			Speeds up the CodesWithPrefix() routine provided by rowaasr13.  This reduces the chance of running into an issue when teleporting into combat.
--			Adds F code prerequisites which indicate a faction requirement.  Demonstrate this with two Work Order: quests, but will be used primarily for "phased" NPC prerequisites, whose architecture is starting to be implemented.
--			Updates some Traditional Chinese localizations.
--		047	Updates some quest/NPC information, primarily with the Isle of Thunder.
--			Adds the basics for the quests added in the 5.3.0 PTR release 16758.
--			Events in combat are forced to be delayed, but the user can still override.
--			Changes the internal design of the NPCs to save about 0.6 MB of space.
--		048	Makes it so choosing PvE or PvP for the day on Isle of Thunder is handled well.
--			Adds IsQuestObsolete() and IsQuestPending() which use the new Z and E quests codes that can be present.  If either returns true, the quest is not available in the current Blizzard client.
--			Adds support for the new way reputation information is being stored.
--			Converts prerequisite information storage to no longer use tables, saving about 1.0 MB of space.
--		049	Changes the Interface to 50300 for the 5.3.0 Blizzard release.
--			Updates some quest/NPC information, primarily with the Isle of Thunder.
--			Adds a new loadable addon, Grail-When, that records when quests are completed.
--			Adds a flag to QuestPrerequisites(), allowing the lack of flag to cause the behavior to return to what it was previously, and with the flag the newer behavior.
--		050	Corrects a problem with QuestPrerequisites() and nil data.
--		051 Adds Midsummer quests for Pandaria.
--			Updates some quest/NPC information not associated with Midsummer.
--			Changes _CleanDatabase() to better handle NPCs that have prerequisites.
--			Corrects a problem where questReputations was not initialized when reputation data was not loaded.
--			Adds the ability to have an equipped iLvl be used as a prerequisite.
--		052	Updates some quest/NPC information.
--			Adds some Wrathion achievements.
--			Moves some achievements into continents that are a little more logical.
--			Separates some achievements to give a little finer-grain control.
--			Updates some zhCN localizations.
--		053	Updates some quest/NPC information.
--			Corrects an error that would cause an infinite loop in evaluating data in Ashenvale for quest 31815, Zonya the Sadist.
--		054	Updates some quest/NPC information.
--			Incorporates prereqisite population API originally written in Wholly.
--			Fills out the Pandaria "loremaster" achievements to include all the prerequisite quests for each sub achievement quest.
--		055	Updates some quest/NPC information.
--			Fixes an infinite loop issue when evaluating data in the Valley of the Four Winds.
--			Fixes a Lua issue that manifests when Dugi guides are loaded, because Grail was incorrectly using a variable that Dugi guides leaks into the global namespace.
--			Caches the results obtained from _QuestsInLog() to make quest status updates faster, invalidating the cache as appropriate.
--			Fixes a rare error caused when cleaning the database of reputation data evident by an "unfinished capture" error message.
--			Adds the ability to treat the chests on the Timeless Isle as quests.
--			Adds the slash command "/grail loot" to control whether the LOOT_CLOSED event is monitored as that is used to handle Timeless Isle chests.
--			Makes persistent the settings for the slash commands "/grail tracking" and "/grail debug".
--			Makes CanAcceptQuest() not return true if the quest is obsolete or pending.
--		056	Updates some quest/NPC information.
--			Fixes a variable leak that causes problems determining prerequisite information.
--		057	Corrects some issues stemming from new reputation information.
--			Adds some localizations of quest/NPC names.
--		058	Augments ClassificationOfQuestCode() to return 'K' for weekly quests.
--			Updates some quest/NPC information.
--			Makes handling LOOT_CLOSED not be so noisy with chat spam.
--			Makes processing the UNIT_QUEST_LOG_CHANGED event delayed by 0.5 seconds to allow walking through the Blizzard quest log using GetQuestLogTitle() to work better.
--		059	Caches the results obtained from ItemPresent() to make quest status updates faster, invalidating the cache as appropriate.
--			Updates some quest/NPC information.
--			Changes the NPC IDs used to represent spells that summon pets to remove a conflict with actual items.
--			Changes some of the internal structures used to save some memory.
--			Corrects an issue where the Loremaster quest data for Pandaria was not populating an internal structure properly (causing Loremaster not to display map pins).
--			Updates _QuestsInLog() to work better when various headings are closed in the Blizzard quest log.
--		060	Updates some quest/NPC information.
--			Updates the issue recording system to provide a little more accurate information to make processing saved variables files easier.
--		061 Updates some quest/NPC information.
--			Added the ability for prerequisite evaluation to only check profession requirements.
--			Corrected the evaluation of ancestor failures to properly propagate past the first level of quest failure.
--		062	Corrected a problem where quests with First Aid prerequisites would cause a Lua error.
--		063	Updates some quest/NPC information.
--			Unified the reputation requirements into the prerequisite codes.
--			Allows A: and T: codes to work in conjuction (additive) with the faction-specific versions.
--			Allows AZ: codes to have more than one map area.
--		064 Updates some quest/NPC information.
--			Corrects prerequisite evaluation when analyzing more than one path that have different results (like Alliance vs Horde both leading to the same quest).
--			Speeds up prerequisite tree analysis.
--		065	Updates some quest/NPC information.
--			Corrects a problem where First Aid quests were not being put into their own "zone" properly.
--			Adds the ability to complete quests when gossiping with an NPC.
--			Changes internal processing of qualified NPCs to stop evaluating at the first match (allows Fiona's Caravan locations to be accurate).
--			Changes use of GetQuestLogTitle(), and a lot more Blizzard API to handle WoD changes.
--			Corrects the problem where tracking quest acceptance, abandoning and completion was not set up properly based on saved preferences.
--			Splits out NPC names into separate localized files because Blizzard can no longer handle them in one.
--			Changes the Interface to 60000.
--		066 Updates some quest/NPC information.
--			Adds function FactionAvailable() to allow users to determine whether the faction is available for the player.
--		067	Updates some quest/NPC information.
--			Adds ability to indicate a quest rewards a follower.
--		068	Updates some quest/NPC information.
--			Adds ability to handle garrison building requirements for quests.
--			Adds ability to have level requirement for quest that differs from what Blizzard marks as their quest minimum level.
--		069	Updates some quest/NPC information.
--			Adds the ability to mark quests as bonus objective, rare mob and treasure.
--			Changes the Interface to 60200.
--		070	Updates some quest/NPC information.
--		071	Updates some quest/NPC information.
--			Adds new prerequisite code 'w' for group complete/turn in.
--			Adds the ability to record quest reward information.
--		072	Updates some quest/NPC information.
--		073	Updates some quest/NPC information.
--			Fixes the issue where the wrong API MeetsRequirementControl was being used.
--		074	Updates some quest/NPC information.
--			Adds IsPetBattle() API.
--			Adds the ability to have more than one X code requirement.
--			Corrects the implementation of AchievementComplete().
--			Implements some variations on some prerequisite codes.
--		075	Updates some quest/NPC information.
--			Adds support for bodyguard levels.
--			Adds support for Adventure Guide quests using the fake NPC ID 1, also using the fake map ID 1.
--			Corrects the implementation of _PhaseMatches() to properly note Frostwall level.
--			Adds support for events and more accurate holiday starts/stops.
--		076	Updates some quest/NPC information.
--			Corrects the problem where the map location is lost on UI reload.
--		077	Updates some quest/NPC information.
--			Adds the ability to support required NPCs working in garrison buildings.
--		078	Updates some quest/NPC information, especially for Legion.
--			Corrects Legion detection since release version is inadequate with the latest update Blizzard made to WoD live.
--		079	Updates some quest/NPC information, especially for Legion.
--			Corrects use of C_Garrison.GetGarrisonInfo() for Legion as it has changed.
--			Provides for prerequisites to require a specific player class.
--			Fixes an issue where Blizzard changed the C_Garrison.GetBuildings() API not in Legion beta, but in the live release based on it.
--			Changes the Interface to 70000.
--		080	Corrects a problem where learning a quest causes an error if nothing else already learned.
--			Updates some quest/NPC information for Legion.
--		081	Updates some quest/NPC information for Legion.
--			Adds factions for Legion.
--			Fixes the problem with strsplit error that can happen when first looting.
--		082	Updates some quest/NPC information for Legion.
--			Turns reputation recording system back on as Blizzard API seems to be working properly again.
--			Splits localized quest names into loadable addons.
--		083	Updates some quest/NPC information for Legion.
--		084	Adds the ability to know when world quests are available.
--			Updates some quest/NPC information for Legion, especially world quests.
--		085	Corrects problem where map was reseting to Eye of Azshara.
--			Updates some quest/NPC information for Legion.
--		086	Updates some quest/NPC information for Legion.
--			Adds capability to know when withering is happening with NPCs.
--		087	Updates some quest/NPC information for Legion.
--			Corrects problem where GrailDatabase.learned was not being initialized before accessed.
--			Uses Blizzard's new calendar API present in 7.2.
--		088	Changes the Interface to 70200
--			Updates some quest/NPC information for Legion.
--			Adds the ability to handle artifact levels which are required for some newer quests.
--		089	Corrects problem where garrison NPC building prerequisites was causing a Lua error.
--			Updates some quest/NPC information.
--		090	Updates some quest/NPC information.
--			Supports quests requiring paragon reputations.
--			Supports the Argus continent being introduced in 7.3.
--		091	Updates some quest/NPC information.
--			Updates the Interface to 70300.
--			Adds Argus zones to treasure looting.
--		092	Updates some quest/NPC information.
--			Corrects a problem where Loremaster quests were not listed correctly when there is more than one achievement in the same zone.
--			Corrects the problem where paragon faction levels were not reported properly after more than one reward achieved.
--		093	Updates some quest/NPC information.
--			Adds the ability to have class hall missions available as prerequisites.
--			Adds support for Allied races.
--			Changes CodeObtainers() to no longer return race information, which is now returned in a similar manner with CodeObtainersRace().
--		094	Corrects the problem where BloodElf was being overritten by Nightborne.
--		095 Update some quest/NPC information, but primarily the required level of thousands of quests due to Blizzard changing them.
--		096	Updates some quest/NPC information.
--			Handles Blizzard removing GetCurrentMapDungeonLevel() and GetCurrentMapAreaID().
--			Achievements are now indexed by the continent mapID instead of a one-up number.
--			The "continent" constants are removed from Grail as they were not used internally and serve no scalable purpose.
--			Continent information now uses Blizzard's new API for maps.
--			Updates use of UnitAura() to support Blizzard's changes for Battle for Azeroth.
--			Reimplements GetMapNameByID() because Blizzard removed it for Battle for Azeroth.
--			Starts reimplementing GetPlayerMapPosition() because Blizzard removes it for Battle for Azeroth.
--			Handles Blizzard's change of calendar APIs.
--		097	Updates some quest/NPC information.
--			Removes map setting code as it is not needed.
--			Checks whether locations have x and y coordinates before comparing.
--			Checks whether Blizzard map returns are rational before asking for player coordinates.
--			Ignores checking Thunder Isle for phasing for the moment.
--		098	Updates some quest/NPC information.
--			Adds Silithus to zones for quest looting.
--			Names treasure quests based on the item looted.
--			Updates map areas for Loremaster quests.
--		099	Updates some quest/NPC information.
--			Corrects a problem where cleaning quest data could result in a Lua error.
--		100 Updates some quest/NPC information.
--			Enables support for the two latest Allied races.
--			Updates Interface in TOC to 80200.
--			Starts to add support for newly added zones.
--			Transforms GrailDatabase to use Grail.environment so _retail_ differs from _ptr_ differs from _classic_.
--			Augments the mapping system because Blizzard API is a little wonky and does not report zones like Teldrassil in Kalimdor like one would expect.
--			Adds support for quests to be marked only available during a WoW Anniversay event.
--		101	Updates some quest/NPC information.
--			Changes the code that detects group quests as Hogger in Classic returned a string vice a number.
--			Changes IsPrimed() to no longer need the calendar to be checked in Classic.
--			Forces Classic to query for completed quests at startup because calendar processing is not done (where it was done as a side effect).
--			Creates an implementation of ProfessionExceeds() that works in Classic.
--		102	Updates some quest/NPC information.
--			Adds the NPCComment() function to give access to NPC comments.
--			Fixes a Lua error associated with quests requiring garrison buildings.
--		103	Updates some quest/NPC information.
--			Removes reimplementation of GetMapNameByID().
--			Removes call to load Blizzard_ArtifactUI since ElvUI has problems.
--			Makes it so holiday codes for quests do not cause Lua errors in Classic, though still do not work as there is no Classic calendar.
--			Adds support for Mechagnome and Vulpera races.
--			Adds support for the "/grail eraseAndReloadCompletedQuests" slash command.
--		104	Updates some quest/NPC information.
--			Fixes the implementation of CurrentDateTime() because the month and day were reversed.
--			Corrects CelebratingHoliday() to behave and perform better.
--			Sets faction obtainers to account for quest giver faction.
--			Corrects IsNPCAvailable() to properly use holiday markers for NPCs.
--			Augments QuestsInMap() to allow quests in the log whose turn in is in the map to be included.
--		105	Fixes problem where AQ quests cause Lua error in non-English locales.
--			Updates some quest/NPC information.
--		106	Updates some quest/NPC information.
--			Corrects a problem where lack of quests in a zone causes a Lua issue when quests in the log turnin in that zone.
--		107	Updates some quest/NPC information.
--			Works around a problem where learned quest information could cause Lua strsplit errors.
--			Changes interface to 80300.
--			Adds support for threat quests.
--			Adds support for Heart of Azeroth level requirements.
--		108	Updates Classic Wetlands and Duskwood NPC information.
--			Updates Retail horror quest information.
--			Works around a problem learning world quests where the mapId is not defined.
--			Corrects the Classic holiday code for Midsummer Fire Festival.
--			Adds support for detecting Darkmoon Faire in Classic.
--			Works around a problem where a holiday is not known.
--			Corrects issue where CurrentDateTime() did not return weekday in Classic.
--			Adds support for phase code 0000 in Classic for Darkmoon Faire location.  See _PhaseMatches() comments for specifics.
--			Updates some Retail quest information.
--			Corrects a Lua issue with localized French Classic quest names.
--			Adds protection to ensure processing of NPCs does not occur if NPCs are not loaded.
--			Adds protection to ensure loremaster quests can be handled if addons load out of order.
--			Adds protection to ensure C_Reputation is not accessed on Classic.
--			Corrects an improper prerequisite associated with the Classic quest "Filling the Soul Gem".
--			Adds more Classic holiday quests and NPCs.
--		109	Updates some Classic NPC information.
--			Works around a problem in Retail where world quests can appear in Blizzard's API in different zones.
--			Corrects the determination of Darkmoon Faire in Classic.
--			Changes quest level storage and processing.
--			Optimizes NPC location processing to cache values.
--		110	Corrects checking a prerequisite code for level "less than".
--			Updates GetPlayerMapPosition() to handle when UnitPosition() returns nils.
--			Delays NPC name lookup from startup.
--		111 Updates some Quest/NPC information.
--			Adds basic support for Shadowlands beta P:58619.
--			Changes the way treasures are looted to hopefully be faster.
--			Changes interface to 90001.
--		112	Updates from Quest/NPC information.
--			Redefines LE_GARRISON_TYPE_6_0 because Blizzard removed it.
--			Adds slash command "/grail treasures" which toggles the old method of LOOT_CLOSED to record information when looting.
--			Adds GetCurrencyInfo() which works around issues for which Blizzard API to use.
--			Ensures AzeriteLevelMeetsOrExceeds() checks to make sure API used are present.
--			Reworks quest abandoning to use events instead of the old routines.
--		113 Updates some Quest/NPC information.
--			Fixes the problem where unregistering tracking quest acceptance was not being done properly.
--			Changes technique of obtaining NPC location to use internal routine rather than Blizzard's which does not show locations in instances.
--			Changes interface to 90002.
--		114	Changes the Orgrimmar NPCs to use the proper map ID.
--			Updates quest levels based on Blizzard's new system.
--			Update GetPlayerMapPosition() to accept an optional map ID and has Coordinates() use it.
--			Enables prerequisite quest determination for non-Loremaster achievements.
--			Updates Quest/NPC information.
--			Adds basic support for covenant renown level prerequisites.
--			Adds support to mark quests as callings quests.
--			Adds the ability to set covenant talent prerequisites.
--			Adds the ability to have prerequisites for quests turned in prior to the previous weekly reset.
--			Adds GetBasicAchievementInfo() that acts as a front for Blizzard's GetAchievementInfo() albeit with limited return values, but also provides information about achievements for which Blizzard's API returns nil.
--		115 Updates some Quest/NPC information.
--			Removes redefinition of LE_GARRISON_TYPE_6_0 and uses Enum.GarrisonType.Type_6_0 instead.
--			Adds the ability to have groups of weekly quests behave like groups of daily quests.
--			Changes zone names to include floors if map is part of a group, and not to duplicate entries if possible.  Maps with the same name as another map will get a mapId added to it.
--			Adds color to debug statements for quests marked completed when others completed or accepted.
--			Changes IsLowLevel to now use the maximum variable level for a quest in its computation.  Changes QuestLevelString to include a range if there is a maximum variable level for the quest.
--			Changes interface to 90005.
--			Changes check for renown level to ensure covenant matches as Blizzard renown API ignores covenant.
--			Starts to add support for Classic Burning Crusade (using interface 20501).
--		116	Switches to a unified addon for all of Blizzard's releases.
--			Augments _CovenantRenownMeetsOrExceeds to accept covenant 0 to represent the currrently active covenant, used to indicate that the renown level is at a specific level independent of covenant.
--			Changes retail interface to 90100.
--		117 Updates some Quest/NPC information.
--			Updates some Ve'nari localized reputation levels.
--			Changes retail interface to 90105, BCC to 20502 and Classic to 11400.
--      118 Changes retail interface to 90205, BCC to 20504 and Classic to 11402.
--          Updates some Quest/NPC information.
--          Adds factions for Zereth Mortis (9.2 release).
--			Adds support for quests that only become available after the next daily reset.
--			Adds support for quests that only become available when currency requirements are met.
--		119 Adds support for Classic Wrath of the Lich King.
--			Changes retail interface to 100002, Wrath to 30400 and Vanilla to 11403.
--			Switched to using C_GossipInfo.GetFriendshipReputation instead of GetFriendshipReputation.
--			Adds support for Evoker class.
--			Adds support for Dracthyr race.
--			Adds missing race localizations.
--			Switched to using C_Container routines.
--		120	Corrects the problem where NPC tooltips did not show items dropped that start quests.
--			Updates some Quest/NPC information.
--			Adds support for major faction renown level prerequisites.
--			Implemented GetContainerItemInfo to return the values the old API did.
--			Adds support for POI presence prerequisites.
--			Adds support for items with specific counts as prerequisites.
--			Changes retail interface to 100005.
--			Adds support group membership completion counts being exact (to support Dragon Isles Waygate quests).
--		121 Changes Classic Wrath interface to 30401.
--			Corrects problem where attempting to use modern achievement name in Classic causes crash.
--		122	Updates some Quest/NPC information.
--			Adds better support for The Ruby Feast quests.
--			Adds better support for quest 70779.
--			Changed retail interface to 100007.
--		123 Adds initial support for The War Within.
--			Switches TOC to have a single Interface that lists all supported versions.
--			Changes the use of localized names to no longer be addons but to be included in the base Grail addon.
--		124 Adds IsQuestFlaggedCompletedOnAccount to help indicate when a quest is completed by the warband.
--		125	Adds faction data for The War Within and Midnight.
--			Adds additional zones to the treasure looting detection system for Wrath of the Lich King, Legion, and The War Within content.
--			Changes the way zones are initialized to allow continents that contain other continents to work properly.
--			Corrects UnitAura to use the modern Blizzard API correctly in retail and the original API properly in Classic.
--			Makes UNIT_AURA processing skip redundant work when no auras have actually changed since the last update.
--			Adds recording of quest faction reputation changes from faction change chat messages for modern expansions.
--			Automatically removes already-integrated reputation data from the saved variables file on load.
--			Adds handling of the CRITERIA_COMPLETE event to track criterion completions.
--			Adds handling of the ITEM_TEXT_BEGIN event to track book reads in zones such as Eversong Woods.
--			Improves ITEM_TEXT_READY tracking to record target name, NPC ID, and coordinates.
--			Improves looting tracking to record coordinates in the looting message.
--			Adds support for a ? prefix on integer quest IDs in P: prerequisite codes to indicate an unverified prerequisite.
--			Adds a verifyWatchedBy reverse-lookup so any quest can find the quests that list it as a prerequisite.
--			Corrects some issues that would cause taint.
--			Adds a startup message encouraging players to enable tracking and submit data.
--			Updates some Quest/NPC information.
--
--	Known Issues
--
--			The use of GetQuestResetTime() is not adequate, nor is the API good enough to provide us accurate information for weeklies (and possibly yearlies depending on when they actually reset compared to dailies).
--				The check is only made when a quest is accepted or completed, and this means the reset could happen during play and the Blizzard-provided data would be out of date until a restart or one of our
--				monitored events occurs.  This is the price one pays for not using something like OnUpdate.
--			Support for Neutral faction for starting Pandarens does not exist as it need not.  Quests are marked with a racial requirement, and the system
--				should handle the situation when the Pandaren chooses the desired faction.
--
--			Update the "BadQuestData" data recording/cleaning to handle the rest of the failure possibilities.
--			Need to make it so special quests with the same name AND same NPC ID can be handled.  For the Consortium gem quests I believe we will have to check the levels of the Consortium rep to know how to distinguish.
--			Need a time detection system because we need to know when we cross boundaries for things like the fishing holidays so we can turn the quests on or off appropriately.  This will also allow us to handle other time-based quests.  It means we will most likely use OnUpdate and the above comment will go away and we can actually put in a timer for the next quest reset time so we know when dailies reset.  Of course this means we may want to study the calendar to know when an upcoming event boundary will be crossed as well other than fishing (like Darkmoon Faire, etc.).
--			Need to be able to set Grail.playerFactionBitMask for a Pandaren if they start out playing before they select a faction, and then select a faction during play.  Otherwise they will be defaulted to Alliance which could prove problematic.
--
--			Determine if it is possible to notice when a faction is marked "at war" by the user so reputation checks against it take that into account because when one is "at war" the NPCs will not give the quests as expected.  If we can note whether at war then we need to mark NPCs as being associated with a specific faction.  If the NPC has a faction then we can check whether at war (or a low enough reputation with the faction).  Added _NPCFaction() to handle getting the data assuming we have it.
--
--			Finish the transition to supporting | with the last known routine for skipping over J codes properly.
--
--	UTF-8 file
--

--	Make local references to things in the global namespace to speed things up
local tinsert, tContains, tremove = tinsert, tContains, tremove
local strsplit, strfind, strformat, strsub, strlen, strgsub, strtrim, strgmatch = strsplit, string.find, string.format, string.sub, strlen, string.gsub, strtrim, string.gmatch
local strchar, strbyte = string.char, string.byte
local pairs, next = pairs, next
local tonumber, tostring = tonumber, tostring
local type = type
local print = print
local bitband, bitbnot, bitrshift, bitbxor, bitbor = bit.band, bit.bnot, bit.rshift, bit.bxor, bit.bor
local assert, wipe = assert, wipe
local floor, mod = math.floor, mod


-- BEGIN Grail_SafeGetAuraDataByIndex wrapper
-- Safe wrapper that skips secret aura indices and logs (only when Grail debug is ON)
local function Grail_SafeGetAuraDataByIndex(unit, index, filter)
    -- Check for secret aura indices using Blizzard's secrecy API (Retail/TWW)
    if C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret then
        local ok, secret = pcall(C_Secrets.ShouldUnitAuraIndexBeSecret, unit, index, filter)
        if not ok or secret then
            -- Skip if secret confirmed OR if the secrecy check itself threw (can't safely read this index)
            return nil
        end
    end
    -- Fallback to Blizzard API when available
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local info = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        return info
    end
    return nil
end
-- END Grail_SafeGetAuraDataByIndex wrapper

-- Returns the first left-text line for a hyperlink, or nil.
-- On retail/TWW uses C_TooltipInfo.GetHyperlink to avoid rendering a tooltip frame
-- and tainting the UIWidgetManager pool.  On Classic falls back to rendering into a
-- hidden private tooltip frame.
local function _GetHyperlinkName(hyperlink, frame, globalTextName)
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local data = C_TooltipInfo.GetHyperlink(hyperlink)
        if data and data.lines and data.lines[1] then
            return data.lines[1].leftText
        end
        -- C_TooltipInfo returned no data (e.g. unit:Creature hyperlinks for NPCs not
        -- in the local cache are not supported).  Fall through to the tooltip frame path.
    end
    if not frame:IsOwned(UIParent) then frame:SetOwner(UIParent, "ANCHOR_NONE") end
    frame:ClearLines()
    frame:SetHyperlink(hyperlink)
    if (frame:NumLines() or 0) ~= 0 then
        local text = _G[globalTextName]
        if text then return text:GetText() end
    end
    return nil
end


--	The Blizzard API is separated out so it is easier to see what API is being used

-- AbandonQuest																	-- we rewrite this to our own function
local C_MapBar							= C_MapBar
local C_PetJournal						= C_PetJournal
local CreateFrame						= CreateFrame
local debugprofilestop					= debugprofilestop
local GetAchievementCriteriaInfoByID	= GetAchievementCriteriaInfoByID
local GetAddOnMetadata					= GetAddOnMetadata
local GetAverageItemLevel				= GetAverageItemLevel
local GetBuildInfo						= GetBuildInfo
local GetContainerItemID				= GetContainerItemID
local GetCurrentMapDungeonLevel			= GetCurrentMapDungeonLevel
local GetCVar							= GetCVar
local GetInstanceInfo					= GetInstanceInfo
local GetLocale							= GetLocale
local GetNumQuestLogEntries				= GetNumQuestLogEntries
local GetProfessionInfo					= GetProfessionInfo
local GetProfessions					= GetProfessions
local GetRealmName						= GetRealmName
-- local GetQuestGreenRange				= GetQuestGreenRange
local GetQuestLogRewardFactionInfo		= GetQuestLogRewardFactionInfo
local GetQuestLogSelection				= GetQuestLogSelection
local GetQuestResetTime					= GetQuestResetTime
local GetQuestsCompleted				= GetQuestsCompleted					-- GetQuestsCompleted is special because in modern environments we define it ourselves
local GetSpellLink						= GetSpellLink
local GetText							= GetText
local GetTime							= GetTime
local GetTitleText						= GetTitleText
--local InCombatLockdown					= InCombatLockdown
-- local IsQuestFlaggedCompleted			= IsQuestFlaggedCompleted
local QueryQuestsCompleted				= QueryQuestsCompleted					-- QueryQuestsCompleted is special because in modern environments we define it ourselves
local SelectQuestLogEntry				= SelectQuestLogEntry
-- SendQuestChoiceResponse														-- we rewrite this to our own function
-- SetAbandonQuest																-- we rewrite this to our own function
local UnitClass							= UnitClass
local UnitFactionGroup					= UnitFactionGroup
local UnitGUID							= UnitGUID
local UnitLevel							= UnitLevel
local UnitName							= UnitName
local UnitRace							= UnitRace
local UnitSex							= UnitSex

local BLIZZ_UnitAura					= _G.UnitAura
local BOOKTYPE_SPELL					= BOOKTYPE_SPELL
local DAILY								= DAILY
local LOCALIZED_CLASS_NAMES_FEMALE		= LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE		= LOCALIZED_CLASS_NAMES_MALE
local QuestFrameCompleteQuestButton		= QuestFrameCompleteQuestButton
local REPUTATION						= REPUTATION
local UIParent							= UIParent

local directoryName, _ = ...
local GetAddOnMetadata_API = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local versionFromToc = GetAddOnMetadata_API(directoryName, "Version")
local _, _, versionValueFromToc = strfind(versionFromToc, "(%d+)")
local Grail_File_Version = tonumber(versionValueFromToc)

if nil == Grail or Grail.versionNumber < Grail_File_Version then

	--	Grail uses self.inCombat to determine whether the player is in combat.  This
	--	is set true when PLAYER_REGEN_DISABLED is received, and cleared when
	--	PLAYER_REGEN_ENABLED is received.  This seems to be a better measure than
	--	calling InCombatLockdown().

	--
	--	Even though it is documented that UNIT_QUEST_LOG_CHANGED is preferable to QUEST_LOG_UPDATE, in practice UNIT_QUEST_LOG_CHANGED fails
	--	to do what it is supposed to do.  In fact, processing cannot properly happen using it and not QUEST_LOG_UPDATE, even with proper
	--	priming of the data structures.  Therefore, this addon makes use of QUEST_LOG_UPDATE instead.  Actually, this has proven to be a
	--	little unreliable as well, so a hooked function is now used instead.

	--	It would be really convenient to be able not to store the localized names of the quests and the NPCs.  However, the only real way
	--	to get any arbitrary one (that is not in the quest log) is to populate the tooltip with a hyperlink.  However, that will not normally
	--	return results immediately from a server query, so another attempt at tooltip population is needed.  In the case of quests, this
	--	works pretty well.  However, with NPCs the results are less than satisfactory.  In reality, we want the information to be readily
	--	available for when someone needs it, so polling the server is not convenient.  Therefore, we will continue to store the localized
	--	names of these objects so they are available immediately to the caller.  This means the size of the add-on in memory is going to
	--	be constant and not growing overtime if we were to attempt to populate the information in the background (which we would want to do
	--	to make the information available).

	--	Instead of trying to deal with the concept of having NPCs who have unique IDs to be associated with each other but only be available
	--	in specific "phases", the availability of an NPC should probably be checked through the use of determining whether a quest can be
	--	obtained.  Normally, the prerequisite structure of the quests will indicate specific quests cannot yet be obtained, and those are
	--	likely to be associated with the NPCs that will be in new "phases".  Therefore, nothing special needs be done in this library, but
	--	the onus can be put on the user of this library to ensure only quest givers for available quests are listed/shown.

	--	The Blizzard quest log list cannot reliably be queried upon startup until after the PLAYER_ALIVE event has been received.  However,
	--	setting a flag during that event processing will not work since reloading the UI will not cause PLAYER_ALIVE to be sent again, but
	--	will cause the flag to be reset.  It appears under brief testing that QUEST_LOG_UPDATE fires after PLAYER_ALIVE on normal login, and
	--	fires sometime after PLAYER_LOGIN after a UI reload.  Therefore, the flag will be set in QUEST_LOG_UPDATE event processing.

	--	Another issue is the fact that the calendar API cannot be properly used to get real data until OpenCalendar() has returned something
	--	useful, which cannot occur until later in the login sequence.  And trying to call OpenCalendar() without calling CalendarSetAbsMonth()
	--	beforehand makes it so the call does nothing and the CALENDAR_UPDATE_EVENT_LIST event is never sent.

	--
	--	Caching of the quest status.
	--
	--	If the status of a quest is requested, and that status already exists in the cache, then the cache results
	--	should be returned.  When the status of a quest is computed it is added to the quest status cache.  The
	--	cache of a quest status can be invalidated based on what happens in the environment and the status of the
	--	quest.  For example, if a quest was marked as being too high for the player to obtain, but the player gains
	--	a level, that quest status in the cache needs to be removed so it can be recomputed when needed.
	--

	--	For some quests Blizzard marks others complete when you complete one.  For example, Firelands dailies are in groups and when you
	--	finish one, the others are marked complete on the server.  This tends not to be a problem.  However, Blizzard also does this with
	--	quests the player would never be able to acquire, like the starting zone class-specific quests.  So, when a mage completes its
	--	class quest the server marks the class quests for hunter, warrior, etc. also complete.  This seems idiotic as Blizzard already has
	--	other mechanisms to limit a mage from getting a hunter quest, for example.  This causes a problem with the way Grail evaluates the
	--	status of a quest, since it is done "live" because quests have so many relationships.  In general, the quests that one could never
	--	aquire are evaluated such during play, and in the future when they are marked complete on the server they will be both marked
	--	complete since we must believe what the server reports, and will be marked unobtainable for whatever reasons are appropriate.
	--	This works well except for when we attempt to evaluate prerequisites because part of prerequisites is to see if the required quest
	--	is complete.  However, we also check to see whether the quest can be obtained.  The flaw that we currently have is that we are
	--	evaluating whether the quest can be obtained currently, which is technically incorrect because it should be can the quest be
	--	obtained at the time the quest is marked complete.  Of course we can only know this if we keep track of which specific quests are
	--	marked complete when any other is done.  This is yet another level of annoyance that Blizzard causes that it need not.  So, Grail
	--	is going to approximate this for the time being with evaluating the current ability to accept a quest that was complete.

	--	Blizzard seems to have some internal method of determining state with regard to quests that is not flagged using another quest.
	--	They do use other quests sometimes, but not all the time.  Therefore, to ensure we keep a similar state bogus quests are used within
	--	the database, but these are not going to be present from the server query.  Therefore, this state is kept in controlCompletedQuests
	--	which will be checked every time the results from the server query are processed to ensure the internally kept master completed
	--	quests include them.

	--	Database of stored information per character.
	GrailDatabasePlayer = {}
	GrailDatabase = { }
	--	The completedQuests is a table of 32-bit integers.  The index in the table indicates which set of 32 bits are being used and the value at that index
	--	is a bit representation of completed quests in that 32 quest range.  For example, quest 7 being the only one completed in the quests from 1 to 32
	--	would mean table entry 0 would have a value of 64.  Quest 33 being done would mean [1] = 1, while quests 33 and 35 would mean [1] = 5.  The user need
	--	not know any of this since the API to access this information takes care of the dirty work.
	--	The completedResettableQuests is just like completedQuests except it records only those quests that Blizzard resets like dailies and weeklies.  This
	--	is used for API that can determine if a quest has ever been completed (since a daily could have been completed in the past, but Blizzard's API would
	--	indicate that it is currently not completed (because it has been reset)).
	--	There are four possible tables of interest:  NewNPCs, NewQuests, SpecialQuests and BadQuestData.
	--	These tables could be used to provide feedback which can be used to update the internal database to provide more accurate quest information.

	Grail = {
experimental = false,	-- currently this implementation does not reduce memory significantly [this is used to make the map area hold quests in bit form]
		versionNumber = Grail_File_Version,
		questsVersionNumber = 0,
		npcsVersionNumber = 0,
		npcNamesVersionNumber = 0,
		zonesVersionNumber = 0,
		zonesIndexedVersionNumber = 0,
		achievementsVersionNumber = 0,
		reputationsVersionNumber = 0,
		buggedQuestsVersionNumber = 0,
		INFINITE_LEVEL = 100000,
		NO_SKILL = -1,
		NPC_TYPE_BY = 'BY',
		NPC_TYPE_DROP = 'DROP',
		NPC_TYPE_KILL = 'KILL',
		abandonPostNotificationDelay = 1.0,
		abandoningQuestIndex = nil,
		artifactLevels = {},	-- key is itemID, value is level
		accountUnlock = "Account Unlock",
		availableWorldQuests = {},

		-- Bit mask system for quest status
		-- First bits are "good" bits
		bitMaskNothing							= 0x00000000,
		bitMaskCompleted						= 0x00000001,
		bitMaskRepeatable						= 0x00000002,
		bitMaskResettable						= 0x00000004,
		bitMaskEverCompleted					= 0x00000008,
		bitMaskInLog							= 0x00000010,
		bitMaskLevelTooLow						= 0x00000020,		-- the player's level is too low for the quest currently
		bitMaskLowLevel							= 0x00000040,		-- the quest is a low-level quest compared to the player's level
		-- These are really failure bits
		bitMaskClass							= 0x00000080,
		bitMaskRace								= 0x00000100,
		bitMaskGender							= 0x00000200,
		bitMaskFaction							= 0x00000400,
		bitMaskInvalidated						= 0x00000800,
		bitMaskProfession						= 0x00001000,
		bitMaskReputation						= 0x00002000,
		bitMaskHoliday							= 0x00004000,
		bitMaskLevelTooHigh						= 0x00008000,		-- the player's level is too high for the quest
		-- This next one indicates no prerequisites have been fulfilled
		bitMaskPrerequisites					= 0x00010000,
		-- These are failure bits for ancestor quests if bitMaskPrerequisites is set.  They are the same
		-- as the previous set of failure bits * 1024
		bitMaskAncestorClass					= 0x00020000,
		bitMaskAncestorRace						= 0x00040000,
		bitMaskAncestorGender					= 0x00080000,
		bitMaskAncestorFaction					= 0x00100000,
		bitMaskAncestorInvalidated				= 0x00200000,
		bitMaskAncestorProfession				= 0x00400000,
		bitMaskAncestorReputation				= 0x00800000,
		bitMaskAncestorHoliday					= 0x01000000,
		bitMaskAncestorLevelTooHigh				= 0x02000000,
		-- Informational bits
		bitMaskInLogComplete					= 0x04000000,
		bitMaskInLogFailed						= 0x08000000,
		bitMaskResettableRepeatableCompleted	= 0x10000000,
		bitMaskBugged							= 0x20000000,
		-- These basically represent internal errors within the database
		bitMaskNonexistent						= 0x40000000,
		bitMaskError							= 0x80000000,
		-- Some convenience values precomputed
		bitMaskQuestFailure = 0xff80,	-- from bitMaskClass to bitMaskLevelTooHigh
		bitMaskQuestFailureWithAncestor = 0x03feff80,	-- bitMaskQuestFailure + (bitMaskAncestorClass to bitMaskAncestorLevelTooHigh)
		bitMaskAcceptableMask = 0xcfffffb1,	-- all bits except bitMaskRepeatable, bitMaskResettable, bitMaskEverCompleted, bitMaskResettableRepeatableCompleted and bitMaskLowLevel and now bitMaskBugged
		-- End of Bit mask values


		-- Bit mask system for other quest information indicating who can get a quest
		-- Faction
		bitMaskFactionAlliance	=	0x00000001,
		bitMaskFactionHorde		=	0x00000002,
		-- Class
		bitMaskClassDeathKnight	=	0x00000004,
		bitMaskClassDruid		=	0x00000008,
		bitMaskClassHunter		=	0x00000010,
		bitMaskClassMage		=	0x00000020,
		bitMaskClassMonk		=	0x00000040,
		bitMaskClassPaladin		=	0x00000080,
		bitMaskClassPriest		=	0x00000100,
		bitMaskClassRogue		=	0x00000200,
		bitMaskClassShaman		=	0x00000400,
		bitMaskClassWarlock		=	0x00000800,
		bitMaskClassWarrior		=	0x00001000,
		-- Gender
		bitMaskGenderMale		=	0x00002000,
		bitMaskGenderFemale		=	0x00004000,
		-- Unused
		bitMaskCanGetUnused1	=	0x00008000,
		bitMaskCanGetUnused2	=	0x00010000,
		bitMaskCanGetUnused3	=	0x00020000,
		bitMaskCanGetUnused4	=	0x00040000,
		bitMaskCanGetUnused5	=	0x00080000,
		bitMaskCanGetUnused6	=	0x00100000,
		bitMaskCanGetUnused7	=	0x00200000,
		bitMaskCanGetUnused8	=	0x00400000,
		bitMaskCanGetUnused9	=	0x00800000,
		bitMaskCanGetUnused10	=	0x01000000,
		bitMaskCanGetUnused11	=	0x02000000,
		bitMaskCanGetUnused12	=	0x04000000,
		bitMaskClassEvoker		=	0x08000000,	-- *** CLASS ***, kept in bit order
		bitMaskClassDemonHunter =	0x10000000,	-- *** CLASS ***, kept in bit order
		bitMaskCanGetUnused14	=	0x20000000,
		bitMaskCanGetUnused15	=	0x40000000,
		bitMaskCanGetUnused16	=	0x80000000,
		-- Some convenience values
		bitMaskFactionAll		=	0x00000003,
		bitMaskClassAll			=	0x18001ffc,
		bitMaskGenderAll		=	0x00006000,
		-- End of bit mask values

		-- Bit mask system for which race can get a quest
		bitMaskRaceHighmountainTauren	=	0x00000001,
		bitMaskRaceNightborne			=	0x00000002,
		bitMaskRaceDarkIronDwarf		=	0x00000004,
		bitMaskRaceMagharOrc			=	0x00000008,
		bitMaskRaceHarronir				=	0x00000010,
			bitMaskRaceUnused2			=	0x00000020,
			bitMaskRaceUnused3			=	0x00000040,
			bitMaskRaceUnused4			=	0x00000080,
			bitMaskRaceUnused5			=	0x00000100,
			bitMaskRaceUnused6			=	0x00000200,
			bitMaskRaceUnused7			=	0x00000400,
		bitMaskEarthen					=	0x00000800,
		bitMaskRaceDracthyr				=	0x00001000,
		bitMaskRaceMechagnome			=	0x00002000,
		bitMaskRaceVulpera				=	0x00004000,
		bitMaskRaceHuman				=	0x00008000,
		bitMaskRaceDwarf				=	0x00010000,
		bitMaskRaceNightElf				=	0x00020000,
		bitMaskRaceGnome				=	0x00040000,
		bitMaskRaceDraenei				=	0x00080000,
		bitMaskRaceWorgen				=	0x00100000,
		bitMaskRaceOrc					=	0x00200000,
		bitMaskRaceScourge				=	0x00400000,
		bitMaskRaceTauren				=	0x00800000,
		bitMaskRaceTroll				=	0x01000000,
		bitMaskRaceBloodElf				=	0x02000000,
		bitMaskRaceGoblin				=	0x04000000,
		bitMaskRacePandaren				=	0x08000000,
		bitMaskZandalariTroll			=	0x10000000,
		bitMaskRaceVoidElf				=	0x20000000,
		bitMaskRaceLightforgedDraenei	=	0x40000000,
		bitMaskKulTiran					=	0x80000000,
		-- Convenience values
		bitMaskRaceAll			=	0xfffff81f,

		-- Enf of bit mask values


		-- Bit mask system for information about type of quest
		bitMaskQuestRepeatable	=	0x00000001,
		bitMaskQuestDaily		=	0x00000002,
		bitMaskQuestWeekly		=	0x00000004,
		bitMaskQuestMonthly		=	0x00000008,
		bitMaskQuestYearly		=	0x00000010,
		bitMaskQuestEscort		=	0x00000020,
		bitMaskQuestDungeon		=	0x00000040,
		bitMaskQuestRaid		=	0x00000080,
		bitMaskQuestPVP			=	0x00000100,
		bitMaskQuestGroup		=	0x00000200,
		bitMaskQuestHeroic		=	0x00000400,
		bitMaskQuestScenario	=	0x00000800,
		bitMaskQuestLegendary	=	0x00001000,
		bitMaskQuestAccountWide	=	0x00002000,
		bitMaskQuestPetBattle	=	0x00004000,
		bitMaskQuestBonus		=	0x00008000,		-- bonus objective
		bitMaskQuestRareMob		=	0x00010000,		-- rare mob
		bitMaskQuestTreasure	=	0x00020000,
		bitMaskQuestWorldQuest	=	0x00040000,
		bitMaskQuestBiweekly	=	0x00080000,
		bitMaskQuestThreatQuest =	0x00100000,
		bitMaskQuestCallingQuest =	0x00200000,
			bitMaskQuestUnused1 =	0x00400000,
			bitMaskQuestUnused2 =	0x00800000,
			bitMaskQuestUnused3	=	0x01000000,
		bitMaskQuestPushable	=	0x02000000,		-- sharable
		bitMaskQuestMeta		=	0x04000000,
		bitMaskQuestInvasion	=	0x08000000,
		bitMaskQuestBounty		=	0x10000000,
		bitMaskQuestImportant	=	0x20000000,
		bitMaskQuestWarband		=	0x40000000,
		bitMaskQuestSpecial		=	0x80000000,		-- quest is "special" and never appears in the quest log
		-- End of bit mask values

		-- Bit mask system for information about level of quest
		-- Eight bits are used to be able to represent a level value from 0 - 255.
		-- Three sets of those eight bits are used to represent the actual level
		-- of the quest, the minimum level required for the quest, and the maximum
		-- level allowed to accept the quest.  Some quests have a variable level
		-- and this is now supported in the bit structure as well.
		-- we should have them as MMKKLLNN
		bitMaskQuestLevel				=	0x00ff0000, -- K
		bitMaskQuestMinLevel			=	0x0000ff00, -- L
		bitMaskQuestMaxLevel			=	0xff000000, -- M
		bitMaskQuestVariableLevel		=	0x000000ff, -- N

		bitMaskQuestLevelOffset			=	0x00010000,	-- K
		bitMaskQuestMinLevelOffset		=	0x00000100, -- L
		bitMaskQuestMaxLevelOffset		=	0x01000000, -- M
		bitMaskQuestVariableLevelOffset	=	0x00000001, -- N
		-- End of bit mask values


		-- Bit mask system for holidays
		bitMaskHolidayLove		=	0x00000001,
		bitMaskHolidayBrewfest	=	0x00000002,
		bitMaskHolidayChildren	=	0x00000004,
		bitMaskHolidayDead		=	0x00000008,
		bitMaskHolidayDarkmoon	=	0x00000010,
		bitMaskHolidayHarvest	=	0x00000020,
		bitMaskHolidayLunar		=	0x00000040,
		bitMaskHolidayMidsummer	=	0x00000080,
		bitMaskHolidayNoble		=	0x00000100,
		bitMaskHolidayPirate	=	0x00000200,
		bitMaskHolidayNewYear	=	0x00000400,
		bitMaskHolidayWinter	=	0x00000800,
		bitMaskHolidayHallow	=	0x00001000,
		bitMaskHolidayPilgrim	=	0x00002000,
		bitMaskHolidayChristmas	=	0x00004000,
		bitMaskHolidayFishing	=	0x00008000,
		bitMaskHolidayKaluak    =   0x00010000,
		--                ['a'] =   0x00020000,
		--                ['b'] =   0x00040000,
		--                ['c'] =   0x00080000,
		--                ['d'] =   0x00100000,
		--                ['e'] =   0x00200000,
		--                ['f'] =   0x00400000,
		--                ['g'] =   0x00800000,
		--                ['h'] =   0x01000000,
		--                ['i'] =   0x02000000,
		bitMaskHolidayAnniversary = 0x04000000,	-- WoW Anniversary event
		bitMaskHolidayAQ		=	0x08000000,
		--				  ['j']	=	0x10000000,
		--				  ['k']	=	0x20000000,
		--				  ['l']	=	0x40000000,
		-- End of bit mask values

		bodyGuardLevel = { 'Bodyguard', 'Trusted Bodyguard', 'Personal Wingman' },
		buggedQuests = {},	-- index is the questId, value is a string describing issue/solution

		cachedBagItems = nil,
		--	This is used to speed up getting the status of each quest because there is a routine that needs to find whether
		--	any specific quest is already in the quest log.  When evaluating many quests this check of quests in the quest
		--	log would be made at least once for each quest, so caching makes things a little quicker.
		cachedQuestsInLog = nil,
		checksReputationRewardsOnAcceptance = true,
		classMapping = {
			['D'] = 'DRUID',
			['E'] = 'DEMONHUNTER',
			['H'] = 'HUNTER',
			['K'] = 'DEATHKNIGHT',
			['L'] = 'WARLOCK',
			['M'] = 'MAGE',
			['O'] = 'MONK',
			['P'] = 'PALADIN',
			['R'] = 'ROGUE',
			['S'] = 'SHAMAN',
			['T'] = 'PRIEST',
			['V'] = 'EVOKER',
			['W'] = 'WARRIOR',
		},
		classToBitMapping = { ['K'] = 0x00000004, ['D'] = 0x00000008, ['E'] = 0x10000000, ['H'] = 0x00000010, ['M'] = 0x00000020, ['O'] = 0x00000040, ['P'] = 0x00000080, ['T'] = 0x00000100, ['R'] = 0x00000200, ['S'] = 0x00000400, ['L'] = 0x00000800, ['V'] = 0x08000000, ['W'] = 0x00001000, },
		classToMapAreaMapping = { ['CK'] = 200011, ['CD'] = 200004, ['CE'] = 200005, ['CH'] = 200008, ['CM'] = 200013, ['CO'] = 200015, ['CP'] = 200016, ['CT'] = 200020, ['CR'] = 200018, ['CS'] = 200019, ['CL'] = 200012, ['CV'] = 200022, ['CW'] = 200023, },
		completedQuestThreshold = 0.5,
		continents = {},	-- key is mapId for the continent, value is { name = string, zones = {}, mapID = int, dungeons = {} }
							-- and zones and dungeons are just arrays of { name = string, mapID = int }
		currentlyProcessingStatus = {},
		currentlyVerifying = false,
		currentMortalIssues = {},
		currentQuestIndex = nil,
		debug = false,
		defaultUnfoundLootingName = "No name gotten",
		delayBagUpdate = 0.5,
		delayedEvents = {},
		delayedEventsCount = 0,
		delayQuestRemoved = 4.5,
		diversionMapping = {	-- a mapping of talentID to associated questId
			[1255] = 60304,
			[1257] = 60305,
			[1258] = 60299,
		},
		eventDispatch = {			-- table of functions whose keys are the events

			-- >>>VIGNETTE_DEBUG
			['VIGNETTES_UPDATED'] = function(self, frame)
				-- Use persistent snapshots: by the time this event fires the state has
				-- already changed, so a local before/after within this call would be identical.
				local _vigNow = self:_VignetteSnapshot()
				-- Build a context label so we know what was happening when the vignette changed
				local _ctx = 'VIGNETTES_UPDATED'
				if nil ~= self.questTurningIn then
					_ctx = _ctx .. strformat(' [during QUEST_TURNED_IN quest=%d]', self.questTurningIn)
				elseif nil ~= self.lootingGUID then
					_ctx = _ctx .. strformat(' [during loot guid=%s]', self.lootingGUID)
				end
				-- _VignetteCompareAndLog is deferred to after link-writing:
				-- if links are written, the compare is suppressed (redundant).
				local _linksWritten = 0
				-- Store disappeared vignettes keyed by spawn UID (last GUID segment) so
				-- _HandleEventLootClosed can correlate them with the creature and its quests.
				self._recentlyDisappearedVignettes = self._recentlyDisappearedVignettes or {}
				self._recentlyAppearedVignettes    = self._recentlyAppearedVignettes or {}
				local _disappearedThisUpdate = {}
				local _appearedThisUpdate    = {}
				for guid, info in pairs(self._persistentVigSnapshot or {}) do
					if not _vigNow[guid] then
						local spawnUID = select(7, strsplit('-', guid))
						if spawnUID then
							self._recentlyDisappearedVignettes[spawnUID] = { guid=guid, name=info.name, vignetteType=info.vignetteType, time=GetTime(), coords=info.coords }
							table.insert(_disappearedThisUpdate, { guid=guid, name=info.name, spawnUID=spawnUID })
						end
					end
				end
				for guid, info in pairs(_vigNow) do
					local prev = (self._persistentVigSnapshot or {})[guid]
					local isNew      = (prev == nil)
					local cameInRange = (prev ~= nil and not prev.onMinimap and info.onMinimap)
					if isNew or cameInRange then
						local spawnUID = select(7, strsplit('-', guid))
						if spawnUID then
							local timeToUse = cameInRange and (GetTime() - 120) or GetTime()  -- wider window for in-range
							self._recentlyAppearedVignettes[spawnUID] = { guid=guid, name=info.name, vignetteType=info.vignetteType, time=timeToUse, coords=info.coords }
							table.insert(_appearedThisUpdate, { guid=guid, name=info.name, spawnUID=spawnUID, cameInRange=cameInRange })
							_linksWritten = _linksWritten + 1  -- suppress compare: vignette stored for future linking
						end
					end
				end
				-- Reverse rep lookup: if a vignette appeared and there are recent rep changes not yet linked,
				-- log the correlation now (rep event fired before VIGNETTES_UPDATED).
				if #_appearedThisUpdate > 0 and nil ~= self._recentlyRepChanges then
					local now = GetTime()
					-- Collect all valid rep entries first, then link ALL vignettes
					-- Use wider window (120s) for vignettes that just came in range
					local maxWindow = 10
					for _, ve in ipairs(_appearedThisUpdate) do
						if ve.cameInRange then maxWindow = 120 break end
					end
					local linkedReps = {}
					local usedRepKeys = {}
					for repKey, repInfo in pairs(self._recentlyRepChanges) do
						if (now - repInfo.time) <= maxWindow then
							table.insert(linkedReps, strformat('%s+%s', repInfo.faction, tostring(repInfo.amount)))
							table.insert(usedRepKeys, repKey)
						end
					end
					if #linkedReps > 0 then
						local repStr = table.concat(linkedReps, ', ')
						for _, vigEntry in ipairs(_appearedThisUpdate) do
							local _vigCoords = (self._recentlyAppearedVignettes[vigEntry.spawnUID] and self._recentlyAppearedVignettes[vigEntry.spawnUID].coords)
								or tostring(self:Coordinates())
							local _src = strformat('rep=%s | coords=%s', repStr, _vigCoords)
							if self:_IsNewVignetteLink(vigEntry.guid, _src, vigEntry.name) then
								local msg = strformat('VIGNETTE_REP_LINK (rep before vig): vignette=%s name=%s | %s', vigEntry.guid, tostring(vigEntry.name), _src)
								print(msg)
								self:_AddTrackingMessage(msg)
								_linksWritten = _linksWritten + 1
							end
							self._recentlyAppearedVignettes[vigEntry.spawnUID] = nil
						end
						-- Clean up rep entries after all vignettes are linked
						for _, repKey in ipairs(usedRepKeys) do
							self._recentlyRepChanges[repKey] = nil
						end
					end
				end
				-- If a book was just read and a vignette disappeared in the same event,
				-- do a deferred quest compare to catch async-completed tracking quests.
				-- Expire the context after 5 seconds to avoid false matches when a book
				-- has no associated vignette and one disappears later for unrelated reasons.
				if nil ~= self._pendingBookVignetteContext
					and (GetTime() - self._pendingBookVignetteContext.time) <= 5
					and #_disappearedThisUpdate > 0 then
					local bctx = self._pendingBookVignetteContext
					self._pendingBookVignetteContext = nil
					local silentValue, manualValue = self.GDE.silent, self.manuallyExecutingServerQuery
					self.GDE.silent, self.manuallyExecutingServerQuery = true, false
					QueryQuestsCompleted()
					local newlyCompleted = {}
					self:_ProcessServerCompare(newlyCompleted)
					for _, qId in pairs(newlyCompleted) do
						self:_MarkQuestComplete(qId, true)
						local vigNames = {}
						for _, v in ipairs(_disappearedThisUpdate) do table.insert(vigNames, v.name) end
						local msg = strformat('Book read completes %d | Target: %s (%d) | Coords: %s | vignette: %s',
							qId, tostring(bctx.targetName), tonumber(bctx.npcId) or -1,
							tostring(bctx.coordinates), table.concat(vigNames, ', '))
						print(msg)
						self:_AddTrackingMessage(msg)
					end
					self:_ProcessServerBackup(true)
					self.GDE.silent, self.manuallyExecutingServerQuery = silentValue, manualValue
				end
				-- Reverse lookup: if vignettes disappeared and there are recently completed
				-- quests not yet linked (quest completed before vignette update fired),
				-- log the link now.
				if #_disappearedThisUpdate > 0 and nil ~= self._recentlyCompletedUnlinkedQuests then
					local now = GetTime()
					-- Collect all valid quests first, then link ALL vignettes
					-- Wider window for vignettes that just came in range
					local _qWindow = 10
					for _, ve in ipairs(_disappearedThisUpdate) do
						if ve.cameInRange then _qWindow = 120 break end
					end
					local linkedQuests = {}
					for qId, qTime in pairs(self._recentlyCompletedUnlinkedQuests) do
						if (now - qTime) <= _qWindow then
							table.insert(linkedQuests, tostring(qId))
						end
					end
					if #linkedQuests > 0 then
						local questStr = table.concat(linkedQuests, ',')
						for _, vigEntry in ipairs(_disappearedThisUpdate) do
							local _vcoords = (self._recentlyDisappearedVignettes[vigEntry.spawnUID] and self._recentlyDisappearedVignettes[vigEntry.spawnUID].coords)
								or tostring(self:Coordinates())
							local _src = strformat('quests=%s | coords=%s', questStr, _vcoords)
							if self:_IsNewVignetteLink(vigEntry.guid, _src, vigEntry.name) then
								local msg = strformat('VIGNETTE_QUEST_LINK (no loot): vignette=%s name=%s | %s', vigEntry.guid, tostring(vigEntry.name), _src)
								print(msg)
								self:_AddTrackingMessage(msg)
								_linksWritten = _linksWritten + 1
							end
							self._recentlyDisappearedVignettes[vigEntry.spawnUID] = nil
						end
						-- Clean up quests after all vignettes are linked
						for _, qId in ipairs(linkedQuests) do
							self._recentlyCompletedUnlinkedQuests[tonumber(qId)] = nil
						end
					end
				end
				-- Clear expired book context even when no vignette disappeared
				if nil ~= self._pendingBookVignetteContext
					and (GetTime() - self._pendingBookVignetteContext.time) > 5 then
					self._pendingBookVignetteContext = nil
				end
				-- Only show compare if no links were written for this update
				if _linksWritten == 0 then
					self:_VignetteCompareAndLog(self._persistentVigSnapshot or {}, _vigNow, _ctx)
				end
				self._persistentVigSnapshot = _vigNow
				-- Auto-update names for vignette links that have true instead of name
				local db = GrailDatabase
				if db.vignetteLinks then
					for k, v in pairs(db.vignetteLinks) do
						if v == true then
							local g = strmatch(k, '^([^|]+)')
							if g and strsub(g, 1, 9) == 'Vignette-' then
								local info = C_VignetteInfo.GetVignetteInfo(g)
								if info and info.name then
									db.vignetteLinks[k] = info.name
									if db.vignetteGuidIndex then db.vignetteGuidIndex[g] = k end
									print(strformat('|cFFFFFF00Grail|r: vignette named: |cFF00FF00%s|r', info.name))
								end
							end
						end
					end
				end
			end,
			-- >>>VIGNETTE_DEBUG_END

			['AREA_POIS_UPDATED'] = function(self, frame)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventAreaPOIsUpdated()
				else
					self:_RegisterDelayedEvent(frame, { 'AREA_POIS_UPDATED' } )
				end
			end,

			['MAJOR_FACTION_RENOWN_LEVEL_CHANGED'] = function(self, frame, arg1, arg2, arg3)
				local factionId = tonumber(arg1)
				local newRenownLevel = tonumber(arg2)
				local oldRenownLevel = tonumber(arg3)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventMajorFactionRenownLevelChanged(factionId, newRenownLevel, oldRenownLevel)
				else
					self:_RegisterDelayedEvent(frame, { 'MAJOR_FACTION_RENOWN_LEVEL_CHANGED', factionId, newRenownLevel, oldRenownLevel } )
				end
			end,

			['MAJOR_FACTION_UNLOCKED'] = function(self, frame, arg1)
				local factionId = tonumber(arg1)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventMajorFactionUnlocked(factionId)
				else
					self:_RegisterDelayedEvent(frame, { 'MAJOR_FACTION_UNLOCKED', factionId } )
				end
			end,

			['ACHIEVEMENT_EARNED'] = function(self, frame, arg1, arg2)
				local achievementNumber = tonumber(arg1)
				local _, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementNumber)

				if nil ~= achievementNumber then
					if self.GDE.debug then
						print(
							"Achievement earned:",
							"ID:", tostring(achievementNumber),
							"Name:", tostring(name),
							"Points:", tostring(points),
							"Completed:", tostring(completed),
							"Month:", tostring(month),
							"Day:", tostring(day),
							"Year:", tostring(year),
							"Description:", tostring(description),
							"Flags:", tostring(flags),
							"Icon:", tostring(icon),
							"RewardText:", tostring(rewardText),
							"isGuild:", tostring(isGuild),
							"wasEarnedByMe:", tostring(wasEarnedByMe),
							"earnedBy:", tostring(earnedBy)
						)
					end
						--print("Achievement earned: ", achievementNumber)
							
					local msg = string.format(
						"Achievement earned: ID: %s, Name: %s/ Points: %s/ Completed: %s/ Month: %s/ Day: %s/ Year: %s/ Description: %s/ Flags: %s/ Icon: %s/ RewardText: %s/ isGuild: %s/ wasEarnedByMe: %s/ earnedBy: %s",
						tostring(achievementNumber),
						tostring(name),
						tostring(points),
						tostring(completed),
						tostring(month),
						tostring(day),
						tostring(year),
						tostring(description),
						tostring(flags),
						tostring(icon),
						tostring(rewardText),
						tostring(isGuild),
						tostring(wasEarnedByMe),
						tostring(earnedBy)
					)
					self:_AddTrackingMessage(msg)

				end
				if nil ~= achievementNumber and nil ~= self.questStatusCache['A'][achievementNumber] then
					if not self.inCombat or not self.GDE.delayEvents then
						self:_HandleEventAchievementEarned(achievementNumber)
					else
						self:_RegisterDelayedEvent(frame, { 'ACHIEVEMENT_EARNED', achievementNumber } )
					end
				end
			end,

			['CRITERIA_COMPLETE'] = function(self, frame, arg1)
				local criteriaID = tonumber(arg1)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleCriteriaComplete(criteriaID)
				else
					self:_RegisterDelayedEvent(frame, { 'CRITERIA_COMPLETE', criteriaID } )
				end
			end,

			['PLAYER_LOGIN'] = function(self, frame, arg1)
--				if "Grail" == arg1 then

					local debugStartTime = debugprofilestop()
					--
					--	First pull some information about the player and environment so it can be recorded for easier access
					--
					local _
					self.playerRealm = GetRealmName()
					self.playerName = UnitName('player')
					_, self.playerClass, self.playerClassId = UnitClass('player')
					_, self.playerRace = UnitRace('player')
					self.playerFaction = UnitFactionGroup('player')		-- for Pandaren who has not chosen results is "Neutral"
					self.playerGender = UnitSex('player')
					self.levelingLevel = UnitLevel('player')
					local version, release, date, tocVersion = GetBuildInfo()
					self.blizzardRelease = tonumber(release)
					self.blizzardVersion = version
					self.blizzardVersionAsNumber = self:_MakeNumberFromVersion(self.blizzardVersion)
					self.portal = GetCVar("portal")
					self.covenant = C_Covenants and C_Covenants.GetActiveCovenantID() or 0
					self.renownLevel = C_CovenantSanctumUI and C_CovenantSanctumUI.GetRenownLevel() or 0
					self.activeSeason = C_Seasons and C_Seasons.GetActiveSeason() or 0	-- 0 is NoSeason
					self.timerunningSeason = PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() or 0
					self.accountExpansionLevel = GetAccountExpansionLevel() or 0
					self.expansionLevel = GetExpansionLevel() or 0
					self.classicExpansionLevel = GetClassicExpansionLevel() or 0
					self.serverExpansionLevel = GetServerExpansionLevel() or 0
					self.isTrial = IsTrialAccount() or 0
					self.isVeteranTrial = IsVeteranTrialAccount() or 0
					-- IsBetaBuild() does not exist in _classic_era_ nor in _classic_
					if IsBetaBuild and IsBetaBuild() then
						self.environment = "_beta_"
					else
						local baseEnvironment = "_unknown_"
						if self.existsMainline then
							baseEnvironment = "_retail_"                    -- "World of Warcraft"
						elseif self.existsClassic then
							baseEnvironment = "_classic_"                   -- "Cataclysm Classic"
						elseif self.existsClassicEra then
							baseEnvironment = "_classic_era_"               -- "World of Warcraft Classic"
						end
						-- There is no reason to need to make use of IsPublicBuild() because what we need to know is done with IsTestBuild().
						if IsTestBuild() then
							if self.existsMainline then
								self.environment = "_ptr_"              -- note that 11.0.2 PTR is _ptr_ but 11.0.5 PTR is _xptr_
							else
								self.environment = baseEnvironment .. "ptr_"
							end
						else
							self.environment = baseEnvironment
						end
					end

					self.existsClassic = self.existsClassicBasic or self.existsClassicWrathOfTheLichKing or self.existsClassicCataclysm or self.existsClassicPandaria

					GrailDatabase[self.environment] = GrailDatabase[self.environment] or {}
					self.GDE = GrailDatabase[self.environment]

					-- Snapshot the quest pins already known from prior sessions so that
					-- /grail pins can report only the ones discovered this session.
					self.sessionStartQuestPins = {}
					if self.GDE.observedQuestLocations then
						for questID in pairs(self.GDE.observedQuestLocations) do
							self.sessionStartQuestPins[questID] = true
						end
					end

					-- Now we set up some capabilities flags
					self.capabilities = {}
					self.capabilities.usesFriendshipReputation = self.existsMainline
					self.capabilities.usesAchievements = not self.existsClassic or self.existsClassicWrathOfTheLichKing or self.existsClassicCataclysm or self.existsClassicPandaria
					self.capabilities.usesGarrisons = self.existsMainline
					self.capabilities.usesArtifacts = false --self.existsMainline
					self.capabilities.usesCampaignInfo = self.existsMainline
					self.capabilities.usesCalendar = self.existsMainline
					self.capabilities.usesAzerothAsCosmicMap = self.existsClassicEra
					self.capabilities.usesQuestHyperlink = self.existsMainline or self.existsClassicWrathOfTheLichKing or self.existsClassicCataclysm or self.existsClassicPandaria
					self.capabilities.usesFollowers = self.existsMainline
					self.capabilities.usesWorldEvents = self.existsMainline
					self.capabilities.usesWorldQuests = self.existsMainline
					self.capabilities.usesCallingQuests = self.existsMainline
					self.capabilities.usesCampaignQuests = self.existsMainline
					self.capabilities.usesFlightPoints = self.existsMainline
					self.capabilities.usesMajorFactions = self.existsMainline
					self.capabilities.usesAreaPOIs    = self.existsMainline
					-- >>>VIGNETTE_DEBUG
					self.capabilities.usesVignettes   = self.existsMainline and (C_VignetteInfo ~= nil)
					-- >>>VIGNETTE_DEBUG_END
					self.capabilities.usesLegendaryQuests = self.existsMainline
					self.capabilities.usesThreatQuests = self.existsMainline
					self.capabilities.usesPetBattles = self.existsMainline or self.existsClassicPandaria
					self.capabilities.usesImportantQuests = self.existsMainline
					self.capabilities.usesInvasionQuests = self.existsMainline
					self.capabilities.usesAccountQuests = self.existsMainline
					self.capabilities.usesWarbandQuests = self.existsMainline

                    -- These values are no longer used, but kept for posterity.
-- TODO: Deal with the following by eliminating them...
					self.existsPandaria = (self.blizzardRelease >= 15640)
					self.existsWoD = (self.blizzardRelease >= 18505)
					self.existsLegion = (self.blizzardRelease >= 21531 and self.blizzardVersionAsNumber >= 7000000)
					self.exists72 = (self.blizzardRelease >= 23578)
					self.exists73 = (self.blizzardRelease >= 24563 and self.blizzardVersionAsNumber >= 7003000)
					self.battleForAzeroth = (self.blizzardRelease >= 26175 and self.blizzardVersionAsNumber >= 8000000)

					-- We have loaded GrailDatabase at this point, but we need to ensure the structure is set up for first-time players as we rely on at least an empty structure existing
					GrailDatabasePlayer = GrailDatabasePlayer or {}
					-- Purge invalid vignette entries (no valid GUID starting with 'Vignette-')
					do
						local purgeCount = 0
						-- Purge from Tracking log
						if GrailDatabasePlayer.Tracking then
							for i = #GrailDatabasePlayer.Tracking, 1, -1 do
								local entry = GrailDatabasePlayer.Tracking[i]
								if strfind(entry, 'VIGNETTE_', 1, true) then
									local g = strmatch(entry, 'vignette=(%S+)')
									if g and strsub(g, 1, 9) ~= 'Vignette-' then
										table.remove(GrailDatabasePlayer.Tracking, i)
										purgeCount = purgeCount + 1
									end
								end
							end
						end
						-- Purge from vignetteLinks
						if GrailDatabase.vignetteLinks then
							for k in pairs(GrailDatabase.vignetteLinks) do
								local g = strmatch(k, '^([^|]+)')
								if g and strsub(g, 1, 9) ~= 'Vignette-' then
									GrailDatabase.vignetteLinks[k] = nil
									purgeCount = purgeCount + 1
								end
							end
						end
						-- Purge from vignetteGuidIndex
						if GrailDatabase.vignetteGuidIndex then
							for g in pairs(GrailDatabase.vignetteGuidIndex) do
								if strsub(g, 1, 9) ~= 'Vignette-' then
									GrailDatabase.vignetteGuidIndex[g] = nil
									purgeCount = purgeCount + 1
								end
							end
						end
						if purgeCount > 0 then
							print(strformat('|cFFFFFF00Grail|r: purged %d invalid vignette entries', purgeCount))
						end
					end

					self.quest.name[600000]=Grail:_GetMapNameByID(19)..' '..REQUIREMENTS
					self.quest.name[600001]=Grail:_GetMapNameByID(19)..' '..FACTION_ALLIANCE..' '..REQUIREMENTS
					self.quest.name[600002]=Grail:_GetMapNameByID(19)..' '..FACTION_HORDE..' '..REQUIREMENTS

					if self.existsClassic then	-- redefine races that are available
						self.races = {
							-- [1] is Blizzard API return (non-localized)
							-- [2] is localized male
							-- [3] is localized female
							-- [4] is bitmap value
							['E'] = { 'NightElf', 'Night Elf', 'Night Elf', 0x00020000 },
							['F'] = { 'Dwarf',    'Dwarf',     'Dwarf',     0x00010000 },
							['H'] = { 'Human',    'Human',     'Human',     0x00008000 },
							['L'] = { 'Troll',    'Troll',     'Troll',     0x01000000 },
							['N'] = { 'Gnome',    'Gnome',     'Gnome',     0x00040000 },
							['O'] = { 'Orc',      'Orc',       'Orc',       0x00200000 },
-- Do not ever use P because it will interfere with SP quest code
							['T'] = { 'Tauren',   'Tauren',    'Tauren',    0x00800000 },
							['U'] = { 'Scourge',  'Undead',    'Undead',    0x00400000 },
							}
						self.bitMaskRaceAll = 0x01e78000
						if self.existsClassicWrathOfTheLichKing or self.existsClassicCataclysm or self.existsClassicPandaria then
							self.races['B'] = { 'BloodElf', 'Blood Elf', 'Blood Elf', 0x02000000 }
							self.races['D'] = { 'Draenei',  'Draenei',   'Draenei',   0x00080000 }
							self.bitMaskRaceAll = 0x03ef8000
						end
						if self.existsClassicPandaria then
							self.races['A'] = { 'Pandaren', 'Pandaren',  'Pandaren',  0x08000000 }
							self.bitMaskRaceAll = 0x0BEF8000
						end
						--	To make things a little prettier, because we are using phase 0000 to represent the location of the Darkmoon Faire we
						--	define the map area for 0000 to be that.
						self.mapAreaMapping[0] = self.holidayMapping['F']
						
						--	For the Classic setup for Darkmoon Faire we have a special holiday which will use the same name
						self.holidayMapping['G'] = self.holidayMapping['F']

					end

					if self.battleForAzeroth then
						self.zonesForLootingTreasure = {
							[1]   = true, -- Durotar
							[14]  = true, -- Arathi
							[17]  = true, -- Blasted Lands
							[23]  = true, -- Western Plaguelands
							[24]  = true, -- Lights Hope Chapel, Western Plaguelands, Paladin Order Hall, Legion
							[25]  = true, -- Hillsbrad Foothils
							[26]  = true, -- The Hinterlands
							[37]  = true, -- Elwynn Forest
							[42]  = true, -- Deadwind Pass
							[46]  = true, -- Catacombs of Karazhan (Warlock Legion Artifact)
							[47]  = true, -- Duskwood
							[49]  = true, -- Redrige Mountains
							[62]  = true,
							[64]  = true, -- Thousand Needles
							[69]  = true, -- Felwood
							[71]  = true, -- Tanaris
							[77]  = true, -- Ashenvale
							[80]  = true, -- Moonglade
							[81]  = true, -- Silithus
							[85]  = true, -- Ogrimmar
							[86]  = true, -- Ogrimmar - Cleft of Shadow
							[107] = true, -- Nagrand
							[109] = true, -- Netherstorm
							[114] = true, -- Borean Tundra, WotLK
							[115] = true, -- Dragonblight, WotLK
							[116] = true, -- Grizzly Hills, WotLK
							[117] = true, -- Howling Fjord, WotLK
							[118] = true, -- Icecrown Citadel (DK intro), WotLK
							[119] = true, -- Sholazar Basin, WotLK
							[121] = true, -- Zul'Drak, WotLK
							[170] = true, -- Hrothgar's Landing, WotLK
							[185] = true, -- Hyjal
							[198] = true, -- Hyjal
							[204] = true, -- Vashj'ir: Abyssal Depths
							[205] = true, -- Vashj'ir: Shimmering Flats
							[210] = true, -- Stranglethorn Cape
							[217] = true, -- Ruins of Gilneas
							[241] = true, -- Twilight Highlands
							[249] = true, -- Uldum, Cataclysm
							[310] = true, -- Silverpine Forest - Shadowfang Keep (Dungeon)
							[327] = true, -- Ahn'Qiraj: The Fallen Kingdom
							[371] = true, -- Jade Forest, MoP
							[376] = true, -- Valley of the Four Winds, MoP
							[378] = true, -- Wandering Isle, MoP
							[379] = true, -- Kun-Lai Summit, MoP
							[388] = true, -- Townlong Steppes, MoP
							[389] = true, -- Townlong Steppes Nizuao Temple, MoP
							[429] = true, -- Temple of the Jade Serpent, MoP
							[433] = true, -- The Veiled Stairs, MoP
							[439] = true, -- Trueshot Lodge, Highmountain , Hunter Order Hall, Legion
							[525] = true, -- Frostfire Ridge, WoD
							[534] = true, -- Tanaan Jungle, WoD
							[535] = true, -- Talador, WoD
							[539] = true,
							[542] = true, -- Spires of Arrak, WoD
							[543] = true,
							[550] = true, -- Nagrand, WoD
							[554] = true, -- Timeless Isle, MoP
							[619] = true, -- Broken Isles, Legion
							[625] = true,
							[626] = true, -- Dalaran:Legion: Rogue Class Hall
							[627] = true, -- Dalaran
							[628] = true, -- Dalaran -- Shadow Site
							[629] = true, -- Dalaran --Aegwynns Gallery
							[630] = true, -- Legion: Aszuna
							[631] = true, -- Legion: Aszuna, Academy of Nar'thalas
							[634] = true, -- Legion: Stormheim
							[641] = true, -- Legion: Val'shara
							[646] = true, -- Legion: Broken Shore
							[648] = true, -- Legion: Acherus, DK Order Hall
							[649] = true, -- Legion: Stormheim-Helheim
							[650] = true, -- Legion: Highmountain
							[657] = true, -- Legion: Highmountain - Neltharions Vault
							[672] = true, -- Mardum , DH Startzone
							[673] = true, -- Cryptic Hollow - Mardum , DH Startzone
							[674] = true, -- The Soul Engine (lower Floor) - Mardum , DH Startzone
							[675] = true, -- The Soul Engine (upper Floor) - Mardum , DH Startzone
							[676] = true, -- Legion: Broken Shore (Warrior Campaign)
							[677] = true, -- Illidari Ward, Vault of the Wardens, DH Startzone
							[678] = true, -- Vault of the Wardens, DH Startzone
							[679] = true, -- Warden's Court, Vault of the Wardens, DH Startzone
							[680] = true, -- Suramar, Legion
							[682] = true, -- Devil Soul Bastion, Suramar , Legion
							[683] = true, -- Das Arkusgewölbe, Suramar , Legion
							[684] = true, -- The Epicenter - Temple of Fal'adora, Suramar, Legion
							[685] = true, -- The Epicenter - Tunnel of Falanaar, Suramar, Legion
							[686] = true, -- Elor'shan ,Suramar, Legion
							[688] = true, -- Leystation Anora, Suramar, Legion
							[690] = true, -- Leystation Aethenar, Suramar, Legion
							[692] = true, -- Withered Army Training - Tunnel of Falanaar, Suramar, Legion
							[693] = true, -- Withered Army Training - Falanaar, Suramar, Legion
							[695] = true, -- Skyhold, Warrior Order Hall, Legion
							[702] = true, -- Netherlight Temple, Priest Order Hall, Legion
							[704] = true, -- Halls of Valor, Stormheim, Legion
							[709] = true, -- The Wandering Isle, Monk Order Hall, Legion
							[711] = true, -- Vault of the Wardens Dungeon, Legion
							[713] = true, -- Eye of Azshara Dungeon , Legion
							[714] = true, -- Niskara, DK Blood Artifact , Legion
							[715] = true, -- Emerald Dreamway, Druid Artifact quest, Legion
							[716] = true, -- Skywall, Monk artifact campaign
							[714] = true, -- Dreadscar Rift, Summoning Area -- Warlock Legion Campaign
							[718] = true, -- Dreadscar Rift -- Warlock Legion Campaign
							[720] = true, -- Mardum , DH Order Hall, Legion
							[724] = true, -- Maelstrom, Abyssal Halls, Shaman Restoration Artifact questchain, Legion
							[725] = true, -- Maelstrom, Legion
							[726] = true, -- Maelstrom, Shaman Order Hall, Legion
							[729] = true, -- Maelstrom, Shaman Doomhammer Quest line (Maelstrom/Bruchtiefen), Legion
							[735] = true, -- Hall of the Guardians, Mage Order Hall, Legion
							[737] = true, -- Vortex Pinnacle, Shaman Order Hall quest line , Legion
							[740] = true, -- Shadowblood Citadel - highest level (rogue artifact campaign)
							[745] = true, -- Ulduar, Spark of Imagination (hunter artifact campaign)
							[747] = true, -- Dreamgrove , Druid Order Hall, Legion
							[748] = true, -- Niskara , Priest Order Hall Quests, Legion
							[749] = true, -- The Arcway, Suramar, Legion
							[750] = true,
							[757] = true, -- Ursocs Hideout , Druid guardian artifact, Legion
							[760] = true, -- Malornes Nightmare, Druid order hall campaign, Legion
							[764] = true, -- The Nighthold, Suramar, Legion
							[766] = true, -- The Nighthold-Elisandes Weiten, Suramar, Legion
							[767] = true, -- The Nighthold-Terace of the Shaldorei, Suramar, Legion
							[768] = true, -- The Nighthold-KingsQuarters, Suramar, Legion
							[769] = true, -- The Nighthold-Stieg des Astromanten, Suramar, Legion
							[770] = true, -- The Nighthold-Nachtspitze, Suramar, Legion
							[772] = true, -- The Nighthold-Quell der Nacht, Suramar, Legion
							[773] = true, -- Tol'Barad (legion:warlock campaign)
							[775] = true, -- Battle for Exodar, Legion
							[798] = true, -- The Arcway, Suramar, Scenario edition 43567
							[790] = true,
							[804] = true, -- Scarlet Monastery (Dungeon)
							[826] = true, -- Mage Tower Legion (windwalker) - Höhle der Bluttotems
							[830] = true, -- Legion: Krokuun
							[831] = true, -- Vindicaar: UpperDeck		(Yoshimo: maybe beginning of the quests compared to 830?)					
							[850] = true, -- Tomb Of Sargeras, Legion
							[851] = true, -- Tomb Of Sargeras, Legion
							[852] = true, -- Tomb Of Sargeras, Legion
							[853] = true, -- Tomb Of Sargeras - Maiden of Vigilance , Legion
							[854] = true, -- Tomb Of Sargeras - Chamber of the Avatar , Legion
							[855] = true, -- Tomb Of Sargeras - Felstorm Rift, Legion
							[856] = true, -- Tomb Of Sargeras - Whirling Nether, Legion
							[882] = true, -- Legion: Eredath
							--- 8.x BFA ---

							[885] = true,
							[862] = true, -- Zuldazar (primarily horde)
							[863] = true, -- Nazmir (primarily horde)
							[864] = true, -- Vol'dun (primarily horde)
							[895] = true, -- Tiragarde Sound (primarily alliance)
							[896] = true, -- Drustvar (primarily alliance)
							[942] = true, -- Stormsong Valley (primarily alliance)
							[1165] = true, -- Dazar'Alor (primarily horde)
							--
							[1355] = true, -- Nazjatar 8.2
							[1462] = true, -- Mechagon Island 8.2
							--
							[1469] = true, -- Horrific Vision of Ogrimmar 8.3
							[1470] = true, -- Horrific Vision of Stormwind 8.3
							[1527] = true, -- Uldum 8.3
 							[1530] = true, -- Valley of Eternal Blossoms 8.3
							[1537] = true, -- Alterac Valley (Korraks Revenge)
							[1595] = true, -- Nyalotha 8.3
							[1580] = true, -- Nyalotha RAID EINGANG FURORION
							[1581] = true, -- Nyalotha RAID Annex der Prophezeiung (lvl 2)(Ma'ut)
							[1582] = true, -- Nyalotha RAID Ny'alotha (lvl 3)
							[1590] = true, -- Nyalotha RAID Der Schwarm (lvl 4)
							[1591] = true, -- Nyalotha RAID Terasse der Verwüstung (lvl 5)
							[1593] = true, -- Nyalotha RAID Zwielichtlandung (lvl 7)
							[1594] = true, -- Nyalotha RAID Schlund des Gorma (lvl 8)
							[1595] = true, -- Nyalotha RAID Höhle des Verfalls (lvl 9)
							[1596] = true, -- Nyalotha RAID Kammer der Wiedergeburt (lvl 10)
							[1597] = true, -- Nyalotha RAID Kern der Unendlichen Wahrheiten (lvl 10)

							-- Shadowlands
							[1360] = true, -- IceCrown Citadel 9.0 intro
							[1409] = true, -- Exiles Reach 9.0
							[1525] = true, -- Revendreth 9.0
							[1533] = true, -- Bastion 9.0
							[1536] = true, -- Maldraxxus 9.0
							[1543] = true, -- The Maw 9.0 , during 57690, rescuing prince renathal
							[1550] = true, -- Thorgast, The Maw,   quest 57693
							[1565] = true, -- Ardenweald 9.0
							[1602] = true, -- Icecrown Citadel (DK intro)
							[1648] = true, -- The Maw (intro version) 9.0
							[1666] = true, -- Necrotic Wake 9.0 , (dungeon)
							[1670] = true, -- Oribos 9.0 , TODO: so far no chests and rares
							[1671] = true, -- Oribos 9.0, Part 2 , TODO: so far no chests and rares 
							[1681] = true, -- IceCrown Citadel 9.0 intro
							[1688] = true, -- Hof der Ernter 9.0 , during quest 58086
							[1693] = true, -- Spire Of Ascension 9.0, (dungeon), has quests, hidden and visible
							[1707] = true, -- Bastion: Elyssian Keep 9.0 , TODO: so far no chests and rares
							[1755] = true, -- Schloss Nathria 9.0 , During Quest 57159
							[1912] = true, -- Runecarver, TODO: so far no chests and rares
							[1911] = true, -- Thorgast 9.0  Ring Entrance
							[1631] = true, -- Thorgast 9.0 4 Kaltherzinterstitia Ebene 4
							[1736] = true, -- Thorgast 9.0 4 Kaltherzinterstitia Ebene 1
							[1797] = true, -- Thorgast 9.0 4 Kaltherzinterstitia Ebene 2
							[1712] = true, -- Thorgast 9.0 4 Kaltherzinterstitia Ebene 3
							[1784] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 1
							[1771] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 2
							[1749] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 3
							[1785] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 4
							[1773] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 5
							[1772] = true, -- Thorgast 9.0 Doing quest 60139 LEVEL 6
							[1632] = true, -- Thorgast 9.0 ?2? Kaltherzinterstitia Ebene 1
							[1796] = true, -- Thorgast 9.0 ?2? Kaltherzinterstitia Ebene 5
							[1630] = true, -- Thorgast 9.0 ?2? Kaltherzinterstitia Ebene 6
							[1961] = true, -- Korthia 9.1
							[1970] = true, -- Zereth Mortis
							[2016] = true, -- Tazavesh, the Veiled Market
							-- Dragon Flight
							[940]  = true, -- The Vindikaar . Oberdeck(quest:77408)
							[2109] = true, -- Forbidden Reach: Creche (Evoker)
							[2118] = true, -- Forbidden Reach (Evoker)
							[2022] = true, -- Dragon Isles: The Waking Shores
							[2023] = true, -- Dragon Isles: Ohn'ahran Plains
							[2024] = true, -- Dragon Isles: The Azure Span
							[2025] = true, -- Dragon Isles: Thaldraszus
							[2085] = true, -- Dragon Isles: Thaldraszus - Primalists Tomorrow
							[2112] = true, -- Dragon Isles: Valdrakken
--							[2092] = true, -- Dragon Isles: Northrend Timeline Azmerloth
							[2080] = true, -- Dragon Isles: Neltharus
							[2082] = true, -- Dragon Isles: Halls of Infusion
							[2119] = true, -- Dragon Isles: Gewölbe der Inkarnationen: Primalistenbollwerk
							[2120] = true, -- Dragon Isles: Gewölbe der Inkarnationen: Elementarkonklave
							[2121] = true, -- Dragon Isles: Gewölbe der Inkarnationen: Orkanhauchfels
							[2122] = true, -- Dragon Isles: Gewölbe der Inkarnationen: Gewölbeannäherung
							[2124] = true, -- Dragon Isles: Gewölbe der Inkarnationen: Urzeitliche Konvergenz
							[2151] = true, -- Forbidden Reach (10.0.7)
							[2133] = true, -- Zaralek Cavern (10.1)
							[2165] = true, -- Der Durchgang /Zaralek Cavern (10.1)
							[2166] = true, -- Aberrus, the Shadowed Crucible (Raid) (10.1)
							[2171] = true, -- Aberrus, the Shadowed Crucible (Raid) (quest-edition)(10.1)
							[2173] = true, -- Aberrus, the Shadowed Crucible (Raid) Neltharions Sanctum (quest-edition)(10.1)
							[2174] = true, -- Aberrus, the Shadowed Crucible (Raid) Schneide des Vergessens (quest-edition)(10.1)
							[2184] = true, -- Zaralek Cavern Tiefenschindernest (10.1)
							[2200] = true, -- Emerald Dream (10.2)
							[2239] = true, -- Amirdrassil (10.2)
							[2254] = true, -- Emerald Dream --Hügel der Träume(10.2)

							-- The War Within
							[2255] = true, -- Azj-Kahet
							[2256] = true, -- Azj-Kahet - Lower
							[2213] = true, -- City of Threads
							[2216] = true, -- City of Threads - Lower
							[2215] = true, -- HallowFall /Heilsturz
							[2248] = true, -- Isle of Dorn
							[2339] = true, -- Dornogal
							[2214] = true, -- Ringing Deeps
							[2305] = true, -- Dalaran
							[2321] = true, -- Chamber of Heart Silithus
							[2322] = true, -- Hall of Awakening (earthen-race)
							[2362] = true, -- Blackrock Depths (Raid)
							[2363] = true, -- Blackrock Depths - Gefängnisblock(Raid)
							[2346] = true, -- Undermine
							-- 11.2
							[2371] = true, -- K'aresh
							[2451] = true, -- Arathi Highlands (Catchup Experience Version)

							-- TWW Dungeons (S2)
							[2315] = true, -- Isle of Dorn >Die Brutstätte: Der Brustättenlandeplatz (lvl1)
							[2316] = true, -- Isle of Dorn >Die Brutstätte: Sturmhorst (lvl2)
							[2317] = true, -- Isle of Dorn >Die Brutstätte: Sturmkrähenbrutstätte (lvl3)
							[2318] = true, -- Isle of Dorn >Die Brutstätte: Sturmreiterkaserne (lvl4)
							[2319] = true, -- Isle of Dorn >Die Brutstätte: Einstürzende Sturmhalle (lvl5)
							[2320] = true, -- Isle of Dorn >Die Brutstätte: Verlassene Minen (lvl6)
							[2303] = true, -- Khaz>Schallende Tiefen>Dunkelflammenspalt
							[2335] = true, -- Isle of Dorn > Metbrauerei Glutbräu
							[2308] = true, -- Heilsturz> Priorität der Heligen Flamme: Geweihter Boden (lvl1)
							[2309] = true, -- Heilsturz> Priorität der Heligen Flamme: Priorat der Heiligen Flamme (lvl2)
							[2387] = true, -- Schallende Tiefen > Operation: Schleuse: Die Wasserwerke (lvl1)
							[2388] = true, -- Schallende Tiefen > Operation: Schleuse: Das R.A.S.T.E.R. (lvl2)

							[1683] = true, -- Maldraxxus > Theater der Schmerzen: Theater der Schmerzen (lvl1)
							[1684] = true, -- Maldraxxus > Theater der Schmerzen: Kammer der Eroberung (lvl2)
							[1685] = true, -- Maldraxxus > Theater der Schmerzen: Altäre der Agonie (lvl3)
							[1686] = true, -- Maldraxxus > Theater der Schmerzen: Obere Tunnel des Gemetzels (lv4)
							[1687] = true, -- Maldraxxus > Theater der Schmerzen: Untere Tunnel des Gemetzels (lv4)

							[1490] = true, -- Kul Tiras >Operation: Mechagon: Mechagon (lvl1)
							[1491] = true, -- Kul Tiras >Operation: Mechagon: Das Robodrom (lvl2)
							[1493] = true, -- Kul Tiras >Operation: Mechagon: Abflussrohre (lvl3)
							[1494] = true, -- Kul Tiras >Operation: Mechagon: Die Unterhalde (lvl4)
							[1497] = true, -- Kul Tiras >Operation: Mechagon: Stadt Mechagon (lvl5)
							[1010] = true, -- Mahlstrom> Kezan:Das RIESENFLÖZ!!

							-- TWW: Delves
							[2423] = true, -- Kaz Algar>Schallende Tiefen>Lorenhall>Seitenstraßenschleuse (Lvl1): Eingang
							[2422] = true, -- Kaz Algar>Schallende Tiefen>Lorenhall>Seitenstraßenschleuse (Lvl2): Die Hohen Decks
							[2421] = true, -- Kaz Algar>Schallende Tiefen>Lorenhall>Seitenstraßenschleuse (Lvl3): Die Niedrigen Decks
							[2420] = true, -- Kaz Algar>Schallende Tiefen>Lorenhall>Seitenstraßenschleuse (Lvl4): Die Grube

							[2302] = true, -- Kaz Algar>Schallende Tiefen> Terrorschacht


							-- TWW Raids:
							[2292] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Großes Bollwerk (lvl1)
							[2291] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Die Gärende Grube (lvl2)
							[2293] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Terasse der Majestät (lvl3)
							[2294] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Der Narthex (lvl4)
							[2295] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Die Krone der Schatten (lvl5)
							[2296] = true, --Azj-Kahet> Palast der Nerub'ar (11.0): Die Krone der Schatten - Oberer Bereich (lvl6)

							[2406] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Lorenhall (lvl1)
							[2428] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Forschung und Zerstörung (lvl2)
							[2407] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Das Garbagio (lvl3)
							[2408] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Das Glückliche Herz (lvl4)
							[2411] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Der Pikturm (lvl5)
							[2409] = true, --Schallende Tiefen> Befreiung von Lorenhall (11.1):Das Haus des Chroms (lvl6)
							-- Midnight
							[947]  = true, -- Housing Area
							[2351] = true, -- Klingenschluchtküste
							[2393] = true, -- Silvermoon (Midnight)
							[2395] = true, -- Quel'thalas: Eversong Woods (Midnight)
							[2405] = true, -- Quel'thalas: Voidstorm
							[2413] = true, -- Quel'thalas: Harandar
							[2424] = true, -- Isle of Quel'danas - Isle of Quel'danas
							[2444] = true, -- Isle of Quel'danas - Slayer's Rise
							[2537] = true, -- Isle of Quel'danas? - TODO: Yoshimo: check (internally named "unknown")
							[2565] = true, -- Isle of Quel'danas - Isle of Quel'danas , during the MN intro questchain from Liadrin id:236693
							[2437] = true, -- Quel'thalas: Zul'Aman (Midnight)
							[2536] = true, -- Quel'thalas: Zul'Aman (Midnight): Atal'Aman
							[2432] = true, -- Isle of Quel'danas - Isle of Quel'danas ( while on quest 88719)
							[2565] = true, -- Isle of Quel'danas - Isle of Quel'danas ( while on quest 86834)
							[2579] = true, -- Isle of Quel'danas - Eversong Woods - Gruft von Wartha'nan
							[2438] = true, -- Tirisfal: Scarlet Halls (during 86842)
							[2541] = true, -- The Arcantina
							-- Midnight dungeons
							[2433] = true, -- Silvermoon: Mördergasse: Mördergasse(Level 1)
							[2435] = true, -- Silvermoon: Mördergasse: Schwarzschauer (Level 2)
							[2434] = true, -- Silvermoon: Mördergasse: Terrasse der Auguren (Level 3)
							[2492] = true, -- Eversong Woods: Windrunnter Tower: Die Promenaade (Level 1)
							[2493] = true, -- Eversong Woods: Windrunnter Tower: Vereesas Rast: Oberer Bereich(Level 2)
							[2494] = true, -- Eversong Woods: Windrunnter Tower: Vereesas Rast: Unterer Bereich(Level 3)
							[2496] = true, -- Eversong Woods: Windrunnter Tower: Sylvanas' Gemächer: Oberer Bereich(Level 4)
							[2497] = true, -- Eversong Woods: Windrunnter Tower: Sylvanas' Gemächer: Unterer Bereich(Level 5)
							[2498] = true, -- Eversong Woods: Windrunnter Tower: Windläufergewölbe (Level 6)
							[2499] = true, -- Eversong Woods: Windrunnter Tower: Die Spitze (Level 7)
							-- Midnight Delves
							[2502] = true, -- Eversong Woods: Schattenenklave
							[2575] = true, -- Harandar: Kluft der Erinnerung- Unterer Wurzelpfad

						}

						self.quest.name[51570]=Grail:_GetMapNameByID(862)	-- Zuldazar
						self.quest.name[51571]=Grail:_GetMapNameByID(863)	-- Nazmir
						self.quest.name[51572]=Grail:_GetMapNameByID(864)	-- Vol'dun
						self.quest.name[600000]=Grail:_GetMapNameByID(17)..' '..REQUIREMENTS
						self.quest.name[600001]=Grail:_GetMapNameByID(17)..' '..FACTION_ALLIANCE..' '..REQUIREMENTS
						self.quest.name[600002]=Grail:_GetMapNameByID(17)..' '..FACTION_HORDE..' '..REQUIREMENTS
					end

					--	For users prior to the release version 028, the GrailDatabase held personal quest information.  Now we move that information into the
					--	new structure GrailDatabasePlayer so it can be separated from the information that would be reported.
					if GrailDatabase[self.playerRealm] then
						if GrailDatabase[self.playerRealm][self.playerName] then
							GrailDatabasePlayer["completedQuests"] = GrailDatabase[self.playerRealm][self.playerName]["completedQuests"]
							GrailDatabasePlayer["completedResettableQuests"] = GrailDatabase[self.playerRealm][self.playerName]["completedResettableQuests"]
							GrailDatabasePlayer["actuallyCompletedQuests"] = GrailDatabase[self.playerRealm][self.playerName]["actuallyCompletedQuests"]
							GrailDatabasePlayer["controlCompletedQuests"] = GrailDatabase[self.playerRealm][self.playerName]["controlCompletedQuests"]
							GrailDatabase[self.playerRealm][self.playerName] = nil
						end
						local realmCount = 0
						for n, v in pairs(GrailDatabase[self.playerRealm]) do
							if nil ~= v then realmCount = realmCount + 1 end
						end
						if 0 == realmCount then GrailDatabase[self.playerRealm] = nil end
					end

					GrailDatabasePlayer.completedQuests = GrailDatabasePlayer.completedQuests or {}
					GrailDatabasePlayer.completedResettableQuests = GrailDatabasePlayer.completedResettableQuests or {}
					GrailDatabasePlayer.actuallyCompletedQuests = GrailDatabasePlayer.actuallyCompletedQuests or {}
					GrailDatabasePlayer.controlCompletedQuests = GrailDatabasePlayer.controlCompletedQuests or {}
					GrailDatabasePlayer.abandonedQuests = GrailDatabasePlayer.abandonedQuests or {}
					GrailDatabasePlayer.spellsCast = GrailDatabasePlayer.spellsCast or {}
					GrailDatabasePlayer.buffsExperienced = GrailDatabasePlayer.buffsExperienced or {}
					GrailDatabasePlayer.dailyGroups = GrailDatabasePlayer.dailyGroups or {}
					GrailDatabase.vignetteLinks      = GrailDatabase.vignetteLinks or {}
					GrailDatabase.gossipQuestLinks   = GrailDatabase.gossipQuestLinks or {}
					GrailDatabase.vignetteGuidIndex  = GrailDatabase.vignetteGuidIndex or {}
					GrailDatabase.questPinEvents     = GrailDatabase.questPinEvents or {}
					GrailDatabase.questPinEventIndex = GrailDatabase.questPinEventIndex or {}
					GrailDatabase.questPinLinks      = GrailDatabase.questPinLinks or {}
					GrailDatabase.questPinGuidIndex  = GrailDatabase.questPinGuidIndex or {}
					-- Migrate questPinEventIndex from character to account level
					if GrailDatabasePlayer.questPinEventIndex and next(GrailDatabasePlayer.questPinEventIndex) then
						if not next(GrailDatabase.questPinEventIndex or {}) then
							GrailDatabase.questPinEventIndex = GrailDatabasePlayer.questPinEventIndex
							print(strformat('|cFFFFFF00Grail|r: migrated questPinEventIndex to account level'))
						end
						GrailDatabasePlayer.questPinEventIndex = nil
					end
					-- Migrate questPinGuidIndex from character to account level
					if GrailDatabasePlayer.questPinGuidIndex and next(GrailDatabasePlayer.questPinGuidIndex) then
						if not next(GrailDatabase.questPinGuidIndex or {}) then
							GrailDatabase.questPinGuidIndex = GrailDatabasePlayer.questPinGuidIndex
							print(strformat('|cFFFFFF00Grail|r: migrated questPinGuidIndex to account level'))
						end
						GrailDatabasePlayer.questPinGuidIndex = nil
					end
					-- Migrate gossipQuestLinks from character to account level
					if GrailDatabasePlayer.gossipQuestLinks and next(GrailDatabasePlayer.gossipQuestLinks) then
						if not next(GrailDatabase.gossipQuestLinks or {}) then
							GrailDatabase.gossipQuestLinks = GrailDatabasePlayer.gossipQuestLinks
							print(strformat('|cFFFFFF00Grail|r: migrated gossipQuestLinks to account level'))
						end
						GrailDatabasePlayer.gossipQuestLinks = nil
					end
					-- Migrate questPinLinks from character to account level
					if GrailDatabasePlayer.questPinLinks and next(GrailDatabasePlayer.questPinLinks) then
						if not next(GrailDatabase.questPinLinks or {}) then
							GrailDatabase.questPinLinks = GrailDatabasePlayer.questPinLinks
							print(strformat('|cFFFFFF00Grail|r: migrated questPinLinks to account level'))
						end
						GrailDatabasePlayer.questPinLinks = nil
					end
					-- Migrate vignetteLinks from character to account level
					if GrailDatabasePlayer.vignetteLinks and next(GrailDatabasePlayer.vignetteLinks) then
						if not next(GrailDatabase.vignetteLinks or {}) then
							GrailDatabase.vignetteLinks = GrailDatabasePlayer.vignetteLinks
							print(strformat('|cFFFFFF00Grail|r: migrated vignetteLinks to account level'))
						end
						GrailDatabasePlayer.vignetteLinks = nil
					end
					-- Migrate questPinEvents from character to account level
					if GrailDatabasePlayer.questPinEvents and next(GrailDatabasePlayer.questPinEvents) then
						if not next(GrailDatabase.questPinEvents or {}) then
							GrailDatabase.questPinEvents = GrailDatabasePlayer.questPinEvents
							print(strformat('|cFFFFFF00Grail|r: migrated questPinEvents to account level'))
						end
						GrailDatabasePlayer.questPinEvents = nil
					end
					-- Migrate vignetteGuidIndex from character to account level
					if GrailDatabasePlayer.vignetteGuidIndex and next(GrailDatabasePlayer.vignetteGuidIndex) then
						if not next(GrailDatabase.vignetteGuidIndex or {}) then
							GrailDatabase.vignetteGuidIndex = GrailDatabasePlayer.vignetteGuidIndex
							print(strformat('|cFFFFFF00Grail|r: migrated vignetteGuidIndex to account level'))
						end
						GrailDatabasePlayer.vignetteGuidIndex = nil
					end

					-- See if we can load LibArtifactData
--					local LibStub = _G["LibStub"]
--					if LibStub then
--						self.LAD = LibStub("LibArtifactData-1.0", true)
--						if nil ~= self.LAD then
--							--	Note that reading the scroll to raise the artifact knowledge level does not trigger this event
--							self.LAD.RegisterCallback(self, "ARTIFACT_KNOWLEDGE_CHANGED", "ArtifactChange")
--						end
--					end

					for i = 1, self.invalidateGroupHighestValue do
						self.invalidateControl[i] = {}
					end

-- This was causing problems with ElvUI and is removed since we don't do this.
--					if self.capabilities.usesArtifacts then
--						self:LoadAddOn("Blizzard_ArtifactUI")
--					end

					--
					--	Create the tooltip that we use for getting information like NPC name
					--
					self.tooltip = CreateFrame("GameTooltip", "com_mithrandir_grailTooltip", UIParent, "GameTooltipTemplate")
					self.tooltip:SetFrameStrata("TOOLTIP")
					self.tooltip:Hide()

					self.tooltipNPC = CreateFrame("GameTooltip", "com_mithrandir_grailTooltipNPC", UIParent, "GameTooltipTemplate")
					self.tooltipNPC:SetFrameStrata("TOOLTIP")
					self.tooltipNPC:Hide()

					-- This needs to be done after the tooltipNPC is created because it uses NPC names for some quests.
					if self.forceLocalizedQuestNameLoad then
						self:LoadLocalizedQuestNames()
					end

					--
					--	Set up the slash command
					--
					SlashCmdList["GRAIL"] = function(msg)
						self:_SlashCommand(frame, msg)
					end
					SLASH_GRAIL1 = "/grail"

					--
					--	For verification of NPC information the tooltips can return a string
					--	that indicates the server is being queried.  Therefore, we record the
					--	localized version of it here so it can be used in comparisons.
					--
					if self.playerLocale == "enUS" or self.playerLocale == "enGB" then
						self.retrievingString = "Retrieving item information"
					elseif self.playerLocale == "deDE" then
						self.retrievingString = "Frage Gegenstandsinformationen ab"
					elseif self.playerLocale == "esES" or self.playerLocale == "esMX" then
						self.retrievingString = "Obteniendo información de objeto"
					elseif self.playerLocale == "frFR" then
						self.retrievingString = "Récupération des informations de l'objet"
					elseif self.playerLocale == "itIT" then
    				   self.retrievingString = "Recupero dati oggetto"
					elseif self.playerLocale == "koKR" then
						self.retrievingString = "아이템 정보 검색"
					elseif self.playerLocale == "ptBR" then
						self.retrievingString = "Recuperando informações do item"
					elseif self.playerLocale == "ruRU" then
						self.retrievingString = "Получение сведений о предмете"
					elseif self.playerLocale == "zhTW" then
						self.retrievingString = "讀取物品資訊"
					elseif self.playerLocale == "zhCN" then
						self.retrievingString = "正在获取物品信息"
					else
						self.retrievingString = "Unknown"
					end

					--
					--	Blizzard has changed the way one queries to determine what quests are complete.
					--	Prior to Mists of Pandaria the architecture required a call to be made to the
					--	server, and when the server was ready it would post an event.  Processing based
					--	on that event allowed the server's view of completed quests to be known.  With
					--	Mists of Pandaria, the architecture changed on Blizzard's side.  However, this
					--	addon needed to operate in both the prerelease of MoP and the live version with
					--	the two different server query architectures.  So instead of changing the way
					--	Grail works, Grail detects the API changes in the Blizzard environment and does
					--	the right things, allowing the same addon to work in both environments.
					--
					if nil == QueryQuestsCompleted then
						QueryQuestsCompleted = function() Grail:_ProcessServerQuests() end
					end
					if nil == GetQuestsCompleted then
						GetQuestsCompleted = function(t)
							if C_QuestLog.GetAllCompletedQuestIDs then
								-- Assumes returns a table of integers that are the completed quests.
								local completedQuests = C_QuestLog.GetAllCompletedQuestIDs()
								if completedQuests then
									for k, v in pairs(completedQuests) do
										t[v] = true
									end
								end
							else
								for questId in pairs(Grail.questCodes) do
									if self:IsQuestFlaggedCompleted(questId) then
										t[questId] = true
									end
								end
							end
						end
					end

					--	For the choice of types of quest on Isle of Thunder the following function is eventually
					--	called with anId which is associated with the button in the UI.
					if SendQuestChoiceResponse then
						hooksecurefunc("SendQuestChoiceResponse", function(anId) self:_SendQuestChoiceResponse(anId) end)
					elseif SendPlayerChoiceResponse then
						hooksecurefunc("SendPlayerChoiceResponse", function(anId) self:_SendQuestChoiceResponse(anId) end)
					elseif C_PlayerChoice and C_PlayerChoice.SendPlayerChoiceResponse then
						hooksecurefunc(C_PlayerChoice, "SendPlayerChoiceResponse", function(anId) self:_SendQuestChoiceResponse(anId) end)
					else
						if self.GDE.debug then
							print("Grail did not replace any SendQuestChoiceResponse")
						end
					end

					self:_QuestCompleteCheckObserve(Grail.GDE.debug)
					self:_QuestAcceptCheckObserve(Grail.GDE.debug)
					self:_LevelGainedQuestCheckObserve(Grail.GDE.debug)

					--	Specific quests become available when certain interactions are done with specific NPCs so
					--	we use this routine in conjunction with the GOSSIP_SHOW and GOSSIP_CLOSED events to determine
					--	if we are to do anything.  GOSSIP_SHOW will record the NPC and GOSSIP_CLOSED will reset it.
					if nil ~= SelectGossipOption then -- workaround for Shadowlands
					hooksecurefunc("SelectGossipOption", function(index, text, confirm)
						-- >>>QUESTPIN_DEBUG: capture pool snapshot before gossip quest completes
						if not self._questPinSnapshotBefore then
							-- Use persistent snapshot as before-state: pool pin may be gone already
							self._questPinSnapshotBefore = self._persistentPinSnapshot or self:_QuestPinPoolSnapshot()
							self._questPinTrigger       = 'GOSSIP_COMPLETE'
							self._questPinTriggerDetail = strformat('gossipIndex=%d', index)
						end
						-- >>>QUESTPIN_DEBUG_END
						local questToComplete = nil
						local gossipTable = self.currentGossipNPCId and self.gossipNPCs[self.currentGossipNPCId] or nil
						if gossipTable then
							if gossipTable[index] then
								-- gossipTable[index] should have two items: [1] the questId, [2] any prerequisites required
								-- if the prerequisites are empty or evaluate to true then questToComplete gets set to the questId
								local prereqs = gossipTable[index][2]
								if nil == prereqs or ("table" == type(prereqs) and 0 == #prereqs) or self:_AnyEvaluateTrueF(prereqs, nil, Grail._EvaluateCodeAsPrerequisite) then
									questToComplete = gossipTable[index][1]
								end
							end
						end
						-- >>>GOSSIP_DEBUG
						-- Store selected option on context for CLOSED_COMPLETE
						if self._gossipDebugContext then
							if C_GossipInfo and C_GossipInfo.GetOptions then
								local _opts = C_GossipInfo.GetOptions()
								if _opts and _opts[index] then
									self._gossipDebugContext.lastOptionName = _opts[index].name
									self._gossipDebugContext.lastOptionID   = _opts[index].gossipOptionID
								end
							end
						end
						-- Capture the gossip option text for this index
						local _optionName = nil
						local _optionID   = nil
						if C_GossipInfo and C_GossipInfo.GetOptions then
							local opts = C_GossipInfo.GetOptions()
							if opts and opts[index] then
								_optionName = opts[index].name
								_optionID   = opts[index].gossipOptionID
							end
						end
						if nil ~= questToComplete then
							local ctx = self._gossipDebugContext
							local msg = strformat('GOSSIP_DEBUG QUEST_COMPLETE: quest=%d npc=%s(%s) option=%s(id=%s) coords=%s',
								questToComplete, tostring(ctx and ctx.targetName), tostring(ctx and ctx.npcId),
								tostring(_optionName), tostring(_optionID), tostring(ctx and ctx.coordinates))
							print(msg)
							self:_AddTrackingMessage(msg)
							self:_RecordGossipQuestLink(questToComplete,
								ctx and ctx.npcId, ctx and ctx.targetName,
								_optionName, _optionID, ctx and ctx.coordinates)
						end
						-- >>>GOSSIP_DEBUG_END
						if nil ~= questToComplete then
							self:_MarkQuestComplete(questToComplete, true)
						end
						-- >>>GOSSIP_DEBUG: check for quest triggered by selecting this option
						do
							local _sv, _mv = self.GDE.silent, self.manuallyExecutingServerQuery
							self.GDE.silent, self.manuallyExecutingServerQuery = true, false
							QueryQuestsCompleted()
							local _nc = {}
							self:_ProcessServerCompare(_nc)
							for _, qId in pairs(_nc) do
								if qId ~= questToComplete then self:_MarkQuestComplete(qId, true) end
								local ctx = self._gossipDebugContext
								local msg = strformat('GOSSIP_DEBUG SELECT_COMPLETE: quest=%d npc=%s(%s) option=%s(id=%s) coords=%s',
									qId, tostring(ctx and ctx.targetName), tostring(ctx and ctx.npcId),
									tostring(_optionName), tostring(_optionID), tostring(ctx and ctx.coordinates))
								print(msg)
								self:_AddTrackingMessage(msg)
								self:_RecordGossipQuestLink(qId,
									ctx and ctx.npcId, ctx and ctx.targetName,
									_optionName, _optionID, ctx and ctx.coordinates)
							end
							self.GDE.silent, self.manuallyExecutingServerQuery = _sv, _mv
						end
						-- >>>GOSSIP_DEBUG_END
					end)
					end

					--
					--	The basic quest information is loaded from a file.  However, we need to create internal structures
					--	that are used as caches to ensure processing of information is done as quickly as possible.  Here
					--	we set up the basic structures that hold information outside of the quests themselves.
					--
					if nil == self.questStatusCache then
						-- quests is a table whose indexes are questIds and values are the actual bit mask status
						-- A is a table whose key is an achievement ID and whose value is a table of quests assocaited with it
						-- B is a table whose key is a buff ID and whose value is a table of quests associated with it
						-- C is a table whose key is an item ID whose presence is needed and whose value is a table of quests associated with it
						-- D is a table whose indexes are questIds and values are tables of questIds that need to be invalidated when the index is no longer in the quest log
						-- E is a table whose key is an item ID whose presence is NOT wanted and whose value is a table of quests associated with it
						-- F is a table whose key is a questId that when abandoned needs to have the table of associated quests invalidated
						-- G is a table whose key is a group number and whose value is a table of quests associated with it
						-- H is a table whose key is a questId and whose value is a table of groups associated with it
						-- I is a table whose indexes are questIds and values are tables of questIds that suffer bitMaskInvalidated from the quest that is the index
						-- J is a table whose key is a group number and whose value is a table of quests associated with it (weekly instead of daily "G")
						-- K is a table whose key is a questId and whose value is a table of groups associated with it (weekly instead of daily "H")
						-- L is a table of questIds who fail because of bitMaskLevelTooLow
						-- M is a table of questIds that require garrison buildings
						-- P is a table of questIds who fail because of bitMaskProfession
						-- Q is a table whose indexes are questIds and values are tables of questIds that suffer bitMaskPrerequisites from the quest that is the index
						-- R is a table of questIds who fail because of bitMaskReputation
						-- S is a table whose key is a spellId whose presence is needed and whose value is a table of quests associated with it
						-- V is a table of questIds for quests that are NOT marked bitMaskLowLevel because gaining levels can change that value
						-- W is a table whose key is a group number and whose value is a table of quests interested in that group.  this differs from G because that is a list of all quests in the group
						-- X is a table whose key is a group number and whose value is a table of quests interested in that group for accepting.
						-- Y is a table whose key is a spellId that has ever been experienced and whose value is a table of quests associated with it
						-- Z is a table whose key is a spellId that has ever been cast and whose value is a table of quests associated with it
						self.questStatusCache = { ["A"] = {}, ["B"] = {}, ["C"] = {}, ["D"] = {}, ["E"] = {}, ["F"] = {}, ["G"] = {}, ["H"] = {}, ["I"] = {}, ["J"] = {}, ["K"] = {}, ["L"] = {}, ["M"] = {}, ["P"] = {}, ["Q"] = {}, ["R"] = {}, ["S"] = {}, ["V"] = {}, ["W"] = {}, ["X"] = {}, ["Y"] = {}, ["Z"] = {},
							["questToItemCountGroup"] = {},	-- this contains all the groups to which quests have interest, probably only one in reality
							["itemCountGroupToQuest"] = {},	-- this contains a table of questId and the count of the item needed for that quest
							}
						self.npcStatusCache = { ["A"] = {}, ["B"] = {}, ["C"] = {}, ["D"] = {}, ["E"] = {}, ["F"] = {}, ["G"] = {}, ["H"] = {}, ["I"] = {}, ["J"] = {}, ["K"] = {}, ["L"] = {}, ["M"] = {}, ["P"] = {}, ["Q"] = {}, ["R"] = {}, ["S"] = {}, ["V"] = {}, ["W"] = {}, ["X"] = {}, ["Y"] = {}, ["Z"] = {}, }
					end
					-- Contemplate switching the questStatusCache keys to make use of the quest prerequisite codes, with further refinement probably using numerals since
					-- they are not used as prerequisite codes.
--      Possible codes for prerequisite info:
--		(if no code present A assumed for P: and C is assumed for I: and B:)
--			A   quest must be turned in
--			a	world quest must be available
--			B   quest must be in log
--			C   quest must be in log or turned in
--			c	quest must NOT be in log and NOT turned in
--			D   quest must be completed in log
--			E   quest must be completed in log or turned in
--			e	quest must be in log but not completed or not turned in
--			Fx	must belong to faction x where A is Alliance and H is Horde
--			Gbbbbppp	building bbbb (with negative meaning any of that type) present in garrison, with optional ppp plot location required
--			H   quest has ever been completed
--			I   spell effect present
--			i	spell effect NOT present
--			J   achievement completed
--			j	achievement NOT completed
--			K	item possessed
--			k	item NOT possessed
--			Lxxx	player level must be >= xxx
--			lxxx	player level must be < xxx
--			M	quest has been abandoned at least once
--			m	quest has never been abandoned
--			Nx	where x is the key to a required class (see classMapping).
--			nx	where x is the key to a forbidden class (see classMapping).
--			O	quest must be accepted
--			Pxyyy	profession x (see professionMapping) must have a skill value of at least yyy
--			Qxxxx	the equipped iLvl must be >= xxxx
--			qxxxx	the equipped iLvl must be < xxxx
--			R	spell effect has ever been present
--			S	skill possessed (where the value is Blizzard's spell ID of the skill)
--			s	skill not possessed (where the value is Blizzard's spell ID of the skill)
--			Txxxyyyyy	reputation xxx must be at least yyyyy value
--			txxxyyyyy	reputation xxx must be under yyyyy value
--			Uxxxyyyyy	frienship reputation xxx must be at least yyyyy value -- used for withering
--			uxxxyyyyy	frienship reputation xxx must be under yyyyy value -- used for withering
--			Vxxxy	quest group xxx must have y quests accepted
--			vxxxxx	quest must have been turned in prior to the previous weekly reset
--			Wxxxy	quest group xxx must have y quests completed (turned in)
--			wxxxy	quest group xxx must have y quests completed in log or turned in
--			X	quest must not be turned in
--			xyy	artifact knowledge level must be at least yy
--			Y	achievement completed by this player
--			y	achievement NOT completed by this player
--			Z	spell has ever been cast by player
--			zbbbb	building bbbb (with negative meaning any of that type) needs a worker	[I will eventually unify the letters above properly to free one instead of using 'z']
--			=zzzzp	the current phase in zone zzzz must be phase p
--			>zzzzp	the current phase in zone zzzz must be more than phase p
--			<zzzzp	the current phase in zone zzzz must be less than phase p
--			!xxxx	the NPC represented by xxxx needs to be killed		*** implement this ***
--			?xxxx	when zone xxxx is entered	*** implement this ***
--			@yyyxxxx	artifact item ID xxxx must be >= level y	*** implement this ***
--			#xxx	the item represented by xxx needs to be available in a class hall mission
--			$xyy	renown with covenant x must be at least yy
--				0=any, 1=Kyrian, 2=Venthyr, 3=NightFae, 4=Necrolord
--			^	calling quest must be available
--			&xxx	Azerite level is at least
--			%xxxx	garrison (covenant) talent must be researched
--			*xyy	renown with covenant x must be less than yy
--			(xxx	quest xxx must be completed prior to today's reset
--			)xxxxyyy	currency xxxx must equal or exceed yyy

					-- Create some convenience tables
					self.raceNameToBitMapping = {}
					for code, raceTable in pairs(self.races) do
						local raceName = raceTable[1]
						self.raceNameToBitMapping[raceName] = self.races[code][4]
					end
					self.classNameToBitMapping = {}
					self.classBitToCodeMapping = {}
					self.classNameToCodeMapping = {}
					for code,className in pairs(self.classMapping) do
						self.classNameToBitMapping[className] = self.classToBitMapping[code]
						self.classBitToCodeMapping[self.classToBitMapping[code]] = code
						self.classNameToCodeMapping[className] = code
					end
					self.holidayBitToCodeMapping = {}
					for code,bitValue in pairs(self.holidayToBitMapping) do
						self.holidayBitToCodeMapping[bitValue] = code
					end
					--	Set up some copies of holidays that will be altered based on release names
					self.holidayMapping['g'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME1
					self.holidayMapping['h'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME2
					self.holidayMapping['i'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME3
					self.holidayMapping['j'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME4
					self.holidayMapping['k'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME5
					self.holidayMapping['l'] = self.holidayMapping['f'] .. ' - ' .. EXPANSION_NAME6
					self.reverseHolidayMapping = {}
					for index, holidayName in pairs(self.holidayMapping) do
						self.reverseHolidayMapping[holidayName] = index
					end
					self.reverseProfessionMapping = {}
					for index, professionName in pairs(self.professionMapping) do
						self.reverseProfessionMapping[professionName] = index
					end

					-- Set up some reputation processing code
					-- We use the Blizzard API to get the names of the factions instead of maintaining them internally ourselves which we used to do
					local reputationIndex
					for hexIndex, _ in pairs(self.reputationMapping) do
						reputationIndex = tonumber(hexIndex, 16)
						local name = self:GetFactionInfoByID(reputationIndex)
						if nil == name and self.capabilities.usesFriendshipReputation then
							local id, rep, maxRep, friendName, text, texture, reaction, threshold, nextThreshold = self:GetFriendshipReputation(reputationIndex)
							if friendName == nil then
--								name = "*** UNKNOWN " .. reputationIndex .. " ***"
--								if self.reputationMapping[hexIndex] then
--									name = name .. " (" .. self.reputationMapping[hexIndex] .. ")"
--								end
							else
								name = friendName
							end
						end
						if nil ~= name then
							self.reputationMapping[hexIndex] = name
						end
					end
					self.reverseReputationMapping = {}
					for index, repName in pairs(self.reputationMapping) do
						self.reverseReputationMapping[repName] = index
					end

					self:_LoadContinentData()

--					self:LoadAddOn("Grail-Quests")
					local originalMem = gcinfo()
--					if self:LoadAddOn("Grail-NPCs") then
						self:_ProcessNPCs(originalMem)
--					end
--					self:LoadAddOn("Grail-NPCs-" .. self.playerLocale)
					self.npc.name[1] = ADVENTURE_JOURNAL

					-- Now we need to update some information based on the server to which we are connected
					if self.portal == "eu" or self.portal == "EU" then
						-- The following quests are not available on European servers
						local bannedQuests = {11117, 11118, 11120, 11431}
						for _, questId in pairs(bannedQuests) do
--							self.questNames[questId] = nil
							self.questCodes[questId] = nil
							self.quests[questId] = nil	--	Don't really need to do this since self.quests is not populated until after this (currently at least)
						end
					end

					-- Precompute the bit masks associated with things that cannot change so future access will be faster
					self.playerClassBitMask = self.classNameToBitMapping[self.playerClass]
					self.playerRaceBitMask = self.raceNameToBitMapping[self.playerRace]
					self.playerFactionBitMask = ('Horde' == self.playerFaction) and self.bitMaskFactionHorde or self.bitMaskFactionAlliance
					self.playerGenderBitMask = (3 == self.playerGender) and self.bitMaskGenderFemale or self.bitMaskGenderMale

					-- Create the indexed quest list up front so future requests are much faster
					self:CreateIndexedQuestList()

					-- Now take all the unnamed zones we determined from NPCs and add them to Grail.otherMapping
					-- and find their names
					self.otherMapping = {}
					local otherCount = 0
					local mapName
					for mapId in pairs(self.unnamedZones) do
						-- It turns out that Blizzard API is a little weird in that, for example, Teldrassil is a zone in Kalimdor, but
						-- when you ask for all the Kalimdor zones it is not listed.  Therefore, we have to do some work to find the
						-- zone for each of these zones and put them in their proper place.
						local continentInfo = MapUtil.GetMapParentInfo(mapId, Enum.UIMapType.Continent, true)
						local mapInfo = C_Map.GetMapInfo(mapId)
						local targetTable = nil ~= continentInfo and self.continents[continentInfo.mapID] and self.continents[continentInfo.mapID].zones or nil
						if nil ~= continentInfo and nil ~= mapInfo and nil ~= targetTable then
							self:_AddMapId(targetTable, mapInfo.name, mapInfo.mapID, continentInfo.mapID)
						else
							mapName = self:_GetMapNameByID(mapId)
							if "" ~= mapName then
								local nameToUse = mapName
								while nil ~= self.zoneNameMapping[nameToUse] do
									nameToUse = nameToUse .. ' '
								end
								self.zoneNameMapping[nameToUse] = mapId
								otherCount = otherCount + 1
								self.otherMapping[otherCount] = mapId
							else
								if self.GDE.debug then print("Grail found no name for mapId", mapId) end
							end
						end
					end

					-- Now we need to make a reverse mapping table that maps map area IDs into localized zone names.
					for zoneName, mapId in pairs(self.zoneNameMapping) do
						if nil == self.mapAreaMapping[mapId] then self.mapAreaMapping[mapId] = zoneName end
						-- Also create the "self" NPCs that are specific to each zone
						if nil == self.npc.nameIndex[0 - mapId] then
							self.npc.nameIndex[0 - mapId] = 0
							local t = {}
							t.mapArea = mapId
							self.npc.locations[0 - mapId] = { t }
						end
					end

					-- We need to be notified when any of these happen so we can update the quest status caches properly
					self:RegisterObserverQuestAbandon(Grail._StatusCodeCallback)
					self:RegisterObserverQuestAccept(Grail._StatusCodeCallback)
					self:RegisterObserverQuestComplete(Grail._StatusCodeCallback)

					self:RegisterObserver("CloseTradeSkillUI", Grail._CloseTradeSkillUI)

					-- Starting with Grail 100 all the preferences are stored within an environment so we can differentiate
					-- between _retail_, _ptr_, and _classic_ which is really going to be used for quest/NPC information
					-- primarily, but extends to all Grail preferences stored in GrailDatabase.  Therefore, the older data
					-- is moved the first time into the current environment only.
					local databaseKeys = {"delayEventsHandled", "delayEvents", "silent", "debug", "tracking", "notLoot", "learned", "Tracking", "eek"}
					for i = 1, #databaseKeys do
						if nil ~= GrailDatabase[databaseKeys[i]] then
							self.GDE[databaseKeys[i]] = GrailDatabase[databaseKeys[i]]
							GrailDatabase[databaseKeys[i]] = nil
						end
					end

					-- We are defaulting to making events in combat delayed, and only doing it once in case the user decides to override.
					if nil == self.GDE.delayEventsHandled then
						self.GDE.delayEvents = true
						self.GDE.delayEventsHandled = true
					end

					--	Ensure the tooltip is not messed up
					if not self.tooltip:IsOwned(UIParent) then self.tooltip:SetOwner(UIParent, "ANCHOR_NONE") end

					self:RegisterSlashOption("events", "|cFF00FF00events|r => toggles delaying events in combat on and off, printing new value", function()
						Grail.GDE.delayEvents = not Grail.GDE.delayEvents
						print(strformat("Grail delays events in combat now %s", Grail.GDE.delayEvents and "ON" or "OFF"))
					end)
					self:RegisterSlashOption("silent", "|cFF00FF00silent|r => toggles silent startup on and off, printing new value", function()
						Grail.GDE.silent = not Grail.GDE.silent
						print(strformat("Grail silent startup for this player now %s", Grail.GDE.silent and "ON" or "OFF"))
					end)
					self:RegisterSlashOption("debug", "|cFF00FF00debug|r => toggles debug on and off, printing new value", function()
						Grail.GDE.debug = not Grail.GDE.debug
						Grail:_QuestCompleteCheckObserve(Grail.GDE.debug)
						Grail:_QuestAcceptCheckObserve(Grail.GDE.debug)
						Grail:_LevelGainedQuestCheckObserve(Grail.GDE.debug)
						print(strformat("Grail Debug now %s", Grail.GDE.debug and "ON" or "OFF"))
					end)
					self:RegisterSlashOption("treasures", "|cFF00FF00treasures|r => toggles treasures on and off, printing new value", function()
						Grail.GDE.treasures = not Grail.GDE.treasures
						print(strformat("Grail Debug Treasures now %s", Grail.GDE.treasures and "ON" or "OFF"))
					end)
					self:RegisterSlashOption("target", "|cFF00FF00target|r => gets target information (NPC ID and your current location)", function()
						local targetName, npcId, coordinates = self:TargetInformation()
						local message = strformat("%s (%d) %s", targetName and targetName or 'nil target', npcId and npcId or -1, coordinates and coordinates or 'no coords')
						print(message)
						self:_AddTrackingMessage(message)
					end)
					self:RegisterSlashOption("c ", "|cFF00FF00c|r |cFFFF8C00msg|r => adds the |cFFFF8C00msg|r to the tracking data", function(msg)
						self:_AddTrackingMessage(strsub(msg, 3))
					end)
					self:RegisterSlashOption("comment ", "|cFF00FF00comment|r |cFFFF8C00msg|r => adds the |cFFFF8C00msg|r to the tracking data", function(msg)
						self:_AddTrackingMessage(strsub(msg, 9))
					end)
					self:RegisterSlashOption("tracking", "|cFF00FF00tracking|r => toggles tracking on and off, printing new value", function()
						Grail.GDE.tracking = not Grail.GDE.tracking
						print(strformat("Grail Tracking now %s", Grail.GDE.tracking and "ON" or "OFF"))
						self:_UpdateTrackingObserver()
					end)
					self:RegisterSlashOption("loot", "|cFF00FF00loot|r => toggles loot event processing on and off, printing new value", function()
						Grail.GDE.notLoot = not Grail.GDE.notLoot
						print(strformat("Grail Loot Event Processing now %s", Grail.GDE.notLoot and "OFF" or "ON"))
						if Grail.GDE.notLoot then
							Grail.notificationFrame:UnregisterEvent("LOOT_CLOSED")
						else
							Grail.notificationFrame:RegisterEvent("LOOT_CLOSED")
						end
					end)
					self:RegisterSlashOption("pins", "|cFF00FF00pins|r => lists quest pins discovered this session that were not previously recorded", function()
						local locs = self.GDE.observedQuestLocations
						if not locs then
							print("Grail: no quest pins recorded yet — open the world map and browse some zones")
							return
						end
						local count = 0
						for questID, loc in pairs(locs) do
							if not self.sessionStartQuestPins[questID] then
								count = count + 1
								local name = self.quest.name[questID]
								if not name then
									local title = C_QuestLog.GetQuestInfo(questID)
									name = title or "?"
								end
								local mapName = self:_GetMapNameByID(loc.mapID)
								print(strformat("|cFFFF8C00Q%d|r %s  |cFF808080[%s]|r x=%.4f y=%.4f", questID, name, mapName, loc.x, loc.y))
							end
						end
						if 0 == count then
							print("Grail: no new quest pins this session")
						else
							print(strformat("Grail: |cFF00FF00%d|r new quest pin(s) this session", count))
						end
					end)
					self:RegisterSlashOption("help", "|cFF00FF00help|r => print out this list of commands", function()
						print("|cFFFF0000Grail|r slash commands:")
						for option, value in pairs(self.slashCommandOptions) do
							print("|cFFFF0000/grail|r",value['help'])
						end
						print("|cFFFF0000/grail|r => initiates a database query to get completed quests [this happens at startup normally]")
					end)
					self:RegisterSlashOption("backup", "|cFF00FF00backup|r => creates a backup copy of the completed quests used for comparison", function()
						self:_ProcessServerBackup()
					end)
					self:RegisterSlashOption("compare", "|cFF00FF00compare|r => compares the current completed quest list to the backup copy", function()
						self:_ProcessServerCompare()
					end)
					--	Add a command for MoP that makes comparison of completed quests a little easier.  Only for MoP since before that the server
					--	needs to be queried and that means the return result will not happen before we compare.
                    self:RegisterSlashOption("cb", "|cFF00FF00cb|r => compares the latest server status quest list to the backup copy, and makes the backup become current", function()
						if not self.inCombat then
							print("|cFFFFFF00Grail|r initiating server database query")
							QueryQuestsCompleted()
							self:_ProcessServerCompare()
							self:_ProcessServerBackup()
						else
							print("|cFFFFFF00Grail cb|r not available in combat")
						end
					end)
					self:RegisterSlashOption("clearstatuses", "|cFF00FF00clearstatuses|r => clears the status of all quests allowing them to be recomputed", function()
						wipe(self.questStatuses)
						self.questStatuses = {}
						self:_CoalesceDelayedNotification("Status", 0)
					end)
					self:RegisterSlashOption("eraseAndReloadCompletedQuests", "|cFF00FF00eraseAndReloadCompletedQuests|r => reloads the completed quest list from Blizzard erasing the current list", function()
						GrailDatabasePlayer["completedQuests"] = {}
						QueryQuestsCompleted()
						-- And the following code is the same as the clearstatuses command...
						wipe(self.questStatuses)
						self.questStatuses = {}
						self:_CoalesceDelayedNotification("Status", 0)
					end)
					-- >>>VIGNETTE_DEBUG
					-- >>>QUESTPIN_DEBUG
					self:RegisterSlashOption("vignames db", "|cFF00FF00vignames db|r => fills in vignette names from built-in DB (English fallback)", function()
						local t = {[4]="Vignette Test Kill",[5]="Vignette Test Loot",[9]="Vignette Test Event",[10]="Sternenbrecher Roghash",[11]="Schatzträger der Fara",[12]="Gefangener Draenei",[13]="Der Leerenseher",[14]="Uraka",[15]="Synodicus",[16]="Verteidigungskristall von Embaari",[17]="Mysteriöse Leere",[18]="Der Vernichter",[19]="Prophezeiung von Jerrikar",[20]="Prophezeiung von Kraator",[21]="Prophezeiung des Sphärenwächters",[22]="Konstruktion des Vernichters",[23]="Blattleser Kurri",[24]="Eisenkettenschatz",[25]="Hygrocybe",[26]="Felshuf",[27]="Talby",[28]="Schattenbergschatz",[29]="Bergzoid",[30]="Yggdrel",[33]="Blutspitz",[34]="Knackzahn",[35]="Zangenkiefer",[36]="Kwall",[37]="Aetha",[38]="Geist von Lao-Fe",[39]="Bai-Jin der Schlächter",[40]="Gochao die Eisenfaust",[41]="Gaohun der Seelenschnitter",[42]="General Temuja",[43]="Schattenmeister Sydow",[44]="Wulon",[45]="Huo-Shuang",[46]="Baolai der Verbrenner",[47]="Vyraxxis",[48]="Kri'chon",[49]="Richtig ranziges Bier",[50]="Zesqua",[51]="Versunkener Schatz",[52]="Bis auf die Knochen",[53]="Kranichknirscher",[54]="Schwarzwaches Strandgut",[55]="Kukurus Schatzkammer",[56]="Verschnürte Schatztruhe",[57]="Funkelnde Schatztruhe",[58]="Funkelnder Schatzbeutel",[59]="Chelon",[60]="Karkanos",[61]="Schlacht um die Seepocke",[62]="Jeremy's Test Vignette",[63]="Mondfang",[64]="Einsturzstelle",[65]="Eisenfellstahlhorn",[66]="Blattheiler",[67]="Großschildkröte Zornpanzer",[68]="Smaragdkranich",[69]="Gu'chi der Schwarmbringer",[70]="Jadefeuergeist",[71]="Klapperknochen",[72]="Whizzig",[73]="Zhu-Gon der Saure",[74]="Spelurk",[75]="Garnia",[76]="Steinmoos",[77]="Glutfall",[78]="Tsavo'ka",[79]="Huolon",[80]="Monströse Dornzange",[81]="Bufo",[82]="Schreckensschiff Vazuvius",[83]="Golganarr",[84]="Kaiserpython",[85]="Tiefenschlund",[86]="Archiereus der Flamme",[87]="Behüter Osu",[88]="Urdur der Kauterisierer",[89]="Jakur von Ordos",[90]="Funkenlord Gairan",[91]="Champion der Schwarzen Flamme",[92]="Glitzernde Kranichstatue",[93]="Uralte Salzschnappschildkröte",[94]="Sooty",[95]="Stinkezopf",[96]="Ra'sha",[97]="Willi Wilder",[98]="Kriegsspäher der Zandalari",[99]="Muerta",[100]="Kar Kriegstreiber",[101]="Ubunti der Schatten",[102]="Disha Furchtwächter",[103]="Dalan Nachtbrecher",[104]="Mavis Harms",[105]="Ferdinand",[106]="Schwarzhuf",[107]="Major Affentanz",[108]="Ik-Ik der Flinke",[109]="Der Jauler",[110]="Kritscher",[111]="Spriggin",[112]="Bonobos",[113]="Das Tier",[114]="Ai-Ran die flüchtige Wolke",[115]="Ai-Li Himmelsspiegel",[116]="Yul Wildpfote",[117]="Ahone die Wanderin",[118]="Ruun Geisterpranke",[119]="Nasra Fleckpelz",[120]="Urobi der Wanderer",[121]="Moldo Einauge",[122]="Omnis Feixmaul",[123]="Siltriss der Schärfer",[124]="Nessos das Orakel",[125]="Arness die Schuppe",[126]="Kriegsspäher von Salyis",[127]="Sarnak",[128]="Sahn Gezeitenjäger",[129]="Nalash Verdantis",[130]="Eshelon",[131]="Zai der Verstoßene",[132]="Cournith Wasserläufer",[133]="Sele'na",[134]="Aethis",[135]="Kal'tik der Veröder",[136]="Gar'lok",[137]="Lith'ik der Pirscher",[138]="Ski'thik",[139]="Torik-Ethis",[140]="Nal'lak der Reißer",[141]="Krax'ik",[142]="Urgolax",[143]="Krol die Klinge",[144]="Kah'tir",[145]="Havak",[146]="Qu'nas",[147]="Jonn-Dar",[148]="Morgrinn Bersthauer",[149]="Kang der Seelendieb",[150]="Karr der Verdunkler",[151]="Norlaxx",[152]="Borginn Dunkelfaust",[153]="Gaarn der Giftige",[154]="Sulik'shor",[155]="Kor'nas Nachtgrauen",[156]="Yorik Scharfauge",[157]="Dak der Brecher",[158]="Lon der Bulle",[159]="Korda Torros",[160]="Go-Kan",[161]="Doktor Theolen Krastinov",[162]="Mumta",[163]="Kriegshetzer der Zandalari",[164]="Kriegsgott Dokah",[165]="Progenitus",[166]="Ku'lai die Himmelsklaue",[167]="Goda",[168]="Gottkoloss Ramuk",[169]="Al'tabim der Allsehende",[170]="Rückenbrecher Uru",[171]="Lu-Ban",[172]="Molthor",[173]="Krakkanon",[180]="Kannibaleneichhörnchen",[194]="Riesentöter Kul",[195]="Schluchteismutter",[196]="Donnerfürstentruhe",[197]="Glutrachen",[198]="Zeitverzerrter Turm",[199]="Ergrauter Veteran der Frostwölfe",[200]="Feuerzornstein",[201]="Feuerzornriese",[202]="Borrok der Verschlinger",[203]="Gorg'ak der Lavaschlinger",[204]="Magenstein des Verschlingers",[205]="Veloss",[207]="Giftschatten",[211]="Verstaubte Kiste",[212]="Klingenmeister Zaruk",[213]="Future Vignette Placeholder",[214]="Primalist Mur'og",[215]="Dunkle Manifestation",[216]="Faulatem",[217]="Todesschlund",[218]="Amaukwa",[219]="Karawane der Eisernen Horde",[220]="Eisenflegel",[221]="Schattenruferin Anga",[222]="Felshuf",[223]="Aruumels Streitkolben",[224]="Riesige Flusspferdmutter",[225]="Froststampf der Trauernde",[226]="Riesenjägertrupp",[227]="Frosthauer",[228]="Späher Blutsucher",[229]="Der Prügler",[230]="Yazheera die Verbrennerin",[231]="Dr. Depression",[232]="Kal'rak der Trunkenbold",[233]="Vipernhieb",[234]="Nixxie der Goblin",[235]="Riesiges Insekt",[236]="Rasender Golem",[237]="Cro Fleischfetzer",[238]="Hennenmutter Hami",[239]="Sturmwelle",[240]="Larvra",[241]="Aarko",[242]="Hammerzahn",[243]="Glimmerflügel",[244]="Eiserner Schütze",[245]="Ra'kahn",[246]="Blutblüte der Koloss",[247]="Roardan",[248]="Die Anachoretenrast retten",[249]="Wandernder Verteidiger",[250]="Lo'marg Kieferbrecher",[251]="Echo von Murmur",[252]="Riesenschlange",[253]="Eiserner Jäger",[254]="Der Knochenkriecher",[255]="Brutmutter Reeg'ak",[256]="Großhexenmeisterin Duress",[257]="Knarlkiefer",[258]="Schleimkönig",[259]="Fahler Fischfänger",[260]="Eingefrorener Schatz",[261]="Zyklonzorn",[262]="Kharazos der Siegestrunkene",[263]="Galzomar",[264]="Azika die Frosthexe",[265]="Caldera Makrah",[266]="Champion Logor",[267]="Scharfschütze Kizi",[268]="Erdmeister Rogok",[269]="Elementaristin Utrah",[270]="Schmiedeoberin Targa",[271]="Kalgor Feindestöter",[272]="Frontbrecher Drugg",[273]="Lorgrun Eisenfaust",[274]="Magmos der Bergbrecher",[275]="Kriegsmatrone Okrilla",[276]="Pfadpirscherin Draga",[277]="Flammenzauberin Zindra",[278]="Kragor die Narbenhaut",[279]="Spähmeister Hasark",[280]="Grun der Schädelspalter",[281]="Steinmatrone Shula",[282]="Schlachtzauberer Bargol",[283]="Worgmeister Rakan",[284]="Gebäude wird angegriffen",[285]="Atemlos",[286]="Klikixx",[287]="Eisengebundene Lawine",[288]="Eisengebundenes Inferno",[289]="Kriegsmaschine der Eisernen Horde",[290]="Zuchtmeisterin Mugrah",[291]="Bonusziel: Der Verbotene Gletscher",[292]="Gefrorene Axt",[293]="Gorum",[294]="Bonusziel: Blutdornhöhle",[295]="Krummzahnschlund",[296]="Vorarbeiter Fallow",[297]="Verhängnisreißer",[298]="Riesengroßer Eisschnabel",[299]="Marok Verdammnishand",[300]="Brotoculus",[301]="Bonusziel: Frostbrandhöhle",[302]="Bonusziel: Grimmfrostberg",[303]="Bonusziel: Steinzornklippen",[304]="Ug'lok der Frostige",[305]="Brotoculus",[306]="Yaga die Vernarbte",[308]="Bonusziel: Zerfleischt sie",[309]="Bonusziel: Aruunas Verheerung",[310]="Kriegsmeister Blugthol",[311]="Bombe zum Explodieren gebracht",[312]="Bonusziel: Zorkras Sturz",[313]="Krallenpriesterin Zorkra",[314]="Shirzir",[315]="Bonusziel: Rodung von Mor'gran",[316]="Bonusziel: Hof der Seelen",[317]="Jehil der Kletterer",[318]="Kapitän Eisenbart",[319]="Bonusziel: Der Schimmerhain",[320]="Torvaths Kristallklinge",[321]="Torvaths Kristallklinge",[322]="Hierhin reisen",[323]="Eindringling",[324]="Bonusziel: Die Begräbnisfelder",[325]="Bonusziel: Eisenfausthafen",[326]="Donnerfürstenboss",[327]="Gruuk",[328]="Gurun",[329]="Saboteur",[330]="Frostfang",[331]="No'losh",[332]="Entzündet die Kohlenpfannen",[333]="Bonusziel: Orunaiküste",[334]="Grutush der Plünderer",[335]="Gennadian",[336]="Mutter Araneae",[337]="Unterseher Blutmähne",[338]="Doug Test - Vignette",[339]="Gaz'orda",[340]="Sulfuror",[341]="Teufelsborke",[342]="Gefährdetes Gebäude",[343]="Fungusprätorianer",[344]="Waffenträger",[345]="Goren",[346]="Sikthiss die Kriegsfurie",[347]="Der Hüter",[348]="Skagg",[349]="Dornkönig Fili",[350]="Bahamai",[351]="Auferstandene Geister",[354]="Varashas Ei",[355]="Bashiok",[356]="Varashas Ei",[357]="Vignette Placeholder",[358]="Dunkelmeister Go'vid",[359]="Nizzix' Truhe",[360]="An Land gespülte Rettungskapsel",[361]="Char der Brennende",[362]="Morva Seelenzerstörer",[363]="Verwundete Verteidigerin",[364]="Rai'vosh",[365]="Dunkelkralle",[366]="Seelenschänder Torek",[367]="Kronus",[368]="Fangraal",[369]="Klingentänzer Aeryx",[370]="Forscher Nozzand",[371]="Moltnoma",[372]="Seelenschänderportal",[373]="Schmatzschlund",[374]="Wuchthauer",[375]="Tor'goroth der Seelenverschlinger",[376]="Sohn von Goramal",[377]="Schatz der Blutschläger",[378]="Enavra",[379]="Vielfraß",[380]="Mutierter Verteidiger",[381]="Rotklaue der Wilde",[382]="Großfeder",[383]="Gar'lua die Wolfsmutter",[384]="Knorrhuf der Tollwütige",[385]="Feenglanz",[386]="Ba'ruun",[387]="Shinri",[388]="Verängstiger Peon",[389]="Zünder für Goblinsprengstoff",[390]="Furchterregender Gronnling",[391]="Schwert des Klingenmeisters",[392]="Grauschlund",[393]="Bonusziel: Hemets Schlaraffenland",[394]="Leerenseher Kalurg",[395]="Liegen gelassene Angelrute",[396]="Netherbrut",[397]="Ophiis",[398]="Windrufer Korast",[399]="Mutter Om'ra",[400]="Bonusziel: Ruinenräuber",[401]="Flinthaut",[402]="Makellose Lilie",[403]="Sicherer Ort",[404]="Ru'klaa",[405]="Wahnsinniger \"\"König\"\" Sporeon",[406]="Schwarmkönigin Skrikka",[407]="Insha'tar",[408]="Zurückgelassene Truhe",[409]="Stampfer Kreego",[410]="Tura'aka",[411]="Jäger Schwarzzahn",[412]="Späher Pokhar",[413]="Malroc Steinmahler",[414]="Vorhut Duretha",[415]="Tiefenwurz",[416]="Aufgeladenes Erz einsammeln",[417]="Aufgeladenes Erz einsammeln",[418]="Stadionrennen",[420]="Goldzehs Plündergut",[421]="Windfeuer der Donnerfürsten",[422]="Korthall Seelenschlinger",[423]="Eingesponnene Spinne",[424]="Seelenfang",[425]="Nas Dunberlinn",[426]="Tötet Schotterzahns Goren",[427]="Mandragoraster",[428]="Mandrakor",[429]="Greldrok",[430]="Springschlinger",[431]="Hexenmeisterportal",[432]="Portal zum Sturmschild",[433]="Sonnenverstärker",[434]="Schlinger",[435]="Hexenmeisterportal",[436]="Portal zum Kriegsspeer",[437]="Dr. Zwicky sen.",[438]="Wegelagerer",[439]="Titarus",[440]="Gefangener Steinformer der Gor'vosh",[441]="Tesska der Zerbrochene",[442]="Steingrimm",[443]="Durkath Stahlrachen",[444]="Kalos der Blutgetränkte",[445]="Protzki",[446]="Brut von Sethe",[447]="Klauenbrecher",[448]="Giftmeister Keilzahn",[449]="Fäulglimmer",[450]="Schlüpfriger Schleim",[451]="Oskiira",[452]="Betti Bummbatz",[453]="Eiterblüte",[454]="Uraltes Inferno",[455]="Gorenspießer",[456]="Oraggro",[457]="Stachelschwanznest",[458]="Brennende Macht",[459]="Augenloser",[460]="Kugel der Macht!",[461]="Gochar",[462]="Schlingflosse",[463]="Jiasska der Sporenschlinger",[464]="Sonnenweiser Valarik",[465]="Phylarch der Immergrüne",[466]="Verschollenes Urtum",[467]="Greisholz der Versteinerte",[468]="Gelgor aus der blauen Flamme",[469]="Rolkor",[470]="Kuruk der Uralte",[471]="Autuk der Uralte",[472]="Loruk der Uralte",[473]="Hanuk der Uralter",[474]="Mutafen",[475]="Hauptfeldwebel Milgra",[476]="Rüstmeister Hershak",[477]="Herrin Temptessa",[478]="Demidos",[479]="Schattensprecher Niir",[480]="Horde hier entdeckt!",[481]="Allianz hier entdeckt!",[482]="Hypnoquak",[483]="Schwarmblatt",[484]="Schattenborke",[485]="Nachtschlund",[486]="Panthora",[487]="Alexi Barov",[488]="Weldon Barov",[489]="Verfluchte Kreatur",[490]="Ältester Dunkelwirker Kath",[491]="Beschwörer",[492]="Malgosh Schattenhüter",[493]="Formloser Alptraum",[494]="Leerenhetzerin Urnae",[495]="Kenos' schwarzer Altar",[496]="Ogerfeuer",[497]="Berthora die Flussbestie",[498]="Riptar",[499]="Sonnenklaue",[500]="Aqualir",[502]="Gorianischer Legionär",[503]="Gorianischer Elementarist",[504]="Blutrünstiger Haudrauf",[505]="Gorianischer Arkanist",[506]="Gorianischer Zenturio",[507]="Gorianischer Magierlord",[508]="Gorianischer Wächter",[509]="Soldat der Gefallenen",[510]="Sylldross",[511]="Stampfalupagus",[512]="Stahlhauer",[513]="Deserteur Dazgo",[514]="Maroder Madgard",[515]="Morgo Kain",[516]="Horgg",[517]="Durp der Verhasste",[518]="Erfinderin Rumskugel",[519]="Klingenmeister Ro'gor",[520]="Begleiter",[521]="Schniefel",[522]="Terokkschrein",[523]="Terokkschrein",[524]="Terokkschrein",[525]="Terokkschrein",[526]="Terokkschrein",[527]="Terokkschrein",[528]="Blassfell der Einsiedler",[529]="Eindringling",[530]="Aaswurm",[531]="Verräterischer Plünderer",[532]="Opportunist der Horde",[533]="Erzknirscher",[543]="Raureif",[544]="Gomtar der Gewandte",[545]="Mutter der Goren",[546]="Gibblett der Feigling",[547]="Vrok der Urzeitliche",[548]="Valkor",[549]="Karosh Schwarzwind",[550]="Brutag Grimmklinge",[551]="Krahl Todeswind",[552]="Gortag Stahlgriff",[553]="Kriegstrupp von Mok'gol",[554]="Bombardier Gu'gok",[558]="Knochenbrecher",[559]="Grubenschlächter",[560]="Durg Rückenzermalmer",[561]="Avatar von Socrethar",[562]="Haakun der Allesverschlingende",[563]="Gug'tol",[564]="Teufelsfeuerbuhle",[565]="Kriegsrat der Sargerei",[566]="Verwandeltes Wesen",[567]="Gefräßiger Riese",[568]="Mechaplünderer",[569]="Gigabewacher",[570]="Schattenkoloss",[571]="Lord Korinak",[572]="Orumo der Beobachter",[573]="Matrone der Sünde",[574]="Kurlosh Verdammnisbiss",[575]="Herrin Demlash",[576]="Schattenflammenschreiter",[579]="Scherbenschlund",[580]="Nagidna",[581]="Lawine",[582]="Krud der Ausweider",[583]="Grubenbestie",[586]="Beschützer des Hains",[587]="Scharfseher Weißauge",[588]="Wachsamer Paarthos",[589]="Xothear der Zerstörer",[590]="Vorhut der Legion",[591]="Echidna",[592]="Typhon",[593]="Keravnos",[594]="Lernaea",[595]="Schneller Onyxschinder",[596]="Venolasix",[597]="Hainwächter Yal",[598]="Feuerteufel Grash",[599]="Kaga der Eisenbieger",[600]="Erderschütterer Holar",[601]="Jaluk der Pazifist",[602]="Faulhut",[603]="Böser Blick",[604]="Ragore Schneejäger",[605]="Ogom der Zerfleischer",[606]="Verwaltungsassistent Spez",[607]="Riesiger Gorgrondsandjäger",[608]="Goblinarbeiter",[609]="Shirrak der Totenwächter",[610]="Jägerin Bal'ra",[611]="Großmarschall Tremblade",[612]="Oberster Kriegsfürst Volrath",[613]="Mogamago",[614]="Alkali",[616]="Gorok",[617]="Schlickhaut",[618]="Nakk der Donnerer",[619]="Rammfaust",[620]="Luk'hok",[621]="Pfadläufer",[622]="Kenos der Zerreißer",[623]="Opportunist der Allianz",[624]="Gorivax",[626]="Bergruu",[627]="Dekorhan",[628]="Gagrog der Metzler",[629]="Thek'talon",[630]="Mu'gra",[631]="Aogexon",[632]="Terrorhuf",[633]="Xelganak",[634]="Gräuelklaue",[635]="Ak'ox die Schlächterin",[636]="Ravyn-Drath",[637]="Garnisonslager",[638]="Verängstiger Arbeiter",[639]="Flammenpanzer",[640]="Rylai Jammerthal",[641]="Jeron Funkendrift",[642]="Fledermausreiter des Teufelsfeuers",[643]="Kor'lok",[644]="Angreifende Ranke",[645]="Eindringling",[646]="Leerenverzerrer des Schattenmondklans",[647]="Wildfeuerelementar",[648]="Erdbrechergronn",[649]="Gorenbau",[650]="Urzeitlicher Schrecken",[651]="Zeitbomben",[652]="Todesrufer des Schattenmondklans",[653]="Reißdorn",[654]="Sangrikass",[655]="Gorianischer Kriegsrufer",[656]="Leerenportal",[657]="Galzomar",[658]="Wütender Erdstampfer",[659]="Opfergaben für die Riesen",[660]="Gorianischer Kampfmagier",[661]="Wandernder Verteidiger",[662]="Gorianischer Zauberbinder",[663]="Auftragsmörder der Zerschmetterten Hand",[664]="Nachtflügelaasfresser",[665]="Eisschlundaasfresser",[666]="Eisschlundaasfresser",[667]="Furchterregender Gronnling",[668]="Konkubine der Sünde",[669]="Teufelslegionär",[670]="Ruchlose Buhle",[671]="Scharfschütze der Grom'kar",[672]="Bannerträger der Horde",[673]="Bannerträger der Allianz",[674]="Verheererschwarm",[676]="Wyrmzungenhorter",[677]="Valiyaka die Sturmbringerin",[678]="Horn der Sirene",[679]="Hauptmann Volo'ren",[680]="Das Orakel",[681]="Mrrgrl der Gezeitenhäscher",[682]="Flog der Kapitänenfresser",[683]="Vignette Placeholder",[684]="Yaeger-367",[685]="Kristallbart",[686]="Dolchschnabel",[687]="Hafenmeister Korak",[688]="Zoug der Klotz",[690]="Eiserner Hauptmann Argha",[691]="Inquisitor Ernstenbok",[692]="Such- & Zerstörungstrupp",[693]="Normantis der Entthronte",[694]="Entfesselter Riss",[695]="Varyx der Verdammte",[696]="Unteroffizier Mor'grak",[697]="Syphonus & Leodrath",[698]="Cindral",[699]="Cindral",[700]="Wichtelmeisterin Valessa",[701]="Hohepriester Ikzan",[702]="Lady Oran",[703]="Hundemeister Jax'zor",[704]="Ceraxas",[705]="Herrin Thavra",[706]="Rasthe",[707]="Höllenbestienvorrat",[708]="Invasionsort",[709]="Kleiner Invasionsort",[710]="Großer Invasionsort",[711]="Dimensionsanker",[712]="Lord Jaraxxus",[715]="Schatzgoblin",[716]="Rudelführer Miaul",[717]="Zeter'el",[718]="Dornenwüter",[719]="Teufelsfunke",[720]="Marius & Tehd",[721]="Gezeitenungetüm",[723]="Sandros",[724]="Scheinbar unbehüteter Schatzhaufen",[725]="Bilkor der Werfer",[726]="Rogond der Fährtenleser",[727]="Drivnul",[728]="Dorg der Blutige",[729]="Blutjäger Zulk",[730]="Überrest des Blutmonds",[731]="Cailyn Bleichbann",[732]="Kraw der Mystiker",[734]="Schotenfürst Wakkawumm",[735]="Glimar Eisenfaust",[736]="Verborgener Dämon",[737]="Marius & Tehd",[738]="Verborgener Dämon",[739]="Schwelende Schmiede",[740]="Kleine Schatztruhe",[741]="Schatztruhe",[742]="Schatztruhe",[743]="Schatztruhe",[744]="Schatztruhe",[745]="Schatztruhe",[746]="Glitzernde Schatztruhe",[747]="Kleine Schatztruhe",[748]="Schatztruhe",[749]="Schatztruhe",[750]="Schatztruhe",[751]="Schatztruhe",[752]="Schatztruhe",[753]="Patt der Gilblin",[754]="Glitzernde Schatztruhe",[755]="Schatztruhe",[756]="Wespenkönigin Zsala",[757]="Helyas Kraken",[758]="Großhexenmeister Nethekurse",[759]="Exekutor Riloth",[760]="Schatztruhe",[761]="Schatztruhe",[762]="Die Pestrufer",[763]="Matriarchin der Sturmschwingen",[764]="Methalle des Thans",[765]="Fathnyr",[768]="Argosh der Zerstörer",[769]="Klingenbö",[770]="Geir Bauchschlitzer",[771]="Verborgener Dämon",[772]="Putre'thar",[773]="Fenri",[774]="Shyama die Gefürchtete",[775]="Unbewachter Distelblattschatz",[776]="Blutschnabel",[777]="Wilde Mandragora",[778]="Elunes Kuss",[779]="Weißwassertaifun",[780]="Kleine Schatztruhe",[781]="Kleine Schatztruhe",[782]="Schatztruhe",[783]="Kleine Schatztruhe",[784]="Sehsei",[785]="Kleine Schatztruhe",[786]="Schatztruhe",[787]="Kleine Schatztruhe",[788]="Schatztruhe",[789]="Schatztruhe",[790]="Schatztruhe",[791]="Kleine Schatztruhe",[792]="Kleine Schatztruhe",[793]="Kleine Schatztruhe",[794]="Schatztruhe",[795]="Infizierter Pilz",[796]="Glitzernde Schatztruhe",[797]="Glitzernde Schatztruhe",[798]="Meisterspäher Relgor",[799]="Schatztruhe",[800]="Kleine Schatztruhe",[801]="Kleine Schatztruhe",[802]="Schrein der Bärenzwillinge",[803]="Gunst der Bärenzwillinge",[804]="Kleine Schatztruhe",[805]="Schatztruhe",[806]="Eichblatts Alptraum",[807]="Kleine Schatztruhe",[808]="Borstenknolls Versteck",[809]="Taylas Rettung",[810]="Schatztruhe",[811]="Brimbil's Reward [PH]",[812]="Brimbils Reise",[813]="Invasionspunkt: Verwüstung",[814]="Schmerzmeisterin Selora",[815]="Xanzith der Unvergängliche",[816]="Oberanführer Ma'gruth",[817]="Brutwächter Ixkor",[818]="Der Schwarzfang",[819]="Seelenschlitzer",[820]="Finsterkralle",[821]="Krell der Gleichmütige",[822]="Belgork",[823]="Thromma der Bauchschlitzer",[824]="Haken & Versenker",[825]="Worgrudel",[826]="Worgenpirscher",[827]="Sylissa",[828]="Todesschwadron der Verlassenen",[829]="Rendrak",[830]="Der Nachtschatten",[831]="Teufelsschmiedin Damorka",[832]="Kleine Schatztruhe",[833]="Räuber des Höllenschlunds",[834]="Die Schlitzklaue",[835]="Blutgeweihs Sohn",[836]="Kleine Schatztruhe",[837]="Schatztruhe",[838]="Kleine Schatztruhe",[839]="Schatztruhe",[840]="Der Namenlose König",[841]="Schrecken des Blutenden Auges",[842]="Stahlschnauze",[843]="Questgeber der Herausforderung",[844]="Interaktive Objektsprechblase",[845]="Schreckensrufer Rek'zolar",[846]="Gorabosh",[847]="Hundemeister Ely",[848]="Iroxus",[849]="Legionszitadelle",[850]="Magwia",[851]="[PH] Farm Defense",[852]="[PH] Banshee Queen",[853]="Driss Aasflinte",[854]="Schatztruhe",[855]="Kleine Schatztruhe",[856]="Kommandant Krag'goth",[857]="Tho'gar Blutfaust",[858]="Kommandant Org'mok",[859]="Grannok",[860]="Der Eiserne Hundemeister",[861]="Szirek der Entstellte",[862]="Kapitän Eisenbart",[863]="Titan Vault",[864]="Matschflutalpha",[865]="Grauschatten",[866]="Theryssia",[867]="Verirrter Ettin",[868]="Teufelsfräser",[869]="Thondrax",[870]="Glitzernde Schatztruhe",[871]="Schatztruhe",[872]="Kleine Schatztruhe",[873]="Schattendrescher",[874]="Hauptmann Grok'mar",[875]="Kris'kar der Verschmähte",[876]="Schreckenslord Seelenfessler",[877]="Mordvigbjorn",[878]="Wütender Erddiener",[879]="Urgev der Schinder",[880]="Kommandant Kar'threk",[881]="Schreckenslord Verakaz",[882]="Kleine Schatztruhe",[883]="Kleine Schatztruhe",[884]="Ur'lux",[885]="Invasionspunkt",[886]="Zitterndes Aschenmauljunges",[887]="Elindya Fiederlicht",[888]="Kommandant Zarthak",[889]="Kleine Schatztruhe",[890]="Schatztruhe",[891]="Antydas Nachtrufers Versteck",[892]="Glitzernde Blüte",[893]="Interaktive NSC-Sprechblase",[894]="Bewusstloser Haudrauf",[895]="Abyssalmonstrosität",[896]="Legionsreliktjäger",[897]="Elfenbeinbehüterin",[898]="Legionskommandant Arifex",[899]="Reliktverschlingerin Siniara",[900]="Pionier Vorick",[901]="Geistbeuger Alazor",[902]="Kleine Schatztruhe",[903]="Kleine Schatztruhe",[904]="Schatztruhe",[905]="Kleine Schatztruhe",[906]="Kleine Schatztruhe",[907]="Schatztruhe",[908]="Kleine Schatztruhe",[909]="Kleine Schatztruhe",[910]="Kleine Schatztruhe",[911]="Schatztruhe",[912]="Kleine Schatztruhe",[913]="Schatztruhe",[914]="Kleine Schatztruhe",[915]="Glitzernde Schatztruhe",[916]="Kleine Schatztruhe",[917]="Schatztruhe",[918]="Glitzernde Schatztruhe",[919]="Kleine Schatztruhe",[920]="Kleine Schatztruhe",[921]="Kleine Schatztruhe",[922]="Schatztruhe",[923]="Kleine Schatztruhe",[924]="Unterwerfer Deth'ryzak",[925]="Kleine Schatztruhe",[926]="Kleine Schatztruhe",[927]="Kleine Schatztruhe",[928]="Schatztruhe",[929]="Kleine Schatztruhe",[930]="Kleine Schatztruhe",[931]="Kleine Schatztruhe",[932]="Kleine Schatztruhe",[933]="Schatztruhe",[934]="Schatztruhe",[935]="Glitzernde Schatztruhe",[936]="Kleine Schatztruhe",[937]="Kleine Schatztruhe",[938]="Kleine Schatztruhe",[939]="Schatztruhe",[940]="Isel der Hammer",[941]="Spukhaus",[942]="Ix'Gur der Infizierte",[943]="Lager der Illidari",[944]="Den Fluss läutern",[945]="Netherflamme",[946]="Schreckensritter",[947]="Teufelshäscher",[948]="Die Wildnis erhebt sich",[949]="Stadtbewohner retten",[950]="Loherus",[952]="Orramis der Himmelssenger",[953]="Hundemeister Vorix",[954]="Brogrul der Mächtige",[955]="Kleine Schatztruhe",[956]="Terrorfaust",[957]="Verdammniswalze",[958]="Rache",[959]="Todeskralle",[960]="Gurgstok",[961]="Rekonstruierter Feindschnitter 5000",[962]="Kriegshetzer Shri'valox",[963]="Kleine Schatztruhe",[964]="Schatztruhe",[965]="Der Blutmond",[966]="Syndrelle",[967]="Alte Bärenfalle",[968]="Sammelt Apexismale",[970]="Oubdob der Knaller",[971]="Schatztruhe",[972]="Wurmple",[973]="Zuchtmeister der Himmelsschnauzer",[974]="Schatztruhe",[975]="Zaubersauger",[976]="Glitzernde Schatztruhe",[977]="Schatztruhe",[978]="Kleine Schatztruhe",[979]="Schatztruhe",[980]="Schatztruhe",[981]="Schatztruhe",[982]="Schatztruhe",[983]="Zaldrok",[984]="Eine dampfende Kiste",[985]="Koppklopperarena",[986]="Auferstandene Geister",[987]="Sammelt Apexismale",[988]="Ogerfeuer",[989]="Aufgeladenes Erz einsammeln",[990]="Stadionrennen",[991]="Sammelt Apexismale",[992]="Sammelt Apexismale",[993]="Perrexx der Verderber",[994]="Herz des Hains",[995]="Majestätisches Urhorn",[998]="Schatztruhe",[999]="Shara Teufelshauch",[1000]="Vollkommen sichere Schatztruhe",[1001]="Der verbannte Schamane",[1002]="Eraakis",[1003]="Bestienmeister Pao'lek",[1004]="Hartli die Wegfängerin",[1006]="Krähenschropf der Hungrige",[1007]="Der Schneebringer",[1008]="Schatztruhe",[1009]="Schatztruhe",[1010]="Schatztruhe",[1011]="Schatztruhe",[1012]="Schatztruhe",[1013]="Schatztruhe",[1014]="Schatztruhe",[1015]="Schatztruhe",[1016]="Schatztruhe",[1017]="Arachnis",[1018]="Schatztruhe",[1019]="Schatztruhe",[1020]="Schatztruhe",[1021]="Schatztruhe",[1022]="Schatztruhe",[1023]="Schatztruhe",[1024]="Schatztruhe",[1025]="Schatztruhe",[1026]="Schatztruhe",[1027]="Phantomkralle",[1028]="Terrormoor",[1031]="Pfadfinder Hastfuß",[1032]="Faules Ei",[1033]="Wahnsinniger Magier",[1034]="Manasicker",[1035]="Skriek",[1036]="Segacedi",[1037]="Diebisches Gesindel",[1038]="Splint",[1039]="Xullorax",[1040]="Hort der Schattenseite",[1041]="Seelenlechzer",[1042]="Jägerin Ellandryn",[1043]="Der Bestienboxer",[1044]="Qualtotem",[1045]="Alptraumwurzeln",[1046]="Alptraumwurzeln",[1047]="Liegen gelassene Angelrute",[1048]="Schatztruhe",[1049]="Schatztruhe",[1050]="Schatztruhe",[1051]="Schatztruhe",[1052]="Schatztruhe",[1053]="Arkuthaz",[1054]="Garthulak der Zermalmer",[1055]="Schatztruhe",[1056]="Grmlrml der Krabbenreiter",[1057]="Schatztruhe",[1058]="Schatztruhe",[1059]="Schatztruhe",[1060]="Schatztruhe",[1061]="Schatztruhe",[1062]="Schatztruhe",[1063]="Kleine Schatztruhe",[1064]="Earlnoc der Bestienbrecher",[1065]="Egyl der Ausdauernde",[1066]="Pugg",[1067]="Guk",[1068]="Rukdug",[1069]="Lyrath Mondfeder",[1070]="Eisenast",[1071]="Tarben",[1072]="Kleine Schatztruhe",[1073]="Bodash der Hamsterer",[1074]="Schatztruhe",[1075]="Schatztruhe",[1076]="Schatztruhe",[1077]="Schatztruhe",[1078]="Schatztruhe",[1079]="Schatztruhe",[1080]="Schatztruhe",[1081]="Kleine Schatztruhe",[1082]="Kleine Schatztruhe",[1083]="Schatztruhe",[1084]="Gefangener Überlebender",[1085]="Sonnenbriser",[1086]="Schatztruhe",[1087]="Eileen die Krähe",[1088]="Zaggund Hopp",[1089]="Gondar",[1090]="Drakum",[1091]="Teufelsaufseher Lehmklump",[1092]="Glitzernde Schatztruhe",[1093]="Kottr Vondyr",[1094]="Korazoth",[1095]="Grrvrgull der Eroberer",[1096]="Schatztruhe",[1097]="Schatztruhe",[1098]="Schatztruhe",[1099]="Grelda die Hexe",[1100]="Aufseher Th'talak",[1103]="Schatztruhe",[1104]="Schatztruhe",[1105]="Schatztruhe",[1106]="Schlummernder Bär",[1107]="Der Hof der Brutkönigin: Graf Nefarious",[1108]="Der Hof der Brutkönigin: König Voras",[1109]="Der Hof der Brutkönigin: Aufseher Brutarg",[1110]="Der Hof der Brutkönigin: General Volroth",[1111]="Mellok",[1112]="Kethrazor",[1113]="Urg'thal",[1114]="Thaz'gul",[1115]="Schatztruhe",[1116]="Schatztruhe",[1117]="Schatztruhe",[1118]="Erdu'un",[1119]="Zornfürst Lekos",[1122]="Vedra die Geistbeugerin",[1123]="Schatztruhe",[1124]="Schatztruhe",[1125]="Glitzernde Schatztruhe",[1126]="Gurbog der Klopper",[1127]="Schätze der Valarjar",[1138]="Teufelsbrenner",[1143]="Vor'zathul",[1144]="Ri'sich",[1145]="Alptraum des Matrosen",[1146]="Ruheloser Meeresgeist",[1147]="Luggut der Eierfresser",[1148]="Borstenschlund",[1150]="Freizeitjäger",[1151]="Honigstock",[1152]="Kleine Schatztruhe",[1153]="Kleine Schatztruhe",[1154]="Kleine Schatztruhe",[1155]="Kleine Schatztruhe",[1156]="Kleine Schatztruhe",[1157]="Schatztruhe",[1158]="Ethisch fragwürdige Abenteurer",[1159]="Kleine Schatztruhe",[1160]="Kleine Schatztruhe",[1161]="Kleine Schatztruhe",[1162]="Glitzernde Schatztruhe",[1163]="Kleine Schatztruhe",[1164]="Schatztruhe",[1165]="Kleine Schatztruhe",[1166]="Kleine Schatztruhe",[1167]="Kleine Schatztruhe",[1168]="Schatztruhe",[1169]="Schatztruhe",[1170]="Schatztruhe",[1171]="Schatztruhe",[1172]="Schatztruhe",[1173]="Schatztruhe",[1174]="Schatztruhe",[1175]="Schatztruhe",[1176]="Schatztruhe",[1177]="Schatztruhe",[1178]="Schatztruhe",[1179]="Schatztruhe",[1180]="Schatztruhe",[1181]="Kleine Schatztruhe",[1182]="Schatztruhe",[1183]="Schatztruhe",[1184]="Kleine Schatztruhe",[1185]="Schatztruhe",[1186]="Kleine Schatztruhe",[1187]="Schatztruhe",[1188]="Schatztruhe",[1189]="Kleine Schatztruhe",[1190]="Kleine Schatztruhe",[1191]="Schatztruhe",[1192]="Schatztruhe",[1193]="Kleine Schatztruhe",[1194]="Schatztruhe",[1195]="Schatztruhe",[1196]="Kleine Schatztruhe",[1197]="Schatztruhe",[1198]="Schatztruhe",[1199]="Schatztruhe",[1200]="Kleine Schatztruhe",[1201]="Kleine Schatztruhe",[1202]="Kleine Schatztruhe",[1203]="Schatztruhe",[1204]="Schatztruhe",[1205]="Kleine Schatztruhe",[1206]="Schatztruhe",[1207]="Kleine Schatztruhe",[1208]="Kleine Schatztruhe",[1209]="Kleine Schatztruhe",[1210]="Schatztruhe",[1211]="Kleine Schatztruhe",[1212]="Kleine Schatztruhe",[1213]="Kleine Schatztruhe",[1214]="Schatztruhe",[1215]="Kleine Schatztruhe",[1216]="Kleine Schatztruhe",[1217]="Schatztruhe",[1218]="Verschlingende Finsternis",[1219]="Kleine Schatztruhe",[1220]="Rok'nash",[1221]="Sekhan",[1222]="Warpspeicher",[1226]="Schatztruhe",[1227]="Schatztruhe",[1228]="Gom Krabbar",[1229]="Panzermaul",[1230]="Jaggen-Ra",[1231]="Kleine Schatztruhe",[1232]="Kleine Schatztruhe",[1233]="Kohlfeder",[1234]="Staubige Truhe",[1236]="Garvrulg",[1237]="Algal Blütenquell",[1238]="Kleine Schatztruhe",[1239]="Leutnant Strathmar",[1240]="Meistermümmler",[1241]="Rek'zelok",[1242]="Mythana",[1243]="Zornfäule",[1244]="Kudzilla",[1245]="Treibgut",[1246]="Ragoul",[1247]="Arthfael",[1248]="Strandgut",[1249]="Cora'kar",[1250]="Har'kess der Unersättliche",[1251]="Hertha Grimmdottir",[1252]="Kraxa",[1253]="Ultanok",[1258]="Kommandant Vorlax",[1259]="Rifflord Raj'his",[1260]="Lady Aga'thar",[1261]="Gezeitenjäger Mela'kar",[1263]="Elfenbann",[1271]="Invasionsort",[1272]="Portal",[1273]="Großes Portal",[1274]="Legionsgebäude",[1275]="Ra'thuzek",[1276]="Tel'thuzek",[1277]="Unterwerfer Val'rek",[1278]="Shel'zuul",[1279]="Nekrolord Mordrathel",[1280]="Fäulnisbringer Karthex",[1281]="König der Meeresriesen",[1285]="Großes Gebäude",[1287]="Legionsbasis",[1291]="Bärenjunges",[1295]="Vis'ileth",[1296]="Xal'drunoth",[1297]="Garn",[1298]="Verezoth",[1299]="Marius & Tehd",[1300]="Flammenbringer Zol'drathul",[1301]="Ko'razz",[1302]="Feuerrufer Rok'duun",[1303]="Vel'thrak der Bestrafer",[1304]="Kriegsrufer Gorax",[1305]="Unterwerfer Doth'razel",[1306]="Balnazoth",[1307]="Zar'vok",[1308]="Teufelslord Kaz'ral",[1309]="Meisterhafte Handwerkskunst",[1310]="Geschichte in Euren Händen",[1311]="Teufelsflammenoberdämon",[1312]="Gargorok",[1313]="Knochenzermalmer Korgolath",[1314]="Zargrom",[1315]="Flammen vergangener Zeitalter",[1316]="Mazgoroth",[1318]="Bolzathar",[1319]="Roth'kar",[1322]="Erzmagus Zyrel",[1323]="Erzmagus Velysra",[1324]="Dunkelmagus Falo'reth",[1325]="Dunkelmagus Drazzok",[1326]="Häuptling Bittergischt",[1328]="Kleine Schatztruhe",[1329]="Kleine Schatztruhe",[1330]="Kleine Schatztruhe",[1331]="Flammenbringer Az'rothel",[1332]="Baldrazar",[1333]="Malphazel der Gesichtslose",[1334]="Verdammnisbringer Valus",[1335]="Vogrethar der Entweihte",[1337]="Vorthax",[1338]="Flammenruferin Vezrah",[1339]="Azbaleth",[1341]="Kleine Schatztruhe",[1342]="Kazruul",[1343]="Gorgoloth",[1344]="Herold Drel'nathar",[1345]="Herold Faraleth",[1346]="Kleine Schatztruhe",[1347]="Kleine Schatztruhe",[1348]="Raufgoth",[1349]="Kleine Schatztruhe",[1350]="Kleine Schatztruhe",[1351]="Hundemeister Stroxis",[1352]="Kleine Schatztruhe",[1353]="Kleine Schatztruhe",[1354]="Schatztruhe",[1355]="Kleine Schatztruhe",[1356]="Kleine Schatztruhe",[1357]="Schatztruhe",[1358]="Kleine Schatztruhe",[1359]="Kleine Schatztruhe",[1360]="Kleine Schatztruhe",[1361]="Glitzernde Schatztruhe",[1362]="Kleine Schatztruhe",[1363]="Schatztruhe",[1364]="Dargrol",[1365]="Argothel",[1366]="Mal'serus",[1367]="Inquisitor Tivos",[1368]="Ox'iloth",[1369]="Instabiles Fass",[1370]="Gallhirn",[1371]="Sternbock",[1372]="Teufelskommandant Urgoz",[1373]="Abyssischer Erschütterer",[1374]="Wahl des Meuchelmörders",[1375]="Wahl des Giftmörders",[1376]="Der Geschmack von Königsblut",[1378]="Arkanist Shal'iman",[1379]="Ein Liebhaber des Liquidierens",[1380]="Dul'thar",[1381]="Mordrethal",[1382]="Ur'goth",[1383]="Gor'threzal",[1384]="Magdrezoth",[1386]="Maglothar",[1387]="Schrein der Erde",[1388]="Schrein der Erde",[1389]="Schrein der Erde",[1390]="Schrein der Erde",[1391]="Schrein der Erde",[1392]="Schrein der Erde",[1393]="Schrein der Erde",[1394]="Schrein der Erde",[1395]="Schrein des Windes",[1396]="Schrein des Windes",[1397]="Schrein des Windes",[1398]="Schrein des Windes",[1399]="Schrein des Windes",[1400]="Hannval der Schlächter",[1401]="Agmozuul",[1402]="Ruheloser Meeresgeist",[1404]="Kleine Schatztruhe",[1405]="Schatztruhe",[1406]="Kleine Schatztruhe",[1407]="Teufelsflammeneruptor",[1408]="Gigantische Höllenbestie",[1409]="Selia",[1410]="Coura",[1411]="Quin'el",[1412]="Ruhelose Meister",[1413]="Die Schätze Todesschwinges",[1414]="Thogrum",[1420]="Gloth",[1421]="Gelthrak",[1422]="Eine Frage des Willens",[1423]="Das unendliche Dunkel",[1424]="Allkönigsbogen",[1425]="Die zahllosen Toten",[1426]="Unused",[1427]="Idra'zuul",[1428]="Gelgothar",[1429]="Orgrokk",[1430]="Nez'val",[1431]="Akzorek",[1432]="Dal'grozz",[1433]="Zok'verel",[1436]="Teufelskommandant Vorgroth",[1438]="Kur'zok",[1439]="Shel'drozul",[1442]="Shal'an",[1443]="Kleine Schatztruhe",[1444]="Schreckenskommandant Il'tholzul",[1445]="Druug",[1446]="Grarm",[1447]="Balzorok",[1448]="Warden Dungeon - Adventure - Dog Tags",[1449]="Unterwerfer Vuur",[1450]="Schatztruhe",[1451]="Schatztruhe",[1452]="Schatztruhe",[1453]="Untergrellangriff",[1454]="Kleine Schatztruhe",[1455]="Kleine Schatztruhe",[1456]="Glitzernde Schatztruhe",[1457]="Kleine Schatztruhe",[1458]="Kleine Schatztruhe",[1459]="Kleine Schatztruhe",[1460]="Schatztruhe",[1461]="Schatztruhe",[1462]="Kleine Schatztruhe",[1463]="Kleine Schatztruhe",[1464]="Schatztruhe",[1465]="Schatztruhe",[1466]="Schatztruhe",[1467]="Schatztruhe",[1468]="Schatztruhe",[1469]="Schatztruhe",[1470]="Schatztruhe",[1471]="Schatztruhe",[1472]="Schatztruhe",[1473]="Glitzernde Schatztruhe",[1474]="Glitzernde Schatztruhe",[1475]="Glitzernde Schatztruhe",[1476]="Glitzernde Schatztruhe",[1477]="Glitzernde Schatztruhe",[1478]="Glitzernde Schatztruhe",[1479]="Kleine Schatztruhe",[1480]="Kleine Schatztruhe",[1481]="Kleine Schatztruhe",[1482]="Kleine Schatztruhe",[1483]="Kleine Schatztruhe",[1484]="Schatztruhe",[1485]="Schatztruhe",[1486]="Kleine Schatztruhe",[1487]="Kleine Schatztruhe",[1488]="Kleine Schatztruhe",[1489]="Kleine Schatztruhe",[1490]="Kleine Schatztruhe",[1491]="Schatztruhe",[1492]="Glitzernde Schatztruhe",[1493]="Thel'draz",[1494]="Invasionspunkt",[1495]="Faulauge",[1496]="Schreckensreiter Cortis",[1497]="Magister Phaedris",[1498]="Mal'Dreth der Verderber",[1499]="Myonix",[1500]="Belagerungsmeister Aedrin",[1501]="Zar'teth",[1502]="Az'odrel",[1503]="Fäulnisbringer Velthux",[1504]="Bahagar",[1505]="Oreth der Grässliche",[1506]="Huk'roth der Hundemeister",[1507]="Arkanistin Lylandre",[1508]="Rauren",[1509]="Cadraeus",[1510]="Gezeitenklaue",[1511]="Apotheker Faldren",[1513]="Verderbter Knochenbrecher",[1515]="Wächter Thor'el",[1517]="Randril",[1518]="Randril",[1519]="Ix'dreloth",[1520]="Vel'karozz",[1521]="Schlickfratze",[1522]="Silberschlange",[1523]="Der Rattenkönig",[1524]="Tagerma die Seelensüchtige",[1525]="Seuchenschlund",[1526]="Hüllensucher",[1527]="Schreckenskapitän Thedon",[1528]="Ataxius",[1529]="Velimar",[1530]="Arkanistin Malrodi",[1531]="Lagertha",[1532]="Aegir Wellenschmetterer",[1533]="Runenseher Sigvid",[1534]="Rulf Knochenknacker",[1535]="Seelenbinderin Halldora",[1536]="Jägerin Estrid",[1537]="Felssturz der Zerfressene",[1538]="Kapitän Dargun",[1539]="Höhlenmutter Ylva",[1540]="Halfdan",[1541]="Anax",[1542]="Rasender Animus",[1543]="Dunkler Jäger",[1544]="Energietransfer",[1545]="Maugroth",[1546]="Thar'gokk",[1547]="Konstrukteur Lothaire",[1548]="Matrone Hagatha",[1549]="Gol'drazel",[1550]="Zaar'koz",[1551]="Dro'zek",[1552]="Schimmernde uralte Manazusammenballung",[1553]="Schimmernde uralte Manazusammenballung",[1554]="Schimmernde uralte Manazusammenballung",[1555]="Schimmernde uralte Manazusammenballung",[1556]="Schimmernde uralte Manazusammenballung",[1557]="Schimmernde uralte Manazusammenballung",[1558]="Adliger Klingenmeister",[1559]="Miasu",[1560]="Botschafter D'vwinn",[1561]="Karthax",[1562]="Kleine Schatztruhe",[1563]="Kleine Schatztruhe",[1564]="Kleine Schatztruhe",[1565]="Schatztruhe",[1566]="Kleine Schatztruhe",[1567]="Kleine Schatztruhe",[1568]="Kleine Schatztruhe",[1569]="Schatztruhe",[1570]="Kleine Schatztruhe",[1571]="Kleine Schatztruhe",[1572]="Schatztruhe",[1573]="Kleine Schatztruhe",[1574]="Kleine Schatztruhe",[1575]="Kleine Schatztruhe",[1576]="Schatztruhe",[1577]="Glitzernde Schatztruhe",[1578]="Schatztruhe",[1579]="Kleine Schatztruhe",[1580]="Kleine Schatztruhe",[1581]="Kleine Schatztruhe",[1582]="Glitzernde Schatztruhe",[1583]="Kleine Schatztruhe",[1584]="Schatztruhe",[1585]="Kleine Schatztruhe",[1586]="Kleine Schatztruhe",[1587]="Kleine Schatztruhe",[1588]="Schatztruhe",[1589]="Schatztruhe",[1590]="Kleine Schatztruhe",[1591]="Kleine Schatztruhe",[1592]="Kleine Schatztruhe",[1593]="Schatztruhe",[1594]="Schatztruhe",[1595]="Kleine Schatztruhe",[1596]="Kleine Schatztruhe",[1597]="Kleine Schatztruhe",[1598]="Schatztruhe",[1599]="Schatztruhe",[1600]="Schatztruhe",[1601]="Schatztruhe",[1602]="Glitzernde Schatztruhe",[1603]="Thal'goroth",[1604]="Lysanis Schattenseele",[1605]="Jade Dunkelhafen",[1606]="Glutschwinge",[1607]="Bestrix",[1608]="Zwickzange",[1609]="Gorgroth",[1610]="Schattenfeder",[1611]="Xel'varek",[1612]="Schreckenskommandant Nath'razel",[1613]="Torrentius",[1614]="Meereskönig Tidross",[1615]="Marius & Tehd",[1616]="Born der Weisheit",[1617]="Maia der Weiße",[1618]="Teufelskommandant Maz'golar",[1619]="Valazar der Verderber",[1620]="Baalstrog",[1621]="Smoth",[1622]="Wilder Worgen",[1623]="Verräterische Hengste",[1624]="Schatulle des Hauses Rabenkrone",[1625]="Schatztruhe",[1626]="Alptraumbeute",[1627]="Kästchen mit Kleinodien",[1628]="Verkrustete Kvaldirtruhe",[1629]="Gestohlene Waren der Himmelshörner",[1630]="Deplatzierte Kiste",[1631]="Truhe der Legion",[1632]="Kleine Schatztruhe",[1633]="Kleine Schatztruhe",[1634]="Kleine Schatztruhe",[1635]="Kleine Schatztruhe",[1636]="Zornschlund",[1637]="Genn",[1639]="Jaina",[1640]="Varian",[1641]="Gelbin",[1642]="Mar'tura",[1643]="Wilder Worgen",[1644]="Wilder Worgen",[1645]="Wilder Worgen",[1646]="Wilder Worgen",[1647]="Wilder Worgen",[1648]="Kleine Schatztruhe",[1649]="Kleine Schatztruhe",[1650]="Schatztruhe",[1651]="Kleine Schatztruhe",[1652]="Baine",[1653]="Sylvanas",[1654]="Thrall",[1655]="Vol'jin",[1656]="Sel'farius",[1657]="Drel'vareus",[1658]="Erzmagierin Nielthende",[1659]="Arkanistin Halice",[1660]="Erzmagier Kesalon",[1661]="Mal'drovas",[1662]="Val'rothar",[1663]="Vol'zeth",[1664]="Sath'razel",[1665]="Volynd Sturmbringer",[1666]="Uralte Witwe",[1667]="General Tel'arn",[1668]="Braxas der Fleischschnitzer",[1669]="Erzmagier Galeorn",[1670]="Kelorn Nachtklinge",[1671]="Kleine Schatztruhe",[1672]="Kleine Schatztruhe",[1673]="Frostsplitter",[1674]="Schatztruhe",[1675]="Schatztruhe",[1676]="Schatztruhe",[1677]="Sal'thezrus",[1678]="Schatztruhe",[1679]="Kleine Schatztruhe",[1680]="Mondwachenportal",[1681]="Dämonenversklavter Vollstrecker",[1682]="Mondwachenportal",[1683]="Portal nach Nihilam",[1684]="Leutnant Strathmar",[1685]="Inquisitor Volitix",[1686]="Flammenwirker Verathix",[1687]="Boshafter Walhai",[1688]="Brutmutter Lizax",[1689]="Der Muskel",[1690]="Kommandant Soraax",[1691]="Lady Rivantas",[1692]="Llorian",[1693]="Glitzernde Schatztruhe",[1694]="Kozrum",[1695]="Degrazol der Nötigende",[1697]="Invasionsort",[1698]="Schatztruhe",[1699]="Invasionspunkt",[1701]="Angriffspunkt",[1702]="Azrok der Folterer",[1720]="Verdammnisgeißel",[1721]="Ariadne",[1722]="Schatzgoblin",[1724]="Schatztruhe",[1725]="Schatztruhe",[1726]="Schatztruhe",[1727]="Schatztruhe",[1728]="Schatztruhe",[1729]="Schatztruhe",[1730]="Schatztruhe",[1731]="Schatztruhe",[1732]="Schatztruhe",[1733]="Schatztruhe",[1734]="Schatztruhe",[1735]="Schatztruhe",[1736]="Schatztruhe",[1737]="Schatztruhe",[1738]="Schatztruhe",[1739]="Schatztruhe",[1740]="Schatztruhe",[1741]="Schatztruhe",[1742]="Schatztruhe",[1743]="Schatztruhe",[1744]="Schatztruhe",[1745]="Schatztruhe",[1746]="Schatztruhe",[1747]="Schatztruhe",[1748]="Schatztruhe",[1749]="Schatztruhe",[1750]="Schatztruhe",[1751]="Schatztruhe",[1752]="Schatztruhe",[1753]="Überladener Seelensplitter",[1754]="Schatztruhe",[1755]="Schatztruhe",[1756]="Schatztruhe",[1757]="Schatztruhe",[1758]="Schatztruhe",[1759]="Schatztruhe",[1760]="Schatztruhe",[1761]="Schatztruhe",[1762]="Schatztruhe",[1763]="Schatztruhe",[1764]="Schatztruhe",[1765]="Schatztruhe",[1766]="Schatztruhe",[1767]="Schatztruhe",[1768]="Schatztruhe",[1769]="Schatztruhe",[1770]="Schatztruhe",[1771]="Schatztruhe",[1772]="Schatztruhe",[1773]="Schatztruhe",[1774]="Schatztruhe",[1775]="Schatztruhe",[1776]="Schatztruhe",[1777]="Schatztruhe",[1778]="Schatztruhe",[1779]="Schatztruhe",[1780]="Schatztruhe",[1781]="Schatztruhe",[1782]="Schatztruhe",[1783]="Schatztruhe",[1784]="Schatztruhe",[1785]="Schatztruhe",[1786]="Zirux",[1787]="Schläger der Mo'arg",[1788]="Schatz eines Meeresriesen",[1789]="Erzürnter Meeresriese",[1790]="Schatz eines Meeresriesen",[1791]="Teufelssplitter",[1797]="Horde von Höllenbestien",[1798]="Asgrims Grabgesang",[1800]="Vergoldeter Wächter",[1801]="Torm der Schläger",[1802]="Az'jatar",[1803]="Volshax der Willensbrecher",[1804]="Auditor Esiel",[1805]="Magistrix Vilessa",[1806]="Sorallus",[1807]="Achronos",[1808]="Kosumoth der Hungernde",[1809]="Ealdis",[1810]="Herold der Schreie",[1811]="Aodh Welkblüte",[1812]="Rabxach",[1813]="Nylaathria die Vergessene",[1814]="Tiefenschere",[1815]="Lytheron",[1816]="Hauptschatzmeister Jabril",[1817]="Marblub der Massive",[1818]="Hexendoktor Grgl-Brgl",[1819]="Arkanor Prime",[1820]="Feurio",[1821]="Die Flüsterin",[1822]="Sturmfeder",[1823]="Fjordun",[1824]="Shalas'aman",[1825]="Malisandra",[1826]="Selenyi",[1827]="Colerian",[1828]="Alteria",[1829]="Sichelmeister Cil'raman",[1830]="Oglok der Rasende",[1831]="Fjorlag der Grabeshauch",[1833]="Xavrix",[1834]="Ormagrogg",[1835]="Olokk der Schiffszerstörer",[1836]="Mawat'aki",[1837]="Defilia",[1838]="Ala'washte",[1839]="Valakar der Durstige",[1840]="Mortiferus",[1841]="Salzbart der Auferstandene",[1842]="Malfarius",[1843]="Gorgamaul",[1844]="Magdromath",[1845]="Kleine Schatztruhe",[1846]="Teufelsruferin Zelthae",[1847]="Teufelsbeschwörer Xar'thok",[1848]="Glutfeuer",[1849]="Inquisitor Eisbann",[1850]="Xorogun der Flammenschnitzer",[1851]="Glutbiest der Teufelsrachen",[1852]="Schreckensklingenvernichter",[1853]="Trankmeister Glug",[1854]="Verdammnisbringer Zar'thoz",[1855]="Salethan der Brutwandler",[1856]="Malgrazoth",[1857]="Kar'zun",[1858]="Flugmeister Volnath",[1860]="Altvater Winter",[1861]="Knochenzermalmer Korgolath",[1862]="Gargorok",[1863]="Zar'vok",[1864]="Thol'drel",[1865]="Thal'xur",[1866]="Zar'teth",[1867]="Za'kaar",[1868]="Aldrugoth",[1869]="Dral'zeth",[1870]="Zagmothar",[1871]="Larthogg",[1872]="Il'drethal",[1873]="Draz'guul",[1874]="Schlachtbrett der Verheerten Küste",[1881]="Balnazoth",[1882]="Gelthrog",[1883]="Malorus der Seelenwärter",[1884]="Teufelsruferin Thalezra",[1885]="Schreckensauge",[1886]="Artefaktforschung",[1887]="Lord Hel'nurath",[1888]="Wichtelmutter Bruva",[1894]="Malgrazoth",[1897]="Kleine Schatztruhe",[1898]="Kleine Schatztruhe",[1899]="Larithia",[1900]="Wa'glur",[1901]="Raga'yut",[1902]="Schreckenssprecher Serilis",[1903]="Herrin Dominix",[1904]="Jorvild der Vertraute",[1905]="Flllurlokkr",[1906]="Verderbter Knochenbrecher",[1907]="Aqueux",[1908]="Kleine Schatztruhe",[1909]="Kleine Schatztruhe",[1910]="Kleine Schatztruhe",[1911]="Kleine Schatztruhe",[1912]="Kleine Schatztruhe",[1913]="Kleine Schatztruhe",[1914]="Kleine Schatztruhe",[1915]="Kleine Schatztruhe",[1916]="Kleine Schatztruhe",[1917]="Brutmutter Nix",[1918]="Kleine Schatztruhe",[1919]="Kleine Schatztruhe",[1920]="Kleine Schatztruhe",[1921]="Kleine Schatztruhe",[1922]="Kleine Schatztruhe",[1923]="Kleine Schatztruhe",[1924]="Kleine Schatztruhe",[1925]="Kleine Schatztruhe",[1926]="Kleine Schatztruhe",[1927]="Kleine Schatztruhe",[1928]="Kleine Schatztruhe",[1929]="Kleine Schatztruhe",[1930]="Kleine Schatztruhe",[1931]="Kleine Schatztruhe",[1932]="Kleine Schatztruhe",[1933]="Kleine Schatztruhe",[1934]="Kleine Schatztruhe",[1935]="Kleine Schatztruhe",[1936]="Kleine Schatztruhe",[1937]="Kleine Schatztruhe",[1938]="Kleine Schatztruhe",[1939]="Kleine Schatztruhe",[1940]="Kleine Schatztruhe",[1941]="Kleine Schatztruhe",[1942]="Kleine Schatztruhe",[1943]="Kleine Schatztruhe",[1944]="Kleine Schatztruhe",[1945]="Kleine Schatztruhe",[1946]="Kleine Schatztruhe",[1947]="Grossir",[1948]="Bruder Badatin",[1949]="Tangfaust",[1950]="Dresanoth",[1951]="Erdu'val",[1952]="Tiefenmaul",[1953]="Instabiles Netherportal",[1954]="Lady Eldrathe",[1955]="Dämmerfinsternis",[1956]="Ryul der Schwindende",[1957]="Der Schreckenspirscher",[1958]="Kriegsfürst Darjah",[1959]="Unheilvoller Kürassier",[1960]="Verzerrter Leerenfürst",[1961]="Missgestaltete Terrorwache",[1962]="Wahnsinniger Sukkubus",[1963]="Verrückte Shivarra",[1964]="Zermürbender Oberdämon",[1965]="Anomaler Aufseher",[1966]="Instabiler Wichtel",[1967]="Flimmernder Teufelsjäger",[1968]="Instabiler Abyssal",[1969]="Herzog Sithizi",[1970]="Auge von Gurgh",[1971]="Naisha",[1972]="Dresanoth",[1973]="Liquidator der Legion",[1974]="Ardaan der Ehrwürdige",[1975]="Tercin Shivenllher",[1976]="Die alte Rotana",[1977]="Schatztruhe",[1978]="Allianzkonvoi",[1979]="Hordenereignis",[1980]="Die Feste Nordwacht",[1983]="Nordwachtstraße",[1984]="Grabenlager",[1985]="Der Gefechtsstand",[1986]="Der Gefechtsstand",[1987]="Grabenlager",[1988]="Wird angegriffen",[1996]="Belagerungsmeister Voraan",[1998]="Umbra'jin",[1999]="Horde",[2000]="Blutsichel",[2001]="Schatztruhe",[2002]="Schatztruhe",[2003]="Death-Metal-Ritter",[2004]="Golrakahn",[2007]="X'ue",[2008]="Knochenhüter Makiri",[2009]="Vollgefressener Saurolisk",[2010]="Kal'draxa",[2012]="Invasionspunkt",[2013]="Befallenes Terrorhorn",[2014]="Herrenloser Schatz",[2015]="Betti",[2016]="Großer Invasionspunkt",[2017]="Werkstatt",[2018]="Ställe",[2019]="Schmied",[2020]="Kaserne",[2021]="Gebäude der Horde",[2022]="Verbündete verfügbar",[2024]="Schatztruhe",[2025]="Schatztruhe",[2026]="Schatztruhe",[2027]="Truhe voller Gold",[2028]="Krubbs",[2029]="Die verfluchte Truhe",[2030]="Verfluchte Truhe",[2031]="Uralter Kieferknirscher",[2032]="Kriegshetzer Kro'goth",[2033]="Aufseher Krix",[2034]="Doug Test - Frostfire Gronnling",[2035]="Stachelrattenmatriarchin",[2038]="Kul'krazahn",[2039]="Schatztruhe",[2040]="Schatztruhe",[2041]="Schatztruhe",[2042]="Schatztruhe",[2043]="Schatztruhe",[2044]="Schatztruhe",[2045]="Schatztruhe",[2046]="Schatztruhe",[2047]="Schatztruhe",[2048]="Schatztruhe",[2049]="Schatztruhe",[2050]="Schatztruhe",[2051]="Schatztruhe",[2052]="Schatztruhe",[2053]="Schatztruhe",[2054]="Schatztruhe",[2055]="Obsidiantodeswärter",[2056]="Schatztruhe",[2057]="Schatztruhe",[2058]="Schatztruhe",[2059]="Schatztruhe",[2060]="Schatztruhe",[2061]="Schatztruhe",[2062]="Schatztruhe",[2063]="Schatztruhe",[2064]="Schatztruhe",[2065]="Schatztruhe",[2066]="Schatztruhe",[2067]="Überfüttertes Rachenscheusal",[2068]="Totemmacherin Jash'ga",[2069]="Schatztruhe",[2070]="Schatztruhe",[2071]="Schatztruhe",[2072]="Schatztruhe",[2073]="Schatztruhe",[2074]="Schatztruhe",[2075]="Schatztruhe",[2076]="Schatztruhe",[2077]="Schatztruhe",[2078]="Schatztruhe",[2079]="Schatztruhe",[2081]="Schatztruhe",[2082]="Schatztruhe",[2083]="Schatztruhe",[2084]="Schatztruhe",[2085]="Schatztruhe",[2086]="Schatztruhe",[2087]="Schatztruhe",[2088]="Schatztruhe",[2089]="Schatztruhe",[2090]="Schatztruhe",[2091]="Schatztruhe",[2092]="Schatztruhe",[2093]="Schatztruhe",[2094]="Schatztruhe",[2095]="Schatztruhe",[2096]="Schatztruhe",[2097]="Schatztruhe",[2098]="Schatztruhe",[2099]="Schatztruhe",[2100]="Schatztruhe",[2101]="Schatztruhe",[2102]="Schatztruhe",[2103]="Schatztruhe",[2104]="Schatztruhe",[2105]="Schatztruhe",[2106]="Schatztruhe",[2107]="Schatztruhe",[2108]="Schatztruhe",[2109]="Schatztruhe",[2110]="Schatztruhe",[2111]="Schatztruhe",[2112]="Schatztruhe",[2113]="Schatztruhe",[2114]="Schatztruhe",[2115]="Schatztruhe",[2116]="Schatztruhe",[2117]="Schatztruhe",[2118]="Schatztruhe",[2119]="Schatztruhe",[2120]="Bajiatha",[2121]="Schatztruhe",[2122]="Schatztruhe",[2123]="Schatztruhe",[2124]="Schatztruhe",[2125]="Schatztruhe",[2126]="Schatztruhe",[2127]="Schatztruhe",[2128]="Schatztruhe",[2129]="Schatztruhe",[2130]="Leichenbringerin Yal'kar",[2137]="Schatztruhe",[2138]="Schatztruhe",[2139]="Schatztruhe",[2140]="Schatztruhe",[2141]="Schatztruhe",[2142]="Schatztruhe",[2143]="Schatztruhe",[2144]="Schatztruhe",[2145]="Schatztruhe",[2146]="Schatztruhe",[2147]="Schatztruhe",[2148]="Schatztruhe",[2149]="Schatztruhe",[2150]="Schatztruhe",[2151]="Schatztruhe",[2152]="Schatztruhe",[2153]="Schatztruhe",[2154]="Schatztruhe",[2155]="Schatztruhe",[2156]="Schatztruhe",[2157]="Schatztruhe",[2158]="Schatztruhe",[2159]="Schatztruhe",[2160]="Schatztruhe",[2161]="Schatztruhe",[2162]="Schatztruhe",[2163]="Schatztruhe",[2164]="Schatztruhe",[2165]="Schatztruhe",[2166]="Schatztruhe",[2167]="Schatztruhe",[2168]="Schatztruhe",[2169]="Schatztruhe",[2170]="Schatztruhe",[2171]="Schatztruhe",[2172]="Schatztruhe",[2173]="Schatztruhe",[2174]="Schatztruhe",[2175]="Schatztruhe",[2176]="Schatztruhe",[2177]="Schatztruhe",[2178]="Schatztruhe",[2179]="Schatztruhe",[2180]="Schatztruhe",[2181]="Schatztruhe",[2182]="Schatztruhe",[2183]="Schatztruhe",[2184]="Schatztruhe",[2185]="Schatztruhe",[2186]="Schatztruhe",[2187]="Schatztruhe",[2190]="Kommandant Reinholz",[2191]="Verteidiger Hakbi",[2192]="Besudelter Wächter",[2194]="Za'amar",[2195]="Blutpriesterin Xak'lar",[2196]="Kandak",[2197]="Khazaduum",[2198]="Kommandant Sathrenael",[2199]="Kommandantin Vecaya",[2200]="Kommandant Endaxis",[2201]="Schwester Subversia",[2202]="Schatztruhe",[2203]="Kleine Schatztruhe",[2204]="Kleine Schatztruhe",[2205]="Kleine Schatztruhe",[2206]="Kleine Schatztruhe",[2207]="Kleine Schatztruhe",[2208]="Kleine Schatztruhe",[2209]="Verbündete verfügbar",[2210]="Kleine Schatztruhe",[2211]="Kleine Schatztruhe",[2212]="Kleine Schatztruhe",[2213]="Kleine Schatztruhe",[2214]="Kleine Schatztruhe",[2215]="Kleine Schatztruhe",[2216]="Kleine Schatztruhe",[2217]="Kleine Schatztruhe",[2218]="Kleine Schatztruhe",[2219]="Kriegstrommlerin Zurula",[2220]="Ahalt'cob",[2221]="Giftkiefer",[2222]="Talestra die Grässliche",[2223]="Vagath der Verratene",[2224]="Gwugnug der Verfluchte",[2225]="Tereck der Ausleser",[2226]="Meuterer Kabwalla",[2227]="Teerspucker",[2228]="Wichtelmutter Laglath",[2229]="Naroua",[2230]="Schattenzauberer Voruun",[2231]="Treiber Kravos",[2232]="Seelenverzerrte Monstrosität",[2233]="Kaara die Bleiche",[2234]="Baruut der Blutrünstige",[2235]="Fiesel der Muffindieb",[2236]="Wache Thanos",[2237]="Wache Kuro",[2238]="Giftschwanzhimmelsflosse",[2239]="Turek der Wache",[2240]="Hauptmann Faruq",[2241]="Umbraliss",[2242]="Ataxon",[2243]="Sorolis der Unglückselige",[2244]="Vorbote des Chaos",[2245]="Jed'hinchampion Vorusk",[2246]="Aufseherin Y'Beda",[2247]="Aufseherin Y'Sorna",[2248]="Aufseherin Y'Morna",[2249]="Lehrmeisterin Tarahna",[2250]="Zul'tan der Zahllose",[2251]="Kommandant Xethgar",[2252]="Skreeg der Verschlinger",[2253]="Sabuul",[2254]="Schatztruhe der Eredar",[2255]="Kiste mit Diebesgut",[2256]="Streitiger Studentenschatz",[2257]="Leerenberührte Truhe",[2258]="Geheimversteck der Augari",[2259]="Truhe des verzweifelten Eredar",[2260]="Zerschmetterte Haustruhe",[2261]="Schatz des Verdammnissuchers",[2263]="Sauroliskenzähmer Mugg",[2265]="Puscilla",[2266]="Ven'orn",[2267]="Vrax'thul",[2268]="Varga",[2269]="Leutnant Xakaar",[2270]="Zornfürst Yarez",[2271]="Inquisitor Vethroz",[2272]="Kommandant Texlaz",[2273]="Admiral Rel'var",[2274]="Allseher Xanarian",[2276]="Weltenspalter Skuul",[2277]="Hundemeister Kerrax",[2278]="Beobachter Aival",[2279]="Leerenwächterin Valsuran",[2280]="Dornstachelkönigin",[2281]="Oberster Alchemist Munculus",[2282]="Die Paraxis",[2283]="Occularus",[2284]="Matrone Folnuna",[2285]="Sotanathor",[2286]="Inquisitor Meto",[2287]="Herrin Alluradel",[2288]="Grubenlord Vilemus",[2289]="Verlorene Krokultruhe",[2290]="Turmkiste der Legion",[2291]="Notfallkiste der Krokul",[2292]="Knochenbildnis",[2293]="Vernachlässigte Angelrute",[2294]="Slithon die Letzte",[2295]="Opfergaben der Auserwählten",[2296]="Innenhof",[2297]="Innenhof",[2298]="Dornrückenbrutmutter",[2299]="Sauroliskenmatriarchin",[2300]="Der Vielgesichtige Verschlinger",[2301]="Schwadronskommandant Vishax",[2302]="Verdammniswirker Suprax",[2303]="Seelenhüter Videx",[2304]="Mutter Rosula",[2305]="Rezira der Seher",[2306]="Späher Skrasniss",[2307]="Kriegsmatrone Zug",[2308]="Knochenschwall",[2309]="Gefräßiger Yeti",[2310]="Schmarotzerpatriarch",[2311]="Langzahn und Wellenbruch",[2313]="Vizz der Sammler",[2314]="Torraske der Ewige",[2315]="Vergessene Vorräte der Legion",[2316]="Uralte Kriegstruhe der Legion",[2317]="Teufelsgebundene Truhe",[2318]="Schatz der Legion",[2319]="Verwitterte Teufelstruhe",[2320]="Augarirunentruhe",[2321]="Uralter Sarkophag",[2322]="Kleine Schatztruhe",[2323]="Geheime Augaritruhe",[2324]="Augaribesitztümer",[2325]="Verschollener Augarischatz",[2326]="Wertvolle Augariandenken",[2327]="Vermisste Augaritruhe",[2328]="Blasenmaul",[2329]="Kleine Schatztruhe",[2330]="Kleine Schatztruhe",[2331]="Schatztruhe",[2332]="Abscheulicher Ritualschädel",[2333]="Kleine Schatztruhe",[2334]="Kleine Schatztruhe",[2335]="Kleine Schatztruhe",[2336]="Kleine Schatztruhe",[2337]="Fleischfetz der Hungrige",[2338]="Leerenklinge Zedaat",[2339]="Zwielichtbote Tharuul",[2340]="Rufer der Dunkelheit",[2341]="Leerenschlund",[2344]="Gar'zoth",[2345]="Herrin Il'thendra",[2346]="Kleine Schatztruhe",[2348]="Kleine Schatztruhe",[2349]="Kleine Schatztruhe",[2350]="Die einsame Krona",[2351]="Bajiani die Aalglatte",[2352]="Azer'tor",[2353]="Kleine Schatztruhe",[2354]="Kleine Schatztruhe",[2355]="Kleine Schatztruhe",[2356]="Kleine Schatztruhe",[2357]="Schatz des Kriegsherrn",[2358]="Schatztruhe",[2359]="Blutwulst",[2360]="Frostfels",[2361]="Schlitz-Ritz der Fresser",[2363]="Verfluchte Truhe der Nazmani",[2364]="Kleine Schatztruhe",[2365]="Kleine Schatztruhe",[2366]="Kleine Schatztruhe",[2367]="Kleine Schatztruhe",[2368]="Kleine Schatztruhe",[2369]="Kleine Schatztruhe",[2370]="Kleine Schatztruhe",[2371]="Unkontrolliert",[2372]="Kleine Schatztruhe",[2373]="Kleine Schatztruhe",[2374]="Kleine Schatztruhe",[2375]="Kleine Schatztruhe",[2376]="Uroku der Gebundene",[2377]="Kleine Schatztruhe",[2378]="Kleine Schatztruhe",[2379]="Kleine Schatztruhe",[2380]="Raunz der Übellaunige",[2381]="Königin Tzxi'kik",[2382]="Wunjas Schatz",[2383]="König Kooba",[2384]="Brodelnde Truhe",[2385]="Kleine Schatztruhe",[2386]="Kleine Schatztruhe",[2387]="Herold von Thun'ka",[2388]="Kleine Schatztruhe",[2389]="Kleine Schatztruhe",[2390]="Belagerungsmaschine",[2391]="Kriegshetzer Hozzik",[2392]="Brücke",[2393]="Hügelkuppe",[2394]="Ost",[2395]="Sägewerk",[2396]="Schlachtfeld",[2397]="Brücke",[2398]="Hügelkuppe",[2399]="Ost",[2400]="Sägewerk",[2401]="Schlachtfeld",[2402]="West",[2403]="West",[2404]="Grozgor",[2405]="Azerit",[2406]="Riesiger Sandschnapper",[2407]="Avatar von Xolotal",[2408]="Azeritgeysir",[2409]="Kleine Schatztruhe",[2410]="Zunashi der Verbannte",[2411]="Aufgeblähter Krolusk",[2412]="Verstoßener Ra-Ra",[2413]="Schrein von Thun'ka",[2419]="Blutgeweih",[2420]="Offensichtlich sichere Truhe",[2421]="Kleine Schatztruhe",[2422]="Angeschwemmte Truhe",[2423]="Opfergabe für Bwonsamdi",[2424]="Kleine Schatztruhe",[2425]="Kleine Schatztruhe",[2426]="Kleine Schatztruhe",[2427]="Kleine Schatztruhe",[2428]="Kleine Schatztruhe",[2429]="Kleine Schatztruhe",[2430]="Kleine Schatztruhe",[2431]="Vinyeti",[2433]="Legionsinvasion",[2434]="Kralle",[2435]="Emely Maidorf",[2436]="Mine",[2439]="Test Vignette Glow (msc)",[2440]="Nimmermehr",[2441]="Unheilsdorn",[2443]="Kleine Schatztruhe",[2444]="Anthemusa",[2445]="Vathikur",[2446]="Aschmähne",[2447]="Schwarmmutter Kraxi",[2448]="Kleine Schatztruhe",[2449]="Kleine Schatztruhe",[2450]="Kleine Schatztruhe",[2451]="Kleine Schatztruhe",[2452]="Kleine Schatztruhe",[2453]="Kleine Schatztruhe",[2457]="Kleine Schatztruhe",[2458]="Kleine Schatztruhe",[2459]="Kleine Schatztruhe",[2460]="Kleine Schatztruhe",[2466]="Schmugglervorrat",[2467]="Glückstruhe von Horace dem Glückspilz",[2468]="Holzfäller",[2469]="Schatztruhe",[2470]="Kleine Schatztruhe",[2471]="Genial\"\" getarnte Truhe",[2472]="Truppen ausbilden",[2473]="Giftsiegeltruhe",[2474]="Kleine Schatztruhe",[2475]="Kleine Schatztruhe",[2476]="Kleine Schatztruhe",[2477]="Schatztruhe",[2478]="Kleine Schatztruhe",[2479]="Forschung",[2480]="Fahrzeugproduktion",[2481]="Kleine Schatztruhe",[2482]="Schatztruhe",[2483]="Kleine Schatztruhe",[2484]="Schatztruhe",[2485]="Kleine Schatztruhe",[2486]="Kleine Schatztruhe",[2487]="Schatztruhe",[2488]="Schatztruhe",[2489]="Kleine Schatztruhe",[2490]="Schatztruhe",[2491]="Merianae",[2492]="Rudelführer Asenya",[2493]="Schatztruhe",[2494]="Schatztruhe",[2495]="Kleine Schatztruhe",[2496]="Lei-zhi",[2498]="Kleine Schatztruhe",[2499]="Bluthexe Ysinna",[2500]="Schätze Pandarias",[2501]="Teres",[2502]="Vorarbeiter Zettel",[2504]="Kleine Schatztruhe",[2505]="Kleine Schatztruhe",[2507]="Kleine Schatztruhe",[2508]="Kleine Schatztruhe",[2509]="Kleine Schatztruhe",[2510]="Kleine Schatztruhe",[2511]="Wächter der Quelle",[2512]="Schatztruhe",[2513]="Zayoos",[2514]="Kleine Schatztruhe",[2515]="Kleine Schatztruhe",[2517]="Kleine Schatztruhe",[2518]="Kulett die Störrische",[2519]="Kleine Schatztruhe",[2520]="Kleine Schatztruhe",[2521]="Kleine Schatztruhe",[2522]="Brutmutter Razora",[2523]="Kleine Schatztruhe",[2524]="Tambano",[2525]="Puschel",[2526]="Zayolin",[2527]="Dornenschwinge",[2528]="Kleine Schatztruhe",[2529]="Mala'kili und Rohnkor",[2530]="Rohn'kor",[2531]="Verschluckte Truhe",[2533]="Halb verdauter Schatz",[2534]="Kleine Schatztruhe",[2535]="Doppelherzkonstrukt",[2536]="Orkansturm",[2537]="Alte eisenbeschlagene Truhe",[2538]="Brück'ntroll",[2539]="Baschmu",[2540]="Gärtner",[2541]="Der schwarzäugige Bartholomäus",[2542]="Schmugglerversteck",[2543]="Verwüster",[2544]="Himmelsschrecken der Fuchsbauwaldung",[2545]="Tosender Strom",[2546]="Schmuddelschnabel",[2547]="Auditor Dolp",[2548]="Kiboku",[2549]="Krächz",[2550]="Held",[2551]="Gallenzahnmutter",[2552]="Eisenvorkommen",[2553]="Kleine Schatztruhe",[2554]="Kleine Schatztruhe",[2555]="Hauptmann Klingenstachel",[2560]="Leon der Todesbote",[2561]="Leon der tote Bote",[2562]="Leyjäger Gaston",[2563]="Zan'ya Teufelsmaske",[2564]="Elementarist Zapi'boi",[2565]="Qroshekx",[2566]="Ssinkrix",[2567]="Xaarshej",[2570]="Ogmot der Verrückte",[2571]="Der Goblintrupp",[2572]="Kneipenwirt Willy",[2573]="Aschenwindschätze",[2574]="Grollender Goliath",[2575]="Fozruk",[2576]="Zweigfürst Aldrus",[2577]="Champions der Allianz",[2578]="Champions der Allianz",[2579]="Die Großfuhre",[2580]="Schatz des Hexendoktors",[2581]="G'Naat",[2582]="Kleine Schatztruhe",[2583]="Brutmutter Chimal",[2584]="Tia'Kawan",[2585]="Flusszahn",[2586]="Xu'e",[2587]="Dolchzahn",[2588]="Gotaka der Atal'zul",[2589]="Mordschnabel",[2590]="Kleine Schatztruhe",[2591]="Verdächtiger Fleischhaufen",[2592]="Hügelbrutmutter",[2593]="Jax'teb der Wiederbelebte",[2594]="Janis Schatz",[2595]="Kleine Schatztruhe",[2596]="Kleine Schatztruhe",[2597]="Verderbter Spross von Rezan",[2598]="Aiji der Verfluchte",[2599]="Juba der Vernarbte",[2600]="Xu'ba der Knochensammler",[2601]="Lo'kuno",[2602]="Vorratsabwurf",[2603]="Glompschlund",[2604]="Golanar",[2605]="Vugthuth",[2606]="Azerit an der Absturzstelle",[2607]="Azerit am Wasserfall",[2608]="Azerit bei den Ruinen",[2609]="Azerit bei der Warte",[2610]="Azerit am Sturz",[2611]="Azerit am Turm",[2612]="Azerit am Gezeitenbecken",[2613]="Azerit beim Tempel",[2614]="Azerit beim Schiffswrack",[2615]="Azerit beim Kamm",[2616]="Azerit bei den Teergruben",[2617]="Azerit am Feuer",[2618]="Azerit an der Absturzstelle",[2619]="Azerit am Wasserfall",[2620]="Azerit bei den Ruinen",[2621]="Azerit bei der Warte",[2622]="Azerit am Sturz",[2623]="Azerit am Turm",[2624]="Azerit am Gezeitenbecken",[2625]="Azerit beim Tempel",[2626]="Azerit beim Schiffswrack",[2627]="Azerit beim Kamm",[2628]="Azerit bei den Teergruben",[2629]="Azerit am Feuer",[2630]="Zanxib der Aufgedunsene",[2631]="Janis Schatz",[2632]="Janis Schatz",[2633]="Große Schatztruhe",[2634]="Große Schatztruhe",[2635]="Schlachtkriecher Karkithiss",[2636]="Gahz'ralka",[2637]="Große Schatztruhe",[2638]="Schatztruhe der Schwertwasserkorsaren",[2639]="Kriegsfürst Sreptik",[2640]="Zujothgul",[2641]="Klingenschlund",[2642]="Shul-Nagruth",[2643]="Drukengu",[2644]="A'yame",[2647]="Perle der Gefahr!",[2648]="Unterfürst Xerxiz",[2649]="Vukuba",[2650]="Seltsames Ei",[2651]="Ködereimer",[2652]="Tyrannenechse von Xibala",[2653]="Greifholzwächter",[2654]="Frostige Schatztruhe",[2655]="Kamid der Fallensteller",[2656]="Biengetüm",[2657]="Scharfrichter Schwartz",[2658]="Azeritdurchströmte Schlacke",[2659]="Verlorene Schriftrolle",[2660]="Chags Herausforderung",[2661]="Azeritdurchströmter Elementar",[2662]="Honigbär",[2663]="Kleine Schatztruhe",[2664]="Kleine Schatztruhe",[2665]="Geschenk der gebrochenen Herzen",[2666]="Holzhaufen",[2667]="Kleine Schatztruhe",[2668]="Himmelsrufer Teskris",[2669]="Schatztruhe",[2672]="Gefangene Kriegsmatrone",[2673]="Kopfjägerin Lee'za",[2674]="Kriegsfürst Zothix",[2675]="Brgl-Lrgl der Schläger",[2676]="Hexendoktor Habra'du",[2677]="Mor'fani der Verbannte",[2678]="Todeskappe",[2679]="Lady Seirine",[2680]="Umbra'rix",[2681]="Erntezeit",[2682]="Hakbi der Auferstandene",[2683]="Himmelsschnitzer Krakit",[2684]="Hyo'gi",[2685]="Dunkelsprecher Jo'la",[2691]="Dazars vergessene Truhe",[2692]="Schatztruhe",[2693]="Schatztruhe",[2694]="Schatztruhe",[2695]="Schatztruhe",[2696]="Gruppe F: Schatztruhe",[2697]="Schatztruhe",[2698]="Schatztruhe",[2699]="Schatztruhe",[2700]="Schatztruhe",[2701]="Schatztruhe",[2702]="Schatztruhe",[2703]="Schatztruhe",[2704]="Schatztruhe",[2705]="Ragna",[2706]="Schatztruhe",[2707]="Schatztruhe",[2708]="Schatztruhe",[2709]="Schatztruhe",[2710]="Dagrus der Verachtete",[2711]="Die Großfuhre",[2770]="Kampf gegen Windmühlen",[2771]="Kua'fon",[2772]="Kua'fon",[2773]="Kua'fon",[2774]="Kua'fon",[2775]="Kaserne",[2776]="Haupthaus",[2777]="Altar der Stürme",[2778]="Werkstatt",[2779]="Arsenal",[2780]="Wagga Knurrzahn",[2781]="Kua'fon",[2782]="Kua'fon",[2783]="Kua'fon",[2784]="R'gal der Alte",[2785]="Kua'fon",[2786]="Kua'fon",[2787]="Janis Schatz",[2788]="Urne von Agussu",[2789]="Janis Schatz",[2790]="Janis Schatz",[2791]="Schatztruhe",[2792]="Schatztruhe",[2793]="Schatztruhe",[2794]="Schatztruhe",[2795]="Nez'ara",[2796]="Aiji der Verfluchte",[2797]="Kommodore Kalhaun",[2812]="Schatztruhe",[2813]="Schatztruhe",[2814]="Schatztruhe",[2815]="Schatztruhe",[2816]="Schatztruhe",[2817]="Schatztruhe",[2818]="Schatztruhe",[2819]="Schatztruhe",[2820]="Schatztruhe",[2821]="Schatztruhe",[2822]="Schatztruhe",[2823]="Schatztruhe",[2824]="Schatztruhe",[2825]="Schatztruhe",[2826]="Severus der Ausgestoßene",[2827]="Riesiger Papierdrachen",[2828]="Versteckte Truhe eines Gelehrten",[2829]="Versunkene Schließkassette",[2831]="Käpt'n Bleifaust",[2833]="Die Haibraut",[2834]="Klage des Verbannten",[2836]="Kleine Schatztruhe",[2837]="Rankensprecherin Ratha",[2838]="Merkwürdiger Pilzring",[2839]="Fluggenieur Krazzel",[2884]="Der Pilzkönig",[2885]="Ak'tar",[2886]="Sängerin Najeen",[2887]="Giftzahnrufer Xorreth",[2888]="Verstärkung aus Eisenschmiede",[2889]="Stef \"\"Bis aufs Mark\"\" Quin",[2890]="Dschungelnetzjäger",[2891]="Sirokar",[2892]="Skorpox",[2893]="Wütender Krolusk",[2894]="Knochenpicker der Blutflügel",[2895]="Tehd & Marius",[2897]="Dunkler Chronist",[2898]="Grayals letzte Opfergabe",[2899]="Reliktjäger Hazaak",[2900]="Beute des verschollenen Entdeckers",[2901]="Allianzattentäter",[2902]="Sandwütervorrat",[2903]="Gestrandeter Schatz",[2904]="Gier des Ausgräbers",[2905]="Zem'lans vergrabener Schatz",[2928]="Kua'fon",[2929]="Kua'fon",[2933]="Portal",[2934]="Kleine Schatztruhe",[2935]="Tiefzahn",[2937]="Ankermaul",[2938]="Späherkarte",[2939]="Brutmutter",[2940]="Champion",[2941]="Muradin Bronzebart",[2942]="Händler in Gefahr",[2943]="Hochexarch Turalyon",[2944]="Danath Trollbann",[2945]="Truhe der Geheimnisse",[2946]="Angriffswelle der Allianz",[2947]="Schatztruhe",[2948]="Gruppe R: Schatztruhe",[2949]="Gruppe S: Schatztruhe",[2950]="Allianz",[2951]="Angriffswelle der Allianz",[2952]="Mächtiger Gegner",[2953]="Arvon der Verratene",[2954]="König Zwickizwack",[2955]="Angreifer der Bleichborken",[2956]="Angreifer der Felsfäuste",[2957]="Verwitterte Schatztruhe",[2958]="Verstärkung aus Eisenschmiede",[2959]="Verstärkung aus Arathor",[2960]="Bogenlicht",[2961]="Schneesturz",[2962]="Champion von Neuhof",[2963]="Champion des Zirkels der Elemente",[2964]="Gestohlene Truhe",[2965]="Hordeattentäter",[2966]="Questboss",[2967]="Kiste mit Kriegsvorräten",[2968]="Reichtümer von Tor'nowa",[2969]="Schatztruhe",[2970]="Azeriterz",[2971]="Angriffswelle der Allianz",[2972]="Durchgebrannter Golem",[2974]="Vollgefressener Eber",[2975]="Angriffswelle der Horde",[2976]="Angriffswelle der Horde",[2977]="Angriffswelle der Horde",[2978]="Schwester Martha",[2979]="Fungustrio",[2980]="Seebrecher Skoloth",[2981]="Nestmutter Acada",[2982]="Squirgel aus der Tiefe",[2983]="Schwarzstich",[2984]="Carla Schmunzel",[2985]="P4-N73R4",[2986]="Gulliver",[2987]="Krötenkiefer",[2988]="Kleine Schatztruhe",[2989]="Ranja",[2990]="Sythian der Flinke",[2991]="Kleine Schatztruhe",[2992]="Schauderschuppe der Giftige",[2993]="Sägezahn",[2994]="Kleine Schatztruhe",[2995]="Tentulos der Schwebende",[2996]="Maison der Tragbare",[2997]="Kleine Schatztruhe",[2998]="Kleine Schatztruhe",[2999]="Nad el Kissen",[3000]="Kleine Schatztruhe",[3001]="Kleine Schatztruhe",[3002]="Kleine Schatztruhe",[3003]="Kleine Schatztruhe",[3004]="Kleine Schatztruhe",[3005]="Kleine Schatztruhe",[3006]="Kleine Schatztruhe",[3007]="Kleine Schatztruhe",[3008]="Kleine Schatztruhe",[3009]="Aufgewühltes Öl",[3010]="Molluskelprotz",[3011]="Hordeschiff",[3012]="Allianzschiff",[3013]="Braedan Weißwall",[3014]="Whitney \"\"Stahlklaue\"\" Ramsay",[3015]="Kleine Schatztruhe",[3016]="Kleine Schatztruhe",[3017]="Kleine Schatztruhe",[3018]="Kleine Schatztruhe",[3019]="Kleine Schatztruhe",[3020]="Kleine Schatztruhe",[3021]="Kleine Schatztruhe",[3022]="Kleine Schatztruhe",[3023]="Kleine Schatztruhe",[3024]="Kleine Schatztruhe",[3025]="Kleine Schatztruhe",[3026]="Kleine Schatztruhe",[3027]="Ruinierte Hochzeitstorte",[3028]="Säbeltron",[3029]="Schlickpest",[3030]="Truhe der Großfuhre",[3031]="Entdecktes Azerit",[3032]="Entdecktes Azerit",[3033]="Auge von Sethraliss",[3034]="Steingolem",[3035]="Matrone Morana",[3036]="Verseuchte Monstrosität",[3037]="Seelengoliath",[3038]="Späherkarte",[3039]="Seeglas",[3040]="Schädlingsbekämpfer MK. II",[3041]="Verderbte Schule",[3042]="Taja der Gezeitenheuler",[3043]="Sandzahn",[3044]="Altar der Könige",[3045]="Schmiede",[3046]="Kaserne",[3047]="Werkstatt",[3048]="Moderschlund",[3049]="Ruheloser Schrecken",[3050]="Champion des Zirkels der Elemente",[3051]="Champion von Neuhof",[3052]="Peitschenstengel",[3053]="Quako",[3054]="Treter",[3055]="Dok Maartens",[3056]="Jakala die Grausame",[3057]="Eissichel",[3058]="Zorngroll der Mümmlermalmer",[3059]="Sturmbö",[3060]="Zurückgelassene Vesperdose",[3061]="Geschnitzte Holztruhe",[3062]="Schwester Absinthia",[3063]="Herrin der Gesänge Dadalea",[3064]="Wirbelschwinge",[3065]="Haegol der Hammer",[3066]="Käpt'n Mu'kala",[3067]="Oska der Blutige",[3068]="Verstärkter Kielbrecher",[3069]="Wilderer Jannes",[3070]="UNUSED",[3164]="Lehrling Karyn",[3167]="Vergrabene Schatzkiste",[3169]="Vergrabene Schatzkiste",[3170]="Vergrabene Schatzkiste",[3171]="Vergrabene Schatzkiste",[3172]="Schlammschnauze von Mildenhall",[3173]="Heikle Schatztruhe",[3174]="Vergessene Schatztruhe",[3175]="Vorrat der Knochenritzer",[3176]="Sandmalmer",[3177]="Vorratstruhe der Venture Co.",[3178]="Vergessene Truhe",[3179]="Kleine Schatztruhe",[3180]="Verlorene Opfergaben von Kimbul",[3181]="Totholztruhe",[3182]="Im Sand versunkener Schatz",[3183]="Donnernder Goliath",[3184]="Überschäumender Goliath",[3185]="Seuchenfeder",[3186]="Zornschnabel",[3187]="Schädelreißer",[3188]="Venomarus",[3189]="Yogursa",[3190]="Zweigfürst Aldrus",[3191]="Aufseher Krix",[3192]="Yogursa",[3193]="Zornschnabel",[3194]="Brennender Goliath",[3195]="Überschäumender Goliath",[3196]="Fozruk",[3197]="Seuchenfeder",[3198]="Grollender Goliath",[3199]="Schädelreißer",[3200]="Donnernder Goliath",[3201]="Venomarus",[3202]="Molok der Zermalmer",[3203]="Kor'gresh Frostzorn",[3204]="Echo von Myzrael",[3205]="Geomant Flintdolch",[3206]="Kriegstrike",[3207]="Bestienreiter Kama",[3208]="Darbel Montrose",[3209]="Verdammnisreiter Helgrim",[3210]="Faulbauch",[3211]="Schreckliche Erscheinung",[3212]="Kürassier Aldrin",[3213]="Kovork",[3214]="Menschenjäger Rog",[3215]="Nimar der Töter",[3216]="Ruul Zweistein",[3217]="Sängerin",[3218]="Zalas Bleichborke",[3219]="Geisel",[3220]="Gestohlene Beute",[3221]="Sammler Kojo",[3222]="Toki",[3223]="Lady Liadrin",[3224]="Rokhan",[3225]="Etrigg",[3226]="Gespinstbedeckte Schatztruhe",[3227]="Schatztruhe des Kaufmanns",[3228]="Grayson Bell",[3229]="Runengebundene Truhe",[3230]="Runengebundene Kiste",[3231]="Runengebundene Lade",[3232]="Holzhaufen",[3233]="Hochburg",[3234]="Festung",[3235]="Arsenal",[3236]="Rathaus",[3237]="Burg",[3238]="Schloss",[3239]="Zwiestrump",[3240]="Frankie Zuckauge",[3241]="Gimzy Tröpfelstad",[3242]="Twitti Leuchtritzel",[3243]="Zinno",[3244]="Royston P. Crutchley III.",[3245]="Löffler der Tunichtgut",[3246]="Aerin Himmelshammer",[3247]="Brunold",[3248]="Langkralle",[3249]="Yuke",[3250]="Der alte Li",[3251]="Gregg",[3252]="Vizio der Kartograf",[3253]="Gurgel",[3254]="Flackerkerz",[3255]="Wassersprecher Deshi",[3256]="Sylvester",[3257]="Schmuddelbart",[3258]="Arwan Bestienherz",[3259]="Manape",[3260]="Taz'anga",[3261]="Nizhoni",[3262]="Kaserne",[3263]="Arsenal",[3264]="Altar der Stürme",[3265]="Werkstatt",[3266]="Altar der Könige",[3267]="Arsenal",[3268]="Kaserne",[3269]="Rathaus",[3270]="Werkstatt",[3271]="Himmelskönigin",[3272]="Schriftrollengelehrte Nola",[3273]="Zeritarj",[3274]="Sammler Kojo",[3275]="Sammler Kojo",[3276]="Sammler Kojo",[3277]="Sammler Kojo",[3278]="Sammler Kojo",[3279]="Toki",[3280]="Toki",[3281]="Toki",[3282]="Schriftrollengelehrte Nola",[3283]="Schriftrollengelehrte Nola",[3284]="Schriftrollengelehrte Nola",[3285]="Schriftrollengelehrte Nola",[3286]="Schriftrollengelehrte Nola",[3287]="Vergessene Schatztruhe",[3288]="Vorrat der Knochenritzer",[3289]="Kaserne",[3290]="Kaserne",[3291]="Altar der Stürme",[3292]="Arsenal",[3293]="Werkstatt",[3294]="Hochburg",[3295]="Festung",[3296]="Arsenal",[3297]="Altar der Könige",[3298]="Werkstatt",[3299]="Schloss",[3300]="Burg",[3301]="Haupthaus",[3302]="Seltsamer Getreidesack",[3303]="Säbeltron",[3304]="Quellenwächter",[3305]="Seltsamer Getreidesack",[3307]="Nestmutter Acada",[3308]="Altar der Alten",[3309]="Altar der Alten",[3310]="Altar der Alten",[3311]="Jägerhalle",[3312]="Jägerhalle",[3313]="Jägerhalle",[3314]="Urtum des Krieges",[3315]="Urtum des Krieges",[3316]="Urtum des Krieges",[3317]="Baum des Lebens",[3319]="Baum des Alters",[3320]="Baum des Alters",[3321]="Baum der Ewigkeit",[3322]="Baum der Ewigkeit",[3323]="Werkstatt",[3324]="Werkstatt",[3325]="Werkstatt",[3326]="Schuppenscheusal",[3327]="Wahnfeder",[3328]="Schattenklaue",[3329]="Schimmerpanzer",[3330]="Grimmhorn",[3331]="Schwarzpranke",[3332]="<Hippogryphenmeister>",[3333]="Seuchenkatapult der Verlassenen",[3334]="Glevenschleuder",[3335]="Baum des Lebens",[3336]="Holzhaufen",[3337]="Eisenlore",[3338]="Erzkiste",[3339]="Angriffswelle der Naga",[3340]="Haupthaus",[3341]="Durchnässte Truhe",[3342]="Maiev Schattensang",[3343]="Sira Mondhüter",[3346]="Wächterinnengleve",[3350]="Gnollschlemmer",[3351]="Hydrath",[3352]="Cyclarus",[3353]="Conflagros",[3354]="Granokk",[3355]="Steinbinderin Ssra'vess",[3356]="Azeritextraktor der Horde",[3357]="Azeritextraktor der Allianz",[3358]="Zerstörter Azeritextraktor",[3359]="Einsatzbereiter Azeritextraktor",[3360]="Thelar Mondstreich",[3361]="Klopfer der Shed-Ling",[3362]="Klopfer der Shed-Ling",[3363]="Zim'kaga",[3364]="Moxo der Köpfer",[3365]="Athrikus Narassin",[3366]="Azeritbruch",[3367]="Glrglrr",[3368]="Trümmerstück",[3369]="Onu",[3372]="Kommandant Drald",[3373]="Soggoth der Glitschige",[3374]="Aschenwindschätze",[3375]="Zwielichtprophet Graeme",[3376]="Aman",[3377]="Mrggr'marr",[3378]="Kommandant Ral'esh",[3379]="Gren Fetzfell",[3380]="Athil Tauglanz",[3381]="Pionierin Odette",[3382]="Croz Blutzorn",[3383]="Orwell Stevenson",[3384]="Lorna Crowley",[3385]="Agathe Wyrmholz",[3386]="Holz",[3387]="Eisen",[3388]="Beute des Spinnenbots",[3389]="Beute des Gorillabots",[3390]="Maiev",[3391]="Sira",[3392]="Alash'anir",[3393]="Altar der Stürme",[3394]="Altar der Stürme",[3395]="Altar der Stürme",[3396]="Arsenal",[3397]="Arsenal",[3398]="Arsenal",[3399]="Kaserne",[3400]="Kaserne",[3401]="Kaserne",[3402]="Haupthaus",[3403]="Hochburg",[3404]="Hochburg",[3405]="Festung",[3406]="Festung",[3407]="Seuchenwerk",[3408]="Seuchenwerk",[3409]="Seuchenwerk",[3410]="Botschafter Gaines",[3411]="Katrianna",[3412]="Artilleriemeister Siegesfroh",[3413]="Kapitänin Grünsegel",[3414]="Hartford Strengbach",[3415]="Nebelwirkerin Nian",[3416]="Jörn Starkarm",[3417]="Zagg Blindauge",[3418]="Togoth Grobfaust",[3419]="Belagerungsingenieur Krachbumm",[3420]="Grubb",[3421]="Brugg",[3422]="Rottenmeisterin Stahlzahn",[3423]="Erster Maat Malle",[3424]="Motega Blutschild",[3425]="Zunjo von Sen'jin",[3426]="Alsian Vistreth",[3427]="Geheime Vorratstruhe",[3428]="Geheime Vorratstruhe",[3429]="Geheime Vorratstruhe",[3430]="Geheime Vorratstruhe",[3431]="Geheime Vorratstruhe",[3432]="Geheime Vorratstruhe",[3433]="Leerenmeister Schattenfall",[3434]="Gezeitenweise Clarissa",[3435]="Alkalinius",[3436]="Owynn Graddock",[3437]="Nalaess Federsucher",[3438]="Kürassier Josiph",[3439]="Bestienzähmer Watteck",[3440]="Schattenjägerin Mutumba",[3441]="Mörsermeister Zappfritz",[3442]="Gurin Steinbinder",[3443]="Dolizit",[3444]="Feuerwächter Viton Nachtfackel",[3445]="Dinomant Zakuru",[3446]="Käpt'n Gorok",[3447]="Zillie Wunderzange",[3448]="Magistrix Kristalynn",[3449]="Maddok der Scharfschütze",[3450]="Inquisitor Erik",[3451]="Doktor Lazane",[3452]="Karawanenkommandantin Veronica",[3453]="Zul'aki der Kopfjäger",[3454]="Rudelmeister Flinkpfeil",[3455]="Omgar Unheilsbogen",[3456]="Ingenieur Bolzenhalt",[3457]="Herzogin Todessang von Frost",[3458]="Muk'luk",[3459]="Apotheker Jerrod",[3460]="Portalhüter Romiir",[3461]="Jessibelle Mondschild",[3462]="Uralter Verteidiger",[3463]="Eric Leisefaust",[3464]="Dinojäger Wildbart",[3465]="Blinky Funkendings",[3466]="Karawanenmeister",[3467]="Gezeitenbinder Maka",[3468]="Belagerungsbrecher Vol'gar",[3469]="Späherhauptmann Quengelknopf",[3470]="Dinomant Dajingo",[3471]="Todeshauptmann Detheca",[3472]="Todeshauptmann Danielle",[3473]="Todeshauptmann Delilah",[3474]="Wolfsanführer Skraug",[3475]="Belager-o-matik 9000",[3476]="Jin'tago",[3477]="Abrichterin Drakara",[3478]="Sandbinder Sodir",[3479]="Drox'ar Morgar",[3480]="Evezon der Ewige",[3481]="Karawanenmeister",[3482]="Felsfuror",[3483]="Eisenschamane Grimmbart",[3484]="Großmarschall Furon",[3485]="Schattenjäger Vol'tris",[3486]="Karawanenmeister",[3487]="Überwuchertes Urtum",[3488]="Seuchenmeister Herbert",[3489]="Arkanist Quintril",[3490]="Braumeister Lin",[3491]="Ptin'go",[3492]="Sturmruferin Morka",[3493]="Lichtgeschmiedete Kriegspanzerung",[3494]="Himmelskapitän Thermofunk",[3495]="Thomas Vandergrief",[3496]="Belagertron",[3497]="Glevenwerk",[3498]="Glevenwerk",[3499]="Glevenwerk",[3501]="Maiev Schattensang",[3502]="Verlorenes Zandalarirelikt",[3503]="Abfackler Modell V",[3504]="N'chala der Eierdieb",[3505]="Xizz Dolchschlitz",[3506]="Gallenstampfer",[3507]="Reifer Kürbis",[3508]="Reife Rübe",[3509]="Reifer Speisekürbis",[3510]="Reife Karotte",[3511]="Yakfleisch",[3512]="Erzkiste",[3513]="Ormin Raketenklaps",[3514]="Dunkelküstenschatz",[3515]="Dunkelküstenschatz",[3516]="Dunkelküstenschatz",[3517]="Dunkelküstenschatz",[3518]="Dunkelküstenschatz",[3519]="Agathe Wyrmholz",[3520]="Schimmerpanzer",[3521]="Croz Blutzorn",[3522]="Wahnfeder",[3523]="Orwell Stevenson",[3524]="Schwarzpranke",[3525]="Grimmhorn",[3526]="Schattenklaue",[3527]="Schuppenscheusal",[3528]="Adhara Weiß",[3529]="Dunkelküstenschatz",[3530]="Dunkelküstenschatz",[3531]="Dunkelküstenschatz",[3532]="Dunkelküstenschatz",[3533]="Dunkelküstenschatz",[3534]="Azeritbruch",[3537]="Geläuterte Truhe",[3538]="Verstandswiederherstellung",[3540]="Geheime Vorratstruhe",[3541]="Geheime Vorratstruhe",[3542]="Geheime Vorratstruhe",[3543]="Geheime Vorratstruhe",[3544]="Geheime Vorratstruhe",[3545]="Geheime Vorratstruhe",[3546]="Mechagonischer Nullifizierer",[3547]="Vergrabener Schatz",[3549]="Gratis T-Shirts!",[3550]="Der Schrottkönig",[3551]="Der Schrottkönig",[3552]="Mecharantel",[3553]="Kieferbrecher",[3554]="Paol Teichwandler",[3555]="Rumpelfels",[3556]="Sonnenprophet Epaphos",[3557]="Leuchtfeuer des Sonnenkönigs",[3559]="Beobachter Rehu",[3560]="Lichte Leuchten",[3561]="Anaua",[3562]="Sonnenpriesterin Nubitt",[3563]="Schleimiger Kokon",[3564]="Schleimiger Kokon",[3565]="Schleimiger Kokon",[3566]="Schleimiger Kokon",[3567]="Das Wanderfest",[3568]="Senbu der Rudelvater",[3569]="Hik-ten der Zuchtmeister",[3570]="Arachnoider Ernter",[3571]="Tiefseeschlund",[3572]="Fungianischer Furor",[3573]="Üble Manifestation",[3574]="Todessäge",[3575]="Raketenhühnchenrandale",[3576]="Leerenwurzeln",[3577]="Spähmeister Moswen",[3578]="Menepthah der Kriegshetzer",[3579]="Ausbildungsgelände der Lichtklingen",[3580]="Ritual des Aufstiegs",[3581]="Knochenpicker",[3582]="Onkel T'Rogg",[3583]="Boggac Schädelrums",[3584]="Defekter Gorillabot",[3585]="Seespuck",[3586]="Tresorbot",[3587]="Mechanisierte Truhe",[3588]="Mechanisierte Truhe",[3589]="Mechanisierte Truhe",[3590]="Mechanisierte Truhe",[3591]="Mechanisierte Truhe",[3592]="Mechanisierte Truhe",[3593]="Mechanisierte Truhe",[3594]="Mechanisierte Truhe",[3595]="Mechanisierte Truhe",[3596]="Mechanisierte Truhe",[3597]="Avarius",[3598]="Fleischfressender Peitscher",[3599]="Vol'koth",[3600]="Leuchtfeuer des Sonnenkönigs",[3601]="Schriftrollengelehrte Nola",[3602]="Schriftrollengelehrte Nola",[3603]="Schriftrollengelehrte Nola",[3604]="Schriftrollengelehrte Nola",[3605]="Schriftrollengelehrte Nola",[3606]="Schriftrollengelehrte Nola",[3607]="Leuchtfeuer des Sonnenkönigs",[3608]="Leuchtfeuer des Sonnenkönigs",[3609]="Kaneb-ti",[3610]="Schrein der Stürme",[3611]="Schrein der Abendflut",[3612]="Schrein der Dämmerung",[3613]="Schrein der Natur",[3614]="Schrein der Sande",[3615]="Schrein der See",[3616]="Das entsiegelte Grab",[3617]="Vision von Sturmwind",[3618]="Zeitriss",[3619]="König Gakula",[3620]="Raubflotte der Amathet",[3621]="Tatt der Knochenkauer",[3622]="Nebet der Aufgestiegene",[3623]="Atekhramun",[3624]="Uat-ka der Sonnenzorn",[3625]="Funkenkönigin P'Emp",[3626]="Wahnsinniger Trogg",[3627]="Rostfeder",[3628]="Getriebeprüfer Radstern",[3629]="Alter Großhauer",[3630]="Stahlsängerin Freza",[3631]="Splitterzid",[3632]="Oxidierte Egelbestie",[3633]="Siedebrand",[3634]="Erdbrecher Gulroc",[3635]="Der Kleptoboss",[3636]="Herr Richter",[3637]="Säule der ertrunkenen Seelen",[3638]="Riesiger gehärteter Klingenpanzer",[3639]="Urzeitlicher Zitterstachelzermalmer",[3640]="Schreckensalpha der Schnappdrachen",[3641]="Riesiger Tiefennatterglitschkönig",[3642]="Gewaltige Höhlenschimmerschale",[3643]="Grabengleiterältester",[3644]="Invasiver Riffwanderer",[3645]="Monströser Großaal",[3647]="Ogeraufseher",[3648]="Heimir von der Schwarzen Faust",[3649]="Rythas das Orakel",[3650]="Oktel Drachenblut",[3651]="Grufthauchschrecken",[3652]="Leerenleitung",[3653]="Abyssisches Ritual",[3654]="Rachsüchtige Erde",[3655]="Zror'um der Unendliche",[3656]="Wertvoller Ogerschatz",[3657]="Geléeablagerung",[3658]="Das Gebräu beschützen",[3661]="Ludin der Abrichter",[3662]="Kwall",[3663]="Muradin",[3664]="Turalyon",[3665]="Danath Trollbann",[3666]="Etrigg",[3667]="Rokhan",[3668]="Lady Liadrin",[3669]="Grula die Bestienmutter",[3670]="Quell der Verderbnis",[3674]="Gezeitenherrin Leth'sindra",[3675]="Gezeitenlord Aquatus",[3676]="Gezeitenlord Dispersius",[3677]="Sslithara",[3678]="Gebundener Wächter",[3684]="Leerenleitung",[3685]="Leerenleitung",[3686]="Gebundener Wächter",[3687]="Der rostige Prinz",[3688]="Leerenhüter Malketh",[3689]="Kiste mit Kriegsvorräten",[3690]="Vollstrecker KX-T57",[3691]="Veskan der Gefallene",[3692]="Bruder Meller",[3693]="Häuptling Mek-mek",[3694]="Primalistin Thurloga",[3695]="Erzdruidin Renferal",[3696]="Anenga",[3697]="Atomik",[3698]="Rijz'x der Verschlinger",[3699]="Amethystspindelschnecke",[3700]="Blindlicht",[3701]="Schluchtschatten",[3702]="Dolchzahnschrecken",[3703]="Wille von N'Zoth",[3704]="Tiefengleiter",[3705]="Granatschuppe",[3706]="Schlammkriecher",[3707]="Nadelstachel",[3708]="Sandburg",[3709]="Sandscherensteinpanzer",[3710]="Toxigore der Alpha",[3711]="Alga der Augenlose",[3712]="Allseher Oma'kil",[3713]="Anemonar",[3714]="Fluchschuppe der Rudelvater",[3715]="Höhlendunkelschrecken",[3716]="Ältester Unu",[3717]="Brutälteste Nalaada",[3718]="Schillernde Schimmerschale",[3719]="Tangwurz",[3720]="Oronu",[3721]="Prinz Typhonus",[3722]="Prinz Vortran",[3723]="Felskrautschlurfer",[3724]="Schuppenma­t­ri­ar­chin Gratinax",[3725]="Schuppenma­t­ri­ar­chin Vynara",[3726]="Schuppenma­t­ri­ar­chin Zodia",[3727]="Shassera",[3728]="Shiz'narasz der Verschlinger",[3729]="Schlickpirsch die Rudelmutter",[3730]="Lautlos",[3731]="Urduu",[3732]="Stimme in den Tiefen",[3733]="Tiefenfürst Zrihj",[3734]="Teng der Erweckte",[3735]="Vollgefressener Ritzelknabberer",[3736]="Ätzender Mechaschleim",[3737]="Große Geléeablagerung",[3738]="Starrender Beobachter",[3739]="Brodelnder uralter Schrecken",[3740]="Eitriger uralter Schrecken",[3741]="Vog'reth der Unersättliche",[3742]="Verderbter Schatz",[3743]="Honigrückenernterin",[3744]="Üppiges Blumenbeet",[3745]="Die alte Nasha",[3746]="Honigrückenusurpatorin",[3747]="Gurg der Schwarmdieb",[3748]="Falltürbienenjäger",[3749]="Die Schwarmtöterin",[3750]="Yorag der Geléeschlemmer",[3751]="Obskuron",[3752]="Schätze der Stacheleber",[3753]="Gestohlener Schatz",[3756]="Schrottklaue",[3757]="Gerufen aus den Tiefen",[3758]="Gefangener Gräber",[3759]="Kommandantin Minzera",[3760]="Theurgin Nitara",[3761]="Kriegsfürst Zalzjar",[3762]="Schattenbinderin Athissa",[3763]="Inkantatrix Vazina",[3764]="Dominus",[3765]="Sanguifang",[3767]="Verstärkter Kriegswagen",[3768]="Mantisbrutstätte",[3769]="Die Front am Vir'naal",[3771]="Große Schatztruhe",[3772]="Truhe des Schwarzen Imperiums",[3773]="Truhe des Schwarzen Imperiums",[3774]="Maschine des Aufstiegs",[3775]="Ausgegrabener Hüter",[3776]="Ausgegrabener Hüter",[3777]="Ausgegrabener Hüter",[3778]="Ausgegrabener Hüter",[3779]="Wiederbelebungsstrahl",[3780]="Thrall",[3781]="Schatz der Weisheit",[3782]="Schatz der Demut",[3783]="Schatz des Mutes",[3784]="Schatz der Reinheit",[3785]="Sonnensammler",[3786]="Sonnensammler",[3787]="Pontifex Tratus",[3788]="Lehrmeister Brutus",[3789]="Dunkler Champion",[3790]="Rektorin Kalliope",[3791]="Sklavenlager der Amathet",[3792]="Reißzahnsammler Orsa",[3793]="Ishak von den Vier Winden",[3794]="Fäulnisverschlinger",[3795]="Ha-Li",[3796]="Muminah der Strahlende",[3797]="Hundmeister Ren",[3798]="Rei Lun",[3799]="Glocke der Demut",[3800]="Glocke des Mutes",[3801]="Glocke der Weisheit",[3802]="Glocke der Reinheit",[3803]="Zelot Tekem",[3804]="Champion Sen-mat",[3805]="Heixi der Steinfürst",[3806]="Akolyth Taspu",[3807]="Die Vergessenen",[3808]="Geronnene Anima",[3809]="Gruftwitwe",[3810]="Kilxl das Klaffende Maul",[3811]="Entflohene Mutation",[3812]="Sturmgeheul",[3813]="Auslöscher der Dokani",[3814]="Jadebeobachter",[3815]="Meisterspion Hul'ach",[3816]="Animasammler",[3817]="Xiln der Berg",[3819]="Anh-De der Loyale",[3820]="Tisiphon",[3821]="Mechanoidenwagen",[3822]="Horrende Heilung",[3823]="Verheererbau",[3824]="Chins Nudelwagen",[3825]="Schwarmrufer",[3826]="Datenanomalie",[3827]="Datenanomalie",[3828]="Datenanomalie",[3829]="Datenanomalie",[3830]="Borr-Geth",[3831]="Jagdgründe der Vil'thik",[3832]="Adjutant Dekaris",[3833]="Ritual des Erwachens",[3834]="Kriegsbanner der Vil'thik",[3835]="Eternas der Peiniger",[3836]="Dunkellord Taraxis",[3837]="Schwarmrufer",[3838]="Schwarmrufer",[3839]="Verstärkter Kriegswagen",[3840]="Kunchonginkubator",[3843]="Schwarmrufer",[3844]="Soul Well",[3845]="Mantisbrutstätte",[3846]="Blazing Pyrestone",[3847]="Neugeborener Verschlinger",[3848]="Treibender Kummer",[3849]="Seelenanker",[3850]="Seelenanker",[3851]="Kiste des Schwarzen Imperiums",[3852]="Schwarze Kiste",[3853]="Schwarze Kiste",[3854]="Schwarze Kiste",[3855]="Schwarze Kiste",[3856]="Truhe des Schwarzen Imperiums",[3857]="Truhe des Schwarzen Imperiums",[3858]="Truhe des Schwarzen Imperiums",[3859]="Truhe des Schwarzen Imperiums",[3860]="Truhe des Schwarzen Imperiums",[3861]="Truhe des Schwarzen Imperiums",[3862]="Üppiges Blumenbeet",[3863]="Verlies der Seelen",[3864]="Beschwertes Moguartefakt",[3865]="Konstruktionsritual",[3866]="Barukvernichter",[3867]="Schlangenkäfig der Zan-Tien",[3868]="Elektrische Ermächtigung",[3869]="Goldastwächter",[3870]="Arena der Sturmerwählten",[3871]="Blutgebundenes Abbild",[3872]="Falkner Amenophis",[3873]="Mysteriöser Sarkophag",[3874]="Schlangenbindung",[3875]="Oberster Wächter Reshef",[3876]="Verderbte Wache der Neferset",[3877]="Verderbter Verstandräuber",[3878]="Fleischverschmelzung",[3879]="Actiss der Betrüger",[3881]="Weltuntergangsverkünder Vathiris",[3882]="Gedankenräuber Vos",[3883]="Hochexekutor Yothrim",[3884]="Verderbtes Protoplasma",[3885]="Blick von N'Zoth",[3886]="R'khuzj der Unergründliche",[3887]="Yiphrim der Willensräuber",[3888]="Aphrom das Antlitz des Wahnsinns",[3889]="R'aas der Animaverschlinger",[3890]="Zoth'rum der Intellektplünderer",[3891]="Shugshul der Fleischschlinger",[3892]="R'oyolok der Realitätenverschlinger",[3893]="Der Großexekutor",[3894]="Shol'thoss der Untergangsverkünder",[3895]="Herkulon",[3896]="Truhe des Aspiranten",[3897]="Geronnene Verderbnis",[3898]="Leerenriss",[3899]="Beschwörungsportal",[3900]="Beschwörungsportal",[3901]="Beschwörungsportal",[3902]="Exekutor von N'Zoth",[3903]="Exekutor von N'Zoth",[3904]="Exekutor von N'Zoth",[3905]="Exekutor von N'Zoth",[3906]="Exekutor von N'Zoth",[3907]="Ruf der Leere",[3908]="Ruf der Leere",[3909]="Ruf der Leere",[3910]="Scheiterhaufen des Amalgamierten",[3911]="Geisttrinker",[3912]="Geisttrinker",[3913]="Geisttrinker",[3914]="Geisttrinker",[3915]="Geisttrinker",[3916]="Geisttrinker",[3917]="Geisttrinker",[3918]="Schwarzwächter Rhothkozz",[3919]="Mogubeute",[3920]="Mogubeute",[3921]="Mogubeute",[3922]="Mogubeute",[3923]="Mogubeute",[3924]="Mogubeute",[3925]="Schließkassette der Mogu",[3926]="Truhe der Amathet",[3927]="Truhe der Amathet",[3928]="Truhe der Amathet",[3929]="Truhe der Amathet",[3930]="Truhe der Amathet",[3931]="Truhe der Amathet",[3932]="Reliquiar der Amathet",[3933]="PH Rare - Needs Data",[3934]="Verderbter Knochenhäuter",[3935]="Vision von N'Zoth",[3936]="Honighauer",[3937]="Solarsphäre",[3938]="Schwester Chelicera",[3939]="Wespagantua",[3940]="Sammler Kash",[3941]="Gräss",[3943]="Manipulator Yggshoth",[3944]="Manipulator Shrog'lth",[3945]="Schattenwandler Yash'gth",[3946]="Dunkelsprecher Thul'grsh",[3947]="Dunkelsprecher Shath'gul",[3948]="Craggle Schlingerkreisel",[3949]="Zuchtmeister Xox",[3950]="Seelenpirscherin Doina",[3951]="Befallene Truhe",[3952]="Befallene Truhe",[3953]="Befallene Truhe",[3954]="Befallene Truhe",[3955]="Befallene Truhe",[3956]="Befallene Truhe",[3957]="Befallene Kiste",[3958]="Befallene Kiste",[3959]="Befallene Kiste",[3960]="Befallene Kiste",[3961]="Befallene Schließkassette",[3962]="Shoth der Verdunkelte",[3963]="Hungerndes Miasma",[3964]="Innervus",[3965]="Schreiberin Lenua",[3966]="Verschlingendes Maul",[3967]="Gefallene Akolythin Erisne",[3968]="Bernbesetzte Truhe",[3969]="Bernbesetzte Truhe",[3970]="Bernbesetzte Truhe",[3971]="Bernbesetzte Truhe",[3972]="Bernbesetzte Truhe",[3973]="Truhe des Schwarzen Imperiums",[3974]="Truhe des Schwarzen Imperiums",[3975]="Truhe des Schwarzen Imperiums",[3976]="Truhe des Schwarzen Imperiums",[3977]="Verschlingendes Maul",[3978]="Verschlingendes Maul",[3979]="Verschlingendes Maul",[3980]="Weltenrandfresser",[3981]="Blubbernder Blubberball",[3982]="Schleimige Schleimsphäre",[3983]="Graf Ladinas",[3984]="Nikara Schwarzherz",[3985]="Ritual der Leerenflamme",[3986]="Monströse Beschwörung",[3987]="Mar'at in Flammen",[3988]="Jadekoloss",[3989]="Herold Il'koxik",[3990]="Bernformer Esh'ri",[3991]="Stockwache Naz'ruzek",[3992]="Kzit'kovok",[3993]="Hetzer Nir'verash",[3994]="Zerstörer Krox'tazar",[3995]="Drohnenhüter Ak'thet",[3996]="Wütender Bernelementar",[3997]="Buh'gzaki der Blasphemiker",[3998]="Hauptmann Vor'lek",[3999]="Schlitzer",[4000]="Kal'tik der Veröder",[4001]="Nadler Zhesalla",[4002]="Durchströmter Bernschlamm",[4003]="Schriftrolle der Äonen",[4004]="Nikara die Wiedergeborene",[4005]="Sophias Gabe",[4006]="Sophias Glanz",[4007]="Vesperreparatur: Sophias Arie",[4008]="Unbezwingbarer Schmidt",[4009]="Schattenschlund",[4010]="Korzaran der Schlächter",[4011]="Nebelhauch in Flammen",[4012]="Leichenschneider Moroc",[4013]="Beschwertes Moguartefakt",[4014]="Verlies der Seelen",[4015]="Reine Arroganz",[4016]="Ermächtigter Verwüster",[4017]="Ermächtigter Verwüster",[4018]="Konstruktionsritual",[4019]="Herrenlose Schatztruhe",[4020]="Valioc",[4021]="Verderbnisriss",[4022]="Pulsierender Hügel",[4023]="Befallene Jadestatue",[4024]="Seelengefängnis",[4025]="Pyrestone",[4026]="Verschlingendes Maul",[4027]="Verschlingendes Maul",[4028]="Scharfrichterin Adrastia",[4029]="Manipulator Yar'shath",[4030]="Tiefenrufer Velshen",[4031]="Portalhüterin Jin'tashal",[4032]="Bestien der Bastion",[4033]="Debug",[4034]="Ausbilder Teshal",[4035]="Bestien der Bastion: Siegelrücken",[4036]="Bestien der Bastion: Aethon",[4037]="Bestien der Bastion: Nemaeus",[4038]="Bestien der Bastion: Wolkenschweif",[4039]="Antak'shal",[4040]="Brutale Spitze von Ny'alotha",[4041]="Verfluchte Spitze von Ny'alotha",[4042]="Entropische Spitze von Ny'alotha",[4043]="Besudelte Spitze von Ny'alotha",[4044]="Nirvaska der Beschwörer",[4045]="Lord Mortegore",[4046]="Ny'alothischer Riss",[4047]="Baedos' Fressattacke",[4048]="Grabende Schrecken",[4049]="Grabende Schrecken",[4050]="Grabende Schrecken",[4051]="Erste Glocke von Markos",[4052]="Zweite Glocke von Markos",[4053]="Dritte Glocke von Markos",[4054]="Obsidianextraktion",[4055]="Schlummernder Zerstörer",[4056]="Zwirnherrin Leeda",[4057]="Schlummernder Zerstörer",[4058]="Obsidianvernichter",[4059]="Vergessene Andenken",[4060]="Vestige of the Descended",[4061]="Katakombenschatz",[4062]="Smorgas der Schmauser",[4063]="Bernbesetzte Kiste",[4064]="Tahonta",[4065]="Sabriel die Knochenspalterin",[4066]="Schling'us",[4067]="Knorpelschnabel",[4068]="Nerissa Herzlos",[4069]="Todschickling",[4070]="Blubberblut",[4071]="Gieger",[4072]="Pestizid",[4073]="Tiefnarbe",[4074]="Allerias verderbte Truhe",[4075]="Kriegshetzer Mal'korak",[4076]="Leichenfresser",[4077]="Anq'uri der Titanische",[4078]="Schinder der Aqir",[4079]="Titanus der Aqir",[4080]="Schlachtzauberer der Aqir",[4081]="Hauptmann Dünenläufer",[4082]="Hohepriester Ytaessis",[4083]="Schlachtzauberer der Aqir",[4084]="Befallener Hauptmann der Wüstenwanderer",[4085]="Lord Aj'qirai",[4086]="Magus Rehleth",[4087]="Qho",[4088]="R'krox",[4089]="Skikx'traz",[4090]="Schlachtzauberer Xeshro",[4091]="Zuythiz",[4092]="Läuternde Flammen",[4093]="Überfallene Siedler",[4094]="Überfallene Siedler",[4095]="Verhärteter Bau",[4096]="Staubrauf",[4097]="Titanusei",[4098]="Entzündliche Kokons",[4099]="Junger Setzling",[4100]="Gormkeiler",[4104]="Buchhalter Mnemis",[4105]="Leerengeist",[4106]="Geist des dunklen Ritualisten Zakahn",[4107]="Geist Cyrus' des Schwarzen",[4108]="Fleischverschmelzung",[4109]="Sonnenkönig Nahkotep",[4110]="Armagürtlon",[4111]="Tashara",[4112]="Verschlingendes Maul",[4113]="Mysteriöser Pilzring",[4114]="Gormzähmer Tizo",[4115]="Zuckende Wurzel",[4116]="Deifir der Ungezähmte",[4117]="Alter Ardeit",[4119]="Skuld Vit",[4120]="Jägerin Vivanna",[4121]="Todesbinder Hroth",[4122]="Mystisches Regenbogenhorn",[4123]="Augentruhe",[4124]="Truhe mit Konstruktvorräten",[4125]="Preissack",[4126]="Vorräte des Klingenschwurs",[4127]="Ve'nari",[4128]="Zargox der Wiedergeborene",[4129]="Kunstvoller Knochenschild",[4130]="Seltsamer Auswuchs",[4131]="Mymaen",[4132]="Seelenschmied Yol-Mattar",[4133]="Entzogene Seele",[4134]="Endlauerer",[4135]="Lichtamalgam",[4136]="Zöllner Varaboss",[4137]="Ogerzuchtmeister",[4138]="Harika die Schreckliche",[4139]="Spektralschlüssel",[4140]="Spektralgebundene Truhe",[4141]="Runenverschlossener Tresor",[4142]="Mit Hebel verschlossene Truhe",[4143]="Seelenaschenreliquiar",[4144]="Nächster Stock",[4145]="Gallaths Glocke",[4146]="Phantoriax' Kriegsschwert",[4147]="Renavyths Medaillon",[4148]="Indris Flöte",[4149]="Die Schmiede braucht mehr Güldenit",[4150]="Amethia",[4151]="Penthia",[4152]="Varrik",[4153]="Knöpfchen",[4154]="Sumpfbestie",[4155]="Animazapfen",[4156]="Pylon",[4157]="Schmutzamalgam",[4158]="Famu der Unendliche",[4159]="Duellmeister Rowyn",[4160]="Truhe der neidischen Träume",[4161]="Diebestrophäe",[4162]="Zurückgelassene Beute eines Wanderers",[4163]="Remlates versteckter Schatz",[4164]="Azgar",[4165]="Schatztruhe",[4166]="Bündel der flüchtigen Seele",[4167]="Hoffnungsvernichter",[4168]="Kiste mit vergoldeter Pflaume",[4169]="Scharfrichter Aatron",[4170]="Jagdmeister Petrus' Freunde",[4171]="Gespinstbedeckte Schatztruhe",[4172]="Großarkanist Dimitri",[4173]="Geheimer Schatz",[4174]="Geheimer Schatz",[4175]="Geheimer Schatz",[4176]="Geheimer Schatz",[4177]="Geheimer Schatz",[4178]="Geheimer Schatz",[4179]="Geheimer Schatz",[4180]="Geheimer Schatz",[4181]="Geheimer Schatz",[4182]="Geheimer Schatz",[4183]="Fauldornboggart",[4184]="Skoldushalle",[4185]="Frakturkammern",[4186]="Die Seelenschmieden",[4187]="Mort'regar",[4188]="Die Oberen Ebenen",[4189]="Kaltherzinterstitia",[4190]="Die Gewundenen Korridore",[4191]="Unbewachte Gormeier",[4192]="Bizarres Blütenbündel",[4193]="Seltsame Wolke",[4194]="Feuer",[4195]="Nachtmähre",[4196]="Mehrzfresser",[4197]="Verlegte Vorräte",[4198]="Schwingenschinder der Grausame",[4199]="Schwarzhundtruhe",[4200]="Vesperglocke der Tugenden",[4201]="Augenlager",[4202]="Sprießender Auswuchs",[4203]="Grabsprenger",[4204]="Truhe",[4205]="Kyrianerleiche",[4206]="Truhe",[4207]="Truhe",[4208]="Truhe",[4210]="Gigantischer Sucher",[4211]="Knochengebundene Kiste",[4212]="Kahlholzkiste",[4213]="Verzauberte Truhe",[4214]="Vergoldete Truhe",[4215]="Konvokation der Trauer",[4216]="Obolos",[4217]="Verrottete Hülle",[4218]="Verrottete Hülle",[4219]="Verrottete Hülle",[4220]="Verrottete Hülle",[4221]="Verrottete Hülle",[4222]="Feenvorrat",[4223]="Feenvorrat",[4224]="Feenvorrat",[4225]="Feenvorrat",[4226]="Feenvorrat",[4227]="Manifestation des Zorns",[4228]="Halis' Henkelmann",[4229]="Verschlossener Werkzeugkasten",[4230]="Frontrationskiste",[4231]="Befreier Vlavios",[4232]="Konvokation des Verlusts",[4233]="Konvokation des Schmerzes",[4234]="Mondlichtkapsel",[4235]="Mondlichtkapsel",[4236]="Mondlichtkapsel",[4237]="Mondlichtkapsel",[4238]="Mondlichtkapsel",[4239]="Zerbrochene Glocke",[4240]="Zerbrochene Glocke",[4241]="Zerbrochene Glocke",[4242]="Himmelsglocke",[4243]="Himmelsglocke",[4244]="Wunschgrille",[4245]="Seelenschmied Rhovus",[4246]="Vesperglocke der Tugenden",[4247]="Sündenamalgam",[4248]="Sonnentänzer",[4249]="Baronin Vashj",[4250]="Polemarch Adrestes",[4251]="Choofa",[4252]="Grufthüter Kassir",[4253]="Klumplump",[4254]="Ritual der Absolution",[4255]="Ritual der Anklage",[4256]="Ein stiller Moment",[4257]="Teekränzchen",[4258]="Hochinquisitor Vetar",[4259]="Theotars Trinkspruch",[4260]="Tributtruhe",[4261]="Partyaufmerksamkeit",[4263]="Silberne Schließkassette",[4264]="Silberne Schließkassette",[4265]="Silberne Schließkassette",[4266]="Silberne Schließkassette",[4267]="Silberne Schließkassette",[4268]="Silberne Schließkassette",[4269]="Silberne Schließkassette",[4270]="Silberne Schließkassette",[4271]="Silberne Schließkassette",[4272]="Silberne Schließkassette",[4273]="Silberne Schließkassette",[4274]="Goldene Truhe des Provosten",[4275]="Himmelsglocke",[4276]="Versteckter Vorrat",[4277]="Versteckter Vorrat",[4278]="Versteckter Vorrat",[4279]="Versteckter Vorrat",[4280]="Versteckter Vorrat",[4281]="Versteckter Vorrat",[4282]="Tugend der Bußfertigkeit",[4283]="Dunkle Wächterin",[4284]="Schattenweber Zeris",[4285]="Auf Bestellung",[4286]="Prüfung der Reinheit",[4287]="Essensschlacht",[4288]="Prüfung der Demut",[4289]="Prüfung des Mutes",[4290]="Prüfung der Weisheit",[4291]="Prüfung der Loyalität",[4292]="Basilofos",[4293]="Krala",[4294]="Dolos",[4295]="Eurydos",[4296]="Thanassos",[4297]="Die Gewundenen Korridore",[4298]="Animaartefakt",[4299]="Eketra",[4300]="Akros der Brutale",[4301]="Pilzexperimente",[4302]="Senkt Eure Erwartungen",[4303]="Die Ernte",[4304]="Rückmeldung: Grufthüter Kassir",[4305]="Steingeborenensäckchen",[4306]="Rückmeldung: Steinkopf",[4307]="Steingeborenensäckchen",[4308]="Steingeborenensäckchen",[4309]="Steingeborenensäckchen",[4310]="Steingeborenensäckchen",[4311]="Steingeborenensäckchen",[4312]="Steingeborenensäckchen",[4313]="Rückmeldung: Die Gräfin",[4314]="Preis des Faustkämpfers",[4315]="Preis des Faustkämpfers",[4316]="Preis des Faustkämpfers",[4317]="Preis des Faustkämpfers",[4318]="Preis des Faustkämpfers",[4319]="Konzertbeginn",[4320]="Der Rat der Aufgestiegenen",[4321]="Rat der Aufgestiegenen",[4322]="Wolkenfederwächter",[4323]="Steingeborenensäckchen",[4324]="Steingeborenensäckchen",[4325]="Steingeborenensäckchen",[4326]="Steingeborenensäckchen",[4327]="Steingeborenensäckchen",[4328]="Steingeborenensäckchen",[4329]="Steingeborenensäckchen",[4330]="Steingeborenensäckchen",[4331]="Razkazzar",[4332]="Orrholyn",[4333]="Yol-Mattar",[4334]="Unphlaxx",[4335]="Dath Rezara",[4336]="Morguliax",[4337]="Tanz für die Liebe",[4338]="Instabile Erinnerung",[4339]="Vollstrecker Aegeon",[4340]="Fehlerhafte Klauenwache",[4341]="Demi die Relikthorterin",[4342]="Wachsender Riss",[4343]="Verkörperter Hunger",[4344]="Sammler Astorestes",[4345]="Verlassener Vorrat",[4346]="Gestohlene Ausrüstung",[4347]="Gierstein",[4348]="Belohnung der Gier",[4349]="Xixin der Räuberische",[4350]="Weltenschmauser Chronn",[4351]="Notizen des verlorenen Jüngers",[4352]="Harnisch des Larionbändigers",[4353]="Experimentelles Konstruktteil",[4354]="Werkzeuge des Windschmieds",[4355]="Reliktschatz",[4356]="Abstecher ins Abenteuer",[4357]="Gormkäfig",[4358]="Rückmeldung: Rendel und Knüppelfratze",[4359]="Aspirant Eolis",[4360]="Tierrettung",[4361]="Speer des Aspiranten",[4362]="Sprießender Auswuchs",[4363]="Sprießender Auswuchs",[4364]="Echo von Aella",[4365]="Rückmeldung: Großmeister Vole",[4366]="Schleimbedeckte Kiste",[4368]="Truhe der würdigen Aspirantin",[4369]="Rückmeldung: Seuchenerfinder Marileth",[4370]="Beschworener Tod",[4371]="Rückmeldung: Jagdhauptmann Korayn",[4372]="Pesthetzer",[4373]="Aufgeblähte Plünderfliege",[4374]="Runengebundene Lade",[4375]="Runengebundene Lade",[4376]="Zo'Sorg",[4377]="Rückmeldung: Polemarch Adrestes",[4378]="Labyrinthmischling",[4379]="Huwerath",[4380]="Seelenbrunnen",[4381]="Boshafte Stygia",[4382]="Wahnsinniger schlundgebundener Fessler",[4383]="Dartanos",[4384]="Verängstige Seele",[4385]="Rückmeldung: Dromanin Aliothe",[4386]="Agonix",[4387]="Rückmeldung: Choofa",[4388]="Sehr hohe Klippe",[4389]="Ausgetrocknete Motte",[4390]="Gedenkopfergaben",[4391]="Rückmeldung: Sika",[4392]="Drezgruda",[4393]="Schwappi",[4394]="Sündenfresser",[4395]="Kedu",[4396]="Rückmeldung: Mikanikos",[4397]="Rückmeldung: Baronin Vashj",[4398]="Seelenverzerrer Cero",[4399]="Vesperglocke des Silberwinds",[4400]="Faeschinder",[4401]="Astra",[4402]="Mi'kai",[4403]="Glimmerstaub",[4404]="Senthii",[4405]="Glimmerstaub",[4406]="Traumweber",[4407]="Niya",[4408]="Grubs Schaufel",[4409]="Steinschmeißers Sündenstein",[4411]="Thelas Gedächtnisstein",[4412]="Rückmeldung: Alexandros Mograine",[4413]="Die Gräfin",[4414]="Lady Mondbeere",[4415]="Mikanikos",[4416]="Alexandros Mograine",[4417]="Jagdhauptmann Korayn",[4418]="Rendel und Knüppelfratze",[4419]="Dromanin Aliothe",[4420]="Großmeister Vole",[4421]="Kleia und Pelagos",[4422]="Seuchenerfinder Marileth",[4423]="Sika",[4424]="Steinkopf",[4425]="Rückmeldung: Kleia und Pelagos",[4426]="Thelas Gedächtnisstein",[4427]="Cyrixia",[4428]="Halas Schwert",[4429]="Hofzermalmer",[4430]="Prinz Renathal",[4432]="Ispiron",[4433]="Ersatzteile",[4434]="Knickerbock",[4435]="Der Winterwolf",[4436]="Gluthof: Erinnerungen an die Sterblichkeit",[4437]="Blisswing Rescue NPC",[4438]="Venthyrprovokateur",[4439]="Brutale Blase",[4440]="Gluthimmelsschrecken",[4441]="Halas Schwert",[4442]="Karynmwylyanns Erinnerungskristall",[4443]="Thelas Gedächtnisstein",[4445]="Gluthof: Tubbins' Teekränzchen",[4446]="Gluthof: Traditionell",[4447]="Gluthof: Blick in die Wildnis",[4448]="Gefäß mit auffälligem Schleim",[4449]="Gestohlener Krug",[4450]="Das Necro-mjam-nicon",[4451]="Seuchensturztruhe",[4452]="Gluthof: Deliziöse Desserts",[4453]="Gluthof: Rituale der Buße",[4454]="Glutherns Vorrat",[4455]="Gluthof: Steingeborene Reservisten",[4456]="Schatz des Runensprechers",[4457]="Truhe des Ritualisten",[4458]="Gluthof: Freiwillige Venthyr",[4459]="Orophea",[4460]="Jagd: Schemenhunde",[4461]="Jagd: Seelenfresser",[4462]="Jagd: Todeselementare",[4463]="Zovak der Schinder",[4464]="Gluthof: Pilz Surprise",[4465]="Yero der Sprunghafte",[4466]="Venthyrverstärkungen verfügbar",[4467]="Nekrolordverstärkungen verfügbar",[4468]="Kyrianerverstärkungen verfügbar",[4469]="Nachtfaeverstärkungen verfügbar",[4470]="Gluthof: Armee von Maldraxxus",[4471]="Madalavs Hammer",[4472]="Schmiedemeister Madalav",[4473]="Valfir der Unerbittliche",[4474]="Funkelnder Animasamen",[4475]="Schmucktau",[4476]="Orstus und Sotiros",[4477]="Schwarze Glocke",[4478]="Letzter Faden",[4479]="Gluthof: Mysteriöse Spiegel",[4480]="Terrorschreckballiste",[4481]="Horn des Mutes",[4482]="Verlangen der Gier",[4483]="Großer Gierstein",[4484]="Runenlade der Auserwählten",[4485]="Bußfertigkeit der Reinheit",[4486]="Große Mondlichtkapsel",[4487]="Truhe des Wolkenwanderers",[4488]="Machtmissbrauch",[4489]="Unter die Gäste mischen",[4490]="Pulsierender Egel",[4491]="Verderbtes Sediment",[4492]="Violetter Fehler",[4493]="Gehlo",[4494]="Knochenschlürfer",[4495]="Brandblase",[4496]="Öliger Invertebrat",[4497]="Der Mord an Oberst Mort",[4498]="Steinernes Vermächtnis",[4499]="Modeverbrechen",[4500]="Einen Hauch komfortabler",[4501]="Partystörer",[4502]="Gestohlene Andenken",[4503]="Valis der Grausame",[4504]="Gluthof: Der Verschüttete Kelch",[4505]="Gluthof: Tubbins' Teekränzchen",[4506]="Verlassene Schätze",[4507]="Geschmuggelte Truhe",[4508]="Der Mord an Oberst Mort",[4509]="Verlorener Federkiel",[4510]="Schicker Sonnenschirm",[4511]="Der Zinnengraf",[4512]="Rapier der Furchtlosen",[4513]="Tote Graumähne",[4514]="Vyrthas Schreckensgleve",[4515]="Vergessene Angelrute",[4516]="Verbotene Kammer",[4517]="Behelfsmäßige Schlammlache",[4518]="Hundemeister Vasanok",[4519]="Sanngror der Folterer",[4520]="Huschende Brutmutter",[4521]="Steinfaust",[4522]="Altar der Sünde",[4523]="Verlorene Rüstung",[4524]="Halas Schwert",[4525]="Velkeins Schwert",[4526]="Rasselbeutel",[4527]="Exos",[4528]="Schatz des Zuchtmeisters",[4529]="Darithis der Düstere",[4530]="Urahne Nadox",[4531]="Prinz Taldaram",[4532]="Krik'thir der Torwächter",[4533]="Trollgrind",[4534]="Novos der Beschwörer",[4535]="Der Prophet Tharon'ja",[4536]="Falric",[4537]="Marwyn",[4538]="Schmiedemeister Garfrost",[4539]="Geißelfürst Tyrannus",[4540]="Bronjahm",[4541]="Der schwarze Ritter",[4542]="Prinz Keleseth",[4543]="Ingvar der Brandschatzer",[4544]="Skadi der Skrupellose",[4545]="Lady Todeswisper",[4546]="Professor Seuchenmord",[4547]="Blutkönigin Lana'thel",[4548]="Flickwerk",[4549]="Noth der Seuchenfürst",[4550]="Es regnet Anima",[4551]="Nekromantische Anomalie",[4552]="Gezähmter Lichtungsläufer",[4553]="Fallen gelassene Stygia",[4554]="Dunkelvorstoßvorräte",[4555]="Jagd: Todeselementare",[4556]="Truhe der Nacht",[4557]="Stygisches Reliquiar",[4558]="Schwer zu findende Feentruhe",[4559]="Verzauberter Traumfänger",[4560]="Traumsangherz",[4561]="Lebhafte Drachenfeder",[4562]="Harmonische Truhe",[4563]="Feenschatz",[4564]="Aufgequollener Animasamen",[4565]="Uraltes Wolkenfederei",[4566]="Verlorenes Säckchen",[4567]="Aerto",[4568]="Stygischer Einäscherer",[4569]="Torghast",[4570]="Argentumheiler",[4571]="Vesperreparatur: Sophias Ouvertüre",[4572]="Epischer Riesenschatz",[4573]="Odalrik",[4574]="Flucht aus der Dunkelheit",[4575]="Dionae",[4576]="Läuternder Trunk",[4577]="Silberne Schließkassette",[4578]="Tor zur Heldenrast",[4579]="Gefesselte Ausreißer",[4580]="Ikras der Verschlinger",[4581]="Kletterwuchs",[4582]="Reife Purianfrucht",[4583]="Tor zur Heldenrast",[4584]="Sündensteinfragmente",[4585]="Arglistiger Tod",[4586]="Vorräte",[4590]="Zo'Sorgs versteckter Schatz",[4591]="Rendel und Knüppelfratze",[4592]="Kleia und Pelagos",[4593]="Ritual der Absolution",[4594]="Ritual des Urteils",[4595]="Archivar Fane",[4596]="Archivar Fane",[4598]="Grufthüter Kassir",[4599]="Sühnengruftschlüssel",[4600]="Die Anklägerin",[4601]="Klagende Seele",[4602]="Ziellose Seele",[4603]="Rattenschwärmer",[4604]="Gebändigte Seele",[4605]="Arkobanhalle",[4606]="Jagd: Geflügelte Seelenfresser",[4607]="Verwundete Seele",[4608]="Geplünderte Seele",[4610]="Ausgelaugte Seele",[4612]="Zorn des Kerkermeisters",[4613]="Zorn des Kerkermeisters",[4614]="Zorn des Kerkermeisters",[4615]="Zorn des Kerkermeisters",[4616]="Rakul der Seelenverwüster",[4617]="Gefangene Seele",[4618]="Zorn des Kerkermeisters",[4619]="Gepeinigte Seele",[4625]="Endlauerer",[4626]="Famu der Unendliche",[4627]="Verbotene Kammer",[4628]="Alascene",[4629]="Fleddermausstatue",[4630]="Schlosssündenmähre",[4631]="Steinscheusalsschwarm",[4632]="Inaktiver Felskieferbeschützer",[4633]="Händler für durchflutete Rubine",[4634]="Chaotischer Rissstein",[4636]="Vergessene Truhe",[4637]="Vergessene Truhe",[4638]="Vergessene Truhe",[4639]="Vergessene Truhe",[4640]="Vergessene Truhe",[4641]="Vergessene Truhe",[4642]="Vergessene Truhe",[4643]="Vergessene Truhe",[4644]="Vergessene Truhe",[4645]="Vergessene Truhe",[4646]="Vergessene Truhe",[4647]="Vergessene Truhe",[4648]="Chaotischer Rissstein",[4650]="Animastromteleporter",[4651]="Schatz des Zuchtmeisters",[4652]="Inquisitor Sorin",[4653]="Inquisitor Petre",[4654]="Inquisitorin Otilia",[4655]="Inquisitor Traian",[4656]="Hochinquisitorin Gabi",[4657]="Hochinquisitorin Radu",[4658]="Hochinquisitorin Magda",[4659]="Hochinquisitor Dacian",[4660]="Großinquisitor Nicu",[4661]="Großinquisitorin Aurica",[4662]="Großzügiges Geschenk",[4663]="Frisierspiegel",[4664]="Arsenal der Verbündeten",[4665]="Die Wilde Trommel",[4666]="Trainingsattrappe",[4667]="Beschützende Kohlenpfannen",[4668]="Glitschi",[4669]="Altar der Errungenschaften",[4670]="Knochenknacker",[4671]="Animaversetztes Wasser",[4672]="Loderndes Feuer",[4673]="Beschützende Kohlenpfanne",[4674]="Sammelglocke",[4675]="Tubbins' Glücksteekanne",[4676]="Verzauberte Kommode",[4677]="Näherin Rogana",[4678]="Angereicherte Erde",[4679]="Glutmücke",[4680]="Hüter Ta'saran",[4681]="Verdächtiger Kellner",[4682]="Gestohlenes Andenken",[4683]="Festtagsgeschenk",[4684]="Theotars Liederbuch",[4685]="Ältester Naladu",[4686]="Theotars verlockende Düfte",[4687]="Zappelnder Barsch",[4688]="Sprungpilz",[4689]="Entkommener Gormling",[4690]="Verzauberte Kiste",[4691]="Baustelle der Tuskarr",[4692]="Adamantgewölbe",[4693]="Angelsteg",[4694]="Angelsteg",[4695]="Holzbündel",[4696]="Aufgerolltes Seil",[4697]="Angelausrüstung",[4705]="Gefangenenkäfige",[4706]="Stygiakonvergenz",[4707]="Verirrte Seele",[4708]="Zeitwanderungshändler",[4710]="Chaotischer Riss",[4711]="Seelenstahlamboss",[4712]="Theotars Ei",[4713]="Theotar",[4714]="Temels Ei",[4715]="Lord Garridans Ei",[4716]="Prinz Renathals Ei",[4717]="Temel",[4718]="Lord Garridan",[4719]="Theotars Eierjagd",[4720]="Peinigerleutnant",[4721]="Peiniger von Torghast",[4722]="Stygiarückstände",[4723]="Ereignis: Peiniger von Torghast",[4725]="Schlundgebundene Truhe",[4726]="Schlundgebundene Truhe",[4727]="Schlundgebundene Truhe",[4728]="Schlundgebundene Truhe",[4729]="Schlundgebundene Truhe",[4730]="Schlundgebundene Truhe",[4732]="Dominierter Beschützer",[4734]="Energieerfüllter Goliath",[4735]="Energieerfüllter Goliath",[4736]="Energieerfüllter Goliath",[4737]="Energieerfüllter Goliath",[4738]="Hadeon der Steinbrecher",[4739]="Mutter Phestis",[4740]="Schlemmerin",[4741]="Leutnant der Seelenschmiede",[4742]="Gefräßige Überwucherung",[4743]="Brennende Seele",[4744]="Ve'lors Paket",[4745]="Eisseele",[4746]="Gorkek",[4747]="Akkaris",[4748]="Peinigerin von Torghast",[4749]="Versteckte Risstruhe",[4750]="Peinigerin von Torghast",[4751]="Peiniger von Torghast",[4752]="Peiniger von Torghast",[4753]="Peinigerin von Torghast",[4754]="Peiniger von Torghast",[4755]="Peiniger von Torghast",[4756]="Peiniger von Torghast",[4757]="Peiniger von Torghast",[4758]="Peiniger von Torghast",[4759]="Versteckte Risstruhe",[4760]="Versteckte Risstruhe",[4761]="Versteckte Risstruhe",[4762]="Versteckte Risstruhe",[4763]="Versteckte Risstruhe",[4764]="Peiniger von Torghast",[4765]="Peiniger von Torghast",[4766]="Peiniger von Torghast",[4767]="Peiniger von Torghast",[4768]="Peiniger von Torghast",[4769]="Ätherwyrmkäfig",[4770]="Orixal",[4771]="Ereignis: Zorn des Kerkermeisters",[4772]="Ereignis: Zorn des Kerkermeisters",[4773]="Ereignis: Peiniger von Torghast",[4774]="Kroke der Gepeinigte",[4775]="Schlundgebundene Truhe",[4776]="Phantasmatisches Amalgam",[4777]="Ylva",[4778]="Gefallenes Streitross",[4779]="Schlundgebundene Truhe",[4780]="Signaturautorisierungsgerät",[4781]="Glitzerndes Nestmaterial",[4782]="Torglluun",[4783]="Malbog",[4784]="Vergessene Feder",[4785]="Verlorenes Andenken",[4786]="Seidenschreiterlarve",[4787]="Energiekern",[4788]="Amulett der Aspirantin",[4789]="Schankgriffels Tablett",[4790]="Heruntergefallenes Nest",[4791]="Lassiks Kissen",[4792]="Ryujas Rucksack",[4793]="Schlinger",[4794]="Animabeladenes Ei",[4795]="Kinessas Skelett",[4796]="Freund?",[4798]="Gewaltiger Exterminator",[4799]="Schlundgebundener Exterminator",[4800]="Konthrogz der Zerstörer",[4801]="Spektralgebundene Truhe",[4802]="Spektralgebundene Truhe",[4803]="Deomen der Vortex",[4804]="Versetztes Relikt",[4805]="Helgebundene Truhe",[4806]="Uralter Teleporter",[4808]="Verräter Balthier",[4809]="Juwelenbesetztes Herz",[4810]="Schreiender Schemen",[4811]="Befallener Überrest",[4812]="Opferkiste",[4813]="Verbrenner Arkolath",[4814]="Wache Orguluus",[4815]="Blendender Schatten",[4816]="Zovaals Tresor",[4817]="Uralter Teleporter",[4818]="Scharfrichter Varruth",[4819]="Schreiender Schemen",[4820]="Lautloser Seelenpirscher",[4821]="Lautloser Seelenpirscher",[4822]="Totenseelenbrüter",[4823]="Totenseelenbrüter",[4824]="Reliktbrecherin Krelva",[4825]="Relikttruhe",[4826]="Relikttruhe",[4827]="Knochenhaufen",[4828]="Splitterfellvorrat",[4829]="Knochenhaufen",[4830]="Kaputter Torbrecher",[4831]="Kaputter Torbrecher",[4832]="Stygischer Steinzermalmer",[4833]="Relikttruhe",[4834]="Verlockende Trommel",[4835]="Entkommener Wildling",[4836]="Reliktbrecherin Krelva",[4837]="Popoes Trankpatrouille",[4838]="Popoes Trankpatrouille",[4839]="Wilder Weltenknacker",[4840]="Leichenhaufen",[4841]="Fleischschwinge",[4842]="Invasiver Schlundpilz",[4843]="Invasiver Schlundpilz",[4844]="Invasiver Schlundpilz",[4845]="Invasiver Schlundpilz",[4846]="Invasiver Schlundpilz",[4847]="Nest aus ungewöhnlichen Materialien",[4848]="Nest aus ungewöhnlichen Materialien",[4849]="Nest aus ungewöhnlichen Materialien",[4850]="Nest aus ungewöhnlichen Materialien",[4851]="Nest aus ungewöhnlichen Materialien",[4852]="Schlundgebundene Truhe",[4853]="Schlundgebundene Truhe",[4854]="Leichenhaufen",[4855]="Bob der Schmied",[4857]="Angriffsversorgungskutsche",[4858]="Beobachter Yorik",[4859]="Uralter Teleporter",[4860]="Yarxhov der Plünderer",[4861]="Uralter Teleporter",[4862]="Xyraxz der Unbegreifliche",[4863]="Zelnithop",[4864]="Schlundberührte Klingenschwinge",[4865]="Rissgebundene Truhe",[4866]="Ve'rayn",[4867]="Rissgebundene Truhe",[4868]="Rissgebundene Truhe",[4869]="Rissgebundene Truhe",[4871]="Angriffsversorgungskutsche",[4872]="Soggodon der Brecher",[4873]="Oros Kaltherz",[4874]="Bubbins",[4875]="Feuer",[4876]="Vergessener Goliath",[4877]="Untergetauchte Truhe",[4878]="Theotars Verkoster",[4879]="Theotars bedenkliche Beschwörungen",[4880]="Visionen von Graf Denathrius",[4881]="Theotars immerwährendes Festmahl",[4882]="Kutschenzermalmer",[4883]="Zurückgelassener Schleierstab",[4884]="Unverderbtes Klingenschwingenei",[4885]="Verschlingender Spalt",[4886]="Schlundgebundenes Portal",[4887]="Verzaubertes Wellenreiterbrett",[4888]="Ruhelose Welle",[4889]="Versunkene Schatzkiste",[4890]="Beschützer der Ersten",[4891]="Beschädigter Behälter der Jiro",[4892]="Destabilisierter Kern",[4893]="Garudeon",[4894]="Reserve des Aufsehers",[4895]="Zelt des Obsidiankommandanten",[4896]="Obsidianbelagerungsschmiede",[4897]="Obsidianherausforderung",[4898]="Beschwörungsritual der Djaradin",[4899]="Kolossaler Aurelid",[4900]="Bergsteigerlager",[4902]="Teleportkette",[4903]="Tethos",[4904]="Sturmrücken",[4905]="Gesammelte Konkordanzen",[4906]="Schimmerschlund",[4907]="Verlorene Schriftrolle",[4908]="Unbeständiger Sand",[4909]="Generalin Zarathura",[4910]="Legionsinvasionssignal",[4913]="Spießrutenlauf des Kerkermeisters",[4915]="Narduke",[4916]="Annihilanhoffnungsbrecher",[4917]="Zurückgelassenes Automa",[4918]="Iska",[4919]="Phalangax",[4920]="Edra",[4923]="Bibliotheksarchiv",[4925]="Vorlagenarchiv",[4926]="Vergessenes Protoarchiv",[4928]="Provistruhe",[4929]="Entdeckung des Spürauges",[4931]="Die Matriarchin",[4933]="Der Umhüller",[4934]="Verdächtig wütender Tresor",[4936]="Vexis",[4937]="Sorranos",[4938]="Xy'rath der Begehrliche",[4939]="Otiosen",[4940]="Zatojin",[4941]="Otaris der Provozierte",[4942]="Symphonisches Archiv",[4943]="Tahkwitz",[4944]="OOX-Flinkfuß/MG",[4945]="Verderbter Architekt",[4946]="Uralter Translokator",[4947]="Seilrutschenlager",[4948]="Chitali der Älteste",[4949]="Zoridian",[4950]="Helmix",[4951]="Oberster Häscher Damaris",[4952]="Reanimatrox Marzan",[4953]="Rhuv",[4954]="Aufmerksamer Pocopoc",[4955]="Frostschwinges Schicksal",[4956]="Dämonenversklavter Vollstrecker",[4957]="Wilder Wasserwirbelwind",[4958]="Der heulende Vilomah",[4959]="Veränderlicher Sternfresser",[4960]="Fehlerhafter Architekt",[4961]="Euv'ouk",[4962]="Klauenverschrammte Tasche",[4963]="Protoformbauplan",[4964]="Schlundgebundene Truhe",[4965]="Gestohlenes Relikt",[4966]="Chiffrengebundene Truhe",[4967]="Vitiane",[4968]="Herrschaftstruhe",[4969]="Schlundgebundene Vorratstruhe",[4970]="Ornidennest",[4971]="Tarachnideneier",[4973]="Angenagter Handkoffer",[4974]="Weggeworfener Automaschrott",[4975]="Gefallenes Gewölbe",[4976]="Zerschmetterte Vorratskiste",[4977]="Sandmatriarchin Ilius",[4978]="Breibedecktes Relikt",[4979]="Geklautes Artefakt",[4980]="Reserve des Architekten",[4981]="Verwechseltes Ovoid",[4982]="Garudeon",[4983]="Vorräte des ertrunkenen Mittlers",[4984]="Hirukon",[4985]="Hirukon",[4986]="Überwucherte Protofrucht",[4987]="Opfergabe an die Ersten",[4988]="Beschützer der Ersten",[4989]="Verderbter Architekt",[4990]="Zatojin",[4991]="Bedarfsoriginator",[4992]="Protomineralienextraktor",[4993]="Stibitzte Kuriosität",[4994]="Gestohlene Schriftrolle",[4995]="Dankbares Geschenk",[4996]="Protofloraernter",[4997]="Vergessener Schatztresor",[4998]="Syntaktisches Gewölbe",[4999]="Protobirne",[5000]="Chiffrenkonsole",[5001]="Wogendes Blattwerk",[5002]="Ein Scheffel Progenitorerzeugnisse",[5003]="Rundtruhe",[5004]="Merl",[5005]="Klettererlager",[5006]="Sandgeschliffene Truhe",[5007]="Verstärkungskonsole",[5011]="Angelhütte",[5013]="Prototypbauplan",[5014]="Breibedecktes Relikt",[5015]="Breibedecktes Relikt",[5016]="Katalogisiererlager",[5018]="Untergetauchte Truhe",[5019]="Zerfleddertes Astraltuch",[5020]="Verstärkungskonsole",[5021]="Vorräte des ertrunkenen Mittlers",[5022]="Verschlossene Truhe",[5023]="Schatztruhe",[5024]="Firim im Exil",[5025]="Firim im Exil",[5026]="Firim im Exil",[5027]="Firim im Exil",[5028]="Firim im Exil",[5029]="Firim im Exil",[5030]="Firim im Exil",[5031]="Firim im Exil",[5032]="Geistwandlervision",[5033]="Geistwandlervision",[5034]="Vorratsdepot",[5035]="Käferkauer",[5036]="Dracthyrschatz",[5039]="Rußschuppe die Unbeugsame",[5040]="Portal",[5041]="Verdächtige Flasche",[5042]="Tasche voller verzauberter Winde",[5043]="Tripletath der Verlorene",[5044]="Harkyn Grymmstein",[5045]="Steinbrech",[5046]="Vorratskiste der Vollsegel",[5047]="Galgresh",[5048]="Verschlossene Bibliothek",[5049]="Gorbo der Thronräuber",[5050]="Kaskade",[5051]="Seine Fluffigkeit",[5052]="Schatztruhe",[5053]="Geheimer Perlmuttschatz der Gorloc",[5054]="Klettererlager",[5055]="Urscythidenkönigin",[5056]="Ga'ree",[5057]="Uralter Flunker",[5058]="Kleines verirrtes Entchen",[5062]="Kriegsmeisterin der Nokhud",[5063]="[PH] Gorloc Historian",[5066]="Säbelzahnmatrone",[5067]="Verschlossene Truhe",[5068]="Ravinni",[5069]="Anhydros der Gezeitenräuber",[5071]="Odd Mana Infused Crystal",[5073]="Alte Truhe",[5074]="Alte Truhe",[5075]="Seltener Mechanoid",[5076]="Seltene Ananaspizza",[5077]="Jäger der Tiefe",[5078]="Eisenbaum",[5079]="Verlorenes Kissen",[5080]="Testing Rare Vignette",[5081]="Nächster Kontrollpunkt",[5082]="Testing Treasure",[5084]="Erdschlund",[5085]="Instabile Fumarole",[5086]="Verstärkter Haken",[5087]="Zerimek",[5089]="Georteter Schatz 01",[5090]="Gebundene Truhe",[5092]="Ursturm",[5094]="Untersuchungsfernrohr",[5095]="Pirscher von Ausblick 01",[5096]="Grabwühler Khenbish",[5097]="Unterwasserknochen",[5099]="Tokker",[5100]="Uraltes Monument",[5103]="Jagdtrupp 001",[5104]="Bronzezeithüter",[5107]="Penumbrus",[5108]="Shas'ith",[5109]="Turboris",[5110]="Weltenschnitzer A'tir",[5111]="Ambossbrecher Azor",[5112]="Kampfhorn Pyrhus",[5113]="Schatten des Todes",[5114]="Kampfhorn Pyrhus",[5115]="Seng",[5116]="Magmaton",[5117]="Hessethiashs erbärmlich versteckter Schatz",[5118]="Tresor des Erdwächters",[5119]="Wiederhergestellter Morchock",[5120]="Pirschender Säbelzahn",[5121]="Hungriger Schluchtgeier",[5122]="Norbett",[5123]="Wütender Mammutbulle",[5124]="Uranto",[5125]="Der Große Flunk",[5126]="Drachenjäger Igordan",[5127]="Kluzicc der Aufgestiegene",[5128]="Zurückgelassener Waffenständer",[5129]="Todesriss",[5130]="Scytherin",[5131]="Ty'foon der Aufgestiegene",[5132]="Tazenrath",[5133]="Ketess der Plünderer",[5134]="Verlorenes drakonisches Stundenglas",[5135]="Schwefiron",[5136]="Porta der Überwucherte",[5137]="Ausgeweidetes Riesenwildschaf",[5138]="Adlermeisterin Niraak",[5139]="Versteckter Flunkerhort",[5140]="Windschuppe der Sturmgeborene",[5141]="Sturmritual",[5142]="Kriegsspeer der Nokhud",[5143]="Vaniik der Verderbte",[5144]="Quaker der Schreckliche",[5146]="Ursturm",[5147]="Ursturm",[5148]="Ursturm",[5149]="Elementarsturm",[5150]="Großes Entennest",[5152]="Lava Fish School FX",[5153]="Frostpfote",[5157]="Urelemente",[5158]="Diebische Gnolle",[5159]="Urelemente",[5160]="Proto-Drake Hangout (NAME WIP)",[5162]="Urelemente",[5163]="Gespinstkönigin Ashkaz",[5165]="Shezra",[5166]="Fliederfarbene Protomutter",[5167]="O'nank Strandsieb",[5168]="Dampfkieme",[5169]="Schmokflunk der Feuerspeier",[5170]="Sonnenschuppenungetüm",[5171]="Amethyzar der Glitzernde",[5172]="Azras preisgekrönte Pfingstrose",[5173]="Wütender Saphir",[5174]="Donnernde Matriarchin",[5175]="Riesige Magmakrabbe",[5176]="Wütender Dampffontänenelementar",[5177]="Wollfang",[5178]="Fetzsäge der Pirscher",[5179]="Territorialer Küstling",[5180]="Razk'vex der Ungezähmte",[5181]="Solethus' Grabstein",[5182]="Fulgurb",[5183]="Mikrin der tobenden Winde",[5184]="Seuchenfell",[5185]="Sandana der Sturm",[5186]="Trilvarus Lehrenweber",[5187]="Scav Ohneschweif",[5189]="Beogoka",[5190]="Schuppensucherin Mezeri",[5191]="Vergessene Schöpfung",[5192]="Pfliep",[5193]="Brutweberin Araznae",[5194]="Vakril",[5195]="Malsegan",[5196]="Henlare",[5197]="Gorjo der Krabbenfessler",[5198]="Eldoren der Wiedergeborene",[5199]="Oshigol",[5200]="Zaubergeschmiedeter Schneemann",[5201]="Flussläufer Tamopo",[5203]="Lord Epochenbrgl",[5204]="Matriarchin Remalla",[5205]="Ronsak der Dezimierer",[5206]="Schroffi",[5207]="Orkandrian",[5208]="Hanmuk",[5209]="Prunkvoller Schimmerflügel",[5210]="Grollrüssel",[5211]="Dracthyrgeheimnis",[5212]="Eisriss",[5213]="Beschworener Zerstörer",[5214]="Erdhaufen",[5215]="Melkhop",[5217]="Galzuda",[5218]="Angen",[5224]="Wilrive",[5225]="Brockon",[5226]="Kristallus",[5227]="Karantun",[5228]="Infernum",[5229]="Titanischer Reaktor",[5230]="Emblazion",[5231]="Grizzlefels",[5232]="Gaelzion",[5233]="Gravlion",[5234]="Frozion",[5235]="Verderbter Protodrache",[5236]="Urtumbeschützerin",[5237]="Aufgebrachter Elementar",[5238]="Rokmur",[5239]="Ausguck Mordren",[5240]="Prozela Windschuss",[5241]="Voraazka",[5242]="Kain Feuermal",[5243]="Eisklingentrio",[5244]="Zurgaz Kernbrecher",[5245]="Rouen Eiswind",[5246]="Pipfunke Donnerschnapp",[5247]="Neela Feuerfluch",[5248]="Phenran",[5249]="Jareeza",[5251]="Zerbrochene Angelrute",[5252]="Kaltpelzhöhlenmutter",[5253]="Honmor",[5254]="Tomnu",[5255]="Uurtus",[5256]="Stummel der Verstümmler",[5257]="Verlorene Obsidiantruhe",[5258]="Anomalie",[5259]="Galnmor",[5260]="Salkii",[5261]="Borzgas",[5262]="Kristallsammler",[5263]="Verdrängte Energie",[5264]="Muugurv",[5265]="Gamgus",[5266]="Degmakh",[5267]="Arkanverschlinger",[5268]="Arkaner Foliant",[5269]="Brackel",[5270]="Ergburk",[5271]="Khomuur",[5272]="Windflüsterin Navati",[5273]="Expeditionsversorgungspaket",[5274]="Rokzul",[5275]="Zagdech",[5276]="Kholdeg",[5277]="Zumakh",[5279]="Experimenteller Verderbniskessel",[5280]="Verzauberter Schlick",[5281]="Uurhilt",[5282]="Khuumog",[5283]="Tenmod",[5284]="Dunkle Schmiede",[5285]="Gebrochene Balken",[5289]="Schönes Juwel des Malers",[5290]="Vergessenes Schmuckkästchen",[5291]="Foliant des vergesslichen Lehrlings",[5292]="Verfallerfülltes Gerböl",[5293]="Interessanter blauer Stoffballen",[5294]="Tuskarrtrommel",[5295]="Harmonische Truhe",[5296]="Bummthyrrakete",[5297]="Frostgeschmiedeter Trank",[5300]="Kristalliner Überwuchs",[5302]="Feuriger Edelstein",[5303]="Lavaerfüllter Samen",[5304]="Erhabener Malygit",[5305]="Welplingzähmen leicht gemacht",[5306]="Ersatzwerkzeuge der Djaradin",[5307]="Modernde Brackenfelldecke",[5308]="Hervorgebrochene Alexstraszitansammlung",[5310]="Kiste mit behandelten Bälgen",[5311]="Miniaturbanner des bronzenen Drachenschwarms",[5312]="Frostgeschmiedeter Trank",[5314]="Streng bewachter Glitzerkram",[5315]="Sturmgebundenes Horn",[5316]="Mattes Pergament",[5317]="Angereicherter Erdsplitter",[5318]="Mysteriöse Kessel",[5319]="Beutel voller verrotteter Schuppen",[5320]="Kampfgestählter Zentaurenteppich",[5321]="Verlockender Barren",[5322]="Staubige Dunkelmondkarte",[5323]="Windgesegneter Balg",[5324]="Verbotenes Gemisch",[5325]="Mysteriöses Banner",[5326]="Überraschungsseidenraupe",[5327]="Angesengter Wanderstoff",[5328]="Frostgeschmiedeter Trank",[5329]="Referenzblatt für Gebärdensprache",[5330]="Bündel des Wilderers",[5331]="Kleiner Korb mit Feuerwasserpulver",[5332]="Waffendiagramm der Qalashi",[5333]="Drakonischer Flux",[5334]="Eigentümliche Barren",[5335]="Uralte Speersplitter",[5336]="Uralte Speersplitter",[5337]="Lanzenmeisterin der Nokhud",[5338]="Totem der Sturmwoge",[5339]="Schockgefrorene Schriftrolle",[5340]="Vergessener arkaner Foliant",[5341]="Blaufederbanner",[5342]="Gebrochene titanische Sphäre",[5343]="Katalogisiererlager",[5344]="Zeichnungen der Stulpen des Falkners",[5346]="Moskhoi",[5347]="Yaankhi",[5348]="Tor",[5349]="Uralter Drachenwebrahmen",[5350]="Tevgai",[5351]="Cinta der Vergessene",[5352]="Der fröhliche Riese",[5353]="Smaragdedelsteinklumpen",[5354]="Flinkschwingenmatriarchin",[5356]="Leuchtsignal der Allianz entdeckt",[5357]="Leuchtsignal der Horde entdeckt",[5358]="Bernsteinklumpen",[5359]="Yamakh",[5360]="Mantai",[5361]="Arkhuu",[5362]="Tsokorg",[5363]="Molkeej",[5364]="Diluu",[5365]="Makhra der Aschenberührte",[5367]="Goldener Drachenkelch",[5369]="Ausgelegtes Fischernetz",[5370]="Jagdausrüstung",[5371]="Sandhaufen",[5372]="Firava der Entzünder",[5373]="Vergessenes Schmuckkästchen",[5374]="Onyxedelsteinklumpen",[5375]="Saphiredelsteinklumpen",[5377]="Dreschflegel des Gnollunholds",[5378]="Forscherin Schleichflügel",[5379]="Gesprungenes Stundenglas",[5380]="Spritzbauch der Schnabelsenker",[5381]="Schattenschlitzer Trakken",[5382]="Enkine der Gefräßige",[5383]="Vergessener Greif",[5384]="Schlabbro",[5385]="Hauptmann Lancer",[5386]="Kriegstrupp der Qalashi",[5387]="Terillod der Andächtige",[5388]="Morchok",[5389]="Skaara",[5390]="Hoher Gipfel",[5391]="Hoher Gipfel",[5392]="Hoher Gipfel",[5393]="Hoher Gipfel",[5394]="Hoher Gipfel",[5395]="Hoher Gipfel",[5396]="Hoher Gipfel",[5397]="Blasentreiber",[5398]="Seelenernter Mandakh",[5399]="Seelenernterin Tumen",[5400]="Seelenernter Duuren",[5401]="Seelenernterin Galtmaa",[5402]="Grabesfürstin Monkh",[5403]="Maruuk",[5404]="Teera",[5405]="Bronzezeithüter",[5406]="Gefreite Shikzar",[5407]="Wassergebundene Truhe",[5408]="Winde der Inseln",[5409]="Hoher Gipfel",[5410]="Hoher Gipfel",[5411]="Hoher Gipfel",[5412]="Hoher Gipfel",[5413]="Nuschelknochen",[5414]="Blasenfell",[5415]="Knorren",[5416]="Hochschamanin Faulknöchel",[5417]="Hoher Gipfel",[5418]="Hoher Gipfel",[5419]="Hoher Gipfel",[5420]="Hoher Gipfel",[5421]="Hoher Gipfel",[5422]="Hoher Gipfel",[5423]="Hoher Gipfel",[5424]="Hoher Gipfel",[5425]="Hoher Gipfel",[5426]="Gefülltes Fischernetz",[5427]="Innovationsmaschine",[5428]="Elementargebundene Truhe",[5430]="Balgar",[5431]="Schatzbesessener Trambladd",[5432]="Sturmruferin Veldra",[5433]="Ritualstätte der Urschildkröten",[5434]="Celormu",[5435]="Angelausrüstungsherstellerin",[5436]="Acrosoth",[5437]="Liskron der Blendende",[5438]="Lohengebundener Zerstörer",[5439]="Der Große Panzerkhan",[5440]="Skag der Werfer",[5441]="Rubinedelsteinklumpen",[5442]="Podium der Transformation",[5443]="Die Abgewetzte Drachenschuppe",[5444]="Die Draufgängerische Drachenschuppe",[5445]="Blockierte Netzstelle",[5446]="Blockierte Netzstelle",[5447]="Fähre",[5448]="Fähre",[5449]="Fähre",[5450]="Fähre",[5451]="Verlorener Arvillo",[5452]="Instabiler Elementarsturm",[5453]="Karawane der Aylaag",[5454]="Instabiler Elementarsturm",[5455]="Instabiler Elementarsturm",[5456]="Instabiler Elementarsturm",[5457]="Bändigerin Rendra",[5458]="Der Zorn des Sturms",[5459]="Der Zorn des Sturms",[5460]="Monster der Primalisten",[5461]="Elementarportal",[5462]="Vinyeti",[5463]="Verbotener Schatz",[5465]="Rarbär",[5466]="Bewegte Erde",[5467]="Magiegebundene Truhe",[5468]="Expeditionsspäherpack",[5469]="Zarizz",[5470]="Katalogisiererin Jakes",[5471]="Murik",[5472]="Agari Dotur",[5473]="Unatos",[5474]="Weinumrankte Kiste",[5475]="Angler Tinnak",[5476]="Magiegebundene Truhe",[5477]="Junger Belvo",[5478]="Alte Beyfir",[5479]="Schönalpha",[5480]="Kesselträgerin Blakor",[5481]="Konvergierender Elementarsturm",[5483]="Fähre",[5484]="Scharfzahn",[5485]="Angelzubehör der Tuskarr",[5486]="Seismografische Untersuchungsstätte",[5488]="Gahz'raxes",[5489]="Ishyra",[5490]="Vraken der Jäger",[5491]="Reisa die Ertrunkene",[5492]="Duzalgor",[5493]="Tektonus",[5494]="Sir Zwickbald",[5495]="Manathema",[5496]="Schnarrfang",[5497]="Knochenstreuer Marwak",[5498]="Galakhad",[5499]="Gareed",[5500]="Grugoth der Schiffbrecher",[5501]="Faunos",[5502]="Gezeitenschmied Zarviss",[5503]="Arkantrix",[5504]="Kangalo",[5505]="Fimbol",[5506]="Agni Feuerhuf",[5507]="Luttrok",[5508]="Amephyst",[5510]="Warcraft Rumble-Münze",[5511]="Warcraft Rumble-Münze",[5512]="Rasnar der Kriegsender",[5513]="Rohzor Schmelzschlag",[5514]="Lady Shaz'ra",[5515]="Vulkanokk",[5516]="Mysteriöse Schriften",[5517]="Veltrax",[5518]="Wundersamer Fisch",[5519]="Uukbart",[5520]="Wächterin Entrix",[5521]="Pyrachniss",[5522]="Ordentlich zerkaute Truhe",[5523]="Lodernde Schattenflammentruhe",[5524]="Runenstein der Dracthyr",[5525]="Geist des Segens",[5526]="Wyrmtöter Angvardi",[5527]="Brodelnde Truhe",[5528]="Ritualopfergaben",[5529]="Ritualopfergaben",[5530]="Ritualopfergaben",[5531]="Ritualopfergaben",[5532]="Kristalliner König",[5533]="Hoher Gipfel",[5534]="Uralte Zaqalitruhe",[5535]="Hoher Gipfel",[5536]="Hoher Gipfel",[5537]="Hoher Gipfel",[5538]="Archivar der Zauberverschworenen",[5539]="Verkohltes Ei",[5540]="Warcraft Rumble-Münze",[5541]="Warcraft Rumble-Münze",[5542]="Warcraft Rumble-Folie",[5543]="Warcraft Rumble-Folie: Gold",[5544]="Irrblick Carrey",[5545]="Katzenminzenwedel",[5546]="Warcraft Rumble-Folie",[5547]="Warcraft Rumble-Folie",[5548]="Warcraft Rumble-Folie: Gold",[5549]="Warcraft Rumble-Folie: Gold",[5550]="Sturmgebundene Truhe",[5551]="Runenstein der Dracthyr",[5553]="Windsucher Avash",[5554]="Granitklaue",[5555]="Wassermassen",[5556]="Malgain Steinglock",[5557]="Shiobhan die Wassergeborene",[5558]="Instabiler Arkanogolem",[5559]="Antreiber Krathos",[5560]="Großkonstrukteurin Zeerak",[5561]="Srivantos",[5562]="Aufseherin Steinzunge",[5563]="Überladende Verteidigungsmatrix",[5564]="Morlash",[5565]="Tikarr Frostklaue",[5566]="Avalantus",[5567]="Splitterschwinge",[5568]="Formmeisterin Za'lani",[5569]="Groffnar",[5570]="Lurgan",[5571]="Sturmruferin Narkena",[5572]="Meisterjägerin Yrgena",[5573]="Blutschnabel der Gefräßige",[5574]="Elementarportal",[5575]="Elementarportal",[5576]="Gesicherte Lieferung",[5580]="Deaktiviertes Elementarportal",[5581]="Deaktiviertes Elementarportal",[5582]="Deaktiviertes Elementarportal",[5583]="Warcraft Rumble-Münze",[5584]="Warcraft Rumble-Münze",[5585]="Warcraft Rumble-Münze",[5586]="Warcraft Rumble-Münze",[5587]="Warcraft Rumble-Folie",[5588]="Warcraft Rumble-Folie",[5589]="Warcraft Rumble-Folie",[5590]="Warcraft Rumble-Folie",[5591]="Warcraft Rumble-Folie",[5592]="Durchnässtes Bündel",[5593]="Lang verlorene Truhe",[5594]="Vinyeti",[5595]="Elitebeute der Verbotenen Insel",[5596]="Katalogisiererin Daela - Gesandtenaufgabe ausstehend",[5597]="Instabile Kohlenpfanne",[5598]="Schrein der Weitenschuppen",[5599]="Ungewürzter Eintopf",[5600]="Buch der arkanen Wesen",[5601]="Beschädigte Brummsäule 505",[5602]="Leere Krabbenfalle",[5603]="Erweckter Boden",[5604]="Schutz der Zauberverschworenen",[5605]="Resonierender Kristall",[5606]="Gerbrahmen der Tuskarr",[5607]="Grollendes Vorkommen",[5608]="Unbehandelte Riesenwildschafpelze",[5609]="Tuskarrdrachenpfosten",[5610]="Anhänger von Fyrakk",[5611]="Fyrakks Schwarm",[5612]="Warcraft Rumble-Folie",[5613]="Warcraft Rumble-Folie",[5614]="Verbotener Schatz",[5615]="Verlegte Auslassblaupläne von Aberrus",[5616]="Unachtsam weggeworfene Bomben",[5617]="Fehlerhaftes Überlebenspaket",[5618]="Kaputter Wyrmlochgenerator",[5619]="Truhe der Schwärme",[5620]="Unauffälliger Datenschürfer",[5621]="Vogelfund",[5622]="Obsidiankiste",[5623]="Vorrat der Zauberverschworenen",[5624]="Knochenhaufen",[5625]="Truhe der Weitenschuppen",[5626]="Vorrat der Eisenfluträuber",[5627]="Sturmfresserhaufen",[5628]="Steinschuppenhaufen",[5629]="Feuerhaufen",[5630]="Frostherzhaufen",[5631]="Rationen von Morqut",[5632]="Gesandtensatzung",[5633]="Der größte Forscher aller Zeiten",[5634]="Objekt",[5635]="Beuteexperte",[5636]="Unidentifiziertes Objekt in der Nähe",[5637]="Blutige Leiche",[5638]="Kob'rok",[5639]="Kapraku",[5640]="Aquifon",[5641]="Schleimo",[5642]="Webmark",[5643]="Alcanon",[5644]="Professor Gastrinax",[5645]="Generalin Zskorro",[5646]="Tiefenlichtkönigin",[5647]="Gestohlenes Lager",[5648]="Gestohlenes Lager",[5649]="Hadexia",[5650]="Von Motten geplünderte Tasche",[5651]="Klakatak",[5652]="Brullo der Starke",[5653]="Karokta",[5654]="Invoq",[5655]="Lavermix",[5656]="Magtembo",[5657]="Kronkapace",[5658]="Von Motten geplünderte Tasche",[5659]="Skornak",[5660]="Dinn",[5661]="Fluffi",[5662]="Subterrax",[5663]="Glutnacht",[5664]="Viridiankönig",[5665]="Handhold Highlighted - 90",[5666]="Handhold Highlighted - 91",[5667]="Handhold Highlighted - 92",[5668]="Handhold Highlighted - 93",[5669]="Greifhakenziel",[5670]="Geschichtenwahrerin Ashekh",[5671]="Bolzen und Bronze",[5672]="Weggeworfener Drakothystbohrer",[5673]="Geschmolzener Späherbot",[5674]="Kolossian",[5675]="Invasion des Grimmigen Säufers",[5676]="Temporalinvesti-gator",[5677]="Geschichtenwahrerin Ashekh",[5678]="Flammenerfülltes Schuppenöl",[5679]="Lavageschmiedetes \"\"Ledermesser",[5680]="Schwefeldurchtränkte Häute",[5681]="Lavaübergossener Schattenkristall",[5682]="Schimmernde aquatische Kugel",[5683]="Resonierender Arkankristall",[5684]="Mimeep",[5685]="Belohnung der Treue",[5686]="Geschmolzener Schatz",[5687]="Alter Koffer",[5688]="Gesicherte Lieferung",[5689]="Zeitrone",[5690]="Kristallummantelte Truhe",[5692]="Unterernährte Exemplare",[5693]="Markgereifter Schleim",[5694]="Verdächtiger Schimmel",[5696]="Schroffe Schneckenhäuser",[5697]="Leicht durchgeschüttelte Juwelen",[5698]="Zerbrochener Tauschfelsbrocken",[5699]="Stressexpress",[5700]="Kristalline Untersuchung",[5701]="Panzerfeuer",[5702]="Räucherduftwerk",[5703]="Müffelnde Mixtur",[5704]="Glimmerfischer",[5705]="Herausforderung des Champions",[5706]="Ruf der Kaskaden",[5707]="Artilleriekrieg",[5708]="Verschwörung der Flammen",[5709]="Seismische Zeremonie",[5710]="Unausgewogenes Gleichgewicht",[5711]="Reliquiar von Nal ks'kol",[5712]="Belohnung des Träumers",[5713]="Myrrit",[5714]="Stinkender Müllhaufen",[5715]="Stinkende bewegte Erde",[5716]="Magmaklauenmatriarchin",[5717]="Wirbelnder Zephyr",[5718]="Hungrige",[5719]="Farbe bekennen",[5720]="Disharmonische Kristalle",[5721]="Monumentenpflege",[5724]="Monströse \"\"Baby\"\"-Magmaklaue",[5725]="Belebte Eindämmung",[5726]="Hüterin der Eingreiftruppe",[5727]="Kontaminierter Titanenhüter",[5728]="Hauptmann Reykal",[5729]="Alte Magmaschlange",[5730]="Höhlenschindermatriarchin",[5731]="Myrrit",[5732]="Schatzgoblin",[5733]="Abgenutzter Brennofen",[5734]="Schwefel-Rettungsring",[5735]="Ältestenspeer der Zaqali",[5736]="Zurückgelassener Reservefallschirm",[5737]="Medizinisches Verbandsset benutzen",[5738]="Fein besticktes Banner",[5739]="Aufwendige Zaqali-Runen",[5740]="Zischender Runenentwurf",[5741]="Uralte Forschung",[5742]="Winde der Inseln",[5743]="Zeitverschobener Kriegsfürst",[5744]="Chronotruhe mit Andenken",[5745]="Fyrakks Schwarm",[5746]="Fyrakks Schwarm",[5748]="Verhülltes Portal",[5749]="Brann Bronzebart",[5750]="Gelöst!",[5751]="Wachtraum",[5752]="Bronzezeithüterassistent",[5753]="Geschmolzener General",[5754]="Flammengebundener Leutnant",[5755]="Aschengebundener Hauptmann",[5759]="Amrymn",[5760]="Schreckloc",[5761]="Läuterungsschmiede",[5762]="Schleimpfütze aus Azmerloth",[5763]="Waffenständer der Bluthorde",[5764]="Waffenständer der großen",[5767]="Warcraft Rumble-Folie",[5768]="Warcraft Rumble-Folie",[5769]="Traumsaattruhe",[5770]="Warcraft Rumble-Folie",[5771]="Warcraft Rumble-Folie",[5772]="Traumsaattruhe",[5773]="Traumsaattruhe",[5774]="Traumsaattruhe",[5775]="Traumsaattruhe",[5776]="Traumsaattruhe",[5777]="Traumsaattruhe",[5778]="Traumsaattruhe",[5779]="Traumsaattruhe",[5780]="Traumsaattruhe",[5782]="Traumsaattruhe",[5783]="Traumsaattruhe",[5784]="Traumsaattruhe",[5785]="Nozdormu",[5786]="Nuoberon",[5787]="Traumsaattruhe",[5788]="Traumsaattruhe",[5789]="Traumsaattruhe",[5790]="Traumsaattruhe",[5791]="Traumsaattruhe",[5792]="Traumsaattruhe",[5793]="Traumsaattruhe",[5794]="Geheimer Schatz",[5795]="Ebenengeborener Vernichter",[5796]="Verbündeter Aschewüter",[5797]="Verlassener Stein der Wiederherstellung",[5798]="Flammenschwingenaszendent",[5799]="Riesige Traummotte",[5800]="Seltsam platzierte Statue",[5801]="Geisel",[5802]="Großer Schmiededämon",[5803]="Große Schmiedekiste",[5804]="Vorlage",[5805]="Obstgesicht",[5806]="Riffbrecher Moruud",[5807]="Gerinnende Träume",[5808]="Raszageths letzter Atemzug",[5809]="Krabbonkerus",[5810]="Splitterast",[5811]="Ignit der Gebrandmarkte",[5812]="Kleinschnappers Fundgrube",[5813]="Superblüte",[5814]="Riffbrecher Moruud",[5815]="Sturer Säbelzahn",[5816]="Gesandter des Winters",[5817]="Habgierige Gessie",[5818]="Lehrling der Schmelzbinderin",[5819]="Blutgestreifter Großrochen",[5820]="Henri Schnupperschweif",[5821]="Geschmolzener Bleistachel",[5822]="Mosa Umbramähne",[5823]="UNUSED_GREEDY GESSIE",[5824]="Isaqa",[5825]="Die Apostelin",[5826]="Verstecktes Mondkinlager",[5827]="Satte Schlummernuss",[5828]="Talthonei Aschengeflüster",[5829]="Talthonei Aschengeflüster",[5830]="Flammendruidenvorrat",[5831]="Magische Blüte",[5832]="Seltsame Knolle",[5833]="Kleine Schlummernuss",[5834]="Satte Schlummernuss",[5835]="Feuerbrand Fystia",[5836]="Königin des Berges",[5837]="Balboan",[5838]="Traumsaattruhe",[5839]="Traumsaattruhe",[5840]="Traumsaattruhe",[5841]="Traumsaattruhe",[5842]="Traumsaattruhe",[5843]="Traumsaattruhe",[5844]="Traumsaattruhe",[5845]="Traumsaattruhe",[5846]="Traumsaattruhe",[5847]="Traumsaattruhe",[5848]="Traumsaattruhe",[5849]="Traumsaattruhe",[5850]="Traumsaattruhe",[5851]="Traumsaattruhe",[5852]="Traumsaattruhe",[5853]="Traumsaattruhe",[5854]="Traumsaattruhe",[5855]="Traumsaattruhe",[5856]="Traumsaattruhe",[5857]="Traumsaattruhe",[5858]="Traumsaaterde",[5859]="Smaragdraserei",[5860]="Energiequelle",[5861]="Arkane Schmiede",[5862]="Traumsaattruhe",[5863]="Traumsaattruhe",[5864]="Traumsaattruhe",[5865]="Traumsaattruhe",[5866]="Traumsaattruhe",[5867]="Traumsaattruhe",[5868]="Traumsaattruhe",[5869]="Traumsaattruhe",[5870]="Statue des Bärenfürsten",[5871]="Ristar der Tollwütige",[5872]="Pinienmaushaufen",[5874]="[DNT] Scenario Sample",[5875]="Schattenflammenwissen anzeigen",[5876]="Traumsaattruhe",[5877]="Traumsaattruhe",[5878]="Traumsaattruhe",[5879]="Morlash",[5880]="Überladende Verteidigungsmatrix",[5881]="Aufseherin Steinzunge",[5882]="Massive Kraftquelle",[5883]="Großkonstrukteurin Zeerak",[5884]="Antreiber Krathos",[5885]="Srivantos",[5886]="Instabiler Arkanogolem",[5887]="Granitklaue",[5888]="Malgain Steinglock",[5889]="Shiobhan die Wassergeborene",[5890]="Wassermassen",[5891]="Blasenfell",[5892]="Knorren",[5893]="Hochschamanin Faulknöchel",[5894]="Nuschelknochen",[5895]="Blutschnabel der Gefräßige",[5896]="Groffnar",[5897]="Meisterjägerin Yrgena",[5898]="Lurgan",[5899]="Sturmruferin Narkena",[5900]="Kampfhorn Pyrhus",[5901]="Kesselträgerin Blakor",[5902]="Kohle",[5903]="Rohzor Schmelzschlag",[5904]="Rasnar der Kriegsender",[5905]="Turboris",[5906]="Funkenfeder",[5907]="Segen von Ursol",[5908]="Moragh die Faule",[5909]="Scharfsichtiger Cian",[5910]="Schlafwandler Ori",[5911]="Matriarchin Keevah",[5912]="Gieriger Mikanji",[5915]="Kerzenerhelltes Refugium",[5916]="Halbvoller Trank des traumlosen Schlafs",[5917]="Spritztrank der Narkolepsie",[5918]="Die Wurzel des Problems",[5919]="Experimenteller Traumfänger",[5920]="Schlaflositron",[5921]="Wachs",[5922]="Ungeschlüpfte Batterie",[5923]="Versteinerte Hoffnung",[5924]="Unpolierter Makel",[5925]="Verschmolzener Traumstein",[5926]="Magische Blüte",[5927]="Magische Blüte",[5928]="Brann Bronzebart (Bewusstlos)",[5929]="Büschel Traumsäblerfell",[5930]="Abgeworfene Feendrachenschuppen",[5931]="Traumkrallenklaue",[5932]="Reines Traumwasser",[5933]="Immerflammenkern",[5934]="Essenz der Träume",[5935]="Statue des Aschepanthers",[5936]="Statue der Himmelsherrin",[5937]="Statue des großen Wolfs",[5938]="Statue des weißen Hirsches",[5939]="Erinnerungen an Murlocs",[5940]="Unvergessener Ragnaros",[5941]="Erinnerungen an Mosh",[5942]="Rennring",[5943]="Winnies Notizen zu Flora und Fauna",[5944]="Säule des Hainhüters",[5945]="Schattenbindungsrune der Primalisten",[5946]="Enorm weicher Wildstoff",[5947]="Flauschiges Kissen",[5948]="Kuschelkumpel",[5949]="Schild der Verteidigerin von Amirdrassil",[5950]="Todespirscherchassis",[5951]="Flammengebundener Reißer",[5952]="Atrejo-Test",[5953]="Nie erwachendes Echo",[5954]="Nie erwachendes Echo",[5955]="Nie erwachendes Echo",[5956]="Nie erwachendes Echo",[5957]="Liebe liegt in der Luft",[5958]="Moth'ethk",[5959]="Rostul Titanenkappe",[5960]="Unvorstellbar seltene Eberleber von makelloser Perfektion",[5961]="Erinnerungen an Kleiner",[5962]="Vergiftete Kürbisse",[5963]="Erinnerungen an Hogger",[5964]="Erinnerungen an Hakkar",[5965]="Süderstade vs. Tarrens Mühle",[5967]="Kochend heißes Morgengebräu",[5968]="Auslöschung der Lepragnome",[5969]="Habgierige Gessie",[5970]="Zone der Grünen Hügel",[5971]="Smaragdfülle",[5973]="Ahg'zagall",[5974]="Kopftücher der Defias!",[5976]="Maybells Liebesbriefe!",[5977]="Goldstaub!",[5978]="Ixkreten die Unzerstörbare",[5979]="Unvergessener Exekutus",[5980]="Schmiedvignette",[5981]="Kristalline Leuchtblüte",[5982]="Seltene Vignettenkiste",[5983]="Vignette für glänzende Kristalle",[5984]="Strahlenverzerrtes Myzel",[5986]="Immerstrom",[5988]="Platschdreck",[5989]="Sporenbedeckte Truhe",[5990]="Seltener Elite der Neruber",[5991]="Einzigartiger Schatz",[5992]="Seltener Stufenaufstieg 1",[5993]="Riesenbohrer",[5994]="Eingesponnener Ranzen",[5995]="Lord Harlbrand",[5996]="Beschädigter Ernter",[5997]="Morkus Grimlock",[5998]="Narla Donnerhuf",[5999]="Rasende Eulenbestie",[6000]="Gorthak Grimmhauer",[6001]="Geronnene Erinnerungen",[6002]="Schlüsselflamme der Fungusfelder",[6003]="Schlüsselflamme von Blüte des Lichts",[6004]="Schlüsselflamme des Surrenden Felds",[6005]="Schlüsselflamme des Stillsteintümpels",[6006]="Schlüsselflamme der Fackelscheinmine",[6007]="Schlüsselflamme der Verblassten Küste",[6008]="Schlüsselflamme von Trübsand",[6009]="Schlüsselflamme des Dämmerhöhenackers",[6010]="Kaldoreitasche",[6011]="Kaldoreispeer",[6012]="Kaldoreischild",[6013]="Kaldoreitasche",[6014]="Kaldoreihorn",[6015]="Kaldoreirucksack",[6016]="Kaldoreischlafsack",[6017]="Kaldoreihorn",[6018]="Kaldoreidolch",[6019]="Kaldoreifernrohr",[6020]="Kaldoreimondbogen",[6021]="Vorräte der Forscherliga",[6024]="Ominöses Portal",[6025]="Schatzraumtür",[6026]="Sandres der Reliktträger",[6027]="Verzauberte Kerze",[6028]="Da'kash",[6029]="Verblasste Vorratstruhe",[6031]="Aufgewühlter Erdfresser",[6032]="Ixlorb die Weberin",[6033]="Der Aufgabenplaner",[6034]="Trübschatten",[6035]="Tiefenunhold Azellix",[6039]="Ewiger Basar",[6040]="Stücke Hass",[6043]="Quellblase",[6044]="Sphärenhorn",[6045]="Blutrachen",[6046]="Kaiser Grubenzahn",[6047]="Pesthart",[6048]="Gar'loc",[6049]="Entkommene Halsabschneiderin",[6050]="Sturmfürst Incarnus",[6051]="Kronolith",[6052]="Seichtpanzer der Klacker",[6053]="Doppelstecher der Jämmerliche",[6054]="Flammenhüter Graz",[6055]="Alunira",[6058]="Zovex",[6060]="Totes Besatzungsmitglied",[6061]="Vergessene Truhe",[6062]="Winde von Dorn",[6064]="Greifhakenziel",[6065]="Herrenlose Beute",[6066]="Kiste mit Kriegsvorräten",[6067]="Kiste mit Kriegsvorräten",[6068]="Kiste mit Kriegsvorräten",[6069]="Großes Entennest",[6070]="Großes Entennest",[6071]="Erntekiste",[6072]="Neruberballiste",[6073]="Beschädigte Spitze",[6074]="Vergessene Schätze",[6075]="Soleschlitzer",[6076]="Transportmittel",[6077]="Verlorene Truhe",[6078]="Todesblatt",[6079]="Zilthara",[6080]="Kerzenfliegerkapitän",[6081]="Schrecken der Schmiede",[6082]="Tiefenschinderbrutmutter",[6083]="Durchnässte Truhe",[6084]="Krötenstampfer",[6085]="Flossenklaue Blutstrom",[6086]="Anglervorratskiste",[6087]="Vergessenes Denkmal",[6088]="König Spritzer",[6089]="Aquellion",[6090]="Felsmund",[6091]="Fingerhuts Vorräte",[6092]="Landarbeitervorrat",[6093]="Kreaturenname",[6094]="[TEMPLATE] Creature Name",[6095]="[TEMPLATE] Creature Name",[6096]="Rettungspaket der Furchtloser Funke",[6097]="Vergessenes Denkmal",[6098]="Beleuchtete Schließkiste",[6099]="Tangmoor",[6100]="Launische Händlerin",[6101]="Geronnenes Monstrum",[6102]="Felsenhauer",[6103]="Tasche des Fischers",[6104]="Glutschürer",[6105]="Tobende Seuche",[6106]="Todesgebundene Hülle",[6107]="Vergessenes Denkmal",[6108]="Kapitänin Lancekats Mittel zur freien Verfügung",[6109]="Feuerpartikel",[6110]="Lauerer der Tiefen",[6111]="Der Landwart",[6112]="Tephratenne",[6113]="Süßfunke der Schleimreiche",[6114]="Matriarchin Kohlfuria",[6115]="Krallenbrecherin K'zithix",[6116]="Vorräte der Forscherliga",[6117]="Verschwind-o-Bot 7000",[6118]="Beledars Brut",[6119]="Hungerleider der Tiefen",[6120]="Durchgedrehter Kohlschläger",[6121]="Sporenerfüllte Schieferschwinge",[6122]="Dämmerschatten",[6123]="Düsterstachel",[6124]="Wüterich",[6125]="Quakit",[6126]="Trungal",[6127]="Ausgang",[6128]="Automaxor",[6129]="Abyssalverschlinger",[6130]="Späher der Feste",[6131]="XT-Minenzermalmer 8700",[6132]="Ekelschwinge",[6133]="Xishorr",[6134]="Seidenschlepper der Kaheti",[6135]="Netzsprecher Grik'ik",[6136]="Cha'tak",[6137]="Monströser Peitschiath",[6138]="Wahnsinniger Belagerungsbomber",[6139]="Robuste Gossenvisage",[6140]="[TEMPLATE] Creature Name",[6141]="Deviat Supremes",[6142]="Durchgebranntes Konstrukt der Sonnenhäscher",[6143]="Das Feuer wird Euch läutern!",[6144]="Prophet von Sseratus",[6145]="Lytfang der Verlorene",[6146]="Grimmschlitz",[6147]="Erinnerungen von König Gordok",[6148]="Erinnerungen von Gahz'rilla",[6149]="Unvergessene Onyxia",[6150]="Spinnenaugen von Sumpfauge",[6151]="Der Ansitzvater",[6152]="Horror des Flachwassers",[6153]="Stärke von Beledar",[6154]="Sir Alastair Reinfeuer",[6155]="Störende Stacheleber",[6156]="Todesflut",[6157]="Funglur",[6158]="Kristallkraft",[6159]="Stolz von Beledar",[6160]="Die Argentumprüfungen",[6161]="Faule Peons",[6162]="Ungebundene Beute",[6163]="In den Bergen...",[6164]="Zenns Aufträge",[6165]="Erste Klinge Grimskarn",[6166]="Exekutor Nizrek",[6167]="Talinhet",[6168]="Nablya",[6169]="Gong'tze der Flusshauer",[6170]="Zeeben und Zillix",[6171]="Seltsame Störung",[6172]="Ungebundene Beute",[6173]="Eine Klinge",[6174]="Juwel der Klippen",[6175]="Windgepeitschtes Säckchen",[6176]="Sir Finley Mrrgglton",[6177]="Verlorenes Andenken",[6178]="Hofsäckchen",[6179]="Vergessener Werkzeugkasten",[6181]="Versunkene Truhe",[6182]="Galans Edikt",[6183]="Jix'ak die Wahnsinnige",[6184]="Der Schleimkhan",[6185]="Ernter Qixt",[6186]="Umbraklauenmatra",[6187]="Titanenschalttafel",[6188]="Stein der Freien",[6189]="Wächter des Nordens",[6190]="Wächterin des Südens",[6191]="Ein Schädel auf einem Schild",[6192]="Achtung: Eingestürzter Tunnel",[6193]="Versunkenes Schild",[6194]="Wachsgetränktes Schild",[6195]="Abgenutztes Schild",[6196]="Letzter Flug der Zuverlässigkeit",[6197]="Ein zerlesenes Tagebuch",[6198]="Ein verwitterter Foliant",[6199]="Eine zerfledderte Notiz",[6200]="Ein Spähertagebuch",[6201]="Manische Neruberin",[6202]="Kah'teht",[6203]="Tiefenkriecher Tx'kesh",[6204]="Klingenwache der Kaheti",[6205]="Vergessener Schattenwerfer",[6206]="Verwitterter Schattenwerfer",[6207]="Vernachlässigter Schattenwerfer",[6208]="Erschöpfter Wasserelementar",[6209]="U'llort der freiwillige Exilant",[6210]="Irisierende Panzerkrabbe",[6211]="DEBUG Treasure Location",[6212]="Verlorene Mooswolle",[6214]="Aufgeblähter Schlucker",[6215]="Kereke",[6216]="Moderfaust",[6217]="Aqu'yinra",[6218]="Yoh'nath der Beender",[6219]="Yor'sith",[6220]="Bor'zal der Lauernde",[6221]="Aufgewühlte Erde",[6222]="Aszendent Vis'coxria",[6223]="Todeskreischerin Iken'tak",[6224]="Lionel",[6225]="Ankoanerchampion Utaari",[6226]="Utmoth der Gezeitendreher",[6227]="Gurl der Schmauser",[6228]="Hand von Azshara",[6229]="Zaniga der Fährtenleser",[6230]="Kiste der Irdenen",[6231]="Magische Schatztruhe",[6232]="Verfluchte Hacke",[6233]="Munderuts vergessener Vorrat",[6235]="Zurückgelassener Werkzeugkasten",[6236]="Einäugiger Thak",[6237]="Thaks Schatz",[6238]="Mooswollenblüte",[6239]="Rätselhafte Kugel",[6240]="Pilzkappe",[6241]="Kaja'Cola-Maschine",[6242]="Schatz des Hüters",[6243]="Elementargeode",[6244]="Kanalschildkröte von Dalaran",[6245]="Kanalschildkröte von Dalaran",[6246]="Kanalschildkröte von Dalaran",[6247]="Tor'go",[6248]="Nalo'xic",[6249]="Tengi die Kriegsmatrone",[6250]="Kiji der Stampfer",[6251]="Pterrordaxus",[6252]="Erdenwutfelsscher",[6253]="Erzmex Flammenbrecher",[6254]="Tiefenläuferhöhlenfürst",[6255]="Flammausweider Ignes",[6256]="Tiefenkern-Flammenhauer",[6257]="Mauernmalmer Min'cho",[6258]="Sturmlord Kao'dor",[6259]="Toaka der Entdecker",[6260]="Champion Or'sosh",[6261]="Kriegstreiberin Ogli",[6262]="Jadeperle",[6263]="Schatzhort der Arathi",[6264]="Ritualtruhe der Kobyss",[6265]="Tka'ktath",[6266]="Der Letzte",[6267]="Spiz'na die Verräterin",[6268]="Die rebellische Königin",[6269]="Vil'vim der Geistgräber",[6270]="Vin'ris der Verderber",[6271]="S'toth der Unersättliche",[6272]="Brann Bronzebarts Falle",[6273]="Koboldspitzhacke",[6274]="Schimmernde Opallilie",[6275]="Eingesponnener Schatz",[6276]="Spule des Schicksalswebers",[6277]="Unheimliche dunkle Truhe",[6278]="Sureki-Schließkassette",[6279]="Konzentrierte Schatten",[6280]="Gestörte Erde",[6281]="Nerubische Opfergaben",[6282]="Niffen-Schatz",[6283]="Bündel des vermissten Spähers",[6284]="Versperrter Zulauf",[6285]="Seidenumsponnene Vorräte",[6286]="Truhe des verstaubten Ausgrabungsleiters",[6287]="Erinnerungskiste",[6288]="Versteckte Schmuggelware",[6289]="Webereivorräte",[6290]="Eingeschlossener Schatz",[6291]="Nestei",[6292]="Erfülltes Glutbräu",[6293]="Eingesponnene Axt",[6294]="Haufen Abfall",[6295]="Gerüchtevermittler",[6296]="Gerüchtevermittler",[6297]="Informationsvermittler",[6298]="Unvergessener Lichkönig",[6299]="Gerüchtevermittler",[6300]="Gerüchtevermittler",[6301]="Gerüchtevermittler",[6302]="Gerüchtevermittler",[6303]="Gerüchtevermittler",[6304]="Gerüchtevermittler",[6305]="Gerüchtevermittler",[6306]="Gerüchtevermittler",[6307]="Gerüchtevermittler",[6308]="Gerüchtevermittler",[6309]="Oh neeiin! Die Kaulquappen!",[6310]="Ruf des Champions!",[6311]="Schaumblut und Seelenkocher",[6312]="Splitter von Gorribal",[6313]="Witwenkern",[6314]="Azeritmanifestation",[6315]="Herzsenger",[6316]="[TEMPLATE] SCHATZ",[6317]="Vergessenes Denkmal",[6318]="Vergessenes Denkmal",[6319]="Vergessenes Denkmal",[6320]="Vergessenes Denkmal",[6321]="Vergessenes Denkmal",[6322]="Vergessenes Denkmal",[6323]="Vergessenes Denkmal",[6324]="Vergessenes Denkmal",[6325]="Vergessenes Denkmal",[6326]="Kahetiausgrabung",[6327]="Kahetiausgrabung",[6328]="Kahetiausgrabung",[6329]="Kahetiausgrabung",[6330]="Kahetiausgrabung",[6331]="Kahetiausgrabung",[6332]="Kahetiausgrabung",[6333]="Kahetiausgrabung",[6334]="Kahetiausgrabung",[6335]="Kahetiausgrabung",[6336]="Kahetiausgrabung",[6337]="Kahetiausgrabung",[6338]="Weberattenschatz",[6339]="Weberattenschatz",[6340]="Weberattenschatz",[6341]="Weberattenschatz",[6342]="Weberattenschatz",[6343]="Weberattenschatz",[6344]="Weberattenschatz",[6345]="Weberattenschatz",[6346]="Weberattenschatz",[6347]="Weberattenschatz",[6348]="Weberattenschatz",[6349]="Weberattenschatz",[6350]="Eingesponnene Kreuzfahrer",[6351]="Verschmelzung der Schrecken",[6352]="Vesperdose des Hügelpinnenhofs",[6353]="Kleines Schweinchen",[6354]="Merkwürdiges Objekt",[6355]="Brandungsbrecher",[6356]="Durchnässter Unrat",[6357]="Verirrte Abgesandte",[6358]="Weltenseelenerinnerung",[6359]="Beledars Brut",[6360]="Anub'ikkaj",[6361]="Parasidius",[6362]="Aromawissenschaftlerin",[6363]="Reliquiar des Maschinenflüsterers",[6364]="In den Tiefen verlorenes Säckchen",[6366]="Gestörter Luchsschatz",[6367]="Caesper",[6368]="Caesper",[6369]="Luftreiniger",[6370]="Schmugglerschatz",[6371]="Dunkles Ritual",[6372]="Dunkles Ritual",[6373]="Meisterin der Lehren der Arathi",[6374]="Palawltars Kodex der dimensionalen Struktur",[6375]="Pflege und Ernährung des Kaiserluchses",[6376]="Richtlinien der Schattensperrstunde",[6377]="Beledar - Vision des Kaisers",[6378]="Das Lied von Renilash",[6379]="Das große Buch über die Idiome der Arathi",[6380]="Holzsammlung",[6381]="Verweilende Erinnerungen",[6382]="Versteckte Beute",[6383]="Umsponnene Kiste",[6385]="Aufgestellte Kampfvorräte",[6386]="Aufgestellter Windbändigerturm",[6387]="Aufgestelltes Fass der Erholung",[6388]="Weberattenschatz",[6389]="Weberattenschatz",[6390]="Weberattenschatz",[6391]="Weberattenschatz",[6392]="Weberattenschatz",[6393]="Weberattenschatz",[6394]="Weberattenschatz",[6395]="Weberattenschatz",[6396]="Weberattenschatz",[6397]="Weberattenschatz",[6398]="Weberattenschatz",[6399]="Weberattenschatz",[6400]="Vergessenes Denkmal",[6401]="Vergessenes Denkmal",[6402]="Vergessenes Denkmal",[6403]="Vergessenes Denkmal",[6404]="Vergessenes Denkmal",[6405]="Vergessenes Denkmal",[6406]="Vergessenes Denkmal",[6407]="Vergessenes Denkmal",[6408]="Vergessenes Denkmal",[6409]="Vergessenes Denkmal",[6410]="Vergessenes Denkmal",[6411]="Vergessenes Denkmal",[6413]="Kahetiausgrabung",[6414]="Kahetiausgrabung",[6415]="Kahetiausgrabung",[6416]="Kahetiausgrabung",[6417]="Kahetiausgrabung",[6418]="Kahetiausgrabung",[6419]="Kahetiausgrabung",[6420]="Kahetiausgrabung",[6421]="Kahetiausgrabung",[6422]="Kahetiausgrabung",[6423]="Kahetiausgrabung",[6424]="Kahetiausgrabung",[6425]="Eisenpulver der Irdenen",[6426]="Metallrahmen aus Dornogal",[6427]="Verstärkter Messbecher",[6428]="Gravierter Rührstab",[6429]="Geläutertes Wasser des Chemikers",[6430]="Geheiligter Mörser und Stößel",[6431]="Nerubisches Mischsalz",[6432]="Phiole der dunklen Apothekerin",[6433]="Uralter Amboss der Irdenen",[6434]="Hammer aus Dornogal",[6435]="Klemme des schallenden Hammers",[6436]="Meißel der Irdenen",[6437]="Schmiede der Heiligen Flamme",[6438]="Strahlende Zange",[6439]="Nerubische Schmiedeausrüstung",[6440]="Drahtbürste des Spinnlings",[6441]="Geschliffener Edelstein der Irdenen",[6442]="Silberrute aus Dornogal",[6443]="Rußbedeckte Kugel",[6444]="Belebter Verzauberungsstaub",[6445]="Essenz des Heiligen Feuers",[6446]="Verzauberte Arathischriftrolle",[6447]="Buch der dunklen Magie",[6448]="Leerensplitter",[6449]="Schraubenschlüssel des Felsingenieurs",[6450]="Brille aus Dornogal",[6451]="Inaktive Bergbaubombe",[6452]="Konstruktionspläne der Irdenen",[6453]="Heiliger Feuerwerksblindgänger",[6454]="Sicherheitshandschuhe der Arathi",[6455]="Verpuppte Mechanospinne",[6456]="Entleerter Giftbehälter",[6457]="Uralte Blume",[6458]="Gartensense aus Dornogal",[6459]="Grabgabel der Irdenen",[6460]="Messer des fungianischen Schlitzers",[6461]="Gartenschaufel der Arathi",[6462]="Kräuterschere der Arathi",[6463]="Gespinstumschlungener Lotus",[6464]="Schaufel des Tunnelgräbers",[6465]="Federkiel des Schreibers aus Dornogal",[6466]="Federhalter des Historikers",[6467]="Runische Schriftrolle",[6468]="Blaupigment der Irdenen",[6469]="Füllhalter des Informanten",[6470]="Gemeißelte Markierung des Kalligraphen",[6471]="Nerubische Texte",[6472]="Tintenfass des Giftmischers",[6473]="Behutsamer Juwelenhammer",[6474]="Edelsteinzange der Irdenen",[6475]="Gemeißelte Steinakte",[6476]="Feiner Bohrer des Juweliers",[6477]="Größenschablone der Arathi",[6478]="Vergrößerungsglas des Bibliothekars",[6479]="Kristall des Ritualzauberwirkers",[6480]="Bankblöcke der Neruber",[6481]="Verschnürungsgerät der Irdenen",[6482]="Flachmesser des Handwerkers aus Dornogal",[6483]="Unterirdische Abzieherverbindung",[6484]="Ahle der Irdenen",[6485]="Abkantersatz der Arathi",[6486]="Lederpolierer der Arathi",[6487]="Gerbhammer der Neruber",[6488]="Gekrümmtes Kürschnermesser der Neruber",[6489]="Hammer des irdenen Minenarbeiters",[6490]="Meißel aus Dornogal",[6491]="Schaufel des irdenen Ausgräbers",[6492]="Regenerierendes Erz",[6493]="Präzisionsbohrer der Arathi",[6494]="Ausgräber des frommen Archäologen",[6495]="Schwerer Spinnenquetscher",[6496]="Nerubische Minenlore",[6497]="Schnitzmesser aus Dornogal",[6498]="Balken des irdenen Arbeiters",[6499]="Abziehmesser des Kunsthandwerkers",[6500]="Ergiebiger Fungianergerbstoff",[6501]="Arathigerbstoff",[6502]="Schweifhobel des Arathihandwerkers",[6503]="Poliereisen der Neruber",[6504]="Panzerpolierer",[6505]="Trennmesser aus Dornogal",[6506]="Maßband der Irdenen",[6507]="Runenverzierte irdene Nadeln",[6508]="Schere des irdenen Nähers",[6509]="Rollschneider der Arathi",[6510]="Winkelmesser des königlichen Ausstatters",[6511]="Nerubische Steppdecke",[6512]="Nadelkissen der Neruber",[6513]="Verbreiterbrutstätte",[6516]="Schatzelementar",[6517]="Grabschlamm",[6518]="Archavon der Steinwächter",[6519]="Sha des Zorns",[6520]="Verdammniswandler",[6521]="Verweigerer von Mereldar",[6522]="Verweigerer von Mereldar",[6523]="Verweigerer von Mereldar",[6524]="Schlächterpanzer",[6525]="Ikir der Treibwoger",[6526]="Wrackwasser",[6527]="Gunnlod der Meeressäufer",[6528]="Splittsturm",[6529]="Grantmöwe",[6530]="Salzblut",[6531]="Geistmacher",[6532]="Toxischer Koloss",[6533]="Feldarbeitervorrat",[6534]="Alte verrottende Kiste",[6535]="Verlegte Vorräte",[6536]="Feldmesserkiste",[6537]="Krabbenfischervorräte",[6538]="Chromie",[6539]="Buddelstelle",[6540]="Dunkler Prophet Grshol",[6541]="Gerüchtevermittler",[6542]="Gerüchtevermittler",[6543]="Gerüchtevermittler",[6544]="Gerüchtevermittler",[6545]="Gerüchtevermittler",[6546]="Gerüchtevermittler",[6547]="Gerüchtevermittler",[6548]="Gerüchtevermittler",[6549]="Gerüchtevermittler",[6550]="Gerüchtevermittler",[6551]="Gerüchtevermittler",[6552]="Gerüchtevermittler",[6553]="Gerüchtevermittler",[6554]="Gerüchtevermittler",[6555]="Gerüchtevermittler",[6556]="Gerüchtevermittler",[6557]="Gerüchtevermittler",[6558]="Gerüchtevermittler",[6559]="Gerüchtevermittler",[6560]="Gerüchtevermittler",[6561]="Gerüchtevermittler",[6562]="Gerüchtevermittler",[6563]="Gerüchtevermittler",[6564]="Gerüchtevermittler",[6565]="Uhrwerkschrottsammler",[6566]="Schlüsselflamme von Blüte des Lichts",[6567]="Schlüsselflamme des Surrenden Felds",[6568]="Schlüsselflamme des Dämmerhöhenackers",[6569]="Schlüsselflamme des Stillsteintümpels",[6570]="Schlüsselflamme der Fackelscheinmine",[6571]="Schlüsselflamme der Verblassten Küste",[6572]="Schlüsselflamme von Trübsand",[6573]="Wiederbelebungsposition",[6574]="Wiederbelebungsposition",[6575]="Schlüsselflamme der Fungusfelder",[6576]="[TEMPLATE] Creature Name",[6577]="Plankenmeisterin Blaubauch",[6579]="Schildkrötendank",[6580]="Chefkoch Köderplatte",[6581]="Korallenweberin Calliso",[6582]="Siris Seeskorpion",[6583]="Die Morgenbringer",[6584]="Die Morgenbringer",[6585]="Ruhmreicher Rüstmeister",[6586]="Ruhmreicher Rüstmeister",[6587]="Ruhmreicher Rüstmeister",[6588]="Ruhmreicher Rüstmeister",[6589]="Ruhmreicher Rüstmeister",[6590]="Asbjörn der Blutgetränkte",[6591]="Rastloser Odek",[6592]="Kodexverzerrung",[6593]="Flüchtige Agentin Lathyd",[6594]="Die Müllwand",[6595]="Faulpelz der Schlaue",[6596]="Oberster Vorarbeiter Gutso",[6597]="Fliegerjunge Schnauzi",[6598]="Schrottschnabel",[6599]="Hof der Ratten",[6600]="Tally Doppelsprech",[6601]="V.V. Ganswerth",[6602]="Womp",[6603]="S.A.A.",[6604]="Nitro",[6605]="Lolli Händehoch",[6606]="Rußdocht",[6607]="Hais Hunger",[6608]="Verschlingerangriff: Die Oase",[6609]="Schlucks Weitsicht",[6610]="Stalagnarok",[6611]="Überquellender Müllcontainer",[6612]="Glänzende Mülltonne",[6613]="Fällmittel der Düsternisverschmolzenen",[6614]="Fällmittel der Düsternisverschmolzenen",[6615]="Gewitterkralle",[6616]="Salzstamm",[6617]="Zek'ul der Schiffszerstörer",[6618]="Nickelrücken",[6619]="Ksvir der Vergessene",[6620]="Bot",[6621]="Gurumurgel des Abgrunds",[6622]="Roboter (Bewusstlos)",[6624]="Muffs Selbstschließer",[6625]="Muffs Selbstschließer",[6626]="Muffs Selbstschließer",[6627]="Muffs Selbstschließer",[6628]="Muffs Selbstschließer",[6629]="Sha'ryth der Verfluchte",[6630]="Schlund der Sande",[6631]="Korgorath der Verheerer",[6632]="Mampfadar",[6633]="Morgil die Netherbrut",[6634]="Der Nachthäscher",[6635]="Orith der Schreckliche",[6636]="Ixthal der niemals Blinzelnde",[6637]="Schattengroll",[6638]="Prototyp Mk-V",[6639]="Klagegeist der Ödnis",[6640]="Ödnispirscher",[6641]="Urmag",[6642]="Xarran",[6643]="Zurückgelassene Werkzeugkiste",[6644]="Papas langverlorener Putter",[6645]="Nicht überwachte Entnahme",[6646]="Kräftige Komposition",[6648]="Der Abfluss",[6649]="Der Versunkene Hort",[6650]="Schauderhöhle",[6651]="Besonders hübsche Lampe",[6652]="Erzwungene \"\"Quest\"\"-Behandlung für Fundbürotruhe",[6653]="Verlassener Floßmingo",[6654]="Ungeöffnete Kaltgetränke",[6655]="Trickkartenset",[6656]="Haltegriff",[6657]="Nicht explodiertes Feuerwerk",[6658]="Inaktiver Zünder?",[6659]="Schatz des Seefahrers",[6660]="Azuregos",[6661]="Lord Kazzak",[6662]="Lethon",[6663]="Smariss",[6664]="Taerar",[6665]="Ysondre",[6666]="Splittersang",[6667]="Schrottmampfer",[6668]="Voltschlag der Geladene",[6669]="Runenverzierte Sturmtruhe",[6670]="Glyphe 'Hieb'",[6671]="Geschwärzter Würfel",[6672]="Explodierter Zünder",[6673]="Zurückgelassene Schließkassette",[6674]="Leicht verbeultes Gepäck",[6675]="Verlorenes Glockenspiel",[6676]="Sandgegerbter Kasten",[6677]="Feuerwerkhut",[6678]="Einsame Wanne",[6679]="Verdächtiges Buch",[6680]="Primula Kurbelwelle",[6681]="Geschenk der Brüder",[6682]="Flackernde Laterne",[6683]="Vorratstruhe der Bilgeratten",[6684]="Runenversiegelte Kassette",[6685]="Geplünderte Kiste der Irdenen",[6686]="Profitabler Standort",[6687]="S.C.H.R.O.T.T.-Haufen",[6689]="M.A.G.N.O.",[6690]="Hort des Ödnisbewohners",[6691]="Prüfer des Bilgewasserkartells",[6692]="Gestürztes Paket",[6693]="Gestürztes Paket",[6694]="Noggenfogger-Nervensäge",[6695]="Zertrümmerte Kristalle",[6696]="Steißknochen",[6697]="Grob genähter Beutel",[6698]="Profit!",[6699]="Verlegte Kuriosität",[6700]="Müll des Garbagio",[6701]="Vergrabenes Buch",[6702]="Uralter Kasten",[6703]="Verzauberter Besen",[6704]="Schmuddeliger Zeithüter",[6705]="Verschlingerangriff: Biokuppel: Primus",[6706]="Glas",[6707]="Verschlingerangriff: Das Atrium",[6708]="Verschlingerangriff: Tazavesh",[6709]="Postraumverteiler",[6710]="Noggenfogger-Nervensäge",[6711]="Magnoschrotter 9000",[6712]="Postraumverteiler",[6713]="Zusammengeknüllter Bauplan",[6714]="Massenvernichtungsprototyp",[6715]="Piet der Charmeur",[6716]="Vynnie Samophlangus",[6717]="Madame Colada",[6718]="Freg",[6719]="Tiefenkönig Grobrosh",[6720]="Roxarix der Tunnelbohrer",[6721]="Geomant Keeri",[6722]="Gewaltiger Kaja'mentar",[6723]="Zuchtmeister Zendu",[6724]="Ixthars Lieblingskristall",[6725]="Sthaarbs der Unaufgewühlte",[6726]="Phasenverlorener Schatz",[6727]="Phasendiebin Tezra",[6728]="Großschwert des Ödniswandlers",[6729]="Phasenverlorener Schatz",[6730]="Schatz des Seefahrers",[6731]="Piratenhändler",[6732]="Ein bedrohlicher Brief",[6733]="Verlegter Arbeitsauftrag",[6734]="Sicherheitsleitfaden für Extraktionsbohrer X-78",[6735]="Sicherheitshandbuch für Raketenbohrer",[6736]="Zweite Hälfte von Noggenfoggers Tagebuch",[6737]="Erste Hälfte von Noggenfoggers Tagebuch",[6738]="Gallywix' Notizen",[6739]="Skramasax des Steinmetzes",[6740]="Arbeitsstiefel nach Aschenwindauftrag",[6741]="Beil des Holzfällers aus Kul Tiras",[6742]="Eisenspitzhacke",[6743]="Pfrilles Lieblingsklinge",[6744]="Verbeulte Nagawaffe",[6745]="Zerrissene Bilgerattenkappe",[6746]="Blutbedeckte Waffe der Blutgischt",[6747]="Seepockenverkrustete Truhe",[6748]="Sprengstoff der Düsternisverschmolzenen",[6750]="Wache\"\" von Silbermond",[6751]="Leerensturmriss",[6752]="Schrottmampfer",[6753]="Voltschlag der Geladene",[6754]="Nerathor",[6755]="Berg die Zauberfaust",[6756]="Rätselhafte Kugel",[6757]="S.C.H.R.O.T.T.-Haufen",[6758]="Belath Dämmerklinge",[6759]="Verkäufer",[6760]="Schmuddeliger Zeithüter",[6761]="Corla",[6762]="Lehrensuche",[6763]="[TEMPLATE] [Object Name]",[6764]="Leerengesättigte Hydra",[6765]="Bösartiger Hasssplitter",[6766]="Astrales Taschenlager",[6767]="Mittlerkasse",[6768]="Phasenverlorenes Taschenlager",[6769]="Midsummer Bonfire Map POI Test - JZB",[6770]="Xy'vox der Verrenkte",[6771]="Splitterimpuls",[6772]="Xy'vox der Verrenkte",[6773]="Hohlfluch",[6774]="Schmuddler",[6777]="Test",[6778]="Auge der Gier",[6779]="Schreckenslord der verlorenen Legion",[6780]="Silbermondgast",[6781]="Silbermondgast",[6783]="Überfluss",[6784]="Phasenleiter",[6785]="Thalassisches Kürschnermesser",[6786]="Kürschnermesser der Amani",[6787]="Gerböl der Sin'dorei",[6788]="Gerböl der Amani",[6789]="Leerensturmlederprobe",[6790]="Urtümlicher Balg",[6791]="Kürschnermesser des Kaders",[6792]="Lichtblütenbefallener Balg",[6793]="Abdeckkamm des Kunsthandwerkers",[6794]="Besonders bezauberndes Tischtuch",[6795]="Satinzierkissen",[6796]="Buch der Sin'dorei-Nähkunst",[6797]="Hölzernes Webschwert",[6798]="Lineal des Sin'dorei-Ausstatters",[6799]="Ein richtig schöner Vorhang",[6800]="Ein Stofftier eines Kindes",[6801]="Ersatzexpeditionsfackel",[6802]="Sternenmetallvorkommen",[6803]="Meißel des Amaniexperten",[6804]="Schimmernde Leerenperle",[6805]="Bündel der Schmuckstücke des Gerbers",[6806]="Prestigevoll gegerbtes Leder",[6807]="Astrales Lederverarbeitungsmesser",[6808]="Amanilederwerkzeug",[6809]="Edelsteinschleifer der Sin'dorei",[6810]="Astrale Edelsteinzange",[6811]="Antiker Seelenedelstein",[6812]="Zerbrochenes Glas",[6813]="Markierung des unerschrockenen Entdeckers",[6814]="Ersatztinte",[6815]="Ledergebundene Techniken",[6816]="Leerenberührter Federkiel",[6817]="Praktischer Schraubenschlüssel",[6818]="Was tun",[6819]="Offline-Helferbot",[6820]="Astrale Sturmzwinge",[6821]="Flinker Pylon",[6822]="Handbuch der Fehler und Missgeschicke",[6823]="Miniaturisiertes Transportboot",[6824]="Des einen Ingenieurs Schrott",[6825]="Verzauberkunstrute der Sin'dorei",[6826]="Loageweihter Staub",[6827]="Urzeitliche Essenzkugel",[6828]="Entropischer Splitter",[6829]="Immerbrennender Sonnenpartikel",[6830]="Reiner Leerenkristall",[6831]="Verzauberte Sonnenfeuerseide",[6832]="Verzauberte Amanimaske",[6833]="Silbermondschmiedehammer",[6834]="Schmiedestreitkolben des Sin'dorei-Meisters",[6835]="Schwert des Rutaani-Florahüters",[6836]="Leerensturmverteidigungsspeer",[6837]="Spickzettel zu Metallarbeiten",[6838]="Sorgfältig gehämmerter Speer",[6839]="Silbermondschmiedeset",[6840]="Dekonstruierte Schmiedetechniken",[6841]="Fehlgeschlagenes Experiment",[6842]="Makelloser Trank",[6843]="Abgemessene Kelle",[6844]="Frisch gepflückte Friedensblume",[6845]="Phiole der Kuriositäten aus Zul'Aman",[6846]="Phiole der Kuriositäten der Wurzellande",[6847]="Phiole der Kuriositäten des Leerensturms",[6848]="Phiole der Kuriositäten des Immersangwalds",[6849]="Blühende Knospe",[6850]="Schwingende Sichel des Ernters",[6851]="Einfacher Blattschneider",[6852]="Lichtblütenwurzel",[6853]="Ein Spaten",[6854]="Sichel des Ernters",[6855]="Seltsamer Lotus",[6856]="Pflanzschaufel",[6857]="Massive Erzstanzer",[6858]="Verlorene Leerensturmsichel",[6859]="Glücksbringer des Höhlenforschers",[6860]="Bergmannsleitfaden für den Leerensturm",[6861]="Bedachter Auftrag des Kunsthandwerkers",[6862]="Lederverarbeitungsmesser der Haranir",[6863]="Lederverarbeitungsschlägel der Haranir",[6864]="Muster: Jenseits der Leere",[6865]="Schlecht gerundete Phiole",[6866]="Zweifachfunktionslupe",[6867]="Spekulativer Leerensturmkristall",[6868]="Meisterwerkmeißel der Sin'dorei",[6869]="Federkiel des Komponisten",[6870]="Stift des Komponisten",[6871]="Halbherzige Techniken",[6872]="Übriges Rotdornpigment",[6873]="Teleporter",[6874]="Phasenriss",[6875]="Dissident Glevenpelz",[6876]="Dissident Eidland",[6877]="Flüsterin Kampfeyd",[6878]="Flüsterin Hügelpinne",[6879]="Dissident Eifermacht",[6880]="Dissidentin Schweifpfad",[6881]="Flüsterer Tapferfeste",[6882]="Flüsterin Kriegidittel",[6883]="Dissidentin Burgzorn",[6884]="Dissident Truhsilber",[6885]="Flüsterer Belagerweise",[6886]="Flüsterin Kriegschaous",[6887]="[TEMPLATE] [Object Name]",[6888]="[TEMPLATE] [Object Name]",[6889]="Astraler leerengeschmiedeter Behälter",[6890]="Akil'zons Geschwindigkeit",[6891]="Lila Torf",[6892]="Geisterschlachttruhe",[6893]="Arkanahetzer So'zer",[6895]="Nekroverhexer Raz'ka",[6896]="Die Schnappgeißel",[6897]="Schädelmalmer Harak",[6898]="Ältester Eichenkralle",[6899]="Tiefengeborener Aalementar",[6900]="Lichtholzbohrer",[6902]="Entfesseltes Sturmgewitter",[6903]="Stachelkragen",[6904]="Oophaga",[6905]="Winziges Ungeziefer",[6906]="Leerenberührtes Krustentier",[6907]="Der verschlingende Invasor",[6909]="Waffenvorrat",[6910]="Bombenhaufen",[6911]="Spitzel von Silbermond",[6912]="Ereignis",[6913]="Arkanahetzer So'zer",[6914]="Schmuddler",[6915]="Hohlfluch",[6916]="Splitterimpuls",[6917]="Lila Torf",[6918]="Ruhmrüstmeister",[6919]="Lichtdurchströmtes Spaltbeil",[6920]="Speer der gefallenen Erinnerungen",[6921]="Efrats vergessenes Bollwerk",[6922]="Versteinerter Ast von Janaa",[6923]="Sufaadische Skifflaterne",[6924]="Manaschmiedentranslokator",[6925]="Talwar der Goldenen Wache",[6926]="Zermalmer der Schattenwache",[6927]="Korgoraths Kralle",[6928]="Salm der Flamme",[6929]="Lauer",[6930]="Nebelwinter",[6931]="Verlegter Foliant",[6932]="Leerenriss",[6933]="Türsteuerkonsole",[6934]="Ruz'avalts wertvoller Besitz",[6935]="[DEPRECATED]",[6936]="[Object Name]",[6937]="Schatz des wohlwollenden Kriegers",[6938]="Zurückgelassener Ritualschädel",[6939]="Köder und Angelzubehör",[6940]="Vergrabene Beute",[6941]="Mrruks miserabler Schatz",[6942]="Geheime Formel",[6943]="Verlassenes Nest",[6944]="Stumpfhauervorräte",[6945]="Vergessenes Leckereienglas",[6946]="Von Bären geplünderter Vorrat",[6947]="[DEPRECATED]",[6948]="Zurückgelassener Ritualschädel",[6949]="Sundereth der Rufer",[6950]="Magister Umbric",[6951]="Runenstein",[6952]="Domanaar",[6953]="Domanaar",[6954]="Runenstein",[6955]="Runenstein",[6957]="Leerenfass",[6958]="Abgabe bei der Allianz",[6959]="Runenstein",[6960]="Abgabe bei der Horde",[6961]="Territoriale Leerensense",[6962]="Tremora",[6963]="Eruundi",[6964]="Nachtbrut",[6965]="Kriegsgleve des verwegenen Jägers",[6966]="Prototyppaket und Portopresse des P.O.S.T.-Meisters",[6967]="Phasenklinge der Leerenmärsche",[6968]="Klingengewehr des uneingeschränkten Momentums",[6971]="Der verfaulende Diamantrücken",[6972]="Ash'an der Ermächtigte",[6973]="[DEPRECATED]",[6974]="Lachsteich",[6975]="Mittlerkasse",[6976]="Phasenverlorene Kasse",[6977]="Mrrlokk",[6978]="Ausgehöhltes Totem",[6979]="[DEPRECATED]",[6980]="Malek'ta",[6981]="Heka'tamos",[6982]="[TEMPLATE] [Object Name]",[6983]="Portal zur Madenstadt",[6984]="Portal zu den Eiskalten Frostlanden",[6985]="Portal zum Lavalabyrinth",[6986]="Portal zum Giftwald",[6987]="Portal zum Blutzirkus",[6988]="Leerenzelotin Devinda",[6989]="Violetter Rankenschnapper",[6990]="Irisrindenstampfer",[6991]="Efeudornenschwanz",[6992]="Wächter des Unkrauts",[6994]="Asira Dämmerschlächter",[6995]="Fäulnisstrahl",[6996]="Erzbischof Benedictus",[6997]="Ix der Blutgefallene",[6998]="Kommandant Ix'vaarha",[6999]="Leerenbesudelte Überreste",[7000]="Verlorene Schattenschrittvorräte",[7001]="Ez'Haadosh die Liminalität",[7002]="Gehetzter Falkenschreiter",[7003]="Saligrum der Beobachter",[7004]="Sharfadi",[7005]="Gustavan",[7006]="Spiegelzwicker",[7007]="Rotauge der Schädelbeißer",[7008]="Nedrand der Augenschlinger",[7009]="Leerenklaue Hexathor",[7010]="Truhe des Fachmanns",[7011]="Magister Sonnenbrecher",[7012]="Ziel 2",[7013]="Ziel 3",[7014]="Ziel 4",[7015]="Ziel 5",[7016]="Ziel 6",[7017]="Ziel 7",[7018]="Ziel 8",[7019]="Jo'zolo der Brecher",[7020]="Ziel 10",[7021]="Ziel 11",[7022]="Ziel 12",[7023]="Ziel 13",[7024]="Ziel 14",[7025]="Ziel 15",[7026]="Ziel 16",[7027]="Ziel 17",[7028]="Ziel 18",[7029]="Ziel 19",[7030]="Ziel 20",[7031]="Exekutor Kaenius",[7032]="Ziel 22",[7033]="Ziel 23",[7034]="Ziel 24",[7035]="Ziel 25",[7036]="Ziel 26",[7037]="Ziel 27",[7038]="Ziel 28",[7039]="Ziel 29",[7040]="Ziel 30",[7041]="Blubbernder Farbtopf",[7042]="Scharfrichterin Lynthelma",[7043]="T'aavihan der Ungebundene",[7044]="Vergessenes Versteck der Amani",[7045]="Graviertes Ruder",[7046]="Kriegsfürstin Hlaka",[7047]="Hexfürst O'tom",[7048]="Schattenjäger Jun'tilo",[7049]="Überfluss",[7050]="Ziel 2",[7051]="Ziel 3",[7052]="Ziel 4",[7053]="Ziel 5",[7054]="Ziel 6",[7055]="Ziel 7",[7056]="Ziel 8",[7057]="Jo'zolo der Brecher",[7058]="Ziel 10",[7059]="Ziel 11",[7060]="Ziel 12",[7061]="Ziel 13",[7062]="Ziel 14",[7063]="Ziel 15",[7064]="Ziel 16",[7065]="Ziel 17",[7066]="Ziel 18",[7067]="Ziel 19",[7068]="Ziel 20",[7069]="Exekutor Kaenius",[7070]="Ziel 22",[7071]="Ziel 23",[7072]="Ziel 24",[7073]="Ziel 25",[7074]="Ziel 26",[7075]="Ziel 27",[7076]="Ziel 28",[7077]="Ziel 29",[7078]="Ziel 30",[7079]="Magisterrenegat",[7080]="Magisterrenegat",[7081]="Ziel 2",[7082]="Ziel 3",[7083]="Ziel 4",[7084]="Ziel 5",[7085]="Ziel 6",[7086]="Ziel 7",[7087]="Ziel 8",[7088]="Jo'zolo der Brecher",[7089]="Ziel 10",[7090]="Ziel 11",[7091]="Ziel 12",[7092]="Ziel 13",[7093]="Ziel 14",[7094]="Ziel 15",[7095]="Ziel 16",[7096]="Ziel 17",[7097]="Ziel 18",[7098]="Ziel 19",[7099]="Ziel 20",[7100]="Exekutor Kaenius",[7101]="Ziel 22",[7102]="Ziel 23",[7103]="Ziel 24",[7104]="Ziel 25",[7105]="Ziel 26",[7106]="Ziel 27",[7107]="Ziel 28",[7108]="Ziel 29",[7109]="Ziel 30",[7110]="Überfluss",[7111]="Wahnsinniger Minenwall",[7112]="Erfüllter Minenschmetter",[7113]="Entfesselter Minenrohling",[7114]="Überfluss",[7115]="Portalstein",[7116]="Vorrat des Weisen",[7117]="Wilderer Rav'ik",[7118]="Ein Buch mit Eselsohren",[7119]="Mysteriöses Notizbuch",[7120]="Multiverselle Energiedynamik und das Schar-Paradoxon",[7121]="Ba'keys Rezepte für aromatische Mittlerkekse",[7122]="Von der Rache in die Leere",[7123]="Die Facetten von K'aresh",[7124]="Münzen: Ein Eid",[7125]="Ich bin die Leere selbst!",[7126]="Selenar Sonnenscheu",[7127]="Geologisches Feldtagebuch",[7128]="Kontrollliste für kleine Freuden",[7129]="Nullspirale",[7130]="Runenstein",[7131]="Antigravitationsbereich",[7132]="Ruhmrüstmeister",[7133]="Der oft Gebrochene",[7135]="Valeera Sanguinar",[7136]="Höllenbestie der verlorenen Legion",[7137]="Höllenbestie der Endzeit",[7138]="Abysschlick",[7139]="Rhazul",[7140]="Leerenseher Orivane",[7141]="Gedenkplakette",[7142]="Schwarzkern",[7143]="Aufsteigendes Tor",[7144]="Absteigendes Tor",[7145]="Absteigendes Tor",[7146]="Aufsteigendes Tor",[7147]="Sturmarionvorräte",[7148]="Sturmarionvorräte",[7149]="Astrales Werkzeugregal",[7152]="Apfelfass",[7153]="Nahrungsvorräte",[7154]="Beerenbusch",[7155]="Tropfender Schatten",[7156]="Chironex",[7157]="Ha'kalawe",[7158]="Weitkappe der Wahrheitssager",[7159]="Königin Peitschenzunge",[7160]="Interessantes Objekt",[7161]="Chlorokyll",[7162]="Stubbe",[7163]="Serrasa",[7164]="Gedankenfäule",[7165]="Dracaena",[7166]="Baumkrone",[7167]="Oro'ohna",[7168]="Petrosaurus",[7169]="Vidious",[7170]="Ziadan",[7171]="Ahl'ua'huhi",[7172]="Annulus der Weltenerschütterer",[7173]="Leuchtende Motte",[7174]="Angriff der Leere",[7175]="Leuchtende Motte",[7176]="Leuchtende Motte",[7177]="Leuchtende Motte",[7178]="Leuchtende Motte",[7179]="Leuchtende Motte",[7180]="Leuchtende Motte",[7181]="Leuchtende Motte",[7182]="Leuchtende Motte",[7183]="Leuchtende Motte",[7184]="Leuchtende Motte",[7185]="Leuchtende Motte",[7186]="Leuchtende Motte",[7187]="Leuchtende Motte",[7188]="Leuchtende Motte",[7189]="Leuchtende Motte",[7190]="Leuchtende Motte",[7191]="Leuchtende Motte",[7192]="Leuchtende Motte",[7193]="Leuchtende Motte",[7194]="Leuchtende Motte",[7195]="Leuchtende Motte",[7196]="Leuchtende Motte",[7197]="Leuchtende Motte",[7198]="Leuchtende Motte",[7199]="Leuchtende Motte",[7200]="Leuchtende Motte",[7201]="Leuchtende Motte",[7202]="Leuchtende Motte",[7203]="Leuchtende Motte",[7204]="Leuchtende Motte",[7205]="Leuchtende Motte",[7206]="Leuchtende Motte",[7207]="Leuchtende Motte",[7208]="Leuchtende Motte",[7209]="Leuchtende Motte",[7210]="Leuchtende Motte",[7211]="Leuchtende Motte",[7212]="Leuchtende Motte",[7213]="Leuchtende Motte",[7214]="Leuchtende Motte",[7215]="Leuchtende Motte",[7216]="Leuchtende Motte",[7217]="Leuchtende Motte",[7218]="Leuchtende Motte",[7219]="Leuchtende Motte",[7220]="Leuchtende Motte",[7221]="Leuchtende Motte",[7222]="Leuchtende Motte",[7223]="Leuchtende Motte",[7224]="Leuchtende Motte",[7225]="Leuchtende Motte",[7226]="Leuchtende Motte",[7227]="Leuchtende Motte",[7228]="Leuchtende Motte",[7229]="Leuchtende Motte",[7230]="Leuchtende Motte",[7231]="Leuchtende Motte",[7232]="Leuchtende Motte",[7233]="Leuchtende Motte",[7234]="Leuchtende Motte",[7235]="Leuchtende Motte",[7236]="Leuchtende Motte",[7237]="Leuchtende Motte",[7238]="Leuchtende Motte",[7239]="Leuchtende Motte",[7240]="Leuchtende Motte",[7241]="Leuchtende Motte",[7242]="Leuchtende Motte",[7243]="Leuchtende Motte",[7244]="Leuchtende Motte",[7245]="Leuchtende Motte",[7246]="Leuchtende Motte",[7247]="Leuchtende Motte",[7248]="Leuchtende Motte",[7249]="Leuchtende Motte",[7250]="Leuchtende Motte",[7251]="Leuchtende Motte",[7252]="Leuchtende Motte",[7253]="Leuchtende Motte",[7254]="Leuchtende Motte",[7255]="Leuchtende Motte",[7256]="Leuchtende Motte",[7257]="Leuchtende Motte",[7258]="Leuchtende Motte",[7259]="Leuchtende Motte",[7260]="Leuchtende Motte",[7261]="Leuchtende Motte",[7262]="Leuchtende Motte",[7263]="Leuchtende Motte",[7264]="Leuchtende Motte",[7265]="Leuchtende Motte",[7266]="Leuchtende Motte",[7267]="Leuchtende Motte",[7268]="Leuchtende Motte",[7269]="Leuchtende Motte",[7270]="Leuchtende Motte",[7271]="Leuchtende Motte",[7272]="Leuchtende Motte",[7273]="Leuchtende Motte",[7274]="Leuchtende Motte",[7275]="Leuchtende Motte",[7276]="Leuchtende Motte",[7277]="Leuchtende Motte",[7278]="Leuchtende Motte",[7279]="Leuchtende Motte",[7280]="Leuchtende Motte",[7281]="Leuchtende Motte",[7282]="Leuchtende Motte",[7283]="Leuchtende Motte",[7284]="Leuchtende Motte",[7285]="Leuchtende Motte",[7286]="Leuchtende Motte",[7287]="Leuchtende Motte",[7288]="Leuchtende Motte",[7289]="Leuchtende Motte",[7290]="Leuchtende Motte",[7291]="Leuchtende Motte",[7292]="Leuchtende Motte",[7293]="Leuchtende Motte",[7294]="Aufgeblähter Schnappdrache",[7295]="Schatzdundun",[7296]="Altar des Überflusses",[7297]="Regen des Überflusses",[7298]="Korallenreißer",[7299]="Cre'van",[7300]="Schlafende Lichtblütenhydra",[7301]="Lady Liminus",[7302]="Wellenzwick",[7303]="Verirrter Wächter",[7304]="Banuran",[7305]="Böser Zed",[7306]="Terrinor",[7307]="Ruhmrüstmeister",[7308]="Säckchen des abgestürzten Pilzspringers",[7309]="Brennender Zweig des Weltenbaumes",[7310]="Astrales Feuer",[7311]="Kampfpreis des Sporenherrschers",[7312]="Verlorener Malpinsel der Archäologischen Akademie",[7313]="Kemets köchelnder Kessel",[7314]="Angriff der Leere",[7315]="Hängender Kürbis",[7316]="Bemalte Flasche",[7317]="Fungushüllentontopf",[7318]="Knospendes Fass",[7319]="Dornenumwickelte Kiste",[7320]="Leaf-Wrapped Package",[7321]="Fungushüllentruhe",[7322]="Dornentruhe",[7323]="Blütendornentruhe",[7324]="Arkane Aufladung",[7325]="Tarhu die Plünderin",[7327]="Ve'nari",[7328]="Steinbruchlager",[7329]="Trainingslager",[7330]="Steinbruchlager",[7331]="Versunkener Schatz",[7333]="Verbündete Streitkräfte",[7335]="Gefunden!",[7336]="Säckchen der Geisterpfoten",[7337]="Zwielichtmunition",[7338]="Maisaraunheilsgefäß",[7339]="Reinsteinvorräte",[7340]="Stimme der Finsternis",[7341]="Gefangener Bleichborkentroll",[7342]="Versteckte Singularitätsvorräte",[7343]="Mysteriöses Gefäß der Domanaar",[7344]="Steinbottich",[7345]="Kernzugriffskonsole",[7346]="Manazitleitung",[7347]="Vantazitleitung",[7348]="Riesenwundertüte",[7349]="Schäbiger Vorrat",[7350]="Vorräte des Tiefenforschers",[7351]="Geschenk des Kreislaufs",[7352]="Verderbte Kreatur",[7353]="Dunkler Obelisk",[7354]="Leutnant der Domanaar",[7355]="Letztes Gelege von Predaxas",[7356]="Dämonisches Tor",[7357]="Abbild von Astalor Blutschwur",[7359]="Vergessene Oubliette",[7360]="Blutiger Sack",[7361]="Brutmutter Shu'malis",[7362]="Flaches Grab",[7363]="Wächter des Unkrauts",[7364]="Antiker Siegelring des Adligen",[7365]="Dreifach verriegelte Truhe",[7366]="Verlorener Köcher des Weltenwanderers",[7367]="Halbverdaute Eingeweide",[7368]="Köcher des erschlagenen Spähers",[7369]="Wey'nans Wehklagen: Ein Funke der Hoffnung",[7370]="Wey'nans Wehklagen: Die Jagd nach Sinn",[7371]="Wey'nans Wehklagen: Das kann nicht alles sein",[7372]="Echos unserer Vergangenheit: Schwindende Geschichte",[7373]="Echos unserer Vergangenheit: Alnstaub",[7374]="Echos unserer Vergangenheit: Gefährliche Erinnerungen",[7375]="Der Pfad des Suchers: Aln'haras Ruf",[7376]="Der Pfad des Suchers: Die Suche nach Frieden",[7377]="Der Pfad des Suchers: Mission ohne Ende",[7378]="Worte von Obayo: Die Flamme",[7379]="Worte von Obayo: Der Riss",[7380]="Worte von Obayo: Die Stille",[7381]="Im Dienst des Landes: Der Konflikt",[7382]="Im Dienst des Landes: Der Plan",[7383]="Im Dienst des Landes: Der Kreislauf",[7384]="Die Wege der Wurzeln: Dienen",[7385]="Die Wege der Wurzeln: Wachsen",[7386]="Die Wege der Wurzeln: Stutzen",[7387]="Awe'ohnas Pfad: Fragen",[7389]="Awe'ohnas Pfad: Antworten",[7390]="Awe'ohnas Pfad: Die Wiege",[7391]="Weggeworfener Energiespeer",[7392]="Exaliburn",[7393]="Zitterndes Ei",[7394]="Versiegelter Kürbis",[7395]="Geschenk des Phönix",[7396]="Dämmerbrand",[7397]="Steckender Speer",[7398]="Verblasstes Wandbild",[7399]="Fehlerhaftes Konstrukt",[7400]="Uralter Mondrunenstein",[7401]="Heruntergekommenes Wandbild",[7402]="Vergessenes Wandbild",[7403]="Eine zerfranste Schriftrolle",[7404]="Dame Blutfang",[7405]="Wie man Falkenschreiter hält: Ungekürzte Fassung",[7406]="Schrein von Dath'Remar",[7407]="Mirvedas Notizen",[7408]="Weltliche Forschung",[7409]="Unvollendetes Notenblatt",[7410]="Seltsamer Kessel",[7411]="Sporenbewachsene Truhe",[7416]="Seelenverbindung",[7418]="Heimtückische Truhe",[7419]="Versiegelte Beute der Zwielichtklinge",[7422]="Gallenschlund der Unersättliche",[7423]="Interessantes Objekt",[7424]="Vergessene Tinte und Feder",[7426]="Rabengerus",[7428]="Far'thana die Wahnsinnige",[7429]="Vergoldete Armillarsphäre",[7430]="Quallenkönigin",[7431]="Lirath",[7432]="Aeonelle Schwarzstern",[7433]="Verderben des Ekelbluts",[7434]="Lotus Dunkelblüte",[7435]="Rakshur der Knochenmahler",[7436]="Schreimaxa die Matriarchin",[7437]="Horsttruhe",[7438]="Toter Briefkasten",[7439]="Verschmolzenes Licht",[7440]="Vorrat des Waldläufers",[7441]="Stellarvorrat",[7442]="Hardin Stahllocke",[7443]="Geringe verdichtende Pein",[7444]="Große verdichtende Pein",[7445]="Gar'chak Schädelspalter",[7446]="Schützendes Räucherwerk",[7447]="Bündel des Spähers",[7448]="Leerenrüstung",[7449]="Uralte Schrifttafel",[7450]="Zurückgelassenes Teleskop",[7451]="Zerfledderte Seite",[7452]="Schattenjochharnisch",[7455]="Vergessene Truhe eines Forschers",[7456]="Interessantes Objekt",[7457]="Saroniterz",[7458]="Saroniterz",[7459]="Lagerfeuer der Ren'dorei",[7460]="Hoher Gipfel",[7461]="Hoher Gipfel",[7462]="Hoher Gipfel",[7463]="Hoher Gipfel",[7464]="Hoher Gipfel",[7465]="Hoher Gipfel",[7466]="Hoher Gipfel",[7467]="Hoher Gipfel",[7468]="Hoher Gipfel",[7469]="Hoher Gipfel",[7470]="Hoher Gipfel",[7471]="Hoher Gipfel",[7472]="Hoher Gipfel",[7473]="Hoher Gipfel",[7474]="Hoher Gipfel",[7475]="Hoher Gipfel",[7476]="Hoher Gipfel",[7477]="Hoher Gipfel",[7478]="Hoher Gipfel",[7479]="Hoher Gipfel",[7481]="Sturmarionnachschub",[7483]="Altar der Segnung",[7486]="Erfüllter Knochenhaufen",[7487]="Schrifttafel von Akil'zon",[7488]="Schrifttafel von Halazzi",[7489]="Schrifttafel von Jan'alai",[7490]="Schrifttafel von Nalorakk",[7491]="Schrifttafel der Herrscherfamilie",[7492]="Schrifttafel von Kulzi",[7493]="Schrifttafel von Filo",[7497]="Sturmariontruhe",[7498]="Leerengeschütztes Grab",[7499]="Unvollständiges Buch der Sonette",[7502]="Kurioser Obelisk",[7503]="Kurioser Obelisk",[7504]="Erfüllter Knochenhaufen",[7505]="Truhe des Fachmanns",[7506]="Truhe des Fachmanns",[7507]="Truhe des Fachmanns",[7508]="Truhe des Fachmanns",[7509]="Truhe des Fachmanns",[7510]="Truhe des Fachmanns",[7511]="Ruhmrüstmeister der Singularität",[7512]="Altvater Baum",[7513]="Rüstmeister",[7514]="Dekorationsexperte",[7515]="Dekorationsexperte der Hara'ti",[7516]="Ruhmrüstmeister",[7517]="Ruhmrüstmeister des Amanistamms",[7518]="Ruhmrüstmeister der Hara'ti",[7519]="Ruhmrüstmeister des Hofs in Silbermond",[7520]="Dekorationsexperte des Amanistamms",[7521]="Rüstmeister des Handwerkerkonsortiums",[7522]="Rüstmeister für Eroberungspunkte",[7523]="Rüstmeisterin für Kriegsmodus",[7525]="Sonnenläuferin Nadura",[7526]="Dekorationsexperte des Hofs in Silbermond",[7527]="Dekorationsexperte der Singularität",[7528]="Hassbrecherultradon",[7529]="Trauerknochenultradon",[7530]="Uraltes Relikt",[7531]="Nullaeus' Diener",[7533]="Mausoloamonolith",[7534]="Loagewirktes Mammut",[7535]="Loablümchenwuchs",[7536]="Loanitleere",[7537]="Türsteuerkonsole",[7538]="Ruhmrüstmeister der Singularität",[7544]="Speerwand",[7545]="Verschlossene Tür",[7546]="The Tauren Chieftains",[7549]="Ziel von Lindormis Rat",[7551]="Große Schließkassette",[7552]="Nyxovar",[7553]="Obliron",[7554]="Vexaroth",[7555]="Nullatros",[7556]="Schrein",[7558]="Eisbrutmutter",[7566]="Champion von Pahk",[7567]="Atem holen",[7568]="Atem holen",[7578]="Auf Patrouille",[7579]="Fragment der Macht",[7593]="Knochenhaufen",[7600]="Die erzürnten Gezeiten",[7601]="Managesättigter Großwyrm",[7602]="Giftschuppe Mar'grita",[7603]="Dämmerklaue",[7605]="Leerenerfüllter Graupelstein",[7606]="Atomus",[7611]="Ungebundener Rufer",[7612]="Agiles Gespenst",[7613]="Schwerfälliger Frevler",[7614]="Lehrling Thentor",[7615]="Lehrling Kurgsbann",[7616]="Lehrling Jezhren",[7617]="Verderbter Drachenfalke der Amani",[7618]="Eidbrecher Ger'lok",[7619]="Strömungsbrecher Garazyn",[7620]="Tiefenpirscher Szeirjal",[7621]="Abyssischer Vazir",[7622]="Leerenerfüllter Geistbeuger",[7623]="Selen'vjar",[7624]="Morastgebundenes Gespenst",[7625]="Durchnässter Leerenbinder",[7626]="Abgrundschlächter",[7628]="Leerenrufer Ozi'rug",[7631]="Kriegsfürstin Heth",[7632]="Aufgebrachter Schrecken",[7657]="Verurteiltes Tier",[7658]="Ellenlanger Uarn",[7659]="Broxion",[7660]="Flackernde Senkenschwinge",[7661]="Lomelith",[7662]="Obeliskenportal",[7663]="Soridormi",[7667]="Beutejagdfalle",[7668]="Auredar",[7669]="Unbezähmbarer Mk XII",[7670]="Xi'Grivr",[7671]="Slaipaan",[7674]="Versteckter",[7675]="Xirah",[7676]="Mercilus",[7677]="Krilkan",[7678]="Opprimius",[7679]="Nelgothar",[7680]="Das Grauen der Tiefe",[7684]="Eissturm",[7690]="Zerstörer der Schattenwache",[7693]="Truhe",[7698]="Dekorationsduellhändler",[7699]="Voidwarped Sporebat",[7706]="Hal'hadar Pocket-Storage",[7707]="Domanaar Storage Vessel",[7733]="Vanguard Kadoxe",[7734]="Starseeker Dreadus",[7735]="Reaper Gorzok",[7736]="Mender Amatory",[7737]="Techno-Medic Alazj",[7738]="Renegade Kulivero",[7739]="Spellslinger Rem'lazar",[7740]="Guardian Halazir"}
						local db = GrailDatabase
						if not db.vignetteLinks then print('vignames db: no vignetteLinks') return end
						local updated, notfound = 0, 0
						for k, v in pairs(db.vignetteLinks) do
							if v == true then
								local g = strmatch(k, '^([^|]+)')
								if g and strsub(g, 1, 9) == 'Vignette-' then
									local tid = tonumber((select(6, strsplit('-', g))))
									local name = tid and t[tid]
									if name then
										db.vignetteLinks[k] = name
										if db.vignetteGuidIndex then db.vignetteGuidIndex[g] = k end
										print(strformat('|cFFFFFF00Grail|r: named (db): |cFF00FF00%s|r', name))
										updated = updated + 1
									else
										notfound = notfound + 1
									end
								end
							end
						end
						print(strformat('vignames db: updated=%d not_in_db=%d', updated, notfound))
					end)
					self:RegisterSlashOption("vignames", "|cFF00FF00vignames|r => updates known vignette links with names from currently visible vignettes", function()
						local db = GrailDatabase
						if not db.vignetteLinks then print('vignames: no vignetteLinks found') return end
						local updated, skipped, missing = 0, 0, 0
						for k, v in pairs(db.vignetteLinks) do
							if v == true then
								local g = strmatch(k, '^([^|]+)')
								if g and strsub(g, 1, 9) == 'Vignette-' then
									local info = C_VignetteInfo and C_VignetteInfo.GetVignetteInfo and C_VignetteInfo.GetVignetteInfo(g)
									if info and info.name then
										db.vignetteLinks[k] = info.name
										if db.vignetteGuidIndex then db.vignetteGuidIndex[g] = k end
										updated = updated + 1
									else
										missing = missing + 1
									end
								end
							else
								skipped = skipped + 1
							end
						end
						print(strformat('vignames: updated=%d already_named=%d not_visible=%d', updated, skipped, missing))
						-- List vignettes still needing names with their stored coords
						if missing > 0 then
							local tomtomAvail = TomTom and TomTom.AddWaypoint
							if tomtomAvail then
								print('vignames: adding TomTom waypoints for unnamed vignettes')
							else
								print('vignames: vignettes still needing names (TomTom not available):')
							end
							for k, v in pairs(db.vignetteLinks) do
								if v == true then
									local g = strmatch(k, '^([^|]+)')
									local coordStr = strmatch(k, 'coords=([^|]+)')
									if g and strsub(g, 1, 9) == 'Vignette-' then
										print(strformat('  guid=%s coords=%s', g, tostring(coordStr)))
										if tomtomAvail and coordStr then
											local mapID, x, y = strmatch(coordStr, '(%d+):([%d%.]+),([%d%.]+)')
											mapID = tonumber(mapID)
											x = tonumber(x)
											y = tonumber(y)
											if mapID and x and y then
												TomTom:AddWaypoint(mapID, x/100, y/100, { title = strformat('Grail: unnamed vignette %s', g) })
											end
										end
									end
								end
							end
						end
					end)
					self:RegisterSlashOption("questhub", "|cFF00FF00questhub|r => dumps QuestHub dataProvider.questHubs and questOffers", function()
						local p = WorldMapFrame and WorldMapFrame.pinPools and WorldMapFrame.pinPools['QuestHubPinTemplate']
						if not p then print('QuestHubPinTemplate pool not found') return end
						local pins = {}
						pcall(function() for pin in p:EnumerateActive() do table.insert(pins, pin) end end)
						if #pins == 0 then print('No active QuestHub pins') return end
						for i, pin in ipairs(pins) do
							local dp = pin.dataProvider
							local poiID = pin.poiInfo and pin.poiInfo.areaPoiID
							local hubName = pin.name or (pin.poiInfo and pin.poiInfo.name)
							print(strformat('HUB #%d: name=%s areaPoiID=%s mapID=%s',
								i, tostring(hubName), tostring(poiID), tostring(pin.lastOwningMapID)))
							-- Dump questHubs
							if dp and dp.questHubs then
								print(strformat('  questHubs:'))
								for hk, hv in pairs(dp.questHubs) do
									if type(hv) == 'table' then
										print(strformat('    [%s]:', tostring(hk)))
										for k2, v2 in pairs(hv) do
											if type(v2) ~= 'function' and type(v2) ~= 'table' then
												print(strformat('      %s = %s', tostring(k2), tostring(v2)))
											end
										end
									else
										print(strformat('    [%s] = %s', tostring(hk), tostring(hv)))
									end
								end
							end
							-- Dump questOffers
							if dp and dp.questOffers then
								print(strformat('  questOffers:'))
								for ok2, ov in pairs(dp.questOffers) do
									if type(ov) == 'table' then
										print(strformat('    [%s]:', tostring(ok2)))
										for k3, v3 in pairs(ov) do
											if type(v3) ~= 'function' and type(v3) ~= 'table' then
												print(strformat('      %s = %s', tostring(k3), tostring(v3)))
											end
										end
									else
										print(strformat('    [%s] = %s', tostring(ok2), tostring(ov)))
									end
								end
							end
							-- relatedQuests
							if pin.relatedQuests and next(pin.relatedQuests) then
								print('  relatedQuests:')
								for rk, rv in pairs(pin.relatedQuests) do
									print(strformat('    [%s] = %s', tostring(rk), tostring(rv)))
								end
							end
						end
					end)
					-- >>>QUESTPIN_DEBUG_END
					-- >>>QUESTPIN_DEBUG
					self:RegisterSlashOption("taskquests", "|cFF00FF00taskquests|r => dumps C_TaskQuest data for current map", function()
						local mapID = C_Map.GetBestMapForUnit('player')
						local frame = ChatFrame1
						local function p(s) frame:AddMessage(s) end
						p(strformat('TASKQUEST_SCAN: mapID=%d', mapID))
						-- C_TaskQuest.GetQuestsOnMap
						if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
							local tasks = C_TaskQuest.GetQuestsOnMap(mapID)
							p(strformat('  GetQuestsOnMap: %d entries', tasks and #tasks or 0))
							for _, q in ipairs(tasks or {}) do
								p(strformat('  questID=%s x=%.2f y=%.2f inProgress=%s numObjectives=%s',
									tostring(q.questID), (q.x or 0)*100, (q.y or 0)*100,
									tostring(q.inProgress), tostring(q.numObjectives)))
							end
						end
						-- C_TaskQuest.GetQuestsForPlayerByMapID
						if C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID then
							local tasks2 = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
							p(strformat('  GetQuestsForPlayerByMapID: %d entries', tasks2 and #tasks2 or 0))
							for _, q in ipairs(tasks2 or {}) do
								p(strformat('  questID=%s x=%.2f y=%.2f inProgress=%s',
									tostring(q.questID), (q.x or 0)*100, (q.y or 0)*100, tostring(q.inProgress)))
							end
						end
						-- WorldMap pool: QuestBlobPinTemplate
						if WorldMapFrame and WorldMapFrame.pinPools then
							local pool = WorldMapFrame.pinPools['QuestBlobPinTemplate']
							if pool then
								local pins = {}
								pcall(function() for pin in pool:EnumerateActive() do table.insert(pins, pin) end end)
								if #pins == 0 and pool.activeObjects then
									for pin in pairs(pool.activeObjects) do table.insert(pins, pin) end
								end
								p(strformat('  QuestBlobPinTemplate: %d active', #pins))
								for _, pin in ipairs(pins) do
									p(strformat('  pin: questID=%s', tostring(pin.questID)))
									for k,v in pairs(pin) do
										if type(v) ~= 'function' and type(v) ~= 'table' then
											p(strformat('    %s=%s', tostring(k), tostring(v)))
										end
									end
								end
							end
						end
					end)
					self:RegisterSlashOption("questpins", "|cFF00FF00questpins|r |cFFFF8C00[questID]|r => dumps all quest pins, or diagnoses a specific questID", function(msg)
						local diagID = tonumber(strtrim(strsub(msg, 10)))
						print(strformat('questpins: msg=%q diagID=%s', msg, tostring(diagID)))
						if diagID then
							-- Single quest diagnosis
							print(strformat('QUESTPIN_DIAG: questID=%d', diagID))
							print(strformat('  IsQuestFlaggedCompleted: %s', tostring(C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(diagID))))
							print(strformat('  IsOnQuest: %s', tostring(C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(diagID))))
							print(strformat('  IsComplete: %s', tostring(C_QuestLog.IsComplete and C_QuestLog.IsComplete(diagID))))
							local info = C_QuestLog.GetQuestInfo and C_QuestLog.GetQuestInfo(diagID)
							if info then
								print(strformat('  GetQuestInfo: title=%s isCampaign=%s isHidden=%s',
									tostring(info.title), tostring(info.isCampaign), tostring(info.isHidden)))
							else print('  GetQuestInfo: nil') end
							local details = C_QuestLog.GetQuestDetails and C_QuestLog.GetQuestDetails(diagID)
							if details then
								print(strformat('  GetQuestDetails: %s', tostring(details)))
							else print('  GetQuestDetails: nil/not found') end
							local mapID = C_Map.GetBestMapForUnit('player')
							local waypointInfo = C_QuestLog.GetQuestObjectivesForPin and C_QuestLog.GetQuestObjectivesForPin(diagID, mapID)
							if waypointInfo then
								print(strformat('  GetQuestObjectivesForPin: %s', tostring(waypointInfo)))
							else print('  GetQuestObjectivesForPin: nil') end
							-- Check if visible in GetQuestsOnMap across map hierarchy
							local mid = mapID
							for d = 1, 5 do
								if not mid then break end
								local pins = C_QuestLog.GetQuestsOnMap and C_QuestLog.GetQuestsOnMap(mid)
								if pins then
									for _, p in ipairs(pins) do
										if p.questID == diagID then
											print(strformat('  FOUND in GetQuestsOnMap mapID=%d x=%.2f y=%.2f', mid, (p.x or 0)*100, (p.y or 0)*100))
										end
									end
								end
								local mi = C_Map.GetMapInfo(mid)
								mid = mi and mi.parentMapID
							end
							-- Check C_QuestLine (campaign quest lines)
							if C_QuestLine then
								local _mid = C_Map.GetBestMapForUnit('player')
								if C_QuestLine.GetQuestLineInfo then
									local qli = C_QuestLine.GetQuestLineInfo(diagID, _mid)
									print(strformat('  C_QuestLine.GetQuestLineInfo: %s', qli and strformat('questLineID=%s name=%s', tostring(qli.questLineID), tostring(qli.questLineName)) or 'nil'))
								end
								if C_QuestLine.GetAvailableQuestLines then
									local qlines = C_QuestLine.GetAvailableQuestLines(_mid)
									if qlines then
										for _, ql in ipairs(qlines) do
											print(strformat('  QuestLine: id=%s name=%s', tostring(ql.questLineID), tostring(ql.questLineName)))
										end
									else print('  GetAvailableQuestLines: nil') end
								end
							end
							-- Check C_CampaignInfo
							if C_CampaignInfo then
								if C_CampaignInfo.GetCampaignInfo then
									local ok, ci = pcall(C_CampaignInfo.GetCampaignInfo, diagID)
									print(strformat('  C_CampaignInfo.GetCampaignInfo: %s', (ok and ci) and tostring(ci) or 'nil'))
								end
							end
							-- Check C_QuestLog.GetAllCompletedQuestIDs nearby
							if C_QuestLog.RequestLoadQuestByID then
								C_QuestLog.RequestLoadQuestByID(diagID)
								print(strformat('  RequestLoadQuestByID(%d): called (check QUEST_DATA_LOAD_RESULT)', diagID))
							end
							-- Check WorldMap pools - dump ALL active pins in ALL pools
							local _ppos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit('player'), 'player')
							local _playerX = _ppos and _ppos.x*100 or 0
							local _playerY = _ppos and _ppos.y*100 or 0
							-- Check pools regardless of IsShown (addons may replace the map frame)
							if WorldMapFrame and WorldMapFrame.pinPools then
								print(strformat('  Player map pos: %.2f, %.2f isShown=%s', _playerX, _playerY, tostring(WorldMapFrame:IsShown())))
								for poolKey, pool in pairs(WorldMapFrame.pinPools) do
									-- Collect pins - try multiple pool iteration methods
									local _pins = {}
									if pool then
										if pool.activeObjects then
											for pin in pairs(pool.activeObjects) do table.insert(_pins, pin) end
										elseif type(pool.EnumerateActive) == 'function' then
											local ok2, err = pcall(function() for pin in pool:EnumerateActive() do table.insert(_pins, pin) end end)
											if not ok2 then print(strformat('  pool=%s EnumerateActive err=%s', poolKey, tostring(err))) end
										elseif type(pool.GetPins) == 'function' then
											local ok, result = pcall(function() return pool:GetPins() end)
											if ok and type(result) == 'table' then
												for pin in pairs(result) do table.insert(_pins, pin) end
											end
										end
									end
									if #_pins > 0 then
										print(strformat('  pool=%s count=%d', poolKey, #_pins))
										for _, pin in ipairs(_pins) do
											local qid = pin.questID or (pin.questInfo and pin.questInfo.questID)
											local x, y
											if pin.normalizedX then x=pin.normalizedX*100; y=pin.normalizedY*100
											elseif pin.GetNormalizedPosition then local px,py=pin:GetNormalizedPosition(); x=px and px*100; y=py and py*100 end
											if qid == diagID then
												print(strformat('    MATCHED questID=%s x=%s y=%s', tostring(qid), tostring(x), tostring(y)))
												for k,v in pairs(pin) do
													if type(v) ~= 'function' and type(v) ~= 'table' then
														print(strformat('      pin.%s=%s', tostring(k), tostring(v)))
													end
												end
											else
												print(strformat('    pin: questID=%s x=%s y=%s', tostring(qid), tostring(x), tostring(y)))
											end
										end
									end
								end
								-- Also dump ALL AreaPOIs without atlas filter
								local _mapID = C_Map.GetBestMapForUnit('player')
								if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap then
									local pois = C_AreaPoiInfo.GetAreaPOIForMap(_mapID)
									if pois then
										print(strformat('  ALL AreaPOIs mapID=%d count=%d', _mapID, #pois))
										for _, poiID in ipairs(pois) do
											local info = C_AreaPoiInfo.GetAreaPOIInfo(_mapID, poiID)
											print(strformat('    POI: id=%s name=%s atlas=%s',
												tostring(poiID), tostring(info and info.name), tostring(info and info.atlasName)))
										end
									end
								end
							end
							return
						end
						-- Full scan (no questID given)
						local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
						local snapSize = 0
						if self._persistentPinSnapshot then for _ in pairs(self._persistentPinSnapshot) do snapSize=snapSize+1 end end
						print(strformat('QUESTPIN_SCAN: player mapID=%s persistentSnapshot=%d entries', tostring(playerMapID), snapSize))
						-- Recent completed quests
						local recentList = {}
						if self._recentlyCompletedQuestIds then
							for q in pairs(self._recentlyCompletedQuestIds) do table.insert(recentList, tostring(q)) end
						end
						print(strformat('  recentlyCompleted: %s', #recentList>0 and table.concat(recentList,',') or 'none'))
						-- Scan current map + parent maps
						local totalOffer, totalHub = 0, 0
						local mapID = playerMapID
						for depth = 1, 5 do
							if not mapID then break end
							local mapInfo = C_Map.GetMapInfo(mapID)
							local offerCount, hubCount = 0, 0
							if C_QuestLog and C_QuestLog.GetQuestsOnMap then
								local pins = C_QuestLog.GetQuestsOnMap(mapID)
								if pins then
									for _, pin in ipairs(pins) do
										local pinKey = strformat('offer:%d', pin.questID or 0)
										local inSnap  = self._persistentPinSnapshot and self._persistentPinSnapshot[pinKey] ~= nil
										local inLinks = false
										if GrailDatabase.questPinLinks then
											for k in pairs(GrailDatabase.questPinLinks) do
												if strfind(k, pinKey, 1, true) then inLinks=true break end
											end
										end
										print(strformat('    OFFER: questID=%s x=%.2f y=%.2f inSnapshot=%s linked=%s',
											tostring(pin.questID), (pin.x or 0)*100, (pin.y or 0)*100, tostring(inSnap), tostring(inLinks)))
										offerCount=offerCount+1; totalOffer=totalOffer+1
									end
								end
							end
							if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap then
								local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
								if pois then
									for _, poiID in ipairs(pois) do
										local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
										if info and info.atlasName and strfind(strlower(info.atlasName), 'quest') then
											local pinKey = strformat('hub:%d', poiID)
											local inSnap  = self._persistentPinSnapshot and self._persistentPinSnapshot[pinKey] ~= nil
											print(strformat('    HUB: poiID=%s name=%s atlas=%s inSnapshot=%s',
												tostring(poiID), tostring(info.name), tostring(info.atlasName), tostring(inSnap)))
											hubCount=hubCount+1; totalHub=totalHub+1
										end
									end
								end
							end
							print(strformat('  mapID=%d name=%s: offer=%d hub=%d',
								mapID, tostring(mapInfo and mapInfo.name), offerCount, hubCount))
							mapID = mapInfo and mapInfo.parentMapID
						end
						print(strformat('QUESTPIN_SCAN: total offer=%d hub=%d', totalOffer, totalHub))
						-- Active WorldMap pin pools (only if map open)
						if WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.pinPools then
							local targetPools = { QuestOfferPinTemplate='campaign_offer', QuestBlobPinTemplate='blob', QuestHubPinTemplate='hub', QuestPinTemplate='active' }
							for poolKey, pinType in pairs(targetPools) do
								local pool = WorldMapFrame.pinPools[poolKey]
								if pool and pool.activeObjects then
									for pin in pairs(pool.activeObjects) do
										local qid = pin.questID or (pin.questInfo and pin.questInfo.questID)
										local x, y
										if pin.normalizedX then x=pin.normalizedX; y=pin.normalizedY
										elseif pin.GetNormalizedPosition then x,y=pin:GetNormalizedPosition() end
										local inSnap = self._persistentPinSnapshot and qid and self._persistentPinSnapshot[strformat('offer:%d',qid)] ~= nil
										print(strformat('  POOL %s: questID=%s x=%s y=%s inSnapshot=%s',
											pinType, tostring(qid),
											x and strformat('%.2f',x*100) or '?',
											y and strformat('%.2f',y*100) or '?',
											tostring(inSnap)))
									end
								end
							end
						else
							print('  WorldMap not open - open map and run /grail questpins for pool scan')
						end
					end)

					self:RegisterSlashOption("vignettes", "|cFF00FF00vignettes|r => dumps all known vignettes on the current map with coordinates and distance to player", function()
						local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
						if not mapID then print('vignettes: no map') return end
						local px, py = Grail.GetPlayerMapPosition('player', mapID)
						if not px then print('vignettes: player position unavailable') return end
						local vignettes = C_VignetteInfo and C_VignetteInfo.GetVignettes and C_VignetteInfo.GetVignettes()
						if not vignettes or #vignettes == 0 then print('vignettes: none on this map') return end
						print(strformat('|cFFFFFF00Grail vignettes|r on map %d (player %.4f,%.4f):', mapID, px, py))
						for _, guid in ipairs(vignettes) do
							local info = C_VignetteInfo.GetVignetteInfo(guid)
							local pos  = C_VignetteInfo.GetVignettePosition and C_VignetteInfo.GetVignettePosition(guid, mapID)
							local coordStr, distStr = 'no pos', 'n/a'
							if pos then
								coordStr = strformat('%d:%.2f,%.2f', mapID, pos.x * 100, pos.y * 100)
								-- Map coords are 0-1 fractions. Convert delta to approximate yards
								-- using UnitPosition world coords for accuracy.
								local wx, wy, wz = UnitPosition('player')
								local vwx, vwy
								if wx and C_Map.GetWorldPosFromMapPos then
									local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(pos.x, pos.y))
									if worldPos then vwx, vwy = worldPos.x, worldPos.y end
								end
								if vwx and wx then
									local dx, dy = vwx - wx, vwy - wy
									distStr = strformat('%.0f yds', math.sqrt(dx*dx + dy*dy))
								else
									local dx = (pos.x - px) * 533
									local dy = (pos.y - py) * 533
									distStr = strformat('~%.0f yds', math.sqrt(dx*dx + dy*dy))
								end
							end
							local name    = info and info.name or '?'
							local vigType = info and tostring(info.vignetteType) or '?'
							local msg = strformat('  %s | %s | coords=%s | dist=%s | type=%s', guid, name, coordStr, distStr, vigType)
							print(msg)
							self:_AddTrackingMessage(msg)
						end
					end)
					-- Manual vignette link: /grail viglink <guid> <name> <rep> <coords>
					-- Example: /grail viglink Vignette-0-2012-2694-261-7195-000069CAE1 "Leuchtende Motte" "Hara'ti+2500" 2413:50.83,53.30
					self:RegisterSlashOption("viglink ", "|cFF00FF00viglink|r |cFFFF8C00guid name rep coords|r => manually records a vignette-rep or vignette-quest link", function(msg)
						-- Skip if this is a 'viglink all' call
						if strsub(msg, 1, 11) == 'viglink all' then return end
						-- Parse: first token=guid, then quoted or unquoted name, then rep/quest, then coords
						local guid, rest = strmatch(strsub(msg, 9), '^(%S+)%s+(.*)')
						if not guid then
							print('Usage: /grail viglink <guid> <name> <rep_or_quest> <coords>')
							return
						end
						-- Name may be quoted
						local name, remainder
						if strsub(rest, 1, 1) == '"' then
							name, remainder = strmatch(rest, '^"([^"]+)"%s+(.*)')
						else
							name, remainder = strmatch(rest, '^(%S+)%s+(.*)')
						end
						if not name or not remainder then
							print('Usage: /grail viglink <guid> <name> <rep_or_quest> <coords>')
							return
						end
						local source, coords = strmatch(remainder, '^(%S+)%s*(.*)')
						coords = (coords and strlen(coords) > 0) and coords or tostring(self:Coordinates())
						-- Detect if source looks like a quest ID (pure number) or rep string
						local questId = tonumber(source)
						local msg
						if questId then
							local _src = strformat('quests=%s | coords=%s', source, coords)
							msg = self:_IsNewVignetteLink(guid, _src, name)
								and strformat('VIGNETTE_QUEST_LINK (manual): vignette=%s name=%s | %s', guid, name, _src) or nil
						else
							local _src = strformat('rep=%s | coords=%s', source, coords)
							msg = self:_IsNewVignetteLink(guid, _src, name)
								and strformat('VIGNETTE_REP_LINK (manual): vignette=%s name=%s | %s', guid, name, _src) or nil
						end
						if msg then
							print(msg)
							self:_AddTrackingMessage(msg)
						else
							print('viglink: already recorded, skipped')
						end
					end)
					-- >>>VIGNETTE_DEBUG_END
					-- >>>VIGNETTE_DEBUG
					-- /grail viglink all [filter] -- links all visible vignettes to unlinked quests/rep
					-- /grail viglink all name=Leuchtende  -- only vignettes whose name contains 'Leuchtende'
					-- /grail viglink all quest=93144  -- links to a specific quest instead of all unlinked
					-- /grail viglink all rep=Hara'ti+50  -- links to a specific rep string instead of all unlinked
					self:RegisterSlashOption("viglink all", "|cFF00FF00viglink all|r |cFFFF8C00[name=X] [quest=N] [rep=X]|r => links all visible vignettes to recent unlinked quests/rep, with optional filters", function(msg)
						local args = strsub(msg, 12)  -- skip 'viglink all'
						local nameFilter  = strmatch(args, 'name=([^%s]+)')
						local questFilter = strmatch(args, 'quest=(%d+)')
						local repFilter   = strmatch(args, 'rep=([^%s]+)')
						local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
						local vignettes = C_VignetteInfo and C_VignetteInfo.GetVignettes and C_VignetteInfo.GetVignettes()
						if not vignettes or #vignettes == 0 then print('viglink all: no vignettes visible') return end
						local now = GetTime()
						-- Collect sources: quests and rep changes
						local questSources, repSources = {}, {}
						if questFilter then
							table.insert(questSources, questFilter)
						else
							for qId, qTime in pairs(self._recentlyCompletedUnlinkedQuests or {}) do
								if (now - qTime) <= 200 then table.insert(questSources, tostring(qId)) end
							end
						end
						if repFilter then
							table.insert(repSources, repFilter)
						else
							for _, repInfo in pairs(self._recentlyRepChanges or {}) do
								if (now - repInfo.time) <= 120 then
									table.insert(repSources, strformat('%s+%s', repInfo.faction, tostring(repInfo.amount)))
								end
							end
						end
						if #questSources == 0 and #repSources == 0 then
							print('viglink all: no recent unlinked quests or rep changes (within 120s)')
							return
						end
						local count = 0
						for _, guid in ipairs(vignettes) do
							local info = C_VignetteInfo.GetVignetteInfo(guid)
							local name = info and info.name or '?'
							-- Apply name filter if set
							if nameFilter and not strfind(strlower(name), strlower(nameFilter), 1, true) then
								-- skip
							else
								local coordStr = self:Coordinates()
								if mapID and C_VignetteInfo.GetVignettePosition then
									local pos = C_VignetteInfo.GetVignettePosition(guid, mapID)
									if pos then coordStr = strformat('%d:%.2f,%.2f', mapID, pos.x * 100, pos.y * 100) end
								end
								for _, qId in ipairs(questSources) do
									local _src = strformat('quests=%s | coords=%s', qId, coordStr)
									if self:_IsNewVignetteLink(guid, _src, name) then
										local m = strformat('VIGNETTE_QUEST_LINK (manual): vignette=%s name=%s | %s', guid, name, _src)
										print(m) self:_AddTrackingMessage(m) count = count + 1
									end
								end
								for _, rep in ipairs(repSources) do
									local _src = strformat('rep=%s | coords=%s', rep, coordStr)
									if self:_IsNewVignetteLink(guid, _src, name) then
										local m = strformat('VIGNETTE_REP_LINK (manual): vignette=%s name=%s | %s', guid, name, _src)
										print(m) self:_AddTrackingMessage(m) count = count + 1
									end
								end
							end
						end
						print(strformat('viglink all: wrote %d link(s)', count))
					end)
					-- >>>VIGNETTE_DEBUG_END

					if self.capabilities.usesAchievements then
						frame:RegisterEvent("ACHIEVEMENT_EARNED")		-- e.g., quest 29452 can be gotten if certain achievements are complete
						frame:RegisterEvent("CRITERIA_EARNED")		-- for debugging to see when criteria are earned in MoP
					end
					if self.existsClassicPandaria or self.existsMainline then
						frame:RegisterEvent("CRITERIA_COMPLETE")
					end
					-- >>>WARBAND_DEBUG
					frame:RegisterEvent("CRITERIA_UPDATE")
					frame:RegisterEvent("QUEST_WATCH_UPDATE")
					-- >>>WARBAND_DEBUG_END
					frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")	-- needed for quest status caching
					frame:RegisterEvent("COMBAT_TEXT_UPDATE")				-- used to capture structured faction rep changes
					frame:RegisterEvent("CHAT_MSG_SKILL")	-- needed for quest status caching
					if self.capabilities.usesGarrisons then
						frame:RegisterEvent("GARRISON_BUILDING_ACTIVATED")
						frame:RegisterEvent("GARRISON_BUILDING_REMOVED")
						frame:RegisterEvent("GARRISON_BUILDING_UPDATE")
						frame:RegisterEvent("GARRISON_TALENT_COMPLETE")
						frame:RegisterEvent("GARRISON_TALENT_UPDATE")
						frame:RegisterEvent("GARRISON_MISSION_STARTED")
						frame:RegisterEvent("GARRISON_MISSION_FINISHED")
						frame:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
						frame:RegisterEvent("GARRISON_TALENT_EVENT_UPDATE")
						frame:RegisterEvent("GARRISON_TALENT_RESEARCH_STARTED")
						frame:RegisterEvent("GARRISON_TALENT_UNLOCKS_RESULT")
						frame:RegisterEvent("GARRISON_TALENT_UPDATE")
					end
					frame:RegisterEvent("GOSSIP_CLOSED")
					frame:RegisterEvent("GOSSIP_SHOW")		-- needed to learn about gossips to be able to know when specific events have happened so quest availability can be updated
					frame:RegisterEvent("ITEM_TEXT_READY")	-- probably not need ITEM_TEXT_BEGIN
					frame:RegisterEvent("ITEM_TEXT_BEGIN")		-- support for tracking book reads in Eversong Woods (Midnight)
					if not self.GDE.notLoot then
						frame:RegisterEvent("LOOT_CLOSED")		-- Timeless Isle chests
					end
					frame:RegisterEvent("LOOT_OPENED")		-- support for Timeless Isle chests
					frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GOSSIP_CONFIRM")	-- gossipIndex, text, cost
frame:RegisterEvent("GOSSIP_ENTER_CODE")	-- gossipIndex
					if self.capabilities.usesMajorFactions then
						frame:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
						frame:RegisterEvent("MAJOR_FACTION_UNLOCKED")
					end
					if self.capabilities.usesAreaPOIs then
						frame:RegisterEvent("AREA_POIS_UPDATED")
					end
					-- >>>VIGNETTE_DEBUG
					if self.capabilities.usesVignettes then
						frame:RegisterEvent("VIGNETTES_UPDATED")
					end
					-- >>>VIGNETTE_DEBUG_END

-- ReloadUI in Classic same as startup
-- Normal startup in Classic		startup in Retail		ReloadUI in Retail
-- ADDON_LOADED						ADDON_LOADED			ADDON_LOADED
--									SPELLS_CHANGED
-- PLAYER_LOGIN						PLAYER_LOGIN			PLAYER_LOGIN
-- PLAYER_ENTERING_WORLD			PLAYER_ENTERING_WORLD	PLAYER_ENTERING_WORLD
-- QUEST_LOG_UPDATE					QUEST_LOG_UPDATE		QUEST_LOG_UPDATE
-- SPELLS_CHANGED					SPELLS_CHANGED			SPELLS_CHANGED

					frame:RegisterEvent("PLAYER_LEVEL_UP")	-- needed for quest status caching
					frame:RegisterEvent("PLAYER_REGEN_ENABLED")
					frame:RegisterEvent("PLAYER_REGEN_DISABLED")
					self:RegisterObserver("FullAccept", Grail._AcceptQuestProcessing)
					frame:RegisterEvent("QUEST_ACCEPTED")
					frame:RegisterEvent("QUEST_AUTOCOMPLETE")
					if self.capabilities.usesWorldQuests then
						frame:RegisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL")
						frame:RegisterEvent("COVENANT_CALLINGS_UPDATED")
						frame:RegisterEvent("COVENANT_CHOSEN")
						frame:RegisterEvent("COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED")
						frame:RegisterEvent("ANIMA_DIVERSION_OPEN")
					end
					frame:RegisterEvent("QUEST_DETAIL")
					frame:RegisterEvent("QUEST_LOG_UPDATE")	-- just to indicate we are now available to read the Blizzard quest log without issues
					frame:RegisterEvent("QUEST_REMOVED")
					frame:RegisterEvent("QUEST_TURNED_IN")
					frame:RegisterEvent("SKILL_LINES_CHANGED")
					if frame.RegisterUnitEvent then
						frame:RegisterUnitEvent("UNIT_AURA", "player")
						frame:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED", "player")
						frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
					else
						frame:RegisterEvent("UNIT_AURA")				-- it seems we need to know when a specific buff happens for quest 28656 at a minimum
						frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")	-- so we can know when a quest is complete or failed
						frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
					end
					frame:RegisterEvent("UPDATE_EXPANSION_LEVEL")
					frame:RegisterEvent("MAX_EXPANSION_LEVEL_UPDATED")
					frame:RegisterEvent("MIN_EXPANSION_LEVEL_UPDATED")
--					frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")	-- only to get the first time logging in so the GetQuestResetTime() actually returns a real value
					self:_CleanDatabase()
					self:_CleanDatabaseLearnedQuestName()
					self:_CleanDatabaseLearnedObjectName()
					--	We rely on _ProcessNPCs() being called before _CleanDatabaseLearnedNPCLocation() because we want all the world quest NPCs to be processed
					--	so any learned ones can be removed if the database contains them.
					self:_CleanDatabaseLearnedNPCLocation()
					self:_CleanDatabaseLearnedQuest()
					self:_CleanDatabaseLearnedQuestCode()

					self:RegisterObserver("Bags", self._BagUpdates)
					self:RegisterObserver("QuestLogChange", self._QuestLogUpdate)
					self:_UpdateTrackingObserver()

					-- Hook the world map to passively collect quest-pin locations as the
					-- player browses.  C_QuestLog.GetQuestsOnMap is retail/BFA+ only.
					-- We defer the scan by 0.5s because Blizzard populates quest-pin data
					-- asynchronously; calling GetQuestsOnMap immediately on SetMapID returns
					-- stale or empty results.
					if C_QuestLog.GetQuestsOnMap then
						WorldMapFrame:HookScript("OnShow", function()
							local mapID = WorldMapFrame:GetMapID()
							C_Timer.After(2.0, function()
								self:_ScanMapQuestPins(mapID)
								-- >>>QUESTPIN_DEBUG: diff against persistent snapshot when map opens after quest turnin
								if nil ~= self._recentlyCompletedQuestIds then
									local now = GetTime()
									local recentQuests = {}
									for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
										if (now - qTime) <= 30 then table.insert(recentQuests, tostring(qId)) end
									end
									if #recentQuests > 0 then
										local detail = strformat('quests=%s', table.concat(recentQuests, ','))
										local _pinNow = self:_QuestPinPoolSnapshot()
										local _poolNow = self:_QuestPinPoolSnapshot()
										self:_QuestPinCompareAndRecord(self._persistentPinSnapshot or {}, _poolNow,
											'WORLD_MAP_OPEN', detail)
										self._persistentPinSnapshot = _poolNow
										print(strformat('QUESTPIN_MAP_OPEN: scanned mapID=%d recent_quests=%s', mapID, table.concat(recentQuests, ',')))
											-- Check recently accepted quests
											if nil ~= self._recentlyAcceptedQuestIds then
												local _nowAccept = GetTime()
												local acceptList = {}
												for qId, qTime in pairs(self._recentlyAcceptedQuestIds) do
													if (_nowAccept - qTime) <= 30 then table.insert(acceptList, tostring(qId)) end
												end
												if #acceptList > 0 then
													local _base2 = self._questPinAcceptSnapshotBefore or {}
													local _poolNow2 = self:_QuestPinPoolSnapshot()
													local detail2 = strformat('accept_quests=%s', table.concat(acceptList, ','))
													self:_QuestPinCompareAndRecord(_base2, _poolNow2, 'WORLD_MAP_OPEN_ACCEPT', detail2)
													print(strformat('QUESTPIN_MAP_OPEN: scanned mapID=%d recent_accepts=%s', mapID, table.concat(acceptList, ',')))
												end
											end
									end
								end
								-- >>>QUESTPIN_DEBUG_END
							end)
						end)
						hooksecurefunc(WorldMapFrame, "SetMapID", function(_, mapID)
							C_Timer.After(2.0, function()
								self:_ScanMapQuestPins(mapID)
								-- >>>QUESTPIN_DEBUG: diff on map navigation if recent quest turnin
								if nil ~= self._recentlyCompletedQuestIds then
									local now = GetTime()
									local recentQuests = {}
									for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
										if (now - qTime) <= 30 then table.insert(recentQuests, tostring(qId)) end
									end
									if #recentQuests > 0 then
										local detail = strformat('quests=%s', table.concat(recentQuests, ','))
										local _pinNow = self:_QuestPinPoolSnapshot()
										local _poolNow2 = self:_QuestPinPoolSnapshot()
										self:_QuestPinCompareAndRecord(self._persistentPinSnapshot or {}, _poolNow2,
											'WORLD_MAP_SETMAPID', detail)
										self._persistentPinSnapshot = _poolNow2
									end
								end
								-- >>>QUESTPIN_DEBUG_END
							end)
						end)
					end

					self.timings.AddonLoaded = 	debugprofilestop() - debugStartTime
--				end

			end,

			-- Because we cannot use C_AnimaDiversion.GetAnimaDiversionNodes() before the Anima Diversion UI has been opened to get real results
			-- and because the results are only for your current covenant, we instead record the quest names and intend to populate all the quest
			-- names over time by having all covenants and localizations eventually have their Anima DIversion UI opened.
			['ANIMA_DIVERSION_OPEN'] = function(self, frame)
				local diversionNodes = C_AnimaDiversion.GetAnimaDiversionNodes()
				if nil ~= diversionNodes then
					for _, node in pairs(diversionNodes) do
						local id = tonumber(node.talentID)
						if nil ~= id then
							local questId = self.diversionMapping[id] or id + 100000
							local questName = node.description
							if nil ~= questName and questName ~= '' and questName ~= self.quest.name[questId] then
								self:_LearnQuestName(questId, questName)
							end
						end
					end
				end
			end,

			['BAG_UPDATE'] = function(self, frame, bagId)
				if bagId ~= -2 and bagId < 5 then		-- a normal bag that is not the special (-2) backpack
					if not self.inCombat or not self.GDE.delayEvents then
						self:_CoalesceDelayedNotification("Bags", self.delayBagUpdate)
					else
						self:_RegisterDelayedEvent(frame, { 'BAG_UPDATE' } )
					end
				end
			end,

			['ARTIFACT_XP_UPDATE'] = function(self, frame)
				local Dynamic = C_ArtifactUI.IsAtForge() and C_ArtifactUI.GetArtifactInfo or C_ArtifactUI.GetEquippedArtifactInfo
				local itemID, _, _, _, _, ranksPurchased = Dynamic()
				if nil ~= itemID and nil ~= ranksPurchased then
					local olderValue = self.artifactLevels[itemID]
					if olderValue ~= ranksPurchased then
						self.artifactLevels[itemID] = ranksPurchased
						self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupArtifactLevel])
					end
				end
			end,

			['CALENDAR_UPDATE_EVENT_LIST'] = function(self, frame)
				self.receivedCalendarUpdateEventList = true
				frame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
				self:_UpdateQuestResetTime()	-- moved here from ADDON_LOADED in the hopes that here GetQuestResetTime() will always return a real value
			end,

			-- When we call C_CovenantCallings.RequestCallings() we will get this event, but it also happens during gameplay.
			['COVENANT_CALLINGS_UPDATED'] = function(self, frame, ...)
				self:_AddCallingQuests(...)
			end,

			['COVENANT_CHOSEN'] = function(self, frame, ...)
				local covenantId = ...
				local message = strformat("Covenant chosen: %d", covenantId)
				if self.GDE.debug or self.GDE.tracking then
					print(message)
				end
				self:_AddTrackingMessage(message)
				-- If someone were to change covenants all the quests associated with covenant need to have their status refreshed.
				self:_InvalidateStatusForQuestsWithTalentPrerequisites()
				self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupRenownQuests])
				C_CovenantCallings.RequestCallings()	-- this causes COVENANT_CALLINGS_UPDATED to be received which is exactly what we need to update the current calling quests
			end,

			['COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED'] = function(self, frame, ...)
				local newLevel, oldLevel = ...
				local message = strformat("Renown level changed from %d to %d", oldLevel, newLevel)
				if self.GDE.debug or self.GDE.tracking then
					print(message)
				end
				self:_AddTrackingMessage(message)
				self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupRenownQuests])
			end,

			['GARRISON_MISSION_STARTED'] = function(self, frame, garrFollowerTypeID, missionID)
				local mission = C_Garrison.GetBasicMissionInfo(missionID)
				if nil ~= mission then
					local message = strformat("mission name: %s with mission id: %d started with garrFollowerTypeID %d", mission.name, missionID, garrFollowerTypeID)
					if self.GDE.debug or self.GDE.tracking then
						print(message)
					end
					self:_AddTrackingMessage(message)
				end
			end,

			['GARRISON_MISSION_FINISHED'] = function(self, frame, garrFollowerTypeID, missionID)
				local mission = C_Garrison.GetBasicMissionInfo(missionID)
				if nil ~= mission then
					local message = strformat("mission name: %s with mission id: %d finished with garrFollowerTypeID %d", mission.name, missionID, garrFollowerTypeID)
					if self.GDE.debug or self.GDE.tracking then
						print(message)
					end
					self:_AddTrackingMessage(message)
				end
			end,

			['GARRISON_MISSION_COMPLETE_RESPONSE'] = function(self, frame, missionID, canComplete, success, overmaxSucceeded, followerDeaths, autoCombatResult)
				local mission = C_Garrison.GetBasicMissionInfo(missionID)
				if nil ~= mission then
					local message = string.format("Garrison mission complete response: %s, missionID: %d, canComplete: %s, success: %s, overmaxSucceeded: %s", mission.name, missionID, tostring(canComplete), tostring(success), tostring(overmaxSucceeded))
					if self.GDE.debug then
						print(message)
					end
					self:_AddTrackingMessage(message)
				end
			end,

			['CHAT_MSG_COMBAT_FACTION_CHANGE'] = function(self, frame, message)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventChatMsgCombatFactionChange(message)
				else
					self:_RegisterDelayedEvent(frame, { 'CHAT_MSG_COMBAT_FACTION_CHANGE' } )
				end
			end,

			['COMBAT_TEXT_UPDATE'] = function(self, frame, type, arg1, arg2)
				self:_HandleEventCombatTextUpdate(type, arg1, arg2)
			end,

			['CHAT_MSG_SKILL'] = function(self, frame)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventChatMsgSkill()
				else
					self:_RegisterDelayedEvent(frame, { 'CHAT_MSG_SKILL' } )
				end
			end,

			['CRITERIA_EARNED'] = function(self, frame, ...)
				if self.GDE.debug or self.GDE.tracking then
--					local achievementId, criterionId = ...
					local achievementId, criterionName = ...
					local achievementName = self:GetBasicAchievementInfo(achievementId)
--					local criterionName = GetAchievementCriteriaInfoByID(achievementId, criterionId)
--					self:_AddTrackingMessage("Criterion earned: "..criterionName.." ("..criterionId..") for achievement "..achievementName.." ("..achievementId..")")
					self:_AddTrackingMessage("Criterion earned: "..criterionName.." for achievement "..achievementName.." ("..achievementId..")")
					self:_AddTrackingMessage("Coordinates earned: ", Grail:Coordinates())
				end
			end,

			['GARRISON_BUILDING_ACTIVATED'] = function(self, frame, plotId, buildingId)
if self.GDE.debug then print("GARRISON_BUILDING_ACTIVATED "..plotId.." "..buildingId) end
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventGarrisonBuildingActivated(buildingId)
				else
					self:_RegisterDelayedEvent(frame, { 'GARRISON_BUILDING_ACTIVATED', buildingId })
				end
			end,

			['GARRISON_BUILDING_REMOVED'] = function(self, frame, plotId, buildingId)
if self.GDE.debug then print("GARRISON_BUILDING_REMOVED "..plotId.." "..buildingId) end
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventGarrisonBuildingActivated(buildingId)
				else
					self:_RegisterDelayedEvent(frame, { 'GARRISON_BUILDING_REMOVED', buildingId })
				end
			end,

			['GARRISON_BUILDING_UPDATE'] = function(self, frame, buildingId)
if self.GDE.debug then print("GARRISON_BUILDING_UPDATE ", buildingId) end
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventGarrisonBuildingUpdate(buildingId)
				else
					self:_RegisterDelayedEvent(frame, { 'GARRISON_BUILDING_UPDATE', buildingId })
				end
			end,

			['GARRISON_TALENT_COMPLETE'] = function(self, frame, garrTypeID, doAlert)
				self:_InvalidateStatusForQuestsWithTalentPrerequisites()
				if self.GDE.debug then
					print("GARRISON_TALENT_COMPLETE, garrTypeID: ", garrTypeID)
				end
			end,
			
			['GARRISON_TALENT_UPDATE'] = function(self, frame, garrTypeID)
				self:_InvalidateStatusForQuestsWithTalentPrerequisites()
				if self.GDE.debug then
					print("GARRISON_TALENT_UPDATE garrTypeID: ", garrTypeID)
				end
			end,

			['GOSSIP_CLOSED'] = function(self, frame, ...)
				-- >>>GOSSIP_DEBUG
				local ctx = self._gossipDebugContext
				if nil ~= ctx then
					local newlyCompleted = {}
					QueryQuestsCompleted()
					self:_ProcessServerCompare(newlyCompleted)
					for _, qId in pairs(newlyCompleted) do
						self:_MarkQuestComplete(qId, true)
						local msg = strformat('GOSSIP_DEBUG CLOSED_COMPLETE: quest=%d npc=%s(%s) option=%s(id=%s) coords=%s',
							qId, tostring(ctx.targetName), tostring(ctx.npcId),
							tostring(ctx.lastOptionName), tostring(ctx.lastOptionID), tostring(ctx.coordinates))
						print(msg)
						self:_AddTrackingMessage(msg)
						self:_RecordGossipQuestLink(qId,
							ctx.npcId, ctx.targetName,
							ctx.lastOptionName, ctx.lastOptionID, ctx.coordinates)
					end
					if #newlyCompleted == 0 then
					end
					self:_ProcessServerBackup(true)
					-- Keep context briefly for async quest completion detection
					self._lastGossipContext = { targetName=ctx.targetName, npcId=ctx.npcId, coordinates=ctx.coordinates, time=GetTime(),
						lastOptionName=ctx.lastOptionName, lastOptionID=ctx.lastOptionID }
					self._gossipDebugContext = nil
				end
				-- >>>GOSSIP_DEBUG_END
				self.currentGossipNPCId = nil
			end,

			['GOSSIP_SHOW'] = function(self, frame, ...)
				local targetName, npcId, coordinates = self:TargetInformation()
				self.currentGossipNPCId = npcId
				-- >>>GOSSIP_DEBUG
				self._gossipDebugContext = {
					targetName  = targetName,
					npcId       = npcId,
					coordinates = coordinates,
				}
				self:_ProcessServerBackup(true)
				-- >>>GOSSIP_DEBUG_END
--				print("GOSSIP_SHOW:",targetName, npcId, coordinates,GetNumGossipAvailableQuests(),GetNumGossipActiveQuests(),GetNumGossipOptions(),GetGossipOptions())
				-- Check available gossip quests for unverified prerequisite observations.
				-- This covers multi-quest NPCs where QUEST_DETAIL only fires after the player selects a quest.
				if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
					local gossipQuests = C_GossipInfo.GetAvailableQuests()
					if gossipQuests then
						for _, questInfo in ipairs(gossipQuests) do
							self:_CheckAndLearnPrereqVerification(questInfo.questID)
						end
					end
				end
			end,

			['ITEM_TEXT_BEGIN'] = function(self, frame, ...)
				local currentMapAreaId = Grail.GetCurrentMapAreaID()
				if self.zonesForLootingTreasure[currentMapAreaId] then
					self.lootingGUID = GetLootSourceInfo(1)
					local text = GameTooltipTextLeft1
					self.lootingName = text and text:GetText() or self.defaultUnfoundLootingName
					if not self.doneProcessingBackup then
						self:_ProcessServerBackup(true)
						self.doneProcessingBackup = true
					end
				end
				-- Book path uses its own flag, independent of the loot path
				-- >>>VIGNETTE_DEBUG (also useful general book debug, remove with vignette code)
				print(strformat('DBG ITEM_TEXT_BEGIN: doneProcessingBookBackup=%s doneProcessingBackup=%s', tostring(self.doneProcessingBookBackup), tostring(self.doneProcessingBackup)))
				-- >>>VIGNETTE_DEBUG_END
				if not self.doneProcessingBookBackup then
					self:_ProcessServerBackup(true)
					self.doneProcessingBookBackup = true
				end
			end,

			['ITEM_TEXT_READY'] = function(self, frame, ...)
				local targetName, npcId, coordinates = self:TargetInformation()
				local questToComplete = self._ItemTextBeginList[npcId]
				-- Always log target and coordinates, even for unknown books
				local baseMessage = strformat("ITEM_TEXT_READY | Target: %s (%d) | Coords: %s", tostring(targetName), tonumber(npcId) or -1, tostring(coordinates))
				if self.GDE.debug then
					print(baseMessage)
				end
				self:_AddTrackingMessage(baseMessage)
				if nil ~= questToComplete then
					self:_MarkQuestComplete(questToComplete, true)
					local message = strformat("ITEM_TEXT_READY completes %d | Target: %s (%d) | Coords: %s", questToComplete, tostring(targetName), tonumber(npcId) or -1, tostring(coordinates))
					if self.GDE.debug then
						print(message)
					end
					self:_AddTrackingMessage(message)
				end
				-- Fallback: if ITEM_TEXT_BEGIN did not fire, take a fresh backup now.
				-- Uses doneProcessingBookBackup, independent from the loot path flag.
				if not self.doneProcessingBookBackup then
					self:_ProcessServerBackup(true)
					self.doneProcessingBookBackup = true
				end
				-- >>>VIGNETTE_DEBUG
				local _vigSnapBefore = self:_VignetteSnapshot()
				-- >>>VIGNETTE_DEBUG_END
				-- In Retail, QueryQuestsCompleted is replaced at startup with a synchronous
				-- wrapper around _ProcessServerQuests() -- completedQuests is updated immediately
				-- and QUEST_QUERY_COMPLETE never fires.  So we diff right after the call.
				-- In Classic, the call is async and QUEST_QUERY_COMPLETE fires later; we store
				-- context in pendingBookReadContext for that deferred handler to pick up.
				self.pendingBookReadContext = {
					targetName  = targetName,
					npcId       = npcId,
					coordinates = coordinates,
					knownQuest  = questToComplete,
				}
				QueryQuestsCompleted()
				-- Retail: if pendingBookReadContext is still set after the call, the compare
				-- was not done by QUEST_QUERY_COMPLETE, so do it now synchronously.
				if nil ~= self.pendingBookReadContext then
					local ctx = self.pendingBookReadContext
					self.pendingBookReadContext = nil
					local newlyCompleted = {}
					self:_ProcessServerCompare(newlyCompleted)
					for _, qId in pairs(newlyCompleted) do
						if qId ~= ctx.knownQuest then
							self:_MarkQuestComplete(qId, true)
						end
						local msg = strformat("Book read completes %d | Target: %s (%d) | Coords: %s", qId, tostring(ctx.targetName), tonumber(ctx.npcId) or -1, tostring(ctx.coordinates))
						if self.GDE.debug then
							print(msg)
						end
						self:_AddTrackingMessage(msg)
					end
					self:_ProcessServerBackup(true)
					self.doneProcessingBookBackup = false
					-- >>>VIGNETTE_DEBUG
					self:_VignetteCompareAndLog(_vigSnapBefore, self:_VignetteSnapshot(),
						strformat('ITEM_TEXT_READY npc=%s(%s)', tostring(targetName), tostring(npcId)))
					-- Store book-read context so VIGNETTES_UPDATED can correlate a disappearing
					-- vignette with this NPC and trigger a deferred quest compare.
					-- Timestamp guards against false matches if no vignette disappears for this book.
					self._pendingBookVignetteContext = {
						targetName  = targetName,
						npcId       = npcId,
						coordinates = coordinates,
						time        = GetTime(),
					}
					-- >>>VIGNETTE_DEBUG_END
				end
			end,

			--	We want to be able to handle the chests on the Timeless Isle.  To do so we need to be able to determine
			--	what quest was just completed and we need to have a current backup of quests before we ask to see what
			--	has changed.  Therefore, we will ensure one is made if we need to here.
			['LOOT_OPENED'] = function(self, frame, ...)
				local currentMapAreaId = Grail.GetCurrentMapAreaID()
				if self.zonesForLootingTreasure[currentMapAreaId] then
					self.lootingGUID = GetLootSourceInfo(1)
					local text = GameTooltipTextLeft1
					self.lootingName = text and text:GetText() or self.defaultUnfoundLootingName
					if not self.doneProcessingBackup then
						self:_ProcessServerBackup(true)
						self.doneProcessingBackup = true
--						frame:UnregisterEvent("LOOT_OPENED")
					end
				end
			end,

			['LOOT_CLOSED'] = function(self, frame, ...)
				local currentMapAreaId = Grail.GetCurrentMapAreaID()
				if self.zonesForLootingTreasure[currentMapAreaId] then
					if not self.inCombat or not self.GDE.delayEvents then
						self:_HandleEventLootClosed()
					else
						self:_RegisterDelayedEvent(frame, { 'LOOT_CLOSED' } )
					end
				end
			end,

			['PLAYER_REGEN_DISABLED'] = function(self, frame, ...)
				self.inCombat = true
			end,

			-- When the player is in combat and an event is processed that would normally
			-- take some time, that processing is deferred, and the PLAYER_REGEN_ENABLED
			-- event is registered so the addon is informed when the player is no longer
			-- in combat and can have the deferred work done.  When all the deferred work
			-- is done, PLAYER_REGEN_ENABLED is unregistered.
			-- Actually in more modern times PLAYER_REGEN_ENABLED remains registered.
			['PLAYER_REGEN_ENABLED'] = function(self, frame)
				self.inCombat = nil
				local t, type
				while (0 < self.delayedEventsCount) do
					t = self.delayedEvents[1]
					type = t[1]
					if 'UNIT_SPELLCAST_SUCCEEDED' == type then
						self:_StatusCodeInvalidate(self.questStatusCache['Z'][t[2]])
						self:_NPCLocationInvalidate(self.npcStatusCache['Z'][t[2]])
					elseif 'UNIT_QUEST_LOG_CHANGED' == type then
						self:_HandleEventUnitQuestLogChanged()
					elseif 'UNIT_AURA' == type then
						local spellsToNuke = t[2]
						for i = 1, #spellsToNuke do
							self:_StatusCodeInvalidate(self.questStatusCache['B'][spellsToNuke[i]])
							self:_StatusCodeInvalidate(self.questStatusCache['Y'][spellsToNuke[i]])
							self:_NPCLocationInvalidate(self.npcStatusCache['B'][spellsToNuke[i]])
							self:_NPCLocationInvalidate(self.npcStatusCache['Y'][spellsToNuke[i]])
						end
					elseif 'SKILL_LINES_CHANGED' == type then
						self:_HandleEventSkillLinesChanged()
					elseif 'PLAYER_LEVEL_UP' == type then
						self:_HandleEventPlayerLevelUp()
					elseif 'CHAT_MSG_SKILL' == type then
						self:_HandleEventChatMsgSkill()
					elseif 'LOOT_CLOSED' == type then
						self:_HandleEventLootClosed()
					elseif 'CHAT_MSG_COMBAT_FACTION_CHANGE' == type then
						self:_HandleEventChatMsgCombatFactionChange(t[2])
					elseif 'BAG_UPDATE' == type then
						self:_CoalesceDelayedNotification("Bags", self.delayBagUpdate)
					elseif 'ACHIEVEMENT_EARNED' == type then
						self:_HandleEventAchievementEarned(t[2])
					elseif 'GARRISON_BUILDING_ACTIVATED' == type then
						self:_HandleEventGarrisonBuildingActivated(t[2])
					elseif 'GARRISON_BUILDING_REMOVED' == type then
						self:_HandleEventGarrisonBuildingActivated(t[2])
					elseif 'GARRISON_BUILDING_UPDATE' == type then
						self:_HandleEventGarrisonBuildingUpdate(t[2])
					elseif 'MAJOR_FACTION_UNLOCKED' == type then
						self:_HandleEventMajorFactionUnlocked(t[2])
					elseif 'MAJOR_FACTION_RENOWN_LEVEL_CHANGED' == type then
						self:_HandleEventMajorFactionRenownLevelChanged(t[2], t[3], t[4])
					elseif 'AREA_POIS_UPDATED' == type then
						self:_HandleEventAreaPOIsUpdated()
					elseif 'UPDATE_EXPANSION_LEVEL' == type then
						self:_HandleEventUpdateExpansionLevel(t[2], t[3], t[4], t[5], t[6])
					elseif 'MAX_EXPANSION_LEVEL_UPDATED' == type then
						self:_HandleMaxExpansionLevelUpdated()
					elseif 'MIN_EXPANSION_LEVEL_UPDATED' == type then
						self:_HandleMinExpansionLevelUpdated()
					elseif 'CRITERIA_COMPLETE' == type then
						self:_HandleCriteriaComplete(t[2])
					end
					tremove(self.delayedEvents, 1)
					self.delayedEventsCount = self.delayedEventsCount - 1
					if InCombatLockdown() then			-- we have entered combat since we started processing, so abandon ship for now
						break
					end
				end
--				if 0 == self.delayedEventsCount then
--					frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
--				end
			end,

			['GOSSIP_CONFIRM'] = function(self, frame, ...)
			if self.GDE.debug then print("*** GOSSIP_CONFIRM", ...) end
			end,
			['GOSSIP_ENTER_CODE'] = function(self, frame, ...)
			if self.GDE.debug then print("*** GOSSIP_ENTER_CODE", ...) end
			end,

			['PLAYER_ENTERING_WORLD'] = function(self, frame)
			print("|cFF00FF00Grail|r: needs your help! Consider running /grail tracking & /Grail treasures ON and submit your data regularly")
				if self.capabilities.usesArtifacts then
					frame:RegisterEvent("ARTIFACT_XP_UPDATE")
				end
				-- >>>WARBAND_DEBUG
				self:_CheckWarbandQuestChanges('PLAYER_ENTERING_WORLD')
				-- >>>WARBAND_DEBUG_END
				-- >>>QUESTPIN_DEBUG: scan for new pins after zone change if quest was recently turned in
				if nil ~= self._recentlyCompletedQuestIds then
					local now = GetTime()
					local recentQuests = {}
					for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
						if (now - qTime) <= 200 then table.insert(recentQuests, tostring(qId)) end
					end
					if #recentQuests > 0 then
						local _self = self
						local detail = strformat('quests=%s', table.concat(recentQuests, ','))
						for _, delay in ipairs({1.0, 3.0}) do
							C_Timer.After(delay, function()
								local _poolNow = _self:_QuestPinPoolSnapshot()
								local cnt = _self:_QuestPinCompareAndRecord(_self._persistentPinSnapshot or {}, _poolNow,
									'PLAYER_ENTERING_WORLD', detail)
								if cnt > 0 then
									print(strformat('QUESTPIN_ZONE_CHANGE: found=%d delay=%.1fs %s', cnt, delay, detail))
								end
								_self._persistentPinSnapshot = _poolNow
						end)
						end
					end
				end
				-- >>>QUESTPIN_DEBUG_END
			end,

			-- Note that the new level is recorded here, because during processing of this event calls to UnitLevel('player')
			-- will not return the new level.
			['PLAYER_LEVEL_UP'] = function(self, frame, newLevel)
				self.levelingLevel = tonumber(newLevel)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventPlayerLevelUp()
				else
					self:_RegisterDelayedEvent(frame, { 'PLAYER_LEVEL_UP' } )
				end
			end,

			-- When a guestgiver only has one quest to give, by the time QUEST_ACCEPTED
			-- happens in WoD asking for TargetInformation() will not yield good results.
			-- Therefore, we record that information here and use it in QUEST_ACCEPTED.
			-- This is not perfect and there is no way to properly clear this unless I start
			-- overriding buttons on Blizzard's quest panel because, for example, the
			-- QUEST_FINISH event happens for both accepting and rejecting a quest.
			['QUEST_DETAIL'] = function(self, frame)
				local npcId, npcName = self:GetNPCInformation("questnpc")
				local coordinates = self:Coordinates()
				local databaseNPCId = self:_UpdateTargetDatabase(npcName, npcId, coordinates)
				local offeredQuestId = GetQuestID()
				self.questDetailInformation = {
					blizzardNPCId = npcId,
					coordinates = coordinates,
					npcId = databaseNPCId,
					npcName = npcName,
					questId = offeredQuestId
				}
				self:_CheckAndLearnPrereqVerification(offeredQuestId)
			end,

			-- Prior to Shadowlands, the signature is (self, frame, questIndex, questId)
			-- In Shadowlands, the signature is       (self, frame, questId)
			-- To run in both, we need to detect the number of parameters and deal with them appropriately.
			['QUEST_ACCEPTED'] = function(self, frame, questIndexOrIdBasedOnRelease, aQuestId)
				-- >>>WARBAND_DEBUG: accepting a quest may unlock warband quests
				self:_CheckWarbandQuestChanges('QUEST_ACCEPTED')
				-- >>>WARBAND_DEBUG_END
				-- If there are two parameters, the first will be the questIndex, otherwise we have no questIndex
				local questIndex = aQuestId and questIndexOrIdBasedOnRelease or nil
				
				-- If there are two parameters, the second is the quest Id, otherwise the first is.
				local theQuestId = aQuestId or questIndexOrIdBasedOnRelease
				
				-- In Shadowlands we need to look up the questIndex
				if questIndex == nil and C_QuestLog.GetLogIndexForQuestID then
					questIndex = C_QuestLog.GetLogIndexForQuestID(theQuestId)
				end
				
				-- For the "FullAccept" notification we want to provide a payload that includes all the useful
				-- information gathered when accepting a quest.
				local payload = {}
				if nil ~= self.questDetailInformation then
					payload.blizzardNPCId = self.questDetailInformation.blizzardNPCId
					payload.npcId = self.questDetailInformation.npcId
					payload.npcName = self.questDetailInformation.npcName
					if self.GDE.debug then
						if self.questDetailInformation.questId ~= theQuestId then
							print("*** QUEST_DETAIL reports questId", self.questDetailInformation.questId, "but QUEST_ACCEPT reports questId", theQuestId)
						end
					end
				else
					-- The assumption is if there was no QUEST_DETAIL presented, that the quest is gotten from self in the current map.
					payload.npcId = Grail.GetCurrentMapAreaID() * -1
					payload.npcName = Grail.npc.name[0]
				end
				payload.questId = theQuestId
				payload.questIndex = questIndex
				payload.coordinates = self:Coordinates()
				
				-- Get rid of the information gotten from QUEST_DETAIL so we do not use it erroneously again.
				self.questDetailInformation = nil
				
				-- Inform subscribers of what just happened
				self:_PostNotification("FullAccept", payload)
				self:_PostNotification("Accept", theQuestId)
				-- Check to see whether there are any other quests that are also marked by Blizzard as being completed now.
				if self.GDE.debug then
					self:_CoalesceDelayedNotification("QuestAcceptCheck", 1.0, theQuestId)
				end
				-- >>>QUESTPIN_DEBUG: track accepted quest for pin correlation
				self._recentlyAcceptedQuestIds = self._recentlyAcceptedQuestIds or {}
				self._recentlyAcceptedQuestIds[theQuestId] = GetTime()
				-- Take pool snapshot before new pins appear
				if not self._questPinAcceptSnapshotBefore then
					self._questPinAcceptSnapshotBefore = self._persistentPinSnapshot or self:_QuestPinPoolSnapshot()
				end
				-- Delayed scans for pins that appear/disappear after quest accept
				local _acceptedId = theQuestId
				local _self = self
				local _acceptBase = self._questPinAcceptSnapshotBefore
				if C_Timer and C_Timer.After then
					for _, delay in ipairs({1.0, 3.0, 7.0, 15.0}) do
						C_Timer.After(delay, function()
							local _pinNow = _self:_QuestPinPoolSnapshot()
							local _found = 0
							local detail = strformat('quest=%d delay=%.1fs', _acceptedId, delay)
							-- Appeared pins
							for key, info in pairs(_pinNow) do
								if not _acceptBase[key] then
									_found = _found + 1
									_self:_QuestPinCompareAndRecord({}, { [key]=info },
										'QUEST_ACCEPTED_DELAYED', detail)
									_self:_RecordQuestPinLink(key, info.pinType, info.name,
										strformat('accept:%d', _acceptedId), info.coords)
									print(strformat('QUESTPIN_ACCEPT: appeared pin=%s name=%s after %.1fs (quest=%d)',
										key, tostring(info.name), delay, _acceptedId))
									_acceptBase[key] = info
								end
							end
							-- Disappeared pins (only check at 1s)
							if delay == 1.0 then
								for key, info in pairs(_acceptBase) do
									if not _pinNow[key] then
										_self:_QuestPinCompareAndRecord({ [key]=info }, {},
											'QUEST_ACCEPTED_DELAYED', detail)
										_self:_RecordQuestPinLink(key, info.pinType, info.name,
											strformat('accept:%d|disappeared', _acceptedId), info.coords)
										print(strformat('QUESTPIN_ACCEPT: disappeared pin=%s after %.1fs (quest=%d)',
											key, delay, _acceptedId))
									end
								end
							end
							local _nowSize, _baseSize = 0, 0
							for _ in pairs(_pinNow) do _nowSize=_nowSize+1 end
							for _ in pairs(_acceptBase) do _baseSize=_baseSize+1 end
							print(strformat('QUESTPIN_ACCEPT_DELAYED: %.1fs quest=%d found=%d now=%d base=%d',
								delay, _acceptedId, _found, _nowSize, _baseSize))
							_self._persistentPinSnapshot = _pinNow
						end)
					end
					-- Reset accept snapshot after last delay
					C_Timer.After(16.0, function()
						_self._questPinAcceptSnapshotBefore = nil
					end)
				end
				-- >>>QUESTPIN_DEBUG_END

			end,

			['QUEST_AUTOCOMPLETE'] = function(self, frame, questId)
				local message = strformat("QUEST_AUTOCOMPLETE completes %d", questId)
				if self.GDE.debug then
					print(message)
				end
				self:_AddTrackingMessage(message)
			end,
			
			['WORLD_QUEST_COMPLETED_BY_SPELL'] = function(self, frame, questId)
			local message = strformat("WORLD_QUEST_COMPLETED_BY_SPELL completes %d", questId)
				if self.GDE.debug then
					print(message)
				end
				self:_AddTrackingMessage(message)
			end,

			-- This is used solely to indicate to the system that the Blizzard quest log is available to be read properly.  Early in the startup
			-- this is not the case prior to receiving PLAYER_ALIVE, but since that event is never received in a UI reload this event is used as
			-- a replacement which seems to work properly.
			['QUEST_LOG_UPDATE'] = function(self, frame)
				frame:UnregisterEvent("QUEST_LOG_UPDATE")
				self.receivedQuestLogUpdate = true
				-- >>>WARBAND_DEBUG
				self:_CheckWarbandQuestChanges('QUEST_LOG_UPDATE')
				-- >>>WARBAND_DEBUG_END
				frame:RegisterEvent("BAG_UPDATE")						-- we need to know when certain items are present or not (for quest 28607 e.g.)
				if self.capabilities.usesCalendar then
					frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")		-- to indicate the calendar is primed and can be accurately read
					-- The intention is to receive the CALENDAR_UPDATE_EVENT_LIST event
					-- and to do so, one calls OpenCalendar(), but it seems if one does
					-- not call the other calendar functions beforehand, the call to
					-- OpenCalendar() will do nothing useful.
					local weekday, month, day, year, hour, minute = self:CurrentDateTime()
					C_Calendar.SetAbsMonth(month, year)
					C_Calendar.OpenCalendar()	-- this does nothing during startup...its real usage is when checking holidays
					self:_AddWorldQuests()
					self:_AddThreatQuests()
					C_CovenantCallings.RequestCallings()	-- causes COVENANT_CALLINGS_UPDATED event to be sent
				end
				-- In Classic we need to get the completed quests because we have eliminated the
				-- call as a result of calendar processing being removed from Classic.
				if self.existsClassic then
					QueryQuestsCompleted()
				end
			end,

			['QUEST_QUERY_COMPLETE'] = function(self, frame, arg1)
				self:_ProcessServerQuests()
				-- If a book was just read, diff against the pre-read backup to find
				-- any quests the server newly marked complete.
				if nil ~= self.pendingBookReadContext then
					local ctx = self.pendingBookReadContext
					self.pendingBookReadContext = nil
					local newlyCompleted = {}
					self:_ProcessServerCompare(newlyCompleted)
					for _, qId in pairs(newlyCompleted) do
						if qId ~= ctx.knownQuest then   -- avoid double-marking
							self:_MarkQuestComplete(qId, true)
						end
						local msg = strformat("Book read completes %d | Target: %s (%d) | Coords: %s", qId, tostring(ctx.targetName), tonumber(ctx.npcId) or -1, tostring(ctx.coordinates))
						if self.GDE.debug then
							print(msg)
						end
						self:_AddTrackingMessage(msg)
					end
					self:_ProcessServerBackup(true)        -- update snapshot for next book read
					self.doneProcessingBookBackup = false  -- allow ITEM_TEXT_BEGIN to snapshot again
				end
			end,

			['QUEST_REMOVED'] = function(self, frame, questId)
				-- this happens for both abandon and turn-in
				-- and turn-in is first, so we can know we are abandoning or not
				if nil == self.questTurningIn then
					self:_QuestAbandon(questId)
				end
				-- >>>VIGNETTE_DEBUG
				if nil ~= self._vignetteSnapshotBefore then
					self:_VignetteCompareAndLog(self._vignetteSnapshotBefore, self:_VignetteSnapshot(), self._vignetteSnapshotLabel or 'QUEST_REMOVED')
					self._vignetteSnapshotBefore = nil
				end
				self._vignetteSnapshotLabel  = nil
				-- >>>VIGNETTE_DEBUG_END
				-- >>>QUESTPIN_DEBUG
				do
					local _poolCurrent = self:_QuestPinPoolSnapshot()
					do
						local _bSize, _pSize = 0, 0
						if self._questPinSnapshotBefore then for _ in pairs(self._questPinSnapshotBefore) do _bSize=_bSize+1 end end
						for _ in pairs(_poolCurrent) do _pSize=_pSize+1 end
						print(strformat('QUESTPIN_REMOVED_DEBUG: snapshotBefore=%s(%d) pool=%d trigger=%s',
							tostring(self._questPinSnapshotBefore ~= nil), _bSize, _pSize, tostring(self._questPinTrigger)))
					end
					if nil ~= self._questPinSnapshotBefore then
						self:_QuestPinCompareAndRecord(self._questPinSnapshotBefore, _poolCurrent,
							self._questPinTrigger or 'QUEST_REMOVED', self._questPinTriggerDetail)
						self._questPinSnapshotBefore, self._questPinTrigger, self._questPinTriggerDetail = nil, nil, nil
					end
					-- Update persistent snapshot (pool-only) so AREA_POIS_UPDATED can diff against it
					self._persistentPinSnapshot = _poolCurrent
				end
					-- >>>QUESTPIN_DEBUG: delayed scans to catch pins that appear after map opens
					local _turnedInId = self.questTurningIn
					-- Capture the before-snapshot once for all delays
					local _delayedBase = self._persistentPinSnapshot or {}
				local _self = self
					if C_Timer and C_Timer.After then
						for _, delay in ipairs({1.0, 3.0, 7.0, 15.0}) do
							C_Timer.After(delay, function()
								local _pinNow = _self:_QuestPinPoolSnapshot()
								local _base   = _delayedBase
								local _found  = 0
								local _nowSize, _baseSize = 0, 0
								for _ in pairs(_pinNow) do _nowSize=_nowSize+1 end
								for _ in pairs(_base) do _baseSize=_baseSize+1 end
								-- Check for appeared pins
								for key, info in pairs(_pinNow) do
									if not _base[key] then
										_found = _found + 1
										local detail = strformat('quest=%s delay=%.1fs', tostring(_turnedInId), delay)
										local cnt = _self:_QuestPinCompareAndRecord({}, { [key]=info },
											'QUEST_TURNED_IN_DELAYED', detail)
										if cnt > 0 then
											print(strformat('QUESTPIN_DELAYED: found pin=%s name=%s after %.1fs (quest=%s)',
												key, tostring(info.name), delay, tostring(_turnedInId)))
										end
										_base[key] = info
									end
								end
								-- Check for disappeared pins (pin was in persistent snapshot but gone now)
								if delay == 1.0 then
									local detail = strformat('quest=%s delay=%.1fs', tostring(_turnedInId), delay)
									for key, info in pairs(_base) do
										if not _pinNow[key] then
											_self:_QuestPinCompareAndRecord({ [key]=info }, {},
												'QUEST_TURNED_IN_DELAYED', detail)
											print(strformat('QUESTPIN_DELAYED: disappeared pin=%s after %.1fs (quest=%s)',
												key, delay, tostring(_turnedInId)))
										end
									end
								end
								print(strformat('QUESTPIN_DELAYED: %.1fs quest=%s found=%d now=%d base=%d',
									delay, tostring(_turnedInId), _found, _nowSize, _baseSize))
								-- Update persistent snapshot but not _delayedBase so later delays still catch new pins
								_self._persistentPinSnapshot = _pinNow
							end)
						end
					end
					-- >>>QUESTPIN_DEBUG_END
				self.questTurningIn = nil
				self.pendingRepChanges = nil
			end,

			-- >>>WARBAND_DEBUG
			['CRITERIA_UPDATE'] = function(self, frame, ...)
				self:_CheckWarbandQuestChanges('CRITERIA_UPDATE')
			end,
			['QUEST_WATCH_UPDATE'] = function(self, frame, ...)
				self:_CheckWarbandQuestChanges('QUEST_WATCH_UPDATE')
			end,
			-- >>>WARBAND_DEBUG_END

			['QUEST_TURNED_IN'] = function(self, frame, questId, xp, money)
				self.questTurningIn = questId
				-- >>>VIGNETTE_DEBUG
				self._vignetteSnapshotBefore = self:_VignetteSnapshot()
				self._vignetteSnapshotLabel  = strformat('QUEST_TURNED_IN quest=%d', questId)
				-- >>>VIGNETTE_DEBUG_END
				-- >>>QUESTPIN_DEBUG
					-- Use persistent snapshot as before-state: pool pin is already gone when QUEST_TURNED_IN fires
					self._questPinSnapshotBefore = self._persistentPinSnapshot or self:_QuestPinPoolSnapshot()
				self._questPinTrigger        = 'QUEST_TURNED_IN'
				self._questPinTriggerDetail  = strformat('quest=%d', questId)
				-- Store pending quest for async pin→quest reverse lookup
				self._recentlyCompletedQuestIds = self._recentlyCompletedQuestIds or {}
				self._recentlyCompletedQuestIds[questId] = GetTime()
				-- >>>QUESTPIN_DEBUG_END
				-- Consume any rep changes buffered from CHAT_MSG_COMBAT_FACTION_CHANGE
				-- (which fires before this event).
				if nil ~= self.pendingRepChanges then
					local now = GetTime()
					for _, entry in ipairs(self.pendingRepChanges) do
						if now - entry.time <= 2 then
							self:_LearnQuestReputation(questId, self:_ResolveFactionId(entry.factionName), entry.amount)
						end
					end
					self.pendingRepChanges = nil
				end
				self:_QuestCompleteProcess(questId)
				self:_UpdateQuestResetTime()
				-- If this is a ?-marked prereq for any target quest, record it as the most
				-- recent turn-in so _LearnPrereqVerification can identify the trigger prereq.
				local targets = self.verifyWatchedBy[questId]
				if targets then
					for _, targetQuestId in ipairs(targets) do
						local unverified = self.questUnverifiedPrereqs[targetQuestId]
						if unverified then
							for _, uid in ipairs(unverified) do
								if uid == questId then
									self.recentPrereqTurnIn[targetQuestId] = questId
									break
								end
							end
						end
					end
				end
			end,

			['GARRISON TALENT COMPLETE'] = function(self, frame, garrTypeID, doAlert)
				if self.GDE.debug then
					print("GARRISON TALENT COMPLETE garrTypeID: %s & doAlert: %s", garrTypeID, doAlert)
				end
			end,

			['GARRISON TALENT EVENT UPDATE'] = function(self, frame, garrTypeID)
				if self.GDE.debug then
					print("GARRISON_TALENT_UPDATE: garrTypeID %d ", garrTypeID)
				end
			end,

			['GARRISON TALENT RESEARCH STARTED'] = function(self, frame, garrTypeID, garrisonTalentTreeID, garrTalentID)
				if self.GDE.debug then
					print("GARRISON TALENT RESEARCH STARTED: garrTypeID: %d , garrisonTalentTreeID %d, garrTalentID: %d", garrTypeID, garrisonTalentTreeID, garrTalentID )
				end
			end,

			['GARRISON TALENT UNLOCKS RESULT'] = function(self, frame)
				if self.GDE.debug then
					print("GARRISON_TALENT_UNLOCKS_RESULT")
				end
			end,

			['GARRISON TALENT UPDATE'] = function(self, frame, garrTypeID)
				if self.GDE.debug then
					print("GARRISON TALENT UPDATE: garrTypeID:%d", garrTypeID)
				end
			end,

			['SKILL_LINES_CHANGED'] = function(self, frame)
				if not self.inCombat or not self.GDE.delayEvents then
					self:_HandleEventSkillLinesChanged()
				else
					self:_RegisterDelayedEvent(frame, { 'SKILL_LINES_CHANGED' } )
				end
			end,

			['UNIT_AURA'] = function(self, frame, arg1)
				if arg1 == "player" then
					-- Collect all current aura spell IDs in one pass.
					local currentSpellIds = {}
					local i = 1
					while true do
						local name, spellId = self:UnitAura(arg1, i)
						if not name then break end
						local sid = tonumber(spellId)
						if sid then tinsert(currentSpellIds, sid) end
						i = i + 1
					end

					-- Build a cheap sorted fingerprint and skip all work if auras are unchanged.
					table.sort(currentSpellIds)
					local currentKey = table.concat(currentSpellIds, ",")
					if currentKey == self._lastPlayerAuraKey then return end
					self._lastPlayerAuraKey = currentKey

					-- Auras changed: update tracking and invalidate affected caches.
					local spellsToNuke = {}
					if nil == self.spellsToHandle then self.spellsToHandle = {} end
					self.spellsJustHandled = {}
					for _, spellId in ipairs(currentSpellIds) do
						self:_MarkQuestInDatabase(spellId, GrailDatabasePlayer["buffsExperienced"])
						if nil ~= self.questStatusCache['B'][spellId] or nil ~= self.questStatusCache['Y'][spellId] then
							if not tContains(spellsToNuke, spellId) then tinsert(spellsToNuke, spellId) end
							self.spellsToHandle[spellId] = true
							self.spellsJustHandled[spellId] = true
						end
					end
					for spellId, _ in pairs(self.spellsToHandle) do
						if not self.spellsJustHandled[spellId] then
							if not tContains(spellsToNuke, spellId) then tinsert(spellsToNuke, spellId) end
							self.spellsToHandle[spellId] = nil
						end
					end
					if not self.inCombat or not self.GDE.delayEvents then
						for i = 1, #spellsToNuke do
							self:_StatusCodeInvalidate(self.questStatusCache['B'][spellsToNuke[i]])
							self:_StatusCodeInvalidate(self.questStatusCache['Y'][spellsToNuke[i]])
							self:_NPCLocationInvalidate(self.npcStatusCache['B'][spellsToNuke[i]])
							self:_NPCLocationInvalidate(self.npcStatusCache['Y'][spellsToNuke[i]])
						end
					else
						self:_RegisterDelayedEvent(frame, { 'UNIT_AURA', spellsToNuke } )
					end
				end
			end,

			['UNIT_QUEST_LOG_CHANGED'] = function(self, frame, arg1)
				if arg1 == "player" then
					if not self.inCombat or not self.GDE.delayEvents then
						self:_PostDelayedNotification("QuestLogChange", 0, 0.5)
					else
						self:_RegisterDelayedEvent(frame, { 'UNIT_QUEST_LOG_CHANGED' } )
					end
				end
			end,

			['UNIT_SPELLCAST_SUCCEEDED'] = function(self, frame, unit, spellName, noLongerValidRank, lineId, spellId)
				if unit == "player" then
					if self.battleForAzeroth then
						-- Blizzard now returns a lineId and spellId instead of its normal parameters
						-- and the lineId has an extra item at the start "Cast".
						lineId = spellName	-- even though we need not use it now
						spellId = noLongerValidRank
					elseif self.existsLegion then
						--	Blizzard no longers returns a spellId, but a lineId that needs to be parsed
						local numberThree, serverId, instanceId, zoneUID, realSpellId, castUID = strsplit("-", lineId)
						spellId = realSpellId
						--	Reading Artifact Research Notes raises the knowledge level, so we need to handle this
						if tonumber(spellId) == 219978 then
							local _, level = self:GetCurrencyInfo(1171)
							self:ArtifactChange(level)
						end
					end
					self:_MarkQuestInDatabase(spellId, GrailDatabasePlayer["spellsCast"])
					if nil ~= self.questStatusCache and nil ~= self.questStatusCache['Z'] then
						if not self.inCombat or not self.GDE.delayEvents then
							self:_StatusCodeInvalidate(self.questStatusCache['Z'][spellId])
							self:_NPCLocationInvalidate(self.npcStatusCache['Z'][spellId])
						else
							self:_RegisterDelayedEvent(frame, { 'UNIT_SPELLCAST_SUCCEEDED', spellId } )
						end
					end
				end
			end,

--			['ZONE_CHANGED_NEW_AREA'] = function(self, frame)
--				self:_UpdateQuestResetTime()	-- moved here from ADDON_LOADED in the hopes that here GetQuestResetTime() will always return a real value
--				frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
--			end,

			},
		-- WOW_PROJECT_ID can have the following values:
		--		WOW_PROJECT_MAINLINE (1)
		--		WOW_PROJECT_CLASSIC (2)
		--		WOW_PROJECT_BURNING_CRUSADE_CLASSIC (5)
		--		WOW_PROJECT_WRATH_CLASSIC (11)
		--		WOW_PROJECT_CATACLYSM_CLASSIC (14)
		-- LE_EXPANSION_LEVEL_CURRENT can have the following values:
		--		LE_EXPANSION_CLASSIC (0)
		--		LE_EXPANSION_BURNING_CRUSADE (1)
		--		LE_EXPANSION_WRATH_OF_THE_LICH_KING (2)
		--		LE_EXPANSION_CATACLYSM (3)
		--		LE_EXPANSION_MISTS_OF_PANDARIA (4)
		--		LE_EXPANSION_WARLORDS_OF_DRAENOR (5)
		--		LE_EXPANSION_LEGION (6)
		--		LE_EXPANSION_BATTLE_FOR_AZEROTH (7)
		--		LE_EXPANSION_SHADOWLANDS (8)
		--		LE_EXPANSION_DRAGONFLIGHT (9)
		--	one of the LE_EXPANSION... values is returned from GetMaximumExpansionLevel() (which is from C_Expansion)
		--	The maximum character level in any expansion is gotten from: maxLevel = GetMaxLevelForExpansionLevel(expansionLevel)
		--	For Classic, we should be able to use GetClassicExpansionLevel()
		--	calling GetClassicExpansionLevel() in Mainline returns 9 (because I am in Dragonflight)
		--
		--	There are currently (2026-03-08), four different LIVE games
		--		World of Warcraft					WOW_PROJECT_ID = 1  (WOW_PROJECT_MAINLINE)
		--		World of Warcraft Classic			WOW_PROJECT_ID = 2	(WOW_PROJECT_CLASSIC)
		--		Burning Crusade Anniversary			WOW_PROJECT_ID = 5	(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
		--		Mists of Pandaria Classic			WOW_PROJECT_ID = 19	(WOW_PROJECT_MISTS_CLASSIC)
		--	It appears we have the normal World of Warcraft, Wolrd of Warcraft Classic, the latest "Classic" version which marches through games, and then possible "Anniversary" editions.
		--	Therefore, we should have
		--		_retail_							WOW_PROJECT_ID = 1
		--		_classic_era_						WOW_PROJECT_ID = 2
		--		_classic_							WOW_PROJECT_ID = the latest one being used (basically not 1, 2 or any anniversary)
		--		_anniversary_						WOW_PROJECT_ID = 5
		existsClassicBasic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC),
		-- I don't think we need to know about Classic Burning Crusade any more so am removing this...
--		existsClassicBurningCrusade = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC),
		existsClassicWrathOfTheLichKing = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC),
		existsClassicCataclysm = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC),
		existsClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC),	-- _classic_era_	"World of Warcraft Classic"
		existsClassicPandaria = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC),-- "Mist of Pandaria Classic"
		existsClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC),	-- _classic_	"Cataclysm Classic"
		existsMainline = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE),	-- _retail_	"World of Warcraft"
		existsMidnight = (LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_MIDNIGHT),
		factionMapping = { ['A'] = 'Alliance', ['H'] = 'Horde', },
		followerMapping = {},
		forceLocalizedQuestNameLoad = true,
		friendshipLevel = { 'Stranger', 'Acquaintance', 'Buddy', 'Friend', 'Good Friend', 'Best Friend' },
		friendshipMawLevel = { 'Dubious', 'Apprehensive', 'Tentative', 'Ambivalent', 'Cordial', 'Appreciative' },	-- TODO: localize them
		garrisonBuildingLevelMapping = {
			[-8] = "1+", [-9] = "2+", [-24] = "1+", [-25] = "2+", [-26] = "1+", [-27] = "2+",
			[-29] = "1+", [-34] = "1+", [-35] = "2+", [-37] = "1+", [-38] = "2+", [-40] = "1+",
			[-41] = "2+", [-42] = "1+", [-51] = "1+", [-52] = "1+", [-60] = "1+", [-61] = "1+",
			[-62] = "2+", [-64] = "1+", [-65] = "1+", [-66] = "2+", [-76] = "1+", [-90] = "1+",
			[-91] = "1+", [-93] = "1+", [-94] = "1+", [-95] = "1+", [-96] = "1+", [-111] = "1+",
			[-117] = "2+", [-119] = "2+", [-121] = "2+", [-123] = "2+", [-125] = "2+", [-127] = "2+",
			[-129] = "2+", [-131] = "2+", [-134] = "2+", [-136] = "2+", [-140] = "2+", [-142] = "2+",
			[-144] = "2+", [-159] = "1+", [-160] = "2+", [-162] = "1+", [-163] = "2+", [-167] = "2+",
			[8] = "1", [9] = "2", [10] = "3",
			[24] = "1", [25] = "2", [133] = "3",
			[26] = "1", [27] = "2", [28] = "3",
			[29] = "1", [136] = "2", [137] = "3",
			[34] = "1", [35] = "2", [36] = "3",
			[37] = "1", [38] = "2", [39] = "3",
			[40] = "1", [41] = "2", [138] = "3",
			[42] = "1", [167] = "2", [168] = "3",
			[51] = "1", [142] = "2", [143] = "3",
			[52] = "1", [140] = "2", [141] = "3",
			[60] = "1", [117] = "2", [118] = "3",
			[61] = "1", [62] = "2", [63] = "3",
			[64] = "1", [134] = "2", [135] = "3",
			[65] = "1", [66] = "2", [67] = "3",
			[76] = "1", [119] = "2", [120] = "3",
			[90] = "1", [121] = "2", [122] = "3",
			[91] = "1", [123] = "2", [124] = "3",
			[93] = "1", [125] = "2", [126] = "3",
			[94] = "1", [127] = "2", [128] = "3",
			[95] = "1", [129] = "2", [130] = "3",
			[96] = "1", [131] = "2", [132] = "3",
			[111] = "1", [144] = "2", [145] = "3",
			[159] = "1", [160] = "2", [161] = "3",
			[162] = "1", [163] = "2", [164] = "3",
		},
		garrisonBuildingMapping = {
			[-8] = { 8, 9, 10 },		-- Armory
			[-9] = { 9, 10 },
			[-24] = { 24, 25, 133 },	-- Barn
			[-25] = { 25, 133 },
			[-26] = { 26, 27, 28 },		-- Barracks
			[-27] = { 27, 28 },
			[-29] = { 29, 136, 137 },	-- Farm
			[-34] = { 34, 35, 36 },		-- Inn
			[-35] = { 35, 36 },
			[-37] = { 37, 38, 39 },		-- Mage Tower
			[-38] = { 38, 39 },
			[-40] = { 40, 41, 138 },	-- Lumber Mill
			[-41] = { 41, 138 },
			[-42] = { 42, 167, 168 },	-- Pet Menagerie
			[-51] = { 51, 142, 143 },	-- Storehouse
			[-52] = { 52, 140, 141 },	-- Salvage Yard
			[-60] = { 60, 117, 118 },	-- Forge
			[-61] = { 61, 62, 63 },		-- Mine
			[-62] = { 62, 63 },
			[-64] = { 64, 134, 135 },	-- Fishing
			[-65] = { 65, 66, 67 },		-- Stables
			[-66] = { 66, 67 },
			[-76] = { 76, 119, 120 },	-- Alchemy
			[-90] = { 90, 121, 122 },	-- Leatherworking
			[-91] = { 91, 123, 124 },	-- Engineering
			[-93] = { 93, 125, 126 },	-- Enchanting
			[-94] = { 94, 127, 128 },	-- Tailoring
			[-95] = { 95, 129, 130 },	-- Inscription
			[-96] = { 96, 131, 132 },	-- Jewelcrafting
			[-111] = { 111, 144, 145 },	-- Trading Post
			[-117] = { 117, 118 },
			[-119] = { 119, 120 },
			[-121] = { 121, 122 },
			[-123] = { 123, 124 },
			[-125] = { 125, 126 },
			[-127] = { 127, 128 },
			[-129] = { 129, 130 },
			[-131] = { 131, 132 },
			[-134] = { 134, 135 },
			[-136] = { 136, 137 },
			[-140] = { 140, 141 },
			[-142] = { 142, 143 },
			[-144] = { 144, 145 },
			[-159] = { 159, 160, 161 },	-- Gladiator's Sanctum
			[-160] = { 160, 161 },
			[-162] = { 162, 163, 164 },	-- Gnomish Gearworks
			[-163] = { 163, 164 },
			[-167] = { 167, 168 },
		},
		garrisonType6 = Enum.GarrisonType.Type_6_0 or Enum.GarrisonType.Type_6_0_Garrison or 2,
		garrisonType9 = Enum.GarrisonType.Type_9_0 or Enum.GarrisonType.Type_9_0_Garrison or 111,
		genderMapping = { ['M'] = 2, ['F'] = 3, },
		gossipNPCs = {},
		--
		--	***** Cannot add any more holidays with the current holidayToBitMapping use as we have run out of
		--	***** 32 bits to use.  New holidays will mean new structures to implement.
		--
		holidayMapping = {	['A'] = 'Love is in the Air',
							['B'] = 'Brewfest',
							['C'] = "Children's Week",
							['D'] = 'Day of the Dead',
							['E'] = 'WoW Anniversary',
							['F'] = 'Darkmoon Faire',
							['G'] = 'Speecial used for Darkmoon Faire setup in Classic',
							['H'] = 'Harvest Festival',
							-- I
							-- J
							['K'] = "Kalu'ak Fishing Derby",
							['L'] = 'Lunar Festival',
							['M'] = 'Midsummer Fire Festival',
							['N'] = 'Noblegarden',
							-- O
							['P'] = "Pirates' Day",
							['Q'] = "AQ",
							-- R
							-- S
							-- T
							['U'] = 'New Year',
							['V'] = 'Feast of Winter Veil',
							['W'] = "Hallow's End",
							['X'] = 'Stranglethorn Fishing Extravaganza',
							['Y'] = "Pilgrim's Bounty",
							['Z'] = "Christmas Week",
							['a'] = 'Apexis Bonus Event',
							['b'] = 'Arena Skirmish Bonus Event',
							['c'] = 'Battleground Bonus Event',
							['d'] = 'Draenor Dungeon Event',
							['e'] = 'Pet Battle Bonus Event',
							['f'] = 'Timewalking Dungeon Event',
							-- g automatically assigned Timewalking Dungeon Event - The Burning Crusade
							-- h automatically assigned Timewalking Dungeon Event - Wrath of the Lich King
							-- i automatically assigned Timewalking Dungeon Event - Cataclysm
							-- j automatically assigned Timewalking Dungeon Event - Mists of Pandaria
							-- k automatically assigned Timewalking Dungeon Event - Warlords of Draenor
							-- l automatically assigned Timewalking Dungeon Event - Legion
						},
		--
		--	***** Cannot add any more holidays with the current holidayToBitMapping use as we have run out of
		--	***** 32 bits to use.  New holidays will mean new structures to implement.
		--
		holidayToBitMapping = {	['A'] = 0x00000001,
								['B'] = 0x00000002,
								['C'] = 0x00000004,
								['D'] = 0x00000008,
								['F'] = 0x00000010,
								['H'] = 0x00000020,
								['L'] = 0x00000040,
								['M'] = 0x00000080,
								['N'] = 0x00000100,
								['P'] = 0x00000200,
								['U'] = 0x00000400,
								['V'] = 0x00000800,
								['W'] = 0x00001000,
								['Y'] = 0x00002000,
								['Z'] = 0x00004000,
								['X'] = 0x00008000,
								['K'] = 0x00010000,
								['a'] = 0x00020000,
								['b'] = 0x00040000,
								['c'] = 0x00080000,
								['d'] = 0x00100000,
								['e'] = 0x00200000,
								['f'] = 0x00400000,
								['g'] = 0x00800000,
								['h'] = 0x01000000,
								['i'] = 0x02000000,
								['E'] = 0x04000000,
								['Q'] = 0x08000000,
								['j'] = 0x10000000,
								['k'] = 0x20000000,
								['l'] = 0x40000000,
								['G'] = 0x80000000,
								},
		holidayToMapAreaMapping = { ['HA'] = 100001, ['HB'] = 100002, ['HC'] = 100003, ['HD'] = 100004, ['HE'] = 100005, ['HF'] = 100006, ['HG'] = 100007, ['HH'] = 100008, ['HK'] = 100011, ['HL'] = 100012, ['HM'] = 100013,
				['HN'] = 100014, ['HP'] = 100016, ['HQ'] = 100017, ['HU'] = 100021, ['HV'] = 100022, ['HW'] = 100023, ['HX'] = 100024, ['HY'] = 100025, ['HZ'] = 100026, ['Ha'] = 100027, ['Hb'] = 100028, ['Hc'] = 100029, ['Hd'] = 100030, ['He'] = 100031, ['Hf'] = 100032, ['Hg'] = 100033, ['Hh'] = 100034, ['Hi'] = 100035, ['Hj'] = 100036, ['Hk'] = 100037, ['Hl'] = 100038, },
		indexedQuests = {},
		indexedQuestsExtra = {},
		levelingLevel = nil,	-- this is set during the PLAYER_LEVEL_UP event because UnitLevel() does not work during it
		locationCloseness = 1.55,
		loremasterQuests = {},
		mapAreaBaseAchievement = 500000,
		mapAreaBaseClass = 200000,
		mapAreaBaseDaily = 400000,
		mapAreaBaseHoliday = 100000,
		mapAreaBaseOther = 700000,
		mapAreaBaseProfession = 300000,
		mapAreaBaseReputation = 400000,	-- note that 400000 is used for Daily
		mapAreaBaseReputationChange = 600000,
		mapAreaMapping = {},
--		mapAreaMapping = setmetatable({}, {
--			__index = function(t, id_num)
--				if nil == id_num then id_num = "nil" end
--				return "Error "..id_num
--				end,
--				}),
		mapAreaMaximumAchievement = 599999,
		mapAreaMaximumClass = 299999,
		mapAreaMaximumDaily = 400000,	-- not used since Daily really is only every one area
		mapAreaMaximumHoliday = 199999,
		mapAreaMaximumProfession = 399999,
		mapAreaMaximumReputation = 499999,
		mapAreaMaximumReputationChange = 699999,
		mapAreasWithTreasures = {},	-- index is the mapId, and the value is a table of treasure questIds
		memoryUsage = {},	-- see timings
		nameTaleElders = "Tale of the Elders",
		nameTaleMagmaPact = "Tale of the Magma Pact",
		nameTaleOutsider = "Tale of the Outsider",
		nameTaleSlumbering = "Tale of the Slumbering",
		nameTaleWarlord = "Tale of the Warlord",
		nameTaleWeakling = "Tale of the Weakling",
		nonPatternExperiment = true,

		--	The NPC database contains all we need to know about NPCs with data in specifc tables based on need.
		--	The index into each table is a numeric value of our internal representation of NPC ID.  For the most
		--	part this matches the Blizzard NPC ID, but we have alias NPCs, as well as mapping game objects and
		--	items into our NPC IDs as well.  The convenience APIs allow using Blizzard IDs for game object and
		--	items which will access the internal data structure using our modified NPC IDs.
		npc = {

			-- Possible list of NPCs that are aliases of the key.
			aliases = {},

			-- The localized comment for the NPC.
			-- This is sparsely populated, as most NPCs will not have a comment.
			comment = {},

			-- Possible list of NPCs that can drop this item.
			droppedBy = {},

			-- Possible faction affiliation for the NPC.
			-- This is sparsely populated, and the values are the internal representations of factions.
			faction = {},

			-- Possible list of items that the NPC has (basically the reverse of the droppedBy in other NPCs).
			has = {},

			-- Possible indication that NPC is only available in heroic mode.
			heroic = {},

			-- Possible indication that NPC is only available on holidays.  Value
			-- is a string of characters representing holidays, usually only 1 long.
			holiday = {},

			-- Possible indication that the NPC is to be killed.
			kill = {},

			-- Each value contains a table of locations for the NPC.
			locations = {},

			-- The localized name of the NPC.
			-- The only names that get prepopulated from loading files are those of game objects because there is
			-- no Blizzard API that we seem to be able to use to get the localized name of the game object at any
			-- time we want, unlike normal NPCs and items whose name we scrape from a game tooltip.
			name = {},

			-- The actual index value to use when accessing the name table if non-nil is returned.
			-- Normally the actual NPC ID is used because a lookup of most NPC IDs in this table will return nil.
			-- However, there are some alias NPCs, and others that use names of other NPCs which return a non-nil
			-- value which is used by the internal routines to get the proper localized name.
			nameIndex = {},

			-- This is a special table for items that are associated with quests for use with tooltips.
			-- This is sparsely populated.  It does not reflect the quests most NPCs are associated with.  Each
			-- value contains a table of quest IDs.
			questAssociations = {},

			},

		quest = {

			-- Note that Grail.questCodes is where we put all the codes associated with quests.  This could be used
			-- to control access to what quests are available since we want a code for each quest, even if it were
			-- an empty code.

			-- The localized name of the quest.
			-- This is dynamically populated as requests are made to show the quest name.  However, if someone were
			-- to load one of the loadable addons of quest names, they would replace the contents of this table with
			-- entries from the loadable addon.
			-- The initial population of a few quests that are actually artifically
			-- created to support some complicated prerequisites.
			name = {
			--	[600000]='Blasted Lands Phase Requirements'
			--	[600001]='Blasted Lands Alliance Phase Requirements'
			--	[600002]='Blasted Lands Horde Phase Requirements'
				},

			-- The localized description of the quest.
			-- This is dynamically populated in Classic and only used there because Blizzard API does not allow us
			-- access to the description in game.
			description = {
				},

			},

		-- A table whose keys represent situations where quests need to be invalidated, and whose values are
		-- the quest IDs to invalidate.
		-- The contents of this table is populated primarily from processing the quest codes associated with each
		-- quest.  During play, specific events happen that may need to have the status of specific quests re-evaluated
		-- and this is accomplished by invalidating the current status only.  When a client needs the current status
		-- it will automatically be re-evaluated.  The keys are numbers with arbitrary values, except for those that
		-- are associated with Blizzard groups (like factions), which are noted.
		invalidateControl = {},

		invalidateGroupHighestValue = 9,

		invalidateGroupWithering = 1,
		invalidateGroupGarrisonBuildings = 2,
		invalidateGroupCurrentWorldQuests = 3,
		invalidateGroupArtifactKnowledge = 4,
		invalidateGroupArtifactLevel = 5,
		invalidateGroupCurrentThreatQuests = 6,
		invalidateGroupCurrentCallingQuests = 7,
		invalidateGroupCurrentGarrisonTalentQuests = 8,
		invalidateGroupRenownQuests = 9,
		invalidateGroupMajorFactionQuests = 10,
		invalidateGroupAreaPOIQuests = 11,
		invalidateGroupBaseAchievement = 1000000,	-- the actual achievement ID is added to this
		invalidateGroupBaseBuff = 2000000,	-- the actual buff ID is added to this
		invalidateGroupBaseItem = 3000000,	-- the actual item ID is added to this

						-- quests is a table whose indexes are questIds and values are the actual bit mask status
						-- A is a table whose key is an achievement ID and whose value is a table of quests assocaited with it
						-- B is a table whose key is a buff ID and whose value is a table of quests associated with it
						-- C is a table whose key is an item ID whose presence is needed and whose value is a table of quests associated with it
						-- D is a table whose indexes are questIds and values are tables of questIds that need to be invalidated when the index is no longer in the quest log
						-- E is a table whose key is an item ID whose presence is NOT wanted and whose value is a table of quests associated with it
						-- F is a table whose key is a questId that when abandoned needs to have the table of associated quests invalidated
						-- G is a table whose key is a group number and whose value is a table of quests associated with it
						-- H is a table whose key is a questId and whose value is a table of groups associated with it
						-- I is a table whose indexes are questIds and values are tables of questIds that suffer bitMaskInvalidated from the quest that is the index
						-- L is a table of questIds who fail because of bitMaskLevelTooLow
						-- M is a table of questIds that require garrison buildings
						-- P is a table of questIds who fail because of bitMaskProfession
						-- Q is a table whose indexes are questIds and values are tables of questIds that suffer bitMaskPrerequisites from the quest that is the index
						-- R is a table of questIds who fail because of bitMaskReputation
						-- S is a table whose key is a spellId whose presence is needed and whose value is a table of quests associated with it
						-- V is a table of questIds for quests that are NOT marked bitMaskLowLevel because gaining levels can change that value
						-- W is a table whose key is a group number and whose value is a table of quests interested in that group.  this differs from G because that is a list of all quests in the group
						-- X is a table whose key is a group number and whose value is a table of quests interested in that group for accepting.
						-- Y is a table whose key is a spellId that has ever been experienced and whose value is a table of quests associated with it
						-- Z is a table whose key is a spellId that has ever been cast and whose value is a table of quests associated with it

		npcNames = {},
		observers = { },
		origAbandonQuestFunction = nil,
		origConfirmAbandonQuestFunction = nil,
		playerClass = nil,
		playerFaction = nil,
		playerGender = nil,
		playerLocale = GetLocale(),
		playerName = nil,
		playerRace = nil,
		playerRealm = nil,
		professionMapping = {
			A = 'Alchemy',
			B = 'Blacksmithing',
			C = PROFESSIONS_COOKING,	-- "Cooking"
			E = 'Enchanting',
			F = PROFESSIONS_FISHING,	-- "Fishing"
			H = 'Herbalism',
			I = 'Inscription',		-- probably could use INSCRIPTION
			J = 'Jewelcrafting',
			L = 'Leatherworking',
			M = 'Mining',
			N = 'Engineering',
			R = 'Riding',
			S = 'Skinning',
			T = 'Tailoring',
			X = PROFESSIONS_ARCHAEOLOGY,	-- "Archaeology"
			Z = PROFESSIONS_FIRST_AID,	-- "First Aid"
			},
		professionToMapAreaMapping = { ['PA'] = 300001, ['PB'] = 300002, ['PC'] = 300003, ['PE'] = 300005, ['PF'] = 300006, ['PH'] = 300008, ['PI'] = 300009, ['PJ'] = 300010, ['PL'] = 300012, ['PM'] = 300013, ['PN'] = 300014, ['PP'] = 300016, ['PR'] = 300018, ['PS'] = 300019, ['PT'] = 300020, ['PU'] = 300021, ['PX'] = 300024, ['PZ'] = 300043, },
		questBits = {},					-- key is the questId, and value is a string that represents integers of bits
		questCodes = {},
--		questNames = {},
--		questNPCId = nil,
		questPrerequisites = {},
		questUnverifiedPrereqs = {},		-- key is questId, value is ordered table of prereq questIds marked with ? in the P: code
		questVerifyAllPrereqs = {},			-- key is questId, value is table of ALL bare integer prereq questIds when any are unverified; used to build verifyWatchedBy
		verifyWatchedBy = {},				-- key is a prereq questId, value is table of target questIds that have unverified prereqs and include this prereq; built lazily in _CodeAllFixed
		recentPrereqTurnIn = {},			-- key is targetQuestId, value is the most recent ?-marked prereq questId turned in before targetQuestId appeared at an NPC
		questReputationRequirements = {},	-- key is questId, value is a string of 4-character codes appended to each other, ignoring specific aspects of the P: code positions
		questReputations = {},			-- the table after the initial load is processed
		questResetTime = 0,
		quests = {},
		questsNoLongerAvailable = {},	-- quests with a Z code that has passed
		questsNotYetAvailable = {},		-- quests with an E code that has not yet happened
		questStatuses = {},				-- computed on demand
		races = {
			-- [1] is Blizzard API return (non-localized)
			-- [2] is localized male
			-- [3] is localized female
			-- [4] is bitmap value
			['A'] = { 'Pandaren', 'Pandaren',  'Pandaren',  0x08000000 },
			['B'] = { 'BloodElf', 'Blood Elf', 'Blood Elf', 0x02000000 },
			['C'] = { 'DarkIronDwarf', 'Dark Iron Dwarf', 'Dark Iron Dwarf', 0x00000004 },
			['D'] = { 'Draenei',  'Draenei',   'Draenei',   0x00080000 },
			['E'] = { 'NightElf', 'Night Elf', 'Night Elf', 0x00020000 },
			['F'] = { 'Dwarf',    'Dwarf',     'Dwarf',     0x00010000 },
			['G'] = { 'Goblin',   'Goblin',    'Goblin',    0x04000000 },
			['H'] = { 'Human',    'Human',     'Human',     0x00008000 },
			['I'] = { 'LightforgedDraenei', 'Lightforged Draenei', 'Lightforged Draenei', 0x40000000 },
			['J'] = { 'MagharOrc', "Mag'har Orc", "Mag'har Orc", 0x00000008 },
			['K'] = { 'KulTiran', "Kul'Tiran", "Kul'Tiran", 0x80000000 },
			['L'] = { 'Troll',    'Troll',     'Troll',     0x01000000 },
			['M'] = { 'HighmountainTauren', 'Highmountain Tauren', 'Highmountain Tauren', 0x00000001 },
			['N'] = { 'Gnome',    'Gnome',     'Gnome',     0x00040000 },
			['O'] = { 'Orc',      'Orc',       'Orc',       0x00200000 },
-- Do not ever use P because it will interfere with SP quest code
			['Q'] = { 'Mechagnome', 'Mechagnome', 'Mechagnome', 0x00002000 },
			['R'] = { 'Nightborne', 'Nightborne', 'Nightborne', 0x00000002 },
			['S'] = { 'Vulpera', 'Vulpera', 'Vulpera', 0x00004000 },
			['T'] = { 'Tauren',   'Tauren',    'Tauren',    0x00800000 },
			['U'] = { 'Scourge',  'Undead',    'Undead',    0x00400000 },
			['V'] = { 'VoidElf',  'Void Elf',  'Void Elf',	0x20000000 },
			['W'] = { 'Worgen',   'Worgen',    'Worgen',    0x00100000 },
			['X'] = { 'EarthenDwarf',  'Earthen',   'Earthen',   0x00000800 },
			['Y'] = { 'Dracthyr', 'Dracthyr',  'Dracthyr',	0x00001000 },
			['Z'] = { 'ZandalariTroll', 'Zandalari Troll', 'Zandalari Troll', 0x10000000 },
			['h'] = { 'Harronir', 'Haranir', 'Haranir', 0x00000010 }
			},
		receivedCalendarUpdateEventList = false,
		receivedQuestLogUpdate = false,

		reputationBodyGuards = {
			["6C5"] = 'Delvar Ironfist',
			["6C8"] = 'Tormmok',
			["6C9"] = 'Talonpriest Ishaal',
			["6CA"] = 'Defender Illona',
			["6CB"] = 'Vivianne',
			["6CC"] = 'Aeda Brightdawn',
			["6CD"] = 'Leorajh',
			},

		reputationBodyGuardLevelMapping = { [41999] = 1, [51999] = 2, [61999] = 3 },

		--	The reputation values are the actual faction values used by Blizzard.
		reputationExpansionMapping = {
			[1] = { 69, 54, 47, 72, 930, 1134, 530, 76, 81, 68, 911, 1133, 509, 890, 730, 510, 729, 889, 21, 577, 369, 470, 910, 609, 749, 990, 270, 529, 87, 909, 92, 989, 93, 349, 809, 70, 59, 576, 922, 967, 589, 469, 67, 471, 893, 550, 551, 549, 83, 86, },
			[2] = { 942, 946, 978, 941, 1038, 1015, 970, 933, 947, 1011, 1031, 1077, 932, 934, 935, 1156, 1012, 936, },
			[3] = { 1037, 1106, 1068, 1104, 1126, 1067, 1052, 1073, 1097, 1098, 1105, 1117, 1119, 1064, 1050, 1085, 1091, 1090, 1094, 1124, },
			[4] = { 1158, 1173, 1135, 1171, 1174, 1178, 1172, 1177, 1204, },
			[5] = { 1216, 1351, 1270, 1277, 1275, 1283, 1282, 1228, 1281, 1269, 1279, 1243, 1273, 1358, 1276, 1271, 1242, 1278, 1302, 1341, 1337, 1345, 1272, 1280, 1352, 1357, 1353, 1359, 1375, 1376, 1387, 1388, 1435, 1492, },
			[6] = { 1445, 1515, 1520, 1679, 1681, 1682, 1708, 1710, 1711, 1731, 1732, 1733, 1735, 1736, 1737, 1738, 1739, 1740, 1741, 1847, 1848, 1849, 1850, },
			[7] = { 1815, 1828, 1833, 1859, 1860, 1862, 1883, 1888, 1894, 1899, 1900, 1919, 1947, 1948, 1975, 1984, 1989, 2018, 2045, 2097, 2098, 2099, 2100, 2101, 2102, 2135, 2165, 2170, },
			[8] = { 2103, 2111, 2120, 2156, 2157, 2158, 2159, 2160, 2161, 2162, 2163, 2164, 2233, 2264, 2265, 2371, 2372, 2373, 2374, 2375, 2376, 2377, 2378, 2379, 2380, 2381, 2382, 2383, 2384, 2385, 2386, 2387, 2388, 2389, 2390, 2391, 2392, 2395, 2396, 2397, 2398, 2400, 2401, 2415, 2417, 2427, },
			[9] = { 2407, 2410, 2413, 2432, 2439, 2445, 2446, 2447, 2448, 2449, 2450, 2451, 2452, 2453, 2454, 2455, 2456, 2457, 2458, 2459, 2460, 2461, 2462, 2463, 2464, 2465, 2469, 2470, 2472, 2478, },
			[10] = { 2503, 2507, 2509, 2510, 2511, 2512, 2513, 2517, 2518, 2520, 2522, 2523, 2524, 2526, 2542, 2544, 2550, 2553, 2554, 2555, 2557, 2564, 2568, 2574, 2593, 2615, },
			[11] = { 2569, 2570, 2590, 2594, 2600, 2601, 2605, 2607, 2640, 2644, 2645, 2653, 2658, 2663, 2664, 2665, 2666, 2669, 2671, 2673, 2675, 2677, 2683, 2685, 2688, 2693, 2722, 2736, 2739, 2766, 2767, }, -- TWW
			[12] = { 2696, 2698, 2699, 2704, 2710, 2711, 2712, 2713, 2714, 2742, 2744, 2764, 2770, },	-- Midnight
			},

		-- These reputations use the friendship names instead of normal reputation names
		reputationFriends = {
			["4F9"] = 'Jogu the Drunk',
			["4FB"] = 'Ella',
			["4FC"] = 'Old Hillpaw',
			["4FD"] = 'Chee Chee',
			["4FE"] = 'Sho',
			["4FF"] = 'Haohan Mudclaw',
			["500"] = 'Tina Mudclaw',
			["501"] = 'Gina Mudclaw',
			["502"] = 'Fish Fellreed',
			["503"] = 'Farmer Fung',
			["54D"] = 'Nomi',
			["54E"] = 'Nat Pagle',
			},

		reputationFriendshipLevelMapping = { [41999] = 1, [50399] = 2, [58799] = 3, [67199] = 4, [75599] = 5, [83999] = 6,
											[55439] = 2005040, [71430] = 4004231, [79925] = 5004326,
											},

		reputationFriendsMaw = {
			["980"] = "Ve'nari",
			},

		reputationFriendshipMawLevelMapping = { [0] = 1, [1000] = 2, [7000] = 3, [14000] = 4, [21000] = 5, [42000] = 6, },

		--	The keys are the boundary values for specific reputation names.  Up to 8 indicates the names used for reputations.
		--	For values > 100 the reputation level is the value / 1000000 and the value mod 1000000 is how much over is
		--	required.
		reputationLevelMapping = { [0] = 1, [35999] = 2, [38999] = 3, [41999] = 4, [44999] = 5, [50999] = 6, [62999] = 7, [83999] = 8, [84998] = 8,
									-- And now for those funky values for the Tillers reputation requirements...
									[56599] = 6005600, [67250] = 7004251, [71498] = 7008499, [75599] = 7012600, [79799] = 7016800, [82999] = 7020000,
									-- And now for assume Klaxxi reputation requirements...
									[55999] = 6005000,
									-- And now for Operation: Shieldwall
									[45949] = 5000950, [49899] = 5004900, [53849] = 6002850, [57799] = 6006800, [61749] = 6010750, [65699] = 7002700,
									[69649] = 7006650, [71661] = 7008662, [77549] = 7014550, [81499] = 7018500,
									--	And now for Nightfallen
									[46749] = 5001750, [58999] = 6008000, [69999] = 7007000,
									--	And now for Paragon reputations
									[93999] = 8010000,
									-- And now for 7th Legion
									[49499] = 5004500, [53999] = 6003000, [58499] = 6007500,
									-- And now for Darmnoon Faire in Classic
									[42499] = 4000500, [43099] = 4001100, [43699] = 4001700, [44499] = 4002500,
									},

		--	The keys are the actual faction values used by Blizzard converted into a 3-character hexidecimal value.
		--	The values will be localized at runtime.
		reputationMapping = {
			["015"] = 'Booty Bay',
			["02F"] = 'Ironforge',
			["036"] = 'Gnomeregan',
			["03B"] = 'Thorium Brotherhood',
			["043"] = 'Horde',
			["044"] = 'Undercity',
			["045"] = 'Darnassus',
			["046"] = 'Syndicate',
			["048"] = 'Stormwind',
			["04C"] = 'Orgrimmar',
			["051"] = 'Thunder Bluff',
			["053"] = 'Leatherworking - Elemental',	-- Classic
			["056"] = 'Leatherworking - Dragonscale',	-- Classic
			["057"] = 'Bloodsail Buccaneers',
			["05C"] = 'Gelkis Clan Centaur',
			["05D"] = 'Magram Clan Centaur',
			["0A9"] = 'Steamwheedle Cartel',
			["10E"] = 'Zandalar Tribe',
			["15D"] = 'Ravenholdt',
			["171"] = 'Gadgetzan',
			["1D5"] = 'Alliance',
			["1D6"] = 'Ratchet',
			["1D7"] = "Wildhammer Clan",	-- Classic
			["1FD"] = 'The League of Arathor',
			["1FE"] = 'The Defilers',
			["211"] = 'Argent Dawn',
			["212"] = 'Darkspear Trolls',
			["225"] = 'Leatherworking - Tribal',	-- Classic
			["226"] = "Engineering - Goblin",	-- Classic
			["227"] = "Engineering - Gnome",	-- Classic
			["240"] = 'Timbermaw Hold',
			["241"] = 'Everlook',
			["24D"] = 'Wintersaber Trainers',
			["261"] = 'Cenarion Circle',
			["2D9"] = 'Frostwolf Clan',
			["2DA"] = 'Stormpike Guard',
			["2ED"] = 'Hydraxian Waterlords',
			["329"] = "Shen'dralar",
			["379"] = 'Warsong Outriders',
			["37A"] = 'Silverwing Sentinels',
			["37D"] = "Revantusk Trolls",	-- Classic
			["38D"] = 'Darkmoon Faire',
			["38E"] = 'Brood of Nozdormu',
			["38F"] = 'Silvermoon City',
			["39A"] = 'Tranquillien',
			["3A2"] = 'Exodar',
			["3A4"] = 'The Aldor',
			["3A5"] = 'The Consortium',
			["3A6"] = 'The Scryers',
			["3A7"] = "The Sha'tar",
			["3A8"] = "Shattrath City",
			["3AD"] = "The Mag'har",
			["3AE"] = 'Cenarion Expedition',
			["3B2"] = 'Honor Hold',
			["3B3"] = 'Thrallmar',
			["3C7"] = 'The Violet Eye',
			["3CA"] = 'Sporeggar',
			["3D2"] = 'Kurenai',
			["3DD"] = 'Keepers of Time',
			["3DE"] = 'The Scale of the Sands',
			["3F3"] = 'Lower City',
			["3F4"] = 'Ashtongue Deathsworn',
			["3F7"] = 'Netherwing',
			["407"] = "Sha'tari Skyguard",
			["40D"] = 'Alliance Vanguard',
			["40E"] = "Ogri'la",
			["41A"] = 'Valiance Expedition',
			["41C"] = 'Horde Expedition',
			["428"] = 'The Taunka',
			["42B"] = 'The Hand of Vengeance',
			["42C"] = "Explorers' League",
			["431"] = "The Kalu'ak",
			["435"] = 'Shattered Sun Offensive',
			["43D"] = 'Warsong Offensive',
			["442"] = 'Kirin Tor',
			["443"] = 'The Wyrmrest Accord',
			["446"] = 'The Silver Covenant',
			["449"] = 'Wrath of the Lich King',
			["44A"] = 'Knights of the Ebon Blade',
			["450"] = 'Frenzyheart Tribe',
			["451"] = 'The Oracles',
			["452"] = 'Argent Crusade',
			["45D"] = 'Sholazar Basin',
			["45F"] = 'The Sons of Hodir',
			["464"] = 'The Sunreavers',
			["466"] = 'The Frostborn',
			["46D"] = 'Bilgewater Cartel',
			["46E"] = 'Gilneas',
			["46F"] = 'The Earthen Ring',
			["470"] = 'Tranquilien Conversion',
			["484"] = 'The Ashen Verdict',
			["486"] = 'Guardians of Hyjal',
			["490"] = 'Guild',
			["493"] = 'Therazane',
			["494"] = "Dragonmaw Clan",
			["495"] = 'Ramkahen',
			["496"] = 'Wildhammer Clan',
			["499"] = "Baradin's Wardens",
			["49A"] = "Hellscream's Reach",
			["4B4"] = "Avengers of Hyjal",
			["4C0"] = "Shang Xi's Academy",
			["4CC"] = 'Forest Hozen',
			["4DA"] = 'Pearlfin Jinyu',
			["4DB"] = 'Hozen',
			["4F5"] = 'Golden Lotus',
			["4F6"] = 'Shado-Pan',
			["4F7"] = 'Order of the Cloud Serpent',
			["4F8"] = 'The Tillers',
			["4F9"] = 'Jogu the Drunk',
			["4FB"] = 'Ella',
			["4FC"] = 'Old Hillpaw',
			["4FD"] = 'Chee Chee',
			["4FE"] = 'Sho',
			["4FF"] = 'Haohan Mudclaw',
			["500"] = 'Tina Mudclaw',
			["501"] = 'Gina Mudclaw',
			["502"] = 'Fish Fellreed',
			["503"] = 'Farmer Fung',
			["516"] = 'The Anglers',
			["539"] = 'The Klaxxi',
			["53D"] = 'The August Celestials',
			["541"] = 'The Lorewalkers',
			["547"] = 'The Brewmasters',
			["548"] = 'Huojin Pandaren',
			["549"] = 'Tushui Pandaren',
			["54D"] = 'Nomi',
			["54E"] = 'Nat Pagle',
			["54F"] = 'The Black Prince',
			["55F"] = "Dominance Offensive",
			["560"] = "Operation: Shieldwall",
			["56B"] = "Kirin Tor Offensive",
			["56C"] = "Sunreaver Onslaught",
			["59B"] = "Shado-Pan Assault",
			["5A5"] = "Frostwolf Orcs",
			["5D4"] = "Emperor Shaohao",
			["5EB"] = "Arakkoa Outcasts",
			["5F0"] = "Shadowmoon Exiles",
			["68F"] = "Operation: Aardvark",
			["691"] = "Vol'jin's Spear",
			["692"] = "Wrynn's Vanguard",
			["6AC"] = "Laughing Skull Orcs",
			["6AE"] = "Sha'tari Defense",
			["6AF"] = "Steamwheedle Preservation Society",
			["6B0"] = "GarInvasion_IronHorde",
			["6B1"] = "GarInvasion_ShadowCouncil",
			["6B2"] = "GarInvasion_IronHorde",
			["6B3"] = "GarInvasion_Ogres",
			["6B4"] = "GarInvasion_Primals",
			["6B5"] = "GarInvasion_Breakers",
			["6B6"] = "GarInvasion_ThunderLord",
			["6B7"] = "GarInvasion_Shadowmoon",
			["6C3"] = "Council of Exarchs",
			["6C4"] = "Steamwheedle Draenor Expedition",
			["6C5"] = "Delvar Ironfist",
			["6C7"] = "Barracks Bodyguards",
			["6C8"] = "Tormmok",
			["6C9"] = "Talonpriest Ishaal",
			["6CA"] = "Defender Illona",
			["6CB"] = "Vivianne",
			["6CC"] = "Aeda Brightdawn",
			["6CD"] = "Leorajh",
			["717"] = "Gilnean Survivors",
			["724"] = "Highmountain Tribe",
			["729"]	= "Uncrowned",
			["737"] = "Hand of the Prophet",
			["738"] = "Vol'jin's Headhunters",
			["739"] = "Order of the Awakened",	-- 1849
			["73A"] = "The Saberstalkers",
			["743"] = "The Nightfallen",
			["744"] = "Arcane Thirst (Thalyssra)",
			["746"] = "Arcane Thirst (Oculeth)",
			["75B"] = "Dreamweavers",
			["760"] = "Jandvik Vrykul",
			["766"] = "The Wardens",
			["76B"] = "Moonguard",
			["76C"] = "Court of Farondis",
			["77F"] = "Arcane Thirst (Valtrois)",
			["79B"] = "Illidari",
			["79C"] = "Valarjar",
			["7B7"] = "Conjurer Margoss",
			["7C0"] = "The First Responders",
			["7C5"] = "Moon Guard",
			["7E2"] = "Talon's Vengeance",
			["7FD"] = "Armies of Legionfall",
			["831"] = "Ilyssia of the Waters",
			["832"] = "Keeper Raynae",
			["833"] = "Akule Riverhorn",
			["834"] = "Corbyn",
			["835"] = "Sha'leth",
			["836"] = "Impus",
			["837"] = "Zandalari Empire",
			["83F"] = "Zandalari Dinosaurs",
["848"] = "Unknown",
			["857"] = "Chromie",
			["86C"] = "Talanji's Expedition",	-- 2156
			["86D"] = "The Honorbound",	-- 2157
			["86E"] = "Voldunai",	-- 2158
			["86F"] = "7th Legion",	-- 2159
			["870"] = "Proudmoore Admiralty",	-- 2160
			["871"] = "Order of Embers",	-- 2161
			["872"] = "Storm's Wake",	-- 2162
			["873"] = "Tortollan Seekers",	-- 2163
			["874"] = "Champions of Azeroth",	-- 2164
			["875"] = "Army of the Light",
			["87A"] = "Argussian Reach",
			["8B9"] = "Dino Training - Pterrodax",	-- 2233
			["8D8"] = "Kul Tiras - Drustvar",	-- 2264
			["8D9"] = "Kul Tiras - Stormsong",	-- 2265
			["943"] = "Bizmo's Brawlpub",	-- 2371
			["944"] = "Brawl'gar Arena",	-- 2372
			["945"] = "The Unshackled",	-- 2373
			["946"] = "The Unshackled (Paragon)",	-- 2374
			["947"] = "Hunter Akana",	-- 2375
			["948"] = "Farseer Ori",	-- 2376
			["949"] = "Bladesman Inowari",	-- 2377
			["94A"] = "Zandalari Empire (Paragon)",	-- 2378
			["94B"] = "Proudmoore Admiralty (Paragon)",	-- 2379
			["94C"] = "Talanji's Expedition (Paragon)",	-- 2380
			["94D"] = "Storm's Wake (Paragon)",	-- 2381
			["94E"] = "Voldunai (Paragon)",	-- 2382
			["94F"] = "Order of Embers (Paragon)",	-- 2383
			["950"] = "7th Legion (Paragon)",	-- 2384
			["951"] = "The Honorbound (Paragon)",	-- 2385
			["952"] = "Champions of Azeroth (Paragon)",	-- 2386
			["953"] = "Tortollan Seekers (Paragon)",	-- 2387
			["954"] = "Poen Gillbrack",	-- 2388
			["955"] = "Neri Sharpfin",	-- 2389
			["956"] = "Vim Brineheart",	-- 2390
			["957"] = "Rustbolt Resistance",	-- 2391
			["958"] = "Rustbolt Resistance (Paragon)",	-- 2392
			["95B"] = "Tidebreak Hive",	-- 2395
			["95C"] = "Tidebreak Guardian",	-- 2396
			["95D"] = "Tidebreak Hivemother",	-- 2397
			["95E"] = "Tidebreak Harvester",	-- 2398
			["960"] = "Waveblade Ankoan",	-- 2400
			["961"] = "Waveblade Ankoan (Paragon)",	-- 2401
			["967"] = "The Ascended", -- 2407
			["96A"] = "The Undying Army", -- 2410
			["96D"] = "Court of Harvesters", -- 2413
			["96F"] = "Rajani", -- 2415
			["971"] = "Uldum Accord", -- 2417
			["976"] = "Night Fae", -- 2422
			["97B"] = "Aqir Hatchling", -- 2427
			["980"] = "Ve'nari", -- 2432
			["987"] = "The Avowed", -- 2439
			["98D"] = "The Ember Court", -- 2445
			["98E"] = "Baroness Vashj", -- 2446
			["98F"] = "Lady Moonberry", -- 2447
			["990"] = "Mikanikos", -- 2448
			["991"] = "The Countess", -- 2449
			["992"] = "Alexandros Mograine", -- 2450
			["993"] = "Hunt-Captain Korayn", -- 2451
			["994"] = "Polemarch Adrestes", -- 2452
			["995"] = "Rendle and Cudgelface", -- 2453
			["996"] = "Choofa", -- 2454
			["997"] = "Cryptkeeper Kassir", -- 2455
			["998"] = "Droman Aliothe", -- 2456
			["999"] = "Grandmaster Vole", -- 2457
			["99A"] = "Kleia and Pelagos", -- 2458
			["99B"] = "Sika", -- 2459
			["99C"] = "Stonehead", -- 2460
			["99D"] = "Plague Deviser Marileth", -- 2461
			["99E"] = "Stitchmasters", -- 2462
			["99F"] = "Marasmius", -- 2463
			["9A0"] = "Court of Night", -- 2464
			["9A1"] = "The Wild Hunt",	-- 2465
            ["9A5"] = "Fractal Lore", -- 2469
			["9A6"] = "Death's Advance", -- 2470
			["9A8"] = "The Archivists' Codex", -- 2472
            ["9AE"] = "The Enlightened", -- 2478
            ["9C7"] = "Maruuk Centaur", -- 2503
            ["9CB"] = "Dragonscale Expedition", -- 2507
            ["9CD"] = "Clan Shikaar", -- 2509
            ["9CE"] = "Valdrakken Accord", -- 2510
            ["9CF"] = "Iskaara Tuskarr", -- 2511
            ["9D0"] = "Clan Aylaag", -- 2512
            ["9D1"] = "Clan Ohn'ir", -- 2513
            ["9D5"] = "Wrathion", -- 2517
            ["9D6"] = "Sabellian", -- 2518
            ["9D8"] = "Clan Nokhud", -- 2520
            ["9DA"] = "Clan Teerai", -- 2522
            ["9DB"] = "Dark Talons", -- 2523
            ["9DC"] = "Obsidian Warders", -- 2524
            ["9DE"] = "Winterpelt Furbolg", -- 2526
            ["9EE"] = "Clan Ukhel", -- 2542
            ["9F0"] = "Artisan's Consortium - Dragon Isles Branch", -- 2544
            ["9F6"] = "Cobalt Assembly", -- 2550
            ["9F9"] = "Soridormi", -- 2553
            ["9FA"] = "Clan Toghus", -- 2554
            ["9FB"] = "Clan Kaighan", -- 2555
            ["9FD"] = "XXX", -- 2557
            ["A04"] = "Loamm Niffen", -- 2564
            ["A08"] = "Glimmerogg Racer", -- 2568
            ["A09"] = "The War Within", -- 2569
            ["A0A"] = "Hallowfall Arathi", -- 2570
            ["A0E"] = "Dream Wardens", -- 2574
            ["A1E"] = "Council of Dornogal", -- 2590
            ["A21"] = "Keg Leg's Crew", -- 2593
            ["A22"] = "The Assembly of the Deeps", -- 2594
            ["A28"] = "The Severed Threads", -- 2600
            ["A29"] = "The Weaver", -- 2601
            ["A2D"] = "The General", -- 2605
            ["A2F"] = "The Vizier", -- 2607
            ["A37"] = "Azerothian Archives", -- 2615
            ["A50"] = "Brann Bronzebeard", -- 2640
            ["A54"] = "Delves: Season 1", -- 2644
            ["A55"] = "Earthen", -- 2645
            ["A5D"] = "The Cartels of Undermine", -- 2653
            ["A62"] = "The K'aresh Trust", -- 2658
            ["A67"] = "Meerah", -- 2663
            ["A68"] = "Flynn Fairwind", -- 2664
            ["A69"] = "Lillistrasza", -- 2665
            ["A6A"] = "Roasts and Boasts", -- 2666
            ["A6D"] = "Darkfuse Solutions", -- 2669
            ["A6F"] = "Venture Company", -- 2671
            ["A71"] = "Bilgewater Cartel", -- 2673
            ["A73"] = "Blackwater Cartel", -- 2675
            ["A75"] = "Steamwheedle Cartel", -- 2677
            ["A7B"] = "Delves: Season 2", -- 2683
            ["A7D"] = "Gallagio Loyalty Rewards Club", -- 2685
            ["A80"] = "Flame's Radiance", -- 2688
            ["A85"] = "Delver's Journey (Season 1)", -- 2693
            ["A88"] = "Amani Tribe", -- 2696
            ["A8A"] = "Midnight", -- 2698
            ["A8B"] = "The Singularity", -- 2699
            ["A90"] = "Hara'ti", -- 2704
            ["A96"] = "Silvermoon Court", -- 2710
            ["A97"] = "Magisters", -- 2711
            ["A98"] = "Blood Knights", -- 2712
            ["A99"] = "Farstriders", -- 2713
            ["A9A"] = "Shades of the Row", -- 2714
            ["AA2"] = "Delves: Season 3", -- 2722
            ["AB0"] = "Manaforge Vandals", -- 2736
            ["AB3"] = "Delves: Coffer Key Shards Conversion", -- 2739
            ["AB6"] = "Delves: Season 1", -- 2742
            ["AB8"] = "Valeera Sanguinar", -- 2744
            ["ACC"] = "Prey: Season 1", -- 2764
            ["ACE"] = "Brawl'gar Arena", -- 2766
            ["ACF"] = "Bizmo's Brawlpub", -- 2767
            ["AD2"] = "Slayer's Duellum", -- 2770
			},

		reputationMappingFaction = {
			["015"] = 'Neutral',
			["02F"] = 'Alliance',
			["036"] = 'Alliance',
			["03B"] = 'Neutral',
			["043"] = 'Horde',
			["044"] = 'Horde',
			["045"] = 'Alliance',
			["046"] = 'Neutral',
			["048"] = 'Alliance',
			["04C"] = 'Horde',
			["051"] = 'Horde',
			["057"] = 'Neutral',
			["05C"] = 'Neutral',
			["05D"] = 'Neutral',
			["0A9"] = 'Neutral',
			["10E"] = 'Neutral',
			["15D"] = 'Neutral',
			["171"] = 'Alliance',
			["1D5"] = 'Alliance',
			["1D6"] = 'Neutral',
			["1FD"] = 'Alliance',
			["1FE"] = 'Horde',
			["211"] = 'Neutral',
			["212"] = 'Horde',
			["240"] = 'Neutral',
			["241"] = 'Neutral',
			["24D"] = 'Alliance',
			["261"] = 'Neutral',
			["2D9"] = 'Horde',
			["2DA"] = 'Alliance',
			["2ED"] = 'Neutral',
			["329"] = 'Neutral',
			["379"] = 'Horde',
			["37A"] = 'Alliance',
			["38D"] = 'Neutral',
			["38E"] = 'Neutral',
			["38F"] = 'Horde',
			["39A"] = 'Horde',
			["3A2"] = 'Alliance',
			["3A4"] = 'Neutral',
			["3A5"] = 'Neutral',
			["3A6"] = 'Neutral',
			["3A7"] = 'Neutral',
			["3A8"] = 'Neutral',
			["3AD"] = 'Horde',
			["3AE"] = 'Neutral',
			["3B2"] = 'Alliance',
			["3B3"] = 'Horde',
			["3C7"] = 'Neutral',
			["3CA"] = 'Neutral',
			["3D2"] = 'Alliance',
			["3DD"] = 'Neutral',
			["3DE"] = 'Neutral',
			["3F3"] = 'Neutral',
			["3F4"] = 'Neutral',
			["3F7"] = 'Neutral',
			["407"] = 'Neutral',
			["40D"] = 'Alliance',
			["40E"] = 'Neutral',
			["41A"] = 'Alliance',
			["41C"] = 'Horde',
			["428"] = 'Horde',
			["42B"] = 'Horde',
			["42C"] = 'Alliance',
			["431"] = 'Neutral',
			["435"] = 'Neutral',
			["43D"] = 'Horde',
			["442"] = 'Neutral',
			["443"] = 'Neutral',
			["446"] = 'Alliance',
			["449"] = 'Neutral',
			["44A"] = 'Neutral',
			["450"] = 'Neutral',
			["451"] = 'Neutral',
			["452"] = 'Neutral',
			["45D"] = 'Neutral',
			["45F"] = 'Neutral',
			["464"] = 'Horde',
			["466"] = 'Alliance',
			["46D"] = 'Horde',
			["46E"] = 'Alliance',
			["46F"] = 'Neutral',
			["470"] = 'Horde',
			["484"] = 'Neutral',
			["486"] = 'Neutral',
			["490"] = 'Neutral',
			["493"] = 'Neutral',
			["494"] = 'Horde',
			["495"] = 'Neutral',
			["496"] = 'Alliance',
			["499"] = 'Alliance',
			["49A"] = 'Horde',
			["4B4"] = 'Neutral',
			["4C0"] = 'Neutral',
			["4CC"] = 'Horde',
			["4DA"] = 'Alliance',
			["4DB"] = 'Horde',
			["4F5"] = 'Neutral',
			["4F6"] = 'Neutral',
			["4F7"] = 'Neutral',
			["4F8"] = 'Neutral',
			["4F9"] = 'Neutral',
			["4FB"] = 'Neutral',
			["4FC"] = 'Neutral',
			["4FD"] = 'Neutral',
			["4FE"] = 'Neutral',
			["4FF"] = 'Neutral',
			["500"] = 'Neutral',
			["501"] = 'Neutral',
			["502"] = 'Neutral',
			["503"] = 'Neutral',
			["516"] = 'Neutral',
			["539"] = 'Neutral',
			["53D"] = 'Neutral',
			["541"] = 'Neutral',
			["547"] = 'Neutral',
			["548"] = 'Horde',
			["549"] = 'Alliance',
			["54D"] = 'Neutral',
			["54E"] = 'Neutral',
			["54F"] = 'Neutral',
			["55F"] = 'Horde',
			["560"] = 'Alliance',
			["56B"] = 'Alliance',
			["56C"] = 'Horde',
			["59B"] = 'Neutral',
			["5A5"] = 'Horde',
			["5D4"] = 'Neutral',
			["5EB"] = 'Neutral',
			["5F0"] = 'Neutral',
			["68F"] = 'Neutral',
			["691"] = 'Horde',
			["692"] = 'Alliance',
			["6AC"] = 'Horde',
			["6AE"] = 'Alliance',
			["6AF"] = 'Neutral',
			["6B0"] = "Neutral",
			["6B1"] = "Neutral",
			["6B2"] = "Neutral",
			["6B3"] = "Neutral",
			["6B4"] = "Neutral",
			["6B5"] = "Neutral",
			["6B6"] = "Neutral",
			["6B7"] = "Neutral",
			["6C3"] = 'Alliance',
			["6C4"] = 'Neutral',
			["6C5"] = 'Alliance',
			["6C7"] = 'Neutral',
			["6C8"] = 'Neutral',
			["6C9"] = 'Neutral',
			["6CA"] = 'Alliance',
			["6CB"] = 'Horde',
			["6CC"] = 'Horde',
			["6CD"] = 'Neutral',
			["717"] = "Neutral",
			["724"] = "Neutral",
			["729"]	= "Neutral",
			["737"] = "Alliance",
			["738"] = "Horde",
			["739"] = "Neutral",
			["73A"] = "Neutral",
			["743"] = "Neutral",
			["744"] = "Neutral",
			["746"] = "Neutral",
			["75B"] = "Neutral",
			["760"] = "Neutral",
			["766"] = "Neutral",
			["76B"] = "Neutral",
			["76C"] = "Neutral",
			["77F"] = "Neutral",
			["79B"] = "Neutral",
			["79C"] = "Neutral",
			["7B7"] = "Neutral",
			["7C0"] = "Neutral",
			["7C5"] = "Neutral",
			["7E2"] = "Neutral",
			["7FD"] = "Neutral",
			["831"] = "Neutral",
			["832"] = "Neutral",
			["833"] = "Neutral",
			["834"] = "Neutral",
			["835"] = "Neutral",
			["836"] = "Neutral",
			["837"] = "Neutral",	-- TODO: Determine faction
			["83F"] = "Neutral",	-- TODO: Determine faction
["848"] = "Neutral",	-- TODO: Determine faction
			["857"] = "Neutral",
			["86C"] = "Neutral",	-- TODO: Determine faction
			["86D"] = "Neutral",	-- TODO: Determine faction
			["86E"] = "Neutral",	-- TODO: Determine faction
			["86F"] = "Neutral",	-- TODO: Determine faction
			["870"] = "Neutral",	-- TODO: Determine faction
			["871"] = "Neutral",	-- TODO: Determine faction
			["872"] = "Neutral",	-- TODO: Determine faction
			["873"] = "Neutral",	-- TODO: Determine faction
			["874"] = "Neutral",	-- TODO: Determine faction
			["875"] = "Neutral",
			["87A"] = "Neutral",
			["8B9"] = "Neutral",	-- TODO: Determine faction
			["8D8"] = "Neutral",	-- TODO: Determine faction
			["8D9"] = "Neutral",	-- TODO: Determine faction
			["943"] = "Alliance",	-- 2371
			["944"] = "Horde",	-- 2372
			["945"] = "Horde",	-- 2373
			["946"] = "Horde",	-- 2374
			["947"] = "Alliance",	-- 2375
			["948"] = "Alliance",	-- 2376
			["949"] = "Alliance",	-- 2377
			["94A"] = "Horde",	-- 2378
			["94B"] = "Alliance",	-- 2379
			["94C"] = "Horde",	-- 2380
			["94D"] = "Alliance",	-- 2381
			["94E"] = "Horde",	-- 2382
			["94F"] = "Alliance",	-- 2383
			["950"] = "Alliance",	-- 2384
			["951"] = "Neutral",	-- 2385	-- TODO: Determine faction
			["952"] = "Neutral",	-- 2386	-- TODO: Determine faction
			["953"] = "Neutral",	-- 2387
			["954"] = "Horde",	-- 2388
			["955"] = "Horde",	-- 2389
			["956"] = "Horde",	-- 2390
			["957"] = "Neutral",	-- 2391
			["958"] = "Neutral",	-- 2392
			["95B"] = "Neutral",	-- 2395	-- TODO: Determine faction
			["95C"] = "Neutral",	-- 2396	-- TODO: Determine faction
			["95D"] = "Neutral",	-- 2397	-- TODO: Determine faction
			["95E"] = "Neutral",	-- 2398	-- TODO: Determine faction
			["960"] = "Alliance",	-- 2400
			["961"] = "Alliance",	-- 2401
			["967"] = "Neutral", -- 2407	-- TODO: Determine faction
			["96A"] = "Neutral", -- 2410	-- TODO: Determine faction
			["96D"] = "Neutral", -- 2413	-- TODO: Determine faction
			["96F"] = "Neutral", -- 2415	-- TODO: Determine faction
			["971"] = "Neutral", -- 2417	-- TODO: Determine faction
--			["976"] = "Neutral", -- 2422	-- TODO: Determine faction
			["97B"] = "Neutral", -- 2427	-- TODO: Determine faction
			["980"] = "Neutral", -- 2432	-- TODO: Determine faction
			["987"] = "Neutral", -- 2439	-- TODO: Determine faction
			["98D"] = "Neutral", -- 2445	-- TODO: Determine faction
			["98E"] = "Neutral", -- 2446	-- TODO: Determine faction
			["98F"] = "Neutral", -- 2447	-- TODO: Determine faction
			["990"] = "Neutral", -- 2448	-- TODO: Determine faction
			["991"] = "Neutral", -- 2449	-- TODO: Determine faction
			["992"] = "Neutral", -- 2450	-- TODO: Determine faction
			["993"] = "Neutral", -- 2451	-- TODO: Determine faction
			["994"] = "Neutral", -- 2452	-- TODO: Determine faction
			["995"] = "Neutral", -- 2453	-- TODO: Determine faction
			["996"] = "Neutral", -- 2454	-- TODO: Determine faction
			["997"] = "Neutral", -- 2455	-- TODO: Determine faction
			["998"] = "Neutral", -- 2456	-- TODO: Determine faction
			["999"] = "Neutral", -- 2457	-- TODO: Determine faction
			["99A"] = "Neutral", -- 2458	-- TODO: Determine faction
			["99B"] = "Neutral", -- 2459	-- TODO: Determine faction
			["99C"] = "Neutral", -- 2460	-- TODO: Determine faction
			["99D"] = "Neutral", -- 2461	-- TODO: Determine faction
			["99E"] = "Neutral", -- 2462	-- TODO: Determine faction
			["99F"] = "Neutral", -- 2463	-- TODO: Determine faction
			["9A0"] = "Neutral", -- 2464	-- TODO: Determine faction
			["9A1"] = "Neutral", -- 2465	-- TODO: Determine faction
            ["9A5"] = "Neutral", -- 2469    -- TODO: Determine faction
			["9A6"] = "Neutral", -- 2470	-- TODO: Determine faction
			["9A8"] = "Neutral", -- 2472	-- TODO: Determine faction
            ["9AE"] = "Neutral", -- 2478    -- TODO: Determine faction
            ["9C7"] = "Neutral", -- 2503    -- TODO: Determine faction
            ["9CB"] = "Neutral", -- 2507    -- TODO: Determine faction
            ["9CD"] = "Neutral", -- 2509    -- TODO: Determine faction
            ["9CE"] = "Neutral", -- 2510    -- TODO: Determine faction
            ["9CF"] = "Neutral", -- 2511    -- TODO: Determine faction
            ["9D0"] = "Neutral", -- 2512    -- TODO: Determine faction
            ["9D1"] = "Neutral", -- 2513    -- TODO: Determine faction
            ["9D5"] = "Neutral", -- 2517    -- TODO: Determine faction
            ["9D6"] = "Neutral", -- 2518    -- TODO: Determine faction
            ["9D8"] = "Neutral", -- 2520    -- TODO: Determine faction
            ["9DA"] = "Neutral", -- 2522    -- TODO: Determine faction
            ["9DB"] = "Horde", -- 2523
            ["9DC"] = "Alliance", -- 2524
            ["9DE"] = "Neutral", -- 2526
            ["9EE"] = "Neutral", -- 2542    -- TODO: Determine faction
            ["9F0"] = "Neutral", -- 2544    -- TODO: Determine faction
            ["9F6"] = "Neutral", -- 2550    -- TODO: Determine faction
            ["9F9"] = "Neutral", -- 2553    -- TODO: Determine faction
            ["9FA"] = "Neutral", -- 2554    -- TODO: Determine faction
            ["9FB"] = "Neutral", -- 2555    -- TODO: Determine faction
            ["9FD"] = "Neutral", -- 2555    -- TODO: Determine faction
            ["A04"] = "Neutral", -- 2564    -- TODO: Determine faction
            ["A08"] = "Neutral", -- 2568    -- TODO: Determine faction
            ["A09"] = "Neutral", -- 2569    -- TODO: Determine faction
            ["A0A"] = "Neutral", -- 2570    -- TODO: Determine faction
            ["A0E"] = "Neutral", -- 2574    -- TODO: Determine faction
            ["A1E"] = "Neutral", -- 2590    -- TODO: Determine faction
            ["A21"] = "Neutral", -- 2593    -- TODO: Determine faction
            ["A22"] = "Neutral", -- 2594    -- TODO: Determine faction
            ["A28"] = "Neutral", -- 2600    -- TODO: Determine faction
            ["A29"] = "Neutral", -- 2601    -- TODO: Determine faction
            ["A2D"] = "Neutral", -- 2605    -- TODO: Determine faction
            ["A2F"] = "Neutral", -- 2607    -- TODO: Determine faction
            ["A37"] = "Neutral", -- 2615    -- TODO: Determine faction
            ["A50"] = "Neutral", -- 2640    -- TODO: Determine faction
            ["A54"] = "Neutral", -- 2644    -- TODO: Determine faction
            ["A55"] = "Neutral", -- 2645    -- TODO: Determine faction
            ["A5D"] = "Neutral", -- 2653    -- TODO: Determine faction
            ["A62"] = "Neutral", -- 2658    -- TODO: Determine faction
            ["A67"] = "Neutral", -- 2663    -- TODO: Determine faction
            ["A68"] = "Neutral", -- 2664    -- TODO: Determine faction
            ["A69"] = "Neutral", -- 2665    -- TODO: Determine faction
            ["A6A"] = "Neutral", -- 2666    -- TODO: Determine faction
            ["A6D"] = "Neutral", -- 2669    -- TODO: Determine faction
            ["A6F"] = "Neutral", -- 2671    -- TODO: Determine faction
            ["A71"] = "Neutral", -- 2673    -- TODO: Determine faction
            ["A73"] = "Neutral", -- 2675    -- TODO: Determine faction
            ["A75"] = "Neutral", -- 2677    -- TODO: Determine faction
            ["A7B"] = "Neutral", -- 2683    -- TODO: Determine faction
            ["A80"] = "Neutral", -- 2688    -- TODO: Determine faction
            ["A85"] = "Neutral", -- 2693    -- TODO: Determine faction
            ["A88"] = "Neutral", -- 2696    -- TODO: Determine faction
            ["A8A"] = "Neutral", -- 2698    -- TODO: Determine faction
            ["A8B"] = "Neutral", -- 2699    -- TODO: Determine faction
            ["A90"] = "Neutral", -- 2704    -- TODO: Determine faction
            ["A96"] = "Neutral", -- 2710    -- TODO: Determine faction
            ["A97"] = "Neutral", -- 2711    -- TODO: Determine faction
            ["A98"] = "Neutral", -- 2712    -- TODO: Determine faction
            ["A99"] = "Neutral", -- 2713    -- TODO: Determine faction
            ["A9A"] = "Neutral", -- 2714    -- TODO: Determine faction
            ["AA2"] = "Neutral", -- 2722    -- TODO: Determine faction
            ["AB0"] = "Neutral", -- 2736    -- TODO: Determine faction
            ["AB3"] = "Neutral", -- 2739    -- TODO: Determine faction
            ["AB6"] = "Neutral", -- 2742    -- TODO: Determine faction
            ["AB8"] = "Neutral", -- 2744    -- TODO: Determine faction
            ["ACC"] = "Neutral", -- 2764    -- TODO: Determine faction
            ["ACE"] = "Neutral", -- 2766    -- TODO: Determine faction
            ["ACF"] = "Neutral", -- 2767    -- TODO: Determine faction
            ["AD2"] = "Neutral", -- 2770    -- TODO: Determine faction
			},

		slashCommandOptions = {},
		specialQuests = {},
		statusMapping = { ['C'] = "Completed", ['F'] = 'Faction', ['G'] = 'Gender', ['H'] = 'Holiday', ['I'] = 'Invalidated', ['L'] = "InLog",
			['P'] = 'Profession', ['Q'] = 'Prerequisites', ['R'] = 'Race', ['S'] = 'Class', ['T'] = 'Reputation', ['V'] = "Level", },
		timeSinceLastUpdate = 0,
		timings = {},	-- a table of debug timings whose keys are areas of interest, and values are elapsed times in milliseconds
		tooltip = nil,
		tracking = false,
		trackingStarted = false,
		unnamedZones = {},
		useAncestor = true,
		verifyTable = {},
		verifyTableCount = 0,
--		warnedClientQuestLocationsAccept = nil,
--		warnedClientQuestLocationsTurnin = nil,
		worldNPCBase = 5999999,
		zoneNameMapping = {},	-- maps zone names into map IDs
		zonesForLootingTreasure = {
			[941] = true, -- Frostfire Ridge
			[945] = true,
			[946] = true, -- Talador
			[947] = true, -- Shadowmoon Valley
			[948] = true,
			[949] = true, -- Gorgrond
			[950] = true,
			[951] = true,
			[1014] = true, -- Dalaran
			[1015] = true, -- Azsuna
			[1017] = true, -- Sturmheim
			[1018] = true, -- Val'sharah
			[1021] = true, -- Broken Shore
			[1022] = true, -- Felheim
			[1024] = true, -- Highmountain
			[1028] = true,
			[1032] = true,
			[1033] = true, -- Suramar
			[1080] = true, -- Thunder Totem village in HighMountain
			[1096] = true, -- Eye of Azshara
			[1135] = true, -- Krokuun
			[1170] = true, -- Mac'Aree
			[1171] = true, -- Antoran Wastes
			},

		---
		--	This is what happens when a quest has been accepted.
		_AcceptQuestProcessing = function(callbackType, payload)
			local debugStartTime = debugprofilestop()
			local questIndex = payload.questIndex
			local npcId = payload.npcId
			if questIndex ~= nil then
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId, startEvent, displayQuestId, isWeekly, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel = Grail:GetQuestLogTitle(questIndex)
				if nil == questTitle then questTitle = "NO TITLE PROVIDED BY BLIZZARD" end
				if nil == questId then questId = -1 end
				if not isHeader then
					local kCodeValue = 0
					if isDaily then kCodeValue = kCodeValue + Grail.bitMaskQuestDaily end
					if isWeekly then kCodeValue = kCodeValue + Grail.bitMaskQuestWeekly end
					if suggestedGroup then
						if type(suggestedGroup) == "string" or suggestedGroup > 1 then
							kCodeValue = kCodeValue + Grail.bitMaskQuestGroup
						end
					end
					-- We should be able to handle this with getting all the quest types
--					if isTask and not Grail:IsWorldQuest(questId) then kCodeValue = kCodeValue + Grail.bitMaskQuestBonus end	-- bonus objective
					if Grail.capabilities.usesCampaignInfo then
						local isCampaign = false
						if C_CampaignInfo.IsCampaignQuest then
							isCampaign = C_CampaignInfo.IsCampaignQuest(questId)
						end
						if isCampaign then kCodeValue = kCodeValue + Grail.bitMaskQuestLegendary end -- war campaign (recorded as legendary)
					end
					local kCode = (kCodeValue > 0) and strformat("K%d", kCodeValue) or nil
					local lCode = "L" .. Grail:StringFromQuestLevels(difficultyLevel, level, 0)
					Grail:_UpdateQuestDatabase(questId, questTitle, npcId, isDaily, 'A', nil, kCode, lCode)
				end
			end
			Grail:_LearnKCodesForQuest(payload.questId or (payload.questIndex and Grail:GetQuestID(payload.questIndex)))
			Grail:_AcceptQuestProcessingUpdateGroupCounts(payload.questId)
			Grail:_AcceptQuestProcessingCompleteOnAccept(payload.questId)
			Grail:_UpdateQuestResetTime()
			Grail.timings.QuestAccepted = debugprofilestop() - debugStartTime
		end,

		_AcceptQuestProcessingUpdateGroupCounts = function(self, questId)
			if questId ~= nil and self.questStatusCache.H[questId] then
				for _, group in pairs(self.questStatusCache.H[questId]) do
					if self:_RecordGroupValueChange(group, true, false, questId) >= self.dailyMaximums[group] then
						self:_StatusCodeInvalidate(self.questStatusCache['G'][group])
						self:_NPCLocationInvalidate(self.npcStatusCache['G'][group])
					end
					self:_StatusCodeInvalidate(self.questStatusCache['X'][group])
					self:_NPCLocationInvalidate(self.npcStatusCache['X'][group])
				end
			end
			if questId ~= nil and self.questStatusCache.K[questId] then
				for _, group in pairs(self.questStatusCache.K[questId]) do
					if self:_RecordGroupValueChange(group, true, false, questId, true) >= self.weeklyMaximums[group] then
						self:_StatusCodeInvalidate(self.questStatusCache.J[group])
						self:_NPCLocationInvalidate(self.npcStatusCache.J[group])
					end
				end
			end
		end,

		_AcceptQuestProcessingCompleteOnAccept = function(self, questId)
			if nil ~= questId then
				local oacCodes = self:QuestOnAcceptCompletes(questId)
				if nil ~= oacCodes then
					for i = 1, #oacCodes do
						self:_MarkQuestComplete(oacCodes[i], true, false, false)
					end
				end
			end
		end,

		---
		--	Returns the mapID where the player currently is.
		GetCurrentMapAreaID = function()
-- C_Map.GetBestMapForUnit will return nil if it can't find a map for that unit, MapUtil.GetDisplayableMapForPlayer will uses a fallback map if so
--				return C_Map.GetBestMapForUnit('player')
			return MapUtil.GetDisplayableMapForPlayer()
		end,

		---
		--	Returns the mapID of where the map is showing.
		GetCurrentDisplayedMapAreaID = function()
--	Prior to 26567 there was C_Map API to use, but now we have to ask the map itself, which only
--	works if we have shown the map.
--			return Grail.battleForAzeroth and C_Map.GetCurrentMapID() or Grail.GetCurrentMapAreaID()
			return WorldMapFrame:GetMapID() or Grail.GetCurrentMapAreaID()
		end,

		---
		--	Returns whether the specified achievement is complete.
		--	@param soughtAchievementId The standard numeric achievement ID representing an achievement.
		--	@param onlyPlayerCompleted If true, the return value indicates whether the player completed the achievement, otherwise it represents whether the achievement is completed on the account.
		--	@return true is the achievement is complete, false otherwise.
		AchievementComplete = function(self, soughtAchievementId, onlyPlayerCompleted)
			local name, achievementComplete, playerCompletedIt = self:GetBasicAchievementInfo(soughtAchievementId)
			local retval = achievementComplete
			if onlyPlayerCompleted then
				retval = playerCompletedIt
			end
			return retval
		end,

		_customAchievementNames = {
									[13997] = C_CampaignInfo and C_CampaignInfo.GetCampaignInfo(113).name or "",	-- Venthyr Campaign
									[14234] = C_CampaignInfo and C_CampaignInfo.GetCampaignInfo(119).name or "",	-- Kyrian Campaign
									[14279] = C_CampaignInfo and C_CampaignInfo.GetCampaignInfo(115).name or "",	-- The Art of War
									[14282] = C_CampaignInfo and C_CampaignInfo.GetCampaignInfo(117).name or "",	-- Night Fae Campaign
									},
		-- The assumption is the value of each entry in the table would logically be considered a valid P:
		_customAchievementPrerequisites = {
											[13997] = "58407",	-- Venthyr
											[14234] = "62557",	-- Kyrian
											[14279] = "62406",	-- Necrolords
											[14282] = "60108",	-- Night Fae
											},

		GetBasicAchievementInfo = function(self, achievementId)
			if not GetAchievementInfo then
				return nil, false, false
			end
			local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementId)
			if nil == id then
				-- Attempt to look up the achievement in our own limited list of supported achievements.
				-- Note that we are limited in determining completed vs wasEarnedByMe so assume they are the same.
				name = self._customAchievementNames[achievementId]
				local prerequisites = self._customAchievementPrerequisites[achievementId]
				if nil ~= prerequisites then
					local isCompleted = self:_AnyEvaluateTrueF(prerequisites, { q = 0, d = false}, Grail._EvaluateCodeAsPrerequisite, false)
					completed = isCompleted
					wasEarnedByMe = isCompleted
				end
			end
			return name, completed, wasEarnedByMe
		end,

		_HighestSupportedExpansion = function(self)
			local retval = 0
			-- As of 2020-10-15 Classic has EXPANSION_NAME 0..6 defined, while Retail has 0..8 defined.
			-- It would be great if we could support what is defined in the system, but it seems we cannot
			-- and therefore if in Classic we limit ourselves to EXPANSION_NAME0 only.
			if not self.existsClassic then
				for expansionIndex = 0, 100 do
					if nil == self:_ExpansionName(expansionIndex) then
						break
					end
					if self.GDE and self.GDE.debug then
						print("ExpansionIndex:", expansionIndex, "ExpansionName: ", self:_ExpansionName(expansionIndex))
					end
					retval = expansionIndex
				end
			end
			return retval
		end,
		
		_ExpansionName = function(self, expansionIndex)
			return _G["EXPANSION_NAME"..expansionIndex]
		end,

		_LoadContinentData = function(self)
			--	Attempt to get all the Continents by starting wherever you are and getting the Cosmic
			--	map and then asking it for all the Continents that are children of it, hoping the API
			--	will bypass the intervening World maps.
			local currentMapId, TOP_MOST, ALL_DESCENDANTS = Grail.GetCurrentMapAreaID(), true, true
			-- For Exile's Reach (Shadowlands) there is no parent map, so we are not going to be able to get continents from it.  Default to normal Cosmic of 946
			if currentMapId == 1409 then
				currentMapId = nil
			end
			local cosmicMapInfo = MapUtil.GetMapParentInfo(currentMapId or 946, Enum.UIMapType.Cosmic, TOP_MOST)
			if nil == cosmicMapInfo then
				cosmicMapInfo = { mapID = 946 }
			end
			if self.capabilities.usesAzerothAsCosmicMap then
				cosmicMapInfo = { mapID = 947 }
			end
			local continents = C_Map.GetMapChildrenInfo(cosmicMapInfo.mapID, Enum.UIMapType.Continent, ALL_DESCENDANTS)
			self.continentMapIds = {}
			self.mapToContinentMapping = {}		-- key is mapId, value is continent mapId
			for i, continentInfo in ipairs(continents) do
				local L = { name = continentInfo.name, zones = {}, mapID = continentInfo.mapID, dungeons = {} }
				-- Use false (not ALL_DESCENDANTS) so sub-continents (e.g. Quel'Thalas, Argus) keep their
				-- own zones instead of having them stolen by the parent continent's recursive descent.
				local zones = C_Map.GetMapChildrenInfo(continentInfo.mapID, Enum.UIMapType.Zone, false)
				for j, zoneInfo in ipairs(zones) do
					self:_AddMapId(L.zones, zoneInfo.name, zoneInfo.mapID, L.mapID)
				end
				local dungeons = C_Map.GetMapChildrenInfo(continentInfo.mapID, Enum.UIMapType.Dungeon, false)
				for j, dungeonInfo in ipairs(dungeons) do
					self:_AddMapId(L.dungeons, dungeonInfo.name, dungeonInfo.mapID, L.mapID)
				end
-- TODO: Do we need to handle Micro map types?
				-- Stormsong Valley is an Orphan and not a Zone in beta at least
				local orphans = C_Map.GetMapChildrenInfo(continentInfo.mapID, Enum.UIMapType.Orphan, false)
				for j, orphanInfo in ipairs(orphans) do
					self:_AddMapId(L.zones, orphanInfo.name, orphanInfo.mapID, L.mapID)
				end
				self.continents[L.mapID] = L
				tinsert(self.continentMapIds, L.mapID)
			end
			table.sort(self.continentMapIds)
		end,

		_AddMapId = function(self, zoneTable, zoneName, mapId, continentMapId)
			-- If we have processed this mapId already we do not need to do so again
			if self.mapToContinentMapping[mapId] then return end
			
			-- If this map is part of a group there is a good chance that zoneName is going to exist more than
			-- once and therefore we will add the specific "floor" name to the zone name.
			local mapGroupId = C_Map.GetMapGroupID(mapId)
			if nil ~= mapGroupId then
				local groupMembers = C_Map.GetMapGroupMembersInfo(mapGroupId)
				if nil ~= groupMembers then
					for _, info in ipairs(groupMembers) do
						if mapId == info.mapID then
							zoneName = zoneName .. ' - ' .. info.name
						end
					end
				end
			end

			-- Instead of the old technique of appending spaces to make the zone names unique we now append the mapId
			if nil ~= self.zoneNameMapping[zoneName] then
				zoneName = zoneName .. ' ('..mapId..')'
			end
			zoneTable[#zoneTable + 1] = { name = zoneName, mapID = mapId }
--self.GDE.zoneNames = self.GDE.zoneNames or {}
--tinsert(self.GDE.zoneNames, { name = zoneName, mapID = mapId, continent = continentMapId })
			self.zoneNameMapping[zoneName] = mapId
			self.mapToContinentMapping[mapId] = continentMapId
		end,

		---
		--	Internal Use.
		--	Updates the internal database to associate the specified quest with the specified map area,
		--	optionally setting the title for the map area.
		--	@param questId The standard numeric questId representing a quest.
		--	@param mapAreaId The standard numeric map are ID representing the map area.
		--	@param title The localized name of the map area.
		AddQuestToMapArea = function(self, questId, mapAreaId, title)
			if nil ~= questId and nil ~= mapAreaId then
				if not self.experimental then
					self:_InsertSet(self.indexedQuests, mapAreaId, questId)
				else
					self:_MarkQuestInDatabase(questId, self.indexedQuests[mapAreaId])
				end
				if nil == self.mapAreaMapping[mapAreaId] then self.mapAreaMapping[mapAreaId] = title end
			end
		end,

		--	This routine is registered to be called when any of the notifications this addon can post are posted.
		--	It formats a message that is stored in the tracking system.
		--	@param callbackType The string representing the type of callback as posted by the notification system.
		--	@param questId The standard questId posted by the notification system.
		_AddTrackingCallback = function(callbackType, questId)
			local functionKey = "+"
			if "Complete" == callbackType then
				functionKey = "="
			elseif "Abandon" == callbackType then
				functionKey = "-"
			end
			local message = strformat("%s %s(%d)", functionKey, Grail:QuestName(questId) or "NO NAME", questId)
			if "Accept" == callbackType or "Complete" == callbackType then
				local targetName, npcId, coordinates = Grail:TargetInformation()
				if nil ~= targetName then
					if nil == npcId then npcId = -123 end
					if nil == coordinates then coordinates = "NO COORDS" end
					message = strformat("%s %s %s(%d) %s", message, ("Accept" == callbackType) and "<=" or "=>", targetName, npcId, coordinates)
				else
					message = strformat("%s, self coords: %s", message, Grail:Coordinates())
				end
			end
			Grail:_AddTrackingMessage(message)
		end,

		_AddFullTrackingCallback = function(callbackType, payload)
			local questId = payload.questId
			local questIndex = payload.questIndex or "NO questIndex"
			local npcName = payload.npcName or "NO npcName"
			local npcId = tonumber(payload.npcId) or "NO npcId"
			local blizardNPCId = payload.blizzardNPCId and tonumber(payload.blizzardNPCId) or nil
			local coordinates = payload.coordinates or "NO coordinates"
			local errorCodeString = Grail:CanAcceptQuest(questId, false, false, true) and "" or strformat(" Error: %d", Grail:StatusCode(questId))
			local actualNPCIdString = (nil ~= blizardNPCId and blizardNPCId ~= npcId) and ("[" .. blizardNPCId .. "]") or ""
			local message = strformat("+ %s(%d)[%d] <= %s(%d)%s %s%s", Grail:QuestName(questId) or "NO NAME", questId, questIndex, npcName, npcId, actualNPCIdString, coordinates, errorCodeString)
			Grail:_AddTrackingMessage(message)
			print(message)
		end,

		--	This adds the provided message to the tracking system.  The first time this is called, a timestamp with some player
		--	information is logged into the tracking system as well.
		--	@param msg The string that will be added to the tracking system.
		_AddTrackingMessage = function(self, msg)
			self.GDE.Tracking = self.GDE.Tracking or {}
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
			if not self.trackingStarted then
				tinsert(self.GDE.Tracking, strformat("%4d-%02d-%02d %02d:%02d %s/%s/%s/%s/%s/%s/%s/%s/%d/%d/%d/%d/%2d/%2d/%2d/%2d/%d/%d", year, month, day, hour, minute, self.playerRealm, self.playerName, self.playerFaction, self.playerClass, self.playerRace, self.playerGender, self.playerLocale, self.portal, self.blizzardRelease, self.covenant, self.renownLevel, self.activeSeason, self.timerunningSeason, self.accountExpansionLevel, self.expansionLevel, self.classicExpansionLevel, self.serverExpansionLevel, self.isTrial, self.isVeteranTrial))
				self.trackingStarted = true
			end
			msg = strformat("%02d:%02d %s", hour, minute, msg)
			tinsert(self.GDE.Tracking, msg)
		end,

		_RemoveWorldQuest = function(self, soughtQuestId)
			local index, foundIndex = 1, nil
			for _, questId in pairs(self.invalidateControl[self.invalidateGroupCurrentWorldQuests]) do
				if questId == soughtQuestId then
					foundIndex = index
				end
				index = index + 1
			end
			if foundIndex then
				tremove(self.invalidateControl[self.invalidateGroupCurrentWorldQuests], foundIndex)
			end
--			self.availableWorldQuests[questId] = nil
			--	There is no need to deal with the timer that goes off to reset the quests because
			--	if we are removing the first one to trigger, all the others remaining would cause
			--	the trigger to be later.  And if we remove any other, the current trigger will be
			--	called properly anyway.
		end,

		_ResetWorldQuests = function(self)
--			self.questsToInvalidate = self.availableWorldQuests
			self.questsToInvalidate = self.invalidateControl[self.invalidateGroupCurrentWorldQuests]
			self:_AddWorldQuests()
			C_Timer.After(3, function()
--				local q = {}
--				for questId, _ in pairs(self.questsToInvalidate) do
--					tinsert(q, questId)
--				end
--				self:_StatusCodeInvalidate(q)
				self:_StatusCodeInvalidate(self.questsToInvalidate)
				end)
		end,

		_AddWorldQuestsUpdateTimes = function(self)
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
--			local newTable = {}
			--	We set the smallestMinutes to the top of the hour with the intention to check every top of the hour at a minimum
			--	because we do not know exactly when Blizzard will refresh the list of available world quests (meaning add new ones)
			--	because this will change with each server.
			local smallestMinutes = 60 - minute
--			for questId, _ in pairs(self.availableWorldQuests) do
			for _, questId in pairs(self.invalidateControl[self.invalidateGroupCurrentWorldQuests]) do
				local minutesLeft = C_TaskQuest.GetQuestTimeLeftMinutes(questId) or 0
				if 0 < minutesLeft then
----					newTable[questId] = minutesLeft .. ' => ' .. C_TaskQuest.GetQuestInfoByQuestID(questId)
--					newTable[questId] = minutesLeft
					if minutesLeft < smallestMinutes then
						smallestMinutes = minutesLeft
					end
				else
					if self.GDE.debug and self.levelingLevel >= 110 then
						local stringValue = strformat("%4d-%02d-%02d %02d:%02d %s/%s", year, month, day, hour, minute, self.playerRealm, self.playerName)
						self.GDE.learned = self.GDE.learned or {}
						self.GDE.learned.WORLD_QUEST_UNAVAILABLE = self.GDE.learned.WORLD_QUEST_UNAVAILABLE or {}
						self.GDE.learned.WORLD_QUEST_UNAVAILABLE[questId] = stringValue
					end
				end
			end
--			self.availableWorldQuests = newTable
			C_Timer.After((smallestMinutes + 1) * 60, function() self:_ResetWorldQuests() end)
		end,

		_worldQuestSelfNPCs = {},	-- key is the mapId, value is a table that contains as keys the x/y coords, and values as the npcId
		--	This looks at the current NPCs for self in the mapId and creates a structure of them
		--	so they can be looked up based on coordinates.
		_PrepareWorldQuestSelfNPCs = function(self, mapId)
			if nil == self._worldQuestSelfNPCs[mapId] then
				self._worldQuestSelfNPCs[mapId] = {}
-- Since the processing of npc.locations for world quests has been handled in _ProcessNPCs(), we need not do any here.
--				local currentNPCId = -100000 - mapId
--				while Grail.npc.locations[currentNPCId] and Grail.npc.locations[currentNPCId][1] and Grail.npc.locations[currentNPCId][1].x do
--					local coordinates = strformat("%.2f,%.2f", Grail.npc.locations[currentNPCId][1].x, Grail.npc.locations[currentNPCId][1].y)
--					self._worldQuestSelfNPCs[mapId][coordinates] = currentNPCId
--					currentNPCId = currentNPCId - 10000
--				end
			end
		end,

		_AddCallingQuests = function(self, callingQuests)
			-- Clear the status of all the ones in the current calling quest list
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupCurrentCallingQuests])

			-- Clean out the list because we will rebuild it with current values
			self.invalidateControl[self.invalidateGroupCurrentCallingQuests] = {}

			-- Process the calling quests provided to us
			if nil ~= callingQuests and 0 < #callingQuests then
				for _, callingQuest in pairs(callingQuests) do
					local questId = callingQuest.questID
					if nil ~= questId then
						self:_LearnCallingQuest(questId)
						tinsert(self.invalidateControl[self.invalidateGroupCurrentCallingQuests], questId)
					end
				end
			end

			-- Clear the status of all the ones in the current (new) calling quest list
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupCurrentCallingQuests])
		end,

		-- Assume we are going to get the current list of threat quests and update the internal structures
		-- to those quests.
		_AddThreatQuests = function(self)
			-- Clear the status of all the ones in the current threat quest list
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupCurrentThreatQuests])

			-- Clean out the list because we will rebuild it with current values
			self.invalidateControl[self.invalidateGroupCurrentThreatQuests] = {}

			-- Ask Blizzard for the current list of threat quests
			local currentlyAvailableThreatQuests = C_TaskQuest.GetThreatQuests()

			-- Assuming we have something, do the work to process the list
			if nil ~= currentlyAvailableThreatQuests and 0 < #currentlyAvailableThreatQuests then
				for k, questId in ipairs(currentlyAvailableThreatQuests) do
					-- Record this quest as a threat quest for Grail enhancement
					self:_LearnThreatQuest(questId)

					-- Add the quest to the list of current threat quests available in the system
					tinsert(self.invalidateControl[self.invalidateGroupCurrentThreatQuests], questId)
				end
			end

			-- Because quests added to the list may have been previously evaluated as not being present
			-- they should have their statuses cleared.
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupCurrentThreatQuests])
--	TODO: Find out when threat quests reset to see if we can automate calling this method after that time
		end,

		--	This adds to our internal data structure the world quests found available
		_AddWorldQuests = function(self)
			self.invalidateControl[self.invalidateGroupCurrentWorldQuests] = {}
--			self.availableWorldQuests = {}

			local mapIdsForWorldQuests = { 14, 62, 241, 625, 627, 630, 634, 641, 646, 650, 680, 790, 830, 882, 885, 862, 863, 864, 895, 896, 942, 1161, 1355, 1462, 1525, 1527, 1530, 1533, 1536, 1543, 1565, 1970, 2022, 2023, 2024, 2025, 2085, 2112, 2133, 2151, 2200, 2213, 2214 ,2215, 2248, 2255, 2256, 2346, 2369, 2371, 2472}

			for _, mapId in pairs(mapIdsForWorldQuests) do
				self:_PrepareWorldQuestSelfNPCs(mapId)
				-- Retail 12.x: GetQuestsForPlayerByMapID may be nil; prefer GetQuestsOnMap when available. Was deprecated in 11.0.5 and removed with 12.0
				local tasks
				if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
					tasks = C_TaskQuest.GetQuestsOnMap(mapId)
				elseif C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID then
					tasks = C_TaskQuest.GetQuestsForPlayerByMapID(mapId)
				else
					tasks = nil
				end
				tasks = tasks or {}
				if nil ~= tasks and 0 < #tasks then
					for k,v in ipairs(tasks) do
						-- In 11.0.5 the questId is now questID so an adjustment is made here.
						if nil == v.questId then
							v.questId = v.questID
						end
						if self.GDE.tracking then
							local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = self:GetQuestTagInfo(v.questId)
							if tagID and ((nil == self._LearnedWorldQuestProfessionMapping[tagID] and nil == self._LearnedWorldQuestTypeMapping[tagID]) or self.GDE.worldquestforcing) then
								self.GDE.eek = self.GDE.eek or {}
								self.GDE.eek[v.questId] = 'A:'..(tagID and tagID or 'NoTagID')..' B:'..(tagName and tagName or 'NoTagName')..' C:'..(worldQuestType and worldQuestType or 'NotWorld') ..' D:'..(rarity and rarity or 'NO')..' E:'..(isElite and 'YES' or 'NO')..' F:'..(tradeskillLineIndex or 'nil')
							end
						end
--	41672 123	"Enchanting World Quest" 1 1 false 9

--	1	Group
--	21	Class
--	41	PvP
--	62	Raid
--	81	Dungeon
--	82	World Event
--	83	Legendary
--	84	Escort
--	85	Heroic
--	88	Raid (10)
--	89	Raid (25)
--	98	Scenario
--	102	Account
--	104	Side Quest
--	107	Artifact
--	109 normal world quest
--	110 epic
--	111	elite
--	112	epic elite
--	113	PVP
--	114	First Aid
--	115	battle pet
--	116 Blacksmithing
--	117	Leatherworking
--	118	Alchemy
--	119	Herbalism
--	120	Mining
--	121	Tailoring
--	122 Engineering
--	123	Enchanting	tradeskillLineIndex: 9
--	124	Skinning
--	125	Jewelcrafting
--	126	Inscription

--	128	Emissary
--	129	Archaeology
--	130	Fishing		tradeskillLineIndex: 10
--	131 Cooking		tradeskillLineIndex: 7

--	135	rare
--	136	rare elite
--	137	Dungeon

--	139 Legion Invasion World Quest
--	140	Rated Reward
--	141	Raid World Quest
--	142	Legion Invasion Elite World Quest
--	143	Legionfall Contribution
--	144	Legionfall World Quest
--	145	Legionfall Dungeon World Quest
--	146	Legionfall Invasion World Quest
--	147	Warfront - Barrens
--	148	Pickpocketing

--	151 Magni World Quest - Azerite
--	152 Tortollan World Quest - 8.0

--	259 Faction Assault World Quest
--	260	Faction Assault Elite World Quest
--	266 Combat Ally Quest

--	268	Threat Wrapper

--	271	Calling Quest


						if nil ~= v.mapID and v.mapID ~= mapId then
							self:_PrepareWorldQuestSelfNPCs(v.mapID)
						end
						-- In 11.0.5 the questId is now questID so an adjustment is made here.
						if nil == v.questId then
							v.questId = v.questID
						end
						if nil ~= v.questId then 
							self:_LearnWorldQuest(v.questId, v.mapID, v.x, v.y, v.isDaily)
	--						self.availableWorldQuests[v.questId] = true
							tinsert(self.invalidateControl[self.invalidateGroupCurrentWorldQuests], v.questId)
							C_TaskQuest.GetQuestTimeLeftMinutes(v.questId)	-- attempting to prime the system, because first calls do not work
						end
					end
				end
			end
			C_Timer.After(2, function() Grail:_AddWorldQuestsUpdateTimes() end)
		end,

		_LearnedWorldQuestProfessionMapping = { [116] = 'B', [117] = 'L', [118] = 'A', [119] = 'H', [120]= 'M', [121] = 'T', [122] = 'N', [123] = 'E', [124] = 'S', [125] = 'J', [126] = 'I', [130] = 'F', [131] = 'C', },

		_LearnedWorldQuestTypeMapping = { [109] = 0, [111] = 0, [112] = 0, [113] = 0x00000100, [115] = 0x00004000, [135] = 0, [136] = 0, [137] = 0x00000040, [139] = 0, [141] = 0x00000080, [142] = 0, [144] = 0, [145] = 0x00000040, [151] = 0, [152] = 0, [259] = 0, [260] = 0, [266] = 0, },

		_LearnCallingQuest = function(self, questId)
			questId = tonumber(questId)
			if nil == questId then return end
			local kCodeToAdd, pCodeToAdd = 'K2097152', 'P:^'..questId
			
			self:_LearnKCode(questId, kCodeToAdd)
			
			if nil == strfind(self.questPrerequisites[questId] or '', strsub(pCodeToAdd, 3), 1, true) then
				self:_LearnQuestCode(questId, pCodeToAdd)
				local codeToAdd = strsub(pCodeToAdd, 3)
				if nil == self.questPrerequisites[questId] then
					self.questPrerequisites[questId] = codeToAdd
				else
					self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToAdd
				end
			end
		end,

		_LearnThreatQuest = function(self, questId)
			questId = tonumber(questId)
			if nil == questId then return end
			local kCodeToAdd, pCodeToAdd = 'K1048576', 'P:b'..questId
			
			self:_LearnKCode(questId, kCodeToAdd)
			
			if nil == strfind(self.questPrerequisites[questId] or '', strsub(pCodeToAdd, 3), 1, true) then
				self:_LearnQuestCode(questId, pCodeToAdd)
				local codeToAdd = strsub(pCodeToAdd, 3)
				if nil == self.questPrerequisites[questId] then
					self.questPrerequisites[questId] = codeToAdd
				else
					self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToAdd
				end
			end
		end,

		_LearnKCode = function(self, questId, kCode, dontLearn)
			local retval = false
			local possibleQuestType = tonumber(strsub(kCode, 2))
			if nil ~= possibleQuestType and 0 ~= possibleQuestType and possibleQuestType ~= bitband(self:CodeType(questId), possibleQuestType) then
				if not dontLearn then
					self:_LearnQuestCode(questId, kCode)
				end
				self:_MarkQuestType(questId, possibleQuestType)
				retval = true
			end
			return retval
		end,

		_LearnKCodesForQuest = function(self, questId)
			local code = self:CodeType(questId)
			-- Masking out things that we get from this API use so the API gives us truth.
			code = bitband(code,
					self.bitMaskQuestDaily +
					self.bitMaskQuestWeekly +
					self.bitMaskQuestMonthly +
					self.bitMaskQuestYearly +
					self.bitMaskQuestEscort +
					self.bitMaskQuestDungeon +
					self.bitMaskQuestRaid +
					self.bitMaskQuestPVP +
					self.bitMaskQuestGroup +
					self.bitMaskQuestHeroic +
					self.bitMaskQuestScenario +
					self.bitMaskQuestPetBattle +
					self.bitMaskQuestRareMob +
					self.bitMaskQuestTreasure +
					self.bitMaskQuestBiweekly
					)
			
			if self:IsRepeatableQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestRepeatable)
			end
			if self:IsImportantQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestImportant)
			end
			if self:IsAccountQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestAccountWide)
			end
			if self:IsLegendaryQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestLegendary)
			end
			if self:IsMetaQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestMeta)
			end
--			if self:IsPushableQuestBlizzardAPI(questId) then
--				code = bitbor(code, self.bitMaskQuestPushable)
--			end
			if self:IsQuestBountyBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestBounty)
			end
			if self:IsQuestCallingBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestCallingQuest)
			end
			if self:IsQuestInvasionBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestInvasion)
			end
			if self:IsQuestTaskBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestBonus)
			end
			if self:IsThreatQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestThreatQuest)
			end
			if self:IsWorldQuestBlizzardAPI(questId) then
				code = bitbor(code, self.bitMaskQuestWorldQuest)
			end
			self:_LearnKCode(questId, "K"..code)
		end,

		_LearnWorldQuest = function(self, questId, mapId, x, y, isDaily)
			questId = tonumber(questId)
			if nil == questId then return end
			local kCodeToAdd, pCodeToAdd = 'K', 'P:a'..questId
			local tagId, tagName = self:GetQuestTagInfo(questId)
			if tagId == 268 or tagId == 271 then return end	-- It turns out tagName is localized so tagId is the smarter comparison.
			local professionRequirement = self._LearnedWorldQuestProfessionMapping[tagId]
			local typeModifier = self._LearnedWorldQuestTypeMapping[tagId]
			local typeValue = tagId and 262144 or (isDaily and 2 or 0)

			if nil ~= professionRequirement then
				pCodeToAdd = pCodeToAdd .. '+P' .. professionRequirement .. '001'
			end
			if (646 == mapId) then
				pCodeToAdd = pCodeToAdd .. '+46734'
			end
			if (830 == mapId) then
				pCodeToAdd = pCodeToAdd .. '+48199'	-- PTR was 47743, but live seems to be 48199
			end
			if (882 == mapId) then
				pCodeToAdd = pCodeToAdd .. '+48107'
			end
			if (885 == mapId) then
				pCodeToAdd = pCodeToAdd .. '+48199'
			end
-- TODO: Should add the prerequisites for BfA but it seems the quests are not actually available for a character unless they have qualified for the quest, which means Grail should evaluate properly anyway
			if nil ~= typeModifier then
				typeValue = typeValue + typeModifier
			end
			kCodeToAdd = kCodeToAdd .. typeValue

			self:_LearnKCode(questId, kCodeToAdd)

			if nil == strfind(self.questPrerequisites[questId] or '', strsub(pCodeToAdd, 3), 1, true) then
				self:_LearnQuestCode(questId, pCodeToAdd)
				local codeToAdd = strsub(pCodeToAdd, 3)
				if nil == self.questPrerequisites[questId] then
					self.questPrerequisites[questId] = codeToAdd
				else
					self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToAdd
				end
			end

			-- If we do not already have a T: code of some sort we will create one that is based on turning
			-- in the quest to self in the zone.
			if nil == self.quests[questId] or (nil == self.quests[questId]['T'] and nil == self.quests[questId]['TP']) then
				self:_LearnQuestCode(questId, 'T:-'..mapId)
			end

			if (nil == self.quests[questId] or (nil == self.quests[questId]['A'] and nil == self.quests[questId]['AP'])) and nil ~= mapId then
				local coordinates = strformat("%.2f,%.2f", x * 100 , y * 100)
				if nil ~= coordinates then
					local npcId = self._worldQuestSelfNPCs[mapId][coordinates]
					if nil == npcId then
						npcId = self:_CreateWorldNPC(mapId..':'..coordinates)
						if self.GDE.debug then print("*** did not find NPC for "..mapId..":"..coordinates.." so created a new NPC "..npcId) end
						self._worldQuestSelfNPCs[mapId][coordinates] = npcId
					end
					self:_LearnQuestCode(questId, 'A:'..npcId)
				end
			end
		end,

		-- If there is already a code that starts with the code in codeToAdd we should append to it
		-- with a comma and return true.
		AppendCode = function(self, line, codeToAdd)
			local retval = false
			local newLine = ''
			if nil ~= line and 0 < strlen(line) then
				local codeStart, codeRest = strsplit(':', codeToAdd)
				codeStart = codeStart .. ':'
				local codesInLine = { strsplit(' ', line) }
				local code
				local spacer = ''
				for i = 1, #codesInLine do
					code = codesInLine[i]
					if strsub(code, 1, #codeStart) == codeStart then
						code = code .. ',' .. codeRest
						retval = true
					end
					newLine = newLine .. spacer .. code
					spacer = ' '
				end
			end
			return retval, newLine
		end,

		AliasQuestId = function(self, questId)
			return self:_QuestGenericAccess(questId, 'Y')
		end,

		_AllEvaluateTrueF = function(self, codesTable, p, f, forceSpecificChecksOnly)
			local stillGood, failures = true, {}

			if nil ~= codesTable then
				for key, value in pairs(codesTable) do
					if "table" == type(value) then
						local anyEvaluateTrue, requirementPresent, allFailures = self:_AnyEvaluateTrueF(value, p, f, forceSpecificChecksOnly)
						if requirementPresent then
							stillGood = stillGood and anyEvaluateTrue
						end
						if nil ~= allFailures then self:_TableAppend(failures, allFailures) end
					else
						local good, allFailures = f(value, p, forceSpecificChecksOnly)
						stillGood = stillGood and good
						if nil ~= allFailures then self:_TableAppend(failures, allFailures) end
					end
				end
			end

			if 0 == #failures then failures = nil end
			return stillGood, failures
		end,

		_AllEvaluateTrueS = function(self, codeString, p, f, forceSpecificChecksOnly)
			local stillGood, failures = true, nil
			if nil ~= codeString then
				local start, length = 1, strlen(codeString)
				local stop = length
				local good, allFailures
				local anyEvaluateTrue, requirementPresent
				while start <= length do
					local found = strfind(codeString, "+", start, true)
					if nil == found then
						if 1 < start then
							stop = strlen(codeString)
						end
					else
						stop = found - 1
					end
					local substring = strsub(codeString, start, stop)
					if nil ~= strfind(substring, "|", 1, true) then
						anyEvaluateTrue, requirementPresent, allFailures = self:_AnyEvaluateTrueS(substring, p, f, "|", forceSpecificChecksOnly)
						if requirementPresent then
							stillGood = stillGood and anyEvaluateTrue
						end
					else
						good, allFailures = f(substring, p, forceSpecificChecksOnly)
						stillGood = stillGood and good
					end
					start = stop + 2
					if nil ~= allFailures then
						failures = failures or {}
						self:_TableAppend(failures, allFailures)
					end
				end
			end
			return stillGood, failures
		end,

		AncestorStatusCode = function(self, questId, baseStatusCode)
			local prerequisites = self:QuestPrerequisites(questId, true)

			if nil ~= prerequisites then
				local anyEvaluateTrue, requirementPresent, allFailures = self:_AnyEvaluateTrueF(prerequisites, { q = questId }, Grail._EvaluateCodeDoesNotFailQuestStatus)
				if requirementPresent and not anyEvaluateTrue and nil ~= allFailures then
--					baseStatusCode = baseStatusCode + (1024 * allFailures[1])
					for _, failure in pairs(allFailures) do
						baseStatusCode = bitbor(baseStatusCode, bitband(failure, Grail.bitMaskQuestFailure) * 1024)		-- puts them up into ancestor failure range
						baseStatusCode = bitbor(baseStatusCode, bitband(failure, Grail.bitMaskQuestFailureWithAncestor - Grail.bitMaskQuestFailure))
					end
				end
				
			end

			return baseStatusCode
		end,

		--	This looks at the code with appropriate prefix from the specified log and analyzes it to determine if any of the quests
		--	the code contains have been completed, or if checkLog is true, are in the quest log.  The format for the code is a comma
		--	separated list of single questIds that match or if more than one is required to match, they are separated by a plus.  So:
		--	<br>123,456,789+1122,3344<br>means and of the following quests would match:<br>123<br>456<br>789 and 1122<br>3344<br>
		--	@param questId The standard numeric questId representing a quest.
		--	@param codePrefix An prefix used to determine which type of internal code to process.
		--	@return True if any of the codes quests are completed (or appropriately in the quest log), false otherwise.
		--	@return True is there actually is a code that needed checking, false otherwise.
		_AnyEvaluateTrue = function(self, questId, codePrefix, forceSpecificChecksOnly)
			questId = tonumber(questId)
--			if nil == questId or nil == self.quests[questId] then return false end
			if nil == questId or nil == self.questCodes[questId] then return false end
--			local codeValues = self.quests[questId][codePrefix]
			local codeValues
			if 'P' == codePrefix then
				codeValues = self.questPrerequisites[questId]
			elseif self.quests[questId] then
				codeValues = self.quests[questId][codePrefix]
			else
				return false
			end
			local dangerous = (codePrefix == 'I' or codePrefix == 'B')
			return self:_AnyEvaluateTrueF(codeValues, { q = questId, d = dangerous}, Grail._EvaluateCodeAsPrerequisite, forceSpecificChecksOnly)
		end,

		-- This is part of evaluating a "pattern" set of requirements specified in the codesTable, using
		-- the function f to evaluate whether individual codes meet requirements. The table p contains
		-- parameters to be used by any function.
		_AnyEvaluateTrueF = function(self, codesTable, p, f, forceSpecificChecksOnly)
			if "table" ~= type(codesTable) then return self:_AnyEvaluateTrueS(codesTable, p, f, ',', forceSpecificChecksOnly) end
			local anyEvaluateTrue, requirementPresent, allFailures = false, false, {}

			if nil ~= codesTable then
				local currentFailures, valueToUse
				local noBreak = p and p.noBreak
				requirementPresent = true
				for key, value in pairs(codesTable) do
					valueToUse = ("table" == type(value)) and value or {value}
					anyEvaluateTrue, currentFailures = self:_AllEvaluateTrueF(valueToUse, p, f, forceSpecificChecksOnly)
					if nil ~= currentFailures then
						self:_TableAppend(allFailures, currentFailures)
					end
					if anyEvaluateTrue and not noBreak then break end
				end
			end

			if 0 == #allFailures then allFailures = nil end
			return anyEvaluateTrue, requirementPresent, allFailures
		end,

		_AnyEvaluateTrueS = function(self, codeString, p, f, splitCode, forceSpecificChecksOnly)
			local anyEvaluateTrue, requirementPresent, allFailures = false, false, nil

			splitCode = splitCode or ","
			if nil ~= codeString then
				local currentFailures
				local noBreak = p and p.noBreak
				requirementPresent = true
				local start, length = 1, strlen(codeString)
				local stop = length
				while start <= length do
					local found = strfind(codeString, splitCode, start, true)
					if nil == found then
						if 1 < start then
							stop = strlen(codeString)
						end
					else
						stop = found - 1
					end
					anyEvaluateTrue, currentFailures = self:_AllEvaluateTrueS(strsub(codeString, start, stop), p, f, forceSpecificChecksOnly)
					start = stop + 2
					if nil ~= currentFailures then
						allFailures = allFailures or {}
						self:_TableAppend(allFailures, currentFailures)
					end
-- TODO: Technically we do not use noBreak at the moment, do we are fine, but we should really check to see if anyEvaluateTrue has ever been correct and record that to be used in return
					if anyEvaluateTrue and not noBreak then break end
				end
			end
			return anyEvaluateTrue, requirementPresent, allFailures
		end,

		ArtifactChange = function(self, knowledgeLevel, knowledgeMultiplier)
			self.artifactKnowledgeLevel = knowledgeLevel or 0
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupArtifactKnowledge])
		end,

		GetCurrencyInfo = function(self, currencyIndex)
			local currencyName, currencyAmount = nil, nil
			if GetCurrencyInfo then
				currencyName, currencyAmount = GetCurrencyInfo(currencyIndex)
			elseif C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
				local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyIndex)
				if currencyInfo then
					currencyName = currencyInfo.name
					currencyAmount = currencyInfo.quantity
				end
			end
			return currencyName, currencyAmount
		end,

		CurrencyAmountMeetsOrExceeds = function(self, currencyIndex, soughtAmount)
			local retval = false
			local _, currentAmount = self:GetCurrencyInfo(currencyIndex)
			if nil ~= currentAmount and currentAmount >= soughtAmount then
				retval = true
			end
			return retval
		end,

		ArtifactKnowledgeLevel = function(self)
--	In 7.1 the following API does not work unless the artifact UI is already open.
--			return C_ArtifactUI.GetArtifactKnowledgeLevel()
--	Using the LibArtifactData allows access to the artifact knowledge level, but we need
--	not use this since we can get this information from the hidden currency
--			if self.LAD then
--				self.artifactKnowledgeLevel = self.LAD:GetArtifactKnowledge()
--			end
			local _, artifactKnowledgeCurrency = self:GetCurrencyInfo(1171)
			self.artifactKnowledgeLevel = artifactKnowledgeCurrency or 0
			return self.artifactKnowledgeLevel
		end,

		ArtifactLevelMeetsOrExceeds = function(self, itemId, soughtLevel)
			local retval = false
			local currentLevel = self.artifactLevels[itemId]
			if nil ~= currentLevel and currentLevel >= soughtLevel then
				retval = true
			end
			return retval
		end,

		---
		--	Returns a table of questIds that are available breadcrumb quests for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of questIds for available breadcrumb quests for this quest, or nil if there are none.
		AvailableBreadcrumbs = function(self, questId)
			local retval = {}
			local possible = self:QuestBreadcrumbs(questId)
			if nil ~= possible then
				for _, qid in pairs(possible) do
					if self:CanAcceptQuest(qid, false, true) then
						tinsert(retval, qid)
					end
				end
			end
			if 0 == #retval then retval = nil end
			return retval
		end,

		--	Not used, as the name of the mission will be showin instead...
		_AvailableMissionsRewardItem = function(self, itemId, missionType)
			if itemId > 100000000 then itemId = itemId - 100000000 end
			local retval = false
			local missionTypeToUse = missionType or 4	-- default to those from the class hall map
			local availableMissions = C_Garrison.GetAvailableMissions(missionTypeToUse)
			if nil ~= availableMissions then
				for _, mission in pairs(availableMissions) do
					local rewards = mission.rewards
					if nil ~= rewards then
						for _, reward in pairs(rewards) do
							local possibleItemId = reward.itemID
							if nil ~= possibleItemId then
								if itemId == tonumber(possibleItemId) then
									retval = true
								end
							end
						end
					end
				end
			end
			return retval
		end,

		AzeriteLevelMeetsOrExceeds = function(self, soughtLevel)
			local retval, currentLevel = false, nil
			if C_AzeriteItem then
				if C_AzeriteItem.GetPowerLevel and C_AzeriteItem.FindActiveAzeriteItem then
					local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
					currentLevel = azeriteItemLocation and C_AzeriteItem.GetPowerLevel(azeriteItemLocation) or 0
				end
			end
			if nil ~= currentLevel and currentLevel >= soughtLevel then
				retval = true
			end
			return retval
		end,

		IsMissionAvailable = function(self, missionId, missionType)
			local retval = false
			if nil ~= missionId then
				local missionTypeToUse = missionType or 4	-- default to those from the class hall map
				local availableMissions = C_Garrison.GetAvailableMissions(missionTypeToUse)
				if nil ~= availableMissions then
					for _, mission in pairs(availableMissions) do
						if missionId == mission.missionID then
							retval = true
						end
					end
				end
			end
			return retval
		end,

		-- It seems Blizzard's API C_Garrison.GetBasicMissionInfo() returns an empty result
		-- when the mission is not currently available.  This means when we want to display
		-- the name we will need to display the mission ID instead.
		MissionName = function(self, missionId)
			local retval = nil
			if nil ~= missionId then
				local mission = C_Garrison.GetBasicMissionInfo(missionId)
				if nil ~= mission then
					retval = mission.name
				end
			end
			return retval
		end,

		_BagUpdates = function(type, ignored)
			if nil == Grail.processedBagUpdates then
				if Grail.capabilities.usesArtifacts then
					Grail:_RecordArtifactLevels()
				end
				Grail.processedBagUpdates = true
			end
			local self = Grail
			self.cachedBagItems = nil
			-- we cheat and instead of doing any work here we just invalidate all the quests associated with
			-- items that need to be present or need not be present because the evaluation of status will
			-- check whether items are present
			local t = {}
			for itemId in pairs(self.questStatusCache['C']) do
--				self:_StatusCodeInvalidate(self.questStatusCache['C'][itemId])
				self:_TableAppend(t, self.questStatusCache['C'][itemId])
			end
			for itemId in pairs(self.npcStatusCache['C']) do
				self:_NPCLocationInvalidate(self.npcStatusCache['C'][itemId])
			end
			for itemId in pairs(self.questStatusCache['E']) do
--				self:_StatusCodeInvalidate(self.questStatusCache['E'][itemId])
				self:_TableAppend(t, self.questStatusCache['E'][itemId])
			end
			for itemId in pairs(self.npcStatusCache['E']) do
				self:_NPCLocationInvalidate(self.npcStatusCache['E'][itemId])
			end
			self:_StatusCodeInvalidate(t)
			wipe(t)
		end,

		---
		--	Returns true is the specified quest can be accepted based on the other parameters.  Otherwise returns false.
		--	@param questId The standard numeric questId representing a quest.
		--	@param ignoreCompleted	Ignores the status of the quest being completed.
		--	@param ignorePrerequisites	Ignores whether the quest has met all its prerequisites.
		--	@param ignoreInLog	Ignores whether the quest is already in the Blizzard quest log.
		--	@param ignoreLevelTooLow	Ignores whether the quest is too high for the player to obtain currently.
		--	@param ignoreHolidayRequirement	Ignores whether the quest is only available during specific holidays.
		--	@param buggedQuestsUnacceptable Specifies whether bugged quests are considered unacceptable.
		CanAcceptQuest = function(self, questId, ignoreCompleted, ignorePrerequisites, ignoreInLog, ignoreLevelTooLow, ignoreHolidayRequirement, buggedQuestsUnacceptable)
			local bitValue = self.bitMaskAcceptableMask
			if ignoreCompleted then bitValue = bitValue - self.bitMaskCompleted end
			if ignorePrerequisites then bitValue = bitValue - self.bitMaskPrerequisites end
			if ignoreInLog then bitValue = bitValue - self.bitMaskInLog - self.bitMaskInLogComplete end
			if ignoreLevelTooLow then bitValue = bitValue - self.bitMaskLevelTooLow end
			if ignoreHolidayRequirement then bitValue = bitValue - self.bitMaskHoliday end
			if buggedQuestsUnacceptable then bitValue = bitValue + self.bitMaskBugged end
			return (0 == bitband(self:StatusCode(questId), bitValue) and not self:IsQuestObsolete(questId) and not self:IsQuestPending(questId))
		end,

		-- These are the eventIds associated with Timewalking Dungeons
		celebratingHolidayEventIdMapping = {	["g"] = 559, -- The Burning Crusade
												["h"] = 562, -- Wrath of the Lich King
												["i"] = 9999, -- Cataclysm
												["j"] = 9999, -- Mists of Pandaria
												["k"] = 1056, -- Warlords of Draenor
												["l"] = 9999, -- Legion
											},
		---
		--	This returns true if the specified holiday is currently being celebrated based on the calendar event.
		_CelebratingHolidayDayEventProcessor = function(self, soughtHolidayName, event)
			local retval = false
			local holidayNameToUse = soughtHolidayName
			local holidayCode = self.reverseHolidayMapping[soughtHolidayName]
			if nil ~= self.celebratingHolidayEventIdMapping[holidayCode] then
				holidayNameToUse = self.holidayMapping['f']
			end
			if event.calendarType == 'HOLIDAY' and event.title == holidayNameToUse then
				local shouldContinue = true
				local possibleEventId = self.celebratingHolidayEventIdMapping[holidayCode]
				if nil ~= possibleEventId and tonumber(event.eventID) ~= possibleEventId then
					shouldContinue = false
				end
				if shouldContinue then
					local sequenceType = event.sequenceType
					if sequenceType == 'ONGOING' then
						retval = true
					else
						local weekday, month, day, year, hour, minute = self:CurrentDateTime()
						local elapsedMinutes = hour * 60 + minute
						local date = (sequenceType == "END") and event.endTime or event.startTime
						local eventMinutes = date.hour * 60 + date.minute
						if sequenceType == 'START' and elapsedMinutes >= eventMinutes then
							retval = true
						end
						if sequenceType == 'END' and elapsedMinutes < eventMinutes then
							retval = true
						end
					end
				end
			end
			return retval
		end,

-- Hallows 10/18 10h00 -> 11/01 11h00

		celebratingHolidayCache = {},	-- key is holidayName, value is table with key of date/time and value of 0(false) or 1(true)

		CelebratingClassicDarkmoonFaire = function(self, includesPrecedingWeekend)
			local retval = false
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
			-- Darkmoon Faire - first week from Monday to Sunday following first Friday in month
			local weekdayToUse = (weekday == 1) and 8 or weekday
			local thisOrLastMonday = day - weekdayToUse + 2
			if thisOrLastMonday >= 4 and thisOrLastMonday <= 10 then
				retval = true
			end
			-- For some quests they are available from the start of the Darkmoon Faire setup
			if not retval and includesPrecedingWeekend then
				if weekday == 6 and day < 8 then	-- Friday
					retval = true
				elseif weekday == 7 and day >= 2 and day < 9 then	-- Saturday
					retval = true
				elseif weekday == 1 and day >= 3 and day < 10 then	-- Sunday
					retval = true
				end
			end
			return retval
		end,
	
		---
		--	Determines whether the soughtHolidayName is currently being celebrated.
		--	@param soughtHolidayName The localized name of a holiday, like Brewfest or Darkmoon Faire.
		--	@return true if the holiday is being celebrated currently, or false otherwise
		CelebratingHoliday = function(self, soughtHolidayName)
			local retval = false
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
			local elapsedMinutes = hour * 60 + minute
			local datetimeKey = strformat("%4d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
			local holidayCode = self.reverseHolidayMapping[soughtHolidayName] or '?'
			if self.celebratingHolidayCache[soughtHolidayName] and self.celebratingHolidayCache[soughtHolidayName][datetimeKey] then
				retval = (self.celebratingHolidayCache[soughtHolidayName][datetimeKey] == 1)
			elseif 'V' == holidayCode and self.existsClassic then
				if 2019 == year and 12 == month and day >= 17 then
					retval = true
				end
			elseif 'F' == holidayCode and self.existsClassic then
				retval = self:CelebratingClassicDarkmoonFaire()
			elseif 'G' == holidayCode and self.existsClassic then
				retval = self:CelebratingClassicDarkmoonFaire(true)
			elseif 'L' == holidayCode and self.existsClassic then
				-- Lunar Festival 2/1 -> 2/7 10h00
				if 2020 == year and 2 == month and (day <= 6 or (7 == day and (elapsedMinutes <= 10 * 60))) then
					retval = true
				end
				if 2021 == year and 2 == month and (day >=5 and (day < 19 or (day == 19 and elapsedMinutes <= 10 * 60))) then
					retval = true
				end
			elseif 'A' == holidayCode and self.existsClassic then
				-- Love is in the Air 2/11 -> 2/16
				if 2020 == year and 2 == month and day >= 11 and day <= 16 then
					retval = true
				end
				if 2021 == year and 2 == month and day >= 12 and day <= 26 then
					retval = true
				end
			elseif 'N' == holidayCode and self.existsClassic then
				-- Noble Garden 4/13 -> 4/19
				if 2020 == year and 4 == month and day >= 13 and day <= 19 then
					retval = true
				end
			elseif 'C' == holidayCode and self.existsClassic then
				-- Children's Week 5/1 -> 5/7
				if 2020 == year and 5 == month and day <= 7 then
					retval = true
				end
			elseif 'M' == holidayCode and self.existsClassic then
				-- Midsummer Fire Festival 6/21 10h00 -> 7/5 10h00
				if 2020 == year then
					if 6 == month then
						if day >= 22 or (day == 21 and (elapsedMinutes >= 10 * 60)) then
							retval = true
						end
					elseif 7 == month then
						if day <= 4 or (day == 5 and (elapsedMinutes <= 10 * 60)) then
							retval = true
						end
					end
				end
			elseif 'Q' == holidayCode and self.existsClassic then
				-- Ahn'Q
				if 2020 == year then
					if (month == 7 and day >= 29) or month > 7 then
						retval = true
					end
				end
			elseif 'Z' == holidayCode then
				if 12 == month and day >= 25 then
					retval = true
				end
			elseif 'U' == holidayCode then
				if 12 == month and 31 == day then
					retval = true
				end
			elseif 'X' == holidayCode then
				-- Stranglethorn Fishing Extravaganza quest givers appear on Saturday and Sunday
				if 1 == weekday or 7 == weekday then
					retval = not self.existsClassic
				end
			elseif 'K' == holidayCode then
				-- Kalu'ak Fishing Derby quest giver appears on Saturday between 14h00 and 16h00 server
				-- This seems to have been removed in 5.1.0 but code remains
				if weekday == 7 then
					if elapsedMinutes >= (14 * 60) and elapsedMinutes <= (16 * 60) then
						retval = true
					end
				end
			elseif 'E' == holidayCode then
				-- WoW Anniversary is second half of November
				if 11 == month and 15 < day then
					retval = true
				end
			else
				if self.capabilities.usesCalendar then
					C_Calendar.SetAbsMonth(month, year)
					C_Calendar.OpenCalendar()
				end
				local CalendarGetNumDayEvents = (self.existsClassic and function() return 0 end) or (self.battleForAzeroth and C_Calendar.GetNumDayEvents) or CalendarGetNumDayEvents
				local numEvents = CalendarGetNumDayEvents(0, day)
				for i = 1, numEvents do
					local event = C_Calendar.GetDayEvent(0, day, i)
					retval = self:_CelebratingHolidayDayEventProcessor(soughtHolidayName, event)
					if retval then break end
				end
			end
			self.celebratingHolidayCache[soughtHolidayName] = {}
			self.celebratingHolidayCache[soughtHolidayName][datetimeKey] = (retval and 1 or 0)
			return retval
		end,

		--	This returns a character based on how the quest is "classified".
		--		B	unobtainable
		--		C	completed
		--		D	daily
		--		G	can accept
		--		H	daily that is too high
		--		I	in log
		--		K	weekly
		--		L	too high
		--		O	world quest
		--		P	fails (prerequisites)
		--		R	repeatable
		--		U	unknown
		--		W	low-level	
		--		Y	legendary
		ClassificationOfQuestCode = function(self, questCode, shouldDisplayHolidays, buggedQuestsUnobtainable)
			local retval = 'U'
			local code, subcode, numeric = self:CodeParts(questCode)

			if nil ~= numeric then
				if code == 'BOGUS' then
					--	Nothing here, this is just to put all the rest in elseif
				elseif 'F' == code then
					if ('A' == subcode and 'Alliance' == self.playerFaction) or ('H' == subcode and 'Horde' == self.playerFaction) then
						retval = 'C'
					else
						retval = 'B'
					end
				elseif 'G' == code then
					if '' == subcode then
						retval = self:HasGarrisonBuilding(numeric) and 'C' or 'P'
					else
						retval = self:HasGarrisonBuildingInPlot(numeric, subcode) and 'C' or 'P'
					end
				elseif 'z' == code then
					retval = self:HasGarrisonBuildingNPCWorking(numeric) and 'C' or 'P'
				elseif 'I' == code then
					retval = self:SpellPresent(numeric) and 'C' or 'P'
				elseif 'i' == code then
					retval = self:SpellPresent(numeric) and 'P' or 'C'
				elseif 'J' == code then
					retval = self:AchievementComplete(numeric) and 'C' or 'G'
				elseif 'j' == code then
					retval = self:AchievementComplete(numeric) and 'B' or 'C'
				elseif 'K' == code then
					retval = self:ItemPresent(numeric, subcode) and 'C' or 'P'
				elseif 'k' == code then
					retval = self:ItemPresent(numeric, subcode) and 'P' or 'C'
				elseif 'L' == code then
					retval = (self.levelingLevel >= numeric) and 'C' or 'P'
				elseif 'l' == code then
					retval = (self.levelingLevel < numeric) and 'C' or 'P'
				elseif 'M' == code then
					retval = self:HasQuestEverBeenAbandoned(numeric) and 'C' or 'P'
				elseif 'm' == code then
					retval = self:HasQuestEverBeenAbandoned(numeric) and 'P' or 'C'
				elseif 'N' == code then
					retval = (self.classNameToCodeMapping[self.playerClass] == subcode) and 'C' or 'B'
				elseif 'n' == code then
					retval = (self.classNameToCodeMapping[self.playerClass] == subcode) and 'B' or 'C'
				elseif 'P' == code then
					retval = self:ProfessionExceeds(subcode, numeric) and 'C' or 'P'
				elseif 'R' == code then
					retval = self:EverExperiencedSpell(numeric) and 'C' or 'P'
				elseif 'r' == code then
					retval = self:MeetsRequirementGroupControl({groupNumber = subcode, minimum = numeric, inLog = true, turnedIn = true, exactMatch = true }) and 'C' or 'P'
				elseif 'S' == code then
					retval = self:_HasSkill(numeric) and 'C' or 'P'
				elseif 's' == code then
					retval = self:_HasSkill(numeric) and 'P' or 'C'
				elseif 'T' == code or 't' == code then
					local exceeds, earnedValue = Grail:_ReputationExceeds(Grail.reputationMapping[subcode], numeric)
					retval = 'P'
					if (not exceeds and code == 't') or (exceeds and code == 'T') then
						retval = 'C'
					end
				elseif 'U' == code or 'u' == code then
					local exceeds, earnedValue = Grail:_FriendshipReputationExceeds(Grail.reputationMapping[subcode], numeric)
					retval = 'P'
					if (not exceeds and code == 'u') or (exceeds and code == 'U') then
						retval = 'C'
					end
				elseif 'V' == code then
					retval = self:MeetsRequirementGroupControl({groupNumber = subcode, minimum = numeric, accepted = true}) and 'C' or 'P'
				elseif 'v' == code then
					retval = self:_QuestTurnedInBeforeLastWeeklyReset(numeric) and 'C' or 'P'
				elseif 'W' == code then
					retval = self:MeetsRequirementGroupControl({groupNumber = subcode, minimum = numeric, turnedIn = true}) and 'C' or 'P'
				elseif 'w' == code then
					retval = self:MeetsRequirementGroupControl({ groupNumber = subcode, minimum = numeric, turnedIn = true, completeInLog = true}) and 'C' or 'P'
				elseif 'x' == code then
					retval = (Grail:ArtifactKnowledgeLevel() >= numeric) and 'C' or 'P'
				elseif 'Y' == code then
					retval = self:AchievementComplete(numeric, true) and 'C' or 'G'
				elseif 'y' == code then
					retval = self:AchievementComplete(numeric, true) and 'G' or 'C'
				elseif 'Z' == code then
					retval = self:_EverCastSpell(numeric) and 'C' or 'P'
				elseif '=' == code or '<' == code or '>' == code then
					retval = self:_PhaseMatches(code, subcode, numeric) and 'C' or 'P'
				elseif 'Q' == code or 'q' == code then
					retval = self:_iLvlMatches(code, numeric) and 'C' or 'P'
				elseif 'a' == code or 'b' == code or '^' == code then
					retval = self:IsAvailable(numeric) and 'C' or 'P'
				elseif '@' == code then
					retval = self:ArtifactLevelMeetsOrExceeds(subcode, numeric) and 'C' or 'P'
				elseif '#' == code then
					retval = self:IsMissionAvailable(numeric) and 'C' or 'P'
				elseif '&' == code then
					retval = self:AzeriteLevelMeetsOrExceeds(numeric) and 'C' or 'P'
				elseif '$' == code then
					retval = self:_CovenantRenownMeetsOrExceeds(subcode, numeric) and 'C' or 'P'
				elseif '*' == code then
					retval = self:_CovenantRenownMeetsOrExceeds(subcode, numeric) and 'P' or 'C'
				elseif '%' == code then
					retval = self:_GarrisonTalentResearched(numeric) and 'C' or 'P'
				elseif '(' == code then
					retval = self:_QuestTurnedInBeforeTodaysReset(numeric) and 'C' or 'P'
				elseif ')' == code then
					retval = self:CurrencyAmountMeetsOrExceeds(subcode, numeric) and 'C' or 'P'
				elseif '_' == code or '~' == code then
					retval = self:MajorFactionRenownLevelMeetsOrExceeds(Grail.reputationMapping[subcode], numeric, code == '~') and 'C' or 'P'
				elseif '`' == code then
					retval = self:POIPresent(subcode, numeric) and 'C' or 'P'
				elseif 'h' == code then
					retval = (bitband(questBitMask, self.bitMaskEverCompleted) > 0) and 'P' or 'C'
				else	-- A, B, C, D, E, H, O, X
					local questBitMask = self:StatusCode(numeric)
					local questTypeMask = self:CodeType(numeric)
					if shouldDisplayHolidays then
						if bitband(questBitMask, self.bitMaskHoliday) > 0 then
							questBitMask = questBitMask - self.bitMaskHoliday
						end
						if bitband(questBitMask, self.bitMaskAncestorHoliday) > 0 then
							questBitMask = questBitMask - self.bitMaskAncestorHoliday
						end
					end
					if code == 'H' and bitband(questBitMask, self.bitMaskEverCompleted) > 0 then		-- special case where we want the fact that the quest was ever completed to take priority
						retval = 'C'
					elseif bitband(questBitMask, self.bitMaskNonexistent + self.bitMaskError) > 0 then
						retval = 'U'
					elseif bitband(questBitMask, self.bitMaskInLog) > 0 then
						retval = 'I'
					elseif bitband(questBitMask, self.bitMaskQuestFailureWithAncestor
													+ (buggedQuestsUnobtainable and self.bitMaskBugged or 0)
													) > 0 or self:IsQuestObsolete(numeric) or self:IsQuestPending(numeric) then
						retval = 'B'
					elseif bitband(questBitMask, self.bitMaskCompleted + self.bitMaskRepeatable) == self.bitMaskCompleted then
						if 'X' == code then
							retval = 'B'
						else
							retval = 'C'
						end
					elseif bitband(questBitMask, self.bitMaskPrerequisites) > 0 then
						retval = 'P'
					elseif self:IsDaily(numeric) then	-- self.bitMaskResettable contains IsWeekly, IsMonthly and IsYearly, so we do not use because 	Blizzard shows yellow
						if bitband(questBitMask, self.bitMaskLevelTooLow) > 0 then
							retval = 'H'
						elseif self:IsWeekly(numeric) then
							retval = 'K'
						else
							retval = 'D'
						end
					elseif bitband(questBitMask, self.bitMaskRepeatable) > 0 then
						retval = 'R'
					elseif bitband(questBitMask, self.bitMaskLevelTooLow) > 0 then
						retval = 'L'
					elseif bitband(questBitMask, self.bitMaskLowLevel) > 0 then
						retval = 'W'
					elseif bitband(questTypeMask, self.bitMaskQuestLegendary) > 0 then
						retval = 'Y'
					elseif bitband(questTypeMask, self.bitMaskQuestWorldQuest) > 0 then
						retval = 'O'
					elseif self:IsWeekly(numeric) then
						retval = 'K'
					else
						retval = 'G'
					end
				end
			end
			return retval, code, subcode, numeric
		end,

		_CleanCheckNPC = function(self, code, npcId, questId)
			local allCodesGood = true
			if nil == code or "" == code then
				allCodesGood = false
			elseif nil == npcId then
				allCodesGood = false
			elseif nil == questId then
				allCodesGood = false
			elseif nil == self.quests[questId] then
				allCodesGood = false
			elseif 0 == npcId then
				local foundAny = false
				if nil ~= self.quests[questId][code] then
					for _, n in pairs(self.quests[questId][code]) do
						local n1 = tonumber(n)
						if n1 ~= nil and n1 <= 0 then foundAny = true end
					end
				end
				if not foundAny then allCodesGood = false end
			elseif (nil == self.quests[questId][code] or (not tContains(self.quests[questId][code], npcId) and not self:_ContainsAliasNPC(self.quests[questId][code], npcId))) and (nil == self.quests[questId][code..'P'] and not self:_ContainsPrerequisiteNPC(self.quests[questId][code..'P'], npcId)) then
				allCodesGood = false
			end
			return allCodesGood
		end,

		_NPCsMatch = function(self, npcId1, npcId2)
			local retval = false
			npcId1 = tonumber(npcId1)
			npcId2 = tonumber(npcId2)
			if npcId1 == npcId2 then
				retval = true
			elseif npcId1 == 0 and npcId2 < 0 then
				retval = true
			elseif npcId2 == 0 and npcId1 < 0 then
				retval = true
			elseif Grail.npc.aliases[npcId1] and tContains(Grail.npc.aliases[npcId1], npcId2) then
				retval = true
			end
			return retval
		end,

		--	The preqTable is from AP: or TP:, and the nonPreqTable is from A: or T:
		_GoodNPC = function(self, npcId, preqTable, nonPreqTable)
			local retval = false
			npcId = tonumber(npcId)
			if nil ~= npcId then
				if nil ~= preqTable then
					for anNPCId, _ in pairs(preqTable) do
						retval = self:_NPCsMatch(anNPCId, npcId)
						if retval then break end
					end
				end
				if not retval and nil ~= nonPreqTable then
					for _, anNPCId in pairs(nonPreqTable) do
						retval = self:_NPCsMatch(anNPCId, npcId)
						if retval then break end
					end
				end
			end
			return retval
		end,

		_GoodNPCAccept = function(self, questId, npcId)
			return self:_GoodNPC(npcId, self:QuestNPCPrerequisiteAccepts(questId), self:QuestNPCAccepts(questId))
		end,

		_GoodNPCTurnin = function(self, questId, npcId)
			return self:_GoodNPC(npcId, self:QuestNPCPrerequisiteTurnins(questId), self:QuestNPCTurnins(questId))
		end,

		_CleanDatabaseLearnedNPCLocation = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.NPC_LOCATION then
				local newNPCLocations = {}
				for _, npcLocationLine in pairs(self.GDE.learned.NPC_LOCATION) do
					local shouldAdd = true
					local release, locale, npcId, npcLocation, aliasId = strsplit('|', npcLocationLine)
					npcId = tonumber(npcId)
					-- Note that we are not checking to ensure the locale matches self.playerLocale because locations should be universal
					if nil ~= npcId then
						if npcLocation ~= "" and not self:_LocationKnown(npcId, npcLocation, aliasId) then
							self:_AddNPCLocation(npcId, npcLocation, aliasId)
						else
							shouldAdd = false
						end
					end
					if shouldAdd then
						tinsert(newNPCLocations, npcLocationLine)
					end
				end
				self.GDE.learned.NPC_LOCATION = newNPCLocations
			end
		end,

		_CleanDatabaseLearnedObjectName = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.OBJECT_NAME then
				local newObjectNames = {}
				for _, objectNameLine in pairs(self.GDE.learned.OBJECT_NAME) do
					local shouldAdd = true
					local release, locale, objectId, objectName = strsplit('|', objectNameLine)
					objectId = tonumber(objectId)
					if objectId > 1000000 then
						objectId = objectId - 1000000
					end
					if locale == self.playerLocale and nil ~= objectId then
						local storedObjectName = self:ObjectName(objectId)
						if nil == storedObjectName or storedObjectName ~= objectName then
							self.npc.name[1000000 + objectId] = objectName
						else
							shouldAdd = false
						end
					end
					if shouldAdd then
						tinsert(newObjectNames, objectNameLine)
					end
				end
				self.GDE.learned.OBJECT_NAME = newObjectNames
			end
		end,

		-- This transforms the older database entry into the newer one stored in QUEST_CODE.
		_CleanDatabaseLearnedQuest = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.QUEST then
				-- Because we are using _LearnQuestCode() to populate, and we want to mark these entries
				-- as something special, we reset self.blizzardRelease for the time being.
				local realBlizzardRelease = self.blizzardRelease
				self.blizzardRelease = 0
				for questId, questLine in pairs(self.GDE.learned.QUEST) do
					local codes = { strsplit(' ', questLine) }
					for c = 1, #codes do
						local currentCode = codes[c]
						if '' ~= currentCode then
							-- The only codes that could have a comma in them should be P:, A: and T: and
							-- since we want to break up A: and T: we should be able to detect the need to
							-- break things up with the following check.
							if 'P' ~= strsub(currentCode, 1, 1) and strfind(currentCode, ',') then
								local codeType = strsub(currentCode, 1, 2)
								local remainder = strsub(currentCode, 3)
								local remainders = { strsplit(',', remainder) }
								for r = 1, #remainders do
									self:_LearnQuestCode(questId, codeType .. remainders[r])
								end
							else
								self:_LearnQuestCode(questId, currentCode)
							end
						end
					end
				end
				self.blizzardRelease = realBlizzardRelease
				self.GDE.learned.QUEST = nil
			end
		end,

		_UpdateWorldQuestSelfNPC = function(self, npcId)
			npcId = tonumber(npcId)
			if nil ~= npcId and npcId > self.worldNPCBase and npcId < self.worldNPCBase + 1000000 then
				local locations = self:NPCLocations(npcId, false, true)
				if nil ~= locations then
					for _, npc in pairs(locations) do
						if nil ~= npc.mapArea and nil ~= npc.x and nil ~= npc.y then
							local coordinates = strformat("%.2f,%.2f", npc.x, npc.y)
							self._worldQuestSelfNPCs[npc.mapArea] = self._worldQuestSelfNPCs[npc.mapArea] or {}
							self._worldQuestSelfNPCs[npc.mapArea][coordinates] = npcId
						end
					end
				end
			end
		end,

		-- This assumes that QUEST_CODE entries are single entries like most of the rest of the learned database.  This should make it easier to process.
		_CleanDatabaseLearnedQuestCode = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.QUEST_CODE then
				local newQuestCodes = {}
				for _, questCodeLine in pairs(self.GDE.learned.QUEST_CODE) do
					local shouldAdd = true
					local grailVersion, release, locale, questId, questCode = strsplit('|', questCodeLine)
					grailVersion = tonumber(grailVersion)
					-- If we have one fewer values than expected, we are in an older version where we do not have the grailVersion recorded per entry.
					if nil == questCode then
						questCode = questId
						questId = locale
						locale = release
						release = grailVersion
						grailVersion = 114
					end
					questId = tonumber(questId)
					-- Note that we are not checking to ensure the locale matches self.playerLocale because quest codes should be universal
					if questId ~= nil and questCode ~= nil and 1 < strlen(questCode) then
						local code = strsub(questCode, 1, 1)
						local subcode = strsub(questCode, 2, 2)
						if 'A' == code and ':' == subcode then
							local npcId = tonumber(strsub(questCode, 3)) or 0
							if npcId >= 3000000 and npcId < 4000000 then
								shouldAdd = (nil ~= self.npc.aliases[npcId])
							elseif self:_GoodNPCAccept(questId, npcId) then
								shouldAdd = false
							else
								self:_UpdateWorldQuestSelfNPC(npcId)
								self.quests[questId] = self.quests[questId] or {}
								self.quests[questId]['A'] = self:_TableAppendCodes(self:_FromList(npcId), self.quests[questId], { 'A' })
							end
						elseif 'T' == code and ':' == subcode then
							local npcId = tonumber(strsub(questCode, 3)) or 0
							if npcId >= 3000000 and npcId < 4000000 then
								shouldAdd = (nil ~= self.npc.aliases[npcId])
							elseif self:_GoodNPCTurnin(questId, npcId) then
								shouldAdd = false
							else
								self:_UpdateWorldQuestSelfNPC(npcId)
								self.quests[questId] = self.quests[questId] or {}
								self.quests[questId]['T'] = self:_TableAppendCodes(self:_FromList(npcId), self.quests[questId], { 'T' })
							end
						elseif 'K' == code then
							shouldAdd = self:_LearnKCode(questId, questCode, true)
						elseif 'L' == code then
							local questLevel, questLevelRequired
							if grailVersion < 115 then
								questLevel, questLevelRequired = self:QuestLevelsFromString(strsub(questCode, 2), true)
							else
								questLevel = tonumber(strsub(questCode, 2)) or 0
								questLevelRequired = questLevel
							end
							if 0 ~= questLevel then
								local questLevelMatches = (self:QuestLevel(questId) == questLevel)
								local questLevelRequiredMatches = (self:QuestLevelRequired(questId) == questLevelRequired)
								if (questLevelMatches and questLevelRequiredMatches) or 0 == self:_QuestLevelMatchesRangeInDatabase(questId, questLevelRequired) then
									shouldAdd = false
								else
									if not questLevelMatches then
										self:_SetQuestLevel(questId, questLevel)
									end
									if not questLevelRequiredMatches then
										self:_SetQuestRequiredLevel(questId, questLevelRequired)
									end
								end
							end
						elseif 'N' == code then
							local suggestedVariableLevel = tonumber(strsub(questCode, 2))
							if suggestedVariableLevel == self:QuestLevel(questId) then
								shouldAdd = false
							elseif suggestedVariableLevel == self:QuestLevelVariableMax(questId) then
								shouldAdd = false
							else
								self:_SetQuestVariableLevel(questId, suggestedVariableLevel)
							end
						elseif 'P' == code and ':' == subcode then
							local codeToSeek = strsub(questCode, 3)
							if nil == strfind(self.questPrerequisites[questId] or '', codeToSeek, 1, true) then
								if nil == self.questPrerequisites[questId] then
									self.questPrerequisites[questId] = codeToSeek
								else
									self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToSeek
								end
							else
								shouldAdd = false
							end
						end
					end
					if shouldAdd then
						tinsert(newQuestCodes, questCodeLine)
					end
				end
				self.GDE.learned.QUEST_CODE = newQuestCodes
			end
		end,

		_CleanDatabaseLearnedQuestName = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.QUEST_NAME then
				local newQuestNames = {}
				for _, questNameLine in pairs(self.GDE.learned.QUEST_NAME) do
					local shouldAdd = true
					local locale, release, questId, questName = strsplit('|', questNameLine)
					questId = tonumber(questId)
					if locale == self.playerLocale and nil ~= questId then
						local storedQuestName = self.quest.name[questId]
						if nil == storedQuestName or storedQuestName ~= questName then
							self.quest.name[questId] = questName
						else
							shouldAdd = false
						end
					end
					if shouldAdd then
						tinsert(newQuestNames, questNameLine)
					end
				end
				self.GDE.learned.QUEST_NAME = newQuestNames
			end
		end,

		_CleanDatabaseLearnedQuestReputation = function(self)
			self.GDE.learned = self.GDE.learned or {}
			if nil ~= self.GDE.learned.QUEST_REPUTATION then
				local newQuestReputations = {}
				for _, line in pairs(self.GDE.learned.QUEST_REPUTATION) do
					local shouldAdd = true
					local c = { strsplit('|', line) }
					-- Format: grailVersion|release|locale|questId|factionCode|amount
					if #c == 6 then
						local questId     = tonumber(c[4])
						local factionCode = c[5]
						local amount      = c[6]
						if nil ~= questId and #factionCode == 3 and not factionCode:find('^N:') then
							local questRep = self.questReputations[questId]
							-- questReputations values are binary strings after Grail-Reputations
							-- loads and its trailer runs (_ReputationCode encoding, 4 bytes per entry).
							-- If the value is still a table the trailer has not run yet -- skip.
							if nil ~= questRep and type(questRep) == 'string' then
								if nil ~= strfind(questRep, self:_ReputationCode(factionCode .. amount), 1, true) then
									shouldAdd = false
								end
							end
						end
					end
					if shouldAdd then
						tinsert(newQuestReputations, line)
					end
				end
				self.GDE.learned.QUEST_REPUTATION = newQuestReputations
			end
		end,

		_LearnNPCLocation = function(self, npcId, npcLocation, aliasNPCId)
			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.NPC_LOCATION = self.GDE.learned.NPC_LOCATION or {}
			local aliasString = aliasNPCId and ('|' .. aliasNPCId) or ''
			tinsert(self.GDE.learned.NPC_LOCATION, self.blizzardRelease .. '|' .. self.playerLocale .. '|' .. npcId .. '|' .. npcLocation .. aliasString)
			self:_AddNPCLocation(npcId, npcLocation, aliasNPCId)
		end,

		_LearnObjectName = function(self, objectId, objectName)
			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.OBJECT_NAME = self.GDE.learned.OBJECT_NAME or {}
			tinsert(self.GDE.learned.OBJECT_NAME, self.blizzardRelease .. '|' .. self.playerLocale .. '|' .. objectId .. '|' .. objectName)
			self.npc.name[1000000 + tonumber(objectId)] = objectName
		end,

		_LearnQuestCode = function(self, questId, questCode)
			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.QUEST_CODE = self.GDE.learned.QUEST_CODE or {}
			-- The Grail version is added because we need to be able to differentiate between different questCode structures
			tinsert(self.GDE.learned.QUEST_CODE, self.versionNumber .. '|' .. self.blizzardRelease .. '|' .. self.playerLocale .. '|' .. questId .. '|' .. questCode)
		end,

		_LearnQuestName = function(self, questId, questName)
			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.QUEST_NAME = self.GDE.learned.QUEST_NAME or {}
			-- Note that the order of locale and release is reversed here, but we need to keep it that way for data that was
			-- written historically.
			tinsert(self.GDE.learned.QUEST_NAME, self.playerLocale .. '|' .. self.blizzardRelease .. '|' .. questId .. '|' .. questName)
		end,

		---
		--	Records a faction reputation reward observed when turning in a quest.
		--	Called from the QUEST_TURNED_IN handler after consuming pendingRepChanges.
		--	Format: grailVersion|release|locale|questId|factionId|amount
		--	  factionId : 3-digit uppercase hex faction ID (e.g. "A90" for faction 2704)
		--	             OR the raw localized faction name prefixed with "N:" if the hex ID
		--	             could not be resolved via reverseReputationMapping
		--	  amount    : signed integer rep change (positive = gain, negative = loss)
		--
		_LearnQuestReputation = function(self, questId, factionId, amount)
			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.QUEST_REPUTATION = self.GDE.learned.QUEST_REPUTATION or {}
			tinsert(self.GDE.learned.QUEST_REPUTATION,
				self.versionNumber .. '|' .. self.blizzardRelease .. '|' ..
				self.playerLocale .. '|' .. questId .. '|' .. factionId .. '|' .. amount)
		end,

		---
		--	Records a prerequisite verification observation for the given target quest.
		--	Called when a quest with unverified prerequisites is seen as available at an NPC.
		--	Format: grailVersion|release|locale|targetQuestId|allPrereqIds|completedPrereqIds|lastTurnedIn
		--	  allPrereqIds    : all P: prereq IDs (both confirmed and ? ones)
		--	  completedPrereqIds : which of those were already done when the quest appeared
		--	  lastTurnedIn    : most recently turned-in ?-prereq before this quest appeared (0 if unknown)
		--
		--	Observations are useful when:
		--	  (a) at least one ?-prereq was NOT yet done (lets us eliminate absent ones), OR
		--	  (b) lastTurnedIn is known (identifies the trigger prereq even if all were done)
		_LearnPrereqVerification = function(self, targetQuestId)
			local allPrereqs = self.questVerifyAllPrereqs[targetQuestId]
			local unverified = self.questUnverifiedPrereqs[targetQuestId]
			if nil == allPrereqs or nil == unverified then return end

			-- Determine which prereqs are currently complete
			local completed = {}
			for _, prereqId in ipairs(allPrereqs) do
				if self:IsQuestFlaggedCompleted(prereqId) then
					tinsert(completed, prereqId)
				end
			end

			-- Check whether any ?-prereq was absent (useful for elimination)
			local hasUsefulData = false
			for _, uid in ipairs(unverified) do
				local found = false
				for _, cid in ipairs(completed) do
					if cid == uid then found = true; break end
				end
				if not found then hasUsefulData = true; break end
			end

			-- Also useful if we know which prereq was the trigger (lastTurnedIn)
			local lastTurnedIn = self.recentPrereqTurnIn[targetQuestId] or 0
			if not hasUsefulData and lastTurnedIn == 0 then return end

			-- Build comma-separated id lists for the record
			local allStr = ''
			for i = 1, #allPrereqs do
				if i > 1 then allStr = allStr .. ',' end
				allStr = allStr .. allPrereqs[i]
			end
			local completedStr = ''
			for i = 1, #completed do
				if i > 1 then completedStr = completedStr .. ',' end
				completedStr = completedStr .. completed[i]
			end

			self.GDE.learned = self.GDE.learned or {}
			self.GDE.learned.PREREQ_VERIFY = self.GDE.learned.PREREQ_VERIFY or {}
			tinsert(self.GDE.learned.PREREQ_VERIFY,
				self.versionNumber .. '|' .. self.blizzardRelease .. '|' ..
				self.playerLocale .. '|' .. targetQuestId .. '|' ..
				allStr .. '|' .. completedStr .. '|' .. lastTurnedIn)

			-- Clear the trigger record; it has been captured in the observation
			self.recentPrereqTurnIn[targetQuestId] = nil
		end,

		--	Convenience: ensures the quest is parsed then records a verification observation if applicable.
		_CheckAndLearnPrereqVerification = function(self, questId)
			if nil == questId then return end
			self:_CodeAllFixed(questId)
			if nil ~= self.questUnverifiedPrereqs[questId] then
				self:_LearnPrereqVerification(questId)
			end
		end,

		--	This should only be run after _CleanLearnedDatabase() because it is assumed anything
		--	present at this point in the learned database will be integrated into the master.
		_UpdateDatabaseFromLearnedDatabase = function(self)
			local locale = GetLocale()
			if nil ~= self.GDE.learned then
--				if nil ~= self.GDE.learned.OBJECT_NAME then
--					for _, objectLine in pairs(self.GDE.learned.OBJECT_NAME) do
--						local ver, loc, objId, objName = strsplit('|', objectLine)
--						if loc == locale and self:ObjectName(objId) ~= objName then
--							self.npc.name[1000000 + tonumber(objId)] = objName
--						end
--					end
--				end
--				if nil ~= self.GDE.learned.NPC_LOCATION then
--					for _, npcLine in pairs(self.GDE.learned.NPC_LOCATION) do
--						local ver, loc, npcId, npcLoc, aliasId = strsplit('|', npcLine)
--						if nil ~= npcId and not self:_LocationKnown(npcId, npcLoc, aliasId) then
--							self:_AddNPCLocation(npcId, npcLoc, aliasId)
--						end
--					end
--				end
--				if nil ~= self.GDE.learned.QUEST_NAME then
--					for _, questNameLine in pairs(self.GDE.learned.QUEST_NAME) do
--						local loc, release, questId, questName = strsplit('|', questNameLine)
--						if loc == locale and nil ~= questId and (nil == self.quest.name[questId] or self.quest.name[questId] ~= questName) then
--							self.quest.name[questId] = questName
--						end
--					end
--				end
				if nil ~= self.GDE.learned.QUEST then
					for questId, questLine in pairs(self.GDE.learned.QUEST) do
						local codes = { strsplit(' ', questLine) }
						for c = 1, #codes do
							local shouldAdd = false
							if '' ~= codes[c] then
								if 1 < strlen(codes[c]) then
									local code = strsub(codes[c], 1, 1)
									local subcode = strsub(codes[c], 2, 2)
									if 'K' == code then
										local possibleQuestType = tonumber(strsub(codes[c], 5))
										if (nil ~= possibleQuestType and possibleQuestType ~= bitband(self:CodeType(questId), possibleQuestType)) then
											shouldAdd = true
											if nil ~= possibleQuestType then
												self:_MarkQuestType(questId, possibleQuestType)
											end
										end
									elseif 'A' == code and ':' == subcode then
										if not self:_GoodNPCAccept(questId, strsub(codes[c], 3)) then
											shouldAdd = true
										end
									elseif 'T' == code and ':' == subcode then
										if not self:_GoodNPCTurnin(questId, strsub(codes[c], 3)) then
											shouldAdd = true
										end
--									elseif 'L' == code then
--										if self:QuestLevelRequired(questId) ~= tonumber(strsub(codes[c], 2)) then
--											shouldAdd = true
--											self:_SetQuestRequiredLevel(questId, tonumber(strsub(codes[c], 2)))
--										end
									elseif 'P' == code and ':' == subcode then
										local codeToSeek = strsub(codes[c], 3)
										if nil == strfind(self.questPrerequisites[questId] or '', codeToSeek, 1, true) then
											shouldAdd = true
											if nil == self.questPrerequisites[questId] then
												self.questPrerequisites[questId] = codeToSeek
											else
												self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToSeek
											end
										end
									end
-- TODO: Implement this
								end
							end
							if shouldAdd then
								self.questCodes[questId] = self.questCodes[questId] or ''
								self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
							end
						end
					end
				end
			end
		end,

		--	Grail populates some special tables in the GrailDatabase table as it learns new things
		--	during gameplay.  This routine attempts to remove items that are in these tables but
		--	no longer need to be because Grail has been updated to know them.  This specific part
		--	of cleaning only removes known values.
		_CleanLearnedDatabase = function(self)
			-- In general we only want to eliminate things for our current locale
			-- if that is how they are stored in the learned datbase.
			local locale = GetLocale()
			local learned = self.GDE.learned
			if nil ~= learned and not self.processedLearned then

--				local learnedObjectNames = learned.OBJECT_NAME
--				if nil ~= learnedObjectNames then
--					local newObjectNames = {}
--					for _, objectLine in pairs(learnedObjectNames) do
--						local ver, loc, objId, objName = strsplit('|', objectLine)
--						if loc ~= locale or self:ObjectName(objId) ~= objName then
--							tinsert(newObjectNames, objectLine)
--						end
--					end
--					learned.OBJECT_NAME = newObjectNames
--				end

--				local learnedNPCLocations = learned.NPC_LOCATION
--				if nil ~= learnedNPCLocations then
--					local newNPCLocations = {}
--					for _, npcLine in pairs(learnedNPCLocations) do
--						local ver, loc, npcId, npcLoc, aliasId = strsplit('|', npcLine)
--						if nil ~= npcId and not self:_LocationKnown(npcId, npcLoc, aliasId) then
--							tinsert(newNPCLocations, npcLine)
--						end
--					end
--					learned.NPC_LOCATION = newNPCLocations
--				end

--				local learnedQuestNames = learned.QUEST_NAME
--				if nil ~= learnedQuestNames then
--					local newQuestNames = {}
--					for _, questNameLine in pairs(learnedQuestNames) do
--						local loc, ver, questId, questName = strsplit('|', questNameLine)
--						if loc ~= locale or (nil ~= questId and nil ~= self.quest.name[questId] and self.quest.name[questId] ~= questName) then
--							tinsert(newQuestNames, questNameLine)
--						end
--					end
--					learned.QUEST_NAME = newQuestNames
--				end

				local learnedQuest = learned.QUEST
				if nil ~= learnedQuest then
					local newQuests = {}
					local longestSafeLine = self.GDE.longestSafeLine or 15000
					for questId, questLine in pairs(learnedQuest) do
						if strlen(questLine) > longestSafeLine then
							questLine = strsub(questLine, 1, longestSafeLine)
						end
						local codes = { strsplit(' ', questLine) }
						local codeSet = {}
						for c = 1, #codes do
							self:InsertSet(codeSet, codes[c])
						end
						codes = codeSet
						local formatError = false
						local newCodes = ''
						local codeSpacer = ''
						for c = 1, #codes do
							local shouldAdd = false
							local codeToAdd = codes[c]
							if '' ~= codes[c] then
								if 1 < strlen(codes[c]) then
									local code = strsub(codes[c], 1, 1)
									local subcode = strsub(codes[c], 2, 2)
									if 'K' == code then
										local possibleQuestLevel = tonumber(strsub(codes[c], 2, 4))
										local possibleQuestType = tonumber(strsub(codes[c], 5))
										if (nil ~= possibleQuestLevel and possibleQuestLevel ~= self:QuestLevel(questId)) or (nil ~= possibleQuestType and possibleQuestType ~= bitband(self:CodeType(questId), possibleQuestType)) then
											shouldAdd = true
										end
									elseif 'A' == code and ':' == subcode then
										local stillNeedToHaveSet = {}
										local aCodes = { strsplit(',', strsub(codes[c], 3)) }
										for a = 1, #aCodes do
											if not self:_GoodNPCAccept(questId, aCodes[a]) then
												self:InsertSet(stillNeedToHaveSet, aCodes[a])
											end
										end
										if #stillNeedToHaveSet > 0 then
											shouldAdd = true
											codeToAdd = 'A:'
											local commaSpacer = ''
											for a = 1, #stillNeedToHaveSet do
												codeToAdd = codeToAdd .. commaSpacer .. stillNeedToHaveSet[a]
												commaSpacer = ','
											end
										end
									elseif 'T' == code and ':' == subcode then
										local stillNeedToHaveSet = {}
										local tCodes = { strsplit(',', strsub(codes[c], 3)) }
										for t = 1, #tCodes do
											if not self:_GoodNPCTurnin(questId, tCodes[t]) then
												self:InsertSet(stillNeedToHaveSet, tCodes[t])
											end
										end
										if #stillNeedToHaveSet > 0 then
											shouldAdd = true
											codeToAdd = 'T:'
											local commaSpacer = ''
											for t = 1, #stillNeedToHaveSet do
												codeToAdd = codeToAdd .. commaSpacer .. stillNeedToHaveSet[t]
												commaSpacer = ','
											end
										end
									elseif 'L' == code then
--										if self:QuestLevelRequired(questId) ~= tonumber(strsub(codes[c], 2)) then
--											shouldAdd = true
--										end
									elseif 'P' == code and ':' == subcode then
										if nil == strfind(self.questPrerequisites[questId] or '', strsub(codes[c], 3), 1, true) then
											shouldAdd = true
										end
									else
										formatError = true
									end
								else
									formatError = true
								end
							end
							if shouldAdd then
								newCodes = newCodes .. codeSpacer .. codeToAdd
								codeSpacer = ' '
							end
						end
						if formatError then
							print("Malformed code in saved variables for quest", questId, questLine)
						end
						if strlen(newCodes) > 0 then
							newQuests[questId] = newCodes
						end
					end
					learned.QUEST = newQuests
				end
				self.processedLearned = true
			end
		end,

		--	This routine attempts to remove items from the special tables that are stored in the GrailDatabase table
		--	when they have been added to the internal database.  These special tables are populated when Grail discovers
		--	something lacking in its internal database as game play proceeds.  This routine is called upon startup.
-- TODO: This should be split up so all the codes that are in the saved variables that no longer
--		need to be there are removed as step 1.  Then in step 2 anything that needs to update the
--		internal structure can be done.  In other words, we should not update the internal database
--		in step 1.
		_CleanDatabase = function(self)

--			self:_CleanLearnedDatabase()
--			self:_UpdateDatabaseFromLearnedDatabase()

			local locale = GetLocale()

--			if nil ~= self.GDE.learned and not self.processedLearned then
--
--				--	If the object name is for our locale we process it.  If it is the
--				--	same that we have, we remove it from the saved variables, else we
--				--	update our internal database so it need not be recorded again.
--				if nil ~= self.GDE.learned.OBJECT_NAME then
--					local newObjectNames = {}
--					for _, objectLine in pairs(self.GDE.learned.OBJECT_NAME) do
--						local shouldAdd = true
--						local ver, loc, objId, objName = strsplit('|', objectLine)
--						if loc == locale then
--							if self:ObjectName(objId) == objName then
--								shouldAdd = false
--							else
--								self.npc.name[1000000 + tonumber(objId)] = objName
--							end
--						end
--						if shouldAdd then
--							tinsert(newObjectNames, objectLine)
--						end
--					end
--					self.GDE.learned.OBJECT_NAME = newObjectNames
--				end
--
--				if nil ~= self.GDE.learned.NPC_LOCATION then
--					local newNPCLocations = {}
--					for _, npcLine in pairs(self.GDE.learned.NPC_LOCATION) do
--						local shouldAdd = true
--						local ver, loc, npcId, npcLoc, aliasId = strsplit('|', npcLine)
--						if self:_LocationKnown(npcId, npcLoc, aliasId) then
--							shouldAdd = false
--						else
--							self:_AddNPCLocation(npcId, npcLoc, aliasId)
--						end
--						if shouldAdd then
--							tinsert(newNPCLocations, npcLine)
--						end
--					end
--					self.GDE.learned.NPC_LOCATION = newNPCLocations
--				end
--
--				if nil ~= self.GDE.learned.QUEST then
--					local newQuest = {}
--					for questId, questLine in pairs(self.GDE.learned.QUEST) do
--						local questBits = { strsplit('|', questLine) }
--						-- The questBits should have the first item being the list
--						-- of codes, K, A: and T:.  Any other bits will be the locale
--						-- a colon and the localized name of the quest that did not
--						-- match the internal database value.  Those latter bits are
--						-- optional.
--						local newQuestLine = ''
--						local questSpacer = ''
--						for i = 1, #questBits do
--							if 1 == i then
--								-- process codes
--								local codes = { strsplit(' ', questBits[i]) }
--								local formatError = false
--								local newCodes = ''
--								local codeSpacer = ''
--								for c = 1, #codes do
--									if '' ~= codes[c] then
--										if 1 < strlen(codes[c]) then
--											local code = strsub(codes[c], 1, 1)
--											local subcode = strsub(codes[c], 2, 2)
--											if 'K' == code then
--												local possibleQuestLevel = tonumber(strsub(codes[c], 2, 4))
--												local possibleQuestType = tonumber(strsub(codes[c], 5))
--												if (nil ~= possibleQuestLevel and possibleQuestLevel ~= self:QuestLevel(questId)) or (nil ~= possibleQuestType and possibleQuestType ~= bitband(self:CodeType(questId), possibleQuestType)) then
--													newCodes = newCodes .. codeSpacer .. codes[c]
--													codeSpacer = ' '
--													self.questCodes[questId] = self.questCodes[questId] or ''
--													self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
--													if nil ~= possibleQuestLevel then
--														self:_SetQuestLevel(questId, possibleQuestLevel)
--													end
--													if nil ~= possibleQuestType then
--														self:_MarkQuestType(questId, possibleQuestType)
--													end
--												end
--											elseif 'A' == code and ':' == subcode then
--												if not self:_GoodNPCAccept(questId, strsub(codes[c], 3)) then
--													newCodes = newCodes .. codeSpacer .. codes[c]
--													codeSpacer = ' '
--													self.questCodes[questId] = self.questCodes[questId] or ''
--													self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
--												end
--											elseif 'T' == code and ':' == subcode then
--												if not self:_GoodNPCTurnin(questId, strsub(codes[c], 3)) then
--													newCodes = newCodes .. codeSpacer .. codes[c]
--													codeSpacer = ' '
--													self.questCodes[questId] = self.questCodes[questId] or ''
--													self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
--												end
--											elseif 'L' == code then
--												if self:QuestLevelRequired(questId) ~= tonumber(strsub(codes[c], 2)) then
--													newCodes = newCodes .. codeSpacer .. codes[c]
--													codeSpacer = ' '
--													self.questCodes[questId] = self.questCodes[questId] or ''
--													self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
--													self:_SetQuestRequiredLevel(questId, tonumber(strsub(codes[c], 2)))
--												end
--											elseif 'P' == code and ':' == subcode then
--												local codeToSeek = strsub(codes[c], 3)
--												if nil == strfind(self.questPrerequisites[questId] or '', codeToSeek, 1, true) then
--													newCodes = newCodes .. codeSpacer .. codes[c]
--													codeSpacer = ' '
--													self.questCodes[questId] = self.questCodes[questId] or ''
--													self.questCodes[questId] = self.questCodes[questId] .. ' ' .. codes[c]
--													if nil == self.questPrerequisites[questId] then
--														self.questPrerequisites[questId] = codeToSeek
--													else
--														self.questPrerequisites[questId] = self.questPrerequisites[questId] .. "+" .. codeToSeek
--													end
--												end
--											else
--												formatError = true
--											end
--										end
--									end
--								end
--								if formatError then
--									print("Malformed code in saved variables for quest", questId, questLine)
--								end
--								if 0 < strlen(newCodes) then
--									newQuestLine = newQuestLine .. questSpacer .. newCodes
--									questSpacer = '|'
--								end
--							else
---- With dynamic determination of quest names we no longer need to worry about mismatches.
----								local addLocalizedName = true
----								local loc, localizedName = strsplit(':', questBits[i])
----								if loc == locale then
----									if self:QuestName(questId) == localizedName then
----										addLocalizedName = false
----									else
----										self.questNames[questId] = localizedName
----									end
----								end
----								if addLocalizedName then
----									newQuestLine = newQuestLine .. questSpacer .. questBits[i]
----									questSpacer = '|'
----								end
--							end
--						end
--						if 0 < strlen(newQuestLine) then
--							newQuest[questId] = newQuestLine
--						end
--						self.quests[questId] = self.quests[questId] or {}
--					end
--					self.GDE.learned.QUEST = newQuest
--				end
--
--				self.processedLearned = true
--
--			end

			-- Remove quests from SpecialQuests that have been marked as special in our internal database.
			if nil ~= GrailDatabase["SpecialQuests"] then
-- We are just going to remove all the special quests as they are not working well in Classic.
				GrailDatabase.SpecialQuests = nil
--				for questName, _ in pairs(GrailDatabase["SpecialQuests"]) do
--					local questId = self:QuestWithName(questName)
----					if self.quests[questId] and  self.quests[questId]['SP'] then
--					if self.quests[questId] and bitband(self:CodeType(questId), self.bitMaskQuestSpecial) > 0 then
--						GrailDatabase["SpecialQuests"][questName] = nil
--					end
--				end
			end

			-- Remove quests from NewQuests that have been added to our internal database.
			-- If the name matches and all the codes are in our internal database we remove.
			if nil ~= GrailDatabase["NewQuests"] then
				local originalQuestIdThatBlizzardHasBrokenInBeta
				for questId, q in pairs(GrailDatabase["NewQuests"]) do
					originalQuestIdThatBlizzardHasBrokenInBeta = questId
					questId = floor(tonumber(questId))
					if self:DoesQuestExist(questId) then
						if q[self.playerLocale] == self:QuestName(questId) or q[self.playerLocale] == "No Title Stored" then
							local allCodesGood = true
							if nil ~= q[1] then
								local codeArray = { strsplit(" ", q[1]) }
								for _, code in pairs(codeArray) do
									if code ~= "" then
										if "A:" == strsub(code, 1, 2) then
											if allCodesGood then
												allCodesGood = self:_CleanCheckNPC('A', tonumber(strsub(code, 3)), questId)
											end
										elseif "T:" == strsub(code, 1, 2) then
											if allCodesGood then
												allCodesGood = self:_CleanCheckNPC('T', tonumber(strsub(code, 3)), questId)
											end
										elseif "+D" == code then
											if not self:IsDaily(questId) then
												allCodesGood = false
											end
										elseif "K0" == strsub(code, 1, 2) or "K1" == strsub(code, 1, 2) then
-- At the moment we ignore this code instead of verifying it exists in the current database.
										else
											print("|cffff0000Grail|r found NewQuests quest ID", questId, "with unknown code", code)
										end
									end
								end
							end
							if allCodesGood then GrailDatabase["NewQuests"][originalQuestIdThatBlizzardHasBrokenInBeta] = nil end
						end
					end
				end
			end

			-- Remove NPCs from NewNPCs that have been added to our internal database
			-- Basically, if the name matches and we have a location in our internal database we remove
			if nil ~= GrailDatabase["NewNPCs"] then
-- This code is commented out since we no longer save things into NewNPCs, but we still want to remove the
-- entry for any older versions of the saved variables.
--				local originalNPCIdThatBlizzardHasBrokenInBeta
--				for npcId, n in pairs(GrailDatabase["NewNPCs"]) do
--					originalNPCIdThatBlizzardHasBrokenInBeta = npcId
--					npcId = floor(tonumber(npcId))
--					local locations = self:_RawNPCLocations(npcId)
--					if nil ~= locations then
--						for _, npc in pairs(locations) do
--							if nil ~= npc.name and n[self.playerLocale] == npc.name and ((nil ~= npc.x and nil ~= npc.y) or npc.near) then
--								GrailDatabase["NewNPCs"][originalNPCIdThatBlizzardHasBrokenInBeta] = nil
--							end
--						end
--					else	-- it seems we do not have the NPC or we have no information about it
--						-- if the version of this entry is so old we will just nuke it
--						local startPos, endPos, grailVersion, restOfString = strfind(n[2], "(%d+)/(.*)")
--						if nil ~= startPos then
--							grailVersion = tonumber(grailVersion)
--							if nil ~= grailVersion and grailVersion < self.versionNumber - 4 then
--								GrailDatabase["NewNPCs"][originalNPCIdThatBlizzardHasBrokenInBeta] = nil
--							end
--						end
--					end
--				end
				GrailDatabase.NewNPCs = nil
			end

			-- BadNPCData is processed like BadQuestData (which follows)
			if nil ~= GrailDatabase["BadNPCData"] then
-- This code is commented out since we no longer save things into BadNPCData, but we still want to remove the
-- entry for any older versions of the saved variables.
--				local newBadNPCData = {}
--				for k, v in pairs(GrailDatabase["BadNPCData"]) do
--					local startPos, endPos, grailVersion, npcId, restOfString = strfind(v, "G(%d+)|(%d+)(.*)")
--					local writables = {}
--					if nil ~= startPos then
--						npcId = tonumber(npcId)
--						if nil ~= restOfString then
--							local codes = { strsplit('|', restOfString) }
--							if nil ~= codes then
--								local nameValue = nil	-- used in conjunction with localeValue
--								local localeValue = nil	-- used in conjunction with nameValue
--								for _, v in pairs(codes) do
--									if nil == v or "" == v then
--										-- skip it
--									elseif "Locale:" == strsub(v, 1, 7) then
--										localeValue = strsub(v, 8)
--										if nil ~= nameValue then
--											if localeValue ~= self.playerLocale or nameValue ~= self:NPCName(npcId) then
--												tinsert(writables, "Name:" .. nameValue)
--												tinsert(writables, "Locale:" .. localeValue)
--											end
--										end
--									elseif "Name:" == strsub(v, 1, 5) then
--										nameValue = strsub(v, 6)
--										if nil ~= localeValue then
--											if localeValue ~= self.playerLocale or nameValue ~= self:NPCName(npcId) then
--												tinsert(writables, "Name:" .. nameValue)
--												tinsert(writables, "Locale:" .. localeValue)
--											end
--										end
--									else
--										tinsert(writables, v)
--									end
--								end
--							end
--						end
--					end
--					if 0 < #writables then
--						local whatToWrite = 'G' .. grailVersion .. '|' .. npcId
--						for _, w in pairs(writables) do
--							whatToWrite = whatToWrite .. '|' .. w
--						end
--						tinsert(newBadNPCData, whatToWrite)
--					end
--				end
--				GrailDatabase["BadNPCData"] = newBadNPCData
				GrailDatabase.BadNPCData = nil
			end

			-- The BadQuestData will be analyzed against the current database and things that have been fixed
			-- in the current database will be removed from BadQuestData.  This is done by creating a new table
			-- and only putting things that are not fixed into it.
			if nil ~= GrailDatabase["BadQuestData"] then
				local newBadQuestData = {}
				for k, v in pairs(GrailDatabase["BadQuestData"]) do
					if "table" ~= type(v) then
						local startPos, endPos, grailVersion, questId, statusCode, restOfString = strfind(v, "G(%d+)|(%d+)|(%d+)(.*)")
						local writables = {}

						if nil ~= startPos then
							questId = tonumber(questId)
							statusCode = tonumber(statusCode)
							if nil ~= restOfString then
								local codes = { strsplit('|', restOfString) }
								if nil ~= codes then
									local titleValue = nil	-- used in conjunction with localeValue
									local localeValue = nil	-- used in conjunction with titleValue
									for _, v in pairs(codes) do
										if nil == v or "" == v then
											-- skip it
										elseif "Rep:" == strsub(v, 1, 4) and 4 < strlen(v) then
--											if nil == self.quests[questId] or nil == self.quests[questId][6] or not tContains(self.quests[questId][6], strsub(v, 5)) then
											if nil == self.questReputations[questId] or nil == strfind(self.questReputations[questId], self:_ReputationCode(strsub(v, 5))) then
												tinsert(writables, v)
											end
										elseif "UnknownRep:" == strsub(v, 1, 11) then
											local startPos2, endPos2, reputationName, changeAmount = strfind(strsub(v, 12), "(.*) (-?%d+)")
											local shouldWrite = true
											local whatToWrite = v
											if nil ~= startPos2 then
												local reputationIndex = self.reverseReputationMapping[reputationName]
												if nil ~= reputationIndex then
													if "490" == reputationIndex then	-- remove the Guild reputation indexes that beta testers may have since we do not want them
														shouldWrite = false
													else
														local repChangeString = strformat("%s%d", reputationIndex, changeAmount)
--														if nil ~= self.quests[questId][6] and tContains(self.quests[questId][6], repChangeString) then
														if nil ~= self.questReputations[questId] and nil ~= strfind(self.questReputations[questId], self:_ReputationCode(repChangeString)) then
															shouldWrite = false
														else
															whatToWrite = strformat("Rep:%s", repChangeString)
														end
													end
												end
											end
											if shouldWrite then tinsert(writables, whatToWrite) end
										elseif "C:" == strsub(v, 1, 2) then
											if not self:MeetsRequirementClass(questId, strsub(v, 3)) then tinsert(writables, v) end
										elseif "F:" == strsub(v, 1, 2) then
											if not self:MeetsRequirementFaction(questId, strsub(v, 3)) then tinsert(writables, v) end
										elseif "G:" == strsub(v, 1, 2) then
											if not self:MeetsRequirementGender(questId, strsub(v, 3)) then tinsert(writables, v) end
										elseif "L:" == strsub(v, 1, 2) then
											if not self:MeetsRequirementLevel(questId, tonumber(strsub(v, 3))) then tinsert(writables, v) end
										elseif "R:" == strsub(v, 1, 2) then
											if not self:MeetsRequirementRace(questId, strsub(v, 3)) then tinsert(writables, v) end
										elseif "Level:" == strsub(v, 1, 6) then
											local internalLevel = self:QuestLevel(questId)
											local actualLevel = tonumber(strsub(v, 7))
											if 0 ~= actualLevel and 0 ~= internalLevel and (internalLevel or 1) ~= actualLevel then
												tinsert(writables, v)
											end
										elseif "Locale:" == strsub(v, 1, 7) then
											localeValue = strsub(v, 8)
											if nil ~= titleValue then
												if localeValue ~= self.playerLocale or titleValue ~= self:QuestName(questId) then
													tinsert(writables, "Title:" .. titleValue)
													tinsert(writables, "Locale:" .. localeValue)
												end
											end
										elseif "Title:" == strsub(v, 1, 6) then
											titleValue = strsub(v, 7)
											if nil ~= localeValue then
												if localeValue ~= self.playerLocale or titleValue ~= self:QuestName(questId) then
													tinsert(writables, "Title:" .. titleValue)
													tinsert(writables, "Locale:" .. localeValue)
												end
											end
										elseif "Faction:" == strsub(v, 1, 8) then
											local factionValue = strsub(v, 9)
											if nil ~= factionValue then
												local shouldWrite = true
												local bitMaskToCheckAgainst
												if "Alliance" == factionValue then
													bitMaskToCheckAgainst = self.bitMaskFactionAlliance
												elseif "Horde" == factionValue then
													bitMaskToCheckAgainst = self.bitMaskFactionHorde
												elseif "Both" == factionValue then
													bitMaskToCheckAgainst = self.bitMaskFactionAll
												end
												if bitband(self:CodeObtainers(questId), self.bitMaskFactionAll) == bitMaskToCheckAgainst then
													shouldWrite = false
												end
												if shouldWrite then tinsert(writables, v) end
											end
										else
											tinsert(writables, v)
										end
									end
								end
							end
						else
							local shouldReinsert = true
							local startPos, endPos, grailVersion, portal, blizzardVersion, restOfString = strfind(v, "G(%d+)|(.+)|(%d+)(.*)")
							if nil ~= startPos then
								local startPosition, endPosition, questId, reputations = strfind(restOfString, "|G.(%d+)..6.=.(.*).")
								if nil ~= startPosition then
									local blizzardReps
									reputations = strgsub(reputations, "\'", "")
									if reputations == "" then
										blizzardReps = {}
									else
										blizzardReps = { strsplit(",", reputations) }
									end
									if self:_ReputationChangesMatch(questId, blizzardReps) then
										shouldReinsert = false
									end
								else
									local rewardString
									startPosition, endPosition, questId, rewardString = strfind(restOfString, "|G.(%d+)..reward.=(.*)")
									if nil ~= startPosition then
										if nil ~= self.questRewards and rewardString == self.questRewards[tonumber(questId)] then
											shouldReinsert = false
										end
									end
								end
							else
								print("Grail cannot understand format of:", v)
							end
							if shouldReinsert then
								tinsert(newBadQuestData, v)
							end
						end
						if 0 < #writables and tonumber(grailVersion) + 4 >= self.versionNumber then
							local whatToWrite = 'G' .. grailVersion .. '|' .. questId .. '|' .. statusCode
							for _, w in pairs(writables) do
								whatToWrite = whatToWrite .. '|' .. w
							end
							tinsert(newBadQuestData, whatToWrite)
						end
					end
				end
				GrailDatabase["BadQuestData"] = newBadQuestData
			end
		end,

		--	This routine adds a notification to the delayed notification system if a notification
		--	of that type does not already exist in the system.  Using this allows the code to effectively
		--	post as many of a type of notification as it wants, but when the delayed notifications are
		--	processed only one type of notification will be sent to observers.
		_CoalesceDelayedNotification = function(self, notificationName, delay, questId)
			local needToPost = true
			if nil ~= self.delayedNotifications then
				for i = 1, #(self.delayedNotifications) do
					if notificationName == self.delayedNotifications[i]["n"] then
						needToPost = false
					end
				end
			end
			if needToPost then
				self:_PostDelayedNotification(notificationName, questId, delay)
			end
		end,

		_RemoveDelayedNotification = function(self, notificationName)
			if nil ~= self.delayedNotifications then
				local newTable = {}
				for i = 1, #(self.delayedNotifications) do
					if notificationName ~= self.delayedNotifications[i].n then
						newTable[#newTable + 1] = self.delayedNotifications[i]
					end
				end
				self.delayedNotifications = newTable
			end
		end,

		_QuestCode = function(self, questId, soughtCode)
			questId = tonumber(questId)
			if nil ~= questId then
				local codeString = self.questCodes[questId]
				if nil ~= codeString then
					local start, length = 1, strlen(codeString)
					local stop = length
					local c, code, codeValue
					while start < length do
						local foundSpace = strfind(codeString, " ", start, true)
						if nil == foundSpace then
							if 1 < start then
								stop = strlen(codeString)
							end
						else
							stop = foundSpace - 1
						end
						c = strsub(codeString, start, stop)
						if '' == c then
							code = '!'
						else
							code = strsub(c, 1, 1)
							codeValue = strsub(c, 2)
						end
						if code == soughtCode then
							return code, codeValue
						end
						start = stop + 2
					end
				end
			end
			return nil, nil
		end,

		--	Populates the internal caches for all the fixed codes that are derived from quest data.
		--	@param questId The standard numeric questId representing a quest.
		_CodeAllFixed = function(self, questId)
			questId = tonumber(questId)

			if nil ~= questId then

				--	We just need to use one of the caches as the signal to compute them since they are all done together
				if nil ~= self.quests[questId] and nil == self.questBits[questId] then
					local typeValue = 0
					local holidayValue = 0
					local obtainersValue = self.bitMaskClassAll		-- we will start out assuming all classes are allowed
					local obtainersRaceValue = 0;
					local levelValue = 0

					local codeString = self.questCodes[questId] or nil
					if nil ~= codeString then
						local start, length = 1, strlen(codeString)
						local stop = length
---						local codeArray = { strsplit(" ", codeString) }
						local c
						local code
						local codeValue
						local bitValue
						local hasError
						--	X and C are mutually exclusive so only allow one type to be processed
						local foundCCode = false
						local foundXCode = false
---						for i = 1, #codeArray do
						while start < length do
							local foundSpace = strfind(codeString, " ", start, true)
							if nil == foundSpace then
								if 1 < start then
									stop = strlen(codeString)
								end
							else
								stop = foundSpace - 1
							end
							c = strsub(codeString, start, stop)
---							c = codeArray[i]
							if '' == c then
								code = '!'
							else
								code = strsub(c, 1, 1)
								codeValue = strsub(c, 2, 2)
							end
							hasError = false

							if '!' == code then
								-- Do nothing...this is an empty string...extra space in the input file

							elseif 'U' == code then
								local followerId = tonumber(strsub(c, 2))
								self.followerMapping[questId] = followerId

							elseif 'C' == code then
								bitValue = self.classToBitMapping[codeValue]
								if nil ~= bitValue and not foundXCode then
									-- The first time through we will remove the assumption that all the classes are allowed
									if not foundCCode then
										obtainersValue = obtainersValue - self.bitMaskClassAll
									end
									foundCCode = true
									obtainersValue = obtainersValue + bitValue
								else
									hasError = true
								end

							elseif 'E' == code or 'Z' == code then
								local releaseNumber = tonumber(strsub(c, 2))
								if nil ~= releaseNumber then
									if 'E' == code and self.blizzardRelease < releaseNumber then
										self.questsNotYetAvailable[questId] = releaseNumber
									end
									if 'Z' == code and self.blizzardRelease > releaseNumber then
										self.questsNoLongerAvailable[questId] = releaseNumber
									end
								else
									hasError = true
								end

							elseif 'D' == code then
								local group = tonumber(strsub(c, 2))
								if nil ~= group then
									self:_InsertSet(self.questStatusCache.G, group, questId)
									self:_InsertSet(self.questStatusCache.H, questId, group)
								else
									hasError = true
								end

							elseif 'W' == code then
								local group = tonumber(strsub(c, 2))
								if nil ~= group then
									self:_InsertSet(self.questStatusCache.J, group, questId)
									self:_InsertSet(self.questStatusCache.K, questId, group)
								else
									hasError = true
								end

							-- The "item counts" quests are grouped together because they all have the
							-- same item as a requirement, but the counts of that item differ.  The game
							-- only presents the quest to the user that has the most of that item that
							-- the user has.  So, for quests that require 20, 5, and 1 of an item, if the
							-- user has 27, the quest with 20 will be presented, but if the user has 17,
							-- the quest with 5 will be presented.
							-- The system needs to ensure each of the quests associated with the item have
							-- their cached status cleared if the count of the item ever changes.
							-- When determining if a quest is available, all the quests in the group need to
							-- be checked and this is only avaiable if it requires the most of the item out of
							-- all the quests in the group that could be available by item count.
							elseif 'V' == code then
								local group = tonumber(strsub(c, 2))
								if nil ~= group then
									self:_InsertSet(self.questStatusCache.questToItemCountGroup, questId, group)
								else
									hasError = true
								end

							elseif 'B' == code then
								if ':' == codeValue then
									--	we call _FromList with the current value of the 'B' table because processing 'O:' codes before
									--	may have created a 'B' table, so we would want to add to it instead of overwriting it
									self.quests[questId]['B'] = self:_FromList(strsub(c, 3), nil, self.quests[questId]['B'])
								else
									hasError = true
								end

							elseif 'J' == code then
								if ':' == codeValue then
									self.quests[questId]['J'] = strsub(c, 3)
								else
									hasError = true
								end

							elseif 'X' == code then
								--	The inherent nature of an X code makes is such that only one has meaning, and C codes should not be combined
								bitValue = self.classToBitMapping[codeValue]
								if nil ~= bitValue and not foundCCode then
--									obtainersValue = bitband(obtainersValue, bitbnot(self.bitMaskClassAll))
--									obtainersValue = obtainersValue + self.bitMaskClassAll - bitValue
									foundXCode = true
									obtainersValue = obtainersValue - bitValue
								else
									hasError = true
								end

							elseif 'F' == code or 'f' == code then
								if 'A' == codeValue then
									obtainersValue = obtainersValue + self.bitMaskFactionAlliance
								elseif 'H' == codeValue then
									obtainersValue = obtainersValue + self.bitMaskFactionHorde
								else
									hasError = true
								end

							elseif 'G' == code then
								if 'M' == codeValue then
									obtainersValue = obtainersValue + self.bitMaskGenderMale
								elseif 'F' == codeValue then
									obtainersValue = obtainersValue + self.bitMaskGenderFemale
								else
									hasError = true
								end

							elseif 'Q' == code then
								if ':' == strsub(c, 3, 3) then
									local gossipIndex = tonumber(codeValue)
									local npcCodes = self:_FromQualified(strsub(c, 4))
									local npcValue, npcCode, pattern
									for _, preqTable in pairs(npcCodes) do
										npcCode, pattern = preqTable[1], preqTable[2]
										npcValue = tonumber(npcCode)
										self.gossipNPCs[npcValue] = self.gossipNPCs[npcValue] or {}
										self.gossipNPCs[npcValue][gossipIndex] = { questId, pattern }
									end
								else
									hasError = true
								end

							elseif 'R' == code then
								bitValue = self.races[codeValue][4]
								if nil ~= bitValue then
									obtainersRaceValue = obtainersRaceValue + bitValue
								else
									hasError = true
								end

							elseif 'S' == code then
								if 'P' ~= codeValue then
									--	The inherent nature of an S code makes is such that only one has meaning, and R codes should not be combined
									bitValue = self.races[codeValue][4]
									if nil ~= bitValue then
										obtainersRaceValue = bitband(obtainersRaceValue, bitbnot(self.bitMaskRaceAll))
										obtainersRaceValue = obtainersRaceValue + self.bitMaskRaceAll - bitValue
									else
										hasError = true
									end
								else
									if 0 == bitband(typeValue, self.bitMaskQuestSpecial) then typeValue = typeValue + self.bitMaskQuestSpecial end
								end

--							elseif 'K' == code then
--								levelValue = levelValue + (tonumber(strsub(c, 2, 4)) * self.bitMaskQuestLevelOffset)
--								if strlen(c) > 4 then
--									local possibleTypeValue = tonumber(strsub(c, 5))
--									if possibleTypeValue then typeValue = typeValue + possibleTypeValue end
--								end
							
							elseif 'K' == code then
								typeValue = typeValue + (tonumber(strsub(c, 2)) or 0)
							
							elseif 'L' == code then
--								levelValue = levelValue + (tonumber(strsub(c, 2)) or 0)
								local questLevel, questRequiredLevel, questMaximumScalingLevel = self:QuestLevelsFromString(strsub(c, 2))
								levelValue = levelValue + questLevel * self.bitMaskQuestLevelOffset + questRequiredLevel * self.bitMaskQuestMinLevelOffset + questMaximumScalingLevel * self.bitMaskQuestVariableLevelOffset
							
--							elseif 'l' == code then
--								-- lLLLNNNKKK+
--								local codeLength = strlen(c)
--								if codeLength >= 10 then
--									levelValue = levelValue +
--										((tonumber(strsub(c, 2, 4)) or 1) * self.bitMaskQuestMinLevelOffset) +
--										((tonumber(strsub(c, 5, 7)) or 255) * self.bitMaskQuestVariableLevelOffset) +
--										(tonumber(strsub(c, 8, 10)) * self.bitMaskQuestLevelOffset)
--									if codeLength > 10 then
--										local possibleTypeValue = tonumber(strsub(c, 11))
--										if possibleTypeValue then typeValue = typeValue + possibleTypeValue end
--									end
--								end

--							elseif 'L' == code then
--								levelValue = levelValue + ((tonumber(strsub(c, 2)) or 1) * self.bitMaskQuestMinLevelOffset)

							elseif 'M' == code then
								levelValue = levelValue + ((tonumber(strsub(c, 2)) or 255) * self.bitMaskQuestMaxLevelOffset)

							elseif 'N' == code then
								levelValue = levelValue + ((tonumber(strsub(c, 2)) or 0) * self.bitMaskQuestVariableLevelOffset)

							elseif 'H' == code then
								bitValue = self.holidayToBitMapping[codeValue]
								if nil ~= bitValue then
									holidayValue = holidayValue + bitValue
								else
									hasError = true
								end

-- Old V and W codes no longer exist
--							elseif 'V' == code or 'W' == code then
--								local reputationIndex = strsub(c, 2, 4)
--								local reputationValue = tonumber(strsub(c, 5))
--								if nil == self.quests[questId]['rep'] then self.quests[questId]['rep'] = {} end
--								if nil == self.quests[questId]['rep'][reputationIndex] then self.quests[questId]['rep'][reputationIndex] = {} end
--								self.quests[questId]['rep'][reputationIndex][('V' == code) and 'min' or 'max'] = reputationValue

							elseif 'O' == code then
								if ':' == codeValue then
									self.quests[questId]['O'] = self:_FromPattern(strsub(c, 3))
									self:_FromStructure(self.quests[questId]['O'], questId, 'B')
								elseif 'A' == codeValue and strlen(c) > 4 and 'OAC:' == strsub(c, 1, 4) then
									self.quests[questId]['OAC'] = self:_FromList(strsub(c, 5))
								elseif 'B' == codeValue and strlen(c) > 4 and 'OBC:' == strsub(c, 1, 4) then
									self.quests[questId]['OBC'] = self:_FromList(strsub(c, 5))
								elseif 'C' == codeValue and strlen(c) > 4 and 'OCC:' == strsub(c, 1, 4) then
									self.quests[questId]['OCC'] = self:_FromList(strsub(c, 5))
								elseif 'D' == codeValue and strlen(c) > 4 and 'ODC:' == strsub(c, 1, 4) then
									self.quests[questId]['ODC'] = self:_FromList(strsub(c, 5))
								elseif 'E' == codeValue and strlen(c) > 4 and 'OEC:' == strsub(c, 1, 4) then
									self.quests[questId]['OEC'] = self:_FromList(strsub(c, 5))
								elseif 'P' == codeValue and strlen(c) > 4 and 'OPC:' == strsub(c, 1, 4) then
									self.quests[questId]['OPC'] = self:_FromPattern(strsub(c, 5))
									self:_ProcessQuestsForHandlers(questId, self.quests[questId]['OPC'])
								elseif 'T' == codeValue and strlen(c) > 4 and 'OTC:' == strsub(c, 1, 4) then
									self.quests[questId]['OTC'] = self:_FromPattern(strsub(c, 5))
								else
									hasError = true
								end

							elseif 'Y' == code then
								if ':' == codeValue then
									self.quests[questId]['Y'] = tonumber(strsub(c, 3))
								else
									hasError = true
								end

							elseif 'T' == code then
								if ':' == codeValue then
									self.quests[questId]['T'] = self:_TableAppendCodes(self:_FromList(strsub(c, 3)), self.quests[questId], { 'T' })
								elseif 'A' == codeValue or 'H' == codeValue then
									if (('Horde' == self.playerFaction) and 'H' or 'A') == codeValue then
										self.quests[questId]['T'] = self:_TableAppendCodes(self:_FromList(strsub(c, 4)), self.quests[questId], { 'T' })
									end
								elseif 'P' == codeValue then
									self.quests[questId]['TP'] = self:_FromQualified(strsub(c, 4), questId)
								else
									hasError = true
								end

							elseif 'I' == code then
								if ':' == codeValue then
									self.quests[questId]['I'] = self:_FromPattern(strsub(c, 3))
									local iQuests = self.quests[questId]['I']
									if nil ~= iQuests then
										for _, iQuestId in pairs(iQuests) do
											local t = self.questStatusCache["I"][iQuestId] or {}
											if not tContains(t, questId) then tinsert(t, questId) end
											self.questStatusCache["I"][iQuestId] = t
										end
									end
									self:_ProcessQuestsForHandlers(questId, self.quests[questId]['I'])
								else
									hasError = true
								end

							elseif 'A' == code then
								if ':' == codeValue then
									self.quests[questId]['A'] = self:_TableAppendCodes(self:_FromList(strsub(c, 3)), self.quests[questId], { 'A' })
								elseif 'A' == codeValue or 'H' == codeValue then
									if (('Horde' == self.playerFaction) and 'H' or 'A') == codeValue then
										self.quests[questId]['A'] = self:_TableAppendCodes(self:_FromList(strsub(c, 4)), self.quests[questId], { 'A' })
									end
								elseif 'K' == codeValue then
									self.quests[questId]['AK'] = self:_FromList(strsub(c, 4))
								elseif 'P' == codeValue then
									self.quests[questId]['AP'] = self:_FromQualified(strsub(c, 4), questId)
								elseif 'Z' == codeValue then
									self.quests[questId]['AZ'] = self:_FromList(strsub(c, 4))
								else
									hasError = true
								end

							elseif 'P' == code then
								if ':' == codeValue then
									local rawPrereqString = strsub(c, 3)
									-- Strip ? from unverified prereq quest IDs and record them separately.
									-- ? is only valid on bare numeric quest IDs (e.g. ?10995), not coded ones (e.g. A10995).
									local unverified = {}
									local cleanedString = gsub(rawPrereqString, '%?(%d+)', function(id)
										tinsert(unverified, tonumber(id))
										return id		-- return without ?, so downstream parsing sees a clean integer
									end)
									if #unverified > 0 then
										self.questUnverifiedPrereqs[questId] = unverified
										-- Also record ALL bare integer prereq questIds (confirmed + unverified) so the
										-- verifyWatchedBy reverse index can trigger on any of them, not just the ? ones.
										local allBarePrereqs = {}
										for token in gmatch(cleanedString, '[^+,|]+') do
											local id = tonumber(token)
											if id then tinsert(allBarePrereqs, id) end
										end
										self.questVerifyAllPrereqs[questId] = allBarePrereqs
										-- Build reverse index: any of these prereqs being turned in should trigger the warning.
										for _, prereqId in ipairs(allBarePrereqs) do
											self.verifyWatchedBy[prereqId] = self.verifyWatchedBy[prereqId] or {}
											tinsert(self.verifyWatchedBy[prereqId], questId)
										end
									end
									if self.nonPatternExperiment then
										self.questPrerequisites[questId] = cleanedString
									else
										self.questPrerequisites[questId] = self:_FromPattern(cleanedString)
									end
									self:_ProcessQuestsForHandlers(questId, self.questPrerequisites[questId])
								else
									hasError = true
								end
							end

							if hasError then
								print("|cFFFF0000Grail Error|r: Quest",questId,"has unknown code:", c)
							end

							start = stop + 2
						end

						--	Since the assumption is if there is a lack of code present to limit those permitted to
						--	obtain quests, checks must be done to see whether any limitations are present, and if
						--	none, the values need to be altered to permit all of those subset.
						if 0 == bitband(obtainersValue, self.bitMaskFactionAll) then
							local questGiversFactions = self:_FactionsFromQuestGivers(questId)
							if 'B' == questGiversFactions then
								obtainersValue = obtainersValue + self.bitMaskFactionAll
							elseif 'A' == questGiversFactions then
								obtainersValue = obtainersValue + self.bitMaskFactionAlliance
							elseif 'H' == questGiversFactions then
								obtainersValue = obtainersValue + self.bitMaskFactionHorde
							end
						end
--						if 0 == bitband(obtainersValue, self.bitMaskClassAll) then obtainersValue = obtainersValue + self.bitMaskClassAll end
						if 0 == bitband(obtainersValue, self.bitMaskGenderAll) then obtainersValue = obtainersValue + self.bitMaskGenderAll end
						if 0 == bitband(obtainersRaceValue, self.bitMaskRaceAll) then obtainersRaceValue = self.bitMaskRaceAll end

						--	And the levels are assumed to have minimum and maximum values that are reasonable if none present
						if 0 == bitband(levelValue, self.bitMaskQuestMinLevel) then levelValue = levelValue + self.bitMaskQuestMinLevelOffset end
						if 0 == bitband(levelValue, self.bitMaskQuestMaxLevel) then levelValue = levelValue + self.bitMaskQuestMaxLevel end

					end

					self:_SetQuestBits(questId, typeValue, obtainersRaceValue, levelValue, obtainersValue, holidayValue)
--					self.questBits[questId] = strchar(
--												bitband(bitrshift(typeValue, 24), 255),
--												bitband(bitrshift(typeValue, 16), 255),
--												bitband(bitrshift(typeValue, 8), 255),
--												bitband(typeValue, 255),
--												0, 0, 0, 0,		-- placeholder for status
--												bitband(bitrshift(levelValue, 24), 255),
--												bitband(bitrshift(levelValue, 16), 255),
--												bitband(bitrshift(levelValue, 8), 255),
--												bitband(levelValue, 255),
--												bitband(bitrshift(obtainersValue, 24), 255),
--												bitband(bitrshift(obtainersValue, 16), 255),
--												bitband(bitrshift(obtainersValue, 8), 255),
--												bitband(obtainersValue, 255),
--												bitband(bitrshift(holidayValue, 24), 255),
--												bitband(bitrshift(holidayValue, 16), 255),
--												bitband(bitrshift(holidayValue, 8), 255),
--												bitband(holidayValue, 255)
--												)

--					self.quests[questId][2] = typeValue
--					self.quests[questId][3] = holidayValue
--					self.quests[questId][4] = obtainersValue
--					self.quests[questId][13] = levelValue

				end

			end

		end,

		_MarkQuestType = function(self, questId, bitValue)
			local codeType = self:CodeType(questId)
			codeType = bitbor(codeType, bitValue)
			self:_SetQuestBits(questId, codeType)
		end,

		_SetQuestLevel = function(self, questId, level)
			local codeLevel = self:CodeLevel(questId)
			codeLevel = codeLevel - bitband(codeLevel, self.bitMaskQuestLevel)
			codeLevel = codeLevel + (level * self.bitMaskQuestLevelOffset)
			self:_SetQuestBitLevel(questId, codeLevel)
		end,

		_SetQuestRequiredLevel = function(self, questId, requiredLevel)
			local codeLevel = self:CodeLevel(questId)
			codeLevel = codeLevel - bitband(codeLevel, self.bitMaskQuestMinLevel)
			codeLevel = codeLevel + (requiredLevel * self.bitMaskQuestMinLevelOffset)
			self:_SetQuestBitLevel(questId, codeLevel)
		end,

		_SetQuestVariableLevel = function(self, questId, variableLevel)
			local codeLevel = self:CodeLevel(questId)
			codeLevel = codeLevel - bitband(codeLevel, self.bitMaskQuestVariableLevel)
			codeLevel = codeLevel + (variableLevel * self.bitMaskQuestVariableLevelOffset)
			self:_SetQuestBitLevel(questId, codeLevel)
		end,

		_SetQuestBitLevel = function(self, questId, levelValue)
			self:_SetQuestBits(questId, nil, nil, levelValue)
		end,

		_SetQuestBits = function(self, questId, typeValue, obtainersRaceValue, levelValue, obtainersValue, holidayValue)
			local currentValue = self.questBits[questId]
			typeValue = typeValue or self:_IntegerFromStringPosition(currentValue, 1)
			obtainersRaceValue = obtainersRaceValue or self:_IntegerFromStringPosition(currentValue, 2)
			levelValue = levelValue or self:_IntegerFromStringPosition(currentValue, 3)
			obtainersValue = obtainersValue or self:_IntegerFromStringPosition(currentValue, 4)
			holidayValue = holidayValue or self:_IntegerFromStringPosition(currentValue, 5)
					self.questBits[questId] = strchar(
												bitband(bitrshift(typeValue, 24), 255),
												bitband(bitrshift(typeValue, 16), 255),
												bitband(bitrshift(typeValue, 8), 255),
												bitband(typeValue, 255),
												bitband(bitrshift(obtainersRaceValue, 24), 255),
												bitband(bitrshift(obtainersRaceValue, 16), 255),
												bitband(bitrshift(obtainersRaceValue, 8), 255),
												bitband(obtainersRaceValue, 255),
												bitband(bitrshift(levelValue, 24), 255),
												bitband(bitrshift(levelValue, 16), 255),
												bitband(bitrshift(levelValue, 8), 255),
												bitband(levelValue, 255),
												bitband(bitrshift(obtainersValue, 24), 255),
												bitband(bitrshift(obtainersValue, 16), 255),
												bitband(bitrshift(obtainersValue, 8), 255),
												bitband(obtainersValue, 255),
												bitband(bitrshift(holidayValue, 24), 255),
												bitband(bitrshift(holidayValue, 16), 255),
												bitband(bitrshift(holidayValue, 8), 255),
												bitband(holidayValue, 255)
												)
		end,

		_IntegerFromStringPosition = function(self, theString, thePosition)
			if nil == theString then return 0 end
			local a, b, c, d = strbyte(strsub(theString, thePosition * 4 - 3, thePosition * 4), 1, 4)
			return a * 256 * 256 * 256 + b * 256 * 256 + c * 256 + d
		end,

--		_StatusValid = function(self, questId)
--			return 0 == bitband(strbyte(self.questBits[questId]), 0x80)
--		end,
--
--		_MarkStatusValid = function(self, questId, notValid)
--			local modifier = 0
--			if notValid and self:_StatusValid(questId) then
--				modifier = 1
--			elseif not notValid and not self:_StatusValid(questId) then
--				modifier = -1
--			end
--			if 0 ~= modifier then
--				self.questBits[questId] = self.questBits[questId]:gsub("^.", function(w) return strchar(strbyte(w) + (modifier * 0x80)) end)
--			end
--		end,

		---
		--	Returns a bit mask indicating the type of the holidays that limit who can get the quest.
		--	@return An integer that should be interpreted as a bit mask containing information about what holiday .
		CodeHoliday = function(self, questId)
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			return nil ~= questId and self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 5) or 0
		end,

		---
		--	Returns a bit mask indicating the levels of who can get the quest.
		--	@return An integer that should be interpreted as a bit mask containing information about levels of the quest.
		CodeLevel = function(self, questId)
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			return nil ~= questId and self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 3) or 0
		end,

		---
		--	Returns a bit mask indicating the type of the obtainers who can get the quest.
		--	@return An integer that should be interpreted as a bit mask containing information about who can get the quest.
		CodeObtainers = function(self, questId)
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			return nil ~= questId and self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 4) or 0
		end,

		---
		--	Returns a bit mask indicating the race of the obtainers who can get the quest.
		--	@return An integer that should be interpreted as a bit mask containing information about who can get the quest.
		CodeObtainersRace = function(self, questId)
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			return nil ~= questId and self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 2) or 0
		end,

		--	This routine breaks apart a "prerequisite" code into its component
		--	parts.  The code and subcode can both be empty strings, while the
		--	numeric would be nil if there is an error in questCode.
		CodeParts = function(self, questCode)
			local code, subcode, numeric = '', '', tonumber(questCode)
			if nil == numeric and nil ~= questCode then
				-- Cn+ (c can be a letter)
				code = strsub(questCode, 1, 1)
				numeric = tonumber(strsub(questCode, 2))

				-- CSSSn+ (sss can have letters)
				if 'T' == code or 't' == code or 'U' == code or 'u' == code or '_' == code or '~' == code then
					subcode = strsub(questCode, 2, 4)
					numeric = tonumber(strsub(questCode, 5))

				-- Csssn+ (sss must be numbers)
				elseif 'V' == code or 'W' == code or 'w' == code or 'r' == code then
					subcode = tonumber(strsub(questCode, 2, 4))
					numeric = tonumber(strsub(questCode, 5))

				-- CS
				elseif 'F' == code or 'N' == code or 'n' == code then
					subcode = strsub(questCode, 2, 2)
					numeric = ''

				-- Cnnnns+	(for K it is Cnnnnnnnnns+)
				elseif 'G' == code or 'K' == code then
					-- Note numeric and subcode are reverse from traditional codes
					local lengthToUse = 'G' == code and 5 or 10
					numeric = tonumber(strsub(questCode, 2, lengthToUse))
					if lengthToUse < strlen(questCode) then
						subcode = tonumber(strsub(questCode, lengthToUse + 1))
					end

				-- Cnnnnn
				elseif 'z' == code then
					numeric = tonumber(strsub(questCode, 2, 5))

				-- Cssssn+ (ssss must be numbers)
				elseif '=' == code or '<' == code or '>' == code or ')' == code or '`' == code then
					subcode = tonumber(strsub(questCode, 2, 5))
					numeric = tonumber(strsub(questCode, 6))

				-- Cnnns+
				elseif '@' == code then
					-- Note numeric and subcode are reverse from traditional codes
					numeric = tonumber(strsub(questCode, 2, 4))
					subcode = tonumber(strsub(questCode, 5))
				
				-- Csn+ (s must be a number)
				elseif '$' == code or '*' == code then
					subcode = tonumber(strsub(questCode, 2, 2))
					numeric = tonumber(strsub(questCode, 3))
				end

				-- CSn+ (s can be a letter)
				if nil == numeric then
					subcode = strsub(questCode, 2, 2)
					numeric = tonumber(strsub(questCode, 3))
				end
			end
			return code, subcode, numeric
		end,

		---
		--	Internal Use.
		--	Returns a table of codes from the victim string that match the sought prefix.
		--	@param victim The string that contains codes separated by spaces.
		--	@param soughtPrefix The prefix of the desired matching codes.
		--	@return A table of the matching codes or nil if there are none.
		CodesWithPrefix = function(self, victim, soughtPrefix)
			local start = strfind(victim, soughtPrefix, 1, true)
			if not start then return end

			local finish
			local retval

			soughtPrefix = " " .. soughtPrefix
			if not (start == 1 or strbyte(victim, start - 1) == 32) then
				start = strfind(victim, soughtPrefix, 1, true) + 1
			end

			while start do
				finish = strfind(victim, " ", start, true)
				if not retval then retval = {} end
				if finish then
					retval[#retval + 1] = strsub(victim, start, finish - 1)
					start = strfind(victim, soughtPrefix, finish, true)
					if start then start = start + 1 end
				else
					retval[#retval + 1] = strsub(victim, start)
					start = nil
				end
			end

			return retval
		end,

		AssociatedQuestsForNPC = function(self, npcId)
			local retval = nil
			npcId = tonumber(npcId)
			return npcId and self.npc.questAssociations[npcId] or nil
		end,

		---
		--	Returns a bit mask indicating the type of the quest.
		--	@return An integer that should be interpreted as a bit mask containing information about the type of quest.
		CodeType = function(self, questId)
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			return nil ~= questId and self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 1) or 0
		end,

		-- This checks to see if the npcList contains an NPC that is an alias for the soughtNPC
		_ContainsAliasNPC = function(self, npcList, soughtNPC)
			local retval = false
			if nil ~= npcList and nil ~= soughtNPC then
				for _, npcId in pairs(npcList) do
					local locations = self:_RawNPCLocations(npcId)
					if nil ~= locations then
						for _, npc in pairs(locations) do
							if npc.alias == soughtNPC then
								retval = true
							end
						end
					end
				end
			end
			return retval
		end,

		_ContainsPrerequisiteNPC = function(self, npcList, soughtNPC)
			local retval = false
			if nil ~= npcList and nil ~= soughtNPC then
				if nil ~= npcList[soughtNPC] then
					retval = true
				else
					-- Check to see whether there is an alias NPC id present
					for npcId in pairs(npcList) do
						local locations = self:_RawNPCLocations(npcId)
						if nil ~= locations then
							for _, npc in pairs(locations) do
								if npc.alias == soughtNPC then
									retval = true
								end
							end
						end
					end
				end
			end
			return retval
		end,

		_CountCompleteInDatabase = function(self, db)
			local retval = 0
			db = db or GrailDatabasePlayer["completedQuests"]
			for key, value in pairs(db) do
				for i = 0, 31 do
					if bitband(value, 2^i) > 0 then
						retval = retval + 1
					end
				end
			end
			return retval
		end,

		---
		--	Returns the localized and gender specific name of the player's class.
		--	@param englishName The Blizzard internal name of the class.  If nil, the player's class will be used.
		--	@param desiredGender The numeric value for the desired gender (2 is male and 3 is female).  If nil, the player's gender will be used.
		--	@return A string whose value is the localized name of the class using the appropriate gender where applicable.
		CreateClassNameLocalizedGenderized = function(self, englishName, desiredGender)
			local nameToUse = englishName or self.playerClass
			local genderToUse = desiredGender or self.playerGender
			return (genderToUse == 3) and LOCALIZED_CLASS_NAMES_FEMALE[nameToUse] or LOCALIZED_CLASS_NAMES_MALE[nameToUse]
		end,

		---
		--	Internal Use.
		--	Populates internal quest lists based on location of NPCs that can start
		--	the quests.  In normal mode, the API will use this indexed list instead
		--	of accessing the NPC information, thereby speeding up queries.
		CreateIndexedQuestList = function(self)
			local debugStartTime = debugprofilestop()
			self.indexedQuests = {}
			self.indexedQuestsExtra = {}
			self.loremasterQuests = {}
			self.specialQuests = {}
			self.unnamedZones = {}

			local locations
			local mapId
			local bitMask
			local questName
			local mapIdsWithNames = {}
			local mapName
			local totalLocationsTime = 0
			self.totalQuestLocationsAcceptTime = 0
			self.totalRawNPCLocations = 0

--			for questId in pairs(self.quests) do
			for questId in pairs(self.questCodes) do

				self.quests[questId] = self.quests[questId] or {}
--	Conceptually it would be nice for those that access the self.quests[questId]['SP'] structure
--	directly to be able to get access to the data they desire without needing to change their code
--	with something like this.  However, this will not work because we need to know the questId in
--	the __index function but we do not have that informtion in the table.
--				self.quests[questId] = self.quests[questId] or setmetatable({}, {
--					__index = function(table, anIndex)
--						if 'SP' == anIndex then
--							return bitband(Grail:CodeType(questId), Grail.bitMaskQuestSpecial) > 0
--						end
--						return nil
--					end,
--					})
				self:_CodeAllFixed(questId)

				local start2Time = debugprofilestop()
				--	Add the quests to the map areas based on the locations of the starting NPCs
--				locations = self:QuestLocations(questId, 'A')
				locations = self:QuestLocationsAccept(questId, nil, nil, nil, nil, nil, nil, true)
				if nil ~= locations then
					for _, npc in pairs(locations) do
						if nil ~= npc.mapArea then
							local mapId = npc.mapArea
							-- Add this quest to the list of treasure quests per zone if appropriate
							if self:IsTreasure(questId) then
								self:_InsertSet(self.mapAreasWithTreasures, mapId, questId)
							end
							if npc.realArea then
								if not self.experimental then
									self:_InsertSet(self.indexedQuestsExtra, mapId, questId)
								else
									self:_MarkQuestInDatabase(questId, self.indexedQuestsExtra[mapId])
								end
							else
								if not self.experimental then
									self:_InsertSet(self.indexedQuests, mapId, questId)
								else
									self:_MarkQuestInDatabase(questId, self.indexedQuests[mapId])
								end
							end
							if nil == mapIdsWithNames[mapId] then
								mapName = self:_GetMapNameByID(mapId)
								if "" ~= mapName then
									if nil == self.zoneNameMapping[mapName] or self.zoneNameMapping[mapName] ~= mapId then self.unnamedZones[mapId] = true end
									mapIdsWithNames[mapId] = mapName
								end
							end
						else
-- *** --							if self.GDE.debug then print("Quest", questId, "has nil mapId for NPC", npc.name, npc.id) end
							self:_InsertSet(self.indexedQuests, self.mapAreaBaseOther, questId)
						end
					end
				end
				totalLocationsTime = totalLocationsTime + (debugprofilestop() - start2Time)

				-- Add this quest if it automatically starts entering a map area
				if nil ~= self.quests[questId]['AZ'] then
--					self:AddQuestToMapArea(questId, self.quests[questId]['AZ'], self.mapAreaMapping[self.quests[questId]['AZ']])
					for _, mapAreaId in pairs(self.quests[questId]['AZ']) do
						self:AddQuestToMapArea(questId, mapAreaId, self.mapAreaMapping[mapAreaId])
					end
				end

				--	Add this quest to holiday quests
				bitMask = self:CodeHoliday(questId)
				if 0 ~= bitMask then
					for bitValue,code in pairs(self.holidayBitToCodeMapping) do
						if bitband(bitMask, bitValue) > 0 then
							self:AddQuestToMapArea(questId, tonumber(self.holidayToMapAreaMapping['H'..code]), self.holidayMapping[code])
						end
					end
				end

				--	Add this quest to class quests
				bitMask = bitband(self:CodeObtainers(questId), self.bitMaskClassAll)
				if bitMask ~= self.bitMaskClassAll then
					for bitValue,code in pairs(self.classBitToCodeMapping) do
						if bitband(bitMask, bitValue) > 0 then
							self:AddQuestToMapArea(questId, tonumber(self.classToMapAreaMapping['C'..code]), self:CreateClassNameLocalizedGenderized(self.classMapping[code]))
						end
					end
				end

				--	Add this quest to daily quests
				if bitband(self:CodeType(questId), self.bitMaskQuestDaily) > 0 then
					self:AddQuestToMapArea(questId, self.mapAreaBaseDaily, DAILY)
				end
				
				--	Add this quest to reputation quests
				if nil ~= self.questReputationRequirements[questId] then
					local reputationCodes = self.questReputationRequirements[questId]
					local reputationCount = strlen(reputationCodes) / 4
					local index, value
					for i = 1, reputationCount do
						index, value = self:ReputationDecode(strsub(reputationCodes, i * 4 - 3, i * 4))
						self:AddQuestToMapArea(questId, self.mapAreaBaseReputation + tonumber(index, 16), REPUTATION .. " - " .. self.reputationMapping[index])
					end
				end

				--	Deal with SPecial and repeatable quests to allow them to be accepted even when they do not appear in the quest log
				if bitband(self:CodeType(questId), self.bitMaskQuestRepeatable + self.bitMaskQuestSpecial) > 0 then
					questName = self:QuestName(questId, 3)
-- TODO: Need to rethink how we deal with specialQuests because name getting is going to be delayed...perhaps store by questId
if nil ~= questName then
					if nil == self.specialQuests[questName] then self.specialQuests[questName] = {} end
					-- Now we go through and get the NPCs that give this quest and add them to the name table matching this quest
					local npcs = self:_TableAppendCodes(nil, self.quests[questId], { 'A', 'AK' })
					if nil ~= npcs then
						for _, questGiverId in pairs(npcs) do
							tinsert(self.specialQuests[questName], { questGiverId, questId })
						end
					end
end
				end

			end
			mapIdsWithNames = nil
			self.timings.CreateIndexedQuestList = debugprofilestop() - debugStartTime
			self.timings.CreateIndexedQuestListLocations = totalLocationsTime
			self.timings.QuestLocationsAcceptTime = self.totalQuestLocationsAcceptTime
			self.timings.RawNPCLocationsTime = self.totalRawNPCLocations
			if self.GDE.debug then print("Done creating indexed quest list with elapsed milliseconds:", self.timings.CreateIndexedQuestList) end
		end,

		---
		--	Returns the localized and gender specific name of the player's race.
		--	@param englishName The Blizzard internal name of the class.  If nil, the player's class will be used.
		--	@param desiredGender The numeric value for the desired gender (2 is male and 3 is female).  If nil, the player's gender will be used.
		--	@return A string whose value is the localized name of the race using the appropriate gender where applicable.
		CreateRaceNameLocalizedGenderized = function(self, englishName, desiredGender)
			local retval = nil
			local nameToUse = englishName or self.playerClass
			local genderToUse = desiredGender or self.playerGender
			local codeToUse = nil
			for code, raceTable in pairs(self.races) do
				local raceName = raceTable[1]
				if raceName == nameToUse then
					codeToUse = code
				end
			end
			if nil ~= codeToUse then
				retval = self.races[codeToUse][genderToUse]
			end
			return retval
		end,

		CurrentDateTime = function(self)
			local date
			if self.existsClassic then
				date = C_DateAndTime.GetTodaysDate()
				date.monthDay = date.day
				date.weekday = date.weekDay	-- don't you just hate it when Blizzard API uses different capitalization!
				date.hour, date.minute = GetGameTime()
			else
				date = C_DateAndTime.GetCurrentCalendarTime()
			end
			return date.weekday, date.month, date.monthDay, date.year, date.hour, date.minute
		end,

		---
		--	Returns a table of questIds that are simple prerequisites for the specified quest
		--	after they have been processed using any juxtaposed values.  The assumption is of
		--	course completion (turned in) of the juxtaposed quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of questIds that are simple prerequisites for this quest, or nil if there are none.
-- TODO: Fix the code this calls.  This name changed so Wholly does not use it until we fix the next routine.
		FIX_DisplayableQuestPrerequisites = function(self, questId, forceRawData)
			local retval = self:_ProcessForFlagQuests(self:QuestPrerequisites(questId, true))	-- we process using raw data no matter what
			if retval and not forceRawData then
				retval = self:_FromPattern(retval)
			end
			return retval
		end,

		---
		--	Determines whether the internal database contains the NPC specified by npcId.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return true if the NPC is known to the internal database, false otherwise
		DoesNPCExist = function(self, npcId)
			npcId = tonumber(npcId)
			return nil ~= npcId and nil ~= self.npc.locations[npcId] and true or false
		end,

		---
		--	Determines whether the internal database contains the quest specified by questId.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is known to the internal database, false otherwise
		DoesQuestExist = function(self, questId)
			questId = tonumber(questId)
			return nil ~= questId and nil ~= self.questCodes[questId] and true or false
		end,

		-- This is a "f" function that evaluates the codeString to see whether it is a quest that requires presence in the
		-- quest log and fails if such a quest is already complete or cannot be obtained.
		_EvaluateCodeAsNotInLogImpossible = function(codeString, p)
			local good, failures = true, {}

			if nil ~= codeString then
				local code = strsub(codeString, 1, 1)
				if 'B' == code or 'D' == code then
					local questId = tonumber(strsub(codeString, 2))
					local status = Grail:StatusCode(questId)
					if bitband(status, Grail.bitMaskQuestFailureWithAncestor + Grail.bitMaskCompleted) > 0 or Grail:IsQuestObsolete(questId) or Grail:IsQuestPending(questId) then
						good = false
					end
				end
			end

			if 0 == #failures then failures = nil end
			return good, failures
		end,

		-- This is a "f" function that evaluates the codeString to see whether it is met when considered a prerequisite.
		_EvaluateCodeAsPrerequisite = function(codeString, p, forceSpecificChecksOnly)
			local good, failures = true, {}

			if nil ~= codeString then
				local questId = p and p.q or nil
				local dangerous = p and p.d or false
				local questCompleted, questInLog, questStatus, questEverCompleted, canAcceptQuest, spellPresent, achievementComplete, itemPresent, questEverAbandoned, professionGood, questEverAccepted, hasSkill, spellEverCast, spellEverExperienced, groupDone, groupAccepted, reputationUnder, reputationExceeds, factionMatches, phaseMatches, iLvlMatches, garrisonBuildingMatches, needsMatchBoth, levelMeetsOrExceeds, groupDoneOrComplete, achievementNotComplete, levelLessThan, playerAchievementComplete, playerAchievementNotComplete, garrisonBuildingNPCMatches, classMatches, artifactKnowledgeLevelMatches, worldQuestAvailable, friendshipReputationUnder, friendshipReputationExceeds, artifactLevelMatches, missionMatches, threatQuestAvailable, azeriteLevelMatches, renownExceeds, callingQuestAvailable, garrisonTalentResearched, questTurnedIndBeforeLastWeeklyReset, questTurnedIndBeforeTodaysReset, currencyAmountMatches, majorFactionRenownLevelMatches, poiPresent, majorFactionRenownLevelMatchesAccountWide, groupInLogOrTurnedIn = false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
				local checkLog, checkEver, checkStatusComplete, shouldCheckTurnin, checkSpell, checkAchievement, checkItem, checkItemLack, checkEverAbandoned, checkNeverAbandoned, checkProfession, checkEverAccepted, checkHasSkill, checkNotCompleted, checkNotSpell, checkEverCastSpell, checkEverExperiencedSpell, checkGroupDone, checkGroupAccepted, checkReputationUnder, checkReputationExceeds, checkSkillLack, checkFaction, checkPhase, checkILvl, checkGarrisonBuilding, checkStatusNotComplete, checkLevelMeetsOrExceeds, checkGroupDoneOrComplete, checkAchievementLack, checkLevelLessThan, checkPlayerAchievement, checkPlayerAchievementLack, checkGarrisonBuildingNPC, checkNotTurnin, checkNotLog, checkClass, checkArtifactKnowledgeLevel, checkWorldQuestAvailable, checkFriendshipReputationExceeds, checkFriendshipReputationUnder, checkArtifactLevel, checkMission, checkNever, checkThreatQuestAvailable, checkAzeriteLevel, checkRenownLevel, checkCallingQuestAvailable, checkGarrisonTalent, checkQuestTurnedInBeforeLastWeeklyReset, checkRenownDoesNotMeetOrExceed, checkNotClass, checkQuestTurnedInBeforeTodaysReset, checkCurrencyAmount, checkMajorFactionRenownLevel, checkPOIPresent, checkMajorFactionRenownLevelAccountWide, checkGroupInLogOrTurnedIn = false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false
				local forcingProfessionOnly, forcingReputationOnly = false, false

				if forceSpecificChecksOnly then
					if bitband(forceSpecificChecksOnly, Grail.bitMaskProfession) > 0 then
						forcingProfessionOnly = true
					end
					if bitband(forceSpecificChecksOnly, Grail.bitMaskReputation) > 0 then
						forcingReputationOnly = true
					end
				end

				local code, subcode, value = Grail:CodeParts(codeString)

				if code == '' then
					if dangerous then	-- we are checking I:
						code = 'C'
					else				-- we are checking P:
						code = 'A'
					end
				end

				--	We do not care about any prerequisite except profession ones when forcingProfessionOnly
				if forcingProfessionOnly and 'P' ~= code then
					code = ' '
				end
				if forcingReputationOnly and ('T' ~= code and 't' ~= code and 'U' ~= code and 'u' ~= code) then
					code = ' '
				end

				-- Now to figure out what needs to be checked based on the code
				if code == ' ' then
					-- We do nothing since we are using this to indicate 
				elseif code == 'A' then	shouldCheckTurnin = true
				elseif code == 'a' then checkWorldQuestAvailable = true
				elseif code == 'b' then checkThreatQuestAvailable = true
				elseif code == 'B' then checkLog = true
				elseif code == 'C' then	shouldCheckTurnin = true
										checkLog = true
				elseif code == 'c' then checkNotTurnin = true
										checkNotLog = true
				elseif code == 'D' then	checkStatusComplete = true
				elseif code == 'E' then	shouldCheckTurnin = true
										checkStatusComplete = true
				elseif code == 'e' then checkStatusNotComplete = true
										checkNotCompleted = true
				elseif code == 'F' then checkFaction = true
				elseif code == 'G' then checkGarrisonBuilding = true
				elseif code == 'H' then	checkEver = true
				elseif code == 'h' then checkNever = true
				elseif code == 'I' then	checkSpell = true
				elseif code == 'i' then	checkNotSpell = true
				elseif code == 'J' then	checkAchievement = true
				elseif code == 'j' then	checkAchievementLack = true
				elseif code == 'K' then	checkItem = true
				elseif code == 'k' then	checkItemLack = true
				elseif code == 'L' then checkLevelMeetsOrExceeds = true
				elseif code == 'l' then checkLevelLessThan = true
				elseif code == 'M' then	checkEverAbandoned = true
				elseif code == 'm' then	checkNeverAbandoned = true
				elseif code == 'N' then checkClass = true
				elseif code == 'n' then checkNotClass = true
				elseif code == 'O' then	checkEverAccepted = true
				elseif code == 'P' then	checkProfession = true
				elseif code == 'Q' or
					   code == 'q' then checkILvl = true
				elseif code == 'R' then checkEverExperiencedSpell = true
				elseif code == 'r' then checkGroupInLogOrTurnedIn = true
				elseif code == 'S' then	checkHasSkill = true
				elseif code == 's' then checkSkillLack = true
				elseif code == 'T' then checkReputationExceeds = true
				elseif code == 't' then checkReputationUnder = true
				elseif code == 'U' then checkFriendshipReputationExceeds = true
				elseif code == 'u' then checkFriendshipReputationUnder = true
				elseif code == 'V' then checkGroupAccepted = true
				elseif code == 'v' then checkQuestTurnedInBeforeLastWeeklyReset = true
				elseif code == 'W' then checkGroupDone = true
				elseif code == 'w' then checkGroupDoneOrComplete = true
				elseif code == 'X' then	checkNotCompleted = true
				elseif code == 'x' then checkArtifactKnowledgeLevel = true
				elseif code == 'Y' then	checkPlayerAchievement = true
				elseif code == 'y' then	checkPlayerAchievementLack = true
				elseif code == 'Z' then checkEverCastSpell = true
				elseif code == 'z' then checkGarrisonBuildingNPC = true
				elseif code == '=' or
					   code == '<' or
					   code == '>' then checkPhase = true
				elseif code == '@' then checkArtifactLevel = true
				elseif code == '#' then checkMission = true
				elseif code == '&' then checkAzeriteLevel = true
				elseif code == '$' then checkRenownLevel = true
				elseif code == '*' then checkRenownDoesNotMeetOrExceed = true
				elseif code == '^' then checkCallingQuestAvailable = true
				elseif code == '%' then checkGarrisonTalent = true
				elseif code == '(' then checkQuestTurnedInBeforeTodaysReset = true
				elseif code == ')' then checkCurrencyAmount = true
				elseif code == '_' then checkMajorFactionRenownLevel = true
				elseif code == '~' then checkMajorFactionRenownLevelAccountWide = true
				elseif code == '`' then checkPOIPresent = true
				else print("|cffff0000Grail|r _EvaluateCodeAsPrerequisite cannot process code", codeString)
				end

				if shouldCheckTurnin or checkNotCompleted or checkNotTurnin then questCompleted = Grail:IsQuestCompleted(value) end
				if checkLog or checkStatusComplete or checkStatusNotComplete or checkNotLog then questInLog, questStatus = Grail:IsQuestInQuestLog(value) end
				if checkEver then questEverCompleted = Grail:HasQuestEverBeenCompleted(value) end
				if checkNever then questEverCompleted = not Grail:HasQuestEverBeenCompleted(value) end
				if (shouldCheckTurnin and questCompleted) or (checkEver and questEverCompleted) then
--	TODO:	Solve this issue:
--		We have quest 30727 that has I:H30727 that seems to be causing the quest to be marked as invalidated.  This I assume is because the previous quest
--		30726 is no longer obtainable (since it is likewise marked I:H30726 which resolves as unobtainable since 30726 has already been completed) and we
--		get the inherited prerequisite failure.
					if dangerous then
						local t = Grail.currentMortalIssues[value] or {}
						if value ~= questId and not tContains(t, questId) then tinsert(t, questId) end
						Grail.currentMortalIssues[value] = t
					else
--						canAcceptQuest = Grail:CanAcceptQuest(value, true)
						canAcceptQuest = Grail:CanAcceptQuest(value, true, true, true, true, true)
					end
				end
				if checkSpell or checkNotSpell then spellPresent = Grail:SpellPresent(value) end
				if checkAchievement then achievementComplete = Grail:AchievementComplete(value) end
				if checkAchievementLack then achievementNotComplete = not Grail:AchievementComplete(value) end
				if checkPlayerAchievement then playerAchievementComplete = Grail:AchievementComplete(value, true) end
				if checkPlayerAchievementLack then playerAchievementNotComplete = not Grail:AchievementComplete(value, true) end
				if checkItem or checkItemLack then itemPresent = Grail:ItemPresent(value, subcode) end
				if checkItem and nil ~= Grail.questStatusCache.itemCountGroupToQuest[value] then
					local mostAvailable = nil
					local questWithMostAvailable = nil
					for aQuestId, anItemCount in pairs(Grail.questStatusCache.itemCountGroupToQuest[value]) do
						if Grail:ItemPresent(value, anItemCount) then
							if mostAvailable == nil or anItemCount > mostAvailable then
								mostAvailable = anItemCount
								questWithMostAvailable = aQuestId
							end
						end
					end
					if questWithMostAvailable ~= questId then
						itemPresent = false
					end
				end
				if checkEverAbandoned or checkNeverAbandoned then questEverAbandoned = Grail:HasQuestEverBeenAbandoned(value) end
				if checkProfession then professionGood = Grail:ProfessionExceeds(subcode, value) end
				if checkEverAccepted then questEverAccepted = Grail:HasQuestEverBeenAccepted(value) end
				if checkHasSkill or checkSkillLack then hasSkill = Grail:_HasSkill(value) end
				if checkEverCastSpell then spellEverCast = Grail:_EverCastSpell(value) end
				if checkEverExperiencedSpell then spellEverExperienced = Grail:EverExperiencedSpell(value) end
				if checkGroupDone then groupDone = Grail:MeetsRequirementGroupControl({groupNumber = subcode, minimum = value, turnedIn = true}) end
				if checkGroupDoneOrComplete then groupDoneOrComplete = Grail:MeetsRequirementGroupControl({ groupNumber = subcode, minimum = value, turnedIn = true, completeInLog = true}) end
				if checkGroupAccepted then groupAccepted = Grail:MeetsRequirementGroupControl({groupNumber = subcode, minimum = value, accepted = true}) end
				if checkGroupInLogOrTurnedIn then groupInLogOrTurnedIn = Grail:MeetsRequirementGroupControl({groupNumber = subcode, minimum = value, inLog = true, turnedIn = true, exactMatch = true }) end
				if checkReputationUnder or checkReputationExceeds then
					local exceeds, earnedValue = Grail:_ReputationExceeds(Grail.reputationMapping[subcode], value)
					if not exceeds then reputationUnder = true end
					if exceeds then reputationExceeds = true end
				end
				if checkFriendshipReputationExceeds or checkFriendshipReputationUnder then
					local exceeds, earnedValue = Grail:_FriendshipReputationExceeds(Grail.reputationMapping[subcode], value)
					if not exceeds then friendshipReputationUnder = true end
					if exceeds then friendshipReputationExceeds = true end
				end
				if checkFaction then
					if ('A' == subcode and 'Alliance' == Grail.playerFaction) or ('H' == subcode and 'Horde' == Grail.playerFaction) then
						factionMatches = true
					end
				end
				if checkPhase then phaseMatches = Grail:_PhaseMatches(code, subcode, value) end
				if checkILvl then iLvlMatches = Grail:_iLvlMatches(code, value) end
				if checkGarrisonBuilding then
					if nil == subcode or '' == subcode then
						garrisonBuildingMatches = Grail:HasGarrisonBuilding(value)
					else
						garrisonBuildingMatches = Grail:HasGarrisonBuildingInPlot(value, subcode)
					end
				end
				if checkGarrisonBuildingNPC then
					garrisonBuildingNPCMatches = Grail:HasGarrisonBuildingNPCWorking(value)
				end
				if checkStatusNotComplete and checkNotCompleted then
					-- TODO: this is a situation where we need an AND between the two, where each individually will not succeed
					--			which means we need to know the difference between this case and those that are individual
					needsMatchBoth = true
				end
				if checkLevelMeetsOrExceeds then
					levelMeetsOrExceeds = (Grail.levelingLevel >= value)
				end
				if checkLevelLessThan then
					levelLessThan = (Grail.levelingLevel < value)
				end
				if checkClass or checkNotClass then
					classMatches = (Grail.classNameToCodeMapping[Grail.playerClass] == subcode)
				end
				if checkArtifactKnowledgeLevel then
					artifactKnowledgeLevelMatches = (Grail:ArtifactKnowledgeLevel() >= value)
				end
				if checkWorldQuestAvailable then
					worldQuestAvailable = Grail:IsAvailable(value)
				end
				if checkArtifactLevel then
					artifactLevelMatches = Grail:ArtifactLevelMeetsOrExceeds(subcode, value)
				end
				if checkMission then
					missionMatches = Grail:IsMissionAvailable(value)
				end
				if checkThreatQuestAvailable then
					threatQuestAvailable = Grail:IsAvailable(value)
				end
				if checkAzeriteLevel then
					azeriteLevelMatches = Grail:AzeriteLevelMeetsOrExceeds(value)
				end
				if checkRenownLevel or checkRenownDoesNotMeetOrExceed then
					renownExceeds = Grail:_CovenantRenownMeetsOrExceeds(subcode, value)
				end
				if checkCallingQuestAvailable then
					callingQuestAvailable = Grail:IsAvailable(value)
				end
				if checkGarrisonTalent then
					garrisonTalentResearched = Grail:_GarrisonTalentResearched(value)
				end
				if checkQuestTurnedInBeforeLastWeeklyReset then
					questTurnedIndBeforeLastWeeklyReset = Grail:_QuestTurnedInBeforeLastWeeklyReset(value)
				end
				if checkQuestTurnedInBeforeTodaysReset then
					questTurnedIndBeforeTodaysReset = Grail:_QuestTurnedInBeforeTodaysReset(value)
				end
				if checkCurrencyAmount then
					currencyAmountMatches = Grail:CurrencyAmountMeetsOrExceeds(subcode, value)
				end
				if checkMajorFactionRenownLevel then
					majorFactionRenownLevelMatches = Grail:MajorFactionRenownLevelMeetsOrExceeds(Grail.reputationMapping[subcode], value)
				end
				if checkMajorFactionRenownLevelAccountWide then
					majorFactionRenownLevelMatchesAccountWide = Grail:MajorFactionRenownLevelMeetsOrExceeds(Grail.reputationMapping[subcode], value, true)
				end
				if checkPOIPresent then
					poiPresent = Grail:POIPresent(subcode, value)
				end

				good =
					(code == ' ') or
					(shouldCheckTurnin and questCompleted and canAcceptQuest) or
					(not needsMatchBoth and checkNotCompleted and not questCompleted) or
					(checkLog and questInLog) or
					(checkEver and questEverCompleted and canAcceptQuest) or
					(checkNever and not questEverCompleted) or
					(checkStatusComplete and questInLog and questStatus ~= nil and questStatus > 0) or
					(not needsMatchBoth and checkStatusNotComplete and questInLog and (questStatus == nil or questStatus == 0)) or
					(needsMatchBoth and checkStatusNotComplete and questInLog and (questStatus == nil or questStatus == 0) and checkNotCompleted and not questCompleted) or
					(checkSpell and spellPresent) or
					(checkNotSpell and not spellPresent) or
					(checkAchievement and achievementComplete) or
					(checkAchievementLack and achievementNotComplete) or
					(checkPlayerAchievement and playerAchievementComplete) or
					(checkPlayerAchievementLack and playerAchievementNotComplete) or
					(checkItem and itemPresent) or
					(checkItemLack and not itemPresent) or
					(checkEverAbandoned and questEverAbandoned) or
					(checkNeverAbandoned and not questEverAbandoned) or
					(checkProfession and professionGood) or
					(checkEverAccepted and questEverAccepted) or
					(checkHasSkill and hasSkill) or
					(checkEverCastSpell and spellEverCast) or
					(checkEverExperiencedSpell and spellEverExperienced) or
					(checkGroupDone and groupDone) or
					(checkGroupAccepted and groupAccepted) or
					(checkReputationUnder and reputationUnder) or
					(checkReputationExceeds and reputationExceeds) or
					(checkFriendshipReputationUnder and friendshipReputationUnder) or
					(checkFriendshipReputationExceeds and friendshipReputationExceeds) or
					(checkSkillLack and not hasSkill) or
					(checkFaction and factionMatches) or
					(checkPhase and phaseMatches) or
					(checkILvl and iLvlMatches) or
					(checkGarrisonBuilding and garrisonBuildingMatches) or
					(checkGarrisonBuildingNPC and garrisonBuildingNPCMatches) or
					(checkLevelMeetsOrExceeds and levelMeetsOrExceeds) or
					(checkLevelLessThan and levelLessThan) or
					(checkGroupDoneOrComplete and groupDoneOrComplete) or
					(checkNotLog and checkNotTurnin and not questCompleted and not questInLog) or
					(checkClass and classMatches) or
					(checkNotClass and not classMatches) or
					(checkArtifactKnowledgeLevel and artifactKnowledgeLevelMatches) or
					(checkWorldQuestAvailable and worldQuestAvailable) or
					(checkArtifactLevel and artifactLevelMatches) or
					(checkMission and missionMatches) or
					(checkThreatQuestAvailable and threatQuestAvailable) or
					(checkAzeriteLevel and azeriteLevelMatches) or
					(checkRenownLevel and renownExceeds) or
					(checkRenownDoesNotMeetOrExceed and not renownExceeds) or
					(checkCallingQuestAvailable and callingQuestAvailable) or
					(checkGarrisonTalent and garrisonTalentResearched) or
					(checkQuestTurnedInBeforeLastWeeklyReset and questTurnedIndBeforeLastWeeklyReset) or
					(checkQuestTurnedInBeforeTodaysReset and questTurnedIndBeforeTodaysReset) or
					(checkCurrencyAmount and currencyAmountMatches) or
					(checkMajorFactionRenownLevel and majorFactionRenownLevelMatches) or
					(checkMajorFactionRenownLevelAccountWide and majorFactionRenownLevelMatchesAccountWide) or
					(checkPOIPresent and poiPresent) or
					(checkGroupInLogOrTurnedIn and groupInLogOrTurnedIn)
				if not good then tinsert(failures, codeString) end
			end

			if 0 == #failures then failures = nil end
			return good, failures
		end,

-- TODO: See why we are playing with a table for the failures here since we are just returning an integer in its first element
		_EvaluateCodeDoesNotFailQuestStatus = function(codeString, p)
			local good, failures = true, {}

			if nil ~= codeString then
				local questId = p and p.q or nil
--				local code = strsub(codeString, 1, 1)
				local code, subcode, numeric = Grail:CodeParts(codeString)
				local anyFailure = nil
				if 'V' == code then
					if not Grail:MeetsRequirementGroupControl({groupNumber = subcode, minimum = numeric, accepted = true}) then
						anyFailure = Grail.bitMaskInvalidated
					end
				elseif 'W' == code then
					if not Grail:MeetsRequirementGroupControl({ groupNumber = subcode, minimum = numeric, possible = true}) then
						anyFailure = Grail.bitMaskInvalidated
					end
				elseif 'w' == code then
					if not Grail:MeetsRequirementGroupControl({ groupNumber = subcode, minimum = numeric, turnedIn = true, completeInLog = true}) then
						anyFailure = Grail.bitMaskInvalidated
					end
				elseif 'r' == code then
					if not Grail:MeetsRequirementGroupControl({groupNumber = subcode, minimum = numeric, inLog = true, turnedIn = true, exactMatch = true }) then
						anyFailure = Grail.bitMaskInvalidated
					end
				elseif 'T' == code or 't' == code then
					local exceeds, earnedValue = Grail:_ReputationExceeds(Grail.reputationMapping[subcode], numeric)
					if 'T' == code and not exceeds then
						anyFailure = Grail.bitMaskInvalidated
					elseif 't' == code and exceeds then
						anyFailure = Grail.bitMaskInvalidated
					end
				elseif 'U' == code or 'u' == code then
					local exceeds, earnedValue = Grail:_FriendshipReputationExceeds(Grail.reputationMapping[subcode], numeric)
					if 'U' == code and not exceeds then
						anyFailure = Grail.bitMaskInvalidated
					elseif 'u' == code and exceeds then
						anyFailure = Grail.bitMaskInvalidated
					end

				-- s means a lack of skill.  if the skill is present this means we fail because we assume you cannot unlearn a skill (or at least reasonably)
				elseif 's' == code then
					if Grail:_HasSkill(numeric) then
						anyFailure = Grail.bitMaskInvalidated
					end

				elseif	'F' ~= code
					and 'I' ~= code
					and 'J' ~= code
					and 'j' ~= code
					and 'Y' ~= code
					and 'y' ~= code
					and 'K' ~= code
					and 'k' ~= code
					and 'M' ~= code
					and 'm' ~= code
					and 'N' ~= code
					and 'n' ~= code
					and 'P' ~= code
					and 'R' ~= code
					and 'S' ~= code
					and 'i' ~= code
					and 'Z' ~= code
					and '=' ~= code
					and '<' ~= code
					and '>' ~= code
					and 'L' ~= code
					and 'l' ~= code
					and 'a' ~= code
					and 'b' ~= code
					and 'c' ~= code
					and '_' ~= code
					and '~' ~= code
					and '`' ~= code
					then

--					local currentQuestId = tonumber(codeString)
--					if nil == currentQuestId then currentQuestId = tonumber(strsub(codeString, 2)) end
					local currentQuestId = numeric

					local t = Grail.questStatusCache.Q[currentQuestId] or {}
					if not tContains(t, questId) then tinsert(t, questId) end
					if nil == currentQuestId then print("*** NIL from ", codeString, questId) return anyFailure end
					Grail.questStatusCache.Q[currentQuestId] = t
					local subCode = Grail:StatusCode(currentQuestId)
					--	SMH 2014-02-09
					--	The behavior of failing for ancestors is changing such that we will return both the current status hard failure and the ancestor one together and let
					--	the caller determine what needs to be done with this information.
					local failureBits = bitband(subCode, Grail.bitMaskQuestFailureWithAncestor)
					if failureBits > 0 then
						anyFailure = failureBits
--					local failureBits = bitband(subCode, Grail.bitMaskQuestFailure)
--					if failureBits > 0 then
--						-- this means this specific quest has bits in it that would cause failure (need not check prerequisites for it at all since it fails by itself)
--						anyFailure = failureBits
--					elseif bitband(subCode, Grail.bitMaskPrerequisites) > 0 then
--						-- this means the quest itself does not immediately fail, but it fails because of prerequisites, so that reason needs to be checked in
--						-- case it is one of the hard reasons for failure
--						failureBits = bitband(subCode, Grail.bitMaskQuestFailureWithAncestor)
--						if failureBits > 0 then
--							-- this means the quest has a prerequisite quest that fails in one of the hard ways
--							anyFailure = failureBits / 1024
--						end
					elseif Grail:IsQuestObsolete(currentQuestId) or Grail:IsQuestPending(currentQuestId) then
						anyFailure = Grail.bitMaskInvalidated
					end
				end
				if nil ~= anyFailure then
					good = false
					tinsert(failures, anyFailure)
				end
			end

			if 0 == #failures then failures = nil end
			return good, failures
		end,

		_EverCastSpell = function(self, spellId)
			return self:_IsQuestMarkedInDatabase(spellId, GrailDatabasePlayer["spellsCast"])
		end,

		EverExperiencedSpell = function(self, spellId)
			return self:_IsQuestMarkedInDatabase(spellId, GrailDatabasePlayer["buffsExperienced"])
		end,

		FactionAvailable = function(self, reputationIndex, playerFaction)
			local retval = false
			playerFaction = playerFaction or self.playerFaction
			local permittedFaction = self.reputationMappingFaction[reputationIndex]
			if permittedFaction == 'Neutral' or permittedFaction == playerFaction then
				retval = true
			end
			return retval
		end,

		--	This takes a string of items representing an OR structure and returns a list where
		--	each element in the list is one of the OR items.
		--	@param list The string representing a list of OR items
		--	@param splitter An optional splitter string, with comma being the default
		--	@param oldTable An optional table to use to populate, otherwise a new one is created
		--	@return A table where each OR item is an entry in the table
		_FromList = function(self, list, splitter, oldTable)
			local retval = oldTable or {}
			local splitterToUse = splitter or ','
			local items = { strsplit(splitterToUse, list) }
			local itemToInsert
			for i = 1, #items do
				itemToInsert = tonumber(items[i])
				if nil == itemToInsert then itemToInsert = items[i] end
				tinsert(retval, itemToInsert)
			end
			return retval
		end,

		--		A,B,C	{ A, B, C }		(A or B or C)
		--		A+B		{ {A, B } }		(A and B)
		--		A+B,C	{ {A, B}, C }	((A and B) or C)
		--		A+B,C+D	{ {A,B}, {C,D} }((A and B) or (C and D))
		--		A+B|C+D	{ {A,{B,C},D} }	(A and (B or C) and D)		-- the | is to be used for OR within an AND block
		--		A,B+C|D		{A, {B, {C, D}}} 	-- this should evaluate the same as the one that follows
		--		A,B+C,B+D	{A, {B, C}, {B, D}}

		--	This takes a string of items representing an AND/OR structure and returns a list where
		--	each element in the list is one of the OR items, and tables within the list elements
		--	are the AND items.
		--	@param list The string representing a list of OR items
		--	@param orSplitter An optional splitter string, with comma being the default
		--	@param andSplitter An optional splitter string, with plus being the default
		--	@param oldTable An optional table to use to populate, otherwise a new one is created
		--	@return A table where each OR item is an entry in the table
		_FromPattern = function(self, pattern, orSplitter, andSplitter, oldTable)
			local retval = oldTable or {}
			local orSplitterToUse = orSplitter or ','
			local andSplitterToUse = andSplitter or '+'
			local items = { strsplit(orSplitterToUse, pattern) }
			local andItems
			local subOrItems
			for i = 1, #items do
				andItems = self:_FromList(items[i], andSplitterToUse)
				if 1 == #andItems then				-- technically since there is only one item it should never contain the | because that is only used between more than one AND item
					tinsert(retval, andItems[1])
				else
					local newAndItems = {}
					for j = 1, #andItems do
						subOrItems = self:_FromList(andItems[j], '|')
						if 1 == #subOrItems then
							tinsert(newAndItems, subOrItems[1])
						else
							tinsert(newAndItems, subOrItems)
						end
					end
					tinsert(retval, newAndItems)
				end
			end
			return retval
		end,

		--	This takes the qualifiedList which should have the pattern
		--		item:prerequisitePattern
		--	and these can be separated by a semi-colon.  The return value
		--	is a table whose keys are the item and whose values are the
		--	prerequisitePattern.
		_FromQualified = function(self, qualifiedList, questId)
			local retval = {}
			local items = { strsplit(';', qualifiedList) }
			local colon, key, value
			for i = 1, #items do
				colon = strfind(items[i], ':', 1, true)
				if colon then
					key = tonumber(strsub(items[i], 1, colon - 1))
					value = self:_FromPattern(strsub(items[i], colon + 1))
					if questId then
						self:_ProcessQuestsForHandlers(questId, value, self.npcStatusCache);
					end
				else
					key = tonumber(items[i])
					value = {}
				end
--				retval[key] = value
				tinsert(retval, { key, value })
			end
			return retval
		end,

		--	This takes the structure which represents OR/AND combinations and for
		--	each quest value contained, will associate that quest's code with the
		--	provided questId.
		_FromStructure = function(self, structure, questId, code)
			for _, value in pairs(structure) do
				if "table" == type(value) then
					self:_FromStructure(value, questId, code)
				else
					local qId = tonumber(value)
					self.quests[qId] = self.quests[qId] or {}
					self.quests[qId][code] = self.quests[qId][code] or {}
					tinsert(self.quests[qId][code], questId)
				end
			end
		end,

		GarrisonBuildingLevelString = function(self, garrisonBuildingId)
			return self.garrisonBuildingLevelMapping[garrisonBuildingId]
		end,

		GetContainerItemID = function(self, container, slot)
			return (C_Container and C_Container.GetContainerItemID or GetContainerItemID)(container, slot)
		end,

		GetContainerItemInfo = function(self, container, slot)
			if C_Container then
				local info = C_Container.GetContainerItemInfo(container, slot)
				if nil == info then return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil end
				return info.iconFileID, info.stackCount, info.isLocked, info.quality, info.isReadable, info.hasLoot, info.hyperlink, info.isFiltered, info.hasNoValue, info.itemID, info.isBound
			else
				return GetContainerItemInfo(container, slot)
			end
		end,

		GetContainerNumSlots = function(self, bagSlot)
			return (C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots)(bagSlot)
		end,

		-- Blizzard changed from using GetFactionInfoByID to C_Reputation.GetFactionDataByID and we will make use
		-- of whichever is available to us, but return the data like that returned by GetFactionInfoByID.
		GetFactionInfoByID = function(self, factionID)
			if C_Reputation and C_Reputation.GetFactionDataByID then
				local info = C_Reputation.GetFactionDataByID(factionID)
				-- Note that we are not returning canSetInactive nor isAccountWide
				if info == nil then return nil end
				return
					info.name,
					info.description,
					info.reaction,					-- standingID?
					info.currentReactionThreshold,	-- barMin?
					info.nextReactionThreshold, 	-- barMax?
					info.currentStanding,			-- barValue?
					info.atWarWith,
					info.canToggleAtWar,
					info.isHeader,
					info.isCollapsed,
					info.isHeaderWithRep,			-- hasRep
					info.isWatched,
					info.isChild,
					info.id,
					info.hasBonusRepGain
					-- canBeLFGBonus
			else
				return GetFactionInfoByID(factionID)
			end
		end,

		-- Blizzard changed from using GetSpellTabInfo to C_SpellBook.GetSpellBookSkillLineInfo and we will make
		-- use of whichever is available to us, but return the data like that returned by GetSpellTabInfo.
		GetSpellTabInfo = function(self, skillLineIndex)
			if C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
				local info = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
				return
					info.name,
					info.iconID,
					info.itemIndexOffset,
					info.numSpellBookItems,
					info,isGuild,
					-- shouldHide
					-- specID
					info.offSpecID
			else
				-- name, texture, offset, numSlots, isGuild, offspecID
				return GetSpellTabInfo(skillLineIndex)
			end
		end,

		-- Blizzard changed from using GetFriendshipReputation to C_GossipInfo.GetFriendshipReputation and we will
		-- make use of whichever is available to us.
		GetFriendshipReputation = function(self, factionIndex)
			if C_GossipInfo then
				local info = C_GossipInfo.GetFriendshipReputation(factionIndex)
				-- reversedColor
				return info.friendshipFactionID, info.standing, info.maxRep, info.name, info.text, info.texture, info.reaction, info.reactionThreshold, info.nextThreshold
			else
				return GetFriendshipReputation(factionIndex)
			end
		end,

		--	This routine returns the current "weekly" day which is the start time date for
		--	weekly quests in the format YYYY-MM-DD.
		_GetWeeklyDay = function(self)
			local lastWeeklyResetDate = C_DateAndTime.AdjustTimeByMinutes(C_DateAndTime.GetCurrentCalendarTime(), (C_DateAndTime.GetSecondsUntilWeeklyReset() - (86400 * 7)) / 60)
			return strformat("%4d-%02d-%02d", lastWeeklyResetDate.year, lastWeeklyResetDate.month, lastWeeklyResetDate.monthDay)
		end,

		--	This routine returns the current "daily" day which is the start time date for
		--	daily quests in the format YYYY-MM-DD.
		_GetDailyDay = function(self)
			local secondsUntilReset = GetQuestResetTime()
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
			local seconds = hour * 3600 + minute
			if seconds + secondsUntilReset >= 86400 then
				-- do nothing since the next period starts tomorrow, which means the current period started today
			else
				-- Must move the clock back one day since today is actually on the day of the next reset
				if day > 1 then
					day = day - 1
				else
					if month > 1 then
						month = month - 1
						if 2 == month then
							day = 28
							if 0 == year % 4 then	-- we can ignore the real definition of a leap year since it will not be important for decades
								day = 29
							end
						elseif 4 == month or 6 == month or 9 == month or 11 == month then
							day = 30
						else
							day = 31
						end
					else
						month = 12
						day = 31
						year = year - 1
					end
				end
			end
			return strformat("%4d-%02d-%02d", year, month, day)
		end,

		--	This is just a front for the Blizzard routine except with our special processing for our fake zones
		_GetMapNameByID = function(self, mapId)
			local retval = ""
			if 1 == mapId then
				retval = ADVENTURE_JOURNAL
			elseif GetMapNameByID then
				retval = GetMapNameByID(mapId)
			else
				-- Blizzard is removing GetMapNameByID in the 8.x release
				-- so its functionality is reproduced here with more modern
				-- API usage.
				local mapInfo = mapId and C_Map.GetMapInfo(mapId) or nil
				retval = mapInfo and mapInfo.name or ""
			end
			return retval
		end,

		---
		--	Gets the NPC ID and name of an NPC indicated using the supplied parameters.  If
		--	useMouseoverOnly is true, the only NPC checked is mouseover.  If useTargetFirst
		--	is true, the list of NPCs to check uses target first.  Normally, the list of NPCs
		--	to check just contains npc and questnpc in that order.  The first NPC in the list
		--	that returns a name is used.  The NPC ID that is returned will be modified to
		--	meet the Grail requirements, which means if the NPC is really a world object the
		--	number one million will be added to Blizzard's NPC ID.
		--	@param useTargetFirst If non-nil target is first checked in the normal list
		--	@param useMouseoverOnly If non-nil only mouseover is checked
		--	@return The NPC ID (Grail modified for world objects)
		--	@return The name of the NPC
		GetNPCId = function(self, useTargetFirst, useMouseoverOnly)
			local used
			local targetName = nil
			local npcId = nil
			local searchTable = {}
			if useMouseoverOnly then
				tinsert(searchTable, "mouseover")
			else
				if useTargetFirst then tinsert(searchTable, "target") end
				tinsert(searchTable, "npc")
				tinsert(searchTable, "questnpc")
			end
			for k, v in pairs(searchTable) do
				used = v
				targetName = UnitName(used)
				if nil ~= targetName then break end
			end
			if nil ~= targetName then
				-- UnitGUID returns a secret string on dead bodies; pcall guards against taint errors
				local ok, gid = pcall(UnitGUID, used)
				if not ok then gid = nil end
				if nil ~= gid then
					local targetType = nil
					--	Blizzard has changed the separator from : to - but we will try both if needed
					local npcBits = { strsplit("-", gid) }
					if #npcBits == 1 then
						npcBits = { strsplit(":", gid) }
					end
					if #npcBits == 3 and npcBits[1] == "Player" then
						npcId = Grail.GetCurrentMapAreaID() * -1
						targetName = "Player: " .. targetName
					end
					if #npcBits > 5 then
						npcId = npcBits[6]
						targetType = (npcBits[1] == "GameObject") and 1 or nil
					end
					if 1 == targetType then npcId = npcId + 1000000 end		-- our representation of a world object
				end
			end
			return npcId, targetName
		end,

		GetNPCInformation = function(self, npcType)
			local npcId = nil
			local name = UnitName(npcType)
			-- UnitGUID returns a secret string on dead bodies; pcall guards against taint errors
			local ok, gid = pcall(UnitGUID, npcType)
			if not ok then gid = nil end
			if nil ~= gid then
				local targetType = nil
				--	Blizzard has changed the separator from : to - but we will try both if needed
				local npcBits = { strsplit("-", gid) }
				if #npcBits == 1 then
					npcBits = { strsplit(":", gid) }
				end
				if #npcBits == 3 and npcBits[1] == "Player" then
					npcId = Grail.GetCurrentMapAreaID() * -1
					name = "Player: " .. name
				end
				if #npcBits > 5 then
					npcId = npcBits[6]
					targetType = (npcBits[1] == "GameObject") and 1 or nil
				end
				if 1 == targetType then npcId = npcId + 1000000 end		-- our representation of a world object
			end
			return npcId, name
		end,

		_GetOTCQuest = function(self, questId, npcId)
			questId = tonumber(questId)
			npcId = tonumber(npcId)
			local retval = questId
			if nil ~= questId and nil ~= self.quests[questId] and nil ~= self.quests[questId]['OTC'] then
				local sets = self.quests[questId]['OTC']
				for i = 1, #sets do
					if npcId == sets[i][1] then retval = sets[i][2] end
				end
			end
			return retval
		end,

		-- Code derived from elcius post in http://www.wowinterface.com/forums/showthread.php?t=56290
		GetPlayerMapPositionMapRects = {},
		GetPlayerMapPositionTempVec2D = CreateVector2D(0,0),
		GetPlayerMapPosition = function(unitName, optionalMapId)
			local MapID = optionalMapId or C_Map.GetBestMapForUnit(unitName)
			if not MapID or MapID < 1 then return 0, 0 end
			local R,P,_ = Grail.GetPlayerMapPositionMapRects[MapID], Grail.GetPlayerMapPositionTempVec2D
			if not R then
				R = {}
				local test
				test, R[1] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(0,0))
				if nil == test then return 0, 0 end
				_, R[2] = C_Map.GetWorldPosFromMapPos(MapID, CreateVector2D(1,1))
				R[2]:Subtract(R[1])
				Grail.GetPlayerMapPositionMapRects[MapID] = R
			end
			local x, y = UnitPosition(unitName)
			if nil == x or nil == y then return nil, nil end
			P.x = x or 0
			P.y = y or 0
			P:Subtract(R[1])
			return (1/R[2].y)*P.y, (1/R[2].x)*P.x
--	It turns out that using this code results in a memory increase because of the table returned
--	which means we cannot really use this to update a position of the player every second.  This
--	is why the code from elcius above is used instead, as there is really no memory increase.
--			local results = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit(unitName), unitName)
--			return results.x, results.y
		end,

		GetQuestGreenRange = function(self)
			local retval
			if GetQuestGreenRange then
				retval = GetQuestGreenRange()
			else
				retval = UnitQuestTrivialLevelRange("player")
			end
			if nil == retval then
				retval = 8	-- 8 is the return value from GetQuestGreenRange() for anyone level 60 or higher (at least)
			end
			return retval
		end,

		--	This is used to mask the real Blizzard API since it changes in WoD and I would prefer to have only
		--	one location where I need to mess with it.
		GetQuestLogTitle = function(self, questIndex)
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId, startEvent, displayQuestID
			local isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling
			local isWeekly = nil
            local frequency
            local questLogIndex, campaignId, difficultyLevel, isAutoComplete, overridesSortOrder, readyForTranslation
            if C_QuestLog.GetInfo then
				local info = C_QuestLog.GetInfo(questIndex)
				if info then
					questTitle = info.title
					level = info.level
					suggestedGroup = info.suggestedGroup
					isHeader = info.isHeader
					isCollapsed = info.isCollapsed
					questId = info.questID
					-- our use of isComplete is based on the old API and thus needs to be -1, 0, or 1 based on failure, not yet, and complete
					if self:IsCompleteBlizzardAPI(questId) then
						isComplete = 1
					elseif self:IsFailedBlizzardAPI(questId) then
						isComplete = -1
					else
						isComplete = 0
					end
					isDaily = (Enum.QuestFrequency.Daily == info.frequency)
					startEvent = info.startEvent
					displayQuestID = nil
					isWeekly = (Enum.QuestFrequency.Weekly == info.frequency)
					isTask = info.isTask
					isBounty = info.isBounty
					isStory = info.isStory
					isHidden = info.isHidden
					isScaling = info.isScaling
					difficultyLevel = info.difficultyLevel
				end
            else
				questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questId, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questIndex)
				isDaily = (LE_QUEST_FREQUENCY_DAILY == frequency)
				isWeekly = (LE_QUEST_FREQUENCY_WEEKLY == frequency)
			end
			questTag = nil
			return questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId, startEvent, displayQuestID, isWeekly, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel
		end,

		-- This is used to mask the real Blizzard API since it changes in Shadowlands and I would prefer to have
		-- only one location where I need to mess with it.
		GetQuestTagInfo = function(self, questId)
			local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex
			local quality, tradeskillLineID, displayExpiration
			if C_QuestLog.GetQuestTagInfo then
				local info = questId and C_QuestLog.GetQuestTagInfo(questId) or nil
				if info then
					tagID = info.tagID
					tagName = info.tagName
					worldQuestType = info.worldQuestType
					-- quality 0 = Common, 1 = Rare, 2 = Epic
					rarity = info.quality
					isElite = info.isElite
					tradeskillLineIndex = info.tradeskillLineID
				end
			else
				tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo(questId)
			end
			return tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex
		end,

		_HandleEventAchievementEarned = function(self, achievementId)
			self:_StatusCodeInvalidate(self.questStatusCache['A'][achievementId])
			self:_NPCLocationInvalidate(self.npcStatusCache['A'][achievementId])
			if self.GDE.debug then
				print("Grail Achievment handled with number: ", achievementId)
			end
			self:_AddTrackingMessage("Achievement earned: ", achievementId)
			self:_AddTrackingMessage("Coordinates earned: ", Grail:Coordinates())
		end,

		_HandleCriteriaComplete = function(self, criteriaID)
			if self.GDE.debug then
				print("Grail: Criteria earned with number: ", criteriaID)
			end
			self:_AddTrackingMessage("Criteria earned: ", criteriaID)
			self:_AddTrackingMessage("Coordinates earned: ", Grail:Coordinates())
		end,

		_HandleEventMajorFactionUnlocked = function(self, factionId)
			local message = "Major faction unlocked: " .. factionId
			if self.GDE.debug then
				print(message)
			end
			self:_AddTrackingMessage(message)
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupMajorFactionQuests])
			-- >>>VIGNETTE_DEBUG: use persistent snapshots; VIGNETTES_UPDATED may have already fired
			local _label = strformat('MAJOR_FACTION_UNLOCKED faction=%s', tostring(factionId))
			local _vigNow = self:_VignetteSnapshot()
			self:_VignetteCompareAndLog(self._persistentVigSnapshot or {}, _vigNow, _label)
			self._persistentVigSnapshot = _vigNow
			-- Store rep change and do forward vignette lookup
			self._recentlyRepChanges = self._recentlyRepChanges or {}
			local _repKey = strformat('unlock_%s_%s', tostring(factionId), tostring(GetTime()))
			self._recentlyRepChanges[_repKey] = { faction=strformat('unlock:%s', tostring(factionId)), amount=0, time=GetTime() }
			if nil ~= self._recentlyAppearedVignettes then
				local _now = GetTime()
				for _spawnUID, _vigInfo in pairs(self._recentlyAppearedVignettes) do
					if (_now - _vigInfo.time) <= 10 then
						local _ucoords = _vigInfo.coords or tostring(self:Coordinates())
						local _usrc = strformat('faction unlocked=%s | coords=%s', tostring(factionId), _ucoords)
						if self:_IsNewVignetteLink(_vigInfo.guid, _usrc, _vigInfo.name) then
							local _msg = strformat('VIGNETTE_REP_LINK (vig before unlock): vignette=%s name=%s | %s', _vigInfo.guid, tostring(_vigInfo.name), _usrc)
							print(_msg)
							self:_AddTrackingMessage(_msg)
						end
						self._recentlyAppearedVignettes[_spawnUID] = nil
						self._recentlyRepChanges[_repKey] = nil
					end
				end
			end
			-- >>>VIGNETTE_DEBUG_END
			-- >>>QUESTPIN_DEBUG
			local _pinNow = self:_QuestPinPoolSnapshot()
			self:_QuestPinCompareAndRecord(self._persistentPinSnapshot or {}, _pinNow,
				'MAJOR_FACTION_UNLOCKED', strformat('faction=%s', tostring(factionId)))
			self._persistentPinSnapshot = _pinNow
			-- >>>QUESTPIN_DEBUG_END
		end,

		_HandleEventMajorFactionRenownLevelChanged = function(self, factionId, newRenownLevel, oldRenownLevel)
			local message = "Major faction: " .. factionId .. " renown changed from " .. oldRenownLevel .. " to " .. newRenownLevel
			if self.GDE.debug then
				print(message)
			end
			self:_AddTrackingMessage(message)
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupMajorFactionQuests])
			-- >>>VIGNETTE_DEBUG: use persistent snapshots; VIGNETTES_UPDATED may have already fired
			local _label = strformat('MAJOR_FACTION_RENOWN_CHANGED faction=%s old=%s new=%s', tostring(factionId), tostring(oldRenownLevel), tostring(newRenownLevel))
			local _vigNow = self:_VignetteSnapshot()
			self:_VignetteCompareAndLog(self._persistentVigSnapshot or {}, _vigNow, _label)
			self._persistentVigSnapshot = _vigNow
			-- Store rep change and do forward vignette lookup
			self._recentlyRepChanges = self._recentlyRepChanges or {}
			local _repKey = strformat('renown_%s_%s', tostring(factionId), tostring(GetTime()))
			self._recentlyRepChanges[_repKey] = { faction=strformat('renown:%s', tostring(factionId)), amount=newRenownLevel, time=GetTime() }
			if nil ~= self._recentlyAppearedVignettes then
				local _now = GetTime()
				for _spawnUID, _vigInfo in pairs(self._recentlyAppearedVignettes) do
					if (_now - _vigInfo.time) <= 10 then
						local _rcoords = _vigInfo.coords or tostring(self:Coordinates())
						local _rsrc = strformat('renown faction=%s level=%s | coords=%s', tostring(factionId), tostring(newRenownLevel), _rcoords)
						if self:_IsNewVignetteLink(_vigInfo.guid, _rsrc, _vigInfo.name) then
							local _msg = strformat('VIGNETTE_REP_LINK (vig before renown): vignette=%s name=%s | %s', _vigInfo.guid, tostring(_vigInfo.name), _rsrc)
							print(_msg)
							self:_AddTrackingMessage(_msg)
						end
						self._recentlyAppearedVignettes[_spawnUID] = nil
						self._recentlyRepChanges[_repKey] = nil
					end
				end
			end
			-- >>>VIGNETTE_DEBUG_END
			-- >>>QUESTPIN_DEBUG
			local _pinNow = self:_QuestPinPoolSnapshot()
			self:_QuestPinCompareAndRecord(self._persistentPinSnapshot or {}, _pinNow,
				'MAJOR_FACTION_RENOWN_CHANGED', strformat('faction=%s old=%s new=%s',
					tostring(factionId), tostring(oldRenownLevel), tostring(newRenownLevel)))
			self._persistentPinSnapshot = _pinNow
			-- >>>QUESTPIN_DEBUG_END
		end,

		_HandleEventAreaPOIsUpdated = function(self)
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupAreaPOIQuests])
			-- >>>VIGNETTE_DEBUG
			-- Use persistent snapshots: state has already changed when this fires
			local _vigNow = self:_VignetteSnapshot()
			self:_VignetteCompareAndLog(self._persistentVigSnapshot or {}, _vigNow, 'AREA_POIS_UPDATED')
			self._persistentVigSnapshot = _vigNow
			-- >>>VIGNETTE_DEBUG_END
			-- >>>QUESTPIN_DEBUG: use persistent snapshot so we catch pins that appeared before this event fired
			local _pinNow = self:_QuestPinPoolSnapshot()
			self:_QuestPinCompareAndRecord(self._persistentPinSnapshot or {}, _pinNow, 'AREA_POIS_UPDATED', nil)
			self._persistentPinSnapshot = _pinNow
			-- Delayed scans: pool may be populated after event fires
			if C_Timer and C_Timer.After then
				local _self = self
				for _, delay in ipairs({1.0, 2.0}) do
					C_Timer.After(delay, function()
						local _nowPool = _self:_QuestPinPoolSnapshot()
						local _recentQuests = {}
						if _self._recentlyCompletedQuestIds then
							for q, t in pairs(_self._recentlyCompletedQuestIds) do
								if (GetTime() - t) <= 30 then table.insert(_recentQuests, tostring(q)) end
							end
						end
						local detail = #_recentQuests > 0
							and strformat('quests=%s delay=%.1fs', table.concat(_recentQuests,','), delay)
							or strformat('delay=%.1fs', delay)
						local cnt = _self:_QuestPinCompareAndRecord(_self._persistentPinSnapshot or {}, _nowPool,
							'AREA_POIS_UPDATED_DELAYED', detail)
						if cnt > 0 then
							print(strformat('QUESTPIN_AOI_DELAYED: %.1fs found=%d %s', delay, cnt, detail))
						end
						_self._persistentPinSnapshot = _nowPool
					end)
				end
			end
			-- >>>QUESTPIN_DEBUG_END
		end,

		---
		--	Scans C_QuestLog.GetQuestsOnMap() for the given map and records each quest pin
		--	position into GDE.observedQuestLocations[questID] = {mapID, x, y}.
		--	This builds a passive dataset of "where each quest giver stands" that can be
		--	used to verify or fill Grail NPC location data.  Only the most-recent
		--	observation per quest is kept; later sightings overwrite earlier ones.
		_ScanMapQuestPins = function(self, uiMapID)
			if not uiMapID then return end
			if nil == self.GDE.observedQuestLocations then
				self.GDE.observedQuestLocations = {}
			end
			local locs = self.GDE.observedQuestLocations
			-- Standard offer pins
			local pins = C_QuestLog.GetQuestsOnMap(uiMapID)
			if pins then
				for _, pin in ipairs(pins) do
					local questID = tonumber(pin.questID)
					if questID then
						locs[questID] = {mapID = uiMapID, x = pin.x, y = pin.y}
						self:_LearnKCodesForQuest(questID)
					end
				end
			end
			-- Hub child quests (e.g. weekly quests inside QuestHub pins)
			if WorldMapFrame and WorldMapFrame.pinPools then
				local hubPool = WorldMapFrame.pinPools['QuestHubPinTemplate']
				if hubPool then
					local hubPins = {}
					pcall(function() for pin in hubPool:EnumerateActive() do table.insert(hubPins, pin) end end)
					for _, hpin in ipairs(hubPins) do
						if hpin.dataProvider and hpin.dataProvider.questOffers then
							for qid, qinfo in pairs(hpin.dataProvider.questOffers) do
								local questID = tonumber(qid)
								if questID then
									locs[questID] = {mapID = uiMapID, x = qinfo.x, y = qinfo.y}
									self:_LearnKCodesForQuest(questID)
								end
							end
						end
					end
				end
			end
			-- >>>QUESTPIN_DEBUG: update persistent pin snapshot (pool-only) when map is scanned
			self._persistentPinSnapshot = self:_QuestPinPoolSnapshot()
			-- >>>QUESTPIN_DEBUG_END
		end,

		_HandleEventGarrisonBuildingActivated = function(self, buildingId)
			if nil ~= self.questStatusCache then
				self:_StatusCodeInvalidate(self.questStatusCache.M[buildingId])
			end
		end,

		_HandleEventGarrisonBuildingUpdate = function(self, buildingId)
			if nil ~= self.questStatusCache then
				self:_StatusCodeInvalidate(self.questStatusCache.M[buildingId])
			end
		end,

		_HandleEventCombatTextUpdate = function(self, type, arg1, arg2)
			-- COMBAT_TEXT_UPDATE type=FACTION fires with nil args for Warband rep — not useful.
			-- All rep capture is handled via CHAT_MSG_COMBAT_FACTION_CHANGE instead.
		end,

		_HandleEventChatMsgCombatFactionChange = function(self, message)
			if nil ~= self.questStatusCache then
				self:_StatusCodeInvalidate(self.questStatusCache["R"])
				self.questStatusCache["R"] = {}
				self:_NPCLocationInvalidate(self.npcStatusCache["R"])
			end
			-- Capture rep changes for quest-turn-in learning.  Event ordering varies:
			--   Traditional rep:    fires before QUEST_TURNED_IN → buffer in pendingRepChanges
			--   Warband/Midnight:   fires after  QUEST_TURNED_IN → questTurningIn is already set
			local factionName, amount = self:_ParseFactionChangeMessage(message)
			if nil ~= factionName and nil ~= amount then
				if nil ~= self.questTurningIn then
					self:_LearnQuestReputation(self.questTurningIn, self:_ResolveFactionId(factionName), amount)
				else
					self.pendingRepChanges = self.pendingRepChanges or {}
					tinsert(self.pendingRepChanges, { factionName = factionName, amount = amount, time = GetTime() })
				end
				-- >>>VIGNETTE_DEBUG: store rep change for vignette correlation
				self._recentlyRepChanges = self._recentlyRepChanges or {}
				local repKey = strformat('%s_%s', tostring(factionName), tostring(GetTime()))
				self._recentlyRepChanges[repKey] = { faction=factionName, amount=amount, time=GetTime() }
				-- Forward lookup: vignette appeared before this rep event fired
				if nil ~= self._recentlyAppearedVignettes then
					local now = GetTime()
					local repLinked = false
					for spawnUID, vigInfo in pairs(self._recentlyAppearedVignettes) do
						if (now - vigInfo.time) <= 10 then
							local _coords = vigInfo.coords or tostring(self:Coordinates())
							local _src = strformat('rep=%s+%s | coords=%s', tostring(factionName), tostring(amount), _coords)
							if self:_IsNewVignetteLink(vigInfo.guid, _src, vigInfo.name) then
								local msg = strformat('VIGNETTE_REP_LINK (vig before rep): vignette=%s name=%s | %s', vigInfo.guid, tostring(vigInfo.name), _src)
								print(msg)
								self:_AddTrackingMessage(msg)
							end
							self._recentlyAppearedVignettes[spawnUID] = nil
							repLinked = true
						end
					end
					if repLinked then self._recentlyRepChanges[repKey] = nil end
				end
				-- >>>VIGNETTE_DEBUG_END
			end
		end,

		---
		--	Warband/account-wide reputation message patterns, keyed by WoW locale string.
		--	WoW provides no global format string for these messages, so patterns are stored
		--	here per locale.  To add a new locale, add one entry:
		--	  deDE = { gain = "...", loss = "..." },
		--	where capture 1 = faction name and capture 2 = amount (always a positive integer).
		--	Unknown locales fall back to enUS.
		--
		---
		--	Resolves a localized faction name to a 3-digit uppercase hex faction ID string,
		--	matching the format used throughout Grail's reputation data (e.g. "A90" for 2704).
		--	Resolution order:
		--	  1. reverseReputationMapping  — pre-built from Grail's existing reputation data
		--	  2. C_Reputation / GetFactionInfo scan — live WoW panel, covers factions not yet in Grail data
		--	  3. "N:<name>" fallback        — preserves the name for later manual resolution
		--
		_ResolveFactionId = function(self, factionName)
			local hexId = self.reverseReputationMapping[factionName]
			if nil ~= hexId then return hexId end

			if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
				for i = 1, C_Reputation.GetNumFactions() do
					local info = C_Reputation.GetFactionDataByIndex(i)
					if info and info.name == factionName and info.factionID and info.factionID > 0 then
						return self:_HexValue(info.factionID, 3)
					end
				end
			elseif GetNumFactions and GetFactionInfo then
				for i = 1, GetNumFactions() do
					local name, _, _, _, _, _, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
					if name == factionName and factionID and factionID > 0 then
						return self:_HexValue(factionID, 3)
					end
				end
			end

			return 'N:' .. factionName
		end,

		warbandRepPatterns = {
			enUS = {
				gain = "Your Warband's reputation with (.+) increased by (%d+)%.",
				loss = "Your Warband's reputation with (.+) decreased by (%d+)%.",
			},
			deDE = {
				gain = "Der Ruf der Kriegsmeute bei der Fraktion '(.+)' hat sich um (%d+) verbessert%.",
				loss = "Der Ruf der Kriegsmeute bei der Fraktion '(.+)' hat sich um (%d+) verschlechtert%.",
			},
			frFR = {
				gain = "Réputation de votre bataillon auprès de la faction (.+) augmentée de (%d+)%.",
				loss = "Réputation de votre bataillon auprès de la faction (.+) diminuée de (%d+)%.",
			},
			esMX = {
				gain = "La reputación de tu tropa con (.+) ha aumentado (%d+) p%.",
				loss = "La reputación de tu tropa con (.+) ha disminuido (%d+) p%.",	-- loss inferred
			},
			ptBR = {
				gain = "A Reputação do seu Bando de Guerra com (.+) aumentou em (%d+)%.",
				loss = "A Reputação do seu Bando de Guerra com (.+) diminuiu em (%d+)%.",	-- loss inferred
			},
			koKR = {
				gain = "(.+)에 대한 전투부대의 평판이 (%d+)만큼 상승했습니다%.",
				loss = "(.+)에 대한 전투부대의 평판이 (%d+)만큼 감소했습니다%.",	-- loss inferred
			},
			zhTW = {
				gain = "戰隊的(.+)聲望提高(%d+)點。",
				loss = "戰隊的(.+)聲望降低(%d+)點。",	-- loss inferred
			},
			zhCN = {
				gain = "你的战团在(.+)中的声望值提高了(%d+)点。",
				loss = "你的战团在(.+)中的声望值降低了(%d+)点。",	-- loss inferred
			},
			esES = {
				gain = "La reputación de tu banda guerrera con la facción (.+) ha aumentado (%d+) p%.",
				loss = "La reputación de tu banda guerrera con la facción (.+) ha disminuido (%d+) p%.",	-- loss inferred
			},
			itIT = {
				gain = "La reputazione della Brigata con \"(.+)\" è aumentata di (%d+)%.",
				loss = "La reputazione della Brigata con \"(.+)\" è diminuita di (%d+)%.",	-- loss inferred
			},
			ruRU = {
				gain = "Отношение (.+) к вашему отряду улучшилось на (%d+)%.",
				loss = "Отношение (.+) к вашему отряду ухудшилось на (%d+)%.",	-- loss inferred
			},
		},

		---
		--	Parses a CHAT_MSG_COMBAT_FACTION_CHANGE message and returns the faction name
		--	and the signed rep change amount (positive = gain, negative = loss).
		--	Uses WoW global format strings for standard rep and the warbandRepPatterns
		--	table for Warband/account-wide rep.  Returns nil, nil on no match.
		--
		_ParseFactionChangeMessage = function(self, message)
			if nil == message then return nil, nil end
			local function fmtToPattern(fmt)
				local p = fmt:gsub("%(", "%%("):gsub("%)", "%%)")
				p = p:gsub("%%s", "(.+)")
				p = p:gsub("%%d", "(%%d+)")
				return p
			end

			-- Standard rep gain/loss — WoW global strings (locale-independent).
			if FACTION_STANDING_INCREASED then
				local name, amtStr = strmatch(message, fmtToPattern(FACTION_STANDING_INCREASED))
				if nil ~= name then return name, tonumber(amtStr) end
			end
			if FACTION_STANDING_DECREASED then
				local name, amtStr = strmatch(message, fmtToPattern(FACTION_STANDING_DECREASED))
				if nil ~= name then return name, -tonumber(amtStr) end
			end

			-- Warband/account-wide rep — no WoW global exists; use per-locale pattern table.
			local locale = GetLocale()
			local wp = self.warbandRepPatterns[locale] or self.warbandRepPatterns["enUS"]
			if wp then
				local name, amtStr = strmatch(message, wp.gain)
				if nil ~= name then return name, tonumber(amtStr) end
				local name2, amtStr2 = strmatch(message, wp.loss)
				if nil ~= name2 then return name2, -tonumber(amtStr2) end
			end

			return nil, nil
		end,

		_HandleEventChatMsgSkill = function(self)
			if nil ~= self.questStatusCache then
				self:_StatusCodeInvalidate(self.questStatusCache["P"])
				self.questStatusCache["P"] = {}
				self:_NPCLocationInvalidate(self.npcStatusCache["P"])
			end
		end,

		_HandleEventLootClosed = function(self)
			-- Since querying the server is a little noisy we force it to be less so, reseting values later
			local silentValue, manualValue = self.GDE.silent, self.manuallyExecutingServerQuery
			self.GDE.silent, self.manuallyExecutingServerQuery = true, false
			-- >>>VIGNETTE_DEBUG
			local _vigSnapBeforeLoot = self:_VignetteSnapshot()
			-- >>>VIGNETTE_DEBUG_END
-- The old way of doing this was to query all the quests that were completed and see how they differ from the currently completed
-- list and then assume the newly completed one(s) are associated with the treasure.  However, that is a little expensive.  Thus,
-- only the treasure quests associated with the current zone are queried to see if there is any change in their status.
			local newlyCompleted = {}
			-- We now support a value that controls using the old code versus the new because getting the initial treasure values
			-- is a lot easier with the old code.
			if Grail.GDE.treasures then
				QueryQuestsCompleted()
				self:_ProcessServerCompare(newlyCompleted)
			else
-- This is the new code that handles only checking specific values...
				local mapId = Grail.GetCurrentMapAreaID()
				local listOfTreasureQuestsInThisMap = self.mapAreasWithTreasures[mapId]
				if nil ~= listOfTreasureQuestsInThisMap then
					for k,v in pairs(listOfTreasureQuestsInThisMap) do
						-- the first is server call, and the second is Grail database
						if self:IsQuestFlaggedCompleted(v) and not self:IsQuestCompleted(v) then
							tinsert(newlyCompleted, v)
						end
					end
				end
			end
-- And back to the original code...
			if #newlyCompleted > 0 or Grail.GDE.debug then
				local lootingNameToUse = self.lootingName or "NO LOOTING OBJECT"
				local guidParts = { strsplit('-', self.lootingGUID or "") }
				if nil ~= guidParts and guidParts[1] == "GameObject" and self.lootingName ~= self.defaultUnfoundLootingName then
					local internalName = self:ObjectName(guidParts[6])
					if self.lootingName ~= internalName then
						self:_LearnObjectName(guidParts[6], lootingNameToUse)
					end
				end
				local message = "Looting from " .. (self.lootingGUID or "NO LOOTING GUID") .. " locale: " .. self.playerLocale .. " name: " .. lootingNameToUse .. " Coords: " .. Grail:Coordinates()
				if message ~= self._lastLootingMessage then
					self._lastLootingMessage = message
					if self.GDE.debug then
						print(message)
					end
					self:_AddTrackingMessage(message)
				end
			end
			for _, questId in pairs(newlyCompleted) do
				self:_MarkQuestComplete(questId, true)
			end
			self:_ProcessServerBackup(true)
			-- >>>VIGNETTE_DEBUG
			self:_VignetteCompareAndLog(_vigSnapBeforeLoot, self:_VignetteSnapshot(),
				strformat('LOOT_CLOSED guid=%s', tostring(self.lootingGUID)))
			-- Correlate disappeared vignettes with this creature and its completed quests
			if nil ~= self._recentlyDisappearedVignettes and nil ~= self.lootingGUID then
				local lootSpawnUID = select(7, strsplit('-', self.lootingGUID))
				local lootNpcId    = select(6, strsplit('-', self.lootingGUID))
				local vigInfo = lootSpawnUID and self._recentlyDisappearedVignettes[lootSpawnUID]
				if nil ~= vigInfo then
					local questList = {}
					for _, qId in pairs(newlyCompleted) do
						table.insert(questList, tostring(qId))
					end
					-- Also include recently completed quests (may have been detected before loot)
					if #questList == 0 and nil ~= self._recentlyCompletedQuestIds then
						local now = GetTime()
						for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
							if (now - qTime) <= 30 then table.insert(questList, tostring(qId)) end
						end
					end
					local questStr = #questList > 0 and table.concat(questList, ',') or 'none'
					local coords = Grail:Coordinates()
					local _lootSrc = strformat('npcId=%s | quests=%s | coords=%s', tostring(lootNpcId), questStr, tostring(coords))
					if self:_IsNewVignetteLink(vigInfo.guid, _lootSrc, vigInfo.name) then
						local msg = strformat(
							'VIGNETTE_QUEST_LINK: vignette=%s name=%s | npcId=%s | quests=%s | coords=%s',
							vigInfo.guid, tostring(vigInfo.name), tostring(lootNpcId), questStr, tostring(coords))
						print(msg)
						self:_AddTrackingMessage(msg)
					end
					self._recentlyDisappearedVignettes[lootSpawnUID] = nil
				end
				-- No vignette match: log NPC+quest link directly from loot info
				if nil == vigInfo and #newlyCompleted > 0 then
					local questList = {}
					for _, qId in pairs(newlyCompleted) do table.insert(questList, tostring(qId)) end
					local coords = Grail:Coordinates()
					local _src = strformat('npcId=%s | quests=%s | coords=%s',
						tostring(lootNpcId), table.concat(questList, ','), tostring(coords))
					local _syntheticGuid = strformat('Loot-%s', tostring(lootNpcId))
					if self:_IsNewVignetteLink(_syntheticGuid, _src, self.lootingName) then
						local msg = strformat('LOOT_QUEST_LINK: npcId=%s name=%s | quests=%s | coords=%s',
							tostring(lootNpcId), tostring(self.lootingName), table.concat(questList, ','), tostring(coords))
						print(msg)
						self:_AddTrackingMessage(msg)
					end
				end
			end
			-- >>>VIGNETTE_DEBUG_END
			self.GDE.silent, self.manuallyExecutingServerQuery = silentValue, manualValue
		end,

		_HandleEventPlayerLevelUp = function(self)
			-- >>>QUESTPIN_DEBUG
			local _pinBefore = self:_QuestPinPoolSnapshot()
			-- >>>QUESTPIN_DEBUG_END
			if nil ~= self.questStatusCache then
				self:_StatusCodeInvalidate(self.questStatusCache["L"])
				self.questStatusCache["L"] = {}
				self:_StatusCodeInvalidate(self.questStatusCache["V"])
				self.questStatusCache["V"] = {}
			end
			if self.GDE.debug then
				self:_PostDelayedNotification("PlayerLevelUp", self.levelingLevel, 1.0)
			end
			-- >>>QUESTPIN_DEBUG
			self:_QuestPinCompareAndRecord(_pinBefore, self:_QuestPinPoolSnapshot(),
				'PLAYER_LEVEL_UP', strformat('level=%s', tostring(self.levelingLevel)))
			-- >>>QUESTPIN_DEBUG_END
		end,

		_HandleEventSkillLinesChanged = function(self)
			for spellId in pairs(self.questStatusCache['S']) do
				self:_StatusCodeInvalidate(self.questStatusCache['S'][spellId])
			end
		end,

		_HandleEventUnitQuestLogChanged = function(self)
			-- Get all the quests in the Blizzard quest log and invalidate their status cache values if they have changed with regard to completed/failed
			self.cachedQuestsInLog = nil	-- First clear the cache of our quests in the log
			local questsToInvalidate = {}
			local quests = self:_QuestsInLog()
			local bitsToCheckAgainst = self.bitMaskInLog + self.bitMaskInLogComplete + self.bitMaskInLogFailed
			for questId, t in pairs(quests) do
				local cachedStatus = self.questStatuses[questId]
--				local cachedStatus = self.quests[questId] and self.quests[questId][7] or nil
--				local cachedStatus = self.questBits[questId] and self:_IntegerFromStringPosition(self.questBits[questId], 2) or nil
				if nil ~= cachedStatus then
					local soughtBitMask = self.bitMaskInLog
					local foundComplete = false
					if t[2] then
						if t[2] > 0 then soughtBitMask = soughtBitMask + self.bitMaskInLogComplete foundComplete = true end
						if t[2] < 0 then soughtBitMask = soughtBitMask + self.bitMaskInLogFailed end
					end
					if bitband(cachedStatus, bitsToCheckAgainst) ~= soughtBitMask then
						tinsert(questsToInvalidate, questId)
						if foundComplete then
							local occCodes = (self.quests[questId] and self.quests[questId]['OCC'])
							if nil ~= occCodes then
								for i = 1, #occCodes do
									self:_MarkQuestComplete(occCodes[i], true, false, false)
									tinsert(questsToInvalidate, occCodes[i])
								end
							end
						end
					end
				end
			end
			self:_StatusCodeInvalidate(questsToInvalidate)
		end,

		_HandleEventUpdateExpansionLevel = function(self, unk1, unk2, oldExpansion, unk3, upgFromExpTrial)
			local message = "UpdateExpansionLevel: ~currentExpansionLevel~+unk1:" .. unk1 .. "~currentAccountExpansionLevel~unk2:" .. unk2 .. " from oldExpansion " .. oldExpansion .. "~previousAccountExpansionLevel~unk3:" .. unk3 .. "upgFromExpTrial:" .. upgFromExpTrial
			if self.GDE.debug then
				print(message)
			end
				self:_AddTrackingMessage(message)
		end,

		_HandleMinExpansionLevelUpdated = function(self)
			local message = "MinEpansionLevel updated: ael:" .. self.accountExpansionLevel .. " el:" .. self.expansionLevel .. " cEL:" .. self.classicExpansionLevel .. " sEL:" .. self.serverExpansionLevel
				self:_AddTrackingMessage(message)
			if self.GDE.debug then
				print(message)
			end
		end,

		_HandleMaxExpansionLevelUpdated = function(self)
			local message = "MaxEpansionLevel updated: ael:" .. self.accountExpansionLevel .. " el:" .. self.expansionLevel .. " cEL:" .. self.classicExpansionLevel .. " sEL:" .. self.serverExpansionLevel
			if self.GDE.debug then
				print(message)
			end
			self:_AddTrackingMessage(message)
		end,

		---
		--	Checks whether the garrison has the specific buildingId, where a negative buildingId will mean
		--	check whether any building of that type exists.
		HasGarrisonBuilding = function(self, buildingId, ignoreIsBuildingRequirement)
			local desiredBuildingTable = nil
			local retval = false
			local buildings = (self.blizzardRelease >= 22248) and C_Garrison.GetBuildings(self.garrisonType6) or C_Garrison.GetBuildings()
			local building
			local id, name, texPrefix, icon, rank, isBuilding, timeStart, buildTime, canActivate, canUpgrade, planExists
			local foundPlot, foundBuildingId

			--	Because the return value of C_Garrison.GetBuildingInfo() seems to change based on whether the
			--	character has been to the garrison already during the playing session, we cannot guarantee
			--	the 14th return value will be present, so we use our own mapping of negative numbers to the
			--	possible buildings.  This also allows us to specify the negative number of the level two
			--	building which means level two or three is acceptable.
			if buildingId < 0 then
				desiredBuildingTable = self.garrisonBuildingMapping[buildingId]
--				desiredBuildingTable = select(14, C_Garrison.GetBuildingInfo(-1 * buildingId))
			end
			if nil == desiredBuildingTable then
				desiredBuildingTable = { buildingId }
			end
			for i = 1, #buildings do
				building = buildings[i]
				if tContains(desiredBuildingTable, building.buildingID) then
					id, name, texPrefix, icon, rank, isBuilding, timeStart, buildTime, canActivate, canUpgrade, planExists = C_Garrison.GetOwnedBuildingInfoAbbrev(building.plotID)
					foundPlot = building.plotID
					foundBuildingId = building.buildingID
					if not isBuilding then retval = true break end
				end
			end
			return retval, name, rank, foundPlot, foundBuildingId
		end,

		HasGarrisonBuildingInPlot = function(self, buildingId, plotId)
			local retval, name, rank, foundPlot, foundBuildingId = self:HasGarrisonBuilding(buildingId)
			if retval then
				if foundPlot ~= plotId then
					retval = false
				end
			end
			return retval, name, rank, foundPlot, foundBuildingId
		end,

		HasGarrisonBuildingNPCWorking = function(self, buildingId)
			local npcName = nil
			local retval, name, rank, foundPlot, foundBuildingId = self:HasGarrisonBuilding(buildingId)
			if retval then
				npcName = C_Garrison.GetFollowerInfoForBuilding(foundPlot)
				if nil == npcName then
					retval = false
				end
			end
			return retval, npcName
		end,

		---
		--	Indicates whether the character has ever abandoned the specified quest.  This information is only valid
		--	as long as Grail has been used to record this information.  This information cannot be known prior to
		--	Grail being used.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest has been marked abandoned at any time, otherwise false
		HasQuestEverBeenAbandoned = function(self, questId)
			return self:_IsQuestMarkedInDatabase(questId, GrailDatabasePlayer["abandonedQuests"])
		end,

		---
		--	Indicates whether the character has ever accepted the specified quest.  This information is only valid
		--	as long as Grail has been used to record this information.  This information cannot be known perfectly
		--	prior to Grail being used.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest has been accepted at any time, otherwise false
		HasQuestEverBeenAccepted = function(self, questId)
			return self:HasQuestEverBeenAbandoned(questId) or self:HasQuestEverBeenCompleted(questId) or self:IsQuestInQuestLog(questId)
		end,

		---
		--	Indicates whether the character has ever completed the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest has been marked complete, or if the quest has been completed and is one that Blizzard resets daily/weekly/yearly, otherwise false
		HasQuestEverBeenCompleted = function(self, questId)
			return self:IsQuestCompleted(questId) or self:IsResettableQuestCompleted(questId)
		end,

		_HasSkill = function(self, desiredSkillId)
			local retval = nil
			if nil ~= desiredSkillId then
				if desiredSkillId > 200000000 then		-- dealing with a pet that is summoned
					local numPets, numOwned = C_PetJournal.GetNumPets()
					for i = 1, numOwned do
						local _, speciesId, owned, _, _, _, _, speciesName, _, _, companionId = C_PetJournal.GetPetInfoByIndex(i)
						if owned and desiredSkillId == 200000000 + companionId then
							retval = true
						end
					end
				else
					if GetSpellBookItemInfo then
						-- name, texture, offset, numSlots, isGuild, offspecID
						local _, _, _, numberSpells1 = self:GetSpellTabInfo(1)
						local _, _, _, numberSpells2 = self:GetSpellTabInfo(2)
						for i = 1, numberSpells1 + numberSpells2, 1 do
							local spellType, spellId = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
							if spellId and desiredSkillId == spellId and spellType == "SPELL" then
								retval = true
							end
						end
					else
						-- Blizzard has transitioned from GetSpellBookItemInfo to more modern API
						for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
							local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
							local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
							for j = offset + 1, offset + numSlots do
								local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
								-- ID must match and type must not be .FutureSpell because that means you do not have it yet
								if desiredSkillId == spellBookItemInfo.actionID and spellBookItemInfo.itemType == Enum.SpellBookItemType.Spell then
									retval = true
								end
							end
						end
					end
				end
			end
			return retval
		end,

		--	This turns a number into its hexidecimal equivalent.
		--	@param aNumber The integer to convert to hexidecimal
		--	@param minDigits An optional minimum number of hexidecimal digits to return, 0 padding at front
		--	@return A hexidecimal string representing the provided integer
		_HexValue = function(self, aNumber, minDigits)
			local codes = "0123456789ABCDEF"
			local retval = ""
			local position
			while aNumber > 0 do
				aNumber, position = floor(aNumber / 16), mod(aNumber, 16) + 1
				retval = strsub(codes, position, position) .. retval
			end
			if nil ~= minDigits then
				while (strlen(retval) < minDigits) do
					retval = '0' .. retval
				end
			end
			return retval
		end,

		--	Checks to see whether the player's current equipped iLvl matches
		_iLvlMatches = function(self, typeOfMatch, soughtNumber)
			local retval = false
			local iLvl, equippedILvl = GetAverageItemLevel()
			if 'Q' == typeOfMatch and equippedILvl >= soughtNumber then retval = true end
			if 'q' == typeOfMatch and equippedILvl < soughtNumber then retval = true end
			return retval
		end,

		_InsertSet = function(self, table, index, value)
			local t = table[index] or {}
			if not tContains(t, value) then
				t[#t + 1] = value
			end
			table[index] = t
		end,

		InsertSet = function(self, table, value)
			if not tContains(table, value) then
				tinsert(table, value)
			end
		end,

		---
		--	Indicates whether the character is in a heroic instance with the specified NPC.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return true if the character is in a heroic instance where the NPC is located, otherwise false
		InWithHeroicNPC = function(self, npcId)
			local retval = false
			local isHeroic, instanceName = self:IsInHeroicInstance()
			if isHeroic then
				local locations = self:NPCLocations(npcId, false, false, true)	-- only return things that match the current map area
				if nil ~= locations and 0 < #(locations) then
					retval = true
				end
			end
			return retval
		end,

		---
		--	Indicates whether the quest is an account-wide quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is an account-wide quest, otherwise false
		IsAccountWide = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestAccountWide) > 0)
		end,

		---
		--	Indicates whether the world quest is currently available.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the world quest is currently available, otherwise false
		IsAvailable = function(self, questId)
--			return (nil ~= self.availableWorldQuests[questId])
			return tContains(self.invalidateControl[self.invalidateGroupCurrentWorldQuests], questId) or tContains(self.invalidateControl[self.invalidateGroupCurrentThreatQuests], questId) or tContains(self.invalidateControl[self.invalidateGroupCurrentCallingQuests], questId)
		end,

		---
		--	Indicates whether the quest is a bonus objective quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a bonus objective quest, otherwise false
		IsBonusObjective = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestBonus) > 0)
		end,

		---
		--	Indicated whether Grail thinks the quest is bugged, meaning it cannot be completed
		--	because of a Blizzard server problem.
		--	@param questId The standard numeric questId representing a quest.
		--	@return nil if the quest is not bugged, otherwise a string describing the problem.
		IsBugged = function(self, questId)
--			return self:_QuestGenericAccess(questId, 'bugged')
			questId = tonumber(questId)
			return questId and self.buggedQuests[questId] or nil
		end,

		---
		--	Indicates whether the quest is a daily quest as indicated by the internal database.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a daily quest, otherwise false
		IsDaily = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestDaily) > 0)
		end,

		---
		--	Indicates whether the quest is a dungeon quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a dungeon quest, otherwise false
		IsDungeon = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestDungeon) > 0)
		end,

		---
		--	Indicates whether the quest is an escort quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is an escort quest, otherwise false
		IsEscort = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestEscort) > 0)
		end,

		---
		--	Indicates whether the quest is a group quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a group quest, otherwise false
		IsGroup = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestGroup) > 0)
		end,

		---
		--	Indicates whether the quest is a heroic quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a heroic quest, otherwise false
		IsHeroic = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestHeroic) > 0)
		end,

		---
		--	Indicates whether the NPC is only to be found in heroic instances.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return True if the NPC is only found in heroic instances, false otherwise.
		IsHeroicNPC = function(self, npcId)
			local retval = false
			npcId = tonumber(npcId)
			if nil ~= npcId then
				retval = self.npc.heroic[npcId]
			end
			return retval
		end,

		---
		--	Indicates whether the character is in a heroic instance.
		--	@return true if the character is in a heroic instance, otherwise false
		--	@return the name of the instance the character is in
		--	@usage isHeroic, instanceName = Grail:IsInHeroicInstance()
		IsInHeroicInstance = function(self)
			local retval = false
			local name, type, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID, instanceGroupSize = GetInstanceInfo()
			if "none" ~= type then
				if 3 == difficultyIndex or 4 == difficultyIndex or (2 == difficultyIndex and "raid" ~= type) then
					retval = true
				end
			end
			return retval, name, mapID
		end,

		IsInInstance = function(self)
			local retval = false
			local name, type, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID, instanceGroupSize = GetInstanceInfo()
			if "none" ~= type then
				retval = true
			end
			return retval, name, mapID
		end,

		---
		--	Indicates whether the quest is invalidated (meaning it cannot be accepted based on other completed quests or those in the quest log).
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest cannot be accepted because of a quest in the log or one already completed, false otherwise.
		--	@return A table of failure reasons, or nil if there are none.
		IsInvalidated = function(self, questId, ignoreBreadcrumb)
			local retval = false
			local any, present, failures = self:_AnyEvaluateTrue(questId, "I")
			if present then
				retval = any
			end

			if not retval and not ignoreBreadcrumb then

				-- Check to see whether this quest is a breadcrumb quest for something that is already completed or in the quest log.

				any, present, failures = self:_AnyEvaluateTrue(questId, "B")
				if present then retval = any end

			end

			if not retval then

				-- Examine the P codes to determine if any of them require the presence in the log.  If there is a code that does
				-- not, then we are ok.  If the only P codes require in the log presence check the status of those quests.  If they
				-- are unobtainable or already completed (turned in) then this quest is invalidated.

				local prerequisites = self:QuestPrerequisites(questId, true)

				if nil ~= prerequisites then
					any, present, failures = self:_AnyEvaluateTrueF(prerequisites, nil, Grail._EvaluateCodeAsNotInLogImpossible)
					if present and not any then retval = true end
				end
			end

			--	If the quest does not meet prerequisites check to see whether the quest has prerequisites that cannot be met and
			--	so the quest should be marked as invalidated because of this.
			if not retval and not self:MeetsPrerequisites(questId) then
				local prerequisites = self:QuestPrerequisites(questId, true)
				local anyEvaluateTrue, requirementPresent, allFailures = self:_AnyEvaluateTrueF(prerequisites, { q = questId }, Grail._EvaluateCodeDoesNotFailQuestStatus)
				if requirementPresent then retval = not anyEvaluateTrue end
			end

			-- Check to see if this quest is part of a group and whether that group has reached its maximum quest and whether the
			-- quest is not already part of the accepted from that group for today.
			if not retval then
				if self.questStatusCache.H[questId] then
					local dailyDay = self:_GetDailyDay()
					for _, group in pairs(self.questStatusCache.H[questId]) do
						if self:_RecordGroupValueChange(group, false, false, questId) >= self.dailyMaximums[group] then
							if not tContains(GrailDatabasePlayer["dailyGroups"][dailyDay][group], questId) then
								retval = true
							end
						end
					end
				end
			end
			-- Now do the check for weekly quests too...
			if not retval then
				if self.questStatusCache.K[questId] then
					local weeklyDay = self:_GetWeeklyDay()
					for _, group in pairs(self.questStatusCache.K[questId]) do
						if self:_RecordGroupValueChange(group, false, false, questId, true) >= self.weeklyMaximums[group] then
							if not tContains(GrailDatabasePlayer["weeklyGroups"][weeklyDay][group], questId) then
						 		retval = true
							end
						end
					end
				end
			end

			return retval, failures
		end,

		---
		--	Indicates whether the quest is a legendary quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a legendary quest, otherwise false
		IsLegendary = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestLegendary) > 0)
		end,

		---
		--	Returns whether the quest is a low level quest in comparison to the specified level
		--	or that of the player if none specified.
		--	@param questId The standard numeric questId representing a quest.
		--	@param comparisonLevel The level used to make a comparison against the quest level.
		--	@return True if the comparisonLevel (or player level) is more than the quest's level plus Blizzard's green range comparison
		IsLowLevel = function(self, questId, comparisonLevel)
			local retval = false
			comparisonLevel = tonumber(comparisonLevel) or UnitLevel("player")
			local questLevel = self:QuestLevel(questId) or 1
			if 0 ~= questLevel then		-- 0 is the special marker indicating the quest is actually the same level as the player
				local possibleVariableQuestLevel = self:QuestLevelVariableMax(questId)
				if possibleVariableQuestLevel > questLevel then
					questLevel = possibleVariableQuestLevel
				end
				retval = (comparisonLevel > (questLevel + self:GetQuestGreenRange()))
			end
			return retval
		end,

		---
		--	Indicates whether the quest is a monthly quest as indicated by the internal database.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a monthly quest, otherwise false
		IsMonthly = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestMonthly) > 0)
		end,

		---
		--	Returns whether the NPC should be available to the character.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return True if the NPC is available based on holidays currently celebrated and presence in a heroic instance, false otherwise.
		IsNPCAvailable = function(self, npcId)
			local retval = false
			npcId = tonumber(npcId)
			if nil ~= npcId then
				retval = true
				local codes = self.npc.holiday[npcId]
				if nil ~= codes then
					retval = false	-- Assume we fail all holidays unless proven otherwise
					for i = 1, strlen(codes) do
						if not retval then
							retval = self:CelebratingHoliday(self.holidayMapping[strsub(codes, i, i)])
						end
					end
				end
				if retval and self:IsHeroicNPC(npcId) then
					retval = self:InWithHeroicNPC(npcId)
				end
			end
			return retval
		end,

		---
		--	Indicates whether the quest is a pet battle quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a pet battle quest, otherwise false
		IsPetBattle = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestPetBattle) > 0)
		end,

		---
		--	Returns whether Grail is ready to properly respond to status information about quests.
		IsPrimed = function(self)
			local retval = true
			if retval and self.capabilities.usesCalendar then
				retval = self.receivedCalendarUpdateEventList
			end
			if retval then
				retval = self.receivedQuestLogUpdate
			end
			return retval
		end,

		---
		--	Indicates whether the quest is a PVP quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a PVP quest, otherwise false
		IsPVP = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestPVP) > 0)
		end,

		---
		--	Returns whether the quest is considered completed.
		--	Note that certain types of quests can be reset (e.g., dailies) and when they are, this routine will return false.  These types of
		--	quests can be completed and this routine will return true until they are once again reset.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is completed, false otherwise.
		--	@see HasQuestEverBeenCompleted
		--	@see IsResettableQuestCompleted
		IsQuestCompleted = function(self, questId)
			return self:_IsQuestMarkedInDatabase(questId)
		end,

		IsCompleteBlizzardAPI = function(self, questId)
			-- it has to be in the quest log and complete (meaning ready for turnin)
			if C_QuestLog.IsComplete then
				return C_QuestLog.IsComplete(questId)
			elseif IsQuestComplete then
				return IsQuestComplete(questId)
			else
				return false
			end
		end,

		IsFailedBlizzardAPI = function(self, questId)
			if C_QuestLog.IsFailed then
				return C_QuestLog.IsFailed(questId)
			else
				return false
			end
		end,

		-- think about adding BlizzardAPI to the end of the function name
		IsQuestFlaggedCompletedOnAccount = function(self, questId)
			if C_QuestLog.IsQuestFlaggedCompletedOnAccount then
				return C_QuestLog.IsQuestFlaggedCompletedOnAccount(questId)
			else
				return false
			end
		end,

		IsRepeatableQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsRepeatableQuest then
				return C_QuestLog.IsRepeatableQuest(questId)
			else
				return false
			end
		end,

		IsImportantQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsImportantQuest then
				return C_QuestLog.IsImportantQuest(questId)
			else
				return false
			end
		end,
		
		IsAccountQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsAccountQuest then
				return C_QuestLog.IsAccountQuest(questId)
			else
				return false
			end
		end,
		
		IsLegendaryQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsLegendaryQuest then
				return C_QuestLog.IsLegendaryQuest(questId)
			else
				return false
			end
		end,
		
		IsMetaQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsMetaQuest then
				return C_QuestLog.IsMetaQuest(questId)
			else
				return false
			end
		end,
		
		IsOnQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsOnQuest then
				return C_QuestLog.IsOnQuest(questId)
			else
				return false
			end
		end,
		
		IsPushableQuestBlizzardAPI = function(self, questId)
			-- can be shared with other players
			if C_QuestLog.IsPushableQuest then
				return C_QuestLog.IsPushableQuest(questId)
			elseif GetQuestLogPushable then
				return GetQuestLogPushable()	-- note the lack of parameter.  this means the current quest in the quest log is used.
			else
				return false
			end
		end,
		
		IsQuestBountyBlizzardAPI = function(self, questId)
			if C_QuestLog.IsQuestBounty then
				return C_QuestLog.IsQuestBounty(questId)
			else
				return false
			end
		end,
		
		IsQuestCallingBlizzardAPI = function(self, questId)
			if C_QuestLog.IsQuestCalling then
				return C_QuestLog.IsQuestCalling(questId)
			else
				return false
			end
		end,
		
		IsQuestInvasionBlizzardAPI = function(self, questId)
			if C_QuestLog.IsQuestInvasion then
				return C_QuestLog.IsQuestInvasion(questId)
			else
				return false
			end
		end,
		
		IsQuestTaskBlizzardAPI = function(self, questId)	-- bonus objectives
			if C_QuestLog.IsQuestTask then
				return C_QuestLog.IsQuestTask(questId)
			elseif IsQuestTask then
				return IsQuestTask(questId)
			else
				return false
			end
		end,
		
		IsQuestTrivialBlizzardAPI = function(self, questId)
			if C_QuestLog.IsQuestTrivial then
				return C_QuestLog.IsQuestTrivial(questId)
			else
				return false
			end
		end,
		
		IsThreatQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsThreatQuest then
				return C_QuestLog.IsThreatQuest(questId)
			else
				return false
			end
		end,
		
		IsWorldQuestBlizzardAPI = function(self, questId)
			if C_QuestLog.IsWorldQuest then
				return C_QuestLog.IsWorldQuest(questId)
			else
				return false
			end
		end,


		IsQuestFlaggedCompleted = function(self, questId)
			if C_QuestLog.IsComplete then
				return C_QuestLog.IsComplete(questId)
--			if C_QuestLog.IsQuestFlaggedCompleted then
--				return C_QuestLog.IsQuestFlaggedCompleted(questId)
			else
				return IsQuestFlaggedCompleted(questId)
			end
		end,
		
		---
		--	Returns whether the quest is in the quest log.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is in the quest log, false otherwise.
		--	@return True if the quest is marked as complete in the quest log, false otherwise.
		--	@use inLog, isComplete = Grail:IsQuestInQuestLog(11)
		IsQuestInQuestLog = function(self, questId)
			local retval, retvalComplete = false, nil
			local quests = self:_QuestsInLog()
			questId = tonumber(questId)
			if nil ~= questId and nil ~= quests[questId] then
				retval, retvalComplete = true, quests[questId][2]
			end
			return retval, retvalComplete
		end,

		_IsQuestMarkedInDatabase = function(self, questId, db)
			questId = tonumber(questId)
			if nil == questId then return false end
			db = db or GrailDatabasePlayer["completedQuests"]
			local retval = false
			local index = floor((questId - 1) / 32)
			local offset = questId - (index * 32) - 1
			if nil ~= db[index] then
				if bitband(db[index], 2^offset) > 0 then
					retval = true
				end
			end
			return retval
		end,

		---
		--	Indicates whether the quest has been marked obsolete and thus not available.
		IsQuestObsolete = function(self, questId)
			return questId and self.questsNoLongerAvailable[questId] or nil
		end,

		---
		--	Indicates whether the quest is not yet available in the current version of the game.
		IsQuestPending = function(self, questId)
			return questId and self.questsNotYetAvailable[questId] or nil
		end,

		---
		--	Indicates whether the quest is a raid quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a raid quest, otherwise false
		IsRaid = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestRaid) > 0)
		end,

		---
		--	Indicates whether the quest is a rare mob quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a rare mob quest, otherwise false
		IsRareMob = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestRareMob) > 0)
		end,

		---
		--	Returns whether the quest is a repeatable quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a repeatable quest, false otherwise.
		IsRepeatable = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestRepeatable) > 0)
		end,

		---
		--	Returns whether the quest is a resettable quest and has been completed in the past.
		--	This routine can return true and IsQuestCompleted() can return false as the quest can be reset.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is resettable and has ever been completed, false otherwise.
		--	@see HasQuestEverBeenCompleted
		--	@see IsQuestCompleted
		IsResettableQuestCompleted = function(self, questId)
			return self:_IsQuestMarkedInDatabase(questId, GrailDatabasePlayer["completedResettableQuests"])
		end,

		---
		--	Indicates whether the quest is a scenario quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a scenario quest, otherwise false
		IsScenario = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestScenario) > 0)
		end,

		---
		--	Returns whether the quest is a threat quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a threat quest, false otherwise.
		IsThreatQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestThreatQuest) > 0)
		end,

		IsCallingQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestCallingQuest) > 0)
		end,

		IsImportantQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestImportant) > 0)
		end,

		IsMetaQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestMeta) > 0)
		end,

		IsSharableQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestPushable) > 0)
		end,

		IsBountyQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestBounty) > 0)
		end,

		IsInvasionQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestInvasion) > 0)
		end,

		---
		--	Returns whether this is a special type of NPC that has information useful for tooltips and a table of that information
		--	where each item in the table is a table with the type of NPC and the associated NPC/quest/item ID.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return True if there is any table data being returned, false otherwise
		--	@return Table data containing tables of NPC type and associated ID.
		IsTooltipNPC = function(self, npcId)
			local retval = {}
			npcId = tonumber(npcId)
			if nil ~= npcId then
				local droppedBy = self.npc.droppedBy[npcId]
				if nil ~= droppedBy then
					for _, anotherNPCId in pairs(droppedBy) do
						tinsert(retval, { self.NPC_TYPE_BY, anotherNPCId } )
					end
				end
				local killQuests = self.npc.kill[npcId]
				if nil ~= killQuests then
					for _, questId in pairs(killQuests) do
						tinsert(retval, { self.NPC_TYPE_KILL, questId } )
					end
				end
				local has = self.npc.has[npcId]
				if nil ~= has then
					for _, anotherNPCId in pairs(has) do
						tinsert(retval, { self.NPC_TYPE_DROP, anotherNPCId } )
					end
				end
			end
			return (0 < #(retval)), retval
		end,

		---
		--	Indicates whether the quest is a treasure quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return true if the quest is a treasure quest, otherwise false
		IsTreasure = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestTreasure) > 0)
		end,

		---
		--	Returns whether the quest is a weekly quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a weekly quest, false otherwise.
		IsWeekly = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestWeekly) > 0)
		end,

		---
		--	Returns whether the quest is a biweekly quest (meaning once every two weeks).
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a biweekly quest, false otherwise.
		IsBiweekly = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestBiweekly) > 0)
		end,

		---
		--	Returns whether the quest is a world quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a world quest, false otherwise.
		IsWorldQuest = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestWorldQuest) > 0)
		end,

		---
		--	Returns whether the quest is a yearly quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the quest is a yearly quest, false otherwise.
		IsYearly = function(self, questId)
			return (bitband(self:CodeType(questId), self.bitMaskQuestYearly) > 0)
		end,

		---
		--	Returns whether the specifid item is present in the player's bags.
		--	Normally the itemId passed in is a Grail representation of a Blizzard
		--	item ID, but this routine should be able to handle a pure Blizzard ID
		--	as well.
		--	@param soughtItemId Either the Grail representation of an item or a Blizzard one.
		--	@return True if an item with the same ID is in the player's bags, or false/nil otherwise.
		--  @calls GetContainerNumSlots(), GetContainerItemID()
		--  @alters self.cachedBagItems
		ItemPresent = function(self, soughtItemId, soughtCount)
			soughtItemId = tonumber(soughtItemId)
			soughtCount = tonumber(soughtCount) or 1
			if nil == soughtItemId then return false end

			--	The itemId is really our NPC representation of the item so its value
			--	needs to be adjusted back to Blizzard values.
			if soughtItemId > 100000000 then
				soughtItemId = soughtItemId - 100000000
			end

			if GetItemCount then
				local count = GetItemCount(soughtItemId, nil, nil, true)	-- also include reagent bank
				return count >= soughtCount
			end

			-- If the items in the bags are not cached, create a cache of them.
			-- Note that when bags are updated the cache is destroyed.
			if nil == self.cachedBagItems then
				self.cachedBagItems = {}
				local c = self.cachedBagItems
				local id
				for bag = 0, 4 do
					local numSlots = self:GetContainerNumSlots(bag)
					for slot = 1, numSlots do
						id = self:GetContainerItemID(bag, slot)
						if nil ~= id then
							c[id] = true
						end
					end
				end
			end

			-- Return whether the cache of bag items contains the sought item
			return self.cachedBagItems[soughtItemId]
		end,

		_AddNPCLocation = function(self, npcId, npcLocation, aliasNPCId)
			npcId = tonumber(npcId)
			if nil == npcId then return end
			self.npc.locations[npcId] = self.npc.locations[npcId] or {}
			tinsert(self.npc.locations[npcId], Grail:_LocationStructure(npcLocation))
			aliasNPCId = tonumber(aliasNPCId)
			if nil ~= aliasNPCId then
				self.npc.aliases[aliasNPCId] = self.npc.aliases[aliasNPCId] or {}
				tinsert(self.npc.aliases[aliasNPCId], npcId)
			end
		end,

		---
		--	Attempts to load the addon with the name addonName.  If reportFailureInBlizzardUI
		--	is true, a failure will display a message in the Blizzard UI.  Otherwise, a failure
		--	will display in the chat window.
		--	@param addonName The name of the addon to be loaded.
		--	@param reportFailureInBlizzardUI Indicates whether errors are dislpayed in the Blizzard UI or the chat window.
		--	@return True if the addon is loaded, or false otherwise.
		--  @calls UIParentLoadAddOn(), LoadAddOn()
		LoadAddOn = function(self, addonName, reportFailureInBlizzardUI)
			local success, failureReason
			if reportFailureInBlizzardUI then
				success = UIParentLoadAddOn(addonName)
			else
				local LoadAddOn_API = LoadAddOn or C_AddOns.LoadAddOn
				success, failureReason = LoadAddOn_API(addonName)
				if not success then
					print(format("|cFFFF0000Grail|r "..ADDON_LOAD_FAILED, addonName, _G["ADDON_"..failureReason]))
				end
			end
			return success
		end,

		---
		--  Attempts to load the quest names for both the environment and the locale.
		--  @calls Grail:LoadAddOn()
		--  @requires Grail.playerLocale
		LoadLocalizedQuestNames = function(self)
--			self:LoadAddOn("Grail-Quests-" .. self.playerLocale)
			self.quest.name[62017]=SPELL_FAILED_CUSTOM_ERROR_523	-- Necrolord
			self.quest.name[62019]=SPELL_FAILED_CUSTOM_ERROR_521	-- Night Fae
			self.quest.name[62020]=SPELL_FAILED_CUSTOM_ERROR_520	-- Venthyr
			self.quest.name[62023]=SPELL_FAILED_CUSTOM_ERROR_522	-- Kyrian
-- TODO: Need to deal with the fact that self:ItemName(202081) is going to return "Retrieving some information" initially, so we will
--		want to defer setting this name until we can actually get that information properly
			self.quest.name[64764]="~ " .. self.accountUnlock .. " - " .. (self:NPCName(100202081) or "Dragon Isles Supply Bag") .. " ~"
			self.quest.name[67030]="~ " .. (CHROMIE_TIME_CAMPAIGN_COMPLETE or "Campaign completed") .. " ~"
			self.quest.name[72009]="~ " .. (self:QuestName(71238) or "The Ruby Feast") .. " ~"
			self.quest.name[70767]="+ " .. self.nameTaleOutsider .. " +"	-- available to listen to
			self.quest.name[70768]="- " .. self.nameTaleOutsider .. " -"	-- listened to
			self.quest.name[70769]="- " .. self.nameTaleElders .. " -"		-- listened to
			self.quest.name[70770]="+ " .. self.nameTaleElders .. " +"		-- availalble to listen to
			self.quest.name[70771]="- " .. self.nameTaleWarlord .. " -"		-- listened to
			self.quest.name[70772]="+ " .. self.nameTaleWarlord .. " +"		-- availalble to listen to
			self.quest.name[70773]="- " .. self.nameTaleSlumbering .. " -"		-- listened to
			self.quest.name[70774]="+ " .. self.nameTaleSlumbering .. " +"		-- availalble to listen to
			self.quest.name[70775]="- " .. self.nameTaleMagmaPact .. " -"		-- listened to
			self.quest.name[70776]="+ " .. self.nameTaleMagmaPact .. " +"		-- availalble to listen to
			self.quest.name[70777]="- " .. self.nameTaleWeakling .. " -"		-- listened to
			self.quest.name[70778]="+ " .. self.nameTaleWeakling .. " +"		-- availalble to listen to
			self.quest.name[70872]="~ " .. (self:GetBasicAchievementInfo(16409) or "") .. " ~"	-- Let's Get Quacking
		end,

		---
		--  Attempts to load the reputation information for the environment.
		--  @calls Grail:LoadAddOn()
		LoadReputations = function(self)
			self:LoadAddOn("Grail-Reputations")
			self:_CleanDatabaseLearnedQuestReputation()
		end,

		--	Check the internal npc.locations structure for a location close to
		--	the one derived from the locationString provided.
		_LocationKnown = function(self, npcId, locationString, possibleAliasId)
			local retval = false
			npcId = tonumber(npcId)
			if nil == npcId then return retval end
			local t = self.npc.locations[npcId]
			if npcId >= 3000000 and npcId < 4000000 and nil ~= possibleAliasId then
				possibleAliasId = tonumber(possibleAliasId)
				local possibleAliases = self.npc.aliases[possibleAliasId]
				if nil ~= possibleAliases then
					for _, aliasId in pairs(possibleAliases) do
						if self:_LocationKnown(aliasId, locationString) then
							retval = true
						end
					end
				end
			end
			-- Look for learned world quest locations to see if they are in the datbase as fixed locations
			if npcId > self.worldNPCBase and npcId < self.worldNPCBase + 1000000 then
				local mapId, coordinates = strsplit(':', locationString)
				mapId = tonumber(mapId)
				if mapId and self._worldQuestSelfNPCs[mapId] and self._worldQuestSelfNPCs[mapId][coordinates] then
					retval = true
				end
			end
			if nil ~= t then
				local locations = { strsplit(' ', locationString) }
				for _, loc in pairs(locations) do
					local locationStructure = self:_LocationStructure(loc)
					for _, t1 in pairs(t) do
						if self:_LocationsCloseStructures(t1, locationStructure) then
							retval = true
						end
					end
				end
			end
			return retval
		end,

		_LocationStructure = function(self, locationString)
			locationString = strsplit(' ', locationString)	-- we are taking the first one only for the time being
			local mapId, rest = strsplit(':', locationString)
--			local mapLevel = 0
--			local mapLevelString
--			mapId, mapLevelString = strsplit('[', mapId)
			local t1 = { ["mapArea"] = tonumber(mapId) }
--			if nil ~= mapLevelString then
--				mapLevel = tonumber(strsub(mapLevelString, 1, strlen(mapLevelString) - 1))
--			end
--			t1.mapLevel = mapLevel
			local coord, realArea = nil, nil
			if nil ~= rest then
				coord, realArea = strsplit('>', rest)
				local coordinates = { strsplit(',', coord) }
				t1.x = tonumber(coordinates[1])
				t1.y = tonumber(coordinates[2])
				if nil ~= realArea then
					t1.realArea = tonumber(realArea)
				end
			end
			return t1
		end,

		_LocationsClose = function(self, locationString1, locationString2)
			local l1 = self:_LocationStructure(locationString1)
			local l2 = self:_LocationStructure(locationString2)
			return self:_LocationsCloseStructures(l1, l2)
		end,

		_LocationsCloseStructures = function(self, locationStructure1, locationStructure2)
			local retval = false
			local distance = nil
			local l1 = locationStructure1 or {}
			local l2 = locationStructure2 or {}
			if (l1.near or l2.near) and l1.mapArea == l2.mapArea then
				retval = true
				distance = 0.0	-- Assume that near is really really close :-)
--			elseif l1.mapArea == l2.mapArea and l1.mapLevel == l2.mapLevel then
			elseif l1.mapArea == l2.mapArea then
				if l1.x and l2.x and l1.y and l2.y then
					distance = sqrt((l1.x - l2.x)^2 + (l1.y - l2.y)^2)
					if distance < self.locationCloseness then
						retval = true
					end
				end
			end
			return retval, distance
		end,

--		_LogNameIssue = function(self, npcOrQuest, id, properTitle)
--			if GrailDatabase[npcOrQuest] == nil then GrailDatabase[npcOrQuest] = {} end
--			if GrailDatabase[npcOrQuest][self.playerLocale] == nil then GrailDatabase[npcOrQuest][self.playerLocale] = {} end
--			GrailDatabase[npcOrQuest][self.playerLocale][id] = properTitle
--		end,

		---
		--	This returns the map area to which the specified quest belongs for Loremaster purposes.  If the quest does not
		--	belong to any Loremaster, or the achievements addon is not loaded nil is returned.
		--	@param questId The standard numeric questId representing a quest.
		--	@return The map area for Loremaster or nil if not a Loremaster quest.
		LoremasterMapArea = function(self, questId)
			local retval = nil
			questId = tonumber(questId)
			if nil ~= questId and nil ~= self.questsLoremaster then
				retval = self.questsLoremaster[questId]
			end
--			if nil ~= questId and nil ~= self.quests[questId] and nil ~= self.quests[questId][5] then
--				for _, achievementId in pairs(self.quests[questId][5]) do
--					if achievementId < self.mapAreaBaseAchievement then
--						retval = achievementId
--					end
--				end
--			end
			return retval
		end,

		-- Takes a versionString with syntax like a.b.c and converts
		-- this to a number of a million, b thousand, c
		_MakeNumberFromVersion = function(self, versionString)
			local retval = 0
			local millions, thousands, ones = string.match(versionString, "(%d+).(%d+).(%d+)")
			retval = tonumber(millions) * 1000000 + tonumber(thousands) * 1000 + tonumber(ones)
			return retval
		end,

		MapAreaName = function(self, mapAreaId)
			return self.mapAreaMapping[mapAreaId]
		end,

		--	This marks the specified quest as complete in the internal database.  Optionally it will attempt to update the NewNPCs and NewQuests.
		--	@param questId The standard numeric questId representing a quest.
		--	@param updateDatabase If true the NewNPCs and NewQuests will be updated as well as posting the Complete notification.
		_MarkQuestComplete = function(self, questId, updateDatabase, updateActual, updateControl)
			local v = tonumber(questId)
			local index = floor((v - 1) / 32)
			local offset = v - (index * 32) - 1
			local db = GrailDatabasePlayer["completedQuests"]
			local db2 = GrailDatabasePlayer["actuallyCompletedQuests"]
			local db3 = GrailDatabasePlayer["controlCompletedQuests"]

			if not self:IsRepeatable(questId) then
				if (nil == db[index]) then
					db[index] = 0
				end
				if bitband(db[index], 2^offset) == 0 then
					db[index] = db[index] + (2^offset)
				else
					if self.GDE.debug then print(strformat("Quest %d is already marked completed", v)) end
				end
			end

			if updateControl then
				if nil == db3[index] then db3[index] = 0 end
				if bitband(db3[index], 2^offset) == 0 then
					db3[index] = db3[index] + (2^offset)
				else
					if self.GDE.debug then print(strformat("Quest %d is already marked control completed", v)) end
				end
			end

			if updateActual then
				if nil == db2[index] then db2[index] = 0 end
				if bitband(db2[index], 2^offset) == 0 then
					db2[index] = db2[index] + (2^offset)
				else
					if self.GDE.debug then print(strformat("Quest %d is already marked actually completed", v)) end
				end
				-- Make sure any I: quests are marked as incomplete
				local iQuests = self:QuestInvalidates(v)
				if nil ~= iQuests then
					for _, qId in pairs(iQuests) do
						self:_MarkQuestNotComplete(qId, db2)
					end
				end
			end

			if updateDatabase then
				local status = self:StatusCode(questId)
				if not self:IsResettableQuestCompleted(questId) and bitband(status, self.bitMaskRepeatable + self.bitMaskResettable) > 0 then
					local rdb = GrailDatabasePlayer["completedResettableQuests"]
					if (nil == rdb[index]) then
						rdb[index] = 0
					end
					rdb[index] = rdb[index] + (2^offset)
				end

				-- Get the target information to ensure the target exists in the database of NPCs
				local version = self.versionNumber.."/"..self.questsVersionNumber.."/"..self.npcsVersionNumber.."/"..self.zonesVersionNumber
				local targetName, npcId, coordinates = self:TargetInformation()
				npcId = self:_UpdateTargetDatabase(targetName, npcId, coordinates, version)
				if self.GDE.debug then
					if nil ~= targetName then
						npcId = npcId or -1
						coordinates = coordinates or "no coords"
						print("Grail Debug: = "..questId.." => "..targetName.."("..npcId..") "..coordinates)
					else
						print("Grail Debug: = "..questId)
					end
				end
				self:_UpdateQuestDatabase(questId, 'No Title Stored', npcId, false, 'T', version)
				self:_RemoveWorldQuest(questId)
				self:_LearnKCodesForQuest(questId)
				-- >>>VIGNETTE_DEBUG: correlate with recently disappeared vignettes
				do
					local _now = GetTime()
					-- Store as recently completed for reverse vignette lookup
					self._recentlyCompletedUnlinkedQuests = self._recentlyCompletedUnlinkedQuests or {}
					self._recentlyCompletedUnlinkedQuests[v] = _now
					-- Forward lookup: link ALL recently disappeared vignettes to this quest
					if nil ~= self._recentlyDisappearedVignettes then
						local lootSpawnUID = self.lootingGUID and select(7, strsplit('-', self.lootingGUID))
						local linked = false
						for spawnUID, vigInfo in pairs(self._recentlyDisappearedVignettes) do
							if spawnUID ~= lootSpawnUID and (_now - vigInfo.time) <= 10 then
								local _coords = vigInfo.coords or tostring(self:Coordinates())
								local _src = strformat('quests=%s | coords=%s', tostring(v), _coords)
								if self:_IsNewVignetteLink(vigInfo.guid, _src, vigInfo.name) then
									local msg = strformat('VIGNETTE_QUEST_LINK (no loot): vignette=%s name=%s | %s', vigInfo.guid, tostring(vigInfo.name), _src)
									print(msg)
									self:_AddTrackingMessage(msg)
								end
								self._recentlyDisappearedVignettes[spawnUID] = nil
								linked = true
							end
						end
						if linked then self._recentlyCompletedUnlinkedQuests[v] = nil end
					end
				end
				-- >>>QUESTPIN_DEBUG: reverse quest→pin lookup
				self._recentlyCompletedQuestIds = self._recentlyCompletedQuestIds or {}
				self._recentlyCompletedQuestIds[v] = GetTime()
				-- Check if any pins appeared recently for this quest
				if nil ~= self._recentlyAppearedPins then
					local now = GetTime()
					for pinKey, pinInfo in pairs(self._recentlyAppearedPins) do
						if (now - pinInfo.time) <= 10 then
							self:_RecordQuestPinLink(pinKey, pinInfo.pinType, pinInfo.name, tostring(v), pinInfo.coords)
							self._recentlyAppearedPins[pinKey] = nil
						end
					end
				end
				-- >>>QUESTPIN_DEBUG_END
				-- >>>GOSSIP_DEBUG: async gossip quest correlation
				if nil ~= self._lastGossipContext and (GetTime() - self._lastGossipContext.time) <= 10 then
					local gctx = self._lastGossipContext
					local msg = strformat('GOSSIP_DEBUG CLOSED_COMPLETE (async): quest=%d npc=%s(%s) option=%s(id=%s) coords=%s',
						v, tostring(gctx.targetName), tostring(gctx.npcId),
						tostring(gctx.lastOptionName), tostring(gctx.lastOptionID), tostring(gctx.coordinates))
					print(msg)
					self:_AddTrackingMessage(msg)
					self:_RecordGossipQuestLink(v,
						gctx.npcId, gctx.targetName,
						gctx.lastOptionName, gctx.lastOptionID, gctx.coordinates)
					end
				-- >>>GOSSIP_DEBUG_END
				-- >>>VIGNETTE_DEBUG_END
				self:_PostNotification("Complete", questId)
			end

		end,

		--	This marks the specified quest as complete in the specified database.
		--	@param questId The standard numeric questId representing a quest.
		--	@param db The database to use for marking the quest complete.  If none provided, the completed quests database is used.
		--	@param notComplete If true, the quest is marked not complete, otherwise the quest is marked complete.
		--	@return	True if the database is updated, otherwise false is returned if the quest is already marked the desired value.
		_MarkQuestInDatabase = function(self, questId, db, notComplete)
			local v = tonumber(questId)
			if nil == v then return false end
			db = db or GrailDatabasePlayer["completedQuests"]
			local retval = true
			local index = floor((v - 1) / 32)
			local offset = v - (index * 32) - 1
			if nil == db[index] then
				db[index] = 0
			end
			if notComplete then
				if bitband(db[index], 2^offset) > 0 then
					db[index] = db[index] - (2^offset)
				else
					retval = false
				end
			else
				if bitband(db[index], 2^offset) == 0 then
					db[index] = db[index] + (2^offset)
				else
					retval = false
				end
			end
			return retval
		end,

		_MarkQuestNotComplete = function(self, questId, db)
			self:_MarkQuestInDatabase(questId, db, true)
		end,

		---
		--	Returns whether the character meets prerequisites for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the character meets the prerequisites for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		MeetsPrerequisites = function(self, questId, code, forceSpecificChecksOnly)
			local retval = true
			code = code or 'P'
			local any, present, failures = self:_AnyEvaluateTrue(questId, code, forceSpecificChecksOnly)
			if present then
				retval = any
			end
			return retval, failures
		end,

		_MeetsRequirement = function(self, questId, requirementCode, soughtParameter)
			if nil == questId or not tonumber(questId) then return false end
			local retval = true
			questId = tonumber(questId)
			self:_CodeAllFixed(questId)
			local bitMaskToUse
			local obtainers = self:CodeObtainers(questId)

			if 'G' == requirementCode then
				if nil == soughtParameter then
					bitMaskToUse = self.playerGenderBitMask
				elseif 3 == tonumber(soughtParameter) then
					bitMaskToUse = self.bitMaskGenderFemale
				else
					bitMaskToUse = self.bitMaskGenderMale
				end
--				retval = (bitband(self.quests[questId][4], bitMaskToUse) > 0)
				retval = (bitband(obtainers, bitMaskToUse) > 0)

			elseif 'F' == requirementCode or 'f' == requirementCode then
				if nil == soughtParameter then
					bitMaskToUse = self.playerFactionBitMask
				elseif 'Horde' == soughtParameter then
					bitMaskToUse = self.bitMaskFactionHorde
				else
					bitMaskToUse = self.bitMaskFactionAlliance
				end
--				retval = (bitband(self.quests[questId][4], bitMaskToUse) > 0)
				retval = (bitband(obtainers, bitMaskToUse) > 0)

			elseif 'C' == requirementCode or 'X' == requirementCode then
				bitMaskToUse = (nil == soughtParameter) and self.playerClassBitMask or self.classNameToBitMapping[soughtParameter]
--				retval = (bitband(self.quests[questId][4], bitMaskToUse) > 0)
				retval = (bitband(obtainers, bitMaskToUse) > 0)

			elseif 'H' == requirementCode then
				local comparisonValue = self:CodeHoliday(questId)
				if 0 ~= comparisonValue then
					local found = false
					for bitMask,code in pairs(self.holidayBitToCodeMapping) do
						if bitband(comparisonValue, bitMask) > 0 then		-- this bitValue is one that is required by the quest
							if self:CelebratingHoliday(self.holidayMapping[code]) then
								found = true
							end
						end
					end
					retval = found
				end
			elseif 'R' == requirementCode or 'S' == requirementCode then
				bitMaskToUse = (nil == soughtParameter) and self.playerRaceBitMask or self.raceNameToBitMapping[soughtParameter]
				if nil == bitMaskToUse then
					print("Grail problem: Quest "..questId.." cannot use race ".. soughtParameter)
					self:_AddTrackingMessage("Grail problem: Quest "..questId.." cannot use race ".. soughtParameter)
					bitMaskToUse = 0
				end
--				retval = (bitband(self.quests[questId][4], bitMaskToUse) > 0)
				retval = (bitband(self:CodeObtainersRace(questId), bitMaskToUse) > 0)

-- TODO: Should convert these over to the new way of doing things
--			elseif 'V' == requirementCode or 'W' == requirementCode or 'P' == requirementCode then
			elseif 'P' == requirementCode then
--				local codeArray = { strsplit(" ", self.quests[questId][1]) }
				local codeArray = { strsplit(" ", self.questCodes[questId]) }
				local controlCode
				local controlValue
				for i = 1, #codeArray do
					controlCode = strsub(codeArray[i], 1, 1)
					controlValue = strsub(codeArray[i], 2, 2)
					if controlCode == requirementCode then
--						if 'V' == requirementCode or 'W' == requirementCode then
--							local repIndex = strsub(codeArray[i], 2, 4)
--							local repValue = tonumber(strsub(codeArray[i], 5))
--							local exceeds, earnedValue = self:_ReputationExceeds(self.reputationMapping[repIndex], repValue)
--							local success = exceeds
--							if ('V' == requirementCode) then success = not success end
--							if success then
--								retval = false
----								if nil ~= earnedValue then
----									tinsert(failures, codeArray[i].." actual: "..earnedValue)
----								end
--							end
--						elseif 'P' == requirementCode then
						if 'P' == requirementCode then
							local colonCheck = strsub(codeArray[i], 3, 3)
							if ':' == controlValue or
							('L' == controlValue and ':' == colonCheck) or
							('H' == controlValue and ':' == colonCheck) or
							('C' == controlValue and ':' == colonCheck) or
							('C' == controlValue and 'T' == colonCheck and ':' == strsub(codeArray[i], 4, 4)) or
							('L' == controlValue and 'T' == colonCheck and ':' == strsub(codeArray[i], 4, 4))
							then
								-- we ignore these because they are not profession requirements.
							else
								local profValue = tonumber(strsub(codeArray[i], 3, 5))
								local exceeds, skillLevel = self:ProfessionExceeds(controlValue, profValue)
								if not exceeds then
									retval = false
--									tinsert(failures, codeArray[i].." actual: "..skillLevel)
								end
							end

						end
					end
				end
			end
			return retval
		end,

		---
		--	Returns whether the character meets class requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@soughtClass The desired class to be matched, or if nil the player's class will be used
		--	@return True if the character meets the class requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementClass = function(self, questId, soughtClass)
			return self:_MeetsRequirement(questId, 'C', soughtClass)
		end,

		---
		--  Returns a code indicating the factions associated with the table of NPC IDs.
		--  @return A for Alliance only, H for Horde only, or B for both.
		--  @calls Grail:_NPCFaction()
		_FactionsFromNPCs = function(self, npcs)
			local retval = 'B'
			local foundAlliance, foundHorde = false, false
			if nil ~= npcs then
				for _, npcId in pairs(npcs) do
					local factionCode = self:_NPCFaction(npcId)
					if nil == factionCode then
						-- ignore this
					elseif 'A' == factionCode then
						foundAlliance = true
					elseif 'H' == factionCode then
						foundHorde = true
					end
				end
			end
			if foundAlliance and not foundHorde then
				retval = 'A'
			elseif foundHorde and not foundAlliance then
				retval = 'H'
			end
			return retval
		end,

		---
		--	Returns a code representing the factions associated with quest givers/turnins.
		--  If there is a limit for either givers or turnins that limit is used.  If there
		--  is a limit that disagrees, that of givers is returned.
		--  @return A for Alliance only, H for Horde only, or B for both.
		--  @calls Grail:_FactionsFromNPCs(), Grail:QuestNPCAccepts(), Grail:QuestNPCTurnins()
		_FactionsFromQuestGivers = function(self, questId)
			local retval = self:_FactionsFromNPCs(self:QuestNPCAccepts(questId))
			if retval == 'B' then
				retval = self:_FactionsFromNPCs(self:QuestNPCTurnins(questId))
			end
			return retval
		end,

		---
		--	Returns whether the character meets faction requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@soughtFaction The desired faction to be matched, or if nil the player's faction will be used
		--	@return True if the character meets the faction requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementFaction = function(self, questId, soughtFaction)
			local retval = self:_MeetsRequirement(questId, 'F', soughtFaction)
			if retval then
				if nil == soughtFaction then
					soughtFaction = self.playerFaction
				end
				local soughtFactionCode = 'A'
				if 'Horde' == soughtFaction then
					soughtFactionCode = 'H'
				end
				local questGiversFactions = self:_FactionsFromQuestGivers(questId)
				retval = ('B' == questGiversFactions) or (soughtFactionCode == questGiversFactions)
			end
			return retval
		end,

		---
		--	Returns whether the character meets gender requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@param soughtGender The desired gender to be matched, or if nil the player's gender will be used
		--	@return True if the character meets the gender requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementGender = function(self, questId, soughtGender)
			return self:_MeetsRequirement(questId, 'G', soughtGender)
		end,

		---
		--	Returns whether the character meets group quest requirements based on the contents
		--	of the controlTable, which can have in it:
		--		groupNumber		integer		number of group for quests	(required)
		--		minimum			integer		number needing to match		(required)
		--		exactMatch		boolean		indicates count must match exactly instead of >=
		--		turnedIn		boolean		indicating a match succeeds when quest completed and turned in
		--		inLog			boolean		indicating a match succeeds when quest in log
		--		completeInLog	boolean		indicating a match succeeds when quest complete in log
		--		accepted		boolean		indicating a match succeeds when quest has been accepted
		--		possible		boolean		indicating a match succeeds when quest is not invalidated
		MeetsRequirementGroupControl = function(self, controlTable)
			controlTable = controlTable or {}
			local numberMatching = 0
			local questTable = self.questStatusCache['G'][controlTable.groupNumber] or {}
			local dailyGroup = nil
			if controlTable.accepted then
				local dailyDay = self:_GetDailyDay()
				dailyGroup = GrailDatabasePlayer["dailyGroups"][dailyDay] and GrailDatabasePlayer["dailyGroups"][dailyDay][controlTable.groupNumber] or {}
			end
			if #questTable >= controlTable.minimum then
				for _, questId in pairs(questTable) do
					local foundMatch = false
					if not foundMatch and controlTable.turnedIn then
						if self:IsQuestCompleted(questId) then foundMatch = true end
					end
					if not foundMatch and controlTable.inLog then
						local questInLog, questStatus = Grail:IsQuestInQuestLog(questId)
						if questInLog then foundMatch = true end
					end
					if not foundMatch and controlTable.completeInLog then
						local questInLog, questStatus = Grail:IsQuestInQuestLog(questId)
						if questInLog and questStatus ~= nil and questStatus > 0 then foundMatch = true end
					end
					if not foundMatch and controlTable.accepted then
						if tContains(dailyGroup, questId) then foundMatch = true end
					end
					if not foundMatch and controlTable.possible then
						if not self:IsInvalidated(questId) then foundMatch = true end
					end
					if foundMatch then numberMatching = numberMatching + 1 end
				end
			end
			if controlTable.exactMatch then
				return (numberMatching == controlTable.minimum)
			else
				return (numberMatching >= controlTable.minimum)
			end
		end,

		---
		--	Returns whether the character meets holiday requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the character meets the holiday requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementHoliday = function(self, questId)
			return self:_MeetsRequirement(questId, 'H')
		end,

		---
		--	Returns whether the level requirements are met for the specified quest.  This handles both minimum and maximum level requirements.
		--	@param questId The standard numeric questId representing a quest.
		--	@param optionalComparisonLevel A comparison level to use.  If nil the character's level is used.
		--	@return True if the level requirements for the specified quest are met or false otherwise.
		--	@return The level used in making comparisons to the requirements of the quest.
		--	@return The minimum level required for the quest.
		--	@return The maximum level permitted for the quest or Grail.INFINITE_LEVEL if there is none.
		--	@see StatusCode
		MeetsRequirementLevel = function(self, questId, optionalComparisonLevel)
			questId = tonumber(questId)
			if nil == questId then return false end
			local bitMask = self:CodeLevel(questId)
			local retval = true
			local levelToCompare = optionalComparisonLevel or UnitLevel('player')
			local levelRequired = bitband(bitMask, self.bitMaskQuestMinLevel) / self.bitMaskQuestMinLevelOffset
			local levelNotToExceed = bitband(bitMask, self.bitMaskQuestMaxLevel) / self.bitMaskQuestMaxLevelOffset
			if levelToCompare < levelRequired or levelToCompare > levelNotToExceed then
				retval = false
			end
			return retval, levelToCompare, levelRequired, levelNotToExceed
		end,

		---
		--	Returns whether the character meets profession requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the character meets the profession requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementProfession = function(self, questId)
			return self:MeetsPrerequisites(questId, 'P', self.bitMaskProfession)
		end,

		---
		--	Returns whether the character meets race requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@soughtRace The desired race to be matched, or if nil the player's race will be used
		--	@return True if the character meets the race requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
		MeetsRequirementRace = function(self, questId, soughtRace)
			return self:_MeetsRequirement(questId, 'R', soughtRace)
		end,

		-- Returns a boolean indicating whether the player meets the renown requirements (if any) for the specified quest.
		-- TODO: Implement this some day if we get all crazy about it...
--		MeetsRequirementRenown = function(self, questId)
--			questId = tonumber(questId)
--			if nil == questId then return false end
--			-- TODO: Get a renown requirement for the quest
--			-- TODO: If none exists return true
--			-- TODO: Otherwise determine covenant and needed level and return results of _CovenantRenownMeetsOrExceeds call
--		end,
		
		--	Returns a boolean indicating whether the player's renown level with the specified covenant meets or exceeds the desired level.
		--	1=Bastion, 2=Venthyr, 3=Night Fae, 4=Necrolord
		_CovenantRenownMeetsOrExceeds = function(self, covenant, desiredLevel)
			local retval = false
			covenant = tonumber(covenant)
			desiredLevel = tonumber(desiredLevel)
			if nil == covenant or nil == desiredLevel then return false end
			local activeCovenant = C_Covenants and C_Covenants.GetActiveCovenantID() or nil
			if 0 ~= covenant and covenant ~= activeCovenant then return false end
			local levels = C_CovenantSanctumUI and C_CovenantSanctumUI.GetRenownLevels(activeCovenant) or nil
			if nil ~= levels then
				for _, levelInfo in pairs(levels) do
					if desiredLevel == levelInfo.level then
						return not levelInfo.locked
					end
				end
			end
			return retval
		end,

		-- The assumption is if someone is not using GrailWhenPlayer then this is the same as IsQuestCompleted
		_QuestTurnedInBeforeDate = function(self, questId, comparisonDate)
			questId = tonumber(questId)
			if nil == questId then return false end
			local retval = self:IsQuestCompleted(questId)
			if retval then
				if nil ~= GrailWhenPlayer then
					local when = GrailWhenPlayer.when[questId]
					if nil ~= when then
						-- Start with a date and then replace its values with those from when the quest was completed.
						-- an example of when is: 2018-12-18 06:34
						local whenDate = C_DateAndTime.GetCurrentCalendarTime()
						local year, month, day, hour, minute = string.match(when, "(%d+)-(%d+)-(%d+) (%d+):(%d+)")
						whenDate.year = year
						whenDate.month = month
						whenDate.monthDay = day
						whenDate.hour = hour
						whenDate.minute = minute
						retval = (C_DateAndTime.CompareCalendarTime(whenDate, comparisonDate) >= 0)
					end
				end
			end
			return retval
		end,

		-- The assumption is if someone is not using GrailWhenPlayer then this is the same as IsQuestCompleted
		_QuestTurnedInBeforeLastWeeklyReset = function(self, questId)
			local lastWeeklyResetDate = C_DateAndTime.AdjustTimeByMinutes(C_DateAndTime.GetCurrentCalendarTime(), (C_DateAndTime.GetSecondsUntilWeeklyReset() - (86400 * 7)) / 60)
			return self:_QuestTurnedInBeforeDate(questId, lastWeeklyResetDate)
		end,

		-- The assumption is if someone is not using GrailWhenPlayer then this is the same as IsQuestCompleted
		_QuestTurnedInBeforeTodaysReset = function(self, questId)
			local todayResetDate = C_DateAndTime.AdjustTimeByMinutes(C_DateAndTime.GetCurrentCalendarTime(), (C_DateAndTime.GetSecondsUntilDailyReset() - (86400 * 1)) / 60)
			return self:_QuestTurnedInBeforeDate(questId, todayResetDate)
		end,

		-- Providing -1 as the talendId prints out all the researched talents instead of doing the normal behavior
		_GarrisonTalentResearched = function(self, talentId)
			local retval = false
			talentId = tonumber(talentId)
			if nil ~= talentId then
				-- Note that we would normally try to use self.playerClassId as the second parameter, but that yields nil, and 0 returns them all.
				local talentTreeIds = C_Garrison.GetTalentTreeIDsByClassID(self.garrisonType9, 0)
				if nil ~= talentTreeIds then
					for _, talentTreeId in pairs(talentTreeIds) do
						local treeInfo = C_Garrison.GetTalentTreeInfo(talentTreeId)
						if nil ~= treeInfo then
							local talents = treeInfo.talents
							if nil ~= talents then
								for _, talentInfo in pairs(talents) do
									local fakeQuestName = treeInfo.title .. ' - ' .. talentInfo.name
									local id = tonumber(talentInfo.id)
									local fakeQuestId = 400000 + id
									if fakeQuestName ~= self.quest.name[fakeQuestId] then
										self.quest.name[fakeQuestId] = fakeQuestName
										self:_LearnQuestName(fakeQuestId, fakeQuestName)
									end
									if talentInfo.researched then
										if talentId == id then
											retval = true
										elseif talentId == -1 then
											print(id, fakeQuestName)
										end
									end
								end
							end
						end
					end
				end
			end
			return retval
		end,

		---
		--	Returns whether the character meets reputation requirements for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return True if the character meets the reputation requirements for the specified quest or false otherwise.
		--	@return A table of failures if any, nil otherwise.
		--	@see StatusCode
--		MeetsRequirementReputation = function(self, questId)
--			local first, failures = self:_MeetsRequirement(questId, 'V')
--			local second, failures2 = self:_MeetsRequirement(questId, 'W')
--			local retval = first and second
--			if nil == failures then
--				failures = failures2
--			else
--				failures = self:_TableAppend(failures, failures2)
--			end
--			return retval, failures
--		end,

		MeetsRequirementReputation = function(self, questId)
			return self:MeetsPrerequisites(questId, 'P', self.bitMaskReputation)
		end,

--		MeetsRequirementReputation = function(self, questId)
--			local retval, failures = true, nil
--			local reputationCodes = self.questReputationRequirements[questId]
--			if reputationCodes then
--				local reputationCount = strlen(reputationCodes) / 4
--				local index, value, notExceeds
--				local exceeds, earnedValue
--				for i = 1, reputationCount do
--					index, value = self:ReputationDecode(strsub(reputationCodes, i * 4 - 3, i * 4))	-- when value is negative this means reputation cannot exceed the -value
--					notExceeds = false
--					if value < 0 then
--						value = value * -1
--						notExceeds = true
--					end
--					exceeds, earnedValue = self:_ReputationExceeds(self.reputationMapping[index], value)
--					if notExceeds then exceeds = not exceeds end
--					if not exceeds then
--						retval = false
--						failures = (failures or "") .. "|Rep:" .. index .. value .. " Actual:" .. earnedValue .. " "
--					end
--				end
--			end
--			if nil ~= failures then failures = {failures} end
--			return retval, failures
--		end,

		NPCComment = function(self, npcId)
			npcId = tonumber(npcId)
			return nil ~= npcId and self.npc.comment[npcId] or nil
		end,

		_NPCFaction = function(self, npcId)
			npcId = tonumber(npcId)
			return nil ~= npcId and self.npc.faction[npcId] or nil
		end,

		-- Provided our internal npcId (handling game objects and items) return
		-- the value to use in looking up the name of the NPC.  This allows our
		-- varieties of indirection.  Without a value, return the requested.
		_NPCIndex = function(self, npcId)
			local retval = tonumber(npcId)
			if nil ~= retval and nil ~= self.npc.nameIndex[retval] then
				retval = self.npc.nameIndex[retval]
			end
			return retval
		end,

		---
		--	Returns a table of NPC records filtered by the provided parameters where each record contains
		--	informaion about the NPC's location containing values whose keys are described in this table:
		--		name		the localized name of the NPC
		--		id			the npcId (passed in to the function)
		--		mapArea		the map area ID where the NPC is located
		--		mapLevel	if present the dungeon level within the mapArea 	*** DEPRECATED ***
		--		near		true if the NPC is considered nearby
		--		x			the x coordinate of the NPC location
		--		y			the y coordinate of the NPC location
		--		realArea	the map area ID of the real area where the NPC is located
		--		heroic		true if the NPC needs to be in a heroic dungeon
		--		kill		true if the NPC needs to be killed to start a quest
		--		notes		non-nil if there are notes associated with the NPC
		--		alias		if exists is the actual NPC ID of the Blizzard NPC
		--		dropName	if exists is the name of the item dropped
		--		dropId		if exists is the NPC ID of the item dropped
		--		questId		if exists is the quest associated with the dropped item
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@param requiresNPCAvailable If true, the NPC must be available.
		--	@param onlySingleReturn If true, only one location will be in the returned table, otherwise all matching locations will be there.
		--	@param onlyMapReturn If true, only locations matching the appropriate map area will be returned.
		--	@param preferredMapAreaId The map area ID to be used, and if nil the character's current map area is used.
		--	@param dungeonLevel The dungeon level to be used
		--	@return A table of locations where the NPC can be found or nil if there are none.
		--	@see IsNPCAvailable
		NPCLocations = function(self, npcId, requiresNPCAvailable, onlySingleReturn, onlyMapReturn, preferredMapAreaId, dungeonLevel)
			local retval = {}
			local npcs = self:_RawNPCLocations(npcId)
			if nil ~= npcs then
				local mapIdToUse = tonumber(preferredMapAreaId) or Grail.GetCurrentDisplayedMapAreaID()
				for _, npc in pairs(npcs) do
					if not requiresNPCAvailable or self:IsNPCAvailable(npc.id) then
						if not onlyMapReturn or (onlyMapReturn and mapIdToUse == npc.mapArea) then
--							if not dungeonLevel or (dungeonLevel == npc.mapLevel) then
							if not dungeonLevel then
								tinsert(retval, npc)
							end
						end
					end
				end
				if onlySingleReturn and 1 < #retval then
					retval = { retval[1] }		-- pick the first item for no better algorithm to use to decide
				end
			end
			if 0 == #retval then
				retval = nil
			end
			return retval
		end,

		---
		--	Returns the localized name of the NPC represented by the specified NPC ID.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return The localized string for the specific NPC, or nil if the NPC is not found in the database.
		NPCName = function(self, npcId)
			local retval = nil
			npcId = tonumber(npcId)
			if nil ~= npcId then
				local indexToUse = self:_NPCIndex(npcId)
				retval = self.npc.name[indexToUse]
				if nil == retval then
					local hyperlinkFormat
					if indexToUse > 100000000 then
						hyperlinkFormat = strformat("item:%d:0:0:0:0:0:0:0", indexToUse - 100000000)
					elseif indexToUse > 1000000 then
						hyperlinkFormat = strformat("unit:0xF51%05X00000000", indexToUse - 1000000)	-- does not work
--						hyperlinkFormat = 'item:GameObject-0-0-0-0-' .. indexToUse - 1000000 .. '-0'	-- did not work
--						hyperlinkFormat = 'unit:GameObject-0-0-0-0-' .. indexToUse - 1000000 .. '-0'	-- did not work
--						hyperlinkFormat = 'unit:Creature-0-0-0-0-' .. indexToUse - 1000000 .. '-0'	-- did not work
					else
						hyperlinkFormat = 'unit:Creature-0-0-0-0-' .. indexToUse .. '-0'
					end
					local name = _GetHyperlinkName(hyperlinkFormat, self.tooltipNPC, "com_mithrandir_grailTooltipNPCTextLeft1")
					if name and name ~= self.retrievingString then
						retval = name
						self.npc.name[indexToUse] = name
					end
				end
			end
			return retval
		end,

		---
		--	Returns the npcId to use for the NPC found at the specified location
		--	with the specified npcId.  This can return an alias npcId, and it can
		--	create either the real one or an alias, updating the databases based
		--	on what it has done.
		--	@param npcId The standard numeric Blizzard ID representing an NPC.
		--	@param npcLocationString The standard Grail string representing the location of the NPC.
		--	@return The npcId one should use for this NPC.
		_NPCToUse = function(self, npcId, npcLocationString)
			npcId = tonumber(npcId)
			local retval = npcId
			if nil ~= npcId and npcId > 0 then
				if not self:_LocationKnown(npcId, npcLocationString) then
					local aliasFound, aliasNPCId = self:_BestAliasNPCToUse(npcId, npcLocationString)
					if aliasFound then
						retval = aliasNPCId
					end
--					local aliasFound = false
--					local possibleAliases = self.npc.aliases[npcId]
--					if nil ~= possibleAliases then
--						-- TODO: Need to look through all the possibleAliases and return the best one because otherwise we are not returning the one that should be used.
--						for _, aliasId in pairs(possibleAliases) do
--							if self:_LocationKnown(aliasId, npcLocationString) then
--								retval = aliasId
--								aliasFound = true
--							end
--						end
--					end
					if not aliasFound then
						if nil ~= self.npc.locations[npcId] and 0 < #(self.npc.locations[npcId]) then
							retval = self:_CreateAliasNPC(npcId, npcLocationString)
						else
							self:_LearnNPCLocation(npcId, npcLocationString)
						end
					end
				end
			end
			return retval
		end,

		---
		--	Returns whether an alias is found and the npc ID for it.
		--	Picks the best one (meaning closest) if there are more than one that match.
		_BestAliasNPCToUse = function(self, npcId, npcLocationString)
			local retval, bestNPCId = false, nil
			-- The key for npc.aliases is the true NPC ID.  The values are alias NPC IDs (usually in the 700000 range) for that true NPC ID.
			local possibleAliases = self.npc.aliases[npcId]
			if nil ~= possibleAliases then
				local npcLocationStrings = { strsplit(' ', npcLocationString) }
				local bestDistanceValue = self.locationCloseness * 1000	-- initialize the value to something really big so the first found will be used
				for _, aliasId in pairs(possibleAliases) do
					local aliasLocationStructures = self.npc.locations[aliasId]
					if nil ~= aliasLocationStructures then
						for _, npcLocationString in pairs(npcLocationStrings) do
							local npcLocation = self:_LocationStructure(npcLocationString)
							for _, aliasLocation in pairs(aliasLocationStructures) do
								local found, computedDistance = self:_LocationsCloseStructures(npcLocation, aliasLocation)
								if found and computedDistance and computedDistance < bestDistanceValue then
									bestDistanceValue = computedDistance
									bestNPCId = aliasId
									retval = true
								end
							end
						end
					end
				end
			end
			return retval, bestNPCId
		end,

		_CreateAliasNPC = function(self, npcId, npcLocationString)
			local aliasBase = 2999999
			while nil ~= self.npc.locations[aliasBase + 1] do
				aliasBase = aliasBase + 1
			end
			local newAliasId = aliasBase + 1
			self:_LearnNPCLocation(newAliasId, npcLocationString, npcId)
			return newAliasId
		end,

		---
		--	Returns the npcId for a newly created NPC whose location matches the npcLocationString provided
		--	assuming this is a newly learned World Quest location, with the npcId starting off from a known
		--	value used specifically for this purpose.
		_CreateWorldNPC = function(self, npcLocationString)
			local base = self.worldNPCBase
			while nil ~= self.npc.locations[base + 1] do
				base = base + 1
			end
			local npcId = base + 1
			self:_LearnNPCLocation(npcId, npcLocationString)
			return npcId
		end,

		---
		--	Returns the localized name of the GameObject represented by the specified Object ID, if Grail knows it.
		--	@param objectId The standard numeric Blizzard ID representing a game object.
		--	@return The localized string for the specific game object, or nil if it is not in the database.
		ObjectName = function(self, objectId)
			local retval = nil
			objectId = tonumber(objectId)
			if nil ~= objectId then
				local indexToUse = self:_NPCIndex(objectId + 1000000)
				retval = self:NPCName(indexToUse)
			end
			return retval
		end,

		---
		--	Returns the localized name of the item represented by the specified Item ID.
		--	@param itemId The standard numeric Blizzard ID representing an item.
		--	@return The localized string for the specific item.
		ItemName = function(self, itemId)
			local retval = nil
			itemId = tonumber(itemId)
			if nil ~= itemId then
				local indexToUse = self:_NPCIndex(itemId + 100000000)
				retval = self:NPCName(indexToUse)
			end
			return retval
		end,

		-- Checks to ensure the only prerequisites that fail are ones that possess the specified questCode
		_OnlyFailsPrerequisites = function(self, questId, questCode)
			local retval = true
			local success, failures = self:MeetsPrerequisites(questId)
			if not success and nil ~= failures then
				for _, codeString in pairs(failures) do
					if questCode ~= strsub(codeString, 1, 1) then
						retval = false
					end
				end
			end
			return retval
		end,

		--	Internal Use.
		--	This routine ensures that all the codes present in tableOrString are ones that match the codeLetter.
		_OnlyHasCodes = function(self, tableOrString, codeLetter)
			local controlTable = { retval = true, codeLetter = codeLetter, func = self._OnlyHasCodesSupport }
			self._ProcessCodeTable(tableOrString, controlTable)
			return controlTable.retval
		end,

		_OnlyHasCodesSupport = function(controlTable)
			local code, subcode, numeric = Grail:CodeParts(controlTable.innorItem)
			if controlTable.codeLetter ~= code then controlTable.retval = false end
		end,

		--	Checks to ensure the invalidations present are those that have the specified questCode
		_OnlyHasInvalidates = function(self, questId, questCode)
			return self:_OnlyHasCodes(self:QuestInvalidates(questId), questCode)
		end,

		--	Checks to ensure the prerequisites present are those that have the specified questCode
		_OnlyHasPrerequisites = function(self, questId, questCode)
			return self:_OnlyHasCodes(self:QuestPrerequisites(questId, true), questCode)
		end,

		--	Checks to make sure the phase matches the type for the specified code and number.
		--	For 971, this is the player's Garrison and we can use the same code structure for
		--	phases to handle Garrison level.
		_PhaseMatches = function(self, typeOfMatch, phaseCode, phaseNumber)
			local retval = false
			local currentPhase = nil
-- SMH: This is commented out for the time being until we can investigate how to handle
-- phasing on Thunder Isle.
--			if (not self.battleForAzeroth and 928 == phaseCode) or (self.battleForAzeroth and 504 == phaseCode) then
---- TODO: Determine if we will need to change the map to that of Thunder Isle to make use of this...I believe it will be the only way
--				if "THUNDER_ISLE" == C_MapBar.GetTag() then
--					currentPhase = C_MapBar.GetPhaseIndex() + 1	-- it starts with 0 for phase 1 (just like C)
--				end
--			else
--			if (not self.battleForAzeroth and (971 == phaseCode or 976 == phaseCode)) or (self.battleForAzeroth and (581 == phaseCode or 587 == phaseCode)) then
			if 971 == phaseCode or 976 == phaseCode or 581 == phaseCode or 587 == phaseCode then
				currentPhase = C_Garrison.GetGarrisonInfo(self.garrisonType6) or 0	-- the API returns nil when there is no garrison
			end
			--	We are using phaseCode 0 to mean the Classic Darkmoon Faire location.
			--	We assume perfect swapping back and forth between locations with Elwynn being in odd months.
			--	The results should be phase 1 for Elwynn Forest and 2 for Mulgore
			if 0 == phaseCode and self.existsClassic then
				local weekday, month, day, year, hour, minute = self:CurrentDateTime()
				if month == 1 or month == 3 or month == 5 or month == 7 or month == 9 or month == 11 then
					currentPhase = 1
				else
					currentPhase = 2
				end
			end
			if nil ~= currentPhase then
				if ('=' == typeOfMatch and currentPhase == phaseNumber) or
					('<' == typeOfMatch and currentPhase < phaseNumber) or
					('>' == typeOfMatch and currentPhase > phaseNumber) then
					retval = true
				end
			end
			return retval
		end,

		--	Routine used to put notifications into the system that will be posted in a routine called by OnUpdate after
		--	the spcified delay.  If there were no notifications in the queue prior to this call the notificationFrame
		--	will have an OnUpdate script set.
		--	@param notificationName The name of the notification that will eventually be posted.  E.g., Abandon, Accept, etc.
		--	@param questId The questId associated with the notification.
		--	@param delay The delay time in seconds which will probably be a floating point number less than one.
		_PostDelayedNotification = function(self, notificationName, questId, delay)
			if nil == self.delayedNotifications then self.delayedNotifications = {} end
			if 0 == #(self.delayedNotifications) then	-- the assumption is when the table has 0 notifications we pull the handler off
				self.notificationFrame:SetScript("OnUpdate", function(myself, elapsed) self:_ProcessDelayedNotifications(elapsed) end)
			end
			tinsert(self.delayedNotifications, { ["n"] = notificationName, ["q"] = questId, ["f"] = GetTime() + delay })
		end,

		--	This routine is used to post notifications to observers.
		--	@param eventName The name of the notification.
		--	@param questId The questId associated with the notification.
		_PostNotification = function(self, eventName, questId)
			if nil ~= self.observers[eventName] then
				for _,f in pairs(self.observers[eventName]) do
					f(eventName, questId)
				end
			end
		end,

		--	Internal Use.
		--	@param controlTable The table that provides control information for processing prerequisites.  Its structure is detailed in _PreparePrerequisiteInfo().
		_GetPrerequisiteInfo = function(controlTable)
			controlTable = controlTable or {}
			local questId, preqTable, result, index = controlTable.questId, controlTable.preq, controlTable.result, controlTable.index
			if nil == questId then return end
			local code, subcode, numeric = Grail:CodeParts(questId)
			if nil == numeric then return end
			if nil ~= preqTable and not tContains(preqTable, numeric) then
				tinsert(preqTable, numeric)
				local preqs = Grail:QuestPrerequisites(numeric, true)
				if nil ~= preqs then
					local doMath = controlTable.doMath
					controlTable.doMath = nil
					Grail._PreparePrerequisiteInfo(preqs, controlTable)
					controlTable.doMath = doMath
				end
				return
			end
			local statusLetter = Grail:ClassificationOfQuestCode(questId, nil, controlTable.buggedObtainable)
			if 'P' == statusLetter then
				local doMath = controlTable.doMath
				controlTable.doMath = nil
				Grail._PreparePrerequisiteInfo(Grail:QuestPrerequisites(numeric, true), controlTable)
				controlTable.doMath = doMath
			elseif 'U' == statusLetter or 'B' == statusLetter or 'C' == statusLetter then -- or 'L' == statusLetter
				-- do nothing since this is a failure
			else	-- I, D, R, G, W
				result[numeric] = result[numeric] or {}
				if not tContains(result[numeric], index) then tinsert(result[numeric], index) end
			end
		end,

		--	Internal Use.
		--	This routine allows gathering a list of all the prerequisites starting with the ones in the provided tableOrString
		--	following the prerequsites recursively as appropriate.  The controlTable contains information about how the levels
		--	of prerequisites are to be processed.
		--		result			table		keys will be questIds for the first prerequisites in chains, and values will be tables of indexes (based on the indexes in the first prerequisites)
		--		preq			table
		--		lastIndexUsed	integer
		--		doMath			boolean
		--		index			integer		internal - current index being processed
		--		questId			integer		internal - current questId being processed
		--		buggedObtainable boolean
		--		func			function	function to be called for each innorItem processed from tableOrString
		--		codeString		string		internal - current codeString (where tableOrString is string) being processed, nil for table
		--		orItem			string		internal - current orItem from codeString being processed
		--		andItem			string		internal - current andItem from orItem being processed
		--		innorItem		string		internal - current innorItem from andItem being processed
		--	@param tableOrString The prerequisite information provided as a table or a string.
		--	@param controlTable The table that provides control information for processing the prerequisites.
		_PreparePrerequisiteInfo = function(tableOrString, controlTable)
			controlTable.func = controlTable.func or Grail._PreparePrerequisiteInfoSupport
			Grail._ProcessCodeTable(tableOrString, controlTable)
		end,

		_PreparePrerequisiteInfoSupport = function(controlTable)
			local code, subcode, numeric = Grail:CodeParts(controlTable.innorItem)
			if nil == controlTable.preq or not tContains(controlTable.preq, numeric) then
				if '' == code or 'A' == code or 'B' == code or 'C' == code or 'D' == code or 'E' == code or 'H' == code or 'O' == code or 'X' == code then
					controlTable.questId = numeric
					Grail._GetPrerequisiteInfo(controlTable)
				elseif 'V' == code or 'W' == code or 'w' == code then
					local questTable = Grail.questStatusCache.G[subcode] or {}
					for _, questId in pairs(questTable) do
						controlTable.questId = questId
						Grail._GetPrerequisiteInfo(controlTable)
					end
				else
					-- do nothing since we do not care about this code
				end
			end
		end,

		--	Internal Use.
		--	This routine will process the provided codeString using the internal structure
		--	convention of , indicating logical OR, + indicating logical AND, and | indicating
		--	logical OR within an AND.  In other words we do not use parentheses, but instead
		--	change the symbol used for OR based on whether it is governed by an AND.
		--	The controlTable is used to pass in some more parameters:
		--		lastIndexUsed
		--		doMath
		--		func		=> the actual function that will do the real work
		_ProcessCodeString = function(codeString, controlTable)
			codeString, controlTable = (codeString or ""), (controlTable or {})
			local index, doMath, func = (controlTable.lastIndexUsed or 0), controlTable.doMath, (controlTable.func or Grail._ProcessCodeStringPrintFunction)
			local start, length = 1, strlen(codeString)
			local stop = length
			local orIndex = 0
			local commaCount = 0
			for i in strgmatch(codeString, ",") do commaCount = commaCount + 1 end
			while start <= length do
				local foundComma = strfind(codeString, ",", start, true)
				stop = foundComma and (foundComma - 1) or length
				local orItem = strsub(codeString, start, stop)
				local orStart, orLength = 1, strlen(orItem)
				local orStop = orLength
				orIndex = orIndex + 1
				local plusCount = 0
				for i in strgmatch(orItem, "+") do plusCount = plusCount + 1 end
				if doMath then index = index + 1 end
				local andIndex = 0
				while orStart <= orLength do
					local foundPlus = strfind(orItem, "+", orStart, true)
					orStop = foundPlus and (foundPlus - 1) or orLength
					local andItem = strsub(orItem, orStart, orStop)
					local andStart, andLength = 1, strlen(andItem)
					local andStop = andLength
					andIndex = andIndex + 1
					local pipeCount = 0
					for i in strgmatch(andItem, "|") do pipeCount = pipeCount + 1 end
					local useIndex2 = (0 < pipeCount)
					local pipeIndex = 0
					while andStart <= andLength do
						local foundPipe = strfind(andItem, "|", andStart, true)
						andStop = foundPipe and (foundPipe - 1) or andLength
						local innorItem = strsub(andItem, andStart, andStop)
						pipeIndex = pipeIndex + 1
						if func then
							controlTable.codeString, controlTable.orItem, controlTable.andItem, controlTable.innorItem = codeString, orItem, andItem, innorItem
							controlTable.index, controlTable.useIndex2, controlTable.pipeIndex, controlTable.orIndex, controlTable.andIndex = index, useIndex2, pipeIndex, orIndex, andIndex
							controlTable.commaCount, controlTable.plusCount, controlTable.pipeCount = commaCount, plusCount, pipeCount
							func(controlTable)
						end
						andStart = andStop + 2
					end
					orStart = orStop + 2
				end
				start = stop + 2
			end
			return index
		end,

		--	Internal Use.
		--	This routine is the default function that is used to print a codeString's structure
		--	from _ProcessCodeString() if no function is provided by the caller.
		_ProcessCodeStringPrintFunction = function(controlTable)
			local codeString = controlTable.codeString or "<NIL>"
			print(strgsub(codeString, "|", "*"), "=>", strgsub(controlTable.orItem, "|", "*"), strgsub(controlTable.andItem, "|", "*"), controlTable.innorItem)
		end,

		--	Internal Use.
		--	This routine is the same as _ProcessCodeString() except it uses the original table structure
		--	instead of the codeString.  If it is passed a codeString it will call _ProcessCodeString()
		--	to do the work instead.
		_ProcessCodeTable = function(table, controlTable)
			controlTable = controlTable or {}
			local index, doMath, func = (controlTable.lastIndexUsed or 0), controlTable.doMath, (controlTable.func or Grail._ProcessCodeStringPrintFunction)
			if nil == table then return index end
			if "table" ~= type(table) then return Grail._ProcessCodeString(table, controlTable) end
			local commaCount = #table
			local orIndex = 0
			for key, value in pairs(table) do
				orIndex = orIndex + 1
				if doMath then index = index + 1 end
				local valueToUse = ("table" == type(value)) and value or {value}
				local plusCount = #valueToUse
				local andIndex = 0
				for key2, value2 in pairs(valueToUse) do
					andIndex = andIndex + 1
					local valueToUse2 = ("table" == type(value2)) and value2 or {value2}
					local pipeCount = #valueToUse2
					local useIndex2 = (1 < #valueToUse2)
					local pipeIndex = 0
					for key3, value3 in pairs(valueToUse2) do
						pipeIndex = pipeIndex + 1
						if func then
							controlTable.codeString, controlTable.orItem, controlTable.andItem, controlTable.innorItem = nil, value, value2, value3
							controlTable.index, controlTable.useIndex2, controlTable.pipeIndex, controlTable.orIndex, controlTable.andIndex = index, useIndex2, pipeIndex, orIndex, andIndex
							controlTable.commaCount, controlTable.plusCount, controlTable.pipeCount = commaCount, plusCount, pipeCount
							func(controlTable)
						end
					end
				end
			end
			return index
		end,

		--	Internal Use.
		--	Routine used by the OnUpdate system to process notifications that have been put into a queue for delayed
		--	processing.  When the last notification is removed from the queue, the notificationFrame will have its
		--	OnUpdate script removed.
		_ProcessDelayedNotifications = function(self, ignoredElapsed)
			local now = GetTime()	-- if now > "fire trigger" we post the associated notification
			local newNotificationTable = {}
			for _, t in pairs(self.delayedNotifications) do
				if now > t["f"] then
					self:_PostNotification(t["n"], t["q"])
				else
					tinsert(newNotificationTable, t)
				end
			end
			self.delayedNotifications = newNotificationTable
			if 0 == #(self.delayedNotifications) then
				self.notificationFrame:SetScript("OnUpdate", nil)
			end
		end,

		--	This routine takes a structure of prerequisites in their raw string form and processes them
		--	so any quests in the prerequisites that are in fact flag quests marked with J: codes will
		--	have them processed so no quests with J: codes will appear in the list of prerequisites.
-- TODO: This routine has to deal with a string structure. Basically any quest
--	can have a J code associated with them.  So, quest 777777 could have J:111111,222222 which would mean that any
--	quest having a prerequisite with 777777 in it would need to logically change that 7777777 into 111111,222222
--	which can get quite interesting.
		_ProcessForFlagQuests = function(self, preqsString, controlTable)
			local controlTable = controlTable or { preq = {}, something = "", func = self._ProcessForFlagQuestsSupport }
print("Processing for flags:", strgsub(preqsString, "|", "*"))
			self._ProcessCodeTable(preqsString, controlTable)
print("end:", strgsub(controlTable.something, "|", "*"))
			return controlTable.something
		end,

		_ProcessForFlagQuestsSupport = function(controlTable)
			local code, subcode, numeric = Grail:CodeParts(controlTable.innorItem)
			local stringToAdd = controlTable.innorItem
			if '' == code or 'A' == code or 'B' == code or 'C' == code or 'D' == code or 'E' == code or 'H' == code or 'O' == code or 'X' == code then
				local flags = Grail:QuestFlags(numeric, true)
				if nil ~= flags then
					local innerControlTable = { preq = controlTable.preq, something = "", func = controlTable.func }
					stringToAdd = Grail:_ProcessForFlagQuests(flags, innerControlTable)
				end
			end
			local controlToAdd = ""
			if 1 < controlTable.pipeIndex then
				controlToAdd = "|"
			elseif 1 < controlTable.andIndex then
				controlToAdd = "+"
			elseif 1 < controlTable.orIndex then
				controlToAdd = ","
			end
			controlTable.something = controlTable.something .. controlToAdd .. stringToAdd
		end,

		--	Internal Use.
		_ProcessNPCs = function(self, originalMem)
			local debugStartTime = debugprofilestop()
			local N = self.npc
			if nil == self.npcs then
				print("|cFFFF0000Grail|r: abandoned NPC processing because none loaded")
				return
			end
			N.rawLocations = {}
			for key, value in pairs(self.npcs) do
				if value[1] then
					N.locations[key] = {}
					local codeArray = { strsplit(" ", value[1]) }
					local controlCode
					for _, code in pairs(codeArray) do
						controlCode = strsub(code, 1, 1)
						if 'A' == controlCode then
							if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
								local alias = tonumber(strsub(code, 3))
								if nil ~= alias then
									N.nameIndex[key] = alias
									N.aliases[alias] = N.aliases[alias] or {}
									tinsert(N.aliases[alias], key)
								else
									print("*** NPC processing of",key,"has improper alias")
								end
							end
						elseif 'C' == controlCode then
							tinsert(N.locations[key], { created = true })
						elseif 'D' == controlCode then
							if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
								N.droppedBy[key] = N.droppedBy[key] or {}
								local npcIds = { strsplit(',', strsub(code, 3)) }
								for _, anNPCId in pairs(npcIds) do
									local npcNumber = tonumber(anNPCId)
									if nil ~= npcNumber then
										tinsert(N.droppedBy[key], npcNumber)
										N.has[npcNumber] = N.has[npcNumber] or {}
										tinsert(N.has[npcNumber], key)
									end
								end
							end
						elseif 'F' == controlCode then
							if 'FA' == code then
								N.faction[key] = 'A'
							elseif 'FH' == code then
								N.faction[key] = 'H'
							end
--							if 1 < strlen(code) then
--								N.faction[key] = strsub(code, 2, 2)
--							end
						elseif 'H' == controlCode then
							-- the "has" codes are deprecated as we will populate the data based on "drop" codes instead
							if 2 < strlen(code) then
								local subcode = strsub(code, 2, 2)
								if ':' ~= subcode then
									local holidays = N.holiday[key]
									if nil == holidays then
										holidays = ''
									end
									N.holiday[key] = holidays .. subcode
								end
							end
						elseif 'K' == controlCode then
							if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
								N.kill[key] = N.kill[key] or {}
								local questList = { strsplit(',', strsub(code, 3)) }
								for _, questId in pairs(questList) do
									tinsert(N.kill[key], tonumber(questId))
								end
							end
						elseif 'M' == controlCode then
							local t1 = { mailbox = true }
							if 7 < strlen(code) then
								t1.mapArea = tonumber(strsub(code, 8))
							end
							tinsert(N.locations[key], t1)
						elseif 'N' == controlCode then
							if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
								local nameIndexToUse = tonumber(strsub(code, 3))
								N.nameIndex[key] = nameIndexToUse
							else
								local t1 = { near = true }
								if 4 < strlen(code) then
									t1.mapArea = tonumber(strsub(code, 5))
								end
								tinsert(N.locations[key], t1)
							end
						elseif 'P' == controlCode then
							-- we do nothing special for "Preowned" at the moment
						elseif 'Q' == controlCode then
							if 2 < strlen(code) and ':' == strsub(code, 2, 2) then
								N.questAssociations[key] = N.questAssociations[key] or {}
								local questList = { strsplit(',', strsub(code, 3)) }
								for _, questId in pairs(questList) do
									tinsert(N.questAssociations[key], tonumber(questId))
								end
							end
						elseif 'S' == controlCode then
							-- we do nothing special for "Self" at the moment
						elseif 'X' == controlCode then
							N.heroic[key] = true
						elseif 'Z' == controlCode then
							tinsert(N.locations[key], { ["mapArea"]=tonumber(strsub(code, 2)) })
						else	-- a real coordinate
							tinsert(N.locations[key], Grail:_LocationStructure(code))
							--	If this quest is a world quest location (NPC ID which is negative), it should be added to the _worldQuestSelfNPCs structure.
							local keyAsNumber = tonumber(key)
							if keyAsNumber and keyAsNumber < 0 then
								local mapId, coordinates = strsplit(':', code)
								mapId = tonumber(mapId)
								if nil ~= mapId then
									self._worldQuestSelfNPCs[mapId] = self._worldQuestSelfNPCs[mapId] or {}
									self._worldQuestSelfNPCs[mapId][coordinates] = keyAsNumber
								end
							end
						end
					end
				end
				if value[2] then N.comment[key] = value[2] end
				if value[3] then N.faction[key] = value[3] end
			end
			-- TODO: Go through all the Grail.npc.droppedBy values and make sure the locations for the NPCs are added to those keys
			self.npcs = nil
			self.memoryUsage.NPCs = gcinfo() - originalMem
			self.timings.ProcessNPCInformation = debugprofilestop() - debugStartTime
		end,

		--	Internal Use.
		--	This looks at the quest codes in the table to determine whether any of them require entries to be made in the
		--	questStatusCache structure which is used to invalidate quests based on how quests interrelate and happenings
		--	in the environment.  It calls a support routine to do the dirty work as this just iterates through the table
		--	contents.  The support routine uses a mapping to take quest codes and assign them to the proper internal table
		--	entries.
		_ProcessQuestsForHandlers = function(self, questId, tableOrString, destinationTable)
			local controlTable = { questId = questId, output1 = destinationTable, func = self._ProcessQuestsForHandlersSupport }
			self._ProcessCodeTable(tableOrString, controlTable)
		end,

		_ProcessQuestsForHandlersMapping = { ["B"] = 'D', ["D"] = 'D', ["e"] = 'D', ["I"] = 'B', ["J"] = 'A', ["K"] = 'C', ["L"] = 'E', ["M"] = 'F', ['m'] = 'F', ["R"] = 'R', ["S"] = 'Y', ["V"] = 'X', ["W"] = 'W', ["w"] = 'W', ["Y"] = 'B', ["Z"] = 'Z' },

		-- This gets called when prerequisite codes are processed to determine what caches should contain the quests in question.
		_ProcessQuestsForHandlersSupport = function(controlTable)
			local self = Grail
			local destinationTable, questId = (controlTable.output1 or self.questStatusCache), controlTable.questId
			local code, subcode, numeric = self:CodeParts(controlTable.innorItem)
			if 't' == code or 'u' == code then numeric = numeric * -1 end
			local mappedCode = self._ProcessQuestsForHandlersMapping[code]
			if nil ~= mappedCode then
				-- If we have a prerequisite that deals with an item and the quest also has a V code for that same item process it
				if code == 'K' then
					numeric = tonumber(numeric)
					local foundCode, codeValue = self:_QuestCode(questId, 'V')
-- Cannot use the following because we cannot guarantee that the V code will be processed first (which it is not with the current ordering)
--					local table = self.questStatusCache.questToItemCountGroup[questId]
--					if nil ~= table and tContains(table, numeric) then
					if nil ~= codeValue and tonumber(codeValue) == numeric then
						self.questStatusCache.itemCountGroupToQuest[numeric] = self.questStatusCache.itemCountGroupToQuest[numeric] or {}
						self.questStatusCache.itemCountGroupToQuest[numeric][questId] = tonumber(subcode)
					end
				end
				destinationTable[mappedCode] = destinationTable[mappedCode] or {}
				destinationTable[mappedCode][numeric] = destinationTable[mappedCode][numeric] or {}
				tinsert(destinationTable[mappedCode][numeric], questId)
			elseif 'L' == code then
				if Grail.levelingLevel < numeric then
					tinsert(destinationTable.L, questId)
				end
			elseif 'P' == code then
				self:AddQuestToMapArea(questId, tonumber(self.professionToMapAreaMapping['P'..subcode]), self.professionMapping[subcode])
			elseif 'T' == code or 't' == code or 'U' == code or 'u' == code then
				self.questReputationRequirements[questId] = (self.questReputationRequirements[questId] or "") .. self:_ReputationCode(subcode..numeric)
			elseif 'G' == code or 'z' == code then
				destinationTable.M = destinationTable.M or {}
				local buildingIds, t
				if numeric < 0 then
					buildingIds = Grail.garrisonBuildingMapping[numeric]
				else
					buildingIds = { numeric }
				end
				for _, buildingId in pairs(buildingIds) do
					t = destinationTable.M[buildingId] or {}
					if not tContains(t, questId) then
						tinsert(t, questId)
					end
					destinationTable.M[buildingId] = t
				end
			elseif 'x' ==  code then
				self.invalidateControl[self.invalidateGroupArtifactKnowledge] = self.invalidateControl[self.invalidateGroupArtifactKnowledge] or {}
				tinsert(self.invalidateControl[self.invalidateGroupArtifactKnowledge], questId)
			elseif '@' == code then
				-- This is implemented quite simply to say that any quest that has an artifact level requirement will be invalidated
				-- if there is a change in any artifact level, not examining the actual artifact involved in the change.
				local t = self.invalidateControl[self.invalidateGroupArtifactLevel] or {}
				if not tContains(t, questId) then
					tinsert(t, questId)
				end
				self.invalidateControl[self.invalidateGroupArtifactLevel] = t
			elseif '$' == code or '*' == code then
				-- This is implemented quite simply to say that any quest that has a renown requirement will be invalidated when renown level changes.
				local t = self.invalidateControl[self.invalidateGroupRenownQuests] or {}
				if not tContains(t, questId) then
					tinsert(t, questId)
				end
				self.invalidateControl[self.invalidateGroupRenownQuests] = t
			elseif '%' == code then
				-- This is implemented quite simply to say that any quest that has a garrison talent requirement will be invalidated when talents change.
				local t = self.invalidateControl[self.invalidateGroupCurrentGarrisonTalentQuests] or {}
				if not tContains(t, questId) then
					tinsert(t, questId)
				end
				self.invalidateControl[self.invalidateGroupCurrentGarrisonTalentQuests] = t
			elseif 'v' == code then
				-- TODO: We should take all these quests and put them into a table that is invalidated when the weekly reset happens (even though that is a pain to determine)
			elseif '(' == code then
				-- TODO: We should take all these quests and put them into a table that is invalidated when the daily reset happens (even though that is a pain to determine)
			elseif ')' == code then
				-- TODO: We should take all these quests and put them into a table that is invalidated when curreny amounts change (not sure we should really care about matching currencies, though it would be better for overall performance I guess)
			elseif '_' == code or '~' == code then
				-- This records a quest to be invalidated if ANY of the major faction renown levels change
				local t = self.invalidateControl[self.invalidateGroupMajorFactionQuests] or {}
				if not tContains(t, questId) then
					tinsert(t, questId)
				end
				self.invalidateControl[self.invalidateGroupMajorFactionQuests] = t
			elseif '`' == code then
				-- This records a quest to be invalidated if ANY area POI change happens
				local t = self.invalidateControl[self.invalidateGroupAreaPOIQuests] or {}
				if not tContains(t, questId) then
					tinsert(t, questId)
				end
				self.invalidateControl[self.invalidateGroupAreaPOIQuests] = t
			end
		end,

		-- >>>WARBAND_DEBUG_BEGIN: detects account-wide quests completed while logged out
		-- Remove entire block when no longer needed
		_CheckWarbandQuestChanges = function(self, triggerEvent)
			local _sv, _mv = self.GDE.silent, self.manuallyExecutingServerQuery
			self.GDE.silent, self.manuallyExecutingServerQuery = true, false
			QueryQuestsCompleted()
			local db = GrailDatabasePlayer
			local coords = tostring(self:Coordinates())
			-- If no backup exists, do a first-time scan: find quests the server reports
			-- as complete that Grail knows about but hasn't recorded yet.
			if nil == db['backupCompletedQuests'] then
				local count = 0
				for index, bits in pairs(db['completedQuests'] or {}) do
					for i = 0, 31 do
						if bitband(bits, 2^i) > 0 then
							local qId = index * 32 + i + 1
							local title = self:QuestName(qId) or 'UNKNOWN'
							local msg = strformat('WARBAND_QUEST_COMPLETE [first-login]: quest=%d title=%s coords=%s',
								qId, title, coords)
							print(msg)
							self:_AddTrackingMessage(msg)
							count = count + 1
						end
					end
				end
				if count > 0 then
					print(strformat('WARBAND: first-login scan found %d known completed quests', count))
				end
				self:_ProcessServerBackup(true)
				return
			end
			-- Normal compare against existing backup
			local newlyCompleted, newlyLost = {}, {}
			self:_ProcessServerCompare(newlyCompleted, newlyLost)
			for _, qId in ipairs(newlyCompleted) do
				self:_MarkQuestComplete(qId, true)
				local title = self:QuestName(qId) or 'UNKNOWN'
				local msg = strformat('WARBAND_QUEST_COMPLETE [%s]: quest=%d title=%s coords=%s',
					triggerEvent, qId, title, coords)
				print(msg)
				self:_AddTrackingMessage(msg)
			end
			for _, qId in ipairs(newlyLost) do
				local title = self:QuestName(qId) or 'UNKNOWN'
				local msg = strformat('WARBAND_QUEST_LOST [%s]: quest=%d title=%s coords=%s',
					triggerEvent, qId, title, coords)
				print(msg)
				self:_AddTrackingMessage(msg)
			end
			if #newlyCompleted > 0 or #newlyLost > 0 then
				self:_ProcessServerBackup(true)
			end
		end,
		-- >>>WARBAND_DEBUG_END

		-- >>>QUESTPIN_DEBUG_BEGIN: remove this entire block when no longer needed
		-- Pool-only snapshot: only includes pins currently visible in WorldMapFrame pools.
		-- Use this for QUEST_PIN_LINK diffs to avoid false positives from GetQuestsOnMap.
		_QuestPinPoolSnapshot = function(self)
			local snapshot = {}
			local startMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
			if not startMapID then return snapshot end
			-- Scan QuestHub dataProvider.questOffers
			if WorldMapFrame and WorldMapFrame.pinPools then
				local hubPool = WorldMapFrame.pinPools['QuestHubPinTemplate']
				if hubPool then
					local hubPins = {}
					pcall(function() for pin in hubPool:EnumerateActive() do table.insert(hubPins, pin) end end)
					for _, hpin in ipairs(hubPins) do
						if hpin.dataProvider and hpin.dataProvider.questOffers then
							for qid, qinfo in pairs(hpin.dataProvider.questOffers) do
								qid = tonumber(qid)
								if qid then
									local key = strformat('offer:%d', qid)
									if not snapshot[key] then
										snapshot[key] = { questId=qid, pinType='hub_offer',
											name=qinfo.questName,
											hubPoiID=hpin.poiInfo and hpin.poiInfo.areaPoiID,
											hubName=hpin.name or (hpin.poiInfo and hpin.poiInfo.name),
											coords=strformat('%d:%.2f,%.2f', startMapID, (qinfo.x or 0)*100, (qinfo.y or 0)*100) }
									end
								end
							end
						end
					end
				end
				-- Scan QuestOffer/QuestPin pools
				local questPools = { QuestOfferPinTemplate=true, QuestPinTemplate=true }
				for poolKey in pairs(questPools) do
					local pool = WorldMapFrame.pinPools[poolKey]
					if pool then
						local _pins = {}
						if pool.activeObjects then
							for pin in pairs(pool.activeObjects) do table.insert(_pins, pin) end
						elseif type(pool.EnumerateActive) == 'function' then
							pcall(function() for pin in pool:EnumerateActive() do table.insert(_pins, pin) end end)
						end
						for _, pin in ipairs(_pins) do
							local qid = pin.questID
							if qid and qid > 0 then
								local key = strformat('offer:%d', qid)
								if not snapshot[key] then
									snapshot[key] = { questId=qid,
										pinType=pin.isCampaign and 'campaign_offer' or 'offer',
										isCampaign=pin.isCampaign, questLineID=pin.questLineID,
										questLineName=pin.questLineName, name=pin.questName,
										coords=strformat('%d:%.2f,%.2f', startMapID,
											(pin.normalizedX or 0)*100, (pin.normalizedY or 0)*100) }
								end
							end
						end
					end
				end
			end
			-- Scan C_TaskQuest.GetQuestsOnMap for Bonus Objectives / Task Quests
			if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
				local tasks = C_TaskQuest.GetQuestsOnMap(startMapID)
				if tasks then
					for _, task in ipairs(tasks) do
						local qid = tonumber(task.questID)
						if qid then
							local key = strformat('task:%d', qid)
							if not snapshot[key] then
								snapshot[key] = {
									questId    = qid,
									pinType    = 'task',
									inProgress = task.inProgress,
									coords     = strformat('%d:%.2f,%.2f', startMapID,
										(task.x or 0)*100, (task.y or 0)*100),
								}
							end
						end
					end
				end
			end
			return snapshot
		end,

		_QuestPinSnapshot = function(self)
			local snapshot = {}
			local startMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
			if not startMapID then return snapshot end
			-- Walk the full map hierarchy so parent-map pins are included
			local mapID = startMapID
			for depth = 1, 5 do
				if not mapID then break end
				if C_QuestLog and C_QuestLog.GetQuestsOnMap then
					local pins = C_QuestLog.GetQuestsOnMap(mapID)
					if pins then
						for _, pin in ipairs(pins) do
							local qid = tonumber(pin.questID)
							if qid then
								snapshot[strformat('offer:%d', qid)] = {
									questId    = qid,
									pinType    = pin.isCampaign and 'campaign_offer' or 'offer',
									isCampaign = pin.isCampaign,
									coords     = strformat('%d:%.2f,%.2f', mapID, (pin.x or 0)*100, (pin.y or 0)*100),
								}
							end
						end
					end
				end
				if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap then
					local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
					if pois then
						for _, poiID in ipairs(pois) do
							local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
							if info and info.atlasName and strfind(info.atlasName, '[Qq]uest') then
								snapshot[strformat('hub:%d', poiID)] = {
									questId = poiID, pinType = 'hub', name = info.name, atlas = info.atlasName,
									coords  = strformat('%d:%.2f,%.2f', mapID,
										(info.position and info.position.x or 0)*100,
										(info.position and info.position.y or 0)*100),
								}
							end
						end
					end
				end
				local mapInfo = C_Map.GetMapInfo(mapID)
				mapID = mapInfo and mapInfo.parentMapID
			end
			-- Scan QuestHub dataProvider.questOffers for hub-child quests (e.g. weekly quests)
			if WorldMapFrame and WorldMapFrame.pinPools then
				local hubPool = WorldMapFrame.pinPools['QuestHubPinTemplate']
				if hubPool then
					local hubPins = {}
					pcall(function() for pin in hubPool:EnumerateActive() do table.insert(hubPins, pin) end end)
					for _, hpin in ipairs(hubPins) do
						local dp = hpin.dataProvider
						if dp and dp.questOffers then
							for qid, qinfo in pairs(dp.questOffers) do
								qid = tonumber(qid)
								if qid then
									local key = strformat('offer:%d', qid)
									if not snapshot[key] then
										snapshot[key] = {
											questId    = qid,
											pinType    = 'hub_offer',
											name       = qinfo.questName,
											hubPoiID   = hpin.poiInfo and hpin.poiInfo.areaPoiID,
											hubName    = hpin.name or (hpin.poiInfo and hpin.poiInfo.name),
											coords     = strformat('%d:%.2f,%.2f', startMapID,
												(qinfo.x or 0)*100, (qinfo.y or 0)*100),
										}
									end
								end
							end
						end
					end
				end
			end
			-- Scan active WorldMapFrame pools when map is open (captures campaign pins)
			if WorldMapFrame and WorldMapFrame.pinPools then
				local questPools = { QuestOfferPinTemplate=true, QuestHubPinTemplate=true, QuestPinTemplate=true }
				for poolKey in pairs(questPools) do
					local pool = WorldMapFrame.pinPools[poolKey]
					if pool then
						local _pins = {}
						if pool.activeObjects then
							for pin in pairs(pool.activeObjects) do table.insert(_pins, pin) end
						elseif type(pool.EnumerateActive) == 'function' then
							pcall(function() for pin in pool:EnumerateActive() do table.insert(_pins, pin) end end)
						end
						for _, pin in ipairs(_pins) do
							local qid = pin.questID
							if qid and qid > 0 then
								local key = strformat('offer:%d', qid)
								if not snapshot[key] then
									snapshot[key] = {
										questId       = qid,
										pinType       = pin.isCampaign and 'campaign_offer' or 'offer',
										isCampaign    = pin.isCampaign,
										questLineID   = pin.questLineID,
										questLineName = pin.questLineName,
										name          = pin.questName,
										coords        = strformat('%d:%.2f,%.2f', startMapID,
											(pin.normalizedX or 0)*100, (pin.normalizedY or 0)*100),
									}
								end
							end
						end
					end
				end
			end
			-- Scan C_QuestLine for campaign quests not in GetQuestsOnMap
			if C_QuestLine and C_QuestLine.GetAvailableQuestLines and C_QuestLine.GetQuestsForQuestLine then
				local qlines = C_QuestLine.GetAvailableQuestLines(startMapID)
				if qlines then
					for _, ql in ipairs(qlines) do
						local quests = C_QuestLine.GetQuestsForQuestLine(ql.questLineID, startMapID)
						if quests then
							for _, qinfo in ipairs(quests) do
								local qid = qinfo.questID
								if qid and not snapshot[strformat('offer:%d', qid)] then
									snapshot[strformat('offer:%d', qid)] = {
										questId      = qid,
										pinType      = 'campaign_offer',
										isCampaign   = true,
										questLineID  = ql.questLineID,
										questLineName= ql.questLineName,
											name         = qinfo.questName or (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid)),
										coords       = strformat('%d:%.2f,%.2f', startMapID,
											(qinfo.x or 0)*100, (qinfo.y or 0)*100),
									}
								end
							end
						end
					end
				end
			end
			-- Scan C_TaskQuest.GetQuestsOnMap for Bonus Objectives / Task Quests
			if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
				local tasks = C_TaskQuest.GetQuestsOnMap(startMapID)
				if tasks then
					for _, task in ipairs(tasks) do
						local qid = tonumber(task.questID)
						if qid then
							local key = strformat('task:%d', qid)
							if not snapshot[key] then
								snapshot[key] = { questId=qid, pinType='task', inProgress=task.inProgress,
									coords=strformat('%d:%.2f,%.2f', startMapID, (task.x or 0)*100, (task.y or 0)*100) }
							end
						end
					end
				end
			end
			return snapshot
		end,

		_QuestPinCompareAndRecord = function(self, before, after, trigger, triggerDetail)
			local db = GrailDatabase
			db.questPinEvents     = db.questPinEvents or {}
			db.questPinEventIndex = db.questPinEventIndex or {}
			local coords = tostring(self:Coordinates())
			local now    = GetTime()
			local count  = 0
			local baseWasEmpty = (next(before) == nil)
			for key, info in pairs(before) do
				if not after[key] then
					local idxKey = strformat('%s|disappeared|%s', key, trigger)
					if not db.questPinEventIndex[idxKey] then
						db.questPinEventIndex[idxKey] = true
						table.insert(db.questPinEvents, { questId=info.questId, pinType=info.pinType, event='disappeared',
							trigger=trigger, triggerDetail=triggerDetail, coords=info.coords or coords,
							name=info.name, atlas=info.atlas, time=now })
						count = count + 1
						local msg = strformat('QUESTPIN: disappeared questId=%s type=%s | trigger=%s %s | coords=%s',
							tostring(info.questId), tostring(info.pinType), trigger, tostring(triggerDetail), info.coords or coords)
						print(msg)
						self:_AddTrackingMessage(msg)
						-- Link disappeared pin to the quest that triggered its removal
						local pinQuestStr = 'none'
						if nil ~= self._recentlyCompletedQuestIds then
							local qList = {}
							for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
								if (now - qTime) <= 10 then table.insert(qList, tostring(qId)) end
							end
							if #qList > 0 then pinQuestStr = table.concat(qList, ',') end
						end
						self:_RecordQuestPinLink(key, info.pinType, info.name,
							strformat('%s|disappeared', pinQuestStr), info.coords or coords, baseWasEmpty)
					end
				end
			end
			for key, info in pairs(after) do
				if not before[key] then
					local idxKey = strformat('%s|appeared|%s', key, trigger)
					if not db.questPinEventIndex[idxKey] then
						db.questPinEventIndex[idxKey] = true
						table.insert(db.questPinEvents, { questId=info.questId, pinType=info.pinType, event='appeared',
							trigger=trigger, triggerDetail=triggerDetail, coords=info.coords or coords,
							name=info.name, atlas=info.atlas, time=now })
						count = count + 1
						local msg = strformat('QUESTPIN: appeared questId=%s type=%s | trigger=%s %s | coords=%s',
							tostring(info.questId), tostring(info.pinType), trigger, tostring(triggerDetail), info.coords or coords)
						print(msg)
						self:_AddTrackingMessage(msg)
						-- Store for reverse quest→pin lookup in _MarkQuestComplete
						self._recentlyAppearedPins = self._recentlyAppearedPins or {}
						self._recentlyAppearedPins[key] = { pinType=info.pinType, name=info.name, coords=info.coords or coords, time=now }
						-- Forward pin→quest link: check recent completed quests
						local pinQuestStr = 'none'
						if nil ~= self._recentlyCompletedQuestIds then
							local qList = {}
							for qId, qTime in pairs(self._recentlyCompletedQuestIds) do
								if (now - qTime) <= 10 then table.insert(qList, tostring(qId)) end
							end
							if #qList > 0 then pinQuestStr = table.concat(qList, ',') end
						end
						self:_RecordQuestPinLink(key, info.pinType, info.name, pinQuestStr, info.coords or coords, baseWasEmpty)
					end
				end
			end
			return count
		end,

		_QuestPinLinkKey = function(self, pinKey, source)
			return strformat('%s|%s', tostring(pinKey), tostring(source))
		end,

		_IsNewQuestPinLink = function(self, pinKey, source)
			local db = GrailDatabase
			if not self._questPinLinkIndexBuilt then
				self._questPinLinkIndexBuilt = true
				db.questPinLinks     = db.questPinLinks or {}
				db.questPinGuidIndex = db.questPinGuidIndex or {}
				if next(db.questPinLinks) == nil and db.Tracking then
					for _, entry in ipairs(db.Tracking) do
						local p, s = strmatch(entry, 'QUEST_PIN_LINK: pin=(%S+).-|%s*(%w[^|]+)%s*|%s*coords=')
						if p and s then
							local k = self:_QuestPinLinkKey(p, strtrim(s))
							db.questPinLinks[k] = true
							db.questPinGuidIndex[p] = k
						end
					end
				end
			end
			local key = self:_QuestPinLinkKey(pinKey, source)
			if db.questPinLinks[key] then return false end
			-- Check for upgradeable entry (quests=none)
			local existingKey = db.questPinGuidIndex and db.questPinGuidIndex[pinKey]
			if existingKey and db.questPinLinks[existingKey] then
				local incomplete = strfind(existingKey, 'quests=none', 1, true)
				local hasQuest   = not strfind(source, 'quests=none', 1, true)
				if incomplete and hasQuest then
					db.questPinLinks[existingKey] = nil
					db.questPinLinks[key] = true
					db.questPinGuidIndex[pinKey] = key
					if db.Tracking then
						local oldPinPart = strformat('pin=%s', pinKey)
						for i, entry in ipairs(db.Tracking) do
							if strfind(entry, oldPinPart, 1, true) and strfind(entry, 'quests=none', 1, true) then
								db.Tracking[i] = gsub(entry, 'quests=none', strformat('quests=%s [updated]', strmatch(source, 'quests=([^|]+)') or '?'))
								print(strformat('QUEST_PIN_LINK_UPDATED: %s', db.Tracking[i]))
								break
							end
						end
					end
					return true
				end
			end
			db.questPinLinks[key] = true
			db.questPinGuidIndex[pinKey] = key
			return true
		end,

		-- Writes a QUEST_PIN_LINK entry if not already known.
		_RecordQuestPinLink = function(self, pinKey, pinType, pinName, questStr, coords, baseWasEmpty)
			-- Skip appeared pins with quests=none only when snapshot was empty (first map view)
			if questStr == 'none' and baseWasEmpty and not strfind(tostring(pinKey), 'disappeared', 1, true) then return end
			local source = strformat('quests=%s | coords=%s', questStr, tostring(coords))
			if self:_IsNewQuestPinLink(pinKey, source) then
				local msg = strformat('QUEST_PIN_LINK: pin=%s type=%s name=%s | %s',
					tostring(pinKey), tostring(pinType), tostring(pinName), source)
				print(msg)
				self:_AddTrackingMessage(msg)
			end
		end,

		-- >>>QUESTPIN_DEBUG_END

		-- >>>GOSSIP_DEBUG
		_RecordGossipQuestLink = function(self, questId, npcId, npcName, optionName, optionId, coords)
			-- Skip if no gossip option was involved
			if nil == optionId and nil == optionName then return end
			local db = GrailDatabase
			db.gossipQuestLinks = db.gossipQuestLinks or {}
			local key = strformat('%d|%s|%s', questId, tostring(npcId), tostring(optionId))
			if db.gossipQuestLinks[key] then return end
			db.gossipQuestLinks[key] = true
			local msg = strformat('GOSSIP_QUEST_LINK: quest=%d npc=%s(%s) option=%s(id=%s) coords=%s',
				questId, tostring(npcName), tostring(npcId),
				tostring(optionName), tostring(optionId), tostring(coords))
			print(msg)
			self:_AddTrackingMessage(msg)
		end,
		-- >>>GOSSIP_DEBUG_END

		-- >>>VIGNETTE_DEBUG_BEGIN: remove this entire block when no longer needed
		_VignetteSnapshot = function(self)
			local snapshot = {}
			if C_VignetteInfo and C_VignetteInfo.GetVignettes then
				local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
				local vignettes = C_VignetteInfo.GetVignettes()
				if vignettes then
					for _, vignetteGUID in ipairs(vignettes) do
						local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
						if info then
							local coordStr = nil
							if mapID and C_VignetteInfo.GetVignettePosition then
								local pos = C_VignetteInfo.GetVignettePosition(vignetteGUID, mapID)
								if pos then
									coordStr = strformat('%d:%.2f,%.2f', mapID, pos.x * 100, pos.y * 100)
								end
							end
							snapshot[vignetteGUID] = { name=info.name, vignetteType=info.vignetteType, onMinimap=info.onMinimap, coords=coordStr }
						end
					end
				end
			end
			return snapshot
		end,

		_VignetteDumpAll = function(self, label)
			local snap = self:_VignetteSnapshot()
			local count = 0
			for _ in pairs(snap) do count = count + 1 end
			if count == 0 then return end
			-- Skip duplicate dumps: only print if content differs from last dump
			local fingerprint = ''
			for guid, info in pairs(snap) do
				fingerprint = fingerprint .. guid .. tostring(info.onMinimap)
			end
			if fingerprint == self._lastVignetteDumpFingerprint then return end
			self._lastVignetteDumpFingerprint = fingerprint
			-- Only show unknown vignettes
			local unknownSnap = {}
			for guid, info in pairs(snap) do
				if not self:_IsKnownVignetteType(guid) then unknownSnap[guid] = info end
			end
			local unknownCount = 0
			for _ in pairs(unknownSnap) do unknownCount = unknownCount + 1 end
			if unknownCount == 0 then return end
			print(strformat('VIGNETTE_DEBUG DUMP [%s]: total=%d (unknown=%d)', label, count, unknownCount))
			for guid, info in pairs(unknownSnap) do
				print(strformat('  VIG: GUID=%s name=%s type=%s minimap=%s', guid, tostring(info.name), tostring(info.vignetteType), tostring(info.onMinimap)))
			end
		end,

		_VignetteCompareAndLog = function(self, before, after, label) end,
		-- >>>VIGNETTE_DEBUG_END

		-- >>>VIGNETTE_DEBUG_BEGIN
		_VignetteLinkKey = function(self, guid, source)
			return strformat('%s|%s', tostring(guid), tostring(source))
		end,

		-- Returns the type ID (segment 6) from a vignette GUID.
		_VignetteTypeId = function(self, guid)
			return select(6, strsplit('-', tostring(guid)))
		end,

		-- Returns true if we have ever recorded a link for this vignette type ID.
		_IsKnownVignetteType = function(self, guid)
			if not self._knownVignetteTypeIds then
				self._knownVignetteTypeIds = {}
				local db = GrailDatabase
				if db.vignetteLinks then
					for key in pairs(db.vignetteLinks) do
						local g = strmatch(key, '^([^|]+)')
						if g then
							local typeId = self:_VignetteTypeId(g)
							if typeId then self._knownVignetteTypeIds[typeId] = true end
						end
					end
				end
			end
			local typeId = self:_VignetteTypeId(guid)
			return typeId and self._knownVignetteTypeIds[typeId] == true
		end,


		-- Returns true if this vignette+source combo is new (and registers it).
		-- On first call per session, rebuilds the index from GDE.Tracking.
		_IsNewVignetteLink = function(self, guid, source, name)
			local db = GrailDatabase
			-- vignetteLinks and vignetteGuidIndex are persistent in SavedVariables directly
			db.vignetteLinks     = db.vignetteLinks or {}
			db.vignetteGuidIndex = db.vignetteGuidIndex or {}
			-- One-time migration: import vignette links from Tracking if not yet in vignetteLinks
			if not self._vignetteLinkIndexBuilt then
				self._vignetteLinkIndexBuilt = true
				if db.Tracking then
					for _, entry in ipairs(db.Tracking) do
						if strfind(entry, 'VIGNETTE_', 1, true) then
							local g, s = strmatch(entry, 'vignette=(%S+).-|%s*(%w[^|]+)%s*|%s*coords=')
							if g and s and strsub(g, 1, 9) == 'Vignette-' then
								local k = self:_VignetteLinkKey(g, strtrim(s))
								if not db.vignetteLinks[k] then
									db.vignetteLinks[k] = true
									db.vignetteGuidIndex[g] = db.vignetteGuidIndex[g] or k
								end
							end
						end
					end
				end
			end
			local key = self:_VignetteLinkKey(guid, source)
			if db.vignetteLinks[key] then return false end
			-- Check if an existing entry for this GUID can be upgraded
			local existingKey = db.vignetteGuidIndex and db.vignetteGuidIndex[guid]
			if existingKey and db.vignetteLinks[existingKey] then
				local hasIncomplete = strfind(existingKey, 'quests=none', 1, true)
					or strfind(existingKey, 'npcId=nil', 1, true)
					or strfind(existingKey, '| coords=$', 1, false)
				local hasNewInfo = not strfind(source, 'quests=none', 1, true)
					and not strfind(source, 'npcId=nil', 1, true)
				if hasIncomplete and hasNewInfo then
					-- Upgrade: replace old entry with new one
					self:_UpgradeVignetteLink(guid, existingKey, key)
					return true
				end
					-- Valid complete entry exists for this GUID - skip
					if not hasIncomplete then return false end
			end
			db.vignetteLinks[key] = name or true
			db.vignetteGuidIndex[guid] = key
			if self._knownVignetteTypeIds then
				local typeId = self:_VignetteTypeId(guid)
				if typeId then self._knownVignetteTypeIds[typeId] = true end
			end
			return true
		end,

		-- Replaces an incomplete vignette link with a better one in DB and Tracking log.
		_UpgradeVignetteLink = function(self, guid, oldKey, newKey)
			local db = GrailDatabase
			local oldName = db.vignetteLinks[oldKey]
			db.vignetteLinks[oldKey] = nil
			db.vignetteLinks[newKey] = (type(oldName) == 'string' and oldName) or true
			db.vignetteGuidIndex[guid] = newKey
			-- Patch Tracking log: find old entry and replace with new message
			if db.Tracking then
				local oldGuidPart = strformat('vignette=%s', guid)
				for i, entry in ipairs(db.Tracking) do
					if strfind(entry, oldGuidPart, 1, true) then
						-- Build replacement from new key: extract fields
						local newFields = strmatch(newKey, '^[^|]+|(.+)$')
						local newEntry = strmatch(entry, '^(VIGNETTE[^:]*: vignette=%S+ name=[^|]+| )') or ''
						if newEntry ~= '' and newFields then
							db.Tracking[i] = newEntry .. newFields .. ' [updated]'
							print(strformat('VIGNETTE_LINK_UPDATED: %s', db.Tracking[i]))
						end
						break
					end
				end
			end
		end,
		-- >>>VIGNETTE_DEBUG_END

		_ProcessServerBackup = function(self, quiet)
			GrailDatabasePlayer["backupCompletedQuests"] = {}
			for i, v in pairs(GrailDatabasePlayer["completedQuests"]) do
				GrailDatabasePlayer["backupCompletedQuests"][i] = v
			end
			if not quiet then
				print("|cFFFFFF00Grail|r: A backup of the completed quests has been made")
			end
		end,

		--	This will figure out what quests are marked complete on the server and how that
		--	differs from what is recorded in the backup.  Assuming a recent backup of completed
		--	quests is recorded this can be used to determine what quests have just had their
		--	completed state change.  The two tables passed in can be used to return those
		--	changes.
		_ProcessServerCompare = function(self, newlyCompletedTable, newlyLostTable)
			local quiet = (newlyCompletedTable ~= nil or newlyLostTable ~= nil)
			local db = GrailDatabasePlayer
			if nil == db["backupCompletedQuests"] then print("|cFFFF0000Grail|r: Please do |cFF00FF00/grail backup|r first") return
			else if not quiet then print("|cFF00FF00Grail|r: Starting quest comparison between completed quests and backup") end end
			local indexesToCheck = {}
			for index, value in pairs(db["completedQuests"]) do
				if not tContains(indexesToCheck, index) then tinsert(indexesToCheck, index) end
			end
			for index in pairs(db["backupCompletedQuests"]) do
				if not tContains(indexesToCheck, index) then tinsert(indexesToCheck, index) end
			end
			local backup, current, diff, base, message
			for _, index in pairs(indexesToCheck) do
				backup = db["backupCompletedQuests"][index] or 0
				current = db["completedQuests"][index] or 0
				if current ~= backup then
					diff = bitbxor(current, backup)
					-- index 0 covers 1 - 32
					-- index 1 covers 33 - 64
					-- index 2 covers 65 - 96
					base = index * 32
					for i = 0, 31 do
						if bitband(diff, 2^i) > 0 then		-- this means there is a bit difference between backup and current
							local computedQuestId = base + i + 1
							local computedQuestName = self:QuestName(computedQuestId) or "UNKNOWN NAME"
							if bitband(current, 2^i) > 0 then	-- this means current is marked complete
								message = strformat("New quest completed %d %s", computedQuestId, computedQuestName)
								if newlyCompletedTable then tinsert(newlyCompletedTable, computedQuestId) end
							else
								message = strformat("New quest LOST %d %s", computedQuestId, computedQuestName)
								if newlyLostTable then tinsert(newlyLostTable, computedQuestId) end
							end
							if not quiet then
								print(message)
							end
							self:_AddTrackingMessage(message)
						end
					end
				end
			end
			if not quiet then
				print("|cFFFF0000Grail|r: End quest comparison")
			end
		end,

		_ProcessServerQuests = function(self)
			local debugStartTime = debugprofilestop()
			if not self.GDE.silent or self.manuallyExecutingServerQuery then
				print("|cFF00FF00Grail|r: starting to process completed query results")
			end

			local db = GrailDatabasePlayer

			--	First make a temporary backup of what we think is completed
			local temporaryBackupQuests = {}
			for i, v in pairs(db["completedQuests"]) do
				temporaryBackupQuests[i] = v
			end
			local completedQuestCount = self:_CountCompleteInDatabase(temporaryBackupQuests)

			--	Now process the completed quests from the server query results
			local completedQuests = { }
			GetQuestsCompleted(completedQuests)
			local serverCompletedCount = 0
			for k,v in pairs(completedQuests) do
				serverCompletedCount = serverCompletedCount + 1
			end
			if serverCompletedCount < completedQuestCount * self.completedQuestThreshold then
				print("|cFFFF0000Grail|r: abandoned processing completed query results because currently complete", completedQuestCount, "but server only thinks", serverCompletedCount)
				return
			end
			local weekday, month, day, year, hour, minute = self:CurrentDateTime()
			db["serverUpdated"] = strformat("%4d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
			db["completedQuests"] = { }
			if nil ~= completedQuests then		-- normally should always be non-nil, but just to make sure
				for v,_ in pairs(completedQuests) do
					self:_MarkQuestComplete(v)
				end
			end

			-- Blizzard makes their "champion" Red Crane dailies remain dailies instead of having them be
			-- normal quests.  This even gives them issue because they need to keep track of which ones have
			-- been done since the server does not keep track of this for them because of the behavior of
			-- daily quests.  They keep track with four quests that are used as bits to create a number from
			-- one to fifteen.  We can make use of these bits to record which of the dailes have been done
			-- even if one only starts to use Grail in the middle of the set of champions.
			local totalChampionsCompleted = 0
			for i = 0, 3 do
				if self:IsQuestCompleted(30719 + i) then
					totalChampionsCompleted = totalChampionsCompleted + 2^i
				end
			end
			for i = 1, totalChampionsCompleted do
				self:_MarkQuestInDatabase(30724 + i, GrailDatabasePlayer["completedResettableQuests"])
			end

			--	Now make sure each of the quests marked complete in controlCompletedQuests are also set
			local backup, current, diff, base
			for index, value in pairs(db["controlCompletedQuests"]) do
				if value ~= nil then
					base = index * 32
					for i = 0, 31 do
						if bitband(value, 2^i) > 0 then
							self:_MarkQuestComplete(base + i + 1)
						end
					end
				end
			end

			--	Now process the actuallyCompletedQuests to ensure we have a good concept of what was actually done
			local actualToNuke = {}
			for index, value in pairs(db["actuallyCompletedQuests"]) do
				if value ~= nil then
					base = index * 32
					for i = 0, 31 do
						if bitband(value, 2^i) > 0 then
							current = base + i + 1		-- this is a questId that is considered "actually" complete
							if self:IsQuestCompleted(current) then
							-- ensure all the I: quests are not considered complete from the server
								local iQuests = self:QuestInvalidates(current)
								if nil ~= iQuests then
									local shouldNuke
									for _, questId in pairs(iQuests) do
--										if questId contains an O: code with the value current we do not need to mark it NOT complete
										shouldNuke = true
										local oQuests = self:QuestBreadcrumbs(questId)
										if nil ~= oQuests then
											for _, oQuestId in pairs(oQuests) do
												if oQuestId == current then shouldNuke = false end
											end
										end
										if shouldNuke then self:_MarkQuestNotComplete(questId, db["completedQuests"]) end
									end
								end
							else
								-- remove the quest from the list of "actually" completed quests
								tinsert(actualToNuke, current)
--								self:_MarkQuestNotComplete(current, db["actuallyCompletedQuests"])
							end
						end
					end
				end
			end
			for _, questToNuke in pairs(actualToNuke) do
				self:_MarkQuestNotComplete(questToNuke, db["actuallyCompletedQuests"])
			end

-- TODO: Should contemplate performing a sanity check here to make sure that all the quests from completedQuests
--			actually can be completed by the player.  This means the gender, class, race and faction checks can
--			be used to mark incomplete those that should not be marked complete.

			--	Now invalidate any quests whose completed status from the backup does not match the server
			local indexesToCheck = {}
			for index in pairs(db["completedQuests"]) do
				if not tContains(indexesToCheck, index) then tinsert(indexesToCheck, index) end
			end
			for index in pairs(temporaryBackupQuests) do
				if not tContains(indexesToCheck, index) then tinsert(indexesToCheck, index) end
			end
			if 0 < #indexesToCheck then
				local questsToInvalidate = {}
				for _, index in pairs(indexesToCheck) do
					backup = temporaryBackupQuests[index] or 0
					current = db["completedQuests"][index] or 0
					if current ~= backup then
						diff = bitbxor(current, backup)
						base = index * 32
						for i = 0, 31 do
							if bitband(diff, 2^i) > 0 then
								tinsert(questsToInvalidate, base + i + 1)
							end
						end
					end
				end
				if 0 < #questsToInvalidate then self:_StatusCodeInvalidate(questsToInvalidate) end
			end

			--	Remove the temporary backup
			wipe(temporaryBackupQuests)

			if not self.GDE.silent or self.manuallyExecutingServerQuery then
				print("|cFFFF0000Grail|r: finished processing completed query results")
			end
			self.manuallyExecutingServerQuery = false
			self.timings.ProcessServerQuests = debugprofilestop() - debugStartTime
		end,

		-- The key is the professionCode used as the key in professionMapping, and the value is a table of ids for each extension
		-- These values are the ones that are returned by C_TradeSkillUI.GetAllProfessionTradeSkillLines() as of 2020-11-14.
		-- Note that these do not cover Riding, Cooking, Fishing or Archaeology as the API does not return anything for those.
		-- Using the values from here with the C_TradeSkillUI.GetTradeSkillLineInfoByID(id) API allows access to the following:
		--		skillLineDisplayName, skillLineRank, skillLineMaxRank, skillLineModifier
		-- If skillLineMaxRank is 0 there is no ability for the player.
		-- TODO: Determine whether someone can have a 0 skillLineMaxRank at a lower expansion but a non-zero at a higher one (i.e.,
		--		skipped over a "lower level" of the skill.
		professionSkillLineIdMapping = {
			A = { 2485, 2484, 2483, 2482, 2481, 2480, 2479, 2478, 2750, }, -- 'Alchemy',		-- 171, -- this is parent skillId
			B = { 2477, 2476, 2475, 2474, 2473, 2472, 2454, 2437, 2751, }, -- 'Blacksmithing',	-- 164,
			E = { 2494, 2493, 2492, 2491, 2489, 2488, 2487, 2486, 2753, }, -- 'Enchanting',		-- 333,
			H = { 2556, 2555, 2554, 2553, 2552, 2551, 2550, 2549, 2760, }, -- 'Herbalism',		-- 182,
			I = { 2514, 2513, 2512, 2511, 2510, 2509, 2508, 2507, 2756, }, -- 'Inscription',	-- 773,
			J = { 2524, 2523, 2522, 2521, 2520, 2519, 2518, 2517, 2757, }, -- 'Jewelcrafting',	-- 755,
			L = { 2532, 2531, 2530, 2529, 2528, 2527, 2526, 2525, 2758, }, -- 'Leatherworking',	-- 165,
			M = { 2572, 2571, 2570, 2569, 2568, 2567, 2566, 2565, 2761, }, -- 'Mining',			-- 186,
			N = { 2506, 2505, 2504, 2503, 2502, 2501, 2500, 2499, 2755, }, -- 'Engineering',	-- 202,
			S = { 2564, 2563, 2562, 2561, 2560, 2559, 2558, 2557, 2762, }, -- 'Skinning',		-- 393,
			T = { 2540, 2539, 2538, 2537, 2536, 2535, 2534, 2533, 2759, }, -- 'Tailoring',		-- 197,
			-- 'Ascension Crafting',	-- 2791,
			-- 'Abominable Stiching',	-- 2787,
			-- 'Soul Cyphering',		-- 2777,
			-- 'Junkyard Tinkering',	-- 2720,
			-- 'Stygia Crafting',		-- 2811,
		},
		-- The values for the following are returned from C_TradeSkillUI.GetCategories() on 2021-03-10
		-- For Cooking and Fishing we need to use C_TradeSkillUI.GetCategoryInfo(categoryId) which returns
		--		name, skillLineCurrentLevel, skillLineMaxLevel all in a table
		-- It seems the UI needs to have been opened for the API to return values.  Also, Fishing returns
		-- nil for values that the player does not have, but Cooking returns a structure (albeit with 0 value).
		professionCategoryIdMapping = {
			C = { 72, 73, 74, 75, 90, 342, 475, 1118, 1323, },	-- 'Cooking',
			F = { 1100, 1102, 1104, 1106, 1108, 1110, 1112, 1114, 1391, },	-- 'Fishing',
			-- X = { },	-- 'Archaeology',
		},
		professionUITradeSkill = {
			C = 185,
			F = 356,
		},
		professionUIOpened = {
			C = false,
			F = false,
			X = false,
		},

		--	Internal Use.
		--	Returns the amount of skill the character has associated with the profession and expansion
		_ProfessionSkillLevel = function(self, professionCode, expansion)
			local skillLineDisplayName, skillLineRank, skillLineMaxRank = "NONE", self.NO_SKILL, self.NO_SKILL
			local useCategory = false
			local skillIds = self.professionSkillLineIdMapping[professionCode]
			if nil == skillIds then
				skillIds = self.professionCategoryIdMapping[professionCode]
				useCategory = true
			end
			if nil ~= skillIds then
				local id = skillIds[expansion]
				if nil ~= id then
					if useCategory then
						if not self.professionUIOpened[professionCode] then
							-- Cannot immediately close the trade skill UI with C_TradeSkillUI.CloseTradeSkill() because it does not close.
							-- Cannot register for event TRADE_SKILL_SHOW and then close the trade skill UI in it because it messes up the trade skill UI and returns garbage.
							C_TradeSkillUI.OpenTradeSkill(self.professionUITradeSkill[professionCode])
							self.professionUIOpened[professionCode] = true
							self:_PostDelayedNotification("CloseTradeSkillUI", 0, 0.5)
							-- Experimentation shows that a delay of 0.25 did not work, but 0.5 does work.  However, the skills recorded can only be associated with the
							-- last trade skill UI window opened.  For example, opening Cooking and then Fishing renders attempts to get Cooking information impossible.
						end
						local categoryInfo = C_TradeSkillUI.GetCategoryInfo(id)
						if nil ~= categoryInfo then
							skillLineDisplayName = categoryInfo.name
							skillLineRank = categoryInfo.skillLineCurrentLevel
							skillLineMaxRank = categoryInfo.skillLineMaxLevel
						end
					else
						skillLineDisplayName, skillLineRank, skillLineMaxRank = C_TradeSkillUI.GetTradeSkillLineInfoByID(id)
					end
				end
			end
			return skillLineDisplayName, skillLineRank, skillLineMaxRank
		end,

		--	Internal Use.
		--	Returns whether the character has the profession specified by the code exceeding the specified level.
		--	@param professionCode The code representing the profession as used in Grail.professionMapping
		--	@param professionValue The skill level to use in comparison.
		--	@return True when the character possesses the skill in excess of the indicated value, false otherwise.
		--	@return The actual skill level the character posseses or Grail.NO_SKILL if the character does not have the specified skill.
		--	@use hasSkill, skillLevel = Grail:ProfessionExceeds('Z', 125)
		ProfessionExceeds = function(self, professionCode, professionValue)
			local retval = false
			local skillLevel, ignore1, ignore2 = self.NO_SKILL, nil, nil
			if self.existsClassic then
				if "R" == professionCode then
					skillLevel = self:_RidingSkillLevel()
				else
					local professionName = self.professionMapping[professionCode]
					if nil ~= professionName then
						local numSkills = GetNumSkillLines()
						for i = 1, numSkills do
							local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i)
							if skillName == professionName then
								skillLevel = skillRank
							end
						end
					end
				end
			else
				local skillName = nil
				local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
				-- TODO: Remove the use of firstAid as a profession

-- local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(index)

				if "X" == professionCode and nil ~= archaeology then
					ignore1, ignore2, skillLevel = GetProfessionInfo(archaeology)
				elseif "F" == professionCode and nil ~= fishing then
					ignore1, ignore2, skillLevel = GetProfessionInfo(fishing)
				elseif "C" == professionCode and nil ~= cooking then
					ignore1, ignore2, skillLevel = GetProfessionInfo(cooking)
				elseif "Z" == professionCode and nil ~= firstAid then
					ignore1, ignore2, skillLevel = GetProfessionInfo(firstAid)
				elseif "R" == professionCode then
					skillLevel = self:_RidingSkillLevel()
				else
					local professionName = self.professionMapping[professionCode]
					if nil ~= prof1 then
						skillName, ignore1, skillLevel = GetProfessionInfo(prof1)
					end
					if skillName ~= professionName then
						if nil ~= prof2 then
							skillName, ignore1, skillLevel = GetProfessionInfo(prof2)
						end
						if skillName ~= professionName then
							skillLevel = self.NO_SKILL
						end
					end
				end
			end
			if skillLevel >= professionValue then
				retval = true
			end
			return retval, skillLevel
		end,

		--	Internal Use.
		_QuestAbandon = function(self, questId)
			questId = tonumber(questId)
			if nil == questId then return end

			if nil ~= self.quests[questId] then
				self:_MarkQuestInDatabase(questId, GrailDatabasePlayer["abandonedQuests"])
			end

			-- Check to see whether this quest belongs to a group and handle group counts properly
			if self.questStatusCache.H[questId] then
				for _, group in pairs(self.questStatusCache.H[questId]) do
					if self:_RecordGroupValueChange(group, false, true, questId) >= self.dailyMaximums[group] - 1 then
						self:_StatusCodeInvalidate(self.questStatusCache.G[group])
					end
				end
			end
			-- And weekly...
			if self.questStatusCache.K[questId] then
				for _, group in pairs(self.questStatusCache.K[questId]) do
					if self:_RecordGroupValueChange(group, false, true, questId, true) >= self.weeklyMaximums[group] - 1 then
						self:_StatusCodeInvalidate(self.questStatusCache.J[group])
					end
				end
			end

			if nil ~= self.quests[questId] and nil ~= self.quests[questId]['OBC'] then
				local questsToInvalidate = {}
				for _,clearQuestId in pairs(self.quests[questId]['OBC']) do
					self:_MarkQuestComplete(clearQuestId, true, false, true)
					tinsert(questsToInvalidate, clearQuestId)
				end
				self:_StatusCodeInvalidate(questsToInvalidate)
			end

			self:_StatusCodeInvalidate({ questId }, self.delayQuestRemoved)

			self:_PostDelayedNotification("Abandon", questId, self.abandonPostNotificationDelay)
		end,

		---
		--	Returns a table of questIds that are possible breadcrumbs for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of questIds for possible breadcrumb quests for this quest, or nil if there are none.
		QuestBreadcrumbs = function(self, questId)
			return self:_QuestGenericAccess(questId, 'O')
		end,

		---
		--	Returns a tables of questIds for which this quest is a breadcrumb quest.
		QuestBreadcrumbsFor = function(self, questId)
			return self:_QuestGenericAccess(questId, 'B')
		end,

		_QuestAcceptCheckObserve = function(self, shouldObserve)
			if shouldObserve then
				self:RegisterObserver("QuestAcceptCheck", Grail._QuestCompleteCheck)
			else
				self:UnregisterObserver("QuestAcceptCheck")
			end
		end,

		_QuestCompleteCheckObserve = function(self, shouldObserve)
			if shouldObserve then
				self:RegisterObserver("QuestCompleteCheck", Grail._QuestCompleteCheck)
			else
				self:UnregisterObserver("QuestCompleteCheck")
			end
		end,

		_LevelGainedQuestCheckObserve = function(self, shouldObserve)
			if shouldObserve then
				self:RegisterObserver("PlayerLevelUp", Grail._QuestCompleteCheck)
			else
				self:UnregisterObserver("PlayerLevelUp")
			end
		self.GDE.silent, self.manuallyExecutingServerQuery = _sv, _mv
		end,

		_CloseTradeSkillUI = function(callbackType, questId)	-- these parameters are not used here
			C_TradeSkillUI.CloseTradeSkill()
		end,

		_QuestCompleteCheck = function(callbackType, questId)
			print("*** Starting check", callbackType, questId)
			local self = Grail
-- This code was debug code to check Blizzard's reported quest levels after the quest is in the quest log (which seems to be the only way to get this).
--			if "QuestAcceptCheck" == callbackType then
--				local index = 1
--				while (true) do
--					local questTitle, level, _, _, _, _, _, _, theQuestId, _, _, _, _, _, _, _, _, difficultyLevel = Grail:GetQuestLogTitle(index)
--					if not questTitle then
--						break
--					else
--						index = index + 1
--					end
--					if questId == theQuestId then
--						print(strformat("   *** Quest %d [L%d REQ:%d]", questId, difficultyLevel, level))
--					end
--				end
--			end
			QueryQuestsCompleted()
			local newlyCompletedQuests, newlyLostQuests = {}, {}
			self:_ProcessServerCompare(newlyCompletedQuests, newlyLostQuests)
			if #newlyCompletedQuests > 0 then
				local odcCodes = questId and self.quests[questId] and self.quests[questId]['ODC'] or {}
				for _, aQuestId in pairs(newlyCompletedQuests) do
					if aQuestId ~= questId then
						local foundODC = false
						for i = 1, #odcCodes do
							if aQuestId == odcCodes[i] then
								foundODC = true
							end
						end
						local colorToUse = foundODC and "ff00ff00" or "ffa50000"
						print(strformat("|c%s   *** Completed:|r %d %s", colorToUse, aQuestId, self:QuestName(aQuestId) or "UNKNOWN NAME"))
					end
				end
			end
			if #newlyLostQuests > 0 then
				for _, aQuestId in pairs(newlyLostQuests) do
					print("|cffff0000   *** Lost:|r", aQuestId, self:QuestName(aQuestId) or "UNKNOWN NAME")
				end
			end
			-- TODO: Actually do something with this information to update quest database so it can be used to do things like provide ODC: codes
			self:_ProcessServerBackup(true)
			print("*** Done with check ***")
		end,

		_QuestCompleteProcess = function(self, questId)
			if nil == questId then
				print("Grail problem attempting to complete a quest with no questId")
				return
			end
--			self.questNPCId = self:GetNPCId(false)

			if questId then
-- It appears we were not even using the results of calling _GetOTCQuest()
--				self.completingQuest = self:_GetOTCQuest(questId, self.questNPCId)
				local shouldUpdateActual = (nil ~= self:QuestInvalidates(questId))
				self:_MarkQuestComplete(questId, true, shouldUpdateActual, false)
				-- Check to see whether there are any other quests that are also marked by Blizzard as being completed now.
				if self.GDE.debug then
					self:_PostDelayedNotification("QuestCompleteCheck", questId, 1.0)
				end

				if nil ~= self.quests[questId] then
					local odcCodes = self.quests[questId]['ODC']
					if nil ~= odcCodes then
						for i = 1, #odcCodes do
							self:_MarkQuestComplete(odcCodes[i], true, false, false)
						end
					end
					local oecCodes = self.quests[questId]['OEC']
if self.GDE.debug and nil ~= oecCodes then print("For quest", questId, "we have OEC codes") end
if self.GDE.debug and nil ~= oecCodes and not self:MeetsPrerequisites(questId, "OPC") then print("For quest", questId, "we do not meet prerequisites for OPC") end
					if nil ~= oecCodes and self:MeetsPrerequisites(questId, "OPC") then
						for i = 1, #oecCodes do
if self.GDE.debug then print("Marking OEC quest complete", oecCodes[i]) end
							self:_MarkQuestComplete(oecCodes[i], true, false, false)
						end
					end

					-- Check whether this quest belongs to a group and invalidate those quests that want to know that group status
					if self.questStatusCache.H[questId] then
						for _, group in pairs(self.questStatusCache.H[questId]) do
							if self:_RecordGroupValueChange(group, false, false, questId) >= self.dailyMaximums[group] then
								self:_StatusCodeInvalidate(self.questStatusCache['W'][group])
							end
						end
					end

				else
					print("|cffff0000Grail problem|r because completing quest which seems not to exist", questId)
				end

			end
		end,

		---
		--	Returns a table of quests that are the causes for this quest to be a flag quest.
		QuestFlags = function(self, questId, forceRawData)
			local retval = self:_QuestGenericAccess(questId, 'J')
			if retval and not forceRawData then
				retval = self:_FromPattern(retval)
			end
			return retval
		end,

		_QuestGenericAccess = function(self, questId, internalCode)
			questId = tonumber(questId)
			return nil ~= questId and nil ~= self.quests[questId] and self.quests[questId][internalCode] or nil
		end,

		---
		--	Returns the questId based on the parameters passed in by looking in the specialQuests
		--	for one that matches the either the specified NPC or the one that currently is the "npc"
		--	or "questnpc".  If a questId is not found using the specialQuests, one is returned that
		--	matches the provided name.
		--	@param questName The localized name of the quest whose questId is sought.
		--	@param optionalNPCIdToUse The npcId to use.  If nil, the defaul is looked up.
		--	@param shouldUseNameFallback If not nil, the questId is looked up by name as a fallback if none found using specialQuests.
		--	@return The sought questId.
		QuestIdFromNPCOrName = function(self, questName, optionalNPCIdToUse, shouldUseNameFallback)
			local retval = nil
			local npcId = optionalNPCIdToUse or self:GetNPCId(false)
			local questGivers = self.specialQuests[questName]
			if nil ~= questGivers then
				for i = 1, #questGivers do
					if tonumber(questGivers[i][1]) == npcId then
						retval = questGivers[i][2]
					end
				end
			end
			if nil == retval and shouldUseNameFallback then
				retval = self:QuestWithName(questName)
			end
			return retval
		end,

		---
		--	Returns the questId of the quest in the quest log with the sought title.
		--	@param soughtTitle The localized name of the quest sought in the quest log.
		--	@return The questId of the quest in the quest log matching the sought name or nil if none match.
		QuestInQuestLogMatchingTitle = function(self, soughtTitle)
			local retval = nil
			local cleanedTitle = strtrim(soughtTitle)
			local quests = self:_QuestsInLog()
			for questId, t in pairs(quests) do
				if cleanedTitle == t[1] then
					retval = questId
				end
			end
			return retval
		end,

		---
		--	Returns a table of questIds that invalidate the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of questIds that invalidate this quest, or nil if there are none.
		QuestInvalidates = function(self, questId)
			return self:_QuestGenericAccess(questId, 'I')
		end,

		---
		--	Returns the level of the quest with the specified questId.
		--	@param questId The standard numeric questId representing a quest.
		--	@return The level of the quest matching the questId or 0 if none found.
		QuestLevel = function(self, questId)
			return bitband(self:CodeLevel(questId), self.bitMaskQuestLevel) / self.bitMaskQuestLevelOffset
		end,

		---
		--	Returns the level required for the player to be able to accept the quest for the specified questId.
		--	@param questId The standard numeric questId representing a quest.
		--	@param dontUseRawValue Boolean indicating whether the quest level should be returned if there is no required level specified.
		--	@return The required level of the quest matching the questId or 0 if none found.  Note that 0 can be returned for the raw value.
		QuestLevelRequired = function(self, questId, dontUseRawValue)
			local retval = bitband(self:CodeLevel(questId), self.bitMaskQuestMinLevel) / self.bitMaskQuestMinLevelOffset
			if retval == 0 and dontUseRawValue then
				retval = self:QuestLevel(questId)
			end
			return retval
		end,

		QuestLevelVariableMax = function(self, questId)
			return bitband(self:CodeLevel(questId), self.bitMaskQuestVariableLevel) / self.bitMaskQuestVariableLevelOffset
		end,

		-- The quest levels when represented as an L code are going to be an integer representation of three values.
		-- The first is the quest level, the second is the required player level to accept the quest, and the third
		-- is the maximum scaling level for the quest.  If the required player level is zero, it means its value is
		-- the same as the quest level.  If the maximum scaling level is zero, it means the quest does not scale.
		-- Conceptually you can think of the integers as <scaling level> <required level> <quest level> with values
		-- that can range from 0-255 each, and therefore to create one integer that represents them, the scaling is
		-- multiplied by 65536 and the required is multiplied by 256.

		-- Returns the three quest levels from the provided string assuming the above information.
		QuestLevelsFromString = function(self, questLevelString, oldStyle)
			local questLevel, questRequiredLevel, questMaximumScalingLevel = 0, 0, 0
			local possibleQuestLevels = tonumber(questLevelString)
			if nil ~= possibleQuestLevels then
				if oldStyle then
					questRequiredLevel = floor(possibleQuestLevels / 65536)
					possibleQuestLevels = possibleQuestLevels - questRequiredLevel * 65536
					questLevel = floor(possibleQuestLevels / 256)
					local possibleScalingLevel = possibleQuestLevels - questLevel * 256
					if possibleScalingLevel ~= 255 then
						questMaximumScalingLevel = possibleScalingLevel
					end
				else
					questMaximumScalingLevel = floor(possibleQuestLevels / 65536)
					possibleQuestLevels = possibleQuestLevels - questMaximumScalingLevel * 65536
					questRequiredLevel = floor(possibleQuestLevels / 256)
					questLevel = possibleQuestLevels - questRequiredLevel * 256
				end
				if 0 == questRequiredLevel then
					questRequiredLevel = questLevel
				end
			end
			return questLevel, questRequiredLevel, questMaximumScalingLevel
		end,

		-- Returns the string created from the provided quest levels assuming the above information.
		StringFromQuestLevels = function(self, questLevel, questRequiredLevel, questMaximumScalingLevel)
			questLevel = questLevel or 0
			questRequiredLevel = questRequiredLevel or 0
			if questRequiredLevel == questLevel then
				questRequiredLevel = 0
			end
			questMaximumScalingLevel = questMaximumScalingLevel or 0
			return strformat("%d", questMaximumScalingLevel * 65536 + questRequiredLevel * 256 + questLevel)
		end,

		-- Assumes the variable level of 0 means the quest is not a scaling quest.
		QuestLevelString = function(self, questId)
			local possibleLevel = self:QuestLevel(questId)
			local possibleVariableLevel = self:QuestLevelVariableMax(questId)
			local variableAspect = ""
			if possibleVariableLevel ~= 0 then
				variableAspect = strformat(" - %d", possibleVariableLevel)
			end
			return strformat("%d%s", possibleLevel, variableAspect)
		end,

		--- Returns whether the testingQuestLevel is lower than (-1), within (0), or higher than (1) the
		--- database concept of the range of levels for the questId.
		_QuestLevelMatchesRangeInDatabase = function(self, questId, testingQuestLevel)
			local retval = 0
			local databaseLow = self:QuestLevelRequired(questId, true)
			local databaseHigh = self:QuestLevelVariableMax(questId)
			if databaseHigh == 0 then
				databaseHigh = databaseLow
			end
			if testingQuestLevel < databaseLow then
				retval = -1
			elseif testingQuestLevel > databaseHigh then
				retval = 1
			end
			return retval
		end,
		
		--- The suggestedLevel is found from Blizzard API, though if the quest is variable is influenced by
		--- the current level of the player.  This attempts to determine what should be done when presented
		--- with a suggestedLevel (which is the required level of the quest).
		_QuestLevelUpdate = function(self, questId, suggestedLevel)
			local databaseRequiredLevel = self:QuestLevelRequired(questId, true)
			local databaseVariableLevel = self:QuestLevelVariableMax(questId)	-- will be 0 if the quest is not variable
			local playerLevel = self.levelingLevel
			if suggestedLevel < databaseRequiredLevel then
				-- Someone is able to get this quest at a level lower than was previously thought possible.
				self:_LearnQuestCode(questId, strformat("L%d", suggestedLevel))
			elseif suggestedLevel > databaseRequiredLevel then
				if databaseRequiredLevel == 0 then
					-- There was no required level entry in the database so record one.
					self:_LearnQuestCode(questId, strformat("L%d", suggestedLevel))
				elseif databaseVariableLevel == 0 then
					-- The quest is indicated at a higher level than expected, so assume this is a variable quest.
					self:_LearnQuestCode(questId, strformat("N%d", suggestedLevel))
				elseif databaseVariableLevel >= suggestedLevel then
					if suggestedLevel < playerLevel then
						-- Because the level is lower than the player level this really should be the maximum for the variable level which means the data has changed so update the variable level.
						self:_LearnQuestCode(questId, strformat("N%d", suggestedLevel))
					else
						-- Nothing to do since the suggestedLevel is already marked as the variable level or falls between the variable level and level required.
					end
				else
					-- The suggestedLevel is higher than the current expected variable level, so update it.
					self:_LearnQuestCode(questId, strformat("N%d", suggestedLevel))
				end
			else
				-- Nothing to do since the suggestedLevel is the same as the required level
			end
		end,

		QuestLocationsAccept = function(self, questId, requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, acceptsMultipleUniques, dungeonLevel, isStartup)
			local debugStartTime = debugprofilestop()
			local results = self:_QuestLocations(questId, 'A', requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, acceptsMultipleUniques, dungeonLevel, isStartup)
			self.totalQuestLocationsAcceptTime = self.totalQuestLocationsAcceptTime + debugprofilestop() - debugStartTime
			return results
		end,

		QuestLocationsTurnin = function(self, questId, requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, acceptsMultipleUniques, dungeonLevel, isStartup)
			return self:_QuestLocations(questId, 'T', requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, acceptsMultipleUniques, dungeonLevel, isStartup)
		end,

		_QuestLocations = function(self, questId, acceptOrTurnin, requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, acceptsMultipleUniques, dungeonLevel, isStartup)
			local retval = {}
			questId = tonumber(questId)
			if nil ~= questId and nil ~= self.quests[questId] then
				local npcCodes = self.quests[questId][acceptOrTurnin..'P']
				if nil == npcCodes then
					npcCodes = self.quests[questId][acceptOrTurnin]
					if nil == npcCodes then
						npcCodes = self.quests[questId][acceptOrTurnin..'K']
					end
					if nil ~= npcCodes then
						for _, npcId in pairs(npcCodes) do
							local locations = self:NPCLocations(npcId, requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, dungeonLevel)
							if nil ~= locations then
								for _, npc in pairs(locations) do
									tinsert(retval, npc)
								end
							end
						end
					else
						local zoneId = self.quests[questId][acceptOrTurnin..'Z']
						if nil ~= zoneId and not isStartup then
							local mapId = tonumber(preferredMapId) or Grail.GetCurrentDisplayedMapAreaID()
							if not onlyMapAreaReturn or (onlyMapAreaReturn and zoneId == mapId) then
								tinsert(retval, { ["id"] = 0, ["name"] = self:NPCName(0), ["mapArea"] = mapId, })
							end
						end
					end
				else
					local npcId, prereqs
					for _, npcPreqTable in pairs(npcCodes) do
						npcId, prereqs = npcPreqTable[1], npcPreqTable[2]
--					for npcId, prereqs in pairs(npcCodes) do
						if isStartup or self:_AnyEvaluateTrueF(prereqs, nil, Grail._EvaluateCodeAsPrerequisite) then
							local locations = self:NPCLocations(npcId, requiresNPCAvailable, onlySingleReturn, onlyMapAreaReturn, preferredMapId, dungeonLevel)
							if nil ~= locations then
								for _, npc in pairs(locations) do
									tinsert(retval, npc)
								end
							end
						end
					end
				end
			end
			-- Since the return values from NPCLocations will process things like onlySingleReturn properly, that means the retval should only have
			-- one location value per unique NPC and that means we can make use of acceptsMultipleUniques to ignore the onlySingleReturn value here.
			if onlySingleReturn and not acceptsMultipleUniques and 1 < #retval then retval = { retval[1] } end		-- pick the first item since no better algorithm
			if 0 == #retval then
				retval = nil
			end
			return retval
		end,

		_QuestLogUpdate = function(type, questId)
			Grail:_HandleEventUnitQuestLogChanged()
		end,


		_RealQuestIdToUse = function(self, questId)
			questId = tonumber(questId)
			local retval = questId
			if nil ~= retval and questId > 500000 and questId < 600000 then
				local alias = self:AliasQuestId(questId)
				if nil ~= alias then
					retval = alias
				end
			end
			return retval
		end,

		---
		--	Returns the name of the quest with the specified questId.
		--	@param questId The standard numeric questId representing a quest.
		--	@return The localized name of the quest matching the questId or nil if none found.
		QuestName = function(self, questId, waitForResponse)
			local retval = nil
			questId = self:_RealQuestIdToUse(questId)
			if nil ~= questId then
				local attempts = 0
				local maxAttempts = waitForResponse or 1
				while (nil == retval and attempts < maxAttempts) do
					retval = self.quest.name[questId]
					if nil == retval and self:IsTreasure(questId) then
						-- For treasure quests which Blizzard does not name we can call it the NPC name
						local npcIDs = Grail:QuestNPCAccepts(questId)
						if nil ~= npcIDs then
							local npcID = npcIDs[1]
							if nil ~= npcID then
								local locations = Grail:NPCLocations(npcID)
								if nil ~= locations then
									local npcName = nil
									for _, npc in pairs(locations) do
										if nil ~= npc.name then
											npcName = format("|TInterface\\MINIMAP\\ObjectIcons:0:0:0:0:128:128:32:48:80:96|t %s", npc.name)
										end
									end
									retval = npcName
								end
							end
						end
					end
					if nil == retval and self.capabilities.usesQuestHyperlink then
						local name = _GetHyperlinkName(strformat("quest:%d", questId), self.tooltip, "com_mithrandir_grailTooltipTextLeft1")
						if name and name ~= self.retrievingString then
							retval = name
							self.quest.name[questId] = name
							if self.forceLocalizedQuestNameLoad then
								self:_LearnQuestName(questId, name)
							end
						end
					end
					attempts = attempts + 1
				end
			end
			return retval
		end,

		---
		--	Returns a table of NPC IDs from which one can accept the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of NPC ids, or nil if there are none.
		QuestNPCAccepts = function(self, questId)
			return self:_QuestGenericAccess(questId, 'A')
		end,

		---
		--	Returns a table of NPC IDs that can be killed to accept the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of NPC ids, or nil if there are none.
		QuestNPCKills = function(self, questId)
			return self:_QuestGenericAccess(questId, 'AK')
		end,

		QuestNPCPrerequisiteAccepts = function(self, questId, forceRawData)
			return self:_QuestNPCPrerequisiteGeneric(questId, 'AP', forceRawData)
		end,

		---
		--	Returns a table in the expected format.  Historically the returned table has
		--	the key of the information and the value the prerequisites.  However, the internal
		--	structure has changed to preserve the order defined in the codes to allow first
		--	prerequisites met to define which information is used.
		_QuestNPCPrerequisiteGeneric = function(self, questId, code, forceRawData)
			local retval = self:_QuestGenericAccess(questId, code)
			if retval and not forceRawData then
				local newRetval = {}
				for _, innerTable in pairs(retval) do
					newRetval[innerTable[1]] = innerTable[2]
				end
				retval = newRetval
			end
			return retval
		end,

		QuestNPCPrerequisiteTurnins = function(self, questId, forceRawData)
			return self:_QuestNPCPrerequisiteGeneric(questId, 'TP', forceRawData)
		end,

		---
		--	Returns a table of NPC IDs to which one can turn in the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@return A table of NPC ids, or nil if there are none.
		QuestNPCTurnins = function(self, questId)
			return self:_QuestGenericAccess(questId, 'T')
		end,

		QuestOnAcceptCompletes = function(self, questId)
			return self:_QuestGenericAccess(questId, 'OAC')
		end,

		QuestOnCompletionCompletes = function(self, questId)
			return self:_QuestGenericAccess(questId, 'OCC')
		end,

		QuestOnDoneCompletes = function(self, questId)
			return self:_QuestGenericAccess(questId, 'ODC')
		end,

		QuestOnTurninCompletes = function(self, questId)
			return self:_QuestGenericAccess(questId, 'OTC')
		end,

		---
		--	Returns a table of questIds that are simple prerequisites for the specified quest.
		--	@param questId The standard numeric questId representing a quest.
		--	@param forceRawData True indicates the internal format of the prerequisite codes is returned, otherwise the table form is returned.
		--	@return A table of questIds that are simple prerequisites for this quest, or nil if there are none.
		QuestPrerequisites = function(self, questId, forceRawData)
			local retval = self.questPrerequisites[questId]
			if retval and not forceRawData then
				retval = self:_FromPattern(retval)
			end
			return retval
		end,

		---
		--	Returns the ordered table of prerequisite quest IDs that are marked with ? in the P: code,
		--	indicating they are present in the database but not yet confirmed as actually required.
		--	Returns nil if the quest has no unverified prerequisites.
		--	@param questId The numeric questId to check.
		--	@return A table of numeric questIds, or nil.
		QuestUnverifiedPrerequisites = function(self, questId)
			return self.questUnverifiedPrereqs[tonumber(questId)]
		end,

		--	Returns a table whose key is the questId and whose value is a table made of the quest title and the completedness
		--	of the quest for each quest in the Blizzard quest log.  If there is nothing in the log, an empty table is returned.
		_QuestsInLog = function(self)
			if nil == self.cachedQuestsInLog then
				local retval = {}
				--	It tuns out that numQuests will be correct, but numEntries will not reflect the total number of values that
				--	will be returned from GetQuestLogTitle() if any of the headers are closed.  With closed headers, the quests
				--	that would normally be in them are going to be at the end of the list, but not necessarily in any specific
				--	order that is helpful.
--				local numEntries, numQuests = GetNumQuestLogEntries()
--				for i = 1, numEntries do
				local i = 1
				while (true) do
					local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId, startEvent, displayQuestId, isWeekly, isTask = self:GetQuestLogTitle(i)
					if not questTitle then
						break
					else
						i = i + 1
					end
					if not isHeader then
						retval[questId] = { questTitle, isComplete }
					end
				end
				self.cachedQuestsInLog = retval
			end
			return self.cachedQuestsInLog
		end,

		---
		--	Returns a table of quest IDs for quests that can start in the specified map area.
		--	@param mapId The map area to use, or if nil, the map area the character is currently in will be used.
		--	@param useDungeonAlso If true, dungeon quests inside the map area will also be included.
		--	@param useLoremasterOnly If true, only Loremaster quests will be used for the area, ignoring the normal entire quest list and ignoring the useDungeonAlso parameter.
		--	@return A table of questIds for quests that start in the map area or nil if none.
		QuestsInMap = function(self, mapId, useDungeonAlso, useLoremasterOnly, useQuestsInLogThatEndInMap)
			local retval = {}
			local mapIdToUse = mapId or Grail.GetCurrentDisplayedMapAreaID()

			if nil ~= mapIdToUse then
				if not self.experimental then
					if useLoremasterOnly then
						retval = self.loremasterQuests[mapIdToUse]
					elseif useDungeonAlso then
						if nil == self.indexedQuestsExtra[mapIdToUse] then
							retval = self.indexedQuests[mapIdToUse]
						elseif nil == self.indexedQuests[mapIdToUse] then
							retval = self.indexedQuestsExtra[mapIdToUse]
						else
							for k,v in pairs(self.indexedQuests[mapIdToUse]) do
								tinsert(retval, v)
							end
							for k, v in pairs(self.indexedQuestsExtra[mapIdToUse]) do
								if not tContains(retval, v) then
									tinsert(retval, v)
								end
							end
						end
					else
						retval = self.indexedQuests[mapIdToUse]
					end
				else
					local tableToUse = useLoremasterOnly and self.loremasterQuests[mapIdToUse] or self.indexedQuests[mapIdToUse]
					local questId
					if nil ~= tableToUse then
						for k, v in pairs(tableToUse) do
							for i = 0, 31 do
								if bitband(v, 2^i) > 0 then
									questId = k * 32 + i + 1
									if not tContains(retval, questId) then tinsert(retval, questId) end
								end
							end
						end
					end
					if useDungeonAlso and not useLoremasterOnly and nil ~= self.indexedQuestsExtra[mapIdToUse] then
						for k, v in pairs(self.indexedQuestsExtra[mapIdToUse]) do
							for i = 0, 31 do
								if bitband(v, 2^i) > 0 then
									questId = k * 32 + i + 1
									if not tContains(retval, questId) then tinsert(retval, questId) end
								end
							end
						end
					end
				end
				--	Here we add quests to the return value if there is a turnin NPC in the map.
				if useQuestsInLogThatEndInMap then
					retval = retval or {}
					local quests = self:_QuestsInLog()
					for questId, t in pairs(quests) do
						if nil ~= self:QuestLocationsTurnin(questId, true, false, true, mapIdToUse) then
							if not tContains(retval, questId) then tinsert(retval, questId) end
						end
					end
				end
			end

			if nil ~= retval and 0 == #retval then retval = nil end
			return retval
		end,

		---
		--	Returns the questId for the quest with the specified name.
		--	@param soughtName The localized name of the quest.
		--	@return The questId of the quest or nil if no quest with that name found.
		QuestWithName = function(self, soughtName)
			if not soughtName then return nil end
-- With the change to have dynamic quest name lookups, this API is only going to give names that
-- have already been seen (unless a loadable addon of names has been loaded).
			for questId, questName in pairs(self.quest.name) do
				if questName == soughtName then
					return questId
				end
			end
            return nil
		end,
        
        ---
		--	Returns all questIds for quests with the specified name.
		--	@param soughtName The localized name of the quest.
		--	@return a table, where the keys are the questIDs or an empty table, if no questID was found
        QuestsWithName = function(self, soughtName)
			if not soughtName then return {} end
            local questIDs = {}
			for questId, questName in pairs(self.quest.name) do
				if questName == soughtName then
					questIDs[questId] = true
				end
			end
            return questIDs
		end,

		--	Returns a table of NPC records where each record indicates the location
		--	of the NPC.  Each record can contain information as described in the
		--	documentation for NPCLocations.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@return A table of NPC records
		--	@see NPCLocations
		_RawNPCLocations = function(self, npcId)
			local debugStartTime = debugprofilestop()
			npcId = tonumber(npcId)
			if nil == npcId then return nil end
			local retval = self.npc.rawLocations[npcId]
			if npcId < 0 and nil == self.npc.nameIndex[npcId] then
				self.npc.nameIndex[npcId] = 0
				self.npc.locations[npcId] = {{["mapArea"]= -1 * npcId}}
			end
			if nil ~= self.npc.locations[npcId] and nil == retval then
				retval = {}
				local t = {}
--				t.name = self:NPCName(npcId)
				t.id = npcId
				t.notes = self.npc.comment[npcId]
				t.locations = self.npc.locations[npcId]
				t.kill = (nil ~= self.npc.kill[npcId])
				t.alias = self.npc.nameIndex[npcId]
				if nil ~= t.alias then
					if nil == self.npc.aliases[t.alias] then
						t.alias = nil
					end
				end
				t.heroic = self.npc.heroic[npcId]
				t.droppers = {}
				local droppedBy = self.npc.droppedBy[npcId]
				if nil ~= droppedBy then
					for _, anNPCId in pairs(droppedBy) do
						local droppers = self:_RawNPCLocations(anNPCId)
						if nil ~= droppers then
							for _, dropper in pairs(droppers) do
								tinsert(t.droppers, dropper)
							end
						end
					end
				end
				t.questId = self.npc.questAssociations[npcId] and self.npc.questAssociations[npcId][1] or nil
				for _, t1 in pairs(t.locations) do
					local t2 = {}
--					t2.name = t.name
					t2.id = t.id
					t2.notes = t.notes
					t2.kill = t.kill
					t2.alias = t.alias
					t2.heroic = t.heroic
					t2.mapArea = t1.mapArea
--					t2.mapLevel = t1.mapLevel
					t2.near = t1.near
					t2.mailbox = t1.mailbox
					t2.created = t1.created
					t2.x = t1.x
					t2.y = t1.y
					t2.realArea = t1.realArea
					t2.questId = t.questId
					tinsert(retval, t2)
				end
				for _, t1 in pairs(t.droppers) do
					local t2 = {}
--					t2.name = t1.name
					t2.id = t1.id
					t2.notes = t1.notes
					t2.kill = t.kill
					t2.alias = t.alias
					t2.heroic = t.heroic
					t2.mapArea = t1.mapArea
--					t2.mapLevel = t1.mapLevel
					t2.near = t1.near
					t2.mailbox = t1.mailbox
					t2.created = t1.created
					t2.x = t1.x
					t2.y = t1.y
					t2.realArea = t1.realArea
--					t2.dropName = t.name
					t2.dropId = t.id
					t2.questId = t.questId
					tinsert(retval, t2)
				end
				if 0 == #retval then
					retval = nil
				else
					self.npc.rawLocations[npcId] = retval
				end
			end
			self.totalRawNPCLocations = self.totalRawNPCLocations + debugprofilestop() - debugStartTime
			return retval
		end,

		--	This goes through all the bags to look for artifacts and attempts to record their
		--	levels by pretending to socket each of them which should open the UI that allows
		--	queries to be made against the "current artifact".
		_RecordArtifactLevels = function(self)
			for bag = 0, 4 do
				local numSlots = self:GetContainerNumSlots(bag)
				for slot = 1, numSlots do
					local _, _, _, quality, _, _, _, _, _, itemID = self:GetContainerItemInfo(bag, slot)
					if LE_ITEM_QUALITY_ARTIFACT == quality then
						local classID = select(12, GetItemInfo(itemID))
						if LE_ITEM_CLASS_WEAPON == classID or LE_ITEM_CLASS_ARMOR == classID then
							SocketContainerItem(bag, slot)
							local duplicateItemId, _, _, _, _, ranksPurchased = C_ArtifactUI.GetArtifactInfo()
							if itemID == duplicateItemId then
								self.artifactLevels[itemID] = ranksPurchased
							end
						end
					end
				end
			end
			if HasArtifactEquipped() then
				SocketInventoryItem(INVSLOT_MAINHAND)
				local duplicateItemId, _, _, _, _, ranksPurchased = C_ArtifactUI.GetArtifactInfo()
				if nil ~= duplicateItemId then
					self.artifactLevels[duplicateItemId] = ranksPurchased
				end
			end
			C_ArtifactUI.Clear()
		end,

		_RecordBadData = function(self, whichData, errorString)
			if nil == GrailDatabase[whichData] then GrailDatabase[whichData] = {} end
			if nil ~= errorString then tinsert(GrailDatabase[whichData], errorString) end
		end,

--		_RecordBadNPCData = function(self, errorString)
--			self:_RecordBadData("BadNPCData", errorString)
--		end,

		_RecordBadQuestData = function(self, errorString)
			self:_RecordBadData("BadQuestData", errorString)
		end,

		--	This routine will update the per-player saved information about group quests
		--	that are currently considered accepted on a specific "daily" day.  It erases
		--	any previous information if the "daily" day changes.  It returns the count 
		_RecordGroupValueChange = function(self, group, isAdding, isRemoving, questId, isWeekly)
			local dayName = isWeekly and self:_GetWeeklyDay() or self:_GetDailyDay()
			local categoryName = isWeekly and "weeklyGroups" or "dailyGroups"
			GrailDatabasePlayer[categoryName] = GrailDatabasePlayer[categoryName] or {}
			GrailDatabasePlayer[categoryName][dayName] = GrailDatabasePlayer[categoryName][dayName] or {}
			local t = GrailDatabasePlayer[categoryName][dayName][group] or {}
			if isAdding then
				if not tContains(t, questId) then tinsert(t, questId) end
			elseif isRemoving then
				if tContains(t, questId) then
					local index, foundIndex = 1, nil
					while t[index] do
						if t[index] == questId then
							foundIndex = index
						end
						index = index + 1
					end
					if foundIndex then
						tremove(t, foundIndex)
					end
				else
					if self.GDE.debug then print("|cFFFFFF00Grail|r _RecordGroupValueChange could not remove a non-existent quest", questId) end
				end
			end
			GrailDatabasePlayer[categoryName][dayName][group] = t
			return #(t)
		end,

		_RegisterDelayedEvent = function(self, frame, delayTable)
			if nil ~= delayTable then
				local originalCount = self.delayedEventsCount
				self.delayedEventsCount = self.delayedEventsCount + 1
				self.delayedEvents[self.delayedEventsCount] = delayTable
--				if 0 == originalCount and 1 == self.delayedEventsCount then		-- what we added is the first in the list...therefore, register for the event to take things out of the table
--					frame:RegisterEvent("PLAYER_REGEN_ENABLED")
--				end
			end
		end,

-- TODO: Continue analyzing from here down...
		---
		--	Adds the callback to the observer queue for eventName.  Should use convenience API when possible.
		--	@see RegisterObserverQuestAbandon
		--	@see RegisterObserverQuestAccept
		--	@see RegisterObserverQuestComplete
		--	@see RegisterObserverQuestStatus
		--	@param eventName The name of the event to which the callback should be added.
		--	@param callback The callback that is to be added.
		RegisterObserver = function(self, eventName, callback)
			assert((nil ~= callback), "Grail Error: cannot register a nil callback")
			if nil == self.observers[eventName] then self.observers[eventName] = { } end
			tinsert(self.observers[eventName], callback)
		end,

		---
		--	Add the callback to receive quest Abandon notifications.
		--	When the notification is posted the callback will be called with two parameters, "Abandon" and the questId.
		--	@param callback The callback that is to be added.
		RegisterObserverQuestAbandon = function(self, callback)
			self:RegisterObserver("Abandon", callback)
		end,

		---
		--	Add the callback to receive quest Accept notifications.
		--	When the notification is posted the callback will be called with two parameters, "Accept" and the questId.
		--	@param callback The callback that is to be added.
		RegisterObserverQuestAccept = function(self, callback)
			self:RegisterObserver("Accept", callback)
		end,

		---
		--	Add the callback to receive quest Completion notifications.
		--	When the notification is posted the callback will be called with two parameters, "Complete" and the questId.
		--	@param callback The callback that is to be added.
		RegisterObserverQuestComplete = function(self, callback)
			self:RegisterObserver("Complete", callback)
		end,

		---
		--	Add the callback to receive quest Status notifications.
		--	When the notification is posted the callback will be called with two parameters, "Status" and the questId.
		--	@param callback The callback that is to be added.
		RegisterObserverQuestStatus = function(self, callback)
			self:RegisterObserver("Status", callback)
		end,

		RegisterSlashOption = function(self, option, helpDescription, theFunction)
			self.slashCommandOptions[option] = { ['help'] = helpDescription, ['func'] = theFunction }
		end,

		-- This checks to make sure Grail has the exact same list of blizzardReputations for the specified quest
		_ReputationChangesMatch = function(self, questId, blizzardReputations)
			if not self.questReputations then return (#blizzardReputations == 0) end
			local retval = true
			questId = tonumber(questId)
			local grailReps = questId and self.questReputations[questId] or ""
			local grailRepsCount = strlen(grailReps) / 4
			local start, stop
			local factionId, value

			if #blizzardReputations ~= grailRepsCount then
				retval = false
			else
				for i = 1, #blizzardReputations do
					start, stop = strfind(grailReps, self:_ReputationCode(blizzardReputations[i]), 1, true)
					if nil == start or 0 ~= stop % 4 then retval = false
					end
				end
				for i = 1, grailRepsCount do
					factionId, value = self:ReputationDecode(strsub(grailReps, i * 4 - 3, i * 4))
					if not tContains(blizzardReputations, factionId..tostring(value)) then retval = false
					end
				end
			end
			return retval
		end,

		--	This returns a four-character representation of a reputation string
		_ReputationCode = function(self, reputationString)
			local factionId = tonumber(strsub(reputationString, 1, 3), 16)
			local value = tonumber(strsub(reputationString, 4))
			if value < 0 then
				value = (value * -1) + 0x00080000
			end
			value = value + factionId * 0x00100000
			return strchar(bitband(bitrshift(value, 24), 255), bitband(bitrshift(value, 16), 255), bitband(bitrshift(value, 8), 255), bitband(value, 255))
		end,

		--	This takes the four-character code and returns the index and value
		ReputationDecode = function(self, code)
			local a, b, c, d = strbyte(code, 1, 4)
			local i = a * 256 * 256 * 256 + b * 256 * 256 + c * 256 + d
			local factionId = bitrshift(i, 20)
			local value = i - factionId * 0x00100000
			if bitband(value, 0x00080000) > 0 then
				value = (value - 0x00080000) * -1
			end
			return self:_HexValue(factionId, 3), value
		end,

		--	Returns whether the character has a reputation that exceeds the value specified for the reputation specified.
		--	@param reputationName The localized name of the sought reputation.
		--	@param reputationValue The reputation value that needs to be exceeded.  Note that internally all reputation values are the earned reputation value + 42000.
		--	@return True if the character has more reputation than was sought, or false otherwise.
		--	@return The reputation value the character actually has (earned value + 42000).
		--	@usage doesExceed, reputationValue = Grail:_ReputationExceeds("Lower City", 41999)
		_ReputationExceeds = function(self, reputationName, reputationValue)
			local retval = false
			local actualEarnedValue = nil
			reputationValue = tonumber(reputationValue)
			local reputationId = self.reverseReputationMapping[reputationName]
			local factionId = reputationId and tonumber(reputationId, 16) or nil
if factionId == nil then print("Rep nil issue:", reputationName, reputationId, reputationValue) end
			if nil ~= factionId and nil ~= reputationValue then
				local name, description, standingId, barMin, barMax, barValue = self:GetFactionInfoByID(factionId)
				if name then
					actualEarnedValue = barValue + 42000	-- the reputationValue is stored with 42000 added to it so we do not have to deal with negative numbers, so we normalize here
                    if C_Reputation and C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionId) then
						local paraValue, paraThreshold, paraQuestId, paraRewardPending = C_Reputation.GetFactionParagonInfo(factionId)
						if paraValue and paraThreshold then
							actualEarnedValue = actualEarnedValue + (paraValue % paraThreshold)
							if paraRewardPending then
								actualEarnedValue = actualEarnedValue + paraThreshold
							end
						end
					end
					retval = (actualEarnedValue > reputationValue)
				end
			end
			return retval, actualEarnedValue
		end,

		MajorFactionRenownLevelMeetsOrExceeds = function(self, reputationName, soughtRenownLevel, accountWide)
			-- TODO: Determine how to ascertain whether a reputation is available to the account at the sought renown level
			local retval = false
			local actualRenownLevel = nil
			soughtRenownLevel = tonumber(soughtRenownLevel)
			local reputationId = self.reverseReputationMapping[reputationName]
			local factionId = reputationId and tonumber(reputationId, 16) or nil
			if nil ~= factionId and nil ~= soughtRenownLevel then
				if C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel then
					actualRenownLevel = C_MajorFactions.GetCurrentRenownLevel(factionId)
					if actualRenownLevel >= soughtRenownLevel then
						retval = true
					end
				end
			end
			return retval, actualRenownLevel
		end,
		
		POIPresent = function(self, mapId, poiId)
			local retval = false
			mapId = tonumber(mapId)
			poiId = tonumber(poiId)
			if mapId and poiId and C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo and C_AreaPoiInfo.GetAreaPOIInfo(mapId,poiId) then
				retval = true
			end
			return retval
		end,
		
		_FriendshipReputationExceeds = function(self, reputationName, reputationValue)
			local retval = false
			local actualEarnedValue = nil
			reputationValue = tonumber(reputationValue)
			local reputationId = self.reverseReputationMapping[reputationName]
			local factionId = reputationId and tonumber(reputationId, 16) or nil
if factionId == nil then print("Rep nil issue:", reputationName, reputationId, reputationValue) end
			if nil ~= factionId and nil ~= reputationValue and self.capabilities.usesFriendshipReputation then
				local usingFriendsMaw = self.reputationFriendsMaw[reputationId] and true or false
				local id, rep, maxRep, name, text, texture, reaction, threshold, nextThreshold = self:GetFriendshipReputation(factionId)
				--	when withering, threshold is 0, but when stable threshold is 100
				--	when withering, rep is 1, but when stable threshold is 101 - 199
				--	maxRep seems to be 42999 in any case
				if id and id > 0 then
					if nil == nextThreshold then
						nextThreshold = threshold
					end
					local base = maxRep - nextThreshold + threshold
					local amount = 0
					if 0 ~= threshold then
						amount = rep - threshold
					end
					actualEarnedValue = usingFriendsMaw and rep or (base + amount)
					retval = (actualEarnedValue > reputationValue)
				end
			end
			return retval, actualEarnedValue
		end,

		--	Returns the localized values for the reputation name and the reputation level (including any modifications)
		--	If no reputationValue exists, it is assumed it will be in the reputationCode.  If it does exist, then the
		--	reputationCode cannot contain it.
		ReputationNameAndLevelName = function(self, reputationCode, reputationValue)
			local retval = nil
			local factionStandingFormat = "FACTION_STANDING_LABEL%d"
			if self.playerGender == 3 then factionStandingFormat = factionStandingFormat.."_FEMALE" end
			reputationValue = tonumber(reputationValue)
			if nil == reputationValue then
				reputationValue = tonumber(reputationCode, 4)
				reputationCode = strsub(reputationCode, 1, 3)
			end
			local usingFriends = self.reputationFriends[reputationCode] and true or false
			local usingBodyGuards = self.reputationBodyGuards[reputationCode] and true or false
			local usingFriendsMaw = self.reputationFriendsMaw[reputationCode] and true or false
			if nil ~= reputationValue then
				local repExtra = ""
				local repNumber
				if usingFriends then
					repNumber = self.reputationFriendshipLevelMapping[reputationValue]
				elseif usingBodyGuards then
					repNumber = self.reputationBodyGuardLevelMapping[reputationValue]
				elseif usingFriendsMaw then
					repNumber = self.reputationFriendshipMawLevelMapping[reputationValue]
				else
					repNumber = self.reputationLevelMapping[reputationValue]
				end
				if nil == repNumber then
					print("*** Grail.ReputationNameAndLevelName problem:",factionStandingFormat,reputationCode,reputationValue,usingFriends,usingBodyGuards)
					repNumber = 0
				end
				if repNumber > 100 then
					repExtra = " +" .. mod(repNumber, 1000000)
					repNumber = floor(repNumber / 1000000)
				end
				local reputationValue
				if usingFriends then
					reputationValue = self.friendshipLevel[repNumber]
				elseif usingBodyGuards then
					reputationValue = self.bodyGuardLevel[repNumber]
				elseif usingFriendsMaw then
					reputationValue = self.friendshipMawLevel[repNumber]
				else
					reputationValue = GetText(strformat(factionStandingFormat, repNumber))
				end
				retval = strformat("%s%s", reputationValue, repExtra)
			end
			return self.reputationMapping[reputationCode], retval
		end,

		FriendshipReputationNameAndLevelName = function(self, reputationCode, reputationValue)
			if self.reputationFriendsMaw[reputationCode] then
				return self:ReputationNameAndLevelName(reputationCode, reputationValue)
			else
				return self.reputationMapping[reputationCode], "Stable"
			end
		end,

		--	Returns the riding skill level of the character.
		--	@return The riding skill level of the character or Grail.NO_SKILL if no skill exists.
		_RidingSkillLevel = function(self)
			-- Need to search the spell book for the Riding skill
			local retval = self.NO_SKILL
			local spellIdMapping = { [33388] = 75, [33391] = 150, [34090] = 225, [34091] = 300, [90265] = 375 }
			for spellId, ridingLevel in pairs(spellIdMapping) do
				if self:_HasSkill(spellId) then
					if ridingLevel > retval then
						retval = ridingLevel
					end
				end
			end
--			local _, _, _, numberSpells = self:GetSpellTabInfo(1)
--			for i = 1, numberSpells, 1 do
--				local spellType, spellId = self:GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
--				if spellType == "SPELL" then	-- because FUTURESPELL means you do not have it yet
--					local newLevel = spellIdMapping[spellId]
--					if newLevel and newLevel > retval then
--						retval = newLevel
--					end
--				end
--			end
			return retval
		end,

		_SendQuestChoiceList = {
			[54] = 32259,	-- Isle of Thunder Horde PvE
			[55] = 32258,	-- Isle of Thunder Horde PvP
			[64] = 32260,	-- Isle of Thunder Alliance PvE
--			[64] = XXX,	-- Choosing "Kraxxus's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Valdrakken's Favor"
			[65] = 32261,	-- Isle of Thunder Alliance PvP
			[85] = 34680,	-- Alliance Nagrand Workshop (Tanks)
			[119] = 34560,	-- Artillery Tower Alliance Fort Wrynn -- 37301 37304
			[120] = 34561,	-- Mage Tower Alliance Fort Wrynn -- Also, 34574 as well
			[121] = 34568,	-- Artillery Tower Horde Talador
			[122] = 34567,	-- Mage Tower Horde Talador	-- 37302 37303
			[123] = 34679,	-- Alliance Stables Nagrand
			[124] = 34680,	-- Alliance Tank Works Nagrand
			[125] = 34812,	-- Horde Stables Nagrand
			[126] = 34813,	-- Horde Tank Works Nagrand
			[127] = 35049,	-- Alliance Lumber Mill Gorgrond -- Also 36249,36250,36619
			[128] = 35064,	-- Alliance Fight Club Gorgrond -- Also 36251 36252
			[129] = 34992,	-- Horde Lumber Mill Gorgrond	-- Also, 36249 and 36250 as well
			[130] = 35149,	-- Horde Fight Club Gorgrond	-- Also, 36251 and 36252 as well
			[133] = 35283,	-- Alliance Arak Brewery	-- 35290 37313 37315
--	The planning maps actually accept the quests properly so we
--	should not set them explicitly and just use this for reference.
--			[135] = 36648,	-- Stronghold Alliance Stonefury Cliffs	-- ??Also, 36549 as well	(36527 was turned in automatically - 2015-07-15)
--			[136] = 36649,	-- Stronghold Alliance Shattrath	-- Also, ??36561 was set as well	(36560 was turned in automatically - 2015-07-15)
			-- 2015-07-15 available on Alleria were 135 136
--			[145] = 36648,	-- Stonefury Cliffs Alliance 36527 36549 36664
--			[149] = 36676,	-- Everbloom Wilds Alliance 36533 36552
--			[153] = 36678,	-- Mok'gol Watchpost Alliance
--			[154] = 36686,	-- The Pit Alliance
			-- 2015-07-30 Alleria 153 154
--			[157] = 36556,	-- Socrethar's Rise Alliance 36351 36664
--			[157] = 36680,	-- Socrethar's Rise Alliance 2015-07-28
--			[158] = 36686,	-- The Pit Alliance
			-- 2015-07-28 Alleria 157 158
--			[163] = 36682,	-- Shadowmoon Enclave Alliance
--			[164] = 36686,	-- The Pit Alliance
--			[193] = 36676,	-- Everbloom Wilds Alliance
--			[194] = 36685,	-- Shattrath City Alliance (Group)
			-- 2015-07-25 Alleria 193 194
--			[197] = 36675,	-- Magnarok Alliance
--			[198] = 36685,	-- Heart of Shattrath Alliance (Group)
			-- 2015-07-31 Alleria 197 198
--			[203] = 36648,	-- Stonefury Cliffs Alliance
			[203] = 44046,	-- Hunter choosing Marksmanship artifact
--			[204] = 36685,	-- Shattrath Heart Alliance (Group)
			-- 2015-07-21 available on Alleria were 203 204
--			[215] = 36680,	-- Socrethar's Rise Alliance
--			[216] = 36649,	-- Shattrath Harbor Alliance
			[217] = { 62019, 62710, 62827 },	-- Choosing Night Fae covenant [Kul Tiran druid]
			-- 2015-07-29 Alleria 215 216
--			[220] = 36649,	-- Shattrath Harbor Alliance
--			[225] = 36678,	-- Mok'gol Watchpost Alliance
--			[226] = 36674,	-- Iron Siegeworks Alliance
			-- 2015-07-22 Alleria 225 226
--			[239] = 36677,	-- Broken Precipice Alliance
--			[240] = 36674,	-- Iron Siegeworks Alliance
			--	2015-07-18 available on Alleria were 239 240
--			[243] = 36648,	-- Stonefury Cliffs
--			[244] = 36684,	-- Ashran
			-- 2015-07-27 Alleria 243 244
--			[245] = 36683,	-- Skettis Alliance
--			[246] = 36684,	-- Ashran Alliance
			--	2015-07-20 available on Alleria were 245 246
			--	2015-08-01 Alleria -> 245 246
--			[247] = 36678,	-- Mok'gol Watchpost Alliance
--			[248] = 36684,	-- Ashran Alliance
			-- 2015-07-23 Alleria 247 248
--			[251] = 36680,	-- Socrethar's Rise Alliance
--			[252] = 36684,	-- Ashran Alliance
			-- 2015-07-17 available on Alleria were 251 252
--			[257] = 36675,	-- Magnarok Alliance
--			[258] = 36684,	-- Ashran Alliance
			--	2015-07-19 available on Alleria were 257 258
--			[259] = 36679,	-- Darktide Roost Alliance
--			[260] = 36684,	-- Ashran Alliance
			-- 2015-07-16 available on Alleria were 259 260
--			[395] = 37891,	-- Ironhold Harbor Alliance
--			[396] = 38045,	-- Zeth'Gol Alliance
			--	2015-07-18 available on Alleria were 395 396
			--	2015-07-29 Alleria -> 395 396
			--	2015-07-30 Alleria -> 395 396
--			[397] = 37891,	-- Ironhold Harbor (Tanaan) Alliance 37886 37887
--			[401] = 37891,	-- Ironhold Harbor (Tanaan) Alliance
--			[402] = 38440,	-- Fel Forge (Tanaan) Alliance
			[403] = { 62020, 62709, },	-- Choosing Venthyr covenant	[for a level 60 NE druid]
			-- 2015-08-01 Alleria 401 402
--			[413] = 37968,	--Temple of Sha'naar (Tanaan) Alliance
--			[414] = 38045,	-- Zeth'Gol (Tanaan) Alliance
			-- 2015-07-22 Alleria 413 414
--			[415] = 37968,	-- Temple of Sha'naar (Tanaan) Alliance 37887 37967 38021
--			[423] = 38045,	-- Assault on Zeth'Gol (Tanaan) Alliance 36799 38042
--			[424] = 38250,	-- Kra'nak (Tanaan) Alliance 37887 38010 37939	-- 2015-07-05
--			[429] = 38045,	-- Zeth'Gol Alliance	-- 2015-07-16
--			[430] = 38585,	-- Kil'jaeden Alliance	-- 2015-07-16
			--	2015-07-16 available on Alleria were 429 430
			--	2015-07-25 Alleria -> 429 430
--			[432] = 38440,	-- Fel Forge (Tanaan) Alliance 37887 38438	-- 2015-07-06
--			[433] = 38250,	-- Ruins of Kra'nak (Tanaan) Alliance
--			[434] = 38046,	-- Iron Front (Tanaan) Alliance
			-- 2015-07-28 Alleria 433 434
--			[437] = 38440,	-- Fel Forge (Tanaan) Alliance 37887 38438 -- also 2015-07-17
--			[438] = 38046,	-- Iron Front (Tanaan) Alliance	-- 2015-07-17
			-- 2015-07-17 available on Alleria were 437 438
			-- 2015-07-23 Alleria -> 437 438
--			[439] = 38440,	-- Fel Forge (Tanaan) Alliance 37887 38438
--			[440] = 38585,	-- Throne of Kil'jaeden (Tanaan) Alliance
			-- 2015-07-26 Alleria 439 440
--			[441] = 38046,	-- Iron Front (Tanaan) Alliance
--			[442] = 38585,	-- Throne of Kil'jaeden (Tanaan) Alliance 37887 38583
			-- 2015-07-19 available on Alleria were 441 442
			-- 2015-07-21 Alleria -> 441 442
			[478] = 39517,	-- Demon Hunter choosing Havoc
			[479] = 39518,	-- Demon Hunter choosing Vengeance
			[486] = 40374,	-- Demon Hunter choosing Kayn Sunfury
			[487] = 40375,	-- Demon Hunter choosing Atruis
			[490] = 40409,	-- Paladin choosing Retribution artifact ... also 42495
			[491] = 40582,	-- Warrior choosing Arms artifact
			[493] = 40581,	-- Warrior choosing Fury artifact
			[504] = 40621,	-- Night Elf Hunter choosing beast master artifact
			[523] = 40686,	-- Warlock choosing Affliction artifact
			[531] = 40702,	-- Druid choosing guardian artifact
			[533] = 40707,	-- Priest choosing Shadow artifact
			[546] = 40817,	-- Demon Hunter choosing Havoc artifact (Kayn, Night Elf)
			[547] = 40818,	-- Demon Hunter choosing Vengeance artifact
			[568] = 40842,	-- Rogue choosing Assassination artifact
			[569] = 40843,	-- Rogue choosing Outlaw artifact
			[570] = 40844,	-- Rogue choosing Subtelty artifact
			[585] = 41080,	-- Mage choosing Fire artifact
			[588] = 41329,	-- Shaman choosing Elemental artifact
			[629] = 43979,	-- Druid choosing Restoration artifact
			[645] = 44380,	-- Demon Hunter chossing Havoc artifact
			[667] = 44433,	-- Druid choosing Feral artifact
			[670] = 44444,	-- Druid choosing Balance artifact
			[738] = { 35283, 35290, 37313, 37315 },	-- choosing (Alliance) Brewery in Spires of Arak
			[777] = { 64277, 66808 },	-- choosing "Loyalty to Sabellian"
			[783] = 48602,	-- Choosing Void Elf
			[784] = 48603,	-- Choosing Lightforged Draenei
--			[956] = xxxxx,	-- Choosing Duskwood from Hero's Call Board in Stormwind -- causes acceptance of 28564
			[1195] = 51570,	-- Choosing Zuldazar from Zandalar Mission Board on ship in Boralus
			[1196] = 51572,	-- Choosing Vol'dun from Zandalar Mission Board on ship in Boralus
			[1197] = 51571,	-- Choosing Nazmir from Zandalar Mission Board on ship in Boralus
--			[1705] = XXX,	-- Choosing "Daela's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Dragonscale's Favor"
			[1210] = 51802,	-- Choosing Stormsong Valley from Kul Tiras Mission Board on ship in Zuldazar
			[1594] = { 64277, 66802 }, -- choosing "Loyalty to Wrathion"
			[1650] = 40621,	-- Hunter choosing Beast Mastery artifact
			[2186] = 57042,	-- Choosing Nazjatar Alliance companion Inowari
			[2214] = {55404, 57041},	-- Choosing Nazjatar Alliance companion Ori
			[2215] = 57040, -- Choosing Nazjatar Alliance companion Akana
			[4335] = { 62020, 62709, 62827, },	-- Choosing Venthyr covenant	[for a level 60 prebuild NE druid]
			[4431] = { 62017, 62711, 62827, },	-- Choosing Necrolord covenant	[for a level 60 prebuild NE druid]
			[4499] = { 62019, 62827, },	-- Choosing Night Fae covenant	[for a level 60 prebuild NE druid]
			[4565] = { 62023, 62708, 62827, },	-- Choosing Kyrian covenant	[for a level 60 prebuild NE druid]
--			[4626] = XXX,	-- Choosing "Turik's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Iskaara's Favor"
			[8862] = { 62023, 62708, 62827, },	-- Choosing Kyrian covenant [NE demon hunter]
--			[9667] = XXX,	-- Choosing "Ashekh's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Maruukai's Favor"
--			[9893] = XXX,	-- Choosing "Daela's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Dragonscale's Favor" -- how does this differ from 1705 returned before?
--			[11197] = XXX,	-- Choosing "Daela's Bidding" in the Forbidden Reach -- does not complete a quest, but gives "Dragonscale's Favor" -- how does this differ from 1705 returned before?
			[15801] = {62020, 62827 }, 	-- Choosing Venthyr covenant (for NE druid played through storyline)
--			[20920] = XXX, -- Choosing "Replay Storyline" in Choose Your Shadowlands Experience [note that there is no quest completed]
			[20947] = {		 -- Choosing "The Threads of Fate"
						56829, 56942, 56955, 56978, 57007, 57025, 57026, 57037, 57098, 57102, 57131, 57136, 57159, 57161, 57164, 57173,
						57174, 57175, 57176, 57178, 57179, 57180, 57182, 57189, 57190, 57240, 57261, 57263, 57264, 57265, 57266, 57267,
						57269, 57270, 57288, 57291, 57380, 57381, 57386, 57390, 57405, 57425, 57426, 57427, 57428, 57442, 57446, 57447,
						57460, 57461, 57511, 57512, 57514, 57515, 57516, 57574, 57584, 57619, 57676, 57677, 57689, 57690, 57691, 57693,
						57694, 57709, 57710, 57711, 57713, 57714, 57715, 57716, 57717, 57719, 57724, 57787, 57816, 57908, 57909, 57912,
						57947, 57948, 57949, 57950, 57951, 59773, 59774, 57976, 57977, 57979, 57982, 57983, 57984, 57985, 57986, 57987,
						57993, 57994, 58011, 58016, 58027, 58031, 58036, 58045, 58086, 58117, 58174, 58268, 58351, 58433, 58473, 58480,
						58483, 58484, 58486, 58488, 58524, 58589, 58590, 58591, 58592, 58593, 58616, 58617, 58618, 58654, 58714, 58719,
						58720, 58721, 58723, 58724, 58726, 58751, 58771, 58799, 58800, 58821, 58843, 58869, 58916, 58931, 58932, 58941,
						58976, 58977, 58978, 58979, 58980, 59009, 59011, 59014, 59021, 59023, 59025, 59130, 59147, 59171, 59172, 59185,
						59188, 59190, 59196, 59197, 59198, 59199, 59200, 59202, 59206, 59209, 59210, 59223, 59231, 59232, 59256, 59327,
						59426, 59616, 59644, 59874, 59897, 59920, 59959, 59960, 59962, 59966, 59973, 59974, 60005, 60006, 60007, 60008,
						60009, 60013, 60020, 60021, 60052, 60053, 60054, 60055, 60056, 60129, 60148, 60149, 60150, 60151, 60152, 60154,
						60156, 60179, 60180, 60181, 60217, 60218, 60219, 60220, 60221, 60222, 60223, 60224, 60225, 60226, 60229, 60292,
						60313, 60338, 60341, 60428, 60451, 60453, 60461, 60506, 60519, 60520, 60521, 60522, 60557, 60563, 60566, 60567,
						60572, 60575, 60577, 60578, 60594, 60600, 60621, 60624, 60628, 60629, 60630, 60631, 60632, 60637, 60638, 60639,
						60647, 60648, 60661, 60671, 60709, 60724, 60733, 60735, 60737, 60738, 60763, 60764, 60778, 60831, 60839, 60856,
						60857, 60859, 60881, 60886, 60901, 60905, 60972, 61096, 61107, 61190, 61715, 61716, 62654, 62706, 62713, 62744,
						},
			[21039] = {62019, 62710},	-- Choosing Night Fae covenant [for a level 50 Zand druid having chosen threads of fate]
			},
		_ItemTextBeginList = {
			[1292673] = 52134,
			[1292674] = 52135,
			[1292675] = 52136,
			[1292676] = 52137,
			[1292677] = 52138,
			},

		--	Internal Use.
		--	Routine used to hook the function for selecting the type of daily quests because we need to signal the
		--	system that the choice has been made without requiring the user to reload the UI.
		_SendQuestChoiceResponse = function(self, anId)
			local numericOption = tonumber(anId)
			local message = strformat("_SendQuestChoiceResponse chooses: %d coords: %s", numericOption, self:Coordinates())
			if self.GDE.debug then
				print(message)
			end
			self:_AddTrackingMessage(message)
			local questToComplete = self._SendQuestChoiceList[numericOption]
			if nil ~= questToComplete then
				if type(questToComplete) == "table" then
					for _, questId in pairs(questToComplete) do
						self:_MarkQuestComplete(questId, true)
					end
				else
					self:_MarkQuestComplete(questToComplete, true)
				end
			end
		end,

		SetMapAreaQuests = function(self, mapAreaId, title, questTable, useKey)
			self.indexedQuests[mapAreaId] = {}
			self.mapAreaMapping[mapAreaId] = title
			for key, value in pairs(questTable) do
				self:AddQuestToMapArea(useKey and key or value, mapAreaId)
			end
		end,

		--	The routine called when the /grail slash command is used.  For the most part the currently implemented commands are for testing only.
		--	@param frame The tooltip frame.
		--	@param msg The rest of the command line used with the /grail slash command.
		_SlashCommand = function(self, frame, msg)
			local executed = false
--			msg = strlower(msg)
			for option, value in pairs(self.slashCommandOptions) do
				if option == strsub(msg, 1, strlen(option)) then
					value['func'](msg, frame)
					executed = true
				end
			end
			if not executed then
				self.manuallyExecutingServerQuery = true
				print("|cFFFFFF00Grail|r initiating server database query")
				QueryQuestsCompleted()
			end			
		end,

		SpellPresent = function(self, soughtSpellId)
			soughtSpellId = tonumber(soughtSpellId)
			if nil == soughtSpellId then return false end
			local retval = false
			local i = 1
			while (false == retval) do
--				local name,_,_,_,_,_,_,_,_,boaSpellId,spellId = UnitAura('player', i)
--				if self.battleForAzeroth then
--					spellId = boaSpellId
--				end
				local name, spellId = self:UnitAura('player', i)
				if name then
					if soughtSpellId == tonumber(spellId) then
						retval = true
					end
					i = i + 1
				else
					break
				end
			end
			return retval
		end,

		---
		--	Returns a bit mask indicating the status of the quest.
		--	@param questId The standard numeric questId representing the quest.
		--	@return An integer that should be interpreted as a bit mask containing information why the quest cannot be accepted (or 0 (or 2) if it can).
		StatusCode = function(self, questId)
			local retval = 0
			questId = tonumber(questId)

			--	Normally I would structure the code so there is only one return statement and the checks would
			--	result in an if/else structure that would make the code slightly less readable.  However, this
			--	code makes simple checks first and returns results immediately for ease of readability.

--self.statusCodeCalled = (self.statusCodeCalled or 0) + 1
--GrailDatabase["DEBUG"] = GrailDatabase["DEBUG"] or {}
--local stackString = debugstack()
--GrailDatabase["DEBUG"][stackString] = (GrailDatabase["DEBUG"][stackString] or 0) + 1
			if nil == questId then return self.bitMaskError end
			if nil ~= self.questStatuses[questId] then return self.questStatuses[questId] end

			if tContains(self.currentlyProcessingStatus, questId) then return 0 end
			-- We put this questId onto the stack to control infinite loops during processing.
			tinsert(self.currentlyProcessingStatus, questId)

			if self:DoesQuestExist(questId) then
--self.statusCodeComputed = (self.statusCodeComputed or 0) + 1
				if not self:MeetsRequirementClass(questId) then retval = retval + self.bitMaskClass end
				if not self:MeetsRequirementRace(questId) then retval = retval + self.bitMaskRace end
				if not self:MeetsRequirementGender(questId) then retval = retval + self.bitMaskGender end
				if not self:MeetsRequirementFaction(questId) then retval = retval + self.bitMaskFaction end
				-- Only set the completed if it actually could have been done based on class, race, gender and faction
				if 0 == retval and self:IsQuestCompleted(questId) then retval = retval + self.bitMaskCompleted end
				if self:IsRepeatable(questId) then retval = retval + self.bitMaskRepeatable end
				if self:IsDaily(questId) or self:IsWeekly(questId) or self:IsMonthly(questId) or self:IsYearly(questId) then retval = retval + self.bitMaskResettable end
				if self:HasQuestEverBeenCompleted(questId) then retval = retval + self.bitMaskEverCompleted end
				if self:IsResettableQuestCompleted(questId) then retval = retval + self.bitMaskResettableRepeatableCompleted end
				if nil ~= self:IsBugged(questId) then retval = retval + self.bitMaskBugged end
				if self:IsLowLevel(questId) then retval = retval + self.bitMaskLowLevel else tinsert(self.questStatusCache["V"], questId) end
				local inLog, inLogStatus = self:IsQuestInQuestLog(questId)
				if inLog and 0 == bitband(retval, self.bitMaskCompleted) then retval = retval + self.bitMaskInLog end
				if inLogStatus then
					if inLogStatus > 0 then retval = retval + self.bitMaskInLogComplete end
					if inLogStatus < 0 then retval = retval + self.bitMaskInLogFailed end
				end
-- TODO: Determine if there is an issue evaluating a prerequisite quest whose only prerequisites are P:D codes.  Quest 9622 has a requirement including 9570 which shows issues.
				if not self:MeetsPrerequisites(questId) and not (self:IsQuestCompleted(questId) and (self:_OnlyHasPrerequisites(questId, 'B') or self:_OnlyFailsPrerequisites(questId, 'K'))) then
					retval = retval + self.bitMaskPrerequisites
					retval = self:AncestorStatusCode(questId, retval)		-- !!!!! here is RAM usage !!!!!
				end
				-- Only set an invalidation if the quest is not already completed
				if 0 == bitband(retval, self.bitMaskCompleted) and self:IsInvalidated(questId) then retval = retval + self.bitMaskInvalidated end		-- !!!!! here is RAM usage !!!!!
				if not self:MeetsRequirementProfession(questId) then retval = retval + self.bitMaskProfession tinsert(self.questStatusCache["P"], questId) end
				if not self:MeetsRequirementReputation(questId) then retval = retval + self.bitMaskReputation end
				if self.questReputationRequirements[questId] then tinsert(self.questStatusCache["R"], questId) end
				if not self:MeetsRequirementHoliday(questId) then retval = retval + self.bitMaskHoliday end
				local success, levelToCompare, levelRequired, levelNotToExceed = self:MeetsRequirementLevel(questId, self.levelingLevel)
				-- Only set a level problem if the quest is not already completed
				if not success and 0 == bitband(retval, self.bitMaskCompleted) then
					if levelToCompare < levelRequired then retval = retval + self.bitMaskLevelTooLow tinsert(self.questStatusCache["L"], questId) end
					if levelToCompare > levelNotToExceed then retval = retval + self.bitMaskLevelTooHigh end
				end

			else
				retval = self.bitMaskNonexistent
			end

			self.questStatuses[questId] = retval

			-- First we invalidate the cache for all the quests whose status is suspect
			if nil ~= self.currentMortalIssues[questId] then
				for _,victimQuestId in pairs(self.currentMortalIssues[questId]) do
					self.questStatuses[victimQuestId] = nil
				end
				self.currentMortalIssues[questId] = nil
			end

			-- Now we remove ourselves from the stack of processing
			tremove(self.currentlyProcessingStatus)

			return retval
		end,

		_StatusCodeCallback = function(callbackType, questId, delay)
			questId = tonumber(questId)
			if nil ~= questId then
				if nil ~= Grail.questStatusCache then
					Grail.questStatuses[questId] = nil
--					if Grail.quests[questId] then Grail.quests[questId][7] = nil end
--					if Grail.quests[questId] then self:_MarkStatusValid(questId, true) end
					Grail:_CoalesceDelayedNotification("Status", delay or 0)
					Grail:_StatusCodeInvalidate(Grail.questStatusCache['D'][questId])
					Grail:_StatusCodeInvalidate(Grail.questStatusCache["I"][questId])
					Grail:_StatusCodeInvalidate(Grail.questStatusCache.Q[questId])
					Grail:_StatusCodeInvalidate(Grail.questStatusCache["F"][questId]) -- technically this should only be done for abandon, but the size will be so small it matters not
					Grail.questStatusCache.Q[questId] = {}	-- the list we nuked should be regenerated when descendants get their new StatusCode values

					-- Check to see whether this quest belongs to a group and deal with quests that rely on that group
					if Grail.questStatusCache.H[questId] then
						for _, group in pairs(Grail.questStatusCache.H[questId]) do
							Grail:_StatusCodeInvalidate(Grail.questStatusCache['W'][group])
						end
					end
				end
				if nil ~= Grail.quests[questId] then
					Grail:_StatusCodeInvalidate(Grail.quests[questId]['O'])
				end
			end
		end,

		_NPCLocationInvalidate = function(self, tableOfQuestIds)
			
		end,

		_InvalidateStatusForQuestsWithTalentPrerequisites = function(self)
			self:_StatusCodeInvalidate(self.invalidateControl[self.invalidateGroupCurrentGarrisonTalentQuests])
		end,

		---
		--	
		_StatusCodeInvalidate = function(self, tableOfQuestIds, delay)
			if nil ~= tableOfQuestIds then
				for _, questId in pairs(tableOfQuestIds) do
					if nil ~= self.questStatuses[questId] then
						self.questStatuses[questId] = nil
--					if nil ~= self.quests[questId] and nil ~= self.quests[questId][7] then
--						self.quests[questId][7] = nil
--					if nil ~= self.quests[questId] and self:_StatusValid(questId) then
--						self:_MarkStatusValid(questId, true)
						self._StatusCodeCallback("bogus", questId, delay)	-- we want to invalidate the cache for descendants
						self:_CoalesceDelayedNotification("Status", delay or 0)
					end
				end
			end
		end,

		_SetAppend = function(self, t1, t2)
			if nil ~= t1 and nil ~= t2 then
				if type(t2) == "table" then
					for _, value in pairs(t2) do
						if not tContains(t1, value) then
							tinsert(t1, value)
						end
					end
				else
					if not tContains(t1, t2) then
						tinsert(t1, t2)
					end
				end
			end
			return t1
		end,

		_TableLength = function(self, t)
			local count = 0
			for key in pairs(t) do
				count = count + 1
			end
			return count
		end,

		_TableAppend = function(self, t1, t2)
			if nil ~= t1 and nil ~= t2 then
				if type(t2) == "table" then
					for _, value in pairs(t2) do
						tinsert(t1, value)
					end
				else
					tinsert(t1, t2)
				end
			end
			return t1
		end,

		_TableAppendCodes = function(self, t, master, codes)
			local tableToUse = t or {}
			if nil ~= codes and nil ~= master then
				for _, code in pairs(codes) do
					tableToUse = self:_TableAppend(tableToUse, master[code])
				end
			end
			return tableToUse
		end,

		_TableCopy = function(self, t)
			if nil == t then return nil end
			local retval = {}
			for k, v in pairs(t) do
				retval[k] = v
			end
			return retval
		end,

		_TableRemove = function(self, t, item)
			if nil == t or nil == item then return end
			if tContains(t, item) then
				local index, foundIndex = 1, nil
				while t[index] do
					if t[index] == item then
						foundIndex = index
					end
					index = index + 1
				end
				if foundIndex then
					tremove(t, foundIndex)
				end
			end
		end,

		-- Returns the map coordinates for the specified victim, defaulting to player
		-- if nothing else provided.  The coordinates are structured as
		-- 				mapId*:xx.xx,yy.yy
		-- where * is either nothing or the dungeon level in [] before BfA.  In BfA
		-- there will be multiple coordinates separated by a space if the current map
		-- is within others more than one step from a continent map.
		Coordinates = function(self, victim)
			victim = victim or "player"
			local retval = ""
			local spacer = ""
			if self.battleForAzeroth then
				local currentMapInfo = C_Map.GetMapInfo(Grail.GetCurrentMapAreaID())
				while currentMapInfo do
					local currentMapId = currentMapInfo.mapID
					local x, y = self.GetPlayerMapPosition(victim, currentMapId)
					if x and y then
						retval = retval .. spacer .. strformat("%d:%.2f,%.2f", currentMapId, x * 100 , y * 100)
						spacer = " "
						currentMapInfo = C_Map.GetMapInfo(currentMapInfo.parentMapID)
						if nil ~= currentMapInfo and currentMapInfo.mapType == Enum.UIMapType.Continent then
							currentMapInfo = nil
						end
					else
						currentMapInfo = nil
					end
				end
				return retval
			else
				local x, y = self.GetPlayerMapPosition(victim)	-- cannot get target x,y since Blizzard disabled that and returns 0,0 all the time for it
				if nil == x then x, y = 0, 0 end
				local dungeonLevel = GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
				local dungeonIndicator = (dungeonLevel > 0) and "["..dungeonLevel.."]" or ""
				return strformat("%d%s:%.2f,%.2f", Grail.GetCurrentMapAreaID(), dungeonIndicator, x*100, y*100)
			end
		end,

		---
		--	Returns information about the currently selected target.
		--	@return The localized name of the target or nil if no target.
		--	@return The npcId of the target unless the target is a world object in which one million is added to its value.
		--	@return The coordinates of the player (since the target coordinates cannot be determined) in the format mapId*:xx.xx,yy.yy, where * is nothing or the dungeon level in []
		--	@usage targetName, npcId, coordinates = Grail:TargetInformation()
		TargetInformation = function(self)
			local coordinates = nil
			local ok, npcId, targetName = pcall(self.GetNPCId, self, true)
			if not ok then npcId = nil; targetName = nil end
			if nil ~= npcId then
				coordinates = self:Coordinates()
			end
			return targetName, npcId, coordinates
		end,

		--	The routine called for event processing associated with the hidden tooltip.
		--	@param frame The tooltip frame.
		--	@param event The name of the event.
		--	@param ... Various parameters depending on the event.
		_Tooltip_OnEvent = function(self, frame, event, ...)
			if self.eventDispatch[event] then
				self.eventDispatch[event](self, frame, ...)
			end
		end,

		-- Blizzard has replaced UnitAura with C_UnitAuras.GetAuraDataByIndex so we do the right
		-- thing here, but note that we only return the name and spellID.
		UnitAura = function(self, unit, index, filter)
			if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
				local info = Grail_SafeGetAuraDataByIndex(unit, index, filter)
				if info then
					return info.name, info.spellId
				else
					return nil
				end
			else
				if BLIZZ_UnitAura then
					local name,_,_,_,_,_,_,_,_,boaSpellId,classicSpellId = BLIZZ_UnitAura(unit, index, filter)
					local spellId = tonumber(classicSpellId or boaSpellId)
					return name, spellId
				end
			end
			return nil
		end,

		---
		--	Internal Use.
		--	Removes the callback from the observer queue for eventName.  Should not be called directly, but through the use of convenience API.
		--	@see UnregisterObserverQuestAbandon
		--	@see UnregisterObserverQuestAccept
		--	@see UnregisterObserverQuestComplete
		--	@see UnregisterObserverQuestStatus
		--	@param eventName The name of the event from which the callback should be removed.
		--	@param callback The callback that is to be removed.
		UnregisterObserver = function(self, eventName, callback)
			if nil ~= callback and nil ~= self.observers[eventName] then
				for i = 1, #(self.observers[eventName]), 1 do
					if callback == self.observers[eventName][i] then
						tremove(self.observers[eventName], i)
						break
					end
				end
			end
		end,

		---
		--	Remove the callback from receiving quest Abandon notifications.
		--	@param callback The callback that is to be removed.
		UnregisterObserverQuestAbandon = function(self, callback)
			self:UnregisterObserver("Abandon", callback)
		end,

		---
		--	Remove the callback from receiving quest Accept notifications.
		--	@param callback The callback that is to be removed.
		UnregisterObserverQuestAccept = function(self, callback)
			self:UnregisterObserver("Accept", callback)
		end,

		---
		--	Remove the callback from receiving quest Completion notifications.
		--	@param callback The callback that is to be removed.
		UnregisterObserverQuestComplete = function(self, callback)
			self:UnregisterObserver("Complete", callback)
		end,

		---
		--	Remove the callback from receiving quest Status notifications.
		--	@param callback The callback that is to be removed.
		UnregisterObserverQuestStatus = function(self, callback)
			self:UnregisterObserver("Status", callback)
		end,

		--	Updates the NewQuests with data if the quest does not already exist in the internal database or adds the npcCode to the NewQuests data if it does not already exist.
		--	@param questId The standard numeric questId representing a quest.
		--	@param questTitle The localized name of the quest.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@param isDaily Indicates whether the quest is a daily quest.
		--	@param npcCode A string value 'A:' or 'T:' indicating whether the NPC is for accepting a quest or turning one in.
		--	@param version A version string based on the current internal database versions.
		_UpdateQuestDatabase = function(self, questId, questTitle, npcId, isDaily, npcCode, version, kCode, lCode)
			questId = tonumber(questId)
			npcId = tonumber(npcId)
			if nil == questId or nil == npcId then return end

			self.quests[questId] = self.quests[questId] or {}
			self.questCodes[questId] = self.questCodes[questId] or ''

-- TODO: Do we need to add each of these code that are found (A:, T:, K:, L:) to self.questCodes[questId]?
			if questTitle ~= "No Title Stored" and self:QuestName(questId) ~= questTitle then
				self.quest.name[questId] = questTitle
				self:_LearnQuestName(questId, questTitle)
			end
			
			if 'A' == npcCode and not self:_GoodNPCAccept(questId, npcId) then
				self:_LearnQuestCode(questId, 'A:' .. npcId)
			end
			
			if 'T' == npcCode and not self:_GoodNPCTurnin(questId, npcId) then
				self:_LearnQuestCode(questId, 'T:' .. npcId)
			end
			
			if kCode then
				self:_LearnKCode(questId, kCode)
			end
			
			if lCode then
				local questLevel, questLevelRequired = self:QuestLevelsFromString(strsub(lCode, 2))
				if questLevel ~= 0 then
					local questLevelMatches = (self:QuestLevel(questId) == questLevel)
					local questLevelRequiredMatches = (self:QuestLevelRequired(questId) == questLevelRequired)
					if questLevelMatches and questLevelRequiredMatches then
						-- do nothing as all is well
					else
						self:_QuestLevelUpdate(questId, questLevelRequired)
--						if 0 == self:_QuestLevelMatchesRangeInDatabase(questId, questLevelRequired) then
--							-- This is the case when the required level falls within the range the database accepts for required to scaling max.
--						else
--							self:_LearnQuestCode(questId, lCode)
--						end
--						if not questLevelMatches then
--							self:_SetQuestLevel(questId, questLevel)
--						end
--						if not questLevelRequiredMatches then
--							self:_SetQuestRequiredLevel(questId, questLevelRequired)
--						end
					end
				end
			end
		end,

		--	Updates the time until quests reset based on the GetQuestResetTime() API.  A side-effect is that if the reset time is past QueryQuestsCompleted() will be called.
		_UpdateQuestResetTime = function(self)
if not self.existsClassic then
			local seconds = GetQuestResetTime()
			if seconds > self.questResetTime then
				if not self.GDE.silent then
					print("|cFFFF0000Grail|r automatically initializing a server query for completed quests")
				end
				QueryQuestsCompleted()
			end
			self.questResetTime = seconds
end
		end,

		--	Updates the NewNPCs with data if the NPC does not already exist in the internal database.
		--	@param targetName The localized name of the NPC.
		--	@param npcId The standard numeric npcId representing an NPC.
		--	@param coordinates The zone coordinates of the player.
		--	@param version A version string based on the current internal database versions.
		_UpdateTargetDatabase = function(self, targetName, npcId, coordinates, version)
			npcId = tonumber(npcId)
			-- If the npcId is a world object and we do not already have its name we should learn it.
			if nil ~= npcId and npcId >= 1000000 and npcId < 2000000 then
				local storedNPCName = self:NPCName(npcId)
				if nil == storedNPCName or storedNPCName ~= targetName then
					self:_LearnObjectName(npcId, targetName)
				end
			end
			return self:_NPCToUse(npcId, coordinates)
		end,

		_UpdateTrackingObserver = function(self)
			if self.GDE.tracking then
				self:RegisterObserverQuestAbandon(Grail._AddTrackingCallback)
				self:RegisterObserverQuestComplete(Grail._AddTrackingCallback)
				self:RegisterObserver("FullAccept", Grail._AddFullTrackingCallback)
			else
				self:UnregisterObserverQuestAbandon(Grail._AddTrackingCallback)
				self:UnregisterObserverQuestComplete(Grail._AddTrackingCallback)
				self:UnregisterObserver("FullAccept", Grail._AddFullTrackingCallback)
			end
		end,

		}

local locale = GetLocale()
local me = Grail

if locale == "deDE" then
	me.accountUnlock = "Accountfreischaltung"
	me.bodyGuardLevel = { 'Leibwächter', 'Treuer Leibwächter', 'Persönlicher Flügelmann' }
	me.friendshipLevel = { 'Fremder', 'Bekannter', 'Kumpel', 'Freund', 'guter Freund', 'bester Freund' }
	me.friendshipMawLevel = { 'Unsicher', 'Besorgt', 'Unverbindlich', 'Zwiespältig', 'Herzlich', 'Appreciative' }

	me.holidayMapping = { ['A'] = 'Liebe liegt in der Luft', ['B'] = 'Braufest', ['C'] = "Kinderwoche", ['D'] = 'Tag der Toten', ['E'] = 'WoW Anniversary', ['F'] = 'Dunkelmond-Jahrmarkt', ['H'] = 'Erntedankfest', ['K'] = "Angelwettstreit der Kalu'ak", ['L'] = 'Mondfest', ['M'] = 'Sonnenwendfest', ['N'] = 'Nobelgarten', ['P'] = "Piratentag", ['U'] = 'Neujahr', ['V'] = 'Winterhauch', ['W'] = "Schlotternächte", ['X'] = 'Anglerwettbewerb im Schlingendorntal', ['Y'] = "Die Pilgerfreuden", ['Z'] = "Weihnachtswoche", ['a'] = 'Bonusereignis: Apexis', ['b'] = 'Bonusereignis: Arenascharmützel', ['c'] = 'Bonusereignis: Schlachtfelder', ['d'] = 'Bonusereignis: Draenordungeons', ['e'] = 'Bonusereignis: Haustierkämpfe', ['f'] = 'Bonusereignis: Zeitwanderungsdungeons', ['Q'] = "AQ", }

	me.nameTaleElders = "Geschichte von den Ältesten"
	me.nameTaleOutsider = "Geschichte vom Fremdling"
	me.nameTaleWarlord = "Geschichte von der Kriegsfürstin"
	me.nameTaleSlumbering = "Geschichte von den Schlummernden"
	me.nameTaleMagmaPact = "Geschichte vom Magmapakt"
	me.nameTaleWeakling = "Geschichte vom Schwächling"

	me.professionMapping = { ['A'] = 'Alchemie', ['B'] = 'Schmiedekunst', ['C'] = 'Kochkunst', ['E'] = 'Verzauberkunst', ['F'] = 'Angeln', ['H'] = 'Kräuterkunde', ['I'] = 'Inschriftenkunde', ['J'] = 'Juwelenschleifen', ['L'] = 'Lederverarbeitung', ['M'] = 'Bergbau', ['N'] = 'Ingenieurskunst', ['R'] = 'Reiten', ['S'] = 'Kürschnerei', ['T'] = 'Schneiderei', ['X'] = 'Archäologie', ['Z'] = 'Erste Hilfe', }

	local G = me.races
		G['A'][2] = 'Pandaren'
		G['A'][3] = 'Pandaren'
	G['B'][2] = 'Blutelf'
	G['B'][3] = 'Blutelfe'
	G['C'][2] = 'Dunkeleisenzwerg'
	G['C'][3] = 'Dunkeleisenzwergin'
		G['D'][2] = 'Draenei'
		G['D'][3] = 'Draenei'
	G['E'][2] = 'Nachtelf'
	G['E'][3] = 'Nachtelfe'
	G['F'][2] = 'Zwerg'
	G['F'][3] = 'Zwerg'
		G['G'][2] = 'Goblin'
		G['G'][3] = 'Goblin'
	G['H'][2] = 'Mensch'
	G['H'][3] = 'Mensch'
	G['I'][2] = 'Lichtgeschmiedeter Draenei'
	G['I'][3] = 'Lichtgeschmiedete Draenei'
	G['J'][2] = "Mag'har"
	G['J'][3] = "Mag'har"
	G['K'][2] = 'Kul Tiraner'
	G['K'][3] = 'Kul Tiranerin'
		G['L'][2] = 'Troll'
		G['L'][3] = 'Troll'
	G['M'][2] = 'Hochbergtauren'
	G['M'][3] = 'Hochbergtauren'
	G['N'][2] = 'Gnom'
	G['N'][3] = 'Gnom'
		G['O'][2] = 'Orc'
		G['O'][3] = 'Orc'
	G['Q'][2] = 'Mechagnom'
	G['Q'][3] = 'Mechagnom'
	G['R'][2] = 'Nachtgeborener'
	G['R'][3] = 'Nachtgeborene'
		G['S'][2] = 'Vulpera'
		G['S'][3] = 'Vulpera'
		G['T'][2] = 'Tauren'
		G['T'][3] = 'Tauren'
	G['U'][2] = 'Untoter'
	G['U'][3] = 'Untote'
	G['V'][2] = 'Leerenelf'
	G['V'][3] = 'Leerenelfe'
		G['W'][2] = 'Worgen'
		G['W'][3] = 'Worgen'
	G['X'][2] = 'Irdener'
	G['X'][3] = 'Irdene'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Zandalaritroll'
	G['Z'][3] = 'Zandalaritroll'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "esES" then
	me.accountUnlock = "Desbloqueo ligado a la cuenta"
	me.bodyGuardLevel = { 'Guardaespaldas', 'Escolta leal', 'Compañero del alma' }
	me.friendshipLevel = { 'Extraño', 'Conocido', 'Colega', 'Amigo', 'Buen amigo', 'Mejor amigo' }
	me.friendshipMawLevel = { 'Dubitativa', 'Aprensiva', 'Indecisa', 'Ambivalente', 'Cordial', 'Appreciative' }

	me.holidayMapping = { ['A'] = 'Amor en el aire', ['B'] = 'Fiesta de la cerveza', ['C'] = "Semana de los Niños", ['D'] = 'Festividad de los Muertos', ['E'] = 'WoW Anniversary', ['F'] = 'Feria de la Luna Negra', ['H'] = 'Festival de la Cosecha', ['K'] = "Competición de pesca Kalu'ak", ['L'] = 'Festival Lunar', ['M'] = 'Festival de Fuego del Solsticio de Verano', ['N'] = 'Jardín Noble', ['P'] = "Día de los Piratas", ['U'] = 'Nochevieja', ['V'] = 'El festín del Festival del Invierno', ['W'] = "Halloween", ['X'] = 'Concurso de Pesca', ['Y'] = "Generosidad del Peregrino", ['Z'] = "Semana navideña", ['a'] = 'Evento de bonificación apexis', ['b'] ='Evento de bonificación de escaramuza de arena', ['c'] = 'Evento de bonificación de campo de batalla', ['d'] = 'Evento de mazmorra de Draenor', ['e'] = 'Evento de bonificación de duelo de mascotas', ['f'] = 'Evento de mazmorra de Paseo en el tiempo', ['Q'] = "AQ", }

	me.nameTaleElders = "La historia de los ancianos"
	me.nameTaleOutsider = "La historia del forastero"
	me.nameTaleWarlord = "La historia de la señora de la guerra"
	me.nameTaleSlumbering = "La historia de los durmientes"
	me.nameTaleMagmaPact = "La historia del pacto de magma"
	me.nameTaleWeakling = "La historia de la criatura débil"

	me.professionMapping = { ['A'] = 'Alquimia', ['B'] = 'Herrería', ['C'] = 'Cocina', ['E'] = 'Encantamiento', ['F'] = 'Pesca', ['H'] = 'Hebalismo', ['I'] = 'Inscripción', ['J'] = 'Joyería', ['L'] = 'Peletería', ['M'] = 'Minería', ['N'] = 'Ingeniería', ['R'] = 'Equitación', ['S'] = 'Desuello', ['T'] = 'Sastrería', ['X'] = 'Arqueología', ['Z'] = 'Primeros auxilios', }

	local G = me.races
		G['A'][2] = 'Pandaren'
		G['A'][3] = 'Pandaren'
	G['B'][2] = 'Elfo de sangre'
	G['B'][3] = 'Elfa de sangre'
	G['C'][2] = 'Enano Hierro Negro'
	G['C'][3] = 'Enana Hierro Negro'
		G['D'][2] = 'Draenei'
		G['D'][3] = 'Draenei'
	G['E'][2] = 'Elfo de la noche'
	G['E'][3] = 'Elfa de la noche'
	G['F'][2] = 'Enano'
	G['F'][3] = 'Enana'
		G['G'][2] = 'Goblin'
		G['G'][3] = 'Goblin'
	G['H'][2] = 'Humano'
	G['H'][3] = 'Humana'
	G['I'][2] = 'Draenei forjado por la Luz'
	G['I'][3] = 'Draenei forjada por la Luz'
	G['J'][2] = "Orco Mag'har"
	G['J'][3] = "Orco Mag'har"
	G['K'][2] = 'Ciudadano de Kul Tiras'
	G['K'][3] = 'Ciudadana de Kul Tiras'
	G['L'][2] = 'Trol'
	G['L'][3] = 'Trol'
	G['M'][2] = 'Tauren Monte Alto'
	G['M'][3] = 'Tauren Monte Alto'
	G['N'][2] = 'Gnomo'
	G['N'][3] = 'Gnoma'
	G['O'][2] = 'Orco'
	G['O'][3] = 'Orco'
	G['Q'][2] = 'Mecagnomo'
	G['Q'][3] = 'Mecagnoma'
	G['R'][2] = 'Nocheterna'
	G['R'][3] = 'Nocheterna'
		G['S'][2] = 'Vulpera'
		G['S'][3] = 'Vulpera'
		G['T'][2] = 'Tauren'
		G['T'][3] = 'Tauren'
	G['U'][2] = 'No-muerto'
	G['U'][3] = 'No-muerta'
	G['V'][2] = 'Elfo del Vacío'
	G['V'][3] = 'Elfa del Vacío'
	G['W'][2] = 'Huargen'
	G['W'][3] = 'Huargen'
	G['X'][2] = 'Terráneo'
	G['X'][3] = 'Terránea'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Trol Zandalari'
	G['Z'][3] = 'Trol Zandalari'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "esMX" then
	me.accountUnlock = "Para toda la cuenta"
	me.bodyGuardLevel = { 'Guardaespaldas', 'De confianza', 'Copiloto personal' }
	me.friendshipLevel = { 'Extraño', 'Conocido', 'Colega', 'Amigo', 'Buen amigo', 'Mejor amigo' }
	me.friendshipMawLevel = { 'Sospechosa', 'Aprensiva', 'Vacilante', 'Ambivalente', 'Cordial', 'Appreciative' }

 	me.holidayMapping = { ['A'] = 'Amor en el Aire', ['B'] = 'Fiesta de la Cerveza', ['C'] = "Semana de los Niños", ['D'] = 'Día de los Muertos', ['E'] = 'WoW Anniversary', ['F'] = 'Feria de la Luna Negra', ['H'] = 'Festival de la Cosecha', ['K'] = "Competición de pesca Kalu'ak", ['L'] = 'Festival Lunar', ['M'] = 'Festival de Fuego del Solsticio de Verano', ['N'] = 'Jardín Noble', ['P'] = "Día de los Piratas", ['U'] = 'Nochevieja', ['V'] = 'Festival del Invierno', ['W'] = "Halloween", ['X'] = 'Concurso de Pesca', ['Y'] = "Generosidad del Peregrino", ['Z'] = "Semana navideña", ['a'] = 'Evento de ápices con bonificación', ['b'] ='Evento de refriegas de arena con bonificación', ['c'] = 'Evento de campos de batalla con bonificación', ['d'] = 'Evento de calabozo de Draenor', ['e'] = 'Evento de duelo de mascotas con bonificación', ['f'] = 'Evento de calabozo de cronoviaje', ['Q'] = "AQ", }

	me.nameTaleElders = "Historia de los ancianos"
	me.nameTaleOutsider = "Historia del forastero"
	me.nameTaleWarlord = "Historia de la señora de la guerra"
	me.nameTaleSlumbering = "Historia del largo sueño"
	me.nameTaleMagmaPact = "Historia del pacto de magma"
	me.nameTaleWeakling = "Historia del patético ser"

	me.professionMapping = { ['A'] = 'Alquimia', ['B'] = 'Herrería', ['C'] = 'Cocina', ['E'] = 'Encantamiento', ['F'] = 'Pesca', ['H'] = 'Hebalismo', ['I'] = 'Inscripción', ['J'] = 'Joyería', ['L'] = 'Peletería', ['M'] = 'Minería', ['N'] = 'Ingeniería', ['R'] = 'Equitación', ['S'] = 'Desuello', ['T'] = 'Sastrería', ['X'] = 'Arqueología', ['Z'] = 'Primeros auxilios', }

	local G = me.races
		G['A'][2] = 'Pandaren'
		G['A'][3] = 'Pandaren'
	G['B'][2] = 'Elfo de sangre'
	G['B'][3] = 'Elfa de sangre'
	G['C'][2] = 'Enano Hierro Negro'
	G['C'][3] = 'Enana Hierro Negro'
		G['D'][2] = 'Draenei'
		G['D'][3] = 'Draenei'
	G['E'][2] = 'Elfo de la noche'
	G['E'][3] = 'Elfa de la noche'
	G['F'][2] = 'Enano'
	G['F'][3] = 'Enana'
		G['G'][2] = 'Goblin'
		G['G'][3] = 'Goblin'
	G['H'][2] = 'Humano'
	G['H'][3] = 'Humana'
	G['I'][2] = 'Draenei templeluz'
	G['I'][3] = 'Draenei templeluz'
	G['J'][2] = "Orco mag'har"
	G['J'][3] = "Orco mag'har"
	G['K'][2] = 'Kultirano'
	G['K'][3] = 'Kultirana'
	G['L'][2] = 'Trol'
	G['L'][3] = 'Trol'
	G['M'][2] = 'Tauren de Altamontaña'
	G['M'][3] = 'Tauren de Altamontaña'
	G['N'][2] = 'Gnomo'
	G['N'][3] = 'Gnoma'
	G['O'][2] = 'Orco'
	G['O'][3] = 'Orco'
	G['Q'][2] = 'Mecagnomo'
	G['Q'][3] = 'Mecagnoma'
	G['R'][2] = 'Natonocturno'
	G['R'][3] = 'Natonocturna'
		G['S'][2] = 'Vulpera'
		G['S'][3] = 'Vulpera'
		G['T'][2] = 'Tauren'
		G['T'][3] = 'Tauren'
	G['U'][2] = 'No-muerto'
	G['U'][3] = 'No-muerta'
	G['V'][2] = 'Elfo del Vacío'
	G['V'][3] = 'Elfa del Vacío'
	G['W'][2] = 'Huargen'
	G['W'][3] = 'Huargen'
	G['X'][2] = 'Terráneo'
	G['X'][3] = 'Terránea'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Trol zandalari'
	G['Z'][3] = 'Trol zandalari'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "frFR" then
	me.accountUnlock = "Accès accordé au compte"
	me.bodyGuardLevel = { 'Garde du corps', 'Garde personnel', 'Bras droit' }
	me.friendshipLevel = { 'Étranger', 'Connaissance', 'Camarade', 'Ami', 'Bon ami', 'Meilleur ami' }
	me.friendshipMawLevel = { 'Méfiance', 'Crainte', 'Hésitation', 'Incertitude', 'Bienveillance', 'Appreciative' }

	me.holidayMapping = { ['A'] = "De l'amour dans l'air", ['B'] = 'Fête des Brasseurs', ['C'] = "Semaine des enfants", ['D'] = 'Jour des morts', ['E'] = 'WoW Anniversary', ['F'] = 'Foire de Sombrelune', ['H'] = 'Fête des moissons', ['K'] = "Tournoi de pêche kalu'ak", ['L'] = 'Fête lunaire', ['M'] = "Fête du Feu du solstice d'été", ['N'] = 'Le Jardin des nobles', ['P'] = "Jour des pirates", ['U'] = 'Nouvel an', ['V'] = "Voile d'hiver", ['W'] = "Sanssaint", ['X'] = 'Concours de pêche de Strangleronce', ['Y'] = "Bienfaits du pèlerin", ['Z'] = "Vacances de Noël", ['a'] = 'Évènement bonus Apogides', ['b'] ='Évènement bonus Escarmouches en arène', ['c'] = 'Évènement bonus Champs de bataille', ['d'] = 'Évènement Donjon de Draenor', ['e'] = 'Évènement bonus Combats de mascottes', ['f'] = 'Évènement Donjon des Marcheurs du temps', ['Q'] = "AQ", }

	me.nameTaleElders = "Conte des anciens"
	me.nameTaleOutsider = "Conte de l’étrangère"
	me.nameTaleWarlord = "Conte de la dame de guerre"
	me.nameTaleSlumbering = "Conte du sommeil"
	me.nameTaleMagmaPact = "Conte du pacte magmatique"
	me.nameTaleWeakling = "Conte de l’avorton"

	me.professionMapping = { ['A'] = 'Alchimie', ['B'] = 'Forge', ['C'] = 'Cuisine', ['E'] = 'Enchantement', ['F'] = 'Pêche', ['H'] = 'Herboristerie', ['I'] = 'Calligraphie', ['J'] = 'Joaillerie', ['L'] = 'Travail du cuir', ['M'] = 'Minage', ['N'] = 'Ingénierie', ['R'] = 'Monte', ['S'] = 'Dépeçage', ['T'] = 'Couture', ['X'] = 'Archéologie', ['Z'] = 'Secourisme', }

	local G = me.races
		G['A'][2] = 'Pandaren'
	G['A'][3] = 'Pandarène'
	G['B'][2] = 'Elfe de sang'
	G['B'][3] = 'Elfe de sang'
	G['C'][2] = 'Nain sombrefer'
	G['C'][3] = 'Naine sombrefer'
	G['D'][2] = 'Draeneï'
	G['D'][3] = 'Draeneï'
	G['E'][2] = 'Elfe de la nuit'
	G['E'][3] = 'Elfe de la nuit'
	G['F'][2] = 'Nain'
	G['F'][3] = 'Naine'
	G['G'][2] = 'Gobelin'
	G['G'][3] = 'Gobeline'
	G['H'][2] = 'Humain'
	G['H'][3] = 'Humaine'
	G['I'][2] = 'Draeneï sancteforge'
	G['I'][3] = 'Draeneï sancteforge'
	G['J'][2] = "Orc mag’har"
	G['J'][3] = "Orque mag’har"
	G['K'][2] = 'Kultirassien'
	G['K'][3] = 'Kultirassienne'
		G['L'][2] = 'Troll'
	G['L'][3] = 'Trollesse'
	G['M'][2] = 'Tauren de Haut-Roc'
	G['M'][3] = 'Taurène de Haut-Roc'
		G['N'][2] = 'Gnome'
		G['N'][3] = 'Gnome'
		G['O'][2] = 'Orc'
	G['O'][3] = 'Orque'
	G['Q'][2] = 'Mécagnome'
	G['Q'][3] = 'Mécagnome'
	G['R'][2] = 'Sacrenuit'
	G['R'][3] = 'Sacrenuit'
	G['S'][2] = 'Vulpérin'
	G['S'][3] = 'Vulpérine'
		G['T'][2] = 'Tauren'
	G['T'][3] = 'Taurène'
	G['U'][2] = 'Mort-vivant'
	G['U'][3] = 'Morte-vivante'
	G['V'][2] = 'Elfe du Vide'
	G['V'][3] = 'Elfe du Vide'
		G['W'][2] = 'Worgen'
		G['W'][3] = 'Worgen'
	G['X'][2] = 'Terrestre'
	G['X'][3] = 'Terrestre'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Troll zandalari'
	G['Z'][3] = 'Trolle zandalari'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "itIT" then
	me.accountUnlock = "Sblocco a livello di account"
	me.bodyGuardLevel = { 'Guardia del Corpo', 'Guardia Fidata', 'Scorta Personale' }
	me.friendshipLevel = { 'Estraneo', 'Conoscente', 'Compagno', 'Amico', 'Amico Intimo', 'Miglior Amico' }
	me.friendshipMawLevel = { 'Dubbiosa', 'Ansiosa', 'Incerta', 'Ambivalente', 'Cordiale', 'Appreciative' }

me.holidayMapping = {
    ['A'] = "Amore nell'Aria",
    ['B'] = 'Festa della Birra',
    ['C'] = "Settimana dei Bambini",
    ['D'] = 'Giorno dei Morti',
	['E'] = 'WoW Anniversary',
    ['F'] = 'Fiera di Lunacupa',
    ['H'] = 'Sagra del Raccolto',
	['K'] = "Gara di pesca dei Kalu'ak",
    ['L'] = 'Celebrazione della Luna',
    ['M'] = 'Fuochi di Mezza Estate',
    ['N'] = 'Festa di Nobiluova',
    ['P'] = "Giorno dei Pirati",
    ['U'] = 'New Year', -- LOCALIZE
    ['V'] = 'Vigilia di Grande Inverno',
    ['W'] = "Veglia delle Ombre",
    ['X'] = 'Gara di Pesca a Rovotorto',
    ['Y'] = "Ringraziamento del Pellegrino",
    ['Z'] = "Settimana di Natale",
['a'] = 'Evento bonus: Cristalli Apexis', ['b'] ='Evento bonus: schermaglie in arena', ['c'] = 'Evento bonus: campi di battaglia', ['d'] = 'Evento bonus: spedizioni di Draenor', ['e'] = 'Evento bonus: scontri tra mascotte', ['f'] = 'Evento bonus: Viaggi nel Tempo', ['Q'] = "AQ",     }

	me.nameTaleElders = "Storia degli anziani"
	me.nameTaleOutsider = "Storia dello straniero"
	me.nameTaleWarlord = "Storia della Signora della Guerra"
	me.nameTaleSlumbering = "Storia del torpore"
	me.nameTaleMagmaPact = "Storia del patto di magma"
	me.nameTaleWeakling = "Storia della debole creatura"

me.professionMapping = {
    ['A'] = 'Alchimia',
    ['B'] = 'Forgiatura',
    ['C'] = 'Cucina',
    ['E'] = 'Incantamento',
    ['F'] = 'Pesca',
    ['H'] = 'Erbalismo',
    ['I'] = 'Runografia',
    ['J'] = 'Oreficeria',
    ['L'] = 'Conciatura',
    ['M'] = 'Estrazione',
    ['N'] = 'Ingegneria',
    ['R'] = 'Riding', -- LOCALIZE
    ['S'] = 'Scuoiatura',
    ['T'] = 'Sartoria',
    ['X'] = 'Archeologia',
    ['Z'] = 'Primo Soccorso',
    }

	local G = me.races
		G['A'][2] = 'Pandaren'
		G['A'][3] = 'Pandaren'
	G['B'][2] = 'Elfo del Sangue'
	G['B'][3] = 'Elfa del Sangue'
	G['C'][2] = 'Nano Ferroscuro'
	G['C'][3] = 'Nana Ferroscuro'
		G['D'][2] = 'Draenei'
		G['D'][3] = 'Draenei'
	G['E'][2] = 'Elfo della Notte'
	G['E'][3] = 'Elfa della Notte'
	G['F'][2] = 'Nano'
	G['F'][3] = 'Nana'
		G['G'][2] = 'Goblin'
		G['G'][3] = 'Goblin'
	G['H'][2] = 'Umano'
	G['H'][3] = 'Umana'
	G['I'][2] = 'Draenei Forgialuce'
	G['I'][3] = 'Draenei Forgialuce'
	G['J'][2] = "Orco mag'har"
	G['J'][3] = "Orchessa Mag'har"
	G['K'][2] = 'Kul Tirano'
	G['K'][3] = 'Kul Tirana'
		G['L'][2] = 'Troll'
		G['L'][3] = 'Troll'
	G['M'][2] = 'Tauren di Alto Monte'
	G['M'][3] = 'Tauren di Alto Monte'
	G['N'][2] = 'Gnomo'
	G['N'][3] = 'Gnoma'
	G['O'][2] = 'Orco'
	G['O'][3] = 'Orchessa'
	G['Q'][2] = 'Meccagnomo'
	G['Q'][3] = 'Meccagnoma'
	G['R'][2] = 'Nobile Oscuro'
	G['R'][3] = 'Nobile Oscura'
		G['S'][2] = 'Vulpera'
		G['S'][3] = 'Vulpera'
		G['T'][2] = 'Tauren'
		G['T'][3] = 'Tauren'
	G['U'][2] = 'Non Morto'
	G['U'][3] = 'Non Morta'
	G['V'][2] = 'Elfo del Vuoto'
	G['V'][3] = 'Elfa del Vuoto'
		G['W'][2] = 'Worgen'
		G['W'][3] = 'Worgen'
	G['X'][2] = 'Terrigeno'
	G['X'][3] = 'Terrigena'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Troll Zandalari'
	G['Z'][3] = 'Troll Zandalari'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "koKR" then
	me.accountUnlock = "계정 공유 해제"
	me.bodyGuardLevel = { '경호원', '믿음직스러운 경호원', '개인 호위무사' }
	me.friendshipLevel = { '이방인', '지인', '동료', '친구', '좋은 친구', '가장 친한 친구' }
	me.friendshipMawLevel = { '의심', '불안', '불확신', '애증', '호감', 'Appreciative' }

	me.holidayMapping = { ['A'] = '온누리에 사랑을', ['B'] = '가을 축제', ['C'] = "어린이 주간", ['D'] = '망자의 날', ['E'] = 'WoW Anniversary', ['F'] = '다크문 축제', ['H'] = '추수절', ['K'] = '칼루아크 낚시 대회', ['L'] = '달의 축제', ['M'] = '한여름 불꽃축제', ['N'] = '귀족의 정원', ['P'] = "해적의 날", ['U'] = '새해맞이 전야제', ['V'] = '겨울맞이 축제', ['W'] = "할로윈 축제", ['X'] = '가시덤불 골짜기 낚시왕 선발대회', ['Y'] = "순례자의 감사절", ['Z'] = "한겨울 축제 주간", ['a'] = '에펙시스 보너스 이벤트', ['b'] ='투기장 연습 전투 보너스 이벤트', ['c'] = '전장 보너스 이벤트', ['d'] = '드레노어 던전 이벤트', ['e'] = '애완동물 대전 보너스 이벤트', ['f'] = '시간여행 던전 이벤트', ['Q'] = "AQ", }

	me.nameTaleElders = "장로 이야기"
	me.nameTaleOutsider = "이방인 이야기"
	me.nameTaleWarlord = "전쟁군주 이야기"
	me.nameTaleSlumbering = "잠자는 자 이야기"
	me.nameTaleMagmaPact = "용암의 서약 이야기"
	me.nameTaleWeakling = "나약한 자 이야기"

	me.professionMapping = { ['A'] = '연금술', ['B'] = '대장기술', ['C'] = '요리', ['E'] = '마법부여', ['F'] = '낚시', ['H'] = '약초채집', ['I'] = '주문각인', ['J'] = '보석세공', ['L'] = '가죽세공', ['M'] = '채광', ['N'] = '기계공학', ['R'] = '탈것 숙련', ['S'] = '무두질', ['T'] = '재봉술', ['X'] = '고고학', ['Z'] = '응급치료', }

	local G = me.races
	G['A'][2] = '판다렌'
	G['A'][3] = '판다렌'
	G['B'][2] = '블러드 엘프'
	G['B'][3] = '블러드 엘프'
	G['C'][2] = '검은무쇠 드워프'
	G['C'][3] = '검은무쇠 드워프'
	G['D'][2] = '드레나이'
	G['D'][3] = '드레나이'
	G['E'][2] = '나이트 엘프'
	G['E'][3] = '나이트 엘프'
	G['F'][2] = '드워프'
	G['F'][3] = '드워프'
	G['G'][2] = '고블린'
	G['G'][3] = '고블린'
	G['H'][2] = '인간'
	G['H'][3] = '인간'
	G['I'][2] = '빛벼림 드레나이'
	G['I'][3] = '빛벼림 드레나이'
	G['J'][2] = "마그하르 오크"
	G['J'][3] = "마그하르 오크"
	G['K'][2] = '쿨 티란'
	G['K'][3] = '쿨 티란'
	G['L'][2] = '트롤'
	G['L'][3] = '트롤'
	G['M'][2] = '높은산 타우렌'
	G['M'][3] = '높은산 타우렌'
	G['N'][2] = '노움'
	G['N'][3] = '노움'
	G['O'][2] = '오크'
	G['O'][3] = '오크'
	G['Q'][2] = '기계노움'
	G['Q'][3] = '기계노움'
	G['R'][2] = '나이트본'
	G['R'][3] = '나이트본'
	G['S'][2] = '불페라'
	G['S'][3] = '불페라'
	G['T'][2] = '타우렌'
	G['T'][3] = '타우렌'
	G['U'][2] = '언데드'
	G['U'][3] = '언데드'
	G['V'][2] = '공허 엘프'
	G['V'][3] = '공허 엘프'
	G['W'][2] = '늑대인간'
	G['W'][3] = '늑대인간'
	G['X'][2] = '토석인'
	G['X'][3] = '토석인'
	G['Y'][2] = '드랙티르'
	G['Y'][3] = '드랙티르'
	G['Z'][2] = '잔달라 트롤'
	G['Z'][3] = '잔달라 트롤'
	G['h'][2] = '하라니르'
	G['h'][3] = '하라니르'

elseif locale == "ptBR" then
	me.accountUnlock = "Desbloqueio de Conta"
	me.bodyGuardLevel = { 'Guarda-costas', 'Guarda-costas de Confiança', 'Copiloto Pessoal' }
	me.friendshipLevel = { 'Estranho', 'Conhecido', 'Camarada', 'Amigo', 'Bom Amigo', 'Grande Amigo' }
	me.friendshipMawLevel = { 'Indecisão', 'Apreensão', 'Hesitação', 'Ambivalência', 'Cordialidade', 'Appreciative' }

me.holidayMapping = { ['A'] = "O Amor Está No Ar", ['B'] = 'CervaFest', ['C'] = "Semana das Crianças", ['D'] = 'Dia dos Mortos', ['E'] = 'WoW Anniversary', ['F'] = 'Feira de Negraluna', ['H'] = 'Festival da Colheita', ['K'] = "Campeonato de Pesca dos Kalu'ak", ['L'] = 'Festival da Lua', ['M'] = "Festival do Fogo do Solsticio", ['N'] = 'Jardinova', ['P'] = "Dia dos Piratas", ['U'] = 'New Year', ['V'] = "Festa do Véu de Inverno", ['W'] = "Noturnália", ['X'] = 'Stranglethorn Fishing Extravaganza', ['Y'] = "Festa da Fartura", ['Z'] = "Semana Natalina", ['a'] = 'Evento Bônus de Apexis', ['b'] ='Evento Bônus de Escaramuças da Arena', ['c'] = 'Evento Bônus de Campos de Batalha', ['d'] = 'Evento das Masmorras de Draenor', ['e'] = 'Evento Bônus de Batalha de Mascotes', ['f'] = 'Evento das Masmorras de Caminhada Temporal', ['Q'] = "AQ", }

	me.nameTaleElders = "Contos dos Anciãos"
	me.nameTaleOutsider = "Contos do Forasteiro"
	me.nameTaleWarlord = "Contos da Senhora da Guerra"
	me.nameTaleSlumbering = "Contos do Adormecido"
	me.nameTaleMagmaPact = "Contos do Pacto de Magma"
	me.nameTaleWeakling = "Contos do Fraco"

me.professionMapping = {
	['A'] = 'Alquimia',
	['B'] = 'Ferraria',
	['C'] = 'Culinária',
	['E'] = 'Encantamento',
	['F'] = 'Paseca',
	['H'] = 'Herborismo',
	['I'] = 'Escrivania',
	['J'] = 'Joalheria',
	['L'] = 'Couraria',
	['M'] = 'Mineração',
	['N'] = 'Engenharia',
	['R'] = 'Montaria',
	['S'] = 'Esfolamentoa',
	['T'] = 'Alfaiataria',
	['X'] = 'Arqueologia',
	['Z'] = 'Primeiros Socorros',
	}

	local G = me.races
		G['A'][2] = 'Pandaren'
	G['A'][3] = 'Pandarena'
	G['B'][2] = 'Elfo Sangrento'
	G['B'][3] = 'Elfa Sangrenta'
	G['C'][2] = 'Anão Ferro Negro'
	G['C'][3] = 'Anã Ferro Negro'
		G['D'][2] = 'Draenei'
	G['D'][3] = 'Draenaia'
	G['E'][2] = 'Elfo Noturno'
	G['E'][3] = 'Elfa Noturna'
	G['F'][2] = 'Anão'
	G['F'][3] = 'Anã'
		G['G'][2] = 'Goblin'
	G['G'][3] = 'Goblina'
	G['H'][2] = 'Humano'
	G['H'][3] = 'Humana'
	G['I'][2] = 'Draenei Forjado a Luz'
	G['I'][3] = 'Draeneia Forjada a Luz'
	G['J'][2] = "Orc Mag'har"
	G['J'][3] = "Orc Mag'har"
	G['K'][2] = 'Kultireno'
	G['K'][3] = 'Kultirena'
		G['L'][2] = 'Troll'
	G['L'][3] = 'Trolesa'
	G['M'][2] = 'Tauren Altamontês'
	G['M'][3] = 'Taurena Altamontesa'
	G['N'][2] = 'Gnomo'
	G['N'][3] = 'Gnomida'
		G['O'][2] = 'Orc'
	G['O'][3] = 'Orquisa'
	G['Q'][2] = 'Gnomecânico'
	G['Q'][3] = 'Gnomecânica'
	G['R'][2] = 'Filho do Noite'
	G['R'][3] = 'Filha da Noite'
		G['S'][2] = 'Vulpera'
		G['S'][3] = 'Vulpera'
		G['T'][2] = 'Tauren'
	G['T'][3] = 'Taurena'
	G['U'][2] = 'Morto-vivo'
	G['U'][3] = 'Morta-viva'
	G['V'][2] = 'Elfo Caótico'
	G['V'][3] = 'Elfa Caótica'
		G['W'][2] = 'Worgen'
	G['W'][3] = 'Worgenin'
	G['X'][2] = 'Terrano'
	G['X'][3] = 'Terrano'
		G['Y'][2] = 'Dracthyr'
		G['Y'][3] = 'Dracthyr'
	G['Z'][2] = 'Troll Zandalari'
	G['Z'][3] = 'Trolesa Zandalari'
		G['h'][2] = 'Haranir'
		G['h'][3] = 'Haranir'

elseif locale == "ruRU" then
	me.accountUnlock = "Доступ для всей учетной записи"
	me.bodyGuardLevel = { 'Телохранитель', 'Доверенный боец', 'Боевой товарищ' }
	me.friendshipLevel = { 'Незнакомец', 'Знакомый', 'Приятель', 'Друг', 'Хороший друг', 'Лучший друг' }
	me.friendshipMawLevel = { 'Сомнения', 'Опасения', 'Настороженность', 'Безразличие', 'Сердечность', 'Appreciative' }

	me.holidayMapping = { ['A'] = 'Любовная лихорадка', ['B'] = 'Хмельной фестиваль', ['C'] = "Детская неделя", ['D'] = 'День мертвых', ['E'] = 'WoW Anniversary', ['F'] = 'Ярмарка Новолуния', ['H'] = 'Неделя урожая', ['K'] = "Калуакское рыбоборье", ['L'] = 'Лунный фестиваль', ['M'] = 'Огненный солнцеворот', ['N'] = 'Сад чудес', ['P'] = "День пирата", ['U'] = 'Канун Нового Года', ['V'] = 'Зимний Покров', ['W'] = "Тыквовин", ['X'] = 'Рыбная феерия Тернистой долины', ['Y'] = "Пиршество странников", ['Z'] = "Рождественская неделя", ['a'] = 'Событие: бонус к апекситовым кристаллам', ['b'] ='Событие: бонус за стычки на арене', ['c'] = 'Событие: бонус на полях боя', ['d'] = 'Событие: подземелья Дренора', ['e'] = 'Событие: бонус за битвы питомцев', ['f'] = 'Событие: путешествие во времени по подземельям', ['Q'] = "AQ", }

	me.nameTaleElders = "История о старейшинах"
	me.nameTaleOutsider = "История о чужаке"
	me.nameTaleWarlord = "История о вожде"
	me.nameTaleSlumbering = "История о спящих"
	me.nameTaleMagmaPact = "История о договоре Магмы"
	me.nameTaleWeakling = "История о ничтожестве"

	me.professionMapping = { ['A'] = 'Алхимия', ['B'] = 'Кузнечное дело', ['C'] = 'Кулинария', ['E'] = 'Наложение чар', ['F'] = 'Рыбная ловля', ['H'] = 'Травничество', ['I'] = 'Начертание', ['J'] = 'Ювелирное дело', ['L'] = 'Кожевничество', ['M'] = 'Горное дело', ['N'] = 'Механика', ['R'] = 'Верховая езда', ['S'] = 'Снятие шкур', ['T'] = 'Портняжное дело', ['X'] = 'Археология', ['Z'] = 'Первая помощь', }

	local G = me.races
	G['A'][2] = 'Пандарен'
	G['A'][3] = 'Пандаренка'
	G['B'][2] = 'Эльф крови'
	G['B'][3] = 'Эльфийка крови'
	G['C'][2] = 'Дворф из клана Черного Железа'
	G['C'][3] = 'Дворфийка из клана Черного Железа'
	G['D'][2] = 'Дреней'
	G['D'][3] = 'Дреней'
	G['E'][2] = 'Ночной эльф'
	G['E'][3] = 'Ночная эльфийка'
	G['F'][2] = 'Дворф'
	G['F'][3] = 'Дворф'
	G['G'][2] = 'Гоблин'
	G['G'][3] = 'Гоблин'
	G['H'][2] = 'Человек'
	G['H'][3] = 'Человек'
	G['I'][2] = 'Озаренный дреней'
	G['I'][3] = 'Озаренная дренейка'
	G['J'][2] = "Маг'хар"
	G['J'][3] = "Маг'харка"
	G['K'][2] = 'Култирасец'
	G['K'][3] = 'Култираска'
	G['L'][2] = 'Тролль'
	G['L'][3] = 'Тролль'
	G['M'][2] = 'Таурен Крутогорья'
	G['M'][3] = 'Тауренка Крутогорья'
	G['N'][2] = 'Гном'
	G['N'][3] = 'Гном'
	G['O'][2] = 'Орк'
	G['O'][3] = 'Орк'
	G['Q'][2] = 'Механогном'
	G['Q'][3] = 'Механогномка'
	G['R'][2] = 'Ночнорожденный'
	G['R'][3] = 'Ночнорожденная'
	G['S'][2] = 'Вульпера'
	G['S'][3] = 'Вульпера'
	G['T'][2] = 'Таурен'
	G['T'][3] = 'Таурен'
	G['U'][2] = 'Нежить'
	G['U'][3] = 'Нежить'
	G['V'][2] = 'Эльф Бездны'
	G['V'][3] = 'Эльфийка Бездны'
	G['W'][2] = 'Ворген'
	G['W'][3] = 'Ворген'
	G['X'][2] = 'Земельник'
	G['X'][3] = 'Земельник'
	G['Y'][2] = 'Драктир'
	G['Y'][3] = 'Драктир'
	G['Z'][2] = 'Зандалар'
	G['Z'][3] = 'Зандаларка'
	G['h'][2] = 'Харанир'
	G['h'][3] = 'Харанир'

elseif locale == "zhCN" then
	me.accountUnlock = "账号解锁"
	me.bodyGuardLevel = { '保镖', '贴身保镖', '亲密搭档' }
	me.friendshipLevel = { 'Stranger', 'Acquaintance', 'Buddy', 'Friend', 'Good Friend', '挚友' }
	me.friendshipMawLevel = { '猜忌', '防备', '犹豫', '纠结', '和善', 'Appreciative' }
	me.holidayMapping = { ['A'] = '情人节', ['B'] = '美酒节', ['C'] = "儿童周", ['D'] = '死人节', ['E'] = 'WoW Anniversary', ['F'] = '暗月马戏团', ['H'] = '收获节', ['K'] = "Tournoi de pêche kalu'ak", ['L'] = '春节', ['M'] = '仲夏火焰节', ['N'] = '复活节', ['P'] = "海盗日", ['U'] = '除夕夜', ['V'] = '冬幕节', ['W'] = "万圣节", ['X'] = '荆棘谷钓鱼大赛', ['Y'] = "感恩节", ['Z'] = "圣诞周", ['a'] = '埃匹希斯假日活动', ['b'] ='竞技场练习赛假日活动', ['c'] = '战场假日活动', ['d'] = '德拉诺地下城活动', ['e'] = '宠物对战假日活动', ['f'] = '时空漫游地下城活动', ['Q'] = "AQ", }

	me.nameTaleElders = "长老的故事"
	me.nameTaleOutsider = "外来者的故事"
	me.nameTaleWarlord = "督军的故事"
	me.nameTaleSlumbering = "沉眠的故事"
	me.nameTaleMagmaPact = "熔岩契约的故事"
	me.nameTaleWeakling = "弱者的故事"

	me.professionMapping = { ['A'] = '炼金术', ['B'] = '锻造', ['C'] = '烹饪', ['E'] = '附魔', ['F'] = '钓鱼', ['H'] = '草药学', ['I'] = '铭文', ['J'] = '珠宝加工', ['L'] = '制皮', ['M'] = '采矿', ['N'] = '工程学', ['R'] = '骑术', ['S'] = '剥皮', ['T'] = '裁缝', ['X'] = '考古学', ['Z'] = '急救', }

	local G = me.races
	G['A'][2] = '熊猫人'
	G['A'][3] = '熊猫人'
	G['B'][2] = '血精灵'
	G['B'][3] = '血精灵'
	G['C'][2] = '黑铁矮人'
	G['C'][3] = '黑铁矮人'
	G['D'][2] = '德莱尼'
	G['D'][3] = '德莱尼'
	G['E'][2] = '暗夜精灵'
	G['E'][3] = '暗夜精灵'
	G['F'][2] = '矮人'
	G['F'][3] = '矮人'
	G['G'][2] = '地精'
	G['G'][3] = '地精'
	G['H'][2] = '人类'
	G['H'][3] = '人类'
	G['I'][2] = '光铸德莱尼'
	G['I'][3] = '光铸德莱尼'
	G['J'][2] = "玛格汉兽人"
	G['J'][3] = "玛格汉兽人"
	G['K'][2] = '库尔提拉斯人'
	G['K'][3] = '库尔提拉斯人'
	G['L'][2] = '巨魔'
	G['L'][3] = '巨魔'
	G['M'][2] = '至高岭牛头人'
	G['M'][3] = '至高岭牛头人'
	G['N'][2] = '侏儒'
	G['N'][3] = '侏儒'
	G['O'][2] = '兽人'
	G['O'][3] = '兽人'
	G['Q'][2] = '机械侏儒'
	G['Q'][3] = '机械侏儒'
	G['R'][2] = '夜之子'
	G['R'][3] = '夜之子'
	G['S'][2] = '狐人'
	G['S'][3] = '狐人'
	G['T'][2] = '牛头人'
	G['T'][3] = '牛头人'
	G['U'][2] = '亡灵'
	G['U'][3] = '亡灵'
	G['V'][2] = '虚空精灵'
	G['V'][3] = '虚空精灵'
	G['W'][2] = '狼人'
	G['W'][3] = '狼人'
	G['X'][2] = '土灵'
	G['X'][3] = '土灵'
	G['Y'][2] = '龙希尔'
	G['Y'][3] = '龙希尔'
	G['Z'][2] = '赞达拉巨魔'
	G['Z'][3] = '赞达拉巨魔'
	G['h'][2] = '哈籁尼尔'
	G['h'][3] = '哈籁尼尔'

elseif locale == "zhTW" then
	me.accountUnlock = "帳號解鎖"
	me.bodyGuardLevel = { '保鏢', '信任的保鑣', '個人的搭檔' }
	me.friendshipLevel = { '陌生人', '熟識', '夥伴', '朋友', '好朋友', '最好的朋友' }
	me.friendshipMawLevel = { '懷疑', '不安', '猶豫', '籠統', '友善', 'Appreciative' }

	me.holidayMapping = { ['A'] = '愛就在身邊', ['B'] = '啤酒節', ['C'] = "兒童週", ['D'] = '亡者節', ['E'] = 'WoW Anniversary', ['F'] = '暗月馬戲團', ['H'] = '收穫節', ['K'] = "卡魯耶克釣魚大賽", ['L'] = '新年慶典', ['M'] = '仲夏火焰節慶', ['N'] = '貴族花園', ['P'] = "海賊日", ['U'] = '除夕夜', ['V'] = '冬幕節', ['W'] = "萬鬼節", ['X'] = '荊棘谷釣魚大賽', ['Y'] = "旅人豐年祭", ['Z'] = "聖誕週", ['a'] = '頂尖獎勵事件', ['b'] ='競技場練習戰獎勵事件', ['c'] = '戰場獎勵事件', ['d'] = '德拉諾地城事件', ['e'] = '寵物對戰獎勵事件', ['f'] = '時光漫遊地城事件', ['Q'] = "AQ", }

	me.nameTaleElders = "長老的故事"
	me.nameTaleOutsider = "外來者的故事"
	me.nameTaleWarlord = "督軍的故事"
	me.nameTaleSlumbering = "沉睡的故事"
	me.nameTaleMagmaPact = "熔岩契約的故事"
	me.nameTaleWeakling = "弱者的故事"

	me.professionMapping = { ['A'] = '鍊金術', ['B'] = '鍛造', ['C'] = '烹飪', ['E'] = '附魔', ['F'] = '釣魚', ['H'] = '草藥學', ['I'] = '銘文學', ['J'] = '珠寶設計', ['L'] = '製皮', ['M'] = '採礦', ['N'] = '工程學', ['R'] = '騎術', ['S'] = '剝皮', ['T'] = '裁縫', ['X'] = '考古學', ['Z'] = '急救', }

	local G = me.races
	G['A'][2] = '熊貓人'
	G['A'][3] = '熊貓人'
	G['B'][2] = '血精靈'
	G['B'][3] = '血精靈'
	G['C'][2] = '黑鐵矮人'
	G['C'][3] = '黑鐵矮人'
	G['D'][2] = '德萊尼'
	G['D'][3] = '德萊尼'
	G['E'][2] = '夜精靈'
	G['E'][3] = '夜精靈'
	G['F'][2] = '矮人'
	G['F'][3] = '矮人'
	G['G'][2] = '哥布林'
	G['G'][3] = '哥布林'
	G['H'][2] = '人類'
	G['H'][3] = '人類'
	G['I'][2] = '光鑄德萊尼'
	G['I'][3] = '光鑄德萊尼'
	G['J'][2] = "瑪格哈獸人"
	G['J'][3] = "瑪格哈獸人"
	G['K'][2] = '庫爾提拉斯人'
	G['K'][3] = '庫爾提拉斯人'
	G['L'][2] = '食人妖'
	G['L'][3] = '食人妖'
	G['M'][2] = '高嶺牛頭人'
	G['M'][3] = '高嶺牛頭人'
	G['N'][2] = '地精'
	G['N'][3] = '地精'
	G['O'][2] = '獸人'
	G['O'][3] = '獸人'
	G['Q'][2] = '機械地精'
	G['Q'][3] = '機械地精'
	G['R'][2] = '夜裔精靈'
	G['R'][3] = '夜裔精靈'
	G['S'][2] = '狐狸人'
	G['S'][3] = '狐狸人'
	G['T'][2] = '牛頭人'
	G['T'][3] = '牛頭人'
	G['U'][2] = '不死族'
	G['U'][3] = '不死族'
	G['V'][2] = '虛無精靈'
	G['V'][3] = '虛無精靈'
	G['W'][2] = '狼人'
	G['W'][3] = '狼人'
	G['X'][2] = '土靈'
	G['X'][3] = '土靈'
	G['Y'][2] = '半龍人'
	G['Y'][3] = '半龍人'
	G['Z'][2] = '贊達拉食人妖'
	G['Z'][3] = '贊達拉食人妖'
	G['h'][2] = '哈拉尼爾'
	G['h'][3] = '哈拉尼爾'

elseif locale == "enUS" or locale == "enGB" then
	-- do nothing as the default values are already in English
else
	print("Grail does not have any knowledge of the localization", locale)
end

--	Grail.notificationFrame is a hidden frame with the sole function of receiving
--	notifications from the Blizzard system
me.notificationFrame = CreateFrame("Frame")
me.notificationFrame:SetScript("OnEvent", function(frame, event, ...) Grail:_Tooltip_OnEvent(frame, event, ...) end)
me.notificationFrame:RegisterEvent("PLAYER_LOGIN")

end

--[[
		*** Design ***

		Blizzard provides API that details all the quests that their servers record a player as having completed.  However,
		this information does not show the entire picture, and could be misleading.  Therefore, Grail attempts to provide the
		user with a better picture of reality by adjusting and accounting for the Blizzard results.
		
			* Blizzard can record multiple quests as turned in, when one is turned in.  Sometimes this includes quests
				the player could never have completed (because they are class-specific, or from a different faction).
			* There are a class of quests that Blizzard never records as being completed (like truly repeatable ones).
			* Blizzard sometimes uses a FLAG quest to mark a phase change or completion of an event.
			* There are quests that once abandoned are not able to be gotten again, but an associated quest becomes
				available to take its place.  Sometimes there is no FLAG quest for this, and Grail attempts to handle
				this by using false FLAG quests.

		There are many aspects of the games that influence what quests are available to a player.  Some of these aspects are
		reasonably static, like race and faction, while others are more dynamic like level, and reputation levels.  Therefore,
		Grail monitors events to ensure it is aware of changes that influence the availability of quests.

			* Player class
			* Player race
			* Player faction
			* Player level (both level too low and level too high)
			* Player gender
			* Player profession level
			* Player reputation level (both too low and too high)
			* Player having completed achievements
			* Player having a specific buff
			* Player having or not having a specific item
			* Player having turned in or not turned in specific quests
			* Player having completed the requirements for specific quests
			* Player having abandoned specific quests
			* Player having specific quests in the quest log
			* Quests only available during specific holidays (or other events)

		Quests usually have only one NPC that gives the quest and one to which the quest is turned in.  However, there are
		quests that have more than one, including quests that are accepted or turned in without a direct NPC (meaning an
		automatic quest the player handles).  Most NPCs have a fixed position in the world, but some move in small paths.
		There are also NPCs that change positions depending on the phase the player is in.  Sometimes Blizzard changes the
		NPC ID of the NPC when they phase, and other times the NPC ID remains the same.

		Grail has its quest data configured using strings that are reasonably human-readable.  This fixed information is
		converted to numbers that are interpreted as bitfields upon loading.  This is the fixed data.  Each quest also has
		a status that is computed upon request based on the player-specific information in combination with the fixed data.
		This status is also a number to be interpreted as a bitfield where multiple aspects can be set.  Each of these
		numbers only uses 32 bits, even though the numbers may be able to hold more bits.

		Since the status of a quest may be somewhat expensive in computing because a quest's prerequisites may need to be
		computed, the status of each quest is only computed upon demand.  And once the status of a quest is computed it is
		cached so future requests do not recompute it.  This means Grail needs to understand what influences the status of
		a quest and therefore monitors those influences for changes.  When changes occurs, it invalidates the cached status
		of the quests and posts a notification to its observers indicating a quest status change.  Clients can then update
		their UIs to reflect the changes in quest statuses.

		The Blizzard API that is used to determine quest status varies and covers quite a few different types of API.  Each
		of these API does not return valid results until certain parts of the Blizzard system have been initialized, so
		Grail needs to ensure it does not rely on results from any of these API until certain events have occurred.  In fact,
		some of the information Blizzard returns needs to be queried after delays because Blizzard systems do not update
		immediately after events or expected UI interactions like pressing buttons.  Grail attempts to handle these by
		setting up a delayed system where it processed things after a time period has passed.

		The internal method that is used to indicate that quests are incompatible with each others works only when there is
		one quest from the group allowed at the same time.  However, there are cases where there are more than one allowed
		from a specific set, like the Anglers dailes for example.  For the Anglers, three of 14 quests are made available
		each day.  A player can still hold a quest from a previous day and if it is not one of the random quests for the
		day, three will be acceptable.  If a held quest is the same as one offered today, the total number of quests on the
		day will be reduced.  Therefore, Grail groups quests together that can have more and one from that set available at
		a time.  The group specifies how many are allowed from the set.  There are very few groups of quests, and so far
		they have all been dailies.

]]--
