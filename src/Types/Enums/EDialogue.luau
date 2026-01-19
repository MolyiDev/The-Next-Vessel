return table.freeze({
	--==[ First Scene: The Beginning ]==--

	-- The hero opens the door of the demon king throne room
	-- It's a dark room, the hero enters and the door closes behind him.
	-- Suddenly all the torches light up in sequentially order.
	-- The hero sees the demonking.

	First_Hero_0 = [[I have traveled for years for this moment.  I will kill you and free the world from your tyranny!]],
	First_DemonKing_0 = [[<speed val="0.1">So... this is how it is...</speed>]],

	-- The Demon King grabs his trident and throws it at the hero resulting in the death of the hero.

	First_Hero_1 = [[<speed val="0.2">I...</speed> I couldn't even see it...]],
	First_Hero_2 = [[It <shake val="1">cannot</shake> end like this...]],
	First_Hero_3 = [[<shake val="3"><speed val="0.02">IT CANNOT END LIKE THIS!</speed></shake>]],

	-- A white flame burns in front of the soul of the hero in the other side.

	First_White_0 = [[I hear your plea, brave soul.]],
	First_White_1 = [[The Vessel of the Demon God... it must be destroyed.]],
	First_White_2 = [[My power is yours, but be warned: the soul is fragile, and power is heavy.]],
	First_White_3 = [[Make a wish to overcome this trial. Choose only what is necessary.]],

	-- Two wishes comes to the mind of the hero:
	-- Be able to deflect attacks.
	-- Be able to dodge attacks.

	-- The hero picks one of the three wishes.

	First_White_4 = [[Farewell. May you find victory in this new life.]],

	--==[ Second Scene: The First Loop ]==--

	-- The hero opens the door of the demon king throne room

	Second_Hero_0 = [[Now it is your turn to fall.]],
	Second_DemonKing_0 = [[I would like to see you try.]],

	-- The Demon King grabs his trident and throws it at the hero

	-- The time slows down to show the player how to use it's new ability
	-- If the player selected 'Be able to deflect attacks' it will appear 'Use Right Click in the right moment to deflect/parry'.
	-- If the player selected 'Be able to dodge attacks' it will appear 'Use Q to dodge'.

	-- If the player dies on the quick action (Didn't press anything):
	-- It appears a white flame in front of the hero after death.
	White_EarlyDeath = [[You squandered your wish. Focus. Try again.]],
	-- then scene two starts again.

	-- If the player pressed the key correctly then
	-- If the player selected 'Be able to deflect attacks' then it will deflect the attack.
	-- If the player selected 'Be able to dodge attacks' then it will dodge the attack.

	-- After deflecting or dodging the demonking reacts:

	Second_DemonKing_1 = [[Not bad. A spark of potential, perhaps.]],

	-- The player now begins a battle with the demon king that will eventually fail because the demon king it's still too strong, the demonking reacts:

	Second_DemonKing_2 = [[I was expecting too much from a mortal.]],

	-- On the souls realm a white flame appears in front of the hero.

	Second_White_0 = [[You failed. Tell me... what do you lack?]],

	-- Depending on the attacks that killed the player different wishes will appear on death:
	-- If the player died because of an attack that is deflectable and doesnt have the deflect then the wish 'Be able to deflect attacks' will appear
	-- If the player died because of an attack that is not deflectable and doesnt have the dodge then the wish 'Be able to dodge attacks' will appear
	-- If the player died while the boss was 'hardened' and doesnt have the ability to break the 'hardened skin' then the wish 'Be able to break harden' will appear
	-- If the player died because of the boss poison and doesnt have the poison resistance  then the wish 'Be able to withstand poison' will appear
	-- If the player died after failing a parry and doesnt have the ability to block then the wish 'Be able to block' will appear

	-- Common wishes will appear everytime:
	-- 'Be stronger' gives you +20% damage.
	-- 'Be faster' makes the boss go 10% slower.
	-- 'Be more resistant' gives you +20% health.

	Second_White_1 = [[Great choice. I believe in you.]],

	--==[ Third Scene: The Descent ]==--
	-- In this scene is where the game loop starts.
	-- The player can die many times he wants and he will be granted a wish to be able to win the battle.
	-- So everytime you die you become stronger because of the wishes you've made.
	-- The hero slowly loses his 'hero' persona and becomes obsessed with power/winning.

	-- Level 0: Determination
	Third_Hero_Start_0 = [[I will save this world, no matter how many times I die!]],
	Third_DemonKing_Start_0 = [[Save the world? You barely saved yourself.]],

	-- Level 1: Frustration
	Third_Hero_Start_1 = [[Why won't you just die?!]],
	Third_DemonKing_Start_1 = [[Persistence is a virtue. Until it becomes a shackle.]],

	-- Level 2: Desperation
	Third_Hero_Start_2 = [[I don't care how much it takes. I will crush you to dust!]],
	Third_DemonKing_Start_2 = [[Yes... let the anger guide your hand. It's easier that way.]],

	-- Level 3: Obsession
	Third_Hero_Start_3 = [[I'm going to enjoy tearing that armor off your corpse. Piece by Piece.]],
	Third_DemonKing_Start_3 = [[You have forgotten why you came here, haven't you?]],

	-- Level 4: Complete Corruption
	Third_Hero_Start_4 = [[MORE! I NEED MORE! FIGHT ME! FEED ME!]],
	Third_DemonKing_Start_4 = [[And there it is. The eyes of a beast.]],

	-- Level 5: Loop Dialogues
	Third_Hero_Start_5 = [[]],
	Third_DemonKing_Start_5 = [[]],

	-- Battle

	-- If the player died:
	-- The demon king will say something
	-- Then the white flame will say something
	-- The player choose another wish
	-- Restart Scene 3 until the player can kill the demon king
	Third_DemonKing_Finish_0 = [[Disappointing.]],
	Third_DemonKing_Finish_1 = [[Is that all the 'divine power' gave you?]],
	Third_DemonKing_Finish_2 = [[You are losing yourself.]],
	Third_DemonKing_Finish_3 = [[Rest now. The cycle... it breaks us all eventually.]],
	Third_DemonKing_Finish_4 = [[Pitiful. You are not ready.]],
	Third_DemonKing_Finish_5 = [[What a shame, after all that power you still cannot defeat me.]],

	Third_White_Start_0 = [[What do you crave?]],
	Third_White_Start_1 = [[The enemy is strong. Do not be afraid to ask for help.]],
	Third_White_Start_2 = [[Your soul is resilient. It can handle a little more burden.]],
	Third_White_Start_3 = [[You are so close. You just need that extra edge. Take it.]],
	Third_White_Start_4 = [[Forget the cost. Focus on the power. Wish for it.]],
	Third_White_Start_5 = [[...]],

	Third_White_Finish_0 = [[]],
	Third_White_Finish_1 = [[]],
	Third_White_Finish_2 = [[]],
	Third_White_Finish_3 = [[You cannot fail anymore.]],
	Third_White_Finish_4 = [[See you on the other side.]],
	Third_White_Finish_5 = [[...]],

	-- If the player killed the demon king:
	--==[ Fourth Scene: The Revelation ]==--
	-- The should be 'downed' to it's knee and the player can do a quick action on him.
	-- When doing the quick action the player will put his sword up and prepare for a strong swing.
	-- When the swing of the sword is going down fast the demon king grabs the blade of the sword.

	Fourth_DemonKing_0 = [[You... you actually pushed me this far...]],
	Fourth_DemonKing_1 = [[But I cannot die. Not like this.]],

	-- The demon king breaks the hero sword and punches the hero back.
	-- While the demon king is talking there appears 3 health bars more.
	Fourth_DemonKing_2 = [[Do you think you are the first? This throne is a curse, not a prize.]],
	Fourth_DemonKing_3 = [[I am but an unholy copy of life. A mockery of its freedom. And born in the cruel betrayal of the noble ideas I would've served.]],
	Fourth_DemonKing_4 = [[Now... it is your turn.]],

	-- After the last line of the demon king, he grabs the hero by it's head and shatter it in a million pieces.

	-- On the soul realm:
	Fourth_Hero_0 = [[This cannot be...]],
	Fourth_Hero_1 = [[I GAVE EVERYTHING! MY SOUL! MY HUMANITY!]],
	Fourth_Hero_2 = [[I NEED MORE POWER to finish this! I CRAVE IT!]],
	Fourth_Hero_3 = [[WHITE FLAME! GOD! WHY DO YOU NOT ANSWER?!]],
	Fourth_Hero_4 = [[DID YOU USE ME? WAS I JUST A PAWN FOR YOUR AMUSEMENT?]],
	Fourth_Hero_5 = [[ANSWER MEEEE!]],

	-- Whispers starts to be heared. These text shakes in random parts of the screen.
	-- "you're alone", "you are no more a hero", "you're corrupted", "you are one of us", "you belong down here"
	Whisper_0 = [[you are alone...]],
	Whisper_1 = [[no longer a hero...]],
	Whisper_2 = [[one of us...]],
	Whisper_3 = [[you belong down here...]],

	Fourth_DemonGod_0 = [[The voices of the sky cannot longer reach you down here.]],
	Fourth_Hero_6 = [[Who dares speak from the shadows? Show yourself! I am the Chosen One!]],

	-- A red flame appears
	Fourth_DemonGod_1 = [[The light abandons those who corrupt. But I... I give them a new purpose.]],
	Fourth_Hero_7 = [[Corrupted...? No... I am the Savior...]],

	Fourth_DemonGod_2 = [[Look at yourself. You don't want to save the world anymore. You just want to kill, battle, and consume.]],
	Fourth_Hero_8 = [[No... I... I can stop! I can still go back!]],

	Fourth_DemonGod_3 = [[Can you? After all you've sacrificed? After that god of yours played you for a fool? If you stop now, you die a failure. But I offer you the ultimate wish... to become what you desire most.]],
	Fourth_Hero_9 = [[I... I cannot lose... GIVE ME MORE POWER!]],

	Fourth_DemonGod_4 = [[Good. Then become my next Vessel.]],

	-- The flame goes right trought the hero and enters inside him.
	-- The hero comes back to life, but he does not goes back in time.
	Fourth_Hero_10 = [[AGH! IT BURNS!.]],
	Fourth_Hero_11 = [[IT'S... OVERWHELMING!]],

	Fourth_DemonGod_5 = [[Stabilize yourself. Consume the Old King. Take his place.]],

	Fourth_DemonKing_5 = [[So, you've returned. And it seems that it's finally my time to rest.]],

	-- Here a cinematic 'battle' happens, maybe with quick action.
	-- When the 'Hero' kills the demon king, the soul of the demon king goes out of it's body.
	-- The hero can see how it is normal, it's not a monster, it's a human, just, like you, but even like this
	-- The hero grabs it's soul and destroys it, shattering to glass pieces.

	Fourth_NewDemonKing_0 = [[I DID IT. THIS IS WHAT YOU WANTED, RIGHT? I'VE COMPLETED MY MISSION, GIVE ME MY REWARD.]],

	Fourth_White_0 = [[My wayward son... you are no longer deserving of a reward. Just look at what you have become.]],

	-- The glass pieces from the soul comes up, reflecting the thing that the hero is now, a demon.
	Fourth_NewDemonKing_1 = [[No... NO! It's your fault! You pushed me to this! I only followed your orders!]],

	-- The glass pieces fall to the ground again.
	Fourth_White_1 = [[I offered you the tools to save the world. You used them to feed yourself. The throne... is your reward.]],

	-- The New Demon King now goes and grabs the weapon of the old one, and sits in his throne.
	Fourth_NewDemonKing_2 = [[But it is so cold... and silent.]],

	-- All the torches turn off. He sits in darkness for "Years".

	-- The door opens again, and a man with a shiny armor enters. The torches turn on sequentially.

	Fourth_NewHero_0 = [[I have traveled for years for this moment. I will kill you and free the world from your tyranny!]],
	Fourth_NewDemonKing_3 = [[So... this is how it is]],

	-- The new demon king grabs his trident and throws it to the new hero.
	-- Then the new hero dies, and after some seconds of silence it's body gets eaten by a white flame.

	-- Then the screen goes black and the credits start rolling.
})
