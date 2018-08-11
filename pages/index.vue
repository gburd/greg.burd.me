<template lang="pug">
#home
  .tile.is-ancestor
    .tile.is-vertical.is-4
      .tile.is-9
        .notification.is-info
          h1.title.is-4 me
          p.content.
            i'm a communist, a
            #[a(href='https://mattandmack.website' target='_blank') partner],
            a recently graduated student, and a software developer at yelp.
      .tile.is-9
        .notification.is-warning
          h1.title.is-4 what's inspiring me now
          .content
            p bo burnham's 8th grade
            p louis brennan's #[a(href='https://louisbrennan.bandcamp.com/album/dead-capital' target='_blank') dead capital]
            p thomas pynchon's gravity's rainbow
    .tile.is-4
      .tile.is-9
        .notification.is-danger
            h1.title.is-4 what i care about
            p.content.
              as a communist, i'm passionate about anti-imperialism and decolonization.
              i believe that software can be a tool for liberation, and those are the tools
              i want to develop. feel free to get in touch with
              me at mess [at] yelp [dot] com if you have similar goals.
            p.content.
              "the philosophers have only interpreted the world, in various ways.
              the point, however, is to change it."
    .tile.is-3
      figure.image
        img(src='@/assets/img/me.jpg')
</template>
