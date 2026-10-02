extends Node
## Globaler Signal-Bus für systemübergreifende Ereignisse.
## Nur Signale, keine Logik und kein Zustand.
## Neue Signale nur nach Absprache (siehe docs/ARCHITECTURE.md).

@warning_ignore("unused_signal")
signal item_added(item_id: StringName, amount: int)

@warning_ignore("unused_signal")
signal item_removed(item_id: StringName, amount: int)
