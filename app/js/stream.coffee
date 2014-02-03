app.controller('StreamController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.hideAdvancedOption = true
  $scope.advancedOptionText = 'show Advanced option'
  $scope.feedDisabled = true
  $scope.connecting = false
  $scope.requestUrl = ''
  $scope.responseBody = ''

  $scope.type = 'stream'
  $scope.feed = ''
  $scope.n = 20
  $scope.r = ''
  $scope.ot = ''
  $scope.xt = ''
  $scope.it = ''
  $scope.c = ''
  $scope.output = 'json'


  $scope.types = [
    {value : 'stream', label : 'items'},
    {value : 'itemids', label : 'item ids'}
  ]

  $scope.sorts = [
    {value : '', label : 'newest'},
    {value : 'o', label : 'oldest'}
  ]

  $scope.exTargets = [
    {value : '', label : 'all'},
    {value : 'user/-/state/com.google/read', label : 'unread only'}
  ]

  $scope.icTargets = [
    {value : '', label : 'all'},
    {value : 'user/-/state/com.google/read', label : 'read'},
    {value : 'user/-/state/com.google/starred', label : 'starred'},
    {value : 'user/-/state/com.google/like', label : 'like'}
  ]

  $scope.outputs = [
    {value : 'json', label : 'JSON'},
    {value : 'xml', label : 'XML'}
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
    $scope.feedDisabled = false)



  $scope.submit = ->
    query =
      n : @n
      r : @r
      ot : @ot
      xt : @xt
      it : @it
      c : @c

    data =
      type : @type
      feed : @feed
      query : query


    $scope.requestUrl = ''
    $scope.responseBody = ''
    $scope.connecting = true

    $request.send('/stream', data, 'POST', (res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = angular.fromJson(res.body)
    , ->
      $scope.connecting = false
    )

])
