Let's improve relationships.

- every type should allow having see-also relationships to any other type; this should already be implemented
- get rid of the "other relationship" popup, if it still exists; it's redundant

- the following notes should have the possibility to add logs: hypothesis, milestone, source

- gestalt should allow descriptions
- descriptions should allow gestalts  and evidence (may be source, quote, if-then, description, story or gestalt)
- if-then should allow contexts and evidence (may be source, quote, if-then, description, story or gestalt)
- contexts should have if then
- quotes should allow sources, and entitty
- sources should also allow sources, and entities (referring to `entity`)
- stories should allow sources and entities

All relationships should automatically be mirrored, except: logs (we never look at logs, so no need to put relationships on them), see-also. Apart from that, everything should be automatically be added reciprocically, e.g. adding a source to a quote should also add the quote to the source (even if the mirror relationship is not explicitly mentioned above)

## Later additions

- if-then and description also allow: opposite, parent, child, agrees (same allowed target types as evidence: source, quote, if-then, description, story, gestalt)
- gestalt also allows: opposite, parent, child (not agrees)
- opposite and agrees are symmetric (mirror onto themselves, like gestalt/description mirror onto each other); parent mirrors as child and vice versa
