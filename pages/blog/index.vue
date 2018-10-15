<template lang="pug">
#blog
</template>

<script>
export default {
  asyncData({ app, route }) {
    console.log(route)
  },
  head() {
    return {
      title: 'blog'
    }
  },
  layout: 'compact'
}
</script>
