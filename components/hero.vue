<template lang="pug">
section.hero.is-primary.is-bold(v-once)
  .hero-body(v-if='!compact')
    .container
      h1.title.has-text-danger matthew ess
      h2.subtitle.has-text-danger software developer, social justice warrior, wannabe artist
  .hero-foot
    .tabs.is-boxed.is-fullwidth.is-three-quarters
      ul.has-text-weight-semibold.has-text-danger
        li(v-if='compact') #[nuxt-link.has-text-weight-bold(to='/') matthew ess]
        li #[nuxt-link(to='/projects') projects]
        li #[nuxt-link(to='/resume') resume]
        li #[nuxt-link(to='/blog') blog]
</template>

<script>
export default {
  props: {
    compact: {
      type: Boolean,
      default: false,
    },
  },
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
