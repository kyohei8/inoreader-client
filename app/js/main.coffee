app = angular.module 'app', ['ui.bootstrap']
window.app = app

app.controller('navController', ['$scope', '$window', ($scope, $window) ->
  $scope.isActive = (path)->
    path is $window.location.pathname
]);