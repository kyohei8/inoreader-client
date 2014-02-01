app.controller('prefController',['$scope', '$http', ($scope, $http) ->
  $scope.requestUrl = ''
  $scope.responseBody = ''
  $scope.connecting = false

  # sumit
  $scope.submit = ->
    $scope.connecting = true

    $http({
      url : '/set_subscription_ordering',
      method : 'POST',
      data : $.param({
        s : $scope.s
        v : $scope.v
      }),
      headers :
        'Content-Type' : 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success (res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
]);