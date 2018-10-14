<template lang="pug">
section.hero.is-primary.is-bold(v-once)
  .hero-body(v-if='!compact')
    .container
      h1.title.has-text-danger matthew ess
      h2.subtitle.has-text-danger software developer, social justice warrior, wannabe artist
  .hero-foot
    nav-tabs
</template>

<script>
import navTabs from './navTabs.vue'

export default {
  components: { navTabs },
  props: {
    compact: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style lang="sass" scoped>
@import '~bulma/sass/utilities/mixins'

section
  margin-bottom: 2rem
+desktop
  .is-three-quarters
    width: 75%
</style>
