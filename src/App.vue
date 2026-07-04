<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { open } from '@tauri-apps/plugin-dialog'
import { getDataFolder, setDataFolder } from './composables/useDataFolder'
import HomeDashboard from './components/HomeDashboard.vue'
import ScratchpadTriage from './components/ScratchpadTriage.vue'
import UndoToastHost from './components/UndoToastHost.vue'

type Route = 'home' | 'scratchpad-triage'

const dataFolder = ref<string | null>(null)
const route = ref<Route>('home')

onMounted(async () => {
  let folder = await getDataFolder()
  if (!folder) {
    const picked = await open({ directory: true, multiple: false, title: 'Choose notes data folder' })
    if (!picked) return
    folder = picked as string
    await setDataFolder(folder)
  }
  dataFolder.value = folder
})

async function changeFolder() {
  const picked = await open({ directory: true, multiple: false, title: 'Choose notes data folder' })
  if (!picked) return
  const folder = picked as string
  await setDataFolder(folder)
  dataFolder.value = folder
  route.value = 'home'
}

function navigate(target: string) {
  route.value = target as Route
}
</script>

<template>
  <div v-if="!dataFolder" class="flex items-center justify-center h-screen text-gray-400 text-sm">
    Waiting for folder selection…
  </div>

  <main v-else class="flex-1 overflow-y-auto bg-white">
    <HomeDashboard v-if="route === 'home'" @navigate="navigate" @changeFolder="changeFolder" />
    <ScratchpadTriage
      v-else-if="route === 'scratchpad-triage'"
      :dataFolder="dataFolder"
      @back="route = 'home'"
    />
  </main>

  <UndoToastHost />
</template>
