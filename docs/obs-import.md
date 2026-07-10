Add a new flow, linked from the middle section of the overview dashboard: "Import Obs Flow"

Clicking it should first go to a `primaryType` selection screen, with options:
- gestalt
- context
- ifThen
- description
- quote
- source
- entity
- story

Then, redirect to the correct, dedicated form.
I'm iteratively building this; stub forms not yet described below.

## Add Gestalt

## Add Context

## Add IfThen

Standard affordances for title and content, aliases.
Confirming this form leads to another UI, which again shows title, content, aliases.
Should have little edit icon buttons to activate inline editing of those.

This second UI is a general pattern, not specific to IfThen: it's also what the Lists flow
uses to edit (and land on right after creating) any `primaryType` that opts into it, not
just notes created via this Import Obs Flow.

Also have a button "Add Source Relationship", which leads to a modal/popup that is at the same time
a smart search (title and aliases) of all `primaryType` `source` notes, but also allows adding a new source with the inputed title if non such exists yet.

Also have a button "Add Evidence", working analogous to "Add Source Relationship", only the smart
search/create covers notes of `primaryType` gestalt, context, ifThen, description, quote, or story
(not source). Since more than one type is eligible, when dynamically adding a new note via this
button the user must specify which of those types they want.

## Add Description

## Add Quote

## Add Source

## Add Entity

## Add Story

