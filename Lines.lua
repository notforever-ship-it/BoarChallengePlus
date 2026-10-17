-- Boar Challenge +: the funny lines. Shown in a banner and in chat now and then while you kill boars, and when you
-- level, die, reach a milestone, set a record, beat your day's goal or keep a streak going. Switch them with
-- /boar lines off, rare or normal, or in the settings window.

local BC = BoarChallengePlus

BC.LINES = {
  -- now and then, while you kill boars
  kill = {
    "The boars have a group chat. You're the main topic.",
    "Somewhere, a boar just updated its will.",
    "Boars do not fear the dark. They fear you.",
    "That boar had plans. Big plans. Mostly mud.",
    "The local mud pit is getting very quiet.",
    "One more boar. The legend grows.",
    "Your sword has started humming a boar song.",
    "Boar census update: numbers falling fast.",
    "Trotters up! Another one done.",
    "Somewhere a boar mother says your name to scare the piglets.",
    "The boars have started a petition about you.",
    "You and boars: a long, one-sided story.",
    "Tusk count rising. Bag space falling.",
    "That boar never saw you coming. None of them do.",
    "The hogs are hiding. Not well, but they are trying.",
    "Fun fact: nobody has ever out-snorted you.",
    "The grass is greener where you have been.",
    "Keep swinging. The boars will not count themselves.",
    "This field used to be full of boars. Used to be.",
    "Your weapon wants a raise.",
    "A boar just whispered: not again.",
    "Boars rate you one star. You rate them XP.",
    "Every boar is a step. Keep walking.",
    "You smell faintly of boar. Wear it with pride.",
    "The boars are holding a meeting. You are not invited.",
    "Grind now, brag later.",
    "Somewhere, a druid is very upset with you.",
    "Snout count: going down.",
    "Your boar sense is tingling.",
    "That one squealed in a minor key.",
    "Bristles everywhere. Worth it.",
    "Not all heroes wear capes. Some smell of boar.",
    "The boars call you The Tusk Taker.",
    "Another boar returns to the great mud pit in the sky.",
    "Your map is just one big boar now.",
    "Slow and steady wins the boar race.",
    "XP tastes better when it oinks.",
    "One boar at a time. That is the whole plan.",
    "Boars ahead. Victory behind. Keep going.",
    "They spawn, you swing. Perfect teamwork.",
    "Even the vultures are impressed.",
    "Boring? Never. Boar-ing? Always.",
    "You have a gift. The boars disagree.",
    "Ten more and then a snack. Maybe twenty.",
    "The respawn timer fears you.",
    "Professional boar remover, at your service.",
    "The boars blame the weather. It is you.",
    "Your feet are tired. Your blade is not.",
    "Some climb mountains. You flatten boars.",
    "If boars had wanted posters, your face would be on all of them.",
    "Another tusk for the trophy wall.",
    "The piglets tell scary stories about you at night.",
    "Your hearthstone is jealous of how long you stay out here.",
    "The boar union wants a word.",
    "That was a good boar. It is in a better place now.",
    "Mud on your boots, XP in your bar.",
    "Patience is a virtue. So is pulling the next boar.",
    "Boars: zero. You: lots.",
    "You are not grinding. You are building a legend.",
    "Word is the boars are hiring a bodyguard.",
    "Snort less, swing more.",
    "A boar walked into a field. It did not walk out.",
    "Your road is paved with bristles.",
    "Boar fact: they do not like you. At all.",
    "The XP bar moves. Slowly. But it moves.",
    "Every boar you beat is a boar you never fight again.",
    "This spot has lovely boar views.",
    "Somewhere, a quest giver wonders where you went.",
    "Quest log? Never heard of it.",
    "The ground shakes. Oh wait, that is just you.",
    "The hunt goes on.",
    "A good day for boars. A bad day for boars.",
    "Who needs dungeons when you have boars?",
    "You are the reason boars travel in groups.",
    "Tusks are temporary. Glory is forever.",
    "The boars thought this was a quiet field.",
    "Bring snacks. The boars brought nothing.",
    "Patience of a mountain, swing of an avalanche.",
    "Somewhere, a boar is practising its battle cry. It will not help.",
    "The boars are learning. Too slowly.",
    "Squeal of approval: received.",
    "Stretch your fingers. The boars are not going anywhere.",
    "Fast hands, happy boar count.",
    "The leaderboard of one: you, on top.",
    "Boars fall, numbers climb.",
    "Expect scattered boars and heavy XP all day.",
    "Did that boar just roll its eyes at you?",
    "Your armour has a faint pork scent. Very fashionable.",
    "Hunters ask you for tips now.",
    "A mudslide of XP is coming your way.",
    "Boar after boar after boar. Bliss.",
    "Even your mount is bored. You are not.",
    "The respawns know your name.",
    "The boars hoped you had logged off. You had not.",
    "Your bags are full of tusks and good intentions.",
    "A boar a minute keeps the quest givers out of it.",
    "Somewhere a bard is writing a song about this. It is mostly squeals.",
    "You have seen more boars today than most people see in a lifetime.",
    "The boars are drawing straws to see who goes next.",
  },
  -- when you level up
  level = {
    "Level up! The boars felt that one.",
    "New level, same boars, bigger smile.",
    "Ding! Somewhere a boar heard it and ran.",
    "One level closer to 60. The boars are nervous.",
    "Level up! Your snout sense grows stronger.",
    "Another level, all on bristles and grit.",
    "The boars sent a card. It says: please stop.",
    "Ding! Treat yourself. Then back to the boars.",
    "New level unlocked: more boar.",
    "You went up. The boar count went down.",
    "That golden glow looks good on you.",
    "Level up! The mud pits salute you.",
    "Stronger, faster, still smelling of boar.",
    "Up you go. The boars stay down.",
    "Another step on the road to 60.",
    "New level! Your tusk collection approves.",
  },
  -- when you die
  death = {
    "Even the best boar hunters take a nap now and then.",
    "The boars got lucky. Write it down, it will not happen often.",
    "A small setback. A big comeback is coming.",
    "Spirit healers love a regular.",
    "Walk it off. Well, run it off. As a ghost.",
    "Every legend has a rough day.",
    "That boar will be telling this story for years.",
    "Down, but not out. Well, out for a moment.",
    "Take a breath. The boars are still there.",
    "Ghost run! Good exercise.",
    "Defeat is just a long way of saying: next time.",
    "Plot twist. Back in a minute.",
    "The boars celebrated. Briefly.",
    "Death is short. Boar grudges are forever.",
    "Shake it off and get back in the mud.",
  },
  -- at 100, 250, 500, 1,000 boars and on
  milestone = {
    "A whole herd, gone. Well done.",
    "The boar history books will remember this day.",
    "Some people count sheep. You count boars.",
    "That is a lot of tusks.",
    "Statues have been built for less.",
    "The boars have called an emergency meeting.",
    "A milestone! The mud pits weep.",
    "Look at that number. Just look at it.",
    "The boars send their regards. And their complaints.",
    "A number worth framing.",
  },
  -- a new personal record
  record = {
    "Your old self called. It wants a rematch.",
    "Best ever! The boars are writing letters.",
    "You just beat the best boar hunter you know: you.",
    "New record. Old record, take a seat.",
    "History was made. In a muddy field.",
    "Faster, stronger, more boar.",
    "Somebody frame this moment.",
    "The bar has been raised. By you. Again.",
  },
  -- the day's goal, or beating yesterday
  goal = {
    "Goal smashed. The boars felt it.",
    "Yesterday's you is very proud. And a bit jealous.",
    "Mission complete. Extra boars are a bonus.",
    "Today: won.",
    "Every boar from here on is a gift.",
    "You beat yesterday. Tomorrow is nervous.",
    "Daily dose of boar: delivered.",
    "That is how you do a day.",
  },
  -- 5, 10, 25, 50 and 100 boars in a row
  streak = {
    "No breaks, no mercy.",
    "The boars cannot catch their breath.",
    "On a roll, and the boars are rolling too.",
    "Keep the chain going!",
    "Unstoppable. Untouchable. Slightly muddy.",
    "Boar after boar, no rest.",
    "The streak is alive!",
    "Snacks can wait. The streak cannot.",
  },
}

-- A line of this kind: never the same as last time, and not one shown lately until most of them have been.
function BC.PickLine(kind)
  local list = BC.LINES[kind]
  if not list or not BC.db then return nil end
  local n = table.getn(list)
  if n == 0 then return nil end
  if n == 1 then return list[1] end
  if type(BC.db.seen[kind]) ~= "table" then BC.db.seen[kind] = {} end
  local seen, last = BC.db.seen[kind], BC.db.lastLine[kind]
  local count = 0
  for i in pairs(seen) do
    if type(i) == "number" and i <= n then count = count + 1 end
  end
  if count >= math.floor(n * 0.8) then
    seen = {}
    BC.db.seen[kind] = seen
  end
  local free = {}
  for i = 1, n do
    if not seen[i] and i ~= last then table.insert(free, i) end
  end
  if table.getn(free) == 0 then
    for i = 1, n do
      if i ~= last then table.insert(free, i) end
    end
  end
  local pick = free[math.random(table.getn(free))]
  seen[pick] = true
  BC.db.lastLine[kind] = pick
  return list[pick]
end
