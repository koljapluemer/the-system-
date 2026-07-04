<script setup lang="ts">
import { FolderOpen, ChevronRight } from 'lucide-vue-next'

defineEmits<{
  navigate: [route: string]
  changeFolder: []
}>()

const links = [{ id: 'scratchpad-triage', label: 'Scratchpad Triage' }]
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="px-8 py-6 border-b border-gray-100 flex items-center justify-between">
      <h1 class="text-xl font-semibold text-gray-900">Home</h1>
      <button
        @click="$emit('changeFolder')"
        title="Change data folder"
        class="text-gray-400 hover:text-gray-700 transition-colors"
      >
        <FolderOpen :size="16" />
      </button>
    </div>

    <div class="px-8 py-6">
      <div class="flex flex-col gap-2 max-w-sm">
        <button
          v-for="link in links"
          :key="link.id"
          @click="$emit('navigate', link.id)"
          class="flex items-center justify-between px-4 py-3 rounded-lg border border-gray-200 text-sm text-gray-700 hover:border-gray-300 hover:bg-gray-50 transition-colors"
        >
          {{ link.label }}
          <ChevronRight :size="15" class="text-gray-300" />
        </button>
      </div>
    </div>
  </div>
</template>
