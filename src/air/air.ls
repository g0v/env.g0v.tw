{div} = React.DOM

MainPanel = React.createFactory React.createClass do
  render: ->
    div {id: 'main-panel', className: 'eva-box'},
      div {id: 'forecast'}
      div {id: 'metrics'}
      div {id: 'measure-time'}
      div {id: 'station-name'}
      div {id: 'measure'}
      div {id: 'about'}

App = React.createFactory React.createClass do
  render: ->
    div {className: 'container'},
      MainPanel!

<- $
React.render App!, document.getElementById("app")
