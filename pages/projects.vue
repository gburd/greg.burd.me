<template lang="pug">
#projects.is-half.has-text-centered-mobile
  h2.subtitle.has-text-centered older projects
  hr
  h2.subtitle #[a(href='https://github.com/matthewess/boilertalk-frontend') boilertalk]
  p.content.
    boilertalk is a project i'm working on with my fiancée to enable social
    psychology researchers to easily simulate a social media platform to
    garner realistic interactions and behaviors from students for the purpose
    of research studies.
  h2.subtitle #[a(href='https://github.com/purdue-csusb/openideas') openideas]
  p.content.
    openideas is a platform i worked on with jay hankins for
    #[a(href='https://purdueusb.com') Purdue USB] and the Purdue
    Undergraduate CS Community. we hoped to implement it
    to give students a way to voice concerns or improvements for
    the department, then vote on and discuss them.
  h2.subtitle #[a(href='https://github.com/lemming-online/mischief') lemming]
  p.content.
    i worked on the backend component of the lemming project, a group
    project for Purdue's senior design class that was meant as a queuing
    system to help lab TAs or group leaders manage large groups of students
    or members who need help with an assignment or project.
  h2.subtitle #[a(href='https://github.com/projectkuva/kuva-frontend') kuva]
  p.content.
    kuva was a small iOS app meant as a regional, location centric clone
    of instagram that would allow you to see and interact with popular photos
    taken by users nearby you.

  hr
  p.content.
    check out my #[a.has-text-info(href='https://gitlab.com/matthewess') gitlab account],
    or my older #[a.has-text-info(href='https://github.com/matthewess') github account].
</template>

<script>
export default {
  head() {
    return { title: 'projects' }
  },
  layout: 'compact',
}
</script>

<style lang="sass" scoped>
@import '~assets/sass/utilities'

+desktop
  .is-half
    width: 50%
</style>
