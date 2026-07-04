// A note file is arbitrary JSON — different flows will read/write different
// shapes. Consumers narrow to the fields they care about.
export type NoteFile = Record<string, unknown>

export interface ScratchpadNote extends NoteFile {
  primaryType: string
  title?: string
  body?: string
  triaged?: string
}
