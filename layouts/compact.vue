<template lang="pug">
.nuxt
  hero(:compact='true')
  .container
    nuxt
  footer.footer.white
</template>

<script>
import hero from '../components/hero.vue'

export default {
  components: { hero }
}
</script>

<style lang="sass">
@import '~assets/sass/mat'
</style>
