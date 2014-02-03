app.controller('prefController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.requestUrl = ''
  $scope.responseBody = ''
  $scope.connecting = false # タグを取得
  $scope.getTags = ->
    $scope.connecting = true
    $http.get('/tags').success((res) ->
      $scope.tags = res
      $scope.connecting = false)
  $scope.getTags()

  # sumit
  $scope.submit = ->
    $scope.connecting = true
    $request.send('/set_subscription_ordering', { s : $scope.s, v : $scope.v }, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body), ->
      $scope.connecting = false)
]);