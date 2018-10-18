<template lang="pug">
#post
  h1.title {{ post.title }}
  h2.subtitle {{ post.tagline }}
  p {{ post.date | prettifyDateLong }}
  hr
  .post-body.content(v-html='post.body')
  a(href='#top') top
</template>

<script>
export default {
  async asyncData({ app, params, payload }) {
    return {
      post: await app.$content('/').get(params.slug),
    }
  },
  head() {
    return {
      title: this.post.title,
    }
  },
  beforeMount() {
    if (this.post.draft) {
      this.$router.replace('/blog')
    }
  },
  layout: 'compact',
}
</script>

<style lang="sass" scoped>
@import '~assets/sass/utilities'

.post-body
  width: 75%
  margin-bottom: 5rem
  font-size: $size-medium
  a
    text-decoration: underline
</style>
