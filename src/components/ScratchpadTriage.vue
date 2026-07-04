<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ArrowLeft, Check, Trash2, SkipForward } from 'lucide-vue-next'
import { listUntriagedScratchpads, readJsonFile, writeJsonFile, deleteJsonFile } from '../composables/useDataFolder'
import { useUndoToast } from '../composables/useUndoToast'
import type { NoteFile } from '../types'

const props = defineProps<{ dataFolder: string }>()
defineEmits<{ back: [] }>()

const { showUndoToast } = useUndoToast()

const loading = ref(true)
const queue = ref<string[]>([])
const currentFilename = ref<string | null>(null)
const currentNote = ref<NoteFile | null>(null)

onMounted(async () => {
  await refreshQueue()
  await loadNext()
  loading.value = false
})

async function refreshQueue() {
  queue.value = await listUntriagedScratchpads(props.dataFolder)
}

function popRandom(): string | null {
  if (queue.value.length === 0) return null
  const index = Math.floor(Math.random() * queue.value.length)
  const [filename] = queue.value.splice(index, 1)
  return filename
}

async function loadNext() {
  const filename = popRandom()
  if (!filename) {
    currentFilename.value = null
    currentNote.value = null
    return
  }
  currentFilename.value = filename
  currentNote.value = await readJsonFile(props.dataFolder, filename)
}

async function keep() {
  const filename = currentFilename.value
  const note = currentNote.value
  if (!filename || !note) return
  await writeJsonFile(props.dataFolder, filename, { ...note, triaged: 'true' })
  await loadNext()
}

async function deleteNote() {
  const filename = currentFilename.value
  const note = currentNote.value
  if (!filename || !note) return
  await deleteJsonFile(props.dataFolder, filename)
  showUndoToast(`Deleted "${(note.title as string) ?? filename}"`, async () => {
    await writeJsonFile(props.dataFolder, filename, note)
    queue.value.push(filename)
  })
  await loadNext()
}

async function defer() {
  await loadNext()
}
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="px-8 py-6 border-b border-gray-100 flex items-center gap-3">
      <button @click="$emit('back')" title="Back to home" class="text-gray-400 hover:text-gray-700 transition-colors">
        <ArrowLeft :size="16" />
      </button>
      <h1 class="text-xl font-semibold text-gray-900">Scratchpad Triage</h1>
      <span class="text-xs text-gray-400 ml-auto">{{ queue.length }} remaining</span>
    </div>

    <div class="flex-1 flex items-center justify-center px-8">
      <div v-if="loading" class="text-sm text-gray-300">Loading…</div>

      <div v-else-if="!currentNote" class="text-center text-gray-400 text-sm">
        All caught up — no more scratchpad notes to triage.
      </div>

      <div v-else class="w-full max-w-xl">
        <div class="border border-gray-200 rounded-xl px-6 py-5 mb-6">
          <h2 class="text-base font-semibold text-gray-900 mb-3">
            {{ currentNote.title ?? '(untitled)' }}
          </h2>
          <p class="text-sm text-gray-600 whitespace-pre-wrap leading-relaxed">
            {{ currentNote.body ?? '' }}
          </p>
        </div>

        <div class="flex items-center gap-3">
          <button
            @click="keep"
            class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-green-600 text-white text-sm font-medium hover:bg-green-700 transition-colors"
          >
            <Check :size="15" />
            Keep
          </button>
          <button
            @click="deleteNote"
            class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 transition-colors"
          >
            <Trash2 :size="15" />
            Delete
          </button>
          <button
            @click="defer"
            class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-gray-200 text-gray-600 text-sm font-medium hover:bg-gray-50 transition-colors"
          >
            <SkipForward :size="15" />
            Defer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
