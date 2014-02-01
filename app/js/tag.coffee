app.controller('renameTagController', ['$scope', '$http', ($scope, $http) ->
  $scope.s = ''
  $scope.dest = ''

  $scope.requestUrl = ''
  $scope.responseBody = ''

  $scope.connecting = false

  # sumit
  $scope.submit = ->
    $scope.connecting = true

    $http({
      url : '/rename_tag',
      method : 'POST',
      data : $.param({
        s : $scope.s
        dest : $scope.dest
      }),
      headers :
        'Content-Type' : 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success (res) ->
      $scope.connecting = false
      $scope.dest = ''
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
      $scope.getTags()
])


app.controller('deleteTagController', ['$scope', '$http', ($scope, $http) ->
  $scope.s = ''

  $scope.requestUrl = ''
  $scope.responseBody = ''

  $scope.connecting = false

  # sumit
  $scope.submit = ->
    $scope.connecting = true

    $http({
      url : '/disable_tag',
      method : 'POST',
      data : $.param({
        s : $scope.s
      }),
      headers :
        'Content-Type' : 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success (res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
      $scope.getTags()

])


app.controller('editTagController', ['$scope', '$http', ($scope, $http) ->
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

    $http({
      url : '/edit_tag',
      method : 'POST',
      data : $.param({
        type : $scope.type
        tagname : $scope.tagName.value
        labelname : $scope.labelName
        ids : $scope.ids
      }),
      headers :
        'Content-Type' : 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success (res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body

])