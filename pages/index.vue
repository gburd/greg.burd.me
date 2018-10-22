<template lang="pug">
#home
  .tile.is-ancestor
    .tile.is-vertical.is-4
      .tile.is-9
        .notification.is-info
          h1.title.is-4 me
          p.content.
            i'm an aspiring communist, a
            #[a(href='https://mattandmack.website' target='_blank') partner],
            and a software developer at yelp.
      .tile.is-9
        .notification.is-warning
          h1.title.is-4 what's inspiring me now
          .content
            p wes anderson's isle of dogs
            p mitski's #[a(href='https://mitski.bandcamp.com/album/be-the-cowboy' target='_blank') be the cowboy]
            p thomas pynchon's gravity's rainbow
    .tile.is-4
      .tile.is-9
        .notification.is-danger
            h1.title.is-4 what i care about
            p.content.
              as an aspirational communist, i think the most important tools are the ones that help
              workers organize and empower themselves. i want my software to be a tool for
              liberation, and i want to work on projects that embody that goal. reach out
              to mess [at] yelp [dot] com if you want to work on or discuss something.
            p.content.
              "the philosophers have only interpreted the world, in various ways.
              the point, however, is to change it."
    .tile.is-3
      figure.image
        img(src='@/assets/img/me.jpg')
</template>
