Let's add a flow for Spaced Repetition.

Add a new primary type (@docs/adding-a-primary-type.md) `flashcard`.

These should have the two special props front and back, handled visually like `content` usually is.

On their view page, front and back should be shown directly below title.

Make a new flow, "Memorize".

This should be a basic sr-flashcard-flow.
Use flutter-fsrs to track progress, also storing the learning data in the schema `assets/note_schema.json`
Load a random `flashcard` note that is due.
Show the `front` (rendered as markdown, use a library) and a button `Reveal`.
Once reveal clicked, show `front`, a separator, `back` (also md) and the standard SR buttons.
If no due flashcard, introduce a random `flashcard` that has not been practiced.
When flashcar is new, show immediately the revealed state and just one button "I will remember" which creates the initial fsrs object.

When rendering a flashcard, add small icon buttons (maybe top right, maybe some flutter conventions) to delete the flashcard, and to jump to its edit view.

W/ 1/6 chance, instead of showing any flashcard, show an art-triage screen (as a kind of break).
Art-triage was only ever a prototype for this; remove it as a standalone flow now.