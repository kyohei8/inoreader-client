app.controller('StreamController', ['$scope', '$http', ($scope, $http) ->
  $scope.hideAdvancedOption = true
  $scope.advancedOptionText = 'show Advanced option'
  $scope.feedDisabled = true

  $scope.type = 'itemids'
  $scope.feed = ''
  $scope.n = 20
  $scope.r = ''
  $scope.ot = ''
  $scope.xt = ''
  $scope.it = ''
  $scope.c = ''
  $scope.output = 'json'


  $scope.types = [
    {value: 'stream', label: 'stream'},
    {value: 'itemids', label: 'item ids'}
  ]

  $scope.sorts = [
    {value: '', label: 'newest'},
    {value: 'o', label: 'oldest'}
  ]

  $scope.exTargets = [
    {value: '', label: 'all'},
    {value: 'user/-/state/com.google/read', label: 'unread only'}
  ]

  $scope.icTargets = [
    {value: '', label: 'all'},
    {value: 'user/-/state/com.google/read', label: 'read'},
    {value: 'user/-/state/com.google/starred', label: 'starred'},
    {value: 'user/-/state/com.google/like', label: 'like'}
  ]

  $scope.outputs = [
    {value: 'json', label: 'JSON'},
    {value: 'xml', label: 'XML'}
  ]

  # 詳細の表示非表示
  $scope.toggleAdvancedOption = ->
    $scope.hideAdvancedOption = !$scope.hideAdvancedOption
    if $scope.hideAdvancedOption
      $scope.advancedOptionText = 'show Advanced option'
    else
      $scope.advancedOptionText = 'hide Advanced option'

  # feedを取得
  $http.get('/feeds').success((data) ->
    $scope.feeds = data
    $scope.feedDisabled = false
  )

  $scope.submit = ->
    console.log @n
    console.log @r
    console.log @ot
    console.log @xt
    console.log @it
    console.log @c
  
    #$http.post('/stream', )
    console.log 'submit!'

])
