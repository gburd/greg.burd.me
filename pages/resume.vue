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
      backend engineer on the transactions and food ordering teams. i work on
      high performance, realtime python infrastructure that supports a wide
      variety of features for ordering food on yelp, including driver tracking
      support to realtime updates and notifications about your order via push.
    p.has-text-weight-semibold software engineer intern @ yelp: summer 2017
    p.
      intern on the transactions team. built a streaming transformation pipeline
      that leveraged yelp's streaming datapipe (built on kafka technologies) and
      replicated to elasticsearch for high performance text querying over order
      data.
    p.has-text-weight-semibold developer intern @ school datebooks: summer 2016 - winter 2016
    p.
      i worked on a very small team of talented engineers writing backend
      PHP and javascript microservices for an athletic and educational
      scheduling web app.
    hr.is-three-quarters
    h2.subtitle skills
    .columns
      .column
        p.has-text-weight-semibold strong
        p python
        p pyramid, flask, django
        p unit, integration, and acceptance testing
        p darwin and linux systems
        p git, source control
        p working on a team, agile and "semi-agile" processes
        p html5, css, javascript
      .column
        p.has-text-weight-semibold familiar
        p haskell
        p elixir and phoenix
        p functional programming paradigms
        p database technology, sql, postgresql, elasticsearch
        p software deployment
        p elm, vue.js, react, SPAs, flux
        p c, systems programming, java, junit testing, ruby on rails
      .column
       p.has-text-weight-semibold learning
       p functional reactive programming, reflex
       p nix, nixos
       p type level programming and theory
       p programming language and compiler theory
</template>

<script>
export default {
  head() {
    return { title: 'resume' }
  },
  layout: 'compact',
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
