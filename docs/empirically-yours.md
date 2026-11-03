# Same Money, Different Feelings

*Empirically Yours · Household Finance Lab · Project 4*

Two households earn about the same. They have about the same in savings. Ask each one how secure they feel about money, and you can get two very different answers.

Anyone who has worked with households has seen this. Money explains a lot of how people feel about their finances. It doesn't seem to explain all of it.

So we asked a plain question. Once you account for money, does the way people approach decisions tell you anything about how financially secure they feel?

## Where we looked

The Consumer Financial Protection Bureau surveyed U.S. adults in 2016 and gave each one its Financial Well-Being Scale: ten questions about getting by, handling a surprise expense, being on track, and having room to enjoy life. The CFPB turns the answers into a single score. We used 6,219 adults and the score exactly as published.

The same survey asked about decision habits. Three statements on self-control:

- "I often act without thinking through all the alternatives."
- "I am good at resisting temptation."
- "I am able to work diligently toward long-term goals."

And one question on planning horizon: when you plan your saving and spending, how far ahead do you look? The answers run from the next few months to longer than ten years.

The survey also recorded people's money: income, savings, hardships like a utility shutoff, calls from debt collectors, credit denials. That is the part we held constant.

## Something didn't add up

The easy move is to average the three self-control statements into one score. The CFPB's own analysis did exactly that.

We checked first. The three statements don't hang together. The first one, about acting without thinking, barely moves with the other two.

That fits research on self-control scales, which finds two separate things inside them: restraint and impulsivity. So we kept them apart. Self-discipline became the average of the temptation and long-term-goals statements. Impulsivity stayed on its own.

Check the parts before you trust the whole.

## How we tested it

Two people, two questions.

Lena asked the explanation question in Stata: among people in similar financial circumstances, do those with more self-discipline, less impulsivity, and longer horizons report higher well-being? She built the model in three steps, adding demographics, then money, then the decision habits, and measured what each step added.

Sara asked the prediction question in Python: if you already know someone's money, do their decision habits help you guess their score more accurately? She trained models on most of the sample and tested them on people the models had never seen, 25 times over.

Neither answer stands in for the other. A habit can be clearly associated with well-being across the population and still add almost nothing to predicting one person. In an earlier Lab project, that is exactly what happened.

## What we found

Money and demographics accounted for about **half** of the variation in how secure people felt.

The decision habits added a modest slice on top. People with more self-discipline, less impulsivity, and longer planning horizons reported higher well-being, even compared with people whose money looked similar.

This time the two questions agreed. The habits also improved prediction, by about the same amount, in every one of Sara's 25 tests and in both kinds of model she ran.

Small, but steady.

## The interesting part

Three things surprised us.

**One statement did the work.** When we split self-discipline back into its two statements, "I am able to work diligently toward long-term goals" carried the association. "I am good at resisting temptation" did not show a clear one once everything else was in the model. What tracked well-being here was persistence toward goals more than willpower in the moment.

**Impulsivity lives in the present.** Acting without thinking was tied to how people felt about getting by now. It showed no clear link to how they felt about the future. Another research team found the same split with different questions, in a different study.

**We guessed wrong on the future.** We expected self-discipline to matter more for present-day stress. It mattered more for confidence about the future.

The data get a vote. That part stays in.

## What we can say, and what we can't

We can say that, among people with similar money, decision habits carry real information about how secure they feel, and that information helps predict it.

We can't say the habits cause the feeling. The survey caught each person once. Feeling secure might make it easier to stick to long-term goals, as much as the other way round.

Two checks also cut the association roughly in half: adding how hard it is to cover monthly bills, and adding general life satisfaction. It stayed clearly positive in both. A generally upbeat outlook may explain some of what we see.

The measures are short (two statements, one statement, one question), all self-reported, and from 2016.

About 3 percent of people skipped one of these questions. They were poorer and more often people of color. Filling in their answers statistically didn't change the result, but the findings may describe them less well.

Money still did most of the work. Discipline can't stand in for enough of it.

## So what

For people who teach or advise on money, the useful signal is specific. Resisting the next purchase didn't show a clear link. The habit of working steadily toward something further out did.

That is a habit people can practice, alongside the resources they need.

## The next question

Does a change in goal persistence come before a change in how secure people feel? Answering that takes the same people followed over time, and a fuller self-control measure. That is a study worth doing.

*Data, code, design, and every analytical decision: github.com/household-finance-lab/project-04*
