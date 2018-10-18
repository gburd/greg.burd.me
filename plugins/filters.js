import Vue from 'vue'

const monthNames = [
  { short: 'jan', long: 'january' },
  { short: 'feb', long: 'february' },
  { short: 'mar', long: 'march' },
  { short: 'apr', long: 'april' },
  { short: 'may', long: 'may' },
  { short: 'jun', long: 'june' },
  { short: 'jul', long: 'july' },
  { short: 'aug', long: 'august' },
  { short: 'sep', long: 'september' },
  { short: 'oct', long: 'october' },
  { short: 'nov', long: 'november' },
  { short: 'dec', long: 'december' },
]

/*
** Very confusing to read, but this takes the YYYY-MM-DD format from posts
** and makes it readable in the way I want: either
** 'mon DD', 'mon DD YY', or 'month DD YYYY'
*/
const prettifyDate = (date, long) => {
  date = date.split('-')
  const month = monthNames[parseInt(date[1]) - 1] || {
    short: date[1],
    long: date[1],
  }
  const day = date[2]
  const year = date[0]
  const thisYear = year == new Date().getFullYear()
  return `${long ? month.long : month.short} ${day} ${
    long ? year : thisYear ? '' : year.substring(2)
  }`
}

Vue.filter('prettifyDate', date => prettifyDate(date, false))
Vue.filter('prettifyDateLong', date => prettifyDate(date, true))
