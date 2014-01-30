app.controller('StreamController', ['$scope', '$http', ($scope, $http) ->
  $scope.hideAdvancedOption = true
  $scope.advancedOptionText = 'show Advanced option'

  $scope.types = [
    {value: 'stream', label: 'stream', checked: true},
    {value: 'itemids', label: 'item ids', checked: false}
  ]

  $scope.sorts = [
    {value: '', label: 'newest', checked: true},
    {value: 'o', label: 'oldest', checked: false}
  ]

  $scope.exTargets = [
    {value: '', label: 'all', checked: true},
    {value: 'user/-/state/com.google/read', label: 'unread only', checked: false}
  ]

  $scope.icTargets = [
    {value: '', label: 'all', checked: true},
    {value: 'user/-/state/com.google/read', label: 'read', checked: false},
    {value: 'user/-/state/com.google/starred', label: 'starred', checked: false},
    {value: 'user/-/state/com.google/like', label: 'like', checked: false}
  ]

  $scope.outputs = [
    {value: 'json', label: 'JSON', checked: true},
    {value: 'xml', label: 'XML', checked: false}
  ]

  # 詳細の表示非表示
  $scope.toggleAdvancedOption = ->
    $scope.hideAdvancedOption = !$scope.hideAdvancedOption
    if $scope.hideAdvancedOption
      $scope.advancedOptionText = 'show Advanced option'
    else
      $scope.advancedOptionText = 'hide Advanced option'

  # feedを取得
  $http.get('/feeds').success( (data) ->
    $scope.feeds = data
  )

])
