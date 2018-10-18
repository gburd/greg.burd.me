<template lang="pug">
#resume.is-half.has-text-centered-mobile
  .content
    h1.title matthew ess
    h2.subtitle software developer
    hr.is-three-quarters
    h2.subtitle education
    p.
      purdue university, west lafayette, IN #[br]
      B.S. in computer science, minor in political science #[br]
      may 2018 #[br]
      3.90 gpa
    hr.is-three-quarters
    h2.subtitle experience
    p.has-text-weight-semibold software engineer @ yelp: summer 2018 - present
    p.
      transactions backend engineer.
    p.has-text-weight-semibold software engineer intern @ yelp: summer 2017
    p.
      i joined the transactions team and worked on restructuring ordering data
      to make it more efficient to query.
    p.has-text-weight-semibold developer intern @ school datebooks: summer 2016 - winter 2016
    p.
      i worked on a very small team of talented engineers writing backend
      PHP and javascript microservices for an athletic and educational
      scheduling web app.
    hr.is-three-quarters
    h2.subtitle skills
    .columns
      .column
        p python 2 and 3
        p flask, django, pyramid
        p elixir and phoenix
        p java, junit testing, ruby on rails
      .column
        p html5, css, javascript
        p vue.js, react
        p elm, reactive frontend programming
        p single page apps, components, flux
      .column
        p c, unix programming
        p software deployment
        p macOS, linux, windows
        p source control, git
</template>

<script>
export default {
  head() {
    return { title: 'resume' }
  },
  layout: 'compact'
}
</script>

<style lang="sass" scoped>
@import '~assets/sass/utilities'

+desktop
  .is-three-quarters
    width: 75%
  .is-half
    width: 50%
</style>
