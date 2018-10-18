import pkg from './package'

export default {
  mode: 'universal',

  /*
  ** Headers of the page
  */
  head: {
    titleTemplate(titleChunk) {
      return titleChunk ? `${titleChunk} | matthew ess` : 'matthew ess'
    },
    meta: [
      { charset: 'utf-8' },
      { 'http-equiv': 'X-UA-Compatible', content: 'IE=edge,chrome=1' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: pkg.description }
    ]
  },

  /*
  ** Customize the progress-bar color
  */
  loading: { color: '#fff' },

  /*
  ** Global CSS
  */
  css: [],

  /*
  ** Plugins to load before mounting the App
  */
  plugins: ['~/plugins/filters.js'],

  /*
  ** Nuxt.js modules
  */
  modules: ['@nuxtjs/bulma', 'nuxtent'],

  /*
  ** Static Site Generation configuration
  */
  generate: {
    dir: 'public'
  },

  /*
  ** Nuxtent configuration
  */
  nuxtent: {
    content: {
      page: '/blog/_slug',
      permalink: ':slug',
      generate: ['get', 'getAll']
    }
  },

  /*
  ** Build configuration
  */
  build: {
    postcss: {
      preset: {
        features: {
          customProperties: false
        }
      }
    },
    /*
    ** You can extend webpack config here
    */
    extend(config, ctx) {
      // Run ESLint on save
      if (ctx.isDev && ctx.isClient) {
        config.module.rules.push({
          enforce: 'pre',
          test: /\.(js|vue)$/,
          loader: 'eslint-loader',
          exclude: /(node_modules)/
        })
      }
    }
  }
}
