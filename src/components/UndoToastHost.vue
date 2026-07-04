<script setup lang="ts">
import { X } from 'lucide-vue-next'
import { useUndoToast } from '../composables/useUndoToast'

const { toast, undo, dismiss } = useUndoToast()
</script>

<template>
  <Transition name="toast">
    <div
      v-if="toast"
      class="fixed bottom-6 left-1/2 -translate-x-1/2 flex items-center gap-3 bg-gray-900 text-white text-sm rounded-lg shadow-lg px-4 py-3"
    >
      <span>{{ toast.message }}</span>
      <button @click="undo" class="font-medium text-blue-300 hover:text-blue-200 transition-colors">
        Undo
      </button>
      <button @click="dismiss" class="text-gray-400 hover:text-gray-200 transition-colors">
        <X :size="14" />
      </button>
    </div>
  </Transition>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, 8px);
}
</style>
