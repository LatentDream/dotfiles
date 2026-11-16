---
name: philo-software-design
description: Review code using the red flags from John Ousterhout's A Philosophy of Software Design. Use for design feedback on a diff, class, method, or pull request. Give short, concrete recommendations and name the red flag each finding illustrates.
---

# Software Design Review

Review code through the lens of *A Philosophy of Software Design*: reduce complexity through deep modules, information hiding, and clear interfaces. This is a review skill, not a mandate to refactor or make methods smaller.

## Review approach

1. Read the requested code or diff, including interface comments when present. For diffs, focus on introduced or worsened problems.
2. Inspect callers, callees, and related modules only as needed to confirm a suspected design problem.
3. Check the red flags below. Report concrete complexity costs, not hypothetical concerns or personal style preferences.
4. Group findings by root cause and put the most consequential first. Recommend the smallest useful change; do not edit code unless asked.

## Red flags

| Red flag | What to look for | Recommendation direction |
| --- | --- | --- |
| **Shallow Module** (pp. 25, 110) | A class or method's interface is not much simpler than its implementation. | Simplify the interface or combine responsibilities into a deeper module that hides useful complexity. |
| **Information Leakage** (p. 31) | The same design decision or assumption is embedded in multiple modules. | Give that knowledge one owner and hide it behind an interface. |
| **Temporal Decomposition** (p. 32) | Modules follow execution phases rather than boundaries of knowledge, spreading shared assumptions across steps. | Organize around the information being hidden, not merely read/process/write order. |
| **Overexposure** (p. 36) | Common API usage requires understanding rarely needed features or options. | Provide sensible defaults or a separate advanced path. |
| **Pass-Through Method** (p. 46) | A method mostly forwards arguments to another method with a similar signature, without a useful abstraction. | Remove redundant forwarding or give the layer a distinct responsibility. |
| **Repetition** (p. 62) | Nontrivial logic or knowledge is repeated and must change together. | Centralize the shared rule or restructure so the logic occurs once. |
| **Special-General Mixture** (p. 65) | A general-purpose mechanism includes special-purpose behavior for a particular use case. | Keep the general mechanism reusable and move policy to the use-case module. |
| **Conjoined Methods** (p. 72) | Understanding one method's implementation requires understanding another's internals. | Combine tightly coupled logic or establish a clear, self-contained contract. |
| **Comment Repeats Code** (p. 104) | A comment adds nothing beyond what nearby code already makes obvious. | Remove it or explain intent, constraints, units, or invariants instead. |
| **Implementation Documentation Contaminates Interface** (p. 114) | An interface comment describes internals callers do not need to know. | Document the caller-facing contract; move internal explanations beside the implementation. |
| **Vague Name** (p. 123) | A name is too imprecise to convey its meaning in context. | Name the specific concept, role, or unit. |
| **Hard to Pick Name** (p. 125) | An entity has no precise, intuitive name because its purpose is unclear or mixed. | Clarify or reshape the concept before renaming it. |
| **Hard to Describe** (p. 131) | Fully explaining a variable or method requires a long, tangled description. | Reconsider the abstraction or representation, not just the wording. |
| **Nonobvious Code** (p. 148) | Behavior or meaning is difficult to understand, such as hidden side effects or ambiguous data structures. | Make intent explicit with clearer types, names, contracts, or a targeted explanatory comment. |

## Judgment

- Red flags are signals, not automatic violations or blockers. Explain the actual cost in this code.
- Short methods are not inherently shallow; long methods are not inherently bad. Do not recommend extraction just to reduce line count.
- Forwarding can preserve a valuable boundary; similar-looking code may represent independent rules. Flag only when the abstraction adds complexity without compensating value.
- Sequential execution alone is not temporal decomposition. Long documentation alone is not a poor abstraction. Context matters.
- If evidence is missing, state the uncertainty briefly or omit the finding. Never invent findings to cover every flag.

## Output

Keep the review short. Prefer a few actionable findings over an exhaustive essay. Each finding should take one or two sentences:

- **Red flag — `path:line` or symbol:** Explain the concrete problem. **Recommendation:** Suggest a small, specific improvement.

Example:

- **Information Leakage — `reader.ts:24`, `writer.ts:51`:** Both modules encode the same record format, so a format change requires coordinated edits. **Recommendation:** Move encoding and decoding into one format-owning module.

Use the exact red flag name so the violated principle is clear. No mandatory severity labels, counts, or long summaries. If nothing meaningful applies, say: “No significant software-design red flags found.” Mention limited review context only when it affects confidence.
