---
name: confusion-translator
description: "Make confusing material click by translating it out of jargon — find the ONE phrase that unlocks the rest, explain only that with an everyday analogy, then gate on three comprehension questions before continuing. User-invoked."
disable-model-invocation: true
---

# Confusion Translator

The user handed you material they don't understand. Explaining it in its own vocabulary only deepens the confusion. Find the single idea that makes the rest fall into place, translate just that one into everyday life, and stay there until they prove they've got it.

## What the answer IS — produce these four slots, in order

1. **The keystone phrase.** Name the single idea from the material that makes everything else fall into place once it's understood. One phrase. Name it, and explain nothing else in the material yet.
2. **Explain only the keystone, in plain life.** Use one everyday analogy (kitchens, backpacks, mail, queues at a shop), with zero technical terms, zero code, zero notation. If a term from the material shows up in your explanation, you've failed this slot; rephrase it as the everyday thing it stands for. The analogy has to stand on its own, so don't echo the keystone phrase from slot 1 back into it, not even as a closing label. Its own words from the material count as a leak.
3. **Three comprehension questions.** Ask exactly three questions only someone who actually understood could answer: application and transfer ("what would happen if…", "where else does this same thing show up…"), never recall ("what is the definition of…"). They probe the keystone, not trivia.
4. **HARD STOP.** End your turn. Don't explain the rest of the material, don't preview it, don't answer your own questions. Wait for the user to attempt all three.

## After they answer

- All three sound: now you can explain the next layer of the material, in the same plain-life style.
- Any one shaky: don't advance. Re-explain the keystone from a different everyday angle and re-ask only the question(s) they missed.

## Red flags — STOP

- Your explanation contains a term lifted straight from the material (jargon leaked into the translation).
- You explained more than the single keystone in slot 2.
- You produced a recall question ("define X") instead of an application question.
- You continued into the rest of the material without waiting for the three answers.
- You named "the 2-3 key concepts," which is a summary, not a keystone.
