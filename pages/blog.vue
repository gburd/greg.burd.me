<template lang="pug">
#blog
  nuxt-link(to='/blog')
    h1.title.has-text-centered ~ a mess of words ~
  #top
  nuxt-child
</template>

<script>
export default {
  head() {
    return { title: 'blog' }
  },
  layout: 'compact',
}
</script>

<style lang="sass" scoped>
.title
  margin-bottom: 5rem
</style>
