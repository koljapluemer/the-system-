import { ref } from 'vue'

interface UndoToastState {
  id: number
  message: string
  onUndo: () => void | Promise<void>
}

// Module-level singleton: any component can call showUndoToast() and get the
// same toast UI, so every "destructive action + undo" flow in the app looks
// and behaves the same way.
const toast = ref<UndoToastState | null>(null)
let nextId = 0
let hideTimer: ReturnType<typeof setTimeout> | null = null

const DEFAULT_DURATION_MS = 6000

export function useUndoToast() {
  function showUndoToast(
    message: string,
    onUndo: () => void | Promise<void>,
    durationMs = DEFAULT_DURATION_MS
  ) {
    if (hideTimer) clearTimeout(hideTimer)
    const id = ++nextId
    toast.value = { id, message, onUndo }
    hideTimer = setTimeout(() => {
      if (toast.value?.id === id) toast.value = null
    }, durationMs)
  }

  async function undo() {
    if (!toast.value) return
    const { onUndo } = toast.value
    if (hideTimer) clearTimeout(hideTimer)
    toast.value = null
    await onUndo()
  }

  function dismiss() {
    if (hideTimer) clearTimeout(hideTimer)
    toast.value = null
  }

  return { toast, showUndoToast, undo, dismiss }
}
