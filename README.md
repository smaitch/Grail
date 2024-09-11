# Grail

Grail is a library of World of Warcraft quest information designed to provide that quest information to other addons to make their decision processing easier. For example, an addon like EveryQuest or TourGuide would be able to make use of Grail's knowledge to determine if a quest has been completed, whether the character can obtain a quest, what reasons the character cannot obtain a quest (lack of level, wrong race, wrong class, not enough reputation, has not completed a prerequisite quest, etc.), the location to obtain or turn in a quest, the amount of reputation awarded from completing a quest, whether a quest counts towards an achievement, etc.

Starting with version 029, Grail's achievement and reputation gained information are separated into two loadable on demand addons included in the package. Starting with version 049, Grail includes a loadable on demand addon that records when a quest is complete, and how many times if it is repeatable.

Please create a ticket if you find problems.

# Making Grail better

As a user of Grail plays WoW, Grail's internal database is checked as a player accepts and turns in quests. If Grail has incorrect data, it will record the actual data the player has found in the Grail saved variables file. This file can be used to update Grail for future releases if you choose to provide this information (in a ticket for example). As the Grail database becomes more accurate, the Grail saved variables file will have any previously found discrepencies removed. The Grail saved variables file can be found in your /WoW directory/WTF/Account/account name/SavedVariables directory with the name Grail.lua.

Using the slash command /grail help lists all the options Grail has.
