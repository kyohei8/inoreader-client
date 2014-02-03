app.controller('renameTagController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.s = ''
  $scope.dest = ''
  $scope.requestUrl = ''
  $scope.responseBody = ''
  $scope.connecting = false

  # タグを取得
  $scope.getTags = ->
    $scope.connecting = true
    $http.get('/tags').success((res) ->
      $scope.tags = res
      $scope.connecting = false)
  $scope.getTags()

  # sumit
  $scope.submit = ->
    $scope.connecting = true
    $request.send '/rename_tag', { s : $scope.s, dest : $scope.dest }, 'POST', ((res) ->
      $scope.connecting = false
      $scope.dest = ''
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
      $scope.getTags()), ->
      $scope.connecting = false
])


app.controller('deleteTagController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.s = ''
  $scope.requestUrl = ''
  $scope.responseBody = ''
  $scope.connecting = false

  # タグを取得
  $scope.getTags = ->
    #$scope.connecting = true うまくspinがでないためcomment化
    $http.get('/tags').success((res) ->
      $scope.tags = res
      $scope.connecting = false)
  $scope.getTags()

  # sumit
  $scope.submit = ->
    $scope.connecting = true
    $request.send '/disable_tag', { s : $scope.s }, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
      $scope.getTags()), ->
      $scope.connecting = false
])


app.controller('editTagController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.s = ''
  $scope.type = 'a'
  $scope.labelName = ''
  $scope.ids = ''
  $scope.types = [
    {value : 'a', label : 'Add Tags to item'},
    {value : 'r', label : 'Remove Tags from item'}
  ]

  $http.get('/special_tags').success((res)->
    $scope.tags = res
    $scope.tagName = res[0])

  $scope.requestUrl = ''
  $scope.responseBody = ''

  $scope.connecting = false

  $scope.labelDisabled = true

  $scope.$watch 'tagName', (newValue) ->
    if (newValue && newValue.label is 'label')
      $scope.labelDisabled = false
    else
      $scope.labelDisabled = true
      $scope.labelName = ''

  # sumit
  $scope.submit = ->
    $scope.connecting = true
    data =
      type : $scope.type
      tagname : $scope.tagName.value
      labelname : $scope.labelName
      ids : $scope.ids

    $request.send('/edit_tag', data, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
    ), ->
      $scope.connecting = false)

])