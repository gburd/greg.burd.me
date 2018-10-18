<template lang="pug">
ul.blog-items
  li.blog-item(v-for='(post, index) in listing' v-if='!post.draft')
    nuxt-link(:to='post.path')
      span.post-title {{ post.title }}
      span.post-date {{ post.date | prettifyDate }}
      .post-tagline {{ post.tagline }}
    hr(v-if='index < listing.length - 1')
</template>

<script>
export default {
  async asyncData({ app }) {
    return {
      listing: await app
        .$content('/')
        .query({ exclude: ['body', 'meta', 'permalink', 'anchors'] })
        .getAll()
    }
  },
  layout: 'compact'
}
</script>

<style lang="sass" scoped>
@import '~assets/sass/utilities'

.blog-items
  +desktop
    width: 75%
  margin: 0 auto
.blog-item
  margin-bottom: 3rem
.post-title
  font-size: $size-medium
.post-date
  float: right
.post-tagline
  font-size: $size-normal
  color: $grey-light
  margin-bottom: 1rem
  width: fit-content
</style>
