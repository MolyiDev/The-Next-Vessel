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

	--==[ Second Scene: The Descent ]==--
	-- In this scene is where the game loop starts.
	-- The player can die many times he wants and he will be granted a wish to be able to win the battle.
	-- So everytime you die you become stronger because of the wishes you've made.
	-- The hero slowly loses his 'hero' persona and becomes obsessed with power/winning.

	-- Level 0: Determination
	Second_Hero_Start_0 = [[I will save this world, no matter how many times I die!]],
	Second_DemonKing_Start_0 = [[Save the world? You barely saved yourself.]],

	-- Level 1: Frustration
	Second_Hero_Start_1 = [[Why won't you just die?!]],
	Second_DemonKing_Start_1 = [[Persistence is a virtue. Until it becomes a shackle.]],

	-- Level 2: Desperation
	Second_Hero_Start_2 = [[I don't care how much it takes. I will crush you to dust!]],
	Second_DemonKing_Start_2 = [[Yes... let the anger guide your hand. It's easier that way.]],

	-- Level 3: Obsession
	Second_Hero_Start_3 = [[I'm going to enjoy tearing that armor off your corpse. Piece by Piece.]],
	Second_DemonKing_Start_3 = [[You have forgotten why you came here, haven't you?]],

	-- Level 4: Complete Corruption
	Second_Hero_Start_4 = [[MORE! I NEED MORE! FIGHT ME! FEED ME!]],
	Second_DemonKing_Start_4 = [[And there it is. The eyes of a beast.]],

	-- Level 5: Loop Dialogues
	Second_Hero_Start_5 = [[]],
	Second_DemonKing_Start_5 = [[]],

	-- Battle

	-- If the player died:
	-- The demon king will say something
	-- Then the white flame will say something
	-- The player choose another wish
	-- Restart Scene 3 until the player can kill the demon king
	Second_DemonKing_Finish_0 = [[Disappointing.]],
	Second_DemonKing_Finish_1 = [[Is that all the 'divine power' gave you?]],
	Second_DemonKing_Finish_2 = [[You are losing yourself.]],
	Second_DemonKing_Finish_3 = [[Rest now. The cycle... it breaks us all eventually.]],
	Second_DemonKing_Finish_4 = [[Pitiful. You are not ready.]],
	Second_DemonKing_Finish_5 = [[What a shame, after all that power you still cannot defeat me.]],

	Second_White_Start_0 = [[What do you crave?]],
	Second_White_Start_1 = [[The enemy is strong. Do not be afraid to ask for help.]],
	Second_White_Start_2 = [[Your soul is resilient. It can handle a little more burden.]],
	Second_White_Start_3 = [[You are so close. You just need that extra edge. Take it.]],
	Second_White_Start_4 = [[Forget the cost. Focus on the power. Wish for it.]],
	Second_White_Start_5 = [[...]],

	Second_White_Finish_0 = [[]],
	Second_White_Finish_1 = [[]],
	Second_White_Finish_2 = [[]],
	Second_White_Finish_3 = [[You cannot fail anymore.]],
	Second_White_Finish_4 = [[See you on the other side.]],
	Second_White_Finish_5 = [[...]],

	-- If the player killed the demon king:
	--==[ Third Scene: The Revelation ]==--
	-- The should be 'downed' to it's knee and the player can do a quick action on him.
	-- When doing the quick action the player will put his sword up and prepare for a strong swing.
	-- When the swing of the sword is going down fast the demon king grabs the blade of the sword.

	Third_DemonKing_0 = [[You... you actually pushed me this far...]],
	Third_DemonKing_1 = [[But I cannot die. Not like this.]],

	-- The demon king breaks the hero sword and punches the hero back.
	-- While the demon king is talking there appears 3 health bars more.
	Third_DemonKing_2 = [[Do you think you are the first? This throne is a curse, not a prize.]],
	Third_DemonKing_3 = [[I am but an unholy copy of life. A mockery of its freedom. And born in the cruel betrayal of the noble ideas I would've served.]],
	Third_DemonKing_4 = [[Now... it is your turn.]],

	-- After the last line of the demon king, he grabs the hero by it's head and shatter it in a million pieces.

	-- On the soul realm:
	Third_Hero_0 = [[This cannot be...]],
	Third_Hero_1 = [[I GAVE EVERYTHING! MY SOUL! MY HUMANITY!]],
	Third_Hero_2 = [[I NEED MORE POWER to finish this! I CRAVE IT!]],
	Third_Hero_3 = [[WHITE FLAME! GOD! WHY DO YOU NOT ANSWER?!]],
	Third_Hero_4 = [[DID YOU USE ME? WAS I JUST A PAWN FOR YOUR AMUSEMENT?]],
	Third_Hero_5 = [[ANSWER MEEEE!]],

	-- Whispers starts to be heared. These text shakes in random parts of the screen.
	-- "you're alone", "you are no more a hero", "you're corrupted", "you are one of us", "you belong down here"
	Whisper_0 = [[you are alone...]],
	Whisper_1 = [[no longer a hero...]],
	Whisper_2 = [[one of us...]],
	Whisper_3 = [[you belong down here...]],

	Third_DemonGod_0 = [[The voices of the sky cannot longer reach you down here.]],
	Third_Hero_6 = [[Who dares speak from the shadows? Show yourself! I am the Chosen One!]],

	-- A red flame appears
	Third_DemonGod_1 = [[The light abandons those who corrupt. But I... I give them a new purpose.]],
	Third_Hero_7 = [[Corrupted...? No... I am the Savior...]],

	Third_DemonGod_2 = [[Look at yourself. You don't want to save the world anymore. You just want to kill, battle, and consume.]],
	Third_Hero_8 = [[No... I... I can stop! I can still go back!]],

	Third_DemonGod_3 = [[Can you? After all you've sacrificed? After that god of yours played you for a fool? If you stop now, you die a failure. But I offer you the ultimate wish... to become what you desire most.]],
	Third_Hero_9 = [[I... I cannot lose... GIVE ME MORE POWER!]],

	Third_DemonGod_4 = [[Good. Then become my next Vessel.]],

	-- The flame goes right trought the hero and enters inside him.
	-- The hero comes back to life, but he does not goes back in time.
	Third_Hero_10 = [[AGH! IT BURNS!.]],
	Third_Hero_11 = [[IT'S... OVERWHELMING!]],

	Third_DemonGod_5 = [[Stabilize yourself. Consume the Old King. Take his place.]],

	Third_DemonKing_5 = [[So, you've returned. And it seems that it's finally my time to rest.]],

	-- Here a cinematic 'battle' happens, maybe with quick action.
	-- When the 'Hero' kills the demon king, the soul of the demon king goes out of it's body.
	-- The hero can see how it is normal, it's not a monster, it's a human, just, like you, but even like this
	-- The hero grabs it's soul and destroys it, shattering to glass pieces.

	Third_NewDemonKing_0 = [[I DID IT. THIS IS WHAT YOU WANTED, RIGHT? I'VE COMPLETED MY MISSION, GIVE ME MY REWARD.]],

	Third_White_0 = [[My wayward son... you are no longer deserving of a reward. Just look at what you have become.]],

	-- The glass pieces from the soul comes up, reflecting the thing that the hero is now, a demon.
	Third_NewDemonKing_1 = [[No... NO! It's your fault! You pushed me to this! I only followed your orders!]],

	-- The glass pieces fall to the ground again.
	Third_White_1 = [[I offered you the tools to save the world. You used them to feed yourself. The throne... is your reward.]],

	-- The New Demon King now goes and grabs the weapon of the old one, and sits in his throne.
	Third_NewDemonKing_2 = [[But it is so cold... and silent.]],

	-- All the torches turn off. He sits in darkness for "Years".

	-- The door opens again, and a man with a shiny armor enters. The torches turn on sequentially.

	Third_NewHero_0 = [[I have traveled for years for this moment. I will kill you and free the world from your tyranny!]],
	Third_NewDemonKing_3 = [[So... this is how it is]],

	-- The new demon king grabs his trident and throws it to the new hero.
	-- Then the new hero dies, and after some seconds of silence it's body gets eaten by a white flame.

	-- Then the screen goes black and the credits start rolling.
})
