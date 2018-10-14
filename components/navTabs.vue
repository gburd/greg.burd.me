<template lang="pug">
#nav-tabs
  .tabs.is-boxed.is-fullwidth
    ul.has-text-weight-semibold.has-text-danger
      li #[nuxt-link(to='/') home]
      li #[nuxt-link(to='/projects') projects]
      li #[nuxt-link(to='/resume') resume]
      //- li #[nuxt-link(to='/blog') blog]
</template>
