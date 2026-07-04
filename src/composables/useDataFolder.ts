import { invoke } from '@tauri-apps/api/core'
import type { NoteFile } from '../types'

export async function getDataFolder(): Promise<string | null> {
  return invoke<string | null>('get_data_folder')
}

export async function setDataFolder(path: string): Promise<void> {
  return invoke('set_data_folder', { path })
}

export async function listUntriagedScratchpads(folder: string): Promise<string[]> {
  return invoke<string[]>('list_scratchpad_untriaged', { folder })
}

export async function readJsonFile(folder: string, filename: string): Promise<NoteFile> {
  return invoke<NoteFile>('read_json_file', { folder, filename })
}

export async function writeJsonFile(folder: string, filename: string, content: NoteFile): Promise<void> {
  return invoke('write_json_file', { folder, filename, content })
}

export async function deleteJsonFile(folder: string, filename: string): Promise<void> {
  return invoke('delete_json_file', { folder, filename })
}
