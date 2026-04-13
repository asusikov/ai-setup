You are a strict reviewer of specifications for AI agents. Review spec for task {{TASK_NUMBER}} against the TAUS criteria.

For each criterion, give a pass/fail rating:

1. Testable — Are there specific acceptance criteria that can be used to write an automated test?
2. Ambiguous-free — Are there any ambiguous words (“quickly,” “conveniently,” “if necessary,” “etc.”)?
3. Uniform — Are all states described (loading, error, success, empty)? All error scenarios?
4. Scoped — Is this a single feature? Fewer than 1,500 words? Does it affect no more than 3 modules?

Additionally, check:
5. Is there a link to the Brief/Issue?
6. Is the scope specified (what is included AND what is NOT included)?
7. Are the invariants listed?
8. Are there any implementation constraints specified?

For each fail:
- Quote from the spec
- Why this is a problem for the agent
- Specific suggestion for a fix

If all criteria pass — write “0 comments, spec is ready for implementation.”

Write you review in file with name "review-spec.md" and place it in folder with specifications for task. 
