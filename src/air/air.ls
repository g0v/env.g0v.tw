{createFactory, createClass} = React
{div, span, a, b, br, sub, h1, h2, h3} = React.DOM

MetricsMenu = createFactory createClass do
  metrics:
    * name: 'psi'
      title: '測量空氣中的可吸入微粒、二氧化硫、二氧化氮、一氧化碳及臭氧等含量，再換算成副指標值，以當日各副指標值之最大值為該地方當日的空氣污染指標值。'
      label: '空污指標'
      abbr: 'PSI'
    * name: 'os'
      title: '具強氧化力，對呼吸系統具刺激性，能引起咳嗽、氣喘、頭痛、疲倦及肺部之傷害，特別是對小孩、老人、病人或戶外運動者有較大影響。'
      label: '臭氧濃度'
      abbr: 'O'
      postabbr: '3'
    * name: 'pm10'
      title: '粒徑小於10微米，能深入肺部深處，如附著其他污染物，則將加深對呼吸系統之危害。'
      label: '可吸入微粒'
      abbr: 'PM'
      postabbr: '10'
    * name: 'pm25'
      title: '粒徑小於2.5微米，能深入細支氣管和肺泡，直接影響肺的通氣功能，且吸附於肺泡之後很難掉落。'
      label: '細微粒'
      abbr: 'PM'
      postabbr: '2.5'
  render: ->
    div {id: 'metrics'},
      @metrics.map ->
        a {className: "#{it.name} ui button", title: it.title},
          b {} it.label
          br {}
          sub {} it.preabbr
          span {} it.abbr
          sub {} it.postabbr

MeasureBox = createFactory createClass do
  render: ->
    div {id: 'measure'}

MainPanel = createFactory createClass do
  render: ->
    div {id: 'main-panel', className: 'eva-box'},
      div {id: 'forecast'}
      MetricsMenu!
      h3 {id: 'measure-time'} '2015-01-07 08:00'
      h2 {id: 'station-name'} '懸浮微粒'
      MeasureBox!
      div {id: 'about'},
        span {} '資料來源：環保署'
        a {href: 'http://opendata.epa.gov.tw/Data/Contents/AQX/', target: '_blank'} '空氣品質即時污染指標'

App = createFactory createClass do
  render: ->
    div {className: 'container'},
      MainPanel!

<- $
React.render App!, document.getElementById("app")
